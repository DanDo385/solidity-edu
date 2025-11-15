# ERC-4626 Vault Mathematics Reference

## Complete Guide to Tokenized Vault Mathematics

A comprehensive reference for understanding, implementing, and debugging the mathematical foundations of ERC-4626 tokenized vaults.

---

## Table of Contents

1. [Fundamental Concepts](#fundamental-concepts)
2. [Core Share Calculation Formulas](#core-share-calculation-formulas)
3. [Asset-to-Shares Conversion](#asset-to-shares-conversion)
4. [Rounding Modes](#rounding-modes)
5. [Function Specifications](#function-specifications)
6. [Deposit vs Mint Differences](#deposit-vs-mint-differences)
7. [Withdraw vs Redeem Differences](#withdraw-vs-redeem-differences)
8. [Inflation Attack Vectors](#inflation-attack-vectors)
9. [Edge Cases and Singularities](#edge-cases-and-singularities)
10. [Mathematical Proofs](#mathematical-proofs)
11. [Common Implementation Mistakes](#common-implementation-mistakes)
12. [Flow Diagrams](#flow-diagrams)
13. [Example Calculations](#example-calculations)
14. [Implementation Checklist](#implementation-checklist)

---

## Fundamental Concepts

### The Share System

ERC-4626 vaults operate on a **two-token system**:

1. **Underlying Asset (ERC-20)**: The actual asset deposited by users (e.g., USDC, DAI, WETH)
2. **Vault Shares (ERC-20)**: Proportional claims on the underlying assets

### The Core Relationship

```
Total Assets
─────────────── = Share Price
Total Shares
```

This ratio determines how much underlying asset each share represents.

### Key Variables

```solidity
totalAssets()   // Total amount of underlying asset in vault
totalSupply()   // Total number of shares issued
balanceOf(user) // Number of shares owned by user
```

### The Exchange Rate

```
Exchange Rate = Total Assets / Total Shares
```

In scaled mathematics (with decimals):

```
Exchange Rate = (Total Assets × 10^18) / Total Shares
```

---

## Core Share Calculation Formulas

### Formula 1: Assets to Shares

**Converting underlying assets to vault shares:**

```
shares = assets × totalSupply() / totalAssets()
```

Or with scaling factor `E`:

```
shares = (assets × totalSupply() × E) / (totalAssets() × E)
```

**Intuition**: If you have 100 assets and there are 1000 shares worth 100 assets total, your 100 assets = 1000 shares.

### Formula 2: Shares to Assets

**Converting vault shares to underlying assets:**

```
assets = shares × totalAssets() / totalSupply()
```

**Intuition**: If each share is worth 0.1 assets, then 1000 shares = 100 assets.

### Formula 3: Shares Created (After Deposit)

**When depositing `depositAmount` assets:**

```
sharesReceived = depositAmount × totalSupply() / totalAssets()
```

If totalAssets = 0 (empty vault):

```
sharesReceived = depositAmount × 10^decimalPlaces
```

The decimal places ensure 1-to-1 ratio at initialization.

### Formula 4: Assets Withdrawn (After Redeem)

**When redeeming `shareAmount` shares:**

```
assetsReceived = shareAmount × totalAssets() / totalSupply()
```

---

## Asset-to-Shares Conversion

### The Conversion Mechanism

```
┌─────────────────────┐
│  User has Assets    │
│      (e.g., 100)    │
└──────────┬──────────┘
           │
           │ Convert using formula:
           │ shares = assets × totalSupply / totalAssets
           │
           ▼
┌─────────────────────┐
│   User has Shares   │
│     (e.g., 1000)    │
└─────────────────────┘
```

### Step-by-Step Conversion

**Scenario**: User deposits 50 USDC into a vault with:
- totalAssets = 1000 USDC
- totalSupply = 500 shares

**Calculation**:
```
shares = 50 × 500 / 1000
shares = 25000 / 1000
shares = 25 shares
```

The user receives **25 shares** for their 50 USDC deposit.

### Reverse Conversion (Shares to Assets)

**Scenario**: User redeems 25 shares from the same vault

**Calculation**:
```
assets = 25 × 1000 / 500
assets = 25000 / 500
assets = 50 USDC
```

The user receives **50 USDC** back.

---

## Rounding Modes

### Why Rounding Matters

In vault mathematics, every calculation produces potential fractional tokens. Since blockchains use integers, we must round decisively.

**Rounding direction is critical for security and fairness:**

- **Round DOWN**: Protects the vault; users receive less
- **Round UP**: Protects users; vault receives less

### Rule of Thumb

```
Favor the vault (round against user) in calculations that:
- Determine how much the user RECEIVES
- Represent vault OUTFLOWS

Favor the user (round with user) in calculations that:
- Determine how much the user PAYS
- Represent vault INFLOWS
```

### Implementation in Solidity

**Round DOWN (Integer Division)**:
```solidity
// In Solidity, integer division automatically rounds down
shares = assets * totalSupply / totalAssets;  // Rounds DOWN
```

**Round UP**:
```solidity
// Manually round up using ceiling division
shares = (assets * totalSupply + totalAssets - 1) / totalAssets;

// Or more clearly:
shares = (assets * totalSupply) / totalAssets;
if ((assets * totalSupply) % totalAssets != 0) {
    shares += 1;
}
```

### Rounding in ERC-4626 Functions

| Function | Conversion | Direction | Why |
|----------|-----------|-----------|-----|
| `deposit()` | Assets → Shares | DOWN | User receives less when depositing (protects vault) |
| `mint()` | Shares → Assets | UP | Vault receives more assets when minting shares (protects vault) |
| `withdraw()` | Assets → Shares | UP | Vault receives more shares when withdrawing (user pays more) |
| `redeem()` | Shares → Assets | DOWN | User receives less assets when redeeming (protects vault) |

---

## Function Specifications

### 1. `deposit(uint256 assets, address receiver)`

**Purpose**: User specifies amount of assets to deposit

**Returns**: Shares received

**Formula**:
```
sharesOut = assets × totalSupply / totalAssets
```

**Rounding**: DOWN

**Code Template**:
```solidity
function deposit(uint256 assets, address receiver)
    external
    returns (uint256 shares)
{
    require(assets > 0, "Zero amount");
    require(receiver != address(0), "Zero address");

    // Calculate shares (rounds down)
    shares = convertToShares(assets);

    // Transfer assets from user to vault
    asset.transferFrom(msg.sender, address(this), assets);

    // Mint shares to receiver
    _mint(receiver, shares);

    emit Deposit(msg.sender, receiver, assets, shares);
}
```

**Special Case - First Deposit**:
```
If totalAssets == 0:
    shares = assets × 10^decimalPlaces
```

### 2. `mint(uint256 shares, address receiver)`

**Purpose**: User specifies number of shares they want

**Returns**: Assets required

**Formula**:
```
assetsIn = shares × totalAssets / totalSupply
```

**Rounding**: UP

**Code Template**:
```solidity
function mint(uint256 shares, address receiver)
    external
    returns (uint256 assets)
{
    require(shares > 0, "Zero amount");
    require(receiver != address(0), "Zero address");

    // Calculate assets needed (rounds up)
    assets = convertToAssets(shares);
    if ((shares * totalAssets) % totalSupply != 0) {
        assets += 1;
    }

    // Transfer assets from user to vault
    asset.transferFrom(msg.sender, address(this), assets);

    // Mint exact shares to receiver
    _mint(receiver, shares);

    emit Deposit(msg.sender, receiver, assets, shares);
}
```

### 3. `withdraw(uint256 assets, address receiver, address owner)`

**Purpose**: User specifies amount of assets to withdraw

**Returns**: Shares burned

**Formula**:
```
sharesBurned = assets × totalSupply / totalAssets
```

**Rounding**: UP (user pays more)

**Code Template**:
```solidity
function withdraw(
    uint256 assets,
    address receiver,
    address owner
) external returns (uint256 shares) {
    require(assets > 0, "Zero amount");
    require(receiver != address(0), "Zero address");

    // Calculate shares needed (rounds up, user pays more)
    shares = convertToShares(assets);
    if ((assets * totalSupply) % totalAssets != 0) {
        shares += 1;
    }

    // Burn shares from owner
    if (msg.sender != owner) {
        _approve(owner, msg.sender, allowance[owner][msg.sender] - shares);
    }
    _burn(owner, shares);

    // Transfer assets to receiver
    asset.transfer(receiver, assets);

    emit Withdraw(msg.sender, receiver, owner, assets, shares);
}
```

### 4. `redeem(uint256 shares, address receiver, address owner)`

**Purpose**: User specifies number of shares to redeem

**Returns**: Assets received

**Formula**:
```
assetsOut = shares × totalAssets / totalSupply
```

**Rounding**: DOWN (user receives less)

**Code Template**:
```solidity
function redeem(
    uint256 shares,
    address receiver,
    address owner
) external returns (uint256 assets) {
    require(shares > 0, "Zero amount");
    require(receiver != address(0), "Zero address");

    // Calculate assets (rounds down)
    assets = convertToAssets(shares);

    // Burn shares from owner
    if (msg.sender != owner) {
        _approve(owner, msg.sender, allowance[owner][msg.sender] - shares);
    }
    _burn(owner, shares);

    // Transfer assets to receiver
    asset.transfer(receiver, assets);

    emit Withdraw(msg.sender, receiver, owner, assets, shares);
}
```

### 5. Preview Functions

**Purpose**: Read-only calculations of what operations would return

```solidity
// How many shares for assets?
function previewDeposit(uint256 assets)
    external
    view
    returns (uint256 shares)
{
    return convertToShares(assets);
}

// How many assets for shares?
function previewMint(uint256 shares)
    external
    view
    returns (uint256 assets)
{
    assets = (shares * totalAssets) / totalSupply;
    if ((shares * totalAssets) % totalSupply != 0) {
        assets += 1;
    }
    return assets;
}

// How many shares to burn for assets?
function previewWithdraw(uint256 assets)
    external
    view
    returns (uint256 shares)
{
    shares = (assets * totalSupply) / totalAssets;
    if ((assets * totalSupply) % totalAssets != 0) {
        shares += 1;
    }
    return shares;
}

// How many assets for shares?
function previewRedeem(uint256 shares)
    external
    view
    returns (uint256 assets)
{
    return convertToAssets(shares);
}
```

**Critical Requirement**: Preview functions MUST return the EXACT same result as their corresponding state-changing functions, including rounding direction.

---

## Deposit vs Mint Differences

### The Key Distinction

Both `deposit()` and `mint()` add assets to the vault and give the user shares, but they differ in what the user specifies:

| Aspect | `deposit()` | `mint()` |
|--------|-----------|---------|
| **User specifies** | Assets amount | Shares amount |
| **Vault returns** | Shares received | Assets required |
| **User certainty** | Knows exactly how much to pay | Knows exactly how many shares they get |
| **Rounding** | DOWN (user gets less) | UP (user pays more) |
| **Use case** | "I want to deposit 100 USDC" | "I want exactly 500 shares" |

### Mathematical Relationship

```
If user wants to receive X shares:
  - With deposit():  deposit(convertToAssets(X)) → X shares (approximately)
  - With mint():     mint(X) → exactly X shares

If user wants to spend Y assets:
  - With deposit():  deposit(Y) → shares (rounded down)
  - With mint():     mint(convertToShares(Y)) → shares (exact)
```

### Example: The Rounding Impact

**Scenario**: User wants to interact with a vault where:
- totalAssets = 1000
- totalSupply = 1000 (1:1 ratio)
- User has 333 assets

**Using `deposit(333)`**:
```
shares = 333 × 1000 / 1000 = 333 shares (exactly)
```

**Using `mint(333)`**:
```
assets = 333 × 1000 / 1000 = 333 assets (exactly)
```

Now consider a vault with fractional shares:

**Vault state**:
- totalAssets = 1000
- totalSupply = 999 (slightly more valuable per share)

**Using `deposit(333)`**:
```
shares = 333 × 999 / 1000 = 332.667 → 332 shares (rounds DOWN)
User loses 0.667 shares due to rounding
```

**Using `mint(333)`**:
```
assets = 333 × 1000 / 999 = 333.333 → 334 assets (rounds UP)
User pays 1 extra asset for guaranteed 333 shares
```

### When to Use Which

**Use `deposit()` when**:
- User has exact amount of assets
- Price impact of rounding is acceptable
- Simplicity is preferred

**Use `mint()` when**:
- User wants exact number of shares
- Slippage from rounding is unacceptable
- Shares represent something meaningful (governance power, etc.)

---

## Withdraw vs Redeem Differences

### The Key Distinction

Both `withdraw()` and `redeem()` remove assets from the vault and burn the user's shares, but they differ in what the user specifies:

| Aspect | `withdraw()` | `redeem()` |
|--------|------------|-----------|
| **User specifies** | Assets amount | Shares amount |
| **Vault returns** | Shares burned | Assets received |
| **User certainty** | Knows exactly how much they get | Knows exactly how many shares burn |
| **Rounding** | UP (user pays more) | DOWN (user gets less) |
| **Use case** | "I want 100 USDC back" | "I want to redeem all my shares" |

### Mathematical Relationship

```
If user wants to receive Y assets:
  - With withdraw():  withdraw(Y) → shares burned
  - With redeem():    redeem(convertToShares(Y)) → approximately Y assets

If user wants to burn X shares:
  - With withdraw():  withdraw(convertToAssets(X)) → approximately X shares
  - With redeem():    redeem(X) → exactly X shares
```

### Example: The Rounding Impact

**Scenario**: Same vault as before:
- totalAssets = 1000
- totalSupply = 999

**User wants to withdraw 500 assets**:

Using `withdraw(500)`:
```
shares = 500 × 999 / 1000 = 499.5 → 500 shares (rounds UP)
User must burn 500 shares to get 500 assets
Vault extracts 1 extra share as slippage
```

Using `redeem(500)`:
```
assets = 500 × 1000 / 999 = 500.500 → 500 assets (rounds DOWN)
User redeems 500 shares, gets 500 assets
User loses 0.500 assets to rounding
```

### When to Use Which

**Use `withdraw()` when**:
- User wants specific amount of assets
- Exact asset withdrawal is critical
- User accepts share slippage

**Use `redeem()` when**:
- User wants to redeem all shares
- Exact number of shares burned is critical
- Cleanup operations (exit vault completely)

---

## Inflation Attack Vectors

### What is an Inflation Attack?

An inflation attack in ERC-4626 occurs when an early vault depositor inflates the share price, causing subsequent depositors to receive very few or zero shares.

### Attack Mechanism

**Vulnerable Code**:
```solidity
function deposit(uint256 assets) external returns (uint256 shares) {
    // VULNERABLE: No protection against first deposit manipulation
    shares = assets * totalSupply / totalAssets;

    // ... mint shares ...
}
```

**Attack Steps**:

1. **Step 1**: Attacker deposits 1 wei of assets
   ```
   shares = 1 × 10^18 / 1 = 10^18 shares (1:1 ratio initialized)
   ```

2. **Step 2**: Attacker transfers large amount of assets directly to vault
   ```
   Vault now has: 1 + 1000000 = 1000001 wei assets
   totalSupply: 10^18 shares
   Price per share: 1000001 / 10^18 ≈ 10^-12
   ```

3. **Step 3**: Innocent user deposits 1000000 wei
   ```
   shares = 1000000 × 10^18 / 1000001 ≈ 999999000000
   User receives ~999999 shares instead of ~1000000
   Attacker's 1 original share now worth ~1000001 wei
   ```

### Attack Visualization

```
BEFORE ATTACK:
┌──────────────────────┐
│  Empty Vault         │
│  totalAssets = 0     │
│  totalSupply = 0     │
└──────────────────────┘

STEP 1 - Attacker deposits 1 wei:
┌──────────────────────┐
│  Vault               │
│  totalAssets = 1     │
│  totalSupply = 10^18 │
│  Price/share = 10^-18│
└──────────────────────┘

STEP 2 - Attacker transfers 1M wei directly:
┌──────────────────────┐
│  Vault               │
│  totalAssets = 1M+1  │
│  totalSupply = 10^18 │
│  Price/share = 1M    │
└──────────────────────┘

STEP 3 - Innocent user deposits 1M:
Calculates: 1M × 10^18 / (1M+1) ≈ 999999
Receives only 999999 shares for 1M assets!
```

### Mitigation Strategy 1: Minimum Initial Deposit

```solidity
uint256 private constant INITIAL_CHAIN_ID = 1;
bytes32 private constant INITIAL_DOMAIN_SEPARATOR = 0x...;

function deposit(uint256 assets, address receiver)
    external
    returns (uint256 shares)
{
    // PROTECTION: Enforce minimum initial deposit
    if (totalSupply == 0) {
        require(assets >= 10**6, "Initial deposit too small");
    }

    shares = convertToShares(assets);
    require(shares != 0, "Deposit too small");

    // ... rest of function ...
}
```

### Mitigation Strategy 2: Virtual Offset

```solidity
uint256 internal constant VIRTUAL_OFFSET = 10^6;

function convertToShares(uint256 assets)
    internal
    view
    returns (uint256 shares)
{
    // Add virtual offset to both numerator components
    uint256 totalAssetsPlusBias = totalAssets() + VIRTUAL_OFFSET;
    uint256 totalSupplyPlusBias = totalSupply() + VIRTUAL_OFFSET;

    shares = assets * totalSupplyPlusBias / totalAssetsPlusBias;
}

function convertToAssets(uint256 shares)
    internal
    view
    returns (uint256 assets)
{
    // Same bias applied
    uint256 totalAssetsPlusBias = totalAssets() + VIRTUAL_OFFSET;
    uint256 totalSupplyPlusBias = totalSupply() + VIRTUAL_OFFSET;

    assets = shares * totalAssetsPlusBias / totalSupplyPlusBias;
}
```

**How Virtual Offset Protects**:

With 10^6 offset:
```
Before: 1M assets / 0 supply → undefined
After: (1M + 10^6) / (0 + 10^6) ≈ 1.001 (shares worth ~1 asset)

Attacker's profit = ~1.001 - 1 = 0.001 assets (negligible)
Attack cost (1M transfer) >>> attack profit
```

### Mitigation Strategy 3: Dead Shares

```solidity
function initialize() external {
    require(totalSupply == 0, "Already initialized");

    // Mint and burn dead shares to prevent first deposit attack
    uint256 deadShares = 10**6;
    _mint(address(1), deadShares); // Send to unrecoverable address

    // This ensures totalSupply > 0, preventing share price inflation
}
```

### Comparison of Mitigations

| Strategy | Cost | Complexity | Effectiveness |
|----------|------|-----------|----------------|
| Minimum deposit | Medium | Low | Medium (users can still bypass) |
| Virtual offset | None | Low | High (automatic) |
| Dead shares | Low | Low | High (automatic) |

**Recommended**: Combine virtual offset + minimum deposit requirement for maximum safety.

---

## Edge Cases and Singularities

### Case 1: Empty Vault (totalAssets = 0, totalSupply = 0)

**The Problem**: Division by zero

```
shares = assets × 0 / 0  // Undefined!
```

**Solution**: Define special behavior for first deposit

```solidity
function convertToShares(uint256 assets) internal view returns (uint256) {
    uint256 supply = totalSupply();

    if (supply == 0) {
        // First deposit: 1:1 ratio at decimal precision
        return assets * 10**decimals() / 10**asset.decimals();
    }

    return assets * supply / totalAssets();
}
```

**Example**:
- User deposits 100 USDC (6 decimals)
- Shares have 18 decimals
- Shares received: 100 × 10^18 / 10^6 = 10^14 shares

### Case 2: Zero Assets Remaining

**The Problem**: What happens if vault empties?

```
If totalAssets → 0:
  assets = shares × 0 / totalSupply = 0

All remaining shares become worthless!
```

**This is mathematically correct but operationally problematic:**

```solidity
function redeem(uint256 shares, address receiver, address owner)
    external
    returns (uint256 assets)
{
    assets = convertToAssets(shares);

    // This is acceptable - shares do become worthless
    require(assets > 0 || totalAssets() == 0, "Precision loss");

    // ... burn shares and transfer assets ...
}
```

### Case 3: Rounding to Zero

**The Problem**: Fractional amounts round to zero

```
User deposits 0.5 assets in vault where:
totalSupply = 1000000
totalAssets = 1000000

shares = 0.5 × 1000000 / 1000000 = 0.5 shares
Rounds DOWN to 0 shares!
```

**Solution**: Require minimum meaningful amount

```solidity
function deposit(uint256 assets, address receiver)
    external
    returns (uint256 shares)
{
    require(assets > 0, "Zero amount");

    shares = convertToShares(assets);
    require(shares > 0, "Deposit amount too small for this vault");

    // ... rest of function ...
}
```

### Case 4: Precision Loss on Extreme Ratios

**The Problem**: Very large or very small ratios cause precision loss

```solidity
// Scenario: totalAssets = 10^24, totalSupply = 1
// User deposits 10^6 assets

shares = 10^6 × 1 / 10^24 = 10^-18 shares
Rounds DOWN to 0 shares!
```

**Solution**: Use higher precision arithmetic

```solidity
function convertToShares(uint256 assets) internal view returns (uint256) {
    uint256 supply = totalSupply();
    uint256 total = totalAssets();

    if (supply == 0) return assets * 10**DECIMALS / 10**asset.decimals();

    // Scale up before division to avoid precision loss
    return (assets * supply * 10**18) / (total * 10**18);
}
```

### Case 5: Very Large Share Supply

**The Problem**: Multiplication overflow

```solidity
// If totalSupply ≈ 10^77 and assets ≈ 10^20
shares = assets * totalSupply / totalAssets
       = 10^20 × 10^77 / ...
       = 10^97  // OVERFLOW!
```

**Solution**: Carefully order operations

```solidity
function convertToShares(uint256 assets) internal view returns (uint256) {
    uint256 supply = totalSupply();
    uint256 total = totalAssets();

    // Divide first to avoid overflow
    if (assets < total) {
        return assets * supply / total;
    } else {
        // assets >= total, so divide assets first
        return (assets / total) * supply + (assets % total) * supply / total;
    }
}
```

---

## Mathematical Proofs

### Proof 1: Conservation of Value

**Claim**: The total value of shares always equals total assets

**Proof**:

Let's define:
- `a` = total assets
- `s` = total shares issued
- `p` = price per share = a / s

Each share is worth `p` assets.

Total value of all shares = `s × p = s × (a / s) = a`

Therefore: **Total value of shares ≡ Total assets** ✓

### Proof 2: Linear Scaling

**Claim**: If you double assets, the share price increases proportionally

**Proof**:

Original state:
- totalAssets = a
- totalSupply = s
- Price per share = a / s

If total assets double (vault gains profit):
- totalAssets = 2a
- totalSupply = s (shares unchanged)
- New price per share = 2a / s = 2 × (a / s)

Price per share **exactly doubles** ✓

This proves profit is distributed proportionally to all share holders.

### Proof 3: First Depositor Advantage is Unbounded

**Claim**: First depositor can extract arbitrary profit with standard formulas

**Proof**:

Let `d` = first deposit amount

Step 1: Deposit `d` assets
```
shares = d × 0 / 0 (undefined, we set to d)
```

Step 2: Transfer `K × d` assets directly to vault (where K >> 1)
```
totalAssets = d + K×d = d(1+K)
totalSupply = d
Price per share = d(1+K) / d = (1+K)
```

First depositor's wealth: `d × (1+K)` assets per share owned

This can be made arbitrarily large by choosing K arbitrarily large. ✓

**This proves the inflation attack works and is why mitigations are necessary.**

### Proof 4: Rounding Consistency

**Claim**: Using opposite rounding directions for inflow and outflow prevents extraction of value

**Proof**:

For a user performing deposit then immediate redeem:

Deposit:
```
shares_out = assets × supply_before / assets_before [ROUNDED DOWN]
```

Redeem:
```
assets_out = shares_out × assets_before / supply_before [ROUNDED DOWN]
```

In the best case for the user:
```
assets_out = floor(assets × supply_before / assets_before) × assets_before / supply_before
           ≤ assets × supply_before / assets_before × assets_before / supply_before
           = assets
```

So `assets_out ≤ assets_in`.

By always rounding against the user on outflows, we ensure **users cannot extract value through rounding arbitrage**. ✓

### Proof 5: Share Burning is Equivalent to Withdrawal

**Claim**: Burning shares removes corresponding assets from circulation

**Proof**:

When user redeems `s` shares where total shares = `S` and total assets = `A`:

Assets removed = `s × A / S`

After transaction:
- totalAssets = `A - (s × A / S) = A × (S - s) / S`
- totalSupply = `S - s`
- New price per share = `A × (S - s) / S / (S - s) = A / S`

**Price per share remains unchanged** ✓

This proves that redemptions don't affect other shareholders, which is the fundamental requirement of a fair vault.

---

## Common Implementation Mistakes

### Mistake 1: Incorrect Rounding Direction

```solidity
// WRONG: Using DOWN for mint (should be UP)
function mint(uint256 shares, address receiver) external returns (uint256 assets) {
    assets = shares * totalAssets / totalSupply;  // Rounds DOWN
    // Vault could receive fewer assets than expected!
}

// CORRECT:
function mint(uint256 shares, address receiver) external returns (uint256 assets) {
    assets = (shares * totalAssets + totalSupply - 1) / totalSupply;  // Rounds UP
    // Vault always receives enough assets for exact shares
}
```

**Impact**: Vault can be drained if users exploit rounding.

### Mistake 2: Not Handling Zero Division

```solidity
// WRONG: No check for empty vault
function deposit(uint256 assets, address receiver) external returns (uint256 shares) {
    shares = assets * totalSupply / totalAssets;  // Divides by 0 when empty!
}

// CORRECT:
function deposit(uint256 assets, address receiver) external returns (uint256 shares) {
    if (totalSupply == 0) {
        shares = assets * 10**decimals() / 10**asset.decimals();
    } else {
        shares = assets * totalSupply / totalAssets;
    }
}
```

**Impact**: Vault crashes on first deposit.

### Mistake 3: preview* Functions Don't Match Implementation

```solidity
// WRONG: preview and actual use different rounding
function previewMint(uint256 shares) external view returns (uint256) {
    return shares * totalAssets / totalSupply;  // Rounds DOWN (wrong!)
}

function mint(uint256 shares, address receiver) external returns (uint256 assets) {
    assets = (shares * totalAssets + totalSupply - 1) / totalSupply;  // Rounds UP
    // previewMint(100) might return 50, but mint(100) needs 51 assets!
}

// CORRECT:
function previewMint(uint256 shares) external view returns (uint256) {
    return (shares * totalAssets + totalSupply - 1) / totalSupply;  // Matches mint()
}

function mint(uint256 shares, address receiver) external returns (uint256 assets) {
    assets = (shares * totalAssets + totalSupply - 1) / totalSupply;
}
```

**Impact**: Front-running and contract integration failures.

### Mistake 4: Allowing Rounding to Zero

```solidity
// WRONG: No check for rounding to zero
function withdraw(uint256 assets, address receiver, address owner)
    external
    returns (uint256 shares)
{
    shares = assets * totalSupply / totalAssets;
    // If shares == 0, transaction succeeds but nothing happens!
    _burn(owner, shares);  // Burns 0 shares
    asset.transfer(receiver, assets);  // Transfers assets but doesn't burn shares!
}

// CORRECT:
function withdraw(uint256 assets, address receiver, address owner)
    external
    returns (uint256 shares)
{
    require(assets > 0, "Zero amount");
    shares = assets * totalSupply / totalAssets;
    require(shares > 0, "Rounding resulted in zero shares");
    _burn(owner, shares);
    asset.transfer(receiver, assets);
}
```

**Impact**: Assets stolen, shares not burned.

### Mistake 5: Not Protecting Against First Deposit Attack

```solidity
// WRONG: No mitigation
contract UnsafeVault {
    function deposit(uint256 assets, address receiver) external returns (uint256 shares) {
        shares = totalSupply == 0 ? assets : assets * totalSupply / totalAssets;
        // Attacker can still inflate share price!
    }
}

// CORRECT: Use virtual offset
contract SafeVault {
    uint256 constant VIRTUAL_OFFSET = 10**6;

    function convertToShares(uint256 assets) internal view returns (uint256) {
        return assets * (totalSupply + VIRTUAL_OFFSET) / (totalAssets + VIRTUAL_OFFSET);
    }
}
```

**Impact**: Vault susceptible to inflation attacks.

### Mistake 6: Overflow in Calculations

```solidity
// WRONG: Can overflow with large values
function convertToShares(uint256 assets) internal view returns (uint256) {
    return assets * totalSupply() / totalAssets();  // assets * totalSupply might overflow!
}

// CORRECT: Order operations to minimize risk
function convertToShares(uint256 assets) internal view returns (uint256) {
    uint256 supply = totalSupply();
    uint256 assets_bal = totalAssets();

    if (supply == 0) return assets * 10**18 / 10**6;

    // If assets is small relative to assets_bal, divide first
    if (assets <= type(uint256).max / supply) {
        return assets * supply / assets_bal;
    } else {
        // Otherwise, re-order to avoid overflow
        return (assets / assets_bal) * supply + (assets % assets_bal) * supply / assets_bal;
    }
}
```

**Impact**: Integer overflow crashes vault.

### Mistake 7: Not Adjusting for Decimal Mismatch

```solidity
// WRONG: Doesn't account for different decimals
function deposit(uint256 assets, address receiver) external returns (uint256 shares) {
    // asset might have 6 decimals, shares have 18
    // assets is given in wei of the asset
    shares = assets * totalSupply / totalAssets;
}

// CORRECT:
function deposit(uint256 assets, address receiver) external returns (uint256 shares) {
    uint256 assetDecimals = asset.decimals();
    uint256 shareDecimals = 18;

    if (totalSupply == 0) {
        // Scale assets to share decimals
        shares = assets * (10 ** shareDecimals) / (10 ** assetDecimals);
    } else {
        shares = assets * totalSupply / totalAssets;
    }
}
```

**Impact**: Share prices miscalculated, potential loss of funds.

---

## Flow Diagrams

### User Flow: Deposit

```
User wants to deposit 100 USDC
        ↓
User calls deposit(100 ether)  // 100 USDC in smallest units
        ↓
Vault calculates shares
shares = 100 × totalSupply / totalAssets
        ↓
Vault transfers 100 USDC from user to vault
asset.transferFrom(user, vault, 100)
        ↓
Vault mints shares to user
_mint(user, shares)
        ↓
Event emitted: Deposit(user, user, 100, shares)
        ↓
User receives shares
```

### Mathematical Flow: Deposit

```
┌────────────────────────────────────────────────┐
│ DEPOSIT FLOW                                   │
├────────────────────────────────────────────────┤
│                                                │
│  Input: assets (user has this much underlying)│
│                                                │
│  Formula: shares = assets × S / A              │
│           where S = totalSupply                │
│                 A = totalAssets                │
│  Rounding: DOWN (user receives less)           │
│                                                │
│  Output: shares (user receives this much)      │
│                                                │
│  State Changes:                                │
│  - totalAssets += assets                       │
│  - totalSupply += shares                       │
│  - balanceOf[user] += shares                   │
│                                                │
└────────────────────────────────────────────────┘
```

### User Flow: Mint

```
User wants exactly 1000 shares
        ↓
User calls mint(1000 ether)  // 1000 shares in smallest units
        ↓
Vault calculates assets needed
assets = 1000 × totalAssets / totalSupply
if fractional: assets += 1  (ROUND UP)
        ↓
Vault transfers assets from user to vault
asset.transferFrom(user, vault, assets)
        ↓
Vault mints EXACTLY 1000 shares to user
_mint(user, 1000)
        ↓
Event emitted: Deposit(user, user, assets, 1000)
        ↓
User has exactly 1000 shares (and lost 'assets' USDC)
```

### Mathematical Flow: Mint

```
┌────────────────────────────────────────────────┐
│ MINT FLOW                                      │
├────────────────────────────────────────────────┤
│                                                │
│  Input: shares (user wants this exact amount) │
│                                                │
│  Formula: assets = (shares × A + S - 1) / S   │
│           where S = totalSupply                │
│                 A = totalAssets                │
│  Rounding: UP (user pays more for certainty)  │
│                                                │
│  Output: assets (user must pay this much)      │
│                                                │
│  State Changes:                                │
│  - totalAssets += assets                       │
│  - totalSupply += shares                       │
│  - balanceOf[user] += shares                   │
│                                                │
└────────────────────────────────────────────────┘
```

### User Flow: Redeem

```
User wants to redeem 500 shares
        ↓
User calls redeem(500 ether, receiver, user)
        ↓
Vault calculates assets to return
assets = 500 × totalAssets / totalSupply
        ↓
Vault burns 500 shares from user
_burn(user, 500)
        ↓
Vault transfers assets to receiver
asset.transfer(receiver, assets)
        ↓
Event emitted: Withdraw(user, receiver, user, assets, 500)
        ↓
Receiver has assets, user has 500 fewer shares
```

### Mathematical Flow: Redeem

```
┌────────────────────────────────────────────────┐
│ REDEEM FLOW                                    │
├────────────────────────────────────────────────┤
│                                                │
│  Input: shares (user will give up this many)  │
│                                                │
│  Formula: assets = (shares × A) / S            │
│           where S = totalSupply                │
│                 A = totalAssets                │
│  Rounding: DOWN (user receives less)           │
│                                                │
│  Output: assets (user receives this much)      │
│                                                │
│  State Changes:                                │
│  - totalAssets -= assets                       │
│  - totalSupply -= shares                       │
│  - balanceOf[user] -= shares                   │
│                                                │
└────────────────────────────────────────────────┘
```

### Vault State Evolution

```
TIME 0 (Empty):
┌─────────────────────────────────────┐
│ Vault                               │
│ totalAssets = 0                     │
│ totalSupply = 0                     │
│ Share Price = undefined             │
└─────────────────────────────────────┘

TIME 1 (Alice deposits 100 assets):
┌─────────────────────────────────────┐
│ Vault                               │
│ totalAssets = 100                   │
│ totalSupply = 100 (shares)          │
│ Share Price = 1 asset/share         │
│ Alice: 100 shares                   │
└─────────────────────────────────────┘

TIME 2 (Vault earns 50 assets):
┌─────────────────────────────────────┐
│ Vault                               │
│ totalAssets = 150                   │
│ totalSupply = 100 (unchanged)       │
│ Share Price = 1.5 assets/share      │
│ Alice: 100 shares (worth 150)       │
└─────────────────────────────────────┘

TIME 3 (Bob deposits 150 assets):
shares = 150 × 100 / 150 = 100 shares
┌─────────────────────────────────────┐
│ Vault                               │
│ totalAssets = 300                   │
│ totalSupply = 200                   │
│ Share Price = 1.5 assets/share      │
│ Alice: 100 shares (worth 150)       │
│ Bob: 100 shares (worth 150)         │
└─────────────────────────────────────┘

TIME 4 (Alice redeems 50 shares):
assets = 50 × 300 / 200 = 75 assets
┌─────────────────────────────────────┐
│ Vault                               │
│ totalAssets = 225                   │
│ totalSupply = 150                   │
│ Share Price = 1.5 assets/share      │
│ Alice: 50 shares (worth 75)         │
│ Bob: 100 shares (worth 150)         │
└─────────────────────────────────────┘
```

---

## Example Calculations

### Example 1: Basic Deposit and Earn

**Initial State**:
```
totalAssets = 1000 USDC
totalSupply = 500 shares
Share price = 1000 / 500 = 2 USDC per share
```

**User Action**: Deposit 100 USDC

**Calculation**:
```
shares = 100 × 500 / 1000
shares = 50000 / 1000
shares = 50 shares
```

**After Deposit**:
```
totalAssets = 1000 + 100 = 1100 USDC
totalSupply = 500 + 50 = 550 shares
Share price = 1100 / 550 = 2 USDC per share (unchanged)
User has 50 shares
```

**After Vault Earns 110 USDC**:
```
totalAssets = 1100 + 110 = 1210 USDC
totalSupply = 550 shares (unchanged)
Share price = 1210 / 550 = 2.2 USDC per share (increased)
```

**User's Wealth**:
```
User shares: 50
User wealth = 50 × 2.2 = 110 USDC
Original deposit: 100 USDC
Profit: 10 USDC
Proportional return: 10% (same as vault)
```

### Example 2: First Deposit in Empty Vault

**Initial State**:
```
totalAssets = 0
totalSupply = 0
```

**User Action**: Deposit 100 USDC (with 18 decimal shares, 6 decimal asset)

**Calculation**:
```
Since totalSupply == 0:
shares = assets × 10^decimals / 10^asset.decimals
shares = 100 × 10^18 / 10^6
shares = 100 × 10^12
shares = 10^14 shares
```

**After Deposit**:
```
totalAssets = 100 USDC (10^8 wei)
totalSupply = 10^14 shares
Share price = 10^8 / 10^14 = 10^-6 USDC per share
```

This establishes 1:10^6 ratio between assets (in wei) and shares, giving shares meaningful precision.

### Example 3: Mint with Rounding Up

**Vault State**:
```
totalAssets = 1000
totalSupply = 999
Share price = 1000 / 999 ≈ 1.001 USDC per share
```

**User Action**: Mint exactly 333 shares

**Calculation** (standard division):
```
assets = 333 × 1000 / 999
assets = 333000 / 999
assets = 333.333... (before rounding)
```

**Rounding Up** (for mint):
```
assets = (333 × 1000 + 999 - 1) / 999
assets = (333000 + 998) / 999
assets = 333998 / 999
assets = 334 (rounded up)
```

**After Mint**:
```
totalAssets = 1000 + 334 = 1334
totalSupply = 999 + 333 = 1332
Share price = 1334 / 1332 ≈ 1.0015 USDC per share
```

**Analysis**:
- User paid 334 assets for 333 shares
- 1 asset went to vault surplus (rounded up)
- Vault is protected

### Example 4: Withdraw with Rounding Up

**Vault State**:
```
totalAssets = 1500
totalSupply = 1000
Share price = 1500 / 1000 = 1.5 USDC per share
```

**User Action**: Withdraw exactly 300 assets

**Calculation**:
```
shares = 300 × 1000 / 1500
shares = 300000 / 1500
shares = 200 (exactly)
```

**No rounding needed in this case**, but if there were:

Alternative vault state:
```
totalAssets = 1500
totalSupply = 1001
Share price = 1500 / 1001 ≈ 1.4985 USDC per share
```

**Calculation with rounding**:
```
shares = (300 × 1001 + 1500 - 1) / 1500
shares = (300300 + 1499) / 1500
shares = 301799 / 1500
shares = 201 (rounded up)
```

**After Withdraw**:
```
totalAssets = 1500 - 300 = 1200
totalSupply = 1001 - 201 = 800
Share price = 1200 / 800 = 1.5 (unchanged)
```

**Analysis**:
- User withdrew 300 assets by burning 201 shares
- Had to burn 1 extra share due to rounding
- Vault is protected

### Example 5: The Rounding Impact Over Time

**Scenario**: Users repeatedly deposit and withdraw small amounts

**Initial Vault**:
```
totalAssets = 1000000
totalSupply = 1000000
Price = 1.0
```

**Round 1 - User deposits 1 asset with DOWN rounding**:
```
shares = 1 × 1000000 / 1000000 = 1 share (no rounding)
Vault: 1000001 assets, 1000001 shares
```

**Round 2 - User deposits 1 asset with DOWN rounding**:
```
shares = 1 × 1000001 / 1000001 = 1 share (no rounding)
Vault: 1000002 assets, 1000002 shares
```

**Round 3 - User deposits 2 assets with DOWN rounding**:
```
shares = 2 × 1000002 / 1000002 = 2 shares (no rounding)
Vault: 1000004 assets, 1000004 shares
```

**Pattern**: With DOWN rounding on small deposits, the vault never gains or loses from rounding in simple cases.

**Now with fractional share price** (1500 assets / 1000 shares):

**User deposits 1000 assets**:
```
shares = 1000 × 1000 / 1500 = 1000000 / 1500 = 666.666...
Rounded DOWN: 666 shares
Lost to rounding: 0.666 shares
```

**After many deposits**:
```
Accumulated rounding loss: significant
These fractions accumulate in the vault
Vault becomes slightly more valuable
Early depositors benefit from accumulated dust
```

### Example 6: Preventing Inflation Attack

**Attack Scenario (Without Protection)**:

Step 1 - Attacker deposits 1 wei:
```
shares = 1 × 10^18 / 1 = 10^18 shares
Vault: 1 asset, 10^18 shares
```

Step 2 - Attacker transfers 10^15 assets directly:
```
Vault: 10^15 + 1 assets, 10^18 shares
Share price: 10^15 / 10^18 = 10^-3 assets per share
```

Step 3 - Innocent user deposits 10^9 assets:
```
shares = 10^9 × 10^18 / (10^15 + 1)
shares ≈ 10^27 / 10^15
shares ≈ 10^12 shares

User gets 10^12 shares instead of ~10^9 shares they expected
Attacker's 10^18 shares now worth ~10^15 assets
Profit: 10^15 - 1 = effectively unlimited
```

**With Virtual Offset Protection** (offset = 10^6):

Step 1 - Attacker deposits 1 wei:
```
shares = 1 × (10^18 + 10^6) / (1 + 10^6)
shares ≈ 10^18 shares (approximately same)
```

Step 2 - Attacker transfers 10^15 assets:
```
New share price calculation:
shares = assets × (supply + offset) / (assets + offset)
shares = 10^9 × (10^18 + 10^6) / (10^15 + 10^6)
shares ≈ 10^9 × 10^18 / 10^15
shares ≈ 10^12 shares (same as before!)

BUT with offset considered:
Effective price = (10^15 + 10^6) / (10^18 + 10^6)
               ≈ 10^15 / 10^18
               = 10^-3 assets per share

Attacker's profit reduced from 10^15 to only ~10^6
Cost of attack (10^15) >> profit (10^6)
Attack no longer profitable!
```

---

## Implementation Checklist

### Core Functions

- [ ] `deposit(uint256 assets, address receiver) → uint256 shares`
  - [ ] Handles zero supply (first deposit)
  - [ ] Correct rounding (DOWN)
  - [ ] Prevents rounding to zero
  - [ ] Transfers assets correctly
  - [ ] Mints shares correctly
  - [ ] Emits Deposit event

- [ ] `mint(uint256 shares, address receiver) → uint256 assets`
  - [ ] Calculates assets with UP rounding
  - [ ] Prevents rounding to zero
  - [ ] Transfers assets correctly
  - [ ] Mints exact shares
  - [ ] Emits Deposit event

- [ ] `withdraw(uint256 assets, address receiver, address owner) → uint256 shares`
  - [ ] Calculates shares with UP rounding
  - [ ] Handles approvals correctly
  - [ ] Burns shares correctly
  - [ ] Transfers assets correctly
  - [ ] Emits Withdraw event

- [ ] `redeem(uint256 shares, address receiver, address owner) → uint256 assets`
  - [ ] Calculates assets with DOWN rounding
  - [ ] Handles approvals correctly
  - [ ] Burns shares correctly
  - [ ] Transfers assets correctly
  - [ ] Emits Withdraw event

### Preview Functions

- [ ] `previewDeposit(uint256 assets) → uint256 shares`
  - [ ] Returns same value as `deposit()` would
  - [ ] Uses DOWN rounding
  - [ ] Never reverts

- [ ] `previewMint(uint256 shares) → uint256 assets`
  - [ ] Returns same value as `mint()` would
  - [ ] Uses UP rounding
  - [ ] Never reverts

- [ ] `previewWithdraw(uint256 assets) → uint256 shares`
  - [ ] Returns same value as `withdraw()` would
  - [ ] Uses UP rounding
  - [ ] Never reverts

- [ ] `previewRedeem(uint256 shares) → uint256 assets`
  - [ ] Returns same value as `redeem()` would
  - [ ] Uses DOWN rounding
  - [ ] Never reverts

### Utility Functions

- [ ] `convertToShares(uint256 assets) → uint256`
  - [ ] Handles zero supply
  - [ ] Correct rounding per context
  - [ ] Handles overflow risks

- [ ] `convertToAssets(uint256 shares) → uint256`
  - [ ] Handles zero supply
  - [ ] Correct rounding per context
  - [ ] Handles overflow risks

### Security

- [ ] First deposit inflation attack mitigation
  - [ ] Virtual offset OR minimum deposit OR dead shares
  - [ ] Tested with exploit

- [ ] Rounding to zero prevention
  - [ ] All functions check `shares > 0` or `assets > 0`
  - [ ] Error messages clear

- [ ] Overflow protection
  - [ ] Tested with large numbers
  - [ ] Safe operation ordering

- [ ] Edge cases handled
  - [ ] Empty vault (0 assets, 0 supply)
  - [ ] Drained vault (0 assets, > 0 supply)
  - [ ] Single share
  - [ ] Decimal mismatches

### Testing

- [ ] Unit tests for each function
- [ ] Integration tests (deposit → earn → withdraw)
- [ ] Rounding tests
  - [ ] Verify DOWN rounding on deposits/redeems
  - [ ] Verify UP rounding on mints/withdraws
  - [ ] Test fractional amounts

- [ ] Attack tests
  - [ ] First deposit inflation attack
  - [ ] Rounding arbitrage
  - [ ] Flash loan attacks (if applicable)

- [ ] Property tests
  - [ ] totalAssets always ≥ sum of redeemable assets
  - [ ] totalSupply consistency
  - [ ] Share price monotonicity (with profits)
  - [ ] No funds created or destroyed via rounding

### Documentation

- [ ] Function documentation with formulas
- [ ] Explanation of rounding choices
- [ ] Examples in comments
- [ ] Known limitations documented

---

## Quick Reference Tables

### Rounding Quick Reference

| Function | Direction | Reason | Code |
|----------|-----------|--------|------|
| `deposit()` | DOWN | User gets less | Direct division |
| `mint()` | UP | Vault gets more | `(a * b + c - 1) / c` |
| `withdraw()` | UP | User pays more | `(a * b + c - 1) / c` |
| `redeem()` | DOWN | User gets less | Direct division |

### Formula Quick Reference

| Conversion | Formula | When to Use |
|------------|---------|-------------|
| Assets → Shares (deposit) | `assets × supply / assets` | Deposit flow |
| Shares → Assets (mint) | `shares × assets / supply` | Mint flow |
| Assets → Shares (withdraw) | `assets × supply / assets` | Withdrawal flow |
| Shares → Assets (redeem) | `shares × assets / supply` | Redemption flow |

### Edge Cases Quick Reference

| Case | Behavior | Solution |
|------|----------|----------|
| Empty vault | Division by zero | Return `assets × 10^decimals` |
| Rounding to zero | Lost deposit | Check `shares > 0` |
| Very small ratio | Precision loss | Scale up calculations |
| Overflow | Integer overflow | Reorder operations |
| Inflation attack | Share price spike | Virtual offset / minimum deposit |

---

## Additional Resources

### Related EIP-4626 Documents

- Original Proposal: https://eips.ethereum.org/EIPS/eip-4626
- Reference Implementation: OpenZeppelin's ERC4626

### Testing Libraries

- Foundry (Solidity testing)
- Hardhat (JavaScript testing)
- Property-based testing: Echidna, Medusa

### Security Considerations

- Trail of Bits ERC-4626 audit findings
- Euler Finance vault exploits (learning resources)
- Yearn vault patterns

---

## Summary

ERC-4626 vault mathematics is elegantly simple in concept but requires careful implementation:

1. **Core Principle**: Shares represent proportional ownership
2. **Key Insight**: Price per share = Total Assets / Total Shares
3. **Rounding Rule**: Always round against users on outputs
4. **Critical Protection**: Prevent first deposit inflation attack
5. **Testing Essential**: Property-based testing catches subtle bugs

The formulas are universal, but the rounding directions and edge case handling are where implementations differ. Follow the checklist carefully and test thoroughly.

---

*Last Updated: November 2024*
*This guide is comprehensive but not a substitute for professional security auditing.*
