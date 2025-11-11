# Project 06: Mappings, Arrays & Gas ⛽

> **Deep dive into storage structures and gas optimization**

## 🎯 Learning Objectives

- Understand storage slot hashing for mappings
- Analyze iteration costs for arrays
- Recognize DoS vectors in unbounded loops
- Implement gas-optimized data structures
- Choose between mappings and arrays appropriately

## 📚 Key Concepts

### Mapping Storage

```solidity
mapping(address => uint256) balances;  // Slot 0
// Actual storage: keccak256(abi.encodePacked(key, 0))
```

- O(1) access
- No iteration possible
- Conceptually infinite size

### Array Risks

- Unbounded growth → DoS
- Iteration costs scale linearly
- Consider mappings + events instead

## 🔧 What You'll Build

A contract demonstrating:
- Storage slot calculations
- Array vs mapping trade-offs
- Gas optimization techniques
- DoS prevention patterns

## ✅ Status

🚧 **Scaffold** - Complete Projects 01-05 first

## 🚀 Next Steps

After completing this project:
- Move to [Project 07: Reentrancy & Security](../07-reentrancy-and-security/)
