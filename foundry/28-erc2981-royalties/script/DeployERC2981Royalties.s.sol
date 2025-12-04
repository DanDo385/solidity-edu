// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/ERC2981Royalties.sol";
import "../src/solution/ERC2981RoyaltiesSolution.sol";

/**
 * @title DeployERC2981Royalties
 * @notice Deployment script for ERC-2981 Royalties NFT
 * @dev Deploys NFT contract with royalty configuration
 *
 * Usage:
 * 1. Deploy skeleton (student version):
 *    forge script script/DeployERC2981Royalties.s.sol:DeployERC2981Royalties --rpc-url <RPC_URL> --broadcast
 *
 * 2. Deploy solution:
 *    forge script script/DeployERC2981Royalties.s.sol:DeployERC2981RoyaltiesSolution --rpc-url <RPC_URL> --broadcast
 *
 * 3. Deploy with custom parameters:
 *    forge script script/DeployERC2981Royalties.s.sol:DeployERC2981RoyaltiesCustom --rpc-url <RPC_URL> --broadcast
 *
 * 4. Verify contract:
 *    forge verify-contract <CONTRACT_ADDRESS> ERC2981RoyaltiesSolution --chain <CHAIN_ID>
 */
contract DeployERC2981Royalties is Script {
    function run() external returns (ERC2981Royalties) {
        // Load deployer private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Default royalty configuration
        address royaltyReceiver = deployer; // Deployer receives royalties
        uint96 royaltyFee = 500; // 5% royalty

        console.log("Deploying ERC2981Royalties (Skeleton)...");
        console.log("Deployer:", deployer);
        console.log("Royalty Receiver:", royaltyReceiver);
        console.log("Royalty Fee:", royaltyFee, "basis points (", royaltyFee / 100, "%)");

        vm.startBroadcast(deployerPrivateKey);

        ERC2981Royalties nft = new ERC2981Royalties(
            "RoyaltyNFT",
            "RNFT",
            royaltyReceiver,
            royaltyFee
        );

        vm.stopBroadcast();

        console.log("ERC2981Royalties deployed at:", address(nft));
        console.log("==============================================");
        console.log("NEXT STEPS:");
        console.log("1. Verify contract on block explorer");
        console.log("2. Test minting: cast send", address(nft), '"mint(address)" <RECIPIENT>');
        console.log("3. Check royalty info: cast call", address(nft), '"royaltyInfo(uint256,uint256)" <TOKEN_ID> <SALE_PRICE>');
        console.log("4. Update royalty: cast send", address(nft), '"setDefaultRoyalty(address,uint96)" <RECEIVER> <FEE>');
        console.log("==============================================");

        return nft;
    }
}

/**
 * @title DeployERC2981RoyaltiesSolution
 * @notice Deployment script for complete solution
 */
contract DeployERC2981RoyaltiesSolution is Script {
    function run() external returns (ERC2981RoyaltiesSolution) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Default royalty configuration
        address royaltyReceiver = deployer;
        uint96 royaltyFee = 500; // 5%

        console.log("Deploying ERC2981RoyaltiesSolution...");
        console.log("Deployer:", deployer);
        console.log("Royalty Receiver:", royaltyReceiver);
        console.log("Royalty Fee:", royaltyFee, "basis points");

        vm.startBroadcast(deployerPrivateKey);

        ERC2981RoyaltiesSolution nft = new ERC2981RoyaltiesSolution(
            "RoyaltyNFT",
            "RNFT",
            royaltyReceiver,
            royaltyFee
        );

        vm.stopBroadcast();

        console.log("ERC2981RoyaltiesSolution deployed at:", address(nft));
        logDeploymentInfo(address(nft), royaltyReceiver, royaltyFee);

        return nft;
    }

    function logDeploymentInfo(address nftAddress, address receiver, uint96 fee) internal view {
        console.log("==============================================");
        console.log("DEPLOYMENT SUMMARY");
        console.log("==============================================");
        console.log("Contract:", nftAddress);
        console.log("Royalty Receiver:", receiver);
        console.log("Royalty Fee:", fee, "basis points (", fee / 100, "%)");
        console.log("==============================================");
        console.log("INTERFACE SUPPORT:");
        console.log("ERC721: Yes");
        console.log("ERC2981: Yes");
        console.log("ERC2981 Interface ID: 0x2a55205a");
        console.log("==============================================");
        console.log("EXAMPLE INTERACTIONS:");
        console.log("");
        console.log("# Mint NFT");
        console.log("cast send", nftAddress, '"mint(address)" <RECIPIENT> --private-key <KEY>');
        console.log("");
        console.log("# Check royalty info (tokenId=0, salePrice=10 ETH)");
        console.log("cast call", nftAddress, '"royaltyInfo(uint256,uint256)" 0 10000000000000000000');
        console.log("");
        console.log("# Set default royalty (7.5%)");
        console.log("cast send", nftAddress, '"setDefaultRoyalty(address,uint96)" <RECEIVER> 750 --private-key <KEY>');
        console.log("");
        console.log("# Set token-specific royalty");
        console.log("cast send", nftAddress, '"setTokenRoyalty(uint256,address,uint96)" <TOKEN_ID> <RECEIVER> <FEE> --private-key <KEY>');
        console.log("");
        console.log("# Check ERC2981 support");
        console.log("cast call", nftAddress, '"supportsInterface(bytes4)" 0x2a55205a');
        console.log("==============================================");
    }
}

/**
 * @title DeployERC2981RoyaltiesCustom
 * @notice Deployment script with custom parameters from environment
 * @dev Reads configuration from environment variables
 *
 * Environment variables:
 * - PRIVATE_KEY: Deployer private key
 * - NFT_NAME: NFT collection name (default: "RoyaltyNFT")
 * - NFT_SYMBOL: NFT symbol (default: "RNFT")
 * - ROYALTY_RECEIVER: Address to receive royalties (default: deployer)
 * - ROYALTY_FEE: Royalty fee in basis points (default: 500)
 */
contract DeployERC2981RoyaltiesCustom is Script {
    function run() external returns (ERC2981RoyaltiesSolution) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Read custom parameters from environment or use defaults
        string memory nftName = vm.envOr("NFT_NAME", string("RoyaltyNFT"));
        string memory nftSymbol = vm.envOr("NFT_SYMBOL", string("RNFT"));
        address royaltyReceiver = vm.envOr("ROYALTY_RECEIVER", deployer);
        uint96 royaltyFee = uint96(vm.envOr("ROYALTY_FEE", uint256(500)));

        // Validate parameters
        require(royaltyReceiver != address(0), "Invalid royalty receiver");
        require(royaltyFee <= 1000, "Royalty fee too high (max 10%)");
        require(bytes(nftName).length > 0, "NFT name required");
        require(bytes(nftSymbol).length > 0, "NFT symbol required");

        console.log("Deploying ERC2981RoyaltiesSolution with custom parameters...");
        console.log("==============================================");
        console.log("CONFIGURATION:");
        console.log("Deployer:", deployer);
        console.log("NFT Name:", nftName);
        console.log("NFT Symbol:", nftSymbol);
        console.log("Royalty Receiver:", royaltyReceiver);
        console.log("Royalty Fee:", royaltyFee, "basis points (", royaltyFee / 100, "%)");
        console.log("==============================================");

        vm.startBroadcast(deployerPrivateKey);

        ERC2981RoyaltiesSolution nft = new ERC2981RoyaltiesSolution(
            nftName,
            nftSymbol,
            royaltyReceiver,
            royaltyFee
        );

        vm.stopBroadcast();

        console.log("ERC2981RoyaltiesSolution deployed at:", address(nft));
        console.log("==============================================");

        return nft;
    }
}

/**
 * @title DeployERC2981RoyaltiesWithMinting
 * @notice Deployment script that also mints initial NFTs
 * @dev Deploys contract and mints specified number of NFTs
 */
contract DeployERC2981RoyaltiesWithMinting is Script {
    function run() external returns (ERC2981RoyaltiesSolution) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        address royaltyReceiver = deployer;
        uint96 royaltyFee = 500;
        uint256 initialMintCount = vm.envOr("INITIAL_MINT_COUNT", uint256(0));

        console.log("Deploying ERC2981RoyaltiesSolution with initial minting...");
        console.log("Initial mint count:", initialMintCount);

        vm.startBroadcast(deployerPrivateKey);

        ERC2981RoyaltiesSolution nft = new ERC2981RoyaltiesSolution(
            "RoyaltyNFT",
            "RNFT",
            royaltyReceiver,
            royaltyFee
        );

        // Mint initial NFTs
        if (initialMintCount > 0) {
            console.log("Minting", initialMintCount, "initial NFTs...");
            for (uint256 i = 0; i < initialMintCount; i++) {
                uint256 tokenId = nft.mint(deployer);
                console.log("Minted token", tokenId);
            }
        }

        vm.stopBroadcast();

        console.log("==============================================");
        console.log("Deployment complete!");
        console.log("Contract:", address(nft));
        console.log("Total Supply:", nft.totalSupply());
        console.log("==============================================");

        return nft;
    }
}

/**
 * @title DeployERC2981RoyaltiesMultiReceiver
 * @notice Example deployment with multiple royalty receivers via per-token royalties
 * @dev Demonstrates setting different royalties for different tokens
 */
contract DeployERC2981RoyaltiesMultiReceiver is Script {
    function run() external returns (ERC2981RoyaltiesSolution) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying ERC2981RoyaltiesSolution with multi-receiver setup...");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy with deployer as default receiver
        ERC2981RoyaltiesSolution nft = new ERC2981RoyaltiesSolution(
            "CollabNFT",
            "CNFT",
            deployer,
            500 // 5% default
        );

        // Mint tokens for different artists
        uint256 token0 = nft.mint(deployer); // Artist 1
        uint256 token1 = nft.mint(deployer); // Artist 2
        uint256 token2 = nft.mint(deployer); // Artist 3

        // Set different royalties for each (using deployer as example)
        // In production, you'd use actual artist addresses
        nft.setTokenRoyalty(token0, deployer, 500);  // 5%
        nft.setTokenRoyalty(token1, deployer, 750);  // 7.5%
        nft.setTokenRoyalty(token2, deployer, 1000); // 10%

        vm.stopBroadcast();

        console.log("==============================================");
        console.log("Multi-receiver setup complete!");
        console.log("Contract:", address(nft));
        console.log("Token 0: 5% royalty");
        console.log("Token 1: 7.5% royalty");
        console.log("Token 2: 10% royalty");
        console.log("==============================================");

        return nft;
    }
}

/*
DEPLOYMENT EXAMPLES:
====================

1. BASIC DEPLOYMENT (Testnet):
   forge script script/DeployERC2981Royalties.s.sol:DeployERC2981RoyaltiesSolution \
       --rpc-url $SEPOLIA_RPC_URL \
       --broadcast \
       --verify

2. CUSTOM CONFIGURATION:
   NFT_NAME="MyArtNFT" \
   NFT_SYMBOL="MART" \
   ROYALTY_FEE=750 \
   forge script script/DeployERC2981Royalties.s.sol:DeployERC2981RoyaltiesCustom \
       --rpc-url $SEPOLIA_RPC_URL \
       --broadcast

3. WITH INITIAL MINTING:
   INITIAL_MINT_COUNT=10 \
   forge script script/DeployERC2981Royalties.s.sol:DeployERC2981RoyaltiesWithMinting \
       --rpc-url $SEPOLIA_RPC_URL \
       --broadcast

4. DRY RUN (No broadcast):
   forge script script/DeployERC2981Royalties.s.sol:DeployERC2981RoyaltiesSolution \
       --rpc-url $SEPOLIA_RPC_URL

5. MAINNET DEPLOYMENT (Use with caution):
   forge script script/DeployERC2981Royalties.s.sol:DeployERC2981RoyaltiesSolution \
       --rpc-url $MAINNET_RPC_URL \
       --broadcast \
       --verify \
       --slow

VERIFICATION:
=============

After deployment, verify the contract:

forge verify-contract \
    <CONTRACT_ADDRESS> \
    src/solution/ERC2981RoyaltiesSolution.sol:ERC2981RoyaltiesSolution \
    --chain-id <CHAIN_ID> \
    --constructor-args $(cast abi-encode "constructor(string,string,address,uint96)" "RoyaltyNFT" "RNFT" <RECEIVER> 500)

POST-DEPLOYMENT TESTING:
========================

1. Check interface support:
   cast call <CONTRACT> "supportsInterface(bytes4)" 0x2a55205a

2. Get royalty info:
   cast call <CONTRACT> "royaltyInfo(uint256,uint256)" 0 10000000000000000000

3. Mint NFT:
   cast send <CONTRACT> "mint(address)" <RECIPIENT> --private-key <KEY>

4. Update royalty:
   cast send <CONTRACT> "setDefaultRoyalty(address,uint96)" <RECEIVER> 750 --private-key <KEY>

MARKETPLACE INTEGRATION VERIFICATION:
====================================

Test on marketplaces that support ERC-2981:
- OpenSea: Check collection royalty settings
- LooksRare: Verify royalty info displays
- Rarible: Confirm royalty enforcement

Note: Not all marketplaces enforce royalties!
*/
