# Project 09: ERC721 NFT from Scratch 🖼️

> **Implement the NFT standard and understand digital ownership**

## 🎯 Learning Objectives

By completing this project, you will:

1. **Understand the ERC721 standard** and its required functions
2. **Implement ERC721 from scratch** without libraries
3. **Handle token metadata** and URIs
4. **Implement safe transfer callbacks** to prevent stuck NFTs
5. **Understand approval mechanisms** (single token vs operator)
6. **Recognize mint race conditions** and front-running risks
7. **Integrate IPFS metadata** for decentralized storage
8. **Create Foundry deployment scripts** for NFT contracts
9. **Write comprehensive test suites** for NFT functionality

## 📁 Project Directory Structure

```
09-ERC721-NFT-from-scratch/
├── README.md                          # This file
├── foundry.toml                       # Foundry configuration
├── src/
│   ├── ERC721NFT.sol                 # Skeleton contract (TODO: implement)
│   └── solution/
│       └── ERC721NFTSolution.sol     # Complete reference implementation
├── script/
│   ├── DeployERC721NFT.s.sol         # Deployment script (TODO: implement)
│   └── solution/
│       └── DeployERC721NFTSolution.s.sol  # Reference deployment
└── test/
    ├── ERC721NFT.t.sol                # Test suite (TODO: implement)
    └── solution/
        └── ERC721NFTSolution.t.sol    # Reference tests
```

## 🔑 Key Concepts

### ERC721 Standard Overview: Non-Fungible Tokens

**FIRST PRINCIPLES: Uniqueness and Ownership**

ERC721 is the standard for non-fungible tokens (NFTs) - unique, indivisible tokens. Unlike ERC20 (fungible), each ERC721 token is unique and has its own tokenId.

**CONNECTION TO PROJECT 08**:
- **Project 08**: ERC20 - fungible tokens (all identical)
- **Project 09**: ERC721 - non-fungible tokens (each unique)
- Both use similar patterns (mappings, events, approvals) but with key differences!

**KEY DIFFERENCES FROM ERC20**:

| Aspect | ERC20 | ERC721 |
|--------|-------|--------|
| **Fungibility** | Fungible (all identical) | Non-fungible (each unique) |
| **Transfer** | By amount (`transfer(to, amount)`) | By tokenId (`transferFrom(from, to, tokenId)`) |
| **Balance** | Total amount held | Count of NFTs owned |
| **Storage** | `mapping(address => uint256)` | `mapping(uint256 => address)` |
| **Approval** | Amount-based (`approve(spender, amount)`) | Token-based (`approve(spender, tokenId)`) |

**STORAGE STRUCTURE** (from Project 01 knowledge):

**ERC20**:
```solidity
mapping(address => uint256) public balanceOf;  // How many tokens?
```

**ERC721**:
```solidity
mapping(uint256 => address) public ownerOf;      // Who owns tokenId?
mapping(address => uint256) public balanceOf;    // How many NFTs?
```

**UNDERSTANDING THE DIFFERENCE**:

**ERC20 Transfer**:
```solidity
transfer(to, 100);  // Transfer 100 tokens
// All 100 tokens are identical
```

**ERC721 Transfer**:
```solidity
transferFrom(from, to, 5);  // Transfer tokenId #5
// Token #5 is unique - can't transfer "100 NFTs" like ERC20
```

**GAS COST COMPARISON** (from Project 01 & 08 knowledge):

**ERC20 Transfer**:
- 2 SLOADs (balances): ~200 gas
- 2 SSTOREs (balances): ~10,000 gas
- Event: ~1,500 gas
- Total: ~11,700 gas

**ERC721 Transfer**:
- 2 SLOADs (ownerOf + balanceOf): ~200 gas
- 2 SSTOREs (ownerOf + balanceOf): ~10,000 gas
- Event: ~1,500 gas
- Total: ~11,700 gas (similar!)

**REAL-WORLD ANALOGY**: 
Like trading cards vs currency:
- **ERC20** = Dollar bills (all identical, transfer by amount)
- **ERC721** = Trading cards (each unique, transfer by card number)

**COMPARISON TO RUST** (DSA Concept):

**Rust** (HashMap for ownership):
```rust
use std::collections::HashMap;

struct NFT {
    owner_of: HashMap<TokenId, Address>,
    balance_of: HashMap<Address, u256>,
}
```

**Solidity** (mappings):
```solidity
mapping(uint256 => address) public ownerOf;
mapping(address => uint256) public balanceOf;
```

Both use hash-based structures for O(1) lookups, but Solidity's mappings are more gas-efficient!

### Core Functions

```solidity
balanceOf(address owner) → uint256              // Number of NFTs owned
ownerOf(uint256 tokenId) → address              // Owner of specific NFT
transferFrom(address from, address to, uint256 tokenId)  // Transfer NFT
safeTransferFrom(...)                           // Safe transfer with callback
approve(address to, uint256 tokenId)            // Approve single token
setApprovalForAll(address operator, bool)        // Approve all tokens
getApproved(uint256 tokenId) → address          // Get approved address
isApprovedForAll(address owner, address operator) → bool  // Check operator approval
```

### Safe Transfer vs Regular Transfer

**Regular Transfer:**
```solidity
function transferFrom(address from, address to, uint256 tokenId) public {
    // Transfers NFT without checking if recipient can handle it
}
```

**Safe Transfer:**
```solidity
function safeTransferFrom(...) public {
    transferFrom(from, to, tokenId);
    // Checks if recipient is contract
    // Calls onERC721Received callback
    // Reverts if recipient can't handle NFTs
}
```

**Why Safe Transfer Matters:**
- Prevents NFTs stuck in contracts that can't handle them
- Ensures recipient implements `IERC721Receiver`
- Standard practice for NFT transfers

### Token Metadata & URIs

NFTs store metadata off-chain (usually IPFS) and reference it via URI:

```solidity
mapping(uint256 => string) public tokenURI;

function mint(address to, string memory uri) public {
    uint256 tokenId = _tokenIdCounter++;
    tokenURI[tokenId] = uri;  // Points to IPFS/metadata
    // ...
}
```

**Real-world analogy**: Like a certificate of ownership - the NFT is the certificate, the URI points to the actual artwork/metadata stored elsewhere!

### Approval Mechanisms

ERC721 has TWO types of approvals:

1. **Single Token Approval**: `approve(to, tokenId)`
   - Approves specific token
   - Stored in `getApproved[tokenId]`

2. **Operator Approval**: `setApprovalForAll(operator, true)`
   - Approves ALL tokens owned
   - Stored in `isApprovedForAll[owner][operator]`

**Use cases:**
- Single approval: Approve marketplace for one NFT
- Operator approval: Approve marketplace for all NFTs

## 🏗️ What You'll Build

A complete ERC721 NFT implementation that includes:

1. **Token ownership tracking** (tokenId → owner)
2. **Balance tracking** (address → count)
3. **Transfer functionality** (regular and safe)
4. **Approval system** (single token and operator)
5. **Metadata URIs** (IPFS integration)
6. **Minting functionality** (create new NFTs)

## 📋 Tasks

### 1. Implement Constructor
- Set token name and symbol
- Initialize token counter

### 2. Implement `mint(address to, string memory uri)`
- Validate recipient
- Increment token counter
- Set owner and balance
- Store token URI
- Emit Transfer event (from address(0))

### 3. Implement `transferFrom(address from, address to, uint256 tokenId)`
- Validate ownership and authorization
- Update balances and ownership
- Clear single token approval
- Emit Transfer event

### 4. Implement `safeTransferFrom(...)`
- Call regular transferFrom
- Check if recipient is contract
- Call `onERC721Received` callback
- Verify callback return value

### 5. Implement `approve(address to, uint256 tokenId)`
- Validate authorization (owner or operator)
- Set single token approval
- Emit Approval event

### 6. Implement `setApprovalForAll(address operator, bool approved)`
- Set operator approval for all tokens
- Emit ApprovalForAll event

### 7. Write Deployment Script
- Deploy NFT contract
- Mint initial NFTs
- Log deployment and minting

### 8. Write Comprehensive Tests
- Test minting functionality
- Test transfers (regular and safe)
- Test approvals (single and operator)
- Test edge cases (zero address, invalid tokenId)
- Test safe transfer callbacks

## 🧪 Test Coverage

Your tests should verify:

- ✅ Minting creates NFTs correctly
- ✅ Transfer works correctly
- ✅ Safe transfer checks callbacks
- ✅ Single token approval works
- ✅ Operator approval works
- ✅ Authorization checks work correctly
- ✅ Events are emitted correctly
- ✅ Edge cases handled (zero address, invalid tokenId)

## 🎓 Real-World Analogies & Fun Facts

### Trading Cards Analogy
- **ERC721** = Trading cards (each unique)
- **ERC20** = Currency (all identical)
- **TokenId** = Card number
- **Metadata URI** = Card image/details

### Certificate of Ownership
- **NFT** = Certificate proving ownership
- **URI** = Link to actual artwork/metadata
- **Transfer** = Transferring ownership certificate

### Fun Facts
- ERC721 was proposed in 2018 by William Entriken
- CryptoPunks predate ERC721 (they're ERC20-like)
- Most NFTs store metadata on IPFS (decentralized)
- Safe transfer prevents NFTs stuck in contracts
- OpenSea uses operator approvals for gas efficiency

## ✅ Completion Checklist

- [ ] Implement constructor
- [ ] Implement mint function
- [ ] Implement transferFrom function
- [ ] Implement safeTransferFrom function
- [ ] Implement approve function
- [ ] Implement setApprovalForAll function
- [ ] Implement helper functions (_isApprovedOrOwner)
- [ ] Write deployment script
- [ ] Write comprehensive test suite
- [ ] Test safe transfer callbacks
- [ ] Review solution implementation

## 💡 Pro Tips

1. **Always use safeTransferFrom**: Prevents NFTs stuck in contracts
2. **Clear single approvals**: Delete getApproved after transfer
3. **Check authorization**: Use helper function for clarity
4. **Store metadata off-chain**: Use IPFS for decentralized storage
5. **Emit events correctly**: Required by ERC721 standard
6. **Handle callbacks**: Verify onERC721Received return value
7. **Understand operator approvals**: More gas-efficient for marketplaces

## 🚀 Next Steps

After completing this project:

- Move to [Project 10: Upgradeability & Proxies](../10-upgradeability-and-proxies/)
- Study OpenZeppelin ERC721 implementation
- Add metadata extension (ERC721Metadata)
- Implement royalties (ERC2981)
- Learn about ERC721A (gas-optimized version)
