// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/MultiSigWalletSolution.sol";

/**
 * @title Multi-Sig Wallet Tests
 * @notice Comprehensive test suite for the multi-signature wallet
 * @dev Tests cover:
 * - Deployment and initialization
 * - Transaction lifecycle (submit, confirm, execute)
 * - Threshold enforcement
 * - Replay protection
 * - Owner management
 * - Edge cases and security scenarios
 */
contract MultiSigWalletTest is Test {
    MultiSigWalletSolution public wallet;

    // Test accounts
    address public owner1 = address(0x1);
    address public owner2 = address(0x2);
    address public owner3 = address(0x3);
    address public nonOwner = address(0x4);
    address public recipient = address(0x5);

    // Events to test
    event TransactionSubmitted(
        uint256 indexed txId, address indexed submitter, address indexed to, uint256 value, bytes data
    );
    event TransactionConfirmed(uint256 indexed txId, address indexed owner);
    event ConfirmationRevoked(uint256 indexed txId, address indexed owner);
    event TransactionExecuted(uint256 indexed txId, address indexed executor);
    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);
    event ThresholdChanged(uint256 threshold);
    event Deposit(address indexed sender, uint256 amount, uint256 balance);

    function setUp() public {
        // Create 3-owner wallet with 2-of-3 threshold
        address[] memory owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;

        wallet = new MultiSigWalletSolution(owners, 2);

        // Fund wallet with 10 ETH for testing
        vm.deal(address(wallet), 10 ether);

        // Label addresses for better trace output
        vm.label(owner1, "Owner1");
        vm.label(owner2, "Owner2");
        vm.label(owner3, "Owner3");
        vm.label(nonOwner, "NonOwner");
        vm.label(recipient, "Recipient");
        vm.label(address(wallet), "MultiSigWallet");
    }

    /*//////////////////////////////////////////////////////////////
                        DEPLOYMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Deployment() public view {
        // Check owners are set correctly
        address[] memory owners = wallet.getOwners();
        assertEq(owners.length, 3, "Should have 3 owners");
        assertEq(owners[0], owner1, "Owner 1 should be set");
        assertEq(owners[1], owner2, "Owner 2 should be set");
        assertEq(owners[2], owner3, "Owner 3 should be set");

        // Check threshold
        assertEq(wallet.threshold(), 2, "Threshold should be 2");

        // Check owner mapping
        assertTrue(wallet.isOwner(owner1), "Owner 1 should be marked as owner");
        assertTrue(wallet.isOwner(owner2), "Owner 2 should be marked as owner");
        assertTrue(wallet.isOwner(owner3), "Owner 3 should be marked as owner");
        assertFalse(wallet.isOwner(nonOwner), "Non-owner should not be marked as owner");

        // Check initial nonce
        assertEq(wallet.nonce(), 0, "Initial nonce should be 0");
    }

    function test_RevertIf_DeploymentWithNoOwners() public {
        address[] memory owners = new address[](0);
        vm.expectRevert(MultiSigWalletSolution.NoOwners.selector);
        new MultiSigWalletSolution(owners, 1);
    }

    function test_RevertIf_DeploymentWithZeroThreshold() public {
        address[] memory owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;

        vm.expectRevert(MultiSigWalletSolution.InvalidThreshold.selector);
        new MultiSigWalletSolution(owners, 0);
    }

    function test_RevertIf_DeploymentWithThresholdTooHigh() public {
        address[] memory owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;

        vm.expectRevert(MultiSigWalletSolution.InvalidThreshold.selector);
        new MultiSigWalletSolution(owners, 4);
    }

    function test_RevertIf_DeploymentWithZeroAddressOwner() public {
        address[] memory owners = new address[](3);
        owners[0] = owner1;
        owners[1] = address(0);
        owners[2] = owner3;

        vm.expectRevert(MultiSigWalletSolution.InvalidOwner.selector);
        new MultiSigWalletSolution(owners, 2);
    }

    function test_RevertIf_DeploymentWithDuplicateOwners() public {
        address[] memory owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner1; // Duplicate

        vm.expectRevert(MultiSigWalletSolution.DuplicateOwner.selector);
        new MultiSigWalletSolution(owners, 2);
    }

    /*//////////////////////////////////////////////////////////////
                    TRANSACTION SUBMISSION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SubmitTransaction() public {
        vm.startPrank(owner1);

        bytes memory data = "";
        vm.expectEmit(true, true, true, true);
        emit TransactionSubmitted(0, owner1, recipient, 1 ether, data);

        uint256 txId = wallet.submitTransaction(recipient, 1 ether, data);

        assertEq(txId, 0, "First transaction should have ID 0");
        assertEq(wallet.nonce(), 1, "Nonce should increment to 1");

        // Check transaction details
        (address to, uint256 value, bytes memory txData, bool executed) = wallet.getTransaction(0);
        assertEq(to, recipient, "Destination should be recipient");
        assertEq(value, 1 ether, "Value should be 1 ether");
        assertEq(txData, data, "Data should match");
        assertFalse(executed, "Should not be executed yet");

        vm.stopPrank();
    }

    function test_SubmitMultipleTransactions() public {
        vm.startPrank(owner1);

        uint256 txId1 = wallet.submitTransaction(recipient, 1 ether, "");
        uint256 txId2 = wallet.submitTransaction(recipient, 2 ether, "");
        uint256 txId3 = wallet.submitTransaction(recipient, 3 ether, "");

        assertEq(txId1, 0, "First txId should be 0");
        assertEq(txId2, 1, "Second txId should be 1");
        assertEq(txId3, 2, "Third txId should be 2");
        assertEq(wallet.nonce(), 3, "Nonce should be 3");

        vm.stopPrank();
    }

    function test_RevertIf_NonOwnerSubmitsTransaction() public {
        vm.prank(nonOwner);
        vm.expectRevert(MultiSigWalletSolution.NotOwner.selector);
        wallet.submitTransaction(recipient, 1 ether, "");
    }

    function test_RevertIf_SubmitToZeroAddress() public {
        vm.prank(owner1);
        vm.expectRevert(MultiSigWalletSolution.InvalidDestination.selector);
        wallet.submitTransaction(address(0), 1 ether, "");
    }

    /*//////////////////////////////////////////////////////////////
                    TRANSACTION CONFIRMATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ConfirmTransaction() public {
        // Submit transaction
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(recipient, 1 ether, "");

        // Confirm transaction
        vm.prank(owner2);
        vm.expectEmit(true, true, false, false);
        emit TransactionConfirmed(txId, owner2);
        wallet.confirmTransaction(txId);

        // Check confirmation
        assertTrue(wallet.isConfirmedBy(txId, owner2), "Owner2 should have confirmed");
        assertEq(wallet.getConfirmationCount(txId), 1, "Should have 1 confirmation");
    }

    function test_MultipleOwnersConfirm() public {
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(recipient, 1 ether, "");

        // All three owners confirm
        vm.prank(owner1);
        wallet.confirmTransaction(txId);

        vm.prank(owner2);
        wallet.confirmTransaction(txId);

        vm.prank(owner3);
        wallet.confirmTransaction(txId);

        // Check confirmations
        assertTrue(wallet.isConfirmedBy(txId, owner1), "Owner1 should have confirmed");
        assertTrue(wallet.isConfirmedBy(txId, owner2), "Owner2 should have confirmed");
        assertTrue(wallet.isConfirmedBy(txId, owner3), "Owner3 should have confirmed");
        assertEq(wallet.getConfirmationCount(txId), 3, "Should have 3 confirmations");
    }

    function test_RevertIf_NonOwnerConfirms() public {
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(recipient, 1 ether, "");

        vm.prank(nonOwner);
        vm.expectRevert(MultiSigWalletSolution.NotOwner.selector);
        wallet.confirmTransaction(txId);
    }

    function test_RevertIf_ConfirmNonexistentTransaction() public {
        vm.prank(owner1);
        vm.expectRevert(MultiSigWalletSolution.TransactionDoesNotExist.selector);
        wallet.confirmTransaction(999);
    }

    function test_RevertIf_DoubleConfirmation() public {
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(recipient, 1 ether, "");

        // First confirmation should succeed
        vm.prank(owner2);
        wallet.confirmTransaction(txId);

        // Second confirmation should fail
        vm.prank(owner2);
        vm.expectRevert(MultiSigWalletSolution.AlreadyConfirmed.selector);
        wallet.confirmTransaction(txId);
    }

    function test_RevertIf_ConfirmExecutedTransaction() public {
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(recipient, 1 ether, "");

        // Get threshold confirmations and execute
        vm.prank(owner1);
        wallet.confirmTransaction(txId);
        vm.prank(owner2);
        wallet.confirmTransaction(txId);
        wallet.executeTransaction(txId);

        // Try to confirm after execution
        vm.prank(owner3);
        vm.expectRevert(MultiSigWalletSolution.TransactionAlreadyExecuted.selector);
        wallet.confirmTransaction(txId);
    }

    /*//////////////////////////////////////////////////////////////
                    CONFIRMATION REVOCATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RevokeConfirmation() public {
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(recipient, 1 ether, "");

        // Confirm
        vm.prank(owner1);
        wallet.confirmTransaction(txId);
        assertTrue(wallet.isConfirmedBy(txId, owner1), "Should be confirmed");

        // Revoke
        vm.prank(owner1);
        vm.expectEmit(true, true, false, false);
        emit ConfirmationRevoked(txId, owner1);
        wallet.revokeConfirmation(txId);

        assertFalse(wallet.isConfirmedBy(txId, owner1), "Should be revoked");
        assertEq(wallet.getConfirmationCount(txId), 0, "Should have 0 confirmations");
    }

    function test_RevertIf_RevokeNonexistentConfirmation() public {
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(recipient, 1 ether, "");

        // Try to revoke without confirming first
        vm.prank(owner1);
        vm.expectRevert(MultiSigWalletSolution.NotConfirmed.selector);
        wallet.revokeConfirmation(txId);
    }

    function test_RevertIf_RevokeAfterExecution() public {
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(recipient, 1 ether, "");

        // Confirm and execute
        vm.prank(owner1);
        wallet.confirmTransaction(txId);
        vm.prank(owner2);
        wallet.confirmTransaction(txId);
        wallet.executeTransaction(txId);

        // Try to revoke after execution
        vm.prank(owner1);
        vm.expectRevert(MultiSigWalletSolution.TransactionAlreadyExecuted.selector);
        wallet.revokeConfirmation(txId);
    }

    /*//////////////////////////////////////////////////////////////
                    TRANSACTION EXECUTION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ExecuteTransaction() public {
        uint256 recipientBalanceBefore = recipient.balance;

        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(recipient, 1 ether, "");

        // Get threshold confirmations
        vm.prank(owner1);
        wallet.confirmTransaction(txId);
        vm.prank(owner2);
        wallet.confirmTransaction(txId);

        // Execute
        vm.expectEmit(true, true, false, false);
        emit TransactionExecuted(txId, address(this));
        wallet.executeTransaction(txId);

        // Check execution
        (, , , bool executed) = wallet.getTransaction(txId);
        assertTrue(executed, "Transaction should be executed");
        assertEq(recipient.balance, recipientBalanceBefore + 1 ether, "Recipient should receive ETH");
    }

    function test_ExecuteWithExactThreshold() public {
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(recipient, 1 ether, "");

        // Exactly threshold (2) confirmations
        vm.prank(owner1);
        wallet.confirmTransaction(txId);
        vm.prank(owner2);
        wallet.confirmTransaction(txId);

        assertTrue(wallet.isThresholdMet(txId), "Threshold should be met with 2 confirmations");
        wallet.executeTransaction(txId);

        (, , , bool executed) = wallet.getTransaction(txId);
        assertTrue(executed, "Should execute with exact threshold");
    }

    function test_ExecuteWithMoreThanThreshold() public {
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(recipient, 1 ether, "");

        // More than threshold (all 3) confirmations
        vm.prank(owner1);
        wallet.confirmTransaction(txId);
        vm.prank(owner2);
        wallet.confirmTransaction(txId);
        vm.prank(owner3);
        wallet.confirmTransaction(txId);

        assertTrue(wallet.isThresholdMet(txId), "Threshold should be met with 3 confirmations");
        wallet.executeTransaction(txId);

        (, , , bool executed) = wallet.getTransaction(txId);
        assertTrue(executed, "Should execute with more than threshold");
    }

    function test_RevertIf_ExecuteWithoutThreshold() public {
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(recipient, 1 ether, "");

        // Only 1 confirmation (threshold is 2)
        vm.prank(owner1);
        wallet.confirmTransaction(txId);

        assertFalse(wallet.isThresholdMet(txId), "Threshold should not be met with 1 confirmation");

        vm.expectRevert(MultiSigWalletSolution.ThresholdNotMet.selector);
        wallet.executeTransaction(txId);
    }

    function test_RevertIf_ExecuteNonexistentTransaction() public {
        vm.expectRevert(MultiSigWalletSolution.TransactionDoesNotExist.selector);
        wallet.executeTransaction(999);
    }

    function test_RevertIf_DoubleExecution() public {
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(recipient, 1 ether, "");

        // Get confirmations and execute
        vm.prank(owner1);
        wallet.confirmTransaction(txId);
        vm.prank(owner2);
        wallet.confirmTransaction(txId);
        wallet.executeTransaction(txId);

        // Try to execute again
        vm.expectRevert(MultiSigWalletSolution.TransactionAlreadyExecuted.selector);
        wallet.executeTransaction(txId);
    }

    function test_ExecuteWithCalldata() public {
        // Deploy a test contract to call
        TestTarget target = new TestTarget();

        // Create transaction to call setValue(42)
        bytes memory data = abi.encodeWithSelector(TestTarget.setValue.selector, 42);

        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(address(target), 0, data);

        // Confirm and execute
        vm.prank(owner1);
        wallet.confirmTransaction(txId);
        vm.prank(owner2);
        wallet.confirmTransaction(txId);
        wallet.executeTransaction(txId);

        // Check that function was called
        assertEq(target.value(), 42, "Target contract value should be set to 42");
    }

    /*//////////////////////////////////////////////////////////////
                    THRESHOLD ENFORCEMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ThresholdMet() public {
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(recipient, 1 ether, "");

        assertFalse(wallet.isThresholdMet(txId), "Should not meet threshold with 0 confirmations");

        vm.prank(owner1);
        wallet.confirmTransaction(txId);
        assertFalse(wallet.isThresholdMet(txId), "Should not meet threshold with 1 confirmation");

        vm.prank(owner2);
        wallet.confirmTransaction(txId);
        assertTrue(wallet.isThresholdMet(txId), "Should meet threshold with 2 confirmations");
    }

    function test_ThresholdWithRevocation() public {
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(recipient, 1 ether, "");

        // Get to threshold
        vm.prank(owner1);
        wallet.confirmTransaction(txId);
        vm.prank(owner2);
        wallet.confirmTransaction(txId);
        assertTrue(wallet.isThresholdMet(txId), "Should meet threshold");

        // Revoke one confirmation
        vm.prank(owner1);
        wallet.revokeConfirmation(txId);
        assertFalse(wallet.isThresholdMet(txId), "Should not meet threshold after revocation");
    }

    /*//////////////////////////////////////////////////////////////
                    REPLAY PROTECTION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_NonceIncrementsCorrectly() public {
        assertEq(wallet.nonce(), 0, "Initial nonce should be 0");

        vm.startPrank(owner1);
        wallet.submitTransaction(recipient, 1 ether, "");
        assertEq(wallet.nonce(), 1, "Nonce should be 1 after first submission");

        wallet.submitTransaction(recipient, 1 ether, "");
        assertEq(wallet.nonce(), 2, "Nonce should be 2 after second submission");

        wallet.submitTransaction(recipient, 1 ether, "");
        assertEq(wallet.nonce(), 3, "Nonce should be 3 after third submission");
        vm.stopPrank();
    }

    function test_CannotReplayExecutedTransaction() public {
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(recipient, 1 ether, "");

        // Execute transaction
        vm.prank(owner1);
        wallet.confirmTransaction(txId);
        vm.prank(owner2);
        wallet.confirmTransaction(txId);
        wallet.executeTransaction(txId);

        // Try to execute again
        vm.expectRevert(MultiSigWalletSolution.TransactionAlreadyExecuted.selector);
        wallet.executeTransaction(txId);
    }

    function test_EachTransactionHasUniqueId() public {
        vm.startPrank(owner1);

        uint256 txId1 = wallet.submitTransaction(recipient, 1 ether, "");
        uint256 txId2 = wallet.submitTransaction(recipient, 1 ether, "");
        uint256 txId3 = wallet.submitTransaction(recipient, 1 ether, "");

        // All IDs should be different
        assertTrue(txId1 != txId2, "TxId 1 and 2 should be different");
        assertTrue(txId2 != txId3, "TxId 2 and 3 should be different");
        assertTrue(txId1 != txId3, "TxId 1 and 3 should be different");

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                    OWNER MANAGEMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_AddOwner() public {
        address newOwner = address(0x99);
        assertFalse(wallet.isOwner(newOwner), "New owner should not be owner yet");

        // Create transaction to add owner
        bytes memory data = abi.encodeWithSelector(MultiSigWalletSolution.addOwner.selector, newOwner);
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(address(wallet), 0, data);

        // Confirm and execute
        vm.prank(owner1);
        wallet.confirmTransaction(txId);
        vm.prank(owner2);
        wallet.confirmTransaction(txId);

        vm.expectEmit(true, false, false, false);
        emit OwnerAdded(newOwner);
        wallet.executeTransaction(txId);

        // Check new owner was added
        assertTrue(wallet.isOwner(newOwner), "New owner should be added");
        address[] memory owners = wallet.getOwners();
        assertEq(owners.length, 4, "Should have 4 owners now");
    }

    function test_RemoveOwner() public {
        // Create transaction to remove owner3
        bytes memory data = abi.encodeWithSelector(MultiSigWalletSolution.removeOwner.selector, owner3);
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(address(wallet), 0, data);

        // Confirm and execute
        vm.prank(owner1);
        wallet.confirmTransaction(txId);
        vm.prank(owner2);
        wallet.confirmTransaction(txId);

        vm.expectEmit(true, false, false, false);
        emit OwnerRemoved(owner3);
        wallet.executeTransaction(txId);

        // Check owner was removed
        assertFalse(wallet.isOwner(owner3), "Owner3 should be removed");
        address[] memory owners = wallet.getOwners();
        assertEq(owners.length, 2, "Should have 2 owners now");
    }

    function test_ChangeThreshold() public {
        // Create transaction to change threshold to 3
        bytes memory data = abi.encodeWithSelector(MultiSigWalletSolution.changeThreshold.selector, 3);
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(address(wallet), 0, data);

        // Confirm and execute (with current threshold of 2)
        vm.prank(owner1);
        wallet.confirmTransaction(txId);
        vm.prank(owner2);
        wallet.confirmTransaction(txId);

        vm.expectEmit(false, false, false, true);
        emit ThresholdChanged(3);
        wallet.executeTransaction(txId);

        // Check threshold was changed
        assertEq(wallet.threshold(), 3, "Threshold should be 3");
    }

    function test_RevertIf_AddOwnerCalledDirectly() public {
        vm.prank(owner1);
        vm.expectRevert(MultiSigWalletSolution.OnlyWalletCanCall.selector);
        wallet.addOwner(address(0x99));
    }

    function test_RevertIf_RemoveOwnerCalledDirectly() public {
        vm.prank(owner1);
        vm.expectRevert(MultiSigWalletSolution.OnlyWalletCanCall.selector);
        wallet.removeOwner(owner3);
    }

    function test_RevertIf_ChangeThresholdCalledDirectly() public {
        vm.prank(owner1);
        vm.expectRevert(MultiSigWalletSolution.OnlyWalletCanCall.selector);
        wallet.changeThreshold(3);
    }

    function test_RevertIf_AddZeroAddressOwner() public {
        bytes memory data = abi.encodeWithSelector(MultiSigWalletSolution.addOwner.selector, address(0));
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(address(wallet), 0, data);

        vm.prank(owner1);
        wallet.confirmTransaction(txId);
        vm.prank(owner2);
        wallet.confirmTransaction(txId);

        vm.expectRevert(MultiSigWalletSolution.TransactionFailed.selector);
        wallet.executeTransaction(txId);
    }

    function test_RevertIf_AddDuplicateOwner() public {
        bytes memory data = abi.encodeWithSelector(MultiSigWalletSolution.addOwner.selector, owner1);
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(address(wallet), 0, data);

        vm.prank(owner1);
        wallet.confirmTransaction(txId);
        vm.prank(owner2);
        wallet.confirmTransaction(txId);

        vm.expectRevert(MultiSigWalletSolution.TransactionFailed.selector);
        wallet.executeTransaction(txId);
    }

    function test_RevertIf_RemoveOwnerBreaksThreshold() public {
        // First change threshold to 3
        bytes memory data1 = abi.encodeWithSelector(MultiSigWalletSolution.changeThreshold.selector, 3);
        vm.prank(owner1);
        uint256 txId1 = wallet.submitTransaction(address(wallet), 0, data1);
        vm.prank(owner1);
        wallet.confirmTransaction(txId1);
        vm.prank(owner2);
        wallet.confirmTransaction(txId1);
        wallet.executeTransaction(txId1);

        // Now try to remove an owner (would leave 2 owners with threshold 3)
        bytes memory data2 = abi.encodeWithSelector(MultiSigWalletSolution.removeOwner.selector, owner3);
        vm.prank(owner1);
        uint256 txId2 = wallet.submitTransaction(address(wallet), 0, data2);
        vm.prank(owner1);
        wallet.confirmTransaction(txId2);
        vm.prank(owner2);
        wallet.confirmTransaction(txId2);
        vm.prank(owner3);
        wallet.confirmTransaction(txId2);

        vm.expectRevert(MultiSigWalletSolution.TransactionFailed.selector);
        wallet.executeTransaction(txId2);
    }

    function test_RevertIf_ChangeThresholdToZero() public {
        bytes memory data = abi.encodeWithSelector(MultiSigWalletSolution.changeThreshold.selector, 0);
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(address(wallet), 0, data);

        vm.prank(owner1);
        wallet.confirmTransaction(txId);
        vm.prank(owner2);
        wallet.confirmTransaction(txId);

        vm.expectRevert(MultiSigWalletSolution.TransactionFailed.selector);
        wallet.executeTransaction(txId);
    }

    function test_RevertIf_ChangeThresholdTooHigh() public {
        bytes memory data = abi.encodeWithSelector(MultiSigWalletSolution.changeThreshold.selector, 10);
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(address(wallet), 0, data);

        vm.prank(owner1);
        wallet.confirmTransaction(txId);
        vm.prank(owner2);
        wallet.confirmTransaction(txId);

        vm.expectRevert(MultiSigWalletSolution.TransactionFailed.selector);
        wallet.executeTransaction(txId);
    }

    /*//////////////////////////////////////////////////////////////
                        ETH HANDLING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ReceiveEth() public {
        uint256 balanceBefore = address(wallet).balance;

        vm.expectEmit(true, false, false, true);
        emit Deposit(address(this), 1 ether, balanceBefore + 1 ether);

        (bool success,) = address(wallet).call{value: 1 ether}("");
        assertTrue(success, "ETH transfer should succeed");

        assertEq(address(wallet).balance, balanceBefore + 1 ether, "Wallet should receive ETH");
    }

    function test_FallbackFunction() public {
        uint256 balanceBefore = address(wallet).balance;

        // Call with data to trigger fallback
        (bool success,) = address(wallet).call{value: 1 ether}(abi.encodeWithSignature("nonexistent()"));
        assertTrue(success, "Fallback should accept ETH");

        assertEq(address(wallet).balance, balanceBefore + 1 ether, "Wallet should receive ETH via fallback");
    }

    /*//////////////////////////////////////////////////////////////
                        REENTRANCY TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ReentrancyProtection() public {
        // Deploy malicious contract
        MaliciousReentrancy attacker = new MaliciousReentrancy(wallet);

        // Fund attacker
        vm.deal(address(attacker), 1 ether);

        // Attacker becomes owner (via multi-sig)
        bytes memory data = abi.encodeWithSelector(MultiSigWalletSolution.addOwner.selector, address(attacker));
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(address(wallet), 0, data);
        vm.prank(owner1);
        wallet.confirmTransaction(txId);
        vm.prank(owner2);
        wallet.confirmTransaction(txId);
        wallet.executeTransaction(txId);

        // Attacker submits a transaction to itself
        vm.prank(address(attacker));
        uint256 attackTxId = wallet.submitTransaction(address(attacker), 1 ether, "");

        // Get confirmations
        vm.prank(owner1);
        wallet.confirmTransaction(attackTxId);
        vm.prank(owner2);
        wallet.confirmTransaction(attackTxId);

        // Execute - attacker will try to re-enter
        wallet.executeTransaction(attackTxId);

        // Verify transaction was only executed once
        (, , , bool executed) = wallet.getTransaction(attackTxId);
        assertTrue(executed, "Transaction should be executed");
        assertEq(attacker.callCount(), 1, "Should only execute once despite reentrancy attempt");
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GetOwners() public view {
        address[] memory owners = wallet.getOwners();
        assertEq(owners.length, 3, "Should return 3 owners");
        assertEq(owners[0], owner1, "First owner should be owner1");
        assertEq(owners[1], owner2, "Second owner should be owner2");
        assertEq(owners[2], owner3, "Third owner should be owner3");
    }

    function test_GetTransaction() public {
        bytes memory data = abi.encodeWithSignature("test()");
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(recipient, 2 ether, data);

        (address to, uint256 value, bytes memory txData, bool executed) = wallet.getTransaction(txId);
        assertEq(to, recipient, "Should return correct destination");
        assertEq(value, 2 ether, "Should return correct value");
        assertEq(txData, data, "Should return correct data");
        assertFalse(executed, "Should return correct execution status");
    }

    function test_GetTransactionCount() public {
        assertEq(wallet.getTransactionCount(), 0, "Should start at 0");

        vm.startPrank(owner1);
        wallet.submitTransaction(recipient, 1 ether, "");
        assertEq(wallet.getTransactionCount(), 1, "Should be 1 after first submission");

        wallet.submitTransaction(recipient, 1 ether, "");
        assertEq(wallet.getTransactionCount(), 2, "Should be 2 after second submission");
        vm.stopPrank();
    }

    function test_IsConfirmedBy() public {
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(recipient, 1 ether, "");

        assertFalse(wallet.isConfirmedBy(txId, owner1), "Should not be confirmed initially");

        vm.prank(owner1);
        wallet.confirmTransaction(txId);

        assertTrue(wallet.isConfirmedBy(txId, owner1), "Should be confirmed after confirmation");
        assertFalse(wallet.isConfirmedBy(txId, owner2), "Other owner should not be confirmed");
    }

    /*//////////////////////////////////////////////////////////////
                        EDGE CASE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SingleOwnerWallet() public {
        address[] memory owners = new address[](1);
        owners[0] = owner1;

        MultiSigWalletSolution singleOwnerWallet = new MultiSigWalletSolution(owners, 1);
        vm.deal(address(singleOwnerWallet), 10 ether);

        // Single owner should be able to submit and execute immediately
        vm.startPrank(owner1);
        uint256 txId = singleOwnerWallet.submitTransaction(recipient, 1 ether, "");
        singleOwnerWallet.confirmTransaction(txId);
        singleOwnerWallet.executeTransaction(txId);
        vm.stopPrank();

        assertEq(recipient.balance, 1 ether, "Transaction should execute with single owner");
    }

    function test_AllOwnersRequiredWallet() public {
        address[] memory owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;

        MultiSigWalletSolution unanimousWallet = new MultiSigWalletSolution(owners, 3);
        vm.deal(address(unanimousWallet), 10 ether);

        // Submit transaction
        vm.prank(owner1);
        uint256 txId = unanimousWallet.submitTransaction(recipient, 1 ether, "");

        // Only 2 confirmations (threshold requires 3)
        vm.prank(owner1);
        unanimousWallet.confirmTransaction(txId);
        vm.prank(owner2);
        unanimousWallet.confirmTransaction(txId);

        // Should fail without all owners
        vm.expectRevert(MultiSigWalletSolution.ThresholdNotMet.selector);
        unanimousWallet.executeTransaction(txId);

        // Add third confirmation
        vm.prank(owner3);
        unanimousWallet.confirmTransaction(txId);

        // Now should succeed
        unanimousWallet.executeTransaction(txId);
        assertEq(recipient.balance, 1 ether, "Should execute with all confirmations");
    }

    function test_ComplexWorkflow() public {
        // Submit multiple transactions
        vm.prank(owner1);
        uint256 tx1 = wallet.submitTransaction(recipient, 1 ether, "");
        vm.prank(owner2);
        uint256 tx2 = wallet.submitTransaction(recipient, 2 ether, "");

        // Partially confirm tx1
        vm.prank(owner1);
        wallet.confirmTransaction(tx1);

        // Fully confirm tx2
        vm.prank(owner1);
        wallet.confirmTransaction(tx2);
        vm.prank(owner3);
        wallet.confirmTransaction(tx2);

        // Execute tx2 (tx1 still pending)
        wallet.executeTransaction(tx2);

        // Revoke confirmation for tx1
        vm.prank(owner1);
        wallet.revokeConfirmation(tx1);

        // Re-confirm and add second confirmation for tx1
        vm.prank(owner2);
        wallet.confirmTransaction(tx1);
        vm.prank(owner3);
        wallet.confirmTransaction(tx1);

        // Execute tx1
        wallet.executeTransaction(tx1);

        // Both should be executed
        (, , , bool executed1) = wallet.getTransaction(tx1);
        (, , , bool executed2) = wallet.getTransaction(tx2);
        assertTrue(executed1, "Transaction 1 should be executed");
        assertTrue(executed2, "Transaction 2 should be executed");
    }

    /*//////////////////////////////////////////////////////////////
                        FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzz_SubmitTransaction(address to, uint96 value) public {
        vm.assume(to != address(0));
        vm.assume(value <= address(wallet).balance);

        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(to, value, "");

        (address returnedTo, uint256 returnedValue, , bool executed) = wallet.getTransaction(txId);
        assertEq(returnedTo, to, "Destination should match");
        assertEq(returnedValue, value, "Value should match");
        assertFalse(executed, "Should not be executed");
    }

    function testFuzz_MultipleConfirmations(uint8 confirmCount) public {
        confirmCount = uint8(bound(confirmCount, 0, 3));

        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(recipient, 1 ether, "");

        if (confirmCount >= 1) {
            vm.prank(owner1);
            wallet.confirmTransaction(txId);
        }
        if (confirmCount >= 2) {
            vm.prank(owner2);
            wallet.confirmTransaction(txId);
        }
        if (confirmCount >= 3) {
            vm.prank(owner3);
            wallet.confirmTransaction(txId);
        }

        assertEq(wallet.getConfirmationCount(txId), confirmCount, "Confirmation count should match");
        assertEq(wallet.isThresholdMet(txId), confirmCount >= 2, "Threshold met should be correct");
    }
}

/**
 * @title Test Target Contract
 * @notice Simple contract for testing function calls
 */
contract TestTarget {
    uint256 public value;

    function setValue(uint256 _value) external {
        value = _value;
    }
}

/**
 * @title Malicious Reentrancy Contract
 * @notice Attempts to re-enter the wallet during execution
 */
contract MaliciousReentrancy {
    MultiSigWalletSolution public wallet;
    uint256 public callCount;

    constructor(MultiSigWalletSolution _wallet) {
        wallet = _wallet;
    }

    receive() external payable {
        callCount++;
        // Try to re-enter by executing the same transaction again
        // This should fail due to the executed flag being set
        if (callCount == 1) {
            try wallet.executeTransaction(0) {
                // If this succeeds, the wallet is vulnerable
            } catch {
                // Expected - wallet should revert
            }
        }
    }
}
