# Project 25: ERC-721A Optimized NFT Collection

Master Azuki's ERC-721A standard for gas-optimized batch minting of NFTs.

## Learning Objectives

- Understand ERC-721A optimization techniques
- Learn how batch minting saves gas
- Master storage packing and ownership inference
- Compare standard ERC-721 vs ERC-721A
- Implement sequential token IDs efficiently
- Know when to use ERC-721A

## ERC-721A Overview: Gas-Optimized NFT Minting

**FIRST PRINCIPLES: Batch Operation Optimization**

ERC-721A is an improved ERC-721 implementation by Azuki that dramatically reduces gas costs for batch minting NFTs. Instead of updating storage for every token during batch mints, it leverages clever optimizations.

**CONNECTION TO PROJECT 09**:
- **Project 09**: Standard ERC721 implementation (one token = one storage write)
- **Project 25**: ERC721A optimization (batch tokens = one storage write!)
- Both implement the same standard, but ERC721A is optimized for batch operations!

### Key Innovations

**UNDERSTANDING THE OPTIMIZATIONS**:

1. **Batch Minting Optimization**: Mint multiple tokens for the same gas as minting one
   - Standard ERC721: Each token = separate storage write (~20k gas)
   - ERC721A: Entire batch = single storage write (~20k gas)
   - Savings: ~20k gas per additional token!

2. **Sequential Token IDs**: Tokens are minted sequentially starting from 0
   - Enables ownership inference (don't need to store each token's owner)
   - From Project 01: Sequential IDs enable efficient algorithms

3. **Ownership Inference**: Owner lookups scan backwards to find the batch owner
   - Instead of storing owner for each token, scan to find batch start
   - Trade-off: Slightly more expensive reads, massively cheaper writes

4. **Storage Packing** (from Project 01 knowledge): Multiple values packed into single storage slots
   - Pack ownership data into single slot
   - Saves storage slots (and gas!)

5. **Minimal Storage Updates**: Only update storage once per batch, not per token
   - Standard: 5 tokens = 5 storage writes (~100k gas)
   - ERC721A: 5 tokens = 1 storage write (~20k gas)
   - Savings: 80% reduction!

**COMPARISON TO STANDARD ERC721** (from Project 09):

**Standard ERC721**:
```solidity
// Minting 5 tokens
for (uint i = 0; i < 5; i++) {
    _owners[tokenId + i] = owner;  // 5 storage writes
    _balances[owner]++;             // 5 balance updates
}
// Total: ~100,000 gas (5 × 20k gas)
```

**ERC721A**:
```solidity
// Minting 5 tokens
_owners[tokenId] = owner;           // 1 storage write (first token)
// Other tokens inferred from sequential IDs!
// Total: ~20,000 gas (1 × 20k gas)
// Savings: 80%!
```

**REAL-WORLD ANALOGY**: 
Like printing a book:
- **Standard ERC721**: Print each page separately (expensive!)
- **ERC721A**: Print entire book at once (cheap!)

## Gas Savings Analysis

### Standard ERC-721 Batch Minting

```solidity
// Minting 5 tokens with standard ERC-721
Token 1: ~150,000 gas (SSTORE from 0 to non-zero)
Token 2: ~150,000 gas
Token 3: ~150,000 gas
Token 4: ~150,000 gas
Token 5: ~150,000 gas
Total:   ~750,000 gas
```

### ERC-721A Batch Minting

```solidity
// Minting 5 tokens with ERC-721A
Batch of 5: ~160,000 gas (single storage update + batch logic)
Total:      ~160,000 gas
Savings:    ~590,000 gas (79% reduction!)
```

### Gas Comparison Table

| Tokens Minted | Standard ERC-721 | ERC-721A | Savings | % Saved |
|---------------|------------------|----------|---------|---------|
| 1             | ~150,000         | ~160,000 | -10,000 | -6.7%   |
| 2             | ~300,000         | ~165,000 | ~135,000| 45%     |
| 5             | ~750,000         | ~175,000 | ~575,000| 77%     |
| 10            | ~1,500,000       | ~190,000 | ~1,310,000| 87%   |
| 20            | ~3,000,000       | ~210,000 | ~2,790,000| 93%   |
| 50            | ~7,500,000       | ~250,000 | ~7,250,000| 97%   |

**Note**: ERC-721A is slightly more expensive for single mints but massively cheaper for batches.

## Storage Layout Optimization

### Standard ERC-721 Storage

```
// Each token requires separate storage slots
mapping(uint256 => address) private _owners;      // 1 slot per token
mapping(uint256 => address) private _tokenApprovals; // 1 slot per token
mapping(address => uint256) private _balances;     // 1 slot per owner

// Minting 5 tokens = 5 SSTORE operations for _owners + balance updates
```

### ERC-721A Storage Packing

```
// TokenOwnership struct packed into single slot (256 bits)
struct TokenOwnership {
    address addr;           // 160 bits - owner address
    uint64 startTimestamp;  // 64 bits  - when owned
    bool burned;            // 8 bits   - burn status
    // 24 bits unused
}

// Only store ownership for batch start
mapping(uint256 => TokenOwnership) private _ownerships;

// Minting 5 tokens = 1 SSTORE operation + balance update
```

### Storage Diagram

```
Standard ERC-721:
Token 0: [owner0] [approval0]
Token 1: [owner1] [approval1]
Token 2: [owner2] [approval2]
Token 3: [owner3] [approval3]
Token 4: [owner4] [approval4]
= 10 storage slots

ERC-721A (batch mint to same owner):
Token 0: [owner|timestamp|burned]
Token 1: []  ← inferred from token 0
Token 2: []  ← inferred from token 0
Token 3: []  ← inferred from token 0
Token 4: []  ← inferred from token 0
= 1 storage slot!
```

## Sequential Token IDs

ERC-721A enforces sequential token IDs starting from 0 (or _startTokenId()).

```solidity
// First mint: tokens 0-4
_mint(alice, 5);

// Second mint: tokens 5-9 (sequential)
_mint(bob, 5);

// Cannot mint arbitrary token IDs
// This pattern doesn't exist in ERC-721A
```

### Benefits

1. **Predictability**: Users know their token IDs
2. **Enumeration**: Easy to iterate through all tokens
3. **Optimization**: Sequential IDs enable ownership inference

### Limitations

1. **No Arbitrary IDs**: Can't mint specific token numbers
2. **No Gaps**: Can't skip token IDs
3. **Sequential Only**: Mints must be in order

## Ownership Inference

The core optimization: how ERC-721A finds owners without storing every mapping.

### Algorithm

```solidity
function ownerOf(uint256 tokenId) public view returns (address) {
    // Start at the requested token
    uint256 curr = tokenId;

    // Scan backwards until we find explicit ownership
    while (curr >= 0) {
        TokenOwnership memory ownership = _ownerships[curr];

        if (ownership.addr != address(0)) {
            // Found the batch owner!
            return ownership.addr;
        }

        curr--;
    }

    revert("Token doesn't exist");
}
```

### Example

```solidity
// Mint 5 tokens to Alice (IDs 0-4)
_mint(alice, 5);
// Storage: _ownerships[0] = {addr: alice, ...}

// Query ownership
ownerOf(0); // Finds _ownerships[0].addr = alice
ownerOf(3); // Scans: 3→2→1→0, finds alice
ownerOf(4); // Scans: 4→3→2→1→0, finds alice

// Transfer token 2 to Bob
transferFrom(alice, bob, 2);
// Storage: _ownerships[2] = {addr: bob, ...}

// Query ownership after transfer
ownerOf(0); // Finds _ownerships[0].addr = alice
ownerOf(2); // Finds _ownerships[2].addr = bob
ownerOf(3); // Scans: 3→2, finds bob (!)

// Fix: Need to set ownership at 3 to alice
// ERC-721A handles this in _beforeTokenTransfers
```

### Transfer Considerations

When transferring a token from a batch, ERC-721A must:
1. Set ownership for the transferred token to new owner
2. Set ownership for next token (if exists in batch) to previous owner
3. Update balance tracking

This makes transfers slightly more expensive but keeps minting cheap.

## When to Use ERC-721A

### Perfect Use Cases

1. **Public Mints**: Users mint multiple NFTs in one transaction
2. **Airdrops**: Project mints many tokens to various addresses
3. **Batch Distributions**: Pre-minting collections
4. **Sequential Collections**: Art series, generative collections
5. **High Volume Mints**: Thousands of tokens

### Not Ideal For

1. **Single Mint Only**: If users only mint 1, standard ERC-721 is cheaper
2. **Non-Sequential IDs**: If you need specific token numbers
3. **Sparse Collections**: If token IDs have gaps
4. **Low Supply**: Less than 100 tokens (optimization not worth complexity)

### Gas Break-Even Point

- **Break-even**: Minting 2+ tokens per transaction
- **Optimal**: Minting 5+ tokens per transaction
- **Maximum savings**: Batch mints of 20+ tokens

## Implementation Details

### Required Functions

```solidity
// Core minting
function _mint(address to, uint256 quantity) internal

// Batch-aware transfers
function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
) internal virtual

// Ownership lookup with inference
function ownerOf(uint256 tokenId) public view returns (address)

// Efficient balance tracking
function balanceOf(address owner) public view returns (uint256)
```

### Key Optimizations

1. **currentIndex**: Tracks next token ID to mint
2. **_addressData**: Packs balance and mint count per address
3. **Ownership Slots**: Only set at batch boundaries
4. **Aux Data**: 64 bits of custom data per address

## Common Pitfalls

### 1. Ownership Inference Bugs

```solidity
// ❌ Wrong: Transfer without updating adjacent ownership
function transfer(address to, uint256 tokenId) {
    _ownerships[tokenId].addr = to; // Missing next token update!
}

// ✅ Correct: ERC-721A handles this
_beforeTokenTransfers(from, to, tokenId, 1);
```

### 2. Balance Tracking

```solidity
// ❌ Wrong: Manual balance update
_balances[to] += 1;

// ✅ Correct: Use _addressData
_addressData[to].balance += 1;
```

### 3. Token Existence Checks

```solidity
// ❌ Wrong: Checking _ownerships directly
require(_ownerships[tokenId].addr != address(0));

// ✅ Correct: Check against currentIndex
require(tokenId < _currentIndex);
```

## Testing Strategy

### Gas Benchmarks

```solidity
function testGasMintSingle() public {
    uint256 gasBefore = gasleft();
    nft.mint(1);
    uint256 gasUsed = gasBefore - gasleft();
    console.log("Single mint gas:", gasUsed);
}

function testGasMintBatch5() public {
    uint256 gasBefore = gasleft();
    nft.mint(5);
    uint256 gasUsed = gasBefore - gasleft();
    console.log("Batch 5 mint gas:", gasUsed);
}
```

### Ownership Tests

```solidity
function testOwnershipInference() public {
    nft.mint(alice, 5);

    // All tokens should belong to alice
    assertEq(nft.ownerOf(0), alice);
    assertEq(nft.ownerOf(4), alice);

    // Transfer middle token
    nft.transferFrom(alice, bob, 2);

    // Check ownership after transfer
    assertEq(nft.ownerOf(0), alice); // Before transfer
    assertEq(nft.ownerOf(2), bob);   // Transferred
    assertEq(nft.ownerOf(3), alice); // After transfer (updated)
}
```

## Real-World Example: Azuki

Azuki used ERC-721A for their 10,000 NFT collection:

```solidity
// Public mint: Users could mint up to 5 NFTs
Minting 1 NFT:  ~160,000 gas
Minting 5 NFTs: ~175,000 gas (only 15k more!)

// Savings for users who minted 5:
Standard ERC-721: ~750,000 gas
ERC-721A:        ~175,000 gas
User saved:      ~575,000 gas (~76% reduction)
```

At 50 gwei and $2000 ETH:
- Standard: ~$75 in gas
- ERC-721A: ~$17.50 in gas
- **User saved: $57.50 per transaction**

## Project Structure

```
25-erc721a-optimized/
├── src/
│   ├── Project25.sol              # Skeleton implementation
│   └── solution/
│       └── Project25Solution.sol  # Complete solution
├── test/
│   └── Project25.t.sol           # Gas comparison tests
├── script/
│   └── DeployProject25.s.sol     # Deployment script
└── README.md                      # This file
```

## Tasks

### Part 1: Basic ERC-721A Implementation
1. Import ERC-721A from a library or implement core functions
2. Add basic minting function
3. Implement ownership tracking
4. Test single vs batch minting

### Part 2: Gas Optimization Analysis
1. Create gas benchmark tests
2. Compare with standard ERC-721
3. Measure different batch sizes
4. Document gas savings

### Part 3: Advanced Features
1. Add max supply limits
2. Implement mint price
3. Add owner-only batch minting
4. Create metadata URI functions

### Part 4: Transfer Optimization
1. Test transfer gas costs
2. Verify ownership updates
3. Test edge cases (first/last in batch)
4. Benchmark transfer costs

## Running the Project

```bash
# Install dependencies (if using Chiru Labs ERC-721A)
forge install chiru-labs/ERC721A

# Run tests
forge test --match-path test/Project25.t.sol -vv

# Run with gas reporting
forge test --match-path test/Project25.t.sol --gas-report

# Run specific gas test
forge test --match-test testGasBatchMint -vvv

# Deploy
forge script script/DeployProject25.s.sol:DeployProject25 --rpc-url <RPC_URL> --broadcast
```

## Expected Gas Results

When you complete this project, you should see:

```
Minting 1 token:  ~160,000 gas
Minting 2 tokens: ~165,000 gas  (82.5k per token)
Minting 5 tokens: ~175,000 gas  (35k per token)
Minting 10 tokens: ~190,000 gas (19k per token)
Minting 20 tokens: ~210,000 gas (10.5k per token)

Transfer (from batch): ~80,000 gas
Transfer (individual): ~50,000 gas
```

## Additional Resources

- [ERC-721A Documentation](https://chiru-labs.github.io/ERC721A/)
- [Azuki ERC-721A GitHub](https://github.com/chiru-labs/ERC721A)
- [Gas Optimization Article](https://www.azuki.com/erc721a)
- [OpenZeppelin ERC-721](https://docs.openzeppelin.com/contracts/4.x/erc721)

## Key Takeaways

1. **Batch minting** is where ERC-721A shines (77-97% gas savings)
2. **Sequential IDs** enable ownership inference optimization
3. **Storage packing** reduces state updates dramatically
4. **Transfers** are slightly more expensive to maintain optimization
5. **Use ERC-721A** when users mint multiple tokens or you batch mint
6. **Avoid ERC-721A** for single-mint-only scenarios

## Security Considerations

1. **Start Token ID**: Ensure _startTokenId() is set correctly
2. **Max Supply**: Always enforce max supply checks
3. **Ownership Gaps**: Properly handle ownership chains on transfers
4. **Balance Tracking**: Never manually update balances
5. **Reentrancy**: Protect mint functions from reentrancy
6. **Integer Overflow**: Use Solidity 0.8+ for overflow protection

Ready to optimize your NFT gas costs? Let's build!
