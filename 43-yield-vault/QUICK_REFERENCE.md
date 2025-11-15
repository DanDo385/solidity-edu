# Quick Reference Card - Yield Vault

## Essential Formulas

### Share Price Calculation
```solidity
sharePrice = totalAssets() / totalSupply()
```

### Deposit (Assets → Shares)
```solidity
shares = assets * totalSupply / totalAssets
```

### Withdraw (Shares → Assets)
```solidity
assets = shares * totalAssets / totalSupply
```

### Yield Calculation (Simple Interest)
```solidity
yield = principal * APY * timeElapsed / (365 days * 10000)
// APY in basis points (e.g., 1000 = 10%)
```

### Performance Fee
```solidity
fee = yield * performanceFee / 10000
reinvestAmount = yield - fee
```

### APY Calculation
```solidity
// Simple APY
APY = (endValue - startValue) * 365 days * 10000 / (startValue * timePeriod)

// Compound APY (more accurate)
APY = ((endValue / startValue) ** (365 days / timePeriod) - 1) * 10000
```

## Key Interfaces

### IYieldStrategy
```solidity
interface IYieldStrategy {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external returns (uint256);
    function harvest() external returns (uint256);
    function totalAssets() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}
```

### ERC4626 Key Functions
```solidity
function deposit(uint256 assets, address receiver) external returns (uint256 shares);
function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);
function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
function totalAssets() public view returns (uint256);
function convertToShares(uint256 assets) public view returns (uint256);
function convertToAssets(uint256 shares) public view returns (uint256);
```

## Vault Functions Quick Reference

### User Functions
```solidity
// Deposit tokens
vault.deposit(amount, receiver) → shares

// Withdraw tokens
vault.redeem(shares, receiver, owner) → assets
vault.withdraw(assets, receiver, owner) → shares

// Check balance
vault.balanceOf(user) → shares
vault.convertToAssets(shares) → asset value
```

### Harvest (Anyone)
```solidity
// Claim and reinvest yield
vault.harvest()
```

### Owner Functions
```solidity
vault.setStrategy(strategy)
vault.setPerformanceFee(fee)
vault.setFeeRecipient(recipient)
vault.setHarvestCooldown(seconds)
```

## Common Patterns

### Strategy Deposit Pattern
```solidity
function deposit(uint256 amount) external onlyVault {
    // 1. Transfer from vault
    asset.safeTransferFrom(vault, address(this), amount);

    // 2. Approve yield source
    asset.forceApprove(address(yieldSource), amount);

    // 3. Deposit to yield source
    yieldSource.deposit(amount);

    // 4. Track principal
    principal += amount;
}
```

### Strategy Harvest Pattern
```solidity
function harvest() external onlyVault returns (uint256) {
    // 1. Get current balance
    uint256 currentBalance = yieldSource.balanceOf(address(this));

    // 2. Calculate yield
    uint256 yield = currentBalance - principal;
    if (yield == 0) return 0;

    // 3. Withdraw yield
    yieldSource.withdraw(yield);

    // 4. Send to vault
    asset.safeTransfer(vault, yield);

    return yield;
}
```

### Vault Harvest Pattern
```solidity
function harvest() external {
    // 1. Claim yield from strategy
    uint256 yield = strategy.harvest();
    require(yield > 0, "No yield");

    // 2. Calculate fee
    uint256 fee = (yield * performanceFee) / 10000;

    // 3. Transfer fee
    if (fee > 0) {
        asset.safeTransfer(feeRecipient, fee);
    }

    // 4. Reinvest
    uint256 reinvest = yield - fee;
    if (reinvest > 0) {
        asset.forceApprove(address(strategy), reinvest);
        strategy.deposit(reinvest);
    }
}
```

## Test Patterns

### Setup Pattern
```solidity
function setUp() public {
    token = new MockERC20();
    yieldSource = new MockYieldSource(token, APY);
    vault = new YieldVault(token, "Vault", "vToken", feeRecipient, fee);
    strategy = new SimpleYieldStrategy(token, yieldSource, address(vault));
    vault.setStrategy(strategy);
}
```

### Deposit Test Pattern
```solidity
function test_Deposit() public {
    uint256 amount = 1000e18;

    vm.startPrank(alice);
    token.approve(address(vault), amount);
    uint256 shares = vault.deposit(amount, alice);
    vm.stopPrank();

    assertEq(shares, amount); // First deposit 1:1
    assertEq(vault.totalAssets(), amount);
}
```

### Yield Test Pattern
```solidity
function test_YieldAccrual() public {
    // Deposit
    vault.deposit(1000e18, alice);

    // Record initial state
    uint256 startAssets = vault.totalAssets();

    // Fast forward time
    vm.warp(block.timestamp + 30 days);

    // Check yield accrued
    uint256 endAssets = vault.totalAssets();
    assertGt(endAssets, startAssets);
}
```

### Harvest Test Pattern
```solidity
function test_Harvest() public {
    vault.deposit(1000e18, alice);

    vm.warp(block.timestamp + 30 days);
    vault.setHarvestCooldown(0);

    uint256 feeBalanceBefore = token.balanceOf(feeRecipient);
    vault.harvest();
    uint256 feeBalanceAfter = token.balanceOf(feeRecipient);

    assertGt(feeBalanceAfter, feeBalanceBefore); // Fee collected
}
```

## Common Values

### Basis Points
```
1 bp = 0.01%
100 bps = 1%
1000 bps = 10%
10000 bps = 100%
```

### Typical Performance Fees
```
Conservative: 500 bps (5%)
Standard: 1000 bps (10%)
High: 2000 bps (20%)
Max allowed: 2000 bps (20%)
```

### Typical APYs (Basis Points)
```
Stablecoin Lending: 200-500 bps (2-5%)
ETH Staking: 300-500 bps (3-5%)
LP Farming: 1000-5000 bps (10-50%)
Risky Strategies: 5000+ bps (50%+)
```

### Time Periods
```
1 hour = 3600 seconds
1 day = 86400 seconds
30 days = 2592000 seconds
365 days = 31536000 seconds
```

## Debugging Checklist

### Deposit Issues
- [ ] Did you approve the vault?
- [ ] Does user have sufficient balance?
- [ ] Is the amount > 0?
- [ ] Is strategy set correctly?

### Withdraw Issues
- [ ] Does user have enough shares?
- [ ] Is strategy liquid enough?
- [ ] Are there withdrawal fees?
- [ ] Is vault paused?

### Harvest Issues
- [ ] Has cooldown elapsed?
- [ ] Is there yield to harvest?
- [ ] Is strategy working?
- [ ] Is fee recipient valid?

### Yield Not Accruing
- [ ] Is time actually passing? (vm.warp in tests)
- [ ] Is strategy depositing correctly?
- [ ] Is yield source working?
- [ ] Check totalAssets() vs balanceOf()

## Gas Optimization Tips

```solidity
// ✅ Good: Lazy accounting
function harvest() external {
    // Don't update user balances
    // Share price increases automatically
}

// ✅ Good: Batch operations
function harvestMultiple(address[] strategies) external {
    // One call, multiple harvests
}

// ✅ Good: View functions
function totalAssets() public view returns (uint256) {
    // No state changes
}

// ❌ Bad: Updating all users
function harvest() external {
    for (uint i = 0; i < users.length; i++) {
        updateUserBalance(users[i]); // Very expensive!
    }
}
```

## Security Checklist

- [ ] Use SafeERC20 for transfers
- [ ] Add reentrancy guards on harvest/withdraw
- [ ] Validate all inputs
- [ ] Check for zero addresses
- [ ] Implement access control (onlyOwner, onlyVault)
- [ ] Add cooldown periods
- [ ] Cap performance fees
- [ ] Test edge cases (first deposit, zero amounts)
- [ ] Implement emergency pause
- [ ] Get professional audit before mainnet

## Quick Commands

```bash
# Build
forge build

# Test all
forge test

# Test specific
forge test --match-test test_Harvest -vvv

# Test with gas
forge test --gas-report

# Deploy local
forge script script/DeployProject43.s.sol:QuickTest

# Deploy testnet
forge script script/DeployProject43.s.sol --rpc-url sepolia --broadcast

# Verify contract
forge verify-contract <address> YieldVault --chain sepolia
```

## Useful Resources

- [ERC4626 Spec](https://eips.ethereum.org/EIPS/eip-4626)
- [OpenZeppelin ERC4626](https://docs.openzeppelin.com/contracts/4.x/erc4626)
- [Solidity Docs](https://docs.soliditylang.org/)
- [Foundry Book](https://book.getfoundry.sh/)

## Example Values for Testing

```solidity
// Deposits
uint256 smallDeposit = 100 * 10**18;    // 100 tokens
uint256 mediumDeposit = 1000 * 10**18;  // 1,000 tokens
uint256 largeDeposit = 10000 * 10**18;  // 10,000 tokens

// Time periods
uint256 oneDay = 1 days;
uint256 oneWeek = 7 days;
uint256 oneMonth = 30 days;
uint256 oneYear = 365 days;

// APY (basis points)
uint256 lowAPY = 200;    // 2%
uint256 mediumAPY = 1000; // 10%
uint256 highAPY = 5000;   // 50%

// Fees (basis points)
uint256 lowFee = 500;     // 5%
uint256 mediumFee = 1000; // 10%
uint256 highFee = 2000;   // 20%
```

## Common Errors & Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| "Cooldown not elapsed" | Harvesting too frequently | Wait for cooldown period |
| "No yield to harvest" | Not enough time passed | Wait longer or check strategy |
| "Only vault" | Wrong caller | Call from vault contract |
| "Fee too high" | Fee > 2000 bps | Set fee ≤ 2000 |
| "Insufficient balance" | Not enough tokens | Check balanceOf() |

---

**Keep this card handy while working on Project 43!**
