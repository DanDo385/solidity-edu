// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/solution/Project49Solution.sol";

/**
 * @title Deploy Leverage Looping Vault
 * @notice Deployment script for leverage vault on various networks
 *
 * Usage:
 * forge script script/DeployProject49.s.sol:DeployProject49 --rpc-url <network> --broadcast --verify
 *
 * Networks:
 * - Ethereum Mainnet: Use Aave V3
 * - Polygon: Use Aave V3
 * - Arbitrum: Use Aave V3
 * - Optimism: Use Aave V3
 * - Base: Use Aave V3
 */
contract DeployProject49 is Script {
    // ============================================
    // Network Configurations
    // ============================================

    struct NetworkConfig {
        address asset;
        address lendingPool;
        address priceOracle;
        uint256 targetLeverage;
        uint256 targetLTV;
        uint256 minHealthFactor;
        string assetName;
    }

    // Aave V3 Pool addresses (same across networks via CREATE2)
    address constant AAVE_V3_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address constant AAVE_V3_ORACLE = 0x54586bE62E3c3580375aE3723C145253060Ca0C2;

    // Asset addresses per network
    // Ethereum Mainnet
    address constant ETH_WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant ETH_WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address constant ETH_USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    // Polygon
    address constant POLYGON_WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address constant POLYGON_WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address constant POLYGON_USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    // Arbitrum
    address constant ARB_WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant ARB_USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Detect network and get config
        NetworkConfig memory config = getNetworkConfig();

        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying Leverage Looping Vault...");
        console.log("Network: Chain ID", block.chainid);
        console.log("Asset:", config.assetName);
        console.log("Target Leverage:", config.targetLeverage / 100, "x");
        console.log("Target LTV:", config.targetLTV / 100, "%");

        LeverageLoopingVaultSolution vault = new LeverageLoopingVaultSolution(
            config.asset,
            config.lendingPool,
            config.priceOracle,
            config.targetLeverage,
            config.targetLTV,
            config.minHealthFactor
        );

        console.log("Vault deployed at:", address(vault));

        // Verify deployment
        require(address(vault.asset()) == config.asset, "Asset mismatch");
        require(address(vault.lendingPool()) == config.lendingPool, "Lending pool mismatch");
        require(vault.targetLeverage() == config.targetLeverage, "Leverage mismatch");

        console.log("Deployment verified successfully!");

        vm.stopBroadcast();

        // Log deployment info
        console.log("\n=== Deployment Summary ===");
        console.log("Vault:", address(vault));
        console.log("Owner:", vault.owner());
        console.log("Asset:", config.assetName, "-", config.asset);
        console.log("Lending Pool:", config.lendingPool);
        console.log("Price Oracle:", config.priceOracle);
        console.log("\n=== Configuration ===");
        console.log("Target Leverage:", config.targetLeverage, "basis points");
        console.log("Target LTV:", config.targetLTV, "basis points");
        console.log("Min Health Factor:", config.minHealthFactor);
        console.log("\n=== Next Steps ===");
        console.log("1. Verify contract on block explorer");
        console.log("2. Test deposit function with small amount");
        console.log("3. Monitor health factor and leverage");
        console.log("4. Set up automated rebalancing if needed");
    }

    function getNetworkConfig() internal view returns (NetworkConfig memory) {
        uint256 chainId = block.chainid;

        // Ethereum Mainnet
        if (chainId == 1) {
            return getEthereumConfig();
        }
        // Polygon
        else if (chainId == 137) {
            return getPolygonConfig();
        }
        // Arbitrum
        else if (chainId == 42161) {
            return getArbitrumConfig();
        }
        // Optimism
        else if (chainId == 10) {
            return getOptimismConfig();
        }
        // Base
        else if (chainId == 8453) {
            return getBaseConfig();
        }
        // Sepolia (testnet)
        else if (chainId == 11155111) {
            return getSepoliaConfig();
        }
        // Local/Anvil
        else {
            return getAnvilConfig();
        }
    }

    function getEthereumConfig() internal pure returns (NetworkConfig memory) {
        return NetworkConfig({
            asset: ETH_WSTETH, // wstETH for better yield
            lendingPool: AAVE_V3_POOL,
            priceOracle: AAVE_V3_ORACLE,
            targetLeverage: 40000, // 4x leverage
            targetLTV: 7500, // 75% LTV
            minHealthFactor: 1.5e18, // 1.5 minimum HF
            assetName: "wstETH"
        });
    }

    function getPolygonConfig() internal pure returns (NetworkConfig memory) {
        return NetworkConfig({
            asset: POLYGON_WMATIC,
            lendingPool: AAVE_V3_POOL,
            priceOracle: AAVE_V3_ORACLE,
            targetLeverage: 40000,
            targetLTV: 7500,
            minHealthFactor: 1.5e18,
            assetName: "WMATIC"
        });
    }

    function getArbitrumConfig() internal pure returns (NetworkConfig memory) {
        return NetworkConfig({
            asset: ARB_WETH,
            lendingPool: AAVE_V3_POOL,
            priceOracle: AAVE_V3_ORACLE,
            targetLeverage: 40000,
            targetLTV: 7500,
            minHealthFactor: 1.5e18,
            assetName: "WETH"
        });
    }

    function getOptimismConfig() internal pure returns (NetworkConfig memory) {
        // Optimism addresses
        return NetworkConfig({
            asset: 0x4200000000000000000000000000000000000006, // WETH
            lendingPool: AAVE_V3_POOL,
            priceOracle: AAVE_V3_ORACLE,
            targetLeverage: 40000,
            targetLTV: 7500,
            minHealthFactor: 1.5e18,
            assetName: "WETH"
        });
    }

    function getBaseConfig() internal pure returns (NetworkConfig memory) {
        // Base addresses
        return NetworkConfig({
            asset: 0x4200000000000000000000000000000000000006, // WETH
            lendingPool: AAVE_V3_POOL,
            priceOracle: AAVE_V3_ORACLE,
            targetLeverage: 40000,
            targetLTV: 7500,
            minHealthFactor: 1.5e18,
            assetName: "WETH"
        });
    }

    function getSepoliaConfig() internal pure returns (NetworkConfig memory) {
        // Sepolia testnet
        return NetworkConfig({
            asset: 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9, // WETH
            lendingPool: 0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951, // Aave V3 Sepolia
            priceOracle: 0x2da88497588bf89281816106C7259e31AF45a663,
            targetLeverage: 30000, // Conservative 3x for testnet
            targetLTV: 6500, // 65% LTV
            minHealthFactor: 1.8e18, // Higher safety margin for testing
            assetName: "WETH"
        });
    }

    function getAnvilConfig() internal pure returns (NetworkConfig memory) {
        // Local testing configuration
        return NetworkConfig({
            asset: address(0), // Must deploy mock
            lendingPool: address(0), // Must deploy mock
            priceOracle: address(0), // Must deploy mock
            targetLeverage: 40000,
            targetLTV: 7500,
            minHealthFactor: 1.5e18,
            assetName: "MOCK"
        });
    }
}

/**
 * @title Deploy with Custom Configuration
 * @notice Alternative deployment script for custom parameters
 */
contract DeployCustomConfig is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Custom parameters (set via environment or hardcode)
        address asset = vm.envAddress("ASSET_ADDRESS");
        address lendingPool = vm.envAddress("LENDING_POOL_ADDRESS");
        address priceOracle = vm.envAddress("PRICE_ORACLE_ADDRESS");
        uint256 targetLeverage = vm.envUint("TARGET_LEVERAGE"); // e.g., 40000 for 4x
        uint256 targetLTV = vm.envUint("TARGET_LTV"); // e.g., 7500 for 75%
        uint256 minHealthFactor = vm.envUint("MIN_HEALTH_FACTOR"); // e.g., 1.5e18

        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying with custom configuration...");

        LeverageLoopingVaultSolution vault = new LeverageLoopingVaultSolution(
            asset,
            lendingPool,
            priceOracle,
            targetLeverage,
            targetLTV,
            minHealthFactor
        );

        console.log("Vault deployed at:", address(vault));

        vm.stopBroadcast();
    }
}

/**
 * @title Deploy Conservative Vault
 * @notice Deploy a more conservative vault with lower leverage
 */
contract DeployConservative is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Conservative settings
        address asset = vm.envAddress("ASSET_ADDRESS");
        address lendingPool = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2; // Aave V3
        address priceOracle = 0x54586bE62E3c3580375aE3723C145253060Ca0C2;

        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying Conservative Leverage Vault...");

        LeverageLoopingVaultSolution vault = new LeverageLoopingVaultSolution(
            asset,
            lendingPool,
            priceOracle,
            20000, // 2x leverage (conservative)
            5000, // 50% LTV (very safe)
            2.0e18 // 2.0 minimum HF (high safety margin)
        );

        console.log("Conservative Vault deployed at:", address(vault));
        console.log("Configuration: 2x leverage, 50% LTV, 2.0 min HF");

        vm.stopBroadcast();
    }
}

/**
 * @title Deploy Aggressive Vault
 * @notice Deploy a more aggressive vault with higher leverage (RISKY!)
 */
contract DeployAggressive is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address asset = vm.envAddress("ASSET_ADDRESS");
        address lendingPool = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
        address priceOracle = 0x54586bE62E3c3580375aE3723C145253060Ca0C2;

        vm.startBroadcast(deployerPrivateKey);

        console.log("WARNING: Deploying Aggressive Leverage Vault!");
        console.log("High risk of liquidation!");

        LeverageLoopingVaultSolution vault = new LeverageLoopingVaultSolution(
            asset,
            lendingPool,
            priceOracle,
            80000, // 8x leverage (aggressive)
            8750, // 87.5% LTV (high risk)
            1.3e18 // 1.3 minimum HF (tight margin)
        );

        console.log("Aggressive Vault deployed at:", address(vault));
        console.log("Configuration: 8x leverage, 87.5% LTV, 1.3 min HF");
        console.log("WARNING: Monitor closely and ensure automated rebalancing!");

        vm.stopBroadcast();
    }
}
