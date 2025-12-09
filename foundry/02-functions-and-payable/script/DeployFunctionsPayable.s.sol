// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { FunctionsPayable } from "../src/FunctionsPayable.sol";

/**
 * @title DeployFunctionsPayable
 * @notice Deployment script for FunctionsPayable contract
 * @dev Complete the TODOs to implement the deployment script
 *
 * LEARNING GOALS:
 * 1. Understand Foundry Script contracts and the Script.sol base contract
 * 2. Learn how to read environment variables with vm.envOr()
 * 3. Master the broadcast pattern for sending transactions
 * 4. Practice deploying contracts with ETH using {value: amount} syntax
 * 5. Learn how to log deployment information for verification
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                    DEPLOYING PAYABLE CONTRACTS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * This contract has a payable constructor, which means you can send ETH
 * during deployment! This is useful for:
 * - Initial funding of DeFi protocols
 * - Setting up liquidity pools
 * - Pre-funding reward pools
 *
 * HOW TO DEPLOY WITH ETH:
 *   new FunctionsPayable{value: 1 ether}()
 *
 * The {value: amount} syntax sends ETH along with the deployment transaction.
 * This ETH becomes part of the contract's balance immediately.
 *
 * Quick commands:
 *   # Local (Anvil)
 *   forge script script/DeployFunctionsPayable.s.sol --broadcast --rpc-url http://localhost:8545
 *
 *   # Testnet (Sepolia)
 *   forge script script/DeployFunctionsPayable.s.sol --broadcast --rpc-url $SEPOLIA_RPC_URL \
 *     --private-key $PRIVATE_KEY --verify
 *
 *   # Dry run (no tx sent)
 *   forge script script/DeployFunctionsPayable.s.sol
 */
contract DeployFunctionsPayable is Script {
    function run() external {
        // TODO: Read the deployer's private key from environment variable 'PRIVATE_KEY'
        //       Use vm.envOr() to provide a fallback value.
        //       Fallback should be Foundry's first Anvil account: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
        //       Why do we use a fallback? What is this account used for?
        // Hint: uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0x...));

        // TODO: Start broadcasting transactions using vm.startBroadcast()
        //       Pass the deployerPrivateKey as an argument.
        //       What does startBroadcast do? Why is it necessary?
        // Hint: vm.startBroadcast(deployerPrivateKey);

        // TODO: Deploy the FunctionsPayable contract WITHOUT ETH first
        //       Create a new instance and store it in a variable.
        //       What happens when you deploy a contract? What is the constructor called with?
        // Hint: FunctionsPayable payableContract = new FunctionsPayable();

        // TODO: Log the deployed contract address using console.log()
        //       Log the address of the deployed contract.
        //       Why is logging useful in deployment scripts?
        // Hint: console.log("FunctionsPayable deployed at:", address(payableContract));

        // TODO: Log the owner of the deployed contract
        //       Use the public owner() getter function.
        //       What should the owner be set to? Why?
        // Hint: console.log("Owner:", payableContract.owner());

        // TODO: Log the contract's initial balance
        //       Use the getContractBalance() function.
        //       What should this be? Why?
        // Hint: console.log("Contract balance:", payableContract.getContractBalance());

        // TODO: (Optional) Deploy a second instance WITH ETH
        //       Try deploying with: new FunctionsPayable{value: 0.1 ether}()
        //       This demonstrates the payable constructor in action!
        //       Log its address and balance to see the difference.
        // Hint: FunctionsPayable fundedContract = new FunctionsPayable{value: 0.1 ether}();
        //       console.log("Funded contract deployed at:", address(fundedContract));
        //       console.log("Funded contract balance:", fundedContract.getContractBalance());

        // TODO: Stop broadcasting transactions using vm.stopBroadcast()
        //       This closes the broadcast session.
        //       Why is it important to stop broadcasting?
        // Hint: vm.stopBroadcast();
    }
}
