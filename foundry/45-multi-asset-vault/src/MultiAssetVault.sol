// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Multi-Asset Vault
 * @notice A vault that holds multiple ERC20 tokens with weighted allocations
 * @dev Implements index fund patterns with dynamic rebalancing
 *
 * Learning Objectives:
 * 1. Understand multi-asset vault design
 * 2. Implement weighted NAV calculations
 * 3. Build rebalancing mechanisms
 * 4. Integrate price oracles
 * 5. Handle slippage in swaps
 */

// Simple price oracle interface (Chainlink-style)
interface IPriceOracle {
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function decimals() external view returns (uint8);
}

// Simple DEX interface for rebalancing
interface IDEXRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
}

contract MultiAssetVault is ERC20, Ownable, ReentrancyGuard {
    // ========== STRUCTS ==========

    struct Asset {
        address token; // ERC20 token address
        uint256 targetWeight; // Target weight in basis points (10000 = 100%)
        address priceOracle; // Chainlink price feed address
        bool active; // Whether asset is currently in basket
    }

    // ========== STATE VARIABLES ==========

    // Asset configuration
    Asset[] public assets;
    mapping(address => uint256) public assetIndex; // token => index in assets array
    mapping(address => bool) public isAsset; // Quick lookup for valid assets

    // Rebalancing configuration
    uint256 public rebalanceThreshold; // Max deviation from target (basis points)
    uint256 public lastRebalanceTime;
    uint256 public minRebalanceInterval; // Minimum time between rebalances
    address public dexRouter; // Router for swaps during rebalancing

    // Deposit/Withdraw configuration
    address public baseAsset; // Primary asset for deposits (e.g., USDC)
    uint256 public depositFee; // Fee in basis points
    uint256 public withdrawFee; // Fee in basis points

    // Performance tracking
    uint256 public totalDeposited;
    uint256 public totalWithdrawn;
    uint256 public cumulativeSlippage; // Track slippage costs
    uint256 public rebalanceCount;

    // Constants
    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant MAX_ASSETS = 20;
    uint256 public constant PRICE_PRECISION = 1e18;

    // ========== EVENTS ==========

    event AssetAdded(address indexed token, uint256 targetWeight, address oracle);
    event AssetRemoved(address indexed token);
    event WeightUpdated(address indexed token, uint256 oldWeight, uint256 newWeight);
    event Deposited(address indexed user, uint256 assetAmount, uint256 shares, uint256 nav);
    event Withdrawn(address indexed user, uint256 shares, uint256 assetAmount, uint256 nav);
    event Rebalanced(
        address indexed fromAsset, address indexed toAsset, uint256 amountIn, uint256 amountOut, uint256 slippage
    );
    event ConfigUpdated(string param, uint256 value);

    // ========== CONSTRUCTOR ==========

    constructor(
        string memory name,
        string memory symbol,
        address _baseAsset,
        address _dexRouter,
        uint256 _rebalanceThreshold
    ) ERC20(name, symbol) Ownable(msg.sender) {
        require(_baseAsset != address(0), "Invalid base asset");
        require(_dexRouter != address(0), "Invalid DEX router");

        baseAsset = _baseAsset;
        dexRouter = _dexRouter;
        rebalanceThreshold = _rebalanceThreshold;
        minRebalanceInterval = 1 hours;
        depositFee = 10; // 0.1%
        withdrawFee = 10; // 0.1%
    }

    // ========== ASSET MANAGEMENT ==========

    /**
     * @notice Add a new asset to the vault basket
     * @param token The ERC20 token address
     * @param targetWeight Target allocation in basis points
     * @param oracle Price oracle address
     */
    function addAsset(address token, uint256 targetWeight, address oracle) external onlyOwner {
        // TODO: Implement asset addition
        // 1. Validate inputs (non-zero addresses, valid weight)
        // 2. Check total assets < MAX_ASSETS
        // 3. Verify total weights <= 100% after addition
        // 4. Add to assets array
        // 5. Update mappings
        // 6. Emit event
    }

    /**
     * @notice Remove an asset from the basket
     * @param token The token to remove
     */
    function removeAsset(address token) external onlyOwner {
        // TODO: Implement asset removal
        // 1. Validate asset exists
        // 2. Check current balance is zero (must sell first)
        // 3. Mark as inactive or remove from array
        // 4. Update mappings
        // 5. Emit event
    }

    /**
     * @notice Update target weight for an asset
     * @param token The asset to update
     * @param newWeight New target weight
     */
    function setTargetWeight(address token, uint256 newWeight) external onlyOwner {
        // TODO: Implement weight update
        // 1. Validate asset exists
        // 2. Update weight
        // 3. Verify total weights = 100%
        // 4. Emit event
    }

    // ========== NAV CALCULATION ==========

    /**
     * @notice Calculate total Net Asset Value of the vault
     * @return Total value in base asset terms
     */
    function calculateNAV() public view returns (uint256) {
        // TODO: Implement NAV calculation
        // 1. Loop through all active assets
        // 2. Get balance of each asset in vault
        // 3. Get price from oracle
        // 4. Calculate value = balance * price
        // 5. Sum all values
        // 6. Return total NAV
        return 0;
    }

    /**
     * @notice Get price per share
     * @return Price of one vault share in base asset terms
     */
    function getPricePerShare() public view returns (uint256) {
        // TODO: Implement price per share calculation
        // Handle edge case: totalSupply == 0
        return 0;
    }

    /**
     * @notice Get current value of a specific asset holding
     * @param token Asset address
     * @return Value in base asset terms
     */
    function getAssetValue(address token) public view returns (uint256) {
        // TODO: Implement asset value calculation
        // 1. Get balance
        // 2. Get price from oracle
        // 3. Handle decimal normalization
        // 4. Return balance * price
        return 0;
    }

    /**
     * @notice Get price from oracle with staleness check
     * @param oracle Oracle address
     * @return price Price with 18 decimal precision
     */
    function getOraclePrice(address oracle) public view returns (uint256) {
        // TODO: Implement oracle price fetching
        // 1. Call latestRoundData()
        // 2. Check price is positive
        // 3. Check price is fresh (updatedAt within acceptable range)
        // 4. Normalize to 18 decimals
        // 5. Return normalized price
        return 0;
    }

    // ========== CURRENT ALLOCATION ==========

    /**
     * @notice Calculate current weight of each asset
     * @return weights Array of current weights in basis points
     */
    function getCurrentWeights() public view returns (uint256[] memory weights) {
        // TODO: Implement current weight calculation
        // 1. Get total NAV
        // 2. For each asset, calculate: (assetValue / totalNAV) * 10000
        // 3. Return array of weights
    }

    /**
     * @notice Check if vault needs rebalancing
     * @return needsRebalance True if any asset is outside threshold
     */
    function needsRebalancing() public view returns (bool) {
        // TODO: Implement rebalancing check
        // 1. Get current weights
        // 2. Compare each to target weight
        // 3. If any deviation > threshold, return true
        // 4. Check minimum interval has passed
        return false;
    }

    // ========== DEPOSIT / WITHDRAW ==========

    /**
     * @notice Deposit base asset and receive vault shares
     * @param amount Amount of base asset to deposit
     * @return shares Number of shares minted
     */
    function deposit(uint256 amount) external nonReentrant returns (uint256 shares) {
        // TODO: Implement deposit
        // 1. Validate amount > 0
        // 2. Transfer base asset from user
        // 3. Calculate NAV before deposit
        // 4. Calculate shares to mint
        //    - If first deposit: shares = amount
        //    - Otherwise: shares = (amount * totalSupply) / NAV
        // 5. Apply deposit fee
        // 6. Mint shares to user
        // 7. Optionally allocate to basket (or wait for rebalance)
        // 8. Update tracking
        // 9. Emit event
    }

    /**
     * @notice Withdraw vault shares and receive proportional assets
     * @param shares Number of shares to burn
     * @return baseAmount Amount of base asset received
     */
    function withdraw(uint256 shares) external nonReentrant returns (uint256 baseAmount) {
        // TODO: Implement withdrawal
        // 1. Validate user has enough shares
        // 2. Calculate proportion of vault
        // 3. Option A: Return proportional basket of all assets
        // 4. Option B: Convert all to base asset and return
        // 5. Apply withdrawal fee
        // 6. Burn shares
        // 7. Transfer assets to user
        // 8. Update tracking
        // 9. Emit event
    }

    /**
     * @notice Preview how many shares would be minted for a deposit
     * @param amount Deposit amount
     * @return shares Shares that would be minted
     */
    function previewDeposit(uint256 amount) external view returns (uint256 shares) {
        // TODO: Implement deposit preview
        // Calculate shares without state changes
    }

    /**
     * @notice Preview how much base asset would be received for withdrawal
     * @param shares Shares to withdraw
     * @return amount Base asset amount
     */
    function previewWithdraw(uint256 shares) external view returns (uint256 amount) {
        // TODO: Implement withdrawal preview
        // Calculate withdrawal amount without state changes
    }

    // ========== REBALANCING ==========

    /**
     * @notice Rebalance vault to target weights
     */
    function rebalance() external {
        // TODO: Implement rebalancing
        // 1. Check needsRebalancing() returns true
        // 2. Calculate current weights
        // 3. Determine which assets to sell (over-weight)
        // 4. Determine which assets to buy (under-weight)
        // 5. Execute swaps through DEX
        // 6. Track slippage
        // 7. Update lastRebalanceTime
        // 8. Emit events
    }

    /**
     * @notice Execute a single rebalancing swap
     * @param fromAsset Asset to sell
     * @param toAsset Asset to buy
     * @param amountIn Amount to sell
     * @param minAmountOut Minimum amount to receive (slippage protection)
     */
    function executeRebalanceSwap(address fromAsset, address toAsset, uint256 amountIn, uint256 minAmountOut)
        internal
        returns (uint256 amountOut)
    {
        // TODO: Implement swap execution
        // 1. Approve DEX router
        // 2. Build swap path
        // 3. Execute swap
        // 4. Calculate and track slippage
        // 5. Emit event
        // 6. Return actual amount received
    }

    /**
     * @notice Calculate amounts needed for rebalancing
     * @return sells Array of amounts to sell per asset
     * @return buys Array of amounts to buy per asset
     */
    function calculateRebalanceAmounts()
        public
        view
        returns (uint256[] memory sells, uint256[] memory buys)
    {
        // TODO: Implement rebalance calculation
        // 1. Get total NAV
        // 2. For each asset:
        //    - Calculate target value = NAV * targetWeight / 10000
        //    - Calculate current value
        //    - If current > target: mark for selling
        //    - If current < target: mark for buying
        // 3. Return sell and buy arrays
    }

    // ========== ADMIN FUNCTIONS ==========

    function setRebalanceThreshold(uint256 _threshold) external onlyOwner {
        require(_threshold <= 1000, "Threshold too high"); // Max 10%
        rebalanceThreshold = _threshold;
        emit ConfigUpdated("rebalanceThreshold", _threshold);
    }

    function setMinRebalanceInterval(uint256 _interval) external onlyOwner {
        minRebalanceInterval = _interval;
        emit ConfigUpdated("minRebalanceInterval", _interval);
    }

    function setDepositFee(uint256 _fee) external onlyOwner {
        require(_fee <= 100, "Fee too high"); // Max 1%
        depositFee = _fee;
        emit ConfigUpdated("depositFee", _fee);
    }

    function setWithdrawFee(uint256 _fee) external onlyOwner {
        require(_fee <= 100, "Fee too high"); // Max 1%
        withdrawFee = _fee;
        emit ConfigUpdated("withdrawFee", _fee);
    }

    // ========== VIEW FUNCTIONS ==========

    function getAssetCount() external view returns (uint256) {
        return assets.length;
    }

    function getAsset(uint256 index) external view returns (Asset memory) {
        return assets[index];
    }

    function getTotalWeight() public view returns (uint256 total) {
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i].active) {
                total += assets[i].targetWeight;
            }
        }
    }

    function getPerformanceMetrics()
        external
        view
        returns (uint256 avgSlippage, uint256 deposited, uint256 withdrawn, uint256 rebalances)
    {
        avgSlippage = rebalanceCount > 0 ? cumulativeSlippage / rebalanceCount : 0;
        deposited = totalDeposited;
        withdrawn = totalWithdrawn;
        rebalances = rebalanceCount;
    }

    // ========== HELPER FUNCTIONS ==========

    /**
     * @notice Allocate deposited funds to basket according to target weights
     * @param amount Amount to allocate
     */
    function allocateToBasket(uint256 amount) internal {
        // TODO: Implement basket allocation
        // 1. For each asset, calculate: amount * targetWeight / 10000
        // 2. Swap base asset for target amount of each asset
        // 3. Handle slippage
    }

    /**
     * @notice Convert all assets to base asset
     * @return totalBase Total base asset amount
     */
    function convertAllToBase() internal returns (uint256 totalBase) {
        // TODO: Implement conversion to base
        // 1. For each non-base asset
        // 2. Swap entire balance to base asset
        // 3. Sum total received
    }
}
