# Project 11: ERC-4626 Tokenized Vault 🏦

> **Implement the Tokenized Vault Standard for DeFi yield strategies**

## 🎯 Learning Objectives

- Understand the ERC-4626 Tokenized Vault Standard
- Implement deposit/withdraw mechanisms with share calculation
- Handle asset/share conversion mathematics
- Learn vault security patterns
- Study real-world DeFi vault implementations

## 📚 Background: What is ERC-4626?

ERC-4626 is a standard for tokenized vaults that:
- Represent shares of an underlying asset (like USDC, DAI, WETH)
- Enable yield-generating strategies
- Provide standardized deposit/withdraw interfaces
- Power DeFi protocols like Yearn, Beefy, and Rari

### Real-World Use Cases

- **Yield Aggregators**: Yearn vaults deposit user funds into highest-yield protocols
- **Lending**: Aave/Compound style interest-bearing tokens
- **Liquidity Mining**: Auto-compounding LP rewards
- **Treasury Management**: Protocol-owned liquidity strategies

## 🧮 Core Concepts

### Asset vs Shares

```solidity
// User deposits 100 USDC (asset)
// Vault mints 95 shares (based on current exchange rate)
// Later: shares are worth more USDC due to yield

asset = underlying token (USDC, WETH, etc.)
shares = vault tokens (yUSDC, vWETH, etc.)
```

### Share Calculation

```solidity
// Deposit: shares = assets * totalSupply / totalAssets
shares = (assets * totalSupply) / totalAssets;

// Withdraw: assets = shares * totalAssets / totalSupply  
assets = (shares * totalAssets) / totalSupply;
```

### Key Functions

| Function | Purpose |
|----------|---------|
| `deposit(assets, receiver)` | Deposit assets, mint shares |
| `mint(shares, receiver)` | Mint exact shares, deposit assets |
| `withdraw(assets, receiver, owner)` | Burn shares, withdraw assets |
| `redeem(shares, receiver, owner)` | Burn exact shares, withdraw assets |
| `totalAssets()` | Total underlying assets in vault |
| `convertToShares(assets)` | Preview assets→shares conversion |
| `convertToAssets(shares)` | Preview shares→assets conversion |
| `maxDeposit(receiver)` | Max assets user can deposit |
| `maxMint(receiver)` | Max shares user can mint |
| `maxWithdraw(owner)` | Max assets user can withdraw |
| `maxRedeem(owner)` | Max shares user can redeem |
| `previewDeposit(assets)` | Simulate deposit, return shares |
| `previewMint(shares)` | Simulate mint, return assets needed |
| `previewWithdraw(assets)` | Simulate withdraw, return shares burned |
| `previewRedeem(shares)` | Simulate redeem, return assets received |

## 🔧 What You'll Build

A complete ERC-4626 vault that:
- Accepts an ERC-20 asset (like USDC)
- Issues share tokens representing ownership
- Implements all required ERC-4626 functions
- Handles rounding correctly (favor vault on deposits/withdraws)
- Includes security checks and reentrancy guards
- Demonstrates yield accrual simulation

## 📝 Tasks

### Task 1: Implement the Skeleton Contract

Open `src/ERC4626Vault.sol` and implement:

1. **Asset management** - deposit, withdraw, totalAssets
2. **Share conversion** - convertToShares, convertToAssets
3. **Preview functions** - simulate operations
4. **Max functions** - return maximum allowed amounts
5. **ERC-20 share tokens** - inherit or implement

### Task 2: Study the Solution

Compare with `src/solution/ERC4626VaultSolution.sol`:
- Understand share/asset conversion math
- See rounding direction choices (favor vault)
- Learn security patterns (reentrancy, donation attacks)
- Study real-world vault patterns

### Task 3: Run Comprehensive Tests

```bash
cd 11-ERC4626-tokenized-vault

# Run all tests
forge test -vvv

# Test specific scenarios
forge test --match-test test_Deposit
forge test --match-test test_Withdraw
forge test --match-test test_ShareConversion

# Gas report
forge test --gas-report

# Coverage
forge coverage
```

### Task 4: Deploy and Interact

```bash
# Start local node
anvil

# Deploy vault (in another terminal)
forge script script/Deploy.s.sol --broadcast --rpc-url http://localhost:8545

# Interact with vault
cast call <VAULT_ADDRESS> "totalAssets()(uint256)"
cast send <VAULT_ADDRESS> "deposit(uint256,address)(uint256)" 1000000 <YOUR_ADDRESS> \
  --private-key <KEY>
```

### Task 5: Study Real Implementations

After completing this project, study production vaults:
- [OpenZeppelin ERC4626](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC4626.sol)
- [Solmate ERC4626](https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC4626.sol)
- [Yearn vaults](https://github.com/yearn/yearn-vaults)

## 🧪 Test Coverage

The test suite covers:

- ✅ Deposit and mint operations
- ✅ Withdraw and redeem operations
- ✅ Share/asset conversion accuracy
- ✅ Preview function correctness
- ✅ Max function constraints
- ✅ Rounding behavior (favor vault)
- ✅ Edge cases (first depositor, zero amounts)
- ✅ Attack vectors (inflation attack, donation attack)
- ✅ Yield accrual simulation
- ✅ Gas optimization

## ⚠️ Security Considerations

### 1. Inflation Attack

**Problem**: First depositor can manipulate share price

```solidity
// Attacker deposits 1 wei, gets 1 share
vault.deposit(1, attacker);

// Attacker donates large amount directly to vault
asset.transfer(address(vault), 1000000e18);

// Now 1 share = 1000000e18 assets
// Victim deposits 999999e18, gets 0 shares (rounded down!)
```

**Solution**: Mint dead shares to address(0) on first deposit, or require minimum deposit.

### 2. Donation Attack

**Problem**: Direct transfers can break accounting

**Solution**: Don't rely on `asset.balanceOf(address(this))`, track deposits internally.

### 3. Rounding Direction

**Always favor the vault**:
- Deposit/mint: round DOWN shares given to user
- Withdraw/redeem: round UP shares taken from user

### 4. Reentrancy

Use OpenZeppelin ReentrancyGuard on deposit/withdraw functions.

## 📊 Comparison: Vault Implementations

| Implementation | Gas Cost | Security | Flexibility |
|----------------|----------|----------|-------------|
| OpenZeppelin | Higher (safe) | ✅✅✅ | Medium |
| Solmate | Lower (optimized) | ✅✅ | High |
| This Project | Educational | ✅✅✅ | Learning |

## 🌍 Real-World Examples

### Yearn Finance

```solidity
// Yearn vault accepts USDC, implements yield strategy
yUSDC vault = YearnVault(vaultAddress);
vault.deposit(1000e6, msg.sender);  // Deposit 1000 USDC
// Vault deploys to Aave, Compound, Curve for best yield
```

### Beefy Finance

```solidity
// Auto-compounding LP token vault
BeefyVault mooToken = BeefyVault(vaultAddress);
mooToken.deposit(lpTokenAmount, msg.sender);
// Vault claims rewards, sells, re-invests into LP
```

## ✅ Completion Checklist

- [ ] Implemented all ERC-4626 required functions
- [ ] All tests pass
- [ ] Understand share conversion mathematics
- [ ] Can explain rounding directions
- [ ] Know common attack vectors
- [ ] Studied real vault implementations
- [ ] Deployed and interacted with vault
- [ ] Understand yield strategy concepts

## 💡 Pro Tips

1. **Always round in favor of the vault** (protect against attackers)
2. **Virtual shares/assets** - Consider minting dead shares on initialization
3. **Max functions** - Return actual maximums based on current state
4. **Preview functions** - Must match actual behavior exactly
5. **Events** - Emit for all deposits/withdraws for off-chain tracking
6. **Approval** - Users must approve vault to spend their assets
7. **Emergency functions** - Consider pause/unpause for security

## 🚀 Next Steps

After completing this project:

- **Build strategy vaults**: Implement actual yield strategies (Aave deposits, Curve LPs)
- **Multi-asset vaults**: Support multiple underlying tokens
- **Fee mechanisms**: Add performance fees and management fees
- **Access control**: Implement whitelists or caps
- **Integration**: Connect to DeFi protocols (Aave, Compound, Curve)

## 📖 Further Reading

- [EIP-4626 Specification](https://eips.ethereum.org/EIPS/eip-4626)
- [OpenZeppelin ERC4626 Guide](https://docs.openzeppelin.com/contracts/4.x/erc4626)
- [Yield Farming Strategies](https://ethereum.org/en/developers/docs/dapps/)
- [Vault Security Best Practices](https://github.com/yearn/yearn-security)

---

**Congratulations!** You've completed all 11 Solidity mini-projects. You now have:
- ✅ Solid understanding of Solidity fundamentals
- ✅ Experience with major token standards (ERC-20, ERC-721, ERC-4626)
- ✅ Knowledge of security vulnerabilities and mitigations
- ✅ Gas optimization techniques
- ✅ Real-world DeFi protocol patterns

**Keep building! 🚀**
