# ERC-4626 Vault Attack Scenarios & Mitigations

## Overview

This document details known attack vectors against ERC-4626 vaults that exploit incorrect rounding or precision issues. Understanding these attacks is crucial for building secure vaults.

## Attack 1: Share Inflation Attack

### Description

The first depositor can manipulate the share price to steal funds from subsequent depositors through precision loss.

### Attack Steps

1. **Setup**: Attacker is the first depositor
2. **Initial Deposit**: Deposit minimal amount (e.g., 1 wei)
   - Receives 1 share (1:1 ratio initially)
3. **Donation**: Transfer large amount directly to vault (not via deposit)
   - This inflates the asset-per-share ratio without minting shares
4. **Victim Deposits**: Subsequent depositors suffer precision loss
   - Their deposits round down to very few shares
5. **Profit**: Attacker redeems shares for inflated value

### Concrete Example

```solidity
// Step 1: Attacker deposits 1 wei
vault.deposit(1, attacker);
// State: 1 share, 1 asset, rate = 1:1

// Step 2: Attacker donates 10000 ether directly
token.transfer(address(vault), 10000 ether);
// State: 1 share, 10000 ether + 1 wei, rate = 10000 ether per share

// Step 3: Victim deposits 19999 ether
vault.deposit(19999 ether, victim);
// Shares = 19999 ether * 1 / (10000 ether + 1)
//        ≈ 1.9999 shares
//        → Rounds DOWN to 1 share
// State: 2 shares, ~30000 ether

// Step 4: Attacker redeems
vault.redeem(1, attacker);
// Assets = 1 * 30000 ether / 2 = 15000 ether
// Profit = 15000 - 10000 - 1 = ~5000 ether stolen from victim!
```

### Why It Works

- First depositor establishes 1:1 ratio with minimal capital
- Direct transfer inflates asset value without minting shares
- Victim's deposit suffers catastrophic rounding loss
- Attacker profits from the rounding difference

### Impact

- **Severity**: CRITICAL
- **Loss**: Victim can lose up to ~50% of deposited funds
- **Likelihood**: HIGH if no protections

### Mitigations

#### 1. Minimum First Deposit

Require significant first deposit to make attack expensive:

```solidity
function deposit(uint256 assets, address receiver) public returns (uint256 shares) {
    shares = convertToShares(assets);

    // Require minimum shares on first deposit
    if (totalSupply() == 0) {
        require(shares >= 1e6, "First deposit too small");
    }

    // ... rest of deposit logic
}
```

#### 2. Virtual Shares and Assets

Add offset to prevent extreme ratios:

```solidity
function convertToShares(uint256 assets) public view returns (uint256) {
    uint256 supply = totalSupply() + 1;  // Virtual share
    uint256 total = totalAssets() + 1;    // Virtual asset

    return (assets * supply) / total;
}
```

#### 3. Dead Shares

Lock initial liquidity permanently:

```solidity
constructor(IERC20 asset_) {
    // Mint dead shares to zero address
    _mint(address(0), 1000);
}
```

#### 4. Initial Deposit Lock

Require protocol to seed vault:

```solidity
bool public initialized;

function initialize(uint256 initialDeposit) external onlyOwner {
    require(!initialized, "Already initialized");
    require(initialDeposit >= MINIMUM_INIT, "Too small");

    asset.safeTransferFrom(msg.sender, address(this), initialDeposit);
    _mint(msg.sender, initialDeposit);

    // Lock some shares
    _mint(address(0), LOCKED_SHARES);

    initialized = true;
}
```

## Attack 2: Precision Drain

### Description

If vault rounds in user's favor, repeated small operations can drain vault reserves.

### Attack Steps

1. Find rounding favorable to user
2. Repeatedly execute operation to gain 1 wei each time
3. Accumulate stolen funds over many transactions

### Concrete Example

Assume **incorrectly implemented** vault that rounds UP shares in deposit:

```solidity
// VULNERABLE CODE (DO NOT USE)
function deposit(uint256 assets) public returns (uint256 shares) {
    shares = mulDivUp(assets, totalSupply(), totalAssets());  // WRONG!
    // ...
}
```

Attack:
```solidity
// Setup: Vault has 1000 shares, 1500 assets (1.5:1 ratio)

// Attacker deposits 2 assets
// shares = roundUp(2 * 1000 / 1500)
//        = roundUp(1.333...)
//        = 2 shares
// Expected: 1 share, got 2 shares → 1 share profit

// Repeat 1 million times
for (uint i = 0; i < 1000000; i++) {
    vault.deposit(2);
}
// Profit: ~1 million shares * 1.5 assets = 1.5M assets stolen
```

### Why It Works

- Each operation gains 1 wei due to incorrect rounding
- Gas costs may be lower than profit if repeated enough
- Compounds over many transactions

### Impact

- **Severity**: HIGH
- **Loss**: Cumulative, can fully drain vault
- **Likelihood**: MEDIUM (requires wrong rounding)

### Mitigations

1. **Always round in vault's favor** - See main README
2. **Minimum deposit amounts** - Make dust attacks expensive
3. **Deposit fees** - Small fee prevents profitability
4. **Rate limiting** - Limit operations per block/user

## Attack 3: Sandwich Attack on Deposits

### Description

MEV bot front-runs victim's deposit to manipulate exchange rate unfavorably.

### Attack Steps

1. **Front-run**: Detect victim's pending deposit
2. **Deposit**: Large deposit to establish favorable rate
3. **Victim Deposits**: Suffers worse rate due to attacker's deposit
4. **Back-run**: Withdraw to profit from rate change

### Concrete Example

```solidity
// Initial state: 1000 shares, 1000 assets (1:1)

// Victim submits: deposit 1000 assets (expects ~1000 shares)

// MEV bot front-runs: deposit 9000 assets
// Gets 9000 shares
// State: 10000 shares, 10000 assets

// Victim's transaction executes: deposit 1000 assets
// shares = 1000 * 10000 / 10000 = 1000 shares
// State: 11000 shares, 11000 assets

// MEV bot back-runs: redeem 9000 shares
// assets = 9000 * 11000 / 11000 = 9000 assets
// State: 2000 shares, 2000 assets

// Net effect: Victim gets expected shares, but MEV bot manipulated rate
```

### Why This Is Less Effective

Actually, this specific attack **doesn't work** with correct rounding because:
- Victim gets fair rate based on vault state when transaction executes
- Attacker's round-trip loses value due to vault-favorable rounding

### Impact

- **Severity**: LOW (with correct rounding)
- **Loss**: Minimal to none
- **Likelihood**: LOW

### Mitigations

1. Correct rounding (primary defense)
2. Slippage protection in deposit/mint
3. Time-weighted average price (TWAP) for rates

## Attack 4: Reentrancy

### Description

Attacker reenters vault during deposit/withdraw to manipulate state.

### Attack Steps

1. Create malicious ERC20 or ERC777 with transfer hook
2. Use hook to reenter vault during transfer
3. Exploit inconsistent state

### Concrete Example

```solidity
contract MaliciousToken is ERC20 {
    IVault public vault;

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        // Hook: Before transfer completes, reenter vault
        if (to == address(vault)) {
            vault.withdraw(1000, msg.sender);  // Reenter!
        }

        return super.transferFrom(from, to, amount);
    }
}
```

### Why It Works (If Vulnerable)

- Transfer happens before state updates
- Reentered call sees stale state
- Can withdraw before shares are minted

### Impact

- **Severity**: CRITICAL (if vulnerable)
- **Loss**: Complete vault drain possible
- **Likelihood**: LOW (easy to prevent)

### Mitigations

#### 1. Checks-Effects-Interactions Pattern

```solidity
function deposit(uint256 assets, address receiver) public returns (uint256 shares) {
    // CHECKS
    shares = convertToShares(assets);
    require(shares > 0, "Zero shares");

    // EFFECTS (update state BEFORE external calls)
    _mint(receiver, shares);

    // INTERACTIONS (external calls last)
    _asset.safeTransferFrom(msg.sender, address(this), assets);

    emit Deposit(msg.sender, receiver, assets, shares);
}
```

#### 2. Reentrancy Guard

```solidity
modifier nonReentrant() {
    require(!locked, "Reentrancy");
    locked = true;
    _;
    locked = false;
}

function deposit(uint256 assets, address receiver) public nonReentrant returns (uint256 shares) {
    // Safe from reentrancy
}
```

#### 3. Use SafeERC20

```solidity
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

using SafeERC20 for IERC20;

// SafeERC20 handles reentrancy concerns
_asset.safeTransferFrom(msg.sender, address(this), assets);
```

## Attack 5: Flash Loan Price Manipulation

### Description

Use flash loan to temporarily manipulate vault's totalAssets, affecting exchange rate.

### Attack Steps

1. Flash loan large amount of vault's underlying asset
2. Deposit to vault, getting shares at manipulated rate
3. Repay flash loan
4. Exchange rate returns to normal, attacker profits

### Concrete Example

```solidity
// Initial: 1000 shares, 1000 assets (1:1)

// Step 1: Flash loan 99000 assets
flashLoan(99000);

// Step 2: Deposit all 99000
vault.deposit(99000);
// Gets ~99000 shares
// State: 100000 shares, 100000 assets

// Step 3: If vault has yield-generating strategy
// and attacker can trigger yield distribution...
vault.harvest();  // Adds 1000 assets of yield
// State: 100000 shares, 101000 assets

// Step 4: Withdraw
vault.redeem(99000);
// Gets: 99000 * 101000 / 100000 = 99990 assets
// Profit: 990 assets

// Step 5: Repay flash loan (99000)
// Net profit: 990 - flash loan fee
```

### Why It Might Work

- Large flash loan temporarily inflates vault size
- Yield distribution or fee collection happens
- Attacker gets disproportionate share

### Impact

- **Severity**: MEDIUM
- **Loss**: Depends on yield generated during attack
- **Likelihood**: LOW (requires perfect timing)

### Mitigations

1. **Time-weighted balances** for yield distribution
2. **Minimum deposit time** before rewards
3. **Flash loan detection** via balance checks
4. **Slashing for early withdrawal**

```solidity
mapping(address => uint256) public depositTime;

function deposit(uint256 assets, address receiver) public returns (uint256 shares) {
    // Record deposit time
    depositTime[receiver] = block.timestamp;
    // ... normal deposit logic
}

function claimYield() public {
    require(block.timestamp - depositTime[msg.sender] >= 1 days, "Too soon");
    // ... yield distribution
}
```

## Attack 6: Withdrawal Front-Running

### Description

Attacker observes loss event and front-runs other users' withdrawals.

### Attack Steps

1. Monitor vault for loss events (strategy failure, hack, etc.)
2. Detect other users trying to withdraw
3. Front-run with large withdrawal
4. Subsequent withdrawals get less due to depleted reserves

### Concrete Example

```solidity
// Vault has 1000 shares, 1000 assets
// Strategy loses 500 assets
// State: 1000 shares, 500 assets (2:1 share:asset ratio)

// Alice submits: withdraw 250 assets (expects to burn 500 shares)

// Attacker front-runs: redeem 600 shares
// Gets: 600 * 500 / 1000 = 300 assets
// State: 400 shares, 200 assets

// Alice's transaction executes: withdraw 250 assets
// FAILS: Only 200 assets left, transaction reverts
// Or if using redeem: 500 shares → 500 * 200 / 400 = 250 assets
```

### Why It Works

- Race condition during crisis
- First withdrawals get better rate
- Later withdrawals get losses

### Impact

- **Severity**: MEDIUM
- **Loss**: Unequal loss distribution
- **Likelihood**: HIGH during crisis

### Mitigations

1. **Withdrawal queue** during losses
2. **Pro-rata loss sharing**
3. **Withdrawal delays**
4. **Circuit breakers** on large losses

```solidity
function redeem(uint256 shares) public returns (uint256 assets) {
    // Check for significant loss
    uint256 expectedAssets = shares * lastKnownAssetPerShare / 1e18;
    assets = convertToAssets(shares);

    if (assets < expectedAssets * 90 / 100) {
        // More than 10% loss detected
        revert("Circuit breaker: significant loss");
    }

    // ... normal redeem
}
```

## Defense Checklist

Use this checklist when building ERC-4626 vaults:

### Rounding
- [ ] Deposit rounds DOWN shares
- [ ] Mint rounds UP assets
- [ ] Withdraw rounds UP shares
- [ ] Redeem rounds DOWN assets
- [ ] Preview functions match actions

### First Deposit
- [ ] Minimum first deposit enforced
- [ ] Virtual shares/assets implemented OR
- [ ] Dead shares locked OR
- [ ] Initial deposit by protocol

### Reentrancy
- [ ] Checks-Effects-Interactions pattern used
- [ ] ReentrancyGuard on all external functions OR
- [ ] State updated before external calls

### Flash Loans
- [ ] Time-weighted balances for rewards
- [ ] Minimum holding period for yields
- [ ] Balance checks for abnormal deposits

### Loss Events
- [ ] Circuit breakers on significant losses
- [ ] Withdrawal queue mechanism OR
- [ ] Pro-rata loss distribution

### Edge Cases
- [ ] Zero totalSupply handled
- [ ] Zero totalAssets handled
- [ ] Division by zero prevented
- [ ] Overflow protection (Solidity 0.8+)

### Testing
- [ ] Fuzz tests for all operations
- [ ] Invariant tests (vault never loses)
- [ ] Attack scenario tests
- [ ] Edge case tests

## Conclusion

Building secure ERC-4626 vaults requires:
1. **Correct rounding** (always favor vault)
2. **First deposit protection** (prevent inflation attacks)
3. **Reentrancy protection** (standard Solidity security)
4. **Flash loan resistance** (time-weighted calculations)
5. **Loss handling** (fair distribution mechanisms)

The basic implementation in this project focuses on #1 and #2. Production vaults should implement all protections.

## Further Reading

- [ERC4626 Security Review by Trail of Bits](https://blog.trailofbits.com/2022/04/18/erc-4626-security-considerations/)
- [Rari Capital Hack Analysis](https://medium.com/immunefi/rari-capital-hack-analysis-21eb4fae0f9a)
- [OpenZeppelin ERC4626 Security](https://docs.openzeppelin.com/contracts/4.x/erc4626#security)
- [DeFi Security Best Practices](https://github.com/crytic/building-secure-contracts)

---

**Remember**: Security is not a feature—it's a requirement. Test thoroughly and audit before deploying real funds! 🔒
