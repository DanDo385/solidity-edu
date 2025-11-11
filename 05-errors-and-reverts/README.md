# Project 05: Errors & Reverts ⚠️

> **Master error handling and gas-efficient custom errors**

## 🎯 Learning Objectives

- Use `require()`, `revert()`, and `assert()` appropriately
- Implement custom errors (Solidity 0.8.4+)
- Understand gas savings of custom errors vs strings
- Handle error propagation in external calls
- Learn when to use each error type

## 📚 Key Concepts

### Error Types

- **require()**: Input validation, refunds gas
- **revert()**: Conditional revert with custom logic
- **assert()**: Invariant checks, no gas refund
- **Custom errors**: Gas-efficient, structured errors

### Gas Comparison

```solidity
// Old way: ~2,000 gas overhead
require(balance >= amount, "Insufficient balance");

// New way: ~200 gas overhead (90% savings!)
if (balance < amount) revert InsufficientBalance(balance, amount);
```

## 🔧 What You'll Build

A contract demonstrating:
- All error types in appropriate contexts
- Custom errors with parameters
- Error handling patterns
- Gas benchmarking

## ✅ Status

🚧 **Scaffold** - Complete Projects 01-04 first

## 🚀 Next Steps

After completing this project:
- Move to [Project 06: Mappings, Arrays & Gas](../06-mappings-arrays-and-gas/)
