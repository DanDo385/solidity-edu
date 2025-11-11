# Project 08: ERC20 from Scratch 🪙

> **Implement the ERC20 token standard manually**

## 🎯 Learning Objectives

- Implement ERC20 interface from scratch
- Compare manual implementation vs OpenZeppelin
- Understand approval/allowance mechanics
- Learn about approval race condition vulnerability
- Implement token economics patterns

## 📚 Key Concepts

### ERC20 Required Functions

```solidity
totalSupply() → uint256
balanceOf(address) → uint256
transfer(address, uint256) → bool
approve(address, uint256) → bool
allowance(address, address) → uint256
transferFrom(address, address, uint256) → bool
```

### Required Events

```solidity
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);
```

## 📝 Tasks

```bash
cd 08-ERC20-from-scratch
forge test -vvv
forge test --gas-report
```

## ✅ Status

✅ **Complete** - Implement your own token!

## 🚀 Next Steps

- Move to [Project 09: ERC721 NFT from Scratch](../09-ERC721-NFT-from-scratch/)
- Study OpenZeppelin ERC20
- Add extensions (burnable, mintable, pausable)
