# Complete Learning Guide for Solidity Development

> **Comprehensive reference covering Solidity basics, language comparisons, Foundry tooling, gas optimization, and security practices**

## Table of Contents

### Part 1: Solidity Basics
- [Data Types](#data-types)
- [Functions](#functions)
- [Storage and Memory](#data-locations)
- [Common Patterns](#important-patterns)

### Part 2: Language Comparisons
- [Type Systems](#type-systems)
- [Error Handling](#error-handling-patterns)
- [Memory Management](#memory-management)
- [Performance Characteristics](#performance-characteristics)

### Part 3: Foundry Development
- [Getting Started](#getting-started-with-foundry)
- [Testing](#forge-commands)
- [Deployment](#foundry-scripts-for-deployment)
- [Advanced Patterns](#advanced-testing-patterns)

### Part 4: Gas Optimization
- [Storage Optimization](#storage-optimization)
- [Function Optimization](#external-vs-public-functions)
- [Loop Optimization](#loop-optimization)
- [Advanced Techniques](#advanced-techniques)

### Part 5: Security Checklist
- [Reentrancy & State Management](#reentrancy--state-management)
- [Access Control](#access-control--authorization)
- [Testing & Verification](#testing--verification)
- [Deployment Security](#network--deployment-security)

---

## 🚀 Quick Navigation

**Need to find something fast?**
- [Data Types](#data-types) - All Solidity types explained
- [Functions](#functions) - Function syntax and patterns
- [Storage vs Memory](#data-locations) - Critical gas optimization
- [Foundry Commands](#forge-commands) - Testing and deployment
- [Gas Optimization](#storage-optimization) - Save gas with these patterns
- [Security Checklist](#reentrancy--state-management) - Security best practices

**Jump to:**
- [Part 1: Solidity Basics](#part-1-solidity-basics)
- [Part 2: Language Comparisons](#part-2-language-comparisons)
- [Part 3: Foundry Development](#part-3-foundry-development)
- [Part 4: Gas Optimization](#part-4-gas-optimization)
- [Part 5: Security Checklist](#part-5-security-checklist)

## 📖 When to Use This Guide

**Use LEARNING_GUIDE.md when:**
- ✅ Learning Solidity syntax for the first time
- ✅ Comparing Solidity to other languages you know
- ✅ Looking up Foundry commands and patterns
- ✅ Optimizing gas costs
- ✅ Reviewing security best practices
- ✅ Quick reference while coding

**Don't use this guide for:**
- ❌ Project-specific implementation details (see project READMEs in [main repository](../README.md))
- ❌ DeFi attack vectors (see [DEFI_REFERENCE.md](../DEFI_REFERENCE.md))
- ❌ Project navigation (see [PROJECT_MANAGEMENT.md](../PROJECT_MANAGEMENT.md))

**Related Documentation:**
- **[README.md](../README.md)** - Main entry point, project overview
- **[DEFI_REFERENCE.md](../DEFI_REFERENCE.md)** - DeFi attacks and ERC-4626 vault mathematics
- **[PROJECT_MANAGEMENT.md](../PROJECT_MANAGEMENT.md)** - Learning paths and project dependencies

## 📝 Code Examples Index

Jump straight to worked snippets without scrolling:
- **Data Types**: [Value Types](#value-types-stored-directly-in-variables), [Reference Types](#reference-types-store-reference-to-data), [Storage Packing](#storage-packing)
- **Functions**: [Visibility](#visibility--mutability), [Payable Functions](#payable-functions), [Modifiers](#modifiers)
- **Foundry**: [Testing Commands](#forge-commands), [Deployment Scripts](#foundry-scripts-for-deployment), [Fuzzing/Invariant Patterns](#advanced-testing-patterns)
- **Gas Optimization**: [Storage](#storage-optimization), [Loops](#loop-optimization), [Advanced Techniques](#advanced-techniques)
- **Security**: [Reentrancy](#reentrancy--state-management), [Access Control](#access-control--authorization), [Deployment Security](#network--deployment-security)

## 🔗 Related Projects for Practice

- **Project 01**: Datatypes & Storage — apply the value/reference and data location sections.
- **Project 06**: Mappings, Arrays & Gas — measure the storage hashing and loop tips here.
- **Project 11**: Reentrancy & Security — put the security checklist into practice.

---

# Solidity Basics - Quick Reference Guide

> **Quick lookup for syntax, types, and common patterns**
> For deep dives, see individual project READMEs.

## Table of Contents

1. [Data Types](#data-types)
2. [Data Locations](#data-locations)
3. [Functions](#functions)
4. [Visibility & Mutability](#visibility--mutability)
5. [Control Structures](#control-structures)
6. [Events](#events)
7. [Errors](#errors)
8. [Modifiers](#modifiers)
9. [Inheritance](#inheritance)
10. [Important Patterns](#important-patterns)

---

## Data Types

### Value Types (Stored directly in variables)

```solidity
// Booleans
bool public isActive = true;

// Integers
uint256 public count = 42;           // Unsigned (0 to 2^256-1)
int256 public temperature = -10;     // Signed (-2^255 to 2^255-1)
uint8 public smallNumber = 255;      // 8-bit (0 to 255)

// Address
address public owner = 0x1234...;    // 20-byte Ethereum address
address payable public recipient;    // Can receive ETH

// Bytes
bytes32 public hash;                 // Fixed-size (1 to 32 bytes)
bytes public data;                   // Dynamic-size byte array

// Enums
enum State { Pending, Active, Closed }
State public currentState = State.Pending;
```

**Language Comparisons**:

**TypeScript:**
```typescript
// Static typing with type inference
let count: number = 42;
let isActive: boolean = true;
let owner: string = "0x1234...";
// Types are checked at compile time, but sizes aren't specified
```

**Go:**
```go
// Static typing, explicit types
var count uint256 = 42
var isActive bool = true
var owner string = "0x1234..."
// Types are explicit, but sizes vary by platform
```

**Rust:**
```rust
// Static typing with strong type inference
let count: u256 = 42;
let is_active: bool = true;
let owner: String = "0x1234...".to_string();
// Types are explicit, sizes depend on target architecture
```

**Solidity:**
```solidity
// Static typing, explicit sizes, NO inference
uint256 count = 42;        // Must specify size (256 bits)
bool isActive = true;      // Always 1 byte
address owner = 0x1234...; // Always 20 bytes
// Every type has a fixed size for deterministic storage layout
```

**Real-World Analogy**: Solidity types are like numbered lockers in a gym - each locker (variable) has a fixed size (type) and can only hold items that fit exactly. TypeScript/Go/Rust are more like flexible storage units where sizes can vary.

**Solidity Why**: EVM requires fixed-size types for:
- **Deterministic storage layout**: Every node must compute the same storage slots
- **Gas calculation**: Type sizes determine computational costs
- **Security**: Type confusion can lead to vulnerabilities

### Reference Types (Store reference to data)

```solidity
// Arrays
uint[] public dynamicArray;          // Dynamic size
uint[10] public fixedArray;          // Fixed size
uint[][] public nestedArray;         // 2D array

// Structs
struct User {
    address wallet;
    uint256 balance;
    bool isActive;
}
User public user;

// Mappings (like hash tables)
mapping(address => uint256) public balances;
mapping(address => mapping(uint256 => bool)) public nested;
```

**Gas Note**: Dynamic arrays in storage are expensive. Each `push()` costs ~20k+ gas.

**Real-World Analogy**: Think of storage arrays like renting storage units - each time you add an item (push), you're renting another unit, which costs money (gas). Memory arrays are like borrowing a shopping cart - free to use temporarily, but you return it when done.

**Language Comparison**:

**TypeScript:**
```typescript
// Arrays are dynamic and flexible
let arr: number[] = [];
arr.push(42);  // Easy to grow, no cost concerns
```

**Go:**
```go
// Slices are dynamic
arr := []uint256{}
arr = append(arr, 42)  // Can grow, memory managed automatically
```

**Rust:**
```rust
// Vec is dynamic
let mut arr: Vec<u256> = Vec::new();
arr.push(42);  // Can grow, ownership system manages memory
```

**Solidity:**
```solidity
// Must specify location, each operation costs gas
uint256[] storage persistentArray;  // Expensive: ~20k gas per push
uint256[] memory tempArray;         // Cheaper: ~3 gas per word
```

---

## Data Locations

**Critical concept**: Where your data lives affects gas costs dramatically.

```solidity
contract DataLocations {
    // STORAGE: Persistent on blockchain (expensive)
    uint256 public storedValue;  // Lives in contract state

    function example(
        uint256[] memory memArray,    // MEMORY: Temporary, erased after call
        uint256[] calldata cdArray    // CALLDATA: Read-only, from transaction
    ) public {
        // Storage reference
        uint256 storage sValue = storedValue;  // Points to state variable

        // Memory copy
        uint256[] memory tempArray = new uint256[](10);  // Temp allocation

        // Calldata is read-only, most gas-efficient for external calls
        uint256 first = cdArray[0];  // Read directly from transaction data
    }
}
```

| Location | Use Case | Cost | Mutability |
|----------|----------|------|------------|
| `storage` | Contract state variables | High (~20k gas/write) | Mutable |
| `memory` | Function parameters, temp variables | Medium (~3 gas/word) | Mutable |
| `calldata` | External function inputs | Low (read-only) | Immutable |

**Rule of Thumb**:
- External functions: Use `calldata` for arrays/strings
- Internal functions: Use `memory` for temporary data
- Persistent data: Use state variables (implicit `storage`)

**Real-World Analogy**: Data locations are like different types of storage:
- **Storage**: Like a bank vault - permanent, secure, but expensive to access
- **Memory**: Like a desk drawer - temporary, cheap, but cleared when you're done
- **Calldata**: Like reading a letter - you can read it, but can't modify it, and it's free

**Language Comparison**:

**TypeScript:**
```typescript
// No explicit memory management
function process(data: number[]) {
    // Data is passed by reference (objects) or value (primitives)
    // Memory managed automatically by GC
}
```

**Go:**
```go
// Value semantics vs pointers
func process(data []uint256) {
    // Slices are passed by value (but reference underlying array)
    // GC manages memory
}
```

**Rust:**
```rust
// Ownership system
fn process(data: Vec<u256>) {
    // Ownership transferred, memory managed by ownership system
    // No GC, compile-time memory safety
}
```

**Solidity:**
```solidity
// Explicit data locations required
function process(uint256[] calldata data) external {
    // Must specify: calldata (read-only), memory (temporary), or storage (persistent)
    // Each has different gas costs and mutability rules
}
```

---

## Functions

### Basic Syntax

```solidity
function functionName(
    uint256 param1,
    address param2
)
    public          // Visibility
    payable         // Can receive ETH
    returns (uint256)  // Return type
{
    // Function body
    return param1 + 1;
}
```

### Special Functions

```solidity
// Constructor: Called once on deployment
constructor(address _owner) {
    owner = _owner;
}

// Receive: Called when ETH sent with empty calldata
receive() external payable {
    emit Received(msg.sender, msg.value);
}

// Fallback: Called when no function matches or no receive()
fallback() external payable {
    emit FallbackCalled(msg.sender, msg.value, msg.data);
}
```

**Decision Tree: When is each called?**
```
Send ETH to contract
    |
msg.data empty?
    |-- Yes -> receive() exists? -> Yes: receive() / No: fallback()
    |-- No  -> fallback()
```

---

## Visibility & Mutability

### Visibility Modifiers

```solidity
contract Visibility {
    // PUBLIC: Callable externally and internally (auto-generates getter)
    function publicFunc() public {}

    // EXTERNAL: Only callable externally (cheaper than public)
    function externalFunc() external {}

    // INTERNAL: Only this contract and derived contracts
    function internalFunc() internal {}

    // PRIVATE: Only this contract
    function privateFunc() private {}
}
```

**Gas Comparison**:
```solidity
// Public: Copies calldata to memory (~200 gas overhead)
function publicFunc(uint[] memory data) public {}

// External: Reads directly from calldata (cheaper)
function externalFunc(uint[] calldata data) external {}
```

**Use external for public APIs unless you need internal calls**.

**Real-World Analogy**: Visibility modifiers are like different types of access:
- **Public**: Like a public phone - anyone can use it, but it costs more (like a payphone)
- **External**: Like a mailbox - only outsiders can use it, cheaper (like dropping mail)
- **Internal**: Like a family phone - only family members (this contract and children) can use it
- **Private**: Like a diary - only you (this contract) can access it

**Language Comparison**:

**TypeScript:**
```typescript
// Public by default, can be private/protected
class Contract {
    public value: number = 0;      // Public (default)
    private secret: number = 42;   // Private
    protected shared: number = 10; // Protected (subclasses)
}
```

**Go:**
```go
// Capitalized = exported (public), lowercase = private
type Contract struct {
    Value  uint256  // Public (exported)
    secret uint256  // Private (not exported)
}
```

**Rust:**
```rust
// pub = public, default = private
pub struct Contract {
    pub value: u256,   // Public
    secret: u256,      // Private
}
```

**Solidity:**
```solidity
// Explicit visibility, plus external/internal distinction
contract Example {
    uint256 public value;      // Public: external + internal, auto-getter
    uint256 external extValue; // External only (cheaper)
    uint256 internal shared;   // Internal: this + derived contracts
    uint256 private secret;    // Private: this contract only
}
```

### State Mutability

```solidity
contract Mutability {
    uint256 public value = 10;

    // VIEW: Reads state, doesn't modify (no gas when called externally)
    function getValue() public view returns (uint256) {
        return value;
    }

    // PURE: Neither reads nor writes state (no gas when called externally)
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b;
    }

    // PAYABLE: Can receive ETH
    function deposit() public payable {
        // msg.value available here
    }

    // (no modifier): Can modify state
    function setValue(uint256 _value) public {
        value = _value;  // State modification
    }
}
```

**Real-World Analogy**: State mutability is like library rules:
- **View**: You can read books but can't take them home (read-only access)
- **Pure**: You can use the calculator but can't access the library catalog (no state access)
- **Payable**: You can deposit money into your account (can receive ETH)
- **Regular**: You can check out books and modify your account (full access)

**Language Comparison**:

**TypeScript:**
```typescript
// No mutability keywords at language level
class Contract {
    value: number = 0;
    
    getValue(): number {
        return this.value;  // Can modify if not readonly
    }
    
    setValue(v: number): void {
        this.value = v;  // Modifies state
    }
}
```

**Go:**
```go
// No mutability keywords
type Contract struct {
    value uint256
}

func (c *Contract) GetValue() uint256 {
    return c.value  // Read-only in this function
}

func (c *Contract) SetValue(v uint256) {
    c.value = v  // Modifies state
}
```

**Rust:**
```rust
// Mutability is explicit
struct Contract {
    value: u256,
}

impl Contract {
    fn get_value(&self) -> u256 {
        self.value  // Immutable reference
    }
    
    fn set_value(&mut self, v: u256) {
        self.value = v  // Mutable reference required
    }
}
```

**Solidity:**
```solidity
// Explicit mutability modifiers affect gas costs
contract Example {
    uint256 public value;
    
    function getValue() public view returns (uint256) {
        // 'view' = reads state, no gas when called externally
        return value;
    }
    
    function calculate(uint256 a, uint256 b) public pure returns (uint256) {
        // 'pure' = no state access, no gas when called externally
        return a + b;
    }
    
    function setValue(uint256 v) public {
        // No modifier = can modify state, costs gas
        value = v;
    }
}
```

---

## Control Structures

```solidity
contract ControlFlow {
    // IF-ELSE
    function checkValue(uint256 x) public pure returns (string memory) {
        if (x > 100) {
            return "high";
        } else if (x > 50) {
            return "medium";
        } else {
            return "low";
        }
    }

    // FOR LOOP (? Gas warning: avoid unbounded loops)
    function sumArray(uint[] memory arr) public pure returns (uint) {
        uint sum = 0;
        for (uint i = 0; i < arr.length; i++) {
            sum += arr[i];
        }
        return sum;
    }

    // WHILE LOOP (? Same gas warning)
    function countdown(uint start) public pure returns (uint) {
        uint i = start;
        while (i > 0) {
            i--;
        }
        return i;
    }

    // TERNARY OPERATOR
    function max(uint a, uint b) public pure returns (uint) {
        return a > b ? a : b;
    }
}
```

**? Critical Warning**: Never iterate over unbounded arrays in storage. Can exceed block gas limit ? DoS.

---

## Events

```solidity
contract EventExample {
    // Define event (up to 3 indexed parameters for filtering)
    event Transfer(
        address indexed from,    // Indexed: can filter by this
        address indexed to,      // Indexed: can filter by this
        uint256 value            // Not indexed: cheaper, but can't filter
    );

    event Debug(string message, uint256 value);

    function transfer(address to, uint256 amount) public {
        // Emit event
        emit Transfer(msg.sender, to, amount);
    }
}
```

**Why Events?**
- ✅ Cheaper than storage (~2k gas vs ~20k gas)
- ✅ Enable off-chain indexing (The Graph, Etherscan)
- ✅ Frontend can listen for real-time updates
- ❌ Cannot be read by contracts

**Real-World Analogy**: Events are like receipts from a store - they prove what happened (transaction occurred), but you can't change them, and they're cheaper than storing the full transaction details. Like receipts, they're useful for record-keeping and auditing, but the store (contract) can't read its own receipts.

**Language Comparison**:

**TypeScript:**
```typescript
// Events are callbacks or event emitters
class Contract {
    onTransfer(callback: (from: string, to: string, amount: number) => void) {
        // Event listeners for real-time updates
    }
}
```

**Go:**
```go
// Events are channels or callbacks
type TransferEvent struct {
    From   string
    To     string
    Amount uint256
}

func (c *Contract) OnTransfer(ch chan TransferEvent) {
    // Send events through channel
}
```

**Rust:**
```rust
// Events are typically channels or callbacks
pub struct TransferEvent {
    pub from: String,
    pub to: String,
    pub amount: u256,
}

impl Contract {
    pub fn on_transfer<F: Fn(TransferEvent)>(&self, callback: F) {
        // Call callback when transfer occurs
    }
}
```

**Solidity:**
```solidity
// Events are logged to blockchain, indexed for filtering
event Transfer(address indexed from, address indexed to, uint256 amount);

function transfer(address to, uint256 amount) public {
    // Emit event (logged to blockchain)
    emit Transfer(msg.sender, to, amount);
    // Events are cheaper than storage and enable off-chain indexing
}
```

**Indexed vs Non-Indexed**:
- Indexed: ~375 gas extra per parameter, but filterable
- Non-Indexed: Cheaper, but requires scanning all logs

---

## Errors

### Traditional (Pre-0.8.4)

```solidity
// REQUIRE: Validate inputs, refund remaining gas
require(amount > 0, "Amount must be positive");

// REVERT: Conditional revert with custom logic
if (balance < amount) {
    revert("Insufficient balance");
}

// ASSERT: Check invariants, should never fail (no gas refund)
assert(totalSupply >= individualBalance);
```

### Custom Errors (0.8.4+, saves gas)

```solidity
// Define custom errors
error InsufficientBalance(uint256 available, uint256 required);
error Unauthorized(address caller);

contract Bank {
    mapping(address => uint256) public balances;

    function withdraw(uint256 amount) public {
        if (balances[msg.sender] < amount) {
            // Revert with custom error (saves ~2k gas vs require string)
            revert InsufficientBalance({
                available: balances[msg.sender],
                required: amount
            });
        }
        balances[msg.sender] -= amount;
    }
}
```

**Gas Savings**: Custom errors save ~2k gas compared to `require` strings.

---

## Modifiers

```solidity
contract ModifierExample {
    address public owner;
    bool private locked;

    constructor() {
        owner = msg.sender;
    }

    // Simple modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;  // Placeholder: run function body here
    }

    // Modifier with parameter
    modifier costs(uint256 price) {
        require(msg.value >= price, "Insufficient payment");
        _;
    }

    // Reentrancy guard modifier
    modifier nonReentrant() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }

    // Use modifiers
    function restrictedFunction() public onlyOwner {
        // Only owner can call
    }

    function buy() public payable costs(1 ether) nonReentrant {
        // Must send >= 1 ether, protected from reentrancy
    }
}
```

**Execution Order**:
```solidity
function example() public modifierA modifierB {
    // Runs: modifierA ? modifierB ? function body
}
```

---

## Inheritance

```solidity
// Base contract
contract Animal {
    function makeSound() public virtual returns (string memory) {
        return "Some sound";
    }
}

// Derived contract
contract Dog is Animal {
    // Override parent function
    function makeSound() public override returns (string memory) {
        return "Woof!";
    }
}

// Multiple inheritance
contract Labrador is Dog, Ownable {
    // Inherits from both
}
```

**Important**: Solidity uses C3 linearization for multiple inheritance order.

---

## Important Patterns

### Checks-Effects-Interactions (CEI)

**Prevents reentrancy attacks**:

```solidity
function withdraw(uint256 amount) public {
    // 1. CHECKS
    require(balances[msg.sender] >= amount, "Insufficient balance");

    // 2. EFFECTS (update state BEFORE external calls)
    balances[msg.sender] -= amount;

    // 3. INTERACTIONS (external calls last)
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed");
}
```

### Pull Over Push Payments

**Avoid DoS by letting users withdraw**:

```solidity
// ❌ BAD: Push payment
function payAll(address[] memory recipients) public {
    for (uint i = 0; i < recipients.length; i++) {
        recipients[i].call{value: 1 ether}("");  // Can fail, DoS entire function
    }
}

// ✅ GOOD: Pull payment
mapping(address => uint256) public pendingWithdrawals;

function withdraw() public {
    uint256 amount = pendingWithdrawals[msg.sender];
    pendingWithdrawals[msg.sender] = 0;
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success);
}
```

### Safe ETH Transfer

```solidity
// ✅ RECOMMENDED: call (forwards all gas, returns bool)
(bool success, ) = recipient.call{value: amount}("");
require(success, "Transfer failed");

// ? AVOID: transfer (2300 gas limit, reverts on failure)
payable(recipient).transfer(amount);  // Can break with smart contract wallets

// ? AVOID: send (2300 gas limit, returns bool)
bool success = payable(recipient).send(amount);
```

---

## Global Variables

```solidity
// Block information
block.timestamp;      // Current block timestamp (uint256)
block.number;         // Current block number (uint256)
block.difficulty;     // Deprecated, use block.prevrandao

// Transaction information
msg.sender;           // Caller address (address)
msg.value;            // ETH sent (uint256, in wei)
msg.data;             // Complete calldata (bytes)
msg.sig;              // First 4 bytes of calldata (bytes4)

// Contract information
address(this);        // This contract's address
address(this).balance;  // This contract's ETH balance
```

**? Security Warning**: Never use `tx.origin` for authentication (vulnerable to phishing).

---

## Common Units

```solidity
// Time
1 seconds == 1;
1 minutes == 60;
1 hours == 3600;
1 days == 86400;
1 weeks == 604800;

// Ether
1 wei == 1;
1 gwei == 1e9;        // 1,000,000,000 wei
1 ether == 1e18;      // 1,000,000,000,000,000,000 wei
```

---

## Gas Optimization Tips

1. **Use `uint256` instead of smaller types** (except in structs)
2. **Pack struct variables** to fit in 32-byte slots
3. **Use `calldata` for external function arrays**
4. **Cache storage variables** in memory for repeated access
5. **Use custom errors** instead of require strings
6. **Use `external` instead of `public` when possible**
7. **Avoid unbounded loops**
8. **Use events instead of storage when possible**

---

## Common Security Pitfalls

| Vulnerability | Description | Prevention |
|---------------|-------------|------------|
| Reentrancy | Attacker calls back before state updated | Use CEI pattern, ReentrancyGuard |
| Integer Overflow | Pre-0.8.0: uint256 + 1 could wrap to 0 | Use Solidity ^0.8.0 (auto-checks) |
| Unchecked Call | Low-level call fails silently | Always check return value |
| tx.origin Auth | Phishing via intermediate contract | Use msg.sender instead |
| Timestamp Manipulation | Miners can manipulate ~15 seconds | Don't rely on exact timestamps |
| DoS via Revert | Loop can fail if one recipient reverts | Use pull over push |

---

## Next Steps

- Start with [Project 01: Datatypes & Storage](./01-datatypes-and-storage/)
- Keep this guide handy as a reference
- Experiment in [Remix IDE](https://remix.ethereum.org/)

**Remember**: Solidity is not like other languages. Every line costs gas. Every bug can cost real money. Code carefully.

---

## Additional Concepts

### Struct Packing

**Real-World Analogy**: Struct packing is like organizing items in a moving truck - you want to fit as many items as possible in each box (32-byte storage slot) to minimize the number of boxes (gas costs).

```solidity
// ❌ BAD: Wastes storage slots
struct BadPacking {
    uint256 a;  // Slot 0 (32 bytes)
    uint8 b;    // Slot 1 (1 byte, wastes 31 bytes!)
    uint256 c;  // Slot 2 (32 bytes)
}
// Total: 3 slots = ~60k gas for first write

// ✅ GOOD: Packs efficiently
struct GoodPacking {
    uint256 a;  // Slot 0 (32 bytes)
    uint256 c;  // Slot 1 (32 bytes)
    uint8 b;    // Slot 1 (packs with 'c', uses 1 byte)
}
// Total: 2 slots = ~40k gas for first write
// Saves ~20k gas!
```

**Language Comparison**:

**TypeScript:**
```typescript
// No packing concerns - memory layout managed automatically
interface User {
    id: number;      // 8 bytes
    name: string;    // Variable size
    active: boolean; // 1 byte
}
// Memory layout optimized by JavaScript engine
```

**Go:**
```go
// Struct fields are aligned, but no explicit packing
type User struct {
    ID     uint256  // 32 bytes
    Name   string   // Variable size
    Active bool     // 1 byte
}
// Go compiler handles alignment automatically
```

**Rust:**
```rust
// Can use #[repr(packed)] for explicit packing
#[repr(packed)]
struct User {
    id: u256,      // 32 bytes
    name: String,  // Variable size
    active: bool,  // 1 byte
}
// Packing can improve cache performance
```

**Solidity:**
```solidity
// Must manually pack structs for gas savings
struct User {
    uint256 id;     // 32 bytes
    uint8 active;   // 1 byte - packs with next field if possible
    uint256 balance; // 32 bytes
}
// Order matters! Pack small types together
```

### Mappings Deep Dive

**Real-World Analogy**: Mappings are like a phone book - you look up a name (key) to find a number (value). If someone isn't in the book, you get 0 (not "undefined" or "null"). The phone book is permanent storage - expensive to write entries, but fast to look up.

```solidity
mapping(address => uint256) public balances;

// Reading a mapping
uint256 balance = balances[userAddress];
// If userAddress was never set, returns 0 (not undefined!)

// Writing to a mapping
balances[userAddress] = 100;
// Costs ~20k gas (cold write) or ~5k gas (warm write)
```

**Language Comparison**:

**TypeScript:**
```typescript
// Maps or objects
let balances: Map<string, number> = new Map();
balances.set("0x123", 100);
let balance = balances.get("0x123");  // Returns number | undefined
```

**Go:**
```go
// Maps
balances := make(map[string]uint256)
balances["0x123"] = 100
balance, exists := balances["0x123"]  // Returns value and existence bool
```

**Rust:**
```rust
// HashMap
use std::collections::HashMap;
let mut balances: HashMap<String, u256> = HashMap::new();
balances.insert("0x123".to_string(), 100);
let balance = balances.get("0x123");  // Returns Option<u256>
```

**Solidity:**
```solidity
// Mappings - always return a value (0 if not set)
mapping(address => uint256) public balances;
balances[0x123] = 100;
uint256 balance = balances[0x123];  // Returns 0 if never set (no Option/undefined!)
```

### Gas Optimization Deep Dive

**Real-World Analogy**: Gas optimization is like optimizing fuel efficiency in a car - every decision (route, speed, weight) affects how much fuel (gas) you use. In Solidity, every operation costs gas, so optimization is critical.

**Key Optimization Strategies**:

1. **Use `uint256` for local variables** (EVM optimized)
2. **Pack structs** (fewer storage slots)
3. **Use `calldata` for external arrays** (cheaper than memory)
4. **Cache storage reads** (SLOAD costs 2,100 gas cold, 100 gas warm)
5. **Use custom errors** (saves ~2k gas vs require strings)
6. **Use `external` instead of `public`** (saves ~200 gas)
7. **Avoid unbounded loops** (can exceed gas limit)
8. **Use events instead of storage** (when possible)

**Language Comparison**:

**TypeScript/Go/Rust**: Performance optimization focuses on CPU time, memory usage, and algorithmic complexity. Gas optimization doesn't exist.

**Solidity**: Every operation has a gas cost. Optimization means minimizing gas usage, not execution time. A function that runs slowly but uses less gas is better than a fast function that uses more gas.

---

## Summary

Solidity is unique among programming languages because:
1. **Every operation costs gas** - unlike other languages where computation is "free"
2. **Immutable deployment** - code can't be changed after deployment
3. **Explicit memory management** - must specify storage locations
4. **No null/undefined** - everything has a default value (usually 0)
5. **Atomic transactions** - all or nothing execution
6. **Sequential execution** - no true concurrency, but transactions are atomic

Understanding these differences will help you write better Solidity code and avoid common pitfalls!

---

# Part 2: Language Comparisons

# Comparative Language Guide: Solidity vs TypeScript, Go, and Rust

## Table of Contents
1. [Introduction](#introduction)
2. [Type Systems](#type-systems)
3. [Error Handling Patterns](#error-handling-patterns)
4. [Memory Management](#memory-management)
5. [Function Calling Conventions](#function-calling-conventions)
6. [Inheritance and Composition](#inheritance-and-composition)
7. [Async/Concurrent Programming](#asyncconcurrent-programming)
8. [Testing Frameworks](#testing-frameworks)
9. [Package Management](#package-management)
10. [Security Considerations](#security-considerations)
11. [Performance Characteristics](#performance-characteristics)

## Introduction

Solidity is a unique language designed specifically for writing smart contracts on blockchain platforms like Ethereum. While it borrows syntax from popular languages like TypeScript, its execution model, constraints, and security considerations are fundamentally different. This guide helps developers transitioning from TypeScript, Go, or Rust understand these differences.

### Key Differences at a Glance

| Aspect | Solidity | TypeScript | Rust | Go |
|--------|----------|------------|------|-----|
| **Type System** | Static, Strong, Fixed-size | Static, Strong, Inferred | Static, Strong | Static, Strong |
| **Compilation** | Bytecode/EVM | Transpiled to JS | LLVM Compiled | Native Compiled |
| **Paradigm** | Object-Oriented | Multi-paradigm | Systems Programming | Simple Systems |
| **Immutability** | Enforced for state | Optional (const/readonly) | Enforced | Enforced |
| **Gas Costs** | Yes (unique) | No | No | No |
| **Concurrency** | None | Async/Await | Fearless Concurrency | Goroutines |
| **Memory Model** | Persistent Storage | Automatic GC | Manual+Borrow Checker | Automatic GC |

---

## 1. Type Systems

Solidity has a strong static type system with Ethereum-specific types. Understanding the differences helps prevent runtime errors.

### Integer Types

**Solidity**
```solidity
// Solidity has fixed-size integers
uint8 public counter = 0;           // 0 to 255
uint16 public temperature = 20;     // 0 to 65,535
uint256 public balance = 1000;      // 0 to 2^256-1 (default uint)
int8 public temperature = -5;       // -128 to 127
int256 public balance = -1000;

// Fixed-size integers - overflow/underflow is critical concern
// Solidity 0.8+ automatically checks for overflow
```

**Python**
```python
# Python has arbitrary precision integers
counter: int = 0               # No size limits
balance: int = 1000           # Can be any size
temperature: int = -5         # Automatic type conversion

# Type hints are optional and not enforced at runtime
balance = balance + 1          # Works fine
balance = "string"             # No compile-time error!
```

**Rust**
```rust
// Rust has fixed-size integers similar to Solidity
let counter: u8 = 0;           // 0 to 255
let temperature: i16 = 20;     // -32,768 to 32,767
let balance: u256 = 1000;      // Would need library for 256-bit

// Rust panics on overflow in debug mode, wraps in release
let result = counter.checked_add(1);  // Returns Option<u8>
```

**Go**
```go
// Go has fixed-size integers
var counter uint8 = 0
var temperature int16 = 20
var balance uint64 = 1000

// Overflow is silently wrapped
counter := uint8(255)
counter++  // Wraps to 0

// Big integers available
var balance big.Int
balance.SetString("1000", 10)
```

**TypeScript**
```typescript
// TypeScript has strong typing with number type
let counter: number = 0;              // 64-bit floating point
let temperature: number = 20;
let balance: number = 1000;

// BigInt for arbitrary precision
let balance: bigint = 1000n;          // BigInt literal
let counter: bigint = BigInt(256);

// Compile-time type checking
balance = "string";           // TypeScript error: Type 'string' is not assignable to type 'number'
```

### Boolean and Address Types

**Solidity**
```solidity
// Boolean type
bool public isActive = true;

// Ethereum-specific address type (20 bytes)
address public owner = 0x742d35Cc6634C0532925a3b844Bc9e7595f42bE;
address payable public recipient;  // Can receive Ether

// No equivalent in other languages
// Address is fundamental to blockchain
```

**Python**
```python
is_active: bool = True         # Standard Python boolean

# Address simulation (not native)
owner: str = "0x742d35Cc6634C0532925a3b844Bc9e7595f42bE"
# or use web3.py
from web3 import Web3
owner = Web3.toChecksumAddress("0x742d35Cc6634C0532925a3b844Bc9e7595f42bE")
```

**Rust**
```rust
let is_active: bool = true;    // Standard Rust boolean

// Address simulation
let owner: [u8; 20] = [0x74, 0x2d, ...];  // 20-byte array
// Or use ethers-rs library
```

**Go**
```go
isActive := true

// Address simulation
type Address [20]byte
owner := Address{0x74, 0x2d, ...}
```

**TypeScript**
```typescript
const isActive: boolean = true;

// Address as string
const owner: string = "0x742d35Cc6634C0532925a3b844Bc9e7595f42bE";

// With ethers.js library
import { ethers } from "ethers";
const owner: string = ethers.getAddress("0x742d35...");
```

### Complex Types

**Solidity**
```solidity
// Arrays
uint[] public numbers;           // Dynamic array
uint[3] public fixed_nums;       // Fixed-size array

// Mappings (hash tables)
mapping(address => uint) public balances;
mapping(address => mapping(uint => bool)) public nested;

// Structs
struct User {
    string name;
    uint256 balance;
    bool active;
}

// Enums
enum Status { Pending, Active, Completed }
```

**Python**
```python
# Lists (dynamic)
numbers: list[int] = []

# Dictionaries (mappings)
balances: dict[str, int] = {}
nested: dict[str, dict[int, bool]] = {}

# Dataclasses (structs)
from dataclasses import dataclass

@dataclass
class User:
    name: str
    balance: int
    active: bool

# Enums
from enum import Enum
class Status(Enum):
    PENDING = 1
    ACTIVE = 2
    COMPLETED = 3
```

**Rust**
```rust
// Vectors (dynamic)
let numbers: Vec<u256> = Vec::new();

// HashMaps (mappings)
use std::collections::HashMap;
let balances: HashMap<Address, u256> = HashMap::new();

// Structs
struct User {
    name: String,
    balance: u256,
    active: bool,
}

// Enums
enum Status {
    Pending,
    Active,
    Completed,
}
```

**Go**
```go
// Slices (dynamic)
var numbers []uint

// Maps
balances := make(map[string]uint)
nested := make(map[string]map[uint]bool)

// Structs
type User struct {
    Name    string
    Balance uint256
    Active  bool
}

// Enums (via iota)
const (
    PENDING = iota
    ACTIVE
    COMPLETED
)
```

**TypeScript**
```typescript
// Arrays
let numbers: number[] = [];

// Objects (mappings)
const balances: Record<string, number> = {};
const nested: Record<string, Record<number, boolean>> = {};

// Classes (like structs)
class User {
    name: string;
    balance: number;
    active: boolean;

    constructor(name: string, balance: number, active: boolean) {
        this.name = name;
        this.balance = balance;
        this.active = active;
    }
}

// Enums
enum Status {
    PENDING = 1,
    ACTIVE = 2,
    COMPLETED = 3,
}
```

---

## 2. Error Handling Patterns

Error handling in Solidity is fundamentally different due to the immutable nature of blockchain transactions.

### Basic Error Handling

**Solidity**
```solidity
// Solidity uses require/revert/assert
function withdraw(uint amount) public {
    // require: Check conditions, revert if false
    require(amount <= balances[msg.sender], "Insufficient balance");
    require(amount > 0, "Amount must be positive");

    // Custom errors (more gas efficient in 0.8.4+)
    if (amount > MAX_WITHDRAWAL) {
        revert ExcessiveWithdrawal(amount);
    }

    // assert: Check invariants (consumes all gas)
    assert(totalSupply >= amount);

    balances[msg.sender] -= amount;
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed");
}

error ExcessiveWithdrawal(uint amount);
```

**Python**
```python
def withdraw(self, amount):
    # Use exceptions
    if amount <= 0:
        raise ValueError("Amount must be positive")

    if amount > self.balances.get(self.user, 0):
        raise InsufficientFundsError("Insufficient balance")

    if amount > MAX_WITHDRAWAL:
        raise ValueError("Excessive withdrawal")

    self.balances[self.user] -= amount
    # Transfer happens here with try/except
    try:
        transfer_funds(amount)
    except TransferError as e:
        raise RuntimeError(f"Transfer failed: {e}")

class InsufficientFundsError(Exception):
    pass
```

**Rust**
```rust
fn withdraw(&mut self, amount: u256) -> Result<(), WithdrawalError> {
    // Rust uses Result enum
    if amount <= 0 {
        return Err(WithdrawalError::InvalidAmount);
    }

    let balance = self.balances.get(&self.user)
        .ok_or(WithdrawalError::NoAccount)?;

    if amount > *balance {
        return Err(WithdrawalError::InsufficientBalance);
    }

    if amount > MAX_WITHDRAWAL {
        return Err(WithdrawalError::ExcessiveAmount);
    }

    self.balances.entry(self.user).and_modify(|b| *b -= amount);
    transfer_funds(amount)?;  // ? operator for error propagation
    Ok(())
}

#[derive(Debug)]
enum WithdrawalError {
    InvalidAmount,
    InsufficientBalance,
    ExcessiveAmount,
    TransferFailed,
}
```

**Go**
```go
func (c *Contract) Withdraw(amount uint256) error {
    // Go uses error returns
    if amount <= 0 {
        return errors.New("amount must be positive")
    }

    balance, exists := c.balances[c.user]
    if !exists {
        return errors.New("no account")
    }

    if amount > balance {
        return fmt.Errorf("insufficient balance: have %d, need %d",
            balance, amount)
    }

    if amount > MAX_WITHDRAWAL {
        return WithdrawalError{amount}
    }

    c.balances[c.user] -= amount
    if err := transferFunds(amount); err != nil {
        return fmt.Errorf("transfer failed: %w", err)
    }
    return nil
}

type WithdrawalError struct {
    Amount uint256
}

func (e WithdrawalError) Error() string {
    return fmt.Sprintf("excessive withdrawal: %d", e.Amount)
}
```

**TypeScript**
```typescript
async withdraw(amount: number): Promise<void> {
    // TypeScript uses exceptions and try/catch
    if (amount <= 0) {
        throw new Error("Amount must be positive");
    }

    const balance: number = this.balances[this.user] || 0;
    if (amount > balance) {
        throw new InsufficientFundsError("Insufficient balance");
    }

    if (amount > MAX_WITHDRAWAL) {
        throw new Error("Excessive withdrawal");
    }

    try {
        this.balances[this.user] -= amount;
        await transferFunds(amount);
    } catch (error) {
        throw new Error(`Transfer failed: ${(error as Error).message}`);
    }
}

class InsufficientFundsError extends Error {
    constructor(message: string) {
        super(message);
        this.name = "InsufficientFundsError";
    }
}
```

### Key Differences

| Aspect | Solidity | Others |
|--------|----------|--------|
| **Mechanism** | Revert/require | Exceptions/Results |
| **State on Error** | Entire transaction rolled back | Manual rollback or partial execution |
| **Recovery** | Try-catch available (0.6+) | Full exception handling |
| **Gas Cost** | Wasted on failed transaction | No cost |
| **Partial Success** | Not possible | Possible with careful coding |

---

## 3. Memory Management

Solidity's memory model is radically different from traditional languages due to blockchain constraints.

### Storage vs Memory

**Solidity**
```solidity
contract MemoryDemo {
    // State variables go to STORAGE (persistent, expensive)
    uint256 public count = 0;
    mapping(address => uint) public balances;

    function processData() public {
        // Local variables go to MEMORY (temporary, cheaper)
        uint256[] memory tempArray = new uint256[](10);
        string memory tempString = "temporary";

        // Data location is explicit
        // Arrays in function parameters default to calldata
        processArray(tempArray);

        // Calldata (read-only, inputs)
        // Most gas-efficient
    }

    function processArray(uint256[] memory arr) internal {
        arr[0] = 100;  // Changes local copy only
    }

    // Reference semantics
    function updateStruct(DataStruct storage data) internal {
        data.value = 100;  // Modifies storage directly
    }
}
```

**Python**
```python
class MemoryDemo:
    def __init__(self):
        # Instance variables (heap)
        self.count = 0
        self.balances = {}

    def process_data(self):
        # Local variables (stack)
        temp_array = [0] * 10
        temp_string = "temporary"

        self.process_array(temp_array)

        # Python passes references, modifications affect original
        # Automatic garbage collection

    def process_array(self, arr):
        arr[0] = 100  # Modifies the list

    def update_dict(self, data):
        data["value"] = 100  # Modifies the dict
```

**Rust**
```rust
struct MemoryDemo {
    count: u256,
    balances: HashMap<Address, u256>,
}

impl MemoryDemo {
    fn process_data(&mut self) {
        // Stack allocation
        let temp_array: Vec<u256> = vec![0; 10];
        let temp_string: String = "temporary".to_string();

        self.process_array(temp_array);

        // Ownership system prevents dangling pointers
        // No garbage collection
    }

    fn process_array(&mut self, mut arr: Vec<u256>) {
        arr[0] = 100;  // Owns the vector
    }

    fn update_struct(&mut self, data: &mut SomeStruct) {
        data.value = 100;  // Mutable borrow
    }
}
```

**Go**
```go
type MemoryDemo struct {
    count    uint256
    balances map[string]uint256
}

func (m *MemoryDemo) ProcessData() {
    // Stack allocation
    tempArray := make([]uint256, 10)
    tempString := "temporary"

    m.processArray(tempArray)

    // Go has automatic garbage collection
    // Pointers are explicit
}

func (m *MemoryDemo) processArray(arr []uint256) {
    arr[0] = 100  // Modifies the slice
}

func (m *MemoryDemo) updateStruct(data *SomeStruct) {
    data.Value = 100  // Pointer dereference
}
```

**TypeScript**
```typescript
class MemoryDemo {
    count: number;
    balances: Record<string, number>;

    constructor() {
        this.count = 0;
        this.balances = {};
    }

    processData(): void {
        // Variables on heap (TypeScript stack mostly holds references)
        const tempArray: number[] = new Array(10).fill(0);
        const tempString: string = "temporary";

        this.processArray(tempArray);

        // Automatic garbage collection
        // Everything is reference unless primitive
    }

    processArray(arr: number[]): void {
        arr[0] = 100;  // Modifies the array
    }

    updateStruct(data: { value: number }): void {
        data.value = 100;  // Modifies the object
    }
}
```

### Heap/Stack Behavior

| Language | Stack | Heap | GC | Special Features |
|----------|-------|------|-----|-----------------|
| **Solidity** | MEMORY (temporary) | STORAGE (persistent) | None | Gas costs differ |
| **Python** | Primitives | Objects | Yes | Everything is object |
| **Rust** | Values (owned) | Heap | No | Borrow checker |
| **Go** | Values | Heap | Yes | Escape analysis |
| **TypeScript** | Primitives | Objects | Yes | Hidden class optimization |

---

## 4. Function Calling Conventions

How functions are called and how they interact with state varies significantly.

### Basic Function Definition and Calling

**Solidity**
```solidity
contract FunctionDemo {
    uint public count = 0;

    // Public: anyone can call via transaction
    function increment() public {
        count++;
    }

    // External: only from outside contract
    function externalIncrement() external {
        count++;
    }

    // Internal: only from within contract
    function _internalIncrement() internal {
        count++;
    }

    // Private: only from this contract
    function _privateIncrement() private {
        count++;
    }

    // View: read-only, no gas cost
    function getCount() public view returns (uint) {
        return count;
    }

    // Pure: doesn't access state
    function add(uint a, uint b) public pure returns (uint) {
        return a + b;
    }

    // Payable: can receive Ether
    function deposit() public payable {
        // msg.value contains Ether sent
    }
}
```

**Python**
```python
class FunctionDemo:
    def __init__(self):
        self.count = 0

    # Public method
    def increment(self):
        self.count += 1

    # "Private" method (convention with underscore)
    def _internal_increment(self):
        self.count += 1

    # Read-only method
    @property
    def count_value(self):
        return self.count

    # Static method
    @staticmethod
    def add(a, b):
        return a + b

    # Class method
    @classmethod
    def create(cls):
        return cls()

    # Special method (constructor)
    def __init__(self):
        pass

    # Decorator for visibility control
    def __private_method(self):
        pass
```

**Rust**
```rust
pub struct FunctionDemo {
    count: u256,
}

impl FunctionDemo {
    // Public method
    pub fn increment(&mut self) {
        self.count += 1;
    }

    // Private method
    fn _internal_increment(&mut self) {
        self.count += 1;
    }

    // Borrows immutably (read-only)
    pub fn get_count(&self) -> u256 {
        self.count
    }

    // Pure function
    pub fn add(a: u256, b: u256) -> u256 {
        a + b
    }

    // Constructor function
    pub fn new() -> Self {
        FunctionDemo { count: 0 }
    }

    // Takes ownership
    pub fn consume(self) -> u256 {
        self.count
    }
}
```

**Go**
```go
type FunctionDemo struct {
    count uint256
}

func (f *FunctionDemo) Increment() {
    f.count++
}

func (f *FunctionDemo) internalIncrement() {
    f.count++
}

func (f *FunctionDemo) GetCount() uint256 {
    return f.count
}

func Add(a, b uint256) uint256 {
    return a + b
}

func NewFunctionDemo() *FunctionDemo {
    return &FunctionDemo{count: 0}
}
```

**TypeScript**
```typescript
class FunctionDemo {
    private count: number = 0;

    constructor() {
        this.count = 0;
    }

    // Public method
    increment(): void {
        this.count++;
    }

    // Private method
    private internalIncrement(): void {
        this.count++;
    }

    // Getter
    get countValue(): number {
        return this.count;
    }

    // Static method
    static add(a: number, b: number): number {
        return a + b;
    }

    // Async function
    async fetchData(): Promise<Response> {
        return await fetch('/data');
    }
}
```

### Function Modifiers and Decorators

**Solidity**
```solidity
contract ModifierDemo {
    address public owner;
    bool locked;

    // Modifier: reusable function logic
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;  // Continue execution
    }

    modifier reentrancyGuard() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }

    function withdraw() public onlyOwner reentrancyGuard {
        // Protected by modifiers
    }

    // Multiple modifiers
    function criticalOperation()
        public
        onlyOwner
        reentrancyGuard
    {
        // Doubly protected
    }
}
```

**Python**
```python
from functools import wraps

def only_owner(func):
    @wraps(func)
    def wrapper(self, *args, **kwargs):
        if self.caller != self.owner:
            raise PermissionError("Only owner")
        return func(self, *args, **kwargs)
    return wrapper

def reentrancy_guard(func):
    @wraps(func)
    def wrapper(self, *args, **kwargs):
        if self.locked:
            raise RuntimeError("Reentrancy detected")
        self.locked = True
        try:
            return func(self, *args, **kwargs)
        finally:
            self.locked = False
    return wrapper

class ModifierDemo:
    @only_owner
    @reentrancy_guard
    def withdraw(self):
        pass
```

**Rust**
```rust
trait OnlyOwner {
    fn require_owner(&self);
}

trait ReentrancyGuard {
    fn with_guard<F>(&mut self, f: F)
    where
        F: FnOnce(&mut Self);
}
```

**Go**
```go
func (m *ModifierDemo) Withdraw() error {
    if err := m.requireOwner(); err != nil {
        return err
    }
    if err := m.withReentrancyGuard(func() error {
        // Implementation
        return nil
    }); err != nil {
        return err
    }
    return nil
}

func (m *ModifierDemo) requireOwner() error {
    if m.caller != m.owner {
        return errors.New("only owner")
    }
    return nil
}
```

**TypeScript**
```typescript
class ModifierDemo {
    private caller: string;
    private owner: string;

    async withdraw(): Promise<void> {
        try {
            await this.requireOwner();
            await this.withReentrancyGuard(async () => {
                // Implementation
            });
        } catch (error) {
            throw error;
        }
    }

    private async requireOwner(): Promise<void> {
        if (this.caller !== this.owner) {
            throw new Error("Only owner");
        }
    }

    private async withReentrancyGuard(fn: () => Promise<void>): Promise<void> {
        // Implementation
        await fn();
    }
}
```

---

## 5. Inheritance and Composition

Solidity supports inheritance, but with unique constraints compared to other languages.

### Basic Inheritance

**Solidity**
```solidity
// Parent contract
contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
    }
}

// Child contract
contract Token is Ownable {
    string public name = "MyToken";
    uint public totalSupply;

    function burn() public onlyOwner {
        // Inherits onlyOwner modifier
    }
}

// Multiple inheritance
contract Pausable {
    bool public paused;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }
}

contract CompleteToken is Token, Pausable {
    function transfer() public whenNotPaused {
        // Combines both parent requirements
    }
}
```

**Python**
```python
class Ownable:
    def __init__(self):
        self.owner = None

    def require_owner(self):
        if self.caller != self.owner:
            raise PermissionError("Only owner")

    def renounce_ownership(self):
        self.require_owner()
        self.owner = None

class Token(Ownable):
    def __init__(self):
        super().__init__()
        self.name = "MyToken"
        self.total_supply = 0

    def burn(self):
        self.require_owner()

class Pausable:
    def __init__(self):
        self.paused = False

    def require_not_paused(self):
        if self.paused:
            raise RuntimeError("Contract is paused")

class CompleteToken(Token, Pausable):
    def __init__(self):
        Token.__init__(self)
        Pausable.__init__(self)

    def transfer(self):
        self.require_not_paused()
```

**Rust**
```rust
trait Ownable {
    fn owner(&self) -> Address;
    fn set_owner(&mut self, owner: Address);
    fn require_owner(&self) -> Result<(), Error>;
}

struct Token {
    owner: Address,
    name: String,
    total_supply: u256,
}

impl Ownable for Token {
    fn owner(&self) -> Address {
        self.owner
    }

    fn set_owner(&mut self, owner: Address) {
        self.owner = owner;
    }

    fn require_owner(&self) -> Result<(), Error> {
        // Check logic
        Ok(())
    }
}

impl Token {
    fn burn(&mut self) -> Result<(), Error> {
        self.require_owner()?;
        Ok(())
    }
}

trait Pausable {
    fn is_paused(&self) -> bool;
    fn pause(&mut self);
    fn unpause(&mut self);
}

// Composition over inheritance
struct CompleteToken {
    token: Token,
    paused: bool,
}
```

**Go**
```go
type Ownable struct {
    owner string
}

func (o *Ownable) RequireOwner() error {
    if o.owner != currentCaller {
        return errors.New("only owner")
    }
    return nil
}

type Token struct {
    Ownable  // Embedded struct (composition)
    name     string
    totalSupply uint256
}

func (t *Token) Burn() error {
    return t.RequireOwner()
}

type Pausable struct {
    paused bool
}

func (p *Pausable) RequireNotPaused() error {
    if p.paused {
        return errors.New("paused")
    }
    return nil
}

type CompleteToken struct {
    Token
    Pausable
}
```

**TypeScript**
```typescript
class Ownable {
    protected owner: string | null;
    protected caller: string;

    constructor() {
        this.owner = null;
        this.caller = "";
    }

    requireOwner(): void {
        if (this.caller !== this.owner) {
            throw new Error("Only owner");
        }
    }

    renounceOwnership(): void {
        this.requireOwner();
        this.owner = null;
    }
}

class Token extends Ownable {
    name: string;
    totalSupply: number;

    constructor() {
        super();
        this.name = "MyToken";
        this.totalSupply = 0;
    }

    burn(): void {
        this.requireOwner();
    }
}

class Pausable {
    private paused: boolean;

    constructor() {
        this.paused = false;
    }

    requireNotPaused(): void {
        if (this.paused) {
            throw new Error("Paused");
        }
    }
}

class CompleteToken extends Token {
    private pausable: Pausable;

    constructor() {
        super();
        this.pausable = new Pausable();
    }

    transfer(): void {
        this.pausable.requireNotPaused();
    }
}
```

### Interface/Abstract Patterns

**Solidity**
```solidity
// Interface
interface IERC20 {
    function transfer(address to, uint amount) external returns (bool);
    function balanceOf(address account) external view returns (uint);
}

// Abstract contract
abstract contract ERC20 is IERC20 {
    mapping(address => uint) public balanceOf;

    function transfer(address to, uint amount)
        external
        override
        returns (bool)
    {
        // Implementation
        return true;
    }

    // Pure abstract function
    function mint(address to, uint amount) external virtual;
}

// Concrete implementation
contract MyToken is ERC20 {
    function mint(address to, uint amount) external override {
        balanceOf[to] += amount;
    }
}
```

**Python**
```python
from abc import ABC, abstractmethod

class IERC20(ABC):
    @abstractmethod
    def transfer(self, to: str, amount: int) -> bool:
        pass

    @abstractmethod
    def balance_of(self, account: str) -> int:
        pass

class ERC20(IERC20):
    def __init__(self):
        self.balance_of_map = {}

    def transfer(self, to: str, amount: int) -> bool:
        # Implementation
        return True

    @abstractmethod
    def mint(self, to: str, amount: int):
        pass

class MyToken(ERC20):
    def mint(self, to: str, amount: int):
        self.balance_of_map[to] = self.balance_of_map.get(to, 0) + amount
```

**Rust**
```rust
pub trait IERC20 {
    fn transfer(&mut self, to: Address, amount: u256) -> bool;
    fn balance_of(&self, account: Address) -> u256;
}

pub trait ERC20: IERC20 {
    fn mint(&mut self, to: Address, amount: u256);
}

pub struct MyToken {
    balances: HashMap<Address, u256>,
}

impl IERC20 for MyToken {
    fn transfer(&mut self, to: Address, amount: u256) -> bool {
        true
    }

    fn balance_of(&self, account: Address) -> u256 {
        self.balances.get(&account).copied().unwrap_or(0)
    }
}

impl ERC20 for MyToken {
    fn mint(&mut self, to: Address, amount: u256) {
        self.balances.entry(to).and_modify(|b| *b += amount);
    }
}
```

**Go**
```go
type IERC20 interface {
    Transfer(to string, amount uint256) bool
    BalanceOf(account string) uint256
}

type ERC20 struct {
    balances map[string]uint256
}

func (e *ERC20) Transfer(to string, amount uint256) bool {
    return true
}

func (e *ERC20) BalanceOf(account string) uint256 {
    return e.balances[account]
}

func (e *ERC20) Mint(to string, amount uint256) {
    e.balances[to] += amount
}

type MyToken struct {
    ERC20
}
```

**TypeScript**
```typescript
abstract class IERC20 {
    abstract transfer(to: string, amount: number): boolean;
    abstract balanceOf(account: string): number;
}

class ERC20 extends IERC20 {
    protected balances: Record<string, number>;

    constructor() {
        super();
        this.balances = {};
    }

    transfer(to: string, amount: number): boolean {
        return true;
    }

    balanceOf(account: string): number {
        return this.balances[account] || 0;
    }
}

class MyToken extends ERC20 {
    mint(to: string, amount: number): void {
        this.balances[to] = (this.balances[to] || 0) + amount;
    }
}
```

---

## 6. Async/Concurrent Programming

This is one of the biggest differences between Solidity and other languages.

### Solidity: No Async

**Solidity - Synchronous Only**
```solidity
contract SyncDemo {
    uint public result = 0;

    // All operations are synchronous and atomic
    // No threading, no async/await
    function calculate() public {
        result = 0;
        for (uint i = 0; i < 1000; i++) {
            result += i;
        }
        // Must complete in one transaction
    }

    // External calls stop execution until they return
    function callOtherContract(address target) public {
        // Direct call - must complete
        OtherContract(target).doSomething();

        // Execution waits
    }

    // To handle external calls:
    // 1. Pattern: Callback (contract calls you back)
    // 2. Pattern: Two-step transaction
    function step1() public {
        // Prepare
    }

    function step2() public {
        // Complete after external action
    }
}
```

**Python - Async Example**
```python
import asyncio

class AsyncDemo:
    async def calculate(self):
        # Can pause execution
        result = 0
        for i in range(1000):
            if i % 100 == 0:
                await asyncio.sleep(0)  # Yield control
            result += i
        return result

    async def call_other_service(self, url):
        # Non-blocking network call
        async with aiohttp.ClientSession() as session:
            async with session.get(url) as response:
                return await response.json()

    async def concurrent_operations(self):
        # Run multiple operations concurrently
        results = await asyncio.gather(
            self.calculate(),
            self.call_other_service("http://api1.com"),
            self.call_other_service("http://api2.com"),
        )
        return results

# Run async code
asyncio.run(demo.concurrent_operations())
```

**Rust - Async Example**
```rust
use tokio::task;

struct AsyncDemo;

impl AsyncDemo {
    async fn calculate(&self) -> u256 {
        let mut result = 0;
        for i in 0..1000 {
            if i % 100 == 0 {
                // Yield to other tasks
                task::yield_now().await;
            }
            result += i;
        }
        result
    }

    async fn call_other_service(&self, url: &str) -> Result<String, Error> {
        // Non-blocking network call
        let response = reqwest::get(url).await?;
        Ok(response.text().await?)
    }

    async fn concurrent_operations(&self) -> Result<Vec<String>, Error> {
        // Run multiple operations concurrently
        let (r1, r2, r3) = tokio::join!(
            self.calculate(),
            self.call_other_service("http://api1.com"),
            self.call_other_service("http://api2.com"),
        );
        Ok(vec![])
    }
}

#[tokio::main]
async fn main() {
    let demo = AsyncDemo;
    demo.concurrent_operations().await;
}
```

**Go - Goroutines Example**
```go
func (d *AsyncDemo) Calculate(ctx context.Context) int {
    result := 0
    for i := 0; i < 1000; i++ {
        select {
        case <-ctx.Done():
            return result
        default:
            result += i
        }
    }
    return result
}

func (d *AsyncDemo) CallOtherService(ctx context.Context, url string) (string, error) {
    req, _ := http.NewRequestWithContext(ctx, "GET", url, nil)
    resp, err := http.DefaultClient.Do(req)
    if err != nil {
        return "", err
    }
    defer resp.Body.Close()
    body, _ := io.ReadAll(resp.Body)
    return string(body), nil
}

func (d *AsyncDemo) ConcurrentOperations(ctx context.Context) {
    // Goroutines with channels
    results := make(chan string, 3)

    go func() {
        r := d.Calculate(ctx)
        results <- fmt.Sprintf("%d", r)
    }()

    go func() {
        r, _ := d.CallOtherService(ctx, "http://api1.com")
        results <- r
    }()

    go func() {
        r, _ := d.CallOtherService(ctx, "http://api2.com")
        results <- r
    }()

    for i := 0; i < 3; i++ {
        <-results
    }
}
```

**TypeScript - Promise/Async Example**
```typescript
class AsyncDemo {
    async calculate(): Promise<number> {
        let result: number = 0;
        for (let i = 0; i < 1000; i++) {
            if (i % 100 === 0) {
                // Yield control
                await new Promise<void>(resolve => setTimeout(resolve, 0));
            }
            result += i;
        }
        return result;
    }

    async callOtherService(url: string): Promise<any> {
        const response: Response = await fetch(url);
        return await response.json();
    }

    async concurrentOperations(): Promise<[number, any, any]> {
        // Run multiple operations concurrently
        const [r1, r2, r3] = await Promise.all([
            this.calculate(),
            this.callOtherService("http://api1.com"),
            this.callOtherService("http://api2.com"),
        ]);
        return [r1, r2, r3];
    }
}

const demo = new AsyncDemo();
demo.concurrentOperations();
```

### Pattern: Handling External Dependencies in Solidity

**Solidity Pattern**
```solidity
// Oracle callback pattern
interface IOracle {
    function requestData(string calldata endpoint) external returns (bytes32);
}

contract SolidityWithExternalData {
    mapping(bytes32 => PendingRequest) public requests;

    struct PendingRequest {
        address requester;
        uint timestamp;
        string endpoint;
    }

    event DataRequested(bytes32 indexed requestId, string endpoint);
    event DataReceived(bytes32 indexed requestId, string result);

    // Step 1: Make asynchronous request
    function fetchData(string calldata endpoint) public {
        bytes32 requestId = IOracle(oracleAddress).requestData(endpoint);
        requests[requestId] = PendingRequest({
            requester: msg.sender,
            timestamp: block.timestamp,
            endpoint: endpoint
        });
        emit DataRequested(requestId, endpoint);
    }

    // Step 2: Oracle calls back with result
    function fulfillData(bytes32 requestId, string calldata result)
        external
        onlyOracle
    {
        PendingRequest memory req = requests[requestId];
        require(req.requester != address(0), "Unknown request");

        // Process result
        processResult(req.requester, result);
        emit DataReceived(requestId, result);

        delete requests[requestId];
    }

    function processResult(address user, string calldata result) internal {
        // Handle the result
    }
}
```

---

## 7. Testing Frameworks

Testing approaches vary significantly across languages due to their different paradigms.

### Unit Testing

**Solidity - Hardhat**
```typescript
// tests/MyToken.test.ts
import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract, Signer } from "ethers";

describe("MyToken", function () {
    let token: Contract;
    let owner: Signer, addr1: Signer, addr2: Signer;
    let ownerAddress: string, addr1Address: string, addr2Address: string;

    beforeEach(async function () {
        [owner, addr1, addr2] = await ethers.getSigners();
        ownerAddress = await owner.getAddress();
        addr1Address = await addr1.getAddress();
        addr2Address = await addr2.getAddress();
        const MyToken = await ethers.getContractFactory("MyToken");
        token = await MyToken.deploy();
    });

    describe("Minting", function () {
        it("Should mint tokens to owner", async function () {
            await token.mint(ownerAddress, 100);
            expect(await token.balanceOf(ownerAddress)).to.equal(100);
        });

        it("Should only allow owner to mint", async function () {
            await expect(
                token.connect(addr1).mint(addr1Address, 100)
            ).to.be.revertedWith("Only owner");
        });
    });

    describe("Transfers", function () {
        beforeEach(async function () {
            await token.mint(ownerAddress, 100);
        });

        it("Should transfer tokens", async function () {
            await token.transfer(addr1Address, 50);
            expect(await token.balanceOf(addr1Address)).to.equal(50);
            expect(await token.balanceOf(ownerAddress)).to.equal(50);
        });
    });
});
```

**Solidity - Truffle**
```typescript
// test/MyToken.test.ts
import { artifacts, contract } from "hardhat";
import { Contract } from "ethers";

const MyToken = await artifacts.readArtifact("MyToken");

contract("MyToken", (accounts: string[]) => {
    const [owner, addr1, addr2] = accounts;
    let token: Contract;

    beforeEach(async () => {
        token = await MyToken.new();
    });

    it("should mint tokens", async () => {
        await token.mint(owner, 100);
        const balance = await token.balanceOf(owner);
        assert.equal(balance.toNumber(), 100);
    });

    it("should only allow owner", async () => {
        try {
            await token.mint(addr1, 100, { from: addr1 });
            assert.fail("Should have thrown");
        } catch (error: any) {
            assert(error.message.includes("Only owner"));
        }
    });
});
```

**Python - unittest**
```python
import unittest
from mytoken import MyToken

class TestMyToken(unittest.TestCase):
    def setUp(self):
        self.token = MyToken()
        self.owner = "0x123..."
        self.addr1 = "0x456..."

    def test_mint(self):
        self.token.mint(self.owner, 100)
        self.assertEqual(self.token.balance_of(self.owner), 100)

    def test_only_owner_can_mint(self):
        with self.assertRaises(PermissionError):
            self.token.mint(self.addr1, 100, caller=self.addr1)

    def test_transfer(self):
        self.token.mint(self.owner, 100)
        self.token.transfer(self.addr1, 50)
        self.assertEqual(self.token.balance_of(self.addr1), 50)
        self.assertEqual(self.token.balance_of(self.owner), 50)

if __name__ == "__main__":
    unittest.main()
```

**Python - pytest**
```python
import pytest
from mytoken import MyToken

@pytest.fixture
def token():
    return MyToken()

@pytest.fixture
def addresses():
    return {
        "owner": "0x123...",
        "addr1": "0x456...",
        "addr2": "0x789..."
    }

def test_mint(token, addresses):
    token.mint(addresses["owner"], 100)
    assert token.balance_of(addresses["owner"]) == 100

def test_only_owner_can_mint(token, addresses):
    with pytest.raises(PermissionError):
        token.mint(addresses["addr1"], 100, caller=addresses["addr1"])

class TestTransfers:
    def setup_method(self):
        self.token = MyToken()
        self.owner = "0x123..."
        self.addr1 = "0x456..."

    def test_transfer(self):
        self.token.mint(self.owner, 100)
        self.token.transfer(self.addr1, 50)
        assert self.token.balance_of(self.addr1) == 50
```

**Rust - Built-in Testing**
```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_mint() {
        let mut token = MyToken::new();
        token.mint("owner".to_string(), 100).unwrap();
        assert_eq!(token.balance_of("owner"), 100);
    }

    #[test]
    fn test_only_owner_can_mint() {
        let mut token = MyToken::new();
        let result = token.mint("addr1".to_string(), 100);
        assert!(result.is_err());
    }

    #[test]
    #[should_panic(expected = "Only owner")]
    fn test_mint_panic() {
        let mut token = MyToken::new();
        token.mint_panic("addr1".to_string(), 100);
    }
}

// Run tests: cargo test
```

**Go - Testing**
```go
package mytoken

import (
    "testing"
)

func TestMint(t *testing.T) {
    token := NewMyToken()
    balance, _ := token.Mint("owner", 100)
    if balance != 100 {
        t.Errorf("expected 100, got %d", balance)
    }
}

func TestOnlyOwnerCanMint(t *testing.T) {
    token := NewMyToken()
    _, err := token.Mint("addr1", 100)
    if err == nil {
        t.Errorf("expected error, got nil")
    }
}

func BenchmarkMint(b *testing.B) {
    token := NewMyToken()
    for i := 0; i < b.N; i++ {
        token.Mint("owner", 100)
    }
}

// Run tests: go test
// Run benchmarks: go test -bench=.
```

**TypeScript - Jest**
```typescript
describe("MyToken", () => {
    let token: MyToken;
    let owner: string, addr1: string, addr2: string;

    beforeEach(() => {
        token = new MyToken();
        owner = "0x123...";
        addr1 = "0x456...";
        addr2 = "0x789...";
    });

    test("should mint tokens", () => {
        token.mint(owner, 100);
        expect(token.balanceOf(owner)).toBe(100);
    });

    test("should only allow owner to mint", () => {
        expect(() => {
            token.mint(addr1, 100, { caller: addr1 });
        }).toThrow("Only owner");
    });

    describe("Transfers", () => {
        beforeEach(() => {
            token.mint(owner, 100);
        });

        test("should transfer tokens", () => {
            token.transfer(addr1, 50);
            expect(token.balanceOf(addr1)).toBe(50);
            expect(token.balanceOf(owner)).toBe(50);
        });
    });
});
```

**TypeScript - Mocha + Chai**
```typescript
import { expect } from "chai";
import { MyToken } from "../src/MyToken";

describe("MyToken", function() {
    let token: MyToken;
    let owner: string = "0x123...";
    let addr1: string = "0x456...";

    beforeEach(function() {
        token = new MyToken();
    });

    it("should mint tokens", function() {
        token.mint(owner, 100);
        expect(token.balanceOf(owner)).to.equal(100);
    });

    it("should only allow owner", function() {
        expect(() => token.mint(addr1, 100, { from: addr1 }))
            .to.throw("Only owner");
    });
});
```

---

## 8. Package Management

How dependencies are managed varies significantly across ecosystems.

### Dependency Declaration

**Solidity**
```solidity
// package.json (for npm-based projects)
{
  "name": "my-smart-contracts",
  "version": "1.0.0",
  "dependencies": {
    "@openzeppelin/contracts": "^4.9.0",
    "@openzeppelin/contracts-upgradeable": "^4.9.0"
  },
  "devDependencies": {
    "hardhat": "^2.14.0",
    "ethers": "^6.0.0",
    "@nomicfoundation/hardhat-toolbox": "^3.0.0"
  }
}

// Import in Solidity
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IMyInterface.sol";

contract MyToken is ERC20 {
    constructor() ERC20("MyToken", "MT") {}
}
```

**Python**
```python
# requirements.txt
web3==6.0.0
eth-keys==0.4.0
eth-typing==3.0.0
eth-utils==2.0.0
vyper==0.3.7

# Pipfile (using pipenv)
[packages]
web3 = "*"
eth-utils = "*"

[dev-packages]
pytest = "*"
pytest-cov = "*"

# Poetry (pyproject.toml)
[tool.poetry.dependencies]
python = "^3.9"
web3 = "^6.0.0"
```

**Rust**
```toml
# Cargo.toml
[package]
name = "smart-contract-library"
version = "0.1.0"
edition = "2021"

[dependencies]
ethers = "2.0"
tokio = { version = "1", features = ["full"] }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"

[dev-dependencies]
tokio-test = "0.4"
proptest = "1.0"

# Import in Rust
use ethers::contract::Contract;
use ethers::signers::LocalWallet;
```

**Go**
```go
// go.mod
module github.com/user/smart-contracts

go 1.21

require (
    github.com/ethereum/go-ethereum v1.13.0
    github.com/pkg/errors v0.9.1
)

// go.sum
github.com/ethereum/go-ethereum v1.13.0 h2:...

// Import in Go
import (
    "github.com/ethereum/go-ethereum/accounts/abi"
    "github.com/ethereum/go-ethereum/common"
)
```

**TypeScript/Node.js**
```json
// package.json
// @node (18.11-18.13)
{
  "name": "smart-contracts",
  "version": "1.0.0",
  "engines": {
    "node": ">=18.11.0 <=18.13.0"
  },
  "dependencies": {
    "ethers": "^6.0.0",
    "web3": "^4.0.0",
    "@openzeppelin/contracts": "^4.9.0"
  },
  "devDependencies": {
    "hardhat": "^2.14.0",
    "@types/chai": "^4.3.0",
    "@types/mocha": "^10.0.0",
    "chai": "^4.3.0",
    "mocha": "^10.0.0",
    "typescript": "^5.0.0",
    "ts-node": "^10.9.0"
  },
  "scripts": {
    "compile": "hardhat compile",
    "test": "hardhat test",
    "deploy": "hardhat run scripts/deploy.ts"
  }
}

// Import in TypeScript
import { ethers } from "ethers";
import { MyToken__factory } from "./typechain";
```

### Version Management

| Language | Package Manager | Lock File | Registry |
|----------|-----------------|-----------|----------|
| **Solidity** | npm/yarn | package-lock.json | npmjs.com |
| **Python** | pip/pipenv/poetry | requirements.lock | PyPI |
| **Rust** | Cargo | Cargo.lock | crates.io |
| **Go** | go mod | go.mod/go.sum | pkg.go.dev |
| **TypeScript** | npm/yarn/pnpm | package-lock.json | npmjs.com |

---

## 9. Security Considerations

Each language has unique security concerns and best practices.

### Solidity Security: Gas Limits and Reentrancy

**Solidity Vulnerabilities**
```solidity
// VULNERABILITY: Reentrancy
contract VulnerableBank {
    mapping(address => uint) balances;

    function withdraw(uint amount) public {
        // WRONG: External call before state update
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success);

        // State change after transfer - too late!
        balances[msg.sender] -= amount;
    }
}

// FIX: Checks-Effects-Interactions pattern
contract SecureBank {
    mapping(address => uint) balances;

    function withdraw(uint amount) public {
        // Check
        require(balances[msg.sender] >= amount);

        // Effect (state change first)
        balances[msg.sender] -= amount;

        // Interaction (external call last)
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success);
    }
}

// Reentrancy Guard Pattern
contract BankWithGuard {
    uint locked;

    modifier nonReentrant() {
        require(locked == 0);
        locked = 1;
        _;
        locked = 0;
    }

    function withdraw(uint amount) public nonReentrant {
        // Safe from reentrancy
    }
}

// Integer Overflow/Underflow
contract VulnerableMath {
    uint8 public counter;

    function increment() public {
        counter++;  // In Solidity <0.8.0, wraps at 256
    }
}

// Fixed in 0.8.0+
contract SafeMath {
    uint8 public counter;

    function increment() public {
        counter++;  // Reverts on overflow by default
    }

    // Or use unchecked for performance
    function unsafeIncrement() public {
        unchecked { counter++; }
    }
}

// Front-running vulnerability
contract VulnerablePrice {
    uint public price = 100;

    function updatePrice(uint newPrice) public onlyOracle {
        // Anyone can see this transaction before it's mined
        // Can front-run to exploit the price
        price = newPrice;
    }
}

// Mitigation: Commit-reveal pattern
contract CommitRevealPrice {
    bytes32 priceCommit;

    function commitPrice(bytes32 commit) public onlyOracle {
        priceCommit = commit;
    }

    function revealPrice(uint newPrice, bytes32 salt) public onlyOracle {
        require(keccak256(abi.encodePacked(newPrice, salt)) == priceCommit);
        // Only after commit is revealed
    }
}
```

### Python Security: Dynamic Types and Injection

**Python Security Issues**
```python
# VULNERABILITY: SQL Injection-like issues
class VulnerableDB:
    def query(self, user_input):
        # WRONG: String interpolation with user input
        query = f"SELECT * FROM users WHERE id = {user_input}"
        # Can be exploited: "1; DROP TABLE users;--"
        return self.db.execute(query)

# FIX: Parameterized queries
class SecureDB:
    def query(self, user_id):
        # Use parameterized queries
        query = "SELECT * FROM users WHERE id = ?"
        return self.db.execute(query, (user_id,))

# VULNERABILITY: Type confusion
class VulnerableCalc:
    def transfer(self, amount):
        if amount < 1000000:
            # No type checking!
            return self.balance - amount

# FIX: Type hints and validation
class SecureCalc:
    def transfer(self, amount: int) -> int:
        if not isinstance(amount, int):
            raise TypeError("Amount must be integer")
        if amount < 0:
            raise ValueError("Amount must be positive")
        if amount > self.balance:
            raise ValueError("Insufficient balance")
        return self.balance - amount

# VULNERABILITY: Pickle deserialization
import pickle

class VulnerablePickle:
    def load_user(self, data):
        # WRONG: Unpickling untrusted data
        return pickle.loads(data)  # Can execute arbitrary code!

# FIX: Use safer serialization
import json

class SecurePickle:
    def load_user(self, data):
        # Use JSON instead
        return json.loads(data)

# VULNERABILITY: Default mutable arguments
class VulnerableList:
    def append_item(self, item, items=[]):  # WRONG!
        items.append(item)
        return items

# This creates bugs: items is shared across calls
obj = VulnerableList()
print(obj.append_item(1))     # [1]
print(obj.append_item(2))     # [1, 2] - UNEXPECTED!

# FIX: Use None as default
class SecureList:
    def append_item(self, item, items=None):
        if items is None:
            items = []
        items.append(item)
        return items
```

### Rust Security: Ownership and Lifetimes

**Rust Security Benefits**
```rust
// Memory Safety: Compiler prevents many issues
// GOOD: Rust prevents use-after-free at compile time
fn safe_reference(s: &String) {
    println!("{}", s);
    // s is borrowed, not owned
}

// COMPILER ERROR: Cannot use after move
fn move_example() {
    let s = String::from("hello");
    let s2 = s;  // s is moved
    println!("{}", s);  // ERROR: s is no longer valid
}

// FIX: Use borrowing
fn borrow_example() {
    let s = String::from("hello");
    let s2 = &s;  // Borrow s
    println!("{}", s);  // OK: s is still valid
}

// Vulnerability: Integer overflow in unchecked math
fn vulnerable_calc(a: u32, b: u32) -> u32 {
    a * b  // Can overflow!
}

// FIX: Use checked operations
fn safe_calc(a: u32, b: u32) -> Result<u32, &'static str> {
    a.checked_mul(b).ok_or("Overflow")
}

// Safe concurrency with Send/Sync traits
use std::sync::{Arc, Mutex};
use std::thread;

fn safe_concurrent() {
    let data = Arc::new(Mutex::new(vec![1, 2, 3]));

    let data_clone = Arc::clone(&data);
    thread::spawn(move || {
        let mut d = data_clone.lock().unwrap();
        d.push(4);
    });

    let d = data.lock().unwrap();
    println!("{:?}", *d);
}
```

### Go Security: Simplicity with Caveats

**Go Security Considerations**
```go
// Vulnerability: Unchecked error handling
func vulnerableRead(filename string) string {
    data, _ := ioutil.ReadFile(filename)  // Ignoring error!
    return string(data)
}

// FIX: Check errors
func safeRead(filename string) (string, error) {
    data, err := ioutil.ReadFile(filename)
    if err != nil {
        return "", fmt.Errorf("read failed: %w", err)
    }
    return string(data), nil
}

// Vulnerability: Race condition
func vulnerableCounter() {
    var count int
    go func() {
        count++
    }()
    go func() {
        count++
    }()
}

// FIX: Use mutex for synchronization
func safeCounter() {
    var mu sync.Mutex
    var count int

    go func() {
        mu.Lock()
        count++
        mu.Unlock()
    }()
}

// Integer overflow not caught
func vulnerable() {
    var x uint8 = 255
    x++  // Wraps to 0
}

// FIX: Use bigger types or check bounds
func safe() {
    var x uint16 = 255
    x++  // Now 256 - safe
}
```

### TypeScript Security: Type Safety and Scope

**TypeScript Security Issues**
```typescript
// VULNERABILITY: String concatenation for sensitive operations
class VulnerableWallet {
    transfer(to: string, amount: number): void {
        // WRONG: Building transaction string
        const tx: string = `transfer(${to}, ${amount})`;
        // Could be exploited!
    }
}

// FIX: Use proper libraries
import { ethers } from "ethers";

class SecureWallet {
    async transfer(to: string, amount: bigint): Promise<void> {
        const tx = await this.contract.transfer(to, amount);
        await tx.wait();
    }
}

// VULNERABILITY: Global scope pollution
let globalState: number = 0;  // WRONG: Creates global variable

function increment(): void {
    globalState++;  // Modifies global
}

// FIX: Use closures and modules
const counter = (() => {
    let count: number = 0;  // Private variable

    return {
        increment(): void { count++; },
        get(): number { return count; },
    };
})();

// VULNERABILITY: Type coercion bugs (less common in TypeScript)
class VulnerableCheck {
    isValid(value: any): boolean {
        if (value == "0") return true;  // Type coercion!
        return false;
    }
}

// Issues:
isValid(false);  // true (== is loose)
isValid([]);     // true (== coerces)

// FIX: Use strict equality and proper types
class SafeCheck {
    isValid(value: string | number): boolean {
        if (value === "0" || value === 0) return true;  // Strict equality
        return false;
    }
}

// VULNERABILITY: Promise handling
class VulnerableAsync {
    async fetchData(): Promise<any> {
        const data: Promise<Response> = fetch(url);  // Forgot await!
        return data.json();  // Error!
    }
}

// FIX: Proper async/await
class SafeAsync {
    async fetchData(): Promise<any> {
        const response: Response = await fetch(url);
        return await response.json();
    }
}
```

---

## 10. Performance Characteristics

How each language's performance differs fundamentally.

### Execution Speed

**Solidity**
```solidity
// Performance determined by gas cost, not actual speed
contract PerformanceDemo {
    uint[] public items;

    // O(1) - constant gas (except stack writes)
    function addToStorage() public {
        items.push(1);
    }

    // More expensive operations
    function multiplyLarge(uint a, uint b) public pure returns (uint) {
        return a * b;  // Different costs for different size integers
    }

    // Very expensive: storage operations
    function complexOperation(uint count) public {
        for (uint i = 0; i < count; i++) {
            items.push(i);  // EXPENSIVE: storage write each iteration
        }
    }

    // Cheaper: memory operations
    function efficientOperation(uint count) public pure returns (uint) {
        uint sum = 0;  // Memory
        for (uint i = 0; i < count; i++) {
            sum += i;  // Cheap memory operations
        }
        return sum;
    }
}

// Gas costs example:
// - SSTORE (write): 20,000 gas (first write), 5,000 gas (update)
// - SLOAD (read): 2,100 gas
// - MSTORE (memory): 3 gas
// - ADD: 3 gas
```

**Python**
```python
# Interpreted, overhead but readable
import timeit

class PerformanceDemo:
    def __init__(self):
        self.items = []

    # Fast for small operations
    def simple_operation(self):
        total = 0
        for i in range(100):
            total += i
        return total

    # Slower: list operations
    def list_operations(self):
        for i in range(1000):
            self.items.append(i)  # Dynamic resizing

    # Optimization: list comprehension is faster
    def list_comprehension(self):
        self.items = [i for i in range(1000)]

    # Use built-ins for speed
    def builtin_sum(self):
        return sum(range(1000))

# Benchmark
setup = "from __main__ import demo; demo = PerformanceDemo()"
print(timeit.timeit("demo.simple_operation()", setup=setup, number=10000))
print(timeit.timeit("demo.list_comprehension()", setup=setup, number=1000))
```

**Rust**
```rust
// Compiled, very fast, no garbage collection overhead
use std::time::Instant;

fn performance_demo() {
    // Stack allocation: very fast
    let mut items: Vec<i32> = Vec::new();

    let start = Instant::now();
    for i in 0..1_000_000 {
        items.push(i);
    }
    println!("Push: {:?}", start.elapsed());

    // Iterator (zero-cost abstraction)
    let start = Instant::now();
    let sum: i32 = (0..1_000_000).sum();
    println!("Iterator: {:?}", start.elapsed());

    // Manual loop
    let start = Instant::now();
    let mut sum = 0;
    for i in 0..1_000_000 {
        sum += i;
    }
    println!("Loop: {:?}", start.elapsed());
}

// Typical results (relative):
// Iterator: ~100x faster than Python loop
// Vec operations: Minimal overhead
```

**Go**
```go
package main

import (
    "fmt"
    "time"
)

func performanceDemo() {
    // Stack allocation
    var items []int

    start := time.Now()
    for i := 0; i < 1_000_000; i++ {
        items = append(items, i)
    }
    fmt.Printf("Append: %v\n", time.Since(start))

    // Goroutine concurrency (very efficient)
    start = time.Now()
    results := make(chan int, 100)

    for i := 0; i < 100; i++ {
        go func(n int) {
            sum := 0
            for j := 0; j < 10_000; j++ {
                sum += j
            }
            results <- sum
        }(i)
    }

    for i := 0; i < 100; i++ {
        <-results
    }
    fmt.Printf("Concurrent: %v\n", time.Since(start))
}

// Typical characteristics:
// - Fast compilation
// - Very efficient concurrency
// - Garbage collection overhead minimal
```

**TypeScript**
```typescript
// JIT compiled, garbage collected
// Performance varies by V8 optimization

class PerformanceDemo {
    items: number[];

    constructor() {
        this.items = [];
    }

    simpleOperation(): number {
        let total: number = 0;
        for (let i = 0; i < 100; i++) {
            total += i;
        }
        return total;
    }

    listOperations(): void {
        for (let i = 0; i < 1000; i++) {
            this.items.push(i);
        }
    }

    // Array methods often optimized
    builtinSum(): number {
        return Array.from({length: 1000}, (_, i) => i)
            .reduce((a, b) => a + b, 0);
    }
}

// Benchmark
console.time("simple");
for (let i = 0; i < 10000; i++) {
    new PerformanceDemo().simpleOperation();
}
console.timeEnd("simple");

// Performance depends on:
// - JIT optimization (improves with repeated calls)
// - Garbage collection pauses
// - Hidden class stability
```

### Performance Comparison Table

| Operation | Solidity | Python | Rust | Go | TypeScript |
|-----------|----------|--------|------|----|----|
| **Simple Arithmetic** | 3-5 gas | μs | ns | ns | μs |
| **Array Push** | 20,000+ gas | μs | ns | ns | ns |
| **Storage Write** | 20,000 gas | N/A | N/A | N/A | N/A |
| **Loop (10K iter)** | 30,000+ gas | ms | μs | μs | ms |
| **Memory Allocation** | N/A | μs | ns | ns | μs |
| **Concurrency** | None | ms/thread | ns | μs/goroutine | μs/promise |

---

## 11. Key Takeaways for Solidity Developers

### Coming from Python

- **Type System**: Add explicit types everywhere - Python's flexibility doesn't exist in Solidity
- **Memory**: Understand storage vs. memory vs. calldata - these have massive cost implications
- **Error Handling**: Replace exceptions with require/revert - no try/catch for business logic
- **Async**: Forget promises - embrace request/callback patterns or multi-step transactions
- **Costs**: Every operation has a gas cost - optimize ruthlessly

### Coming from Rust

- **Ownership**: Solidity doesn't have Rust's ownership model - focus on state management instead
- **Errors**: Use require/revert instead of Result types - simpler but less safe
- **Concurrency**: None exists - think single-threaded execution only
- **Performance**: Gas costs matter more than CPU speed - optimize data structures
- **Safety**: Solidity is less safe than Rust - rely on audits and extensive testing

### Coming from Go

- **Errors**: Simple error handling with require/revert instead of if err != nil
- **Goroutines**: No concurrency - every transaction is synchronous
- **Simplicity**: Go is simpler than Solidity's interaction model
- **State Management**: Permanent state (storage) is unique to blockchain
- **Testing**: Requires specific blockchain testing tools (Hardhat, Truffle)

### Coming from TypeScript

- **Types**: Similar strong typing, but Solidity types are fixed-size and more restrictive
- **Async/Await**: Not available - use callbacks or multi-step transactions
- **Numbers**: Integers are fixed-size - overflow is a major concern (unlike TypeScript's number)
- **Scope**: All functions can be called externally - careful with visibility modifiers
- **Gas**: Every operation has a cost - write efficient code (unlike TypeScript where performance is less critical)

---

## Conclusion

Solidity's unique position as a blockchain language creates significant differences from traditional programming languages:

1. **State Permanence**: Smart contract state is permanently stored on-chain
2. **Atomic Transactions**: Each transaction is all-or-nothing execution
3. **Gas Costs**: Every operation has a direct monetary cost
4. **Limited Async**: No built-in concurrency; external data requires oracle patterns
5. **Immutable Deployment**: Smart contracts can't be updated (unless designed with upgrades)
6. **High Security Bar**: Mistakes cost real money - security is paramount

When transitioning from other languages, success in Solidity requires:

- Deep understanding of the EVM and gas mechanics
- Paranoia about security and edge cases
- Comfort with request/callback patterns instead of async/await
- Optimization for gas costs, not CPU cycles
- Extensive testing and formal verification where possible

Use this guide as a reference when transitioning between these ecosystems, and always remember: in smart contracts, correctness matters more than performance.

---

# Part 3: Foundry Development Guide

# Comprehensive Foundry Guide

> **Master Foundry for Solidity development**: Testing, scripting, deployment, and contract interaction with practical examples

## Table of Contents

1. [Getting Started with Foundry](#getting-started)
2. [Forge Commands](#forge-commands)
3. [Cheatcodes Reference](#cheatcodes)
4. [Fuzzing and Invariant Testing](#fuzzing-invariants)
5. [Gas Snapshots and Profiling](#gas-profiling)
6. [Foundry Scripts for Deployment](#foundry-scripts)
7. [Cast for Contract Interaction](#cast-interaction)
8. [Anvil for Local Testing](#anvil-testing)
9. [Foundry.toml Configuration](#foundry-config)
10. [Advanced Testing Patterns](#advanced-patterns)

---

## Getting Started with Foundry {#getting-started}

> **Complete setup guide for Foundry, Anvil, and local development**

This section will walk you through setting up your development environment, compiling your first contract, and deploying it to a local Anvil instance.

### Prerequisites

Before you begin, ensure you have:

- **macOS, Linux, or Windows (WSL recommended)**
- **Command line access** (Terminal, iTerm, PowerShell, etc.)
- **Git** installed (`git --version`)
- **Basic familiarity** with command line tools

### Installation

Foundry is a fast, portable, and modular toolkit for Ethereum application development. It consists of three main tools:

- **Forge**: Build, test, and deploy contracts
- **Cast**: Interact with contracts and send transactions
- **Anvil**: Local Ethereum node for testing

#### Step 1: Install Foundry

```bash
# Download and run the Foundry installer
curl -L https://foundry.paradigm.xyz | bash
```

This will download and install `foundryup`, the Foundry version manager.

#### Step 2: Initialize Foundry

After installation, you need to add Foundry to your PATH. The installer will provide instructions, but typically:

```bash
# Add to your shell profile (~/.bashrc, ~/.zshrc, etc.)
source ~/.foundry/bin/foundryup

# Or restart your terminal
```

#### Step 3: Install Foundry Tools

```bash
# Install/update Foundry to the latest version
foundryup
```

#### Step 4: Verify Installation

```bash
# Check that all tools are installed correctly
forge --version
cast --version
anvil --version
```

You should see version numbers for each tool. If you see "command not found", make sure Foundry is in your PATH.

**Expected Output:**
```
forge 0.2.0 (abc123 2024-01-01T00:00:00.000000000Z)
cast 0.2.0 (abc123 2024-01-01T00:00:00.000000000Z)
anvil 0.2.0 (abc123 2024-01-01T00:00:00.000000000Z)
```

### Project Structure

```
my-project/
├── foundry.toml              # Foundry configuration
├── src/                      # Smart contracts
│   ├── Counter.sol
│   └── solution/
│       └── CounterSolution.sol
├── test/                     # Test files
│   └── Counter.t.sol
├── script/                   # Deployment and interaction scripts
│   └── Deploy.s.sol
├── lib/                      # Dependencies (OpenZeppelin, etc.)
│   └── openzeppelin-contracts/
└── out/                      # Compiled artifacts (generated)
    ├── Counter.sol/
    └── Counter.json
```

### Project Setup

#### Step 1: Clone the Repository

```bash
# Clone the repository
git clone <repository-url>
cd solidity-edu
```

#### Step 2: Install Dependencies

This project uses OpenZeppelin contracts. Install them:

```bash
# Install OpenZeppelin contracts
forge install openzeppelin/openzeppelin-contracts --no-commit
```

**What this does:**
- Downloads OpenZeppelin contracts to `lib/openzeppelin-contracts/`
- Creates a git submodule (we use `--no-commit` to avoid committing it)
- Makes contracts available for import

### Compiling Contracts

**IMPORTANT: Always compile before deploying!**

Compilation checks for:
- Syntax errors
- Type errors
- Missing imports
- Compiler version compatibility

```bash
# From the project root
forge build
```

**Expected Output:**
```
[⠊] Compiling...
[⠊] Compiling 50 files with 0.8.20
[⠊] Solc 0.8.20 finished in 2.34s
Compiler run successful!
```

### Starting Anvil

Anvil is Foundry's local Ethereum node. Think of it as a private blockchain running on your computer - like a test server for your contracts.

```bash
# Start Anvil in a terminal window
anvil
```

**What you'll see:**
```
Available Accounts
==================

ACCOUNT #0: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 (10000 ETH)
Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

Listening on 127.0.0.1:8545
```

**Key Information:**
- **RPC URL**: `http://localhost:8545` (default)
- **Chain ID**: `31337` (default)
- **10 accounts** pre-funded with 10,000 ETH each
- **Instant mining** (no waiting for blocks)

### Deploying to Anvil

```bash
# Navigate to a project
cd 01-datatypes-and-storage

# ALWAYS compile before deploying
forge build

# Deploy using the script
forge script script/DeployDatatypesStorage.s.sol \
  --broadcast \
  --rpc-url http://localhost:8545
```

**Command Breakdown:**
- `forge script`: Run a deployment script
- `script/DeployDatatypesStorage.s.sol`: Path to script
- `--broadcast`: Actually send transactions (without this, it's a dry run)
- `--rpc-url http://localhost:8545`: Connect to Anvil

### Quick Start Summary

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Setup project
forge install openzeppelin/openzeppelin-contracts --no-commit

# Compile
forge build

# Start Anvil (in separate terminal)
anvil

# Deploy to Anvil
forge script script/Deploy[Contract].s.sol --broadcast --rpc-url http://localhost:8545

# Run tests
forge test
```

---

## Forge Commands {#forge-commands}

### Core Testing Commands

#### `forge test` - Run all tests

```bash
# Run all tests
forge test

# Run tests with increased verbosity
forge test -v      # Level 1: Show pass/fail
forge test -vv     # Level 2: Show logs
forge test -vvv    # Level 3: Show stack traces
forge test -vvvv   # Level 4: Show contract interactions
forge test -vvvvv  # Level 5: Show storage updates

# Run specific test
forge test --match-test test_SetNumber

# Run tests in specific file
forge test --match-path "src/test/Counter.t.sol"

# Run tests in specific contract
forge test --match-contract CounterTest

# Exclude specific tests
forge test --no-match-test "testFuzz" # Skip fuzz tests
forge test --no-match-contract "FuzzTest"

# Run with custom fuzz runs
forge test --fuzz-runs 10000

# Show gas report
forge test --gas-report

# Generate gas snapshots
forge snapshot
```

**Example Output**:
```
Running 5 tests for test/Counter.t.sol:CounterTest
[PASS] test_Increment() (gas: 28328)
[PASS] test_SetNumber() (gas: 31041)
[PASS] testFuzz_SetNumber(uint256) (runs: 256, μ: 31089, ~: 31089)
[PASS] invariant_AlwaysPositive()
Tests: 4 passed, 0 failed, 0 skipped; finished in 0.003s
```

### Build Commands

#### `forge build` - Compile contracts

```bash
# Build all contracts
forge build

# Build with optimizations (as per foundry.toml)
forge build --optimize

# Set custom optimizer runs
forge build --optimizer-runs 200

# Build with specific EVM version
forge build --evm-version paris

# See compilation details
forge build -vv
```

### Script Commands

#### `forge script` - Run Solidity scripts

```bash
# Simulate script execution (dry run)
forge script script/Deploy.s.sol

# Simulate on forked network
forge script script/Deploy.s.sol --fork-url $MAINNET_RPC_URL

# Broadcast to network
forge script script/Deploy.s.sol \
  --broadcast \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY

# Verify contracts after deployment
forge script script/Deploy.s.sol \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_KEY \
  --rpc-url $MAINNET_RPC_URL

# Run specific function
forge script script/Deploy.s.sol:DeployScript --sig "run()"

# Show calldata
forge script script/Deploy.s.sol --broadcast --sig "deployToken(string,string)" "MyToken" "MTK"
```

### Additional Commands

#### `forge fmt` - Format contracts

```bash
# Format all contracts
forge fmt

# Format specific file
forge fmt src/Counter.sol

# Check formatting without modifying
forge fmt --check
```

#### `forge coverage` - Code coverage

```bash
# Generate coverage report
forge coverage

# Save as HTML
forge coverage --report html

# Show specific contract coverage
forge coverage --match-contract Counter
```

#### `forge flatten` - Flatten contracts

```bash
# Flatten a contract (merge dependencies)
forge flatten src/Counter.sol > flattened.sol

# Used for verification on Etherscan
```

#### `forge verify-contract` - Verify on Etherscan

```bash
# Verify contract on Etherscan
forge verify-contract \
  --chain-id 1 \
  --compiler-version v0.8.20 \
  --constructor-args 0x... \
  <CONTRACT_ADDRESS> \
  src/Counter.sol:Counter \
  --etherscan-api-key $ETHERSCAN_KEY
```

#### `forge generate-fig-spec` - Generate autocomplete

```bash
# Generate shell completion specs
forge generate-fig-spec > /tmp/forge-fig-spec.json
```

---

## Cheatcodes Reference {#cheatcodes}

Foundry provides `vm` cheatcodes in the `Test` contract from `forge-std/Test.sol`. These allow you to manipulate the test environment.

### State Manipulation

#### `vm.prank(address)` - Change `msg.sender`

Calls made by the contract (or contract it calls) will have `msg.sender` as the specified address.

```solidity
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Bank.sol";

contract BankTest is Test {
    Bank bank;
    address owner = address(0x1);
    address user = address(0x2);

    function setUp() public {
        bank = new Bank();
        vm.deal(user, 100 ether); // Give user 100 ETH
    }

    // Normal call: msg.sender is address(this) (test contract)
    function test_Deposit_AsOwner() public {
        bank.deposit{value: 1 ether}();
        assertEq(bank.balances(address(this)), 1 ether);
    }

    // prank: next call has msg.sender = user
    function test_Deposit_AsUser() public {
        vm.prank(user);
        bank.deposit{value: 1 ether}();
        assertEq(bank.balances(user), 1 ether);
    }
}
```

#### `vm.startPrank(address)` and `vm.stopPrank()` - Multi-call prank

```solidity
function test_MultipleCallsAsPrank() public {
    vm.startPrank(user);

    // Both these calls have msg.sender = user
    bank.deposit{value: 1 ether}();
    bank.deposit{value: 0.5 ether}();

    vm.stopPrank();

    // Back to msg.sender = address(this)
    bank.withdraw(0.5 ether);
}
```

#### `vm.deal(address, uint256)` - Allocate ETH

```solidity
function test_UserHasEther() public {
    address user = address(0x123);

    // Give user 50 ETH
    vm.deal(user, 50 ether);
    assertEq(user.balance, 50 ether);
}
```

#### `vm.store(address, bytes32, bytes32)` - Write to storage

```solidity
function test_ModifyStorageSlot() public {
    Counter counter = new Counter();

    // Modify the counter's internal value directly
    // slot 0 holds the count value
    vm.store(address(counter), bytes32(uint256(0)), bytes32(uint256(100)));

    assertEq(counter.count(), 100);
}
```

#### `vm.load(address, bytes32) -> bytes32` - Read from storage

```solidity
function test_ReadStorageSlot() public {
    Counter counter = new Counter();
    counter.increment();

    // Read the value at storage slot 0
    bytes32 value = vm.load(address(counter), bytes32(uint256(0)));
    assertEq(uint256(value), 1);
}
```

### Time and Block Manipulation

#### `vm.warp(uint256)` - Set block timestamp

```solidity
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/TimeLockedVault.sol";

contract TimeLockedVaultTest is Test {
    TimeLockedVault vault;
    address depositor = address(0x1);

    function setUp() public {
        vault = new TimeLockedVault(30 days); // 30 day lock
        vm.deal(depositor, 100 ether);
    }

    function test_WithdrawBeforeLockEnds() public {
        vm.prank(depositor);
        vault.deposit{value: 10 ether}();

        // Try to withdraw immediately
        vm.prank(depositor);
        vm.expectRevert("Still locked");
        vault.withdraw();
    }

    function test_WithdrawAfterLockEnds() public {
        // Current block.timestamp is 1 (Foundry starts at 1)
        vm.prank(depositor);
        vault.deposit{value: 10 ether}();

        // Warp 30 days into the future
        vm.warp(block.timestamp + 30 days);

        vm.prank(depositor);
        vault.withdraw();
        assertEq(depositor.balance, 100 ether); // Successfully withdrew
    }
}
```

#### `vm.roll(uint256)` - Set block number

```solidity
function test_BlockNumberDependent() public {
    uint256 startBlock = block.number;
    assertEq(startBlock, 1); // Foundry starts at block 1

    // Jump 100 blocks
    vm.roll(block.number + 100);
    assertEq(block.number, 101);
}
```

### Revert Expectations

#### `vm.expectRevert()` - Expect any revert

```solidity
function test_WithdrawalFailsWhenEmpty() public {
    Bank bank = new Bank();

    // Expect the next call to revert with any message
    vm.expectRevert();
    bank.withdraw(1 ether);
}
```

#### `vm.expectRevert(bytes4)` - Expect specific error selector

```solidity
function test_WithdrawalFailsWithCustomError() public {
    Bank bank = new Bank();

    // Expect custom error InsufficientBalance
    vm.expectRevert(Bank.InsufficientBalance.selector);
    bank.withdraw(1 ether);
}
```

#### `vm.expectRevert(string)` - Expect specific message

```solidity
function test_WithdrawalFailsWithMessage() public {
    Bank bank = new Bank();

    // Expect specific error message
    vm.expectRevert("Insufficient balance");
    bank.withdraw(1 ether);
}
```

#### `vm.expectRevert(bytes)` - Expect encoded revert data

```solidity
function test_WithdrawalFailsWithBytes() public {
    Bank bank = new Bank();

    // Expect specific encoded revert
    vm.expectRevert(abi.encodeWithSelector(Bank.InsufficientBalance.selector));
    bank.withdraw(1 ether);
}
```

**Complete Example**:

```solidity
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

contract Bank {
    error InsufficientBalance();
    error InvalidAmount();

    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        if (amount == 0) revert InvalidAmount();
        if (balances[msg.sender] < amount) revert InsufficientBalance();

        balances[msg.sender] -= amount;
        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }
}

contract BankTest is Test {
    Bank bank;
    address user = address(0x1);

    function setUp() public {
        bank = new Bank();
        vm.deal(user, 100 ether);
    }

    function test_RevertWithCustomError() public {
        vm.expectRevert(Bank.InsufficientBalance.selector);
        bank.withdraw(1 ether); // No deposit yet
    }

    function test_RevertWithAnyError() public {
        vm.expectRevert();
        bank.withdraw(1 ether);
    }

    function test_Success() public {
        vm.prank(user);
        bank.deposit{value: 10 ether}();

        vm.prank(user);
        bank.withdraw(5 ether);

        vm.prank(user);
        assertEq(bank.balances(user), 5 ether);
    }
}
```

### Event Verification

#### `vm.expectEmit()` - Expect event emission

```solidity
pragma solidity ^0.8.20;

contract Token {
    event Transfer(address indexed from, address indexed to, uint256 amount);

    mapping(address => uint256) public balances;

    function transfer(address to, uint256 amount) external {
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
    }
}

contract TokenTest is Test {
    Token token;
    address sender = address(0x1);
    address receiver = address(0x2);

    function setUp() public {
        token = new Token();
        token.balances[sender] = 100;
    }

    function test_TransferEmitsEvent() public {
        // expectEmit(checkTopic1, checkTopic2, checkTopic3, checkData)
        // Topics are indexed parameters, data is non-indexed
        vm.expectEmit(true, true, false, true);

        // Emit the expected event
        emit Token.Transfer(sender, receiver, 50);

        // Call the function that should emit the event
        vm.prank(sender);
        token.transfer(receiver, 50);
    }
}
```

**Event Parameter Reference**:

```solidity
event Transfer(
    address indexed from,    // Topic 1 (indexed)
    address indexed to,      // Topic 2 (indexed)
    uint256 amount          // Data (non-indexed)
);

// expectEmit(topic1, topic2, topic3, checkData)
vm.expectEmit(true, true, false, true);
// Checks topic1 (from), topic2 (to), skipTopic3, checkData (amount)
```

### Call and Delegate Utilities

#### `vm.call()` and `vm.staticcall()` - Low-level calls

```solidity
function test_LowLevelCall() public {
    address target = address(new Target());

    // Call a function
    (bool success, bytes memory result) = vm.call(target, abi.encodeWithSignature("getValue()"));
    assertTrue(success);
}

function test_ReadOnlyCall() public {
    address target = address(new Target());

    // Call with no state changes (staticcall)
    (bool success, bytes memory result) = vm.staticcall(target, abi.encodeWithSignature("getValue()"));
    assertTrue(success);
}
```

#### `vm.etch(address, bytes)` - Set contract code

```solidity
function test_DeployCodeToAddress() public {
    address deployedAddr = address(0x123);
    bytes memory code = type(Counter).creationCode;

    vm.etch(deployedAddr, code);

    // Now deployedAddr has the Counter contract code
    Counter counter = Counter(deployedAddr);
    assertEq(counter.count(), 0);
}
```

### Other Useful Cheatcodes

#### `vm.snapshot()` and `vm.revertToSnapshot()`

```solidity
function test_SnapshotRevert() public {
    Counter counter = new Counter();
    counter.increment();

    uint256 snapshotId = vm.snapshot();
    assertEq(counter.count(), 1);

    // Make changes
    counter.increment();
    assertEq(counter.count(), 2);

    // Revert to snapshot
    vm.revertToSnapshot(snapshotId);
    assertEq(counter.count(), 1);
}
```

#### `vm.getCode()` - Get contract bytecode

```solidity
function test_GetBytecode() public {
    Counter counter = new Counter();
    bytes memory code = vm.getCode(address(counter));
    assertGt(code.length, 0);
}
```

#### `vm.expectCall()` - Expect specific call

```solidity
function test_ExpectCall() public {
    address target = address(new Token());
    address user = address(0x1);

    // Expect a call to token.approve(user, 100)
    vm.expectCall(target, abi.encodeWithSignature("approve(address,uint256)", user, 100));

    // Function that should call approve
    // ...
}
```

#### `vm.label()` - Label addresses in traces

```solidity
function setUp() public {
    owner = address(0x1);
    user = address(0x2);

    // Labels help with readability in traces
    vm.label(owner, "Owner");
    vm.label(user, "User");
    vm.label(address(contract), "ContractName");
}
```

#### `vm.skip()` - Skip test

```solidity
function test_SkippedTest() public {
    vm.skip(true);

    // This code is never executed
    revert("Should never reach");
}
```

---

## Fuzzing and Invariant Testing {#fuzzing-invariants}

### Property-Based Fuzzing

Foundry automatically generates random inputs for functions prefixed with `testFuzz`.

#### Basic Fuzzing

```solidity
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Math.sol";

contract MathTest is Test {
    Math math;

    function setUp() public {
        math = new Math();
    }

    /**
     * @notice Foundry will call this test with random uint256 values
     * @dev Foundry runs 256 fuzz runs by default
     * Each run: testFuzz_Add is called with a random `a` and `b`
     */
    function testFuzz_Add(uint256 a, uint256 b) public {
        // Property: adding two positive numbers should give result >= both inputs
        uint256 result = math.add(a, b);
        assertGe(result, a);
        assertGe(result, b);
    }

    /**
     * @notice Test commutative property: a + b = b + a
     */
    function testFuzz_AddCommutative(uint256 a, uint256 b) public {
        assertEq(math.add(a, b), math.add(b, a));
    }

    /**
     * @notice Test associative property: (a + b) + c = a + (b + c)
     */
    function testFuzz_AddAssociative(uint256 a, uint256 b, uint256 c) public {
        uint256 left = math.add(math.add(a, b), c);
        uint256 right = math.add(a, math.add(b, c));
        assertEq(left, right);
    }
}
```

#### Constrained Fuzzing with `bound()`

```solidity
function testFuzz_Increment(uint256 _start) public {
    // Without bound: _start can be 0 to type(uint256).max
    // incrementNumber might overflow at max

    // Bound to prevent overflow
    uint256 start = bound(_start, 0, type(uint256).max - 1);

    counter.setNumber(start);
    counter.increment();

    // Now this assertion will never fail due to overflow
    assertEq(counter.getNumber(), start + 1);
}
```

**Other bound helpers**:

```solidity
// Constrain to range
uint256 amount = bound(fuzzValue, 1 ether, 1000 ether);

// Exclude address(0)
address user = address(uint160(bound(uint160(fuzzAddr), 1, type(uint160).max)));

// Constrain array length
uint256 length = bound(fuzzyLength, 1, 100);
uint256[] memory arr = new uint256[](length);
```

#### Run Custom Fuzz Count

```bash
# Run with 10,000 fuzz iterations per test
forge test --fuzz-runs 10000

# Run with specific seed
forge test --fuzz-seed 12345

# Replay specific failing case
forge test --fuzz-runs 1 --match test_failing_case
```

### Invariant Testing

Invariant tests verify that certain properties always hold, even after arbitrary sequences of operations.

```solidity
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Vault.sol";

/**
 * @notice Invariant test handler
 * This contract receives random sequences of function calls
 * and verifies that vault invariants hold afterward
 */
contract VaultHandler is Test {
    Vault vault;
    address user1 = address(0x1);
    address user2 = address(0x2);

    constructor() {
        vault = new Vault();
        vm.deal(user1, 1000 ether);
        vm.deal(user2, 1000 ether);
    }

    // Foundry will call random sequences of these functions
    function deposit(uint256 amount) public {
        amount = bound(amount, 1 wei, 1000 ether);

        address user = msg.sender == address(0) ? user1 : msg.sender;
        vm.prank(user);

        if (user.balance >= amount) {
            vault.deposit{value: amount}();
        }
    }

    function withdraw(uint256 amount) public {
        amount = bound(amount, 1 wei, vault.getBalance(msg.sender));

        address user = msg.sender == address(0) ? user1 : msg.sender;
        vm.prank(user);

        vault.withdraw(amount);
    }
}

contract VaultInvariantTest is Test {
    Vault vault;
    VaultHandler handler;

    function setUp() public {
        handler = new VaultHandler();
    }

    /**
     * @notice Invariant: Total vault balance >= sum of all user balances
     * This should hold after ANY sequence of operations
     */
    function invariant_BalanceIntegrity() public {
        uint256 totalUserBalance = 0;

        address user1 = address(0x1);
        address user2 = address(0x2);

        totalUserBalance += vault.getBalance(user1);
        totalUserBalance += vault.getBalance(user2);

        assertLe(totalUserBalance, vault.getTotalBalance());
    }

    /**
     * @notice Invariant: Cannot have negative balance
     */
    function invariant_NoNegativeBalance() public {
        assertGe(vault.getTotalBalance(), 0);
    }
}
```

**Run Invariant Tests**:

```bash
# Run all invariant tests
forge test --match-test invariant

# Run with more sequences
forge test --invariant-runs 1000

# View invariant test details
forge test -vvv --match-test invariant
```

#### Understanding Invariant Test Flow

```
1. setUp() runs once
2. Handler is created
3. Foundry generates random sequences of handler function calls
4. After each sequence:
   - invariant_* functions are called
   - If invariant fails, Foundry shrinks the sequence to minimal reproduction
5. Reports minimal failing case
```

**Example: ERC20 Invariants**

```solidity
contract ERC20Invariants is Test {
    Token token;

    function setUp() public {
        token = new Token();
    }

    // Sum of all balances = total supply
    function invariant_BalanceSum() public {
        assertEq(
            token.balanceOf(user1) + token.balanceOf(user2),
            token.totalSupply()
        );
    }

    // Approved amount <= balance
    function invariant_ApprovedAmountLeqBalance() public {
        assertLe(
            token.allowance(user1, user2),
            token.balanceOf(user1)
        );
    }

    // Cannot transfer more than balance
    function invariant_NoTransferAboveBalance() public {
        vm.expectRevert();
        token.transfer(user2, token.balanceOf(user1) + 1);
    }
}
```

---

## Gas Snapshots and Profiling {#gas-profiling}

### Gas Report with `--gas-report`

```bash
# Generate gas report for all tests
forge test --gas-report

# Generate gas report for specific contract
forge test --match-contract CounterTest --gas-report

# Generate gas report and save to file
forge test --gas-report > gas_report.txt
```

**Sample Gas Report Output**:

```
╭────────────────────────────────┬─────────────┬────────┬────────┬────────╮
│ src/Counter.sol:Counter        ┆ Size (B)    ┆ Times  ┆ Min    ┆ Max    │
├────────────────────────────────┼─────────────┼────────┼────────┼────────┤
│ increment()                    ┆             ┆ 2      ┆ 22315  ┆ 22363  │
│ setNumber(uint256)             ┆             ┆ 3      ┆ 22393  ┆ 22441  │
│ Deployment Cost                ┆ 59115       ┆        ┆        ┆        │
╰────────────────────────────────┴─────────────┴────────┴────────┴────────╯
```

### Gas Snapshots with `snapshot`

Create a baseline of gas costs and track changes.

```bash
# Create initial snapshot
forge snapshot

# Creates .gas-snapshot file with gas costs:
# Counter::increment() (gas: 22315)
# Counter::setNumber(uint256) (gas: 22393)

# After changes, compare:
forge snapshot --diff

# View the difference from last snapshot
forge snapshot --check
```

#### `.gas-snapshot` File Example

```
src/Counter.sol:CounterTest:test_Increment() (gas: 28328)
src/Counter.sol:CounterTest:test_SetNumber() (gas: 31041)
src/Counter.sol:CounterTest:testFuzz_SetNumber(uint256) (gas: 31089)
src/Token.sol:TokenTest:test_Transfer() (gas: 52150)
src/Token.sol:TokenTest:test_Approve() (gas: 28995)
```

### Manual Gas Measurement

```solidity
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Counter.sol";

contract GasProfilingTest is Test {
    Counter counter;

    function setUp() public {
        counter = new Counter();
    }

    /**
     * @notice Measure gas for cold storage write
     */
    function test_GasColdStorageWrite() public {
        uint256 gasBefore = gasleft();
        counter.increment(); // First write to storage slot
        uint256 gasUsed = gasBefore - gasleft();

        // Cold storage writes are expensive (~22,000 gas)
        emit log_named_uint("Cold storage write gas", gasUsed);
        assertTrue(gasUsed > 20000);
    }

    /**
     * @notice Measure gas for warm storage write
     */
    function test_GasWarmStorageWrite() public {
        counter.increment(); // First access (cold)

        uint256 gasBefore = gasleft();
        counter.increment(); // Second access (warm)
        uint256 gasUsed = gasBefore - gasleft();

        // Warm storage writes are cheaper (~5,000 gas)
        emit log_named_uint("Warm storage write gas", gasUsed);
        assertTrue(gasUsed < 10000);
    }

    /**
     * @notice Compare memory vs storage operations
     */
    function test_CompareMemoryVsStorage() public {
        // Storage operation
        uint256 gasBefore = gasleft();
        counter.increment();
        uint256 storageGas = gasBefore - gasleft();

        // Memory operation (much cheaper)
        uint256[] memory arr = new uint256[](10);
        gasBefore = gasleft();
        for (uint256 i = 0; i < 10; i++) {
            arr[i] = i;
        }
        uint256 memoryGas = gasBefore - gasleft();

        emit log_named_uint("Storage gas", storageGas);
        emit log_named_uint("Memory gas", memoryGas);
        assertTrue(memoryGas < storageGas); // Memory is cheaper
    }

    /**
     * @notice Benchmark function execution
     */
    function test_FunctionBenchmark() public {
        uint256 iterations = 100;
        uint256 gasBefore = gasleft();

        for (uint256 i = 0; i < iterations; i++) {
            counter.increment();
        }

        uint256 totalGas = gasBefore - gasleft();
        uint256 gasPerCall = totalGas / iterations;

        emit log_named_uint("Total gas", totalGas);
        emit log_named_uint("Gas per call (avg)", gasPerCall);
    }

    /**
     * @notice Show detailed gas breakdown
     */
    function test_DetailedGasBreakdown() public {
        // Setup gas
        uint256 setupGas = gasleft();
        Counter tempCounter = new Counter(); // ~110k deployment
        setupGas = setupGas - gasleft();

        // Execution gas
        uint256 execGas = gasleft();
        tempCounter.increment();
        execGas = execGas - gasleft();

        emit log_named_uint("Deployment gas", setupGas);
        emit log_named_uint("Execution gas", execGas);
    }
}
```

**View Gas Details**:

```bash
# Show detailed gas info
forge test --gas-report -vv

# Match specific test and show gas
forge test --match-test test_GasColdStorageWrite -vvv
```

### Gas Optimization Analysis

```solidity
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

/**
 * @notice Compare gas costs of different implementations
 */
contract GasOptimizationTest is Test {

    /**
     * @notice Inefficient: multiple storage reads
     */
    function inefficient_Increment() public {
        uint256 currentValue = value; // Storage read: 2100 gas
        uint256 result = currentValue + 1;
        value = result; // Storage write: 2900 gas
    }

    /**
     * @notice Efficient: single storage operation
     */
    function efficient_Increment() public {
        unchecked { value++; } // Single operation: ~5000 gas
    }

    function test_CompareIncrementGas() public {
        // Measure inefficient
        uint256 gasBefore = gasleft();
        for (uint256 i = 0; i < 10; i++) {
            inefficient_Increment();
        }
        uint256 inefficientGas = gasBefore - gasleft();

        // Measure efficient
        gasBefore = gasleft();
        for (uint256 i = 0; i < 10; i++) {
            efficient_Increment();
        }
        uint256 efficientGas = gasBefore - gasleft();

        emit log_named_uint("Inefficient approach gas", inefficientGas);
        emit log_named_uint("Efficient approach gas", efficientGas);

        // Efficient should use less gas
        assertTrue(efficientGas < inefficientGas);
    }
}
```

---

## Foundry Scripts for Deployment {#foundry-scripts}

### Script Structure

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/Counter.sol";

/**
 * @notice Deployment script for Counter contract
 * @dev Run with: forge script script/Deploy.s.sol
 */
contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        // Get private key from environment
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        // Start broadcast (all subsequent calls will be recorded)
        vm.startBroadcast(deployerKey);

        // Deploy the contract
        Counter counter = new Counter();

        // Stop broadcast
        vm.stopBroadcast();

        // Log the deployed address
        console.log("Counter deployed to:", address(counter));
    }
}
```

### Running Scripts

```bash
# Simulate the script (dry run, no state changes)
forge script script/Deploy.s.sol

# Simulate on testnet
forge script script/Deploy.s.sol --fork-url $SEPOLIA_RPC_URL

# Broadcast to network
forge script script/Deploy.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast

# Verify contract after deployment
forge script script/Deploy.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_KEY

# Show transaction data without executing
forge script script/Deploy.s.sol --broadcast --sig "run()"
```

### Advanced Deployment Patterns

#### Multi-Stage Deployment

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/Token.sol";
import "../src/Vault.sol";

contract DeployFullStack is Script {
    function run() public {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        // Stage 1: Deploy Token
        Token token = new Token("MyToken", "MTK");
        console.log("Token deployed:", address(token));

        // Stage 2: Deploy Vault
        Vault vault = new Vault(address(token));
        console.log("Vault deployed:", address(vault));

        // Stage 3: Configure permissions
        token.grantRole(token.MINTER_ROLE(), address(vault));
        console.log("Minter role granted to vault");

        // Stage 4: Set vault as beneficiary
        vault.setBeneficiary(vm.envAddress("BENEFICIARY"));
        console.log("Beneficiary set");

        vm.stopBroadcast();
    }
}
```

#### Conditional Deployment

```solidity
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/Counter.sol";

/**
 * @notice Only deploy if contract doesn't exist at expected address
 */
contract SmartDeploy is Script {
    function run() public {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address expectedAddress = vm.envAddress("EXPECTED_ADDRESS");

        // Check if already deployed
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(expectedAddress)
        }

        if (codeSize == 0) {
            // Not deployed, deploy now
            vm.startBroadcast(deployerKey);
            Counter counter = new Counter();
            vm.stopBroadcast();

            console.log("Deployed new Counter:", address(counter));
        } else {
            console.log("Counter already exists at:", expectedAddress);
        }
    }
}
```

#### Upgrade Pattern (Proxy)

```solidity
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/Counter.sol";

contract DeployUpgradeable is Script {
    function run() public {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        // Deploy implementation
        Counter counterImpl = new Counter();
        console.log("Implementation deployed:", address(counterImpl));

        // Deploy proxy pointing to implementation
        bytes memory initData = abi.encodeWithSignature("initialize()");
        ERC1967Proxy proxy = new ERC1967Proxy(address(counterImpl), initData);
        console.log("Proxy deployed:", address(proxy));

        vm.stopBroadcast();
    }
}
```

### Script with Constructor Arguments

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/Token.sol";

contract DeployToken is Script {
    function run() public {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        // Get constructor arguments from environment
        string memory name = vm.envString("TOKEN_NAME");
        string memory symbol = vm.envString("TOKEN_SYMBOL");
        uint256 initialSupply = vm.envUint("INITIAL_SUPPLY");

        vm.startBroadcast(deployerKey);

        Token token = new Token(name, symbol, initialSupply);

        vm.stopBroadcast();

        console.log("Token deployed:", address(token));
        console.log("Name:", name);
        console.log("Symbol:", symbol);
        console.log("Supply:", initialSupply);
    }
}
```

**Run with arguments**:

```bash
# Set environment variables
export TOKEN_NAME="MyToken"
export TOKEN_SYMBOL="MTK"
export INITIAL_SUPPLY="1000000000000000000000000"

forge script script/DeployToken.s.sol \
  --broadcast \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

---

## Cast for Contract Interaction {#cast-interaction}

`cast` is the CLI tool for interacting with smart contracts and Ethereum RPC endpoints.

### Call vs Send

```bash
# Call (read-only, no transaction)
cast call <CONTRACT> "balanceOf(address)(uint256)" <ADDRESS>

# Send (state-changing, requires signature)
cast send <CONTRACT> "transfer(address,uint256)" <TO> <AMOUNT> \
  --private-key <PRIVATE_KEY>
```

### Common Commands

#### Reading State

```bash
# Call a view/pure function
cast call 0x1234... "name()(string)" --rpc-url $RPC_URL

# Get balance of an address
cast balance <ADDRESS> --rpc-url $RPC_URL

# Get balance in Ether
cast balance <ADDRESS> --ether --rpc-url $RPC_URL

# Get code at an address
cast code <CONTRACT> --rpc-url $RPC_URL

# Get storage value at slot
cast storage <CONTRACT> <SLOT> --rpc-url $RPC_URL

# Get nonce
cast nonce <ADDRESS> --rpc-url $RPC_URL
```

#### Sending Transactions

```bash
# Send transaction
cast send <TO> "functionName(arg1Type,arg2Type)" <arg1> <arg2> \
  --private-key <PRIVATE_KEY> \
  --rpc-url $RPC_URL

# Transfer ETH
cast send <RECIPIENT> --value 1ether \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL

# Set gas price
cast send <TO> "functionName()" \
  --private-key $PRIVATE_KEY \
  --gas-price 50gwei \
  --rpc-url $RPC_URL

# Set gas limit
cast send <TO> "functionName()" \
  --private-key $PRIVATE_KEY \
  --gas 200000 \
  --rpc-url $RPC_URL
```

### Data Encoding/Decoding

```bash
# Encode function call
cast calldata "transfer(address,uint256)" 0x123... 100

# Decode calldata
cast decode <FUNCTION_SIGNATURE> <CALLDATA>

# Get function selector (4 bytes)
cast sig "transfer(address,uint256)"

# Decode logs/events
cast decode-event "Transfer(address,address,uint256)" <LOG_DATA>

# ABI encode
cast abi-encode "test(uint256,address)" 123 0x123...
```

### Practical Examples

#### Token Interaction

```bash
# Check balance
cast call 0xTokenAddress "balanceOf(address)(uint256)" 0xMyAddress

# Approve spending
cast send 0xTokenAddress \
  "approve(address,uint256)" \
  0xSpenderAddress \
  1000000000000000000 \  # 1 token with 18 decimals
  --private-key $PRIVATE_KEY

# Transfer tokens
cast send 0xTokenAddress \
  "transfer(address,uint256)" \
  0xRecipient \
  1000000000000000000 \
  --private-key $PRIVATE_KEY
```

#### NFT Interaction

```bash
# Get owner of token
cast call 0xNFTAddress "ownerOf(uint256)(address)" 1

# Approve NFT transfer
cast send 0xNFTAddress \
  "approve(address,uint256)" \
  0xSpender \
  1 \
  --private-key $PRIVATE_KEY

# Transfer NFT
cast send 0xNFTAddress \
  "safeTransferFrom(address,address,uint256)" \
  0xFrom \
  0xTo \
  1 \
  --private-key $PRIVATE_KEY
```

#### Custom Contract Interaction

```bash
# Call increment function
cast send 0xCounterAddress "increment()" \
  --private-key $PRIVATE_KEY \
  --rpc-url http://localhost:8545

# Get current count
cast call 0xCounterAddress "count()(uint256)"

# Set number with parameters
cast send 0xCounterAddress "setNumber(uint256)" 42 \
  --private-key $PRIVATE_KEY
```

### Batch Operations

```bash
# Use cast in a loop to send multiple transactions
for i in {1..10}; do
  cast send 0xContract \
    "mint(address)" \
    0xMinter \
    --private-key $PRIVATE_KEY \
    --rpc-url $RPC_URL
done
```

---

## Anvil for Local Testing {#anvil-testing}

Anvil is a local Ethereum node for testing and development.

### Starting Anvil

```bash
# Start with default settings
anvil

# Start on specific port
anvil -p 8546

# Start with specific account
anvil --accounts 5

# Fork mainnet
anvil --fork-url $MAINNET_RPC_URL

# Fork specific block
anvil --fork-url $MAINNET_RPC_URL --fork-block-number 12345678

# Enable features
anvil --enable-min-gas-price

# Set block time
anvil --block-time 2 # Mine a block every 2 seconds
```

**Default Anvil Setup**:
- 10 accounts with 10,000 ETH each
- RPC available at `http://localhost:8545`
- Chain ID: 31337
- All transactions are mined instantly

### Using Anvil with Foundry

#### Terminal 1: Start Anvil

```bash
anvil
```

Output:
```
Listening on 127.0.0.1:8545
Account #0: 0x1234...
Private Key: 0xabcd...
```

#### Terminal 2: Deploy and Test

```bash
# Deploy contract to local node
forge script script/Deploy.s.sol \
  --broadcast \
  --rpc-url http://localhost:8545

# Run tests against local node
forge test --rpc-url http://localhost:8545

# Interact with deployed contract
cast call 0xDeployedAddress "getCount()(uint256)" \
  --rpc-url http://localhost:8545
```

### Forking with Anvil

```bash
# Fork mainnet at latest block
anvil --fork-url https://eth.rpc.blxrbdn.com

# Fork at specific block
anvil --fork-url https://eth.rpc.blxrbdn.com --fork-block-number 17000000

# Fork and set auto-mine off (manual mining)
anvil --fork-url https://eth.rpc.blxrbdn.com --no-mining
```

### Testing on Fork

```solidity
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

/**
 * @notice Test against forked mainnet state
 * @dev Run with: forge test --fork-url $MAINNET_RPC_URL
 */
contract ForkTest is Test {
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDC_WHALE = 0xae2D4617c4d5B142Dab8D539E03197601FA1DCA6;

    function setUp() public {
        // Create fork at latest block
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));
    }

    function test_TransferFromWhale() public {
        // In fork, we can use real whale account
        vm.prank(USDC_WHALE);

        (bool success,) = USDC.call(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                address(this),
                1000e6  // 1000 USDC
            )
        );

        assertTrue(success);
    }
}
```

### Anvil RPC Methods

```bash
# Mine block
cast rpc evm_mine --rpc-url http://localhost:8545

# Set block time
cast rpc evm_setBlockGasLimit 30000000 --rpc-url http://localhost:8545

# Get chain ID
cast chain-id --rpc-url http://localhost:8545

# Get latest block
cast block latest --rpc-url http://localhost:8545

# Get gas price
cast gas-price --rpc-url http://localhost:8545
```

---

## Foundry.toml Configuration {#foundry-config}

The `foundry.toml` file configures Forge behavior.

### Complete Example

```toml
[profile.default]
# Paths
src = "src"
test = "test"
out = "out"
libs = ["lib"]
cache_path = "cache"

# Compiler settings
solc_version = "0.8.20"
optimizer = true
optimizer_runs = 200
evm_version = "paris"

# Output
extra_output = ["storageLayout", "metadata"]
extra_output_files = ["storageLayout"]

# Testing
via_ir = false  # Use legacy code generation

# RPC endpoints
[rpc_endpoints]
mainnet = "https://eth.rpc.blxrbdn.com"
sepolia = "https://rpc.sepolia.org"
localhost = "http://localhost:8545"

# Etherscan configuration
[etherscan]
mainnet = { key = "${ETHERSCAN_KEY}", url = "https://api.etherscan.io/api" }
sepolia = { key = "${ETHERSCAN_KEY}", url = "https://api-sepolia.etherscan.io/api" }

# Formatter settings
[fmt]
line_length = 100
tab_width = 4
bracket_spacing = true
int_types = "long"
function_attributes = ["view", "pure", "override", "public"]

# Profile-specific settings
[profile.heavy]
optimizer = true
optimizer_runs = 10000

[profile.test]
optimizer = false
```

### Common Settings

```toml
# Use IR compilation (faster compilation, better optimization)
via_ir = true

# Verbosity (0-5)
verbosity = 2

# Gas reporting
gas_reports = ["*"]  # Report gas for all contracts

# Remappings for imports
remappings = [
    "openzeppelin=lib/openzeppelin-contracts/contracts/",
    "@=./src/"
]

# Fuzz settings
[fuzz]
runs = 256
max_test_rejects = 65536
seed = 0x4242424242  # Use specific seed for reproducibility

# Invariant settings
[invariant]
runs = 256
depth = 15
fail_on_revert = false
```

---

## Advanced Testing Patterns {#advanced-patterns}

### Test Organization

```solidity
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyContract.sol";

/**
 * @notice Well-organized test suite with clear sections
 */
contract MyContractTest is Test {
    MyContract contract;
    address owner;
    address user;

    event ContractDeployed(address indexed contractAddress);

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // SETUP
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    function setUp() public {
        owner = address(this);
        user = address(0x1);
        contract = new MyContract();
        vm.label(owner, "Owner");
        vm.label(user, "User");
    }

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // CONSTRUCTOR TESTS
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    function test_InitialState() public {
        assertTrue(contract.isInitialized());
        assertEq(contract.owner(), owner);
    }

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // STATE MODIFICATION TESTS
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    function test_SetValue() public {
        contract.setValue(42);
        assertEq(contract.getValue(), 42);
    }

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // REVERT TESTS
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    function test_RevertWhenUnauthorized() public {
        vm.prank(user);
        vm.expectRevert("Unauthorized");
        contract.onlyOwnerFunction();
    }

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // EVENT TESTS
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    function test_EmitsEvent() public {
        vm.expectEmit(true, false, false, true);
        emit MyContract.ValueChanged(42);
        contract.setValue(42);
    }

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // FUZZ TESTS
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    function testFuzz_SetAnyValue(uint256 value) public {
        contract.setValue(value);
        assertEq(contract.getValue(), value);
    }

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // GAS TESTS
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    function test_Gas_SetValue() public {
        uint256 gasBefore = gasleft();
        contract.setValue(42);
        uint256 gasUsed = gasBefore - gasleft();
        assertTrue(gasUsed < 30000);
    }

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // INVARIANT TESTS
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    function invariant_ValueNeverOverflows() public {
        assertLe(contract.getValue(), type(uint256).max);
    }
}
```

### Testing Complex Interactions

```solidity
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AMM.sol";
import "../src/Token.sol";

contract AMMTest is Test {
    AMM amm;
    Token tokenA;
    Token tokenB;
    address trader = address(0x1);

    function setUp() public {
        // Deploy tokens
        tokenA = new Token("Token A", "TKA");
        tokenB = new Token("Token B", "TKB");

        // Deploy AMM
        amm = new AMM(address(tokenA), address(tokenB));

        // Mint tokens to trader
        tokenA.mint(trader, 1000e18);
        tokenB.mint(trader, 1000e18);

        // Approve AMM to spend tokens
        vm.prank(trader);
        tokenA.approve(address(amm), type(uint256).max);
        vm.prank(trader);
        tokenB.approve(address(amm), type(uint256).max);
    }

    function test_AddLiquidityAndSwap() public {
        // Add liquidity
        vm.prank(trader);
        (uint256 lpTokens) = amm.addLiquidity(100e18, 100e18);
        assertGt(lpTokens, 0);

        // Swap
        uint256 tokenBBefore = tokenB.balanceOf(trader);
        vm.prank(trader);
        amm.swap(address(tokenA), 10e18);
        uint256 tokenBAfter = tokenB.balanceOf(trader);

        // Verify swap happened
        assertGt(tokenBAfter, tokenBBefore);
    }

    function testFuzz_SwapsRespectSlippage(uint256 amountIn) public {
        amountIn = bound(amountIn, 1e18, 100e18);

        vm.prank(trader);
        amm.addLiquidity(1000e18, 1000e18);

        uint256 expectedOut = (amountIn * 1000e18) / (1000e18 + amountIn);

        vm.prank(trader);
        uint256 actualOut = amm.swap(address(tokenA), amountIn);

        // Allow 0.3% slippage
        assertGe(actualOut, (expectedOut * 997) / 1000);
    }

    function invariant_ConstantProductFormula() public {
        uint256 reserveA = tokenA.balanceOf(address(amm));
        uint256 reserveB = tokenB.balanceOf(address(amm));

        // x * y = k (approximately)
        uint256 k = reserveA * reserveB;
        assertTrue(k >= amm.lastK() || reserveA == 0 || reserveB == 0);
    }
}
```

### Testing Access Control

```solidity
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AccessControlledContract.sol";

contract AccessControlTest is Test {
    AccessControlledContract contract;
    address owner = address(0x1);
    address admin = address(0x2);
    address user = address(0x3);
    address attacker = address(0x4);

    function setUp() public {
        contract = new AccessControlledContract();
        contract.grantRole(contract.ADMIN_ROLE(), admin);
        contract.grantRole(contract.USER_ROLE(), user);
    }

    function test_OnlyOwnerCanDoSomething() public {
        vm.prank(owner);
        contract.ownerOnlyFunction(); // Should succeed

        vm.prank(user);
        vm.expectRevert();
        contract.ownerOnlyFunction(); // Should fail
    }

    function test_RoleBasedAccess() public {
        vm.prank(admin);
        contract.adminFunction(); // Admin can call

        vm.prank(user);
        vm.expectRevert();
        contract.adminFunction(); // User cannot call
    }

    function test_RoleEscalation() public {
        vm.prank(user);
        vm.expectRevert();
        contract.grantRole(contract.ADMIN_ROLE(), address(0x5)); // Cannot grant role
    }

    function test_AttackerCannotBypass() public {
        vm.prank(attacker);
        vm.expectRevert();
        contract.sensitiveFunction();
    }
}
```

### Benchmarking and Comparison

```solidity
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/OptimizedMath.sol";
import "../src/UnoptimizedMath.sol";

contract MathOptimizationTest is Test {
    OptimizedMath optimized;
    UnoptimizedMath unoptimized;

    function setUp() public {
        optimized = new OptimizedMath();
        unoptimized = new UnoptimizedMath();
    }

    function test_BothProduceSameResult() public {
        uint256 a = 12345;
        uint256 b = 67890;

        uint256 optimizedResult = optimized.complexCalculation(a, b);
        uint256 unoptimizedResult = unoptimized.complexCalculation(a, b);

        assertEq(optimizedResult, unoptimizedResult);
    }

    function test_OptimizedIsMoreEfficient() public {
        uint256 a = 12345;
        uint256 b = 67890;

        uint256 optimizedGas;
        uint256 unoptimizedGas;

        // Measure optimized
        uint256 gasBefore = gasleft();
        optimized.complexCalculation(a, b);
        optimizedGas = gasBefore - gasleft();

        // Measure unoptimized
        gasBefore = gasleft();
        unoptimized.complexCalculation(a, b);
        unoptimizedGas = gasBefore - gasleft();

        emit log_named_uint("Optimized gas", optimizedGas);
        emit log_named_uint("Unoptimized gas", unoptimizedGas);

        assertLt(optimizedGas, unoptimizedGas);
    }

    function testFuzz_BothProduceSameResult(uint256 a, uint256 b) public {
        a = bound(a, 1, type(uint128).max);
        b = bound(b, 1, type(uint128).max);

        uint256 optimizedResult = optimized.complexCalculation(a, b);
        uint256 unoptimizedResult = unoptimized.complexCalculation(a, b);

        assertEq(optimizedResult, unoptimizedResult);
    }
}
```

### Testing State Transitions

```solidity
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Auction.sol";

contract AuctionStateTest is Test {
    Auction auction;
    address bidder1 = address(0x1);
    address bidder2 = address(0x2);

    function setUp() public {
        auction = new Auction(30 minutes);
        vm.deal(bidder1, 100 ether);
        vm.deal(bidder2, 100 ether);
    }

    function test_StateTransitions() public {
        // Initial state: RUNNING
        assertEq(uint8(auction.state()), uint8(Auction.State.RUNNING));

        // Place bids
        vm.prank(bidder1);
        auction.bid{value: 1 ether}();

        // Still running
        assertEq(uint8(auction.state()), uint8(Auction.State.RUNNING));

        // Warp to end
        vm.warp(block.timestamp + 31 minutes);

        // Now should be ENDED
        assertEq(uint8(auction.state()), uint8(Auction.State.ENDED));

        // Cannot bid after ended
        vm.prank(bidder2);
        vm.expectRevert("Auction ended");
        auction.bid{value: 1 ether}();

        // Can finalize
        auction.finalize();
        assertEq(uint8(auction.state()), uint8(Auction.State.FINALIZED));
    }
}
```

### Testing Edge Cases and Boundaries

```solidity
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SafeMath.sol";

contract EdgeCaseTest is Test {
    SafeMath math;

    function setUp() public {
        math = new SafeMath();
    }

    function test_MaxValues() public {
        uint256 result = math.add(type(uint256).max - 1, 1);
        assertEq(result, type(uint256).max);
    }

    function test_OverflowReverts() public {
        vm.expectRevert();
        math.add(type(uint256).max, 1);
    }

    function test_ZeroValues() public {
        assertEq(math.add(0, 0), 0);
        assertEq(math.add(0, 123), 123);
        assertEq(math.add(123, 0), 123);
    }

    function test_Boundaries() public {
        // Test boundaries of common divisions
        assertEq(math.divide(100, 10), 10);
        assertEq(math.divide(100, 3), 33);
        assertEq(math.divide(1, 2), 0);

        // Division by zero reverts
        vm.expectRevert();
        math.divide(100, 0);
    }

    function testFuzz_BoundariesWithFuzzing(uint256 x, uint256 y) public {
        y = bound(y, 1, type(uint256).max); // Avoid division by zero

        uint256 result = math.divide(x, y);
        assertLe(result, x);
    }
}
```

---

## Best Practices Summary

### Testing Checklist

- **Happy Path**: Normal operations work correctly
- **Edge Cases**: Empty inputs, max values, zero addresses
- **Reverts**: Invalid operations fail with correct errors
- **Events**: State changes emit correct events
- **Gas**: Measure costs of critical operations
- **Access Control**: Unauthorized access is prevented
- **State Consistency**: Invariants always hold
- **Fuzz Testing**: Properties hold for random inputs

### Command Reference

```bash
# Complete testing workflow
forge build                                      # Build contracts
forge test                                       # Run all tests
forge test --gas-report                         # With gas report
forge test -vvv                                 # Verbose output
forge test --match-test test_specific           # Specific test
forge snapshot                                  # Create gas baseline
forge coverage                                  # Code coverage

# Deployment
forge script script/Deploy.s.sol --broadcast \
  --rpc-url $RPC \
  --private-key $KEY \
  --verify

# Interaction
cast call 0xAddress "function()(type)" args --rpc-url $RPC
cast send 0xAddress "function(type)" args \
  --private-key $KEY --rpc-url $RPC
```

---

## Useful Resources

- **Foundry Book**: https://book.getfoundry.sh/
- **Forge-std**: https://github.com/foundry-rs/forge-std
- **Solidity Docs**: https://docs.soliditylang.org/
- **OpenZeppelin Docs**: https://docs.openzeppelin.com/
- **Ethereum Yellow Paper**: https://ethereum.org/en/whitepaper/

---

## Quick Links to Repository Projects

Each project in this repository demonstrates specific Foundry patterns:

- **Project 01**: Basic test setup, unit tests, fuzz tests
- **Project 05**: Custom errors, revert testing
- **Project 07**: Reentrancy testing with cheatcodes
- **Project 11**: Complex vault testing with invariants

Explore the `test/` directories in each project for real-world examples!

---

**Remember**: Tests are your safety net. Write them before deploying to production.

*Happy testing!*

---

# Part 4: Gas Optimization

# Solidity Gas Optimization Guide

A comprehensive guide to optimizing gas consumption in Solidity smart contracts. This guide covers practical techniques with concrete examples and gas cost comparisons.

## Table of Contents
1. [Storage Optimization](#storage-optimization)
2. [Memory vs Calldata](#memory-vs-calldata)
3. [External vs Public Functions](#external-vs-public-functions)
4. [Custom Errors vs Require Strings](#custom-errors-vs-require-strings)
5. [Immutable and Constant Variables](#immutable-and-constant-variables)
6. [Batch Operations](#batch-operations)
7. [Unchecked Math Blocks](#unchecked-math-blocks)
8. [Short-Circuit Evaluation](#short-circuit-evaluation)
9. [Loop Optimization](#loop-optimization)
10. [Minimal Proxy Patterns](#minimal-proxy-patterns)
11. [Advanced Techniques](#advanced-techniques)

---

## Storage Optimization

### Overview
Storage is one of the most expensive operations in Solidity. Each storage slot is 32 bytes. Optimizing storage layout can significantly reduce gas costs.

### Packing Variables

**Problem: Inefficient Storage Layout**
```solidity
// BEFORE: Inefficient - 3 slots
contract BadPacking {
    uint256 public amount;      // Slot 0: 32 bytes
    bool public isActive;       // Slot 1: 1 byte (wastes 31 bytes)
    address public owner;       // Slot 2: 20 bytes (wastes 12 bytes)
    uint16 public id;           // Slot 3: 2 bytes (wastes 30 bytes)
}

// Gas cost for storage: ~20,000 per slot initialization
// Total: ~60,000 gas for initialization
```

**Solution: Pack Variables Efficiently**
```solidity
// AFTER: Efficient - 2 slots
contract GoodPacking {
    uint256 public amount;          // Slot 0: 32 bytes
    address public owner;           // Slot 1: 20 bytes
    uint16 public id;               // Slot 1: 2 bytes (total: 22 bytes in slot 1)
    bool public isActive;           // Slot 1: 1 byte (total: 23 bytes in slot 1)
}

// Gas cost for storage: ~20,000 per slot
// Total: ~40,000 gas for initialization
// SAVINGS: ~20,000 gas (33% reduction)
```

**Why This Works:**
- Variables are packed into 32-byte slots
- Smaller data types (uint16, uint8, bool) can share a slot with larger types
- Reading/writing packed slots still costs the same, but fewer slots = fewer SSTORE operations

### Struct Packing Example

```solidity
// BEFORE: 4 storage slots
struct UserBad {
    address user;           // Slot 0: 20 bytes
    uint256 balance;        // Slot 1: 32 bytes
    uint8 status;           // Slot 2: 1 byte
    bool isActive;          // Slot 3: 1 byte
}

// AFTER: 2 storage slots
struct UserGood {
    address user;           // Slot 0: 20 bytes
    uint8 status;           // Slot 0: 1 byte
    bool isActive;          // Slot 0: 1 byte
    uint256 balance;        // Slot 1: 32 bytes
}
```

### Slot Layout Best Practices

```solidity
pragma solidity ^0.8.0;

contract OptimizedStorage {
    // Slot 0: 32 bytes total
    uint256 public largeNumber;     // 32 bytes

    // Slot 1: 23 bytes used, 9 bytes wasted
    address public owner;           // 20 bytes
    uint8 public statusCode;        // 1 byte
    bool public isInitialized;      // 1 byte
    uint8 public tierLevel;         // 1 byte

    // Slot 2: 32 bytes total
    uint256 public timestamp;       // 32 bytes

    // Slot 3: 16 bytes used
    uint128 public minAmount;       // 16 bytes
    uint64 public maxAmount;        // 8 bytes

    // Dynamic arrays and mappings use additional hash-calculated slots
    mapping(address => uint256) public balances;
    uint256[] public history;
}

// Gas Cost Summary:
// - 3-4 SSTORE operations for initialization
// - Each SSTORE: 20,000 gas (first time), 5,000 (subsequent)
// - Total initialization: ~60,000-80,000 gas
```

**Key Rules:**
1. Group smaller data types together
2. Put the largest variables first
3. Keep frequently accessed variables in the same slot
4. Use smaller int types (uint8, uint16) instead of uint256 when possible

**Gas Savings:**
- Efficient packing: 25-40% reduction in storage operations
- Per slot saved: ~15,000 gas for initialization

---

## Memory vs Calldata

### Overview
Calldata is cheaper than memory because it's read-only external data. Using calldata reduces memory allocation costs.

**Example: Array Parameter Handling**

```solidity
// BEFORE: Using memory (expensive)
contract BadMemoryUsage {
    function processArray(uint256[] memory data) public pure returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < data.length; i++) {
            sum += data[i];
        }
        return sum;
    }
    // Gas cost for memory allocation: ~3,000-5,000 gas
    // Gas cost for copying: ~60 gas per 32-byte word
    // Example: 10 items = ~10 * 60 = 600 gas for copy
    // Total: ~3,600-5,600 gas
}

// AFTER: Using calldata (cheaper)
contract GoodCalldataUsage {
    function processArray(uint256[] calldata data) public pure returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < data.length; i++) {
            sum += data[i];
        }
        return sum;
    }
    // Gas cost: 0 for calldata (external data)
    // Just read cost: ~3 gas per item
    // Example: 10 items = ~30 gas
    // SAVINGS: ~3,570 gas (64% reduction)
}
```

**String Parameter Example:**

```solidity
// BEFORE: Memory string
contract BadString {
    event LogMessage(string indexed message);

    function logData(string memory message) external {
        emit LogMessage(message);
    }
    // Gas cost: Memory allocation for string
}

// AFTER: Calldata string
contract GoodString {
    event LogMessage(string indexed message);

    function logData(string calldata message) external {
        emit LogMessage(message);
    }
    // SAVINGS: 50-80% gas for external calls
}
```

**When to Use Calldata:**
- External functions with array/string parameters
- Read-only data processing
- Function arguments (not local variables)

**When to Use Memory:**
- Internal functions
- Local variable manipulation
- Data transformations

**Gas Comparison Table:**
| Operation | Calldata | Memory | Savings |
|-----------|----------|--------|---------|
| Read 10 uint256 | ~30 gas | ~600 gas | 95% |
| Pass string | 0 gas | ~variable | variable |
| Modify array | ❌ Cannot | ✅ Yes | N/A |

---

## External vs Public Functions

### Overview
External functions are cheaper than public functions for receiving external calls because they use calldata directly, while public functions must copy parameters to memory.

**Direct Comparison:**

```solidity
// BEFORE: Using public (less efficient)
contract PublicFunction {
    function processData(uint256[] memory data) public pure returns (uint256) {
        return data.length;
    }

    // Caller sends: [1, 2, 3, 4, 5] (5 uint256s)
    // Gas cost:
    // - CALLDATACOPY: copies all data to memory: ~5 * 16 = 80 gas
    // - MSTORE: memory allocation overhead: ~20 gas
    // Total external call: ~100 gas overhead
}

// AFTER: Using external (more efficient)
contract ExternalFunction {
    function processData(uint256[] calldata data) external pure returns (uint256) {
        return data.length;
    }

    // Caller sends: [1, 2, 3, 4, 5]
    // Gas cost:
    // - No CALLDATACOPY needed: 0 gas
    // - No memory allocation: 0 gas
    // Total external call: 0 gas overhead
    // SAVINGS: ~100 gas (100% reduction)
}
```

**Key Difference:**

```solidity
pragma solidity ^0.8.0;

contract FunctionComparison {

    // PUBLIC function
    function publicAdd(uint256 a, uint256 b) public pure returns (uint256) {
        // Parameters must be accessible internally
        // If called externally, parameters are copied from calldata to memory
        return a + b;
    }

    // EXTERNAL function
    function externalAdd(uint256 a, uint256 b) external pure returns (uint256) {
        // Parameters stay in calldata
        // No memory copy needed
        return a + b;
    }

    // Gas Analysis for external call:
    // publicAdd: ~2,000 gas (includes memory overhead)
    // externalAdd: ~1,900 gas
    // SAVINGS: ~100 gas per call
}
```

**When to Use:**
- **External**: Functions called from outside the contract only
- **Public**: Functions that might be called internally or externally

**Gas Savings:**
- 50-100 gas per external call
- Multiplied by frequency of calls

---

## Custom Errors vs Require Strings

### Overview
Custom errors are more gas-efficient than require statements with strings, especially for large error messages.

**Detailed Comparison:**

```solidity
// BEFORE: Using require with strings (expensive)
contract BadErrorHandling {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function sensitiveFunction() external {
        require(msg.sender == owner, "Only owner can call this function");
        // Additional require
        require(msg.value > 0, "Must send some ether to this function");
        require(block.timestamp > 0, "Timestamp must be valid");
    }

    // Gas cost for require statements:
    // - String encoding: 4 + 68 = 72 bytes (very long string)
    // - Deployment cost: ~72 * 16 = 1,152 gas
    // - Runtime cost per failed require: ~21,000 gas base + storage cost
    // - For 3 requires: ~3,456 gas deployment overhead
}

// AFTER: Using custom errors (efficient)
contract GoodErrorHandling {
    address public owner;

    error UnauthorizedAccess();
    error InsufficientValue();
    error InvalidTimestamp();

    constructor() {
        owner = msg.sender;
    }

    function sensitiveFunction() external {
        if (msg.sender != owner) revert UnauthorizedAccess();
        if (msg.value == 0) revert InsufficientValue();
        if (block.timestamp == 0) revert InvalidTimestamp();
    }

    // Gas cost for custom errors:
    // - Error encoding: 4 bytes (selector) per error
    // - Deployment cost: ~4 * 3 = 12 bytes = ~192 gas total
    // - Runtime cost per failed revert: ~21,000 gas base (same)
    // SAVINGS: ~3,264 gas deployment cost (94% reduction)
}
```

**Gas Cost Breakdown:**

```solidity
pragma solidity ^0.8.19;

contract ErrorCostAnalysis {
    // Custom Errors (Recommended)
    error InvalidAmount();                              // 4 bytes selector
    error Unauthorized();                               // 4 bytes selector
    error AlreadyInitialized();                         // 4 bytes selector
    error ExceedsMaxSupply();                           // 4 bytes selector

    // If using require strings instead:
    // require(amount > 0, "Amount must be greater than 0"); // 42 bytes
    // require(msg.sender == owner, "Only owner");           // 18 bytes
    // require(!initialized, "Already initialized");         // 24 bytes
    // require(supply <= maxSupply, "Exceeds max supply");   // 25 bytes

    // Total string cost: 42 + 18 + 24 + 25 = 109 bytes
    // Deployment cost per byte: 16 gas
    // Total for require: 109 * 16 = 1,744 gas
    // Total for errors: ~48 bytes * 16 = 768 gas
    // SAVINGS: 976 gas per contract (56% reduction)

    function validateAndTransfer(
        uint256 amount,
        address recipient
    ) external {
        // Custom error approach - efficient
        if (amount == 0) revert InvalidAmount();
        if (msg.sender != owner) revert Unauthorized();

        // vs require approach - wasteful
        // require(amount > 0, "Amount must be greater than 0");
        // require(msg.sender == owner, "Only owner can call this");
    }
}
```

**Comparison Table:**

| Aspect | Require String | Custom Error | Savings |
|--------|----------------|--------------|---------|
| Deployment Cost (4 checks) | ~1,744 gas | ~768 gas | 56% |
| Runtime Cost (revert) | ~21,000 gas | ~21,000 gas | 0% |
| Readability | Good | Excellent | - |
| Error Details | String | None | - |

**Best Practices:**
```solidity
pragma solidity ^0.8.0;

// Define errors at contract level
error InvalidInput(string reason);
error InsufficientBalance(uint256 required, uint256 available);
error Unauthorized(address caller);

contract BestPractices {
    function transfer(address to, uint256 amount) external {
        if (amount == 0) revert InvalidInput("Amount cannot be zero");
        if (balances[msg.sender] < amount) {
            revert InsufficientBalance(amount, balances[msg.sender]);
        }
        if (!isApproved[msg.sender]) {
            revert Unauthorized(msg.sender);
        }

        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}
```

---

## Immutable and Constant Variables

### Overview
Immutable and constant variables reduce gas costs by avoiding storage reads and enabling compiler optimizations.

**Comparison:**

```solidity
// BEFORE: Using regular state variables (expensive)
contract BadImmutables {
    address public owner;           // Requires SLOAD: 2,100 gas per read
    uint256 public maxSupply;       // Requires SLOAD: 2,100 gas per read
    string public name;             // Requires SLOAD: 2,100 gas per read

    constructor(address _owner, uint256 _maxSupply, string memory _name) {
        owner = _owner;
        maxSupply = _maxSupply;
        name = _name;
    }

    function getOwnerAndMax() external view returns (address, uint256) {
        return (owner, maxSupply);  // 2x SLOAD = 4,200 gas
    }
}

// AFTER: Using immutable (efficient)
contract GoodImmutables {
    address public immutable owner;     // Compiled to constant: 3 gas per access
    uint256 public immutable maxSupply; // Compiled to constant: 3 gas per access
    string public immutable name;       // Compiled to constant: 3 gas per access

    constructor(address _owner, uint256 _maxSupply, string memory _name) {
        owner = _owner;
        maxSupply = _maxSupply;
        name = _name;
    }

    function getOwnerAndMax() external view returns (address, uint256) {
        return (owner, maxSupply);  // 2x access = 6 gas (vs 4,200)
        // SAVINGS: 4,194 gas (99.9% reduction)
    }
}
```

**Immutable vs Constant:**

```solidity
pragma solidity ^0.8.0;

contract ImmutableVsConstant {
    // CONSTANT: Value known at compile time
    uint256 constant public VERSION = 1;              // 3 gas per read
    address constant public ZERO_ADDRESS = address(0); // 3 gas per read

    // IMMUTABLE: Value set in constructor, then fixed
    address public immutable owner;                   // 3 gas per read
    uint256 public immutable deploymentTime;          // 3 gas per read
    uint256 public immutable initialBalance;          // 3 gas per read

    constructor() {
        owner = msg.sender;
        deploymentTime = block.timestamp;
        initialBalance = address(this).balance;
    }

    // Gas cost comparison:
    // Reading constant: 3 gas
    // Reading immutable: 3 gas
    // Reading storage variable: 2,100 gas
    // SAVINGS per read: 2,097 gas
}
```

**Real-World Example:**

```solidity
pragma solidity ^0.8.0;

// ERC20-like token with optimized gas
contract OptimizedToken {
    // Constants
    uint8 constant decimals = 18;
    uint256 constant MAX_UINT = type(uint256).max;

    // Immutables (set once in constructor)
    string public immutable name;
    string public immutable symbol;
    address public immutable admin;
    uint256 public immutable totalSupply;

    // Storage (mutable)
    mapping(address => uint256) public balances;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply
    ) {
        name = _name;
        symbol = _symbol;
        admin = msg.sender;
        totalSupply = _initialSupply;
        balances[msg.sender] = _initialSupply;
    }

    function transfer(address to, uint256 amount) external {
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    // Gas Analysis:
    // - Reading name (immutable): 3 gas
    // - Reading balances (storage): 2,100 gas
    // - Reading totalSupply (immutable): 3 gas
    // For 10 accesses per transaction:
    // - With storage: ~21,000 gas
    // - With immutable: ~30 gas
    // SAVINGS: ~20,970 gas per transaction
}
```

**When to Use:**
- **Constant**: Fixed values (MAX_SUPPLY, VERSION, etc.)
- **Immutable**: Values set at deployment, never changed (owner, deployer)

---

## Batch Operations

### Overview
Combining multiple operations reduces function call overhead and improves gas efficiency.

**Example: Batch Transfers**

```solidity
// BEFORE: Individual transfers (expensive)
contract BadBatchTransfers {
    mapping(address => uint256) public balances;

    function transfer(address to, uint256 amount) external {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    // For 10 transfers:
    // 10 * (transaction overhead + function call) = ~21,000 * 10 = 210,000 gas
}

// AFTER: Batch transfers (efficient)
contract GoodBatchTransfers {
    mapping(address => uint256) public balances;

    struct TransferData {
        address to;
        uint256 amount;
    }

    function batchTransfer(TransferData[] calldata transfers) external {
        for (uint256 i = 0; i < transfers.length; i++) {
            balances[msg.sender] -= transfers[i].amount;
            balances[transfers[i].to] += transfers[i].amount;
        }
    }

    // For 10 transfers in one call:
    // 1 * (transaction overhead + function call) + loop cost
    // = ~21,000 + (10 * 300) = ~24,000 gas
    // SAVINGS: ~186,000 gas (88% reduction)
}
```

**Batch Minting Example:**

```solidity
pragma solidity ^0.8.0;

contract BatchOptimization {
    mapping(address => uint256) public balances;

    // BAD: Multiple transactions
    function mint(address to, uint256 amount) external {
        balances[to] += amount;
    }

    // GOOD: Single transaction
    function batchMint(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external {
        require(recipients.length == amounts.length);

        for (uint256 i = 0; i < recipients.length; i++) {
            balances[recipients[i]] += amounts[i];
        }
    }

    // Gas Comparison for 100 mint operations:
    // Individual calls: 100 * ~52,000 = 5,200,000 gas
    // Batch call: 52,000 + (100 * ~300) = 82,000 gas
    // SAVINGS: ~5,118,000 gas (98% reduction)
}
```

**Batch Approval + Transfer:**

```solidity
pragma solidity ^0.8.0;

contract BatchApprovalTransfer {
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public balances;

    struct ApprovalTransferData {
        address spender;
        address to;
        uint256 amount;
    }

    function batchApproveAndTransfer(
        ApprovalTransferData[] calldata operations
    ) external {
        for (uint256 i = 0; i < operations.length; i++) {
            allowance[msg.sender][operations[i].spender] = operations[i].amount;

            balances[msg.sender] -= operations[i].amount;
            balances[operations[i].to] += operations[i].amount;
        }
    }

    // Single transaction with 50 approve+transfer operations
    // vs 100 individual transactions
    // SAVINGS: ~5,000,000 gas
}
```

**Key Benefits:**
- Reduces transaction overhead (21,000 gas per transaction)
- Single function call cost
- Saves ~20,000+ gas per reduced transaction

---

## Unchecked Math Blocks

### Overview
Solidity 0.8+ adds automatic overflow/underflow checks. For proven safe operations, using unchecked blocks saves gas.

**Example: Safe Arithmetic**

```solidity
// BEFORE: Automatic checks (expensive)
contract BadArithmetic {
    uint256 public counter;

    function increment() external {
        counter += 1;  // Compiler adds safety checks: ~100 gas overhead per operation
    }

    function decrement() external {
        counter -= 1;  // Safety checks cost gas even when unnecessary
    }

    // Gas cost: ~60 + 100 (checks) = 160 gas per operation
}

// AFTER: Unchecked safe math (efficient)
contract GoodArithmetic {
    uint256 public counter;

    function increment() external {
        unchecked {
            counter += 1;  // No safety checks needed here
        }
    }

    function decrement() external {
        unchecked {
            counter -= 1;  // Safe to skip checks when we control the inputs
        }
    }

    // Gas cost: ~60 gas per operation
    // SAVINGS: ~100 gas per operation (62% reduction)
}
```

**When Unchecked is Safe:**

```solidity
pragma solidity ^0.8.0;

contract UncheckedExamples {

    // SAFE: Loop counter incrementing
    function loopWithUnchecked() external pure returns (uint256 sum) {
        for (uint256 i = 0; i < 100; ) {
            sum += i;
            unchecked {
                i++;  // Can't overflow in this context
            }
        }
    }

    // SAFE: Subtraction after validation
    function safeSubtract(uint256 a, uint256 b) external pure returns (uint256) {
        require(a >= b);  // Validate before

        unchecked {
            return a - b;  // Safe to skip checks
        }
    }

    // SAFE: Post-increment in for loop
    function efficientLoop(uint256[] calldata data) external pure returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < data.length; ) {
            sum += data[i];
            unchecked {
                i++;
            }
        }
        return sum;
    }

    // UNSAFE: Don't use unchecked here
    function unsafeExample(uint256 untrustedInput) external pure {
        unchecked {
            uint256 result = untrustedInput + 1;  // Could overflow!
        }
    }
}
```

**Performance Comparison:**

```solidity
pragma solidity ^0.8.0;

contract UncheckedBenchmark {

    function checkedLoop(uint256 iterations) external pure returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < iterations; i++) {
            sum += i;
            // Overhead: ~100 gas for i++ safety check per iteration
        }
        return sum;
    }

    function uncheckedLoop(uint256 iterations) external pure returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < iterations; ) {
            sum += i;
            unchecked {
                i++;  // ~100 gas saved per iteration
            }
        }
        return sum;
    }

    // For 100 iterations:
    // checkedLoop: ~52,000 + (100 * 100) = 62,000 gas
    // uncheckedLoop: ~52,000 + (100 * 5) = 52,500 gas
    // SAVINGS: ~9,500 gas (15% reduction)

    // For 1000 iterations:
    // SAVINGS: ~95,000 gas (15% reduction)
}
```

**Rules for Unchecked:**
1. Use only when mathematically safe
2. Common cases: loop counters, validated subtraction, known-safe addition
3. Document why unchecked is safe
4. Never use with untrusted external input without validation

---

## Short-Circuit Evaluation

### Overview
Arrange conditional logic to exit early and skip expensive operations.

**Example: Complex Condition Evaluation**

```solidity
// BEFORE: All conditions evaluated (expensive)
contract BadShortCircuit {
    mapping(address => uint256) public balances;
    mapping(address => bool) public isWhitelisted;

    function canTransfer(address from, address to, uint256 amount) external view returns (bool) {
        // All conditions evaluated, even if first is false
        return (balances[from] >= amount) &&  // SLOAD: 2,100 gas
               isWhitelisted[to] &&            // SLOAD: 2,100 gas
               to != address(0) &&             // Comparison: 3 gas
               amount > 0;                     // Comparison: 3 gas

        // Worst case (from unwhitelisted): 4,200+ gas
    }
}

// AFTER: Short-circuit evaluation (efficient)
contract GoodShortCircuit {
    mapping(address => uint256) public balances;
    mapping(address => bool) public isWhitelisted;

    function canTransfer(address from, address to, uint256 amount) external view returns (bool) {
        // Cheapest checks first
        if (amount == 0) return false;              // 3 gas check
        if (to == address(0)) return false;         // 3 gas check
        if (balances[from] < amount) return false;  // 2,100 gas check (only if needed)
        if (!isWhitelisted[to]) return false;       // 2,100 gas check (only if needed)

        return true;

        // Best case (amount = 0): 3 gas
        // Worst case: ~4,200 gas
        // Average case: ~2,100 gas
    }
}
```

**Real-World Token Transfer Example:**

```solidity
pragma solidity ^0.8.0;

contract TokenWithShortCircuit {
    mapping(address => uint256) public balances;
    mapping(address => bool) public blacklisted;
    uint256 public constant MAX_TRANSFER = 1000000e18;

    function transfer(address to, uint256 amount) external returns (bool) {
        // Order checks from cheapest to most expensive

        // Arithmetic check (no storage)
        if (amount == 0) revert InvalidAmount();
        if (amount > MAX_TRANSFER) revert ExceedsMax();

        // Address check (no storage)
        if (to == address(0)) revert ZeroAddress();
        if (to == msg.sender) revert SelfTransfer();

        // Blacklist check (1x SLOAD)
        if (blacklisted[to]) revert ToBlacklisted();
        if (blacklisted[msg.sender]) revert FromBlacklisted();

        // Balance check (1x SLOAD)
        if (balances[msg.sender] < amount) revert InsufficientBalance();

        // Only if all checks pass, do expensive state changes
        balances[msg.sender] -= amount;
        balances[to] += amount;

        return true;
    }

    // Error definitions
    error InvalidAmount();
    error ExceedsMax();
    error ZeroAddress();
    error SelfTransfer();
    error ToBlacklisted();
    error FromBlacklisted();
    error InsufficientBalance();
}
```

**Optimization Ordering:**

```solidity
pragma solidity ^0.8.0;

contract ConditionOrdering {

    // BAD: Expensive storage read first
    function bad_order(address user, uint256 amount) external view {
        require(balances[user] >= amount &&      // 2,100 gas - expensive first!
                amount > 0 &&                     // 3 gas
                user != address(0));              // 3 gas
    }

    // GOOD: Cheap checks first
    function good_order(address user, uint256 amount) external view {
        require(user != address(0) &&             // 3 gas
                amount > 0 &&                     // 3 gas
                balances[user] >= amount);        // 2,100 gas - only evaluated if needed
    }

    mapping(address => uint256) balances;
}
```

---

## Loop Optimization

### Overview
Loops are common gas consumers. Various optimization techniques can significantly reduce loop costs.

**Basic Loop Optimization:**

```solidity
// BEFORE: Inefficient loop (expensive)
contract BadLoop {
    function sumArray(uint256[] memory arr) external pure returns (uint256) {
        uint256 sum = 0;

        for (uint256 i = 0; i < arr.length; i++) {
            sum += arr[i];
            // Problems:
            // 1. arr.length loaded multiple times (2-3 gas each)
            // 2. i++ has safety checks (100 gas each)
            // 3. Each MLOAD costs gas
        }

        return sum;
    }

    // For 100-item array:
    // - Length reads: ~100 * 3 = 300 gas
    // - Increment checks: ~100 * 100 = 10,000 gas
    // - Memory reads: ~100 * 3 = 300 gas
    // Total: ~10,600 gas (excluding sum additions)
}

// AFTER: Efficient loop (optimized)
contract GoodLoop {
    function sumArray(uint256[] calldata arr) external pure returns (uint256) {
        uint256 sum = 0;
        uint256 length = arr.length;  // Load once

        for (uint256 i = 0; i < length; ) {
            sum += arr[i];

            unchecked {
                i++;  // No safety checks
            }
        }

        return sum;
    }

    // For 100-item array:
    // - Length reads: 1 * 3 = 3 gas
    // - Increment checks: 0 gas (unchecked)
    // - Calldata reads: ~100 * 3 = 300 gas
    // Total: ~303 gas (excluding sum additions)
    // SAVINGS: ~10,297 gas (97% reduction)
}
```

**Cache Length and Use Calldata:**

```solidity
pragma solidity ^0.8.0;

contract LoopOptimizations {

    // Technique 1: Cache array length
    function cachedLength(uint256[] memory arr) external pure returns (uint256) {
        uint256 sum = 0;
        uint256 len = arr.length;  // Cache once

        for (uint256 i = 0; i < len; ) {
            sum += arr[i];
            unchecked { i++; }
        }
        return sum;
    }

    // Technique 2: Use calldata (cheapest read)
    function calldataLoop(uint256[] calldata arr) external pure returns (uint256) {
        uint256 sum = 0;

        for (uint256 i = 0; i < arr.length; ) {
            sum += arr[i];
            unchecked { i++; }
        }
        return sum;
    }

    // Technique 3: Reverse loop (sometimes cheaper)
    function reverseLoop(uint256[] calldata arr) external pure returns (uint256) {
        uint256 sum = 0;

        for (uint256 i = arr.length; i > 0; ) {
            unchecked {
                i--;
                sum += arr[i];  // Access after decrement
            }
        }
        return sum;
    }

    // Reverse loop advantage: Decrement and compare to 0 is 1 operation
    // vs increment and compare to length (2 operations)
    // SAVINGS: ~3-5 gas per iteration for large loops
}
```

**Break and Continue:**

```solidity
pragma solidity ^0.8.0;

contract LoopControlFlow {
    uint256[] public data;

    // BAD: Unnecessary iterations
    function bad_search(uint256 target) external view returns (uint256) {
        uint256 count = 0;

        for (uint256 i = 0; i < data.length; i++) {  // Loops entire array
            if (data[i] == target) {
                count++;
                // Continues looping even after finding target
            }
        }

        return count;
    }

    // GOOD: Early exit
    function good_search(uint256 target) external view returns (uint256) {
        for (uint256 i = 0; i < data.length; ) {
            if (data[i] == target) {
                return i;  // Early exit saves iterations
            }
            unchecked { i++; }
        }
        return type(uint256).max;  // Not found
    }
}
```

**Loop Gas Cost Summary:**

| Optimization | Gas Saved Per Iteration | For 100 Items |
|--------------|------------------------|---------------|
| Cache length | 3 gas | 300 gas |
| Use unchecked i++ | 100 gas | 10,000 gas |
| Use calldata | 3 gas | 300 gas |
| Reverse loop | 3-5 gas | 300-500 gas |
| **Combined** | **~110 gas** | **~11,100 gas** |

---

## Minimal Proxy Patterns

### Overview
When deploying multiple instances of a contract, minimal proxies reduce deployment costs significantly.

**Standard vs Proxy Deployment:**

```solidity
// BEFORE: Deploying contract directly (expensive)
contract ExpensiveToken {
    string public name;
    string public symbol;
    mapping(address => uint256) public balances;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function transfer(address to, uint256 amount) external {
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}

// Deployment cost: ~200,000 - 500,000 gas per contract
// For 10 tokens: ~2,000,000 - 5,000,000 gas
```

**Minimal Proxy Pattern:**

```solidity
pragma solidity ^0.8.0;

// Implementation contract (deployed once)
contract Token {
    string public name;
    string public symbol;
    address immutable admin;
    mapping(address => uint256) public balances;

    constructor() {
        admin = msg.sender;
    }

    function transfer(address to, uint256 amount) external {
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}

// Minimal proxy contract
contract MinimalProxy {
    // EIP-1167 minimal proxy bytecode
    // Proxies calls to implementation contract

    constructor(address implementation) {
        // Minimal proxy setup
    }
}

// Factory for deploying proxies
contract ProxyFactory {
    address public implementation;

    constructor(address _implementation) {
        implementation = _implementation;
    }

    function createProxy() external returns (address proxy) {
        bytes20 implementationBytes = bytes20(implementation);

        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), implementationBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            proxy := create(0, clone, 0x37)
        }
    }

    // Deployment cost per proxy: ~50,000 - 100,000 gas
    // vs ~200,000 - 500,000 gas for full contract
    // SAVINGS: ~150,000 gas per proxy (75% reduction)

    // For 10 proxies:
    // Full contracts: ~2,500,000 gas
    // Proxies + 1 implementation: ~150,000 + 500,000 = 650,000 gas
    // SAVINGS: ~1,850,000 gas (74% reduction)
}
```

**Complete Minimal Proxy Example:**

```solidity
pragma solidity ^0.8.0;

// EIP-1167 Minimal Proxy Clone Factory
contract CloneFactory {

    event ProxyCreated(address indexed proxy, address indexed implementation);

    function createClone(address implementation) internal returns (address instance) {
        bytes20 implementationBytes = bytes20(implementation);

        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), implementationBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, clone, 0x37)
        }

        require(instance != address(0), "EIP1167: create failed");
        emit ProxyCreated(instance, implementation);
    }
}

// Usage
contract TokenFactory is CloneFactory {
    address public masterToken;
    address[] public allTokens;

    constructor(address _masterToken) {
        masterToken = _masterToken;
    }

    function createToken() external returns (address) {
        address newToken = createClone(masterToken);
        allTokens.push(newToken);
        return newToken;
    }

    // Gas costs:
    // Deploy master: 300,000 gas (one time)
    // Create proxy: 70,000 gas each
    // 10 tokens total: 300,000 + (10 * 70,000) = 1,000,000 gas
    // vs 10 full deployments: 10 * 300,000 = 3,000,000 gas
    // SAVINGS: 2,000,000 gas (67% reduction)
}
```

---

## Advanced Techniques

### Inline Assembly for Gas Optimization

```solidity
pragma solidity ^0.8.0;

contract AssemblyOptimizations {

    // BEFORE: Pure Solidity (more gas)
    function safeTransfer_Solidity(address to, uint256 amount) external {
        (bool success, ) = to.call{value: amount}("");
        require(success, "Transfer failed");
    }

    // AFTER: Optimized with assembly (less gas)
    function safeTransfer_Assembly(address to, uint256 amount) external {
        assembly {
            let success := call(gas(), to, amount, 0, 0, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }
        }
    }

    // Assembly version saves ~500-1000 gas per call

    // BEST: Use low-level transfer helper
    function safeTransfer_Best(address payable to, uint256 amount) external {
        bool success;
        assembly {
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }
        if (!success) revert TransferFailed();
    }

    error TransferFailed();
}
```

### Bitwise Operations

```solidity
pragma solidity ^0.8.0;

contract BitwiseOptimization {

    // BEFORE: Using modulo operator
    function bad_divideBy2(uint256 num) external pure returns (uint256) {
        return num / 2;  // Division: ~35 gas
    }

    // AFTER: Using bitwise right shift
    function good_divideBy2(uint256 num) external pure returns (uint256) {
        return num >> 1;  // Bitwise shift: ~3 gas
        // SAVINGS: 32 gas (91% reduction)
    }

    // BEFORE: Multiply by 2
    function bad_multiplyBy2(uint256 num) external pure returns (uint256) {
        return num * 2;  // Multiplication: ~5 gas
    }

    // AFTER: Bitwise left shift
    function good_multiplyBy2(uint256 num) external pure returns (uint256) {
        return num << 1;  // Bitwise shift: ~3 gas
        // SAVINGS: 2 gas (40% reduction)
    }

    // Modulo optimization
    function bad_isEven(uint256 num) external pure returns (bool) {
        return num % 2 == 0;  // Modulo: ~30 gas
    }

    function good_isEven(uint256 num) external pure returns (bool) {
        return num & 1 == 0;  // Bitwise AND: ~3 gas
        // SAVINGS: 27 gas (90% reduction)
    }
}
```

### Reentrancy Guard Optimization

```solidity
pragma solidity ^0.8.0;

// BEFORE: Inefficient reentrancy guard
contract BadReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() {
        require(locked == 1, "No reentrancy");  // SLOAD: 2,100 gas
        locked = 2;                              // SSTORE: 5,000 gas
        _;
        locked = 1;                              // SSTORE: 5,000 gas
        // Total: ~12,100 gas
    }

    function withdraw() external nonReentrant {
        // Function code
    }
}

// AFTER: Optimized reentrancy guard using assembly
contract GoodReentrancyGuard {
    uint256 private locked;

    modifier nonReentrant() {
        assembly {
            if locked { revert(0, 0) }
            locked := 1
        }
        _;
        assembly {
            locked := 0
        }
    }

    // Total: ~500-1000 gas
    // SAVINGS: ~11,000 gas per call (91% reduction)
}
```

---

## Gas Optimization Checklist

### Critical Optimizations (High Impact)
- [ ] Pack storage variables efficiently
- [ ] Use immutable/constant for fixed values
- [ ] Use custom errors instead of require strings
- [ ] Optimize loop structures (cache length, unchecked increment)
- [ ] Use calldata instead of memory for external parameters

### Important Optimizations (Medium Impact)
- [ ] Use external instead of public for external-only functions
- [ ] Implement batch operations for repeated actions
- [ ] Use unchecked blocks for proven safe math
- [ ] Short-circuit conditional logic (cheap checks first)
- [ ] Cache frequently accessed state variables

### Advanced Optimizations (Lower Impact)
- [ ] Use bitwise operations instead of arithmetic
- [ ] Minimize function arguments
- [ ] Use minimal proxies for multiple instances
- [ ] Inline simple functions
- [ ] Use indexed events efficiently
- [ ] Avoid dynamic arrays in storage when possible

### Testing and Measurement
- [ ] Use Remix or Hardhat gas reporter
- [ ] Profile critical functions
- [ ] Compare before/after gas costs
- [ ] Test with realistic transaction volumes
- [ ] Monitor mainnet gas usage

---

## Real-World Optimization Case Study

### Before Optimization
```solidity
// A real token contract with inefficiencies
contract TokenBefore {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;
    bool public initialized;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory _name, string memory _symbol) public {
        name = _name;
        symbol = _symbol;
        decimals = 18;
        owner = msg.sender;
        initialized = false;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(msg.sender != to, "Cannot transfer to self");
        require(to != address(0), "Cannot transfer to zero address");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] = balances[msg.sender] - amount;
        balances[to] = balances[to] + amount;

        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        require(spender != address(0), "Cannot approve zero address");
        allowance[msg.sender][spender] = amount;
        return true;
    }
}

// Issues:
// 1. Storage not packed (5+ slots)
// 2. String parameters use memory instead of calldata
// 3. Multiple require statements with strings
// 4. No immutable values used
```

### After Optimization
```solidity
pragma solidity ^0.8.0;

contract TokenAfter {
    // Custom errors instead of require strings
    error SelfTransfer();
    error ZeroAddress();
    error InsufficientBalance();
    error InvalidApproval();

    // Packed storage (2 slots)
    address public immutable owner;
    string public immutable name;
    string public immutable symbol;
    uint8 constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory _name, string memory _symbol) {
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
    }

    // Use external and calldata
    function transfer(address to, uint256 amount) external returns (bool) {
        if (msg.sender == to) revert SelfTransfer();
        if (to == address(0)) revert ZeroAddress();
        if (balances[msg.sender] < amount) revert InsufficientBalance();

        unchecked {
            balances[msg.sender] -= amount;
            balances[to] += amount;
        }

        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        if (spender == address(0)) revert InvalidApproval();

        allowance[msg.sender][spender] = amount;
        return true;
    }
}

// Improvements:
// - Custom errors reduce deployment by 1,000+ gas
// - Immutable storage saves 2,100 gas per read
// - External function saves 100 gas per call
// - Unchecked math saves 100 gas per operation
// - Total per transaction: ~500-1000 gas saved
// - Over 1 million transactions: 500 million - 1 billion gas saved!
```

---

## Conclusion

Gas optimization requires understanding trade-offs between:
- **Readability vs Efficiency**
- **Security vs Cost**
- **Maintainability vs Performance**

Key takeaways:
1. Storage is the most expensive operation - optimize layout first
2. Use immutable/constant for fixed values
3. Cache frequently accessed variables
4. Use custom errors for better error handling
5. Batch operations when handling multiple items
6. Profile and measure - don't optimize blindly

Most important: **Test thoroughly after optimization to ensure correctness and security.**

---

## References
- [Solidity Gas Optimization Techniques](https://docs.soliditylang.org/en/v0.8.0/)
- [EIP-1167: Minimal Proxy Contract](https://eips.ethereum.org/EIPS/eip-1167)
- [EIP-6093: Custom Errors](https://eips.ethereum.org/EIPS/eip-6093)
- [Hardhat Gas Reporter](https://github.com/cgewecke/hardhat-gas-reporter)
- [Contract Audit Checklist](https://docs.openzeppelin.com/contracts/4.x/)

---

# Part 5: Security Checklist

# Solidity Security Audit Checklist

A comprehensive pre-deployment security audit checklist for Solidity smart contracts. This checklist should be completed before deploying any contract to mainnet or production networks.

**Last Updated:** November 2024
**Repository:** Solidity 10x Mini-Projects Learning Curriculum

---

## Table of Contents

1. [Reentrancy & State Management](#reentrancy--state-management)
2. [Arithmetic & Overflow Protection](#arithmetic--overflow-protection)
3. [Access Control & Authorization](#access-control--authorization)
4. [External Calls & Oracle Safety](#external-calls--oracle-safety)
5. [Gas Optimization vs Security](#gas-optimization-vs-security)
6. [ERC Token Standard Compliance](#erc-token-standard-compliance)
7. [Proxy Pattern Security](#proxy-pattern-security)
8. [Cryptographic & Signature Validation](#cryptographic--signature-validation)
9. [Economic & Logic Exploits](#economic--logic-exploits)
10. [Testing & Verification](#testing--verification)
11. [Code Quality & Best Practices](#code-quality--best-practices)
12. [Network & Deployment Security](#network--deployment-security)

---

## Reentrancy & State Management

### Reentrancy Attacks
- [ ] All external calls are made after state changes (Checks-Effects-Interactions pattern)
- [ ] External calls are at the end of functions when possible
- [ ] State variables are updated before calling untrusted contracts
- [ ] Reentrancy guards (mutex locks) are used where external calls occur
- [ ] Contract is protected against both direct and indirect reentrancy
- [ ] Transfer functions use `.transfer()` or `.send()` where reentrancy is a concern (gas-limited)
- [ ] Low-level `call` operations are documented and have reentrancy protection
- [ ] Fallback functions do not perform critical state changes
- [ ] All callbacks from external contracts are verified to be safe

### State Consistency
- [ ] Contract invariants are maintained after each state-modifying operation
- [ ] Atomic operations are completed without intermediate inconsistent states
- [ ] No state is left in a partially updated condition after failed transactions
- [ ] Guard clauses prevent entry into functions with inconsistent state
- [ ] State transitions are unidirectional where applicable (no invalid state combinations)

---

## Arithmetic & Overflow Protection

### Integer Overflow/Underflow (Solidity >= 0.8.0)
- [ ] Solidity version >= 0.8.0 is used (has built-in overflow checks)
- [ ] For Solidity < 0.8.0: SafeMath or equivalent library is used
- [ ] No `unchecked` blocks are used without explicit mathematical proof
- [ ] Division operations check for division by zero
- [ ] Modulo operations check for modulo by zero
- [ ] Negative number handling is explicit (use integers >= 0)

### Arithmetic Correctness
- [ ] Order of operations is correct (no precision loss from division)
- [ ] Multiplication before division is used to prevent rounding errors
- [ ] Fixed-point arithmetic is handled correctly (decimal places are tracked)
- [ ] Large numbers don't cause overflow with reasonable inputs
- [ ] Edge cases (0, 1, max values) are tested for arithmetic operations

### Decimal Precision
- [ ] Token decimal handling is consistent across contracts (e.g., 18 decimals)
- [ ] Exchange rates account for decimal differences
- [ ] Rounding is handled consistently (floor vs round vs ceil)
- [ ] Precision loss in calculations is documented and acceptable

---

## Access Control & Authorization

### Role-Based Access Control
- [ ] Owner/admin functions are properly restricted
- [ ] Only authorized addresses can call sensitive functions
- [ ] Access control lists (ACL) or role-based systems are implemented
- [ ] Role assignments are logged with events
- [ ] Roles are immutable or have timelock for changes
- [ ] Multi-signature requirements exist for critical functions (if appropriate)

### Function-Level Security
- [ ] All state-modifying functions have proper access checks
- [ ] View/pure functions don't bypass access controls
- [ ] Internal functions are only called from authorized contexts
- [ ] Public functions validate caller identity (msg.sender)
- [ ] Constructor is restricted from being called multiple times

### Authorization Patterns
- [ ] Uses OpenZeppelin's AccessControl or similar battle-tested library
- [ ] Whitelist/blacklist implementation (if used) is secure
- [ ] Delegated access patterns are properly validated
- [ ] No unchecked delegation loops or authorization bypasses
- [ ] Access control is not dependent on external contract state

---

## External Calls & Oracle Safety

### External Call Safety
- [ ] All external calls are wrapped in try-catch or have revert checks
- [ ] Failed external calls are handled gracefully
- [ ] Return values from external calls are validated
- [ ] Gas limits are set for external calls where possible
- [ ] No assumptions about external contract behavior

### Oracle Dependencies
- [ ] Oracle data freshness is verified (timestamp checks)
- [ ] Multiple oracle sources are used (no single point of failure)
- [ ] Oracle price feeds have reasonable deviation limits
- [ ] Staleness checks prevent using outdated price data
- [ ] Oracle data is not relied upon for critical security decisions
- [ ] Price oracle manipulation resistance is implemented
- [ ] Chainlink or similar oracle's circuit breaker is respected

### External Contract Assumptions
- [ ] External contracts are not assumed to follow any interface
- [ ] Exception handling exists for failed external calls
- [ ] Contract addresses are validated (not zero address)
- [ ] Interactions with upgradeable proxies are considered
- [ ] No trust assumptions about external contract implementations

---

## Gas Optimization vs Security

### Gas Limits & Safety
- [ ] Unbounded loops are prevented (arrays have size limits)
- [ ] Loop iterations are bounded and documented
- [ ] Dynamic array operations are carefully considered
- [ ] Gas-intensive operations are not in tight loops
- [ ] Block gas limit is not exceeded in normal operations

### Security vs Gas Trade-offs
- [ ] Security is prioritized over minor gas optimizations
- [ ] Documented trade-offs between gas efficiency and security
- [ ] No security critical code is optimized with `unchecked` blocks
- [ ] Memory operations are safe (no buffer overflows)
- [ ] Storage operations are atomic and consistent

### Denial of Service (DoS) Prevention
- [ ] No functions that can be made expensive by external actors
- [ ] Push over pull pattern is used for payments
- [ ] Batch operations have reasonable limits
- [ ] No array iteration over unbounded user-controlled data
- [ ] Gas usage scales reasonably with input size

---

## ERC Token Standard Compliance

### ERC20 (Fungible Tokens)
- [ ] Implements all required ERC20 functions: `transfer`, `approve`, `transferFrom`, `balanceOf`, `totalSupply`, `allowance`
- [ ] Events are emitted: `Transfer(from, to, value)`, `Approval(owner, spender, value)`
- [ ] Allowance is set to 0 before changing to non-zero (prevents race condition)
- [ ] Transfer events are logged for all value movements
- [ ] Approval events are logged for all allowance changes
- [ ] Return values are correct (`true` on success)
- [ ] Handles edge case: sending to self
- [ ] No transferFrom without adequate allowance
- [ ] Decimal places are documented and consistent

### ERC721 (Non-Fungible Tokens)
- [ ] Implements all required ERC721 functions: `transferFrom`, `safeTransferFrom`, `ownerOf`, `balanceOf`, `approve`, `setApprovalForAll`
- [ ] `safeTransferFrom` includes safety check for smart contract receivers
- [ ] ERC721Receiver callback is properly handled
- [ ] Transfer events are correctly emitted
- [ ] Approval events are correctly emitted
- [ ] Token IDs are unique and immutable
- [ ] Owner can be queried correctly
- [ ] Approval state is correctly managed per token
- [ ] Metadata URI is accessible (if using metadata extension)

### ERC4626 (Tokenized Vault)
- [ ] Implements all required functions: `deposit`, `mint`, `withdraw`, `redeem`, `convertToAssets`, `convertToShares`, `previewDeposit`, `previewMint`, `previewWithdraw`, `previewRedeem`, `totalAssets`, `maxDeposit`, `maxMint`, `maxWithdraw`, `maxRedeem`
- [ ] Asset decimals match expected precision
- [ ] Share price calculations are accurate
- [ ] Deposit/mint operations correctly update shares
- [ ] Withdraw/redeem operations correctly update assets
- [ ] Preview functions return accurate estimates
- [ ] Max functions enforce reasonable limits
- [ ] Reentrancy is protected in deposit/withdrawal operations
- [ ] Yield generation is fairly distributed
- [ ] Rounding favors the vault (not the user) for vault security

### Other ERC Standards (as applicable)
- [ ] ERC165 interface detection is correctly implemented
- [ ] Optional extensions are properly declared
- [ ] No accidental multiple inheritance issues
- [ ] Function selectors don't collide across inherited contracts

---

## Proxy Pattern Security

### Proxy Implementation
- [ ] Transparent Proxy pattern is used (or UUPS with proper guards)
- [ ] Admin functionality is clearly separated from business logic
- [ ] Proxy storage layout matches implementation contract
- [ ] No storage conflicts between proxy and implementation
- [ ] Upgrade logic has proper timelock (if not a learning contract)
- [ ] Only authorized addresses can upgrade implementation

### Storage Layout Safety
- [ ] Storage slots are not reused in incompatible ways
- [ ] New state variables are appended, never inserted
- [ ] Storage gaps are used for future expansions (`uint256[50] private __gap`)
- [ ] Inheritance order is preserved across upgrades
- [ ] No storage variable name changes (only additions)

### Upgrade Safety
- [ ] Initialization function cannot be called twice
- [ ] Implementation contract is not left uninitialized
- [ ] No selfdestruct in implementation contract
- [ ] Proxy can recover from failed initialization
- [ ] Upgrade events are logged
- [ ] No breaking changes to function signatures

### Proxy Interaction
- [ ] Fallback function properly delegates to implementation
- [ ] All calls are delegated (not executed on proxy)
- [ ] No state stored in proxy contract
- [ ] Careful with `msg.sender` in delegated calls
- [ ] Contract construction and initialization are distinct steps

---

## Cryptographic & Signature Validation

### Signature Verification
- [ ] Signatures use `ecrecover` safely (if custom) or OpenZeppelin's ECDSA
- [ ] Message hashing follows EIP-191 or EIP-712 standards
- [ ] Nonces are used to prevent replay attacks
- [ ] Chain ID is included in signature to prevent cross-chain replay
- [ ] Signature deadlines are checked (prevent old signatures)
- [ ] Recovered address is validated (not address(0))

### EIP-712 Typed Data
- [ ] Domain separator is correctly computed
- [ ] Domain separator includes chainId, name, version, verifyingContract
- [ ] Struct hashing matches EIP-712 spec
- [ ] All typed parameters are included in hash
- [ ] No omitted fields in domain or type encoding

### Cryptographic Best Practices
- [ ] Keccak256 is used for hashing (not SHA3 variants)
- [ ] Hash functions are not used for randomness
- [ ] No reliance on `blockhash` for recent blocks (< 256 blocks)
- [ ] ECDSA signatures are standard (not custom implementations)
- [ ] Keys are not hardcoded in contracts

---

## Economic & Logic Exploits

### Flash Loan & Atomic Arbitrage Protection
- [ ] Flash loan attacks are mitigated where applicable
- [ ] Price checks are done within same block where safe
- [ ] State-affecting decisions don't rely solely on token balances
- [ ] No logic vulnerable to "read-modify-write" patterns
- [ ] Checkpoint or snapshot patterns are used for voting/distribution

### Incentive Misalignment
- [ ] Rewards/incentives cannot be manipulated by users
- [ ] No perverse incentive structures
- [ ] Fee collection doesn't create arbitrage opportunities
- [ ] Governance token distribution is fair
- [ ] No front-running friendly operations

### Integer Precision Exploits
- [ ] Rounding errors don't accumulate to significant amounts
- [ ] Dust amounts are handled (not left stuck)
- [ ] No way to create free tokens through rounding
- [ ] Division ordering prevents precision attacks
- [ ] Minimum amounts are enforced where needed

### Economic Griefing
- [ ] Users cannot prevent others from operating
- [ ] No way to permanently lock funds
- [ ] Fallback positions exist for failed transactions
- [ ] No forced token movements
- [ ] Withdrawal mechanisms are always available

### Logic Exploits
- [ ] Conditional logic is verified against all states
- [ ] No dependency on block timestamps for critical logic (or acceptable range)
- [ ] `now` alias is not used (use `block.timestamp`)
- [ ] Contract state cannot enter deadlock
- [ ] Emergency withdrawal mechanisms exist
- [ ] No circular dependency in contract interactions

---

## Testing & Verification

### Unit Testing
- [ ] Minimum 80% code coverage by tests
- [ ] All state transitions are tested
- [ ] All access control paths are tested
- [ ] All error conditions are tested
- [ ] Edge cases are tested (0, 1, max values)
- [ ] Test suite can be run independently
- [ ] Tests verify events are emitted correctly

### Integration Testing
- [ ] Multi-contract interactions are tested
- [ ] External contract mocks are used appropriately
- [ ] Upgradeability scenarios are tested (if applicable)
- [ ] Contract interactions across different networks are considered
- [ ] Realistic workflows are tested end-to-end

### Security Testing
- [ ] Reentrancy attacks are tested (especially for external calls)
- [ ] Overflow/underflow scenarios are tested
- [ ] Access control violations are attempted and prevented
- [ ] Malicious external contracts are simulated
- [ ] Front-running scenarios are considered

### Property-Based Testing
- [ ] Invariants are defined and tested
- [ ] Fuzzing is applied to core functions
- [ ] Random inputs are tested for crashes
- [ ] Stateful fuzzing tests contract interactions
- [ ] Symbolic execution is considered (for critical contracts)

### Formal Verification
- [ ] Critical functions use formal methods (if high value)
- [ ] Contract behavior is proven to meet spec
- [ ] State machine properties are verified
- [ ] Security properties are formally stated

---

## Code Quality & Best Practices

### Code Standards
- [ ] Solidity code follows official style guide
- [ ] Naming conventions are consistent (camelCase for functions/variables, PascalCase for contracts)
- [ ] Function order is documented (state-modifying before view/pure)
- [ ] Comments explain "why", not "what"
- [ ] NatSpec comments are complete for public functions
- [ ] No debug code or console.log statements remain

### Contract Design
- [ ] Single Responsibility Principle is followed
- [ ] Inheritance is kept simple (no deep hierarchies)
- [ ] Library usage is preferred over inheritance when possible
- [ ] No contract performs too many roles
- [ ] Business logic is separate from security logic

### Dependency Management
- [ ] OpenZeppelin or similar audited libraries are used
- [ ] Custom code is only for unique business logic
- [ ] Library versions are pinned
- [ ] All imported contracts are reviewed
- [ ] No version conflicts in dependencies

### Error Handling
- [ ] Custom errors are used (Solidity >= 0.8.4)
- [ ] Error messages are meaningful
- [ ] Revert reasons are appropriate
- [ ] No silent failures
- [ ] Edge cases properly validate inputs

### Documentation
- [ ] README includes security considerations
- [ ] Known limitations are documented
- [ ] Configuration parameters are explained
- [ ] Upgrade process is documented
- [ ] Recovery procedures are documented

---

## Network & Deployment Security

### Pre-Deployment
- [ ] Contract is deployed to testnet first
- [ ] Testnet deployment is tested identically to mainnet deployment
- [ ] Address registries are correct (oracles, tokens, etc.)
- [ ] No hardcoded addresses in production contracts
- [ ] Private keys are not stored in version control
- [ ] Deployment scripts are reviewed

### Deployment Process
- [ ] Only authorized addresses execute deployment
- [ ] Multisig is used for deploying sensitive contracts
- [ ] Deployment is done during low-traffic periods
- [ ] Deployed contract address is verified on block explorer
- [ ] Constructor parameters are verified
- [ ] Initialization is done atomically

### Post-Deployment
- [ ] Contract verification on block explorer is complete
- [ ] Source code matches deployed bytecode
- [ ] All access controls are set correctly post-deployment
- [ ] Initial state is verified (owner, paused, etc.)
- [ ] Contracts are monitored for unusual activity

### Operational Security
- [ ] Keys are stored in hardware wallets or secure vaults
- [ ] Multi-signature wallets are used for admin functions
- [ ] Timelock contracts delay sensitive operations
- [ ] Role separation is enforced (deployer, admin, pauser)
- [ ] Emergency pause mechanisms are tested
- [ ] Upgrade/pause authority is decentralized if appropriate

### Upgradeability
- [ ] Upgrade process requires governance approval (if appropriate)
- [ ] Upgrades are timelocked
- [ ] Previous implementation can be audited
- [ ] Upgrade events are logged
- [ ] Rollback procedures exist

---

## Additional Security Considerations

### Contract-Specific Risks
- [ ] All contract-specific vulnerabilities are identified
- [ ] Mitigation strategies are documented
- [ ] Risk levels are assessed (critical, high, medium, low)
- [ ] Residual risks are documented and accepted

### Audit & Review
- [ ] Code has been peer-reviewed
- [ ] External audit is recommended for mainnet contracts
- [ ] Bug bounty program is considered
- [ ] Security advisories are monitored
- [ ] Incident response plan exists

### Ongoing Monitoring
- [ ] Events are monitored for anomalies
- [ ] Gas usage is monitored
- [ ] Function call patterns are monitored
- [ ] Emergency contacts are established
- [ ] Incident response playbook is prepared

---

## Deployment Sign-Off Checklist

Complete this checklist only after all above items are verified:

### Before Going to Testnet
- [ ] All security checks are completed
- [ ] Code review is finished
- [ ] Test coverage is adequate
- [ ] No critical warnings from automated tools

### Before Going to Mainnet
- [ ] External security audit is completed (for non-learning contracts)
- [ ] All audit findings are resolved
- [ ] Mainnet deployment is approved by team
- [ ] Multisig wallet is set up and tested
- [ ] Emergency response plan is in place
- [ ] Insurance/coverage is obtained (if applicable)
- [ ] Timeline for announcement is set

### Final Sign-Off
- **Auditor/Lead Developer:** _____________________ Date: _______
- **Security Review Lead:** _____________________ Date: _______
- **Project Manager:** _____________________ Date: _______

---

## Security Resources

### Documentation & Standards
- [Solidity Security Considerations](https://docs.soliditylang.org/en/latest/security-considerations.html)
- [Ethereum Smart Contract Best Practices](https://github.com/ConsenSys/smart-contract-best-practices)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [EIP-191: Signed Data Standard](https://eips.ethereum.org/EIPS/eip-191)
- [EIP-712: Typed Structured Data Hashing](https://eips.ethereum.org/EIPS/eip-712)

### Tools & Testing
- [Foundry](https://github.com/foundry-rs/foundry) - Development framework
- [Hardhat](https://hardhat.org/) - Development framework
- [Slither](https://github.com/crytic/slither) - Static analysis
- [Echidna](https://github.com/crytic/echidna) - Fuzzing framework
- [Mythril](https://github.com/ConsenSys/mythril) - Symbolic execution
- [Manticore](https://github.com/trailofbits/manticore) - Formal verification

### Vulnerability Resources
- [SWC Registry](https://swcregistry.io/) - Smart Contract Weakness Classification
- [Rekt.news](https://rekt.news/) - Hack postmortems
- [Trail of Bits Blog](https://blog.trailofbits.com/) - Security research
- [Immunefi](https://immunefi.com/) - Bug bounty platform

### Common Patterns & Solutions
- [Checks-Effects-Interactions Pattern](https://docs.soliditylang.org/en/latest/security-considerations.html#use-the-checks-effects-interactions-pattern)
- [Reentrancy Guard](https://docs.openzeppelin.com/contracts/4.x/api/security#ReentrancyGuard)
- [Pull Payment Pattern](https://docs.openzeppelin.com/contracts/4.x/api/security#PullPayment)
- [Pausable Contracts](https://docs.openzeppelin.com/contracts/4.x/api/security#Pausable)

---

## Usage Instructions

### How to Use This Checklist

1. **Create a copy** for each contract or contract suite being audited
2. **Assign responsibility** to team members for each section
3. **Complete items methodically** - don't skip sections
4. **Document findings** - note any failures or exceptions
5. **Track remediation** - mark items as resolved when fixed
6. **Review with team** - discuss any uncertain items
7. **Sign off** when all items are complete

### Customization

This checklist is comprehensive but may need customization for:
- **Token contracts:** Add ERC standard compliance specifics
- **Defi protocols:** Add oracle and economic exploit checks
- **NFT contracts:** Add metadata and receiver pattern checks
- **Governance:** Add voting and delegation security checks
- **Upgradeable contracts:** Add proxy pattern specifics

### Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Nov 2024 | Initial comprehensive checklist creation |

---

**Note:** This checklist is a comprehensive guide but not exhaustive. Each smart contract project may have unique security considerations. Always supplement with project-specific analysis and professional security audits before deploying to production.

**Disclaimer:** This checklist is for educational purposes. Use at your own risk. Always consult with professional security auditors for high-value contracts.
