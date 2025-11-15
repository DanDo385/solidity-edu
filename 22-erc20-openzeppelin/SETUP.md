# Setup Guide - Project 22: ERC-20 (OpenZeppelin)

This guide will help you set up and run Project 22, which focuses on OpenZeppelin's ERC-20 implementation.

## Prerequisites

1. **Foundry**: Install from [https://getfoundry.sh](https://getfoundry.sh)
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Git**: Required for dependency management

## Quick Start

### Option 1: Using the Install Script (Recommended)

```bash
cd 22-erc20-openzeppelin
./install.sh
```

### Option 2: Manual Installation

```bash
cd 22-erc20-openzeppelin

# Install OpenZeppelin Contracts
forge install OpenZeppelin/openzeppelin-contracts@v5.0.0 --no-commit

# Install Forge Standard Library
forge install foundry-rs/forge-std --no-commit
```

## Verify Installation

Check that dependencies are installed:

```bash
ls lib/
# Should show:
# - openzeppelin-contracts
# - forge-std
```

## Build the Project

```bash
forge build
```

Expected output: All contracts should compile successfully.

## Run Tests

### Run all tests:
```bash
forge test
```

### Run with verbosity:
```bash
forge test -vv
```

### Run specific test contract:
```bash
forge test --match-contract Project22Test -vvv
```

### Run specific test function:
```bash
forge test --match-test test_BasicToken_Transfer -vvv
```

### Run with gas reporting:
```bash
forge test --gas-report
```

## Project Structure

```
22-erc20-openzeppelin/
├── README.md                          # Comprehensive learning guide
├── SETUP.md                          # This file
├── foundry.toml                      # Foundry configuration
├── remappings.txt                    # Import path mappings
├── install.sh                        # Installation script
├── .gitignore                        # Git ignore rules
├── src/
│   ├── Project22.sol                # Skeleton with TODOs
│   └── solution/
│       └── Project22Solution.sol    # Complete solution
├── test/
│   └── Project22.t.sol             # Comprehensive tests
└── script/
    └── DeployProject22.s.sol       # Deployment scripts
```

## Working on the Project

### 1. Start with the Skeleton

Open `src/Project22.sol` and implement the TODOs:

```bash
# Open in your editor
code src/Project22.sol
```

### 2. Run Tests

As you implement, run tests to verify:

```bash
forge test --match-contract BasicToken -vv
```

### 3. Compare with Solution

When stuck, check the solution:

```bash
code src/solution/Project22Solution.sol
```

### 4. Run Solution Tests

To see how the complete solution works:

```bash
forge test --match-contract Project22Test -vvv
```

## Common Issues

### Issue: "Error: No such file or directory: lib/openzeppelin-contracts"

**Solution**: Install dependencies using `./install.sh` or manually with `forge install`

### Issue: "Error: Failed to resolve imports"

**Solution**: Check that `remappings.txt` exists and contains:
```
@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/
```

### Issue: "Command not found: forge"

**Solution**: Install Foundry:
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Issue: Tests fail with "ERC20: ..."

**Solution**: Make sure you're using OpenZeppelin v5.0.0:
```bash
cd lib/openzeppelin-contracts
git checkout v5.0.0
```

## Deployment

### Local Deployment (Anvil)

1. Start local node:
```bash
anvil
```

2. Deploy (in another terminal):
```bash
forge script script/DeployProject22.s.sol:DeployBasicToken \
  --rpc-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --broadcast
```

### Testnet Deployment (Sepolia)

1. Set up environment variables:
```bash
export PRIVATE_KEY=your_private_key_here
export SEPOLIA_RPC_URL=your_sepolia_rpc_url
```

2. Deploy:
```bash
forge script script/DeployProject22.s.sol:DeployBasicToken \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify
```

## Learning Path

1. **Basic Token** (30 min)
   - Implement `BasicToken`
   - Run tests: `forge test --match-contract BasicToken`

2. **Burnable Token** (20 min)
   - Implement `BurnableToken`
   - Test burn functionality

3. **Pausable Token** (30 min)
   - Implement `PausableToken`
   - Learn about hook overrides

4. **Snapshot Token** (45 min)
   - Implement `SnapshotToken`
   - Understand historical balance tracking

5. **Governance Token** (60 min)
   - Implement `GovernanceToken`
   - Learn delegation and voting

6. **Advanced Tokens** (90 min)
   - Implement `CustomHookToken`
   - Implement `VestingToken`
   - Implement `RewardToken`

Total estimated time: **4-5 hours**

## Additional Resources

- [OpenZeppelin Contracts Documentation](https://docs.openzeppelin.com/contracts/5.x/)
- [Foundry Book](https://book.getfoundry.sh/)
- [EIP-20: Token Standard](https://eips.ethereum.org/EIPS/eip-20)
- [EIP-2612: Permit](https://eips.ethereum.org/EIPS/eip-2612)

## Getting Help

If you encounter issues:

1. Check the [README.md](README.md) for detailed explanations
2. Review the solution in `src/solution/Project22Solution.sol`
3. Run tests with `-vvvv` for detailed traces
4. Check the [OpenZeppelin forum](https://forum.openzeppelin.com/)

## Next Steps

After completing this project:

1. Try combining multiple extensions
2. Experiment with custom hook logic
3. Build a token for a specific use case
4. Deploy to testnet and interact with it
5. Move on to Project 23: ERC-20 Permit (EIP-2612)

Happy coding!
