# Project 26: ERC-1155 Multi-Token Standard

## Overview

The ERC-1155 Multi-Token Standard is a revolutionary token standard that allows a single contract to manage multiple token types, both fungible and non-fungible. This project teaches you how to implement and work with ERC-1155 tokens, which are particularly popular in gaming and multi-asset systems.

## What is ERC-1155? The Multi-Token Standard

**FIRST PRINCIPLES: Unified Token Interface**

ERC-1155 is a token standard that supports multiple token types in a single contract. It combines the best of ERC20 and ERC721!

**CONNECTION TO PROJECTS 08 & 09**:
- **Project 08**: ERC20 - fungible tokens (all identical)
- **Project 09**: ERC721 - non-fungible tokens (each unique)
- **Project 26**: ERC1155 - both in one contract!

ERC-1155 is a token standard that supports:
- **Fungible tokens** (like ERC-20): Interchangeable tokens of the same type
  - Example: Gold coins, silver coins (many units, all identical)
  
- **Non-fungible tokens** (like ERC-721): Unique tokens with individual identities
  - Example: Unique sword, unique armor (one unit, unique properties)
  
- **Semi-fungible tokens**: Tokens that start fungible but become unique
  - Example: Ticket that becomes unique after event (fungible → NFT)

All of these can exist in a single smart contract, making it extremely versatile and gas-efficient!

**UNDERSTANDING THE UNIFIED MODEL**:

```
ERC-1155 Unified Model:
┌─────────────────────────────────────────┐
│ Single Contract                         │
│   ↓                                      │
│ Token ID 0: Gold (fungible)            │ ← Like ERC20
│   - balanceOf(user, 0) = 1000           │ ← Can have many
│   ↓                                      │
│ Token ID 1: Silver (fungible)           │ ← Like ERC20
│   - balanceOf(user, 1) = 500            │ ← Can have many
│   ↓                                      │
│ Token ID 1000: Unique Sword (NFT)       │ ← Like ERC721
│   - balanceOf(user, 1000) = 1           │ ← Only one exists
│   ↓                                      │
│ Token ID 1001: Unique Armor (NFT)      │ ← Like ERC721
│   - balanceOf(user, 1001) = 1           │ ← Only one exists
└─────────────────────────────────────────┘
```

**STORAGE STRUCTURE** (from Project 01 knowledge):

**ERC20** (Project 08):
```solidity
mapping(address => uint256) public balanceOf;  // One mapping per contract
```

**ERC721** (Project 09):
```solidity
mapping(uint256 => address) public ownerOf;    // One mapping per contract
mapping(address => uint256) public balanceOf;
```

**ERC1155** (Project 26):
```solidity
mapping(uint256 => mapping(address => uint256)) public balanceOf;
// Nested mapping: tokenId → owner → balance
// One contract, multiple token types!
```

**GAS EFFICIENCY** (from Project 01 & 06 knowledge):

**Deploying Multiple Token Types**:

**Separate Contracts** (ERC20 + ERC721):
- Deploy ERC20: ~200,000 gas
- Deploy ERC721: ~200,000 gas
- Total: ~400,000 gas

**Single ERC1155 Contract**:
- Deploy ERC1155: ~200,000 gas
- Total: ~200,000 gas
- **Savings**: 50% reduction!

**REAL-WORLD ANALOGY**: 
Like a video game inventory:
- **ERC20**: Separate contracts for gold, silver, etc. (inefficient)
- **ERC721**: Separate contracts for each unique item (very inefficient)
- **ERC1155**: One inventory contract for everything (efficient!)

## Key Advantages of ERC-1155

### 1. Gas Efficiency
- **Batch Operations**: Transfer multiple token types in a single transaction
- **Reduced Contract Deployments**: One contract for all token types vs. multiple ERC-20/721 contracts
- **Optimized Storage**: More efficient than deploying separate contracts

### 2. Simplified Management
- One contract manages hundreds or thousands of token types
- Unified interface for all token operations
- Single approval for all token types (operator approval)

### 3. Atomic Swaps
- Trade multiple assets in a single transaction
- No need for complex multi-step exchanges
- Reduced risk of failed partial trades

## Core Concepts

### Token IDs and Fungibility

```solidity
// Fungible tokens (like currencies)
uint256 constant GOLD = 0;      // Many units, all identical
uint256 constant SILVER = 1;    // Many units, all identical

// Non-fungible tokens (like unique items)
uint256 constant SWORD_1 = 1000;  // Unique item
uint256 constant SWORD_2 = 1001;  // Different unique item

// Convention: Check balance
// If balance can be > 1, it's fungible
// If balance is always 0 or 1, it's non-fungible
```

**How to distinguish:**
- **Fungible**: Multiple users can own the same token ID with different amounts
- **Non-fungible**: Only one user owns each token ID, and the amount is always 1

### Balance Model

Unlike ERC-721, ERC-1155 uses a nested mapping:

```solidity
// ERC-1155: mapping(tokenId => mapping(owner => balance))
mapping(uint256 => mapping(address => uint256)) private _balances;

// This allows:
// - Multiple people to own token ID 0 (fungible)
// - Only one person to own token ID 1000 (NFT)
```

### Batch Operations

One of the most powerful features:

```solidity
// Transfer multiple token types at once
function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
) public;

// Example: Transfer gold, silver, and a sword in one transaction
ids = [0, 1, 1000];
amounts = [100, 50, 1];
```

**Benefits:**
- Save gas on multiple transfers
- Atomic execution (all succeed or all fail)
- Useful for trading, crafting, or bulk distributions

### Operator Approval

ERC-1155 uses operator approval instead of per-token approval:

```solidity
// One approval for ALL token types
function setApprovalForAll(address operator, bool approved) public;

// The operator can then transfer ANY token ID on your behalf
```

**Key differences from ERC-721:**
- ERC-721: Approve specific token ID
- ERC-1155: Approve all token IDs at once
- More convenient but requires more trust in operators

### Safe Transfer Callbacks

All transfers must be "safe" - they call a hook on the recipient:

```solidity
interface IERC1155Receiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}
```

**Purpose:**
- Prevent tokens from being locked in contracts that can't handle them
- Allow recipient contracts to execute logic on receipt
- Reentrancy protection required!

### URI Management

ERC-1155 uses a single URI template for all tokens:

```solidity
// Template with {id} placeholder
string private _uri = "https://game.com/api/item/{id}.json";

// For token ID 42, becomes:
// "https://game.com/api/item/42.json"
```

**Alternative approaches:**
- Per-token URI overrides
- On-chain metadata generation
- IPFS base URI with token-specific hashes

## ERC-1155 vs ERC-20 + ERC-721

### Gas Comparison

| Operation | ERC-20 + ERC-721 | ERC-1155 | Savings |
|-----------|------------------|----------|---------|
| Deploy 10 token types | ~15M gas | ~1.5M gas | **90%** |
| Transfer 5 different tokens | ~250k gas | ~120k gas | **52%** |
| Approve all types | 5 txs * 46k | 1 tx * 46k | **80%** |

### Feature Comparison

| Feature | ERC-20 | ERC-721 | ERC-1155 |
|---------|--------|---------|----------|
| Fungible tokens | ✅ | ❌ | ✅ |
| Non-fungible tokens | ❌ | ✅ | ✅ |
| Batch transfers | ❌ | ❌ | ✅ |
| Multiple types/contract | ❌ | ❌ | ✅ |
| Per-token approval | N/A | ✅ | ❌ |
| Operator approval | ✅ | ✅ | ✅ |

## Use Cases

### 1. Gaming (Most Common)

```solidity
// Currencies (fungible)
uint256 constant GOLD = 0;
uint256 constant GEMS = 1;

// Consumables (fungible)
uint256 constant HEALTH_POTION = 100;
uint256 constant MANA_POTION = 101;

// Equipment (non-fungible)
uint256 constant LEGENDARY_SWORD_1 = 10000;
uint256 constant LEGENDARY_SWORD_2 = 10001;

// Resources (fungible)
uint256 constant WOOD = 200;
uint256 constant IRON = 201;
```

### 2. Digital Art Collections

- Edition prints (fungible): 100 copies of the same artwork
- Unique pieces (non-fungible): 1/1 artworks
- Unlockable content tied to ownership

### 3. Real Estate Tokenization

- Fungible shares of a property
- Unique property deeds
- Rental income tokens

### 4. Supply Chain

- Fungible commodity units
- Non-fungible tracking IDs for unique items
- Certificates of authenticity

### 5. DeFi Positions

- Liquidity pool shares (fungible)
- Unique loan positions (non-fungible)
- Reward tokens

## Common Patterns and Best Practices

### 1. Token ID Organization

```solidity
// Use ranges to organize token types
uint256 constant CURRENCY_RANGE = 0;        // 0-999
uint256 constant CONSUMABLE_RANGE = 1000;   // 1000-1999
uint256 constant EQUIPMENT_RANGE = 10000;   // 10000-99999

// Helper functions
function isCurrency(uint256 tokenId) internal pure returns (bool) {
    return tokenId < 1000;
}

function isEquipment(uint256 tokenId) internal pure returns (bool) {
    return tokenId >= 10000 && tokenId < 100000;
}
```

### 2. Supply Tracking

```solidity
// Track total supply per token ID
mapping(uint256 => uint256) private _totalSupply;

// For NFTs, limit to 1
function mintNFT(address to, uint256 tokenId) public {
    require(_totalSupply[tokenId] == 0, "NFT already exists");
    _totalSupply[tokenId] = 1;
    _mint(to, tokenId, 1, "");
}

// For fungible, track aggregate
function mintFungible(address to, uint256 tokenId, uint256 amount) public {
    _totalSupply[tokenId] += amount;
    _mint(to, tokenId, amount, "");
}
```

### 3. Role-Based Minting

```solidity
// Different roles for different token types
bytes32 public constant CURRENCY_MINTER = keccak256("CURRENCY_MINTER");
bytes32 public constant ITEM_MINTER = keccak256("ITEM_MINTER");

function mintCurrency(address to, uint256 id, uint256 amount) public {
    require(hasRole(CURRENCY_MINTER, msg.sender), "Not authorized");
    require(id < 1000, "Not a currency");
    _mint(to, id, amount, "");
}
```

### 4. Reentrancy Protection

```solidity
// ALWAYS use reentrancy guard with safe transfers
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MyERC1155 is ERC1155, ReentrancyGuard {
    function safeTransferFrom(...) public override nonReentrant {
        super.safeTransferFrom(...);
    }
}
```

### 5. URI Management

```solidity
// Option 1: Template URI (most common)
constructor() ERC1155("https://game.com/api/item/{id}.json") {}

// Option 2: Per-token URI
mapping(uint256 => string) private _tokenURIs;

function uri(uint256 tokenId) public view override returns (string memory) {
    string memory tokenURI = _tokenURIs[tokenId];
    if (bytes(tokenURI).length > 0) {
        return tokenURI;
    }
    return super.uri(tokenId);
}

// Option 3: On-chain metadata
function uri(uint256 tokenId) public view override returns (string memory) {
    return string(abi.encodePacked(
        'data:application/json;base64,',
        Base64.encode(bytes(generateMetadata(tokenId)))
    ));
}
```

## Security Considerations

### 1. Reentrancy in Callbacks

The safe transfer callbacks can lead to reentrancy:

```solidity
// Malicious receiver
contract Attacker is IERC1155Receiver {
    function onERC1155Received(...) external returns (bytes4) {
        // Reenter the token contract!
        token.safeTransferFrom(victim, attacker, id, amount, "");
        return this.onERC1155Received.selector;
    }
}
```

**Protection:**
- Use `ReentrancyGuard` from OpenZeppelin
- Follow checks-effects-interactions pattern
- Update balances before calling hooks

### 2. Operator Approval Trust

Operators have full control over all token types:

```solidity
// If you approve a malicious operator...
token.setApprovalForAll(maliciousOperator, true);

// They can drain ALL your tokens of ALL types!
token.safeBatchTransferFrom(you, attacker, allIds, allAmounts, "");
```

**Best practices:**
- Only approve trusted contracts
- Provide clear UI warnings
- Consider time-limited approvals
- Implement revokable approvals

### 3. Balance Overflow

Unlike ERC-721, balances can overflow:

```solidity
// In Solidity < 0.8.0, this could overflow
balances[id][to] += amount;
```

**Protection:**
- Use Solidity ^0.8.0 (automatic overflow checks)
- Or use SafeMath library

### 4. URI Validation

Malicious URIs could be used for phishing:

```solidity
// Bad: Allowing arbitrary URIs
function setURI(string memory newuri) public {
    _setURI(newuri);
}

// Better: Validate URI format
function setURI(string memory newuri) public onlyOwner {
    require(bytes(newuri).length > 0, "Empty URI");
    require(validateURI(newuri), "Invalid URI format");
    _setURI(newuri);
}
```

## Testing Strategy

### Essential Tests

1. **Basic Operations**
   - Mint fungible tokens
   - Mint non-fungible tokens
   - Single transfers
   - Balance queries

2. **Batch Operations**
   - Batch minting
   - Batch transfers
   - Mixed fungible/NFT batches

3. **Approvals**
   - Operator approval
   - Operator transfers
   - Approval revocation

4. **Safe Transfer Callbacks**
   - Transfer to EOA (should succeed)
   - Transfer to contract with receiver (should succeed)
   - Transfer to contract without receiver (should fail)
   - Reentrancy protection

5. **Edge Cases**
   - Zero amount transfers
   - Self-transfers
   - Transfer to zero address
   - Insufficient balance
   - Unauthorized transfers

6. **Gas Optimization**
   - Compare batch vs individual transfers
   - Compare with ERC-20 + ERC-721
   - Measure deployment costs

## Project Structure

```
26-erc1155-multi/
├── src/
│   ├── Project26.sol              # Skeleton for students
│   └── solution/
│       └── Project26Solution.sol  # Complete implementation
├── test/
│   └── Project26.t.sol            # Comprehensive tests
├── script/
│   └── DeployProject26.s.sol      # Deployment script
└── README.md                       # This file
```

## Learning Objectives

By completing this project, you will:

1. ✅ Understand ERC-1155 standard and its advantages
2. ✅ Implement both fungible and non-fungible tokens in one contract
3. ✅ Master batch operations for gas efficiency
4. ✅ Handle operator approvals correctly
5. ✅ Implement safe transfer callbacks
6. ✅ Protect against reentrancy attacks
7. ✅ Design token ID schemes for different use cases
8. ✅ Compare gas costs with ERC-20/721
9. ✅ Build a complete gaming item system

## Tasks

### Part 1: Basic Implementation (Skeleton)

1. Implement ERC1155 base functionality
2. Add token minting functions
3. Implement URI management
4. Add access control

### Part 2: Advanced Features (Solution)

1. Implement batch operations efficiently
2. Add safe transfer callback handling
3. Implement reentrancy protection
4. Create gaming item system example

### Part 3: Testing

1. Write tests for all operations
2. Test reentrancy protection
3. Compare gas costs
4. Test edge cases

## Resources

- [EIP-1155 Specification](https://eips.ethereum.org/EIPS/eip-1155)
- [OpenZeppelin ERC1155](https://docs.openzeppelin.com/contracts/4.x/erc1155)
- [ERC-1155 vs ERC-721](https://ethereum.org/en/developers/docs/standards/tokens/erc-1155/)
- [Enjin's ERC-1155 Guide](https://github.com/enjin/erc-1155)

## Common Pitfalls

1. ❌ Not implementing reentrancy guards
2. ❌ Confusing fungible and non-fungible token handling
3. ❌ Forgetting to check receiver interface support
4. ❌ Not validating array lengths in batch operations
5. ❌ Allowing operator approval without user awareness
6. ❌ Poor URI management for metadata
7. ❌ Not tracking total supply correctly

## Next Steps

After completing this project:
- Explore ERC-1155 extensions (supply tracking, burnable, etc.)
- Build a complete NFT game using ERC-1155
- Integrate with marketplaces that support ERC-1155
- Implement meta-transactions for gasless transfers
- Study advanced patterns like semi-fungible tokens

## Getting Started

1. Read through the skeleton contract (`src/Project26.sol`)
2. Complete the TODOs in order
3. Run tests: `forge test --match-path test/Project26.t.sol`
4. Compare with solution when stuck
5. Deploy locally: `forge script script/DeployProject26.s.sol`

Happy coding! 🎮
