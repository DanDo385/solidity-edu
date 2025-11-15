// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Project 43: Yield-Bearing Vault
 * @notice A vault that generates yield through strategies and auto-compounds returns
 * @dev Implements ERC4626 standard for tokenized vaults
 *
 * Learning Objectives:
 * 1. Implement yield-bearing vault with ERC4626
 * 2. Integrate strategy pattern for yield generation
 * 3. Handle harvest and reinvestment mechanics
 * 4. Manage totalAssets() drift over time
 * 5. Calculate and distribute performance fees
 * 6. Simulate compound interest growth
 */

interface IYieldStrategy {
    /**
     * @notice Deposits assets into the yield source
     * @param amount Amount of assets to deposit
     */
    function deposit(uint256 amount) external;

    /**
     * @notice Withdraws assets from the yield source
     * @param amount Amount of assets to withdraw
     * @return actualAmount Amount actually withdrawn
     */
    function withdraw(uint256 amount) external returns (uint256 actualAmount);

    /**
     * @notice Harvests accrued yield
     * @return yield Amount of yield harvested
     */
    function harvest() external returns (uint256 yield);

    /**
     * @notice Returns total assets managed by strategy
     * @return Total assets including accrued yield
     */
    function totalAssets() external view returns (uint256);

    /**
     * @notice Returns balance for a specific account
     * @param account Account to check
     * @return Balance for the account
     */
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title YieldVault
 * @notice Main vault contract that accepts deposits and manages yield strategies
 */
contract YieldVault is ERC4626, Ownable {
    using SafeERC20 for IERC20;

    // Strategy that generates yield
    IYieldStrategy public strategy;

    // Performance fee in basis points (e.g., 1000 = 10%)
    uint256 public performanceFee;

    // Address that receives performance fees
    address public feeRecipient;

    // Timestamp of last harvest
    uint256 public lastHarvest;

    // Minimum time between harvests
    uint256 public harvestCooldown;

    // Events
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
     * @notice Returns the total assets held by the vault
     * @dev Includes assets in vault + assets in strategy
     * TODO: Implement this function
     * - Return the sum of assets in the vault and assets in the strategy
     * - If no strategy is set, return only vault balance
     */
    function totalAssets() public view override returns (uint256) {
        // TODO: Implement
        return 0;
    }

    /**
     * @notice Harvests yield from the strategy and reinvests
     * @dev Callable by anyone, applies performance fee
     * TODO: Implement harvest logic
     * - Check cooldown period has elapsed
     * - Call strategy.harvest() to get yield
     * - Calculate and transfer performance fee
     * - Reinvest remaining yield
     * - Update lastHarvest timestamp
     * - Emit Harvested event
     */
    function harvest() external {
        // TODO: Implement
    }

    /**
     * @notice Deposits assets into the strategy
     * @param assets Amount to deposit into strategy
     * TODO: Implement strategy deposit
     * - Transfer assets from vault to strategy
     * - Call strategy.deposit()
     */
    function _depositToStrategy(uint256 assets) internal {
        // TODO: Implement
    }

    /**
     * @notice Withdraws assets from the strategy
     * @param assets Amount to withdraw from strategy
     * @return Amount actually withdrawn
     * TODO: Implement strategy withdrawal
     * - Call strategy.withdraw()
     * - Return actual amount received
     */
    function _withdrawFromStrategy(uint256 assets) internal returns (uint256) {
        // TODO: Implement
        return 0;
    }

    /**
     * @notice Hook called after deposit
     * @dev Automatically deploys assets to strategy
     */
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares)
        internal
        override
    {
        super._deposit(caller, receiver, assets, shares);

        // Deploy to strategy if one is set
        if (address(strategy) != address(0) && assets > 0) {
            _depositToStrategy(assets);
        }
    }

    /**
     * @notice Hook called before withdrawal
     * @dev Withdraws from strategy if vault doesn't have enough assets
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal override {
        // Check if we need to withdraw from strategy
        uint256 vaultBalance = IERC20(asset()).balanceOf(address(this));

        if (assets > vaultBalance && address(strategy) != address(0)) {
            uint256 needed = assets - vaultBalance;
            _withdrawFromStrategy(needed);
        }

        super._withdraw(caller, receiver, owner, assets, shares);
    }

    /**
     * @notice Sets the yield strategy
     * @param _strategy New strategy address
     * TODO: Add security checks
     * - Only owner can call
     * - Withdraw all funds from old strategy first
     * - Emit event
     */
    function setStrategy(IYieldStrategy _strategy) external onlyOwner {
        // TODO: Implement with proper migration
        address oldStrategy = address(strategy);
        strategy = _strategy;
        emit StrategyUpdated(oldStrategy, address(_strategy));
    }

    /**
     * @notice Updates the performance fee
     * @param _performanceFee New fee in basis points
     */
    function setPerformanceFee(uint256 _performanceFee) external onlyOwner {
        require(_performanceFee <= 2000, "Fee too high");
        uint256 oldFee = performanceFee;
        performanceFee = _performanceFee;
        emit PerformanceFeeUpdated(oldFee, _performanceFee);
    }

    /**
     * @notice Updates the fee recipient
     * @param _feeRecipient New fee recipient address
     */
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "Invalid recipient");
        address oldRecipient = feeRecipient;
        feeRecipient = _feeRecipient;
        emit FeeRecipientUpdated(oldRecipient, _feeRecipient);
    }

    /**
     * @notice Updates harvest cooldown period
     * @param _cooldown New cooldown in seconds
     */
    function setHarvestCooldown(uint256 _cooldown) external onlyOwner {
        harvestCooldown = _cooldown;
    }
}

/**
 * @title MockYieldSource
 * @notice Simulates a yield-generating protocol (like Aave or Compound)
 * @dev For testing purposes - generates predictable yield over time
 */
contract MockYieldSource {
    IERC20 public asset;

    // Annual Percentage Yield in basis points (e.g., 500 = 5% APY)
    uint256 public apy;

    // Mapping of user deposits
    mapping(address => uint256) public deposits;

    // Timestamp of last deposit/withdrawal for each user
    mapping(address => uint256) public lastUpdate;

    constructor(IERC20 _asset, uint256 _apy) {
        asset = _asset;
        apy = _apy;
    }

    /**
     * @notice Deposits assets and starts earning yield
     * @param amount Amount to deposit
     * TODO: Implement deposit logic
     * - Update accrued yield first
     * - Transfer tokens from user
     * - Update deposit amount
     * - Update timestamp
     */
    function deposit(uint256 amount) external {
        // TODO: Implement
    }

    /**
     * @notice Withdraws assets including accrued yield
     * @param amount Amount to withdraw
     * TODO: Implement withdrawal logic
     * - Update accrued yield first
     * - Check user has enough balance
     * - Transfer tokens to user
     * - Update deposit amount
     */
    function withdraw(uint256 amount) external {
        // TODO: Implement
    }

    /**
     * @notice Returns current balance including accrued yield
     * @param account Account to check
     * @return Current balance with yield
     * TODO: Implement balance calculation
     * - Calculate time elapsed since last update
     * - Calculate accrued yield using APY
     * - Return principal + yield
     *
     * Formula: balance + (balance * apy * timeElapsed / (365 days * 10000))
     */
    function balanceOf(address account) public view returns (uint256) {
        // TODO: Implement
        return 0;
    }

    /**
     * @notice Updates accrued yield for an account
     * @param account Account to update
     * TODO: Implement yield accrual
     * - Calculate current balance with yield
     * - Update deposits to include yield
     * - Update lastUpdate timestamp
     */
    function _accrueYield(address account) internal {
        // TODO: Implement
    }
}

/**
 * @title SimpleYieldStrategy
 * @notice Strategy that deposits into MockYieldSource
 */
contract SimpleYieldStrategy is IYieldStrategy {
    using SafeERC20 for IERC20;

    IERC20 public asset;
    MockYieldSource public yieldSource;
    address public vault;

    // Track principal deposited (excluding yield)
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
     * TODO: Implement deposit
     * - Transfer assets from vault
     * - Approve yield source
     * - Deposit to yield source
     * - Update principal
     */
    function deposit(uint256 amount) external onlyVault {
        // TODO: Implement
    }

    /**
     * @notice Withdraws assets from yield source
     * @param amount Amount to withdraw
     * @return actualAmount Amount withdrawn
     * TODO: Implement withdrawal
     * - Withdraw from yield source
     * - Transfer to vault
     * - Update principal
     */
    function withdraw(uint256 amount) external onlyVault returns (uint256 actualAmount) {
        // TODO: Implement
        return 0;
    }

    /**
     * @notice Harvests accrued yield
     * @return yield Amount of yield harvested
     * TODO: Implement harvest
     * - Get current balance from yield source
     * - Calculate yield (balance - principal)
     * - Withdraw only the yield
     * - Transfer to vault
     * - Return yield amount
     */
    function harvest() external onlyVault returns (uint256 yield) {
        // TODO: Implement
        return 0;
    }

    /**
     * @notice Returns total assets in strategy
     * @return Total assets including yield
     */
    function totalAssets() external view returns (uint256) {
        return yieldSource.balanceOf(address(this));
    }

    /**
     * @notice Returns balance for account (vault only)
     * @param account Account to check
     * @return Balance
     */
    function balanceOf(address account) external view returns (uint256) {
        if (account == vault) {
            return yieldSource.balanceOf(address(this));
        }
        return 0;
    }
}
