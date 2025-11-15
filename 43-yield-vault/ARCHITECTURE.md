# Project 43: Yield Vault Architecture

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              USERS                                      │
│                    (Alice, Bob, Charlie, etc.)                          │
└────────────────────────────┬────────────────────────────────────────────┘
                             │
                             │ deposit() / withdraw()
                             │ balanceOf() / convertToAssets()
                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         YIELD VAULT                                     │
│                      (ERC4626 Compliant)                                │
├─────────────────────────────────────────────────────────────────────────┤
│  State:                                                                 │
│  • totalAssets (increases with yield)                                   │
│  • totalSupply (shares outstanding)                                     │
│  • performanceFee (e.g., 10%)                                          │
│  • feeRecipient (treasury address)                                      │
│  • lastHarvest (timestamp)                                              │
│  • harvestCooldown (e.g., 1 hour)                                      │
│                                                                         │
│  Functions:                                                             │
│  • deposit(assets) → shares                                             │
│  • withdraw(assets) → shares                                            │
│  • redeem(shares) → assets                                              │
│  • harvest() → claims and reinvests yield                               │
│  • totalAssets() → vault + strategy assets                              │
│  • convertToShares(assets) → shares                                     │
│  • convertToAssets(shares) → assets                                     │
└────────────────────────────┬────────────────────────────────────────────┘
                             │
                             │ strategy.deposit() / withdraw() / harvest()
                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         STRATEGY LAYER                                  │
│                    (Pluggable Strategies)                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐    │
│  │ Simple Strategy  │  │Compound Strategy │  │  Multi-Strategy  │    │
│  ├──────────────────┤  ├──────────────────┤  ├──────────────────┤    │
│  │ • Deposits all   │  │ • Harvests       │  │ • Allocates      │    │
│  │ • Harvests 100%  │  │ • Keeps 50%      │  │   across multiple│    │
│  │ • Returns all    │  │ • Reinvests 50%  │  │ • Balances risk  │    │
│  │   yield to vault │  │ • Compounds      │  │ • Diversifies    │    │
│  └────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘    │
│           │                     │                      │               │
└───────────┼─────────────────────┼──────────────────────┼───────────────┘
            │                     │                      │
            ▼                     ▼                      ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        YIELD SOURCES                                    │
│                  (External DeFi Protocols)                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌────────────┐│
│  │     Aave     │  │   Compound   │  │   Staking    │  │ Uniswap LP ││
│  │   Lending    │  │   Lending    │  │  Contracts   │  │   Farming  ││
│  ├──────────────┤  ├──────────────┤  ├──────────────┤  ├────────────┤│
│  │ • Supply     │  │ • Mint cToken│  │ • Stake      │  │ • Add LP   ││
│  │ • Earn aToken│  │ • Earn Rate  │  │ • Earn       │  │ • Farm     ││
│  │ • Auto-yield │  │ • Redeem     │  │   rewards    │  │   rewards  ││
│  └──────────────┘  └──────────────┘  └──────────────┘  └────────────┘│
└─────────────────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Yield Vault (Core)

**Responsibilities:**
- Accept user deposits (assets → shares)
- Track share ownership
- Calculate share price (totalAssets / totalSupply)
- Manage strategy allocation
- Coordinate harvests
- Distribute performance fees

**Key Invariants:**
- `sharePrice = totalAssets / totalSupply`
- `sharePrice` never decreases (in normal operation)
- `totalAssets >= sum of all deposits - sum of all withdrawals`

### 2. Strategy Layer

**Interface:**
```solidity
interface IYieldStrategy {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external returns (uint256);
    function harvest() external returns (uint256);
    function totalAssets() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}
```

**Strategy Types:**

#### Simple Strategy
- Deposits 100% to yield source
- Harvests all yield
- Returns all yield to vault

#### Compound Strategy
- Deposits to yield source
- Harvests periodically
- Keeps portion to compound
- Returns portion to vault

#### Multi-Strategy
- Allocates across multiple sources
- Rebalances based on APY
- Harvests from all sources
- Aggregates yields

### 3. Yield Sources

**External Protocols:**
- Lending: Aave, Compound
- Staking: Lido, Rocket Pool
- LPs: Uniswap, Curve
- Yield Aggregators: Yearn

## Data Flow

### Deposit Flow

```
User
  │
  │ 1. approve(vault, amount)
  │
  ▼
Vault
  │
  │ 2. transferFrom(user, vault, assets)
  │ 3. calculate shares = assets * totalSupply / totalAssets
  │ 4. mint(user, shares)
  │
  ▼
Strategy
  │
  │ 5. transferFrom(vault, strategy, assets)
  │ 6. approve(yieldSource, assets)
  │
  ▼
Yield Source
  │
  │ 7. deposit(assets)
  │ 8. start earning yield
  │
  ▼
[Assets now earning yield]
```

### Harvest Flow

```
Anyone (Caller)
  │
  │ 1. vault.harvest()
  │
  ▼
Vault
  │
  │ 2. strategy.harvest()
  │
  ▼
Strategy
  │
  │ 3. calculate yield = currentBalance - principal
  │ 4. yieldSource.withdraw(yield)
  │ 5. transfer(vault, yield)
  │
  ▼
Vault
  │
  │ 6. calculate fee = yield * performanceFee / 10000
  │ 7. transfer(feeRecipient, fee)
  │ 8. approve(strategy, yield - fee)
  │ 9. strategy.deposit(yield - fee)
  │
  ▼
Strategy
  │
  │ 10. yieldSource.deposit(reinvestAmount)
  │
  ▼
[Yield reinvested, totalAssets increased, share price increased]
```

### Withdraw Flow

```
User
  │
  │ 1. vault.redeem(shares, user, user)
  │
  ▼
Vault
  │
  │ 2. calculate assets = shares * totalAssets / totalSupply
  │ 3. if (vaultBalance < assets) → strategy.withdraw(needed)
  │
  ▼
Strategy (if needed)
  │
  │ 4. yieldSource.withdraw(amount)
  │ 5. transfer(vault, withdrawn)
  │
  ▼
Vault
  │
  │ 6. burn(user, shares)
  │ 7. transfer(user, assets)
  │
  ▼
User receives assets (original deposit + yield share)
```

## State Transitions

### Share Price Over Time

```
Time 0: Deploy
├─ totalAssets = 0
├─ totalSupply = 0
└─ sharePrice = undefined (1:1 for first deposit)

Time 1: Alice deposits 1000 tokens
├─ totalAssets = 1000
├─ totalSupply = 1000
└─ sharePrice = 1.0

Time 2: 30 days pass, yield accrues
├─ totalAssets = 1010 (1% yield)
├─ totalSupply = 1000
└─ sharePrice = 1.01

Time 3: Bob deposits 1000 tokens
├─ totalAssets = 2010
├─ totalSupply = 1990.1 (Bob gets 990.1 shares)
└─ sharePrice = 1.01

Time 4: Harvest called
├─ Yield = 10 tokens
├─ Fee = 1 token (10%)
├─ Reinvest = 9 tokens
├─ totalAssets = 2019 (10 + 9, minus 1 fee)
├─ totalSupply = 1990.1
└─ sharePrice = 1.0145

Time 5: 30 more days
├─ totalAssets = 2039.4 (~1% yield on 2019)
├─ totalSupply = 1990.1
└─ sharePrice = 1.0248

And so on...
```

## Performance Calculations

### APY Calculation

```
Start State:
├─ totalAssets = 1000
├─ timestamp = T0

End State (30 days later):
├─ totalAssets = 1010
├─ timestamp = T0 + 30 days

Simple APY:
└─ (1010 - 1000) / 1000 * (365 / 30) = 12.17%

Compound APY:
└─ (1010 / 1000) ^ (365 / 30) - 1 = 12.94%
```

### Yield Distribution

```
Total Yield: 100 tokens
├─ Performance Fee (10%): 10 tokens → treasury
├─ Reinvested (90%): 90 tokens → back to strategy
└─ Benefit to Users: Share price ↑ by reinvested amount

Alice (1000 shares, 50% of total):
├─ Share of yield: 50% of 90 = 45 tokens
└─ New value: 1045 tokens

Bob (1000 shares, 50% of total):
├─ Share of yield: 50% of 90 = 45 tokens
└─ New value: 1045 tokens
```

## Security Model

### Access Control

```
Public Functions (Anyone):
├─ deposit()
├─ withdraw()
├─ redeem()
├─ harvest() [after cooldown]
└─ View functions

Owner Functions:
├─ setStrategy()
├─ setPerformanceFee()
├─ setFeeRecipient()
└─ setHarvestCooldown()

Vault-Only Functions (in Strategy):
├─ deposit()
├─ withdraw()
└─ harvest()
```

### Attack Vectors & Mitigations

| Attack | Mitigation |
|--------|------------|
| Reentrancy | ReentrancyGuard on sensitive functions |
| First depositor inflation | Virtual shares or minimum deposit |
| Harvest spam | Cooldown period between harvests |
| Strategy rugpull | Timelock on strategy changes |
| Fee manipulation | Cap fees at 20% |
| Flash loan manipulation | Time-weighted accounting |

## Upgrade Path

```
┌─────────────┐
│  Vault V1   │
└──────┬──────┘
       │
       │ setStrategy()
       ▼
┌─────────────┐     ┌─────────────┐
│ Strategy A  │────→│ Strategy B  │
└─────────────┘     └─────────────┘
   (Aave)              (Compound)

Process:
1. Pause new deposits
2. Call strategy.harvest()
3. Call oldStrategy.withdraw(all)
4. Call vault.setStrategy(newStrategy)
5. NewStrategy.deposit(all)
6. Resume deposits
```

## Gas Costs (Approximate)

| Operation | Gas Cost |
|-----------|----------|
| First deposit | ~150k |
| Subsequent deposit | ~120k |
| Withdraw | ~100k |
| Harvest | ~180k |
| Strategy change | ~200k |

## Monitoring & Analytics

### Key Metrics

```
Vault Health:
├─ Total Assets Under Management (AUM)
├─ Total Shares Outstanding
├─ Current Share Price
├─ Share Price Growth (%)
└─ Total Unique Depositors

Yield Performance:
├─ Total Yield Harvested
├─ Total Fees Collected
├─ Current APY
├─ Historical APY (7d, 30d, 90d)
└─ Harvest Frequency

Strategy Health:
├─ Strategy Utilization (%)
├─ Yield Source APY
├─ Last Harvest Timestamp
└─ Unharvested Yield
```

### Events to Monitor

```solidity
event Deposited(address user, uint256 assets, uint256 shares);
event Withdrawn(address user, uint256 assets, uint256 shares);
event Harvested(uint256 yield, uint256 fee, uint256 timestamp);
event StrategyUpdated(address oldStrategy, address newStrategy);
event PerformanceFeeUpdated(uint256 oldFee, uint256 newFee);
```

## Testing Strategy

### Unit Tests
- Individual function testing
- Edge case coverage
- Access control verification

### Integration Tests
- Multi-step workflows
- Strategy interaction
- Harvest cycles

### Scenario Tests
- Realistic user journeys
- Time-based simulations
- Multi-user interactions

### Fuzz Tests
- Random input testing
- Invariant checking
- Property-based testing

## Deployment Checklist

- [ ] Audit smart contracts
- [ ] Test on testnet
- [ ] Verify all parameters
- [ ] Set initial strategy
- [ ] Configure fees
- [ ] Set up monitoring
- [ ] Prepare emergency procedures
- [ ] Document admin procedures
- [ ] Create user guides
- [ ] Set up multisig for owner

---

This architecture supports:
- **Scalability**: Easy to add new strategies
- **Security**: Multiple layers of protection
- **Efficiency**: Gas-optimized operations
- **Flexibility**: Configurable parameters
- **Transparency**: Full on-chain accounting
