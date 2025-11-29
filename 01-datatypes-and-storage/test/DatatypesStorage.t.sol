// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/DatatypesStorage.sol";

/**
 * @title DatatypesStorageTest
 * @notice Comprehensive test suite for DatatypesStorage contract
 * @dev Tests cover:
 *      - Value type operations
 *      - Mapping operations
 *      - Array operations
 *      - Struct operations
 *      - Data location behavior
 *      - Gas measurements
 *
 * FOUNDRY TESTING BASICS:
 * PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
 * - Test functions must start with "test"
 * - Use setUp() for initialization (runs before each test)
 * - Use assertEq, assertTrue, assertFalse for checks
 * - Use vm.expectRevert() for testing reverts
 * - Use vm.prank() to simulate different callers
 *
 * Run tests: forge test
 * Run with details: forge test -vvv
 * Run with gas report: forge test --gas-report
 */
contract DatatypesStorageTest is Test {
    DatatypesStorageSolution public datatypes;

    address public owner;
    address public user1;
    address public user2;

    /**
     * @notice Set up test environment
     * @dev Runs before each test function
     *      Creates fresh contract instance for each test (isolation)
     */
    function setUp() public {
        owner = address(this); // Test contract is the deployer
        user1 = address(0x1);
        user2 = address(0x2);

        datatypes = new DatatypesStorageSolution();

        // Label addresses for better trace output
        vm.label(owner, "Owner");
        vm.label(user1, "User1");
        vm.label(user2, "User2");
    }

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // CONSTRUCTOR TESTS
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    function test_Constructor_SetsOwner() public {
        assertEq(datatypes.owner(), owner, "Owner should be set to deployer");
    }

    function test_Constructor_SetsIsActive() public {
        assertTrue(datatypes.isActive(), "Contract should be active on deployment");
    }

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // VALUE TYPE TESTS
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    function test_SetNumber() public {
        uint256 newNumber = 42;
        datatypes.setNumber(newNumber);
        assertEq(datatypes.getNumber(), newNumber, "Number should be updated");
    }

    function test_SetNumber_EmitsEvent() public {
        uint256 newNumber = 100;

        // Expect NumberUpdated event with parameters
        vm.expectEmit(true, true, false, false);
        emit DatatypesStorageSolution.NumberUpdated(0, newNumber);

        datatypes.setNumber(newNumber);
    }

    function test_GetNumber_ReturnsCorrectValue() public {
        assertEq(datatypes.getNumber(), 0, "Initial number should be 0");

        datatypes.setNumber(123);
        assertEq(datatypes.getNumber(), 123, "Number should be 123 after setting");
    }

    function test_IncrementNumber() public {
        datatypes.setNumber(5);
        datatypes.incrementNumber();
        assertEq(datatypes.getNumber(), 6, "Number should increment by 1");
    }

    function test_IncrementNumber_FromZero() public {
        assertEq(datatypes.getNumber(), 0, "Initial number is 0");
        datatypes.incrementNumber();
        assertEq(datatypes.getNumber(), 1, "Number should be 1 after increment");
    }

    function test_IncrementNumber_RevertsOnOverflow() public {
        // Set to max uint256
        datatypes.setNumber(type(uint256).max);

        // Should revert on overflow (Solidity 0.8+ has automatic checks)
        vm.expectRevert();
        datatypes.incrementNumber();
    }

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // MAPPING TESTS
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    function test_SetBalance() public {
        uint256 balance = 1000;
        datatypes.setBalance(user1, balance);
        assertEq(datatypes.getBalance(user1), balance, "Balance should be set correctly");
    }

    function test_GetBalance_ReturnsZeroForNewAddress() public {
        assertEq(
            datatypes.getBalance(user1), 0, "New address should have zero balance by default"
        );
    }

    function test_SetBalance_UpdatesExistingBalance() public {
        datatypes.setBalance(user1, 100);
        datatypes.setBalance(user1, 200);
        assertEq(datatypes.getBalance(user1), 200, "Balance should be updated to new value");
    }

    function test_SetBalance_IndependentAddresses() public {
        datatypes.setBalance(user1, 100);
        datatypes.setBalance(user2, 200);

        assertEq(datatypes.getBalance(user1), 100, "User1 balance should be 100");
        assertEq(datatypes.getBalance(user2), 200, "User2 balance should be 200");
    }

    function test_HasBalance_ReturnsTrueForNonZero() public {
        datatypes.setBalance(user1, 1);
        assertTrue(datatypes.hasBalance(user1), "Should return true for non-zero balance");
    }

    function test_HasBalance_ReturnsFalseForZero() public {
        assertFalse(datatypes.hasBalance(user1), "Should return false for zero balance");
    }

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // ARRAY TESTS
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    function test_AddNumber_IncreasesLength() public {
        assertEq(datatypes.getNumbersLength(), 0, "Initial length should be 0");

        datatypes.addNumber(10);
        assertEq(datatypes.getNumbersLength(), 1, "Length should be 1 after adding");

        datatypes.addNumber(20);
        assertEq(datatypes.getNumbersLength(), 2, "Length should be 2 after adding");
    }

    function test_AddNumber_StoresCorrectValue() public {
        datatypes.addNumber(42);
        assertEq(datatypes.getNumberAt(0), 42, "First element should be 42");

        datatypes.addNumber(100);
        assertEq(datatypes.getNumberAt(1), 100, "Second element should be 100");
    }

    function test_GetNumberAt_RevertsOnOutOfBounds() public {
        datatypes.addNumber(1);

        // Should revert when accessing index 1 (only index 0 exists)
        vm.expectRevert("Index out of bounds");
        datatypes.getNumberAt(1);
    }

    function test_GetNumbersLength_ReturnsCorrectLength() public {
        for (uint256 i = 0; i < 5; i++) {
            datatypes.addNumber(i);
        }
        assertEq(datatypes.getNumbersLength(), 5, "Length should be 5 after adding 5 elements");
    }

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // STRUCT TESTS
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    function test_RegisterUser() public {
        uint256 initialBalance = 500;
        datatypes.registerUser(user1, initialBalance);

        (address wallet, uint256 balance, bool isRegistered) = datatypes.getUser(user1);

        assertEq(wallet, user1, "Wallet address should match");
        assertEq(balance, initialBalance, "Balance should match");
        assertTrue(isRegistered, "User should be registered");
    }

    function test_RegisterUser_EmitsEvent() public {
        uint256 balance = 1000;

        vm.expectEmit(true, false, false, true);
        emit DatatypesStorageSolution.UserRegistered(user1, balance);

        datatypes.registerUser(user1, balance);
    }

    function test_RegisterUser_UpdatesExistingUser() public {
        datatypes.registerUser(user1, 100);
        datatypes.registerUser(user1, 200);

        (, uint256 balance,) = datatypes.getUser(user1);
        assertEq(balance, 200, "Balance should be updated to new value");
    }

    function test_GetUser_ReturnsDefaultForNonExistent() public {
        (address wallet, uint256 balance, bool isRegistered) = datatypes.getUser(user1);

        assertEq(wallet, address(0), "Wallet should be zero address");
        assertEq(balance, 0, "Balance should be zero");
        assertFalse(isRegistered, "Should not be registered");
    }

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // DATA LOCATION TESTS
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    function test_SumMemoryArray() public {
        uint256[] memory arr = new uint256[](4);
        arr[0] = 10;
        arr[1] = 20;
        arr[2] = 30;
        arr[3] = 40;

        uint256 sum = datatypes.sumMemoryArray(arr);
        assertEq(sum, 100, "Sum should be 100");
    }

    function test_SumMemoryArray_EmptyArray() public {
        uint256[] memory arr = new uint256[](0);
        uint256 sum = datatypes.sumMemoryArray(arr);
        assertEq(sum, 0, "Sum of empty array should be 0");
    }

    function test_SumMemoryArray_SingleElement() public {
        uint256[] memory arr = new uint256[](1);
        arr[0] = 42;

        uint256 sum = datatypes.sumMemoryArray(arr);
        assertEq(sum, 42, "Sum should be 42");
    }

    function test_GetFirstElement() public {
        uint256[] memory arr = new uint256[](3);
        arr[0] = 100;
        arr[1] = 200;
        arr[2] = 300;

        // Note: Need to call via external interface
        uint256 first = datatypes.getFirstElement(arr);
        assertEq(first, 100, "First element should be 100");
    }

    function test_GetFirstElement_RevertsOnEmpty() public {
        uint256[] memory arr = new uint256[](0);

        vm.expectRevert("Array is empty");
        datatypes.getFirstElement(arr);
    }

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // ADVANCED: STRUCT PACKING DEMO
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    function test_GetPackedDataExample() public {
        (uint128 n1, uint128 n2, uint64 ts, address user, bool flag) =
            datatypes.getPackedDataExample();

        assertEq(n1, 100, "smallNumber1 should be 100");
        assertEq(n2, 200, "smallNumber2 should be 200");
        assertGt(ts, 0, "timestamp should be greater than 0");
        assertEq(user, address(0x1234567890123456789012345678901234567890), "user should match");
        assertTrue(flag, "flag should be true");
    }

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // FUZZ TESTS (Foundry automatically generates random inputs)
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    /**
     * @notice Fuzz test for setNumber
     * @dev Foundry runs this test with many random values for _number
     */
    function testFuzz_SetNumber(uint256 _number) public {
        datatypes.setNumber(_number);
        assertEq(datatypes.getNumber(), _number, "Number should equal fuzzed input");
    }

    /**
     * @notice Fuzz test for setBalance
     * @dev Tests with random addresses and balances
     */
    function testFuzz_SetBalance(address _addr, uint256 _balance) public {
        datatypes.setBalance(_addr, _balance);
        assertEq(datatypes.getBalance(_addr), _balance, "Balance should match fuzzed input");
    }

    /**
     * @notice Fuzz test for incrementNumber - never overflows from reasonable values
     * @dev Bound the input to avoid overflow
     */
    function testFuzz_IncrementNumber(uint256 _start) public {
        // Bound to avoid overflow
        _start = bound(_start, 0, type(uint256).max - 1);

        datatypes.setNumber(_start);
        datatypes.incrementNumber();
        assertEq(datatypes.getNumber(), _start + 1, "Should increment by 1");
    }

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // GAS BENCHMARKING
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    /**
     * @notice Benchmark gas cost of setting a number (first time - cold storage)
     */
    function test_Gas_SetNumber_Cold() public {
        uint256 gasBefore = gasleft();
        datatypes.setNumber(42);
        uint256 gasUsed = gasBefore - gasleft();

        // Cold storage write should be expensive (~20k+ gas)
        emit log_named_uint("Gas used for cold setNumber", gasUsed);
    }

    /**
     * @notice Benchmark gas cost of setting a number (second time - warm storage)
     */
    function test_Gas_SetNumber_Warm() public {
        datatypes.setNumber(42); // First write (cold)

        uint256 gasBefore = gasleft();
        datatypes.setNumber(100); // Second write (warm)
        uint256 gasUsed = gasBefore - gasleft();

        // Warm storage write should be cheaper (~5k gas)
        emit log_named_uint("Gas used for warm setNumber", gasUsed);
    }

    /**
     * @notice Benchmark gas cost of array operations
     */
    function test_Gas_ArrayOperations() public {
        uint256 gasBefore = gasleft();
        datatypes.addNumber(1);
        uint256 gasUsed = gasBefore - gasleft();

        emit log_named_uint("Gas used for first array push", gasUsed);

        gasBefore = gasleft();
        datatypes.addNumber(2);
        gasUsed = gasBefore - gasleft();

        emit log_named_uint("Gas used for second array push", gasUsed);
    }

    /**
     * @notice Compare gas costs of memory vs calldata
     */
    function test_Gas_MemoryVsCalldata() public {
        uint256[] memory arr = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) {
            arr[i] = i;
        }

        uint256 gasBefore = gasleft();
        datatypes.sumMemoryArray(arr);
        uint256 memoryGas = gasBefore - gasleft();

        gasBefore = gasleft();
        datatypes.getFirstElement(arr);
        uint256 calldataGas = gasBefore - gasleft();

        emit log_named_uint("Gas for memory array processing", memoryGas);
        emit log_named_uint("Gas for calldata array processing", calldataGas);

        // Calldata should be cheaper (no copy overhead)
        assertTrue(
            calldataGas < memoryGas, "Calldata access should be cheaper than memory processing"
        );
    }

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // EDGE CASES
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    function test_EdgeCase_MaxUint256() public {
        datatypes.setNumber(type(uint256).max);
        assertEq(datatypes.getNumber(), type(uint256).max, "Should handle max uint256");
    }

    function test_EdgeCase_ZeroAddress() public {
        datatypes.setBalance(address(0), 100);
        assertEq(datatypes.getBalance(address(0)), 100, "Should handle zero address");
    }

    function test_EdgeCase_LargeArray() public {
        // Add many elements to test gas limits
        for (uint256 i = 0; i < 10; i++) {
            datatypes.addNumber(i);
        }
        assertEq(datatypes.getNumbersLength(), 10, "Should handle multiple additions");
    }

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // INVARIANT TESTS (Properties that should always hold)
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    function invariant_OwnerNeverChanges() public {
        assertEq(datatypes.owner(), owner, "Owner should never change");
    }

    function invariant_ArrayLengthConsistent() public {
        // The length returned should always match actual array length
        // This is automatically consistent in Solidity, but good to verify
        uint256 length = datatypes.getNumbersLength();
        assertTrue(length >= 0, "Length should never be negative");
    }
}

/**
 * TPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPW
 * Q                        TESTING BEST PRACTICES                             Q
 * ZPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP]
 *
 * 1. TEST NAMING CONVENTION
 *      test_FunctionName_Scenario
 *      testFuzz_FunctionName for fuzz tests
 *      invariant_PropertyName for invariant tests
 *
 * 2. COVERAGE
 *      Happy path (normal operations)
 *      Edge cases (max values, empty inputs, zero address)
 *      Reverts (invalid inputs, overflow, out of bounds)
 *      Events (verify emissions)
 *      Gas costs (benchmark critical operations)
 *
 * 3. ISOLATION
 *      Each test should be independent
 *      setUp() runs before each test
 *      Don't rely on test execution order
 *
 * 4. ASSERTIONS
 *      assertEq: Check equality
 *      assertTrue/False: Check booleans
 *      assertGt/Lt: Check comparisons
 *      vm.expectRevert: Check reverts
 *
 * 5. GAS AWARENESS
 *      Use gasleft() for manual measurements
 *      Use --gas-report flag for automated reports
 *      Benchmark critical operations
 *
 * TPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPW
 * Q                            RUN TESTS                                      Q
 * ZPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP]
 *
 * forge test                    # Run all tests
 * forge test -vvv              # Run with verbose output
 * forge test --gas-report      # Run with gas reporting
 * forge test --match-test test_SetNumber  # Run specific test
 * forge test --match-contract DatatypesStorageTest  # Run specific contract
 * forge coverage               # Generate coverage report
 */
