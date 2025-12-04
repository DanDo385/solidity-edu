# Project 48: Meta-Vault (4626→4626)

A meta-vault that wraps one or more ERC-4626 vaults, enabling yield aggregation, auto-rebalancing, and recursive vault compositions.

## Concepts

### Meta-Vault Architecture
```
User → MetaVault (ERC-4626)
          ↓
          → Underlying Vault A (ERC-4626)
          → Underlying Vault B (ERC-4626)
          → Underlying Vault C (ERC-4626)
```

A meta-vault is an ERC-4626 vault that invests in other ERC-4626 vaults rather than directly in assets. This creates a recursive structure where:
- Users deposit assets into the meta-vault
- The meta-vault deposits into underlying vaults
- The meta-vault can rebalance between vaults to optimize yield

### Recursive Share Calculations

When a user deposits assets:
```
1. User deposits 1000 DAI to MetaVault
2. MetaVault deposits 1000 DAI to UnderlyingVault
3. UnderlyingVault mints X shares to MetaVault
4. MetaVault mints Y shares to User

convertToAssets for User:
Y shares → MetaVault.convertToAssets(Y)
         → X underlying shares
         → UnderlyingVault.convertToAssets(X)
         → Z assets
```

The math is recursive:
```solidity
// Meta-vault's convertToAssets must call underlying vault's convertToAssets
function convertToAssets(uint256 shares) public view returns (uint256) {
    uint256 underlyingShares = // calculate underlying shares held
    uint256 assets = underlyingVault.convertToAssets(underlyingShares);
    return shares * assets / totalSupply();
}
```

### Performance Compounding

When both vaults generate yield, the effects compound:
```
Year 1:
- Underlying Vault: 10% APY
- Meta-Vault adds: 5% strategy alpha
- Total: ~15.5% (not 15% due to compounding)

Calculation:
- 100 DAI → 110 DAI (underlying vault)
- 110 DAI → 115.5 DAI (meta-vault's 5% on 110)
```

### Fee on Fee Calculations

If both vaults charge fees, they compound negatively:
```
Underlying Vault: 2% fee
Meta-Vault: 1% fee

Effective fee: 1 - (0.98 * 0.99) = 2.98% (not 3%)
```

This is important for users to understand total cost of nested vaults.

### Yield Aggregation

A meta-vault can aggregate yield from multiple sources:
```
MetaVault holds:
- 40% in StableVault (5% APY)
- 30% in LendingVault (8% APY)
- 30% in LiquidityVault (12% APY)

Effective APY: 0.4*5% + 0.3*8% + 0.3*12% = 8%
```

### Rebalancing Between Vaults

The meta-vault can shift capital to maximize yield:
```solidity
function rebalance() external {
    // Find vault with highest yield
    uint256 bestVaultIndex = findHighestYield();

    // Withdraw from lower-yield vaults
    for (uint256 i = 0; i < vaults.length; i++) {
        if (i != bestVaultIndex) {
            uint256 shares = vaults[i].balanceOf(address(this));
            vaults[i].redeem(shares, address(this), address(this));
        }
    }

    // Deposit all assets to best vault
    asset.approve(address(vaults[bestVaultIndex]), balance);
    vaults[bestVaultIndex].deposit(balance, address(this));
}
```

### Gas Considerations

Nested vaults have higher gas costs:
- Each operation requires multiple vault interactions
- Recursive calculations add overhead
- Rebalancing involves multiple withdrawals and deposits

Trade-off: Higher gas costs vs. better yield optimization

### Use Cases

#### 1. Yield Aggregators (Yearn-style)
```
User deposits USDC
  → MetaVault finds best yield among:
    → Aave Lending
    → Compound Lending
    → Curve LP
    → Convex Staking
```

#### 2. Risk Diversification
```
MetaVault spreads capital across multiple vaults to reduce risk:
- 50% in conservative vault (3% APY, low risk)
- 30% in moderate vault (7% APY, medium risk)
- 20% in aggressive vault (15% APY, high risk)
```

#### 3. Strategy Layering
```
Base Layer: Lending vault (provides base yield)
  → Middle Layer: Yield optimization (compounds rewards)
    → Top Layer: Auto-selling rewards (converts to base asset)
```

#### 4. Multi-Asset Exposure
```
User deposits ETH
  → MetaVault splits to:
    → 60% ETH vault
    → 40% stETH vault (liquid staking)
```

## Key Implementation Details

### Recursive Asset Calculation
```solidity
function totalAssets() public view override returns (uint256) {
    uint256 total = 0;
    for (uint256 i = 0; i < underlyingVaults.length; i++) {
        // Get our shares in underlying vault
        uint256 shares = underlyingVaults[i].balanceOf(address(this));
        // Convert to assets (recursive call)
        uint256 assets = underlyingVaults[i].convertToAssets(shares);
        total += assets;
    }
    return total;
}
```

### Deposit Strategy
```solidity
function _depositToUnderlying(uint256 assets) internal {
    if (autoRebalance) {
        // Deposit to vault with highest yield
        uint256 bestVault = _findBestVault();
        IERC20(asset()).approve(address(underlyingVaults[bestVault]), assets);
        underlyingVaults[bestVault].deposit(assets, address(this));
    } else {
        // Deposit proportionally to all vaults
        for (uint256 i = 0; i < underlyingVaults.length; i++) {
            uint256 amount = assets * allocations[i] / TOTAL_BPS;
            IERC20(asset()).approve(address(underlyingVaults[i]), amount);
            underlyingVaults[i].deposit(amount, address(this));
        }
    }
}
```

### Withdrawal Strategy
```solidity
function _withdrawFromUnderlying(uint256 assets) internal {
    uint256 remaining = assets;

    // Try to withdraw from most liquid vault first
    for (uint256 i = 0; i < underlyingVaults.length && remaining > 0; i++) {
        uint256 available = underlyingVaults[i].maxWithdraw(address(this));
        uint256 toWithdraw = remaining > available ? available : remaining;

        if (toWithdraw > 0) {
            underlyingVaults[i].withdraw(toWithdraw, address(this), address(this));
            remaining -= toWithdraw;
        }
    }

    require(remaining == 0, "Insufficient liquidity");
}
```

### Rebalancing Logic
```solidity
function rebalance() external {
    // Calculate target allocations based on yields
    uint256[] memory targetAllocations = _calculateOptimalAllocation();

    // Calculate current allocations
    uint256 totalAssets = totalAssets();
    uint256[] memory currentAssets = new uint256[](underlyingVaults.length);

    for (uint256 i = 0; i < underlyingVaults.length; i++) {
        currentAssets[i] = underlyingVaults[i].convertToAssets(
            underlyingVaults[i].balanceOf(address(this))
        );
    }

    // Rebalance: withdraw from over-allocated, deposit to under-allocated
    for (uint256 i = 0; i < underlyingVaults.length; i++) {
        uint256 target = totalAssets * targetAllocations[i] / TOTAL_BPS;

        if (currentAssets[i] > target) {
            // Withdraw excess
            uint256 excess = currentAssets[i] - target;
            underlyingVaults[i].withdraw(excess, address(this), address(this));
        }
    }

    // Deposit to under-allocated vaults
    uint256 idle = IERC20(asset()).balanceOf(address(this));
    for (uint256 i = 0; i < underlyingVaults.length; i++) {
        uint256 target = totalAssets * targetAllocations[i] / TOTAL_BPS;

        if (currentAssets[i] < target) {
            uint256 needed = target - currentAssets[i];
            uint256 toDeposit = needed > idle ? idle : needed;

            if (toDeposit > 0) {
                IERC20(asset()).approve(address(underlyingVaults[i]), toDeposit);
                underlyingVaults[i].deposit(toDeposit, address(this));
                idle -= toDeposit;
            }
        }
    }
}
```

## Security Considerations

### 1. Underlying Vault Trust
- Meta-vault is only as secure as underlying vaults
- Malicious underlying vault can drain funds
- Important to whitelist trusted vaults only

### 2. Reentrancy
- Recursive calls to multiple vaults create reentrancy risks
- Use ReentrancyGuard on all external functions
- Follow checks-effects-interactions pattern

### 3. Rounding Errors
- Multiple conversions amplify rounding errors
- Always round in favor of the vault (against users slightly)
- Monitor for accumulated rounding dust

### 4. Liquidity Risks
- Underlying vaults might have withdrawal limits
- Need to handle partial withdrawals gracefully
- Consider withdrawal queues for illiquid positions

### 5. Oracle/Price Risks
- If vaults use different pricing mechanisms
- Arbitrage opportunities between vaults
- Flash loan attacks on rebalancing

## Testing Checklist

- [ ] Deposit to single underlying vault
- [ ] Deposit split across multiple vaults
- [ ] Withdraw from single vault with sufficient liquidity
- [ ] Withdraw requiring multiple vaults
- [ ] Recursive share calculations are accurate
- [ ] Rebalancing shifts funds correctly
- [ ] Yield accumulation in underlying vaults reflects in meta-vault
- [ ] Fees compound correctly
- [ ] Handle underlying vault with withdrawal limits
- [ ] Prevent unauthorized rebalancing
- [ ] Gas costs are acceptable for operations
- [ ] Rounding errors don't accumulate significantly

## Learning Objectives

1. Understand vault composition patterns
2. Implement recursive share calculations
3. Build yield aggregation logic
4. Handle multi-vault rebalancing
5. Calculate compounding fees and yields
6. Manage liquidity across multiple sources
7. Optimize gas for nested operations
8. Design secure multi-vault systems

## Common Pitfalls

1. **Incorrect recursive math**: Forgetting to convert underlying shares to assets
2. **Rebalancing costs**: Gas costs can exceed yield gains from rebalancing
3. **Liquidity fragmentation**: Splitting too much across many vaults reduces efficiency
4. **Stale yield data**: Using outdated APY for rebalancing decisions
5. **Approval management**: Not approving each underlying vault separately
6. **Withdrawal failures**: Not handling cases where vaults have different liquidity

## Extensions

1. **Dynamic allocation**: ML-based vault selection
2. **Flash rebalancing**: Use flash loans to rebalance without fragmented liquidity
3. **Cross-chain vaults**: Aggregate yield across multiple chains
4. **Risk-adjusted allocation**: Allocate based on Sharpe ratio, not just APY
5. **Social vaults**: Users can copy successful meta-vault strategies
6. **Governance**: Token holders vote on allocation strategy

## Real-World Examples

- **Yearn Finance**: Aggregates yield across DeFi protocols
- **Idle Finance**: Rebalances between lending protocols
- **Rari Capital (Fuse)**: Pools aggregate yield from isolated markets
- **Harvest Finance**: Auto-compounds farm rewards
- **Beefy Finance**: Vault composition for optimal yields

## Resources

- [ERC-4626 Specification](https://eips.ethereum.org/EIPS/eip-4626)
- [Yearn Vaults](https://docs.yearn.finance/getting-started/products/yvaults/overview)
- [Vault Aggregation Patterns](https://github.com/yearn/yearn-vaults)
- [Yield Optimization Strategies](https://defillama.com/yields)
