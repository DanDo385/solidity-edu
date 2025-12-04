// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/ERC20TokenSolution.sol";

contract ERC20TokenTest is Test {
    ERC20TokenSolution public token;
    address public user1;
    address public user2;
    
    function setUp() public {
        token = new ERC20TokenSolution("Test Token", "TEST", 1000000);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
    }
    
    function test_InitialSupply() public {
        assertEq(token.totalSupply(), 1000000 * 10**18);
        assertEq(token.balanceOf(address(this)), 1000000 * 10**18);
    }
    
    function test_Transfer_Works() public {
        uint256 amount = 1000 * 10**18;
        token.transfer(user1, amount);
        
        assertEq(token.balanceOf(user1), amount);
        assertEq(token.balanceOf(address(this)), 1000000 * 10**18 - amount);
    }
    
    function test_Approve_SetsAllowance() public {
        uint256 amount = 500 * 10**18;
        token.approve(user1, amount);
        
        assertEq(token.allowance(address(this), user1), amount);
    }
    
    function test_TransferFrom_Works() public {
        uint256 amount = 100 * 10**18;
        token.approve(user1, amount);
        
        vm.prank(user1);
        token.transferFrom(address(this), user2, amount);
        
        assertEq(token.balanceOf(user2), amount);
    }
    
    function test_Transfer_RevertsOnInsufficientBalance() public {
        vm.prank(user1);
        vm.expectRevert("Insufficient balance");
        token.transfer(user2, 1);
    }
}
