// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Project12 - Safe ETH Transfer Library
 * @notice Learn pull payment patterns and safe ETH transfers
 * @dev This is the skeleton contract with TODOs for students to complete
 *
 * LEARNING OBJECTIVES:
 * 1. Implement pull payment pattern instead of push payments
 * 2. Create a secure withdrawal queue system
 * 3. Handle failed ETH transfers gracefully
 * 4. Follow Checks-Effects-Interactions pattern
 * 5. Protect against reentrancy attacks
 *
 * KEY CONCEPTS:
 * - Pull vs Push payments
 * - DoS attack prevention
 * - Safe ETH transfer mechanisms
 * - EIP-1884 gas considerations
 */

contract Project12 {
    // ============================================
    // STATE VARIABLES
    // ============================================

    /**
     * @dev Maps each address to their pending withdrawal amount
     * TODO: Declare a mapping to track balances
     * Hint: mapping(address => uint256) public pendingWithdrawals;
     */
    // YOUR CODE HERE

    /**
     * @dev Track total ETH deposited (for accounting)
     * TODO: Declare a uint256 variable to track total deposits
     */
    // YOUR CODE HERE

    /**
     * @dev Track total ETH withdrawn (for accounting)
     * TODO: Declare a uint256 variable to track total withdrawals
     */
    // YOUR CODE HERE

    // ============================================
    // EVENTS
    // ============================================

    /**
     * @dev Emitted when a user deposits ETH
     * TODO: Declare an event with user address and amount
     * Hint: event Deposited(address indexed user, uint256 amount);
     */
    // YOUR CODE HERE

    /**
     * @dev Emitted when a user withdraws ETH
     * TODO: Declare an event with user address and amount
     */
    // YOUR CODE HERE

    /**
     * @dev Emitted when a withdrawal fails (for emergency tracking)
     * TODO: Declare an event with user address, amount, and reason
     */
    // YOUR CODE HERE

    // ============================================
    // ERRORS
    // ============================================

    /// @dev Thrown when trying to withdraw with no balance
    error NoBalanceToWithdraw();

    /// @dev Thrown when ETH transfer fails
    error TransferFailed();

    /// @dev Thrown when trying to deposit 0 ETH
    error DepositZero();

    // ============================================
    // DEPOSIT FUNCTION
    // ============================================

    /**
     * @notice Deposit ETH into the contract for later withdrawal
     * @dev Users deposit ETH which is tracked in pendingWithdrawals
     *
     * REQUIREMENTS:
     * 1. Must send some ETH (msg.value > 0)
     * 2. Update user's pending withdrawal balance
     * 3. Update total deposits
     * 4. Emit Deposited event
     *
     * TODO: Implement the deposit function
     *
     * SECURITY NOTES:
     * - Check msg.value > 0 to prevent spam
     * - Solidity 0.8+ protects against overflow automatically
     * - No reentrancy risk here (no external calls)
     */
    function deposit() public payable {
        // TODO: Check that msg.value is greater than 0
        // Hint: if (msg.value == 0) revert DepositZero();

        // TODO: Add msg.value to pendingWithdrawals[msg.sender]
        // Hint: pendingWithdrawals[msg.sender] += msg.value;

        // TODO: Update totalDeposited
        // Hint: totalDeposited += msg.value;

        // TODO: Emit Deposited event
        // Hint: emit Deposited(msg.sender, msg.value);
    }

    // ============================================
    // WITHDRAWAL FUNCTION (PULL PATTERN)
    // ============================================

    /**
     * @notice Withdraw all pending ETH balance (PULL PATTERN)
     * @dev Implements secure pull payment pattern
     *
     * REQUIREMENTS:
     * 1. User must have a balance > 0
     * 2. Follow Checks-Effects-Interactions pattern:
     *    a. CHECKS: Verify user has balance
     *    b. EFFECTS: Update state (set balance to 0)
     *    c. INTERACTIONS: Transfer ETH to user
     * 3. Handle transfer failure appropriately
     * 4. Emit Withdrawn event on success
     *
     * TODO: Implement the withdraw function
     *
     * SECURITY CRITICAL:
     * - MUST update state BEFORE external call (prevents reentrancy)
     * - MUST check transfer success
     * - MUST follow Checks-Effects-Interactions pattern
     *
     * WHY PULL PATTERN?
     * - Users withdraw their own funds
     * - No DoS if one user can't receive
     * - User controls gas for their own withdrawal
     * - No unbounded loops over recipients
     */
    function withdraw() public {
        // ========================================
        // CHECKS
        // ========================================

        // TODO: Get the user's pending balance
        // Hint: uint256 amount = pendingWithdrawals[msg.sender];

        // TODO: Check that amount > 0
        // Hint: if (amount == 0) revert NoBalanceToWithdraw();

        // ========================================
        // EFFECTS
        // ========================================

        // TODO: Set user's balance to 0 BEFORE transfer
        // This prevents reentrancy attacks!
        // Hint: pendingWithdrawals[msg.sender] = 0;

        // TODO: Update totalWithdrawn
        // Hint: totalWithdrawn += amount;

        // ========================================
        // INTERACTIONS
        // ========================================

        // TODO: Transfer ETH to msg.sender using call
        // Why call? It forwards more gas than transfer/send
        // Hint: (bool success, ) = msg.sender.call{value: amount}("");

        // TODO: Require that transfer succeeded
        // Hint: if (!success) revert TransferFailed();

        // TODO: Emit Withdrawn event
        // Hint: emit Withdrawn(msg.sender, amount);
    }

    // ============================================
    // VIEW FUNCTIONS
    // ============================================

    /**
     * @notice Get pending withdrawal balance for a user
     * @param user The address to check
     * @return The pending balance
     *
     * TODO: Implement this view function
     */
    function getBalance(address user) public view returns (uint256) {
        // TODO: Return pendingWithdrawals[user]
        return 0; // Replace this
    }

    /**
     * @notice Get contract's current ETH balance
     * @return The contract's ETH balance
     *
     * TODO: Implement this view function
     */
    function getContractBalance() public view returns (uint256) {
        // TODO: Return address(this).balance
        return 0; // Replace this
    }

    /**
     * @notice Get total deposited amount (accounting)
     * @return Total ETH deposited
     *
     * TODO: Implement this view function
     */
    function getTotalDeposited() public view returns (uint256) {
        // TODO: Return totalDeposited
        return 0; // Replace this
    }

    /**
     * @notice Get total withdrawn amount (accounting)
     * @return Total ETH withdrawn
     *
     * TODO: Implement this view function
     */
    function getTotalWithdrawn() public view returns (uint256) {
        // TODO: Return totalWithdrawn
        return 0; // Replace this
    }

    // ============================================
    // RECEIVE FUNCTION
    // ============================================

    /**
     * @notice Receive ETH sent directly to contract
     * @dev Automatically deposits for the sender
     *
     * TODO: Implement receive() function that calls deposit()
     * Hint: receive() external payable { deposit(); }
     */
    // YOUR CODE HERE
}

/**
 * ============================================
 * LEARNING NOTES
 * ============================================
 *
 * 1. PULL VS PUSH PAYMENTS:
 *    - Push: Contract sends ETH to recipients
 *      → Can fail if recipient rejects
 *      → One failure blocks all payments
 *    - Pull: Recipients withdraw their own ETH
 *      → Each user responsible for their own withdrawal
 *      → Failures are isolated
 *
 * 2. CHECKS-EFFECTS-INTERACTIONS PATTERN:
 *    Always follow this order:
 *    a. Checks: Validate conditions
 *    b. Effects: Update state
 *    c. Interactions: Call external contracts
 *
 *    Why? Prevents reentrancy attacks!
 *
 * 3. WHY NOT .transfer() OR .send()?
 *    - transfer(): Forwards only 2300 gas (can fail after EIP-1884)
 *    - send(): Forwards only 2300 gas, returns bool
 *    - call{value: x}(""): Forwards sufficient gas, returns bool
 *
 * 4. REENTRANCY ATTACK EXAMPLE:
 *    If you transfer BEFORE updating state:
 *
 *    function badWithdraw() {
 *        uint256 amount = balances[msg.sender];
 *        msg.sender.call{value: amount}("");  // DANGER!
 *        balances[msg.sender] = 0;  // Too late!
 *    }
 *
 *    Attacker's receive():
 *    receive() {
 *        if (contract.balance > 0) {
 *            contract.withdraw();  // Re-enter and drain!
 *        }
 *    }
 *
 * 5. GAS CONSIDERATIONS:
 *    - .call forwards all available gas by default
 *    - Can limit gas: call{value: x, gas: 50000}("")
 *    - Usually safe to forward all gas with CEI pattern
 *
 * ============================================
 * TESTING CHECKLIST
 * ============================================
 *
 * Test these scenarios:
 * [ ] Normal deposit and withdraw
 * [ ] Multiple deposits from same user
 * [ ] Withdraw with 0 balance (should revert)
 * [ ] Withdraw after partial withdrawal
 * [ ] Contract that rejects ETH (should revert)
 * [ ] Reentrancy attack attempt (should fail)
 * [ ] Gas limits on recipient
 * [ ] Event emissions
 * [ ] Multiple users
 * [ ] Accounting (deposits vs withdrawals vs balance)
 *
 * ============================================
 */
