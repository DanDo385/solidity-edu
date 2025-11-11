# Project 09: ERC721 NFT from Scratch 🖼️

> **Implement the NFT standard and understand digital ownership**

## 🎯 Learning Objectives

- Implement ERC721 interface from scratch
- Handle token metadata and URIs
- Implement safe transfer callbacks
- Understand mint race conditions
- Integrate IPFS metadata

## 📚 Key Concepts

### ERC721 Standard

Non-fungible tokens (NFTs):
- Each token is unique (tokenId)
- Ownership tracking per token
- Approval model (approve vs approveAll)
- Metadata URIs (IPFS, on-chain, etc.)

### Safe Transfers

`safeTransferFrom` vs `transferFrom`:
- Safe version calls recipient contract
- Prevents tokens stuck in contracts
- Implements ERC721Receiver interface

### Common Patterns

- Enumerable extension
- Metadata extension
- Royalties (ERC2981)
- Soul-bound tokens

## 🔧 What You'll Build

A contract demonstrating:
- Full ERC721 implementation
- Metadata handling
- Minting mechanisms
- Safe transfer patterns

## ✅ Status

🚧 **Scaffold** - Complete Projects 01-08 first

## 🚀 Next Steps

After completing this project:
- Move to [Project 10: Upgradeability & Proxies](../10-upgradeability-and-proxies/)
