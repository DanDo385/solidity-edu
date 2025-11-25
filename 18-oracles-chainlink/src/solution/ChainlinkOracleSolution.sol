// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Project18Solution - Chainlink Oracle Integration (Complete Implementation)
 * @notice Production-ready Chainlink price feed integration with comprehensive safety checks
 * @dev This is the SOLUTION - study this after attempting the skeleton contract
 *
 * KEY LEARNING POINTS:
 * 1. Always validate oracle data (staleness, bounds, completeness)
 * 2. Circuit breakers protect against extreme price movements
 * 3. Multiple safety layers prevent oracle manipulation
 * 4. Proper error handling for oracle failures
 * 5. Gas-efficient caching strategies
 *
 * SECURITY FEATURES IMPLEMENTED:
 * ✅ Stale price detection
 * ✅ Price range validation
 * ✅ Round completeness check
 * ✅ Circuit breaker pattern
 * ✅ Emergency pause mechanism
 * ✅ Owner-controlled configuration
 * ✅ Comprehensive event logging
 */

// Chainlink AggregatorV3Interface
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract Project18Solution {
    // =====================================================
    // STATE VARIABLES
    // =====================================================

    /// @notice Chainlink price feed contract
    AggregatorV3Interface public priceFeed;

    /// @notice Owner address for admin functions
    address public owner;

    /// @notice Maximum age of price data before considered stale (in seconds)
    /// @dev Typically 1 hour for ETH/USD, but varies by feed
    uint256 public stalenessThreshold;

    /// @notice Maximum allowed price deviation percentage (basis points: 5000 = 50%)
    /// @dev Circuit breaker triggers if price moves more than this percentage
    uint256 public maxPriceDeviation;

    /// @notice Last recorded price for circuit breaker comparison
    /// @dev Used to detect abnormal price swings
    uint256 public lastPrice;

    /// @notice Timestamp of last price update
    uint256 public lastUpdateTime;

    /// @notice Minimum reasonable price (to prevent oracle errors)
    /// @dev Example: ETH should never be $0.01
    uint256 public minPrice;

    /// @notice Maximum reasonable price (to prevent oracle errors)
    /// @dev Example: ETH unlikely to be $1,000,000 in near term
    uint256 public maxPrice;

    /// @notice Circuit breaker state - true when paused
    /// @dev When triggered, all price operations are paused until manual reset
    bool public circuitBreakerTriggered;

    // =====================================================
    // EVENTS
    // =====================================================

    event PriceUpdated(uint256 newPrice, uint256 timestamp);
    event CircuitBreakerTriggered(uint256 price, uint256 deviation);
    event CircuitBreakerReset();
    event ConfigUpdated(
        uint256 stalenessThreshold,
        uint256 maxPriceDeviation,
        uint256 minPrice,
        uint256 maxPrice
    );
    event PriceFeedUpdated(address indexed oldFeed, address indexed newFeed);

    // =====================================================
    // ERRORS
    // =====================================================

    error Unauthorized();
    error StalePrice(uint256 timeSinceUpdate);
    error InvalidPrice(int256 price);
    error PriceOutOfBounds(uint256 price);
    error IncompleteRound();
    error ExcessivePriceDeviation(uint256 deviation);
    error CircuitBreakerActive();
    error InvalidConfiguration();

    // =====================================================
    // MODIFIERS
    // =====================================================

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    modifier whenNotPaused() {
        if (circuitBreakerTriggered) revert CircuitBreakerActive();
        _;
    }

    // =====================================================
    // CONSTRUCTOR
    // =====================================================

    /**
     * @notice Initialize the oracle contract
     * @param _priceFeed Address of Chainlink price feed
     * @param _stalenessThreshold Maximum age of price data (seconds)
     * @param _maxPriceDeviation Maximum allowed deviation in basis points (10000 = 100%)
     * @param _minPrice Minimum reasonable price
     * @param _maxPrice Maximum reasonable price
     */
    constructor(
        address _priceFeed,
        uint256 _stalenessThreshold,
        uint256 _maxPriceDeviation,
        uint256 _minPrice,
        uint256 _maxPrice
    ) {
        require(_priceFeed != address(0), "Invalid price feed");
        require(_minPrice < _maxPrice, "Invalid price bounds");
        require(_stalenessThreshold > 0, "Invalid staleness threshold");

        owner = msg.sender;
        priceFeed = AggregatorV3Interface(_priceFeed);
        stalenessThreshold = _stalenessThreshold;
        maxPriceDeviation = _maxPriceDeviation;
        minPrice = _minPrice;
        maxPrice = _maxPrice;

        // Circuit breaker starts inactive
        circuitBreakerTriggered = false;

        // lastPrice starts at 0 (will be set on first price fetch)
        lastPrice = 0;
    }

    // =====================================================
    // MAIN ORACLE FUNCTIONS
    // =====================================================

    /**
     * @notice Get the latest price from Chainlink with all safety checks
     * @return price The validated price
     * @return decimals The number of decimals in the price
     *
     * SAFETY CHECKS PERFORMED:
     * 1. ✅ Circuit breaker check (modifier)
     * 2. ✅ Price validity (not zero/negative)
     * 3. ✅ Staleness check
     * 4. ✅ Round completeness
     * 5. ✅ Price bounds validation
     * 6. ✅ Deviation check (circuit breaker)
     * 7. ✅ State update and event emission
     */
    function getLatestPrice()
        public
        whenNotPaused
        returns (uint256 price, uint8 decimals)
    {
        // Step 1: Fetch latest round data from Chainlink
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        // Step 2: Validate price is positive
        // Oracle should never return negative or zero price for asset pairs
        if (answer <= 0) {
            revert InvalidPrice(answer);
        }

        // Step 3: Check price staleness
        // If oracle hasn't updated recently, price may be outdated
        if (_isPriceStale(updatedAt)) {
            revert StalePrice(block.timestamp - updatedAt);
        }

        // Step 4: Verify round completeness
        // answeredInRound should be >= roundId, otherwise round not finalized
        // This prevents using data from incomplete oracle rounds
        if (answeredInRound < roundId) {
            revert IncompleteRound();
        }

        // Step 5: Convert to uint256 (safe because we checked answer > 0)
        price = uint256(answer);

        // Step 6: Validate price is within reasonable bounds
        // Protects against oracle errors or extreme black swan events
        if (price < minPrice || price > maxPrice) {
            revert PriceOutOfBounds(price);
        }

        // Step 7: Check circuit breaker for excessive deviation
        // Only check if we have a previous price to compare against
        if (lastPrice != 0) {
            if (!_checkCircuitBreaker(price)) {
                // Circuit breaker was triggered inside _checkCircuitBreaker
                // This revert may be redundant but makes intent clear
                revert ExcessivePriceDeviation(_calculateDeviation(price, lastPrice));
            }
        }

        // Step 8: Update state
        lastPrice = price;
        lastUpdateTime = block.timestamp;

        // Step 9: Get decimals (cache to save gas if calling multiple times)
        decimals = priceFeed.decimals();

        // Step 10: Emit event for off-chain monitoring
        emit PriceUpdated(price, block.timestamp);

        return (price, decimals);
    }

    /**
     * @notice Get price without updating state (view function)
     * @return price The current price
     * @return decimals The number of decimals
     *
     * @dev Use this when you need price for calculations but don't want to update state
     * @dev Still performs all safety checks except circuit breaker deviation
     */
    function viewLatestPrice()
        public
        view
        returns (uint256 price, uint8 decimals)
    {
        // Fetch latest round data
        (
            uint80 roundId,
            int256 answer,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        // Validate price
        if (answer <= 0) {
            revert InvalidPrice(answer);
        }

        // Check staleness
        if (_isPriceStale(updatedAt)) {
            revert StalePrice(block.timestamp - updatedAt);
        }

        // Check round completeness
        if (answeredInRound < roundId) {
            revert IncompleteRound();
        }

        // Convert and validate bounds
        price = uint256(answer);
        if (price < minPrice || price > maxPrice) {
            revert PriceOutOfBounds(price);
        }

        // Note: We don't check circuit breaker deviation in view function
        // because we can't trigger the circuit breaker without state change

        decimals = priceFeed.decimals();

        return (price, decimals);
    }

    // =====================================================
    // CIRCUIT BREAKER FUNCTIONS
    // =====================================================

    /**
     * @notice Check if price deviation triggers circuit breaker
     * @param newPrice The new price to check
     * @return withinBounds True if price change is acceptable
     *
     * @dev Circuit breaker logic:
     * - Calculate percentage deviation from last price
     * - If deviation > threshold, trigger circuit breaker
     * - This prevents protocol from using potentially manipulated prices
     *
     * EXAMPLE:
     * - lastPrice = 2000 (ETH/USD)
     * - newPrice = 3000 (ETH/USD)
     * - deviation = (1000 * 10000) / 2000 = 5000 basis points (50%)
     * - If maxPriceDeviation = 2000 (20%), circuit breaker triggers
     */
    function _checkCircuitBreaker(uint256 newPrice) internal returns (bool withinBounds) {
        // First price fetch, no previous price to compare
        if (lastPrice == 0) {
            return true;
        }

        // Calculate percentage deviation in basis points
        uint256 deviation = _calculateDeviation(newPrice, lastPrice);

        // Check if deviation exceeds threshold
        if (deviation > maxPriceDeviation) {
            // Trigger circuit breaker
            circuitBreakerTriggered = true;
            emit CircuitBreakerTriggered(newPrice, deviation);
            return false;
        }

        return true;
    }

    /**
     * @notice Calculate percentage deviation between two prices
     * @param price1 First price
     * @param price2 Second price
     * @return deviation Percentage deviation in basis points (10000 = 100%)
     */
    function _calculateDeviation(uint256 price1, uint256 price2)
        internal
        pure
        returns (uint256 deviation)
    {
        // Get absolute difference
        uint256 diff = price1 > price2 ? price1 - price2 : price2 - price1;

        // Calculate percentage: (diff * 10000) / price2
        // Using basis points (10000 = 100%) for precision
        deviation = (diff * 10000) / price2;

        return deviation;
    }

    /**
     * @notice Manually trigger circuit breaker (emergency function)
     * @dev Only owner can trigger. Use when oracle behavior is suspicious.
     */
    function triggerCircuitBreaker() external onlyOwner {
        circuitBreakerTriggered = true;
        emit CircuitBreakerTriggered(lastPrice, 0);
    }

    /**
     * @notice Reset circuit breaker (resume operations)
     * @dev Only owner can reset after investigating the cause
     *
     * IMPORTANT: Before resetting, ensure:
     * 1. Oracle data is reliable again
     * 2. Price movements were legitimate
     * 3. No ongoing attack
     */
    function resetCircuitBreaker() external onlyOwner {
        circuitBreakerTriggered = false;

        // Reset lastPrice to current price to avoid immediate re-trigger
        // This is safe because owner has verified current price is legitimate
        try priceFeed.latestRoundData() returns (
            uint80,
            int256 answer,
            uint256,
            uint256,
            uint80
        ) {
            if (answer > 0) {
                lastPrice = uint256(answer);
                lastUpdateTime = block.timestamp;
            }
        } catch {
            // If oracle call fails, keep old lastPrice
            // Circuit breaker is still reset, but next call will re-check
        }

        emit CircuitBreakerReset();
    }

    // =====================================================
    // HELPER FUNCTIONS
    // =====================================================

    /**
     * @notice Check if price data is stale
     * @param updatedAt Timestamp when price was last updated
     * @return isStale True if price is stale
     *
     * @dev Staleness thresholds vary by feed:
     * - ETH/USD: ~1 hour
     * - BTC/USD: ~1 hour
     * - Stablecoins: ~24 hours
     * Check Chainlink docs for your specific feed
     */
    function _isPriceStale(uint256 updatedAt) internal view returns (bool) {
        return (block.timestamp - updatedAt) > stalenessThreshold;
    }

    /**
     * @notice Get time since last update
     * @return Time in seconds since last oracle update
     */
    function getTimeSinceLastUpdate() external view returns (uint256) {
        if (lastUpdateTime == 0) return 0;
        return block.timestamp - lastUpdateTime;
    }

    /**
     * @notice Get the price feed description
     * @return Description string (e.g., "ETH / USD")
     */
    function getPriceFeedDescription() external view returns (string memory) {
        return priceFeed.description();
    }

    // =====================================================
    // ADMIN FUNCTIONS
    // =====================================================

    /**
     * @notice Update configuration parameters
     * @param _stalenessThreshold New staleness threshold
     * @param _maxPriceDeviation New max price deviation
     * @param _minPrice New minimum price
     * @param _maxPrice New maximum price
     *
     * @dev Use this to adjust parameters as market conditions change
     */
    function updateConfig(
        uint256 _stalenessThreshold,
        uint256 _maxPriceDeviation,
        uint256 _minPrice,
        uint256 _maxPrice
    ) external onlyOwner {
        // Validate parameters
        if (_minPrice >= _maxPrice) revert InvalidConfiguration();
        if (_stalenessThreshold == 0) revert InvalidConfiguration();

        stalenessThreshold = _stalenessThreshold;
        maxPriceDeviation = _maxPriceDeviation;
        minPrice = _minPrice;
        maxPrice = _maxPrice;

        emit ConfigUpdated(_stalenessThreshold, _maxPriceDeviation, _minPrice, _maxPrice);
    }

    /**
     * @notice Update the price feed address
     * @param _newPriceFeed New price feed address
     *
     * @dev Use this to migrate to a different Chainlink feed
     * WARNING: This resets lastPrice, so circuit breaker won't trigger on first fetch
     */
    function updatePriceFeed(address _newPriceFeed) external onlyOwner {
        require(_newPriceFeed != address(0), "Invalid address");

        address oldFeed = address(priceFeed);
        priceFeed = AggregatorV3Interface(_newPriceFeed);

        // Reset lastPrice since we're using a new feed
        // This prevents false circuit breaker triggers
        lastPrice = 0;
        lastUpdateTime = 0;

        emit PriceFeedUpdated(oldFeed, _newPriceFeed);
    }

    /**
     * @notice Transfer ownership
     * @param newOwner New owner address
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }

    // =====================================================
    // EXAMPLE USAGE FUNCTIONS
    // =====================================================

    /**
     * @notice Example: Calculate value in USD
     * @param assetAmount Amount of asset (in wei for ETH)
     * @return usdValue Value in USD (scaled by price feed decimals)
     *
     * @dev This demonstrates how to use the oracle in a real application
     *
     * EXAMPLE:
     * - assetAmount = 1 ETH = 1e18 wei
     * - price = 2000 USD = 2000e8 (8 decimals)
     * - usdValue = (1e18 * 2000e8) / 1e18 = 2000e8 (2000 USD with 8 decimals)
     */
    function calculateUSDValue(uint256 assetAmount) external returns (uint256 usdValue) {
        (uint256 price, uint8 decimals) = getLatestPrice();

        // Scale calculation: assetAmount * price / 1e18
        // Result is in USD with `decimals` decimal places
        usdValue = (assetAmount * price) / (10 ** 18);

        return usdValue;
    }

    /**
     * @notice Example: Calculate asset amount from USD value
     * @param usdValue USD value (scaled by price feed decimals)
     * @return assetAmount Amount of asset in wei
     *
     * EXAMPLE:
     * - usdValue = 4000 USD = 4000e8 (8 decimals)
     * - price = 2000 USD/ETH = 2000e8
     * - assetAmount = (4000e8 * 1e18) / 2000e8 = 2e18 (2 ETH)
     */
    function calculateAssetAmount(uint256 usdValue) external returns (uint256 assetAmount) {
        (uint256 price, uint8 decimals) = getLatestPrice();

        // Scale calculation: usdValue * 1e18 / price
        assetAmount = (usdValue * (10 ** 18)) / price;

        return assetAmount;
    }
}

/**
 * ============================================================================
 * PRODUCTION DEPLOYMENT CHECKLIST
 * ============================================================================
 *
 * Before deploying to mainnet:
 *
 * 1. VERIFY PRICE FEED ADDRESS
 *    ✅ Use official Chainlink feed from docs.chain.link
 *    ✅ Verify feed is actively maintained
 *    ✅ Check feed heartbeat (update frequency)
 *
 * 2. SET APPROPRIATE THRESHOLDS
 *    ✅ stalenessThreshold: Match feed's heartbeat + buffer
 *    ✅ maxPriceDeviation: Based on historical volatility
 *    ✅ minPrice/maxPrice: Reasonable bounds for asset
 *
 * 3. SECURITY MEASURES
 *    ✅ Multi-sig wallet as owner
 *    ✅ Off-chain monitoring for circuit breaker events
 *    ✅ Emergency response plan
 *    ✅ Backup oracle strategy
 *
 * 4. TESTING
 *    ✅ Comprehensive unit tests
 *    ✅ Integration tests with mainnet fork
 *    ✅ Fuzz testing for edge cases
 *    ✅ Audit by professional security firm
 *
 * 5. MONITORING
 *    ✅ Alert on StalePrice events
 *    ✅ Alert on CircuitBreakerTriggered events
 *    ✅ Monitor deviation between Chainlink and other sources (DEX TWAP)
 *    ✅ Track oracle update frequency
 *
 * ============================================================================
 * ADVANCED PATTERNS TO CONSIDER
 * ============================================================================
 *
 * 1. MULTIPLE ORACLE SOURCES
 *    - Combine Chainlink with Uniswap V3 TWAP
 *    - Use median of multiple sources
 *    - Fallback to secondary oracle if primary fails
 *
 * 2. TWAP INTEGRATION
 *    - Track historical prices on-chain
 *    - Calculate time-weighted average
 *    - Smooth out flash loan attacks
 *
 * 3. ORACLE DIVERSITY
 *    - Chainlink for primary
 *    - Band Protocol for backup
 *    - DEX TWAP for sanity check
 *
 * 4. GRADUAL PRICE UPDATES
 *    - Don't allow instant large movements
 *    - Ramp price changes over time
 *    - Protects against oracle manipulation
 *
 * 5. KEEPER AUTOMATION
 *    - Use Chainlink Keepers to update prices
 *    - Trigger circuit breaker automatically
 *    - Monitor and alert on anomalies
 *
 * ============================================================================
 */
