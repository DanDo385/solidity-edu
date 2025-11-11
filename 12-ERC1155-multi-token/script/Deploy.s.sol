// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/solution/ERC1155MultiTokenSolution.sol";

contract DeployERC1155MultiToken is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        vm.startBroadcast(deployerPrivateKey);
        
        ERC1155MultiTokenSolution token = new ERC1155MultiTokenSolution(
            "Game Assets",
            "GAME",
            "https://api.example.com/metadata/"
        );
        
        console.log("ERC1155 Multi-Token deployed at:", address(token));
        
        vm.stopBroadcast();
    }
}
