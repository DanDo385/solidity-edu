# 12-proofs: Merkle-Patricia Trie Proofs

**Goal:** Fetch and interpret Merkle-Patricia trie proofs for accounts and storage slots via `eth_getProof`.

## Big Picture: Cryptographic Proofs for Trust-Minimized Verification

**Merkle-Patricia trie proofs** are cryptographic receipts that prove "account X has balance Y and storage slot Z has value W at block N" without downloading the entire blockchain state. This enables:
- **Light clients:** Verify state without syncing full blockchain
- **Bridges:** Prove state on one chain to another chain
- **Indexers:** Verify indexed data is correct
- **Wallets:** Check balances without trusting a single RPC endpoint

**Computer Science principle:** Merkle trees allow you to prove membership in a set using only a logarithmic number of hashes. Instead of downloading 100GB of state, you download a few KB of proof nodes.

### The Proof Model

```
┌─────────────────────────────────────────────────────────┐
│              Merkle-Patricia Trie (State)               │
│                                                          │
│                    ┌─────────────┐                      │
│                    │  State Root  │ ← In block header    │
│                    └──────┬──────┘                      │
│                           │                              │
│              ┌────────────┴────────────┐                │
│              │                         │                 │
│         ┌────▼────┐              ┌────▼────┐            │
│         │  Node   │              │  Node   │            │
│         └────┬────┘              └────┬────┘            │
│              │                         │                 │
│         ┌────▼────┐              ┌────▼────┐            │
│         │ Account │              │ Account │            │
│         │  Data   │              │  Data   │            │
│         └─────────┘              └─────────┘            │
│                                                          │
│  Proof = Path from root to leaf (highlighted nodes)     │
│  You can verify the proof using only the proof nodes!   │
└─────────────────────────────────────────────────────────┘
```

**Real-world analogy:** Like a **notarized receipt** stapled to a ledger page. The receipt contains:
- The entry you're proving (account balance, storage value)
- Cryptographic signatures (Merkle hashes) proving the entry is part of the official ledger
- Anyone can verify the receipt without seeing the entire ledger

## Learning Objectives

By the end of this module, you should be able to:

1. **Call `eth_getProof` via Go's `GetProof` method:**
   - Request proofs for accounts and storage slots
   - Specify block number (or use latest)
   - Understand proof structure

2. **Interpret proof results:**
   - Account proof: balance, nonce, codeHash, storageHash
   - Storage proof: slot value and proof nodes
   - Proof nodes: Merkle tree path from root to leaf

3. **Understand trust-minimized verification:**
   - How proofs enable verification without full state
   - Why light clients need proofs
   - How bridges use proofs for cross-chain verification

4. **Connect proofs to storage slots:**
   - Proof paths use same slot calculations as module 11
   - Storage proofs prove specific slot values
   - Account proofs prove account state

## Prerequisites

- **Module 11 (storage):** You should understand storage slot calculation
- **Go basics:** Context, error handling, big integers
- **Conceptual understanding:** Merkle trees, cryptographic hashing

## Building on Previous Modules

### From Module 11 (Storage)
- You learned to read storage slots directly
- Now you're getting **cryptographic proofs** for those slots
- Proofs use the same slot calculations you learned

### From Module 01 (Stack)
- Block headers contain `stateRoot` (Merkle root of state trie)
- Proofs prove membership in that trie
- You can verify proofs against the `stateRoot`

### Connection to Solidity-edu

**From Solidity 01 (Datatypes & Storage):**
- Storage slots you learned about are what proofs prove
- Proofs prove "contract X has value Y in slot Z"

**From Solidity 03 (Events & Logging):**
- Proofs are different from logs
- Logs are in receipts (transaction logs)
- Proofs are in state trie (account/storage state)

## Understanding Merkle-Patricia Trie Proofs

### What is a Merkle Tree?

A **Merkle tree** is a binary tree where:
- **Leaves:** Data items (account balances, storage values)
- **Internal nodes:** Hashes of children
- **Root:** Single hash representing entire tree

**Verification process:**
1. You have a data item (leaf)
2. You have proof nodes (sibling hashes along path to root)
3. You compute hashes up the tree
4. If final hash matches root, proof is valid!

**Computer Science principle:** This is **cryptographic commitment**. The root hash commits to all data in the tree. You can't change any data without changing the root.

### Account Proofs

An **account proof** proves:
- Account balance
- Account nonce
- Contract code hash (if contract account)
- Storage root hash (if contract account)

**Proof structure:**
```go
type AccountResult struct {
    Balance     *big.Int      // Account balance
    Nonce       uint64        // Transaction nonce
    CodeHash    common.Hash   // Hash of contract code (if contract)
    StorageHash common.Hash   // Root of storage trie (if contract)
    AccountProof []string      // Merkle proof nodes
}
```

### Storage Proofs

A **storage proof** proves:
- Storage slot value
- That the value is part of the contract's storage trie

**Proof structure:**
```go
type StorageResult struct {
    Key   string   // Storage slot (hex-encoded)
    Value *big.Int // Value at that slot
    Proof []string // Merkle proof nodes
}
```

**Connection to module 11:** The slot calculation you learned (keccak256(key, baseSlot)) is used to navigate the storage trie!

## Real-World Analogies

### The Notarized Receipt Analogy
- **Proof** = Notarized receipt stapled to ledger page
- **Proof nodes** = Notary signatures along the path
- **State root** = Official ledger seal
- **Verification** = Checking signatures match official seal

### The Library Card Catalog Analogy
- **State trie** = Library card catalog (index of all books)
- **Account** = A specific book
- **Proof** = Path through catalog to find the book
- **Verification** = Following the path to confirm book exists

### The Git Commit Analogy
- **State root** = Git commit hash
- **Account** = File in repository
- **Proof** = Path from root to file in Git tree
- **Verification** = Computing tree hash and comparing to commit

## Fun Facts & Nerdy Details

### Proof Size
- **Account proof:** ~1-5 KB (depends on trie depth)
- **Storage proof:** ~1-5 KB per slot
- **Full state:** ~100+ GB (mainnet)
- **Savings:** 99.999% reduction in data!

**Computer Science principle:** Merkle trees provide logarithmic proof size. For 2^256 accounts, you only need ~256 proof nodes (one per level).

### Trie Depth
- **Account trie depth:** ~7-9 levels on mainnet
- **Storage trie depth:** ~5-7 levels per contract
- **Why it matters:** Deeper trie = more proof nodes = larger proofs

### Light Client Verification
Light clients use proofs to:
1. Download block headers only (small, ~500 bytes each)
2. Request proofs for accounts they care about
3. Verify proofs against `stateRoot` in headers
4. Trust the network without syncing full state

**Security model:** Light clients trust that >50% of validators are honest (same as full nodes). Proofs ensure data integrity.

### Bridge Applications
Cross-chain bridges use proofs to:
1. Prove state on source chain (e.g., "user has 100 USDC")
2. Submit proof to destination chain
3. Destination chain verifies proof
4. Mints equivalent tokens on destination

**Example:** Optimism bridge proves L1 state to L2, Arbitrum does the same.

## Comparisons

### Proofs vs Direct Queries

| Aspect | Direct Query (`eth_getBalance`) | Proof (`eth_getProof`) |
|--------|--------------------------------|------------------------|
| **Trust** | Trust RPC endpoint | Verify cryptographically |
| **Size** | Small response | Larger (proof nodes) |
| **Use case** | Simple queries | Light clients, bridges |
| **Verification** | None | Cryptographic |

**When to use what:**
- **Direct query:** When you trust the RPC endpoint (most applications)
- **Proof:** When you need cryptographic verification (light clients, bridges)

### Go `ethclient.GetProof` vs JavaScript `ethers.js`

| Aspect | Go `ethclient` | JavaScript `ethers.js` |
|--------|----------------|------------------------|
| **Method** | `client.GetProof(ctx, addr, slots, block)` | `provider.send("eth_getProof", ...)` |
| **Returns** | `*AccountResult` struct | JSON object |
| **Type safety** | Compile-time (Go types) | Runtime (JavaScript) |

**Same JSON-RPC:** Both call `eth_getProof` under the hood.

### Account Proofs vs Storage Proofs

| Aspect | Account Proof | Storage Proof |
|--------|---------------|---------------|
| **Proves** | Account state (balance, nonce) | Storage slot value |
| **Trie** | Account trie (global) | Storage trie (per contract) |
| **Root** | `stateRoot` in block header | `storageHash` in account |

**Connection:** Storage proofs are nested inside account proofs. You need the account proof to get the `storageHash`, then you can prove storage slots.

## Related Solidity-edu Modules

- **01 Datatypes & Storage:** Storage slots that proofs prove
- **06 Mappings, Arrays & Gas:** Slot calculations used in proof paths
- **12 Proofs (this module):** How to fetch and verify proofs

## What You'll Build

In this module, you'll create a CLI that:
1. Takes an account address (and optional storage slot)
2. Calls `eth_getProof` to fetch Merkle-Patricia trie proofs
3. Displays account state (balance, nonce, codeHash, storageHash)
4. Displays storage proof (if slot provided)
5. Shows proof node counts

**Key learning:** You'll understand how cryptographic proofs enable trust-minimized verification. This is essential for:
- Building light clients
- Implementing cross-chain bridges
- Verifying indexed data
- Building trustless applications

## Files

- **Starter:** `cmd/12-proofs/main.go` - Your starting point with TODO comments
- **Solution:** `cmd/12-proofs_solution/main.go` - Complete implementation with detailed comments

## Next Steps

After completing this module, you'll move to **13-trace** where you'll:
- Trace transaction execution (opcode-by-opcode)
- Understand EVM execution internals
- Debug contract behavior
- Analyze gas usage at the opcode level
