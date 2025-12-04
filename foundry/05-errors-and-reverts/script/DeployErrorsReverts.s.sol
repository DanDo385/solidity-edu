// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/ErrorsReverts.sol";

/**
 * @title DeployErrorsReverts
 * @notice Deployment script for ErrorsReverts contract
 * @dev Complete the TODOs to implement the deployment script
 *
 * LEARNING GOALS:
 * 1. Understand Foundry Script contracts and the Script.sol base contract
 * 2. Learn how to read environment variables with vm.envOr()
 * 3. Master the broadcast pattern for sending transactions
 * 4. Practice deploying contracts with error handling
 * 5. Learn how to test error scenarios in deployment scripts
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                    DEPLOYING ERROR-HANDLED CONTRACTS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * Error-handled contracts are critical for user experience:
 * - Clear error messages help users understand what went wrong
 * - Gas-efficient errors reduce transaction costs
 * - Proper error handling prevents unexpected behavior
 *
 * Quick commands:
 *   # Local (Anvil)
 *   forge script script/DeployErrorsReverts.s.sol --broadcast --rpc-url http://localhost:8545
 *
 *   # Testnet (Sepolia)
 *   forge script script/DeployErrorsReverts.s.sol --broadcast --rpc-url $SEPOLIA_RPC_URL \
 *     --private-key $PRIVATE_KEY --verify
 *
 *   # Dry run (no tx sent)
 *   forge script script/DeployErrorsReverts.s.sol
 */
contract DeployErrorsReverts is Script {
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

        // TODO: Deploy the ErrorsReverts contract
        //       Create a new instance and store it in a variable.
        //       What happens when you deploy this contract? What is the initial state?
        // Hint: ErrorsReverts errors = new ErrorsReverts();

        // TODO: Log the deployed contract address using console.log()
        //       Log the address of the deployed contract.
        //       Why is logging useful in deployment scripts?
        // Hint: console.log("ErrorsReverts deployed at:", address(errors));

        // TODO: Log the owner of the deployed contract
        //       Use the public owner() getter function.
        //       What should the owner be set to? Why?
        // Hint: console.log("Owner:", errors.owner());

        // TODO: Log the initial balance
        //       Use the getBalance() function.
        //       What should this be? Why?
        // Hint: console.log("Initial balance:", errors.getBalance());

        // TODO: (Optional) Test error scenarios after deployment
        //       Try calling depositWithCustomError(0) - it should revert
        //       This demonstrates that scripts can test error handling!
        //       Use try-catch or expectRevert to handle the revert
        // Hint: try errors.depositWithCustomError(0) {} catch {}

        // TODO: Stop broadcasting transactions using vm.stopBroadcast()
        //       This closes the broadcast session.
        //       Why is it important to stop broadcasting?
        // Hint: vm.stopBroadcast();
    }
}
