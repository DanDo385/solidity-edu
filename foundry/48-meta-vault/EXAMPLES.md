# Meta-Vault Examples and Use Cases

This document provides practical examples of using the MetaVault for various scenarios.

## Table of Contents
1. [Basic Usage](#basic-usage)
2. [Yield Aggregation](#yield-aggregation)
3. [Rebalancing Strategies](#rebalancing-strategies)
4. [Advanced Scenarios](#advanced-scenarios)

## Basic Usage

### Example 1: Simple Deposit and Withdrawal

```solidity
// Setup
IERC20 dai = IERC20(DAI_ADDRESS);
MetaVaultSolution metaVault = MetaVaultSolution(META_VAULT_ADDRESS);

// User has 1000 DAI
uint256 depositAmount = 1000e18;

// Approve meta-vault
dai.approve(address(metaVault), depositAmount);

// Deposit and receive shares
uint256 shares = metaVault.deposit(depositAmount, msg.sender);

// Wait for some time as vaults earn yield...

// Check how much you can withdraw
uint256 withdrawable = metaVault.maxWithdraw(msg.sender);
console.log("Can withdraw:", withdrawable); // > 1000 DAI (due to yield)

// Withdraw all
metaVault.redeem(shares, msg.sender, msg.sender);
```

### Example 2: Preview Functions

```solidity
// Before depositing, preview how many shares you'll get
uint256 expectedShares = metaVault.previewDeposit(1000e18);

// Before withdrawing, preview how many shares will be burned
uint256 sharesToBurn = metaVault.previewWithdraw(500e18);

// Check your current asset value
uint256 myShares = metaVault.balanceOf(msg.sender);
uint256 myAssets = metaVault.convertToAssets(myShares);
```

## Yield Aggregation

### Example 3: Multi-Vault Yield Strategy

```solidity
// Deploy meta-vault
MetaVaultSolution metaVault = new MetaVaultSolution(
    IERC20(DAI_ADDRESS),
    "Diversified Yield Vault",
    "divYLD"
);

// Add multiple underlying vaults with different strategies
metaVault.addVault(aaveLendingVault, 4000);     // 40% Aave lending
metaVault.addVault(compoundLendingVault, 3000); // 30% Compound lending
metaVault.addVault(curveLPVault, 2000);         // 20% Curve LP
metaVault.addVault(yearnVault, 1000);           // 10% Yearn strategy

// Users deposit and get diversified yield exposure
dai.approve(address(metaVault), 10000e18);
metaVault.deposit(10000e18, msg.sender);

// Assets are automatically distributed:
// - 4000 DAI → Aave (e.g., 5% APY)
// - 3000 DAI → Compound (e.g., 4% APY)
// - 2000 DAI → Curve (e.g., 8% APY)
// - 1000 DAI → Yearn (e.g., 6% APY)
// Effective APY ≈ 5.5%
```

### Example 4: Risk-Adjusted Allocation

```solidity
// Conservative allocation (lower risk)
metaVault.addVault(aaveVault, 6000);      // 60% stable lending
metaVault.addVault(compoundVault, 3000);  // 30% stable lending
metaVault.addVault(curveVault, 1000);     // 10% LP (higher risk)

// Aggressive allocation (higher risk/reward)
metaVault.addVault(yearnVault, 3000);     // 30% active strategies
metaVault.addVault(convexVault, 4000);    // 40% boosted rewards
metaVault.addVault(curveLPVault, 3000);   // 30% liquidity provision
```

## Rebalancing Strategies

### Example 5: Manual Rebalancing

```solidity
// Check if rebalancing is needed
bool needsRebalance = metaVault.needsRebalancing();

if (needsRebalance) {
    // View current vs target allocations
    uint256[] memory current = metaVault.getCurrentAllocations();
    uint256[] memory target = metaVault.getTargetAllocations();

    for (uint256 i = 0; i < current.length; i++) {
        console.log("Vault", i, "- Current:", current[i], "Target:", target[i]);
    }

    // Rebalance to match targets
    metaVault.rebalance();
}
```

### Example 6: Auto-Rebalance Mode

```solidity
// Enable auto-rebalance mode
metaVault.setAutoRebalance(true);

// Now all new deposits go to the highest-yield vault
dai.approve(address(metaVault), 5000e18);
metaVault.deposit(5000e18, msg.sender);

// If vault B has highest yield (2% vs 1%), all 5000 DAI goes there
// This maximizes yield but may create unbalanced allocation
```

### Example 7: Shift to Higher Yield Vault

```solidity
// Initial setup: Equal allocation
metaVault.addVault(vaultA, 5000); // 50%
metaVault.addVault(vaultB, 5000); // 50%

// After monitoring, vault B shows consistently higher yields
// Update allocation to favor vault B
metaVault.updateAllocation(0, 3000); // Vault A: 30%
metaVault.updateAllocation(1, 7000); // Vault B: 70%

// Rebalance to shift funds
metaVault.rebalance();

// Now 70% of assets are in the higher-yielding vault B
```

### Example 8: Periodic Rebalancing

```solidity
// Off-chain keeper/bot script (pseudo-code)
while (true) {
    // Wait for rebalance interval (e.g., 24 hours)
    wait(24 hours);

    if (metaVault.needsRebalancing()) {
        // Calculate gas cost
        uint256 gasCost = estimateGas(metaVault.rebalance);

        // Calculate potential yield benefit
        uint256 yieldBenefit = calculateYieldImprovement();

        // Only rebalance if benefit > cost
        if (yieldBenefit > gasCost * 2) {
            metaVault.rebalance();
        }
    }
}
```

## Advanced Scenarios

### Example 9: Emergency Withdrawal

```solidity
// If an underlying vault is compromised
// Owner can emergency withdraw all funds

// This withdraws from ALL underlying vaults
metaVault.emergencyWithdrawAll();

// Funds are now idle in the meta-vault
uint256 idle = dai.balanceOf(address(metaVault));

// Users can still withdraw their share
metaVault.withdraw(userAmount, msg.sender, msg.sender);

// Later, can add new safe vaults and rebalance
metaVault.addVault(newSafeVault, 10000);
metaVault.rebalance(); // Deposits idle funds to new vault
```

### Example 10: Monitoring Vault Performance

```solidity
// Helper function to monitor each vault's performance
function monitorVaultPerformance(MetaVaultSolution metaVault) external view {
    uint256 vaultCount = metaVault.getVaultCount();
    IERC4626[] memory vaults = metaVault.getVaults();

    for (uint256 i = 0; i < vaultCount; i++) {
        // Get our position in this vault
        uint256 shares = metaVault.getVaultShares(i);
        uint256 assets = metaVault.getVaultAssets(i);

        // Calculate share price (higher = better yield so far)
        uint256 sharePrice = vaults[i].convertToAssets(1e18);

        console.log("Vault", i, ":");
        console.log("  Our shares:", shares);
        console.log("  Our assets:", assets);
        console.log("  Share price:", sharePrice);
    }
}
```

### Example 11: Yield Comparison with Direct Investment

```solidity
// Compare meta-vault yield vs direct vault investment
contract YieldComparison {
    IERC20 public asset;
    MetaVaultSolution public metaVault;
    IERC4626 public directVault;

    function compareYield(uint256 amount) external {
        // Invest in meta-vault
        asset.approve(address(metaVault), amount);
        uint256 metaShares = metaVault.deposit(amount, address(this));

        // Invest same amount directly
        asset.approve(address(directVault), amount);
        uint256 directShares = directVault.deposit(amount, address(this));

        // Wait for yield accumulation...
        // (In practice, would wait days/weeks)

        // Compare results
        uint256 metaYield = metaVault.convertToAssets(metaShares) - amount;
        uint256 directYield = directVault.convertToAssets(directShares) - amount;

        console.log("Meta-vault yield:", metaYield);
        console.log("Direct vault yield:", directYield);

        // Meta-vault may have:
        // - Lower yield (due to diversification)
        // - Higher yield (due to smart rebalancing)
        // - Lower risk (due to diversification)
    }
}
```

### Example 12: Fee Analysis

```solidity
// Understanding compounding fees
function analyzeFees(
    IERC4626 underlyingVault,
    MetaVaultSolution metaVault
) external view {
    // If underlying vault has 2% fee and meta-vault has 1% fee:
    // User deposits 100 tokens

    // After 1 year with 10% gross yield:
    // Gross: 110 tokens
    // Underlying vault fee: 110 * 2% = 2.2 tokens → Net: 107.8
    // Meta-vault fee: 107.8 * 1% = 1.078 tokens → Net: 106.722

    // Effective total fee: 100 → 106.722 = 3.278% fee
    // (Not 3% due to compounding)

    // Calculate actual fee from share price
    uint256 metaSharePrice = metaVault.convertToAssets(1e18);
    uint256 underlyingSharePrice = underlyingVault.convertToAssets(1e18);

    // Effective fee = 1 - (metaSharePrice / underlyingSharePrice)
}
```

### Example 13: Flash Rebalancing (Advanced)

```solidity
// Use flash loans to rebalance without fragmenting liquidity
contract FlashRebalancer {
    MetaVaultSolution public metaVault;
    IFlashLoanProvider public flashLoan;

    function flashRebalance() external {
        // Calculate how much to move
        uint256 amountToMove = calculateRebalanceAmount();

        // Take flash loan
        flashLoan.flashLoan(
            address(this),
            amountToMove,
            abi.encodeWithSignature("executeRebalance(uint256)", amountToMove)
        );
    }

    function executeRebalance(uint256 amount) external {
        // 1. Use flash loan to deposit to target vault
        asset.approve(targetVault, amount);
        targetVault.deposit(amount, address(metaVault));

        // 2. Withdraw from source vault
        metaVault.withdrawFromVault(sourceVault, amount);

        // 3. Repay flash loan
        asset.transfer(address(flashLoan), amount + fee);

        // Result: Rebalanced without fragmenting liquidity across vaults
    }
}
```

### Example 14: Integration with Yield Optimizer

```solidity
// Meta-vault as part of larger yield optimization strategy
contract YieldOptimizer {
    MetaVaultSolution[] public metaVaults;
    mapping(IERC20 => MetaVaultSolution) public assetToMetaVault;

    // User deposits any asset, gets optimal yield
    function deposit(IERC20 asset, uint256 amount) external {
        MetaVaultSolution metaVault = assetToMetaVault[asset];

        if (address(metaVault) == address(0)) {
            // Create new meta-vault for this asset
            metaVault = new MetaVaultSolution(
                asset,
                string(abi.encodePacked("Optimized ", asset.symbol())),
                string(abi.encodePacked("opt", asset.symbol()))
            );

            // Add best vaults for this asset
            addBestVaults(metaVault, asset);

            assetToMetaVault[asset] = metaVault;
            metaVaults.push(metaVault);
        }

        // Deposit to meta-vault
        asset.transferFrom(msg.sender, address(this), amount);
        asset.approve(address(metaVault), amount);
        metaVault.deposit(amount, msg.sender);
    }

    function addBestVaults(MetaVaultSolution metaVault, IERC20 asset) internal {
        // Query off-chain API for best vaults
        // Add top 3 vaults with optimal allocation
        // This is where the "smart" yield aggregation happens
    }
}
```

## Gas Optimization Tips

### Example 15: Batch Operations

```solidity
// Instead of multiple small deposits
// BAD: High gas cost
for (uint256 i = 0; i < 10; i++) {
    metaVault.deposit(100e18, msg.sender);
}

// GOOD: Single deposit
metaVault.deposit(1000e18, msg.sender);

// Rebalancing is expensive, so do it strategically
// Check if yield benefit exceeds gas cost
uint256 gasPrice = tx.gasprice;
uint256 rebalanceGasCost = 300000 * gasPrice; // Estimate
uint256 yieldImprovement = estimateYieldImprovement();

if (yieldImprovement > rebalanceGasCost) {
    metaVault.rebalance();
}
```

## Testing Scenarios

### Example 16: Foundry Test Setup

```solidity
// See test/Project48.t.sol for comprehensive tests
// Here's a quick test scenario:

function testUserDepositAndYield() public {
    // Setup
    asset.mint(user, 1000e18);

    vm.startPrank(user);
    asset.approve(address(metaVault), 1000e18);
    uint256 shares = metaVault.deposit(1000e18, user);
    vm.stopPrank();

    // Simulate yield in underlying vaults
    // (In tests, we use mock vaults with accrueYield())
    vaultA.accrueYield(); // +1%
    vaultB.accrueYield(); // +2%

    // Check user gained yield
    uint256 newAssets = metaVault.convertToAssets(shares);
    assertGt(newAssets, 1000e18, "User should have gained yield");

    // User withdraws
    vm.prank(user);
    uint256 withdrawn = metaVault.redeem(shares, user, user);
    assertGt(withdrawn, 1000e18, "User should withdraw more than deposited");
}
```

## Real-World Integration

### Example 17: Yearn-style Strategy

```solidity
// Simplified version of how Yearn might use meta-vaults
contract YearnStrategy {
    MetaVaultSolution public metaVault;

    constructor(IERC20 asset) {
        metaVault = new MetaVaultSolution(asset, "Yearn Meta", "yMETA");

        // Add various strategies as underlying vaults
        metaVault.addVault(aaveStrategy, 3000);
        metaVault.addVault(compoundStrategy, 3000);
        metaVault.addVault(curveStrategy, 2000);
        metaVault.addVault(convexStrategy, 2000);

        // Enable auto-rebalance to always use best strategy
        metaVault.setAutoRebalance(true);
    }

    // Harvest rewards and compound
    function harvest() external {
        // Each underlying strategy harvests its rewards
        // Meta-vault's totalAssets increases
        // User share value increases automatically
    }

    // Migrate to new strategy
    function migrate(IERC4626 oldStrategy, IERC4626 newStrategy) external {
        // Remove old strategy (withdraws all funds)
        metaVault.removeVault(findVaultIndex(oldStrategy));

        // Add new strategy
        metaVault.addVault(newStrategy, 3000);

        // Rebalance
        metaVault.rebalance();
    }
}
```

## Conclusion

The meta-vault pattern is powerful for:
- **Yield Aggregation**: Combine multiple yield sources
- **Risk Management**: Diversify across protocols
- **Flexibility**: Easy to add/remove strategies
- **Optimization**: Auto-rebalance to best yields
- **Composability**: Vaults can wrap other vaults recursively

Key considerations:
- Gas costs vs yield benefits
- Trust in underlying vaults
- Complexity vs user understanding
- Rebalancing frequency
- Fee compounding effects
