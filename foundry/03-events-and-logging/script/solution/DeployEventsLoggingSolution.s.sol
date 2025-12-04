// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../src/solution/EventsLoggingSolution.sol";

/**
 * @title DeployEventsLoggingSolution
 * @notice Reference deployment script for EventsLogging contract
 * @dev This script demonstrates:
 *      - Reading environment variables with fallback values
 *      - Broadcasting transactions
 *      - Deploying contracts
 *      - Logging deployment information
 *      - Interacting with deployed contracts
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                    EVENT-BASED CONTRACT DEPLOYMENT
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * After deployment, you can query events using:
 * - cast logs: Foundry's CLI tool for querying events
 * - ethers.js: JavaScript library for event listening
 * - The Graph: Decentralized indexing protocol
 *
 * Example event query:
 *   cast logs --address <CONTRACT_ADDRESS> \
 *     "Transfer(address indexed,address indexed,uint256)"
 */
contract DeployEventsLoggingSolution is Script {
    function run() external {
        // 🔑 READ PRIVATE KEY: From environment with safe fallback
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );

        // 📡 START BROADCAST: Enable transaction sending
        vm.startBroadcast(deployerPrivateKey);

        // 🚀 DEPLOY CONTRACT: Constructor sets owner and initial balance
        EventsLoggingSolution eventsContract = new EventsLoggingSolution();

        // 📝 LOG DEPLOYMENT INFO: Critical for verification and frontend integration
        console.log("EventsLogging deployed at:", address(eventsContract));
        console.log("Owner:", eventsContract.owner());
        console.log("Deployer balance:", eventsContract.balanceOf(vm.addr(deployerPrivateKey)));

        // 🛑 STOP BROADCAST: Cleanup and prevent accidental transactions
        vm.stopBroadcast();
    }
}
