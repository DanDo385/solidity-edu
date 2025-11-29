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
7. **Learn Foundry Script contracts** and how to deploy contracts programmatically

## Why This Matters

**Python**: You can write `x = 42` then reassign `x = "hello"`. Types are dynamic.
**Solidity**: You must declare `uint256 x = 42` and can *never* assign a string to `x`. Types are static and immutable.

**Why?** The EVM (Ethereum Virtual Machine) requires:
- **Deterministic memory layout**: Every node must compute the same storage slots
- **Gas predictability**: Type sizes determine computational costs
- **Security**: Type confusion can lead to vulnerabilities

Think of storage like a *global shipping warehouse*: every package must have the exact same dimensions and aisle number on every forklift (node) so deliveries are reproducible worldwide.

This is similar to Rust (safety through types) and Go (explicit types), but stricter than both because blockchain state must be deterministically reproducible. Solidity was co-designed by Gavin Wood and Christian Reitwiessner; they favored explicit types so compilers (Solc) could map human code to tight EVM bytecode without ambiguity.

## Background: The EVM Storage Model

**Fun fact**: Solc first lowers Solidity to an intermediate language called *Yul* before emitting bytecode. That lets the compiler aggressively reorder storage writes for gas gains while keeping the slot math deterministic.

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
- Write (zero → non-zero): 20,000 gas
- Write (non-zero → non-zero): 5,000 gas

**Compare to memory**: ~3 gas per 32-byte word

On rollups (Layer 2s), calldata is cheaper but storage writes are still pricey because the data ultimately posts to Ethereum mainnet. Choosing smaller types reduces calldata footprint, which is why calldata packing matters even more on L2.

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

**Plus**, a Foundry deployment script that:
- ✅ Reads environment variables for configuration
- ✅ Deploys contracts to local/testnet/mainnet
- ✅ Logs deployment information for verification

## Tasks

### Task 1: Implement the Skeleton Contract

Open `src/DatatypesStorage.sol` and implement:

1. **State variables** for each datatype
2. **Functions** to manipulate mappings and arrays
3. **Getters** that demonstrate data location keywords
4. **Struct packing** to minimize gas costs

### Task 2: Implement the Deployment Script

Open `script/DeployDatatypesStorage.s.sol` and complete the TODOs:

1. **Read the deployer's private key** from environment variables using `vm.envOr()`
2. **Start broadcasting transactions** with `vm.startBroadcast()`
3. **Deploy the contract** using the `new` keyword
4. **Log deployment information** using `console.log()`
5. **Stop broadcasting** with `vm.stopBroadcast()`

**Why deployment scripts?** In production, you need reproducible, scriptable deployments. Foundry Script contracts let you:
- Deploy the same way every time
- Test deployments locally before going to mainnet
- Automate deployment pipelines
- Verify contracts on Etherscan automatically

**Key Foundry Script concepts**:
- `Script.sol`: Base contract that provides cheatcodes like `vm.envOr()` and `vm.startBroadcast()`
- `vm.envOr()`: Reads environment variables with fallback values
- `vm.startBroadcast()`: Enables transaction broadcasting (without this, scripts are simulation-only)
- `console.log()`: Prints values during script execution (useful for debugging and recording addresses)

### Task 3: Study the Solutions

Compare your implementations with the solution files:

**Contract Solution**: `src/solution/DatatypesStorageSolution.sol`
- Read the extensive inline documentation
- Understand *why* each line is written that way
- Note the gas optimization comments

**Script Solution**: `script/solution/DeployDatatypesStorageSolution.s.sol`
- See how environment variables are handled
- Understand the broadcast pattern
- Learn best practices for logging deployment info

### Task 4: Run Tests

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

### Task 5: Test Your Deployment Script

```bash
# Start a local Anvil node (in a separate terminal)
anvil

# Run the deployment script (dry run - no transactions sent)
forge script script/DeployDatatypesStorage.s.sol

# Deploy to local Anvil (with transactions)
forge script script/DeployDatatypesStorage.s.sol --broadcast --rpc-url http://localhost:8545

# Deploy to testnet (Sepolia)
forge script script/DeployDatatypesStorage.s.sol --broadcast \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --verify
```

**What happens in each mode?**
- **Dry run** (`forge script` without `--broadcast`): Simulates the script, shows what would happen, but doesn't send transactions
- **Broadcast** (`--broadcast`): Actually sends transactions to the network
- **Verify** (`--verify`): Automatically verifies the contract on Etherscan after deployment

### Task 6: Experiment

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
4. Deploy without `vm.startBroadcast()` - what happens?
5. Try deploying with a different private key - how does the owner change?

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

### Foundry Script Cheatcodes

Foundry provides powerful cheatcodes for scripts:

```solidity
// Read environment variable with fallback
uint256 key = vm.envOr("PRIVATE_KEY", uint256(0x123...));

// Start broadcasting transactions
vm.startBroadcast(key);

// Deploy a contract
MyContract instance = new MyContract();

// Log information
console.log("Deployed at:", address(instance));

// Stop broadcasting
vm.stopBroadcast();
```

**Why cheatcodes?** They're special functions that Foundry intercepts and handles differently than normal Solidity. They let you interact with the environment, control transaction flow, and debug deployments.

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

**Rule**: Variables in a struct pack if their combined size <= 32 bytes. Storage packing is the EVM equivalent of fitting carry-ons into an overhead bin; wasted space costs gas every time.

### Pitfall 4: Forgetting to Broadcast

```solidity
// ❌ WRONG: Script runs but no transactions are sent
function run() external {
    MyContract instance = new MyContract();  // Simulation only!
}

// ✅ CORRECT: Transactions are actually sent
function run() external {
    vm.startBroadcast();
    MyContract instance = new MyContract();  // Real deployment
    vm.stopBroadcast();
}
```

### Pitfall 5: Hardcoding Private Keys

```solidity
// ❌ WRONG: Never hardcode private keys!
uint256 key = 0x123...;  // Security risk!

// ✅ CORRECT: Read from environment
uint256 key = vm.envOr("PRIVATE_KEY", uint256(0xac09...));  // Safe fallback for local dev
```

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
// x = "hello";  // Compile error
uint256[] memory arr = new uint256[](3);  // Must specify type AND location
```

**Solidity is strictest because blockchain state must be deterministic across all nodes.**

## Real-World Anchors and Fun Facts

- **Elevator vs stairs**: Reading storage is like waiting for an elevator (slow but reaches every floor), while memory is taking the stairs for quick trips that do not persist.
- **DAO fork**: After the 2016 DAO exploit, Ethereum and Ethereum Classic split. That fork reinforced the need for explicit storage rules because replaying history on two chains demanded byte-for-byte determinism.
- **ETH inflation risk**: Large unbounded mappings/arrays increase state size. More state means more chain bloat; if block sizes grow, validators need more resources, which can indirectly pressure issuance to pay for security.
- **Compiler trivia**: The Solidity team ships frequent optimizer improvements; a packed struct can compile down to fewer `SSTORE` opcodes, saving thousands of gas. Run `solc --optimize` to see the difference in bytecode size.
- **Layer 2 tie-in**: Rollups charge mainly for calldata. Returning `bytes32` instead of `string` trims calldata bytes, which can cut fees by 30–60% on optimistic rollups.
- **Deployment automation**: Most production teams use Foundry Scripts or Hardhat scripts to deploy. This ensures consistency and allows for automated verification, which is critical for security audits.

## Deployment Guide

### Local Development (Anvil)

```bash
# Terminal 1: Start Anvil
anvil

# Terminal 2: Deploy to local network
forge script script/DeployDatatypesStorage.s.sol \
  --broadcast \
  --rpc-url http://localhost:8545
```

### Testnet Deployment (Sepolia)

```bash
# Set environment variables
export SEPOLIA_RPC_URL="https://sepolia.infura.io/v3/YOUR_KEY"
export PRIVATE_KEY="0xYOUR_PRIVATE_KEY"

# Deploy and verify
forge script script/DeployDatatypesStorage.s.sol \
  --broadcast \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

### Mainnet Deployment

**⚠️ WARNING**: Only deploy to mainnet after thorough testing!

```bash
# Set mainnet RPC URL
export MAINNET_RPC_URL="https://mainnet.infura.io/v3/YOUR_KEY"

# Deploy (double-check everything first!)
forge script script/DeployDatatypesStorage.s.sol \
  --broadcast \
  --rpc-url $MAINNET_RPC_URL \
  --private-key $PRIVATE_KEY \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

**Best Practices**:
1. Always test locally first
2. Deploy to testnet before mainnet
3. Use a hardware wallet or secure key management for mainnet
4. Verify contracts on Etherscan
5. Keep deployment logs for records

## Further Reading

- [Solidity Docs: Types](https://docs.soliditylang.org/en/latest/types.html)
- [Solidity Docs: Data Location](https://docs.soliditylang.org/en/latest/types.html#data-location)
- [Understanding Storage Layout](https://docs.soliditylang.org/en/latest/internals/layout_in_storage.html)
- [Gas Costs Reference](https://www.evm.codes/)
- [Foundry Book: Scripts](https://book.getfoundry.sh/tutorials/solidity-scripting)
- [Foundry Cheatcodes Reference](https://book.getfoundry.sh/cheatcodes/)

## Completion Checklist

- [ ] Implemented skeleton contract (`src/DatatypesStorage.sol`)
- [ ] Implemented deployment script (`script/DeployDatatypesStorage.s.sol`)
- [ ] All tests pass (`forge test`)
- [ ] Deployment script works locally (`forge script --broadcast`)
- [ ] Read and understood solution contract (`src/solution/`)
- [ ] Read and understood solution script (`script/solution/`)
- [ ] Compared gas costs (`forge test --gas-report`)
- [ ] Experimented with different data types and locations
- [ ] Can explain storage vs memory vs calldata
- [ ] Can calculate struct packing savings
- [ ] Understands Foundry Script cheatcodes and broadcast pattern

## Next Steps

Once comfortable with datatypes, storage, and deployment:
- Move to [Project 02: Functions & Payable](../02-functions-and-payable/)
- Experiment with the contract in Remix IDE
- Deploy to a testnet and interact with your contract
- Try deploying with constructor parameters
- Explore multi-step deployment scripts

## Pro Tips

1. **Always specify data locations** for reference types in functions
2. **Use `calldata` for external function parameters** (cheapest)
3. **Pack structs carefully** - group small types together
4. **Use `uint256` for local variables** (gas-optimized by EVM)
5. **Only use smaller types (`uint8`, `uint128`) in structs** for packing
6. **Always use `vm.envOr()` for sensitive values** - never hardcode keys
7. **Test deployments locally first** - Anvil is your friend
8. **Log everything** - deployment addresses are important for frontends
9. **Use `--verify` flag** - automatic Etherscan verification saves time
10. **Keep deployment logs** - you'll need contract addresses later

---

**Ready to code?** Start with `src/DatatypesStorage.sol`, then move to `script/DeployDatatypesStorage.s.sol`!
