# Project 18: Oracles (Chainlink) 🔮

> **Master external data integration with Chainlink price feeds and oracle safety patterns**

## 🎯 Learning Objectives

- Understand why blockchains need oracles
- Integrate Chainlink AggregatorV3Interface
- Detect and handle stale price data
- Implement circuit breaker patterns
- Recognize price manipulation risks
- Learn TWAP (Time-Weighted Average Price) patterns
- Use multiple oracle sources for redundancy

## 📚 Background: The Oracle Problem

### What is an Oracle?

Blockchains are deterministic, isolated systems. They cannot:
- Access real-world data (stock prices, weather, sports scores)
- Make HTTP requests to external APIs
- Generate truly random numbers
- Know the current temperature in Tokyo

**Oracles** are bridges that bring external data onto the blockchain in a trustworthy way.

### The Oracle Problem

**Centralization Risk**: A single oracle is a single point of failure.

```solidity
// BAD: Trusting a single source
uint256 price = oracle.getPrice(); // What if oracle is compromised?
```

**Solution**: Use decentralized oracle networks like Chainlink.

### Real-World Use Cases

| Use Case | Oracle Data Needed |
|----------|-------------------|
| **DeFi Lending** | ETH/USD price to calculate collateralization |
| **Stablecoins** | Asset prices for peg maintenance |
| **Prediction Markets** | Sports scores, election results |
| **Insurance** | Weather data for crop insurance |
| **NFT Dynamics** | External events to change NFT traits |
| **Derivatives** | Commodities prices (oil, gold) |

## 🔗 Chainlink Price Feeds

Chainlink is the most popular decentralized oracle network. It provides:
- **Price Feeds**: Crypto and traditional asset prices
- **Proof of Reserve**: Verify collateral backing
- **VRF (Verifiable Random Function)**: Provably random numbers
- **Any API**: Connect to any external data source

### AggregatorV3Interface

```solidity
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,        // The price
        uint256 startedAt,
        uint256 updatedAt,    // When price was updated
        uint80 answeredInRound
    );
}
```

### Example: ETH/USD Price Feed

```solidity
// Ethereum Mainnet ETH/USD: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
AggregatorV3Interface priceFeed = AggregatorV3Interface(feedAddress);

(
    uint80 roundId,
    int256 price,      // e.g., 200000000000 (8 decimals) = $2,000.00
    uint256 startedAt,
    uint256 updatedAt, // e.g., 1699876543 (Unix timestamp)
    uint80 answeredInRound
) = priceFeed.latestRoundData();

uint8 decimals = priceFeed.decimals(); // Usually 8 for USD pairs
```

## ⚠️ Oracle Safety Patterns

### 1. Stale Data Detection

**Problem**: Oracle hasn't updated recently, price may be outdated.

```solidity
// BAD: No staleness check
(, int256 price,,,) = priceFeed.latestRoundData();
require(price > 0, "Invalid price");

// GOOD: Check update time
(, int256 price,, uint256 updatedAt,) = priceFeed.latestRoundData();
require(updatedAt >= block.timestamp - STALENESS_THRESHOLD, "Stale price");
require(price > 0, "Invalid price");
```

**Recommendation**: Set threshold based on feed's heartbeat (usually 1-24 hours).

### 2. Price Validity Checks

**Problem**: Oracle might return invalid data (0, negative for some types).

```solidity
// Check for valid price range
require(price > 0, "Invalid price");
require(price < MAX_REASONABLE_PRICE, "Price too high");

// Check round completeness
require(answeredInRound >= roundId, "Stale round");
```

### 3. Circuit Breaker Pattern

**Problem**: Extreme price swings might indicate oracle manipulation or market chaos.

```solidity
// Store previous price
uint256 previousPrice = lastStoredPrice;
uint256 currentPrice = uint256(price);

// Check for extreme deviation
uint256 deviation = currentPrice > previousPrice
    ? (currentPrice - previousPrice) * 100 / previousPrice
    : (previousPrice - currentPrice) * 100 / previousPrice;

require(deviation <= MAX_PRICE_DEVIATION, "Circuit breaker triggered");
```

### 4. Multiple Oracle Sources

**Best Practice**: Use multiple oracles and compare/aggregate results.

```solidity
// Get price from two different sources
uint256 chainlinkPrice = getChainlinkPrice();
uint256 uniswapTWAP = getUniswapTWAP();

// Ensure they agree within tolerance
uint256 diff = chainlinkPrice > uniswapTWAP
    ? chainlinkPrice - uniswapTWAP
    : uniswapTWAP - chainlinkPrice;

require(diff * 100 / chainlinkPrice <= PRICE_TOLERANCE, "Oracle mismatch");
```

## 📊 TWAP (Time-Weighted Average Price)

TWAP smooths out price volatility and prevents manipulation.

### Why TWAP?

```solidity
// Spot price: Easily manipulated by flash loans
uint256 spotPrice = getCurrentPrice(); // Can be manipulated in 1 block!

// TWAP: Average over time window
uint256 twapPrice = getTWAP(30 minutes); // Harder to manipulate
```

### Uniswap V3 TWAP

```solidity
// Observe price at two time points
(int56 tickCumulative1,) = pool.observe(secondsAgo1);
(int56 tickCumulative2,) = pool.observe(secondsAgo2);

// Calculate time-weighted average
int56 tickDelta = tickCumulative1 - tickCumulative2;
int24 averageTick = int24(tickDelta / int56(uint56(period)));

// Convert tick to price
uint256 twapPrice = getTokenPriceFromTick(averageTick);
```

## 🚨 Price Manipulation Risks

### Flash Loan Attack

```solidity
// Attacker takes flash loan
// 1. Borrow 10,000 ETH
// 2. Swap all ETH for TOKEN on DEX (pumps TOKEN price)
// 3. Oracle reads manipulated price
// 4. Attacker exploits protocol using inflated price
// 5. Repay flash loan with profit
```

**Defense**: Use TWAP or Chainlink (which aggregates across multiple blocks).

### Frontrunning Oracle Updates

```solidity
// Attacker sees oracle update in mempool
// 1. Oracle will update price from $100 to $120
// 2. Attacker frontruns with transaction benefiting from $100
// 3. Oracle updates to $120
// 4. Attacker backs out transaction profiting from $120
```

**Defense**: Use commit-reveal schemes or limit impact of single transactions.

### Stale Price Exploitation

```solidity
// Price feed hasn't updated in 6 hours
// Real price: $2000, Oracle price: $1800
// Attacker uses stale $1800 price to get unfair liquidation/borrowing terms
```

**Defense**: Enforce staleness thresholds.

## 🔧 What You'll Build

A robust oracle integration system that:
- Integrates Chainlink ETH/USD price feed
- Detects stale data with configurable thresholds
- Implements circuit breaker for extreme price swings
- Validates price ranges and round data
- Demonstrates multi-oracle patterns
- Includes comprehensive safety checks

## 📝 Tasks

### Task 1: Implement the Skeleton Contract

Open `src/Project18.sol` and implement:

1. **Oracle integration** - Connect to Chainlink price feed
2. **Price retrieval** - Get latest price with all safety checks
3. **Staleness detection** - Reject outdated prices
4. **Price validation** - Verify price is within reasonable bounds
5. **Circuit breaker** - Pause on extreme price movements

### Task 2: Study the Solution

Compare with `src/solution/Project18Solution.sol`:
- Understand all safety checks
- See how circuit breaker works
- Learn proper error handling
- Study multi-oracle patterns
- Review detailed comments explaining oracle risks

### Task 3: Run Comprehensive Tests

```bash
cd 18-oracles-chainlink

# Run all tests
forge test -vvv

# Test specific scenarios
forge test --match-test test_GetPrice
forge test --match-test test_StalePrice
forge test --match-test test_CircuitBreaker

# Gas report
forge test --gas-report

# Coverage
forge coverage
```

### Task 4: Deploy and Test

```bash
# Start local node
anvil

# Deploy (in another terminal)
forge script script/DeployProject18.s.sol --broadcast --rpc-url http://localhost:8545

# Get current price
cast call <CONTRACT_ADDRESS> "getLatestPrice()(uint256)"

# Check last update time
cast call <CONTRACT_ADDRESS> "getLastUpdateTime()(uint256)"
```

### Task 5: Experiment with Mainnet Fork

```bash
# Fork Ethereum mainnet
anvil --fork-url https://eth-mainnet.g.alchemy.com/v2/INFURA_RPC_URL

# Deploy against real Chainlink feeds
forge script script/DeployProject18.s.sol --broadcast \
  --rpc-url http://localhost:8545

# See real ETH/USD price from Chainlink
cast call <CONTRACT_ADDRESS> "getLatestPrice()(uint256)"
```

## 🧪 Test Coverage

The test suite covers:

- ✅ Basic price retrieval
- ✅ Stale price detection and rejection
- ✅ Invalid price handling (zero, negative)
- ✅ Circuit breaker triggering on large swings
- ✅ Round data validation
- ✅ Edge cases (first price, exactly at threshold)
- ✅ Mock oracle for testing
- ✅ Decimal handling
- ✅ Access control
- ✅ Emergency pause functionality

## ⚠️ Security Considerations

### 1. Always Check Staleness

```solidity
// Never use price without checking update time
require(block.timestamp - updatedAt <= STALENESS_THRESHOLD);
```

### 2. Validate Price Range

```solidity
// Sanity check: ETH shouldn't be $0 or $1,000,000
require(price > MIN_PRICE && price < MAX_PRICE);
```

### 3. Check Round Completeness

```solidity
// Ensure the round actually completed
require(answeredInRound >= roundId);
```

### 4. Handle Oracle Failures Gracefully

```solidity
try priceFeed.latestRoundData() returns (...) {
    // Use price
} catch {
    // Fallback: pause system, use backup oracle, etc.
    revert("Oracle unavailable");
}
```

### 5. Circuit Breaker for Black Swan Events

```solidity
// If price changes >50% in one update, something is wrong
if (deviation > MAX_DEVIATION) {
    _pause(); // Stop all operations
    emit CircuitBreakerTriggered(price);
}
```

### 6. Use Multiple Oracles When Possible

```solidity
// Compare Chainlink and Uniswap TWAP
require(abs(chainlinkPrice - twapPrice) < TOLERANCE);
```

## 📊 Chainlink Feed Addresses

### Ethereum Mainnet

| Pair | Address |
|------|---------|
| ETH/USD | `0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419` |
| BTC/USD | `0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c` |
| USDC/USD | `0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6` |
| DAI/USD | `0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9` |

### Sepolia Testnet

| Pair | Address |
|------|---------|
| ETH/USD | `0x694AA1769357215DE4FAC081bf1f309aDC325306` |
| BTC/USD | `0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43` |

Find more at: [Chainlink Data Feeds](https://docs.chain.link/data-feeds/price-feeds/addresses)

## 🌍 Real-World Examples

### Aave Lending Protocol

```solidity
// Aave uses Chainlink for collateral pricing
IPriceOracle oracle = IPoolAddressesProvider(provider).getPriceOracle();
uint256 ethPrice = oracle.getAssetPrice(WETH);

// Calculate if user is eligible for loan
uint256 collateralValue = userCollateral * ethPrice / 1e18;
uint256 borrowLimit = collateralValue * LTV / 100;
require(borrowAmount <= borrowLimit);
```

### MakerDAO DAI Stability

```solidity
// MakerDAO uses multiple oracles (Chainlink + custom)
uint256 ethPrice = getMedianPrice(); // Median of many sources

// Determine if vault is undercollateralized
uint256 collateralValue = vaultETH * ethPrice;
uint256 debtValue = vaultDAI;
uint256 ratio = collateralValue * 100 / debtValue;

if (ratio < LIQUIDATION_RATIO) {
    liquidate(vault);
}
```

### Synthetix Synthetic Assets

```solidity
// Synthetix uses Chainlink for all synth prices
uint256 sETHPrice = getChainlinkPrice("sETH");
uint256 sBTCPrice = getChainlinkPrice("sBTC");

// Trade synthetic assets
exchange(sETH, sBTC, amount);
```

## ✅ Completion Checklist

- [ ] Integrated Chainlink AggregatorV3Interface
- [ ] Implemented stale price detection
- [ ] Added price validation checks
- [ ] Built circuit breaker pattern
- [ ] All tests pass
- [ ] Understand oracle manipulation risks
- [ ] Can explain TWAP vs spot price
- [ ] Deployed and tested with real price feeds
- [ ] Studied real-world oracle usage
- [ ] Know how to use multiple oracle sources

## 💡 Pro Tips

1. **Heartbeat varies by feed** - Check Chainlink docs for each feed's update frequency
2. **Decimals matter** - Always check `decimals()`, don't assume 18
3. **Gas optimization** - Cache oracle results if using multiple times in one transaction
4. **Emergency pause** - Always have a way to pause if oracle fails
5. **Monitor off-chain** - Set up alerts if oracle becomes stale
6. **Test with forks** - Use mainnet forks to test with real Chainlink feeds
7. **Fallback oracles** - Consider secondary oracle sources for critical operations
8. **Price impact limits** - Limit how much one transaction can move based on oracle price

## 🚀 Next Steps

After completing this project:

- **Chainlink VRF**: Learn verifiable randomness for NFTs and gaming
- **Chainlink Automation**: Trigger contract functions automatically
- **Custom oracles**: Build your own oracle for custom data
- **Multi-oracle aggregation**: Combine Chainlink, Band Protocol, API3
- **MEV protection**: Study how oracle timing affects MEV
- **Cross-chain oracles**: Use Chainlink CCIP for cross-chain data

## 📖 Further Reading

- [Chainlink Documentation](https://docs.chain.link/)
- [AggregatorV3Interface Reference](https://docs.chain.link/data-feeds/api-reference)
- [Oracle Security Best Practices](https://blog.chain.link/secure-data-oracle/)
- [TWAP Oracles Explained](https://docs.uniswap.org/concepts/protocol/oracle)
- [Oracle Manipulation Attacks](https://github.com/0xcacti/awesome-oracle-manipulation)
- [Euler Finance Oracle Attack Post-Mortem](https://www.euler.finance/)

## 🎓 Key Takeaways

1. **Never trust spot prices** - Use TWAP or decentralized oracles
2. **Always check staleness** - Old prices are dangerous
3. **Validate everything** - Don't assume oracle data is correct
4. **Circuit breakers save protocols** - Pause on anomalies
5. **Multiple sources** - Redundancy protects against oracle failures
6. **Understand attack vectors** - Flash loans, frontrunning, manipulation
7. **Test with real data** - Fork mainnet to test with actual Chainlink feeds

---

**Great work!** You now understand how to safely integrate external data into smart contracts using Chainlink oracles. This is critical knowledge for building production DeFi protocols.

**Keep learning! 🔮**
