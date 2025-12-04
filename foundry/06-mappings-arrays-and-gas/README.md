# Project 06: Mappings, Arrays & Gas ⛽

> **Master gas-efficient data structures and understand the trade-offs**

## 🎯 Learning Objectives

By completing this project, you will:

1. **Understand mapping storage** and O(1) lookup efficiency
2. **Recognize array iteration costs** and DoS risks
3. **Implement gas-optimized patterns** for balance tracking
4. **Compare iteration vs tracking** approaches
5. **Analyze gas costs** of different data structures
6. **Master caching patterns** to reduce storage reads
7. **Understand unbounded loop risks** and mitigation strategies
8. **Create Foundry deployment scripts** from scratch
9. **Write comprehensive test suites** with gas reporting

## 📁 Project Directory Structure

```
06-mappings-arrays-and-gas/
├── README.md                          # This file
├── foundry.toml                       # Foundry configuration
├── src/
│   ├── MappingsArraysGas.sol        # Skeleton contract (TODO: implement)
│   └── solution/
│       └── MappingsArraysGasSolution.sol  # Complete reference implementation
├── script/
│   ├── DeployMappingsArraysGas.s.sol # Deployment script (TODO: implement)
│   └── solution/
│       └── DeployMappingsArraysGasSolution.s.sol  # Reference deployment
└── test/
    ├── MappingsArraysGas.t.sol        # Test suite (TODO: implement)
    └── solution/
        └── MappingsArraysGasSolution.t.sol  # Reference tests
```

## 🔑 Key Concepts

### Mapping Storage: O(1) Lookups

Mappings provide constant-time lookups using keccak256 hashing:

```solidity
mapping(address => uint256) public balances;
// Storage slot: keccak256(abi.encodePacked(key, slot_number))
```

**Gas Costs:**
- Cold read: ~2,100 gas (first access)
- Warm read: ~100 gas (recently accessed)
- Write: ~5,000 gas (warm) or ~20,000 gas (cold)

**Real-world analogy**: Like a phone book - you know the name (key), you instantly find the number (value). No need to search through pages!

### Array Storage: Ordered but Expensive

Arrays maintain order but require iteration for lookups:

```solidity
address[] public users;
// Storage: length at slot N, elements at keccak256(N), keccak256(N)+1, ...
```

**Gas Costs:**
- Push: ~20,000 gas (new slot)
- Read: ~100 gas per element
- Length: ~100 gas
- Iteration: n × ~103 gas (SLOAD + MLOAD per element)

**Real-world analogy**: Like a guest list - ordered but you have to scan through to find someone. Great for iteration, bad for lookups!

### Gas Optimization: Track Totals Separately

Instead of iterating to calculate totals, maintain a running total:

```solidity
uint256 public totalBalance;  // Track separately

function setBalance(address user, uint256 amount) public {
    uint256 oldBalance = balances[user];
    balances[user] = amount;
    totalBalance = totalBalance - oldBalance + amount;  // Update running total
}
```

**Gas Savings:**
- Reading totalBalance: ~100 gas
- Calculating sumAllBalances(): n × ~103 gas
- For 100 users: 100 gas vs 10,300 gas (99% reduction!)

**Real-world analogy**: Like a cash register that keeps a running total instead of counting all items every time someone asks for the total.

### Unbounded Loop DoS Risk

⚠️ **CRITICAL**: Unbounded loops can cause DoS attacks!

```solidity
// DANGEROUS: Unbounded iteration
function sumAllBalances() public view returns (uint256) {
    uint256 sum = 0;
    for (uint256 i = 0; i < users.length; i++) {  // Could be huge!
        sum += balances[users[i]];
    }
    return sum;
}
```

**Attack Vector:**
1. Attacker adds thousands of users
2. Legitimate users can't call sumAllBalances() (exceeds gas limit)
3. Contract becomes unusable

**Mitigation:**
- Track totals separately (avoid iteration)
- Limit array size
- Use pagination for iteration
- Consider mappings + events instead of arrays

## 🏗️ What You'll Build

A gas-efficient balance tracking system that demonstrates:

1. **Mapping-based lookups** (O(1) access)
2. **Array-based iteration** (for when order matters)
3. **Running total tracking** (gas optimization)
4. **Gas cost comparisons** (iteration vs tracking)

## 📋 Tasks

### 1. Implement `addUser(address user)`
- Check if user already exists
- Add to `users` array
- Set `isUser[user] = true`
- Emit `UserAdded` event

**Gas considerations:**
- Use mapping check first (cheaper than array search)
- Cache values you'll use multiple times

### 2. Implement `setBalance(address user, uint256 amount)`
- Add user if doesn't exist
- Cache old balance
- Update balance mapping
- Update `totalBalance` efficiently
- Emit `BalanceUpdated` event

**Gas optimization:**
- Cache old balance to avoid re-reading
- Update totalBalance incrementally (don't recalculate)

### 3. Implement `sumAllBalances()` (for comparison)
- Iterate through all users
- Sum their balances
- Return total

**Gas warning:**
- This is expensive! Use only for verification
- Cache array length to avoid repeated SLOADs
- Use `unchecked` increment (safe in loop)

### 4. Implement `getTotalBalance()` (gas-efficient)
- Simply return `totalBalance`
- No iteration needed!

### 5. Write Deployment Script
- Deploy contract
- Log deployment address
- Verify deployment

### 6. Write Comprehensive Tests
- Test user addition
- Test balance updates
- Test total balance tracking
- Compare gas costs (iteration vs tracking)
- Test edge cases (zero balance, duplicate users)

## 🧪 Test Coverage

Your tests should verify:

- ✅ Users can be added
- ✅ Duplicate users are rejected
- ✅ Balances update correctly
- ✅ Total balance tracks correctly
- ✅ Iteration function works (but is expensive)
- ✅ Tracking is more gas-efficient than iteration
- ✅ Edge cases handled (zero balance, empty array)

## 🎓 Real-World Analogies & Fun Facts

### Phone Book vs Guest List
- **Mapping** = Phone book (instant lookup by name)
- **Array** = Guest list (ordered, but must scan to find)

### Cash Register Analogy
- **Running total** = Cash register display (instant read)
- **Recalculation** = Counting all items manually (slow, expensive)

### Fun Facts
- Mappings use keccak256 for storage slots (same as Project 01!)
- Array iteration costs scale linearly (O(n))
- Tracking totals separately saves 99%+ gas for large datasets
- Unbounded loops are a common DoS vector in DeFi protocols

## ✅ Completion Checklist

- [ ] Implement `addUser()` function
- [ ] Implement `setBalance()` function
- [ ] Implement `sumAllBalances()` function
- [ ] Implement `getTotalBalance()` function
- [ ] Write deployment script
- [ ] Write comprehensive test suite
- [ ] Run `forge test --gas-report` to compare gas costs
- [ ] Verify iteration is more expensive than tracking
- [ ] Review solution implementation
- [ ] Understand gas optimization patterns

## 💡 Pro Tips

1. **Cache storage reads**: If you use a value multiple times, cache it in memory
2. **Track totals separately**: Avoid expensive loops for frequently accessed totals
3. **Use mappings for lookups**: O(1) access vs O(n) for arrays
4. **Use arrays for iteration**: When order matters and you need to iterate
5. **Beware unbounded loops**: They can cause DoS attacks
6. **Compare gas costs**: Use `forge test --gas-report` to see actual costs
7. **Use unchecked arithmetic**: Safe in loops (i++ can't overflow if i < length)

## 🚀 Next Steps

After completing this project:

- Move to [Project 07: Reentrancy & Security](../07-reentrancy-and-security/)
- Study gas optimization patterns in production contracts
- Explore how DeFi protocols handle large datasets
- Learn about pagination patterns for iteration
