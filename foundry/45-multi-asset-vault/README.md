# Project 45: Multi-Asset Vault

A sophisticated vault system that holds multiple underlying assets with weighted allocations, dynamic rebalancing, and oracle-based NAV calculations. This project demonstrates index fund patterns and basket management strategies.

## Concepts Covered

### 1. Multi-Asset Vault Design

A multi-asset vault holds a basket of different ERC20 tokens, representing diversified exposure similar to an index fund or ETF.

**Key Components:**
```solidity
struct Asset {
    address token;          // ERC20 token address
    uint256 targetWeight;   // Target allocation (basis points, 10000 = 100%)
    address priceOracle;    // Chainlink-style oracle for pricing
}

// Vault holds multiple assets
Asset[] public assets;
mapping(address => uint256) public assetIndex;
```

**Design Principles:**
- Vault shares represent proportional ownership of the entire basket
- Users deposit/withdraw in a base asset (e.g., USDC)
- Vault internally manages multiple positions
- Shares are minted/burned based on NAV

### 2. Weighted NAV Calculation: Portfolio Valuation

**FIRST PRINCIPLES: Net Asset Value**

Net Asset Value (NAV) represents the total value of all vault holdings. This is fundamental to multi-asset vaults!

**CONNECTION TO PROJECT 11, 18, & 20**:
- **Project 11**: ERC-4626 vaults calculate share prices
- **Project 18**: Oracles provide price data
- **Project 20**: Share-based accounting fundamentals
- **Project 45**: Multi-asset NAV combines all concepts!

**NAV FORMULA**:

```
NAV = Σ (balance_i × price_i) for all assets i

Price Per Share = NAV / Total Shares
```

**UNDERSTANDING THE CALCULATION** (from Project 01 & 18 knowledge):

```
NAV Calculation Flow:
┌─────────────────────────────────────────┐
│ For each asset in vault:                │
│   1. Get balance: balanceOf(vault)     │ ← From Project 08 (ERC20)
│   2. Get price: oracle.getPrice()      │ ← From Project 18 (Oracle)
│   3. Calculate value: balance × price   │ ← Arithmetic
│   4. Sum all values                     │ ← Accumulator pattern
│   ↓                                      │
│ NAV = sum of all asset values           │ ← Total portfolio value
│   ↓                                      │
│ Price per share = NAV / totalShares     │ ← From Project 11!
└─────────────────────────────────────────┘
```

**EXAMPLE CALCULATION**:

```
Multi-Asset Portfolio:
┌─────────────────────────────────────────┐
│ Asset A (ETH):                          │
│   Balance: 100 tokens                   │
│   Price: $2,000 (from oracle)          │
│   Value: 100 × $2,000 = $200,000       │
│                                          │
│ Asset B (USDC):                         │
│   Balance: 500,000 tokens               │
│   Price: $1.00 (stablecoin)             │
│   Value: 500,000 × $1.00 = $500,000    │
│                                          │
│ Asset C (WBTC):                         │
│   Balance: 10 tokens                    │
│   Price: $30,000 (from oracle)         │
│   Value: 10 × $30,000 = $300,000       │
│   ↓                                      │
│ Total NAV = $1,000,000                  │ ← Portfolio value
│                                          │
│ If 1,000,000 shares exist:              │
│   Price Per Share = $1,000,000 / 1,000,000│
│   Price Per Share = $1.00               │ ← Share value
└─────────────────────────────────────────┘
```

**GAS COST BREAKDOWN** (from Project 01, 06, & 18 knowledge):

**NAV Calculation**:
- Oracle calls: ~100 gas × N assets (view functions)
- Balance reads: ~100 gas × N assets (SLOAD from ERC20)
- Arithmetic: ~10 gas × N assets (multiplication)
- Total: ~210 gas × N assets (for N assets)

**Example** (3 assets):
- Oracle calls: ~300 gas
- Balance reads: ~300 gas
- Arithmetic: ~30 gas
- Total: ~630 gas (cheap for portfolio valuation!)

**REAL-WORLD ANALOGY**: 
Like calculating the value of an investment portfolio:
- **Assets** = Different stocks/bonds in portfolio
- **Prices** = Current market prices (from exchanges/oracles)
- **NAV** = Total portfolio value
- **Shares** = Units of ownership in the portfolio
- **Price per share** = NAV / shares (how much each share is worth)

**Weighted Allocation:**
```solidity
function calculateNAV() public view returns (uint256) {
    uint256 totalValue = 0;

    for (uint256 i = 0; i < assets.length; i++) {
        uint256 balance = IERC20(assets[i].token).balanceOf(address(this));
        uint256 price = IPriceOracle(assets[i].priceOracle).getPrice();
        totalValue += (balance * price) / 1e18; // Normalize decimals
    }

    return totalValue;
}
```

### 3. Rebalancing Strategies

Rebalancing maintains target weights as asset prices fluctuate.

**Types of Rebalancing:**

**a) Periodic Rebalancing:**
- Fixed schedule (daily, weekly, monthly)
- Predictable but may miss optimal timing

**b) Threshold-Based Rebalancing:**
```solidity
// Rebalance when allocation drifts beyond threshold
if (abs(currentWeight - targetWeight) > threshold) {
    rebalance();
}
```

**c) Opportunistic Rebalancing:**
- Rebalance during deposits/withdrawals
- Minimizes separate transactions

**Rebalancing Process:**
1. Calculate current allocations
2. Determine required swaps
3. Execute trades via DEX
4. Account for slippage
5. Verify new allocations

### 4. Oracle Integration for Pricing

Accurate pricing is critical for NAV calculations.

**Oracle Interface:**
```solidity
interface IPriceOracle {
    function getPrice() external view returns (uint256);
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
}
```

**Chainlink Integration:**
```solidity
function getAssetPrice(address asset) public view returns (uint256) {
    uint256 idx = assetIndex[asset];
    IPriceOracle oracle = IPriceOracle(assets[idx].priceOracle);

    // Chainlink returns price with 8 decimals typically
    uint256 price = oracle.getPrice();
    uint8 oracleDecimals = oracle.decimals();

    // Normalize to 18 decimals
    return price * 10**(18 - oracleDecimals);
}
```

**Oracle Considerations:**
- Price freshness (check timestamps)
- Circuit breakers for stale data
- Multiple oracle sources for validation
- Fallback pricing mechanisms

### 5. Basket Composition Management

Managing which assets are in the basket and their target weights.

**Adding Assets:**
```solidity
function addAsset(
    address token,
    uint256 targetWeight,
    address oracle
) external onlyOwner {
    require(targetWeight > 0, "Invalid weight");
    require(getTotalWeight() + targetWeight <= 10000, "Exceeds 100%");

    assets.push(Asset({
        token: token,
        targetWeight: targetWeight,
        priceOracle: oracle
    }));
}
```

**Adjusting Weights:**
```solidity
function setTargetWeight(address token, uint256 newWeight) external onlyOwner {
    uint256 idx = assetIndex[token];
    assets[idx].targetWeight = newWeight;

    // Ensure total weights = 100%
    require(getTotalWeight() == 10000, "Weights must sum to 100%");

    emit WeightUpdated(token, newWeight);
}
```

**Basket Constraints:**
- Total weights must equal 100% (10,000 basis points)
- Minimum/maximum position sizes
- Asset eligibility criteria
- Diversification requirements

### 6. Index Fund Patterns

Multi-asset vaults implement index fund strategies.

**Common Index Strategies:**

**a) Market Cap Weighted:**
```solidity
// Weight by market capitalization
weight_i = marketCap_i / Σ(marketCap_j)
```

**b) Equal Weight:**
```solidity
// Equal allocation to all assets
weight_i = 1 / n  // where n = number of assets
```

**c) Risk Parity:**
```solidity
// Weight by inverse volatility
weight_i = (1/volatility_i) / Σ(1/volatility_j)
```

**d) Custom Strategic:**
- Fundamental analysis
- Sector allocations
- Thematic exposure

**Deposit/Withdraw Flow:**
```solidity
// User deposits base asset
function deposit(uint256 amount) external {
    baseAsset.transferFrom(msg.sender, address(this), amount);

    // Calculate shares based on current NAV
    uint256 nav = calculateNAV();
    uint256 shares = (amount * totalShares) / nav;

    // Allocate deposited funds across basket
    allocateToBasket(amount);

    _mint(msg.sender, shares);
}

// User withdraws proportional basket
function withdraw(uint256 shares) external {
    require(balanceOf(msg.sender) >= shares, "Insufficient shares");

    uint256 proportion = (shares * 1e18) / totalSupply();

    // Withdraw proportional amount of each asset
    for (uint256 i = 0; i < assets.length; i++) {
        uint256 assetBalance = IERC20(assets[i].token).balanceOf(address(this));
        uint256 withdrawAmount = (assetBalance * proportion) / 1e18;
        IERC20(assets[i].token).transfer(msg.sender, withdrawAmount);
    }

    _burn(msg.sender, shares);
}
```

### 7. Slippage in Rebalancing

Rebalancing requires trading, which incurs slippage.

**Slippage Sources:**
1. **Price Impact** - Large trades move the market
2. **Fees** - DEX fees reduce effective price
3. **Price Movement** - Market moves during execution
4. **MEV** - Front-running and sandwich attacks

**Slippage Protection:**
```solidity
function rebalanceAsset(
    address fromAsset,
    address toAsset,
    uint256 amountIn,
    uint256 minAmountOut  // Slippage protection
) internal {
    // Calculate expected output
    uint256 expectedOut = getExpectedOutput(fromAsset, toAsset, amountIn);

    // Apply slippage tolerance (e.g., 1%)
    uint256 minAcceptable = (expectedOut * 9900) / 10000;
    require(minAmountOut >= minAcceptable, "Excessive slippage");

    // Execute swap
    uint256 actualOut = executeDEXSwap(fromAsset, toAsset, amountIn, minAmountOut);

    // Track slippage for analytics
    uint256 slippage = expectedOut > actualOut
        ? ((expectedOut - actualOut) * 10000) / expectedOut
        : 0;

    emit Rebalanced(fromAsset, toAsset, amountIn, actualOut, slippage);
}
```

**Minimizing Slippage:**
- Split large trades across multiple blocks
- Use TWAP (Time-Weighted Average Price) execution
- Route through optimal DEX/aggregator
- Consider limit orders instead of market orders
- Rebalance during high liquidity periods

**Slippage Accounting:**
```solidity
// Track cumulative slippage costs
uint256 public cumulativeSlippage;
uint256 public rebalanceCount;

function averageSlippage() public view returns (uint256) {
    return rebalanceCount > 0 ? cumulativeSlippage / rebalanceCount : 0;
}
```

## Architecture

### Contract Structure

```
MultiAssetVault (ERC20 vault shares)
├── Asset Management
│   ├── addAsset()
│   ├── removeAsset()
│   └── setTargetWeight()
├── NAV Calculation
│   ├── calculateNAV()
│   ├── getPricePerShare()
│   └── getAssetValue()
├── User Operations
│   ├── deposit()
│   ├── withdraw()
│   └── previewDeposit/Withdraw()
└── Rebalancing
    ├── rebalance()
    ├── needsRebalancing()
    └── calculateRebalanceAmounts()
```

### State Variables

```solidity
// Asset configuration
Asset[] public assets;
mapping(address => uint256) public assetIndex;

// Rebalancing configuration
uint256 public rebalanceThreshold;  // Basis points
uint256 public lastRebalance;
uint256 public minRebalanceInterval;

// Performance tracking
uint256 public totalDeposited;
uint256 public totalWithdrawn;
uint256 public totalSlippage;
```

## Use Cases

### 1. Crypto Index Fund
Hold top cryptocurrencies weighted by market cap:
- 40% BTC
- 30% ETH
- 20% BNB
- 10% MATIC

### 2. Stablecoin Basket
Diversified stablecoin exposure:
- 25% USDC
- 25% USDT
- 25% DAI
- 25% FRAX

### 3. DeFi Blue Chip
Exposure to leading DeFi protocols:
- 30% UNI
- 25% AAVE
- 25% CRV
- 20% COMP

### 4. Sector Rotation
Dynamic allocation based on market conditions:
- Adjust weights based on momentum
- Shift between growth/value
- Risk-on/risk-off positioning

## Security Considerations

### 1. Oracle Risks
- **Stale Prices**: Verify oracle freshness
- **Oracle Manipulation**: Use multiple sources
- **Circuit Breakers**: Halt on suspicious prices

### 2. Rebalancing Risks
- **Sandwich Attacks**: Use private transactions/flashbots
- **Slippage**: Enforce strict tolerance
- **Failed Swaps**: Handle gracefully without bricking vault

### 3. Asset Risks
- **Token Blacklisting**: Some tokens can freeze addresses
- **Pausable Tokens**: Handle paused transfers
- **Fee-on-Transfer**: Account for transfer fees
- **Rebasing Tokens**: Incompatible with vault accounting

### 4. Access Control
- **Admin Powers**: Time-lock critical operations
- **Multi-sig**: Require multiple approvals for basket changes
- **Emergency Pause**: Circuit breaker for emergencies

### 5. Accounting Precision
- **Decimal Normalization**: Handle different token decimals
- **Rounding Errors**: Prevent dust accumulation
- **NAV Manipulation**: Prevent first depositor attack

## Gas Optimization

### 1. Batch Operations
```solidity
// Rebalance multiple assets in one transaction
function rebalanceMultiple(RebalanceOrder[] calldata orders) external {
    for (uint256 i = 0; i < orders.length; i++) {
        executeRebalance(orders[i]);
    }
}
```

### 2. Lazy NAV Updates
```solidity
// Only calculate NAV when needed
uint256 private cachedNAV;
uint256 private navTimestamp;

function getNAV() public returns (uint256) {
    if (block.timestamp > navTimestamp + NAV_CACHE_DURATION) {
        cachedNAV = calculateNAV();
        navTimestamp = block.timestamp;
    }
    return cachedNAV;
}
```

### 3. Packed Storage
```solidity
// Pack weights into single storage slot
struct PackedAsset {
    address token;           // 20 bytes
    uint64 targetWeight;     // 8 bytes (sufficient for basis points)
    uint32 lastRebalance;    // 4 bytes (timestamp)
}
```

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/MultiAssetVaultSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployMultiAssetVaultSolution.s.sol` - Deployment script patterns
- `test/solution/MultiAssetVaultSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains portfolio valuation, weighted NAV calculations, rebalancing algorithms
- **Connections to Project 11**: ERC-4626 vault standard (this extends it to multiple assets)
- **Connections to Project 18**: Oracle integration for multi-asset pricing
- **Connections to Project 20**: Share-based accounting for basket ownership
- **Real-World Context**: Index fund/ETF pattern - diversified exposure in single vault

## Testing Checklist

- [ ] NAV calculation with multiple assets
- [ ] NAV accuracy with different decimals
- [ ] Deposit mints correct shares based on NAV
- [ ] Withdraw burns shares and returns correct amounts
- [ ] Rebalancing brings weights within threshold
- [ ] Slippage protection prevents excessive losses
- [ ] Oracle price changes update NAV correctly
- [ ] Adding/removing assets updates basket
- [ ] Weight adjustments maintain 100% total
- [ ] First depositor attack prevention
- [ ] Handling failed rebalancing swaps
- [ ] Emergency pause functionality
- [ ] Multi-asset deposit optimization
- [ ] Proportional withdrawal accuracy
- [ ] Performance fee calculation

## Additional Resources

- [Chainlink Price Feeds](https://docs.chain.link/data-feeds/price-feeds)
- [ERC4626 Tokenized Vault Standard](https://eips.ethereum.org/EIPS/eip-4626)
- [Uniswap V3 Swaps](https://docs.uniswap.org/contracts/v3/guides/swaps/single-swaps)
- [Index Fund Strategies](https://www.investopedia.com/terms/i/indexfund.asp)
- [Modern Portfolio Theory](https://www.investopedia.com/terms/m/modernportfoliotheory.asp)

## Next Steps

After completing this project, explore:
- **Leveraged Vaults**: Borrow against collateral for amplified returns
- **Options Vaults**: Generate yield through covered calls
- **Cross-Chain Vaults**: Hold assets across multiple chains
- **Algorithmic Rebalancing**: ML-based dynamic allocation
- **Governance Integration**: Let token holders vote on basket composition
