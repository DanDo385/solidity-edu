# Project 07: Reentrancy & Security 🛡️

> **Understand and prevent the infamous reentrancy attack**

## 🎯 Learning Objectives

- Reproduce classic reentrancy attack
- Apply Checks-Effects-Interactions pattern
- Use OpenZeppelin ReentrancyGuard
- Understand cross-function reentrancy
- Learn read-only reentrancy

## 📚 Key Concepts

### The Reentrancy Attack

The vulnerability that drained The DAO ($60M in 2016):

```solidity
// VULNERABLE
function withdraw(uint amount) public {
    require(balances[msg.sender] >= amount);
    msg.sender.call{value: amount}("");  // ← Attacker re-enters here!
    balances[msg.sender] -= amount;      // ← Too late
}
```

### The Fix: Checks-Effects-Interactions

```solidity
// SAFE
function withdraw(uint amount) public {
    require(balances[msg.sender] >= amount);  // Check
    balances[msg.sender] -= amount;           // Effect (first!)
    msg.sender.call{value: amount}("");       // Interaction (last)
}
```

## 🔧 What You'll Build

A contract demonstrating:
- Vulnerable withdrawal function
- Attacker contract that exploits it
- Secure implementation with CEI pattern
- ReentrancyGuard integration

## ✅ Status

🚧 **Scaffold** - Complete Projects 01-06 first

## 🚀 Next Steps

After completing this project:
- Move to [Project 08: ERC20 from Scratch](../08-ERC20-from-scratch/)
