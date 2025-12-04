// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/EventsLogging.sol";

/**
 * @title DeployEventsLogging
 * @notice Deployment script for EventsLogging contract
 * @dev Complete the TODOs to implement the deployment script
 *
 * LEARNING GOALS:
 * 1. Understand Foundry Script contracts and the Script.sol base contract
 * 2. Learn how to read environment variables with vm.envOr()
 * 3. Master the broadcast pattern for sending transactions
 * 4. Practice deploying contracts and logging deployment information
 * 5. Learn how to interact with deployed contracts after deployment
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                    DEPLOYING EVENT-BASED CONTRACTS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * This contract uses events extensively for logging. After deployment, you
 * can query events using tools like:
 * - cast logs (Foundry CLI)
 * - ethers.js (JavaScript)
 * - web3.py (Python)
 * - The Graph (decentralized indexing)
 *
 * Quick commands:
 *   # Local (Anvil)
 *   forge script script/DeployEventsLogging.s.sol --broadcast --rpc-url http://localhost:8545
 *
 *   # Testnet (Sepolia)
 *   forge script script/DeployEventsLogging.s.sol --broadcast --rpc-url $SEPOLIA_RPC_URL \
 *     --private-key $PRIVATE_KEY --verify
 *
 *   # Dry run (no tx sent)
 *   forge script script/DeployEventsLogging.s.sol
 *
 *   # Query events after deployment
 *   cast logs --address <CONTRACT_ADDRESS> "Transfer(address indexed,address indexed,uint256)"
 */
contract DeployEventsLogging is Script {
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

        // TODO: Deploy the EventsLogging contract
        //       Create a new instance and store it in a variable.
        //       What happens when you deploy this contract? What is the initial state?
        // Hint: EventsLogging eventsContract = new EventsLogging();

        // TODO: Log the deployed contract address using console.log()
        //       Log the address of the deployed contract.
        //       Why is logging useful in deployment scripts?
        // Hint: console.log("EventsLogging deployed at:", address(eventsContract));

        // TODO: Log the owner of the deployed contract
        //       Use the public owner() getter function.
        //       What should the owner be set to? Why?
        // Hint: console.log("Owner:", eventsContract.owner());

        // TODO: Log the deployer's initial balance
        //       Use the balanceOf() function with the deployer's address.
        //       What should this be? Check the constructor!
        // Hint: console.log("Deployer balance:", eventsContract.balanceOf(vm.addr(deployerPrivateKey)));

        // TODO: (Optional) Interact with the contract after deployment
        //       Try calling transfer() or deposit() to generate some events
        //       This demonstrates that scripts can do more than just deploy!
        // Hint: eventsContract.transfer(vm.addr(1), 100 ether);

        // TODO: Stop broadcasting transactions using vm.stopBroadcast()
        //       This closes the broadcast session.
        //       Why is it important to stop broadcasting?
        // Hint: vm.stopBroadcast();
    }
}
