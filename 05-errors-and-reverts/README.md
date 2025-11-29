# Project 05: Errors & Reverts ⚠️

> **Master error handling and gas-efficient custom errors**

## 🎯 Learning Objectives

- Use `require()`, `revert()`, and `assert()` appropriately
- Implement custom errors (Solidity 0.8.4+)
- Understand gas savings (~90%) of custom errors
- Handle error propagation in external calls
- Learn when to use each error type
- Connect revert design to fork history, compiler choices, and gas economics

## 📚 Key Concepts

### Custom Errors Save Gas

```solidity
// Old: ~2,000 gas
require(balance >= amount, "Insufficient balance");

// New: ~200 gas (90% savings!)
if (balance < amount) revert InsufficientBalance(balance, amount);
```

**Fun fact**: Before Solidity 0.4.22, `throw` reverted without data. Modern `revert` opcodes bubble encoded error data, which explorers and off-chain services can parse for better UX.

Custom errors shine on L2s: fewer bytes in revert strings means smaller calldata when transactions revert during optimistic rollup dispute games.

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

## 🛰️ Real-World Analogies & Fun Facts

- **Airplane checklists**: `require` is the preflight checklist; if anything is missing, you stop before takeoff. `assert` is the “wing still attached” invariant—if it fails, something is fundamentally wrong.
- **Compiler trivia**: Solc emits `REVERT` with ABI-encoded selectors for custom errors, letting frontends decode human-friendly reasons without inflating bytecode with strings.
- **DAO/ETC lesson**: The DAO fork highlighted how clear error surfaces speed up incident response. Ethereum Classic retained the old state; explicit errors made replay analysis easier across chains.
- **ETH inflation angle**: Reverting early prevents wasted gas and failed state writes. Less wasted execution → less pressure for higher base fees → less need for elevated issuance to pay validators.
- **Layer 2**: Short custom errors reduce calldata, which directly lowers fees on rollups and keeps fraud proofs cheaper to verify.
