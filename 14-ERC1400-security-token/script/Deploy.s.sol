// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/solution/ERC1400SecurityTokenSolution.sol";

contract DeployERC1400SecurityToken is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        vm.startBroadcast(deployerPrivateKey);
        
        ERC1400SecurityTokenSolution token = new ERC1400SecurityTokenSolution(
            "Real Estate Token",
            "RET"
        );
        
        console.log("ERC1400 Security Token deployed at:", address(token));
        console.log("Owner:", token.owner());
        
        vm.stopBroadcast();
    }
}
