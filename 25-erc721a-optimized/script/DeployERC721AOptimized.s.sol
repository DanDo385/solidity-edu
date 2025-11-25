// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/solution/ERC721AOptimizedSolution.sol";

/**
 * @title Deploy Script for ERC-721A Optimized NFT
 * @notice Deploys an optimized NFT collection using ERC-721A
 * @dev Run with: forge script script/DeployERC721AOptimized.s.sol:DeployERC721AOptimized --rpc-url <RPC_URL> --broadcast
 */
contract DeployERC721AOptimized is Script {
    function run() external {
        // Read private key from environment or use default for local testing
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the optimized NFT contract
        OptimizedNFTSolution nft = new OptimizedNFTSolution(
            "Optimized Collection",
            "OPTC"
        );

        vm.stopBroadcast();

        // Log deployment information
        console.log("\n=== ERC-721A Optimized NFT Deployed ===");
        console.log("Contract address:", address(nft));
        console.log("Name:", nft.name());
        console.log("Symbol:", nft.symbol());
        console.log("Max Supply:", nft.MAX_SUPPLY());
        console.log("Mint Price:", nft.MINT_PRICE());
        console.log("Max Per Transaction:", nft.MAX_MINT_PER_TX());
        console.log("\n=== Gas Optimization Info ===");
        console.log("Standard ERC-721 (5 mint):", "~750,000 gas");
        console.log("ERC-721A (5 mint):", "~175,000 gas");
        console.log("Savings:", "~575,000 gas (77%)");
        console.log("\n=== Next Steps ===");
        console.log("1. Verify contract on Etherscan");
        console.log("2. Test minting with various batch sizes");
        console.log("3. Monitor gas costs in production");
        console.log("4. Set up metadata URI if needed");
    }
}

/**
 * DEPLOYMENT EXAMPLES:
 *
 * Local Anvil:
 * forge script script/DeployERC721AOptimized.s.sol:DeployERC721AOptimized --rpc-url http://localhost:8545 --broadcast
 *
 * Sepolia Testnet:
 * forge script script/DeployERC721AOptimized.s.sol:DeployERC721AOptimized \
 *   --rpc-url $SEPOLIA_RPC_URL \
 *   --broadcast \
 *   --verify \
 *   -vvvv
 *
 * Mainnet:
 * forge script script/DeployERC721AOptimized.s.sol:DeployERC721AOptimized \
 *   --rpc-url $MAINNET_RPC_URL \
 *   --broadcast \
 *   --verify \
 *   -vvvv
 *
 * With Ledger:
 * forge script script/DeployERC721AOptimized.s.sol:DeployERC721AOptimized \
 *   --rpc-url $MAINNET_RPC_URL \
 *   --broadcast \
 *   --ledger \
 *   --sender <LEDGER_ADDRESS>
 */
