# Project 09: ERC721 NFT from Scratch 🖼️

> **Implement the NFT standard and understand digital ownership**

## 🎯 Learning Objectives

- Implement ERC721 interface from scratch
- Handle token metadata and URIs
- Implement safe transfer callbacks
- Understand mint race conditions and front-running
- Integrate IPFS metadata

## 📚 Key Concepts

### ERC721 Core Functions

```solidity
balanceOf(address owner) → uint256
ownerOf(uint256 tokenId) → address
safeTransferFrom(address from, address to, uint256 tokenId)
transferFrom(address from, address to, uint256 tokenId)
approve(address to, uint256 tokenId)
setApprovalForAll(address operator, bool approved)
getApproved(uint256 tokenId) → address
isApprovedForAll(address owner, address operator) → bool
```

### Safe Transfer vs Transfer

`safeTransferFrom` checks if recipient can receive NFTs:
- Prevents tokens stuck in contracts
- Calls `onERC721Received` on recipient if contract
- Reverts if recipient doesn't implement interface

## 📝 Tasks

```bash
cd 09-ERC721-NFT-from-scratch
forge test -vvv
```

## ✅ Status

✅ **Complete** - Create your own NFTs!

## 🚀 Next Steps

- Move to [Project 10: Upgradeability & Proxies](../10-upgradeability-and-proxies/)
- Study OpenZeppelin ERC721
- Add metadata extension
- Implement royalties (ERC2981)
