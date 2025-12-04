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

### Why This Matters

Events are the bridge between on-chain and off-chain worlds. Without events, frontends would have to constantly poll storage (expensive and inefficient!). Events make blockchain data accessible to indexers, frontends, and analytics tools.

**Traditional code**: Logs go to console, then disappear
**Solidity events**: Logs are permanently stored on blockchain, searchable forever

Solidity (started by Gavin Wood) added events early so frontends could react without polluting storage. The EVM keeps logs in a separate bloom-filtered structure for fast topic search.

### What Are Events?

Events are **logs** stored on the blockchain that:
- ✅ Cost ~2,000 gas (vs ~20,000 for storage) - **10x cheaper!**
- ✅ Enable off-chain indexing and querying
- ✅ Notify frontends of state changes
- ✅ Permanent and immutable (cannot be deleted)
- ❌ Cannot be read by contracts (write-only)
- 🛰️ Survive chain reorgs with topics that clients can replay deterministically

**Real-world analogy**: Events are like receipts at a store:
- **Storage** = The actual inventory (expensive to update, queryable on-chain)
- **Events** = Receipts (cheap to print, permanent record, searchable off-chain)
- **Frontend** = Cash register display (shows events in real-time)

### Indexed Parameters

Up to 3 parameters can be `indexed`:
- Allows filtering events by specific values
- Costs ~375 gas extra per indexed param
- Essential for efficient event queries
- Great for L2s because you can stream only the topics you need instead of all calldata

**Gas Cost Breakdown**:
- LOG1 (no indexed): ~375 gas base + 8 gas/byte
- LOG2 (1 indexed): ~750 gas base + 8 gas/byte  
- LOG3 (2 indexed): ~1,125 gas base + 8 gas/byte
- LOG4 (3 indexed): ~1,500 gas base + 8 gas/byte

**Example**:
```solidity
event Transfer(address indexed from, address indexed to, uint256 amount);
// Can filter: "Show me all transfers FROM address X"
// Can filter: "Show me all transfers TO address Y"
// Cannot filter by amount (not indexed)
```

**Real-world analogy**: Indexed parameters are like searchable tags on blog posts. You can search for posts tagged "solidity" (indexed), but you can't efficiently search the full content (non-indexed).

### Events vs Storage

| Aspect | Events | Storage |
|--------|--------|---------|
| **Cost** | ~2,000 gas | ~20,000 gas (cold write) |
| **Readable by contracts?** | ❌ No | ✅ Yes |
| **Readable off-chain?** | ✅ Yes (via logs) | ✅ Yes (via RPC) |
| **Filterable?** | ✅ Yes (indexed params) | ❌ No (must read all) |
| **Permanent?** | ✅ Yes | ✅ Yes |
| **Modifiable?** | ❌ No | ✅ Yes (by contract) |

**When to use events**:
- Logging state changes for off-chain systems
- Tracking transfer history (cheaper than storage arrays)
- Frontend notifications
- Analytics and reporting

**When to use storage**:
- Data needed by contract logic
- Current state that contracts read
- Values that change frequently and need on-chain access

**Real-world analogy**: 
- **Storage** = Your bank account balance (you need to check it, it changes)
- **Events** = Your bank statement (history of transactions, you don't need to check it often, but it's useful for records)

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
- `src/solution/EventsLoggingSolution.sol` - Reference contract implementation
- `script/solution/DeployEventsLoggingSolution.s.sol` - Deployment script patterns
- `test/solution/EventsLoggingSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

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
