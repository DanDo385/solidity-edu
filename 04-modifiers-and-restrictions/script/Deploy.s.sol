// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/solution/ModifiersRestrictionsSolution.sol";

contract DeployModifiersRestrictions is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        vm.startBroadcast(deployerPrivateKey);
        
        ModifiersRestrictionsSolution modifiers = new ModifiersRestrictionsSolution();
        console.log("ModifiersRestrictions deployed at:", address(modifiers));
        
        vm.stopBroadcast();
    }
}
