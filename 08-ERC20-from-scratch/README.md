# Project 08: ERC20 from Scratch 🪙

> **Implement the ERC20 token standard manually**

## 🎯 Learning Objectives

- Implement ERC20 interface from scratch
- Compare manual implementation vs OpenZeppelin
- Understand approval/allowance mechanics
- Learn about approval race conditions
- Implement token economics patterns

## 📚 Key Concepts

### ERC20 Standard

Required functions:
- `totalSupply()`
- `balanceOf(address)`
- `transfer(address, uint256)`
- `approve(address, uint256)`
- `allowance(address, address)`
- `transferFrom(address, address, uint256)`

### Approval Mechanics

Two-step pattern for third-party transfers:
1. Owner approves spender for amount
2. Spender transfers on owner's behalf

### Common Pitfalls

- Approval race condition
- Unchecked transfers
- Missing events
- Integer overflow (pre-0.8.0)

## 🔧 What You'll Build

A contract demonstrating:
- Full ERC20 implementation
- Comparison with OpenZeppelin
- Gas optimization techniques
- Security best practices

## ✅ Status

🚧 **Scaffold** - Complete Projects 01-07 first

## 🚀 Next Steps

After completing this project:
- Move to [Project 09: ERC721 NFT](../09-ERC721-NFT-from-scratch/)
