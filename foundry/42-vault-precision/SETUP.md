# Project 42 Setup Instructions

## Prerequisites

This project uses Foundry for Solidity development. You'll need to install it first.

## Installing Foundry

### Linux/macOS
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Windows
Download from: https://github.com/foundry-rs/foundry/releases

Or use WSL (Windows Subsystem for Linux) and follow Linux instructions.

## Project Setup

1. **Navigate to project directory**
   ```bash
   cd /home/user/solidity-edu/42-vault-precision
   ```

2. **Install dependencies**
   ```bash
   forge install openzeppelin/openzeppelin-contracts --no-commit
   forge install foundry-rs/forge-std --no-commit
   ```

   Or use the Makefile:
   ```bash
   make install
   ```

3. **Build the project**
   ```bash
   forge build
   ```

   Or:
   ```bash
   make build
   ```

4. **Run tests**
   ```bash
   forge test
   ```

   Or:
   ```bash
   make test
   ```

## Quick Start Commands

```bash
# Run all tests
make test

# Run tests with verbose output
make test-v

# Run tests with very verbose output (shows traces)
make test-vv

# Run tests with gas reporting
make test-gas

# Run specific test
make test-match TEST=testDepositRoundsDownShares

# Run only rounding tests
make test-rounding

# Run only preview function tests
make test-preview

# Run only edge case tests
make test-edge

# Run only attack prevention tests
make test-attacks

# Run only invariant tests
make test-invariants

# Generate coverage report
make coverage

# Format code
make fmt

# Check code size
make size
```

## Verifying Your Solution

After implementing the TODOs in `src/Project42.sol`, run:

```bash
# Test your implementation
forge test --match-contract Project42Test -vv

# If all tests pass, compare with solution
diff src/Project42.sol src/solution/Project42Solution.sol
```

## Common Issues

### Issue: `forge: command not found`
**Solution**: Install Foundry (see above)

### Issue: `Missing dependencies`
**Solution**: Run `make install` or manually install with:
```bash
forge install openzeppelin/openzeppelin-contracts --no-commit
forge install foundry-rs/forge-std --no-commit
```

### Issue: `Could not find artifact`
**Solution**: Build the project first:
```bash
forge build
```

### Issue: Tests failing
**Solution**: Make sure you've implemented all TODOs in `Project42.sol`. Check:
- `mulDiv` and `mulDivUp` functions
- All conversion functions
- All preview functions
- All deposit/mint/withdraw/redeem functions

## Development Workflow

1. **Read the README.md** for concepts
2. **Read the TUTORIAL.md** for step-by-step implementation guide
3. **Implement TODOs** in `src/Project42.sol`
4. **Run tests** with `make test-v`
5. **Fix failures** by reviewing the tutorial and solution
6. **Verify all tests pass** with `make test`
7. **Check gas usage** with `make test-gas`

## Test Organization

The test file (`test/Project42.t.sol`) contains:

1. **Basic Functionality Tests** - Verify metadata and initial state
2. **Rounding Direction Tests** - Ensure correct rounding for security
3. **Preview Function Tests** - Verify preview matches actual operations
4. **Edge Case Tests** - Handle zero values and empty vault
5. **Invariant Tests** - Prove vault security properties
6. **Precision Tests** - Verify small amounts work correctly
7. **Attack Prevention Tests** - Ensure common attacks fail
8. **Allowance Tests** - Test approval mechanisms
9. **Fuzz Tests** - Random testing for edge cases

## Understanding Test Output

When a test fails, Foundry shows:
```
[FAIL. Reason: assertion failed]

Expected: 66
  Actual: 67
```

This means your rounding direction is incorrect. Review the TUTORIAL.md section on that function.

## Next Steps

After completing Project 42, you'll understand:
- ✅ Why rounding direction matters for DeFi security
- ✅ How to implement mathematically correct vault operations
- ✅ How to prevent precision-based attacks
- ✅ How to write comprehensive tests for financial contracts

Continue to the next project to learn more advanced DeFi concepts!

## Resources

- [Foundry Book](https://book.getfoundry.sh/)
- [EIP-4626 Standard](https://eips.ethereum.org/EIPS/eip-4626)
- [OpenZeppelin ERC4626](https://docs.openzeppelin.com/contracts/4.x/erc4626)
- [Solidity Documentation](https://docs.soliditylang.org/)

## Support

If you're stuck:
1. Review the TUTORIAL.md step-by-step guide
2. Check the solution in `src/solution/Project42Solution.sol`
3. Read the extensive comments in the solution
4. Run specific tests to isolate the issue
5. Use `forge test -vvvv` for maximum trace output

Happy learning! 🚀
