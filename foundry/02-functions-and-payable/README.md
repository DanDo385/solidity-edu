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

### Why This Matters

Traditional code only moves numbers in RAM. A Solidity function can move **real money** on a shared ledger that never forgets. Designing a payable function is closer to wiring funds at a bank than calling a local method: identity (`msg.sender`), amount (`msg.value`), and side effects (gas limits, reentrancy) all matter.

**Python**: `def deposit(amount): balance += amount` - just numbers in memory
**Solidity**: `function deposit() public payable { balances[msg.sender] += msg.value; }` - **real ETH** permanently recorded on blockchain

Solidity exists because Ethereum needed a contract language that compiles deterministically to EVM bytecode. Gavin Wood sketched the first version so every node could run the *exact* same bytecode without ambiguity. Today the Solidity team still optimizes the compiler (Solc) to shrink bytecode and reorder operations safely.

### ETH: The Native Currency

ETH is the native asset tracked directly by the EVM. It is measured in **wei** (1 ETH = 10^18 wei) and can be sent to EOAs or contracts.

**Key Properties**:
- Not a token contract - tracked by EVM itself
- Measured in wei (smallest unit)
- Can be sent to EOAs (Externally Owned Accounts) or contracts
- Contracts must explicitly accept ETH (via `payable` modifier)

**Real-world analogy**: ETH is like cash - it's the native currency of the Ethereum network. ERC20 tokens are like gift cards - they're contracts that represent value, but ETH is the real money.

### Ways to Send ETH

| Method | Gas limit | Reverts on failure? | Return value | Recommendation |
|--------|-----------|---------------------|--------------|----------------|
| `transfer()` | 2,300 | Yes | None | ❌ Avoid (breaks on smart wallets) |
| `send()` | 2,300 | No | `bool` | ❌ Avoid (limited gas) |
| `call{value:}()` | All remaining | No | `(bool, bytes)` | ✅ Use (modern standard) |

**Why `.call` is better**:
- After the 2016 DAO fork, gas costs were repriced (EIP-150, later EIP-1884)
- `transfer()` started failing on some contracts (smart contract wallets need more gas)
- `.call` gives you the success boolean so you can handle failures explicitly
- Forwards all remaining gas (works with smart contract wallets like Gnosis Safe)

**Real-world analogy**: `transfer()` is like a vending machine that only accepts exact change and gives you no change back. `.call` is like a cashier who can handle any payment and tells you if it worked.

### Function Visibility

Solidity has four visibility levels:

1. **`public`**: Callable from anywhere (external + internal)
   - Auto-generates getter for state variables
   - Copies calldata to memory (~200 gas overhead for arrays)

2. **`external`**: Only callable from outside
   - Most gas-efficient for arrays/structs (uses calldata directly)
   - Cannot be called internally without `this.functionName()`

3. **`internal`**: Callable from this contract and derived contracts
   - Like protected in other languages
   - Perfect for helper functions

4. **`private`**: Only callable from this exact contract
   - Most restricted
   - Note: "private" doesn't mean encrypted - all blockchain data is public!

**Gas optimization**: Use `external` with `calldata` for user-facing APIs when possible - saves ~200 gas per call for complex parameters.

### The `payable` Modifier

```solidity
function deposit() public payable {
    // msg.value holds the wei sent with this call
}
```

**Without `payable`**: Any incoming ETH causes the transaction to revert
**With `payable`**: Contract can receive ETH

**Why explicit?** Prevents accidental ETH acceptance - you must deliberately opt-in. This prevents contracts from accidentally accepting ETH they can't handle.

**Real-world analogy**: `payable` is like a cash register drawer - it must be explicitly opened to accept money. Without it, the drawer stays closed and money bounces back.

### `receive()` vs `fallback()`

These are special functions that handle ETH transfers:

**`receive()`**:
- Called when ETH is sent with **empty calldata**
- Must be `external payable`
- No arguments, no return value
- Think: "plain envelope with just money inside"

**`fallback()`**:
- Called when:
  1. Function signature doesn't match any function
  2. ETH sent with data but no `receive()` exists
- Can be `payable` or not
- Can access `msg.data`
- Think: "mystery package - we don't know what it is"

**Decision tree**:
- Empty data + `receive()` exists → `receive()`
- Unknown function or no `receive()` → `fallback()`

**Real-world analogy**: `receive()` is like an ATM slot - it only accepts cash (ETH) with no instructions. `fallback()` is like a mailroom sorting system - it handles packages (calls) that don't match any known recipient.

### Checks-Effects-Interactions Pattern

**CRITICAL SECURITY PATTERN** for functions that send ETH:

1. **CHECKS**: Validate conditions (`require` statements)
2. **EFFECTS**: Update state (modify storage)
3. **INTERACTIONS**: External calls (send ETH, call contracts)

**Why this order?** Prevents reentrancy attacks! If you update state BEFORE external calls, a reentrant attacker can't drain funds because the balance is already updated.

**Vulnerable example**:
```solidity
// ❌ BAD: External call before state update
require(balances[msg.sender] >= amount);
msg.sender.call{value: amount}("");  // Attacker can re-enter here!
balances[msg.sender] -= amount;  // Too late!
```

**Safe example**:
```solidity
// ✅ GOOD: State update before external call
require(balances[msg.sender] >= amount);  // CHECK
balances[msg.sender] -= amount;  // EFFECT (update first!)
msg.sender.call{value: amount}("");  // INTERACTION (call last)
```

**Real-world analogy**: Like settling a tab at a bar - you close your tab (update state) BEFORE handing over cash (external call). If someone tries to order again, the tab already shows they paid.

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
- `src/solution/FunctionsPayableSolution.sol` - Reference contract implementation
- `script/solution/DeployFunctionsPayableSolution.s.sol` - Deployment script patterns
- `test/solution/FunctionsPayableSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

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
