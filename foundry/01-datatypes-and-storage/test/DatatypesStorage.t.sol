// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/DatatypesStorageSolution.sol";

/**
 * @title DatatypesStorageTest
 * @notice Skeleton test suite for DatatypesStorage contract
 * @dev Complete the TODOs to implement comprehensive tests
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          WHAT IS A TEST FILE?
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * Think of a test file as a quality control inspector in a factory. Just like
 * an inspector checks every product to make sure it works correctly before
 * shipping, our test file checks every function in our smart contract to ensure
 * it behaves exactly as expected.
 *
 * WHY DO WE TEST?
 *
 * 1. **Catch Bugs Before Deployment**: Once a contract is on the blockchain,
 *    you CAN'T change it. A bug in production could mean lost funds forever.
 *    Testing is your safety net.
 *
 * 2. **Document Expected Behavior**: Tests serve as living documentation.
 *    Someone reading your tests can understand exactly what your contract
 *    should do, with concrete examples.
 *
 * 3. **Prevent Regressions**: When you add new features, tests ensure you
 *    didn't accidentally break existing functionality.
 *
 * 4. **Build Confidence**: Good tests let you refactor code fearlessly,
 *    knowing you'll catch any mistakes immediately.
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        FOUNDRY TESTING BASICS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * Foundry's testing framework follows these conventions:
 *
 * - **Test functions MUST start with "test"**: This is how Foundry identifies
 *   which functions to run. `testSetNumber()` runs, `checkNumber()` doesn't.
 *
 * - **setUp() runs before EACH test**: Think of it like resetting the game
 *   board before each round. This ensures every test starts from the same
 *   clean state (isolation!).
 *
 * - **Assertions verify behavior**:
 *   - `assertEq(a, b)`: Check if two values are equal
 *   - `assertTrue(x)`: Check if something is true
 *   - `assertFalse(x)`: Check if something is false
 *   - `vm.expectRevert()`: Check that the next call fails (reverts)
 *
 * - **Cheatcodes control the environment** (vm.*):
 *   - `vm.prank(address)`: Next call pretends to come from that address
 *   - `vm.deal(address, amount)`: Give an address some ETH
 *   - `vm.expectEmit()`: Check that an event was emitted
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                      HOW TO RUN TESTS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * forge test                    # Run all tests
 * forge test -vvv               # Verbose mode - see detailed output
 * forge test --gas-report       # Show gas costs for each function
 * forge test --match-test testSetNumber  # Run only tests matching this name
 * forge coverage                # See which lines of code are tested
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                      THIS TEST FILE SHOULD COVER:
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ✓ Constructor behavior (initial state)
 * ✓ Value type operations (uint256, address, bool)
 * ✓ Mapping operations (set, get, check existence)
 * ✓ Array operations (push, access, length, remove)
 * ✓ Struct operations (create, read, update)
 * ✓ Data location behavior (storage vs memory vs calldata)
 * ✓ Event emissions (logging important state changes)
 * ✓ Edge cases (max values, empty arrays, zero address)
 * ✓ Gas measurements (comparing costs of different approaches)
 * ✓ Fuzz testing (randomized inputs to find unexpected bugs)
 * ✓ Invariant testing (properties that should ALWAYS be true)
 *
 */
contract DatatypesStorageTest is Test {
    DatatypesStorageSolution public datatypes;

    address public owner;
    address public user1;
    address public user2;

    // Event declarations for testing (must match contract events)
    // TODO: Declare events that match the contract's events
    // Hint: Check the contract for event declarations like:
    //       event NumberUpdated(uint256 oldValue, uint256 newNumber);
    //       event UserRegistered(address indexed wallet, uint256 balance);

    /**
     * ═══════════════════════════════════════════════════════════════════════
     *                           setUp() FUNCTION
     * ═══════════════════════════════════════════════════════════════════════
     *
     * This special function runs BEFORE EACH AND EVERY test function.
     *
     * WHY?
     * Isolation! We want each test to start from a clean slate, like resetting
     * a video game before each level. If Test A modifies the contract and
     * Test B depends on that modification, our tests become fragile and
     * hard to debug.
     *
     * WHAT HAPPENS HERE:
     * 1. We create test addresses (owner, user1, user2)
     * 2. We deploy a FRESH instance of DatatypesStorageSolution
     * 3. We label addresses for better debugging output
     *
     * IMPORTANT: Even if Test A sets number = 100, when Test B runs,
     * setUp() will deploy a brand new contract where number = 0 again.
     * This is GOOD - it prevents tests from interfering with each other!
     *
     * @dev Runs before each test function
     *      Creates fresh contract instance for each test (isolation)
     */
    function setUp() public {
        // TODO: Set owner to address(this) - the test contract is the deployer
        owner = address(this);
        // TODO: Create user1 and user2 addresses (use address(0x1) and address(0x2))
        user1 = address(0x1);
        user2 = address(0x2);

        // TODO: Deploy a new DatatypesStorageSolution contract instance
        datatypes = new DatatypesStorageSolution();
        // TODO: Use vm.label() to label addresses for better debugging output
        //       Example: vm.label(owner, "Owner");
        vm.label(owner, "Owner");
        vm.label(user1, "User1");
        vm.label(user2, "User2");
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          CONSTRUCTOR TESTS
    // ═══════════════════════════════════════════════════════════════════════
    //
    // WHY TEST THE CONSTRUCTOR?
    // The constructor runs once when the contract is deployed. It sets up the
    // initial state. If the constructor has a bug, EVERY deployment will start
    // in a broken state. Testing it ensures the contract initializes correctly.
    //
    // WHAT TO TEST:
    // - Check that all initial values are set correctly
    // - Verify that ownership is assigned properly
    // - Ensure any flags (like isActive) start in the expected state

    /**
     * @notice Tests that the constructor correctly sets the owner
     * @dev Use assertEq to check that datatypes.owner() equals the owner variable
     */
    function test_Constructor_SetsOwner() public {
        // TODO: Assert that datatypes.owner() equals owner
        // Hint: assertEq(datatypes.owner(), owner, "Owner should be set to deployer");
        assertEq(datatypes.owner(), owner, "Owner should be set to deployer");
    }

    /**
     * @notice Tests that the constructor correctly sets isActive to true
     * @dev Use assertTrue to check that datatypes.isActive() returns true
     */
    function test_Constructor_SetsIsActive() public {
        // TODO: Assert that datatypes.isActive() is true
        // Hint: assertTrue(datatypes.isActive(), "Contract should be active on deployment");
        assertTrue(datatypes.isActive(), "Contract should be active on deployment");
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          VALUE TYPE TESTS
    // ═══════════════════════════════════════════════════════════════════════
    //
    // WHY TEST VALUE TYPES?
    // Value types (uint, address, bool, etc.) are the building blocks of your
    // contract's state. Testing them ensures basic state management works.
    //
    // WHAT TO TEST FOR VALUE TYPES:
    // 1. Setting values (write operations)
    // 2. Getting values (read operations)
    // 3. Edge cases (zero, max values, overflow protection)
    // 4. Events (are state changes properly logged?)

    /**
     * @notice Tests setting a number value
     * @dev Test the "happy path" - normal expected use case
     *      Pattern: Arrange → Act → Assert
     */
    function test_SetNumber() public {
        // TODO: Set a number (e.g., 42) using datatypes.setNumber()
        uint256 newNumber = 42;
        datatypes.setNumber(newNumber);
        // TODO: Assert that datatypes.getNumber() returns the value you set
        assertEq(datatypes.getNumber(), newNumber, "Number should be updated");
       
    }

    /**
     * @notice Tests that setNumber emits the correct event
     * @dev Use vm.expectEmit() to check event emissions
     *      Parameters: vm.expectEmit(false, false, false, true)
     *      Then emit the expected event, then call the function
     */
    function test_SetNumber_EmitsEvent() public {
        // TODO: Set up vm.expectEmit(false, false, false, true)
        vm.expectEmit(false, false, false, true);
        // TODO: Emit the expected NumberUpdated event (check contract for event signature)
        vm.expectEmit(false, false, false, true);
        emit NumberUpdated(oldNumber, newNumber);
        // TODO: Call datatypes.setNumber() with a value
        // Hint: You'll need to know the old value (0 initially) and new value
        datatypes.setNumber(newNumber);
        assertEq(datatypes.getNumber(), newNumber, "Number should be updated");
    }

    /**
     * @notice Tests that getNumber returns the correct initial value
     * @dev Check initial state, then set and verify
     */
    function test_GetNumber_ReturnsCorrectValue() public {
        // TODO: Assert that initial number is 0
        // TODO: Set number to 123
        // TODO: Assert that getNumber() returns 123
    }

    /**
     * @notice Tests incrementing the number
     * @dev Set a number, increment it, verify it increased by 1
     */
    function test_IncrementNumber() public {
        // TODO: Set number to 5
        uint256 newNumber = 5;
        datatypes.setNumber(newNumber);
        // TODO: Call incrementNumber()
        datatypes.incrementNumber();
        // TODO: Assert that number is now 6
        assertEq(datatypes.getNumber(), 6, "Number should be incremented by 1");
    }

    /**
     * @notice Tests incrementing from zero
     * @dev Verify incrementing from 0 works correctly
     */
    function test_IncrementNumber_FromZero() public {
        // TODO: Assert initial number is 0
        uint256 newNumber = 0;
        datatypes.setNumber(newNumber); 
        // TODO: Call incrementNumber()
        datatypes.incrementNumber();
        // TODO: Assert number is now 1
        assertEq(datatypes.getNumber(), 1, "Number should be incremented by 1");
    }

    /**
     * @notice Tests that incrementNumber reverts when it would overflow
     * @dev Set number to type(uint256).max, then try to increment
     *      Use vm.expectRevert() before the call that should fail
     */
    function test_IncrementNumber_RevertsOnOverflow() public {
        // TODO: Set number to type(uint256).max
        uint256 newNumber = type(uint256).max;
        datatypes.setNumber(newNumber);
        // TODO: Use vm.expectRevert() to expect a revert
        vm.expectRevert();
        // TODO: Call incrementNumber() - this should revert
        datatypes.incrementNumber();
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          MAPPING TESTS
    // ═══════════════════════════════════════════════════════════════════════
    //
    // WHY TEST MAPPINGS?
    // Mappings are like databases - they store key-value pairs. Most contracts
    // use mappings extensively (token balances, user data, permissions). Testing
    // them ensures your "database" works correctly!
    //
    // WHAT TO TEST FOR MAPPINGS:
    // 1. Setting values (write operations)
    // 2. Getting values (read operations)
    // 3. Default values (what happens for non-existent keys?)
    // 4. Independence (changing one key doesn't affect others)
    // 5. Updates (overwriting existing values)

    /**
     * @notice Tests setting a balance for an address
     * @dev Basic "write then read" pattern for mappings
     */
    function test_SetBalance() public {
        // TODO: Set balance for user1 to 1000
        uint256 newBalance = 1000;
        datatypes.setBalance(user1, newBalance);
        // TODO: Assert that getBalance(user1) returns 1000
    }

    /**
     * @notice Tests that getBalance returns zero for new addresses
     * @dev Mappings return default values (0 for uint256) for non-existent keys
     */
    function test_GetBalance_ReturnsZeroForNewAddress() public {
        // TODO: Assert that getBalance(user1) returns 0 without setting it first
    }

    /**
     * @notice Tests updating an existing balance
     * @dev Set balance twice, verify second value overwrites first
     */
    function test_SetBalance_UpdatesExistingBalance() public {
        // TODO: Set balance to 100, then to 200
        // TODO: Assert balance is 200 (not 100)
    }

    /**
     * @notice Tests that balances are independent for different addresses
     * @dev Set different balances for user1 and user2, verify both are correct
     */
    function test_SetBalance_IndependentAddresses() public {
        // TODO: Set user1 balance to 100
        // TODO: Set user2 balance to 200
        // TODO: Assert both balances are correct independently
    }

    /**
     * @notice Tests hasBalance returns true for non-zero balance
     * @dev Set a balance, verify hasBalance returns true
     */
    function test_HasBalance_ReturnsTrueForNonZero() public {
        // TODO: Set balance to 1
        // TODO: Assert hasBalance returns true
    }

    /**
     * @notice Tests hasBalance returns false for zero balance
     * @dev Don't set balance, verify hasBalance returns false
     */
    function test_HasBalance_ReturnsFalseForZero() public {
        // TODO: Assert hasBalance returns false for user1 (no balance set)
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          ARRAY TESTS
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * @notice Tests that adding numbers increases array length
     * @dev Verify length increases with each addNumber() call
     */
    function test_AddNumber_IncreasesLength() public {
        // TODO: Assert initial length is 0
        // TODO: Add a number, assert length is 1
        // TODO: Add another number, assert length is 2
    }

    /**
     * @notice Tests that added numbers are stored correctly
     * @dev Add numbers and verify they're at the correct indices
     */
    function test_AddNumber_StoresCorrectValue() public {
        // TODO: Add number 42, verify it's at index 0
        // TODO: Add number 100, verify it's at index 1
    }

    /**
     * @notice Tests that getNumberAt reverts on out of bounds access
     * @dev Add one number, try to access index 1, expect revert
     */
    function test_GetNumberAt_RevertsOnOutOfBounds() public {
        // TODO: Add one number
        // TODO: Use vm.expectRevert("Index out of bounds")
        // TODO: Try to get number at index 1 (should revert)
    }

    /**
     * @notice Tests that getNumbersLength returns correct length
     * @dev Add multiple numbers in a loop, verify length
     */
    function test_GetNumbersLength_ReturnsCorrectLength() public {
        // TODO: Add 5 numbers in a loop (0 to 4)
        // TODO: Assert length is 5
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          STRUCT TESTS
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * @notice Tests registering a user
     * @dev Register user, then get user data and verify all fields
     */
    function test_RegisterUser() public {
        // TODO: Register user1 with balance 500
        // TODO: Get user data using getUser(user1)
        // TODO: Assert wallet, balance, and isRegistered are correct
        // Hint: (address wallet, uint256 balance, bool isRegistered) = datatypes.getUser(user1);
    }

    /**
     * @notice Tests that registerUser emits the correct event
     * @dev Use vm.expectEmit() to verify event emission
     */
    function test_RegisterUser_EmitsEvent() public {
        // TODO: Set up vm.expectEmit(true, false, false, true) - first param true for indexed
        // TODO: Emit UserRegistered event with user1 and balance
        // TODO: Call registerUser()
    }

    /**
     * @notice Tests updating an existing user
     * @dev Register user twice with different balances, verify update
     */
    function test_RegisterUser_UpdatesExistingUser() public {
        // TODO: Register user1 with balance 100
        // TODO: Register user1 again with balance 200
        // TODO: Verify balance is 200 (updated)
    }

    /**
     * @notice Tests that getUser returns default values for non-existent users
     * @dev Get user data without registering, verify default values
     */
    function test_GetUser_ReturnsDefaultForNonExistent() public {
        // TODO: Get user data for user1 without registering
        // TODO: Assert wallet is address(0), balance is 0, isRegistered is false
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          DATA LOCATION TESTS
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * @notice Tests summing a memory array
     * @dev Create a memory array, sum it, verify result
     */
    function test_SumMemoryArray() public {
        // TODO: Create a memory array with values [10, 20, 30, 40]
        // TODO: Call sumMemoryArray() and assert result is 100
        // Hint: uint256[] memory arr = new uint256[](4);
        //       arr[0] = 10; arr[1] = 20; etc.
    }

    /**
     * @notice Tests summing an empty array
     * @dev Sum empty array, verify result is 0
     */
    function test_SumMemoryArray_EmptyArray() public {
        // TODO: Create empty memory array
        // TODO: Sum it and assert result is 0
    }

    /**
     * @notice Tests summing a single element array
     * @dev Sum array with one element, verify result
     */
    function test_SumMemoryArray_SingleElement() public {
        // TODO: Create array with single element 42
        // TODO: Sum it and assert result is 42
    }

    /**
     * @notice Tests getting first element from calldata array
     * @dev Create memory array, call getFirstElement, verify result
     */
    function test_GetFirstElement() public {
        // TODO: Create memory array [100, 200, 300]
        // TODO: Call getFirstElement() and assert result is 100
    }

    /**
     * @notice Tests that getFirstElement reverts on empty array
     * @dev Create empty array, expect revert when getting first element
     */
    function test_GetFirstElement_RevertsOnEmpty() public {
        // TODO: Create empty memory array
        // TODO: Use vm.expectRevert("Array is empty")
        // TODO: Call getFirstElement() - should revert
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          ADVANCED TESTS
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * @notice Tests setting a message string
     * @dev Set message and verify it's stored correctly
     */
    function test_SetMessage() public {
        // TODO: Set message to "Hello World"
        // TODO: Assert message() returns "Hello World"
    }

    /**
     * @notice Tests depositing ETH increases balance
     * @dev Use vm.deal() to give user1 ETH, then deposit
     */
    function test_Deposit_IncreasesBalance() public {
        // TODO: Use vm.deal(user1, 1 ether) to give user1 ETH
        // TODO: Use vm.prank(user1) to make next call from user1
        // TODO: Call deposit{value: 1 ether}()
        // TODO: Assert balance is updated
    }

    /**
     * @notice Tests that deposit reverts on zero amount
     * @dev Try to deposit 0 ETH, expect revert
     */
    function test_Deposit_RevertsOnZeroAmount() public {
        // TODO: Use vm.prank(user1)
        // TODO: Use vm.expectRevert()
        // TODO: Call deposit{value: 0}() - should revert
    }

    /**
     * @notice Tests removing a number from array
     * @dev Add numbers, remove one, verify correct removal
     */
    function test_RemoveNumber() public {
        // TODO: Add numbers [10, 20, 30]
        // TODO: Remove number at index 1
        // TODO: Assert length is 2
        // TODO: Assert element at index 1 is now 30 (last element moved)
    }

    /**
     * @notice Tests that removeNumber reverts on out of bounds
     * @dev Add one number, try to remove at invalid index
     */
    function test_RemoveNumber_RevertsOnOutOfBounds() public {
        // TODO: Add one number
        // TODO: Use vm.expectRevert()
        // TODO: Try to remove at index 1 (should revert)
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          FUZZ TESTS
    // ═══════════════════════════════════════════════════════════════════════
    //
    // WHAT IS FUZZ TESTING?
    // Fuzz testing automatically generates HUNDREDS of random inputs and runs
    // your test with each one. This finds edge cases you never thought of!
    //
    // HOW IT WORKS IN FOUNDRY:
    // 1. Name your test function starting with "testFuzz_"
    // 2. Add parameters to the function (uint256 _number, address _addr, etc.)
    // 3. Foundry runs the test 256 times (default) with random values
    // 4. If ANY run fails, the test fails and shows you the problematic input

    /**
     * @notice Fuzz test for setNumber - tests with random uint256 values
     * @dev Foundry will generate random values for _number
     */
    function testFuzz_SetNumber(uint256 _number) public {
        // TODO: Set number to _number
        // TODO: Assert getNumber() equals _number
    }

    /**
     * @notice Fuzz test for setBalance - tests with random addresses and values
     * @dev Foundry will generate random address and balance
     */
    function testFuzz_SetBalance(address _addr, uint256 _balance) public {
        // TODO: Set balance for _addr to _balance
        // TODO: Assert getBalance(_addr) equals _balance
    }

    /**
     * @notice Fuzz test for incrementNumber with bounded inputs
     * @dev Use bound() to constrain _start to avoid overflow
     */
    function testFuzz_IncrementNumber(uint256 _start) public {
        // TODO: Bound _start to [0, type(uint256).max - 1] using bound()
        // TODO: Set number to _start
        // TODO: Call incrementNumber()
        // TODO: Assert number equals _start + 1
        // Hint: _start = bound(_start, 0, type(uint256).max - 1);
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          GAS BENCHMARKING
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * @notice Benchmark gas cost of setting a number (first time - cold storage)
     * @dev Use gasleft() before and after to measure gas
     */
    function test_Gas_SetNumber_Cold() public {
        // TODO: Record gasleft() before call
        // TODO: Call setNumber(42)
        // TODO: Calculate gas used (gasBefore - gasleft())
        // TODO: Emit log_named_uint("Gas used for cold setNumber", gasUsed)
    }

    /**
     * @notice Benchmark gas cost of setting a number (second time - warm storage)
     * @dev First call warms storage, second call should be cheaper
     */
    function test_Gas_SetNumber_Warm() public {
        // TODO: Call setNumber(42) once (cold write)
        // TODO: Record gasleft() before second call
        // TODO: Call setNumber(100) (warm write)
        // TODO: Calculate and log gas used
    }

    /**
     * @notice Benchmark gas cost of array operations
     * @dev Measure gas for adding numbers to array
     */
    function test_Gas_ArrayOperations() public {
        // TODO: Measure gas for first addNumber() call
        // TODO: Measure gas for second addNumber() call
        // TODO: Log both gas costs
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          EDGE CASES
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * @notice Tests handling of maximum uint256 value
     * @dev Set number to type(uint256).max and verify it works
     */
    function test_EdgeCase_MaxUint256() public {
        // TODO: Set number to type(uint256).max
        // TODO: Assert getNumber() returns type(uint256).max
    }

    /**
     * @notice Tests handling of zero address
     * @dev Set balance for address(0) and verify it works
     */
    function test_EdgeCase_ZeroAddress() public {
        // TODO: Set balance for address(0) to 100
        // TODO: Assert getBalance(address(0)) returns 100
    }

    /**
     * @notice Tests handling of large arrays
     * @dev Add many elements and verify length
     */
    function test_EdgeCase_LargeArray() public {
        // TODO: Add 10 numbers in a loop
        // TODO: Assert length is 10
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          INVARIANT TESTS
    // ═══════════════════════════════════════════════════════════════════════
    //
    // WHAT ARE INVARIANTS?
    // Properties that should ALWAYS be true, no matter what operations are
    // performed. Foundry can run these repeatedly with random operations.

    /**
     * @notice Invariant: Owner should never change
     * @dev Function name starts with "invariant_" for Foundry to recognize it
     */
    function invariant_OwnerNeverChanges() public {
        // TODO: Assert that owner never changes
        // TODO: Assert datatypes.owner() equals owner
    }

    /**
     * @notice Invariant: Array length should always be consistent
     * @dev Verify length is never negative (always >= 0)
     */
    function invariant_ArrayLengthConsistent() public {
        // TODO: Get array length
        // TODO: Assert length >= 0 (should always be true for uint256)
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                        TESTING BEST PRACTICES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. TEST NAMING CONVENTION
 *    test_FunctionName_Scenario
 *    testFuzz_FunctionName for fuzz tests
 *    invariant_PropertyName for invariant tests
 *
 * 2. COVERAGE
 *    Happy path (normal operations)
 *    Edge cases (max values, empty inputs, zero address)
 *    Reverts (invalid inputs, overflow, out of bounds)
 *    Events (verify emissions)
 *    Gas costs (benchmark critical operations)
 *
 * 3. ISOLATION
 *    Each test should be independent
 *    setUp() runs before each test
 *    Don't rely on test execution order
 *
 * 4. ASSERTIONS
 *    assertEq: Check equality
 *    assertTrue/False: Check booleans
 *    assertGt/Lt: Check comparisons
 *    vm.expectRevert: Check reverts
 *
 * 5. GAS AWARENESS
 *    Use gasleft() for manual measurements
 *    Use --gas-report flag for automated reports
 *    Benchmark critical operations
 *
 *                            RUN TESTS                                      
 *
 * forge test                   # Run all tests
 * forge test -vvv              # Run with verbose output
 * forge test --gas-report      # Run with gas reporting
 * forge test --match-test test_SetNumber  # Run specific test
 * forge test --match-contract DatatypesStorageTest  # Run specific contract
 * forge coverage               # Generate coverage report
 *
 *                            STUDY THE SOLUTION
 *
 * After implementing your tests, compare with:
 * test/solution/DatatypesStorageSolution.t.sol
 */
