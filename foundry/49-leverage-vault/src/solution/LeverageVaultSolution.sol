// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Leverage Looping Vault - Complete Solution
 * @notice A sophisticated DeFi vault implementing leveraged yield strategies
 * @dev This solution demonstrates production-ready leverage looping with comprehensive risk management
 *
 * Architecture Overview:
 * ┌─────────────────────────────────────────────────────────────┐
 * │                     User Deposits                            │
 * └──────────────────────┬──────────────────────────────────────┘
 *                        │
 *                        ▼
 * ┌─────────────────────────────────────────────────────────────┐
 * │               Leverage Loop Vault                            │
 * │  ┌────────────────────────────────────────────────────┐    │
 * │  │  Loop: Deposit → Borrow → Deposit → Borrow...      │    │
 * │  │  Target: 4x leverage at 75% LTV                    │    │
 * │  │  Safety: Maintain HF > 1.5                         │    │
 * │  └────────────────────────────────────────────────────┘    │
 * └──────────────────────┬──────────────────────────────────────┘
 *                        │
 *                        ▼
 * ┌─────────────────────────────────────────────────────────────┐
 * │              Lending Pool (Aave/Compound)                    │
 * │  Collateral: ~400 ETH    Debt: ~300 ETH                     │
 * └─────────────────────────────────────────────────────────────┘
 */

interface ILendingPool {
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
    function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf)
        external;
    function repay(address asset, uint256 amount, uint256 rateMode, address onBehalfOf) external returns (uint256);
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );
}

interface IPriceOracle {
    function getAssetPrice(address asset) external view returns (uint256);
}

contract LeverageLoopingVaultSolution is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============================================
    // State Variables
    // ============================================

    IERC20 public immutable asset;
    ILendingPool public immutable lendingPool;
    IPriceOracle public immutable priceOracle;

    /// @notice Target leverage ratio in basis points (e.g., 400 = 4x)
    uint256 public targetLeverage;

    /// @notice Target LTV in basis points (e.g., 7500 = 75%)
    uint256 public targetLTV;

    /// @notice Minimum health factor to maintain (e.g., 1.5e18)
    uint256 public minHealthFactor;

    /// @notice Rebalance threshold in basis points (e.g., 200 = 2%)
    uint256 public rebalanceThreshold;

    uint256 public totalDeposits;
    mapping(address => uint256) public userDeposits;

    bool public paused;

    // ============================================
    // Constants
    // ============================================

    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant RATE_MODE_VARIABLE = 2;
    uint256 public constant HEALTH_FACTOR_DECIMALS = 18;
    uint256 public constant MAX_ITERATIONS = 10; // Safety limit

    // ============================================
    // Events
    // ============================================

    event Deposited(address indexed user, uint256 amount, uint256 newBalance);
    event Withdrawn(address indexed user, uint256 amount, uint256 newBalance);
    event Leveraged(uint256 iterations, uint256 finalLeverage, uint256 healthFactor);
    event Deleveraged(uint256 iterations, uint256 finalLeverage, uint256 healthFactor);
    event Rebalanced(uint256 oldLTV, uint256 newLTV, uint256 healthFactor);
    event EmergencyDeleveraged(uint256 healthFactor, uint256 newLeverage);
    event ParametersUpdated(uint256 targetLeverage, uint256 targetLTV, uint256 minHealthFactor);
    event Paused();
    event Unpaused();

    // ============================================
    // Errors
    // ============================================

    error ZeroAmount();
    error InsufficientBalance();
    error VaultPaused();
    error UnsafeParameters();
    error HealthFactorTooLow();
    error RebalanceNotNeeded();

    // ============================================
    // Constructor
    // ============================================

    constructor(
        address _asset,
        address _lendingPool,
        address _priceOracle,
        uint256 _targetLeverage,
        uint256 _targetLTV,
        uint256 _minHealthFactor
    ) Ownable(msg.sender) {
        require(_targetLeverage >= BASIS_POINTS, "Leverage must be >= 1x");
        require(_targetLTV < BASIS_POINTS, "LTV must be < 100%");
        require(_minHealthFactor >= 1e18, "Min HF must be >= 1.0");

        asset = IERC20(_asset);
        lendingPool = ILendingPool(_lendingPool);
        priceOracle = IPriceOracle(_priceOracle);
        targetLeverage = _targetLeverage;
        targetLTV = _targetLTV;
        minHealthFactor = _minHealthFactor;
        rebalanceThreshold = 200; // 2% default

        // Approve lending pool for maximum efficiency
        asset.approve(_lendingPool, type(uint256).max);
    }

    // ============================================
    // User Functions
    // ============================================

    /**
     * @notice Deposit assets and execute leverage loop
     * @param amount Amount to deposit
     *
     * Process:
     * 1. Transfer assets from user
     * 2. Execute leverage loop on deposited amount
     * 3. Update user's position
     *
     * Example: Depositing 100 ETH with 4x target leverage
     * - Initial deposit: 100 ETH
     * - Loop executes ~5 iterations
     * - Final position: ~400 ETH collateral, ~300 ETH debt
     */
    function deposit(uint256 amount) external nonReentrant {
        if (paused) revert VaultPaused();
        if (amount == 0) revert ZeroAmount();

        // Transfer assets from user
        asset.safeTransferFrom(msg.sender, address(this), amount);

        // Update user's position
        userDeposits[msg.sender] += amount;
        totalDeposits += amount;

        // Execute leverage loop to amplify the position
        executeLeverageLoop(amount);

        emit Deposited(msg.sender, amount, userDeposits[msg.sender]);
    }

    /**
     * @notice Withdraw assets by deleveraging position proportionally
     * @param amount Amount to withdraw
     *
     * Process:
     * 1. Calculate user's share of total position
     * 2. Deleverage proportionally
     * 3. Transfer assets to user
     *
     * Example: Withdrawing 50 ETH from 100 ETH position
     * - Current leverage: 4x (400 collateral, 300 debt)
     * - Need to deleverage 50% of position
     * - Withdraw and repay proportionally
     */
    function withdraw(uint256 amount) external nonReentrant {
        if (paused) revert VaultPaused();
        if (amount == 0) revert ZeroAmount();
        if (userDeposits[msg.sender] < amount) revert InsufficientBalance();

        // Calculate how much to deleverage
        // User's share of total position
        uint256 shareToWithdraw = (amount * BASIS_POINTS) / totalDeposits;

        // Execute deleverage to free up the amount
        executeDeleverageLoop(shareToWithdraw);

        // Update balances
        userDeposits[msg.sender] -= amount;
        totalDeposits -= amount;

        // Transfer assets to user
        asset.safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount, userDeposits[msg.sender]);
    }

    // ============================================
    // Leverage Functions
    // ============================================

    /**
     * @notice Execute leverage loop to reach target leverage
     * @param initialAmount Amount to start leveraging
     *
     * Algorithm:
     * 1. Deposit initial amount as collateral
     * 2. Loop (max 10 iterations):
     *    a. Calculate safe borrow amount based on target LTV
     *    b. Borrow from lending pool
     *    c. Deposit borrowed amount as additional collateral
     *    d. Check if target leverage reached
     * 3. Verify final health factor is safe
     *
     * Math:
     * Each iteration: borrow = collateral × targetLTV
     * After N iterations: total_collateral = initial × Σ(ltv^i) for i=0 to N-1
     * This approaches: initial / (1 - ltv) as N → ∞
     *
     * Example with 75% LTV, starting with 100:
     * Iteration 0: Deposit 100, borrow 75
     * Iteration 1: Deposit 75, borrow 56.25
     * Iteration 2: Deposit 56.25, borrow 42.19
     * Iteration 3: Deposit 42.19, borrow 31.64
     * Iteration 4: Deposit 31.64, borrow 23.73
     * Final: ~305 collateral, ~229 debt, ~4x leverage
     */
    function executeLeverageLoop(uint256 initialAmount) internal {
        if (initialAmount == 0) return;

        // Deposit initial amount
        lendingPool.deposit(address(asset), initialAmount, address(this), 0);

        uint256 iterations = 0;
        uint256 currentLeverage = BASIS_POINTS; // Start at 1x

        // Execute leverage loop
        while (currentLeverage < targetLeverage && iterations < MAX_ITERATIONS) {
            // Calculate how much we can safely borrow
            uint256 borrowAmount = calculateMaxBorrow();

            if (borrowAmount == 0) break;

            // Borrow from lending pool (variable rate)
            lendingPool.borrow(address(asset), borrowAmount, RATE_MODE_VARIABLE, 0, address(this));

            // Deposit borrowed amount to increase collateral
            lendingPool.deposit(address(asset), borrowAmount, address(this), 0);

            // Update current leverage
            currentLeverage = getCurrentLeverage();
            iterations++;

            // Safety check: ensure health factor is still safe
            uint256 hf = getHealthFactor();
            if (hf < minHealthFactor) {
                revert HealthFactorTooLow();
            }
        }

        uint256 finalHF = getHealthFactor();
        emit Leveraged(iterations, currentLeverage, finalHF);
    }

    /**
     * @notice Execute deleverage loop to reduce position
     * @param shareToDeleverage Share of position to deleverage (in basis points)
     *
     * Algorithm:
     * 1. Calculate target debt reduction
     * 2. Loop until target reached:
     *    a. Withdraw safe amount of collateral
     *    b. Repay debt with withdrawn collateral
     *    c. Check health factor remains safe
     * 3. Verify final state
     *
     * Important: We withdraw and repay in lockstep to maintain safe health factor
     * throughout the process. Never let HF drop below minimum.
     *
     * Example: Deleverage 50% of position
     * Current: 400 collateral, 300 debt
     * Target: 200 collateral, 150 debt
     * Loop: Withdraw 50 → Repay 50 (repeat 4x)
     */
    function executeDeleverageLoop(uint256 shareToDeleverage) internal {
        if (shareToDeleverage == 0) return;

        (uint256 totalCollateral, uint256 totalDebt,,,,) = lendingPool.getUserAccountData(address(this));

        // Calculate target debt after deleverage
        uint256 targetDebt = totalDebt - (totalDebt * shareToDeleverage / BASIS_POINTS);

        uint256 iterations = 0;

        // Execute deleverage loop
        while (totalDebt > targetDebt && iterations < MAX_ITERATIONS) {
            // Calculate safe withdraw amount (maintains min health factor)
            uint256 withdrawAmount = calculateMaxWithdraw();

            if (withdrawAmount == 0) break;

            // Calculate how much to actually withdraw and repay this iteration
            uint256 debtToRepay = min(withdrawAmount, totalDebt - targetDebt);

            // Withdraw collateral
            lendingPool.withdraw(address(asset), debtToRepay, address(this));

            // Repay debt
            lendingPool.repay(address(asset), debtToRepay, RATE_MODE_VARIABLE, address(this));

            // Update totals
            (, totalDebt,,,,) = lendingPool.getUserAccountData(address(this));
            iterations++;
        }

        uint256 finalLeverage = getCurrentLeverage();
        uint256 finalHF = getHealthFactor();
        emit Deleveraged(iterations, finalLeverage, finalHF);
    }

    /**
     * @notice Calculate maximum safe borrow amount
     * @return maxBorrow Maximum amount that can be borrowed safely
     *
     * Calculation:
     * 1. Get current collateral from lending pool
     * 2. Calculate target debt: collateral × targetLTV
     * 3. Subtract current debt to get available borrow
     * 4. Apply safety buffer (use 95% of available to stay safe)
     *
     * Example:
     * Collateral: 100 ETH
     * Current Debt: 50 ETH
     * Target LTV: 75%
     * Target Debt: 100 × 0.75 = 75 ETH
     * Available: 75 - 50 = 25 ETH
     * Safe Borrow: 25 × 0.95 = 23.75 ETH
     */
    function calculateMaxBorrow() internal view returns (uint256 maxBorrow) {
        (uint256 totalCollateral, uint256 totalDebt, uint256 availableBorrow,,,) =
            lendingPool.getUserAccountData(address(this));

        if (totalCollateral == 0) return 0;

        // Calculate target debt based on target LTV
        uint256 targetDebt = (totalCollateral * targetLTV) / BASIS_POINTS;

        // If we're already at or above target, don't borrow more
        if (totalDebt >= targetDebt) return 0;

        // Calculate how much more we can borrow
        uint256 additionalBorrow = targetDebt - totalDebt;

        // Take minimum of calculated amount and protocol's available borrow
        maxBorrow = min(additionalBorrow, availableBorrow);

        // Apply 95% safety factor to stay away from edge
        maxBorrow = (maxBorrow * 9500) / BASIS_POINTS;
    }

    /**
     * @notice Calculate maximum safe withdraw amount
     * @return maxWithdraw Maximum amount that can be withdrawn safely
     *
     * Calculation:
     * 1. Get current position data
     * 2. Calculate collateral needed to maintain min health factor
     * 3. Subtract from current collateral
     * 4. Apply safety buffer
     *
     * Health Factor = (Collateral × LiqThreshold) / Debt
     * Required Collateral = (Debt × minHF) / LiqThreshold
     * Max Withdraw = Current Collateral - Required Collateral
     *
     * Example:
     * Collateral: 400 ETH
     * Debt: 300 ETH
     * Liq Threshold: 82.5%
     * Min HF: 1.5
     * Required: (300 × 1.5) / 0.825 = 545.45 ETH
     * Wait, that's more than we have! So maxWithdraw = 0
     *
     * Better example:
     * Collateral: 400 ETH
     * Debt: 200 ETH
     * Required: (200 × 1.5) / 0.825 = 363.64 ETH
     * Max Withdraw: 400 - 363.64 = 36.36 ETH
     */
    function calculateMaxWithdraw() internal view returns (uint256 maxWithdraw) {
        (uint256 totalCollateral, uint256 totalDebt,, uint256 liqThreshold,,) =
            lendingPool.getUserAccountData(address(this));

        if (totalCollateral == 0 || totalDebt == 0) return 0;

        // Calculate collateral needed to maintain min health factor
        // Required = (Debt × minHF) / liqThreshold
        // liqThreshold is in basis points
        uint256 requiredCollateral = (totalDebt * minHealthFactor * BASIS_POINTS)
            / (liqThreshold * 10 ** HEALTH_FACTOR_DECIMALS);

        // If we don't have enough collateral, can't withdraw
        if (totalCollateral <= requiredCollateral) return 0;

        // Calculate withdrawable amount
        maxWithdraw = totalCollateral - requiredCollateral;

        // Apply 90% safety factor for extra buffer
        maxWithdraw = (maxWithdraw * 9000) / BASIS_POINTS;
    }

    // ============================================
    // Rebalancing Functions
    // ============================================

    /**
     * @notice Rebalance position if LTV has drifted from target
     *
     * Market conditions cause LTV to drift:
     * - Asset price ↑: LTV ↓ (under-leveraged)
     * - Asset price ↓: LTV ↑ (over-leveraged)
     * - Interest accrual: LTV ↑ slowly
     *
     * This function brings LTV back to target if drift exceeds threshold.
     *
     * Example:
     * Target LTV: 75%
     * Current LTV: 78% (drifted +3% due to price drop)
     * Threshold: 2%
     * Action: Deleverage to reduce LTV back to 75%
     */
    function rebalance() external nonReentrant {
        if (paused) revert VaultPaused();

        uint256 currentLTV = getCurrentLTV();
        uint256 drift = abs(currentLTV, targetLTV);

        // Only rebalance if drift exceeds threshold
        if (drift < rebalanceThreshold) revert RebalanceNotNeeded();

        uint256 oldLTV = currentLTV;

        if (currentLTV > targetLTV) {
            // Over-leveraged: need to deleverage
            // Calculate how much debt to repay
            (uint256 totalCollateral, uint256 totalDebt,,,,) = lendingPool.getUserAccountData(address(this));

            uint256 targetDebt = (totalCollateral * targetLTV) / BASIS_POINTS;
            uint256 excessDebt = totalDebt - targetDebt;

            // Deleverage by excess amount
            uint256 shareToDeleverage = (excessDebt * BASIS_POINTS) / totalDebt;
            executeDeleverageLoop(shareToDeleverage);
        } else {
            // Under-leveraged: can leverage more
            // Calculate how much more we can borrow
            (uint256 totalCollateral, uint256 totalDebt,,,,) = lendingPool.getUserAccountData(address(this));

            uint256 targetDebt = (totalCollateral * targetLTV) / BASIS_POINTS;
            uint256 additionalDebt = targetDebt - totalDebt;

            // Leverage up by borrowing more
            // This is essentially one iteration of the leverage loop
            if (additionalDebt > 0) {
                lendingPool.borrow(address(asset), additionalDebt, RATE_MODE_VARIABLE, 0, address(this));
                lendingPool.deposit(address(asset), additionalDebt, address(this), 0);
            }
        }

        uint256 newLTV = getCurrentLTV();
        uint256 hf = getHealthFactor();
        emit Rebalanced(oldLTV, newLTV, hf);
    }

    /**
     * @notice Emergency deleverage if health factor drops too low
     *
     * This is a critical safety mechanism. If health factor approaches
     * liquidation threshold (1.0), we aggressively deleverage to prevent
     * liquidation.
     *
     * Triggered when: HF < minHealthFactor (e.g., 1.5)
     * Target: Increase HF to safe level (e.g., 1.8)
     *
     * Example:
     * Current: 400 ETH collateral, 320 ETH debt, HF = 1.03 (DANGER!)
     * Target HF: 1.8
     * Required Collateral at HF 1.8: (320 × 1.8) / 0.825 = 698 ETH
     * We only have 400, so we need to reduce debt
     * Target Debt at HF 1.8: (400 × 0.825) / 1.8 = 183 ETH
     * Debt to Repay: 320 - 183 = 137 ETH
     */
    function emergencyDeleverage() external nonReentrant {
        uint256 currentHF = getHealthFactor();

        // Only trigger if health factor is below minimum
        if (currentHF >= minHealthFactor) {
            revert HealthFactorTooLow();
        }

        // Target: increase HF to 1.8 (20% above minimum of 1.5)
        uint256 targetHF = (minHealthFactor * 120) / 100;

        (uint256 totalCollateral, uint256 totalDebt,, uint256 liqThreshold,,) =
            lendingPool.getUserAccountData(address(this));

        // Calculate target debt for target HF
        // HF = (Collateral × LiqThreshold) / Debt
        // Target Debt = (Collateral × LiqThreshold) / Target HF
        uint256 targetDebt =
            (totalCollateral * liqThreshold * 10 ** HEALTH_FACTOR_DECIMALS) / (targetHF * BASIS_POINTS);

        if (targetDebt >= totalDebt) return; // Already safe

        // Calculate share to deleverage
        uint256 debtToRepay = totalDebt - targetDebt;
        uint256 shareToDeleverage = (debtToRepay * BASIS_POINTS) / totalDebt;

        // Execute aggressive deleverage
        executeDeleverageLoop(shareToDeleverage);

        uint256 finalLeverage = getCurrentLeverage();
        uint256 finalHF = getHealthFactor();
        emit EmergencyDeleveraged(finalHF, finalLeverage);
    }

    // ============================================
    // View Functions
    // ============================================

    /**
     * @notice Get current leverage ratio
     * @return leverage Current leverage in basis points
     *
     * Leverage = Total Exposure / Net Position
     *          = Collateral / (Collateral - Debt)
     *          = Collateral / Equity
     *
     * Example:
     * Collateral: 400 ETH
     * Debt: 300 ETH
     * Equity: 100 ETH
     * Leverage: 400 / 100 = 4x = 40000 basis points
     */
    function getCurrentLeverage() public view returns (uint256 leverage) {
        (uint256 totalCollateral, uint256 totalDebt,,,,) = lendingPool.getUserAccountData(address(this));

        if (totalCollateral == 0 || totalCollateral <= totalDebt) {
            return BASIS_POINTS; // 1x leverage
        }

        // Leverage = Collateral / (Collateral - Debt)
        leverage = (totalCollateral * BASIS_POINTS) / (totalCollateral - totalDebt);
    }

    /**
     * @notice Get current LTV ratio
     * @return ltv Current loan-to-value in basis points
     *
     * LTV = Debt / Collateral
     *
     * Example:
     * Collateral: 400 ETH
     * Debt: 300 ETH
     * LTV: 300 / 400 = 0.75 = 7500 basis points (75%)
     */
    function getCurrentLTV() public view returns (uint256 ltv) {
        (uint256 totalCollateral, uint256 totalDebt,,,,) = lendingPool.getUserAccountData(address(this));

        if (totalCollateral == 0) return 0;

        ltv = (totalDebt * BASIS_POINTS) / totalCollateral;
    }

    /**
     * @notice Get current health factor
     * @return healthFactor Current health factor with 18 decimals
     *
     * Health Factor = (Collateral × Liquidation Threshold) / Debt
     *
     * Values:
     * > 1.5: Safe (green)
     * 1.2-1.5: Warning (yellow)
     * 1.0-1.2: Danger (red)
     * < 1.0: Liquidation (black)
     */
    function getHealthFactor() public view returns (uint256 healthFactor) {
        (,,,, healthFactor) = lendingPool.getUserAccountData(address(this));
    }

    /**
     * @notice Get user's share of the vault
     * @param user User address
     * @return userShare User's share in basis points
     */
    function getUserShare(address user) public view returns (uint256 userShare) {
        if (totalDeposits == 0) return 0;
        userShare = (userDeposits[user] * BASIS_POINTS) / totalDeposits;
    }

    /**
     * @notice Get total net position value (collateral - debt)
     * @return positionValue Net position value in ETH terms
     *
     * This represents the total equity in the vault.
     *
     * Example:
     * Collateral: 400 ETH ($800,000 at $2,000/ETH)
     * Debt: 300 ETH ($600,000)
     * Net Position: 100 ETH ($200,000)
     */
    function getPositionValue() public view returns (uint256 positionValue) {
        (uint256 totalCollateral, uint256 totalDebt,,,,) = lendingPool.getUserAccountData(address(this));

        if (totalCollateral <= totalDebt) return 0;

        positionValue = totalCollateral - totalDebt;
    }

    /**
     * @notice Calculate user's withdrawable amount
     * @param user User address
     * @return withdrawable Maximum amount user can safely withdraw
     *
     * Considers:
     * 1. User's share of total deposits
     * 2. Current position value
     * 3. Health factor constraints
     */
    function getWithdrawableAmount(address user) public view returns (uint256 withdrawable) {
        if (totalDeposits == 0) return 0;

        // User's share of total position
        uint256 userShare = getUserShare(user);
        uint256 positionValue = getPositionValue();
        uint256 userPosition = (positionValue * userShare) / BASIS_POINTS;

        // Max withdraw while maintaining health factor
        uint256 maxWithdrawable = calculateMaxWithdraw();

        // Return minimum of user's position and max withdrawable
        withdrawable = min(userPosition, maxWithdrawable);
    }

    /**
     * @notice Get detailed position metrics
     * @return collateral Total collateral
     * @return debt Total debt
     * @return leverage Current leverage
     * @return ltv Current LTV
     * @return healthFactor Current health factor
     */
    function getPositionMetrics()
        external
        view
        returns (uint256 collateral, uint256 debt, uint256 leverage, uint256 ltv, uint256 healthFactor)
    {
        (collateral, debt,,,, healthFactor) = lendingPool.getUserAccountData(address(this));
        leverage = getCurrentLeverage();
        ltv = getCurrentLTV();
    }

    // ============================================
    // Admin Functions
    // ============================================

    /**
     * @notice Update vault parameters
     * @param _targetLeverage New target leverage (in basis points)
     * @param _targetLTV New target LTV (in basis points)
     * @param _minHealthFactor New minimum health factor
     *
     * Safety checks:
     * - Leverage must be >= 1x
     * - LTV must be < 100%
     * - Min HF must be >= 1.0
     * - Parameters must be consistent (leverage compatible with LTV)
     */
    function updateParameters(uint256 _targetLeverage, uint256 _targetLTV, uint256 _minHealthFactor)
        external
        onlyOwner
    {
        if (_targetLeverage < BASIS_POINTS) revert UnsafeParameters();
        if (_targetLTV >= BASIS_POINTS) revert UnsafeParameters();
        if (_minHealthFactor < 1e18) revert UnsafeParameters();

        // Verify leverage and LTV are compatible
        // Max leverage = 1 / (1 - LTV)
        uint256 maxPossibleLeverage = (BASIS_POINTS * BASIS_POINTS) / (BASIS_POINTS - _targetLTV);
        if (_targetLeverage > maxPossibleLeverage) revert UnsafeParameters();

        targetLeverage = _targetLeverage;
        targetLTV = _targetLTV;
        minHealthFactor = _minHealthFactor;

        emit ParametersUpdated(_targetLeverage, _targetLTV, _minHealthFactor);
    }

    /**
     * @notice Pause deposits and withdrawals
     */
    function pause() external onlyOwner {
        paused = true;
        emit Paused();
    }

    /**
     * @notice Unpause deposits and withdrawals
     */
    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused();
    }

    /**
     * @notice Update rebalance threshold
     * @param _threshold New threshold in basis points
     */
    function updateRebalanceThreshold(uint256 _threshold) external onlyOwner {
        require(_threshold <= 1000, "Threshold too high"); // Max 10%
        rebalanceThreshold = _threshold;
    }

    // ============================================
    // Internal Helper Functions
    // ============================================

    /**
     * @notice Calculate absolute difference
     */
    function abs(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a - b : b - a;
    }

    /**
     * @notice Get minimum of two numbers
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @notice Get maximum of two numbers
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. LEVERAGE AMPLIFIES RETURNS AND RISKS
 *    ✅ Borrow against collateral to increase position
 *    ✅ 4x leverage = 4x returns (and 4x losses!)
 *    ✅ Real-world: Used by major DeFi protocols
 *    ✅ Requires careful risk management
 *
 * 2. LEVERAGE LOOPING BUILDS POSITION
 *    ✅ Deposit → Borrow → Deposit → Borrow...
 *    ✅ Iteratively builds leverage
 *    ✅ Target leverage ratio (e.g., 4x)
 *    ✅ Maintains health factor above threshold
 *
 * 3. HEALTH FACTOR PREVENTS LIQUIDATION
 *    ✅ HF = (collateral * LTV) / debt
 *    ✅ HF < 1.0 = liquidation risk
 *    ✅ Maintain HF > 1.5 for safety
 *    ✅ Monitor continuously
 *
 * 4. REBALANCING MAINTAINS TARGET LEVERAGE
 *    ✅ Monitor actual vs target leverage
 *    ✅ Rebalance when drift exceeds threshold
 *    ✅ Add/remove collateral or debt
 *    ✅ Gas intensive, limit frequency
 *
 * 5. LIQUIDATION RISK IS REAL
 *    ✅ Price drops can trigger liquidation
 *    ✅ Users lose collateral if liquidated
 *    ✅ Circuit breakers can pause during volatility
 *    ✅ Real-world: Many liquidations during crashes
 *
 * 6. RISK MANAGEMENT IS CRITICAL
 *    ✅ Maximum leverage limits
 *    ✅ Health factor monitoring
 *    ✅ Circuit breakers
 *    ✅ Emergency withdrawal mechanisms
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMMON MISTAKES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ❌ Not monitoring health factor (liquidation risk!)
 * ❌ Too high leverage (amplified losses!)
 * ❌ No circuit breakers (continues during crashes!)
 * ❌ Rebalancing too frequently (gas costs!)
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          NEXT STEPS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * • Study Aave and Compound leverage mechanisms
 * • Learn about liquidation protection strategies
 * • Explore dynamic leverage adjustment
 * • Move to Project 50 for the DeFi capstone
 */
