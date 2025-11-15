// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/solution/Project30Solution.sol";

/**
 * @title DeployProject30
 * @notice Deployment script for On-Chain SVG NFT
 * @dev Deploys the contract and optionally mints test tokens
 *
 * Usage:
 *   Deploy to local:
 *     forge script script/DeployProject30.s.sol:DeployProject30 --fork-url http://localhost:8545 --broadcast
 *
 *   Deploy to testnet:
 *     forge script script/DeployProject30.s.sol:DeployProject30 --rpc-url sepolia --broadcast --verify
 *
 *   Deploy to mainnet (use with caution):
 *     forge script script/DeployProject30.s.sol:DeployProject30 --rpc-url mainnet --broadcast --verify
 */
contract DeployProject30 is Script {
    function run() external {
        // Get private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying OnChain SVG NFT...");
        console.log("Deployer:", deployer);
        console.log("Deployer balance:", deployer.balance);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the NFT contract
        Project30Solution nft = new Project30Solution();

        console.log("OnChain SVG NFT deployed at:", address(nft));
        console.log("Name:", nft.name());
        console.log("Symbol:", nft.symbol());
        console.log("Max Supply:", nft.maxSupply());

        // Optionally mint a test token to verify deployment
        // Uncomment the following lines to mint on deployment:
        /*
        console.log("\nMinting test token...");
        nft.mint();
        console.log("Test token minted to:", deployer);
        console.log("Token 0 owner:", nft.ownerOf(0));

        // Display token URI (can be pasted into browser)
        string memory uri = nft.tokenURI(0);
        console.log("\nToken 0 URI (paste in browser to view):");
        console.log(uri);
        */

        vm.stopBroadcast();

        console.log("\nDeployment complete!");
        console.log("\nNext steps:");
        console.log("1. Mint tokens: nft.mint()");
        console.log("2. View metadata: nft.tokenURI(tokenId)");
        console.log("3. Copy the data URI and paste into browser address bar");
        console.log("4. See your fully on-chain NFT!");
    }
}

/**
 * @title DeployAndMint
 * @notice Deployment script that also mints several test tokens
 * @dev Use this to deploy and immediately create sample NFTs
 */
contract DeployAndMint is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying OnChain SVG NFT with test mints...");
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy
        Project30Solution nft = new Project30Solution();
        console.log("Contract deployed at:", address(nft));

        // Mint several test tokens
        uint256 mintCount = 5;
        console.log("\nMinting", mintCount, "test tokens...");

        for (uint256 i = 0; i < mintCount; i++) {
            nft.mint();
            console.log("Minted token", i);
        }

        console.log("\nMinted tokens:", nft.balanceOf(deployer));

        // Display first token's metadata
        console.log("\n=== Token 0 Metadata ===");
        string memory uri0 = nft.tokenURI(0);
        console.log("Token URI (paste in browser):");
        console.log(uri0);

        console.log("\n=== Token 0 Attributes ===");
        console.log("Color:", nft.getColorName(0));
        console.log("Shape:", nft.getShape(0));
        console.log("Pattern:", nft.getPattern(0));
        console.log("Complexity:", nft.getComplexity(0));

        vm.stopBroadcast();

        console.log("\nDeployment and minting complete!");
    }
}

/**
 * @title DeployAndDemo
 * @notice Deployment script with comprehensive demo
 * @dev Deploys and demonstrates all functionality
 */
contract DeployAndDemo is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== OnChain SVG NFT - Complete Demo ===\n");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy
        Project30Solution nft = new Project30Solution();
        console.log("Contract deployed at:", address(nft));
        console.log("Max Supply:", nft.maxSupply());

        // Mint a few tokens
        console.log("\n=== Minting Tokens ===");
        for (uint256 i = 0; i < 3; i++) {
            nft.mint();
        }
        console.log("Minted 3 tokens to:", deployer);

        // Show attributes for each token
        console.log("\n=== Token Attributes ===");
        for (uint256 i = 0; i < 3; i++) {
            console.log("\nToken", i, ":");
            console.log("  Color:", nft.getColorName(i));
            console.log("  Shape:", nft.getShape(i));
            console.log("  Pattern:", nft.getPattern(i));
            console.log("  Complexity:", nft.getComplexity(i));
        }

        // Show SVG for token 0
        console.log("\n=== Token 0 SVG (first 500 chars) ===");
        string memory svg = nft.generateSVG(0);
        // Note: console.log has length limits, so we only show this in actual deployment
        console.log("SVG generated (length:", bytes(svg).length, "bytes)");

        // Show full token URI for token 0
        console.log("\n=== Token 0 Complete Metadata ===");
        string memory uri = nft.tokenURI(0);
        console.log("Paste this data URI into your browser to see the NFT:");
        console.log(uri);

        vm.stopBroadcast();

        console.log("\n=== Demo Complete ===");
        console.log("\nHow to view your NFT:");
        console.log("1. Copy the data URI above");
        console.log("2. Paste into browser address bar");
        console.log("3. Press Enter");
        console.log("4. See your on-chain NFT artwork!");
        console.log("\nHow to view on OpenSea (testnets):");
        console.log("1. Go to OpenSea testnet");
        console.log("2. Search for contract:", address(nft));
        console.log("3. View your NFTs with full metadata!");
    }
}

/*
 * DEPLOYMENT NOTES:
 *
 * 1. ENVIRONMENT SETUP:
 *    - Set PRIVATE_KEY in .env file
 *    - Ensure deployer has enough ETH for gas
 *    - For testnet: Get faucet ETH first
 *
 * 2. GAS COSTS:
 *    - Deployment: ~2-3M gas
 *    - Minting: ~200-500k gas per token (higher than off-chain)
 *    - This is expected for on-chain metadata/SVG
 *
 * 3. VERIFICATION:
 *    - Add --verify flag to verify on Etherscan
 *    - Requires ETHERSCAN_API_KEY in .env
 *    - Verification helps with contract interaction
 *
 * 4. TESTING DEPLOYMENT:
 *    - Always test on local/testnet first
 *    - Verify tokenURI output in browser
 *    - Check SVG renders correctly
 *    - Validate JSON structure
 *
 * 5. POST-DEPLOYMENT:
 *    - Save contract address
 *    - Mint test tokens
 *    - View on OpenSea/marketplace
 *    - Share data URIs to showcase
 *
 * 6. MAINNET CONSIDERATIONS:
 *    - Double-check all parameters
 *    - Audit code thoroughly
 *    - Consider max supply carefully
 *    - Account for high minting costs
 *    - Test extensively on testnet first
 *
 * 7. VIEWING METADATA:
 *    - Copy tokenURI output
 *    - Paste in browser (Chrome/Firefox/Safari)
 *    - Browser will decode base64 and show JSON
 *    - Click image data URI to see SVG
 *    - Alternatively use online base64 decoder
 *
 * 8. TROUBLESHOOTING:
 *    - If SVG doesn't render: check XML syntax
 *    - If JSON invalid: use JSON validator
 *    - If gas too high: optimize string operations
 *    - If base64 broken: verify encoding logic
 */
