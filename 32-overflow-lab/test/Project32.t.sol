// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/Project32Solution.sol";

/**
 * @title Project 32 Tests: Integer Overflow Labs
 * @notice Comprehensive tests demonstrating overflow vulnerabilities and protections
 * @dev These tests:
 *      1. Reproduce historical exploits (BeautyChain, SMT)
 *      2. Show pre-0.8 vulnerabilities using unchecked
 *      3. Verify SafeMath protections
 *      4. Confirm 0.8+ automatic checking
 *      5. Test edge cases and boundary conditions
 */
contract Project32Test is Test {
    // Contracts under test
    VulnerableToken vulnerableToken;
    SafeToken safeToken;
    ModernToken modernToken;
    UncheckedExamples uncheckedExamples;
    AdvancedOverflowScenarios advancedScenarios;

    // Test accounts
    address alice = address(0x1);
    address bob = address(0x2);
    address charlie = address(0x3);

    // Constants for testing
    uint256 constant INITIAL_SUPPLY = 1000 ether;
    uint256 constant MAX_UINT256 = type(uint256).max;

    function setUp() public {
        // Deploy all contracts
        vulnerableToken = new VulnerableToken(INITIAL_SUPPLY);
        safeToken = new SafeToken(INITIAL_SUPPLY);
        modernToken = new ModernToken(INITIAL_SUPPLY);
        uncheckedExamples = new UncheckedExamples();
        advancedScenarios = new AdvancedOverflowScenarios();

        // Label addresses for better trace output
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(charlie, "Charlie");
    }

    // ============================================================================
    // PART 1: VULNERABLE TOKEN EXPLOITS
    // ============================================================================

    /**
     * @notice Test underflow attack on vulnerable transfer
     * @dev Classic attack: user with 0 balance transfers 1 token
     */
    function testVulnerableTransferUnderflow() public {
        // Setup: Alice has 0 tokens
        assertEq(vulnerableToken.balances(alice), 0);

        // Attack: Alice transfers 1 token (should be impossible)
        vm.prank(alice);
        vulnerableToken.transfer(bob, 1);

        // Result: Alice's balance underflowed to max uint256!
        assertEq(vulnerableToken.balances(alice), MAX_UINT256);
        assertEq(vulnerableToken.balances(bob), 1);

        console.log("EXPLOIT: Alice started with 0 tokens");
        console.log("After transferring 1 token, Alice has:");
        console.log(vulnerableToken.balances(alice));
    }

    /**
     * @notice Test overflow attack on vulnerable transfer
     * @dev Recipient balance can overflow
     */
    function testVulnerableTransferOverflow() public {
        // Setup: Give bob almost max tokens
        vm.store(
            address(vulnerableToken),
            keccak256(abi.encode(bob, 0)),
            bytes32(MAX_UINT256 - 100)
        );
        assertEq(vulnerableToken.balances(bob), MAX_UINT256 - 100);

        // Give deployer some tokens
        vm.store(
            address(vulnerableToken),
            keccak256(abi.encode(address(this), 0)),
            bytes32(uint256(1000))
        );

        // Attack: Send 101 tokens to bob (should overflow)
        vulnerableToken.transfer(bob, 101);

        // Result: Bob's balance overflowed and wrapped around
        // (MAX_UINT256 - 100) + 101 = 1
        assertEq(vulnerableToken.balances(bob), 1);

        console.log("EXPLOIT: Bob had MAX_UINT256 - 100 tokens");
        console.log("After receiving 101 tokens, Bob has:");
        console.log(vulnerableToken.balances(bob));
    }

    /**
     * @notice Reproduce BeautyChain (BEC) exploit
     * @dev Real exploit that crashed a $1B market cap token in 2018
     *
     * THE REAL ATTACK:
     * - BEC token had batchTransfer function
     * - Attacker found: 2 * (2^255) = 0 (overflow)
     * - Called batchTransfer([addr1, addr2], 2^255)
     * - Total = 2 * 2^255 = 0 (overflow!)
     * - Balance check: require(balance >= 0) ✓
     * - Sent 2^255 tokens to each address from nothing
     * - Created ~10^77 tokens, token price crashed to $0
     */
    function testBeautyChainExploit() public {
        // Setup: Attacker (alice) has only 100 tokens
        vm.store(
            address(vulnerableToken),
            keccak256(abi.encode(alice, 0)),
            bytes32(uint256(100))
        );

        // The exploit values
        uint256 value = 2**255;  // Half of max uint256
        address[] memory recipients = new address[](2);
        recipients[0] = bob;
        recipients[1] = charlie;

        console.log("BeautyChain Exploit Setup:");
        console.log("Alice's balance:", vulnerableToken.balances(alice));
        console.log("Value per recipient:", value);
        console.log("Number of recipients:", recipients.length);

        // The attack: 2 * 2^255 overflows to 0
        vm.prank(alice);
        vulnerableToken.batchTransfer(recipients, value);

        // Results: Each recipient got 2^255 tokens from alice who only had 100!
        assertEq(vulnerableToken.balances(bob), value);
        assertEq(vulnerableToken.balances(charlie), value);

        console.log("\nAfter exploit:");
        console.log("Bob's balance:", vulnerableToken.balances(bob));
        console.log("Charlie's balance:", vulnerableToken.balances(charlie));
        console.log("Alice's balance:", vulnerableToken.balances(alice));
    }

    /**
     * @notice Reproduce SMT token exploit
     * @dev Real exploit from April 2018
     *
     * THE REAL ATTACK:
     * - SMT token had transferProxy(from, to, value, fee)
     * - Calculation: total = value + fee
     * - Attacker used: value = MAX_UINT256, fee = 1
     * - Total = MAX_UINT256 + 1 = 0 (overflow!)
     * - Balance check: require(balance >= 0) ✓
     * - Transferred max value with 0 balance requirement
     */
    function testSMTExploit() public {
        // Setup: Attacker (bob) has only 100 tokens
        vm.store(
            address(vulnerableToken),
            keccak256(abi.encode(bob, 0)),
            bytes32(uint256(100))
        );

        // The exploit values
        uint256 value = MAX_UINT256;
        uint256 fee = 1;

        console.log("SMT Exploit Setup:");
        console.log("Bob's balance:", vulnerableToken.balances(bob));
        console.log("Transfer value:", value);
        console.log("Fee:", fee);
        console.log("Total (with overflow):", value + fee);  // This is 0 due to overflow!

        // The attack: MAX_UINT256 + 1 overflows to 0
        vm.prank(bob);
        vulnerableToken.transferProxy(bob, alice, value, fee);

        // Results: Transferred max value even though total calculation was 0
        assertEq(vulnerableToken.balances(alice), value);

        console.log("\nAfter exploit:");
        console.log("Alice received:", vulnerableToken.balances(alice));
    }

    /**
     * @notice Test totalSupply overflow in mint
     * @dev Shows supply tracking can be broken
     */
    function testVulnerableMintOverflow() public {
        // Setup: Set totalSupply to almost max
        vm.store(
            address(vulnerableToken),
            bytes32(uint256(1)),  // totalSupply slot
            bytes32(MAX_UINT256 - 50)
        );

        uint256 beforeSupply = vulnerableToken.totalSupply();

        // Mint 100 tokens (should overflow totalSupply)
        vulnerableToken.mint(alice, 100);

        uint256 afterSupply = vulnerableToken.totalSupply();

        // Result: totalSupply overflowed and wrapped to small number
        assertLt(afterSupply, beforeSupply);
        assertEq(afterSupply, 49);  // (MAX_UINT256 - 50) + 100 = 49

        console.log("Supply before mint:", beforeSupply);
        console.log("Supply after mint:", afterSupply);
        console.log("Supply decreased! (overflow)");
    }

    // ============================================================================
    // PART 2: SAFEMATH PROTECTION TESTS
    // ============================================================================

    /**
     * @notice Test SafeMath prevents addition overflow
     */
    function testSafeMathAdditionOverflow() public {
        uint256 a = MAX_UINT256;
        uint256 b = 1;

        // Should revert with "SafeMath: addition overflow"
        vm.expectRevert("SafeMath: addition overflow");
        SafeMath.add(a, b);
    }

    /**
     * @notice Test SafeMath prevents subtraction underflow
     */
    function testSafeMathSubtractionUnderflow() public {
        uint256 a = 5;
        uint256 b = 10;

        // Should revert with "SafeMath: subtraction underflow"
        vm.expectRevert("SafeMath: subtraction underflow");
        SafeMath.sub(a, b);
    }

    /**
     * @notice Test SafeMath prevents multiplication overflow
     */
    function testSafeMathMultiplicationOverflow() public {
        uint256 a = 2**128;
        uint256 b = 2**128;

        // Should revert with "SafeMath: multiplication overflow"
        vm.expectRevert("SafeMath: multiplication overflow");
        SafeMath.mul(a, b);
    }

    /**
     * @notice Test SafeMath prevents division by zero
     */
    function testSafeMathDivisionByZero() public {
        uint256 a = 100;
        uint256 b = 0;

        // Should revert with "SafeMath: division by zero"
        vm.expectRevert("SafeMath: division by zero");
        SafeMath.div(a, b);
    }

    /**
     * @notice Test SafeMath prevents modulo by zero
     */
    function testSafeMathModuloByZero() public {
        uint256 a = 100;
        uint256 b = 0;

        // Should revert with "SafeMath: modulo by zero"
        vm.expectRevert("SafeMath: modulo by zero");
        SafeMath.mod(a, b);
    }

    /**
     * @notice Test SafeToken prevents underflow attack
     */
    function testSafeTokenPreventsUnderflow() public {
        // Setup: Alice has 0 tokens (not minted any)
        vm.prank(alice);

        // Attack attempt: Transfer 1 token
        vm.expectRevert("SafeMath: subtraction underflow");
        safeToken.transfer(bob, 1);

        // Alice still has 0, attack prevented
        assertEq(safeToken.balances(alice), 0);
    }

    /**
     * @notice Test SafeToken prevents BeautyChain exploit
     */
    function testSafeTokenPreventsBeautyChainExploit() public {
        // Setup: Deployer has initial supply
        uint256 value = 2**255;
        address[] memory recipients = new address[](2);
        recipients[0] = bob;
        recipients[1] = charlie;

        // Attack attempt: Should revert on multiplication overflow
        vm.expectRevert("SafeMath: multiplication overflow");
        safeToken.batchTransfer(recipients, value);
    }

    /**
     * @notice Test SafeToken prevents SMT exploit
     */
    function testSafeTokenPreventsSMTExploit() public {
        uint256 value = MAX_UINT256;
        uint256 fee = 1;

        // Attack attempt: Should revert on addition overflow
        vm.expectRevert("SafeMath: addition overflow");
        safeToken.transferProxy(address(this), alice, value, fee);
    }

    // ============================================================================
    // PART 3: MODERN TOKEN (0.8+ AUTOMATIC CHECKS)
    // ============================================================================

    /**
     * @notice Test 0.8+ prevents underflow automatically
     */
    function testModernTokenPreventsUnderflow() public {
        vm.prank(alice);

        // Automatic check: reverts with panic code 0x11 (arithmetic overflow/underflow)
        vm.expectRevert(stdError.arithmeticError);
        modernToken.transfer(bob, 1);
    }

    /**
     * @notice Test 0.8+ prevents overflow automatically
     */
    function testModernTokenPreventsOverflow() public {
        // Setup: Give bob almost max tokens
        vm.store(
            address(modernToken),
            keccak256(abi.encode(bob, 0)),
            bytes32(MAX_UINT256 - 50)
        );

        // Give deployer some tokens
        vm.store(
            address(modernToken),
            keccak256(abi.encode(address(this), 0)),
            bytes32(uint256(100))
        );

        // Automatic check: reverts on overflow
        vm.expectRevert(stdError.arithmeticError);
        modernToken.transfer(bob, 100);
    }

    /**
     * @notice Test 0.8+ prevents BeautyChain exploit automatically
     */
    function testModernTokenPreventsBeautyChainExploit() public {
        uint256 value = 2**255;
        address[] memory recipients = new address[](2);
        recipients[0] = bob;
        recipients[1] = charlie;

        // Automatic check: multiplication overflow detected
        vm.expectRevert(stdError.arithmeticError);
        modernToken.batchTransfer(recipients, value);
    }

    /**
     * @notice Test 0.8+ prevents SMT exploit automatically
     */
    function testModernTokenPreventsSMTExploit() public {
        uint256 value = MAX_UINT256;
        uint256 fee = 1;

        // Automatic check: addition overflow detected
        vm.expectRevert(stdError.arithmeticError);
        modernToken.transferProxy(address(this), alice, value, fee);
    }

    /**
     * @notice Test normal operations work correctly in 0.8+
     */
    function testModernTokenNormalOperation() public {
        // Transfer works normally when no overflow
        modernToken.transfer(alice, 100);
        assertEq(modernToken.balances(alice), 100);
        assertEq(modernToken.balances(address(this)), INITIAL_SUPPLY - 100);
    }

    // ============================================================================
    // PART 4: UNCHECKED USAGE TESTS
    // ============================================================================

    /**
     * @notice Test safe loop counter usage
     */
    function testSafeLoopCounter() public {
        uint256[] memory data = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) {
            data[i] = i + 1;
        }

        uint256 result = uncheckedExamples.safeLoopCounter(data);
        assertEq(result, 55);  // Sum of 1 to 10
    }

    /**
     * @notice Test safe subtraction with check
     */
    function testSafeSubtractWithCheck() public {
        uint256 result = uncheckedExamples.safeSubtractWithCheck(10, 5);
        assertEq(result, 5);

        // Should revert when b > a
        vm.expectRevert("Underflow");
        uncheckedExamples.safeSubtractWithCheck(5, 10);
    }

    /**
     * @notice Test safe countdown loop
     */
    function testSafeCountdown() public {
        uint256 result = uncheckedExamples.safeCountdown(10);
        assertEq(result, 55);  // Sum of 1 to 10
    }

    /**
     * @notice Test gas difference between checked and unchecked loops
     */
    function testGasDifference() public {
        uint256[] memory data = new uint256[](100);
        for (uint256 i = 0; i < 100; i++) {
            data[i] = i;
        }

        uint256 gasBefore1 = gasleft();
        uncheckedExamples.expensiveLoop(data);
        uint256 gasUsed1 = gasBefore1 - gasleft();

        uint256 gasBefore2 = gasleft();
        uncheckedExamples.cheaperLoop(data);
        uint256 gasUsed2 = gasBefore2 - gasleft();

        console.log("Gas used (checked loop):", gasUsed1);
        console.log("Gas used (unchecked loop):", gasUsed2);
        console.log("Gas saved:", gasUsed1 - gasUsed2);

        // Unchecked should use less gas
        assertLt(gasUsed2, gasUsed1);
    }

    // ============================================================================
    // PART 5: ADVANCED OVERFLOW SCENARIOS
    // ============================================================================

    /**
     * @notice Test time lock overflow vulnerability
     */
    function testTimeLockOverflow() public {
        // Vulnerable version: delay can overflow
        uint256 largeDelay = MAX_UINT256 - block.timestamp + 1;

        vm.prank(alice);
        advancedScenarios.vulnerableSetUnlockTime(largeDelay);

        // Result: Unlock time overflowed to 0 (past timestamp)
        uint256 unlockTime = advancedScenarios.unlockTime(alice);
        assertEq(unlockTime, 0);

        // Alice can withdraw immediately (time lock bypassed!)
        vm.prank(alice);
        advancedScenarios.withdraw();  // Should not revert

        console.log("Time lock bypassed via overflow!");
        console.log("Current timestamp:", block.timestamp);
        console.log("Unlock time:", unlockTime);
    }

    /**
     * @notice Test safe time lock (0.8+ prevents overflow)
     */
    function testSafeTimeLock() public {
        uint256 largeDelay = MAX_UINT256 - block.timestamp + 1;

        vm.prank(alice);
        // Safe version: automatically reverts on overflow
        vm.expectRevert(stdError.arithmeticError);
        advancedScenarios.safeSetUnlockTime(largeDelay);
    }

    /**
     * @notice Test voting overflow vulnerability
     */
    function testVotingOverflow() public {
        uint256 proposalId = 1;

        // First vote: almost max
        advancedScenarios.vulnerableVote(proposalId, MAX_UINT256 - 100);
        assertEq(advancedScenarios.proposalVotes(proposalId), MAX_UINT256 - 100);

        // Second vote: causes overflow
        advancedScenarios.vulnerableVote(proposalId, 200);

        // Result: Vote count overflowed to small number
        assertEq(advancedScenarios.proposalVotes(proposalId), 99);

        console.log("Voting overflow exploit!");
        console.log("Vote count reset from MAX to:", advancedScenarios.proposalVotes(proposalId));
    }

    /**
     * @notice Test safe voting (0.8+ prevents overflow)
     */
    function testSafeVoting() public {
        uint256 proposalId = 2;

        advancedScenarios.safeVote(proposalId, MAX_UINT256 - 100);

        // Safe version: automatically reverts on overflow
        vm.expectRevert(stdError.arithmeticError);
        advancedScenarios.safeVote(proposalId, 200);
    }

    /**
     * @notice Test safe interest calculation
     */
    function testInterestCalculation() public {
        uint256 principal = 1000 ether;
        uint256 rate = 5;  // 5%
        uint256 periods = 10;

        uint256 result = advancedScenarios.calculateInterest(principal, rate, periods);

        // Should be principal + (principal * 5% * 10 periods) = principal + 50%
        assertEq(result, 1500 ether);
    }

    /**
     * @notice Test downcasting overflow (0.8+ protects)
     */
    function testDowncastingOverflow() public {
        // Value fits in uint8
        uint8 result1 = advancedScenarios.downcastingOverflow(255);
        assertEq(result1, 255);

        // Value doesn't fit: reverts in 0.8+
        vm.expectRevert();
        advancedScenarios.downcastingOverflow(256);
    }

    /**
     * @notice Test unsafe downcasting (unchecked truncates)
     */
    function testUnsafeDowncasting() public {
        // Unchecked downcasting truncates
        uint8 result1 = advancedScenarios.unsafeDowncasting(256);
        assertEq(result1, 0);  // Truncated

        uint8 result2 = advancedScenarios.unsafeDowncasting(257);
        assertEq(result2, 1);  // Truncated

        uint8 result3 = advancedScenarios.unsafeDowncasting(511);
        assertEq(result3, 255);  // Truncated
    }

    // ============================================================================
    // PART 6: EDGE CASE TESTS
    // ============================================================================

    /**
     * @notice Test edge case: max uint256 + 1
     */
    function testMaxUint256PlusOne() public {
        uint256 a = MAX_UINT256;
        uint256 b = 1;

        // Checked: reverts
        vm.expectRevert(stdError.arithmeticError);
        uint256 result = a + b;

        // Unchecked: wraps to 0
        unchecked {
            result = a + b;
            assertEq(result, 0);
        }
    }

    /**
     * @notice Test edge case: 0 - 1
     */
    function testZeroMinusOne() public {
        uint256 a = 0;
        uint256 b = 1;

        // Checked: reverts
        vm.expectRevert(stdError.arithmeticError);
        uint256 result = a - b;

        // Unchecked: wraps to max
        unchecked {
            result = a - b;
            assertEq(result, MAX_UINT256);
        }
    }

    /**
     * @notice Test edge case: max uint128 * 2
     */
    function testMaxUint128TimesTwo() public {
        uint256 a = type(uint128).max;
        uint256 b = 2;

        // This should NOT overflow (fits in uint256)
        uint256 result = a * b;
        assertEq(result, type(uint128).max * 2);
    }

    /**
     * @notice Test SafeMath with zero
     */
    function testSafeMathWithZero() public {
        // Add with zero
        assertEq(SafeMath.add(0, 0), 0);
        assertEq(SafeMath.add(100, 0), 100);
        assertEq(SafeMath.add(0, 100), 100);

        // Sub with zero
        assertEq(SafeMath.sub(0, 0), 0);
        assertEq(SafeMath.sub(100, 0), 100);

        // Mul with zero
        assertEq(SafeMath.mul(0, 0), 0);
        assertEq(SafeMath.mul(100, 0), 0);
        assertEq(SafeMath.mul(0, 100), 0);
    }

    /**
     * @notice Fuzz test: SafeMath add should match 0.8+ checked add
     */
    function testFuzzSafeMathAdd(uint256 a, uint256 b) public {
        // Both should behave the same way
        if (a > MAX_UINT256 - b) {
            // Overflow expected
            vm.expectRevert("SafeMath: addition overflow");
            SafeMath.add(a, b);

            vm.expectRevert(stdError.arithmeticError);
            uint256 result = a + b;
        } else {
            // No overflow
            assertEq(SafeMath.add(a, b), a + b);
        }
    }

    /**
     * @notice Fuzz test: SafeMath sub should match 0.8+ checked sub
     */
    function testFuzzSafeMathSub(uint256 a, uint256 b) public {
        if (b > a) {
            // Underflow expected
            vm.expectRevert("SafeMath: subtraction underflow");
            SafeMath.sub(a, b);

            vm.expectRevert(stdError.arithmeticError);
            uint256 result = a - b;
        } else {
            // No underflow
            assertEq(SafeMath.sub(a, b), a - b);
        }
    }

    /**
     * @notice Fuzz test: SafeMath mul should match 0.8+ checked mul
     */
    function testFuzzSafeMathMul(uint128 a, uint128 b) public {
        // Use uint128 to avoid always overflowing
        uint256 a256 = uint256(a);
        uint256 b256 = uint256(b);

        if (a != 0 && b > MAX_UINT256 / a) {
            // Overflow expected
            vm.expectRevert("SafeMath: multiplication overflow");
            SafeMath.mul(a256, b256);

            vm.expectRevert(stdError.arithmeticError);
            uint256 result = a256 * b256;
        } else {
            // No overflow
            assertEq(SafeMath.mul(a256, b256), a256 * b256);
        }
    }
}
