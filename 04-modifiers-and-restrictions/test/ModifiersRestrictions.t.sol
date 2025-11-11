// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/ModifiersRestrictionsSolution.sol";

contract ModifiersRestrictionsTest is Test {
    ModifiersRestrictionsSolution public modifiers;
    address public owner;
    address public user1;
    address public user2;
    
    function setUp() public {
        modifiers = new ModifiersRestrictionsSolution();
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
    }
    
    function test_OnlyOwner_RevertsForNonOwner() public {
        vm.prank(user1);
        vm.expectRevert("Not owner");
        modifiers.transferOwnership(user2);
    }
    
    function test_OnlyOwner_AllowsOwner() public {
        modifiers.transferOwnership(user1);
        assertEq(modifiers.owner(), user1);
    }
    
    function test_GrantRole_Works() public {
        modifiers.grantRole(modifiers.MINTER_ROLE(), user1);
        assertTrue(modifiers.hasRole(modifiers.MINTER_ROLE(), user1));
    }
    
    function test_RevokeRole_Works() public {
        modifiers.grantRole(modifiers.MINTER_ROLE(), user1);
        modifiers.revokeRole(modifiers.MINTER_ROLE(), user1);
        assertFalse(modifiers.hasRole(modifiers.MINTER_ROLE(), user1));
    }
    
    function test_Pause_PreventsOperations() public {
        modifiers.pause();
        
        vm.expectRevert("Contract paused");
        modifiers.incrementCounter();
    }
    
    function test_Unpause_AllowsOperations() public {
        modifiers.pause();
        modifiers.unpause();
        
        modifiers.incrementCounter();
        assertEq(modifiers.counter(), 1);
    }
}
