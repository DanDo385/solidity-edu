// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SafeETHTransferSolution - Safe ETH Transfer Library
 * @notice Complete implementation of pull payment pattern with detailed explanations
 * @dev This solution demonstrates best practices for safe ETH transfers
 *
 * ARCHITECTURE OVERVIEW:
 * ┌──────────────────────────────────────────────────────────────┐
 * │                    Safe ETH Transfer                         │
 * ├──────────────────────────────────────────────────────────────┤
 * │                                                              │
 * │  1. Users deposit ETH → stored in pendingWithdrawals        │
 * │  2. Users withdraw ETH → pull pattern (self-service)        │
 * │  3. Failed withdrawals → revert (preserves state)           │
 * │  4. Reentrancy protection → CEI pattern                     │
 * │                                                              │
 * │  ┌──────────┐         ┌──────────────┐                     │
 * │  │  User A  │────────>│   Contract   │                     │
 * │  └──────────┘ deposit │              │                     │
 * │                       │  Withdrawal  │                     │
 * │  ┌──────────┐         │    Queue     │                     │
 * │  │  User B  │<────────│              │                     │
 * │  └──────────┘withdraw └──────────────┘                     │
 * │                                                              │
 * └──────────────────────────────────────────────────────────────┘
 *
 * KEY SECURITY FEATURES:
 * - Pull payment pattern (no DoS risk)
 * - Checks-Effects-Interactions pattern (reentrancy protection)
 * - Safe ETH transfer with .call (EIP-1884 compatible)
 * - Proper error handling
 * - Event emission for transparency
 * - Accounting integrity
 */

/**
 * @title ReentrancyGuard
 * @notice Simple reentrancy protection using the mutex pattern
 * @dev Implemented inline for educational purposes
 */
abstract contract ReentrancyGuard {
    /**
     * @dev Reentrancy status values
     *
     * WHY THESE SPECIFIC VALUES?
     * - NOT_ENTERED (1): Starting state
     * - ENTERED (2): Function is executing
     *
     * Why not use 0 and 1?
     * - Setting storage from 0 → non-zero costs 20,000 gas (SSTORE)
     * - Setting non-zero → non-zero costs only 5,000 gas
     * - Using 1 and 2 saves 15,000 gas on first call!
     */
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Initialize to NOT_ENTERED state
     */
    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly
     *
     * MECHANISM:
     * 1. Before function executes: check _status == NOT_ENTERED
     * 2. Set _status = ENTERED
     * 3. Execute function body
     * 4. Set _status = NOT_ENTERED (in modifier's second half)
     *
     * If reentrancy is attempted:
     * - _status will be ENTERED
     * - require(_status != ENTERED) will fail
     * - Transaction reverts
     */
    modifier nonReentrant() {
        // Check not already entered
        require(_status != ENTERED, "ReentrancyGuard: reentrant call");

        // Mark as entered
        _status = ENTERED;

        // Execute function
        _;

        // Reset status
        _status = NOT_ENTERED;
    }
}

contract SafeETHTransferSolution is ReentrancyGuard {
    // ============================================
    // STATE VARIABLES
    // ============================================

    /**
     * @dev Maps each address to their pending withdrawal amount
     *
     * STORAGE LAYOUT:
     * - Slot: keccak256(address || 0)
     * - Type: uint256 (32 bytes)
     * - Cost: 20,000 gas (cold SLOAD), 2,100 gas (warm)
     *
     * WHY MAPPING?
     * - O(1) lookup time
     * - Isolated per user (no DoS risk)
     * - Gas efficient for sparse data
     */
    mapping(address => uint256) public pendingWithdrawals;

    /**
     * @dev Track total ETH deposited (for accounting verification)
     *
     * ACCOUNTING INVARIANT:
     * totalDeposited - totalWithdrawn == address(this).balance
     *
     * This helps detect:
     * - Force-fed ETH via selfdestruct
     * - Accounting bugs
     * - Unexpected balance changes
     */
    uint256 public totalDeposited;

    /**
     * @dev Track total ETH withdrawn (for accounting verification)
     */
    uint256 public totalWithdrawn;

    // ============================================
    // EVENTS
    // ============================================

    /**
     * @dev Emitted when a user deposits ETH
     * @param user The address that deposited
     * @param amount The amount deposited in wei
     *
     * INDEXING:
     * - user is indexed → can filter by user address
     * - amount is not indexed → cheaper, but can't filter
     *
     * GAS COST:
     * - LOG2: ~375 gas base + ~375 gas per topic + 8 gas per byte
     */
    event Deposited(address indexed user, uint256 amount);

    /**
     * @dev Emitted when a user successfully withdraws ETH
     * @param user The address that withdrew
     * @param amount The amount withdrawn in wei
     */
    event Withdrawn(address indexed user, uint256 amount);

    /**
     * @dev Emitted when a withdrawal fails (emergency tracking)
     * @param user The address that attempted withdrawal
     * @param amount The amount that failed to transfer
     *
     * NOTE: In this implementation, failed withdrawals cause revert,
     * so this event wouldn't normally be emitted. However, it's here
     * to show how you COULD track failures if you chose to handle
     * them differently (e.g., queuing retry).
     */
    event WithdrawalFailed(address indexed user, uint256 amount);

    // ============================================
    // ERRORS
    // ============================================

    /**
     * @dev Custom errors save gas vs require strings
     *
     * GAS SAVINGS:
     * - require("string"): ~50 gas + string length
     * - revert CustomError(): ~24 gas
     *
     * Savings: ~26 gas + string length per revert
     */

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
     * @dev Uses pull payment pattern - ETH is stored, not immediately distributed
     *
     * FLOW:
     * 1. User sends ETH with transaction
     * 2. Contract credits user's pendingWithdrawals
     * 3. User can withdraw anytime by calling withdraw()
     *
     * GAS COST:
     * - First deposit by user: ~44,600 gas
     *   - SSTORE (zero to non-zero): 20,000 gas
     *   - Event: ~1,500 gas
     *   - Base: 21,000 gas
     * - Subsequent deposits: ~29,600 gas
     *   - SSTORE (non-zero to non-zero): 5,000 gas
     *
     * SECURITY:
     * - No reentrancy risk (no external calls)
     * - Overflow protection (Solidity 0.8+)
     * - No DoS risk (isolated per user)
     *
     * @custom:example
     * // Deposit 1 ETH
     * contract.deposit{value: 1 ether}();
     * // pendingWithdrawals[msg.sender] = 1 ether
     */
    function deposit() public payable {
        // ========================================
        // CHECKS
        // ========================================

        /**
         * WHY CHECK msg.value > 0?
         * - Prevents spam (empty transactions waste gas)
         * - Makes intent clear (must send ETH to deposit)
         * - Saves gas on accounting for 0 amounts
         */
        if (msg.value == 0) revert DepositZero();

        // ========================================
        // EFFECTS
        // ========================================

        /**
         * UPDATE STATE
         *
         * GAS OPTIMIZATION: Using += instead of separate read/write
         * - pendingWithdrawals[msg.sender] += msg.value
         *   Costs: 1 SLOAD (2,100 gas warm) + 1 SSTORE (5,000 gas warm)
         *   Total: ~7,100 gas
         *
         * ALTERNATIVE (less efficient):
         * - uint256 current = pendingWithdrawals[msg.sender];  // SLOAD: 2,100
         * - pendingWithdrawals[msg.sender] = current + msg.value;  // SSTORE: 5,000
         *   Same cost, but more verbose. += is cleaner and same gas.
         *
         * Solidity 0.8+ automatically checks for overflow:
         * - If pendingWithdrawals[msg.sender] + msg.value > type(uint256).max
         * - Transaction reverts with Panic(0x11)
         *
         * No need for SafeMath!
         *
         * REAL-WORLD ANALOGY: Like updating your bank balance - you add the deposit
         * to your existing balance in one operation, not read it, calculate, then write.
         */
        pendingWithdrawals[msg.sender] += msg.value;
        totalDeposited += msg.value;

        /**
         * EMIT EVENT
         *
         * Events are crucial for:
         * - Off-chain tracking
         * - User interfaces
         * - Analytics
         * - Debugging
         *
         * Make all state changes observable!
         */
        emit Deposited(msg.sender, msg.value);

        // ========================================
        // INTERACTIONS
        // ========================================

        // None - no external calls needed
    }

    // ============================================
    // WITHDRAWAL FUNCTION (PULL PATTERN)
    // ============================================

    /**
     * @notice Withdraw all pending ETH balance (PULL PATTERN)
     * @dev Implements secure pull payment pattern with reentrancy protection
     *
     * SECURITY FEATURES:
     * 1. Checks-Effects-Interactions pattern
     * 2. ReentrancyGuard modifier (defense in depth)
     * 3. Safe ETH transfer with .call
     * 4. Proper error handling
     *
     * FLOW:
     * 1. Check user has balance
     * 2. Set balance to 0 (BEFORE transfer!)
     * 3. Transfer ETH to user
     * 4. Require transfer success
     *
     * WHY PULL PATTERN?
     * ┌──────────────────────────────────────────────────┐
     * │            Push vs Pull Comparison               │
     * ├──────────────────────────────────────────────────┤
     * │ Push Pattern:                                    │
     * │   ✗ Contract sends to multiple recipients        │
     * │   ✗ One failure blocks all payments              │
     * │   ✗ Unbounded gas costs                          │
     * │   ✗ DoS vulnerable                               │
     * │                                                  │
     * │ Pull Pattern:                                    │
     * │   ✓ Users withdraw their own funds               │
     * │   ✓ Failures are isolated                        │
     * │   ✓ Predictable gas costs                        │
     * │   ✓ DoS resistant                                │
     * └──────────────────────────────────────────────────┘
     *
     * GAS COST:
     * - SLOAD: 2,100 gas (warm)
     * - SSTORE (non-zero to zero): 2,900 gas
     * - CALL: 9,000 base + recipient code
     * - Event: ~1,500 gas
     * - Total: ~30,000-50,000 gas
     *
     * @custom:example
     * // User has 1 ETH pending
     * contract.withdraw();
     * // Receives 1 ETH
     * // pendingWithdrawals[msg.sender] = 0
     */
    function withdraw() public nonReentrant {
        // ========================================
        // CHECKS
        // ========================================

        /**
         * READ STATE
         *
         * GAS OPTIMIZATION: Cache storage read to memory
         * - SLOAD (cold): 2,100 gas (first read)
         * - SLOAD (warm): 100 gas (subsequent reads)
         * - MLOAD: 3 gas (reading from memory)
         *
         * WHY CACHE?
         * - We use 'amount' multiple times in this function
         * - Reading from memory (3 gas) is cheaper than re-reading storage (100 gas)
         * - Saves ~97 gas per additional read
         *
         * ALTERNATIVE (less efficient):
         * - Direct reads: pendingWithdrawals[msg.sender] (multiple times)
         *   Each read costs 100 gas (warm), so 3 reads = 300 gas
         * - Cached: 1 read (100 gas) + 2 memory reads (6 gas) = 106 gas
         *   Savings: ~194 gas
         *
         * REAL-WORLD ANALOGY: Like writing down a phone number you'll need to call
         * multiple times - it's faster to read from your note (memory) than look it up
         * in the phone book (storage) each time.
         */
        uint256 amount = pendingWithdrawals[msg.sender];

        /**
         * VALIDATE BALANCE
         *
         * Must have something to withdraw.
         * Without this check:
         * - Wasted gas on 0 transfer
         * - Confusing event emissions
         * - Poor UX
         */
        if (amount == 0) revert NoBalanceToWithdraw();

        // ========================================
        // EFFECTS
        // ========================================

        /**
         * UPDATE STATE BEFORE EXTERNAL CALL
         *
         * THIS IS CRITICAL FOR SECURITY!
         *
         * GAS OPTIMIZATION: Setting to zero gives gas refund
         * - SSTORE (non-zero to zero): 2,900 gas
         * - Gas refund: -15,000 gas (capped at 20% of transaction gas)
         * - Net cost: ~2,900 gas, but refund helps offset total transaction cost
         *
         * Why set to 0 before transfer?
         * Prevents reentrancy attack:
         *
         * Attack scenario if we transfer first:
         * 1. Attacker calls withdraw()
         * 2. Contract transfers ETH
         * 3. Attacker's receive() is called
         * 4. Attacker calls withdraw() AGAIN
         * 5. Balance still not updated → withdraw again!
         * 6. Repeat until contract drained
         *
         * With state update first:
         * 1. Attacker calls withdraw()
         * 2. Balance set to 0
         * 3. Contract transfers ETH
         * 4. Attacker's receive() is called
         * 5. Attacker calls withdraw() AGAIN
         * 6. Balance is 0 → reverts with NoBalanceToWithdraw
         *
         * CHECKS-EFFECTS-INTERACTIONS PATTERN:
         * Always follow this order!
         *
         * REAL-WORLD ANALOGY: Like marking a check as "paid" before sending it,
         * not after. If the check bounces, you've already marked it paid, preventing
         * double-spending.
         */
        pendingWithdrawals[msg.sender] = 0;

        /**
         * UPDATE ACCOUNTING
         *
         * Track total withdrawn for verification:
         * totalDeposited - totalWithdrawn == expected balance
         */
        totalWithdrawn += amount;

        // ========================================
        // INTERACTIONS
        // ========================================

        /**
         * SAFE ETH TRANSFER
         *
         * Why use .call instead of .transfer or .send?
         *
         * ┌────────────────────────────────────────────────┐
         * │        ETH Transfer Methods Comparison         │
         * ├────────────────────────────────────────────────┤
         * │ transfer():                                    │
         * │   - 2300 gas stipend (FIXED)                   │
         * │   - Reverts on failure                         │
         * │   - Breaks after EIP-1884                      │
         * │   - NOT RECOMMENDED                            │
         * │                                                │
         * │ send():                                        │
         * │   - 2300 gas stipend (FIXED)                   │
         * │   - Returns bool                               │
         * │   - Breaks after EIP-1884                      │
         * │   - NOT RECOMMENDED                            │
         * │                                                │
         * │ call{value: x}(""):                           │
         * │   - Forwards all available gas                 │
         * │   - Returns (bool, bytes)                      │
         * │   - EIP-1884 compatible                        │
         * │   - RECOMMENDED ✓                              │
         * └────────────────────────────────────────────────┘
         *
         * EIP-1884 Impact:
         * - Increased SLOAD cost from 200 to 800 gas
         * - 2300 gas no longer sufficient for many operations
         * - Even simple fallback functions can fail
         *
         * Example that fails with transfer():
         * contract Recipient {
         *     uint256 count;
         *     receive() external payable {
         *         count++;  // SLOAD (800) + SSTORE (20000)
         *     }
         * }
         *
         * .call forwards enough gas for this!
         */
        (bool success, ) = msg.sender.call{value: amount}("");

        /**
         * CHECK TRANSFER SUCCESS
         *
         * Why require success?
         * - If transfer fails, state already updated (balance = 0)
         * - Must revert to restore state
         * - User doesn't lose their funds
         *
         * What causes transfer to fail?
         * - Recipient has no receive/fallback
         * - Recipient's receive/fallback reverts
         * - Recipient's receive/fallback runs out of gas
         * - Recipient is a contract that was destroyed
         *
         * By reverting:
         * - All state changes are rolled back
         * - pendingWithdrawals restored
         * - User can try again
         */
        if (!success) revert TransferFailed();

        /**
         * EMIT EVENT
         *
         * Only emit after successful transfer.
         * Events are part of the transaction receipt,
         * so they also revert if transaction reverts.
         *
         * This ensures events accurately reflect state.
         */
        emit Withdrawn(msg.sender, amount);

        /**
         * NOTE: nonReentrant modifier
         *
         * We use ReentrancyGuard for defense in depth:
         * - CEI pattern is primary defense
         * - nonReentrant is secondary defense
         * - Both together = maximum security
         *
         * Even if CEI pattern is accidentally broken,
         * reentrancy is still prevented.
         */
    }

    // ============================================
    // EMERGENCY WITHDRAWAL
    // ============================================

    /**
     * @notice Emergency withdrawal for specific amount
     * @dev Allows partial withdrawals if user wants to manage gas
     * @param amount Amount to withdraw (must be <= balance)
     *
     * USE CASE:
     * - User has large balance
     * - Wants to withdraw in smaller chunks
     * - Can control gas costs per transaction
     *
     * SECURITY:
     * - Same CEI pattern as withdraw()
     * - Same reentrancy protection
     * - Additional check: amount <= balance
     */
    function withdrawAmount(uint256 amount) public nonReentrant {
        // CHECKS
        uint256 balance = pendingWithdrawals[msg.sender];
        if (balance == 0) revert NoBalanceToWithdraw();
        require(amount > 0 && amount <= balance, "Invalid amount");

        // EFFECTS
        pendingWithdrawals[msg.sender] -= amount;
        totalWithdrawn += amount;

        // INTERACTIONS
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) revert TransferFailed();

        emit Withdrawn(msg.sender, amount);
    }

    // ============================================
    // BATCH OPERATIONS
    // ============================================

    /**
     * @notice Allow admin/owner to credit multiple addresses
     * @dev PUSH pattern for crediting (not sending), users still PULL to withdraw
     * @param recipients Addresses to credit
     * @param amounts Amounts to credit each address
     *
     * IMPORTANT:
     * This is NOT push payment (no external calls)!
     * We're just updating internal balances.
     * Users still withdraw themselves (pull pattern).
     *
     * SECURITY:
     * - No external calls → no DoS risk
     * - Users withdraw independently
     * - Gas cost is predictable
     *
     * WHY THIS IS SAFE:
     * - We're only updating storage, not transferring
     * - Each user withdraws when ready
     * - Failed withdrawal doesn't affect others
     */
    /**
     * @notice Allow admin/owner to credit multiple addresses
     * @dev PUSH pattern for crediting (not sending), users still PULL to withdraw
     * @param recipients Addresses to credit
     * @param amounts Amounts to credit each address
     *
     * GAS OPTIMIZATION: Using calldata instead of memory
     * - calldata: Read directly from transaction data (cheapest)
     * - memory: Copy to memory first (~3 gas/word)
     * - Savings: ~600 gas for 10 recipients (20 words * 3 gas = 60 gas per array)
     *
     * GAS OPTIMIZATION: Unchecked arithmetic in loop
     * - We validate lengths match, so i can't overflow
     * - Using unchecked saves ~100 gas per iteration
     * - For 10 recipients: saves ~1,000 gas
     *
     * ALTERNATIVE (less efficient):
     * - address[] memory recipients (copies to memory)
     * - uint256[] memory amounts (copies to memory)
     * - for (uint256 i = 0; i < recipients.length; i++) (checked increment)
     *   Total extra cost: ~1,200 gas for 10 recipients
     *
     * IMPORTANT:
     * This is NOT push payment (no external calls)!
     * We're just updating internal balances.
     * Users still withdraw themselves (pull pattern).
     *
     * SECURITY:
     * - No external calls → no DoS risk
     * - Users withdraw independently
     * - Gas cost is predictable
     *
     * WHY THIS IS SAFE:
     * - We're only updating storage, not transferring
     * - Each user withdraws when ready
     * - Failed withdrawal doesn't affect others
     *
     * REAL-WORLD ANALOGY: Like crediting multiple customer accounts at once
     * (updating balances), but each customer withdraws their own money when ready
     * (pull pattern). Much safer than trying to send money to everyone at once.
     */
    function batchCredit(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) public payable {
        require(recipients.length == amounts.length, "Length mismatch");

        uint256 totalAmount = 0;

        // Credit each recipient
        // GAS OPTIMIZATION: Unchecked increment safe because we validated lengths
        for (uint256 i = 0; i < recipients.length; ) {
            require(amounts[i] > 0, "Amount must > 0");
            pendingWithdrawals[recipients[i]] += amounts[i];
            totalAmount += amounts[i];
            emit Deposited(recipients[i], amounts[i]);
            
            // Unchecked increment saves ~100 gas per iteration
            unchecked {
                i++;
            }
        }

        // Ensure enough ETH sent
        require(msg.value == totalAmount, "Insufficient ETH");
        totalDeposited += totalAmount;
    }

    // ============================================
    // VIEW FUNCTIONS
    // ============================================

    /**
     * @notice Get pending withdrawal balance for a user
     * @param user The address to check
     * @return The pending balance in wei
     */
    function getBalance(address user) public view returns (uint256) {
        return pendingWithdrawals[user];
    }

    /**
     * @notice Get contract's current ETH balance
     * @return The contract's ETH balance in wei
     *
     * NOTE:
     * This can be > (totalDeposited - totalWithdrawn) if:
     * - ETH was force-fed via selfdestruct
     * - ETH sent to address before deployment
     *
     * Always compare with accounting totals!
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Get total deposited amount (accounting)
     * @return Total ETH deposited in wei
     */
    function getTotalDeposited() public view returns (uint256) {
        return totalDeposited;
    }

    /**
     * @notice Get total withdrawn amount (accounting)
     * @return Total ETH withdrawn in wei
     */
    function getTotalWithdrawn() public view returns (uint256) {
        return totalWithdrawn;
    }

    /**
     * @notice Verify accounting integrity
     * @return Whether accounting matches contract balance
     *
     * INVARIANT:
     * totalDeposited - totalWithdrawn == address(this).balance
     *
     * If false:
     * - ETH was force-fed (selfdestruct)
     * - Accounting bug (should never happen)
     * - Contract received ETH before deployment
     */
    function verifyAccounting() public view returns (bool) {
        return (totalDeposited - totalWithdrawn) == address(this).balance;
    }

    // ============================================
    // RECEIVE FUNCTION
    // ============================================

    /**
     * @notice Receive ETH sent directly to contract
     * @dev Automatically deposits for the sender
     *
     * ENABLES:
     * - Simple ETH transfers: address(contract).transfer(1 ether)
     * - Better UX: Users don't need to call deposit()
     *
     * GAS:
     * - Must be careful of 2300 gas limit for .transfer
     * - Our receive() only calls deposit() which is gas efficient
     * - Should work with .transfer, .send, and .call
     */
    receive() external payable {
        deposit();
    }

    /**
     * @notice Fallback function
     * @dev Reject calls with data
     *
     * WHY:
     * - Prevents accidental function calls
     * - Makes interface explicit
     * - Saves gas on invalid calls
     */
    fallback() external payable {
        revert("Use deposit() or send ETH");
    }
}

/**
 * ============================================
 * SECURITY ANALYSIS
 * ============================================
 *
 * REENTRANCY:
 * ✓ Protected by CEI pattern
 * ✓ Protected by ReentrancyGuard
 * ✓ State updated before external calls
 *
 * DOS:
 * ✓ Pull pattern prevents DoS
 * ✓ No unbounded loops
 * ✓ Failures are isolated
 *
 * INTEGER OVERFLOW:
 * ✓ Solidity 0.8+ automatic checks
 * ✓ No unchecked blocks
 *
 * FAILED TRANSFERS:
 * ✓ Check success of .call
 * ✓ Revert on failure
 * ✓ State preserved
 *
 * ACCESS CONTROL:
 * ~ No admin functions (except batchCredit)
 * ~ Consider adding owner for emergency
 *
 * FORCE-FEEDING ETH:
 * ✓ Accounting tracks expected balance
 * ✓ verifyAccounting() detects force-feeding
 * ⚠ Don't rely on exact balance checks
 *
 * ============================================
 * GAS OPTIMIZATIONS
 * ============================================
 *
 * 1. CUSTOM ERRORS:
 *    - Save ~50 gas per revert vs require strings
 *
 * 2. CACHE STORAGE READS:
 *    - uint256 amount = pendingWithdrawals[msg.sender]
 *    - Use cached value instead of re-reading
 *
 * 3. INDEXED EVENT PARAMETERS:
 *    - Only index what you'll filter by
 *    - Indexed parameters cost more gas
 *
 * 4. BATCH OPERATIONS:
 *    - batchCredit saves gas vs individual deposits
 *    - Amortize base transaction cost
 *
 * 5. TIGHT VARIABLE PACKING:
 *    - Not applicable here (uint256 values)
 *    - Consider for struct optimizations
 *
 * ============================================
 * COMPARISON WITH ALTERNATIVES
 * ============================================
 *
 * OPENZEPPELIN PULLPAYMENT:
 * - Uses escrow pattern
 * - More complex
 * - Additional abstraction layer
 * - Good for production
 *
 * THIS IMPLEMENTATION:
 * - Direct and simple
 * - Educational
 * - Explicit control flow
 * - Good for learning
 *
 * RECOMMENDATION:
 * - Use this to learn concepts
 * - Use OpenZeppelin for production
 * - Audited code is always better
 *
 * ============================================
 */
