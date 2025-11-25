// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/ChainlinkOracle.sol";
import "../src/solution/ChainlinkOracleSolution.sol";

/**
 * @title DeployChainlinkOracle
 * @notice Deployment script for Oracle integration contract
 * @dev Supports deployment to various networks with appropriate Chainlink feeds
 *
 * USAGE:
 * Deploy to local testnet (Anvil):
 *   forge script script/DeployChainlinkOracle.s.sol --broadcast --rpc-url http://localhost:8545
 *
 * Deploy to Sepolia testnet:
 *   forge script script/DeployChainlinkOracle.s.sol --broadcast --rpc-url $SEPOLIA_RPC_URL \
 *     --private-key $PRIVATE_KEY --verify
 *
 * Deploy to Ethereum mainnet (DANGEROUS - use multi-sig!):
 *   forge script script/DeployChainlinkOracle.s.sol --broadcast --rpc-url $MAINNET_RPC_URL \
 *     --private-key $PRIVATE_KEY --verify
 *
 * Fork mainnet for testing:
 *   anvil --fork-url $MAINNET_RPC_URL
 *   forge script script/DeployChainlinkOracle.s.sol --broadcast --rpc-url http://localhost:8545
 */
contract DeployChainlinkOracle is Script {
    // =====================================================
    // CHAINLINK PRICE FEED ADDRESSES
    // =====================================================

    // Ethereum Mainnet Feeds
    address constant MAINNET_ETH_USD = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address constant MAINNET_BTC_USD = 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c;
    address constant MAINNET_USDC_USD = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
    address constant MAINNET_DAI_USD = 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9;

    // Sepolia Testnet Feeds
    address constant SEPOLIA_ETH_USD = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address constant SEPOLIA_BTC_USD = 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43;

    // =====================================================
    // CONFIGURATION PARAMETERS
    // =====================================================

    // Staleness thresholds (based on feed heartbeats)
    uint256 constant ETH_STALENESS_THRESHOLD = 1 hours; // ETH/USD updates ~every hour
    uint256 constant BTC_STALENESS_THRESHOLD = 1 hours; // BTC/USD updates ~every hour
    uint256 constant STABLECOIN_STALENESS_THRESHOLD = 24 hours; // Stablecoins update less frequently

    // Circuit breaker thresholds
    uint256 constant ETH_MAX_DEVIATION = 5000; // 50% - ETH can be volatile
    uint256 constant BTC_MAX_DEVIATION = 5000; // 50% - BTC can be volatile
    uint256 constant STABLECOIN_MAX_DEVIATION = 500; // 5% - Stablecoins should be stable

    // Price bounds (with 8 decimals for USD pairs)
    uint256 constant ETH_MIN_PRICE = 100e8; // $100 - reasonable floor
    uint256 constant ETH_MAX_PRICE = 50000e8; // $50,000 - reasonable ceiling
    uint256 constant BTC_MIN_PRICE = 1000e8; // $1,000
    uint256 constant BTC_MAX_PRICE = 500000e8; // $500,000
    uint256 constant STABLECOIN_MIN_PRICE = 0.5e8; // $0.50
    uint256 constant STABLECOIN_MAX_PRICE = 1.5e8; // $1.50

    // =====================================================
    // STATE VARIABLES
    // =====================================================

    ChainlinkOracleSolution public oracle;
    address public deployer;

    // =====================================================
    // MAIN DEPLOYMENT FUNCTION
    // =====================================================

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying from address:", deployer);
        console.log("Current chain ID:", block.chainid);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy based on chain ID
        if (block.chainid == 1) {
            // Ethereum Mainnet
            console.log("Deploying to Ethereum Mainnet...");
            deployMainnetETH();
        } else if (block.chainid == 11155111) {
            // Sepolia Testnet
            console.log("Deploying to Sepolia Testnet...");
            deploySepoliaETH();
        } else {
            // Local or unknown network - deploy with mock feed
            console.log("Deploying to local/unknown network with mock feed...");
            deployLocal();
        }

        vm.stopBroadcast();

        // Post-deployment verification
        verifyDeployment();
    }

    // =====================================================
    // NETWORK-SPECIFIC DEPLOYMENTS
    // =====================================================

    /**
     * @notice Deploy to Ethereum Mainnet with ETH/USD feed
     */
    function deployMainnetETH() internal {
        console.log("Using Chainlink ETH/USD feed:", MAINNET_ETH_USD);

        oracle = new ChainlinkOracleSolution(
            MAINNET_ETH_USD,
            ETH_STALENESS_THRESHOLD,
            ETH_MAX_DEVIATION,
            ETH_MIN_PRICE,
            ETH_MAX_PRICE
        );

        console.log("Oracle deployed at:", address(oracle));
        console.log("Price feed:", oracle.getPriceFeedDescription());
    }

    /**
     * @notice Deploy to Ethereum Mainnet with BTC/USD feed
     */
    function deployMainnetBTC() internal {
        console.log("Using Chainlink BTC/USD feed:", MAINNET_BTC_USD);

        oracle = new ChainlinkOracleSolution(
            MAINNET_BTC_USD,
            BTC_STALENESS_THRESHOLD,
            BTC_MAX_DEVIATION,
            BTC_MIN_PRICE,
            BTC_MAX_PRICE
        );

        console.log("Oracle deployed at:", address(oracle));
        console.log("Price feed:", oracle.getPriceFeedDescription());
    }

    /**
     * @notice Deploy to Sepolia Testnet with ETH/USD feed
     */
    function deploySepoliaETH() internal {
        console.log("Using Chainlink ETH/USD feed:", SEPOLIA_ETH_USD);

        oracle = new ChainlinkOracleSolution(
            SEPOLIA_ETH_USD,
            ETH_STALENESS_THRESHOLD,
            ETH_MAX_DEVIATION,
            ETH_MIN_PRICE,
            ETH_MAX_PRICE
        );

        console.log("Oracle deployed at:", address(oracle));
        console.log("Price feed:", oracle.getPriceFeedDescription());
    }

    /**
     * @notice Deploy to local network with mock price feed
     */
    function deployLocal() internal {
        console.log("Deploying mock price feed for testing...");

        // Deploy mock Chainlink feed
        MockAggregatorV3 mockFeed = new MockAggregatorV3(8, "ETH / USD");
        mockFeed.setPrice(2000e8); // Initial price: $2000

        console.log("Mock price feed deployed at:", address(mockFeed));

        oracle = new ChainlinkOracleSolution(
            address(mockFeed),
            ETH_STALENESS_THRESHOLD,
            ETH_MAX_DEVIATION,
            ETH_MIN_PRICE,
            ETH_MAX_PRICE
        );

        console.log("Oracle deployed at:", address(oracle));
        console.log("Price feed:", oracle.getPriceFeedDescription());
    }

    // =====================================================
    // POST-DEPLOYMENT VERIFICATION
    // =====================================================

    /**
     * @notice Verify deployment was successful
     */
    function verifyDeployment() internal view {
        console.log("\n=== Deployment Verification ===");
        console.log("Oracle address:", address(oracle));
        console.log("Owner:", oracle.owner());
        console.log("Price feed:", address(oracle.priceFeed()));
        console.log("Staleness threshold:", oracle.stalenessThreshold(), "seconds");
        console.log("Max price deviation:", oracle.maxPriceDeviation(), "basis points");
        console.log("Min price:", oracle.minPrice());
        console.log("Max price:", oracle.maxPrice());
        console.log("Circuit breaker triggered:", oracle.circuitBreakerTriggered());

        // Try to fetch current price (view function, won't change state)
        try oracle.viewLatestPrice() returns (uint256 price, uint8 decimals) {
            console.log("\nCurrent price:", price);
            console.log("Decimals:", decimals);

            // Convert to human-readable USD
            uint256 dollars = price / (10 ** decimals);
            uint256 cents = (price % (10 ** decimals)) * 100 / (10 ** decimals);
            console.log("Human-readable: $", dollars, ".", cents);
        } catch Error(string memory reason) {
            console.log("Could not fetch price:", reason);
        } catch {
            console.log("Could not fetch price: Unknown error");
        }

        console.log("\n=== Deployment Complete ===");
    }

    // =====================================================
    // ALTERNATIVE DEPLOYMENT FUNCTIONS
    // =====================================================

    /**
     * @notice Deploy with custom parameters
     * @dev Useful for specialized deployments
     */
    function deployCustom(
        address priceFeed,
        uint256 stalenessThreshold,
        uint256 maxPriceDeviation,
        uint256 minPrice,
        uint256 maxPrice
    ) public returns (address) {
        oracle = new ChainlinkOracleSolution(
            priceFeed,
            stalenessThreshold,
            maxPriceDeviation,
            minPrice,
            maxPrice
        );

        console.log("Custom oracle deployed at:", address(oracle));
        return address(oracle);
    }
}

/**
 * @title MockAggregatorV3
 * @notice Mock Chainlink price feed for local testing
 */
contract MockAggregatorV3 {
    uint8 public decimals;
    string public description;
    uint256 public version;

    uint80 public roundId;
    int256 public answer;
    uint256 public startedAt;
    uint256 public updatedAt;
    uint80 public answeredInRound;

    constructor(uint8 _decimals, string memory _description) {
        decimals = _decimals;
        description = _description;
        version = 1;

        roundId = 1;
        answer = 2000e8;
        startedAt = block.timestamp;
        updatedAt = block.timestamp;
        answeredInRound = 1;
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 _roundId,
            int256 _answer,
            uint256 _startedAt,
            uint256 _updatedAt,
            uint80 _answeredInRound
        )
    {
        return (roundId, answer, startedAt, updatedAt, answeredInRound);
    }

    function setPrice(int256 _price) external {
        answer = _price;
        roundId++;
        answeredInRound = roundId;
        updatedAt = block.timestamp;
    }

    function setUpdatedAt(uint256 _updatedAt) external {
        updatedAt = _updatedAt;
    }
}

/**
 * ============================================================================
 * DEPLOYMENT GUIDE
 * ============================================================================
 *
 * STEP 1: PREPARE ENVIRONMENT
 * ---------------------------
 * Create .env file with:
 *   PRIVATE_KEY=your_private_key
 *   MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY
 *   SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY
 *   ETHERSCAN_API_KEY=your_etherscan_key
 *
 * STEP 2: LOCAL TESTING
 * ---------------------
 * # Start Anvil
 * anvil
 *
 * # Deploy to local node
 * forge script script/DeployChainlinkOracle.s.sol --broadcast --rpc-url http://localhost:8545
 *
 * # Test with cast
 * cast call <ORACLE_ADDRESS> "viewLatestPrice()(uint256,uint8)"
 *
 * STEP 3: TESTNET DEPLOYMENT
 * --------------------------
 * # Deploy to Sepolia
 * forge script script/DeployChainlinkOracle.s.sol \
 *   --broadcast \
 *   --rpc-url $SEPOLIA_RPC_URL \
 *   --private-key $PRIVATE_KEY \
 *   --verify \
 *   --etherscan-api-key $ETHERSCAN_API_KEY
 *
 * STEP 4: MAINNET FORK TESTING
 * ----------------------------
 * # Fork mainnet for testing with real Chainlink data
 * anvil --fork-url $MAINNET_RPC_URL
 *
 * # Deploy to fork
 * forge script script/DeployChainlinkOracle.s.sol --broadcast --rpc-url http://localhost:8545
 *
 * # You'll see real ETH/USD prices from Chainlink!
 *
 * STEP 5: MAINNET DEPLOYMENT (PRODUCTION)
 * ---------------------------------------
 * ⚠️  WARNING: Use multi-sig wallet for production!
 * ⚠️  Never use a personal private key for mainnet!
 *
 * # Deploy to mainnet (after thorough testing!)
 * forge script script/DeployChainlinkOracle.s.sol \
 *   --broadcast \
 *   --rpc-url $MAINNET_RPC_URL \
 *   --ledger \ # Use hardware wallet
 *   --verify \
 *   --etherscan-api-key $ETHERSCAN_API_KEY
 *
 * # Immediately transfer ownership to multi-sig
 * cast send <ORACLE_ADDRESS> \
 *   "transferOwnership(address)" <MULTISIG_ADDRESS> \
 *   --rpc-url $MAINNET_RPC_URL \
 *   --ledger
 *
 * STEP 6: POST-DEPLOYMENT
 * ----------------------
 * 1. Verify contract on Etherscan
 * 2. Set up monitoring/alerts
 * 3. Document contract address
 * 4. Test all functions
 * 5. Transfer ownership to multi-sig
 *
 * ============================================================================
 */
