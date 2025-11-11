# Project 07: Reentrancy & Security 🛡️

> **Understand and prevent the infamous reentrancy attack**

## 🎯 Learning Objectives

- Reproduce classic reentrancy attack ($60M The DAO hack)
- Apply Checks-Effects-Interactions pattern
- Use OpenZeppelin ReentrancyGuard
- Understand cross-function reentrancy

## 📚 Key Concepts

### The Vulnerability

```solidity
// VULNERABLE
function withdraw(uint amount) public {
    require(balances[msg.sender] >= amount);
    msg.sender.call{value: amount}("");  // ← Attacker re-enters!
    balances[msg.sender] -= amount;      // ← Too late
}
```

### The Fix

```solidity
// SAFE: Checks-Effects-Interactions
function withdraw(uint amount) public {
    require(balances[msg.sender] >= amount);  // Check
    balances[msg.sender] -= amount;           // Effect (first!)
    msg.sender.call{value: amount}("");       // Interaction (last)
}
```

## 📝 Tasks

```bash
cd 07-reentrancy-and-security
forge test -vvv  # See the attack in action!
```

## ✅ Status

✅ **Complete** - Critical security lesson

## 🚀 Next Steps

- Move to [Project 08: ERC20 from Scratch](../08-ERC20-from-scratch/)
