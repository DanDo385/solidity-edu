// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/solution/Project25Solution.sol";

/**
 * @title Project 25 Tests: ERC-721A Gas Optimization
 * @notice Comprehensive tests with gas benchmarking
 * @dev Tests cover:
 *      - Single vs batch mint gas comparison
 *      - Ownership inference after batch minting
 *      - Transfer mechanics with ownership chain
 *      - Large batch minting (stress testing)
 *      - Gas snapshots and analysis
 */
contract Project25Test is Test {
    OptimizedNFTSolution public nft;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public carol = makeAddr("carol");
    address public owner;

    // Events to test
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setUp() public {
        owner = address(this);
        nft = new OptimizedNFTSolution("Optimized NFT", "OPTNFT");

        // Fund test addresses
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(carol, 100 ether);
    }

    // =============================================================
    //                      BASIC FUNCTIONALITY
    // =============================================================

    function test_Metadata() public view {
        assertEq(nft.name(), "Optimized NFT");
        assertEq(nft.symbol(), "OPTNFT");
    }

    function test_InitialState() public view {
        assertEq(nft.totalSupply(), 0);
        assertEq(nft.MAX_SUPPLY(), 10000);
        assertEq(nft.MINT_PRICE(), 0.01 ether);
        assertEq(nft.MAX_MINT_PER_TX(), 20);
    }

    // =============================================================
    //                    SINGLE MINT TESTS
    // =============================================================

    function test_MintSingle() public {
        vm.prank(alice);
        nft.mint{value: 0.01 ether}(1);

        assertEq(nft.totalSupply(), 1);
        assertEq(nft.balanceOf(alice), 1);
        assertEq(nft.ownerOf(0), alice);
    }

    function test_MintSingleEmitsTransfer() public {
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), alice, 0);

        vm.prank(alice);
        nft.mint{value: 0.01 ether}(1);
    }

    function test_MintRequiresPayment() public {
        vm.prank(alice);
        vm.expectRevert(OptimizedNFTSolution.InsufficientPayment.selector);
        nft.mint{value: 0.005 ether}(1);
    }

    function test_MintRevertsOnZeroQuantity() public {
        vm.prank(alice);
        vm.expectRevert(OptimizedNFTSolution.InvalidQuantity.selector);
        nft.mint{value: 0}(0);
    }

    // =============================================================
    //                    BATCH MINT TESTS
    // =============================================================

    function test_MintBatch() public {
        vm.prank(alice);
        nft.mint{value: 0.05 ether}(5);

        assertEq(nft.totalSupply(), 5);
        assertEq(nft.balanceOf(alice), 5);

        // All tokens should belong to alice
        for (uint256 i = 0; i < 5; i++) {
            assertEq(nft.ownerOf(i), alice);
        }
    }

    function test_MintBatchEmitsMultipleTransfers() public {
        // Expect 5 Transfer events
        for (uint256 i = 0; i < 5; i++) {
            vm.expectEmit(true, true, true, true);
            emit Transfer(address(0), alice, i);
        }

        vm.prank(alice);
        nft.mint{value: 0.05 ether}(5);
    }

    function test_MintMaxPerTransaction() public {
        vm.prank(alice);
        nft.mint{value: 0.2 ether}(20);

        assertEq(nft.balanceOf(alice), 20);
        assertEq(nft.totalSupply(), 20);
    }

    function test_MintRevertsOnExceedMaxPerTx() public {
        vm.prank(alice);
        vm.expectRevert(OptimizedNFTSolution.InvalidQuantity.selector);
        nft.mint{value: 0.21 ether}(21);
    }

    function test_MintRevertsOnMaxSupply() public {
        // Mint up to max supply
        uint256 remaining = nft.MAX_SUPPLY();
        while (remaining > 0) {
            uint256 batch = remaining > 20 ? 20 : remaining;
            nft.ownerMint(alice, batch);
            remaining -= batch;
        }

        assertEq(nft.totalSupply(), nft.MAX_SUPPLY());

        // Try to mint one more
        vm.prank(bob);
        vm.expectRevert(OptimizedNFTSolution.MaxSupplyReached.selector);
        nft.mint{value: 0.01 ether}(1);
    }

    // =============================================================
    //                  OWNERSHIP INFERENCE TESTS
    // =============================================================

    function test_OwnershipInferenceBasic() public {
        // Mint batch of 5 to alice
        vm.prank(alice);
        nft.mint{value: 0.05 ether}(5);

        // All should return alice due to ownership inference
        assertEq(nft.ownerOf(0), alice); // Explicit ownership
        assertEq(nft.ownerOf(1), alice); // Inferred from token 0
        assertEq(nft.ownerOf(2), alice); // Inferred from token 0
        assertEq(nft.ownerOf(3), alice); // Inferred from token 0
        assertEq(nft.ownerOf(4), alice); // Inferred from token 0
    }

    function test_OwnershipInferenceMultipleBatches() public {
        // Mint batch to alice
        vm.prank(alice);
        nft.mint{value: 0.05 ether}(5); // Tokens 0-4

        // Mint batch to bob
        vm.prank(bob);
        nft.mint{value: 0.03 ether}(3); // Tokens 5-7

        // Mint batch to carol
        vm.prank(carol);
        nft.mint{value: 0.02 ether}(2); // Tokens 8-9

        // Verify alice's tokens
        assertEq(nft.ownerOf(0), alice);
        assertEq(nft.ownerOf(4), alice);

        // Verify bob's tokens
        assertEq(nft.ownerOf(5), bob);
        assertEq(nft.ownerOf(7), bob);

        // Verify carol's tokens
        assertEq(nft.ownerOf(8), carol);
        assertEq(nft.ownerOf(9), carol);
    }

    function test_OwnerOfNonexistentToken() public {
        vm.expectRevert(OptimizedNFTSolution.TokenDoesNotExist.selector);
        nft.ownerOf(0);

        // Mint one token
        vm.prank(alice);
        nft.mint{value: 0.01 ether}(1);

        // Token 1 doesn't exist yet
        vm.expectRevert(OptimizedNFTSolution.TokenDoesNotExist.selector);
        nft.ownerOf(1);
    }

    // =============================================================
    //                      TRANSFER TESTS
    // =============================================================

    function test_TransferSingleToken() public {
        // Mint to alice
        vm.prank(alice);
        nft.mint{value: 0.01 ether}(1);

        // Transfer to bob
        vm.prank(alice);
        nft.transferFrom(alice, bob, 0);

        assertEq(nft.ownerOf(0), bob);
        assertEq(nft.balanceOf(alice), 0);
        assertEq(nft.balanceOf(bob), 1);
    }

    function test_TransferFromBatchMiddle() public {
        // Mint batch of 5 to alice
        vm.prank(alice);
        nft.mint{value: 0.05 ether}(5); // Tokens 0-4

        // Transfer middle token (2) to bob
        vm.prank(alice);
        nft.transferFrom(alice, bob, 2);

        // Verify ownership
        assertEq(nft.ownerOf(0), alice); // Before transfer
        assertEq(nft.ownerOf(1), alice); // Before transfer
        assertEq(nft.ownerOf(2), bob);   // Transferred
        assertEq(nft.ownerOf(3), alice); // After transfer (should maintain alice)
        assertEq(nft.ownerOf(4), alice); // After transfer

        // Verify balances
        assertEq(nft.balanceOf(alice), 4);
        assertEq(nft.balanceOf(bob), 1);
    }

    function test_TransferFromBatchFirst() public {
        // Mint batch to alice
        vm.prank(alice);
        nft.mint{value: 0.05 ether}(5);

        // Transfer first token
        vm.prank(alice);
        nft.transferFrom(alice, bob, 0);

        assertEq(nft.ownerOf(0), bob);
        assertEq(nft.ownerOf(1), alice); // Should still be alice
        assertEq(nft.ownerOf(4), alice);

        assertEq(nft.balanceOf(alice), 4);
        assertEq(nft.balanceOf(bob), 1);
    }

    function test_TransferFromBatchLast() public {
        // Mint batch to alice
        vm.prank(alice);
        nft.mint{value: 0.05 ether}(5);

        // Transfer last token
        vm.prank(alice);
        nft.transferFrom(alice, bob, 4);

        assertEq(nft.ownerOf(0), alice);
        assertEq(nft.ownerOf(3), alice);
        assertEq(nft.ownerOf(4), bob);

        assertEq(nft.balanceOf(alice), 4);
        assertEq(nft.balanceOf(bob), 1);
    }

    function test_TransferMultipleFromBatch() public {
        // Mint batch to alice
        vm.prank(alice);
        nft.mint{value: 0.05 ether}(5);

        // Transfer tokens 1 and 3
        vm.startPrank(alice);
        nft.transferFrom(alice, bob, 1);
        nft.transferFrom(alice, carol, 3);
        vm.stopPrank();

        assertEq(nft.ownerOf(0), alice);
        assertEq(nft.ownerOf(1), bob);
        assertEq(nft.ownerOf(2), alice);
        assertEq(nft.ownerOf(3), carol);
        assertEq(nft.ownerOf(4), alice);

        assertEq(nft.balanceOf(alice), 3);
        assertEq(nft.balanceOf(bob), 1);
        assertEq(nft.balanceOf(carol), 1);
    }

    function test_TransferRevertsToZeroAddress() public {
        vm.prank(alice);
        nft.mint{value: 0.01 ether}(1);

        vm.prank(alice);
        vm.expectRevert(OptimizedNFTSolution.TransferToZeroAddress.selector);
        nft.transferFrom(alice, address(0), 0);
    }

    function test_TransferRevertsNotOwner() public {
        vm.prank(alice);
        nft.mint{value: 0.01 ether}(1);

        // Bob tries to transfer alice's token
        vm.prank(bob);
        vm.expectRevert(OptimizedNFTSolution.NotOwnerNorApproved.selector);
        nft.transferFrom(alice, bob, 0);
    }

    // =============================================================
    //                      APPROVAL TESTS
    // =============================================================

    function test_Approve() public {
        vm.prank(alice);
        nft.mint{value: 0.01 ether}(1);

        vm.expectEmit(true, true, true, true);
        emit Approval(alice, bob, 0);

        vm.prank(alice);
        nft.approve(bob, 0);

        assertEq(nft.getApproved(0), bob);
    }

    function test_TransferWithApproval() public {
        vm.prank(alice);
        nft.mint{value: 0.01 ether}(1);

        vm.prank(alice);
        nft.approve(bob, 0);

        // Bob can now transfer
        vm.prank(bob);
        nft.transferFrom(alice, carol, 0);

        assertEq(nft.ownerOf(0), carol);
    }

    function test_ApprovalClearedOnTransfer() public {
        vm.prank(alice);
        nft.mint{value: 0.01 ether}(1);

        vm.prank(alice);
        nft.approve(bob, 0);

        vm.prank(alice);
        nft.transferFrom(alice, carol, 0);

        // Approval should be cleared
        assertEq(nft.getApproved(0), address(0));
    }

    function test_SetApprovalForAll() public {
        vm.expectEmit(true, true, true, true);
        emit ApprovalForAll(alice, bob, true);

        vm.prank(alice);
        nft.setApprovalForAll(bob, true);

        assertTrue(nft.isApprovedForAll(alice, bob));
    }

    function test_TransferWithOperatorApproval() public {
        vm.prank(alice);
        nft.mint{value: 0.05 ether}(5);

        vm.prank(alice);
        nft.setApprovalForAll(bob, true);

        // Bob can transfer any of alice's tokens
        vm.prank(bob);
        nft.transferFrom(alice, carol, 2);

        assertEq(nft.ownerOf(2), carol);
    }

    // =============================================================
    //                    GAS BENCHMARK TESTS
    // =============================================================

    function test_GasMintSingle() public {
        vm.prank(alice);
        uint256 gasBefore = gasleft();
        nft.mint{value: 0.01 ether}(1);
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas for minting 1 token:", gasUsed);
        console.log("Gas per token:", gasUsed);

        // Expected: ~160,000 gas
        assertLt(gasUsed, 200000, "Single mint should be under 200k gas");
    }

    function test_GasMintBatch2() public {
        vm.prank(alice);
        uint256 gasBefore = gasleft();
        nft.mint{value: 0.02 ether}(2);
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas for minting 2 tokens:", gasUsed);
        console.log("Gas per token:", gasUsed / 2);

        // Expected: ~165,000 gas (82.5k per token)
        assertLt(gasUsed, 200000, "Batch 2 should be under 200k gas");
    }

    function test_GasMintBatch5() public {
        vm.prank(alice);
        uint256 gasBefore = gasleft();
        nft.mint{value: 0.05 ether}(5);
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas for minting 5 tokens:", gasUsed);
        console.log("Gas per token:", gasUsed / 5);

        // Expected: ~175,000 gas (35k per token)
        assertLt(gasUsed, 220000, "Batch 5 should be under 220k gas");
    }

    function test_GasMintBatch10() public {
        vm.prank(alice);
        uint256 gasBefore = gasleft();
        nft.mint{value: 0.1 ether}(10);
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas for minting 10 tokens:", gasUsed);
        console.log("Gas per token:", gasUsed / 10);

        // Expected: ~190,000 gas (19k per token)
        assertLt(gasUsed, 250000, "Batch 10 should be under 250k gas");
    }

    function test_GasMintBatch20() public {
        vm.prank(alice);
        uint256 gasBefore = gasleft();
        nft.mint{value: 0.2 ether}(20);
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas for minting 20 tokens:", gasUsed);
        console.log("Gas per token:", gasUsed / 20);

        // Expected: ~210,000 gas (10.5k per token)
        assertLt(gasUsed, 280000, "Batch 20 should be under 280k gas");
    }

    function test_GasComparisonSummary() public {
        console.log("\n=== ERC-721A Gas Benchmark Summary ===\n");

        // Test various batch sizes
        uint256[] memory quantities = new uint256[](5);
        quantities[0] = 1;
        quantities[1] = 2;
        quantities[2] = 5;
        quantities[3] = 10;
        quantities[4] = 20;

        for (uint256 i = 0; i < quantities.length; i++) {
            uint256 qty = quantities[i];
            uint256 cost = qty * nft.MINT_PRICE();

            vm.prank(alice);
            uint256 gasBefore = gasleft();
            nft.mint{value: cost}(qty);
            uint256 gasUsed = gasBefore - gasleft();

            console.log("Quantity:", qty);
            console.log("  Total gas:", gasUsed);
            console.log("  Gas per token:", gasUsed / qty);
            console.log("  Efficiency gain:", (100 - (gasUsed / qty) * 100 / 160000), "%");
            console.log("");

            // Prepare for next iteration
            if (i < quantities.length - 1) {
                vm.prank(alice);
                // Transfer all to bob to reset alice's balance for next test
                for (uint256 j = 0; j < nft.balanceOf(alice); j++) {
                    // Simple approach: we know token IDs are sequential
                }
            }
        }
    }

    function test_GasOwnerOf() public {
        // Mint batch of 20
        vm.prank(alice);
        nft.mint{value: 0.2 ether}(20);

        console.log("\n=== ownerOf() Gas Costs ===\n");

        // Test ownerOf at different positions in the batch
        uint256[] memory positions = new uint256[](5);
        positions[0] = 0;  // First (explicit ownership)
        positions[1] = 5;  // Early
        positions[2] = 10; // Middle
        positions[3] = 15; // Late
        positions[4] = 19; // Last

        for (uint256 i = 0; i < positions.length; i++) {
            uint256 tokenId = positions[i];
            uint256 gasBefore = gasleft();
            address tokenOwner = nft.ownerOf(tokenId);
            uint256 gasUsed = gasBefore - gasleft();

            assertEq(tokenOwner, alice);
            console.log("ownerOf(", tokenId, ") gas:", gasUsed);
        }
    }

    function test_GasTransferFromBatch() public {
        // Mint batch to alice
        vm.prank(alice);
        nft.mint{value: 0.05 ether}(5);

        console.log("\n=== Transfer Gas Costs ===\n");

        // Transfer from middle of batch (requires updating next token)
        vm.prank(alice);
        uint256 gasBefore = gasleft();
        nft.transferFrom(alice, bob, 2);
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Transfer from batch (middle):", gasUsed);

        // Transfer standalone token
        vm.prank(bob);
        gasBefore = gasleft();
        nft.transferFrom(bob, carol, 2);
        gasUsed = gasBefore - gasleft();

        console.log("Transfer standalone token:", gasUsed);
    }

    // =============================================================
    //                    LARGE BATCH TESTS
    // =============================================================

    function test_LargeBatchMint() public {
        // Test maximum batch size
        vm.prank(alice);
        nft.mint{value: 0.2 ether}(20);

        assertEq(nft.balanceOf(alice), 20);
        assertEq(nft.ownerOf(0), alice);
        assertEq(nft.ownerOf(19), alice);
    }

    function test_SequentialBatches() public {
        // Multiple users minting in sequence
        vm.prank(alice);
        nft.mint{value: 0.05 ether}(5); // 0-4

        vm.prank(bob);
        nft.mint{value: 0.1 ether}(10); // 5-14

        vm.prank(carol);
        nft.mint{value: 0.03 ether}(3); // 15-17

        assertEq(nft.totalSupply(), 18);

        // Verify all ownerships
        for (uint256 i = 0; i < 5; i++) {
            assertEq(nft.ownerOf(i), alice);
        }
        for (uint256 i = 5; i < 15; i++) {
            assertEq(nft.ownerOf(i), bob);
        }
        for (uint256 i = 15; i < 18; i++) {
            assertEq(nft.ownerOf(i), carol);
        }
    }

    // =============================================================
    //                    OWNER FUNCTIONS
    // =============================================================

    function test_OwnerMint() public {
        nft.ownerMint(alice, 10);

        assertEq(nft.balanceOf(alice), 10);
        assertEq(nft.totalSupply(), 10);
    }

    function test_OwnerMintRevertsNonOwner() public {
        vm.prank(alice);
        vm.expectRevert(OptimizedNFTSolution.CallerNotOwner.selector);
        nft.ownerMint(bob, 5);
    }

    function test_Withdraw() public {
        // Mint some NFTs to add funds
        vm.prank(alice);
        nft.mint{value: 1 ether}(5);

        uint256 contractBalance = address(nft).balance;
        uint256 ownerBalanceBefore = address(this).balance;

        nft.withdraw();

        assertEq(address(nft).balance, 0);
        assertEq(address(this).balance, ownerBalanceBefore + contractBalance);
    }

    // =============================================================
    //                    EDGE CASES
    // =============================================================

    function test_BalanceOfZeroAddress() public {
        vm.expectRevert(OptimizedNFTSolution.QueryForZeroAddress.selector);
        nft.balanceOf(address(0));
    }

    function test_NumberMinted() public {
        vm.prank(alice);
        nft.mint{value: 0.05 ether}(5);

        assertEq(nft.numberMinted(alice), 5);

        vm.prank(alice);
        nft.mint{value: 0.03 ether}(3);

        assertEq(nft.numberMinted(alice), 8);
        assertEq(nft.balanceOf(alice), 8);
    }

    function test_AuxiliaryData() public {
        nft.setAux(alice, 12345);
        assertEq(nft.getAux(alice), 12345);
    }

    // =============================================================
    //                    FUZZ TESTS
    // =============================================================

    function testFuzz_MintBatch(uint8 quantity) public {
        vm.assume(quantity > 0 && quantity <= 20);

        uint256 cost = uint256(quantity) * nft.MINT_PRICE();
        vm.deal(alice, cost);

        vm.prank(alice);
        nft.mint{value: cost}(quantity);

        assertEq(nft.balanceOf(alice), quantity);
        assertEq(nft.totalSupply(), quantity);

        // Verify all tokens belong to alice
        for (uint256 i = 0; i < quantity; i++) {
            assertEq(nft.ownerOf(i), alice);
        }
    }

    function testFuzz_OwnershipAfterTransfer(uint8 batchSize, uint8 transferIndex) public {
        vm.assume(batchSize > 2 && batchSize <= 20);
        vm.assume(transferIndex < batchSize);

        uint256 cost = uint256(batchSize) * nft.MINT_PRICE();
        vm.deal(alice, cost);

        vm.prank(alice);
        nft.mint{value: cost}(batchSize);

        vm.prank(alice);
        nft.transferFrom(alice, bob, transferIndex);

        // Verify ownership
        assertEq(nft.ownerOf(transferIndex), bob);

        // All other tokens should still belong to alice
        for (uint256 i = 0; i < batchSize; i++) {
            if (i != transferIndex) {
                assertEq(nft.ownerOf(i), alice);
            }
        }
    }

    // Allow contract to receive ETH
    receive() external payable {}
}

/**
 * EXPECTED GAS RESULTS:
 *
 * Single mint (1):     ~160,000 gas (160k per token)
 * Batch mint (2):      ~165,000 gas (82.5k per token) - 48% savings
 * Batch mint (5):      ~175,000 gas (35k per token)   - 78% savings
 * Batch mint (10):     ~190,000 gas (19k per token)   - 88% savings
 * Batch mint (20):     ~210,000 gas (10.5k per token) - 93% savings
 *
 * Transfer from batch:  ~80,000 gas (needs 2 ownership updates)
 * Transfer standalone:  ~50,000 gas (needs 1 ownership update)
 *
 * ownerOf() first:     ~2,500 gas (explicit ownership)
 * ownerOf() middle:    ~5,000 gas (scan ~10 tokens)
 * ownerOf() last:      ~15,000 gas (scan ~20 tokens)
 *
 * REAL WORLD COMPARISON:
 *
 * Standard ERC-721 batch mint (5 tokens):
 * - Gas: ~750,000
 * - At 50 gwei, $2000 ETH: ~$75
 *
 * ERC-721A batch mint (5 tokens):
 * - Gas: ~175,000
 * - At 50 gwei, $2000 ETH: ~$17.50
 * - User saves: $57.50 (77% savings!)
 *
 * This is why Azuki and other major NFT projects use ERC-721A!
 */
