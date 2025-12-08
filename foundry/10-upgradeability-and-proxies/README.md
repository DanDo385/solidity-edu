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

### Delegatecall Pattern: Code Execution in Foreign Context

**FIRST PRINCIPLES: Context Preservation**

`delegatecall` executes code from another contract in the context of the current contract. This is the magic behind proxy patterns!

**CONNECTION TO PROJECT 02**:
We learned about `.call()` in Project 02 for ETH transfers. `delegatecall` is similar but preserves the calling contract's context!

**UNDERSTANDING THE DIFFERENCE**:

```solidity
// Regular call: Executes in target's context
target.call(data);
// - Uses target's storage
// - Uses target's balance
// - msg.sender = current contract

// Delegatecall: Executes in current contract's context
target.delegatecall(data);
// - Uses CURRENT contract's storage ✅
// - Uses CURRENT contract's balance ✅
// - msg.sender = original caller ✅
```

**HOW IT WORKS**:

```
Delegatecall Execution Flow:
┌─────────────────────────────────────────┐
│ Proxy contract calls                     │
│   implementation.delegatecall(data)      │
│   ↓                                      │
│ Implementation's code executes          │ ← Code from implementation
│   ↓                                      │
│ BUT: Uses proxy's storage!              │ ← Storage from proxy
│   ↓                                      │
│ BUT: Uses proxy's balance!              │ ← Balance from proxy
│   ↓                                      │
│ BUT: msg.sender = original caller!      │ ← Context preserved
│   ↓                                      │
│ State changes affect PROXY, not impl!   │ ← Key insight!
└─────────────────────────────────────────┘
```

**STORAGE LAYOUT CRITICAL** (from Project 01 knowledge):

**The Problem**: Implementation's storage layout must match proxy's!
```solidity
// Implementation V1
contract ImplV1 {
    uint256 public value;  // Slot 0
}

// Proxy
contract Proxy {
    address public implementation;  // Slot 0 ❌ COLLISION!
    // Implementation's value would overwrite implementation address!
}
```

**The Solution**: Use EIP-1967 storage slots!
```solidity
// Proxy uses specific slot for implementation
bytes32 private constant IMPLEMENTATION_SLOT = 
    bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
// Implementation's storage starts at slot 0
```

**GAS COST BREAKDOWN**:

**Delegatecall**:
- Base call: ~2,100 gas
- Code execution: Variable (depends on implementation)
- Storage operations: Same as regular calls (~5k-20k per write)

**COMPARISON TO RUST** (Conceptual):

**Rust** (similar pattern with traits):
```rust
trait Implementation {
    fn execute(&mut self, data: Vec<u8>);
}

struct Proxy {
    implementation: Box<dyn Implementation>,
    storage: Storage,
}

impl Proxy {
    fn delegate_call(&mut self, data: Vec<u8>) {
        // Execute implementation's code
        // But use proxy's storage
        self.implementation.execute(data);
    }
}
```

**Solidity** (delegatecall):
```solidity
function delegatecall(address impl, bytes memory data) {
    impl.delegatecall(data);  // Code from impl, storage from this
}
```

Both preserve context, but Solidity's delegatecall is built into the EVM!

**REAL-WORLD ANALOGY**: 
Like hiring a consultant:
- **Regular call**: Consultant works in their office (target's storage)
- **Delegatecall**: Consultant works in YOUR office (your storage), uses YOUR resources, but brings THEIR expertise (code)

**SECURITY CONSIDERATION**:
Delegatecall is powerful but dangerous - malicious implementation code can corrupt proxy storage if storage layout doesn't match!

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
### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/UpgradeableProxySolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployUpgradeableProxySolution.s.sol` - Deployment script patterns
- `test/solution/UpgradeableProxySolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains delegation pattern, storage layout separation, fallback functions
- **Connections to Project 01**: EIP-1967 storage slots (keccak256-based, like mappings)
- **Connections to Project 02**: delegatecall (executes code in proxy's context)
- **Connections to Project 04**: Access control for upgrades
- **Real-World Context**: Enables bug fixes and upgrades without losing state or user funds

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
