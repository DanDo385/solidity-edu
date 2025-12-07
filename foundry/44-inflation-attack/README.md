# Project 44: ERC-4626 Inflation Attack Demo

A comprehensive educational project demonstrating the inflation attack vulnerability in ERC-4626 vaults and various mitigation strategies.

## Overview

The inflation attack (also known as the donation attack or first depositor attack) is a critical vulnerability that can affect ERC-4626 vault implementations. This attack exploits the share calculation mechanism to steal funds from depositors through share price manipulation.

## What is an Inflation Attack? Share Price Manipulation

**FIRST PRINCIPLES: Rounding Exploitation**

An inflation attack occurs when an attacker manipulates the share price of a vault to cause rounding errors that work in their favor. This is a critical vulnerability in ERC-4626 vaults!

**CONNECTION TO PROJECT 11, 20, & 42**:
- **Project 11**: ERC-4626 vault standard
- **Project 20**: Share-based accounting fundamentals
- **Project 42**: Rounding precision and security
- **Project 44**: Inflation attack exploits rounding vulnerabilities!

**UNDERSTANDING THE ATTACK**:

The attack exploits the fundamental share calculation in ERC-4626:

```solidity
shares = assets * totalSupply / totalAssets  // From Project 11 & 20!
```

**THE VULNERABILITY**:

When `totalAssets` is much larger than `totalSupply`, small deposits can round down to zero shares, effectively donating the deposited assets to existing shareholders.

**HOW IT WORKS** (Mathematical Exploitation):

```
Normal State:
┌─────────────────────────────────────────┐
│ totalAssets = 1000                      │
│ totalShares = 1000                      │
│ Exchange rate: 1.0                      │
│                                          │
│ User deposits: 100 assets               │
│   shares = (100 * 1000) / 1000 = 100   │ ← Works fine
└─────────────────────────────────────────┘

Attacked State:
┌─────────────────────────────────────────┐
│ Attacker deposits: 1 wei                │
│   shares = 1 (first deposit)            │
│   totalAssets = 1 wei                    │
│   totalShares = 1                        │
│   ↓                                      │
│ Attacker donates: 1,000,000 tokens      │ ← Direct transfer!
│   totalAssets = 1,000,001 wei           │ ← Inflated!
│   totalShares = 1 (unchanged!)          │ ← Not increased!
│   Exchange rate: 1,000,001 wei/share   │ ← Manipulated!
│   ↓                                      │
│ Victim deposits: 1,000,000 wei          │
│   shares = (1,000,000 * 1) / 1,000,001  │
│   shares = 0.999999...                   │
│   shares = 0 (rounds down!)            │ ← Gets nothing!
│   ↓                                      │
│ Attacker redeems 1 share:              │
│   assets = (1 * 2,000,001) / 1 = 2,000,001│
│   Attacker gets victim's deposit! 💥    │
└─────────────────────────────────────────┘
```

**WHY IT WORKS**:

The attack exploits three key properties:

1. **Integer Division** (from Project 01): Solidity uses integer math, which rounds down
   - `999,999 / 1,000,000 = 0` (rounds down to zero!)

2. **External Donations**: Tokens can be sent directly to the vault
   - From Project 02: Contracts can receive tokens via `receive()` or direct transfer
   - Donation increases `totalAssets` without minting shares!

3. **Share Price Calculation**: Price = totalAssets / totalSupply
   - When assets >> shares, price is very high
   - Small deposits result in fractional shares
   - Fractional shares round down to zero!

**REAL-WORLD ANALOGY**: 
Like manipulating a stock price by donating shares to the company, then buying at the inflated price. The donation inflates the price, making small purchases worthless!

## Attack Mechanism

### Step-by-Step Attack Flow

1. **Initial Deposit (Attacker)**
   - Attacker deposits minimal amount (e.g., 1 wei)
   - Receives 1 share in return
   - State: 1 share, 1 wei assets, price = 1 wei/share

2. **Donation (Attacker)**
   - Attacker transfers large amount directly to vault (not via deposit)
   - This bypasses the normal share minting
   - State: 1 share, 1,000,001 wei assets, price = 1,000,001 wei/share

3. **Victim Deposit**
   - Victim deposits 1,000,000 wei
   - Share calculation: `1,000,000 * 1 / 1,000,001 = 0.999999...`
   - Rounds down to 0 shares!
   - State: 1 share, 2,000,001 wei assets

4. **Profit (Attacker)**
   - Attacker redeems their 1 share
   - Receives all 2,000,001 wei
   - Profit: 1,000,000 wei (victim's deposit minus attacker's costs)

### Why It Works

The attack exploits three key properties:

1. **Integer Division**: Solidity uses integer math, which rounds down
2. **External Donations**: Tokens can be sent directly to the vault
3. **Share Price Calculation**: Price = totalAssets / totalSupply

When the attacker inflates totalAssets without increasing totalSupply, they create a situation where small deposits result in fractional shares that round to zero.

## Economic Analysis

### Attack Cost vs Profit

For an attack to be profitable:
- `victimDeposit > attackerDonation + attackerInitialDeposit`

If the attacker donates D and initially deposits I:
- To steal deposit V, the victim must receive 0 shares
- This requires: `V < (totalAssets / totalSupply) = (D + I) / I`
- Simplifying: `V * I < D + I`

The attacker profits when `V > D`, meaning the victim deposits more than the attacker donated.

### Making Attacks Expensive

By requiring a larger initial deposit or burning initial shares, we force the attacker to put more capital at risk, making the attack economically unfeasible for most scenarios.

## Mitigation Strategies

### 1. Virtual Shares and Assets (OpenZeppelin Approach)

Add a virtual offset to share calculations:

```solidity
function _convertToShares(uint256 assets, Math.Rounding rounding)
    internal
    view
    returns (uint256)
{
    return assets.mulDiv(
        totalSupply() + 10 ** _decimalsOffset(),
        totalAssets() + 1,
        rounding
    );
}
```

**How it works:**
- Adds virtual shares (10^offset) and 1 virtual asset to calculations
- Makes initial inflation much more expensive
- For offset=3, attacker needs 1000x more capital

**Advantages:**
- Elegant mathematical solution
- No storage overhead
- Compatible with existing contracts

**Trade-offs:**
- Slightly reduces share precision
- Requires careful offset selection

### 2. Minimum Deposit Requirement

Require substantial first deposit:

```solidity
if (totalSupply() == 0) {
    require(assets >= MIN_FIRST_DEPOSIT, "First deposit too small");
}
```

**How it works:**
- Forces first depositor to commit significant capital
- Makes the attack require large upfront investment
- Simple to implement and understand

**Advantages:**
- Easy to implement
- Clear security guarantee

**Trade-offs:**
- Creates friction for first user
- Requires governance to set appropriate minimum
- May need to vary by asset price

### 3. Dead Shares Pattern

Burn initial shares permanently:

```solidity
if (totalSupply() == 0) {
    shares = assets - BURN_AMOUNT;
    _mint(DEAD_ADDRESS, BURN_AMOUNT);
    _mint(receiver, shares);
} else {
    shares = _convertToShares(assets);
    _mint(receiver, shares);
}
```

**How it works:**
- First deposit mints some shares to dead address
- These shares are never redeemable
- Inflates totalSupply without being controlled by attacker

**Advantages:**
- Permanent protection
- No ongoing gas cost
- Works with any asset

**Trade-offs:**
- Small loss for first depositor
- Need to choose appropriate burn amount
- Slightly more complex initialization

### 4. Decimals Offset (Combined with Virtual Shares)

Use higher precision for shares than assets:

```solidity
function decimals() public view override returns (uint8) {
    return _asset.decimals() + _decimalsOffset;
}
```

**How it works:**
- Shares have more decimals than underlying asset
- Creates automatic offset in calculations
- Reduces rounding errors

**Advantages:**
- Elegant solution
- Improves precision for all operations

**Trade-offs:**
- May confuse users expecting 1:1 decimals
- Requires frontend awareness

## Real-World Examples

### Incidents

1. **Rari Capital Fuse Pools (2022)**
   - Some pools were vulnerable to inflation attacks
   - No major exploitation reported
   - Led to industry awareness

2. **Various ERC-4626 Implementations**
   - Many early implementations were vulnerable
   - Security audits increasingly check for this
   - Now considered critical issue

### Industry Response

- **OpenZeppelin**: Added virtual shares/assets to ERC-4626 implementation
- **Solmate**: Documented the issue, left mitigation to developers
- **EIP-4626**: Security considerations section added
- **Audit Checklist**: Standard item in vault audits

## Best Practices

### For Vault Developers

1. **Always Mitigate**: Don't launch unprotected vaults
2. **Use Proven Libraries**: OpenZeppelin ERC-4626 includes protections
3. **Consider Context**: Choose mitigation based on your use case
4. **Test Thoroughly**: Include inflation attack tests
5. **Audit**: Have security experts review vault logic

### Choosing a Mitigation

- **High-value vaults**: Use virtual shares/assets + decimals offset
- **Simple vaults**: Minimum deposit requirement may suffice
- **Maximum security**: Combine multiple strategies
- **Public vaults**: Dead shares pattern prevents privileged first depositor

### Testing Strategy

Always test:
1. Attack scenario with minimal deposit + donation
2. Share calculation edge cases
3. First depositor experience
4. Gas costs of mitigation
5. Interaction with other vault features

## Implementation Guide

### Using OpenZeppelin (Recommended)

```solidity
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract SafeVault is ERC4626 {
    constructor(IERC20 asset)
        ERC4626(asset)
        ERC20("Safe Vault", "sVAULT")
    {
        // OpenZeppelin ERC4626 includes virtual shares protection
    }

    function _decimalsOffset() internal pure override returns (uint8) {
        return 3; // Add offset for extra protection
    }
}
```

### Custom Implementation with Dead Shares

```solidity
contract CustomVault is ERC4626 {
    uint256 private constant DEAD_SHARES = 1000;
    address private constant DEAD_ADDRESS = address(0xdead);

    function deposit(uint256 assets, address receiver)
        public
        override
        returns (uint256)
    {
        uint256 shares;

        if (totalSupply() == 0) {
            shares = assets;
            _mint(DEAD_ADDRESS, DEAD_SHARES);
            _mint(receiver, shares - DEAD_SHARES);
        } else {
            shares = convertToShares(assets);
            _mint(receiver, shares);
        }

        SafeERC20.safeTransferFrom(asset, msg.sender, address(this), assets);

        emit Deposit(msg.sender, receiver, assets, shares);
        return shares;
    }
}
```

## Learning Objectives

After completing this project, you should understand:

1. How share-based vaults work
2. The mathematics behind the inflation attack
3. Why integer division creates vulnerabilities
4. Economic considerations of the attack
5. Multiple mitigation strategies and their trade-offs
6. How to implement secure ERC-4626 vaults
7. Testing approaches for vault security

## Project Structure

```
44-inflation-attack/
├── README.md                          # This file
├── src/
│   ├── Project44.sol                  # Skeleton with TODOs
│   └── solution/
│       └── Project44Solution.sol      # Complete solution
├── test/
│   └── Project44.t.sol                # Comprehensive tests
└── script/
    └── DeployProject44.s.sol          # Deployment script
```

## Getting Started

1. **Study the skeleton**: Review `src/Project44.sol` and read all comments
2. **Attempt implementation**: Try to implement the vulnerable vault and attacker
3. **Run tests**: `forge test --match-contract Project44Test -vvv`
4. **Compare with solution**: Check `src/solution/Project44Solution.sol`
5. **Experiment**: Try different mitigation strategies

## Tasks

### Part 1: Understanding the Attack
- [ ] Implement vulnerable vault
- [ ] Create attacker contract
- [ ] Execute successful attack
- [ ] Calculate profit vs cost

### Part 2: Implementing Mitigations
- [ ] Add virtual shares/assets
- [ ] Implement minimum deposit
- [ ] Create dead shares pattern
- [ ] Test each mitigation

### Part 3: Analysis
- [ ] Compare gas costs
- [ ] Analyze attack economics
- [ ] Test edge cases
- [ ] Document trade-offs

## Additional Resources

- [EIP-4626: Tokenized Vault Standard](https://eips.ethereum.org/EIPS/eip-4626)
- [OpenZeppelin ERC-4626 Documentation](https://docs.openzeppelin.com/contracts/4.x/erc4626)
- [Inflation Attack Analysis by MixBytes](https://mixbytes.io/blog/overview-of-the-inflation-attack)
- [OpenZeppelin Security Advisory](https://blog.openzeppelin.com/a-novel-defense-against-erc4626-inflation-attacks)

## Security Warning

This project is for educational purposes only. The vulnerable implementations should never be used in production. Always:

- Use audited libraries (OpenZeppelin)
- Include proper mitigations
- Conduct security audits
- Test extensively
- Consider economic incentives

## License

MIT License - Educational purposes only
