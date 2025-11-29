// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../src/solution/DatatypesStorageSolution.sol";

/**
 * @title DeployDatatypesStorageSolution
 * @notice Complete deployment script solution for DatatypesStorage contract
 * @dev This is the solution version - students should implement DeployDatatypesStorage.s.sol
 *
 * Steps:
 *      - Reads PRIVATE_KEY from env, falls back to Anvil default for local use.
 *      - Starts a broadcast so every call is sent as a transaction.
 *      - Deploys the solution contract.
 *      - Logs the address so you can plug it into tests or frontends.
 *
 * Quick commands:
 *   # Local (Anvil)
 *   forge script script/solution/DeployDatatypesStorageSolution.s.sol --broadcast --rpc-url http://localhost:8545
 *
 *   # Testnet (Sepolia)
 *   forge script script/solution/DeployDatatypesStorageSolution.s.sol --broadcast --rpc-url $SEPOLIA_RPC_URL \\
 *     --private-key $PRIVATE_KEY --verify
 *
 *   # Dry run (no tx sent)
 *   forge script script/solution/DeployDatatypesStorageSolution.s.sol
 */
contract DeployDatatypesStorageSolution is Script {
    function run() external {
        // Pull a deployer key from env; default is Foundry's first Anvil account for quick demos
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));

        // Begin sending real transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the fully implemented solution (students compare against this)
        DatatypesStorageSolution datatypes = new DatatypesStorageSolution();

        // Useful logs for quick wiring into frontends/scripts
        console.log("DatatypesStorage deployed at:", address(datatypes));
        console.log("Owner:", datatypes.owner());
        console.log("Is Active:", datatypes.isActive());

        // Close the broadcast session
        vm.stopBroadcast();
    }
}
