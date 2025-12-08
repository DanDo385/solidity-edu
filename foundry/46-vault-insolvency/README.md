# Project 46: Vault Insolvency Scenarios

A comprehensive guide to handling vault insolvency, bad debt, and emergency scenarios in DeFi protocols.

## Overview

This project teaches how to build resilient vault systems that can handle catastrophic scenarios including strategy losses, bad debt, and emergency situations. Learn to implement proper crisis management and loss socialization mechanisms.

## Concepts

### What is Vault Insolvency? When Assets < Liabilities

**FIRST PRINCIPLES: Solvency and Accounting**

Vault insolvency occurs when the total assets held by a vault are less than the total claims (shares) against it. This means users cannot fully redeem their shares for the underlying assets they deposited.

**CONNECTION TO PROJECT 11, 20, & 42**:
- **Project 11**: ERC-4626 vault standard
- **Project 20**: Share-based accounting
- **Project 42**: Rounding precision (affects solvency!)
- **Project 46**: What happens when vault becomes insolvent!

**UNDERSTANDING SOLVENCY**:

```
Solvency Check:
┌─────────────────────────────────────────┐
│ Vault State:                            │
│   totalAssets = 1,000 tokens            │ ← What vault has
│   totalShares = 1,000 shares            │ ← What users own
│   ↓                                      │
│ Expected Value:                         │
│   expectedValue = totalShares × pricePerShare│
│   expectedValue = 1,000 × 1.0 = 1,000  │ ← What users expect
│   ↓                                      │
│ Solvency Check:                         │
│   totalAssets >= expectedValue?          │
│   1,000 >= 1,000? ✅ SOLVENT            │ ← Can honor withdrawals
│                                          │
│ After Loss:                             │
│   totalAssets = 800 tokens (loss!)      │ ← Strategy lost funds
│   totalShares = 1,000 shares            │ ← Unchanged
│   ↓                                      │
│ Solvency Check:                         │
│   800 >= 1,000? ❌ INSOLVENT           │ ← Cannot honor withdrawals!
└─────────────────────────────────────────┘
```

**CAUSES OF INSOLVENCY**:

1. **Strategy Losses**: Underlying strategy loses funds
   - Exploit in yield protocol (from Project 34: oracle manipulation)
   - Liquidation with slippage
   - Impermanent loss beyond tolerable levels
   - Smart contract bugs (from Project 07: reentrancy, etc.)

2. **Oracle Manipulation or Failure** (from Project 18 & 34):
   - Flash loan price manipulation
   - Oracle outage or stale data
   - Cross-chain bridge failures

3. **Smart Contract Exploits**: In underlying protocols
   - Reentrancy attacks (from Project 07)
   - Access control bugs (from Project 36)
   - Precision errors (from Project 42)

4. **Cascading Liquidations**:
   - One liquidation triggers others
   - Slippage accumulates
   - Vault loses more than expected

5. **Flash Loan Attacks** (from Project 33):
   - Price manipulation
   - Governance attacks
   - Oracle manipulation

6. **Protocol-Level Failures**:
   - Entire protocol exploited
   - Bridge hacks
   - Centralized failure points

**REAL-WORLD ANALOGY**: 
Like a bank run:
- **Solvent**: Bank has enough cash to honor all withdrawals
- **Insolvent**: Bank doesn't have enough cash (assets < liabilities)
- **Vault**: Shares represent claims, assets must cover claims
- **Problem**: When assets < shares × price, vault is insolvent!

### Bad Debt Scenarios

**Types of Bad Debt:**

1. **Strategy Loss**: Underlying strategy loses funds
   - Exploit in yield protocol
   - Liquidation with slippage
   - Impermanent loss beyond tolerable levels
   - Smart contract bugs

2. **Oracle Failures**: Mispricing leads to incorrect valuations
   - Flash loan price manipulation
   - Oracle outage or stale data
   - Cross-chain bridge failures

3. **Withdrawal Runs**: Bank-run scenarios
   - First withdrawers get full value
   - Later withdrawers face losses
   - Liquidity crunch

### Strategy Loss Handling

**Detection:**
```solidity
// Check if total assets < expected value
uint256 totalAssets = strategy.totalAssets();
uint256 expectedValue = totalShares * pricePerShare;
bool isInsolvent = totalAssets < expectedValue;
```

**Response Mechanisms:**
1. **Immediate Shutdown**: Stop all deposits
2. **Loss Calculation**: Determine actual vs expected
3. **Loss Distribution**: Share loss among users
4. **Recovery Attempts**: Try to recover funds

### Emergency Withdrawal Modes

**Standard Mode**: Full redemptions available
```solidity
withdraw(shares) → assets = shares * pricePerShare
```

**Emergency Mode**: Proportional withdrawals only
```solidity
withdraw(shares) → assets = shares * (totalAssets / totalShares)
```

**Modes:**

1. **Normal**: Full operations
2. **Paused**: Deposits paused, withdrawals work
3. **Emergency**: Only proportional withdrawals
4. **Frozen**: All operations stopped (worst case)

### Partial Withdrawal Logic

When a vault can't honor full withdrawals, implement proportional logic:

```solidity
// Instead of: shares * expectedPrice
// Use: shares * (actualAssets / totalShares)

uint256 userShare = userShares * totalAssets / totalSupply;
```

**Considerations:**
- Gas costs for small withdrawals
- Dust amounts
- Rounding errors favoring the vault
- Minimum withdrawal amounts

### Socialized Losses

When losses occur, distribute them fairly among all users:

**Approaches:**

1. **Pro-Rata Distribution**
   - Everyone loses same percentage
   - Most common and fair
   - Easy to calculate

2. **FIFO Protection**
   - First depositors protected
   - Later depositors take losses
   - Can cause runs

3. **Time-Weighted**
   - Longer holders get better treatment
   - Rewards loyalty
   - More complex

**Implementation:**
```solidity
// Pro-rata: Reduce price per share
pricePerShare = totalAssets / totalShares;

// Everyone's effective balance reduced proportionally
userAssets = userShares * pricePerShare;
```

### Circuit Breakers

Automatic safety mechanisms that trigger during anomalies:

**Triggers:**
1. **Large Loss**: Single tx loss > threshold
2. **Rapid Drawdown**: Loss rate too fast
3. **Withdrawal Surge**: Too many withdrawals
4. **Price Deviation**: Asset price moves too much

**Actions:**
1. **Pause Deposits**: Stop new money
2. **Pause Withdrawals**: Stop bank run
3. **Notify Admin**: Alert for manual intervention
4. **Auto-Recovery**: Try to harvest/recover

**Example:**
```solidity
if (lossPercentage > MAX_LOSS_THRESHOLD) {
    emergencyMode = true;
    pauseDeposits();
    notifyAdmin();
}
```

## Key Features to Implement

### 1. Loss Detection System
- Monitor strategy health
- Compare expected vs actual assets
- Track price per share deviations

### 2. Emergency Shutdown
- Multi-signature control
- Timelocks for safety
- Graceful degradation

### 3. Proportional Withdrawals
- Fair distribution of remaining assets
- Prevent first-mover advantage
- Handle rounding carefully

### 4. Recovery Mechanisms
- Attempt to recover funds
- Coordinate with affected protocols
- Potential liquidation of strategy positions

### 5. Loss Socialization
- Calculate per-share loss
- Update share price
- Track individual losses for reporting

## Implementation Steps

### Step 1: Basic Vault Structure
```solidity
contract InsolvencyVault {
    IERC20 public asset;
    uint256 public totalShares;
    mapping(address => uint256) public shares;

    enum Mode { NORMAL, PAUSED, EMERGENCY, FROZEN }
    Mode public currentMode;
}
```

### Step 2: Deposit/Withdraw Logic
```solidity
function deposit(uint256 assets) external returns (uint256 shares) {
    require(currentMode == Mode.NORMAL, "Deposits paused");
    shares = convertToShares(assets);
    // ... mint shares
}

function withdraw(uint256 shares) external returns (uint256 assets) {
    require(currentMode != Mode.FROZEN, "Frozen");

    if (currentMode == Mode.EMERGENCY) {
        assets = proportionalWithdraw(shares);
    } else {
        assets = normalWithdraw(shares);
    }
}
```

### Step 3: Loss Detection
```solidity
function checkSolvency() public returns (bool) {
    uint256 totalAssets = getTotalAssets();
    uint256 expectedValue = totalShares * lastKnownPrice;

    if (totalAssets < expectedValue * 90 / 100) {
        triggerEmergency();
        return false;
    }
    return true;
}
```

### Step 4: Emergency Mode
```solidity
function triggerEmergency() internal {
    currentMode = Mode.EMERGENCY;
    emit EmergencyTriggered(block.timestamp, getTotalAssets());
}

function proportionalWithdraw(uint256 shares) internal returns (uint256) {
    uint256 totalAssets = getTotalAssets();
    return shares * totalAssets / totalShares;
}
```

### Step 5: Recovery
```solidity
function attemptRecovery() external onlyAdmin {
    // Try to withdraw from strategy
    // Liquidate positions
    // Update accounting

    if (isSolvent()) {
        currentMode = Mode.NORMAL;
    }
}
```

## Security Considerations

### 1. Reentrancy
- Use ReentrancyGuard on all withdraw functions
- Update state before external calls
- Consider cross-contract reentrancy

### 2. Oracle Dependence
- Use multiple oracle sources
- Implement circuit breakers for price deviations
- Have fallback pricing mechanisms

### 3. Access Control
- Multi-sig for emergency functions
- Timelocks for critical operations
- Role-based access (owner, guardian, keeper)

### 4. Withdrawal Runs
- Consider withdrawal limits
- Queue-based withdrawals during stress
- Cooldown periods

### 5. Rounding Errors
- Always round in favor of the vault
- Track dust carefully
- Minimum deposit/withdrawal amounts

## Testing Scenarios

### 1. Normal Operations
- Deposits and withdrawals work correctly
- Share price calculations accurate
- No losses

### 2. Strategy Loss (10% loss)
- Detect loss
- Emergency mode triggers
- Proportional withdrawals work
- Loss socialized correctly

### 3. Catastrophic Loss (50%+ loss)
- Immediate freeze
- All users get proportional amount
- No user gets unfair advantage

### 4. Recovery
- Admin can recover funds
- Mode can be downgraded
- Normal operations resume

### 5. Edge Cases
- First depositor scenario
- Last withdrawer scenario
- Multiple sequential losses
- Dust handling

## Common Pitfalls

1. **Not checking for insolvency**: Always verify vault health
2. **First-mover advantage**: Early withdrawers shouldn't be able to drain vault
3. **Integer overflow**: Large numbers in loss calculations
4. **No emergency shutdown**: Must have kill switch
5. **Centralization risks**: Admin has too much power
6. **No loss reporting**: Users should know their losses
7. **Improper rounding**: Can lead to exploitation

## Best Practices

1. **Multi-layered Security**
   - Circuit breakers
   - Gradual mode degradation
   - Multiple admin roles

2. **Transparent Loss Handling**
   - Events for all state changes
   - Clear loss attribution
   - User-facing loss queries

3. **Conservative Accounting**
   - Round in vault's favor
   - Maintain reserves
   - Limit strategy exposure

4. **Emergency Preparedness**
   - Documented procedures
   - Tested recovery mechanisms
   - Communication channels

5. **Fair Loss Distribution**
   - Pro-rata basis
   - No favoritism
   - Deterministic calculations

## Real-World Examples

### Yearn Finance
- Multi-strategy vaults
- Emergency shutdown mechanism
- Governance-controlled recovery

### Rari Capital (Post-Exploit)
- Suffered exploit losses
- Had to socialize losses
- Implemented better controls

### Cream Finance
- Multiple exploits
- Insolvency issues
- Lessons in risk management

## Learning Objectives

After completing this project, you will understand:

1. How vault insolvency occurs
2. Mechanisms to detect and handle bad debt
3. Emergency shutdown procedures
4. Fair loss distribution mechanisms
5. Recovery and crisis management
6. Circuit breaker implementation
7. Building resilient DeFi protocols

## Exercises

### Beginner
1. Implement basic vault with deposit/withdraw
2. Add simple insolvency check
3. Implement emergency pause

### Intermediate
4. Add proportional withdrawal logic
5. Implement circuit breakers
6. Create multi-mode state machine

### Advanced
7. Handle multiple concurrent losses
8. Implement time-weighted loss distribution
9. Create comprehensive recovery mechanisms
10. Add cross-strategy risk management

## Additional Resources

- [EIP-4626: Tokenized Vault Standard](https://eips.ethereum.org/EIPS/eip-4626)
- [Yearn Vault Documentation](https://docs.yearn.finance/)
- [DeFi Risk Assessment](https://github.com/defi-defense-dao)
- [Trail of Bits: Building Secure Contracts](https://github.com/crytic/building-secure-contracts)

## File Structure

```
46-vault-insolvency/
├── README.md (this file)
├── src/
│   ├── Project46.sol (skeleton code with TODOs)
│   └── solution/
│       └── Project46Solution.sol (complete solution)
├── test/
│   └── Project46.t.sol (comprehensive tests)
└── script/
    └── DeployProject46.s.sol (deployment script)
```

## Getting Started

1. Review the concepts above
2. Examine the skeleton code in `src/Project46.sol`
3. Try to implement the TODOs yourself
4. Run tests: `forge test --match-contract Project46Test -vvv`
5. Compare with solution in `src/solution/VaultInsolvencySolution.sol`

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/VaultInsolvencySolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployVaultInsolvencySolution.s.sol` - Deployment script patterns
- `test/solution/VaultInsolvencySolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains insolvency handling, proportional withdrawals, loss distribution
- **Connections to Project 11**: ERC-4626 vaults (insolvency is a critical edge case)
- **Connections to Project 20**: Share-based accounting (how losses affect shares)
- **Real-World Context**: Strategy losses can cause insolvency - must handle gracefully

6. Deploy locally: `forge script script/DeployProject46.s.sol`

Good luck, and remember: handling insolvency is about protecting users during the worst-case scenarios!
