# Inflation Attack Quick Reference

Quick reference guide for understanding and mitigating ERC-4626 inflation attacks.

## Attack Summary

**What**: Manipulating vault share price to cause victim deposits to round to zero shares
**How**: Minimal deposit + large donation = inflated price per share
**Impact**: Victim loses entire deposit, attacker captures funds
**Severity**: Critical (complete loss of funds)

## Attack Flow (4 Steps)

```
1. Deposit 1 wei → Get 1 share
   State: 1 share, 1 wei, price = 1 wei/share

2. Donate 1000 ether directly to vault
   State: 1 share, 1000 ether, price = 1000 ether/share

3. Victim deposits 999 ether
   Calculation: 999 * 1 / 1000 = 0 shares (rounds down!)
   State: 1 share, 1999 ether, victim has 0 shares

4. Redeem 1 share → Get all 1999 ether
   Profit: 999 ether (victim's deposit)
```

## Key Vulnerability

```solidity
// Standard share calculation
shares = assets * totalSupply / totalAssets

// When totalAssets >> totalSupply
// Small deposits round to zero!
// Example: 1000 * 1 / 1000000 = 0
```

## Why It Works

1. **Integer Division**: Solidity rounds down
2. **External Donations**: Can transfer tokens directly to vault
3. **Share Price**: Based on totalAssets / totalSupply ratio

## Three Main Mitigations

### 1. Virtual Shares/Assets (OpenZeppelin)

```solidity
shares = assets * (totalSupply + OFFSET) / (totalAssets + 1)
```

**Pros**: Elegant, no storage, widely used
**Cons**: Slightly reduced precision
**Best for**: General purpose vaults
**Protection**: Makes attack 10^offset times more expensive

### 2. Minimum First Deposit

```solidity
if (totalSupply == 0) {
    require(assets >= MIN_DEPOSIT);
}
```

**Pros**: Simple, clear economics
**Cons**: Friction for first user
**Best for**: Known asset value vaults
**Protection**: Forces large upfront capital commitment

### 3. Dead Shares

```solidity
if (totalSupply == 0) {
    _mint(DEAD_ADDRESS, DEAD_SHARES);
    _mint(receiver, assets - DEAD_SHARES);
}
```

**Pros**: Permanent protection, can't bypass
**Cons**: Small cost to first depositor
**Best for**: Maximum security vaults
**Protection**: Permanently inflates totalSupply

## Comparison Matrix

| Mitigation | Complexity | Gas Cost | Protection | User Impact |
|------------|-----------|----------|------------|-------------|
| Virtual Shares | Medium | Low | High | None |
| Min Deposit | Low | None | Medium | First user |
| Dead Shares | Medium | Low (once) | High | First user |
| None (Vulnerable) | N/A | N/A | **NONE** | **ALL USERS** |

## Economics

### Attack Cost
```
Total Cost = Initial Deposit + Donation
```

### Attack Profit
```
Profit = Victim Deposit - Donation - Initial Deposit
```

### Profitability Condition
```
Profitable when: Victim Deposit > Donation
```

### Example
- Attacker deposits: 1 wei
- Attacker donates: 1000 ether
- Victim deposits: 999 ether → Gets 0 shares
- Attacker profit: 999 - 1000 = -1 ether (LOSS!)

*Attack only works if victim deposits > donation amount*

## Detection Checklist

Look for these red flags in vault code:

- [ ] No minimum first deposit requirement
- [ ] No virtual shares/assets offset
- [ ] No dead shares initialization
- [ ] totalAssets() uses simple balance check
- [ ] No protection in _convertToShares()
- [ ] Direct transfers affect share price
- [ ] First deposit not specially handled

**If ANY are true → Potentially vulnerable!**

## Testing Checklist

Essential tests for vault security:

- [ ] Attack with 1 wei deposit + large donation
- [ ] Verify victim gets 0 shares
- [ ] Test with various donation amounts
- [ ] Check economic boundaries
- [ ] Verify mitigation prevents attack
- [ ] Test first depositor experience
- [ ] Check gas costs
- [ ] Test edge cases (max values, dust)

## Code Snippets

### Vulnerable Pattern
```solidity
function totalAssets() public view returns (uint256) {
    return token.balanceOf(address(this)); // Includes donations!
}

function _convertToShares(uint256 assets) internal view returns (uint256) {
    return assets * totalSupply() / totalAssets(); // Can round to 0!
}
```

### Protected Pattern (Virtual Shares)
```solidity
function _convertToShares(uint256 assets) internal view returns (uint256) {
    uint256 offset = 10 ** 3; // 1000 virtual shares
    return assets.mulDiv(
        totalSupply() + offset,
        totalAssets() + 1,
        rounding
    );
}
```

### Protected Pattern (Dead Shares)
```solidity
function deposit(uint256 assets, address receiver) public returns (uint256) {
    if (!initialized) {
        _mint(DEAD_ADDRESS, DEAD_SHARES);
        initialized = true;
        return assets - DEAD_SHARES;
    }
    return previewDeposit(assets);
}
```

## Real-World Impact

### Historical Incidents
- Rari Capital Fuse (2022) - Theoretical vulnerability found
- Various early ERC-4626 implementations - Many vulnerable
- Industry-wide awareness raised after research

### Current Status
- OpenZeppelin: Protected (virtual shares)
- Solmate: Documented, not protected by default
- Most modern vaults: Include some protection
- Still found in audits: Common finding

## Best Practices

### For Developers
1. ✅ Use OpenZeppelin ERC4626 (includes protection)
2. ✅ Consider combining multiple mitigations
3. ✅ Test with attack scenarios
4. ✅ Get professional audit
5. ✅ Document mitigation choice

### For Auditors
1. ✅ Check for inflation attack protection
2. ✅ Verify first deposit handling
3. ✅ Test economic boundaries
4. ✅ Review totalAssets() implementation
5. ✅ Confirm share calculation safety

### For Users
1. ✅ Check if vault is audited
2. ✅ Verify mitigation strategy
3. ✅ Avoid being first depositor on new vaults
4. ✅ Monitor share price before large deposits
5. ✅ Prefer established, audited vaults

## Quick Calculation Tool

To check if attack would work:

```python
def check_attack(deposit, donation, victim_deposit):
    total_supply = 1  # After attacker's initial deposit
    total_assets = deposit + donation

    # Calculate victim's shares
    victim_shares = (victim_deposit * total_supply) // total_assets

    if victim_shares == 0:
        profit = victim_deposit - donation - deposit
        print(f"Attack succeeds! Profit: {profit}")
    else:
        print(f"Attack fails. Victim gets {victim_shares} shares")

# Example
check_attack(1, 1000e18, 999e18)  # Output: Attack succeeds! Profit: 999e18 - 1e18
```

## Common Misconceptions

❌ **Myth**: "Share price manipulation is just theoretical"
✅ **Reality**: Mathematically proven and demonstrated

❌ **Myth**: "Users won't fall for this"
✅ **Reality**: Automated systems and bots are vulnerable

❌ **Myth**: "Small vaults don't need protection"
✅ **Reality**: ALL vaults need protection regardless of size

❌ **Myth**: "One mitigation is always enough"
✅ **Reality**: Depends on context; high-value may need multiple

❌ **Myth**: "This only affects first depositor"
✅ **Reality**: Affects ALL subsequent depositors if attack succeeds

## Emergency Response

If you discover your vault is vulnerable:

1. **Immediate**: Pause deposits if possible
2. **Alert**: Notify users and security contacts
3. **Assess**: Check if attack has occurred
4. **Fix**: Deploy protected version
5. **Migrate**: Move users to new vault
6. **Post-mortem**: Document and learn

## Additional Resources

### Standards
- [EIP-4626](https://eips.ethereum.org/EIPS/eip-4626)
- [OpenZeppelin ERC4626](https://docs.openzeppelin.com/contracts/4.x/erc4626)

### Research
- [OpenZeppelin Blog: Novel Defense](https://blog.openzeppelin.com/a-novel-defense-against-erc4626-inflation-attacks)
- [MixBytes: Inflation Attack Overview](https://mixbytes.io/blog/overview-of-the-inflation-attack)

### Tools
- [Slither](https://github.com/crytic/slither) - Static analyzer
- [Mythril](https://github.com/ConsenSys/mythril) - Security analysis
- [Foundry](https://book.getfoundry.sh/) - Testing framework

## Key Takeaway

🔑 **Always protect your ERC-4626 vaults against inflation attacks**

The mitigation is simple, but the vulnerability is critical. There's no excuse for launching an unprotected vault in production.

---

*For detailed explanations, see README.md
For implementation guide, see SETUP.md
For complete code, see src/solution/Project44Solution.sol*
