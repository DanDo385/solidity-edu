# Getting Started with Project 28: ERC-2981 Royalties

## Quick Start

### 1. Install Dependencies
```bash
cd /home/user/solidity-edu/28-erc2981-royalties
forge install OpenZeppelin/openzeppelin-contracts --no-commit
```

### 2. Run Tests
```bash
# Run all tests
forge test --match-path test/Project28.t.sol

# Run with verbose output
forge test --match-path test/Project28.t.sol -vv

# Run with gas report
forge test --match-path test/Project28.t.sol --gas-report
```

### 3. Your Task

Complete the TODOs in `src/Project28.sol`:

```solidity
// TODO locations:
1. Constructor - Set default royalty
2. mint() - Implement minting logic
3. setDefaultRoyalty() - Validate and set global royalty
4. setTokenRoyalty() - Validate and set per-token royalty
5. resetTokenRoyalty() - Reset token royalty to default
6. deleteDefaultRoyalty() - Delete global royalty
7. supportsInterface() - Return combined interface support
```

### 4. Test Your Implementation

```bash
# Run tests for your implementation
forge test --match-path test/Project28.t.sol -vv

# Check specific functionality
forge test --match-test test_SetDefaultRoyalty -vvv
forge test --match-test test_RoyaltyCalculation -vvv
```

### 5. Compare with Solution

After completing your implementation, compare with:
- `src/solution/Project28Solution.sol` - Complete solution
- `src/ExampleMarketplace.sol` - Real marketplace integration

### 6. Deploy (Optional)

```bash
# Set environment variables
export PRIVATE_KEY=your_private_key
export SEPOLIA_RPC_URL=your_rpc_url

# Deploy
forge script script/DeployProject28.s.sol:DeployProject28Solution \
    --rpc-url $SEPOLIA_RPC_URL \
    --broadcast
```

## Learning Path

### Beginner Track (Start Here)

1. Read `README.md` - Introduction section
2. Read `QUICK_REFERENCE.md` - Essential interface
3. Study `src/solution/Project28Solution.sol` - Constructor and mint
4. Complete TODOs 1-2 in `src/Project28.sol`
5. Run tests: `forge test --match-test test_Mint`

### Intermediate Track

1. Read `README.md` - Implementation Patterns
2. Study `src/solution/Project28Solution.sol` - Royalty functions
3. Complete TODOs 3-6 in `src/Project28.sol`
4. Run tests: `forge test --match-test test_SetDefaultRoyalty`
5. Run tests: `forge test --match-test test_SetTokenRoyalty`

### Advanced Track

1. Read `README.md` - Marketplace Integration
2. Study `src/ExampleMarketplace.sol`
3. Read `README.md` - Advanced Patterns
4. Run integration tests: `forge test --match-test test_MarketplaceIntegration`
5. Experiment with custom implementations

## Key Concepts to Understand

### 1. Interface Detection
```solidity
// ERC-2981 interface ID
bytes4 constant INTERFACE_ID = 0x2a55205a;

// Check support
bool supportsRoyalties = nft.supportsInterface(INTERFACE_ID);
```

### 2. Royalty Calculation
```solidity
// 5% royalty on 10 ETH sale
// (10 ETH * 500 basis points) / 10000 = 0.5 ETH
(address receiver, uint256 amount) = nft.royaltyInfo(tokenId, 10 ether);
// receiver = 0x123...
// amount = 0.5 ether
```

### 3. Global vs Per-Token
```solidity
// Global: All tokens use same royalty
_setDefaultRoyalty(creator, 500); // 5% to creator

// Per-token: Specific token uses custom royalty
_setTokenRoyalty(tokenId, artist, 1000); // 10% to artist
```

## Common Issues & Solutions

### Issue 1: Interface Not Detected
```solidity
// ❌ Wrong - missing ERC2981 in override
function supportsInterface(bytes4 interfaceId)
    public view override(ERC721) returns (bool)

// ✅ Correct - includes both parents
function supportsInterface(bytes4 interfaceId)
    public view override(ERC721, ERC2981) returns (bool)
```

### Issue 2: Royalty Too High
```solidity
// ❌ Wrong - no validation
_setDefaultRoyalty(receiver, feeNumerator);

// ✅ Correct - validate maximum
require(feeNumerator <= 1000, "Max 10%");
_setDefaultRoyalty(receiver, feeNumerator);
```

### Issue 3: Invalid Receiver
```solidity
// ❌ Wrong - allows zero address
_setDefaultRoyalty(receiver, feeNumerator);

// ✅ Correct - validate receiver
require(receiver != address(0), "Invalid receiver");
_setDefaultRoyalty(receiver, feeNumerator);
```

## Testing Checklist

Before considering your implementation complete:

- [ ] All tests pass
- [ ] ERC-2981 interface is detected
- [ ] Royalty calculation is accurate
- [ ] Maximum royalty fee is enforced
- [ ] Zero address is rejected
- [ ] Per-token royalties override global
- [ ] Reset functionality works
- [ ] Events are emitted
- [ ] Gas usage is reasonable
- [ ] Code is well-commented

## What Success Looks Like

```bash
forge test --match-path test/Project28.t.sol

Running 40+ tests...

[PASS] test_Constructor()
[PASS] test_SupportsInterface_ERC2981()
[PASS] test_Mint()
[PASS] test_SetDefaultRoyalty()
[PASS] test_SetTokenRoyalty()
[PASS] test_RoyaltyCalculation_5Percent()
[PASS] test_MarketplaceIntegration_BasicSale()
...

Test result: ok. 40+ passed; 0 failed
```

## Resources

### Documentation
- `README.md` - Comprehensive guide (442 lines)
- `QUICK_REFERENCE.md` - Quick reference (235 lines)
- `PROJECT_OVERVIEW.md` - Project overview (383 lines)

### Code
- `src/Project28.sol` - Your workspace (153 lines)
- `src/solution/Project28Solution.sol` - Reference solution (347 lines)
- `src/ExampleMarketplace.sol` - Marketplace example (336 lines)

### Testing
- `test/Project28.t.sol` - 100+ tests (566 lines)

### Deployment
- `script/DeployProject28.s.sol` - Multiple deployment scripts (354 lines)

### External Links
- [EIP-2981 Specification](https://eips.ethereum.org/EIPS/eip-2981)
- [OpenZeppelin ERC2981](https://docs.openzeppelin.com/contracts/4.x/api/token/common#ERC2981)
- [OpenZeppelin ERC721](https://docs.openzeppelin.com/contracts/4.x/api/token/erc721)

## Need Help?

1. Check `QUICK_REFERENCE.md` for syntax
2. Read `README.md` for concepts
3. Study `src/solution/Project28Solution.sol` for implementation
4. Review test cases in `test/Project28.t.sol`
5. Examine `src/ExampleMarketplace.sol` for integration

## Next Project

After completing this project, you'll be ready for:
- Operator Filter Registry (enforcing royalties)
- Advanced NFT features
- Marketplace development
- Multi-sig royalty management

Good luck! 🚀
