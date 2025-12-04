# Project 35: Delegatecall Storage Corruption

Learn about one of the most dangerous vulnerabilities in Solidity - delegatecall storage corruption. This project explores how improper use of delegatecall can lead to complete contract takeover.

## Overview

Delegatecall is a powerful feature in Solidity that allows a contract to execute code from another contract while maintaining its own storage context. However, when used incorrectly, it can lead to severe storage corruption vulnerabilities.

## How Delegatecall Works

### Normal Call vs Delegatecall

**Normal Call (`call`)**:
- Executes code in the target contract's context
- Uses target contract's storage
- `msg.sender` is the calling contract
- Storage changes affect the target contract

**Delegatecall (`delegatecall`)**:
- Executes target contract's code in the calling contract's context
- Uses calling contract's storage
- Preserves original `msg.sender` and `msg.value`
- Storage changes affect the calling contract

### Visual Representation

```
Contract A calls Contract B with delegatecall:

┌─────────────────┐
│   Contract A    │
│                 │
│  Storage:       │
│  slot 0: value1 │
│  slot 1: value2 │
│                 │
│  delegatecall   │────┐
│  to Contract B  │    │
└─────────────────┘    │
                       │
                       │ Executes B's code
                       │ but modifies A's storage
                       │
                       ▼
              ┌─────────────────┐
              │   Contract B    │
              │                 │
              │  Code:          │
              │  function f() { │
              │    slot0 = x;   │
              │    slot1 = y;   │
              │  }              │
              └─────────────────┘
```

## Storage Layout in Solidity

Solidity stores state variables in sequential storage slots (each 32 bytes):

```solidity
contract Example {
    uint256 public value;      // slot 0
    address public owner;      // slot 1
    bool public initialized;   // slot 2 (packed with other small types)
}
```

**Critical Rule**: When using delegatecall, the storage layout of both contracts must match exactly, or storage corruption will occur.

## Storage Collision Vulnerabilities

### The Problem

When a proxy contract uses delegatecall to an implementation contract with mismatched storage layouts, the implementation's code will read/write to the wrong storage slots in the proxy.

### Example of Storage Corruption

```solidity
// Proxy Contract
contract VulnerableProxy {
    address public implementation;  // slot 0
    address public owner;           // slot 1

    function upgrade(address _impl) external {
        require(msg.sender == owner);
        implementation = _impl;
    }

    fallback() external {
        address impl = implementation;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}

// Implementation Contract (Wrong Storage Layout!)
contract MaliciousImplementation {
    uint256 public value;       // slot 0 (maps to proxy's implementation!)
    address public owner;       // slot 1 (maps to proxy's owner!)

    function setValue(uint256 _value) external {
        value = _value;  // This writes to proxy's implementation slot!
    }

    function takeOwnership() external {
        owner = msg.sender;  // This writes to proxy's owner slot!
    }
}
```

**Attack Flow**:
1. Attacker calls `takeOwnership()` via proxy's fallback
2. Code executes in proxy's context
3. `owner = msg.sender` writes to slot 1 of proxy
4. Attacker becomes owner of proxy
5. Attacker can now upgrade to any implementation

## The Parity Wallet Hack (July 2017)

The Parity multisig wallet vulnerability is one of the most famous delegatecall exploits.

### What Happened

**Setup**:
- Parity wallet contracts used a library pattern
- Wallet contract used delegatecall to WalletLibrary
- Both had `owner` variables but in different storage positions

**The Vulnerability**:
```solidity
contract WalletLibrary {
    address public owner;

    function initWallet(address _owner) public {
        owner = _owner;  // Anyone could call this!
    }
}

contract Wallet {
    address public walletLibrary;

    fallback() external payable {
        address _impl = walletLibrary;
        assembly {
            // delegatecall to library
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
```

**The Attack**:
1. Attacker called `initWallet()` through the wallet's fallback
2. Due to delegatecall, `owner` was set in the wallet's storage
3. Attacker became owner of the wallet
4. Attacker drained ~$30M worth of ETH from affected wallets

### Second Parity Hack (November 2017)

A developer accidentally called `kill()` on the shared WalletLibrary contract, destroying it and freezing $150M+ in ETH across hundreds of wallets that depended on it.

## Safe Proxy Patterns

### EIP-1967: Standard Proxy Storage Slots

To avoid storage collisions, EIP-1967 defines specific storage slots for proxy data using pseudo-random positions:

```solidity
// Implementation slot: keccak256("eip1967.proxy.implementation") - 1
bytes32 constant IMPLEMENTATION_SLOT =
    0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

// Admin slot: keccak256("eip1967.proxy.admin") - 1
bytes32 constant ADMIN_SLOT =
    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
```

These slots are computed to avoid collision with normal storage layout:
- Normal storage uses slots 0, 1, 2, ...
- EIP-1967 uses keccak256 hash - 1 (extremely unlikely to collide)

### Safe Proxy Implementation

```solidity
contract SafeProxy {
    bytes32 constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 constant ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    constructor(address _implementation, address _admin) {
        _setImplementation(_implementation);
        _setAdmin(_admin);
    }

    function _setImplementation(address _implementation) private {
        assembly {
            sstore(IMPLEMENTATION_SLOT, _implementation)
        }
    }

    function _setAdmin(address _admin) private {
        assembly {
            sstore(ADMIN_SLOT, _admin)
        }
    }

    function _getImplementation() private view returns (address impl) {
        assembly {
            impl := sload(IMPLEMENTATION_SLOT)
        }
    }

    function _getAdmin() private view returns (address admin) {
        assembly {
            admin := sload(ADMIN_SLOT)
        }
    }

    function upgradeTo(address _newImplementation) external {
        require(msg.sender == _getAdmin(), "Not admin");
        _setImplementation(_newImplementation);
    }

    fallback() external payable {
        address impl = _getImplementation();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
```

### Implementation Contract Rules

When writing implementation contracts for proxies:

1. **Never use constructor** - use `initialize()` instead
2. **Match storage layout** - or use EIP-1967 slots
3. **Use storage gaps** - for upgradeability
4. **Avoid `selfdestruct`** - can break proxy
5. **Be careful with delegatecall** - in implementation

```solidity
contract SafeImplementation {
    // Match proxy's storage layout or use unstructured storage

    uint256[50] private __gap;  // Reserve space for future variables

    uint256 public value;
    address public owner;
    bool private initialized;

    function initialize(address _owner) external {
        require(!initialized, "Already initialized");
        owner = _owner;
        initialized = true;
    }

    function setValue(uint256 _value) external {
        require(msg.sender == owner, "Not owner");
        value = _value;
    }
}
```

## Storage Slot Calculations

### Sequential Storage

```solidity
contract Storage {
    uint256 a;      // slot 0
    uint256 b;      // slot 1
    address c;      // slot 2
    bool d;         // slot 3 (or packed with c)
    uint256 e;      // slot 3 or 4
}
```

### Packing Rules

Solidity packs variables < 32 bytes:

```solidity
contract Packed {
    uint128 a;      // slot 0 (first 16 bytes)
    uint128 b;      // slot 0 (last 16 bytes)
    address c;      // slot 1 (20 bytes)
    uint96 d;       // slot 1 (12 bytes) - packed with c!
    uint256 e;      // slot 2 (needs full slot)
}
```

### Mappings and Arrays

```solidity
contract Complex {
    uint256 a;                          // slot 0
    mapping(address => uint256) balances;  // slot 1 (only stores position)
    uint256[] items;                    // slot 2 (only stores length)
}

// Mapping storage: keccak256(abi.encode(key, slot))
// For balances[addr]: keccak256(abi.encode(addr, 1))

// Dynamic array storage:
// Length at slot 2
// Elements at keccak256(abi.encode(2)) + index
```

### Computed Slots (EIP-1967)

```typescript
// Implementation slot
const implSlot: bigint = BigInt(keccak256("eip1967.proxy.implementation")) - 1n;
// = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc

// Admin slot
const adminSlot: bigint = BigInt(keccak256("eip1967.proxy.admin")) - 1n;
// = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
```

## Common Vulnerabilities

### 1. Storage Collision
- **Problem**: Proxy and implementation have different storage layouts
- **Impact**: Implementation corrupts proxy storage
- **Solution**: Use EIP-1967 or match layouts exactly

### 2. Uninitialized Proxy
- **Problem**: Delegatecall to uninitialized implementation address
- **Impact**: Attacker can set implementation
- **Solution**: Initialize in constructor

### 3. Missing Access Control
- **Problem**: Anyone can call initialize/upgrade functions
- **Impact**: Attacker takes control
- **Solution**: Proper access control on sensitive functions

### 4. Function Selector Collision
- **Problem**: Proxy and implementation have same function signatures
- **Impact**: Proxy functions can't be called
- **Solution**: Use transparent proxy pattern

## Learning Objectives

By completing this project, you will:

1. Understand how delegatecall works at the storage level
2. Identify storage collision vulnerabilities
3. Exploit storage corruption to take over contracts
4. Implement safe proxy patterns using EIP-1967
5. Calculate storage slots for different variable types
6. Understand the Parity wallet hack
7. Write secure upgradeable contracts

## Tasks

### Part 1: Vulnerable Proxy
1. Study the VulnerableProxy contract
2. Identify storage collision points
3. Implement attack to become owner
4. Upgrade to malicious implementation

### Part 2: Safe Proxy
1. Implement EIP-1967 proxy pattern
2. Use unstructured storage slots
3. Add proper access control
4. Test upgrade mechanism

### Part 3: Storage Analysis
1. Calculate storage slots manually
2. Verify with foundry's `vm.load()`
3. Understand storage packing
4. Map proxy to implementation slots

## Security Best Practices

1. **Use OpenZeppelin's Proxy Contracts**
   - Battle-tested implementations
   - Proper storage patterns
   - Transparent and UUPS patterns

2. **Follow EIP-1967**
   - Use standard storage slots
   - Avoid collision with sequential storage
   - Document storage layout

3. **Initialize Carefully**
   - Use initializer modifier
   - Prevent re-initialization
   - Set critical values immediately

4. **Audit Storage Layout**
   - Document all state variables
   - Use storage gaps for upgradeability
   - Test storage positions

5. **Restrict Delegatecall**
   - Only to trusted implementations
   - With proper access control
   - Never to user-supplied addresses

## Testing Commands

```bash
# Run all tests
forge test --match-path test/Project35.t.sol -vvv

# Test specific vulnerability
forge test --match-test testStorageCorruption -vvvv

# Check storage layout
forge inspect Project35 storage-layout

# Deploy
forge script script/DeployProject35.s.sol --rpc-url $RPC_URL --broadcast
```

## References

- [EIP-1967: Standard Proxy Storage Slots](https://eips.ethereum.org/EIPS/eip-1967)
- [Parity Wallet Hack Explained](https://blog.openzeppelin.com/on-the-parity-wallet-multisig-hack-405a8c12e8f7)
- [OpenZeppelin Proxy Documentation](https://docs.openzeppelin.com/contracts/4.x/api/proxy)
- [Solidity Storage Layout](https://docs.soliditylang.org/en/latest/internals/layout_in_storage.html)
- [Delegatecall Vulnerabilities](https://blog.sigmaprime.io/solidity-security.html#delegatecall)

## Additional Resources

- [Writing Upgradeable Contracts](https://docs.openzeppelin.com/upgrades-plugins/writing-upgradeable)
- [Proxy Patterns Comparison](https://blog.openzeppelin.com/the-state-of-smart-contract-upgrades)
- [Storage Collision Analysis Tool](https://github.com/ItsNickBarry/hardhat-storage-layout)

---

**⚠️ Warning**: This project is for educational purposes only. Never use vulnerable proxy patterns in production. Always use well-audited libraries like OpenZeppelin for proxy implementations.
