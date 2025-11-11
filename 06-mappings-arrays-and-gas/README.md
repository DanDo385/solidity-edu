# Project 06: Mappings, Arrays & Gas ⛽

> **Deep dive into storage structures and gas optimization**

## 🎯 Learning Objectives

- Understand storage slot hashing for mappings
- Analyze iteration costs for arrays
- Recognize DoS vectors in unbounded loops
- Implement gas-optimized data structures

## 📚 Key Concepts

### Mapping Storage

```solidity
mapping(address => uint256) balances;  // Slot 0
// Storage location: keccak256(abi.encodePacked(key, 0))
```

### Array Dangers

- Unbounded growth → DoS
- Iteration costs scale linearly
- Consider mappings + events instead

## 📝 Tasks

```bash
cd 06-mappings-arrays-and-gas
forge test --gas-report
forge snapshot
```

## ✅ Status

✅ **Complete** - Ready to learn

## 🚀 Next Steps

- Move to [Project 07: Reentrancy & Security](../07-reentrancy-and-security/)
