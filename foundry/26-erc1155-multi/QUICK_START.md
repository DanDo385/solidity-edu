# Quick Start Guide - Project 26: ERC-1155 Multi-Token

## Setup

1. Install Foundry (if not already installed):
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

2. Install dependencies:
```bash
forge install
```

3. Copy environment file:
```bash
cp .env.example .env
# Edit .env with your values
```

## Running Tests

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vvv

# Run specific test
forge test --match-test test_MintFungibleToken -vvv

# Run gas report
forge test --gas-report

# Run with gas snapshot
forge snapshot
```

## Key Test Categories

- **Basic Functionality**: Minting, balances, token types
- **Transfers**: Single and batch transfers
- **Approvals**: Operator approvals and transfers
- **Burn**: Token burning functionality
- **Safe Transfer Callbacks**: ERC-1155 receiver interface
- **Reentrancy**: Protection against reentrancy attacks
- **Mixed Tokens**: Combining fungible and NFTs
- **Gas Optimization**: Batch vs individual operations
- **Fuzz Tests**: Property-based testing

## Deployment

### Local Deployment

```bash
# Start local node
anvil

# Deploy (in another terminal)
forge script script/DeployProject26.s.sol:DeployProject26 \
  --fork-url http://localhost:8545 \
  --broadcast
```

### Testnet Deployment

```bash
# Deploy to Sepolia
forge script script/DeployProject26.s.sol:DeployProject26 \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```

### Run Demo

```bash
# Set deployed contract address in .env
export GAME_ITEMS_ADDRESS=0x...

# Run demo script
forge script script/DeployProject26.s.sol:DemoProject26 \
  --rpc-url <RPC_URL> \
  --broadcast
```

## Learning Path

### Step 1: Understand the Standard
- Read `/README.md` sections on ERC-1155 overview
- Compare with ERC-20 and ERC-721
- Study the token ID organization

### Step 2: Study the Skeleton
- Open `src/Project26.sol`
- Review the TODOs and structure
- Understand the gaming use case

### Step 3: Implement Features
Complete the TODOs in this order:
1. State variables and events
2. Basic view functions (`balanceOf`, `uri`)
3. Approval system (`setApprovalForAll`)
4. Single transfers (`safeTransferFrom`)
5. Batch operations (`safeBatchTransferFrom`)
6. Minting functions
7. Safe transfer callbacks
8. Burn functionality

### Step 4: Run Tests
```bash
# Test each feature as you implement
forge test --match-test test_MintFungibleToken
forge test --match-test test_SafeTransferFrom
forge test --match-test test_SafeBatchTransferFrom
```

### Step 5: Compare with Solution
- Check `src/solution/Project26Solution.sol`
- Study the comments and implementation details
- Understand the gas optimizations

### Step 6: Advanced Topics
- Study reentrancy protection
- Analyze gas comparisons in tests
- Explore batch operation efficiency
- Review safe transfer callback patterns

## Important Concepts to Master

### 1. Token ID Organization
```solidity
// Fungible (0-9999)
GOLD = 0
HEALTH_POTION = 1000

// Non-Fungible (10000+)
SWORD_1 = 10000
SWORD_2 = 10001
```

### 2. Nested Balance Mapping
```solidity
mapping(uint256 => mapping(address => uint256)) private _balances;
// _balances[tokenId][owner] = amount
```

### 3. Operator Approval
```solidity
// One approval for ALL token types
setApprovalForAll(operator, true);
```

### 4. Batch Operations
```solidity
// Transfer multiple types in one transaction
safeBatchTransferFrom(from, to, [id1, id2], [amt1, amt2], data);
```

### 5. Safe Transfer Callbacks
```solidity
// Contracts must implement IERC1155Receiver
function onERC1155Received(...) external returns (bytes4);
```

## Common Issues and Solutions

### Issue: "NotAuthorized" error
**Solution**: Make sure caller is token owner or approved operator

### Issue: "InsufficientBalance" error
**Solution**: Check balance before transfer with `balanceOf()`

### Issue: "UnsafeRecipient" error
**Solution**: Recipient contract must implement `IERC1155Receiver`

### Issue: "ArrayLengthMismatch" error
**Solution**: Ensure `ids` and `amounts` arrays have same length

### Issue: "Reentrancy" error
**Solution**: The contract is protecting against reentrancy attacks (this is good!)

## Gas Optimization Tips

1. **Use Batch Operations**
   - `mintBatch()` instead of multiple `mint()` calls
   - `safeBatchTransferFrom()` instead of multiple `safeTransferFrom()` calls

2. **Unchecked Math** (when safe)
   ```solidity
   unchecked {
       _balances[id][from] = fromBalance - amount;
   }
   ```

3. **Custom Errors**
   - Use custom errors instead of `require` strings
   - Saves deployment and runtime gas

4. **Efficient Storage**
   - Nested mappings are more efficient than alternatives
   - No need to track token ownership like ERC-721

## Testing Commands

```bash
# Run all tests
forge test

# Run with gas report
forge test --gas-report

# Run specific test file
forge test --match-path test/Project26.t.sol

# Run specific test function
forge test --match-test test_GasComparisonSingleVsBatch

# Run with maximum verbosity (shows stack traces)
forge test -vvvv

# Run fuzz tests with more runs
forge test --fuzz-runs 10000

# Generate coverage report
forge coverage
```

## Interacting with Deployed Contract

### Using Cast

```bash
# Check balance
cast call $GAME_ITEMS_ADDRESS \
  "balanceOf(address,uint256)" \
  $PLAYER_ADDRESS \
  0  # GOLD token ID

# Mint tokens (as owner)
cast send $GAME_ITEMS_ADDRESS \
  "mint(address,uint256,uint256,bytes)" \
  $RECIPIENT \
  0 \
  1000 \
  0x \
  --private-key $PRIVATE_KEY

# Approve operator
cast send $GAME_ITEMS_ADDRESS \
  "setApprovalForAll(address,bool)" \
  $OPERATOR_ADDRESS \
  true \
  --private-key $PRIVATE_KEY

# Transfer tokens
cast send $GAME_ITEMS_ADDRESS \
  "safeTransferFrom(address,address,uint256,uint256,bytes)" \
  $FROM \
  $TO \
  0 \
  100 \
  0x \
  --private-key $PRIVATE_KEY
```

## Additional Resources

- [EIP-1155 Specification](https://eips.ethereum.org/EIPS/eip-1155)
- [OpenZeppelin ERC1155 Docs](https://docs.openzeppelin.com/contracts/4.x/erc1155)
- [Foundry Book](https://book.getfoundry.sh/)
- Main README.md for detailed explanations

## Next Steps

After completing this project:
1. Build a complete game using ERC-1155
2. Implement marketplace with atomic swaps
3. Add meta-transaction support
4. Create a multi-token DeFi protocol
5. Explore semi-fungible token patterns
