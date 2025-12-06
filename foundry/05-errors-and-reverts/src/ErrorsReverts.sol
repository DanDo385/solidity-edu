// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ErrorsReverts {
    // ============================================================
    // STATE VARIABLES
    // ============================================================

    uint256 public balance;

    // ============================================================
    // CUSTOM ERRORS
    // ============================================================

    // TODO: Define custom error InsufficientBalance(uint256 available, uint256 required)
    // TODO: Define custom error Unauthorized(address caller)
    // TODO: Define custom error InvalidAmount()
    // Custom errors keep revert data compact. On rollups, fewer bytes in revert
    // payloads mean cheaper dispute proofs. They also map cleanly to frontend
    // messages without inflating bytecode with strings.

    // ============================================================
    // FUNCTIONS
    // ============================================================

    // TODO: Implement function using require()
    // TODO: Implement function using custom errors
    // TODO: Implement function using assert()
    // require = user input checks (like airport security), revert = rich
    // domain errors, assert = internal invariants that should never fail.
    // Pre-0.8 Solidity used throw; modern REVERT opcode carries ABI data so
    // explorers can decode human-friendly reasons.
}
