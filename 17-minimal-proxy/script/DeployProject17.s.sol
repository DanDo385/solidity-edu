// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/solution/Project17Solution.sol";

/**
 * @title DeployProject17
 * @notice Deployment script for Minimal Proxy (EIP-1167) project
 * @dev Deploys implementation and factory contracts
 *
 * Usage:
 * forge script script/DeployProject17.s.sol:DeployProject17 --rpc-url <your_rpc_url> --broadcast
 *
 * For local testing:
 * forge script script/DeployProject17.s.sol:DeployProject17 --fork-url http://localhost:8545 --broadcast
 *
 * To verify on Etherscan:
 * forge script script/DeployProject17.s.sol:DeployProject17 --rpc-url <your_rpc_url> --broadcast --verify
 */
contract DeployProject17 is Script {
    // Deployment addresses (will be set during deployment)
    SimpleWallet public implementation;
    WalletFactory public factory;
    DirectWallet public directWallet;

    function run() external {
        // Get deployer private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("========================================");
        console.log("Deploying Minimal Proxy Project");
        console.log("========================================");
        console.log("Deployer:", deployer);
        console.log("Balance:", deployer.balance);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // Step 1: Deploy implementation contract
        console.log("Step 1: Deploying SimpleWallet implementation...");
        uint256 gasBefore = gasleft();
        implementation = new SimpleWallet();
        uint256 implGas = gasBefore - gasleft();
        console.log("  Implementation deployed at:", address(implementation));
        console.log("  Gas used:", implGas);
        console.log("");

        // Step 2: Deploy factory
        console.log("Step 2: Deploying WalletFactory...");
        gasBefore = gasleft();
        factory = new WalletFactory(address(implementation));
        uint256 factoryGas = gasBefore - gasleft();
        console.log("  Factory deployed at:", address(factory));
        console.log("  Gas used:", factoryGas);
        console.log("");

        // Step 3: Deploy DirectWallet for comparison
        console.log("Step 3: Deploying DirectWallet (for comparison)...");
        gasBefore = gasleft();
        directWallet = new DirectWallet(deployer);
        uint256 directGas = gasBefore - gasleft();
        console.log("  DirectWallet deployed at:", address(directWallet));
        console.log("  Gas used:", directGas);
        console.log("");

        // Step 4: Create a sample clone
        console.log("Step 4: Creating sample clone wallet...");
        gasBefore = gasleft();
        address sampleClone = factory.createWallet();
        uint256 cloneGas = gasBefore - gasleft();
        console.log("  Clone deployed at:", sampleClone);
        console.log("  Gas used:", cloneGas);
        console.log("");

        vm.stopBroadcast();

        // Print summary
        console.log("========================================");
        console.log("Deployment Summary");
        console.log("========================================");
        console.log("Implementation:", address(implementation));
        console.log("Factory:", address(factory));
        console.log("DirectWallet:", address(directWallet));
        console.log("Sample Clone:", sampleClone);
        console.log("");

        console.log("========================================");
        console.log("Gas Comparison");
        console.log("========================================");
        console.log("DirectWallet deployment:", directGas);
        console.log("Clone deployment:", cloneGas);
        console.log("Gas saved per clone:", directGas - cloneGas);
        console.log("Savings percentage:", ((directGas - cloneGas) * 100) / directGas, "%");
        console.log("");

        console.log("========================================");
        console.log("Cost Analysis (10 wallets)");
        console.log("========================================");
        uint256 direct10 = directGas * 10;
        uint256 clone10 = implGas + (cloneGas * 10);
        console.log("10 DirectWallets:", direct10, "gas");
        console.log("1 Implementation + 10 Clones:", clone10, "gas");
        console.log("Total savings:", direct10 - clone10, "gas");
        console.log("Savings percentage:", ((direct10 - clone10) * 100) / direct10, "%");
        console.log("");

        console.log("========================================");
        console.log("Cost Analysis (100 wallets)");
        console.log("========================================");
        uint256 direct100 = directGas * 100;
        uint256 clone100 = implGas + (cloneGas * 100);
        console.log("100 DirectWallets:", direct100, "gas");
        console.log("1 Implementation + 100 Clones:", clone100, "gas");
        console.log("Total savings:", direct100 - clone100, "gas");
        console.log("Savings percentage:", ((direct100 - clone100) * 100) / direct100, "%");
        console.log("");

        console.log("========================================");
        console.log("Next Steps");
        console.log("========================================");
        console.log("1. Create your own wallet:");
        console.log("   cast send", address(factory), "\"createWallet()\" --rpc-url <rpc> --private-key <key>");
        console.log("");
        console.log("2. Check your wallet address:");
        console.log("   cast call", address(factory), "\"userWallets(address)\" <your_address> --rpc-url <rpc>");
        console.log("");
        console.log("3. Create deterministic wallet:");
        console.log("   cast send", address(factory), "\"createDeterministicWallet(bytes32)\" <salt> --rpc-url <rpc> --private-key <key>");
        console.log("");
        console.log("4. Predict deterministic address:");
        console.log("   cast call", address(factory), "\"predictWalletAddress(bytes32)\" <salt> --rpc-url <rpc>");
        console.log("========================================");
    }
}

/**
 * @title DeployProject17Local
 * @notice Local deployment script with additional testing
 * @dev Deploys and creates multiple clones for testing
 */
contract DeployProject17Local is Script {
    SimpleWallet public implementation;
    WalletFactory public factory;

    function run() external {
        console.log("========================================");
        console.log("Local Deployment & Testing");
        console.log("========================================");

        vm.startBroadcast();

        // Deploy contracts
        console.log("Deploying contracts...");
        implementation = new SimpleWallet();
        factory = new WalletFactory(address(implementation));
        console.log("Implementation:", address(implementation));
        console.log("Factory:", address(factory));
        console.log("");

        // Create multiple clones
        console.log("Creating 5 sample clones...");
        address[] memory clones = new address[](5);

        for (uint256 i = 0; i < 5; i++) {
            // Create clone
            clones[i] = factory.createWallet();
            console.log("  Clone", i + 1, ":", clones[i]);

            // Deposit some ETH
            SimpleWallet(payable(clones[i])).deposit{value: (i + 1) * 1 ether}();
        }
        console.log("");

        // Create deterministic clones
        console.log("Creating 3 deterministic clones...");
        for (uint256 i = 0; i < 3; i++) {
            bytes32 salt = bytes32(i);
            address predicted = factory.predictWalletAddress(salt);
            console.log("  Predicted address:", predicted);

            // Note: Can't create deterministic clones with same sender in same tx
            // This will fail on second iteration in same broadcast
            // In real usage, different users would call this
        }
        console.log("");

        vm.stopBroadcast();

        // Verify clones
        console.log("Verifying clones...");
        console.log("Total wallets created:", factory.getWalletCount());

        for (uint256 i = 0; i < clones.length; i++) {
            SimpleWallet clone = SimpleWallet(payable(clones[i]));
            console.log("  Clone", i + 1, "balance:", clone.getBalance());
        }
        console.log("");

        console.log("========================================");
        console.log("Deployment Complete!");
        console.log("========================================");
    }
}

/**
 * @title DeployAndBenchmark
 * @notice Deployment script with detailed gas benchmarking
 * @dev Creates multiple clones and compares gas usage
 */
contract DeployAndBenchmark is Script {
    SimpleWallet public implementation;
    WalletFactory public factory;

    function run() external {
        console.log("========================================");
        console.log("Gas Benchmarking");
        console.log("========================================");

        vm.startBroadcast();

        // Deploy implementation
        uint256 gasBefore = gasleft();
        implementation = new SimpleWallet();
        uint256 implGas = gasBefore - gasleft();
        console.log("Implementation deployment:", implGas, "gas");

        // Deploy factory
        gasBefore = gasleft();
        factory = new WalletFactory(address(implementation));
        uint256 factoryGas = gasBefore - gasleft();
        console.log("Factory deployment:", factoryGas, "gas");
        console.log("");

        // Benchmark clone deployments
        console.log("Clone Deployment Benchmarks:");
        console.log("----------------------------------------");

        uint256[] memory cloneGases = new uint256[](10);
        uint256 totalCloneGas = 0;

        for (uint256 i = 0; i < 10; i++) {
            gasBefore = gasleft();
            factory.createWallet();
            cloneGases[i] = gasBefore - gasleft();
            totalCloneGas += cloneGases[i];

            console.log("  Clone", i + 1, ":", cloneGases[i], "gas");
        }

        console.log("----------------------------------------");
        console.log("Average clone deployment:", totalCloneGas / 10, "gas");
        console.log("");

        // Benchmark deterministic clones
        console.log("Deterministic Clone Benchmarks:");
        console.log("----------------------------------------");

        uint256[] memory detGases = new uint256[](5);
        uint256 totalDetGas = 0;

        for (uint256 i = 0; i < 5; i++) {
            bytes32 salt = keccak256(abi.encodePacked("benchmark", i));
            gasBefore = gasleft();
            factory.createDeterministicWallet(salt);
            detGases[i] = gasBefore - gasleft();
            totalDetGas += detGases[i];

            console.log("  Deterministic clone", i + 1, ":", detGases[i], "gas");
        }

        console.log("----------------------------------------");
        console.log("Average deterministic deployment:", totalDetGas / 5, "gas");
        console.log("");

        // Benchmark DirectWallet for comparison
        console.log("DirectWallet Deployment Benchmarks:");
        console.log("----------------------------------------");

        uint256[] memory directGases = new uint256[](10);
        uint256 totalDirectGas = 0;

        for (uint256 i = 0; i < 10; i++) {
            gasBefore = gasleft();
            new DirectWallet(address(this));
            directGases[i] = gasBefore - gasleft();
            totalDirectGas += directGases[i];

            console.log("  DirectWallet", i + 1, ":", directGases[i], "gas");
        }

        console.log("----------------------------------------");
        console.log("Average direct deployment:", totalDirectGas / 10, "gas");
        console.log("");

        vm.stopBroadcast();

        // Summary
        console.log("========================================");
        console.log("Gas Comparison Summary");
        console.log("========================================");
        console.log("Average DirectWallet:", totalDirectGas / 10, "gas");
        console.log("Average Clone:", totalCloneGas / 10, "gas");
        console.log("Average Deterministic:", totalDetGas / 5, "gas");
        console.log("");

        uint256 avgDirect = totalDirectGas / 10;
        uint256 avgClone = totalCloneGas / 10;
        console.log("Gas saved per clone:", avgDirect - avgClone, "gas");
        console.log("Savings percentage:", ((avgDirect - avgClone) * 100) / avgDirect, "%");
        console.log("");

        console.log("Break-even point:");
        console.log("Implementation cost:", implGas, "gas");
        console.log("Savings per clone:", avgDirect - avgClone, "gas");
        console.log("Break-even after:", implGas / (avgDirect - avgClone), "clones");
        console.log("========================================");
    }
}
