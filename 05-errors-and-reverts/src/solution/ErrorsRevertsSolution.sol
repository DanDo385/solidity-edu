// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ErrorsRevertsSolution
 * @notice Demonstrates different error handling mechanisms in Solidity
 * @dev Shows gas-efficient error patterns and when to use each
 * 
 * REAL-WORLD ANALOGY: Errors are like different types of warnings:
 * - require(): Like a "STOP" sign - prevents action with a message
 * - revert with custom error: Like a specific error code - precise and efficient
 * - assert(): Like a safety check - should never fail if code is correct
 */

// Custom errors are more gas-efficient than require() with strings
error InsufficientBalance(uint256 available, uint256 required);
error Unauthorized(address caller);
error InvalidAmount();
error InvariantViolation();

contract ErrorsRevertsSolution {
    address public owner;
    uint256 public balance;
    uint256 public totalDeposits;
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @notice Deposit using require() statements
     * @param amount Amount to deposit
     * 
     * GAS COST: require() with string message
     * - require(condition, "message"): ~50 gas + string length * 3 gas
     * - For "Amount must be positive": ~50 + 24*3 = ~122 gas
     * - For "Only owner": ~50 + 11*3 = ~83 gas
     * - Total: ~205 gas for both requires
     * 
     * REAL-WORLD ANALOGY: Like a detailed error message on a form - helpful
     * for debugging but costs more to store and transmit.
     */
    function depositWithRequire(uint256 amount) public {
        require(amount > 0, "Amount must be positive");
        require(msg.sender == owner, "Only owner");
        balance += amount;
        totalDeposits += amount;
    }
    
    /**
     * @notice Deposit using custom errors (gas-efficient!)
     * @param amount Amount to deposit
     * 
     * GAS OPTIMIZATION: Custom errors vs require() with strings
     * - Custom error: ~50 gas (just the error selector)
     * - require() with string: ~50 + string_length * 3 gas
     * - For "Amount must be positive" (24 chars): ~122 gas
     * - Savings: ~72 gas per error (59% reduction!)
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
     * LANGUAGE COMPARISON:
     *   TypeScript: throw new Error("message") - similar to require()
     *   Go: return fmt.Errorf("message") - similar to require()
     *   Rust: Err(ErrorType::Variant) - similar to custom errors!
     *   Solidity: Custom errors are most efficient (like Rust enums)
     */
    function depositWithCustomError(uint256 amount) public {
        if (amount == 0) revert InvalidAmount();
        if (msg.sender != owner) revert Unauthorized(msg.sender);
        balance += amount;
        totalDeposits += amount;
    }
    
    /**
     * @notice Withdraw funds with custom error
     * @param amount Amount to withdraw
     * 
     * GAS OPTIMIZATION: Why include parameters in error?
     * - revert InsufficientBalance(balance, amount): ~50 + 32 + 32 = ~114 gas
     * - require(balance >= amount, "Insufficient balance"): ~50 + 20*3 = ~110 gas
     * - Custom error with params: Slightly more expensive BUT provides context
     * - Trade-off: ~4 gas more, but error handler gets both values
     * 
     * REAL-WORLD ANALOGY: Like a detailed error report that includes both
     * what you have and what you need, making debugging easier.
     */
    function withdraw(uint256 amount) public {
        if (balance < amount) {
            revert InsufficientBalance(balance, amount);
        }
        balance -= amount;
    }
    
    /**
     * @notice Check invariant using assert()
     * 
     * GAS OPTIMIZATION: assert() vs require()
     * - assert(): ~50 gas (same as require without message)
     * - require(): ~50 gas (without message)
     * - Both cost the same, but assert() indicates a programming error
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
     */
    function checkInvariant() public view {
        assert(totalDeposits >= balance);
    }
    
    function getBalance() public view returns (uint256) {
        return balance;
    }
}
