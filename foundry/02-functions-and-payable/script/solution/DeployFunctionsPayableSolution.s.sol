// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { FunctionsPayableSolution } from "../../src/solution/FunctionsPayableSolution.sol";

/**
 * @title DeployFunctionsPayableSolution
 * @notice Reference deployment script for FunctionsPayable contract
 * @dev This script demonstrates:
 *      - Reading environment variables with fallback values
 *      - Broadcasting transactions
 *      - Deploying contracts with and without ETH
 *      - Logging deployment information
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                    DEPLOYMENT SCRIPT PATTERNS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * WHY DEPLOYMENT SCRIPTS?
 *   - Reproducible deployments (same script = same result)
 *   - Testable (can run dry-run before real deployment)
 *   - Version controlled (deployment logic lives in code)
 *   - Automatable (CI/CD pipelines can deploy)
 *
 * BROADCAST PATTERN:
 *   1. Read private key from environment
 *   2. Start broadcast (enables transaction sending)
 *   3. Deploy contracts / call functions
 *   4. Stop broadcast (cleanup)
 *
 * ENVIRONMENT VARIABLES:
 *   - PRIVATE_KEY: Deployer's private key (NEVER commit to git!)
 *   - Use vm.envOr() with safe fallback for local development
 *   - Anvil's default account #0 is safe for local testing only
 *
 * PAYABLE CONSTRUCTOR DEPLOYMENT:
 *   - Without ETH: new FunctionsPayable()
 *   - With ETH: new FunctionsPayable{value: amount}()
 *   - ETH sent during deployment becomes contract balance
 */
contract DeployFunctionsPayableSolution is Script {
    function run() external {
        // 🔑 READ PRIVATE KEY: From environment with safe fallback
        // vm.envOr() reads environment variable, uses fallback if not set
        // Fallback is Anvil's default Account #0 (safe for local dev only!)
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );

        // 📡 START BROADCAST: Enable transaction sending
        // Without this, script runs in simulation mode (dry-run)
        // With this, transactions are actually sent to the network
        vm.startBroadcast(deployerPrivateKey);

        // 🚀 DEPLOY WITHOUT ETH: Standard deployment
        // Constructor sets owner = msg.sender (the deployer)
        FunctionsPayableSolution payableContract = new FunctionsPayableSolution();

        // 📝 LOG DEPLOYMENT INFO: Critical for verification and frontend integration
        console.log("FunctionsPayable deployed at:", address(payableContract));
        console.log("Owner:", payableContract.owner());
        console.log("Contract balance:", payableContract.getContractBalance());

        // 💰 DEPLOY WITH ETH: Demonstrates payable constructor
        // This sends 0.1 ETH along with the deployment transaction
        // The ETH becomes part of the contract's balance immediately
        FunctionsPayableSolution fundedContract = new FunctionsPayableSolution{value: 0.1 ether}();

        console.log("\nFunded contract deployed at:", address(fundedContract));
        console.log("Funded contract owner:", fundedContract.owner());
        console.log("Funded contract balance:", fundedContract.getContractBalance());

        // 🛑 STOP BROADCAST: Cleanup and prevent accidental transactions
        // Always stop broadcasting when done
        vm.stopBroadcast();
    }
}
