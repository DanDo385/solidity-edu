# Project 05: Errors & Reverts ⚠️

> **Master error handling and gas-efficient custom errors**

## 🎯 Learning Objectives

- Use `require()`, `revert()`, and `assert()` appropriately
- Implement custom errors (Solidity 0.8.4+)
- Understand gas savings (~90%) of custom errors
- Handle error propagation in external calls
- Learn when to use each error type

## 📚 Key Concepts

### Custom Errors Save Gas

```solidity
// Old: ~2,000 gas
require(balance >= amount, "Insufficient balance");

// New: ~200 gas (90% savings!)
if (balance < amount) revert InsufficientBalance(balance, amount);
```

## 📝 Tasks

```bash
cd 05-errors-and-reverts
forge test -vvv
forge test --gas-report
```

## ✅ Status

✅ **Complete** - Ready to learn

## 🚀 Next Steps

- Move to [Project 06: Mappings, Arrays & Gas](../06-mappings-arrays-and-gas/)
