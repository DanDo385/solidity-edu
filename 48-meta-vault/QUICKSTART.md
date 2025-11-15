# Quick Start Guide - Project 48: Meta-Vault

Get started with building and testing the meta-vault in 5 minutes.

## Prerequisites

- Foundry installed ([installation guide](https://book.getfoundry.sh/getting-started/installation))
- Basic understanding of ERC-4626 vaults
- Familiarity with Solidity ^0.8.20

## Installation

```bash
# Navigate to project directory
cd 48-meta-vault

# Install dependencies
forge install OpenZeppelin/openzeppelin-contracts
forge install foundry-rs/forge-std

# Build contracts
forge build
```

## Project Structure

```
48-meta-vault/
├── src/
│   ├── Project48.sol           # Skeleton with TODOs
│   └── solution/
│       └── Project48Solution.sol # Complete implementation
├── test/
│   └── Project48.t.sol         # Comprehensive test suite
├── script/
│   └── DeployProject48.s.sol   # Deployment scripts
├── README.md                    # Detailed concepts and theory
├── EXAMPLES.md                  # Practical usage examples
└── foundry.toml                 # Foundry configuration
```

## Quick Test

Run the test suite to verify everything works:

```bash
# Run all tests
forge test

# Run with verbosity to see details
forge test -vv

# Run specific test
forge test --match-test testDepositToSingleVault

# Run with gas reporting
forge test --gas-report
```

## Learning Path

### Step 1: Understand the Concept (15 min)
Read `README.md` sections:
- Meta-vault concept
- Recursive share calculations
- Yield aggregation basics

### Step 2: Study the Skeleton (20 min)
Open `src/Project48.sol` and review:
- Contract structure
- State variables
- TODO comments explaining what to implement

Key functions to understand:
- `totalAssets()` - Recursive calculation core
- `_depositToUnderlying()` - Multi-vault distribution
- `_withdrawFromUnderlying()` - Multi-source withdrawal
- `rebalance()` - Vault optimization

### Step 3: Try to Implement (1-2 hours)
Implement the TODOs in `src/Project48.sol`:

```solidity
// Start with the easiest functions
1. addVault() - Validate and add underlying vault
2. totalAssets() - Sum assets from all vaults
3. _depositToUnderlying() - Distribute proportionally
4. _withdrawFromUnderlying() - Withdraw from vaults

// Then move to more complex functions
5. rebalance() - Shift funds between vaults
6. _findBestVault() - Yield comparison logic
```

### Step 4: Study the Solution (30 min)
Compare your implementation with `src/solution/Project48Solution.sol`

Key learnings:
- How recursive `totalAssets()` works
- Proportional deposit distribution
- Multi-vault withdrawal strategy
- Rebalancing algorithm

### Step 5: Run Tests (15 min)

```bash
# Test basic functionality
forge test --match-test testAddVault
forge test --match-test testDepositToSingleVault
forge test --match-test testTotalAssetsWithMultipleVaults

# Test recursive calculations
forge test --match-test testRecursiveYieldAccumulation
forge test --match-test testCompoundingYield

# Test rebalancing
forge test --match-test testRebalanceToTargetAllocation
forge test --match-test testAutoRebalanceToHighestYield
```

### Step 6: Explore Examples (30 min)
Read `EXAMPLES.md` for real-world usage patterns:
- Yield aggregation strategies
- Rebalancing techniques
- Advanced scenarios

## Key Concepts to Master

### 1. Recursive Asset Calculation

```solidity
function totalAssets() public view returns (uint256) {
    uint256 total = 0;

    for (uint256 i = 0; i < underlyingVaults.length; i++) {
        // Get our shares in underlying vault
        uint256 shares = underlyingVaults[i].balanceOf(address(this));

        // Convert to assets - THIS IS THE RECURSIVE PART
        uint256 assets = underlyingVaults[i].convertToAssets(shares);

        total += assets;
    }

    return total;
}
```

**Why this matters**: User shares → Meta-vault assets → Underlying shares → Actual assets. Each step uses `convertToAssets()`.

### 2. Proportional Distribution

```solidity
// Deposit 1000 tokens with 60/40 allocation
// Vault A gets: 1000 * 6000 / 10000 = 600
// Vault B gets: 1000 * 4000 / 10000 = 400

for (uint256 i = 0; i < vaults.length; i++) {
    uint256 amount = (assets * targetAllocations[i]) / TOTAL_BPS;
    vault.deposit(amount, address(this));
}
```

### 3. Rebalancing Logic

```solidity
// Current: 500 in A, 500 in B
// Target: 700 in A (70%), 300 in B (30%)

// Step 1: Withdraw 200 from B
vaultB.withdraw(200, address(this), address(this));

// Step 2: Deposit 200 to A
vaultA.deposit(200, address(this));

// Result: 700 in A, 300 in B ✓
```

## Common Challenges

### Challenge 1: Rounding Errors
**Problem**: Multiple conversions amplify rounding
**Solution**: Always round in favor of vault, accept small dust

### Challenge 2: Insufficient Liquidity
**Problem**: Vault doesn't have enough to withdraw
**Solution**: Withdraw from multiple vaults sequentially

```solidity
uint256 remaining = assets;
for (uint256 i = 0; i < vaults.length && remaining > 0; i++) {
    uint256 available = vault.maxWithdraw(address(this));
    uint256 toWithdraw = min(remaining, available);
    vault.withdraw(toWithdraw, address(this), address(this));
    remaining -= toWithdraw;
}
```

### Challenge 3: Gas Optimization
**Problem**: Rebalancing is expensive
**Solution**: Only rebalance when benefit exceeds cost

```solidity
// Check if drift exceeds threshold
if (drift > rebalanceThreshold) {
    rebalance(); // Only when necessary
}
```

## Testing Your Implementation

Create a simple test:

```solidity
function testMyImplementation() public {
    // 1. Deploy meta-vault
    // 2. Add underlying vaults
    metaVault.addVault(vaultA, 5000);
    metaVault.addVault(vaultB, 5000);

    // 3. User deposits
    vm.prank(alice);
    uint256 shares = metaVault.deposit(1000e18, alice);

    // 4. Check distribution
    assertApproxEqAbs(metaVault.getVaultAssets(0), 500e18, 1e18);
    assertApproxEqAbs(metaVault.getVaultAssets(1), 500e18, 1e18);

    // 5. Simulate yield
    vaultA.accrueYield();
    vaultB.accrueYield();

    // 6. Check user gained yield
    uint256 assets = metaVault.convertToAssets(shares);
    assertGt(assets, 1000e18);
}
```

## Deployment

### Local Testing

```bash
# Deploy mock vaults for testing
forge script script/DeployProject48.s.sol:DeployWithMockVaults --rpc-url http://localhost:8545 --broadcast
```

### Testnet Deployment

```bash
# Set environment variables
export PRIVATE_KEY=your_private_key
export UNDERLYING_ASSET=0x... # DAI/USDC address
export VAULT_A=0x...           # First vault address
export VAULT_B=0x...           # Second vault address

# Deploy
forge script script/DeployProject48.s.sol:DeployProject48 --rpc-url sepolia --broadcast --verify
```

### Mainnet Deployment

```bash
# IMPORTANT: Audit code before mainnet deployment!
# Use same process as testnet but with mainnet RPC
export MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY

forge script script/DeployProject48.s.sol:DeployProject48 \
    --rpc-url $MAINNET_RPC_URL \
    --broadcast \
    --verify
```

## Interactive Testing

Use Foundry's interactive console:

```bash
# Start local node
anvil

# In another terminal, load script
forge script script/DeployProject48.s.sol:DeployWithMockVaults --rpc-url http://localhost:8545 --broadcast

# Interact with deployed contracts
cast call <META_VAULT_ADDRESS> "totalAssets()" --rpc-url http://localhost:8545
```

## Next Steps

1. **Implement all TODOs** in `src/Project48.sol`
2. **Run tests** to verify correctness
3. **Study the solution** to learn best practices
4. **Experiment** with different allocation strategies
5. **Read examples** for real-world patterns
6. **Deploy to testnet** and interact with it

## Resources

- [ERC-4626 Spec](https://eips.ethereum.org/EIPS/eip-4626)
- [OpenZeppelin ERC4626](https://docs.openzeppelin.com/contracts/4.x/erc4626)
- [Foundry Book](https://book.getfoundry.sh/)
- [Yearn Vaults](https://docs.yearn.finance/)

## Getting Help

- Review `README.md` for concept explanations
- Check `EXAMPLES.md` for usage patterns
- Study tests in `test/Project48.t.sol`
- Compare with solution in `src/solution/Project48Solution.sol`

## Success Criteria

You've mastered this project when you can:

- [ ] Explain how recursive `totalAssets()` works
- [ ] Implement proportional deposit distribution
- [ ] Handle multi-vault withdrawals
- [ ] Build a rebalancing algorithm
- [ ] Calculate compounding yields and fees
- [ ] Write tests for edge cases
- [ ] Deploy and interact with the meta-vault
- [ ] Understand gas optimization trade-offs

**Time estimate**: 3-5 hours for complete implementation and testing.

Happy building!
