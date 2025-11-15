# Usage Guide: Yield-Bearing Vault

## Quick Start

### 1. Deploy the Vault

```bash
# Set up environment
export PRIVATE_KEY=your_private_key
export ASSET_TOKEN=0x... # Or omit to deploy mock token

# Deploy
forge script script/DeployProject43.s.sol --rpc-url sepolia --broadcast

# Or run quick local test
forge script script/DeployProject43.s.sol:QuickTest --fork-url mainnet
```

### 2. Interact with the Vault

#### As a User

```solidity
// Approve the vault
IERC20(asset).approve(address(vault), depositAmount);

// Deposit assets
uint256 shares = vault.deposit(1000e18, msg.sender);
// You receive shares representing your ownership

// Check your balance
uint256 myShares = vault.balanceOf(msg.sender);
uint256 myValue = vault.convertToAssets(myShares);

// Wait for yield to accrue...
// (share price increases over time)

// Withdraw
uint256 assets = vault.redeem(shares, msg.sender, msg.sender);
// You receive more assets than you deposited!
```

#### Anyone Can Harvest

```solidity
// After cooldown period, anyone can call harvest
vault.harvest();
// This claims yield from the strategy
// Takes performance fee
// Reinvests the rest
// Benefits all vault shareholders
```

#### As the Owner

```solidity
// Set a new strategy
vault.setStrategy(newStrategy);

// Adjust performance fee
vault.setPerformanceFee(1500); // 15%

// Change fee recipient
vault.setFeeRecipient(treasuryAddress);

// Adjust harvest cooldown
vault.setHarvestCooldown(6 hours);
```

## Understanding Share Price

The share price increases as yield accrues:

```
Time 0:
- Total Assets: 1000 tokens
- Total Shares: 1000
- Share Price: 1.0

After 30 days (assuming 10% APY):
- Total Assets: ~1008 tokens (yield accrued)
- Total Shares: 1000 (unchanged)
- Share Price: 1.008

After harvest:
- Performance fee taken (10% of 8 = 0.8 tokens)
- Remaining yield reinvested (7.2 tokens)
- Total Assets: ~1007.2 tokens
- Share Price: 1.0072
```

## Yield Calculation Example

### Simple Interest (No Compounding)

```
Principal: 1000 tokens
APY: 10%
Time: 1 year

Yield = 1000 * 0.10 = 100 tokens
Final: 1100 tokens
```

### Compound Interest (With Monthly Harvests)

```
Month 1: 1000 → 1008.3
Month 2: 1008.3 → 1016.7
Month 3: 1016.7 → 1025.1
...
Month 12: ~1104.7

Effective APY: 10.47% (higher due to compounding)
```

## Strategy Examples

### Simple Strategy

Deposits into a lending protocol, harvests interest:

```solidity
function harvest() external returns (uint256) {
    uint256 currentBalance = lendingProtocol.balanceOf(address(this));
    uint256 yield = currentBalance - principal;

    // Withdraw only the yield
    lendingProtocol.withdraw(yield);

    // Send to vault
    asset.transfer(vault, yield);

    return yield;
}
```

### Compound Strategy

Keeps 50% of yield, sends 50% to vault:

```solidity
function harvest() external returns (uint256) {
    uint256 totalYield = getCurrentYield();

    uint256 toVault = totalYield / 2;
    uint256 toReinvest = totalYield - toVault;

    // Withdraw portion for vault
    lendingProtocol.withdraw(toVault);
    asset.transfer(vault, toVault);

    // Rest stays invested (becomes new principal)
    principal += toReinvest;

    return toVault;
}
```

## Testing Scenarios

### Test Yield Accrual

```bash
forge test --match-test test_YieldAccrual -vv
```

### Test Harvest Mechanism

```bash
forge test --match-test test_Harvest -vv
```

### Run Realistic Scenario

```bash
forge test --match-test test_RealisticYieldScenario -vvv
```

This will output a 6-month simulation with:
- Multiple depositors
- Monthly harvests
- Detailed reporting

### Gas Reports

```bash
forge test --gas-report --match-contract Project43Test
```

## Common Patterns

### Dollar Cost Averaging

```solidity
// Deposit monthly
for (uint256 month = 0; month < 12; month++) {
    vault.deposit(monthlyAmount, msg.sender);
    vm.warp(block.timestamp + 30 days);
}
```

### Withdraw Only Profits

```solidity
uint256 shares = vault.balanceOf(msg.sender);
uint256 currentValue = vault.convertToAssets(shares);
uint256 originalDeposit = userDeposits[msg.sender];

if (currentValue > originalDeposit) {
    uint256 profit = currentValue - originalDeposit;
    uint256 sharesToRedeem = vault.convertToShares(profit);
    vault.redeem(sharesToRedeem, msg.sender, msg.sender);
}
```

## Performance Metrics

### Calculate Current APY

```solidity
uint256 startTime = block.timestamp - 90 days;
uint256 startAssets = historicalAssets[startTime];
uint256 currentAssets = vault.totalAssets();

uint256 gain = currentAssets - startAssets;
uint256 simpleAPY = (gain * 365 days * 10000) / (startAssets * 90 days);
// Result in basis points
```

### Track Your Performance

```solidity
struct Position {
    uint256 shares;
    uint256 depositValue;
    uint256 depositTime;
}

mapping(address => Position) public positions;

function recordDeposit(address user, uint256 shares) internal {
    positions[user] = Position({
        shares: shares,
        depositValue: vault.convertToAssets(shares),
        depositTime: block.timestamp
    });
}

function getProfit(address user) public view returns (uint256) {
    Position memory pos = positions[user];
    uint256 currentValue = vault.convertToAssets(pos.shares);
    return currentValue - pos.depositValue;
}
```

## Security Best Practices

1. **Always approve exact amounts**: Don't approve max uint256
2. **Check share price before large deposits**: Prevent front-running
3. **Understand strategy risks**: Each strategy has different risk profiles
4. **Monitor harvests**: Ensure they happen regularly
5. **Use a multisig for owner functions**: Protect admin operations

## Troubleshooting

### "Cooldown not elapsed" error

Wait for the cooldown period before calling harvest again.

### "No yield to harvest" error

Not enough time has passed, or the yield is too small.

### Unexpected share price

Check:
- Has harvest been called recently?
- Is the strategy performing as expected?
- Are there any fees being taken?

### Withdrawal amount less than expected

Could be:
- Strategy has withdrawal fees
- Performance fees were taken
- Share price decreased (rare in yield vaults)

## Advanced Topics

### Multiple Strategies

```solidity
// Allocate across strategies
strategy1.deposit(totalAssets * 60 / 100); // 60% to Aave
strategy2.deposit(totalAssets * 40 / 100); // 40% to Compound

// Harvest all
uint256 yield1 = strategy1.harvest();
uint256 yield2 = strategy2.harvest();
```

### Dynamic Performance Fees

```solidity
// Higher fees on higher yields
function calculateFee(uint256 yield) internal view returns (uint256) {
    if (yield < lowThreshold) return 500;  // 5%
    if (yield < highThreshold) return 1000; // 10%
    return 1500; // 15%
}
```

### Harvest Incentives

```solidity
// Reward the caller
function harvest() external {
    uint256 yield = strategy.harvest();
    uint256 callerReward = yield * 50 / 10000; // 0.5%

    asset.transfer(msg.sender, callerReward);
    // ... process rest of yield
}
```

## Resources

- [ERC4626 Docs](https://eips.ethereum.org/EIPS/eip-4626)
- [Yearn Finance](https://docs.yearn.finance/)
- [Compound Finance](https://compound.finance/docs)
- [Aave Protocol](https://docs.aave.com/)

## Support

For questions or issues:
1. Check the test files for examples
2. Review the solution implementation
3. Read the comprehensive README.md
4. Test on a local fork before deploying
