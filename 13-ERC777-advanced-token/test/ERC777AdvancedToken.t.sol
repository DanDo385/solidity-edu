// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/ERC777AdvancedTokenSolution.sol";

contract ERC777AdvancedTokenTest is Test {
    ERC777AdvancedTokenSolution public token;
    address public alice;
    address public bob;
    
    function setUp() public {
        address[] memory defaultOps = new address[](0);
        token = new ERC777AdvancedTokenSolution("Advanced Token", "ADV", 1000000e18, defaultOps);
        alice = makeAddr("alice");
        bob = makeAddr("bob");
    }
    
    function test_Send_Works() public {
        token.send(alice, 1000e18, "");
        assertEq(token.balanceOf(alice), 1000e18);
    }
    
    function test_AuthorizeOperator_Works() public {
        vm.prank(alice);
        token.authorizeOperator(bob);
        assertTrue(token.isOperatorFor(bob, alice));
    }
    
    function test_OperatorSend_Works() public {
        token.send(alice, 1000e18, "");
        
        vm.prank(alice);
        token.authorizeOperator(bob);
        
        vm.prank(bob);
        token.operatorSend(alice, address(this), 500e18, "", "");
        
        assertEq(token.balanceOf(alice), 500e18);
    }
    
    function test_ERC20_Transfer_Works() public {
        token.transfer(alice, 1000e18);
        assertEq(token.balanceOf(alice), 1000e18);
    }
}
