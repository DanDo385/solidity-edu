# Project 34: Oracle Manipulation Attack

Learn how oracle manipulation attacks work and how to prevent them in DeFi protocols.

## Overview

Oracle manipulation is one of the most profitable attack vectors in DeFi. Attackers exploit the way protocols determine asset prices, often combining flashloans with price oracle vulnerabilities to drain millions of dollars.

## Vulnerability Explained: Oracle Manipulation Attacks

**FIRST PRINCIPLES: Trust in External Data**

Oracle manipulation is one of the most profitable attack vectors in DeFi. Understanding how oracles work and how they can be manipulated is critical!

**CONNECTION TO PROJECT 18**:
- **Project 18**: We learned about Chainlink oracles (secure, decentralized)
- **Project 34**: We learn about vulnerable oracles (manipulable, single-source)
- Both teach oracle security - one shows secure patterns, one shows vulnerabilities!

### What is an Oracle?

An oracle is a mechanism that provides external data (like asset prices) to smart contracts. DeFi protocols rely on oracles to:
- Determine collateral values in lending protocols
- Calculate swap rates in DEXes
- Trigger liquidations
- Value synthetic assets

**CONNECTION TO PROJECT 11**:
ERC-4626 vaults need price data to calculate share values! Vulnerable oracles can manipulate vault pricing!

### Oracle Manipulation Mechanics

**THE ATTACK PATTERN**:

```
Oracle Manipulation Attack Flow:
┌─────────────────────────────────────────┐
│ Step 1: Setup                           │
│   Identify protocol with weak oracle    │ ← Research phase
│   ↓                                      │
│ Step 2: Flashloan                       │
│   Borrow massive amount (no collateral) │ ← Unlimited capital
│   ↓                                      │
│ Step 3: Manipulate                      │
│   Execute large trades to skew price    │ ← Price manipulation
│   ↓                                      │
│ Step 4: Exploit                         │
│   Use manipulated price to extract value│ ← Profit extraction
│   ↓                                      │
│ Step 5: Repay                           │
│   Return flashloan, keep profits         │ ← Risk-free profit
└─────────────────────────────────────────┘
```

**WHY IT WORKS**:

1. **Spot Price Oracles**: Can be manipulated within a single transaction
   - Read price from AMM reserves
   - Large swap changes reserves
   - Oracle reads manipulated price
   - All in one transaction!

2. **Flashloans**: Provide unlimited capital for manipulation
   - No collateral needed
   - Borrow millions, manipulate, repay
   - From Project 02: Flashloans enable atomic operations!

3. **Atomic Transactions**: Ensure risk-free execution
   - All steps in one transaction
   - Either all succeed or all revert
   - No risk of partial execution

4. **Missing Protections**: Many protocols don't implement proper oracle protections
   - No TWAP (Time-Weighted Average Price)
   - No price bounds checking
   - No multiple oracle sources

**REAL-WORLD ANALOGY**: 
Like manipulating a stock price by buying/selling large amounts quickly, then using that manipulated price to execute profitable trades. Flashloans make this possible without capital!

### Types of Vulnerable Oracles

#### 1. AMM Spot Price Oracles

**Vulnerable Pattern:**
```solidity
function getPrice() public view returns (uint256) {
    return (reserveB * 1e18) / reserveA;  // ❌ Instant manipulation
}
```

**Attack:**
- Execute a massive swap in the AMM
- Oracle reads manipulated reserves
- Protocol uses incorrect price
- Attacker profits from mispricing

#### 2. Single Source Oracles

**Vulnerability:**
- Relying on only one price source (single point of failure)
- No redundancy or validation
- Easy to manipulate or compromise

#### 3. Non-Updated Oracles

**Vulnerability:**
- Stale price data
- Outdated information from infrequent updates
- Exploitable during high volatility

## Attack Vectors

### 1. AMM Price Manipulation with Flashloans

**Classic Attack Flow:**

```
1. Flashloan 10,000 ETH
2. Swap 10,000 ETH → TokenA (price spikes)
3. Oracle reads inflated TokenA price
4. Borrow maximum tokens using overvalued TokenA collateral
5. Swap back TokenA → ETH (price normalizes)
6. Repay flashloan
7. Keep borrowed tokens as profit
```

**Real Example - Harvest Finance (2020):**
- $34 million stolen
- Attacker manipulated USDC/USDT price on Curve
- Used flashloans to create massive imbalance
- Exploited arbitrage between pools

### 2. Lending Protocol Manipulation

**Attack Pattern:**
```solidity
// Vulnerable lending protocol
function borrow(address token, uint256 amount) external {
    uint256 collateralValue = oracle.getPrice(collateralToken) * collateralAmount;
    uint256 borrowValue = oracle.getPrice(token) * amount;
    require(collateralValue >= borrowValue * 150 / 100, "Insufficient collateral");
    // ❌ Uses manipulated oracle price
}
```

**Exploit:**
1. Manipulate collateral token price upward
2. Deposit minimal collateral (now appears valuable)
3. Borrow maximum tokens
4. Restore price and profit

### 3. Compound/Aave Oracle Attacks

**Historical Vulnerabilities:**

**Compound:**
- Initially used Uniswap V2 TWAP
- Vulnerable to multi-block manipulation
- Switched to Chainlink oracles

**Cream Finance (2021):**
- $130 million stolen
- Manipulated priceOracle for yUSD
- Used flashloans to inflate collateral value
- Borrowed and drained protocol

**Aave:**
- More resilient with Chainlink integration
- Multiple oracle sources
- Fallback mechanisms

## Spot Price vs TWAP

### Spot Price (Vulnerable)

```solidity
// ❌ Single block manipulation
function getSpotPrice() public view returns (uint256) {
    return (reserveToken1 * PRECISION) / reserveToken0;
}
```

**Vulnerability:**
- Can be manipulated within one transaction
- No historical context
- Perfect for flashloan attacks

### TWAP (Time-Weighted Average Price)

```solidity
// ✅ More resistant to manipulation
function getTWAP(uint256 period) public view returns (uint256) {
    uint256 currentPrice = getCurrentPrice();
    uint256 currentTime = block.timestamp;

    // Update cumulative price
    if (currentTime > lastUpdateTime) {
        priceCumulative += currentPrice * (currentTime - lastUpdateTime);
        lastUpdateTime = currentTime;
    }

    // Calculate TWAP over period
    return (priceCumulative - priceCumulativeStart) / period;
}
```

**Benefits:**
- Averages price over time
- Requires sustained manipulation (expensive)
- Cannot be manipulated in single transaction

**Limitations:**
- Still vulnerable to multi-block attacks
- Lag in price updates during volatility
- Can be gamed with enough capital and time

## Mitigation Strategies

### 1. Use Chainlink Price Feeds

```solidity
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract SafeOracle {
    AggregatorV3Interface internal priceFeed;

    function getPrice() public view returns (uint256) {
        (, int256 price,,,) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price");
        return uint256(price);
    }
}
```

**Benefits:**
- Decentralized oracle network
- Multiple data sources
- Cryptographic guarantees
- Industry standard

### 2. Multiple Oracle Sources

```solidity
contract MultiOracle {
    function getPrice() public view returns (uint256) {
        uint256 chainlinkPrice = chainlinkOracle.getPrice();
        uint256 uniswapTWAP = uniswapOracle.getTWAP(3600);
        uint256 bandPrice = bandOracle.getPrice();

        // Use median of three sources
        return median(chainlinkPrice, uniswapTWAP, bandPrice);
    }
}
```

### 3. TWAP Implementation

```solidity
contract TWAPOracle {
    uint256 public constant PERIOD = 1 hours;
    uint256 public priceCumulativeLast;
    uint32 public blockTimestampLast;

    function update() external {
        (uint256 price0Cumulative,, uint32 blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(pair);

        uint32 timeElapsed = blockTimestamp - blockTimestampLast;

        if (timeElapsed >= PERIOD) {
            // Calculate TWAP
            twap = (price0Cumulative - priceCumulativeLast) / timeElapsed;
            priceCumulativeLast = price0Cumulative;
            blockTimestampLast = blockTimestamp;
        }
    }
}
```

### 4. Price Deviation Checks

```solidity
function checkPriceDeviation(uint256 newPrice) internal view {
    uint256 oldPrice = lastPrice;
    uint256 deviation = newPrice > oldPrice
        ? ((newPrice - oldPrice) * 100) / oldPrice
        : ((oldPrice - newPrice) * 100) / oldPrice;

    require(deviation < MAX_DEVIATION, "Price change too large");
}
```

### 5. Commit-Reveal Schemes

```solidity
// Prevent single-transaction attacks
mapping(address => uint256) public commitBlock;

function commitAction() external {
    commitBlock[msg.sender] = block.number;
}

function executeAction() external {
    require(block.number > commitBlock[msg.sender] + 1, "Must wait");
    // Execute with oracle price
}
```

## Real-World Exploits

### 1. Harvest Finance (October 2020)
- **Loss:** $34 million
- **Method:** Curve pool price manipulation
- **Attack:** Flashloaned USDC/USDT to create imbalance
- **Lesson:** Use TWAP, not spot prices

### 2. Cream Finance (October 2021)
- **Loss:** $130 million
- **Method:** yUSD price oracle manipulation
- **Attack:** Flashloan + donate to vault to inflate share price
- **Lesson:** Validate oracle inputs, use multiple sources

### 3. Mango Markets (October 2022)
- **Loss:** $110 million
- **Method:** Perpetual futures price manipulation
- **Attack:** Inflated MNGO price with low liquidity
- **Lesson:** Ensure oracle liquidity requirements

### 4. Indexed Finance (October 2021)
- **Loss:** $16 million
- **Method:** Low liquidity pool manipulation
- **Attack:** Manipulated DEFI5 index token price
- **Lesson:** Oracle must account for liquidity depth

### 5. Warp Finance (December 2020)
- **Loss:** $8 million
- **Method:** Uniswap LP token price manipulation
- **Attack:** Flashloan to manipulate LP token value
- **Lesson:** LP tokens need special oracle considerations

## Best Practices

### For Protocol Developers

1. **Never use spot prices alone**
   - Always implement TWAP or use Chainlink
   - Minimum 30-minute window for TWAP

2. **Multiple oracle sources**
   - Use at least 2-3 independent oracles
   - Implement circuit breakers for discrepancies

3. **Validate oracle data**
   - Check for stale data
   - Verify price bounds
   - Monitor for extreme deviations

4. **Liquidity requirements**
   - Ensure sufficient liquidity in price sources
   - Set minimum liquidity thresholds

5. **Time delays**
   - Implement cooldown periods
   - Prevent single-block exploits

### For Auditors

1. **Identify all oracle dependencies**
2. **Verify TWAP implementation**
3. **Check for single-transaction vulnerabilities**
4. **Test with flashloan scenarios**
5. **Review fallback mechanisms**

## Learning Objectives

By completing this project, you will:

1. ✅ Understand how oracle manipulation works
2. ✅ Implement a flashloan-based price manipulation attack
3. ✅ Recognize vulnerable oracle patterns
4. ✅ Build TWAP protection mechanisms
5. ✅ Implement multi-oracle systems
6. ✅ Learn defense strategies

## Setup

```bash
# Install dependencies
forge install

# Run tests
forge test

# Run specific test
forge test --match-test testOracleManipulation -vvv

# Deploy
forge script script/DeployProject34.s.sol --rpc-url <RPC_URL> --broadcast
```

## Exercises

### Part 1: Understanding the Vulnerability

1. Study the vulnerable lending protocol in `Project34.sol`
2. Identify the oracle vulnerability
3. Trace how a flashloan could manipulate prices

### Part 2: Exploit Development

1. Complete the `Attacker` contract
2. Implement the attack sequence:
   - Get flashloan
   - Manipulate AMM price
   - Exploit lending protocol
   - Restore price
   - Profit

### Part 3: Testing

1. Run tests to verify the attack works
2. Measure profit from manipulation
3. Test TWAP protection effectiveness

### Part 4: Build Defenses

1. Implement TWAP oracle
2. Add multiple oracle sources
3. Create price deviation checks
4. Test protection mechanisms

## Key Takeaways

1. **Spot prices are dangerous** - Never use them directly for critical operations
2. **Flashloans amplify risk** - Consider flashloan attack vectors in all protocols
3. **TWAP isn't perfect** - It's more resistant but still exploitable
4. **Chainlink is gold standard** - Decentralized, battle-tested, reliable
5. **Defense in depth** - Use multiple protections (TWAP + Chainlink + checks)
6. **Liquidity matters** - Low liquidity makes manipulation cheaper
7. **Time is a defense** - Multi-block requirements prevent atomic attacks

## Resources

- [Chainlink Price Feeds](https://docs.chain.link/data-feeds/price-feeds)
- [Uniswap V2 TWAP Oracle](https://docs.uniswap.org/contracts/v2/guides/smart-contract-integration/building-an-oracle)
- [Euler Finance: Oracle Rating Framework](https://docs.euler.finance/getting-started/methodology/oracle-rating)
- [Openzeppelin Governor Bravo](https://docs.openzeppelin.com/contracts/4.x/api/governance)
- [Rekt News - Oracle Manipulation Incidents](https://rekt.news/)

## Advanced Topics

- MEV and oracle manipulation synergies
- Cross-chain oracle attacks
- Governance token price manipulation
- LP token oracle vulnerabilities
- Synthetic asset oracle risks

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/OracleManipulationSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployOracleManipulationSolution.s.sol` - Deployment script patterns
- `test/solution/OracleManipulationSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains oracle manipulation attacks, flashloan synergies, price manipulation
- **Connections to Project 18**: Chainlink oracles (this shows vulnerable patterns to avoid)
- **Connections to Project 11**: ERC-4626 vaults (vulnerable oracles can manipulate vault pricing)
- **Real-World Context**: Oracle manipulation has drained millions - understanding attacks is critical for defense

---

**⚠️ Educational Purpose Only**

This project is for learning security concepts. Never use these techniques on mainnet or against real protocols without authorization. Oracle manipulation is illegal and unethical.
