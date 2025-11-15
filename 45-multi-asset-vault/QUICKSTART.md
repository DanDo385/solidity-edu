# Multi-Asset Vault - Quick Start Guide

## Project Overview

This project implements a sophisticated multi-asset vault that holds a basket of ERC20 tokens with weighted allocations, similar to an index fund or ETF. It features dynamic rebalancing, oracle-based pricing, and comprehensive basket management.

## Files Structure

```
45-multi-asset-vault/
├── README.md                          # Comprehensive educational guide
├── QUICKSTART.md                      # This file
├── src/
│   ├── Project45.sol                  # Skeleton with TODOs
│   └── solution/
│       └── Project45Solution.sol      # Complete implementation
├── test/
│   └── Project45.t.sol                # Comprehensive test suite
└── script/
    └── DeployProject45.s.sol          # Deployment script
```

## Key Features

### 1. Multi-Asset Holdings
- Vault holds multiple ERC20 tokens in configurable proportions
- Supports up to 20 different assets
- Target weights defined in basis points (10000 = 100%)

### 2. NAV Calculation
- Real-time Net Asset Value calculation
- Oracle-based pricing (Chainlink compatible)
- Proper decimal normalization across different tokens
- Price per share tracking

### 3. Dynamic Rebalancing
- Threshold-based rebalancing (configurable deviation tolerance)
- DEX integration for swapping assets
- Slippage protection and tracking
- Minimum interval enforcement

### 4. User Operations
- Deposit base asset, receive vault shares
- Withdraw shares, receive proportional basket or base asset
- Preview functions for deposit/withdraw amounts
- Fee system (configurable deposit/withdraw fees)

### 5. Basket Management
- Add/remove assets from basket
- Adjust target weights
- Oracle configuration per asset
- Active/inactive asset states

## Learning Path

### Step 1: Understand the Concepts (README.md)
Read the comprehensive guide covering:
- Multi-asset vault design patterns
- Weighted NAV calculation formulas
- Rebalancing strategies
- Oracle integration best practices
- Index fund patterns
- Slippage handling

### Step 2: Study the Skeleton (src/Project45.sol)
Review the skeleton contract with:
- Complete structure and interfaces
- Function signatures with parameters
- TODO comments explaining what to implement
- Helper functions and view functions

### Step 3: Implement the TODOs
Work through each function:
1. **Asset Management**: `addAsset()`, `removeAsset()`, `setTargetWeight()`
2. **NAV Calculation**: `calculateNAV()`, `getPricePerShare()`, `getAssetValue()`
3. **Allocations**: `getCurrentWeights()`, `needsRebalancing()`
4. **User Operations**: `deposit()`, `withdraw()`, `preview*()` functions
5. **Rebalancing**: `rebalance()`, `calculateRebalanceAmounts()`

### Step 4: Study the Solution (src/solution/Project45Solution.sol)
Compare your implementation with the complete solution:
- Full error handling with custom errors
- SafeERC20 usage for token transfers
- Comprehensive oracle validation
- Efficient rebalancing algorithm
- Gas optimizations

### Step 5: Run Tests (test/Project45.t.sol)
Test coverage includes:
- ✅ Asset management (add, remove, weight updates)
- ✅ NAV calculations with multiple assets
- ✅ Oracle price changes and staleness
- ✅ Deposit/withdraw operations
- ✅ Current weight calculations
- ✅ Rebalancing logic
- ✅ Slippage tracking
- ✅ Edge cases and error conditions

### Step 6: Deploy (script/DeployProject45.s.sol)
Deploy to various networks:
- Pre-configured for Ethereum, Polygon, Arbitrum, Optimism, BSC
- Mock deployment for local testing
- Example index fund setup (DeFi Blue Chip)

## Quick Commands

```bash
# Install dependencies (from solidity-edu root)
forge install

# Build the project
forge build

# Run all tests
forge test

# Run specific test
forge test --match-test testCalculateNAV

# Run tests with gas reporting
forge test --gas-report

# Run tests with verbosity
forge test -vvv

# Deploy to local network
forge script script/DeployProject45.s.sol:DeployProject45 --fork-url http://localhost:8545 --broadcast

# Deploy to testnet
forge script script/DeployProject45.s.sol:DeployProject45 --rpc-url $SEPOLIA_RPC_URL --broadcast --verify

# Run local deployment with mocks
forge script script/DeployProject45.s.sol:DeployProject45 --sig "deployLocal()" --fork-url http://localhost:8545 --broadcast
```

## Key Concepts to Master

### 1. Weighted Portfolio Management
```solidity
// Each asset has a target weight
Asset {
    address token;         // ERC20 token
    uint256 targetWeight;  // Basis points (5000 = 50%)
    address priceOracle;   // Chainlink price feed
    bool active;           // Is asset in basket?
}

// Total weights must equal 10000 (100%)
```

### 2. NAV Calculation Formula
```
NAV = Σ (balance_i × price_i) for all assets i

where:
- balance_i = vault's balance of asset i
- price_i = oracle price of asset i (normalized to 18 decimals)
```

### 3. Share Price Calculation
```
Price Per Share = Total NAV / Total Shares Outstanding

On Deposit:
- shares_minted = (deposit_amount × total_shares) / NAV

On Withdraw:
- amount_received = (shares_burned × NAV) / total_shares
```

### 4. Rebalancing Logic
```
For each asset:
    target_value = NAV × target_weight / 10000
    current_value = balance × price

    if current_value > target_value:
        sell (current_value - target_value)

    if current_value < target_value:
        buy (target_value - current_value)
```

### 5. Oracle Integration
```solidity
// Chainlink price feed interface
IPriceOracle(oracle).latestRoundData()
    returns (roundId, price, startedAt, updatedAt, answeredInRound)

// Always validate:
1. price > 0
2. updatedAt is recent (< 1 hour old)
3. answeredInRound >= roundId
4. Normalize decimals to 18
```

## Common Use Cases

### 1. Crypto Index Fund
```solidity
// Market cap weighted crypto portfolio
addAsset(BTC, 4000, btcOracle);   // 40%
addAsset(ETH, 3000, ethOracle);   // 30%
addAsset(BNB, 2000, bnbOracle);   // 20%
addAsset(MATIC, 1000, maticOracle); // 10%
```

### 2. Stablecoin Diversification
```solidity
// Equal-weight stablecoin basket
addAsset(USDC, 2500, usdcOracle); // 25%
addAsset(USDT, 2500, usdtOracle); // 25%
addAsset(DAI, 2500, daiOracle);   // 25%
addAsset(FRAX, 2500, fraxOracle); // 25%
```

### 3. DeFi Blue Chip Index
```solidity
// Strategic allocation to DeFi leaders
addAsset(UNI, 3000, uniOracle);   // 30%
addAsset(AAVE, 2500, aaveOracle); // 25%
addAsset(CRV, 2500, crvOracle);   // 25%
addAsset(COMP, 2000, compOracle); // 20%
```

## Security Considerations

### Critical Checks
1. ✅ Oracle price staleness (< 1 hour)
2. ✅ Oracle price validity (> 0)
3. ✅ Slippage protection on swaps
4. ✅ Reentrancy guards on deposits/withdrawals
5. ✅ Total weights always equal 100%
6. ✅ SafeERC20 for token transfers
7. ✅ Access control on admin functions

### Potential Risks
- Oracle manipulation or failure
- DEX slippage/sandwich attacks
- Incompatible tokens (fee-on-transfer, rebasing)
- First depositor attack
- Rounding errors with different decimals

### Best Practices
- Use multiple oracle sources
- Implement circuit breakers
- Add pausability for emergencies
- Time-lock critical parameter changes
- Multi-sig for admin operations

## Testing Strategy

The test suite covers:
- **Unit Tests**: Individual function behavior
- **Integration Tests**: Multi-function workflows
- **Edge Cases**: Zero values, first depositor, extreme weights
- **Oracle Tests**: Price changes, staleness, invalid data
- **Rebalancing Tests**: Threshold detection, swap execution
- **Accounting Tests**: Share calculations, NAV accuracy

Run with different scenarios:
```bash
# Test with different asset counts
# Test with various price changes
# Test with different decimal configurations
# Test rebalancing under various market conditions
```

## Next Steps After Completion

1. **Advanced Features**:
   - Implement flash loan protection
   - Add leverage mechanisms
   - Support NFT-based positions
   - Cross-chain asset holdings

2. **Optimization**:
   - Gas optimization for rebalancing
   - Batch operations
   - Storage packing
   - View function caching

3. **Integration**:
   - Connect to DEX aggregators (1inch, Paraswap)
   - Multi-oracle support
   - Governance voting on basket composition
   - Performance fees and profit sharing

4. **Related Projects**:
   - Options vaults (covered calls)
   - Yield aggregators
   - Leveraged index products
   - Algorithmic rebalancing

## Resources

- [EIP-4626: Tokenized Vault Standard](https://eips.ethereum.org/EIPS/eip-4626)
- [Chainlink Price Feeds Documentation](https://docs.chain.link/data-feeds)
- [Uniswap V2 Router Documentation](https://docs.uniswap.org/contracts/v2/reference/smart-contracts/router-02)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Modern Portfolio Theory](https://www.investopedia.com/terms/m/modernportfoliotheory.asp)

## Support

For questions or issues:
1. Review the comprehensive README.md
2. Study the solution implementation
3. Check test cases for examples
4. Refer to inline code comments

Happy coding! 🚀
