// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/ModifiersRestrictions.sol";

/**
 * @title DeployModifiersRestrictions
 * @notice Deployment script for ModifiersRestrictions contract
 * @dev Complete the TODOs to implement the deployment script
 *
 * LEARNING GOALS:
 * 1. Understand Foundry Script contracts and the Script.sol base contract
 * 2. Learn how to read environment variables with vm.envOr()
 * 3. Master the broadcast pattern for sending transactions
 * 4. Practice deploying contracts with access control setup
 * 5. Learn how to configure initial roles after deployment
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                    DEPLOYING ACCESS CONTROL CONTRACTS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * Access control contracts need proper setup after deployment:
 * - Owner is set in constructor (deployer)
 * - Initial roles are granted in constructor
 * - Additional roles can be granted after deployment
 *
 * Quick commands:
 *   # Local (Anvil)
 *   forge script script/DeployModifiersRestrictions.s.sol --broadcast --rpc-url http://localhost:8545
 *
 *   # Testnet (Sepolia)
 *   forge script script/DeployModifiersRestrictions.s.sol --broadcast --rpc-url $SEPOLIA_RPC_URL \
 *     --private-key $PRIVATE_KEY --verify
 *
 *   # Dry run (no tx sent)
 *   forge script script/DeployModifiersRestrictions.s.sol
 */
contract DeployModifiersRestrictions is Script {
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

        // TODO: Deploy the ModifiersRestrictions contract
        //       Create a new instance and store it in a variable.
        //       What happens when you deploy this contract? What is the initial state?
        //       What roles are granted in the constructor?
        // Hint: ModifiersRestrictions modifiers = new ModifiersRestrictions();

        // TODO: Log the deployed contract address using console.log()
        //       Log the address of the deployed contract.
        //       Why is logging useful in deployment scripts?
        // Hint: console.log("ModifiersRestrictions deployed at:", address(modifiers));

        // TODO: Log the owner of the deployed contract
        //       Use the public owner() getter function.
        //       What should the owner be set to? Why?
        // Hint: console.log("Owner:", modifiers.owner());

        // TODO: (Optional) Grant additional roles after deployment
        //       Try granting MINTER_ROLE to a test address
        //       This demonstrates that scripts can do more than just deploy!
        //       You'll need to create a test address first: address testUser = vm.addr(1);
        //       Then grant the role: modifiers.grantRole(modifiers.MINTER_ROLE(), testUser);
        //       Then verify: console.log("Has MINTER_ROLE:", modifiers.hasRole(modifiers.MINTER_ROLE(), testUser));

        // TODO: Stop broadcasting transactions using vm.stopBroadcast()
        //       This closes the broadcast session.
        //       Why is it important to stop broadcasting?
        // Hint: vm.stopBroadcast();
    }
}
