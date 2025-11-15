# Project 43: Yield-Bearing Vault

A comprehensive implementation of a yield-bearing vault that integrates with external yield strategies, implements auto-compounding, and manages performance fees.

## Overview

Yield-bearing vaults are smart contracts that accept user deposits and automatically deploy those assets into yield-generating strategies. They provide:

- **Simplified Yield Access**: Users deposit once and earn yield automatically
- **Strategy Abstraction**: The vault handles complex DeFi interactions
- **Auto-Compounding**: Harvested yields are reinvested for compound growth
- **Shared Gas Costs**: One harvest benefits all depositors
- **ERC4626 Compatibility**: Standard vault interface for composability

## Learning Objectives

1. Understand yield vault mechanics and the ERC4626 standard
2. Implement strategy patterns for modular yield generation
3. Handle harvest and reinvest operations
4. Manage totalAssets() drift and share price growth
5. Calculate APY and simulate compound interest
6. Implement performance fee mechanisms
7. Integrate with lending protocols and other yield sources

## Core Concepts

### Yield-Bearing Vault Mechanics

A yield vault manages the relationship between shares and assets:

```
Initial State:
- User deposits 100 tokens
- Receives 100 shares (1:1 ratio)

After Yield Accrual:
- Total assets: 110 tokens (10 from yield)
- Total shares: 100 shares
- Share price: 1.1 tokens per share
- User can redeem 100 shares for 110 tokens
```

**Key Formula:**
```
shareValue = totalAssets / totalSupply
```

### Strategy Pattern

Vaults use pluggable strategies to generate yield:

```
┌──────────────────┐
│   Yield Vault    │
│  (User Facing)   │
└────────┬─────────┘
         │
         │ allocates funds
         ▼
┌──────────────────┐
│    Strategy      │
│ (Yield Logic)    │
└────────┬─────────┘
         │
         │ interacts with
         ▼
┌──────────────────┐
│  Yield Source    │
│ (e.g., Aave,     │
│  Compound, etc)  │
└──────────────────┘
```

**Strategy Types:**
- **Lending**: Deposit to Aave/Compound for interest
- **Staking**: Stake tokens for rewards
- **LP Farming**: Provide liquidity and farm tokens
- **Mixed**: Combine multiple strategies

### Harvest and Reinvest Mechanism

The harvest process captures accrued yield and compounds it:

```solidity
function harvest() external {
    // 1. Claim yield from strategy
    uint256 yield = strategy.harvest();

    // 2. Calculate and take performance fee
    uint256 fee = yield * performanceFee / 10000;

    // 3. Reinvest remaining yield
    uint256 reinvestAmount = yield - fee;
    strategy.deposit(reinvestAmount);

    // 4. totalAssets increases → share price increases
    // No new shares minted → existing shares worth more
}
```

### totalAssets() Drift Over Time

The `totalAssets()` value changes as yield accrues:

```
Block 100:  totalAssets = 1000 tokens
Block 200:  totalAssets = 1020 tokens (+2% yield)
Block 300:  totalAssets = 1040.4 tokens (+2% on new total)
```

This is measured without harvesting - just tracking underlying value.

### APY Calculations

**Simple Interest APY:**
```
APY = (endValue - startValue) / startValue * (365 days / timePeriod)
```

**Compound APY (more accurate):**
```
APY = (endValue / startValue) ^ (365 days / timePeriod) - 1
```

**Example:**
```
Start: 1000 tokens
After 30 days: 1020 tokens
Simple APY: (20/1000) * (365/30) = 24.33%
Compound APY: (1020/1000)^(365/30) - 1 = 27.44%
```

### Compound Interest Simulation

Compound interest occurs when harvested yield is reinvested:

```
Year 1: 100 → 110 (10% APY)
Year 2: 110 → 121 (10% on 110)
Year 3: 121 → 133.1 (10% on 121)

Formula: FV = PV * (1 + r)^t
```

**Harvest Frequency Impact:**
```
Daily Compound:   (1 + 0.10/365)^365 - 1 = 10.52% effective
Weekly Compound:  (1 + 0.10/52)^52 - 1 = 10.51% effective
Monthly Compound: (1 + 0.10/12)^12 - 1 = 10.47% effective
Yearly Compound:  (1 + 0.10/1)^1 - 1 = 10.00% effective
```

## Architecture

### Vault Components

```solidity
contract YieldVault is ERC4626 {
    IStrategy public strategy;        // Yield generation logic
    uint256 public performanceFee;    // Fee on profits (basis points)
    uint256 public lastHarvest;       // Timestamp of last harvest
    address public feeRecipient;      // Where fees go

    function deposit(uint256 assets) external {
        // Transfer assets from user
        // Deploy to strategy
        // Mint shares proportional to current share price
    }

    function withdraw(uint256 assets) external {
        // Burn shares
        // Withdraw from strategy if needed
        // Transfer assets to user
    }

    function harvest() external {
        // Claim yield from strategy
        // Take performance fee
        // Reinvest remainder
    }

    function totalAssets() public view returns (uint256) {
        // Current value of all deposited + accrued yield
        return strategy.balanceOf(address(this));
    }
}
```

### Strategy Interface

```solidity
interface IStrategy {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external returns (uint256);
    function harvest() external returns (uint256 yield);
    function balanceOf(address account) external view returns (uint256);
    function totalAssets() external view returns (uint256);
}
```

## Yield Sources Integration

### 1. Lending Protocols (Aave)

```solidity
contract AaveLendingStrategy {
    function deposit(uint256 amount) external {
        IERC20(asset).approve(address(aavePool), amount);
        aavePool.supply(asset, amount, address(this), 0);
    }

    function harvest() external returns (uint256) {
        // aTokens automatically accrue value
        uint256 currentBalance = aToken.balanceOf(address(this));
        uint256 yield = currentBalance - principalDeposited;
        return yield;
    }
}
```

### 2. Staking

```solidity
contract StakingStrategy {
    function deposit(uint256 amount) external {
        stakingContract.stake(amount);
    }

    function harvest() external returns (uint256) {
        uint256 rewards = stakingContract.claimRewards();
        // Convert rewards to underlying asset if needed
        return rewards;
    }
}
```

### 3. Liquidity Mining

```solidity
contract LPStrategy {
    function deposit(uint256 amount) external {
        // Add liquidity to pool
        // Stake LP tokens in farm
    }

    function harvest() external returns (uint256) {
        // Claim farm rewards
        // Swap rewards for underlying
        // Add to liquidity
    }
}
```

## Performance Fees

Performance fees are taken only on profits:

```solidity
// Common fee structure: 10-20% of profits
uint256 public constant PERFORMANCE_FEE = 1000; // 10%

function harvest() external {
    uint256 yield = strategy.harvest();

    // Calculate fee
    uint256 fee = yield * PERFORMANCE_FEE / 10000;

    // Fee can be:
    // 1. Transferred as tokens to treasury
    // 2. Minted as shares to treasury
    // 3. Left in vault (dilutes other users)

    if (fee > 0) {
        asset.transfer(feeRecipient, fee);
    }

    // Reinvest the rest
    uint256 reinvestAmount = yield - fee;
    strategy.deposit(reinvestAmount);
}
```

## Share Price Growth Example

```
Initial Deposit:
- Alice deposits 1000 USDC
- Gets 1000 shares
- Share price: 1.0 USDC

After 1 Month (5% yield):
- totalAssets: 1050 USDC
- totalShares: 1000
- Share price: 1.05 USDC
- Alice's value: 1050 USDC

Bob Deposits 500 USDC:
- totalAssets: 1550 USDC
- Share price: 1.05 USDC
- Bob gets: 500 / 1.05 = 476.19 shares
- totalShares: 1476.19

After Another Month (5% yield):
- totalAssets: 1550 * 1.05 = 1627.5 USDC
- totalShares: 1476.19
- Share price: 1.1025 USDC
- Alice's value: 1000 * 1.1025 = 1102.5 USDC
- Bob's value: 476.19 * 1.1025 = 525 USDC
```

## Security Considerations

1. **Strategy Risk**: Malicious or buggy strategies can lose funds
2. **Reentrancy**: Guard harvest and withdrawal functions
3. **Share Inflation**: First depositor attack mitigation
4. **Oracle Manipulation**: Don't rely on spot prices for yield
5. **Admin Keys**: Strategy changes should be timelocked
6. **Emergency Withdrawal**: Allow users to exit even if strategy fails

## Gas Optimization

1. **Batch Harvests**: One call benefits all users
2. **Lazy Accounting**: Don't update all user balances on harvest
3. **Strategy Buffers**: Keep small amount in vault for withdrawals
4. **View Functions**: Make totalAssets() a view when possible

## Testing Strategy

1. **Basic Operations**: Deposit, withdraw, share price
2. **Yield Accrual**: Simulate time passing and yield generation
3. **Harvest Mechanics**: Test fee calculation and reinvestment
4. **Edge Cases**: First depositor, empty vault, zero yield
5. **Multi-User**: Multiple deposits/withdrawals with yield
6. **Performance**: Gas costs for operations

## Project Structure

```
43-yield-vault/
├── src/
│   ├── Project43.sol              # Skeleton implementation
│   └── solution/
│       └── Project43Solution.sol  # Complete solution
├── test/
│   └── Project43.t.sol            # Comprehensive tests
├── script/
│   └── DeployProject43.s.sol      # Deployment script
└── README.md                      # This file
```

## Tasks

### Part 1: Basic Vault (Project43.sol)
- [ ] Implement ERC4626 vault structure
- [ ] Add strategy integration
- [ ] Implement deposit/withdraw logic
- [ ] Calculate share price correctly

### Part 2: Yield Strategy (Project43.sol)
- [ ] Create mock yield source
- [ ] Implement strategy deposit/withdraw
- [ ] Simulate yield accrual over time
- [ ] Track totalAssets() changes

### Part 3: Harvest Mechanism (Project43.sol)
- [ ] Implement harvest function
- [ ] Calculate performance fees
- [ ] Reinvest harvested yield
- [ ] Update accounting correctly

### Part 4: Advanced Features (Optional)
- [ ] Multiple strategy support
- [ ] Strategy migration
- [ ] Emergency pause/shutdown
- [ ] Harvest incentives (reward caller)

## Key Formulas Reference

```solidity
// Share Price
sharePrice = totalAssets / totalSupply

// Shares to Mint on Deposit
sharesToMint = depositAmount * totalSupply / totalAssets

// Assets to Return on Withdrawal
assetsToReturn = sharesToBurn * totalAssets / totalSupply

// Performance Fee
feeAmount = yieldEarned * feeBasisPoints / 10000

// APY Calculation (for display)
APY = ((finalValue / initialValue) ^ (365 days / timePeriod)) - 1

// Compound Interest
finalValue = principal * (1 + rate) ^ periods
```

## Running the Project

```bash
# Install dependencies
forge install

# Run tests
forge test --match-path test/Project43.t.sol -vv

# Run specific test with gas report
forge test --match-test test_HarvestAndCompound -vvv --gas-report

# Deploy
forge script script/DeployProject43.s.sol --rpc-url <RPC_URL> --broadcast

# Simulate yield over time
forge test --match-test test_YieldSimulation -vvv
```

## Expected Output

```
Test Harvest and Yield Accrual:
  ✓ Initial deposit: 1000 tokens → 1000 shares
  ✓ Share price: 1.0
  ✓ After 30 days: totalAssets = 1050 (+5%)
  ✓ Harvest: 50 tokens yield, 5 tokens fee
  ✓ Reinvested: 45 tokens
  ✓ New totalAssets: 1095
  ✓ Share price: 1.095
  ✓ User can withdraw 1095 tokens
```

## Resources

- [ERC4626 Specification](https://eips.ethereum.org/EIPS/eip-4626)
- [Yearn V2 Vaults](https://docs.yearn.finance/getting-started/products/yvaults/overview)
- [Compound Interest Calculator](https://www.investor.gov/financial-tools-calculators/calculators/compound-interest-calculator)
- [Aave Protocol](https://docs.aave.com/developers/)
- [Understanding Vault Economics](https://medium.com/iearn/understanding-yearn-vaults-f5e2aa0d7bc5)

## Common Pitfalls

1. **Not Handling First Deposit**: Can lead to share inflation attacks
2. **Incorrect Share Price**: Must use totalAssets, not balance
3. **Rounding Errors**: Always favor the vault in conversions
4. **Harvest Timing**: Don't let anyone harvest too frequently
5. **Strategy Limits**: Check if strategy has deposit caps
6. **Fee Calculation**: Only on profits, not on principal

## Extensions

1. **Multi-Asset Vaults**: Accept multiple tokens
2. **Leveraged Strategies**: Borrow to amplify yields
3. **Insurance Integration**: Protect against strategy losses
4. **NFT Receipt Tokens**: More composable than fungible shares
5. **Time-Locked Deposits**: Higher APY for longer commitments

---

**Difficulty**: Advanced
**Time Estimate**: 4-6 hours
**Prerequisites**: ERC20, ERC4626, DeFi basics, compound interest math
