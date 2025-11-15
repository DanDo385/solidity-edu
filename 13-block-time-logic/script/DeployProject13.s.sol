// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/Project13.sol";
import "../src/solution/Project13Solution.sol";

/**
 * @title DeployProject13
 * @notice Deployment script for Project 13: Block Properties & Time Logic
 * @dev Run with: forge script script/DeployProject13.s.sol --rpc-url <network> --broadcast
 *
 * DEPLOYMENT OPTIONS:
 * 1. Deploy skeleton (for students to complete)
 * 2. Deploy solution (for reference/testing)
 *
 * USAGE EXAMPLES:
 *
 * Local deployment (Anvil):
 * forge script script/DeployProject13.s.sol --rpc-url http://localhost:8545 --broadcast
 *
 * Testnet deployment (e.g., Sepolia):
 * forge script script/DeployProject13.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
 *
 * Mainnet deployment (use with caution):
 * forge script script/DeployProject13.s.sol --rpc-url $MAINNET_RPC_URL --broadcast --verify
 */
contract DeployProject13 is Script {
    // Deployment addresses will be stored here
    Project13 public project13;
    Project13Solution public project13Solution;

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
        project13 = new Project13();
        console.log("Project13 (skeleton) deployed to:", address(project13));

        // Deploy the solution contract (for reference)
        project13Solution = new Project13Solution();
        console.log("Project13Solution deployed to:", address(project13Solution));

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

        project13 = new Project13();
        console.log("Project13 (skeleton) deployed to:", address(project13));

        vm.stopBroadcast();

        // Verify deployment
        verifyDeployment(address(project13));
    }

    /**
     * @notice Deploy only the solution contract
     * @dev Useful for testing or providing reference implementation
     */
    function deploySolution() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        project13Solution = new Project13Solution();
        console.log("Project13Solution deployed to:", address(project13Solution));

        vm.stopBroadcast();

        // Verify deployment
        verifyDeployment(address(project13Solution));

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

        if (address(project13) != address(0)) {
            console.log("\nProject13 (Skeleton):");
            console.log("  Address:", address(project13));
            console.log("  Owner:", project13.owner());
        }

        if (address(project13Solution) != address(0)) {
            console.log("\nProject13Solution:");
            console.log("  Address:", address(project13Solution));
            console.log("  Owner:", project13Solution.owner());
        }

        console.log("\n=== Next Steps ===");
        console.log("1. Verify contracts on block explorer (if on testnet/mainnet)");
        console.log("2. Test time-locked vault functionality");
        console.log("3. Test rate limiting features");
        console.log("4. Experiment with vesting schedules");
        console.log("5. Run lottery simulation");
        console.log("\n=== Testing Commands ===");
        console.log("Run all tests:");
        console.log("  forge test --match-path test/Project13.t.sol -vvv");
        console.log("\nRun specific test:");
        console.log("  forge test --match-test testVestingDuringPeriod -vvv");
        console.log("\nRun with gas report:");
        console.log("  forge test --match-path test/Project13.t.sol --gas-report");
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
        Project13Solution project = new Project13Solution();
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
