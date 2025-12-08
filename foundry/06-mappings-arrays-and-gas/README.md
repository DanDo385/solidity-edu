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

### Mapping Storage: O(1) Lookups with Hash Tables

**FIRST PRINCIPLES: Hash Table Data Structure**

Mappings provide constant-time O(1) lookups using keccak256 hashing. This is a fundamental hash table data structure implementation.

**UNDERSTANDING THE STRUCTURE**:

```solidity
mapping(address => uint256) public balances;
// Storage slot: keccak256(abi.encodePacked(key, slot_number))
```

**HOW IT WORKS** (DSA Concept):

```
Hash Table Lookup:
┌─────────────────────────────────────────┐
│ Input: address key (0x1234...)          │
│   ↓                                      │
│ Hash: keccak256(key, slot_number)       │ ← O(1) hash operation
│   ↓                                      │
│ Storage slot calculated                  │ ← Direct access
│   ↓                                      │
│ Read value from slot                     │ ← O(1) access
└─────────────────────────────────────────┘

Time Complexity: O(1) - Constant time!
Space Complexity: O(n) - Linear space for n entries
```

**CONNECTION TO PROJECT 01**: 
We learned about mapping storage layout in Project 01. The storage slot calculation uses keccak256 hashing, which is what makes mappings O(1) lookups!

**GAS COSTS** (from Project 01 knowledge):
- Cold read: ~2,100 gas (first access - SLOAD from cold slot)
- Warm read: ~100 gas (recently accessed - SLOAD from warm slot)
- Write: ~5,000 gas (warm SSTORE) or ~20,000 gas (cold SSTORE)

**COMPARISON TO RUST** (DSA Concept):

**Rust** (HashMap):
```rust
use std::collections::HashMap;

let mut balances: HashMap<Address, u256> = HashMap::new();

// Insert: O(1) average case
balances.insert(address, amount);

// Lookup: O(1) average case
let balance = balances.get(&address);
```

**Solidity** (mapping):
```solidity
mapping(address => uint256) public balances;

// Write: O(1) - direct storage write
balances[address] = amount;

// Read: O(1) - direct storage read
uint256 balance = balances[address];
```

Both use hash-based structures for O(1) operations, but Solidity's mapping is more gas-efficient because it's built into the EVM storage model.

**REAL-WORLD ANALOGY**: 
Like a phone book - you know the name (key), you instantly find the number (value). No need to search through pages! The hash function (keccak256) is like the alphabetical organization - it tells you exactly where to look.

### Array Storage: Ordered Lists with Linear Complexity

**FIRST PRINCIPLES: Array Data Structure**

Arrays maintain order but require iteration for lookups. This is a fundamental array/vector data structure.

**UNDERSTANDING THE STRUCTURE**:

```solidity
address[] public users;
// Storage: length at slot N, elements at keccak256(N), keccak256(N)+1, ...
```

**HOW IT WORKS** (DSA Concept):

```
Array Lookup:
┌─────────────────────────────────────────┐
│ Input: index (e.g., 5)                  │
│   ↓                                      │
│ Calculate slot: keccak256(N) + index    │ ← O(1) calculation
│   ↓                                      │
│ Read value from slot                     │ ← O(1) access
└─────────────────────────────────────────┘

Array Search (find address):
┌─────────────────────────────────────────┐
│ Input: address to find                  │
│   ↓                                      │
│ Iterate through all elements            │ ← O(n) iteration
│   ↓                                      │
│ Compare each element                     │ ← O(n) comparisons
│   ↓                                      │
│ Return if found                          │
└─────────────────────────────────────────┘

Time Complexity:
- Access by index: O(1) - Constant time
- Search by value: O(n) - Linear time
- Insertion: O(1) amortized (push to end)
- Deletion: O(n) - Must shift elements
```

**CONNECTION TO PROJECT 01**: 
We learned about array storage layout in Project 01. Arrays store length separately and elements at calculated slots, which enables O(1) access by index but O(n) search.

**GAS COSTS** (from Project 01 knowledge):
- Push: ~20,000 gas (new slot - cold SSTORE)
- Read by index: ~100 gas per element (warm SLOAD)
- Length: ~100 gas (SLOAD from base slot)
- Iteration: n × ~103 gas (SLOAD + MLOAD per element)

**COMPARISON TO RUST** (DSA Concept):

**Rust** (Vec):
```rust
let mut users: Vec<Address> = Vec::new();

// Push: O(1) amortized
users.push(address);

// Access by index: O(1)
let user = users[5];

// Search: O(n)
let found = users.iter().find(|&x| x == target);
```

**Solidity** (array):
```solidity
address[] public users;

// Push: O(1) - but expensive gas-wise
users.push(address);

// Access by index: O(1)
address user = users[5];

// Search: O(n) - must iterate
for (uint i = 0; i < users.length; i++) {
    if (users[i] == target) return true;
}
```

Both have similar time complexity, but Solidity arrays are more expensive gas-wise due to storage costs.

**REAL-WORLD ANALOGY**: 
Like a guest list - ordered but you have to scan through to find someone. Great for iteration (going through the list), bad for lookups (finding a specific person). Arrays are perfect when you need order and iteration, but mappings are better for lookups!

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
### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/MappingsArraysGasSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployMappingsArraysGasSolution.s.sol` - Deployment script patterns
- `test/solution/MappingsArraysGasSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains hash tables (O(1) lookups), dynamic arrays (O(n) iteration), running totals pattern (O(1) vs O(n))
- **Connections to Project 01**: References mapping/array storage patterns, builds on storage layout concepts
- **THE KEY OPTIMIZATION**: Running totals pattern - 99% gas savings vs iteration (critical for all balance systems)
- **Real-World Context**: This pattern is used in all DeFi protocols (Uniswap, Aave, Compound)

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
