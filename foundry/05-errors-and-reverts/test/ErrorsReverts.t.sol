// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ErrorsReverts.sol";

/**
 * @title ErrorsRevertsTest
 * @notice Skeleton test suite for ErrorsReverts contract
 * @dev Complete the TODOs to implement comprehensive tests
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          TESTING ERROR HANDLING
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * Error handling is critical for user experience! We need to test:
 * - require() statements with string messages
 * - Custom errors with and without parameters
 * - assert() statements for invariants
 * - Gas comparison between error types
 * - Error propagation
 *
 * TESTING PATTERNS:
 * - Use vm.expectRevert() for error testing
 * - Use vm.expectRevert(ErrorsReverts.InsufficientBalance.selector) for custom errors
 * - Use descriptive test names: test_DepositWithRequire_RevertsForZeroAmount
 * - Follow Arrange-Act-Assert pattern
 */
contract ErrorsRevertsTest is Test {
    ErrorsReverts public errors;
    
    address public owner;
    address public user1;
    
    function setUp() public {
        // TODO: Deploy the ErrorsReverts contract
        //       The test contract (address(this)) will be the deployer
        //       What should the owner be set to?
        // Hint: errors = new ErrorsReverts();
        
        // TODO: Set owner to address(this) - the test contract is the deployer
        // Hint: owner = address(this);
        
        // TODO: Create user1 address (use makeAddr("user1"))
        //       This will be used to test unauthorized access
        // Hint: user1 = makeAddr("user1");
    }
    
    // ════════════════════════════════════════════════════════════════════════
    // CONSTRUCTOR TESTS
    // ════════════════════════════════════════════════════════════════════════
    
    function test_Constructor_SetsOwner() public {
        // TODO: Assert that errors.owner() equals owner
        //       What should the owner be set to in the constructor?
        // Hint: assertEq(errors.owner(), owner);
    }
    
    // ════════════════════════════════════════════════════════════════════════
    // require() TESTS
    // ════════════════════════════════════════════════════════════════════════
    
    function test_DepositWithRequire_RevertsForZeroAmount() public {
        // TODO: Use vm.expectRevert() to expect the revert
        //       Then call depositWithRequire(0)
        //       What error message should we expect?
        // Hint: vm.expectRevert("Amount must be positive");
        //       errors.depositWithRequire(0);
    }
    
    function test_DepositWithRequire_RevertsForNonOwner() public {
        // TODO: Use vm.prank(user1) to simulate user1 calling depositWithRequire
        //       Use vm.expectRevert() to expect the revert
        //       Then call depositWithRequire(100)
        //       What error message should we expect?
        // Hint: vm.prank(user1);
        //       vm.expectRevert("Only owner");
        //       errors.depositWithRequire(100);
    }
    
    function test_DepositWithRequire_WorksForOwner() public {
        // TODO: Call depositWithRequire(100) as owner (no prank needed)
        //       Assert that balance is now 100
        //       Assert that totalDeposits is now 100
        // Hint: errors.depositWithRequire(100);
        //       assertEq(errors.getBalance(), 100);
    }
    
    // ════════════════════════════════════════════════════════════════════════
    // CUSTOM ERROR TESTS
    // ════════════════════════════════════════════════════════════════════════
    
    function test_DepositWithCustomError_RevertsForZeroAmount() public {
        // TODO: Use vm.expectRevert() with the custom error selector
        //       For custom errors, use: vm.expectRevert(ErrorsReverts.InvalidAmount.selector)
        //       Then call depositWithCustomError(0)
        // Hint: vm.expectRevert(ErrorsReverts.InvalidAmount.selector);
        //       errors.depositWithCustomError(0);
    }
    
    function test_DepositWithCustomError_RevertsForNonOwner() public {
        // TODO: Use vm.prank(user1) to simulate user1 calling depositWithCustomError
        //       Use vm.expectRevert() with the custom error selector
        //       For custom errors with parameters, use: vm.expectRevert(abi.encodeWithSelector(ErrorsReverts.Unauthorized.selector, user1))
        //       Then call depositWithCustomError(100)
        // Hint: vm.prank(user1);
        //       vm.expectRevert(abi.encodeWithSelector(ErrorsReverts.Unauthorized.selector, user1));
        //       errors.depositWithCustomError(100);
    }
    
    function test_DepositWithCustomError_WorksForOwner() public {
        // TODO: Call depositWithCustomError(100) as owner
        //       Assert that balance is now 100
        //       Assert that totalDeposits is now 100
        // Hint: errors.depositWithCustomError(100);
        //       assertEq(errors.getBalance(), 100);
    }
    
    // ════════════════════════════════════════════════════════════════════════
    // WITHDRAW TESTS
    // ════════════════════════════════════════════════════════════════════════
    
    function test_Withdraw_RevertsForInsufficientBalance() public {
        // TODO: First deposit 100 using depositWithCustomError(100)
        //       Then try to withdraw 200 - it should revert
        //       Use vm.expectRevert() with the custom error selector and parameters
        //       For custom errors with parameters: vm.expectRevert(abi.encodeWithSelector(ErrorsReverts.InsufficientBalance.selector, 100, 200))
        // Hint: errors.depositWithCustomError(100);
        //       vm.expectRevert(abi.encodeWithSelector(ErrorsReverts.InsufficientBalance.selector, 100, 200));
        //       errors.withdraw(200);
    }
    
    function test_Withdraw_WorksWithSufficientBalance() public {
        // TODO: First deposit 100 using depositWithCustomError(100)
        //       Then withdraw 50
        //       Assert that balance is now 50
        // Hint: errors.depositWithCustomError(100);
        //       errors.withdraw(50);
        //       assertEq(errors.getBalance(), 50);
    }
    
    // ════════════════════════════════════════════════════════════════════════
    // assert() TESTS
    // ════════════════════════════════════════════════════════════════════════
    
    function test_CheckInvariant_WorksWhenInvariantHolds() public {
        // TODO: Deposit some amount
        //       Then call checkInvariant() - it should not revert
        //       (The invariant is: totalDeposits >= balance)
        // Hint: errors.depositWithCustomError(100);
        //       errors.checkInvariant(); // Should not revert
    }
    
    // ════════════════════════════════════════════════════════════════════════
    // GAS COMPARISON TESTS
    // ════════════════════════════════════════════════════════════════════════
    
    function test_Gas_CustomErrorVsRequire() public {
        // TODO: Compare gas costs of custom errors vs require()
        //       Use gasleft() before and after to measure gas
        //       Use try-catch to handle reverts
        //       Assert that custom errors use less gas
        // Hint: uint256 gasBefore = gasleft();
        //       try errors.depositWithRequire(0) {} catch {}
        //       uint256 requireGas = gasBefore - gasleft();
        //       gasBefore = gasleft();
        //       try errors.depositWithCustomError(0) {} catch {}
        //       uint256 customErrorGas = gasBefore - gasleft();
        //       assertTrue(customErrorGas < requireGas);
    }
}
