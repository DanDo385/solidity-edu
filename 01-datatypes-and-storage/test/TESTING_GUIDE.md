# Testing Guide for DatatypesStorage Contract

> **Learn how to write comprehensive tests for Solidity smart contracts using Foundry**

This guide will help you write a complete test suite for the `DatatypesStorage` contract. You'll be creating the test file (`test/DatatypesStorage.t.sol`) yourself, using the skeleton file with TODOs as your guide.

## What is a Test File?

Think of a test file as a quality control inspector in a factory. Just like an inspector checks every product to make sure it works correctly before shipping, our test file checks every function in our smart contract to ensure it behaves exactly as expected.

In this project, you'll write tests that verify:
- ✅ All datatypes work correctly (uint256, address, bool, bytes32, string)
- ✅ Mappings store and retrieve data properly
- ✅ Arrays can be manipulated (add, remove, access)
- ✅ Structs are created and updated correctly
- ✅ Data locations (storage, memory, calldata) behave as expected
- ✅ Events are emitted when state changes
- ✅ Error conditions are handled properly

## Why Do We Test?

1. **Catch Bugs Before Deployment**: Once a contract is on the blockchain, you CAN'T change it. A bug in production could mean lost funds forever. Testing is your safety net.

2. **Document Expected Behavior**: Tests serve as living documentation. Someone reading your tests can understand exactly what your contract should do, with concrete examples.

3. **Prevent Regressions**: When you add new features, tests ensure you didn't accidentally break existing functionality.

4. **Build Confidence**: Good tests let you refactor code fearlessly, knowing you'll catch any mistakes immediately.

5. **Learn by Doing**: Writing tests helps you understand how your contract works and catches edge cases you might not have considered.

## Project Structure

Your test file should be located at `test/DatatypesStorage.t.sol`. The skeleton file already has:
- ✅ Test contract structure (`DatatypesStorageTest is Test`)
- ✅ Contract instance variable (`DatatypesStorage public datatypes`)
- ✅ Test addresses (`owner`, `user1`, `user2`)
- ✅ Detailed TODOs with hints for each test
- ✅ Comments explaining what each section should test

**Your job**: Implement all the TODOs to create a comprehensive test suite!

## Foundry Testing Basics

Foundry's testing framework follows these conventions:

### Test Function Naming

- **Test functions MUST start with "test"**: This is how Foundry identifies which functions to run.
  - ✅ `test_SetNumber()` - runs as a test
  - ❌ `checkNumber()` - won't run (missing "test" prefix)

- **Fuzz tests start with "testFuzz_"**: Foundry will run these with random inputs
  - ✅ `testFuzz_SetNumber(uint256 _number)` - runs 256 times with random values

- **Invariant tests start with "invariant_"**: These test properties that should always be true
  - ✅ `invariant_OwnerNeverChanges()` - verifies owner never changes

### setUp() Function

The `setUp()` function runs **BEFORE EACH AND EVERY test**. This ensures test isolation:

```solidity
function setUp() public {
    // This runs before EVERY test
    owner = address(this);  // Test contract is the deployer
    user1 = address(0x1);
    user2 = address(0x2);
    
    datatypes = new DatatypesStorage();  // Fresh contract instance
    
    // Label addresses for better debugging output
    vm.label(owner, "Owner");
    vm.label(user1, "User1");
    vm.label(user2, "User2");
}
```

**Why isolation matters**: Each test gets a fresh contract instance. If Test A sets `number = 100`, Test B still starts with `number = 0`. This prevents tests from interfering with each other.

### Assertions

Assertions verify that your contract behaves correctly:

```solidity
assertEq(a, b);           // Check if two values are equal
assertTrue(x);            // Check if something is true
assertFalse(x);           // Check if something is false
assertGt(a, b);          // Check if a > b
assertLt(a, b);          // Check if a < b
assertGe(a, b);          // Check if a >= b
assertLe(a, b);          // Check if a <= b
```

**Example**:
```solidity
function test_SetNumber() public {
    datatypes.setNumber(42);
    assertEq(datatypes.getNumber(), 42, "Number should be 42");
}
```

### Cheatcodes (vm.*)

Foundry provides powerful cheatcodes to control the testing environment:

```solidity
// Impersonate an address (next call appears from that address)
vm.prank(user1);
datatypes.deposit{value: 1 ether}();

// Give an address ETH
vm.deal(user1, 10 ether);

// Expect the next call to revert
vm.expectRevert("Error message");
datatypes.incrementNumber();  // This should fail

// Expect an event to be emitted
vm.expectEmit(true, false, false, true);
emit NumberUpdated(0, 100);
datatypes.setNumber(100);

// Bound a fuzz input to a range
uint256 bounded = bound(randomInput, 1, 100);

// Label addresses for better debugging
vm.label(user1, "User1");
```

## What Makes a Good Test?

A good test file accomplishes these goals:

1. **Comprehensive Coverage**: Test the "happy path" (normal usage) AND edge cases (unusual inputs, boundary conditions, error states)

2. **Isolation**: Each test should be independent. Tests shouldn't depend on running in a specific order or affect each other.

3. **Clarity**: Test names should clearly describe what they're testing. Reading the test should be like reading a story.

4. **Assertion Quality**: Each test should verify ONE specific behavior. More focused tests make debugging easier.

## Testing Best Practices

### 1. Test Naming Convention

Good test names are like newspaper headlines - they tell you the whole story:

**Format**: `test_FunctionName_Scenario`

- ✅ `test_SetNumber_UpdatesValue` - Clear: tests SetNumber, verifies it updates
- ✅ `test_IncrementNumber_RevertsOnOverflow` - Clear: tests IncrementNumber, expects revert on overflow
- ✅ `test_GetBalance_ReturnsZeroForNewAddress` - Clear: tests GetBalance, expects zero for new address
- ❌ `test1` - Bad: tells you nothing
- ❌ `testNumber` - Bad: too vague

**For this project**, follow the naming pattern in the skeleton file:
- `test_Constructor_SetsOwner` - Constructor tests
- `test_SetNumber` - Value type tests
- `test_SetBalance` - Mapping tests
- `test_AddNumber_IncreasesLength` - Array tests
- `test_RegisterUser` - Struct tests
- `test_SumMemoryArray` - Data location tests
- `testFuzz_SetNumber` - Fuzz tests
- `invariant_OwnerNeverChanges` - Invariant tests

### 2. What to Test (Comprehensive Coverage)

A complete test suite for `DatatypesStorage` should cover:

#### ✓ Constructor Behavior
- Owner is set correctly
- `isActive` is set to `true`
- Initial values are correct (number = 0, etc.)

#### ✓ Value Type Operations
- Setting and getting `uint256` values
- Incrementing numbers
- Handling max values (`type(uint256).max`)
- Overflow protection

#### ✓ Mapping Operations
- Setting balances for addresses
- Getting balances (including default zero values)
- Updating existing balances
- Independence (different addresses have different balances)
- Checking if balance exists (`hasBalance`)

#### ✓ Array Operations
- Adding numbers (`addNumber`)
- Getting array length
- Accessing elements by index
- Bounds checking (revert on out-of-bounds)
- Removing elements (`removeNumber`)
- Empty array handling

#### ✓ Struct Operations
- Registering users
- Getting user data
- Updating existing users
- Default values for non-existent users
- Event emissions

#### ✓ Data Location Behavior
- Memory arrays (temporary, cheap)
- Calldata arrays (read-only, cheapest)
- Storage arrays (permanent, expensive)
- Differences between locations

#### ✓ Event Emissions
- `NumberUpdated` event when number changes
- `UserRegistered` event when user registers
- `FundsDeposited` event when ETH is deposited
- Correct event parameters

#### ✓ Edge Cases
- Maximum `uint256` value
- Zero address (`address(0)`)
- Empty arrays
- Zero values
- Large arrays

#### ✓ Error Conditions
- Reverts on invalid inputs
- Overflow protection
- Out-of-bounds array access
- Empty array operations

#### ✓ Gas Benchmarking
- Cold storage writes vs warm writes
- Array operation costs
- Struct packing savings

#### ✓ Fuzz Testing
- Random inputs for `setNumber`
- Random addresses and balances for `setBalance`
- Bounded inputs for `incrementNumber`

#### ✓ Invariant Testing
- Owner never changes
- Array length is always consistent
- Contract balance matches sum of user balances

### 3. Test Isolation

Each test should be completely independent:

```solidity
// ✅ GOOD: Each test is independent
function setUp() public {
    datatypes = new DatatypesStorage();  // Fresh instance for each test
}

function test_SetNumber() public {
    datatypes.setNumber(42);
    assertEq(datatypes.getNumber(), 42);
}

function test_GetNumber() public {
    // This test doesn't depend on test_SetNumber
    // It gets a fresh contract where number = 0
    assertEq(datatypes.getNumber(), 0);
}
```

```solidity
// ❌ BAD: Tests depend on each other
uint256 public sharedNumber = 0;  // Shared state!

function test_SetNumber() public {
    datatypes.setNumber(42);
    sharedNumber = 42;  // Modifies shared state
}

function test_GetNumber() public {
    // This might fail if test_SetNumber didn't run first!
    assertEq(datatypes.getNumber(), sharedNumber);
}
```

### 4. How to Know What to Test

Ask yourself these questions for each function:

1. **What is the HAPPY PATH?** (Test it!)
   - Normal, expected usage
   - Example: `setNumber(42)` should set number to 42

2. **What can go WRONG?** (Test it!)
   - Invalid inputs, edge cases
   - Example: `incrementNumber()` should revert if number is max

3. **What are the BOUNDARIES?** (Test them!)
   - Zero, maximum values, empty arrays
   - Example: What happens when array is empty? When it's at max length?

4. **What are the SIDE EFFECTS?** (Test them!)
   - Events emitted, state changes
   - Example: Does `setNumber` emit `NumberUpdated` event?

5. **What are the ASSUMPTIONS?** (Test them!)
   - Default values, initial state
   - Example: What does `getBalance` return for a new address? (Should be 0)

## Common Testing Patterns

### Arrange-Act-Assert Pattern

This is the standard pattern for writing tests:

```solidity
function test_SetNumber() public {
    // Arrange: Set up test data
    uint256 newNumber = 42;

    // Act: Perform the action
    datatypes.setNumber(newNumber);

    // Assert: Verify the result
    assertEq(datatypes.getNumber(), newNumber, "Number should be updated");
}
```

### Testing Reverts

Use `vm.expectRevert()` to test error conditions:

```solidity
function test_IncrementNumber_RevertsOnOverflow() public {
    // Arrange: Set number to maximum value
    datatypes.setNumber(type(uint256).max);
    
    // Act & Assert: Expect revert when incrementing
    vm.expectRevert();  // Or: vm.expectRevert("Arithmetic over/underflow");
    datatypes.incrementNumber();
}
```

**For specific error messages**:
```solidity
vm.expectRevert("Index out of bounds");
datatypes.getNumberAt(100);  // Should revert with this message
```

### Testing Events

Use `vm.expectEmit()` to verify events are emitted:

```solidity
function test_SetNumber_EmitsEvent() public {
    // Set up expected event
    vm.expectEmit(false, false, false, true);
    // Parameters: checkTopic1, checkTopic2, checkTopic3, checkData
    emit NumberUpdated(0, 100);  // oldNumber, newNumber
    
    // Perform action that should emit event
    datatypes.setNumber(100);
}
```

**For indexed events**:
```solidity
function test_RegisterUser_EmitsEvent() public {
    vm.expectEmit(true, false, false, true);  // First param true for indexed
    emit UserRegistered(user1, 500);  // indexed address, balance
    
    datatypes.registerUser(user1, 500);
}
```

### Testing with Different Callers

Use `vm.prank()` to test functions from different addresses:

```solidity
function test_Deposit_IncreasesBalance() public {
    // Arrange: Give user1 some ETH
    vm.deal(user1, 1 ether);
    
    // Act: User1 deposits ETH
    vm.prank(user1);  // Next call appears from user1
    datatypes.deposit{value: 1 ether}();
    
    // Assert: Balance increased
    assertEq(datatypes.getBalance(user1), 1 ether);
}
```

### Fuzz Testing

Fuzz tests run with random inputs to find unexpected bugs:

```solidity
function testFuzz_SetNumber(uint256 _number) public {
    // Foundry runs this 256 times with random uint256 values
    datatypes.setNumber(_number);
    assertEq(datatypes.getNumber(), _number);
}
```

**Bounding fuzz inputs** (to avoid overflow):
```solidity
function testFuzz_IncrementNumber(uint256 _start) public {
    // Bound input to avoid overflow
    _start = bound(_start, 0, type(uint256).max - 1);
    
    datatypes.setNumber(_start);
    datatypes.incrementNumber();
    assertEq(datatypes.getNumber(), _start + 1);
}
```

### Gas Benchmarking

Measure gas costs to understand performance:

```solidity
function test_Gas_SetNumber_Cold() public {
    uint256 gasBefore = gasleft();
    datatypes.setNumber(42);  // Cold write (first time)
    uint256 gasUsed = gasBefore - gasleft();
    
    console.log("Gas used for cold setNumber:", gasUsed);
}
```

### Invariant Testing

Test properties that should ALWAYS be true:

```solidity
function invariant_OwnerNeverChanges() public {
    // Owner should never change, no matter what operations are performed
    assertEq(datatypes.owner(), owner, "Owner should never change");
}
```

## Project-Specific Examples

### Testing Value Types

```solidity
function test_SetNumber() public {
    uint256 newNumber = 42;
    datatypes.setNumber(newNumber);
    assertEq(datatypes.getNumber(), newNumber);
}

function test_IncrementNumber() public {
    datatypes.setNumber(5);
    datatypes.incrementNumber();
    assertEq(datatypes.getNumber(), 6);
}
```

### Testing Mappings

```solidity
function test_SetBalance() public {
    datatypes.setBalance(user1, 1000);
    assertEq(datatypes.getBalance(user1), 1000);
}

function test_GetBalance_ReturnsZeroForNewAddress() public {
    // Mappings return default values (0) for non-existent keys
    assertEq(datatypes.getBalance(user1), 0);
}

function test_SetBalance_IndependentAddresses() public {
    datatypes.setBalance(user1, 100);
    datatypes.setBalance(user2, 200);
    assertEq(datatypes.getBalance(user1), 100);
    assertEq(datatypes.getBalance(user2), 200);
}
```

### Testing Arrays

```solidity
function test_AddNumber_IncreasesLength() public {
    assertEq(datatypes.getNumbersLength(), 0);
    datatypes.addNumber(42);
    assertEq(datatypes.getNumbersLength(), 1);
    datatypes.addNumber(100);
    assertEq(datatypes.getNumbersLength(), 2);
}

function test_GetNumberAt_RevertsOnOutOfBounds() public {
    datatypes.addNumber(42);
    vm.expectRevert("Index out of bounds");
    datatypes.getNumberAt(1);  // Only index 0 exists
}
```

### Testing Structs

```solidity
function test_RegisterUser() public {
    datatypes.registerUser(user1, 500);
    
    (address wallet, uint256 balance, bool isRegistered) = datatypes.getUser(user1);
    assertEq(wallet, user1);
    assertEq(balance, 500);
    assertTrue(isRegistered);
}
```

### Testing Data Locations

```solidity
function test_SumMemoryArray() public {
    uint256[] memory arr = new uint256[](4);
    arr[0] = 10;
    arr[1] = 20;
    arr[2] = 30;
    arr[3] = 40;
    
    uint256 sum = datatypes.sumMemoryArray(arr);
    assertEq(sum, 100);
}

function test_GetFirstElement() public {
    uint256[] memory arr = new uint256[](3);
    arr[0] = 100;
    arr[1] = 200;
    arr[2] = 300;
    
    uint256 first = datatypes.getFirstElement(arr);
    assertEq(first, 100);
}
```

## Running Tests

```bash
# Navigate to project directory
cd 01-datatypes-and-storage

# Run all tests (Foundry compiles automatically)
forge test

# Run with verbose output (shows detailed traces)
forge test -vvv

# Run with gas reporting
forge test --gas-report

# Run specific test
forge test --match-test test_SetNumber

# Run tests matching a pattern
forge test --match-test "test_Set*"

# Run only fuzz tests
forge test --match-test "testFuzz_*"

# Generate coverage report
forge coverage

# Run tests and show only failures
forge test --no-match-test "testFuzz"
```

## Debugging Failed Tests

When a test fails, Foundry provides detailed error messages:

```bash
# Use -vvv for maximum verbosity
forge test -vvv

# This shows:
# - Full stack trace
# - State changes
# - Gas usage
# - Event emissions
# - Revert reasons
```

**Common issues**:
1. **Test not running**: Check function name starts with "test"
2. **Assertion failure**: Check expected vs actual values
3. **Revert not caught**: Make sure `vm.expectRevert()` is called before the failing function
4. **Event not emitted**: Check event signature matches contract
5. **Wrong caller**: Use `vm.prank()` to set the caller

## Comparing with Solution

After you've written your tests, compare with the solution file:

**Solution location**: `test/solution/DatatypesStorageSolution.t.sol`

**What to look for**:
- ✅ Did you cover all the same test cases?
- ✅ Are your test names clear and descriptive?
- ✅ Did you test edge cases?
- ✅ Are your assertions specific?
- ✅ Did you use fuzz testing where appropriate?
- ✅ Are your tests isolated (no dependencies)?

**Remember**: The solution is a reference, not a template to copy. Your tests might be different but still correct!

## Final Thoughts

Testing smart contracts is CRITICAL because:
1. You can't update contracts after deployment (bugs are permanent!)
2. Bugs can cost millions (see: DAO hack, Parity freeze, etc.)
3. Users trust you with their money (don't break that trust!)
4. Writing tests helps you understand your code better

The time you spend writing tests now saves you from disaster later. Every major Ethereum hack could have been prevented with better testing.

**For this project**:
- Start with simple tests (constructor, basic getters/setters)
- Build up to more complex tests (arrays, structs, data locations)
- Don't forget edge cases and error conditions
- Use fuzz testing to find unexpected bugs
- Write tests as you implement the contract (not after!)

Happy testing! 🧪

---

**Next Steps**:
1. Open `test/DatatypesStorage.t.sol`
2. Read through all the TODOs and comments
3. Start implementing tests one section at a time
4. Run `forge test` frequently to see your progress
5. Compare with the solution after you're done
