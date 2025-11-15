// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/Project13Solution.sol";

/**
 * @title Project13Test
 * @notice Comprehensive tests for Block Properties & Time Logic
 * @dev Demonstrates vm.warp() and vm.roll() for time manipulation in tests
 *
 * KEY TESTING CONCEPTS:
 * - vm.warp(timestamp): Set block.timestamp to specific value
 * - vm.roll(blockNumber): Set block.number to specific value
 * - skip(duration): Advance block.timestamp by duration
 * - vm.expectRevert(): Test error cases
 * - vm.deal(): Give test accounts ETH
 *
 * LEARNING: Time manipulation is essential for testing time-based logic
 * Without it, we'd have to wait hours/days for tests to complete!
 */
contract Project13Test is Test {
    Project13Solution public project;

    // Test accounts
    address public owner = address(this);
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public user3 = address(0x3);

    // Constants for testing
    uint256 constant RATE_LIMIT = 1 hours;
    uint256 constant COOLDOWN = 7 days;

    /*//////////////////////////////////////////////////////////////
                              SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        // Deploy contract
        project = new Project13Solution();

        // Give test accounts ETH
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(user3, 100 ether);

        // Set predictable starting time and block for tests
        vm.warp(1000); // Start at timestamp 1000
        vm.roll(100);  // Start at block 100
    }

    /*//////////////////////////////////////////////////////////////
                        TIME-LOCKED VAULT TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test locking ETH in vault
     * @dev Verifies vault locking mechanics and event emission
     */
    function testLockInVault() public {
        uint256 lockDuration = 1 days;
        uint256 depositAmount = 5 ether;

        // Expect VaultLocked event
        vm.expectEmit(true, true, true, true);
        emit Project13Solution.VaultLocked(block.timestamp + lockDuration, depositAmount);

        // Lock ETH in vault
        vm.prank(user1);
        project.lockInVault{value: depositAmount}(lockDuration);

        // Verify vault state
        assertEq(project.vaultBalance(), depositAmount);
        assertEq(project.vaultUnlockTime(), 1000 + lockDuration);
        assertTrue(project.isVaultLocked());
    }

    /**
     * @notice Test withdrawing from vault before unlock time fails
     * @dev Demonstrates testing time-based restrictions
     */
    function testCannotWithdrawWhileLocked() public {
        // Lock funds
        vm.prank(user1);
        project.lockInVault{value: 5 ether}(1 days);

        // Try to withdraw immediately (should fail)
        vm.prank(user1);
        vm.expectRevert(Project13Solution.VaultStillLocked.selector);
        project.withdrawFromVault();

        // Advance time by half a day (still locked)
        vm.warp(block.timestamp + 12 hours);

        // Try again (should still fail)
        vm.prank(user1);
        vm.expectRevert(Project13Solution.VaultStillLocked.selector);
        project.withdrawFromVault();
    }

    /**
     * @notice Test withdrawing from vault after unlock time succeeds
     * @dev Demonstrates vm.warp() for time travel in tests
     */
    function testWithdrawAfterUnlock() public {
        uint256 depositAmount = 5 ether;
        uint256 lockDuration = 1 days;

        // Lock funds
        vm.prank(user1);
        project.lockInVault{value: depositAmount}(lockDuration);

        // Advance time to exactly unlock time
        vm.warp(block.timestamp + lockDuration);

        // Verify vault is no longer locked
        assertFalse(project.isVaultLocked());

        // Record balance before withdrawal
        uint256 balanceBefore = user1.balance;

        // Withdraw funds
        vm.prank(user1);
        project.withdrawFromVault();

        // Verify balance increased
        assertEq(user1.balance, balanceBefore + depositAmount);

        // Verify vault is empty
        assertEq(project.vaultBalance(), 0);
    }

    /**
     * @notice Test withdrawing well after unlock time
     * @dev Demonstrates that >= comparison works for any time after unlock
     */
    function testWithdrawLongAfterUnlock() public {
        // Lock for 1 day
        vm.prank(user1);
        project.lockInVault{value: 3 ether}(1 days);

        // Fast forward 1 week (way past unlock time)
        vm.warp(block.timestamp + 1 weeks);

        // Should still be able to withdraw
        vm.prank(user1);
        project.withdrawFromVault();

        assertEq(project.vaultBalance(), 0);
    }

    /**
     * @notice Test cannot withdraw from empty vault
     */
    function testCannotWithdrawFromEmptyVault() public {
        // Try to withdraw without depositing
        vm.expectRevert(Project13Solution.InsufficientBalance.selector);
        project.withdrawFromVault();
    }

    /**
     * @notice Test multiple deposits accumulate
     */
    function testMultipleDeposits() public {
        // First deposit
        vm.prank(user1);
        project.lockInVault{value: 2 ether}(1 days);

        // Second deposit with longer lock
        vm.prank(user2);
        project.lockInVault{value: 3 ether}(2 days);

        // Verify total balance
        assertEq(project.vaultBalance(), 5 ether);

        // Verify unlock time updated to latest
        assertEq(project.vaultUnlockTime(), 1000 + 2 days);
    }

    /*//////////////////////////////////////////////////////////////
                        RATE LIMITER TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test first action always succeeds
     * @dev First call has lastActionTime = 0, so check passes
     */
    function testFirstActionSucceeds() public {
        // First action should succeed
        vm.prank(user1);
        project.performRateLimitedAction();

        // Verify lastActionTime was updated
        assertEq(project.lastActionTime(user1), block.timestamp);
    }

    /**
     * @notice Test cannot perform action twice within rate limit
     * @dev Demonstrates rate limiting enforcement
     */
    function testCannotBypassRateLimit() public {
        // First action succeeds
        vm.prank(user1);
        project.performRateLimitedAction();

        // Second action immediately fails
        vm.prank(user1);
        vm.expectRevert(Project13Solution.RateLimitActive.selector);
        project.performRateLimitedAction();

        // Advance time by 30 minutes (still within 1 hour limit)
        vm.warp(block.timestamp + 30 minutes);

        // Still should fail
        vm.prank(user1);
        vm.expectRevert(Project13Solution.RateLimitActive.selector);
        project.performRateLimitedAction();
    }

    /**
     * @notice Test can perform action after rate limit expires
     * @dev Demonstrates time-based access control
     */
    function testCanActAfterRateLimit() public {
        // First action
        vm.prank(user1);
        project.performRateLimitedAction();

        uint256 firstActionTime = block.timestamp;

        // Advance time by exactly 1 hour
        vm.warp(block.timestamp + RATE_LIMIT);

        // Second action should succeed
        vm.prank(user1);
        project.performRateLimitedAction();

        // Verify timestamp updated
        assertEq(project.lastActionTime(user1), firstActionTime + RATE_LIMIT);
    }

    /**
     * @notice Test getRemainingCooldown calculation
     * @dev Tests view function for UI feedback
     */
    function testGetRemainingCooldown() public {
        // Before any action, cooldown is 0
        assertEq(project.getRemainingCooldown(user1), 0);

        // Perform action
        vm.prank(user1);
        project.performRateLimitedAction();

        // Remaining time should be full duration
        assertEq(project.getRemainingCooldown(user1), RATE_LIMIT);

        // Advance 30 minutes
        vm.warp(block.timestamp + 30 minutes);

        // Remaining should be 30 minutes
        assertEq(project.getRemainingCooldown(user1), 30 minutes);

        // Advance to exactly limit
        vm.warp(block.timestamp + 30 minutes);

        // Remaining should be 0
        assertEq(project.getRemainingCooldown(user1), 0);
    }

    /**
     * @notice Test rate limits are per-user
     * @dev Different users have independent rate limits
     */
    function testRateLimitPerUser() public {
        // User1 performs action
        vm.prank(user1);
        project.performRateLimitedAction();

        // User1 cannot perform again
        vm.prank(user1);
        vm.expectRevert(Project13Solution.RateLimitActive.selector);
        project.performRateLimitedAction();

        // But user2 can perform (different rate limit)
        vm.prank(user2);
        project.performRateLimitedAction(); // Should succeed

        // Verify both users have different timestamps
        assertEq(project.lastActionTime(user1), project.lastActionTime(user2));
    }

    /*//////////////////////////////////////////////////////////////
                         COOLDOWN TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test initiating cooldown
     */
    function testInitiateCooldown() public {
        vm.prank(user1);
        project.initiateCooldown();

        // Verify cooldown state
        assertTrue(project.cooldownActive(user1));
        assertEq(project.cooldownStart(user1), block.timestamp);
    }

    /**
     * @notice Test cannot initiate cooldown twice
     */
    function testCannotInitiateCooldownTwice() public {
        // First initiation succeeds
        vm.prank(user1);
        project.initiateCooldown();

        // Second initiation fails
        vm.prank(user1);
        vm.expectRevert(Project13Solution.CooldownAlreadyActive.selector);
        project.initiateCooldown();
    }

    /**
     * @notice Test cannot execute before cooldown initiated
     */
    function testCannotExecuteWithoutInitiation() public {
        vm.prank(user1);
        vm.expectRevert(Project13Solution.CooldownNotInitiated.selector);
        project.executeAfterCooldown();
    }

    /**
     * @notice Test cannot execute before cooldown finishes
     */
    function testCannotExecuteBeforeCooldownFinishes() public {
        // Initiate cooldown
        vm.prank(user1);
        project.initiateCooldown();

        // Try to execute immediately
        vm.prank(user1);
        vm.expectRevert(Project13Solution.CooldownNotFinished.selector);
        project.executeAfterCooldown();

        // Advance 3 days (not enough)
        vm.warp(block.timestamp + 3 days);

        // Still should fail
        vm.prank(user1);
        vm.expectRevert(Project13Solution.CooldownNotFinished.selector);
        project.executeAfterCooldown();
    }

    /**
     * @notice Test can execute after cooldown finishes
     * @dev Demonstrates two-step process with time delay
     */
    function testExecuteAfterCooldown() public {
        // Initiate cooldown
        vm.prank(user1);
        project.initiateCooldown();

        uint256 cooldownStartTime = block.timestamp;

        // Advance exactly 7 days
        vm.warp(block.timestamp + COOLDOWN);

        // Execute should succeed
        vm.prank(user1);
        project.executeAfterCooldown();

        // Verify state reset
        assertFalse(project.cooldownActive(user1));
        assertEq(project.cooldownStart(user1), 0);
    }

    /**
     * @notice Test can initiate new cooldown after completing previous
     */
    function testCanInitiateNewCooldownAfterCompletion() public {
        // First cooldown cycle
        vm.prank(user1);
        project.initiateCooldown();

        vm.warp(block.timestamp + COOLDOWN);

        vm.prank(user1);
        project.executeAfterCooldown();

        // Should be able to initiate new cooldown
        vm.prank(user1);
        project.initiateCooldown();

        assertTrue(project.cooldownActive(user1));
    }

    /*//////////////////////////////////////////////////////////////
                        VESTING WALLET TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test initializing vesting
     */
    function testInitializeVesting() public {
        uint256 totalAmount = 1000 ether;
        uint256 duration = 365 days;

        project.initializeVesting(user1, totalAmount, duration);

        // Verify vesting parameters
        assertEq(project.vestingBeneficiary(), user1);
        assertEq(project.vestingTotalAmount(), totalAmount);
        assertEq(project.vestingDuration(), duration);
        assertEq(project.vestingStartTime(), block.timestamp);
        assertEq(project.vestingReleased(), 0);
    }

    /**
     * @notice Test vesting calculation before start
     */
    function testVestingBeforeStart() public {
        // Initialize vesting
        project.initializeVesting(user1, 1000 ether, 100 days);

        // Go back in time (before vesting starts)
        vm.warp(block.timestamp - 1 days);

        // Should return 0
        assertEq(project.calculateVestedAmount(), 0);
    }

    /**
     * @notice Test vesting calculation during vesting period
     * @dev Demonstrates linear vesting math
     */
    function testVestingDuringPeriod() public {
        uint256 totalAmount = 1000 ether;
        uint256 duration = 100 days;

        project.initializeVesting(user1, totalAmount, duration);

        // After 25 days, 25% should be vested
        vm.warp(block.timestamp + 25 days);
        assertEq(project.calculateVestedAmount(), 250 ether);

        // After 50 days, 50% should be vested
        vm.warp(block.timestamp + 25 days); // Total 50 days
        assertEq(project.calculateVestedAmount(), 500 ether);

        // After 75 days, 75% should be vested
        vm.warp(block.timestamp + 25 days); // Total 75 days
        assertEq(project.calculateVestedAmount(), 750 ether);
    }

    /**
     * @notice Test vesting calculation after period ends
     */
    function testVestingAfterPeriod() public {
        uint256 totalAmount = 1000 ether;
        uint256 duration = 100 days;

        project.initializeVesting(user1, totalAmount, duration);

        // After exactly 100 days
        vm.warp(block.timestamp + duration);
        assertEq(project.calculateVestedAmount(), totalAmount);

        // After 200 days (well past end)
        vm.warp(block.timestamp + 100 days);
        assertEq(project.calculateVestedAmount(), totalAmount);
    }

    /**
     * @notice Test releasing vested tokens
     */
    function testReleaseVestedTokens() public {
        uint256 totalAmount = 1000 ether;
        uint256 duration = 100 days;

        project.initializeVesting(user1, totalAmount, duration);

        // Advance 25 days (25% vested)
        vm.warp(block.timestamp + 25 days);

        // Release tokens
        uint256 released = project.releaseVestedTokens();

        // Verify 250 ether released
        assertEq(released, 250 ether);
        assertEq(project.vestingReleased(), 250 ether);
    }

    /**
     * @notice Test cannot release same tokens twice
     */
    function testCannotReleaseTokensTwice() public {
        project.initializeVesting(user1, 1000 ether, 100 days);

        // Advance 25 days
        vm.warp(block.timestamp + 25 days);

        // Release once (succeeds)
        project.releaseVestedTokens();

        // Try to release again immediately (fails - no new vesting)
        vm.expectRevert(Project13Solution.NoTokensToRelease.selector);
        project.releaseVestedTokens();
    }

    /**
     * @notice Test incremental token releases
     * @dev Simulates multiple claims over vesting period
     */
    function testIncrementalReleases() public {
        project.initializeVesting(user1, 1000 ether, 100 days);

        // Release after 25 days
        vm.warp(block.timestamp + 25 days);
        uint256 release1 = project.releaseVestedTokens();
        assertEq(release1, 250 ether);

        // Release after another 25 days (total 50 days)
        vm.warp(block.timestamp + 25 days);
        uint256 release2 = project.releaseVestedTokens();
        assertEq(release2, 250 ether); // Another 25%

        // Release after another 50 days (total 100 days)
        vm.warp(block.timestamp + 50 days);
        uint256 release3 = project.releaseVestedTokens();
        assertEq(release3, 500 ether); // Final 50%

        // Verify total released
        assertEq(project.vestingReleased(), 1000 ether);
    }

    /*//////////////////////////////////////////////////////////////
                    BLOCK-BASED LOTTERY TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test starting a lottery
     * @dev Demonstrates vm.roll() for block manipulation
     */
    function testStartLottery() public {
        uint256 duration = 100; // blocks

        project.startLottery(duration);

        assertEq(project.lotteryStartBlock(), block.number);
        assertEq(project.lotteryEndBlock(), block.number + duration);
        assertEq(project.getParticipantCount(), 0);
        assertTrue(project.isLotteryActive());
    }

    /**
     * @notice Test entering lottery
     */
    function testEnterLottery() public {
        // Start lottery
        project.startLottery(100);

        // User1 enters
        vm.prank(user1);
        project.enterLottery();

        // Verify entry
        assertTrue(project.hasEntered(user1));
        assertEq(project.getParticipantCount(), 1);
    }

    /**
     * @notice Test cannot enter lottery twice
     */
    function testCannotEnterTwice() public {
        project.startLottery(100);

        // First entry succeeds
        vm.prank(user1);
        project.enterLottery();

        // Second entry fails
        vm.prank(user1);
        vm.expectRevert(Project13Solution.AlreadyEntered.selector);
        project.enterLottery();
    }

    /**
     * @notice Test cannot enter before lottery starts
     */
    function testCannotEnterBeforeStart() public {
        // Start lottery at block 100
        vm.roll(100);
        project.startLottery(50);

        // Go back to block 99
        vm.roll(99);

        // Try to enter (should fail)
        vm.prank(user1);
        vm.expectRevert(Project13Solution.LotteryNotActive.selector);
        project.enterLottery();
    }

    /**
     * @notice Test cannot enter after lottery ends
     * @dev Demonstrates block.number boundary checking
     */
    function testCannotEnterAfterEnd() public {
        // Start lottery at block 100, duration 50 blocks
        vm.roll(100);
        project.startLottery(50);
        // Lottery runs from block 100 to 149 (inclusive)
        // Ends at block 150

        // Advance to block 150 (past end)
        vm.roll(150);

        // Try to enter (should fail)
        vm.prank(user1);
        vm.expectRevert(Project13Solution.LotteryNotActive.selector);
        project.enterLottery();
    }

    /**
     * @notice Test multiple participants
     */
    function testMultipleParticipants() public {
        project.startLottery(100);

        // Three users enter
        vm.prank(user1);
        project.enterLottery();

        vm.prank(user2);
        project.enterLottery();

        vm.prank(user3);
        project.enterLottery();

        // Verify count
        assertEq(project.getParticipantCount(), 3);

        // Verify all entered
        assertTrue(project.hasEntered(user1));
        assertTrue(project.hasEntered(user2));
        assertTrue(project.hasEntered(user3));

        // Verify participants array
        address[] memory participants = project.getParticipants();
        assertEq(participants.length, 3);
        assertEq(participants[0], user1);
        assertEq(participants[1], user2);
        assertEq(participants[2], user3);
    }

    /**
     * @notice Test selecting winner
     * @dev Uses vm.roll() to advance blocks
     */
    function testSelectWinner() public {
        // Start lottery at block 100
        vm.roll(100);
        project.startLottery(50);

        // Users enter
        vm.prank(user1);
        project.enterLottery();

        vm.prank(user2);
        project.enterLottery();

        vm.prank(user3);
        project.enterLottery();

        // Advance to end block
        vm.roll(150);

        // Select winner
        project.selectWinner();

        // Verify a winner was selected
        address winner = project.lotteryWinner();
        assertTrue(winner == user1 || winner == user2 || winner == user3);
    }

    /**
     * @notice Test cannot select winner before lottery ends
     */
    function testCannotSelectWinnerEarly() public {
        vm.roll(100);
        project.startLottery(50);

        vm.prank(user1);
        project.enterLottery();

        // Try to select winner before end (block 149)
        vm.roll(149);
        vm.expectRevert(Project13Solution.LotteryNotEnded.selector);
        project.selectWinner();
    }

    /**
     * @notice Test cannot select winner with no participants
     */
    function testCannotSelectWinnerWithNoParticipants() public {
        vm.roll(100);
        project.startLottery(50);

        // Advance to end without any participants
        vm.roll(150);

        vm.expectRevert(Project13Solution.NoParticipants.selector);
        project.selectWinner();
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTION TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test getCurrentTimestamp
     */
    function testGetCurrentTimestamp() public {
        assertEq(project.getCurrentTimestamp(), block.timestamp);

        vm.warp(5000);
        assertEq(project.getCurrentTimestamp(), 5000);
    }

    /**
     * @notice Test getCurrentBlockNumber
     */
    function testGetCurrentBlockNumber() public {
        assertEq(project.getCurrentBlockNumber(), block.number);

        vm.roll(500);
        assertEq(project.getCurrentBlockNumber(), 500);
    }

    /**
     * @notice Test isVaultLocked
     */
    function testIsVaultLocked() public {
        // Initially not locked (unlockTime = 0)
        assertFalse(project.isVaultLocked());

        // Lock for 1 day
        project.lockInVault{value: 1 ether}(1 days);

        // Should be locked
        assertTrue(project.isVaultLocked());

        // Advance time past unlock
        vm.warp(block.timestamp + 1 days);

        // Should be unlocked
        assertFalse(project.isVaultLocked());
    }

    /**
     * @notice Test isLotteryActive
     */
    function testIsLotteryActive() public {
        // Not active initially
        assertFalse(project.isLotteryActive());

        // Start lottery
        vm.roll(100);
        project.startLottery(50);

        // Should be active
        assertTrue(project.isLotteryActive());

        // Advance to end block
        vm.roll(150);

        // Should not be active
        assertFalse(project.isLotteryActive());
    }

    /*//////////////////////////////////////////////////////////////
                        EDGE CASE TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test zero-duration lock
     */
    function testZeroDurationLock() public {
        project.lockInVault{value: 1 ether}(0);

        // Should be immediately withdrawable
        project.withdrawFromVault();
        assertEq(project.vaultBalance(), 0);
    }

    /**
     * @notice Test very long vesting period
     */
    function testLongVestingPeriod() public {
        uint256 veryLongDuration = 10 * 365 days; // 10 years
        project.initializeVesting(user1, 1000 ether, veryLongDuration);

        // After 1 year, should have vested 10%
        vm.warp(block.timestamp + 365 days);
        assertEq(project.calculateVestedAmount(), 100 ether);
    }

    /**
     * @notice Test lottery with single participant
     */
    function testLotteryWithSingleParticipant() public {
        vm.roll(100);
        project.startLottery(50);

        vm.prank(user1);
        project.enterLottery();

        vm.roll(150);
        project.selectWinner();

        // Only participant must be winner
        assertEq(project.lotteryWinner(), user1);
    }

    /*//////////////////////////////////////////////////////////////
                        FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Fuzz test vesting calculation
     * @dev Tests vesting with random values
     */
    function testFuzzVestingCalculation(
        uint256 totalAmount,
        uint256 duration,
        uint256 timeElapsed
    ) public {
        // Bound inputs to reasonable ranges
        totalAmount = bound(totalAmount, 1 ether, 1_000_000 ether);
        duration = bound(duration, 1 days, 10 * 365 days);
        timeElapsed = bound(timeElapsed, 0, duration * 2);

        // Initialize vesting
        project.initializeVesting(user1, totalAmount, duration);

        // Advance time
        vm.warp(block.timestamp + timeElapsed);

        // Calculate vested amount
        uint256 vested = project.calculateVestedAmount();

        // Assertions
        if (timeElapsed >= duration) {
            // Fully vested
            assertEq(vested, totalAmount);
        } else {
            // Partially vested
            uint256 expected = (totalAmount * timeElapsed) / duration;
            assertEq(vested, expected);
            assertLe(vested, totalAmount);
        }
    }

    /**
     * @notice Fuzz test rate limit
     */
    function testFuzzRateLimit(uint256 timeAdvance) public {
        // Bound to reasonable range
        timeAdvance = bound(timeAdvance, 0, 10 days);

        // First action
        vm.prank(user1);
        project.performRateLimitedAction();

        // Advance time
        vm.warp(block.timestamp + timeAdvance);

        // Try second action
        vm.prank(user1);
        if (timeAdvance >= RATE_LIMIT) {
            // Should succeed
            project.performRateLimitedAction();
        } else {
            // Should fail
            vm.expectRevert(Project13Solution.RateLimitActive.selector);
            project.performRateLimitedAction();
        }
    }

    /*//////////////////////////////////////////////////////////////
                        HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Helper to receive ETH
     */
    receive() external payable {}
}
