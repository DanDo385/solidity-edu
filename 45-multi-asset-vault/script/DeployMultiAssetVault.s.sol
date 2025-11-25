// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/solution/MultiAssetVaultSolution.sol";

/**
 * @title Deploy Multi-Asset Vault
 * @notice Deployment script for the Multi-Asset Vault project
 *
 * Usage:
 *   forge script script/DeployMultiAssetVault.s.sol:DeployMultiAssetVault --rpc-url <RPC_URL> --broadcast --verify
 *
 * Local testing:
 *   forge script script/DeployMultiAssetVault.s.sol:DeployMultiAssetVault --fork-url <RPC_URL>
 */
contract DeployMultiAssetVault is Script {
    // Configuration for different networks
    struct NetworkConfig {
        address baseAsset; // USDC or other stablecoin
        address dexRouter; // Uniswap V2 Router or similar
        uint256 rebalanceThreshold; // Basis points
    }

    // Network configurations
    mapping(uint256 => NetworkConfig) public configs;

    function setUp() public {
        // Ethereum Mainnet
        configs[1] = NetworkConfig({
            baseAsset: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, // USDC
            dexRouter: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, // Uniswap V2 Router
            rebalanceThreshold: 500 // 5%
        });

        // Polygon
        configs[137] = NetworkConfig({
            baseAsset: 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174, // USDC
            dexRouter: 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff, // QuickSwap Router
            rebalanceThreshold: 500 // 5%
        });

        // Arbitrum
        configs[42161] = NetworkConfig({
            baseAsset: 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8, // USDC
            dexRouter: 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506, // SushiSwap Router
            rebalanceThreshold: 500 // 5%
        });

        // Optimism
        configs[10] = NetworkConfig({
            baseAsset: 0x7F5c764cBc14f9669B88837ca1490cCa17c31607, // USDC
            dexRouter: 0x9c12939390052919aF3155f41Bf4160Fd3666A6f, // Velodrome Router
            rebalanceThreshold: 500 // 5%
        });

        // BSC
        configs[56] = NetworkConfig({
            baseAsset: 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d, // USDC
            dexRouter: 0x10ED43C718714eb63d5aA57B78B54704E256024E, // PancakeSwap Router
            rebalanceThreshold: 500 // 5%
        });

        // Sepolia Testnet (for testing)
        configs[11155111] = NetworkConfig({
            baseAsset: address(0), // Deploy mock USDC
            dexRouter: address(0), // Deploy mock DEX
            rebalanceThreshold: 500 // 5%
        });
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying Multi-Asset Vault");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);

        NetworkConfig memory config = configs[block.chainid];

        require(config.baseAsset != address(0), "Unsupported network");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy vault
        MultiAssetVaultSolution vault = new MultiAssetVaultSolution(
            "DeFi Index Fund", // Name
            "DIF", // Symbol
            config.baseAsset,
            config.dexRouter,
            config.rebalanceThreshold
        );

        console.log("Multi-Asset Vault deployed at:", address(vault));

        // Optional: Set up initial basket configuration
        // This would be done based on the specific index strategy
        // Example: DeFi Blue Chip Index
        setupDeFiBlueChipIndex(vault);

        vm.stopBroadcast();

        // Log deployment info
        logDeployment(vault, config);
    }

    function setupDeFiBlueChipIndex(MultiAssetVaultSolution vault) internal {
        console.log("\nSetting up DeFi Blue Chip Index basket...");

        // Example configuration for mainnet
        if (block.chainid == 1) {
            // Add UNI (30%)
            vault.addAsset(
                0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984, // UNI token
                3000, // 30%
                0x553303d460EE0afB37EdFf9bE42922D8FF63220e // Chainlink UNI/USD oracle
            );

            // Add AAVE (25%)
            vault.addAsset(
                0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9, // AAVE token
                2500, // 25%
                0x547a514d5e3769680Ce22B2361c10Ea13619e8a9 // Chainlink AAVE/USD oracle
            );

            // Add CRV (25%)
            vault.addAsset(
                0xD533a949740bb3306d119CC777fa900bA034cd52, // CRV token
                2500, // 25%
                0xCd627aA160A6fA45Eb793D19Ef54f5062F20f33f // Chainlink CRV/USD oracle
            );

            // Add COMP (20%)
            vault.addAsset(
                0xc00e94Cb662C3520282E6f5717214004A7f26888, // COMP token
                2000, // 20%
                0xdbd020CAeF83eFd542f4De03e3cF0C28A4428bd5 // Chainlink COMP/USD oracle
            );

            console.log("Added 4 assets to basket:");
            console.log("- UNI: 30%");
            console.log("- AAVE: 25%");
            console.log("- CRV: 25%");
            console.log("- COMP: 20%");
        } else {
            console.log("Skipping asset setup for non-mainnet deployment");
            console.log("Configure assets manually after deployment");
        }
    }

    function logDeployment(MultiAssetVaultSolution vault, NetworkConfig memory config) internal view {
        console.log("\n=== Deployment Summary ===");
        console.log("Vault Address:", address(vault));
        console.log("Vault Name:", vault.name());
        console.log("Vault Symbol:", vault.symbol());
        console.log("Base Asset:", config.baseAsset);
        console.log("DEX Router:", config.dexRouter);
        console.log("Rebalance Threshold:", config.rebalanceThreshold, "bps");
        console.log("Asset Count:", vault.getAssetCount());
        console.log("Total Target Weight:", vault.getTotalWeight(), "bps");
        console.log("\n=== Configuration ===");
        console.log("Deposit Fee:", vault.depositFee(), "bps");
        console.log("Withdraw Fee:", vault.withdrawFee(), "bps");
        console.log("Min Rebalance Interval:", vault.minRebalanceInterval(), "seconds");
        console.log("========================\n");
    }

    // Helper function to deploy on local testnet with mocks
    function deployLocal() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy mock USDC
        MockERC20 usdc = new MockERC20("USD Coin", "USDC", 6);
        console.log("Mock USDC deployed at:", address(usdc));

        // Deploy mock DEX router
        MockDEXRouter dex = new MockDEXRouter();
        console.log("Mock DEX Router deployed at:", address(dex));

        // Deploy vault
        MultiAssetVaultSolution vault = new MultiAssetVaultSolution(
            "Test Index Fund",
            "TIF",
            address(usdc),
            address(dex),
            500 // 5% threshold
        );

        console.log("Multi-Asset Vault deployed at:", address(vault));

        // Deploy mock tokens and oracles
        MockERC20 tokenA = new MockERC20("Token A", "TKNA", 18);
        MockERC20 tokenB = new MockERC20("Token B", "TKNB", 18);
        MockERC20 tokenC = new MockERC20("Token C", "TKNC", 18);

        MockPriceOracle oracleUSDC = new MockPriceOracle(1e8, 8); // $1
        MockPriceOracle oracleA = new MockPriceOracle(10e8, 8); // $10
        MockPriceOracle oracleB = new MockPriceOracle(5e8, 8); // $5
        MockPriceOracle oracleC = new MockPriceOracle(20e8, 8); // $20

        // Add assets to vault
        vault.addAsset(address(usdc), 2500, address(oracleUSDC)); // 25%
        vault.addAsset(address(tokenA), 2500, address(oracleA)); // 25%
        vault.addAsset(address(tokenB), 2500, address(oracleB)); // 25%
        vault.addAsset(address(tokenC), 2500, address(oracleC)); // 25%

        console.log("\nLocal deployment complete!");
        console.log("USDC:", address(usdc));
        console.log("Token A:", address(tokenA));
        console.log("Token B:", address(tokenB));
        console.log("Token C:", address(tokenC));
        console.log("Vault:", address(vault));

        vm.stopBroadcast();
    }
}

// Mock contracts for local testing
contract MockERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
}

contract MockPriceOracle {
    int256 private _price;
    uint8 private _decimals;

    constructor(int256 initialPrice, uint8 decimals_) {
        _price = initialPrice;
        _decimals = decimals_;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (1, _price, block.timestamp, block.timestamp, 1);
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function setPrice(int256 newPrice) external {
        _price = newPrice;
    }
}

contract MockDEXRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        require(deadline >= block.timestamp, "Expired");

        // Simplified: transfer in and mint out (1% slippage)
        MockERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        uint256 amountOut = (amountIn * 99) / 100;
        MockERC20(path[1]).mint(to, amountOut);

        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;
    }

    function getAmountsOut(uint256 amountIn, address[] calldata path) external pure returns (uint256[] memory amounts) {
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        amounts[1] = (amountIn * 99) / 100; // 1% slippage
    }
}
