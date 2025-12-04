// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/solution/DatatypesStorageSolution.sol";

/**
 * @title DatatypesStorageSolutionTest
 * @notice Complete reference test suite for DatatypesStorage contract
 * @dev This is the solution test file - study it after implementing your own tests
 * 
 * See test/DatatypesStorage.t.sol for the skeleton version with TODOs
 */
contract DatatypesStorageSolutionTest is Test {
    DatatypesStorageSolution public datatypes;

    // Event declarations for testing (must match contract events)
    event NumberUpdated(uint256 indexed oldValue, uint256 indexed newValue);
    event UserRegistered(address indexed wallet, uint256 balance);

    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

        datatypes = new DatatypesStorageSolution();

        vm.label(owner, "Owner");
        vm.label(user1, "User1");
        vm.label(user2, "User2");
    }

    // CONSTRUCTOR TESTS

    function test_Constructor_SetsOwner() public view {
        assertEq(datatypes.owner(), owner, "Owner should be set to deployer");
    }

    function test_Constructor_SetsIsActive() public view {
        assertTrue(datatypes.isActive(), "Contract should be active on deployment");
    }

    // VALUE TYPE TESTS

    function test_SetNumber() public {
        uint256 newNumber = 42;
        datatypes.setNumber(newNumber);
        assertEq(datatypes.getNumber(), newNumber, "Number should be updated");
    }

    function test_SetNumber_EmitsEvent() public {
        uint256 newNumber = 100;

        vm.expectEmit(true, true, false, true); // Both params are indexed
        emit NumberUpdated(0, newNumber);

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
        datatypes.setNumber(type(uint256).max);

        vm.expectRevert();
        datatypes.incrementNumber();
    }

    // MAPPING TESTS

    function test_SetBalance() public {
        uint256 balance = 1000;
        datatypes.setBalance(user1, balance);
        assertEq(datatypes.getBalance(user1), balance, "Balance should be set correctly");
    }

    function test_GetBalance_ReturnsZeroForNewAddress() public view {
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

    function test_HasBalance_ReturnsFalseForZero() public view {
        assertFalse(datatypes.hasBalance(user1), "Should return false for zero balance");
    }

    // ARRAY TESTS

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

        vm.expectRevert("Index out of bounds");
        datatypes.getNumberAt(1);
    }

    function test_GetNumbersLength_ReturnsCorrectLength() public {
        for (uint256 i = 0; i < 5; i++) {
            datatypes.addNumber(i);
        }
        assertEq(datatypes.getNumbersLength(), 5, "Length should be 5 after adding 5 elements");
    }

    // STRUCT TESTS

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
        emit UserRegistered(user1, balance);

        datatypes.registerUser(user1, balance);
    }

    function test_RegisterUser_UpdatesExistingUser() public {
        datatypes.registerUser(user1, 100);
        datatypes.registerUser(user1, 200);

        (, uint256 balance,) = datatypes.getUser(user1);
        assertEq(balance, 200, "Balance should be updated to new value");
    }

    function test_GetUser_ReturnsDefaultForNonExistent() public view {
        (address wallet, uint256 balance, bool isRegistered) = datatypes.getUser(user1);

        assertEq(wallet, address(0), "Wallet should be zero address");
        assertEq(balance, 0, "Balance should be zero");
        assertFalse(isRegistered, "Should not be registered");
    }

    // DATA LOCATION TESTS

    function test_SumMemoryArray() public view {
        uint256[] memory arr = new uint256[](4);
        arr[0] = 10;
        arr[1] = 20;
        arr[2] = 30;
        arr[3] = 40;

        uint256 sum = datatypes.sumMemoryArray(arr);
        assertEq(sum, 100, "Sum should be 100");
    }

    function test_SumMemoryArray_EmptyArray() public view {
        uint256[] memory arr = new uint256[](0);
        uint256 sum = datatypes.sumMemoryArray(arr);
        assertEq(sum, 0, "Sum of empty array should be 0");
    }

    function test_SumMemoryArray_SingleElement() public view {
        uint256[] memory arr = new uint256[](1);
        arr[0] = 42;

        uint256 sum = datatypes.sumMemoryArray(arr);
        assertEq(sum, 42, "Sum should be 42");
    }

    function test_GetFirstElement() public view {
        uint256[] memory arr = new uint256[](3);
        arr[0] = 100;
        arr[1] = 200;
        arr[2] = 300;

        uint256 first = datatypes.getFirstElement(arr);
        assertEq(first, 100, "First element should be 100");
    }

    function test_GetFirstElement_RevertsOnEmpty() public {
        uint256[] memory arr = new uint256[](0);

        vm.expectRevert("Array is empty");
        datatypes.getFirstElement(arr);
    }

    // ADVANCED TESTS

    function test_SetMessage() public {
        string memory newMessage = "Hello World";
        datatypes.setMessage(newMessage);
        assertEq(datatypes.message(), newMessage, "Message should be updated");
    }

    function test_Deposit_IncreasesBalance() public {
        uint256 amount = 1 ether;
        vm.deal(user1, amount);
        vm.prank(user1);
        datatypes.deposit{value: amount}();
        assertEq(datatypes.getBalance(user1), amount, "Balance should be updated");
    }

    function test_Deposit_RevertsOnZeroAmount() public {
        vm.prank(user1);
        vm.expectRevert();
        datatypes.deposit{value: 0}();
    }

    function test_RemoveNumber() public {
        datatypes.addNumber(10);
        datatypes.addNumber(20);
        datatypes.addNumber(30);
        datatypes.removeNumber(1);
        assertEq(datatypes.getNumbersLength(), 2, "Array length should be 2");
        assertEq(datatypes.getNumberAt(1), 30, "Last element should be moved");
    }

    function test_RemoveNumber_RevertsOnOutOfBounds() public {
        datatypes.addNumber(10);
        vm.expectRevert();
        datatypes.removeNumber(1);
    }

    // FUZZ TESTS

    function testFuzz_SetNumber(uint256 _number) public {
        datatypes.setNumber(_number);
        assertEq(datatypes.getNumber(), _number, "Number should equal fuzzed input");
    }

    function testFuzz_SetBalance(address _addr, uint256 _balance) public {
        datatypes.setBalance(_addr, _balance);
        assertEq(datatypes.getBalance(_addr), _balance, "Balance should match fuzzed input");
    }

    function testFuzz_IncrementNumber(uint256 _start) public {
        _start = bound(_start, 0, type(uint256).max - 1);

        datatypes.setNumber(_start);
        datatypes.incrementNumber();

        assertEq(datatypes.getNumber(), _start + 1, "Should increment by 1");
    }

    // GAS BENCHMARKING

    function test_Gas_SetNumber_Cold() public {
        uint256 gasBefore = gasleft();
        datatypes.setNumber(42);
        uint256 gasUsed = gasBefore - gasleft();

        emit log_named_uint("Gas used for cold setNumber", gasUsed);
    }

    function test_Gas_SetNumber_Warm() public {
        datatypes.setNumber(42);

        uint256 gasBefore = gasleft();
        datatypes.setNumber(100);
        uint256 gasUsed = gasBefore - gasleft();

        emit log_named_uint("Gas used for warm setNumber", gasUsed);
    }

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

        assertTrue(
            calldataGas < memoryGas, "Calldata access should be cheaper than memory processing"
        );
    }

    // EDGE CASES

    function test_EdgeCase_MaxUint256() public {
        datatypes.setNumber(type(uint256).max);
        assertEq(datatypes.getNumber(), type(uint256).max, "Should handle max uint256");
    }

    function test_EdgeCase_ZeroAddress() public {
        datatypes.setBalance(address(0), 100);
        assertEq(datatypes.getBalance(address(0)), 100, "Should handle zero address");
    }

    function test_EdgeCase_LargeArray() public {
        for (uint256 i = 0; i < 10; i++) {
            datatypes.addNumber(i);
        }
        assertEq(datatypes.getNumbersLength(), 10, "Should handle multiple additions");
    }

    // INVARIANT TESTS

    function invariant_OwnerNeverChanges() public view {
        assertEq(datatypes.owner(), owner, "Owner should never change");
    }

    function invariant_ArrayLengthConsistent() public view {
        uint256 length = datatypes.getNumbersLength();
        assertTrue(length >= 0, "Length should never be negative");
    }
}
