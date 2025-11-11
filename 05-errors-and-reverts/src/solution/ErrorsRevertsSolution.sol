// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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
    
    function depositWithRequire(uint256 amount) public {
        require(amount > 0, "Amount must be positive");
        require(msg.sender == owner, "Only owner");
        balance += amount;
        totalDeposits += amount;
    }
    
    function depositWithCustomError(uint256 amount) public {
        if (amount == 0) revert InvalidAmount();
        if (msg.sender != owner) revert Unauthorized(msg.sender);
        balance += amount;
        totalDeposits += amount;
    }
    
    function withdraw(uint256 amount) public {
        if (balance < amount) {
            revert InsufficientBalance(balance, amount);
        }
        balance -= amount;
    }
    
    function checkInvariant() public view {
        assert(totalDeposits >= balance);
    }
    
    function getBalance() public view returns (uint256) {
        return balance;
    }
}
