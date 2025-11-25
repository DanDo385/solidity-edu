// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/solution/UpgradeableProxySolution.sol";

contract DeployUpgradeableProxy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        vm.startBroadcast(deployerPrivateKey);
        
        ImplementationV1 impl = new ImplementationV1();
        UUPSProxy proxy = new UUPSProxy(address(impl));
        
        console.log("Implementation deployed at:", address(impl));
        console.log("Proxy deployed at:", address(proxy));
        
        vm.stopBroadcast();
    }
}
