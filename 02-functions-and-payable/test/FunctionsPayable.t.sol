// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/FunctionsPayableSolution.sol";

contract FunctionsPayableTest is Test {
    FunctionsPayableSolution public functionsContract;

    address public owner;
    address public user1;
    address public user2;

    // Events to test
    event Deposited(address indexed sender, uint256 amount);
    event Withdrawn(address indexed recipient, uint256 amount);
    event Received(address indexed sender, uint256 amount);
    event FallbackCalled(address indexed sender, uint256 amount, bytes data);

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        // Fund test accounts
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);

        // Deploy contract
        functionsContract = new FunctionsPayableSolution();
    }

    // PPP CONSTRUCTOR TESTS PPP

    function test_Constructor_SetsOwner() public {
        assertEq(functionsContract.owner(), owner);
    }

    function test_Constructor_AcceptsETH() public {
        FunctionsPayableSolution funded = new FunctionsPayableSolution{value: 1 ether}();
        assertEq(address(funded).balance, 1 ether);
    }

    // PPP RECEIVE FUNCTION TESTS PPP

    function test_Receive_AcceptsETH() public {
        vm.expectEmit(true, false, false, true);
        emit Received(user1, 1 ether);

        vm.prank(user1);
        (bool success,) = address(functionsContract).call{value: 1 ether}("");
        assertTrue(success);
        assertEq(address(functionsContract).balance, 1 ether);
    }

    function test_Receive_ViaTransfer() public {
        vm.prank(user1);
        payable(address(functionsContract)).transfer(0.5 ether);
        assertEq(address(functionsContract).balance, 0.5 ether);
    }

    // PPP FALLBACK FUNCTION TESTS PPP

    function test_Fallback_WithData() public {
        bytes memory data = abi.encodeWithSignature("nonExistentFunction()");

        vm.expectEmit(true, false, false, false);
        emit FallbackCalled(user1, 0, data);

        vm.prank(user1);
        (bool success,) = address(functionsContract).call(data);
        assertTrue(success);
    }

    function test_Fallback_WithETHAndData() public {
        bytes memory data = abi.encodeWithSignature("someFunction(uint256)", 42);

        vm.expectEmit(true, false, false, false);
        emit FallbackCalled(user1, 0.1 ether, data);

        vm.prank(user1);
        (bool success,) = address(functionsContract).call{value: 0.1 ether}(data);
        assertTrue(success);
    }

    // PPP DEPOSIT TESTS PPP

    function test_Deposit_IncreasesBalance() public {
        vm.prank(user1);
        functionsContract.deposit{value: 1 ether}();

        assertEq(functionsContract.getBalance(user1), 1 ether);
        assertEq(address(functionsContract).balance, 1 ether);
    }

    function test_Deposit_EmitsEvent() public {
        vm.expectEmit(true, false, false, true);
        emit Deposited(user1, 2 ether);

        vm.prank(user1);
        functionsContract.deposit{value: 2 ether}();
    }

    function test_Deposit_RevertsOnZeroValue() public {
        vm.prank(user1);
        vm.expectRevert("Must send ETH");
        functionsContract.deposit{value: 0}();
    }

    function test_Deposit_MultipleDeposits() public {
        vm.startPrank(user1);
        functionsContract.deposit{value: 1 ether}();
        functionsContract.deposit{value: 0.5 ether}();
        vm.stopPrank();

        assertEq(functionsContract.getBalance(user1), 1.5 ether);
    }

    // PPP DEPOSIT FOR TESTS PPP

    function test_DepositFor_CreditsRecipient() public {
        vm.prank(user1);
        functionsContract.depositFor{value: 1 ether}(user2);

        assertEq(functionsContract.getBalance(user2), 1 ether);
        assertEq(functionsContract.getBalance(user1), 0);
    }

    function test_DepositFor_RevertsOnZeroAddress() public {
        vm.prank(user1);
        vm.expectRevert("Invalid recipient");
        functionsContract.depositFor{value: 1 ether}(address(0));
    }

    function test_DepositFor_RevertsOnZeroValue() public {
        vm.prank(user1);
        vm.expectRevert("Must send ETH");
        functionsContract.depositFor{value: 0}(user2);
    }

    // PPP WITHDRAW TESTS PPP

    function test_Withdraw_DecreasesBalance() public {
        // Deposit first
        vm.prank(user1);
        functionsContract.deposit{value: 2 ether}();

        uint256 balanceBefore = user1.balance;

        // Withdraw
        vm.prank(user1);
        functionsContract.withdraw(1 ether);

        assertEq(functionsContract.getBalance(user1), 1 ether);
        assertEq(user1.balance, balanceBefore + 1 ether);
    }

    function test_Withdraw_EmitsEvent() public {
        vm.prank(user1);
        functionsContract.deposit{value: 1 ether}();

        vm.expectEmit(true, false, false, true);
        emit Withdrawn(user1, 0.5 ether);

        vm.prank(user1);
        functionsContract.withdraw(0.5 ether);
    }

    function test_Withdraw_RevertsOnInsufficientBalance() public {
        vm.prank(user1);
        vm.expectRevert("Insufficient balance");
        functionsContract.withdraw(1 ether);
    }

    function test_Withdraw_RevertsOnZeroAmount() public {
        vm.prank(user1);
        vm.expectRevert("Amount must be greater than 0");
        functionsContract.withdraw(0);
    }

    // PPP WITHDRAW ALL TESTS PPP

    function test_WithdrawAll_WithdrawsFullBalance() public {
        vm.prank(user1);
        functionsContract.deposit{value: 3 ether}();

        uint256 balanceBefore = user1.balance;

        vm.prank(user1);
        functionsContract.withdrawAll();

        assertEq(functionsContract.getBalance(user1), 0);
        assertEq(user1.balance, balanceBefore + 3 ether);
    }

    function test_WithdrawAll_RevertsOnZeroBalance() public {
        vm.prank(user1);
        vm.expectRevert("No balance to withdraw");
        functionsContract.withdrawAll();
    }

    // PPP OWNER WITHDRAW TESTS PPP

    function test_OwnerWithdraw_SendsETHToOwner() public {
        // Send ETH via receive (not tracked in balances)
        vm.prank(user1);
        (bool success,) = address(functionsContract).call{value: 2 ether}("");
        assertTrue(success);

        uint256 ownerBalanceBefore = owner.balance;

        functionsContract.ownerWithdraw(1 ether);

        assertEq(owner.balance, ownerBalanceBefore + 1 ether);
    }

    function test_OwnerWithdraw_RevertsIfNotOwner() public {
        vm.prank(user1);
        vm.expectRevert("Only owner");
        functionsContract.ownerWithdraw(1 ether);
    }

    function test_OwnerWithdraw_RevertsOnInsufficientBalance() public {
        vm.expectRevert("Insufficient contract balance");
        functionsContract.ownerWithdraw(1 ether);
    }

    // PPP VIEW FUNCTION TESTS PPP

    function test_GetBalance_ReturnsCorrectBalance() public {
        vm.prank(user1);
        functionsContract.deposit{value: 5 ether}();

        assertEq(functionsContract.getBalance(user1), 5 ether);
    }

    function test_GetContractBalance_ReturnsTotalBalance() public {
        vm.prank(user1);
        functionsContract.deposit{value: 1 ether}();

        vm.prank(user2);
        functionsContract.deposit{value: 2 ether}();

        assertEq(functionsContract.getContractBalance(), 3 ether);
    }

    // PPP VISIBILITY TESTS PPP

    function test_PublicFunction_Returns() public {
        string memory result = functionsContract.publicFunction();
        assertEq(result, "This is public");
    }

    function test_ExternalFunction_Returns() public {
        string memory result = functionsContract.externalFunction();
        assertEq(result, "This is external");
    }

    function test_CallInternalFunction_Returns() public {
        string memory result = functionsContract.callInternalFunction();
        assertEq(result, "This is internal");
    }

    function test_CallPrivateFunction_Returns() public {
        string memory result = functionsContract.callPrivateFunction();
        assertEq(result, "This is private");
    }

    // PPP FUZZ TESTS PPP

    function testFuzz_Deposit(uint96 amount) public {
        vm.assume(amount > 0);
        vm.deal(user1, amount);

        vm.prank(user1);
        functionsContract.deposit{value: amount}();

        assertEq(functionsContract.getBalance(user1), amount);
    }

    function testFuzz_WithdrawAfterDeposit(uint96 depositAmount, uint96 withdrawAmount) public {
        vm.assume(depositAmount > 0 && withdrawAmount > 0 && withdrawAmount <= depositAmount);
        vm.deal(user1, depositAmount);

        vm.prank(user1);
        functionsContract.deposit{value: depositAmount}();

        vm.prank(user1);
        functionsContract.withdraw(withdrawAmount);

        assertEq(functionsContract.getBalance(user1), depositAmount - withdrawAmount);
    }

    // PPP GAS TESTS PPP

    function test_Gas_Deposit() public {
        vm.prank(user1);
        uint256 gasBefore = gasleft();
        functionsContract.deposit{value: 1 ether}();
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("Gas for deposit", gasUsed);
    }

    function test_Gas_Withdraw() public {
        vm.prank(user1);
        functionsContract.deposit{value: 1 ether}();

        vm.prank(user1);
        uint256 gasBefore = gasleft();
        functionsContract.withdraw(0.5 ether);
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("Gas for withdraw", gasUsed);
    }
}
