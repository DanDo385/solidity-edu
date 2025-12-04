// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Vault Insolvency Scenarios - Complete Solution
 * @notice Demonstrates handling vault insolvency, bad debt, and emergency scenarios
 * @dev Complete implementation with crisis management and loss socialization
 */

// Mock risky strategy that can lose funds
contract RiskyStrategySolution {
    using SafeERC20 for IERC20;

    IERC20 public asset;
    uint256 public totalInvested;
    uint256 public simulatedLoss; // For testing purposes

    constructor(address _asset) {
        asset = IERC20(_asset);
    }

    function deposit(uint256 amount) external {
        asset.safeTransferFrom(msg.sender, address(this), amount);
        totalInvested += amount;
    }

    function withdraw(uint256 amount) external returns (uint256) {
        uint256 available = balanceOf();
        uint256 toWithdraw = amount > available ? available : amount;

        if (toWithdraw > 0) {
            asset.safeTransfer(msg.sender, toWithdraw);
            totalInvested -= toWithdraw;
        }

        return toWithdraw;
    }

    function balanceOf() public view returns (uint256) {
        // Simulate losses
        if (simulatedLoss >= totalInvested) {
            return 0;
        }
        return totalInvested - simulatedLoss;
    }

    function simulateLoss(uint256 lossAmount) external {
        simulatedLoss += lossAmount;
    }

    function resetLoss() external {
        simulatedLoss = 0;
    }
}

contract VaultInsolvencySolution is ReentrancyGuard {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    IERC20 public immutable asset;
    RiskyStrategySolution public strategy;

    mapping(address => uint256) public shares;
    uint256 public totalShares;

    address public owner;

    // Vault operating modes
    enum Mode {
        NORMAL, // All operations allowed
        PAUSED, // Only withdrawals allowed
        EMERGENCY, // Only proportional withdrawals allowed
        FROZEN // No operations allowed
    }

    Mode public currentMode;

    // Circuit breaker thresholds
    uint256 public constant MAX_LOSS_PERCENTAGE = 1000; // 10% (basis points)
    uint256 public constant CATASTROPHIC_LOSS = 5000; // 50%
    uint256 public constant MIN_SOLVENCY_RATIO = 9500; // 95%

    // Loss tracking
    uint256 public lastKnownTotalAssets;
    uint256 public totalLosses;
    uint256 public lastHealthCheck;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposited(address indexed user, uint256 assets, uint256 shares);
    event Withdrawn(address indexed user, uint256 shares, uint256 assets);
    event EmergencyTriggered(uint256 timestamp, uint256 totalAssets, uint256 lossPercentage);
    event ModeChanged(Mode oldMode, Mode newMode);
    event LossDetected(uint256 lossAmount, uint256 lossPercentage);
    event RecoveryAttempted(uint256 recovered, uint256 remaining);
    event StrategyLoss(uint256 lossAmount);
    event CircuitBreakerTriggered(string reason);

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier inMode(Mode requiredMode) {
        require(currentMode == requiredMode, "Wrong mode");
        _;
    }

    modifier notFrozen() {
        require(currentMode != Mode.FROZEN, "Vault frozen");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _asset, address _strategy) {
        asset = IERC20(_asset);
        strategy = RiskyStrategySolution(_strategy);
        owner = msg.sender;
        currentMode = Mode.NORMAL;
        lastHealthCheck = block.timestamp;
    }

    /*//////////////////////////////////////////////////////////////
                         DEPOSIT/WITHDRAWAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposit assets and receive shares
     * @dev Only allowed in NORMAL mode
     * @param assets Amount of assets to deposit
     * @return sharesToMint Amount of shares minted
     */
    function deposit(uint256 assets) external nonReentrant inMode(Mode.NORMAL) returns (uint256) {
        require(assets > 0, "Zero assets");

        // Check health before accepting new deposits
        _checkHealth();

        // Calculate shares to mint
        uint256 sharesToMint = convertToShares(assets);
        require(sharesToMint > 0, "Zero shares");

        // Transfer assets from user
        asset.safeTransferFrom(msg.sender, address(this), assets);

        // Deploy to strategy
        asset.safeApprove(address(strategy), assets);
        strategy.deposit(assets);

        // Mint shares
        shares[msg.sender] += sharesToMint;
        totalShares += sharesToMint;

        // Update tracking
        lastKnownTotalAssets = totalAssets();

        emit Deposited(msg.sender, assets, sharesToMint);

        return sharesToMint;
    }

    /**
     * @notice Withdraw assets by burning shares
     * @dev Behavior depends on vault mode
     * @param sharesToBurn Amount of shares to burn
     * @return assetsToReturn Amount of assets returned
     */
    function withdraw(uint256 sharesToBurn) external nonReentrant notFrozen returns (uint256) {
        require(sharesToBurn > 0, "Zero shares");
        require(shares[msg.sender] >= sharesToBurn, "Insufficient shares");

        uint256 assetsToReturn;

        // Mode-based withdrawal logic
        if (currentMode == Mode.NORMAL || currentMode == Mode.PAUSED) {
            // Normal withdrawal: full expected value
            assetsToReturn = convertToAssets(sharesToBurn);

            // Ensure vault has enough liquidity
            uint256 vaultBalance = asset.balanceOf(address(this));

            if (vaultBalance < assetsToReturn) {
                // Withdraw from strategy
                uint256 needed = assetsToReturn - vaultBalance;
                uint256 withdrawn = strategy.withdraw(needed);

                // Check if we got what we needed
                if (withdrawn < needed) {
                    // Strategy couldn't provide enough - potential insolvency
                    _detectLoss();

                    // Switch to emergency withdrawal
                    assetsToReturn = _emergencyWithdraw(sharesToBurn);
                }
            }
        } else if (currentMode == Mode.EMERGENCY) {
            // Emergency mode: proportional withdrawal
            assetsToReturn = _emergencyWithdraw(sharesToBurn);
        }

        // Burn shares
        shares[msg.sender] -= sharesToBurn;
        totalShares -= sharesToBurn;

        // Transfer assets
        if (assetsToReturn > 0) {
            asset.safeTransfer(msg.sender, assetsToReturn);
        }

        emit Withdrawn(msg.sender, sharesToBurn, assetsToReturn);

        return assetsToReturn;
    }

    /*//////////////////////////////////////////////////////////////
                         EMERGENCY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Trigger emergency mode manually
     * @dev Can be called by owner or automatically by circuit breakers
     */
    function triggerEmergency() public onlyOwner {
        require(currentMode != Mode.EMERGENCY, "Already in emergency");

        Mode oldMode = currentMode;
        currentMode = Mode.EMERGENCY;

        // Try to recover all funds from strategy
        _attemptRecovery();

        uint256 loss = calculateLoss();

        emit EmergencyTriggered(block.timestamp, totalAssets(), loss);
        emit ModeChanged(oldMode, Mode.EMERGENCY);
    }

    /**
     * @notice Proportional withdrawal during emergency
     * @dev Distributes remaining assets fairly among all shareholders
     * @param sharesToBurn Shares to burn
     * @return assets Assets returned (proportional)
     */
    function _emergencyWithdraw(uint256 sharesToBurn) internal returns (uint256) {
        if (totalShares == 0) return 0;

        // Proportional distribution of remaining assets
        // This ensures fair loss socialization
        uint256 totalAssetsNow = totalAssets();
        uint256 assets = (sharesToBurn * totalAssetsNow) / totalShares;

        return assets;
    }

    /**
     * @notice Attempt to recover funds from strategy
     * @dev Pulls all possible funds back to vault
     */
    function recoverFromStrategy() external onlyOwner {
        _attemptRecovery();
    }

    /**
     * @notice Internal recovery function
     */
    function _attemptRecovery() internal {
        uint256 strategyBalance = strategy.balanceOf();

        if (strategyBalance > 0) {
            uint256 recovered = strategy.withdraw(strategyBalance);
            emit RecoveryAttempted(recovered, strategy.balanceOf());
        }

        // Check if we can restore normal operations
        if (currentMode == Mode.EMERGENCY && checkSolvency()) {
            _changeMode(Mode.PAUSED); // Move to paused, not directly to normal
        }
    }

    /**
     * @notice Freeze all operations
     * @dev Most severe emergency measure
     */
    function freeze() external onlyOwner {
        _changeMode(Mode.FROZEN);
        emit CircuitBreakerTriggered("Manual freeze");
    }

    /**
     * @notice Pause deposits only
     */
    function pauseDeposits() external onlyOwner {
        require(currentMode == Mode.NORMAL, "Not in normal mode");
        _changeMode(Mode.PAUSED);
    }

    /**
     * @notice Resume normal operations
     * @dev Only allowed if vault is solvent
     */
    function resumeNormal() external onlyOwner {
        require(checkSolvency(), "Not solvent");
        require(currentMode == Mode.PAUSED, "Must be paused");
        _changeMode(Mode.NORMAL);
    }

    /*//////////////////////////////////////////////////////////////
                           HEALTH CHECKS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Check vault health and trigger circuit breakers if needed
     */
    function _checkHealth() internal {
        // Only check periodically to save gas
        if (block.timestamp < lastHealthCheck + 1 hours) {
            return;
        }

        lastHealthCheck = block.timestamp;

        // Check for losses
        uint256 currentAssets = totalAssets();

        if (currentAssets < lastKnownTotalAssets) {
            uint256 loss = lastKnownTotalAssets - currentAssets;
            uint256 lossPercentage = (loss * 10000) / lastKnownTotalAssets;

            emit LossDetected(loss, lossPercentage);
            totalLosses += loss;

            // Circuit breakers
            if (lossPercentage >= CATASTROPHIC_LOSS) {
                // Catastrophic loss: freeze immediately
                _changeMode(Mode.FROZEN);
                emit CircuitBreakerTriggered("Catastrophic loss");
            } else if (lossPercentage >= MAX_LOSS_PERCENTAGE) {
                // Significant loss: emergency mode
                if (currentMode == Mode.NORMAL) {
                    _changeMode(Mode.EMERGENCY);
                    emit CircuitBreakerTriggered("Significant loss");
                }
            }
        }

        lastKnownTotalAssets = currentAssets;
    }

    /**
     * @notice Detect and respond to losses
     */
    function _detectLoss() internal {
        uint256 loss = calculateLoss();

        if (loss > 0) {
            emit StrategyLoss(loss);

            // Automatic circuit breaker
            if (loss >= MAX_LOSS_PERCENTAGE && currentMode == Mode.NORMAL) {
                triggerEmergency();
            }
        }
    }

    /**
     * @notice Check if vault is solvent
     * @return True if vault can cover at least MIN_SOLVENCY_RATIO of shares
     */
    function checkSolvency() public view returns (bool) {
        if (totalShares == 0) return true;

        uint256 currentAssets = totalAssets();
        uint256 expectedAssets = (lastKnownTotalAssets * totalShares) / totalShares;

        // Allow for small rounding differences
        if (expectedAssets == 0) return true;

        uint256 solvencyRatio = (currentAssets * 10000) / expectedAssets;

        return solvencyRatio >= MIN_SOLVENCY_RATIO;
    }

    /*//////////////////////////////////////////////////////////////
                         ACCOUNTING HELPERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Calculate total assets held by vault
     * @return Total assets (in vault + in strategy - losses)
     */
    function totalAssets() public view returns (uint256) {
        return asset.balanceOf(address(this)) + strategy.balanceOf();
    }

    /**
     * @notice Convert assets to shares
     * @param assets Amount of assets
     * @return Amount of shares
     */
    function convertToShares(uint256 assets) public view returns (uint256) {
        if (totalShares == 0) {
            // First deposit: 1:1 ratio
            return assets;
        }

        uint256 totalAssetsNow = totalAssets();

        if (totalAssetsNow == 0) {
            // Vault is empty but shares exist (post-loss scenario)
            // Prevent new deposits in this case
            return 0;
        }

        // Standard formula: shares = assets * totalShares / totalAssets
        // This maintains proportional ownership
        return (assets * totalShares) / totalAssetsNow;
    }

    /**
     * @notice Convert shares to assets
     * @param _shares Amount of shares
     * @return Amount of assets
     */
    function convertToAssets(uint256 _shares) public view returns (uint256) {
        if (totalShares == 0) return 0;

        // Standard formula: assets = shares * totalAssets / totalShares
        return (_shares * totalAssets()) / totalShares;
    }

    /**
     * @notice Calculate current loss percentage
     * @return Loss in basis points (10000 = 100%)
     */
    function calculateLoss() public view returns (uint256) {
        if (lastKnownTotalAssets == 0 || totalShares == 0) return 0;

        uint256 currentAssets = totalAssets();

        if (currentAssets >= lastKnownTotalAssets) {
            return 0; // No loss (or gain)
        }

        uint256 loss = lastKnownTotalAssets - currentAssets;

        // Return as basis points
        return (loss * 10000) / lastKnownTotalAssets;
    }

    /**
     * @notice Get user's asset balance
     * @param user User address
     * @return User's claimable assets (accounting for losses)
     */
    function balanceOf(address user) public view returns (uint256) {
        return convertToAssets(shares[user]);
    }

    /**
     * @notice Get expected vs actual assets for a user
     * @param user User address
     * @return expected Expected assets (no loss)
     * @return actual Actual assets (with losses)
     * @return loss Amount of loss
     */
    function getUserLossInfo(address user)
        public
        view
        returns (uint256 expected, uint256 actual, uint256 loss)
    {
        uint256 userShares = shares[user];

        if (totalShares == 0 || userShares == 0) {
            return (0, 0, 0);
        }

        // Expected: Based on last known good total
        expected = (userShares * lastKnownTotalAssets) / totalShares;

        // Actual: Based on current total
        actual = convertToAssets(userShares);

        // Loss
        loss = expected > actual ? expected - actual : 0;
    }

    /*//////////////////////////////////////////////////////////////
                             MODE MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Change vault operating mode
     * @param newMode New mode to set
     */
    function _changeMode(Mode newMode) internal {
        Mode oldMode = currentMode;
        currentMode = newMode;
        emit ModeChanged(oldMode, newMode);
    }

    /**
     * @notice Get current mode as string
     */
    function getCurrentModeString() public view returns (string memory) {
        if (currentMode == Mode.NORMAL) return "NORMAL";
        if (currentMode == Mode.PAUSED) return "PAUSED";
        if (currentMode == Mode.EMERGENCY) return "EMERGENCY";
        return "FROZEN";
    }

    /*//////////////////////////////////////////////////////////////
                          VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get comprehensive vault status
     */
    function getVaultStatus()
        public
        view
        returns (
            Mode mode,
            uint256 totalAssetsValue,
            uint256 totalSharesValue,
            uint256 lossPercentage,
            bool isSolvent
        )
    {
        mode = currentMode;
        totalAssetsValue = totalAssets();
        totalSharesValue = totalShares;
        lossPercentage = calculateLoss();
        isSolvent = checkSolvency();
    }

    /**
     * @notice Get share price (assets per share)
     * @return Price per share (scaled by 1e18)
     */
    function getPricePerShare() public view returns (uint256) {
        if (totalShares == 0) return 1e18;
        return (totalAssets() * 1e18) / totalShares;
    }

    /**
     * @notice Emergency admin function to update owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        owner = newOwner;
    }
}

/*
SOLUTION FEATURES:

1. Multi-Mode State Machine
   - NORMAL: Full operations
   - PAUSED: No deposits, withdrawals ok
   - EMERGENCY: Only proportional withdrawals
   - FROZEN: Complete shutdown

2. Loss Detection & Circuit Breakers
   - Automatic health checks
   - Loss percentage calculation
   - Automatic emergency triggers
   - Catastrophic loss freeze

3. Fair Loss Socialization
   - Pro-rata distribution
   - Proportional withdrawals in emergency
   - No first-mover advantage
   - Transparent loss tracking

4. Recovery Mechanisms
   - Strategy fund recovery
   - Gradual mode degradation
   - Solvency restoration checks
   - Manual override capabilities

5. Comprehensive Accounting
   - Accurate total asset calculation
   - Share/asset conversions
   - Individual loss tracking
   - Price per share tracking

6. Security Features
   - ReentrancyGuard protection
   - Mode-based access control
   - Owner-only emergency functions
   - Proper state transitions

KEY LEARNINGS:

1. Insolvency happens when totalAssets < totalShares * expectedPrice
2. Emergency mode uses proportional withdrawals: shares * totalAssets / totalShares
3. Circuit breakers prevent further damage during crises
4. Loss socialization must be fair (pro-rata)
5. Multiple modes allow graceful degradation
6. Recovery mechanisms are essential
7. Transparent loss reporting builds trust

CRISIS RESPONSE FLOW:

1. Loss Detected → Emit LossDetected event
2. Check Loss Severity → Compare to thresholds
3. Trigger Circuit Breaker → Automatic mode change
4. Attempt Recovery → Pull funds from strategy
5. Switch to Proportional → Fair withdrawal mode
6. Monitor & Report → Track recovery progress
7. Restore Operations → When solvent again

This solution demonstrates production-ready crisis management for DeFi vaults!
*/

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. VAULT INSOLVENCY IS REAL RISK
 *    ✅ Strategies can lose funds (hacks, market crashes)
 *    ✅ totalAssets < totalShares * expectedPrice
 *    ✅ Vault can't honor all withdrawals
 *    ✅ Real-world: Multiple vault insolvencies
 *
 * 2. PROPORTIONAL WITHDRAWALS ARE FAIR
 *    ✅ In emergency: assets = shares * totalAssets / totalShares
 *    ✅ Everyone gets proportional share of remaining assets
 *    ✅ Prevents first-come-first-served advantage
 *    ✅ Fair distribution during crisis
 *
 * 3. CIRCUIT BREAKERS LIMIT DAMAGE
 *    ✅ Detect losses automatically
 *    ✅ Trigger mode changes based on severity
 *    ✅ Pause operations to prevent further damage
 *    ✅ Real-world: Critical for DeFi protocols
 *
 * 4. MULTIPLE MODES ENABLE GRACEFUL DEGRADATION
 *    ✅ NORMAL: All operations allowed
 *    ✅ PAUSED: Only withdrawals allowed
 *    ✅ EMERGENCY: Proportional withdrawals only
 *    ✅ FROZEN: No operations (last resort)
 *
 * 5. LOSS SOCIALIZATION MUST BE FAIR
 *    ✅ Losses shared proportionally among all users
 *    ✅ No preferential treatment
 *    ✅ Transparent reporting
 *    ✅ Real-world: Required for trust
 *
 * 6. RECOVERY MECHANISMS ARE ESSENTIAL
 *    ✅ Pull funds from failed strategies
 *    ✅ Attempt to recover lost assets
 *    ✅ Restore normal operations when possible
 *    ✅ Document recovery process
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMMON MISTAKES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ❌ Not detecting insolvency (continues operating!)
 * ❌ First-come-first-served withdrawals (unfair!)
 * ❌ No circuit breakers (continues losing!)
 * ❌ Not tracking losses (lack of transparency!)
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          NEXT STEPS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * • Study real-world vault insolvency cases
 * • Learn about crisis management patterns
 * • Explore insurance mechanisms
 * • Move to Project 47 to learn about vault oracle integration
 */
