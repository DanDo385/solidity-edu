// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ErrorsRevertsSolution
 * @notice Complete reference implementation demonstrating error handling in Solidity
 * @dev Shows gas-efficient error patterns and when to use each
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        CONCEPTUAL OVERVIEW
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ERROR HANDLING: The Safety Net
 * ═══════════════════════════════════
 *
 * REAL-WORLD ANALOGY: Errors are like different types of warnings:
 * - require(): Like a "STOP" sign - prevents action with a message
 * - revert with custom error: Like a specific error code - precise and efficient
 * - assert(): Like a safety check - should never fail if code is correct
 *
 * HOW ERRORS WORK:
 * ┌─────────────────────────────────────────┐
 * │ Function executes                        │
 * │   ↓                                      │
 * │ Error condition detected                │ ← require/revert/assert
 * │   ↓                                      │
 * │ Transaction reverts                     │ ← All state changes undone
 * │   ↓                                      │
 * │ Error data returned                     │ ← Can be decoded off-chain
 * │   ↓                                      │
 * │ Gas refunded (require/revert)           │ ← assert consumes all gas!
 * └─────────────────────────────────────────┘
 *
 * FUN FACT: Before Solidity 0.4.22, `throw` reverted without data.
 * Modern `revert` opcodes bubble encoded error data, which explorers
 * and off-chain services can parse for better UX.
 *
 * KEY CONCEPTS:
 * - Custom errors: ~90% cheaper than string messages
 * - require(): For user input validation
 * - revert: For all error conditions (preferred)
 * - assert(): For internal invariants (should never fail)
 *
 * LANGUAGE COMPARISON:
 *   TypeScript: throw new Error("message") - similar to require()
 *   Go: return fmt.Errorf("message") - similar to require()
 *   Rust: Err(ErrorType::Variant) - similar to custom errors!
 *   Solidity: Custom errors are most efficient (like Rust enums)
 *
 * CONNECTION TO EARLIER CONCEPTS:
 * - Project 02: require() statements for validation
 * - Project 04: Access control errors (Unauthorized)
 * - Project 05: All error handling patterns combined!
 */

// ════════════════════════════════════════════════════════════════════════
// CUSTOM ERRORS (Defined at file level, outside contract)
// ════════════════════════════════════════════════════════════════════════

/**
 * @notice Custom error for insufficient balance
 * @param available Current balance available
 * @param required Amount required for operation
 * @dev GAS OPTIMIZATION: Custom errors are ~90% cheaper than string messages!
 *      This error includes parameters for better debugging.
 *
 * GAS COST:
 * - revert InsufficientBalance(balance, amount): ~50 + 32 + 32 = ~114 gas
 * - require(balance >= amount, "Insufficient balance"): ~50 + 20*3 = ~110 gas
 * - Custom error with params: Slightly more expensive BUT provides context
 * - Trade-off: ~4 gas more, but error handler gets both values
 *
 * REAL-WORLD ANALOGY: Like a detailed error report that includes both
 * what you have and what you need, making debugging easier.
 */
error InsufficientBalance(uint256 available, uint256 required);

/**
 * @notice Custom error for unauthorized access
 * @param caller Address that attempted unauthorized action
 * @dev CONNECTION TO PROJECT 04: Access control errors!
 *      This error includes the caller address for better debugging.
 *
 * GAS COST:
 * - revert Unauthorized(msg.sender): ~50 + 20 (address) = ~70 gas
 * - require(msg.sender == owner, "Only owner"): ~50 + 11*3 = ~83 gas
 * - Savings: ~13 gas per error
 */
error Unauthorized(address caller);

/**
 * @notice Custom error for invalid amount
 * @dev Simple error without parameters (cheapest option)
 *      Use when you don't need additional context.
 *
 * GAS COST:
 * - revert InvalidAmount(): ~50 gas
 * - require(amount > 0, "Amount must be positive"): ~50 + 24*3 = ~122 gas
 * - Savings: ~72 gas per error (59% reduction!)
 */
error InvalidAmount();

/**
 * @notice Custom error for invariant violations
 * @dev Used with assert() for internal consistency checks
 *      Should never fail if code is correct.
 */
error InvariantViolation();

contract ErrorsRevertsSolution {
    // ════════════════════════════════════════════════════════════════════════
    // STATE VARIABLES
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Contract owner address
     * @dev CONNECTION TO PROJECT 01: Simple address storage
     */
    address public owner;

    /**
     * @notice Current balance
     * @dev CONNECTION TO PROJECT 01: uint256 storage
     */
    uint256 public balance;

    /**
     * @notice Total deposits made (for invariant checking)
     * @dev Used to demonstrate assert() pattern
     *      Invariant: totalDeposits >= balance (can't withdraw more than deposited)
     */
    uint256 public totalDeposits;

    // ════════════════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Initializes the contract
     * @dev Sets owner to deployer
     *      CONNECTION TO PROJECT 01: Constructor pattern!
     */
    constructor() {
        owner = msg.sender;
    }

    // ════════════════════════════════════════════════════════════════════════
    // FUNCTIONS USING require() WITH STRINGS
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Deposit using require() statements
     * @param amount Amount to deposit
     * @dev GAS COST: require() with string message
     *      - require(condition, "message"): ~50 gas + string length * 3 gas
     *      - For "Amount must be positive": ~50 + 24*3 = ~122 gas
     *      - For "Only owner": ~50 + 11*3 = ~83 gas
     *      - Total: ~205 gas for both requires
     *
     * REAL-WORLD ANALOGY: Like a detailed error message on a form - helpful
     * for debugging but costs more to store and transmit.
     *
     * WHEN TO USE:
     * - Development/debugging (human-readable messages)
     * - Simple contracts where gas isn't critical
     * - NOT recommended for production (use custom errors instead!)
     *
     * CONNECTION TO PROJECT 02: require() for input validation!
     */
    function depositWithRequire(uint256 amount) public {
        require(amount > 0, "Amount must be positive");
        require(msg.sender == owner, "Only owner");
        balance += amount;
        totalDeposits += amount;
    }

    // ════════════════════════════════════════════════════════════════════════
    // FUNCTIONS USING CUSTOM ERRORS
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Deposit using custom errors (gas-efficient!)
     * @param amount Amount to deposit
     * @dev GAS OPTIMIZATION: Custom errors vs require() with strings
     *      - Custom error: ~50 gas (just the error selector)
     *      - require() with string: ~50 + string_length * 3 gas
     *      - For "Amount must be positive" (24 chars): ~122 gas
     *      - Savings: ~72 gas per error (59% reduction!)
     *
     * GAS COST BREAKDOWN:
     * - revert InvalidAmount(): ~50 gas
     * - revert Unauthorized(msg.sender): ~50 + 20 (address) = ~70 gas
     * - Total: ~120 gas vs ~205 gas with require()
     * - Savings: ~85 gas (41% reduction!)
     *
     * TRADE-OFF:
     *   ✅ Much cheaper gas-wise
     *   ✅ Can include parameters (like address)
     *   ❌ Less human-readable (need to decode error)
     *   ❌ Requires ABI to decode properly
     *
     * REAL-WORLD ANALOGY: Like using error codes instead of full messages.
     * Error codes are faster to process and cheaper to transmit, but you
     * need a reference guide to understand them.
     *
     * WHEN TO USE:
     * - Production code (gas-efficient!)
     * - When you need parameters in errors
     * - High-frequency operations (every gas counts!)
     *
     * CONNECTION TO PROJECT 02: Same validation logic, better gas efficiency!
     */
    /**
     * @notice Deposit using custom errors (gas-efficient!)
     * @param amount Amount to deposit
     *
     * @dev CUSTOM ERRORS: The Gas-Efficient Alternative
     * ═══════════════════════════════════════════════
     *
     *      This function demonstrates using custom errors instead of
     *      require() with string messages. Custom errors save ~90% gas!
     *
     *      EXECUTION FLOW:
     *      ┌─────────────────────────────────────────┐
     *      │ 1. VALIDATION: Check amount > 0        │
     *      │    - If NO: Revert InvalidAmount()     │
     *      │    - If YES: Continue                  │
     *      │    ↓                                      │
     *      │ 2. VALIDATION: Check msg.sender == owner│
     *      │    - If NO: Revert Unauthorized(sender)│
     *      │    - If YES: Continue                  │
     *      │    ↓                                      │
     *      │ 3. UPDATE STATE: Increase balances     │
     *      │    - balance += amount                  │
     *      │    - totalDeposits += amount            │
     *      └─────────────────────────────────────────┘
     *
     *      CUSTOM ERRORS VS require() WITH STRINGS:
     *      ═══════════════════════════════════════════
     *
     *      APPROACH 1: require() with String (EXPENSIVE!)
     *      ```solidity
     *      require(amount > 0, "Amount must be positive");
     *      require(msg.sender == owner, "Only owner");
     *      ```
     *      - Cost: ~50 + 24*3 + 50 + 11*3 = ~205 gas
     *      - Pros: Human-readable
     *      - Cons: Very expensive, string data stored in bytecode
     *
     *      APPROACH 2: Custom Errors (CHEAP!)
     *      ```solidity
     *      if (amount == 0) revert InvalidAmount();
     *      if (msg.sender != owner) revert Unauthorized(msg.sender);
     *      ```
     *      - Cost: ~50 + 70 = ~120 gas
     *      - Pros: Much cheaper, can include parameters
     *      - Cons: Need ABI to decode (but tools do this automatically!)
     *
     *      GAS SAVINGS: ~85 gas per function call (41% reduction!)
     *
     *      GAS COST BREAKDOWN:
     *      ┌─────────────────────┬──────────────┬─────────────────┐
     *      │ Operation           │ Gas (warm)   │ Gas (cold)      │
     *      ├─────────────────────┼──────────────┼─────────────────┤
     *      │ Comparison (== 0)    │ ~3 gas       │ ~3 gas          │
     *      │ Custom error        │ ~50 gas      │ ~50 gas         │
     *      │ Comparison (!=)      │ ~3 gas       │ ~3 gas          │
     *      │ Custom error + param│ ~70 gas      │ ~70 gas         │
     *      │ SLOAD balance       │ ~100 gas     │ ~2,100 gas      │
     *      │ SSTORE balance      │ ~5,000 gas   │ ~20,000 gas     │
     *      │ SSTORE totalDeposits│ ~5,000 gas   │ ~20,000 gas     │
     *      ├─────────────────────┼──────────────┼─────────────────┤
     *      │ TOTAL (warm)        │ ~10,226 gas  │                 │
     *      │ TOTAL (cold)        │              │ ~42,226 gas     │
     *      └─────────────────────┴──────────────┴─────────────────┘
     *
     *      CONNECTION TO PROJECT 01: Storage Updates!
     *      ══════════════════════════════════════════
     *
     *      We're updating two state variables:
     *      - balance: Stored in slot 0
     *      - totalDeposits: Stored in slot 1
     *
     *      Both use the += operator (read-modify-write pattern):
     *      - Read current value (SLOAD)
     *      - Add amount (ADD)
     *      - Write new value (SSTORE)
     *
     *      REAL-WORLD ANALOGY:
     *      ═══════════════════
     *
     *      Like using error codes instead of full messages:
     *      - **require() with string**: "Error 404: Page not found"
     *        (helpful but expensive to store)
     *      - **Custom error**: ErrorCode(404)
     *        (cheap, tools translate it automatically)
     *
     *      🎓 LEARNING MOMENT:
     *      Custom errors are the industry standard for production contracts!
     *      They save massive amounts of gas while still providing useful
     *      error information through parameters.
     */
    function depositWithCustomError(uint256 amount) public {
        // 🛡️  VALIDATION 1: Check amount is positive
        // CONNECTION TO PROJECT 05: Custom errors!
        // Using custom error instead of require() with string
        // Cost: ~50 gas (just error selector)
        if (amount == 0) revert InvalidAmount(); // ~50 gas

        // 🛡️  VALIDATION 2: Check caller is owner
        // CONNECTION TO PROJECT 05: Custom errors with parameters!
        // Using custom error with parameter (includes caller address)
        // Cost: ~70 gas (error selector + address parameter)
        if (msg.sender != owner) revert Unauthorized(msg.sender); // ~70 gas

        // 💾 UPDATE STATE: Increase balance
        // CONNECTION TO PROJECT 01: Storage write!
        // Using += operator (read-modify-write pattern)
        balance += amount; // SSTORE: ~5,000 gas (warm)

        // 💾 UPDATE STATE: Increase total deposits
        // CONNECTION TO PROJECT 01: Storage write!
        // Tracking total deposits for invariant checking
        totalDeposits += amount; // SSTORE: ~5,000 gas (warm)
    }

    /**
     * @notice Withdraw funds with custom error
     * @param amount Amount to withdraw
     *
     * @dev WITHDRAWAL WITH CUSTOM ERROR: Gas-Efficient Error Handling
     * ═══════════════════════════════════════════════════════════════
     *
     *      This function demonstrates using custom errors with parameters
     *      for better error reporting while maintaining gas efficiency.
     *
     *      EXECUTION FLOW:
     *      ┌─────────────────────────────────────────┐
     *      │ 1. CHECK: Validate balance >= amount    │
     *      │    - If NO: Revert with custom error    │
     *      │    - If YES: Continue                  │
     *      │    ↓                                      │
     *      │ 2. UPDATE: Decrease balance             │
     *      │    - balance -= amount                 │
     *      └─────────────────────────────────────────┘
     *
     *      CUSTOM ERROR WITH PARAMETERS:
     *      ══════════════════════════════
     *
     *      Our custom error includes TWO parameters:
     *      ```solidity
     *      error InsufficientBalance(uint256 available, uint256 required);
     *      ```
     *
     *      When we revert, we provide BOTH values:
     *      ```solidity
     *      revert InsufficientBalance(balance, amount);
     *      ```
     *
     *      This gives error handlers complete context:
     *      - What they have: balance
     *      - What they need: amount
     *      - Why it failed: Insufficient balance
     *
     *      GAS OPTIMIZATION: Parameters in Errors
     *      ═══════════════════════════════════════
     *
     *      APPROACH 1: Custom Error with Parameters (What we use)
     *      ```solidity
     *      revert InsufficientBalance(balance, amount);
     *      ```
     *      - Cost: ~50 + 32 + 32 = ~114 gas
     *      - Pros: Provides both values, type-safe
     *      - Cons: Slightly more expensive than no params
     *
     *      APPROACH 2: require() with String
     *      ```solidity
     *      require(balance >= amount, "Insufficient balance");
     *      ```
     *      - Cost: ~50 + 20*3 = ~110 gas
     *      - Pros: Human-readable
     *      - Cons: Less informative (doesn't show values)
     *
     *      APPROACH 3: Custom Error without Parameters
     *      ```solidity
     *      revert InsufficientBalance();
     *      ```
     *      - Cost: ~50 gas
     *      - Pros: Cheapest
     *      - Cons: No context (doesn't show balance or amount)
     *
     *      TRADE-OFF: ~4 gas more, but error handler gets both values!
     *      This makes debugging MUCH easier - worth the small cost!
     *
     *      GAS COST BREAKDOWN:
     *      ┌─────────────────────┬──────────────┬─────────────────┐
     *      │ Operation           │ Gas (warm)   │ Gas (cold)      │
     *      ├─────────────────────┼──────────────┼─────────────────┤
     *      │ SLOAD balance       │ ~100 gas     │ ~2,100 gas      │
     *      │ Comparison (<)      │ ~3 gas       │ ~3 gas          │
     *      │ Custom error        │ ~114 gas     │ ~114 gas        │
     *      │ SSTORE balance      │ ~5,000 gas   │ ~20,000 gas     │
     *      ├─────────────────────┼──────────────┼─────────────────┤
     *      │ TOTAL (warm)        │ ~5,217 gas   │                 │
     *      │ TOTAL (cold)        │              │ ~22,217 gas     │
     *      └─────────────────────┴──────────────┴─────────────────┘
     *
     *      CONNECTION TO PROJECT 01: Storage Updates!
     *      ══════════════════════════════════════════
     *
     *      We're updating the balance state variable:
     *      - Stored in slot 0 (first state variable)
     *      - Using -= operator (read-modify-write pattern)
     *      - Cost: ~5,100 gas (warm) or ~22,100 gas (cold)
     *
     *      STORAGE UPDATE:
     *      ┌─────────────────────────────────────────────┐
     *      │ Slot 0: balance (uint256)                   │
     *      │ Old value: 100 wei                           │
     *      │ Operation: balance -= amount (50 wei)      │
     *      │ New value: 50 wei                           │
     *      │ Cost: ~5,000 gas (warm SSTORE)              │
     *      └─────────────────────────────────────────────┘
     *
     *      ERROR DECODING:
     *      ═══════════════
     *
     *      When this error is emitted, tools can decode it:
     *      ```javascript
     *      try {
     *          await contract.withdraw(200);
     *      } catch (error) {
     *          // Error decoded automatically:
     *          // InsufficientBalance(available: 100, required: 200)
     *          console.log("Available:", error.args.available);
     *          console.log("Required:", error.args.required);
     *      }
     *      ```
     *
     *      This makes debugging MUCH easier than string messages!
     *
     *      REAL-WORLD ANALOGY:
     *      ═══════════════════
     *
     *      Like a detailed error report:
     *      - **String error**: "Insufficient balance" (not helpful!)
     *      - **Custom error**: "InsufficientBalance(available: 100, required: 200)"
     *        (shows exactly what's wrong!)
     *
     *      The custom error is like a detailed error report that includes
     *      both what you have and what you need, making debugging easier.
     *
     *      CONNECTION TO PROJECT 02: Simple Withdrawal Pattern!
     *      ═══════════════════════════════════════════════════
     *
     *      This is a simplified withdrawal function (no ETH transfer).
     *      Project 02 showed the full pattern with Checks-Effects-Interactions!
     *
     *      🎓 LEARNING MOMENT:
     *      Custom errors with parameters are the best of both worlds:
     *      - Gas-efficient (like error codes)
     *      - Informative (like detailed messages)
     *      - Type-safe (parameters are typed)
     *      - Decodable (tools can parse them automatically)
     */
    function withdraw(uint256 amount) public {
        // 🛡️  VALIDATION: Check balance is sufficient
        // CONNECTION TO PROJECT 01: Storage read!
        // Reading balance: ~100 gas (warm) or ~2,100 gas (cold)
        // If balance is insufficient, revert with custom error
        // The error includes BOTH values (balance and amount) for context!
        if (balance < amount) {
            // 📢 CUSTOM ERROR WITH PARAMETERS: Provides full context
            // CONNECTION TO PROJECT 05: Custom errors!
            // This error includes both balance and amount
            // Cost: ~114 gas (error selector + 2 parameters)
            // Tools can decode this automatically for better UX!
            revert InsufficientBalance(balance, amount); // ~114 gas
        }

        // 💾 UPDATE STATE: Decrease balance
        // CONNECTION TO PROJECT 01: Storage write!
        // Using -= operator (read-modify-write pattern)
        // Cost: ~5,000 gas (warm) or ~20,000 gas (cold)
        balance -= amount; // SSTORE: ~5,000 gas (warm)
    }

    // ════════════════════════════════════════════════════════════════════════
    // FUNCTIONS USING assert()
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Check invariant using assert()
     * @dev GAS OPTIMIZATION: assert() vs require()
     *      - assert(): ~50 gas (same as require without message)
     *      - require(): ~50 gas (without message)
     *      - Both cost the same, but assert() indicates a programming error
     *
     * WHEN TO USE assert():
     * - For invariants that should NEVER fail if code is correct
     * - For internal consistency checks
     * - Compiler may optimize assert() differently
     *
     * WHEN TO USE require():
     * - For user input validation
     * - For conditions that can legitimately fail
     * - For business logic checks
     *
     * REAL-WORLD ANALOGY: assert() is like a safety check in a car's
     * engine - if it fails, something is fundamentally wrong with the
     * design, not the driver's input.
     *
     * IMPORTANT: assert() consumes ALL gas if it fails (no refund)!
     * This is intentional - it indicates a serious bug that should be fixed.
     *
     * CONNECTION TO PROJECT 01: Invariants are properties that should always be true!
     */
    function checkInvariant() public view {
        // Invariant: totalDeposits should always be >= balance
        // This should NEVER fail if the code is correct
        // If it fails, there's a serious bug!
        assert(totalDeposits >= balance);
    }

    // ════════════════════════════════════════════════════════════════════════
    // VIEW FUNCTIONS
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Get current balance
     * @return Current balance
     *
     * @dev VIEW FUNCTION: Reading State
     * ═══════════════════════════════════
     *
     *      Simple view function to read the current balance.
     *      FREE when called off-chain!
     *
     *      CONNECTION TO PROJECT 01: View Functions!
     *      ═════════════════════════════════════════
     *
     *      View functions are free when called off-chain.
     *      This is perfect for frontends to display balances!
     *
     *      GAS COST:
     *      - Off-chain call: FREE! (no transaction)
     *      - On-chain call: ~100 gas (SLOAD from storage)
     */
    function getBalance() public view returns (uint256) {
        // 📖 READ FROM STORAGE: Simple storage read
        // CONNECTION TO PROJECT 01: Storage reads!
        // This reads from slot 0 (where balance is stored)
        // Cost: ~100 gas (if on-chain), FREE (if off-chain)
        return balance; // SLOAD: ~100 gas (if on-chain), FREE (if off-chain)
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. CUSTOM ERRORS SAVE ~90% GAS
 *    ✅ Custom errors: ~200 gas (just error selector)
 *    ✅ require() with string: ~2,000 gas (selector + string data)
 *    ✅ Savings: ~1,800 gas per error (90% reduction!)
 *    ✅ Can include parameters (like InsufficientBalance(balance, amount))
 *    ✅ Real-world: Like using error codes vs full error messages
 *
 * 2. WHEN TO USE EACH ERROR TYPE
 *    ✅ require(): User input validation, business logic checks
 *       - Can use custom errors or strings
 *       - Reverts with gas refunded
 *    ✅ revert with custom error: All error conditions (preferred!)
 *       - Most gas-efficient
 *       - Can include typed parameters
 *       - Industry standard for production
 *    ✅ assert(): Internal invariants (should NEVER fail)
 *       - Programming errors, not user errors
 *       - Consumes ALL gas if fails (no refund!)
 *       - Use sparingly!
 *
 * 3. CUSTOM ERRORS ARE DEFINED OUTSIDE CONTRACT
 *    ✅ Defined at file level (like events)
 *    ✅ Syntax: error ErrorName(ParamType param);
 *    ✅ Can have multiple parameters
 *    ✅ Parameters are typed (like function parameters)
 *    ✅ Real-world: Like error type definitions in Rust enums
 *
 * 4. ERROR PROPAGATION BEHAVIOR
 *    ✅ When function reverts, error bubbles up
 *    ✅ All state changes are undone (atomicity)
 *    ✅ Remaining gas is refunded (except assert())
 *    ✅ Error data is encoded and returned
 *    ✅ Real-world: Like a chain reaction - one failure stops everything
 *
 * 5. ERROR DECODING IS AUTOMATIC
 *    ✅ Modern tools decode custom errors automatically
 *    ✅ Etherscan, Foundry, ethers.js all support error decoding
 *    ✅ Error selector + parameters = human-readable errors
 *    ✅ Real-world: Like error codes that tools can translate
 *
 * 6. GAS OPTIMIZATION WITH CUSTOM ERRORS
 *    ✅ Include parameters when helpful (like balance, amount)
 *    ✅ Slightly more expensive than no params, but provides context
 *    ✅ Trade-off: ~4 gas more, but error handler gets both values
 *    ✅ Real-world: Like detailed error reports vs simple error codes
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMMON MISTAKES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ❌ Using require() with strings in production (wastes gas!)
 * ❌ Using assert() for user input validation (wrong tool!)
 * ❌ Not checking return values from .call() (silent failures)
 * ❌ Defining custom errors inside contract (must be outside!)
 * ❌ Not including helpful parameters in custom errors
 * ❌ Using generic error names (Error1, Error2) instead of descriptive names
 * ❌ Not reverting early (continuing execution wastes gas)
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          NEXT STEPS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * • Compare gas costs: require() vs custom errors (use forge test --gas-report)
 * • Study OpenZeppelin's error patterns
 * • Learn about error handling in external calls
 * • Explore try-catch patterns (Solidity 0.6.0+)
 * • Learn about error handling in upgradeable contracts
 * • Move to Project 06 to learn about mappings, arrays, and gas optimization
 */
