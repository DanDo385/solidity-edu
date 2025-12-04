// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/solution/GasDoSAttacksSolution.sol";

/**
 * @title GasDoSAttacksTest
 * @notice Comprehensive tests demonstrating gas DoS attacks and mitigations
 */
contract GasDoSAttacksTest is Test {
    // Vulnerable contracts
    VulnerableAirdrop vulnerableAirdrop;
    VulnerableAuction vulnerableAuction;
    VulnerableMassPayment vulnerableMassPayment;
    ExpensiveFallbackRecipient expensiveFallback;
    VulnerableDistributor vulnerableDistributor;

    // Safe contracts
    SafeAirdropWithPagination safeAirdrop;
    SafeAuctionWithPullPayments safeAuction;
    SafeMassPaymentWithPull safeMassPayment;
    SafeDistributorHybrid safeDistributor;

    // Attack contracts
    MaliciousBidder maliciousBidder;
    GriefingAttacker griefingAttacker;

    // Test users
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address charlie = makeAddr("charlie");
    address dave = makeAddr("dave");

    function setUp() public {
        // Deploy vulnerable contracts
        vulnerableAirdrop = new VulnerableAirdrop();
        vulnerableAuction = new VulnerableAuction(1 days);
        vulnerableMassPayment = new VulnerableMassPayment();
        expensiveFallback = new ExpensiveFallbackRecipient();
        vulnerableDistributor = new VulnerableDistributor();

        // Deploy safe contracts
        safeAirdrop = new SafeAirdropWithPagination();
        safeAuction = new SafeAuctionWithPullPayments(1 days);
        safeMassPayment = new SafeMassPaymentWithPull();
        safeDistributor = new SafeDistributorHybrid();

        // Deploy attack contracts
        maliciousBidder = new MaliciousBidder(address(vulnerableAuction));
        griefingAttacker = new GriefingAttacker();

        // Fund contracts and users
        vm.deal(address(vulnerableAirdrop), 100 ether);
        vm.deal(address(safeAirdrop), 100 ether);
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(charlie, 10 ether);
        vm.deal(dave, 10 ether);
        vm.deal(address(maliciousBidder), 5 ether);
        vm.deal(address(griefingAttacker), 10 ether);
    }

    // ============================================================================
    // UNBOUNDED LOOP DOS TESTS
    // ============================================================================

    /**
     * @notice Test gas consumption growth with recipient count
     */
    function test_UnboundedLoop_GasGrowth() public {
        uint256[] memory recipientCounts = new uint256[](4);
        recipientCounts[0] = 10;
        recipientCounts[1] = 50;
        recipientCounts[2] = 100;
        recipientCounts[3] = 200;

        console.log("\n=== Gas Consumption Growth Test ===");

        for (uint256 i = 0; i < recipientCounts.length; i++) {
            VulnerableAirdrop testAirdrop = new VulnerableAirdrop();
            vm.deal(address(testAirdrop), 1000 ether);

            uint256 count = recipientCounts[i];

            // Add recipients
            for (uint256 j = 0; j < count; j++) {
                address recipient = address(uint160(j + 1));
                testAirdrop.addRecipient(recipient);
            }

            // Measure gas
            uint256 gasBefore = gasleft();
            testAirdrop.distributeAirdrop();
            uint256 gasUsed = gasBefore - gasleft();

            console.log("Recipients:", count, "Gas used:", gasUsed);
        }
    }

    /**
     * @notice Test DoS when recipient array is too large
     */
    function test_UnboundedLoop_DoS() public {
        console.log("\n=== Unbounded Loop DoS Attack ===");

        // Add many recipients to bloat the array
        // We'll add enough to make the function expensive but not run out of gas in test
        for (uint256 i = 0; i < 500; i++) {
            address recipient = address(uint160(i + 1));
            vulnerableAirdrop.addRecipient(recipient);
        }

        console.log("Recipients added:", vulnerableAirdrop.getRecipientCount());

        // Try to distribute - will consume massive gas
        uint256 gasBefore = gasleft();
        vulnerableAirdrop.distributeAirdrop();
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas used for 500 recipients:", gasUsed);

        // In a real blockchain, this would fail at ~900-1000 recipients
        // due to block gas limit (30M gas)
        assertTrue(gasUsed > 10_000_000, "Should use massive gas");
    }

    /**
     * @notice Test that attacker can bloat recipient array
     */
    function test_UnboundedLoop_AttackerBloatsArray() public {
        console.log("\n=== Attacker Bloats Array ===");

        // Attacker adds many fake recipients
        vm.startPrank(alice);
        for (uint256 i = 0; i < 100; i++) {
            address fakeRecipient = address(uint160(i + 1000));
            vulnerableAirdrop.addRecipient(fakeRecipient);
        }
        vm.stopPrank();

        console.log("Recipients after attack:", vulnerableAirdrop.getRecipientCount());

        // Distribution becomes very expensive
        uint256 gasBefore = gasleft();
        vulnerableAirdrop.distributeAirdrop();
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas used:", gasUsed);
        assertTrue(gasUsed > 2_000_000, "Distribution very expensive");
    }

    /**
     * @notice Test safe pagination approach
     */
    function test_SafePagination_BoundedGas() public {
        console.log("\n=== Safe Pagination ===");

        // Add 200 recipients
        for (uint256 i = 0; i < 200; i++) {
            address recipient = address(uint160(i + 1));
            safeAirdrop.addRecipient(recipient);
        }

        uint256 batchSize = 50;
        uint256 totalRecipients = safeAirdrop.getRecipientCount();

        console.log("Total recipients:", totalRecipients);
        console.log("Batch size:", batchSize);

        // Process in batches
        for (uint256 i = 0; i < totalRecipients; i += batchSize) {
            uint256 end = i + batchSize;
            if (end > totalRecipients) {
                end = totalRecipients;
            }

            uint256 gasBefore = gasleft();
            safeAirdrop.distributeBatch(i, end);
            uint256 gasUsed = gasBefore - gasleft();

            console.log("Batch", i / batchSize + 1, "gas used:", gasUsed);

            // Gas should be predictable and bounded
            assertTrue(gasUsed < 2_000_000, "Each batch uses reasonable gas");
        }
    }

    /**
     * @notice Test that batch size is enforced
     */
    function test_SafePagination_EnforcesBatchSize() public {
        for (uint256 i = 0; i < 100; i++) {
            safeAirdrop.addRecipient(address(uint160(i + 1)));
        }

        // Try to process too large a batch
        vm.expectRevert("Batch too large");
        safeAirdrop.distributeBatch(0, 51); // MAX_BATCH_SIZE is 50
    }

    // ============================================================================
    // AUCTION DOS TESTS
    // ============================================================================

    /**
     * @notice Test normal auction flow
     */
    function test_VulnerableAuction_NormalFlow() public {
        console.log("\n=== Normal Auction Flow ===");

        // Alice bids 1 ether
        vm.prank(alice);
        vulnerableAuction.bid{value: 1 ether}();
        assertEq(vulnerableAuction.highestBidder(), alice);

        // Bob bids 2 ether, Alice gets refunded
        vm.prank(bob);
        vulnerableAuction.bid{value: 2 ether}();
        assertEq(vulnerableAuction.highestBidder(), bob);
        assertEq(alice.balance, 10 ether); // Got refund
    }

    /**
     * @notice Test auction DoS via malicious bidder
     */
    function test_VulnerableAuction_DoSAttack() public {
        console.log("\n=== Auction DoS Attack ===");

        // Malicious contract bids
        maliciousBidder.attack{value: 1 ether}();
        assertEq(vulnerableAuction.highestBidder(), address(maliciousBidder));

        console.log("Malicious bidder is highest bidder");

        // Alice tries to bid higher - will fail because malicious contract blocks refund
        vm.prank(alice);
        vm.expectRevert("Blocking refund - DoS attack!");
        vulnerableAuction.bid{value: 2 ether}();

        console.log("Legitimate bid blocked - auction DoSed!");

        // Auction is stuck with malicious bidder
        assertEq(vulnerableAuction.highestBidder(), address(maliciousBidder));
    }

    /**
     * @notice Test that disabling blocker allows recovery
     */
    function test_VulnerableAuction_RecoveryPossible() public {
        // Malicious contract bids
        maliciousBidder.attack{value: 1 ether}();

        // Bids are blocked
        vm.prank(alice);
        vm.expectRevert();
        vulnerableAuction.bid{value: 2 ether}();

        // Attacker disables blocking
        maliciousBidder.disableBlocking();

        // Now bids work again
        vm.prank(alice);
        vulnerableAuction.bid{value: 2 ether}();
        assertEq(vulnerableAuction.highestBidder(), alice);
    }

    /**
     * @notice Test safe auction with pull payments
     */
    function test_SafeAuction_PullPayments() public {
        console.log("\n=== Safe Auction with Pull Payments ===");

        // Alice bids
        vm.prank(alice);
        safeAuction.bid{value: 1 ether}();

        // Bob bids higher - Alice's funds are not sent, just recorded
        vm.prank(bob);
        safeAuction.bid{value: 2 ether}();

        assertEq(safeAuction.highestBidder(), bob);
        assertEq(safeAuction.pendingReturns(alice), 1 ether);

        // Alice withdraws her refund
        uint256 balanceBefore = alice.balance;
        vm.prank(alice);
        safeAuction.withdraw();

        assertEq(alice.balance, balanceBefore + 1 ether);
        assertEq(safeAuction.pendingReturns(alice), 0);
    }

    /**
     * @notice Test safe auction cannot be DoSed
     */
    function test_SafeAuction_CannotBeDoSed() public {
        console.log("\n=== Safe Auction Cannot Be DoSed ===");

        // Deploy malicious bidder targeting safe auction
        MaliciousBidder maliciousSafeBidder = new MaliciousBidder(
            address(safeAuction)
        );
        vm.deal(address(maliciousSafeBidder), 5 ether);

        // Malicious contract bids
        maliciousSafeBidder.attack{value: 1 ether}();

        // Alice can still bid! No refund is sent to malicious contract
        vm.prank(alice);
        safeAuction.bid{value: 2 ether}();

        assertEq(safeAuction.highestBidder(), alice);
        assertEq(safeAuction.pendingReturns(address(maliciousSafeBidder)), 1 ether);

        console.log("Alice successfully bid despite malicious contract");
    }

    // ============================================================================
    // MASS PAYMENT DOS TESTS
    // ============================================================================

    /**
     * @notice Test mass payment gas growth
     */
    function test_MassPayment_GasGrowth() public {
        console.log("\n=== Mass Payment Gas Growth ===");

        uint256[] memory payeeCounts = new uint256[](4);
        payeeCounts[0] = 10;
        payeeCounts[1] = 50;
        payeeCounts[2] = 100;
        payeeCounts[3] = 200;

        for (uint256 i = 0; i < payeeCounts.length; i++) {
            VulnerableMassPayment testPayment = new VulnerableMassPayment();

            uint256 count = payeeCounts[i];

            // Add payees
            for (uint256 j = 0; j < count; j++) {
                address payee = address(uint160(j + 1));
                testPayment.addPayment{value: 0.1 ether}(payee);
            }

            // Measure gas
            uint256 gasBefore = gasleft();
            testPayment.executePayments();
            uint256 gasUsed = gasBefore - gasleft();

            console.log("Payees:", count, "Gas used:", gasUsed);
        }
    }

    /**
     * @notice Test that attacker can bloat payee array
     */
    function test_MassPayment_DoSByBloating() public {
        console.log("\n=== Mass Payment DoS by Bloating ===");

        // Attacker adds many payees with minimal payment
        vm.startPrank(alice);
        for (uint256 i = 0; i < 500; i++) {
            address payee = address(uint160(i + 1));
            vulnerableMassPayment.addPayment{value: 1 wei}(payee);
        }
        vm.stopPrank();

        console.log("Payees added:", vulnerableMassPayment.getPayeeCount());

        // Execution becomes very expensive
        uint256 gasBefore = gasleft();
        vulnerableMassPayment.executePayments();
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas used:", gasUsed);
        assertTrue(gasUsed > 5_000_000, "Very expensive execution");
    }

    /**
     * @notice Test safe pull payment approach
     */
    function test_SafeMassPayment_PullPattern() public {
        console.log("\n=== Safe Mass Payment with Pull ===");

        // Add payments for many users
        for (uint256 i = 0; i < 100; i++) {
            address payee = address(uint160(i + 1));
            safeMassPayment.addPayment{value: 0.1 ether}(payee);
        }

        // Each user withdraws independently - predictable gas
        address testPayee = address(uint160(42));
        uint256 expectedAmount = 0.1 ether;

        assertEq(safeMassPayment.getPendingAmount(testPayee), expectedAmount);

        uint256 gasBefore = gasleft();
        vm.prank(testPayee);
        safeMassPayment.withdraw();
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas for single withdrawal:", gasUsed);
        assertEq(testPayee.balance, expectedAmount);
        assertTrue(gasUsed < 100_000, "Withdrawal uses minimal gas");
    }

    // ============================================================================
    // EXPENSIVE FALLBACK TESTS
    // ============================================================================

    /**
     * @notice Test that transfer() fails with expensive fallback
     */
    function test_ExpensiveFallback_BlocksTransfer() public {
        console.log("\n=== Expensive Fallback Blocks Transfer ===");

        // Try to send ETH with transfer() - will fail
        vm.expectRevert();
        payable(address(expensiveFallback)).transfer(1 ether);

        console.log("transfer() failed due to expensive fallback");
    }

    /**
     * @notice Test that call() succeeds with expensive fallback
     */
    function test_ExpensiveFallback_CallSucceeds() public {
        console.log("\n=== call() Works with Expensive Fallback ===");

        // call() forwards all available gas
        (bool success, ) = payable(address(expensiveFallback)).call{
            value: 1 ether
        }("");

        assertTrue(success, "call() should succeed");
        assertEq(address(expensiveFallback).balance, 1 ether);
        console.log("call() succeeded with expensive fallback");
    }

    /**
     * @notice Test auction DoS with expensive fallback recipient
     */
    function test_ExpensiveFallback_DoSAuction() public {
        console.log("\n=== Expensive Fallback DoS Auction ===");

        // Expensive fallback contract bids
        vm.deal(address(expensiveFallback), 5 ether);
        vm.prank(address(expensiveFallback));
        vulnerableAuction.bid{value: 1 ether}();

        // Alice tries to bid higher - will fail when refunding expensive fallback
        vm.prank(alice);
        vm.expectRevert();
        vulnerableAuction.bid{value: 2 ether}();

        console.log("Auction blocked by expensive fallback recipient");
    }

    // ============================================================================
    // GRIEFING ATTACK TESTS
    // ============================================================================

    /**
     * @notice Test griefing attack on distributor
     */
    function test_Griefing_BlockDistributor() public {
        console.log("\n=== Griefing Attack on Distributor ===");

        // Add legitimate stakeholders
        vulnerableDistributor.addStakeholder(alice, 100);
        vulnerableDistributor.addStakeholder(bob, 100);

        // Attacker adds itself as stakeholder
        griefingAttacker.attackDistributor(address(vulnerableDistributor));

        // Try to distribute rewards - will fail
        vm.expectRevert("Griefing attack - blocking payment!");
        vulnerableDistributor.distributeRewards{value: 10 ether}();

        console.log("Distribution blocked by griefing attacker");
        console.log("All stakeholders suffer, including attacker");
    }

    /**
     * @notice Test griefing by bloating mass payment
     */
    function test_Griefing_BloatMassPayment() public {
        console.log("\n=== Griefing by Bloating Mass Payment ===");

        uint256 attackCount = 100;

        // Attacker bloats the payment array
        griefingAttacker.attackMassPayment{value: attackCount * 1 wei}(
            address(vulnerableMassPayment),
            attackCount
        );

        console.log("Payees after griefing:", vulnerableMassPayment.getPayeeCount());

        // Execution becomes expensive
        uint256 gasBefore = gasleft();
        vulnerableMassPayment.executePayments();
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas used:", gasUsed);
        assertTrue(gasUsed > 1_000_000, "Griefing made execution expensive");
    }

    // ============================================================================
    // HYBRID SAFE DISTRIBUTOR TESTS
    // ============================================================================

    /**
     * @notice Test safe distributor with batch processing
     */
    function test_SafeDistributor_BatchProcessing() public {
        console.log("\n=== Safe Distributor Batch Processing ===");

        // Add stakeholders
        for (uint256 i = 0; i < 100; i++) {
            address stakeholder = address(uint160(i + 1));
            safeDistributor.addStakeholder(stakeholder, 1);
        }

        uint256 batchSize = 50;
        uint256 totalStakeholders = safeDistributor.getStakeholderCount();

        // Distribute in batches
        for (uint256 i = 0; i < totalStakeholders; i += batchSize) {
            uint256 end = i + batchSize;
            if (end > totalStakeholders) {
                end = totalStakeholders;
            }

            uint256 gasBefore = gasleft();
            safeDistributor.distributeRewardsBatch{value: 10 ether}(i, end);
            uint256 gasUsed = gasBefore - gasleft();

            console.log("Batch gas used:", gasUsed);
            assertTrue(gasUsed < 3_000_000, "Batch uses reasonable gas");
        }
    }

    /**
     * @notice Test graceful failure handling
     */
    function test_SafeDistributor_GracefulFailure() public {
        console.log("\n=== Safe Distributor Graceful Failure ===");

        // Add normal stakeholders
        safeDistributor.addStakeholder(alice, 100);
        safeDistributor.addStakeholder(bob, 100);

        // Add malicious stakeholder that will fail
        safeDistributor.addStakeholder(address(griefingAttacker), 100);

        // Distribution succeeds despite one failure
        safeDistributor.distributeRewardsBatch{value: 9 ether}(0, 3);

        // Alice and Bob received their rewards
        // Griefing attacker has pending withdrawal
        uint256 expectedReward = 3 ether; // 9 ether / 3 stakeholders

        assertTrue(
            safeDistributor.pendingRewards(address(griefingAttacker)) > 0,
            "Failed payment recorded"
        );

        console.log("Distribution succeeded despite one failure");
        console.log(
            "Failed payment available for withdrawal:",
            safeDistributor.pendingRewards(address(griefingAttacker))
        );
    }

    /**
     * @notice Test pull withdrawal of failed payments
     */
    function test_SafeDistributor_PullFailedPayment() public {
        // Add stakeholder
        safeDistributor.addStakeholder(alice, 100);
        safeDistributor.addStakeholder(address(expensiveFallback), 100);

        // Distribute - expensive fallback will fail
        safeDistributor.distributeRewardsBatch{value: 10 ether}(0, 2);

        // Failed payment recorded
        uint256 pendingAmount = safeDistributor.pendingRewards(
            address(expensiveFallback)
        );
        assertTrue(pendingAmount > 0, "Failed payment recorded");

        // Can be withdrawn later
        vm.prank(address(expensiveFallback));
        safeDistributor.withdrawReward();

        assertEq(
            safeDistributor.pendingRewards(address(expensiveFallback)),
            0,
            "Payment withdrawn"
        );
    }

    // ============================================================================
    // COMPARISON TESTS
    // ============================================================================

    /**
     * @notice Compare gas costs: push vs pull
     */
    function test_Comparison_PushVsPull() public {
        console.log("\n=== Push vs Pull Comparison ===");

        uint256 numPayees = 100;

        // Setup push payment
        VulnerableMassPayment pushPayment = new VulnerableMassPayment();
        for (uint256 i = 0; i < numPayees; i++) {
            pushPayment.addPayment{value: 0.1 ether}(address(uint160(i + 1)));
        }

        // Setup pull payment
        SafeMassPaymentWithPull pullPayment = new SafeMassPaymentWithPull();
        for (uint256 i = 0; i < numPayees; i++) {
            pullPayment.addPayment{value: 0.1 ether}(address(uint160(i + 1)));
        }

        // Measure push payment (single transaction)
        uint256 pushGas = gasleft();
        pushPayment.executePayments();
        uint256 pushGasUsed = pushGas - gasleft();

        // Measure pull payment (single withdrawal)
        uint256 pullGas = gasleft();
        vm.prank(address(uint160(1)));
        pullPayment.withdraw();
        uint256 pullGasUsed = pullGas - gasleft();

        console.log("Push (all 100 payees):", pushGasUsed, "gas");
        console.log("Pull (per payee):", pullGasUsed, "gas");
        console.log("Pull total (estimated):", pullGasUsed * numPayees, "gas");

        console.log("\nKey difference:");
        console.log(
            "- Push: Single transaction, can fail or hit gas limit"
        );
        console.log(
            "- Pull: Distributed across users, each transaction succeeds independently"
        );
    }

    /**
     * @notice Test demonstrating all DoS vectors in one scenario
     */
    function test_ComprehensiveDoSScenario() public {
        console.log("\n=== Comprehensive DoS Scenario ===");

        // 1. Unbounded loop DoS
        for (uint256 i = 0; i < 100; i++) {
            vulnerableAirdrop.addRecipient(address(uint160(i + 1)));
        }
        uint256 gas1 = gasleft();
        vulnerableAirdrop.distributeAirdrop();
        console.log("1. Unbounded loop gas:", gas1 - gasleft());

        // 2. Auction blocking DoS
        maliciousBidder.attack{value: 1 ether}();
        vm.prank(alice);
        vm.expectRevert();
        vulnerableAuction.bid{value: 2 ether}();
        console.log("2. Auction blocked: true");

        // 3. Mass payment bloating DoS
        for (uint256 i = 0; i < 100; i++) {
            vulnerableMassPayment.addPayment{value: 0.01 ether}(
                address(uint160(i + 100))
            );
        }
        uint256 gas3 = gasleft();
        vulnerableMassPayment.executePayments();
        console.log("3. Mass payment gas:", gas3 - gasleft());

        // 4. Expensive fallback DoS
        vm.expectRevert();
        payable(address(expensiveFallback)).transfer(1 ether);
        console.log("4. Expensive fallback blocked: true");

        console.log("\nAll DoS vectors demonstrated successfully!");
    }
}
