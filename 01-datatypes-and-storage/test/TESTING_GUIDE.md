# Testing Guide for Solidity Smart Contracts

## What is a Test File?

Think of a test file as a quality control inspector in a factory. Just like an inspector checks every product to make sure it works correctly before shipping, our test file checks every function in our smart contract to ensure it behaves exactly as expected.

## Why Do We Test?

1. **Catch Bugs Before Deployment**: Once a contract is on the blockchain, you CAN'T change it. A bug in production could mean lost funds forever. Testing is your safety net.

2. **Document Expected Behavior**: Tests serve as living documentation. Someone reading your tests can understand exactly what your contract should do, with concrete examples.

3. **Prevent Regressions**: When you add new features, tests ensure you didn't accidentally break existing functionality.

4. **Build Confidence**: Good tests let you refactor code fearlessly, knowing you'll catch any mistakes immediately.

## What Makes a Good Test?

A good test file accomplishes these goals:

1. **Comprehensive Coverage**: Test the "happy path" (normal usage) AND edge cases (unusual inputs, boundary conditions, error states)

2. **Isolation**: Each test should be independent. Tests shouldn't depend on running in a specific order or affect each other.

3. **Clarity**: Test names should clearly describe what they're testing. Reading the test should be like reading a story.

4. **Assertion Quality**: Each test should verify ONE specific behavior. More focused tests make debugging easier.

## Testing Best Practices

### 1. Test Naming Convention

Good test names are like newspaper headlines - they tell you the whole story:

- `test_FunctionName_Scenario`
  - Example: `test_SetNumber_UpdatesValue`
  - Example: `test_IncrementNumber_RevertsOnOverflow`

- `testFuzz_FunctionName` for fuzz tests
  - Example: `testFuzz_SetBalance`

- `invariant_PropertyName` for invariant tests
  - Example: `invariant_OwnerNeverChanges`

**Why?** When a test fails, you want to know EXACTLY what broke by reading the test name.

### 2. What to Test (Comprehensive Coverage)

A complete test suite covers FIVE categories:

✓ **Happy Path** (Normal Operations)
- Test the function with typical, expected inputs
- Example: Set a balance to 100, verify it equals 100
- This is what users will do 99% of the time

✓ **Edge Cases** (Boundary Conditions)
- Test extreme values: 0, maximum, empty arrays, etc.
- Example: Set balance to `type(uint256).max`
- Bugs love to hide at the edges!

✓ **Reverts** (Error Conditions)
- Test that your contract FAILS when it should
- Example: Overflow should revert, not wrap around
- Use `vm.expectRevert()` for these tests

✓ **Events** (Logging)
- Verify important actions emit the correct events
- Frontend apps rely on events for UI updates!

✓ **Gas Costs** (Performance)
- Benchmark critical operations to track gas usage
- Small optimizations can save users thousands in gas fees!

### 3. Test Isolation

Each test should be completely independent:

- `setUp()` runs BEFORE EACH test
- Don't rely on test execution order
- Don't share state between tests

### 4. How to Know What to Test

Ask yourself these questions for each function:

1. What is the HAPPY PATH? (Test it!)
2. What can go WRONG? (Test it!)
3. What are the BOUNDARIES? (Test them!)
4. What are the SIDE EFFECTS? (Test them!)
5. What are the ASSUMPTIONS? (Test them!)

## Common Testing Patterns

### Arrange-Act-Assert Pattern

```solidity
function test_SetNumber() public {
    // Arrange: Set up test data
    uint256 newNumber = 42;

    // Act: Perform the action
    datatypes.setNumber(newNumber);

    // Assert: Verify the result
    assertEq(datatypes.getNumber(), newNumber);
}
```

### Testing Reverts

```solidity
function test_IncrementNumber_RevertsOnOverflow() public {
    datatypes.setNumber(type(uint256).max);
    vm.expectRevert();  // Expect the next call to fail
    datatypes.incrementNumber();
}
```

### Testing Events

```solidity
function test_SetNumber_EmitsEvent() public {
    vm.expectEmit(false, false, false, true);
    emit NumberUpdated(0, 100);
    datatypes.setNumber(100);
}
```

### Fuzz Testing

```solidity
function testFuzz_SetNumber(uint256 _number) public {
    // Foundry runs this 256 times with random values
    datatypes.setNumber(_number);
    assertEq(datatypes.getNumber(), _number);
}
```

## Running Tests

```bash
forge test                           # Run all tests
forge test -vvv                      # Verbose output (shows trace)
forge test --gas-report              # Show gas usage
forge test --match-test SetNumber    # Run tests matching "SetNumber"
forge coverage                       # Generate coverage report
```

## Final Thoughts

Testing smart contracts is CRITICAL because:
1. You can't update contracts after deployment (bugs are permanent!)
2. Bugs can cost millions (see: DAO hack, Parity freeze, etc.)
3. Users trust you with their money (don't break that trust!)

The time you spend writing tests now saves you from disaster later. Every major Ethereum hack could have been prevented with better testing.

Happy testing! 🧪
