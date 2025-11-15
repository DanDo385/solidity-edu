// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/Project47.sol";
import "../src/solution/Project47Solution.sol";

/**
 * @title DeployProject47
 * @notice Deployment script for Project 47 - Vault Oracle Integration
 *
 * USAGE:
 *forge script script/DeployProject47.s.sol:DeployProject47 --rpc-url <RPC_URL> --broadcast
 *
 * DEPLOYMENT CHECKLIST:
 * 1. ✓ Verify asset token address
 * 2. ✓ Verify Chainlink price feed address
 * 3. ✓ Set appropriate staleness threshold
 * 4. ✓ Set price deviation limits
 * 5. ✓ Configure fallback oracle (if available)
 * 6. ✓ Set price bounds
 * 7. ✓ Test oracle connectivity before production
 */

contract DeployProject47 is Script {
    // ============================================
    // CONFIGURATION
    // ============================================

    // Mainnet Chainlink Price Feeds (examples)
    // ETH/USD: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
    // BTC/USD: 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c
    // USDC/USD: 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6

    // Sepolia Testnet Chainlink Price Feeds
    // ETH/USD: 0x694AA1769357215DE4FAC081bf1f309aDC325306

    // Default configuration (modify as needed)
    struct DeployConfig {
        address asset;              // Token address
        address priceFeed;          // Chainlink price feed
        address fallbackOracle;     // Fallback oracle (optional)
        string name;                // Vault name
        string symbol;              // Vault symbol
        uint256 maxStaleness;       // Max oracle staleness (seconds)
        uint256 maxDeviation;       // Max price deviation (basis points)
        uint256 minPrice;           // Minimum acceptable price
        uint256 maxPrice;           // Maximum acceptable price
    }

    // ============================================
    // DEPLOYMENT FUNCTIONS
    // ============================================

    /**
     * @notice Deploy skeleton version (for learning)
     */
    function deploySkeleton() public returns (Project47) {
        DeployConfig memory config = getConfig();

        vm.startBroadcast();

        Project47 vault = new Project47(
            config.asset,
            config.priceFeed,
            config.name,
            config.symbol
        );

        console.log("Project47 (Skeleton) deployed at:", address(vault));
        console.log("Asset token:", config.asset);
        console.log("Price feed:", config.priceFeed);

        vm.stopBroadcast();

        return vault;
    }

    /**
     * @notice Deploy complete solution
     */
    function deploySolution() public returns (Project47Solution) {
        DeployConfig memory config = getConfig();

        vm.startBroadcast();

        // Deploy vault
        Project47Solution vault = new Project47Solution(
            config.asset,
            config.priceFeed,
            config.name,
            config.symbol
        );

        console.log("====================================");
        console.log("Project47Solution deployed at:", address(vault));
        console.log("====================================");
        console.log("Configuration:");
        console.log("  Asset:", config.asset);
        console.log("  Price Feed:", config.priceFeed);
        console.log("  Name:", config.name);
        console.log("  Symbol:", config.symbol);
        console.log("====================================");

        // Configure vault parameters
        if (config.maxStaleness > 0) {
            vault.updateMaxStaleness(config.maxStaleness);
            console.log("  Max Staleness:", config.maxStaleness, "seconds");
        }

        if (config.maxDeviation > 0) {
            vault.updateMaxDeviation(config.maxDeviation);
            console.log("  Max Deviation:", config.maxDeviation, "basis points");
        }

        if (config.minPrice > 0 && config.maxPrice > 0) {
            vault.updatePriceBounds(config.minPrice, config.maxPrice);
            console.log("  Min Price:", config.minPrice);
            console.log("  Max Price:", config.maxPrice);
        }

        if (config.fallbackOracle != address(0)) {
            vault.updateFallbackOracle(config.fallbackOracle);
            console.log("  Fallback Oracle:", config.fallbackOracle);
        }

        console.log("====================================");

        // Verify oracle is working
        _verifyOracle(vault);

        vm.stopBroadcast();

        return vault;
    }

    /**
     * @notice Get deployment configuration
     * @dev Modify this function for your specific deployment
     */
    function getConfig() public view returns (DeployConfig memory) {
        // Check which network we're on
        uint256 chainId = block.chainid;

        if (chainId == 1) {
            // Ethereum Mainnet
            return getMainnetConfig();
        } else if (chainId == 11155111) {
            // Sepolia Testnet
            return getSepoliaConfig();
        } else if (chainId == 31337) {
            // Local/Anvil
            return getLocalConfig();
        } else {
            // Default configuration
            revert("Unsupported network");
        }
    }

    /**
     * @notice Mainnet configuration
     */
    function getMainnetConfig() public pure returns (DeployConfig memory) {
        return DeployConfig({
            // Example: WETH vault with ETH/USD price feed
            asset: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, // WETH
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419, // ETH/USD
            fallbackOracle: address(0), // Set if you have one
            name: "ETH Oracle Vault",
            symbol: "vETH",
            maxStaleness: 1 hours,
            maxDeviation: 1000, // 10%
            minPrice: 100 * 1e18, // $100
            maxPrice: 100000 * 1e18 // $100,000
        });
    }

    /**
     * @notice Sepolia testnet configuration
     */
    function getSepoliaConfig() public pure returns (DeployConfig memory) {
        return DeployConfig({
            // You'll need to deploy a test token or use existing one
            asset: address(0), // SET YOUR TOKEN ADDRESS
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306, // ETH/USD Sepolia
            fallbackOracle: address(0),
            name: "Test Oracle Vault",
            symbol: "vTEST",
            maxStaleness: 1 hours,
            maxDeviation: 1000,
            minPrice: 100 * 1e18,
            maxPrice: 100000 * 1e18
        });
    }

    /**
     * @notice Local/Anvil configuration
     */
    function getLocalConfig() public pure returns (DeployConfig memory) {
        return DeployConfig({
            // For local testing, you'll deploy mocks
            asset: address(0), // Deploy mock token first
            priceFeed: address(0), // Deploy mock price feed first
            fallbackOracle: address(0),
            name: "Local Oracle Vault",
            symbol: "vLOCAL",
            maxStaleness: 1 hours,
            maxDeviation: 1000,
            minPrice: 1 * 1e18,
            maxPrice: 1000000 * 1e18
        });
    }

    /**
     * @notice Verify oracle is working correctly
     */
    function _verifyOracle(Project47Solution vault) internal view {
        console.log("====================================");
        console.log("Verifying Oracle...");

        try vault.getChainlinkPrice() returns (uint256 price, bool isValid) {
            if (isValid) {
                console.log("  Chainlink Status: WORKING");
                console.log("  Current Price:", price);
            } else {
                console.log("  Chainlink Status: INVALID");
                console.log("  WARNING: Oracle is not returning valid data!");
            }
        } catch {
            console.log("  Chainlink Status: FAILED");
            console.log("  ERROR: Cannot connect to oracle!");
        }

        console.log("====================================");
    }

    /**
     * @notice Main deployment function
     * @dev Called by forge script
     */
    function run() public {
        // Deploy solution by default
        // Change to deploySkeleton() for learning version
        deploySolution();
    }
}

/**
 * @title DeployWithMocks
 * @notice Deploy with mock contracts for testing
 */
contract DeployWithMocks is Script {
    function run() public {
        vm.startBroadcast();

        // Deploy mock token
        MockToken token = new MockToken();
        console.log("Mock Token deployed at:", address(token));

        // Deploy mock price feed
        MockChainlinkFeed priceFeed = new MockChainlinkFeed(2000 * 1e8, 8);
        console.log("Mock Price Feed deployed at:", address(priceFeed));

        // Deploy mock fallback oracle
        MockFallbackOracle fallbackOracle = new MockFallbackOracle(2000 * 1e18);
        console.log("Mock Fallback Oracle deployed at:", address(fallbackOracle));

        // Deploy vault
        Project47Solution vault = new Project47Solution(
            address(token),
            address(priceFeed),
            "Mock Vault",
            "vMOCK"
        );
        console.log("Vault deployed at:", address(vault));

        // Configure vault
        vault.updateFallbackOracle(address(fallbackOracle));
        vault.updatePriceBounds(1 * 1e18, 1000000 * 1e18);

        console.log("====================================");
        console.log("Mock deployment complete!");
        console.log("====================================");

        vm.stopBroadcast();
    }
}

// ============================================
// MOCK CONTRACTS FOR TESTING
// ============================================

contract MockToken {
    string public name = "Mock Token";
    string public symbol = "MOCK";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        totalSupply = 1000000 * 1e18;
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
}

contract MockChainlinkFeed {
    int256 public price;
    uint256 public updatedAt;
    uint80 public roundId;
    uint8 public decimals;

    constructor(int256 _price, uint8 _decimals) {
        price = _price;
        decimals = _decimals;
        updatedAt = block.timestamp;
        roundId = 1;
    }

    function latestRoundData()
        external
        view
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return (roundId, price, block.timestamp, updatedAt, roundId);
    }

    function updatePrice(int256 newPrice) external {
        price = newPrice;
        updatedAt = block.timestamp;
        roundId++;
    }
}

contract MockFallbackOracle {
    uint256 public price;

    constructor(uint256 _price) {
        price = _price;
    }

    function getPrice() external view returns (uint256) {
        return price;
    }

    function updatePrice(uint256 newPrice) external {
        price = newPrice;
    }
}
