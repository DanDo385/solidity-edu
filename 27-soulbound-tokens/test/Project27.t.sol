// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Project27.sol";
import "../src/solution/Project27Solution.sol";

/**
 * @title Project27Test
 * @notice Comprehensive test suite for Soulbound Token implementation
 * @dev Tests cover:
 *      - Transfer prevention
 *      - Revocation mechanism
 *      - Recovery mechanism
 *      - EIP-5192 compliance
 *      - Edge cases and security
 */
contract Project27Test is Test {
    SoulboundTokenSolution public sbt;

    // Test addresses
    address public owner;
    address public issuer1;
    address public issuer2;
    address public holder1;
    address public holder2;
    address public attacker;

    // Events to test
    event Locked(uint256 indexed tokenId);
    event Unlocked(uint256 indexed tokenId);
    event Revoked(uint256 indexed tokenId, address indexed holder, address indexed issuer);
    event RecoveryInitiated(
        uint256 indexed tokenId,
        address indexed currentOwner,
        address indexed newOwner,
        uint256 readyTime
    );
    event RecoveryCompleted(uint256 indexed tokenId, address indexed oldOwner, address indexed newOwner);
    event RecoveryCancelled(uint256 indexed tokenId);

    function setUp() public {
        owner = address(this);
        issuer1 = makeAddr("issuer1");
        issuer2 = makeAddr("issuer2");
        holder1 = makeAddr("holder1");
        holder2 = makeAddr("holder2");
        attacker = makeAddr("attacker");

        sbt = new SoulboundTokenSolution();
    }

    // ============================================
    // MINTING TESTS
    // ============================================

    function test_Mint_Success() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        assertEq(tokenId, 0, "First token should have ID 0");
        assertEq(sbt.ownerOf(tokenId), holder1, "Holder should own the token");
        assertEq(sbt.issuer(tokenId), issuer1, "Issuer should be recorded");
    }

    function test_Mint_EmitsLockedEvent() public {
        vm.expectEmit(true, false, false, false);
        emit Locked(0);

        vm.prank(issuer1);
        sbt.mint(holder1);
    }

    function test_Mint_IncrementTokenId() public {
        vm.startPrank(issuer1);

        uint256 tokenId1 = sbt.mint(holder1);
        uint256 tokenId2 = sbt.mint(holder2);
        uint256 tokenId3 = sbt.mint(holder1);

        assertEq(tokenId1, 0);
        assertEq(tokenId2, 1);
        assertEq(tokenId3, 2);

        vm.stopPrank();
    }

    function test_Mint_MultipleIssuers() public {
        vm.prank(issuer1);
        uint256 tokenId1 = sbt.mint(holder1);

        vm.prank(issuer2);
        uint256 tokenId2 = sbt.mint(holder2);

        assertEq(sbt.issuer(tokenId1), issuer1);
        assertEq(sbt.issuer(tokenId2), issuer2);
    }

    // ============================================
    // EIP-5192 COMPLIANCE TESTS
    // ============================================

    function test_Locked_ReturnsTrueForExistingToken() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        assertTrue(sbt.locked(tokenId), "Token should be locked");
    }

    function test_Locked_RevertsForNonExistentToken() public {
        vm.expectRevert(SoulboundTokenSolution.TokenDoesNotExist.selector);
        sbt.locked(999);
    }

    function test_SupportsInterface_EIP5192() public {
        // EIP-5192 interface ID: 0xb45a3c0e
        assertTrue(sbt.supportsInterface(0xb45a3c0e), "Should support EIP-5192");
    }

    function test_SupportsInterface_ERC721() public {
        // ERC721 interface ID: 0x80ac58cd
        assertTrue(sbt.supportsInterface(0x80ac58cd), "Should support ERC721");
    }

    // ============================================
    // TRANSFER PREVENTION TESTS
    // ============================================

    function test_Transfer_RevertsAfterMint() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        vm.prank(holder1);
        vm.expectRevert(SoulboundTokenSolution.TransferNotAllowed.selector);
        sbt.transferFrom(holder1, holder2, tokenId);
    }

    function test_SafeTransfer_RevertsAfterMint() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        vm.prank(holder1);
        vm.expectRevert(SoulboundTokenSolution.TransferNotAllowed.selector);
        sbt.safeTransferFrom(holder1, holder2, tokenId);
    }

    function test_Transfer_RevertsEvenAfterApproval() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        vm.prank(holder1);
        sbt.approve(holder2, tokenId);

        vm.prank(holder2);
        vm.expectRevert(SoulboundTokenSolution.TransferNotAllowed.selector);
        sbt.transferFrom(holder1, holder2, tokenId);
    }

    function test_Transfer_RevertsWithApprovalForAll() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        vm.prank(holder1);
        sbt.setApprovalForAll(holder2, true);

        vm.prank(holder2);
        vm.expectRevert(SoulboundTokenSolution.TransferNotAllowed.selector);
        sbt.transferFrom(holder1, holder2, tokenId);
    }

    function test_Burn_AllowedByOwner() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        // Owner should be able to burn their own token
        // Note: In standard ERC721, _burn is internal
        // This test verifies burning works via revoke
        vm.prank(issuer1);
        sbt.revoke(tokenId);

        vm.expectRevert();
        sbt.ownerOf(tokenId);
    }

    // ============================================
    // REVOCATION TESTS
    // ============================================

    function test_Revoke_SuccessByIssuer() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        vm.prank(issuer1);
        sbt.revoke(tokenId);

        // Token should no longer exist
        vm.expectRevert();
        sbt.ownerOf(tokenId);
    }

    function test_Revoke_EmitsRevokedEvent() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        vm.expectEmit(true, true, true, false);
        emit Revoked(tokenId, holder1, issuer1);

        vm.prank(issuer1);
        sbt.revoke(tokenId);
    }

    function test_Revoke_RevertsIfNotIssuer() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        vm.prank(issuer2);
        vm.expectRevert(SoulboundTokenSolution.NotIssuer.selector);
        sbt.revoke(tokenId);
    }

    function test_Revoke_RevertsIfNotOwner() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        vm.prank(owner);
        vm.expectRevert(SoulboundTokenSolution.NotIssuer.selector);
        sbt.revoke(tokenId);
    }

    function test_Revoke_RevertsIfNotHolder() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        vm.prank(holder1);
        vm.expectRevert(SoulboundTokenSolution.NotIssuer.selector);
        sbt.revoke(tokenId);
    }

    function test_Revoke_CleansUpRecoveryRequest() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        // Initiate recovery
        vm.prank(holder1);
        sbt.initiateRecovery(tokenId, holder2);

        // Verify recovery is in progress
        assertTrue(sbt.hasRecoveryInProgress(tokenId));

        // Revoke the token
        vm.prank(issuer1);
        sbt.revoke(tokenId);

        // Recovery should be cleaned up (but token doesn't exist, so check reverts)
        vm.expectRevert();
        sbt.hasRecoveryInProgress(tokenId);
    }

    // ============================================
    // RECOVERY INITIATION TESTS
    // ============================================

    function test_InitiateRecovery_Success() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        vm.prank(holder1);
        sbt.initiateRecovery(tokenId, holder2);

        assertTrue(sbt.hasRecoveryInProgress(tokenId), "Recovery should be in progress");

        (address newOwner, uint256 requestTime, uint256 readyTime) = sbt.getRecoveryRequest(tokenId);
        assertEq(newOwner, holder2);
        assertEq(requestTime, block.timestamp);
        assertEq(readyTime, block.timestamp + sbt.RECOVERY_DELAY());
    }

    function test_InitiateRecovery_EmitsEvent() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        vm.expectEmit(true, true, true, false);
        emit RecoveryInitiated(tokenId, holder1, holder2, block.timestamp + sbt.RECOVERY_DELAY());

        vm.prank(holder1);
        sbt.initiateRecovery(tokenId, holder2);
    }

    function test_InitiateRecovery_RevertsIfNotOwner() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        vm.prank(attacker);
        vm.expectRevert(SoulboundTokenSolution.NotTokenOwner.selector);
        sbt.initiateRecovery(tokenId, holder2);
    }

    function test_InitiateRecovery_RevertsIfZeroAddress() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        vm.prank(holder1);
        vm.expectRevert(SoulboundTokenSolution.InvalidRecoveryAddress.selector);
        sbt.initiateRecovery(tokenId, address(0));
    }

    function test_InitiateRecovery_RevertsIfSameAddress() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        vm.prank(holder1);
        vm.expectRevert(SoulboundTokenSolution.InvalidRecoveryAddress.selector);
        sbt.initiateRecovery(tokenId, holder1);
    }

    function test_InitiateRecovery_CanOverridePreviousRequest() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        vm.startPrank(holder1);

        // First recovery request
        sbt.initiateRecovery(tokenId, holder2);

        // Override with new recovery request
        address holder3 = makeAddr("holder3");
        sbt.initiateRecovery(tokenId, holder3);

        vm.stopPrank();

        (address newOwner,,) = sbt.getRecoveryRequest(tokenId);
        assertEq(newOwner, holder3, "Should override to new address");
    }

    // ============================================
    // RECOVERY COMPLETION TESTS
    // ============================================

    function test_CompleteRecovery_Success() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        vm.prank(holder1);
        sbt.initiateRecovery(tokenId, holder2);

        // Fast forward past recovery delay
        vm.warp(block.timestamp + sbt.RECOVERY_DELAY() + 1);

        sbt.completeRecovery(tokenId);

        assertEq(sbt.ownerOf(tokenId), holder2, "Token should be owned by new holder");
        assertFalse(sbt.hasRecoveryInProgress(tokenId), "Recovery should be complete");
    }

    function test_CompleteRecovery_EmitsEvent() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        vm.prank(holder1);
        sbt.initiateRecovery(tokenId, holder2);

        vm.warp(block.timestamp + sbt.RECOVERY_DELAY() + 1);

        vm.expectEmit(true, true, true, false);
        emit RecoveryCompleted(tokenId, holder1, holder2);

        sbt.completeRecovery(tokenId);
    }

    function test_CompleteRecovery_AnyoneCanComplete() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        vm.prank(holder1);
        sbt.initiateRecovery(tokenId, holder2);

        vm.warp(block.timestamp + sbt.RECOVERY_DELAY() + 1);

        // Attacker completes recovery (but it still goes to holder2)
        vm.prank(attacker);
        sbt.completeRecovery(tokenId);

        assertEq(sbt.ownerOf(tokenId), holder2, "Token should be owned by designated new holder");
    }

    function test_CompleteRecovery_RevertsIfNoRecovery() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        vm.expectRevert(SoulboundTokenSolution.NoRecoveryInProgress.selector);
        sbt.completeRecovery(tokenId);
    }

    function test_CompleteRecovery_RevertsIfNotReady() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        vm.prank(holder1);
        sbt.initiateRecovery(tokenId, holder2);

        // Try to complete before delay
        vm.warp(block.timestamp + sbt.RECOVERY_DELAY() - 1);

        vm.expectRevert(SoulboundTokenSolution.RecoveryNotReady.selector);
        sbt.completeRecovery(tokenId);
    }

    function test_CompleteRecovery_ExactlyAtDelay() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        vm.prank(holder1);
        sbt.initiateRecovery(tokenId, holder2);

        // Complete exactly at delay time (should still fail as we need > not >=)
        vm.warp(block.timestamp + sbt.RECOVERY_DELAY());

        vm.expectRevert(SoulboundTokenSolution.RecoveryNotReady.selector);
        sbt.completeRecovery(tokenId);
    }

    // ============================================
    // RECOVERY CANCELLATION TESTS
    // ============================================

    function test_CancelRecovery_Success() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        vm.prank(holder1);
        sbt.initiateRecovery(tokenId, holder2);

        assertTrue(sbt.hasRecoveryInProgress(tokenId));

        vm.prank(holder1);
        sbt.cancelRecovery(tokenId);

        assertFalse(sbt.hasRecoveryInProgress(tokenId), "Recovery should be cancelled");
    }

    function test_CancelRecovery_EmitsEvent() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        vm.prank(holder1);
        sbt.initiateRecovery(tokenId, holder2);

        vm.expectEmit(true, false, false, false);
        emit RecoveryCancelled(tokenId);

        vm.prank(holder1);
        sbt.cancelRecovery(tokenId);
    }

    function test_CancelRecovery_RevertsIfNotOwner() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        vm.prank(holder1);
        sbt.initiateRecovery(tokenId, holder2);

        vm.prank(attacker);
        vm.expectRevert(SoulboundTokenSolution.NotTokenOwner.selector);
        sbt.cancelRecovery(tokenId);
    }

    function test_CancelRecovery_RevertsIfNoRecovery() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        vm.prank(holder1);
        vm.expectRevert(SoulboundTokenSolution.NoRecoveryInProgress.selector);
        sbt.cancelRecovery(tokenId);
    }

    function test_CancelRecovery_AfterDelay() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        vm.prank(holder1);
        sbt.initiateRecovery(tokenId, holder2);

        // Fast forward past delay
        vm.warp(block.timestamp + sbt.RECOVERY_DELAY() + 1);

        // Should still be able to cancel
        vm.prank(holder1);
        sbt.cancelRecovery(tokenId);

        assertFalse(sbt.hasRecoveryInProgress(tokenId));
    }

    // ============================================
    // COMPLEX SCENARIOS
    // ============================================

    function test_Scenario_RecoveryAfterRevocationFails() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        vm.prank(holder1);
        sbt.initiateRecovery(tokenId, holder2);

        // Issuer revokes before recovery completes
        vm.prank(issuer1);
        sbt.revoke(tokenId);

        // Try to complete recovery
        vm.warp(block.timestamp + sbt.RECOVERY_DELAY() + 1);

        vm.expectRevert(); // Token doesn't exist
        sbt.completeRecovery(tokenId);
    }

    function test_Scenario_MultipleRecoveriesInSequence() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        // First recovery: holder1 -> holder2
        vm.prank(holder1);
        sbt.initiateRecovery(tokenId, holder2);

        vm.warp(block.timestamp + sbt.RECOVERY_DELAY() + 1);
        sbt.completeRecovery(tokenId);

        assertEq(sbt.ownerOf(tokenId), holder2);

        // Second recovery: holder2 -> holder1
        vm.prank(holder2);
        sbt.initiateRecovery(tokenId, holder1);

        vm.warp(block.timestamp + sbt.RECOVERY_DELAY() + 1);
        sbt.completeRecovery(tokenId);

        assertEq(sbt.ownerOf(tokenId), holder1);
    }

    function test_Scenario_MultipleTokensSameHolder() public {
        vm.startPrank(issuer1);
        uint256 tokenId1 = sbt.mint(holder1);
        uint256 tokenId2 = sbt.mint(holder1);
        uint256 tokenId3 = sbt.mint(holder1);
        vm.stopPrank();

        assertEq(sbt.ownerOf(tokenId1), holder1);
        assertEq(sbt.ownerOf(tokenId2), holder1);
        assertEq(sbt.ownerOf(tokenId3), holder1);

        // Each should be independently recoverable
        vm.startPrank(holder1);
        sbt.initiateRecovery(tokenId1, holder2);
        sbt.initiateRecovery(tokenId2, holder2);
        vm.stopPrank();

        assertTrue(sbt.hasRecoveryInProgress(tokenId1));
        assertTrue(sbt.hasRecoveryInProgress(tokenId2));
        assertFalse(sbt.hasRecoveryInProgress(tokenId3));
    }

    function test_Scenario_RecoverToNewAddressThenTransferFails() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        vm.prank(holder1);
        sbt.initiateRecovery(tokenId, holder2);

        vm.warp(block.timestamp + sbt.RECOVERY_DELAY() + 1);
        sbt.completeRecovery(tokenId);

        assertEq(sbt.ownerOf(tokenId), holder2);

        // Try to transfer (should still fail)
        address holder3 = makeAddr("holder3");
        vm.prank(holder2);
        vm.expectRevert(SoulboundTokenSolution.TransferNotAllowed.selector);
        sbt.transferFrom(holder2, holder3, tokenId);
    }

    // ============================================
    // VIEW FUNCTION TESTS
    // ============================================

    function test_GetCurrentTokenId() public {
        assertEq(sbt.getCurrentTokenId(), 0);

        vm.prank(issuer1);
        sbt.mint(holder1);

        assertEq(sbt.getCurrentTokenId(), 1);

        vm.prank(issuer1);
        sbt.mint(holder2);

        assertEq(sbt.getCurrentTokenId(), 2);
    }

    function test_HasRecoveryInProgress() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        assertFalse(sbt.hasRecoveryInProgress(tokenId));

        vm.prank(holder1);
        sbt.initiateRecovery(tokenId, holder2);

        assertTrue(sbt.hasRecoveryInProgress(tokenId));

        vm.prank(holder1);
        sbt.cancelRecovery(tokenId);

        assertFalse(sbt.hasRecoveryInProgress(tokenId));
    }

    function test_GetRecoveryRequest() public {
        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        vm.prank(holder1);
        sbt.initiateRecovery(tokenId, holder2);

        (address newOwner, uint256 requestTime, uint256 readyTime) = sbt.getRecoveryRequest(tokenId);

        assertEq(newOwner, holder2);
        assertEq(requestTime, block.timestamp);
        assertEq(readyTime, block.timestamp + sbt.RECOVERY_DELAY());
    }

    // ============================================
    // FUZZ TESTS
    // ============================================

    function testFuzz_Mint_AnyAddress(address to) public {
        vm.assume(to != address(0));

        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(to);

        assertEq(sbt.ownerOf(tokenId), to);
    }

    function testFuzz_Transfer_AlwaysReverts(address from, address to, uint256 tokenId) public {
        vm.assume(from != address(0) && to != address(0));
        vm.assume(tokenId < 1000);

        vm.prank(issuer1);
        sbt.mint(from);

        vm.prank(from);
        vm.expectRevert(SoulboundTokenSolution.TransferNotAllowed.selector);
        sbt.transferFrom(from, to, 0);
    }

    function testFuzz_RecoveryDelay_EnforcesPeriod(uint256 delay) public {
        vm.assume(delay > 0 && delay < sbt.RECOVERY_DELAY());

        vm.prank(issuer1);
        uint256 tokenId = sbt.mint(holder1);

        vm.prank(holder1);
        sbt.initiateRecovery(tokenId, holder2);

        vm.warp(block.timestamp + delay);

        vm.expectRevert(SoulboundTokenSolution.RecoveryNotReady.selector);
        sbt.completeRecovery(tokenId);
    }
}

/**
 * @title AlternativePatternsTest
 * @notice Tests for alternative SBT implementations
 */
contract AlternativePatternsTest is Test {
    PermanentSoulboundToken public permanent;
    TimeLockedSoulboundToken public timeLocked;

    address public holder1;
    address public holder2;

    function setUp() public {
        permanent = new PermanentSoulboundToken();
        timeLocked = new TimeLockedSoulboundToken();

        holder1 = makeAddr("holder1");
        holder2 = makeAddr("holder2");
    }

    // ============================================
    // PERMANENT SOULBOUND TESTS
    // ============================================

    function test_Permanent_TransferAlwaysReverts() public {
        uint256 tokenId = permanent.mint(holder1);

        vm.prank(holder1);
        vm.expectRevert("Soulbound: Transfer not allowed");
        permanent.transferFrom(holder1, holder2, tokenId);
    }

    function test_Permanent_AlwaysLocked() public {
        uint256 tokenId = permanent.mint(holder1);
        assertTrue(permanent.locked(tokenId));
    }

    // ============================================
    // TIME-LOCKED SOULBOUND TESTS
    // ============================================

    function test_TimeLocked_InitiallyUnlocked() public {
        uint256 tokenId = timeLocked.mint(holder1);
        assertFalse(timeLocked.locked(tokenId), "Should be unlocked initially");
    }

    function test_TimeLocked_TransferAllowedBeforeLock() public {
        uint256 tokenId = timeLocked.mint(holder1);

        vm.prank(holder1);
        timeLocked.transferFrom(holder1, holder2, tokenId);

        assertEq(timeLocked.ownerOf(tokenId), holder2);
    }

    function test_TimeLocked_BecomesLockedAfterPeriod() public {
        uint256 tokenId = timeLocked.mint(holder1);

        vm.warp(block.timestamp + timeLocked.LOCK_DURATION() + 1);

        assertTrue(timeLocked.locked(tokenId), "Should be locked after duration");
    }

    function test_TimeLocked_TransferRevertsAfterLock() public {
        uint256 tokenId = timeLocked.mint(holder1);

        vm.warp(block.timestamp + timeLocked.LOCK_DURATION() + 1);

        vm.prank(holder1);
        vm.expectRevert("Soulbound: Token is locked");
        timeLocked.transferFrom(holder1, holder2, tokenId);
    }
}
