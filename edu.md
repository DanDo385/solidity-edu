# Solidity 47-Project Educational Content

> **Complete learning content from all 47 mini-projects in one document**
>
> This file combines the educational content from all project READMEs for easy reference and offline reading.

## Table of Contents

1. [01-datatypes-and-storage: Datatypes & Storage 💾](#01-datatypes-and-storage)
2. [02-functions-and-payable: Functions & Payable 💰](#02-functions-and-payable)
3. [03-events-and-logging: Events & Logging 📢](#03-events-and-logging)
4. [04-modifiers-and-restrictions: Modifiers & Access Control 🔐](#04-modifiers-and-restrictions)
5. [05-errors-and-reverts: Errors & Reverts ⚠️](#05-errors-and-reverts)
6. [06-mappings-arrays-and-gas: Mappings, Arrays & Gas ⛽](#06-mappings-arrays-and-gas)
7. [07-reentrancy-and-security: Reentrancy & Security 🛡️](#07-reentrancy-and-security)
8. [08-ERC20-from-scratch: ERC20 from Scratch 🪙](#08-ERC20-from-scratch)
9. [09-ERC721-NFT-from-scratch: ERC721 NFT from Scratch 🖼️](#09-ERC721-NFT-from-scratch)
10. [10-upgradeability-and-proxies: Upgradeability & Proxies 🔄](#10-upgradeability-and-proxies)
11. [11-ERC4626-tokenized-vault: ERC-4626 Tokenized Vault 🏦](#11-ERC4626-tokenized-vault)
12. [12-safe-eth-transfer: Safe ETH Transfer Library 🛡️](#12-safe-eth-transfer)
13. [13-block-time-logic: Block Properties & Time Logic ⏰](#13-block-time-logic)
14. [14-abi-encoding: ABI Encoding & Function Selectors](#14-abi-encoding)
15. [15-low-level-calls: Low-Level Calls](#15-low-level-calls)
16. [16-contract-factories: Contract Factories (CREATE2)](#16-contract-factories)
17. [17-minimal-proxy: Minimal Proxy (EIP-1167)](#17-minimal-proxy)
18. [18-oracles-chainlink: Oracles (Chainlink) 🔮](#18-oracles-chainlink)
19. [19-signed-messages: Signed Messages & EIP-712](#19-signed-messages)
20. [20-deposit-withdraw: Deposit/Withdraw Accounting](#20-deposit-withdraw)
21. [22-erc20-openzeppelin: ERC-20 (OpenZeppelin)](#22-erc20-openzeppelin)
22. [23-erc20-permit: ERC-20 Permit (EIP-2612)](#23-erc20-permit)
23. [25-erc721a-optimized: ERC-721A Optimized NFT Collection](#25-erc721a-optimized)
24. [26-erc1155-multi: ERC-1155 Multi-Token Standard](#26-erc1155-multi)
25. [27-soulbound-tokens: Soulbound Tokens (SBTs)](#27-soulbound-tokens)
26. [28-erc2981-royalties: ERC-2981 Royalties](#28-erc2981-royalties)
27. [29-merkle-allowlist: Merkle Proof Allowlists](#29-merkle-allowlist)
28. [30-onchain-svg: On-Chain SVG Rendering](#30-onchain-svg)
29. [31-reentrancy-lab: Reentrancy Lab (Advanced) 🔄](#31-reentrancy-lab)
30. [32-overflow-lab: Integer Overflow Labs (Pre-0.8)](#32-overflow-lab)
31. [33-mev-frontrunning: MEV & Front-Running Simulation](#33-mev-frontrunning)
32. [34-oracle-manipulation: Oracle Manipulation Attack](#34-oracle-manipulation)
33. [35-delegatecall-corruption: Delegatecall Storage Corruption](#35-delegatecall-corruption)
34. [36-access-control-bugs: Access Control Bugs](#36-access-control-bugs)
35. [37-gas-dos-attacks: Gas DoS Attacks](#37-gas-dos-attacks)
36. [38-signature-replay: Signature Replay Attack](#38-signature-replay)
37. [39-governance-attack: Governance Attack Simulation](#39-governance-attack)
38. [40-multisig-wallet: Multi-Sig Wallet](#40-multisig-wallet)
39. [42-vault-precision: ERC-4626 Precision & Rounding 🔢](#42-vault-precision)
40. [43-yield-vault: Yield-Bearing Vault](#43-yield-vault)
41. [44-inflation-attack: ERC-4626 Inflation Attack Demo](#44-inflation-attack)
42. [45-multi-asset-vault: Multi-Asset Vault](#45-multi-asset-vault)
43. [46-vault-insolvency: Vault Insolvency Scenarios](#46-vault-insolvency)
44. [47-vault-oracle: Vault Oracle Integration](#47-vault-oracle)
45. [48-meta-vault: Meta-Vault (4626→4626)](#48-meta-vault)
46. [49-leverage-vault: Leverage Looping Vault](#49-leverage-vault)
47. [50-defi-capstone: Full DeFi Protocol Capstone 🏆](#50-defi-capstone)

---


## 01-datatypes-and-storage

# Project 01: Datatypes & Storage 💾

> **Master Solidity's type system and understand where your data lives**

## 🎯 Learning Objectives

By completing this project, you will:

1. **Understand Solidity's static type system** and why it exists
2. **Distinguish between value types and reference types**
3. **Master data locations**: `storage`, `memory`, and `calldata`
4. **Analyze gas costs** of different data structures
5. **Explain storage layout** and slot allocation
6. **Compare** Solidity's approach with TypeScript, Go, and Rust
7. **Create Foundry deployment scripts** from scratch
8. **Write comprehensive test suites** using Foundry's testing framework

## 📁 Project Directory Structure

### Understanding `cache/` and `out/` Directories

When you run `forge build` or `forge test`, Foundry generates two important directories:

#### `cache/` Directory

The `cache/` directory contains Foundry's **compilation cache**:
- **Purpose**: Tracks file metadata to determine what needs recompiling
- **Contents**: `solidity-files-cache.json` - stores modification dates, content hashes, imports, and build artifacts
- **Why it exists**: Speeds up compilation by only recompiling files that changed
- **Should you commit it?**: No - it's auto-generated and project-specific

**Real-world analogy**: Like a library's card catalog - it tracks which books (files) exist and when they were last updated, so the librarian (compiler) knows what needs checking.

#### `out/` Directory

The `out/` directory contains **compiled contract artifacts**:
- **Purpose**: Stores all compilation outputs (bytecode, ABIs, metadata)
- **Structure**: One subdirectory per Solidity file that gets compiled - this includes **everything**:
  - ✅ Your contracts (`DatatypesStorage.sol`)
  - ✅ Your tests (`DatatypesStorage.t.sol`)
  - ✅ Your scripts (`DeployDatatypesStorage.s.sol`)
  - ✅ **All forge-std library files** (`Base.sol`, `Test.sol`, `Script.sol`, `Vm.sol`, `console.sol`, etc.)
  - ✅ **All Std* helper contracts** (`StdAssertions.sol`, `StdChains.sol`, `StdCheats.sol`, `StdStorage.sol`, etc.)
  - ✅ **Interface contracts** (`IMulticall3.sol`)
  - ✅ **Any imported dependencies**

  ```
  out/
  ├── DatatypesStorage.sol/          # Your contract
  │   └── DatatypesStorage.json      # Contains bytecode, ABI, metadata
  ├── DatatypesStorage.t.sol/        # Your test contract
  │   └── DatatypesStorageTest.json
  ├── Base.sol/                      # forge-std base contracts
  │   ├── CommonBase.json
  │   ├── ScriptBase.json
  │   └── TestBase.json
  ├── Test.sol/                      # forge-std Test contract
  │   └── Test.json
  ├── Vm.sol/                        # Foundry cheatcodes
  │   ├── Vm.json
  │   └── VmSafe.json
  ├── Script.sol/                    # forge-std Script contract
  │   └── Script.json
  ├── console.sol/                   # forge-std console logging
  │   └── console.json
  ├── StdAssertions.sol/             # forge-std assertion helpers
  │   └── StdAssertions.json
  ├── StdChains.sol/                 # forge-std chain helpers
  │   └── StdChains.json
  ├── StdCheats.sol/                 # forge-std cheatcode helpers
  │   ├── StdCheats.json
  │   └── StdCheatsSafe.json
  ├── IMulticall3.sol/               # Multicall3 interface
  │   └── IMulticall3.json
  └── build-info/                    # Detailed compilation metadata
      └── [hash].json
  ```

- **Why so many subdirectories?**: Foundry compiles **every Solidity file** that your project uses, including all dependencies from `forge-std` and other libraries. Each file gets its own directory with JSON artifacts, even if you didn't write it yourself!
- **What's in each JSON file?**:
  - `bytecode.object`: Deployment bytecode (constructor + contract code)
  - `deployedBytecode.object`: Runtime bytecode (what's stored on-chain)
  - `abi`: Application Binary Interface (function signatures, events, errors)
  - `metadata`: Compiler version, settings, source mappings
- **Should you commit it?**: No - it's auto-generated and can be rebuilt with `forge build`

**Real-world analogy**: Like a factory's finished goods warehouse - each product (contract) gets its own shelf (subdirectory) with all its documentation (JSON artifacts) stored together.

**Why this structure?**:
- **Organization**: Keeps artifacts for each contract separate and easy to find
- **Efficiency**: Only recompiles what changed (using cache)
- **Compatibility**: Standard format that tools (Etherscan, frontends, debuggers) can read
- **Debugging**: Source maps in metadata help debuggers map bytecode back to source code

**Pro tip**: You can extract ABIs for frontend integration:
```bash
# Extract ABI for your contract
cat out/DatatypesStorage.sol/DatatypesStorage.json | jq '.abi' > abi.json
```

## 📚 Key Concepts

### Why Solidity Types Are Strict

**Python**: You can write `x = 42` then reassign `x = "hello"`. Types are dynamic.
**Solidity**: You must declare `uint256 x = 42` and can *never* assign a string to `x`. Types are static and immutable.

**Why?** The EVM (Ethereum Virtual Machine) requires:
- **Deterministic memory layout**: Every node must compute the same storage slots
- **Gas predictability**: Type sizes determine computational costs
- **Security**: Type confusion can lead to vulnerabilities

Think of storage like a *global shipping warehouse*: every package must have the exact same dimensions and aisle number on every forklift (node) so deliveries are reproducible worldwide.

### Storage Slots (256-bit)

Every contract has 2^256 storage slots, each 256 bits (32 bytes):

```
Slot 0: [32 bytes]
Slot 1: [32 bytes]
Slot 2: [32 bytes]
...
```

**Understanding Storage Costs (Gas)**:

- **Cold read (first access)**: ~2,100 gas - like walking into a cold storage warehouse for the first time
- **Warm read (subsequent)**: ~100 gas - lights are already on, you know where the file is
- **Cold write (zero → non-zero)**: ~20,000 gas - creating something from nothing
- **Warm write (non-zero → non-zero)**: ~5,000 gas - updating existing data
- **Memory**: ~3 gas per 32-byte word - like a whiteboard, temporary and cheap

**Compare**: Storage is 100x more expensive than memory! On rollups, calldata is cheaper but storage writes are still pricey because data ultimately posts to Ethereum mainnet.

### Data Locations

In Solidity, **where** your data lives is just as important as **what** type it is:

1. **Storage** (Permanent, Expensive)
   - Like a bank vault: secure, permanent, but costly to access
   - Costs ~20,000 gas for new data, ~5,000 gas for updates

2. **Memory** (Temporary, Cheap)
   - Like RAM: fast, temporary, erased when done
   - Costs ~3 gas per 32-byte word

3. **Calldata** (Read-Only, Cheapest)
   - Like a read-only USB drive: can't modify it, but super cheap to read
   - Most gas-efficient for passing large arrays/strings to functions

```solidity
uint256 public storageVar;  // Lives forever, expensive (~20k gas to write)

function temp(uint256[] memory arr) public {
    // 'arr' is temporary, erased after function exits
    // Costs ~3 gas per word to allocate
}

function readOnly(uint256[] calldata arr) external {
    // 'arr' is read-only from transaction data
    // Cheapest option because no copying happens!
}
```

### Value Types vs Reference Types

**Value Types** (Copied When Assigned):
- Examples: `uint`, `int`, `bool`, `address`, `bytes32`, `enum`
- Work like photocopying a document - independent copies
- Real-world analogy: Like cash - if you give someone a $10 bill, they have their own $10

**Reference Types** (Assigned by Reference):
- Examples: `array`, `struct`, `mapping` (storage only)
- Work like sharing a Google Doc link - multiple variables point to same data
- Critical rule: Data location (`storage`, `memory`, `calldata`) determines if you're working with original or copy
- Real-world analogy: Like a house address - multiple people can have "123 Main St" written down, but there's only one actual house

### Struct Packing

The EVM stores data in slots of exactly 32 bytes. Variables < 32 bytes can share slots if declared consecutively, saving gas!

**Bad Packing** (3 slots):
```solidity
struct BadPacking {
    uint256 a;  // Slot 0: [32 bytes]
    uint8 b;    // Slot 1: [1 byte used, 31 WASTED!]
    uint256 c;  // Slot 2: [32 bytes]
}
```

**Good Packing** (2 slots):
```solidity
struct OptimalPacking {
    uint128 a;  // Slot 0: [16 bytes]
    uint128 c;  // Slot 0: [16 bytes - FITS!]
    uint8 b;    // Slot 1: [1 byte]
}
```

**Gas Savings**: 2 slots vs 3 slots = ~10,000 gas saved per write!

---

## 📖 Deep Dive: Computer Science First Principles

### Building Your Solidity Foundation

This project introduces fundamental concepts that form the **foundation** of all Solidity development. Every concept you learn here will be referenced and built upon in future projects. Understanding these deeply will make you a more effective smart contract developer.

### The Solidity Type System: Why Strict Typing Matters

**Computer Science Principle**: Type systems exist to catch errors at compile-time rather than runtime, ensuring program correctness before execution.

**Real-World Analogy**: Solidity types are like numbered lockers in a gym. Each locker (variable) has a fixed size (type) and can only hold items that fit exactly. Unlike TypeScript/Go/Rust where storage is flexible, Solidity requires exact sizes because every node on the blockchain must compute the same storage layout.

**Why Solidity is Different**:

Unlike TypeScript/Go/Rust (static typing with inference), Solidity requires explicit types and sizes because the EVM (Ethereum Virtual Machine) needs to:

1. **Calculate exact gas costs at compile time** - Every operation must have predictable gas costs
2. **Determine storage layout deterministically** - Every node must agree on where data is stored
3. **Prevent type confusion attacks** - Mixing types could lead to security vulnerabilities
4. **Enable all nodes to compute identical state** - Consensus requires byte-for-byte agreement

**Language Comparison**:

| Language | Type Declaration | Type Inference | Size Specification |
|----------|-----------------|----------------|-------------------|
| TypeScript | `let x: number = 42` | ✅ Yes | ❌ No (handled by JS engine) |
| Go | `var x uint256 = 42` | ✅ Yes | ⚠️ Platform-dependent |
| Rust | `let x: u256 = 42` | ✅ Yes | ⚠️ Target-dependent |
| Solidity | `uint256 x = 42` | ❌ No | ✅ Always fixed 256-bit |

**Foundation Building**: This strict type system underpins everything. In future projects, you'll learn that:
- Type mismatches catch bugs early (Project 02: Functions & Payable)
- Storage layout determines gas costs (Project 06: Mappings, Arrays & Gas)
- Type safety prevents vulnerabilities (Project 05: Errors & Reverts, Project 07: Reentrancy)

### Storage Model Deep Dive: The 256-Bit Word Machine

**Computer Science Principle**: The EVM is a 256-bit word machine. All storage operations work on 256-bit (32-byte) words, following a deterministic slot-based addressing scheme.

**Storage Slots: The Building Blocks**

Every contract has 2^256 storage slots (practically infinite), each exactly 32 bytes (256 bits):

```
┌─────────────────────────────────────────┐
│ Slot 0: [32 bytes] - number (uint256)  │
│ Slot 1: [32 bytes] - owner (address)   │
│ Slot 2: [32 bytes] - isActive (bool)   │
│ Slot 3: [32 bytes] - data (bytes32)    │
│ Slot 4: [dynamic] - message (string)   │
│ Slot 5: [mapping] - balances           │
│ ...                                     │
└─────────────────────────────────────────┘
```

**How Storage Slot Allocation Works**:

1. **State variables** are allocated sequentially starting at slot 0
2. **Each 32-byte variable** gets its own slot
3. **Smaller variables** can pack together if declared consecutively (struct packing)
4. **Mappings** don't occupy slots directly - their values are calculated: `keccak256(abi.encodePacked(key, slot))`
5. **Arrays** store length in their slot, elements at `keccak256(slot) + index`

**Storage Costs Breakdown**:

| Operation | Gas Cost | When It Happens |
|-----------|----------|-----------------|
| SSTORE (cold, zero → non-zero) | ~20,000 | First write to a slot |
| SSTORE (warm, non-zero → non-zero) | ~5,000 | Updating existing data |
| SSTORE (non-zero → zero) | ~5,000 + refund | Clearing storage (refund up to ~15,000) |
| SLOAD (cold) | ~2,100 | First read from a slot |
| SLOAD (warm) | ~100 | Subsequent reads |

**Why Cold vs Warm?**: EVM tracks recently accessed storage. "Warm" storage (accessed in current transaction) is cheaper because the node has it in cache. "Cold" storage requires reading from disk/state database.

**Foundation Building**: Understanding storage costs is critical because:
- Every storage operation affects gas costs (all projects)
- Mappings vs arrays storage layout determines efficiency (Project 06)
- Storage patterns impact scalability (Project 50: DeFi Capstone)

### Mappings: The O(1) Key-Value Store

**Computer Science Principle**: Mappings provide O(1) constant-time lookups using hash-based addressing. They're conceptually infinite in size (2^256 possible keys).

**How Mappings Store Data**:

Mappings don't store keys - only values! When you write `balances[address] = amount`, the storage slot is calculated:

```solidity
slot = keccak256(abi.encodePacked(key, mapping_slot))
```

**Example**: For `mapping(address => uint256) public balances` at slot 5:
- Key: `0x1234...5678`
- Slot calculation: `keccak256(abi.encodePacked(0x1234...5678, 5))`
- Value stored at calculated slot

**Mapping Characteristics**:

✅ **Advantages**:
- O(1) access time (constant, regardless of size)
- No iteration needed
- Infinite conceptual size (2^256 possible keys)
- Default values for unset keys (0 for uint, false for bool, etc.)

❌ **Limitations**:
- Cannot iterate over keys (no `.keys()` like Python)
- Cannot get length/size
- Cannot check if key exists (always returns default if unset)

**The Zero Default Mystery**:

One of Solidity's unique features: mappings **always** return a value, even for keys that were never set! This is different from most languages:

- **Python**: Raises `KeyError` if key doesn't exist
- **JavaScript**: Returns `undefined`
- **Solidity**: Returns the type's default value (0 for uint256, false for bool, empty bytes for bytes)

**Why This Design?**:
1. Gas efficiency - no need to check "does key exist?" (saves gas)
2. Safety - no risk of undefined/null errors
3. Predictable behavior - easier to reason about

**The Problem**: You can't distinguish between "never set" and "set to zero":
```solidity
balances[alice] = 0;  // Was it never set, or was it set to 0?
```

**Solutions**:
1. **Separate existence mapping**: `mapping(address => bool) hasDeposited`
2. **Sentinel value**: Reserve 0 for "never set", use 1 wei minimum for "exists"
3. **Accept ambiguity**: If zero means "empty", you might not need to distinguish

**Foundation Building**: Mappings are used everywhere:
- ERC20 token balances (Project 08: ERC20 from Scratch)
- Access control (Project 04: Modifiers & Restrictions)
- Voting systems (Project 39: Governance Attack)
- DeFi protocols (Project 50: DeFi Capstone)

### Arrays: Ordered Collections with Hidden Complexity

**Computer Science Principle**: Arrays provide ordered, iterable collections but require careful bounds checking and gas cost awareness due to linear-time operations.

**How Arrays Are Stored**:

Arrays use a two-part storage system:

```
┌─────────────────────────────────────────────┐
│ Slot N: Length (uint256) - stored value    │
├─────────────────────────────────────────────┤
│ Slot keccak256(N) + 0: array[0]            │
│ Slot keccak256(N) + 1: array[1]            │
│ Slot keccak256(N) + 2: array[2]            │
│ ...                                         │
└─────────────────────────────────────────────┘
```

**Key Insight**: Unlike many languages, Solidity arrays store their length **explicitly** as a uint256 value. This provides:
- O(1) length access (constant time)
- No need to iterate to count elements
- Efficient bounds checking

**Array Operations and Gas Costs**:

| Operation | Gas Cost (warm) | Complexity | Notes |
|-----------|----------------|------------|-------|
| `push()` | ~10,000 | O(1) | Two storage writes: length + element |
| `pop()` | ~5,000 + refund | O(1) | Decrements length, clears element |
| `array[index]` (read) | ~100 | O(1) | Direct slot calculation |
| `array[index]` (write) | ~5,000 | O(1) | Single storage write |
| Loop through array | ~100 × length | O(n) | Linear gas cost - **DANGEROUS!** |

**The Unbounded Growth Problem (DoS Vulnerability)**:

Arrays can grow forever (theoretically up to 2^256 elements). This creates a **Denial of Service** vulnerability:

```solidity
// Attacker can make array huge
function attack() public {
    for(uint i = 0; i < 1000; i++) {
        addNumber(i);  // Makes array huge!
    }
}

// Later, this becomes impossible (exceeds block gas limit)
function processAll() public {
    for(uint i = 0; i < numbers.length; i++) {
        process(numbers[i]);  // ❌ FAILS if array too large!
    }
}
```

**Defense Strategies**:
1. **Limit array size**: `require(numbers.length < MAX_SIZE)`
2. **Use mappings instead**: O(1) access, no iteration needed
3. **Process off-chain**: Emit events, use indexers for heavy lifting
4. **Use fixed-size arrays**: `uint256[10] fixedNumbers` if max size known

**The Swap-and-Pop Pattern**:

Removing elements from arrays efficiently:

**Naive Approach (O(n), Expensive)**:
```solidity
// Shift everything left - costs O(n) gas
[10, 20, 30, 40] → remove index 1
[10, 30, 40, 0]  // Shifted all elements - expensive!
```

**Swap-and-Pop (O(1), Cheap)**:
```solidity
// Swap with last, then pop - costs O(1) gas
[10, 20, 30, 40] → remove index 1
Step 1: numbers[1] = numbers[3] → [10, 40, 30, 40]
Step 2: numbers.pop() → [10, 40, 30]
// Order changed, but much cheaper!
```

**Trade-off**: Order is not preserved, but gas savings are massive (90% reduction for large arrays).

**Foundation Building**: Arrays are used for:
- Iterable collections (when order matters)
- Token lists (Project 09: ERC721 NFT)
- Participant lists (Project 40: Multisig Wallet)
- **But be careful** - many patterns use mappings + events instead for gas efficiency

### Structs: Custom Types and Packing Optimization

**Computer Science Principle**: Structs group related data together, and careful field ordering enables efficient memory/storage packing, reducing gas costs significantly.

**How Structs Are Stored in Mappings**:

When a struct is stored in a mapping, fields are stored sequentially:

```
Mapping: mapping(address => User) users;
For key 0xABCD...:

Base slot = keccak256(abi.encodePacked(0xABCD..., slot_7))
┌─────────────────────────────────────────────┐
│ base_slot + 0: wallet (address) - 20 bytes │
│ base_slot + 1: balance (uint256) - 32 bytes│
│ base_slot + 2: isRegistered (bool) - 1 byte│
└─────────────────────────────────────────────┘
Total: 3 storage slots per User struct
```

**Struct Packing Rules**:

1. **Variables pack if total size ≤ 32 bytes** and declared consecutively
2. **Packing ONLY works in structs**, not global state variables
3. **Order matters!** Solidity doesn't reorder fields

**Packing Example**:

**Unpacked Struct (3 slots)**:
```solidity
struct User {
    address wallet;      // Slot 0: 20 bytes (wastes 12)
    uint256 balance;     // Slot 1: 32 bytes
    bool isRegistered;   // Slot 2: 1 byte (wastes 31)
}
// Total: 96 bytes (3 slots) = 60,000 gas (cold)
```

**Packed Struct (2 slots)**:
```solidity
struct PackedData {
    uint128 smallNumber1;  // Slot 0: 16 bytes
    uint128 smallNumber2;  // Slot 0: 16 bytes (fits!)
    uint64 timestamp;      // Slot 1: 8 bytes
    address user;          // Slot 1: 20 bytes (fits!)
    bool flag;             // Slot 1: 1 byte (fits!)
}
// Total: 61 bytes (2 slots) = 40,000 gas (cold)
// Savings: 20,000 gas (50% reduction!)
```

**Real-World Impact**: In NFT contracts (Project 09), packing token metadata can save millions of gas when minting collections. In DeFi (Project 50), packing user positions saves significant gas across thousands of transactions.

**Foundation Building**: Struct packing is essential for:
- NFT metadata optimization (Project 09: ERC721 NFT)
- DeFi position tracking (Project 11: ERC4626, Project 50: DeFi Capstone)
- Gas optimization in production contracts (all projects)

### Events: The Bridge Between On-Chain and Off-Chain

**Computer Science Principle**: Events provide an efficient, searchable log of on-chain state changes, enabling off-chain systems (frontends, indexers) to track contract activity without expensive storage reads.

**How Events Work**:

```
┌─────────────────────────────────────────┐
│ Contract emits event                    │
│   ↓                                      │
│ Event data stored in transaction log    │ ← Cheaper than storage!
│   ↓                                      │
│ Off-chain systems listen to events       │ ← Indexers, frontends
│   ↓                                      │
│ UI updates in real-time                 │
└─────────────────────────────────────────┘
```

**Events vs Storage**:

| Feature | Storage | Events |
|---------|---------|--------|
| Cost | ~20,000 gas/write | ~2,000 gas/emit |
| Persistence | Permanent | Permanent (in logs) |
| Searchability | No | Yes (indexed params) |
| Off-chain access | Requires RPC calls | Efficient filtering |
| Use case | On-chain state | Off-chain indexing |

**Indexed Parameters: The Search Feature**:

Indexed parameters are like searchable tags:
- Can filter events by indexed values
- Up to **3 indexed parameters** per event
- Each indexed param costs ~375 gas extra

**Example**:
```javascript
// Filter all NumberUpdated events where oldValue = 100
contract.on("NumberUpdated", { oldValue: 100 }, (event) => {
    console.log("Number was updated from 100!");
});
```

**Event Structure**:
```solidity
event NumberUpdated(uint256 indexed oldValue, uint256 indexed newValue);
//                            ↑ indexed              ↑ indexed
//                            (searchable)           (searchable)
```

**Gas Cost Breakdown**:
- Base event: ~375 gas
- Each indexed param: +375 gas
- Each non-indexed param: +375 gas (for data)
- **Total**: ~2,000-3,000 gas (much cheaper than storage!)

**Why Events Matter**: Frontends, indexers, and analytics tools all rely on events. Without events, off-chain systems would have to constantly poll storage (expensive and inefficient!). Events make blockchain data accessible to web applications.

**Foundation Building**: Events are critical for:
- Frontend integration (all projects)
- Transaction history tracking (Project 03: Events & Logging)
- DeFi protocols (Project 08: ERC20, Project 50: DeFi Capstone)
- NFT marketplaces (Project 09: ERC721 NFT)

### Constructors: One-Time Initialization

**Computer Science Principle**: Constructors execute exactly once during contract deployment, providing a deterministic initialization point that can't be re-executed.

**How Constructors Work**:

```
┌─────────────────────────────────────────┐
│ Developer deploys contract             │
│   ↓                                      │
│ Constructor executes                   │ ← Runs ONCE, never again!
│   ↓                                      │
│ Initial state is set                    │
│   ↓                                      │
│ Contract is live on blockchain          │
│   ↓                                      │
│ Constructor code is DISCARDED           │ ← Not stored!
└─────────────────────────────────────────┘
```

**Critical Insight**: Constructor code is **NOT stored on-chain**! Only the runtime code (your functions) is stored. The constructor runs during deployment, then disappears. This saves gas - you don't pay to store initialization code forever.

**Security Pattern: Setting Owner**:

Setting owner in constructor is a **CRITICAL security pattern**:
1. Establishes who controls the contract
2. `msg.sender` during deployment = the deployer
3. Prevents anyone else from claiming ownership
4. Common pattern in "Ownable" contracts (like OpenZeppelin)

**Gas Cost**:
- Constructor execution: Included in deployment cost
- Setting owner: ~20,000 gas (cold write)
- Setting isActive: ~20,000 gas (cold write)
- Total deployment: ~200,000+ gas (includes bytecode storage)

**Important**: Constructor can't be called again! Once deployed, there's NO WAY to re-run the constructor. This is why initialization must be complete and correct.

**Foundation Building**: Constructors are used for:
- Setting initial owners (Project 04: Modifiers & Restrictions)
- Initializing upgradeable proxies (Project 10: Upgradeability & Proxies)
- Setting up initial state in all contracts (all projects)

### Data Locations: Storage, Memory, and Calldata

**Computer Science Principle**: Understanding data locations is fundamental to gas optimization and preventing bugs. Each location has different costs, persistence, and mutability characteristics.

**The Three Realms of Solidity**:

| Location | Persistence | Cost | Mutability | Use Case |
|----------|-------------|------|------------|----------|
| **storage** | Permanent | ~20k/write, ~100/read | Mutable | State variables |
| **memory** | Temporary | ~3/word | Mutable | Local variables, return values |
| **calldata** | Read-only | Free (read from tx) | Immutable | External function parameters |

**Storage: The Permanent Vault**

Storage is like a bank vault - secure, permanent, but costly to access. State variables live here.

**Memory: The Temporary Workspace**

Memory is like a scratchpad - temporary and cheap:
- Allocated when function is called
- Erased when function exits
- Perfect for calculations and return values

**How Memory Works**:
```
┌─────────────────────────────────────────┐
│ Function called                          │
│   ↓                                      │
│ Memory allocated (grows as needed)      │
│   ↓                                      │
│ Function executes (uses memory)         │
│   ↓                                      │
│ Function returns                         │
│   ↓                                      │
│ Memory cleared (freed automatically)     │
└─────────────────────────────────────────┘
```

**Memory Cost**: Each 32-byte word costs ~3 gas to allocate. An array of 10 uint256s costs ~30 gas for memory allocation. Compare that to storage: ~200,000 gas for 10 writes!

**Calldata: The Zero-Copy Champion**

Calldata is the MOST gas-efficient data location! It's read-only data that comes directly from the transaction.

**How Calldata Works**:
```
┌─────────────────────────────────────────┐
│ User sends transaction with data        │
│   ↓                                      │
│ Data stored in transaction calldata    │ ← Already on-chain!
│   ↓                                      │
│ Function reads directly from calldata   │ ← No copy needed!
│   ↓                                      │
│ Function returns                         │
└─────────────────────────────────────────┘
```

**Calldata Benefits**:
- Zero copy cost - reads directly from transaction
- Cheapest option for large arrays/strings
- Only available in EXTERNAL functions

**Gas Comparison (100-element array)**:

| Location | Allocation | Read First Element | Total |
|----------|------------|-------------------|-------|
| calldata | 0 gas | ~100 gas | **~100 gas** ← Winner! |
| memory | ~300 gas | ~103 gas | ~403 gas |
| storage | N/A | ~100 gas | ~100 gas |

**Restrictions**:
- Calldata only available in **EXTERNAL** functions
- Cannot be modified (read-only)
- Cannot be used in internal/public functions

**Foundation Building**: Data location understanding is critical for:
- Gas optimization (all projects)
- Function parameter design (Project 02: Functions & Payable)
- Preventing bugs (memory vs storage confusion causes many errors)
- External vs public functions (Project 08: ERC20, Project 09: ERC721)

---

## 🎓 How Concepts Build on Each Other

As you progress through this course, you'll see how the foundational concepts from this project form the building blocks for everything else:

1. **Type System → Security**: Strict types prevent vulnerabilities (Project 05: Errors & Reverts, Project 07: Reentrancy)
2. **Storage Layout → Gas Optimization**: Understanding slots enables optimization (Project 06: Mappings, Arrays & Gas)
3. **Mappings → Token Standards**: ERC20 balances are mappings (Project 08: ERC20 from Scratch)
4. **Events → Frontend Integration**: Events enable web3 apps (Project 03: Events & Logging)
5. **Data Locations → Efficiency**: Calldata optimization saves gas (Project 15: Low-Level Calls)
6. **Struct Packing → DeFi**: Efficient position tracking (Project 11: ERC4626, Project 50: DeFi Capstone)
7. **Constructors → Upgradeability**: Proxy patterns use initialization (Project 10: Upgradeability & Proxies)

**Each concept you master here makes you stronger for the next project!**

---

## 📋 Key Takeaways & Common Mistakes

### Essential Takeaways

1. **Types Are Strict**: EVM requires deterministic, fixed-size layout. No type inference, no dynamic typing - everything must be explicit.

2. **Data Locations Matter**: 
   - `storage`: Persistent, expensive (~20k gas/write)
   - `memory`: Temporary, medium cost (~3 gas/word)
   - `calldata`: Read-only, cheapest (no copy)

3. **Gas Is King**: Every operation costs gas. Storage is 100x more expensive than memory. Struct packing can save 50%+ gas.

4. **Mappings Are Special**: O(1) access, no iteration, infinite conceptual size. Storage slot = `keccak256(key, slot)`.

5. **Arrays Are Dangerous**: Unbounded growth → DoS risk. Iteration costs scale linearly. Consider mappings + events instead.

6. **Solidity ≠ Other Languages**: Static, explicit, gas-aware, blockchain-specific. Not like Python (dynamic) or Rust (with inference).

### Common Mistakes to Avoid

- ❌ **Forgetting data location**: `uint[] arr` (missing `memory`/`calldata`)
- ❌ **Modifying memory instead of storage**: `User memory u = users[addr]; u.x = 5;` (doesn't affect storage!)
- ❌ **Inefficient packing**: Declaring `uint8` after `uint256` (wastes space)
- ❌ **Unbounded loops**: `for(i = 0; i < array.length; i++)` on large arrays (DoS risk)
- ❌ **Not checking array bounds explicitly** when needed
- ❌ **Using smaller uints for local variables** (costs MORE gas - use `uint256`)
- ❌ **Not emitting events** for state changes (off-chain indexing needs them)

---

## 🔧 What You'll Build

A contract demonstrating:
- All major Solidity datatypes (uint256, address, bool, bytes32, string)
- Storage vs memory vs calldata differences
- Gas-efficient struct packing
- Mapping usage patterns
- Array operations and costs
- Payable functions for ETH deposits

Plus:
- **Deployment script** using Foundry Scripts
- **Comprehensive test suite** with fuzz testing and gas benchmarking

## 📝 Tasks

### Task 1: Implement the Smart Contract

Open `src/DatatypesStorage.sol` and implement all the TODOs:

1. **State variables** for each datatype
2. **Functions** to manipulate mappings and arrays
3. **Getters** that demonstrate data location keywords
4. **Struct packing** to minimize gas costs
5. **Events** for important state changes

### Task 2: Create Your Deployment Script

Open `script/DeployDatatypesStorage.s.sol` and implement:

1. Read deployer's private key from environment using `vm.envOr()`
2. Start broadcasting transactions with `vm.startBroadcast()`
3. Deploy the contract using `new`
4. Log deployment information using `console.log()`
5. Stop broadcasting with `vm.stopBroadcast()`

**Why deployment scripts?** Reproducible, scriptable deployments that work the same way every time.

### Task 3: Write Your Test Suite

Open `test/DatatypesStorage.t.sol` and write comprehensive tests:

1. Constructor behavior and initial state
2. Value type operations (set/get)
3. Mapping operations (set, get, check existence)
4. Array operations (push, access, length, remove)
5. Struct operations (create, read, update)
6. Data location behavior (memory vs storage vs calldata)
7. Event emissions
8. Edge cases and error conditions
9. Fuzz testing with randomized inputs
10. Gas benchmarking

**Testing Best Practices**:
- Use descriptive test names: `test_FunctionName_Scenario`
- Follow Arrange-Act-Assert pattern
- Use `vm.expectRevert()` for error testing
- Use `vm.expectEmit()` for event testing
- Use `testFuzz_` prefix for fuzz tests

### Task 4: Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/DatatypesStorageSolution.sol` - Reference contract implementation with comprehensive CS concept explanations
- `script/solution/DeployDatatypesStorageSolution.s.sol` - Deployment script patterns
- `test/solution/DatatypesStorageSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Each solution file explains computer science principles from first principles (hash tables, dynamic arrays, memory management)
- **Syntax Explanations**: Detailed comments explain Solidity syntax and why certain patterns are used
- **Cross-Project Connections**: Solutions reference how concepts build on each other across projects
- **Purpose Statements**: Each contract includes a clear explanation of real-world use cases

### Task 5: Compile and Test

```bash
cd 01-datatypes-and-storage

# Compile contracts
forge build

# Run all tests
forge test

# Run with verbose output
forge test -vvv

# Run with gas reporting
forge test --gas-report

# Run specific test
forge test --match-test test_SetNumber
```

### Task 6: Deploy Locally

**⚠️ IMPORTANT: This project runs on LOCAL ANVIL ONLY**

```bash
# Terminal 1: Start Anvil (keep this running)
anvil

# Terminal 2: Deploy
cd 01-datatypes-and-storage

# Dry run (simulation only)
forge script script/DeployDatatypesStorage.s.sol

# Deploy to local Anvil (with transactions)
forge script script/DeployDatatypesStorage.s.sol \
  --broadcast \
  --rpc-url http://localhost:8545
```

**Environment Setup**:

Create `.env` with Anvil's default accounts (see project files for examples). Use `PRIVATE_KEY` for main deployer, `PRIVATE_KEY_1` through `PRIVATE_KEY_9` for multi-address testing.

### Task 7: Experiment

Try these experiments:
1. Change `uint256` to `uint128` in a struct - how does gas change?
2. Modify struct packing order - measure the gas difference
3. Use `storage` instead of `memory` for an array parameter - what breaks?
4. Test with fuzz testing - what unexpected inputs break your code?
5. Compare gas costs: `forge snapshot` and `forge snapshot --diff`

## 🧪 Test Coverage

The test suite covers:

- ✅ Constructor behavior and initial state
- ✅ Value type operations (set/get/increment)
- ✅ Mapping operations (set, get, existence checks)
- ✅ Array operations (push, access, length, remove, bounds checking)
- ✅ Struct operations (create, read, update, default values)
- ✅ Data location behavior (memory vs storage vs calldata)
- ✅ Event emissions verification
- ✅ Edge cases (max values, empty arrays, zero address)
- ✅ Error conditions and reverts
- ✅ Fuzz testing with randomized inputs
- ✅ Gas benchmarking

## 🔍 Contract Walkthrough (Solution Highlights)

### Enhanced Solution Files

The solution files (`src/solution/DatatypesStorageSolution.sol`) have been enhanced with:

1. **Computer Science Concepts**: Explanations of hash tables, dynamic arrays, memory management, and storage layout from first principles
2. **Purpose Statements**: Clear descriptions of what each contract could be used for in real-world scenarios
3. **Syntax Explanations**: Detailed comments explaining Solidity syntax and patterns
4. **Cross-Project Connections**: References to how concepts from this project are used in later projects

**Key Learning Approach**: The solution files are designed to reinforce learning by:
- Explaining CS concepts that apply across all programming languages
- Showing how storage patterns are fundamental to all Solidity contracts
- Building connections to future projects (functions, events, tokens, etc.)

- **State layout**: `number`, `owner`, `isActive`, and `data` sit in consecutive slots to make the 32-byte alignment rules tangible. The `message` string shows how dynamic types spill into extra slots, while `balances` and `users` reuse the mapping slot math introduced earlier.
- **Events vs storage**: Every mutating function emits an event (e.g., `NumberUpdated`, `FundsDeposited`) to reinforce that history should live in logs while queryable state stays in storage (see Project 03).
- **Mappings & arrays**: `setBalance` uses direct assignment (no read-modify-write) when overwriting, while `addNumber`/`removeNumber` demonstrate the length write + element write pattern and the swap-and-pop gas saver (order not preserved).
- **Data locations**: `sumMemoryArray` vs `getFirstElement` contrast `memory` (cheap, copyable) and `calldata` (cheapest, zero-copy) so you can connect the theory from the “Data Locations” section to concrete syntax.
- **Structs**: `User` shows the simple “one slot per field” layout; `PackedData` shows how grouping small types reclaims a slot. `registerUser` writes directly to storage to avoid extra memory copies, while `getUser` copies to memory before returning multiple values.
- **Owner pattern**: The constructor sets `owner` once—seed for the access-control modifiers you’ll formalize in Project 04.

## ✅ Key Takeaways & Common Pitfalls

- Events are the cheap history channel; keep queryable state in storage and log context in events (don’t reverse it).
- Mapping keys that were never written return `0`—track existence separately if `0` is ambiguous.
- Dynamic types (`string`, `bytes`) cost multiple slots; prefer `bytes32` for fixed-size labels and use events for change history.
- Arrays grow via two writes (length + element); unbounded growth can DoS iteration—prefer mappings + events for scalable lists.
- Cache storage reads in memory before emitting events to avoid double `SLOAD`s.

## 🛰️ Real-World Analogies & Fun Facts

- **Elevator vs stairs**: Reading storage is like waiting for an elevator (slow but reaches every floor), while memory is taking the stairs for quick trips that don't persist.
- **DAO fork**: After the 2016 DAO exploit, Ethereum and Ethereum Classic split. That fork reinforced the need for explicit storage rules because replaying history on two chains demanded byte-for-byte determinism.
- **ETH inflation risk**: Large unbounded mappings/arrays increase state size. More state means more chain bloat; if block sizes grow, validators need more resources, which can indirectly pressure issuance to pay for security.
- **Compiler trivia**: The Solidity team ships frequent optimizer improvements; a packed struct can compile down to fewer `SSTORE` opcodes, saving thousands of gas. Run `solc --optimize` to see the difference in bytecode size.
- **Layer 2 tie-in**: Rollups charge mainly for calldata. Returning `bytes32` instead of `string` trims calldata bytes, which can cut fees by 30–60% on optimistic rollups.
- **Deployment automation**: Most production teams use Foundry Scripts or Hardhat scripts to deploy. This ensures consistency and allows for automated verification, which is critical for security audits.
- **Testing importance**: Every major Ethereum hack (DAO, Parity, etc.) could have been prevented with better testing. Writing comprehensive tests is not optional - it's essential.
- **Creator trivia**: Solidity was co-designed by Gavin Wood and Christian Reitwiessner; they favored explicit types so compilers (Solc) could map human code to tight EVM bytecode without ambiguity.

## ✅ Completion Checklist

- [ ] Implemented skeleton contract (`src/DatatypesStorage.sol`)
- [ ] Created deployment script (`script/DeployDatatypesStorage.s.sol`)
- [ ] Wrote comprehensive test suite (`test/DatatypesStorage.t.sol`)
- [ ] All tests pass (`forge test`)
- [ ] Deployment script works locally (`forge script --broadcast`)
- [ ] Read and understood solution contract (`src/solution/`)
- [ ] Read and understood solution script (`script/solution/`)
- [ ] Read and understood solution tests (`test/solution/`)
- [ ] Compared gas costs (`forge test --gas-report`)
- [ ] Experimented with different data types and locations
- [ ] Can explain storage vs memory vs calldata
- [ ] Can calculate struct packing savings
- [ ] Understands Foundry Script cheatcodes and broadcast pattern
- [ ] Understands Foundry testing patterns and best practices

## 🚀 Next Steps

Once comfortable with datatypes, storage, deployment scripts, and testing:

- Move to [Project 02: Functions & Payable](../02-functions-and-payable/)
- Experiment with the contract in Remix IDE
- Deploy to a testnet and interact with your contract
- Try deploying with constructor parameters
- Explore multi-step deployment scripts
- Learn more advanced testing techniques (invariant testing, fork testing)

## 💡 Pro Tips

1. **Always specify data locations** for reference types in functions
2. **Use `calldata` for external function parameters** (cheapest)
3. **Pack structs carefully** - group small types together
4. **Use `uint256` for local variables** (gas-optimized by EVM)
5. **Only use smaller types (`uint8`, `uint128`) in structs** for packing
6. **Always use `vm.envOr()` for sensitive values** - never hardcode keys
7. **Test deployments locally first** - Anvil is your friend
8. **Write tests as you code** - don't wait until the end
9. **Use fuzz testing** - it finds bugs you never thought of
10. **Read the solution files** - but only after you've tried yourself

---

**Ready to code?** Start with `src/DatatypesStorage.sol`, then create your deployment script and test suite! Remember: the best way to learn is by doing. Don't be afraid to make mistakes - that's how you learn! 🚀

---


## 02-functions-and-payable

# Project 02: Functions & Payable 💰

> **Master Solidity functions, ETH handling, and the `payable` modifier**

## 🎯 Learning Objectives

By completing this project, you will:

1. **Understand function visibility modifiers** (`public`, `external`, `internal`, `private`)
2. **Master the `payable` modifier** and receiving ETH safely
3. **Implement `receive()` and `fallback()`** correctly
4. **Learn modern ETH transfer patterns** (`.call`, not `.transfer` or `.send`)
5. **Track `msg.sender`, `msg.value`, and `address(this).balance`**
6. **Prevent common ETH handling vulnerabilities**
7. **Create Foundry deployment scripts** from scratch
8. **Write comprehensive test suites** using Foundry's testing framework

## 📁 Project Directory Structure

### Understanding `cache/` and `out/` Directories

When you run `forge build` or `forge test`, Foundry generates two important directories:

#### `cache/` Directory

The `cache/` directory contains Foundry's **compilation cache**:
- **Purpose**: Tracks file metadata to determine what needs recompiling
- **Contents**: `solidity-files-cache.json` - stores modification dates, content hashes, imports, and build artifacts
- **Why it exists**: Speeds up compilation by only recompiling files that changed
- **Should you commit it?**: No - it's auto-generated and project-specific

**Real-world analogy**: Like a library's card catalog - it tracks which books (files) exist and when they were last updated, so the librarian (compiler) knows what needs checking.

#### `out/` Directory

The `out/` directory contains **compiled contract artifacts**:
- **Purpose**: Stores all compilation outputs (bytecode, ABIs, metadata)
- **Structure**: One subdirectory per Solidity file that gets compiled - this includes **everything**:
  - ✅ Your contracts (`FunctionsPayable.sol`)
  - ✅ Your tests (`FunctionsPayable.t.sol`)
  - ✅ Your scripts (`DeployFunctionsPayable.s.sol`)
  - ✅ **All forge-std library files** (`Base.sol`, `Test.sol`, `Script.sol`, `Vm.sol`, `console.sol`, etc.)
  - ✅ **All Std* helper contracts** (`StdAssertions.sol`, `StdChains.sol`, `StdCheats.sol`, `StdStorage.sol`, etc.)
  - ✅ **Interface contracts** (`IMulticall3.sol`)
  - ✅ **Any imported dependencies**

- **Why so many subdirectories?**: Foundry compiles **every Solidity file** that your project uses, including all dependencies from `forge-std` and other libraries. Each file gets its own directory with JSON artifacts, even if you didn't write it yourself!
- **What's in each JSON file?**:
  - `bytecode.object`: Deployment bytecode (constructor + contract code)
  - `deployedBytecode.object`: Runtime bytecode (what's stored on-chain)
  - `abi`: Application Binary Interface (function signatures, events, errors)
  - `metadata`: Compiler version, settings, source mappings
- **Should you commit it?**: No - it's auto-generated and can be rebuilt with `forge build`

**Real-world analogy**: Like a factory's finished goods warehouse - each product (contract) gets its own shelf (subdirectory) with all its documentation (JSON artifacts) stored together.

**Pro tip**: You can extract ABIs for frontend integration:
```bash
# Extract ABI for your contract
cat out/FunctionsPayable.sol/FunctionsPayable.json | jq '.abi' > abi.json
```

## 📚 Key Concepts

### Why This Matters: Functions That Handle Real Money

Traditional code only moves numbers in RAM. A Solidity function can move **real money** on a shared ledger that never forgets. Designing a payable function is closer to wiring funds at a bank than calling a local method: identity (`msg.sender`), amount (`msg.value`), and side effects (gas limits, reentrancy) all matter.

**FIRST PRINCIPLES: What Makes Solidity Functions Different?**

In traditional programming languages, functions are just code blocks that process data. In Solidity, functions are **state transition functions** that:
1. **Cost real money** (gas fees) to execute
2. **Move real value** (ETH) between accounts
3. **Permanently modify** a shared global state (the blockchain)
4. **Cannot be undone** once included in a block (immutability)

**COMPARISON TO OTHER LANGUAGES:**

**Python**: 
```python
def deposit(amount):
    balance += amount  # Just numbers in memory, free to execute
```
- No gas cost
- No real money involved
- Can be undone (rollback, debugger)
- Local to your program

**Go**:
```go
func deposit(amount uint256) {
    balance += amount  // Just numbers, no money
}
```
- No gas cost
- No real money involved
- Can be undone
- Local to your program

**Rust**:
```rust
fn deposit(amount: u256) {
    balance += amount;  // Just numbers, no money
}
```
- No gas cost
- No real money involved
- Can be undone
- Local to your program

**Solidity**:
```solidity
function deposit() public payable {
    balances[msg.sender] += msg.value;  // REAL ETH permanently recorded!
}
```
- Costs gas (real money)
- Moves real ETH (native currency)
- Cannot be undone (immutable blockchain)
- Global state (all nodes see it)

**REAL-WORLD ANALOGY**: Traditional functions are like writing in a notebook - you can erase, edit, or throw it away. Solidity functions are like engraving in stone - permanent, expensive, and visible to everyone forever.

**CONNECTION TO PROJECT 01**: Remember how we learned about storage costs (~20k gas per write)? Here we're using those same storage operations (`balances[msg.sender] += msg.value`), but now we're also handling the **native currency** (ETH) that powers the entire network. The `balances` mapping we use here is the same mapping type we learned about in Project 01!

**HISTORICAL CONTEXT**: Solidity exists because Ethereum needed a contract language that compiles deterministically to EVM bytecode. Gavin Wood sketched the first version so every node could run the *exact* same bytecode without ambiguity. Today the Solidity team still optimizes the compiler (Solc) to shrink bytecode and reorder operations safely. The `payable` keyword was added to make ETH handling explicit and prevent accidental fund acceptance.

### ETH: The Native Currency

ETH is the native asset tracked directly by the EVM. It is measured in **wei** (1 ETH = 10^18 wei) and can be sent to EOAs or contracts.

**FIRST PRINCIPLES: What is ETH?**

ETH is fundamentally different from ERC20 tokens:
- **ETH**: Built into the EVM itself, tracked at the protocol level
- **ERC20 tokens**: Smart contracts that simulate currency using storage mappings

**Key Properties**:
- Not a token contract - tracked by EVM itself (no contract address needed)
- Measured in wei (smallest unit, like cents to dollars)
- Can be sent to EOAs (Externally Owned Accounts) or contracts
- Contracts must explicitly accept ETH (via `payable` modifier)
- Cannot be "minted" by contracts (only by protocol rewards)
- Cannot be "burned" by contracts (only sent to address(0))

**UNDERSTANDING WEI**:
```
1 ETH = 1,000,000,000,000,000,000 wei (10^18)
1 gwei = 1,000,000,000 wei (10^9)  // Common unit for gas prices
```

**Why wei?** The EVM works with integers, not decimals. Using wei (the smallest unit) allows precise calculations without floating-point errors. This is critical for financial applications!

**REAL-WORLD ANALOGY**: 
- **ETH** = Cash (native currency, accepted everywhere, no contract needed)
- **ERC20 tokens** = Gift cards (require a contract to track balances, can be rejected)

**CONNECTION TO PROJECT 01**: Remember the `balances` mapping we used? That's exactly what ERC20 tokens use internally! But ETH doesn't need a mapping - it's tracked directly by the EVM. When you check `address(this).balance`, you're reading from the EVM's native balance tracking, not from contract storage.

**GAS COST COMPARISON**:
- Reading `address(this).balance`: ~100 gas (SLOAD from special EVM storage)
- Reading `token.balanceOf(address)`: ~100 gas (SLOAD from contract storage)
- Both are similar cost, but ETH balance is "built-in" while token balance requires a contract call

### Ways to Send ETH: The Evolution of Transfer Methods

**FIRST PRINCIPLES: Why Three Different Methods?**

Solidity has evolved its ETH transfer methods over time. Each method has different gas forwarding behavior, which became critical after gas repricing events.

| Method | Gas limit | Reverts on failure? | Return value | Recommendation |
|--------|-----------|---------------------|--------------|----------------|
| `transfer()` | 2,300 | Yes | None | ❌ Avoid (breaks on smart wallets) |
| `send()` | 2,300 | No | `bool` | ❌ Avoid (limited gas) |
| `call{value:}()` | All remaining | No | `(bool, bytes)` | ✅ Use (modern standard) |

**UNDERSTANDING THE SYNTAX**:

```solidity
// OLD WAY (deprecated):
payable(recipient).transfer(amount);  // Hardcoded 2,300 gas limit

// OLD WAY (deprecated):
bool success = payable(recipient).send(amount);  // Hardcoded 2,300 gas limit

// MODERN WAY (recommended):
(bool success, bytes memory data) = payable(recipient).call{value: amount}("");
require(success, "Transfer failed");
```

**BREAKING DOWN `.call{value:}()`**:
- `payable(recipient)`: Converts address to payable address (required for ETH transfers)
- `.call{value: amount}`: Low-level call with ETH value attached
- `("")`: Empty calldata (no function call, just ETH transfer)
- Returns `(bool success, bytes memory data)`: Success status and return data

**WHY `.call` IS BETTER: Historical Context**

**2016 DAO Fork**: After the DAO exploit, Ethereum hard-forked. This led to gas repricing (EIP-150) to prevent similar attacks.

**2019 Istanbul Fork**: Gas costs were repriced again (EIP-1884), increasing `SLOAD` from 200 to 800 gas. This broke many contracts using `.transfer()`.

**The Problem**: `.transfer()` and `.send()` forward exactly 2,300 gas. This was fine for simple EOAs, but:
- Smart contract wallets (Gnosis Safe, Argent) need more gas for their fallback functions
- Gas repricing made 2,300 gas insufficient for many operations
- Contracts started failing unexpectedly

**The Solution**: `.call{value:}()` forwards **all remaining gas**, making it:
- Compatible with smart contract wallets
- Future-proof against gas repricing
- More flexible (can call functions, not just send ETH)

**GAS COST BREAKDOWN**:

**Using `.transfer()`**:
```
Base transaction: ~21,000 gas
Transfer operation: ~2,100 gas
Gas forwarded: 2,300 gas (fixed)
Total: ~23,100 gas
```

**Using `.call{value:}()`**:
```
Base transaction: ~21,000 gas
Call operation: ~2,100 gas
Gas forwarded: All remaining (flexible!)
Total: ~23,100+ gas (depends on remaining gas)
```

**REAL-WORLD ANALOGY**: 
- `.transfer()` = Vending machine (exact change only, no flexibility)
- `.send()` = Vending machine with return slot (can fail silently)
- `.call{value:}()` = Cashier (handles any amount, tells you if it worked, flexible)

**CONNECTION TO PROJECT 01**: Remember how we learned about storage costs? When you send ETH using `.call`, you're not writing to storage - you're modifying the EVM's native balance tracking. This is why ETH transfers are cheaper than updating a token balance mapping!

**SECURITY CONSIDERATION**: Always check the return value of `.call`! Silent failures can strand funds. Never use `.send()` without checking the return value.

### Function Visibility: Controlling Access and Gas Costs

**FIRST PRINCIPLES: Why Visibility Matters**

In Solidity, function visibility controls:
1. **Who can call** the function (access control)
2. **How data is passed** (gas efficiency)
3. **Code organization** (internal vs external APIs)

**UNDERSTANDING THE FOUR LEVELS**:

#### 1. **`public`**: Callable from Anywhere

```solidity
function deposit() public payable {
    // Can be called externally (from EOAs, other contracts)
    // Can be called internally (from this contract)
}
```

**Properties**:
- Callable externally (from EOAs, other contracts)
- Callable internally (from this contract)
- Auto-generates getter for state variables
- Copies calldata to memory (~200 gas overhead for arrays/structs)

**When to use**: Functions that need to be called both internally and externally.

**GAS COST**: 
- Simple parameters: ~21,000 gas (base transaction)
- Arrays/structs: +200 gas (memory copy overhead)

**COMPARISON TO OTHER LANGUAGES**:
- **Python**: No visibility keywords (everything is public by convention)
- **Go**: Capitalized = exported (public), lowercase = package-private
- **Rust**: `pub` keyword for public, no keyword for private
- **Solidity**: Explicit visibility required (compiler enforces it)

#### 2. **`external`**: Only Callable from Outside

```solidity
function deposit() external payable {
    // Can be called externally (from EOAs, other contracts)
    // CANNOT be called internally without this.deposit()
}
```

**Properties**:
- Only callable externally (from EOAs, other contracts)
- NOT callable internally (must use `this.functionName()` if needed)
- Most gas-efficient for arrays/structs (uses calldata directly, no memory copy)
- Cannot be called internally without external call syntax

**When to use**: Public API functions that are never called internally, especially with array/struct parameters.

**GAS COST**: 
- Simple parameters: ~21,000 gas (base transaction)
- Arrays/structs: No extra overhead (reads directly from calldata)

**GAS SAVINGS**: ~200 gas per call for functions with array/struct parameters!

**REAL-WORLD ANALOGY**: `public` is like a public phone booth (anyone can use it, but it costs more). `external` is like a drive-through window (only external access, but faster/cheaper).

#### 3. **`internal`**: Callable from This Contract and Derived Contracts

```solidity
function _calculateFee(uint256 amount) internal pure returns (uint256) {
    // Can be called from this contract
    // Can be called from contracts that inherit this
    // CANNOT be called externally
}
```

**Properties**:
- Callable from this contract
- Callable from contracts that inherit this (inheritance)
- NOT callable externally
- Perfect for helper functions and shared logic

**When to use**: Helper functions, shared logic in inheritance hierarchies, internal building blocks.

**COMPARISON TO OTHER LANGUAGES**:
- **Python**: Single underscore prefix `_internal_func()` (convention)
- **Go**: Lowercase (package-private, similar concept)
- **Rust**: `pub(crate)` or no `pub` keyword
- **Solidity**: Explicit `internal` keyword

**INHERITANCE EXAMPLE**:
```solidity
contract Parent {
    function internalFunction() internal pure returns (string memory) {
        return "internal";
    }
}

contract Child is Parent {
    function callInternal() public pure returns (string memory) {
        return internalFunction();  // ✅ OK: inherits access
    }
}
```

#### 4. **`private`**: Only Callable from This Exact Contract

```solidity
function _validateInput(uint256 amount) private pure {
    // Can be called from this contract ONLY
    // CANNOT be called from derived contracts
    // CANNOT be called externally
}
```

**Properties**:
- Only callable from this exact contract
- NOT callable from derived contracts (unlike `internal`)
- NOT callable externally
- Most restricted visibility

**When to use**: Implementation details, functions that should never be overridden, sensitive logic encapsulation.

**SECURITY NOTE**: "Private" doesn't mean encrypted! All blockchain data is public. Visibility only controls **who can call** the function, not **who can see** the code or data.

**COMPARISON TO OTHER LANGUAGES**:
- **Python**: Double underscore prefix `__private_func()` (name mangling)
- **Go**: Lowercase (similar concept)
- **Rust**: No `pub` keyword
- **Solidity**: Explicit `private` keyword

**INHERITANCE EXAMPLE**:
```solidity
contract Parent {
    function privateFunction() private pure returns (string memory) {
        return "private";
    }
}

contract Child is Parent {
    function callPrivate() public pure returns (string memory) {
        return privateFunction();  // ❌ ERROR: not accessible
    }
}
```

**GAS OPTIMIZATION SUMMARY**:

| Visibility | Gas Cost (arrays) | Use Case |
|------------|------------------|----------|
| `external` | Lowest (~200 gas saved) | Public APIs with arrays/structs |
| `public` | Medium (+200 gas overhead) | Functions called internally + externally |
| `internal` | N/A (not callable externally) | Helper functions |
| `private` | N/A (not callable externally) | Implementation details |

**CONNECTION TO PROJECT 01**: Remember how we learned about `calldata` vs `memory`? `external` functions can use `calldata` directly (cheaper), while `public` functions must copy to `memory` first (more expensive). This is why `external` saves gas for complex parameters!

### The `payable` Modifier: Explicit ETH Acceptance

**FIRST PRINCIPLES: Why Explicit Opt-In?**

Solidity requires explicit `payable` declaration to prevent accidental ETH acceptance. This is a security feature that prevents contracts from receiving ETH they can't handle.

**UNDERSTANDING THE SYNTAX**:

```solidity
// WITHOUT payable: Rejects ETH
function deposit() public {
    // If someone sends ETH, transaction REVERTS
    // msg.value is not accessible
}

// WITH payable: Accepts ETH
function deposit() public payable {
    // Can receive ETH
    // msg.value contains the amount sent (in wei)
    balances[msg.sender] += msg.value;
}
```

**WHAT HAPPENS WITHOUT `payable`**:

```solidity
contract NonPayable {
    function deposit() public {
        // No payable modifier
    }
}

// When called with ETH:
contract.deposit{value: 1 ether}();  // ❌ REVERTS!
// Error: "Function is not payable"
```

**WHAT HAPPENS WITH `payable`**:

```solidity
contract Payable {
    function deposit() public payable {
        // Can receive ETH
        // msg.value = 1 ether (in wei: 1000000000000000000)
    }
}

// When called with ETH:
contract.deposit{value: 1 ether}();  // ✅ SUCCESS!
// msg.value = 1000000000000000000 wei
```

**UNDERSTANDING `msg.value`**:

- **Type**: `uint256`
- **Unit**: Always in **wei** (smallest unit)
- **Scope**: Available in payable functions
- **Value**: Amount of ETH sent with the call

```solidity
function deposit() public payable {
    uint256 weiSent = msg.value;  // Always in wei!
    
    // Common conversions:
    // 1 ether = 10^18 wei
    // 1 gwei = 10^9 wei
    
    require(msg.value >= 1 ether, "Minimum 1 ETH");
    // This checks: msg.value >= 1000000000000000000 wei
}
```

**GAS COST IMPACT**:

- Functions without `payable`: No gas difference (just rejects ETH)
- Functions with `payable`: No extra gas cost (just enables ETH acceptance)
- The ETH transfer itself costs gas (separate from function execution)

**REAL-WORLD ANALOGY**: 
- **Without `payable`**: Like a vending machine with a locked coin slot - money bounces back
- **With `payable`**: Like an open cash register drawer - accepts money and processes it

**CONNECTION TO PROJECT 01**: Remember how we learned about mappings? Here we're using `balances[msg.sender] += msg.value` - the same mapping pattern from Project 01! The `payable` modifier is what allows us to access `msg.value` (the ETH amount sent).

**SECURITY CONSIDERATIONS**:

1. **Always validate `msg.value > 0`** if you require ETH:
   ```solidity
   require(msg.value > 0, "Must send ETH");
   ```

2. **Don't forget to handle received ETH**:
   ```solidity
   function deposit() public payable {
       // ❌ BAD: Receives ETH but doesn't track it
       // ETH is stuck in contract!
       
       // ✅ GOOD: Track the deposit
       balances[msg.sender] += msg.value;
   }
   ```

3. **Consider what happens if ETH is sent accidentally**:
   - Use `receive()` or `fallback()` to handle unexpected ETH
   - Or revert if you don't want to accept ETH

**COMPARISON TO OTHER LANGUAGES**:
- **Python/Go/Rust**: No concept of "payable" - functions don't handle money
- **Solidity**: Explicit `payable` required - makes ETH handling intentional

**CONSTRUCTOR PAYABLE**:

```solidity
constructor() payable {
    // Can receive ETH during deployment
    // Useful for initial funding
}

// Deployment with ETH:
new MyContract{value: 10 ether}();
```

**Why payable constructor?** Allows contracts to receive initial funding during deployment. Common in DeFi protocols for liquidity pools, reward pools, etc.

### `receive()` vs `fallback()`: Special Functions for ETH Handling

**FIRST PRINCIPLES: Why Special Functions?**

When ETH is sent to a contract, Solidity needs to know what function to call. These special functions handle cases where:
1. No function signature matches
2. ETH is sent without calling a specific function
3. Unknown function calls occur

**UNDERSTANDING THE DECISION TREE**:

```
ETH sent to contract
    ↓
Is msg.data empty?
    ├─ YES → Does receive() exist?
    │          ├─ YES → Call receive()
    │          └─ NO → Call fallback() (if exists and payable)
    │
    └─ NO → Does function signature match?
               ├─ YES → Call matching function
               └─ NO → Call fallback() (if exists)
```

#### `receive()`: The Plain ETH Handler

**SYNTAX**:
```solidity
receive() external payable {
    // Handle plain ETH transfers (no function call)
    emit Received(msg.sender, msg.value);
}
```

**PROPERTIES**:
- Called when ETH is sent with **empty calldata** (`msg.data` is empty)
- Must be `external payable` (required keywords)
- No arguments, no return value
- Cannot access `msg.data` (it's empty anyway)
- Think: "plain envelope with just money inside"

**WHEN IS IT CALLED?**:
```solidity
// These all trigger receive():
address(contract).transfer(1 ether);
address(contract).send(1 ether);
address(contract).call{value: 1 ether}("");
contract.receive{value: 1 ether}();  // If receive() exists
```

**GAS CONSIDERATIONS**:
- When called via `.transfer()` or `.send()`: Only 2,300 gas available!
- When called via `.call{value:}()`: All remaining gas available
- Keep logic minimal if you want to support `.transfer()` calls

**REAL-WORLD ANALOGY**: Like an ATM slot - it only accepts cash (ETH) with no instructions. Just drop money in, and it's accepted.

#### `fallback()`: The Catch-All Handler

**SYNTAX**:
```solidity
// Payable version (can receive ETH):
fallback() external payable {
    // Handle unknown function calls or ETH with data
    emit FallbackCalled(msg.sender, msg.value, msg.data);
}

// Non-payable version (cannot receive ETH):
fallback() external {
    // Handle unknown function calls (no ETH)
    emit FallbackCalled(msg.sender, 0, msg.data);
}
```

**PROPERTIES**:
- Called when:
  1. Function signature doesn't match any function
  2. ETH sent with data but no `receive()` exists
  3. ETH sent with empty data but no `receive()` exists
- Can be `payable` or not (your choice)
- Can access `msg.data` (full calldata available)
- Think: "mystery package - we don't know what it is"

**UNDERSTANDING `msg.data`**:
```solidity
fallback() external payable {
    bytes memory data = msg.data;  // Full calldata
    
    // First 4 bytes = function selector (if function call)
    // Remaining bytes = encoded arguments
    
    if (data.length >= 4) {
        bytes4 selector = bytes4(data[:4]);
        // Check what function was attempted
    }
}
```

**WHEN IS IT CALLED?**:
```solidity
// Unknown function call:
contract.unknownFunction();  // → fallback()

// ETH with data but no receive():
contract.someFunction{value: 1 ether}();  // If function doesn't exist → fallback()

// ETH with empty data but no receive():
address(contract).transfer(1 ether);  // If no receive() → fallback()
```

**USE CASES**:
1. **Proxy Patterns**: Forward all calls to implementation
2. **Catch-All Logging**: Log all unknown calls
3. **Accept ETH**: If you want to accept ETH but don't have `receive()`

**SECURITY WARNING**: Don't blindly trust `msg.data`! Attackers can send malicious calldata. Always validate in proxy patterns.

**REAL-WORLD ANALOGY**: Like a mailroom sorting system - it handles packages (calls) that don't match any known recipient. It can accept packages (ETH) or just route them.

**COMPARISON TABLE**:

| Feature | `receive()` | `fallback()` |
|---------|-------------|--------------|
| **When called** | Empty calldata + ETH | Unknown function or no receive() |
| **Must be payable?** | Yes (required) | No (optional) |
| **Can access msg.data?** | No (empty anyway) | Yes (full calldata) |
| **Arguments?** | No | No |
| **Return value?** | No | No |
| **Gas limit (.transfer)** | 2,300 gas | 2,300 gas |
| **Gas limit (.call)** | All remaining | All remaining |

**CONNECTION TO PROJECT 01**: Remember how we learned about events? Both `receive()` and `fallback()` should emit events to track incoming ETH. Events are cheaper than storage (~2k gas vs ~20k gas) and perfect for off-chain indexing!

**BEST PRACTICES**:

1. **Always emit events** in both functions:
   ```solidity
   event Received(address indexed sender, uint256 amount);
   event FallbackCalled(address indexed sender, uint256 amount, bytes data);
   ```

2. **Keep logic minimal** if you want to support `.transfer()`:
   ```solidity
   receive() external payable {
       // ✅ GOOD: Just emit event
       emit Received(msg.sender, msg.value);
   }
   ```

3. **Consider tracking ETH** if needed:
   ```solidity
   receive() external payable {
       // Track untracked ETH (from receive/fallback)
       untrackedFunds += msg.value;
       emit Received(msg.sender, msg.value);
   }
   ```

**COMPARISON TO OTHER LANGUAGES**:
- **Python**: `__call__` magic method (similar concept, but for function calls)
- **Go/Rust**: No direct equivalent (blockchain-specific feature)
- **Solidity**: Special functions for ETH handling (unique to blockchain)

### Checks-Effects-Interactions Pattern: The Golden Rule of Secure ETH Handling

**CRITICAL SECURITY PATTERN** for functions that send ETH or call external contracts.

**FIRST PRINCIPLES: Why Order Matters**

The order of operations in functions that send ETH is critical. If you call external contracts BEFORE updating state, you create a reentrancy vulnerability. The attacker can call your function again before state is updated, draining funds.

**THE THREE PHASES**:

1. **CHECKS**: Validate all conditions (`require` statements)
2. **EFFECTS**: Update state (modify storage)
3. **INTERACTIONS**: External calls (send ETH, call contracts)

**WHY THIS ORDER?** Prevents reentrancy attacks! If you update state BEFORE external calls, a reentrant attacker can't drain funds because the balance is already updated.

**UNDERSTANDING REENTRANCY**:

Reentrancy occurs when:
1. Function A calls external contract B
2. Contract B calls back into function A (re-enters)
3. Function A executes again before completing the first call
4. State hasn't been updated yet, so checks pass again
5. Attacker drains funds

**VULNERABLE EXAMPLE**:
```solidity
// ❌ BAD: External call before state update
function withdraw(uint256 amount) public {
    require(balances[msg.sender] >= amount);  // CHECK ✅
    
    // ❌ INTERACTION BEFORE EFFECT!
    msg.sender.call{value: amount}("");  // Attacker can re-enter here!
    
    balances[msg.sender] -= amount;  // ❌ Too late! Attacker already re-entered
}
```

**Attack Scenario**:
```
1. Attacker calls withdraw(100)
2. Check passes: balance >= 100 ✅
3. ETH sent to attacker's contract
4. Attacker's receive() calls withdraw(100) again
5. Check passes AGAIN (balance not updated yet!) ✅
6. More ETH sent
7. Repeat until contract drained
8. Finally, balance updated (but too late!)
```

**SAFE EXAMPLE**:
```solidity
// ✅ GOOD: State update before external call
function withdraw(uint256 amount) public {
    require(amount > 0, "Amount must be greater than 0");  // CHECK ✅
    require(balances[msg.sender] >= amount, "Insufficient balance");  // CHECK ✅
    
    // ✅ EFFECT BEFORE INTERACTION!
    balances[msg.sender] -= amount;  // Update state FIRST
    
    // ✅ INTERACTION LAST
    (bool success,) = payable(msg.sender).call{value: amount}("");
    require(success, "Transfer failed");
    
    emit Withdrawn(msg.sender, amount);
}
```

**Why This Works**:
```
1. Attacker calls withdraw(100)
2. Check passes: balance >= 100 ✅
3. Balance updated: balance = 0 ✅ (state changed!)
4. ETH sent to attacker's contract
5. Attacker's receive() calls withdraw(100) again
6. Check FAILS: balance = 0 < 100 ❌ (already updated!)
7. Attack fails!
```

**GAS COST BREAKDOWN**:

**Vulnerable Pattern** (wrong order):
```
CHECKS: ~100 gas (SLOAD)
INTERACTIONS: ~2,100 gas (external call)
EFFECTS: ~5,000 gas (SSTORE)
Total: ~7,200 gas
Risk: Reentrancy attack possible!
```

**Safe Pattern** (correct order):
```
CHECKS: ~100 gas (SLOAD)
EFFECTS: ~5,000 gas (SSTORE)
INTERACTIONS: ~2,100 gas (external call)
Total: ~7,200 gas
Risk: Reentrancy attack prevented!
```

**REAL-WORLD ANALOGY**: 
- **Vulnerable**: Like a bar tab - you hand over cash first, then try to close the tab. Someone can order more drinks before you close it!
- **Safe**: Like settling a tab - you close the tab FIRST (update state), then hand over cash. If someone tries to order again, the tab already shows they paid!

**CONNECTION TO PROJECT 01**: Remember how we learned about storage costs? The `balances[msg.sender] -= amount` operation costs ~5,000 gas (warm SSTORE). By doing this BEFORE the external call, we ensure state is updated even if the external call fails or re-enters.

**ADDITIONAL PROTECTIONS**:

While Checks-Effects-Interactions is the foundation, consider:

1. **Reentrancy Guard** (for extra protection):
   ```solidity
   bool private locked;
   
   modifier nonReentrant() {
       require(!locked, "Reentrancy detected");
       locked = true;
       _;
       locked = false;
   }
   ```

2. **Pull-over-Push Pattern** (let users withdraw themselves):
   ```solidity
   // Instead of pushing ETH, let users pull it
   mapping(address => uint256) public pendingWithdrawals;
   
   function withdraw() public {
       uint256 amount = pendingWithdrawals[msg.sender];
       pendingWithdrawals[msg.sender] = 0;  // EFFECT
       payable(msg.sender).call{value: amount}("");  // INTERACTION
   }
   ```

**COMPARISON TO OTHER LANGUAGES**:
- **Python/Go/Rust**: No reentrancy risk (no external calls during execution)
- **Solidity**: Reentrancy is a real threat (contracts can call each other)
- **Solution**: Always update state before external calls

**BEST PRACTICES**:

1. ✅ **Always follow Checks-Effects-Interactions**
2. ✅ **Update state before external calls**
3. ✅ **Use reentrancy guards for extra protection**
4. ✅ **Consider pull-over-push for withdrawals**
5. ✅ **Test with malicious contracts that re-enter**

**COMMON MISTAKES**:

❌ External call before state update
❌ Multiple external calls before state updates
❌ Forgetting to check return values
❌ Not handling failed transfers

## 🔧 What You'll Build

A contract demonstrating:
- Function visibility with practical examples
- `payable` functions for deposits
- `receive()` for empty-call ETH transfers
- `fallback()` for unknown function calls
- Safe withdrawals using checks-effects-interactions
- Balance tracking and queries

Plus:
- **Deployment script** using Foundry Scripts
- **Comprehensive test suite** with fuzz testing and gas benchmarking

## 📝 Tasks

### Task 1: Implement the Smart Contract

Open `src/FunctionsPayable.sol` and implement all the TODOs:

1. **State variables** (owner, balances mapping)
2. **Events** (Deposited, Withdrawn, Received, FallbackCalled)
3. **Payable constructor** that accepts ETH during deployment
4. **`receive()` function** for plain ETH transfers
5. **`fallback()` function** for unknown calls
6. **Deposit functions** (`deposit()`, `depositFor()`)
7. **Withdrawal functions** using checks-effects-interactions pattern
8. **View functions** for balance queries
9. **Visibility demonstrations** (public, external, internal, private)

### Task 2: Create Your Deployment Script

Open `script/DeployFunctionsPayable.s.sol` and implement:

1. Read deployer's private key from environment using `vm.envOr()`
2. Start broadcasting transactions with `vm.startBroadcast()`
3. Deploy the contract (optionally with ETH using `{value: amount}`)
4. Log deployment information using `console.log()`
5. Stop broadcasting with `vm.stopBroadcast()`

**Why deployment scripts?** Reproducible, scriptable deployments that work the same way every time.

### Task 3: Write Your Test Suite

Open `test/FunctionsPayable.t.sol` and write comprehensive tests:

1. Constructor behavior (sets owner, accepts ETH)
2. `receive()` function tests (plain ETH transfers)
3. `fallback()` function tests (unknown calls, ETH with data)
4. Deposit tests (basic deposit, depositFor, events, edge cases)
5. Withdrawal tests (withdraw, withdrawAll, events, edge cases)
6. Owner withdrawal tests (access control, edge cases)
7. View function tests (getBalance, getContractBalance)
8. Visibility tests (public, external, internal, private)
9. Fuzz testing with randomized inputs
10. Gas benchmarking

**Testing Best Practices**:
- Use descriptive test names: `test_FunctionName_Scenario`
- Follow Arrange-Act-Assert pattern
- Use `vm.expectRevert()` for error testing
- Use `vm.expectEmit()` for event testing
- Use `testFuzz_` prefix for fuzz tests

### Task 4: Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/FunctionsPayableSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployFunctionsPayableSolution.s.sol` - Deployment script patterns
- `test/solution/FunctionsPayableSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains function visibility (access control), message passing with value, state machines (CEI pattern)
- **Connections to Project 01**: References storage patterns and builds on them
- **Security Patterns**: Detailed explanation of Checks-Effects-Interactions (CEI) pattern - the most critical security pattern in Solidity
- **Real-World Context**: Examples of how these patterns are used in production DeFi protocols

### Task 5: Compile and Test

```bash
cd 02-functions-and-payable

# Compile contracts
forge build

# Run all tests
forge test

# Run with verbose output
forge test -vvv

# Run with gas reporting
forge test --gas-report

# Run specific test
forge test --match-test test_Deposit
```

### Task 6: Deploy Locally

**⚠️ IMPORTANT: This project runs on LOCAL ANVIL ONLY**

```bash
# Terminal 1: Start Anvil (keep this running)
anvil

# Terminal 2: Deploy
cd 02-functions-and-payable

# Dry run (simulation only)
forge script script/DeployFunctionsPayable.s.sol

# Deploy to local Anvil (with transactions)
forge script script/DeployFunctionsPayable.s.sol \
  --broadcast \
  --rpc-url http://localhost:8545
```

**Environment Setup**:

Create `.env` with Anvil's default accounts (see project files for examples). Use `PRIVATE_KEY` for main deployer, `PRIVATE_KEY_1` through `PRIVATE_KEY_9` for multi-address testing.

### Task 7: Experiment

Try these experiments:
1. Send ETH to contract using `cast send` - which function gets called?
2. Call non-existent function - what happens?
3. Test with smart contract wallet (deploy a simple contract wallet)
4. Measure gas costs: `.transfer()` vs `.call()` vs `.send()`
5. Test reentrancy protection - try to re-enter during withdrawal

## 🧪 Test Coverage

The test suite covers:

- ✅ Constructor behavior (sets owner, accepts ETH)
- ✅ `receive()` function (plain ETH transfers)
- ✅ `fallback()` function (unknown calls, ETH with data)
- ✅ Deposit operations (basic, depositFor, events)
- ✅ Withdrawal operations (withdraw, withdrawAll, events)
- ✅ Owner withdrawal (access control)
- ✅ View functions (balance queries)
- ✅ Function visibility (public, external, internal, private)
- ✅ Edge cases (zero values, insufficient balance, zero address)
- ✅ Fuzz testing with randomized inputs
- ✅ Gas benchmarking

## 🔍 Contract Walkthrough (Solution Highlights)

- **Owner slot**: Constructor pins `owner` in slot 0 to foreshadow the access-control checks you’ll build formally in Project 04.
- **Visibility tour**: `publicSquare`, `externalCube`, `internalDouble`, and `privateTriple` show how the same math changes call semantics (external saves a calldata copy, internal/ private enable optimizer inlining).
- **Payable paths**: `deposit`, `receive`, and `fallback` all credit `balances[msg.sender]` to keep accounting consistent. The fallback stays minimal to avoid reentrancy surprises when unknown selectors hit the contract.
- **Withdrawals and CEI**: `withdraw` debits storage before calling out with `.call{value: amount}("")`, reinforcing the checks-effects-interactions ordering and why `.transfer()`’s 2,300 gas stipend is unsafe post-EIP-1884.
- **Owner withdrawal**: Mirrors production “treasury drain” flows while reminding you to gate by `owner` and to check contract balance first.
- **Helpers**: `viewBalance` surfaces mapping reads for frontends; `demoInternalCall` exercises internal/private visibility from another public function.

## ✅ Key Takeaways & Common Pitfalls

- Always mark ETH-receiving functions `payable`; without it, sends revert and users waste gas.
- Keep fallback logic tiny—every extra opcode widens the attack surface and raises gas for legit callers.
- Update storage before sending ETH (CEI) and always check the boolean returned by `.call`.
- Prefer `.call` over `.transfer`/`.send`; modern wallets and proxies routinely need more than 2,300 gas.
- `external` + `calldata` avoids copying large inputs; switch to `public` when you need internal reuse.

## 🛰️ Real-World Analogies & Fun Facts

- **ATM vs call center**: `receive()` is the ATM slot—silent, only accepts cash. `fallback()` is the call center routing unknown requests.
- **Who built this?** Solidity was started by Gavin Wood and later led by Christian Reitwiessner; it targets the EVM, a stack machine inspired by early CPU designs.
- **Compiler trivia**: Solc lowers code to Yul and can inline small functions; marking helpers `internal` often lets the optimizer erase jumps entirely.
- **Layer 2s**: Rollups reward calldata-efficient APIs. Passing structs by `calldata` instead of `memory` can shave cents off every transaction at scale.
- **Ethereum Classic history**: The DAO exploit and ensuing fork showed why refunds/reverts must be explicit—`throw` (old revert) evolved into structured `revert` and custom errors.
- **ETH inflation risk**: Poorly designed payable contracts that hoard useless state bloat the chain. Bigger state → higher validator costs → upward pressure on issuance to pay for security.
- **Gas repricing impact**: After Istanbul fork (EIP-1884), `SLOAD` cost increased from 200 to 800 gas. This broke many contracts using `.transfer()` which only forwards 2,300 gas. `.call` became the standard.
- **Smart contract wallets**: Modern wallets like Gnosis Safe need more than 2,300 gas for their fallback functions. Using `.transfer()` breaks compatibility - always use `.call`!

## ✅ Completion Checklist

- [ ] Implemented skeleton contract (`src/FunctionsPayable.sol`)
- [ ] Created deployment script (`script/DeployFunctionsPayable.s.sol`)
- [ ] Wrote comprehensive test suite (`test/FunctionsPayable.t.sol`)
- [ ] All tests pass (`forge test`)
- [ ] Deployment script works locally (`forge script --broadcast`)
- [ ] Read and understood solution contract (`src/solution/`)
- [ ] Read and understood solution script (`script/solution/`)
- [ ] Read and understood solution tests (`test/solution/`)
- [ ] Compared gas costs (`forge test --gas-report`)
- [ ] Understand public vs external vs internal vs private
- [ ] Know when `receive()` vs `fallback()` runs
- [ ] Can explain why `.call` is safer than `.transfer`
- [ ] Can spot reentrancy risks in withdrawal code
- [ ] Understands checks-effects-interactions pattern

## 🚀 Next Steps

Once comfortable with functions, payable, and ETH handling:

- Move to [Project 03: Events & Logging](../03-events-and-logging/)
- Deploy to a testnet and practice sending real ETH
- Study reentrancy deeper in [Project 07](../07-reentrancy-and-security/)
- Experiment with smart contract wallets (Gnosis Safe, Argent)

## 💡 Pro Tips

1. **Always check `.call` return values** - silent failures strand funds
2. **Update state BEFORE external calls** - prevents reentrancy
3. **Use `external` functions with `calldata`** for user-facing APIs when possible
4. **Emit events for deposits and withdrawals** - they're cheap and help off-chain tracking
5. **Consider reentrancy guards** for any function that moves ETH
6. **Never use `.transfer()` or `.send()`** - they're deprecated
7. **Test with smart contract wallets** - they need more gas than EOAs
8. **Use `vm.deal()` in tests** to fund addresses with ETH
9. **Use `vm.prank()` to simulate calls from different addresses**
10. **Always test edge cases** - zero values, max values, insufficient balance

---

**Ready to code?** Open `src/FunctionsPayable.sol` and start implementing! Remember: handling ETH is handling real money - be careful! 💰

---


## 03-events-and-logging

# Project 03: Events & Logging 📢

> **Master Solidity events for off-chain indexing and frontend updates**

## 🎯 Learning Objectives

By completing this project, you will:

1. **Understand `event` declaration and `emit` syntax**
2. **Use indexed parameters** for efficient filtering
3. **Connect events to off-chain indexers** (The Graph, Etherscan)
4. **Compare events vs storage** for gas efficiency
5. **Implement event-driven architecture patterns**
6. **Learn how event design choices** ripple into L2 rollups and analytics pipelines
7. **Create Foundry deployment scripts** from scratch
8. **Write comprehensive test suites** using Foundry's testing framework

## 📁 Project Directory Structure

### Understanding `cache/` and `out/` Directories

When you run `forge build` or `forge test`, Foundry generates two important directories:

#### `cache/` Directory

The `cache/` directory contains Foundry's **compilation cache**:
- **Purpose**: Tracks file metadata to determine what needs recompiling
- **Contents**: `solidity-files-cache.json` - stores modification dates, content hashes, imports, and build artifacts
- **Why it exists**: Speeds up compilation by only recompiling files that changed
- **Should you commit it?**: No - it's auto-generated and project-specific

**Real-world analogy**: Like a library's card catalog - it tracks which books (files) exist and when they were last updated, so the librarian (compiler) knows what needs checking.

#### `out/` Directory

The `out/` directory contains **compiled contract artifacts**:
- **Purpose**: Stores all compilation outputs (bytecode, ABIs, metadata)
- **Structure**: One subdirectory per Solidity file that gets compiled - this includes **everything**:
  - ✅ Your contracts (`EventsLogging.sol`)
  - ✅ Your tests (`EventsLogging.t.sol`)
  - ✅ Your scripts (`DeployEventsLogging.s.sol`)
  - ✅ **All forge-std library files** (`Base.sol`, `Test.sol`, `Script.sol`, `Vm.sol`, `console.sol`, etc.)
  - ✅ **All Std* helper contracts** (`StdAssertions.sol`, `StdChains.sol`, `StdCheats.sol`, `StdStorage.sol`, etc.)
  - ✅ **Interface contracts** (`IMulticall3.sol`)
  - ✅ **Any imported dependencies**

- **Why so many subdirectories?**: Foundry compiles **every Solidity file** that your project uses, including all dependencies from `forge-std` and other libraries. Each file gets its own directory with JSON artifacts, even if you didn't write it yourself!
- **What's in each JSON file?**:
  - `bytecode.object`: Deployment bytecode (constructor + contract code)
  - `deployedBytecode.object`: Runtime bytecode (what's stored on-chain)
  - `abi`: Application Binary Interface (function signatures, events, errors)
  - `metadata`: Compiler version, settings, source mappings
- **Should you commit it?**: No - it's auto-generated and can be rebuilt with `forge build`

**Real-world analogy**: Like a factory's finished goods warehouse - each product (contract) gets its own shelf (subdirectory) with all its documentation (JSON artifacts) stored together.

**Pro tip**: You can extract ABIs for frontend integration:
```bash
# Extract ABI for your contract
cat out/EventsLogging.sol/EventsLogging.json | jq '.abi' > abi.json
```

## 📚 Key Concepts

### Why This Matters: Events as the Bridge Between On-Chain and Off-Chain

**FIRST PRINCIPLES: The On-Chain/Off-Chain Divide**

Blockchain contracts run in isolation - they can't directly communicate with external systems. Events solve this by creating a one-way communication channel from contracts to the outside world.

**THE PROBLEM WITHOUT EVENTS**:
```
Frontend needs to know: "Did Alice transfer tokens to Bob?"
Without events:
  - Frontend must constantly poll contract storage (expensive!)
  - Must check every block for changes
  - No efficient way to filter by address
  - High RPC costs, slow updates
```

**THE SOLUTION WITH EVENTS**:
```
Frontend needs to know: "Did Alice transfer tokens to Bob?"
With events:
  - Contract emits Transfer event when transfer happens
  - Indexer (The Graph) listens to events automatically
  - Frontend queries indexer (fast, free, filtered)
  - Real-time updates, efficient filtering
```

**CONNECTION TO PROJECT 01 & 02**:
- **Project 01**: We learned about storage (expensive, ~20k gas per write)
- **Project 02**: We learned about functions and ETH handling
- **Project 03**: Events complement storage - use storage for state, events for history!

**COMPARISON TO OTHER LANGUAGES**:

**Python**:
```python
print("Transfer:", from_addr, to_addr, amount)  # Goes to console, disappears
# No persistence, no searchability
```

**Go**:
```go
log.Printf("Transfer: %s -> %s: %d", from, to, amount)  // Goes to log file
// Persistent but not on-chain, not searchable by contracts
```

**Rust**:
```rust
println!("Transfer: {} -> {}: {}", from, to, amount);  // Console output
// Not persistent, not on-chain
```

**Solidity**:
```solidity
emit Transfer(from, to, amount);  // Permanently stored on blockchain!
// Persistent, searchable, filterable, accessible off-chain
```

**REAL-WORLD ANALOGY**: 
- **Traditional logging** = Writing in a notebook (temporary, local, disappears)
- **Solidity events** = Publishing in a newspaper (permanent, public, searchable forever)

**HISTORICAL CONTEXT**: Solidity (started by Gavin Wood) added events early so frontends could react without polluting storage. The EVM keeps logs in a separate bloom-filtered structure for fast topic search. This design decision enables the entire DeFi ecosystem - without events, frontends would be prohibitively expensive to build!

**GAS EFFICIENCY**: Events cost ~2,000 gas vs ~20,000 gas for storage writes. That's a **10x savings**! This is why events are essential for tracking history without bloating contract storage.

### What Are Events? Understanding the Logging System

**FIRST PRINCIPLES: Events as Write-Only Logs**

Events are **logs** stored on the blockchain that:
- ✅ Cost ~2,000 gas (vs ~20,000 for storage) - **10x cheaper!**
- ✅ Enable off-chain indexing and querying
- ✅ Notify frontends of state changes
- ✅ Permanent and immutable (cannot be deleted)
- ❌ Cannot be read by contracts (write-only)
- 🛰️ Survive chain reorgs with topics that clients can replay deterministically

**UNDERSTANDING THE EVM LOG STRUCTURE**:

The EVM stores events in a special log structure separate from contract storage:

```
Transaction Log Structure:
┌─────────────────────────────────────────┐
│ Block Number: 12345                     │
│ Transaction Hash: 0xABCD...            │
│ Contract Address: 0x1234...            │
│ Event Topics: [topic1, topic2, ...]   │ ← Indexed parameters
│ Event Data: [data1, data2, ...]        │ ← Non-indexed parameters
└─────────────────────────────────────────┘
```

**HOW EVENTS ARE STORED**:

1. **Topics** (Indexed Parameters):
   - Up to 3 indexed parameters per event
   - Stored in bloom filter for fast searching
   - Each topic is 32 bytes (keccak256 hash for non-uint256 types)

2. **Data** (Non-Indexed Parameters):
   - All non-indexed parameters encoded as ABI-encoded data
   - Stored in log data section
   - Can be any size (strings, arrays, etc.)

**CONNECTION TO PROJECT 01**: Remember storage slots? Events use a completely different storage mechanism:
- **Storage**: SSTORE opcode, stored in contract's storage slots
- **Events**: LOG opcodes, stored in transaction logs (separate from storage)

**REAL-WORLD ANALOGY**: 
- **Storage** = The actual inventory (expensive to update, queryable on-chain, like a warehouse)
- **Events** = Receipts (cheap to print, permanent record, searchable off-chain, like transaction receipts)
- **Frontend** = Cash register display (shows events in real-time, like a dashboard)

**WHY WRITE-ONLY?**

Events cannot be read by contracts because:
1. **Gas efficiency**: Reading logs would require expensive operations
2. **Design philosophy**: Events are for off-chain systems, not on-chain logic
3. **Separation of concerns**: State (storage) vs history (events)

**BLOOM FILTERS: The Magic Behind Fast Event Search**

The EVM uses bloom filters to quickly check if an event might exist in a block:
- **Bloom filter**: Probabilistic data structure (fast but may have false positives)
- **Indexed parameters**: Stored in bloom filter for O(1) lookup
- **Why it matters**: Enables fast event filtering without scanning all logs

**EXAMPLE**:
```solidity
event Transfer(address indexed from, address indexed to, uint256 amount);

// Bloom filter stores:
// - keccak256(from) → topic1
// - keccak256(to) → topic2
// - amount → data (not in bloom filter)

// To find all transfers FROM 0x1234...:
// 1. Check bloom filter for topic1 = keccak256(0x1234...)
// 2. If present, scan logs for exact match
// 3. Much faster than scanning all logs!
```

**GAS COST BREAKDOWN**:

**Event Emission**:
- Base cost: ~375 gas (LOG1 opcode)
- Per indexed parameter: +375 gas (LOG2/LOG3/LOG4)
- Per byte of data: +8 gas

**Example**:
```solidity
event Transfer(address indexed from, address indexed to, uint256 amount);
emit Transfer(0x1234..., 0x5678..., 100);

// Gas cost:
// - LOG3 base: ~1,125 gas (3 indexed params)
// - Data (uint256): +32 bytes × 8 gas = +256 gas
// - Total: ~1,381 gas
```

**COMPARISON TO STORAGE**:
- **Event**: ~1,381 gas (for Transfer with 2 indexed params)
- **Storage**: ~20,000 gas (cold write) or ~5,000 gas (warm write)
- **Savings**: ~18,619 gas (cold) or ~3,619 gas (warm)!

**WHEN TO USE EVENTS**:
- ✅ Logging state changes for off-chain systems
- ✅ Tracking transfer history (cheaper than storage arrays)
- ✅ Frontend notifications
- ✅ Analytics and reporting
- ✅ Audit trails

**WHEN NOT TO USE EVENTS**:
- ❌ Data needed by contract logic (use storage)
- ❌ Current state that contracts read (use storage)
- ❌ Values that change frequently and need on-chain access (use storage)

### Indexed Parameters: The Search Feature

**FIRST PRINCIPLES: Why Indexing Matters**

Up to 3 parameters can be `indexed`:
- Allows filtering events by specific values
- Costs ~375 gas extra per indexed param
- Essential for efficient event queries
- Great for L2s because you can stream only the topics you need instead of all calldata

**UNDERSTANDING INDEXED VS NON-INDEXED**:

**Indexed Parameters**:
- Stored as **topics** in the event log
- Included in bloom filter for fast searching
- Limited to 32 bytes (address, uint256, bytes32, etc.)
- Can filter efficiently: "Show me all events where from = 0x1234..."

**Non-Indexed Parameters**:
- Stored as **data** in the event log
- NOT included in bloom filter
- Can be any size (strings, arrays, structs, etc.)
- Cannot filter efficiently: Must read all logs and check data

**HOW INDEXING WORKS**:

```solidity
event Transfer(address indexed from, address indexed to, uint256 amount);

// When emitted:
emit Transfer(0x1234..., 0x5678..., 100);

// Event log structure:
// Topics: [
//   keccak256("Transfer(address,address,uint256)"),  // Event signature
//   keccak256(0x1234...),                            // from (indexed)
//   keccak256(0x5678...)                            // to (indexed)
// ]
// Data: [100]  // amount (non-indexed, ABI-encoded)
```

**GAS COST BREAKDOWN**:

**LOG Opcodes**:
- LOG1 (no indexed): ~375 gas base + 8 gas/byte of data
- LOG2 (1 indexed): ~750 gas base + 8 gas/byte of data
- LOG3 (2 indexed): ~1,125 gas base + 8 gas/byte of data
- LOG4 (3 indexed): ~1,500 gas base + 8 gas/byte of data

**Example Costs**:
```solidity
// Event with 0 indexed params:
event SimpleEvent(uint256 value);
emit SimpleEvent(100);
// Cost: ~375 + (32 bytes × 8) = ~631 gas

// Event with 2 indexed params:
event Transfer(address indexed from, address indexed to, uint256 amount);
emit Transfer(0x1234..., 0x5678..., 100);
// Cost: ~1,125 + (32 bytes × 8) = ~1,381 gas
// Extra cost: ~750 gas for indexing (but enables filtering!)
```

**WHEN TO INDEX**:

✅ **DO Index**:
- Addresses (you'll almost always filter by address)
- Token IDs (for NFT transfers)
- User IDs (for user-specific queries)
- Timestamps (if you need to filter by time range)

❌ **DON'T Index**:
- Large strings (limited to 32 bytes anyway)
- Arrays (can't index arrays directly)
- Structs (can't index structs directly)
- Values rarely filtered (saves gas)

**EXAMPLE - GOOD EVENT DESIGN**:
```solidity
event Transfer(address indexed from, address indexed to, uint256 amount);
// ✅ Addresses indexed (filterable)
// ✅ Amount not indexed (rarely filtered, saves gas)
// ✅ Matches ERC20 standard (compatible with tools)

// Can filter efficiently:
// - "Show me all transfers FROM address X"
// - "Show me all transfers TO address Y"
// - Cannot filter by amount (but that's OK - rarely needed)
```

**EXAMPLE - BAD EVENT DESIGN**:
```solidity
event Transfer(address from, address to, uint256 indexed amount);
// ❌ Addresses not indexed (can't filter efficiently!)
// ❌ Amount indexed (rarely filtered, wastes gas)
// ❌ Breaks ERC20 standard (incompatible with tools)
```

**REAL-WORLD ANALOGY**: 
- **Indexed parameters** = Searchable tags on blog posts (you can search for posts tagged "solidity")
- **Non-indexed parameters** = Full blog post content (you can't efficiently search the full content)

**CONNECTION TO PROJECT 01**: Remember how mappings use keccak256 for storage calculation? Indexed parameters work similarly - they're hashed and stored in a bloom filter for fast lookup!

**L2 ROLLUP CONSIDERATIONS**:

On Layer 2 rollups (Arbitrum, Optimism), calldata is expensive:
- **Indexed params**: Stored as topics (cheaper on L2)
- **Non-indexed params**: Stored as data (more expensive on L2)
- **Best practice**: Index what you'll filter, keep data small

**THE GRAPH INTEGRATION**:

The Graph protocol indexes events for subgraphs:
- Indexed params: Automatically indexed, fast queries
- Non-indexed params: Must be decoded from data, slower queries
- **Best practice**: Design events with indexers in mind!

**FILTERING EXAMPLES**:

```javascript
// Filter by indexed parameter (FAST):
contract.on("Transfer", { from: "0x1234..." }, (event) => {
    console.log("Transfer from 0x1234...!");
});

// Filter by non-indexed parameter (SLOW):
// Must read all Transfer events and check amount
// Not recommended for production!
```

**GAS OPTIMIZATION TIP**:

Only index what you'll actually filter by:
- **3 indexed params**: ~1,500 gas base
- **2 indexed params**: ~1,125 gas base
- **Savings**: ~375 gas per event (if you don't need the 3rd index)

### Events vs Storage: Choosing the Right Tool

**FIRST PRINCIPLES: Complementary, Not Competing**

Events and storage serve different purposes. Understanding when to use each is crucial for efficient contract design.

**COMPREHENSIVE COMPARISON**:

| Aspect | Events | Storage |
|--------|--------|---------|
| **Cost** | ~2,000 gas | ~20,000 gas (cold write) |
| **Readable by contracts?** | ❌ No | ✅ Yes |
| **Readable off-chain?** | ✅ Yes (via logs) | ✅ Yes (via RPC) |
| **Filterable?** | ✅ Yes (indexed params) | ❌ No (must read all) |
| **Permanent?** | ✅ Yes | ✅ Yes |
| **Modifiable?** | ❌ No | ✅ Yes (by contract) |
| **Gas cost per write** | ~1,500-2,000 gas | ~5,000-20,000 gas |
| **Gas cost per read (on-chain)** | N/A (can't read) | ~100-2,100 gas |
| **Use case** | History, logging | Current state |

**CONNECTION TO PROJECT 01 & 02**:

Remember from Project 01:
- **Storage**: SSTORE opcode, ~20k gas (cold) or ~5k gas (warm)
- **Storage reads**: SLOAD opcode, ~2.1k gas (cold) or ~100 gas (warm)

Remember from Project 02:
- We used storage for `balances` mapping (needed for contract logic)
- We emitted events for deposits/withdrawals (needed for off-chain tracking)

**THE GOLDEN RULE**:
- **Storage**: For data contracts need to READ
- **Events**: For data contracts need to LOG (but don't need to read)

**WHEN TO USE EVENTS**:

✅ **Use Events For**:
- Logging state changes for off-chain systems
- Tracking transfer history (cheaper than storage arrays)
- Frontend notifications
- Analytics and reporting
- Audit trails
- Historical data that doesn't need on-chain access

**Example**:
```solidity
// ✅ GOOD: Use events for history
event Transfer(address indexed from, address indexed to, uint256 amount);

function transfer(address to, uint256 amount) public {
    balances[msg.sender] -= amount;  // Storage (needed for logic)
    balances[to] += amount;          // Storage (needed for logic)
    emit Transfer(msg.sender, to, amount);  // Event (for history)
}
```

**WHEN TO USE STORAGE**:

✅ **Use Storage For**:
- Data needed by contract logic
- Current state that contracts read
- Values that change frequently and need on-chain access
- Mappings, arrays, structs needed for computation

**Example**:
```solidity
// ✅ GOOD: Use storage for current state
mapping(address => uint256) public balances;  // Needed for transfers

function transfer(address to, uint256 amount) public {
    require(balances[msg.sender] >= amount);  // Read from storage
    balances[msg.sender] -= amount;          // Write to storage
    balances[to] += amount;                 // Write to storage
}
```

**THE COST COMPARISON**:

**Tracking Transfer History**:

**Option 1: Storage Array** (Expensive):
```solidity
struct Transfer {
    address from;
    address to;
    uint256 amount;
}
Transfer[] public transferHistory;

function transfer(address to, uint256 amount) public {
    // ... transfer logic ...
    transferHistory.push(Transfer(msg.sender, to, amount));
    // Cost: ~20,000 gas (cold) per transfer!
}
```

**Option 2: Events** (Cheap):
```solidity
event Transfer(address indexed from, address indexed to, uint256 amount);

function transfer(address to, uint256 amount) public {
    // ... transfer logic ...
    emit Transfer(msg.sender, to, amount);
    // Cost: ~1,500 gas per transfer!
}
```

**Savings**: ~18,500 gas per transfer! 🎉

**REAL-WORLD ANALOGY**: 
- **Storage** = Your bank account balance (you need to check it frequently, it changes, you need it for transactions)
- **Events** = Your bank statement (history of transactions, you don't need to check it often, but it's useful for records and audits)

**BEST PRACTICE PATTERN**:

```solidity
contract Token {
    // Storage: Current state (needed for logic)
    mapping(address => uint256) public balances;
    
    // Events: History (needed for off-chain systems)
    event Transfer(address indexed from, address indexed to, uint256 amount);
    
    function transfer(address to, uint256 amount) public {
        // 1. Read from storage (needed for logic)
        require(balances[msg.sender] >= amount);
        
        // 2. Update storage (needed for logic)
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        // 3. Emit event (needed for off-chain tracking)
        emit Transfer(msg.sender, to, amount);
    }
}
```

**COMMON MISTAKES**:

❌ **Storing history in storage arrays**:
```solidity
Transfer[] public history;  // ❌ Expensive!
// Use events instead!
```

❌ **Trying to read events from contracts**:
```solidity
// ❌ Can't do this - events are write-only!
uint256 lastTransfer = getLastTransfer();  // Not possible!
```

✅ **Using both appropriately**:
```solidity
mapping(address => uint256) public balances;  // ✅ Storage for state
event Transfer(...);                          // ✅ Events for history
```

**GAS OPTIMIZATION TIP**:

If you need to track history, use events instead of storage arrays:
- **Storage array**: ~20,000 gas per entry (cold)
- **Event**: ~1,500 gas per entry
- **Savings**: ~18,500 gas per entry!

**CONNECTION TO PROJECT 02**: Remember how we emitted events in deposit/withdraw functions? That's the perfect pattern - use storage for balances (needed for logic), events for history (needed for off-chain systems)!

### Event Design Best Practices

1. **Mirror ERC standards**: Use same event names/signatures as ERC20/ERC721 for compatibility
2. **Index addresses**: Almost always index `address` parameters (enables filtering)
3. **Limit indexed params**: Only index what you'll filter by (costs extra gas)
4. **Keep events small**: Large events cost more gas
5. **Use descriptive names**: `Transfer` not `T`, `Deposit` not `Dep`

**Example - Good Event Design**:
```solidity
event Transfer(address indexed from, address indexed to, uint256 amount);
// ✅ Addresses indexed (filterable)
// ✅ Amount not indexed (rarely filtered, saves gas)
// ✅ Matches ERC20 standard (compatible with tools)
```

## 🔍 Deep Dive: Contract Walkthrough

- **Constructor**: Sets `owner` to deployer and mints `1_000_000 * 10**18` in one write—one-time init pattern you'll reuse for ownership (see Project 04). Single multiplication beats loops of `SSTORE`s.
- **transfer**: CEI ordering (Project 02). Two mapping writes follow the Project 01 layout, then the ERC20-style `Transfer` event so off-chain tools can index by `from`/`to`. Emitting after state avoids paying for logs on reverts.
- **approve**: Nested mapping (`owner => spender => allowance`) showcases the double `keccak256` slot math. Direct assignment overwrites old approvals on purpose to match ERC20 and save a read; use `+=` only when you intentionally allow incremental approvals.
- **deposit**: `payable` enables ETH flow (Project 02). Uses `+=` read-modify-write on balances, and the `Deposit` event carries the timestamp instead of storing an extra slot—cheap history, same state.
- **updateStatus**: Demonstrates expensive dynamic strings. Caches the previous status in memory before the write to avoid two `SLOAD`s, emits `StatusChanged` for history, and hints that `bytes32` is a cheaper option for fixed phrases.

## 🔧 What You'll Build

A contract demonstrating:
- Event declarations with indexed parameters
- Emitting events for state changes
- Multiple events for different operations
- Event best practices and patterns
- Practical schemas that mirror ERC20/721 so block explorers and subgraphs can ingest them easily

Plus:
- **Deployment script** using Foundry Scripts
- **Comprehensive test suite** with event verification and fuzz testing

## 📝 Tasks

### Task 1: Implement the Smart Contract

Open `src/EventsLogging.sol` and implement all the TODOs:

1. **State variables** (owner, balances, allowances)
2. **Event declarations** with appropriate indexed parameters
3. **Functions that emit events** for all state changes
4. **Multiple event types** for different operations
5. **Event data structures** that balance filterability and cost

### Task 2: Create Your Deployment Script

Open `script/DeployEventsLogging.s.sol` and implement:

1. Read deployer's private key from environment using `vm.envOr()`
2. Start broadcasting transactions with `vm.startBroadcast()`
3. Deploy the contract
4. Log deployment information using `console.log()`
5. Stop broadcasting with `vm.stopBroadcast()`

**Why deployment scripts?** Reproducible, scriptable deployments that work the same way every time.

### Task 3: Write Your Test Suite

Open `test/EventsLogging.t.sol` and write comprehensive tests:

1. Constructor behavior (sets owner, initial balance)
2. Transfer tests (basic transfer, events, edge cases)
3. Approval tests (approve, events, edge cases)
4. Deposit tests (deposit ETH, events, timestamps)
5. Status update tests (update status, events)
6. Event emission verification using `vm.expectEmit()`
7. Indexed parameter filtering tests
8. Multiple events in single transaction
9. Fuzz testing with randomized inputs
10. Gas benchmarking (events vs storage)

**Testing Best Practices**:
- Use descriptive test names: `test_FunctionName_Scenario`
- Follow Arrange-Act-Assert pattern
- Use `vm.expectEmit()` for event testing
- Use `vm.expectRevert()` for error testing
- Use `testFuzz_` prefix for fuzz tests

### Task 4: Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/EventsLoggingSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployEventsLoggingSolution.s.sol` - Deployment script patterns
- `test/solution/EventsLoggingSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains event-driven architecture, logging vs storage trade-offs, bloom filters for indexed parameters
- **Connections to Projects 01-02**: References storage patterns and function visibility concepts
- **ERC20 Patterns**: Demonstrates Transfer and Approval events that are required by ERC20 standard (Project 08)
- **Real-World Context**: Shows how events enable off-chain indexing and frontend updates

### Task 5: Compile and Test

```bash
cd 03-events-and-logging

# Compile contracts
forge build

# Run all tests
forge test

# Run with verbose output to see events
forge test -vvv

# Run with gas reporting
forge test --gas-report

# Run specific test
forge test --match-test test_Transfer
```

### Task 6: Deploy Locally

**⚠️ IMPORTANT: This project runs on LOCAL ANVIL ONLY**

```bash
# Terminal 1: Start Anvil (keep this running)
anvil

# Terminal 2: Deploy
cd 03-events-and-logging

# Dry run (simulation only)
forge script script/DeployEventsLogging.s.sol

# Deploy to local Anvil (with transactions)
forge script script/DeployEventsLogging.s.sol \
  --broadcast \
  --rpc-url http://localhost:8545
```

**Environment Setup**:

Create `.env` with Anvil's default accounts (see project files for examples). Use `PRIVATE_KEY` for main deployer, `PRIVATE_KEY_1` through `PRIVATE_KEY_9` for multi-address testing.

### Task 7: Experiment

Try these experiments:
1. Query events using `cast logs` - filter by indexed parameters
2. Compare gas costs: emit event vs store in mapping
3. Test with multiple events in one transaction
4. Build a simple frontend that listens to events
5. Measure gas: indexed vs non-indexed parameters

## ✅ Key Takeaways & Common Pitfalls

- Events are ~10x cheaper than storage writes; keep state in storage and history in logs.
- Indexed params (max 3) make filtering possible—log addresses/token IDs, not giant strings.
- Logs are write-only for contracts, so design read paths with storage and view functions.
- Cache storage reads (like the old status) before writing to avoid extra `SLOAD`s.
- Strings/dynamic data are pricey; prefer `bytes32` when the shape is fixed and log the rest.
- Emit after state changes so reverted transactions don't still pay for useless logs.

## 🧪 Test Coverage

The test suite covers:

- ✅ Constructor behavior (sets owner, initial balance)
- ✅ Transfer operations (basic transfer, events, edge cases)
- ✅ Approval operations (approve, events, edge cases)
- ✅ Deposit operations (deposit ETH, events, timestamps)
- ✅ Status updates (update status, events)
- ✅ Event emission verification
- ✅ Indexed parameter filtering
- ✅ Multiple events in single transaction
- ✅ Event data structure validation
- ✅ Gas cost comparisons (events vs storage)
- ✅ Fuzz testing with randomized inputs

## 🛰️ Real-World Analogies & Fun Facts

- **Newspaper vs filing cabinet**: Events are like publishing a newspaper clipping—cheap, widely distributed, but not editable. Storage is a locked filing cabinet—expensive but queryable on-chain.
- **Creator trivia**: Solidity (started by Gavin Wood) added events early so frontends could react without polluting storage. The EVM keeps logs in a separate bloom-filtered structure for fast topic search.
- **DAO fork echo**: Post-DAO fork, explorers replayed logs on both Ethereum and Ethereum Classic. Event schemas with indexed fields made it easier to reconcile divergent histories.
- **Layer 2 twist**: Rollups compress calldata; well-designed, small events keep fees low for subgraphs that monitor L2s like Arbitrum and Optimism.
- **ETH issuance angle**: Storing every checkpoint on-chain bloats state and can pressure validator costs (and therefore issuance). Emitting events instead of writing storage is a small but meaningful way to keep state lean.
- **Compiler fact**: Solc can prune unused event parameters during optimization. Keeping event arguments tight helps the optimizer reduce bytecode size and gas.
- **Bloom filters**: The EVM uses bloom filters to quickly check if an event might exist in a block before doing expensive log searches. This is why indexed parameters are so powerful - they're stored in the bloom filter!
- **The Graph**: Most DeFi frontends use The Graph protocol to index events. Well-designed events make subgraph development much easier.

## ✅ Completion Checklist

- [ ] Implemented skeleton contract (`src/EventsLogging.sol`)
- [ ] Created deployment script (`script/DeployEventsLogging.s.sol`)
- [ ] Wrote comprehensive test suite (`test/EventsLogging.t.sol`)
- [ ] All tests pass (`forge test`)
- [ ] Deployment script works locally (`forge script --broadcast`)
- [ ] Read and understood solution contract (`src/solution/`)
- [ ] Read and understood solution script (`script/solution/`)
- [ ] Read and understood solution tests (`test/solution/`)
- [ ] Compared gas costs (`forge test --gas-report`)
- [ ] Understand indexed vs non-indexed parameters
- [ ] Can query events using web3/ethers
- [ ] Know when to use events vs storage
- [ ] Understand event gas costs
- [ ] Can design event schemas for dApps

## 🚀 Next Steps

After completing this project:

- Move to [Project 04: Modifiers & Access Control](../04-modifiers-and-restrictions/)
- Integrate with The Graph for event indexing
- Build a frontend that listens to events
- Study ERC standards' event patterns (ERC20, ERC721)
- Experiment with event filtering in block explorers

## 💡 Pro Tips

1. **Always emit events for state changes** - they're cheap and essential for off-chain systems
2. **Index addresses** - you'll almost always want to filter by address
3. **Limit indexed params to 3** - that's the EVM maximum
4. **Mirror ERC standards** - makes your contract compatible with existing tools
5. **Use events instead of storage arrays** for history - much cheaper!
6. **Test event emissions** using `vm.expectEmit()` - ensures events are correct
7. **Consider L2 implications** - smaller events = lower fees on rollups
8. **Design for indexers** - think about how The Graph will index your events
9. **Use descriptive event names** - `Transfer` not `T`, `Deposit` not `Dep`
10. **Include timestamps in events** - cheaper than storing separately

---

**Ready to code?** Open `src/EventsLogging.sol` and start implementing! Remember: events are your contract's API for the off-chain world! 📢

---


## 04-modifiers-and-restrictions

# Project 04: Modifiers & Access Control 🔐

> **Implement custom modifiers and access control patterns**

## 🎯 Learning Objectives

By completing this project, you will:

1. **Create custom function modifiers** from scratch
2. **Implement `onlyOwner` pattern** for access control
3. **Understand role-based access control (RBAC)** with nested mappings
4. **Compare DIY vs OpenZeppelin AccessControl** patterns
5. **Learn modifier execution order** and composition
6. **See how access control choices affect** upgradeability, L2 fee profiles, and incident response
7. **Create Foundry deployment scripts** with access control setup
8. **Write comprehensive test suites** for access control scenarios

## 📁 Project Directory Structure

### Understanding Foundry Project Structure

This project follows the same structure as Project 01:

```
04-modifiers-and-restrictions/
├── src/
│   ├── ModifiersRestrictions.sol          # Skeleton contract (your implementation)
│   └── solution/
│       └── ModifiersRestrictionsSolution.sol  # Reference solution
├── script/
│   ├── DeployModifiersRestrictions.s.sol  # Skeleton deployment script (your implementation)
│   └── solution/
│       └── DeployModifiersRestrictionsSolution.s.sol  # Reference solution
├── test/
│   ├── ModifiersRestrictions.t.sol        # Skeleton test suite (your implementation)
│   └── solution/
│       └── ModifiersRestrictionsSolution.t.sol  # Reference solution
├── foundry.toml                           # Foundry configuration
└── README.md                              # This file
```

**Key directories**:
- `src/`: Your contract implementations
- `script/`: Deployment scripts
- `test/`: Test suites
- `solution/`: Reference implementations (study these after completing your own!)

## 📚 Key Concepts

### Function Modifiers: Reusable Access Control Patterns

**FIRST PRINCIPLES: The Decorator Pattern**

Modifiers are reusable checks that run before/after function execution. They implement the decorator pattern - wrapping functions with additional behavior without modifying the function itself.

**UNDERSTANDING THE SYNTAX**:

```solidity
modifier onlyOwner() {
    require(msg.sender == owner, "Not owner");
    _;  // This is where the function body executes
}

function transferOwnership(address newOwner) public onlyOwner {
    owner = newOwner;
}
```

**HOW MODIFIERS WORK**:

```
Function Call Flow:
┌─────────────────────────────────────────┐
│ transferOwnership(newOwner) called     │
│   ↓                                      │
│ onlyOwner modifier executes             │ ← Check: msg.sender == owner?
│   ↓                                      │
│ If check passes: Continue               │
│ If check fails: REVERT                  │ ← Access denied!
│   ↓                                      │
│ Function body executes at _             │ ← Only if check passed
│   ↓                                      │
│ owner = newOwner;                       │ ← Function logic
└─────────────────────────────────────────┘
```

**CONNECTION TO PROJECT 01 & 02**:
- **Project 01**: We learned about storage and mappings
- **Project 02**: We learned about `require()` statements for validation
- **Project 04**: Modifiers combine these concepts - they use `require()` to check conditions before allowing function execution

**WHY USE MODIFIERS?**:

1. **Code Reuse (DRY Principle)**:
   ```solidity
   // ❌ WITHOUT modifiers: Repetitive code
   function transferOwnership(address newOwner) public {
       require(msg.sender == owner, "Not owner");
       owner = newOwner;
   }
   
   function pause() public {
       require(msg.sender == owner, "Not owner");
       paused = true;
   }
   
   // ✅ WITH modifiers: Write once, use everywhere
   modifier onlyOwner() {
       require(msg.sender == owner, "Not owner");
       _;
   }
   
   function transferOwnership(address newOwner) public onlyOwner {
       owner = newOwner;
   }
   
   function pause() public onlyOwner {
       paused = true;
   }
   ```

2. **Cleaner Syntax**: `onlyOwner` is more readable than inline `require()`
3. **Consistency**: Same check logic across all functions (prevents bugs)
4. **Gas Efficiency**: Modifiers compile to internal functions, optimizer can inline them

**GAS COST BREAKDOWN**:

**Modifier Overhead**:
- Base modifier call: ~5 gas (JUMP operation)
- `require()` check: ~3 gas (if passes)
- Total: ~8 gas per modifier (negligible compared to storage operations)

**Comparison**:
- **Inline require**: ~3 gas
- **Modifier**: ~8 gas
- **Difference**: ~5 gas (negligible, but modifiers are cleaner)

**COMPARISON TO RUST**:

**Rust** (similar concept with attribute macros):
```rust
#[only_owner]
fn transfer_ownership(new_owner: Address) {
    // Function body
}
```

**Solidity** (built-in language feature):
```solidity
function transferOwnership(address newOwner) public onlyOwner {
    // Function body
}
```

Both implement the decorator pattern, but Solidity's modifiers are built into the language, while Rust uses macros.

**REAL-WORLD ANALOGY**: 
Modifiers are like security checkpoints. Before you can enter a restricted area (function), you must pass through the checkpoint (modifier) that verifies your credentials (role, ownership, etc.). If you don't have the right credentials, you're denied access (revert).

**COMPILER OPTIMIZATION**:

Modifiers are compiled into internal functions. The Solidity optimizer can inline simple modifiers, so a clean `onlyOwner` often costs only a couple of `JUMPI` opcodes in bytecode. This means modifiers are both clean AND efficient!

### Modifier Execution Order

Modifiers execute in the order they're declared:

```solidity
function example() public modifierA modifierB {
    // Execution: modifierA → modifierB → function body
}
```

**Fun fact**: Modifiers are compiled into internal functions. Solc can inline simple modifiers, so a clean `onlyOwner` often costs only a couple of `JUMPI` opcodes in bytecode.

**Real-world analogy**: Like needing both a boarding pass AND an ID to board a plane - you must pass both checks in order.

### Role-Based Access Control (RBAC): Flexible Permission Systems

**FIRST PRINCIPLES: Beyond Simple Ownership**

RBAC uses roles instead of simple ownership, allowing fine-grained access control. This is a fundamental design pattern in access control systems.

**UNDERSTANDING THE STRUCTURE**:

```solidity
mapping(address => mapping(bytes32 => bool)) public roles;

bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

modifier onlyRole(bytes32 role) {
    require(roles[msg.sender][role], "Missing role");
    _;
}
```

**HOW RBAC WORKS**:

```
Role Assignment:
┌─────────────────────────────────────────┐
│ grantRole(ADMIN_ROLE, alice)            │
│   ↓                                      │
│ roles[alice][ADMIN_ROLE] = true         │ ← Storage write
│   ↓                                      │
│ Alice can now call admin functions      │
└─────────────────────────────────────────┘

Role Check:
┌─────────────────────────────────────────┐
│ pause() called by alice                 │
│   ↓                                      │
│ onlyRole(ADMIN_ROLE) modifier executes  │
│   ↓                                      │
│ Check: roles[alice][ADMIN_ROLE] == true?│ ← Storage read
│   ↓                                      │
│ If true: Continue                       │
│ If false: REVERT                        │
└─────────────────────────────────────────┘
```

**CONNECTION TO PROJECT 01**: 
This uses **nested mappings**! `mapping(address => mapping(bytes32 => bool))` is a mapping of mappings:
- Outer mapping: address → (inner mapping)
- Inner mapping: bytes32 role → bool (has role?)

**Storage Layout** (from Project 01 knowledge):
For account `0x1234...` and role `ADMIN_ROLE`:
```
Storage slot = keccak256(abi.encodePacked(
    keccak256(abi.encodePacked(0x1234..., slot_number)),
    ADMIN_ROLE
))
```

**GAS COST BREAKDOWN**:

**Role Check**:
- SLOAD from nested mapping: ~100 gas (warm) or ~2,100 gas (cold)
- require() check: ~3 gas (if passes)
- Total: ~103 gas (warm) or ~2,103 gas (cold)

**Role Grant**:
- SSTORE to nested mapping: ~5,000 gas (warm) or ~20,000 gas (cold)
- Event emission: ~2,000 gas
- Total: ~7,000 gas (warm) or ~22,000 gas (cold)

**WHY `bytes32` FOR ROLES?**:

1. **Gas-Efficient**: Single storage slot lookup (32 bytes fits in one slot)
2. **Deterministic**: `keccak256("ADMIN_ROLE")` always produces same hash
3. **Flexible**: Can add new roles without changing contract structure
4. **Collision-Resistant**: keccak256 prevents role name collisions

**Alternative Approaches**:

**Option 1: Enum** (Less Flexible):
```solidity
enum Role { NONE, ADMIN, MINTER }
mapping(address => Role) public roles;
// ❌ Problem: Can't add new roles without redeploying
```

**Option 2: String** (Expensive):
```solidity
mapping(address => mapping(string => bool)) public roles;
// ❌ Problem: String storage is expensive (~20k gas)
```

**Option 3: bytes32** (Best):
```solidity
mapping(address => mapping(bytes32 => bool)) public roles;
// ✅ Problem: Gas-efficient, flexible, deterministic
```

**COMPARISON TO RUST** (DSA Concept):

**Rust** (similar pattern with HashMap):
```rust
use std::collections::HashMap;

struct AccessControl {
    roles: HashMap<Address, HashSet<Role>>,
}

impl AccessControl {
    fn has_role(&self, account: Address, role: Role) -> bool {
        self.roles.get(&account)
            .map(|roles| roles.contains(&role))
            .unwrap_or(false)
    }
}
```

**Solidity** (nested mapping):
```solidity
mapping(address => mapping(bytes32 => bool)) public roles;

function hasRole(address account, bytes32 role) public view returns (bool) {
    return roles[account][role];
}
```

Both use hash-based data structures (HashMap in Rust, mapping in Solidity) for O(1) lookup, but Solidity's nested mapping is more gas-efficient for this use case.

**REAL-WORLD ANALOGY**: 
Like a company with different departments - employees have different roles (admin, manager, employee), and each role has different permissions. The roles mapping is like an employee directory that tracks who has which permissions.

**PRINCIPLE OF LEAST PRIVILEGE**:

RBAC enables the principle of least privilege - users only get the minimum permissions they need:
- **Admin**: Can pause/unpause (emergency control)
- **Minter**: Can mint tokens (limited operation)
- **User**: Can only interact with public functions

This reduces attack surface - if a minter's key is compromised, they can't pause the contract!

### Pause Mechanism

Emergency stop pattern for contracts:

```solidity
bool public paused;

modifier whenNotPaused() {
    require(!paused, "Contract paused");
    _;
}

function pause() public onlyOwner {
    paused = true;
}
```

**Why pause?**:
- Emergency response: Stop operations if bug is discovered
- Security: Prevent further damage while fixing issues
- Governance: Allows controlled shutdown

**Real-world analogy**: Like a fire alarm - when activated, all operations stop immediately for safety.

**Connection to Project 02**: Pause checks follow the Checks-Effects-Interactions pattern!

### Modifier Composition

You can chain multiple modifiers:

```solidity
function mint(address to) public onlyRole(MINTER_ROLE) whenNotPaused {
    // Must have MINTER_ROLE AND contract must not be paused
}
```

**Execution order**: Modifiers execute left-to-right, then function body executes.

**Gas consideration**: Each modifier adds ~5 gas overhead. Keep modifiers simple!

**Best practice**: Put cheaper checks first (like `whenNotPaused`) before expensive checks (like role lookups).

## 🔧 What You'll Build

A contract demonstrating:
- Custom modifiers with parameters (`onlyRole(bytes32)`)
- Owner-based access control (`onlyOwner`)
- Role management system (grant/revoke roles)
- Modifier composition and chaining
- Pause mechanism for emergency stops
- Checks-effects-interactions ordering inside modifiers

Plus:
- **Deployment script** that sets up initial roles
- **Comprehensive test suite** covering all access control scenarios

## 📝 Tasks

### Task 1: Implement Custom Modifiers

Open `src/ModifiersRestrictions.sol` and implement:

1. **`onlyOwner` modifier**: Checks `msg.sender == owner`
2. **`onlyRole(bytes32 role)` modifier**: Checks `roles[msg.sender][role]`
3. **`whenNotPaused` modifier**: Checks `!paused`
4. **`whenPaused` modifier**: Checks `paused` (for unpause function)

**Hints**:
- Use `require()` statements for checks
- Use `_;` to indicate where function body executes
- Remember: modifiers execute BEFORE the function body

### Task 2: Implement Access Control Functions

Implement functions that use your modifiers:

1. **`transferOwnership(address newOwner)`**: Uses `onlyOwner`
2. **`grantRole(bytes32 role, address account)`**: Uses `onlyOwner`
3. **`revokeRole(bytes32 role, address account)`**: Uses `onlyOwner`
4. **`pause()`**: Uses `onlyRole(ADMIN_ROLE)`
5. **`unpause()`**: Uses `onlyRole(ADMIN_ROLE)` and `whenPaused`
6. **`incrementCounter()`**: Uses `whenNotPaused`
7. **`mint(address to)`**: Uses `onlyRole(MINTER_ROLE)` and `whenNotPaused`

### Task 3: Create Your Deployment Script

Open `script/DeployModifiersRestrictions.s.sol` and implement:

1. Read deployer's private key from environment using `vm.envOr()`
2. Start broadcasting transactions with `vm.startBroadcast()`
3. Deploy the contract
4. Log deployment information (address, owner, initial roles)
5. (Optional) Grant roles to test addresses
6. Stop broadcasting with `vm.stopBroadcast()`

**Why deployment scripts?** Access control contracts need proper setup - deployment scripts ensure roles are configured correctly.

### Task 4: Write Your Test Suite

Open `test/ModifiersRestrictions.t.sol` and write comprehensive tests:

1. **Constructor tests**: Verify owner and initial roles are set correctly
2. **`onlyOwner` tests**: Verify only owner can call owner-only functions
3. **`onlyRole` tests**: Verify only users with role can call role-gated functions
4. **Role management tests**: Grant/revoke roles, verify changes
5. **Pause tests**: Pause/unpause, verify operations are blocked/allowed
6. **Modifier composition tests**: Verify functions with multiple modifiers work correctly
7. **Edge cases**: Zero address, invalid roles, already granted/revoked roles
8. **Event tests**: Verify events are emitted correctly

**Testing Best Practices**:
- Use `vm.prank()` to simulate different callers
- Use `vm.expectRevert()` for access control failures
- Use descriptive test names: `test_OnlyOwner_RevertsForNonOwner`
- Follow Arrange-Act-Assert pattern

### Task 5: Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/ModifiersRestrictionsSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployModifiersRestrictionsSolution.s.sol` - Deployment script patterns
- `test/solution/ModifiersRestrictionsSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains aspect-oriented programming (modifiers), access control patterns, state machines (pause pattern)
- **Connections to Projects 01-03**: References storage patterns, owner pattern from earlier projects, event emission
- **Generalization**: Shows how manual owner checks from Project 02 become reusable modifiers
- **Real-World Context**: Demonstrates patterns used in production contracts (OpenZeppelin, Uniswap)

### Task 6: Compile and Test

```bash
cd 04-modifiers-and-restrictions

# Compile contracts
forge build

# Run all tests
forge test

# Run with verbose output
forge test -vvv

# Run with gas reporting
forge test --gas-report

# Run specific test
forge test --match-test test_OnlyOwner
```

### Task 7: Deploy Locally

**⚠️ IMPORTANT: This project runs on LOCAL ANVIL ONLY**

```bash
# Terminal 1: Start Anvil (keep this running)
anvil

# Terminal 2: Deploy
cd 04-modifiers-and-restrictions

# Dry run (simulation only)
forge script script/DeployModifiersRestrictions.s.sol

# Deploy to local Anvil (with transactions)
forge script script/DeployModifiersRestrictions.s.sol \
  --broadcast \
  --rpc-url http://localhost:8545
```

### Task 8: Experiment

Try these experiments:
1. Change modifier order - does it affect gas costs?
2. Add a modifier that checks multiple conditions - how does gas change?
3. Compare gas costs: inline `require()` vs modifier
4. Test with multiple roles - verify role combinations work correctly
5. Test pause/unpause flow - verify state transitions

## 🧪 Test Coverage

The test suite covers:

- ✅ Constructor behavior and initial state
- ✅ Owner-only functions (transferOwnership)
- ✅ Role-based functions (grantRole, revokeRole, pause, unpause)
- ✅ Modifier composition (multiple modifiers on one function)
- ✅ Pause mechanism (pause/unpause, operations blocked/allowed)
- ✅ Edge cases (zero address, invalid roles, already granted/revoked)
- ✅ Event emissions verification
- ✅ Access control failures (wrong caller, missing role, paused contract)
- ✅ Gas benchmarking

## 🔍 Contract Walkthrough (Solution Highlights)

- **State + role scaffolding**: `owner`, `paused`, and `counter` sit beside the nested `roles[address][role]` mapping so you can trace every storage write from Projects 01–03. The constructor seeds both `ADMIN_ROLE` and `MINTER_ROLE` for the deployer, so your tests start with one known admin/minter without extra setup.
- **Modifier library**: `onlyOwner`, `onlyRole`, `whenNotPaused`, and `whenPaused` are intentionally tiny—just a `require` each—so you can compose them freely. `transferOwnership` highlights the pattern of caching `owner` once before writing/ emitting, which saves a second SLOAD.
- **Role lifecycle**: `grantRole` / `revokeRole` guard against redundant writes, flip the nested mapping flag, and emit `RoleGranted`/`RoleRevoked` so explorers, bots, and dashboards stay in sync with on-chain authority changes.
- **Circuit breaker**: `pause` (only ADMIN) and `unpause` (ADMIN + `whenPaused`) let you exercise modifier order: role check → pause flag check → function body. Both fire events that double as incident-response alerts for monitoring systems.
- **Usage sites**: `incrementCounter` is the simple “business logic” hook you can call through different modifiers, `mint` demonstrates stacking role + pause guards before any external side effect, and `hasRole` rounds out the API so frontends can query permissions off-chain.

## ✅ Key Takeaways & Common Pitfalls

- Keep modifiers short and reusable; complex logic belongs inside functions where the compiler can better optimize ordering.
- Emit events for every ownership or role change—state alone cannot tell off-chain systems who is in control or when it changed.
- Cache storage reads you plan to reuse in the same function (e.g., old owner for an event) to avoid double `SLOAD`s when modifiers already do heavy lifting.
- Validate inputs inside gated functions (`newOwner != address(0)`, prevent duplicate role grants) to avoid soft-locking the contract or wasting gas on no-ops.
- Order modifiers by cost: cheap checks like `whenNotPaused` should run before nested mapping lookups performed in `onlyRole`.

## 🛰️ Real-World Analogies & Fun Facts

- **Bouncer at a club**: `onlyOwner` is the bouncer checking IDs before anyone enters the function. Stacking modifiers is like needing both a ticket and a VIP wristband.

- **Compiler trivia**: Modifiers are syntactic sugar. Solc desugars them into internal calls, which the optimizer can inline, so keeping modifiers short often reduces gas.

- **Layer 2 tie-in**: Pausing contracts on L2 during incidents prevents costly dispute windows on L1. Cheap role checks (packed `bytes32` roles) make multi-sig admin actions more affordable across chains.

- **ETH inflation risk**: Overly permissive write functions can bloat state. Tight modifiers help limit who can create new storage, indirectly reducing long-term state growth pressure on validator hardware (and issuance).

- **Design history**: Access control libraries evolved after early hacks (e.g., Parity multisig). Clear modifiers make audits and incident response faster.

- **OpenZeppelin patterns**: OpenZeppelin's `Ownable` and `AccessControl` contracts use similar patterns. Learning these fundamentals helps you understand production-grade code.

- **Security importance**: Most hacks involve access control failures. Understanding modifiers deeply is critical for secure smart contract development.

- **DAO fork lesson**: The DAO fork highlighted the need for clear access control. Proper modifiers make it clear who can do what, preventing confusion during incidents.

## ✅ Completion Checklist

- [ ] Implemented custom modifiers (`onlyOwner`, `onlyRole`, `whenNotPaused`, `whenPaused`)
- [ ] Implemented access control functions (transferOwnership, grantRole, revokeRole, pause, unpause)
- [ ] Created deployment script (`script/DeployModifiersRestrictions.s.sol`)
- [ ] Wrote comprehensive test suite (`test/ModifiersRestrictions.t.sol`)
- [ ] All tests pass (`forge test`)
- [ ] Deployment script works locally (`forge script --broadcast`)
- [ ] Read and understood solution contract (`src/solution/`)
- [ ] Read and understood solution script (`script/solution/`)
- [ ] Read and understood solution tests (`test/solution/`)
- [ ] Compared gas costs (`forge test --gas-report`)
- [ ] Experimented with modifier composition
- [ ] Can explain modifier execution order
- [ ] Understands role-based access control patterns
- [ ] Understands pause mechanism and emergency stops

## 🚀 Next Steps

Once comfortable with modifiers and access control:

- Move to [Project 05: Errors & Reverts](../05-errors-and-reverts/)
- Study OpenZeppelin access control contracts (`Ownable.sol`, `AccessControl.sol`)
- Implement time-locked operations (add delays to critical functions)
- Consider how ownership transfers behaved during the Ethereum Classic split
- Learn about multi-sig wallets and their access control patterns
- Explore upgradeable proxy patterns and their access control implications

## 💡 Pro Tips

1. **Always validate inputs in modifiers**: Check for zero address, invalid roles, etc.
2. **Keep modifiers simple**: Complex logic in modifiers is harder to audit
3. **Use events**: Emit events when roles change (helps with off-chain tracking)
4. **Test access control thoroughly**: Most bugs are access control related
5. **Document modifier behavior**: Comments help auditors understand intent
6. **Consider gas costs**: Each modifier adds overhead - don't overuse
7. **Use constants for roles**: `keccak256("ADMIN_ROLE")` is deterministic
8. **Follow Checks-Effects-Interactions**: Even in modifiers!
9. **Test edge cases**: Zero address, already granted roles, etc.
10. **Study OpenZeppelin**: Their patterns are battle-tested

---

**Ready to code?** Start with `src/ModifiersRestrictions.sol`, then create your deployment script and test suite! Remember: access control is critical for security - take your time and test thoroughly! 🔐

---


## 05-errors-and-reverts

# Project 05: Errors & Reverts ⚠️

> **Master error handling and gas-efficient custom errors**

## 🎯 Learning Objectives

By completing this project, you will:

1. **Use `require()`, `revert()`, and `assert()` appropriately**
2. **Implement custom errors** (Solidity 0.8.4+)
3. **Understand gas savings** (~90%) of custom errors vs string messages
4. **Handle error propagation** in external calls
5. **Learn when to use each error type**
6. **Connect revert design** to fork history, compiler choices, and gas economics
7. **Create Foundry deployment scripts** for error-handled contracts
8. **Write comprehensive test suites** for error scenarios

## 📁 Project Directory Structure

### Understanding Foundry Project Structure

This project follows the same structure as Project 01:

```
05-errors-and-reverts/
├── src/
│   ├── ErrorsReverts.sol              # Skeleton contract (your implementation)
│   └── solution/
│       └── ErrorsRevertsSolution.sol   # Reference solution
├── script/
│   ├── DeployErrorsReverts.s.sol      # Skeleton deployment script (your implementation)
│   └── solution/
│       └── DeployErrorsRevertsSolution.s.sol  # Reference solution
├── test/
│   ├── ErrorsReverts.t.sol            # Skeleton test suite (your implementation)
│   └── solution/
│       └── ErrorsRevertsSolution.t.sol  # Reference solution
├── foundry.toml                       # Foundry configuration
└── README.md                          # This file
```

**Key directories**:
- `src/`: Your contract implementations
- `script/`: Deployment scripts
- `test/`: Test suites
- `solution/`: Reference implementations (study these after completing your own!)

## 📚 Key Concepts

### Custom Errors: Gas-Efficient Error Handling

**FIRST PRINCIPLES: Why Custom Errors Matter**

Custom errors were introduced in Solidity 0.8.4+ to provide gas-efficient error handling. They replace expensive string messages with cheap error codes.

**GAS COST COMPARISON**:

```solidity
// ❌ OLD WAY: String message (~2,000 gas)
require(balance >= amount, "Insufficient balance");

// ✅ NEW WAY: Custom error (~200 gas - 90% savings!)
if (balance < amount) revert InsufficientBalance(balance, amount);
```

**GAS BREAKDOWN**:

**String Message**:
- String encoding: ~1,800 gas (depends on length)
- REVERT opcode: ~200 gas
- Total: ~2,000 gas

**Custom Error**:
- Error selector: ~4 bytes (cheap)
- Parameter encoding: ~100 gas (if any)
- REVERT opcode: ~200 gas
- Total: ~200-300 gas

**Savings**: ~1,700-1,800 gas per revert! 🎉

**CONNECTION TO PROJECT 02**:
Remember how we used `require()` with string messages in Project 02? Custom errors replace those expensive strings with cheap error codes. Same functionality, 90% less gas!

**HISTORICAL CONTEXT**: 
Before Solidity 0.4.22, `throw` reverted without data. Modern `revert` opcodes bubble encoded error data, which explorers and off-chain services can parse for better UX. Custom errors (0.8.4+) take this further by making errors gas-efficient.

**L2 ROLLUP CONSIDERATIONS**:
Custom errors shine on L2s: fewer bytes in revert strings means smaller calldata when transactions revert during optimistic rollup dispute games. This reduces L2 fees significantly!

**COMPARISON TO RUST** (Error Handling Pattern):

**Rust** (Result type):
```rust
enum Error {
    InsufficientBalance { available: u256, required: u256 },
    Unauthorized { caller: Address },
}

fn withdraw(amount: u256) -> Result<(), Error> {
    if balance < amount {
        return Err(Error::InsufficientBalance { available: balance, required: amount })
    } else {
        Ok(())
    }
}
```

**Solidity** (Custom errors):
```solidity
error InsufficientBalance(uint256 available, uint256 required);

function withdraw(uint256 amount) public {
    if (balance < amount) {
        revert InsufficientBalance(balance, amount);
    }
    // ...
}
```

Both use typed error structures, but Solidity's custom errors are more gas-efficient because they're encoded at compile time.

**REAL-WORLD ANALOGY**: 
Like using error codes instead of full messages. Error codes are faster to process and cheaper to transmit, but you need a reference guide (ABI) to understand them. Custom errors are like HTTP status codes - efficient and standardized.

### When to Use Each Error Type

**`require()`** - User Input Validation:
- Validates user inputs and external conditions
- Can include a string message (expensive) or custom error (cheap)
- Reverts with remaining gas refunded
- Use for: Input validation, business logic checks, access control

**`revert` with custom error** - Gas-Efficient Errors:
- Most gas-efficient way to revert
- Can include parameters (like `InsufficientBalance(balance, amount)`)
- Reverts with remaining gas refunded
- Use for: All error conditions (preferred over require with strings)

**`assert()`** - Internal Invariants:
- Checks conditions that should NEVER fail if code is correct
- Reverts with NO gas refund (consumes all gas)
- Use for: Internal consistency checks, overflow protection (pre-0.8.0), invariants

**Real-world analogy**:
- `require()`: Like a "STOP" sign - prevents action with a message
- `revert` with custom error: Like a specific error code - precise and efficient
- `assert()`: Like a safety check in a car's engine - if it fails, something is fundamentally wrong

### Custom Error Syntax

```solidity
// Define custom error (outside contract)
error InsufficientBalance(uint256 available, uint256 required);
error Unauthorized(address caller);
error InvalidAmount();

// Use in contract
function withdraw(uint256 amount) public {
    if (balance < amount) {
        revert InsufficientBalance(balance, amount);
    }
    balance -= amount;
}
```

**Why custom errors?**:
- **Gas efficient**: ~200 gas vs ~2,000 gas for string messages
- **Type-safe**: Parameters are typed (like function parameters)
- **Decodable**: Frontends can decode error parameters
- **Flexible**: Can include multiple parameters

**Connection to Project 02**: Custom errors replace string messages in `require()` statements!

### Error Propagation

When a function reverts, the error bubbles up:

```solidity
function a() public {
    b(); // If b() reverts, a() also reverts
}

function b() public {
    revert InsufficientBalance(100, 200);
}
```

**Real-world analogy**: Like a chain reaction - if one link breaks, everything stops.

**Gas consideration**: Reverting early saves gas! Don't continue execution if an error occurs.

## 🔧 What You'll Build

A contract demonstrating:
- `require()` statements with string messages
- Custom errors with parameters
- `assert()` for internal invariants
- Gas-efficient error handling
- Error propagation patterns

Plus:
- **Deployment script** for error-handled contracts
- **Comprehensive test suite** covering all error scenarios

## 📝 Tasks

### Task 1: Define Custom Errors

Open `src/ErrorsReverts.sol` and define custom errors:

1. **`InsufficientBalance(uint256 available, uint256 required)`**: For balance checks
2. **`Unauthorized(address caller)`**: For access control failures
3. **`InvalidAmount()`**: For invalid input amounts
4. **`InvariantViolation()`**: For assert failures

**Hints**:
- Custom errors are defined outside the contract (at file level)
- Use `error` keyword (not `function`)
- Parameters are typed (like function parameters)

### Task 2: Implement Functions with Different Error Types

Implement functions that use different error mechanisms:

1. **`depositWithRequire(uint256 amount)`**: Uses `require()` with string messages
2. **`depositWithCustomError(uint256 amount)`**: Uses custom errors
3. **`withdraw(uint256 amount)`**: Uses custom error with parameters
4. **`checkInvariant()`**: Uses `assert()` for internal checks

### Task 3: Create Your Deployment Script

Open `script/DeployErrorsReverts.s.sol` and implement:

1. Read deployer's private key from environment using `vm.envOr()`
2. Start broadcasting transactions with `vm.startBroadcast()`
3. Deploy the contract
4. Log deployment information
5. (Optional) Test error scenarios
6. Stop broadcasting with `vm.stopBroadcast()`

### Task 4: Write Your Test Suite

Open `test/ErrorsReverts.t.sol` and write comprehensive tests:

1. **`require()` tests**: Verify require statements work correctly
2. **Custom error tests**: Verify custom errors revert correctly
3. **Error parameter tests**: Verify error parameters are correct
4. **`assert()` tests**: Verify assert statements work correctly
5. **Edge cases**: Zero amounts, max values, invalid inputs
6. **Gas comparison**: Compare gas costs of different error types

**Testing Best Practices**:
- Use `vm.expectRevert()` for error testing
- Use `vm.expectRevert(ErrorsReverts.InsufficientBalance.selector)` for custom errors
- Use descriptive test names: `test_DepositWithRequire_RevertsForZeroAmount`
- Test both success and failure cases

### Task 5: Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/ErrorsRevertsSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployErrorsRevertsSolution.s.sol` - Deployment script patterns
- `test/solution/ErrorsRevertsSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains exception handling, gas optimization (custom errors vs strings), invariant checking, transaction atomicity
- **Connections to Projects 01-04**: References storage patterns, function visibility, access control, and error handling in modifiers
- **Gas Optimization**: Demonstrates how custom errors save ~27+ gas per error compared to string messages
- **Real-World Context**: Shows error handling patterns used throughout all production contracts

### Task 6: Compile and Test

```bash
cd 05-errors-and-reverts

# Compile contracts
forge build

# Run all tests
forge test

# Run with verbose output
forge test -vvv

# Run with gas reporting (compare error costs!)
forge test --gas-report

# Run specific test
forge test --match-test test_DepositWithRequire
```

### Task 7: Deploy Locally

**⚠️ IMPORTANT: This project runs on LOCAL ANVIL ONLY**

```bash
# Terminal 1: Start Anvil (keep this running)
anvil

# Terminal 2: Deploy
cd 05-errors-and-reverts

# Dry run (simulation only)
forge script script/DeployErrorsReverts.s.sol

# Deploy to local Anvil (with transactions)
forge script script/DeployErrorsReverts.s.sol \
  --broadcast \
  --rpc-url http://localhost:8545
```

### Task 8: Experiment

Try these experiments:
1. Compare gas costs: `require()` with string vs custom error
2. Test error propagation: Call a function that reverts from another function
3. Test assert failures: What happens when assert fails?
4. Measure gas savings: Use `forge test --gas-report` to see the difference
5. Test error decoding: Can you decode custom error parameters?

## 🧪 Test Coverage

The test suite covers:

- ✅ `require()` with string messages
- ✅ Custom errors with and without parameters
- ✅ Error parameter verification
- ✅ `assert()` statements
- ✅ Edge cases (zero amounts, max values, invalid inputs)
- ✅ Gas comparison between error types
- ✅ Error propagation
- ✅ Error decoding

## 🔍 Contract Walkthrough (Solution Highlights)

- **State & ownership**: `owner`, `balance`, and `totalDeposits` follow the same slot layout from Project 01 so you can reason about storage writes before and after a revert. The constructor pins `owner` for the access checks you formalized in Project 04.
- **`depositWithRequire`**: Keeps the classic `require` + string form around for contrast. It’s intentionally verbose so you can measure bytecode and gas overhead when strings live in production contracts.
- **`depositWithCustomError`**: Repeats the same logic but swaps strings for typed errors. `InvalidAmount()` and `Unauthorized(msg.sender)` show how to pass context without inflating calldata, a pattern we’ll reuse for ERC20/721 reverts.
- **`withdraw`**: Demonstrates parameterized custom errors (`InsufficientBalance(balance, amount)`) so wallets can surface the exact failure. The state write happens only after all checks, reinforcing the CEI discipline from Project 02.
- **`checkInvariant`**: Uses `assert` to lock in `totalDeposits >= balance`; it’s a reminder that Panic codes are for “should never happen” states (think unit-test invariants) while user-facing paths should revert with custom errors.
- **`getBalance`**: Mirrors the auto-generated getter but stays explicit so you can trace a pure storage read when comparing revert vs view costs.

## 🛰️ Real-World Analogies & Fun Facts

- **Airplane checklists**: `require` is the preflight checklist; if anything is missing, you stop before takeoff. `assert` is the "wing still attached" invariant—if it fails, something is fundamentally wrong.

- **Compiler trivia**: Solc emits `REVERT` with ABI-encoded selectors for custom errors, letting frontends decode human-friendly reasons without inflating bytecode with strings.

- **DAO/ETC lesson**: The DAO fork highlighted how clear error surfaces speed up incident response. Ethereum Classic retained the old state; explicit errors made replay analysis easier across chains.

- **ETH inflation angle**: Reverting early prevents wasted gas and failed state writes. Less wasted execution → less pressure for higher base fees → less need for elevated issuance to pay validators.

- **Layer 2**: Short custom errors reduce calldata, which directly lowers fees on rollups and keeps fraud proofs cheaper to verify.

- **Gas savings**: Custom errors save ~90% gas compared to string messages. In high-frequency operations, this adds up quickly!

- **Error decoding**: Modern tools (Etherscan, Foundry, ethers.js) can decode custom errors automatically, making debugging easier.

- **Best practices**: Always use custom errors in production code. String messages are only for development/debugging.

## 🧠 Deep Dive: Computer Science First Principles

- **Revert opcode internals**: Both `require` and `revert` compile down to the `REVERT` opcode, which unwinds the call stack and refunds remaining gas. The payload is ABI-encoded—custom errors shrink that payload while keeping typed data.
- **Panic vs. custom errors**: `assert` triggers a Panic error selector (`0x4e487b71`) that consumes all gas, while `require`/`revert` refund remaining gas. Use Panic only for invariants that must never fail.
- **Call stack bubbling**: Errors propagate up the call stack. External callers should expect and handle bubbled errors (later projects use this for cross-contract UX).
- **Data size economics**: Strings bloat bytecode and calldata. Custom errors keep revert data to a fixed selector + parameters, which is crucial for rollups where calldata drives cost.
- **State updates**: All branches revert before SSTORE writes to ensure state is never partially updated—a nod to transactional consistency from database theory.

## 🔗 How Concepts Build on Each Other

- **From Project 01**: Storage layout knowledge explains why reverts happen before writes; the `getBalance` helper mirrors those storage reads.
- **From Project 02**: The same validation checks now use custom errors for cheaper failures, demonstrating evolution from string-based `require`.
- **From Project 04**: Access control in `depositWithCustomError` uses the same owner gate you built earlier, but returns structured error data.
- **Forward to Project 06**: Arrays/mappings rely on revert reasons for safe bounds checks; the patterns here prepare you for those structures.
- **Forward to Project 08 (ERC20)**: Balance updates and custom errors mirror real token contracts where precise failure reasons improve wallet UX.

## 📝 Key Takeaways & Common Mistakes

- **Prefer custom errors** for production-grade reverts; reserve strings for debugging or console logs.
- **Gate state writes** with validation up front—reverting after partial updates is a classic bug.
- **Use `assert` sparingly**; if you can explain an issue to a user, it should be a `require`/custom error instead of Panic.
- **Always include parameters** when they help debugging (e.g., `InsufficientBalance(balance, amount)`); they add context for free compared to strings.
- **Test revert surfaces** explicitly with `expectRevert` selectors so refactors do not silently change error shapes.

## ✅ Completion Checklist

- [ ] Defined custom errors (`InsufficientBalance`, `Unauthorized`, `InvalidAmount`, `InvariantViolation`)
- [ ] Implemented functions with `require()` statements
- [ ] Implemented functions with custom errors
- [ ] Implemented functions with `assert()` statements
- [ ] Created deployment script (`script/DeployErrorsReverts.s.sol`)
- [ ] Wrote comprehensive test suite (`test/ErrorsReverts.t.sol`)
- [ ] All tests pass (`forge test`)
- [ ] Deployment script works locally (`forge script --broadcast`)
- [ ] Read and understood solution contract (`src/solution/`)
- [ ] Read and understood solution script (`script/solution/`)
- [ ] Read and understood solution tests (`test/solution/`)
- [ ] Compared gas costs (`forge test --gas-report`)
- [ ] Can explain when to use `require()` vs `revert` vs `assert()`
- [ ] Understands gas savings of custom errors
- [ ] Understands error propagation

## 🚀 Next Steps

Once comfortable with errors and reverts:

- Move to [Project 06: Mappings, Arrays & Gas](../06-mappings-arrays-and-gas/)
- Study OpenZeppelin's error patterns
- Learn about error handling in external calls
- Explore try-catch patterns (Solidity 0.6.0+)
- Learn about error handling in upgradeable contracts
- Study gas optimization techniques with custom errors

## 💡 Pro Tips

1. **Always use custom errors**: They're 90% cheaper than string messages
2. **Include parameters in errors**: Makes debugging easier
3. **Use `require()` for user input**: Clear and explicit
4. **Use `assert()` sparingly**: Only for invariants that should never fail
5. **Revert early**: Saves gas by not executing unnecessary code
6. **Test error scenarios**: Most bugs are in error handling
7. **Document error meanings**: Comments help developers understand errors
8. **Use descriptive error names**: `InsufficientBalance` is better than `Error1`
9. **Compare gas costs**: Use `forge test --gas-report` to see savings
10. **Study production code**: See how real projects handle errors

---

**Ready to code?** Start with `src/ErrorsReverts.sol`, then create your deployment script and test suite! Remember: good error handling is critical for user experience and gas efficiency! ⚠️

---


## 06-mappings-arrays-and-gas

# Project 06: Mappings, Arrays & Gas ⛽

> **Master gas-efficient data structures and understand the trade-offs**

## 🎯 Learning Objectives

By completing this project, you will:

1. **Understand mapping storage** and O(1) lookup efficiency
2. **Recognize array iteration costs** and DoS risks
3. **Implement gas-optimized patterns** for balance tracking
4. **Compare iteration vs tracking** approaches
5. **Analyze gas costs** of different data structures
6. **Master caching patterns** to reduce storage reads
7. **Understand unbounded loop risks** and mitigation strategies
8. **Create Foundry deployment scripts** from scratch
9. **Write comprehensive test suites** with gas reporting

## 📁 Project Directory Structure

```
06-mappings-arrays-and-gas/
├── README.md                          # This file
├── foundry.toml                       # Foundry configuration
├── src/
│   ├── MappingsArraysGas.sol        # Skeleton contract (TODO: implement)
│   └── solution/
│       └── MappingsArraysGasSolution.sol  # Complete reference implementation
├── script/
│   ├── DeployMappingsArraysGas.s.sol # Deployment script (TODO: implement)
│   └── solution/
│       └── DeployMappingsArraysGasSolution.s.sol  # Reference deployment
└── test/
    ├── MappingsArraysGas.t.sol        # Test suite (TODO: implement)
    └── solution/
        └── MappingsArraysGasSolution.t.sol  # Reference tests
```

## 🔑 Key Concepts

### Mapping Storage: O(1) Lookups with Hash Tables

**FIRST PRINCIPLES: Hash Table Data Structure**

Mappings provide constant-time O(1) lookups using keccak256 hashing. This is a fundamental hash table data structure implementation.

**UNDERSTANDING THE STRUCTURE**:

```solidity
mapping(address => uint256) public balances;
// Storage slot: keccak256(abi.encodePacked(key, slot_number))
```

**HOW IT WORKS** (DSA Concept):

```
Hash Table Lookup:
┌─────────────────────────────────────────┐
│ Input: address key (0x1234...)          │
│   ↓                                      │
│ Hash: keccak256(key, slot_number)       │ ← O(1) hash operation
│   ↓                                      │
│ Storage slot calculated                  │ ← Direct access
│   ↓                                      │
│ Read value from slot                     │ ← O(1) access
└─────────────────────────────────────────┘

Time Complexity: O(1) - Constant time!
Space Complexity: O(n) - Linear space for n entries
```

**CONNECTION TO PROJECT 01**: 
We learned about mapping storage layout in Project 01. The storage slot calculation uses keccak256 hashing, which is what makes mappings O(1) lookups!

**GAS COSTS** (from Project 01 knowledge):
- Cold read: ~2,100 gas (first access - SLOAD from cold slot)
- Warm read: ~100 gas (recently accessed - SLOAD from warm slot)
- Write: ~5,000 gas (warm SSTORE) or ~20,000 gas (cold SSTORE)

**COMPARISON TO RUST** (DSA Concept):

**Rust** (HashMap):
```rust
use std::collections::HashMap;

let mut balances: HashMap<Address, u256> = HashMap::new();

// Insert: O(1) average case
balances.insert(address, amount);

// Lookup: O(1) average case
let balance = balances.get(&address);
```

**Solidity** (mapping):
```solidity
mapping(address => uint256) public balances;

// Write: O(1) - direct storage write
balances[address] = amount;

// Read: O(1) - direct storage read
uint256 balance = balances[address];
```

Both use hash-based structures for O(1) operations, but Solidity's mapping is more gas-efficient because it's built into the EVM storage model.

**REAL-WORLD ANALOGY**: 
Like a phone book - you know the name (key), you instantly find the number (value). No need to search through pages! The hash function (keccak256) is like the alphabetical organization - it tells you exactly where to look.

### Array Storage: Ordered Lists with Linear Complexity

**FIRST PRINCIPLES: Array Data Structure**

Arrays maintain order but require iteration for lookups. This is a fundamental array/vector data structure.

**UNDERSTANDING THE STRUCTURE**:

```solidity
address[] public users;
// Storage: length at slot N, elements at keccak256(N), keccak256(N)+1, ...
```

**HOW IT WORKS** (DSA Concept):

```
Array Lookup:
┌─────────────────────────────────────────┐
│ Input: index (e.g., 5)                  │
│   ↓                                      │
│ Calculate slot: keccak256(N) + index    │ ← O(1) calculation
│   ↓                                      │
│ Read value from slot                     │ ← O(1) access
└─────────────────────────────────────────┘

Array Search (find address):
┌─────────────────────────────────────────┐
│ Input: address to find                  │
│   ↓                                      │
│ Iterate through all elements            │ ← O(n) iteration
│   ↓                                      │
│ Compare each element                     │ ← O(n) comparisons
│   ↓                                      │
│ Return if found                          │
└─────────────────────────────────────────┘

Time Complexity:
- Access by index: O(1) - Constant time
- Search by value: O(n) - Linear time
- Insertion: O(1) amortized (push to end)
- Deletion: O(n) - Must shift elements
```

**CONNECTION TO PROJECT 01**: 
We learned about array storage layout in Project 01. Arrays store length separately and elements at calculated slots, which enables O(1) access by index but O(n) search.

**GAS COSTS** (from Project 01 knowledge):
- Push: ~20,000 gas (new slot - cold SSTORE)
- Read by index: ~100 gas per element (warm SLOAD)
- Length: ~100 gas (SLOAD from base slot)
- Iteration: n × ~103 gas (SLOAD + MLOAD per element)

**COMPARISON TO RUST** (DSA Concept):

**Rust** (Vec):
```rust
let mut users: Vec<Address> = Vec::new();

// Push: O(1) amortized
users.push(address);

// Access by index: O(1)
let user = users[5];

// Search: O(n)
let found = users.iter().find(|&x| x == target);
```

**Solidity** (array):
```solidity
address[] public users;

// Push: O(1) - but expensive gas-wise
users.push(address);

// Access by index: O(1)
address user = users[5];

// Search: O(n) - must iterate
for (uint i = 0; i < users.length; i++) {
    if (users[i] == target) return true;
}
```

Both have similar time complexity, but Solidity arrays are more expensive gas-wise due to storage costs.

**REAL-WORLD ANALOGY**: 
Like a guest list - ordered but you have to scan through to find someone. Great for iteration (going through the list), bad for lookups (finding a specific person). Arrays are perfect when you need order and iteration, but mappings are better for lookups!

### Gas Optimization: Track Totals Separately

Instead of iterating to calculate totals, maintain a running total:

```solidity
uint256 public totalBalance;  // Track separately

function setBalance(address user, uint256 amount) public {
    uint256 oldBalance = balances[user];
    balances[user] = amount;
    totalBalance = totalBalance - oldBalance + amount;  // Update running total
}
```

**Gas Savings:**
- Reading totalBalance: ~100 gas
- Calculating sumAllBalances(): n × ~103 gas
- For 100 users: 100 gas vs 10,300 gas (99% reduction!)

**Real-world analogy**: Like a cash register that keeps a running total instead of counting all items every time someone asks for the total.

### Unbounded Loop DoS Risk

⚠️ **CRITICAL**: Unbounded loops can cause DoS attacks!

```solidity
// DANGEROUS: Unbounded iteration
function sumAllBalances() public view returns (uint256) {
    uint256 sum = 0;
    for (uint256 i = 0; i < users.length; i++) {  // Could be huge!
        sum += balances[users[i]];
    }
    return sum;
}
```

**Attack Vector:**
1. Attacker adds thousands of users
2. Legitimate users can't call sumAllBalances() (exceeds gas limit)
3. Contract becomes unusable

**Mitigation:**
- Track totals separately (avoid iteration)
- Limit array size
- Use pagination for iteration
- Consider mappings + events instead of arrays

## 🏗️ What You'll Build

A gas-efficient balance tracking system that demonstrates:

1. **Mapping-based lookups** (O(1) access)
2. **Array-based iteration** (for when order matters)
3. **Running total tracking** (gas optimization)
4. **Gas cost comparisons** (iteration vs tracking)

## 📋 Tasks

### 1. Implement `addUser(address user)`
- Check if user already exists
- Add to `users` array
- Set `isUser[user] = true`
- Emit `UserAdded` event

**Gas considerations:**
- Use mapping check first (cheaper than array search)
- Cache values you'll use multiple times

### 2. Implement `setBalance(address user, uint256 amount)`
- Add user if doesn't exist
- Cache old balance
- Update balance mapping
- Update `totalBalance` efficiently
- Emit `BalanceUpdated` event

**Gas optimization:**
- Cache old balance to avoid re-reading
- Update totalBalance incrementally (don't recalculate)

### 3. Implement `sumAllBalances()` (for comparison)
- Iterate through all users
- Sum their balances
- Return total

**Gas warning:**
- This is expensive! Use only for verification
- Cache array length to avoid repeated SLOADs
- Use `unchecked` increment (safe in loop)

### 4. Implement `getTotalBalance()` (gas-efficient)
- Simply return `totalBalance`
- No iteration needed!

### 5. Write Deployment Script
- Deploy contract
- Log deployment address
- Verify deployment

### 6. Write Comprehensive Tests
- Test user addition
- Test balance updates
- Test total balance tracking
- Compare gas costs (iteration vs tracking)
- Test edge cases (zero balance, duplicate users)

## 🧪 Test Coverage

Your tests should verify:

- ✅ Users can be added
- ✅ Duplicate users are rejected
- ✅ Balances update correctly
- ✅ Total balance tracks correctly
- ✅ Iteration function works (but is expensive)
- ✅ Tracking is more gas-efficient than iteration
- ✅ Edge cases handled (zero balance, empty array)

## 🎓 Real-World Analogies & Fun Facts

### Phone Book vs Guest List
- **Mapping** = Phone book (instant lookup by name)
- **Array** = Guest list (ordered, but must scan to find)

### Cash Register Analogy
- **Running total** = Cash register display (instant read)
- **Recalculation** = Counting all items manually (slow, expensive)

### Fun Facts
- Mappings use keccak256 for storage slots (same as Project 01!)
- Array iteration costs scale linearly (O(n))
- Tracking totals separately saves 99%+ gas for large datasets
- Unbounded loops are a common DoS vector in DeFi protocols

## ✅ Completion Checklist

- [ ] Implement `addUser()` function
- [ ] Implement `setBalance()` function
- [ ] Implement `sumAllBalances()` function
- [ ] Implement `getTotalBalance()` function
- [ ] Write deployment script
- [ ] Write comprehensive test suite
- [ ] Run `forge test --gas-report` to compare gas costs
- [ ] Verify iteration is more expensive than tracking
### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/MappingsArraysGasSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployMappingsArraysGasSolution.s.sol` - Deployment script patterns
- `test/solution/MappingsArraysGasSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains hash tables (O(1) lookups), dynamic arrays (O(n) iteration), running totals pattern (O(1) vs O(n))
- **Connections to Project 01**: References mapping/array storage patterns, builds on storage layout concepts
- **THE KEY OPTIMIZATION**: Running totals pattern - 99% gas savings vs iteration (critical for all balance systems)
- **Real-World Context**: This pattern is used in all DeFi protocols (Uniswap, Aave, Compound)

- [ ] Review solution implementation
- [ ] Understand gas optimization patterns

## 💡 Pro Tips

1. **Cache storage reads**: If you use a value multiple times, cache it in memory
2. **Track totals separately**: Avoid expensive loops for frequently accessed totals
3. **Use mappings for lookups**: O(1) access vs O(n) for arrays
4. **Use arrays for iteration**: When order matters and you need to iterate
5. **Beware unbounded loops**: They can cause DoS attacks
6. **Compare gas costs**: Use `forge test --gas-report` to see actual costs
7. **Use unchecked arithmetic**: Safe in loops (i++ can't overflow if i < length)

## 🚀 Next Steps

After completing this project:

- Move to [Project 07: Reentrancy & Security](../07-reentrancy-and-security/)
- Study gas optimization patterns in production contracts
- Explore how DeFi protocols handle large datasets
- Learn about pagination patterns for iteration

---


## 07-reentrancy-and-security

# Project 07: Reentrancy & Security 🛡️

> **Master the most critical security pattern in Solidity**

## 🎯 Learning Objectives

By completing this project, you will:

1. **Understand reentrancy attacks** and how they work
2. **Reproduce the classic attack** ($60M The DAO hack)
3. **Apply Checks-Effects-Interactions pattern** correctly
4. **Use OpenZeppelin ReentrancyGuard** modifier
5. **Recognize cross-function reentrancy** vulnerabilities
6. **Understand gas limits** and DoS vectors
7. **Master secure ETH transfer** patterns
8. **Create Foundry deployment scripts** from scratch
9. **Write comprehensive test suites** demonstrating attacks and fixes

## 📁 Project Directory Structure

```
07-reentrancy-and-security/
├── README.md                          # This file
├── foundry.toml                       # Foundry configuration
├── src/
│   ├── ReentrancySecurity.sol        # Skeleton contract (TODO: implement)
│   └── solution/
│       └── ReentrancySecuritySolution.sol  # Complete reference implementation
├── script/
│   ├── DeployReentrancySecurity.s.sol # Deployment script (TODO: implement)
│   └── solution/
│       └── DeployReentrancySecuritySolution.s.sol  # Reference deployment
└── test/
    ├── ReentrancySecurity.t.sol        # Test suite (TODO: implement)
    └── solution/
        └── ReentrancySecuritySolution.t.sol  # Reference tests
```

## 🔑 Key Concepts

### The Reentrancy Attack: Understanding the Vulnerability

**FIRST PRINCIPLES: Call Stack and State Consistency**

A reentrancy attack occurs when a malicious contract calls back into the original contract before the first call completes, exploiting state that hasn't been updated yet. This is a fundamental concurrency issue in smart contracts.

**CONNECTION TO PROJECT 02**:
We learned about Checks-Effects-Interactions in Project 02. Reentrancy attacks exploit contracts that violate this pattern!

**THE VULNERABILITY**:
```solidity
// ❌ VULNERABLE: Wrong order!
function withdraw(uint256 amount) public {
    require(balances[msg.sender] >= amount);  // 1. CHECK ✅
    msg.sender.call{value: amount}("");       // 2. INTERACTION FIRST! ❌
    balances[msg.sender] -= amount;           // 3. EFFECT TOO LATE! ❌
}
```

**DETAILED ATTACK FLOW**:

```
Call Stack Visualization:
┌─────────────────────────────────────────┐
│ withdraw(100) - First Call              │
│   ↓                                      │
│ Check: balance >= 100 ✅                 │ ← Passes
│   ↓                                      │
│ External call: send 100 ETH             │ ← Attacker receives ETH
│   ↓                                      │
│ [ATTACKER'S RECEIVE() EXECUTES]         │ ← Re-enters contract!
│   ↓                                      │
│ withdraw(100) - Second Call             │ ← Reentrant call!
│   ↓                                      │
│ Check: balance >= 100 ✅                 │ ← STILL PASSES! (not updated!)
│   ↓                                      │
│ External call: send 100 ETH             │ ← More ETH sent!
│   ↓                                      │
│ [ATTACKER'S RECEIVE() EXECUTES AGAIN]   │ ← Can repeat!
│   ↓                                      │
│ ... (continues until contract drained)  │
│   ↓                                      │
│ Finally: balance -= 100                 │ ← Too late! Already drained
└─────────────────────────────────────────┘
```

**WHY IT WORKS**:
1. Attacker calls `withdraw(100)`
2. Contract checks balance: ✅ Passes (balance = 100)
3. Contract sends 100 ETH to attacker
4. **Attacker's `receive()` function executes** (this is the key!)
5. Attacker's `receive()` calls `withdraw(100)` again
6. Contract checks balance: ✅ **STILL PASSES** (balance not updated yet!)
7. Contract sends another 100 ETH
8. Attacker repeats until contract drained! 💥

**THE ROOT CAUSE**:
State is updated AFTER the external call. If the external call re-enters, the state check still sees the old value!

**HISTORICAL CONTEXT**: 
The DAO hack (2016) exploited this exact vulnerability, draining $60M. This led to the Ethereum hard fork and Ethereum Classic split. Understanding reentrancy is critical for secure Solidity development!

### Checks-Effects-Interactions Pattern: The Golden Rule

**FIRST PRINCIPLES: State Consistency Before External Calls**

The CEI pattern is THE fundamental security pattern for Solidity. It ensures state is updated before external calls, preventing reentrancy attacks.

**CONNECTION TO PROJECT 02**:
We introduced this pattern in Project 02 when learning about secure ETH withdrawals. Here we dive deep into why it's critical!

**THE SECURE PATTERN**:
```solidity
// ✅ SECURE: Checks-Effects-Interactions
function withdraw(uint256 amount) public {
    require(balances[msg.sender] >= amount);  // 1. CHECKS
    balances[msg.sender] -= amount;           // 2. EFFECTS (first!)
    msg.sender.call{value: amount}("");       // 3. INTERACTIONS (last)
}
```

**WHY THIS ORDER MATTERS**:

**Phase 1: CHECKS** (Validate Conditions)
- Validate all conditions first
- Fail early if conditions aren't met (saves gas)
- Examples: Balance checks, access control, input validation

**Phase 2: EFFECTS** (Update State)
- Update state BEFORE external calls
- This is CRITICAL - prevents reentrancy!
- Examples: Update balances, set flags, emit events

**Phase 3: INTERACTIONS** (External Calls)
- External calls LAST (after state updated)
- Safe because if re-entered, state already changed
- Examples: Send ETH, call other contracts

**HOW IT PREVENTS REENTRANCY**:

```
Secure Call Flow:
┌─────────────────────────────────────────┐
│ withdraw(100) - First Call              │
│   ↓                                      │
│ Check: balance >= 100 ✅                 │ ← 1. CHECK
│   ↓                                      │
│ balance -= 100 ✅                        │ ← 2. EFFECT (state updated!)
│   ↓                                      │
│ External call: send 100 ETH             │ ← 3. INTERACTION
│   ↓                                      │
│ [ATTACKER'S RECEIVE() EXECUTES]         │ ← Re-enters contract
│   ↓                                      │
│ withdraw(100) - Second Call             │ ← Reentrant call
│   ↓                                      │
│ Check: balance >= 100 ❌                 │ ← FAILS! (balance = 0)
│   ↓                                      │
│ REVERT - Attack prevented! ✅            │
└─────────────────────────────────────────┘
```

**GAS COST BREAKDOWN** (from Project 01 & 02 knowledge):

**Vulnerable Pattern**:
- Checks: ~100 gas (SLOAD)
- Interactions: ~2,100 gas (external call)
- Effects: ~5,000 gas (SSTORE)
- Risk: Reentrancy attack possible!

**Secure Pattern**:
- Checks: ~100 gas (SLOAD)
- Effects: ~5,000 gas (SSTORE)
- Interactions: ~2,100 gas (external call)
- Risk: Reentrancy attack prevented! ✅

Same gas cost, but secure!

**REAL-WORLD ANALOGY**: 
Like a bank teller - they check your ID (checks), update your account balance in the system (effects), THEN give you cash (interactions). If someone tries to withdraw again immediately, the system already shows the balance is updated!

**CONNECTION TO PROJECT 01**: 
Remember storage costs? The `balances[msg.sender] -= amount` operation costs ~5,000 gas (warm SSTORE). By doing this BEFORE the external call, we ensure state is updated even if the external call fails or re-enters.

### OpenZeppelin ReentrancyGuard

For complex contracts, use OpenZeppelin's ReentrancyGuard:

```solidity
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SecureContract is ReentrancyGuard {
    function withdraw() public nonReentrant {
        // Protected by ReentrancyGuard
    }
}
```

**How it works:**
- Uses aReentrancyGuard` modifier
- Sets a flag before function execution
- Clears flag after function completes
- Reverts if re-entered while flag is set

### Cross-Function Reentrancy

Reentrancy can occur across different functions:

```solidity
// ❌ VULNERABLE: Cross-function reentrancy
function withdraw() public {
    balances[msg.sender] -= amount;
    msg.sender.call{value: amount}("");
}

function transfer(address to, uint256 amount) public {
    balances[msg.sender] -= amount;
    balances[to] += amount;  // Attacker can call this from receive()!
}
```

**Mitigation:**
- Use ReentrancyGuard on all state-changing functions
- Or ensure all functions follow CEI pattern

## 🏗️ What You'll Build

A secure banking contract that demonstrates:

1. **Vulnerable implementation** (for learning)
2. **Secure implementation** using CEI pattern
3. **ReentrancyGuard** usage
4. **Attack demonstration** in tests

## 📋 Tasks

### 1. Implement Vulnerable Contract
- Create `withdrawVulnerable()` function
- Make external call BEFORE state update
- Demonstrate the vulnerability

### 2. Implement Secure Contract
- Create `withdrawSecure()` function
- Apply Checks-Effects-Interactions pattern
- Update state BEFORE external call

### 3. Implement ReentrancyGuard Version
- Use OpenZeppelin ReentrancyGuard
- Apply `nonReentrant` modifier
- Compare with CEI pattern

### 4. Write Attack Contract
- Create malicious contract with `receive()` function
- Attempt reentrancy attack on vulnerable contract
- Verify attack succeeds on vulnerable, fails on secure

### 5. Write Deployment Script
- Deploy all three contracts
- Log deployment addresses
- Verify deployments

### 6. Write Comprehensive Tests
- Test vulnerable contract (attack succeeds)
- Test secure contract (attack fails)
- Test ReentrancyGuard version
- Compare gas costs

## 🧪 Test Coverage

Your tests should verify:

- ✅ Vulnerable contract can be drained
- ✅ Secure contract prevents reentrancy
- ✅ ReentrancyGuard prevents reentrancy
- ✅ CEI pattern works correctly
- ✅ Attack fails on secure implementations
- ✅ Gas costs are reasonable

## 🎓 Real-World Analogies & Fun Facts

### Bank Teller Analogy
- **Vulnerable**: Give cash first, update account later (can withdraw multiple times!)
- **Secure**: Update account first, give cash later (can't withdraw twice)

### The DAO Hack ($60M)
- One of the largest hacks in crypto history
- Caused Ethereum hard fork (ETH vs ETC split)
- Led to creation of ReentrancyGuard pattern

### Fun Facts
- Reentrancy attacks are still common in DeFi
- CEI pattern is used in ALL secure contracts
- OpenZeppelin ReentrancyGuard adds ~2,300 gas overhead
- Cross-function reentrancy is harder to detect

## ✅ Completion Checklist

- [ ] Implement vulnerable withdraw function
- [ ] Implement secure withdraw function (CEI pattern)
- [ ] Implement ReentrancyGuard version
- [ ] Write attack contract
- [ ] Write deployment script
- [ ] Write comprehensive test suite
- [ ] Verify attack succeeds on vulnerable contract
- [ ] Verify attack fails on secure contracts
### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/ReentrancySecuritySolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployReentrancySecuritySolution.s.sol` - Deployment script patterns
- `test/solution/ReentrancySecuritySolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains state machine attacks, race conditions, atomic state transitions
- **Connections to Project 02**: Deep dive into CEI pattern - why it's THE most critical security pattern
- **Attack Demonstrations**: Shows both vulnerable and secure implementations side-by-side
- **Real-World Context**: References The DAO hack ($60M) and how CEI pattern prevents it

- [ ] Review solution implementation
- [ ] Understand CEI pattern deeply

## 💡 Pro Tips

1. **Always use CEI pattern**: For any function that modifies state and makes external calls
2. **Use ReentrancyGuard**: For complex contracts with multiple state-changing functions
3. **Test attacks**: Always test that attacks fail on secure implementations
4. **Understand gas limits**: Reentrancy can cause DoS if gas limit exceeded
5. **Review external calls**: Every external call is a potential reentrancy vector
6. **Use .call{value:}()**: Not .transfer() or .send() (Project 02!)

## 🚀 Next Steps

After completing this project:

- Move to [Project 08: ERC20 from Scratch](../08-ERC20-from-scratch/)
- Study real-world reentrancy attacks
- Explore cross-function reentrancy patterns
- Learn about flash loan attacks

---


## 08-ERC20-from-scratch

# Project 08: ERC20 from Scratch 🪙

> **Implement the most important token standard in Ethereum**

## 🎯 Learning Objectives

By completing this project, you will:

1. **Understand the ERC20 standard** and its required functions
2. **Implement ERC20 from scratch** without libraries
3. **Master approval/allowance mechanics** for delegated transfers
4. **Understand token economics** and supply management
5. **Recognize approval race condition** vulnerability
6. **Compare manual vs OpenZeppelin** implementations
7. **Understand events** required by ERC20
8. **Create Foundry deployment scripts** for token deployment
9. **Write comprehensive test suites** for ERC20 functionality

## 📁 Project Directory Structure

```
08-ERC20-from-scratch/
├── README.md                          # This file
├── foundry.toml                       # Foundry configuration
├── src/
│   ├── ERC20Token.sol                # Skeleton contract (TODO: implement)
│   └── solution/
│       └── ERC20TokenSolution.sol    # Complete reference implementation
├── script/
│   ├── DeployERC20Token.s.sol         # Deployment script (TODO: implement)
│   └── solution/
│       └── DeployERC20TokenSolution.s.sol  # Reference deployment
└── test/
    ├── ERC20Token.t.sol               # Test suite (TODO: implement)
    └── solution/
        └── ERC20TokenSolution.t.sol    # Reference tests
```

## 🔑 Key Concepts

### ERC20 Standard Overview: The Foundation of DeFi

**FIRST PRINCIPLES: Token Standardization**

ERC20 is the most widely used token standard on Ethereum. It defines a common interface for fungible tokens, enabling interoperability between different applications. This standardization is what makes DeFi composable!

**CONNECTION TO PROJECTS 01-07**:
- **Project 01**: We learned about mappings - ERC20 uses `mapping(address => uint256)` for balances
- **Project 02**: We learned about functions and ETH - ERC20 transfers tokens instead
- **Project 03**: We learned about events - ERC20 requires Transfer and Approval events
- **Project 04**: We learned about modifiers - ERC20 can use access control modifiers
- **Project 05**: We learned about errors - ERC20 uses custom errors for gas efficiency
- **Project 06**: We learned about gas optimization - ERC20 balances use O(1) mappings
- **Project 07**: We learned about security - ERC20 must follow CEI pattern

**REQUIRED FUNCTIONS**:
```solidity
totalSupply() → uint256                    // Total token supply
balanceOf(address) → uint256               // Balance of an address
transfer(address, uint256) → bool         // Transfer tokens
approve(address, uint256) → bool          // Approve spending
allowance(address, address) → uint256     // Check approval amount
transferFrom(address, address, uint256) → bool  // Delegated transfer
```

**REQUIRED EVENTS** (from Project 03 knowledge):
```solidity
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);
```

**UNDERSTANDING FUNGIBILITY**:

**Fungible** = Interchangeable (all tokens identical)
- Example: 1 USDC = 1 USDC (they're identical)
- Like: Dollar bills, gold bars, shares of stock

**Non-Fungible** = Unique (each token different)
- Example: Each NFT has unique properties
- Like: Trading cards, artwork, real estate

ERC20 tokens are fungible - this is what makes them work as currency!

**STORAGE STRUCTURE** (from Project 01 knowledge):

```solidity
mapping(address => uint256) public balanceOf;  // O(1) balance lookup
mapping(address => mapping(address => uint256)) public allowance;  // Nested mapping
uint256 public totalSupply;  // Total tokens in existence
```

**GAS COST BREAKDOWN**:

**Balance Check**:
- `balanceOf(addr)`: ~100 gas (warm SLOAD from mapping)

**Transfer**:
- Validation: ~6 gas
- 2 SLOADs: ~200 gas (warm reads)
- 2 SSTOREs: ~10,000 gas (warm writes)
- Event: ~1,500 gas
- Total: ~11,706 gas (warm)

**REAL-WORLD ANALOGY**: 
Like a standardized currency format - every ERC20 token follows the same rules, so wallets and exchanges can handle them all the same way! Just like how all credit cards have the same shape, all ERC20 tokens have the same interface.

### Transfer Function

The `transfer()` function moves tokens from the caller to another address:

```solidity
function transfer(address to, uint256 amount) public returns (bool) {
    require(to != address(0), "Invalid recipient");
    require(balanceOf[msg.sender] >= amount, "Insufficient balance");
    
    balanceOf[msg.sender] -= amount;
    balanceOf[to] += amount;
    
    emit Transfer(msg.sender, to, amount);
    return true;
}
```

**Gas costs:**
- Validation: ~6 gas
- 2 SLOADs: ~200 gas (warm)
- 2 SSTOREs: ~10,000 gas (warm)
- Event: ~1,500 gas
- Total: ~11,706 gas (warm)

### Approval & Allowance Pattern: Delegated Spending

**FIRST PRINCIPLES: Delegation Pattern**

The approval pattern enables delegated spending - allowing another address to spend tokens on your behalf. This is essential for DeFi composability!

**CONNECTION TO PROJECT 01**:
This uses **nested mappings**! `mapping(address => mapping(address => uint256))` stores approvals:
- Outer mapping: Owner address
- Inner mapping: Spender address → approved amount

**UNDERSTANDING THE PATTERN**:

```solidity
function approve(address spender, uint256 amount) public returns (bool) {
    allowance[msg.sender][spender] = amount;  // Set approval
    emit Approval(msg.sender, spender, amount);
    return true;
}
```

**HOW IT WORKS**:

```
Delegated Transfer Flow:
┌─────────────────────────────────────────┐
│ 1. Owner approves spender                │
│    approve(spender, 100)                 │
│    ↓                                      │
│    allowance[owner][spender] = 100       │ ← Storage write
│    ↓                                      │
│ 2. Spender calls transferFrom            │
│    transferFrom(owner, recipient, 50)    │
│    ↓                                      │
│    Check: allowance >= 50 ✅             │ ← Read from nested mapping
│    ↓                                      │
│    balanceOf[owner] -= 50                 │ ← Update balances
│    balanceOf[recipient] += 50            │
│    allowance[owner][spender] -= 50       │ ← Decrease allowance
│    ↓                                      │
│ 3. Approval automatically decremented    │ ← Can't exceed limit!
└─────────────────────────────────────────┘
```

**GAS COST BREAKDOWN** (from Project 01 & 06 knowledge):

**Approve**:
- SSTORE to nested mapping: ~5,000 gas (warm) or ~20,000 gas (cold)
- Event emission: ~1,500 gas
- Total: ~6,500 gas (warm) or ~21,500 gas (cold)

**TransferFrom**:
- 2 SLOADs (balance + allowance): ~200 gas (warm)
- 2 SSTOREs (balances): ~10,000 gas (warm)
- 1 SSTORE (allowance): ~5,000 gas (warm)
- Event: ~1,500 gas
- Total: ~16,700 gas (warm)

**USE CASES**:
- **DEXs**: Users approve DEX to swap tokens
- **Lending**: Users approve protocol to use tokens as collateral
- **Yield Farming**: Users approve staking contract to stake tokens
- **Multi-sig**: One signer approves another to execute transfers

**REAL-WORLD ANALOGY**: 
Like giving someone a credit card with a spending limit - they can spend up to the approved amount, but you control the limit! The allowance is like the credit limit, and `transferFrom` is like making a purchase (decreases available credit).

### TransferFrom Function

The `transferFrom()` function enables delegated transfers:

```solidity
function transferFrom(address from, address to, uint256 amount) public returns (bool) {
    require(balanceOf[from] >= amount, "Insufficient balance");
    require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
    
    balanceOf[from] -= amount;
    balanceOf[to] += amount;
    allowance[from][msg.sender] -= amount;  // Decrease allowance
    
    emit Transfer(from, to, amount);
    return true;
}
```

**Use cases:**
- DEXs swapping tokens
- Lending protocols using tokens as collateral
- Yield farming protocols staking tokens

### Approval Race Condition

⚠️ **WARNING**: There's a known race condition in ERC20 approvals!

**The Problem:**
If Alice approves Bob for 100 tokens, then wants to change it to 50:
1. Alice calls `approve(bob, 50)`
2. Bob sees the transaction in mempool
3. Bob front-runs with `transferFrom(alice, bob, 100)` (using old approval)
4. Then Alice's approval goes through (sets to 50)
5. Bob got 100 tokens, not 50!

**Mitigation:**
- Use `increaseAllowance()` / `decreaseAllowance()` (OpenZeppelin)
- Or approve to 0 first, then approve new amount
- Or use `safeIncreaseAllowance()` pattern

## 🏗️ What You'll Build

A complete ERC20 token implementation that includes:

1. **Token metadata** (name, symbol, decimals)
2. **Balance tracking** (mapping)
3. **Transfer functionality** (direct transfers)
4. **Approval system** (delegated spending)
5. **TransferFrom** (delegated transfers)
6. **Event emissions** (Transfer, Approval)

## 📋 Tasks

### 1. Implement Constructor
- Set token name, symbol, decimals
- Initialize total supply
- Mint initial supply to deployer
- Emit Transfer event (from address(0))

### 2. Implement `transfer(address to, uint256 amount)`
- Validate recipient is not zero address
- Check sender has sufficient balance
- Update balances (decrease sender, increase recipient)
- Emit Transfer event
- Return true

### 3. Implement `approve(address spender, uint256 amount)`
- Validate spender is not zero address
- Set allowance mapping
- Emit Approval event
- Return true

### 4. Implement `transferFrom(address from, address to, uint256 amount)`
- Validate addresses are not zero
- Check balance and allowance
- Update balances
- Decrease allowance
- Emit Transfer event
- Return true

### 5. Write Deployment Script
- Deploy token with name, symbol, initial supply
- Log deployment address
- Verify deployment

### 6. Write Comprehensive Tests
- Test transfer functionality
- Test approval and transferFrom
- Test edge cases (zero address, insufficient balance)
- Test events are emitted correctly
- Compare with OpenZeppelin ERC20

## 🧪 Test Coverage

Your tests should verify:

- ✅ Constructor initializes correctly
- ✅ Transfer works correctly
- ✅ Transfer reverts on invalid inputs
- ✅ Approval sets allowance correctly
- ✅ TransferFrom works with approval
- ✅ TransferFrom decreases allowance
- ✅ Events are emitted correctly
- ✅ Edge cases handled (zero address, insufficient balance/allowance)

## 🎓 Real-World Analogies & Fun Facts

### Currency Standardization
- **ERC20** = Standardized currency format
- **Different tokens** = Different currencies (USD, EUR, etc.)
- **Same interface** = Wallets can handle all tokens

### Credit Card Analogy
- **approve()** = Setting credit limit
- **allowance** = Remaining credit
- **transferFrom()** = Making a purchase (decreases credit)
- **Decrease allowance** = Automatic after purchase

### Fun Facts
- ERC20 was proposed in 2015 by Fabian Vogelsteller
- Over 500,000 ERC20 tokens exist on Ethereum
- Most DeFi protocols use ERC20 tokens
- USDC, USDT, DAI are all ERC20 tokens
- Approval race condition is a known issue (still used widely)

## ✅ Completion Checklist

- [ ] Implement constructor
- [ ] Implement transfer function
- [ ] Implement approve function
- [ ] Implement transferFrom function
- [ ] Emit Transfer events correctly
- [ ] Emit Approval events correctly
- [ ] Write deployment script
- [ ] Write comprehensive test suite
- [ ] Test all edge cases
### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/ERC20TokenSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployERC20TokenSolution.s.sol` - Deployment script patterns
- `test/solution/ERC20TokenSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains hash tables (balances), nested mappings (allowances), delegation pattern
- **Connections to Projects 01-07**: Combines ALL previous concepts - storage, functions, events, CEI, access control
- **ERC20 Standard**: Complete implementation of the most important token standard (500,000+ tokens use it)
- **Real-World Context**: Foundation for all DeFi protocols - DEXs, lending, yield farming all use ERC20

- [ ] Review solution implementation
- [ ] Compare with OpenZeppelin ERC20

## 💡 Pro Tips

1. **Always validate addresses**: Check for zero address in transfer/approve
2. **Emit events correctly**: Required by ERC20 standard
3. **Return true**: ERC20 functions should return bool
4. **Decrease allowance**: Always decrease in transferFrom
5. **Use nested mappings**: For allowance (owner → spender → amount)
6. **Understand decimals**: Most tokens use 18 decimals (like ETH)
7. **Test approval race condition**: Understand the vulnerability

## 🚀 Next Steps

After completing this project:

- Move to [Project 09: ERC721 NFT from Scratch](../09-ERC721-NFT-from-scratch/)
- Study OpenZeppelin ERC20 implementation
- Add extensions (burnable, mintable, pausable)
- Learn about ERC20 extensions (ERC20Votes, ERC20Permit)

---


## 09-ERC721-NFT-from-scratch

# Project 09: ERC721 NFT from Scratch 🖼️

> **Implement the NFT standard and understand digital ownership**

## 🎯 Learning Objectives

By completing this project, you will:

1. **Understand the ERC721 standard** and its required functions
2. **Implement ERC721 from scratch** without libraries
3. **Handle token metadata** and URIs
4. **Implement safe transfer callbacks** to prevent stuck NFTs
5. **Understand approval mechanisms** (single token vs operator)
6. **Recognize mint race conditions** and front-running risks
7. **Integrate IPFS metadata** for decentralized storage
8. **Create Foundry deployment scripts** for NFT contracts
9. **Write comprehensive test suites** for NFT functionality

## 📁 Project Directory Structure

```
09-ERC721-NFT-from-scratch/
├── README.md                          # This file
├── foundry.toml                       # Foundry configuration
├── src/
│   ├── ERC721NFT.sol                 # Skeleton contract (TODO: implement)
│   └── solution/
│       └── ERC721NFTSolution.sol     # Complete reference implementation
├── script/
│   ├── DeployERC721NFT.s.sol         # Deployment script (TODO: implement)
│   └── solution/
│       └── DeployERC721NFTSolution.s.sol  # Reference deployment
└── test/
    ├── ERC721NFT.t.sol                # Test suite (TODO: implement)
    └── solution/
        └── ERC721NFTSolution.t.sol    # Reference tests
```

## 🔑 Key Concepts

### ERC721 Standard Overview: Non-Fungible Tokens

**FIRST PRINCIPLES: Uniqueness and Ownership**

ERC721 is the standard for non-fungible tokens (NFTs) - unique, indivisible tokens. Unlike ERC20 (fungible), each ERC721 token is unique and has its own tokenId.

**CONNECTION TO PROJECT 08**:
- **Project 08**: ERC20 - fungible tokens (all identical)
- **Project 09**: ERC721 - non-fungible tokens (each unique)
- Both use similar patterns (mappings, events, approvals) but with key differences!

**KEY DIFFERENCES FROM ERC20**:

| Aspect | ERC20 | ERC721 |
|--------|-------|--------|
| **Fungibility** | Fungible (all identical) | Non-fungible (each unique) |
| **Transfer** | By amount (`transfer(to, amount)`) | By tokenId (`transferFrom(from, to, tokenId)`) |
| **Balance** | Total amount held | Count of NFTs owned |
| **Storage** | `mapping(address => uint256)` | `mapping(uint256 => address)` |
| **Approval** | Amount-based (`approve(spender, amount)`) | Token-based (`approve(spender, tokenId)`) |

**STORAGE STRUCTURE** (from Project 01 knowledge):

**ERC20**:
```solidity
mapping(address => uint256) public balanceOf;  // How many tokens?
```

**ERC721**:
```solidity
mapping(uint256 => address) public ownerOf;      // Who owns tokenId?
mapping(address => uint256) public balanceOf;    // How many NFTs?
```

**UNDERSTANDING THE DIFFERENCE**:

**ERC20 Transfer**:
```solidity
transfer(to, 100);  // Transfer 100 tokens
// All 100 tokens are identical
```

**ERC721 Transfer**:
```solidity
transferFrom(from, to, 5);  // Transfer tokenId #5
// Token #5 is unique - can't transfer "100 NFTs" like ERC20
```

**GAS COST COMPARISON** (from Project 01 & 08 knowledge):

**ERC20 Transfer**:
- 2 SLOADs (balances): ~200 gas
- 2 SSTOREs (balances): ~10,000 gas
- Event: ~1,500 gas
- Total: ~11,700 gas

**ERC721 Transfer**:
- 2 SLOADs (ownerOf + balanceOf): ~200 gas
- 2 SSTOREs (ownerOf + balanceOf): ~10,000 gas
- Event: ~1,500 gas
- Total: ~11,700 gas (similar!)

**REAL-WORLD ANALOGY**: 
Like trading cards vs currency:
- **ERC20** = Dollar bills (all identical, transfer by amount)
- **ERC721** = Trading cards (each unique, transfer by card number)

**COMPARISON TO RUST** (DSA Concept):

**Rust** (HashMap for ownership):
```rust
use std::collections::HashMap;

struct NFT {
    owner_of: HashMap<TokenId, Address>,
    balance_of: HashMap<Address, u256>,
}
```

**Solidity** (mappings):
```solidity
mapping(uint256 => address) public ownerOf;
mapping(address => uint256) public balanceOf;
```

Both use hash-based structures for O(1) lookups, but Solidity's mappings are more gas-efficient!

### Core Functions

```solidity
balanceOf(address owner) → uint256              // Number of NFTs owned
ownerOf(uint256 tokenId) → address              // Owner of specific NFT
transferFrom(address from, address to, uint256 tokenId)  // Transfer NFT
safeTransferFrom(...)                           // Safe transfer with callback
approve(address to, uint256 tokenId)            // Approve single token
setApprovalForAll(address operator, bool)        // Approve all tokens
getApproved(uint256 tokenId) → address          // Get approved address
isApprovedForAll(address owner, address operator) → bool  // Check operator approval
```

### Safe Transfer vs Regular Transfer

**Regular Transfer:**
```solidity
function transferFrom(address from, address to, uint256 tokenId) public {
    // Transfers NFT without checking if recipient can handle it
}
```

**Safe Transfer:**
```solidity
function safeTransferFrom(...) public {
    transferFrom(from, to, tokenId);
    // Checks if recipient is contract
    // Calls onERC721Received callback
    // Reverts if recipient can't handle NFTs
}
```

**Why Safe Transfer Matters:**
- Prevents NFTs stuck in contracts that can't handle them
- Ensures recipient implements `IERC721Receiver`
- Standard practice for NFT transfers

### Token Metadata & URIs

NFTs store metadata off-chain (usually IPFS) and reference it via URI:

```solidity
mapping(uint256 => string) public tokenURI;

function mint(address to, string memory uri) public {
    uint256 tokenId = _tokenIdCounter++;
    tokenURI[tokenId] = uri;  // Points to IPFS/metadata
    // ...
}
```

**Real-world analogy**: Like a certificate of ownership - the NFT is the certificate, the URI points to the actual artwork/metadata stored elsewhere!

### Approval Mechanisms

ERC721 has TWO types of approvals:

1. **Single Token Approval**: `approve(to, tokenId)`
   - Approves specific token
   - Stored in `getApproved[tokenId]`

2. **Operator Approval**: `setApprovalForAll(operator, true)`
   - Approves ALL tokens owned
   - Stored in `isApprovedForAll[owner][operator]`

**Use cases:**
- Single approval: Approve marketplace for one NFT
- Operator approval: Approve marketplace for all NFTs

## 🏗️ What You'll Build

A complete ERC721 NFT implementation that includes:

1. **Token ownership tracking** (tokenId → owner)
2. **Balance tracking** (address → count)
3. **Transfer functionality** (regular and safe)
4. **Approval system** (single token and operator)
5. **Metadata URIs** (IPFS integration)
6. **Minting functionality** (create new NFTs)

## 📋 Tasks

### 1. Implement Constructor
- Set token name and symbol
- Initialize token counter

### 2. Implement `mint(address to, string memory uri)`
- Validate recipient
- Increment token counter
- Set owner and balance
- Store token URI
- Emit Transfer event (from address(0))

### 3. Implement `transferFrom(address from, address to, uint256 tokenId)`
- Validate ownership and authorization
- Update balances and ownership
- Clear single token approval
- Emit Transfer event

### 4. Implement `safeTransferFrom(...)`
- Call regular transferFrom
- Check if recipient is contract
- Call `onERC721Received` callback
- Verify callback return value

### 5. Implement `approve(address to, uint256 tokenId)`
- Validate authorization (owner or operator)
- Set single token approval
- Emit Approval event

### 6. Implement `setApprovalForAll(address operator, bool approved)`
- Set operator approval for all tokens
- Emit ApprovalForAll event

### 7. Write Deployment Script
- Deploy NFT contract
- Mint initial NFTs
- Log deployment and minting

### 8. Write Comprehensive Tests
- Test minting functionality
- Test transfers (regular and safe)
- Test approvals (single and operator)
- Test edge cases (zero address, invalid tokenId)
- Test safe transfer callbacks

## 🧪 Test Coverage

Your tests should verify:

- ✅ Minting creates NFTs correctly
- ✅ Transfer works correctly
- ✅ Safe transfer checks callbacks
- ✅ Single token approval works
- ✅ Operator approval works
- ✅ Authorization checks work correctly
- ✅ Events are emitted correctly
- ✅ Edge cases handled (zero address, invalid tokenId)

## 🎓 Real-World Analogies & Fun Facts

### Trading Cards Analogy
- **ERC721** = Trading cards (each unique)
- **ERC20** = Currency (all identical)
- **TokenId** = Card number
- **Metadata URI** = Card image/details

### Certificate of Ownership
- **NFT** = Certificate proving ownership
- **URI** = Link to actual artwork/metadata
- **Transfer** = Transferring ownership certificate

### Fun Facts
- ERC721 was proposed in 2018 by William Entriken
- CryptoPunks predate ERC721 (they're ERC20-like)
- Most NFTs store metadata on IPFS (decentralized)
- Safe transfer prevents NFTs stuck in contracts
- OpenSea uses operator approvals for gas efficiency

## ✅ Completion Checklist

- [ ] Implement constructor
- [ ] Implement mint function
- [ ] Implement transferFrom function
- [ ] Implement safeTransferFrom function
- [ ] Implement approve function
- [ ] Implement setApprovalForAll function
- [ ] Implement helper functions (_isApprovedOrOwner)
- [ ] Write deployment script
- [ ] Write comprehensive test suite
- [ ] Test safe transfer callbacks
### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/ERC721NFTSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployERC721NFTSolution.s.sol` - Deployment script patterns
- `test/solution/ERC721NFTSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains hash tables (tokenId → owner), count tracking, delegation patterns
- **Connections to Project 08**: Compares ERC721 (non-fungible) vs ERC20 (fungible) - similar patterns, different use cases
- **Connections to Projects 01-03**: Uses mapping storage, events, and function patterns from earlier projects
- **Real-World Context**: Foundation for NFT marketplaces, digital art, gaming assets

- [ ] Review solution implementation

## 💡 Pro Tips

1. **Always use safeTransferFrom**: Prevents NFTs stuck in contracts
2. **Clear single approvals**: Delete getApproved after transfer
3. **Check authorization**: Use helper function for clarity
4. **Store metadata off-chain**: Use IPFS for decentralized storage
5. **Emit events correctly**: Required by ERC721 standard
6. **Handle callbacks**: Verify onERC721Received return value
7. **Understand operator approvals**: More gas-efficient for marketplaces

## 🚀 Next Steps

After completing this project:

- Move to [Project 10: Upgradeability & Proxies](../10-upgradeability-and-proxies/)
- Study OpenZeppelin ERC721 implementation
- Add metadata extension (ERC721Metadata)
- Implement royalties (ERC2981)
- Learn about ERC721A (gas-optimized version)

---


## 10-upgradeability-and-proxies

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

---


## 11-ERC4626-tokenized-vault

# Project 11: ERC-4626 Tokenized Vault 🏦

> **Implement the Tokenized Vault Standard for DeFi yield strategies**

## 🎯 Learning Objectives

By completing this project, you will:

1. **Understand the ERC-4626 Tokenized Vault Standard** and its purpose
2. **Implement deposit/withdraw mechanisms** with share calculation
3. **Handle asset/share conversion mathematics** correctly
4. **Learn vault security patterns** (inflation attack, donation attack)
5. **Understand rounding directions** (always favor vault)
6. **Master reentrancy protection** in vault contracts
7. **Study real-world DeFi vault implementations** (Yearn, Beefy)
8. **Create Foundry deployment scripts** for vault contracts
9. **Write comprehensive test suites** for vault operations

## 📁 Project Directory Structure

```
11-ERC4626-tokenized-vault/
├── README.md                          # This file
├── foundry.toml                       # Foundry configuration
├── src/
│   ├── ERC4626Vault.sol              # Skeleton contract (TODO: implement)
│   └── solution/
│       └── ERC4626VaultSolution.sol  # Complete reference implementation
├── script/
│   ├── DeployERC4626Vault.s.sol      # Deployment script (TODO: implement)
│   └── solution/
│       └── DeployERC4626VaultSolution.s.sol  # Reference deployment
└── test/
    ├── ERC4626Vault.t.sol            # Test suite (TODO: implement)
    └── solution/
        └── ERC4626VaultSolution.t.sol  # Reference tests
```

## 🔑 Key Concepts

### What is ERC-4626?

ERC-4626 is a standard for tokenized vaults that:
- Represent shares of an underlying asset (like USDC, DAI, WETH)
- Enable yield-generating strategies
- Provide standardized deposit/withdraw interfaces
- Power DeFi protocols like Yearn, Beefy, and Rari

### Real-World Use Cases

- **Yield Aggregators**: Yearn vaults deposit user funds into highest-yield protocols
- **Lending**: Aave/Compound style interest-bearing tokens
- **Liquidity Mining**: Auto-compounding LP rewards
- **Treasury Management**: Protocol-owned liquidity strategies

## 🧮 Core Concepts

### Asset vs Shares: Understanding the Exchange Rate

**FIRST PRINCIPLES: Fractional Reserve Banking**

ERC-4626 vaults work like banks - you deposit assets and receive shares that represent your portion of the vault.

**CONNECTION TO PROJECT 08**:
- **Project 08**: ERC20 tokens (fungible)
- **Project 11**: ERC-4626 vaults (also ERC20 tokens, but representing shares!)
- Vault shares ARE ERC20 tokens - they're fungible tokens representing fractional ownership!

**UNDERSTANDING THE CONCEPT**:

```solidity
// User deposits 100 USDC (asset)
// Vault mints 95 shares (based on current exchange rate)
// Later: shares are worth more USDC due to yield

asset = underlying token (USDC, WETH, etc.)  // What you deposit
shares = vault tokens (yUSDC, vWETH, etc.)   // What you receive
```

**HOW IT WORKS**:

```
Vault Mechanics:
┌─────────────────────────────────────────┐
│ Initial State:                          │
│   totalAssets = 1000 USDC               │
│   totalSupply = 1000 shares             │
│   Exchange rate: 1 share = 1 USDC      │
│   ↓                                      │
│ User deposits 100 USDC:                 │
│   shares = (100 * 1000) / 1000 = 100   │ ← Mint 100 shares
│   ↓                                      │
│ Vault earns yield:                      │
│   totalAssets = 1100 USDC (10% yield)   │
│   totalSupply = 1100 shares             │
│   Exchange rate: 1 share = 1 USDC      │ ← Still 1:1!
│   ↓                                      │
│ User withdraws 100 shares:             │
│   assets = (100 * 1100) / 1100 = 100   │ ← But vault has 1100 USDC!
│   User gets: 100 USDC                   │ ← Original deposit
│   Vault keeps: 10 USDC yield            │ ← Profit!
└─────────────────────────────────────────┘
```

**SHARE CALCULATION** (Precision Math):

```solidity
// Deposit: shares = assets * totalSupply / totalAssets
shares = (assets * totalSupply) / totalAssets;

// Withdraw: assets = shares * totalAssets / totalSupply  
assets = (shares * totalAssets) / totalSupply;
```

**UNDERSTANDING ROUNDING** (Critical for Security):

**Always Round DOWN** (favor vault):
```solidity
// ✅ CORRECT: Round down (favor vault)
shares = (assets * totalSupply) / totalAssets;  // Integer division rounds down

// ❌ WRONG: Round up (favor attacker)
shares = (assets * totalSupply + totalAssets - 1) / totalAssets;  // Rounds up!
```

**Why Round Down?**
- Prevents inflation attacks
- Ensures vault always has enough assets
- Protects against precision manipulation

**GAS COST BREAKDOWN** (from Project 01 & 06 knowledge):

**Deposit**:
- ERC20 transfer: ~50,000 gas (approve + transferFrom)
- Share calculation: ~100 gas (MUL + DIV)
- Mint shares: ~20,000 gas (SSTORE)
- Event: ~2,000 gas
- Total: ~72,100 gas

**Withdraw**:
- Share calculation: ~100 gas
- Burn shares: ~5,000 gas (SSTORE to zero)
- ERC20 transfer: ~50,000 gas
- Event: ~2,000 gas
- Total: ~57,100 gas

**REAL-WORLD ANALOGY**: 
Like buying shares of a mutual fund:
- **Assets** = Cash you deposit (USDC)
- **Shares** = Fund shares you receive
- **Exchange Rate** = NAV (Net Asset Value)
- **Yield** = Fund performance increases NAV

### Key Functions

| Function | Purpose |
|----------|---------|
| `deposit(assets, receiver)` | Deposit assets, mint shares |
| `mint(shares, receiver)` | Mint exact shares, deposit assets |
| `withdraw(assets, receiver, owner)` | Burn shares, withdraw assets |
| `redeem(shares, receiver, owner)` | Burn exact shares, withdraw assets |
| `totalAssets()` | Total underlying assets in vault |
| `convertToShares(assets)` | Preview assets→shares conversion |
| `convertToAssets(shares)` | Preview shares→assets conversion |
| `maxDeposit(receiver)` | Max assets user can deposit |
| `maxMint(receiver)` | Max shares user can mint |
| `maxWithdraw(owner)` | Max assets user can withdraw |
| `maxRedeem(owner)` | Max shares user can redeem |
| `previewDeposit(assets)` | Simulate deposit, return shares |
| `previewMint(shares)` | Simulate mint, return assets needed |
| `previewWithdraw(assets)` | Simulate withdraw, return shares burned |
| `previewRedeem(shares)` | Simulate redeem, return assets received |

## 🔧 What You'll Build

A complete ERC-4626 vault that:
- Accepts an ERC-20 asset (like USDC)
- Issues share tokens representing ownership
- Implements all required ERC-4626 functions
- Handles rounding correctly (favor vault on deposits/withdraws)
- Includes security checks and reentrancy guards
- Demonstrates yield accrual simulation

## 📝 Tasks

### Task 1: Implement the Skeleton Contract

Open `src/ERC4626Vault.sol` and implement:

1. **Asset management** - deposit, withdraw, totalAssets
2. **Share conversion** - convertToShares, convertToAssets
3. **Preview functions** - simulate operations
4. **Max functions** - return maximum allowed amounts
5. **ERC-20 share tokens** - inherit or implement

### Task 2: Study the Solution

Compare with `src/solution/ERC4626VaultSolution.sol`:

**Solution File Features**:
- **CS Concepts**: Explains proportional ownership math, precision handling, composability patterns
- **Connections to Project 08**: Vault shares are ERC20 tokens (inherits all ERC20 functionality)
- **Connections to Project 20**: Uses share-based accounting pattern for yield distribution
- **Real-World Context**: Standard used by Yearn, Aave, Compound for yield-bearing vaults
- Understand share/asset conversion math
- See rounding direction choices (favor vault)
- Learn security patterns (reentrancy, donation attacks)
- Study real-world vault patterns

### Task 3: Run Comprehensive Tests

```bash
cd 11-ERC4626-tokenized-vault

# Run all tests
forge test -vvv

# Test specific scenarios
forge test --match-test test_Deposit
forge test --match-test test_Withdraw
forge test --match-test test_ShareConversion

# Gas report
forge test --gas-report

# Coverage
forge coverage
```

### Task 4: Deploy and Interact

```bash
# Start local node
anvil

# Deploy vault (in another terminal)
forge script script/Deploy.s.sol --broadcast --rpc-url http://localhost:8545

# Interact with vault
cast call <VAULT_ADDRESS> "totalAssets()(uint256)"
cast send <VAULT_ADDRESS> "deposit(uint256,address)(uint256)" 1000000 <YOUR_ADDRESS> \
  --private-key <KEY>
```

### Task 5: Study Real Implementations

After completing this project, study production vaults:
- [OpenZeppelin ERC4626](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC4626.sol)
- [Solmate ERC4626](https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC4626.sol)
- [Yearn vaults](https://github.com/yearn/yearn-vaults)

## 🧪 Test Coverage

The test suite covers:

- ✅ Deposit and mint operations
- ✅ Withdraw and redeem operations
- ✅ Share/asset conversion accuracy
- ✅ Preview function correctness
- ✅ Max function constraints
- ✅ Rounding behavior (favor vault)
- ✅ Edge cases (first depositor, zero amounts)
- ✅ Attack vectors (inflation attack, donation attack)
- ✅ Yield accrual simulation
- ✅ Gas optimization

## ⚠️ Security Considerations

### 1. Inflation Attack

**Problem**: First depositor can manipulate share price

```solidity
// Attacker deposits 1 wei, gets 1 share
vault.deposit(1, attacker);

// Attacker donates large amount directly to vault
asset.transfer(address(vault), 1000000e18);

// Now 1 share = 1000000e18 assets
// Victim deposits 999999e18, gets 0 shares (rounded down!)
```

**Solution**: Mint dead shares to address(0) on first deposit, or require minimum deposit.

### 2. Donation Attack

**Problem**: Direct transfers can break accounting

**Solution**: Don't rely on `asset.balanceOf(address(this))`, track deposits internally.

### 3. Rounding Direction

**Always favor the vault**:
- Deposit/mint: round DOWN shares given to user
- Withdraw/redeem: round UP shares taken from user

### 4. Reentrancy

Use OpenZeppelin ReentrancyGuard on deposit/withdraw functions.

## 📊 Comparison: Vault Implementations

| Implementation | Gas Cost | Security | Flexibility |
|----------------|----------|----------|-------------|
| OpenZeppelin | Higher (safe) | ✅✅✅ | Medium |
| Solmate | Lower (optimized) | ✅✅ | High |
| This Project | Educational | ✅✅✅ | Learning |

## 🌍 Real-World Examples

### Yearn Finance

```solidity
// Yearn vault accepts USDC, implements yield strategy
yUSDC vault = YearnVault(vaultAddress);
vault.deposit(1000e6, msg.sender);  // Deposit 1000 USDC
// Vault deploys to Aave, Compound, Curve for best yield
```

### Beefy Finance

```solidity
// Auto-compounding LP token vault
BeefyVault mooToken = BeefyVault(vaultAddress);
mooToken.deposit(lpTokenAmount, msg.sender);
// Vault claims rewards, sells, re-invests into LP
```

## ✅ Completion Checklist

- [ ] Implemented all ERC-4626 required functions
- [ ] All tests pass
- [ ] Understand share conversion mathematics
- [ ] Can explain rounding directions
- [ ] Know common attack vectors
- [ ] Studied real vault implementations
- [ ] Deployed and interacted with vault
- [ ] Understand yield strategy concepts

## 💡 Pro Tips

1. **Always round in favor of the vault** (protect against attackers)
2. **Virtual shares/assets** - Consider minting dead shares on initialization
3. **Max functions** - Return actual maximums based on current state
4. **Preview functions** - Must match actual behavior exactly
5. **Events** - Emit for all deposits/withdraws for off-chain tracking
6. **Approval** - Users must approve vault to spend their assets
7. **Emergency functions** - Consider pause/unpause for security

## 🚀 Next Steps

After completing this project:

- **Build strategy vaults**: Implement actual yield strategies (Aave deposits, Curve LPs)
- **Multi-asset vaults**: Support multiple underlying tokens
- **Fee mechanisms**: Add performance fees and management fees
- **Access control**: Implement whitelists or caps
- **Integration**: Connect to DeFi protocols (Aave, Compound, Curve)

## 📖 Further Reading

- [EIP-4626 Specification](https://eips.ethereum.org/EIPS/eip-4626)
- [OpenZeppelin ERC4626 Guide](https://docs.openzeppelin.com/contracts/4.x/erc4626)
- [Yield Farming Strategies](https://ethereum.org/en/developers/docs/dapps/)
- [Vault Security Best Practices](https://github.com/yearn/yearn-security)

---

**Congratulations!** You've completed all 11 Solidity mini-projects. You now have:
- ✅ Solid understanding of Solidity fundamentals
- ✅ Experience with major token standards (ERC-20, ERC-721, ERC-4626)
- ✅ Knowledge of security vulnerabilities and mitigations
- ✅ Gas optimization techniques
- ✅ Real-world DeFi protocol patterns

**Keep building! 🚀**

---


## 12-safe-eth-transfer

# Project 12: Safe ETH Transfer Library 🛡️

> **Master secure ETH transfer patterns and avoid common pitfalls**

## 🎯 Learning Objectives

By completing this project, you will:

1. **Understand push vs pull payment patterns** and their security implications
2. **Recognize DoS attack vectors** in push payments
3. **Implement secure withdrawal queue systems** using pull pattern
4. **Handle failed ETH transfers** gracefully
5. **Understand EIP-1884** and gas stipend concerns
6. **Master safe ETH transfer mechanisms** (.call{value:} pattern)
7. **Apply Checks-Effects-Interactions** pattern correctly
8. **Create Foundry deployment scripts** for safe transfer contracts
9. **Write comprehensive test suites** including attack scenarios

## 📁 Project Directory Structure

```
12-safe-eth-transfer/
├── README.md                          # This file
├── foundry.toml                       # Foundry configuration
├── src/
│   ├── SafeETHTransfer.sol           # Skeleton contract (TODO: implement)
│   └── solution/
│       └── SafeETHTransferSolution.sol  # Complete reference implementation
├── script/
│   ├── DeploySafeETHTransfer.s.sol    # Deployment script (TODO: implement)
│   └── solution/
│       └── DeploySafeETHTransferSolution.s.sol  # Reference deployment
└── test/
    ├── SafeETHTransfer.t.sol          # Test suite (TODO: implement)
    └── solution/
        └── SafeETHTransferSolution.t.sol  # Reference tests
```

## 🔑 Key Concepts

### Push vs Pull Payment Patterns

## What Are Pull Payments?

### Push vs Pull Patterns

**FIRST PRINCIPLES: Push vs Pull Patterns**

Understanding push vs pull patterns is critical for secure ETH transfers. This connects directly to Project 02's ETH handling and Project 07's security patterns!

**CONNECTION TO PROJECT 02 & 07**:
- **Project 02**: We learned about ETH transfers using `.call{value:}()`
- **Project 07**: We learned about Checks-Effects-Interactions
- **Project 12**: Pull pattern combines both - safe ETH transfers with proper ordering!

**PUSH PAYMENT PATTERN (Dangerous)**:
```solidity
// ❌ BAD: Pushing payment to recipient
function distributeRewards(address[] memory recipients) public {
    for (uint i = 0; i < recipients.length; i++) {
        recipients[i].call{value: rewardAmount}("");  // Push payment
    }
}
```

**Problems with Push**:
1. **DoS Risk**: One failing recipient blocks entire distribution
2. **Gas Limit**: Large arrays can exceed block gas limit
3. **No Control**: Recipients can't control when they receive funds
4. **Failed Transfers**: Contract can't handle failures gracefully

**PULL PAYMENT PATTERN (Safe)**:
```solidity
// ✅ GOOD: Let recipients withdraw their own funds
mapping(address => uint256) public pendingWithdrawals;  // From Project 01!

function withdraw() public {
    uint256 amount = pendingWithdrawals[msg.sender];     // 1. CHECK
    pendingWithdrawals[msg.sender] = 0;                  // 2. EFFECT (CEI pattern!)
    (bool success, ) = msg.sender.call{value: amount}(""); // 3. INTERACTION
    require(success, "Transfer failed");
}
```

**Why Pull is Better**:
1. **No DoS**: Recipients withdraw individually (can't block others)
2. **Gas Efficient**: Only active recipients pay gas
3. **User Control**: Recipients choose when to withdraw
4. **Failure Handling**: Each withdrawal handled independently

**GAS COST COMPARISON** (from Project 01 & 02 knowledge):

**Push Pattern** (100 recipients):
- Loop overhead: ~100 gas
- 100 external calls: ~210,000 gas (100 × 2,100)
- Total: ~210,100 gas (all paid by distributor!)
- Risk: One failure blocks all!

**Pull Pattern** (100 recipients):
- Distributor: Update mapping only (~5,000 gas per recipient)
- Recipients: Withdraw individually (~23,000 gas each)
- Total: Distributor pays ~500,000 gas, recipients pay their own
- Benefit: No DoS risk, users control timing!

**REAL-WORLD ANALOGY**: 
- **Push** = Mailing checks to everyone (one bad address blocks delivery)
- **Pull** = Posting checks at bank, people pick them up (each person handles their own)

---

## Why Push Payments Are Dangerous

### 1. Denial of Service (DoS) Attack

An attacker can block the entire payment distribution by refusing to accept ETH:

```solidity
contract MaliciousRecipient {
    // This contract has no receive() or fallback()
    // Any ETH sent to it will fail
}

// If this recipient is in the list, the entire distributeRewards() fails
```

**Impact:**
- One malicious recipient can block payments to ALL users
- Contract functionality becomes frozen
- Gas is wasted on failed transactions

### 2. Unbounded Gas Consumption

```solidity
// What if recipients array has 1000 addresses?
function distributeRewards(address[] memory recipients) public {
    for (uint i = 0; i < recipients.length; i++) {
        // Each iteration costs gas
        // Total gas may exceed block gas limit!
        recipients[i].call{value: rewardAmount}("");
    }
}
```

**Problems:**
- Transaction may exceed block gas limit
- Unpredictable gas costs
- Can become impossible to execute as array grows

### 3. Reentrancy Vulnerabilities

```solidity
function distributeReward(address recipient) public {
    uint256 reward = calculateReward(recipient);
    // DANGER: External call before state update
    recipient.call{value: reward}("");
    // Attacker can re-enter here!
    hasReceivedReward[recipient] = true;
}
```

---

## EIP-1884 and Gas Stipends

### The 2300 Gas Stipend Problem

Prior to EIP-1884 (Istanbul hard fork), the common pattern was:

```solidity
recipient.transfer(amount);  // 2300 gas stipend
// or
recipient.send(amount);      // 2300 gas stipend
```

**EIP-1884 Changed Everything:**
- Increased gas cost of `SLOAD` from 200 to 800 gas
- The 2300 gas stipend is no longer sufficient for many operations
- Even a simple fallback function might fail

**Example of EIP-1884 Impact:**
```solidity
contract Recipient {
    uint256 private balance;

    receive() external payable {
        balance += msg.value;  // SLOAD (800) + SSTORE (20000)
        // This FAILS with 2300 gas stipend!
    }
}
```

### Modern Best Practice: Forward More Gas

```solidity
// BAD: Fixed 2300 gas
recipient.transfer(amount);

// GOOD: Forward sufficient gas (but not all gas)
(bool success, ) = recipient.call{value: amount}("");
require(success, "Transfer failed");
```

---

## Storage Diagrams for Withdrawal Queues

### Simple Withdrawal Mapping

```
┌─────────────────────────────────────────┐
│     Withdrawal Queue Storage            │
├─────────────────────────────────────────┤
│                                         │
│  mapping(address => uint256) balances   │
│                                         │
│  ┌──────────────┬──────────────┐       │
│  │   Address    │   Balance    │       │
│  ├──────────────┼──────────────┤       │
│  │  0x123...    │  1.5 ETH     │       │
│  │  0x456...    │  0.8 ETH     │       │
│  │  0x789...    │  2.0 ETH     │       │
│  └──────────────┴──────────────┘       │
│                                         │
│  Storage Slot: keccak256(address || slot) │
│  Gas Cost: 20,000 (cold SLOAD)         │
│            2,100 (warm SLOAD)           │
└─────────────────────────────────────────┘
```

### Advanced Queue with Metadata

```
┌─────────────────────────────────────────────────┐
│     Enhanced Withdrawal Queue                   │
├─────────────────────────────────────────────────┤
│                                                 │
│  struct Withdrawal {                            │
│      uint256 amount;                            │
│      uint256 timestamp;                         │
│      bool processed;                            │
│  }                                              │
│                                                 │
│  mapping(address => Withdrawal) withdrawals     │
│                                                 │
│  ┌─────────┬──────────┬─────────────┬──────┐  │
│  │ Address │  Amount  │  Timestamp  │ Done │  │
│  ├─────────┼──────────┼─────────────┼──────┤  │
│  │ 0x123   │ 1.5 ETH  │ 1699999999  │  ✓   │  │
│  │ 0x456   │ 0.8 ETH  │ 1700000123  │  ✗   │  │
│  │ 0x789   │ 2.0 ETH  │ 1700001000  │  ✗   │  │
│  └─────────┴──────────┴─────────────┴──────┘  │
│                                                 │
│  Storage: 3 slots per withdrawal                │
│  Gas: ~60,000 for first write (cold)           │
└─────────────────────────────────────────────────┘
```

---

## Security Pitfalls and Solutions

### Pitfall 1: Check-Effects-Interactions Violation

```solidity
// VULNERABLE
function withdraw() public {
    uint256 amount = balances[msg.sender];
    // DANGER: External call before state change
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success);
    balances[msg.sender] = 0;  // TOO LATE!
}

// SECURE
function withdraw() public {
    uint256 amount = balances[msg.sender];
    balances[msg.sender] = 0;  // Update state FIRST
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success);
}
```

### Pitfall 2: Not Handling Failed Transfers

```solidity
// BAD: Funds are lost if transfer fails
function withdraw() public {
    uint256 amount = balances[msg.sender];
    balances[msg.sender] = 0;
    msg.sender.call{value: amount}("");  // Ignores failure!
}

// GOOD: Revert on failure to preserve state
function withdraw() public {
    uint256 amount = balances[msg.sender];
    balances[msg.sender] = 0;
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed");  // State reverts
}
```

### Pitfall 3: Integer Overflow/Underflow

```solidity
// Pre-0.8.0: VULNERABLE
function deposit() public payable {
    balances[msg.sender] += msg.value;  // Can overflow!
}

// Post-0.8.0: SAFE (automatic checks)
// Or use SafeMath explicitly
```

### Pitfall 4: Unprotected Self-Destruct

```solidity
// VULNERABLE
function destroy() public {
    selfdestruct(payable(owner));  // Anyone can call!
}

// SECURE
function destroy() public {
    require(msg.sender == owner, "Not owner");
    selfdestruct(payable(owner));
}
```

---

## Gas Analysis

### Deposit Function

```solidity
function deposit() public payable {
    balances[msg.sender] += msg.value;
    emit Deposited(msg.sender, msg.value);
}
```

**Gas Breakdown:**
- `SLOAD` (cold): 2,100 gas (read balance)
- `SSTORE` (non-zero to non-zero): 5,000 gas
- `SSTORE` (zero to non-zero): 20,000 gas (first deposit)
- `LOG2` (event): ~1,500 gas
- Base transaction: 21,000 gas

**Total:**
- First deposit: ~44,600 gas
- Subsequent deposits: ~29,600 gas

### Withdraw Function

```solidity
function withdraw() public {
    uint256 amount = balances[msg.sender];
    require(amount > 0, "No balance");

    balances[msg.sender] = 0;

    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed");

    emit Withdrawn(msg.sender, amount);
}
```

**Gas Breakdown:**
- `SLOAD` (cold): 2,100 gas (read balance)
- `SSTORE` (non-zero to zero): -15,000 gas (gas refund)
- `CALL`: 9,000 base + 2,300 stipend + recipient code
- `LOG2` (event): ~1,500 gas
- Base transaction: 21,000 gas

**Total:**
- ~30,000-50,000 gas (depends on recipient)

### Gas Refunds

Since Solidity 0.8.0 and EIP-3529:
- Storage refunds are capped at 20% of gas used
- Setting storage to zero gives refund, but limited
- Old refund: 15,000 gas
- New refund: Capped by transaction gas

---

## Common Attack Vectors

### 1. Reentrancy Attack

```solidity
contract Attacker {
    VulnerableContract target;

    function attack() public payable {
        target.deposit{value: 1 ether}();
        target.withdraw();
    }

    receive() external payable {
        if (address(target).balance >= 1 ether) {
            target.withdraw();  // Re-enter!
        }
    }
}
```

**Defense:** Checks-Effects-Interactions pattern

### 2. DoS by Block Gas Limit

```solidity
// Attacker creates many small deposits
for (uint i = 0; i < 1000; i++) {
    target.deposit{value: 1 wei}();
}

// Now any function iterating over deposits fails
```

**Defense:** Use pull pattern, never iterate unbounded arrays

### 3. Force-Feeding ETH

```solidity
// Contract with strict balance check
require(address(this).balance == expectedBalance);

// Attacker can break this with selfdestruct
selfdestruct(payable(targetContract));
```

**Defense:** Never rely on exact balance checks

---

## Implementation Checklist

- [ ] Use pull payment pattern for all ETH transfers
- [ ] Follow Checks-Effects-Interactions pattern
- [ ] Handle failed transfers appropriately
- [ ] Emit events for all state changes
- [ ] Protect against reentrancy
- [ ] Avoid unbounded loops
- [ ] Use OpenZeppelin's ReentrancyGuard
- [ ] Test with malicious contracts
- [ ] Consider emergency withdrawal mechanisms
- [ ] Document all edge cases

---

## Testing Strategy

### Unit Tests
- Test successful deposits
- Test successful withdrawals
- Test zero balance withdrawals
- Test reentrancy protection
- Test event emissions

### Integration Tests
- Test with contracts that reject ETH
- Test with contracts that consume lots of gas
- Test gas limits
- Test multiple users

### Fuzzing Tests
- Random deposit amounts
- Random withdrawal patterns
- Edge case amounts (0, MAX_UINT256)

---

## Best Practices Summary

1. **Always use pull payments** for distributing funds to multiple recipients
2. **Follow CEI pattern**: Checks → Effects → Interactions
3. **Handle failures**: Never ignore return values from `.call()`
4. **Use ReentrancyGuard**: Defense in depth
5. **Emit events**: Make all state changes observable
6. **Test thoroughly**: Include malicious contract tests
7. **Document**: Explain security decisions in comments
8. **Gas considerations**: Forward appropriate gas, not all gas

---

## Additional Resources

- [ConsenSys Best Practices: Pull over Push](https://consensys.github.io/smart-contract-best-practices/attacks/denial-of-service/#favor-pull-over-push-for-external-calls)
- [OpenZeppelin Pull Payment](https://docs.openzeppelin.com/contracts/4.x/api/security#PullPayment)
- [EIP-1884: Repricing for trie-size-dependent opcodes](https://eips.ethereum.org/EIPS/eip-1884)
- [SWC-107: Reentrancy](https://swcregistry.io/docs/SWC-107)
- [SWC-113: DoS with Failed Call](https://swcregistry.io/docs/SWC-113)

---

## Project Structure

```
12-safe-eth-transfer/
├── README.md
├── src/
│   ├── SafeETHTransfer.sol           # Skeleton with TODOs
│   └── solution/
│       └── SafeETHTransferSolution.sol # Complete implementation
├── test/
│   └── SafeETHTransfer.t.sol         # Comprehensive tests
└── script/
    └── DeploySafeETHTransfer.s.sol   # Deployment script
```

---

## Getting Started

1. Read this README thoroughly
2. Study the skeleton contract in `src/SafeETHTransfer.sol`
3. Try implementing the TODOs yourself
4. Run tests: `forge test`
5. Compare with solution in `src/solution/SafeETHTransferSolution.sol`

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/SafeETHTransferSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeploySafeETHTransferSolution.s.sol` - Deployment script patterns
- `test/solution/SafeETHTransferSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains pull payment pattern (DoS prevention), mutex pattern (reentrancy guard)
- **Connections to Projects 02 & 07**: Builds on CEI pattern and safe ETH transfer patterns
- **Security Patterns**: Demonstrates pull-over-push pattern to prevent DoS attacks
- **Real-World Context**: Pattern used in production contracts (OpenZeppelin, Uniswap)
6. Deploy: `forge script script/DeploySafeETHTransfer.s.sol`

Happy learning!

---


## 13-block-time-logic

# Project 13: Block Properties & Time Logic ⏰

> **Master blockchain time and block properties safely**

## 🎯 Learning Objectives

By completing this project, you will:

1. **Understand `block.timestamp` vs `block.number`** and when to use each
2. **Learn about miner manipulation** possibilities and risks
3. **Implement rate limiting patterns** to prevent spam
4. **Create cooldown mechanisms** for two-step processes
5. **Recognize time-based exploits** and avoid them
6. **Use Foundry's time manipulation** (`vm.warp()`, `vm.roll()`, `skip()`)
7. **Implement vesting schedules** and time-locked vaults
8. **Create Foundry deployment scripts** for time-based contracts
9. **Write comprehensive test suites** with time manipulation

## Block Properties Deep Dive

### block.timestamp: Human-Readable Time

**FIRST PRINCIPLES: Miner-Controlled Time**

`block.timestamp` is the Unix timestamp (seconds since January 1, 1970) when the block was mined. Understanding its limitations is critical for secure time-based logic!

**CONNECTION TO PROJECT 11**:
ERC-4626 vaults use `block.timestamp` for yield calculations and vesting schedules. Understanding timestamp manipulation is essential!

**KEY CHARACTERISTICS**:
- Measured in seconds (Unix timestamp)
- Set by the block miner (not perfectly accurate!)
- Subject to ~15 second drift allowance (manipulation possible!)
- Can be manipulated within limits by miners
- More human-readable for time periods

**UNDERSTANDING MINER MANIPULATION**:

```
Timestamp Setting Process:
┌─────────────────────────────────────────┐
│ Miner creates block                    │
│   ↓                                      │
│ Miner sets block.timestamp              │ ← Miner chooses!
│   ↓                                      │
│ Constraints:                            │
│   - Must be > parent block timestamp    │ ← Can't go backwards
│   - Must be within ~15s of real time    │ ← Can manipulate ±15s
│   ↓                                      │
│ Other nodes validate                    │ ← Reject if invalid
│   ↓                                      │
│ Block accepted if valid                  │
└─────────────────────────────────────────┘
```

**EXAMPLE**:
```solidity
// Current timestamp
uint256 currentTime = block.timestamp;  // e.g., 1699876543

// Check if 1 day has passed
require(block.timestamp >= lastAction + 1 days, "Too soon");
// 1 days = 86400 seconds
// Safe for long periods (15s manipulation is negligible)
```

**GAS COST** (from Project 01 knowledge):
- Reading `block.timestamp`: ~2 gas (special opcode, very cheap!)
- Time comparisons: ~3 gas (arithmetic operations)

### block.number: Block-Based Time

**FIRST PRINCIPLES: Deterministic Block Counting**

`block.number` is the sequential number of the current block in the blockchain. It's more predictable than timestamp but less human-readable.

**KEY CHARACTERISTICS**:
- Increments by 1 for each block (deterministic!)
- Cannot be manipulated (other than by controlling block production)
- More predictable than timestamp
- Average block time: ~12 seconds on Ethereum mainnet
- Block time varies by network (e.g., 2s on Polygon, 1s on BSC)

**UNDERSTANDING BLOCK TIME VARIANCE**:

```
Block Production:
┌─────────────────────────────────────────┐
│ Ethereum Mainnet:                       │
│   Average: ~12 seconds per block         │
│   Range: 10-20 seconds (variable)        │
│                                          │
│ Polygon:                                 │
│   Average: ~2 seconds per block          │
│   Range: 1-3 seconds                     │
│                                          │
│ block.number increments deterministically│ ← Always +1
│   ↓                                      │
│ Cannot be manipulated by miners!        │ ← More secure
└─────────────────────────────────────────┘
```

**EXAMPLE**:
```solidity
// Current block number
uint256 currentBlock = block.number;  // e.g., 18500000

// Check if 100 blocks have passed (~20 minutes on Ethereum)
require(block.number >= lastBlock + 100, "Too soon");
// 100 blocks × 12 seconds = ~20 minutes
// More predictable than timestamp!
```

**GAS COST**:
- Reading `block.number`: ~2 gas (special opcode, very cheap!)
- Block comparisons: ~3 gas (arithmetic operations)

**COMPARISON TO RUST** (Conceptual):

**Rust** (can get real time):
```rust
use std::time::{SystemTime, UNIX_EPOCH};

let timestamp = SystemTime::now()
    .duration_since(UNIX_EPOCH)
    .unwrap()
    .as_secs();
// Real time, not manipulable
```

**Solidity** (blockchain time):
```solidity
uint256 timestamp = block.timestamp;  // Miner-controlled, ±15s variance
uint256 blockNum = block.number;      // Deterministic, but time varies
```

Blockchain time is fundamentally different - it's approximate and miner-controlled!

**Example:**
```solidity
// Current block number
uint256 currentBlock = block.number;

// Check if 100 blocks have passed (~20 minutes on Ethereum)
require(block.number >= lastBlock + 100, "Too soon");
```

## Miner Manipulation: Understanding the Risks

**FIRST PRINCIPLES: Trust in Decentralized Systems**

Ethereum protocol allows miners to set `block.timestamp` with constraints. Understanding these limits is critical for secure time-based logic!

**CONNECTION TO PROJECT 07**:
Time-based logic can be exploited if not designed carefully. Understanding manipulation limits helps prevent vulnerabilities!

### The 15-Second Drift Rule

Ethereum protocol allows miners to set `block.timestamp` with these constraints:
- Must be greater than the parent block's timestamp (monotonic)
- Must be within ~15 seconds of the actual time (drift limit)
- Other nodes will reject blocks that violate these rules (consensus enforcement)

**UNDERSTANDING THE CONSTRAINTS**:

```
Timestamp Validation:
┌─────────────────────────────────────────┐
│ Miner sets timestamp: T                 │
│   ↓                                      │
│ Check 1: T > parent.timestamp?          │ ← Must be increasing
│   ❌ No → Block rejected                 │
│   ✅ Yes → Continue                      │
│   ↓                                      │
│ Check 2: |T - real_time| < 15s?         │ ← Drift limit
│   ❌ No → Block rejected                 │
│   ✅ Yes → Block accepted                │
└─────────────────────────────────────────┘
```

**WHAT THIS MEANS**:
- Miners can manipulate timestamp by ±15 seconds (within limits)
- For short time periods (<15 seconds), timestamp is unreliable
- For longer periods (hours/days), manipulation is negligible

**SECURITY IMPLICATIONS**:

**Vulnerable Pattern**:
```solidity
// ❌ DANGEROUS: Short time window
function claimReward() external {
    require(block.timestamp % 10 == 0, "Only on even 10s");
    // Miner can manipulate ±15s to hit this condition!
    // Attack: Miner sets timestamp to even 10s, claims reward
}
```

**Safe Pattern**:
```solidity
// ✅ SAFE: Long time period
function claimReward() external {
    require(block.timestamp >= lastClaim + 1 days, "24h cooldown");
    // 15 second manipulation is negligible over 24 hours
    // Attack: Miner can only manipulate ±15s (0.017% of 24h)
}
```

**REAL-WORLD ANALOGY**: 
Like a clock that can be set ±15 seconds - fine for long periods (days), but unreliable for short periods (seconds). Always design for worst-case manipulation!

### Attack Scenarios

**Vulnerable code:**
```solidity
// DANGEROUS: Can be manipulated
function claimReward() external {
    require(block.timestamp % 10 == 0, "Only on even 10s");
    // Miner can manipulate to hit this condition
}
```

**Safer code:**
```solidity
// BETTER: Long time periods are safer
function claimReward() external {
    require(block.timestamp >= lastClaim + 1 days, "24h cooldown");
    // 15 second manipulation is negligible over 1 day
}
```

## When to Use Each Approach

### Use block.timestamp when:
- Time periods are measured in hours, days, weeks, or longer
- Human-readable time matters (e.g., "7 day voting period")
- Exact timing isn't critical for security
- You need to work with specific dates/times

**Good use cases:**
- Vesting schedules
- Lock-up periods
- Voting durations
- Auction end times
- Cooldown periods (>1 hour)

### Use block.number when:
- You need more predictable intervals
- Security depends on precise ordering
- Working with short time periods
- You want network-agnostic logic

**Good use cases:**
- Snapshot mechanisms
- Oracle price updates
- Rate limiting (very short periods)
- Governance checkpoints

### Avoid time-based logic when:
- Security depends on exact second precision
- Time periods are < 15 seconds
- Randomness is involved (never use block properties for randomness!)

## Common Patterns

### 1. Rate Limiting

Restrict how often an action can be performed.

```solidity
mapping(address => uint256) public lastActionTime;
uint256 public constant RATE_LIMIT = 1 hours;

function rateLimitedAction() external {
    require(
        block.timestamp >= lastActionTime[msg.sender] + RATE_LIMIT,
        "Rate limit active"
    );

    lastActionTime[msg.sender] = block.timestamp;
    // Perform action...
}
```

### 2. Cooldown Period

Enforce waiting time between state changes.

```solidity
mapping(address => uint256) public cooldownStart;
uint256 public constant COOLDOWN_PERIOD = 7 days;

function initiateCooldown() external {
    cooldownStart[msg.sender] = block.timestamp;
}

function executeAfterCooldown() external {
    require(
        cooldownStart[msg.sender] != 0,
        "Cooldown not initiated"
    );
    require(
        block.timestamp >= cooldownStart[msg.sender] + COOLDOWN_PERIOD,
        "Cooldown not finished"
    );

    cooldownStart[msg.sender] = 0;
    // Execute action...
}
```

### 3. Time-Locked Vault

Lock funds until a specific time.

```solidity
uint256 public unlockTime;

constructor(uint256 _lockDuration) {
    unlockTime = block.timestamp + _lockDuration;
}

function withdraw() external {
    require(block.timestamp >= unlockTime, "Still locked");
    // Withdraw logic...
}
```

### 4. Deadline Enforcement

Ensure actions happen before a deadline.

```solidity
uint256 public deadline;

function submitProposal() external {
    require(block.timestamp <= deadline, "Deadline passed");
    // Submit logic...
}
```

## Testing Time-Based Logic

Foundry provides powerful time manipulation tools:

### vm.warp(timestamp)

Sets `block.timestamp` to a specific value.

```solidity
function testCooldown() public {
    // Set to a known time
    vm.warp(1000);

    contract.initiateCooldown();

    // Fast forward 7 days
    vm.warp(1000 + 7 days);

    contract.executeAfterCooldown();
}
```

### vm.roll(blockNumber)

Sets `block.number` to a specific value.

```solidity
function testBlockBased() public {
    vm.roll(100);

    contract.doSomething();

    // Advance 100 blocks
    vm.roll(200);

    contract.doSomethingElse();
}
```

### skip(duration)

Advances `block.timestamp` by a duration.

```solidity
function testRateLimit() public {
    contract.action();

    // Try too soon
    vm.expectRevert("Rate limit active");
    contract.action();

    // Skip forward
    skip(1 hours);

    // Should work now
    contract.action();
}
```

## Common Pitfalls & Exploits

### 1. Short Time Windows

**Problem:**
```solidity
// VULNERABLE
require(block.timestamp % 60 < 10, "Only in first 10 seconds of each minute");
```

**Why:** Miner can manipulate within 15 seconds to hit this window.

### 2. Timestamp as Randomness

**Problem:**
```solidity
// NEVER DO THIS
uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp))) % 100;
```

**Why:** Miners can manipulate timestamp AND see the value before mining.

### 3. Comparison with block.timestamp Equality

**Problem:**
```solidity
// FRAGILE
require(block.timestamp == unlockTime, "Not exact time");
```

**Why:** Very unlikely to execute at exact second. Use `>=` instead.

**Fix:**
```solidity
// CORRECT
require(block.timestamp >= unlockTime, "Not yet unlocked");
```

### 4. Overflow with Arithmetic

**Problem (pre-0.8.0):**
```solidity
// Could overflow
uint256 deadline = block.timestamp + 100 days;
```

**Why:** In Solidity <0.8.0, this could overflow. Always use SafeMath or 0.8.0+.

### 5. Network-Specific Assumptions

**Problem:**
```solidity
// Assumes Ethereum block time
uint256 blocksPerDay = 7200; // 12 second blocks
```

**Why:** Different networks have different block times (Polygon ~2s, BSC ~3s).

## Real-World Examples

### DeFi Vesting
```solidity
// Vesting contract releases tokens over time
function calculateVested() public view returns (uint256) {
    if (block.timestamp < startTime) return 0;
    if (block.timestamp >= startTime + duration) return totalAmount;

    uint256 elapsed = block.timestamp - startTime;
    return (totalAmount * elapsed) / duration;
}
```

### Governance Voting
```solidity
// Voting period with clear start/end times
require(block.timestamp >= proposalStart, "Not started");
require(block.timestamp <= proposalEnd, "Voting ended");
```

### Flash Loan Protection
```solidity
// Prevent flash loan attacks with cooldown
require(
    lastDepositBlock[msg.sender] < block.number,
    "No same-block withdraw"
);
```

## Security Best Practices

1. **Use timestamp for long periods (>1 hour):** Manipulation is negligible.
2. **Use block.number for short periods:** More predictable.
3. **Never use for randomness:** Use Chainlink VRF or similar.
4. **Use >= not ==:** Time won't hit exact seconds.
5. **Document assumptions:** Note block time assumptions.
6. **Test edge cases:** Use vm.warp() and vm.roll() extensively.
7. **Consider MEV:** Miners/validators can see pending transactions.

## Project Tasks

In this project, you will implement:

1. **TimeLockedVault:** Lock ETH until a specific timestamp
2. **RateLimiter:** Allow actions only after a cooldown period
3. **BlockBasedLottery:** Use block numbers for fair lottery mechanics
4. **VestingWallet:** Release tokens linearly over time

Each implementation will include security considerations and proper testing.

## Resources

- [Solidity Documentation - Block and Transaction Properties](https://docs.soliditylang.org/en/latest/units-and-global-variables.html#block-and-transaction-properties)
- [Consensys Best Practices - Timestamp Dependence](https://consensys.github.io/smart-contract-best-practices/development-recommendations/solidity-specific/timestamp-dependence/)
- [SWC-116: Block values as a proxy for time](https://swcregistry.io/docs/SWC-116)
- [Foundry Cheatcodes - Time](https://book.getfoundry.sh/cheatcodes/warp)

## Running the Project

```bash
# Run tests
forge test --match-path test/BlockTimeLogic.t.sol -vvv

# Run specific test
forge test --match-test testRateLimit -vvv

# Deploy
forge script script/DeployBlockTimeLogic.s.sol --rpc-url <your-rpc> --broadcast

# Test with gas report
forge test --match-path test/BlockTimeLogic.t.sol --gas-report
```

## Success Criteria

- All tests pass
- Understand timestamp vs block number tradeoffs
- Can identify vulnerable time-based code
- Know when each approach is appropriate
- Can use vm.warp() and vm.roll() for testing

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/BlockTimeLogicSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployBlockTimeLogicSolution.s.sol` - Deployment script patterns
- `test/solution/BlockTimeLogicSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains time-based state machines, rate limiting, linear interpolation (vesting)
- **Connections to Projects 01-04**: References storage patterns, access control, and modifier patterns
- **Security Patterns**: Demonstrates safe time comparisons (always use >=, not ==)
- **Real-World Context**: Used in vesting schedules, time-locked vaults, rate limiting

---


## 14-abi-encoding

# Project 14: ABI Encoding & Function Selectors

> **Master low-level encoding, function selectors, and security pitfalls**

## Learning Objectives

- Understand `abi.encode` vs `abi.encodePacked` vs `abi.encodeWithSignature`
- Calculate and use function selectors
- Recognize selector collision risks
- Identify hash collision vulnerabilities with `encodePacked`
- Implement manual function routing with fallback
- Choose the right encoding method for each use case

## Key Concepts

### ABI Encoding Methods

Solidity provides several encoding functions, each with different use cases and security implications:

#### 1. `abi.encode` - Standard ABI Encoding

```solidity
// Adds padding, unambiguous
abi.encode("AA", "BB")
// → 0x0000...0020 (offset for "AA")
//    0000...0060 (offset for "BB")
//    0000...0002 (length of "AA")
//    4141000000... (padded "AA")
//    0000...0002 (length of "BB")
//    4242000000... (padded "BB")
```

**Use when:**
- Encoding function call data
- Need unambiguous encoding
- Working with contracts that expect standard ABI

#### 2. `abi.encodePacked` - Tight Packing (Dangerous!)

**FIRST PRINCIPLES: Hash Collision Vulnerability**

`abi.encodePacked` concatenates values without padding, making it compact but **dangerous** due to collision risks!

**CONNECTION TO PROJECT 01**:
We learned about `keccak256` hashing in Project 01 for storage calculations. `abi.encodePacked` is often used with `keccak256`, but must be used carefully!

```solidity
// No padding, compact but dangerous
abi.encodePacked("AA", "BB")
// → 0x41414242 (just the bytes)

// ⚠️ COLLISION RISK!
abi.encodePacked("A", "ABB") == abi.encodePacked("AA", "BB") // true!
// Both produce: 0x41414242
```

**UNDERSTANDING THE COLLISION**:

```
Why Collisions Happen:
┌─────────────────────────────────────────┐
│ encodePacked("A", "ABB"):               │
│   "A" = 0x41                            │
│   "ABB" = 0x414242                      │
│   Result: 0x41414242                     │
│                                          │
│ encodePacked("AA", "BB"):               │
│   "AA" = 0x4141                         │
│   "BB" = 0x4242                         │
│   Result: 0x41414242                     │ ← SAME!
└─────────────────────────────────────────┘

No delimiter = Ambiguity!
```

**SECURITY IMPLICATIONS**:

**Vulnerable Example**:
```solidity
// ❌ DANGEROUS: Collision possible!
bytes32 hash = keccak256(abi.encodePacked(user, amount));
// Attacker can manipulate: ("Alice", 100) vs ("Ali", "ce100")
```

**Safe Example**:
```solidity
// ✅ SAFE: Unambiguous encoding
bytes32 hash = keccak256(abi.encode(user, amount));
// Each value padded, no collision possible
```

**Use when:**
- Computing hashes (with caution!)
- Gas optimization for storage
- Working with `keccak256` for signatures
- **BUT**: Only with fixed-size types or single dynamic type!

**DANGER:** Never use with multiple variable-length types in critical contexts!

**COMPARISON TO RUST** (DSA Concept):

**Rust** (similar concatenation risk):
```rust
// Similar risk with string concatenation
let hash1 = sha256(format!("{}{}", "A", "ABB"));
let hash2 = sha256(format!("{}{}", "AA", "BB"));
// Could collide if not careful with delimiters
```

**Solidity** (encodePacked):
```solidity
bytes32 hash1 = keccak256(abi.encodePacked("A", "ABB"));
bytes32 hash2 = keccak256(abi.encodePacked("AA", "BB"));
// Collision risk - use abi.encode instead!
```

Both have similar risks - always use delimiters or unambiguous encoding!

#### 3. `abi.encodeWithSignature` - Function Calls

```solidity
// Includes 4-byte function selector
abi.encodeWithSignature("transfer(address,uint256)", to, amount)
// → 0xa9059cbb (selector) + encoded parameters
```

**Use when:**
- Making dynamic contract calls
- Implementing proxy patterns
- Building meta-transaction systems

### Function Selectors

Function selectors are the first 4 bytes of the keccak256 hash of the function signature:

```solidity
bytes4 selector = bytes4(keccak256("transfer(address,uint256)"));
// → 0xa9059cbb
```

**Key points:**
- Only 4 bytes (32 bits) → ~4.3 billion possibilities
- Birthday paradox: ~77k functions have 50% collision chance
- Malicious contracts can create intentional collisions
- Used for function dispatching in the EVM

### Hash Collision with encodePacked

When using `abi.encodePacked` with multiple dynamic-length arguments:

```solidity
// VULNERABLE: These produce the same hash!
keccak256(abi.encodePacked("A", "BC"))
keccak256(abi.encodePacked("AB", "C"))

// SAFE: Use abi.encode instead
keccak256(abi.encode("A", "BC")) != keccak256(abi.encode("AB", "C"))
```

**Real-world impact:**
- Signature replay attacks
- Authorization bypasses
- Merkle tree manipulation

### When to Use Each Method

| Method | Padding | Gas | Collision Risk | Use Case |
|--------|---------|-----|----------------|----------|
| `abi.encode` | Yes | Higher | None | Function calls, standard ABI |
| `abi.encodePacked` | No | Lower | HIGH | Hashing (carefully), gas optimization |
| `abi.encodeWithSignature` | Yes | Higher | None | Dynamic calls, proxies |
| `abi.encodeWithSelector` | Yes | Lower | None | Known selectors, gas saving |

## Security Checklist

- [ ] Never use `encodePacked` with multiple variable-length types for signatures
- [ ] Always validate function selectors in fallback functions
- [ ] Be aware of potential selector collisions in untrusted contracts
- [ ] Use `abi.encode` for hashing when collision resistance is critical
- [ ] Test for collision scenarios in security-critical code

## Common Vulnerabilities

### 1. Hash Collision in Signatures

```solidity
// VULNERABLE
function verify(string memory a, string memory b) public view returns (bool) {
    bytes32 hash = keccak256(abi.encodePacked(a, b));
    return hash == storedHash;
}

// Attacker: verify("A", "BC") == verify("AB", "C")
```

### 2. Selector Collision Attack

```solidity
// Attacker creates collisionFunc() with same selector as adminFunc()
// If contract only checks selector, both functions execute same code
```

### 3. Unchecked Fallback Routing

```solidity
fallback() external payable {
    // VULNERABLE: No selector validation
    address(implementation).delegatecall(msg.data);
}
```

## Tasks

```bash
cd 14-abi-encoding

# Run tests to see encoding differences
forge test -vvv

# See gas comparison
forge test --gas-report

# Run specific collision tests
forge test --match-test testHashCollision -vvv
```

### Implementation Checklist

Skeleton contract (`src/ABIEncoding.sol`):
- [ ] Implement encoding demonstration functions
- [ ] Calculate function selectors
- [ ] Create collision examples
- [ ] Build manual function router
- [ ] Add security comments

## Expected Output

```
Running tests...

[PASS] testEncodeVsEncodePacked() (gas: 15234)
Logs:
  abi.encode length: 192
  abi.encodePacked length: 4

[PASS] testHashCollision() (gas: 12456)
Logs:
  Hash 1: 0x1234...
  Hash 2: 0x1234... (COLLISION!)

[PASS] testFunctionSelector() (gas: 8901)
Logs:
  Selector: 0xa9059cbb
```

## Advanced Topics

### Function Selector Optimization

```solidity
// Gas efficient: pre-computed selector
bytes4 constant TRANSFER_SELECTOR = 0xa9059cbb;

// vs computing each time
bytes4 selector = bytes4(keccak256("transfer(address,uint256)"));
```

### Safe Multi-Argument Hashing

```solidity
// UNSAFE
keccak256(abi.encodePacked(a, b, c))

// SAFE - Add separators
keccak256(abi.encodePacked(a, ":", b, ":", c))

// SAFEST - Use abi.encode
keccak256(abi.encode(a, b, c))
```

## Real-World Examples

1. **OpenZeppelin's EIP-712** - Uses `abi.encode` for typed data hashing
2. **Uniswap V2** - Uses `encodePacked` carefully in pair creation
3. **ECDSA Signatures** - Always use `abi.encode` for message hashing
4. **Proxy Patterns** - Use `encodeWithSelector` for delegatecalls

## Common Mistakes

1. Using `encodePacked` for signature verification
2. Not validating selectors in fallback functions
3. Assuming 4-byte selectors are collision-resistant
4. Mixing encoding methods in security-critical code
5. Not testing for collision scenarios

## Resources

- [Solidity Docs: ABI Encoding](https://docs.soliditylang.org/en/latest/abi-spec.html)
- [SWC-133: Hash Collisions](https://swcregistry.io/docs/SWC-133)
- [EIP-712: Typed Data Signing](https://eips.ethereum.org/EIPS/eip-712)
- [Function Selector Database](https://www.4byte.directory/)

## Status

 **Ready to Learn** - Critical encoding concepts

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/ABIEncodingSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployABIEncodingSolution.s.sol` - Deployment script patterns
- `test/solution/ABIEncodingSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains serialization, hash collisions, function dispatch mechanisms
- **Connections to Project 01**: Storage slot calculation uses keccak256(abi.encodePacked(...))
- **Connections to Project 02**: Function calls use selectors for routing
- **Connections to Project 15**: Low-level calls use ABI encoding
- **Real-World Context**: Critical for proxy patterns, function routing, and data encoding

## Next Steps

After completing this project, you'll understand:
- How the EVM dispatches function calls
- Why encoding method choice matters for security
- How to prevent hash collision attacks
- When to use each encoding variant

**Challenge**: Try finding two different function signatures with the same selector!

---


## 15-low-level-calls

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

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/LowLevelCallsSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployLowLevelCallsSolution.s.sol` - Deployment script patterns
- `test/solution/LowLevelCallsSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains message passing, execution context, call vs delegatecall differences
- **Connections to Project 02**: .call{value:}() for ETH transfers
- **Connections to Project 10**: delegatecall for proxy patterns
- **Connections to Project 14**: ABI encoding for call data
- **Real-World Context**: Foundation for all contract interactions and upgradeable proxies

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

---


## 16-contract-factories

# Project 16: Contract Factories (CREATE2)

Learn how to deploy contracts with deterministic addresses using CREATE2 opcode, enabling address prediction before deployment.

## Overview

This project explores CREATE2, an opcode introduced in EIP-1014 that allows deploying contracts to deterministic addresses. Unlike CREATE, CREATE2 makes the deployment address predictable and independent of the deployer's nonce.

## Learning Objectives

- Understand CREATE vs CREATE2
- Calculate deterministic addresses
- Use salts for unique deployments
- Distinguish initcode from runtime code
- Predict addresses off-chain
- Implement counterfactual contracts

## CREATE vs CREATE2

### CREATE (Traditional Deployment)

When you deploy a contract normally, the address is calculated as:

```
address = keccak256(rlp([sender_address, sender_nonce]))[12:]
```

**Characteristics:**
- Address depends on deployer's nonce
- Non-deterministic (nonce changes with each transaction)
- Cannot predict address before deployment
- Standard `new Contract()` syntax uses CREATE

**Example:**
```solidity
// Uses CREATE
MyContract instance = new MyContract();
// Address depends on factory's nonce at deployment time
```

### CREATE2 (Deterministic Deployment): Predictable Addresses

**FIRST PRINCIPLES: Deterministic Address Calculation**

CREATE2 calculates the address deterministically, enabling address prediction before deployment. This is powerful for counterfactual contracts and address-based logic!

**CONNECTION TO PROJECT 01**:
We learned about `keccak256` hashing in Project 01. CREATE2 uses keccak256 to calculate deterministic addresses!

CREATE2 calculates the address as:

```
address = keccak256(0xff ++ sender_address ++ salt ++ keccak256(initCode))[12:]
```

**UNDERSTANDING THE FORMULA**:

```
CREATE2 Address Calculation:
┌─────────────────────────────────────────┐
│ Input Components:                       │
│   1. 0xff (1 byte)                     │ ← Prefix to distinguish from CREATE
│   2. sender_address (20 bytes)         │ ← Factory contract address
│   3. salt (32 bytes)                    │ ← Chosen by deployer
│   4. keccak256(initCode) (32 bytes)    │ ← Hash of creation bytecode
│   ↓                                      │
│ Concatenate: 0xff || sender || salt || hash │
│   ↓                                      │
│ Hash: keccak256(concatenated)           │ ← Single hash operation
│   ↓                                      │
│ Extract: last 20 bytes                  │ ← Address format
│   ↓                                      │
│ Result: Deterministic address!          │ ← Always the same!
└─────────────────────────────────────────┘
```

**CHARACTERISTICS:**
- Address is deterministic and predictable ✅
- Independent of nonce ✅ (unlike CREATE)
- Depends on: deployer address, salt, and contract bytecode
- Enables address prediction before deployment
- Requires assembly or specific syntax

**COMPONENTS BREAKDOWN**:

1. **`0xff`** - Constant prefix to distinguish from CREATE
   - Prevents collision with CREATE addresses
   - Single byte: `0xff`

2. **`sender_address`** - Factory contract address (20 bytes)
   - The contract deploying (factory)
   - From Project 01: address type is 20 bytes

3. **`salt`** - 32-byte value chosen by deployer
   - Allows multiple deployments with same bytecode
   - Different salt = different address
   - From Project 01: bytes32 type

4. **`initCode`** - Contract creation bytecode (constructor + runtime code)
   - Includes constructor parameters
   - Hash ensures bytecode changes = address changes

**USE CASES**:

1. **Counterfactual Contracts**: Deploy only when needed
2. **Address-Based Logic**: Know address before deployment
3. **Minimal Proxies**: Deploy many instances efficiently
4. **State Channels**: Predictable addresses for channels

**GAS COST** (from Project 01 knowledge):
- CREATE2 deployment: ~32,000 gas (base) + contract size
- Address calculation: ~100 gas (keccak256 computation)
- Prediction: FREE (off-chain calculation)

**COMPARISON TO RUST** (Conceptual):

**Rust** (no direct equivalent):
```rust
// Rust doesn't have deterministic deployment
// But similar concept: deterministic IDs based on content
let id = sha256(format!("{}{}{}", prefix, salt, content));
```

**Solidity** (CREATE2):
```solidity
address predicted = address(uint160(uint256(keccak256(abi.encodePacked(
    bytes1(0xff),
    factory,
    salt,
    keccak256(initCode)
)))));
```

CREATE2 is unique to EVM - enables powerful deployment patterns!

## How CREATE2 Works

### Address Calculation Formula

```solidity
address predictedAddress = address(uint160(uint256(keccak256(abi.encodePacked(
    bytes1(0xff),
    address(this),      // Factory address
    salt,               // 32-byte salt
    keccak256(initCode) // Hash of creation bytecode
)))));
```

### Initcode vs Runtime Code

**Initcode (Creation Bytecode):**
- Code that runs during contract deployment
- Includes constructor logic and parameters
- Returns the runtime bytecode
- Never stored on-chain
- Used for address calculation in CREATE2

**Runtime Code:**
- The actual contract code stored on-chain
- What you write in your contract
- Executes when contract is called
- Result of initcode execution

**Getting Initcode:**
```solidity
// Without constructor arguments
bytes memory initCode = type(MyContract).creationCode;

// With constructor arguments
bytes memory initCode = abi.encodePacked(
    type(MyContract).creationCode,
    abi.encode(arg1, arg2, arg3)
);
```

### Salt Usage

The salt is a 32-byte value that allows deploying the same contract to different addresses:

```solidity
bytes32 salt1 = keccak256("version1");
bytes32 salt2 = keccak256("version2");

// Same contract, different salts = different addresses
address addr1 = deploy(salt1);
address addr2 = deploy(salt2);
```

**Salt Strategies:**
- User-specific: `keccak256(abi.encodePacked(userAddress))`
- Version-based: `keccak256("v1.0.0")`
- Sequential: `bytes32(uint256(counter++))`
- Random: `keccak256(abi.encodePacked(block.timestamp, msg.sender))`

## Deploying with CREATE2

### Basic Syntax

```solidity
contract Factory {
    function deploy(bytes32 salt) public returns (address) {
        MyContract instance = new MyContract{salt: salt}();
        return address(instance);
    }
}
```

### With Assembly

```solidity
function deploy(bytes32 salt, bytes memory bytecode) public returns (address addr) {
    assembly {
        addr := create2(
            0,                              // value (ETH to send)
            add(bytecode, 0x20),           // bytecode start
            mload(bytecode),               // bytecode length
            salt                            // salt
        )

        if iszero(extcodesize(addr)) {
            revert(0, 0)
        }
    }
}
```

### Assembly Breakdown

- `create2(value, offset, size, salt)` - CREATE2 opcode
- `add(bytecode, 0x20)` - Skip first 32 bytes (length prefix)
- `mload(bytecode)` - Read length from first 32 bytes
- `extcodesize(addr)` - Check deployment succeeded (size > 0)

## Address Prediction Off-Chain

You can predict addresses before deployment using the same formula:

### TypeScript Example

```typescript
import { ethers } from 'ethers';

function predictAddress(factoryAddress: string, salt: string, initCodeHash: string): string {
    return ethers.getCreate2Address(
        factoryAddress,
        salt,
        initCodeHash
    );
}

// Usage
const factory: string = "0x1234...";
const salt: string = ethers.id("my-salt");
const initCode: string = MyContract.bytecode;
const initCodeHash: string = ethers.keccak256(initCode);

const predicted: string = predictAddress(factory, salt, initCodeHash);
```

### Solidity Example

```solidity
function predictAddress(bytes32 salt, bytes memory bytecode)
    public
    view
    returns (address)
{
    bytes32 hash = keccak256(
        abi.encodePacked(
            bytes1(0xff),
            address(this),
            salt,
            keccak256(bytecode)
        )
    );
    return address(uint160(uint256(hash)));
}
```

## Use Cases

### 1. Counterfactual Contracts

Deploy contracts only when needed, but use the address beforehand:

```solidity
// Predict address
address wallet = predictWalletAddress(owner);

// Send funds to predicted address
(bool sent, ) = wallet.call{value: 1 ether}("");

// Deploy later when needed
if (address(wallet).code.length == 0) {
    deployWallet(owner);
}
```

### 2. State Channels

- Predict contract addresses for state channel disputes
- Deploy only if dispute occurs
- Saves gas in optimistic case

### 3. Minimal Proxies

- Deploy minimal proxy clones to deterministic addresses
- EIP-1167 compatible
- Gas-efficient contract replication

### 4. Account Abstraction

- Smart contract wallets (EIP-4337)
- Predict wallet address before deployment
- Users can receive funds before wallet creation

### 5. Cross-Chain Deployment

- Deploy same contract to same address on different chains
- Requires same deployer address and salt
- Useful for multi-chain protocols

### 6. Upgradeable Patterns

- Deploy new implementations to predictable addresses
- Coordinate upgrades across multiple proxies
- Version management

## Important Considerations

### 1. Deployment Fails if Address Occupied

```solidity
// Will revert if already deployed
new MyContract{salt: salt}();

// Check before deploying
if (predictedAddress.code.length == 0) {
    new MyContract{salt: salt}();
}
```

### 2. Constructor Arguments Affect Address

```solidity
// Different initcode = different address
bytes memory initCode1 = abi.encodePacked(
    type(MyContract).creationCode,
    abi.encode(arg1)
);

bytes memory initCode2 = abi.encodePacked(
    type(MyContract).creationCode,
    abi.encode(arg2)
);

// initCode1 != initCode2, so addresses will differ
```

### 3. Self-Destruct and Redeployment

Before Cancun upgrade:
- Could `selfdestruct` and redeploy to same address
- Enabled malicious patterns

After Cancun (EIP-6780):
- `selfdestruct` only works in same transaction as creation
- Cannot redeploy to same address after deployment
- More secure

### 4. Factory Address Matters

```solidity
// Different factory = different address (same salt, same bytecode)
Factory1.deploy(salt) != Factory2.deploy(salt)
```

## Security Considerations

### 1. Salt Manipulation

```solidity
// Bad: Predictable salt
bytes32 salt = keccak256(abi.encodePacked(block.timestamp));

// Better: Include sender
bytes32 salt = keccak256(abi.encodePacked(msg.sender, userNonce));
```

### 2. Frontrunning

Attackers can frontrun deployment with same salt:
- Monitor mempool for CREATE2 deployments
- Deploy with higher gas price
- Original transaction reverts

**Mitigation:**
```solidity
mapping(address => bool) public canDeploy;

function deploy(bytes32 salt) public {
    require(canDeploy[msg.sender], "Not authorized");
    // Deploy...
}
```

### 3. Initcode Verification

Always verify the bytecode matches expectations:
```solidity
function deploy(bytes32 salt, bytes memory bytecode) public {
    bytes32 expectedHash = keccak256(type(MyContract).creationCode);
    bytes32 actualHash = keccak256(bytecode);
    require(expectedHash == actualHash, "Invalid bytecode");

    // Deploy...
}
```

## Testing Strategies

1. **Address Prediction:**
   - Predict address off-chain
   - Deploy contract
   - Verify addresses match

2. **Salt Uniqueness:**
   - Deploy with salt A
   - Attempt redeploy with same salt (should revert)
   - Deploy with salt B (should succeed)

3. **Constructor Arguments:**
   - Test with different constructor args
   - Verify addresses differ
   - Ensure proper initialization

4. **Cross-Factory:**
   - Deploy from different factories
   - Verify addresses differ
   - Test isolation

## Project Structure

```
16-contract-factories/
├── src/
│   ├── Project16.sol              # Skeleton implementation
│   └── solution/
│       └── Project16Solution.sol  # Complete solution
├── test/
│   └── Project16.t.sol            # Comprehensive tests
├── script/
│   └── DeployProject16.s.sol      # Deployment script
└── README.md                       # This file
```

## Tasks

### Part 1: Basic Factory

1. Implement `ContractFactory` with CREATE2
2. Add address prediction function
3. Track deployed contracts
4. Prevent duplicate deployments

### Part 2: Advanced Features

5. Deploy with constructor arguments
6. Implement salt generation strategies
7. Add deployment events
8. Create helper functions

### Part 3: Testing

9. Write prediction tests
10. Test duplicate prevention
11. Verify address calculation
12. Test edge cases

## Getting Started

```bash
# Run tests
forge test --match-path test/ContractFactory.t.sol -vvv

# Check skeleton
forge build

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/ContractFactorySolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployContractFactorySolution.s.sol` - Deployment script patterns
- `test/solution/ContractFactorySolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains deterministic hashing, address prediction, counterfactual deployments
- **Connections to Project 01**: keccak256 for address calculation (like mapping storage slots)
- **Connections to Project 14**: ABI encoding for bytecode construction
- **Connections to Project 17**: Used with minimal proxies for gas-efficient cloning
- **Real-World Context**: Enables counterfactual deployments, upgrade patterns, address-based logic

# See solution
cat src/solution/ContractFactorySolution.sol

# Deploy
forge script script/DeployContractFactory.s.sol --rpc-url $RPC_URL --broadcast
```

## Additional Resources

- [EIP-1014: CREATE2](https://eips.ethereum.org/EIPS/eip-1014)
- [EIP-6780: SELFDESTRUCT Changes](https://eips.ethereum.org/EIPS/eip-6780)
- [OpenZeppelin CREATE2](https://docs.openzeppelin.com/cli/2.8/deploying-with-create2)
- [Solidity Documentation: CREATE2](https://docs.soliditylang.org/en/latest/control-structures.html#salted-contract-creations-create2)

## Common Pitfalls

1. Forgetting to include constructor args in initcode
2. Using wrong factory address in prediction
3. Not checking if address already deployed
4. Assuming bytecode is constant across Solidity versions
5. Not accounting for compiler settings affecting bytecode

## Advanced Topics

- Minimal proxy factories with CREATE2
- Diamond pattern deployment
- CREATE3 (CREATE2 + proxy wrapper)
- Deterministic cross-chain deployments
- Metamorphic contracts (pre-Cancun)

## Conclusion

CREATE2 is a powerful tool for deterministic deployments. Understanding address calculation, initcode, and salt usage unlocks advanced patterns like counterfactual contracts and state channels.

Master these concepts to build more sophisticated smart contract systems!

---


## 17-minimal-proxy

# Project 17: Minimal Proxy (EIP-1167)

Learn how to use the minimal proxy pattern to deploy multiple contract instances at a fraction of the normal deployment cost.

## Learning Objectives

- Understand EIP-1167 minimal proxy standard
- Master the clone factory pattern
- Learn initialization patterns for proxies
- Compare gas costs: clone vs new deployment
- Understand when to use clones vs regular deployments
- Work with OpenZeppelin's Clones library

## What is EIP-1167?

EIP-1167 defines a minimal bytecode implementation that delegates all calls to a known, fixed address. This standard allows for the creation of extremely cheap proxy contracts (clones) that forward all calls to an implementation contract.

### Key Concepts

#### 1. Minimal Proxy Bytecode

The minimal proxy is only **45 bytes** of bytecode that:
- Delegates all calls to an implementation address
- Forwards all `msg.data` to the implementation
- Returns the result back to the caller
- Preserves `msg.sender` and `msg.value`

```
363d3d373d3d3d363d73bebebebebebebebebebebebebebebebebebebebe5af43d82803e903d91602b57fd5bf3
```

Where `bebebebe...` is the implementation address.

#### 2. How It Works

```
┌─────────────┐         ┌──────────────┐         ┌────────────────┐
│   Caller    │────────>│  Clone Proxy │────────>│ Implementation │
└─────────────┘         └──────────────┘         └────────────────┘
                              (45 bytes)             (Full Contract)
```

**Call Flow:**
1. User calls clone at address A
2. Clone's minimal bytecode delegates to implementation at address B
3. Implementation executes in the context of clone (using clone's storage)
4. Result is returned to user

#### 3. Important Properties

- **Storage**: Each clone has its own storage (isolated from implementation and other clones)
- **Address**: Each clone has a unique address
- **Bytecode**: All clones share the same minimal bytecode (only implementation address differs)
- **Execution Context**: Functions execute with the clone's `address(this)` and storage

## Clone vs New Deployment

### Gas Cost Comparison

| Operation | New Deployment | Clone | Savings |
|-----------|---------------|-------|---------|
| Simple Contract | ~200,000 gas | ~40,000 gas | **80%** |
| Medium Contract | ~500,000 gas | ~40,000 gas | **92%** |
| Complex Contract | ~2,000,000 gas | ~40,000 gas | **98%** |

**Why such savings?**
- New deployment: Must deploy full bytecode (runtime + constructor)
- Clone: Only deploys 45 bytes + minimal creation code

### When to Use Clones

**Good Use Cases:**
- NFT collections (each token as a separate contract)
- User wallets (one per user)
- Escrow contracts (one per transaction)
- Prediction markets (one per market)
- Any pattern requiring many identical contract instances

**Not Recommended:**
- Upgradeable proxies (use UUPS or Transparent instead)
- Single instance contracts
- When initialization is complex and gas is not critical

## Runtime vs Initcode

### Understanding the Separation

**Initcode (Constructor Code):**
- Runs only once during deployment
- Returns the runtime bytecode
- Can accept constructor arguments
- Not stored on-chain

**Runtime Bytecode:**
- Stored on-chain permanently
- Executed on every call
- Contains all contract functions
- Must be as small as possible

### Clone Pattern Impact

```solidity
// Traditional deployment
contract MyContract {
    address public owner;
    uint256 public value;

    // Constructor runs during deployment (initcode)
    constructor(address _owner, uint256 _value) {
        owner = _owner;
        value = _value;
    }
}

// Clone pattern - no constructor!
contract MyContractCloneable {
    address public owner;
    uint256 public value;
    bool private initialized;

    // Initialize function runs AFTER deployment
    function initialize(address _owner, uint256 _value) external {
        require(!initialized, "Already initialized");
        initialized = true;
        owner = _owner;
        value = _value;
    }
}
```

**Why no constructor for clones?**
- Clones copy runtime bytecode only
- Constructor is part of initcode (not copied)
- Must use initialization function instead

## Clone Factory Patterns

### Pattern 1: Basic Clone Factory

```solidity
import "@openzeppelin/contracts/proxy/Clones.sol";

contract BasicFactory {
    address public implementation;

    constructor(address _implementation) {
        implementation = _implementation;
    }

    function createClone() external returns (address) {
        return Clones.clone(implementation);
    }
}
```

### Pattern 2: Clone and Initialize

```solidity
contract CloneAndInitFactory {
    address public implementation;

    function createClone(bytes memory initData) external returns (address) {
        address clone = Clones.clone(implementation);
        (bool success,) = clone.call(initData);
        require(success, "Initialization failed");
        return clone;
    }
}
```

### Pattern 3: Deterministic Clones

```solidity
contract DeterministicFactory {
    address public implementation;

    function createClone(bytes32 salt) external returns (address) {
        return Clones.cloneDeterministic(implementation, salt);
    }

    function predictAddress(bytes32 salt) external view returns (address) {
        return Clones.predictDeterministicAddress(implementation, salt);
    }
}
```

## Initialization Patterns

### Anti-Pattern: Unprotected Initialize

```solidity
// DON'T DO THIS - Anyone can initialize!
contract Bad {
    address public owner;

    function initialize(address _owner) external {
        owner = _owner; // No protection!
    }
}
```

### Pattern 1: Single Initialize

```solidity
contract SingleInit {
    address public owner;
    bool private initialized;

    function initialize(address _owner) external {
        require(!initialized, "Already initialized");
        initialized = true;
        owner = _owner;
    }
}
```

### Pattern 2: OpenZeppelin Initializable

```solidity
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract OZInit is Initializable {
    address public owner;

    function initialize(address _owner) external initializer {
        owner = _owner;
    }
}
```

### Pattern 3: Factory-Only Initialize

```solidity
contract FactoryInit {
    address public immutable factory;
    address public owner;
    bool private initialized;

    constructor() {
        factory = msg.sender; // Set in implementation deployment
    }

    function initialize(address _owner) external {
        require(msg.sender == factory, "Only factory");
        require(!initialized, "Already initialized");
        initialized = true;
        owner = _owner;
    }
}
```

## OpenZeppelin Clones Library

### Available Functions

```solidity
library Clones {
    // Creates a non-deterministic clone
    function clone(address implementation) internal returns (address);

    // Creates a deterministic clone using CREATE2
    function cloneDeterministic(address implementation, bytes32 salt)
        internal returns (address);

    // Predicts the address of a deterministic clone
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address);

    // Predicts using msg.sender as deployer
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal view returns (address);
}
```

### Usage Example

```solidity
import "@openzeppelin/contracts/proxy/Clones.sol";

contract MyFactory {
    using Clones for address;

    address public implementation;
    address[] public allClones;

    function createClone() external returns (address) {
        // Simple clone
        address clone = implementation.clone();
        allClones.push(clone);
        return clone;
    }

    function createDeterministicClone(bytes32 salt) external returns (address) {
        // Deterministic clone (can predict address)
        address clone = implementation.cloneDeterministic(salt);
        allClones.push(clone);
        return clone;
    }

    function predictCloneAddress(bytes32 salt) external view returns (address) {
        return implementation.predictDeterministicAddress(salt);
    }
}
```

## Security Considerations

### 1. Initialize Protection

```solidity
// CRITICAL: Prevent re-initialization
bool private initialized;

function initialize(address _owner) external {
    require(!initialized, "Already initialized");
    initialized = true;
    owner = _owner;
}
```

### 2. Selfdestruct Warning

```solidity
// DANGER: If implementation selfdestructs, ALL clones break!
contract Implementation {
    function destroy() external {
        selfdestruct(payable(msg.sender)); // DON'T DO THIS!
    }
}
```

### 3. Delegatecall Awareness

Remember: Clones use `delegatecall`, so:
- `msg.sender` is preserved (the original caller)
- `address(this)` is the clone's address
- Storage is the clone's storage
- Implementation cannot have constructor state

## Gas Optimization Tips

### 1. Batch Clone Creation

```solidity
function createMultipleClones(uint256 count) external returns (address[] memory) {
    address[] memory newClones = new address[](count);
    for (uint256 i = 0; i < count; i++) {
        newClones[i] = Clones.clone(implementation);
    }
    return newClones;
}
```

### 2. Deterministic vs Regular Clones

- **Regular clone** (`clone`): Cheaper (~41,000 gas)
- **Deterministic clone** (`cloneDeterministic`): Slightly more expensive (~43,000 gas)
- Use deterministic only when you need predictable addresses

### 3. Initialize in Same Transaction

```solidity
function createAndInitialize(address owner) external returns (address) {
    address clone = Clones.clone(implementation);
    IMyContract(clone).initialize(owner);
    return clone;
}
```

## Common Patterns

### Pattern 1: NFT Collection Factory

```solidity
contract NFTCollectionFactory {
    address public nftImplementation;
    mapping(address => address[]) public creatorCollections;

    function createCollection(string memory name, string memory symbol)
        external returns (address) {
        address collection = Clones.clone(nftImplementation);
        INFTCollection(collection).initialize(msg.sender, name, symbol);
        creatorCollections[msg.sender].push(collection);
        return collection;
    }
}
```

### Pattern 2: Wallet Factory

```solidity
contract WalletFactory {
    address public walletImplementation;
    mapping(address => address) public userWallets;

    function createWallet() external returns (address) {
        require(userWallets[msg.sender] == address(0), "Wallet exists");

        bytes32 salt = bytes32(uint256(uint160(msg.sender)));
        address wallet = Clones.cloneDeterministic(walletImplementation, salt);

        IWallet(wallet).initialize(msg.sender);
        userWallets[msg.sender] = wallet;
        return wallet;
    }

    function predictWalletAddress(address user) external view returns (address) {
        bytes32 salt = bytes32(uint256(uint160(user)));
        return Clones.predictDeterministicAddress(walletImplementation, salt);
    }
}
```

### Pattern 3: Escrow Factory

```solidity
contract EscrowFactory {
    address public escrowImplementation;

    event EscrowCreated(address indexed escrow, address indexed buyer, address indexed seller);

    function createEscrow(address seller, address token, uint256 amount)
        external returns (address) {
        address escrow = Clones.clone(escrowImplementation);
        IEscrow(escrow).initialize(msg.sender, seller, token, amount);
        emit EscrowCreated(escrow, msg.sender, seller);
        return escrow;
    }
}
```

## Your Task

Implement a complete clone factory system:

1. **Implementation Contract**: Create a simple contract that can be cloned
2. **Factory Contract**: Create a factory that clones the implementation
3. **Initialization**: Implement safe initialization pattern
4. **Gas Comparison**: Compare gas costs between clone and new deployment
5. **Multiple Clones**: Deploy and test multiple independent clones

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/MinimalProxySolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployMinimalProxySolution.s.sol` - Deployment script patterns
- `test/solution/MinimalProxySolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains code reuse via delegatecall, template pattern, gas optimization
- **Connections to Project 10**: Uses delegatecall (like upgradeable proxies)
- **Connections to Project 15**: Low-level calls for cloning mechanism
- **Connections to Project 16**: CREATE2 for deterministic clone addresses
- **Real-World Context**: 88% gas savings vs full deployment - used in production for multi-instance contracts

## Testing Checklist

- [ ] Deploy implementation contract
- [ ] Create clone factory
- [ ] Deploy clone using factory
- [ ] Initialize clone successfully
- [ ] Verify clone independence (separate storage)
- [ ] Compare gas costs (clone vs new)
- [ ] Test multiple clones
- [ ] Verify initialization protection (prevent re-init)
- [ ] Test deterministic clones (optional)
- [ ] Verify address prediction (optional)

## Expected Gas Savings

For the implementation in this project:
- **New deployment**: ~350,000 - 400,000 gas
- **Clone deployment**: ~41,000 - 45,000 gas
- **Savings**: ~90% reduction!

## Resources

- [EIP-1167 Specification](https://eips.ethereum.org/EIPS/eip-1167)
- [OpenZeppelin Clones Library](https://docs.openzeppelin.com/contracts/4.x/api/proxy#Clones)
- [Minimal Proxy Deep Dive](https://blog.openzeppelin.com/deep-dive-into-the-minimal-proxy-contract/)

## Running the Project

```bash
# Install dependencies
forge install

# Run tests
forge test --match-path test/Project17.t.sol -vv

# See gas comparison
forge test --match-path test/Project17.t.sol --gas-report

# Deploy
forge script script/DeployProject17.s.sol:DeployProject17 --rpc-url <your_rpc_url> --broadcast
```

## Next Steps

After completing this project, explore:
- **UUPS Proxies** (upgradeable proxies)
- **Transparent Proxies** (admin-based upgrades)
- **Beacon Proxies** (multiple proxies, single upgradeable implementation)
- **Diamond Pattern** (multi-facet proxies)

---


## 18-oracles-chainlink

# Project 18: Oracles (Chainlink) 🔮

> **Master external data integration with Chainlink price feeds and oracle safety patterns**

## 🎯 Learning Objectives

- Understand why blockchains need oracles
- Integrate Chainlink AggregatorV3Interface
- Detect and handle stale price data
- Implement circuit breaker patterns
- Recognize price manipulation risks
- Learn TWAP (Time-Weighted Average Price) patterns
- Use multiple oracle sources for redundancy

## 📚 Background: The Oracle Problem

### What is an Oracle? The Bridge to External Data

**FIRST PRINCIPLES: Deterministic Isolation**

Blockchains are deterministic, isolated systems. They cannot:
- Access real-world data (stock prices, weather, sports scores)
- Make HTTP requests to external APIs
- Generate truly random numbers
- Know the current temperature in Tokyo

**CONNECTION TO PROJECT 11**:
ERC-4626 vaults need price data to calculate share values! Oracles provide this external data securely.

**WHY ORACLES ARE NEEDED**:

```
The Problem:
┌─────────────────────────────────────────┐
│ Blockchain (Deterministic)               │
│   ↓                                      │
│ Needs: ETH/USD price = $2,000           │ ← External data!
│   ↓                                      │
│ Cannot: Query CoinGecko API             │ ← No HTTP!
│   ↓                                      │
│ Solution: Oracle                         │ ← Bridge to external world
│   ↓                                      │
│ Oracle fetches price off-chain          │ ← External system
│   ↓                                      │
│ Oracle posts price on-chain             │ ← On-chain data
│   ↓                                      │
│ Contract reads price from oracle        │ ← Contract can use it!
└─────────────────────────────────────────┘
```

**ORACLES ARE BRIDGES** that bring external data onto the blockchain in a trustworthy way.

**THE ORACLE PROBLEM**:

**Centralization Risk**: A single oracle is a single point of failure.
```solidity
// ❌ BAD: Trusting a single source
uint256 price = oracle.getPrice(); // What if oracle is compromised?
```

**Solution**: Use decentralized oracle networks like Chainlink (multiple nodes, consensus).

**COMPARISON TO RUST** (Conceptual):

**Rust** (can make HTTP requests):
```rust
// Rust can directly access external APIs
let response = reqwest::get("https://api.coingecko.com/price").await?;
let price: f64 = response.json().await?;
```

**Solidity** (cannot make HTTP requests):
```solidity
// Solidity CANNOT access external APIs directly
// Must use oracle pattern
uint256 price = chainlinkOracle.getPrice();  // Oracle fetches off-chain
```

This is a fundamental difference - blockchains need oracles for external data!

### The Oracle Problem

**Centralization Risk**: A single oracle is a single point of failure.

```solidity
// BAD: Trusting a single source
uint256 price = oracle.getPrice(); // What if oracle is compromised?
```

**Solution**: Use decentralized oracle networks like Chainlink.

### Real-World Use Cases

| Use Case | Oracle Data Needed |
|----------|-------------------|
| **DeFi Lending** | ETH/USD price to calculate collateralization |
| **Stablecoins** | Asset prices for peg maintenance |
| **Prediction Markets** | Sports scores, election results |
| **Insurance** | Weather data for crop insurance |
| **NFT Dynamics** | External events to change NFT traits |
| **Derivatives** | Commodities prices (oil, gold) |

## 🔗 Chainlink Price Feeds

Chainlink is the most popular decentralized oracle network. It provides:
- **Price Feeds**: Crypto and traditional asset prices
- **Proof of Reserve**: Verify collateral backing
- **VRF (Verifiable Random Function)**: Provably random numbers
- **Any API**: Connect to any external data source

### AggregatorV3Interface

```solidity
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,        // The price
        uint256 startedAt,
        uint256 updatedAt,    // When price was updated
        uint80 answeredInRound
    );
}
```

### Example: ETH/USD Price Feed

```solidity
// Ethereum Mainnet ETH/USD: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
AggregatorV3Interface priceFeed = AggregatorV3Interface(feedAddress);

(
    uint80 roundId,
    int256 price,      // e.g., 200000000000 (8 decimals) = $2,000.00
    uint256 startedAt,
    uint256 updatedAt, // e.g., 1699876543 (Unix timestamp)
    uint80 answeredInRound
) = priceFeed.latestRoundData();

uint8 decimals = priceFeed.decimals(); // Usually 8 for USD pairs
```

## ⚠️ Oracle Safety Patterns

### 1. Stale Data Detection

**Problem**: Oracle hasn't updated recently, price may be outdated.

```solidity
// BAD: No staleness check
(, int256 price,,,) = priceFeed.latestRoundData();
require(price > 0, "Invalid price");

// GOOD: Check update time
(, int256 price,, uint256 updatedAt,) = priceFeed.latestRoundData();
require(updatedAt >= block.timestamp - STALENESS_THRESHOLD, "Stale price");
require(price > 0, "Invalid price");
```

**Recommendation**: Set threshold based on feed's heartbeat (usually 1-24 hours).

### 2. Price Validity Checks

**Problem**: Oracle might return invalid data (0, negative for some types).

```solidity
// Check for valid price range
require(price > 0, "Invalid price");
require(price < MAX_REASONABLE_PRICE, "Price too high");

// Check round completeness
require(answeredInRound >= roundId, "Stale round");
```

### 3. Circuit Breaker Pattern

**Problem**: Extreme price swings might indicate oracle manipulation or market chaos.

```solidity
// Store previous price
uint256 previousPrice = lastStoredPrice;
uint256 currentPrice = uint256(price);

// Check for extreme deviation
uint256 deviation = currentPrice > previousPrice
    ? (currentPrice - previousPrice) * 100 / previousPrice
    : (previousPrice - currentPrice) * 100 / previousPrice;

require(deviation <= MAX_PRICE_DEVIATION, "Circuit breaker triggered");
```

### 4. Multiple Oracle Sources

**Best Practice**: Use multiple oracles and compare/aggregate results.

```solidity
// Get price from two different sources
uint256 chainlinkPrice = getChainlinkPrice();
uint256 uniswapTWAP = getUniswapTWAP();

// Ensure they agree within tolerance
uint256 diff = chainlinkPrice > uniswapTWAP
    ? chainlinkPrice - uniswapTWAP
    : uniswapTWAP - chainlinkPrice;

require(diff * 100 / chainlinkPrice <= PRICE_TOLERANCE, "Oracle mismatch");
```

## 📊 TWAP (Time-Weighted Average Price)

TWAP smooths out price volatility and prevents manipulation.

### Why TWAP?

```solidity
// Spot price: Easily manipulated by flash loans
uint256 spotPrice = getCurrentPrice(); // Can be manipulated in 1 block!

// TWAP: Average over time window
uint256 twapPrice = getTWAP(30 minutes); // Harder to manipulate
```

### Uniswap V3 TWAP

```solidity
// Observe price at two time points
(int56 tickCumulative1,) = pool.observe(secondsAgo1);
(int56 tickCumulative2,) = pool.observe(secondsAgo2);

// Calculate time-weighted average
int56 tickDelta = tickCumulative1 - tickCumulative2;
int24 averageTick = int24(tickDelta / int56(uint56(period)));

// Convert tick to price
uint256 twapPrice = getTokenPriceFromTick(averageTick);
```

## 🚨 Price Manipulation Risks

### Flash Loan Attack

```solidity
// Attacker takes flash loan
// 1. Borrow 10,000 ETH
// 2. Swap all ETH for TOKEN on DEX (pumps TOKEN price)
// 3. Oracle reads manipulated price
// 4. Attacker exploits protocol using inflated price
// 5. Repay flash loan with profit
```

**Defense**: Use TWAP or Chainlink (which aggregates across multiple blocks).

### Frontrunning Oracle Updates

```solidity
// Attacker sees oracle update in mempool
// 1. Oracle will update price from $100 to $120
// 2. Attacker frontruns with transaction benefiting from $100
// 3. Oracle updates to $120
// 4. Attacker backs out transaction profiting from $120
```

**Defense**: Use commit-reveal schemes or limit impact of single transactions.

### Stale Price Exploitation

```solidity
// Price feed hasn't updated in 6 hours
// Real price: $2000, Oracle price: $1800
// Attacker uses stale $1800 price to get unfair liquidation/borrowing terms
```

**Defense**: Enforce staleness thresholds.

## 🔧 What You'll Build

A robust oracle integration system that:
- Integrates Chainlink ETH/USD price feed
- Detects stale data with configurable thresholds
- Implements circuit breaker for extreme price swings
- Validates price ranges and round data
- Demonstrates multi-oracle patterns
- Includes comprehensive safety checks

## 📝 Tasks

### Task 1: Implement the Skeleton Contract

Open `src/Project18.sol` and implement:

1. **Oracle integration** - Connect to Chainlink price feed
2. **Price retrieval** - Get latest price with all safety checks
3. **Staleness detection** - Reject outdated prices
4. **Price validation** - Verify price is within reasonable bounds
5. **Circuit breaker** - Pause on extreme price movements

### Task 2: Study the Solution

Compare with `src/solution/ChainlinkOracleSolution.sol`:

**Solution File Features**:
- **CS Concepts**: Explains external data validation, circuit breakers, staleness detection
- **Connections to Project 04**: Access control for oracle configuration
- **Connections to Project 05**: Error handling for oracle failures
- **Connections to Project 13**: Time-based staleness checks
- **Real-World Context**: Production-ready oracle integration used in all DeFi protocols
- Understand all safety checks
- See how circuit breaker works
- Learn proper error handling
- Study multi-oracle patterns
- Review detailed comments explaining oracle risks

### Task 3: Run Comprehensive Tests

```bash
cd 18-oracles-chainlink

# Run all tests
forge test -vvv

# Test specific scenarios
forge test --match-test test_GetPrice
forge test --match-test test_StalePrice
forge test --match-test test_CircuitBreaker

# Gas report
forge test --gas-report

# Coverage
forge coverage
```

### Task 4: Deploy and Test

```bash
# Start local node
anvil

# Deploy (in another terminal)
forge script script/DeployProject18.s.sol --broadcast --rpc-url http://localhost:8545

# Get current price
cast call <CONTRACT_ADDRESS> "getLatestPrice()(uint256)"

# Check last update time
cast call <CONTRACT_ADDRESS> "getLastUpdateTime()(uint256)"
```

### Task 5: Experiment with Mainnet Fork

```bash
# Fork Ethereum mainnet
anvil --fork-url https://eth-mainnet.g.alchemy.com/v2/INFURA_RPC_URL

# Deploy against real Chainlink feeds
forge script script/DeployProject18.s.sol --broadcast \
  --rpc-url http://localhost:8545

# See real ETH/USD price from Chainlink
cast call <CONTRACT_ADDRESS> "getLatestPrice()(uint256)"
```

## 🧪 Test Coverage

The test suite covers:

- ✅ Basic price retrieval
- ✅ Stale price detection and rejection
- ✅ Invalid price handling (zero, negative)
- ✅ Circuit breaker triggering on large swings
- ✅ Round data validation
- ✅ Edge cases (first price, exactly at threshold)
- ✅ Mock oracle for testing
- ✅ Decimal handling
- ✅ Access control
- ✅ Emergency pause functionality

## ⚠️ Security Considerations

### 1. Always Check Staleness

```solidity
// Never use price without checking update time
require(block.timestamp - updatedAt <= STALENESS_THRESHOLD);
```

### 2. Validate Price Range

```solidity
// Sanity check: ETH shouldn't be $0 or $1,000,000
require(price > MIN_PRICE && price < MAX_PRICE);
```

### 3. Check Round Completeness

```solidity
// Ensure the round actually completed
require(answeredInRound >= roundId);
```

### 4. Handle Oracle Failures Gracefully

```solidity
try priceFeed.latestRoundData() returns (...) {
    // Use price
} catch {
    // Fallback: pause system, use backup oracle, etc.
    revert("Oracle unavailable");
}
```

### 5. Circuit Breaker for Black Swan Events

```solidity
// If price changes >50% in one update, something is wrong
if (deviation > MAX_DEVIATION) {
    _pause(); // Stop all operations
    emit CircuitBreakerTriggered(price);
}
```

### 6. Use Multiple Oracles When Possible

```solidity
// Compare Chainlink and Uniswap TWAP
require(abs(chainlinkPrice - twapPrice) < TOLERANCE);
```

## 📊 Chainlink Feed Addresses

### Ethereum Mainnet

| Pair | Address |
|------|---------|
| ETH/USD | `0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419` |
| BTC/USD | `0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c` |
| USDC/USD | `0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6` |
| DAI/USD | `0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9` |

### Sepolia Testnet

| Pair | Address |
|------|---------|
| ETH/USD | `0x694AA1769357215DE4FAC081bf1f309aDC325306` |
| BTC/USD | `0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43` |

Find more at: [Chainlink Data Feeds](https://docs.chain.link/data-feeds/price-feeds/addresses)

## 🌍 Real-World Examples

### Aave Lending Protocol

```solidity
// Aave uses Chainlink for collateral pricing
IPriceOracle oracle = IPoolAddressesProvider(provider).getPriceOracle();
uint256 ethPrice = oracle.getAssetPrice(WETH);

// Calculate if user is eligible for loan
uint256 collateralValue = userCollateral * ethPrice / 1e18;
uint256 borrowLimit = collateralValue * LTV / 100;
require(borrowAmount <= borrowLimit);
```

### MakerDAO DAI Stability

```solidity
// MakerDAO uses multiple oracles (Chainlink + custom)
uint256 ethPrice = getMedianPrice(); // Median of many sources

// Determine if vault is undercollateralized
uint256 collateralValue = vaultETH * ethPrice;
uint256 debtValue = vaultDAI;
uint256 ratio = collateralValue * 100 / debtValue;

if (ratio < LIQUIDATION_RATIO) {
    liquidate(vault);
}
```

### Synthetix Synthetic Assets

```solidity
// Synthetix uses Chainlink for all synth prices
uint256 sETHPrice = getChainlinkPrice("sETH");
uint256 sBTCPrice = getChainlinkPrice("sBTC");

// Trade synthetic assets
exchange(sETH, sBTC, amount);
```

## ✅ Completion Checklist

- [ ] Integrated Chainlink AggregatorV3Interface
- [ ] Implemented stale price detection
- [ ] Added price validation checks
- [ ] Built circuit breaker pattern
- [ ] All tests pass
- [ ] Understand oracle manipulation risks
- [ ] Can explain TWAP vs spot price
- [ ] Deployed and tested with real price feeds
- [ ] Studied real-world oracle usage
- [ ] Know how to use multiple oracle sources

## 💡 Pro Tips

1. **Heartbeat varies by feed** - Check Chainlink docs for each feed's update frequency
2. **Decimals matter** - Always check `decimals()`, don't assume 18
3. **Gas optimization** - Cache oracle results if using multiple times in one transaction
4. **Emergency pause** - Always have a way to pause if oracle fails
5. **Monitor off-chain** - Set up alerts if oracle becomes stale
6. **Test with forks** - Use mainnet forks to test with real Chainlink feeds
7. **Fallback oracles** - Consider secondary oracle sources for critical operations
8. **Price impact limits** - Limit how much one transaction can move based on oracle price

## 🚀 Next Steps

After completing this project:

- **Chainlink VRF**: Learn verifiable randomness for NFTs and gaming
- **Chainlink Automation**: Trigger contract functions automatically
- **Custom oracles**: Build your own oracle for custom data
- **Multi-oracle aggregation**: Combine Chainlink, Band Protocol, API3
- **MEV protection**: Study how oracle timing affects MEV
- **Cross-chain oracles**: Use Chainlink CCIP for cross-chain data

## 📖 Further Reading

- [Chainlink Documentation](https://docs.chain.link/)
- [AggregatorV3Interface Reference](https://docs.chain.link/data-feeds/api-reference)
- [Oracle Security Best Practices](https://blog.chain.link/secure-data-oracle/)
- [TWAP Oracles Explained](https://docs.uniswap.org/concepts/protocol/oracle)
- [Oracle Manipulation Attacks](https://github.com/0xcacti/awesome-oracle-manipulation)
- [Euler Finance Oracle Attack Post-Mortem](https://www.euler.finance/)

## 🎓 Key Takeaways

1. **Never trust spot prices** - Use TWAP or decentralized oracles
2. **Always check staleness** - Old prices are dangerous
3. **Validate everything** - Don't assume oracle data is correct
4. **Circuit breakers save protocols** - Pause on anomalies
5. **Multiple sources** - Redundancy protects against oracle failures
6. **Understand attack vectors** - Flash loans, frontrunning, manipulation
7. **Test with real data** - Fork mainnet to test with actual Chainlink feeds

---

**Great work!** You now understand how to safely integrate external data into smart contracts using Chainlink oracles. This is critical knowledge for building production DeFi protocols.

**Keep learning! 🔮**

---


## 19-signed-messages

# Project 19: Signed Messages & EIP-712

Learn about cryptographic signatures, EIP-712 typed structured data, and how to build secure off-chain authorization systems in Solidity.

## Table of Contents
- [Overview](#overview)
- [Cryptographic Signatures Primer](#cryptographic-signatures-primer)
- [EIP-191: Signed Data Standard](#eip-191-signed-data-standard)
- [EIP-712: Typed Structured Data](#eip-712-typed-structured-data)
- [Domain Separators](#domain-separators)
- [Signature Verification](#signature-verification)
- [Replay Protection](#replay-protection)
- [Implementation Guide](#implementation-guide)
- [Security Considerations](#security-considerations)
- [Real-World Applications](#real-world-applications)

## Overview

This project teaches you how to implement **EIP-712** (Typed Structured Data Hashing and Signing), a standard for creating human-readable, type-safe signatures that can be verified on-chain.

### What You'll Learn
- How ECDSA signatures work in Ethereum
- Difference between EIP-191 and EIP-712
- How to construct domain separators
- Typed structured data hashing
- On-chain signature verification
- Replay attack prevention with nonces
- Cross-chain replay protection with chainId
- Permit-style meta-transactions

### Use Cases
- **Gasless transactions** (meta-transactions)
- **ERC20 Permit** (approve via signature)
- **NFT lazy minting** (claim with signature)
- **DAO voting** (off-chain signatures)
- **Vouchers and coupons** (one-time use signatures)

## Cryptographic Signatures Primer: ECDSA in Ethereum

**FIRST PRINCIPLES: Asymmetric Cryptography**

Ethereum uses ECDSA (Elliptic Curve Digital Signature Algorithm) over the secp256k1 curve for signatures. Understanding how signatures work is essential for meta-transactions and permit patterns!

**CONNECTION TO PROJECT 08**:
ERC20 Permit (EIP-2612) uses signatures to approve tokens without a transaction! This project teaches the fundamentals behind permit.

### ECDSA (Elliptic Curve Digital Signature Algorithm)

Ethereum uses ECDSA over the secp256k1 curve. Here's how it works:

```
ECDSA Signature Flow:
┌─────────────────────────────────────────┐
│ Private Key (secret, 256 bits)          │ ← Only signer knows
│   ↓                                      │
│ Public Key (derived, 512 bits)          │ ← Can be shared
│   ↓                                      │
│ Ethereum Address (keccak256(public)[12:])│ ← 20 bytes
│   ↓                                      │
│ Sign Message                            │ ← Off-chain operation
│   ↓                                      │
│ Signature (v, r, s) - 65 bytes         │ ← Can be verified
│   ↓                                      │
│ Verify: Message + Signature → Address   │ ← On-chain verification
└─────────────────────────────────────────┘
```

**UNDERSTANDING THE MATHEMATICS** (DSA Concept):

ECDSA uses elliptic curve cryptography:
- **Private Key**: Random 256-bit number (secret)
- **Public Key**: Point on elliptic curve (derived from private key)
- **Signature**: Mathematical proof that private key holder signed message
- **Verification**: Mathematical operation that recovers public key from signature

**COMPARISON TO RUST** (DSA Concept):

**Rust** (using secp256k1 crate):
```rust
use secp256k1::{SecretKey, PublicKey, Message, Signature};

let secret = SecretKey::from_slice(&private_key_bytes)?;
let public = PublicKey::from_secret_key(&secret);
let message = Message::from_slice(&message_hash)?;
let signature = secret.sign_ecdsa(&message);
// Same ECDSA algorithm, different language
```

**Solidity** (using ecrecover):
```solidity
address signer = ecrecover(messageHash, v, r, s);
// Built-in EVM function for signature recovery
```

Both use the same ECDSA algorithm - Solidity just provides built-in recovery!

### Signature Components

An Ethereum signature consists of three parts:
- **v** (1 byte): Recovery identifier (27 or 28, sometimes 0 or 1)
  - Indicates which of two possible public keys to use
  - 27 = uncompressed, 28 = compressed (legacy)
  - 0/1 = EIP-155 compatible (chainId encoded)
  
- **r** (32 bytes): First part of the signature
  - X coordinate on elliptic curve (mod n)
  
- **s** (32 bytes): Second part of the signature
  - Signature proof value

**Total: 65 bytes** (1 + 32 + 32)

**UNDERSTANDING RECOVERY**:

```
Signature Recovery:
┌─────────────────────────────────────────┐
│ Input: messageHash, v, r, s            │
│   ↓                                      │
│ ecrecover(messageHash, v, r, s)        │ ← EVM opcode
│   ↓                                      │
│ Mathematical operation                  │ ← Elliptic curve math
│   ↓                                      │
│ Output: address (public key)           │ ← Signer's address
└─────────────────────────────────────────┘
```

**GAS COST**:
- `ecrecover()`: ~3,000 gas (expensive cryptographic operation!)
- Signature verification is one of the most expensive operations in Solidity

### Signing Process

```solidity
// Off-chain (TypeScript):
const messageHash = ethers.utils.keccak256(message);
const signature = await signer.signMessage(messageHash);
// signature = 0x... (130 hex chars = 65 bytes)

// Split signature:
const { v, r, s } = ethers.utils.splitSignature(signature);
```

### Verification Process

```solidity
// On-chain (Solidity):
address signer = ecrecover(messageHash, v, r, s);
require(signer == expectedSigner, "Invalid signature");
```

## EIP-191: Signed Data Standard

**EIP-191** defines a standard for signed data to prevent confusion between different types of data:

```
0x19 <1 byte version> <version specific data> <data to sign>
```

### Version 0x00: Data with intended validator
```
0x19 0x00 <20 bytes validator address> <data>
```

### Version 0x01: Structured data (EIP-712)
```
0x19 0x01 <32 bytes domainSeparator> <32 bytes structHash>
```

### Version 0x45: Personal message
```
0x19 "Ethereum Signed Message:\n" <length> <message>
```

This is what `eth_sign` and `personal_sign` use automatically.

## EIP-712: Typed Structured Data

**EIP-712** provides a standard for hashing and signing typed structured data, making signatures:
- **Human-readable**: Users can see what they're signing
- **Type-safe**: Structured data with types
- **Domain-specific**: Bound to specific contracts/chains
- **Replay-protected**: Nonces and deadlines

### EIP-712 Structure

```
Final Hash = keccak256(0x19 0x01 <domainSeparator> <structHash>)
```

Where:
- `domainSeparator`: Uniquely identifies the signing domain
- `structHash`: Hash of the typed structured data

### Type Hash

Each struct type has a type hash:

```solidity
// For a struct like:
struct Permit {
    address owner;
    address spender;
    uint256 value;
    uint256 nonce;
    uint256 deadline;
}

// The type hash is:
bytes32 constant PERMIT_TYPEHASH = keccak256(
    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
);
```

### Struct Hash

The struct hash combines the type hash with the data:

```solidity
bytes32 structHash = keccak256(
    abi.encode(
        PERMIT_TYPEHASH,
        owner,
        spender,
        value,
        nonce,
        deadline
    )
);
```

## Domain Separators

The **domain separator** ensures signatures are only valid for:
- A specific contract
- A specific blockchain (chainId)
- A specific version

### Domain Type

```solidity
bytes32 constant TYPE_HASH = keccak256(
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
);
```

### Computing Domain Separator

```solidity
bytes32 domainSeparator = keccak256(
    abi.encode(
        TYPE_HASH,
        keccak256(bytes(name)),        // Contract name
        keccak256(bytes(version)),     // Version (e.g., "1")
        block.chainid,                 // Chain ID (1 for mainnet)
        address(this)                  // This contract's address
    )
);
```

### Why Domain Separators Matter

Without domain separators:
- ✗ Signature from Contract A could work on Contract B
- ✗ Signature from Ethereum could work on Polygon
- ✗ No version control for upgrades

With domain separators:
- ✓ Signatures are contract-specific
- ✓ Signatures are chain-specific
- ✓ Signatures are version-specific

## Signature Verification

### Step 1: Recreate the Hash

```solidity
bytes32 structHash = keccak256(abi.encode(
    PERMIT_TYPEHASH,
    owner,
    spender,
    value,
    nonce,
    deadline
));

bytes32 digest = keccak256(abi.encodePacked(
    "\x19\x01",
    domainSeparator,
    structHash
));
```

### Step 2: Recover Signer

```solidity
address signer = ecrecover(digest, v, r, s);
```

### Step 3: Verify Signer

```solidity
require(signer != address(0), "Invalid signature");
require(signer == expectedSigner, "Unauthorized");
```

### ECDSA Library (OpenZeppelin)

For production, use OpenZeppelin's ECDSA library:

```solidity
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

address signer = ECDSA.recover(digest, signature);
```

This handles:
- Malleability protection
- Invalid signature checks
- Cleaner API

## Replay Protection

Signatures can be **replayed** (reused) unless you implement protections.

### Attack Scenario

```solidity
// Alice signs: "Transfer 100 tokens to Bob"
// ✓ Transaction 1: Bob submits signature -> Works
// ✗ Transaction 2: Bob submits SAME signature -> Works again!
```

### Solution 1: Nonces

Track a counter for each user:

```solidity
mapping(address => uint256) public nonces;

function verify(..., uint256 nonce, ...) {
    require(nonce == nonces[signer], "Invalid nonce");
    nonces[signer]++; // Increment after use
}
```

Now each signature can only be used once, in order.

### Solution 2: Deadlines

Add expiration time:

```solidity
function verify(..., uint256 deadline, ...) {
    require(block.timestamp <= deadline, "Signature expired");
}
```

### Solution 3: Used Signature Tracking

For one-time vouchers:

```solidity
mapping(bytes32 => bool) public usedSignatures;

function verify(bytes32 digest, ...) {
    require(!usedSignatures[digest], "Signature already used");
    usedSignatures[digest] = true;
}
```

### Chain ID Protection

Prevent cross-chain replays:

```solidity
// Domain separator includes block.chainid
// Signature valid on mainnet won't work on testnet
```

## Implementation Guide

### 1. Define Your Struct

```solidity
struct MetaTx {
    address from;
    address to;
    uint256 value;
    uint256 nonce;
    uint256 deadline;
}
```

### 2. Create Type Hash

```solidity
bytes32 public constant METATX_TYPEHASH = keccak256(
    "MetaTx(address from,address to,uint256 value,uint256 nonce,uint256 deadline)"
);
```

### 3. Implement Domain Separator

```solidity
bytes32 public immutable DOMAIN_SEPARATOR;

constructor() {
    DOMAIN_SEPARATOR = keccak256(
        abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes("MyContract")),
            keccak256(bytes("1")),
            block.chainid,
            address(this)
        )
    );
}
```

### 4. Create Verification Function

```solidity
function verify(
    MetaTx calldata metaTx,
    uint8 v,
    bytes32 r,
    bytes32 s
) public view returns (bool) {
    // 1. Check deadline
    require(block.timestamp <= metaTx.deadline, "Expired");

    // 2. Check nonce
    require(metaTx.nonce == nonces[metaTx.from], "Invalid nonce");

    // 3. Create struct hash
    bytes32 structHash = keccak256(
        abi.encode(
            METATX_TYPEHASH,
            metaTx.from,
            metaTx.to,
            metaTx.value,
            metaTx.nonce,
            metaTx.deadline
        )
    );

    // 4. Create digest
    bytes32 digest = keccak256(
        abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
    );

    // 5. Recover signer
    address signer = ecrecover(digest, v, r, s);

    // 6. Verify
    return signer == metaTx.from;
}
```

### 5. Execute Function

```solidity
function executeMetaTx(
    MetaTx calldata metaTx,
    uint8 v,
    bytes32 r,
    bytes32 s
) external {
    require(verify(metaTx, v, r, s), "Invalid signature");

    // Increment nonce BEFORE execution (reentrancy protection)
    nonces[metaTx.from]++;

    // Execute the transaction
    // ... your logic here ...
}
```

## Security Considerations

### 1. Signature Malleability

ECDSA signatures are malleable. For a valid signature `(v, r, s)`, there exists another valid signature `(v', r, s')` for the same message.

**Solution**: Use OpenZeppelin's ECDSA library or check:
```solidity
require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "Invalid s");
```

### 2. ecrecover Returns Zero Address

If signature is invalid, `ecrecover` returns `address(0)`.

**Solution**: Always check:
```solidity
require(signer != address(0), "Invalid signature");
```

### 3. Nonce Management

Wrong nonce handling can brick accounts or allow replays.

**Solution**:
- Increment nonce BEFORE external calls
- Allow nonce queries
- Consider partial ordering (DAI-style)

### 4. Deadline Validation

Missing deadline checks allow signatures to live forever.

**Solution**: Always check:
```solidity
require(block.timestamp <= deadline, "Expired");
```

### 5. Domain Separator Caching

If your contract can be deployed on multiple chains, don't cache the domain separator if using `CREATE2` deterministic deployment.

**Solution**: Compute domain separator dynamically or validate chainId.

### 6. Front-Running

Meta-transactions can be front-run.

**Solution**:
- Use nonces (ensures ordering)
- Add relayer-specific data
- Use flashbots or private mempools

### 7. Phishing

Users might sign malicious data.

**Solution**:
- Use EIP-712 (human-readable)
- Clear UI warnings
- Wallet integration

## Real-World Applications

### ERC20 Permit (EIP-2612)

Allow approvals via signature instead of transaction:

```solidity
function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
) external {
    // Verify signature
    // ...

    // Set allowance
    _approve(owner, spender, value);
}
```

Benefits:
- ✓ No approval transaction needed
- ✓ Save gas for users
- ✓ Better UX

### Meta-Transactions

Execute transactions on behalf of users:

```solidity
function executeMetaTx(
    address from,
    bytes calldata data,
    uint256 nonce,
    bytes calldata signature
) external {
    // Verify signature
    // Execute call from user's context
    // Relayer pays gas
}
```

### NFT Lazy Minting

Mint NFTs only when claimed:

```solidity
function claim(
    uint256 tokenId,
    address to,
    bytes calldata signature
) external {
    // Verify admin signature
    // Mint NFT to claimer
}
```

### DAO Voting

Vote off-chain, execute on-chain:

```solidity
function castVoteBySig(
    uint256 proposalId,
    uint8 support,
    uint8 v,
    bytes32 r,
    bytes32 s
) external {
    // Verify signature
    // Record vote
}
```

## Testing Your Implementation

```bash
# Run tests
forge test --match-path test/Project19.t.sol -vvv

# Run specific test
forge test --match-test testPermitSignature -vvv

# Check gas costs
forge test --match-path test/Project19.t.sol --gas-report
```

## Tasks

### Part 1: Understanding (src/Project19.sol)
1. Implement `DOMAIN_SEPARATOR` computation
2. Create `_hashPermit()` function for struct hashing
3. Implement `_verify()` for signature verification
4. Add nonce tracking
5. Implement deadline checks

### Part 2: Advanced Features
1. Add support for EIP-2612 permit
2. Implement meta-transaction execution
3. Create voucher system with one-time signatures
4. Add batch signature verification

### Part 3: Security
1. Prevent signature malleability
2. Handle nonce edge cases
3. Protect against replay attacks
4. Test cross-chain scenarios

## Additional Resources

### EIPs
- [EIP-191: Signed Data Standard](https://eips.ethereum.org/EIPS/eip-191)
- [EIP-712: Typed Structured Data](https://eips.ethereum.org/EIPS/eip-712)
- [EIP-2612: Permit Extension for ERC-20](https://eips.ethereum.org/EIPS/eip-2612)

### Libraries
- [OpenZeppelin ECDSA](https://docs.openzeppelin.com/contracts/4.x/api/utils#ECDSA)
- [OpenZeppelin EIP712](https://docs.openzeppelin.com/contracts/4.x/api/utils#EIP712)

### Tools
- [eth-sig-util](https://github.com/MetaMask/eth-sig-util) - Sign and verify
- [eip712-codegen](https://github.com/danfinlay/eip-712-codegen) - Generate TypeScript types

## License

MIT

---


## 20-deposit-withdraw

# Project 20: Deposit/Withdraw Accounting

> **Learn share-based accounting for deposits and withdrawals with slippage protection**

## Learning Objectives

- Understand share-based vs direct accounting
- Implement deposit/withdraw with share calculations
- Create preview functions for transaction simulation
- Add slippage protection against front-running
- Prepare for ERC-4626 Tokenized Vault Standard
- Handle rounding to protect the protocol

## Background: Why Share-Based Accounting?

### The Problem with Direct Accounting

Imagine a simple vault where users deposit tokens:

```solidity
// BAD: Direct accounting doesn't handle yield
mapping(address => uint256) public deposits;

function deposit(uint256 amount) external {
    deposits[msg.sender] += amount;  // Alice deposits 100 tokens
    token.transferFrom(msg.sender, address(this), amount);
}
```

**What happens when the vault earns yield?**

- Vault starts with 100 tokens
- Vault earns 10 tokens from external strategy
- Vault now has 110 tokens
- But Alice's deposit still shows 100!
- How do we distribute the 10 token profit?

### The Solution: Share-Based Accounting

**FIRST PRINCIPLES: Proportional Ownership Through Shares**

Instead of tracking exact deposits, we mint **shares** representing proportional ownership. This automatically handles yield distribution!

**CONNECTION TO PROJECT 01 & 06**:
- Uses mappings (Project 01) for O(1) lookups
- Uses arithmetic operations (Project 06) for share calculations
- Gas-efficient pattern for yield distribution!

```solidity
// ✅ GOOD: Share-based accounting handles yield automatically
mapping(address => uint256) public shares;  // From Project 01!
uint256 public totalShares;                 // Total shares minted
uint256 public totalAssets;                 // Tracks actual tokens in vault

function deposit(uint256 assets) external returns (uint256 shares) {
    shares = convertToShares(assets);  // Calculate proportional shares
    totalShares += shares;              // Update total shares
    totalAssets += assets;              // Update total assets
    shares[msg.sender] += shares;       // Credit user's shares
}

function convertToShares(uint256 assets) public view returns (uint256) {
    return totalShares == 0
        ? assets                        // First deposit: 1:1 ratio
        : (assets * totalShares) / totalAssets;  // Proportional shares
}
```

**HOW IT HANDLES YIELD AUTOMATICALLY**:

```
Share-Based Accounting Flow:
┌─────────────────────────────────────────┐
│ Step 1: Alice deposits 100 tokens       │
│   shares = (100 * 0) / 0 = 100         │ ← First deposit: 1:1
│   totalShares = 100                     │
│   totalAssets = 100                     │
│   shares[alice] = 100                   │
│   ↓                                      │
│ Step 2: Vault earns 10 tokens yield    │
│   totalAssets = 110 (increased!)        │ ← Yield increases assets
│   totalShares = 100 (unchanged!)        │ ← Shares stay same
│   Exchange rate: 110/100 = 1.1          │ ← Each share worth more!
│   ↓                                      │
│ Step 3: Bob deposits 110 tokens         │
│   shares = (110 * 100) / 110 = 100     │ ← Gets same shares as Alice
│   totalShares = 200                     │
│   totalAssets = 220                     │
│   shares[bob] = 100                     │
│   ↓                                      │
│ Step 4: Alice withdraws 100 shares     │
│   assets = (100 * 220) / 200 = 110    │ ← Gets 110 tokens!
│   Alice's profit: 10 tokens ✅          │ ← Automatic yield distribution!
└─────────────────────────────────────────┘
```

**WHY THIS WORKS**:

1. **Automatic Yield Distribution**: When assets increase, exchange rate increases
2. **Fair Distribution**: Each share gets proportional profit
3. **Gas Efficient**: No need to update individual user balances
4. **Simple Math**: Just track totals, calculate on-demand

**GAS COST BREAKDOWN** (from Project 01 & 06 knowledge):

**Deposit**:
- Share calculation: ~100 gas (MUL + DIV)
- 2 SSTOREs (totalShares, totalAssets): ~10,000 gas (warm)
- 1 SSTORE (user shares): ~5,000 gas (warm)
- ERC20 transfer: ~50,000 gas
- Total: ~65,100 gas

**Withdraw**:
- Share calculation: ~100 gas
- 2 SSTOREs: ~10,000 gas
- 1 SSTORE (user shares to zero): ~5,000 gas (may refund!)
- ERC20 transfer: ~50,000 gas
- Total: ~65,100 gas

**REAL-WORLD ANALOGY**: 
Like buying shares of a mutual fund:
- **Deposit** = Buying fund shares
- **Yield** = Fund performance increases NAV (Net Asset Value)
- **Withdraw** = Selling shares at current NAV
- **Profit** = Difference between buy and sell NAV

## Core Concepts

### 1. Shares vs Assets

| Concept | Definition | Example |
|---------|------------|---------|
| **Assets** | The underlying token (USDC, DAI, etc.) | 1000 USDC |
| **Shares** | Vault tokens representing ownership | 950 vault shares |
| **Exchange Rate** | Assets per share | 1.053 USDC per share |

### 2. Share Calculation Math

The fundamental formulas:

```solidity
// DEPOSIT: Converting assets → shares
shares = (assets * totalShares) / totalAssets

// WITHDRAW: Converting shares → assets
assets = (shares * totalAssets) / totalShares

// FIRST DEPOSIT: When totalShares == 0
shares = assets  // 1:1 ratio for bootstrap
```

**Example Timeline:**

| Event | Total Assets | Total Shares | Exchange Rate |
|-------|--------------|--------------|---------------|
| Initial | 0 | 0 | N/A |
| Alice deposits 1000 | 1000 | 1000 | 1.0 |
| Vault earns 100 | 1100 | 1000 | 1.1 |
| Bob deposits 1100 | 2200 | 2000 | 1.1 |
| Carol deposits 550 | 2750 | 2500 | 1.1 |

### 3. Preview Functions

Preview functions let users **simulate** transactions before executing:

```solidity
function previewDeposit(uint256 assets) public view returns (uint256 shares) {
    // Shows how many shares you'll get for depositing assets
    return convertToShares(assets);
}

function previewWithdraw(uint256 assets) public view returns (uint256 shares) {
    // Shows how many shares you'll burn to withdraw assets
    return convertToSharesRoundUp(assets);  // Round up to protect vault
}
```

**Why preview functions matter:**

- **Transparency**: Users know exactly what they'll get
- **Slippage calculation**: Users can set minimum acceptable amounts
- **Front-end integration**: UIs can show accurate estimates
- **Slippage protection**: Users can revert if conditions change

### 4. Slippage Protection

Slippage occurs when the exchange rate changes between simulation and execution.

**The Attack:**

```solidity
// 1. Alice previews: deposit 1000 assets → expect 100 shares
uint256 expectedShares = vault.previewDeposit(1000);  // Returns 100

// 2. MEV bot front-runs Alice with large deposit
//    This changes the exchange rate!

// 3. Alice's transaction executes
uint256 actualShares = vault.deposit(1000);  // Returns only 90 shares!

// Alice lost value due to front-running!
```

**The Solution:**

```solidity
function depositWithSlippage(
    uint256 assets,
    uint256 minShares  // Minimum shares Alice will accept
) external returns (uint256 shares) {
    shares = _deposit(assets);
    require(shares >= minShares, "Slippage too high");
    return shares;
}

// Usage:
uint256 expectedShares = vault.previewDeposit(1000);
uint256 minShares = expectedShares * 99 / 100;  // Accept 1% slippage
vault.depositWithSlippage(1000, minShares);
```

### 5. Rounding Direction

**Critical Rule: Always favor the vault (protocol), never the user**

Why? An attacker could exploit favorable rounding to drain the vault.

```solidity
// DEPOSIT/MINT: Round DOWN shares given to user
// User gives exact assets, gets slightly fewer shares
shares = (assets * totalShares) / totalAssets;  // Truncates

// WITHDRAW: Round UP shares taken from user
// User wants exact assets, we burn slightly more shares
shares = (assets * totalShares + totalAssets - 1) / totalAssets;  // Rounds up
```

**Example:**

```solidity
// Vault has 1000 assets, 999 shares (1.001 ratio)
// User deposits 100 assets

// shares = (100 * 999) / 1000 = 99.9 → truncates to 99 shares
// User gives 100 assets, gets 99 shares (vault keeps 0.9 share worth)

// User withdraws 100 assets
// shares = (100 * 999 + 1000 - 1) / 1000 = 100.899 → rounds up to 101
// User gets 100 assets, burns 101 shares (vault gains 1 share worth)
```

The vault accumulates tiny amounts over time, protecting against attacks.

## Common Attack Vectors

### 1. Inflation Attack

**The Attack:**

```solidity
// Step 1: Attacker is first depositor
vault.deposit(1 wei, attacker);  // Gets 1 share

// Step 2: Attacker donates 1000 ether directly to vault
token.transfer(address(vault), 1000 ether);

// Step 3: Now totalAssets = 1000 ether + 1 wei, totalShares = 1
//         Exchange rate is ~1000 ether per share!

// Step 4: Victim tries to deposit 999 ether
shares = (999 ether * 1) / 1000 ether = 0.999 → 0 shares!
// Victim loses everything due to rounding down!
```

**Defense #1: Minimum Deposit**

```solidity
function deposit(uint256 assets) external returns (uint256 shares) {
    shares = convertToShares(assets);
    require(shares > 0, "Zero shares");
    require(shares >= MIN_SHARES, "Below minimum");
    // ...
}
```

**Defense #2: Virtual Shares (Advanced)**

```solidity
// Add virtual offset to make inflation attack expensive
uint256 constant VIRTUAL_SHARES = 1e8;
uint256 constant VIRTUAL_ASSETS = 1;

function convertToShares(uint256 assets) public view returns (uint256) {
    return (assets * (totalShares + VIRTUAL_SHARES))
           / (totalAssets + VIRTUAL_ASSETS);
}
```

**Defense #3: Mint Dead Shares on First Deposit**

```solidity
if (totalShares == 0) {
    // Burn first 1000 shares to address(0)
    _mint(address(0), 1000);
    shares = assets - 1000;
}
```

### 2. Donation Attack

**The Attack:**

```solidity
// Attacker donates tokens directly to vault
token.transfer(address(vault), 1000 ether);

// If vault uses balanceOf for totalAssets:
function totalAssets() public view returns (uint256) {
    return token.balanceOf(address(this));  // WRONG!
}

// The accounting breaks - shares become worth more, but who gets the profit?
```

**Defense: Internal Accounting**

```solidity
uint256 private _totalAssets;  // Track deposits internally

function deposit(uint256 assets) external {
    _totalAssets += assets;  // Increment internal counter
    token.transferFrom(msg.sender, address(this), assets);
}

function totalAssets() public view returns (uint256) {
    return _totalAssets;  // Use internal accounting, not balanceOf
}
```

### 3. Front-Running

**The Attack:**

```solidity
// 1. Alice submits: deposit 1000 assets
// 2. MEV bot sees Alice's transaction in mempool
// 3. Bot front-runs with large deposit, changing exchange rate
// 4. Alice gets fewer shares than expected
```

**Defense: Slippage Protection**

```solidity
function depositWithSlippage(uint256 assets, uint256 minShares) external {
    uint256 shares = _deposit(assets);
    require(shares >= minShares, "Slippage exceeded");
}
```

## Introduction to ERC-4626

This project teaches the **core concepts** of ERC-4626, the Tokenized Vault Standard:

| This Project | ERC-4626 | Notes |
|--------------|----------|-------|
| `deposit()` | `deposit(assets, receiver)` | Mint shares for assets |
| `withdraw()` | `withdraw(assets, receiver, owner)` | Burn shares for assets |
| N/A | `mint(shares, receiver)` | Deposit assets for exact shares |
| N/A | `redeem(shares, receiver, owner)` | Burn exact shares for assets |
| `previewDeposit()` | `previewDeposit(assets)` | Simulate deposit |
| `previewWithdraw()` | `previewWithdraw(assets)` | Simulate withdraw |
| `convertToShares()` | `convertToShares(assets)` | Assets → shares conversion |
| `convertToAssets()` | `convertToAssets(shares)` | Shares → assets conversion |

**ERC-4626 also includes:**

- `maxDeposit(receiver)` - Maximum assets user can deposit
- `maxWithdraw(owner)` - Maximum assets user can withdraw
- `maxMint(receiver)` - Maximum shares user can mint
- `maxRedeem(owner)` - Maximum shares user can redeem
- Standard events: `Deposit`, `Withdraw`

After mastering this project, ERC-4626 will be much easier to understand!

## What You'll Build

A simplified deposit/withdraw vault with:

1. **Share-based accounting** - Track proportional ownership
2. **Deposit function** - Convert assets to shares
3. **Withdraw function** - Convert shares to assets
4. **Preview functions** - Simulate transactions
5. **Slippage protection** - Prevent front-running losses
6. **Proper rounding** - Always favor the vault
7. **Attack resistance** - Handle inflation and donation attacks

## Tasks

### Task 1: Implement the Skeleton Contract

Open `src/Project20.sol` and implement:

1. Share calculation math in `convertToShares()` and `convertToAssets()`
2. Deposit function with share minting
3. Withdraw function with share burning
4. Preview functions for simulation
5. Slippage protection variants

### Task 2: Run the Tests

```bash
cd 20-deposit-withdraw

# Run all tests
forge test -vvv

# Run specific test categories
forge test --match-test test_Deposit
forge test --match-test test_Withdraw
forge test --match-test test_Preview
forge test --match-test test_Slippage

# Gas report
forge test --gas-report
```

### Task 3: Study the Solution

Compare your implementation with `src/solution/DepositWithdrawSolution.sol`:

**Solution File Features**:
- **CS Concepts**: Explains proportional math, share-based accounting, precision handling
- **Connections to Project 11**: ERC-4626 uses this exact pattern for vault operations
- **Connections to Project 06**: Running totals pattern for efficient balance tracking
- **Connections to Project 02**: CEI pattern for secure deposits/withdrawals
- **Real-World Context**: Foundation for all yield vaults (Yearn, Aave, Compound)

- Understand the share conversion math
- See how rounding favors the vault
- Learn slippage protection patterns
- Study attack mitigations

### Task 4: Experiment with Edge Cases

```bash
# Run fuzz tests
forge test --match-test testFuzz

# Run with high verbosity to see all traces
forge test -vvvv

# Test specific scenarios
forge test --match-test test_InflationAttack
forge test --match-test test_MultipleUsers
```

## Security Checklist

- [ ] Share calculations round in favor of vault
- [ ] Zero-share deposits are rejected
- [ ] Preview functions match actual behavior
- [ ] Slippage protection is available
- [ ] Internal accounting prevents donation attacks
- [ ] First depositor can't manipulate share price
- [ ] Reentrancy guards on state-changing functions
- [ ] Events emitted for all deposits/withdraws

## Real-World Applications

### Yield Vaults (Yearn, Beefy)

```solidity
// Users deposit USDC, get yUSDC shares
vault.deposit(1000e6);  // Deposit 1000 USDC

// Vault deploys USDC to yield strategies
// Time passes, yield accrues...

// User redeems shares for original deposit + yield
vault.withdraw(shares);  // Gets 1050 USDC (5% yield)
```

### Lending Protocols (Aave, Compound)

```solidity
// Deposit USDC, get aUSDC (interest-bearing token)
aavePool.deposit(1000e6);  // Get aUSDC shares

// aUSDC grows in value as interest accrues
// 1 aUSDC might represent 1.05 USDC after time

// Withdraw to get USDC back with interest
aavePool.withdraw(aUsdcBalance);
```

### Liquidity Mining

```solidity
// Stake LP tokens, get vault shares
vault.deposit(uniswapLP);

// Vault auto-compounds rewards
// Shares increase in value as rewards are claimed and re-invested

// Withdraw shares for original LP + accumulated rewards
vault.withdraw(shares);
```

## Gas Optimization Tips

1. **Use internal accounting** - Cheaper than checking `balanceOf` repeatedly
2. **Cache storage variables** - Store `totalShares` in memory during calculations
3. **Avoid redundant checks** - Don't check `shares > 0` twice
4. **Use immutable** - Mark `token` as `immutable` for cheaper reads
5. **Batch operations** - Allow depositing for multiple users in one transaction

## Testing Checklist

Your tests should cover:

- [ ] First deposit (bootstrap ratio)
- [ ] Subsequent deposits with existing shares
- [ ] Withdrawals with correct share burning
- [ ] Preview functions match actual results
- [ ] Slippage protection reverts when threshold exceeded
- [ ] Multiple users depositing and withdrawing
- [ ] Edge cases: minimum amounts, maximum amounts
- [ ] Fuzz tests for deposit/withdraw invariants
- [ ] Inflation attack mitigation
- [ ] Donation attack doesn't break accounting

## Pro Tips

1. **Preview before deposit** - Always show users what they'll get
2. **Set reasonable slippage** - 0.5-1% is typical for DeFi
3. **Round in vault's favor** - Small fees accumulate to protect against attacks
4. **Emit events** - Off-chain indexers need deposit/withdraw events
5. **Consider minimums** - Prevent dust amounts that cost more gas than value
6. **Use safe math** - Solidity 0.8+ has built-in overflow checks
7. **Test with different decimals** - Not all tokens use 18 decimals

## Common Mistakes

### Mistake 1: Wrong Rounding

```solidity
// BAD: Rounding in user's favor
shares = (assets * totalShares + totalAssets - 1) / totalAssets;  // Rounds up
```

```solidity
// GOOD: Rounding in vault's favor
shares = (assets * totalShares) / totalAssets;  // Rounds down
```

### Mistake 2: Using balanceOf for Accounting

```solidity
// BAD: Direct donations break accounting
function totalAssets() public view returns (uint256) {
    return token.balanceOf(address(this));
}
```

```solidity
// GOOD: Track deposits internally
uint256 private _totalAssets;
function totalAssets() public view returns (uint256) {
    return _totalAssets;
}
```

### Mistake 3: No Slippage Protection

```solidity
// BAD: User has no control over outcome
function deposit(uint256 assets) external returns (uint256 shares) {
    shares = convertToShares(assets);
    // User might get way fewer shares than expected!
}
```

```solidity
// GOOD: User can specify minimum acceptable shares
function deposit(uint256 assets, uint256 minShares) external returns (uint256 shares) {
    shares = convertToShares(assets);
    require(shares >= minShares, "Slippage too high");
}
```

## Next Steps

After completing this project:

1. Study **ERC-4626 Tokenized Vault Standard** (Project 11)
2. Learn about **yield strategies** (Aave, Compound, Curve)
3. Implement **fee mechanisms** (performance fees, management fees)
4. Add **access controls** (deposit caps, whitelists)
5. Build **multi-strategy vaults** (diversified yield)

## Further Reading

- [EIP-4626: Tokenized Vault Standard](https://eips.ethereum.org/EIPS/eip-4626)
- [OpenZeppelin ERC4626 Documentation](https://docs.openzeppelin.com/contracts/4.x/erc4626)
- [Yearn Vaults Explained](https://docs.yearn.finance/getting-started/products/yvaults/overview)
- [Understanding Share-Based Accounting](https://ethereum.org/en/developers/docs/standards/tokens/erc-4626/)
- [Slippage Protection Best Practices](https://www.paradigm.xyz/2021/04/understanding-automated-market-makers-part-1-price-impact)

## Completion Checklist

- [ ] Implemented share-based deposit/withdraw
- [ ] All tests pass
- [ ] Understand share conversion math
- [ ] Can explain rounding directions
- [ ] Know how to prevent inflation attack
- [ ] Implemented slippage protection
- [ ] Understand preview function importance
- [ ] Ready to learn ERC-4626

---

**Ready to build?** Start with `src/Project20.sol` and complete the TODOs!

---


## 22-erc20-openzeppelin

# Project 22: ERC-20 (OpenZeppelin)

This project explores OpenZeppelin's ERC-20 implementation, teaching you how to leverage battle-tested contract patterns, hooks, and extensions to build production-ready tokens.

## Learning Objectives

- Understand OpenZeppelin vs manual ERC-20 implementation
- Master the ERC20 base contract and its features
- Learn the hook system (_beforeTokenTransfer, _afterTokenTransfer)
- Implement various extension patterns (Burnable, Pausable, Snapshot, Votes)
- Make informed decisions about when to use each extension
- Compare gas costs between manual and OpenZeppelin implementations
- Apply best practices for production token contracts

## OpenZeppelin vs Manual Implementation: Production-Ready Patterns

**FIRST PRINCIPLES: Battle-Tested vs Custom Code**

OpenZeppelin provides production-ready implementations of common standards. Understanding when to use libraries vs custom code is crucial!

**CONNECTION TO PROJECT 08**:
- **Project 08**: We implemented ERC20 from scratch (learning the fundamentals)
- **Project 22**: We use OpenZeppelin's ERC20 (production-ready implementation)
- Both approaches have their place - understand fundamentals, use libraries in production!

### Why Use OpenZeppelin?

**Advantages:**
1. **Battle-tested**: Audited by multiple security firms and used by thousands of projects
2. **Gas-optimized**: Carefully optimized for gas efficiency (though slightly more than custom)
3. **Modular**: Extension pattern allows adding functionality without bloating base contract
4. **Maintained**: Regular updates for security patches and new standards
5. **Standardized**: Widely recognized code patterns reduce audit time

**Disadvantages:**
1. **Slightly higher gas costs**: Generic implementation trades some gas for flexibility (~2% overhead)
2. **Learning curve**: Need to understand the extension patterns
3. **Dependency**: External dependency in your project
4. **Less control**: Can't customize low-level behavior without forking

**WHEN TO USE OPENZEPPELIN**:
- ✅ Production contracts (security > gas savings)
- ✅ Standard functionality (ERC20, ERC721, etc.)
- ✅ When you need extensions (Pausable, Burnable, etc.)
- ✅ When audit time is limited (battle-tested code)

**WHEN TO USE CUSTOM**:
- ✅ Learning/education (understand fundamentals)
- ✅ Gas-critical applications (need every optimization)
- ✅ Non-standard requirements (custom logic needed)
- ✅ When you need full control (no dependencies)

**COMPARISON TO RUST** (DSA/Library Pattern):

**Rust** (using crates):
```rust
// Using standard library or crates
use std::collections::HashMap;
use serde::{Serialize, Deserialize};

// Benefits: Battle-tested, maintained, standardized
// Trade-off: Less control, dependency management
```

**Solidity** (using OpenZeppelin):
```solidity
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    // Benefits: Battle-tested, maintained, standardized
    // Trade-off: Slightly more gas, dependency
}
```

Both use library patterns - leverage existing code for production, write custom for learning!

### Gas Comparison

| Operation | Manual ERC20 | OpenZeppelin ERC20 | Difference |
|-----------|-------------|-------------------|------------|
| Deployment | ~650k gas | ~750k gas | +15% |
| Transfer | ~51k gas | ~52k gas | +2% |
| Approve | ~44k gas | ~45k gas | +2% |
| TransferFrom | ~55k gas | ~56k gas | +2% |

**Verdict**: OpenZeppelin adds ~2% gas overhead per operation but provides significantly better security guarantees. The trade-off is almost always worth it for production contracts.

## ERC20 Base Contract Features

OpenZeppelin's ERC20 provides:

```solidity
// Core ERC20 functionality
function totalSupply() public view returns (uint256)
function balanceOf(address account) public view returns (uint256)
function transfer(address to, uint256 amount) public returns (bool)
function allowance(address owner, address spender) public view returns (uint256)
function approve(address spender, uint256 amount) public returns (bool)
function transferFrom(address from, address to, uint256 amount) public returns (bool)

// Extended functionality
function name() public view returns (string memory)
function symbol() public view returns (string memory)
function decimals() public view returns (uint8)

// Internal functions for extensions
function _mint(address account, uint256 amount) internal
function _burn(address account, uint256 amount) internal
function _transfer(address from, address to, uint256 amount) internal
function _approve(address owner, address spender, uint256 amount) internal
```

## Hook System

OpenZeppelin's hook system allows you to inject custom logic before and after token transfers.

### Available Hooks

```solidity
function _update(address from, address to, uint256 value) internal virtual
```

**Note**: In OpenZeppelin 5.x, `_beforeTokenTransfer` and `_afterTokenTransfer` were replaced with a single `_update` hook that's called during transfers, mints, and burns.

### Hook Use Cases

1. **Pausable Tokens**: Prevent transfers when contract is paused
2. **Snapshot Tokens**: Record balances at specific blocks
3. **Vesting**: Enforce token lock-up periods
4. **Fees**: Deduct fees on every transfer
5. **Whitelisting**: Restrict transfers to approved addresses
6. **Supply Caps**: Enforce maximum supply limits

### Hook Example

```solidity
function _update(address from, address to, uint256 value) internal virtual override {
    // from == address(0) means minting
    // to == address(0) means burning
    // both non-zero means transfer

    if (from != address(0) && to != address(0)) {
        // Custom transfer logic
        require(!paused, "Transfers are paused");
    }

    super._update(from, to, value);
}
```

## Extension Patterns

OpenZeppelin provides several pre-built extensions. Here's when to use each:

### 1. ERC20Burnable

**What it does**: Allows token holders to burn (destroy) their tokens.

**Use when**:
- You want deflationary tokenomics
- Users need to permanently remove tokens from circulation
- Implementing burn-to-redeem mechanisms

**Gas cost**: Adds ~500 gas per burn operation

```solidity
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract MyToken is ERC20, ERC20Burnable {
    // burn() and burnFrom() are now available
}
```

### 2. ERC20Pausable

**What it does**: Allows owner to pause all token transfers.

**Use when**:
- You need emergency stop functionality
- Regulatory compliance requires transfer halting
- During security incident response

**Gas cost**: Adds ~2.5k gas per transfer (checks paused state)

```solidity
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";

contract MyToken is ERC20, ERC20Pausable, Ownable {
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
```

### 3. ERC20Snapshot

**What it does**: Records token balances at specific points in time.

**Use when**:
- Implementing dividend distributions based on historical holdings
- Governance voting based on past balances
- Airdrop calculations

**Gas cost**: Adds ~10-15k gas per transfer (maintains historical records)

```solidity
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";

contract MyToken is ERC20, ERC20Snapshot, Ownable {
    function snapshot() public onlyOwner returns (uint256) {
        return _snapshot();
    }

    function balanceOfAt(address account, uint256 snapshotId) public view returns (uint256) {
        return super.balanceOfAt(account, snapshotId);
    }
}
```

### 4. ERC20Votes

**What it does**: Enables on-chain governance with delegation and voting power.

**Use when**:
- Building a DAO governance token
- Need delegated voting mechanisms
- Implementing on-chain governance proposals

**Gas cost**: Adds ~20-30k gas per transfer (maintains voting checkpoints)

```solidity
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract GovernanceToken is ERC20, ERC20Votes {
    constructor() ERC20("Governance", "GOV") ERC20Permit("Governance") {
        _mint(msg.sender, 1_000_000e18);
    }

    // Required overrides
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    function nonces(address owner) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
```

### 5. ERC20Permit (EIP-2612)

**What it does**: Allows approvals via signatures instead of transactions.

**Use when**:
- Improving UX by removing approval transactions
- Building gasless transaction systems
- Integrating with meta-transaction protocols

**Gas cost**: ~0 gas (uses off-chain signatures)

```solidity
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract MyToken is ERC20, ERC20Permit {
    constructor() ERC20("MyToken", "MTK") ERC20Permit("MyToken") {
        _mint(msg.sender, 1_000_000e18);
    }
}
```

### 6. ERC20Capped

**What it does**: Enforces a maximum token supply cap.

**Use when**:
- You want to guarantee maximum supply
- Implementing fixed-supply tokenomics
- Building deflationary with supply cap

**Gas cost**: Adds ~200 gas per mint operation

```solidity
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

contract MyToken is ERC20, ERC20Capped {
    constructor() ERC20("MyToken", "MTK") ERC20Capped(1_000_000e18) {
        _mint(msg.sender, 500_000e18); // Can't exceed cap
    }
}
```

## Combining Multiple Extensions

You can combine multiple extensions, but be aware of:

1. **Override conflicts**: Multiple extensions may override the same function
2. **Gas costs**: Each extension adds overhead
3. **Complexity**: More extensions = more complex interactions

### Example: Full-Featured Token

```solidity
contract FullToken is ERC20, ERC20Burnable, ERC20Pausable, ERC20Snapshot, Ownable {
    constructor() ERC20("Full", "FULL") Ownable(msg.sender) {
        _mint(msg.sender, 1_000_000e18);
    }

    // Must override _update to resolve conflicts
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Pausable, ERC20Snapshot) {
        super._update(from, to, value);
    }
}
```

## Extension Selection Guide

| Feature Needed | Extension | Gas Impact | Complexity |
|----------------|-----------|------------|------------|
| Token burning | ERC20Burnable | Low | Low |
| Emergency pause | ERC20Pausable | Low | Low |
| Historical balances | ERC20Snapshot | Medium | Medium |
| Governance/voting | ERC20Votes | High | High |
| Gasless approvals | ERC20Permit | None | Low |
| Supply cap | ERC20Capped | Low | Low |
| Flash minting | ERC20FlashMint | Medium | Medium |

## Best Practices

### 1. Initialization

```solidity
// Good: Set metadata in constructor
constructor() ERC20("MyToken", "MTK") {
    _mint(msg.sender, INITIAL_SUPPLY);
}

// Bad: Forgetting to set supply
constructor() ERC20("MyToken", "MTK") {
    // No tokens minted - useless token!
}
```

### 2. Access Control

```solidity
// Good: Use OpenZeppelin's AccessControl or Ownable
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, Ownable {
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

// Bad: Manual access control (bug-prone)
address public owner;
modifier onlyOwner() {
    require(msg.sender == owner); // Missing error message
    _;
}
```

### 3. Safe Minting

```solidity
// Good: Check for address(0) and overflow
function mint(address to, uint256 amount) public onlyOwner {
    require(to != address(0), "Cannot mint to zero address");
    _mint(to, amount); // OpenZeppelin checks for overflow
}

// Bad: No validation
function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount); // Could mint to address(0)
}
```

### 4. Event Emissions

```solidity
// Good: OpenZeppelin automatically emits Transfer events
// You just need to emit custom events

event TokensMinted(address indexed to, uint256 amount);

function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount); // Emits Transfer(address(0), to, amount)
    emit TokensMinted(to, amount); // Your custom event
}
```

### 5. Override Conflicts

```solidity
// Good: Properly resolve multiple inheritance
function _update(
    address from,
    address to,
    uint256 value
) internal override(ERC20, ERC20Pausable, ERC20Snapshot) {
    super._update(from, to, value); // Calls all parent implementations
}

// Bad: Missing override specifiers
function _update(address from, address to, uint256 value) internal override(ERC20) {
    super._update(from, to, value); // Doesn't call all parents!
}
```

### 6. Decimal Precision

```solidity
// Good: Document your decimal choice
/**
 * @dev Uses 18 decimals (standard for most ERC20 tokens)
 * 1 token = 1e18 units
 */
constructor() ERC20("MyToken", "MTK") {
    _mint(msg.sender, 1_000_000 * 10**18);
}

// Also good: Custom decimals with clear documentation
function decimals() public pure override returns (uint8) {
    return 6; // USDC-style 6 decimals
}
```

### 7. Testing

```solidity
// Always test:
// 1. Basic transfers
// 2. Approval mechanisms
// 3. Edge cases (zero address, zero amount)
// 4. Access control
// 5. Extension-specific functionality
// 6. Integration with other contracts
```

## Common Pitfalls

### 1. Forgetting Override Specifiers

```solidity
// Wrong: Will fail to compile
contract MyToken is ERC20, ERC20Pausable {
    function _update(address from, address to, uint256 value) internal {
        // Missing: override(ERC20, ERC20Pausable)
        super._update(from, to, value);
    }
}
```

### 2. Incorrect Super Calls

```solidity
// Wrong: Not calling super._update
function _update(address from, address to, uint256 value)
    internal override(ERC20, ERC20Pausable)
{
    // Custom logic but forgot super call!
    // This breaks the token!
}

// Correct:
function _update(address from, address to, uint256 value)
    internal override(ERC20, ERC20Pausable)
{
    // Custom logic first
    super._update(from, to, value); // Then call parent
}
```

### 3. Snapshot Before Distribution

```solidity
// Wrong: Snapshot after distribution
function distributeRewards() public {
    uint256 currentSnapshot = _snapshot(); // Too late!
    // Users could have transferred tokens already
}

// Correct: Snapshot before announcement
function announceDistribution() public {
    uint256 snapshot = _snapshot(); // Lock balances first
    // Then announce distribution
}
```

### 4. Not Handling Delegation for Votes

```solidity
// Wrong: Assuming votes are automatic
function getVotingPower(address account) public view returns (uint256) {
    return balanceOf(account); // Wrong! Need to delegate first
}

// Correct: Use getVotes
function getVotingPower(address account) public view returns (uint256) {
    return getVotes(account); // Returns delegated voting power
}
```

## Project Structure

```
22-erc20-openzeppelin/
├── README.md
├── src/
│   ├── Project22.sol              # Skeleton for students
│   └── solution/
│       └── Project22Solution.sol  # Complete solution
├── test/
│   └── Project22.t.sol           # Comprehensive tests
└── script/
    └── DeployProject22.s.sol     # Deployment script
```

## Getting Started

1. Install dependencies:
```bash
forge install OpenZeppelin/openzeppelin-contracts
```

2. Implement the TODOs in `src/Project22.sol`

3. Run tests:
```bash
forge test --match-path test/Project22.t.sol -vv
```

4. Compare with solution:
```bash
forge test --match-path test/Project22.t.sol --match-contract Project22SolutionTest -vvv
```

## Tasks

### Basic Tasks

1. Create a simple ERC20 token using OpenZeppelin
2. Add burnable functionality
3. Add pausable functionality
4. Combine multiple extensions

### Advanced Tasks

5. Implement a snapshot token for dividend distribution
6. Create a governance token with voting capabilities
7. Build a token with custom hook logic
8. Implement a capped token with vesting

### Expert Tasks

9. Create a full-featured token combining 4+ extensions
10. Build a token with custom fee mechanism using hooks
11. Implement a governance token with delegation strategies
12. Compare gas costs between manual and OZ implementation

## Additional Resources

- [OpenZeppelin ERC20 Documentation](https://docs.openzeppelin.com/contracts/5.x/erc20)
- [OpenZeppelin Contracts GitHub](https://github.com/OpenZeppelin/openzeppelin-contracts)
- [EIP-20: Token Standard](https://eips.ethereum.org/EIPS/eip-20)
- [EIP-2612: Permit Extension](https://eips.ethereum.org/EIPS/eip-2612)
- [OpenZeppelin Wizard](https://wizard.openzeppelin.com/)

## Security Considerations

1. **Always use latest OpenZeppelin version**: Security patches are critical
2. **Audit custom hooks**: Any custom logic in hooks should be thoroughly audited
3. **Test extension interactions**: Multiple extensions can have unexpected interactions
4. **Be cautious with pausability**: Paused tokens can be permanently locked
5. **Understand delegation**: ERC20Votes delegation can have complex edge cases
6. **Reentrancy**: While ERC20 is generally safe, custom hooks may introduce risks

## Summary

OpenZeppelin's ERC20 implementation provides:
- Battle-tested, secure token functionality
- Modular extension system for common patterns
- Small gas overhead (~2%) for significant security gains
- Comprehensive hooks for custom logic
- Production-ready code used by thousands of projects

For production tokens, OpenZeppelin is almost always the right choice. The minor gas costs are far outweighed by the security, maintainability, and community trust it provides.

---


## 23-erc20-permit

# Project 23: ERC-20 Permit (EIP-2612)

Learn how to implement gasless token approvals using EIP-2612 permit functionality, enabling better UX and significant gas savings for users.

## Table of Contents
- [Overview](#overview)
- [The Approval Problem](#the-approval-problem)
- [EIP-2612 Solution](#eip-2612-solution)
- [How Permit Works](#how-permit-works)
- [EIP-712 Integration](#eip-712-integration)
- [Gas Comparison](#gas-comparison)
- [Nonces and Deadlines](#nonces-and-deadlines)
- [Implementation Guide](#implementation-guide)
- [Security Considerations](#security-considerations)
- [Real-World Usage](#real-world-usage)

## Overview

**EIP-2612** introduces the `permit` function to ERC-20 tokens, allowing users to approve token spending via off-chain signatures instead of on-chain transactions.

### What You'll Learn
- EIP-2612 permit standard specification
- Signature-based approvals using EIP-712
- Domain separators and replay protection
- Nonce management for permits
- Deadline enforcement for signature expiration
- Gas optimization through signature-based approvals
- OpenZeppelin ERC20Permit extension usage

### Why This Matters
- **Better UX**: One transaction instead of two (approve + transfer)
- **Gas Savings**: No approval transaction needed
- **Gasless Approvals**: Users can sign without paying gas
- **Meta-Transactions**: Enable relayer-based transactions
- **Standard Compliance**: Used by major DeFi protocols

## The Approval Problem: Why Permit Exists

**FIRST PRINCIPLES: Transaction Overhead**

Traditional ERC-20 approvals require a separate transaction, creating UX friction and gas costs. EIP-2612 permit solves this!

**CONNECTION TO PROJECT 08 & 19**:
- **Project 08**: We learned about ERC20 `approve()` function
- **Project 19**: We learned about EIP-712 signatures
- **Project 23**: Permit combines both - signatures for approvals!

### Traditional ERC-20 Workflow

When a user wants to interact with a DeFi protocol (like Uniswap), they need TWO transactions:

```solidity
// Transaction 1: Approve (from Project 08 knowledge)
token.approve(uniswapRouter, 1000e18);  // Costs gas, requires ETH
// Gas: ~45,000 gas (from Project 08)
// Requires: User must have ETH for gas

// Transaction 2: Execute
uniswapRouter.swapExactTokensForETH(...);  // Costs gas again
// Gas: ~100,000+ gas
// Total: ~145,000 gas across 2 transactions
```

**UNDERSTANDING THE FRICTION**:

```
Traditional Flow:
┌─────────────────────────────────────────┐
│ User wants to swap tokens               │
│   ↓                                      │
│ Step 1: Approve DEX                     │ ← Transaction 1
│   - User signs transaction               │
│   - Wait for confirmation                │ ← Block time delay
│   - Pay gas (~45k gas)                  │ ← Requires ETH
│   ↓                                      │
│ Step 2: Execute swap                    │ ← Transaction 2
│   - User signs transaction               │
│   - Wait for confirmation                │ ← Another delay
│   - Pay gas (~100k gas)                 │ ← More ETH needed
│   ↓                                      │
│ Total: 2 transactions, 2 delays, 2 gas payments │
└─────────────────────────────────────────┘
```

### Problems

1. **Two Transactions Required**: User must wait for approval to confirm
   - Block time delay between transactions
   - Poor UX (confusing for new users)

2. **Poor UX**: Confusing for new users ("Why do I need to approve?")
   - Users don't understand why two steps are needed
   - Approval seems like an extra step

3. **Gas Costs**: Both transactions cost gas
   - Approval: ~45,000 gas
   - Swap: ~100,000 gas
   - Total: ~145,000 gas

4. **ETH Requirement**: User needs ETH for gas even if they only have tokens
   - Can't swap tokens if you don't have ETH for gas
   - Forces users to hold ETH just for gas

5. **Front-Running Risk**: Approval can be front-run
   - Attacker sees approval in mempool
   - Can front-run and use approval before user's swap

**REAL-WORLD ANALOGY**: 
Like needing to sign two separate forms at a bank - one to authorize a transaction, then another to actually do it. Permit is like signing both forms at once!

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/ERC20PermitSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployERC20PermitSolution.s.sol` - Deployment script patterns
- `test/solution/ERC20PermitSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains cryptographic signatures (ECDSA), domain separation, permit pattern
- **Connections to Project 08**: ERC20 base (permit is an extension)
- **Connections to Project 19**: EIP-712 typed structured data signing
- **Real-World Context**: Enables gasless approvals - critical for DeFi UX

## EIP-2612 Solution

### Permit Workflow

With EIP-2612, users can approve via signature:

```solidity
// Off-chain: User signs permit (NO GAS, NO TRANSACTION)
const signature = await signPermit(owner, spender, amount, deadline);

// On-chain: Single transaction does everything
token.permit(owner, spender, amount, deadline, v, r, s);  // Sets approval
uniswapRouter.swapExactTokensForETH(...);  // Uses approval
```

### Benefits
- **One Transaction**: Approve and execute in single transaction
- **No Gas for Approval**: Signature is free
- **Better UX**: Simpler flow for users
- **Gasless Transactions**: Relayers can submit on behalf of users
- **Meta-Transactions**: Enable advanced patterns

## How Permit Works

### The Permit Function

```solidity
function permit(
    address owner,        // Token owner granting approval
    address spender,      // Address being approved
    uint256 value,        // Amount to approve
    uint256 deadline,     // Signature expiration timestamp
    uint8 v,             // ECDSA signature component
    bytes32 r,           // ECDSA signature component
    bytes32 s            // ECDSA signature component
) external;
```

### Step-by-Step Process

#### 1. Off-Chain: User Signs Permit

```typescript
// User's wallet (MetaMask, etc.)
const domain = {
    name: 'MyToken',
    version: '1',
    chainId: 1,
    verifyingContract: tokenAddress
};

const types = {
    Permit: [
        { name: 'owner', type: 'address' },
        { name: 'spender', type: 'address' },
        { name: 'value', type: 'uint256' },
        { name: 'nonce', type: 'uint256' },
        { name: 'deadline', type: 'uint256' }
    ]
};

const value = {
    owner: userAddress,
    spender: spenderAddress,
    value: amount,
    nonce: await token.nonces(userAddress),
    deadline: Math.floor(Date.now() / 1000) + 3600  // 1 hour
};

// User signs (no transaction, no gas)
const signature: string = await signer.signTypedData(domain, types, value);
const sig = ethers.Signature.from(signature);
const { v, r, s } = { v: sig.v, r: sig.r, s: sig.s };
```

#### 2. On-Chain: Contract Verifies and Approves

```solidity
function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
) public virtual {
    // 1. Check deadline
    require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

    // 2. Get current nonce
    uint256 nonce = _useNonce(owner);

    // 3. Create EIP-712 struct hash
    bytes32 structHash = keccak256(
        abi.encode(
            PERMIT_TYPEHASH,
            owner,
            spender,
            value,
            nonce,
            deadline
        )
    );

    // 4. Create digest with domain separator
    bytes32 digest = _hashTypedDataV4(structHash);

    // 5. Recover signer from signature
    address signer = ECDSA.recover(digest, v, r, s);

    // 6. Verify signer is owner
    require(signer == owner, "ERC20Permit: invalid signature");

    // 7. Set approval
    _approve(owner, spender, value);
}
```

## EIP-712 Integration

### Why EIP-712?

EIP-712 provides:
- **Structured Data**: Type-safe signing
- **Human-Readable**: Users see what they're signing
- **Domain Separation**: Prevents cross-contract/chain replays

### Domain Separator

The domain separator uniquely identifies the token:

```solidity
// Computed once at deployment
bytes32 private immutable _DOMAIN_SEPARATOR;

constructor() {
    _DOMAIN_SEPARATOR = keccak256(
        abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes("MyToken")),      // Token name
            keccak256(bytes("1")),            // Version
            block.chainid,                    // Chain ID (1 = mainnet)
            address(this)                     // Token contract address
        )
    );
}
```

### Permit Typehash

```solidity
bytes32 public constant PERMIT_TYPEHASH = keccak256(
    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
);
```

### Creating the Digest

```solidity
// 1. Hash the struct data
bytes32 structHash = keccak256(
    abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonce, deadline)
);

// 2. Combine with domain separator (EIP-712 format)
bytes32 digest = keccak256(
    abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
);

// 3. Recover signer
address signer = ecrecover(digest, v, r, s);
```

## Gas Comparison

### Traditional Approve + TransferFrom

```solidity
// Transaction 1: approve() - ~46,000 gas
token.approve(spender, amount);

// Transaction 2: transferFrom() - ~65,000 gas
spender.transferFrom(owner, recipient, amount);

// TOTAL: ~111,000 gas + 2 transactions
```

### With Permit

```solidity
// Off-chain: User signs permit - 0 gas, no transaction

// On-chain: permit() + transferFrom() in one tx - ~85,000 gas
token.permit(owner, spender, amount, deadline, v, r, s);  // ~40,000 gas
spender.transferFrom(owner, recipient, amount);           // ~45,000 gas

// TOTAL: ~85,000 gas + 1 transaction
```

### Savings
- **Gas**: ~26,000 gas saved (~23% reduction)
- **Transactions**: 1 instead of 2 (50% reduction)
- **User Experience**: Dramatically improved
- **Cost at 50 gwei**: Saves ~$0.13 per approval (at $2000 ETH)

### Even Better: Integrated Permit

Many protocols integrate permit into their functions:

```solidity
// Single transaction does everything!
function swapWithPermit(
    address owner,
    uint256 amount,
    uint256 deadline,
    uint8 v, bytes32 r, bytes32 s
) external {
    // Apply permit
    token.permit(owner, address(this), amount, deadline, v, r, s);

    // Execute swap
    _swap(owner, amount);

    // No separate transferFrom needed - we're already approved!
}

// TOTAL: ~70,000 gas + 1 transaction
// SAVINGS: ~41,000 gas (37% reduction)
```

## Nonces and Deadlines

### Nonces

Nonces prevent replay attacks:

```solidity
// Each owner has an incrementing nonce
mapping(address => uint256) private _nonces;

function nonces(address owner) public view returns (uint256) {
    return _nonces[owner];
}

function _useNonce(address owner) internal returns (uint256 current) {
    current = _nonces[owner];
    _nonces[owner] = current + 1;
}
```

**Why Nonces Matter:**
- Each signature can only be used once
- Signatures must be used in order
- Prevents signature replay attacks
- Protects against front-running

### Deadlines

Deadlines limit signature validity:

```solidity
require(block.timestamp <= deadline, "ERC20Permit: expired deadline");
```

**Benefits:**
- Limits time window for signature use
- Prevents stale signatures
- User control over expiration
- Common practice: `deadline = block.timestamp + 1 hour`

### Nonce vs Deadline

| Feature | Nonce | Deadline |
|---------|-------|----------|
| Purpose | Prevent replay | Limit validity window |
| Type | Counter | Timestamp |
| Scope | Per user | Per signature |
| Required | Yes | Yes |
| User Control | No (automatic) | Yes (sets expiration) |

## Implementation Guide

### Option 1: OpenZeppelin (Recommended)

Use OpenZeppelin's battle-tested implementation:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract MyToken is ERC20, ERC20Permit {
    constructor() ERC20("MyToken", "MTK") ERC20Permit("MyToken") {
        _mint(msg.sender, 1000000 * 10**18);
    }
}

// That's it! You now have full permit functionality.
```

### Option 2: Manual Implementation

Implement yourself for learning:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract MyTokenWithPermit is ERC20, EIP712 {
    bytes32 private constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    mapping(address => uint256) private _nonces;

    constructor() ERC20("MyToken", "MTK") EIP712("MyToken", "1") {
        _mint(msg.sender, 1000000 * 10**18);
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(
            abi.encode(PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline)
        );

        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    function nonces(address owner) public view virtual returns (uint256) {
        return _nonces[owner];
    }

    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function _useNonce(address owner) internal virtual returns (uint256 current) {
        current = _nonces[owner];
        _nonces[owner] = current + 1;
    }
}
```

## Security Considerations

### 1. Signature Malleability

**Problem**: ECDSA signatures are malleable - multiple valid signatures exist for same message.

**Solution**: OpenZeppelin's ECDSA library handles this automatically:
```solidity
// Checks that s is in lower half of curve order
address signer = ECDSA.recover(hash, v, r, s);
```

### 2. Front-Running

**Problem**: Relayer could front-run permit transactions.

**Mitigation**:
- Nonces prevent replay
- Deadlines limit time window
- Use flashbots for MEV protection
- Integrate permit into main function

### 3. Deadline Validation

**Always check deadlines:**
```solidity
require(block.timestamp <= deadline, "Expired");
```

**Never use:**
```solidity
// BAD - deadline could be in the past!
deadline = block.timestamp - 1 days;

// GOOD - reasonable future deadline
deadline = block.timestamp + 1 hours;
```

### 4. Nonce Management

**Critical rules:**
- Increment nonce BEFORE external calls (reentrancy protection)
- Never reuse nonces
- Make nonces publicly queryable
- Consider ordered vs unordered nonces

### 5. Domain Separator

**Important for cross-chain:**
```solidity
// BAD - cached domain separator breaks on chain forks
bytes32 public constant DOMAIN_SEPARATOR = 0x123...;

// GOOD - computed dynamically or with fork detection
function _domainSeparatorV4() internal view returns (bytes32) {
    if (block.chainid == _CACHED_CHAIN_ID) {
        return _CACHED_DOMAIN_SEPARATOR;
    } else {
        return _buildDomainSeparator();
    }
}
```

### 6. Griefing Attacks

**Problem**: Attacker could front-run permit to grief user.

**Not a real issue because:**
- Only sets approval (desired outcome)
- Nonce prevents actual replay
- User's intended action still works

### 7. Infinite Approvals

**Consider the implications:**
```solidity
// Common pattern but has risks
token.permit(owner, spender, type(uint256).max, deadline, v, r, s);
```

**Better approach:**
```solidity
// Approve exact amount needed
token.permit(owner, spender, exactAmount, deadline, v, r, s);
```

## Real-World Usage

### Uniswap V2

```solidity
// UniswapV2Router02.sol
function swapExactTokensForETHWithPermit(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline,
    bool approveMax,
    uint8 v, bytes32 r, bytes32 s
) external {
    uint value = approveMax ? type(uint256).max : amountIn;
    IERC20Permit(path[0]).permit(msg.sender, address(this), value, deadline, v, r, s);
    swapExactTokensForETH(amountIn, amountOutMin, path, to, deadline);
}
```

### DAI

DAI was one of the first to implement permit (pre-EIP-2612):

```solidity
// Maker's DAI uses slightly different parameter order
function permit(
    address holder,
    address spender,
    uint256 nonce,  // Different position!
    uint256 expiry,
    bool allowed,   // Boolean instead of amount
    uint8 v, bytes32 r, bytes32 s
) external;
```

### USDC

USDC implements standard EIP-2612:

```solidity
// Can approve USDC via permit
usdc.permit(owner, spender, amount, deadline, v, r, s);
```

### Common DeFi Integrations

```solidity
// Aave
pool.supplyWithPermit(asset, amount, onBehalfOf, referralCode, deadline, v, r, s);

// 1inch
aggregator.swapWithPermit(...);

// SushiSwap
router.swapWithPermit(...);
```

## Testing Your Implementation

```bash
# Run all tests
forge test --match-path test/Project23.t.sol -vvv

# Test specific function
forge test --match-test testPermitSetsApproval -vvv

# Check gas usage
forge test --match-path test/Project23.t.sol --gas-report

# Test with gas comparison
forge test --match-test testGasComparison -vvv
```

## Tasks

### Part 1: Understanding (src/Project23.sol)
1. Implement `permit()` function with signature verification
2. Add nonce tracking and management
3. Implement deadline validation
4. Create EIP-712 domain separator
5. Implement struct hashing

### Part 2: Gas Optimization
1. Compare gas costs: approve vs permit
2. Implement integrated permit functions
3. Optimize signature verification
4. Test with various amounts

### Part 3: Security
1. Prevent signature malleability
2. Handle nonce edge cases
3. Validate deadline properly
4. Test replay protection
5. Check domain separator uniqueness

### Part 4: Integration
1. Use OpenZeppelin's ERC20Permit
2. Create wrapper functions with permit
3. Test with relayer pattern
4. Implement batch permits

## Additional Resources

### Standards
- [EIP-2612: Permit Extension for ERC-20](https://eips.ethereum.org/EIPS/eip-2612)
- [EIP-712: Typed Structured Data](https://eips.ethereum.org/EIPS/eip-712)
- [EIP-191: Signed Data Standard](https://eips.ethereum.org/EIPS/eip-191)

### Implementations
- [OpenZeppelin ERC20Permit](https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#ERC20Permit)
- [Uniswap Permit2](https://github.com/Uniswap/permit2)
- [DAI Permit](https://github.com/makerdao/dss/blob/master/src/dai.sol)

### Tools
- [eth-permit](https://github.com/dmihal/eth-permit) - Easy permit signing
- [permit-helper](https://github.com/Uniswap/permit2-sdk) - Uniswap SDK
- [EIP-712 Signing](https://docs.metamask.io/guide/signing-data.html) - MetaMask docs

### Articles
- [Understanding EIP-2612](https://soliditydeveloper.com/eip-2612)
- [Gasless Approvals Deep Dive](https://blog.openzeppelin.com/workshop-recap-secure-development-workshop-2/)

## License

MIT

---


## 25-erc721a-optimized

# Project 25: ERC-721A Optimized NFT Collection

Master Azuki's ERC-721A standard for gas-optimized batch minting of NFTs.

## Learning Objectives

- Understand ERC-721A optimization techniques
- Learn how batch minting saves gas
- Master storage packing and ownership inference
- Compare standard ERC-721 vs ERC-721A
- Implement sequential token IDs efficiently
- Know when to use ERC-721A

## ERC-721A Overview: Gas-Optimized NFT Minting

**FIRST PRINCIPLES: Batch Operation Optimization**

ERC-721A is an improved ERC-721 implementation by Azuki that dramatically reduces gas costs for batch minting NFTs. Instead of updating storage for every token during batch mints, it leverages clever optimizations.

**CONNECTION TO PROJECT 09**:
- **Project 09**: Standard ERC721 implementation (one token = one storage write)
- **Project 25**: ERC721A optimization (batch tokens = one storage write!)
- Both implement the same standard, but ERC721A is optimized for batch operations!

### Key Innovations

**UNDERSTANDING THE OPTIMIZATIONS**:

1. **Batch Minting Optimization**: Mint multiple tokens for the same gas as minting one
   - Standard ERC721: Each token = separate storage write (~20k gas)
   - ERC721A: Entire batch = single storage write (~20k gas)
   - Savings: ~20k gas per additional token!

2. **Sequential Token IDs**: Tokens are minted sequentially starting from 0
   - Enables ownership inference (don't need to store each token's owner)
   - From Project 01: Sequential IDs enable efficient algorithms

3. **Ownership Inference**: Owner lookups scan backwards to find the batch owner
   - Instead of storing owner for each token, scan to find batch start
   - Trade-off: Slightly more expensive reads, massively cheaper writes

4. **Storage Packing** (from Project 01 knowledge): Multiple values packed into single storage slots
   - Pack ownership data into single slot
   - Saves storage slots (and gas!)

5. **Minimal Storage Updates**: Only update storage once per batch, not per token
   - Standard: 5 tokens = 5 storage writes (~100k gas)
   - ERC721A: 5 tokens = 1 storage write (~20k gas)
   - Savings: 80% reduction!

**COMPARISON TO STANDARD ERC721** (from Project 09):

**Standard ERC721**:
```solidity
// Minting 5 tokens
for (uint i = 0; i < 5; i++) {
    _owners[tokenId + i] = owner;  // 5 storage writes
    _balances[owner]++;             // 5 balance updates
}
// Total: ~100,000 gas (5 × 20k gas)
```

**ERC721A**:
```solidity
// Minting 5 tokens
_owners[tokenId] = owner;           // 1 storage write (first token)
// Other tokens inferred from sequential IDs!
// Total: ~20,000 gas (1 × 20k gas)
// Savings: 80%!
```

**REAL-WORLD ANALOGY**: 
Like printing a book:
- **Standard ERC721**: Print each page separately (expensive!)
- **ERC721A**: Print entire book at once (cheap!)

## Gas Savings Analysis

### Standard ERC-721 Batch Minting

```solidity
// Minting 5 tokens with standard ERC-721
Token 1: ~150,000 gas (SSTORE from 0 to non-zero)
Token 2: ~150,000 gas
Token 3: ~150,000 gas
Token 4: ~150,000 gas
Token 5: ~150,000 gas
Total:   ~750,000 gas
```

### ERC-721A Batch Minting

```solidity
// Minting 5 tokens with ERC-721A
Batch of 5: ~160,000 gas (single storage update + batch logic)
Total:      ~160,000 gas
Savings:    ~590,000 gas (79% reduction!)
```

### Gas Comparison Table

| Tokens Minted | Standard ERC-721 | ERC-721A | Savings | % Saved |
|---------------|------------------|----------|---------|---------|
| 1             | ~150,000         | ~160,000 | -10,000 | -6.7%   |
| 2             | ~300,000         | ~165,000 | ~135,000| 45%     |
| 5             | ~750,000         | ~175,000 | ~575,000| 77%     |
| 10            | ~1,500,000       | ~190,000 | ~1,310,000| 87%   |
| 20            | ~3,000,000       | ~210,000 | ~2,790,000| 93%   |
| 50            | ~7,500,000       | ~250,000 | ~7,250,000| 97%   |

**Note**: ERC-721A is slightly more expensive for single mints but massively cheaper for batches.

## Storage Layout Optimization

### Standard ERC-721 Storage

```
// Each token requires separate storage slots
mapping(uint256 => address) private _owners;      // 1 slot per token
mapping(uint256 => address) private _tokenApprovals; // 1 slot per token
mapping(address => uint256) private _balances;     // 1 slot per owner

// Minting 5 tokens = 5 SSTORE operations for _owners + balance updates
```

### ERC-721A Storage Packing

```
// TokenOwnership struct packed into single slot (256 bits)
struct TokenOwnership {
    address addr;           // 160 bits - owner address
    uint64 startTimestamp;  // 64 bits  - when owned
    bool burned;            // 8 bits   - burn status
    // 24 bits unused
}

// Only store ownership for batch start
mapping(uint256 => TokenOwnership) private _ownerships;

// Minting 5 tokens = 1 SSTORE operation + balance update
```

### Storage Diagram

```
Standard ERC-721:
Token 0: [owner0] [approval0]
Token 1: [owner1] [approval1]
Token 2: [owner2] [approval2]
Token 3: [owner3] [approval3]
Token 4: [owner4] [approval4]
= 10 storage slots

ERC-721A (batch mint to same owner):
Token 0: [owner|timestamp|burned]
Token 1: []  ← inferred from token 0
Token 2: []  ← inferred from token 0
Token 3: []  ← inferred from token 0
Token 4: []  ← inferred from token 0
= 1 storage slot!
```

## Sequential Token IDs

ERC-721A enforces sequential token IDs starting from 0 (or _startTokenId()).

```solidity
// First mint: tokens 0-4
_mint(alice, 5);

// Second mint: tokens 5-9 (sequential)
_mint(bob, 5);

// Cannot mint arbitrary token IDs
// This pattern doesn't exist in ERC-721A
```

### Benefits

1. **Predictability**: Users know their token IDs
2. **Enumeration**: Easy to iterate through all tokens
3. **Optimization**: Sequential IDs enable ownership inference

### Limitations

1. **No Arbitrary IDs**: Can't mint specific token numbers
2. **No Gaps**: Can't skip token IDs
3. **Sequential Only**: Mints must be in order

## Ownership Inference

The core optimization: how ERC-721A finds owners without storing every mapping.

### Algorithm

```solidity
function ownerOf(uint256 tokenId) public view returns (address) {
    // Start at the requested token
    uint256 curr = tokenId;

    // Scan backwards until we find explicit ownership
    while (curr >= 0) {
        TokenOwnership memory ownership = _ownerships[curr];

        if (ownership.addr != address(0)) {
            // Found the batch owner!
            return ownership.addr;
        }

        curr--;
    }

    revert("Token doesn't exist");
}
```

### Example

```solidity
// Mint 5 tokens to Alice (IDs 0-4)
_mint(alice, 5);
// Storage: _ownerships[0] = {addr: alice, ...}

// Query ownership
ownerOf(0); // Finds _ownerships[0].addr = alice
ownerOf(3); // Scans: 3→2→1→0, finds alice
ownerOf(4); // Scans: 4→3→2→1→0, finds alice

// Transfer token 2 to Bob
transferFrom(alice, bob, 2);
// Storage: _ownerships[2] = {addr: bob, ...}

// Query ownership after transfer
ownerOf(0); // Finds _ownerships[0].addr = alice
ownerOf(2); // Finds _ownerships[2].addr = bob
ownerOf(3); // Scans: 3→2, finds bob (!)

// Fix: Need to set ownership at 3 to alice
// ERC-721A handles this in _beforeTokenTransfers
```

### Transfer Considerations

When transferring a token from a batch, ERC-721A must:
1. Set ownership for the transferred token to new owner
2. Set ownership for next token (if exists in batch) to previous owner
3. Update balance tracking

This makes transfers slightly more expensive but keeps minting cheap.

## When to Use ERC-721A

### Perfect Use Cases

1. **Public Mints**: Users mint multiple NFTs in one transaction
2. **Airdrops**: Project mints many tokens to various addresses
3. **Batch Distributions**: Pre-minting collections
4. **Sequential Collections**: Art series, generative collections
5. **High Volume Mints**: Thousands of tokens

### Not Ideal For

1. **Single Mint Only**: If users only mint 1, standard ERC-721 is cheaper
2. **Non-Sequential IDs**: If you need specific token numbers
3. **Sparse Collections**: If token IDs have gaps
4. **Low Supply**: Less than 100 tokens (optimization not worth complexity)

### Gas Break-Even Point

- **Break-even**: Minting 2+ tokens per transaction
- **Optimal**: Minting 5+ tokens per transaction
- **Maximum savings**: Batch mints of 20+ tokens

## Implementation Details

### Required Functions

```solidity
// Core minting
function _mint(address to, uint256 quantity) internal

// Batch-aware transfers
function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
) internal virtual

// Ownership lookup with inference
function ownerOf(uint256 tokenId) public view returns (address)

// Efficient balance tracking
function balanceOf(address owner) public view returns (uint256)
```

### Key Optimizations

1. **currentIndex**: Tracks next token ID to mint
2. **_addressData**: Packs balance and mint count per address
3. **Ownership Slots**: Only set at batch boundaries
4. **Aux Data**: 64 bits of custom data per address

## Common Pitfalls

### 1. Ownership Inference Bugs

```solidity
// ❌ Wrong: Transfer without updating adjacent ownership
function transfer(address to, uint256 tokenId) {
    _ownerships[tokenId].addr = to; // Missing next token update!
}

// ✅ Correct: ERC-721A handles this
_beforeTokenTransfers(from, to, tokenId, 1);
```

### 2. Balance Tracking

```solidity
// ❌ Wrong: Manual balance update
_balances[to] += 1;

// ✅ Correct: Use _addressData
_addressData[to].balance += 1;
```

### 3. Token Existence Checks

```solidity
// ❌ Wrong: Checking _ownerships directly
require(_ownerships[tokenId].addr != address(0));

// ✅ Correct: Check against currentIndex
require(tokenId < _currentIndex);
```

## Testing Strategy

### Gas Benchmarks

```solidity
function testGasMintSingle() public {
    uint256 gasBefore = gasleft();
    nft.mint(1);
    uint256 gasUsed = gasBefore - gasleft();
    console.log("Single mint gas:", gasUsed);
}

function testGasMintBatch5() public {
    uint256 gasBefore = gasleft();
    nft.mint(5);
    uint256 gasUsed = gasBefore - gasleft();
    console.log("Batch 5 mint gas:", gasUsed);
}
```

### Ownership Tests

```solidity
function testOwnershipInference() public {
    nft.mint(alice, 5);

    // All tokens should belong to alice
    assertEq(nft.ownerOf(0), alice);
    assertEq(nft.ownerOf(4), alice);

    // Transfer middle token
    nft.transferFrom(alice, bob, 2);

    // Check ownership after transfer
    assertEq(nft.ownerOf(0), alice); // Before transfer
    assertEq(nft.ownerOf(2), bob);   // Transferred
    assertEq(nft.ownerOf(3), alice); // After transfer (updated)
}
```

## Real-World Example: Azuki

Azuki used ERC-721A for their 10,000 NFT collection:

```solidity
// Public mint: Users could mint up to 5 NFTs
Minting 1 NFT:  ~160,000 gas
Minting 5 NFTs: ~175,000 gas (only 15k more!)

// Savings for users who minted 5:
Standard ERC-721: ~750,000 gas
ERC-721A:        ~175,000 gas
User saved:      ~575,000 gas (~76% reduction)
```

At 50 gwei and $2000 ETH:
- Standard: ~$75 in gas
- ERC-721A: ~$17.50 in gas
- **User saved: $57.50 per transaction**

## Project Structure

```
25-erc721a-optimized/
├── src/
│   ├── Project25.sol              # Skeleton implementation
│   └── solution/
│       └── Project25Solution.sol  # Complete solution
├── test/
│   └── Project25.t.sol           # Gas comparison tests
├── script/
│   └── DeployProject25.s.sol     # Deployment script
└── README.md                      # This file
```

## Tasks

### Part 1: Basic ERC-721A Implementation
1. Import ERC-721A from a library or implement core functions
2. Add basic minting function
3. Implement ownership tracking
4. Test single vs batch minting

### Part 2: Gas Optimization Analysis
1. Create gas benchmark tests
2. Compare with standard ERC-721
3. Measure different batch sizes
4. Document gas savings

### Part 3: Advanced Features
1. Add max supply limits
2. Implement mint price
3. Add owner-only batch minting
4. Create metadata URI functions

### Part 4: Transfer Optimization
1. Test transfer gas costs
2. Verify ownership updates
3. Test edge cases (first/last in batch)
4. Benchmark transfer costs

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/ERC721AOptimizedSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployERC721AOptimizedSolution.s.sol` - Deployment script patterns
- `test/solution/ERC721AOptimizedSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains storage packing, ownership inference, batch operations
- **Connections to Project 09**: Standard ERC721 (this optimizes it)
- **Connections to Project 01**: Storage packing for gas optimization
- **Connections to Project 06**: Batch operations pattern
- **Real-World Context**: 77% gas savings vs standard ERC721 - used by Azuki and major NFT collections

## Running the Project

```bash
# Install dependencies (if using Chiru Labs ERC-721A)
forge install chiru-labs/ERC721A

# Run tests
forge test --match-path test/Project25.t.sol -vv

# Run with gas reporting
forge test --match-path test/Project25.t.sol --gas-report

# Run specific gas test
forge test --match-test testGasBatchMint -vvv

# Deploy
forge script script/DeployProject25.s.sol:DeployProject25 --rpc-url <RPC_URL> --broadcast
```

## Expected Gas Results

When you complete this project, you should see:

```
Minting 1 token:  ~160,000 gas
Minting 2 tokens: ~165,000 gas  (82.5k per token)
Minting 5 tokens: ~175,000 gas  (35k per token)
Minting 10 tokens: ~190,000 gas (19k per token)
Minting 20 tokens: ~210,000 gas (10.5k per token)

Transfer (from batch): ~80,000 gas
Transfer (individual): ~50,000 gas
```

## Additional Resources

- [ERC-721A Documentation](https://chiru-labs.github.io/ERC721A/)
- [Azuki ERC-721A GitHub](https://github.com/chiru-labs/ERC721A)
- [Gas Optimization Article](https://www.azuki.com/erc721a)
- [OpenZeppelin ERC-721](https://docs.openzeppelin.com/contracts/4.x/erc721)

## Key Takeaways

1. **Batch minting** is where ERC-721A shines (77-97% gas savings)
2. **Sequential IDs** enable ownership inference optimization
3. **Storage packing** reduces state updates dramatically
4. **Transfers** are slightly more expensive to maintain optimization
5. **Use ERC-721A** when users mint multiple tokens or you batch mint
6. **Avoid ERC-721A** for single-mint-only scenarios

## Security Considerations

1. **Start Token ID**: Ensure _startTokenId() is set correctly
2. **Max Supply**: Always enforce max supply checks
3. **Ownership Gaps**: Properly handle ownership chains on transfers
4. **Balance Tracking**: Never manually update balances
5. **Reentrancy**: Protect mint functions from reentrancy
6. **Integer Overflow**: Use Solidity 0.8+ for overflow protection

Ready to optimize your NFT gas costs? Let's build!

---


## 26-erc1155-multi

# Project 26: ERC-1155 Multi-Token Standard

## Overview

The ERC-1155 Multi-Token Standard is a revolutionary token standard that allows a single contract to manage multiple token types, both fungible and non-fungible. This project teaches you how to implement and work with ERC-1155 tokens, which are particularly popular in gaming and multi-asset systems.

## What is ERC-1155? The Multi-Token Standard

**FIRST PRINCIPLES: Unified Token Interface**

ERC-1155 is a token standard that supports multiple token types in a single contract. It combines the best of ERC20 and ERC721!

**CONNECTION TO PROJECTS 08 & 09**:
- **Project 08**: ERC20 - fungible tokens (all identical)
- **Project 09**: ERC721 - non-fungible tokens (each unique)
- **Project 26**: ERC1155 - both in one contract!

ERC-1155 is a token standard that supports:
- **Fungible tokens** (like ERC-20): Interchangeable tokens of the same type
  - Example: Gold coins, silver coins (many units, all identical)
  
- **Non-fungible tokens** (like ERC-721): Unique tokens with individual identities
  - Example: Unique sword, unique armor (one unit, unique properties)
  
- **Semi-fungible tokens**: Tokens that start fungible but become unique
  - Example: Ticket that becomes unique after event (fungible → NFT)

All of these can exist in a single smart contract, making it extremely versatile and gas-efficient!

**UNDERSTANDING THE UNIFIED MODEL**:

```
ERC-1155 Unified Model:
┌─────────────────────────────────────────┐
│ Single Contract                         │
│   ↓                                      │
│ Token ID 0: Gold (fungible)            │ ← Like ERC20
│   - balanceOf(user, 0) = 1000           │ ← Can have many
│   ↓                                      │
│ Token ID 1: Silver (fungible)           │ ← Like ERC20
│   - balanceOf(user, 1) = 500            │ ← Can have many
│   ↓                                      │
│ Token ID 1000: Unique Sword (NFT)       │ ← Like ERC721
│   - balanceOf(user, 1000) = 1           │ ← Only one exists
│   ↓                                      │
│ Token ID 1001: Unique Armor (NFT)      │ ← Like ERC721
│   - balanceOf(user, 1001) = 1           │ ← Only one exists
└─────────────────────────────────────────┘
```

**STORAGE STRUCTURE** (from Project 01 knowledge):

**ERC20** (Project 08):
```solidity
mapping(address => uint256) public balanceOf;  // One mapping per contract
```

**ERC721** (Project 09):
```solidity
mapping(uint256 => address) public ownerOf;    // One mapping per contract
mapping(address => uint256) public balanceOf;
```

**ERC1155** (Project 26):
```solidity
mapping(uint256 => mapping(address => uint256)) public balanceOf;
// Nested mapping: tokenId → owner → balance
// One contract, multiple token types!
```

**GAS EFFICIENCY** (from Project 01 & 06 knowledge):

**Deploying Multiple Token Types**:

**Separate Contracts** (ERC20 + ERC721):
- Deploy ERC20: ~200,000 gas
- Deploy ERC721: ~200,000 gas
- Total: ~400,000 gas

**Single ERC1155 Contract**:
- Deploy ERC1155: ~200,000 gas
- Total: ~200,000 gas
- **Savings**: 50% reduction!

**REAL-WORLD ANALOGY**: 
Like a video game inventory:
- **ERC20**: Separate contracts for gold, silver, etc. (inefficient)
- **ERC721**: Separate contracts for each unique item (very inefficient)
- **ERC1155**: One inventory contract for everything (efficient!)

## Key Advantages of ERC-1155

### 1. Gas Efficiency
- **Batch Operations**: Transfer multiple token types in a single transaction
- **Reduced Contract Deployments**: One contract for all token types vs. multiple ERC-20/721 contracts
- **Optimized Storage**: More efficient than deploying separate contracts

### 2. Simplified Management
- One contract manages hundreds or thousands of token types
- Unified interface for all token operations
- Single approval for all token types (operator approval)

### 3. Atomic Swaps
- Trade multiple assets in a single transaction
- No need for complex multi-step exchanges
- Reduced risk of failed partial trades

## Core Concepts

### Token IDs and Fungibility

```solidity
// Fungible tokens (like currencies)
uint256 constant GOLD = 0;      // Many units, all identical
uint256 constant SILVER = 1;    // Many units, all identical

// Non-fungible tokens (like unique items)
uint256 constant SWORD_1 = 1000;  // Unique item
uint256 constant SWORD_2 = 1001;  // Different unique item

// Convention: Check balance
// If balance can be > 1, it's fungible
// If balance is always 0 or 1, it's non-fungible
```

**How to distinguish:**
- **Fungible**: Multiple users can own the same token ID with different amounts
- **Non-fungible**: Only one user owns each token ID, and the amount is always 1

### Balance Model

Unlike ERC-721, ERC-1155 uses a nested mapping:

```solidity
// ERC-1155: mapping(tokenId => mapping(owner => balance))
mapping(uint256 => mapping(address => uint256)) private _balances;

// This allows:
// - Multiple people to own token ID 0 (fungible)
// - Only one person to own token ID 1000 (NFT)
```

### Batch Operations

One of the most powerful features:

```solidity
// Transfer multiple token types at once
function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
) public;

// Example: Transfer gold, silver, and a sword in one transaction
ids = [0, 1, 1000];
amounts = [100, 50, 1];
```

**Benefits:**
- Save gas on multiple transfers
- Atomic execution (all succeed or all fail)
- Useful for trading, crafting, or bulk distributions

### Operator Approval

ERC-1155 uses operator approval instead of per-token approval:

```solidity
// One approval for ALL token types
function setApprovalForAll(address operator, bool approved) public;

// The operator can then transfer ANY token ID on your behalf
```

**Key differences from ERC-721:**
- ERC-721: Approve specific token ID
- ERC-1155: Approve all token IDs at once
- More convenient but requires more trust in operators

### Safe Transfer Callbacks

All transfers must be "safe" - they call a hook on the recipient:

```solidity
interface IERC1155Receiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}
```

**Purpose:**
- Prevent tokens from being locked in contracts that can't handle them
- Allow recipient contracts to execute logic on receipt
- Reentrancy protection required!

### URI Management

ERC-1155 uses a single URI template for all tokens:

```solidity
// Template with {id} placeholder
string private _uri = "https://game.com/api/item/{id}.json";

// For token ID 42, becomes:
// "https://game.com/api/item/42.json"
```

**Alternative approaches:**
- Per-token URI overrides
- On-chain metadata generation
- IPFS base URI with token-specific hashes

## ERC-1155 vs ERC-20 + ERC-721

### Gas Comparison

| Operation | ERC-20 + ERC-721 | ERC-1155 | Savings |
|-----------|------------------|----------|---------|
| Deploy 10 token types | ~15M gas | ~1.5M gas | **90%** |
| Transfer 5 different tokens | ~250k gas | ~120k gas | **52%** |
| Approve all types | 5 txs * 46k | 1 tx * 46k | **80%** |

### Feature Comparison

| Feature | ERC-20 | ERC-721 | ERC-1155 |
|---------|--------|---------|----------|
| Fungible tokens | ✅ | ❌ | ✅ |
| Non-fungible tokens | ❌ | ✅ | ✅ |
| Batch transfers | ❌ | ❌ | ✅ |
| Multiple types/contract | ❌ | ❌ | ✅ |
| Per-token approval | N/A | ✅ | ❌ |
| Operator approval | ✅ | ✅ | ✅ |

## Use Cases

### 1. Gaming (Most Common)

```solidity
// Currencies (fungible)
uint256 constant GOLD = 0;
uint256 constant GEMS = 1;

// Consumables (fungible)
uint256 constant HEALTH_POTION = 100;
uint256 constant MANA_POTION = 101;

// Equipment (non-fungible)
uint256 constant LEGENDARY_SWORD_1 = 10000;
uint256 constant LEGENDARY_SWORD_2 = 10001;

// Resources (fungible)
uint256 constant WOOD = 200;
uint256 constant IRON = 201;
```

### 2. Digital Art Collections

- Edition prints (fungible): 100 copies of the same artwork
- Unique pieces (non-fungible): 1/1 artworks
- Unlockable content tied to ownership

### 3. Real Estate Tokenization

- Fungible shares of a property
- Unique property deeds
- Rental income tokens

### 4. Supply Chain

- Fungible commodity units
- Non-fungible tracking IDs for unique items
- Certificates of authenticity

### 5. DeFi Positions

- Liquidity pool shares (fungible)
- Unique loan positions (non-fungible)
- Reward tokens

## Common Patterns and Best Practices

### 1. Token ID Organization

```solidity
// Use ranges to organize token types
uint256 constant CURRENCY_RANGE = 0;        // 0-999
uint256 constant CONSUMABLE_RANGE = 1000;   // 1000-1999
uint256 constant EQUIPMENT_RANGE = 10000;   // 10000-99999

// Helper functions
function isCurrency(uint256 tokenId) internal pure returns (bool) {
    return tokenId < 1000;
}

function isEquipment(uint256 tokenId) internal pure returns (bool) {
    return tokenId >= 10000 && tokenId < 100000;
}
```

### 2. Supply Tracking

```solidity
// Track total supply per token ID
mapping(uint256 => uint256) private _totalSupply;

// For NFTs, limit to 1
function mintNFT(address to, uint256 tokenId) public {
    require(_totalSupply[tokenId] == 0, "NFT already exists");
    _totalSupply[tokenId] = 1;
    _mint(to, tokenId, 1, "");
}

// For fungible, track aggregate
function mintFungible(address to, uint256 tokenId, uint256 amount) public {
    _totalSupply[tokenId] += amount;
    _mint(to, tokenId, amount, "");
}
```

### 3. Role-Based Minting

```solidity
// Different roles for different token types
bytes32 public constant CURRENCY_MINTER = keccak256("CURRENCY_MINTER");
bytes32 public constant ITEM_MINTER = keccak256("ITEM_MINTER");

function mintCurrency(address to, uint256 id, uint256 amount) public {
    require(hasRole(CURRENCY_MINTER, msg.sender), "Not authorized");
    require(id < 1000, "Not a currency");
    _mint(to, id, amount, "");
}
```

### 4. Reentrancy Protection

```solidity
// ALWAYS use reentrancy guard with safe transfers
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MyERC1155 is ERC1155, ReentrancyGuard {
    function safeTransferFrom(...) public override nonReentrant {
        super.safeTransferFrom(...);
    }
}
```

### 5. URI Management

```solidity
// Option 1: Template URI (most common)
constructor() ERC1155("https://game.com/api/item/{id}.json") {}

// Option 2: Per-token URI
mapping(uint256 => string) private _tokenURIs;

function uri(uint256 tokenId) public view override returns (string memory) {
    string memory tokenURI = _tokenURIs[tokenId];
    if (bytes(tokenURI).length > 0) {
        return tokenURI;
    }
    return super.uri(tokenId);
}

// Option 3: On-chain metadata
function uri(uint256 tokenId) public view override returns (string memory) {
    return string(abi.encodePacked(
        'data:application/json;base64,',
        Base64.encode(bytes(generateMetadata(tokenId)))
    ));
}
```

## Security Considerations

### 1. Reentrancy in Callbacks

The safe transfer callbacks can lead to reentrancy:

```solidity
// Malicious receiver
contract Attacker is IERC1155Receiver {
    function onERC1155Received(...) external returns (bytes4) {
        // Reenter the token contract!
        token.safeTransferFrom(victim, attacker, id, amount, "");
        return this.onERC1155Received.selector;
    }
}
```

**Protection:**
- Use `ReentrancyGuard` from OpenZeppelin
- Follow checks-effects-interactions pattern
- Update balances before calling hooks

### 2. Operator Approval Trust

Operators have full control over all token types:

```solidity
// If you approve a malicious operator...
token.setApprovalForAll(maliciousOperator, true);

// They can drain ALL your tokens of ALL types!
token.safeBatchTransferFrom(you, attacker, allIds, allAmounts, "");
```

**Best practices:**
- Only approve trusted contracts
- Provide clear UI warnings
- Consider time-limited approvals
- Implement revokable approvals

### 3. Balance Overflow

Unlike ERC-721, balances can overflow:

```solidity
// In Solidity < 0.8.0, this could overflow
balances[id][to] += amount;
```

**Protection:**
- Use Solidity ^0.8.0 (automatic overflow checks)
- Or use SafeMath library

### 4. URI Validation

Malicious URIs could be used for phishing:

```solidity
// Bad: Allowing arbitrary URIs
function setURI(string memory newuri) public {
    _setURI(newuri);
}

// Better: Validate URI format
function setURI(string memory newuri) public onlyOwner {
    require(bytes(newuri).length > 0, "Empty URI");
    require(validateURI(newuri), "Invalid URI format");
    _setURI(newuri);
}
```

## Testing Strategy

### Essential Tests

1. **Basic Operations**
   - Mint fungible tokens
   - Mint non-fungible tokens
   - Single transfers
   - Balance queries

2. **Batch Operations**
   - Batch minting
   - Batch transfers
   - Mixed fungible/NFT batches

3. **Approvals**
   - Operator approval
   - Operator transfers
   - Approval revocation

4. **Safe Transfer Callbacks**
   - Transfer to EOA (should succeed)
   - Transfer to contract with receiver (should succeed)
   - Transfer to contract without receiver (should fail)
   - Reentrancy protection

5. **Edge Cases**
   - Zero amount transfers
   - Self-transfers
   - Transfer to zero address
   - Insufficient balance
   - Unauthorized transfers

6. **Gas Optimization**
   - Compare batch vs individual transfers
   - Compare with ERC-20 + ERC-721
   - Measure deployment costs

## Project Structure

```
26-erc1155-multi/
├── src/
│   ├── Project26.sol              # Skeleton for students
│   └── solution/
│       └── Project26Solution.sol  # Complete implementation
├── test/
│   └── Project26.t.sol            # Comprehensive tests
├── script/
│   └── DeployProject26.s.sol      # Deployment script
└── README.md                       # This file
```

## Learning Objectives

By completing this project, you will:

1. ✅ Understand ERC-1155 standard and its advantages
2. ✅ Implement both fungible and non-fungible tokens in one contract
3. ✅ Master batch operations for gas efficiency
4. ✅ Handle operator approvals correctly
5. ✅ Implement safe transfer callbacks
6. ✅ Protect against reentrancy attacks
7. ✅ Design token ID schemes for different use cases
8. ✅ Compare gas costs with ERC-20/721
9. ✅ Build a complete gaming item system

## Tasks

### Part 1: Basic Implementation (Skeleton)

1. Implement ERC1155 base functionality
2. Add token minting functions
3. Implement URI management
4. Add access control

### Part 2: Advanced Features (Solution)

1. Implement batch operations efficiently
2. Add safe transfer callback handling
3. Implement reentrancy protection
4. Create gaming item system example

### Part 3: Testing

1. Write tests for all operations
2. Test reentrancy protection
3. Compare gas costs
4. Test edge cases

## Resources

- [EIP-1155 Specification](https://eips.ethereum.org/EIPS/eip-1155)
- [OpenZeppelin ERC1155](https://docs.openzeppelin.com/contracts/4.x/erc1155)
- [ERC-1155 vs ERC-721](https://ethereum.org/en/developers/docs/standards/tokens/erc-1155/)
- [Enjin's ERC-1155 Guide](https://github.com/enjin/erc-1155)

## Common Pitfalls

1. ❌ Not implementing reentrancy guards
2. ❌ Confusing fungible and non-fungible token handling
3. ❌ Forgetting to check receiver interface support
4. ❌ Not validating array lengths in batch operations
5. ❌ Allowing operator approval without user awareness
6. ❌ Poor URI management for metadata
7. ❌ Not tracking total supply correctly

## Next Steps

After completing this project:
- Explore ERC-1155 extensions (supply tracking, burnable, etc.)
- Build a complete NFT game using ERC-1155
- Integrate with marketplaces that support ERC-1155
- Implement meta-transactions for gasless transfers
- Study advanced patterns like semi-fungible tokens

## Getting Started

1. Read through the skeleton contract (`src/Project26.sol`)
2. Complete the TODOs in order
3. Run tests: `forge test --match-path test/Project26.t.sol`
4. Compare with solution when stuck

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/ERC1155MultiTokenSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployERC1155MultiTokenSolution.s.sol` - Deployment script patterns
- `test/solution/ERC1155MultiTokenSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains batch operations, multi-token accounting, efficient storage patterns
- **Connections to Projects 08 & 09**: Combines ERC20 (fungible) and ERC721 (non-fungible) concepts
- **Real-World Context**: Used in gaming, marketplaces, and multi-asset systems

5. Deploy locally: `forge script script/DeployProject26.s.sol`

Happy coding! 🎮

---


## 27-soulbound-tokens

# Project 27: Soulbound Tokens (SBTs)

Learn how to implement non-transferable NFTs for identity, credentials, and achievements.

## Table of Contents
- [Overview](#overview)
- [What are Soulbound Tokens?](#what-are-soulbound-tokens)
- [Use Cases](#use-cases)
- [EIP-5192: Minimal Soulbound NFTs](#eip-5192-minimal-soulbound-nfts)
- [Implementation Patterns](#implementation-patterns)
- [Security Considerations](#security-considerations)
- [Privacy Considerations](#privacy-considerations)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Testing](#testing)

## Overview

Soulbound Tokens (SBTs) are non-transferable NFTs that are permanently bound to a specific address. They represent achievements, credentials, reputation, or identity that shouldn't be sold or transferred.

**What You'll Learn:**
- How to prevent token transfers while maintaining ERC721 compatibility
- Different SBT patterns (permanent, revocable, recoverable)
- EIP-5192 standard implementation
- Revocation and recovery mechanisms
- Privacy-preserving techniques for SBTs

**Difficulty:** Advanced

## What are Soulbound Tokens? Non-Transferable Identity

**FIRST PRINCIPLES: Identity vs Property**

Soulbound Tokens are inspired by "soulbound items" in video games - items that become permanently bound to a player and cannot be traded or sold. In Web3, SBTs represent identity and credentials, not transferable property.

**CONNECTION TO PROJECT 09**:
- **Project 09**: ERC721 - transferable NFTs (property)
- **Project 27**: Soulbound Tokens - non-transferable NFTs (identity)
- Same standard (ERC721), different transfer behavior!

Soulbound Tokens serve as:

- **Non-transferable credentials**: Educational degrees, certifications
  - Example: University degree NFT (can't sell your degree!)
  
- **Reputation systems**: On-chain reputation that follows your identity
  - Example: DeFi credit score (personal, not transferable)
  
- **Achievement badges**: Proof of participation or accomplishment
  - Example: POAPs (Proof of Attendance Protocol)
  
- **Identity attestations**: KYC/AML compliance, proof of humanity
  - Example: Verified identity badge
  
- **Membership proofs**: DAO membership, community participation
  - Example: DAO member NFT (proves membership, can't transfer)

### Key Characteristics

**UNDERSTANDING THE RESTRICTIONS**:

1. **Non-transferable**: Cannot be sent to another address
   ```solidity
   // Override transfer functions to revert
   function transferFrom(...) public override {
       revert("Soulbound: non-transferable");
   }
   ```

2. **Revocable (optional)**: Issuer may revoke under certain conditions
   - Example: Degree revoked due to fraud
   - Example: Certification expired

3. **Recoverable (optional)**: Can be recovered if wallet is compromised
   - Example: Lost private key recovery mechanism
   - Trade-off: Security vs permanence

4. **Publicly verifiable**: Anyone can verify credentials on-chain
   - Example: Employer can verify degree on-chain
   - Transparency benefit

5. **Privacy-aware**: May use techniques to protect holder privacy
   - Example: Zero-knowledge proofs for private credentials
   - Balance: Verifiability vs privacy

**COMPARISON TO STANDARD ERC721** (from Project 09):

**Standard ERC721**:
```solidity
function transferFrom(address from, address to, uint256 tokenId) public {
    // Transfers token ✅
    // Can be sold, traded, gifted
}
```

**Soulbound Token**:
```solidity
function transferFrom(address from, address to, uint256 tokenId) public override {
    revert("Soulbound: non-transferable");  // ❌ Always reverts
    // Cannot be sold, traded, or gifted
    // Permanently bound to original owner
}
```

**REAL-WORLD ANALOGY**: 
Like a driver's license:
- **Standard NFT**: Can be transferred (like cash - can give it away)
- **Soulbound Token**: Cannot be transferred (like your license - tied to you)

## Use Cases

### 1. Educational Credentials
```solidity
// University issues degree SBTs
// - Non-transferable (you can't sell your degree)
// - Revocable (if fraud is discovered)
// - Non-recoverable (tied to your identity)
```

### 2. Professional Certifications
```solidity
// Professional bodies issue certification SBTs
// - Non-transferable
// - Revocable (if certification expires or is revoked)
// - May have expiration dates
```

### 3. Event Attendance (POAPs)
```solidity
// Proof of Attendance Protocols
// - Non-transferable
// - Non-revocable (you attended, period)
// - Collectible achievements
```

### 4. Reputation Systems
```solidity
// DeFi protocol credit scores
// - Non-transferable (reputation is personal)
// - Dynamic (updates based on behavior)
// - May be recoverable (if wallet compromised)
```

### 5. Identity & KYC
```solidity
// Know Your Customer compliance
// - Non-transferable
// - Revocable (if verification status changes)
// - Recoverable (allow wallet migration)
// - Privacy-preserving (zero-knowledge proofs)
```

### 6. DAO Membership
```solidity
// Membership tokens for DAOs
// - Non-transferable
// - Revocable (if member is removed)
// - May grant voting rights
```

## EIP-5192: Minimal Soulbound NFTs

[EIP-5192](https://eips.ethereum.org/EIPS/eip-5192) proposes a minimal standard for soulbound tokens:

### Interface

```solidity
interface IERC5192 {
    /// @notice Emitted when the locking status is changed to locked.
    /// @dev If a token is minted and the status is locked, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event Locked(uint256 tokenId);

    /// @notice Emitted when the locking status is changed to unlocked.
    /// @dev If a token is minted and the status is unlocked, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event Unlocked(uint256 tokenId);

    /// @notice Returns the locking status of an Soulbound Token
    /// @dev SBTs assigned to zero address are considered invalid, and queries
    /// about them do throw.
    /// @param tokenId The identifier for an SBT.
    function locked(uint256 tokenId) external view returns (bool);
}
```

### Key Points

- **`locked(uint256 tokenId)`**: Returns whether a token is locked (soulbound)
- **Events**: `Locked` and `Unlocked` events for status changes
- **Flexibility**: Tokens can be permanently or conditionally locked
- **Compatibility**: Works alongside ERC721

## Implementation Patterns

### Pattern 1: Permanently Soulbound

Tokens are **never** transferable after minting.

```solidity
contract PermanentSoulbound is ERC721 {
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal virtual override returns (address) {
        address from = _ownerOf(tokenId);

        // Allow minting (from == address(0))
        // Allow burning (to == address(0))
        // Reject all transfers
        if (from != address(0) && to != address(0)) {
            revert("Soulbound: Transfer not allowed");
        }

        return super._update(to, tokenId, auth);
    }
}
```

**Use Cases:**
- Educational degrees
- Attendance proofs
- Historical achievements

### Pattern 2: Revocable Soulbound

Issuer can revoke (burn) tokens under certain conditions.

```solidity
contract RevocableSoulbound is PermanentSoulbound {
    mapping(uint256 => address) public issuer;

    function revoke(uint256 tokenId) external {
        require(msg.sender == issuer[tokenId], "Not issuer");
        _burn(tokenId);
    }
}
```

**Use Cases:**
- Certifications with expiration
- Conditional credentials
- Reputation systems

### Pattern 3: Recoverable Soulbound

Allows recovery to a new address (e.g., if wallet is compromised).

```solidity
contract RecoverableSoulbound is RevocableSoulbound {
    function recover(uint256 tokenId, address newOwner) external {
        require(msg.sender == ownerOf(tokenId), "Not owner");
        require(newOwner != address(0), "Invalid address");

        // Special transfer allowed for recovery
        _transfer(msg.sender, newOwner, tokenId);
    }
}
```

**Use Cases:**
- Identity tokens
- High-value credentials
- Long-term reputation

### Pattern 4: Time-Locked Soulbound

Tokens become soulbound after a certain period.

```solidity
contract TimeLockedSoulbound is ERC721 {
    mapping(uint256 => uint256) public lockTime;
    uint256 public constant LOCK_DURATION = 30 days;

    function locked(uint256 tokenId) public view returns (bool) {
        return block.timestamp >= lockTime[tokenId];
    }

    function _update(...) internal virtual override returns (address) {
        if (locked(tokenId) && from != address(0) && to != address(0)) {
            revert("Soulbound: Token is locked");
        }
        return super._update(to, tokenId, auth);
    }
}
```

**Use Cases:**
- Vesting credentials
- Gradual commitment proofs
- Probationary memberships

### Pattern 5: Conditionally Soulbound

Tokens are soulbound based on certain conditions.

```solidity
contract ConditionalSoulbound is ERC721 {
    mapping(uint256 => bool) public isSoulbound;

    function makeNonTransferable(uint256 tokenId) external {
        require(msg.sender == ownerOf(tokenId), "Not owner");
        isSoulbound[tokenId] = true;
        emit Locked(tokenId);
    }
}
```

**Use Cases:**
- Optional permanence
- User choice in credential binding
- Hybrid systems

## Security Considerations

### 1. Transfer Prevention

**Challenge**: Must block all transfer methods while allowing mint/burn.

```solidity
// Override all transfer functions
function _update(address to, uint256 tokenId, address auth)
    internal virtual override returns (address)
{
    // Check transfer conditions
}

// Also consider: safeTransferFrom, transferFrom, approve, setApprovalForAll
```

### 2. Revocation Authority

**Challenge**: Who can revoke and under what conditions?

```solidity
// Options:
// 1. Only issuer
// 2. Multi-sig governance
// 3. Holder + issuer (mutual consent)
// 4. On-chain conditions (e.g., expiration)

// Best Practice: Emit events for transparency
event Revoked(uint256 indexed tokenId, address indexed holder, string reason);
```

### 3. Recovery Mechanism

**Challenge**: Prevent abuse while allowing legitimate recovery.

```solidity
// Security measures:
// 1. Time delays
// 2. Multi-signature approval
// 3. Social recovery (guardians)
// 4. On-chain proof requirements

// Example: Time-delayed recovery
mapping(uint256 => RecoveryRequest) public recoveryRequests;

struct RecoveryRequest {
    address newOwner;
    uint256 requestTime;
}

function initiateRecovery(uint256 tokenId, address newOwner) external {
    require(msg.sender == ownerOf(tokenId), "Not owner");
    recoveryRequests[tokenId] = RecoveryRequest(newOwner, block.timestamp);
}

function completeRecovery(uint256 tokenId) external {
    RecoveryRequest memory req = recoveryRequests[tokenId];
    require(block.timestamp >= req.requestTime + DELAY, "Too early");
    _transfer(ownerOf(tokenId), req.newOwner, tokenId);
}
```

### 4. Issuer Centralization

**Risk**: Single issuer has too much power.

**Mitigations:**
- Multi-sig issuers
- DAO governance for revocations
- Immutable credentials (no revocation)
- On-chain evidence requirements

### 5. Front-Running

**Risk**: MEV bots could front-run revocations or recoveries.

**Mitigations:**
- Time locks
- Commit-reveal schemes
- Private mempools (Flashbots)

## Privacy Considerations

### 1. Public Visibility

**Issue**: SBTs are publicly visible on-chain.

**Implications:**
- Anyone can see your credentials
- Can build profiles of individuals
- May reveal sensitive information

### 2. Selective Disclosure

**Solution**: Use zero-knowledge proofs.

```solidity
// Instead of storing credential on-chain:
// Store commitment: hash(credential + salt)

// Prove you have credential without revealing it:
function verifyCredential(
    bytes32 commitment,
    bytes calldata zkProof
) external view returns (bool);
```

### 3. Privacy-Preserving Patterns

**Pattern A: Merkle Tree Storage**
```solidity
// Store only merkle root of all credentials
// Prove membership without revealing which credential
bytes32 public credentialRoot;

function verify(
    bytes32 leaf,
    bytes32[] calldata proof
) external view returns (bool);
```

**Pattern B: Encrypted Metadata**
```solidity
// Store encrypted credential data
// Only holder can decrypt
mapping(uint256 => bytes) public encryptedMetadata;
```

**Pattern C: Separate Verification Contract**
```solidity
// SBT contract: Private, minimal info
// Verification contract: Public interface
// Verifiers query without seeing full credentials
```

### 4. Correlation Resistance

**Issue**: Multiple SBTs can be correlated to deanonymize users.

**Mitigations:**
- Use different addresses for different contexts
- Stealth addresses
- Zero-knowledge set membership proofs

## Project Structure

```
27-soulbound-tokens/
├── README.md
├── src/
│   ├── Project27.sol                 # Skeleton contract with TODOs
│   └── solution/
│       └── Project27Solution.sol     # Complete implementation
├── test/
│   └── Project27.t.sol              # Comprehensive test suite
└── script/
    └── DeployProject27.s.sol        # Deployment script
```

## Getting Started

### Step 1: Study the Skeleton

Open `src/Project27.sol` and read through the TODO comments.

### Step 2: Implement Core Features

1. **Permanent Soulbound**: Prevent all transfers
2. **Revocable Pattern**: Add issuer revocation
3. **Recoverable Pattern**: Implement recovery mechanism
4. **EIP-5192**: Add `locked()` function and events

### Step 3: Run Tests

```bash
forge test --match-path test/Project27.t.sol -vvv
```

### Step 4: Compare with Solution

Study `src/solution/SoulboundTokensSolution.sol` to see best practices.

**Solution File Features**:
- **CS Concepts**: Explains transfer prevention patterns, revocation mechanisms
- **Connections to Project 09**: ERC721 base with transfer restrictions
- **Real-World Context**: Used for credentials, achievements, identity tokens

## Testing

The test suite covers:

### Transfer Prevention
- Cannot transfer after minting
- Cannot use safeTransferFrom
- Cannot approve others
- Can still mint and burn

### Revocation
- Only issuer can revoke
- Revocation burns token
- Events emitted correctly
- Non-issuer cannot revoke

### Recovery
- Owner can initiate recovery
- Time delay enforced
- Recovery completes successfully
- Non-owner cannot initiate

### EIP-5192 Compliance
- `locked()` returns correct status
- Events emitted on mint
- Interface support detected

### Edge Cases
- Recovery to zero address blocked
- Recovery cancellation
- Multiple simultaneous recoveries
- Revocation during recovery period

## Key Takeaways

1. **SBTs are not just "locked" NFTs** - they represent a new primitive for identity and reputation
2. **Transfer prevention requires careful implementation** - must override all transfer paths
3. **Revocation and recovery are trade-offs** - more flexibility means more attack surface
4. **Privacy is critical** - consider what information you're revealing on-chain
5. **Standards matter** - EIP-5192 provides interoperability
6. **Use cases drive design** - permanent degree ≠ revocable certification ≠ recoverable identity

## Advanced Topics

### Multi-Token Soulbound (ERC1155)

```solidity
// Multiple non-transferable token types
contract SoulboundBadges is ERC1155 {
    // Achievement system with multiple badge types
}
```

### Composable SBTs

```solidity
// SBTs that grant access to other SBTs
// E.g., Bachelor's degree → Master's degree → PhD
```

### Reputation Scoring

```solidity
// Dynamic SBTs that update based on behavior
contract ReputationSBT {
    mapping(uint256 => uint256) public reputationScore;
}
```

### Cross-Chain SBTs

```solidity
// SBTs that exist on multiple chains
// Using LayerZero, Axelar, or other bridges
```

## Resources

- [EIP-5192: Minimal Soulbound NFTs](https://eips.ethereum.org/EIPS/eip-5192)
- [Vitalik's SBT Paper: "Decentralized Society"](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4105763)
- [OpenZeppelin ERC721 Documentation](https://docs.openzeppelin.com/contracts/4.x/erc721)
- [Privacy-Preserving Credentials](https://zkp.science/)

## License

MIT

---


## 28-erc2981-royalties

# Project 28: ERC-2981 Royalties

A comprehensive guide to implementing on-chain NFT royalties using the EIP-2981 standard.

## Learning Objectives

- Understand the EIP-2981 royalty standard
- Implement on-chain royalty information
- Calculate royalty fees correctly
- Manage global and per-token royalties
- Integrate with NFT marketplaces
- Handle royalty recipient updates
- Understand limitations and considerations

## What is EIP-2981? On-Chain Royalty Standard

**FIRST PRINCIPLES: Creator Compensation**

EIP-2981 is a standardized way to retrieve royalty payment information for Non-Fungible Tokens (NFTs). It allows NFT creators to receive ongoing royalties from secondary sales across different marketplaces.

**CONNECTION TO PROJECT 09**:
- **Project 09**: ERC721 NFT standard (ownership and transfers)
- **Project 28**: ERC2981 royalty standard (creator compensation)
- Both work together - NFTs can implement both standards!

### Key Features

**UNDERSTANDING THE STANDARD**:

1. **Standardized Interface**: All compliant contracts expose the same `royaltyInfo()` function
   - Marketplaces can query any NFT for royalty info
   - Consistent interface across all NFTs
   - From Project 03: Standard interfaces enable composability!

2. **Marketplace Agnostic**: Works with any marketplace that supports the standard
   - OpenSea, LooksRare, Blur all support EIP-2981
   - Creator gets royalties regardless of marketplace
   - Decentralized royalty enforcement

3. **Flexible Configuration**: Supports both global and per-token royalty settings
   - Global: Same royalty for all tokens
   - Per-token: Different royalty per NFT
   - From Project 01: Uses mappings for per-token storage!

4. **On-Chain Information**: Royalty data is stored directly on the blockchain
   - No off-chain dependencies
   - Verifiable and transparent
   - Permanent record

**HOW ROYALTIES WORK**:

```
Royalty Flow:
┌─────────────────────────────────────────┐
│ NFT listed for sale: 10 ETH            │
│   ↓                                      │
│ Marketplace queries royaltyInfo()      │ ← EIP-2981 call
│   ↓                                      │
│ Contract returns:                       │
│   receiver = creator address            │
│   royaltyAmount = 0.5 ETH (5%)         │
│   ↓                                      │
│ Marketplace splits payment:            │
│   - Seller: 9.5 ETH                    │
│   - Creator: 0.5 ETH (royalty)         │ ← Automatic!
│   ↓                                      │
│ Creator receives ongoing royalties      │ ← From all future sales!
└─────────────────────────────────────────┘
```

**GAS COST** (from Project 01 & 03 knowledge):
- `royaltyInfo()` call: ~100 gas (view function, free off-chain)
- Royalty calculation: ~10 gas (arithmetic)
- Total: ~110 gas (negligible!)

**REAL-WORLD ANALOGY**: 
Like artist royalties in music:
- **First Sale**: Artist gets full price
- **Secondary Sales**: Artist gets royalty percentage
- **Ongoing**: Every resale generates royalty
- **Standardized**: Same system works across all platforms

### The Standard Interface

```solidity
interface IERC2981 {
    /// @notice Called with the sale price to determine how much royalty
    ///         is owed and to whom.
    /// @param tokenId - the NFT asset queried for royalty information
    /// @param salePrice - the sale price of the NFT asset specified by tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for salePrice
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);
}
```

## How Royalties Work On-Chain

### Royalty Calculation

The `royaltyInfo()` function takes two parameters:
- `tokenId`: The specific NFT being sold
- `salePrice`: The price at which the NFT is being sold

It returns:
- `receiver`: The address that should receive the royalty
- `royaltyAmount`: The calculated royalty amount in the sale currency

### Fee Calculation Example

If a marketplace sells an NFT for 10 ETH with a 5% royalty:

```solidity
(address receiver, uint256 royaltyAmount) = nft.royaltyInfo(tokenId, 10 ether);
// receiver = 0x123... (creator's address)
// royaltyAmount = 0.5 ether (5% of 10 ETH)
```

### Basis Points System

Royalties are typically stored as basis points (1 basis point = 0.01%):
- 100 basis points = 1%
- 250 basis points = 2.5%
- 500 basis points = 5%
- 1000 basis points = 10%

Maximum recommended: 10,000 basis points (100%)

## Implementation Patterns

### 1. Global Royalties

Set a single royalty percentage for all tokens:

```solidity
// All tokens have the same royalty
_setDefaultRoyalty(receiver, feeNumerator); // e.g., feeNumerator = 500 (5%)
```

**Pros**:
- Simple to implement
- Lower gas costs
- Easy to manage

**Cons**:
- Less flexible
- Cannot customize per token

### 2. Per-Token Royalties

Set different royalties for each token:

```solidity
// Customize royalty per token
_setTokenRoyalty(tokenId, receiver, feeNumerator);
```

**Pros**:
- Highly flexible
- Different creators can have different rates
- Can support collaborative works

**Cons**:
- Higher gas costs
- More complex management
- Requires more storage

### 3. Hybrid Approach

Combine both methods:

```solidity
// Set default for most tokens
_setDefaultRoyalty(defaultReceiver, 500);

// Override for specific tokens
_setTokenRoyalty(specialTokenId, specialReceiver, 1000);
```

## Marketplace Integration

### How Marketplaces Use ERC-2981

1. **Check Support**: Verify the contract implements ERC-2981

```solidity
// Check via ERC165
bool supportsRoyalties = nft.supportsInterface(0x2a55205a); // ERC2981 interface ID
```

2. **Calculate Royalty**: Call `royaltyInfo()` with sale price

```solidity
(address royaltyReceiver, uint256 royaltyAmount) = nft.royaltyInfo(tokenId, salePrice);
```

3. **Process Payment**: Pay royalty to receiver, remainder to seller

```solidity
// Pay royalty
payable(royaltyReceiver).transfer(royaltyAmount);

// Pay seller
payable(seller).transfer(salePrice - royaltyAmount);
```

### Example Marketplace Integration

```solidity
contract SimpleMarketplace {
    function buyNFT(address nftContract, uint256 tokenId) external payable {
        uint256 salePrice = msg.value;

        // Check if NFT supports royalties
        bool supportsRoyalties = IERC165(nftContract).supportsInterface(0x2a55205a);

        if (supportsRoyalties) {
            // Get royalty info
            (address royaltyReceiver, uint256 royaltyAmount) =
                IERC2981(nftContract).royaltyInfo(tokenId, salePrice);

            // Pay royalty
            if (royaltyAmount > 0) {
                payable(royaltyReceiver).transfer(royaltyAmount);
                salePrice -= royaltyAmount;
            }
        }

        // Pay seller the remaining amount
        address seller = IERC721(nftContract).ownerOf(tokenId);
        payable(seller).transfer(salePrice);

        // Transfer NFT to buyer
        IERC721(nftContract).transferFrom(seller, msg.sender, tokenId);
    }
}
```

## Royalty Recipient Management

### Setting Royalty Recipients

```solidity
// Set default recipient for all tokens
function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
}

// Set recipient for specific token
function setTokenRoyalty(
    uint256 tokenId,
    address receiver,
    uint96 feeNumerator
) external onlyOwner {
    _setTokenRoyalty(tokenId, receiver, feeNumerator);
}
```

### Updating Royalties

Important considerations when updating royalties:

1. **Access Control**: Only authorized addresses should update royalties
2. **Maximum Caps**: Enforce maximum royalty percentages (typically 10%)
3. **Validation**: Ensure receiver addresses are valid
4. **Events**: Emit events when royalties are updated

```solidity
function updateRoyalty(address newReceiver, uint96 newFee) external onlyOwner {
    require(newFee <= 1000, "Royalty too high"); // Max 10%
    require(newReceiver != address(0), "Invalid receiver");

    _setDefaultRoyalty(newReceiver, newFee);

    emit RoyaltyUpdated(newReceiver, newFee);
}
```

## Fee Calculation Best Practices

### Preventing Overflow

Always use safe math or Solidity ^0.8.0 for automatic overflow checks:

```solidity
// Safe calculation in OpenZeppelin's ERC2981
function royaltyInfo(uint256 tokenId, uint256 salePrice)
    public
    view
    returns (address, uint256)
{
    uint256 royaltyAmount = (salePrice * _feeDenominator) / 10000;
    return (_receiver, royaltyAmount);
}
```

### Rounding Considerations

Division in Solidity rounds down:
- Sale price: 1.999 ETH
- Royalty: 5% (500 basis points)
- Calculation: (1999000000000000000 * 500) / 10000 = 99950000000000000 (0.09995 ETH)

### Minimum Royalties

Consider setting minimum royalty amounts for small sales:

```solidity
uint256 royaltyAmount = (salePrice * feeNumerator) / 10000;
if (royaltyAmount > 0 && royaltyAmount < MIN_ROYALTY) {
    royaltyAmount = MIN_ROYALTY;
}
```

## Limitations and Considerations

### Not Enforceable

**Critical**: ERC-2981 provides royalty *information* but does not *enforce* payment.

- Marketplaces must voluntarily honor royalties
- Direct transfers bypass royalty mechanisms
- No on-chain enforcement is possible without restricting transfers

### Marketplace Adoption

Not all marketplaces support ERC-2981:
- OpenSea: Supports (but moving to operator filter)
- LooksRare: Supports
- X2Y2: Supports
- Blur: Does not enforce creator royalties
- Direct transfers: No royalties

### Gas Considerations

- **Global royalties**: Low gas overhead
- **Per-token royalties**: Higher gas costs
- **Reading royalty info**: Very cheap (view function)

### Currency Agnostic

Royalties are calculated as a percentage:
- Works with ETH, WETH, ERC20s
- Marketplace responsible for currency handling
- Royalty amount is in same units as sale price

### Privacy

All royalty information is public:
- Receiver addresses are visible on-chain
- Royalty percentages are transparent
- Cannot hide or obfuscate royalty data

## OpenZeppelin Implementation

The OpenZeppelin `ERC2981` contract provides:

1. **Default Royalty**: `_setDefaultRoyalty(receiver, feeNumerator)`
2. **Token Royalty**: `_setTokenRoyalty(tokenId, receiver, feeNumerator)`
3. **Delete Royalty**: `_deleteDefaultRoyalty()` and `_resetTokenRoyalty(tokenId)`
4. **Interface Support**: Automatic ERC165 registration

### Basic Integration

```solidity
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract MyNFT is ERC721, ERC2981 {
    constructor() ERC721("MyNFT", "MNFT") {
        // Set 5% royalty to contract deployer
        _setDefaultRoyalty(msg.sender, 500);
    }

    // Override supportsInterface for both ERC721 and ERC2981
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
```

## Advanced Patterns

### Split Royalties

Multiple recipients can be implemented via a splitter contract:

```solidity
// Set royalty receiver to a PaymentSplitter contract
_setDefaultRoyalty(address(paymentSplitter), 500);
```

### Dynamic Royalties

Royalties that change based on conditions:

```solidity
function royaltyInfo(uint256 tokenId, uint256 salePrice)
    public
    view
    override
    returns (address, uint256)
{
    // Higher royalty for rare tokens
    uint256 feeBps = isRare(tokenId) ? 1000 : 500;
    uint256 royaltyAmount = (salePrice * feeBps) / 10000;

    return (royaltyReceiver, royaltyAmount);
}
```

### Decreasing Royalties

Royalties that decrease over time:

```solidity
function royaltyInfo(uint256 tokenId, uint256 salePrice)
    public
    view
    override
    returns (address, uint256)
{
    uint256 age = block.timestamp - mintTimestamp[tokenId];
    uint256 feeBps = age > 365 days ? 250 : 500; // Reduce after 1 year
    uint256 royaltyAmount = (salePrice * feeBps) / 10000;

    return (royaltyReceiver, royaltyAmount);
}
```

## Common Pitfalls

1. **Integer Division**: Always multiply before dividing to avoid precision loss
2. **Zero Address**: Validate receiver addresses
3. **Fee Caps**: Enforce maximum royalty percentages
4. **Interface Support**: Remember to override `supportsInterface()`
5. **Denominator**: Use 10000 as denominator for basis points

## Testing Checklist

- [ ] Verify correct interface ID (0x2a55205a)
- [ ] Test royalty calculation accuracy
- [ ] Validate fee percentages
- [ ] Test both global and per-token royalties
- [ ] Verify royalty updates work correctly
- [ ] Test with zero address handling
- [ ] Ensure maximum royalty caps
- [ ] Test edge cases (zero sale price, maximum values)

## Project Structure

```
28-erc2981-royalties/
├── src/
│   ├── Project28.sol           # Skeleton contract (your task)
│   └── solution/
│       └── Project28Solution.sol  # Complete solution
├── test/
│   └── Project28.t.sol         # Comprehensive tests
├── script/
│   └── DeployProject28.s.sol   # Deployment script
└── README.md                    # This file
```

## Getting Started

1. Review the concepts above
2. Examine `src/Project28.sol` and complete the TODOs
3. Run tests: `forge test --match-path test/Project28.t.sol`
4. Compare with `src/solution/ERC2981RoyaltiesSolution.sol`

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/ERC2981RoyaltiesSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployERC2981RoyaltiesSolution.s.sol` - Deployment script patterns
- `test/solution/ERC2981RoyaltiesSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains royalty calculation patterns, payment distribution
- **Connections to Project 09**: ERC721 NFT standard (royalties are NFT-specific)
- **Real-World Context**: Enables creator royalties in NFT marketplaces

5. Deploy: `forge script script/DeployProject28.s.sol`

## Additional Resources

- [EIP-2981 Specification](https://eips.ethereum.org/EIPS/eip-2981)
- [OpenZeppelin ERC2981 Documentation](https://docs.openzeppelin.com/contracts/4.x/api/token/common#ERC2981)
- [NFT Royalty Standard Explainer](https://eips.ethereum.org/EIPS/eip-2981)
- [Marketplace Royalty Support](https://royaltyregistry.xyz/)

## Next Steps

After mastering ERC-2981, explore:
- Project 29: Operator Filter Registry (enforcing royalties)
- Payment splitters for multiple royalty recipients
- Cross-chain royalty tracking
- Alternative royalty enforcement mechanisms

## License

MIT

---


## 29-merkle-allowlist

# Project 29: Merkle Proof Allowlists

Learn how to use Merkle trees for efficient allowlist verification in smart contracts.

## Overview

This project teaches you how to implement gas-efficient allowlists using Merkle trees and Merkle proofs. Instead of storing thousands of allowlisted addresses on-chain, you store a single 32-byte Merkle root and verify proofs off-chain.

## What are Merkle Trees? Efficient Set Membership Proofs

**FIRST PRINCIPLES: Hash Tree Data Structure**

A Merkle tree (also called a hash tree) is a data structure where:
- Each leaf node is a hash of some data
- Each non-leaf node is a hash of its children
- The root node represents the entire dataset

**CONNECTION TO PROJECT 01**:
We learned about `keccak256` hashing in Project 01. Merkle trees use keccak256 to build hierarchical hash structures!

**UNDERSTANDING THE STRUCTURE** (DSA Concept):

```
Merkle Tree Visualization:
         Root Hash (Merkle Root) ← Only 32 bytes stored on-chain!
              /        \
           H(AB)      H(CD)      ← Intermediate nodes (computed)
           /  \        /  \
         H(A) H(B)  H(C) H(D)    ← Leaf nodes (hashes of data)
          |    |     |    |
          A    B     C    D       ← Actual data (off-chain)
```

**HOW IT WORKS** (from Project 01 knowledge):

```
Hash Calculation:
┌─────────────────────────────────────────┐
│ Leaf Level:                             │
│   H(A) = keccak256(A)                   │ ← Hash of data
│   H(B) = keccak256(B)                   │
│   ↓                                      │
│ Intermediate Level:                     │
│   H(AB) = keccak256(H(A) || H(B))       │ ← Hash of children
│   ↓                                      │
│ Root Level:                              │
│   Root = keccak256(H(AB) || H(CD))      │ ← Final hash
└─────────────────────────────────────────┘
```

**PROPERTIES** (DSA Analysis):

1. **Compact**: Only need to store the root hash (32 bytes)
   - From Project 01: bytes32 = 32 bytes
   - Can represent millions of addresses with one hash!
   - Storage: ~20,000 gas (one SSTORE) vs millions for mappings

2. **Verifiable**: Can prove a leaf is in the tree without revealing all leaves
   - Proof size: O(log n) - logarithmic!
   - For 1M addresses: ~20 hashes needed (log2(1M) ≈ 20)
   - Privacy: Don't reveal entire allowlist

3. **Immutable**: Changing any leaf changes the root hash
   - From Project 01: keccak256 is one-way function
   - Any change propagates to root
   - Tamper-evident structure

4. **Efficient**: Proof size is O(log n) where n is the number of leaves
   - Time complexity: O(log n) verification
   - Space complexity: O(log n) proof size
   - From Project 06: Logarithmic is much better than linear!

**COMPARISON TO RUST** (DSA Concept):

**Rust** (Merkle tree implementation):
```rust
use sha2::{Sha256, Digest};

struct MerkleTree {
    root: [u8; 32],
    leaves: Vec<[u8; 32]>,
}

impl MerkleTree {
    fn verify(&self, leaf: [u8; 32], proof: Vec<[u8; 32]>) -> bool {
        // O(log n) verification
    }
}
```

**Solidity** (Merkle proof verification):
```solidity
function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) 
    public pure returns (bool) {
    // O(log n) verification using keccak256
}
```

Both use the same Merkle tree algorithm - Solidity just uses keccak256 (from Project 01)!

## How Merkle Proofs Work

To prove that leaf `A` is in the tree, you need:
1. The leaf data (`A`)
2. The sibling hashes along the path to the root (`H(B)`, `H(CD)`)

Verification:
```
1. Compute H(A)
2. Compute H(AB) = hash(H(A) + H(B))
3. Compute Root = hash(H(AB) + H(CD))
4. Compare computed Root with stored Root
```

If they match, the proof is valid!

## Why Use Merkle Trees vs Mappings?

### Traditional Allowlist (Mapping)

```solidity
mapping(address => bool) public allowlist;

// Setting up 1000 addresses
function setAllowlist(address[] calldata addresses) external {
    for (uint i = 0; i < addresses.length; i++) {
        allowlist[addresses[i]] = true; // ~20,000 gas per address
    }
}
// Total: ~20,000,000 gas for 1000 addresses!
```

### Merkle Allowlist

```solidity
bytes32 public merkleRoot;

// Setting up ANY number of addresses
function setMerkleRoot(bytes32 _root) external {
    merkleRoot = _root; // ~20,000 gas total
}
// Total: ~20,000 gas for ANY number of addresses!
```

### Gas Comparison

| Operation | Mapping | Merkle Tree |
|-----------|---------|-------------|
| Setup 100 addresses | ~2,000,000 gas | ~20,000 gas |
| Setup 1,000 addresses | ~20,000,000 gas | ~20,000 gas |
| Setup 10,000 addresses | ~200,000,000 gas | ~20,000 gas |
| Verify 1 address | ~2,100 gas | ~3,500 gas |

**Winner**: Merkle trees for large allowlists!

## Creating Merkle Trees Off-Chain

### Using TypeScript (ethers.js + merkletreejs)

```typescript
import { MerkleTree } from 'merkletreejs';
import keccak256 from 'keccak256';
import { ethers } from 'ethers';

// 1. Define your allowlist
const allowlist: string[] = [
    "0x1111111111111111111111111111111111111111",
    "0x2222222222222222222222222222222222222222",
    "0x3333333333333333333333333333333333333333"
];

// 2. Create leaf nodes (hash each address)
const leafNodes: Buffer[] = allowlist.map(addr =>
    keccak256(ethers.solidityPacked(['address'], [addr]))
);

// 3. Create Merkle tree
const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true });

// 4. Get root hash
const rootHash: Buffer = merkleTree.getRoot();
console.log("Merkle Root:", "0x" + rootHash.toString('hex'));

// 5. Generate proof for an address
const address: string = "0x1111111111111111111111111111111111111111";
const leaf: Buffer = keccak256(ethers.solidityPacked(['address'], [address]));
const proof: string[] = merkleTree.getHexProof(leaf);
console.log("Proof:", proof);
```

### Using Foundry (Solidity)

```solidity
// In your test file
import "forge-std/Test.sol";
import "murky/Merkle.sol";

contract MerkleTest is Test {
    Merkle merkle = new Merkle();

    function testGenerateMerkleTree() public {
        bytes32[] memory leaves = new bytes32[](3);
        leaves[0] = keccak256(abi.encodePacked(address(0x1111)));
        leaves[1] = keccak256(abi.encodePacked(address(0x2222)));
        leaves[2] = keccak256(abi.encodePacked(address(0x3333)));

        bytes32 root = merkle.getRoot(leaves);
        bytes32[] memory proof = merkle.getProof(leaves, 0);

        bool verified = merkle.verifyProof(root, proof, leaves[0]);
        assertTrue(verified);
    }
}
```

## Proof Verification On-Chain

### Using OpenZeppelin's MerkleProof

```solidity
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MyContract {
    bytes32 public merkleRoot;

    function verify(
        bytes32[] calldata proof,
        address account
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(account));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }
}
```

### Manual Implementation

```solidity
function verifyProof(
    bytes32[] memory proof,
    bytes32 root,
    bytes32 leaf
) internal pure returns (bool) {
    bytes32 computedHash = leaf;

    for (uint256 i = 0; i < proof.length; i++) {
        bytes32 proofElement = proof[i];

        if (computedHash <= proofElement) {
            computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
        } else {
            computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
        }
    }

    return computedHash == root;
}
```

## Security Considerations

### 1. Double Claiming

**Problem**: Users might try to claim multiple times

**Solution**: Track claimed addresses

```solidity
mapping(address => bool) public hasClaimed;

function claim(bytes32[] calldata proof) external {
    require(!hasClaimed[msg.sender], "Already claimed");
    require(verify(proof, msg.sender), "Invalid proof");

    hasClaimed[msg.sender] = true;
    // Transfer tokens/NFT
}
```

### 2. Leaf Node Hashing

**Problem**: If you hash just the address, someone could use a proof for one tree in another tree

**Solution**: Include additional context in the leaf

```solidity
// Better: Include contract-specific data
bytes32 leaf = keccak256(abi.encodePacked(account, amount, contractAddress));

// Or use OpenZeppelin's MessageHashUtils
bytes32 leaf = MessageHashUtils.toEthSignedMessageHash(
    keccak256(abi.encodePacked(account))
);
```

### 3. Proof Forgery

**Problem**: Attacker might try to forge proofs

**Defense**: OpenZeppelin's MerkleProof library handles this correctly by:
- Sorting pairs during hashing
- Preventing second pre-image attacks
- Validating proof length

### 4. Front-Running

**Problem**: Attacker sees your valid claim transaction and front-runs it

**Mitigation**:
```solidity
// Option 1: Signature-based claiming
function claim(bytes32[] calldata proof, bytes calldata signature) external {
    require(verify(proof, msg.sender), "Invalid proof");
    require(verifySignature(signature), "Invalid signature");
    // ...
}

// Option 2: Commit-reveal pattern
// Option 3: Accept front-running (if minting is cheap)
```

### 5. Root Update

**Problem**: Owner updates root maliciously

**Solution**:
```solidity
// Make root immutable
bytes32 public immutable merkleRoot;

constructor(bytes32 _root) {
    merkleRoot = _root;
}

// Or use a timelock
uint256 public constant ROOT_UPDATE_DELAY = 7 days;
```

## Common Use Cases

### 1. Allowlist Minting (NFTs)

```solidity
contract AllowlistNFT is ERC721 {
    bytes32 public merkleRoot;
    mapping(address => bool) public hasMinted;

    function allowlistMint(bytes32[] calldata proof) external {
        require(!hasMinted[msg.sender], "Already minted");
        require(verify(proof, msg.sender), "Not on allowlist");

        hasMinted[msg.sender] = true;
        _mint(msg.sender, totalSupply());
    }
}
```

### 2. Airdrops with Amounts

```solidity
contract Airdrop {
    bytes32 public merkleRoot;
    mapping(address => bool) public hasClaimed;

    function claim(
        uint256 amount,
        bytes32[] calldata proof
    ) external {
        require(!hasClaimed[msg.sender], "Already claimed");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");

        hasClaimed[msg.sender] = true;
        token.transfer(msg.sender, amount);
    }
}
```

### 3. Tiered Access

```solidity
contract TieredNFT {
    bytes32 public goldRoot;
    bytes32 public silverRoot;

    function mintGold(bytes32[] calldata proof) external {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, goldRoot, leaf), "Not gold tier");
        _mint(msg.sender, GOLD_TIER);
    }

    function mintSilver(bytes32[] calldata proof) external {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, silverRoot, leaf), "Not silver tier");
        _mint(msg.sender, SILVER_TIER);
    }
}
```

### 4. Vesting Schedule

```solidity
contract VestingAirdrop {
    struct VestingInfo {
        uint256 totalAmount;
        uint256 startTime;
        uint256 duration;
    }

    bytes32 public merkleRoot;
    mapping(address => uint256) public claimed;

    function claim(
        VestingInfo calldata vesting,
        bytes32[] calldata proof
    ) external {
        bytes32 leaf = keccak256(abi.encode(msg.sender, vesting));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");

        uint256 vested = calculateVested(vesting);
        uint256 claimable = vested - claimed[msg.sender];

        claimed[msg.sender] = vested;
        token.transfer(msg.sender, claimable);
    }
}
```

## Best Practices

1. **Always Use OpenZeppelin's MerkleProof**: Don't implement your own unless you have a specific reason
2. **Sort Pairs**: Ensure consistent tree construction with `{ sortPairs: true }`
3. **Track Claims**: Use mapping to prevent double claiming
4. **Test Edge Cases**: Empty proofs, invalid proofs, forged proofs
5. **Document Your Tree Structure**: Make it clear how leaves are hashed
6. **Consider Leaf Uniqueness**: Hash with additional data if needed
7. **Gas Optimize**: Larger trees = more proof elements = more gas
8. **Store Proofs Off-Chain**: Don't put proofs in the contract
9. **Provide Proof Generation Tools**: Make it easy for users to get their proofs
10. **Consider Multi-Proof**: For claiming multiple items, use MultiProof

## Advanced: Multi Proof

For claiming multiple items efficiently:

```solidity
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

function claimMultiple(
    uint256[] calldata amounts,
    bytes32[] calldata proof,
    bool[] calldata proofFlags
) external {
    bytes32[] memory leaves = new bytes32[](amounts.length);
    for (uint i = 0; i < amounts.length; i++) {
        leaves[i] = keccak256(abi.encodePacked(msg.sender, amounts[i]));
    }

    require(
        MerkleProof.multiProofVerify(proof, proofFlags, merkleRoot, leaves),
        "Invalid multi-proof"
    );

    // Process all claims
}
```

## Learning Objectives

By completing this project, you will learn:
- How Merkle trees work and why they're useful
- How to create Merkle trees off-chain
- How to verify Merkle proofs on-chain
- Gas efficiency comparison between methods
- Common security pitfalls and how to avoid them
- Real-world use cases for Merkle trees

## Project Structure

```
29-merkle-allowlist/
├── src/
│   ├── Project29.sol              # Skeleton with TODOs
│   └── solution/
│       └── Project29Solution.sol  # Complete solution
├── test/
│   └── Project29.t.sol            # Comprehensive tests
├── script/
│   └── DeployProject29.s.sol      # Deployment script
└── README.md                      # This file
```

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/MerkleAllowlistSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployMerkleAllowlistSolution.s.sol` - Deployment script patterns
- `test/solution/MerkleAllowlistSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains Merkle trees, cryptographic proofs, hash functions
- **Connections to Project 01**: keccak256 hashing (used for Merkle tree construction)
- **Connections to Project 14**: ABI encoding for leaf node construction
- **Connections to Project 09**: NFT minting with allowlist restriction
- **Real-World Context**: Gas-efficient whitelisting - store only root hash, verify with proof (O(log n))

## Tasks

1. Implement Merkle proof verification
2. Add allowlist minting functionality
3. Prevent double claiming
4. Write tests for valid and invalid proofs
5. Compare gas costs with mapping approach
6. Generate Merkle trees off-chain

## Testing

```bash
# Run tests
forge test --match-path test/Project29.t.sol -vv

# Run with gas reporting
forge test --match-path test/Project29.t.sol --gas-report

# Test specific function
forge test --match-test testValidProof -vvv
```

## Deployment

```bash
# Deploy to local network
forge script script/DeployProject29.s.sol --rpc-url http://localhost:8545 --broadcast

# Deploy to testnet
forge script script/DeployProject29.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
```

## Resources

- [OpenZeppelin MerkleProof](https://docs.openzeppelin.com/contracts/5.x/api/utils#MerkleProof)
- [Merkle Tree JS Library](https://github.com/merkletreejs/merkletreejs)
- [Murky (Foundry Merkle)](https://github.com/dmfxyz/murky)
- [Uniswap Merkle Distributor](https://github.com/Uniswap/merkle-distributor)
- [How Merkle Trees Work](https://en.wikipedia.org/wiki/Merkle_tree)

## Further Exploration

- Implement a multi-tier allowlist
- Add dynamic Merkle root updates with governance
- Create an airdrop with different amounts per address
- Implement batch claiming with MultiProof
- Build a frontend for proof generation and claiming
- Optimize for extremely large allowlists (1M+ addresses)

## Common Pitfalls

1. **Not sorting pairs**: Trees must be consistent
2. **Forgetting to track claims**: Users can claim multiple times
3. **Incorrect leaf hashing**: Must match off-chain construction
4. **Not validating proof length**: Could lead to unexpected behavior
5. **Storing proofs on-chain**: Defeats the purpose of Merkle trees
6. **Updating root without consideration**: Could invalidate existing proofs

Good luck! Merkle trees are a powerful tool for building gas-efficient smart contracts.

---


## 30-onchain-svg

# Project 30: On-Chain SVG Rendering

Learn how to create fully on-chain NFTs with dynamically generated SVG artwork stored entirely on the blockchain.

## Overview

This project teaches you how to create NFTs where both metadata and artwork are stored completely on-chain, making them truly permanent and decentralized. You'll learn to generate SVG images programmatically in Solidity and encode them as data URIs.

## Learning Objectives

- Understand on-chain vs off-chain metadata storage
- Master SVG generation in Solidity
- Implement Base64 encoding for data URIs
- Create dynamic NFT attributes
- Build generative art algorithms
- Optimize gas costs for on-chain storage
- Construct proper JSON metadata

## On-Chain vs Off-Chain Metadata: Storage Trade-offs

**FIRST PRINCIPLES: Decentralization vs Cost**

Understanding the trade-offs between on-chain and off-chain metadata is crucial for NFT design. Each approach has different costs and benefits!

**CONNECTION TO PROJECT 09**:
- **Project 09**: ERC721 NFTs with off-chain metadata (IPFS)
- **Project 30**: On-chain SVG generation (no IPFS needed!)
- Both valid approaches - choose based on requirements!

### Off-Chain Metadata (Traditional)

**HOW IT WORKS**:
```
Token -> tokenURI -> IPFS/Server -> JSON -> Image URL -> IPFS/Server -> Image
```

**CONNECTION TO PROJECT 03**:
We learned about events in Project 03. Off-chain metadata uses similar pattern - data stored off-chain, referenced on-chain!

**PROS**:
- Low gas costs (from Project 01: storage is expensive!)
  - Only store URI string: ~20,000 gas
  - Image stored off-chain (free!)
  
- Can store high-resolution images
  - No size constraints
  - Complex media (videos, 3D models)
  
- Easy to update
  - Change metadata without redeploying
  - Update images independently

**CONS**:
- Requires external storage (IPFS, centralized servers)
  - Dependency on external systems
  - IPFS requires pinning services
  
- Risk of link rot
  - If IPFS node goes down, metadata unavailable
  - Centralized servers can be censored
  
- Not truly decentralized
  - Relies on external infrastructure
  - Can be taken down

### On-Chain Metadata (This Project)

**HOW IT WORKS**:
```
Token -> Smart Contract -> Generated SVG + JSON -> Data URI
```

**UNDERSTANDING DATA URIs**:

```
Data URI Format:
data:image/svg+xml;base64,<base64_encoded_svg>
```

**PROS**:
- Truly permanent and decentralized
  - Stored on blockchain forever
  - No external dependencies
  
- Cannot be censored or taken down
  - Blockchain is immutable
  - No single point of failure
  
- Guaranteed availability
  - As long as blockchain exists, NFT exists
  - No link rot possible

**CONS**:
- Higher gas costs (from Project 01 knowledge)
  - Storage: ~20,000 gas per write
  - SVG strings: ~5 gas per byte
  - For 1KB SVG: ~25,000 gas (storage) + ~5,000 gas (data) = ~30,000 gas
  
- Limited to simple graphics
  - SVG only (no videos, 3D models)
  - Size constraints (gas limits)
  
- Cannot update without upgradeable contracts
  - Immutable once deployed
  - Need proxies (Project 10) for updates

**GAS COST COMPARISON** (from Project 01 & 03 knowledge):

**Off-Chain**:
- Store URI: ~20,000 gas (string storage)
- Image: FREE (off-chain)
- Total: ~20,000 gas

**On-Chain**:
- Store SVG: ~20,000 gas (base) + ~5 gas/byte
- For 1KB SVG: ~25,000 gas
- For 10KB SVG: ~70,000 gas
- Total: 25,000-70,000+ gas (depends on size)

**REAL-WORLD ANALOGY**: 
- **Off-Chain**: Like storing artwork in a museum (cheap, but museum can close)
- **On-Chain**: Like engraving artwork in stone (expensive, but permanent)

## SVG Basics for NFTs

### What is SVG?

SVG (Scalable Vector Graphics) is an XML-based format for 2D graphics that's perfect for on-chain NFTs because:

1. **Text-based**: Can be generated as strings in Solidity
2. **Scalable**: Looks crisp at any size
3. **Small file size**: Efficient for on-chain storage
4. **Browser support**: All modern browsers render SVGs
5. **Dynamic**: Easy to parameterize and generate programmatically

### Basic SVG Structure

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">
  <!-- Shapes go here -->
  <rect x="50" y="50" width="100" height="100" fill="blue" />
  <circle cx="200" cy="200" r="50" fill="red" />
  <text x="200" y="350" text-anchor="middle" font-size="24">Hello</text>
</svg>
```

### Common SVG Elements

**Shapes:**
- `<rect>` - Rectangles
- `<circle>` - Circles
- `<ellipse>` - Ellipses
- `<line>` - Lines
- `<polyline>` - Connected lines
- `<polygon>` - Closed shapes
- `<path>` - Complex curves

**Styling:**
- `fill` - Fill color
- `stroke` - Border color
- `stroke-width` - Border thickness
- `opacity` - Transparency

**Text:**
- `<text>` - Text elements
- `font-size`, `font-family`, `text-anchor`

## Base64 Encoding

### Why Base64?

Base64 encoding converts binary data (or strings) into ASCII text, allowing us to embed SVG and JSON directly in URIs.

### Data URI Format

```
data:[<mediatype>][;base64],<data>
```

**Examples:**
```
data:image/svg+xml;base64,PHN2ZyB4bWxucz0i...
data:application/json;base64,eyJuYW1lIjoi...
```

### Base64 in Solidity

Solidity doesn't have built-in Base64 encoding, so we need to implement it:

```solidity
// Base64 alphabet
string constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

function encode(bytes memory data) internal pure returns (string memory) {
    // Encoding logic: converts 3 bytes into 4 base64 characters
    // Handles padding with '=' for data not divisible by 3
}
```

## Dynamic NFTs

Dynamic NFTs change based on various factors:

### 1. Token ID-Based
```solidity
// Different colors for each token
function getColor(uint256 tokenId) internal pure returns (string memory) {
    uint256 hue = (tokenId * 137) % 360;  // Golden angle distribution
    return string.concat("hsl(", toString(hue), ",70%,50%)");
}
```

### 2. Time-Based
```solidity
// Changes based on block timestamp
function getPattern(uint256 tokenId) internal view returns (string memory) {
    uint256 timeOfDay = (block.timestamp % 86400) / 3600;  // Hour of day
    if (timeOfDay < 6) return "night";
    if (timeOfDay < 12) return "morning";
    if (timeOfDay < 18) return "afternoon";
    return "evening";
}
```

### 3. Trait-Based
```solidity
// Based on stored attributes
struct Traits {
    uint8 shape;
    uint8 pattern;
    uint8 rarity;
}

mapping(uint256 => Traits) public tokenTraits;
```

### 4. Interactive
```solidity
// Changes based on user actions
function levelUp(uint256 tokenId) external {
    require(ownerOf(tokenId) == msg.sender);
    tokenLevel[tokenId]++;
    // SVG changes to reflect new level
}
```

## Gas Costs of On-Chain Storage

### Storage Costs

Gas costs for on-chain data (approximate):
- **SSTORE** (new): ~20,000 gas per 32 bytes
- **SSTORE** (update): ~5,000 gas per 32 bytes
- **Contract code**: ~200 gas per byte

### Optimization Strategies

#### 1. Use String Concatenation Efficiently
```solidity
// Bad: Creates many intermediate strings
string memory svg = "<svg>";
svg = string.concat(svg, "<rect/>");
svg = string.concat(svg, "<circle/>");

// Better: Concatenate in fewer operations
string memory svg = string.concat(
    "<svg>",
    "<rect/>",
    "<circle/>"
);
```

#### 2. Store Reusable Components
```solidity
// Store common strings as constants (in bytecode, not storage)
string constant SVG_HEADER = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">';
string constant SVG_FOOTER = '</svg>';
```

#### 3. Pack Data Efficiently
```solidity
// Bad: Each trait uses 256 bits
uint256 shape;
uint256 color;
uint256 pattern;

// Good: Pack into single uint256
uint256 packedTraits;  // [8 bits shape][8 bits color][8 bits pattern][232 bits unused]
```

#### 4. Use Events for Historical Data
```solidity
// Don't store everything in state
event MetadataUpdate(uint256 indexed tokenId, string metadata);

// Emit events for historical records, only store current state
```

### Real-World Gas Costs

**Typical On-Chain NFT Mint:**
- Off-chain metadata: ~50,000-100,000 gas
- On-chain metadata: ~200,000-500,000 gas
- Complex generative art: ~500,000-1,000,000+ gas

**Cost Analysis** (at 50 gwei, ETH = $2000):
- Simple on-chain NFT: $20-50
- Complex generative NFT: $50-100+

## Generative Art Patterns

### 1. Geometric Patterns

```solidity
function generateCircles(uint256 tokenId) internal pure returns (string memory) {
    string memory circles;
    for (uint256 i = 0; i < 5; i++) {
        uint256 cx = (tokenId * (i + 1) * 73) % 400;
        uint256 cy = (tokenId * (i + 1) * 31) % 400;
        uint256 r = 20 + (i * 10);

        circles = string.concat(
            circles,
            '<circle cx="', toString(cx),
            '" cy="', toString(cy),
            '" r="', toString(r),
            '" fill="hsl(', toString(i * 72), ',70%,50%)" />'
        );
    }
    return circles;
}
```

### 2. Color Schemes

```solidity
// Golden ratio for pleasing color distribution
function getHue(uint256 seed, uint256 index) internal pure returns (uint256) {
    return (seed + index * 137) % 360;  // 137.5° is golden angle
}

// Complementary colors
function getComplementary(uint256 hue) internal pure returns (uint256) {
    return (hue + 180) % 360;
}

// Triadic colors
function getTriadic(uint256 hue, uint256 index) internal pure returns (uint256) {
    return (hue + index * 120) % 360;
}
```

### 3. Pseudo-Random Generation

```solidity
// Deterministic randomness from token ID
function getRandom(uint256 tokenId, uint256 seed) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(tokenId, seed)));
}

// Multiple random values
function getRandomPattern(uint256 tokenId) internal pure returns (uint256[] memory) {
    uint256[] memory randoms = new uint256[](5);
    for (uint256 i = 0; i < 5; i++) {
        randoms[i] = getRandom(tokenId, i);
    }
    return randoms;
}
```

### 4. Mathematical Patterns

```solidity
// Spiral pattern
function getSpiral(uint256 index, uint256 totalPoints) internal pure returns (uint256 x, uint256 y) {
    uint256 angle = (index * 360 * 3) / totalPoints;  // 3 full rotations
    uint256 radius = 50 + (index * 100) / totalPoints;

    x = 200 + (radius * cos(angle)) / 1000;
    y = 200 + (radius * sin(angle)) / 1000;
}

// Grid pattern
function getGrid(uint256 index, uint256 cols) internal pure returns (uint256 x, uint256 y) {
    x = (index % cols) * 50 + 25;
    y = (index / cols) * 50 + 25;
}
```

## Use Cases for On-Chain NFTs

### 1. Generative Art Projects
- **Art Blocks**: Pioneered on-chain generative art
- **Autoglyphs**: First on-chain generative art on Ethereum
- **Chain Runners**: Fully on-chain pixel art characters

### 2. Gaming Assets
- **Loot**: Text-based adventure game items
- **On-chain games**: Assets that can't be taken down
- **Provably fair randomness**: All logic verifiable on-chain

### 3. Credentials & Certificates
- **Educational certificates**: Permanent proof of achievement
- **Professional licenses**: Verifiable credentials
- **Event attendance**: POAPs and similar

### 4. Identity & Profile
- **ENS names**: On-chain domain names
- **Profile pictures**: Permanent social media avatars
- **Reputation systems**: Immutable achievement records

### 5. Financial Instruments
- **Bonds**: Visual representation of financial positions
- **Derivatives**: Complex financial products
- **Receipts**: Proof of transactions

## JSON Metadata Structure

### ERC721 Metadata Standard

```json
{
  "name": "Token Name #1",
  "description": "Description of the token",
  "image": "data:image/svg+xml;base64,...",
  "attributes": [
    {
      "trait_type": "Background",
      "value": "Blue"
    },
    {
      "trait_type": "Pattern",
      "value": "Circles"
    },
    {
      "trait_type": "Rarity",
      "value": "Legendary",
      "display_type": "string"
    },
    {
      "trait_type": "Power",
      "value": 95,
      "display_type": "number",
      "max_value": 100
    }
  ]
}
```

### Attribute Display Types

- `string`: Default text display
- `number`: Numeric value (shows progress bar on OpenSea)
- `boost_number`: Numerical boost
- `boost_percentage`: Percentage boost
- `date`: Unix timestamp (shows as date)

### Generating JSON in Solidity

```solidity
function getMetadata(uint256 tokenId) internal view returns (string memory) {
    return string.concat(
        '{"name":"Token #', toString(tokenId),
        '","description":"On-chain SVG NFT",',
        '"image":"data:image/svg+xml;base64,', Base64.encode(bytes(getSVG(tokenId))),
        '","attributes":[',
        '{"trait_type":"Color","value":"', getColorName(tokenId), '"},',
        '{"trait_type":"Pattern","value":"', getPatternName(tokenId), '"}',
        ']}'
    );
}
```

## Implementation Patterns

### Pattern 1: Simple Static SVG

```solidity
function tokenURI(uint256 tokenId) public view override returns (string memory) {
    string memory svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">'
        '<rect width="400" height="400" fill="blue"/>'
        '<text x="200" y="200" text-anchor="middle" font-size="48" fill="white">NFT</text>'
        '</svg>';

    string memory json = string.concat(
        '{"name":"Token #', toString(tokenId), '",',
        '"image":"data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'
    );

    return string.concat('data:application/json;base64,', Base64.encode(bytes(json)));
}
```

### Pattern 2: Token ID-Based Colors

```solidity
function tokenURI(uint256 tokenId) public view override returns (string memory) {
    string memory color = getColor(tokenId);

    string memory svg = string.concat(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">',
        '<rect width="400" height="400" fill="', color, '"/>',
        '</svg>'
    );

    // ... rest of metadata generation
}

function getColor(uint256 tokenId) internal pure returns (string memory) {
    uint256 hue = (tokenId * 137) % 360;
    return string.concat('hsl(', toString(hue), ',70%,50%)');
}
```

### Pattern 3: Complex Generative Art

```solidity
function tokenURI(uint256 tokenId) public view override returns (string memory) {
    // Generate multiple components
    string memory background = generateBackground(tokenId);
    string memory shapes = generateShapes(tokenId);
    string memory effects = generateEffects(tokenId);

    string memory svg = string.concat(
        SVG_HEADER,
        background,
        shapes,
        effects,
        SVG_FOOTER
    );

    // Generate traits
    string memory attributes = generateAttributes(tokenId);

    string memory json = string.concat(
        '{"name":"Generative #', toString(tokenId), '",',
        '"description":"Complex on-chain generative art",',
        '"image":"data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '",',
        '"attributes":', attributes,
        '}'
    );

    return string.concat('data:application/json;base64,', Base64.encode(bytes(json)));
}
```

## Best Practices

### 1. Gas Optimization
- Minimize storage reads/writes
- Use `pure` and `view` functions when possible
- Batch string concatenations
- Store constants in bytecode, not storage

### 2. SVG Generation
- Keep SVGs simple and clean
- Use viewBox for responsiveness
- Avoid excessive nesting
- Test rendering in browsers

### 3. Metadata Quality
- Follow ERC721 metadata standard
- Provide meaningful attributes
- Use proper JSON formatting
- Include description and name

### 4. Testing
- Test Base64 encoding/decoding
- Verify SVG renders correctly
- Check JSON validity
- Test with various token IDs

### 5. Security
- Validate all inputs
- Prevent overflow in calculations
- Handle edge cases (tokenId = 0, max uint256)
- Ensure deterministic output

## Common Pitfalls

1. **Gas Costs**: Underestimating minting costs
2. **String Handling**: Inefficient concatenation
3. **SVG Syntax**: Invalid XML/SVG that won't render
4. **JSON Formatting**: Broken JSON that marketplaces can't parse
5. **Base64 Encoding**: Incorrect implementation
6. **Number Conversion**: toString() not implemented
7. **Non-Deterministic**: Using block.timestamp in ways that change historical tokens

## Advanced Techniques

### 1. Layered Composition

```solidity
function buildLayers(uint256 tokenId) internal pure returns (string memory) {
    return string.concat(
        getLayer("background", tokenId),
        getLayer("base", tokenId),
        getLayer("pattern", tokenId),
        getLayer("overlay", tokenId)
    );
}
```

### 2. Animation

```solidity
string memory animated = string.concat(
    '<circle cx="200" cy="200" r="50" fill="red">',
    '<animate attributeName="r" values="50;75;50" dur="2s" repeatCount="indefinite"/>',
    '</circle>'
);
```

### 3. Filters and Effects

```solidity
string memory withEffects = string.concat(
    '<defs>',
    '<filter id="blur"><feGaussianBlur in="SourceGraphic" stdDeviation="5"/></filter>',
    '</defs>',
    '<rect width="400" height="400" fill="blue" filter="url(#blur)"/>'
);
```

## Your Task

Complete the skeleton contract in `src/Project30.sol` to create a fully on-chain NFT with dynamic SVG generation:

1. Implement Base64 encoding
2. Generate dynamic SVGs based on token ID
3. Create colorful, interesting artwork
4. Build proper JSON metadata
5. Implement tokenURI function
6. Add multiple dynamic attributes

## Testing

Run the test suite:
```bash
forge test -vv
```

Test specific functions:
```bash
forge test --match-test testSVGGeneration -vvvv
```

## Deployment

Deploy to a testnet:
```bash
forge script script/DeployProject30.s.sol:DeployProject30 --rpc-url sepolia --broadcast --verify
```

View your on-chain NFT metadata:
1. Mint a token
2. Call tokenURI(tokenId)
3. Copy the data URI
4. Paste into browser address bar
5. See your fully on-chain metadata and artwork!

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/OnChainSVGSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployOnChainSVGSolution.s.sol` - Deployment script patterns
- `test/solution/OnChainSVGSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains string concatenation, Base64 encoding, data URI construction
- **Connections to Project 09**: ERC721 NFT standard (this adds on-chain metadata)
- **Connections to Project 01**: String storage costs (on-chain metadata is expensive but permanent)
- **Real-World Context**: Fully decentralized NFTs - no IPFS dependency

## Resources

- [SVG Tutorial - MDN](https://developer.mozilla.org/en-US/docs/Web/SVG/Tutorial)
- [ERC721 Metadata Standard](https://eips.ethereum.org/EIPS/eip-721)
- [OpenSea Metadata Standards](https://docs.opensea.io/docs/metadata-standards)
- [Base64 Encoding](https://en.wikipedia.org/wiki/Base64)
- [Art Blocks](https://www.artblocks.io/)
- [Loot Project](https://www.lootproject.com/)

## Examples of On-Chain NFT Projects

1. **Autoglyphs** - First on-chain generative art
2. **Loot** - Text-based adventure gear
3. **Chain Runners** - Pixel art characters
4. **Blitmap** - Collaborative pixel art
5. **Nouns** - Daily generative avatars
6. **On-Chain Monkey** - First PFP with on-chain metadata

Good luck creating your fully on-chain NFT collection!

---


## 31-reentrancy-lab

# Project 31: Reentrancy Lab (Advanced) 🔄

> **Master advanced reentrancy attack patterns and defenses**

## 🎯 Learning Objectives

By completing this project, you will:

1. **Understand multi-function reentrancy attacks** and cross-function exploitation
2. **Exploit cross-contract reentrancy vulnerabilities** through multiple contracts
3. **Master read-only reentrancy** (view function exploits)
4. **Build multi-hop reentrancy chains** for complex attacks
5. **Analyze real-world case studies** (DAO hack, Lendf.me)
6. **Implement advanced defense strategies** beyond basic ReentrancyGuard
7. **Create Foundry attack simulations** for testing
8. **Write comprehensive test suites** covering all attack vectors
9. **Understand defense-in-depth** approaches

## Reentrancy Attack Types

### 1. Single-Function Reentrancy (Basic)

**CONNECTION TO PROJECT 07**:
We learned about basic reentrancy in Project 07. Here we dive deeper into advanced patterns!

The classic DAO attack pattern where a function is reentered before state updates:

```solidity
function withdraw(uint amount) external {
    require(balances[msg.sender] >= amount);  // CHECK ✅
    // ❌ VULNERABLE: External call before state update
    (bool success,) = msg.sender.call{value: amount}("");  // INTERACTION FIRST!
    require(success);
    balances[msg.sender] -= amount; // ❌ EFFECT TOO LATE!
}
```

**DETAILED ATTACK FLOW** (from Project 07 knowledge):

```
Call Stack Visualization:
┌─────────────────────────────────────────┐
│ withdraw(100) - First Call              │
│   ↓                                      │
│ Check: balance >= 100 ✅                 │ ← Passes
│   ↓                                      │
│ External call: send 100 ETH             │ ← Attacker receives ETH
│   ↓                                      │
│ [ATTACKER'S RECEIVE() EXECUTES]         │ ← Re-enters contract!
│   ↓                                      │
│ withdraw(100) - Second Call             │ ← Reentrant call!
│   ↓                                      │
│ Check: balance >= 100 ✅                 │ ← STILL PASSES! (not updated!)
│   ↓                                      │
│ External call: send 100 ETH             │ ← More ETH sent!
│   ↓                                      │
│ [ATTACKER'S RECEIVE() EXECUTES AGAIN]   │ ← Can repeat!
│   ↓                                      │
│ ... (continues until contract drained)  │
│   ↓                                      │
│ Finally: balance -= 100                 │ ← Too late! Already drained
└─────────────────────────────────────────┘
```

**WHY IT WORKS**:
- State updated AFTER external call
- Reentrant call sees old state
- Can drain contract before state updates

**THE FIX** (Checks-Effects-Interactions from Project 07):
```solidity
function withdraw(uint amount) external {
    require(balances[msg.sender] >= amount);  // CHECK ✅
    balances[msg.sender] -= amount;           // EFFECT FIRST! ✅
    (bool success,) = msg.sender.call{value: amount}("");  // INTERACTION LAST ✅
    require(success);
}
```

### 2. Multi-Function Reentrancy (Cross-Function)

Reentering through a DIFFERENT function than the one being exploited:

```solidity
function withdraw(uint amount) external {
    require(balances[msg.sender] >= amount);
    (bool success,) = msg.sender.call{value: amount}("");
    require(success);
    balances[msg.sender] -= amount;
}

function transfer(address to, uint amount) external {
    require(balances[msg.sender] >= amount);
    balances[msg.sender] -= amount;
    balances[to] += amount;
}
```

**Attack Flow:**
1. Call withdraw(100)
2. During ETH transfer callback, call transfer(attacker2, 100)
3. Balance is still 100, so transfer succeeds
4. Then withdraw completes, subtracting balance
5. Result: Withdrew 100 + transferred 100 with only 100 balance

**Why It's Dangerous:**
- Each function individually looks safe (updates state)
- The vulnerability emerges from SHARED state
- Harder to detect with basic pattern matching

### 3. Cross-Contract Reentrancy

Reentering Contract A through Contract B:

```
User → ContractA.deposit()
  → ContractB.callback()
    → ContractA.withdraw()  // Reentrancy!
```

**Example Scenario:**
```solidity
// Vault contract
function deposit() external payable {
    balances[msg.sender] += msg.value;
    // Notify rewards contract
    rewardsContract.notifyDeposit(msg.sender, msg.value);
}

// Rewards contract
function notifyDeposit(address user, uint amount) external {
    // Attacker's receive() function can now call Vault.withdraw()
    (bool success,) = user.call("");
}
```

**Attack Flow:**
1. Attacker calls Vault.deposit()
2. Vault updates balance, then calls Rewards.notifyDeposit()
3. Rewards calls attacker's contract
4. Attacker's receive() calls Vault.withdraw()
5. Vault balance hasn't been "locked" yet
6. Withdraw succeeds, then deposit completes

**Why It's Dangerous:**
- State updates happen in correct order WITHIN each contract
- The reentrancy path goes through an external contract
- Traditional mutex guards might not catch it
- Requires analyzing entire call graph

### 4. Read-Only Reentrancy

Exploiting inconsistent state visible through VIEW functions:

```solidity
contract Vault {
    uint public totalSupply;
    mapping(address => uint) public balances;

    function withdraw(uint amount) external {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount; // Updated
        (bool success,) = msg.sender.call{value: amount}("");
        require(success);
        totalSupply -= amount; // NOT YET UPDATED during callback
    }

    function getPrice() public view returns (uint) {
        return (address(this).balance * 1e18) / totalSupply;
    }
}

contract Oracle {
    function getVaultPrice() external view returns (uint) {
        return vault.getPrice(); // Uses inconsistent state!
    }
}
```

**Attack Flow:**
1. Vault has 100 ETH, 100 totalSupply (price = 1 ETH)
2. Attacker calls withdraw(50)
3. Vault updates balances[attacker] (50 → 0)
4. Vault sends 50 ETH to attacker
5. During callback, attacker calls Oracle.getVaultPrice()
6. Vault balance = 50 ETH, but totalSupply still = 100
7. Oracle returns price = 0.5 ETH (WRONG!)
8. Attacker uses this to exploit lending protocol, etc.

**Why It's Dangerous:**
- No state is being WRITTEN during reentrancy
- View functions seem "safe"
- Leads to oracle manipulation attacks
- Cream Finance lost $130M to this in 2021

### 5. Multi-Hop Reentrancy Chains

Creating complex call chains: A → B → C → A

```
1. User calls ContractA.action()
2. ContractA calls ContractB.process()
3. ContractB calls ContractC.verify()
4. ContractC triggers callback to User
5. User reenters ContractA.action() again
```

**Why It's Dangerous:**
- Each individual hop might be "safe"
- The vulnerability emerges from the CHAIN
- Extremely difficult to audit
- Can bypass per-contract reentrancy guards

## Real-World Case Studies

### Case Study 1: The DAO (2016)

**Amount Lost:** $60 million (3.6M ETH)

**Vulnerability:** Basic single-function reentrancy

**Code:**
```solidity
function withdraw(uint _amount) {
    if (balances[msg.sender] >= _amount) {
        if (msg.sender.call.value(_amount)()) {
            balances[msg.sender] -= _amount;
        }
    }
}
```

**Impact:**
- Led to Ethereum hard fork (ETH/ETC split)
- Changed smart contract security forever
- Introduced Checks-Effects-Interactions pattern

### Case Study 2: Cream Finance (2021)

**Amount Lost:** $130 million

**Vulnerability:** Read-only reentrancy via ERC777 tokens

**Attack Flow:**
1. Cream used Curve LP tokens as collateral
2. Curve's `balanceOf()` could be reentered via ERC777 hooks
3. During withdrawal, balances were inconsistent
4. Attacker borrowed against inflated collateral value
5. Drained multiple pools

**Key Insight:** View functions can be exploited if they read inconsistent state!

### Case Study 3: Curve/Vyper Reentrancy (2023)

**Amount Lost:** $52 million

**Vulnerability:** Vyper compiler bug - reentrancy guards ineffective

**Details:**
- Vyper 0.2.15-0.3.0 had broken reentrancy guards
- Multiple Curve pools affected
- Even "protected" functions were vulnerable
- Never trust compiler features blindly

### Case Study 4: Lendf.Me (2020)

**Amount Lost:** $25 million

**Vulnerability:** ERC777 reentrancy during supply/borrow

**Attack Pattern:**
```
1. Supply ERC777 tokens as collateral
2. During supply callback, borrow against the collateral
3. Collateral not yet fully recorded
4. Over-borrow beyond collateral value
```

**Lesson:** Be extremely careful with tokens that have hooks (ERC777, ERC1155)

## Defense Strategies

### Level 1: Checks-Effects-Interactions (CEI)

The foundational pattern:

```solidity
function withdraw(uint amount) external {
    // CHECKS
    require(balances[msg.sender] >= amount);

    // EFFECTS
    balances[msg.sender] -= amount;
    totalSupply -= amount; // Update ALL state!

    // INTERACTIONS
    (bool success,) = msg.sender.call{value: amount}("");
    require(success);
}
```

**Limitations:**
- Only protects single function
- Doesn't prevent cross-function reentrancy
- Doesn't prevent read-only reentrancy

### Level 2: Reentrancy Guards (Mutex)

```solidity
uint private _status = 1; // 1 = NOT_ENTERED, 2 = ENTERED

modifier nonReentrant() {
    require(_status != 2, "ReentrancyGuard: reentrant call");
    _status = 2;
    _;
    _status = 1;
}

function withdraw(uint amount) external nonReentrant {
    // Function body
}
```

**Advantages:**
- Protects against cross-function reentrancy
- Simple to implement
- Gas efficient

**Limitations:**
- Must be applied to ALL vulnerable functions
- Doesn't prevent cross-contract reentrancy
- Doesn't prevent read-only reentrancy

### Level 3: Pull Payment Pattern

```solidity
mapping(address => uint) public pendingWithdrawals;

function withdraw(uint amount) external {
    require(balances[msg.sender] >= amount);
    balances[msg.sender] -= amount;
    pendingWithdrawals[msg.sender] += amount;
}

function claimWithdrawal() external {
    uint amount = pendingWithdrawals[msg.sender];
    pendingWithdrawals[msg.sender] = 0;
    (bool success,) = msg.sender.call{value: amount}("");
    require(success);
}
```

**Advantages:**
- Completely isolates state changes from external calls
- Users pull funds rather than contract pushing

**Limitations:**
- Requires two transactions
- More gas for users
- Doesn't prevent read-only reentrancy

### Level 4: Global Reentrancy Guard

For cross-contract reentrancy:

```solidity
contract ReentrancyGuardRegistry {
    mapping(address => bool) public locked;

    modifier globalGuard() {
        require(!locked[tx.origin], "Global reentrancy");
        locked[tx.origin] = true;
        _;
        locked[tx.origin] = false;
    }
}

// Both contracts use the same registry
contract VaultA {
    function action() external globalGuard {
        // Safe from cross-contract reentrancy
    }
}

contract VaultB {
    function action() external globalGuard {
        // Safe from cross-contract reentrancy
    }
}
```

**Advantages:**
- Protects entire ecosystem
- Catches cross-contract attacks

**Limitations:**
- Complex to implement
- Still doesn't prevent read-only reentrancy
- Can block legitimate multi-contract interactions

### Level 5: Read-Only Reentrancy Protection

```solidity
uint private _status = 1;

modifier nonReentrant() {
    require(_status != 2);
    _status = 2;
    _;
    _status = 1;
}

modifier nonReentrantView() {
    require(_status != 2, "Cannot read during reentrancy");
    _;
}

function withdraw(uint amount) external nonReentrant {
    balances[msg.sender] -= amount;
    totalSupply -= amount; // CRITICAL: Update before external call
    (bool success,) = msg.sender.call{value: amount}("");
    require(success);
}

function getPrice() public view nonReentrantView returns (uint) {
    return (address(this).balance * 1e18) / totalSupply;
}
```

**Key Points:**
- View functions check the guard too
- All state must be consistent before external calls
- Prevents oracle manipulation

### Level 6: The Ultimate Pattern

Combining all strategies:

```solidity
contract SecureVault is ReentrancyGuard {
    using SafeERC20 for IERC20;

    mapping(address => uint) private _balances; // Private to enforce getter
    uint private _totalSupply;

    // WRITE operations
    function withdraw(uint amount) external nonReentrant {
        // CHECKS
        require(_balances[msg.sender] >= amount, "Insufficient balance");

        // EFFECTS - Update ALL state first
        _balances[msg.sender] -= amount;
        _totalSupply -= amount;

        // INTERACTIONS - External calls last
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    // READ operations - protected view
    function balanceOf(address account) external view nonReentrantView returns (uint) {
        return _balances[account];
    }

    function totalSupply() external view nonReentrantView returns (uint) {
        return _totalSupply;
    }

    function getPrice() external view nonReentrantView returns (uint) {
        if (_totalSupply == 0) return 0;
        return (address(this).balance * 1e18) / _totalSupply;
    }
}
```

## Lab Exercises

### Exercise 1: Multi-Function Reentrancy

**Goal:** Exploit the Bank contract by reentering through transfer() during withdraw()

**Vulnerable Contract:** `VulnerableBank` in Project31.sol

**Task:**
1. Study how withdraw() and transfer() share the `balances` mapping
2. Create an attacker contract that:
   - Calls withdraw()
   - During the callback, calls transfer() to move funds
   - Extracts more value than deposited
3. Write a test demonstrating the exploit

### Exercise 2: Cross-Contract Reentrancy

**Goal:** Exploit the Vault through the Router contract

**Vulnerable Contracts:** `VulnerableVault` and `RewardsRouter`

**Task:**
1. Understand the deposit → notifyRewards → callback chain
2. Create an attacker that reenters vault during rewards notification
3. Drain funds using cross-contract reentrancy

### Exercise 3: Read-Only Reentrancy

**Goal:** Manipulate the Oracle by exploiting view functions during reentrancy

**Vulnerable Contract:** `VulnerableOracle`

**Task:**
1. Identify inconsistent state windows
2. Create an attack that exploits getPrice() during withdrawal
3. Use the manipulated price to profit in a lending scenario

### Exercise 4: Multi-Hop Chain

**Goal:** Build a complex A → B → C → A attack chain

**Task:**
1. Create a 3-hop reentrancy path
2. Demonstrate how single-contract guards fail
3. Show the entire call stack

### Exercise 5: Fix Everything

**Goal:** Secure all contracts against advanced reentrancy

**Task:**
1. Apply appropriate guards
2. Implement CEI pattern correctly
3. Protect view functions
4. Write tests proving security

## Running the Lab

```bash
# Install dependencies
forge install

# Run all tests
forge test -vvv

# Run specific test
forge test --match-test testMultiFunctionReentrancy -vvvv

# See gas costs
forge test --gas-report

# Deploy locally
forge script script/DeployProject31.s.sol --fork-url http://localhost:8545 --broadcast
```

## Key Takeaways

1. **Reentrancy is not just about one function** - Consider the entire contract state
2. **View functions can be exploited** - Read-only reentrancy is real
3. **Cross-contract interactions are dangerous** - Think about the entire call graph
4. **Defense in depth** - Use multiple protection layers
5. **Test everything** - Write comprehensive attack simulations
6. **Real audits matter** - These vulnerabilities are subtle

## Advanced Topics

### Gas Optimization vs Security

Reentrancy guards cost gas. When is the tradeoff worth it?

```solidity
// More gas, more secure
function withdraw(uint amount) external nonReentrant {
    // ...
}

// Less gas, requires perfect CEI
function withdraw(uint amount) external {
    // Must be perfect...
}
```

### Reentrancy in DeFi Protocols

- **AMMs:** Price manipulation via read-only reentrancy
- **Lending:** Collateral valuation attacks
- **Yield Farms:** Reward calculation exploits
- **Bridges:** Cross-chain reentrancy (even more complex!)

### Future Threats

- **Account Abstraction:** New reentrancy vectors via ERC-4337
- **Cross-chain:** Reentrancy across different chains
- **MEV:** Reentrancy combined with sandwich attacks
- **AI-discovered exploits:** Automated vulnerability finding

## Resources

- [Consensys Smart Contract Best Practices](https://consensys.github.io/smart-contract-best-practices/)
- [SWC-107: Reentrancy](https://swcregistry.io/docs/SWC-107)
- [Curve Read-Only Reentrancy Analysis](https://chainsecurity.com/curve-lp-oracle-manipulation-post-mortem/)
- [OpenZeppelin ReentrancyGuard](https://docs.openzeppelin.com/contracts/4.x/api/security#ReentrancyGuard)

## Conclusion

Advanced reentrancy attacks are among the most dangerous vulnerabilities in smart contracts. Understanding these patterns is essential for:

- Writing secure contracts
- Auditing DeFi protocols
- Designing safe cross-contract interactions
- Building robust oracle systems

Master these concepts, and you'll be well-equipped to handle real-world smart contract security.

---


## 32-overflow-lab

# Project 32: Integer Overflow Labs (Pre-0.8)

## Overview

This project explores one of the most critical vulnerabilities in early Solidity: **integer overflow and underflow**. Before Solidity 0.8.0, arithmetic operations would silently wrap around on overflow/underflow, leading to catastrophic exploits. This lab teaches you how these vulnerabilities worked, why they were dangerous, and how Solidity evolved to prevent them.

## Table of Contents

1. [Understanding Integer Overflow/Underflow](#understanding-integer-overflowunderflow)
2. [Pre-0.8.0 Behavior](#pre-080-behavior)
3. [The Solidity 0.8.0 Revolution](#the-solidity-080-revolution)
4. [SafeMath Library Pattern](#safemath-library-pattern)
5. [Historical Exploits](#historical-exploits)
6. [Unchecked Blocks in 0.8+](#unchecked-blocks-in-08)
7. [When Unchecked is Safe vs Dangerous](#when-unchecked-is-safe-vs-dangerous)
8. [Learning Objectives](#learning-objectives)
9. [Getting Started](#getting-started)

## Understanding Integer Overflow/Underflow: The Silent Wraparound Bug

**FIRST PRINCIPLES: Fixed-Width Integer Arithmetic**

Integer overflow/underflow occurs when arithmetic operations exceed the representable range. Understanding this is critical for secure Solidity development!

**CONNECTION TO PROJECT 01**:
We learned about `uint256` types in Project 01. Understanding their limits and overflow behavior is essential!

### What is Integer Overflow?

**UNDERSTANDING THE CONCEPT** (DSA/Computer Science):

Integer overflow occurs when an arithmetic operation attempts to create a numeric value outside the range that can be represented with a given number of bits.

**HOW IT WORKS**:

For `uint8` (0 to 255, 8 bits):
```
Binary Representation:
255 = 11111111 (8 bits, all 1s)
255 + 1 = 100000000 (9 bits) → Wraps to 00000000 = 0

Examples:
255 + 1 = 0   (overflow wraps around)
255 + 2 = 1
255 + 10 = 9
```

For `uint256` (0 to 2^256 - 1):
```
2^256 - 1 = 0xFFFF...FFFF (256 bits, all 1s)
2^256 - 1 + 1 = 0x10000...0000 (257 bits) → Wraps to 0x0000...0000 = 0

Example:
type(uint256).max + 1 = 0  (overflow wraps around)
```

**UNDERSTANDING BINARY ARITHMETIC** (DSA Concept):

```
8-bit Addition Example:
  11111111  (255)
+ 00000001  (1)
-----------
 100000000  (256, but only 8 bits stored!)
           ↓
  00000000  (0, wraps around!)
```

### What is Integer Underflow?

**UNDERSTANDING THE CONCEPT**:

Underflow is the opposite - when subtraction goes below the minimum value:

For `uint8` (0 to 255):
```
Binary Representation:
0 = 00000000 (8 bits, all 0s)
0 - 1 = 11111111 (borrow wraps around) = 255

Examples:
0 - 1 = 255  (underflow wraps around)
0 - 2 = 254
```

For `uint256`:
```
0 - 1 = 2^256 - 1  (a VERY large number!)
// This is type(uint256).max
```

**WHY THIS IS DANGEROUS**:

In financial smart contracts, these wrapping behaviors can be catastrophic:

1. **Balance Manipulation**: User with 0 tokens calls transfer(1) → balance becomes 2^256-1 tokens
   ```solidity
   // Pre-0.8.0: Silent underflow!
   balances[user] = 0;
   balances[user] -= 1;  // 0 - 1 = 2^256 - 1 (massive balance!)
   ```

2. **Access Control Bypass**: Counter expected to increase may wrap to 0
   ```solidity
   // Pre-0.8.0: Silent overflow!
   uint8 counter = 255;
   counter++;  // 255 + 1 = 0 (bypasses check!)
   ```

3. **Time Lock Bypass**: timestamp + delay might overflow to past timestamp
   ```solidity
   // Pre-0.8.0: Silent overflow!
   uint256 unlockTime = type(uint256).max;
   unlockTime += 1 day;  // Overflows to small number (immediate unlock!)
   ```

4. **Supply Manipulation**: Total supply calculations can be manipulated
   ```solidity
   // Pre-0.8.0: Silent overflow!
   totalSupply = type(uint256).max;
   totalSupply += 1;  // Wraps to 0 (supply reset!)
   ```

**HISTORICAL CONTEXT**: 
Before Solidity 0.8.0 (February 2021), ALL arithmetic silently wrapped. This led to major exploits. Solidity 0.8.0+ automatically checks for overflow/underflow and reverts!

**COMPARISON TO RUST** (DSA Concept):

**Rust** (checked arithmetic):
```rust
// Rust checks overflow by default (panics in debug, wraps in release)
let x: u8 = 255;
let y = x + 1;  // Panic in debug mode!
```

**Solidity 0.8.0+** (checked arithmetic):
```solidity
uint8 x = 255;
uint8 y = x + 1;  // Reverts transaction!
```

Both languages now protect against overflow by default!

## Pre-0.8.0 Behavior

Before Solidity 0.8.0 (released February 2021), **all arithmetic operations silently wrapped**:

```solidity
// Solidity 0.7.6 and earlier
contract VulnerableToken {
    mapping(address => uint256) public balances;

    function transfer(address to, uint256 amount) public {
        balances[msg.sender] -= amount;  // Can underflow!
        balances[to] += amount;           // Can overflow!
    }
}
```

**Attack scenario:**
1. Attacker has 0 tokens
2. Calls `transfer(victim, 1)`
3. `balances[attacker] = 0 - 1 = 2^256 - 1`
4. Attacker now has maximum uint256 tokens

## The Solidity 0.8.0 Revolution

Solidity 0.8.0 introduced **automatic overflow/underflow checking**:

```solidity
// Solidity 0.8.0+
contract SafeToken {
    mapping(address => uint256) public balances;

    function transfer(address to, uint256 amount) public {
        balances[msg.sender] -= amount;  // Reverts on underflow!
        balances[to] += amount;           // Reverts on overflow!
    }
}
```

### Key Changes in 0.8.0

1. **Automatic Checks**: All arithmetic operations check for overflow/underflow
2. **Reverts on Error**: Operations revert instead of wrapping
3. **No Gas Cost Increase**: Compiler optimizations made this efficient
4. **Breaking Change**: Old contracts needed review before upgrading

### Checked Operations

These operations are now checked in 0.8.0+:
- Addition: `a + b`
- Subtraction: `a - b`
- Multiplication: `a * b`
- Division: `a / b` (also checks division by zero)
- Modulo: `a % b` (also checks modulo by zero)
- Unary minus: `-a`
- Increment/Decrement: `++a`, `a++`, `--a`, `a--`

## SafeMath Library Pattern

Before 0.8.0, developers used the **SafeMath library** to protect against overflows:

```solidity
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction underflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
}
```

### Usage Pattern

```solidity
using SafeMath for uint256;

function transfer(address to, uint256 amount) public {
    balances[msg.sender] = balances[msg.sender].sub(amount);
    balances[to] = balances[to].add(amount);
}
```

### SafeMath in 0.8.0+

**SafeMath is no longer needed in Solidity 0.8.0+** because:
1. Built-in checks are automatic
2. Built-in checks are more gas efficient
3. Error messages are clearer with custom errors

However, understanding SafeMath is important for:
- Reading older contracts
- Understanding the history of Solidity security
- Auditing legacy code

## Historical Exploits

### 1. PoWHC Token (2018)

**The Bug:**
```solidity
function sell(uint256 _amountOfTokens) {
    uint256 _tokens = _amountOfTokens;
    uint256 _ethereum = tokensToEthereum_(_tokens);
    uint256 _dividends = SafeMath.div(_ethereum, dividendFee_); // = 3
    uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);

    // Underflow vulnerability
    tokenBalanceLedger_[msg.sender] =
        SafeMath.sub(tokenBalanceLedger_[msg.sender], _tokens);
}
```

**The Attack:**
- Attacker called `sell()` with amount > balance
- SafeMath checked the subtraction, BUT...
- The check happened AFTER dividend calculation
- Attacker could manipulate order of operations
- **Loss**: $866,000 in Ether

### 2. BeautyChain (BEC) Token (2018)

**The Bug:**
```solidity
function batchTransfer(address[] _receivers, uint256 _value) public {
    uint256 cnt = _receivers.length;
    uint256 amount = uint256(cnt) * _value;  // OVERFLOW!
    require(balances[msg.sender] >= amount);

    for (uint i = 0; i < cnt; i++) {
        balances[_receivers[i]] += _value;
    }
    balances[msg.sender] -= amount;
}
```

**The Attack:**
- Attacker passed large `_value` and 2 receivers
- `cnt * _value` overflowed to small number
- Passed balance check
- Created tokens out of thin air
- **Impact**: Trading halted on all exchanges, $1B market cap lost

### 3. SMT Token Overflow (2018)

**Similar batch transfer vulnerability:**
```solidity
function transferProxy(
    address _from,
    address _to,
    uint256 _value,
    uint256 _fee
) public returns (bool) {
    uint256 _total = _value + _fee;  // OVERFLOW!
    require(balances[_from] >= _total);
    // ... transfer logic
}
```

**The Attack:**
- Set `_value` and `_fee` such that `_value + _fee` overflows
- Result is small number, passes check
- Transferred large amounts without sufficient balance

## Unchecked Blocks in 0.8+

Solidity 0.8.0+ introduced the `unchecked` keyword to **opt-out** of automatic checks:

```solidity
function example() public pure returns (uint256) {
    uint256 x = 0;

    unchecked {
        x = x - 1;  // No revert, wraps to 2^256-1
    }

    return x;
}
```

### Why Use Unchecked?

1. **Gas Optimization**: Skip checks when overflow/underflow is mathematically impossible
2. **Intentional Wrapping**: Some algorithms require wrapping behavior
3. **Performance**: In tight loops with proven safety

### Gas Savings Example

```solidity
// More expensive (checked)
function sumChecked(uint256[] calldata values) public pure returns (uint256) {
    uint256 sum = 0;
    for (uint256 i = 0; i < values.length; i++) {
        sum += values[i];
    }
    return sum;
}

// Cheaper (unchecked iterator)
function sumUnchecked(uint256[] calldata values) public pure returns (uint256) {
    uint256 sum = 0;
    for (uint256 i = 0; i < values.length;) {
        sum += values[i];
        unchecked { i++; }  // i can never overflow in practice
    }
    return sum;
}
```

## When Unchecked is Safe vs Dangerous

### ✅ Safe Uses of Unchecked

#### 1. Loop Counters (Most Common)

```solidity
for (uint256 i = 0; i < array.length;) {
    // ... process array[i]
    unchecked { i++; }  // Safe: i < array.length, can't overflow
}
```

**Why safe**: Loop bounds ensure counter can't reach max value

#### 2. Known Bounds

```solidity
function calculateDiscount(uint256 price) public pure returns (uint256) {
    // Price capped at 100, discount is 10%
    require(price <= 100);
    unchecked {
        return price - (price / 10);  // Safe: price >= price/10 always
    }
}
```

**Why safe**: Mathematical proof that overflow/underflow can't occur

#### 3. After Explicit Checks

```solidity
function safeSub(uint256 a, uint256 b) public pure returns (uint256) {
    require(a >= b, "Underflow");
    unchecked {
        return a - b;  // Safe: we just checked a >= b
    }
}
```

**Why safe**: Explicit require prevents underflow

#### 4. Intentional Wrapping (Advanced)

```solidity
function hash(uint256 a, uint256 b) public pure returns (uint256) {
    unchecked {
        // Intentional wrapping for hash calculation
        return (a * 31) + b;
    }
}
```

**Why safe**: Wrapping is intentional for the algorithm

### ❌ Dangerous Uses of Unchecked

#### 1. User-Controlled Values

```solidity
// DANGEROUS!
function transfer(address to, uint256 amount) public {
    unchecked {
        balances[msg.sender] -= amount;  // Can underflow!
        balances[to] += amount;           // Can overflow!
    }
}
```

**Why dangerous**: User controls `amount`, can exploit wrapping

#### 2. External Data

```solidity
// DANGEROUS!
function processPrice(uint256 externalPrice) public {
    unchecked {
        uint256 total = externalPrice * quantity;  // Can overflow!
    }
}
```

**Why dangerous**: External data is untrusted

#### 3. Financial Calculations

```solidity
// DANGEROUS!
function calculateReward(uint256 stake, uint256 multiplier) public {
    unchecked {
        uint256 reward = stake * multiplier;  // Can overflow!
        rewards[msg.sender] += reward;
    }
}
```

**Why dangerous**: Financial calculations must never wrap

#### 4. Timestamp Arithmetic

```solidity
// DANGEROUS!
function setUnlockTime(uint256 delay) public {
    unchecked {
        unlockTime = block.timestamp + delay;  // Can overflow!
    }
}
```

**Why dangerous**: Could wrap to past timestamp, bypassing time lock

### Decision Flowchart

```
Should I use unchecked?
│
├─ Are values user-controlled?
│  └─ YES → ❌ DON'T use unchecked
│
├─ Is this a financial calculation?
│  └─ YES → ❌ DON'T use unchecked
│
├─ Can I mathematically prove no overflow?
│  ├─ NO → ❌ DON'T use unchecked
│  └─ YES ↓
│
├─ Is gas optimization critical here?
│  ├─ NO → ❌ DON'T use unchecked (keep safety)
│  └─ YES → ✅ Consider unchecked (document why!)
│
└─ ALWAYS document why unchecked is safe!
```

## Learning Objectives

By completing this project, you will:

1. ✅ Understand how integer overflow/underflow worked in pre-0.8.0 Solidity
2. ✅ Learn why these vulnerabilities were so dangerous
3. ✅ Implement SafeMath library from scratch
4. ✅ Understand the security improvements in Solidity 0.8.0+
5. ✅ Know when unchecked blocks are safe vs dangerous
6. ✅ Be able to audit legacy contracts for overflow vulnerabilities
7. ✅ Make informed decisions about gas optimization vs safety

## Getting Started

### Prerequisites

- Foundry installed
- Understanding of Solidity basics
- Familiarity with arithmetic operations

### Setup

```bash
# Navigate to project directory
cd 32-overflow-lab

# Install dependencies
forge install

# Run tests
forge test

# Run tests with verbosity
forge test -vvv

# Run specific test
forge test --match-test testOverflowExploit -vvv
```

### Project Structure

```
32-overflow-lab/
├── README.md                          # This file
├── src/
│   ├── Project32.sol                  # Skeleton with TODOs
│   └── solution/
│       └── Project32Solution.sol      # Complete solution
├── test/
│   └── Project32.t.sol               # Comprehensive tests
└── script/
    └── DeployProject32.s.sol         # Deployment script
```

### Learning Path

1. **Read this README** thoroughly
2. **Study the solution** (`src/solution/OverflowLabSolution.sol`)

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/OverflowLabSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployOverflowLabSolution.s.sol` - Deployment script patterns
- `test/solution/OverflowLabSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains integer overflow/underflow, arithmetic safety, unchecked blocks
- **Connections to Project 01**: Arithmetic operations and overflow protection
- **Real-World Context**: Solidity 0.8.0+ automatically checks, but understanding is critical

3. **Run the tests** to see exploits in action
4. **Complete the TODOs** in `src/Project32.sol`
5. **Experiment** with different overflow scenarios
6. **Write additional tests** for edge cases

## Key Takeaways

### For Modern Development (0.8.0+)

1. ✅ **Default behavior is safe** - rely on automatic checks
2. ✅ **Only use unchecked when proven safe** - document why
3. ✅ **Optimize loop counters** - common safe use of unchecked
4. ✅ **Never use unchecked for user input** - always validate first

### For Auditing Legacy Code

1. 🔍 **Check Solidity version** - pre-0.8.0 is vulnerable
2. 🔍 **Look for SafeMath usage** - is it used consistently?
3. 🔍 **Verify all arithmetic** - especially in transfers and calculations
4. 🔍 **Test edge cases** - max values, zero, boundary conditions

### Historical Perspective

1. 📚 **SafeMath was standard** - understanding it is important
2. 📚 **Many exploits occurred** - real money was lost
3. 📚 **0.8.0 was revolutionary** - changed smart contract security
4. 📚 **Still relevant today** - legacy contracts exist, unchecked is available

## Additional Resources

- [Solidity 0.8.0 Release Notes](https://blog.soliditylang.org/2020/12/16/solidity-0.8.0-release-announcement/)
- [OpenZeppelin SafeMath](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/math/SafeMath.sol)
- [SWC-101: Integer Overflow and Underflow](https://swcregistry.io/docs/SWC-101)
- [BeautyChain Exploit Analysis](https://medium.com/@peckshield/alert-new-batchoverflow-bug-in-multiple-erc20-smart-contracts-cve-2018-10299-511067db6536)

## Practice Exercises

1. **Reproduce Historical Exploits**: Use the test file to recreate real exploits
2. **Build SafeMath**: Implement all SafeMath operations from scratch
3. **Find Vulnerabilities**: Identify vulnerable patterns in example contracts
4. **Safe Unchecked Usage**: Write functions that safely use unchecked blocks
5. **Gas Optimization**: Compare gas costs of checked vs unchecked operations

## Security Checklist

When reviewing code for overflow vulnerabilities:

- [ ] Check Solidity version (< 0.8.0 is vulnerable by default)
- [ ] Verify SafeMath usage in legacy contracts
- [ ] Audit all arithmetic operations
- [ ] Test with boundary values (0, max uint256, etc.)
- [ ] Review unchecked blocks for safety
- [ ] Ensure financial calculations are never unchecked
- [ ] Validate user input before arithmetic
- [ ] Consider upgrade path for legacy contracts

---

**Remember**: Integer overflow/underflow was one of the most common and dangerous vulnerabilities in early Solidity. While 0.8.0+ provides automatic protection, understanding this vulnerability is crucial for:
- Auditing existing contracts
- Making informed decisions about unchecked blocks
- Appreciating the evolution of smart contract security

Happy learning! 🔐

---


## 33-mev-frontrunning

# Project 33: MEV & Front-Running Simulation

## Overview

This project provides an in-depth exploration of **MEV (Maximal Extractable Value)**, front-running, and sandwich attacks in Ethereum and EVM-compatible blockchains. You'll learn how these attacks work, how to simulate them, and most importantly, how to protect against them.

## Table of Contents

1. [What is MEV?](#what-is-mev)
2. [Front-Running Mechanics](#front-running-mechanics)
3. [Sandwich Attack Anatomy](#sandwich-attack-anatomy)
4. [Mempool Observation](#mempool-observation)
5. [Attack Simulations](#attack-simulations)
6. [Protection Mechanisms](#protection-mechanisms)
7. [Real-World MEV Examples](#real-world-mev-examples)
8. [Learning Objectives](#learning-objectives)
9. [Project Structure](#project-structure)
10. [Getting Started](#getting-started)

---

## What is MEV? Maximal Extractable Value

**FIRST PRINCIPLES: Transaction Ordering and Value Extraction**

**MEV (Maximal Extractable Value)**, formerly known as "Miner Extractable Value," is the maximum value that can be extracted from block production beyond the standard block reward and gas fees.

**CONNECTION TO PROJECT 02 & 07**:
- **Project 02**: We learned about transactions and gas
- **Project 07**: We learned about reentrancy (one type of MEV)
- **Project 33**: MEV is broader - exploiting transaction ordering!

### Why MEV Exists

**UNDERSTANDING THE ROOT CAUSES**:

MEV exists due to the following characteristics of blockchain systems:

1. **Public Mempool**: Transactions are publicly visible before inclusion in a block
   - Anyone can see pending transactions
   - Attackers can observe and react
   - From Project 02: Transactions are public before execution!

2. **Transaction Ordering**: Block producers (miners/validators) can order transactions arbitrarily
   - Can reorder transactions within a block
   - Can exclude transactions
   - Creates opportunities for value extraction

3. **Deterministic Execution**: Smart contract behavior is predictable
   - Can simulate transaction outcomes
   - Can predict price changes
   - Enables strategic positioning

4. **Latency**: Network propagation creates timing opportunities
   - Transactions propagate across network
   - Time window for observation
   - Can submit competing transactions

**UNDERSTANDING THE MEV LANDSCAPE**:

```
MEV Extraction Flow:
┌─────────────────────────────────────────┐
│ 1. User submits transaction             │
│    (e.g., large DEX swap)               │
│   ↓                                      │
│ 2. Transaction enters mempool           │ ← Public visibility
│   ↓                                      │
│ 3. Searcher observes transaction        │ ← MEV opportunity identified
│   ↓                                      │
│ 4. Searcher calculates profit           │ ← Predictable outcome
│   ↓                                      │
│ 5. Searcher submits front-run           │ ← Higher gas price
│   ↓                                      │
│ 6. Block producer orders transactions   │ ← Arbitrary ordering
│    [Front-run, User TX, Back-run]      │
│   ↓                                      │
│ 7. Searcher extracts value              │ ← MEV captured!
└─────────────────────────────────────────┘
```

**REAL-WORLD ANALOGY**: 
Like insider trading in traditional markets:
- **Public Mempool** = Public order book (visible to all)
- **Transaction Ordering** = Exchange can prioritize orders
- **MEV** = Exploiting information advantage
- **Difference**: MEV is legal (by design), insider trading is illegal

### Types of MEV

1. **Front-Running**: Placing a transaction before a target transaction
2. **Back-Running**: Placing a transaction immediately after a target transaction
3. **Sandwich Attacks**: Front-running + back-running a target transaction
4. **Liquidations**: Racing to liquidate under-collateralized positions
5. **Arbitrage**: Exploiting price differences across DEXs
6. **Time-Bandit Attacks**: Reordering historical blocks (theoretical)

### MEV Value Chain

```
┌─────────────────┐
│   Searcher      │  Identifies MEV opportunities
└────────┬────────┘
         │
┌────────▼────────┐
│   Builder       │  Constructs optimized blocks
└────────┬────────┘
         │
┌────────▼────────┐
│   Proposer      │  Proposes blocks to network
└─────────────────┘
```

---

## Front-Running Mechanics

Front-running occurs when an attacker observes a pending transaction and submits their own transaction with a higher gas price to be executed first.

### How Front-Running Works

```
Timeline:
1. User submits TX1 (gas price: 50 gwei)
2. Attacker sees TX1 in mempool
3. Attacker submits TX2 (gas price: 100 gwei)
4. Block is mined: [TX2, TX1]  ← Attacker's transaction executed first
5. Attacker profits from executing before user
```

### Front-Running Attack Scenarios

#### 1. Auction Sniping
```solidity
// User places bid
auction.bid{value: 100 ether}();

// Attacker front-runs with slightly higher bid
auction.bid{value: 100.1 ether}();  // Executed first
```

#### 2. Price Oracle Manipulation
```solidity
// User initiates oracle update
oracle.updatePrice(newPrice);

// Attacker trades before price update
dex.swap(tokenA, tokenB);  // Profits from old price
```

#### 3. Token Purchase Front-Running
```solidity
// User tries to buy token at current price
dex.buyToken(amount);

// Attacker front-runs, driving up price
dex.buyToken(largeAmount);  // User pays more
```

### Gas Price Wars

Front-running often leads to gas price auctions:

```
Original TX:   50 gwei
Front-runner:  60 gwei
Counter:       70 gwei
Counter:       80 gwei
...
Result: Massive gas costs, failed transactions
```

---

## Sandwich Attack Anatomy

A sandwich attack combines front-running and back-running to profit from a victim's transaction.

### Attack Structure

```
Block Structure:
┌──────────────────────────────┐
│  TX1: Attacker Buy (Front)   │  ← Push price up
├──────────────────────────────┤
│  TX2: Victim Buy             │  ← Victim pays inflated price
├──────────────────────────────┤
│  TX3: Attacker Sell (Back)   │  ← Profit from price increase
└──────────────────────────────┘
```

### Step-by-Step Sandwich Attack

**Setup**: DEX with AMM (Automated Market Maker)

```
Initial State:
- Pool: 100 ETH / 10,000 USDC
- Price: 1 ETH = 100 USDC

Step 1: Victim submits buy order (10 ETH for USDC)
- Visible in mempool
- Slippage tolerance: 5%

Step 2: Attacker Front-Runs
- Buys 5 ETH for ~476 USDC
- New pool: 105 ETH / 9,524 USDC
- New price: 1 ETH ≈ 90.7 USDC

Step 3: Victim's Transaction Executes
- Buys 10 ETH for ~1,111 USDC (inflated price)
- New pool: 115 ETH / 8,413 USDC
- New price: 1 ETH ≈ 73.2 USDC

Step 4: Attacker Back-Runs
- Sells 5 ETH for ~405 USDC
- Profit: 405 - 476 = -71 USDC

Wait, let me recalculate...
Actually the attacker profits when the victim BUYS tokens:

Correct Example:
Initial: 10,000 USDC / 100 ETH (1 ETH = 100 USDC)

Victim wants to BUY 100 USDC worth of ETH

Step 1: Attacker Front-Run (Buy ETH)
- Buy 0.5 ETH for ~50 USDC
- New: 9,950 USDC / 99.5 ETH

Step 2: Victim Executes (Buy ETH)
- Buys at inflated price
- Gets less ETH than expected

Step 3: Attacker Back-Run (Sell ETH)
- Sells 0.5 ETH back
- Gets more USDC than spent
- Profit extracted
```

### Sandwich Attack Requirements

1. **Sufficient Liquidity**: Attacker needs capital
2. **Price Impact**: Victim's trade must move the price
3. **Slippage Tolerance**: Victim's slippage allows the attack
4. **Gas Control**: Attacker can control transaction ordering

### Mathematical Model

For constant product AMM (x * y = k):

```
Profit = BackRunRevenue - FrontRunCost - GasCosts

Where:
- FrontRunCost = Amount paid to push price up
- BackRunRevenue = Amount received selling at inflated price
- GasCosts = Gas for both transactions
```

---

## Mempool Observation

The mempool is where pending transactions wait for inclusion in blocks.

### Mempool Characteristics

```
┌─────────────────────────────────────┐
│           Public Mempool            │
│                                     │
│  ┌─────┐  ┌─────┐  ┌─────┐        │
│  │ TX1 │  │ TX2 │  │ TX3 │  ...   │
│  └─────┘  └─────┘  └─────┘        │
│                                     │
│  All transactions visible           │
│  to all nodes                       │
└─────────────────────────────────────┘
```

### Information Leaked in Mempool

1. **Transaction Data**: Complete transaction payload
2. **Target Contract**: Which contract will be called
3. **Function**: Which function will be executed
4. **Parameters**: All input parameters
5. **Value**: ETH amount being sent
6. **Gas Price**: How much user is willing to pay

### Mempool Monitoring Tools

```typescript
// Using ethers.js to monitor mempool
provider.on("pending", (txHash: string) => {
  provider.getTransaction(txHash).then((tx: any) => {
    // Analyze transaction
    if (isProfitableToFrontRun(tx)) {
      submitFrontRunningTx(tx);
    }
  });
});
```

### Dark Pools / Private Mempools

To combat MEV, private transaction pools have emerged:

1. **Flashbots Protect**: Private transaction relay
2. **Eden Network**: Priority ordering for members
3. **KeeperDAO**: MEV redistribution
4. **Manifold Finance**: Private RPC endpoints

---

## Attack Simulations

This project includes several MEV attack simulations:

### 1. Simple Front-Running

**Scenario**: Auction bidding

```solidity
// Victim bids 10 ETH
function placeBid() external payable {
    require(msg.value > highestBid, "Bid too low");
    highestBid = msg.value;
    highestBidder = msg.sender;
}

// Attacker observes and front-runs with 10.1 ETH
```

### 2. DEX Sandwich Attack

**Scenario**: Token swap on AMM

```solidity
// Victim swaps 100 ETH for USDC
dex.swap(100 ether, tokenIn, tokenOut, minOut);

// Attacker:
// 1. Front-run: Buy USDC (price ↑)
// 2. Victim executes (pays inflated price)
// 3. Back-run: Sell USDC (profit)
```

### 3. Oracle Manipulation

**Scenario**: Price oracle update

```solidity
// Victim updates oracle price
oracle.updatePrice(newPrice);

// Attacker front-runs with trade at old price
lending.borrow(amount);  // Uses old oracle price
```

### 4. NFT Minting Front-Running

**Scenario**: Rare NFT mint

```solidity
// Victim mints NFT #100 (rare)
nft.mint(100);

// Attacker sees transaction and front-runs
nft.mint(100);  // Executes first, gets rare NFT
```

---

## Protection Mechanisms

### 1. Commit-Reveal Schemes

Hide transaction intent until execution is guaranteed.

```solidity
// Phase 1: Commit
function commit(bytes32 hash) external {
    commitments[msg.sender] = hash;
    commitTime[msg.sender] = block.timestamp;
}

// Phase 2: Reveal (after time delay)
function reveal(uint256 bid, bytes32 salt) external {
    require(block.timestamp >= commitTime[msg.sender] + DELAY);
    require(keccak256(abi.encode(bid, salt)) == commitments[msg.sender]);

    // Execute bid
    executeBid(bid);
}
```

**Pros**: Completely hides intent
**Cons**: Requires two transactions, time delay

### 2. Slippage Protection

Limit acceptable price movement.

```solidity
function swap(
    uint256 amountIn,
    uint256 minAmountOut  // Minimum acceptable output
) external {
    uint256 amountOut = calculateSwap(amountIn);
    require(amountOut >= minAmountOut, "Slippage too high");

    // Execute swap
}
```

**Pros**: Simple, built into most DEXs
**Cons**: Can still be sandwiched within slippage tolerance

### 3. Batch Auctions

Execute multiple orders at the same price.

```solidity
// Collect orders during batch period
function submitOrder(uint256 amount, uint256 price) external {
    orders.push(Order(msg.sender, amount, price));
}

// Execute all orders at clearing price
function executeBatch() external {
    uint256 clearingPrice = calculateClearingPrice(orders);
    for (uint i = 0; i < orders.length; i++) {
        executeOrder(orders[i], clearingPrice);
    }
}
```

**Pros**: Eliminates intra-batch front-running
**Cons**: Requires coordination, delayed execution

### 4. Time Locks

Enforce minimum delay between submission and execution.

```solidity
function submitAction(bytes calldata data) external {
    bytes32 id = keccak256(data);
    pendingActions[id] = block.timestamp + TIME_LOCK;
}

function executeAction(bytes calldata data) external {
    bytes32 id = keccak256(data);
    require(block.timestamp >= pendingActions[id], "Time lock active");

    // Execute action
}
```

**Pros**: Gives time for review/cancellation
**Cons**: Poor UX, delayed execution

### 5. Submarine Sends

Hide transaction until commitment is mined.

```solidity
// Off-chain: Generate commit hash
// On-chain: Submit commit
function commit(bytes32 commitHash) external payable {
    commits[commitHash] = msg.value;
}

// Later: Reveal transaction
function reveal(bytes memory data, bytes32 salt) external {
    bytes32 commitHash = keccak256(abi.encode(data, salt));
    require(commits[commitHash] > 0, "No commit");

    // Execute hidden transaction
}
```

**Pros**: Strong protection
**Cons**: Complex, capital lockup

### 6. Private Transactions (Flashbots)

Submit transactions privately to block builders.

```typescript
// Send transaction via Flashbots RPC
const flashbotsProvider = await FlashbotsBundleProvider.create(
  provider,
  authSigner
);

const bundle = [{
  transaction: signedTransaction
}];

await flashbotsProvider.sendBundle(bundle, targetBlock);
```

**Pros**: No public mempool exposure
**Cons**: Requires Flashbots integration, validator support

### 7. Fair Ordering Protocols

Use protocols designed for fair ordering.

Examples:
- **Chainlink FSS (Fair Sequencing Services)**
- **Arbitrum's Fair Ordering**
- **Optimism's Sequencer**

### 8. Decoy Transactions

Submit multiple conflicting transactions.

```solidity
// Submit multiple bids with different nonces
submitBid(10 ETH, nonce: 1);
submitBid(11 ETH, nonce: 1);  // Conflicts
submitBid(12 ETH, nonce: 1);  // Conflicts

// Only one will be included
```

**Pros**: Confuses attackers
**Cons**: Wastes gas, unreliable

---

## Real-World MEV Examples

### 1. The $1.4M Arbitrage (April 2023)

**Incident**: MEV bot extracted $1.4M from single Curve pool arbitrage

**Details**:
- Exploited price difference between Curve and Uniswap
- Single atomic transaction
- Required flash loan of $200M+
- Gas cost: $30,000+
- Net profit: $1.4M

**Transaction Flow**:
```
1. Flash loan 200M USDC
2. Swap on Curve (low price)
3. Swap on Uniswap (high price)
4. Repay flash loan
5. Keep profit
```

### 2. Salmonella Token Attack

**Incident**: Honeypot tokens that only allow deployer to sell

**Mechanism**:
```solidity
function transfer(address to, uint256 amount) public returns (bool) {
    if (msg.sender != owner) {
        revert("Only owner can transfer");
    }
    // transfer logic
}
```

**Result**: MEV bots lost millions trying to sandwich these tokens

### 3. Ethereum's First Block MEV

**Date**: September 15, 2022 (The Merge)

**Details**:
- First PoS block on Ethereum
- Builder: 0x690...
- MEV extracted: 0.548 ETH
- Historic significance: First post-merge MEV

### 4. NFT Minting Front-Running

**Incident**: Bored Ape Yacht Club minting chaos

**Details**:
- Gas wars during mint
- Front-runners paid 2-5 ETH in gas
- Some paid more in gas than NFT cost
- Congested network for hours

### 5. DeFi Protocol Liquidations

**Example**: Compound Finance liquidation bot wars

**Details**:
- Under-collateralized positions trigger liquidation
- Bots compete to liquidate first
- Priority gas auctions (PGAs)
- Gas prices spike 1000x+

### 6. Sandwich Attack Statistics

**Research Findings** (2023):
- ~5% of all Uniswap trades sandwiched
- Average victim loss: $50-100
- Daily MEV from sandwiching: $500K+
- Largest single sandwich: $300K profit

---

## Learning Objectives

After completing this project, you will understand:

1. **MEV Fundamentals**
   - What MEV is and why it exists
   - Different types of MEV extraction
   - Economic incentives for searchers

2. **Attack Mechanisms**
   - How front-running works
   - Sandwich attack construction
   - Gas price manipulation
   - Mempool monitoring techniques

3. **Vulnerability Patterns**
   - Contracts susceptible to MEV
   - Information leakage in transactions
   - Price impact vulnerabilities

4. **Defense Strategies**
   - Commit-reveal patterns
   - Slippage protection
   - Batch processing
   - Private transaction submission
   - Fair ordering mechanisms

5. **Real-World Impact**
   - MEV's effect on users
   - Network congestion from gas wars
   - Protocol security considerations

---

## Project Structure

```
33-mev-frontrunning/
├── README.md                          (This file)
├── src/
│   ├── Project33.sol                 (Skeleton with TODOs)
│   └── solution/
│       └── Project33Solution.sol     (Complete implementation)
├── test/
│   └── Project33.t.sol               (Attack simulations & tests)
└── script/
    └── DeployProject33.s.sol         (Deployment script)
```

### Contract Components

#### Vulnerable Contracts
1. **VulnerableAuction**: Simple auction susceptible to front-running
2. **VulnerableDEX**: AMM DEX vulnerable to sandwich attacks
3. **VulnerableOracle**: Price oracle with update delays

#### Attack Contracts
1. **FrontRunner**: Generic front-running bot
2. **SandwichAttacker**: DEX sandwich attack implementation
3. **MEVSearcher**: Multi-strategy MEV searcher

#### Protected Contracts
1. **CommitRevealAuction**: Auction with commit-reveal
2. **ProtectedDEX**: DEX with slippage limits
3. **BatchAuction**: Fair batch auction system

---

## Getting Started

### Prerequisites

- Foundry installed
- Basic understanding of Solidity
- Familiarity with DeFi concepts (AMMs, DEXs)

### Installation

```bash
# Navigate to project directory
cd 33-mev-frontrunning

# Install dependencies (if any)
forge install

# Run tests
forge test -vvv
```

### Running Attack Simulations

```bash
# Run all tests
forge test

# Run specific attack simulation
forge test --match-test testFrontRunning -vvv
forge test --match-test testSandwichAttack -vvv

# Run with gas reporting
forge test --gas-report
```

### Deployment

```bash
# Deploy to local testnet
anvil  # In separate terminal

# Deploy contracts
forge script script/DeployProject33.s.sol --rpc-url http://localhost:8545 --broadcast

# Deploy to testnet
forge script script/DeployProject33.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
```

---

## Learning Path

### Stage 1: Understanding (src/Project33.sol)

1. Read through the skeleton contracts
2. Understand the vulnerability patterns
3. Complete the TODOs for basic implementations

### Stage 2: Attacking

1. Study the attack contracts
2. Simulate front-running attacks
3. Execute sandwich attacks
4. Analyze profit extraction

### Stage 3: Defending (solution contracts)

1. Implement commit-reveal scheme
2. Add slippage protection
3. Create batch auction system
4. Test mitigation effectiveness

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/MEVFrontrunningSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployMEVFrontrunningSolution.s.sol` - Deployment script patterns
- `test/solution/MEVFrontrunningSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains MEV extraction, front-running, sandwich attacks, commit-reveal schemes
- **Connections to Project 02**: Transaction ordering and mempool mechanics
- **Real-World Context**: MEV is a major concern in DeFi - understanding attacks and defenses is critical

### Stage 4: Advanced Topics

1. Study Flashbots integration
2. Explore MEV-Boost architecture
3. Analyze real-world MEV transactions
4. Consider L2 MEV implications

---

## Additional Resources

### Documentation
- [Flashbots Documentation](https://docs.flashbots.net/)
- [Ethereum MEV Research](https://ethereum.org/en/developers/docs/mev/)
- [MEV-Boost](https://boost.flashbots.net/)

### Research Papers
- "Flash Boys 2.0" by Daian et al.
- "Quantifying MEV" by Flashbots Research
- "SoK: Transparent Dishonesty" by Eskandari et al.

### Tools
- [Flashbots Explorer](https://transparency.flashbots.net/)
- [MEV-Inspect](https://github.com/flashbots/mev-inspect-py)
- [EigenPhi](https://eigenphi.io/)
- [Zeromev](https://www.zeromev.org/)

### Community
- [Flashbots Discord](https://discord.gg/flashbots)
- [MEV Research Forum](https://collective.flashbots.net/)
- [EthResearch MEV Category](https://ethresear.ch/c/mev/)

---

## Security Warnings

**EDUCATIONAL PURPOSE ONLY**

This project is for educational purposes. MEV extraction and front-running can:

1. **Harm Users**: Cause financial losses to transaction submitters
2. **Congest Networks**: Drive up gas prices for everyone
3. **Violate ToS**: May violate exchange terms of service
4. **Legal Issues**: May have legal implications in some jurisdictions

**DO NOT** use these techniques on mainnet to harm others.

**DO** use this knowledge to:
- Protect your own contracts
- Understand the MEV landscape
- Design MEV-resistant protocols
- Contribute to fair ordering research

---

## Challenges

1. **Implement a profitable sandwich attack** that extracts value from a DEX trade
2. **Create a commit-reveal auction** that prevents front-running
3. **Build slippage protection** that minimizes sandwich attack profitability
4. **Design a batch auction system** with fair price discovery
5. **Analyze gas costs** and determine MEV profitability thresholds

---

## Contributing

Found a vulnerability pattern we missed? Have ideas for better mitigations? Contributions welcome!

---

## License

MIT License - Educational use only

---

## Acknowledgments

- Flashbots team for MEV research and tooling
- Ethereum Foundation for MEV documentation
- DeFi protocols for open-source implementations
- Security researchers for vulnerability disclosures

---

**Remember**: The goal is to understand MEV to build better, more secure protocols. Use this knowledge responsibly.

Happy learning!

---


## 34-oracle-manipulation

# Project 34: Oracle Manipulation Attack

Learn how oracle manipulation attacks work and how to prevent them in DeFi protocols.

## Overview

Oracle manipulation is one of the most profitable attack vectors in DeFi. Attackers exploit the way protocols determine asset prices, often combining flashloans with price oracle vulnerabilities to drain millions of dollars.

## Vulnerability Explained: Oracle Manipulation Attacks

**FIRST PRINCIPLES: Trust in External Data**

Oracle manipulation is one of the most profitable attack vectors in DeFi. Understanding how oracles work and how they can be manipulated is critical!

**CONNECTION TO PROJECT 18**:
- **Project 18**: We learned about Chainlink oracles (secure, decentralized)
- **Project 34**: We learn about vulnerable oracles (manipulable, single-source)
- Both teach oracle security - one shows secure patterns, one shows vulnerabilities!

### What is an Oracle?

An oracle is a mechanism that provides external data (like asset prices) to smart contracts. DeFi protocols rely on oracles to:
- Determine collateral values in lending protocols
- Calculate swap rates in DEXes
- Trigger liquidations
- Value synthetic assets

**CONNECTION TO PROJECT 11**:
ERC-4626 vaults need price data to calculate share values! Vulnerable oracles can manipulate vault pricing!

### Oracle Manipulation Mechanics

**THE ATTACK PATTERN**:

```
Oracle Manipulation Attack Flow:
┌─────────────────────────────────────────┐
│ Step 1: Setup                           │
│   Identify protocol with weak oracle    │ ← Research phase
│   ↓                                      │
│ Step 2: Flashloan                       │
│   Borrow massive amount (no collateral) │ ← Unlimited capital
│   ↓                                      │
│ Step 3: Manipulate                      │
│   Execute large trades to skew price    │ ← Price manipulation
│   ↓                                      │
│ Step 4: Exploit                         │
│   Use manipulated price to extract value│ ← Profit extraction
│   ↓                                      │
│ Step 5: Repay                           │
│   Return flashloan, keep profits         │ ← Risk-free profit
└─────────────────────────────────────────┘
```

**WHY IT WORKS**:

1. **Spot Price Oracles**: Can be manipulated within a single transaction
   - Read price from AMM reserves
   - Large swap changes reserves
   - Oracle reads manipulated price
   - All in one transaction!

2. **Flashloans**: Provide unlimited capital for manipulation
   - No collateral needed
   - Borrow millions, manipulate, repay
   - From Project 02: Flashloans enable atomic operations!

3. **Atomic Transactions**: Ensure risk-free execution
   - All steps in one transaction
   - Either all succeed or all revert
   - No risk of partial execution

4. **Missing Protections**: Many protocols don't implement proper oracle protections
   - No TWAP (Time-Weighted Average Price)
   - No price bounds checking
   - No multiple oracle sources

**REAL-WORLD ANALOGY**: 
Like manipulating a stock price by buying/selling large amounts quickly, then using that manipulated price to execute profitable trades. Flashloans make this possible without capital!

### Types of Vulnerable Oracles

#### 1. AMM Spot Price Oracles

**Vulnerable Pattern:**
```solidity
function getPrice() public view returns (uint256) {
    return (reserveB * 1e18) / reserveA;  // ❌ Instant manipulation
}
```

**Attack:**
- Execute a massive swap in the AMM
- Oracle reads manipulated reserves
- Protocol uses incorrect price
- Attacker profits from mispricing

#### 2. Single Source Oracles

**Vulnerability:**
- Relying on only one price source (single point of failure)
- No redundancy or validation
- Easy to manipulate or compromise

#### 3. Non-Updated Oracles

**Vulnerability:**
- Stale price data
- Outdated information from infrequent updates
- Exploitable during high volatility

## Attack Vectors

### 1. AMM Price Manipulation with Flashloans

**Classic Attack Flow:**

```
1. Flashloan 10,000 ETH
2. Swap 10,000 ETH → TokenA (price spikes)
3. Oracle reads inflated TokenA price
4. Borrow maximum tokens using overvalued TokenA collateral
5. Swap back TokenA → ETH (price normalizes)
6. Repay flashloan
7. Keep borrowed tokens as profit
```

**Real Example - Harvest Finance (2020):**
- $34 million stolen
- Attacker manipulated USDC/USDT price on Curve
- Used flashloans to create massive imbalance
- Exploited arbitrage between pools

### 2. Lending Protocol Manipulation

**Attack Pattern:**
```solidity
// Vulnerable lending protocol
function borrow(address token, uint256 amount) external {
    uint256 collateralValue = oracle.getPrice(collateralToken) * collateralAmount;
    uint256 borrowValue = oracle.getPrice(token) * amount;
    require(collateralValue >= borrowValue * 150 / 100, "Insufficient collateral");
    // ❌ Uses manipulated oracle price
}
```

**Exploit:**
1. Manipulate collateral token price upward
2. Deposit minimal collateral (now appears valuable)
3. Borrow maximum tokens
4. Restore price and profit

### 3. Compound/Aave Oracle Attacks

**Historical Vulnerabilities:**

**Compound:**
- Initially used Uniswap V2 TWAP
- Vulnerable to multi-block manipulation
- Switched to Chainlink oracles

**Cream Finance (2021):**
- $130 million stolen
- Manipulated priceOracle for yUSD
- Used flashloans to inflate collateral value
- Borrowed and drained protocol

**Aave:**
- More resilient with Chainlink integration
- Multiple oracle sources
- Fallback mechanisms

## Spot Price vs TWAP

### Spot Price (Vulnerable)

```solidity
// ❌ Single block manipulation
function getSpotPrice() public view returns (uint256) {
    return (reserveToken1 * PRECISION) / reserveToken0;
}
```

**Vulnerability:**
- Can be manipulated within one transaction
- No historical context
- Perfect for flashloan attacks

### TWAP (Time-Weighted Average Price)

```solidity
// ✅ More resistant to manipulation
function getTWAP(uint256 period) public view returns (uint256) {
    uint256 currentPrice = getCurrentPrice();
    uint256 currentTime = block.timestamp;

    // Update cumulative price
    if (currentTime > lastUpdateTime) {
        priceCumulative += currentPrice * (currentTime - lastUpdateTime);
        lastUpdateTime = currentTime;
    }

    // Calculate TWAP over period
    return (priceCumulative - priceCumulativeStart) / period;
}
```

**Benefits:**
- Averages price over time
- Requires sustained manipulation (expensive)
- Cannot be manipulated in single transaction

**Limitations:**
- Still vulnerable to multi-block attacks
- Lag in price updates during volatility
- Can be gamed with enough capital and time

## Mitigation Strategies

### 1. Use Chainlink Price Feeds

```solidity
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract SafeOracle {
    AggregatorV3Interface internal priceFeed;

    function getPrice() public view returns (uint256) {
        (, int256 price,,,) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price");
        return uint256(price);
    }
}
```

**Benefits:**
- Decentralized oracle network
- Multiple data sources
- Cryptographic guarantees
- Industry standard

### 2. Multiple Oracle Sources

```solidity
contract MultiOracle {
    function getPrice() public view returns (uint256) {
        uint256 chainlinkPrice = chainlinkOracle.getPrice();
        uint256 uniswapTWAP = uniswapOracle.getTWAP(3600);
        uint256 bandPrice = bandOracle.getPrice();

        // Use median of three sources
        return median(chainlinkPrice, uniswapTWAP, bandPrice);
    }
}
```

### 3. TWAP Implementation

```solidity
contract TWAPOracle {
    uint256 public constant PERIOD = 1 hours;
    uint256 public priceCumulativeLast;
    uint32 public blockTimestampLast;

    function update() external {
        (uint256 price0Cumulative,, uint32 blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(pair);

        uint32 timeElapsed = blockTimestamp - blockTimestampLast;

        if (timeElapsed >= PERIOD) {
            // Calculate TWAP
            twap = (price0Cumulative - priceCumulativeLast) / timeElapsed;
            priceCumulativeLast = price0Cumulative;
            blockTimestampLast = blockTimestamp;
        }
    }
}
```

### 4. Price Deviation Checks

```solidity
function checkPriceDeviation(uint256 newPrice) internal view {
    uint256 oldPrice = lastPrice;
    uint256 deviation = newPrice > oldPrice
        ? ((newPrice - oldPrice) * 100) / oldPrice
        : ((oldPrice - newPrice) * 100) / oldPrice;

    require(deviation < MAX_DEVIATION, "Price change too large");
}
```

### 5. Commit-Reveal Schemes

```solidity
// Prevent single-transaction attacks
mapping(address => uint256) public commitBlock;

function commitAction() external {
    commitBlock[msg.sender] = block.number;
}

function executeAction() external {
    require(block.number > commitBlock[msg.sender] + 1, "Must wait");
    // Execute with oracle price
}
```

## Real-World Exploits

### 1. Harvest Finance (October 2020)
- **Loss:** $34 million
- **Method:** Curve pool price manipulation
- **Attack:** Flashloaned USDC/USDT to create imbalance
- **Lesson:** Use TWAP, not spot prices

### 2. Cream Finance (October 2021)
- **Loss:** $130 million
- **Method:** yUSD price oracle manipulation
- **Attack:** Flashloan + donate to vault to inflate share price
- **Lesson:** Validate oracle inputs, use multiple sources

### 3. Mango Markets (October 2022)
- **Loss:** $110 million
- **Method:** Perpetual futures price manipulation
- **Attack:** Inflated MNGO price with low liquidity
- **Lesson:** Ensure oracle liquidity requirements

### 4. Indexed Finance (October 2021)
- **Loss:** $16 million
- **Method:** Low liquidity pool manipulation
- **Attack:** Manipulated DEFI5 index token price
- **Lesson:** Oracle must account for liquidity depth

### 5. Warp Finance (December 2020)
- **Loss:** $8 million
- **Method:** Uniswap LP token price manipulation
- **Attack:** Flashloan to manipulate LP token value
- **Lesson:** LP tokens need special oracle considerations

## Best Practices

### For Protocol Developers

1. **Never use spot prices alone**
   - Always implement TWAP or use Chainlink
   - Minimum 30-minute window for TWAP

2. **Multiple oracle sources**
   - Use at least 2-3 independent oracles
   - Implement circuit breakers for discrepancies

3. **Validate oracle data**
   - Check for stale data
   - Verify price bounds
   - Monitor for extreme deviations

4. **Liquidity requirements**
   - Ensure sufficient liquidity in price sources
   - Set minimum liquidity thresholds

5. **Time delays**
   - Implement cooldown periods
   - Prevent single-block exploits

### For Auditors

1. **Identify all oracle dependencies**
2. **Verify TWAP implementation**
3. **Check for single-transaction vulnerabilities**
4. **Test with flashloan scenarios**
5. **Review fallback mechanisms**

## Learning Objectives

By completing this project, you will:

1. ✅ Understand how oracle manipulation works
2. ✅ Implement a flashloan-based price manipulation attack
3. ✅ Recognize vulnerable oracle patterns
4. ✅ Build TWAP protection mechanisms
5. ✅ Implement multi-oracle systems
6. ✅ Learn defense strategies

## Setup

```bash
# Install dependencies
forge install

# Run tests
forge test

# Run specific test
forge test --match-test testOracleManipulation -vvv

# Deploy
forge script script/DeployProject34.s.sol --rpc-url <RPC_URL> --broadcast
```

## Exercises

### Part 1: Understanding the Vulnerability

1. Study the vulnerable lending protocol in `Project34.sol`
2. Identify the oracle vulnerability
3. Trace how a flashloan could manipulate prices

### Part 2: Exploit Development

1. Complete the `Attacker` contract
2. Implement the attack sequence:
   - Get flashloan
   - Manipulate AMM price
   - Exploit lending protocol
   - Restore price
   - Profit

### Part 3: Testing

1. Run tests to verify the attack works
2. Measure profit from manipulation
3. Test TWAP protection effectiveness

### Part 4: Build Defenses

1. Implement TWAP oracle
2. Add multiple oracle sources
3. Create price deviation checks
4. Test protection mechanisms

## Key Takeaways

1. **Spot prices are dangerous** - Never use them directly for critical operations
2. **Flashloans amplify risk** - Consider flashloan attack vectors in all protocols
3. **TWAP isn't perfect** - It's more resistant but still exploitable
4. **Chainlink is gold standard** - Decentralized, battle-tested, reliable
5. **Defense in depth** - Use multiple protections (TWAP + Chainlink + checks)
6. **Liquidity matters** - Low liquidity makes manipulation cheaper
7. **Time is a defense** - Multi-block requirements prevent atomic attacks

## Resources

- [Chainlink Price Feeds](https://docs.chain.link/data-feeds/price-feeds)
- [Uniswap V2 TWAP Oracle](https://docs.uniswap.org/contracts/v2/guides/smart-contract-integration/building-an-oracle)
- [Euler Finance: Oracle Rating Framework](https://docs.euler.finance/getting-started/methodology/oracle-rating)
- [Openzeppelin Governor Bravo](https://docs.openzeppelin.com/contracts/4.x/api/governance)
- [Rekt News - Oracle Manipulation Incidents](https://rekt.news/)

## Advanced Topics

- MEV and oracle manipulation synergies
- Cross-chain oracle attacks
- Governance token price manipulation
- LP token oracle vulnerabilities
- Synthetic asset oracle risks

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/OracleManipulationSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployOracleManipulationSolution.s.sol` - Deployment script patterns
- `test/solution/OracleManipulationSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains oracle manipulation attacks, flashloan synergies, price manipulation
- **Connections to Project 18**: Chainlink oracles (this shows vulnerable patterns to avoid)
- **Connections to Project 11**: ERC-4626 vaults (vulnerable oracles can manipulate vault pricing)
- **Real-World Context**: Oracle manipulation has drained millions - understanding attacks is critical for defense

---

**⚠️ Educational Purpose Only**

This project is for learning security concepts. Never use these techniques on mainnet or against real protocols without authorization. Oracle manipulation is illegal and unethical.

---


## 35-delegatecall-corruption

# Project 35: Delegatecall Storage Corruption

Learn about one of the most dangerous vulnerabilities in Solidity - delegatecall storage corruption. This project explores how improper use of delegatecall can lead to complete contract takeover.

## Overview

Delegatecall is a powerful feature in Solidity that allows a contract to execute code from another contract while maintaining its own storage context. However, when used incorrectly, it can lead to severe storage corruption vulnerabilities.

## How Delegatecall Works: Context Preservation

**FIRST PRINCIPLES: Code Execution vs Storage Context**

Delegatecall is a powerful but dangerous feature. Understanding context preservation is critical for secure proxy patterns!

**CONNECTION TO PROJECT 10 & 15**:
- **Project 10**: We learned about UUPS proxies using delegatecall
- **Project 15**: We learned about low-level calls including delegatecall
- **Project 35**: We dive deep into delegatecall storage corruption risks!

### Normal Call vs Delegatecall: Understanding Context

**NORMAL CALL (`call`)** (from Project 15 knowledge):
- Executes code in the **target contract's context**
- Uses **target contract's storage**
- `msg.sender` is the calling contract
- Storage changes affect the **target contract**

**DELEGATECALL (`delegatecall`)**:
- Executes **target contract's code** in the **calling contract's context**
- Uses **calling contract's storage** ⚠️
- Preserves original `msg.sender` and `msg.value`
- Storage changes affect the **calling contract** ⚠️

**UNDERSTANDING THE DIFFERENCE**:

```
Normal Call:
┌─────────────────────────────────────────┐
│ Contract A calls Contract B             │
│   ↓                                      │
│ B's code executes                       │ ← Code from B
│   ↓                                      │
│ Uses B's storage                        │ ← Storage from B
│   ↓                                      │
│ Changes affect B                        │ ← B's state changes
└─────────────────────────────────────────┘

Delegatecall:
┌─────────────────────────────────────────┐
│ Contract A delegatecalls Contract B     │
│   ↓                                      │
│ B's code executes                       │ ← Code from B
│   ↓                                      │
│ Uses A's storage!                       │ ← Storage from A!
│   ↓                                      │
│ Changes affect A!                       │ ← A's state changes!
└─────────────────────────────────────────┘
```

**THE CRITICAL INSIGHT**:
Delegatecall uses **target's code** but **caller's storage**. This is powerful for proxies but dangerous if storage layouts don't match!

**STORAGE CORRUPTION RISK** (from Project 01 & 10 knowledge):

```solidity
// Proxy Contract (A)
contract Proxy {
    address public implementation;  // Slot 0
    uint256 public value;           // Slot 1
}

// Implementation Contract (B) - WRONG LAYOUT!
contract Implementation {
    uint256 public value;           // Slot 0 ❌ COLLISION!
    address public owner;            // Slot 1 ❌ COLLISION!
    
    function setValue(uint256 _value) public {
        value = _value;  // Writes to Proxy's slot 0 (implementation address!)
        // Corrupts implementation address! 💥
    }
}
```

**REAL-WORLD ANALOGY**: 
Like hiring a consultant:
- **Normal call**: Consultant works in their office (target's storage)
- **Delegatecall**: Consultant works in YOUR office (your storage), but uses their methods (target's code)
- **Risk**: If consultant's methods expect different office layout, they'll mess up your files!

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

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/DelegatecallCorruptionSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployDelegatecallCorruptionSolution.s.sol` - Deployment script patterns
- `test/solution/DelegatecallCorruptionSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains storage layout collisions, delegatecall execution context
- **Connections to Project 10**: Upgradeable proxies (this shows the vulnerability)
- **Connections to Project 15**: delegatecall mechanism
- **Connections to Project 01**: Storage slot layout understanding
- **Real-World Context**: Storage slots must match between proxy and implementation (EIP-1967 solves this)

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

---


## 36-access-control-bugs

# Project 36: Access Control Bugs

Learn about common access control vulnerabilities in Solidity and how to prevent them.

## Overview

Access control is one of the most critical aspects of smart contract security. Improper access control can lead to unauthorized users performing privileged operations, potentially draining funds or corrupting contract state. This project explores common access control bugs and their exploits.

## Learning Objectives

By completing this project, you will:
- Understand common access control anti-patterns
- Learn the difference between `tx.origin` and `msg.sender`
- Identify uninitialized owner vulnerabilities
- Recognize missing modifier bugs
- Understand role escalation attacks
- Learn proper initialization patterns
- Master OpenZeppelin's AccessControl library

## Common Access Control Vulnerabilities: The Gatekeepers' Mistakes

**FIRST PRINCIPLES: Access Control is Critical**

Access control bugs are among the most common and dangerous vulnerabilities. Understanding these patterns is essential for secure contract development!

**CONNECTION TO PROJECT 04 & 10**:
- **Project 04**: We learned about modifiers and access control patterns
- **Project 10**: We learned about proxy patterns and initialization
- **Project 36**: We learn about common access control bugs and exploits!

### 1. Uninitialized Proxy Owner: The Race Condition

**PROBLEM**: In upgradeable proxy patterns, if the owner is not initialized in the constructor or initializer, anyone can claim ownership.

**CONNECTION TO PROJECT 10**:
Proxy contracts don't use constructors (they delegate to implementation). If initialization isn't protected, first caller wins!

```solidity
contract VulnerableProxy {
    address public owner;  // Slot 0: address(0) initially

    // ❌ Owner never initialized!
    // First caller of setOwner becomes owner
    function setOwner(address newOwner) public {
        require(owner == address(0), "Owner already set");
        owner = newOwner;  // Anyone can call this first!
    }
}
```

**ATTACK SCENARIO**:

```
Race Condition Attack:
┌─────────────────────────────────────────┐
│ Proxy deployed                          │
│   owner = address(0)                     │ ← Uninitialized!
│   ↓                                      │
│ Attacker sees deployment                │ ← Mempool observation
│   ↓                                      │
│ Attacker calls setOwner(attacker)       │ ← Front-run!
│   ↓                                      │
│ Check: owner == address(0)? ✅          │ ← Passes!
│   ↓                                      │
│ owner = attacker                        │ ← Attacker becomes owner!
│   ↓                                      │
│ Legitimate owner tries to initialize    │ ← Too late!
│   ↓                                      │
│ Check: owner == address(0)? ❌          │ ← Fails!
│   ↓                                      │
│ Attacker has full control! 💥           │
└─────────────────────────────────────────┘
```

**THE FIX**: Initialize owner in constructor or use proper initializer pattern:

```solidity
contract SecureProxy {
    address public owner;

    constructor() {
        owner = msg.sender;  // ✅ Initialized immediately!
    }

    function setOwner(address newOwner) public {
        require(msg.sender == owner, "Not owner");  // ✅ Protected!
        owner = newOwner;
    }
}
```

**OR** (for upgradeable proxies):

```solidity
bool private initialized;

function initialize(address _owner) public {
    require(!initialized, "Already initialized");  // ✅ One-time only!
    owner = _owner;
    initialized = true;
}
```

**GAS COST** (from Project 01 & 04 knowledge):
- Setting owner: ~20,000 gas (cold SSTORE)
- Initialization check: ~100 gas (SLOAD)
- Total: ~20,100 gas (one-time cost)

**REAL-WORLD ANALOGY**: 
Like a bank vault with no lock - first person to arrive can set the combination! Always initialize access control immediately!

### 2. Missing Access Control Modifiers

**Problem**: Forgetting to add access control modifiers to privileged functions.

```solidity
contract MissingModifier {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // Missing onlyOwner modifier!
    function withdraw() public {
        payable(owner).transfer(address(this).balance);
    }
}
```

**Fix**: Always add appropriate modifiers:

```solidity
contract SecureContract {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
```

### 3. tx.origin vs msg.sender

**Problem**: Using `tx.origin` for authentication can be exploited through phishing attacks.

```solidity
contract VulnerableTxOrigin {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function withdraw() public {
        require(tx.origin == owner, "Not owner");  // VULNERABLE!
        payable(owner).transfer(address(this).balance);
    }
}
```

**Attack Scenario**:
1. Attacker deploys malicious contract
2. Owner calls malicious contract
3. Malicious contract calls `withdraw()` on vulnerable contract
4. Since `tx.origin` is still the owner, the check passes
5. Funds are drained

**Fix**: Always use `msg.sender`:

```solidity
contract SecureContract {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function withdraw() public {
        require(msg.sender == owner, "Not owner");  // CORRECT
        payable(owner).transfer(address(this).balance);
    }
}
```

### 4. Role Escalation

**Problem**: Users can escalate their privileges through improper role management.

```solidity
contract VulnerableRoles {
    mapping(address => bool) public admins;

    constructor() {
        admins[msg.sender] = true;
    }

    // Anyone can become admin!
    function addAdmin(address newAdmin) public {
        admins[newAdmin] = true;
    }
}
```

**Fix**: Restrict role management to existing privileged users:

```solidity
contract SecureRoles {
    mapping(address => bool) public admins;

    constructor() {
        admins[msg.sender] = true;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Not admin");
        _;
    }

    function addAdmin(address newAdmin) public onlyAdmin {
        admins[newAdmin] = true;
    }
}
```

### 5. Public Functions That Should Be Private/Internal

**Problem**: Making initialization or privileged functions public when they should be restricted.

```solidity
contract VulnerableInitialization {
    address public owner;
    bool private initialized;

    // Should be external or have access control!
    function initialize(address _owner) public {
        require(!initialized, "Already initialized");
        owner = _owner;
        initialized = true;
    }
}
```

**Fix**: Use proper visibility and access control:

```solidity
contract SecureInitialization {
    address public owner;
    bool private initialized;

    constructor(address _owner) {
        owner = _owner;
        initialized = true;
    }

    // Or use initializer pattern with Ownable
    function initialize(address _owner) external {
        require(!initialized, "Already initialized");
        require(msg.sender == deployer, "Not deployer");
        owner = _owner;
        initialized = true;
    }
}
```

### 6. Constructor vs Initializer Issues

**Problem**: In upgradeable contracts, constructors don't work as expected. Initializers must be protected.

```solidity
// WRONG for upgradeable contracts
contract VulnerableUpgradeable {
    address public owner;

    constructor() {
        owner = msg.sender;  // Won't work with proxies!
    }
}

// WRONG - unprotected initializer
contract VulnerableInitializer {
    address public owner;

    function initialize() public {
        owner = msg.sender;  // Can be called multiple times!
    }
}
```

**Fix**: Use proper initializer pattern:

```solidity
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract SecureUpgradeable is Initializable, OwnableUpgradeable {
    function initialize() public initializer {
        __Ownable_init(msg.sender);
    }
}
```

### 7. Delegatecall Preservation

**Problem**: When using `delegatecall`, the caller's context is preserved, which can bypass access controls.

```solidity
contract VulnerableDelegatecall {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function delegateCallToLibrary(address library, bytes memory data) public {
        // No access control!
        library.delegatecall(data);
    }
}
```

**Fix**: Restrict delegatecall to trusted addresses:

```solidity
contract SecureDelegatecall {
    address public owner;
    mapping(address => bool) public trustedLibraries;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function delegateCallToLibrary(address library, bytes memory data) public onlyOwner {
        require(trustedLibraries[library], "Untrusted library");
        library.delegatecall(data);
    }
}
```

## Real-World Access Control Bugs

### Parity Wallet Hack (2017)

The Parity multi-sig wallet had an uninitialized owner vulnerability. The library contract's `initWallet` function was public and unprotected:

```solidity
function initWallet(address[] _owners, uint _required, uint _daylimit) {
    // No check if already initialized!
    initMultiowned(_owners, _required);
    initDaylimit(_daylimit);
}
```

An attacker called `initWallet`, became the owner, and then called `kill`, destroying the library contract and freezing ~$300M in ETH.

### Rubixi (2016)

The contract was originally named "DynamicPyramid" but was renamed to "Rubixi". However, the constructor name wasn't updated:

```solidity
contract Rubixi {
    address private creator;

    // Old constructor name - now just a public function!
    function DynamicPyramid() public {
        creator = msg.sender;
    }
}
```

Anyone could call `DynamicPyramid()` and become the creator.

### OpenZeppelin AccessControl Best Practices

OpenZeppelin provides robust role-based access control:

```solidity
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SecureContract is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function adminFunction() public onlyRole(ADMIN_ROLE) {
        // Admin-only logic
    }

    function operatorFunction() public onlyRole(OPERATOR_ROLE) {
        // Operator-only logic
    }
}
```

## Project Tasks

### Part 1: Identify Vulnerabilities

Examine the vulnerable contracts in `src/Project36.sol` and identify:
1. Which contracts have access control bugs
2. What type of vulnerability each has
3. How an attacker could exploit each bug

### Part 2: Write Exploits

Create exploit contracts that:
1. Take ownership of uninitialized contracts
2. Call functions missing modifiers
3. Exploit tx.origin authentication
4. Escalate roles
5. Call unprotected initializers

### Part 3: Fix Vulnerabilities

Implement secure versions:
1. Add proper initialization
2. Add missing modifiers
3. Replace tx.origin with msg.sender
4. Add role-based access control
5. Protect all privileged functions

### Part 4: Write Tests

Create comprehensive tests:
1. Verify exploits work on vulnerable contracts
2. Verify fixes prevent exploits
3. Test edge cases
4. Test role-based access control

## Testing

Run the test suite:

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vvv

# Run specific test
forge test --match-test testUninitializedOwner -vvv

# Check gas usage
forge test --gas-report
```

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/AccessControlBugsSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployAccessControlBugsSolution.s.sol` - Deployment script patterns
- `test/solution/AccessControlBugsSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains access control vulnerabilities, tx.origin vs msg.sender, initialization patterns
- **Connections to Project 04**: Modifiers and access control (this shows common bugs)
- **Connections to Project 10**: Proxy initialization (uninitialized owner is a common bug)
- **Real-World Context**: Access control bugs are among the most common vulnerabilities

## Key Takeaways

1. **Always initialize ownership**: Never leave owner uninitialized
2. **Use modifiers consistently**: Don't forget access control modifiers
3. **Never use tx.origin**: Always use msg.sender for authentication
4. **Protect role management**: Only privileged users should manage roles
5. **Follow initialization patterns**: Use OpenZeppelin's Initializable for upgradeable contracts
6. **Use established libraries**: OpenZeppelin AccessControl is battle-tested
7. **Test access control**: Always test both positive and negative cases
8. **Principle of least privilege**: Give minimum necessary permissions
9. **Audit carefully**: Access control bugs are subtle and critical
10. **Document permissions**: Clearly document who should have what access

## Additional Resources

- [OpenZeppelin Access Control](https://docs.openzeppelin.com/contracts/4.x/access-control)
- [SWC-105: Unprotected Ether Withdrawal](https://swcregistry.io/docs/SWC-105)
- [SWC-115: Authorization through tx.origin](https://swcregistry.io/docs/SWC-115)
- [Consensys Best Practices: Access Control](https://consensys.github.io/smart-contract-best-practices/development-recommendations/solidity-specific/access-control/)
- [Parity Wallet Hack Explained](https://blog.openzeppelin.com/on-the-parity-wallet-multisig-hack-405a8c12e8f7)

## Security Tips

- Use OpenZeppelin's `Ownable` and `AccessControl` contracts
- Initialize all state variables
- Use modifiers for repeated access checks
- Never trust `tx.origin`
- Test access control thoroughly
- Consider multi-sig for critical operations
- Implement timelock for sensitive changes
- Emit events for all permission changes
- Use role-based access control for complex permissions
- Review access control in every function

Remember: Access control is the first line of defense in smart contract security!

---


## 37-gas-dos-attacks

# Project 37: Gas DoS Attacks

A comprehensive educational project demonstrating gas-based denial of service (DoS) attacks in Solidity and their mitigations.

## Overview

Gas DoS attacks exploit the gas mechanics of the Ethereum Virtual Machine to make contracts unusable or significantly degrade their performance. This project explores various DoS attack vectors and teaches secure coding patterns to prevent them.

## Learning Objectives

- Understand unbounded loops and their dangers
- Learn about block gas limit constraints
- Recognize expensive fallback function vulnerabilities
- Understand griefing attacks and economic DoS
- Master push vs pull payment patterns
- Identify msg.sender blocking attacks
- Implement effective mitigation strategies

## DoS Attack Vectors

### 1. Unbounded Loops and Iteration: The Gas Limit Trap

**FIRST PRINCIPLES: Block Gas Limits**

Loops that iterate over dynamically-sized arrays can grow beyond the block gas limit, making functions permanently unusable. This is a fundamental DoS vector!

**CONNECTION TO PROJECT 06 & 12**:
- **Project 06**: We learned about array iteration costs (O(n) gas)
- **Project 12**: We learned about push vs pull patterns
- **Project 37**: Unbounded loops can exceed block gas limit (DoS)!

**UNDERSTANDING THE VULNERABILITY**:

**VULNERABLE PATTERN**:
```solidity
address[] public participants;  // From Project 01: Dynamic array

function distributeRewards() public {
    for (uint i = 0; i < participants.length; i++) {
        // Gas cost grows with array size
        payable(participants[i]).transfer(1 ether);  // ~23,000 gas per transfer
    }
}
```

**GAS COST ANALYSIS** (from Project 01, 02, & 06 knowledge):

```
Gas Cost Per Iteration:
┌─────────────────────────────────────────┐
│ Loop overhead: ~10 gas                 │
│ Array access: ~100 gas (SLOAD)         │
│ Transfer: ~23,000 gas                  │
│ Total per iteration: ~23,110 gas        │
│                                          │
│ Block gas limit: ~30,000,000 gas        │
│ Max iterations: ~1,300 iterations       │ ← Can exceed this!
└─────────────────────────────────────────┘
```

**IMPACT**:
- Function becomes uncallable when array grows too large
- Permanent DoS if no alternative access pattern exists
- Attackers can deliberately add entries to bloat arrays

**ATTACK SCENARIO**:

```
DoS Attack Flow:
┌─────────────────────────────────────────┐
│ Attacker calls addParticipant()        │
│   (if public or accessible)            │
│   ↓                                      │
│ Attacker adds 2,000 addresses          │ ← Bloat array
│   ↓                                      │
│ Legitimate user calls distributeRewards()│
│   ↓                                      │
│ Loop tries to process 2,000 addresses   │
│   ↓                                      │
│ Gas required: 2,000 × 23,110 = 46M gas  │ ← Exceeds limit!
│   ↓                                      │
│ Transaction REVERTS                      │ ← DoS achieved!
│   ↓                                      │
│ Function permanently unusable! 💥       │
└─────────────────────────────────────────┘
```

**THE FIX** (Pull Pattern from Project 12):

```solidity
// ✅ SAFE: Pull pattern (from Project 12)
mapping(address => uint256) public pendingRewards;  // From Project 01!

function distributeRewards(address[] calldata recipients, uint256[] calldata amounts) public {
    // Update mappings only (cheap!)
    for (uint i = 0; i < recipients.length; i++) {
        pendingRewards[recipients[i]] += amounts[i];  // ~5,000 gas per update
    }
}

function withdrawReward() public {
    // Users withdraw individually (no DoS!)
    uint256 amount = pendingRewards[msg.sender];
    pendingRewards[msg.sender] = 0;
    payable(msg.sender).transfer(amount);
}
```

**GAS COMPARISON**:

**Push Pattern** (Vulnerable):
- 1,000 recipients: ~23,110,000 gas (exceeds limit!)
- DoS risk: HIGH

**Pull Pattern** (Safe):
- Distributor: ~5,000,000 gas (updates only)
- Users: ~23,000 gas each (withdraw individually)
- DoS risk: NONE

**REAL-WORLD ANALOGY**: 
Like trying to deliver mail to everyone in a city at once (push) vs having people pick up their mail (pull). Push can fail if there's too much mail, pull scales infinitely!

**Mitigation:**
- Use pull payment patterns instead of push
- Implement pagination for large datasets
- Set maximum bounds on loops
- Use mappings with external indexing when appropriate

### 2. Block Gas Limit DoS

**Vulnerability:**
Operations that consume gas proportional to user-controlled data can be forced to exceed the block gas limit.

**Example:**
```solidity
mapping(address => uint) public balances;
address[] public users;

function withdrawAll() public {
    for (uint i = 0; i < users.length; i++) {
        if (balances[users[i]] > 0) {
            payable(users[i]).transfer(balances[users[i]]);
        }
    }
}
```

**Impact:**
- Critical functions become permanently disabled
- Funds can be locked in the contract
- Service degradation as operations become expensive

**Mitigation:**
- Batch processing with user-specified limits
- Pull over push patterns
- Separate state modification from external calls

### 3. Expensive Fallback Functions

**Vulnerability:**
Contracts with expensive fallback/receive functions can cause DoS when they are recipients of transfers.

**Example:**
```solidity
contract ExpensiveFallback {
    uint[] public data;

    receive() external payable {
        // Expensive operation in fallback
        for (uint i = 0; i < 1000; i++) {
            data.push(i);
        }
    }
}
```

**Impact:**
- Auctions can't send refunds to previous highest bidder
- Payment distributions fail
- Legitimate transfers revert

**Mitigation:**
- Use pull payment patterns
- Limit gas for external calls with `.call{gas: X}`
- Handle failed transfers gracefully
- Emit events and allow manual withdrawal

### 4. Griefing Attacks

**Vulnerability:**
Attackers can waste gas or cause financial harm without direct benefit, just to disrupt the protocol.

**Example:**
```solidity
function bid() public payable {
    require(msg.value > highestBid);
    // Refund previous bidder - can be griefed
    payable(previousBidder).transfer(previousBid);
    highestBid = msg.value;
}
```

**Impact:**
- Economic damage to protocol users
- Service disruption
- Wasted gas fees
- User frustration leading to protocol abandonment

**Mitigation:**
- Pull payment patterns
- Gas limits on external calls
- Economic incentives against griefing
- Whitelisting or reputation systems

### 5. Push vs Pull Payment Patterns

**Push Pattern (Vulnerable):**
```solidity
function distribute() public {
    for (uint i = 0; i < recipients.length; i++) {
        recipients[i].transfer(amounts[i]); // Can fail
    }
}
```

**Pull Pattern (Safe):**
```solidity
mapping(address => uint) public pendingWithdrawals;

function withdraw() public {
    uint amount = pendingWithdrawals[msg.sender];
    pendingWithdrawals[msg.sender] = 0;
    payable(msg.sender).transfer(amount);
}
```

**Benefits of Pull Pattern:**
- Each user controls their own withdrawal
- One failing transfer doesn't affect others
- Predictable gas costs
- No array iteration needed

### 6. msg.sender Blocking

**Vulnerability:**
Malicious contracts can revert in their fallback function to block operations that depend on sending them funds.

**Example:**
```solidity
contract Auction {
    function bid() public payable {
        require(msg.value > highestBid);
        // This can be blocked by current leader
        payable(currentLeader).transfer(previousBid);
        currentLeader = msg.sender;
    }
}

contract MaliciousBlocker {
    receive() external payable {
        revert("I block refunds!");
    }
}
```

**Impact:**
- Auctions become stuck
- Legitimate users can't participate
- Contract functionality breaks down

**Mitigation:**
- Pull payment patterns
- Graceful handling of failed transfers
- Allow admin override in extreme cases
- Blacklist mechanisms (use carefully)

## Gas Optimization Techniques

### 1. Pagination

```solidity
function processInBatches(uint start, uint end) public {
    require(end <= users.length);
    require(end > start);
    require(end - start <= MAX_BATCH_SIZE);

    for (uint i = start; i < end; i++) {
        // Process users[i]
    }
}
```

### 2. Pull Payments

```solidity
mapping(address => uint) public pendingPayments;

function claim() public {
    uint amount = pendingPayments[msg.sender];
    require(amount > 0);
    pendingPaydrawals[msg.sender] = 0;
    payable(msg.sender).transfer(amount);
}
```

### 3. Gas-Limited External Calls

```solidity
(bool success, ) = recipient.call{value: amount, gas: 2300}("");
if (!success) {
    // Handle failure gracefully
    pendingWithdrawals[recipient] += amount;
    emit WithdrawalFailed(recipient, amount);
}
```

### 4. Bounded Loops

```solidity
uint constant MAX_PARTICIPANTS = 100;

function addParticipant(address user) public {
    require(participants.length < MAX_PARTICIPANTS);
    participants.push(user);
}
```

## Project Structure

```
37-gas-dos-attacks/
├── README.md
├── src/
│   ├── Project37.sol                      # Skeleton with TODOs
│   └── solution/
│       └── Project37Solution.sol          # Complete implementation
├── test/
│   └── Project37.t.sol                    # Comprehensive tests
└── script/
    └── DeployProject37.s.sol              # Deployment script
```

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/GasDoSAttacksSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployGasDoSAttacksSolution.s.sol` - Deployment script patterns
- `test/solution/GasDoSAttacksSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains denial-of-service attacks, unbounded loops, gas limit exploitation
- **Connections to Project 06**: Array iteration costs and DoS risks
- **Connections to Project 12**: Pull payment pattern prevents DoS
- **Real-World Context**: DoS attacks can make contracts unusable - critical to prevent

## Getting Started

### Prerequisites

- Foundry installed
- Basic understanding of Solidity
- Knowledge of gas mechanics

### Installation

```bash
# Navigate to project directory
cd 37-gas-dos-attacks

# Install dependencies
forge install

# Build the project
forge build
```

### Running Tests

```bash
# Run all tests
forge test

# Run with gas reporting
forge test --gas-report

# Run with verbosity to see gas details
forge test -vvv

# Run specific test
forge test --match-test testUnboundedLoopDoS
```

## Exercises

### Exercise 1: Unbounded Loop Attack
1. Review the `VulnerableAirdrop` contract
2. Add participants until the `distribute()` function fails
3. Calculate the gas cost growth rate
4. Implement the pull payment solution

### Exercise 2: Auction Griefing
1. Study the `VulnerableAuction` contract
2. Create a malicious bidder that blocks refunds
3. Demonstrate the DoS attack
4. Implement the pull pattern fix

### Exercise 3: Block Gas Limit
1. Analyze the `MassPayment` contract
2. Calculate maximum recipients before hitting gas limit
3. Test the pagination solution
4. Compare gas costs between push and pull patterns

### Exercise 4: Expensive Fallback
1. Create a contract with an expensive receive function
2. Make it a recipient in the auction
3. Show how it DoSes the auction
4. Implement graceful failure handling

## Key Takeaways

1. **Never use unbounded loops** over dynamic arrays in critical functions
2. **Always prefer pull over push** for payments and distributions
3. **Limit gas for external calls** to prevent griefing
4. **Implement pagination** for operations over large datasets
5. **Handle external call failures gracefully** - never assume they succeed
6. **Consider economic incentives** that might motivate DoS attacks
7. **Test gas costs** at scale before deployment
8. **Monitor contract state growth** in production

## Common Patterns to Avoid

❌ **Never do this:**
```solidity
// Unbounded loop with external calls
for (uint i = 0; i < users.length; i++) {
    users[i].transfer(amounts[i]);
}

// Assuming external calls succeed
payable(user).transfer(amount);
nextOperation(); // This won't run if transfer fails

// No bounds checking
function addUser(address user) public {
    users.push(user); // Can grow infinitely
}
```

✅ **Do this instead:**
```solidity
// Pull payment pattern
mapping(address => uint) public withdrawals;
function withdraw() public {
    uint amount = withdrawals[msg.sender];
    withdrawals[msg.sender] = 0;
    payable(msg.sender).transfer(amount);
}

// Graceful failure handling
(bool success, ) = user.call{value: amount}("");
if (!success) {
    withdrawals[user] += amount;
}

// Bounded growth
require(users.length < MAX_USERS);
users.push(user);
```

## Real-World Examples

### GovernMental (2016)
- Ponzi scheme contract with unbounded loop
- Became unusable when participant array grew too large
- ~1100 ETH locked forever
- Classic example of DoS by block gas limit

### King of the Ether (2016)
- Auction contract using push payments
- Malicious contract could become "king" and refuse payments
- Prevented anyone else from claiming the throne
- Fixed by implementing pull payments

## Gas Analysis

### Unbounded Loop Growth
```
10 participants:   ~50,000 gas
100 participants:  ~500,000 gas
1000 participants: ~5,000,000 gas
2000 participants: Exceeds block limit (30M gas)
```

### Pull vs Push Comparison
```
Push to 100 users:  ~5,000,000 gas (single transaction)
Pull (per user):    ~50,000 gas (100 transactions)
                    Total: ~5,000,000 gas
```

**Key Difference:** Pull pattern distributes gas cost across users and prevents DoS.

## Additional Resources

- [Consensys Smart Contract Best Practices - DoS](https://consensys.github.io/smart-contract-best-practices/attacks/denial-of-service/)
- [SWC-128: DoS with Block Gas Limit](https://swcregistry.io/docs/SWC-128)
- [SWC-113: DoS with Failed Call](https://swcregistry.io/docs/SWC-113)
- [Ethereum Block Gas Limit](https://ethereum.org/en/developers/docs/gas/)

## Security Checklist

- [ ] No unbounded loops in critical functions
- [ ] All payment distributions use pull pattern
- [ ] External calls have gas limits or failure handling
- [ ] Array growth is bounded or paginated
- [ ] Gas costs tested at realistic scale
- [ ] No assumptions about external call success
- [ ] Fallback functions are minimal
- [ ] Economic incentives considered for griefing

## License

MIT License - Educational purposes only

## Disclaimer

This project contains intentionally vulnerable contracts for educational purposes. Never deploy these contracts to mainnet with real funds. Always conduct thorough security audits before deploying smart contracts.

---


## 38-signature-replay

# Project 38: Signature Replay Attack

Learn about signature replay vulnerabilities and how to protect against them in Solidity smart contracts.

## Overview

Signature replay attacks occur when a valid signature can be reused maliciously in ways not intended by the signer. This project explores various replay attack vectors and demonstrates proper defenses using nonces, chainID, domain separators, and EIP-712.

## Vulnerability Categories

### 1. Missing Nonce Vulnerability: Infinite Replay

**FIRST PRINCIPLES: Signature Uniqueness**

The most common replay attack occurs when contracts don't track which signatures have been used. Signatures must be unique per transaction!

**CONNECTION TO PROJECT 19 & 23**:
- **Project 19**: We learned about EIP-712 signatures
- **Project 23**: ERC20 Permit uses signatures with nonces
- **Project 38**: Missing nonces allow signature replay attacks!

**THE VULNERABILITY**:

```solidity
// ❌ VULNERABLE: Signature can be replayed infinitely
function transfer(address to, uint256 amount, bytes memory signature) external {
    bytes32 message = keccak256(abi.encodePacked(to, amount));
    address signer = recover(message, signature);  // From Project 19!
    // ❌ No nonce tracking - signature can be reused!
    _transfer(signer, to, amount);
}
```

**ATTACK SCENARIO**:

```
Signature Replay Attack:
┌─────────────────────────────────────────┐
│ User signs: transfer(alice, 100)        │
│   Signature: 0xABCD...                 │ ← Valid signature
│   ↓                                      │
│ Legitimate use:                         │
│   Contract verifies signature ✅         │
│   Transfers 100 tokens                  │
│   ↓                                      │
│ Attacker observes transaction           │ ← Mempool observation
│   ↓                                      │
│ Attacker replays same signature         │ ← Reuse signature!
│   Contract verifies signature ✅         │ ← Still valid!
│   Transfers 100 tokens again            │ ← Funds drained!
│   ↓                                      │
│ Attacker repeats infinitely             │ ← Can replay forever!
└─────────────────────────────────────────┘
```

**WHY IT WORKS**:
- Signature is valid for the message (to, amount)
- No tracking of used signatures
- Same signature can be submitted multiple times
- Each submission transfers funds!

**THE FIX** (Nonce Tracking):

```solidity
// ✅ SAFE: Nonce tracking prevents replay
mapping(address => uint256) public nonces;  // From Project 01!

function transfer(
    address to, 
    uint256 amount, 
    uint256 nonce,  // ✅ Include nonce!
    bytes memory signature
) external {
    require(nonce == nonces[msg.sender], "Invalid nonce");  // ✅ Check nonce
    nonces[msg.sender]++;  // ✅ Increment nonce (prevents replay!)
    
    bytes32 message = keccak256(abi.encodePacked(to, amount, nonce));  // ✅ Include nonce in message
    address signer = recover(message, signature);
    require(signer == msg.sender, "Invalid signature");
    
    _transfer(signer, to, amount);
}
```

**HOW NONCES PREVENT REPLAY**:

```
Nonce Protection Flow:
┌─────────────────────────────────────────┐
│ User signs: transfer(alice, 100, nonce=5)│
│   Signature: 0xABCD...                  │ ← Includes nonce
│   ↓                                      │
│ First use:                              │
│   Check: nonce == 5? ✅                 │ ← Matches!
│   nonces[user] = 6                      │ ← Incremented
│   Transfer succeeds                     │
│   ↓                                      │
│ Attacker replays signature:             │
│   Check: nonce == 5? ❌                 │ ← Nonce is now 6!
│   Transaction REVERTS                   │ ← Replay prevented!
└─────────────────────────────────────────┘
```

**GAS COST** (from Project 01 & 19 knowledge):
- Nonce check: ~100 gas (SLOAD)
- Nonce increment: ~5,000 gas (SSTORE)
- Signature verification: ~3,000 gas (ecrecover)
- Total: ~8,100 gas (small cost for security!)

**REAL-WORLD ANALOGY**: 
Like a checkbook - each check has a unique number. If you reuse a check number, the bank rejects it. Nonces are like check numbers - each signature must have a unique nonce!

### 2. ChainID Replay Attack
Without chainID in signatures, they can be replayed across different blockchain networks:
```solidity
// VULNERABLE: Works on mainnet, can replay on testnets or forks
bytes32 message = keccak256(abi.encodePacked(to, amount, nonce));
```

**Attack**: Use a signature from mainnet on a testnet, or replay after a hard fork.

### 3. Cross-Contract Replay
Signatures valid for one contract can be replayed on another contract:
```solidity
// VULNERABLE: Missing contract address in message
bytes32 message = keccak256(abi.encodePacked(to, amount, nonce));
```

**Attack**: Use a signature intended for ContractA on ContractB.

### 4. Timestamp-Only Protection (Weak)
Using only timestamps for replay protection is insufficient:
```solidity
// WEAK: Attacker can replay within the time window
function transfer(uint256 deadline, ...) external {
    require(block.timestamp <= deadline, "Expired");
    // No nonce - can replay until deadline!
}
```

## Proper Defenses

### Defense 1: Nonce Tracking
Track used nonces per user:
```solidity
mapping(address => uint256) public nonces;

function transfer(address to, uint256 amount, uint256 nonce, bytes memory sig) external {
    require(nonce == nonces[msg.sender], "Invalid nonce");
    nonces[msg.sender]++;

    bytes32 message = keccak256(abi.encodePacked(to, amount, nonce));
    address signer = recover(message, sig);
    require(signer == msg.sender, "Invalid signature");

    _transfer(signer, to, amount);
}
```

### Defense 2: ChainID Protection
Include chainID in the message:
```solidity
bytes32 message = keccak256(abi.encodePacked(
    to,
    amount,
    nonce,
    block.chainid  // Prevents cross-chain replay
));
```

### Defense 3: Domain Separator (EIP-712)
Use EIP-712 structured data hashing:
```solidity
bytes32 public DOMAIN_SEPARATOR;

constructor() {
    DOMAIN_SEPARATOR = keccak256(abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes("MyContract")),
        keccak256(bytes("1")),
        block.chainid,
        address(this)
    ));
}

function hashTypedData(bytes32 structHash) internal view returns (bytes32) {
    return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
}
```

### Defense 4: Signature Invalidation
Allow users to invalidate signatures:
```solidity
mapping(bytes32 => bool) public invalidatedSignatures;

function invalidateSignature(bytes32 sigHash) external {
    invalidatedSignatures[sigHash] = true;
}
```

## EIP-712 Standard

EIP-712 provides structured, human-readable signatures with built-in replay protection:

```solidity
// Define typed data structure
bytes32 public constant TRANSFER_TYPEHASH = keccak256(
    "Transfer(address from,address to,uint256 amount,uint256 nonce)"
);

function verifyTransferSignature(
    address from,
    address to,
    uint256 amount,
    uint256 nonce,
    bytes memory signature
) internal view returns (bool) {
    bytes32 structHash = keccak256(abi.encode(
        TRANSFER_TYPEHASH,
        from,
        to,
        amount,
        nonce
    ));

    bytes32 digest = keccak256(abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        structHash
    ));

    address signer = ECDSA.recover(digest, signature);
    return signer == from && nonces[from] == nonce;
}
```

## Real-World Replay Exploits

### 1. Classic Ethereum (ETC) Replay (2016)
After the DAO hard fork, transactions on Ethereum mainnet could be replayed on Ethereum Classic because chainID wasn't universally implemented.

**Impact**: Millions of dollars in unintended transfers.

### 2. Wintermute Hack (2022)
While not purely a replay attack, missing signature validation allowed unauthorized transfers.

**Impact**: $160 million loss.

### 3. Multiple DEX Permit Exploits (2020-2023)
DEXs using EIP-2612 permits without proper nonce/deadline checks suffered replay attacks.

**Impact**: Various losses from repeated permit executions.

### 4. Cross-Chain Bridge Replays
Several bridges lacked proper chainID validation, allowing signatures to be replayed on different chains.

**Impact**: Double-spending across chains.

## Attack Scenarios

### Scenario 1: Token Transfer Replay
```solidity
// User signs: "Transfer 100 tokens to Alice"
// Attacker: Replays signature 10 times
// Result: 1000 tokens transferred instead of 100
```

### Scenario 2: Voting Replay
```solidity
// User signs: "Vote Yes on Proposal #5"
// Attacker: Replays signature multiple times
// Result: Vote count manipulated
```

### Scenario 3: Cross-Chain Airdrop Abuse
```solidity
// User signs airdrop claim on testnet
// Attacker: Replays on mainnet
// Result: Unauthorized mainnet claim
```

### Scenario 4: Meta-Transaction Replay
```solidity
// User signs gasless transaction
// Relayer: Submits transaction
// Attacker: Front-runs and replays
// Result: Double execution, user pays twice
```

## Best Practices

1. **Always Use Nonces**: Track per-user nonces for sequential ordering
2. **Include ChainID**: Prevent cross-chain replay attacks
3. **Use EIP-712**: Standard format for structured, safe signatures
4. **Add Contract Address**: Prevent cross-contract replay
5. **Implement Deadlines**: Add expiration for time-sensitive operations
6. **Signature Invalidation**: Allow users to revoke signatures
7. **Audit Carefully**: Signature logic is complex and error-prone

## Common Pitfalls

- Forgetting to increment nonces after use
- Using `block.timestamp` alone without nonces
- Not including chainID in signature messages
- Reusing signatures across different functions
- Allowing zero address as signer
- Not validating signature length
- Missing domain separator updates on upgrades

## Connection to Project 19

Project 19 covers basic signature verification and ECDSA. This project extends those concepts to:
- Advanced signature security
- Replay attack prevention
- Production-ready signature schemes
- EIP-712 implementation

## Learning Objectives

After completing this project, you will understand:
1. How signature replay attacks work
2. Why nonces are critical for signature security
3. The importance of chainID and domain separators
4. How to implement EIP-712 properly
5. Real-world replay attack vectors
6. Best practices for signature verification

## Testing Guide

The test suite demonstrates:
- Basic replay attacks on vulnerable contracts
- Nonce protection effectiveness
- ChainID validation
- Cross-contract replay prevention
- EIP-712 signature verification
- Proper signature invalidation

## Project Structure

```
38-signature-replay/
├── README.md                          # This file
├── src/
│   ├── Project38.sol                  # Skeleton with TODOs
│   └── solution/
│       └── Project38Solution.sol      # Complete implementation
├── test/
│   └── Project38.t.sol                # Comprehensive tests
└── script/
    └── DeployProject38.s.sol          # Deployment script
```

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/SignatureReplaySolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeploySignatureReplaySolution.s.sol` - Deployment script patterns
- `test/solution/SignatureReplaySolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains signature replay attacks, nonce-based protection, chainId separation
- **Connections to Project 19**: EIP-712 signatures (this shows replay protection)
- **Connections to Project 13**: Time-based deadlines for signature expiration
- **Real-World Context**: Replay attacks can drain funds - nonces and chainId are essential

## Resources

- [EIP-712: Typed Structured Data Hashing](https://eips.ethereum.org/EIPS/eip-712)
- [EIP-2612: Permit Extension for ERC-20](https://eips.ethereum.org/EIPS/eip-2612)
- [OpenZeppelin ECDSA Library](https://docs.openzeppelin.com/contracts/4.x/api/utils#ECDSA)
- [Consensys: Signature Replay Attacks](https://consensys.github.io/smart-contract-best-practices/attacks/replay-attacks/)

## Setup

```bash
# Install dependencies
forge install

# Run tests
forge test --match-path test/Project38.t.sol -vvv

# Run specific test
forge test --match-test testReplayAttack -vvv

# Deploy
forge script script/DeployProject38.s.sol --rpc-url $RPC_URL --broadcast
```

## Exercises

1. **Basic Replay**: Exploit the vulnerable contract by replaying a signature
2. **Add Nonce Protection**: Fix the vulnerable contract with nonce tracking
3. **ChainID Attack**: Demonstrate cross-chain replay vulnerability
4. **Implement EIP-712**: Create a secure signature scheme using EIP-712
5. **Cross-Contract Replay**: Show how signatures can be replayed across contracts
6. **Advanced Defense**: Combine multiple protections for maximum security

## Security Checklist

- [ ] Nonces implemented and incremented
- [ ] ChainID included in signature
- [ ] Contract address in domain separator
- [ ] EIP-712 standard followed
- [ ] Signature length validated
- [ ] Zero address checks present
- [ ] Deadline/expiration implemented
- [ ] Tests cover replay scenarios
- [ ] Signature invalidation available
- [ ] No signature reuse across functions

---

**Remember**: Signature security is critical. A single mistake can lead to catastrophic fund loss. Always use established standards like EIP-712 and thoroughly test signature handling logic.

---


## 39-governance-attack

# Project 39: Governance Attack Simulation

Learn about DAO governance vulnerabilities and how attackers exploit voting mechanisms through flashloans, vote buying, and other attack vectors.

## Overview

Decentralized Autonomous Organizations (DAOs) rely on token-based governance where token holders vote on proposals. However, this system is vulnerable to various attacks that can compromise the integrity of governance decisions. This project demonstrates real-world governance attack vectors and defensive patterns.

## Governance Attack Vectors

### 1. Flashloan Governance Attacks: Borrowed Voting Power

**FIRST PRINCIPLES: Token-Based Voting**

Many DAOs use token balance as voting power. Attackers can flashloan massive amounts of governance tokens, vote on proposals, and return the tokens in the same transaction.

**CONNECTION TO PROJECT 08 & 33**:
- **Project 08**: ERC20 tokens (governance tokens are ERC20)
- **Project 33**: MEV and flashloans (borrowing for manipulation)
- **Project 39**: Flashloans used to manipulate governance!

**UNDERSTANDING THE VULNERABILITY**:

**THE PROBLEM**:
```solidity
// ❌ VULNERABLE: Voting power = current balance
function vote(uint256 proposalId, bool support) public {
    uint256 votingPower = governanceToken.balanceOf(msg.sender);  // Current balance!
    // Attacker can flashloan tokens, vote, return tokens!
    proposals[proposalId].votes[msg.sender] = votingPower;
}
```

**ATTACK FLOW**:

```
Flashloan Governance Attack:
┌─────────────────────────────────────────┐
│ Step 1: Attacker creates proposal        │
│   Proposal: "Send funds to attacker"     │ ← Malicious proposal
│   ↓                                      │
│ Step 2: Flashloan governance tokens      │
│   Borrow: 1,000,000 tokens (no collateral!)│ ← From Project 33
│   ↓                                      │
│ Step 3: Vote with borrowed tokens        │
│   votingPower = 1,000,000 tokens         │ ← Massive voting power!
│   Vote: YES                              │
│   ↓                                      │
│ Step 4: Proposal passes                  │
│   Attacker has majority voting power     │ ← Proposal approved!
│   ↓                                      │
│ Step 5: Return flashloan                 │
│   Return: 1,000,000 tokens                │ ← No tokens owned!
│   ↓                                      │
│ Step 6: Proposal executes later          │
│   Funds sent to attacker                 │ ← Attack succeeds!
└─────────────────────────────────────────┘
```

**REAL EXAMPLE**:
- **Beanstalk DAO (April 2022)**: Attacker used flashloans to acquire 79% voting power, passed a malicious proposal that drained $182M
- The attacker borrowed over $1B in assets across multiple DeFi protocols to gain voting majority
- All in a single transaction (atomic attack)!

**WHY IT WORKS**:
- Voting power = current token balance (not historical)
- Flashloans provide unlimited capital (no collateral needed)
- Atomic transactions (borrow, vote, repay in one TX)
- No time delay between borrowing and voting

**THE FIX** (Snapshot Voting Power):

```solidity
// ✅ SAFE: Snapshot voting power at proposal creation
mapping(uint256 => mapping(address => uint256)) public votingPowerSnapshots;  // From Project 01!

function createProposal(...) public {
    uint256 proposalId = nextProposalId++;
    // ✅ Snapshot voting power NOW (can't be manipulated later!)
    votingPowerSnapshots[proposalId][msg.sender] = governanceToken.balanceOf(msg.sender);
    // ... create proposal
}

function vote(uint256 proposalId, bool support) public {
    // ✅ Use snapshot, not current balance!
    uint256 votingPower = votingPowerSnapshots[proposalId][msg.sender];
    require(votingPower > 0, "No voting power");
    // ... record vote
}
```

**GAS COST** (from Project 01 knowledge):
- Snapshot: ~20,000 gas (cold SSTORE) per voter
- Vote: ~100 gas (read snapshot)
- Total: ~20,100 gas per voter (one-time snapshot cost)

**REAL-WORLD ANALOGY**: 
Like an election where you can borrow votes temporarily:
- **Vulnerable**: Count votes at election time (can borrow votes!)
- **Safe**: Lock in voter eligibility at registration (can't borrow later!)

**Prevention:**
- Snapshot voting power at proposal creation time
- Require minimum lock period before tokens can vote
- Implement delegation with time delays
- Use vote escrow mechanisms (lock tokens for extended periods)

### 2. Vote Buying and Delegation Exploits

**The Vulnerability:**
Token delegation allows users to delegate voting power to others. Attackers can accumulate delegated power to manipulate votes.

**Attack Vectors:**
- Bribing token holders to delegate voting power
- Offering financial incentives for votes on specific proposals
- Creating secondary markets for voting rights
- Temporary vote lending without token transfer

**Real Example:**
- **Curve Wars**: Protocols compete to accumulate veCRV voting power to direct emissions
- Billions of dollars locked to influence governance decisions
- Creation of "vote markets" like Votium and Hidden Hand

**Prevention:**
- Implement delegation cooldown periods
- Track and limit delegation chains
- Require skin-in-the-game for voters
- Use conviction voting (voting power increases with lock time)

### 3. Quorum Manipulation

**The Vulnerability:**
DAOs often require a minimum quorum (participation threshold) for proposals to pass. Attackers can manipulate this in multiple ways.

**Attack Types:**

**A. Quorum Denial:**
- Attackers acquire tokens and don't vote
- Prevents legitimate proposals from reaching quorum
- Gridlocks the DAO

**B. Dust Attack Quorum:**
- Set very low quorum requirements
- Attacker creates proposal when participation is low
- Small amount of tokens can pass malicious proposals

**C. Quorum Inflation:**
- Use flashloans or borrowed tokens to artificially inflate participation
- Makes future quorums harder to reach organically

**Prevention:**
- Adaptive quorum based on token supply participation
- Minimum absolute vote threshold (not just percentage)
- Require sustained participation over time
- Implement quadratic voting

### 4. Proposal Spam and Griefing

**The Vulnerability:**
If proposal creation is unrestricted or has low barriers, attackers can spam the system.

**Attack Impact:**
- Flooding with junk proposals
- Legitimate proposals get buried
- Community fatigue and disengagement
- Draining treasury through proposal deposits (if refundable)

**Real Example:**
- Multiple DAOs faced spam attacks where hundreds of worthless proposals were created
- Gitcoin and other platforms had to increase proposal thresholds

**Prevention:**
- Require significant token holdings to create proposals
- Non-refundable proposal deposits
- Rate limiting on proposal creation
- Community vetting period before voting starts

### 5. Timelock Bypasses

**The Vulnerability:**
Timelocks give the community time to react to malicious proposals. However, various bypasses exist.

**Attack Vectors:**

**A. Short Timelock:**
- DAO sets timelock too short (e.g., 1 hour)
- Not enough time for community to react and exit

**B. Timelock Reduction:**
- Attacker first passes proposal to reduce timelock
- Then passes malicious proposal with shorter delay

**C. Emergency Function Abuse:**
- Many DAOs have emergency functions that bypass timelock
- If governance controls emergency functions, attackers can abuse them

**Real Example:**
- **Indexed Finance (October 2021)**: Attacker attempted to pass proposal to reduce timelock and gain control

**Prevention:**
- Set minimum timelock periods (24-48 hours minimum)
- Separate timelock for different proposal types
- Emergency functions controlled by separate multisig, not governance
- Timelock parameters should themselves have long delays to change

### 6. Malicious Proposal Execution

**The Vulnerability:**
Proposals can execute arbitrary code, allowing complete control over DAO assets.

**Attack Examples:**

**A. Treasury Drain:**
```solidity
// Malicious proposal: Transfer all treasury funds to attacker
function execute() external {
    treasury.transfer(attacker, treasury.balance);
}
```

**B. Token Minting:**
```solidity
// Mint unlimited governance tokens to attacker
function execute() external {
    governanceToken.mint(attacker, 1000000000 * 1e18);
}
```

**C. Contract Upgrade:**
```solidity
// Replace DAO logic with malicious implementation
function execute() external {
    proxy.upgradeTo(maliciousImplementation);
}
```

**D. Parameter Manipulation:**
```solidity
// Change critical parameters to attacker's benefit
function execute() external {
    dao.setQuorum(1); // Allow any vote to pass
    dao.setTimelock(0); // Remove safety delay
    dao.setAdmin(attacker); // Give attacker control
}
```

**Prevention:**
- Use proposal templates with limited actions
- Implement proposal validation and whitelisting
- Require multiple separate proposals for critical changes
- Add proposal value limits (e.g., max 5% of treasury per proposal)
- Use multisig guardians with veto power

### 7. Vote Timing Attacks

**The Vulnerability:**
Attackers exploit the timing of snapshot blocks, voting periods, and execution.

**Attack Types:**

**A. Snapshot Front-Running:**
- Attacker monitors for upcoming proposals
- Buys tokens right before snapshot block
- Votes with new tokens
- Sells immediately after snapshot

**B. Last-Minute Voting:**
- Accumulate tokens during voting period
- Wait until last block to vote
- Community can't react or counter-vote

**C. Execution Timing:**
- Time malicious proposal execution for maximum damage
- Execute during holidays, weekends, or low activity periods

**Prevention:**
- Random or delayed snapshot blocks
- Minimum token holding period before voting
- Extended timelock after vote passes
- Active monitoring and alerting systems

## Real-World DAO Hacks

### 1. Beanstalk DAO - $182M (April 2022)
- **Attack**: Flashloan governance attack
- **Method**: Borrowed $1B in crypto via flashloans to gain 67% voting power
- **Outcome**: Passed malicious proposal that drained treasury
- **Key Lesson**: Never use current token balance for voting; use snapshots with time locks

### 2. Audius - $6M (July 2022)
- **Attack**: Malicious proposal execution
- **Method**: Exploited governance to make malicious proposal pass
- **Outcome**: Unauthorized token minting
- **Key Lesson**: Implement proper proposal validation and safeguards

### 3. Build Finance - $470K (February 2021)
- **Attack**: Governance takeover
- **Method**: Attacker accumulated 25% of tokens and passed malicious proposal
- **Outcome**: Treasury drained
- **Key Lesson**: Higher thresholds needed for critical operations

### 4. Indexed Finance - Attempted (October 2021)
- **Attack**: Attempted governance takeover
- **Method**: Tried to pass proposal to reduce timelock
- **Outcome**: Community detected and prevented
- **Key Lesson**: Long timelocks and active monitoring save DAOs

## Defensive Patterns

### 1. Snapshot Voting
```solidity
// Record voting power at proposal creation, not voting time
mapping(uint256 => mapping(address => uint256)) public votingPowerSnapshot;

function propose() external returns (uint256 proposalId) {
    uint256 currentBlock = block.number;
    // Take snapshot of all token balances
    votingPowerSnapshot[proposalId][msg.sender] = token.balanceOf(msg.sender);
}
```

### 2. Vote Escrow (ve-Tokenomics)
```solidity
// Users lock tokens for extended periods to gain voting power
// Longer lock = more voting power
// Prevents flashloan attacks and aligns long-term incentives
struct Lock {
    uint256 amount;
    uint256 unlockTime;
}

function votingPower(address user) public view returns (uint256) {
    Lock memory lock = locks[user];
    if (block.timestamp >= lock.unlockTime) return 0;

    uint256 timeLeft = lock.unlockTime - block.timestamp;
    // Max 4 year lock
    return lock.amount * timeLeft / 4 years;
}
```

### 3. Quadratic Voting
```solidity
// Cost to vote increases quadratically
// Prevents whales from dominating votes
function votingCost(uint256 votes) public pure returns (uint256) {
    return votes * votes;
}
```

### 4. Multi-Tier Governance
```solidity
// Different proposal types require different thresholds
enum ProposalType {
    Minor,      // 10% quorum, 51% approval
    Standard,   // 20% quorum, 66% approval
    Critical,   // 30% quorum, 75% approval
    Emergency   // Multisig only
}
```

### 5. Timelock with Guardians
```solidity
// Add guardian multisig that can veto malicious proposals
contract GovernorWithGuardian {
    address public guardian; // Multisig

    function veto(uint256 proposalId) external {
        require(msg.sender == guardian, "Only guardian");
        proposals[proposalId].vetoed = true;
    }
}
```

### 6. Rage Quit Mechanism
```solidity
// Allow token holders to exit with their share before malicious proposal executes
function rageQuit() external {
    uint256 share = (treasury.balance * token.balanceOf(msg.sender)) / token.totalSupply();
    token.burn(msg.sender, token.balanceOf(msg.sender));
    payable(msg.sender).transfer(share);
}
```

## Key Takeaways

1. **Never use current balances for voting** - Always use historical snapshots
2. **Implement meaningful timelocks** - Minimum 24-48 hours for community reaction
3. **Require skin in the game** - Lock tokens to vote, prevent flashloans
4. **Multi-tier governance** - Critical changes need higher thresholds
5. **Guardian multisigs** - Last line of defense against obvious attacks
6. **Proposal validation** - Limit what proposals can do
7. **Active monitoring** - Automated alerts for unusual proposals
8. **Emergency exits** - Allow users to leave before malicious execution

## Project Structure

```
39-governance-attack/
├── src/
│   ├── Project39.sol                 # Skeleton with TODOs
│   └── solution/
│       └── Project39Solution.sol     # Complete implementation
├── test/
│   └── Project39.t.sol              # Attack simulation tests
├── script/
│   └── DeployProject39.s.sol        # Deployment script
└── README.md
```

## Learning Objectives

After completing this project, you will understand:

1. How flashloan governance attacks work
2. Vote buying and delegation vulnerabilities
3. Quorum manipulation techniques
4. Proposal spam and griefing attacks
5. Timelock bypass methods
6. Malicious proposal execution patterns
7. Real-world DAO security incidents
8. Defensive governance patterns

## Setup

```bash
# Install dependencies
forge install

# Run tests
forge test --match-path test/Project39.t.sol -vvv

# Run specific test
forge test --match-test testFlashloanGovernanceAttack -vvvv
```

## Tasks

1. **Understand the Vulnerability**: Review the VulnerableDAO contract
2. **Implement Flashloan Attack**: Complete the FlashloanGovernanceAttacker
3. **Test Vote Buying**: Demonstrate delegation exploits
4. **Simulate Quorum Manipulation**: Show how to bypass quorum requirements
5. **Implement Defenses**: Complete the SafeDAO with protective measures
6. **Run Attack Simulations**: Execute all test cases

## Security Considerations

This project is for EDUCATIONAL PURPOSES ONLY:
- Never deploy vulnerable contracts to mainnet
- Understand attacks to build better defenses
- Real DAOs require comprehensive security audits
- Governance is a complex socio-technical problem
- No single solution prevents all attacks

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/GovernanceAttackSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployGovernanceAttackSolution.s.sol` - Deployment script patterns
- `test/solution/GovernanceAttackSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains flashloan attacks, vote buying, quorum manipulation, proposal spam
- **Connections to Project 08**: Governance tokens (ERC20 with voting power)
- **Connections to Project 40**: Multi-sig patterns (governance is multi-party decision making)
- **Real-World Context**: Governance attacks have drained millions - understanding attack vectors is critical

## Going Further

1. Research Compound and Curve governance models
2. Study ve-tokenomics and vote escrow mechanisms
3. Explore optimistic governance (Optimism's model)
4. Implement conviction voting
5. Design hybrid on-chain/off-chain governance
6. Study snapshot.org for gas-efficient voting
7. Research quadratic funding and voting

## Additional Resources

- [Beanstalk Post-Mortem](https://bean.money/blog/beanstalk-governance-exploit)
- [Curve Wars Explained](https://every.to/almanack/curve-wars)
- [Vitalik on Governance](https://vitalik.ca/general/2021/08/16/voting3.html)
- [OpenZeppelin Governor](https://docs.openzeppelin.com/contracts/4.x/governance)
- [Compound Governance](https://compound.finance/docs/governance)
- [Trail of Bits: Governance Security](https://blog.trailofbits.com/2023/03/01/dao-governance-attacks/)

## Further Reading

- **Research Papers**: "SoK: Decentralized Finance (DeFi)" - arXiv:2101.08778
- **Security Guides**: "Not So Smart Contracts" - Trail of Bits
- **Best Practices**: "Smart Contract Security Verification Standard"

---

Remember: Good governance is not just about code - it's about incentive alignment, community engagement, and thoughtful system design. Defense in depth requires technical, economic, and social safeguards.

---


## 40-multisig-wallet

# Project 40: Multi-Sig Wallet

## Overview

A multi-signature (multi-sig) wallet is a smart contract that requires multiple parties to approve a transaction before it can be executed. This is one of the most critical security patterns in blockchain development, used to protect high-value assets and critical operations.

## Learning Objectives

- Understand multi-signature wallet architecture
- Implement threshold signature schemes (M-of-N)
- Build secure transaction proposal and approval systems
- Implement replay protection for multi-sig transactions
- Handle owner management safely
- Learn from production systems like Gnosis Safe
- Apply security best practices for asset custody

## Multi-Sig Wallet Design Patterns: Secure Asset Custody

**FIRST PRINCIPLES: Distributed Trust**

A multi-signature wallet requires multiple parties to approve transactions, eliminating single points of failure. This is critical for high-value asset custody!

**CONNECTION TO PROJECT 04 & 19**:
- **Project 04**: We learned about access control and roles
- **Project 19**: We learned about EIP-712 signatures
- **Project 40**: Multi-sig combines both - multiple owners with signature verification!

### Basic Architecture

**UNDERSTANDING THE COMPONENTS**:

A multi-sig wallet typically consists of:

1. **Owner Set**: A list of authorized signers
   - From Project 01: `address[] public owners;`
   - Multiple addresses with voting power
   - Can add/remove owners (with approval)

2. **Threshold**: The minimum number of signatures required (M-of-N)
   - Example: 3-of-5 (3 signatures needed from 5 owners)
   - Balances security vs convenience
   - From Project 04: Threshold-based access control!

3. **Transaction Proposal System**: Mechanism to propose transactions
   - Anyone (or owners) can propose transactions
   - Proposals stored until approved
   - From Project 01: Structs for transaction data!

4. **Approval/Signature Collection**: Tracking who has approved
   - From Project 01: `mapping(uint256 => mapping(address => bool)) public confirmations;`
   - Nested mapping tracks approvals per transaction
   - From Project 04: Similar to role-based access control!

5. **Execution Logic**: Execute when threshold is met
   - Check: `approvalCount >= threshold`
   - Execute transaction (send ETH, call contract, etc.)
   - From Project 02: ETH transfers and external calls!

6. **Nonce System**: Prevent replay attacks
   - From Project 38: Nonces prevent signature replay!
   - Each transaction has unique nonce
   - Prevents reusing signatures

**UNDERSTANDING M-OF-N** (from Project 04 knowledge):

```
M-of-N Multi-Sig Example (3-of-5):
┌─────────────────────────────────────────┐
│ Owners: [Alice, Bob, Carol, Dave, Eve]  │ ← 5 owners
│ Threshold: 3                             │ ← Need 3 approvals
│                                          │
│ Transaction Proposal:                   │
│   Send 10 ETH to recipient             │
│   ↓                                      │
│ Approvals Collected:                    │
│   ✅ Alice approves                     │ ← 1/3
│   ✅ Bob approves                       │ ← 2/3
│   ✅ Carol approves                     │ ← 3/3 ✅ Threshold met!
│   ↓                                      │
│ Transaction Executes                    │ ← 10 ETH sent
└─────────────────────────────────────────┘
```

**GAS COST BREAKDOWN** (from Project 01 & 19 knowledge):

**On-Chain Confirmation Pattern**:
- Each confirmation: ~20,000 gas (SSTORE)
- Execution: ~23,000 gas (ETH transfer)
- Total for 3-of-5: ~83,000 gas (3 confirmations + execution)

**Off-Chain Signature Pattern**:
- Signature verification: ~3,000 gas × 3 = ~9,000 gas
- Execution: ~23,000 gas
- Total: ~32,000 gas (much cheaper!)

**REAL-WORLD ANALOGY**: 
Like a bank vault requiring multiple keys:
- **Single owner**: One key opens vault (single point of failure)
- **Multi-sig**: Multiple keys required (distributed trust)
- **Threshold**: Need M keys out of N total keys

### Design Pattern 1: On-Chain Confirmation

```solidity
// Each owner confirms on-chain
mapping(uint256 => mapping(address => bool)) public confirmations;

function confirmTransaction(uint256 txId) external onlyOwner {
    confirmations[txId][msg.sender] = true;
    emit Confirmation(msg.sender, txId);
}
```

**Pros**:
- Simple to implement
- Transparent confirmation status
- No off-chain coordination needed

**Cons**:
- Higher gas costs (each confirmation is a transaction)
- Multiple transactions required

### Design Pattern 2: Off-Chain Signatures (EIP-712)

```solidity
// Collect signatures off-chain, submit all at once
function executeWithSignatures(
    Transaction memory tx,
    bytes[] memory signatures
) external {
    bytes32 txHash = hashTransaction(tx);
    require(verifySignatures(txHash, signatures), "Invalid signatures");
    executeTx(tx);
}
```

**Pros**:
- Lower gas costs
- Single transaction for execution
- Better UX for signers

**Cons**:
- Requires off-chain coordination
- More complex signature verification
- Need to handle signature malleability

## Threshold Signature Schemes (M-of-N)

### What is M-of-N?

In an M-of-N multi-sig:
- **N** = Total number of owners
- **M** = Minimum signatures required (threshold)
- Example: 2-of-3 means 2 out of 3 owners must approve

### Choosing the Right Threshold

```
1-of-N: Single point of failure (avoid for security)
2-of-3: Good for small teams (66% agreement)
3-of-5: Good for medium teams (60% agreement)
5-of-7: Good for larger teams (71% agreement)
N-of-N: All must agree (can cause gridlock)
```

### Threshold Validation

```solidity
function isThresholdMet(uint256 txId) public view returns (bool) {
    uint256 count = 0;
    for (uint256 i = 0; i < owners.length; i++) {
        if (confirmations[txId][owners[i]]) {
            count++;
            if (count >= threshold) {
                return true;
            }
        }
    }
    return false;
}
```

## Transaction Queuing and Execution

### Transaction Lifecycle

1. **Proposal**: Owner proposes a transaction
2. **Confirmation**: Owners confirm/approve
3. **Execution**: When threshold met, anyone can execute
4. **Completion**: Transaction marked as executed

### Transaction Structure

```solidity
struct Transaction {
    address to;           // Destination address
    uint256 value;        // ETH value to send
    bytes data;           // Function call data
    bool executed;        // Execution status
    uint256 nonce;        // Replay protection
    uint256 confirmations; // Confirmation count
}
```

### Execution Patterns

**Pattern 1: Execute Immediately When Threshold Met**
```solidity
function confirmTransaction(uint256 txId) external {
    // Confirm
    confirmations[txId][msg.sender] = true;

    // Auto-execute if threshold met
    if (isThresholdMet(txId) && !transactions[txId].executed) {
        executeTransaction(txId);
    }
}
```

**Pattern 2: Separate Confirmation and Execution**
```solidity
function confirmTransaction(uint256 txId) external {
    confirmations[txId][msg.sender] = true;
}

function executeTransaction(uint256 txId) external {
    require(isThresholdMet(txId), "Threshold not met");
    require(!transactions[txId].executed, "Already executed");
    // Execute...
}
```

## Replay Protection for Multi-Sig

### Why Replay Protection?

Without replay protection, a transaction could be:
- Executed multiple times
- Re-submitted after owner changes
- Replayed on different chains (post-fork)

### Nonce-Based Protection

```solidity
uint256 public nonce;

function submitTransaction(
    address to,
    uint256 value,
    bytes calldata data
) external returns (uint256 txId) {
    txId = nonce++;
    transactions[txId] = Transaction({
        to: to,
        value: value,
        data: data,
        executed: false,
        nonce: txId
    });
}
```

### EIP-712 Structured Data Hashing

```solidity
bytes32 public constant TRANSACTION_TYPEHASH = keccak256(
    "Transaction(address to,uint256 value,bytes data,uint256 nonce)"
);

function hashTransaction(Transaction memory tx) public view returns (bytes32) {
    return keccak256(abi.encode(
        TRANSACTION_TYPEHASH,
        tx.to,
        tx.value,
        keccak256(tx.data),
        tx.nonce
    ));
}
```

### Chain ID Protection

```solidity
// Include chain ID in signature to prevent cross-chain replay
bytes32 domainSeparator = keccak256(abi.encode(
    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
    keccak256(bytes("MultiSigWallet")),
    keccak256(bytes("1")),
    block.chainid,
    address(this)
));
```

## Owner Management

### Adding Owners

```solidity
function addOwner(address newOwner) external {
    require(msg.sender == address(this), "Only via multi-sig");
    require(newOwner != address(0), "Invalid owner");
    require(!isOwner[newOwner], "Already owner");

    owners.push(newOwner);
    isOwner[newOwner] = true;

    emit OwnerAdded(newOwner);
}
```

### Removing Owners

```solidity
function removeOwner(address owner) external {
    require(msg.sender == address(this), "Only via multi-sig");
    require(isOwner[owner], "Not an owner");
    require(owners.length - 1 >= threshold, "Would break threshold");

    isOwner[owner] = false;

    // Remove from array
    for (uint256 i = 0; i < owners.length; i++) {
        if (owners[i] == owner) {
            owners[i] = owners[owners.length - 1];
            owners.pop();
            break;
        }
    }

    emit OwnerRemoved(owner);
}
```

### Changing Threshold

```solidity
function changeThreshold(uint256 newThreshold) external {
    require(msg.sender == address(this), "Only via multi-sig");
    require(newThreshold > 0, "Threshold must be > 0");
    require(newThreshold <= owners.length, "Threshold too high");

    threshold = newThreshold;
    emit ThresholdChanged(newThreshold);
}
```

### Critical Invariants

Always maintain these invariants:
- `threshold > 0`
- `threshold <= owners.length`
- `owners.length > 0`
- No duplicate owners
- No zero address owners

## Gnosis Safe Comparison

### Gnosis Safe Architecture

Gnosis Safe is the industry-standard multi-sig wallet. Key features:

1. **Modular Design**: Extensible via modules
2. **Gas Optimization**: Efficient signature verification
3. **EIP-1271**: Contract signature validation
4. **Delegate Calls**: Execute complex operations
5. **Gas Refunds**: Relayer can be reimbursed
6. **Social Recovery**: Module for account recovery

### Our Implementation vs Gnosis Safe

| Feature | Our Implementation | Gnosis Safe |
|---------|-------------------|-------------|
| Basic Multi-Sig | ✓ | ✓ |
| On-Chain Confirmations | ✓ | ✓ |
| Off-Chain Signatures | Basic | Advanced (EIP-712) |
| Modules | ✗ | ✓ |
| Gas Refunds | ✗ | ✓ |
| EIP-1271 | ✗ | ✓ |
| Delegate Calls | ✓ | ✓ |
| Upgradability | ✗ | ✓ (Proxy) |

### Key Gnosis Safe Patterns

**Pattern 1: Signature Encoding**
```solidity
// Gnosis uses packed signatures for gas efficiency
// Each signature is 65 bytes (r, s, v)
function checkNSignatures(
    bytes32 dataHash,
    bytes memory data,
    bytes memory signatures,
    uint256 requiredSignatures
) public view
```

**Pattern 2: Module System**
```solidity
// Modules can execute transactions
mapping(address => bool) public modules;

function execTransactionFromModule(
    address to,
    uint256 value,
    bytes memory data,
    Operation operation
) public returns (bool success)
```

## Security Best Practices

### 1. Prevent Signature Malleability

```solidity
// ECDSA signatures can be malleable
// Always use the lower s value
function recoverSigner(
    bytes32 hash,
    bytes memory signature
) internal pure returns (address) {
    require(signature.length == 65, "Invalid signature length");

    bytes32 r;
    bytes32 s;
    uint8 v;

    assembly {
        r := mload(add(signature, 0x20))
        s := mload(add(signature, 0x40))
        v := byte(0, mload(add(signature, 0x60)))
    }

    // Prevent signature malleability
    require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
        "Invalid signature 's' value");

    return ecrecover(hash, v, r, s);
}
```

### 2. Protect Against Reentrancy

```solidity
// Mark as executed BEFORE external call
function executeTransaction(uint256 txId) external {
    Transaction storage txn = transactions[txId];
    require(!txn.executed, "Already executed");
    require(isThresholdMet(txId), "Threshold not met");

    // CEI pattern: Mark executed first
    txn.executed = true;

    // Then make external call
    (bool success,) = txn.to.call{value: txn.value}(txn.data);
    require(success, "Transaction failed");
}
```

### 3. Validate All Inputs

```solidity
function submitTransaction(
    address to,
    uint256 value,
    bytes calldata data
) external onlyOwner returns (uint256) {
    // Validate destination
    require(to != address(0), "Invalid destination");

    // Validate value
    require(value <= address(this).balance, "Insufficient balance");

    // Validate data (if necessary)
    // For example, prevent calling selfdestruct

    // Create transaction...
}
```

### 4. Owner Management Safety

```solidity
// Never allow the last owner to be removed
require(owners.length > 1, "Cannot remove last owner");

// Never allow threshold to exceed owners
require(threshold <= owners.length, "Invalid threshold");

// Never allow zero address as owner
require(owner != address(0), "Invalid owner");
```

### 5. Gas Limits for Execution

```solidity
// Don't forward all gas to prevent gas griefing
function executeTransaction(uint256 txId) external {
    // Reserve gas for cleanup
    uint256 gasToForward = gasleft() - 5000;

    (bool success,) = txn.to.call{
        value: txn.value,
        gas: gasToForward
    }(txn.data);

    // Handle success/failure
}
```

### 6. Event Emission for Transparency

```solidity
event TransactionSubmitted(uint256 indexed txId, address indexed submitter);
event TransactionConfirmed(uint256 indexed txId, address indexed owner);
event TransactionExecuted(uint256 indexed txId);
event OwnerAdded(address indexed owner);
event OwnerRemoved(address indexed owner);
event ThresholdChanged(uint256 threshold);
```

### 7. Access Control

```solidity
modifier onlyOwner() {
    require(isOwner[msg.sender], "Not an owner");
    _;
}

modifier onlyWallet() {
    require(msg.sender == address(this), "Only wallet can call");
    _;
}
```

## Common Vulnerabilities

### 1. Confirmation Replay

**Vulnerability**: Re-using confirmations for different transactions

**Fix**: Tie confirmations to specific transaction IDs
```solidity
mapping(uint256 => mapping(address => bool)) public confirmations;
```

### 2. Missing Execution Check

**Vulnerability**: Executing a transaction multiple times

**Fix**: Track execution status
```solidity
require(!transactions[txId].executed, "Already executed");
transactions[txId].executed = true;
```

### 3. Threshold Bypass

**Vulnerability**: Executing without meeting threshold

**Fix**: Always verify threshold before execution
```solidity
require(getConfirmationCount(txId) >= threshold, "Threshold not met");
```

### 4. Owner Manipulation

**Vulnerability**: Malicious owner changes during pending transactions

**Fix**: Option 1 - Invalidate pending transactions
```solidity
function removeOwner(address owner) external {
    // Clear their confirmations
    for (uint256 i = 0; i < transactionCount; i++) {
        if (confirmations[i][owner]) {
            confirmations[i][owner] = false;
        }
    }
}
```

**Fix**: Option 2 - Require higher threshold for owner changes
```solidity
// Use separate, higher threshold for governance
uint256 public governanceThreshold;
```

### 5. Front-Running

**Vulnerability**: Attacker sees pending confirmation and front-runs

**Fix**: Implement commit-reveal or use off-chain signatures

## Testing Strategy

### Unit Tests

1. **Owner Management**
   - Add owner
   - Remove owner
   - Change threshold
   - Validate invariants

2. **Transaction Submission**
   - Submit transaction
   - Validate storage
   - Event emission

3. **Confirmation**
   - Confirm transaction
   - Prevent double confirmation
   - Count confirmations correctly

4. **Execution**
   - Execute when threshold met
   - Fail when threshold not met
   - Prevent double execution

### Integration Tests

1. **Complete Flows**
   - Submit → Confirm → Execute
   - Multiple confirmations
   - Revocation flows

2. **Edge Cases**
   - Exactly threshold confirmations
   - More than threshold
   - Threshold changes mid-flight

### Security Tests

1. **Access Control**
   - Non-owner cannot submit
   - Non-owner cannot confirm
   - Only wallet can change owners

2. **Reentrancy**
   - Test with malicious recipient
   - Verify CEI pattern

3. **Replay Protection**
   - Cannot execute twice
   - Nonce increments correctly

## Implementation Guide

### Step 1: Define State Variables

```solidity
address[] public owners;
mapping(address => bool) public isOwner;
uint256 public threshold;
uint256 public nonce;
```

### Step 2: Define Transaction Structure

```solidity
struct Transaction {
    address to;
    uint256 value;
    bytes data;
    bool executed;
}

mapping(uint256 => Transaction) public transactions;
mapping(uint256 => mapping(address => bool)) public confirmations;
```

### Step 3: Implement Constructor

```solidity
constructor(address[] memory _owners, uint256 _threshold) {
    require(_owners.length > 0, "Owners required");
    require(_threshold > 0 && _threshold <= _owners.length, "Invalid threshold");

    for (uint256 i = 0; i < _owners.length; i++) {
        require(_owners[i] != address(0), "Invalid owner");
        require(!isOwner[_owners[i]], "Duplicate owner");

        owners.push(_owners[i]);
        isOwner[_owners[i]] = true;
    }

    threshold = _threshold;
}
```

### Step 4: Implement Core Functions

1. `submitTransaction()`
2. `confirmTransaction()`
3. `revokeConfirmation()`
4. `executeTransaction()`
5. `getConfirmationCount()`

### Step 5: Implement Owner Management

1. `addOwner()`
2. `removeOwner()`
3. `changeThreshold()`

### Step 6: Add Helper Functions

1. `getOwners()`
2. `getTransactionCount()`
3. `isConfirmedBy()`

## Gas Optimization Tips

1. **Use `uint256` for loop counters** (cheaper than smaller types)
2. **Cache array length** in loops
3. **Pack struct variables** efficiently
4. **Use events instead of storage** for historical data
5. **Avoid unnecessary SLOADs** (storage reads)
6. **Use `calldata` for read-only parameters**

## Deployment Checklist

- [ ] Validate initial owners (no duplicates, no zero addresses)
- [ ] Validate threshold (> 0, <= owner count)
- [ ] Test all functions on testnet
- [ ] Verify contracts on block explorer
- [ ] Test with small amounts first
- [ ] Document all owner addresses
- [ ] Set up monitoring for events
- [ ] Plan for owner key management

## Conclusion

Multi-sig wallets are essential for:
- Protecting high-value assets
- Decentralizing control
- Preventing single points of failure
- Adding accountability and transparency

This implementation provides a solid foundation, but for production use, consider:
- Using battle-tested contracts like Gnosis Safe
- Professional security audits
- Comprehensive testing
- Proper key management procedures
- Emergency procedures

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/MultiSigWalletSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployMultiSigWalletSolution.s.sol` - Deployment script patterns
- `test/solution/MultiSigWalletSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains threshold cryptography, consensus mechanisms, state machines
- **Connections to Project 04**: Access control patterns (extended to multi-party)
- **Connections to Project 07**: CEI pattern for secure execution
- **Connections to Project 05**: Error handling for invalid transactions
- **Real-World Context**: Transaction lifecycle - Submit → Confirm (M times) → Execute

## Additional Resources

- [Gnosis Safe Contracts](https://github.com/safe-global/safe-contracts)
- [EIP-712: Typed structured data hashing](https://eips.ethereum.org/EIPS/eip-712)
- [EIP-1271: Standard Signature Validation](https://eips.ethereum.org/EIPS/eip-1271)
- [OpenZeppelin Multi-Sig](https://docs.openzeppelin.com/contracts/4.x/)
- [ConsenSys Best Practices](https://consensys.github.io/smart-contract-best-practices/)

---


## 42-vault-precision

# Project 42: ERC-4626 Precision & Rounding 🔢

> **Master the critical mathematics of vault rounding and precision**

## 🎯 Learning Objectives

By completing this project, you will:

1. **Understand rounding direction requirements** in vault operations
2. **Implement mathematically sound preview functions** that match actual behavior
3. **Handle edge cases** with zero denominators and first deposits
4. **Prevent precision-based attacks** through correct rounding
5. **Master mulDiv rounding modes** (up, down, nearest)
6. **Prove vault invariants** hold under all conditions
7. **Compare rounding strategies** and their security implications
8. **Create comprehensive test suites** for precision edge cases
9. **Understand production-grade rounding** implementations

## Why Rounding Matters: Precision and Security

**FIRST PRINCIPLES: Integer Division and Rounding**

Rounding direction is critical for vault security. Understanding why rounding must favor the vault prevents precision-based attacks!

**CONNECTION TO PROJECT 11 & 20**:
- **Project 11**: ERC-4626 vaults use share-based accounting
- **Project 20**: We learned share calculation fundamentals
- **Project 42**: We dive deep into rounding precision and security!

### The Golden Rule of Vault Rounding

**ROUNDING MUST ALWAYS FAVOR THE VAULT** to maintain security and solvency.

**UNDERSTANDING THE RULES**:

- **Deposit/Mint**: Round DOWN shares given to user
  - User deposits assets, vault gives shares
  - Give fewer shares = vault favorable (vault keeps extra)
  - Formula: `shares = (assets * totalShares) / totalAssets` (rounds down)

- **Withdraw/Redeem**: Round UP assets taken from vault
  - User burns shares, vault gives assets
  - Take more assets from user (fewer assets out) = vault favorable
  - Formula: `assets = (shares * totalAssets + totalShares - 1) / totalShares` (rounds up)

**WHY THIS MATTERS** (Mathematical Proof):

```
Example: Deposit 100.5 assets
┌─────────────────────────────────────────┐
│ totalAssets = 1000                      │
│ totalShares = 1000                      │
│ Exchange rate: 1.0                      │
│                                          │
│ User deposits: 100.5 assets             │
│                                          │
│ Calculation:                            │
│   shares = (100.5 * 1000) / 1000       │
│   shares = 100500 / 1000                │
│   shares = 100.5 (but must be integer!) │
│                                          │
│ Round DOWN: shares = 100                │ ← Vault keeps 0.5 assets
│ Round UP: shares = 101                   │ ← Vault loses 0.5 assets ❌
└─────────────────────────────────────────┘
```

**SECURITY IMPLICATIONS**:

Incorrect rounding can lead to:

1. **Vault Insolvency**: Users can extract more value than deposited
   ```solidity
   // ❌ WRONG: Rounding up on withdraw
   assets = (shares * totalAssets + totalShares - 1) / totalShares;  // Rounds UP
   // User gets MORE assets than they should!
   // Vault becomes insolvent over time!
   ```

2. **Inflation Attacks**: First depositor can manipulate share price
   - Deposit 1 wei → get 1 share
   - Donate 1,000,000 tokens directly to vault
   - Withdraw: Get 1,000,000 tokens for 1 share!
   - If rounding wrong, attacker profits!

3. **Precision Drain**: Repeated operations drain vault reserves
   - Each operation with wrong rounding loses small amount
   - Over many operations, losses accumulate
   - Vault becomes insolvent

4. **Share Manipulation**: Attackers exploit rounding to steal funds
   - Precision errors can be amplified
   - Rounding direction determines who benefits

**REAL-WORLD ANALOGY**: 
Like a bank rounding:
- **Round DOWN deposits**: Bank keeps extra (vault favorable)
- **Round UP withdrawals**: Bank gives less (vault favorable)
- **Wrong direction**: Bank loses money over time (insolvency!)

## Mathematical Foundation

### Share-Asset Conversion Formula

```
shares = assets × totalShares / totalAssets
assets = shares × totalAssets / totalShares
```

### Rounding Modes in mulDiv

When computing `(a × b) / c`:

- **Round DOWN**: `(a × b) / c` (default division)
- **Round UP**: `(a × b + c - 1) / c` (add denominator - 1)

Mathematical proof of round-up formula:
```
Let q = (a × b) / c (rounded down)
Let r = (a × b) % c (remainder)

If r > 0:
  (a × b + c - 1) / c = (q × c + r + c - 1) / c
                      = q + (r + c - 1) / c
                      = q + 1  (since 0 < r < c, so c ≤ r + c - 1 < 2c)

If r = 0:
  (a × b + c - 1) / c = (q × c + c - 1) / c
                      = q  (since c - 1 < c)

Result: Rounds up exactly when remainder exists
```

## ERC-4626 Function Rounding Requirements

### Deposit Functions

```solidity
function deposit(uint256 assets, address receiver) returns (uint256 shares)
```

**Rounding**: MUST round DOWN shares
- User gives assets → receives shares
- Fewer shares = vault keeps more value per share

**Formula**:
```
shares = (assets × totalSupply) / totalAssets  // Round DOWN
```

### Mint Functions

```solidity
function mint(uint256 shares, address receiver) returns (uint256 assets)
```

**Rounding**: MUST round UP assets required
- User wants shares → must pay assets
- More assets required = vault favorable

**Formula**:
```
assets = roundUp((shares × totalAssets) / totalSupply)  // Round UP
```

### Withdraw Functions

```solidity
function withdraw(uint256 assets, address receiver, address owner) returns (uint256 shares)
```

**Rounding**: MUST round UP shares burned
- User wants assets out → must burn shares
- More shares burned = vault keeps more

**Formula**:
```
shares = roundUp((assets × totalSupply) / totalAssets)  // Round UP
```

### Redeem Functions

```solidity
function redeem(uint256 shares, address receiver, address owner) returns (uint256 assets)
```

**Rounding**: MUST round DOWN assets given
- User burns shares → receives assets
- Fewer assets given = vault favorable

**Formula**:
```
assets = (shares × totalAssets) / totalSupply  // Round DOWN
```

## Preview Functions

Preview functions MUST match the rounding of their corresponding action:

```solidity
previewDeposit  → round DOWN (matches deposit)
previewMint     → round UP   (matches mint)
previewWithdraw → round UP   (matches withdraw)
previewRedeem   → round DOWN (matches redeem)
```

Per EIP-4626 specification:
> "MUST return as close to and no fewer than the exact amount of shares
> that would be minted in a deposit call in the same transaction."

## Edge Cases

### Zero Total Supply (Empty Vault)

When `totalSupply == 0`:

```solidity
// First deposit: 1:1 ratio
shares = assets  // Initial deposit is 1:1
```

**Critical**: First depositor sets initial exchange rate!

### Zero Total Assets

When `totalAssets == 0` but `totalSupply > 0`:

**This is a CRITICAL state** indicating:
- Vault has been drained
- Loss event occurred
- Accounting error

**Handling**:
```solidity
// Shares are worthless - conversions should return 0
if (totalAssets == 0 && totalSupply > 0) {
    return 0;  // Shares have no value
}
```

### Division by Zero

Always check denominators:

```solidity
// Converting assets to shares
if (totalAssets == 0) {
    return assets;  // 1:1 for empty vault
}
shares = (assets × totalSupply) / totalAssets;

// Converting shares to assets
if (totalSupply == 0) {
    return 0;  // No shares exist, no assets owed
}
assets = (shares × totalAssets) / totalSupply;
```

## Precision Loss

### The Rounding Tax

Every conversion potentially loses 1 wei due to rounding:

```solidity
// User deposits 100 assets
deposit(100)  → receives 99 shares (rounded down)

// If exchange rate is 1:1, lost 1 share worth of value
```

Over many small operations, precision loss accumulates in vault's favor.

### Mitigation

1. **Minimum Deposit Amount**: Prevent dust deposits
2. **Virtual Shares**: Add offset to prevent inflation attacks
3. **Dead Shares**: Lock initial liquidity

## Attack Scenarios

### 1. Inflation Attack

**Setup**:
1. Attacker is first depositor
2. Deposits 1 wei → receives 1 share
3. Directly transfers 1000e18 tokens to vault (not via deposit)
4. Exchange rate is now 1 share = 1000e18 assets

**Attack**:
1. Victim deposits 1999e18 assets
2. shares = (1999e18 × 1) / 1000e18 = 1.999 → rounds to 1 share
3. Victim lost ~1000e18 in value!

**Prevention**:
- Require minimum deposit
- Use virtual shares/assets
- Lock initial liquidity

### 2. Precision Drain

**Setup**: Vault rounds incorrectly (favors user)

**Attack**:
1. Repeatedly deposit and withdraw small amounts
2. Each round gains 1 wei due to incorrect rounding
3. 1 million operations = drain 1 million wei

**Prevention**: Always round in vault's favor

### 3. Share Dilution

**Setup**: Withdraw rounds down shares burned

**Attack**:
1. User withdraws maximum assets while burning minimum shares
2. Each withdrawal increases attacker's share percentage
3. Eventually owns disproportionate vault value

**Prevention**: Withdraw must round UP shares burned

## Implementation Requirements

### 1. MulDiv Helper

```solidity
/// @dev Multiplies two numbers and divides by a third, rounding down
function mulDiv(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
    return (a × b) / c;  // Solidity default rounds down
}

/// @dev Multiplies two numbers and divides by a third, rounding up
function mulDivUp(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
    uint256 result = (a × b) / c;
    if ((a × b) % c > 0) {
        result += 1;  // Add 1 if remainder exists
    }
    return result;
}
```

### 2. Conversion Functions

```solidity
function convertToShares(uint256 assets) public view returns (uint256) {
    uint256 supply = totalSupply();
    if (supply == 0) return assets;  // 1:1 initial

    // Round DOWN for user's benefit limit
    return mulDiv(assets, supply, totalAssets());
}

function convertToAssets(uint256 shares) public view returns (uint256) {
    uint256 supply = totalSupply();
    if (supply == 0) return 0;  // No shares = no value

    // Round DOWN for user's withdrawal limit
    return mulDiv(shares, totalAssets(), supply);
}
```

### 3. Preview Functions

```solidity
function previewDeposit(uint256 assets) public view returns (uint256) {
    return convertToShares(assets);  // Already rounds DOWN
}

function previewMint(uint256 shares) public view returns (uint256) {
    uint256 supply = totalSupply();
    if (supply == 0) return shares;  // 1:1 initial

    // Round UP - user must pay this much
    return mulDivUp(shares, totalAssets(), supply);
}

function previewWithdraw(uint256 assets) public view returns (uint256) {
    uint256 supply = totalSupply();
    if (supply == 0) return 0;

    // Round UP - user must burn this many shares
    return mulDivUp(assets, supply, totalAssets());
}

function previewRedeem(uint256 shares) public view returns (uint256) {
    return convertToAssets(shares);  // Already rounds DOWN
}
```

## Mathematical Proofs

### Invariant 1: Vault Cannot Lose Value

**Claim**: For any deposit followed by immediate redeem, vault value cannot decrease.

**Proof**:
```
User deposits A assets
  → receives S shares where S = ⌊A × T_supply / T_assets⌋

User immediately redeems S shares
  → receives B assets where B = ⌊S × T_assets / T_supply⌋

Substituting:
  B = ⌊⌊A × T_supply / T_assets⌋ × T_assets / T_supply⌋
    ≤ ⌊A × T_supply / T_assets × T_assets / T_supply⌋
    = ⌊A⌋
    = A

Therefore: B ≤ A (user gets ≤ deposited amount)
Vault net gain: A - B ≥ 0 ✓
```

### Invariant 2: User Cannot Profit from Round-Trip

**Claim**: Deposit then redeem cannot increase user's assets.

**Proof**: Same as Invariant 1, shows B ≤ A ✓

### Invariant 3: Total Value Conserved

**Claim**: Sum of (user assets) + (vault assets) remains constant.

**Proof**:
```
Initial: User has A assets, vault has V assets
After deposit: User has 0 assets + S shares, vault has V + A assets
  Total value = S × (V + A) / T_new + (V + A) = (V + A)  ✓

After redeem: User has B assets, vault has V + A - B assets
  Total value = B + (V + A - B) = V + A  ✓
```

## Testing Strategy

### Unit Tests

1. **Rounding Direction**
   - Verify deposit rounds down shares
   - Verify mint rounds up assets
   - Verify withdraw rounds up shares
   - Verify redeem rounds down assets

2. **Edge Cases**
   - Zero total supply
   - Zero total assets
   - Maximum uint256 values
   - Minimum viable amounts

3. **Precision**
   - Detect 1 wei rounding differences
   - Verify preview matches actual
   - Test with various exchange rates

### Integration Tests

1. **Round-Trip Tests**
   - Deposit → Redeem ≤ original
   - Mint → Withdraw ≥ original cost

2. **Invariant Tests**
   - Vault value never decreases
   - Total supply matches accounting

### Attack Prevention Tests

1. **Inflation Attack**
   - First depositor + donation cannot exploit victim

2. **Precision Drain**
   - Repeated small operations don't drain vault

3. **Share Dilution**
   - Cannot gain share percentage through withdrawals

## Security Checklist

- [ ] Deposit rounds DOWN shares given
- [ ] Mint rounds UP assets required
- [ ] Withdraw rounds UP shares burned
- [ ] Redeem rounds DOWN assets given
- [ ] Preview functions match action rounding
- [ ] Handle zero total supply edge case
- [ ] Handle zero total assets edge case
- [ ] No division by zero possible
- [ ] MulDiv overflow protection
- [ ] Minimum deposit enforced
- [ ] First depositor protection
- [ ] All invariants tested

## Common Mistakes

### ❌ Wrong: Rounding in User's Favor

```solidity
function deposit(uint256 assets) public returns (uint256 shares) {
    shares = mulDivUp(assets, totalSupply(), totalAssets());  // ❌ WRONG!
    // Gives user MORE shares than deserved
}
```

### ✅ Correct: Rounding in Vault's Favor

```solidity
function deposit(uint256 assets) public returns (uint256 shares) {
    shares = mulDiv(assets, totalSupply(), totalAssets());  // ✅ CORRECT
    // Gives user FEWER shares (vault keeps difference)
}
```

### ❌ Wrong: Preview Doesn't Match Action

```solidity
function previewWithdraw(uint256 assets) public view returns (uint256) {
    return convertToShares(assets);  // ❌ Rounds DOWN, but withdraw rounds UP
}
```

### ✅ Correct: Preview Matches Action

```solidity
function previewWithdraw(uint256 assets) public view returns (uint256) {
    return mulDivUp(assets, totalSupply(), totalAssets());  // ✅ CORRECT
}
```

## References

- [EIP-4626: Tokenized Vault Standard](https://eips.ethereum.org/EIPS/eip-4626)
- [OpenZeppelin ERC4626 Implementation](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC4626.sol)
- [Solmate ERC4626](https://github.com/transmissions11/solmate/blob/main/src/mixins/ERC4626.sol)
- [ERC4626 Security Considerations](https://docs.openzeppelin.com/contracts/4.x/erc4626)

## Project Tasks

1. Implement `mulDivUp` helper function
2. Implement proper rounding in deposit/mint/withdraw/redeem
3. Implement preview functions with correct rounding
4. Handle all edge cases (zero denominators)
5. Write tests proving vault invariants
6. Test attack prevention
7. Verify preview functions match actions

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/VaultPrecisionSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployVaultPrecisionSolution.s.sol` - Deployment script patterns
- `test/solution/VaultPrecisionSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains integer division rounding, precision attacks, invariant maintenance
- **Connections to Project 11**: ERC-4626 standard (this shows correct rounding)
- **Connections to Project 20**: Share-based accounting (precision critical here)
- **Connections to Project 44**: Inflation attacks (rounding prevents these)
- **Real-World Context**: Critical for vault security - rounding must favor vault to prevent insolvency

## Running the Project

```bash
# Install dependencies
forge install

# Run tests
forge test -vv

# Run with gas reporting
forge test --gas-report

# Run specific test
forge test --match-test testRoundingDirection -vvv

# Deploy
forge script script/DeployProject42.s.sol --rpc-url $RPC_URL --broadcast
```

## Success Criteria

- All tests pass
- No rounding favors users over vault
- Preview functions exactly match actions
- Edge cases handled safely
- Attack tests prove exploit prevention
- Gas-efficient implementation
- Clear mathematical comments

---

**Master vault mathematics and build secure, exploitproof tokenized vaults! 🏦**

---


## 43-yield-vault

# Project 43: Yield-Bearing Vault

A comprehensive implementation of a yield-bearing vault that integrates with external yield strategies, implements auto-compounding, and manages performance fees.

## Overview

Yield-bearing vaults are smart contracts that accept user deposits and automatically deploy those assets into yield-generating strategies. They provide:

- **Simplified Yield Access**: Users deposit once and earn yield automatically
- **Strategy Abstraction**: The vault handles complex DeFi interactions
- **Auto-Compounding**: Harvested yields are reinvested for compound growth
- **Shared Gas Costs**: One harvest benefits all depositors
- **ERC4626 Compatibility**: Standard vault interface for composability

## Learning Objectives

1. Understand yield vault mechanics and the ERC4626 standard
2. Implement strategy patterns for modular yield generation
3. Handle harvest and reinvest operations
4. Manage totalAssets() drift and share price growth
5. Calculate APY and simulate compound interest
6. Implement performance fee mechanisms
7. Integrate with lending protocols and other yield sources

## Core Concepts: Yield Generation and Share Appreciation

**FIRST PRINCIPLES: Compound Interest on Blockchain**

Yield-bearing vaults automatically generate returns for depositors. Understanding how yield accrues and affects share prices is fundamental!

**CONNECTION TO PROJECT 11 & 20**:
- **Project 11**: ERC-4626 standard for tokenized vaults
- **Project 20**: Share-based accounting fundamentals
- **Project 43**: Yield generation and auto-compounding!

### Yield-Bearing Vault Mechanics

**UNDERSTANDING YIELD ACCRUAL**:

A yield vault manages the relationship between shares and assets:

```
Initial State:
┌─────────────────────────────────────────┐
│ User deposits: 100 tokens              │
│ Receives: 100 shares (1:1 ratio)       │
│ totalAssets = 100                       │
│ totalShares = 100                       │
│ shareValue = 1.0                        │
│   ↓                                      │
│ Vault deploys to strategy               │
│   (e.g., Aave lending)                 │
│   ↓                                      │
│ Strategy generates yield:              │
│   +10 tokens (10% APY)                 │
│   ↓                                      │
│ After Yield Accrual:                    │
│   totalAssets = 110 tokens              │ ← Increased!
│   totalShares = 100 shares              │ ← Unchanged!
│   shareValue = 1.1 tokens per share    │ ← Appreciated!
│   ↓                                      │
│ User redeems 100 shares:                │
│   Gets: 110 tokens                      │ ← 10 token profit!
└─────────────────────────────────────────┘
```

**KEY FORMULA** (from Project 11 & 20 knowledge):

```
shareValue = totalAssets / totalShares

When yield accrues:
- totalAssets increases (more tokens in vault)
- totalShares stays same (no new shares minted)
- shareValue increases (each share worth more!)
```

**UNDERSTANDING AUTO-COMPOUNDING**:

```
Compound Interest Effect:
┌─────────────────────────────────────────┐
│ Year 1:                                 │
│   Deposit: 100 tokens                   │
│   Yield: 10 tokens (10%)                │
│   Total: 110 tokens                     │
│   ↓                                      │
│ Year 2:                                 │
│   Principal: 110 tokens                 │ ← Yield reinvested!
│   Yield: 11 tokens (10% of 110)        │ ← More yield!
│   Total: 121 tokens                     │ ← Compound growth!
│   ↓                                      │
│ Year 3:                                 │
│   Principal: 121 tokens                 │
│   Yield: 12.1 tokens                    │
│   Total: 133.1 tokens                  │ ← Exponential growth!
└─────────────────────────────────────────┘
```

**GAS COST BREAKDOWN** (from Project 01 & 11 knowledge):

**Deposit**:
- Share calculation: ~100 gas
- Mint shares: ~20,000 gas (cold SSTORE)
- Strategy deposit: ~50,000 gas (external call)
- Total: ~70,100 gas

**Harvest** (yield collection):
- Strategy harvest: ~100,000 gas (complex DeFi operations)
- Reinvest: ~50,000 gas
- Total: ~150,000 gas (shared across all users!)

**Withdraw**:
- Share calculation: ~100 gas
- Burn shares: ~5,000 gas (SSTORE to zero)
- Strategy withdraw: ~50,000 gas
- Total: ~55,100 gas

**REAL-WORLD ANALOGY**: 
Like a savings account with automatic reinvestment:
- **Deposit** = Put money in account
- **Yield** = Interest earned
- **Auto-compound** = Interest reinvested automatically
- **Shares** = Account balance (grows with interest)
- **Withdraw** = Take money out (get more than deposited!)

### Strategy Pattern

Vaults use pluggable strategies to generate yield:

```
┌──────────────────┐
│   Yield Vault    │
│  (User Facing)   │
└────────┬─────────┘
         │
         │ allocates funds
         ▼
┌──────────────────┐
│    Strategy      │
│ (Yield Logic)    │
└────────┬─────────┘
         │
         │ interacts with
         ▼
┌──────────────────┐
│  Yield Source    │
│ (e.g., Aave,     │
│  Compound, etc)  │
└──────────────────┘
```

**Strategy Types:**
- **Lending**: Deposit to Aave/Compound for interest
- **Staking**: Stake tokens for rewards
- **LP Farming**: Provide liquidity and farm tokens
- **Mixed**: Combine multiple strategies

### Harvest and Reinvest Mechanism

The harvest process captures accrued yield and compounds it:

```solidity
function harvest() external {
    // 1. Claim yield from strategy
    uint256 yield = strategy.harvest();

    // 2. Calculate and take performance fee
    uint256 fee = yield * performanceFee / 10000;

    // 3. Reinvest remaining yield
    uint256 reinvestAmount = yield - fee;
    strategy.deposit(reinvestAmount);

    // 4. totalAssets increases → share price increases
    // No new shares minted → existing shares worth more
}
```

### totalAssets() Drift Over Time

The `totalAssets()` value changes as yield accrues:

```
Block 100:  totalAssets = 1000 tokens
Block 200:  totalAssets = 1020 tokens (+2% yield)
Block 300:  totalAssets = 1040.4 tokens (+2% on new total)
```

This is measured without harvesting - just tracking underlying value.

### APY Calculations

**Simple Interest APY:**
```
APY = (endValue - startValue) / startValue * (365 days / timePeriod)
```

**Compound APY (more accurate):**
```
APY = (endValue / startValue) ^ (365 days / timePeriod) - 1
```

**Example:**
```
Start: 1000 tokens
After 30 days: 1020 tokens
Simple APY: (20/1000) * (365/30) = 24.33%
Compound APY: (1020/1000)^(365/30) - 1 = 27.44%
```

### Compound Interest Simulation

Compound interest occurs when harvested yield is reinvested:

```
Year 1: 100 → 110 (10% APY)
Year 2: 110 → 121 (10% on 110)
Year 3: 121 → 133.1 (10% on 121)

Formula: FV = PV * (1 + r)^t
```

**Harvest Frequency Impact:**
```
Daily Compound:   (1 + 0.10/365)^365 - 1 = 10.52% effective
Weekly Compound:  (1 + 0.10/52)^52 - 1 = 10.51% effective
Monthly Compound: (1 + 0.10/12)^12 - 1 = 10.47% effective
Yearly Compound:  (1 + 0.10/1)^1 - 1 = 10.00% effective
```

## Architecture

### Vault Components

```solidity
contract YieldVault is ERC4626 {
    IStrategy public strategy;        // Yield generation logic
    uint256 public performanceFee;    // Fee on profits (basis points)
    uint256 public lastHarvest;       // Timestamp of last harvest
    address public feeRecipient;      // Where fees go

    function deposit(uint256 assets) external {
        // Transfer assets from user
        // Deploy to strategy
        // Mint shares proportional to current share price
    }

    function withdraw(uint256 assets) external {
        // Burn shares
        // Withdraw from strategy if needed
        // Transfer assets to user
    }

    function harvest() external {
        // Claim yield from strategy
        // Take performance fee
        // Reinvest remainder
    }

    function totalAssets() public view returns (uint256) {
        // Current value of all deposited + accrued yield
        return strategy.balanceOf(address(this));
    }
}
```

### Strategy Interface

```solidity
interface IStrategy {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external returns (uint256);
    function harvest() external returns (uint256 yield);
    function balanceOf(address account) external view returns (uint256);
    function totalAssets() external view returns (uint256);
}
```

## Yield Sources Integration

### 1. Lending Protocols (Aave)

```solidity
contract AaveLendingStrategy {
    function deposit(uint256 amount) external {
        IERC20(asset).approve(address(aavePool), amount);
        aavePool.supply(asset, amount, address(this), 0);
    }

    function harvest() external returns (uint256) {
        // aTokens automatically accrue value
        uint256 currentBalance = aToken.balanceOf(address(this));
        uint256 yield = currentBalance - principalDeposited;
        return yield;
    }
}
```

### 2. Staking

```solidity
contract StakingStrategy {
    function deposit(uint256 amount) external {
        stakingContract.stake(amount);
    }

    function harvest() external returns (uint256) {
        uint256 rewards = stakingContract.claimRewards();
        // Convert rewards to underlying asset if needed
        return rewards;
    }
}
```

### 3. Liquidity Mining

```solidity
contract LPStrategy {
    function deposit(uint256 amount) external {
        // Add liquidity to pool
        // Stake LP tokens in farm
    }

    function harvest() external returns (uint256) {
        // Claim farm rewards
        // Swap rewards for underlying
        // Add to liquidity
    }
}
```

## Performance Fees

Performance fees are taken only on profits:

```solidity
// Common fee structure: 10-20% of profits
uint256 public constant PERFORMANCE_FEE = 1000; // 10%

function harvest() external {
    uint256 yield = strategy.harvest();

    // Calculate fee
    uint256 fee = yield * PERFORMANCE_FEE / 10000;

    // Fee can be:
    // 1. Transferred as tokens to treasury
    // 2. Minted as shares to treasury
    // 3. Left in vault (dilutes other users)

    if (fee > 0) {
        asset.transfer(feeRecipient, fee);
    }

    // Reinvest the rest
    uint256 reinvestAmount = yield - fee;
    strategy.deposit(reinvestAmount);
}
```

## Share Price Growth Example

```
Initial Deposit:
- Alice deposits 1000 USDC
- Gets 1000 shares
- Share price: 1.0 USDC

After 1 Month (5% yield):
- totalAssets: 1050 USDC
- totalShares: 1000
- Share price: 1.05 USDC
- Alice's value: 1050 USDC

Bob Deposits 500 USDC:
- totalAssets: 1550 USDC
- Share price: 1.05 USDC
- Bob gets: 500 / 1.05 = 476.19 shares
- totalShares: 1476.19

After Another Month (5% yield):
- totalAssets: 1550 * 1.05 = 1627.5 USDC
- totalShares: 1476.19
- Share price: 1.1025 USDC
- Alice's value: 1000 * 1.1025 = 1102.5 USDC
- Bob's value: 476.19 * 1.1025 = 525 USDC
```

## Security Considerations

1. **Strategy Risk**: Malicious or buggy strategies can lose funds
2. **Reentrancy**: Guard harvest and withdrawal functions
3. **Share Inflation**: First depositor attack mitigation
4. **Oracle Manipulation**: Don't rely on spot prices for yield
5. **Admin Keys**: Strategy changes should be timelocked
6. **Emergency Withdrawal**: Allow users to exit even if strategy fails

## Gas Optimization

1. **Batch Harvests**: One call benefits all users
2. **Lazy Accounting**: Don't update all user balances on harvest
3. **Strategy Buffers**: Keep small amount in vault for withdrawals
4. **View Functions**: Make totalAssets() a view when possible

## Testing Strategy

1. **Basic Operations**: Deposit, withdraw, share price
2. **Yield Accrual**: Simulate time passing and yield generation
3. **Harvest Mechanics**: Test fee calculation and reinvestment
4. **Edge Cases**: First depositor, empty vault, zero yield
5. **Multi-User**: Multiple deposits/withdrawals with yield
6. **Performance**: Gas costs for operations

## Project Structure

```
43-yield-vault/
├── src/
│   ├── Project43.sol              # Skeleton implementation
│   └── solution/
│       └── Project43Solution.sol  # Complete solution
├── test/
│   └── Project43.t.sol            # Comprehensive tests
├── script/
│   └── DeployProject43.s.sol      # Deployment script
└── README.md                      # This file
```

## Tasks

### Part 1: Basic Vault (Project43.sol)
- [ ] Implement ERC4626 vault structure
- [ ] Add strategy integration
- [ ] Implement deposit/withdraw logic
- [ ] Calculate share price correctly

### Part 2: Yield Strategy (Project43.sol)
- [ ] Create mock yield source
- [ ] Implement strategy deposit/withdraw
- [ ] Simulate yield accrual over time
- [ ] Track totalAssets() changes

### Part 3: Harvest Mechanism (Project43.sol)
- [ ] Implement harvest function
- [ ] Calculate performance fees
- [ ] Reinvest harvested yield
- [ ] Update accounting correctly

### Part 4: Advanced Features (Optional)
- [ ] Multiple strategy support
- [ ] Strategy migration
- [ ] Emergency pause/shutdown
- [ ] Harvest incentives (reward caller)

## Key Formulas Reference

```solidity
// Share Price
sharePrice = totalAssets / totalSupply

// Shares to Mint on Deposit
sharesToMint = depositAmount * totalSupply / totalAssets

// Assets to Return on Withdrawal
assetsToReturn = sharesToBurn * totalAssets / totalSupply

// Performance Fee
feeAmount = yieldEarned * feeBasisPoints / 10000

// APY Calculation (for display)
APY = ((finalValue / initialValue) ^ (365 days / timePeriod)) - 1

// Compound Interest
finalValue = principal * (1 + rate) ^ periods
```

## Running the Project

```bash
# Install dependencies
forge install

# Run tests
forge test --match-path test/Project43.t.sol -vv

# Run specific test with gas report
forge test --match-test test_HarvestAndCompound -vvv --gas-report

# Deploy
forge script script/DeployProject43.s.sol --rpc-url <RPC_URL> --broadcast

# Simulate yield over time
forge test --match-test test_YieldSimulation -vvv
```

## Expected Output

```
Test Harvest and Yield Accrual:
  ✓ Initial deposit: 1000 tokens → 1000 shares
  ✓ Share price: 1.0
  ✓ After 30 days: totalAssets = 1050 (+5%)
  ✓ Harvest: 50 tokens yield, 5 tokens fee
  ✓ Reinvested: 45 tokens
  ✓ New totalAssets: 1095
  ✓ Share price: 1.095
  ✓ User can withdraw 1095 tokens
```

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/YieldVaultSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployYieldVaultSolution.s.sol` - Deployment script patterns
- `test/solution/YieldVaultSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains strategy pattern, yield compounding, performance fee calculation
- **Connections to Project 11**: ERC-4626 base implementation
- **Connections to Project 20**: Share-based accounting for yield distribution
- **Connections to Project 18**: Oracle integration for strategy valuation
- **Real-World Context**: Strategies are pluggable - vault can switch strategies without user action

## Resources

- [ERC4626 Specification](https://eips.ethereum.org/EIPS/eip-4626)
- [Yearn V2 Vaults](https://docs.yearn.finance/getting-started/products/yvaults/overview)
- [Compound Interest Calculator](https://www.investor.gov/financial-tools-calculators/calculators/compound-interest-calculator)
- [Aave Protocol](https://docs.aave.com/developers/)
- [Understanding Vault Economics](https://medium.com/iearn/understanding-yearn-vaults-f5e2aa0d7bc5)

## Common Pitfalls

1. **Not Handling First Deposit**: Can lead to share inflation attacks
2. **Incorrect Share Price**: Must use totalAssets, not balance
3. **Rounding Errors**: Always favor the vault in conversions
4. **Harvest Timing**: Don't let anyone harvest too frequently
5. **Strategy Limits**: Check if strategy has deposit caps
6. **Fee Calculation**: Only on profits, not on principal

## Extensions

1. **Multi-Asset Vaults**: Accept multiple tokens
2. **Leveraged Strategies**: Borrow to amplify yields
3. **Insurance Integration**: Protect against strategy losses
4. **NFT Receipt Tokens**: More composable than fungible shares
5. **Time-Locked Deposits**: Higher APY for longer commitments

---

**Difficulty**: Advanced
**Time Estimate**: 4-6 hours
**Prerequisites**: ERC20, ERC4626, DeFi basics, compound interest math

---


## 44-inflation-attack

# Project 44: ERC-4626 Inflation Attack Demo

A comprehensive educational project demonstrating the inflation attack vulnerability in ERC-4626 vaults and various mitigation strategies.

## Overview

The inflation attack (also known as the donation attack or first depositor attack) is a critical vulnerability that can affect ERC-4626 vault implementations. This attack exploits the share calculation mechanism to steal funds from depositors through share price manipulation.

## What is an Inflation Attack? Share Price Manipulation

**FIRST PRINCIPLES: Rounding Exploitation**

An inflation attack occurs when an attacker manipulates the share price of a vault to cause rounding errors that work in their favor. This is a critical vulnerability in ERC-4626 vaults!

**CONNECTION TO PROJECT 11, 20, & 42**:
- **Project 11**: ERC-4626 vault standard
- **Project 20**: Share-based accounting fundamentals
- **Project 42**: Rounding precision and security
- **Project 44**: Inflation attack exploits rounding vulnerabilities!

**UNDERSTANDING THE ATTACK**:

The attack exploits the fundamental share calculation in ERC-4626:

```solidity
shares = assets * totalSupply / totalAssets  // From Project 11 & 20!
```

**THE VULNERABILITY**:

When `totalAssets` is much larger than `totalSupply`, small deposits can round down to zero shares, effectively donating the deposited assets to existing shareholders.

**HOW IT WORKS** (Mathematical Exploitation):

```
Normal State:
┌─────────────────────────────────────────┐
│ totalAssets = 1000                      │
│ totalShares = 1000                      │
│ Exchange rate: 1.0                      │
│                                          │
│ User deposits: 100 assets               │
│   shares = (100 * 1000) / 1000 = 100   │ ← Works fine
└─────────────────────────────────────────┘

Attacked State:
┌─────────────────────────────────────────┐
│ Attacker deposits: 1 wei                │
│   shares = 1 (first deposit)            │
│   totalAssets = 1 wei                    │
│   totalShares = 1                        │
│   ↓                                      │
│ Attacker donates: 1,000,000 tokens      │ ← Direct transfer!
│   totalAssets = 1,000,001 wei           │ ← Inflated!
│   totalShares = 1 (unchanged!)          │ ← Not increased!
│   Exchange rate: 1,000,001 wei/share   │ ← Manipulated!
│   ↓                                      │
│ Victim deposits: 1,000,000 wei          │
│   shares = (1,000,000 * 1) / 1,000,001  │
│   shares = 0.999999...                   │
│   shares = 0 (rounds down!)            │ ← Gets nothing!
│   ↓                                      │
│ Attacker redeems 1 share:              │
│   assets = (1 * 2,000,001) / 1 = 2,000,001│
│   Attacker gets victim's deposit! 💥    │
└─────────────────────────────────────────┘
```

**WHY IT WORKS**:

The attack exploits three key properties:

1. **Integer Division** (from Project 01): Solidity uses integer math, which rounds down
   - `999,999 / 1,000,000 = 0` (rounds down to zero!)

2. **External Donations**: Tokens can be sent directly to the vault
   - From Project 02: Contracts can receive tokens via `receive()` or direct transfer
   - Donation increases `totalAssets` without minting shares!

3. **Share Price Calculation**: Price = totalAssets / totalSupply
   - When assets >> shares, price is very high
   - Small deposits result in fractional shares
   - Fractional shares round down to zero!

**REAL-WORLD ANALOGY**: 
Like manipulating a stock price by donating shares to the company, then buying at the inflated price. The donation inflates the price, making small purchases worthless!

## Attack Mechanism

### Step-by-Step Attack Flow

1. **Initial Deposit (Attacker)**
   - Attacker deposits minimal amount (e.g., 1 wei)
   - Receives 1 share in return
   - State: 1 share, 1 wei assets, price = 1 wei/share

2. **Donation (Attacker)**
   - Attacker transfers large amount directly to vault (not via deposit)
   - This bypasses the normal share minting
   - State: 1 share, 1,000,001 wei assets, price = 1,000,001 wei/share

3. **Victim Deposit**
   - Victim deposits 1,000,000 wei
   - Share calculation: `1,000,000 * 1 / 1,000,001 = 0.999999...`
   - Rounds down to 0 shares!
   - State: 1 share, 2,000,001 wei assets

4. **Profit (Attacker)**
   - Attacker redeems their 1 share
   - Receives all 2,000,001 wei
   - Profit: 1,000,000 wei (victim's deposit minus attacker's costs)

### Why It Works

The attack exploits three key properties:

1. **Integer Division**: Solidity uses integer math, which rounds down
2. **External Donations**: Tokens can be sent directly to the vault
3. **Share Price Calculation**: Price = totalAssets / totalSupply

When the attacker inflates totalAssets without increasing totalSupply, they create a situation where small deposits result in fractional shares that round to zero.

## Economic Analysis

### Attack Cost vs Profit

For an attack to be profitable:
- `victimDeposit > attackerDonation + attackerInitialDeposit`

If the attacker donates D and initially deposits I:
- To steal deposit V, the victim must receive 0 shares
- This requires: `V < (totalAssets / totalSupply) = (D + I) / I`
- Simplifying: `V * I < D + I`

The attacker profits when `V > D`, meaning the victim deposits more than the attacker donated.

### Making Attacks Expensive

By requiring a larger initial deposit or burning initial shares, we force the attacker to put more capital at risk, making the attack economically unfeasible for most scenarios.

## Mitigation Strategies

### 1. Virtual Shares and Assets (OpenZeppelin Approach)

Add a virtual offset to share calculations:

```solidity
function _convertToShares(uint256 assets, Math.Rounding rounding)
    internal
    view
    returns (uint256)
{
    return assets.mulDiv(
        totalSupply() + 10 ** _decimalsOffset(),
        totalAssets() + 1,
        rounding
    );
}
```

**How it works:**
- Adds virtual shares (10^offset) and 1 virtual asset to calculations
- Makes initial inflation much more expensive
- For offset=3, attacker needs 1000x more capital

**Advantages:**
- Elegant mathematical solution
- No storage overhead
- Compatible with existing contracts

**Trade-offs:**
- Slightly reduces share precision
- Requires careful offset selection

### 2. Minimum Deposit Requirement

Require substantial first deposit:

```solidity
if (totalSupply() == 0) {
    require(assets >= MIN_FIRST_DEPOSIT, "First deposit too small");
}
```

**How it works:**
- Forces first depositor to commit significant capital
- Makes the attack require large upfront investment
- Simple to implement and understand

**Advantages:**
- Easy to implement
- Clear security guarantee

**Trade-offs:**
- Creates friction for first user
- Requires governance to set appropriate minimum
- May need to vary by asset price

### 3. Dead Shares Pattern

Burn initial shares permanently:

```solidity
if (totalSupply() == 0) {
    shares = assets - BURN_AMOUNT;
    _mint(DEAD_ADDRESS, BURN_AMOUNT);
    _mint(receiver, shares);
} else {
    shares = _convertToShares(assets);
    _mint(receiver, shares);
}
```

**How it works:**
- First deposit mints some shares to dead address
- These shares are never redeemable
- Inflates totalSupply without being controlled by attacker

**Advantages:**
- Permanent protection
- No ongoing gas cost
- Works with any asset

**Trade-offs:**
- Small loss for first depositor
- Need to choose appropriate burn amount
- Slightly more complex initialization

### 4. Decimals Offset (Combined with Virtual Shares)

Use higher precision for shares than assets:

```solidity
function decimals() public view override returns (uint8) {
    return _asset.decimals() + _decimalsOffset;
}
```

**How it works:**
- Shares have more decimals than underlying asset
- Creates automatic offset in calculations
- Reduces rounding errors

**Advantages:**
- Elegant solution
- Improves precision for all operations

**Trade-offs:**
- May confuse users expecting 1:1 decimals
- Requires frontend awareness

## Real-World Examples

### Incidents

1. **Rari Capital Fuse Pools (2022)**
   - Some pools were vulnerable to inflation attacks
   - No major exploitation reported
   - Led to industry awareness

2. **Various ERC-4626 Implementations**
   - Many early implementations were vulnerable
   - Security audits increasingly check for this
   - Now considered critical issue

### Industry Response

- **OpenZeppelin**: Added virtual shares/assets to ERC-4626 implementation
- **Solmate**: Documented the issue, left mitigation to developers
- **EIP-4626**: Security considerations section added
- **Audit Checklist**: Standard item in vault audits

## Best Practices

### For Vault Developers

1. **Always Mitigate**: Don't launch unprotected vaults
2. **Use Proven Libraries**: OpenZeppelin ERC-4626 includes protections
3. **Consider Context**: Choose mitigation based on your use case
4. **Test Thoroughly**: Include inflation attack tests
5. **Audit**: Have security experts review vault logic

### Choosing a Mitigation

- **High-value vaults**: Use virtual shares/assets + decimals offset
- **Simple vaults**: Minimum deposit requirement may suffice
- **Maximum security**: Combine multiple strategies
- **Public vaults**: Dead shares pattern prevents privileged first depositor

### Testing Strategy

Always test:
1. Attack scenario with minimal deposit + donation
2. Share calculation edge cases
3. First depositor experience
4. Gas costs of mitigation
5. Interaction with other vault features

## Implementation Guide

### Using OpenZeppelin (Recommended)

```solidity
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract SafeVault is ERC4626 {
    constructor(IERC20 asset)
        ERC4626(asset)
        ERC20("Safe Vault", "sVAULT")
    {
        // OpenZeppelin ERC4626 includes virtual shares protection
    }

    function _decimalsOffset() internal pure override returns (uint8) {
        return 3; // Add offset for extra protection
    }
}
```

### Custom Implementation with Dead Shares

```solidity
contract CustomVault is ERC4626 {
    uint256 private constant DEAD_SHARES = 1000;
    address private constant DEAD_ADDRESS = address(0xdead);

    function deposit(uint256 assets, address receiver)
        public
        override
        returns (uint256)
    {
        uint256 shares;

        if (totalSupply() == 0) {
            shares = assets;
            _mint(DEAD_ADDRESS, DEAD_SHARES);
            _mint(receiver, shares - DEAD_SHARES);
        } else {
            shares = convertToShares(assets);
            _mint(receiver, shares);
        }

        SafeERC20.safeTransferFrom(asset, msg.sender, address(this), assets);

        emit Deposit(msg.sender, receiver, assets, shares);
        return shares;
    }
}
```

## Learning Objectives

After completing this project, you should understand:

1. How share-based vaults work
2. The mathematics behind the inflation attack
3. Why integer division creates vulnerabilities
4. Economic considerations of the attack
5. Multiple mitigation strategies and their trade-offs
6. How to implement secure ERC-4626 vaults
7. Testing approaches for vault security

## Project Structure

```
44-inflation-attack/
├── README.md                          # This file
├── src/
│   ├── Project44.sol                  # Skeleton with TODOs
│   └── solution/
│       └── Project44Solution.sol      # Complete solution
├── test/
│   └── Project44.t.sol                # Comprehensive tests
└── script/
    └── DeployProject44.s.sol          # Deployment script
```

## Getting Started

1. **Study the skeleton**: Review `src/Project44.sol` and read all comments
2. **Attempt implementation**: Try to implement the vulnerable vault and attacker
3. **Run tests**: `forge test --match-contract Project44Test -vvv`
4. **Compare with solution**: Check `src/solution/InflationAttackSolution.sol`

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/InflationAttackSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployInflationAttackSolution.s.sol` - Deployment script patterns
- `test/solution/InflationAttackSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains precision attacks, first-deposit exploits, rounding manipulation
- **Connections to Project 11**: ERC-4626 vaults (this shows the attack)
- **Connections to Project 20**: Share-based accounting (precision is critical)
- **Connections to Project 42**: Correct rounding prevents these attacks
- **Real-World Context**: First-deposit attacks can drain vaults - virtual shares/assets prevent this

5. **Experiment**: Try different mitigation strategies

## Tasks

### Part 1: Understanding the Attack
- [ ] Implement vulnerable vault
- [ ] Create attacker contract
- [ ] Execute successful attack
- [ ] Calculate profit vs cost

### Part 2: Implementing Mitigations
- [ ] Add virtual shares/assets
- [ ] Implement minimum deposit
- [ ] Create dead shares pattern
- [ ] Test each mitigation

### Part 3: Analysis
- [ ] Compare gas costs
- [ ] Analyze attack economics
- [ ] Test edge cases
- [ ] Document trade-offs

## Additional Resources

- [EIP-4626: Tokenized Vault Standard](https://eips.ethereum.org/EIPS/eip-4626)
- [OpenZeppelin ERC-4626 Documentation](https://docs.openzeppelin.com/contracts/4.x/erc4626)
- [Inflation Attack Analysis by MixBytes](https://mixbytes.io/blog/overview-of-the-inflation-attack)
- [OpenZeppelin Security Advisory](https://blog.openzeppelin.com/a-novel-defense-against-erc4626-inflation-attacks)

## Security Warning

This project is for educational purposes only. The vulnerable implementations should never be used in production. Always:

- Use audited libraries (OpenZeppelin)
- Include proper mitigations
- Conduct security audits
- Test extensively
- Consider economic incentives

## License

MIT License - Educational purposes only

---


## 45-multi-asset-vault

# Project 45: Multi-Asset Vault

A sophisticated vault system that holds multiple underlying assets with weighted allocations, dynamic rebalancing, and oracle-based NAV calculations. This project demonstrates index fund patterns and basket management strategies.

## Concepts Covered

### 1. Multi-Asset Vault Design

A multi-asset vault holds a basket of different ERC20 tokens, representing diversified exposure similar to an index fund or ETF.

**Key Components:**
```solidity
struct Asset {
    address token;          // ERC20 token address
    uint256 targetWeight;   // Target allocation (basis points, 10000 = 100%)
    address priceOracle;    // Chainlink-style oracle for pricing
}

// Vault holds multiple assets
Asset[] public assets;
mapping(address => uint256) public assetIndex;
```

**Design Principles:**
- Vault shares represent proportional ownership of the entire basket
- Users deposit/withdraw in a base asset (e.g., USDC)
- Vault internally manages multiple positions
- Shares are minted/burned based on NAV

### 2. Weighted NAV Calculation: Portfolio Valuation

**FIRST PRINCIPLES: Net Asset Value**

Net Asset Value (NAV) represents the total value of all vault holdings. This is fundamental to multi-asset vaults!

**CONNECTION TO PROJECT 11, 18, & 20**:
- **Project 11**: ERC-4626 vaults calculate share prices
- **Project 18**: Oracles provide price data
- **Project 20**: Share-based accounting fundamentals
- **Project 45**: Multi-asset NAV combines all concepts!

**NAV FORMULA**:

```
NAV = Σ (balance_i × price_i) for all assets i

Price Per Share = NAV / Total Shares
```

**UNDERSTANDING THE CALCULATION** (from Project 01 & 18 knowledge):

```
NAV Calculation Flow:
┌─────────────────────────────────────────┐
│ For each asset in vault:                │
│   1. Get balance: balanceOf(vault)     │ ← From Project 08 (ERC20)
│   2. Get price: oracle.getPrice()      │ ← From Project 18 (Oracle)
│   3. Calculate value: balance × price   │ ← Arithmetic
│   4. Sum all values                     │ ← Accumulator pattern
│   ↓                                      │
│ NAV = sum of all asset values           │ ← Total portfolio value
│   ↓                                      │
│ Price per share = NAV / totalShares     │ ← From Project 11!
└─────────────────────────────────────────┘
```

**EXAMPLE CALCULATION**:

```
Multi-Asset Portfolio:
┌─────────────────────────────────────────┐
│ Asset A (ETH):                          │
│   Balance: 100 tokens                   │
│   Price: $2,000 (from oracle)          │
│   Value: 100 × $2,000 = $200,000       │
│                                          │
│ Asset B (USDC):                         │
│   Balance: 500,000 tokens               │
│   Price: $1.00 (stablecoin)             │
│   Value: 500,000 × $1.00 = $500,000    │
│                                          │
│ Asset C (WBTC):                         │
│   Balance: 10 tokens                    │
│   Price: $30,000 (from oracle)         │
│   Value: 10 × $30,000 = $300,000       │
│   ↓                                      │
│ Total NAV = $1,000,000                  │ ← Portfolio value
│                                          │
│ If 1,000,000 shares exist:              │
│   Price Per Share = $1,000,000 / 1,000,000│
│   Price Per Share = $1.00               │ ← Share value
└─────────────────────────────────────────┘
```

**GAS COST BREAKDOWN** (from Project 01, 06, & 18 knowledge):

**NAV Calculation**:
- Oracle calls: ~100 gas × N assets (view functions)
- Balance reads: ~100 gas × N assets (SLOAD from ERC20)
- Arithmetic: ~10 gas × N assets (multiplication)
- Total: ~210 gas × N assets (for N assets)

**Example** (3 assets):
- Oracle calls: ~300 gas
- Balance reads: ~300 gas
- Arithmetic: ~30 gas
- Total: ~630 gas (cheap for portfolio valuation!)

**REAL-WORLD ANALOGY**: 
Like calculating the value of an investment portfolio:
- **Assets** = Different stocks/bonds in portfolio
- **Prices** = Current market prices (from exchanges/oracles)
- **NAV** = Total portfolio value
- **Shares** = Units of ownership in the portfolio
- **Price per share** = NAV / shares (how much each share is worth)

**Weighted Allocation:**
```solidity
function calculateNAV() public view returns (uint256) {
    uint256 totalValue = 0;

    for (uint256 i = 0; i < assets.length; i++) {
        uint256 balance = IERC20(assets[i].token).balanceOf(address(this));
        uint256 price = IPriceOracle(assets[i].priceOracle).getPrice();
        totalValue += (balance * price) / 1e18; // Normalize decimals
    }

    return totalValue;
}
```

### 3. Rebalancing Strategies

Rebalancing maintains target weights as asset prices fluctuate.

**Types of Rebalancing:**

**a) Periodic Rebalancing:**
- Fixed schedule (daily, weekly, monthly)
- Predictable but may miss optimal timing

**b) Threshold-Based Rebalancing:**
```solidity
// Rebalance when allocation drifts beyond threshold
if (abs(currentWeight - targetWeight) > threshold) {
    rebalance();
}
```

**c) Opportunistic Rebalancing:**
- Rebalance during deposits/withdrawals
- Minimizes separate transactions

**Rebalancing Process:**
1. Calculate current allocations
2. Determine required swaps
3. Execute trades via DEX
4. Account for slippage
5. Verify new allocations

### 4. Oracle Integration for Pricing

Accurate pricing is critical for NAV calculations.

**Oracle Interface:**
```solidity
interface IPriceOracle {
    function getPrice() external view returns (uint256);
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
}
```

**Chainlink Integration:**
```solidity
function getAssetPrice(address asset) public view returns (uint256) {
    uint256 idx = assetIndex[asset];
    IPriceOracle oracle = IPriceOracle(assets[idx].priceOracle);

    // Chainlink returns price with 8 decimals typically
    uint256 price = oracle.getPrice();
    uint8 oracleDecimals = oracle.decimals();

    // Normalize to 18 decimals
    return price * 10**(18 - oracleDecimals);
}
```

**Oracle Considerations:**
- Price freshness (check timestamps)
- Circuit breakers for stale data
- Multiple oracle sources for validation
- Fallback pricing mechanisms

### 5. Basket Composition Management

Managing which assets are in the basket and their target weights.

**Adding Assets:**
```solidity
function addAsset(
    address token,
    uint256 targetWeight,
    address oracle
) external onlyOwner {
    require(targetWeight > 0, "Invalid weight");
    require(getTotalWeight() + targetWeight <= 10000, "Exceeds 100%");

    assets.push(Asset({
        token: token,
        targetWeight: targetWeight,
        priceOracle: oracle
    }));
}
```

**Adjusting Weights:**
```solidity
function setTargetWeight(address token, uint256 newWeight) external onlyOwner {
    uint256 idx = assetIndex[token];
    assets[idx].targetWeight = newWeight;

    // Ensure total weights = 100%
    require(getTotalWeight() == 10000, "Weights must sum to 100%");

    emit WeightUpdated(token, newWeight);
}
```

**Basket Constraints:**
- Total weights must equal 100% (10,000 basis points)
- Minimum/maximum position sizes
- Asset eligibility criteria
- Diversification requirements

### 6. Index Fund Patterns

Multi-asset vaults implement index fund strategies.

**Common Index Strategies:**

**a) Market Cap Weighted:**
```solidity
// Weight by market capitalization
weight_i = marketCap_i / Σ(marketCap_j)
```

**b) Equal Weight:**
```solidity
// Equal allocation to all assets
weight_i = 1 / n  // where n = number of assets
```

**c) Risk Parity:**
```solidity
// Weight by inverse volatility
weight_i = (1/volatility_i) / Σ(1/volatility_j)
```

**d) Custom Strategic:**
- Fundamental analysis
- Sector allocations
- Thematic exposure

**Deposit/Withdraw Flow:**
```solidity
// User deposits base asset
function deposit(uint256 amount) external {
    baseAsset.transferFrom(msg.sender, address(this), amount);

    // Calculate shares based on current NAV
    uint256 nav = calculateNAV();
    uint256 shares = (amount * totalShares) / nav;

    // Allocate deposited funds across basket
    allocateToBasket(amount);

    _mint(msg.sender, shares);
}

// User withdraws proportional basket
function withdraw(uint256 shares) external {
    require(balanceOf(msg.sender) >= shares, "Insufficient shares");

    uint256 proportion = (shares * 1e18) / totalSupply();

    // Withdraw proportional amount of each asset
    for (uint256 i = 0; i < assets.length; i++) {
        uint256 assetBalance = IERC20(assets[i].token).balanceOf(address(this));
        uint256 withdrawAmount = (assetBalance * proportion) / 1e18;
        IERC20(assets[i].token).transfer(msg.sender, withdrawAmount);
    }

    _burn(msg.sender, shares);
}
```

### 7. Slippage in Rebalancing

Rebalancing requires trading, which incurs slippage.

**Slippage Sources:**
1. **Price Impact** - Large trades move the market
2. **Fees** - DEX fees reduce effective price
3. **Price Movement** - Market moves during execution
4. **MEV** - Front-running and sandwich attacks

**Slippage Protection:**
```solidity
function rebalanceAsset(
    address fromAsset,
    address toAsset,
    uint256 amountIn,
    uint256 minAmountOut  // Slippage protection
) internal {
    // Calculate expected output
    uint256 expectedOut = getExpectedOutput(fromAsset, toAsset, amountIn);

    // Apply slippage tolerance (e.g., 1%)
    uint256 minAcceptable = (expectedOut * 9900) / 10000;
    require(minAmountOut >= minAcceptable, "Excessive slippage");

    // Execute swap
    uint256 actualOut = executeDEXSwap(fromAsset, toAsset, amountIn, minAmountOut);

    // Track slippage for analytics
    uint256 slippage = expectedOut > actualOut
        ? ((expectedOut - actualOut) * 10000) / expectedOut
        : 0;

    emit Rebalanced(fromAsset, toAsset, amountIn, actualOut, slippage);
}
```

**Minimizing Slippage:**
- Split large trades across multiple blocks
- Use TWAP (Time-Weighted Average Price) execution
- Route through optimal DEX/aggregator
- Consider limit orders instead of market orders
- Rebalance during high liquidity periods

**Slippage Accounting:**
```solidity
// Track cumulative slippage costs
uint256 public cumulativeSlippage;
uint256 public rebalanceCount;

function averageSlippage() public view returns (uint256) {
    return rebalanceCount > 0 ? cumulativeSlippage / rebalanceCount : 0;
}
```

## Architecture

### Contract Structure

```
MultiAssetVault (ERC20 vault shares)
├── Asset Management
│   ├── addAsset()
│   ├── removeAsset()
│   └── setTargetWeight()
├── NAV Calculation
│   ├── calculateNAV()
│   ├── getPricePerShare()
│   └── getAssetValue()
├── User Operations
│   ├── deposit()
│   ├── withdraw()
│   └── previewDeposit/Withdraw()
└── Rebalancing
    ├── rebalance()
    ├── needsRebalancing()
    └── calculateRebalanceAmounts()
```

### State Variables

```solidity
// Asset configuration
Asset[] public assets;
mapping(address => uint256) public assetIndex;

// Rebalancing configuration
uint256 public rebalanceThreshold;  // Basis points
uint256 public lastRebalance;
uint256 public minRebalanceInterval;

// Performance tracking
uint256 public totalDeposited;
uint256 public totalWithdrawn;
uint256 public totalSlippage;
```

## Use Cases

### 1. Crypto Index Fund
Hold top cryptocurrencies weighted by market cap:
- 40% BTC
- 30% ETH
- 20% BNB
- 10% MATIC

### 2. Stablecoin Basket
Diversified stablecoin exposure:
- 25% USDC
- 25% USDT
- 25% DAI
- 25% FRAX

### 3. DeFi Blue Chip
Exposure to leading DeFi protocols:
- 30% UNI
- 25% AAVE
- 25% CRV
- 20% COMP

### 4. Sector Rotation
Dynamic allocation based on market conditions:
- Adjust weights based on momentum
- Shift between growth/value
- Risk-on/risk-off positioning

## Security Considerations

### 1. Oracle Risks
- **Stale Prices**: Verify oracle freshness
- **Oracle Manipulation**: Use multiple sources
- **Circuit Breakers**: Halt on suspicious prices

### 2. Rebalancing Risks
- **Sandwich Attacks**: Use private transactions/flashbots
- **Slippage**: Enforce strict tolerance
- **Failed Swaps**: Handle gracefully without bricking vault

### 3. Asset Risks
- **Token Blacklisting**: Some tokens can freeze addresses
- **Pausable Tokens**: Handle paused transfers
- **Fee-on-Transfer**: Account for transfer fees
- **Rebasing Tokens**: Incompatible with vault accounting

### 4. Access Control
- **Admin Powers**: Time-lock critical operations
- **Multi-sig**: Require multiple approvals for basket changes
- **Emergency Pause**: Circuit breaker for emergencies

### 5. Accounting Precision
- **Decimal Normalization**: Handle different token decimals
- **Rounding Errors**: Prevent dust accumulation
- **NAV Manipulation**: Prevent first depositor attack

## Gas Optimization

### 1. Batch Operations
```solidity
// Rebalance multiple assets in one transaction
function rebalanceMultiple(RebalanceOrder[] calldata orders) external {
    for (uint256 i = 0; i < orders.length; i++) {
        executeRebalance(orders[i]);
    }
}
```

### 2. Lazy NAV Updates
```solidity
// Only calculate NAV when needed
uint256 private cachedNAV;
uint256 private navTimestamp;

function getNAV() public returns (uint256) {
    if (block.timestamp > navTimestamp + NAV_CACHE_DURATION) {
        cachedNAV = calculateNAV();
        navTimestamp = block.timestamp;
    }
    return cachedNAV;
}
```

### 3. Packed Storage
```solidity
// Pack weights into single storage slot
struct PackedAsset {
    address token;           // 20 bytes
    uint64 targetWeight;     // 8 bytes (sufficient for basis points)
    uint32 lastRebalance;    // 4 bytes (timestamp)
}
```

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/MultiAssetVaultSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployMultiAssetVaultSolution.s.sol` - Deployment script patterns
- `test/solution/MultiAssetVaultSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains portfolio valuation, weighted NAV calculations, rebalancing algorithms
- **Connections to Project 11**: ERC-4626 vault standard (this extends it to multiple assets)
- **Connections to Project 18**: Oracle integration for multi-asset pricing
- **Connections to Project 20**: Share-based accounting for basket ownership
- **Real-World Context**: Index fund/ETF pattern - diversified exposure in single vault

## Testing Checklist

- [ ] NAV calculation with multiple assets
- [ ] NAV accuracy with different decimals
- [ ] Deposit mints correct shares based on NAV
- [ ] Withdraw burns shares and returns correct amounts
- [ ] Rebalancing brings weights within threshold
- [ ] Slippage protection prevents excessive losses
- [ ] Oracle price changes update NAV correctly
- [ ] Adding/removing assets updates basket
- [ ] Weight adjustments maintain 100% total
- [ ] First depositor attack prevention
- [ ] Handling failed rebalancing swaps
- [ ] Emergency pause functionality
- [ ] Multi-asset deposit optimization
- [ ] Proportional withdrawal accuracy
- [ ] Performance fee calculation

## Additional Resources

- [Chainlink Price Feeds](https://docs.chain.link/data-feeds/price-feeds)
- [ERC4626 Tokenized Vault Standard](https://eips.ethereum.org/EIPS/eip-4626)
- [Uniswap V3 Swaps](https://docs.uniswap.org/contracts/v3/guides/swaps/single-swaps)
- [Index Fund Strategies](https://www.investopedia.com/terms/i/indexfund.asp)
- [Modern Portfolio Theory](https://www.investopedia.com/terms/m/modernportfoliotheory.asp)

## Next Steps

After completing this project, explore:
- **Leveraged Vaults**: Borrow against collateral for amplified returns
- **Options Vaults**: Generate yield through covered calls
- **Cross-Chain Vaults**: Hold assets across multiple chains
- **Algorithmic Rebalancing**: ML-based dynamic allocation
- **Governance Integration**: Let token holders vote on basket composition

---


## 46-vault-insolvency

# Project 46: Vault Insolvency Scenarios

A comprehensive guide to handling vault insolvency, bad debt, and emergency scenarios in DeFi protocols.

## Overview

This project teaches how to build resilient vault systems that can handle catastrophic scenarios including strategy losses, bad debt, and emergency situations. Learn to implement proper crisis management and loss socialization mechanisms.

## Concepts

### What is Vault Insolvency? When Assets < Liabilities

**FIRST PRINCIPLES: Solvency and Accounting**

Vault insolvency occurs when the total assets held by a vault are less than the total claims (shares) against it. This means users cannot fully redeem their shares for the underlying assets they deposited.

**CONNECTION TO PROJECT 11, 20, & 42**:
- **Project 11**: ERC-4626 vault standard
- **Project 20**: Share-based accounting
- **Project 42**: Rounding precision (affects solvency!)
- **Project 46**: What happens when vault becomes insolvent!

**UNDERSTANDING SOLVENCY**:

```
Solvency Check:
┌─────────────────────────────────────────┐
│ Vault State:                            │
│   totalAssets = 1,000 tokens            │ ← What vault has
│   totalShares = 1,000 shares            │ ← What users own
│   ↓                                      │
│ Expected Value:                         │
│   expectedValue = totalShares × pricePerShare│
│   expectedValue = 1,000 × 1.0 = 1,000  │ ← What users expect
│   ↓                                      │
│ Solvency Check:                         │
│   totalAssets >= expectedValue?          │
│   1,000 >= 1,000? ✅ SOLVENT            │ ← Can honor withdrawals
│                                          │
│ After Loss:                             │
│   totalAssets = 800 tokens (loss!)      │ ← Strategy lost funds
│   totalShares = 1,000 shares            │ ← Unchanged
│   ↓                                      │
│ Solvency Check:                         │
│   800 >= 1,000? ❌ INSOLVENT           │ ← Cannot honor withdrawals!
└─────────────────────────────────────────┘
```

**CAUSES OF INSOLVENCY**:

1. **Strategy Losses**: Underlying strategy loses funds
   - Exploit in yield protocol (from Project 34: oracle manipulation)
   - Liquidation with slippage
   - Impermanent loss beyond tolerable levels
   - Smart contract bugs (from Project 07: reentrancy, etc.)

2. **Oracle Manipulation or Failure** (from Project 18 & 34):
   - Flash loan price manipulation
   - Oracle outage or stale data
   - Cross-chain bridge failures

3. **Smart Contract Exploits**: In underlying protocols
   - Reentrancy attacks (from Project 07)
   - Access control bugs (from Project 36)
   - Precision errors (from Project 42)

4. **Cascading Liquidations**:
   - One liquidation triggers others
   - Slippage accumulates
   - Vault loses more than expected

5. **Flash Loan Attacks** (from Project 33):
   - Price manipulation
   - Governance attacks
   - Oracle manipulation

6. **Protocol-Level Failures**:
   - Entire protocol exploited
   - Bridge hacks
   - Centralized failure points

**REAL-WORLD ANALOGY**: 
Like a bank run:
- **Solvent**: Bank has enough cash to honor all withdrawals
- **Insolvent**: Bank doesn't have enough cash (assets < liabilities)
- **Vault**: Shares represent claims, assets must cover claims
- **Problem**: When assets < shares × price, vault is insolvent!

### Bad Debt Scenarios

**Types of Bad Debt:**

1. **Strategy Loss**: Underlying strategy loses funds
   - Exploit in yield protocol
   - Liquidation with slippage
   - Impermanent loss beyond tolerable levels
   - Smart contract bugs

2. **Oracle Failures**: Mispricing leads to incorrect valuations
   - Flash loan price manipulation
   - Oracle outage or stale data
   - Cross-chain bridge failures

3. **Withdrawal Runs**: Bank-run scenarios
   - First withdrawers get full value
   - Later withdrawers face losses
   - Liquidity crunch

### Strategy Loss Handling

**Detection:**
```solidity
// Check if total assets < expected value
uint256 totalAssets = strategy.totalAssets();
uint256 expectedValue = totalShares * pricePerShare;
bool isInsolvent = totalAssets < expectedValue;
```

**Response Mechanisms:**
1. **Immediate Shutdown**: Stop all deposits
2. **Loss Calculation**: Determine actual vs expected
3. **Loss Distribution**: Share loss among users
4. **Recovery Attempts**: Try to recover funds

### Emergency Withdrawal Modes

**Standard Mode**: Full redemptions available
```solidity
withdraw(shares) → assets = shares * pricePerShare
```

**Emergency Mode**: Proportional withdrawals only
```solidity
withdraw(shares) → assets = shares * (totalAssets / totalShares)
```

**Modes:**

1. **Normal**: Full operations
2. **Paused**: Deposits paused, withdrawals work
3. **Emergency**: Only proportional withdrawals
4. **Frozen**: All operations stopped (worst case)

### Partial Withdrawal Logic

When a vault can't honor full withdrawals, implement proportional logic:

```solidity
// Instead of: shares * expectedPrice
// Use: shares * (actualAssets / totalShares)

uint256 userShare = userShares * totalAssets / totalSupply;
```

**Considerations:**
- Gas costs for small withdrawals
- Dust amounts
- Rounding errors favoring the vault
- Minimum withdrawal amounts

### Socialized Losses

When losses occur, distribute them fairly among all users:

**Approaches:**

1. **Pro-Rata Distribution**
   - Everyone loses same percentage
   - Most common and fair
   - Easy to calculate

2. **FIFO Protection**
   - First depositors protected
   - Later depositors take losses
   - Can cause runs

3. **Time-Weighted**
   - Longer holders get better treatment
   - Rewards loyalty
   - More complex

**Implementation:**
```solidity
// Pro-rata: Reduce price per share
pricePerShare = totalAssets / totalShares;

// Everyone's effective balance reduced proportionally
userAssets = userShares * pricePerShare;
```

### Circuit Breakers

Automatic safety mechanisms that trigger during anomalies:

**Triggers:**
1. **Large Loss**: Single tx loss > threshold
2. **Rapid Drawdown**: Loss rate too fast
3. **Withdrawal Surge**: Too many withdrawals
4. **Price Deviation**: Asset price moves too much

**Actions:**
1. **Pause Deposits**: Stop new money
2. **Pause Withdrawals**: Stop bank run
3. **Notify Admin**: Alert for manual intervention
4. **Auto-Recovery**: Try to harvest/recover

**Example:**
```solidity
if (lossPercentage > MAX_LOSS_THRESHOLD) {
    emergencyMode = true;
    pauseDeposits();
    notifyAdmin();
}
```

## Key Features to Implement

### 1. Loss Detection System
- Monitor strategy health
- Compare expected vs actual assets
- Track price per share deviations

### 2. Emergency Shutdown
- Multi-signature control
- Timelocks for safety
- Graceful degradation

### 3. Proportional Withdrawals
- Fair distribution of remaining assets
- Prevent first-mover advantage
- Handle rounding carefully

### 4. Recovery Mechanisms
- Attempt to recover funds
- Coordinate with affected protocols
- Potential liquidation of strategy positions

### 5. Loss Socialization
- Calculate per-share loss
- Update share price
- Track individual losses for reporting

## Implementation Steps

### Step 1: Basic Vault Structure
```solidity
contract InsolvencyVault {
    IERC20 public asset;
    uint256 public totalShares;
    mapping(address => uint256) public shares;

    enum Mode { NORMAL, PAUSED, EMERGENCY, FROZEN }
    Mode public currentMode;
}
```

### Step 2: Deposit/Withdraw Logic
```solidity
function deposit(uint256 assets) external returns (uint256 shares) {
    require(currentMode == Mode.NORMAL, "Deposits paused");
    shares = convertToShares(assets);
    // ... mint shares
}

function withdraw(uint256 shares) external returns (uint256 assets) {
    require(currentMode != Mode.FROZEN, "Frozen");

    if (currentMode == Mode.EMERGENCY) {
        assets = proportionalWithdraw(shares);
    } else {
        assets = normalWithdraw(shares);
    }
}
```

### Step 3: Loss Detection
```solidity
function checkSolvency() public returns (bool) {
    uint256 totalAssets = getTotalAssets();
    uint256 expectedValue = totalShares * lastKnownPrice;

    if (totalAssets < expectedValue * 90 / 100) {
        triggerEmergency();
        return false;
    }
    return true;
}
```

### Step 4: Emergency Mode
```solidity
function triggerEmergency() internal {
    currentMode = Mode.EMERGENCY;
    emit EmergencyTriggered(block.timestamp, getTotalAssets());
}

function proportionalWithdraw(uint256 shares) internal returns (uint256) {
    uint256 totalAssets = getTotalAssets();
    return shares * totalAssets / totalShares;
}
```

### Step 5: Recovery
```solidity
function attemptRecovery() external onlyAdmin {
    // Try to withdraw from strategy
    // Liquidate positions
    // Update accounting

    if (isSolvent()) {
        currentMode = Mode.NORMAL;
    }
}
```

## Security Considerations

### 1. Reentrancy
- Use ReentrancyGuard on all withdraw functions
- Update state before external calls
- Consider cross-contract reentrancy

### 2. Oracle Dependence
- Use multiple oracle sources
- Implement circuit breakers for price deviations
- Have fallback pricing mechanisms

### 3. Access Control
- Multi-sig for emergency functions
- Timelocks for critical operations
- Role-based access (owner, guardian, keeper)

### 4. Withdrawal Runs
- Consider withdrawal limits
- Queue-based withdrawals during stress
- Cooldown periods

### 5. Rounding Errors
- Always round in favor of the vault
- Track dust carefully
- Minimum deposit/withdrawal amounts

## Testing Scenarios

### 1. Normal Operations
- Deposits and withdrawals work correctly
- Share price calculations accurate
- No losses

### 2. Strategy Loss (10% loss)
- Detect loss
- Emergency mode triggers
- Proportional withdrawals work
- Loss socialized correctly

### 3. Catastrophic Loss (50%+ loss)
- Immediate freeze
- All users get proportional amount
- No user gets unfair advantage

### 4. Recovery
- Admin can recover funds
- Mode can be downgraded
- Normal operations resume

### 5. Edge Cases
- First depositor scenario
- Last withdrawer scenario
- Multiple sequential losses
- Dust handling

## Common Pitfalls

1. **Not checking for insolvency**: Always verify vault health
2. **First-mover advantage**: Early withdrawers shouldn't be able to drain vault
3. **Integer overflow**: Large numbers in loss calculations
4. **No emergency shutdown**: Must have kill switch
5. **Centralization risks**: Admin has too much power
6. **No loss reporting**: Users should know their losses
7. **Improper rounding**: Can lead to exploitation

## Best Practices

1. **Multi-layered Security**
   - Circuit breakers
   - Gradual mode degradation
   - Multiple admin roles

2. **Transparent Loss Handling**
   - Events for all state changes
   - Clear loss attribution
   - User-facing loss queries

3. **Conservative Accounting**
   - Round in vault's favor
   - Maintain reserves
   - Limit strategy exposure

4. **Emergency Preparedness**
   - Documented procedures
   - Tested recovery mechanisms
   - Communication channels

5. **Fair Loss Distribution**
   - Pro-rata basis
   - No favoritism
   - Deterministic calculations

## Real-World Examples

### Yearn Finance
- Multi-strategy vaults
- Emergency shutdown mechanism
- Governance-controlled recovery

### Rari Capital (Post-Exploit)
- Suffered exploit losses
- Had to socialize losses
- Implemented better controls

### Cream Finance
- Multiple exploits
- Insolvency issues
- Lessons in risk management

## Learning Objectives

After completing this project, you will understand:

1. How vault insolvency occurs
2. Mechanisms to detect and handle bad debt
3. Emergency shutdown procedures
4. Fair loss distribution mechanisms
5. Recovery and crisis management
6. Circuit breaker implementation
7. Building resilient DeFi protocols

## Exercises

### Beginner
1. Implement basic vault with deposit/withdraw
2. Add simple insolvency check
3. Implement emergency pause

### Intermediate
4. Add proportional withdrawal logic
5. Implement circuit breakers
6. Create multi-mode state machine

### Advanced
7. Handle multiple concurrent losses
8. Implement time-weighted loss distribution
9. Create comprehensive recovery mechanisms
10. Add cross-strategy risk management

## Additional Resources

- [EIP-4626: Tokenized Vault Standard](https://eips.ethereum.org/EIPS/eip-4626)
- [Yearn Vault Documentation](https://docs.yearn.finance/)
- [DeFi Risk Assessment](https://github.com/defi-defense-dao)
- [Trail of Bits: Building Secure Contracts](https://github.com/crytic/building-secure-contracts)

## File Structure

```
46-vault-insolvency/
├── README.md (this file)
├── src/
│   ├── Project46.sol (skeleton code with TODOs)
│   └── solution/
│       └── Project46Solution.sol (complete solution)
├── test/
│   └── Project46.t.sol (comprehensive tests)
└── script/
    └── DeployProject46.s.sol (deployment script)
```

## Getting Started

1. Review the concepts above
2. Examine the skeleton code in `src/Project46.sol`
3. Try to implement the TODOs yourself
4. Run tests: `forge test --match-contract Project46Test -vvv`
5. Compare with solution in `src/solution/VaultInsolvencySolution.sol`

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/VaultInsolvencySolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployVaultInsolvencySolution.s.sol` - Deployment script patterns
- `test/solution/VaultInsolvencySolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains insolvency handling, proportional withdrawals, loss distribution
- **Connections to Project 11**: ERC-4626 vaults (insolvency is a critical edge case)
- **Connections to Project 20**: Share-based accounting (how losses affect shares)
- **Real-World Context**: Strategy losses can cause insolvency - must handle gracefully

6. Deploy locally: `forge script script/DeployProject46.s.sol`

Good luck, and remember: handling insolvency is about protecting users during the worst-case scenarios!

---


## 47-vault-oracle

# Project 47: Vault Oracle Integration

A comprehensive guide to implementing secure oracle integration for vaults, focusing on price feeds, TWAP mechanisms, and oracle failure handling.

## Overview

This project teaches how to safely integrate price oracles into vault systems. Oracles are critical for determining asset values, but they introduce significant security risks if not implemented correctly. Learn how to protect against stale data, price manipulation, and oracle failures.

## Concepts

### Oracle Integration for Vaults: Secure Price Feeds

**FIRST PRINCIPLES: Trust in External Data**

Vaults need accurate price data to calculate values and prevent manipulation. Understanding oracle security is critical!

**CONNECTION TO PROJECT 11, 18, & 34**:
- **Project 11**: ERC-4626 vaults need price data
- **Project 18**: Chainlink oracle integration
- **Project 34**: Oracle manipulation attacks
- **Project 47**: Secure oracle integration for vaults!

Vaults need accurate price data to:
- Calculate total value locked (TVL)
- Determine share prices (from Project 11: `convertToAssets()`)
- Enforce price-based limits
- Trigger rebalancing (from Project 45: multi-asset vaults)
- Prevent sandwich attacks (from Project 33: MEV protection)

**KEY CHALLENGES**:

**VULNERABLE PATTERN**:
```solidity
// ❌ BAD: Direct oracle usage without validation
function getShareValue() external view returns (uint256) {
    uint256 price = oracle.getPrice();  // ❌ No staleness check!
    return (totalAssets() * price) / totalSupply();  // From Project 11!
}
```

**PROBLEMS**:
- Stale data: Oracle might not have updated recently
- Manipulation: Flash loan attacks can manipulate price (from Project 34)
- Failure: Oracle might be down or returning bad data

**SECURE PATTERN**:
```solidity
// ✅ GOOD: Validated oracle usage
function getShareValue() external view returns (uint256) {
    (uint256 price, bool isValid) = _getValidatedPrice();  // ✅ Validation!
    require(isValid, "Invalid oracle price");  // ✅ Revert if invalid
    return (totalAssets() * price) / totalSupply();
}

function _getValidatedPrice() internal view returns (uint256, bool) {
    (uint256 price, uint256 updatedAt) = oracle.getPrice();
    
    // ✅ Check staleness (from Project 18 knowledge)
    if (block.timestamp - updatedAt > MAX_STALENESS) {
        return (0, false);  // Stale data!
    }
    
    // ✅ Check price bounds (prevent manipulation)
    if (price < MIN_PRICE || price > MAX_PRICE) {
        return (0, false);  // Suspicious price!
    }
    
    return (price, true);
}
```

**GAS COST** (from Project 01 & 18 knowledge):
- Oracle call: ~100 gas (view function)
- Staleness check: ~10 gas (arithmetic)
- Bounds check: ~20 gas (comparisons)
- Total: ~130 gas (cheap security check!)

### TWAP (Time-Weighted Average Price)

TWAP protects against short-term price manipulation:

**How TWAP Works:**
```solidity
// Store cumulative price over time
struct Observation {
    uint256 timestamp;
    uint256 cumulativePrice;
}

// Calculate TWAP over period
function getTWAP(uint256 period) public view returns (uint256) {
    Observation memory current = observations[observationIndex];
    Observation memory old = _getObservationAt(block.timestamp - period);

    uint256 priceDelta = current.cumulativePrice - old.cumulativePrice;
    uint256 timeDelta = current.timestamp - old.timestamp;

    return priceDelta / timeDelta;
}
```

**Benefits:**
- Smooths out price volatility
- Makes manipulation expensive (must maintain price over time)
- Provides more stable vault valuations

### Stale Data Handling

Oracles can fail or stop updating. Always check freshness:

```solidity
// Chainlink example
function _isStale(uint256 updatedAt) internal view returns (bool) {
    // Data older than MAX_STALENESS is rejected
    return block.timestamp - updatedAt > MAX_STALENESS;
}

function _getChainlinkPrice() internal view returns (uint256, bool) {
    (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) = priceFeed.latestRoundData();

    // Check for stale data
    if (_isStale(updatedAt)) return (0, false);

    // Check for incomplete round
    if (answeredInRound < roundId) return (0, false);

    // Check for invalid price
    if (answer <= 0) return (0, false);

    return (uint256(answer), true);
}
```

**Staleness Thresholds:**
- High-frequency assets (ETH, BTC): 1 hour
- Stable assets (USDC): 24 hours
- Exotic assets: Custom based on liquidity

### Price Deviation Limits

Protect against oracle errors by limiting price changes:

```solidity
uint256 public constant MAX_PRICE_DEVIATION = 1000; // 10%

function _isReasonablePrice(uint256 newPrice, uint256 oldPrice)
    internal
    pure
    returns (bool)
{
    if (oldPrice == 0) return true; // First price

    uint256 deviation;
    if (newPrice > oldPrice) {
        deviation = ((newPrice - oldPrice) * 10000) / oldPrice;
    } else {
        deviation = ((oldPrice - newPrice) * 10000) / oldPrice;
    }

    return deviation <= MAX_PRICE_DEVIATION;
}
```

**Why This Matters:**
- Oracle bugs can report incorrect prices
- Flash crashes might not represent true value
- Protects users from unfair liquidations/swaps

### Multi-Oracle Strategies

Using multiple oracles increases security:

**1. Primary + Fallback:**
```solidity
function getPrice() public view returns (uint256) {
    (uint256 price, bool valid) = _getPrimaryOraclePrice();
    if (valid) return price;

    (price, valid) = _getFallbackOraclePrice();
    require(valid, "All oracles failed");
    return price;
}
```

**2. Median of Multiple Oracles:**
```solidity
function getMedianPrice() public view returns (uint256) {
    uint256[] memory prices = new uint256[](3);
    prices[0] = oracle1.getPrice();
    prices[1] = oracle2.getPrice();
    prices[2] = oracle3.getPrice();

    // Sort and return median
    _sort(prices);
    return prices[1];
}
```

**3. Deviation Check:**
```solidity
function getConsensusPrice() public view returns (uint256, bool) {
    uint256 price1 = oracle1.getPrice();
    uint256 price2 = oracle2.getPrice();

    uint256 deviation = _calculateDeviation(price1, price2);
    if (deviation > MAX_ORACLE_DEVIATION) {
        return (0, false); // Oracles disagree too much
    }

    return ((price1 + price2) / 2, true);
}
```

### Chainlink Integration

Chainlink is the most widely used oracle network:

**Basic Integration:**
```solidity
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ChainlinkVault {
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function getLatestPrice() public view returns (uint256) {
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        require(answer > 0, "Invalid price");
        require(updatedAt > 0, "Round not complete");
        require(answeredInRound >= roundId, "Stale price");

        return uint256(answer);
    }
}
```

**Decimal Handling:**
```solidity
// Chainlink prices have varying decimals (usually 8 for USD pairs)
function _normalizePrice(int256 price) internal view returns (uint256) {
    uint8 decimals = priceFeed.decimals();

    // Normalize to 18 decimals
    if (decimals < 18) {
        return uint256(price) * 10 ** (18 - decimals);
    } else if (decimals > 18) {
        return uint256(price) / 10 ** (decimals - 18);
    }
    return uint256(price);
}
```

### Oracle Failure Modes

Understanding how oracles fail is critical:

**1. Stale Data:**
- Oracle stops updating
- Network congestion delays updates
- **Mitigation:** Check `updatedAt` timestamp

**2. Invalid Data:**
- Price is 0 or negative
- Price is unrealistically high/low
- **Mitigation:** Sanity checks and bounds

**3. Flash Crashes:**
- Temporary extreme price movements
- **Mitigation:** TWAP, price deviation limits

**4. Oracle Compromise:**
- Malicious oracle operators
- Smart contract bugs in oracle
- **Mitigation:** Multi-oracle setup, circuit breakers

**5. Network Issues:**
- L2 sequencer downtime
- Cross-chain bridge failures
- **Mitigation:** Sequencer uptime feeds, grace periods

**Circuit Breaker Pattern:**
```solidity
bool public oracleEmergencyShutdown;
uint256 public lastValidPrice;
uint256 public lastValidTimestamp;

function getPrice() public view returns (uint256) {
    if (oracleEmergencyShutdown) {
        // Use last known good price in emergency
        require(
            block.timestamp - lastValidTimestamp < EMERGENCY_PERIOD,
            "Emergency period expired"
        );
        return lastValidPrice;
    }

    (uint256 price, bool valid) = _getOraclePrice();
    if (!valid) {
        // Could trigger emergency shutdown
        return lastValidPrice;
    }

    return price;
}
```

## Project Structure

```
47-vault-oracle/
├── README.md
├── src/
│   ├── Project47.sol           # Skeleton implementation
│   └── solution/
│       └── Project47Solution.sol   # Complete solution
├── test/
│   └── Project47.t.sol         # Comprehensive tests
└── script/
    └── DeployProject47.s.sol   # Deployment script
```

## Objectives

1. **Implement Oracle-Integrated Vault** ✓
   - Store deposits with oracle-based valuation
   - Calculate share prices using oracle data
   - Handle multiple assets

2. **Build TWAP Oracle** ✓
   - Store price observations
   - Calculate time-weighted averages
   - Handle edge cases (first observation, etc.)

3. **Add Safety Mechanisms** ✓
   - Staleness checks
   - Price deviation limits
   - Circuit breakers
   - Multi-oracle fallback

4. **Integrate Chainlink** ✓
   - Use AggregatorV3Interface
   - Handle decimals correctly
   - Validate round data

5. **Test Oracle Scenarios** ✓
   - Normal operation
   - Stale data rejection
   - Price manipulation attempts
   - Oracle failure modes

## Key Contracts

### Project47.sol (Skeleton)

Basic structure with TODOs for implementing:
- Oracle price validation
- TWAP calculations
- Safety checks
- Vault operations using oracle data

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/VaultOracleSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployVaultOracleSolution.s.sol` - Deployment script patterns
- `test/solution/VaultOracleSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains TWAP (Time-Weighted Average Price), circular buffers, multi-oracle consensus
- **Connections to Project 18**: Chainlink oracle integration (this extends it)
- **Connections to Project 11**: ERC-4626 vaults with oracle-based pricing
- **Real-World Context**: TWAP prevents oracle manipulation - used in production DeFi protocols

### Project47Solution.sol (Complete)

Full implementation featuring:
- Multi-oracle vault system
- TWAP oracle with circular buffer
- Chainlink integration
- Circuit breaker mechanisms
- Comprehensive validation
- Detailed security comments

## Testing Scenarios

1. **Oracle Updates:**
   - Price updates accumulate correctly
   - TWAP calculations are accurate
   - Observations stored properly

2. **Staleness Detection:**
   - Reject old data
   - Fallback to secondary oracle
   - Emergency mode activation

3. **Price Validation:**
   - Deviation limits enforced
   - Invalid prices rejected
   - Circuit breaker triggers

4. **Vault Operations:**
   - Deposits value correctly
   - Withdrawals use safe prices
   - Share calculations accurate

5. **Failure Recovery:**
   - Graceful degradation
   - Emergency withdrawals
   - Oracle recovery

## Security Considerations

### Critical Checks

1. **Always Validate Oracle Data:**
   ```solidity
   require(updatedAt > block.timestamp - MAX_STALENESS, "Stale");
   require(answer > 0, "Invalid price");
   require(answeredInRound >= roundId, "Incomplete");
   ```

2. **Use TWAP for Critical Operations:**
   - Liquidations
   - Large swaps
   - Vault valuations

3. **Implement Circuit Breakers:**
   - Pause on oracle failure
   - Admin recovery mechanisms
   - User protection during anomalies

4. **Never Trust Single Oracle:**
   - Use multiple sources when possible
   - Compare prices for consistency
   - Have fallback mechanisms

5. **Handle Decimal Conversions:**
   - Different oracles use different decimals
   - Always normalize to consistent format
   - Test edge cases (very large/small numbers)

### Common Vulnerabilities

❌ **No Staleness Check:**
```solidity
// Vulnerable
function getPrice() external view returns (uint256) {
    (, int256 answer,,,) = priceFeed.latestRoundData();
    return uint256(answer);
}
```

❌ **No Deviation Protection:**
```solidity
// Vulnerable
function withdraw(uint256 shares) external {
    uint256 price = oracle.getPrice(); // Could be manipulated
    uint256 amount = shares * price / 1e18;
    token.transfer(msg.sender, amount);
}
```

❌ **Single Oracle Dependency:**
```solidity
// Risky
function liquidate(address user) external {
    uint256 price = oracle.getPrice(); // What if oracle fails?
    // ... liquidation logic
}
```

✅ **Proper Implementation:**
```solidity
function getValidatedPrice() public view returns (uint256) {
    // Try primary oracle
    (uint256 price1, bool valid1) = _getChainlinkPrice();
    if (valid1) {
        // Verify against TWAP
        uint256 twapPrice = getTWAP(30 minutes);
        require(
            _isWithinDeviation(price1, twapPrice),
            "Price deviation too high"
        );
        return price1;
    }

    // Fallback to TWAP only
    return getTWAP(1 hours);
}
```

## Gas Optimization Tips

1. **Cache Oracle Reads:**
   ```solidity
   // Instead of multiple calls
   uint256 price = _getPrice();
   uint256 value1 = amount1 * price;
   uint256 value2 = amount2 * price;
   ```

2. **Batch Observations:**
   ```solidity
   // Update multiple observations in one transaction
   function updatePrices(uint256[] calldata prices) external {
       for (uint i = 0; i < prices.length; i++) {
           _recordObservation(prices[i]);
       }
   }
   ```

3. **Use Ring Buffer for TWAP:**
   ```solidity
   // Fixed-size array, O(1) updates
   Observation[100] public observations;
   uint256 public observationIndex;
   ```

## Best Practices

1. **Document Oracle Assumptions:**
   - Expected update frequency
   - Accepted staleness threshold
   - Decimal format
   - Trust assumptions

2. **Monitoring and Alerts:**
   - Track oracle uptime
   - Monitor price deviations
   - Alert on circuit breaker activation

3. **Graceful Degradation:**
   - Continue critical functions with cached prices
   - Disable non-critical features
   - Allow emergency withdrawals

4. **Testing:**
   - Test all failure modes
   - Fuzz test price inputs
   - Simulate oracle downtime
   - Test decimal edge cases

5. **Upgradeability:**
   - Allow oracle address updates
   - Update staleness thresholds
   - Modify deviation limits

## Learning Objectives

By completing this project, you will:

- ✅ Understand oracle security fundamentals
- ✅ Implement TWAP price feeds
- ✅ Integrate Chainlink oracles safely
- ✅ Handle oracle failure modes
- ✅ Build circuit breaker mechanisms
- ✅ Validate price data properly
- ✅ Implement multi-oracle strategies
- ✅ Test oracle edge cases

## Real-World Applications

- **Lending Protocols:** Safe collateral valuation
- **DEXs:** Fair swap pricing
- **Derivatives:** Accurate index prices
- **Vaults:** Correct share valuations
- **Stablecoins:** Peg maintenance
- **Options:** Strike price determination

## Further Reading

- [Chainlink Documentation](https://docs.chain.link/)
- [Oracle Manipulation Attacks](https://blog.chain.link/oracle-manipulation-attacks/)
- [Uniswap V3 TWAP Oracles](https://docs.uniswap.org/concepts/protocol/oracle)
- [MakerDAO Oracle Security](https://docs.makerdao.com/smart-contract-modules/oracle-module)
- [Compound Price Feeds](https://docs.compound.finance/v2/prices/)

## Running the Project

```bash
# Install dependencies
forge install

# Run tests
forge test --match-path test/Project47.t.sol -vvv

# Run specific test
forge test --match-test testOracleStaleness -vvv

# Deploy
forge script script/DeployProject47.s.sol --rpc-url <RPC_URL> --broadcast

# Check coverage
forge coverage --match-path test/Project47.t.sol
```

## Challenge Tasks

1. **Add L2 Sequencer Check:**
   - Integrate Chainlink sequencer uptime feed
   - Prevent operations during sequencer downtime
   - Add grace period after restart

2. **Implement Multi-Asset Vault:**
   - Support multiple tokens
   - Each with different oracles
   - Aggregate total value correctly

3. **Build Oracle Aggregator:**
   - Combine multiple oracle sources
   - Median, average, or weighted strategies
   - Outlier detection and removal

4. **Add Historical Price Access:**
   - Query prices at specific timestamps
   - Support flash loan attack detection
   - Implement price range queries

5. **Create Oracle Governance:**
   - Vote to update oracle addresses
   - Timelock for critical changes
   - Emergency pause mechanism

## Common Pitfalls

1. **Not Checking All Round Data Fields**
   - Check `answeredInRound >= roundId`
   - Verify `updatedAt` is recent
   - Ensure `answer > 0`

2. **Decimal Mismatches**
   - Chainlink uses 8 decimals for USD
   - Tokens can have 6, 8, 18 decimals
   - Always normalize

3. **Ignoring Price Bounds**
   - Set min/max reasonable prices
   - Prevent overflow/underflow
   - Sanity check calculations

4. **No Fallback Mechanism**
   - Single point of failure
   - No degraded mode
   - System halt on oracle failure

5. **Insufficient TWAP Period**
   - Too short: Still manipulatable
   - Too long: Lags market
   - Balance based on use case

## Summary

Oracle integration is one of the most critical and risky aspects of DeFi protocols. This project teaches you how to safely integrate price feeds into vaults, protecting against the most common attack vectors and failure modes.

**Key Takeaways:**
- Always validate oracle data (staleness, sanity checks)
- Use TWAP for critical operations
- Implement circuit breakers for failures
- Never rely on a single oracle
- Test all failure scenarios
- Handle decimals carefully

Master these concepts to build secure, reliable DeFi protocols! 🔐

---


## 48-meta-vault

# Project 48: Meta-Vault (4626→4626)

A meta-vault that wraps one or more ERC-4626 vaults, enabling yield aggregation, auto-rebalancing, and recursive vault compositions.

## Concepts

### Meta-Vault Architecture: Vaults Investing in Vaults

**FIRST PRINCIPLES: Recursive Composition**

A meta-vault is an ERC-4626 vault that invests in other ERC-4626 vaults rather than directly in assets. This creates a recursive structure!

**CONNECTION TO PROJECT 11, 20, & 45**:
- **Project 11**: ERC-4626 vault standard
- **Project 20**: Share-based accounting fundamentals
- **Project 45**: Multi-asset vaults (similar concept)
- **Project 48**: Meta-vaults (vaults of vaults!)

**UNDERSTANDING THE ARCHITECTURE**:

```
Meta-Vault Structure:
┌─────────────────────────────────────────┐
│ User deposits: 1000 DAI                 │
│   ↓                                      │
│ MetaVault (ERC-4626)                    │ ← Top-level vault
│   Receives: 1000 DAI                   │
│   Mints: X shares to user               │ ← Meta-vault shares
│   ↓                                      │
│ MetaVault allocates to:                 │
│   ├─ UnderlyingVault A (ERC-4626)      │ ← 40% allocation
│   │   Receives: 400 DAI                 │
│   │   Mints: Y shares to MetaVault      │ ← Underlying shares
│   │                                      │
│   ├─ UnderlyingVault B (ERC-4626)      │ ← 30% allocation
│   │   Receives: 300 DAI                 │
│   │   Mints: Z shares to MetaVault      │
│   │                                      │
│   └─ UnderlyingVault C (ERC-4626)      │ ← 30% allocation
│       Receives: 300 DAI                 │
│       Mints: W shares to MetaVault      │
└─────────────────────────────────────────┘
```

A meta-vault is an ERC-4626 vault that invests in other ERC-4626 vaults rather than directly in assets. This creates a recursive structure where:
- Users deposit assets into the meta-vault
- The meta-vault deposits into underlying vaults
- The meta-vault can rebalance between vaults to optimize yield

**UNDERSTANDING RECURSIVE SHARES** (from Project 11 & 20 knowledge):

When a user wants to know their asset value:
```
User's shares → MetaVault.convertToAssets()
              → Underlying shares
              → UnderlyingVault.convertToAssets()
              → Actual assets
```

**GAS COST** (from Project 01 & 11 knowledge):
- Meta-vault conversion: ~100 gas (view function)
- Underlying vault conversion: ~100 gas × N vaults
- Total: ~100 + (100 × N) gas (cheap for view functions!)

**REAL-WORLD ANALOGY**: 
Like a mutual fund investing in other mutual funds:
- **Meta-vault** = Fund of funds
- **Underlying vaults** = Individual funds
- **Shares** = Units of ownership
- **Recursive** = Fund value depends on underlying fund values

### Recursive Share Calculations

When a user deposits assets:
```
1. User deposits 1000 DAI to MetaVault
2. MetaVault deposits 1000 DAI to UnderlyingVault
3. UnderlyingVault mints X shares to MetaVault
4. MetaVault mints Y shares to User

convertToAssets for User:
Y shares → MetaVault.convertToAssets(Y)
         → X underlying shares
         → UnderlyingVault.convertToAssets(X)
         → Z assets
```

The math is recursive:
```solidity
// Meta-vault's convertToAssets must call underlying vault's convertToAssets
function convertToAssets(uint256 shares) public view returns (uint256) {
    uint256 underlyingShares = // calculate underlying shares held
    uint256 assets = underlyingVault.convertToAssets(underlyingShares);
    return shares * assets / totalSupply();
}
```

### Performance Compounding

When both vaults generate yield, the effects compound:
```
Year 1:
- Underlying Vault: 10% APY
- Meta-Vault adds: 5% strategy alpha
- Total: ~15.5% (not 15% due to compounding)

Calculation:
- 100 DAI → 110 DAI (underlying vault)
- 110 DAI → 115.5 DAI (meta-vault's 5% on 110)
```

### Fee on Fee Calculations

If both vaults charge fees, they compound negatively:
```
Underlying Vault: 2% fee
Meta-Vault: 1% fee

Effective fee: 1 - (0.98 * 0.99) = 2.98% (not 3%)
```

This is important for users to understand total cost of nested vaults.

### Yield Aggregation

A meta-vault can aggregate yield from multiple sources:
```
MetaVault holds:
- 40% in StableVault (5% APY)
- 30% in LendingVault (8% APY)
- 30% in LiquidityVault (12% APY)

Effective APY: 0.4*5% + 0.3*8% + 0.3*12% = 8%
```

### Rebalancing Between Vaults

The meta-vault can shift capital to maximize yield:
```solidity
function rebalance() external {
    // Find vault with highest yield
    uint256 bestVaultIndex = findHighestYield();

    // Withdraw from lower-yield vaults
    for (uint256 i = 0; i < vaults.length; i++) {
        if (i != bestVaultIndex) {
            uint256 shares = vaults[i].balanceOf(address(this));
            vaults[i].redeem(shares, address(this), address(this));
        }
    }

    // Deposit all assets to best vault
    asset.approve(address(vaults[bestVaultIndex]), balance);
    vaults[bestVaultIndex].deposit(balance, address(this));
}
```

### Gas Considerations

Nested vaults have higher gas costs:
- Each operation requires multiple vault interactions
- Recursive calculations add overhead
- Rebalancing involves multiple withdrawals and deposits

Trade-off: Higher gas costs vs. better yield optimization

### Use Cases

#### 1. Yield Aggregators (Yearn-style)
```
User deposits USDC
  → MetaVault finds best yield among:
    → Aave Lending
    → Compound Lending
    → Curve LP
    → Convex Staking
```

#### 2. Risk Diversification
```
MetaVault spreads capital across multiple vaults to reduce risk:
- 50% in conservative vault (3% APY, low risk)
- 30% in moderate vault (7% APY, medium risk)
- 20% in aggressive vault (15% APY, high risk)
```

#### 3. Strategy Layering
```
Base Layer: Lending vault (provides base yield)
  → Middle Layer: Yield optimization (compounds rewards)
    → Top Layer: Auto-selling rewards (converts to base asset)
```

#### 4. Multi-Asset Exposure
```
User deposits ETH
  → MetaVault splits to:
    → 60% ETH vault
    → 40% stETH vault (liquid staking)
```

## Key Implementation Details

### Recursive Asset Calculation
```solidity
function totalAssets() public view override returns (uint256) {
    uint256 total = 0;
    for (uint256 i = 0; i < underlyingVaults.length; i++) {
        // Get our shares in underlying vault
        uint256 shares = underlyingVaults[i].balanceOf(address(this));
        // Convert to assets (recursive call)
        uint256 assets = underlyingVaults[i].convertToAssets(shares);
        total += assets;
    }
    return total;
}
```

### Deposit Strategy
```solidity
function _depositToUnderlying(uint256 assets) internal {
    if (autoRebalance) {
        // Deposit to vault with highest yield
        uint256 bestVault = _findBestVault();
        IERC20(asset()).approve(address(underlyingVaults[bestVault]), assets);
        underlyingVaults[bestVault].deposit(assets, address(this));
    } else {
        // Deposit proportionally to all vaults
        for (uint256 i = 0; i < underlyingVaults.length; i++) {
            uint256 amount = assets * allocations[i] / TOTAL_BPS;
            IERC20(asset()).approve(address(underlyingVaults[i]), amount);
            underlyingVaults[i].deposit(amount, address(this));
        }
    }
}
```

### Withdrawal Strategy
```solidity
function _withdrawFromUnderlying(uint256 assets) internal {
    uint256 remaining = assets;

    // Try to withdraw from most liquid vault first
    for (uint256 i = 0; i < underlyingVaults.length && remaining > 0; i++) {
        uint256 available = underlyingVaults[i].maxWithdraw(address(this));
        uint256 toWithdraw = remaining > available ? available : remaining;

        if (toWithdraw > 0) {
            underlyingVaults[i].withdraw(toWithdraw, address(this), address(this));
            remaining -= toWithdraw;
        }
    }

    require(remaining == 0, "Insufficient liquidity");
}
```

### Rebalancing Logic
```solidity
function rebalance() external {
    // Calculate target allocations based on yields
    uint256[] memory targetAllocations = _calculateOptimalAllocation();

    // Calculate current allocations
    uint256 totalAssets = totalAssets();
    uint256[] memory currentAssets = new uint256[](underlyingVaults.length);

    for (uint256 i = 0; i < underlyingVaults.length; i++) {
        currentAssets[i] = underlyingVaults[i].convertToAssets(
            underlyingVaults[i].balanceOf(address(this))
        );
    }

    // Rebalance: withdraw from over-allocated, deposit to under-allocated
    for (uint256 i = 0; i < underlyingVaults.length; i++) {
        uint256 target = totalAssets * targetAllocations[i] / TOTAL_BPS;

        if (currentAssets[i] > target) {
            // Withdraw excess
            uint256 excess = currentAssets[i] - target;
            underlyingVaults[i].withdraw(excess, address(this), address(this));
        }
    }

    // Deposit to under-allocated vaults
    uint256 idle = IERC20(asset()).balanceOf(address(this));
    for (uint256 i = 0; i < underlyingVaults.length; i++) {
        uint256 target = totalAssets * targetAllocations[i] / TOTAL_BPS;

        if (currentAssets[i] < target) {
            uint256 needed = target - currentAssets[i];
            uint256 toDeposit = needed > idle ? idle : needed;

            if (toDeposit > 0) {
                IERC20(asset()).approve(address(underlyingVaults[i]), toDeposit);
                underlyingVaults[i].deposit(toDeposit, address(this));
                idle -= toDeposit;
            }
        }
    }
}
```

## Security Considerations

### 1. Underlying Vault Trust
- Meta-vault is only as secure as underlying vaults
- Malicious underlying vault can drain funds
- Important to whitelist trusted vaults only

### 2. Reentrancy
- Recursive calls to multiple vaults create reentrancy risks
- Use ReentrancyGuard on all external functions
- Follow checks-effects-interactions pattern

### 3. Rounding Errors
- Multiple conversions amplify rounding errors
- Always round in favor of the vault (against users slightly)
- Monitor for accumulated rounding dust

### 4. Liquidity Risks
- Underlying vaults might have withdrawal limits
- Need to handle partial withdrawals gracefully
- Consider withdrawal queues for illiquid positions

### 5. Oracle/Price Risks
- If vaults use different pricing mechanisms
- Arbitrage opportunities between vaults
- Flash loan attacks on rebalancing

## Testing Checklist

- [ ] Deposit to single underlying vault
- [ ] Deposit split across multiple vaults
- [ ] Withdraw from single vault with sufficient liquidity
- [ ] Withdraw requiring multiple vaults
- [ ] Recursive share calculations are accurate
- [ ] Rebalancing shifts funds correctly
- [ ] Yield accumulation in underlying vaults reflects in meta-vault
- [ ] Fees compound correctly
- [ ] Handle underlying vault with withdrawal limits
- [ ] Prevent unauthorized rebalancing
- [ ] Gas costs are acceptable for operations
- [ ] Rounding errors don't accumulate significantly

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/MetaVaultSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployMetaVaultSolution.s.sol` - Deployment script patterns
- `test/solution/MetaVaultSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains recursive composition, vault-of-vaults pattern, yield aggregation
- **Connections to Project 11**: ERC-4626 vault standard (meta-vault is also ERC-4626)
- **Connections to Project 20**: Share-based accounting (recursive shares)
- **Connections to Project 45**: Multi-asset vaults (similar concept, different implementation)
- **Real-World Context**: Yield aggregators use this pattern to optimize returns across multiple strategies

## Learning Objectives

1. Understand vault composition patterns
2. Implement recursive share calculations
3. Build yield aggregation logic
4. Handle multi-vault rebalancing
5. Calculate compounding fees and yields
6. Manage liquidity across multiple sources
7. Optimize gas for nested operations
8. Design secure multi-vault systems

## Common Pitfalls

1. **Incorrect recursive math**: Forgetting to convert underlying shares to assets
2. **Rebalancing costs**: Gas costs can exceed yield gains from rebalancing
3. **Liquidity fragmentation**: Splitting too much across many vaults reduces efficiency
4. **Stale yield data**: Using outdated APY for rebalancing decisions
5. **Approval management**: Not approving each underlying vault separately
6. **Withdrawal failures**: Not handling cases where vaults have different liquidity

## Extensions

1. **Dynamic allocation**: ML-based vault selection
2. **Flash rebalancing**: Use flash loans to rebalance without fragmented liquidity
3. **Cross-chain vaults**: Aggregate yield across multiple chains
4. **Risk-adjusted allocation**: Allocate based on Sharpe ratio, not just APY
5. **Social vaults**: Users can copy successful meta-vault strategies
6. **Governance**: Token holders vote on allocation strategy

## Real-World Examples

- **Yearn Finance**: Aggregates yield across DeFi protocols
- **Idle Finance**: Rebalances between lending protocols
- **Rari Capital (Fuse)**: Pools aggregate yield from isolated markets
- **Harvest Finance**: Auto-compounds farm rewards
- **Beefy Finance**: Vault composition for optimal yields

## Resources

- [ERC-4626 Specification](https://eips.ethereum.org/EIPS/eip-4626)
- [Yearn Vaults](https://docs.yearn.finance/getting-started/products/yvaults/overview)
- [Vault Aggregation Patterns](https://github.com/yearn/yearn-vaults)
- [Yield Optimization Strategies](https://defillama.com/yields)

---


## 49-leverage-vault

# Project 49: Leverage Looping Vault

A sophisticated DeFi vault that implements leveraged yield strategies using borrow-deposit loops on lending protocols. This project demonstrates advanced risk management, liquidation prevention, and automated deleverage mechanisms.

## Learning Objectives

- Understand leverage looping mechanics in DeFi
- Implement safe borrow-deposit-borrow cycles
- Calculate and manage leverage ratios
- Implement liquidation prevention strategies
- Build auto-deleverage mechanisms
- Model interest rate impacts
- Manage collateral health factors

## Leverage Looping Mechanics

### Basic Concept: Amplifying Yield Through Leverage

**FIRST PRINCIPLES: Leverage and Compound Interest**

Leverage looping amplifies yield by recursively depositing and borrowing the same asset. This is a powerful but risky DeFi strategy!

**CONNECTION TO PROJECT 11, 20, & 43**:
- **Project 11**: ERC-4626 vault standard
- **Project 20**: Share-based accounting
- **Project 43**: Yield-bearing vaults
- **Project 49**: Leveraged yield strategies!

**UNDERSTANDING LEVERAGE LOOPING**:

Leverage looping amplifies yield by recursively depositing and borrowing the same asset:

```
Leverage Loop Example:
┌─────────────────────────────────────────┐
│ Step 1: Deposit 100 ETH as collateral   │
│   Collateral: 100 ETH                   │
│   Debt: 0 ETH                            │
│   ↓                                      │
│ Step 2: Borrow 75 ETH (75% LTV)        │
│   Collateral: 100 ETH                   │
│   Debt: 75 ETH                           │
│   ↓                                      │
│ Step 3: Deposit 75 ETH as collateral    │
│   Collateral: 175 ETH                   │ ← Increased!
│   Debt: 75 ETH                           │
│   ↓                                      │
│ Step 4: Borrow 56.25 ETH (75% of 75)    │
│   Collateral: 175 ETH                   │
│   Debt: 131.25 ETH                       │ ← Increased!
│   ↓                                      │
│ Step 5: Repeat...                       │
│   ↓                                      │
│ Final Position:                          │
│   Total Collateral: ~400 ETH            │ ← Amplified!
│   Total Debt: ~300 ETH                  │ ← Borrowed!
│   Leverage: 4x                           │ ← 4× exposure!
└─────────────────────────────────────────┘
```

**WHY LOOP?** (Yield Amplification):

If a lending protocol offers:
- **Supply APY**: 3% (earn on deposits)
- **Borrow APY**: 2% (pay on borrows)
- **Net Spread**: 1% (profit margin)

**Without leverage**:
- Deposit: 100 ETH
- Earn: 100 ETH × 3% = 3 ETH/year
- Net: 3 ETH/year (3% return)

**With 4x leverage**:
- Total Collateral: 400 ETH (4× initial)
- Earn: 400 ETH × 3% = 12 ETH/year (on collateral)
- Pay: 300 ETH × 2% = 6 ETH/year (on debt)
- **Net**: 6 ETH/year (6% on initial capital!)
- **Amplification**: 2× return compared to unleveraged!

**UNDERSTANDING THE RISK** (from Project 46 knowledge):

```
Liquidation Risk:
┌─────────────────────────────────────────┐
│ Leverage: 4x                            │
│ Collateral: 400 ETH                     │
│ Debt: 300 ETH                           │
│ Health Factor: 1.33                      │ ← Close to liquidation!
│                                          │
│ If price drops 25%:                     │
│   Collateral: 300 ETH (400 × 0.75)     │ ← Decreased!
│   Debt: 300 ETH (unchanged)             │
│   Health Factor: 1.0                    │ ← LIQUIDATION! 💥
└─────────────────────────────────────────┘
```

**REAL-WORLD ANALOGY**: 
Like buying a house with a mortgage:
- **Deposit** = Initial capital (100 ETH)
- **Borrow** = Mortgage (300 ETH)
- **Total Position** = House value (400 ETH)
- **Leverage** = 4× (4× exposure with 1× capital)
- **Risk** = If house price drops, you can lose everything!

### The Math Behind Loops

For a target leverage ratio `L` with max LTV `ltv`:

```
Total Iterations needed: log(1 - L × (1 - ltv)) / log(ltv)

Example: 4x leverage at 75% LTV
= log(1 - 4 × 0.25) / log(0.75)
≈ 5 iterations
```

Maximum theoretical leverage:
```
Max Leverage = 1 / (1 - ltv)

At 75% LTV: 1 / 0.25 = 4x maximum
At 80% LTV: 1 / 0.20 = 5x maximum
At 90% LTV: 1 / 0.10 = 10x maximum (very risky!)
```

## Risk Buffers and Safety Margins

### Health Factor

Most lending protocols use a health factor:

```
Health Factor = (Collateral × Liquidation Threshold) / Debt

Safe: HF > 1.5
Warning: HF 1.2 - 1.5
Danger: HF 1.0 - 1.2
Liquidation: HF < 1.0
```

### Buffer Calculation

Always maintain a safety buffer:

```solidity
// Target: 4x leverage at 75% LTV
// Liquidation: 80% LTV

Current LTV = Debt / Collateral = 75%
Liquidation LTV = 80%
Buffer = (80% - 75%) / 80% = 6.25%

// Recommended: 10-20% buffer from liquidation
Safe Target LTV = Liquidation LTV × 0.85
```

### Dynamic Buffer Sizing

Adjust buffers based on market conditions:

```
High Volatility (e.g., ETH):
- Normal: 15% buffer
- High vol: 25% buffer

Low Volatility (e.g., stablecoins):
- Normal: 5% buffer
- High vol: 10% buffer
```

## Liquidation Bands

### Liquidation Threshold

Each asset has a liquidation threshold (LT):

```
Asset          | Max LTV | Liq. Threshold | Max Leverage
---------------|---------|----------------|-------------
ETH            | 80%     | 82.5%          | 5.0x
WBTC           | 75%     | 80%            | 4.0x
stETH          | 90%     | 93%            | 10.0x
USDC (stable)  | 90%     | 95%            | 10.0x
```

### Price-Based Liquidation Bands

Monitor price thresholds:

```
Entry Price: $2,000 ETH
Collateral: 100 ETH
Debt: 150,000 USDC
Current LTV: 75%
Liquidation LTV: 82.5%

Liquidation Price = Entry Price × (Current LTV / Liq LTV)
                  = $2,000 × (0.75 / 0.825)
                  = $1,818

Warning Price (10% buffer): $2,000
Danger Price (5% buffer): $1,909
```

### Multi-Asset Liquidation

For correlated assets, calculate joint liquidation risk:

```
Portfolio:
- 100 ETH collateral ($200,000)
- 50 WBTC collateral ($2,000,000)
- Total: $2,200,000
- Debt: 1,650,000 USDC
- Weighted LTV: 75%

If ETH -20% AND WBTC -15%:
- ETH value: $160,000
- WBTC value: $1,700,000
- Total: $1,860,000
- LTV: 88.7% → LIQUIDATED
```

## Interest Rate Modeling

### Variable Interest Rates

Most protocols use utilization-based rates:

```
Utilization = Total Borrows / Total Deposits

Base Rate: 0%
Slope 1 (U < 80%): 4% at optimal
Slope 2 (U > 80%): up to 100%

Borrow Rate = Base + Utilization × Slope1 (if U < optimal)
            = Base + Optimal Rate + (U - Optimal) × Slope2

Supply Rate = Borrow Rate × Utilization × (1 - Reserve Factor)
```

### Interest Rate Example (Aave V3)

```
Utilization: 70%
Base: 0%
Slope1: 4% / 80% = 0.05
Slope2: 96% / 20% = 4.8

Borrow Rate = 0% + 70% × 0.05 = 3.5%
Supply Rate = 3.5% × 70% × 0.9 = 2.205%

Net Spread = 2.205% - 3.5% = -1.295%
```

### Compound Interest Calculation

Interest compounds every block:

```solidity
// Aave uses ray math (1e27 precision)
function calculateCompoundedInterest(
    uint256 rate,
    uint256 lastUpdateTimestamp
) internal view returns (uint256) {
    uint256 timeDelta = block.timestamp - lastUpdateTimestamp;

    // Linear for small periods
    if (timeDelta == 0) return RAY;

    // exp = rate × timeDelta
    uint256 exp = rate * timeDelta;

    // Simple compound: (1 + rate/n)^n ≈ e^rate
    // For precision, use binomial expansion
    uint256 compounded = RAY + exp + (exp * exp) / (2 * RAY);

    return compounded;
}
```

### Net APY Calculation

```
Leverage: 4x
Supply APY: 3%
Borrow APY: 2.5%
Collateral: 400 ETH equivalent
Debt: 300 ETH equivalent

Annual Supply Yield = 400 × 3% = 12 ETH
Annual Borrow Cost = 300 × 2.5% = 7.5 ETH
Net Yield = 12 - 7.5 = 4.5 ETH
Net APY on Initial Capital (100 ETH) = 4.5%

If borrow rate increases to 4%:
Annual Borrow Cost = 300 × 4% = 12 ETH
Net Yield = 12 - 12 = 0 ETH (break-even!)
```

## Deleverage Strategies

### Proportional Deleverage

Reduce leverage by withdrawing collateral and repaying debt proportionally:

```
Current: 400 ETH collateral, 300 ETH debt (4x leverage)
Target: 3x leverage

Steps:
1. Calculate target debt: 100 initial × (3 - 1) = 200 ETH
2. Debt to repay: 300 - 200 = 100 ETH
3. Collateral to withdraw: 100 / 0.75 = 133.33 ETH

Loop:
- Repay 25 ETH debt
- Withdraw 33.33 ETH collateral
- Repeat 4 times
```

### Emergency Deleverage

Fast deleverage during market crashes:

```solidity
function emergencyDeleverage(uint256 targetHealthFactor) external {
    while (getHealthFactor() < targetHealthFactor) {
        // Withdraw maximum safe amount
        uint256 maxWithdraw = calculateMaxWithdraw();

        // Withdraw collateral
        lendingPool.withdraw(asset, maxWithdraw, address(this));

        // Repay debt
        uint256 repayAmount = min(maxWithdraw, totalDebt);
        lendingPool.repay(asset, repayAmount, address(this));

        // Check if we can continue
        if (maxWithdraw < minThreshold) break;
    }
}
```

### Flash Loan Deleverage

Most capital-efficient deleverage using flash loans:

```
Current: 400 ETH collateral, 300 ETH debt

1. Flash loan 300 ETH
2. Repay entire debt (300 ETH)
3. Withdraw all collateral (400 ETH)
4. Repay flash loan (300 ETH + fee)
5. Keep remaining (100 ETH - fee)

Cost: Only flash loan fee (~0.09%)
Time: Single transaction
```

### Partial Deleverage on Drift

Auto-rebalance when LTV drifts:

```solidity
function rebalance() external {
    uint256 currentLTV = getCurrentLTV();
    uint256 targetLTV = getTargetLTV();

    // Allow 2% drift before rebalancing
    if (abs(currentLTV - targetLTV) < 0.02) return;

    if (currentLTV > targetLTV) {
        // Over-leveraged: deleverage
        uint256 excessDebt = calculateExcessDebt();
        deleverageByAmount(excessDebt);
    } else {
        // Under-leveraged: can leverage more
        uint256 additionalBorrow = calculateAdditionalBorrow();
        leverageByAmount(additionalBorrow);
    }
}
```

## Real-World Examples

### Aave V3 ETH Loop

```
Protocol: Aave V3 Ethereum
Asset: wstETH (wrapped staked ETH)
Max LTV: 90%
Liquidation Threshold: 93%
Target Leverage: 8x
Safety Buffer: 15%

Current Rates (May 2024):
- wstETH Supply APY: 2.5%
- wstETH Borrow APY: 2.2%
- stETH Staking APY: 3.5%

Combined Yield:
Base Staking: 3.5% on 800 wstETH = 28 wstETH
Supply Interest: 2.5% on 800 wstETH = 20 wstETH
Borrow Cost: 2.2% on 700 wstETH = -15.4 wstETH
Net: 32.6 wstETH on 100 initial = 32.6% APY!

Risk: 5% price drop → liquidation
```

### Compound V3 USDC Loop

```
Protocol: Compound V3
Asset: USDC
Max LTV: 90%
Liquidation Threshold: 93%
Target Leverage: 9x
Safety Buffer: 10%

Current Rates:
- USDC Supply APY: 5%
- USDC Borrow APY: 4.5%
- COMP Rewards: +2% APY

Combined Yield:
Supply: 5% on 900 USDC = 45 USDC
Rewards: 2% on 900 USDC = 18 USDC
Borrow Cost: 4.5% on 800 USDC = -36 USDC
Net: 27 USDC on 100 initial = 27% APY

Risk: Minimal (stablecoin), but rate risk
```

### Morpho ETH Optimizer Loop

```
Protocol: Morpho (Aave optimizer)
Asset: ETH
Improvement: Matched peer-to-peer lending
Average LTV: 75%
Target Leverage: 4x

Morpho improves rates via P2P matching:
- Standard Aave Supply: 3%
- Morpho Enhanced Supply: 3.5% (+0.5%)
- Standard Aave Borrow: 2.5%
- Morpho Enhanced Borrow: 2.2% (-0.3%)

Increased spread: 0.8% → more profitable leverage!
```

## Implementation Checklist

### Core Features
- [ ] Leverage loop execution
- [ ] Deleverage loop execution
- [ ] Health factor monitoring
- [ ] Automatic rebalancing
- [ ] Emergency shutdown
- [ ] Flash loan integration

### Risk Management
- [ ] LTV calculation
- [ ] Health factor checks
- [ ] Price oracle integration
- [ ] Liquidation threshold monitoring
- [ ] Safety buffer enforcement
- [ ] Slippage protection

### Gas Optimizations
- [ ] Batch operations
- [ ] Optimal loop iterations
- [ ] Storage packing
- [ ] Minimal external calls
- [ ] Event emission strategy

### User Features
- [ ] Deposit/Withdraw
- [ ] Leverage adjustment
- [ ] Yield claiming
- [ ] Position metrics
- [ ] Profit/Loss tracking

## Testing Scenarios

1. **Basic Loop**: Execute 5-iteration leverage loop
2. **Target Leverage**: Achieve exact 4x leverage
3. **Deleverage**: Reduce from 4x to 2x
4. **Emergency**: Deleverage on health factor drop
5. **Interest Accrual**: Simulate 1 year of interest
6. **Market Crash**: 30% price drop simulation
7. **Liquidation Prevention**: Auto-deleverage before liquidation
8. **Flash Loan**: One-tx deleverage via flash loan
9. **Rate Changes**: Handle dynamic interest rates
10. **Dust Handling**: Manage remaining wei amounts

## Advanced Concepts

### Cross-Protocol Leverage

Use multiple protocols for better rates:

```
1. Deposit ETH on Aave (best supply rate: 3%)
2. Borrow USDC on Aave
3. Swap USDC → ETH
4. Deposit ETH on Compound (best borrow rate: 2%)
5. Repeat with cross-protocol optimization
```

### Automated Liquidation Protection

```solidity
// Keeper system
function checkUpkeep() external view returns (bool) {
    uint256 hf = getHealthFactor();
    return hf < 1.5; // Threshold for action
}

function performUpkeep() external {
    uint256 hf = getHealthFactor();

    if (hf < 1.2) {
        // Critical: aggressive deleverage
        emergencyDeleverage(1.8);
    } else if (hf < 1.5) {
        // Warning: partial deleverage
        partialDeleverage(0.1); // Reduce 10%
    }
}
```

### Yield Compounding

Auto-compound earned yield back into the position:

```solidity
function compound() external {
    // Claim rewards (if any)
    claimRewards();

    // Get current supply balance
    uint256 earned = getCurrentSupplyBalance() - lastSupplyBalance;

    // If earned enough to make it worthwhile
    if (earned > minCompoundAmount) {
        // Leverage up the earned amount
        leverageAmount(earned);
        lastSupplyBalance = getCurrentSupplyBalance();
    }
}
```

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/LeverageVaultSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployLeverageVaultSolution.s.sol` - Deployment script patterns
- `test/solution/LeverageVaultSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains leverage mechanics, borrow-deposit loops, liquidation prevention, health factors
- **Connections to Project 11**: ERC-4626 vault standard (this adds leverage)
- **Connections to Project 20**: Share-based accounting (leverage affects share prices)
- **Connections to Project 43**: Yield-bearing vaults (leverage amplifies yield)
- **Real-World Context**: Advanced DeFi strategy - amplifies yield but increases risk

## Security Considerations

1. **Oracle Manipulation**: Use TWAP or multiple oracles
2. **Flash Loan Attacks**: Protect price-sensitive operations
3. **Reentrancy**: Use checks-effects-interactions
4. **Integer Overflow**: Use SafeMath or 0.8+ built-in checks
5. **Front-running**: Consider MEV protection
6. **Emergency Pause**: Implement circuit breakers
7. **Upgradeability**: Be careful with storage layout
8. **Access Control**: Protect privileged functions

## Gas Optimization Tips

```solidity
// ❌ Bad: Multiple external calls
for (uint i = 0; i < 5; i++) {
    lendingPool.deposit(amount);
    lendingPool.borrow(amount);
}

// ✅ Good: Batch when possible
uint256[] memory amounts = new uint256[](5);
lendingPool.depositBatch(amounts);
lendingPool.borrowBatch(amounts);

// ✅ Good: Calculate optimal iterations
uint256 iterations = calculateOptimalIterations(targetLeverage);
```

## Resources

- [Aave V3 Documentation](https://docs.aave.com/developers/)
- [Compound V3 Docs](https://docs.compound.finance/)
- [DeFi Leverage Guide](https://blog.instadapp.io/defi-leverage-explained/)
- [Liquidation Mechanics](https://www.paradigm.xyz/2020/11/so-you-want-to-use-a-price-oracle)
- [Interest Rate Models](https://docs.aave.com/risk/liquidity-risk/borrow-interest-rate)

## Getting Started

1. Review the skeleton contract in `src/Project49.sol`
2. Study the complete solution in `src/solution/Project49Solution.sol`
3. Run tests: `forge test --match-path test/Project49.t.sol -vv`
4. Experiment with different leverage ratios and safety buffers
5. Try implementing flash loan deleverage

Good luck building your leverage looping vault!

---


## 50-defi-capstone

# Project 50: Full DeFi Protocol Capstone 🏆

> **Build a complete production-grade DeFi protocol integrating all concepts**

## 🎯 Learning Objectives

By completing this project, you will:

1. **Integrate multiple token standards** (ERC20, ERC721, ERC4626)
2. **Implement on-chain governance** with voting and proposals
3. **Integrate oracle price feeds** securely
4. **Build flash loan provider** for advanced DeFi operations
5. **Create multi-sig treasury** for secure fund management
6. **Implement upgradeable architecture** using proxy patterns
7. **Apply comprehensive security** (reentrancy, access control, oracles)
8. **Design complete protocol architecture** from scratch
9. **Deploy and test** a full DeFi ecosystem

## Overview: The Ultimate Integration Project

**FIRST PRINCIPLES: System Integration**

This is the **ultimate capstone project** that integrates everything you've learned throughout the Solidity curriculum. You will build a complete, production-grade DeFi protocol that demonstrates mastery of all concepts!

**CONNECTION TO ALL PREVIOUS PROJECTS**:

This project integrates concepts from **every project**:

- **Project 01**: Storage, mappings, arrays, gas optimization
- **Project 02**: Functions, payable, ETH handling, Checks-Effects-Interactions
- **Project 03**: Events for off-chain indexing
- **Project 04**: Modifiers, access control, RBAC
- **Project 05**: Custom errors for gas efficiency
- **Project 06**: Gas-optimized data structures
- **Project 07**: Reentrancy protection
- **Project 08**: ERC20 token standard
- **Project 09**: ERC721 NFT standard
- **Project 10**: Proxy patterns, upgradeability
- **Project 11**: ERC4626 vault standard
- **Project 12**: Safe ETH transfer patterns
- **Project 15**: Low-level calls
- **Projects 22+**: Advanced patterns and security

**WHAT YOU'LL BUILD**:

A complete, production-grade DeFi protocol that includes:

- 🪙 **Protocol Token** (ERC20) - From Project 08
- 🎨 **NFT Membership System** (ERC721) - From Project 09
- 🏦 **Yield Vault** (ERC4626) - From Project 11
- 🗳️ **On-chain Governance** - Integrates access control (Project 04)
- 📊 **Oracle Integration** - Price feeds for vault operations
- ⚡ **Flash Loan Provider** - Advanced DeFi pattern
- 🔐 **Multi-sig Treasury** - Secure fund management
- 🛡️ **Emergency Pause Mechanisms** - From Project 04
- 🔄 **Upgradeable Architecture** - From Project 10

**ARCHITECTURE PRINCIPLES**:

1. **Security First**: Apply all security patterns learned
2. **Gas Optimization**: Use efficient data structures from Project 06
3. **Modularity**: Separate concerns (tokens, vaults, governance)
4. **Upgradeability**: Proxy pattern for future improvements
5. **Composability**: Standard interfaces for DeFi integration

---

## Protocol Architecture

### Component Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    DeFi Protocol Ecosystem                   │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
   ┌────▼────┐          ┌─────▼─────┐        ┌─────▼─────┐
   │Protocol │          │   NFT     │        │Governance │
   │ Token   │          │Membership │        │  System   │
   │(ERC20)  │          │ (ERC721)  │        │           │
   └────┬────┘          └─────┬─────┘        └─────┬─────┘
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              │
                    ┌─────────▼─────────┐
                    │   Main Vault      │
                    │   (ERC4626)       │
                    └─────────┬─────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
   ┌────▼────┐          ┌─────▼─────┐        ┌─────▼─────┐
   │ Oracle  │          │Flash Loan │        │Multi-sig  │
   │  Price  │          │ Provider  │        │ Treasury  │
   │  Feed   │          │           │        │           │
   └─────────┘          └───────────┘        └───────────┘
```

---

## Token Economics

### Protocol Token (PROTO)

**Supply Mechanics:**
- Total Supply: 1,000,000,000 PROTO
- Initial Distribution:
  - 40% - Community Rewards (Vesting over 4 years)
  - 20% - Team & Advisors (1 year cliff, 3 year vesting)
  - 15% - Treasury
  - 15% - Liquidity Mining
  - 10% - Initial DEX Offering

**Utility:**
- Governance voting power
- Staking for protocol revenue share
- NFT minting fee discounts
- Flash loan fee discounts
- Vault performance fee reduction

**Token Flow:**
```
Users → Stake PROTO → Receive stPROTO → Earn Yield
                    ↓
              Governance Power
                    ↓
              Vote on Proposals
```

### NFT Membership System

**Tiers:**
1. **Bronze NFT** - 100 PROTO
   - 5% fee discount
   - Basic governance rights

2. **Silver NFT** - 1,000 PROTO
   - 10% fee discount
   - Enhanced governance weight (2x)

3. **Gold NFT** - 10,000 PROTO
   - 25% fee discount
   - Premium governance weight (5x)
   - Early access to new features

4. **Platinum NFT** - 100,000 PROTO (Limited to 100)
   - 50% fee discount
   - Elite governance weight (10x)
   - Protocol revenue sharing
   - Exclusive features

**NFT Features:**
- Non-transferable (Soulbound) OR Transferable (governance decision)
- Dynamic metadata based on user activity
- Upgrade paths between tiers
- Staking boosts for NFT holders

---

## Vault Strategies

### ERC4626 Yield Vault

**Strategy Types:**
1. **Conservative** - Low risk, stable yields (3-8% APY)
2. **Balanced** - Moderate risk, balanced returns (8-15% APY)
3. **Aggressive** - High risk, high returns (15-30%+ APY)

**Revenue Sources:**
- Lending protocol integration (Aave, Compound)
- Liquidity provision (Uniswap, Curve)
- Yield farming optimizations
- Flash loan fees
- Arbitrage opportunities

**Fee Structure:**
- Deposit Fee: 0% (governance adjustable)
- Withdrawal Fee: 0.1% (governance adjustable)
- Performance Fee: 10% of profits (governance adjustable)
- Management Fee: 2% annually (governance adjustable)

**Vault Mechanics:**
```
User Deposits → Vault Strategy → Yield Generation
                      ↓
                Revenue Split
                      ↓
        ┌─────────────┼─────────────┐
        │             │             │
   Users (90%)   Treasury (5%)   stPROTO Stakers (5%)
```

---

## Governance System

### Governance Token (PROTO)

**Voting Mechanism:**
- 1 PROTO = 1 Vote (base)
- NFT multipliers apply
- Delegation supported
- Vote locking for boosted power

**Proposal Types:**

1. **Parameter Changes**
   - Fee adjustments
   - Strategy allocations
   - Treasury spending limits
   - Quorum requirements

2. **Treasury Actions**
   - Fund allocation
   - Investment decisions
   - Protocol upgrades
   - Emergency actions

3. **Protocol Upgrades**
   - Smart contract upgrades
   - New feature additions
   - Deprecation of old features

**Voting Process:**
```
1. Proposal Creation (requires 100,000 PROTO or Gold NFT)
   ↓
2. Discussion Period (3 days)
   ↓
3. Voting Period (7 days)
   ↓
4. Timelock (2 days)
   ↓
5. Execution (if passed)
```

**Quorum & Thresholds:**
- Quorum: 4% of total supply must vote
- Approval: 51% for parameter changes
- Approval: 66% for protocol upgrades
- Approval: 75% for emergency actions

---

## Oracle Integration

### Price Feeds

**Supported Oracles:**
- Chainlink (Primary)
- Uniswap V3 TWAP (Fallback)
- Custom aggregator

**Use Cases:**
- Vault asset valuation
- Collateral pricing
- Flash loan limits
- NFT tier pricing

**Security Measures:**
- Multiple oracle sources
- Price deviation checks (±10% threshold)
- Staleness checks (1 hour max age)
- Circuit breakers on anomalies

---

## Flash Loan System

### Features

**Loan Mechanics:**
- Uncollateralized loans
- Single transaction repayment
- 0.09% fee (90 basis points)
- Maximum borrow: 80% of vault liquidity

**Use Cases:**
- Arbitrage opportunities
- Collateral swaps
- Debt refinancing
- Liquidation execution

**Security:**
- Reentrancy guards
- Balance verification
- Fee enforcement
- Borrower whitelist (optional)

**Flash Loan Flow:**
```
1. User calls flashLoan(amount, data)
   ↓
2. Vault transfers tokens to borrower
   ↓
3. Vault calls borrower.onFlashLoan()
   ↓
4. Borrower executes strategy
   ↓
5. Borrower returns tokens + fee
   ↓
6. Vault verifies repayment
   ↓
7. Transaction completes or reverts
```

---

## Multi-sig Treasury

### Configuration

**Signers:**
- Minimum: 5 signers
- Threshold: 3 of 5 required
- Signer rotation via governance

**Responsibilities:**
- Protocol upgrades
- Emergency pauses
- Parameter adjustments (within bounds)
- Treasury management
- Security incident response

**Transaction Types:**
1. **Routine** - 3/5 signatures
2. **Emergency** - 3/5 signatures + immediate execution
3. **Critical** - 4/5 signatures + 24h timelock

---

## Security Considerations

### Attack Vectors & Mitigations

**1. Reentrancy**
- ✅ OpenZeppelin ReentrancyGuard
- ✅ Checks-Effects-Interactions pattern
- ✅ Pull payment pattern

**2. Flash Loan Attacks**
- ✅ TWAP oracles (multi-block)
- ✅ Borrow limits
- ✅ Rate limiting
- ✅ Deposit/withdraw delays

**3. Governance Attacks**
- ✅ Timelock on execution
- ✅ Quorum requirements
- ✅ Proposal thresholds
- ✅ Emergency veto (multi-sig)

**4. Oracle Manipulation**
- ✅ Multiple oracle sources
- ✅ Price deviation checks
- ✅ Staleness verification
- ✅ Circuit breakers

**5. Economic Exploits**
- ✅ Deposit/withdrawal limits
- ✅ Gradual parameter changes
- ✅ Vault share inflation protection
- ✅ First depositor protection

### Access Control

**Role-Based Permissions:**
```solidity
- DEFAULT_ADMIN_ROLE
  └─ Full protocol control (multi-sig only)

- GOVERNANCE_ROLE
  └─ Parameter adjustments within bounds

- STRATEGIST_ROLE
  └─ Vault strategy management

- PAUSER_ROLE
  └─ Emergency pause capability

- ORACLE_ROLE
  └─ Price feed updates
```

### Emergency Mechanisms

**Pause System:**
- Individual contract pausing
- Protocol-wide pause
- Withdrawal-only mode
- Automated circuit breakers

**Recovery Procedures:**
1. Detect anomaly
2. Pause affected contracts
3. Investigate issue
4. Governance vote on fix
5. Multi-sig execution
6. Gradual unpause

---

## Deployment Guide

### Prerequisites

```bash
# Install dependencies
forge install OpenZeppelin/openzeppelin-contracts
forge install OpenZeppelin/openzeppelin-contracts-upgradeable

# Set environment variables
export PRIVATE_KEY=your_private_key
export RPC_URL=your_rpc_url
export ETHERSCAN_API_KEY=your_etherscan_key
```

### Deployment Steps

**Step 1: Deploy Core Contracts**
```bash
forge script script/DeployProject50.s.sol:DeployProject50 \
  --rpc-url $RPC_URL \
  --broadcast \
  --verify
```

**Step 2: Initialize Protocol**
```solidity
// 1. Deploy protocol token
// 2. Deploy NFT membership
// 3. Deploy governance
// 4. Deploy vault
// 5. Deploy oracle aggregator
// 6. Deploy flash loan module
// 7. Configure multi-sig
// 8. Transfer ownership
```

**Step 3: Configure Parameters**
```solidity
// Set initial fees
vault.setPerformanceFee(1000); // 10%
vault.setManagementFee(200);   // 2%

// Set governance parameters
governance.setQuorum(4e16);    // 4%
governance.setProposalThreshold(100_000e18);

// Configure oracle
oracle.addPriceFeed(token, feed);
oracle.setHeartbeat(3600);     // 1 hour
```

**Step 4: Fund Treasury**
```solidity
// Transfer initial tokens
token.transfer(treasury, INITIAL_TREASURY_AMOUNT);

// Set up vesting schedules
vesting.createSchedule(team, TEAM_ALLOCATION, vestingParams);
```

**Step 5: Start Protocol**
```solidity
// Open vault deposits
vault.unpause();

// Enable NFT minting
nft.enableMinting();

// Activate governance
governance.activate();
```

### Post-Deployment Verification

```bash
# Verify contract ownership
cast call $VAULT_ADDRESS "owner()" --rpc-url $RPC_URL

# Check initial balances
cast call $TOKEN_ADDRESS "totalSupply()" --rpc-url $RPC_URL

# Verify governance parameters
cast call $GOVERNANCE_ADDRESS "quorum()" --rpc-url $RPC_URL

# Test pause functionality
cast send $VAULT_ADDRESS "pause()" --private-key $PAUSER_KEY
```

---

## Protocol Flow Diagrams

### User Deposit Flow

```
┌─────────┐
│  User   │
└────┬────┘
     │ 1. approve(vault, amount)
     ▼
┌─────────┐
│  Token  │
└────┬────┘
     │ 2. deposit(amount, receiver)
     ▼
┌─────────┐
│  Vault  │────────────────┐
└────┬────┘                │
     │ 3. Check NFT tier   │
     ▼                     │
┌─────────┐                │
│   NFT   │                │
└────┬────┘                │
     │ 4. Calculate fees   │
     ▼                     │
┌─────────┐                │
│Strategy │◄───────────────┘
└────┬────┘  5. Deploy assets
     │
     ▼
┌─────────┐
│Protocol │ 6. Earn yield
│External │
└─────────┘
```

### Governance Proposal Flow

```
┌──────────┐
│Proposer  │
└────┬─────┘
     │ 1. createProposal(targets, values, calldatas)
     ▼
┌──────────┐
│Governance│────────────────┐
└────┬─────┘                │
     │ 2. Check threshold   │
     ▼                      │
┌──────────┐                │
│  Token   │                │
└────┬─────┘                │
     │ 3. Discussion (3d)   │
     ▼                      │
┌──────────┐                │
│  Voters  │                │
└────┬─────┘                │
     │ 4. castVote()        │
     ▼                      │
┌──────────┐                │
│ Voting   │ 5. Check NFT   │
│ Period   │    multipliers │
│  (7d)    │◄───────────────┘
└────┬─────┘
     │ 6. Check quorum & threshold
     ▼
┌──────────┐
│Timelock  │ 7. Queue (2d)
└────┬─────┘
     │ 8. execute()
     ▼
┌──────────┐
│Protocol  │ 9. Apply changes
│Contracts │
└──────────┘
```

### Flash Loan Flow

```
┌──────────┐
│Borrower  │
└────┬─────┘
     │ 1. flashLoan(token, amount, data)
     ▼
┌──────────┐
│  Vault   │
└────┬─────┘
     │ 2. Check liquidity
     ├───────────────────┐
     │                   │
     │ 3. Transfer loan  │
     ▼                   │
┌──────────┐             │
│Borrower  │             │
└────┬─────┘             │
     │ 4. onFlashLoan()  │
     │ 5. Execute strat  │
     │ 6. Approve repay  │
     ▼                   │
┌──────────┐             │
│ Strategy │             │
│Execution │             │
└────┬─────┘             │
     │                   │
     │ 7. Return tokens  │
     ▼                   │
┌──────────┐             │
│  Vault   │◄────────────┘
└────┬─────┘
     │ 8. Verify balance + fee
     │ 9. Distribute fee
     ▼
┌──────────┐
│ Success  │
└──────────┘
```

---

## Testing Strategy

### Test Coverage Requirements

**Unit Tests** (70% of test suite)
- Individual function testing
- Edge case coverage
- Access control verification
- Event emission checks

**Integration Tests** (20% of test suite)
- Multi-contract interactions
- Cross-module flows
- Upgrade scenarios
- Oracle integration

**Invariant Tests** (5% of test suite)
- Total supply consistency
- Vault share calculations
- Accounting accuracy
- Fee distribution

**Fuzzing Tests** (5% of test suite)
- Random input handling
- Boundary conditions
- Overflow/underflow
- Gas optimization

### Key Test Scenarios

1. **Happy Path**
   - User deposits → Earns yield → Withdraws
   - User mints NFT → Gets discounts
   - Proposal created → Voted → Executed

2. **Attack Scenarios**
   - Reentrancy attempts
   - Flash loan attacks
   - Governance takeover
   - Oracle manipulation
   - Vault inflation attacks

3. **Edge Cases**
   - First depositor
   - Last withdrawer
   - Zero amounts
   - Maximum values
   - Paused states

4. **Upgrade Scenarios**
   - Proxy upgrades
   - State migration
   - Backwards compatibility

---

## Advanced Features

### Upgradeability

**Proxy Pattern:**
- UUPS (Universal Upgradeable Proxy Standard)
- Governance-controlled upgrades
- Storage gap preservation
- Initialize functions

**Upgrade Process:**
```solidity
1. Deploy new implementation
2. Create governance proposal
3. Vote and approve
4. Timelock delay
5. Execute upgrade
6. Verify functionality
```

### Analytics & Metrics

**On-chain Tracking:**
- Total Value Locked (TVL)
- Protocol revenue
- User acquisition
- Governance participation
- Vault performance

**Events for Indexing:**
```solidity
event VaultDeposit(address indexed user, uint256 amount, uint256 shares);
event GovernanceVote(uint256 indexed proposalId, address indexed voter, bool support);
event FlashLoan(address indexed borrower, uint256 amount, uint256 fee);
event NFTMinted(address indexed user, uint256 tier, uint256 tokenId);
```

### Gas Optimizations

**Techniques Applied:**
- Packed storage variables
- Unchecked math where safe
- Batch operations
- Event parameter indexing
- Short-circuit evaluations
- Memory vs storage optimization

---

## Development Roadmap

### Phase 1: Foundation (Weeks 1-2)
- [ ] Core token implementation
- [ ] Basic vault mechanics
- [ ] Simple governance
- [ ] Unit tests

### Phase 2: Enhancement (Weeks 3-4)
- [ ] NFT membership system
- [ ] Oracle integration
- [ ] Flash loan module
- [ ] Integration tests

### Phase 3: Security (Weeks 5-6)
- [ ] Access control refinement
- [ ] Emergency mechanisms
- [ ] Audit preparation
- [ ] Attack scenario tests

### Phase 4: Production (Weeks 7-8)
- [ ] Multi-sig setup
- [ ] Deployment scripts
- [ ] Documentation
- [ ] Mainnet deployment

---

## Learning Objectives

By completing this capstone, you will have mastered:

✅ **Token Standards**
- ERC20 advanced features
- ERC721 NFT mechanics
- ERC4626 vault implementation

✅ **DeFi Primitives**
- Yield generation strategies
- Flash loans
- Oracle integration
- Liquidity management

✅ **Governance**
- On-chain voting
- Proposal lifecycle
- Timelock mechanisms
- Delegation

✅ **Security**
- Access control patterns
- Reentrancy prevention
- Oracle manipulation defense
- Emergency procedures

✅ **Architecture**
- Upgradeability patterns
- Modular design
- Gas optimization
- Production deployment

---

## Resources

### Documentation
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [ERC4626 Specification](https://eips.ethereum.org/EIPS/eip-4626)
- [Compound Finance](https://docs.compound.finance/)
- [Aave Protocol](https://docs.aave.com/)

### Tools
- [Foundry Book](https://book.getfoundry.sh/)
- [Solidity Documentation](https://docs.soliditylang.org/)
- [Tenderly](https://tenderly.co/) - Debugging
- [Defender](https://www.openzeppelin.com/defender) - Operations

### Security
- [Smart Contract Security Best Practices](https://consensys.github.io/smart-contract-best-practices/)
- [Secureum](https://secureum.substack.com/)
- [Trail of Bits](https://www.trailofbits.com/)

---

## Success Criteria

Your implementation should:
- ✅ Pass all test suites (>95% coverage)
- ✅ Handle edge cases gracefully
- ✅ Include comprehensive documentation
- ✅ Implement all security measures
- ✅ Be gas-optimized
- ✅ Support upgradeability
- ✅ Include deployment scripts
- ✅ Have emergency mechanisms

---

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/DeFiCapstoneSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployDeFiCapstoneSolution.s.sol` - Deployment script patterns
- `test/solution/DeFiCapstoneSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains protocol design, composability, upgradeability, security patterns
- **Connections to ALL Projects**: Combines ERC20, ERC721, ERC4626, proxies, oracles, governance
- **Real-World Context**: Complete DeFi protocol demonstrating composability and security best practices
- **Integration Mastery**: Shows how all concepts work together in production-grade systems

## Conclusion

This capstone project represents the culmination of your Solidity journey. It's not just about writing code—it's about understanding the intricate dance of security, efficiency, and user experience that defines production-grade DeFi protocols.

Take your time, test thoroughly, and build something you're proud of. This protocol could be the foundation of your next big project!

**Good luck, and happy building! 🚀**

---

## License

MIT License - See LICENSE file for details

---

