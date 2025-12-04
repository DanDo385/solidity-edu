# Project 42: ERC-4626 Precision & Rounding 🔢

> **Master the critical mathematics of vault rounding and precision**

## 🎯 Learning Objectives

By completing this project, you will:

1. **Understand rounding direction requirements** in vault operations
2. **Implement mathematically sound preview functions** that match actual behavior
3. **Handle edge cases** with zero denominators and first deposits
4. **Prevent precision-based attacks** through correct rounding
5. **Master mulDiv rounding modes** (up, down, nearest)
6. **Prove vault invariants** hold under all conditions
7. **Compare rounding strategies** and their security implications
8. **Create comprehensive test suites** for precision edge cases
9. **Understand production-grade rounding** implementations

## Why Rounding Matters

### The Golden Rule of Vault Rounding

**Rounding must ALWAYS favor the vault** to maintain security and solvency.

- **Deposit/Mint**: Round DOWN shares given to user
  - User deposits assets, vault gives shares
  - Give fewer shares = vault favorable

- **Withdraw/Redeem**: Round UP assets taken from vault
  - User burns shares, vault gives assets
  - Take more assets from user (fewer assets out) = vault favorable

### Security Implications

Incorrect rounding can lead to:

1. **Vault Insolvency**: Users can extract more value than deposited
2. **Inflation Attacks**: First depositor can manipulate share price
3. **Precision Drain**: Repeated operations drain vault reserves
4. **Share Manipulation**: Attackers exploit rounding to steal funds

## Mathematical Foundation

### Share-Asset Conversion Formula

```
shares = assets × totalShares / totalAssets
assets = shares × totalAssets / totalShares
```

### Rounding Modes in mulDiv

When computing `(a × b) / c`:

- **Round DOWN**: `(a × b) / c` (default division)
- **Round UP**: `(a × b + c - 1) / c` (add denominator - 1)

Mathematical proof of round-up formula:
```
Let q = (a × b) / c (rounded down)
Let r = (a × b) % c (remainder)

If r > 0:
  (a × b + c - 1) / c = (q × c + r + c - 1) / c
                      = q + (r + c - 1) / c
                      = q + 1  (since 0 < r < c, so c ≤ r + c - 1 < 2c)

If r = 0:
  (a × b + c - 1) / c = (q × c + c - 1) / c
                      = q  (since c - 1 < c)

Result: Rounds up exactly when remainder exists
```

## ERC-4626 Function Rounding Requirements

### Deposit Functions

```solidity
function deposit(uint256 assets, address receiver) returns (uint256 shares)
```

**Rounding**: MUST round DOWN shares
- User gives assets → receives shares
- Fewer shares = vault keeps more value per share

**Formula**:
```
shares = (assets × totalSupply) / totalAssets  // Round DOWN
```

### Mint Functions

```solidity
function mint(uint256 shares, address receiver) returns (uint256 assets)
```

**Rounding**: MUST round UP assets required
- User wants shares → must pay assets
- More assets required = vault favorable

**Formula**:
```
assets = roundUp((shares × totalAssets) / totalSupply)  // Round UP
```

### Withdraw Functions

```solidity
function withdraw(uint256 assets, address receiver, address owner) returns (uint256 shares)
```

**Rounding**: MUST round UP shares burned
- User wants assets out → must burn shares
- More shares burned = vault keeps more

**Formula**:
```
shares = roundUp((assets × totalSupply) / totalAssets)  // Round UP
```

### Redeem Functions

```solidity
function redeem(uint256 shares, address receiver, address owner) returns (uint256 assets)
```

**Rounding**: MUST round DOWN assets given
- User burns shares → receives assets
- Fewer assets given = vault favorable

**Formula**:
```
assets = (shares × totalAssets) / totalSupply  // Round DOWN
```

## Preview Functions

Preview functions MUST match the rounding of their corresponding action:

```solidity
previewDeposit  → round DOWN (matches deposit)
previewMint     → round UP   (matches mint)
previewWithdraw → round UP   (matches withdraw)
previewRedeem   → round DOWN (matches redeem)
```

Per EIP-4626 specification:
> "MUST return as close to and no fewer than the exact amount of shares
> that would be minted in a deposit call in the same transaction."

## Edge Cases

### Zero Total Supply (Empty Vault)

When `totalSupply == 0`:

```solidity
// First deposit: 1:1 ratio
shares = assets  // Initial deposit is 1:1
```

**Critical**: First depositor sets initial exchange rate!

### Zero Total Assets

When `totalAssets == 0` but `totalSupply > 0`:

**This is a CRITICAL state** indicating:
- Vault has been drained
- Loss event occurred
- Accounting error

**Handling**:
```solidity
// Shares are worthless - conversions should return 0
if (totalAssets == 0 && totalSupply > 0) {
    return 0;  // Shares have no value
}
```

### Division by Zero

Always check denominators:

```solidity
// Converting assets to shares
if (totalAssets == 0) {
    return assets;  // 1:1 for empty vault
}
shares = (assets × totalSupply) / totalAssets;

// Converting shares to assets
if (totalSupply == 0) {
    return 0;  // No shares exist, no assets owed
}
assets = (shares × totalAssets) / totalSupply;
```

## Precision Loss

### The Rounding Tax

Every conversion potentially loses 1 wei due to rounding:

```solidity
// User deposits 100 assets
deposit(100)  → receives 99 shares (rounded down)

// If exchange rate is 1:1, lost 1 share worth of value
```

Over many small operations, precision loss accumulates in vault's favor.

### Mitigation

1. **Minimum Deposit Amount**: Prevent dust deposits
2. **Virtual Shares**: Add offset to prevent inflation attacks
3. **Dead Shares**: Lock initial liquidity

## Attack Scenarios

### 1. Inflation Attack

**Setup**:
1. Attacker is first depositor
2. Deposits 1 wei → receives 1 share
3. Directly transfers 1000e18 tokens to vault (not via deposit)
4. Exchange rate is now 1 share = 1000e18 assets

**Attack**:
1. Victim deposits 1999e18 assets
2. shares = (1999e18 × 1) / 1000e18 = 1.999 → rounds to 1 share
3. Victim lost ~1000e18 in value!

**Prevention**:
- Require minimum deposit
- Use virtual shares/assets
- Lock initial liquidity

### 2. Precision Drain

**Setup**: Vault rounds incorrectly (favors user)

**Attack**:
1. Repeatedly deposit and withdraw small amounts
2. Each round gains 1 wei due to incorrect rounding
3. 1 million operations = drain 1 million wei

**Prevention**: Always round in vault's favor

### 3. Share Dilution

**Setup**: Withdraw rounds down shares burned

**Attack**:
1. User withdraws maximum assets while burning minimum shares
2. Each withdrawal increases attacker's share percentage
3. Eventually owns disproportionate vault value

**Prevention**: Withdraw must round UP shares burned

## Implementation Requirements

### 1. MulDiv Helper

```solidity
/// @dev Multiplies two numbers and divides by a third, rounding down
function mulDiv(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
    return (a × b) / c;  // Solidity default rounds down
}

/// @dev Multiplies two numbers and divides by a third, rounding up
function mulDivUp(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
    uint256 result = (a × b) / c;
    if ((a × b) % c > 0) {
        result += 1;  // Add 1 if remainder exists
    }
    return result;
}
```

### 2. Conversion Functions

```solidity
function convertToShares(uint256 assets) public view returns (uint256) {
    uint256 supply = totalSupply();
    if (supply == 0) return assets;  // 1:1 initial

    // Round DOWN for user's benefit limit
    return mulDiv(assets, supply, totalAssets());
}

function convertToAssets(uint256 shares) public view returns (uint256) {
    uint256 supply = totalSupply();
    if (supply == 0) return 0;  // No shares = no value

    // Round DOWN for user's withdrawal limit
    return mulDiv(shares, totalAssets(), supply);
}
```

### 3. Preview Functions

```solidity
function previewDeposit(uint256 assets) public view returns (uint256) {
    return convertToShares(assets);  // Already rounds DOWN
}

function previewMint(uint256 shares) public view returns (uint256) {
    uint256 supply = totalSupply();
    if (supply == 0) return shares;  // 1:1 initial

    // Round UP - user must pay this much
    return mulDivUp(shares, totalAssets(), supply);
}

function previewWithdraw(uint256 assets) public view returns (uint256) {
    uint256 supply = totalSupply();
    if (supply == 0) return 0;

    // Round UP - user must burn this many shares
    return mulDivUp(assets, supply, totalAssets());
}

function previewRedeem(uint256 shares) public view returns (uint256) {
    return convertToAssets(shares);  // Already rounds DOWN
}
```

## Mathematical Proofs

### Invariant 1: Vault Cannot Lose Value

**Claim**: For any deposit followed by immediate redeem, vault value cannot decrease.

**Proof**:
```
User deposits A assets
  → receives S shares where S = ⌊A × T_supply / T_assets⌋

User immediately redeems S shares
  → receives B assets where B = ⌊S × T_assets / T_supply⌋

Substituting:
  B = ⌊⌊A × T_supply / T_assets⌋ × T_assets / T_supply⌋
    ≤ ⌊A × T_supply / T_assets × T_assets / T_supply⌋
    = ⌊A⌋
    = A

Therefore: B ≤ A (user gets ≤ deposited amount)
Vault net gain: A - B ≥ 0 ✓
```

### Invariant 2: User Cannot Profit from Round-Trip

**Claim**: Deposit then redeem cannot increase user's assets.

**Proof**: Same as Invariant 1, shows B ≤ A ✓

### Invariant 3: Total Value Conserved

**Claim**: Sum of (user assets) + (vault assets) remains constant.

**Proof**:
```
Initial: User has A assets, vault has V assets
After deposit: User has 0 assets + S shares, vault has V + A assets
  Total value = S × (V + A) / T_new + (V + A) = (V + A)  ✓

After redeem: User has B assets, vault has V + A - B assets
  Total value = B + (V + A - B) = V + A  ✓
```

## Testing Strategy

### Unit Tests

1. **Rounding Direction**
   - Verify deposit rounds down shares
   - Verify mint rounds up assets
   - Verify withdraw rounds up shares
   - Verify redeem rounds down assets

2. **Edge Cases**
   - Zero total supply
   - Zero total assets
   - Maximum uint256 values
   - Minimum viable amounts

3. **Precision**
   - Detect 1 wei rounding differences
   - Verify preview matches actual
   - Test with various exchange rates

### Integration Tests

1. **Round-Trip Tests**
   - Deposit → Redeem ≤ original
   - Mint → Withdraw ≥ original cost

2. **Invariant Tests**
   - Vault value never decreases
   - Total supply matches accounting

### Attack Prevention Tests

1. **Inflation Attack**
   - First depositor + donation cannot exploit victim

2. **Precision Drain**
   - Repeated small operations don't drain vault

3. **Share Dilution**
   - Cannot gain share percentage through withdrawals

## Security Checklist

- [ ] Deposit rounds DOWN shares given
- [ ] Mint rounds UP assets required
- [ ] Withdraw rounds UP shares burned
- [ ] Redeem rounds DOWN assets given
- [ ] Preview functions match action rounding
- [ ] Handle zero total supply edge case
- [ ] Handle zero total assets edge case
- [ ] No division by zero possible
- [ ] MulDiv overflow protection
- [ ] Minimum deposit enforced
- [ ] First depositor protection
- [ ] All invariants tested

## Common Mistakes

### ❌ Wrong: Rounding in User's Favor

```solidity
function deposit(uint256 assets) public returns (uint256 shares) {
    shares = mulDivUp(assets, totalSupply(), totalAssets());  // ❌ WRONG!
    // Gives user MORE shares than deserved
}
```

### ✅ Correct: Rounding in Vault's Favor

```solidity
function deposit(uint256 assets) public returns (uint256 shares) {
    shares = mulDiv(assets, totalSupply(), totalAssets());  // ✅ CORRECT
    // Gives user FEWER shares (vault keeps difference)
}
```

### ❌ Wrong: Preview Doesn't Match Action

```solidity
function previewWithdraw(uint256 assets) public view returns (uint256) {
    return convertToShares(assets);  // ❌ Rounds DOWN, but withdraw rounds UP
}
```

### ✅ Correct: Preview Matches Action

```solidity
function previewWithdraw(uint256 assets) public view returns (uint256) {
    return mulDivUp(assets, totalSupply(), totalAssets());  // ✅ CORRECT
}
```

## References

- [EIP-4626: Tokenized Vault Standard](https://eips.ethereum.org/EIPS/eip-4626)
- [OpenZeppelin ERC4626 Implementation](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC4626.sol)
- [Solmate ERC4626](https://github.com/transmissions11/solmate/blob/main/src/mixins/ERC4626.sol)
- [ERC4626 Security Considerations](https://docs.openzeppelin.com/contracts/4.x/erc4626)

## Project Tasks

1. Implement `mulDivUp` helper function
2. Implement proper rounding in deposit/mint/withdraw/redeem
3. Implement preview functions with correct rounding
4. Handle all edge cases (zero denominators)
5. Write tests proving vault invariants
6. Test attack prevention
7. Verify preview functions match actions

## Running the Project

```bash
# Install dependencies
forge install

# Run tests
forge test -vv

# Run with gas reporting
forge test --gas-report

# Run specific test
forge test --match-test testRoundingDirection -vvv

# Deploy
forge script script/DeployProject42.s.sol --rpc-url $RPC_URL --broadcast
```

## Success Criteria

- All tests pass
- No rounding favors users over vault
- Preview functions exactly match actions
- Edge cases handled safely
- Attack tests prove exploit prevention
- Gas-efficient implementation
- Clear mathematical comments

---

**Master vault mathematics and build secure, exploitproof tokenized vaults! 🏦**
