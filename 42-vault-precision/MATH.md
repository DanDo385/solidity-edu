# Mathematical Foundations of ERC-4626 Vaults

## Overview

This document provides rigorous mathematical proofs and explanations for ERC-4626 vault operations, rounding behavior, and security properties.

## Notation

| Symbol | Meaning |
|--------|---------|
| `A` | Assets (underlying tokens) |
| `S` | Shares (vault tokens) |
| `T_A` | Total assets in vault |
| `T_S` | Total shares (totalSupply) |
| `⌊x⌋` | Floor function (round down) |
| `⌈x⌉` | Ceiling function (round up) |
| `x mod y` | Remainder of x divided by y |

## Core Conversion Formulas

### Asset to Share Conversion

**Formula:**
```
S = (A × T_S) / T_A
```

**Interpretation:**
- User deposits `A` assets
- Receives `S` shares proportional to their contribution
- Maintains constant ratio: `A/S = T_A/T_S`

**Proof of Proportionality:**
```
Given: User deposits A assets, receives S shares

Before deposit:
  T_A assets → T_S shares
  Ratio: T_A / T_S

After deposit:
  (T_A + A) assets → (T_S + S) shares

For fair distribution, ratios must be equal:
  T_A / T_S = A / S

Solving for S:
  S × T_A = A × T_S
  S = (A × T_S) / T_A  ✓
```

### Share to Asset Conversion

**Formula:**
```
A = (S × T_A) / T_S
```

**Interpretation:**
- User redeems `S` shares
- Receives `A` assets proportional to their ownership
- Ownership percentage: `S / T_S`
- Entitlement: `(S / T_S) × T_A = A`

## Rounding Mathematics

### Integer Division in Solidity

Solidity performs integer division by truncating (rounding toward zero).

For positive integers `a`, `b`:
```
a / b = ⌊a / b⌋
```

**Examples:**
```
7 / 2 = 3     (not 3.5)
10 / 3 = 3    (not 3.333...)
5 / 2 = 2     (not 2.5)
```

### Round Down Implementation

**Formula:**
```solidity
roundDown(a / b) = a / b  // Solidity default
```

**Properties:**
```
Let q = a / b (integer division)
Let r = a mod b (remainder)

Then: a = b × q + r

Where:
  0 ≤ r < b
  q = ⌊a / b⌋
```

### Round Up Implementation

**Formula:**
```solidity
roundUp(a / b) = (a + b - 1) / b
```

**Proof of Correctness:**

**Case 1: Exact division (r = 0)**
```
Given: a = b × q (no remainder)

roundUp(a / b) = (a + b - 1) / b
                = (b × q + b - 1) / b
                = (b × (q + 1) - 1) / b
                = q    (since b - 1 < b, rounds down to q)
                = a / b  ✓

Conclusion: No change when exact division
```

**Case 2: Has remainder (r > 0)**
```
Given: a = b × q + r, where 0 < r < b

roundUp(a / b) = (a + b - 1) / b
                = (b × q + r + b - 1) / b
                = (b × (q + 1) + (r - 1)) / b
                = q + 1    (since 0 ≤ r - 1 < b, adds to q + 1)
                = ⌈a / b⌉  ✓

Conclusion: Rounds up by exactly 1 when remainder exists
```

**Examples:**
```
roundUp(7 / 2):
  (7 + 2 - 1) / 2 = 8 / 2 = 4  ✓ (7/2 = 3.5 → 4)

roundUp(10 / 3):
  (10 + 3 - 1) / 3 = 12 / 3 = 4  ✓ (10/3 = 3.333... → 4)

roundUp(6 / 2):
  (6 + 2 - 1) / 2 = 7 / 2 = 3  ✓ (6/2 = 3.0 → 3, no change)
```

## Vault Operations - Mathematical Analysis

### Deposit Operation

**User Action:** Deposit `A` assets → Receive `S` shares

**Formula:**
```
S = ⌊(A × T_S) / T_A⌋
```

**Rounding:** DOWN (⌊⌋)

**Proof - User Cannot Profit:**
```
Let S* = (A × T_S) / T_A  (exact value, may be fractional)
Let S = ⌊S*⌋  (actual shares received)

Then: S ≤ S*  (by definition of floor)

Value received by user:
  V = (S × T_A) / T_S
    = (⌊S*⌋ × T_A) / T_S
    ≤ (S* × T_A) / T_S    (since ⌊S*⌋ ≤ S*)
    = ((A × T_S / T_A) × T_A) / T_S
    = A  ✓

Conclusion: User receives value ≤ deposited amount
```

**Vault Gain:**
```
Assets gained by vault: A
Shares issued: S = ⌊(A × T_S) / T_A⌋
Value of shares issued: S × T_A / T_S

Vault net gain:
  G = A - (S × T_A / T_S)
    = A - (⌊(A × T_S) / T_A⌋ × T_A / T_S)
    ≥ 0  ✓ (by previous proof)

Conclusion: Vault never loses value
```

### Mint Operation

**User Action:** Request `S` shares → Pay `A` assets

**Formula:**
```
A = ⌈(S × T_A) / T_S⌉
```

**Rounding:** UP (⌈⌉)

**Proof - Vault Cannot Lose:**
```
Let A* = (S × T_A) / T_S  (exact cost)
Let A = ⌈A*⌉  (actual payment)

Then: A ≥ A*  (by definition of ceiling)

Value paid by user:
  V = A
    = ⌈(S × T_A) / T_S⌉
    ≥ (S × T_A) / T_S  ✓

Conclusion: User pays ≥ fair value for shares
```

**Implementation:**
```solidity
A = roundUp((S × T_A) / T_S)
  = (S × T_A + T_S - 1) / T_S
```

### Withdraw Operation

**User Action:** Request `A` assets → Burn `S` shares

**Formula:**
```
S = ⌈(A × T_S) / T_A⌉
```

**Rounding:** UP (⌈⌉)

**Proof - Vault Cannot Lose:**
```
Let S* = (A × T_S) / T_A  (exact shares needed)
Let S = ⌈S*⌉  (actual shares burned)

Then: S ≥ S*  (by definition of ceiling)

Value burned by user:
  V = (S × T_A) / T_S
    = (⌈S*⌉ × T_A) / T_S
    ≥ (S* × T_A) / T_S    (since ⌈S*⌉ ≥ S*)
    = ((A × T_S / T_A) × T_A) / T_S
    = A  ✓

Conclusion: User burns shares worth ≥ assets withdrawn
```

### Redeem Operation

**User Action:** Burn `S` shares → Receive `A` assets

**Formula:**
```
A = ⌊(S × T_A) / T_S⌋
```

**Rounding:** DOWN (⌊⌋)

**Proof - User Cannot Profit:**
```
Let A* = (S × T_A) / T_S  (exact value of shares)
Let A = ⌊A*⌋  (actual assets received)

Then: A ≤ A*  (by definition of floor)

Conclusion: User receives assets ≤ fair value of shares burned
```

## Invariant Proofs

### Invariant 1: Vault Value Never Decreases

**Claim:** Any user operation cannot decrease vault's total value.

**Proof:**

Define vault value: `V = T_A - (all shares' fair value)`

Since shares represent proportional ownership:
```
Fair value of all shares = T_S × T_A / T_S = T_A
```

For vault to maintain solvency:
```
T_A ≥ (fair value of all issued shares)
```

After deposit:
```
T_A_new = T_A_old + A
T_S_new = T_S_old + ⌊(A × T_S_old) / T_A_old⌋

Fair value of new shares:
  = ⌊(A × T_S_old) / T_A_old⌋ × T_A_new / T_S_new

We proved earlier this ≤ A

Therefore: T_A_new ≥ fair value of new shares  ✓
```

### Invariant 2: Round-Trip Never Profits User

**Claim:** Deposit followed by immediate redeem cannot increase user's assets.

**Proof:**
```
User starts with A_0 assets

Step 1: Deposit A_0
  Receives: S = ⌊(A_0 × T_S) / T_A⌋

Step 2: Redeem S
  Receives: A_1 = ⌊(S × T_A) / T_S⌋
          = ⌊(⌊(A_0 × T_S) / T_A⌋ × T_A) / T_S⌋

Simplification:
  Let X = (A_0 × T_S) / T_A
  Then: S = ⌊X⌋

  A_1 = ⌊(⌊X⌋ × T_A) / T_S⌋
      ≤ ⌊(X × T_A) / T_S⌋    (since ⌊X⌋ ≤ X)
      = ⌊((A_0 × T_S / T_A) × T_A) / T_S⌋
      = ⌊A_0⌋
      = A_0

Conclusion: A_1 ≤ A_0  ✓
```

### Invariant 3: Share Ownership Percentage Bounded

**Claim:** No deposit can give user >50% ownership without >50% of total value.

**Proof:**
```
Let user deposit A assets
Receives S shares where S = ⌊(A × T_S) / T_A⌋

User's ownership percentage:
  P = S / (T_S + S)
    = ⌊(A × T_S) / T_A⌋ / (T_S + ⌊(A × T_S) / T_A⌋)
    ≤ ((A × T_S) / T_A) / (T_S + (A × T_S) / T_A)    (floor ≤ value)
    = (A × T_S) / (T_A × T_S + A × T_S)
    = A / (T_A + A)

For P > 0.5:
  A / (T_A + A) > 0.5
  2A > T_A + A
  A > T_A  ✓

Conclusion: User needs >50% of total value to get >50% ownership
```

## Precision Loss Analysis

### Single Operation Loss Bound

**Claim:** Each operation loses at most 1 unit of value due to rounding.

**Proof:**
```
For any division a / b with remainder r:
  ⌊a / b⌋ = (a - r) / b
  where 0 ≤ r < b

Maximum loss from rounding down:
  Loss = (a / b) - ⌊a / b⌋
       = (a / b) - (a - r) / b
       = r / b
       < b / b
       = 1  ✓

Similarly for round up:
  ⌈a / b⌉ = (a + (b - r - 1)) / b  (when r > 0)

Maximum overpayment:
  = ⌈a / b⌉ - (a / b)
  = (b - r - 1) / b
  < b / b
  = 1  ✓
```

### Cumulative Loss Bound

**Claim:** After n operations, total rounding loss < n units.

**Proof:**
```
Each operation loses < 1 unit (proved above)
n operations lose < n × 1 = n units  ✓
```

### Relative Precision Loss

**Claim:** For operations involving amount `A`, relative loss is `< 1/A`.

**Proof:**
```
Absolute loss: < 1 unit
Relative loss: < 1 / A  ✓

Example: For 1000 asset operation
  Relative loss < 1/1000 = 0.1%
```

## Exchange Rate Dynamics

### Exchange Rate Definition

```
R = T_A / T_S  (assets per share)
```

### Rate Change After Deposit

```
Before: R_0 = T_A / T_S
User deposits A, receives S = ⌊(A × T_S) / T_A⌋

After:
  T_A' = T_A + A
  T_S' = T_S + S

  R_1 = T_A' / T_S'
      = (T_A + A) / (T_S + S)

If perfect rounding (S = A × T_S / T_A):
  R_1 = (T_A + A) / (T_S + A × T_S / T_A)
      = (T_A + A) / (T_S × (1 + A / T_A))
      = (T_A × (1 + A / T_A)) / (T_S × (1 + A / T_A))
      = T_A / T_S
      = R_0  ✓

With rounding down (S ≤ A × T_S / T_A):
  R_1 = (T_A + A) / (T_S + S)
      ≥ (T_A + A) / (T_S + A × T_S / T_A)
      = R_0  ✓

Conclusion: Exchange rate increases or stays same after deposit
```

## Appendix: Alternative Formulations

### MulDiv with Full Precision

For very large numbers, `a × b` may overflow. Use:

```solidity
function mulDiv(uint256 a, uint256 b, uint256 denominator)
    internal pure returns (uint256 result)
{
    // Full precision multiply and divide
    uint256 prod0; // Least significant 256 bits
    uint256 prod1; // Most significant 256 bits

    assembly {
        let mm := mulmod(a, b, not(0))
        prod0 := mul(a, b)
        prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }

    // Handle overflow in numerator
    if (prod1 == 0) {
        return prod0 / denominator;
    }

    // ... complex 512-bit division
    // (See OpenZeppelin's Math.sol for full implementation)
}
```

### Fixed-Point Arithmetic Alternative

Instead of shares, use fixed-point representation:

```solidity
// Store user's ownership as fixed-point number
mapping(address => uint256) public ownership;  // in 1e18 units

function deposit(uint256 assets) public {
    uint256 ownershipShare = (assets * 1e18) / totalAssets();
    ownership[msg.sender] += ownershipShare;
}

function withdraw(uint256 ownership) public {
    uint256 assets = (ownership * totalAssets()) / 1e18;
    ownership[msg.sender] -= ownership;
    // transfer assets
}
```

Pros: More precision, no share tokens
Cons: Not ERC-20 compatible, complex accounting

## Conclusion

The mathematics of ERC-4626 vaults relies on:

1. **Proportional distribution**: Maintaining constant asset-to-share ratio
2. **Conservative rounding**: Always favoring vault in rounding decisions
3. **Bounded precision loss**: Each operation loses <1 unit of value
4. **Invariant preservation**: Vault value never decreases from user operations

These mathematical properties ensure vault security and user fairness.

## Further Reading

- [Solidity Fixed-Point Arithmetic](https://docs.soliditylang.org/en/latest/types.html#fixed-point-numbers)
- [OpenZeppelin Math Library](https://docs.openzeppelin.com/contracts/4.x/api/utils#Math)
- [EIP-4626 Specification](https://eips.ethereum.org/EIPS/eip-4626)
- [Numerical Precision in Smart Contracts](https://consensys.github.io/smart-contract-best-practices/development-recommendations/solidity-specific/integer-division/)

---

**Mathematics ensures security. Prove your code correct! 📐**
