# Project 03: Events & Logging 📢

> **Master Solidity events for off-chain indexing and frontend updates**

## 🎯 Learning Objectives

- Understand `event` declaration and `emit` syntax
- Use indexed parameters for efficient filtering
- Connect events to off-chain indexers (The Graph, Etherscan)
- Compare events vs storage for gas efficiency
- Implement event-driven architecture patterns

## 📚 Key Concepts

### What Are Events?

Events are **logs** stored on the blockchain that:
- ✅ Cost ~2,000 gas (vs ~20,000 for storage)
- ✅ Enable off-chain indexing and querying
- ✅ Notify frontends of state changes
- ❌ Cannot be read by contracts (write-only)

### Indexed Parameters

Up to 3 parameters can be `indexed`:
- Allows filtering events by specific values
- Costs ~375 gas extra per indexed param
- Essential for efficient event queries

## 🔧 What You'll Build

A contract demonstrating:
- Event declarations with indexed parameters
- Emitting events for state changes
- Multiple events for different operations
- Event best practices and patterns

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
