// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/EventsLogging.sol";

/**
 * @title EventsLoggingTest
 * @notice Skeleton test suite for EventsLogging contract
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
 *   which functions to run. `testTransfer()` runs, `checkTransfer()` doesn't.
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
 * forge test -vvv               # Verbose mode - see detailed output (shows events!)
 * forge test --gas-report       # Show gas costs for each function
 * forge test --match-test testTransfer  # Run only tests matching this name
 * forge coverage                # See which lines of code are tested
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                      THIS TEST FILE SHOULD COVER:
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ✓ Constructor behavior (sets owner, initial balance)
 * ✓ Transfer operations (basic transfer, events, edge cases)
 * ✓ Approval operations (approve, events, edge cases)
 * ✓ Deposit operations (deposit ETH, events, timestamps)
 * ✓ Status updates (update status, events)
 * ✓ Event emission verification (using vm.expectEmit())
 * ✓ Indexed parameter filtering
 * ✓ Multiple events in single transaction
 * ✓ Edge cases (zero values, insufficient balance, zero address)
 * ✓ Gas measurements (comparing events vs storage)
 * ✓ Fuzz testing (randomized inputs to find unexpected bugs)
 *
 */
contract EventsLoggingTest is Test {
    EventsLogging public events;

    address public owner;
    address public user1;
    address public user2;

    // Event declarations for testing (must match contract events)
    // TODO: Declare events that match the contract's events
    // Hint: Check the contract for event declarations like:
    //       event Transfer(address indexed from, address indexed to, uint256 amount);
    //       event Approval(address indexed owner, address indexed spender, uint256 amount);
    //       event Deposit(address indexed user, uint256 amount, uint256 timestamp);
    //       event StatusChanged(address indexed user, string oldStatus, string newStatus);

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
     * 2. We deploy a FRESH instance of EventsLogging
     * 3. We fund test accounts with ETH using vm.deal()
     * 4. We label addresses for better debugging output
     *
     * IMPORTANT: Even if Test A transfers 100 tokens, when Test B runs,
     * setUp() will deploy a brand new contract with initial balance again.
     * This is GOOD - it prevents tests from interfering with each other!
     *
     * @dev Runs before each test function
     *      Creates fresh contract instance for each test (isolation)
     */
    function setUp() public {
        // TODO: Set owner to address(this) - the test contract is the deployer
        // TODO: Create user1 and user2 addresses (use makeAddr("user1") and makeAddr("user2"))
        // TODO: Fund user1 with ETH using vm.deal(user1, 10 ether)
        // TODO: Deploy a new EventsLogging contract instance
        // TODO: Use vm.label() to label addresses for better debugging output
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
    // - Verify initial balance is set correctly

    /**
     * @notice Tests that the constructor correctly sets the owner
     * @dev Use assertEq to check that events.owner() equals the owner variable
     */
    function test_Constructor_SetsOwner() public {
        // TODO: Assert that events.owner() equals owner
    }

    /**
     * @notice Tests that the constructor sets initial balance
     * @dev Check that deployer has initial balance (check constructor!)
     */
    function test_Constructor_SetsInitialBalance() public {
        // TODO: Assert that owner's balance equals the initial supply
        //       Check the constructor to see what initial balance is set!
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          TRANSFER TESTS
    // ═══════════════════════════════════════════════════════════════════════
    //
    // WHY TEST TRANSFERS?
    // Transfers are core functionality - they move value between addresses.
    // Testing ensures balances update correctly and events are emitted.
    //
    // WHAT TO TEST:
    // - Basic transfer updates balances correctly
    // - Transfer event is emitted with correct parameters
    // - Insufficient balance reverts
    // - Zero address validation

    /**
     * @notice Tests that transfer() updates balances correctly
     * @dev Transfer tokens, verify balances changed
     */
    function test_Transfer_UpdatesBalances() public {
        // TODO: Get owner's initial balance
        // TODO: Transfer 100 tokens to user1
        // TODO: Assert owner's balance decreased by 100
        // TODO: Assert user1's balance equals 100
    }

    /**
     * @notice Tests that transfer() emits Transfer event
     * @dev Use vm.expectEmit() to verify event emission
     *      Parameters: vm.expectEmit(true, true, false, true)
     *      First two true = check indexed params (from, to)
     *      Third false = don't check non-indexed params exactly
     *      Fourth true = check non-indexed params (amount)
     */
    function test_Transfer_EmitsEvent() public {
        // TODO: Use vm.expectEmit(true, true, false, true) to expect event
        // TODO: Emit the expected Transfer event: emit Transfer(owner, user1, 100)
        // TODO: Call transfer(): events.transfer(user1, 100)
        // Note: The order matters! Emit expected event BEFORE calling function
    }

    /**
     * @notice Tests that transfer() reverts on insufficient balance
     * @dev Use vm.expectRevert() to check insufficient balance validation
     */
    function test_Transfer_RevertsOnInsufficientBalance() public {
        // TODO: Use vm.expectRevert("Insufficient balance") to expect revert
        // TODO: Try to transfer more than owner's balance
    }

    /**
     * @notice Tests that transfer() reverts on zero address
     * @dev Use vm.expectRevert() to check zero address validation
     */
    function test_Transfer_RevertsOnZeroAddress() public {
        // TODO: Use vm.expectRevert("Invalid recipient") to expect revert
        // TODO: Try to transfer to address(0)
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          APPROVAL TESTS
    // ═══════════════════════════════════════════════════════════════════════
    //
    // WHY TEST APPROVALS?
    // Approvals allow one address to spend another's tokens. This is critical
    // for DeFi protocols (DEX swaps, lending, etc.).
    //
    // WHAT TO TEST:
    // - Approval updates allowance correctly
    // - Approval event is emitted
    // - Zero address validation

    /**
     * @notice Tests that approve() updates allowance correctly
     * @dev Approve spender, verify allowance set
     */
    function test_Approval_UpdatesAllowance() public {
        // TODO: Approve user1 to spend 500 tokens: events.approve(user1, 500)
        // TODO: Assert that allowance(owner, user1) equals 500
    }

    /**
     * @notice Tests that approve() emits Approval event
     * @dev Use vm.expectEmit() to verify event emission
     */
    function test_Approval_EmitsEvent() public {
        // TODO: Use vm.expectEmit(true, true, false, true) to expect event
        // TODO: Emit the expected Approval event: emit Approval(owner, user1, 500)
        // TODO: Call approve(): events.approve(user1, 500)
    }

    /**
     * @notice Tests that approve() reverts on zero address
     * @dev Use vm.expectRevert() to check zero address validation
     */
    function test_Approval_RevertsOnZeroAddress() public {
        // TODO: Use vm.expectRevert("Invalid spender") to expect revert
        // TODO: Try to approve address(0)
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          DEPOSIT TESTS
    // ═══════════════════════════════════════════════════════════════════════
    //
    // WHY TEST DEPOSITS?
    // Deposits allow users to add ETH to the contract. Testing ensures
    // balances update correctly and events include timestamps.
    //
    // WHAT TO TEST:
    // - Deposit increases balance
    // - Deposit event is emitted with timestamp
    // - Zero value reverts

    /**
     * @notice Tests that deposit() increases balance
     * @dev Deposit ETH, verify balance increased
     */
    function test_Deposit_IncreasesBalance() public {
        // TODO: Use vm.prank(user1) to simulate call from user1
        // TODO: Deposit 1 ether: events.deposit{value: 1 ether}()
        // TODO: Assert that user1's balance equals 1 ether
    }

    /**
     * @notice Tests that deposit() emits Deposit event with timestamp
     * @dev Use vm.expectEmit() to verify event emission
     *      Note: Timestamp will be block.timestamp, so use false for that param
     */
    function test_Deposit_EmitsEventWithTimestamp() public {
        // TODO: Use vm.expectEmit(true, false, false, false) to expect event
        //       First true = check indexed user param
        //       Second false = don't check amount exactly (we'll check it)
        //       Third false = don't check timestamp exactly (it's block.timestamp)
        //       Fourth false = don't check data exactly
        // TODO: Emit expected event: emit Deposit(user1, 1 ether, block.timestamp)
        // TODO: Use vm.prank(user1) and deposit 1 ether
    }

    /**
     * @notice Tests that deposit() reverts on zero value
     * @dev Use vm.expectRevert() to check zero value validation
     */
    function test_Deposit_RevertsOnZeroValue() public {
        // TODO: Use vm.expectRevert("Must send ETH") to expect revert
        // TODO: Try to deposit 0 ETH
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          STATUS UPDATE TESTS
    // ═══════════════════════════════════════════════════════════════════════
    //
    // WHY TEST STATUS UPDATES?
    // Status updates demonstrate events with string parameters. Strings
    // cannot be indexed, so they're stored in event data.
    //
    // WHAT TO TEST:
    // - Status update stores new status
    // - StatusChanged event is emitted with old and new status

    /**
     * @notice Tests that updateStatus() updates status
     * @dev Update status, verify it changed
     */
    function test_UpdateStatus_UpdatesStatus() public {
        // TODO: Use vm.prank(user1) to simulate call from user1
        // TODO: Update status: events.updateStatus("active")
        // TODO: Assert that userStatus(user1) equals "active"
        //       Note: You may need to add a getter function or make userStatus public
    }

    /**
     * @notice Tests that updateStatus() emits StatusChanged event
     * @dev Use vm.expectEmit() to verify event emission
     */
    function test_UpdateStatus_EmitsEvent() public {
        // TODO: Use vm.expectEmit(true, false, false, false) to expect event
        //       First true = check indexed user param
        //       Other false = strings can't be checked exactly (they're in data)
        // TODO: Emit expected event: emit StatusChanged(user1, "", "active")
        //       Old status is empty string "" initially
        // TODO: Use vm.prank(user1) and update status to "active"
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          VIEW FUNCTION TESTS
    // ═══════════════════════════════════════════════════════════════════════
    //
    // WHY TEST VIEW FUNCTIONS?
    // View functions read state without modifying it. Testing them ensures
    // they return correct values.
    //
    // WHAT TO TEST:
    // - balanceOf() returns correct balance
    // - allowance() returns correct allowance

    /**
     * @notice Tests that balanceOf() returns correct balance
     * @dev Transfer tokens, then check balance
     */
    function test_BalanceOf_ReturnsCorrectBalance() public {
        // TODO: Transfer 100 tokens to user1
        // TODO: Assert that balanceOf(user1) equals 100
    }

    /**
     * @notice Tests that allowance() returns correct allowance
     * @dev Approve spender, then check allowance
     */
    function test_Allowance_ReturnsCorrectAllowance() public {
        // TODO: Approve user1 to spend 500 tokens
        // TODO: Assert that allowance(owner, user1) equals 500
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          MULTIPLE EVENTS TESTS
    // ═══════════════════════════════════════════════════════════════════════
    //
    // WHY TEST MULTIPLE EVENTS?
    // A single transaction can emit multiple events. Testing ensures all
    // events are emitted correctly.
    //
    // WHAT TO TEST:
    // - Multiple events in one transaction
    // - Events are emitted in correct order

    /**
     * @notice Tests multiple events in single transaction
     * @dev Call multiple functions, verify all events emitted
     */
    function test_MultipleEvents_InSingleTransaction() public {
        // TODO: Use vm.startPrank(address(this)) to start pranking
        // TODO: Transfer tokens: events.transfer(user1, 100)
        // TODO: Approve spender: events.approve(user2, 200)
        // TODO: Update status: events.updateStatus("active")
        // TODO: Use vm.stopPrank() to stop pranking
        // Note: This test verifies that multiple events can be emitted in one tx
        //       Use -vvv flag to see all events in the output!
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
    // - Transfer with random amounts (within balance)
    // - Approval with random amounts
    // - Edge cases discovered through randomization

    /**
     * @notice Fuzz test for transfer with random amounts
     * @dev Use testFuzz_ prefix, Foundry will generate random uint256 values
     */
    function testFuzz_Transfer(uint256 amount) public {
        // TODO: Get owner's balance: uint256 ownerBalance = events.balanceOf(owner)
        // TODO: Use vm.assume(amount > 0 && amount <= ownerBalance) to filter valid amounts
        // TODO: Transfer amount to user1
        // TODO: Assert that user1's balance equals amount
        // TODO: Assert that owner's balance equals ownerBalance - amount
    }

    /**
     * @notice Fuzz test for approval with random amounts
     * @dev Use testFuzz_ prefix for fuzz testing
     */
    function testFuzz_Approval(uint256 amount) public {
        // TODO: Use vm.assume(amount > 0) to filter out zero
        // TODO: Approve user1 to spend amount
        // TODO: Assert that allowance(owner, user1) equals amount
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          GAS TESTS
    // ═══════════════════════════════════════════════════════════════════════
    //
    // WHY TEST GAS?
    // Gas costs money! Understanding gas costs helps optimize contracts and
    // predict transaction costs for users. Events are much cheaper than storage!
    //
    // WHAT TO TEST:
    // - Measure gas for transfer (includes event)
    // - Compare: event vs storage for logging history

    /**
     * @notice Tests gas cost for transfer (includes event emission)
     * @dev Use gasleft() before and after to measure gas
     */
    function test_Gas_Transfer() public {
        // TODO: Record gas before: uint256 gasBefore = gasleft()
        // TODO: Transfer 100 tokens to user1
        // TODO: Calculate gas used: uint256 gasUsed = gasBefore - gasleft()
        // TODO: Log gas used: emit log_named_uint("Gas for transfer", gasUsed)
    }

    /**
     * @notice Tests gas cost for event emission
     * @dev Compare event cost vs storage cost
     */
    function test_Gas_EventVsStorage() public {
        // TODO: Measure gas for emitting Transfer event (via transfer function)
        // TODO: Log the gas cost
        // TODO: Compare with storage write cost (~20,000 gas)
        // Note: Events are ~10x cheaper than storage!
    }
}
