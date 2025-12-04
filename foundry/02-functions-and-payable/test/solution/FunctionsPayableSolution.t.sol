// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/FunctionsPayable.sol";

/**
 * @title FunctionsPayableTest
 * @notice Skeleton test suite for FunctionsPayable contract
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
 *   which functions to run. `testDeposit()` runs, `checkDeposit()` doesn't.
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
 * forge test --match-test testDeposit  # Run only tests matching this name
 * forge coverage                # See which lines of code are tested
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                      THIS TEST FILE SHOULD COVER:
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ✓ Constructor behavior (sets owner, accepts ETH)
 * ✓ receive() function (plain ETH transfers)
 * ✓ fallback() function (unknown calls, ETH with data)
 * ✓ Deposit operations (basic deposit, depositFor, events, edge cases)
 * ✓ Withdrawal operations (withdraw, withdrawAll, events, edge cases)
 * ✓ Owner withdrawal (access control, edge cases)
 * ✓ View functions (getBalance, getContractBalance)
 * ✓ Function visibility (public, external, internal, private)
 * ✓ Edge cases (zero values, insufficient balance, zero address)
 * ✓ Gas measurements (comparing costs of different approaches)
 * ✓ Fuzz testing (randomized inputs to find unexpected bugs)
 *
 */
contract FunctionsPayableTest is Test {
    FunctionsPayable public functionsContract;

    address public owner;
    address public user1;
    address public user2;

    // Event declarations for testing (must match contract events)
    // TODO: Declare events that match the contract's events
    // Hint: Check the contract for event declarations like:
    //       event Deposited(address indexed sender, uint256 amount);
    //       event Withdrawn(address indexed recipient, uint256 amount);
    //       event Received(address indexed sender, uint256 amount);
    //       event FallbackCalled(address indexed sender, uint256 amount, bytes data);

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
     * 2. We deploy a FRESH instance of FunctionsPayable
     * 3. We fund test accounts with ETH using vm.deal()
     * 4. We label addresses for better debugging output
     *
     * IMPORTANT: Even if Test A deposits 10 ETH, when Test B runs,
     * setUp() will deploy a brand new contract with 0 balance again.
     * This is GOOD - it prevents tests from interfering with each other!
     *
     * @dev Runs before each test function
     *      Creates fresh contract instance for each test (isolation)
     */
    function setUp() public {
        // TODO: Set owner to address(this) - the test contract is the deployer
        // TODO: Create user1 and user2 addresses (use makeAddr("user1") and makeAddr("user2"))
        //       makeAddr() creates deterministic addresses from strings - useful for testing
        // TODO: Fund test accounts with ETH using vm.deal()
        //       Example: vm.deal(user1, 10 ether);
        //       Why do we need to fund accounts? What happens if we don't?
        // TODO: Deploy a new FunctionsPayable contract instance
        // TODO: Use vm.label() to label addresses for better debugging output
        //       Example: vm.label(owner, "Owner");
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
    // - Check that owner is set correctly
    // - Verify that contract can accept ETH during deployment (payable constructor)
    // - Ensure initial balance is correct

    /**
     * @notice Tests that the constructor correctly sets the owner
     * @dev Use assertEq to check that functionsContract.owner() equals the owner variable
     */
    function test_Constructor_SetsOwner() public {
        // TODO: Assert that functionsContract.owner() equals owner
        // Hint: assertEq(functionsContract.owner(), owner, "Owner should be set to deployer");
    }

    /**
     * @notice Tests that the constructor accepts ETH
     * @dev Deploy a new contract with ETH using {value: amount} syntax
     *      Then check that the contract's balance equals the amount sent
     */
    function test_Constructor_AcceptsETH() public {
        // TODO: Deploy a new FunctionsPayable contract with 1 ether
        //       Use: new FunctionsPayable{value: 1 ether}()
        // TODO: Assert that the contract's balance equals 1 ether
        //       Use: address(contract).balance or contract.getContractBalance()
        // Hint: FunctionsPayable funded = new FunctionsPayable{value: 1 ether}();
        //       assertEq(address(funded).balance, 1 ether);
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          RECEIVE() TESTS
    // ═══════════════════════════════════════════════════════════════════════
    //
    // WHY TEST receive()?
    // The receive() function handles plain ETH transfers (empty calldata).
    // This is how users send ETH directly to your contract without calling
    // a specific function. Testing ensures it works correctly.
    //
    // WHAT TO TEST:
    // - ETH is accepted when sent with empty calldata
    // - Received event is emitted
    // - Contract balance increases
    // - Works with .call, .transfer, .send

    /**
     * @notice Tests that receive() accepts ETH sent via .call
     * @dev Use vm.prank() to simulate sending from user1
     *      Use vm.expectEmit() to check event emission
     *      Use .call{value:} to send ETH with empty calldata
     */
    function test_Receive_AcceptsETH() public {
        // TODO: Use vm.expectEmit() to expect the Received event
        //       Parameters: vm.expectEmit(true, false, false, true)
        //       Then emit the expected event: emit Received(user1, 1 ether);
        // TODO: Use vm.prank(user1) to simulate call from user1
        // TODO: Send ETH to contract using: address(functionsContract).call{value: 1 ether}("")
        //       The empty string "" means empty calldata, which triggers receive()
        // TODO: Check that the call succeeded: assertTrue(success)
        // TODO: Assert that contract balance increased: assertEq(address(functionsContract).balance, 1 ether)
        // Hint: (bool success,) = address(functionsContract).call{value: 1 ether}("");
    }

    /**
     * @notice Tests that receive() works with .transfer
     * @dev .transfer() sends ETH with empty calldata, triggering receive()
     */
    function test_Receive_ViaTransfer() public {
        // TODO: Use vm.prank(user1) to simulate call from user1
        // TODO: Send ETH using payable(address(functionsContract)).transfer(0.5 ether)
        // TODO: Assert that contract balance equals 0.5 ether
        // Note: .transfer() only forwards 2,300 gas - this is why we prefer .call in production!
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          FALLBACK() TESTS
    // ═══════════════════════════════════════════════════════════════════════
    //
    // WHY TEST fallback()?
    // The fallback() function handles unknown function calls or ETH sent with
    // data. This is important for proxy patterns and error handling.
    //
    // WHAT TO TEST:
    // - Unknown function calls trigger fallback()
    // - ETH sent with data triggers fallback()
    // - FallbackCalled event is emitted with correct data

    /**
     * @notice Tests that fallback() handles unknown function calls
     * @dev Call a non-existent function, verify fallback() is triggered
     */
    function test_Fallback_WithData() public {
        // TODO: Create calldata for a non-existent function
        //       Use: abi.encodeWithSignature("nonExistentFunction()")
        // TODO: Use vm.expectEmit() to expect FallbackCalled event
        // TODO: Use vm.prank(user1) to simulate call from user1
        // TODO: Call contract with the non-existent function data
        //       Use: address(functionsContract).call(data)
        // TODO: Assert that the call succeeded
        // Hint: bytes memory data = abi.encodeWithSignature("nonExistentFunction()");
        //       (bool success,) = address(functionsContract).call(data);
    }

    /**
     * @notice Tests that fallback() handles ETH sent with data
     * @dev Send ETH along with function call data
     */
    function test_Fallback_WithETHAndData() public {
        // TODO: Create calldata for a function: abi.encodeWithSignature("someFunction(uint256)", 42)
        // TODO: Use vm.expectEmit() to expect FallbackCalled event with ETH amount
        // TODO: Use vm.prank(user1) to simulate call from user1
        // TODO: Send ETH with data: address(functionsContract).call{value: 0.1 ether}(data)
        // TODO: Assert that the call succeeded
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          DEPOSIT TESTS
    // ═══════════════════════════════════════════════════════════════════════
    //
    // WHY TEST DEPOSITS?
    // Deposits are how users add ETH to the contract. This is critical
    // functionality - bugs here could mean lost funds or incorrect balances.
    //
    // WHAT TO TEST:
    // - Basic deposit increases balance
    // - Deposited event is emitted
    // - Multiple deposits accumulate
    // - Zero value reverts
    // - depositFor() credits correct recipient

    /**
     * @notice Tests that deposit() increases user balance
     * @dev Deposit ETH, then check balance increased
     */
    function test_Deposit_IncreasesBalance() public {
        // TODO: Use vm.prank(user1) to simulate call from user1
        // TODO: Call deposit() with 1 ether: functionsContract.deposit{value: 1 ether}()
        // TODO: Assert that user1's balance equals 1 ether: assertEq(functionsContract.getBalance(user1), 1 ether)
        // TODO: Assert that contract balance equals 1 ether
    }

    /**
     * @notice Tests that deposit() emits Deposited event
     * @dev Use vm.expectEmit() to verify event emission
     */
    function test_Deposit_EmitsEvent() public {
        // TODO: Use vm.expectEmit(true, false, false, true) to expect event
        // TODO: Emit the expected event: emit Deposited(user1, 2 ether);
        // TODO: Use vm.prank(user1) to simulate call from user1
        // TODO: Call deposit() with 2 ether
        // Note: The order matters! Emit expected event BEFORE calling function
    }

    /**
     * @notice Tests that deposit() reverts on zero value
     * @dev Use vm.expectRevert() to check that zero value reverts
     */
    function test_Deposit_RevertsOnZeroValue() public {
        // TODO: Use vm.prank(user1) to simulate call from user1
        // TODO: Use vm.expectRevert("Must send ETH") to expect revert
        // TODO: Call deposit() with 0 value: functionsContract.deposit{value: 0}()
    }

    /**
     * @notice Tests multiple deposits accumulate
     * @dev Deposit twice, verify total balance is sum
     */
    function test_Deposit_MultipleDeposits() public {
        // TODO: Use vm.startPrank(user1) to start pranking
        // TODO: Deposit 1 ether
        // TODO: Deposit 0.5 ether
        // TODO: Use vm.stopPrank() to stop pranking
        // TODO: Assert that user1's balance equals 1.5 ether
    }

    /**
     * @notice Tests that depositFor() credits the recipient
     * @dev User1 deposits for user2, verify user2 gets credit
     */
    function test_DepositFor_CreditsRecipient() public {
        // TODO: Use vm.prank(user1) to simulate call from user1
        // TODO: Call depositFor() with user2 as recipient: functionsContract.depositFor{value: 1 ether}(user2)
        // TODO: Assert that user2's balance equals 1 ether
        // TODO: Assert that user1's balance equals 0 (user1 paid, but user2 got credit)
    }

    /**
     * @notice Tests that depositFor() reverts on zero address
     * @dev Use vm.expectRevert() to check zero address validation
     */
    function test_DepositFor_RevertsOnZeroAddress() public {
        // TODO: Use vm.prank(user1) to simulate call from user1
        // TODO: Use vm.expectRevert("Invalid recipient") to expect revert
        // TODO: Call depositFor() with address(0) as recipient
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          WITHDRAWAL TESTS
    // ═══════════════════════════════════════════════════════════════════════
    //
    // WHY TEST WITHDRAWALS?
    // Withdrawals move ETH out of the contract. This is CRITICAL - bugs here
    // could mean permanent loss of funds or reentrancy vulnerabilities.
    //
    // WHAT TO TEST:
    // - Withdrawal decreases balance
    // - ETH is actually sent to user
    // - Withdrawn event is emitted
    // - Insufficient balance reverts
    // - Zero amount reverts
    // - withdrawAll() withdraws full balance

    /**
     * @notice Tests that withdraw() decreases balance and sends ETH
     * @dev Deposit first, then withdraw, verify balance decreased and ETH received
     */
    function test_Withdraw_DecreasesBalance() public {
        // TODO: Deposit first: vm.prank(user1); functionsContract.deposit{value: 2 ether}()
        // TODO: Record user1's balance before withdrawal: uint256 balanceBefore = user1.balance
        // TODO: Use vm.prank(user1) to simulate call from user1
        // TODO: Withdraw 1 ether: functionsContract.withdraw(1 ether)
        // TODO: Assert that user1's balance in contract equals 1 ether (2 - 1)
        // TODO: Assert that user1's ETH balance increased by 1 ether
        //       assertEq(user1.balance, balanceBefore + 1 ether)
    }

    /**
     * @notice Tests that withdraw() emits Withdrawn event
     * @dev Use vm.expectEmit() to verify event emission
     */
    function test_Withdraw_EmitsEvent() public {
        // TODO: Deposit first: vm.prank(user1); functionsContract.deposit{value: 1 ether}()
        // TODO: Use vm.expectEmit() to expect Withdrawn event
        // TODO: Emit expected event: emit Withdrawn(user1, 0.5 ether);
        // TODO: Use vm.prank(user1) to simulate call from user1
        // TODO: Withdraw 0.5 ether
    }

    /**
     * @notice Tests that withdraw() reverts on insufficient balance
     * @dev Use vm.expectRevert() to check insufficient balance validation
     */
    function test_Withdraw_RevertsOnInsufficientBalance() public {
        // TODO: Use vm.prank(user1) to simulate call from user1
        // TODO: Use vm.expectRevert("Insufficient balance") to expect revert
        // TODO: Try to withdraw 1 ether without depositing first
    }

    /**
     * @notice Tests that withdraw() reverts on zero amount
     * @dev Use vm.expectRevert() to check zero amount validation
     */
    function test_Withdraw_RevertsOnZeroAmount() public {
        // TODO: Use vm.prank(user1) to simulate call from user1
        // TODO: Use vm.expectRevert("Amount must be greater than 0") to expect revert
        // TODO: Try to withdraw 0
    }

    /**
     * @notice Tests that withdrawAll() withdraws full balance
     * @dev Deposit, then withdrawAll, verify balance is zero and ETH received
     */
    function test_WithdrawAll_WithdrawsFullBalance() public {
        // TODO: Deposit 3 ether: vm.prank(user1); functionsContract.deposit{value: 3 ether}()
        // TODO: Record user1's balance before withdrawal
        // TODO: Use vm.prank(user1) to simulate call from user1
        // TODO: Call withdrawAll(): functionsContract.withdrawAll()
        // TODO: Assert that user1's balance in contract equals 0
        // TODO: Assert that user1's ETH balance increased by 3 ether
    }

    /**
     * @notice Tests that withdrawAll() reverts on zero balance
     * @dev Use vm.expectRevert() to check zero balance validation
     */
    function test_WithdrawAll_RevertsOnZeroBalance() public {
        // TODO: Use vm.prank(user1) to simulate call from user1
        // TODO: Use vm.expectRevert("No balance to withdraw") to expect revert
        // TODO: Try to withdrawAll without depositing first
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          OWNER WITHDRAWAL TESTS
    // ═══════════════════════════════════════════════════════════════════════
    //
    // WHY TEST OWNER WITHDRAWAL?
    // Owner withdrawal allows the contract owner to withdraw ETH that wasn't
    // tracked in user balances (e.g., from receive()/fallback()). This is
    // important for collecting fees or handling untracked ETH.
    //
    // WHAT TO TEST:
    // - Owner can withdraw unreserved funds
    // - Non-owner cannot withdraw
    // - Insufficient contract balance reverts

    /**
     * @notice Tests that owner can withdraw contract funds
     * @dev Send ETH via receive() (not tracked), then owner withdraws
     */
    function test_OwnerWithdraw_SendsETHToOwner() public {
        // TODO: Send ETH via receive() (not tracked in balances)
        //       vm.prank(user1); (bool success,) = address(functionsContract).call{value: 2 ether}("");
        // TODO: Record owner's balance before withdrawal
        // TODO: Call ownerWithdraw(1 ether) as owner (no prank needed - test contract is owner)
        // TODO: Assert that owner's balance increased by 1 ether
    }

    /**
     * @notice Tests that non-owner cannot withdraw
     * @dev Use vm.expectRevert() to check access control
     */
    function test_OwnerWithdraw_RevertsIfNotOwner() public {
        // TODO: Use vm.prank(user1) to simulate call from user1
        // TODO: Use vm.expectRevert("Only owner") to expect revert
        // TODO: Try to call ownerWithdraw(1 ether) as user1
    }

    /**
     * @notice Tests that ownerWithdraw() reverts on insufficient balance
     * @dev Use vm.expectRevert() to check insufficient balance validation
     */
    function test_OwnerWithdraw_RevertsOnInsufficientBalance() public {
        // TODO: Use vm.expectRevert("Insufficient contract balance") to expect revert
        // TODO: Try to withdraw 1 ether when contract has 0 balance
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          VIEW FUNCTION TESTS
    // ═══════════════════════════════════════════════════════════════════════
    //
    // WHY TEST VIEW FUNCTIONS?
    // View functions read state without modifying it. Testing them ensures
    // they return correct values and helps document expected behavior.
    //
    // WHAT TO TEST:
    // - getBalance() returns correct balance
    // - getContractBalance() returns total contract ETH

    /**
     * @notice Tests that getBalance() returns correct balance
     * @dev Deposit, then check getBalance() returns correct amount
     */
    function test_GetBalance_ReturnsCorrectBalance() public {
        // TODO: Deposit 5 ether: vm.prank(user1); functionsContract.deposit{value: 5 ether}()
        // TODO: Assert that getBalance(user1) equals 5 ether
    }

    /**
     * @notice Tests that getContractBalance() returns total balance
     * @dev Multiple deposits, verify total equals sum
     */
    function test_GetContractBalance_ReturnsTotalBalance() public {
        // TODO: Deposit 1 ether as user1
        // TODO: Deposit 2 ether as user2
        // TODO: Assert that getContractBalance() equals 3 ether
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          VISIBILITY TESTS
    // ═══════════════════════════════════════════════════════════════════════
    //
    // WHY TEST VISIBILITY?
    // Function visibility controls who can call functions. Testing ensures
    // the visibility modifiers work correctly.
    //
    // WHAT TO TEST:
    // - public functions can be called externally
    // - external functions can be called externally
    // - internal functions can be called via wrapper
    // - private functions can be called via wrapper

    /**
     * @notice Tests that publicFunction() can be called
     * @dev Call public function, verify return value
     */
    function test_PublicFunction_Returns() public {
        // TODO: Call publicFunction(): string memory result = functionsContract.publicFunction()
        // TODO: Assert that result equals "This is public"
    }

    /**
     * @notice Tests that externalFunction() can be called
     * @dev Call external function, verify return value
     */
    function test_ExternalFunction_Returns() public {
        // TODO: Call externalFunction(): string memory result = functionsContract.externalFunction()
        // TODO: Assert that result equals "This is external"
    }

    /**
     * @notice Tests that callInternalFunction() returns internal result
     * @dev Call wrapper function, verify it calls internal function correctly
     */
    function test_CallInternalFunction_Returns() public {
        // TODO: Call callInternalFunction(): string memory result = functionsContract.callInternalFunction()
        // TODO: Assert that result equals "This is internal"
    }

    /**
     * @notice Tests that callPrivateFunction() returns private result
     * @dev Call wrapper function, verify it calls private function correctly
     */
    function test_CallPrivateFunction_Returns() public {
        // TODO: Call callPrivateFunction(): string memory result = functionsContract.callPrivateFunction()
        // TODO: Assert that result equals "This is private"
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          FUZZ TESTS
    // ═══════════════════════════════════════════════════════════════════════
    //
    // WHY FUZZ TESTING?
    // Fuzz testing runs tests with random inputs. This helps find edge cases
    // and bugs you might not think of. Foundry automatically generates random
    // values for fuzz test parameters.
    //
    // WHAT TO TEST:
    // - Deposit with random amounts
    // - Withdraw with random amounts (within balance)
    // - Edge cases discovered through randomization

    /**
     * @notice Fuzz test for deposit with random amounts
     * @dev Use testFuzz_ prefix, Foundry will generate random uint96 values
     */
    function testFuzz_Deposit(uint96 amount) public {
        // TODO: Use vm.assume(amount > 0) to filter out zero values
        // TODO: Fund user1 with the amount: vm.deal(user1, amount)
        // TODO: Deposit: vm.prank(user1); functionsContract.deposit{value: amount}()
        // TODO: Assert that balance equals amount
    }

    /**
     * @notice Fuzz test for withdraw after deposit
     * @dev Deposit random amount, withdraw random amount (within balance)
     */
    function testFuzz_WithdrawAfterDeposit(uint96 depositAmount, uint96 withdrawAmount) public {
        // TODO: Use vm.assume() to ensure: depositAmount > 0 && withdrawAmount > 0 && withdrawAmount <= depositAmount
        // TODO: Fund user1: vm.deal(user1, depositAmount)
        // TODO: Deposit: vm.prank(user1); functionsContract.deposit{value: depositAmount}()
        // TODO: Withdraw: vm.prank(user1); functionsContract.withdraw(withdrawAmount)
        // TODO: Assert that balance equals depositAmount - withdrawAmount
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          GAS TESTS
    // ═══════════════════════════════════════════════════════════════════════
    //
    // WHY TEST GAS?
    // Gas costs money! Understanding gas costs helps optimize contracts and
    // predict transaction costs for users.
    //
    // WHAT TO TEST:
    // - Measure gas for deposit operations
    // - Measure gas for withdrawal operations
    // - Compare different approaches

    /**
     * @notice Tests gas cost for deposit
     * @dev Use gasleft() before and after to measure gas
     */
    function test_Gas_Deposit() public {
        // TODO: Use vm.prank(user1) to simulate call from user1
        // TODO: Record gas before: uint256 gasBefore = gasleft()
        // TODO: Call deposit(): functionsContract.deposit{value: 1 ether}()
        // TODO: Calculate gas used: uint256 gasUsed = gasBefore - gasleft()
        // TODO: Log gas used: emit log_named_uint("Gas for deposit", gasUsed)
    }

    /**
     * @notice Tests gas cost for withdraw
     * @dev Deposit first, then measure withdrawal gas
     */
    function test_Gas_Withdraw() public {
        // TODO: Deposit first: vm.prank(user1); functionsContract.deposit{value: 1 ether}()
        // TODO: Use vm.prank(user1) to simulate call from user1
        // TODO: Record gas before: uint256 gasBefore = gasleft()
        // TODO: Withdraw: functionsContract.withdraw(0.5 ether)
        // TODO: Calculate and log gas used
    }
}
