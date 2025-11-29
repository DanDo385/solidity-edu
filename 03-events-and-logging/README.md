# Project 03: Events & Logging 📢

> **Master Solidity events for off-chain indexing and frontend updates**

## 🎯 Learning Objectives

- Understand `event` declaration and `emit` syntax
- Use indexed parameters for efficient filtering
- Connect events to off-chain indexers (The Graph, Etherscan)
- Compare events vs storage for gas efficiency
- Implement event-driven architecture patterns
- Learn how event design choices ripple into L2 rollups and analytics pipelines

## 📚 Key Concepts

### What Are Events?

Events are **logs** stored on the blockchain that:
- ✅ Cost ~2,000 gas (vs ~20,000 for storage)
- ✅ Enable off-chain indexing and querying
- ✅ Notify frontends of state changes
- ❌ Cannot be read by contracts (write-only)
- 🛰️ Survive chain reorgs with topics that clients can replay deterministically

### Indexed Parameters

Up to 3 parameters can be `indexed`:
- Allows filtering events by specific values
- Costs ~375 gas extra per indexed param
- Essential for efficient event queries
- Great for L2s because you can stream only the topics you need instead of all calldata

## 🔧 What You'll Build

A contract demonstrating:
- Event declarations with indexed parameters
- Emitting events for state changes
- Multiple events for different operations
- Event best practices and patterns
- Practical schemas that mirror ERC20/721 so block explorers and subgraphs can ingest them easily

## 📝 Tasks

### Task 1: Implement the Skeleton Contract

Open `src/EventsLogging.sol` and implement:

1. **Event declarations** with appropriate indexed parameters
2. **Functions that emit events** for all state changes
3. **Multiple event types** for different operations
4. **Event data structures** that balance filterability and cost

### Task 2: Study the Solution

Compare with `src/solution/EventsLoggingSolution.sol`:
- See how indexed parameters enable efficient filtering
- Understand gas trade-offs between indexed and non-indexed
- Learn event naming and structure best practices
- Study real-world event patterns

### Task 3: Run Tests

```bash
cd 03-events-and-logging

# Run all tests
forge test

# Run with verbose output to see events
forge test -vvv

# Run specific test
forge test --match-test test_Events

# Check gas costs
forge test --gas-report
```

### Task 4: Experiment

Try these experiments:

```bash
# Deploy locally
anvil  # In one terminal

# In another terminal
forge script script/Deploy.s.sol --broadcast --rpc-url http://localhost:8545

# Query events using cast
cast logs --address <CONTRACT_ADDRESS> \
  "Transfer(address indexed,address indexed,uint256)"
```

## 🧪 Test Coverage

The test suite covers:

- ✅ Event emission verification
- ✅ Indexed parameter filtering
- ✅ Multiple events in single transaction
- ✅ Event data structure validation
- ✅ Gas cost comparisons (events vs storage)
- ✅ Event best practices

## 🛰️ Real-World Analogies & Fun Facts

- **Newspaper vs filing cabinet**: Events are like publishing a newspaper clipping—cheap, widely distributed, but not editable. Storage is a locked filing cabinet—expensive but queryable on-chain.
- **Creator trivia**: Solidity (started by Gavin Wood) added events early so frontends could react without polluting storage. The EVM keeps logs in a separate bloom-filtered structure for fast topic search.
- **DAO fork echo**: Post-DAO fork, explorers replayed logs on both Ethereum and Ethereum Classic. Event schemas with indexed fields made it easier to reconcile divergent histories.
- **Layer 2 twist**: Rollups compress calldata; well-designed, small events keep fees low for subgraphs that monitor L2s like Arbitrum and Optimism.
- **ETH issuance angle**: Storing every checkpoint on-chain bloats state and can pressure validator costs (and therefore issuance). Emitting events instead of writing storage is a small but meaningful way to keep state lean.
- **Compiler fact**: Solc can prune unused event parameters during optimization. Keeping event arguments tight helps the optimizer reduce bytecode size and gas.

## ✅ Completion Checklist

- [ ] Implemented skeleton contract
- [ ] All tests pass
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
