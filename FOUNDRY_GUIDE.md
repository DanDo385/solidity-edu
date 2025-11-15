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

### Installation

```bash
# Install Foundry using the official installer
curl -L https://foundry.paradigm.xyz | bash

# Install the latest version of Foundry
foundryup

# Verify installation
forge --version
cast --version
anvil --version
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

### Quick Start

```bash
# Create a new Foundry project
forge init my-solidity-project
cd my-solidity-project

# Install dependencies
forge install openzeppelin/openzeppelin-contracts --no-commit

# Run tests
forge test

# See current directory structure
tree -L 2
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
