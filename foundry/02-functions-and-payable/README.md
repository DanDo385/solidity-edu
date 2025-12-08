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
