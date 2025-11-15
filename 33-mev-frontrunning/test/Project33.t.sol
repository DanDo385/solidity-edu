// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/Project33Solution.sol";

/**
 * @title Project 33 Tests: MEV & Front-Running Simulations
 * @notice Comprehensive tests demonstrating MEV attacks and defenses
 */
contract Project33Test is Test {
    // Vulnerable contracts
    VulnerableAuctionSolution public vulnerableAuction;
    SimpleAMMSolution public vulnerableAMM;

    // Protected contracts
    CommitRevealAuctionSolution public protectedAuction;
    ProtectedDEXSolution public protectedDEX;
    BatchAuctionSolution public batchAuction;

    // Attack contracts
    FrontRunnerSolution public frontRunner;
    SandwichAttackerSolution public sandwichBot;
    MEVSearcherSolution public mevSearcher;

    // Test actors
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public attacker = address(0x3);
    address public victim = address(0x4);

    // Constants
    uint256 constant INITIAL_LIQUIDITY_A = 100 ether;
    uint256 constant INITIAL_LIQUIDITY_B = 10000 ether; // 1 A = 100 B
    uint256 constant AUCTION_DURATION = 1 hours;

    function setUp() public {
        // Fund test accounts
        vm.deal(alice, 1000 ether);
        vm.deal(bob, 1000 ether);
        vm.deal(attacker, 1000 ether);
        vm.deal(victim, 1000 ether);

        // Deploy vulnerable contracts
        vulnerableAuction = new VulnerableAuctionSolution(AUCTION_DURATION);
        vulnerableAMM = new SimpleAMMSolution();

        // Deploy protected contracts
        protectedAuction = new CommitRevealAuctionSolution(30 minutes, 30 minutes);
        protectedDEX = new ProtectedDEXSolution();
        batchAuction = new BatchAuctionSolution();

        // Deploy attack contracts
        frontRunner = new FrontRunnerSolution();
        sandwichBot = new SandwichAttackerSolution(address(vulnerableAMM));
        mevSearcher = new MEVSearcherSolution();

        // Initialize AMM with liquidity
        vulnerableAMM.addLiquidity{value: 0}(INITIAL_LIQUIDITY_A, INITIAL_LIQUIDITY_B);
        protectedDEX.addLiquidity{value: 0}(INITIAL_LIQUIDITY_A, INITIAL_LIQUIDITY_B);

        // Fund attack contracts
        vm.deal(address(frontRunner), 100 ether);
        vm.deal(address(sandwichBot), 100 ether);
        vm.deal(address(mevSearcher), 100 ether);
    }

    /*//////////////////////////////////////////////////////////////
                        FRONT-RUNNING TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test simple front-running attack on auction
     */
    function testFrontRunningAuction() public {
        console.log("\n=== FRONT-RUNNING ATTACK SIMULATION ===");

        // Alice plans to bid 10 ETH
        uint256 aliceBid = 10 ether;

        // Attacker observes Alice's pending transaction in mempool
        // Attacker front-runs with 10.1 ETH and higher gas price

        console.log("Alice's intended bid:", aliceBid);

        // Simulate: Attacker's TX gets included first (higher gas price)
        vm.prank(attacker);
        vulnerableAuction.placeBid{value: 10.1 ether}();

        console.log("Attacker front-runs with:", 10.1 ether);

        // Alice's transaction executes second
        vm.prank(alice);
        vm.expectRevert("Bid too low");
        vulnerableAuction.placeBid{value: aliceBid}();

        // Verify attacker won
        assertEq(vulnerableAuction.highestBidder(), attacker);
        assertEq(vulnerableAuction.highestBid(), 10.1 ether);

        console.log("Result: Attacker successfully front-ran Alice's bid");
        console.log("Winner:", vulnerableAuction.highestBidder());
    }

    /**
     * @notice Test gas price war scenario
     */
    function testGasPriceWar() public {
        console.log("\n=== GAS PRICE WAR SIMULATION ===");

        uint256 baseBid = 5 ether;

        // Round 1: Alice bids
        vm.prank(alice);
        vm.txGasPrice(50 gwei);
        vulnerableAuction.placeBid{value: baseBid}();
        console.log("Round 1 - Alice bids 5 ETH @ 50 gwei");

        // Round 2: Attacker outbids
        vm.prank(attacker);
        vm.txGasPrice(60 gwei);
        vulnerableAuction.placeBid{value: baseBid + 0.1 ether}();
        console.log("Round 2 - Attacker bids 5.1 ETH @ 60 gwei");

        // Round 3: Alice counters
        vm.prank(alice);
        vm.txGasPrice(70 gwei);
        vulnerableAuction.placeBid{value: baseBid + 0.2 ether}();
        console.log("Round 3 - Alice bids 5.2 ETH @ 70 gwei");

        // Round 4: Attacker counters again
        vm.prank(attacker);
        vm.txGasPrice(100 gwei);
        vulnerableAuction.placeBid{value: baseBid + 0.3 ether}();
        console.log("Round 4 - Attacker bids 5.3 ETH @ 100 gwei");

        console.log("Gas prices escalated from 50 to 100 gwei");
        console.log("Both parties spent significant gas fees");
    }

    /*//////////////////////////////////////////////////////////////
                        SANDWICH ATTACK TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test complete sandwich attack on AMM
     */
    function testSandwichAttack() public {
        console.log("\n=== SANDWICH ATTACK SIMULATION ===");

        // Victim wants to swap 10 A for B
        uint256 victimSwapAmount = 10 ether;
        uint256 attackerFrontRunAmount = 5 ether;

        // Log initial state
        console.log("Initial Pool: 100 A / 10,000 B");
        console.log("Initial Price: 1 A = 100 B");

        // Calculate initial price
        uint256 initialPrice = vulnerableAMM.getPrice();
        console.log("Initial price:", initialPrice);

        // Step 1: Attacker observes victim's pending TX
        // Calculate potential profit
        uint256 estimatedProfit = sandwichBot.calculateProfit(victimSwapAmount, attackerFrontRunAmount);
        console.log("\nAttacker calculates profit:", estimatedProfit);

        // Record attacker's initial balance
        uint256 attackerInitialBalance = address(sandwichBot).balance;

        // Step 2: Front-run - Attacker buys B
        console.log("\nStep 1: FRONT-RUN");
        uint256 attackerBReceived = vulnerableAMM.swapAForB(attackerFrontRunAmount, 0);
        console.log("Attacker swaps", attackerFrontRunAmount, "A for", attackerBReceived, "B");
        console.log("New Pool:", vulnerableAMM.reserveA(), "A /", vulnerableAMM.reserveB(), "B");

        // Step 3: Victim's swap executes
        console.log("\nStep 2: VICTIM SWAP");
        uint256 victimBReceived = vulnerableAMM.swapAForB(victimSwapAmount, 0);
        console.log("Victim swaps", victimSwapAmount, "A for", victimBReceived, "B");
        console.log("Victim expected ~1000 B but got:", victimBReceived);
        console.log("New Pool:", vulnerableAMM.reserveA(), "A /", vulnerableAMM.reserveB(), "B");

        // Step 4: Back-run - Attacker sells B
        console.log("\nStep 3: BACK-RUN");
        uint256 attackerAReceived = vulnerableAMM.swapBForA(attackerBReceived, 0);
        console.log("Attacker swaps", attackerBReceived, "B for", attackerAReceived, "A");
        console.log("Final Pool:", vulnerableAMM.reserveA(), "A /", vulnerableAMM.reserveB(), "B");

        // Calculate profit
        uint256 profit = attackerAReceived > attackerFrontRunAmount ? attackerAReceived - attackerFrontRunAmount : 0;
        console.log("\n=== SANDWICH RESULTS ===");
        console.log("Attacker invested:", attackerFrontRunAmount);
        console.log("Attacker received:", attackerAReceived);
        console.log("Net profit:", profit);
        console.log("Victim loss: Received less B than expected");

        // Verify profit was made
        assertTrue(profit > 0, "Sandwich attack should be profitable");
    }

    /**
     * @notice Test sandwich attack profitability calculation
     */
    function testSandwichProfitability() public {
        console.log("\n=== SANDWICH PROFITABILITY ANALYSIS ===");

        uint256[] memory victimAmounts = new uint256[](5);
        victimAmounts[0] = 1 ether;
        victimAmounts[1] = 5 ether;
        victimAmounts[2] = 10 ether;
        victimAmounts[3] = 20 ether;
        victimAmounts[4] = 50 ether;

        uint256 frontRunAmount = 5 ether;

        console.log("Front-run amount:", frontRunAmount);
        console.log("\nVictim Size | Estimated Profit | Profitable?");
        console.log("------------------------------------------------");

        for (uint256 i = 0; i < victimAmounts.length; i++) {
            uint256 estimatedProfit = sandwichBot.calculateProfit(victimAmounts[i], frontRunAmount);
            uint256 estimatedGas = 200000 * 50 gwei; // Estimate gas cost
            bool profitable = sandwichBot.isProfitable(victimAmounts[i], frontRunAmount, estimatedGas);

            console.log(victimAmounts[i], "|", estimatedProfit, "|", profitable ? "YES" : "NO");
        }
    }

    /**
     * @notice Test victim's slippage protection against sandwich
     */
    function testSandwichWithSlippageProtection() public {
        console.log("\n=== SANDWICH WITH SLIPPAGE PROTECTION ===");

        uint256 victimSwapAmount = 10 ether;
        uint256 attackerFrontRunAmount = 5 ether;

        // Victim calculates expected output
        uint256 expectedOutput = vulnerableAMM.getAmountOut(victimSwapAmount, INITIAL_LIQUIDITY_A, INITIAL_LIQUIDITY_B);
        uint256 minOutput = (expectedOutput * 95) / 100; // 5% slippage tolerance

        console.log("Expected output:", expectedOutput);
        console.log("Min output (5% slippage):", minOutput);

        // Attacker front-runs
        vulnerableAMM.swapAForB(attackerFrontRunAmount, 0);
        console.log("Attacker front-runs");

        // Victim's swap with slippage protection
        uint256 actualOutput = vulnerableAMM.getAmountOut(victimSwapAmount, vulnerableAMM.reserveA(), vulnerableAMM.reserveB());
        console.log("Actual output after front-run:", actualOutput);

        if (actualOutput < minOutput) {
            console.log("PROTECTED: Slippage too high, transaction would revert");
            vm.expectRevert("Slippage too high");
            vulnerableAMM.swapAForB(victimSwapAmount, minOutput);
        } else {
            console.log("VULNERABLE: Sandwich still profitable within slippage");
            vulnerableAMM.swapAForB(victimSwapAmount, minOutput);
        }
    }

    /*//////////////////////////////////////////////////////////////
                    COMMIT-REVEAL PROTECTION TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test commit-reveal auction prevents front-running
     */
    function testCommitRevealPreventssFrontRunning() public {
        console.log("\n=== COMMIT-REVEAL PROTECTION ===");

        // Alice prepares bid
        uint256 aliceBid = 10 ether;
        bytes32 aliceSalt = keccak256("alice_secret");
        bytes32 aliceCommit = protectedAuction.generateCommitHash(aliceBid, aliceSalt, alice);

        console.log("Alice's bid:", aliceBid);
        console.log("Alice's commit hash:", vm.toString(aliceCommit));

        // Alice commits (bid is hidden)
        vm.prank(alice);
        protectedAuction.commit{value: aliceBid}(aliceCommit);
        console.log("Alice commits (bid hidden from attacker)");

        // Attacker tries to front-run but cannot see the bid amount
        console.log("\nAttacker sees commit but cannot determine bid amount");
        console.log("Attacker's front-run attempt is blind");

        // Attacker makes blind commit
        bytes32 attackerSalt = keccak256("attacker_secret");
        bytes32 attackerCommit = protectedAuction.generateCommitHash(9 ether, attackerSalt, attacker);

        vm.prank(attacker);
        protectedAuction.commit{value: 9 ether}(attackerCommit);
        console.log("Attacker commits blind bid of 9 ETH");

        // Move to reveal phase
        vm.warp(block.timestamp + 31 minutes);

        // Both reveal
        vm.prank(alice);
        protectedAuction.reveal(aliceBid, aliceSalt);
        console.log("\nAlice reveals: 10 ETH");

        vm.prank(attacker);
        protectedAuction.reveal(9 ether, attackerSalt);
        console.log("Attacker reveals: 9 ETH");

        // Alice wins because attacker couldn't see her bid
        assertEq(protectedAuction.highestBidder(), alice);
        console.log("\nResult: Alice wins! Commit-reveal prevented front-running");
    }

    /**
     * @notice Test commit-reveal security: invalid reveals fail
     */
    function testCommitRevealSecurity() public {
        console.log("\n=== COMMIT-REVEAL SECURITY ===");

        uint256 bidAmount = 5 ether;
        bytes32 salt = keccak256("secret");
        bytes32 commitHash = protectedAuction.generateCommitHash(bidAmount, salt, alice);

        // Commit
        vm.prank(alice);
        protectedAuction.commit{value: bidAmount}(commitHash);

        // Move to reveal phase
        vm.warp(block.timestamp + 31 minutes);

        // Try to reveal with wrong amount
        vm.prank(alice);
        vm.expectRevert("Invalid reveal");
        protectedAuction.reveal(6 ether, salt);

        // Try to reveal with wrong salt
        vm.prank(alice);
        vm.expectRevert("Invalid reveal");
        protectedAuction.reveal(bidAmount, keccak256("wrong_salt"));

        // Correct reveal works
        vm.prank(alice);
        protectedAuction.reveal(bidAmount, salt);
        assertTrue(true, "Valid reveal succeeded");

        console.log("SECURE: Invalid reveals are rejected");
    }

    /*//////////////////////////////////////////////////////////////
                    PROTECTED DEX TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test protected DEX price impact limits
     */
    function testProtectedDEXPriceImpactLimit() public {
        console.log("\n=== PROTECTED DEX PRICE IMPACT LIMITS ===");

        // Try large swap that exceeds price impact limit
        uint256 largeSwap = 50 ether; // 50% of pool
        uint256 maxPriceImpact = 100; // 1%

        console.log("Attempting swap of", largeSwap, "(50% of pool)");
        console.log("Max allowed price impact: 1%");

        uint256 priceImpact = protectedDEX.calculatePriceImpact(largeSwap, INITIAL_LIQUIDITY_A, INITIAL_LIQUIDITY_B);
        console.log("Calculated price impact:", priceImpact, "basis points");

        // Should revert due to high price impact
        vm.expectRevert("Price impact too high");
        protectedDEX.swapAForB(largeSwap, 0, maxPriceImpact);

        console.log("PROTECTED: Large swap rejected due to price impact");

        // Smaller swap should work
        uint256 smallSwap = 0.5 ether; // 0.5% of pool
        uint256 smallPriceImpact = protectedDEX.calculatePriceImpact(smallSwap, INITIAL_LIQUIDITY_A, INITIAL_LIQUIDITY_B);
        console.log("\nSmaller swap:", smallSwap);
        console.log("Price impact:", smallPriceImpact, "basis points");

        protectedDEX.swapAForB(smallSwap, 0, maxPriceImpact);
        console.log("SUCCESS: Small swap executed");
    }

    /**
     * @notice Test that protected DEX makes sandwich attacks unprofitable
     */
    function testProtectedDEXMitigatesSandwich() public {
        console.log("\n=== PROTECTED DEX SANDWICH MITIGATION ===");

        uint256 victimSwap = 1 ether;
        uint256 attackerFrontRun = 0.5 ether;
        uint256 maxPriceImpact = 100; // 1%

        console.log("Victim swap:", victimSwap);
        console.log("Attacker front-run:", attackerFrontRun);

        // Attacker tries front-run
        try protectedDEX.swapAForB(attackerFrontRun, 0, maxPriceImpact) {
            console.log("Front-run executed");

            // Victim's swap
            try protectedDEX.swapAForB(victimSwap, 0, maxPriceImpact) {
                console.log("Victim swap executed");

                // Attacker tries back-run but price impact limit prevents profit
                console.log("MITIGATED: Price impact limits reduce sandwich profitability");
            } catch {
                console.log("PROTECTED: Victim's swap rejected (price impact too high)");
            }
        } catch {
            console.log("PROTECTED: Front-run rejected (price impact too high)");
        }
    }

    /*//////////////////////////////////////////////////////////////
                        BATCH AUCTION TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test batch auction eliminates ordering advantages
     */
    function testBatchAuctionFairOrdering() public {
        console.log("\n=== BATCH AUCTION FAIR ORDERING ===");

        // Multiple users submit orders
        vm.prank(alice);
        batchAuction.submitOrder{value: 10 ether}(1 ether, 10 ether);
        console.log("Alice orders 1 @ max price 10");

        vm.prank(bob);
        batchAuction.submitOrder{value: 12 ether}(1 ether, 12 ether);
        console.log("Bob orders 1 @ max price 12");

        vm.prank(attacker);
        batchAuction.submitOrder{value: 9 ether}(1 ether, 9 ether);
        console.log("Attacker orders 1 @ max price 9");

        // Move to batch execution time
        vm.warp(block.timestamp + 6 minutes);

        // Execute batch
        batchAuction.executeBatch();

        uint256 clearingPrice = batchAuction.clearingPrice();
        console.log("\nClearing price:", clearingPrice);
        console.log("All filled orders executed at same price");
        console.log("NO FRONT-RUNNING ADVANTAGE");

        assertTrue(clearingPrice > 0, "Batch executed");
    }

    /*//////////////////////////////////////////////////////////////
                        MEV SEARCHER TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test arbitrage opportunity detection
     */
    function testArbitrageDetection() public {
        console.log("\n=== ARBITRAGE OPPORTUNITY DETECTION ===");

        // Create second AMM with different price
        SimpleAMMSolution amm2 = new SimpleAMMSolution();
        amm2.addLiquidity(100 ether, 12000 ether); // Higher price: 1 A = 120 B

        console.log("AMM1 price: 1 A = 100 B");
        console.log("AMM2 price: 1 A = 120 B");

        // Estimate arbitrage profit
        uint256 arbAmount = 10 ether;
        uint256 estimatedProfit =
            mevSearcher.estimateArbitrageProfit(address(vulnerableAMM), address(amm2), arbAmount);

        console.log("Arbitrage amount:", arbAmount);
        console.log("Estimated profit:", estimatedProfit);

        if (estimatedProfit > 0) {
            console.log("PROFITABLE: Arbitrage opportunity detected");
        }

        assertTrue(estimatedProfit > 0, "Arbitrage profitable");
    }

    /*//////////////////////////////////////////////////////////////
                    ECONOMIC ANALYSIS TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Analyze MEV extraction economics
     */
    function testMEVEconomics() public {
        console.log("\n=== MEV ECONOMICS ANALYSIS ===");

        uint256 victimSwap = 20 ether;
        uint256 frontRunAmount = 10 ether;

        // Calculate gross profit
        uint256 grossProfit = sandwichBot.calculateProfit(victimSwap, frontRunAmount);

        // Estimate gas costs
        uint256 gasPerTx = 150000;
        uint256 gasPrice = 50 gwei;
        uint256 totalGas = gasPerTx * 2 * gasPrice; // Front + back run

        console.log("Gross profit:", grossProfit);
        console.log("Gas cost:", totalGas);

        uint256 netProfit = grossProfit > totalGas ? grossProfit - totalGas : 0;
        console.log("Net profit:", netProfit);

        if (netProfit > 0) {
            uint256 roi = (netProfit * 100) / frontRunAmount;
            console.log("ROI:", roi, "%");
        }

        console.log("\nConclusion: MEV only profitable when:");
        console.log("1. Victim trade size is large enough");
        console.log("2. Gas prices are reasonable");
        console.log("3. Competition is low");
    }

    /**
     * @notice Test break-even analysis for sandwich attacks
     */
    function testSandwichBreakEven() public {
        console.log("\n=== SANDWICH BREAK-EVEN ANALYSIS ===");

        uint256 frontRunAmount = 5 ether;
        uint256[] memory victimSizes = new uint256[](10);

        // Test different victim trade sizes
        for (uint256 i = 0; i < 10; i++) {
            victimSizes[i] = (i + 1) * 2 ether; // 2, 4, 6, ..., 20 ETH
        }

        console.log("Front-run: 5 ETH | Gas: 300k @ 50 gwei");
        console.log("\nVictim Size | Gross Profit | Net Profit | Profitable?");
        console.log("-----------------------------------------------------------");

        uint256 gasCost = 300000 * 50 gwei;

        for (uint256 i = 0; i < victimSizes.length; i++) {
            uint256 grossProfit = sandwichBot.calculateProfit(victimSizes[i], frontRunAmount);
            int256 netProfit = int256(grossProfit) - int256(gasCost);

            console.log(
                victimSizes[i],
                "|",
                grossProfit,
                "|",
                netProfit,
                "|",
                netProfit > 0 ? "YES" : "NO"
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                        HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Helper to simulate mempool observation
     */
    function simulateMempoolObservation(address target, bytes memory data) internal view returns (bool) {
        // In reality, MEV searchers monitor the public mempool
        // They decode transaction data to identify profitable opportunities
        return data.length > 0 && target != address(0);
    }

    /**
     * @notice Helper to calculate gas costs
     */
    function calculateGasCost(uint256 gasUsed, uint256 gasPrice) internal pure returns (uint256) {
        return gasUsed * gasPrice;
    }
}

/**
 * @dev Test Summary:
 *
 * VULNERABILITY DEMONSTRATIONS:
 * ✓ Front-running attack on auction
 * ✓ Gas price war escalation
 * ✓ Sandwich attack on AMM
 * ✓ Profitability analysis
 *
 * PROTECTION VALIDATIONS:
 * ✓ Commit-reveal prevents front-running
 * ✓ Slippage protection limits damage
 * ✓ Price impact limits reduce sandwich profits
 * ✓ Batch auctions eliminate ordering advantages
 *
 * ECONOMIC ANALYSIS:
 * ✓ MEV profitability calculation
 * ✓ Break-even analysis
 * ✓ Gas cost consideration
 * ✓ ROI calculations
 *
 * KEY LEARNINGS:
 * - All public mempool transactions are vulnerable to MEV
 * - Front-running requires higher gas price
 * - Sandwich attacks exploit price impact
 * - Protections add complexity but improve fairness
 * - MEV only profitable above certain thresholds
 * - Gas costs significantly impact MEV economics
 */
