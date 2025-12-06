# Project 15: Low-Level Calls

> **Master call(), delegatecall(), staticcall() and understand their dangers**

## 🎯 Learning Objectives

- Understand the three low-level call types
- Learn storage context differences
- Handle return data from low-level calls
- Understand gas forwarding behavior
- Recognize delegatecall storage corruption risks
- Know when to use each call type

## 📚 Key Concepts

### The Three Call Types

**FIRST PRINCIPLES: Context Preservation**

Low-level calls are the foundation of contract interaction. Understanding context (storage, balance, msg.sender) is critical!

**CONNECTION TO PROJECT 02 & 10**:
- **Project 02**: We learned about `.call{value:}()` for ETH transfers
- **Project 10**: We learned about `delegatecall()` for proxies
- **Project 15**: We dive deep into all three call types and their contexts!

#### 1. call() - External Call
Executes code in the **target contract's context**

```solidity
// Storage context: Target contract ✅
// msg.sender: Your contract ✅
// msg.value: Sent value ✅
(bool success, bytes memory data) = target.call{value: 1 ether}(
    abi.encodeWithSignature("someFunction(uint256)", 123)
);
```

**HOW IT WORKS**:
```
Call Execution Flow:
┌─────────────────────────────────────────┐
│ YourContract.call(target, data)         │
│   ↓                                      │
│ Target's code executes                  │ ← Code from target
│   ↓                                      │
│ Uses TARGET's storage                   │ ← Storage from target
│   ↓                                      │
│ Uses TARGET's balance                   │ ← Balance from target
│   ↓                                      │
│ msg.sender = YourContract               │ ← Your contract is sender
│   ↓                                      │
│ Returns (success, data)                 │
└─────────────────────────────────────────┘
```

**Use cases:**
- Calling external contracts
- Sending ETH (from Project 02)
- Interacting with unknown contracts
- Proxy pattern calls

**GAS COST** (from Project 02 knowledge):
- Base call: ~2,100 gas
- Forwarded gas: All remaining (unlike .transfer())
- Return data: Variable (depends on function)

#### 2. delegatecall() - Library Pattern
Executes code in the **caller's context**

```solidity
// Storage context: YOUR contract ⚠️ DANGEROUS!
// msg.sender: Original caller ✅
// msg.value: Original value ✅
(bool success, bytes memory data) = target.delegatecall(
    abi.encodeWithSignature("someFunction(uint256)", 123)
);
```

**HOW IT WORKS**:
```
Delegatecall Execution Flow:
┌─────────────────────────────────────────┐
│ YourContract.delegatecall(target, data) │
│   ↓                                      │
│ Target's code executes                  │ ← Code from target
│   ↓                                      │
│ Uses YOUR storage!                      │ ← Storage from YOUR contract!
│   ↓                                      │
│ Uses YOUR balance!                      │ ← Balance from YOUR contract!
│   ↓                                      │
│ msg.sender = Original caller            │ ← Original caller preserved
│   ↓                                      │
│ State changes affect YOUR contract!     │ ← Key difference!
└─────────────────────────────────────────┘
```

**Use cases:**
- Proxy/implementation pattern (from Project 10)
- Library contracts
- Upgradeable contracts

**⚠️ CRITICAL WARNING**:
- Target code modifies **YOUR** storage
- Storage layout must match **exactly**
- One mistake = complete storage corruption
- Always use EIP-1967 storage slots for proxies!

**STORAGE COLLISION RISK** (from Project 01 & 10 knowledge):

```solidity
// Your Contract
contract YourContract {
    address public owner;      // Slot 0
    uint256 public value;     // Slot 1
}

// Target Contract (WRONG LAYOUT!)
contract Target {
    uint256 public value;     // Slot 0 ❌ COLLISION!
    address public owner;     // Slot 1 ❌ COLLISION!
}

// If you delegatecall Target:
// Target's code writes to slot 0 (thinks it's value)
// But YOUR slot 0 is owner!
// Result: Owner address corrupted! 💥
```

#### 3. staticcall() - Read-Only
Like call() but **reverts on state changes**

```solidity
// Read-only, reverts if target tries to write
(bool success, bytes memory data) = target.staticcall(
    abi.encodeWithSignature("someView()")
);
```

**Use cases:**
- View/pure function calls
- Safe reads from untrusted contracts
- Enforcing read-only behavior

### Storage Context Visualization

```solidity
contract Caller {
    uint256 public value;  // Slot 0

    function useCall(address target) public {
        // Modifies target's slot 0
        target.call(abi.encodeWithSignature("setValue(uint256)", 42));
    }

    function useDelegateCall(address target) public {
        // Modifies Caller's slot 0 (OUR value!)
        target.delegatecall(abi.encodeWithSignature("setValue(uint256)", 42));
    }
}

contract Target {
    uint256 public value;  // Slot 0

    function setValue(uint256 _value) public {
        value = _value;  // Which slot 0 gets modified?
    }
}
```

### Return Data Handling

Low-level calls return `(bool success, bytes memory data)`:

```solidity
(bool success, bytes memory data) = target.call(...);

if (success) {
    // Decode return data
    uint256 result = abi.decode(data, (uint256));
} else {
    // Handle failure
    if (data.length > 0) {
        // Bubble up error message
        assembly {
            revert(add(data, 32), mload(data))
        }
    }
}
```

### Gas Forwarding

By default, low-level calls forward all remaining gas:

```solidity
// Forwards all gas
target.call(data);

// Limit gas
target.call{gas: 10000}(data);
```

**⚠️ Warning:** Be careful with gas limits to avoid:
- Griefing attacks
- Unexpected reverts
- EIP-150 (63/64 rule)

### The Delegatecall Storage Corruption Problem

**The most dangerous aspect of delegatecall:**

```solidity
contract Proxy {
    address public implementation;  // Slot 0
    address public owner;          // Slot 1

    function upgrade(address newImpl) public {
        // DANGER: If newImpl has different storage layout...
        implementation.delegatecall(
            abi.encodeWithSignature("someFunction()")
        );
    }
}

contract MaliciousImpl {
    address public owner;  // Slot 0 - MISALIGNED!

    function someFunction() public {
        owner = msg.sender;  // Overwrites Proxy's implementation!
    }
}
```

**Result:** Complete takeover of proxy contract!

### When to Use Each

| Type | Use When | Risk Level |
|------|----------|-----------|
| `call()` | Calling external contracts, sending ETH | Low (if checked) |
| `delegatecall()` | Proxy patterns, libraries | **CRITICAL** |
| `staticcall()` | Read-only operations | Very Low |

## 🔒 Security Best Practices

### 1. Always Check Return Values
```solidity
// ❌ UNSAFE
target.call(data);

// ✅ SAFE
(bool success,) = target.call(data);
require(success, "Call failed");
```

### 2. Handle Return Data Properly
```solidity
(bool success, bytes memory data) = target.call(data);
if (!success) {
    // Bubble up the error
    assembly {
        revert(add(data, 32), mload(data))
    }
}
```

### 3. Delegatecall Storage Alignment
```solidity
// Both contracts must have IDENTICAL storage layout
contract Proxy {
    address public implementation;  // Slot 0
    address public owner;          // Slot 1
}

contract Implementation {
    address public implementation;  // Slot 0 - MUST MATCH!
    address public owner;          // Slot 1 - MUST MATCH!
    // ... additional storage OK
}
```

### 4. Use staticcall() for Untrusted Views
```solidity
// Safe even if target is malicious
(bool success, bytes memory data) = untrustedContract.staticcall(
    abi.encodeWithSignature("balanceOf(address)", user)
);
```

## 📝 Tasks

```bash
cd 15-low-level-calls
forge test -vvv
```

### Exercises

1. Implement basic call() with return data decoding
2. Demonstrate delegatecall() storage context
3. Show staticcall() reverting on state changes
4. Create a storage corruption example
5. Build proper error bubbling

## 🧪 Testing Focus

- Call success/failure scenarios
- Delegatecall storage corruption demonstration
- Staticcall enforcement
- Gas forwarding behavior
- Return data decoding
- Error bubbling

## 🚨 Common Pitfalls

1. **Ignoring return values** - Always check success
2. **Wrong storage layout** - Delegatecall disaster
3. **Gas griefing** - Limit gas for external calls
4. **Error handling** - Bubble up errors properly
5. **Type confusion** - Decode return data correctly

## 📖 Real-World Examples

### Proxy Patterns (Delegatecall)
- OpenZeppelin Proxies
- UUPS (ERC-1822)
- Transparent Proxy Pattern
- Diamond Pattern (EIP-2535)

### Call Examples
- Token transfers
- Multi-sig wallets
- Payment splitters
- Meta-transactions

### Security Incidents
- Parity Wallet Hack (delegatecall)
- Storage collision bugs
- Re-entrancy via call()

## 🎓 Advanced Topics

- Assembly-level calls
- EIP-150 gas forwarding rules
- Return data size attacks
- Cross-contract re-entrancy
- EIP-1967 storage slots

## ✅ Status

⚠️ **CRITICAL SECURITY TOPIC** - Understand thoroughly before using!

## 🚀 Next Steps

- Study OpenZeppelin proxy implementations
- Review EIP-1967 (Proxy Storage Slots)
- Understand EIP-2535 (Diamond Standard)
- Practice safe delegatecall patterns
- Learn about minimal proxies (EIP-1167)

## 📚 Additional Resources

- [Solidity Docs: Low-Level Calls](https://docs.soliditylang.org/en/latest/units-and-global-variables.html#members-of-address-types)
- [OpenZeppelin Proxy Documentation](https://docs.openzeppelin.com/contracts/4.x/api/proxy)
- [EIP-1967: Standard Proxy Storage Slots](https://eips.ethereum.org/EIPS/eip-1967)
- [Storage Collision Attacks](https://blog.openzeppelin.com/proxy-patterns)
