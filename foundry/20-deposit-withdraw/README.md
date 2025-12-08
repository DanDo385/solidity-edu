# Project 20: Deposit/Withdraw Accounting

> **Learn share-based accounting for deposits and withdrawals with slippage protection**

## Learning Objectives

- Understand share-based vs direct accounting
- Implement deposit/withdraw with share calculations
- Create preview functions for transaction simulation
- Add slippage protection against front-running
- Prepare for ERC-4626 Tokenized Vault Standard
- Handle rounding to protect the protocol

## Background: Why Share-Based Accounting?

### The Problem with Direct Accounting

Imagine a simple vault where users deposit tokens:

```solidity
// BAD: Direct accounting doesn't handle yield
mapping(address => uint256) public deposits;

function deposit(uint256 amount) external {
    deposits[msg.sender] += amount;  // Alice deposits 100 tokens
    token.transferFrom(msg.sender, address(this), amount);
}
```

**What happens when the vault earns yield?**

- Vault starts with 100 tokens
- Vault earns 10 tokens from external strategy
- Vault now has 110 tokens
- But Alice's deposit still shows 100!
- How do we distribute the 10 token profit?

### The Solution: Share-Based Accounting

**FIRST PRINCIPLES: Proportional Ownership Through Shares**

Instead of tracking exact deposits, we mint **shares** representing proportional ownership. This automatically handles yield distribution!

**CONNECTION TO PROJECT 01 & 06**:
- Uses mappings (Project 01) for O(1) lookups
- Uses arithmetic operations (Project 06) for share calculations
- Gas-efficient pattern for yield distribution!

```solidity
// ✅ GOOD: Share-based accounting handles yield automatically
mapping(address => uint256) public shares;  // From Project 01!
uint256 public totalShares;                 // Total shares minted
uint256 public totalAssets;                 // Tracks actual tokens in vault

function deposit(uint256 assets) external returns (uint256 shares) {
    shares = convertToShares(assets);  // Calculate proportional shares
    totalShares += shares;              // Update total shares
    totalAssets += assets;              // Update total assets
    shares[msg.sender] += shares;       // Credit user's shares
}

function convertToShares(uint256 assets) public view returns (uint256) {
    return totalShares == 0
        ? assets                        // First deposit: 1:1 ratio
        : (assets * totalShares) / totalAssets;  // Proportional shares
}
```

**HOW IT HANDLES YIELD AUTOMATICALLY**:

```
Share-Based Accounting Flow:
┌─────────────────────────────────────────┐
│ Step 1: Alice deposits 100 tokens       │
│   shares = (100 * 0) / 0 = 100         │ ← First deposit: 1:1
│   totalShares = 100                     │
│   totalAssets = 100                     │
│   shares[alice] = 100                   │
│   ↓                                      │
│ Step 2: Vault earns 10 tokens yield    │
│   totalAssets = 110 (increased!)        │ ← Yield increases assets
│   totalShares = 100 (unchanged!)        │ ← Shares stay same
│   Exchange rate: 110/100 = 1.1          │ ← Each share worth more!
│   ↓                                      │
│ Step 3: Bob deposits 110 tokens         │
│   shares = (110 * 100) / 110 = 100     │ ← Gets same shares as Alice
│   totalShares = 200                     │
│   totalAssets = 220                     │
│   shares[bob] = 100                     │
│   ↓                                      │
│ Step 4: Alice withdraws 100 shares     │
│   assets = (100 * 220) / 200 = 110    │ ← Gets 110 tokens!
│   Alice's profit: 10 tokens ✅          │ ← Automatic yield distribution!
└─────────────────────────────────────────┘
```

**WHY THIS WORKS**:

1. **Automatic Yield Distribution**: When assets increase, exchange rate increases
2. **Fair Distribution**: Each share gets proportional profit
3. **Gas Efficient**: No need to update individual user balances
4. **Simple Math**: Just track totals, calculate on-demand

**GAS COST BREAKDOWN** (from Project 01 & 06 knowledge):

**Deposit**:
- Share calculation: ~100 gas (MUL + DIV)
- 2 SSTOREs (totalShares, totalAssets): ~10,000 gas (warm)
- 1 SSTORE (user shares): ~5,000 gas (warm)
- ERC20 transfer: ~50,000 gas
- Total: ~65,100 gas

**Withdraw**:
- Share calculation: ~100 gas
- 2 SSTOREs: ~10,000 gas
- 1 SSTORE (user shares to zero): ~5,000 gas (may refund!)
- ERC20 transfer: ~50,000 gas
- Total: ~65,100 gas

**REAL-WORLD ANALOGY**: 
Like buying shares of a mutual fund:
- **Deposit** = Buying fund shares
- **Yield** = Fund performance increases NAV (Net Asset Value)
- **Withdraw** = Selling shares at current NAV
- **Profit** = Difference between buy and sell NAV

## Core Concepts

### 1. Shares vs Assets

| Concept | Definition | Example |
|---------|------------|---------|
| **Assets** | The underlying token (USDC, DAI, etc.) | 1000 USDC |
| **Shares** | Vault tokens representing ownership | 950 vault shares |
| **Exchange Rate** | Assets per share | 1.053 USDC per share |

### 2. Share Calculation Math

The fundamental formulas:

```solidity
// DEPOSIT: Converting assets → shares
shares = (assets * totalShares) / totalAssets

// WITHDRAW: Converting shares → assets
assets = (shares * totalAssets) / totalShares

// FIRST DEPOSIT: When totalShares == 0
shares = assets  // 1:1 ratio for bootstrap
```

**Example Timeline:**

| Event | Total Assets | Total Shares | Exchange Rate |
|-------|--------------|--------------|---------------|
| Initial | 0 | 0 | N/A |
| Alice deposits 1000 | 1000 | 1000 | 1.0 |
| Vault earns 100 | 1100 | 1000 | 1.1 |
| Bob deposits 1100 | 2200 | 2000 | 1.1 |
| Carol deposits 550 | 2750 | 2500 | 1.1 |

### 3. Preview Functions

Preview functions let users **simulate** transactions before executing:

```solidity
function previewDeposit(uint256 assets) public view returns (uint256 shares) {
    // Shows how many shares you'll get for depositing assets
    return convertToShares(assets);
}

function previewWithdraw(uint256 assets) public view returns (uint256 shares) {
    // Shows how many shares you'll burn to withdraw assets
    return convertToSharesRoundUp(assets);  // Round up to protect vault
}
```

**Why preview functions matter:**

- **Transparency**: Users know exactly what they'll get
- **Slippage calculation**: Users can set minimum acceptable amounts
- **Front-end integration**: UIs can show accurate estimates
- **Slippage protection**: Users can revert if conditions change

### 4. Slippage Protection

Slippage occurs when the exchange rate changes between simulation and execution.

**The Attack:**

```solidity
// 1. Alice previews: deposit 1000 assets → expect 100 shares
uint256 expectedShares = vault.previewDeposit(1000);  // Returns 100

// 2. MEV bot front-runs Alice with large deposit
//    This changes the exchange rate!

// 3. Alice's transaction executes
uint256 actualShares = vault.deposit(1000);  // Returns only 90 shares!

// Alice lost value due to front-running!
```

**The Solution:**

```solidity
function depositWithSlippage(
    uint256 assets,
    uint256 minShares  // Minimum shares Alice will accept
) external returns (uint256 shares) {
    shares = _deposit(assets);
    require(shares >= minShares, "Slippage too high");
    return shares;
}

// Usage:
uint256 expectedShares = vault.previewDeposit(1000);
uint256 minShares = expectedShares * 99 / 100;  // Accept 1% slippage
vault.depositWithSlippage(1000, minShares);
```

### 5. Rounding Direction

**Critical Rule: Always favor the vault (protocol), never the user**

Why? An attacker could exploit favorable rounding to drain the vault.

```solidity
// DEPOSIT/MINT: Round DOWN shares given to user
// User gives exact assets, gets slightly fewer shares
shares = (assets * totalShares) / totalAssets;  // Truncates

// WITHDRAW: Round UP shares taken from user
// User wants exact assets, we burn slightly more shares
shares = (assets * totalShares + totalAssets - 1) / totalAssets;  // Rounds up
```

**Example:**

```solidity
// Vault has 1000 assets, 999 shares (1.001 ratio)
// User deposits 100 assets

// shares = (100 * 999) / 1000 = 99.9 → truncates to 99 shares
// User gives 100 assets, gets 99 shares (vault keeps 0.9 share worth)

// User withdraws 100 assets
// shares = (100 * 999 + 1000 - 1) / 1000 = 100.899 → rounds up to 101
// User gets 100 assets, burns 101 shares (vault gains 1 share worth)
```

The vault accumulates tiny amounts over time, protecting against attacks.

## Common Attack Vectors

### 1. Inflation Attack

**The Attack:**

```solidity
// Step 1: Attacker is first depositor
vault.deposit(1 wei, attacker);  // Gets 1 share

// Step 2: Attacker donates 1000 ether directly to vault
token.transfer(address(vault), 1000 ether);

// Step 3: Now totalAssets = 1000 ether + 1 wei, totalShares = 1
//         Exchange rate is ~1000 ether per share!

// Step 4: Victim tries to deposit 999 ether
shares = (999 ether * 1) / 1000 ether = 0.999 → 0 shares!
// Victim loses everything due to rounding down!
```

**Defense #1: Minimum Deposit**

```solidity
function deposit(uint256 assets) external returns (uint256 shares) {
    shares = convertToShares(assets);
    require(shares > 0, "Zero shares");
    require(shares >= MIN_SHARES, "Below minimum");
    // ...
}
```

**Defense #2: Virtual Shares (Advanced)**

```solidity
// Add virtual offset to make inflation attack expensive
uint256 constant VIRTUAL_SHARES = 1e8;
uint256 constant VIRTUAL_ASSETS = 1;

function convertToShares(uint256 assets) public view returns (uint256) {
    return (assets * (totalShares + VIRTUAL_SHARES))
           / (totalAssets + VIRTUAL_ASSETS);
}
```

**Defense #3: Mint Dead Shares on First Deposit**

```solidity
if (totalShares == 0) {
    // Burn first 1000 shares to address(0)
    _mint(address(0), 1000);
    shares = assets - 1000;
}
```

### 2. Donation Attack

**The Attack:**

```solidity
// Attacker donates tokens directly to vault
token.transfer(address(vault), 1000 ether);

// If vault uses balanceOf for totalAssets:
function totalAssets() public view returns (uint256) {
    return token.balanceOf(address(this));  // WRONG!
}

// The accounting breaks - shares become worth more, but who gets the profit?
```

**Defense: Internal Accounting**

```solidity
uint256 private _totalAssets;  // Track deposits internally

function deposit(uint256 assets) external {
    _totalAssets += assets;  // Increment internal counter
    token.transferFrom(msg.sender, address(this), assets);
}

function totalAssets() public view returns (uint256) {
    return _totalAssets;  // Use internal accounting, not balanceOf
}
```

### 3. Front-Running

**The Attack:**

```solidity
// 1. Alice submits: deposit 1000 assets
// 2. MEV bot sees Alice's transaction in mempool
// 3. Bot front-runs with large deposit, changing exchange rate
// 4. Alice gets fewer shares than expected
```

**Defense: Slippage Protection**

```solidity
function depositWithSlippage(uint256 assets, uint256 minShares) external {
    uint256 shares = _deposit(assets);
    require(shares >= minShares, "Slippage exceeded");
}
```

## Introduction to ERC-4626

This project teaches the **core concepts** of ERC-4626, the Tokenized Vault Standard:

| This Project | ERC-4626 | Notes |
|--------------|----------|-------|
| `deposit()` | `deposit(assets, receiver)` | Mint shares for assets |
| `withdraw()` | `withdraw(assets, receiver, owner)` | Burn shares for assets |
| N/A | `mint(shares, receiver)` | Deposit assets for exact shares |
| N/A | `redeem(shares, receiver, owner)` | Burn exact shares for assets |
| `previewDeposit()` | `previewDeposit(assets)` | Simulate deposit |
| `previewWithdraw()` | `previewWithdraw(assets)` | Simulate withdraw |
| `convertToShares()` | `convertToShares(assets)` | Assets → shares conversion |
| `convertToAssets()` | `convertToAssets(shares)` | Shares → assets conversion |

**ERC-4626 also includes:**

- `maxDeposit(receiver)` - Maximum assets user can deposit
- `maxWithdraw(owner)` - Maximum assets user can withdraw
- `maxMint(receiver)` - Maximum shares user can mint
- `maxRedeem(owner)` - Maximum shares user can redeem
- Standard events: `Deposit`, `Withdraw`

After mastering this project, ERC-4626 will be much easier to understand!

## What You'll Build

A simplified deposit/withdraw vault with:

1. **Share-based accounting** - Track proportional ownership
2. **Deposit function** - Convert assets to shares
3. **Withdraw function** - Convert shares to assets
4. **Preview functions** - Simulate transactions
5. **Slippage protection** - Prevent front-running losses
6. **Proper rounding** - Always favor the vault
7. **Attack resistance** - Handle inflation and donation attacks

## Tasks

### Task 1: Implement the Skeleton Contract

Open `src/Project20.sol` and implement:

1. Share calculation math in `convertToShares()` and `convertToAssets()`
2. Deposit function with share minting
3. Withdraw function with share burning
4. Preview functions for simulation
5. Slippage protection variants

### Task 2: Run the Tests

```bash
cd 20-deposit-withdraw

# Run all tests
forge test -vvv

# Run specific test categories
forge test --match-test test_Deposit
forge test --match-test test_Withdraw
forge test --match-test test_Preview
forge test --match-test test_Slippage

# Gas report
forge test --gas-report
```

### Task 3: Study the Solution

Compare your implementation with `src/solution/DepositWithdrawSolution.sol`:

**Solution File Features**:
- **CS Concepts**: Explains proportional math, share-based accounting, precision handling
- **Connections to Project 11**: ERC-4626 uses this exact pattern for vault operations
- **Connections to Project 06**: Running totals pattern for efficient balance tracking
- **Connections to Project 02**: CEI pattern for secure deposits/withdrawals
- **Real-World Context**: Foundation for all yield vaults (Yearn, Aave, Compound)

- Understand the share conversion math
- See how rounding favors the vault
- Learn slippage protection patterns
- Study attack mitigations

### Task 4: Experiment with Edge Cases

```bash
# Run fuzz tests
forge test --match-test testFuzz

# Run with high verbosity to see all traces
forge test -vvvv

# Test specific scenarios
forge test --match-test test_InflationAttack
forge test --match-test test_MultipleUsers
```

## Security Checklist

- [ ] Share calculations round in favor of vault
- [ ] Zero-share deposits are rejected
- [ ] Preview functions match actual behavior
- [ ] Slippage protection is available
- [ ] Internal accounting prevents donation attacks
- [ ] First depositor can't manipulate share price
- [ ] Reentrancy guards on state-changing functions
- [ ] Events emitted for all deposits/withdraws

## Real-World Applications

### Yield Vaults (Yearn, Beefy)

```solidity
// Users deposit USDC, get yUSDC shares
vault.deposit(1000e6);  // Deposit 1000 USDC

// Vault deploys USDC to yield strategies
// Time passes, yield accrues...

// User redeems shares for original deposit + yield
vault.withdraw(shares);  // Gets 1050 USDC (5% yield)
```

### Lending Protocols (Aave, Compound)

```solidity
// Deposit USDC, get aUSDC (interest-bearing token)
aavePool.deposit(1000e6);  // Get aUSDC shares

// aUSDC grows in value as interest accrues
// 1 aUSDC might represent 1.05 USDC after time

// Withdraw to get USDC back with interest
aavePool.withdraw(aUsdcBalance);
```

### Liquidity Mining

```solidity
// Stake LP tokens, get vault shares
vault.deposit(uniswapLP);

// Vault auto-compounds rewards
// Shares increase in value as rewards are claimed and re-invested

// Withdraw shares for original LP + accumulated rewards
vault.withdraw(shares);
```

## Gas Optimization Tips

1. **Use internal accounting** - Cheaper than checking `balanceOf` repeatedly
2. **Cache storage variables** - Store `totalShares` in memory during calculations
3. **Avoid redundant checks** - Don't check `shares > 0` twice
4. **Use immutable** - Mark `token` as `immutable` for cheaper reads
5. **Batch operations** - Allow depositing for multiple users in one transaction

## Testing Checklist

Your tests should cover:

- [ ] First deposit (bootstrap ratio)
- [ ] Subsequent deposits with existing shares
- [ ] Withdrawals with correct share burning
- [ ] Preview functions match actual results
- [ ] Slippage protection reverts when threshold exceeded
- [ ] Multiple users depositing and withdrawing
- [ ] Edge cases: minimum amounts, maximum amounts
- [ ] Fuzz tests for deposit/withdraw invariants
- [ ] Inflation attack mitigation
- [ ] Donation attack doesn't break accounting

## Pro Tips

1. **Preview before deposit** - Always show users what they'll get
2. **Set reasonable slippage** - 0.5-1% is typical for DeFi
3. **Round in vault's favor** - Small fees accumulate to protect against attacks
4. **Emit events** - Off-chain indexers need deposit/withdraw events
5. **Consider minimums** - Prevent dust amounts that cost more gas than value
6. **Use safe math** - Solidity 0.8+ has built-in overflow checks
7. **Test with different decimals** - Not all tokens use 18 decimals

## Common Mistakes

### Mistake 1: Wrong Rounding

```solidity
// BAD: Rounding in user's favor
shares = (assets * totalShares + totalAssets - 1) / totalAssets;  // Rounds up
```

```solidity
// GOOD: Rounding in vault's favor
shares = (assets * totalShares) / totalAssets;  // Rounds down
```

### Mistake 2: Using balanceOf for Accounting

```solidity
// BAD: Direct donations break accounting
function totalAssets() public view returns (uint256) {
    return token.balanceOf(address(this));
}
```

```solidity
// GOOD: Track deposits internally
uint256 private _totalAssets;
function totalAssets() public view returns (uint256) {
    return _totalAssets;
}
```

### Mistake 3: No Slippage Protection

```solidity
// BAD: User has no control over outcome
function deposit(uint256 assets) external returns (uint256 shares) {
    shares = convertToShares(assets);
    // User might get way fewer shares than expected!
}
```

```solidity
// GOOD: User can specify minimum acceptable shares
function deposit(uint256 assets, uint256 minShares) external returns (uint256 shares) {
    shares = convertToShares(assets);
    require(shares >= minShares, "Slippage too high");
}
```

## Next Steps

After completing this project:

1. Study **ERC-4626 Tokenized Vault Standard** (Project 11)
2. Learn about **yield strategies** (Aave, Compound, Curve)
3. Implement **fee mechanisms** (performance fees, management fees)
4. Add **access controls** (deposit caps, whitelists)
5. Build **multi-strategy vaults** (diversified yield)

## Further Reading

- [EIP-4626: Tokenized Vault Standard](https://eips.ethereum.org/EIPS/eip-4626)
- [OpenZeppelin ERC4626 Documentation](https://docs.openzeppelin.com/contracts/4.x/erc4626)
- [Yearn Vaults Explained](https://docs.yearn.finance/getting-started/products/yvaults/overview)
- [Understanding Share-Based Accounting](https://ethereum.org/en/developers/docs/standards/tokens/erc-4626/)
- [Slippage Protection Best Practices](https://www.paradigm.xyz/2021/04/understanding-automated-market-makers-part-1-price-impact)

## Completion Checklist

- [ ] Implemented share-based deposit/withdraw
- [ ] All tests pass
- [ ] Understand share conversion math
- [ ] Can explain rounding directions
- [ ] Know how to prevent inflation attack
- [ ] Implemented slippage protection
- [ ] Understand preview function importance
- [ ] Ready to learn ERC-4626

---

**Ready to build?** Start with `src/Project20.sol` and complete the TODOs!
