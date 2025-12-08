// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title YieldVaultSolution
 * @notice ERC-4626 yield vault with pluggable strategies and auto-compounding
 * 
 * PURPOSE: Generate yield on deposited assets via external strategies (Aave, Compound)
 * CS CONCEPTS: Strategy pattern, yield compounding, performance fee calculation
 * 
 * CONNECTIONS:
 * - Project 11: ERC-4626 base implementation
 * - Project 20: Share-based accounting for yield distribution
 * - Project 18: Oracle integration for strategy valuation
 * 
 * KEY: Strategies are pluggable - vault can switch strategies without user action
 */

interface IYieldStrategy {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external returns (uint256 actualAmount);
    function harvest() external returns (uint256 yield);
    function totalAssets() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title YieldVault
 * @notice ERC4626 vault that generates yield through pluggable strategies
 */
contract YieldVault is ERC4626, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============================================================
    // STATE VARIABLES
    // ============================================================

    // Current active strategy
    IYieldStrategy public strategy;

    // Performance fee in basis points (10000 = 100%)
    uint256 public performanceFee;

    // Address receiving performance fees
    address public feeRecipient;

    // Timestamp of last harvest
    uint256 public lastHarvest;

    // Minimum time between harvests (prevents spam)
    uint256 public harvestCooldown;

    // Total yield harvested (for analytics)
    uint256 public totalYieldHarvested;

    // Total fees collected (for analytics)
    uint256 public totalFeesCollected;

    // ============================================================
    // EVENTS
    // ============================================================

    event Harvested(uint256 yield, uint256 fee, uint256 timestamp);
    event StrategyUpdated(address indexed oldStrategy, address indexed newStrategy);
    event PerformanceFeeUpdated(uint256 oldFee, uint256 newFee);
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);

    constructor(
        IERC20 _asset,
        string memory _name,
        string memory _symbol,
        address _feeRecipient,
        uint256 _performanceFee
    ) ERC4626(_asset) ERC20(_name, _symbol) Ownable(msg.sender) {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        require(_performanceFee <= 2000, "Fee too high"); // Max 20%

        feeRecipient = _feeRecipient;
        performanceFee = _performanceFee;
        harvestCooldown = 1 hours;
        lastHarvest = block.timestamp;
    }

    /**
     * @notice Returns total assets under management
     * @dev Includes vault balance + strategy balance
     * @return Total assets in the vault
     *
     * This value drifts upward as yield accrues in the strategy.
     * Even without calling harvest(), totalAssets() increases as the
     * underlying yield source generates returns.
     */
    function totalAssets() public view override returns (uint256) {
        uint256 vaultBalance = IERC20(asset()).balanceOf(address(this));

        if (address(strategy) == address(0)) {
            return vaultBalance;
        }

        // Get total assets from strategy (includes accrued but unharvested yield)
        uint256 strategyBalance = strategy.totalAssets();

        return vaultBalance + strategyBalance;
    }

    /**
     * @notice Harvests yield from strategy and reinvests
     * @dev Can be called by anyone after cooldown period
     *
     * Harvest Process:
     * 1. Claim yield from strategy (converts accrued yield to actual tokens)
     * 2. Calculate performance fee (% of yield)
     * 3. Transfer fee to feeRecipient
     * 4. Reinvest remaining yield into strategy
     * 5. Result: totalAssets increases, but totalSupply stays same
     *    → share price increases → existing shareholders benefit
     */
    function harvest() external nonReentrant {
        require(
            block.timestamp >= lastHarvest + harvestCooldown,
            "Cooldown not elapsed"
        );

        // Harvest yield from strategy
        uint256 yield = strategy.harvest();
        require(yield > 0, "No yield to harvest");

        // Calculate performance fee
        // Formula: fee = yield * performanceFee / 10000
        // Example: 100 tokens yield * 1000 fee / 10000 = 10 tokens (10%)
        uint256 fee = (yield * performanceFee) / 10000;

        // Transfer fee to recipient
        if (fee > 0) {
            IERC20(asset()).safeTransfer(feeRecipient, fee);
            totalFeesCollected += fee;
        }

        // Reinvest remaining yield
        // This compounds returns: yield generates more yield
        uint256 reinvestAmount = yield - fee;
        if (reinvestAmount > 0) {
            _depositToStrategy(reinvestAmount);
        }

        // Update state
        lastHarvest = block.timestamp;
        totalYieldHarvested += yield;

        emit Harvested(yield, fee, block.timestamp);
    }

    /**
     * @notice Deposits assets into the strategy
     * @param assets Amount to deposit
     */
    function _depositToStrategy(uint256 assets) internal {
        IERC20(asset()).forceApprove(address(strategy), assets);
        strategy.deposit(assets);
    }

    /**
     * @notice Withdraws assets from strategy
     * @param assets Amount to withdraw
     * @return Amount actually withdrawn
     */
    function _withdrawFromStrategy(uint256 assets) internal returns (uint256) {
        return strategy.withdraw(assets);
    }

    /**
     * @notice Hook after deposit - automatically deploy to strategy
     */
    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal override {
        super._deposit(caller, receiver, assets, shares);

        // Deploy to strategy if available
        if (address(strategy) != address(0) && assets > 0) {
            _depositToStrategy(assets);
        }
    }

    /**
     * @notice Hook before withdrawal - pull from strategy if needed
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal override {
        uint256 vaultBalance = IERC20(asset()).balanceOf(address(this));

        // Withdraw from strategy if vault doesn't have enough
        if (assets > vaultBalance && address(strategy) != address(0)) {
            uint256 needed = assets - vaultBalance;
            _withdrawFromStrategy(needed);
        }

        super._withdraw(caller, receiver, owner, assets, shares);
    }

    /**
     * @notice Sets a new yield strategy
     * @param _strategy New strategy address
     * @dev Migrates all funds from old strategy to new one
     */
    function setStrategy(IYieldStrategy _strategy) external onlyOwner {
        address oldStrategy = address(strategy);

        // Withdraw all from old strategy
        if (oldStrategy != address(0)) {
            uint256 strategyBalance = strategy.totalAssets();
            if (strategyBalance > 0) {
                strategy.withdraw(strategyBalance);
            }
        }

        // Set new strategy
        strategy = _strategy;

        // Deploy vault balance to new strategy
        if (address(_strategy) != address(0)) {
            uint256 vaultBalance = IERC20(asset()).balanceOf(address(this));
            if (vaultBalance > 0) {
                _depositToStrategy(vaultBalance);
            }
        }

        emit StrategyUpdated(oldStrategy, address(_strategy));
    }

    /**
     * @notice Updates performance fee
     * @param _performanceFee New fee in basis points
     */
    function setPerformanceFee(uint256 _performanceFee) external onlyOwner {
        require(_performanceFee <= 2000, "Fee too high");
        uint256 oldFee = performanceFee;
        performanceFee = _performanceFee;
        emit PerformanceFeeUpdated(oldFee, _performanceFee);
    }

    /**
     * @notice Updates fee recipient
     * @param _feeRecipient New recipient address
     */
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "Invalid recipient");
        address oldRecipient = feeRecipient;
        feeRecipient = _feeRecipient;
        emit FeeRecipientUpdated(oldRecipient, _feeRecipient);
    }

    /**
     * @notice Updates harvest cooldown
     * @param _cooldown New cooldown in seconds
     */
    function setHarvestCooldown(uint256 _cooldown) external onlyOwner {
        harvestCooldown = _cooldown;
    }

    /**
     * @notice Returns current APY based on recent performance
     * @param timePeriod Period to measure (in seconds)
     * @return APY in basis points
     * @dev This is a simplified calculation for demonstration
     */
    function getCurrentAPY(uint256 timePeriod) external view returns (uint256) {
        if (timePeriod == 0 || totalYieldHarvested == 0) {
            return 0;
        }

        // Simplified: (totalYield / totalAssets) * (365 days / timePeriod) * 10000
        uint256 assets = totalAssets();
        if (assets == 0) return 0;

        uint256 yieldRate = (totalYieldHarvested * 10000) / assets;
        uint256 annualized = (yieldRate * 365 days) / timePeriod;

        return annualized;
    }
}

/**
 * @title MockYieldSource
 * @notice Simulates a lending protocol like Aave or Compound
 * @dev Generates yield linearly based on time and APY
 *
 * How it works:
 * - Deposits earn yield continuously based on APY
 * - Yield = principal * APY * timeElapsed / (365 days * 10000)
 * - Simple interest calculation for predictability
 */
contract MockYieldSource {
    using SafeERC20 for IERC20;

    IERC20 public asset;

    // Annual Percentage Yield in basis points
    // Example: 500 = 5% APY
    uint256 public apy;

    // User deposits (principal only, not including yield)
    mapping(address => uint256) public deposits;

    // Last update timestamp for each user
    mapping(address => uint256) public lastUpdate;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    constructor(IERC20 _asset, uint256 _apy) {
        asset = _asset;
        apy = _apy;
    }

    /**
     * @notice Deposits assets to start earning yield
     * @param amount Amount to deposit
     */
    function deposit(uint256 amount) external {
        require(amount > 0, "Cannot deposit 0");

        // Accrue any existing yield first
        _accrueYield(msg.sender);

        // Transfer assets from user
        asset.safeTransferFrom(msg.sender, address(this), amount);

        // Update deposit amount
        deposits[msg.sender] += amount;

        emit Deposited(msg.sender, amount);
    }

    /**
     * @notice Withdraws assets including accrued yield
     * @param amount Amount to withdraw
     */
    function withdraw(uint256 amount) external {
        require(amount > 0, "Cannot withdraw 0");

        // Accrue yield first
        _accrueYield(msg.sender);

        require(deposits[msg.sender] >= amount, "Insufficient balance");

        // Update deposit
        deposits[msg.sender] -= amount;

        // Transfer to user
        asset.safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @notice Returns balance including accrued yield
     * @param account Account to check
     * @return Current balance with yield
     *
     * Yield Calculation:
     * yield = principal * apy * timeElapsed / (365 days * 10000)
     *
     * Example:
     * - Principal: 1000 tokens
     * - APY: 500 (5%)
     * - Time: 30 days
     * - Yield = 1000 * 500 * 30 days / (365 days * 10000)
     * - Yield = 1000 * 500 * 30 / (365 * 10000) ≈ 4.11 tokens
     * - Balance = 1004.11 tokens
     */
    function balanceOf(address account) public view returns (uint256) {
        uint256 principal = deposits[account];
        if (principal == 0) {
            return 0;
        }

        // Calculate time elapsed since last update
        uint256 timeElapsed = block.timestamp - lastUpdate[account];

        // Calculate accrued yield
        // Formula: yield = principal * apy * time / (365 days * 10000)
        uint256 yield = (principal * apy * timeElapsed) / (365 days * 10000);

        return principal + yield;
    }

    /**
     * @notice Accrues yield for an account
     * @param account Account to update
     *
     * This function "realizes" the yield by adding it to the principal.
     * After this, the yield becomes part of the deposit and earns yield itself
     * (compound interest).
     */
    function _accrueYield(address account) internal {
        if (deposits[account] == 0) {
            lastUpdate[account] = block.timestamp;
            return;
        }

        // Get current balance (principal + yield)
        uint256 currentBalance = balanceOf(account);

        // Update deposit to include yield (compounding)
        deposits[account] = currentBalance;

        // Reset timer
        lastUpdate[account] = block.timestamp;
    }

    /**
     * @notice Updates APY (for testing different scenarios)
     * @param _apy New APY in basis points
     */
    function setAPY(uint256 _apy) external {
        apy = _apy;
    }
}

/**
 * @title SimpleYieldStrategy
 * @notice Strategy that deposits into MockYieldSource
 * @dev Demonstrates basic strategy pattern
 */
contract SimpleYieldStrategy is IYieldStrategy {
    using SafeERC20 for IERC20;

    IERC20 public asset;
    MockYieldSource public yieldSource;
    address public vault;

    // Principal deposited (excludes accrued yield)
    uint256 public principal;

    modifier onlyVault() {
        require(msg.sender == vault, "Only vault");
        _;
    }

    constructor(IERC20 _asset, MockYieldSource _yieldSource, address _vault) {
        asset = _asset;
        yieldSource = _yieldSource;
        vault = _vault;
    }

    /**
     * @notice Deposits assets into yield source
     * @param amount Amount to deposit
     */
    function deposit(uint256 amount) external onlyVault {
        require(amount > 0, "Cannot deposit 0");

        // Transfer from vault to this contract
        asset.safeTransferFrom(vault, address(this), amount);

        // Approve and deposit to yield source
        asset.forceApprove(address(yieldSource), amount);
        yieldSource.deposit(amount);

        // Track principal
        principal += amount;
    }

    /**
     * @notice Withdraws assets from yield source
     * @param amount Amount to withdraw
     * @return actualAmount Amount actually withdrawn
     */
    function withdraw(uint256 amount) external onlyVault returns (uint256) {
        require(amount > 0, "Cannot withdraw 0");

        uint256 balance = yieldSource.balanceOf(address(this));
        uint256 toWithdraw = amount > balance ? balance : amount;

        // Withdraw from yield source
        yieldSource.withdraw(toWithdraw);

        // Update principal (but not below 0)
        if (principal > toWithdraw) {
            principal -= toWithdraw;
        } else {
            principal = 0;
        }

        // Transfer to vault
        asset.safeTransfer(vault, toWithdraw);

        return toWithdraw;
    }

    /**
     * @notice Harvests accrued yield
     * @return yield Amount of yield harvested
     *
     * Harvest Process:
     * 1. Check current balance in yield source
     * 2. Calculate yield = balance - principal
     * 3. Withdraw only the yield portion
     * 4. Transfer to vault for redistribution
     * 5. Principal remains in yield source earning yield
     */
    function harvest() external onlyVault returns (uint256) {
        uint256 currentBalance = yieldSource.balanceOf(address(this));

        // Yield is everything above principal
        if (currentBalance <= principal) {
            return 0;
        }

        uint256 yield = currentBalance - principal;

        // Withdraw only the yield
        yieldSource.withdraw(yield);

        // Transfer to vault
        asset.safeTransfer(vault, yield);

        return yield;
    }

    /**
     * @notice Returns total assets in strategy
     * @return Total balance including yield
     */
    function totalAssets() external view returns (uint256) {
        return yieldSource.balanceOf(address(this));
    }

    /**
     * @notice Returns balance for specific account
     * @param account Account to check
     * @return Balance (only vault has balance)
     */
    function balanceOf(address account) external view returns (uint256) {
        if (account == vault) {
            return yieldSource.balanceOf(address(this));
        }
        return 0;
    }
}

/**
 * @title CompoundStrategy
 * @notice Advanced strategy that auto-compounds on every harvest
 * @dev Demonstrates automatic reinvestment
 */
contract CompoundStrategy is IYieldStrategy {
    using SafeERC20 for IERC20;

    IERC20 public asset;
    MockYieldSource public yieldSource;
    address public vault;

    uint256 public principal;
    uint256 public lastHarvest;

    modifier onlyVault() {
        require(msg.sender == vault, "Only vault");
        _;
    }

    constructor(IERC20 _asset, MockYieldSource _yieldSource, address _vault) {
        asset = _asset;
        yieldSource = _yieldSource;
        vault = _vault;
        lastHarvest = block.timestamp;
    }

    function deposit(uint256 amount) external onlyVault {
        require(amount > 0, "Cannot deposit 0");

        asset.safeTransferFrom(vault, address(this), amount);
        asset.forceApprove(address(yieldSource), amount);
        yieldSource.deposit(amount);

        principal += amount;
    }

    function withdraw(uint256 amount) external onlyVault returns (uint256) {
        uint256 balance = yieldSource.balanceOf(address(this));
        uint256 toWithdraw = amount > balance ? balance : amount;

        yieldSource.withdraw(toWithdraw);

        if (principal > toWithdraw) {
            principal -= toWithdraw;
        } else {
            principal = 0;
        }

        asset.safeTransfer(vault, toWithdraw);
        return toWithdraw;
    }

    /**
     * @notice Harvests and auto-compounds a portion of yield
     * @return yield Amount sent to vault
     *
     * This strategy:
     * 1. Takes 50% of yield and sends to vault
     * 2. Keeps 50% and reinvests it
     * 3. Reinvested portion adds to principal
     * 4. Creates exponential growth
     */
    function harvest() external onlyVault returns (uint256) {
        uint256 currentBalance = yieldSource.balanceOf(address(this));

        if (currentBalance <= principal) {
            return 0;
        }

        uint256 totalYield = currentBalance - principal;

        // Split yield: 50% to vault, 50% reinvested
        uint256 toVault = totalYield / 2;
        uint256 toReinvest = totalYield - toVault;

        // Withdraw portion for vault
        if (toVault > 0) {
            yieldSource.withdraw(toVault);
            asset.safeTransfer(vault, toVault);
        }

        // Reinvested portion stays in yieldSource and becomes new principal
        // This creates compound growth
        principal += toReinvest;

        lastHarvest = block.timestamp;
        return toVault;
    }

    function totalAssets() external view returns (uint256) {
        return yieldSource.balanceOf(address(this));
    }

    function balanceOf(address account) external view returns (uint256) {
        if (account == vault) {
            return yieldSource.balanceOf(address(this));
        }
        return 0;
    }
}
