# Quick Start Guide - ERC-721A Optimized

Get started with ERC-721A gas optimization in 5 minutes!

## What You'll Learn

By completing this project, you'll understand:
- How ERC-721A saves 77-97% gas on batch mints
- Ownership inference and backward scanning
- Storage packing techniques
- When to use ERC-721A vs standard ERC-721

## Step 1: Understand the Problem (2 min)

Standard ERC-721 minting is expensive:
```solidity
// Minting 5 tokens costs ~750,000 gas
for (uint i = 0; i < 5; i++) {
    _owners[tokenId + i] = msg.sender;  // Each SSTORE costs ~22k gas
}
// Total: 5 × 150,000 = 750,000 gas
```

ERC-721A solution:
```solidity
// Minting 5 tokens costs ~175,000 gas
_ownerships[startTokenId] = TokenOwnership({
    addr: msg.sender,
    startTimestamp: block.timestamp,
    burned: false
});
// Total: 175,000 gas (77% savings!)
// Tokens 1-4 infer ownership from token 0
```

## Step 2: Explore the Skeleton (5 min)

Open `src/Project25.sol` and read through:

1. **Structs** (lines 20-60):
   - `TokenOwnership`: Packed into one storage slot
   - `AddressData`: Efficient balance tracking

2. **Storage Layout** (lines 65-95):
   - `_ownerships`: Only stores batch starts
   - `_currentIndex`: Tracks next token to mint

3. **Key Functions**:
   - `ownerOf()`: Scans backwards to find owner
   - `_mint()`: Only writes once per batch
   - `_transfer()`: Maintains ownership chain

## Step 3: Implement Core Functions (30 min)

### Task 1: Define TokenOwnership Struct
```solidity
struct TokenOwnership {
    address addr;           // 160 bits
    uint64 startTimestamp;  // 64 bits
    bool burned;            // 8 bits
    // Perfectly packed into 256 bits!
}
```

### Task 2: Implement ownerOf with Backward Scanning
```solidity
function ownerOf(uint256 tokenId) public view returns (address) {
    if (!_exists(tokenId)) revert TokenDoesNotExist();

    // Scan backwards until we find ownership
    for (uint256 curr = tokenId; ; curr--) {
        TokenOwnership memory ownership = _ownerships[curr];
        if (ownership.addr != address(0)) {
            return ownership.addr;
        }
    }
}
```

### Task 3: Implement Batch Minting
```solidity
function _mint(address to, uint256 quantity) internal {
    uint256 startTokenId = _currentIndex;

    // Update balance (once for all tokens!)
    _addressData[to].balance += uint64(quantity);

    // Set ownership only for first token
    _ownerships[startTokenId] = TokenOwnership({
        addr: to,
        startTimestamp: uint64(block.timestamp),
        burned: false
    });

    // Emit events for each token
    for (uint256 i = 0; i < quantity; i++) {
        emit Transfer(address(0), to, startTokenId + i);
    }

    _currentIndex += quantity;
}
```

## Step 4: Run Tests & Compare Gas (10 min)

```bash
# Run all tests
forge test --match-path test/Project25.t.sol -vv

# Run gas benchmarks
forge test --match-test testGas -vvv

# Generate gas report
forge test --gas-report
```

Expected output:
```
[PASS] test_GasMintSingle()
  Gas for minting 1 token: 160,487
  Gas per token: 160,487

[PASS] test_GasMintBatch5()
  Gas for minting 5 tokens: 175,891
  Gas per token: 35,178

  SAVINGS: 125,309 gas per token (78% reduction!)
```

## Step 5: Understand the Trade-offs (5 min)

### When to Use ERC-721A

✅ **Perfect for:**
- Public mints (users buy 2+ NFTs)
- Batch airdrops
- Large collections (1000+ items)
- Sequential token IDs

❌ **Not ideal for:**
- Single-mint-only collections
- Custom/non-sequential token IDs
- Sparse collections with gaps

### Gas Comparison Summary

| Scenario | Standard ERC-721 | ERC-721A | Your Savings |
|----------|------------------|----------|--------------|
| Mint 1   | ~150,000        | ~160,000 | -10,000 (-6.7%) |
| Mint 5   | ~750,000        | ~175,000 | ~575,000 (77%) |
| Mint 10  | ~1,500,000      | ~190,000 | ~1,310,000 (87%) |
| Transfer | ~50,000         | ~80,000  | -30,000 (-60%) |

**Key Insight**: Transfers are more expensive, but minting saves so much that it's worth it!

## Step 6: Deploy & Test (5 min)

```bash
# Start local blockchain
anvil

# Deploy (in new terminal)
forge script script/DeployProject25.s.sol:DeployProject25 \
  --rpc-url http://localhost:8545 \
  --broadcast

# Interact with contract
cast send <CONTRACT_ADDRESS> "mint(uint256)" 5 \
  --value 0.05ether \
  --rpc-url http://localhost:8545 \
  --private-key <YOUR_PRIVATE_KEY>
```

## Key Concepts to Master

### 1. Ownership Inference
```
Mint tokens 0-4 to Alice:

Storage:
[0]: {addr: alice, timestamp: 123, burned: false}
[1]: {empty} ← not stored!
[2]: {empty}
[3]: {empty}
[4]: {empty}

ownerOf(3) scans: 3→2→1→0, finds alice!
```

### 2. Storage Packing
```
// Before (standard ERC-721): 3 storage slots
address owner;           // Slot 1 (256 bits)
uint256 timestamp;       // Slot 2 (256 bits)
bool burned;             // Slot 3 (256 bits)
Total: 3 SSTORE = ~66,000 gas

// After (ERC-721A): 1 storage slot
struct TokenOwnership {
    address addr;        // 160 bits
    uint64 timestamp;    // 64 bits
    bool burned;         // 8 bits
}                        // 232 bits total
Total: 1 SSTORE = ~22,000 gas

Savings: 44,000 gas per token!
```

### 3. Transfer Complexity
```
Before transfer: Tokens 0-4 owned by Alice
_ownerships[0] = {addr: alice, ...}
_ownerships[1-4] = {empty}

Transfer token 2 to Bob:
_ownerships[2] = {addr: bob, ...}    // New owner
_ownerships[3] = {addr: alice, ...}  // Fix chain!

Why? Without step 2:
ownerOf(3) would scan: 3→2, find Bob (wrong!)

With step 2:
ownerOf(3) scans: 3, finds Alice (correct!)
```

## Common Mistakes to Avoid

### ❌ Mistake 1: Forgetting to Update Next Token on Transfer
```solidity
function _transfer(address from, address to, uint256 tokenId) {
    _ownerships[tokenId] = TokenOwnership(to, ...);
    // Missing: Update _ownerships[tokenId + 1]!
}
```

### ❌ Mistake 2: Storing Ownership for Every Token
```solidity
function _mint(address to, uint256 quantity) {
    for (uint i = 0; i < quantity; i++) {
        _ownerships[startTokenId + i] = TokenOwnership(to, ...);
        // Wrong! Only store first token.
    }
}
```

### ❌ Mistake 3: Not Checking Token Exists
```solidity
function ownerOf(uint256 tokenId) public view returns (address) {
    // Missing: if (!_exists(tokenId)) revert;
    return _ownerships[tokenId].addr;  // Could be empty!
}
```

## Next Steps

1. Complete the skeleton implementation in `src/Project25.sol`
2. Run tests to verify correctness
3. Compare with the solution in `src/solution/Project25Solution.sol`
4. Read `GAS_ANALYSIS.md` for deep dive into optimizations
5. Experiment with different batch sizes
6. Try deploying on testnet

## Resources

- Main README: `README.md`
- Gas Analysis: `GAS_ANALYSIS.md`
- Skeleton Code: `src/Project25.sol`
- Complete Solution: `src/solution/Project25Solution.sol`
- Tests: `test/Project25.t.sol`

## Real-World Impact

Azuki used ERC-721A for their 10,000 NFT drop:
- Users minted ~3-5 NFTs on average
- Saved the community over **$2 million in gas fees**
- Made NFTs more accessible to regular users

At $2,000 ETH and 50 gwei:
- Standard ERC-721 (5 NFTs): ~$75 in gas
- ERC-721A (5 NFTs): ~$17.50 in gas
- **User saves: $57.50 per mint!**

## Challenge: Can You Beat These Numbers?

Try to implement optimizations that:
1. Reduce single mint gas below 155,000
2. Reduce batch 5 gas below 170,000
3. Reduce transfer gas below 75,000

Hint: Consider:
- More efficient packing
- Assembly optimizations
- Smarter ownership inference

Ready? Open `src/Project25.sol` and start coding!
