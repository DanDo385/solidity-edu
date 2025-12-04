// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/VaultInsolvencySolution.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Token", "MOCK") {
        _mint(msg.sender, 1_000_000 * 10 ** 18);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract VaultInsolvencyTest is Test {
    VaultInsolvencySolution public vault;
    RiskyStrategySolution public strategy;
    MockERC20 public token;

    address public owner = address(this);
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public carol = address(0x3);

    uint256 constant INITIAL_BALANCE = 10_000 * 10 ** 18;

    event Deposited(address indexed user, uint256 assets, uint256 shares);
    event Withdrawn(address indexed user, uint256 shares, uint256 assets);
    event EmergencyTriggered(uint256 timestamp, uint256 totalAssets, uint256 lossPercentage);
    event LossDetected(uint256 lossAmount, uint256 lossPercentage);
    event ModeChanged(
        VaultInsolvencySolution.Mode oldMode, VaultInsolvencySolution.Mode newMode
    );

    function setUp() public {
        // Deploy token
        token = new MockERC20();

        // Deploy strategy
        strategy = new RiskyStrategySolution(address(token));

        // Deploy vault
        vault = new VaultInsolvencySolution(address(token), address(strategy));

        // Setup test users
        token.mint(alice, INITIAL_BALANCE);
        token.mint(bob, INITIAL_BALANCE);
        token.mint(carol, INITIAL_BALANCE);

        // Approve vault
        vm.prank(alice);
        token.approve(address(vault), type(uint256).max);

        vm.prank(bob);
        token.approve(address(vault), type(uint256).max);

        vm.prank(carol);
        token.approve(address(vault), type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////
                           BASIC OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function test_Deposit() public {
        uint256 depositAmount = 1000 * 10 ** 18;

        vm.prank(alice);
        uint256 shares = vault.deposit(depositAmount);

        assertEq(shares, depositAmount, "First deposit should be 1:1");
        assertEq(vault.shares(alice), shares, "Shares minted incorrectly");
        assertEq(vault.totalAssets(), depositAmount, "Total assets wrong");
    }

    function test_DepositMultipleUsers() public {
        // Alice deposits first
        vm.prank(alice);
        uint256 aliceShares = vault.deposit(1000 * 10 ** 18);

        // Bob deposits
        vm.prank(bob);
        uint256 bobShares = vault.deposit(1000 * 10 ** 18);

        assertEq(aliceShares, bobShares, "Equal deposits should get equal shares");
        assertEq(vault.totalAssets(), 2000 * 10 ** 18, "Total assets should be sum");
    }

    function test_Withdraw() public {
        // Alice deposits
        vm.prank(alice);
        uint256 shares = vault.deposit(1000 * 10 ** 18);

        // Alice withdraws
        uint256 balanceBefore = token.balanceOf(alice);

        vm.prank(alice);
        uint256 assets = vault.withdraw(shares);

        uint256 balanceAfter = token.balanceOf(alice);

        assertEq(assets, 1000 * 10 ** 18, "Should withdraw full amount");
        assertEq(balanceAfter - balanceBefore, assets, "Balance should increase");
        assertEq(vault.shares(alice), 0, "Shares should be burned");
    }

    function test_ConvertToShares() public {
        // First deposit
        vm.prank(alice);
        vault.deposit(1000 * 10 ** 18);

        // Check conversion
        uint256 shares = vault.convertToShares(500 * 10 ** 18);
        assertEq(shares, 500 * 10 ** 18, "Conversion should be 1:1 without losses");
    }

    function test_ConvertToAssets() public {
        // Alice deposits
        vm.prank(alice);
        uint256 shares = vault.deposit(1000 * 10 ** 18);

        // Check conversion
        uint256 assets = vault.convertToAssets(shares);
        assertEq(assets, 1000 * 10 ** 18, "Conversion should be 1:1 without losses");
    }

    /*//////////////////////////////////////////////////////////////
                          LOSS SCENARIOS
    //////////////////////////////////////////////////////////////*/

    function test_SmallLoss_10Percent() public {
        // Setup: Alice and Bob deposit
        vm.prank(alice);
        vault.deposit(1000 * 10 ** 18);

        vm.prank(bob);
        vault.deposit(1000 * 10 ** 18);

        // Total assets: 2000
        assertEq(vault.totalAssets(), 2000 * 10 ** 18);

        // Simulate 10% loss in strategy
        uint256 loss = 200 * 10 ** 18; // 10% of 2000
        strategy.simulateLoss(loss);

        // Total assets should now be 1800
        assertEq(vault.totalAssets(), 1800 * 10 ** 18);

        // Loss percentage should be 10% (1000 basis points)
        uint256 lossPercentage = vault.calculateLoss();
        assertEq(lossPercentage, 1000, "Loss should be 10%");
    }

    function test_ModeChange_OnSignificantLoss() public {
        // Alice deposits
        vm.prank(alice);
        vault.deposit(1000 * 10 ** 18);

        // Fast forward time for health check
        vm.warp(block.timestamp + 2 hours);

        // Simulate 15% loss (above threshold)
        strategy.simulateLoss(150 * 10 ** 18);

        // Trigger health check via deposit attempt
        vm.prank(bob);
        vm.expectRevert(); // Should revert as mode changed
        vault.deposit(100 * 10 ** 18);
    }

    function test_EmergencyWithdrawal_ProportionalDistribution() public {
        // Setup: Three users deposit equal amounts
        vm.prank(alice);
        uint256 aliceShares = vault.deposit(1000 * 10 ** 18);

        vm.prank(bob);
        uint256 bobShares = vault.deposit(1000 * 10 ** 18);

        vm.prank(carol);
        uint256 carolShares = vault.deposit(1000 * 10 ** 18);

        // Total: 3000 tokens
        assertEq(vault.totalAssets(), 3000 * 10 ** 18);

        // Simulate 30% loss
        strategy.simulateLoss(900 * 10 ** 18);

        // Remaining: 2100 tokens
        assertEq(vault.totalAssets(), 2100 * 10 ** 18);

        // Trigger emergency mode
        vault.triggerEmergency();

        // Each user should get proportional amount (700 tokens each)
        vm.prank(alice);
        uint256 aliceReceived = vault.withdraw(aliceShares);
        assertEq(aliceReceived, 700 * 10 ** 18, "Alice should get 1/3 of remaining");

        vm.prank(bob);
        uint256 bobReceived = vault.withdraw(bobShares);
        assertEq(bobReceived, 700 * 10 ** 18, "Bob should get 1/3 of remaining");

        vm.prank(carol);
        uint256 carolReceived = vault.withdraw(carolShares);
        assertEq(carolReceived, 700 * 10 ** 18, "Carol should get 1/3 of remaining");

        // All funds should be withdrawn
        assertApproxEqAbs(vault.totalAssets(), 0, 1, "Vault should be empty");
    }

    function test_LossSocialization_Fair() public {
        // Alice deposits 2000
        vm.prank(alice);
        vault.deposit(2000 * 10 ** 18);

        // Bob deposits 1000
        vm.prank(bob);
        vault.deposit(1000 * 10 ** 18);

        // Total: 3000, Alice has 2/3, Bob has 1/3

        // Simulate 30% loss (900 tokens lost)
        strategy.simulateLoss(900 * 10 ** 18);
        // Remaining: 2100 tokens

        vault.triggerEmergency();

        // Alice should get 2/3 of 2100 = 1400
        uint256 aliceBalance = vault.balanceOf(alice);
        assertEq(aliceBalance, 1400 * 10 ** 18, "Alice should get 2/3");

        // Bob should get 1/3 of 2100 = 700
        uint256 bobBalance = vault.balanceOf(bob);
        assertEq(bobBalance, 700 * 10 ** 18, "Bob should get 1/3");

        // Verify loss info
        (uint256 expectedAlice, uint256 actualAlice, uint256 lossAlice) =
            vault.getUserLossInfo(alice);

        assertEq(expectedAlice, 2000 * 10 ** 18, "Alice expected 2000");
        assertEq(actualAlice, 1400 * 10 ** 18, "Alice actual 1400");
        assertEq(lossAlice, 600 * 10 ** 18, "Alice lost 600");
    }

    /*//////////////////////////////////////////////////////////////
                        EMERGENCY SCENARIOS
    //////////////////////////////////////////////////////////////*/

    function test_TriggerEmergency_ManuallyByOwner() public {
        vm.prank(alice);
        vault.deposit(1000 * 10 ** 18);

        // Simulate loss
        strategy.simulateLoss(200 * 10 ** 18);

        // Owner triggers emergency
        vm.expectEmit(true, true, true, true);
        emit ModeChanged(VaultInsolvencySolution.Mode.NORMAL, VaultInsolvencySolution.Mode.EMERGENCY);

        vault.triggerEmergency();

        // Verify mode changed
        (VaultInsolvencySolution.Mode mode,,,, bool isSolvent) = vault.getVaultStatus();
        assertEq(uint256(mode), uint256(VaultInsolvencySolution.Mode.EMERGENCY));
    }

    function test_EmergencyMode_DepositsBlocked() public {
        vm.prank(alice);
        vault.deposit(1000 * 10 ** 18);

        // Trigger emergency
        vault.triggerEmergency();

        // Try to deposit - should fail
        vm.prank(bob);
        vm.expectRevert();
        vault.deposit(500 * 10 ** 18);
    }

    function test_EmergencyMode_WithdrawalsWork() public {
        vm.prank(alice);
        uint256 shares = vault.deposit(1000 * 10 ** 18);

        // Trigger emergency
        vault.triggerEmergency();

        // Withdrawals should still work (proportional)
        vm.prank(alice);
        uint256 assets = vault.withdraw(shares);

        // Should get proportional amount
        assertGt(assets, 0, "Should receive some assets");
    }

    function test_Freeze_AllOperationsBlocked() public {
        vm.prank(alice);
        uint256 shares = vault.deposit(1000 * 10 ** 18);

        // Freeze vault
        vault.freeze();

        // Deposits should fail
        vm.prank(bob);
        vm.expectRevert();
        vault.deposit(500 * 10 ** 18);

        // Withdrawals should also fail
        vm.prank(alice);
        vm.expectRevert();
        vault.withdraw(shares);
    }

    /*//////////////////////////////////////////////////////////////
                         RECOVERY SCENARIOS
    //////////////////////////////////////////////////////////////*/

    function test_RecoveryFromStrategy() public {
        vm.prank(alice);
        vault.deposit(1000 * 10 ** 18);

        // Simulate loss
        strategy.simulateLoss(200 * 10 ** 18);

        // Trigger emergency
        vault.triggerEmergency();

        // Attempt recovery
        vault.recoverFromStrategy();

        // Check that funds are in vault
        uint256 vaultBalance = token.balanceOf(address(vault));
        assertGt(vaultBalance, 0, "Should recover funds to vault");
    }

    function test_ResumeNormal_AfterRecovery() public {
        vm.prank(alice);
        vault.deposit(1000 * 10 ** 18);

        // Small loss
        strategy.simulateLoss(30 * 10 ** 18); // 3% loss

        // Pause deposits
        vault.pauseDeposits();

        // Verify mode is PAUSED
        (VaultInsolvencySolution.Mode mode,,,, bool isSolvent) = vault.getVaultStatus();
        assertEq(uint256(mode), uint256(VaultInsolvencySolution.Mode.PAUSED));

        // Reset loss (simulate recovery)
        strategy.resetLoss();

        // Resume normal operations
        vault.resumeNormal();

        // Verify mode is NORMAL
        (mode,,,, isSolvent) = vault.getVaultStatus();
        assertEq(uint256(mode), uint256(VaultInsolvencySolution.Mode.NORMAL));

        // Deposits should work again
        vm.prank(bob);
        vault.deposit(500 * 10 ** 18);
    }

    /*//////////////////////////////////////////////////////////////
                        CATASTROPHIC SCENARIOS
    //////////////////////////////////////////////////////////////*/

    function test_CatastrophicLoss_50Percent() public {
        // Multiple users deposit
        vm.prank(alice);
        vault.deposit(1000 * 10 ** 18);

        vm.prank(bob);
        vault.deposit(1000 * 10 ** 18);

        vm.prank(carol);
        vault.deposit(1000 * 10 ** 18);

        // Total: 3000 tokens

        // Catastrophic 50% loss
        strategy.simulateLoss(1500 * 10 ** 18);

        // Remaining: 1500 tokens
        assertEq(vault.totalAssets(), 1500 * 10 ** 18);

        // Trigger emergency
        vault.triggerEmergency();

        // Each user deposited 1/3, should get 1/3 of remaining
        vm.prank(alice);
        uint256 aliceGets = vault.withdraw(vault.shares(alice));
        assertEq(aliceGets, 500 * 10 ** 18, "Should get 500");

        vm.prank(bob);
        uint256 bobGets = vault.withdraw(vault.shares(bob));
        assertEq(bobGets, 500 * 10 ** 18, "Should get 500");

        vm.prank(carol);
        uint256 carolGets = vault.withdraw(vault.shares(carol));
        assertEq(carolGets, 500 * 10 ** 18, "Should get 500");
    }

    function test_TotalLoss_VaultWorthless() public {
        vm.prank(alice);
        uint256 shares = vault.deposit(1000 * 10 ** 18);

        // 100% loss
        strategy.simulateLoss(1000 * 10 ** 18);

        // Total assets should be 0
        assertEq(vault.totalAssets(), 0);

        // Trigger emergency
        vault.triggerEmergency();

        // Withdrawal should return 0
        vm.prank(alice);
        uint256 assets = vault.withdraw(shares);

        assertEq(assets, 0, "Should receive nothing");
    }

    /*//////////////////////////////////////////////////////////////
                         CIRCUIT BREAKERS
    //////////////////////////////////////////////////////////////*/

    function test_AutomaticEmergencyTrigger() public {
        vm.prank(alice);
        vault.deposit(1000 * 10 ** 18);

        // Record initial mode
        (VaultInsolvencySolution.Mode modeBefore,,,, bool isSolvent) = vault.getVaultStatus();
        assertEq(uint256(modeBefore), uint256(VaultInsolvencySolution.Mode.NORMAL));

        // Fast forward for health check
        vm.warp(block.timestamp + 2 hours);

        // Cause significant loss (15%)
        strategy.simulateLoss(150 * 10 ** 18);

        // Trigger health check by trying deposit
        vm.prank(bob);
        vm.expectRevert(); // Should fail as mode changed
        vault.deposit(100 * 10 ** 18);
    }

    function test_CheckSolvency() public {
        vm.prank(alice);
        vault.deposit(1000 * 10 ** 18);

        // Initially solvent
        assertTrue(vault.checkSolvency(), "Should be solvent");

        // Small loss - still solvent
        strategy.simulateLoss(30 * 10 ** 18);
        assertTrue(vault.checkSolvency(), "Should still be solvent");

        // Large loss - insolvent
        strategy.simulateLoss(100 * 10 ** 18); // Total 13% loss
        // Depending on threshold, might be insolvent
    }

    /*//////////////////////////////////////////////////////////////
                           EDGE CASES
    //////////////////////////////////////////////////////////////*/

    function test_FirstDepositor() public {
        // First deposit should be 1:1
        vm.prank(alice);
        uint256 shares = vault.deposit(1 * 10 ** 18);

        assertEq(shares, 1 * 10 ** 18, "First deposit should be 1:1");
    }

    function test_LastWithdrawer() public {
        // Alice deposits
        vm.prank(alice);
        uint256 aliceShares = vault.deposit(1000 * 10 ** 18);

        // Bob deposits
        vm.prank(bob);
        uint256 bobShares = vault.deposit(1000 * 10 ** 18);

        // Alice withdraws
        vm.prank(alice);
        vault.withdraw(aliceShares);

        // Bob (last withdrawer) should still get fair share
        uint256 bobBalanceBefore = token.balanceOf(bob);

        vm.prank(bob);
        vault.withdraw(bobShares);

        uint256 bobBalanceAfter = token.balanceOf(bob);

        assertEq(
            bobBalanceAfter - bobBalanceBefore, 1000 * 10 ** 18, "Last withdrawer should get full amount"
        );
    }

    function test_MultipleSequentialLosses() public {
        vm.prank(alice);
        vault.deposit(1000 * 10 ** 18);

        // First loss: 10%
        strategy.simulateLoss(100 * 10 ** 18);
        assertEq(vault.totalAssets(), 900 * 10 ** 18);

        // Second loss: 10% of remaining
        strategy.simulateLoss(90 * 10 ** 18);
        assertEq(vault.totalAssets(), 810 * 10 ** 18);

        // Third loss: 10% of remaining
        strategy.simulateLoss(81 * 10 ** 18);
        assertEq(vault.totalAssets(), 729 * 10 ** 18);

        // Total loss should be about 27%
        uint256 loss = vault.calculateLoss();
        assertGt(loss, 2000, "Should show significant loss");
    }

    function test_ZeroSharesEdgeCase() public {
        // Try to withdraw 0 shares
        vm.prank(alice);
        vm.expectRevert();
        vault.withdraw(0);
    }

    function test_InsufficientSharesRevert() public {
        vm.prank(alice);
        vault.deposit(100 * 10 ** 18);

        // Try to withdraw more shares than owned
        vm.prank(alice);
        vm.expectRevert();
        vault.withdraw(200 * 10 ** 18);
    }

    /*//////////////////////////////////////////////////////////////
                          VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function test_GetVaultStatus() public {
        vm.prank(alice);
        vault.deposit(1000 * 10 ** 18);

        (
            VaultInsolvencySolution.Mode mode,
            uint256 totalAssetsValue,
            uint256 totalSharesValue,
            uint256 lossPercentage,
            bool isSolvent
        ) = vault.getVaultStatus();

        assertEq(uint256(mode), uint256(VaultInsolvencySolution.Mode.NORMAL));
        assertEq(totalAssetsValue, 1000 * 10 ** 18);
        assertGt(totalSharesValue, 0);
        assertEq(lossPercentage, 0);
        assertTrue(isSolvent);
    }

    function test_GetPricePerShare() public {
        vm.prank(alice);
        vault.deposit(1000 * 10 ** 18);

        uint256 price = vault.getPricePerShare();
        assertEq(price, 1e18, "Price should be 1:1 initially");

        // After 20% loss
        strategy.simulateLoss(200 * 10 ** 18);

        uint256 newPrice = vault.getPricePerShare();
        assertLt(newPrice, price, "Price should decrease after loss");
        assertEq(newPrice, 0.8e18, "Price should be 0.8 after 20% loss");
    }

    function test_GetUserLossInfo() public {
        vm.prank(alice);
        vault.deposit(1000 * 10 ** 18);

        // Simulate 30% loss
        strategy.simulateLoss(300 * 10 ** 18);

        vault.triggerEmergency();

        (uint256 expected, uint256 actual, uint256 loss) = vault.getUserLossInfo(alice);

        assertEq(expected, 1000 * 10 ** 18, "Expected 1000");
        assertEq(actual, 700 * 10 ** 18, "Actual 700");
        assertEq(loss, 300 * 10 ** 18, "Loss 300");
    }

    /*//////////////////////////////////////////////////////////////
                         ACCESS CONTROL
    //////////////////////////////////////////////////////////////*/

    function test_OnlyOwnerCanTriggerEmergency() public {
        vm.prank(alice);
        vm.expectRevert();
        vault.triggerEmergency();
    }

    function test_OnlyOwnerCanFreeze() public {
        vm.prank(alice);
        vm.expectRevert();
        vault.freeze();
    }

    function test_OnlyOwnerCanResumeNormal() public {
        vault.pauseDeposits();

        vm.prank(alice);
        vm.expectRevert();
        vault.resumeNormal();
    }

    /*//////////////////////////////////////////////////////////////
                        REALISTIC SCENARIOS
    //////////////////////////////////////////////////////////////*/

    function test_BankRun_Scenario() public {
        // Setup: Multiple users deposit
        vm.prank(alice);
        vault.deposit(1000 * 10 ** 18);

        vm.prank(bob);
        vault.deposit(1000 * 10 ** 18);

        vm.prank(carol);
        vault.deposit(1000 * 10 ** 18);

        // News of potential issue spreads, users rush to withdraw
        // Alice withdraws first - gets full amount
        vm.prank(alice);
        uint256 aliceGets = vault.withdraw(vault.shares(alice));
        assertEq(aliceGets, 1000 * 10 ** 18, "First out gets full amount");

        // Before Bob can withdraw, strategy suffers loss
        strategy.simulateLoss(500 * 10 ** 18); // 25% of remaining 2000

        // Emergency mode triggered
        vault.triggerEmergency();

        // Bob and Carol get proportional to remaining (1500 / 2 = 750 each)
        vm.prank(bob);
        uint256 bobGets = vault.withdraw(vault.shares(bob));

        vm.prank(carol);
        uint256 carolGets = vault.withdraw(vault.shares(carol));

        assertEq(bobGets, 750 * 10 ** 18, "Bob gets proportional");
        assertEq(carolGets, 750 * 10 ** 18, "Carol gets proportional");
    }

    function test_PartialRecovery_Scenario() public {
        vm.prank(alice);
        vault.deposit(1000 * 10 ** 18);

        // Loss occurs
        strategy.simulateLoss(300 * 10 ** 18);

        // Emergency triggered
        vault.triggerEmergency();

        // Partial recovery (get back 100)
        strategy.resetLoss();
        strategy.simulateLoss(200 * 10 ** 18); // Net loss now 200

        // Attempt recovery
        vault.recoverFromStrategy();

        // Assets should be 800 now
        assertEq(vault.totalAssets(), 800 * 10 ** 18);

        // Alice withdraws in emergency mode
        vm.prank(alice);
        uint256 assets = vault.withdraw(vault.shares(alice));

        assertEq(assets, 800 * 10 ** 18, "Should get recovered amount");
    }
}
