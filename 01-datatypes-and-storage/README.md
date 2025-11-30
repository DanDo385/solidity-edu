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

**Understanding Storage Costs (Gas)**:

Think of your smart contract's storage like a giant filing cabinet that exists forever on the blockchain. Every time you want to read or write to this cabinet, you pay a cost called "gas". Here's why different operations cost different amounts:

**Reading from Storage**:
- **First-time read (2,100 gas)**: Imagine walking into a cold storage warehouse for the first time in a transaction. The lights are off, you need to find the right aisle, turn on the lights, and locate the file. This "first access" within a transaction is expensive because the EVM (Ethereum Virtual Machine) needs to load this data from the blockchain state into its working memory. We call this a "cold read" - like accessing cold storage.

- **Subsequent reads (100 gas)**: Once you've already accessed that storage location in the same transaction, it's like the lights are already on and you know exactly where the file is. The EVM has already loaded it, so reading it again is much cheaper - about 21x cheaper! We call this a "warm read" - the data is already warmed up and ready to access.

**Writing to Storage**:
- **Writing a new value (zero → non-zero): 20,000 gas**: This is like adding a brand new file to an empty filing cabinet slot. You're creating something from nothing, which requires the blockchain to allocate new state space. This is the most expensive operation because every single node on the Ethereum network must record this new piece of information forever.

- **Updating an existing value (non-zero → non-zero): 5,000 gas**: This is like replacing a file that's already in the cabinet. The slot already exists, you're just changing what's in it. It's still expensive (because all nodes must update their records), but cheaper than creating something new.

**Compare to Memory (~3 gas per 32-byte word)**:
Memory is like a whiteboard in your office. It's super cheap to use because it's temporary - everything gets erased when the transaction ends. You can scribble notes, do calculations, and organize data without worrying about cost. But the moment the transaction finishes, *poof* - it's all gone. That's why memory costs about 700x less than cold storage writes!

**Real-World Example**:
Imagine you're building a game. Player scores stored in `storage` persist forever (expensive, ~20k gas to create). But calculating a temporary leaderboard during gameplay? Use `memory` (cheap, ~3 gas). You wouldn't want to pay $50 (at current gas prices) to store a calculation that only matters for 2 seconds!

On rollups (Layer 2s), calldata is cheaper but storage writes are still pricey because the data ultimately posts to Ethereum mainnet. Choosing smaller types reduces calldata footprint, which is why calldata packing matters even more on L2.

### Why Data Locations Matter

In Solidity, **where** your data lives is just as important as **what** type it is. There are three main locations:

1. **Storage** (Permanent, Expensive)
   - Like a bank vault: secure, permanent, but costly to access
   - Persists between function calls and transactions forever
   - Every change is recorded on the blockchain
   - Costs ~20,000 gas for new data, ~5,000 gas for updates

2. **Memory** (Temporary, Cheap)
   - Like RAM in your computer: fast, temporary, erased when done
   - Only exists during function execution
   - Perfect for calculations and temporary data
   - Costs ~3 gas per 32-byte word (incredibly cheap!)

3. **Calldata** (Read-Only, Cheapest)
   - Like a read-only USB drive: can't modify it, but super cheap to read
   - Used for function parameters from external calls
   - Data comes from the transaction itself
   - Most gas-efficient for passing large arrays/strings to functions

```solidity
uint256 public storageVar;  // Lives forever, expensive (~20k gas to write)
                            // Think: permanent record in a government database

function temp(uint256[] memory arr) public {
    // 'arr' is temporary, erased after function exits
    // Think: scratch paper you throw away after solving a math problem
    // Costs ~3 gas per word to allocate
}

function readOnly(uint256[] calldata arr) external {
    // 'arr' is read-only from the transaction data
    // Think: reading from a book - you can't change the text, just read it
    // Cheapest option because no copying happens!
}
```

**When to use each**:
- `storage`: Player balances, game state, ownership records - anything that must persist
- `memory`: Temporary calculations, sorting arrays, building return values
- `calldata`: Function parameters for external calls, especially large arrays

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

### Task 4: Compile and Analyze Bytecode

**Compiling Contracts:**

```bash
# Navigate to this project
cd 01-datatypes-and-storage

# Compile all contracts (creates bytecode artifacts in out/)
forge build

# Force recompilation (useful after making changes)
forge build --force

# Show compilation details
forge build -vv

# Check contract sizes (important for deployment limits)
forge build --sizes
```

**Understanding Compiled Artifacts:**

After compilation, Foundry saves artifacts in `out/DatatypesStorage.sol/DatatypesStorage.json`:
- **bytecode.object**: Full deployment bytecode (constructor + contract code)
- **deployedBytecode.object**: Runtime bytecode (what's stored on-chain)
- **abi**: Application Binary Interface (function signatures, events, errors)
- **metadata**: Compiler version, settings, source mappings

**Extracting Bytecode for Analysis:**

```bash
# Extract deployment bytecode to a file
cat out/DatatypesStorage.sol/DatatypesStorage.json | jq -r '.bytecode.object' > deployment-bytecode.txt

# Extract runtime bytecode (what's actually deployed on-chain)
cat out/DatatypesStorage.sol/DatatypesStorage.json | jq -r '.deployedBytecode.object' > runtime-bytecode.txt

# Extract ABI for frontend integration
cat out/DatatypesStorage.sol/DatatypesStorage.json | jq '.abi' > abi.json

# View bytecode length (deployment bytecode is larger due to constructor)
cat out/DatatypesStorage.sol/DatatypesStorage.json | jq -r '.bytecode.object' | wc -c
cat out/DatatypesStorage.sol/DatatypesStorage.json | jq -r '.deployedBytecode.object' | wc -c
```

**Why Analyze Bytecode?**
- **Security**: Verify what's actually deployed matches your source code
- **Size Optimization**: Ensure contracts stay under 24KB deployment limit
- **Gas Analysis**: Understand opcode-level gas costs
- **Verification**: Compare on-chain bytecode with compiled bytecode for Etherscan verification
- **Learning**: Understand how Solidity compiles to EVM bytecode

**Bytecode Analysis Tools:**
- **evm.codes**: Interactive EVM opcode reference - paste bytecode to see opcodes
- **Etherscan**: View verified bytecode on-chain after deployment
- **Cast**: Foundry's CLI tool - `cast code <ADDRESS>` to get on-chain bytecode
- **Panoramix**: Decompiler that converts bytecode back to readable Solidity-like code

### Task 5: Run Tests

```bash
# Run tests (Foundry compiles automatically if needed)
forge test

# Run with verbose output
forge test -vvv

# Run with gas reporting
forge test --gas-report
```

**Note**: `forge test` automatically compiles contracts before running tests, but explicit compilation with `forge build` is useful for:
- Checking for compilation errors without running tests
- Analyzing bytecode before deployment
- Extracting ABIs for frontend integration
- Verifying contract sizes

All tests in `test/DatatypesStorage.t.sol` should pass.

### Task 6: Test Your Deployment Script

**⚠️ IMPORTANT: This project runs on LOCAL ANVIL ONLY**

```bash
# Terminal 1: Start Anvil (keep this running)
anvil

# Terminal 2: Set up environment and deploy
cd 01-datatypes-and-storage

# Load environment variables (use default Anvil keys)
source ../.env  # Or manually: export PRIVATE_KEY=0xac0974...

# Run the deployment script (dry run - no transactions sent)
forge script script/DeployDatatypesStorage.s.sol

# Deploy to local Anvil (with transactions)
forge script script/DeployDatatypesStorage.s.sol \
  --broadcast \
  --rpc-url http://localhost:8545

# The script reads PRIVATE_KEY from .env automatically
# Use PRIVATE_KEY_1 through PRIVATE_KEY_9 for multi-address testing
```

**Environment Setup:**

Create `.env` in the project root with Anvil's default accounts:
```bash
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
PRIVATE_KEY_1=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
PRIVATE_KEY_2=0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
# ... (see root .env.example for all 10 accounts)
```

**What happens in each mode?**
- **Dry run** (`forge script` without `--broadcast`): Simulates the script, shows what would happen, but doesn't send transactions
- **Broadcast** (`--broadcast`): Actually sends transactions to the local Anvil network
- **Anvil accounts**: All 10 accounts are pre-funded with 10,000 ETH each

### Task 7: Experiment

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

**What are Value Types?**
Value types work like photocopying a document. When you assign a value type to a new variable, you get a completely independent copy. Changing one doesn't affect the other.

```solidity
uint256 a = 10;
uint256 b = a;  // 'b' is a COPY, not a reference
                // Think: You photocopied document 'a' to create document 'b'
b = 20;         // 'a' is still 10
                // Changing the photocopy doesn't change the original!
```

**Examples**: `uint`, `int`, `bool`, `address`, `bytes32`, `enum`

**Why?** Value types are typically small (32 bytes or less) and fit in a single EVM stack slot. It's cheaper and simpler to just copy them rather than manage pointers.

**Real-World Analogy**: Value types are like cash. If you give someone a $10 bill, they have their own $10 and you can't change it. If they turn it into two $5 bills, your original $10 doesn't change.

### Reference Types (Assigned by Reference)

**What are Reference Types?**
Reference types work like sharing a Google Doc link. Multiple variables can point to the same underlying data. Changing it through one "link" affects everyone who has access to that data.

```solidity
uint[] storage arr1 = myArray;  // 'arr1' points to myArray in permanent storage
                                // Think: arr1 is a link to a shared Google Doc

uint[] memory arr2 = arr1;      // 'arr2' is a COPY in temporary memory
                                // Think: You downloaded a copy of the Google Doc to your computer

arr1.push(5);                   // Changes the permanent storage (the original Google Doc)
arr2.push(5);                   // Only changes your local copy (your downloaded file)
```

**Examples**: `array`, `struct`, `mapping` (storage only)

**Why?** Reference types can be huge (arrays with millions of elements!). Copying them every time would waste insane amounts of gas. Instead, we use "references" (pointers) that tell the EVM where to find the data.

**Critical Rule**: The data location (`storage`, `memory`, `calldata`) determines whether you're working with the original or a copy!
- `storage` → `storage`: Reference (same Google Doc)
- `storage` → `memory`: Copy (download the Doc)
- `memory` → `memory`: Reference (same temporary copy)

**Real-World Analogy**: Reference types are like a house address. Multiple people can have "123 Main St" written down, but there's only one actual house. If someone renovates the house, everyone who visits that address sees the changes.

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

**Understanding Struct Packing**:
The EVM stores data in "slots" of exactly 32 bytes (256 bits). Think of each slot like a shelf in a warehouse - it's always the same size, whether you fill it completely or waste space.

**Why Packing Matters**:
Every storage slot you use costs gas to read and write. If you can fit multiple variables into one slot instead of using multiple slots, you save money! But there's a catch: the EVM can only pack variables that appear next to each other in your struct definition.

**Bad Packing Example**:
```solidity
// ❌ BAD: Uses 3 storage slots (96 bytes total)
struct BadPacking {
    uint256 a;  // Slot 0: [aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa] (32 bytes - FULL)
    uint8 b;    // Slot 1: [b_______________________________] (1 byte used, 31 WASTED!)
    uint256 c;  // Slot 2: [ccccccccccccccccccccccccccccccc] (32 bytes - FULL)
}
// Reading this struct: 3 SLOAD operations = 6,300 gas (if warm)
// Writing this struct: 3 SSTORE operations = 15,000+ gas
```

Think of it like packing suitcases. You put a large item (uint256) in suitcase 1. Then you put a tiny item (uint8 - like a single sock) in suitcase 2, wasting all that space. Then you put another large item (uint256) in suitcase 3. You just paid airline fees for 3 suitcases when you could've paid for 2!

**Good Packing Example**:
```solidity
// ✅ GOOD: Uses 2 storage slots (64 bytes total)
struct GoodPacking {
    uint256 a;  // Slot 0: [aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa] (32 bytes - FULL)
    uint256 c;  // Slot 1: [ccccccccccccccccccccccccccccccc] (32 bytes - FULL)
    uint8 b;    // Slot 1: [ccccccccccccccccccccccccccccccb] (packs with 'c'!)
}
// Reading this struct: 2 SLOAD operations = 4,200 gas (33% cheaper!)
// Writing this struct: 2 SSTORE operations = 10,000+ gas (33% cheaper!)
```

Wait, how did `b` fit into Slot 1 with `c`? Because `uint256` takes 32 bytes, but `uint8` only takes 1 byte. The EVM is smart: it sees that slot 1 has `c` using 32 bytes, but wait - if we re-arrange, we can put `c` in 31 bytes and squeeze `b` into the remaining 1 byte... Actually no, `uint256` always takes the full 32 bytes. Let me correct this:

Actually, the better packing is:
```solidity
// ✅ BEST: Uses 2 storage slots (64 bytes total)
struct BestPacking {
    uint256 a;  // Slot 0: [aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa] (32 bytes - FULL)
    uint8 b;    // Slot 1: [b_______________________________] (1 byte)
    // Since slot 1 has 31 bytes free, we could pack more small types here!
    // But uint256 c won't fit because it needs a full 32 bytes
    uint256 c;  // Slot 2: [ccccccccccccccccccccccccccccccc] (32 bytes - FULL)
}
```

Actually, the REAL optimal packing would be:
```solidity
// ✅ OPTIMAL: Uses 2 storage slots if we're clever!
struct OptimalPacking {
    uint128 a;  // Slot 0: [aaaaaaaaaaaaaaaaa________________] (16 bytes)
    uint128 c;  // Slot 0: [aaaaaaaaaaaaaaaaaaccccccccccccccc] (16 bytes - FITS!)
    uint8 b;    // Slot 1: [b_______________________________] (1 byte)
}
// Or even better, pack everything possible:
struct UltraOptimal {
    uint128 a;  // Slot 0: [aaaaaaaaaaaaaaaaa________________] (16 bytes)
    uint64 d;   // Slot 0: [aaaaaaaaaaaaaaaaadddddddd________] (8 bytes)
    uint32 e;   // Slot 0: [aaaaaaaaaaaaaaaaaddddddddeee_____] (4 bytes)
    uint8 b;    // Slot 0: [aaaaaaaaaaaaaaaaaddddddddeeeb____] (1 byte)
    // Still 3 bytes free in this slot!
}
// Only 1 storage slot used! Reading/writing is 66% cheaper than bad packing!
```

**The Packing Rule**:
The Solidity compiler packs variables into the same slot if:
1. They're sequential in the struct (next to each other)
2. Their combined size ≤ 32 bytes
3. Each individual variable fits within a single slot

**Real-World Analogy**: Struct packing is like Tetris. You want to arrange your blocks (variables) so they fit together tightly, with no wasted space. Every empty gap in a slot is wasted gas!

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

// ✅ CORRECT: Read from environment (uses Anvil default for local dev)
uint256 key = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
```

**Note**: The fallback value is Anvil's default Account #0 private key, safe for local development only.

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

**⚠️ IMPORTANT: This project runs on LOCAL ANVIL ONLY**

```bash
# Terminal 1: Start Anvil (keep running)
anvil

# Terminal 2: Set up environment and deploy
cd 01-datatypes-and-storage

# Load environment variables
source ../.env  # Contains default Anvil private keys

# Deploy to local Anvil
forge script script/DeployDatatypesStorage.s.sol \
  --broadcast \
  --rpc-url http://localhost:8545

# The script automatically uses PRIVATE_KEY from .env
```

### Environment Variables

Create `.env` in the project root with Anvil's default accounts:

```bash
# Main deployer (Account #0)
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Additional accounts for multi-address testing
PRIVATE_KEY_1=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
PRIVATE_KEY_2=0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
PRIVATE_KEY_3=0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6
PRIVATE_KEY_4=0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a
PRIVATE_KEY_5=0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba
PRIVATE_KEY_6=0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e
PRIVATE_KEY_7=0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356
PRIVATE_KEY_8=0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97
PRIVATE_KEY_9=0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6
```

**Account Details:**
- **PRIVATE_KEY**: Account #0 (`0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`) - Main deployer
- **PRIVATE_KEY_1-9**: Accounts #1-9 for multi-address interactions
- All accounts are pre-funded with 10,000 ETH when Anvil starts

**Best Practices:**
1. Always use Anvil for local development
2. Use `PRIVATE_KEY` for main deployer operations
3. Use `PRIVATE_KEY_1` through `PRIVATE_KEY_9` for multi-address testing
4. Never commit `.env` file to git (it's in `.gitignore`)
5. Keep Anvil running in a separate terminal while developing

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
