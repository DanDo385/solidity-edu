# Quick Reference - Project 47: Vault Oracle Integration

## Key Concepts at a Glance

### Oracle Safety Checklist

```solidity
// ✅ Always check these when using Chainlink:
1. updatedAt timestamp (staleness)
2. answer > 0 (validity)
3. answeredInRound >= roundId (completion)
4. Normalize decimals
5. Apply bounds checking
```

### TWAP Formula

```
TWAP = (cumulativePrice[now] - cumulativePrice[now - period]) / timeDelta
```

### Price Deviation Formula

```
deviation = |newPrice - oldPrice| / oldPrice * 10000  // In basis points
```

## Essential Functions

### Oracle Functions

```solidity
// Get Chainlink price with validation
function getChainlinkPrice() public view returns (uint256 price, bool isValid)

// Get validated price with fallback
function getValidatedPrice() public view returns (uint256)

// Check if data is stale
function _isStale(uint256 updatedAt) internal view returns (bool)

// Normalize to 18 decimals
function _normalizeDecimals(int256 price) internal view returns (uint256)
```

### TWAP Functions

```solidity
// Record price observation
function updateObservation(uint256 price) public onlyOwner

// Calculate TWAP over period
function getTWAP(uint256 period) public view returns (uint256)

// Find observation at timestamp
function _getObservationAt(uint256 targetTime) internal view returns (Observation memory)
```

### Vault Functions

```solidity
// Deposit assets, get shares
function deposit(uint256 assets) external returns (uint256 shares)

// Burn shares, get assets
function withdraw(uint256 shares) external returns (uint256 assets)

// Preview operations
function previewDeposit(uint256 assets) external view returns (uint256 shares)
function previewWithdraw(uint256 shares) external view returns (uint256 assets)
```

## Common Patterns

### Chainlink Integration Pattern

```solidity
function getChainlinkPrice() public view returns (uint256, bool) {
    try priceFeed.latestRoundData() returns (
        uint80 roundId,
        int256 answer,
        uint256,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        // 1. Check staleness
        if (block.timestamp - updatedAt > maxStaleness) return (0, false);

        // 2. Check validity
        if (answer <= 0) return (0, false);

        // 3. Check completion
        if (answeredInRound < roundId) return (0, false);

        // 4. Normalize decimals
        uint256 normalized = _normalizeDecimals(answer);

        // 5. Check bounds
        if (normalized < minPrice || normalized > maxPrice) return (0, false);

        return (normalized, true);
    } catch {
        return (0, false);
    }
}
```

### TWAP Recording Pattern

```solidity
function _recordObservation(uint256 price) internal {
    Observation memory last = observations[observationIndex];

    // Calculate cumulative: previous + (price * timeDelta)
    uint256 timeDelta = block.timestamp - last.timestamp;
    uint256 cumulative = last.cumulativePrice + (price * timeDelta);

    // Store new observation
    Observation memory newObs = Observation({
        timestamp: block.timestamp,
        price: price,
        cumulativePrice: cumulative
    });

    // Ring buffer logic
    if (observations.length < MAX_OBSERVATIONS) {
        observations.push(newObs);
        observationIndex = observations.length - 1;
    } else {
        observationIndex = (observationIndex + 1) % MAX_OBSERVATIONS;
        observations[observationIndex] = newObs;
    }
}
```

### Fallback Oracle Pattern

```solidity
function getValidatedPrice() public view returns (uint256) {
    // 1. Try primary oracle
    (uint256 price, bool valid) = getChainlinkPrice();
    if (valid && _isDeviationAcceptable(price, lastValidPrice)) {
        return price;
    }

    // 2. Try fallback
    if (address(fallbackOracle) != address(0)) {
        try fallbackOracle.getPrice() returns (uint256 fbPrice) {
            if (fbPrice >= minPrice && fbPrice <= maxPrice) {
                return fbPrice;
            }
        } catch {}
    }

    // 3. Use last valid price (with time limit)
    require(block.timestamp - lastPriceUpdate <= maxStaleness * 2, "All oracles failed");
    return lastValidPrice;
}
```

## Test Patterns

### Testing Oracle Staleness

```solidity
function testStaleDataRejection() public {
    chainlinkFeed.setStale(2 hours);
    (uint256 price, bool isValid) = vault.getChainlinkPrice();
    assertFalse(isValid);
}
```

### Testing TWAP

```solidity
function testTWAP() public {
    vault.updateObservation(2000 * 1e18);
    vm.warp(block.timestamp + 1 hours);
    vault.updateObservation(2200 * 1e18);

    uint256 twap = vault.getTWAP(1 hours);
    assertTrue(twap > 2000 * 1e18 && twap < 2200 * 1e18);
}
```

### Testing Deviation Limits

```solidity
function testPriceDeviationLimit() public {
    vault.updateObservation(2000 * 1e18);

    // 20% change should trigger fallback (with 10% limit)
    chainlinkFeed.updatePrice(2400 * 1e8);

    uint256 price = vault.getValidatedPrice();
    // Should use fallback or last valid price
}
```

## State Variables Reference

```solidity
// Oracle configuration
AggregatorV3Interface public priceFeed;        // Chainlink feed
IPriceOracle public fallbackOracle;            // Backup oracle
uint256 public maxStaleness;                   // Max age (e.g., 1 hour)
uint256 public maxPriceDeviation;              // Max change (e.g., 1000 = 10%)
uint256 public minPrice;                       // Lower bound
uint256 public maxPrice;                       // Upper bound

// Price tracking
uint256 public lastValidPrice;                 // Last known good price
uint256 public lastPriceUpdate;                // When last updated
bool public emergencyShutdown;                 // Circuit breaker

// TWAP
Observation[] public observations;              // Price history
uint256 public observationIndex;               // Current position
uint256 public constant MAX_OBSERVATIONS = 24; // Buffer size
```

## Error Reference

```solidity
error StalePrice(uint256 age);
error InvalidPrice(int256 price);
error PriceDeviationTooHigh(uint256 deviation);
error EmergencyShutdownActive();
error ZeroAmount();
error InsufficientShares(uint256 requested, uint256 balance);
error PriceOutOfBounds(uint256 price, uint256 min, uint256 max);
error NoObservationsAvailable();
error InsufficientObservationPeriod(uint256 available, uint256 requested);
```

## Gas Optimization Tips

```solidity
// ❌ Bad: Multiple oracle reads
uint256 price1 = oracle.getPrice();
uint256 value1 = amount1 * oracle.getPrice();

// ✅ Good: Cache oracle read
uint256 price = oracle.getPrice();
uint256 value1 = amount1 * price;
uint256 value2 = amount2 * price;
```

```solidity
// ✅ Use ring buffer (fixed size)
Observation[24] public observations;  // Better for gas
// vs
Observation[] public observations;    // Unbounded growth
```

## Security Checklist

- [ ] Check oracle data staleness
- [ ] Validate price > 0
- [ ] Verify round completion
- [ ] Normalize decimals
- [ ] Apply price bounds
- [ ] Check deviation limits
- [ ] Implement fallback mechanism
- [ ] Add circuit breaker
- [ ] Use TWAP for withdrawals
- [ ] Handle oracle failures gracefully

## Useful Commands

```bash
# Build
forge build

# Test everything
forge test -vvv

# Test specific function
forge test --match-test testGetChainlinkPrice -vvv

# Gas report
forge test --gas-report

# Coverage
forge coverage

# Deploy with mocks
forge script script/DeployProject47.s.sol:DeployWithMocks

# Format code
forge fmt

# Check for issues
forge build --force
```

## Chainlink Price Feeds (Examples)

### Mainnet
- ETH/USD: `0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419`
- BTC/USD: `0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c`
- USDC/USD: `0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6`

### Sepolia Testnet
- ETH/USD: `0x694AA1769357215DE4FAC081bf1f309aDC325306`

## Common Mistakes to Avoid

1. **Not checking staleness** → Use stale data
2. **Ignoring decimals** → Wrong price calculations
3. **No deviation limits** → Accept manipulated prices
4. **Single oracle** → No redundancy
5. **No circuit breaker** → System halts on failure
6. **Trusting spot price** → Use TWAP for critical ops
7. **No bounds checking** → Accept invalid prices
8. **Incomplete round check** → Use partial data

## Implementation Order

1. ✅ `_isStale()` - Simple timestamp check
2. ✅ `_normalizeDecimals()` - Decimal conversion
3. ✅ `getChainlinkPrice()` - Chainlink integration
4. ✅ `_isDeviationAcceptable()` - Deviation check
5. ✅ `_recordObservation()` - TWAP recording
6. ✅ `getTWAP()` - TWAP calculation
7. ✅ `getValidatedPrice()` - Full validation + fallback
8. ✅ `deposit()` - Vault deposit
9. ✅ `withdraw()` - Vault withdrawal
10. ✅ `emergencyWithdraw()` - Safety exit

## Links

- [Chainlink Docs](https://docs.chain.link/)
- [Oracle Security](https://blog.chain.link/oracle-manipulation-attacks/)
- [Foundry Book](https://book.getfoundry.sh/)
- [OpenZeppelin](https://docs.openzeppelin.com/)

---

**Remember**: Oracle security is critical. Always validate, always have fallbacks, always test edge cases! 🔐
