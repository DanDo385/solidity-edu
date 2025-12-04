# Project 10: Upgradeability & Proxies 🔄

> **Master proxy patterns and upgradeable contracts**

## 🎯 Learning Objectives

By completing this project, you will:

1. **Understand contract immutability** and its limitations
2. **Implement UUPS proxy pattern** (Universal Upgradeable Proxy Standard)
3. **Master delegatecall** and how it works
4. **Avoid storage collision bugs** in upgradeable contracts
5. **Use EIP-1967 storage slots** correctly
6. **Understand initialization patterns** vs constructors
7. **Recognize risks** of upgradeability
8. **Create Foundry deployment scripts** for proxy contracts
9. **Write comprehensive test suites** for upgrade scenarios

## 📁 Project Directory Structure

```
10-upgradeability-and-proxies/
├── README.md                          # This file
├── foundry.toml                       # Foundry configuration
├── src/
│   ├── UpgradeableProxy.sol          # Skeleton contract (TODO: implement)
│   └── solution/
│       └── UpgradeableProxySolution.sol  # Complete reference implementation
├── script/
│   ├── DeployUpgradeableProxy.s.sol  # Deployment script (TODO: implement)
│   └── solution/
│       └── DeployUpgradeableProxySolution.s.sol  # Reference deployment
└── test/
    ├── UpgradeableProxy.t.sol        # Test suite (TODO: implement)
    └── solution/
        └── UpgradeableProxySolution.t.sol  # Reference tests
```

## 🔑 Key Concepts

### Why Proxies?

Smart contracts are immutable by default:
- Cannot change code after deployment
- Bugs are permanent
- Feature additions impossible
- Security patches require redeployment

**Proxies enable upgradeability:**
- Separate logic (implementation) from state (proxy)
- Proxy delegates calls to implementation
- Can swap implementation while preserving state
- State stays in proxy, logic can be upgraded

**Real-world analogy**: Like a building with replaceable wiring - the building (proxy/state) stays the same, but you can upgrade the electrical system (implementation/logic)!

### Delegatecall Pattern

`delegatecall` executes code from another contract in the context of the current contract:

```solidity
delegatecall(target, data)
// Executes target's code, but:
// - Uses current contract's storage
// - Uses current contract's balance
// - Uses current contract's address (msg.sender)
```

**Key difference from `call`:**
- `call`: Executes in target's context
- `delegatecall`: Executes in current contract's context

**Real-world analogy**: Like hiring a consultant - they use your office (storage), your resources (balance), but bring their expertise (code)!

### UUPS Proxy Pattern

UUPS (Universal Upgradeable Proxy Standard) stores implementation address in a specific storage slot:

```solidity
bytes32 private constant IMPLEMENTATION_SLOT = 
    bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
```

**How it works:**
1. Proxy contract stores implementation address
2. Fallback function delegates all calls to implementation
3. Implementation can be upgraded (if authorized)
4. State remains in proxy contract

### Storage Collisions (CRITICAL!)

⚠️ **The biggest risk in proxy patterns:**

```solidity
// Implementation V1
contract ImplementationV1 {
    uint256 public value;  // Slot 0
}

// Implementation V2 - WRONG! Storage collision!
contract ImplementationV2 {
    address public owner;  // Slot 0 - COLLISION!
    uint256 public value;  // Now in slot 1 - WRONG!
}
```

**Problem:** If you change storage layout, old data gets corrupted!

**Solution:** Use EIP-1967 storage slots and never change storage layout order.

### EIP-1967 Storage Slots

EIP-1967 defines standard storage slots for proxy patterns:

```solidity
// Implementation address slot
bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)

// Admin address slot
bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1)
```

**Why these slots?**
- Unlikely to collide with implementation storage
- Standardized across all proxy implementations
- Tools can read these slots easily

## 🏗️ What You'll Build

A complete UUPS proxy implementation that includes:

1. **Proxy contract** with delegatecall fallback
2. **EIP-1967 storage slots** for implementation and admin
3. **Implementation contracts** (V1 and V2)
4. **Upgrade mechanism** (if implementing UUPS fully)
5. **Storage collision prevention** patterns

## 📋 Tasks

### 1. Implement Proxy Contract
- Store implementation address in EIP-1967 slot
- Store admin address in EIP-1967 slot
- Implement fallback with delegatecall
- Handle return data correctly

### 2. Implement Implementation Contracts
- Create V1 implementation
- Create V2 implementation (with new features)
- Maintain storage layout compatibility

### 3. Write Deployment Script
- Deploy implementation contracts
- Deploy proxy contract
- Initialize proxy with implementation
- Test upgrade scenario

### 4. Write Comprehensive Tests
- Test proxy delegation works
- Test storage persistence across upgrades
- Test upgrade functionality
- Test storage collision scenarios
- Test edge cases

## 🧪 Test Coverage

Your tests should verify:

- ✅ Proxy delegates calls correctly
- ✅ State persists across upgrades
- ✅ Storage layout compatibility
- ✅ Upgrade functionality works
- ✅ Admin controls upgrade
- ✅ Edge cases handled

## 🎓 Real-World Analogies & Fun Facts

### Building Analogy
- **Proxy** = Building structure (permanent)
- **Implementation** = Electrical system (upgradeable)
- **State** = Furniture (stays in building)
- **Upgrade** = Replacing electrical system

### Delegatecall Analogy
- **call** = Hiring contractor at their office
- **delegatecall** = Hiring contractor at your office
- Both use contractor's expertise, but different contexts!

### Fun Facts
- Most DeFi protocols use upgradeable proxies
- Uniswap V2 → V3 used proxy pattern
- Storage collisions have caused major hacks
- EIP-1967 standardizes proxy storage slots
- OpenZeppelin provides battle-tested proxy contracts

## ✅ Completion Checklist

- [ ] Implement proxy contract with EIP-1967 slots
- [ ] Implement delegatecall fallback
- [ ] Create V1 implementation contract
- [ ] Create V2 implementation contract
- [ ] Ensure storage layout compatibility
- [ ] Write deployment script
- [ ] Write comprehensive test suite
- [ ] Test upgrade scenarios
- [ ] Understand storage collision risks
- [ ] Review solution implementation

## 💡 Pro Tips

1. **Never change storage layout order**: Add new variables at the end only
2. **Use EIP-1967 slots**: Prevents collisions with implementation storage
3. **Test upgrades thoroughly**: Storage collisions are hard to detect
4. **Use OpenZeppelin**: Battle-tested proxy contracts
5. **Understand delegatecall**: Critical for proxy patterns
6. **Initialize properly**: Use initializer instead of constructor
7. **Document storage layout**: Helps prevent collisions

## 🚀 Next Steps

After completing this project:

- Move to [Project 11: ERC-4626 Tokenized Vault](../11-ERC4626-tokenized-vault/)
- Study OpenZeppelin upgradeable contracts
- Understand transparent vs UUPS patterns
- Learn about initialization vs constructors
- Explore proxy admin patterns
