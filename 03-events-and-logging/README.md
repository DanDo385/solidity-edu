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

1. Implement event-driven contract
2. Run tests to verify event emissions
3. Study gas differences between events and storage
4. Experiment with event filtering

## ✅ Status

🚧 **Scaffold** - Complete Projects 01-02 first

## 🚀 Next Steps

After completing this project:
- Move to [Project 04: Modifiers & Access Control](../04-modifiers-and-restrictions/)
