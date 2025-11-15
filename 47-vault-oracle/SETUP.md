# Project 47 Setup Guide

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Basic understanding of Solidity and oracles
- Familiarity with Chainlink price feeds

## Installation

### 1. Install Dependencies

```bash
# Install Foundry dependencies
forge install OpenZeppelin/openzeppelin-contracts
forge install smartcontractkit/chainlink
forge install foundry-rs/forge-std
```

### 2. Build the Project

```bash
forge build
```

### 3. Run Tests

```bash
# Run all tests
forge test

# Run with verbosity to see details
forge test -vvv

# Run specific test
forge test --match-test testGetChainlinkPrice -vvv

# Run with gas reporting
forge test --gas-report
```

### 4. Test Coverage

```bash
# Generate coverage report
forge coverage

# Generate detailed coverage report
forge coverage --report lcov
```

## Learning Path

### Step 1: Understand Oracle Basics

1. Read the README.md for comprehensive oracle concepts
2. Study the Chainlink integration patterns
3. Understand TWAP mechanics

### Step 2: Work on Skeleton Implementation

1. Open `src/Project47.sol`
2. Read all the TODOs
3. Implement functions one by one:
   - Start with `getChainlinkPrice()`
   - Then `_isStale()` and `_normalizeDecimals()`
   - Move to TWAP functions
   - Finally implement vault functions

### Step 3: Run Tests as You Go

```bash
# Test individual functions
forge test --match-test testGetChainlinkPrice -vvv
forge test --match-test testTWAPCalculation -vvv
forge test --match-test testDeposit -vvv
```

### Step 4: Compare with Solution

1. After implementing, compare with `src/solution/Project47Solution.sol`
2. Note the security checks and comments
3. Understand the design decisions

### Step 5: Run Full Test Suite

```bash
# Ensure all tests pass
forge test

# Check for edge cases
forge test --match-contract Project47Test -vvv
```

## Common Issues

### Issue: Dependencies not found

**Solution:**
```bash
forge install OpenZeppelin/openzeppelin-contracts
forge install smartcontractkit/chainlink
forge install foundry-rs/forge-std
forge remappings > remappings.txt
```

### Issue: Compilation errors

**Solution:**
- Ensure you're using Solidity ^0.8.20
- Check that all imports are correct
- Run `forge clean && forge build`

### Issue: Tests failing

**Solution:**
- Make sure all TODOs are implemented
- Check return types match expected values
- Verify oracle mock behavior
- Read error messages carefully

## Deployment

### Local Testing with Mocks

```bash
# Deploy with mock contracts
forge script script/DeployProject47.s.sol:DeployWithMocks --fork-url http://localhost:8545 --broadcast
```

### Testnet Deployment (Sepolia)

1. Create a `.env` file:
```bash
SEPOLIA_RPC_URL=your_rpc_url
PRIVATE_KEY=your_private_key
ETHERSCAN_API_KEY=your_etherscan_key
```

2. Deploy:
```bash
source .env
forge script script/DeployProject47.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
```

### Mainnet Deployment

⚠️ **WARNING: Audit your code before mainnet deployment!**

```bash
source .env
forge script script/DeployProject47.s.sol --rpc-url $MAINNET_RPC_URL --broadcast --verify
```

## Useful Commands

```bash
# Format code
forge fmt

# Check for compilation warnings
forge build --force

# Analyze gas usage
forge test --gas-report

# Generate documentation
forge doc

# Run specific test file
forge test --match-path test/Project47.t.sol

# Run fuzz tests with more runs
forge test --fuzz-runs 10000
```

## Debugging Tips

### 1. Use Verbosity Levels

```bash
# -v: Show test results
# -vv: Show test results + logs
# -vvv: Show test results + logs + stack traces
# -vvvv: Show test results + logs + stack traces + storage
forge test -vvvv
```

### 2. Use Console Logging

Add to your contract:
```solidity
import "forge-std/console.sol";

function myFunction() public {
    console.log("Value:", someValue);
}
```

### 3. Use Debugger

```bash
forge test --debug testFunctionName
```

### 4. Check Oracle Status

In tests or scripts, use:
```solidity
(
    uint256 chainlinkPrice,
    bool chainlinkValid,
    uint256 twapPrice,
    uint256 lastPrice,
    uint256 observationCount
) = vault.getOracleStatus();

console.log("Chainlink Price:", chainlinkPrice);
console.log("Is Valid:", chainlinkValid);
console.log("TWAP Price:", twapPrice);
```

## Learning Resources

### Chainlink
- [Chainlink Data Feeds](https://docs.chain.link/data-feeds)
- [Using Price Feeds](https://docs.chain.link/data-feeds/using-data-feeds)
- [Historical Price Data](https://docs.chain.link/data-feeds/historical-data)

### TWAP
- [Uniswap V3 TWAP](https://docs.uniswap.org/concepts/protocol/oracle)
- [Time-Weighted Average Price Explained](https://www.investopedia.com/terms/t/time-weighted-average-price.asp)

### Oracle Security
- [Oracle Manipulation Attacks](https://blog.chain.link/oracle-manipulation-attacks/)
- [DeFi Security Best Practices](https://blog.chain.link/defi-security-best-practices/)

## Next Steps

After completing this project:

1. **Extend the Implementation:**
   - Add L2 sequencer uptime check
   - Implement multi-asset support
   - Build oracle aggregator

2. **Security Enhancements:**
   - Add more circuit breakers
   - Implement timelocks
   - Add governance for parameter updates

3. **Advanced Features:**
   - Flash loan protection
   - Oracle governance
   - Historical price queries

4. **Testing:**
   - Add more fuzz tests
   - Invariant testing
   - Integration tests with real protocols

## Support

If you encounter issues:

1. Check the README.md for concept explanations
2. Review the solution implementation
3. Read test cases for usage examples
4. Check Foundry documentation
5. Review Chainlink documentation

## Contributing

Feel free to:
- Add more test cases
- Improve documentation
- Add new oracle sources
- Enhance security features

Happy learning! 🚀
