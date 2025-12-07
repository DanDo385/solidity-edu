# 02-rpc-basics: Deep Dive into JSON-RPC and Block Structures

**Goal:** Build a robust JSON-RPC client, call common endpoints, and practice timeouts/retries with full block fetching.

## Big Picture: JSON-RPC as the Universal Interface

JSON-RPC is your "librarian desk" to Ethereum: you ask for data (`eth_blockNumber`, `eth_getBlockByNumber`) or submit work (transactions). Geth exposes this API; hosted RPCs proxy it with rate limits.

### What is JSON-RPC?

**JSON-RPC** is a stateless, light-weight remote procedure call (RPC) protocol. Think of it like REST APIs, but simpler:
- **Request:** `{"jsonrpc": "2.0", "method": "eth_blockNumber", "params": [], "id": 1}`
- **Response:** `{"jsonrpc": "2.0", "result": "0x1234", "id": 1}`

**Computer Science principle:** RPC (Remote Procedure Call) allows you to call functions on a remote server as if they were local. JSON-RPC uses JSON for serialization, making it language-agnostic. Go's `ethclient` package wraps these JSON-RPC calls into convenient Go methods.

### The Request-Response Model

```
┌─────────────┐                    ┌─────────────┐
│   Your App  │  JSON-RPC Request  │    Geth    │
│   (Go)      │ ─────────────────> │   Node     │
│             │ <───────────────── │             │
│             │  JSON-RPC Response │             │
└─────────────┘                    └─────────────┘
```

**Fun fact:** JSON-RPC is stateless, meaning each request is independent. This is different from WebSocket subscriptions (which we'll cover in module 10), where you maintain a persistent connection.

## Learning Objectives

By the end of this module, you should be able to:

1. **Initialize `ethclient` with context timeouts** (building on module 01)
2. **Call common JSON-RPC methods:**
   - `eth_blockNumber` → `client.BlockNumber()`
   - `eth_getBlockByNumber` → `client.BlockByNumber()`
   - `net_version` → `client.NetworkID()`
3. **Inspect block fields:** hash, parentHash, gasUsed, transaction count
4. **Understand the difference between headers and full blocks:**
   - Headers (module 01): ~500 bytes, just metadata
   - Full blocks: 100KB-2MB, includes all transaction data
5. **Implement retry logic** for production resilience
6. **Understand JSON-RPC limitations:** rate limits, missing debug/admin endpoints

## Prerequisites

- **Module 01 (01-stack):** You should understand how to dial an RPC endpoint and fetch block headers
- **Go basics:** Flags, contexts, error handling, loops
- **Conceptual understanding:** Blocks, transactions, gas (from Solidity experience)

## Building on Module 01

In **module 01**, you learned to:
- Dial an RPC endpoint
- Query chain ID and network ID
- Fetch block **headers** (lightweight metadata)

In **this module**, you'll:
- Fetch **full blocks** (includes transaction data)
- Understand transaction structures
- Add **retry logic** for resilience
- Compare block numbers from different sources

**Key difference:** `HeaderByNumber()` returns just the header (~500 bytes). `BlockByNumber()` returns the full block including all transactions (can be megabytes). Use headers when you only need metadata!

## Real-World Analogies

### The Library Analogy
Calling the city clerk for the latest ledger page and a photocopy of that page (full block) to see every entry (transactions). In module 01, you only got the page header (stamped with hash and page number). Now you're getting the full page with all the line items.

### The Database Query Analogy
- **Header:** Like querying a database table's metadata (row count, last updated timestamp)
- **Full Block:** Like fetching all rows with all columns (much heavier!)

### The Git Commit Analogy
- **Header:** `git log --oneline` (just commit hash and message)
- **Full Block:** `git show` (commit + full diff + file contents)

## Understanding Block Structures

### Block Header (from module 01)
```go
type Header struct {
    Number      *big.Int    // Block height
    Hash        common.Hash // Cryptographic hash
    ParentHash  common.Hash // Previous block hash
    StateRoot   common.Hash // Merkle root of state trie
    TxRoot      common.Hash // Merkle root of transactions
    ReceiptRoot common.Hash // Merkle root of receipts
    LogsBloom   Bloom       // Bloom filter for events
    GasUsed     uint64      // Total gas consumed
    GasLimit    uint64      // Maximum gas allowed
    Time        uint64      // Unix timestamp
    // ... more fields
}
```

### Full Block (this module)
```go
type Block struct {
    Header       *Header
    Transactions []*Transaction  // All transactions in this block
    Uncles       []*Header       // Stale blocks (uncle blocks)
}
```

**Computer Science principle:** This is a classic example of composition. A block **contains** a header plus additional data (transactions). The header is like a database index—it gives you metadata without loading the full data.

### Transaction Structure
Each transaction in a block contains:
- **Nonce:** Sequence number (prevents replay attacks)
- **GasPrice/GasFeeCap/GasTipCap:** Gas pricing (EIP-1559, covered in module 06)
- **To:** Recipient address (nil for contract creation)
- **Value:** Amount of ETH to send
- **Data:** Calldata (function calls, contract bytecode, etc.)
- **Hash:** Cryptographic hash of the transaction

**Nerdy detail:** Transaction hashes are computed from the RLP-encoded transaction data. RLP (Recursive Length Prefix) is Ethereum's custom serialization format—more efficient than JSON for binary data.

## Retry Logic: Building Resilience

**Why retries matter:** Networks are unreliable. An RPC call might fail due to:
- Temporary network issues
- Rate limiting (429 errors)
- Server overload (503 errors)
- Timeouts

**Computer Science principle:** Retries are a form of **fault tolerance**. They allow transient failures to be automatically recovered without user intervention.

**Exponential backoff:** In production, you'd use exponential backoff (wait 100ms, then 200ms, then 400ms). For this module, we use a simple fixed delay.

**Fun fact:** Too many retries can cause a "thundering herd" problem—if everyone retries immediately, you overwhelm the server. Exponential backoff spreads out retries over time.

## Fun Facts & Nerdy Details

### JSON-RPC Method Names
- **`eth_blockNumber`:** Returns the latest block number as hex string (`"0x1234"`)
- **`eth_getBlockByNumber`:** Can return:
  - `false` (just hashes): `["0x1234", false]` → Returns block with transaction hashes only
  - `true` (full objects): `["0x1234", true]` → Returns block with full transaction objects
- **`net_version`:** Legacy network identifier (often same as chain ID)

**Nerdy detail:** The `eth_` prefix indicates Ethereum namespace. Other namespaces include:
- `net_`: Network operations
- `web3_`: Web3 utilities
- `debug_`: Debug operations (often disabled on public RPCs)
- `admin_`: Admin operations (usually disabled on public RPCs)

### Block Size Considerations
- **Average block size:** ~100-200 KB on mainnet
- **Largest blocks:** Can exceed 2 MB (gas limit is ~30M gas, and calldata costs 16 gas per byte)
- **Empty blocks:** ~500 bytes (just the header)

**Computer Science principle:** This is why block explorers and indexers use specialized databases. You can't efficiently query "all Transfer events" by downloading every block—you need indexes!

### Gas Usage
- **Gas limit per block:** ~30M gas (varies by network)
- **Average gas per transaction:** ~21,000 (simple ETH transfer) to millions (complex contract calls)
- **Average transactions per block:** ~150-300 on mainnet

**Fun fact:** The gas limit is a consensus parameter. Validators vote to adjust it. Higher gas limit = more transactions per block, but larger blocks = slower propagation = more reorgs.

## Comparisons

### Headers vs Full Blocks
| Aspect | Headers | Full Blocks |
|--------|---------|-------------|
| Size | ~500 bytes | 100KB-2MB |
| Contains | Metadata only | Metadata + transactions |
| Use case | Block explorers, monitoring | Transaction analysis, indexing |
| Cost | Very cheap | Expensive (bandwidth + CPU) |

### Go `ethclient` vs JavaScript `ethers.js`
- **Go:** `client.BlockByNumber(ctx, nil)` → Returns `*types.Block`
- **JavaScript:** `provider.getBlockWithTransactions("latest")` → Returns object with transactions array
- **Same JSON-RPC:** Both call `eth_getBlockByNumber` under the hood

### Public RPCs vs Your Own Node
- **Public RPCs (Infura, Alchemy):**
  - ✅ Convenient, no setup
  - ❌ Rate limits (100k requests/day on free tier)
  - ❌ May cache responses (not always latest)
  - ❌ Debug/admin endpoints disabled
- **Your Own Node:**
  - ✅ No rate limits
  - ✅ Always latest data
  - ✅ Full debug/admin access
  - ❌ Requires ~1TB disk space
  - ❌ Takes days to sync initially

## Related Solidity-edu Modules

- **01 Datatypes & Storage:** Block headers include `stateRoot` that commits to all storage slots. The state trie is a Merkle-Patricia tree indexing every storage slot you learned about!
- **03 Events & Logging:** Blocks contain `logsBloom` (bloom filter) and `receiptsRoot` (Merkle root of receipts). Receipts contain logs (events). This is how event queries work!
- **05 Errors & Reverts:** Transaction receipts include a `status` field (0 = failed, 1 = succeeded). Failed transactions still consume gas!
- **06 Mappings, Arrays & Gas:** Transaction `gasUsed` tells you how much gas was consumed. Complex operations (loops, mappings) consume more gas.

## What You'll Build

In this module, you'll create a CLI that:
1. Connects to an RPC endpoint (building on module 01)
2. Queries the latest block number (cheap operation)
3. Queries the network ID (from module 01)
4. Fetches the **full latest block** (includes transactions)
5. Implements **retry logic** for resilience
6. Displays block metadata: number, hash, parent hash, transaction count, gas used

**Key learning:** You'll see the difference between lightweight headers (module 01) and full blocks (this module). This understanding is crucial for building efficient applications!

## Files

- **Starter:** `cmd/02-rpc-basics/main.go` - Your starting point with TODO comments
- **Solution:** `cmd/02-rpc-basics_solution/main.go` - Complete implementation with detailed comments

## Next Steps

After completing this module, you'll move to **03-keys-addresses** where you'll:
- Generate Ethereum keypairs (secp256k1)
- Derive addresses from public keys
- Work with keystore files (encrypted key storage)
- Understand the connection between keys and `msg.sender` in Solidity
