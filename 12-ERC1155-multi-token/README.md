# Project 12: ERC-1155 Multi-Token Standard 🎮

> **Implement the multi-token standard supporting both fungible and non-fungible tokens in one contract**

## 🎯 Learning Objectives

- Understand the ERC-1155 multi-token standard
- Implement batch operations for gas efficiency
- Handle both fungible and non-fungible tokens in one contract
- Learn URI management for metadata
- Study gaming and metaverse use cases

## 📚 Background: Why ERC-1155?

ERC-1155 is a revolutionary standard that combines the best of ERC-20 and ERC-721:

### The Problem ERC-1155 Solves

**Before ERC-1155:**
- Gaming with 100 item types needed 100 separate ERC-721 contracts
- Managing currency + items required ERC-20 + ERC-721
- Each transfer = separate transaction = high gas costs

**With ERC-1155:**
- One contract holds ALL token types (fungible + non-fungible)
- Batch transfers: Send 100 different tokens in ONE transaction
- Dramatically lower gas costs and contract complexity

### Real-World Use Cases

**Gaming:**
```solidity
Token ID 1: Gold coins (fungible, 10000 supply)
Token ID 2: Health potions (fungible, 5000 supply)
Token ID 3: Legendary Sword #1 (non-fungible, unique)
Token ID 4: Legendary Sword #2 (non-fungible, unique)
```

**Metaverse:**
- Virtual land parcels (NFTs)
- In-world currency (fungible)
- Wearables and accessories (NFTs or semi-fungible)

**DeFi:**
- Multiple tranches of structured products
- Batch operations for portfolio management

## 🔧 Core Concepts

### Token IDs

```solidity
// Fungible tokens (many of same ID)
balanceOf[user][tokenId] = 1000;  // User has 1000 of token ID 5

// Non-fungible tokens (only one of this ID)
balanceOf[user][tokenId] = 1;     // User has unique token ID 999
```

### Batch Operations

```solidity
// Transfer multiple token types at once
safeBatchTransferFrom(
    from,
    to,
    [1, 2, 3],           // Token IDs
    [100, 50, 1],        // Amounts
    data
);
```

### Key Functions

| Function | Purpose |
|----------|---------|
| `balanceOf(account, id)` | Get balance of one token type |
| `balanceOfBatch(accounts[], ids[])` | Get multiple balances at once |
| `setApprovalForAll(operator, approved)` | Approve operator for ALL tokens |
| `isApprovedForAll(account, operator)` | Check if operator approved |
| `safeTransferFrom(from, to, id, amount, data)` | Transfer one token type |
| `safeBatchTransferFrom(from, to, ids[], amounts[], data)` | Transfer multiple types |
| `uri(id)` | Get metadata URI for token |

### Required Events

```solidity
event TransferSingle(address indexed operator, address indexed from, 
                    address indexed to, uint256 id, uint256 value);

event TransferBatch(address indexed operator, address indexed from,
                   address indexed to, uint256[] ids, uint256[] values);

event ApprovalForAll(address indexed account, address indexed operator, bool approved);

event URI(string value, uint256 indexed id);
```

## 📝 Tasks

### Task 1: Implement the Skeleton Contract

Open `src/ERC1155MultiToken.sol` and implement:

1. **Balance tracking** - Nested mapping for account → tokenId → balance
2. **Approval system** - Per-operator approvals (not per-token like ERC-721)
3. **Transfer functions** - Single and batch transfers
4. **Minting functions** - Create fungible and non-fungible tokens
5. **URI management** - Metadata for each token type

### Task 2: Study the Solution

Compare with `src/solution/ERC1155MultiTokenSolution.sol`:
- Understand nested mapping structure
- See batch operation gas savings
- Learn safe transfer callback pattern
- Study metadata URI patterns

### Task 3: Run Tests

```bash
cd 12-ERC1155-multi-token

# Run all tests
forge test -vvv

# Test batch operations
forge test --match-test test_Batch

# Gas comparison: single vs batch
forge test --gas-report

# Fuzz test different scenarios
forge test --match-test testFuzz
```

### Task 4: Deploy and Interact

```bash
# Start local node
anvil

# Deploy (in another terminal)
forge script script/Deploy.s.sol --broadcast --rpc-url http://localhost:8545

# Mint tokens
cast send <CONTRACT_ADDRESS> \
  "mint(address,uint256,uint256,bytes)" \
  <YOUR_ADDRESS> 1 1000 0x \
  --private-key <KEY>

# Batch transfer
cast send <CONTRACT_ADDRESS> \
  "safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)" \
  <FROM> <TO> "[1,2,3]" "[100,50,1]" 0x \
  --private-key <KEY>
```

## 🎮 Gaming Example

```solidity
// Setup game items
uint256 constant GOLD = 1;
uint256 constant HEALTH_POTION = 2;
uint256 constant MANA_POTION = 3;
uint256 constant LEGENDARY_SWORD = 1000;

// Player receives quest rewards in ONE transaction
_mintBatch(
    player,
    [GOLD, HEALTH_POTION, MANA_POTION],
    [500, 10, 5],
    ""
);

// Player trades items with another player
safeBatchTransferFrom(
    player1,
    player2,
    [GOLD, LEGENDARY_SWORD],
    [100, 1],
    ""
);
```

## 🧪 Test Coverage

The test suite covers:

- ✅ Single token transfers
- ✅ Batch token transfers  
- ✅ Approval system (all-or-nothing)
- ✅ Safe transfer callbacks (ERC1155Receiver)
- ✅ Balance queries (single and batch)
- ✅ Minting (single and batch)
- ✅ Burning tokens
- ✅ URI management
- ✅ Edge cases (zero amounts, empty arrays)
- ✅ Gas optimization comparisons

## ⚠️ Security Considerations

### 1. Batch Array Length Mismatch

```solidity
// MUST validate arrays are same length
require(ids.length == amounts.length, "Length mismatch");
```

### 2. Safe Transfer Callbacks

```solidity
// MUST call onERC1155Received / onERC1155BatchReceived
// Prevents tokens stuck in contracts
```

### 3. Reentrancy

```solidity
// Apply checks-effects-interactions
// Update balances BEFORE external calls
```

### 4. Integer Overflow

```solidity
// Solidity 0.8+ has built-in checks
// But be aware when handling large amounts
```

## 📊 Gas Comparison: ERC-721 vs ERC-1155

| Operation | ERC-721 (Separate) | ERC-1155 (Batch) | Savings |
|-----------|-------------------|------------------|---------|
| Transfer 1 NFT | ~50,000 gas | ~50,000 gas | 0% |
| Transfer 10 NFTs | ~500,000 gas | ~150,000 gas | 70% |
| Transfer 100 NFTs | ~5,000,000 gas | ~800,000 gas | 84% |

**Batch operations save dramatically on gas!**

## 🌍 Real-World Examples

### OpenSea (Seaport Protocol)

Uses ERC-1155 for efficient NFT marketplace operations.

### Enjin

Gaming platform built entirely on ERC-1155:
- In-game items
- Currencies
- Collectibles
- All in one contract per game

### Decentraland

Metaverse using ERC-1155 for:
- LAND parcels
- Wearables
- Names
- Emotes

## ✅ Completion Checklist

- [ ] Implemented all ERC-1155 functions
- [ ] All tests pass
- [ ] Understand batch operations
- [ ] Can explain fungible vs non-fungible handling
- [ ] Know safe transfer callback pattern
- [ ] Understand gas savings vs ERC-721
- [ ] Can design token ID scheme for game/project

## 💡 Pro Tips

1. **Token ID Scheme**: Plan your ID namespace
   - 0-999: Fungible currencies
   - 1000-9999: Consumable items
   - 10000+: Unique NFTs

2. **Metadata**: Use URI template with `{id}` placeholder
   - `https://api.example.com/metadata/{id}.json`
   - ERC-1155 standard supports this

3. **Supply Tracking**: Maintain `totalSupply(id)` if needed
   - Not required by standard
   - Useful for analytics

4. **Batch Operations**: Always use for multiple transfers
   - Massive gas savings
   - Better UX

5. **Approval Model**: All-or-nothing operator approval
   - Different from ERC-721 per-token approval
   - More efficient for gaming

## 🚀 Next Steps

After completing this project:

- **Build a game**: Implement items, currency, and characters
- **Study Enjin SDK**: Production gaming implementation
- **Explore semi-fungible tokens**: Limited editions
- **Integrate with marketplace**: OpenSea supports ERC-1155
- **Move to Project 13**: ERC-777 Advanced Tokens

## 📖 Further Reading

- [EIP-1155 Specification](https://eips.ethereum.org/EIPS/eip-1155)
- [OpenZeppelin ERC1155](https://docs.openzeppelin.com/contracts/4.x/erc1155)
- [Enjin Documentation](https://docs.enjin.io/)
- [ERC-1155 Design Rationale](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1155.md)

---

**Ready to build the future of gaming and metaverse assets!** 🎮🚀
