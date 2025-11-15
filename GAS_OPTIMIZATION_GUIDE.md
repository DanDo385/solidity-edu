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
