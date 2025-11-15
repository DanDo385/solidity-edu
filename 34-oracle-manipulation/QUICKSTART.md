# Project 34: Oracle Manipulation Attack - Quick Start Guide

## Overview
This project demonstrates oracle manipulation attacks in DeFi, focusing on flashloan-based price manipulation attacks against lending protocols.

## Project Structure

```
34-oracle-manipulation/
├── README.md                           # Comprehensive guide (416 lines)
├── QUICKSTART.md                       # This file
├── src/
│   ├── Project34.sol                   # Skeleton with TODOs (431 lines)
│   └── solution/
│       └── Project34Solution.sol       # Complete solution (573 lines)
├── test/
│   └── Project34.t.sol                 # Comprehensive tests (516 lines)
└── script/
    └── DeployProject34.s.sol           # Deployment scripts (299 lines)
```

## Quick Start

### 1. Run Tests
```bash
# Run all tests
forge test

# Run with verbose output
forge test -vvv

# Run specific test
forge test --match-test test_OracleManipulationAttack -vvvv
```

### 2. Key Test Cases

- `test_OracleManipulationAttack` - Main attack demonstration
- `test_DetailedAttackFlow` - Step-by-step attack breakdown
- `test_TWAPProtection` - TWAP oracle defense
- `test_SecureLendingBlockProtection` - Multi-block protection
- `test_MultiOracleProtection` - Multiple oracle sources
- `test_AttackProfitability` - Profit analysis

### 3. Deploy Locally
```bash
# Start local node
anvil

# Deploy all contracts
forge script script/DeployProject34.s.sol --fork-url http://localhost:8545 --broadcast

# Run attack demonstration
forge script script/DeployProject34.s.sol --sig "runDemo()" --fork-url http://localhost:8545 --broadcast
```

### 4. Deploy to Testnet
```bash
# Set environment variables
export PRIVATE_KEY=<your-private-key>
export RPC_URL=<testnet-rpc-url>

# Deploy
forge script script/DeployProject34.s.sol --rpc-url $RPC_URL --broadcast --verify
```

## Learning Path

### Step 1: Understand the Vulnerability (30 min)
1. Read `README.md` sections:
   - Oracle manipulation mechanics
   - AMM price manipulation with flashloans
   - Real-world exploits
2. Study `src/Project34.sol`:
   - SimpleAMM with spot price oracle
   - VulnerableLending protocol
   - Attack flow comments

### Step 2: Complete the Attack (1 hour)
1. Open `src/Project34.sol`
2. Complete the `Attacker` contract:
   - Implement `attack()` function
   - Complete `onFlashloan()` callback
3. Test your implementation:
   ```bash
   forge test --match-test test_OracleManipulation
   ```

### Step 3: Study the Solution (30 min)
1. Compare with `src/solution/Project34Solution.sol`
2. Understand each attack step:
   - Flashloan acquisition
   - Price manipulation
   - Over-collateralized borrowing
   - Price restoration
   - Profit calculation

### Step 4: Explore Defenses (1 hour)
1. Study secure implementations:
   - `TWAPOracle` - Time-weighted average price
   - `SecureLending` - Multi-block protection
   - `MultiOracleProtection` - Oracle diversity
2. Run protection tests:
   ```bash
   forge test --match-test test_TWAP
   forge test --match-test test_SecureLending
   forge test --match-test test_MultiOracle
   ```

### Step 5: Run Attack Analysis (30 min)
```bash
# Detailed attack demonstration
forge test --match-test test_DetailedAttackFlow -vvvv

# Profitability analysis
forge test --match-test test_AttackProfitability -vv

# Fuzz testing
forge test --match-test testFuzz_OracleManipulation
```

## Key Contracts

### Vulnerable System
- **SimpleAMM**: Basic AMM with manipulable spot price
- **VulnerableLending**: Lending protocol using AMM as oracle
- **FlashloanProvider**: Provides flashloans for attack
- **Attacker**: Exploits oracle manipulation

### Secure System
- **TWAPOracle**: Time-weighted average price oracle
- **SecureLending**: Lending with TWAP and block delays
- **MultiOracleProtection**: Uses multiple oracle sources

## Attack Flow

```
1. Flashloan 100k USDC
   ↓
2. Swap 100k USDC → WBTC (price ↑)
   ↓
3. Deposit 0.5 WBTC as collateral (overvalued)
   ↓
4. Borrow max USDC (using inflated price)
   ↓
5. Swap WBTC → USDC (restore price)
   ↓
6. Repay flashloan
   ↓
7. Profit = Borrowed - Flashloan
```

## Expected Test Results

When you run the tests, you should see:

```
✓ test_AMMBasics - AMM functions correctly
✓ test_SwapAffectsPrice - Swaps change price
✓ test_NormalLending - Normal borrow/lend works
✓ test_OracleManipulationAttack - Attack is profitable
✓ test_DetailedAttackFlow - Step-by-step verification
✓ test_TWAPProtection - TWAP prevents manipulation
✓ test_SecureLendingBlockProtection - Block delay works
✓ test_MultiOracleProtection - Detects deviation
```

## Common Issues

### Attack Not Profitable
- Check flashloan amount (needs to be large enough)
- Verify sufficient liquidity in AMM
- Ensure collateral amount is appropriate

### Tests Failing
- Make sure all TODOs are completed
- Verify approvals are set correctly
- Check arithmetic doesn't overflow

### Price Not Manipulating
- Swap amount must be significant relative to liquidity
- Check AMM reserves are non-zero
- Verify constant product formula

## Key Learning Objectives

✅ Understand spot price vs TWAP
✅ Implement flashloan-based attack
✅ Calculate attack profitability
✅ Build TWAP protection
✅ Implement multi-oracle systems
✅ Recognize vulnerable patterns
✅ Apply defense strategies

## Real-World Context

This attack pattern has been used in:
- **Harvest Finance** - $34M (Oct 2020)
- **Cream Finance** - $130M (Oct 2021)
- **Mango Markets** - $110M (Oct 2022)
- **Indexed Finance** - $16M (Oct 2021)
- **Warp Finance** - $8M (Dec 2020)

## Next Steps

1. ✅ Complete the skeleton implementation
2. ✅ Run all tests successfully
3. ✅ Study the solution
4. ✅ Experiment with parameters
5. ✅ Build additional defenses
6. ✅ Move to next project

## Resources

- [Uniswap V2 TWAP](https://docs.uniswap.org/contracts/v2/guides/smart-contract-integration/building-an-oracle)
- [Chainlink Price Feeds](https://docs.chain.link/data-feeds/price-feeds)
- [Rekt News](https://rekt.news/) - DeFi exploit analysis
- [Project README](README.md) - Comprehensive guide

---

**⚠️ Educational Purpose Only**

These techniques are for learning security concepts only. Never use them against real protocols without authorization.
