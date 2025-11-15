// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/Project12Solution.sol";

/**
 * @title Project12Test
 * @notice Comprehensive tests for Safe ETH Transfer Library
 * @dev Tests cover normal operations, edge cases, and attack scenarios
 *
 * TEST CATEGORIES:
 * 1. Deposit Tests
 * 2. Withdrawal Tests
 * 3. Failed Transfer Tests
 * 4. Reentrancy Protection Tests
 * 5. Gas Limit Tests
 * 6. Accounting Tests
 * 7. Multiple User Tests
 * 8. Emergency Withdrawal Tests
 */
contract Project12Test is Test {
    // ============================================
    // STATE VARIABLES
    // ============================================

    Project12Solution public safeTransfer;

    // Test accounts
    address public alice;
    address public bob;
    address public charlie;

    // Initial balances for testing
    uint256 constant INITIAL_BALANCE = 100 ether;

    // ============================================
    // EVENTS (for testing)
    // ============================================

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    // ============================================
    // SETUP
    // ============================================

    function setUp() public {
        // Deploy contract
        safeTransfer = new Project12Solution();

        // Create test accounts
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");

        // Fund test accounts
        vm.deal(alice, INITIAL_BALANCE);
        vm.deal(bob, INITIAL_BALANCE);
        vm.deal(charlie, INITIAL_BALANCE);
    }

    // ============================================
    // DEPOSIT TESTS
    // ============================================

    /**
     * @notice Test basic deposit functionality
     */
    function test_Deposit() public {
        uint256 depositAmount = 1 ether;

        // Expect Deposited event
        vm.expectEmit(true, true, false, true);
        emit Deposited(alice, depositAmount);

        // Alice deposits
        vm.prank(alice);
        safeTransfer.deposit{value: depositAmount}();

        // Verify balance updated
        assertEq(
            safeTransfer.getBalance(alice),
            depositAmount,
            "Balance should match deposit"
        );

        // Verify contract balance
        assertEq(
            address(safeTransfer).balance,
            depositAmount,
            "Contract should hold ETH"
        );

        // Verify total deposited
        assertEq(
            safeTransfer.getTotalDeposited(),
            depositAmount,
            "Total deposited should match"
        );
    }

    /**
     * @notice Test multiple deposits from same user
     */
    function test_MultipleDeposits() public {
        vm.startPrank(alice);

        // First deposit
        safeTransfer.deposit{value: 1 ether}();
        assertEq(safeTransfer.getBalance(alice), 1 ether);

        // Second deposit
        safeTransfer.deposit{value: 2 ether}();
        assertEq(safeTransfer.getBalance(alice), 3 ether);

        // Third deposit
        safeTransfer.deposit{value: 0.5 ether}();
        assertEq(safeTransfer.getBalance(alice), 3.5 ether);

        vm.stopPrank();
    }

    /**
     * @notice Test deposit with 0 ETH should revert
     */
    function test_RevertIf_DepositZero() public {
        vm.prank(alice);
        vm.expectRevert(Project12Solution.DepositZero.selector);
        safeTransfer.deposit{value: 0}();
    }

    /**
     * @notice Test deposit via receive function
     */
    function test_DepositViaReceive() public {
        uint256 depositAmount = 1 ether;

        vm.expectEmit(true, true, false, true);
        emit Deposited(alice, depositAmount);

        // Send ETH directly (triggers receive)
        vm.prank(alice);
        (bool success, ) = address(safeTransfer).call{value: depositAmount}("");
        assertTrue(success, "ETH transfer should succeed");

        assertEq(safeTransfer.getBalance(alice), depositAmount);
    }

    /**
     * @notice Fuzz test deposits with random amounts
     */
    function testFuzz_Deposit(uint256 amount) public {
        // Bound amount to reasonable range
        amount = bound(amount, 1, INITIAL_BALANCE);

        vm.prank(alice);
        safeTransfer.deposit{value: amount}();

        assertEq(safeTransfer.getBalance(alice), amount);
    }

    // ============================================
    // WITHDRAWAL TESTS
    // ============================================

    /**
     * @notice Test basic withdrawal functionality
     */
    function test_Withdraw() public {
        uint256 depositAmount = 5 ether;

        // Alice deposits
        vm.prank(alice);
        safeTransfer.deposit{value: depositAmount}();

        uint256 aliceBalanceBefore = alice.balance;

        // Expect Withdrawn event
        vm.expectEmit(true, true, false, true);
        emit Withdrawn(alice, depositAmount);

        // Alice withdraws
        vm.prank(alice);
        safeTransfer.withdraw();

        // Verify balance cleared
        assertEq(
            safeTransfer.getBalance(alice),
            0,
            "Balance should be 0 after withdrawal"
        );

        // Verify ETH received
        assertEq(
            alice.balance,
            aliceBalanceBefore + depositAmount,
            "Alice should receive ETH"
        );

        // Verify contract balance
        assertEq(
            address(safeTransfer).balance,
            0,
            "Contract should be empty"
        );

        // Verify total withdrawn
        assertEq(
            safeTransfer.getTotalWithdrawn(),
            depositAmount,
            "Total withdrawn should match"
        );
    }

    /**
     * @notice Test withdrawal with 0 balance should revert
     */
    function test_RevertIf_WithdrawZeroBalance() public {
        vm.prank(alice);
        vm.expectRevert(Project12Solution.NoBalanceToWithdraw.selector);
        safeTransfer.withdraw();
    }

    /**
     * @notice Test cannot withdraw twice
     */
    function test_RevertIf_WithdrawTwice() public {
        // Alice deposits
        vm.startPrank(alice);
        safeTransfer.deposit{value: 1 ether}();

        // First withdrawal succeeds
        safeTransfer.withdraw();

        // Second withdrawal should revert
        vm.expectRevert(Project12Solution.NoBalanceToWithdraw.selector);
        safeTransfer.withdraw();

        vm.stopPrank();
    }

    /**
     * @notice Test partial withdrawal using withdrawAmount
     */
    function test_PartialWithdrawal() public {
        uint256 depositAmount = 10 ether;

        vm.startPrank(alice);

        // Deposit
        safeTransfer.deposit{value: depositAmount}();

        // Withdraw 3 ETH
        safeTransfer.withdrawAmount(3 ether);
        assertEq(safeTransfer.getBalance(alice), 7 ether);

        // Withdraw 5 ETH
        safeTransfer.withdrawAmount(5 ether);
        assertEq(safeTransfer.getBalance(alice), 2 ether);

        // Withdraw remaining 2 ETH
        safeTransfer.withdrawAmount(2 ether);
        assertEq(safeTransfer.getBalance(alice), 0);

        vm.stopPrank();
    }

    /**
     * @notice Test withdrawAmount with amount > balance
     */
    function test_RevertIf_WithdrawAmountTooLarge() public {
        vm.startPrank(alice);

        safeTransfer.deposit{value: 5 ether}();

        vm.expectRevert("Invalid amount");
        safeTransfer.withdrawAmount(6 ether);

        vm.stopPrank();
    }

    // ============================================
    // FAILED TRANSFER TESTS
    // ============================================

    /**
     * @notice Test withdrawal to contract that rejects ETH
     */
    function test_RevertIf_RecipientRejectsETH() public {
        // Deploy contract that rejects ETH
        RejectETH rejecter = new RejectETH();

        // Rejecter deposits
        vm.prank(address(rejecter));
        safeTransfer.deposit{value: 1 ether}();

        // Withdrawal should fail and revert
        vm.prank(address(rejecter));
        vm.expectRevert(Project12Solution.TransferFailed.selector);
        safeTransfer.withdraw();

        // Balance should remain (transaction reverted)
        assertEq(
            safeTransfer.getBalance(address(rejecter)),
            1 ether,
            "Balance should be preserved after failed withdrawal"
        );
    }

    /**
     * @notice Test withdrawal to contract that reverts in receive
     */
    function test_RevertIf_RecipientRevertsInReceive() public {
        // Deploy contract that reverts on receive
        RevertOnReceive reverter = new RevertOnReceive();

        vm.prank(address(reverter));
        safeTransfer.deposit{value: 1 ether}();

        vm.prank(address(reverter));
        vm.expectRevert(Project12Solution.TransferFailed.selector);
        safeTransfer.withdraw();

        // Balance preserved
        assertEq(safeTransfer.getBalance(address(reverter)), 1 ether);
    }

    // ============================================
    // REENTRANCY PROTECTION TESTS
    // ============================================

    /**
     * @notice Test reentrancy attack is prevented
     */
    function test_ReentrancyProtection() public {
        // Deploy attacker contract
        ReentrancyAttacker attacker = new ReentrancyAttacker(
            address(safeTransfer)
        );

        // Fund attacker
        vm.deal(address(attacker), 10 ether);

        // Attacker deposits
        vm.prank(address(attacker));
        safeTransfer.deposit{value: 5 ether}();

        // Attempt reentrancy attack
        // Should fail due to CEI pattern + ReentrancyGuard
        vm.prank(address(attacker));
        attacker.attack();

        // Verify attacker only withdrew once
        assertEq(
            safeTransfer.getBalance(address(attacker)),
            0,
            "Attacker balance should be 0"
        );

        // Contract should not be drained
        assertEq(
            address(safeTransfer).balance,
            0,
            "Contract should be empty (single withdrawal)"
        );
    }

    // ============================================
    // GAS LIMIT TESTS
    // ============================================

    /**
     * @notice Test withdrawal with gas-heavy recipient
     */
    function test_WithdrawToGasHeavyRecipient() public {
        // Deploy recipient that uses gas
        GasHeavyRecipient heavyRecipient = new GasHeavyRecipient();

        vm.prank(address(heavyRecipient));
        safeTransfer.deposit{value: 1 ether}();

        // Should succeed (call forwards enough gas)
        vm.prank(address(heavyRecipient));
        safeTransfer.withdraw();

        // Verify withdrawal succeeded
        assertEq(safeTransfer.getBalance(address(heavyRecipient)), 0);
        assertTrue(heavyRecipient.received(), "Should have received ETH");
    }

    /**
     * @notice Test that we can measure gas consumption
     */
    function test_GasMeasurement() public {
        vm.prank(alice);
        uint256 gasBefore = gasleft();
        safeTransfer.deposit{value: 1 ether}();
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Deposit gas used:", gasUsed);

        vm.prank(alice);
        gasBefore = gasleft();
        safeTransfer.withdraw();
        gasUsed = gasBefore - gasleft();

        console.log("Withdraw gas used:", gasUsed);
    }

    // ============================================
    // ACCOUNTING TESTS
    // ============================================

    /**
     * @notice Test accounting integrity
     */
    function test_AccountingIntegrity() public {
        // Multiple deposits
        vm.prank(alice);
        safeTransfer.deposit{value: 5 ether}();

        vm.prank(bob);
        safeTransfer.deposit{value: 3 ether}();

        vm.prank(charlie);
        safeTransfer.deposit{value: 2 ether}();

        // Verify accounting
        assertTrue(
            safeTransfer.verifyAccounting(),
            "Accounting should be valid after deposits"
        );

        // Some withdrawals
        vm.prank(alice);
        safeTransfer.withdraw();

        vm.prank(bob);
        safeTransfer.withdrawAmount(1 ether);

        // Verify accounting still valid
        assertTrue(
            safeTransfer.verifyAccounting(),
            "Accounting should be valid after withdrawals"
        );

        // Check totals
        assertEq(safeTransfer.getTotalDeposited(), 10 ether);
        assertEq(safeTransfer.getTotalWithdrawn(), 6 ether);
        assertEq(safeTransfer.getContractBalance(), 4 ether);
    }

    /**
     * @notice Test force-feeding ETH detection
     */
    function test_DetectForceFeedETH() public {
        // Normal deposits
        vm.prank(alice);
        safeTransfer.deposit{value: 5 ether}();

        assertTrue(safeTransfer.verifyAccounting());

        // Force-feed ETH via selfdestruct
        SelfDestructor destructor = new SelfDestructor();
        vm.deal(address(destructor), 10 ether);
        destructor.destroy(payable(address(safeTransfer)));

        // Accounting should detect mismatch
        assertFalse(
            safeTransfer.verifyAccounting(),
            "Should detect force-fed ETH"
        );

        // Contract balance should be more than expected
        assertTrue(
            safeTransfer.getContractBalance() >
                (safeTransfer.getTotalDeposited() -
                    safeTransfer.getTotalWithdrawn())
        );
    }

    // ============================================
    // MULTIPLE USER TESTS
    // ============================================

    /**
     * @notice Test multiple users can deposit and withdraw independently
     */
    function test_MultipleUsersIndependent() public {
        // Alice deposits 5 ETH
        vm.prank(alice);
        safeTransfer.deposit{value: 5 ether}();

        // Bob deposits 3 ETH
        vm.prank(bob);
        safeTransfer.deposit{value: 3 ether}();

        // Charlie deposits 2 ETH
        vm.prank(charlie);
        safeTransfer.deposit{value: 2 ether}();

        // Verify balances
        assertEq(safeTransfer.getBalance(alice), 5 ether);
        assertEq(safeTransfer.getBalance(bob), 3 ether);
        assertEq(safeTransfer.getBalance(charlie), 2 ether);

        // Bob withdraws (shouldn't affect others)
        vm.prank(bob);
        safeTransfer.withdraw();

        // Verify Bob's balance cleared
        assertEq(safeTransfer.getBalance(bob), 0);

        // Verify others unchanged
        assertEq(safeTransfer.getBalance(alice), 5 ether);
        assertEq(safeTransfer.getBalance(charlie), 2 ether);

        // Alice and Charlie can still withdraw
        vm.prank(alice);
        safeTransfer.withdraw();

        vm.prank(charlie);
        safeTransfer.withdraw();

        // All balances should be 0
        assertEq(safeTransfer.getBalance(alice), 0);
        assertEq(safeTransfer.getBalance(bob), 0);
        assertEq(safeTransfer.getBalance(charlie), 0);
    }

    // ============================================
    // BATCH OPERATIONS TESTS
    // ============================================

    /**
     * @notice Test batch credit functionality
     */
    function test_BatchCredit() public {
        address[] memory recipients = new address[](3);
        recipients[0] = alice;
        recipients[1] = bob;
        recipients[2] = charlie;

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 5 ether;
        amounts[1] = 3 ether;
        amounts[2] = 2 ether;

        uint256 totalAmount = 10 ether;

        // Batch credit
        vm.prank(alice);
        safeTransfer.batchCredit{value: totalAmount}(recipients, amounts);

        // Verify balances
        assertEq(safeTransfer.getBalance(alice), 5 ether);
        assertEq(safeTransfer.getBalance(bob), 3 ether);
        assertEq(safeTransfer.getBalance(charlie), 2 ether);

        // Verify all can withdraw
        vm.prank(alice);
        safeTransfer.withdraw();

        vm.prank(bob);
        safeTransfer.withdraw();

        vm.prank(charlie);
        safeTransfer.withdraw();
    }

    /**
     * @notice Test batch credit with insufficient ETH
     */
    function test_RevertIf_BatchCreditInsufficientETH() public {
        address[] memory recipients = new address[](2);
        recipients[0] = alice;
        recipients[1] = bob;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 5 ether;
        amounts[1] = 3 ether;

        // Send less than required
        vm.prank(alice);
        vm.expectRevert("Insufficient ETH");
        safeTransfer.batchCredit{value: 7 ether}(recipients, amounts);
    }

    // ============================================
    // EDGE CASE TESTS
    // ============================================

    /**
     * @notice Test with very small amounts (wei)
     */
    function test_SmallAmounts() public {
        vm.startPrank(alice);

        // Deposit 1 wei
        safeTransfer.deposit{value: 1}();
        assertEq(safeTransfer.getBalance(alice), 1);

        // Withdraw 1 wei
        safeTransfer.withdraw();
        assertEq(safeTransfer.getBalance(alice), 0);

        vm.stopPrank();
    }

    /**
     * @notice Test with large amounts
     */
    function test_LargeAmounts() public {
        uint256 largeAmount = 50 ether;
        vm.deal(alice, largeAmount);

        vm.startPrank(alice);

        safeTransfer.deposit{value: largeAmount}();
        assertEq(safeTransfer.getBalance(alice), largeAmount);

        safeTransfer.withdraw();
        assertEq(safeTransfer.getBalance(alice), 0);

        vm.stopPrank();
    }
}

// ============================================
// HELPER CONTRACTS FOR TESTING
// ============================================

/**
 * @notice Contract that rejects all ETH transfers
 */
contract RejectETH {
    // No receive() or fallback() - will reject ETH
}

/**
 * @notice Contract that reverts when receiving ETH
 */
contract RevertOnReceive {
    receive() external payable {
        revert("I don't want your ETH!");
    }
}

/**
 * @notice Contract that attempts reentrancy attack
 */
contract ReentrancyAttacker {
    Project12Solution public target;
    uint256 public attackCount;

    constructor(address _target) {
        target = Project12Solution(_target);
    }

    function attack() public {
        attackCount = 0;
        target.withdraw();
    }

    receive() external payable {
        attackCount++;

        // Try to withdraw again (reentrancy)
        if (attackCount < 5 && target.getBalance(address(this)) > 0) {
            try target.withdraw() {
                // Should fail
            } catch {
                // Expected to fail
            }
        }
    }
}

/**
 * @notice Contract that uses gas in receive function
 * @dev Tests that call{} forwards enough gas (vs transfer/send)
 */
contract GasHeavyRecipient {
    uint256 public counter;
    bool public received;

    receive() external payable {
        // Use gas (SLOAD and SSTORE)
        for (uint256 i = 0; i < 10; i++) {
            counter++;
        }
        received = true;
    }
}

/**
 * @notice Contract for testing force-feeding ETH via selfdestruct
 */
contract SelfDestructor {
    function destroy(address payable target) public {
        selfdestruct(target);
    }
}
