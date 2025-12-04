// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../src/solution/ModifiersRestrictionsSolution.sol";

/**
 * @title DeployModifiersRestrictionsSolution
 * @notice Reference deployment script for ModifiersRestrictions contract
 * @dev This script demonstrates:
 *      - Reading environment variables with fallback values
 *      - Broadcasting transactions
 *      - Deploying contracts with access control
 *      - Logging deployment information
 *      - Configuring initial roles
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                    ACCESS CONTROL DEPLOYMENT PATTERNS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * Access control contracts need proper setup:
 * - Owner is set in constructor (deployer)
 * - Initial roles are granted in constructor
 * - Additional roles can be granted after deployment
 *
 * WHY DEPLOYMENT SCRIPTS FOR ACCESS CONTROL?
 *   - Ensures roles are configured correctly
 *   - Reproducible setup across environments
 *   - Can grant roles to multiple addresses
 *   - Can verify role configuration
 */
contract DeployModifiersRestrictionsSolution is Script {
    function run() external {
        // 🔑 READ PRIVATE KEY: From environment with safe fallback
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );

        // 📡 START BROADCAST: Enable transaction sending
        vm.startBroadcast(deployerPrivateKey);

        // 🚀 DEPLOY CONTRACT: Constructor sets owner and initial roles
        ModifiersRestrictionsSolution modifiers = new ModifiersRestrictionsSolution();

        // 📝 LOG DEPLOYMENT INFO: Critical for verification and frontend integration
        console.log("ModifiersRestrictions deployed at:", address(modifiers));
        console.log("Owner:", modifiers.owner());
        console.log("Deployer has ADMIN_ROLE:", modifiers.hasRole(modifiers.ADMIN_ROLE(), vm.addr(deployerPrivateKey)));
        console.log("Deployer has MINTER_ROLE:", modifiers.hasRole(modifiers.MINTER_ROLE(), vm.addr(deployerPrivateKey)));

        // 🎭 OPTIONAL: Grant additional roles to test addresses
        // This demonstrates that scripts can do more than just deploy!
        address testUser = vm.addr(1);
        modifiers.grantRole(modifiers.MINTER_ROLE(), testUser);
        console.log("Granted MINTER_ROLE to test user:", testUser);
        console.log("Test user has MINTER_ROLE:", modifiers.hasRole(modifiers.MINTER_ROLE(), testUser));

        // 🛑 STOP BROADCAST: Cleanup and prevent accidental transactions
        vm.stopBroadcast();
    }
}
