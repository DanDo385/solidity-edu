# Project 49: Leverage Looping Vault

A sophisticated DeFi vault that implements leveraged yield strategies using borrow-deposit loops on lending protocols. This project demonstrates advanced risk management, liquidation prevention, and automated deleverage mechanisms.

## Learning Objectives

- Understand leverage looping mechanics in DeFi
- Implement safe borrow-deposit-borrow cycles
- Calculate and manage leverage ratios
- Implement liquidation prevention strategies
- Build auto-deleverage mechanisms
- Model interest rate impacts
- Manage collateral health factors

## Leverage Looping Mechanics

### Basic Concept: Amplifying Yield Through Leverage

**FIRST PRINCIPLES: Leverage and Compound Interest**

Leverage looping amplifies yield by recursively depositing and borrowing the same asset. This is a powerful but risky DeFi strategy!

**CONNECTION TO PROJECT 11, 20, & 43**:
- **Project 11**: ERC-4626 vault standard
- **Project 20**: Share-based accounting
- **Project 43**: Yield-bearing vaults
- **Project 49**: Leveraged yield strategies!

**UNDERSTANDING LEVERAGE LOOPING**:

Leverage looping amplifies yield by recursively depositing and borrowing the same asset:

```
Leverage Loop Example:
┌─────────────────────────────────────────┐
│ Step 1: Deposit 100 ETH as collateral   │
│   Collateral: 100 ETH                   │
│   Debt: 0 ETH                            │
│   ↓                                      │
│ Step 2: Borrow 75 ETH (75% LTV)        │
│   Collateral: 100 ETH                   │
│   Debt: 75 ETH                           │
│   ↓                                      │
│ Step 3: Deposit 75 ETH as collateral    │
│   Collateral: 175 ETH                   │ ← Increased!
│   Debt: 75 ETH                           │
│   ↓                                      │
│ Step 4: Borrow 56.25 ETH (75% of 75)    │
│   Collateral: 175 ETH                   │
│   Debt: 131.25 ETH                       │ ← Increased!
│   ↓                                      │
│ Step 5: Repeat...                       │
│   ↓                                      │
│ Final Position:                          │
│   Total Collateral: ~400 ETH            │ ← Amplified!
│   Total Debt: ~300 ETH                  │ ← Borrowed!
│   Leverage: 4x                           │ ← 4× exposure!
└─────────────────────────────────────────┘
```

**WHY LOOP?** (Yield Amplification):

If a lending protocol offers:
- **Supply APY**: 3% (earn on deposits)
- **Borrow APY**: 2% (pay on borrows)
- **Net Spread**: 1% (profit margin)

**Without leverage**:
- Deposit: 100 ETH
- Earn: 100 ETH × 3% = 3 ETH/year
- Net: 3 ETH/year (3% return)

**With 4x leverage**:
- Total Collateral: 400 ETH (4× initial)
- Earn: 400 ETH × 3% = 12 ETH/year (on collateral)
- Pay: 300 ETH × 2% = 6 ETH/year (on debt)
- **Net**: 6 ETH/year (6% on initial capital!)
- **Amplification**: 2× return compared to unleveraged!

**UNDERSTANDING THE RISK** (from Project 46 knowledge):

```
Liquidation Risk:
┌─────────────────────────────────────────┐
│ Leverage: 4x                            │
│ Collateral: 400 ETH                     │
│ Debt: 300 ETH                           │
│ Health Factor: 1.33                      │ ← Close to liquidation!
│                                          │
│ If price drops 25%:                     │
│   Collateral: 300 ETH (400 × 0.75)     │ ← Decreased!
│   Debt: 300 ETH (unchanged)             │
│   Health Factor: 1.0                    │ ← LIQUIDATION! 💥
└─────────────────────────────────────────┘
```

**REAL-WORLD ANALOGY**: 
Like buying a house with a mortgage:
- **Deposit** = Initial capital (100 ETH)
- **Borrow** = Mortgage (300 ETH)
- **Total Position** = House value (400 ETH)
- **Leverage** = 4× (4× exposure with 1× capital)
- **Risk** = If house price drops, you can lose everything!

### The Math Behind Loops

For a target leverage ratio `L` with max LTV `ltv`:

```
Total Iterations needed: log(1 - L × (1 - ltv)) / log(ltv)

Example: 4x leverage at 75% LTV
= log(1 - 4 × 0.25) / log(0.75)
≈ 5 iterations
```

Maximum theoretical leverage:
```
Max Leverage = 1 / (1 - ltv)

At 75% LTV: 1 / 0.25 = 4x maximum
At 80% LTV: 1 / 0.20 = 5x maximum
At 90% LTV: 1 / 0.10 = 10x maximum (very risky!)
```

## Risk Buffers and Safety Margins

### Health Factor

Most lending protocols use a health factor:

```
Health Factor = (Collateral × Liquidation Threshold) / Debt

Safe: HF > 1.5
Warning: HF 1.2 - 1.5
Danger: HF 1.0 - 1.2
Liquidation: HF < 1.0
```

### Buffer Calculation

Always maintain a safety buffer:

```solidity
// Target: 4x leverage at 75% LTV
// Liquidation: 80% LTV

Current LTV = Debt / Collateral = 75%
Liquidation LTV = 80%
Buffer = (80% - 75%) / 80% = 6.25%

// Recommended: 10-20% buffer from liquidation
Safe Target LTV = Liquidation LTV × 0.85
```

### Dynamic Buffer Sizing

Adjust buffers based on market conditions:

```
High Volatility (e.g., ETH):
- Normal: 15% buffer
- High vol: 25% buffer

Low Volatility (e.g., stablecoins):
- Normal: 5% buffer
- High vol: 10% buffer
```

## Liquidation Bands

### Liquidation Threshold

Each asset has a liquidation threshold (LT):

```
Asset          | Max LTV | Liq. Threshold | Max Leverage
---------------|---------|----------------|-------------
ETH            | 80%     | 82.5%          | 5.0x
WBTC           | 75%     | 80%            | 4.0x
stETH          | 90%     | 93%            | 10.0x
USDC (stable)  | 90%     | 95%            | 10.0x
```

### Price-Based Liquidation Bands

Monitor price thresholds:

```
Entry Price: $2,000 ETH
Collateral: 100 ETH
Debt: 150,000 USDC
Current LTV: 75%
Liquidation LTV: 82.5%

Liquidation Price = Entry Price × (Current LTV / Liq LTV)
                  = $2,000 × (0.75 / 0.825)
                  = $1,818

Warning Price (10% buffer): $2,000
Danger Price (5% buffer): $1,909
```

### Multi-Asset Liquidation

For correlated assets, calculate joint liquidation risk:

```
Portfolio:
- 100 ETH collateral ($200,000)
- 50 WBTC collateral ($2,000,000)
- Total: $2,200,000
- Debt: 1,650,000 USDC
- Weighted LTV: 75%

If ETH -20% AND WBTC -15%:
- ETH value: $160,000
- WBTC value: $1,700,000
- Total: $1,860,000
- LTV: 88.7% → LIQUIDATED
```

## Interest Rate Modeling

### Variable Interest Rates

Most protocols use utilization-based rates:

```
Utilization = Total Borrows / Total Deposits

Base Rate: 0%
Slope 1 (U < 80%): 4% at optimal
Slope 2 (U > 80%): up to 100%

Borrow Rate = Base + Utilization × Slope1 (if U < optimal)
            = Base + Optimal Rate + (U - Optimal) × Slope2

Supply Rate = Borrow Rate × Utilization × (1 - Reserve Factor)
```

### Interest Rate Example (Aave V3)

```
Utilization: 70%
Base: 0%
Slope1: 4% / 80% = 0.05
Slope2: 96% / 20% = 4.8

Borrow Rate = 0% + 70% × 0.05 = 3.5%
Supply Rate = 3.5% × 70% × 0.9 = 2.205%

Net Spread = 2.205% - 3.5% = -1.295%
```

### Compound Interest Calculation

Interest compounds every block:

```solidity
// Aave uses ray math (1e27 precision)
function calculateCompoundedInterest(
    uint256 rate,
    uint256 lastUpdateTimestamp
) internal view returns (uint256) {
    uint256 timeDelta = block.timestamp - lastUpdateTimestamp;

    // Linear for small periods
    if (timeDelta == 0) return RAY;

    // exp = rate × timeDelta
    uint256 exp = rate * timeDelta;

    // Simple compound: (1 + rate/n)^n ≈ e^rate
    // For precision, use binomial expansion
    uint256 compounded = RAY + exp + (exp * exp) / (2 * RAY);

    return compounded;
}
```

### Net APY Calculation

```
Leverage: 4x
Supply APY: 3%
Borrow APY: 2.5%
Collateral: 400 ETH equivalent
Debt: 300 ETH equivalent

Annual Supply Yield = 400 × 3% = 12 ETH
Annual Borrow Cost = 300 × 2.5% = 7.5 ETH
Net Yield = 12 - 7.5 = 4.5 ETH
Net APY on Initial Capital (100 ETH) = 4.5%

If borrow rate increases to 4%:
Annual Borrow Cost = 300 × 4% = 12 ETH
Net Yield = 12 - 12 = 0 ETH (break-even!)
```

## Deleverage Strategies

### Proportional Deleverage

Reduce leverage by withdrawing collateral and repaying debt proportionally:

```
Current: 400 ETH collateral, 300 ETH debt (4x leverage)
Target: 3x leverage

Steps:
1. Calculate target debt: 100 initial × (3 - 1) = 200 ETH
2. Debt to repay: 300 - 200 = 100 ETH
3. Collateral to withdraw: 100 / 0.75 = 133.33 ETH

Loop:
- Repay 25 ETH debt
- Withdraw 33.33 ETH collateral
- Repeat 4 times
```

### Emergency Deleverage

Fast deleverage during market crashes:

```solidity
function emergencyDeleverage(uint256 targetHealthFactor) external {
    while (getHealthFactor() < targetHealthFactor) {
        // Withdraw maximum safe amount
        uint256 maxWithdraw = calculateMaxWithdraw();

        // Withdraw collateral
        lendingPool.withdraw(asset, maxWithdraw, address(this));

        // Repay debt
        uint256 repayAmount = min(maxWithdraw, totalDebt);
        lendingPool.repay(asset, repayAmount, address(this));

        // Check if we can continue
        if (maxWithdraw < minThreshold) break;
    }
}
```

### Flash Loan Deleverage

Most capital-efficient deleverage using flash loans:

```
Current: 400 ETH collateral, 300 ETH debt

1. Flash loan 300 ETH
2. Repay entire debt (300 ETH)
3. Withdraw all collateral (400 ETH)
4. Repay flash loan (300 ETH + fee)
5. Keep remaining (100 ETH - fee)

Cost: Only flash loan fee (~0.09%)
Time: Single transaction
```

### Partial Deleverage on Drift

Auto-rebalance when LTV drifts:

```solidity
function rebalance() external {
    uint256 currentLTV = getCurrentLTV();
    uint256 targetLTV = getTargetLTV();

    // Allow 2% drift before rebalancing
    if (abs(currentLTV - targetLTV) < 0.02) return;

    if (currentLTV > targetLTV) {
        // Over-leveraged: deleverage
        uint256 excessDebt = calculateExcessDebt();
        deleverageByAmount(excessDebt);
    } else {
        // Under-leveraged: can leverage more
        uint256 additionalBorrow = calculateAdditionalBorrow();
        leverageByAmount(additionalBorrow);
    }
}
```

## Real-World Examples

### Aave V3 ETH Loop

```
Protocol: Aave V3 Ethereum
Asset: wstETH (wrapped staked ETH)
Max LTV: 90%
Liquidation Threshold: 93%
Target Leverage: 8x
Safety Buffer: 15%

Current Rates (May 2024):
- wstETH Supply APY: 2.5%
- wstETH Borrow APY: 2.2%
- stETH Staking APY: 3.5%

Combined Yield:
Base Staking: 3.5% on 800 wstETH = 28 wstETH
Supply Interest: 2.5% on 800 wstETH = 20 wstETH
Borrow Cost: 2.2% on 700 wstETH = -15.4 wstETH
Net: 32.6 wstETH on 100 initial = 32.6% APY!

Risk: 5% price drop → liquidation
```

### Compound V3 USDC Loop

```
Protocol: Compound V3
Asset: USDC
Max LTV: 90%
Liquidation Threshold: 93%
Target Leverage: 9x
Safety Buffer: 10%

Current Rates:
- USDC Supply APY: 5%
- USDC Borrow APY: 4.5%
- COMP Rewards: +2% APY

Combined Yield:
Supply: 5% on 900 USDC = 45 USDC
Rewards: 2% on 900 USDC = 18 USDC
Borrow Cost: 4.5% on 800 USDC = -36 USDC
Net: 27 USDC on 100 initial = 27% APY

Risk: Minimal (stablecoin), but rate risk
```

### Morpho ETH Optimizer Loop

```
Protocol: Morpho (Aave optimizer)
Asset: ETH
Improvement: Matched peer-to-peer lending
Average LTV: 75%
Target Leverage: 4x

Morpho improves rates via P2P matching:
- Standard Aave Supply: 3%
- Morpho Enhanced Supply: 3.5% (+0.5%)
- Standard Aave Borrow: 2.5%
- Morpho Enhanced Borrow: 2.2% (-0.3%)

Increased spread: 0.8% → more profitable leverage!
```

## Implementation Checklist

### Core Features
- [ ] Leverage loop execution
- [ ] Deleverage loop execution
- [ ] Health factor monitoring
- [ ] Automatic rebalancing
- [ ] Emergency shutdown
- [ ] Flash loan integration

### Risk Management
- [ ] LTV calculation
- [ ] Health factor checks
- [ ] Price oracle integration
- [ ] Liquidation threshold monitoring
- [ ] Safety buffer enforcement
- [ ] Slippage protection

### Gas Optimizations
- [ ] Batch operations
- [ ] Optimal loop iterations
- [ ] Storage packing
- [ ] Minimal external calls
- [ ] Event emission strategy

### User Features
- [ ] Deposit/Withdraw
- [ ] Leverage adjustment
- [ ] Yield claiming
- [ ] Position metrics
- [ ] Profit/Loss tracking

## Testing Scenarios

1. **Basic Loop**: Execute 5-iteration leverage loop
2. **Target Leverage**: Achieve exact 4x leverage
3. **Deleverage**: Reduce from 4x to 2x
4. **Emergency**: Deleverage on health factor drop
5. **Interest Accrual**: Simulate 1 year of interest
6. **Market Crash**: 30% price drop simulation
7. **Liquidation Prevention**: Auto-deleverage before liquidation
8. **Flash Loan**: One-tx deleverage via flash loan
9. **Rate Changes**: Handle dynamic interest rates
10. **Dust Handling**: Manage remaining wei amounts

## Advanced Concepts

### Cross-Protocol Leverage

Use multiple protocols for better rates:

```
1. Deposit ETH on Aave (best supply rate: 3%)
2. Borrow USDC on Aave
3. Swap USDC → ETH
4. Deposit ETH on Compound (best borrow rate: 2%)
5. Repeat with cross-protocol optimization
```

### Automated Liquidation Protection

```solidity
// Keeper system
function checkUpkeep() external view returns (bool) {
    uint256 hf = getHealthFactor();
    return hf < 1.5; // Threshold for action
}

function performUpkeep() external {
    uint256 hf = getHealthFactor();

    if (hf < 1.2) {
        // Critical: aggressive deleverage
        emergencyDeleverage(1.8);
    } else if (hf < 1.5) {
        // Warning: partial deleverage
        partialDeleverage(0.1); // Reduce 10%
    }
}
```

### Yield Compounding

Auto-compound earned yield back into the position:

```solidity
function compound() external {
    // Claim rewards (if any)
    claimRewards();

    // Get current supply balance
    uint256 earned = getCurrentSupplyBalance() - lastSupplyBalance;

    // If earned enough to make it worthwhile
    if (earned > minCompoundAmount) {
        // Leverage up the earned amount
        leverageAmount(earned);
        lastSupplyBalance = getCurrentSupplyBalance();
    }
}
```

## Security Considerations

1. **Oracle Manipulation**: Use TWAP or multiple oracles
2. **Flash Loan Attacks**: Protect price-sensitive operations
3. **Reentrancy**: Use checks-effects-interactions
4. **Integer Overflow**: Use SafeMath or 0.8+ built-in checks
5. **Front-running**: Consider MEV protection
6. **Emergency Pause**: Implement circuit breakers
7. **Upgradeability**: Be careful with storage layout
8. **Access Control**: Protect privileged functions

## Gas Optimization Tips

```solidity
// ❌ Bad: Multiple external calls
for (uint i = 0; i < 5; i++) {
    lendingPool.deposit(amount);
    lendingPool.borrow(amount);
}

// ✅ Good: Batch when possible
uint256[] memory amounts = new uint256[](5);
lendingPool.depositBatch(amounts);
lendingPool.borrowBatch(amounts);

// ✅ Good: Calculate optimal iterations
uint256 iterations = calculateOptimalIterations(targetLeverage);
```

## Resources

- [Aave V3 Documentation](https://docs.aave.com/developers/)
- [Compound V3 Docs](https://docs.compound.finance/)
- [DeFi Leverage Guide](https://blog.instadapp.io/defi-leverage-explained/)
- [Liquidation Mechanics](https://www.paradigm.xyz/2020/11/so-you-want-to-use-a-price-oracle)
- [Interest Rate Models](https://docs.aave.com/risk/liquidity-risk/borrow-interest-rate)

## Getting Started

1. Review the skeleton contract in `src/Project49.sol`
2. Study the complete solution in `src/solution/Project49Solution.sol`
3. Run tests: `forge test --match-path test/Project49.t.sol -vv`
4. Experiment with different leverage ratios and safety buffers
5. Try implementing flash loan deleverage

Good luck building your leverage looping vault!
