// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Project18.sol";
import "../src/solution/Project18Solution.sol";

/**
 * @title MockAggregatorV3
 * @notice Mock Chainlink price feed for testing
 * @dev Allows setting prices, timestamps, and round data for testing scenarios
 */
contract MockAggregatorV3 is AggregatorV3Interface {
    uint8 public decimals;
    string public description;
    uint256 public version;

    // Mock data
    uint80 public roundId;
    int256 public answer;
    uint256 public startedAt;
    uint256 public updatedAt;
    uint80 public answeredInRound;

    constructor(uint8 _decimals, string memory _description) {
        decimals = _decimals;
        description = _description;
        version = 1;

        // Initialize with default values
        roundId = 1;
        answer = 2000e8; // $2000 with 8 decimals
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

    // Helper functions to set mock data
    function setPrice(int256 _price) external {
        answer = _price;
        roundId++;
        answeredInRound = roundId;
        updatedAt = block.timestamp;
    }

    function setUpdatedAt(uint256 _updatedAt) external {
        updatedAt = _updatedAt;
    }

    function setRoundData(
        uint80 _roundId,
        int256 _answer,
        uint256 _startedAt,
        uint256 _updatedAt,
        uint80 _answeredInRound
    ) external {
        roundId = _roundId;
        answer = _answer;
        startedAt = _startedAt;
        updatedAt = _updatedAt;
        answeredInRound = _answeredInRound;
    }

    function setIncompleteRound() external {
        // Set answeredInRound < roundId to simulate incomplete round
        answeredInRound = roundId - 1;
    }
}

/**
 * @title Project18Test
 * @notice Comprehensive test suite for oracle integration
 */
contract Project18Test is Test {
    Project18Solution public oracle;
    MockAggregatorV3 public mockPriceFeed;

    address public owner = address(this);
    address public user = address(0x1);

    // Configuration values
    uint256 constant STALENESS_THRESHOLD = 1 hours;
    uint256 constant MAX_PRICE_DEVIATION = 5000; // 50%
    uint256 constant MIN_PRICE = 100e8; // $100
    uint256 constant MAX_PRICE = 10000e8; // $10,000

    // Events to test
    event PriceUpdated(uint256 newPrice, uint256 timestamp);
    event CircuitBreakerTriggered(uint256 price, uint256 deviation);
    event CircuitBreakerReset();
    event ConfigUpdated(
        uint256 stalenessThreshold,
        uint256 maxPriceDeviation,
        uint256 minPrice,
        uint256 maxPrice
    );

    function setUp() public {
        // Deploy mock price feed
        mockPriceFeed = new MockAggregatorV3(8, "ETH / USD");

        // Deploy oracle contract
        oracle = new Project18Solution(
            address(mockPriceFeed),
            STALENESS_THRESHOLD,
            MAX_PRICE_DEVIATION,
            MIN_PRICE,
            MAX_PRICE
        );
    }

    // =====================================================
    // BASIC FUNCTIONALITY TESTS
    // =====================================================

    function test_Constructor() public {
        assertEq(address(oracle.priceFeed()), address(mockPriceFeed));
        assertEq(oracle.owner(), owner);
        assertEq(oracle.stalenessThreshold(), STALENESS_THRESHOLD);
        assertEq(oracle.maxPriceDeviation(), MAX_PRICE_DEVIATION);
        assertEq(oracle.minPrice(), MIN_PRICE);
        assertEq(oracle.maxPrice(), MAX_PRICE);
        assertEq(oracle.circuitBreakerTriggered(), false);
        assertEq(oracle.lastPrice(), 0);
    }

    function test_GetLatestPrice() public {
        // Set a valid price
        mockPriceFeed.setPrice(2000e8); // $2000

        vm.expectEmit(true, true, true, true);
        emit PriceUpdated(2000e8, block.timestamp);

        (uint256 price, uint8 decimals) = oracle.getLatestPrice();

        assertEq(price, 2000e8);
        assertEq(decimals, 8);
        assertEq(oracle.lastPrice(), 2000e8);
        assertEq(oracle.lastUpdateTime(), block.timestamp);
    }

    function test_ViewLatestPrice() public {
        mockPriceFeed.setPrice(1500e8); // $1500

        (uint256 price, uint8 decimals) = oracle.viewLatestPrice();

        assertEq(price, 1500e8);
        assertEq(decimals, 8);
        // Should not update state
        assertEq(oracle.lastPrice(), 0);
        assertEq(oracle.lastUpdateTime(), 0);
    }

    function test_GetPriceFeedDescription() public {
        string memory desc = oracle.getPriceFeedDescription();
        assertEq(desc, "ETH / USD");
    }

    // =====================================================
    // STALENESS TESTS
    // =====================================================

    function test_RevertWhen_PriceIsStale() public {
        // Set price updated 2 hours ago (exceeds 1 hour threshold)
        mockPriceFeed.setUpdatedAt(block.timestamp - 2 hours);

        vm.expectRevert(
            abi.encodeWithSelector(
                Project18Solution.StalePrice.selector,
                2 hours
            )
        );
        oracle.getLatestPrice();
    }

    function test_AcceptPrice_ExactlyAtThreshold() public {
        // Set price updated exactly at threshold
        mockPriceFeed.setUpdatedAt(block.timestamp - STALENESS_THRESHOLD);

        (uint256 price,) = oracle.getLatestPrice();
        assertEq(price, 2000e8);
    }

    function test_AcceptPrice_JustBeforeThreshold() public {
        // Set price updated 59 minutes ago (just before 1 hour)
        mockPriceFeed.setUpdatedAt(block.timestamp - 59 minutes);

        (uint256 price,) = oracle.getLatestPrice();
        assertEq(price, 2000e8);
    }

    function test_GetTimeSinceLastUpdate() public {
        // Initially should be 0
        assertEq(oracle.getTimeSinceLastUpdate(), 0);

        // Fetch price
        oracle.getLatestPrice();
        assertEq(oracle.getTimeSinceLastUpdate(), 0);

        // Move forward in time
        vm.warp(block.timestamp + 30 minutes);
        assertEq(oracle.getTimeSinceLastUpdate(), 30 minutes);
    }

    // =====================================================
    // PRICE VALIDATION TESTS
    // =====================================================

    function test_RevertWhen_PriceIsZero() public {
        mockPriceFeed.setPrice(0);

        vm.expectRevert(
            abi.encodeWithSelector(Project18Solution.InvalidPrice.selector, int256(0))
        );
        oracle.getLatestPrice();
    }

    function test_RevertWhen_PriceIsNegative() public {
        mockPriceFeed.setPrice(-100e8);

        vm.expectRevert(
            abi.encodeWithSelector(Project18Solution.InvalidPrice.selector, int256(-100e8))
        );
        oracle.getLatestPrice();
    }

    function test_RevertWhen_PriceBelowMinimum() public {
        mockPriceFeed.setPrice(50e8); // $50, below MIN_PRICE of $100

        vm.expectRevert(
            abi.encodeWithSelector(Project18Solution.PriceOutOfBounds.selector, 50e8)
        );
        oracle.getLatestPrice();
    }

    function test_RevertWhen_PriceAboveMaximum() public {
        mockPriceFeed.setPrice(15000e8); // $15,000, above MAX_PRICE of $10,000

        vm.expectRevert(
            abi.encodeWithSelector(Project18Solution.PriceOutOfBounds.selector, 15000e8)
        );
        oracle.getLatestPrice();
    }

    function test_AcceptPrice_AtMinimumBound() public {
        mockPriceFeed.setPrice(int256(MIN_PRICE));

        (uint256 price,) = oracle.getLatestPrice();
        assertEq(price, MIN_PRICE);
    }

    function test_AcceptPrice_AtMaximumBound() public {
        mockPriceFeed.setPrice(int256(MAX_PRICE));

        (uint256 price,) = oracle.getLatestPrice();
        assertEq(price, MAX_PRICE);
    }

    // =====================================================
    // ROUND COMPLETENESS TESTS
    // =====================================================

    function test_RevertWhen_RoundIncomplete() public {
        // Set incomplete round (answeredInRound < roundId)
        mockPriceFeed.setIncompleteRound();

        vm.expectRevert(Project18Solution.IncompleteRound.selector);
        oracle.getLatestPrice();
    }

    function test_AcceptPrice_WhenRoundComplete() public {
        // Set complete round (answeredInRound >= roundId)
        mockPriceFeed.setRoundData(
            10, // roundId
            2000e8, // answer
            block.timestamp,
            block.timestamp,
            10 // answeredInRound = roundId
        );

        (uint256 price,) = oracle.getLatestPrice();
        assertEq(price, 2000e8);
    }

    // =====================================================
    // CIRCUIT BREAKER TESTS
    // =====================================================

    function test_CircuitBreaker_NoTriggerOnFirstPrice() public {
        // First price fetch should not trigger circuit breaker
        mockPriceFeed.setPrice(2000e8);

        (uint256 price,) = oracle.getLatestPrice();
        assertEq(price, 2000e8);
        assertEq(oracle.circuitBreakerTriggered(), false);
    }

    function test_CircuitBreaker_NoTriggerOnSmallDeviation() public {
        // First price: $2000
        mockPriceFeed.setPrice(2000e8);
        oracle.getLatestPrice();

        // Second price: $2500 (25% increase, below 50% threshold)
        mockPriceFeed.setPrice(2500e8);
        (uint256 price,) = oracle.getLatestPrice();

        assertEq(price, 2500e8);
        assertEq(oracle.circuitBreakerTriggered(), false);
    }

    function test_CircuitBreaker_TriggerOnLargeIncrease() public {
        // First price: $2000
        mockPriceFeed.setPrice(2000e8);
        oracle.getLatestPrice();

        // Second price: $3500 (75% increase, exceeds 50% threshold)
        mockPriceFeed.setPrice(3500e8);

        vm.expectEmit(true, true, true, true);
        emit CircuitBreakerTriggered(3500e8, 7500); // 75% = 7500 basis points

        vm.expectRevert(
            abi.encodeWithSelector(
                Project18Solution.ExcessivePriceDeviation.selector,
                7500
            )
        );
        oracle.getLatestPrice();

        assertEq(oracle.circuitBreakerTriggered(), true);
    }

    function test_CircuitBreaker_TriggerOnLargeDecrease() public {
        // First price: $2000
        mockPriceFeed.setPrice(2000e8);
        oracle.getLatestPrice();

        // Second price: $500 (75% decrease, exceeds 50% threshold)
        mockPriceFeed.setPrice(500e8);

        vm.expectRevert();
        oracle.getLatestPrice();

        assertEq(oracle.circuitBreakerTriggered(), true);
    }

    function test_CircuitBreaker_ExactlyAtThreshold() public {
        // First price: $2000
        mockPriceFeed.setPrice(2000e8);
        oracle.getLatestPrice();

        // Second price: $3000 (exactly 50% increase)
        mockPriceFeed.setPrice(3000e8);

        (uint256 price,) = oracle.getLatestPrice();
        assertEq(price, 3000e8);
        assertEq(oracle.circuitBreakerTriggered(), false);
    }

    function test_CircuitBreaker_ManualTrigger() public {
        vm.expectEmit(true, true, true, true);
        emit CircuitBreakerTriggered(0, 0);

        oracle.triggerCircuitBreaker();

        assertEq(oracle.circuitBreakerTriggered(), true);
    }

    function test_CircuitBreaker_Reset() public {
        // Trigger circuit breaker
        oracle.triggerCircuitBreaker();
        assertEq(oracle.circuitBreakerTriggered(), true);

        // Reset
        vm.expectEmit(true, true, true, true);
        emit CircuitBreakerReset();

        oracle.resetCircuitBreaker();

        assertEq(oracle.circuitBreakerTriggered(), false);
    }

    function test_RevertWhen_GetPriceWhilePaused() public {
        // Trigger circuit breaker
        oracle.triggerCircuitBreaker();

        // Try to get price
        vm.expectRevert(Project18Solution.CircuitBreakerActive.selector);
        oracle.getLatestPrice();
    }

    // =====================================================
    // ACCESS CONTROL TESTS
    // =====================================================

    function test_RevertWhen_NonOwnerTriggersCircuitBreaker() public {
        vm.prank(user);
        vm.expectRevert(Project18Solution.Unauthorized.selector);
        oracle.triggerCircuitBreaker();
    }

    function test_RevertWhen_NonOwnerResetsCircuitBreaker() public {
        oracle.triggerCircuitBreaker();

        vm.prank(user);
        vm.expectRevert(Project18Solution.Unauthorized.selector);
        oracle.resetCircuitBreaker();
    }

    function test_RevertWhen_NonOwnerUpdatesConfig() public {
        vm.prank(user);
        vm.expectRevert(Project18Solution.Unauthorized.selector);
        oracle.updateConfig(2 hours, 3000, 50e8, 20000e8);
    }

    // =====================================================
    // CONFIGURATION UPDATE TESTS
    // =====================================================

    function test_UpdateConfig() public {
        vm.expectEmit(true, true, true, true);
        emit ConfigUpdated(2 hours, 3000, 50e8, 20000e8);

        oracle.updateConfig(2 hours, 3000, 50e8, 20000e8);

        assertEq(oracle.stalenessThreshold(), 2 hours);
        assertEq(oracle.maxPriceDeviation(), 3000);
        assertEq(oracle.minPrice(), 50e8);
        assertEq(oracle.maxPrice(), 20000e8);
    }

    function test_RevertWhen_InvalidConfigMinMaxPrice() public {
        vm.expectRevert(Project18Solution.InvalidConfiguration.selector);
        oracle.updateConfig(2 hours, 3000, 20000e8, 50e8); // min > max
    }

    function test_RevertWhen_InvalidConfigZeroThreshold() public {
        vm.expectRevert(Project18Solution.InvalidConfiguration.selector);
        oracle.updateConfig(0, 3000, 50e8, 20000e8);
    }

    function test_UpdatePriceFeed() public {
        MockAggregatorV3 newPriceFeed = new MockAggregatorV3(8, "BTC / USD");

        oracle.updatePriceFeed(address(newPriceFeed));

        assertEq(address(oracle.priceFeed()), address(newPriceFeed));
        // Should reset lastPrice
        assertEq(oracle.lastPrice(), 0);
    }

    function test_TransferOwnership() public {
        address newOwner = address(0x2);

        oracle.transferOwnership(newOwner);

        assertEq(oracle.owner(), newOwner);
    }

    // =====================================================
    // CALCULATION EXAMPLE TESTS
    // =====================================================

    function test_CalculateUSDValue() public {
        mockPriceFeed.setPrice(2000e8); // $2000 per ETH

        // 1 ETH = 1e18 wei
        uint256 usdValue = oracle.calculateUSDValue(1e18);

        // Expected: 2000e8 (2000 USD with 8 decimals)
        assertEq(usdValue, 2000e8);
    }

    function test_CalculateUSDValue_Fractional() public {
        mockPriceFeed.setPrice(2000e8); // $2000 per ETH

        // 0.5 ETH = 0.5e18 wei
        uint256 usdValue = oracle.calculateUSDValue(0.5e18);

        // Expected: 1000e8 (1000 USD with 8 decimals)
        assertEq(usdValue, 1000e8);
    }

    function test_CalculateAssetAmount() public {
        mockPriceFeed.setPrice(2000e8); // $2000 per ETH

        // $4000 USD
        uint256 assetAmount = oracle.calculateAssetAmount(4000e8);

        // Expected: 2e18 (2 ETH)
        assertEq(assetAmount, 2e18);
    }

    // =====================================================
    // EDGE CASE TESTS
    // =====================================================

    function test_MultipleSequentialPriceUpdates() public {
        // Update 1
        mockPriceFeed.setPrice(2000e8);
        oracle.getLatestPrice();

        vm.warp(block.timestamp + 10 minutes);

        // Update 2
        mockPriceFeed.setPrice(2100e8);
        oracle.getLatestPrice();

        vm.warp(block.timestamp + 10 minutes);

        // Update 3
        mockPriceFeed.setPrice(2200e8);
        (uint256 price,) = oracle.getLatestPrice();

        assertEq(price, 2200e8);
        assertEq(oracle.lastPrice(), 2200e8);
    }

    function test_PriceWithDifferentDecimals() public {
        // Create new mock with 18 decimals (unusual for USD pairs)
        MockAggregatorV3 newPriceFeed = new MockAggregatorV3(18, "ETH / USD");
        newPriceFeed.setPrice(2000e18);

        Project18Solution newOracle = new Project18Solution(
            address(newPriceFeed),
            STALENESS_THRESHOLD,
            MAX_PRICE_DEVIATION,
            100e18, // Adjust min/max for 18 decimals
            10000e18
        );

        (uint256 price, uint8 decimals) = newOracle.getLatestPrice();

        assertEq(price, 2000e18);
        assertEq(decimals, 18);
    }

    // =====================================================
    // FUZZ TESTS
    // =====================================================

    function testFuzz_GetPrice(int256 price) public {
        // Bound price to valid range
        vm.assume(price >= int256(MIN_PRICE) && price <= int256(MAX_PRICE));

        mockPriceFeed.setPrice(price);

        (uint256 fetchedPrice,) = oracle.getLatestPrice();
        assertEq(fetchedPrice, uint256(price));
    }

    function testFuzz_CircuitBreakerDeviation(uint256 initialPrice, uint256 newPrice) public {
        // Bound to valid range
        initialPrice = bound(initialPrice, MIN_PRICE, MAX_PRICE);
        newPrice = bound(newPrice, MIN_PRICE, MAX_PRICE);

        // Set initial price
        mockPriceFeed.setPrice(int256(initialPrice));
        oracle.getLatestPrice();

        // Set new price
        mockPriceFeed.setPrice(int256(newPrice));

        // Calculate expected deviation
        uint256 diff = newPrice > initialPrice
            ? newPrice - initialPrice
            : initialPrice - newPrice;
        uint256 deviation = (diff * 10000) / initialPrice;

        if (deviation > MAX_PRICE_DEVIATION) {
            // Should trigger circuit breaker
            vm.expectRevert();
            oracle.getLatestPrice();
        } else {
            // Should succeed
            (uint256 price,) = oracle.getLatestPrice();
            assertEq(price, newPrice);
        }
    }

    // =====================================================
    // GAS BENCHMARKS
    // =====================================================

    function test_GasBenchmark_GetLatestPrice() public {
        mockPriceFeed.setPrice(2000e8);

        uint256 gasBefore = gasleft();
        oracle.getLatestPrice();
        uint256 gasUsed = gasBefore - gasleft();

        // Log for reference
        emit log_named_uint("Gas used for getLatestPrice", gasUsed);
    }

    function test_GasBenchmark_ViewLatestPrice() public {
        mockPriceFeed.setPrice(2000e8);

        uint256 gasBefore = gasleft();
        oracle.viewLatestPrice();
        uint256 gasUsed = gasBefore - gasleft();

        emit log_named_uint("Gas used for viewLatestPrice", gasUsed);
    }
}

/**
 * ============================================================================
 * TEST COVERAGE SUMMARY
 * ============================================================================
 *
 * ✅ Basic Functionality
 *    - Constructor initialization
 *    - Price retrieval (state-changing and view)
 *    - Description fetching
 *
 * ✅ Staleness Detection
 *    - Reject stale prices
 *    - Accept fresh prices
 *    - Edge cases (exactly at threshold)
 *
 * ✅ Price Validation
 *    - Reject zero/negative prices
 *    - Reject out-of-bounds prices
 *    - Accept valid prices at boundaries
 *
 * ✅ Round Completeness
 *    - Reject incomplete rounds
 *    - Accept complete rounds
 *
 * ✅ Circuit Breaker
 *    - No trigger on first price
 *    - No trigger on small deviations
 *    - Trigger on large increases
 *    - Trigger on large decreases
 *    - Manual trigger/reset
 *    - Pause functionality
 *
 * ✅ Access Control
 *    - Only owner can trigger/reset circuit breaker
 *    - Only owner can update config
 *    - Ownership transfer
 *
 * ✅ Configuration Updates
 *    - Valid updates
 *    - Invalid parameter rejection
 *    - Price feed updates
 *
 * ✅ Calculation Examples
 *    - USD value calculation
 *    - Asset amount calculation
 *
 * ✅ Edge Cases
 *    - Multiple sequential updates
 *    - Different decimal configurations
 *
 * ✅ Fuzz Testing
 *    - Random valid prices
 *    - Random deviations
 *
 * ✅ Gas Benchmarks
 *    - State-changing calls
 *    - View calls
 *
 * ============================================================================
 */
