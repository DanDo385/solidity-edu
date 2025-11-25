# Project 01: Datatypes & Storage

> **Master Solidity's type system and understand where your data lives**

## Learning Objectives

By completing this project, you will:

1. **Understand Solidity's static type system** and why it exists
2. **Distinguish between value types and reference types**
3. **Master data locations**: `storage`, `memory`, and `calldata`
4. **Analyze gas costs** of different data structures
5. **Explain storage layout** and slot allocation
6. **Compare** Solidity's approach with TypeScript, Go, and Rust

## Why This Matters

**Python**: You can write `x = 42` then reassign `x = "hello"`. Types are dynamic.
**Solidity**: You must declare `uint256 x = 42` and can *never* assign a string to `x`. Types are static and immutable.

**Why?** The EVM (Ethereum Virtual Machine) requires:
- **Deterministic memory layout**: Every node must compute the same storage slots
- **Gas predictability**: Type sizes determine computational costs
- **Security**: Type confusion can lead to vulnerabilities

This is similar to Rust (safety through types) and Go (explicit types), but stricter than both because blockchain state must be deterministically reproducible.

## Background: The EVM Storage Model

### Storage Slots (256-bit)

Every contract has 2^256 storage slots, each 256 bits (32 bytes):

```
Slot 0: [32 bytes]
Slot 1: [32 bytes]
Slot 2: [32 bytes]
...
```

**Reading/writing storage is expensive**:
- Cold read: 2,100 gas
- Warm read: 100 gas
- Write (zero ? non-zero): 20,000 gas
- Write (non-zero ? non-zero): 5,000 gas

**Compare to memory**: 3 gas per 32-byte word

### Why Data Locations Matter

```solidity
uint256 public storageVar;  // Lives forever, expensive (~20k gas to write)

function temp(uint256[] memory arr) public {
    // 'arr' is temporary, erased after function exits
    // Costs ~3 gas per word to allocate
}
```

## What You'll Build

A contract demonstrating:
- ✅ All major Solidity datatypes
- ✅ Storage vs memory vs calldata differences
- ✅ Gas-efficient struct packing
- ✅ Mapping usage patterns
- ✅ Array operations and costs

## Tasks

### Task 1: Implement the Skeleton Contract

Open `src/DatatypesStorage.sol` and implement:

1. **State variables** for each datatype
2. **Functions** to manipulate mappings and arrays
3. **Getters** that demonstrate data location keywords
4. **Struct packing** to minimize gas costs

### Task 2: Study the Solution

Compare your implementation with `src/solution/DatatypesStorageSolution.sol`:
- Read the extensive inline documentation
- Understand *why* each line is written that way
- Note the gas optimization comments

### Task 3: Run Tests

```bash
# Navigate to this project
cd 01-datatypes-and-storage

# Run tests
forge test

# Run with verbose output
forge test -vvv

# Run with gas reporting
forge test --gas-report
```

All tests in `test/DatatypesStorage.t.sol` should pass.

### Task 4: Experiment

Try these experiments to deepen understanding:

```bash
# Gas snapshot (record baseline)
forge snapshot

# Modify contract, then compare
forge snapshot --diff
```

**Experiments**:
1. Change `uint256` to `uint128` in a struct - how does gas change?
2. Add a third mapping - where does it get stored?
3. Use `storage` instead of `memory` for an array - what breaks?

## Test Coverage

The test suite covers:

- ✅ Setting and getting values
- ✅ Mapping operations (set, get, exists)
- ✅ Array operations (push, pop, access)
- ✅ Struct operations and packing
- ✅ Data location behavior (memory vs storage)
- ✅ Gas comparisons for different approaches

## Key Concepts

### Value Types (Copied When Assigned)

```solidity
uint256 a = 10;
uint256 b = a;  // 'b' is a COPY, not a reference
b = 20;         // 'a' is still 10
```

**Examples**: `uint`, `int`, `bool`, `address`, `bytes32`, `enum`

### Reference Types (Assigned by Reference)

```solidity
uint[] storage arr1 = myArray;  // 'arr1' points to myArray
uint[] memory arr2 = arr1;      // 'arr2' is a COPY in memory
arr1.push(5);                   // Changes storage
arr2.push(5);                   // Only changes memory copy
```

**Examples**: `array`, `struct`, `mapping` (storage only)

### Data Location Rules

| Type | Storage | Memory | Calldata |
|------|---------|--------|----------|
| State variables | ✅ (default) | ❌ | ❌ |
| Function parameters | ✅ (internal) | ✅ | ✅ (external) |
| Local variables (reference types) | ✅ | ✅ | ❌ |
| Return values | ❌ | ✅ | ❌ |

**Special case**: `mapping` can ONLY exist in storage, never memory or calldata.

## Common Pitfalls

### Pitfall 1: Forgetting Data Locations

```solidity
// ❌ WRONG: Will not compile
function bad(uint[] arr) public {}  // Missing data location

// ✅ CORRECT
function good(uint[] memory arr) public {}
```

### Pitfall 2: Modifying Memory Instead of Storage

```solidity
struct User {
    uint balance;
}
User[] public users;

function badUpdate(uint index) public {
    User memory user = users[index];  // Memory COPY
    user.balance = 100;               // Only changes copy, not storage!
}

function goodUpdate(uint index) public {
    User storage user = users[index];  // Storage REFERENCE
    user.balance = 100;                // Changes persistent storage ✅
}
```

### Pitfall 3: Inefficient Struct Packing

```solidity
// ❌ BAD: Uses 3 storage slots (96 bytes)
struct BadPacking {
    uint256 a;  // Slot 0 (32 bytes)
    uint8 b;    // Slot 1 (1 byte, wastes 31 bytes)
    uint256 c;  // Slot 2 (32 bytes)
}

// ✅ GOOD: Uses 2 storage slots (64 bytes)
struct GoodPacking {
    uint256 a;  // Slot 0 (32 bytes)
    uint256 c;  // Slot 1 (32 bytes)
    uint8 b;    // Slot 1 (packs with 'c')
}
```

**Rule**: Variables in a struct pack if their combined size <= 32 bytes.

## Language Comparisons

### Python
```python
# Dynamic typing, no size specification
x = 42
x = "hello"  # Totally fine
data = [1, "two", 3.0, True]  # Mixed types OK
```

### TypeScript
```typescript
// Static typing with type inference
let x: number = 42;
// x = "hello";  // Compile error - type mismatch
const arr: (number | string | boolean)[] = [1, "two", true];  // Union types OK
```

### Go
```go
// Static typing, explicit types
var x uint256 = 42
// x = "hello"  // Compile error
arr := []uint32{1, 2, 3}  // Typed slices
```

### Rust
```rust
// Static typing, but with type inference
let x: u256 = 42;
// x = "hello";  // Compile error ✅
let arr: Vec<u32> = vec![1, 2, 3];  // Typed arrays
```

### Solidity
```solidity
// Static typing, NO inference, explicit sizes
uint256 x = 42;
// x = "hello";  // Compile error 
uint256[] memory arr = new uint256[](3);  // Must specify type AND location
```

**Solidity is strictest because blockchain state must be deterministic across all nodes.**

## =? Further Reading

- [Solidity Docs: Types](https://docs.soliditylang.org/en/latest/types.html)
- [Solidity Docs: Data Location](https://docs.soliditylang.org/en/latest/types.html#data-location)
- [Understanding Storage Layout](https://docs.soliditylang.org/en/latest/internals/layout_in_storage.html)
- [Gas Costs Reference](https://www.evm.codes/)

## Completion Checklist

- [ ] Implemented skeleton contract
- [ ] All tests pass (`forge test`)
- [ ] Read and understood solution contract
- [ ] Compared gas costs (`forge test --gas-report`)
- [ ] Experimented with different data types and locations
- [ ] Can explain storage vs memory vs calldata
- [ ] Can calculate struct packing savings

## Next Steps

Once comfortable with datatypes and storage:
- Move to [Project 02: Functions & Payable](../02-functions-and-payable/)
- Experiment with the contract in Remix IDE
- Try deploying to a testnet (see deployment script)

## Pro Tips

1. **Always specify data locations** for reference types in functions
2. **Use `calldata` for external function parameters** (cheapest)
3. **Pack structs carefully** - group small types together
4. **Use `uint256` for local variables** (gas-optimized by EVM)
5. **Only use smaller types (`uint8`, `uint128`) in structs** for packing

---

**Ready to code?** Open `src/DatatypesStorage.sol` and start implementing! =?
