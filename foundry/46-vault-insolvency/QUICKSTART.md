# Project 46: Vault Insolvency Scenarios - Quick Start Guide

## Overview

This project teaches you how to handle vault insolvency, bad debt, and emergency scenarios in DeFi protocols. You'll learn to implement crisis management systems that protect users during catastrophic events.

## What You'll Learn

1. **Vault Insolvency Detection**: Identifying when a vault cannot cover all user claims
2. **Loss Socialization**: Fair distribution of losses among all users
3. **Emergency Modes**: Multi-level response to different crisis severities
4. **Circuit Breakers**: Automatic safety mechanisms
5. **Recovery Mechanisms**: Attempting to restore normal operations
6. **Proportional Withdrawals**: Fair asset distribution during insolvency

## File Structure

```
46-vault-insolvency/
├── README.md                           # Comprehensive guide
├── QUICKSTART.md                       # This file
├── src/
│   ├── Project46.sol                   # Skeleton with TODOs
│   └── solution/
│       └── Project46Solution.sol       # Complete solution
├── test/
│   └── Project46.t.sol                 # Comprehensive tests
└── script/
    └── DeployProject46.s.sol           # Deployment scripts
```

## Getting Started

### 1. Study the Concepts

Read through `README.md` to understand:
- What vault insolvency is
- How bad debt occurs
- Different emergency modes
- Loss socialization strategies
- Circuit breaker mechanisms

### 2. Examine the Skeleton

Open `src/Project46.sol` and review:
- The `RiskyStrategy` contract (simulates a strategy that can lose funds)
- The vault structure with TODOs
- State variables and events
- Function signatures

### 3. Try to Implement

Work through the TODOs in order:

#### Core Functionality
1. Define the `Mode` enum (NORMAL, PAUSED, EMERGENCY, FROZEN)
2. Implement share calculations in `deposit()`
3. Implement `totalAssets()` calculation
4. Implement `convertToShares()` and `convertToAssets()`
5. Add mode-based withdrawal logic

#### Crisis Management
6. Implement `checkSolvency()`
7. Create `triggerEmergency()` function
8. Implement proportional emergency withdrawals
9. Add `calculateLoss()` function
10. Implement recovery mechanisms

#### Safety Features
11. Add circuit breakers for automatic triggers
12. Implement proper mode transitions
13. Add comprehensive events

### 4. Run Tests

```bash
# Install dependencies (if not already done)
forge install

# Run all tests
forge test --match-contract Project46Test -vvv

# Run specific test
forge test --match-test test_EmergencyWithdrawal_ProportionalDistribution -vvvv

# Run with gas reporting
forge test --match-contract Project46Test --gas-report
```

### 5. Compare with Solution

After attempting the implementation, compare your code with `src/solution/Project46Solution.sol`.

Key features in the solution:
- **4 operating modes**: Gradual degradation from NORMAL → PAUSED → EMERGENCY → FROZEN
- **Automatic circuit breakers**: Loss detection triggers mode changes
- **Fair loss socialization**: Pro-rata distribution using `shares * totalAssets / totalShares`
- **Recovery mechanisms**: Pull funds from strategy, restore operations
- **Comprehensive tracking**: Individual user loss info, vault status

## Key Concepts Explained

### Operating Modes

```solidity
enum Mode {
    NORMAL,     // All operations allowed
    PAUSED,     // No deposits, withdrawals ok
    EMERGENCY,  // Only proportional withdrawals
    FROZEN      // No operations (catastrophic)
}
```

**Mode Transitions:**
```
NORMAL → PAUSED → EMERGENCY → FROZEN
         ↓                     ↓
         NORMAL ← PAUSED ← EMERGENCY
```

### Loss Socialization Formula

In emergency mode, users receive proportional share of remaining assets:

```solidity
userAssets = (userShares * totalAssets) / totalShares
```

**Example:**
- Alice has 2000 shares (66.67%)
- Bob has 1000 shares (33.33%)
- Total: 3000 shares
- Vault suffers 30% loss (900 tokens lost)
- Remaining: 2100 tokens

**Distribution:**
- Alice: (2000 * 2100) / 3000 = 1400 tokens (lost 600)
- Bob: (1000 * 2100) / 3000 = 700 tokens (lost 300)

Both lost 30% - fair distribution!

### Circuit Breakers

Automatic triggers based on thresholds:

```solidity
MAX_LOSS_PERCENTAGE = 1000;      // 10% → Emergency mode
CATASTROPHIC_LOSS = 5000;        // 50% → Freeze
MIN_SOLVENCY_RATIO = 9500;       // 95% → Must maintain
```

## Common Scenarios to Test

### Scenario 1: Normal Operations
```bash
forge test --match-test test_Deposit -vvv
forge test --match-test test_Withdraw -vvv
```

### Scenario 2: 10% Loss
```bash
forge test --match-test test_SmallLoss_10Percent -vvv
```

### Scenario 3: Emergency Withdrawal
```bash
forge test --match-test test_EmergencyWithdrawal_ProportionalDistribution -vvvv
```

### Scenario 4: Catastrophic Loss
```bash
forge test --match-test test_CatastrophicLoss_50Percent -vvvv
```

### Scenario 5: Bank Run
```bash
forge test --match-test test_BankRun_Scenario -vvvv
```

## Deployment

### Local Testing

```bash
# Start local node
anvil

# Deploy with scenario
forge script script/DeployProject46.s.sol:DeployWithScenario \
  --rpc-url http://localhost:8545 \
  --broadcast \
  --private-key <anvil-private-key>
```

### Testnet Deployment

```bash
# Set environment variables
export PRIVATE_KEY=your_private_key
export RPC_URL=your_rpc_url

# Deploy
forge script script/DeployProject46.s.sol:DeployProject46 \
  --rpc-url $RPC_URL \
  --broadcast \
  --verify
```

## Interacting with the Vault

### Using Cast

```bash
# Check vault status
cast call <vault-address> "getVaultStatus()" --rpc-url <rpc>

# Deposit
cast send <vault-address> "deposit(uint256)" 1000000000000000000000 \
  --private-key <key> \
  --rpc-url <rpc>

# Simulate loss (testing only)
cast send <strategy-address> "simulateLoss(uint256)" 100000000000000000000 \
  --private-key <key> \
  --rpc-url <rpc>

# Trigger emergency
cast send <vault-address> "triggerEmergency()" \
  --private-key <key> \
  --rpc-url <rpc>

# Check your balance
cast call <vault-address> "balanceOf(address)" <your-address> --rpc-url <rpc>

# Withdraw
cast send <vault-address> "withdraw(uint256)" <shares> \
  --private-key <key> \
  --rpc-url <rpc>
```

## Learning Challenges

### Challenge 1: Basic Implementation
Complete all TODOs in `Project46.sol` to pass basic tests.

### Challenge 2: Enhanced Circuit Breakers
Add a time-based circuit breaker that triggers if losses exceed X% over Y time period.

### Challenge 3: Recovery Proposals
Implement a governance system where recovery actions require multi-sig approval.

### Challenge 4: Withdrawal Queue
During emergency, implement a queue system for fair withdrawal ordering.

### Challenge 5: Partial Recovery
Allow vault to accept recovered funds and distribute proportionally to users who haven't withdrawn yet.

## Security Checklist

Before considering your implementation complete:

- [ ] ReentrancyGuard on all state-changing functions
- [ ] Access control on emergency functions (onlyOwner)
- [ ] Mode-based operation restrictions
- [ ] Circuit breakers trigger automatically
- [ ] Loss calculations are accurate
- [ ] Pro-rata distribution is fair (no first-mover advantage)
- [ ] Proper rounding (favor the vault to prevent draining)
- [ ] All state changes emit events
- [ ] Edge cases handled (zero shares, total loss, etc.)
- [ ] No integer overflow/underflow
- [ ] Gas-efficient operations

## Common Pitfalls to Avoid

1. **Not checking solvency**: Always verify vault health before operations
2. **First-mover advantage**: Early withdrawers shouldn't drain the vault
3. **Improper rounding**: Can lead to vault drainage
4. **No emergency shutdown**: Must have circuit breakers
5. **Unfair loss distribution**: Must be pro-rata
6. **Missing events**: Users need to track state changes
7. **Centralization**: Owner shouldn't have absolute power

## Real-World Examples

Study these protocols for production examples:

1. **Yearn Finance**: Multi-strategy vaults with emergency shutdown
2. **Rari Capital**: Lessons from handling protocol exploits
3. **Cream Finance**: Circuit breakers and crisis management
4. **MakerDAO**: Bad debt handling and emergency shutdown module

## Additional Resources

- [ERC-4626 Standard](https://eips.ethereum.org/EIPS/eip-4626)
- [Yearn Emergency Shutdown](https://docs.yearn.finance/resources/faq#emergency-shutdown)
- [DeFi Post-Mortems](https://github.com/openblockhq/defi-attacks)
- [Smart Contract Security Best Practices](https://consensys.github.io/smart-contract-best-practices/)

## Getting Help

If you're stuck:

1. Review the README.md for concept explanations
2. Check the test file for expected behavior
3. Compare with the solution (but try first!)
4. Study the inline comments in the solution
5. Review the deployment script for usage examples

## Next Steps

After mastering this project:

- **Project 47**: Vault Oracle Integration - Price feeds and manipulation resistance
- **Project 48**: Meta Vault - Vault of vaults strategies
- **Project 49**: Leverage Vault - Leveraged yield strategies
- **Project 50**: DeFi Capstone - Combine all concepts

---

**Remember**: This project simulates worst-case scenarios. Real production vaults need extensive audits, multi-sig governance, timelocks, and comprehensive monitoring systems. This is educational code for learning crisis management principles!

Good luck! 🚀
