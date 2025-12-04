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

### Custom Errors Save Gas

```solidity
// Old: ~2,000 gas
require(balance >= amount, "Insufficient balance");

// New: ~200 gas (90% savings!)
if (balance < amount) revert InsufficientBalance(balance, amount);
```

**Fun fact**: Before Solidity 0.4.22, `throw` reverted without data. Modern `revert` opcodes bubble encoded error data, which explorers and off-chain services can parse for better UX.

Custom errors shine on L2s: fewer bytes in revert strings means smaller calldata when transactions revert during optimistic rollup dispute games.

**Real-world analogy**: Like using error codes instead of full messages. Error codes are faster to process and cheaper to transmit, but you need a reference guide to understand them.

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
- `src/solution/ErrorsRevertsSolution.sol` - Reference contract implementation
- `script/solution/DeployErrorsRevertsSolution.s.sol` - Deployment script patterns
- `test/solution/ErrorsRevertsSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

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

## 🛰️ Real-World Analogies & Fun Facts

- **Airplane checklists**: `require` is the preflight checklist; if anything is missing, you stop before takeoff. `assert` is the "wing still attached" invariant—if it fails, something is fundamentally wrong.

- **Compiler trivia**: Solc emits `REVERT` with ABI-encoded selectors for custom errors, letting frontends decode human-friendly reasons without inflating bytecode with strings.

- **DAO/ETC lesson**: The DAO fork highlighted how clear error surfaces speed up incident response. Ethereum Classic retained the old state; explicit errors made replay analysis easier across chains.

- **ETH inflation angle**: Reverting early prevents wasted gas and failed state writes. Less wasted execution → less pressure for higher base fees → less need for elevated issuance to pay validators.

- **Layer 2**: Short custom errors reduce calldata, which directly lowers fees on rollups and keeps fraud proofs cheaper to verify.

- **Gas savings**: Custom errors save ~90% gas compared to string messages. In high-frequency operations, this adds up quickly!

- **Error decoding**: Modern tools (Etherscan, Foundry, ethers.js) can decode custom errors automatically, making debugging easier.

- **Best practices**: Always use custom errors in production code. String messages are only for development/debugging.

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
