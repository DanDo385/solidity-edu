# Project 44 Setup Guide

This guide will help you set up and run the Inflation Attack Demo project.

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Basic understanding of Solidity and ERC-4626
- Terminal/command line access

## Installation

### 1. Install Foundry (if not already installed)

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### 2. Initialize the Project

```bash
cd 44-inflation-attack

# Initialize Foundry project (if not already done)
forge init --force

# Install dependencies
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge install foundry-rs/forge-std --no-commit
```

### 3. Build the Project

```bash
# Compile all contracts
forge build

# You should see output indicating successful compilation
```

## Running Tests

### Run All Tests

```bash
forge test
```

### Run with Verbosity (see console.log output)

```bash
# -vv: Show test execution details
forge test -vv

# -vvv: Show execution traces
forge test -vvv

# -vvvv: Show execution traces and setup
forge test -vvvv
```

### Run Specific Tests

```bash
# Run only inflation attack tests
forge test --match-test test_InflationAttack

# Run only mitigation tests
forge test --match-test test_VirtualShares
forge test --match-test test_MinDeposit
forge test --match-test test_DeadShares

# Run comparative analysis
forge test --match-test test_CompareMitigations -vv
```

### Run with Gas Reports

```bash
forge test --gas-report
```

## Project Structure

```
44-inflation-attack/
├── README.md              # Comprehensive guide on inflation attacks
├── SETUP.md              # This file
├── foundry.toml          # Foundry configuration
├── remappings.txt        # Import remappings
├── .gitignore           # Git ignore rules
│
├── src/
│   ├── Project44.sol                    # Skeleton with TODOs
│   └── solution/
│       └── Project44Solution.sol        # Complete solution
│
├── test/
│   └── Project44.t.sol                  # Comprehensive tests
│
└── script/
    └── DeployProject44.s.sol            # Deployment script
```

## Learning Path

### Step 1: Study the Vulnerability

1. Read `README.md` to understand inflation attacks
2. Review the attack mechanism diagrams
3. Study the economic analysis section

### Step 2: Explore the Code

1. Open `src/Project44.sol`
2. Read all comments and TODOs
3. Try to understand the vulnerable vault implementation

### Step 3: Attempt Implementation

1. Try to fill in the TODOs in `src/Project44.sol`
2. Implement the vulnerable vault functions
3. Create the attacker contract logic
4. Test your implementation

### Step 4: Run Tests

```bash
# Test the vulnerable vault
forge test --match-test test_InflationAttack_Success -vvv

# This will show you the attack in action!
```

### Step 5: Study Mitigations

1. Review each mitigation strategy in `src/solution/Project44Solution.sol`
2. Understand the trade-offs of each approach
3. Run tests for each mitigation:

```bash
forge test --match-test test_VirtualShares_PreventsAttack -vv
forge test --match-test test_MinDeposit_PreventsAttack -vv
forge test --match-test test_DeadShares_PreventsAttack -vv
```

### Step 6: Compare Solutions

```bash
# Run comparative analysis
forge test --match-test test_CompareMitigations -vv

# Check gas costs
forge test --match-test test_GasCosts -vv
```

## Testing on Local Network

### 1. Start Anvil (Local Ethereum Node)

```bash
anvil
```

This will start a local Ethereum node and provide you with test accounts.

### 2. Deploy Contracts

In a new terminal:

```bash
# Deploy all contracts
forge script script/DeployProject44.s.sol:DeployProject44 \
  --rpc-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --broadcast

# The private key above is from Anvil's default accounts
```

### 3. Interact with Deployed Contracts

```bash
# Get the deployed addresses from the output
VULNERABLE_VAULT=<address>
MOCK_TOKEN=<address>

# Mint tokens
cast send $MOCK_TOKEN "mint(address,uint256)" YOUR_ADDRESS 10000000000000000000000 \
  --rpc-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Approve vault
cast send $MOCK_TOKEN "approve(address,uint256)" $VULNERABLE_VAULT $(cast max-uint256) \
  --rpc-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Deposit to vault
cast send $VULNERABLE_VAULT "deposit(uint256,address)" 1000000000000000000000 YOUR_ADDRESS \
  --rpc-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

## Understanding Test Output

When you run `forge test --match-test test_InflationAttack_Success -vvv`, you'll see:

1. **Initial Balances**: Starting balances of attacker and victim
2. **Step 1**: Attacker deposits 1 wei, gets 1 share
3. **Step 2**: Attacker donates large amount, inflating share price
4. **Step 3**: Victim deposits, receives 0 shares (!)
5. **Step 4**: Attacker redeems shares, gets all funds
6. **Profit Calculation**: Shows attacker profit and victim loss

## Troubleshooting

### Build Fails

```bash
# Clean build artifacts
forge clean

# Rebuild
forge build
```

### Import Errors

```bash
# Reinstall dependencies
rm -rf lib/
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge install foundry-rs/forge-std --no-commit
```

### Tests Fail

```bash
# Make sure you're using the solution file
# The skeleton file (Project44.sol) has TODOs that need to be filled in

# Run tests against solution
forge test --match-path test/Project44.t.sol -vv
```

## Additional Resources

### Foundry Documentation
- [Foundry Book](https://book.getfoundry.sh/)
- [Forge Commands](https://book.getfoundry.sh/reference/forge/)
- [Testing Guide](https://book.getfoundry.sh/forge/tests)

### ERC-4626 Resources
- [EIP-4626 Specification](https://eips.ethereum.org/EIPS/eip-4626)
- [OpenZeppelin ERC4626 Docs](https://docs.openzeppelin.com/contracts/4.x/erc4626)

### Security Resources
- [OpenZeppelin Security Blog](https://blog.openzeppelin.com/)
- [Consensys Smart Contract Best Practices](https://consensys.github.io/smart-contract-best-practices/)

## Quick Reference

### Common Commands

```bash
# Build
forge build

# Test
forge test

# Test with logs
forge test -vv

# Test specific function
forge test --match-test testName

# Gas report
forge test --gas-report

# Deploy locally
forge script script/DeployProject44.s.sol --rpc-url http://localhost:8545 --broadcast

# Clean
forge clean
```

### Test Contracts Directly

```bash
# Check vault balance
cast call $VAULT_ADDRESS "totalAssets()" --rpc-url http://localhost:8545

# Check share supply
cast call $VAULT_ADDRESS "totalSupply()" --rpc-url http://localhost:8545

# Check user shares
cast call $VAULT_ADDRESS "balanceOf(address)" $USER_ADDRESS --rpc-url http://localhost:8545

# Preview deposit
cast call $VAULT_ADDRESS "previewDeposit(uint256)" 1000000000000000000 --rpc-url http://localhost:8545
```

## Next Steps

After completing this project:

1. ✅ Understand the inflation attack mechanism
2. ✅ Know how to identify vulnerable vaults
3. ✅ Implement multiple mitigation strategies
4. ✅ Make informed decisions about vault security

Consider exploring:
- Other ERC-4626 attack vectors
- Vault strategy implementations
- MEV considerations for vaults
- Cross-chain vault security

## Support

If you encounter issues:

1. Check the README.md for detailed explanations
2. Review the solution code in `src/solution/`
3. Read test output carefully (use -vvv for details)
4. Consult Foundry documentation
5. Review the comments in the code

Happy learning! 🔒
