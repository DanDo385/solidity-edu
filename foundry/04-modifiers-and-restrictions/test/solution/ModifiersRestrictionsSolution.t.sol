// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/solution/ModifiersRestrictionsSolution.sol";

/**
 * @title ModifiersRestrictionsSolutionTest
 * @notice Comprehensive test suite for ModifiersRestrictions contract
 * @dev Reference implementation showing best practices for testing access control
 */
contract ModifiersRestrictionsSolutionTest is Test {
    ModifiersRestrictionsSolution public modifiers;
    
    address public owner;
    address public user1;
    address public user2;
    address public admin;
    
    function setUp() public {
        modifiers = new ModifiersRestrictionsSolution();
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        admin = makeAddr("admin");
    }
    
    // ════════════════════════════════════════════════════════════════════════
    // CONSTRUCTOR TESTS
    // ════════════════════════════════════════════════════════════════════════
    
    function test_Constructor_SetsOwner() public {
        assertEq(modifiers.owner(), owner);
    }
    
    function test_Constructor_GrantsAdminRoleToDeployer() public {
        assertTrue(modifiers.hasRole(modifiers.ADMIN_ROLE(), owner));
    }
    
    function test_Constructor_GrantsMinterRoleToDeployer() public {
        assertTrue(modifiers.hasRole(modifiers.MINTER_ROLE(), owner));
    }
    
    // ════════════════════════════════════════════════════════════════════════
    // ONLY OWNER TESTS
    // ════════════════════════════════════════════════════════════════════════
    
    function test_OnlyOwner_RevertsForNonOwner() public {
        vm.prank(user1);
        vm.expectRevert("Not owner");
        modifiers.transferOwnership(user2);
    }
    
    function test_OnlyOwner_AllowsOwner() public {
        modifiers.transferOwnership(user1);
        assertEq(modifiers.owner(), user1);
    }
    
    function test_TransferOwnership_RevertsForZeroAddress() public {
        vm.expectRevert("Invalid address");
        modifiers.transferOwnership(address(0));
    }
    
    // ════════════════════════════════════════════════════════════════════════
    // ROLE MANAGEMENT TESTS
    // ════════════════════════════════════════════════════════════════════════
    
    function test_GrantRole_Works() public {
        modifiers.grantRole(modifiers.MINTER_ROLE(), user1);
        assertTrue(modifiers.hasRole(modifiers.MINTER_ROLE(), user1));
    }
    
    function test_GrantRole_RevertsForNonOwner() public {
        vm.prank(user1);
        vm.expectRevert("Not owner");
        modifiers.grantRole(modifiers.MINTER_ROLE(), user2);
    }
    
    function test_GrantRole_RevertsIfAlreadyGranted() public {
        modifiers.grantRole(modifiers.MINTER_ROLE(), user1);
        vm.expectRevert("Role already granted");
        modifiers.grantRole(modifiers.MINTER_ROLE(), user1);
    }
    
    function test_RevokeRole_Works() public {
        modifiers.grantRole(modifiers.MINTER_ROLE(), user1);
        modifiers.revokeRole(modifiers.MINTER_ROLE(), user1);
        assertFalse(modifiers.hasRole(modifiers.MINTER_ROLE(), user1));
    }
    
    function test_RevokeRole_RevertsIfNotGranted() public {
        vm.expectRevert("Role not granted");
        modifiers.revokeRole(modifiers.MINTER_ROLE(), user1);
    }
    
    // ════════════════════════════════════════════════════════════════════════
    // PAUSE TESTS
    // ════════════════════════════════════════════════════════════════════════
    
    function test_Pause_PreventsOperations() public {
        modifiers.grantRole(modifiers.ADMIN_ROLE(), admin);
        vm.prank(admin);
        modifiers.pause();
        
        vm.expectRevert("Contract paused");
        modifiers.incrementCounter();
    }
    
    function test_Unpause_AllowsOperations() public {
        modifiers.grantRole(modifiers.ADMIN_ROLE(), admin);
        vm.prank(admin);
        modifiers.pause();
        vm.prank(admin);
        modifiers.unpause();
        
        modifiers.incrementCounter();
        assertEq(modifiers.counter(), 1);
    }
    
    function test_Pause_RevertsForNonAdmin() public {
        vm.prank(user1);
        vm.expectRevert("Missing role");
        modifiers.pause();
    }
    
    function test_Pause_RevertsIfAlreadyPaused() public {
        modifiers.grantRole(modifiers.ADMIN_ROLE(), admin);
        vm.prank(admin);
        modifiers.pause();
        vm.prank(admin);
        vm.expectRevert("Already paused");
        modifiers.pause();
    }
    
    function test_Unpause_RevertsIfNotPaused() public {
        modifiers.grantRole(modifiers.ADMIN_ROLE(), admin);
        vm.prank(admin);
        vm.expectRevert("Contract not paused");
        modifiers.unpause();
    }
    
    // ════════════════════════════════════════════════════════════════════════
    // MODIFIER COMPOSITION TESTS
    // ════════════════════════════════════════════════════════════════════════
    
    function test_Mint_RequiresMinterRoleAndNotPaused() public {
        modifiers.grantRole(modifiers.MINTER_ROLE(), user1);
        vm.prank(user1);
        modifiers.mint(user2);
        // Should not revert
    }
    
    function test_Mint_RevertsWhenPaused() public {
        modifiers.grantRole(modifiers.ADMIN_ROLE(), admin);
        modifiers.grantRole(modifiers.MINTER_ROLE(), admin);
        vm.prank(admin);
        modifiers.pause();
        vm.prank(admin);
        vm.expectRevert("Contract paused");
        modifiers.mint(user1);
    }
    
    function test_Mint_RevertsWithoutMinterRole() public {
        vm.prank(user1);
        vm.expectRevert("Missing role");
        modifiers.mint(user2);
    }
    
    function test_IncrementCounter_WorksWhenNotPaused() public {
        modifiers.incrementCounter();
        assertEq(modifiers.counter(), 1);
    }
    
    function test_IncrementCounter_RevertsWhenPaused() public {
        modifiers.grantRole(modifiers.ADMIN_ROLE(), admin);
        vm.prank(admin);
        modifiers.pause();
        vm.expectRevert("Contract paused");
        modifiers.incrementCounter();
    }
}
