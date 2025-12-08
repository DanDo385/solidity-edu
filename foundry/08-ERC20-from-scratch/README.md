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

### ERC20 Standard Overview: The Foundation of DeFi

**FIRST PRINCIPLES: Token Standardization**

ERC20 is the most widely used token standard on Ethereum. It defines a common interface for fungible tokens, enabling interoperability between different applications. This standardization is what makes DeFi composable!

**CONNECTION TO PROJECTS 01-07**:
- **Project 01**: We learned about mappings - ERC20 uses `mapping(address => uint256)` for balances
- **Project 02**: We learned about functions and ETH - ERC20 transfers tokens instead
- **Project 03**: We learned about events - ERC20 requires Transfer and Approval events
- **Project 04**: We learned about modifiers - ERC20 can use access control modifiers
- **Project 05**: We learned about errors - ERC20 uses custom errors for gas efficiency
- **Project 06**: We learned about gas optimization - ERC20 balances use O(1) mappings
- **Project 07**: We learned about security - ERC20 must follow CEI pattern

**REQUIRED FUNCTIONS**:
```solidity
totalSupply() → uint256                    // Total token supply
balanceOf(address) → uint256               // Balance of an address
transfer(address, uint256) → bool         // Transfer tokens
approve(address, uint256) → bool          // Approve spending
allowance(address, address) → uint256     // Check approval amount
transferFrom(address, address, uint256) → bool  // Delegated transfer
```

**REQUIRED EVENTS** (from Project 03 knowledge):
```solidity
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);
```

**UNDERSTANDING FUNGIBILITY**:

**Fungible** = Interchangeable (all tokens identical)
- Example: 1 USDC = 1 USDC (they're identical)
- Like: Dollar bills, gold bars, shares of stock

**Non-Fungible** = Unique (each token different)
- Example: Each NFT has unique properties
- Like: Trading cards, artwork, real estate

ERC20 tokens are fungible - this is what makes them work as currency!

**STORAGE STRUCTURE** (from Project 01 knowledge):

```solidity
mapping(address => uint256) public balanceOf;  // O(1) balance lookup
mapping(address => mapping(address => uint256)) public allowance;  // Nested mapping
uint256 public totalSupply;  // Total tokens in existence
```

**GAS COST BREAKDOWN**:

**Balance Check**:
- `balanceOf(addr)`: ~100 gas (warm SLOAD from mapping)

**Transfer**:
- Validation: ~6 gas
- 2 SLOADs: ~200 gas (warm reads)
- 2 SSTOREs: ~10,000 gas (warm writes)
- Event: ~1,500 gas
- Total: ~11,706 gas (warm)

**REAL-WORLD ANALOGY**: 
Like a standardized currency format - every ERC20 token follows the same rules, so wallets and exchanges can handle them all the same way! Just like how all credit cards have the same shape, all ERC20 tokens have the same interface.

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

### Approval & Allowance Pattern: Delegated Spending

**FIRST PRINCIPLES: Delegation Pattern**

The approval pattern enables delegated spending - allowing another address to spend tokens on your behalf. This is essential for DeFi composability!

**CONNECTION TO PROJECT 01**:
This uses **nested mappings**! `mapping(address => mapping(address => uint256))` stores approvals:
- Outer mapping: Owner address
- Inner mapping: Spender address → approved amount

**UNDERSTANDING THE PATTERN**:

```solidity
function approve(address spender, uint256 amount) public returns (bool) {
    allowance[msg.sender][spender] = amount;  // Set approval
    emit Approval(msg.sender, spender, amount);
    return true;
}
```

**HOW IT WORKS**:

```
Delegated Transfer Flow:
┌─────────────────────────────────────────┐
│ 1. Owner approves spender                │
│    approve(spender, 100)                 │
│    ↓                                      │
│    allowance[owner][spender] = 100       │ ← Storage write
│    ↓                                      │
│ 2. Spender calls transferFrom            │
│    transferFrom(owner, recipient, 50)    │
│    ↓                                      │
│    Check: allowance >= 50 ✅             │ ← Read from nested mapping
│    ↓                                      │
│    balanceOf[owner] -= 50                 │ ← Update balances
│    balanceOf[recipient] += 50            │
│    allowance[owner][spender] -= 50       │ ← Decrease allowance
│    ↓                                      │
│ 3. Approval automatically decremented    │ ← Can't exceed limit!
└─────────────────────────────────────────┘
```

**GAS COST BREAKDOWN** (from Project 01 & 06 knowledge):

**Approve**:
- SSTORE to nested mapping: ~5,000 gas (warm) or ~20,000 gas (cold)
- Event emission: ~1,500 gas
- Total: ~6,500 gas (warm) or ~21,500 gas (cold)

**TransferFrom**:
- 2 SLOADs (balance + allowance): ~200 gas (warm)
- 2 SSTOREs (balances): ~10,000 gas (warm)
- 1 SSTORE (allowance): ~5,000 gas (warm)
- Event: ~1,500 gas
- Total: ~16,700 gas (warm)

**USE CASES**:
- **DEXs**: Users approve DEX to swap tokens
- **Lending**: Users approve protocol to use tokens as collateral
- **Yield Farming**: Users approve staking contract to stake tokens
- **Multi-sig**: One signer approves another to execute transfers

**REAL-WORLD ANALOGY**: 
Like giving someone a credit card with a spending limit - they can spend up to the approved amount, but you control the limit! The allowance is like the credit limit, and `transferFrom` is like making a purchase (decreases available credit).

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
### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/ERC20TokenSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployERC20TokenSolution.s.sol` - Deployment script patterns
- `test/solution/ERC20TokenSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains hash tables (balances), nested mappings (allowances), delegation pattern
- **Connections to Projects 01-07**: Combines ALL previous concepts - storage, functions, events, CEI, access control
- **ERC20 Standard**: Complete implementation of the most important token standard (500,000+ tokens use it)
- **Real-World Context**: Foundation for all DeFi protocols - DEXs, lending, yield farming all use ERC20

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
