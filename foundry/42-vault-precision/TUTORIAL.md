# ERC-4626 Vault Implementation Tutorial

## Step-by-Step Guide to Implementing Precise Rounding

This tutorial walks you through implementing the critical rounding logic for a secure ERC-4626 vault.

## Understanding the Challenge

### The Core Problem

When converting between assets and shares, we often get fractional results:
- 100 assets → 66.666... shares
- 67 shares → 100.5 assets

Solidity doesn't support decimals, so we must round. The direction we round determines who benefits: the user or the vault.

**Security Rule**: Always round in the vault's favor to prevent exploits.

## Step 1: Implement `mulDiv` (Round Down)

This is straightforward - Solidity's default division rounds down.

```solidity
function mulDiv(
    uint256 x,
    uint256 y,
    uint256 denominator
) internal pure returns (uint256 result) {
    // Solidity automatically rounds down
    result = (x * y) / denominator;
}
```

**Example**:
```
mulDiv(5, 3, 2) = 15 / 2 = 7  (not 7.5)
```

## Step 2: Implement `mulDivUp` (Round Up)

This is the critical function for vault security.

### The Math

To round up, we add `(denominator - 1)` before dividing:

```
roundUp(a/b) = (a + b - 1) / b
```

### Why It Works

When dividing `a` by `b`:
- If `a % b == 0` (exact division): `(a + b - 1) / b = a/b` (no change)
- If `a % b > 0` (has remainder): `(a + b - 1) / b = a/b + 1` (rounds up)

### Implementation Options

**Option 1: Explicit Check (Clearer)**
```solidity
function mulDivUp(
    uint256 x,
    uint256 y,
    uint256 denominator
) internal pure returns (uint256 result) {
    uint256 product = x * y;
    result = product / denominator;

    // If there's a remainder, add 1
    if (product % denominator > 0) {
        result += 1;
    }
}
```

**Option 2: Formula (More Efficient)**
```solidity
function mulDivUp(
    uint256 x,
    uint256 y,
    uint256 denominator
) internal pure returns (uint256 result) {
    result = (x * y + denominator - 1) / denominator;
}
```

Both are correct. Option 1 is clearer for learning; Option 2 uses less gas.

## Step 3: Implement `convertToShares`

Converts assets to shares, used by `deposit` and `previewDeposit`.

**Must round DOWN** (fewer shares to user = vault favorable)

```solidity
function convertToShares(uint256 assets) public view returns (uint256) {
    uint256 supply = totalSupply();

    // Edge case: Empty vault, 1:1 ratio
    if (supply == 0) {
        return assets;
    }

    // Normal case: Round DOWN
    // shares = (assets * totalSupply) / totalAssets
    return mulDiv(assets, supply, totalAssets());
}
```

**Why round down?**
- User deposits 100 assets
- Gets 66.666... shares
- Round DOWN to 66 shares
- Vault keeps the 0.666... share worth of value

## Step 4: Implement `convertToAssets`

Converts shares to assets, used by `redeem` and `previewRedeem`.

**Must round DOWN** (fewer assets to user = vault favorable)

```solidity
function convertToAssets(uint256 shares) public view returns (uint256) {
    uint256 supply = totalSupply();

    // Edge case: No shares exist, no value
    if (supply == 0) {
        return 0;
    }

    // Normal case: Round DOWN
    // assets = (shares * totalAssets) / totalSupply
    return mulDiv(shares, totalAssets(), supply);
}
```

**Why round down?**
- User redeems 67 shares
- Gets 100.5 assets
- Round DOWN to 100 assets
- Vault keeps the 0.5 asset

## Step 5: Implement Preview Functions

Preview functions MUST match the rounding of their corresponding actions.

### `previewDeposit` - Round DOWN

```solidity
function previewDeposit(uint256 assets) public view returns (uint256) {
    // Reuse convertToShares (already rounds down)
    return convertToShares(assets);
}
```

### `previewMint` - Round UP

```solidity
function previewMint(uint256 shares) public view returns (uint256) {
    uint256 supply = totalSupply();

    if (supply == 0) {
        return shares;  // 1:1 for empty vault
    }

    // Round UP - user must pay enough
    // assets = roundUp((shares * totalAssets) / totalSupply)
    return mulDivUp(shares, totalAssets(), supply);
}
```

**Why round up?**
- User wants exactly 66 shares
- Costs 99.001 assets
- Round UP to 100 assets
- User pays more = vault favorable

### `previewWithdraw` - Round UP

```solidity
function previewWithdraw(uint256 assets) public view returns (uint256) {
    uint256 supply = totalSupply();

    if (supply == 0) {
        return 0;
    }

    // Round UP - user must burn enough shares
    // shares = roundUp((assets * totalSupply) / totalAssets)
    return mulDivUp(assets, supply, totalAssets());
}
```

**Why round up?**
- User wants exactly 100 assets
- Costs 66.666... shares
- Round UP to 67 shares
- User burns more = vault favorable

### `previewRedeem` - Round DOWN

```solidity
function previewRedeem(uint256 shares) public view returns (uint256) {
    // Reuse convertToAssets (already rounds down)
    return convertToAssets(shares);
}
```

## Step 6: Implement `deposit`

```solidity
function deposit(uint256 assets, address receiver) public returns (uint256 shares) {
    // Step 1: Calculate shares (rounds down)
    shares = convertToShares(assets);

    // Ensure we mint something
    require(shares > 0, "ERC4626: cannot mint 0 shares");

    // Step 2: Transfer assets from user
    _asset.safeTransferFrom(msg.sender, address(this), assets);

    // Step 3: Mint shares
    _mint(receiver, shares);

    // Step 4: Emit event
    emit Deposit(msg.sender, receiver, assets, shares);
}
```

## Step 7: Implement `mint`

```solidity
function mint(uint256 shares, address receiver) public returns (uint256 assets) {
    // Step 1: Calculate assets needed (rounds up)
    assets = previewMint(shares);

    // Step 2: Transfer assets from user
    _asset.safeTransferFrom(msg.sender, address(this), assets);

    // Step 3: Mint exact shares
    _mint(receiver, shares);

    // Step 4: Emit event
    emit Deposit(msg.sender, receiver, assets, shares);
}
```

## Step 8: Implement `withdraw`

```solidity
function withdraw(
    uint256 assets,
    address receiver,
    address owner
) public returns (uint256 shares) {
    // Step 1: Calculate shares to burn (rounds up)
    shares = previewWithdraw(assets);

    // Step 2: Handle allowance if needed
    _spendAllowance(owner, shares);

    // Step 3: Burn shares
    _burn(owner, shares);

    // Step 4: Transfer exact assets
    _asset.safeTransfer(receiver, assets);

    // Step 5: Emit event
    emit Withdraw(msg.sender, receiver, owner, assets, shares);
}
```

## Step 9: Implement `redeem`

```solidity
function redeem(
    uint256 shares,
    address receiver,
    address owner
) public returns (uint256 assets) {
    // Step 1: Calculate assets to give (rounds down)
    assets = convertToAssets(shares);

    // Step 2: Handle allowance if needed
    _spendAllowance(owner, shares);

    // Step 3: Burn shares
    _burn(owner, shares);

    // Step 4: Transfer assets
    _asset.safeTransfer(receiver, assets);

    // Step 5: Emit event
    emit Withdraw(msg.sender, receiver, owner, assets, shares);
}
```

## Step 10: Implement `_spendAllowance` Helper

```solidity
function _spendAllowance(address owner, uint256 shares) internal {
    // Only check allowance if caller is not owner
    if (msg.sender != owner) {
        uint256 currentAllowance = allowance(owner, msg.sender);

        // Don't decrease infinite allowances
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= shares, "ERC4626: insufficient allowance");
            _approve(owner, msg.sender, currentAllowance - shares);
        }
    }
}
```

## Verification Checklist

After implementing, verify:

### ✅ Rounding Direction
- [ ] `deposit` rounds DOWN shares
- [ ] `mint` rounds UP assets
- [ ] `withdraw` rounds UP shares
- [ ] `redeem` rounds DOWN assets

### ✅ Preview Matches Action
- [ ] `previewDeposit` matches `deposit`
- [ ] `previewMint` matches `mint`
- [ ] `previewWithdraw` matches `withdraw`
- [ ] `previewRedeem` matches `redeem`

### ✅ Edge Cases
- [ ] Empty vault (totalSupply == 0) handled
- [ ] Zero denominators prevented
- [ ] Very small amounts don't break

### ✅ Security
- [ ] User can't profit from round-trip (deposit + redeem)
- [ ] Vault value never decreases from user operations
- [ ] No division by zero possible

## Testing Your Implementation

### Test Rounding Direction

```solidity
function testDepositRoundsDown() public {
    // Setup: 1000 shares : 1500 assets (1.5:1 ratio)
    vault.deposit(1000 ether, alice);
    asset.mint(address(vault), 500 ether);

    // Bob deposits 100 assets
    // Expected: 100 * 1000 / 1500 = 66.666... → 66
    uint256 shares = vault.deposit(100 ether, bob);

    assertEq(shares, 66, "Should round down to 66");
}
```

### Test Preview Matches Action

```solidity
function testPreviewMatchesDeposit() public {
    vault.deposit(1000 ether, alice);

    uint256 previewShares = vault.previewDeposit(100 ether);
    uint256 actualShares = vault.deposit(100 ether, bob);

    assertEq(actualShares, previewShares, "Preview must match");
}
```

### Test No Profit from Round-Trip

```solidity
function testNoRoundTripProfit() public {
    vault.deposit(1000 ether, alice);

    uint256 startBalance = asset.balanceOf(bob);

    // Bob deposits and immediately redeems
    uint256 shares = vault.deposit(100 ether, bob);
    vault.redeem(shares, bob, bob);

    uint256 endBalance = asset.balanceOf(bob);

    // Bob should have ≤ starting balance
    assertLe(endBalance, startBalance);
}
```

## Common Mistakes to Avoid

### ❌ Mistake 1: Wrong Rounding Direction

```solidity
// WRONG: Rounds UP shares for deposit
shares = mulDivUp(assets, totalSupply(), totalAssets());

// RIGHT: Rounds DOWN shares for deposit
shares = mulDiv(assets, totalSupply(), totalAssets());
```

### ❌ Mistake 2: Preview Doesn't Match Action

```solidity
// WRONG: previewWithdraw rounds down
function previewWithdraw(uint256 assets) public view returns (uint256) {
    return convertToShares(assets);  // This rounds DOWN
}

// RIGHT: previewWithdraw rounds up (matches withdraw)
function previewWithdraw(uint256 assets) public view returns (uint256) {
    return mulDivUp(assets, totalSupply(), totalAssets());  // Rounds UP
}
```

### ❌ Mistake 3: Not Handling Edge Cases

```solidity
// WRONG: Division by zero possible
function convertToShares(uint256 assets) public view returns (uint256) {
    return mulDiv(assets, totalSupply(), totalAssets());  // Reverts if totalAssets == 0
}

// RIGHT: Handle empty vault
function convertToShares(uint256 assets) public view returns (uint256) {
    uint256 supply = totalSupply();
    if (supply == 0) return assets;  // 1:1 for empty vault
    return mulDiv(assets, supply, totalAssets());
}
```

## Advanced: Understanding the Attack Scenarios

### Inflation Attack Example

```solidity
// Attacker's exploit:
vault.deposit(1, attacker);              // Get 1 share
asset.transfer(address(vault), 10000e18); // Donate 10000 tokens
// Now 1 share = 10000 tokens

// Victim deposits
vault.deposit(19999e18, victim);
// Shares = 19999e18 * 1 / 10000e18 ≈ 1.999 → rounds to 1
// Victim gets only 1 share for 19999 tokens!

// Attacker withdraws
vault.redeem(1, attacker);
// Gets ~15000 tokens (half of total ~30000)
// Profit: ~5000 tokens stolen from victim
```

**Prevention**:
- Require minimum first deposit
- Use virtual shares/assets (ERC4626 extensions)
- Lock initial liquidity

## Summary

The key to secure ERC-4626 vaults is **consistent rounding in the vault's favor**:

| Function | User Gives | User Gets | Round Direction | Why |
|----------|-----------|-----------|-----------------|-----|
| deposit  | assets    | shares    | DOWN (shares)   | Fewer shares to user |
| mint     | assets    | shares    | UP (assets)     | More assets from user |
| withdraw | shares    | assets    | UP (shares)     | More shares from user |
| redeem   | shares    | assets    | DOWN (assets)   | Fewer assets to user |

**Remember**: Every rounding decision should favor the vault. If unsure, ask: "Does this rounding give the vault less value?" If yes, it's wrong!

Happy building! 🏦
