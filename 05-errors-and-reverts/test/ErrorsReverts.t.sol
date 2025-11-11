// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/ErrorsRevertsSolution.sol";

contract ErrorsRevertsTest is Test {
    ErrorsRevertsSolution public errors;
    
    function setUp() public {
        errors = new ErrorsRevertsSolution();
    }
    
    function test_CustomError_RevertsWithData() public {
        vm.expectRevert(abi.encodeWithSelector(InvalidAmount.selector));
        errors.depositWithCustomError(0);
    }
    
    function test_Require_RevertsWithString() public {
        vm.expectRevert("Amount must be positive");
        errors.depositWithRequire(0);
    }
    
    function test_InsufficientBalance_ShowsAmounts() public {
        errors.depositWithCustomError(100);
        
        vm.expectRevert(abi.encodeWithSelector(InsufficientBalance.selector, 100, 200));
        errors.withdraw(200);
    }
    
    function test_Gas_CustomErrorVsRequire() public {
        errors.depositWithCustomError(100);
        
        uint256 gasBefore = gasleft();
        try errors.depositWithRequire(0) {} catch {}
        uint256 requireGas = gasBefore - gasleft();
        
        gasBefore = gasleft();
        try errors.depositWithCustomError(0) {} catch {}
        uint256 customErrorGas = gasBefore - gasleft();
        
        emit log_named_uint("Require gas", requireGas);
        emit log_named_uint("Custom error gas", customErrorGas);
        assertTrue(customErrorGas < requireGas, "Custom errors should use less gas");
    }
}
