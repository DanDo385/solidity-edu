# Project 49 Setup Guide

## Prerequisites

- Foundry installed (https://book.getfoundry.sh/getting-started/installation)
- Git

## Installation

1. Navigate to the project directory:
```bash
cd 49-leverage-vault
```

2. Install dependencies (OpenZeppelin contracts):
```bash
forge install OpenZeppelin/openzeppelin-contracts --no-commit
```

3. Install Forge Standard Library (if not already installed):
```bash
forge install foundry-rs/forge-std --no-commit
```

## Build

```bash
forge build
```

## Test

Run all tests:
```bash
forge test
```

Run tests with verbose output:
```bash
forge test -vv
```

Run specific test:
```bash
forge test --match-test test_LeverageLoop_ExecutesCorrectly -vvv
```

Run tests with gas reporting:
```bash
forge test --gas-report
```

## Deploy

### Local Testing (Anvil)

1. Start local node:
```bash
anvil
```

2. Deploy (in another terminal):
```bash
forge script script/DeployProject49.s.sol:DeployProject49 --rpc-url http://localhost:8545 --broadcast
```

### Testnet (Sepolia)

```bash
forge script script/DeployProject49.s.sol:DeployProject49 \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify
```

### Mainnet

⚠️ **WARNING**: Review all code thoroughly before mainnet deployment!

```bash
forge script script/DeployProject49.s.sol:DeployProject49 \
  --rpc-url $MAINNET_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify
```

## Project Structure

```
49-leverage-vault/
├── src/
│   ├── Project49.sol              # Skeleton contract with TODOs
│   └── solution/
│       └── Project49Solution.sol  # Complete solution
├── test/
│   └── Project49.t.sol           # Comprehensive test suite
├── script/
│   └── DeployProject49.s.sol     # Deployment scripts
├── README.md                      # Educational guide
├── SETUP.md                       # This file
└── foundry.toml                   # Foundry configuration
```

## Learning Path

1. Read `README.md` to understand leverage looping concepts
2. Study `src/Project49.sol` and review the TODOs
3. Try implementing the TODOs yourself
4. Compare with `src/solution/Project49Solution.sol`
5. Run tests to verify your implementation
6. Experiment with different leverage ratios

## Remappings

If you encounter import issues, create a `remappings.txt`:

```
@openzeppelin/=lib/openzeppelin-contracts/
forge-std/=lib/forge-std/src/
```

## Troubleshooting

### Import errors
- Run `forge install` to ensure dependencies are installed
- Check `remappings.txt` exists
- Run `forge remappings` to verify mappings

### Test failures
- Ensure you're using Solidity ^0.8.20
- Check that mock contracts are properly deployed in setUp()
- Review error messages carefully

### Gas errors
- Increase gas limit in foundry.toml
- Optimize loop iterations
- Review storage usage

## Additional Resources

- [Aave V3 Documentation](https://docs.aave.com/developers/)
- [Compound V3 Docs](https://docs.compound.finance/)
- [Foundry Book](https://book.getfoundry.sh/)
