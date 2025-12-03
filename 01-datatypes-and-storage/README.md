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
- `src/solution/DatatypesStorageSolution.sol` - Reference contract implementation
- `script/solution/DeployDatatypesStorageSolution.s.sol` - Deployment script patterns
- `test/solution/DatatypesStorageSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

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
