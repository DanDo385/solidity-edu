// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/solution/ERC4626VaultSolution.sol";

contract DeployERC4626Vault is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY", 
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Example: Deploy vault for USDC (replace with actual address)
        address usdcAddress = address(0); // Replace with actual USDC address
        
        // For demo, we'll note this
        console.log("Deploy vault with actual ERC20 asset address");
        console.log("Example: USDC on Ethereum mainnet: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48");
        
        if (usdcAddress != address(0)) {
            ERC4626VaultSolution vault = new ERC4626VaultSolution(
                usdcAddress,
                "Vault USDC",
                "vUSDC"
            );
            
            console.log("ERC4626 Vault deployed at:", address(vault));
            console.log("Underlying asset:", usdcAddress);
            console.log("Vault name:", vault.name());
            console.log("Vault symbol:", vault.symbol());
        } else {
            console.log("Set USDC_ADDRESS environment variable to deploy");
        }
        
        vm.stopBroadcast();
    }
}
