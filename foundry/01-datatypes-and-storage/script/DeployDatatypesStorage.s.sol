// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {DatatypesStorage} from "../src/DatatypesStorage.sol";

/**
 * @title DeployDatatypesStorage
 * @notice Deployment script for DatatypesStorage contract
 * @dev Complete the TODOs to implement the deployment script
 *
 * LEARNING GOALS:
 * 1. Understand Foundry Script contracts and the Script.sol base contract
 * 2. Learn how to read environment variables with vm.envOr()
 * 3. Master the broadcast pattern for sending transactions
 * 4. Practice deploying contracts and logging deployment information
 *
 * Quick commands:
 *   # Local (Anvil)
 *   forge script script/DeployDatatypesStorage.s.sol --broadcast --rpc-url http://localhost:8545
 *
 *   # Testnet (Sepolia)
 *   forge script script/DeployDatatypesStorage.s.sol --broadcast --rpc-url $SEPOLIA_RPC_URL \\
 *     --private-key $PRIVATE_KEY --verify
 *
 *   # Dry run (no tx sent)
 *   forge script script/DeployDatatypesStorage.s.sol
 */
contract DeployDatatypesStorage is Script {
    function run() external {
        // TODO: Read the deployer's private key from environment variable 'PRIVATE_KEY'
        //       Use vm.envOr() to provide a fallback value.
        //       Fallback should be Foundry's first Anvil account: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
        //       Why do we use a fallback? What is this account used for?
        // Hint: uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0x...));
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        // TODO: Start broadcasting transactions using vm.startBroadcast()
        //       Pass the deployerPrivateKey as an argument.
        //       What does startBroadcast do? Why is it necessary?
        // Hint: vm.startBroadcast(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);
        // TODO: Deploy the DatatypesStorage contract
        //       Create a new instance of DatatypesStorage and store it in a variable.
        //       What happens when you deploy a contract? What is the constructor called with?
        // Hint: DatatypesStorage datatypes = new DatatypesStorage();
        DatatypesStorage datatypes = new DatatypesStorage();
        // TODO: Log the deployed contract address using console.log()
        //       Log the address of the deployed contract.
        //       Why is logging useful in deployment scripts?
        // Hint: console.log("DatatypesStorage deployed at:", address(datatypes));
        console.log("DatatypesStorage deployed at:", address(datatypes));
        // TODO: Log the owner of the deployed contract
        //       Use the public owner() getter function.
        //       What should the owner be set to? Why?
        // Hint: console.log("Owner:", datatypes.owner());
        console.log("Owner:", datatypes.owner());
        // TODO: Log the isActive status of the deployed contract
        //       Use the public isActive() getter function.
        // Hint: console.log("Is Active:", datatypes.isActive());
        console.log("Is Active:", datatypes.isActive());
        // TODO: Stop broadcasting transactions using vm.stopBroadcast()
        //       This closes the broadcast session.
        //       Why is it important to stop broadcasting?
        // Hint: vm.stopBroadcast();
        vm.stopBroadcast();
    }
}
