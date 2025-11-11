# Project 10: Upgradeability & Proxies 🔄

> **Understand proxy patterns and upgradeable contracts**

## 🎯 Learning Objectives

- Understand contract immutability limitations
- Implement UUPS (Universal Upgradeable Proxy Standard)
- Avoid storage collision bugs
- Use EIP-1967 storage slots correctly
- Understand risks of upgradeability

## 📚 Key Concepts

### Why Proxies?

Smart contracts are immutable:
- Cannot change code after deployment
- Bugs are permanent
- Feature additions impossible

Proxies enable upgradeability:
- Separate logic (implementation) from state (proxy)
- Proxy delegates calls to implementation
- Can swap implementation while preserving state

### Storage Collisions

The biggest risk in proxy patterns:

```solidity
// Implementation V1
contract ImplementationV1 {
    uint256 public value;  // Slot 0
}

// Implementation V2 - WRONG!
contract ImplementationV2 {
    address public owner;  // Slot 0 collision!
    uint256 public value;  // Now in slot 1
}
```

Use EIP-1967 storage slots to avoid collisions.

## 📝 Tasks

```bash
cd 10-upgradeability-and-proxies
forge test -vvv
```

## ✅ Status

✅ **Complete** - Advanced pattern!

## 🚀 Next Steps

- Move to [Project 11: ERC-4626 Tokenized Vault](../11-ERC4626-tokenized-vault/)
- Study OpenZeppelin upgradeable contracts
- Understand transparent vs UUPS patterns
- Learn about initialization vs constructors
