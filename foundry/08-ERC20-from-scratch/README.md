# Project 08: ERC20 from Scratch 🪙

> **Implement the most important token standard in Ethereum**

## 🎯 Learning Objectives

By completing this project, you will:

1. **Understand the ERC20 standard** and its required functions
2. **Implement ERC20 from scratch** without libraries
3. **Master approval/allowance mechanics** for delegated transfers
4. **Understand token economics** and supply management
5. **Recognize approval race condition** vulnerability
6. **Compare manual vs OpenZeppelin** implementations
7. **Understand events** required by ERC20
8. **Create Foundry deployment scripts** for token deployment
9. **Write comprehensive test suites** for ERC20 functionality

## 📁 Project Directory Structure

```
08-ERC20-from-scratch/
├── README.md                          # This file
├── foundry.toml                       # Foundry configuration
├── src/
│   ├── ERC20Token.sol                # Skeleton contract (TODO: implement)
│   └── solution/
│       └── ERC20TokenSolution.sol    # Complete reference implementation
├── script/
│   ├── DeployERC20Token.s.sol         # Deployment script (TODO: implement)
│   └── solution/
│       └── DeployERC20TokenSolution.s.sol  # Reference deployment
└── test/
    ├── ERC20Token.t.sol               # Test suite (TODO: implement)
    └── solution/
        └── ERC20TokenSolution.t.sol    # Reference tests
```

## 🔑 Key Concepts

### ERC20 Standard Overview

ERC20 is the most widely used token standard on Ethereum. It defines a common interface for fungible tokens, enabling interoperability between different applications.

**Required Functions:**
```solidity
totalSupply() → uint256                    // Total token supply
balanceOf(address) → uint256               // Balance of an address
transfer(address, uint256) → bool         // Transfer tokens
approve(address, uint256) → bool          // Approve spending
allowance(address, address) → uint256     // Check approval amount
transferFrom(address, address, uint256) → bool  // Delegated transfer
```

**Required Events:**
```solidity
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);
```

**Real-world analogy**: Like a standardized currency format - every ERC20 token follows the same rules, so wallets and exchanges can handle them all the same way!

### Transfer Function

The `transfer()` function moves tokens from the caller to another address:

```solidity
function transfer(address to, uint256 amount) public returns (bool) {
    require(to != address(0), "Invalid recipient");
    require(balanceOf[msg.sender] >= amount, "Insufficient balance");
    
    balanceOf[msg.sender] -= amount;
    balanceOf[to] += amount;
    
    emit Transfer(msg.sender, to, amount);
    return true;
}
```

**Gas costs:**
- Validation: ~6 gas
- 2 SLOADs: ~200 gas (warm)
- 2 SSTOREs: ~10,000 gas (warm)
- Event: ~1,500 gas
- Total: ~11,706 gas (warm)

### Approval & Allowance Pattern

The approval pattern enables delegated spending - allowing another address to spend tokens on your behalf:

```solidity
function approve(address spender, uint256 amount) public returns (bool) {
    allowance[msg.sender][spender] = amount;  // Set approval
    emit Approval(msg.sender, spender, amount);
    return true;
}
```

**How it works:**
1. Owner calls `approve(spender, amount)`
2. Spender can now call `transferFrom(owner, recipient, amount)`
3. Approval is decremented automatically

**Real-world analogy**: Like giving someone a credit card with a spending limit - they can spend up to the approved amount, but you control the limit!

### TransferFrom Function

The `transferFrom()` function enables delegated transfers:

```solidity
function transferFrom(address from, address to, uint256 amount) public returns (bool) {
    require(balanceOf[from] >= amount, "Insufficient balance");
    require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
    
    balanceOf[from] -= amount;
    balanceOf[to] += amount;
    allowance[from][msg.sender] -= amount;  // Decrease allowance
    
    emit Transfer(from, to, amount);
    return true;
}
```

**Use cases:**
- DEXs swapping tokens
- Lending protocols using tokens as collateral
- Yield farming protocols staking tokens

### Approval Race Condition

⚠️ **WARNING**: There's a known race condition in ERC20 approvals!

**The Problem:**
If Alice approves Bob for 100 tokens, then wants to change it to 50:
1. Alice calls `approve(bob, 50)`
2. Bob sees the transaction in mempool
3. Bob front-runs with `transferFrom(alice, bob, 100)` (using old approval)
4. Then Alice's approval goes through (sets to 50)
5. Bob got 100 tokens, not 50!

**Mitigation:**
- Use `increaseAllowance()` / `decreaseAllowance()` (OpenZeppelin)
- Or approve to 0 first, then approve new amount
- Or use `safeIncreaseAllowance()` pattern

## 🏗️ What You'll Build

A complete ERC20 token implementation that includes:

1. **Token metadata** (name, symbol, decimals)
2. **Balance tracking** (mapping)
3. **Transfer functionality** (direct transfers)
4. **Approval system** (delegated spending)
5. **TransferFrom** (delegated transfers)
6. **Event emissions** (Transfer, Approval)

## 📋 Tasks

### 1. Implement Constructor
- Set token name, symbol, decimals
- Initialize total supply
- Mint initial supply to deployer
- Emit Transfer event (from address(0))

### 2. Implement `transfer(address to, uint256 amount)`
- Validate recipient is not zero address
- Check sender has sufficient balance
- Update balances (decrease sender, increase recipient)
- Emit Transfer event
- Return true

### 3. Implement `approve(address spender, uint256 amount)`
- Validate spender is not zero address
- Set allowance mapping
- Emit Approval event
- Return true

### 4. Implement `transferFrom(address from, address to, uint256 amount)`
- Validate addresses are not zero
- Check balance and allowance
- Update balances
- Decrease allowance
- Emit Transfer event
- Return true

### 5. Write Deployment Script
- Deploy token with name, symbol, initial supply
- Log deployment address
- Verify deployment

### 6. Write Comprehensive Tests
- Test transfer functionality
- Test approval and transferFrom
- Test edge cases (zero address, insufficient balance)
- Test events are emitted correctly
- Compare with OpenZeppelin ERC20

## 🧪 Test Coverage

Your tests should verify:

- ✅ Constructor initializes correctly
- ✅ Transfer works correctly
- ✅ Transfer reverts on invalid inputs
- ✅ Approval sets allowance correctly
- ✅ TransferFrom works with approval
- ✅ TransferFrom decreases allowance
- ✅ Events are emitted correctly
- ✅ Edge cases handled (zero address, insufficient balance/allowance)

## 🎓 Real-World Analogies & Fun Facts

### Currency Standardization
- **ERC20** = Standardized currency format
- **Different tokens** = Different currencies (USD, EUR, etc.)
- **Same interface** = Wallets can handle all tokens

### Credit Card Analogy
- **approve()** = Setting credit limit
- **allowance** = Remaining credit
- **transferFrom()** = Making a purchase (decreases credit)
- **Decrease allowance** = Automatic after purchase

### Fun Facts
- ERC20 was proposed in 2015 by Fabian Vogelsteller
- Over 500,000 ERC20 tokens exist on Ethereum
- Most DeFi protocols use ERC20 tokens
- USDC, USDT, DAI are all ERC20 tokens
- Approval race condition is a known issue (still used widely)

## ✅ Completion Checklist

- [ ] Implement constructor
- [ ] Implement transfer function
- [ ] Implement approve function
- [ ] Implement transferFrom function
- [ ] Emit Transfer events correctly
- [ ] Emit Approval events correctly
- [ ] Write deployment script
- [ ] Write comprehensive test suite
- [ ] Test all edge cases
- [ ] Review solution implementation
- [ ] Compare with OpenZeppelin ERC20

## 💡 Pro Tips

1. **Always validate addresses**: Check for zero address in transfer/approve
2. **Emit events correctly**: Required by ERC20 standard
3. **Return true**: ERC20 functions should return bool
4. **Decrease allowance**: Always decrease in transferFrom
5. **Use nested mappings**: For allowance (owner → spender → amount)
6. **Understand decimals**: Most tokens use 18 decimals (like ETH)
7. **Test approval race condition**: Understand the vulnerability

## 🚀 Next Steps

After completing this project:

- Move to [Project 09: ERC721 NFT from Scratch](../09-ERC721-NFT-from-scratch/)
- Study OpenZeppelin ERC20 implementation
- Add extensions (burnable, mintable, pausable)
- Learn about ERC20 extensions (ERC20Votes, ERC20Permit)
