# Quick Start Guide - Project 50: DeFi Protocol Capstone

## Prerequisites

- Foundry installed ([https://book.getfoundry.sh/getting-started/installation](https://book.getfoundry.sh/getting-started/installation))
- Git
- Basic understanding of DeFi concepts

## Installation

### 1. Install Dependencies

```bash
cd /home/user/solidity-edu/50-defi-capstone

# Install OpenZeppelin contracts (standard)
forge install OpenZeppelin/openzeppelin-contracts --no-commit

# Install OpenZeppelin upgradeable contracts
forge install OpenZeppelin/openzeppelin-contracts-upgradeable --no-commit

# Install forge-std (for testing)
forge install foundry-rs/forge-std --no-commit
```

### 2. Build the Project

```bash
# Compile all contracts
forge build

# Check for any compilation errors
forge build --force
```

### 3. Run Tests

```bash
# Run all tests
forge test

# Run tests with detailed output
forge test -vvv

# Run specific test
forge test --match-contract Project50Test

# Run tests with gas reporting
forge test --gas-report

# Run with coverage
forge coverage
```

## Development Workflow

### Phase 1: Understanding the Skeleton

1. **Read the README.md** - Understand the protocol architecture
2. **Review src/Project50.sol** - Study the skeleton with TODOs
3. **Check the solution** - Reference src/solution/Project50Solution.sol when stuck
4. **Run tests** - See what's expected: `forge test`

### Phase 2: Implementation

Start implementing the TODOs in order:

#### Step 1: Protocol Token
```solidity
// Implement in src/Project50.sol:
// - mint() function with MAX_SUPPLY check
// - burn() function
// - pause/unpause functions
```

#### Step 2: NFT Membership
```solidity
// Implement:
// - mintMembership() - Check limits, burn PROTO, mint NFT
// - upgradeMembership() - Upgrade tier logic
// - getVotingMultiplier() - Return multiplier based on tier
// - getFeeDiscount() - Return discount percentage
```

#### Step 3: Oracle System
```solidity
// Implement:
// - setPriceFeed() - Configure price feeds
// - getPrice() - Fetch and validate price
// - validatePrice() - Check price deviation
```

#### Step 4: Governance
```solidity
// Implement:
// - propose() - Create proposals
// - castVote() - Vote with NFT weight
// - queue() - Queue successful proposals
// - execute() - Execute queued proposals
```

#### Step 5: Vault with Flash Loans
```solidity
// Implement:
// - deposit/withdraw with NFT discounts
// - harvest() - Collect and distribute fees
// - flashLoan() - ERC3156 flash loan implementation
// - maxFlashLoan() - Calculate max loan amount
```

#### Step 6: Multi-sig Treasury
```solidity
// Implement:
// - submitTransaction()
// - confirmTransaction()
// - executeTransaction()
```

### Phase 3: Testing

Write tests as you implement features:

```bash
# Test individual components
forge test --match-contract Project50Test --match-test test_ProtocolToken

# Test integration
forge test --match-test test_Integration

# Test attack scenarios
forge test --match-test test_Attack

# Fuzz testing
forge test --match-test testFuzz
```

### Phase 4: Deployment

```bash
# Local deployment (for testing)
anvil # Start local node in another terminal

# Deploy to local node
forge script script/DeployProject50.s.sol:DeployProject50 \
  --fork-url http://localhost:8545 \
  --broadcast

# Deploy to testnet (Sepolia)
forge script script/DeployProject50.s.sol:DeployProject50 \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify

# Verify contracts
forge verify-contract <ADDRESS> <CONTRACT> --chain sepolia
```

## Testing Scenarios

### Unit Tests
```bash
forge test --match-test test_ProtocolToken_Mint
forge test --match-test test_NFTMembership_MintBronze
forge test --match-test test_Vault_Deposit
```

### Integration Tests
```bash
forge test --match-test test_Integration_FullUserJourney
```

### Attack Tests
```bash
forge test --match-test test_Attack_ReentrancyProtection
forge test --match-test test_Attack_FlashLoanInflationAttack
```

### Fuzzing
```bash
forge test --match-test testFuzz_Vault_DepositWithdraw
```

## Common Commands

### Compilation
```bash
forge build                    # Compile contracts
forge clean                    # Clean build artifacts
forge build --sizes            # Show contract sizes
```

### Testing
```bash
forge test                     # Run all tests
forge test -vvv                # Verbose output
forge test --gas-report        # Show gas usage
forge coverage                 # Coverage report
forge snapshot                 # Gas snapshots
```

### Deployment
```bash
forge script <script>          # Run deployment script
forge create <contract>        # Deploy single contract
forge verify-contract          # Verify on Etherscan
```

### Utilities
```bash
cast call <address> <sig>      # Call contract function
cast send <address> <sig>      # Send transaction
cast balance <address>         # Check balance
cast storage <address> <slot>  # Read storage slot
```

## Environment Variables

Create a `.env` file:

```bash
# RPC URLs
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/INFURA_RPC_URL
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/INFURA_RPC_URL

# Private Keys (NEVER commit these!)
PRIVATE_KEY=0x...
ADMIN_ADDRESS=0x...

# Multi-sig Signers
SIGNER_1=0x...
SIGNER_2=0x...
SIGNER_3=0x...
SIGNER_4=0x...
SIGNER_5=0x...

# Etherscan
ETHERSCAN_API_KEY=INFURA_RPC_URL

# Oracle Feeds (Chainlink)
PRICE_FEED_ADDRESS=0x...
```

Load environment:
```bash
source .env
```

## Debugging Tips

### 1. Compilation Errors
```bash
# Show detailed error
forge build --force

# Check specific file
forge build --contracts src/Project50.sol
```

### 2. Test Failures
```bash
# Run with maximum verbosity
forge test -vvvv

# Run single test with trace
forge test --match-test test_Name -vvvv

# Use console.log in tests
import "forge-std/console.sol";
console.log("Value:", value);
```

### 3. Gas Optimization
```bash
# Gas report
forge test --gas-report

# Create gas snapshot
forge snapshot

# Compare snapshots
forge snapshot --diff .gas-snapshot
```

### 4. Coverage Gaps
```bash
# Generate coverage
forge coverage

# Detailed coverage report
forge coverage --report lcov
```

## Production Checklist

Before mainnet deployment:

- [ ] All tests passing
- [ ] >95% code coverage
- [ ] Gas optimizations complete
- [ ] External audit completed
- [ ] Testnet deployment successful
- [ ] Multi-sig configured
- [ ] Timelock configured
- [ ] Emergency procedures tested
- [ ] Documentation complete
- [ ] Community disclosure

## Resources

- [Foundry Book](https://book.getfoundry.sh/)
- [OpenZeppelin Docs](https://docs.openzeppelin.com/)
- [Solidity Docs](https://docs.soliditylang.org/)
- [ERC Standards](https://eips.ethereum.org/)

## Getting Help

1. Check README.md for architecture details
2. Review solution contracts for reference
3. Read test cases for expected behavior
4. Consult OpenZeppelin documentation
5. Ask in community forums

## Next Steps

1. Complete all TODO implementations
2. Pass all tests
3. Deploy to testnet
4. Conduct security review
5. Plan mainnet launch

Good luck building your DeFi protocol! 🚀
