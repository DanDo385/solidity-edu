# Building Custom Yield Strategies

This guide explains how to build custom yield strategies for the vault.

## Strategy Interface

All strategies must implement the `IYieldStrategy` interface:

```solidity
interface IYieldStrategy {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external returns (uint256);
    function harvest() external returns (uint256);
    function totalAssets() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}
```

## Basic Strategy Template

```solidity
contract MyCustomStrategy is IYieldStrategy {
    using SafeERC20 for IERC20;

    IERC20 public asset;
    address public vault;
    uint256 public principal;

    // Your yield source
    IYieldSource public yieldSource;

    modifier onlyVault() {
        require(msg.sender == vault, "Only vault");
        _;
    }

    constructor(
        IERC20 _asset,
        IYieldSource _yieldSource,
        address _vault
    ) {
        asset = _asset;
        yieldSource = _yieldSource;
        vault = _vault;
    }

    function deposit(uint256 amount) external onlyVault {
        // 1. Transfer assets from vault
        asset.safeTransferFrom(vault, address(this), amount);

        // 2. Deploy to yield source
        asset.forceApprove(address(yieldSource), amount);
        yieldSource.deposit(amount);

        // 3. Track principal
        principal += amount;
    }

    function withdraw(uint256 amount) external onlyVault returns (uint256) {
        // 1. Withdraw from yield source
        uint256 withdrawn = yieldSource.withdraw(amount);

        // 2. Update principal
        principal -= withdrawn;

        // 3. Transfer to vault
        asset.safeTransfer(vault, withdrawn);

        return withdrawn;
    }

    function harvest() external onlyVault returns (uint256) {
        // 1. Calculate yield
        uint256 currentBalance = yieldSource.balanceOf(address(this));
        uint256 yield = currentBalance - principal;

        if (yield == 0) return 0;

        // 2. Withdraw yield
        yieldSource.withdraw(yield);

        // 3. Transfer to vault
        asset.safeTransfer(vault, yield);

        return yield;
    }

    function totalAssets() external view returns (uint256) {
        return yieldSource.balanceOf(address(this));
    }

    function balanceOf(address account) external view returns (uint256) {
        return account == vault ? yieldSource.balanceOf(address(this)) : 0;
    }
}
```

## Example Strategies

### 1. Aave Lending Strategy

```solidity
contract AaveLendingStrategy is IYieldStrategy {
    using SafeERC20 for IERC20;

    IERC20 public asset;
    IAavePool public aavePool;
    IERC20 public aToken; // Interest-bearing token
    address public vault;
    uint256 public principal;

    constructor(
        IERC20 _asset,
        IAavePool _aavePool,
        IERC20 _aToken,
        address _vault
    ) {
        asset = _asset;
        aavePool = _aavePool;
        aToken = _aToken;
        vault = _vault;
    }

    function deposit(uint256 amount) external onlyVault {
        asset.safeTransferFrom(vault, address(this), amount);

        // Supply to Aave
        asset.forceApprove(address(aavePool), amount);
        aavePool.supply(address(asset), amount, address(this), 0);

        principal += amount;
    }

    function withdraw(uint256 amount) external onlyVault returns (uint256) {
        // Withdraw from Aave
        uint256 withdrawn = aavePool.withdraw(
            address(asset),
            amount,
            address(this)
        );

        principal -= withdrawn;
        asset.safeTransfer(vault, withdrawn);

        return withdrawn;
    }

    function harvest() external onlyVault returns (uint256) {
        // aTokens automatically increase in value
        uint256 currentBalance = aToken.balanceOf(address(this));
        uint256 yield = currentBalance - principal;

        if (yield == 0) return 0;

        // Withdraw yield
        aavePool.withdraw(address(asset), yield, address(this));
        asset.safeTransfer(vault, yield);

        return yield;
    }

    function totalAssets() external view returns (uint256) {
        return aToken.balanceOf(address(this));
    }

    function balanceOf(address account) external view returns (uint256) {
        return account == vault ? aToken.balanceOf(address(this)) : 0;
    }
}
```

### 2. Compound Strategy

```solidity
contract CompoundStrategy is IYieldStrategy {
    using SafeERC20 for IERC20;

    IERC20 public asset;
    ICToken public cToken;
    address public vault;
    uint256 public principal;

    constructor(
        IERC20 _asset,
        ICToken _cToken,
        address _vault
    ) {
        asset = _asset;
        cToken = _cToken;
        vault = _vault;
    }

    function deposit(uint256 amount) external onlyVault {
        asset.safeTransferFrom(vault, address(this), amount);

        // Mint cTokens
        asset.forceApprove(address(cToken), amount);
        require(cToken.mint(amount) == 0, "Mint failed");

        principal += amount;
    }

    function withdraw(uint256 amount) external onlyVault returns (uint256) {
        // Calculate cTokens needed
        uint256 exchangeRate = cToken.exchangeRateCurrent();
        uint256 cTokenAmount = (amount * 1e18) / exchangeRate;

        // Redeem cTokens
        require(cToken.redeem(cTokenAmount) == 0, "Redeem failed");

        uint256 withdrawn = asset.balanceOf(address(this));
        principal -= withdrawn;
        asset.safeTransfer(vault, withdrawn);

        return withdrawn;
    }

    function harvest() external onlyVault returns (uint256) {
        // Get current balance
        uint256 cTokenBalance = cToken.balanceOf(address(this));
        uint256 exchangeRate = cToken.exchangeRateCurrent();
        uint256 currentBalance = (cTokenBalance * exchangeRate) / 1e18;

        uint256 yield = currentBalance - principal;
        if (yield == 0) return 0;

        // Redeem yield
        uint256 cTokensToRedeem = (yield * 1e18) / exchangeRate;
        require(cToken.redeem(cTokensToRedeem) == 0, "Redeem failed");

        uint256 harvested = asset.balanceOf(address(this));
        asset.safeTransfer(vault, harvested);

        return harvested;
    }

    function totalAssets() external view returns (uint256) {
        uint256 cTokenBalance = cToken.balanceOf(address(this));
        uint256 exchangeRate = cToken.exchangeRateCurrent();
        return (cTokenBalance * exchangeRate) / 1e18;
    }

    function balanceOf(address account) external view returns (uint256) {
        if (account != vault) return 0;

        uint256 cTokenBalance = cToken.balanceOf(address(this));
        uint256 exchangeRate = cToken.exchangeRateCurrent();
        return (cTokenBalance * exchangeRate) / 1e18;
    }
}
```

### 3. Staking Strategy

```solidity
contract StakingStrategy is IYieldStrategy {
    using SafeERC20 for IERC20;

    IERC20 public asset;
    IStakingContract public stakingContract;
    IERC20 public rewardToken;
    address public vault;
    uint256 public principal;

    ISwapRouter public swapRouter; // To swap rewards

    constructor(
        IERC20 _asset,
        IStakingContract _stakingContract,
        IERC20 _rewardToken,
        ISwapRouter _swapRouter,
        address _vault
    ) {
        asset = _asset;
        stakingContract = _stakingContract;
        rewardToken = _rewardToken;
        swapRouter = _swapRouter;
        vault = _vault;
    }

    function deposit(uint256 amount) external onlyVault {
        asset.safeTransferFrom(vault, address(this), amount);

        // Stake tokens
        asset.forceApprove(address(stakingContract), amount);
        stakingContract.stake(amount);

        principal += amount;
    }

    function withdraw(uint256 amount) external onlyVault returns (uint256) {
        // Unstake
        stakingContract.withdraw(amount);

        principal -= amount;
        asset.safeTransfer(vault, amount);

        return amount;
    }

    function harvest() external onlyVault returns (uint256) {
        // Claim staking rewards
        stakingContract.claimReward();

        uint256 rewardBalance = rewardToken.balanceOf(address(this));
        if (rewardBalance == 0) return 0;

        // Swap rewards for underlying asset
        rewardToken.forceApprove(address(swapRouter), rewardBalance);

        uint256 yield = swapRouter.swap(
            address(rewardToken),
            address(asset),
            rewardBalance,
            0 // min out - should use oracle in production
        );

        asset.safeTransfer(vault, yield);
        return yield;
    }

    function totalAssets() external view returns (uint256) {
        return stakingContract.balanceOf(address(this));
    }

    function balanceOf(address account) external view returns (uint256) {
        return account == vault ? stakingContract.balanceOf(address(this)) : 0;
    }
}
```

### 4. LP Farming Strategy

```solidity
contract LPFarmingStrategy is IYieldStrategy {
    using SafeERC20 for IERC20;

    IERC20 public asset;
    IUniswapV2Router public router;
    IUniswapV2Pair public pair;
    IMasterChef public masterChef;
    uint256 public poolId;
    address public vault;
    uint256 public principal;

    constructor(
        IERC20 _asset,
        IUniswapV2Router _router,
        IUniswapV2Pair _pair,
        IMasterChef _masterChef,
        uint256 _poolId,
        address _vault
    ) {
        asset = _asset;
        router = _router;
        pair = _pair;
        masterChef = _masterChef;
        poolId = _poolId;
        vault = _vault;
    }

    function deposit(uint256 amount) external onlyVault {
        asset.safeTransferFrom(vault, address(this), amount);

        // Split into two tokens for LP
        uint256 halfAmount = amount / 2;

        // Swap half for pair token
        // Add liquidity
        // Stake LP tokens in MasterChef

        principal += amount;
    }

    function withdraw(uint256 amount) external onlyVault returns (uint256) {
        // Unstake LP tokens
        // Remove liquidity
        // Swap back to asset
        // Transfer to vault

        return amount;
    }

    function harvest() external onlyVault returns (uint256) {
        // Claim farm rewards
        masterChef.withdraw(poolId, 0); // Withdraw 0 to claim

        // Get reward tokens
        // Swap to asset
        // Return yield

        return 0;
    }

    function totalAssets() external view returns (uint256) {
        // Calculate value of LP position
        return 0;
    }

    function balanceOf(address account) external view returns (uint256) {
        return 0;
    }
}
```

### 5. Multi-Strategy (Advanced)

```solidity
contract MultiStrategy is IYieldStrategy {
    using SafeERC20 for IERC20;

    IERC20 public asset;
    address public vault;

    struct StrategyAllocation {
        IYieldStrategy strategy;
        uint256 allocation; // Basis points (10000 = 100%)
    }

    StrategyAllocation[] public strategies;

    constructor(IERC20 _asset, address _vault) {
        asset = _asset;
        vault = _vault;
    }

    function addStrategy(
        IYieldStrategy strategy,
        uint256 allocation
    ) external onlyOwner {
        strategies.push(StrategyAllocation(strategy, allocation));
    }

    function deposit(uint256 amount) external onlyVault {
        asset.safeTransferFrom(vault, address(this), amount);

        // Distribute across strategies based on allocation
        for (uint256 i = 0; i < strategies.length; i++) {
            uint256 strategyAmount = (amount * strategies[i].allocation) / 10000;

            asset.forceApprove(address(strategies[i].strategy), strategyAmount);
            strategies[i].strategy.deposit(strategyAmount);
        }
    }

    function withdraw(uint256 amount) external onlyVault returns (uint256) {
        uint256 withdrawn = 0;

        // Withdraw proportionally from each strategy
        for (uint256 i = 0; i < strategies.length; i++) {
            uint256 strategyAmount = (amount * strategies[i].allocation) / 10000;
            withdrawn += strategies[i].strategy.withdraw(strategyAmount);
        }

        asset.safeTransfer(vault, withdrawn);
        return withdrawn;
    }

    function harvest() external onlyVault returns (uint256) {
        uint256 totalYield = 0;

        // Harvest from all strategies
        for (uint256 i = 0; i < strategies.length; i++) {
            totalYield += strategies[i].strategy.harvest();
        }

        asset.safeTransfer(vault, totalYield);
        return totalYield;
    }

    function totalAssets() external view returns (uint256) {
        uint256 total = 0;

        for (uint256 i = 0; i < strategies.length; i++) {
            total += strategies[i].strategy.totalAssets();
        }

        return total;
    }

    function balanceOf(address account) external view returns (uint256) {
        if (account != vault) return 0;
        return this.totalAssets();
    }
}
```

## Strategy Best Practices

### 1. Always Use SafeERC20

```solidity
using SafeERC20 for IERC20;

// Good
asset.safeTransfer(vault, amount);

// Bad - might not revert on failure
asset.transfer(vault, amount);
```

### 2. Track Principal Separately

```solidity
uint256 public principal; // What we deposited
uint256 public totalAssets; // Principal + yield

function harvest() external returns (uint256) {
    uint256 currentBalance = yieldSource.balanceOf(address(this));
    uint256 yield = currentBalance - principal; // Calculate yield
    // ...
}
```

### 3. Handle Rounding Carefully

```solidity
// Always favor the vault
function withdraw(uint256 amount) external returns (uint256) {
    uint256 available = yieldSource.balanceOf(address(this));

    // Don't try to withdraw more than available
    uint256 toWithdraw = amount > available ? available : amount;

    // ...
}
```

### 4. Add Emergency Functions

```solidity
function emergencyWithdraw() external onlyOwner {
    // Withdraw everything from yield source
    uint256 balance = yieldSource.balanceOf(address(this));
    yieldSource.withdraw(balance);

    // Send to vault
    asset.safeTransfer(vault, asset.balanceOf(address(this)));
}
```

### 5. Include View Functions for Monitoring

```solidity
function getCurrentAPY() external view returns (uint256) {
    // Calculate based on recent performance
}

function getPrincipal() external view returns (uint256) {
    return principal;
}

function getUnharvestedYield() external view returns (uint256) {
    uint256 current = yieldSource.balanceOf(address(this));
    return current > principal ? current - principal : 0;
}
```

## Testing Strategies

```solidity
contract StrategyTest is Test {
    MyStrategy strategy;
    MockVault vault;
    MockYieldSource yieldSource;

    function test_Deposit() public {
        uint256 amount = 1000e18;

        vault.deposit(amount);
        strategy.deposit(amount);

        assertEq(strategy.totalAssets(), amount);
        assertEq(strategy.getPrincipal(), amount);
    }

    function test_Withdraw() public {
        strategy.deposit(1000e18);

        uint256 withdrawn = strategy.withdraw(500e18);

        assertEq(withdrawn, 500e18);
        assertEq(strategy.totalAssets(), 500e18);
    }

    function test_Harvest() public {
        strategy.deposit(1000e18);

        // Simulate yield accrual
        vm.warp(block.timestamp + 30 days);

        uint256 yield = strategy.harvest();

        assertGt(yield, 0);
        // Principal should stay the same
        assertEq(strategy.getPrincipal(), 1000e18);
    }
}
```

## Common Pitfalls

1. **Not handling slippage**: Always set minimum output amounts
2. **Ignoring fees**: Account for deposit/withdrawal fees
3. **Forgetting to update principal**: Keep accurate accounting
4. **Not validating caller**: Use `onlyVault` modifier
5. **Approving too much**: Use `forceApprove` for exact amounts
6. **Not handling edge cases**: Zero amounts, full withdrawals, etc.

## Resources

- [Yearn Strategy Template](https://github.com/yearn/yearn-vaults)
- [Harvest Finance Strategies](https://github.com/harvest-finance/harvest-strategy)
- [Beefy Finance Strategies](https://github.com/beefyfinance/beefy-contracts)
