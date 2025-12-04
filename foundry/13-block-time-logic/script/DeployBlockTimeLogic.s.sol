// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/BlockTimeLogic.sol";
import "../src/solution/BlockTimeLogicSolution.sol";

/**
 * @title DeployBlockTimeLogic
 * @notice Deployment script for Block Properties & Time Logic
 * @dev Run with: forge script script/DeployBlockTimeLogic.s.sol --rpc-url <network> --broadcast
 *
 * DEPLOYMENT OPTIONS:
 * 1. Deploy skeleton (for students to complete)
 * 2. Deploy solution (for reference/testing)
 *
 * USAGE EXAMPLES:
 *
 * Local deployment (Anvil):
 * forge script script/DeployBlockTimeLogic.s.sol --rpc-url http://localhost:8545 --broadcast
 *
 * Testnet deployment (e.g., Sepolia):
 * forge script script/DeployBlockTimeLogic.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
 *
 * Mainnet deployment (use with caution):
 * forge script script/DeployBlockTimeLogic.s.sol --rpc-url $MAINNET_RPC_URL --broadcast --verify
 */
contract DeployBlockTimeLogic is Script {
    // Deployment addresses will be stored here
    BlockTimeLogic public blockTimeLogic;
    BlockTimeLogicSolution public blockTimeLogicSolution;

    /**
     * @notice Main deployment function
     * @dev This is called when running the script
     */
    function run() external {
        // Get deployer private key from environment
        // Make sure PRIVATE_KEY is set in your .env file
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the skeleton contract (for students)
        blockTimeLogic = new BlockTimeLogic();
        console.log("BlockTimeLogic (skeleton) deployed to:", address(blockTimeLogic));

        // Deploy the solution contract (for reference)
        blockTimeLogicSolution = new BlockTimeLogicSolution();
        console.log("BlockTimeLogicSolution deployed to:", address(blockTimeLogicSolution));

        // Stop broadcasting
        vm.stopBroadcast();

        // Log deployment summary
        logDeploymentSummary();
    }

    /**
     * @notice Deploy only the skeleton contract
     * @dev Useful when you only want students to work with the skeleton
     */
    function deploySkeleton() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        blockTimeLogic = new BlockTimeLogic();
        console.log("BlockTimeLogic (skeleton) deployed to:", address(blockTimeLogic));

        vm.stopBroadcast();

        // Verify deployment
        verifyDeployment(address(blockTimeLogic));
    }

    /**
     * @notice Deploy only the solution contract
     * @dev Useful for testing or providing reference implementation
     */
    function deploySolution() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        blockTimeLogicSolution = new BlockTimeLogicSolution();
        console.log("BlockTimeLogicSolution deployed to:", address(blockTimeLogicSolution));

        vm.stopBroadcast();

        // Verify deployment
        verifyDeployment(address(blockTimeLogicSolution));

        // Run post-deployment setup if needed
        postDeploymentSetup();
    }

    /**
     * @notice Verify the deployment was successful
     * @param contractAddress Address of deployed contract
     */
    function verifyDeployment(address contractAddress) internal view {
        console.log("\n=== Verifying Deployment ===");

        // Check contract was deployed
        require(contractAddress != address(0), "Deployment failed: zero address");

        // Check contract has code
        uint256 size;
        assembly {
            size := extcodesize(contractAddress)
        }
        require(size > 0, "Deployment failed: no code at address");

        console.log("Contract code size:", size, "bytes");
        console.log("Deployment verified successfully!");
    }

    /**
     * @notice Log deployment summary with useful information
     */
    function logDeploymentSummary() internal view {
        console.log("\n=== Deployment Summary ===");
        console.log("Network:", block.chainid);
        console.log("Block number:", block.number);
        console.log("Block timestamp:", block.timestamp);

        if (address(blockTimeLogic) != address(0)) {
            console.log("\nBlockTimeLogic (Skeleton):");
            console.log("  Address:", address(blockTimeLogic));
            console.log("  Owner:", blockTimeLogic.owner());
        }

        if (address(blockTimeLogicSolution) != address(0)) {
            console.log("\nBlockTimeLogicSolution:");
            console.log("  Address:", address(blockTimeLogicSolution));
            console.log("  Owner:", blockTimeLogicSolution.owner());
        }

        console.log("\n=== Next Steps ===");
        console.log("1. Verify contracts on block explorer (if on testnet/mainnet)");
        console.log("2. Test time-locked vault functionality");
        console.log("3. Test rate limiting features");
        console.log("4. Experiment with vesting schedules");
        console.log("5. Run lottery simulation");
        console.log("\n=== Testing Commands ===");
        console.log("Run all tests:");
        console.log("  forge test --match-path test/BlockTimeLogic.t.sol -vvv");
        console.log("\nRun specific test:");
        console.log("  forge test --match-test testVestingDuringPeriod -vvv");
        console.log("\nRun with gas report:");
        console.log("  forge test --match-path test/BlockTimeLogic.t.sol --gas-report");
    }

    /**
     * @notice Optional post-deployment setup
     * @dev Initialize contract state if needed
     */
    function postDeploymentSetup() internal {
        console.log("\n=== Post-Deployment Setup ===");

        // Example: Initialize vesting (optional)
        // Uncomment if you want to set up vesting on deployment
        /*
        address beneficiary = vm.envAddress("VESTING_BENEFICIARY");
        uint256 amount = vm.envUint("VESTING_AMOUNT");
        uint256 duration = vm.envUint("VESTING_DURATION");

        vm.startBroadcast();
        project13Solution.initializeVesting(beneficiary, amount, duration);
        vm.stopBroadcast();

        console.log("Vesting initialized for:", beneficiary);
        console.log("Amount:", amount);
        console.log("Duration:", duration, "seconds");
        */

        console.log("No post-deployment setup required");
        console.log("Contracts are ready to use!");
    }

    /**
     * @notice Helper function to get network name
     * @param chainId Chain ID
     * @return Network name
     */
    function getNetworkName(uint256 chainId) internal pure returns (string memory) {
        if (chainId == 1) return "Ethereum Mainnet";
        if (chainId == 5) return "Goerli";
        if (chainId == 11155111) return "Sepolia";
        if (chainId == 137) return "Polygon";
        if (chainId == 80001) return "Mumbai";
        if (chainId == 42161) return "Arbitrum One";
        if (chainId == 421613) return "Arbitrum Goerli";
        if (chainId == 10) return "Optimism";
        if (chainId == 420) return "Optimism Goerli";
        if (chainId == 31337) return "Anvil (Local)";
        return "Unknown Network";
    }
}

/**
 * @title DeployAndTest
 * @notice Deploy and run basic tests on the contracts
 * @dev Useful for quick validation after deployment
 */
contract DeployAndTest is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy solution
        BlockTimeLogicSolution project = new BlockTimeLogicSolution();
        console.log("Contract deployed to:", address(project));

        // Test 1: Lock funds
        console.log("\n=== Test 1: Lock Funds ===");
        project.lockInVault{value: 1 ether}(1 days);
        console.log("Locked 1 ETH for 1 day");
        console.log("Vault balance:", project.vaultBalance());
        console.log("Unlock time:", project.vaultUnlockTime());
        console.log("Is locked:", project.isVaultLocked());

        // Test 2: Rate limiting
        console.log("\n=== Test 2: Rate Limiting ===");
        project.performRateLimitedAction();
        console.log("Performed rate-limited action");
        console.log("Last action time:", project.lastActionTime(msg.sender));

        // Test 3: Initiate cooldown
        console.log("\n=== Test 3: Cooldown ===");
        project.initiateCooldown();
        console.log("Cooldown initiated at:", project.cooldownStart(msg.sender));
        console.log("Cooldown active:", project.cooldownActive(msg.sender));

        // Test 4: Start lottery
        console.log("\n=== Test 4: Lottery ===");
        project.startLottery(100);
        console.log("Lottery started");
        console.log("Start block:", project.lotteryStartBlock());
        console.log("End block:", project.lotteryEndBlock());
        console.log("Is active:", project.isLotteryActive());

        vm.stopBroadcast();

        console.log("\n=== All Tests Passed ===");
    }
}
