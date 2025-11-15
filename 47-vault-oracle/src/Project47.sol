// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title Project47 - Vault Oracle Integration
 * @notice A vault that uses oracle price feeds to value deposits
 * @dev Learn to safely integrate oracles for vault pricing
 *
 * LEARNING OBJECTIVES:
 * 1. Integrate Chainlink price feeds safely
 * 2. Implement TWAP (Time-Weighted Average Price)
 * 3. Handle stale oracle data
 * 4. Implement price deviation limits
 * 5. Build circuit breaker mechanisms
 * 6. Use multi-oracle strategies
 *
 * SECURITY CONSIDERATIONS:
 * - Always check oracle data freshness
 * - Validate price data before use
 * - Implement bounds checking
 * - Have fallback mechanisms
 * - Use TWAP for manipulation resistance
 */

// Simple price oracle interface
interface IPriceOracle {
    function getPrice() external view returns (uint256);
    function updatePrice(uint256 newPrice) external;
}

contract Project47 is ERC20, Ownable {
    // ============================================
    // STATE VARIABLES
    // ============================================

    /// @notice The token this vault accepts
    IERC20 public immutable asset;

    /// @notice Primary Chainlink price feed
    AggregatorV3Interface public priceFeed;

    /// @notice Fallback oracle
    IPriceOracle public fallbackOracle;

    /// @notice Maximum age of oracle data (e.g., 1 hour)
    uint256 public maxStaleness;

    /// @notice Maximum allowed price deviation (basis points, e.g., 1000 = 10%)
    uint256 public maxPriceDeviation;

    /// @notice Last validated price
    uint256 public lastValidPrice;

    /// @notice Timestamp of last valid price
    uint256 public lastPriceUpdate;

    /// @notice Circuit breaker - pause operations if oracle fails
    bool public emergencyShutdown;

    // TWAP tracking
    struct Observation {
        uint256 timestamp;
        uint256 price;
        uint256 cumulativePrice;
    }

    /// @notice Ring buffer of price observations
    Observation[] public observations;

    /// @notice Current index in ring buffer
    uint256 public observationIndex;

    /// @notice Maximum observations to store
    uint256 public constant MAX_OBSERVATIONS = 24; // 24 hours if updated hourly

    // ============================================
    // EVENTS
    // ============================================

    event Deposit(address indexed user, uint256 assets, uint256 shares);
    event Withdraw(address indexed user, uint256 assets, uint256 shares);
    event PriceUpdated(uint256 newPrice, uint256 timestamp);
    event OracleFailed(string reason);
    event EmergencyShutdown(bool status);
    event OracleUpdated(address indexed newOracle);

    // ============================================
    // ERRORS
    // ============================================

    error StalePrice();
    error InvalidPrice();
    error PriceDeviationTooHigh();
    error EmergencyShutdownActive();
    error ZeroAmount();
    error InsufficientShares();

    // ============================================
    // CONSTRUCTOR
    // ============================================

    constructor(
        address _asset,
        address _priceFeed,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) Ownable(msg.sender) {
        asset = IERC20(_asset);
        priceFeed = AggregatorV3Interface(_priceFeed);

        // TODO: Set reasonable defaults
        maxStaleness = 1 hours;
        maxPriceDeviation = 1000; // 10%

        // TODO: Initialize first observation
        // Hint: Create first TWAP observation with initial price
    }

    // ============================================
    // ORACLE FUNCTIONS
    // ============================================

    /**
     * @notice Get validated price from Chainlink oracle
     * @return price The current price
     * @return isValid Whether the price is valid
     */
    function getChainlinkPrice() public view returns (uint256 price, bool isValid) {
        // TODO: Implement Chainlink price fetching with validation
        // Steps:
        // 1. Call priceFeed.latestRoundData()
        // 2. Check if data is stale (updatedAt)
        // 3. Check if price is valid (answer > 0)
        // 4. Check if round is complete (answeredInRound >= roundId)
        // 5. Normalize decimals to 18
        // Hint: Use _isStale() and _normalizeDecimals() helpers
    }

    /**
     * @notice Check if oracle data is stale
     * @param updatedAt Timestamp of last update
     * @return Whether data is stale
     */
    function _isStale(uint256 updatedAt) internal view returns (bool) {
        // TODO: Implement staleness check
        // Hint: Compare block.timestamp - updatedAt with maxStaleness
    }

    /**
     * @notice Normalize Chainlink price to 18 decimals
     * @param price The raw price from Chainlink
     * @return Normalized price
     */
    function _normalizeDecimals(int256 price) internal view returns (uint256) {
        // TODO: Implement decimal normalization
        // Hint: Get decimals from priceFeed.decimals()
        // Convert to 18 decimals
    }

    /**
     * @notice Get price with fallback mechanism
     * @return Final validated price
     */
    function getValidatedPrice() public view returns (uint256) {
        // TODO: Implement multi-oracle price retrieval
        // Steps:
        // 1. Try to get Chainlink price
        // 2. If valid, check deviation from last price
        // 3. If invalid or deviation too high, try fallback oracle
        // 4. If all fail and emergency shutdown not active, use last valid price
        // 5. Ensure returned price is reasonable
    }

    /**
     * @notice Check if price deviation is acceptable
     * @param newPrice New price to check
     * @param referencePrice Reference price to compare against
     * @return Whether deviation is within limits
     */
    function _isDeviationAcceptable(uint256 newPrice, uint256 referencePrice)
        internal
        view
        returns (bool)
    {
        // TODO: Implement deviation check
        // Calculate percentage difference
        // Compare with maxPriceDeviation
        // Hint: Use basis points (10000 = 100%)
    }

    // ============================================
    // TWAP FUNCTIONS
    // ============================================

    /**
     * @notice Update price observation for TWAP
     * @param price Current price to record
     */
    function updateObservation(uint256 price) public onlyOwner {
        // TODO: Implement TWAP observation update
        // Steps:
        // 1. Calculate cumulative price
        // 2. Create new observation
        // 3. Store in ring buffer
        // 4. Update index
        // 5. Emit event
    }

    /**
     * @notice Calculate TWAP over a time period
     * @param period Time period in seconds
     * @return TWAP price
     */
    function getTWAP(uint256 period) public view returns (uint256) {
        // TODO: Implement TWAP calculation
        // Steps:
        // 1. Find observation at (current time - period)
        // 2. Get current observation
        // 3. Calculate: (currentCumulative - oldCumulative) / timeDelta
        // Hint: Handle case when not enough observations exist
    }

    /**
     * @notice Get observation at a specific timestamp (or closest before)
     * @param targetTime Target timestamp
     * @return Closest observation before target time
     */
    function _getObservationAt(uint256 targetTime) internal view returns (Observation memory) {
        // TODO: Implement observation lookup
        // Search through ring buffer for closest observation before targetTime
        // Hint: Start from current index and go backwards
    }

    // ============================================
    // VAULT FUNCTIONS
    // ============================================

    /**
     * @notice Deposit assets into vault
     * @param assets Amount of assets to deposit
     * @return shares Number of shares minted
     */
    function deposit(uint256 assets) external returns (uint256 shares) {
        // TODO: Implement deposit with oracle pricing
        // Steps:
        // 1. Check for emergency shutdown
        // 2. Validate amount > 0
        // 3. Get validated price
        // 4. Calculate shares based on current price
        // 5. Transfer assets from user
        // 6. Mint shares to user
        // 7. Emit event
        // Hint: shares = assets * price / precision
    }

    /**
     * @notice Withdraw assets from vault
     * @param shares Number of shares to burn
     * @return assets Amount of assets withdrawn
     */
    function withdraw(uint256 shares) external returns (uint256 assets) {
        // TODO: Implement withdrawal with oracle pricing
        // Steps:
        // 1. Check user has enough shares
        // 2. Get validated price (use TWAP for safety)
        // 3. Calculate assets based on shares and price
        // 4. Burn shares from user
        // 5. Transfer assets to user
        // 6. Emit event
    }

    /**
     * @notice Preview deposit amount
     * @param assets Amount of assets
     * @return shares Expected shares to receive
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares) {
        // TODO: Calculate expected shares for deposit
        // Use current validated price
    }

    /**
     * @notice Preview withdrawal amount
     * @param shares Amount of shares
     * @return assets Expected assets to receive
     */
    function previewWithdraw(uint256 shares) external view returns (uint256 assets) {
        // TODO: Calculate expected assets for withdrawal
        // Use TWAP price for safety
    }

    /**
     * @notice Calculate total value of vault in asset terms
     * @return Total value using oracle price
     */
    function totalValue() public view returns (uint256) {
        // TODO: Calculate total vault value
        // Get asset balance and convert using oracle price
    }

    /**
     * @notice Calculate price per share
     * @return Price per share in assets
     */
    function pricePerShare() public view returns (uint256) {
        // TODO: Calculate current price per share
        // Handle case when totalSupply is 0
    }

    // ============================================
    // ADMIN FUNCTIONS
    // ============================================

    /**
     * @notice Update Chainlink price feed address
     * @param newPriceFeed New price feed address
     */
    function updatePriceFeed(address newPriceFeed) external onlyOwner {
        // TODO: Update price feed with validation
        require(newPriceFeed != address(0), "Invalid address");
        priceFeed = AggregatorV3Interface(newPriceFeed);
        emit OracleUpdated(newPriceFeed);
    }

    /**
     * @notice Update fallback oracle
     * @param newFallbackOracle New fallback oracle address
     */
    function updateFallbackOracle(address newFallbackOracle) external onlyOwner {
        // TODO: Update fallback oracle
        fallbackOracle = IPriceOracle(newFallbackOracle);
    }

    /**
     * @notice Update maximum staleness threshold
     * @param newMaxStaleness New maximum staleness in seconds
     */
    function updateMaxStaleness(uint256 newMaxStaleness) external onlyOwner {
        // TODO: Update staleness threshold with validation
        require(newMaxStaleness > 0 && newMaxStaleness <= 24 hours, "Invalid staleness");
        maxStaleness = newMaxStaleness;
    }

    /**
     * @notice Update maximum price deviation
     * @param newMaxDeviation New maximum deviation in basis points
     */
    function updateMaxDeviation(uint256 newMaxDeviation) external onlyOwner {
        // TODO: Update deviation threshold with validation
        require(newMaxDeviation <= 5000, "Deviation too high"); // Max 50%
        maxPriceDeviation = newMaxDeviation;
    }

    /**
     * @notice Trigger emergency shutdown
     * @param status Whether to activate shutdown
     */
    function setEmergencyShutdown(bool status) external onlyOwner {
        // TODO: Implement emergency shutdown
        emergencyShutdown = status;
        emit EmergencyShutdown(status);
    }

    /**
     * @notice Emergency withdraw (when shutdown active)
     * @dev Allows withdrawal at last known price
     */
    function emergencyWithdraw(uint256 shares) external {
        // TODO: Implement emergency withdrawal
        // Allow users to exit using last valid price
        // Only when emergency shutdown is active
    }
}
