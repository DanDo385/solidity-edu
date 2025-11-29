// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/solution/ErrorsRevertsSolution.sol";

contract DeployErrorsReverts is Script {
    function run() external {
        // Prefer PRIVATE_KEY env var when broadcasting; default uses Anvil's first account
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the completed solution contract for this project
        ErrorsRevertsSolution errors = new ErrorsRevertsSolution();
        console.log("ErrorsReverts deployed at:", address(errors));

        // Stop broadcasting after deployment to avoid accidental txs
        vm.stopBroadcast();
    }
}
