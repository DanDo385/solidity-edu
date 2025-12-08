// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ErrorsRevertsSolution
 * @notice Educational contract demonstrating error handling, reverts, and gas optimization
 * 
 * ═══════════════════════════════════════════════════════════════════════════
 *                        CONTRACT PURPOSE
 * ═══════════════════════════════════════════════════════════════════════════
 * 
 * This contract builds on Projects 01-04 and introduces:
 * 
 * 1. **Error Handling**: require, revert, assert
 *    - Different ways to handle errors
 *    - Gas cost differences
 *    - When to use each pattern
 * 
 * 2. **Custom Errors**: Gas-efficient error reporting
 *    - Introduced in Solidity 0.8.4
 *    - Much cheaper than string messages
 *    - Can include parameters for context
 * 
 * 3. **Revert Patterns**: Transaction rollback
 *    - All state changes are reverted
 *    - Gas consumed up to revert point
 *    - Essential for security
 * 
 * REAL-WORLD USE CASES:
 * - Input validation
 * - Access control
 * - Invariant checking
 * - All production contracts use error handling
 * 
 * ═══════════════════════════════════════════════════════════════════════════
 *                    COMPUTER SCIENCE CONCEPTS
 * ═══════════════════════════════════════════════════════════════════════════
 * 
 * 1. **Exception Handling**
 *    - Similar to try/catch in other languages
 *    - Reverts undo all state changes (atomicity)
 *    - Transaction fails if error occurs
 * 
 * 2. **Gas Optimization**
 *    - Custom errors: ~26 gas + parameters
 *    - String messages: ~50+ gas + string length
 *    - Significant savings in production
 * 
 * 3. **Invariant Checking**
 *    - assert(): For internal consistency
 *    - Should never fail in correct code
 *    - Uses all remaining gas (panic)
 * 
 * 4. **Transaction Atomicity**
 *    - All-or-nothing execution
 *    - Revert = no state changes
 *    - Similar to database transactions
 * 
 * CONNECTION TO PROJECT 01:
 * - Uses storage patterns for balances
 * - Builds on storage layout concepts
 * 
 * CONNECTION TO PROJECT 02:
 * - Uses owner pattern for access control
 * - Builds on function visibility concepts
 * 
 * CONNECTION TO PROJECT 04:
 * - Error handling used in modifiers
 * - Access control uses require/revert
 * 
 * @dev This is the FIFTH project - error handling is critical for security
 */
contract ErrorsRevertsSolution {
    // ════════════════════════════════════════════════════════════════════════
    // CUSTOM ERROR DECLARATIONS
    // ════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Custom error with parameters
     * @dev CUSTOM ERROR DECLARATION (Computer Science: Structured Error Types)
     * 
     * Custom errors were introduced in Solidity 0.8.4.
     * They're much more gas-efficient than string messages!
     * 
     * GAS COMPARISON:
     * - Custom error: ~26 gas + parameter encoding
     * - String message: ~50+ gas + string length encoding
     * - Savings: ~24+ gas per error (significant in production!)
     * 
     * PARAMETERIZED ERRORS:
     * - Can include values for context
     * - Helps debugging and frontend error handling
     * - Example: InsufficientBalance(available, required)
     * 
     * COMPUTER SCIENCE: Structured Error Types
     * - Similar to exception classes in OOP
     * - Type-safe error handling
     * - Better than magic strings
     * 
     * SYNTAX: error ErrorName(type param1, type param2);
     * - error: Keyword for custom error declaration
     * - Parameters: Can include values for context
     * - Must be declared outside contract
     */
    error InsufficientBalance(uint256 available, uint256 required);
    error Unauthorized(address caller);
    error InvalidAmount();
    error InvariantViolation();

    // ════════════════════════════════════════════════════════════════════════
    // STATE VARIABLES
    // ════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Contract owner
     * @dev CONNECTION TO PROJECT 01: Address storage pattern
     * Used for access control (from Projects 01-04)
     */
    address public owner;

    /**
     * @notice Current balance
     * @dev CONNECTION TO PROJECT 01: uint256 storage
     * Tracks current balance in contract
     */
    uint256 public balance;

    /**
     * @notice Total deposits (for invariant checking)
     * @dev CONNECTION TO PROJECT 01: uint256 storage
     * Used to verify internal consistency
     */
    uint256 public totalDeposits;

    /**
     * @notice Constructor - initializes owner
     * @dev CONNECTION TO PROJECT 01: Constructor pattern
     */
    constructor() {
        owner = msg.sender;
    }

    // ════════════════════════════════════════════════════════════════════════
    // ERROR HANDLING PATTERNS
    // ════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Deposit using require() with string message
     * @dev REQUIRE PATTERN (Computer Science: Guard Clauses)
     * 
     * require() is the most common error handling pattern.
     * It validates conditions and reverts with a message if false.
     * 
     * COMPUTER SCIENCE: Guard Clauses
     * - Validate inputs early (fail fast)
     * - Prevents invalid state transitions
     * - Similar to preconditions in design by contract
     * 
     * GAS COST:
     * - require(): ~3 gas (base)
     * - String message: ~50+ gas + string length encoding
     * - Total: ~53+ gas per require()
     * 
     * WHEN TO USE:
     * - Input validation
     * - Access control
     * - State validation
     * - Development/debugging (readable messages)
     * 
     * SYNTAX: require(condition, "Error message");
     * - condition: Boolean expression
     * - message: String error message (optional but recommended)
     * - Reverts transaction if condition is false
     * 
     * CONNECTION TO PROJECT 02: Access control pattern!
     * - require(msg.sender == owner, "Only owner")
     * - Used throughout Projects 01-04
     */
    function depositWithRequire(uint256 amount) public {
        // Input validation: Guard clause pattern
        require(amount > 0, "Amount must be positive"); // ~53+ gas
        
        // Access control: CONNECTION TO PROJECT 02: Owner pattern!
        require(msg.sender == owner, "Only owner"); // ~53+ gas

        // Update state: CONNECTION TO PROJECT 01: Storage updates!
        balance += amount; // SSTORE: ~5,000 gas (warm)
        totalDeposits += amount; // SSTORE: ~5,000 gas (warm)
    }

    /**
     * @notice Deposit using custom errors (gas-optimized)
     * @dev CUSTOM ERROR PATTERN (Computer Science: Structured Error Handling)
     * 
     * Custom errors are more gas-efficient than string messages.
     * They're the recommended pattern for production contracts.
     * 
     * GAS COMPARISON:
     * - Custom error: ~26 gas + parameter encoding
     * - String message: ~53+ gas
     * - Savings: ~27+ gas per error (significant in production!)
     * 
     * WHEN TO USE:
     * - Production contracts (gas optimization)
     * - When you need parameterized errors
     * - Better error handling in frontends
     * 
     * SYNTAX: if (condition) revert ErrorName(params);
     * - if: Conditional statement
     * - revert: Revert with custom error
     * - ErrorName: Custom error name (must be declared)
     * - params: Optional parameters for context
     * 
     * CONNECTION TO PROJECT 04: Access control with custom errors!
     * - More gas-efficient than require() with strings
     * - Better for production contracts
     */
    function depositWithCustomError(uint256 amount) public {
        // Input validation: Custom error (gas-efficient!)
        if (amount == 0) revert InvalidAmount(); // ~26 gas

        // Access control: Parameterized custom error
        if (msg.sender != owner) revert Unauthorized(msg.sender); // ~26 + address encoding

        // Update state: CONNECTION TO PROJECT 01: Storage updates!
        balance += amount; // SSTORE: ~5,000 gas (warm)
        totalDeposits += amount; // SSTORE: ~5,000 gas (warm)
    }

    /**
     * @notice Withdraw with parameterized custom error
     * @dev PARAMETERIZED ERRORS (Computer Science: Context-Rich Errors)
     * 
     * Custom errors can include parameters for context.
     * This helps debugging and frontend error handling.
     * 
     * BENEFITS:
     * - Includes actual values (available, required)
     * - Frontends can display helpful messages
     * - Better debugging experience
     * 
     * CONNECTION TO PROJECT 02: CEI Pattern!
     * - Checks: Validate balance
     * - Effects: Update balance
     * - Note: No external interactions here
     * 
     * SYNTAX: revert InsufficientBalance(balance, amount);
     * - Error name: InsufficientBalance
     * - Parameters: balance (available), amount (required)
     * - Frontend can extract these values
     */
    function withdraw(uint256 amount) public {
        // CHECKS: Validate balance with parameterized error
        // CONNECTION TO PROJECT 01: Storage read!
        if (balance < amount) revert InsufficientBalance(balance, amount); // ~26 + uint256 encoding

        // EFFECTS: Update state
        // CONNECTION TO PROJECT 01: Storage update!
        balance -= amount; // SSTORE: ~5,000 gas (warm)
    }

    /**
     * @notice Check internal invariant
     * @dev ASSERT PATTERN (Computer Science: Invariant Checking)
     * 
     * assert() is for internal consistency checks.
     * It should NEVER fail in correct code.
     * 
     * COMPUTER SCIENCE: Invariant Checking
     * - Invariants: Properties that should always be true
     * - Assertions: Verify invariants hold
     * - If assertion fails, code has a bug
     * 
     * GAS BEHAVIOR:
     * - assert(): Uses ALL remaining gas (panic)
     * - More expensive than require() on failure
     * - Should only be used for internal consistency
     * 
     * WHEN TO USE:
     * - Internal consistency checks
     * - Should never fail in correct code
     * - Debugging and testing
     * 
     * WHEN NOT TO USE:
     * - Input validation (use require())
     * - Access control (use require())
     * - User-facing errors (use require() or custom errors)
     * 
     * SYNTAX: assert(condition);
     * - condition: Boolean expression
     * - Reverts with panic code if false
     * - No error message (panic code instead)
     * 
     * INVARIANT EXAMPLE:
     * - totalDeposits should always >= balance
     * - If this fails, there's a bug in the code
     */
    function checkInvariant() public view {
        // Internal consistency check
        // CONNECTION TO PROJECT 01: Storage reads!
        assert(totalDeposits >= balance); // Should never fail in correct code
    }

    /**
     * @notice Get current balance
     * @dev VIEW FUNCTION (Computer Science: Query Function)
     * 
     * CONNECTION TO PROJECT 01: Storage read pattern!
     * View functions are free when called off-chain
     */
    function getBalance() public view returns (uint256) {
        return balance; // SLOAD: ~100 gas (on-chain), FREE (off-chain)
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS - PROJECT 05
 * ═══════════════════════════════════════════════════════════════════════════
 * 
 * 1. REQUIRE() FOR VALIDATION
 *    ✅ Validates conditions and reverts if false
 *    ✅ Can include string message (useful for debugging)
 *    ✅ Gas cost: ~53+ gas (with string message)
 *    ✅ Use for: Input validation, access control, state validation
 * 
 * 2. CUSTOM ERRORS ARE GAS-EFFICIENT
 *    ✅ Introduced in Solidity 0.8.4
 *    ✅ Gas cost: ~26 gas + parameter encoding
 *    ✅ Savings: ~27+ gas per error (significant!)
 *    ✅ Use for: Production contracts, parameterized errors
 * 
 * 3. REVERT WITH CUSTOM ERRORS
 *    ✅ if (condition) revert ErrorName(params);
 *    ✅ Can include parameters for context
 *    ✅ Better for frontend error handling
 *    ✅ Recommended for production
 * 
 * 4. ASSERT() FOR INVARIANTS
 *    ✅ Internal consistency checks only
 *    ✅ Should NEVER fail in correct code
 *    ✅ Uses all remaining gas (panic)
 *    ✅ Use for: Debugging, testing, internal checks
 * 
 * 5. TRANSACTION ATOMICITY
 *    ✅ Revert = no state changes
 *    ✅ All-or-nothing execution
 *    ✅ Gas consumed up to revert point
 *    ✅ Essential for security
 * 
 * 6. ERROR HANDLING PATTERNS
 *    ✅ require(): Input validation, access control
 *    ✅ revert with custom error: Production, gas-efficient
 *    ✅ assert(): Internal consistency (should never fail)
 * 
 * ═══════════════════════════════════════════════════════════════════════════
 *                    CONNECTIONS TO FUTURE PROJECTS
 * ═══════════════════════════════════════════════════════════════════════════
 * 
 * • All Future Projects
 *   - Error handling used throughout
 *   - Custom errors recommended for production
 *   - Critical for security and UX
 * 
 * • Project 07: Reentrancy & Security
 *   - Error handling prevents attacks
 *   - Reverts protect against invalid state
 *   - Essential for secure contracts
 * 
 * • Project 08: ERC20 Token
 *   - Uses require() for validation
 *   - Custom errors for gas optimization
 *   - Error handling for all operations
 * 
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMPUTER SCIENCE CONCEPTS
 * ═══════════════════════════════════════════════════════════════════════════
 * 
 * • Exception Handling: Reverts undo state changes (atomicity)
 * • Guard Clauses: Validate early, fail fast
 * • Invariant Checking: Properties that should always hold
 * • Gas Optimization: Custom errors save gas vs strings
 * • Transaction Atomicity: All-or-nothing execution
 * 
 * Error handling is critical for secure, gas-efficient contracts!
 */
