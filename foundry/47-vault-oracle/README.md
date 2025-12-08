# Project 47: Vault Oracle Integration

A comprehensive guide to implementing secure oracle integration for vaults, focusing on price feeds, TWAP mechanisms, and oracle failure handling.

## Overview

This project teaches how to safely integrate price oracles into vault systems. Oracles are critical for determining asset values, but they introduce significant security risks if not implemented correctly. Learn how to protect against stale data, price manipulation, and oracle failures.

## Concepts

### Oracle Integration for Vaults: Secure Price Feeds

**FIRST PRINCIPLES: Trust in External Data**

Vaults need accurate price data to calculate values and prevent manipulation. Understanding oracle security is critical!

**CONNECTION TO PROJECT 11, 18, & 34**:
- **Project 11**: ERC-4626 vaults need price data
- **Project 18**: Chainlink oracle integration
- **Project 34**: Oracle manipulation attacks
- **Project 47**: Secure oracle integration for vaults!

Vaults need accurate price data to:
- Calculate total value locked (TVL)
- Determine share prices (from Project 11: `convertToAssets()`)
- Enforce price-based limits
- Trigger rebalancing (from Project 45: multi-asset vaults)
- Prevent sandwich attacks (from Project 33: MEV protection)

**KEY CHALLENGES**:

**VULNERABLE PATTERN**:
```solidity
// ❌ BAD: Direct oracle usage without validation
function getShareValue() external view returns (uint256) {
    uint256 price = oracle.getPrice();  // ❌ No staleness check!
    return (totalAssets() * price) / totalSupply();  // From Project 11!
}
```

**PROBLEMS**:
- Stale data: Oracle might not have updated recently
- Manipulation: Flash loan attacks can manipulate price (from Project 34)
- Failure: Oracle might be down or returning bad data

**SECURE PATTERN**:
```solidity
// ✅ GOOD: Validated oracle usage
function getShareValue() external view returns (uint256) {
    (uint256 price, bool isValid) = _getValidatedPrice();  // ✅ Validation!
    require(isValid, "Invalid oracle price");  // ✅ Revert if invalid
    return (totalAssets() * price) / totalSupply();
}

function _getValidatedPrice() internal view returns (uint256, bool) {
    (uint256 price, uint256 updatedAt) = oracle.getPrice();
    
    // ✅ Check staleness (from Project 18 knowledge)
    if (block.timestamp - updatedAt > MAX_STALENESS) {
        return (0, false);  // Stale data!
    }
    
    // ✅ Check price bounds (prevent manipulation)
    if (price < MIN_PRICE || price > MAX_PRICE) {
        return (0, false);  // Suspicious price!
    }
    
    return (price, true);
}
```

**GAS COST** (from Project 01 & 18 knowledge):
- Oracle call: ~100 gas (view function)
- Staleness check: ~10 gas (arithmetic)
- Bounds check: ~20 gas (comparisons)
- Total: ~130 gas (cheap security check!)

### TWAP (Time-Weighted Average Price)

TWAP protects against short-term price manipulation:

**How TWAP Works:**
```solidity
// Store cumulative price over time
struct Observation {
    uint256 timestamp;
    uint256 cumulativePrice;
}

// Calculate TWAP over period
function getTWAP(uint256 period) public view returns (uint256) {
    Observation memory current = observations[observationIndex];
    Observation memory old = _getObservationAt(block.timestamp - period);

    uint256 priceDelta = current.cumulativePrice - old.cumulativePrice;
    uint256 timeDelta = current.timestamp - old.timestamp;

    return priceDelta / timeDelta;
}
```

**Benefits:**
- Smooths out price volatility
- Makes manipulation expensive (must maintain price over time)
- Provides more stable vault valuations

### Stale Data Handling

Oracles can fail or stop updating. Always check freshness:

```solidity
// Chainlink example
function _isStale(uint256 updatedAt) internal view returns (bool) {
    // Data older than MAX_STALENESS is rejected
    return block.timestamp - updatedAt > MAX_STALENESS;
}

function _getChainlinkPrice() internal view returns (uint256, bool) {
    (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) = priceFeed.latestRoundData();

    // Check for stale data
    if (_isStale(updatedAt)) return (0, false);

    // Check for incomplete round
    if (answeredInRound < roundId) return (0, false);

    // Check for invalid price
    if (answer <= 0) return (0, false);

    return (uint256(answer), true);
}
```

**Staleness Thresholds:**
- High-frequency assets (ETH, BTC): 1 hour
- Stable assets (USDC): 24 hours
- Exotic assets: Custom based on liquidity

### Price Deviation Limits

Protect against oracle errors by limiting price changes:

```solidity
uint256 public constant MAX_PRICE_DEVIATION = 1000; // 10%

function _isReasonablePrice(uint256 newPrice, uint256 oldPrice)
    internal
    pure
    returns (bool)
{
    if (oldPrice == 0) return true; // First price

    uint256 deviation;
    if (newPrice > oldPrice) {
        deviation = ((newPrice - oldPrice) * 10000) / oldPrice;
    } else {
        deviation = ((oldPrice - newPrice) * 10000) / oldPrice;
    }

    return deviation <= MAX_PRICE_DEVIATION;
}
```

**Why This Matters:**
- Oracle bugs can report incorrect prices
- Flash crashes might not represent true value
- Protects users from unfair liquidations/swaps

### Multi-Oracle Strategies

Using multiple oracles increases security:

**1. Primary + Fallback:**
```solidity
function getPrice() public view returns (uint256) {
    (uint256 price, bool valid) = _getPrimaryOraclePrice();
    if (valid) return price;

    (price, valid) = _getFallbackOraclePrice();
    require(valid, "All oracles failed");
    return price;
}
```

**2. Median of Multiple Oracles:**
```solidity
function getMedianPrice() public view returns (uint256) {
    uint256[] memory prices = new uint256[](3);
    prices[0] = oracle1.getPrice();
    prices[1] = oracle2.getPrice();
    prices[2] = oracle3.getPrice();

    // Sort and return median
    _sort(prices);
    return prices[1];
}
```

**3. Deviation Check:**
```solidity
function getConsensusPrice() public view returns (uint256, bool) {
    uint256 price1 = oracle1.getPrice();
    uint256 price2 = oracle2.getPrice();

    uint256 deviation = _calculateDeviation(price1, price2);
    if (deviation > MAX_ORACLE_DEVIATION) {
        return (0, false); // Oracles disagree too much
    }

    return ((price1 + price2) / 2, true);
}
```

### Chainlink Integration

Chainlink is the most widely used oracle network:

**Basic Integration:**
```solidity
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ChainlinkVault {
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function getLatestPrice() public view returns (uint256) {
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        require(answer > 0, "Invalid price");
        require(updatedAt > 0, "Round not complete");
        require(answeredInRound >= roundId, "Stale price");

        return uint256(answer);
    }
}
```

**Decimal Handling:**
```solidity
// Chainlink prices have varying decimals (usually 8 for USD pairs)
function _normalizePrice(int256 price) internal view returns (uint256) {
    uint8 decimals = priceFeed.decimals();

    // Normalize to 18 decimals
    if (decimals < 18) {
        return uint256(price) * 10 ** (18 - decimals);
    } else if (decimals > 18) {
        return uint256(price) / 10 ** (decimals - 18);
    }
    return uint256(price);
}
```

### Oracle Failure Modes

Understanding how oracles fail is critical:

**1. Stale Data:**
- Oracle stops updating
- Network congestion delays updates
- **Mitigation:** Check `updatedAt` timestamp

**2. Invalid Data:**
- Price is 0 or negative
- Price is unrealistically high/low
- **Mitigation:** Sanity checks and bounds

**3. Flash Crashes:**
- Temporary extreme price movements
- **Mitigation:** TWAP, price deviation limits

**4. Oracle Compromise:**
- Malicious oracle operators
- Smart contract bugs in oracle
- **Mitigation:** Multi-oracle setup, circuit breakers

**5. Network Issues:**
- L2 sequencer downtime
- Cross-chain bridge failures
- **Mitigation:** Sequencer uptime feeds, grace periods

**Circuit Breaker Pattern:**
```solidity
bool public oracleEmergencyShutdown;
uint256 public lastValidPrice;
uint256 public lastValidTimestamp;

function getPrice() public view returns (uint256) {
    if (oracleEmergencyShutdown) {
        // Use last known good price in emergency
        require(
            block.timestamp - lastValidTimestamp < EMERGENCY_PERIOD,
            "Emergency period expired"
        );
        return lastValidPrice;
    }

    (uint256 price, bool valid) = _getOraclePrice();
    if (!valid) {
        // Could trigger emergency shutdown
        return lastValidPrice;
    }

    return price;
}
```

## Project Structure

```
47-vault-oracle/
├── README.md
├── src/
│   ├── Project47.sol           # Skeleton implementation
│   └── solution/
│       └── Project47Solution.sol   # Complete solution
├── test/
│   └── Project47.t.sol         # Comprehensive tests
└── script/
    └── DeployProject47.s.sol   # Deployment script
```

## Objectives

1. **Implement Oracle-Integrated Vault** ✓
   - Store deposits with oracle-based valuation
   - Calculate share prices using oracle data
   - Handle multiple assets

2. **Build TWAP Oracle** ✓
   - Store price observations
   - Calculate time-weighted averages
   - Handle edge cases (first observation, etc.)

3. **Add Safety Mechanisms** ✓
   - Staleness checks
   - Price deviation limits
   - Circuit breakers
   - Multi-oracle fallback

4. **Integrate Chainlink** ✓
   - Use AggregatorV3Interface
   - Handle decimals correctly
   - Validate round data

5. **Test Oracle Scenarios** ✓
   - Normal operation
   - Stale data rejection
   - Price manipulation attempts
   - Oracle failure modes

## Key Contracts

### Project47.sol (Skeleton)

Basic structure with TODOs for implementing:
- Oracle price validation
- TWAP calculations
- Safety checks
- Vault operations using oracle data

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/VaultOracleSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployVaultOracleSolution.s.sol` - Deployment script patterns
- `test/solution/VaultOracleSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains TWAP (Time-Weighted Average Price), circular buffers, multi-oracle consensus
- **Connections to Project 18**: Chainlink oracle integration (this extends it)
- **Connections to Project 11**: ERC-4626 vaults with oracle-based pricing
- **Real-World Context**: TWAP prevents oracle manipulation - used in production DeFi protocols

### Project47Solution.sol (Complete)

Full implementation featuring:
- Multi-oracle vault system
- TWAP oracle with circular buffer
- Chainlink integration
- Circuit breaker mechanisms
- Comprehensive validation
- Detailed security comments

## Testing Scenarios

1. **Oracle Updates:**
   - Price updates accumulate correctly
   - TWAP calculations are accurate
   - Observations stored properly

2. **Staleness Detection:**
   - Reject old data
   - Fallback to secondary oracle
   - Emergency mode activation

3. **Price Validation:**
   - Deviation limits enforced
   - Invalid prices rejected
   - Circuit breaker triggers

4. **Vault Operations:**
   - Deposits value correctly
   - Withdrawals use safe prices
   - Share calculations accurate

5. **Failure Recovery:**
   - Graceful degradation
   - Emergency withdrawals
   - Oracle recovery

## Security Considerations

### Critical Checks

1. **Always Validate Oracle Data:**
   ```solidity
   require(updatedAt > block.timestamp - MAX_STALENESS, "Stale");
   require(answer > 0, "Invalid price");
   require(answeredInRound >= roundId, "Incomplete");
   ```

2. **Use TWAP for Critical Operations:**
   - Liquidations
   - Large swaps
   - Vault valuations

3. **Implement Circuit Breakers:**
   - Pause on oracle failure
   - Admin recovery mechanisms
   - User protection during anomalies

4. **Never Trust Single Oracle:**
   - Use multiple sources when possible
   - Compare prices for consistency
   - Have fallback mechanisms

5. **Handle Decimal Conversions:**
   - Different oracles use different decimals
   - Always normalize to consistent format
   - Test edge cases (very large/small numbers)

### Common Vulnerabilities

❌ **No Staleness Check:**
```solidity
// Vulnerable
function getPrice() external view returns (uint256) {
    (, int256 answer,,,) = priceFeed.latestRoundData();
    return uint256(answer);
}
```

❌ **No Deviation Protection:**
```solidity
// Vulnerable
function withdraw(uint256 shares) external {
    uint256 price = oracle.getPrice(); // Could be manipulated
    uint256 amount = shares * price / 1e18;
    token.transfer(msg.sender, amount);
}
```

❌ **Single Oracle Dependency:**
```solidity
// Risky
function liquidate(address user) external {
    uint256 price = oracle.getPrice(); // What if oracle fails?
    // ... liquidation logic
}
```

✅ **Proper Implementation:**
```solidity
function getValidatedPrice() public view returns (uint256) {
    // Try primary oracle
    (uint256 price1, bool valid1) = _getChainlinkPrice();
    if (valid1) {
        // Verify against TWAP
        uint256 twapPrice = getTWAP(30 minutes);
        require(
            _isWithinDeviation(price1, twapPrice),
            "Price deviation too high"
        );
        return price1;
    }

    // Fallback to TWAP only
    return getTWAP(1 hours);
}
```

## Gas Optimization Tips

1. **Cache Oracle Reads:**
   ```solidity
   // Instead of multiple calls
   uint256 price = _getPrice();
   uint256 value1 = amount1 * price;
   uint256 value2 = amount2 * price;
   ```

2. **Batch Observations:**
   ```solidity
   // Update multiple observations in one transaction
   function updatePrices(uint256[] calldata prices) external {
       for (uint i = 0; i < prices.length; i++) {
           _recordObservation(prices[i]);
       }
   }
   ```

3. **Use Ring Buffer for TWAP:**
   ```solidity
   // Fixed-size array, O(1) updates
   Observation[100] public observations;
   uint256 public observationIndex;
   ```

## Best Practices

1. **Document Oracle Assumptions:**
   - Expected update frequency
   - Accepted staleness threshold
   - Decimal format
   - Trust assumptions

2. **Monitoring and Alerts:**
   - Track oracle uptime
   - Monitor price deviations
   - Alert on circuit breaker activation

3. **Graceful Degradation:**
   - Continue critical functions with cached prices
   - Disable non-critical features
   - Allow emergency withdrawals

4. **Testing:**
   - Test all failure modes
   - Fuzz test price inputs
   - Simulate oracle downtime
   - Test decimal edge cases

5. **Upgradeability:**
   - Allow oracle address updates
   - Update staleness thresholds
   - Modify deviation limits

## Learning Objectives

By completing this project, you will:

- ✅ Understand oracle security fundamentals
- ✅ Implement TWAP price feeds
- ✅ Integrate Chainlink oracles safely
- ✅ Handle oracle failure modes
- ✅ Build circuit breaker mechanisms
- ✅ Validate price data properly
- ✅ Implement multi-oracle strategies
- ✅ Test oracle edge cases

## Real-World Applications

- **Lending Protocols:** Safe collateral valuation
- **DEXs:** Fair swap pricing
- **Derivatives:** Accurate index prices
- **Vaults:** Correct share valuations
- **Stablecoins:** Peg maintenance
- **Options:** Strike price determination

## Further Reading

- [Chainlink Documentation](https://docs.chain.link/)
- [Oracle Manipulation Attacks](https://blog.chain.link/oracle-manipulation-attacks/)
- [Uniswap V3 TWAP Oracles](https://docs.uniswap.org/concepts/protocol/oracle)
- [MakerDAO Oracle Security](https://docs.makerdao.com/smart-contract-modules/oracle-module)
- [Compound Price Feeds](https://docs.compound.finance/v2/prices/)

## Running the Project

```bash
# Install dependencies
forge install

# Run tests
forge test --match-path test/Project47.t.sol -vvv

# Run specific test
forge test --match-test testOracleStaleness -vvv

# Deploy
forge script script/DeployProject47.s.sol --rpc-url <RPC_URL> --broadcast

# Check coverage
forge coverage --match-path test/Project47.t.sol
```

## Challenge Tasks

1. **Add L2 Sequencer Check:**
   - Integrate Chainlink sequencer uptime feed
   - Prevent operations during sequencer downtime
   - Add grace period after restart

2. **Implement Multi-Asset Vault:**
   - Support multiple tokens
   - Each with different oracles
   - Aggregate total value correctly

3. **Build Oracle Aggregator:**
   - Combine multiple oracle sources
   - Median, average, or weighted strategies
   - Outlier detection and removal

4. **Add Historical Price Access:**
   - Query prices at specific timestamps
   - Support flash loan attack detection
   - Implement price range queries

5. **Create Oracle Governance:**
   - Vote to update oracle addresses
   - Timelock for critical changes
   - Emergency pause mechanism

## Common Pitfalls

1. **Not Checking All Round Data Fields**
   - Check `answeredInRound >= roundId`
   - Verify `updatedAt` is recent
   - Ensure `answer > 0`

2. **Decimal Mismatches**
   - Chainlink uses 8 decimals for USD
   - Tokens can have 6, 8, 18 decimals
   - Always normalize

3. **Ignoring Price Bounds**
   - Set min/max reasonable prices
   - Prevent overflow/underflow
   - Sanity check calculations

4. **No Fallback Mechanism**
   - Single point of failure
   - No degraded mode
   - System halt on oracle failure

5. **Insufficient TWAP Period**
   - Too short: Still manipulatable
   - Too long: Lags market
   - Balance based on use case

## Summary

Oracle integration is one of the most critical and risky aspects of DeFi protocols. This project teaches you how to safely integrate price feeds into vaults, protecting against the most common attack vectors and failure modes.

**Key Takeaways:**
- Always validate oracle data (staleness, sanity checks)
- Use TWAP for critical operations
- Implement circuit breakers for failures
- Never rely on a single oracle
- Test all failure scenarios
- Handle decimals carefully

Master these concepts to build secure, reliable DeFi protocols! 🔐
