// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ModifiersRestrictions.sol";

/**
 * @title ModifiersRestrictionsTest
 * @notice Skeleton test suite for ModifiersRestrictions contract
 * @dev Complete the TODOs to implement comprehensive tests
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          TESTING ACCESS CONTROL
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * Access control is critical for security! We need to test:
 * - Only owner can call owner-only functions
 * - Only users with roles can call role-gated functions
 * - Roles can be granted and revoked correctly
 * - Pause mechanism works correctly
 * - Modifier composition works correctly
 *
 * TESTING PATTERNS:
 * - Use vm.prank() to simulate different callers
 * - Use vm.expectRevert() for access control failures
 * - Use descriptive test names: test_OnlyOwner_RevertsForNonOwner
 * - Follow Arrange-Act-Assert pattern
 */
contract ModifiersRestrictionsTest is Test {
    ModifiersRestrictions public modifiers;
    
    address public owner;
    address public user1;
    address public user2;
    address public admin;
    
    function setUp() public {
        // TODO: Deploy the ModifiersRestrictions contract
        //       The test contract (address(this)) will be the deployer
        //       What should the owner be set to? What roles are granted in constructor?
        // Hint: modifiers = new ModifiersRestrictions();
        
        // TODO: Set owner to address(this) - the test contract is the deployer
        // Hint: owner = address(this);
        
        // TODO: Create user1 and user2 addresses (use makeAddr("user1") and makeAddr("user2"))
        //       These will be used to test access control
        // Hint: user1 = makeAddr("user1");
        //       user2 = makeAddr("user2");
        
        // TODO: Create admin address (use makeAddr("admin"))
        //       This will be used to test admin role
        // Hint: admin = makeAddr("admin");
    }
    
    // ════════════════════════════════════════════════════════════════════════
    // CONSTRUCTOR TESTS
    // ════════════════════════════════════════════════════════════════════════
    
    function test_Constructor_SetsOwner() public {
        // TODO: Assert that modifiers.owner() equals owner
        //       What should the owner be set to in the constructor?
        // Hint: assertEq(modifiers.owner(), owner);
    }
    
    function test_Constructor_GrantsAdminRoleToDeployer() public {
        // TODO: Assert that deployer has ADMIN_ROLE
        //       Use modifiers.hasRole() to check
        // Hint: assertTrue(modifiers.hasRole(modifiers.ADMIN_ROLE(), owner));
    }
    
    function test_Constructor_GrantsMinterRoleToDeployer() public {
        // TODO: Assert that deployer has MINTER_ROLE
        //       Use modifiers.hasRole() to check
        // Hint: assertTrue(modifiers.hasRole(modifiers.MINTER_ROLE(), owner));
    }
    
    // ════════════════════════════════════════════════════════════════════════
    // ONLY OWNER TESTS
    // ════════════════════════════════════════════════════════════════════════
    
    function test_OnlyOwner_RevertsForNonOwner() public {
        // TODO: Use vm.prank(user1) to simulate user1 calling transferOwnership
        //       Use vm.expectRevert() to expect the revert
        //       Then call modifiers.transferOwnership(user2)
        //       What error message should we expect?
        // Hint: vm.prank(user1);
        //       vm.expectRevert("Not owner");
        //       modifiers.transferOwnership(user2);
    }
    
    function test_OnlyOwner_AllowsOwner() public {
        // TODO: Call transferOwnership as owner (no prank needed)
        //       Transfer ownership to user1
        //       Assert that owner is now user1
        // Hint: modifiers.transferOwnership(user1);
        //       assertEq(modifiers.owner(), user1);
    }
    
    function test_TransferOwnership_RevertsForZeroAddress() public {
        // TODO: Call transferOwnership with address(0)
        //       Use vm.expectRevert() to expect the revert
        //       What error message should we expect?
        // Hint: vm.expectRevert("Invalid address");
        //       modifiers.transferOwnership(address(0));
    }
    
    // ════════════════════════════════════════════════════════════════════════
    // ROLE MANAGEMENT TESTS
    // ════════════════════════════════════════════════════════════════════════
    
    function test_GrantRole_Works() public {
        // TODO: Grant MINTER_ROLE to user1
        //       Assert that user1 now has MINTER_ROLE
        // Hint: modifiers.grantRole(modifiers.MINTER_ROLE(), user1);
        //       assertTrue(modifiers.hasRole(modifiers.MINTER_ROLE(), user1));
    }
    
    function test_GrantRole_RevertsForNonOwner() public {
        // TODO: Use vm.prank(user1) to simulate user1 calling grantRole
        //       Use vm.expectRevert() to expect the revert
        //       Then call grantRole
        // Hint: vm.prank(user1);
        //       vm.expectRevert("Not owner");
        //       modifiers.grantRole(modifiers.MINTER_ROLE(), user2);
    }
    
    function test_RevokeRole_Works() public {
        // TODO: First grant MINTER_ROLE to user1
        //       Then revoke MINTER_ROLE from user1
        //       Assert that user1 no longer has MINTER_ROLE
        // Hint: modifiers.grantRole(modifiers.MINTER_ROLE(), user1);
        //       modifiers.revokeRole(modifiers.MINTER_ROLE(), user1);
        //       assertFalse(modifiers.hasRole(modifiers.MINTER_ROLE(), user1));
    }
    
    // ════════════════════════════════════════════════════════════════════════
    // PAUSE TESTS
    // ════════════════════════════════════════════════════════════════════════
    
    function test_Pause_PreventsOperations() public {
        // TODO: Grant ADMIN_ROLE to admin first
        //       Then use vm.prank(admin) to pause the contract
        //       Then try to call incrementCounter() - it should revert
        //       Use vm.expectRevert() to expect the revert
        // Hint: modifiers.grantRole(modifiers.ADMIN_ROLE(), admin);
        //       vm.prank(admin);
        //       modifiers.pause();
        //       vm.expectRevert("Contract paused");
        //       modifiers.incrementCounter();
    }
    
    function test_Unpause_AllowsOperations() public {
        // TODO: Grant ADMIN_ROLE to admin first
        //       Pause the contract
        //       Then unpause the contract
        //       Then call incrementCounter() - it should work
        //       Assert that counter is 1
        // Hint: modifiers.grantRole(modifiers.ADMIN_ROLE(), admin);
        //       vm.prank(admin);
        //       modifiers.pause();
        //       vm.prank(admin);
        //       modifiers.unpause();
        //       modifiers.incrementCounter();
        //       assertEq(modifiers.counter(), 1);
    }
    
    function test_Pause_RevertsForNonAdmin() public {
        // TODO: Use vm.prank(user1) to simulate user1 calling pause
        //       Use vm.expectRevert() to expect the revert
        //       Then call pause
        // Hint: vm.prank(user1);
        //       vm.expectRevert("Missing role");
        //       modifiers.pause();
    }
    
    // ════════════════════════════════════════════════════════════════════════
    // MODIFIER COMPOSITION TESTS
    // ════════════════════════════════════════════════════════════════════════
    
    function test_Mint_RequiresMinterRoleAndNotPaused() public {
        // TODO: Grant MINTER_ROLE to user1
        //       Use vm.prank(user1) to call mint
        //       It should work (contract is not paused by default)
        // Hint: modifiers.grantRole(modifiers.MINTER_ROLE(), user1);
        //       vm.prank(user1);
        //       modifiers.mint(user2);
    }
    
    function test_Mint_RevertsWhenPaused() public {
        // TODO: Grant ADMIN_ROLE and MINTER_ROLE to admin
        //       Pause the contract
        //       Then try to mint - it should revert
        // Hint: modifiers.grantRole(modifiers.ADMIN_ROLE(), admin);
        //       modifiers.grantRole(modifiers.MINTER_ROLE(), admin);
        //       vm.prank(admin);
        //       modifiers.pause();
        //       vm.prank(admin);
        //       vm.expectRevert("Contract paused");
        //       modifiers.mint(user1);
    }
    
    function test_Mint_RevertsWithoutMinterRole() public {
        // TODO: Try to call mint without MINTER_ROLE
        //       Use vm.prank(user1) and vm.expectRevert()
        // Hint: vm.prank(user1);
        //       vm.expectRevert("Missing role");
        //       modifiers.mint(user2);
    }
}
