// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Project18 - Chainlink Oracle Integration
 * @notice Learn to safely integrate Chainlink price feeds with proper validation
 * @dev This is the skeleton contract - implement the TODOs below
 *
 * LEARNING OBJECTIVES:
 * 1. Integrate Chainlink AggregatorV3Interface
 * 2. Detect and reject stale price data
 * 3. Implement circuit breaker patterns
 * 4. Validate price ranges
 * 5. Handle oracle failures gracefully
 *
 * SECURITY CONSIDERATIONS:
 * - Always check price staleness
 * - Validate price is within reasonable bounds
 * - Check round data completeness
 * - Implement circuit breaker for extreme swings
 * - Have emergency pause mechanism
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

contract Project18 {
    // =====================================================
    // STATE VARIABLES
    // =====================================================

    /// @notice Chainlink price feed contract
    AggregatorV3Interface public priceFeed;

    /// @notice Owner address for admin functions
    address public owner;

    /// @notice Maximum age of price data before considered stale (in seconds)
    uint256 public stalenessThreshold;

    /// @notice Maximum allowed price deviation percentage (basis points: 5000 = 50%)
    uint256 public maxPriceDeviation;

    /// @notice Last recorded price for circuit breaker comparison
    uint256 public lastPrice;

    /// @notice Timestamp of last price update
    uint256 public lastUpdateTime;

    /// @notice Minimum reasonable price (to prevent oracle errors)
    uint256 public minPrice;

    /// @notice Maximum reasonable price (to prevent oracle errors)
    uint256 public maxPrice;

    /// @notice Circuit breaker state - true when paused
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
     * @param _maxPriceDeviation Maximum allowed deviation in basis points
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
        // TODO: Initialize state variables
        // - Set owner to msg.sender
        // - Set priceFeed to AggregatorV3Interface(_priceFeed)
        // - Set stalenessThreshold, maxPriceDeviation, minPrice, maxPrice
        // - Initialize lastPrice to 0 (will be set on first update)
        // - circuitBreakerTriggered should be false by default
    }

    // =====================================================
    // MAIN ORACLE FUNCTIONS
    // =====================================================

    /**
     * @notice Get the latest price from Chainlink with all safety checks
     * @return price The validated price
     * @return decimals The number of decimals in the price
     *
     * TODO: Implement the following:
     * 1. Call priceFeed.latestRoundData()
     * 2. Validate price is not negative or zero
     * 3. Check price staleness (updatedAt vs block.timestamp)
     * 4. Verify round completeness (answeredInRound >= roundId)
     * 5. Convert int256 to uint256
     * 6. Check price is within min/max bounds
     * 7. Check circuit breaker (if lastPrice exists)
     * 8. Update lastPrice and lastUpdateTime
     * 9. Emit PriceUpdated event
     * 10. Return price and decimals
     */
    function getLatestPrice() public whenNotPaused returns (uint256 price, uint8 decimals) {
        // TODO: Implement price retrieval with all safety checks
        // Hint: Use priceFeed.latestRoundData() and priceFeed.decimals()
    }

    /**
     * @notice Get price without updating state (view function)
     * @return price The current price
     * @return decimals The number of decimals
     *
     * TODO: Similar to getLatestPrice but as a view function
     * - Don't update lastPrice or lastUpdateTime
     * - Don't emit events
     * - Still perform all safety checks
     */
    function viewLatestPrice() public view returns (uint256 price, uint8 decimals) {
        // TODO: Implement view-only price retrieval
    }

    // =====================================================
    // CIRCUIT BREAKER FUNCTIONS
    // =====================================================

    /**
     * @notice Check if price deviation triggers circuit breaker
     * @param newPrice The new price to check
     * @return withinBounds True if price change is acceptable
     *
     * TODO: Implement circuit breaker logic:
     * 1. If lastPrice is 0 (first price), return true
     * 2. Calculate percentage deviation: |newPrice - lastPrice| * 10000 / lastPrice
     * 3. If deviation > maxPriceDeviation, trigger circuit breaker and return false
     * 4. Otherwise return true
     */
    function _checkCircuitBreaker(uint256 newPrice) internal returns (bool withinBounds) {
        // TODO: Implement circuit breaker check
    }

    /**
     * @notice Manually trigger circuit breaker (emergency function)
     *
     * TODO: Implement:
     * - Require owner
     * - Set circuitBreakerTriggered to true
     * - Emit event
     */
    function triggerCircuitBreaker() external onlyOwner {
        // TODO: Implement manual circuit breaker trigger
    }

    /**
     * @notice Reset circuit breaker (resume operations)
     *
     * TODO: Implement:
     * - Require owner
     * - Set circuitBreakerTriggered to false
     * - Optionally reset lastPrice
     * - Emit event
     */
    function resetCircuitBreaker() external onlyOwner {
        // TODO: Implement circuit breaker reset
    }

    // =====================================================
    // HELPER FUNCTIONS
    // =====================================================

    /**
     * @notice Check if price data is stale
     * @param updatedAt Timestamp when price was last updated
     * @return isStale True if price is stale
     */
    function _isPriceStale(uint256 updatedAt) internal view returns (bool) {
        // TODO: Return true if (block.timestamp - updatedAt) > stalenessThreshold
        return false;
    }

    /**
     * @notice Get time since last update
     * @return Time in seconds since last oracle update
     */
    function getTimeSinceLastUpdate() external view returns (uint256) {
        // TODO: Return block.timestamp - lastUpdateTime
        return 0;
    }

    /**
     * @notice Get the price feed description
     * @return Description string (e.g., "ETH / USD")
     */
    function getPriceFeedDescription() external view returns (string memory) {
        // TODO: Return priceFeed.description()
        return "";
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
     * TODO: Implement:
     * - Require owner
     * - Validate parameters (e.g., _minPrice < _maxPrice)
     * - Update state variables
     * - Emit ConfigUpdated event
     */
    function updateConfig(
        uint256 _stalenessThreshold,
        uint256 _maxPriceDeviation,
        uint256 _minPrice,
        uint256 _maxPrice
    ) external onlyOwner {
        // TODO: Implement config update
    }

    /**
     * @notice Update the price feed address
     * @param _newPriceFeed New price feed address
     *
     * TODO: Implement:
     * - Require owner
     * - Validate address is not zero
     * - Update priceFeed
     * - Reset lastPrice (new feed = new baseline)
     */
    function updatePriceFeed(address _newPriceFeed) external onlyOwner {
        // TODO: Implement price feed update
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
    // EXAMPLE USAGE FUNCTION (for demonstration)
    // =====================================================

    /**
     * @notice Example: Calculate value in USD
     * @param assetAmount Amount of asset (in wei)
     * @return usdValue Value in USD (scaled by price feed decimals)
     *
     * This demonstrates how to use the oracle in a real application
     */
    function calculateUSDValue(uint256 assetAmount) external returns (uint256 usdValue) {
        (uint256 price, uint8 decimals) = getLatestPrice();

        // Example: If ETH/USD = 2000 (with 8 decimals) and assetAmount = 1 ETH
        // Result: 1e18 * 2000e8 / 1e18 = 2000e8 (2000 USD with 8 decimals)
        usdValue = (assetAmount * price) / (10 ** 18);

        return usdValue;
    }
}

/**
 * IMPLEMENTATION HINTS:
 *
 * 1. STALENESS CHECK:
 *    require(block.timestamp - updatedAt <= stalenessThreshold, "Stale price");
 *
 * 2. PRICE VALIDATION:
 *    require(answer > 0, "Invalid price");
 *    require(answeredInRound >= roundId, "Stale round");
 *
 * 3. CIRCUIT BREAKER:
 *    uint256 deviation = calculatePercentageDeviation(newPrice, lastPrice);
 *    if (deviation > maxPriceDeviation) {
 *        circuitBreakerTriggered = true;
 *        emit CircuitBreakerTriggered(newPrice, deviation);
 *        revert ExcessivePriceDeviation(deviation);
 *    }
 *
 * 4. DECIMAL HANDLING:
 *    Chainlink price feeds typically use 8 decimals for USD pairs
 *    But always check with priceFeed.decimals()
 *
 * 5. GAS OPTIMIZATION:
 *    Cache decimals if calling multiple times
 *    Use view function when state updates not needed
 *
 * TESTING TIPS:
 * - Use a mock oracle contract for testing
 * - Test with various stale timestamps
 * - Test extreme price deviations
 * - Test edge cases (zero price, negative price)
 * - Fork mainnet to test with real Chainlink feeds
 */
