// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/solution/DatatypesStorageSolution.sol";

/**
 * @title DeployDatatypesStorage
 * @notice Deployment script for DatatypesStorage contract
 * @dev Usage:
 *      Local deployment:
 *        forge script script/Deploy.s.sol --broadcast --rpc-url http://localhost:8545
 *
 *      Testnet deployment (e.g., Sepolia):
 *        forge script script/Deploy.s.sol --broadcast --rpc-url $SEPOLIA_RPC_URL \
 *          --private-key $PRIVATE_KEY --verify
 *
 *      Dry run (simulation):
 *        forge script script/Deploy.s.sol
 */
contract DeployDatatypesStorage is Script {
    function run() external {
        // Read deployer private key from environment or use default for local testing
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the contract
        DatatypesStorageSolution datatypes = new DatatypesStorageSolution();

        // Log deployment address
        console.log("DatatypesStorage deployed at:", address(datatypes));
        console.log("Owner:", datatypes.owner());
        console.log("Is Active:", datatypes.isActive());

        // Stop broadcasting
        vm.stopBroadcast();
    }
}
