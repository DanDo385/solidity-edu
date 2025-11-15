# Project 28: ERC-2981 Royalties - Overview

## Project Summary

A comprehensive educational project teaching the EIP-2981 royalty standard for NFTs. Students learn how to implement on-chain royalty information that marketplaces can query to automatically pay creators on secondary sales.

## What Students Learn

1. **EIP-2981 Standard**: Understanding the royalty interface and its purpose
2. **On-Chain Royalties**: How royalty information is stored and retrieved
3. **Marketplace Integration**: How marketplaces use ERC-2981 to pay creators
4. **Royalty Calculation**: Basis points system and fee calculations
5. **Flexibility**: Global vs per-token royalty configurations
6. **Interface Detection**: Using ERC165 for feature detection
7. **OpenZeppelin Integration**: Using battle-tested implementations
8. **Real-World Limitations**: Understanding that royalties are not enforceable

## Project Structure

```
28-erc2981-royalties/
├── README.md                      # Comprehensive guide (442 lines)
├── QUICK_REFERENCE.md             # Quick reference guide (229 lines)
├── PROJECT_OVERVIEW.md            # This file
├── foundry.toml                   # Foundry configuration
├── .gitignore                     # Git ignore file
│
├── src/
│   ├── Project28.sol              # Skeleton contract with TODOs (153 lines)
│   ├── ExampleMarketplace.sol     # Example marketplace integration (271 lines)
│   └── solution/
│       └── Project28Solution.sol  # Complete solution (347 lines)
│
├── test/
│   └── Project28.t.sol            # Comprehensive tests (566 lines)
│
└── script/
    └── DeployProject28.s.sol      # Deployment scripts (354 lines)
```

**Total**: 2,433 lines of educational content

## File Descriptions

### 1. README.md (442 lines)
Comprehensive guide covering:
- What is EIP-2981 and why it matters
- How royalties work on-chain
- The standard interface explained
- Royalty calculation and basis points
- Global vs per-token royalties
- Marketplace integration patterns
- Royalty recipient management
- Fee calculation best practices
- Limitations and considerations
- OpenZeppelin implementation
- Advanced patterns
- Common pitfalls
- Testing checklist

### 2. src/Project28.sol (153 lines)
Skeleton contract for students featuring:
- Clear TODO markers for implementation
- ERC721 + ERC2981 inheritance
- Constructor setup
- Minting functionality
- Default royalty management
- Per-token royalty management
- Interface support
- Detailed hints and guidance
- Marketplace integration notes

### 3. src/solution/Project28Solution.sol (347 lines)
Complete reference implementation with:
- Full ERC-2981 implementation
- Global default royalties
- Per-token royalty customization
- Royalty updates and resets
- Comprehensive documentation
- Inline examples and explanations
- Marketplace integration guide
- Advanced patterns and use cases
- Calculation examples
- Best practices
- Security considerations

### 4. src/ExampleMarketplace.sol (271 lines)
Real-world marketplace example showing:
- How marketplaces list NFTs
- ERC-2981 detection via ERC165
- Royalty info querying
- Payment distribution logic
- Royalty preview functionality
- Complete purchase flow
- Security considerations
- Integration checklist
- Advanced features discussion
- Practical usage examples

### 5. test/Project28.t.sol (566 lines)
Comprehensive test suite covering:
- Constructor validation
- Interface detection (ERC2981, ERC721, ERC165)
- Minting functionality
- Global royalty settings
- Per-token royalty settings
- Royalty calculation accuracy
- Fee validation
- Access control
- Update mechanisms
- Marketplace integration scenarios
- Fuzz testing
- Edge cases
- Real-world scenarios

**Test Categories**:
- 15+ constructor and setup tests
- 10+ interface detection tests
- 8+ minting tests
- 12+ global royalty tests
- 15+ per-token royalty tests
- 10+ calculation accuracy tests
- 8+ marketplace integration tests
- 5+ fuzz tests
- 10+ edge case tests
- 5+ integration scenario tests

### 6. script/DeployProject28.s.sol (354 lines)
Multiple deployment scripts:
- **DeployProject28**: Basic skeleton deployment
- **DeployProject28Solution**: Solution deployment
- **DeployProject28Custom**: Custom configuration from env vars
- **DeployProject28WithMinting**: Deploy with initial minting
- **DeployProject28MultiReceiver**: Multi-receiver example

Features:
- Environment variable configuration
- Parameter validation
- Deployment logging
- Post-deployment instructions
- Verification commands
- Testing examples
- Marketplace verification guide

### 7. QUICK_REFERENCE.md (229 lines)
Fast-access reference guide:
- Essential interface code
- Interface ID constant
- Basis points conversion table
- OpenZeppelin setup examples
- Common implementation patterns
- Marketplace integration snippets
- Testing checklist
- Common gotchas and solutions
- Calculation examples
- Best practices summary
- Limitations reminder
- Useful CLI commands
- Resource links

## Key Concepts Covered

### 1. EIP-2981 Standard
- `royaltyInfo(uint256 tokenId, uint256 salePrice)` function
- Returns receiver address and royalty amount
- Interface ID: `0x2a55205a`
- ERC165 interface detection

### 2. Basis Points System
```
100 basis points = 1%
500 basis points = 5%
1000 basis points = 10%

Formula: royaltyAmount = (salePrice * basisPoints) / 10000
```

### 3. Global Royalties
- Single royalty setting for all tokens
- Lower gas costs
- Simple management
- Use `_setDefaultRoyalty(receiver, feeNumerator)`

### 4. Per-Token Royalties
- Different royalty for each token
- Higher flexibility
- Collaborative collections
- Use `_setTokenRoyalty(tokenId, receiver, feeNumerator)`

### 5. Marketplace Integration
```solidity
// 1. Check support
bool supportsRoyalties = nft.supportsInterface(0x2a55205a);

// 2. Get royalty info
(address receiver, uint256 amount) = nft.royaltyInfo(tokenId, salePrice);

// 3. Pay royalty
payable(receiver).transfer(amount);

// 4. Pay seller
payable(seller).transfer(salePrice - amount);

// 5. Transfer NFT
nft.transferFrom(seller, buyer, tokenId);
```

### 6. Important Limitations
- Royalties are NOT enforceable on-chain
- Marketplaces must voluntarily honor them
- Direct transfers bypass royalties
- Some marketplaces may ignore or cap royalties

## Learning Path

### Step 1: Understand the Concept
Read `README.md` sections:
- What is EIP-2981?
- How Royalties Work On-Chain
- The Standard Interface

### Step 2: Study Implementation Patterns
Review `QUICK_REFERENCE.md`:
- Basic setup
- Common patterns
- OpenZeppelin usage

### Step 3: Examine Real Integration
Study `src/ExampleMarketplace.sol`:
- How marketplaces detect royalties
- Payment flow
- Integration checklist

### Step 4: Complete the Skeleton
Work on `src/Project28.sol`:
- Follow TODO comments
- Implement each function
- Test as you go

### Step 5: Run Tests
Execute test suite:
```bash
forge test --match-path test/Project28.t.sol -vv
```

### Step 6: Compare with Solution
Review `src/solution/Project28Solution.sol`:
- Compare implementations
- Learn advanced patterns
- Understand best practices

### Step 7: Deploy and Verify
Use deployment scripts:
```bash
forge script script/DeployProject28.s.sol:DeployProject28Solution --broadcast
```

## Testing Strategy

The test suite is organized by functionality:

1. **Basic Tests**: Constructor, interface support, minting
2. **Royalty Tests**: Global and per-token royalty settings
3. **Calculation Tests**: Verify accurate fee calculations
4. **Integration Tests**: Marketplace interaction scenarios
5. **Fuzz Tests**: Random input validation
6. **Edge Cases**: Boundary conditions and error cases
7. **Scenarios**: Real-world usage patterns

Run specific test categories:
```bash
# All tests
forge test --match-path test/Project28.t.sol

# Verbose output
forge test --match-path test/Project28.t.sol -vv

# Specific test
forge test --match-test test_RoyaltyCalculation_5Percent -vvv

# Gas report
forge test --match-path test/Project28.t.sol --gas-report
```

## Advanced Topics Covered

1. **Split Royalties**: Using PaymentSplitter for multiple recipients
2. **Dynamic Royalties**: Changing fees based on conditions
3. **Time-Based Royalties**: Decreasing royalties over time
4. **Multi-Tier Royalties**: Different rates for price ranges
5. **Hybrid Approach**: Combining global and per-token royalties
6. **Marketplace Features**: Fees, offers, batch operations
7. **Security Patterns**: Reentrancy protection, validation

## Real-World Applications

This project prepares students for:
- NFT marketplace development
- Creator-focused NFT projects
- Multi-artist collaborative collections
- Gallery and auction platforms
- Royalty management systems
- Cross-platform NFT standards

## Marketplace Compatibility

Students learn about royalty support in:
- OpenSea (supports ERC-2981)
- LooksRare (supports ERC-2981)
- Rarible (supports ERC-2981)
- X2Y2 (supports ERC-2981)
- Blur (does not enforce royalties)
- Direct transfers (no royalties)

## Success Criteria

Students successfully complete this project when they can:
- [ ] Explain what EIP-2981 is and why it exists
- [ ] Implement ERC-2981 in an NFT contract
- [ ] Calculate royalty amounts correctly
- [ ] Set both global and per-token royalties
- [ ] Integrate royalties with a marketplace
- [ ] Override supportsInterface correctly
- [ ] Validate royalty parameters
- [ ] Understand the limitations of on-chain royalties
- [ ] Test royalty functionality comprehensively
- [ ] Deploy a production-ready royalty NFT

## Next Steps

After mastering ERC-2981, students should explore:
- **Operator Filter Registry**: Enforcing royalties via transfer restrictions
- **Payment Splitters**: Distributing royalties to multiple recipients
- **ERC-721 Extensions**: Combining royalties with other features
- **Marketplace Development**: Building platforms that honor royalties
- **Cross-Chain Royalties**: Managing royalties across multiple chains

## Resources Provided

- Comprehensive documentation (README.md)
- Quick reference guide (QUICK_REFERENCE.md)
- Skeleton contract with TODOs
- Complete solution with explanations
- Real marketplace integration example
- 100+ comprehensive tests
- Multiple deployment scripts
- CLI command examples
- Best practices and gotchas
- Security considerations

## Estimated Time

- **Reading & Understanding**: 1-2 hours
- **Implementation**: 2-3 hours
- **Testing & Debugging**: 1-2 hours
- **Advanced Topics**: 1-2 hours
- **Total**: 5-9 hours

## Difficulty Level

**Intermediate**

Prerequisites:
- Solid understanding of ERC-721
- Familiarity with OpenZeppelin contracts
- Understanding of multiple inheritance
- Basic knowledge of interface detection (ERC165)
- Experience with Foundry testing

## Educational Value

This project teaches critical concepts for modern NFT development:
- **Standards Compliance**: Following EIPs for interoperability
- **Marketplace Integration**: Building compatible systems
- **Creator Economics**: Supporting ongoing creator compensation
- **Interface Design**: Clean, standard APIs
- **Gas Optimization**: Choosing between global/per-token approaches
- **Security**: Validating inputs and handling edge cases
- **Real-World Limitations**: Understanding what blockchain can/cannot enforce

## License

MIT License - Free for educational use
