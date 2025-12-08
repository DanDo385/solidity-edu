# Project 03: Events & Logging 📢

> **Master Solidity events for off-chain indexing and frontend updates**

## 🎯 Learning Objectives

By completing this project, you will:

1. **Understand `event` declaration and `emit` syntax**
2. **Use indexed parameters** for efficient filtering
3. **Connect events to off-chain indexers** (The Graph, Etherscan)
4. **Compare events vs storage** for gas efficiency
5. **Implement event-driven architecture patterns**
6. **Learn how event design choices** ripple into L2 rollups and analytics pipelines
7. **Create Foundry deployment scripts** from scratch
8. **Write comprehensive test suites** using Foundry's testing framework

## 📁 Project Directory Structure

### Understanding `cache/` and `out/` Directories

When you run `forge build` or `forge test`, Foundry generates two important directories:

#### `cache/` Directory

The `cache/` directory contains Foundry's **compilation cache**:
- **Purpose**: Tracks file metadata to determine what needs recompiling
- **Contents**: `solidity-files-cache.json` - stores modification dates, content hashes, imports, and build artifacts
- **Why it exists**: Speeds up compilation by only recompiling files that changed
- **Should you commit it?**: No - it's auto-generated and project-specific

**Real-world analogy**: Like a library's card catalog - it tracks which books (files) exist and when they were last updated, so the librarian (compiler) knows what needs checking.

#### `out/` Directory

The `out/` directory contains **compiled contract artifacts**:
- **Purpose**: Stores all compilation outputs (bytecode, ABIs, metadata)
- **Structure**: One subdirectory per Solidity file that gets compiled - this includes **everything**:
  - ✅ Your contracts (`EventsLogging.sol`)
  - ✅ Your tests (`EventsLogging.t.sol`)
  - ✅ Your scripts (`DeployEventsLogging.s.sol`)
  - ✅ **All forge-std library files** (`Base.sol`, `Test.sol`, `Script.sol`, `Vm.sol`, `console.sol`, etc.)
  - ✅ **All Std* helper contracts** (`StdAssertions.sol`, `StdChains.sol`, `StdCheats.sol`, `StdStorage.sol`, etc.)
  - ✅ **Interface contracts** (`IMulticall3.sol`)
  - ✅ **Any imported dependencies**

- **Why so many subdirectories?**: Foundry compiles **every Solidity file** that your project uses, including all dependencies from `forge-std` and other libraries. Each file gets its own directory with JSON artifacts, even if you didn't write it yourself!
- **What's in each JSON file?**:
  - `bytecode.object`: Deployment bytecode (constructor + contract code)
  - `deployedBytecode.object`: Runtime bytecode (what's stored on-chain)
  - `abi`: Application Binary Interface (function signatures, events, errors)
  - `metadata`: Compiler version, settings, source mappings
- **Should you commit it?**: No - it's auto-generated and can be rebuilt with `forge build`

**Real-world analogy**: Like a factory's finished goods warehouse - each product (contract) gets its own shelf (subdirectory) with all its documentation (JSON artifacts) stored together.

**Pro tip**: You can extract ABIs for frontend integration:
```bash
# Extract ABI for your contract
cat out/EventsLogging.sol/EventsLogging.json | jq '.abi' > abi.json
```

## 📚 Key Concepts

### Why This Matters: Events as the Bridge Between On-Chain and Off-Chain

**FIRST PRINCIPLES: The On-Chain/Off-Chain Divide**

Blockchain contracts run in isolation - they can't directly communicate with external systems. Events solve this by creating a one-way communication channel from contracts to the outside world.

**THE PROBLEM WITHOUT EVENTS**:
```
Frontend needs to know: "Did Alice transfer tokens to Bob?"
Without events:
  - Frontend must constantly poll contract storage (expensive!)
  - Must check every block for changes
  - No efficient way to filter by address
  - High RPC costs, slow updates
```

**THE SOLUTION WITH EVENTS**:
```
Frontend needs to know: "Did Alice transfer tokens to Bob?"
With events:
  - Contract emits Transfer event when transfer happens
  - Indexer (The Graph) listens to events automatically
  - Frontend queries indexer (fast, free, filtered)
  - Real-time updates, efficient filtering
```

**CONNECTION TO PROJECT 01 & 02**:
- **Project 01**: We learned about storage (expensive, ~20k gas per write)
- **Project 02**: We learned about functions and ETH handling
- **Project 03**: Events complement storage - use storage for state, events for history!

**COMPARISON TO OTHER LANGUAGES**:

**Python**:
```python
print("Transfer:", from_addr, to_addr, amount)  # Goes to console, disappears
# No persistence, no searchability
```

**Go**:
```go
log.Printf("Transfer: %s -> %s: %d", from, to, amount)  // Goes to log file
// Persistent but not on-chain, not searchable by contracts
```

**Rust**:
```rust
println!("Transfer: {} -> {}: {}", from, to, amount);  // Console output
// Not persistent, not on-chain
```

**Solidity**:
```solidity
emit Transfer(from, to, amount);  // Permanently stored on blockchain!
// Persistent, searchable, filterable, accessible off-chain
```

**REAL-WORLD ANALOGY**: 
- **Traditional logging** = Writing in a notebook (temporary, local, disappears)
- **Solidity events** = Publishing in a newspaper (permanent, public, searchable forever)

**HISTORICAL CONTEXT**: Solidity (started by Gavin Wood) added events early so frontends could react without polluting storage. The EVM keeps logs in a separate bloom-filtered structure for fast topic search. This design decision enables the entire DeFi ecosystem - without events, frontends would be prohibitively expensive to build!

**GAS EFFICIENCY**: Events cost ~2,000 gas vs ~20,000 gas for storage writes. That's a **10x savings**! This is why events are essential for tracking history without bloating contract storage.

### What Are Events? Understanding the Logging System

**FIRST PRINCIPLES: Events as Write-Only Logs**

Events are **logs** stored on the blockchain that:
- ✅ Cost ~2,000 gas (vs ~20,000 for storage) - **10x cheaper!**
- ✅ Enable off-chain indexing and querying
- ✅ Notify frontends of state changes
- ✅ Permanent and immutable (cannot be deleted)
- ❌ Cannot be read by contracts (write-only)
- 🛰️ Survive chain reorgs with topics that clients can replay deterministically

**UNDERSTANDING THE EVM LOG STRUCTURE**:

The EVM stores events in a special log structure separate from contract storage:

```
Transaction Log Structure:
┌─────────────────────────────────────────┐
│ Block Number: 12345                     │
│ Transaction Hash: 0xABCD...            │
│ Contract Address: 0x1234...            │
│ Event Topics: [topic1, topic2, ...]   │ ← Indexed parameters
│ Event Data: [data1, data2, ...]        │ ← Non-indexed parameters
└─────────────────────────────────────────┘
```

**HOW EVENTS ARE STORED**:

1. **Topics** (Indexed Parameters):
   - Up to 3 indexed parameters per event
   - Stored in bloom filter for fast searching
   - Each topic is 32 bytes (keccak256 hash for non-uint256 types)

2. **Data** (Non-Indexed Parameters):
   - All non-indexed parameters encoded as ABI-encoded data
   - Stored in log data section
   - Can be any size (strings, arrays, etc.)

**CONNECTION TO PROJECT 01**: Remember storage slots? Events use a completely different storage mechanism:
- **Storage**: SSTORE opcode, stored in contract's storage slots
- **Events**: LOG opcodes, stored in transaction logs (separate from storage)

**REAL-WORLD ANALOGY**: 
- **Storage** = The actual inventory (expensive to update, queryable on-chain, like a warehouse)
- **Events** = Receipts (cheap to print, permanent record, searchable off-chain, like transaction receipts)
- **Frontend** = Cash register display (shows events in real-time, like a dashboard)

**WHY WRITE-ONLY?**

Events cannot be read by contracts because:
1. **Gas efficiency**: Reading logs would require expensive operations
2. **Design philosophy**: Events are for off-chain systems, not on-chain logic
3. **Separation of concerns**: State (storage) vs history (events)

**BLOOM FILTERS: The Magic Behind Fast Event Search**

The EVM uses bloom filters to quickly check if an event might exist in a block:
- **Bloom filter**: Probabilistic data structure (fast but may have false positives)
- **Indexed parameters**: Stored in bloom filter for O(1) lookup
- **Why it matters**: Enables fast event filtering without scanning all logs

**EXAMPLE**:
```solidity
event Transfer(address indexed from, address indexed to, uint256 amount);

// Bloom filter stores:
// - keccak256(from) → topic1
// - keccak256(to) → topic2
// - amount → data (not in bloom filter)

// To find all transfers FROM 0x1234...:
// 1. Check bloom filter for topic1 = keccak256(0x1234...)
// 2. If present, scan logs for exact match
// 3. Much faster than scanning all logs!
```

**GAS COST BREAKDOWN**:

**Event Emission**:
- Base cost: ~375 gas (LOG1 opcode)
- Per indexed parameter: +375 gas (LOG2/LOG3/LOG4)
- Per byte of data: +8 gas

**Example**:
```solidity
event Transfer(address indexed from, address indexed to, uint256 amount);
emit Transfer(0x1234..., 0x5678..., 100);

// Gas cost:
// - LOG3 base: ~1,125 gas (3 indexed params)
// - Data (uint256): +32 bytes × 8 gas = +256 gas
// - Total: ~1,381 gas
```

**COMPARISON TO STORAGE**:
- **Event**: ~1,381 gas (for Transfer with 2 indexed params)
- **Storage**: ~20,000 gas (cold write) or ~5,000 gas (warm write)
- **Savings**: ~18,619 gas (cold) or ~3,619 gas (warm)!

**WHEN TO USE EVENTS**:
- ✅ Logging state changes for off-chain systems
- ✅ Tracking transfer history (cheaper than storage arrays)
- ✅ Frontend notifications
- ✅ Analytics and reporting
- ✅ Audit trails

**WHEN NOT TO USE EVENTS**:
- ❌ Data needed by contract logic (use storage)
- ❌ Current state that contracts read (use storage)
- ❌ Values that change frequently and need on-chain access (use storage)

### Indexed Parameters: The Search Feature

**FIRST PRINCIPLES: Why Indexing Matters**

Up to 3 parameters can be `indexed`:
- Allows filtering events by specific values
- Costs ~375 gas extra per indexed param
- Essential for efficient event queries
- Great for L2s because you can stream only the topics you need instead of all calldata

**UNDERSTANDING INDEXED VS NON-INDEXED**:

**Indexed Parameters**:
- Stored as **topics** in the event log
- Included in bloom filter for fast searching
- Limited to 32 bytes (address, uint256, bytes32, etc.)
- Can filter efficiently: "Show me all events where from = 0x1234..."

**Non-Indexed Parameters**:
- Stored as **data** in the event log
- NOT included in bloom filter
- Can be any size (strings, arrays, structs, etc.)
- Cannot filter efficiently: Must read all logs and check data

**HOW INDEXING WORKS**:

```solidity
event Transfer(address indexed from, address indexed to, uint256 amount);

// When emitted:
emit Transfer(0x1234..., 0x5678..., 100);

// Event log structure:
// Topics: [
//   keccak256("Transfer(address,address,uint256)"),  // Event signature
//   keccak256(0x1234...),                            // from (indexed)
//   keccak256(0x5678...)                            // to (indexed)
// ]
// Data: [100]  // amount (non-indexed, ABI-encoded)
```

**GAS COST BREAKDOWN**:

**LOG Opcodes**:
- LOG1 (no indexed): ~375 gas base + 8 gas/byte of data
- LOG2 (1 indexed): ~750 gas base + 8 gas/byte of data
- LOG3 (2 indexed): ~1,125 gas base + 8 gas/byte of data
- LOG4 (3 indexed): ~1,500 gas base + 8 gas/byte of data

**Example Costs**:
```solidity
// Event with 0 indexed params:
event SimpleEvent(uint256 value);
emit SimpleEvent(100);
// Cost: ~375 + (32 bytes × 8) = ~631 gas

// Event with 2 indexed params:
event Transfer(address indexed from, address indexed to, uint256 amount);
emit Transfer(0x1234..., 0x5678..., 100);
// Cost: ~1,125 + (32 bytes × 8) = ~1,381 gas
// Extra cost: ~750 gas for indexing (but enables filtering!)
```

**WHEN TO INDEX**:

✅ **DO Index**:
- Addresses (you'll almost always filter by address)
- Token IDs (for NFT transfers)
- User IDs (for user-specific queries)
- Timestamps (if you need to filter by time range)

❌ **DON'T Index**:
- Large strings (limited to 32 bytes anyway)
- Arrays (can't index arrays directly)
- Structs (can't index structs directly)
- Values rarely filtered (saves gas)

**EXAMPLE - GOOD EVENT DESIGN**:
```solidity
event Transfer(address indexed from, address indexed to, uint256 amount);
// ✅ Addresses indexed (filterable)
// ✅ Amount not indexed (rarely filtered, saves gas)
// ✅ Matches ERC20 standard (compatible with tools)

// Can filter efficiently:
// - "Show me all transfers FROM address X"
// - "Show me all transfers TO address Y"
// - Cannot filter by amount (but that's OK - rarely needed)
```

**EXAMPLE - BAD EVENT DESIGN**:
```solidity
event Transfer(address from, address to, uint256 indexed amount);
// ❌ Addresses not indexed (can't filter efficiently!)
// ❌ Amount indexed (rarely filtered, wastes gas)
// ❌ Breaks ERC20 standard (incompatible with tools)
```

**REAL-WORLD ANALOGY**: 
- **Indexed parameters** = Searchable tags on blog posts (you can search for posts tagged "solidity")
- **Non-indexed parameters** = Full blog post content (you can't efficiently search the full content)

**CONNECTION TO PROJECT 01**: Remember how mappings use keccak256 for storage calculation? Indexed parameters work similarly - they're hashed and stored in a bloom filter for fast lookup!

**L2 ROLLUP CONSIDERATIONS**:

On Layer 2 rollups (Arbitrum, Optimism), calldata is expensive:
- **Indexed params**: Stored as topics (cheaper on L2)
- **Non-indexed params**: Stored as data (more expensive on L2)
- **Best practice**: Index what you'll filter, keep data small

**THE GRAPH INTEGRATION**:

The Graph protocol indexes events for subgraphs:
- Indexed params: Automatically indexed, fast queries
- Non-indexed params: Must be decoded from data, slower queries
- **Best practice**: Design events with indexers in mind!

**FILTERING EXAMPLES**:

```javascript
// Filter by indexed parameter (FAST):
contract.on("Transfer", { from: "0x1234..." }, (event) => {
    console.log("Transfer from 0x1234...!");
});

// Filter by non-indexed parameter (SLOW):
// Must read all Transfer events and check amount
// Not recommended for production!
```

**GAS OPTIMIZATION TIP**:

Only index what you'll actually filter by:
- **3 indexed params**: ~1,500 gas base
- **2 indexed params**: ~1,125 gas base
- **Savings**: ~375 gas per event (if you don't need the 3rd index)

### Events vs Storage: Choosing the Right Tool

**FIRST PRINCIPLES: Complementary, Not Competing**

Events and storage serve different purposes. Understanding when to use each is crucial for efficient contract design.

**COMPREHENSIVE COMPARISON**:

| Aspect | Events | Storage |
|--------|--------|---------|
| **Cost** | ~2,000 gas | ~20,000 gas (cold write) |
| **Readable by contracts?** | ❌ No | ✅ Yes |
| **Readable off-chain?** | ✅ Yes (via logs) | ✅ Yes (via RPC) |
| **Filterable?** | ✅ Yes (indexed params) | ❌ No (must read all) |
| **Permanent?** | ✅ Yes | ✅ Yes |
| **Modifiable?** | ❌ No | ✅ Yes (by contract) |
| **Gas cost per write** | ~1,500-2,000 gas | ~5,000-20,000 gas |
| **Gas cost per read (on-chain)** | N/A (can't read) | ~100-2,100 gas |
| **Use case** | History, logging | Current state |

**CONNECTION TO PROJECT 01 & 02**:

Remember from Project 01:
- **Storage**: SSTORE opcode, ~20k gas (cold) or ~5k gas (warm)
- **Storage reads**: SLOAD opcode, ~2.1k gas (cold) or ~100 gas (warm)

Remember from Project 02:
- We used storage for `balances` mapping (needed for contract logic)
- We emitted events for deposits/withdrawals (needed for off-chain tracking)

**THE GOLDEN RULE**:
- **Storage**: For data contracts need to READ
- **Events**: For data contracts need to LOG (but don't need to read)

**WHEN TO USE EVENTS**:

✅ **Use Events For**:
- Logging state changes for off-chain systems
- Tracking transfer history (cheaper than storage arrays)
- Frontend notifications
- Analytics and reporting
- Audit trails
- Historical data that doesn't need on-chain access

**Example**:
```solidity
// ✅ GOOD: Use events for history
event Transfer(address indexed from, address indexed to, uint256 amount);

function transfer(address to, uint256 amount) public {
    balances[msg.sender] -= amount;  // Storage (needed for logic)
    balances[to] += amount;          // Storage (needed for logic)
    emit Transfer(msg.sender, to, amount);  // Event (for history)
}
```

**WHEN TO USE STORAGE**:

✅ **Use Storage For**:
- Data needed by contract logic
- Current state that contracts read
- Values that change frequently and need on-chain access
- Mappings, arrays, structs needed for computation

**Example**:
```solidity
// ✅ GOOD: Use storage for current state
mapping(address => uint256) public balances;  // Needed for transfers

function transfer(address to, uint256 amount) public {
    require(balances[msg.sender] >= amount);  // Read from storage
    balances[msg.sender] -= amount;          // Write to storage
    balances[to] += amount;                 // Write to storage
}
```

**THE COST COMPARISON**:

**Tracking Transfer History**:

**Option 1: Storage Array** (Expensive):
```solidity
struct Transfer {
    address from;
    address to;
    uint256 amount;
}
Transfer[] public transferHistory;

function transfer(address to, uint256 amount) public {
    // ... transfer logic ...
    transferHistory.push(Transfer(msg.sender, to, amount));
    // Cost: ~20,000 gas (cold) per transfer!
}
```

**Option 2: Events** (Cheap):
```solidity
event Transfer(address indexed from, address indexed to, uint256 amount);

function transfer(address to, uint256 amount) public {
    // ... transfer logic ...
    emit Transfer(msg.sender, to, amount);
    // Cost: ~1,500 gas per transfer!
}
```

**Savings**: ~18,500 gas per transfer! 🎉

**REAL-WORLD ANALOGY**: 
- **Storage** = Your bank account balance (you need to check it frequently, it changes, you need it for transactions)
- **Events** = Your bank statement (history of transactions, you don't need to check it often, but it's useful for records and audits)

**BEST PRACTICE PATTERN**:

```solidity
contract Token {
    // Storage: Current state (needed for logic)
    mapping(address => uint256) public balances;
    
    // Events: History (needed for off-chain systems)
    event Transfer(address indexed from, address indexed to, uint256 amount);
    
    function transfer(address to, uint256 amount) public {
        // 1. Read from storage (needed for logic)
        require(balances[msg.sender] >= amount);
        
        // 2. Update storage (needed for logic)
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        // 3. Emit event (needed for off-chain tracking)
        emit Transfer(msg.sender, to, amount);
    }
}
```

**COMMON MISTAKES**:

❌ **Storing history in storage arrays**:
```solidity
Transfer[] public history;  // ❌ Expensive!
// Use events instead!
```

❌ **Trying to read events from contracts**:
```solidity
// ❌ Can't do this - events are write-only!
uint256 lastTransfer = getLastTransfer();  // Not possible!
```

✅ **Using both appropriately**:
```solidity
mapping(address => uint256) public balances;  // ✅ Storage for state
event Transfer(...);                          // ✅ Events for history
```

**GAS OPTIMIZATION TIP**:

If you need to track history, use events instead of storage arrays:
- **Storage array**: ~20,000 gas per entry (cold)
- **Event**: ~1,500 gas per entry
- **Savings**: ~18,500 gas per entry!

**CONNECTION TO PROJECT 02**: Remember how we emitted events in deposit/withdraw functions? That's the perfect pattern - use storage for balances (needed for logic), events for history (needed for off-chain systems)!

### Event Design Best Practices

1. **Mirror ERC standards**: Use same event names/signatures as ERC20/ERC721 for compatibility
2. **Index addresses**: Almost always index `address` parameters (enables filtering)
3. **Limit indexed params**: Only index what you'll filter by (costs extra gas)
4. **Keep events small**: Large events cost more gas
5. **Use descriptive names**: `Transfer` not `T`, `Deposit` not `Dep`

**Example - Good Event Design**:
```solidity
event Transfer(address indexed from, address indexed to, uint256 amount);
// ✅ Addresses indexed (filterable)
// ✅ Amount not indexed (rarely filtered, saves gas)
// ✅ Matches ERC20 standard (compatible with tools)
```

## 🔍 Deep Dive: Contract Walkthrough

- **Constructor**: Sets `owner` to deployer and mints `1_000_000 * 10**18` in one write—one-time init pattern you'll reuse for ownership (see Project 04). Single multiplication beats loops of `SSTORE`s.
- **transfer**: CEI ordering (Project 02). Two mapping writes follow the Project 01 layout, then the ERC20-style `Transfer` event so off-chain tools can index by `from`/`to`. Emitting after state avoids paying for logs on reverts.
- **approve**: Nested mapping (`owner => spender => allowance`) showcases the double `keccak256` slot math. Direct assignment overwrites old approvals on purpose to match ERC20 and save a read; use `+=` only when you intentionally allow incremental approvals.
- **deposit**: `payable` enables ETH flow (Project 02). Uses `+=` read-modify-write on balances, and the `Deposit` event carries the timestamp instead of storing an extra slot—cheap history, same state.
- **updateStatus**: Demonstrates expensive dynamic strings. Caches the previous status in memory before the write to avoid two `SLOAD`s, emits `StatusChanged` for history, and hints that `bytes32` is a cheaper option for fixed phrases.

## 🔧 What You'll Build

A contract demonstrating:
- Event declarations with indexed parameters
- Emitting events for state changes
- Multiple events for different operations
- Event best practices and patterns
- Practical schemas that mirror ERC20/721 so block explorers and subgraphs can ingest them easily

Plus:
- **Deployment script** using Foundry Scripts
- **Comprehensive test suite** with event verification and fuzz testing

## 📝 Tasks

### Task 1: Implement the Smart Contract

Open `src/EventsLogging.sol` and implement all the TODOs:

1. **State variables** (owner, balances, allowances)
2. **Event declarations** with appropriate indexed parameters
3. **Functions that emit events** for all state changes
4. **Multiple event types** for different operations
5. **Event data structures** that balance filterability and cost

### Task 2: Create Your Deployment Script

Open `script/DeployEventsLogging.s.sol` and implement:

1. Read deployer's private key from environment using `vm.envOr()`
2. Start broadcasting transactions with `vm.startBroadcast()`
3. Deploy the contract
4. Log deployment information using `console.log()`
5. Stop broadcasting with `vm.stopBroadcast()`

**Why deployment scripts?** Reproducible, scriptable deployments that work the same way every time.

### Task 3: Write Your Test Suite

Open `test/EventsLogging.t.sol` and write comprehensive tests:

1. Constructor behavior (sets owner, initial balance)
2. Transfer tests (basic transfer, events, edge cases)
3. Approval tests (approve, events, edge cases)
4. Deposit tests (deposit ETH, events, timestamps)
5. Status update tests (update status, events)
6. Event emission verification using `vm.expectEmit()`
7. Indexed parameter filtering tests
8. Multiple events in single transaction
9. Fuzz testing with randomized inputs
10. Gas benchmarking (events vs storage)

**Testing Best Practices**:
- Use descriptive test names: `test_FunctionName_Scenario`
- Follow Arrange-Act-Assert pattern
- Use `vm.expectEmit()` for event testing
- Use `vm.expectRevert()` for error testing
- Use `testFuzz_` prefix for fuzz tests

### Task 4: Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/EventsLoggingSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployEventsLoggingSolution.s.sol` - Deployment script patterns
- `test/solution/EventsLoggingSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains event-driven architecture, logging vs storage trade-offs, bloom filters for indexed parameters
- **Connections to Projects 01-02**: References storage patterns and function visibility concepts
- **ERC20 Patterns**: Demonstrates Transfer and Approval events that are required by ERC20 standard (Project 08)
- **Real-World Context**: Shows how events enable off-chain indexing and frontend updates

### Task 5: Compile and Test

```bash
cd 03-events-and-logging

# Compile contracts
forge build

# Run all tests
forge test

# Run with verbose output to see events
forge test -vvv

# Run with gas reporting
forge test --gas-report

# Run specific test
forge test --match-test test_Transfer
```

### Task 6: Deploy Locally

**⚠️ IMPORTANT: This project runs on LOCAL ANVIL ONLY**

```bash
# Terminal 1: Start Anvil (keep this running)
anvil

# Terminal 2: Deploy
cd 03-events-and-logging

# Dry run (simulation only)
forge script script/DeployEventsLogging.s.sol

# Deploy to local Anvil (with transactions)
forge script script/DeployEventsLogging.s.sol \
  --broadcast \
  --rpc-url http://localhost:8545
```

**Environment Setup**:

Create `.env` with Anvil's default accounts (see project files for examples). Use `PRIVATE_KEY` for main deployer, `PRIVATE_KEY_1` through `PRIVATE_KEY_9` for multi-address testing.

### Task 7: Experiment

Try these experiments:
1. Query events using `cast logs` - filter by indexed parameters
2. Compare gas costs: emit event vs store in mapping
3. Test with multiple events in one transaction
4. Build a simple frontend that listens to events
5. Measure gas: indexed vs non-indexed parameters

## ✅ Key Takeaways & Common Pitfalls

- Events are ~10x cheaper than storage writes; keep state in storage and history in logs.
- Indexed params (max 3) make filtering possible—log addresses/token IDs, not giant strings.
- Logs are write-only for contracts, so design read paths with storage and view functions.
- Cache storage reads (like the old status) before writing to avoid extra `SLOAD`s.
- Strings/dynamic data are pricey; prefer `bytes32` when the shape is fixed and log the rest.
- Emit after state changes so reverted transactions don't still pay for useless logs.

## 🧪 Test Coverage

The test suite covers:

- ✅ Constructor behavior (sets owner, initial balance)
- ✅ Transfer operations (basic transfer, events, edge cases)
- ✅ Approval operations (approve, events, edge cases)
- ✅ Deposit operations (deposit ETH, events, timestamps)
- ✅ Status updates (update status, events)
- ✅ Event emission verification
- ✅ Indexed parameter filtering
- ✅ Multiple events in single transaction
- ✅ Event data structure validation
- ✅ Gas cost comparisons (events vs storage)
- ✅ Fuzz testing with randomized inputs

## 🛰️ Real-World Analogies & Fun Facts

- **Newspaper vs filing cabinet**: Events are like publishing a newspaper clipping—cheap, widely distributed, but not editable. Storage is a locked filing cabinet—expensive but queryable on-chain.
- **Creator trivia**: Solidity (started by Gavin Wood) added events early so frontends could react without polluting storage. The EVM keeps logs in a separate bloom-filtered structure for fast topic search.
- **DAO fork echo**: Post-DAO fork, explorers replayed logs on both Ethereum and Ethereum Classic. Event schemas with indexed fields made it easier to reconcile divergent histories.
- **Layer 2 twist**: Rollups compress calldata; well-designed, small events keep fees low for subgraphs that monitor L2s like Arbitrum and Optimism.
- **ETH issuance angle**: Storing every checkpoint on-chain bloats state and can pressure validator costs (and therefore issuance). Emitting events instead of writing storage is a small but meaningful way to keep state lean.
- **Compiler fact**: Solc can prune unused event parameters during optimization. Keeping event arguments tight helps the optimizer reduce bytecode size and gas.
- **Bloom filters**: The EVM uses bloom filters to quickly check if an event might exist in a block before doing expensive log searches. This is why indexed parameters are so powerful - they're stored in the bloom filter!
- **The Graph**: Most DeFi frontends use The Graph protocol to index events. Well-designed events make subgraph development much easier.

## ✅ Completion Checklist

- [ ] Implemented skeleton contract (`src/EventsLogging.sol`)
- [ ] Created deployment script (`script/DeployEventsLogging.s.sol`)
- [ ] Wrote comprehensive test suite (`test/EventsLogging.t.sol`)
- [ ] All tests pass (`forge test`)
- [ ] Deployment script works locally (`forge script --broadcast`)
- [ ] Read and understood solution contract (`src/solution/`)
- [ ] Read and understood solution script (`script/solution/`)
- [ ] Read and understood solution tests (`test/solution/`)
- [ ] Compared gas costs (`forge test --gas-report`)
- [ ] Understand indexed vs non-indexed parameters
- [ ] Can query events using web3/ethers
- [ ] Know when to use events vs storage
- [ ] Understand event gas costs
- [ ] Can design event schemas for dApps

## 🚀 Next Steps

After completing this project:

- Move to [Project 04: Modifiers & Access Control](../04-modifiers-and-restrictions/)
- Integrate with The Graph for event indexing
- Build a frontend that listens to events
- Study ERC standards' event patterns (ERC20, ERC721)
- Experiment with event filtering in block explorers

## 💡 Pro Tips

1. **Always emit events for state changes** - they're cheap and essential for off-chain systems
2. **Index addresses** - you'll almost always want to filter by address
3. **Limit indexed params to 3** - that's the EVM maximum
4. **Mirror ERC standards** - makes your contract compatible with existing tools
5. **Use events instead of storage arrays** for history - much cheaper!
6. **Test event emissions** using `vm.expectEmit()` - ensures events are correct
7. **Consider L2 implications** - smaller events = lower fees on rollups
8. **Design for indexers** - think about how The Graph will index your events
9. **Use descriptive event names** - `Transfer` not `T`, `Deposit` not `Dep`
10. **Include timestamps in events** - cheaper than storing separately

---

**Ready to code?** Open `src/EventsLogging.sol` and start implementing! Remember: events are your contract's API for the off-chain world! 📢
