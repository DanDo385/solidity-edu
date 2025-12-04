// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../src/solution/ErrorsRevertsSolution.sol";

/**
 * @title DeployErrorsRevertsSolution
 * @notice Reference deployment script for ErrorsReverts contract
 * @dev This script demonstrates:
 *      - Reading environment variables with fallback values
 *      - Broadcasting transactions
 *      - Deploying contracts with error handling
 *      - Logging deployment information
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                    ERROR-HANDLED CONTRACT DEPLOYMENT
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * Error-handled contracts are critical for user experience:
 * - Clear error messages help users understand what went wrong
 * - Gas-efficient errors reduce transaction costs
 * - Proper error handling prevents unexpected behavior
 */
contract DeployErrorsRevertsSolution is Script {
    function run() external {
        // 🔑 READ PRIVATE KEY: From environment with safe fallback
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );

        // 📡 START BROADCAST: Enable transaction sending
        vm.startBroadcast(deployerPrivateKey);

        // 🚀 DEPLOY CONTRACT: Constructor sets owner
        ErrorsRevertsSolution errors = new ErrorsRevertsSolution();

        // 📝 LOG DEPLOYMENT INFO: Critical for verification and frontend integration
        console.log("ErrorsReverts deployed at:", address(errors));
        console.log("Owner:", errors.owner());
        console.log("Initial balance:", errors.getBalance());

        // 🛑 STOP BROADCAST: Cleanup and prevent accidental transactions
        vm.stopBroadcast();
    }
}
