// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/solution/MEVFrontrunningSolution.sol";

/**
 * @title Deploy Project 33: MEV & Front-Running Simulation
 * @notice Deployment script for MEV demonstration contracts
 */
contract DeployMEVFrontrunning is Script {
    // Deployed contracts
    VulnerableAuctionSolution public vulnerableAuction;
    SimpleAMMSolution public vulnerableAMM;
    CommitRevealAuctionSolution public protectedAuction;
    ProtectedDEXSolution public protectedDEX;
    BatchAuctionSolution public batchAuction;
    FrontRunnerSolution public frontRunner;
    SandwichAttackerSolution public sandwichBot;
    MEVSearcherSolution public mevSearcher;

    // Configuration
    uint256 constant AUCTION_DURATION = 1 hours;
    uint256 constant COMMIT_DURATION = 30 minutes;
    uint256 constant REVEAL_DURATION = 30 minutes;
    uint256 constant INITIAL_LIQUIDITY_A = 100 ether;
    uint256 constant INITIAL_LIQUIDITY_B = 10000 ether;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=================================================");
        console.log("Project 33: MEV & Front-Running Simulation");
        console.log("=================================================");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy vulnerable contracts
        console.log("Deploying Vulnerable Contracts...");
        deployVulnerableContracts();

        // Deploy protected contracts
        console.log("\nDeploying Protected Contracts...");
        deployProtectedContracts();

        // Deploy attack contracts
        console.log("\nDeploying Attack Contracts...");
        deployAttackContracts();

        // Initialize contracts
        console.log("\nInitializing Contracts...");
        initializeContracts();

        vm.stopBroadcast();

        // Print deployment summary
        printDeploymentSummary();
    }

    function deployVulnerableContracts() internal {
        vulnerableAuction = new VulnerableAuctionSolution(AUCTION_DURATION);
        console.log("VulnerableAuction deployed at:", address(vulnerableAuction));

        vulnerableAMM = new SimpleAMMSolution();
        console.log("SimpleAMM deployed at:", address(vulnerableAMM));
    }

    function deployProtectedContracts() internal {
        protectedAuction = new CommitRevealAuctionSolution(COMMIT_DURATION, REVEAL_DURATION);
        console.log("CommitRevealAuction deployed at:", address(protectedAuction));

        protectedDEX = new ProtectedDEXSolution();
        console.log("ProtectedDEX deployed at:", address(protectedDEX));

        batchAuction = new BatchAuctionSolution();
        console.log("BatchAuction deployed at:", address(batchAuction));
    }

    function deployAttackContracts() internal {
        frontRunner = new FrontRunnerSolution();
        console.log("FrontRunner deployed at:", address(frontRunner));

        sandwichBot = new SandwichAttackerSolution(address(vulnerableAMM));
        console.log("SandwichAttacker deployed at:", address(sandwichBot));

        mevSearcher = new MEVSearcherSolution();
        console.log("MEVSearcher deployed at:", address(mevSearcher));
    }

    function initializeContracts() internal {
        // Add initial liquidity to vulnerable AMM
        vulnerableAMM.addLiquidity(INITIAL_LIQUIDITY_A, INITIAL_LIQUIDITY_B);
        console.log("Added liquidity to VulnerableAMM:", INITIAL_LIQUIDITY_A, "A /", INITIAL_LIQUIDITY_B, "B");

        // Add initial liquidity to protected DEX
        protectedDEX.addLiquidity(INITIAL_LIQUIDITY_A, INITIAL_LIQUIDITY_B);
        console.log("Added liquidity to ProtectedDEX:", INITIAL_LIQUIDITY_A, "A /", INITIAL_LIQUIDITY_B, "B");
    }

    function printDeploymentSummary() internal view {
        console.log("\n=================================================");
        console.log("DEPLOYMENT SUMMARY");
        console.log("=================================================");

        console.log("\nVULNERABLE CONTRACTS:");
        console.log("--------------------");
        console.log("VulnerableAuction:     ", address(vulnerableAuction));
        console.log("SimpleAMM:             ", address(vulnerableAMM));

        console.log("\nPROTECTED CONTRACTS:");
        console.log("--------------------");
        console.log("CommitRevealAuction:   ", address(protectedAuction));
        console.log("ProtectedDEX:          ", address(protectedDEX));
        console.log("BatchAuction:          ", address(batchAuction));

        console.log("\nATTACK CONTRACTS:");
        console.log("--------------------");
        console.log("FrontRunner:           ", address(frontRunner));
        console.log("SandwichAttacker:      ", address(sandwichBot));
        console.log("MEVSearcher:           ", address(mevSearcher));

        console.log("\nCONFIGURATION:");
        console.log("--------------------");
        console.log("Auction Duration:      ", AUCTION_DURATION);
        console.log("Commit Duration:       ", COMMIT_DURATION);
        console.log("Reveal Duration:       ", REVEAL_DURATION);
        console.log("Initial Liquidity A:   ", INITIAL_LIQUIDITY_A);
        console.log("Initial Liquidity B:   ", INITIAL_LIQUIDITY_B);

        console.log("\n=================================================");
        console.log("USAGE INSTRUCTIONS");
        console.log("=================================================");
        console.log("\n1. VULNERABLE AUCTION:");
        console.log("   - Users can bid by calling placeBid()");
        console.log("   - Vulnerable to front-running attacks");
        console.log("   - Attacker can observe pending bids and outbid");

        console.log("\n2. SIMPLE AMM:");
        console.log("   - Swap tokens using swapAForB() or swapBForA()");
        console.log("   - Vulnerable to sandwich attacks");
        console.log("   - Large swaps create price impact");

        console.log("\n3. COMMIT-REVEAL AUCTION:");
        console.log("   - Phase 1: commit(hash) - hide your bid");
        console.log("   - Phase 2: reveal(amount, salt) - reveal bid");
        console.log("   - Protected from front-running");

        console.log("\n4. PROTECTED DEX:");
        console.log("   - Swap with price impact limits");
        console.log("   - Limits sandwich attack profitability");
        console.log("   - Set maxPriceImpact parameter");

        console.log("\n5. BATCH AUCTION:");
        console.log("   - Submit orders during batch period");
        console.log("   - All orders execute at clearing price");
        console.log("   - No front-running advantage");

        console.log("\n6. ATTACK CONTRACTS:");
        console.log("   - FrontRunner: Generic front-running bot");
        console.log("   - SandwichAttacker: AMM sandwich attacks");
        console.log("   - MEVSearcher: Multi-strategy searcher");

        console.log("\n=================================================");
        console.log("TESTING SCENARIOS");
        console.log("=================================================");
        console.log("\nRun tests with: forge test -vv");
        console.log("\nTest scenarios include:");
        console.log("- Front-running attacks on auctions");
        console.log("- Sandwich attacks on AMM");
        console.log("- Commit-reveal protection");
        console.log("- Slippage and price impact limits");
        console.log("- Batch auction fair ordering");
        console.log("- MEV profitability analysis");

        console.log("\n=================================================");
        console.log("WARNING: EDUCATIONAL USE ONLY");
        console.log("=================================================");
        console.log("These contracts demonstrate MEV vulnerabilities");
        console.log("and attack vectors for educational purposes.");
        console.log("DO NOT use on mainnet to harm others.");
        console.log("=================================================\n");
    }
}

/**
 * @dev Deployment Instructions:
 *
 * LOCAL DEPLOYMENT:
 * 1. Start local node: anvil
 * 2. Deploy: forge script script/DeployMEVFrontrunning.s.sol --rpc-url http://localhost:8545 --broadcast
 *
 * TESTNET DEPLOYMENT:
 * 1. Set environment variables:
 *    export PRIVATE_KEY=your_private_key
 *    export SEPOLIA_RPC_URL=your_rpc_url
 * 2. Deploy: forge script script/DeployMEVFrontrunning.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
 *
 * VERIFICATION:
 * Add --verify flag and set ETHERSCAN_API_KEY environment variable
 *
 * INTERACT WITH CONTRACTS:
 * Use cast commands or write interaction scripts
 *
 * EXAMPLES:
 * # Place bid in vulnerable auction
 * cast send <AUCTION_ADDRESS> "placeBid()" --value 1ether --private-key $PRIVATE_KEY
 *
 * # Swap on AMM
 * cast send <AMM_ADDRESS> "swapAForB(uint256,uint256)" 1000000000000000000 0 --private-key $PRIVATE_KEY
 *
 * # Commit to protected auction
 * cast send <PROTECTED_AUCTION> "commit(bytes32)" <COMMIT_HASH> --value 1ether --private-key $PRIVATE_KEY
 */
