// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {ContractFactory, SimpleContract} from "../src/solution/Project16Solution.sol";

/**
 * @title Deploy Project 16
 * @notice Deployment script for CREATE2 factory demonstration
 * @dev Deploys factory and demonstrates CREATE2 deployment with address prediction
 */
contract DeployProject16 is Script {
    ContractFactory public factory;

    function run() public {
        // Get deployer private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        console2.log("=================================================");
        console2.log("Project 16: Contract Factories (CREATE2)");
        console2.log("=================================================");
        console2.log("");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the factory
        factory = new ContractFactory();
        console2.log("Factory deployed at:", address(factory));
        console2.log("");

        // Example 1: Deploy a contract with CREATE2
        console2.log("----- Example 1: Basic CREATE2 Deployment -----");

        bytes32 salt1 = keccak256("example-1");
        address owner1 = msg.sender;
        uint256 value1 = 100;
        string memory message1 = "First CREATE2 deployment";

        // Predict address BEFORE deployment
        address predicted1 = factory.predictSimpleContractAddress(salt1, owner1, value1, message1);
        console2.log("Predicted address:", predicted1);

        // Deploy contract
        address deployed1 = factory.deploy(salt1, owner1, value1, message1);
        console2.log("Deployed address: ", deployed1);
        console2.log("Match:", predicted1 == deployed1 ? "YES" : "NO");
        console2.log("");

        // Example 2: Deploy with different salt
        console2.log("----- Example 2: Different Salt -----");

        bytes32 salt2 = keccak256("example-2");
        address predicted2 = factory.predictSimpleContractAddress(salt2, owner1, value1, message1);
        address deployed2 = factory.deploy(salt2, owner1, value1, message1);

        console2.log("Salt 1:", vm.toString(salt1));
        console2.log("Salt 2:", vm.toString(salt2));
        console2.log("Address 1:", deployed1);
        console2.log("Address 2:", deployed2);
        console2.log("Different:", deployed1 != deployed2 ? "YES" : "NO");
        console2.log("");

        // Example 3: Deploy with different constructor args
        console2.log("----- Example 3: Different Constructor Args -----");

        bytes32 salt3 = keccak256("example-3");
        string memory message3 = "Different message";

        address predicted3a = factory.predictSimpleContractAddress(salt3, owner1, value1, message1);
        address predicted3b = factory.predictSimpleContractAddress(salt3, owner1, value1, message3);

        console2.log("Same salt, same args:", predicted3a);
        console2.log("Same salt, diff args:", predicted3b);
        console2.log("Different addresses:", predicted3a != predicted3b ? "YES" : "NO");
        console2.log("");

        // Example 4: Using salt generation
        console2.log("----- Example 4: Salt Generation -----");

        bytes32 generatedSalt = factory.generateSalt(1);
        console2.log("Generated salt for nonce 1:", vm.toString(generatedSalt));

        address predicted4 = factory.predictSimpleContractAddress(generatedSalt, owner1, value1, "Generated salt");
        address deployed4 = factory.deploy(generatedSalt, owner1, value1, "Generated salt");

        console2.log("Predicted:", predicted4);
        console2.log("Deployed: ", deployed4);
        console2.log("");

        // Example 5: Deploy with assembly
        console2.log("----- Example 5: Assembly Deployment -----");

        bytes32 salt5 = keccak256("assembly-example");
        bytes memory bytecode5 = factory.getCreationBytecode(owner1, 999, "Assembly deployment");

        address predicted5 = factory.predictAddress(salt5, bytecode5);
        console2.log("Predicted (assembly):", predicted5);

        address deployed5 = factory.deployWithAssembly(salt5, bytecode5);
        console2.log("Deployed (assembly): ", deployed5);
        console2.log("Match:", predicted5 == deployed5 ? "YES" : "NO");
        console2.log("");

        vm.stopBroadcast();

        // Summary
        console2.log("=================================================");
        console2.log("DEPLOYMENT SUMMARY");
        console2.log("=================================================");
        console2.log("Factory address:", address(factory));
        console2.log("Total deployments:", factory.getDeploymentCount());
        console2.log("");
        console2.log("Deployed contracts:");
        console2.log("1.", deployed1);
        console2.log("2.", deployed2);
        console2.log("3.", deployed4);
        console2.log("4.", deployed5);
        console2.log("");

        // Verification info
        console2.log("=================================================");
        console2.log("VERIFICATION");
        console2.log("=================================================");
        console2.log("To verify the factory on Etherscan:");
        console2.log("forge verify-contract", address(factory), "ContractFactory --watch");
        console2.log("");
        console2.log("Chain ID:", block.chainid);
        console2.log("Block number:", block.number);
        console2.log("=================================================");
    }

    /**
     * @notice Run local demonstration without broadcasting
     * @dev Useful for testing the script locally
     */
    function runLocal() public {
        console2.log("=================================================");
        console2.log("LOCAL DEMONSTRATION - CREATE2");
        console2.log("=================================================");
        console2.log("");

        // Deploy factory locally
        factory = new ContractFactory();
        console2.log("Factory deployed at:", address(factory));
        console2.log("");

        // Demonstrate address prediction
        bytes32 salt = keccak256("local-test");
        address owner = address(this);
        uint256 value = 42;
        string memory message = "Local test";

        console2.log("----- Address Prediction Demo -----");
        console2.log("");

        // Show bytecode composition
        bytes memory creationCode = type(SimpleContract).creationCode;
        bytes memory constructorArgs = abi.encode(owner, value, message);
        bytes memory fullBytecode = abi.encodePacked(creationCode, constructorArgs);

        console2.log("Creation code length:", creationCode.length);
        console2.log("Constructor args length:", constructorArgs.length);
        console2.log("Full bytecode length:", fullBytecode.length);
        console2.log("");

        // Show address calculation
        console2.log("CREATE2 Formula Components:");
        console2.log("- Prefix: 0xff");
        console2.log("- Deployer:", address(factory));
        console2.log("- Salt:", vm.toString(salt));
        console2.log("- Bytecode hash:", vm.toString(keccak256(fullBytecode)));
        console2.log("");

        // Predict
        address predicted = factory.predictAddress(salt, fullBytecode);
        console2.log("Predicted address:", predicted);
        console2.log("");

        // Deploy
        address deployed = factory.deploy(salt, owner, value, message);
        console2.log("Deployed address:", deployed);
        console2.log("");

        // Verify
        console2.log("Prediction correct:", predicted == deployed ? "YES" : "NO");
        console2.log("Contract deployed:", factory.isDeployed(deployed) ? "YES" : "NO");
        console2.log("");

        // Show contract state
        SimpleContract instance = SimpleContract(deployed);
        console2.log("----- Contract State -----");
        console2.log("Owner:", instance.owner());
        console2.log("Value:", instance.value());
        console2.log("Message:", instance.message());
        console2.log("");

        // Demonstrate duplicate prevention
        console2.log("----- Duplicate Prevention -----");
        console2.log("Attempting to deploy with same salt...");

        try factory.deploy(salt, owner, value, message) returns (address) {
            console2.log("ERROR: Should have reverted!");
        } catch {
            console2.log("SUCCESS: Duplicate deployment prevented");
        }
        console2.log("");

        // Demonstrate different salts
        console2.log("----- Multiple Deployments -----");
        for (uint256 i = 0; i < 3; i++) {
            bytes32 newSalt = keccak256(abi.encodePacked("multi", i));
            address newAddress = factory.deploy(newSalt, owner, value + i, message);
            console2.log("Deployment", i + 1, "at:", newAddress);
        }

        console2.log("");
        console2.log("Total deployments:", factory.getDeploymentCount());
        console2.log("");
        console2.log("=================================================");
    }
}

/**
 * USAGE INSTRUCTIONS:
 * ===================
 *
 * Local Testing:
 * --------------
 * forge script script/DeployProject16.s.sol --sig "runLocal()"
 *
 * Deploy to Local Network:
 * ------------------------
 * # Start local node
 * anvil
 *
 * # In another terminal
 * forge script script/DeployProject16.s.sol \
 *   --rpc-url http://localhost:8545 \
 *   --broadcast \
 *   --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
 *
 * Deploy to Testnet:
 * ------------------
 * # Set environment variables
 * export PRIVATE_KEY=0x...
 * export SEPOLIA_RPC_URL=https://...
 *
 * # Deploy
 * forge script script/DeployProject16.s.sol \
 *   --rpc-url $SEPOLIA_RPC_URL \
 *   --broadcast \
 *   --verify
 *
 * Deploy to Mainnet:
 * ------------------
 * forge script script/DeployProject16.s.sol \
 *   --rpc-url $MAINNET_RPC_URL \
 *   --broadcast \
 *   --verify \
 *   --slow
 *
 * Verification Only:
 * ------------------
 * forge verify-contract <ADDRESS> ContractFactory \
 *   --chain-id <CHAIN_ID> \
 *   --watch
 *
 * NOTES:
 * ------
 * - Factory address will be different on each chain unless deployed
 *   from the same address with the same nonce
 * - To get the same factory address on multiple chains, you need:
 *   1. Same deployer address
 *   2. Same nonce on each chain
 *   3. Same bytecode (compiler version and settings)
 * - Contracts deployed by the factory can have the same address
 *   on multiple chains if the factory addresses match
 */
