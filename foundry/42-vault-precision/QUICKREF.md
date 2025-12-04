# ERC-4626 Vault Quick Reference

## 🎯 Golden Rule

**ALWAYS ROUND IN VAULT'S FAVOR**

## 📊 Rounding Table

| Function | User Gives | User Gets | Formula | Round Direction | Why |
|----------|-----------|-----------|---------|-----------------|-----|
| `deposit` | assets | shares | `shares = (assets × supply) / totalAssets` | ⬇️ DOWN | Fewer shares = vault keeps more |
| `mint` | assets | shares | `assets = (shares × totalAssets) / supply` | ⬆️ UP | More assets = vault gets more |
| `withdraw` | shares | assets | `shares = (assets × supply) / totalAssets` | ⬆️ UP | More shares = vault loses less |
| `redeem` | shares | assets | `assets = (shares × totalAssets) / supply` | ⬇️ DOWN | Fewer assets = vault keeps more |

## 🔧 Implementation Snippets

### Round Down (mulDiv)

```solidity
function mulDiv(uint256 x, uint256 y, uint256 denominator)
    internal pure returns (uint256)
{
    return (x * y) / denominator;  // Solidity default = round down
}
```

### Round Up (mulDivUp)

```solidity
function mulDivUp(uint256 x, uint256 y, uint256 denominator)
    internal pure returns (uint256 result)
{
    result = (x * y) / denominator;
    if ((x * y) % denominator > 0) {
        result += 1;  // Add 1 if remainder exists
    }
}

// Alternative one-liner:
// return (x * y + denominator - 1) / denominator;
```

### convertToShares (Round DOWN)

```solidity
function convertToShares(uint256 assets) public view returns (uint256) {
    uint256 supply = totalSupply();
    if (supply == 0) return assets;  // 1:1 for empty vault
    return mulDiv(assets, supply, totalAssets());  // Round DOWN
}
```

### convertToAssets (Round DOWN)

```solidity
function convertToAssets(uint256 shares) public view returns (uint256) {
    uint256 supply = totalSupply();
    if (supply == 0) return 0;  // No shares = no value
    return mulDiv(shares, totalAssets(), supply);  // Round DOWN
}
```

### previewDeposit (Round DOWN)

```solidity
function previewDeposit(uint256 assets) public view returns (uint256) {
    return convertToShares(assets);  // Same as deposit
}
```

### previewMint (Round UP)

```solidity
function previewMint(uint256 shares) public view returns (uint256) {
    uint256 supply = totalSupply();
    if (supply == 0) return shares;  // 1:1 for empty vault
    return mulDivUp(shares, totalAssets(), supply);  // Round UP
}
```

### previewWithdraw (Round UP)

```solidity
function previewWithdraw(uint256 assets) public view returns (uint256) {
    uint256 supply = totalSupply();
    if (supply == 0) return 0;
    return mulDivUp(assets, supply, totalAssets());  // Round UP
}
```

### previewRedeem (Round DOWN)

```solidity
function previewRedeem(uint256 shares) public view returns (uint256) {
    return convertToAssets(shares);  // Same as redeem
}
```

### deposit Implementation

```solidity
function deposit(uint256 assets, address receiver)
    public returns (uint256 shares)
{
    shares = convertToShares(assets);  // Round DOWN
    require(shares > 0, "Zero shares");

    _asset.safeTransferFrom(msg.sender, address(this), assets);
    _mint(receiver, shares);

    emit Deposit(msg.sender, receiver, assets, shares);
}
```

### mint Implementation

```solidity
function mint(uint256 shares, address receiver)
    public returns (uint256 assets)
{
    assets = previewMint(shares);  // Round UP

    _asset.safeTransferFrom(msg.sender, address(this), assets);
    _mint(receiver, shares);

    emit Deposit(msg.sender, receiver, assets, shares);
}
```

### withdraw Implementation

```solidity
function withdraw(uint256 assets, address receiver, address owner)
    public returns (uint256 shares)
{
    shares = previewWithdraw(assets);  // Round UP

    _spendAllowance(owner, shares);
    _burn(owner, shares);
    _asset.safeTransfer(receiver, assets);

    emit Withdraw(msg.sender, receiver, owner, assets, shares);
}
```

### redeem Implementation

```solidity
function redeem(uint256 shares, address receiver, address owner)
    public returns (uint256 assets)
{
    assets = convertToAssets(shares);  // Round DOWN

    _spendAllowance(owner, shares);
    _burn(owner, shares);
    _asset.safeTransfer(receiver, assets);

    emit Withdraw(msg.sender, receiver, owner, assets, shares);
}
```

### _spendAllowance Helper

```solidity
function _spendAllowance(address owner, uint256 shares) internal {
    if (msg.sender != owner) {
        uint256 allowed = allowance(owner, msg.sender);
        if (allowed != type(uint256).max) {
            require(allowed >= shares, "Insufficient allowance");
            _approve(owner, msg.sender, allowed - shares);
        }
    }
}
```

## 🧪 Testing Checklist

### Rounding Direction Tests

```solidity
// Deposit rounds DOWN shares
assertEq(vault.deposit(100 ether, user), 66);  // Not 67

// Mint rounds UP assets
assertEq(vault.mint(67, user), 101 ether);  // Not 100

// Withdraw rounds UP shares
assertEq(vault.withdraw(100 ether, user, user), 67);  // Not 66

// Redeem rounds DOWN assets
assertEq(vault.redeem(67, user, user), 100 ether);  // Not 101
```

### Preview Matches Action

```solidity
uint256 preview = vault.previewDeposit(100 ether);
uint256 actual = vault.deposit(100 ether, user);
assertEq(actual, preview);
```

### No Round-Trip Profit

```solidity
uint256 start = asset.balanceOf(user);
uint256 shares = vault.deposit(100 ether, user);
vault.redeem(shares, user, user);
uint256 end = asset.balanceOf(user);
assertLe(end, start);  // User cannot profit
```

### Edge Cases

```solidity
// Empty vault
assertEq(vault.convertToShares(100), 100);  // 1:1

// No shares exist
assertEq(vault.convertToAssets(100), 0);  // No value

// Zero deposit
vm.expectRevert("Zero shares");
vault.deposit(0, user);
```

## ⚠️ Common Mistakes

### ❌ Wrong Rounding Direction

```solidity
// WRONG
function deposit(uint256 assets) returns (uint256 shares) {
    shares = mulDivUp(assets, totalSupply(), totalAssets());  // ❌
}

// RIGHT
function deposit(uint256 assets) returns (uint256 shares) {
    shares = mulDiv(assets, totalSupply(), totalAssets());  // ✅
}
```

### ❌ Preview Doesn't Match

```solidity
// WRONG
function previewWithdraw(uint256 assets) returns (uint256) {
    return convertToShares(assets);  // ❌ Rounds DOWN, but withdraw rounds UP
}

// RIGHT
function previewWithdraw(uint256 assets) returns (uint256) {
    return mulDivUp(assets, totalSupply(), totalAssets());  // ✅
}
```

### ❌ Missing Edge Cases

```solidity
// WRONG
function convertToShares(uint256 assets) returns (uint256) {
    return mulDiv(assets, totalSupply(), totalAssets());  // ❌ Division by zero!
}

// RIGHT
function convertToShares(uint256 assets) returns (uint256) {
    uint256 supply = totalSupply();
    if (supply == 0) return assets;  // ✅ Handle empty vault
    return mulDiv(assets, supply, totalAssets());
}
```

## 🛡️ Security Patterns

### First Deposit Protection

```solidity
// Minimum first deposit
if (totalSupply() == 0) {
    require(shares >= 1e6, "First deposit too small");
}

// Or use virtual shares
function convertToShares(uint256 assets) public view returns (uint256) {
    return (assets * (totalSupply() + 1)) / (totalAssets() + 1);
}

// Or lock initial liquidity
constructor() {
    _mint(address(0), 1000);  // Dead shares
}
```

### Reentrancy Protection

```solidity
// Follow Checks-Effects-Interactions
function deposit(uint256 assets) public returns (uint256 shares) {
    // 1. CHECKS
    shares = convertToShares(assets);
    require(shares > 0);

    // 2. EFFECTS (update state first!)
    _mint(receiver, shares);

    // 3. INTERACTIONS (external calls last)
    _asset.safeTransferFrom(msg.sender, address(this), assets);
}
```

## 📝 Function Summary

### Core Accounting
- `totalAssets()` - Total assets under management
- `convertToShares(assets)` - Assets → Shares (round DOWN)
- `convertToAssets(shares)` - Shares → Assets (round DOWN)

### Preview Functions (Match Action Rounding!)
- `previewDeposit(assets)` - Round DOWN
- `previewMint(shares)` - Round UP
- `previewWithdraw(assets)` - Round UP
- `previewRedeem(shares)` - Round DOWN

### User Actions
- `deposit(assets, receiver)` - Deposit assets, get shares (round DOWN)
- `mint(shares, receiver)` - Get shares, pay assets (round UP)
- `withdraw(assets, receiver, owner)` - Get assets, burn shares (round UP)
- `redeem(shares, receiver, owner)` - Burn shares, get assets (round DOWN)

### Limits (Max Operations)
- `maxDeposit(owner)` - Max assets depositable
- `maxMint(owner)` - Max shares mintable
- `maxWithdraw(owner)` - Max assets withdrawable
- `maxRedeem(owner)` - Max shares redeemable

## 🎓 Remember

1. **Round DOWN** when giving to user (shares in deposit, assets in redeem)
2. **Round UP** when taking from user (assets in mint, shares in withdraw)
3. **Preview = Action** in rounding direction
4. **Handle edge cases** (empty vault, zero values)
5. **Test thoroughly** (all rounding scenarios, edge cases, attacks)

## 📚 Quick Links

- [Full Tutorial](./TUTORIAL.md)
- [Attack Scenarios](./ATTACKS.md)
- [Mathematical Proofs](./MATH.md)
- [EIP-4626 Spec](https://eips.ethereum.org/EIPS/eip-4626)

---

**Build secure vaults! 🏦**
