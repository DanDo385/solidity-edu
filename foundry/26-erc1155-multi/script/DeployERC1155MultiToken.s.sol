// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/solution/ERC1155MultiTokenSolution.sol";

/**
 * @title Deploy Script for Project 26
 * @notice Deploys and initializes the GameItems ERC-1155 contract
 *
 * Usage:
 * forge script script/DeployERC1155MultiToken.s.sol:DeployERC1155MultiToken --rpc-url <RPC_URL> --broadcast --verify
 *
 * Local deployment:
 * forge script script/DeployERC1155MultiToken.s.sol:DeployERC1155MultiToken --fork-url http://localhost:8545 --broadcast
 */
contract DeployERC1155MultiToken is Script {
    // Configuration
    string constant BASE_URI = "https://game.com/api/item/{id}.json";

    // Game token IDs for initial setup
    uint256 constant GOLD = 0;
    uint256 constant SILVER = 1;
    uint256 constant HEALTH_POTION = 1000;
    uint256 constant MANA_POTION = 1001;

    function run() external {
        // Get deployer private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying GameItems ERC-1155 contract...");
        console.log("Deployer address:", deployer);
        console.log("Base URI:", BASE_URI);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the contract
        GameItems gameItems = new GameItems(BASE_URI);

        console.log("GameItems deployed at:", address(gameItems));
        console.log("Owner:", gameItems.owner());

        // Optional: Mint initial tokens for demonstration
        if (vm.envOr("MINT_INITIAL_TOKENS", false)) {
            console.log("\nMinting initial tokens...");

            // Mint currencies
            gameItems.mint(deployer, GOLD, 10000, "");
            console.log("Minted 10000 GOLD to deployer");

            gameItems.mint(deployer, SILVER, 5000, "");
            console.log("Minted 5000 SILVER to deployer");

            // Mint consumables
            gameItems.mint(deployer, HEALTH_POTION, 100, "");
            console.log("Minted 100 HEALTH_POTION to deployer");

            gameItems.mint(deployer, MANA_POTION, 50, "");
            console.log("Minted 50 MANA_POTION to deployer");

            // Mint unique equipment NFTs
            uint256[] memory equipmentIds = new uint256[](5);
            equipmentIds[0] = 10000; // Legendary Sword
            equipmentIds[1] = 10001; // Epic Shield
            equipmentIds[2] = 10002; // Rare Helmet
            equipmentIds[3] = 10003; // Uncommon Boots
            equipmentIds[4] = 10004; // Common Gloves

            for (uint256 i = 0; i < equipmentIds.length; i++) {
                gameItems.mintEquipment(deployer, equipmentIds[i]);
                console.log("Minted equipment NFT with ID:", equipmentIds[i]);
            }
        }

        vm.stopBroadcast();

        // Log deployment summary
        console.log("\n=== Deployment Summary ===");
        console.log("GameItems Contract:", address(gameItems));
        console.log("Owner:", gameItems.owner());
        console.log("URI Template:", gameItems.uri(0));
        console.log("\nToken Constants:");
        console.log("GOLD (fungible):", GOLD);
        console.log("SILVER (fungible):", SILVER);
        console.log("HEALTH_POTION (fungible):", HEALTH_POTION);
        console.log("MANA_POTION (fungible):", MANA_POTION);
        console.log("Equipment NFTs start at: 10000");

        // Log supported interfaces
        console.log("\nSupported Interfaces:");
        console.log("ERC165:", gameItems.supportsInterface(0x01ffc9a7));
        console.log("ERC1155:", gameItems.supportsInterface(0xd9b67a26));
        console.log("ERC1155MetadataURI:", gameItems.supportsInterface(0x0e89341c));

        // Save deployment info
        saveDeploymentInfo(address(gameItems), deployer);
    }

    /**
     * @dev Saves deployment information to a file
     */
    function saveDeploymentInfo(address gameItemsAddress, address deployerAddress) internal {
        string memory json = "deploymentInfo";

        vm.serializeAddress(json, "gameItems", gameItemsAddress);
        vm.serializeAddress(json, "deployer", deployerAddress);
        vm.serializeString(json, "baseURI", BASE_URI);
        vm.serializeUint(json, "timestamp", block.timestamp);
        string memory finalJson = vm.serializeUint(json, "blockNumber", block.number);

        string memory deploymentFile = string.concat(
            vm.projectRoot(),
            "/deployments/",
            vm.toString(block.chainid),
            "-latest.json"
        );

        vm.writeJson(finalJson, deploymentFile);
        console.log("\nDeployment info saved to:", deploymentFile);
    }
}

/**
 * @title Demo Script for Project 26
 * @notice Demonstrates ERC-1155 functionality with gaming scenarios
 *
 * Usage:
 * forge script script/DeployERC1155MultiToken.s.sol:DemoERC1155MultiToken --rpc-url <RPC_URL> --broadcast
 */
contract DemoERC1155MultiToken is Script {
    function run() external {
        // Load deployed contract address
        address gameItemsAddress = vm.envAddress("GAME_ITEMS_ADDRESS");
        GameItems gameItems = GameItems(gameItemsAddress);

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== ERC-1155 Gaming Demo ===");
        console.log("GameItems contract:", gameItemsAddress);
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // Scenario 1: Player receives starter pack
        console.log("\n--- Scenario 1: Starter Pack ---");
        address player1 = address(0x1);

        uint256[] memory starterIds = new uint256[](4);
        starterIds[0] = gameItems.GOLD();
        starterIds[1] = gameItems.SILVER();
        starterIds[2] = gameItems.HEALTH_POTION();
        starterIds[3] = gameItems.MANA_POTION();

        uint256[] memory starterAmounts = new uint256[](4);
        starterAmounts[0] = 100; // 100 gold
        starterAmounts[1] = 50; // 50 silver
        starterAmounts[2] = 10; // 10 health potions
        starterAmounts[3] = 5; // 5 mana potions

        gameItems.mintBatch(player1, starterIds, starterAmounts, "");
        console.log("Minted starter pack to player1");
        console.log("Player1 Gold:", gameItems.balanceOf(player1, gameItems.GOLD()));
        console.log("Player1 Health Potions:", gameItems.balanceOf(player1, gameItems.HEALTH_POTION()));

        // Scenario 2: Player finds legendary equipment
        console.log("\n--- Scenario 2: Legendary Drop ---");
        uint256 legendarySword = 10000;
        gameItems.mintEquipment(player1, legendarySword);
        console.log("Minted Legendary Sword (ID:", legendarySword, ") to player1");
        console.log("Player1 owns unique sword:", gameItems.balanceOf(player1, legendarySword) == 1);

        // Scenario 3: Player-to-player trade
        console.log("\n--- Scenario 3: Player Trade ---");
        address player2 = address(0x2);

        // Give player2 some items first
        gameItems.mint(player2, gameItems.GOLD(), 200, "");
        gameItems.mintEquipment(player2, 10001); // Different sword

        console.log("Before trade:");
        console.log("Player1 Gold:", gameItems.balanceOf(player1, gameItems.GOLD()));
        console.log("Player2 Gold:", gameItems.balanceOf(player2, gameItems.GOLD()));

        // Player1 trades 50 gold to player2
        // Note: In real scenario, player1 would execute this
        uint256[] memory tradeIds = new uint256[](1);
        tradeIds[0] = gameItems.GOLD();
        uint256[] memory tradeAmounts = new uint256[](1);
        tradeAmounts[0] = 50;

        // Simulating player1 transaction
        vm.stopBroadcast();
        vm.startBroadcast(deployerPrivateKey); // In reality, this would be player1's key
        // For demo, we need to transfer from deployer or grant approval
        gameItems.mint(deployer, gameItems.GOLD(), 1000, "");
        gameItems.safeTransferFrom(deployer, player2, gameItems.GOLD(), 50, "");

        console.log("After trade:");
        console.log("Player2 Gold:", gameItems.balanceOf(player2, gameItems.GOLD()));

        // Scenario 4: Batch operations (gas efficiency demo)
        console.log("\n--- Scenario 4: Batch Operations ---");
        address player3 = address(0x3);

        uint256[] memory rewardIds = new uint256[](3);
        rewardIds[0] = gameItems.GOLD();
        rewardIds[1] = gameItems.HEALTH_POTION();
        rewardIds[2] = 10005; // New equipment

        uint256[] memory rewardAmounts = new uint256[](3);
        rewardAmounts[0] = 500;
        rewardAmounts[1] = 20;
        rewardAmounts[2] = 1;

        uint256 gasBefore = gasleft();
        gameItems.mintBatch(player3, rewardIds, rewardAmounts, "");
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Batch minted quest rewards to player3");
        console.log("Gas used for batch mint:", gasUsed);
        console.log("Player3 total items:", rewardIds.length);

        vm.stopBroadcast();

        console.log("\n=== Demo Complete ===");
        console.log("Total supply of GOLD:", gameItems.totalSupply(gameItems.GOLD()));
        console.log("Total unique equipment minted:", 6); // 10000-10005
    }
}

/**
 * @title Verification Script for Project 26
 * @notice Verifies deployed contract and runs basic checks
 *
 * Usage:
 * forge script script/DeployERC1155MultiToken.s.sol:VerifyERC1155MultiToken --rpc-url <RPC_URL>
 */
contract VerifyERC1155MultiToken is Script {
    function run() external view {
        address gameItemsAddress = vm.envAddress("GAME_ITEMS_ADDRESS");
        GameItems gameItems = GameItems(gameItemsAddress);

        console.log("=== Contract Verification ===");
        console.log("Contract address:", gameItemsAddress);
        console.log("Owner:", gameItems.owner());
        console.log("URI template:", gameItems.uri(0));

        // Verify interface support
        console.log("\nInterface Support:");
        require(gameItems.supportsInterface(0x01ffc9a7), "ERC165 not supported");
        console.log("ERC165: PASS");

        require(gameItems.supportsInterface(0xd9b67a26), "ERC1155 not supported");
        console.log("ERC1155: PASS");

        require(gameItems.supportsInterface(0x0e89341c), "ERC1155MetadataURI not supported");
        console.log("ERC1155MetadataURI: PASS");

        // Verify token constants
        console.log("\nToken Constants:");
        console.log("GOLD:", gameItems.GOLD());
        console.log("SILVER:", gameItems.SILVER());
        console.log("HEALTH_POTION:", gameItems.HEALTH_POTION());
        console.log("MANA_POTION:", gameItems.MANA_POTION());

        // Verify helper functions
        console.log("\nHelper Functions:");
        require(gameItems.isFungible(0), "GOLD should be fungible");
        require(gameItems.isFungible(1000), "HEALTH_POTION should be fungible");
        require(!gameItems.isFungible(10000), "Equipment should not be fungible");
        require(gameItems.isNonFungible(10000), "Equipment should be non-fungible");
        console.log("Token type checks: PASS");

        console.log("\n=== All Verifications Passed ===");
    }
}
