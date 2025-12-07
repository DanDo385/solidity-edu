// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ErrorsRevertsSolution
/// @notice Reference implementation showing require/revert/assert patterns with concise, gas-aware comments.
/// @dev See the README for deep dives on revert opcodes, panic codes, and gas tradeoffs.

error InsufficientBalance(uint256 available, uint256 required);
error Unauthorized(address caller);
error InvalidAmount();
error InvariantViolation();

contract ErrorsRevertsSolution {
    /// @notice Owner set on deployment (used for basic access control).
    address public owner;

    /// @notice Tracks current balance stored in the contract.
    uint256 public balance;

    /// @notice Sum of all deposits for simple invariant checks.
    uint256 public totalDeposits;

    constructor() {
        owner = msg.sender;
    }

    /// @notice require-based validation with human-readable strings (useful for debugging, pricier in production).
    function depositWithRequire(uint256 amount) public {
        require(amount > 0, "Amount must be positive");
        require(msg.sender == owner, "Only owner");
        balance += amount;
        totalDeposits += amount;
    }

    /// @notice Custom errors keep revert data compact while still enforcing the same rules.
    /// @dev Mirrors ERC20-style balance updates and the access checks used in Project 04; see README for gas math.
    function depositWithCustomError(uint256 amount) public {
        if (amount == 0) revert InvalidAmount();
        if (msg.sender != owner) revert Unauthorized(msg.sender);

        balance += amount;
        totalDeposits += amount;
    }

    /// @notice Withdraw and bubble useful context with a parameterized custom error.
    /// @dev Pattern mirrors ERC20 balance checks and feeds later projects that rely on revert reasons for UX.
    function withdraw(uint256 amount) public {
        if (balance < amount) revert InsufficientBalance(balance, amount);
        balance -= amount;
    }

    /// @notice Internal consistency guard; if this fails something upstream violated assumptions.
    function checkInvariant() public view {
        assert(totalDeposits >= balance);
    }

    /// @notice Read-only helper mirroring the storage-access patterns from Project 01.
    function getBalance() public view returns (uint256) {
        return balance;
    }
}
