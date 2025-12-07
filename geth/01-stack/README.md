# 01-stack: Understanding the Ethereum Execution Stack

**Goal:** Understand what Geth is, how it fits with consensus clients, and prove connectivity by reading chain ID + latest block.

## Big Picture: The Ethereum Stack from First Principles

Before diving into code, let's build a mental model from the ground up. Ethereum is fundamentally a **distributed state machine**—think of it like a globally synchronized database where everyone agrees on the same sequence of state transitions. But unlike a traditional database, there's no central authority. Instead, we have a **two-client architecture** that emerged from The Merge (Ethereum's transition to Proof-of-Stake):

### The Two-Client Architecture

**Execution Client (Geth)** = The CPU + Memory + Disk
- **What it does:** Executes EVM bytecode, maintains the state trie (think: Merkle-Patricia tree indexing all account balances and contract storage), and exposes JSON-RPC endpoints
- **Computer Science analogy:** Like a CPU executing instructions, Geth executes transactions. The state trie is like a hash table, but cryptographically verifiable—you can prove "account X has balance Y" without downloading the entire blockchain
- **Fun fact:** Geth stands for "Go Ethereum"—it's written in Go, but there are other execution clients: Erigon (also Go), Nethermind (C#), Besu (Java). They all implement the same EVM spec, so they're interchangeable!

**Consensus Client** (Prysm, Lighthouse, Nimbus, etc.) = The Scheduler + Validator
- **What it does:** Runs the Beacon Chain, manages validators, drives fork choice (decides which chain is canonical), and tells the execution client "execute this block"
- **Computer Science analogy:** Like an operating system scheduler deciding which process runs next, the consensus client decides which block gets appended to the chain
- **Nerdy detail:** The Beacon Chain uses a BFT-style consensus (Casper FFG + LMD GHOST). Validators stake ETH and vote on blocks. If you vote incorrectly, you get slashed (lose ETH). This is why it's called "Proof-of-Stake"

**JSON-RPC** = The API Layer
- **What it does:** Exposes a standardized interface (JSON-RPC 2.0) for querying data and submitting transactions
- **Computer Science analogy:** Like REST APIs for web services, JSON-RPC is the protocol for interacting with Ethereum nodes
- **Protocol detail:** JSON-RPC is stateless and request-response based. Methods like `eth_blockNumber` return data, while `eth_sendTransaction` submits work

### The Complete Picture

```
┌─────────────────────────────────────────────────────────┐
│                    Your Application                      │
│              (Go code using ethclient)                   │
└────────────────────┬────────────────────────────────────┘
                     │ JSON-RPC (HTTP/WebSocket)
                     ▼
┌─────────────────────────────────────────────────────────┐
│              Execution Client (Geth)                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   EVM Exec   │  │  State Trie  │  │  JSON-RPC    │  │
│  │   Engine     │  │  (Merkle)    │  │  Server      │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└────────────────────┬────────────────────────────────────┘
                     │ Engine API (local IPC)
                     ▼
┌─────────────────────────────────────────────────────────┐
│           Consensus Client (Prysm/Lighthouse)           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Beacon Chain │  │   Fork       │  │  Validator   │  │
│  │   Logic      │  │   Choice     │  │  Management  │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└────────────────────┬────────────────────────────────────┘
                     │ P2P Gossip Protocol
                     ▼
              ┌──────────────┐
              │ Other Nodes  │
              │  (Peers)     │
              └──────────────┘
```

## Learning Objectives

By the end of this module, you should be able to:

1. **Draw the high-level Ethereum stack:** execution vs consensus vs networking vs JSON-RPC
2. **Use Go + `ethclient` to dial an RPC endpoint** with proper timeout handling (critical for production!)
3. **Query `chainId`, `net_version`, and the latest block header**—these are your "hello world" operations
4. **Interpret the difference between chain ID and network ID:**
   - **Chain ID** (EIP-155): Used for replay protection in transaction signing. Mainnet = 1, Sepolia = 11155111, etc.
   - **Network ID** (legacy): Older identifier, often matches chain ID but not guaranteed. Some networks use different values.
5. **Understand why "public RPC" ≠ "running a node":**
   - Public RPCs (Infura, Alchemy) are convenient but rate-limited
   - They often disable admin/debug endpoints (`debug_traceTransaction`, `admin_*`)
   - Running your own node gives you full power but requires ~1TB disk space and sync time

## Prerequisites

- **Go basics:** modules, `go run`, flags, contexts
- **Conceptual Ethereum familiarity:** blocks, transactions, state (if you've done Solidity, you know this!)
- **From Solidity-edu:**
  - **01 Datatypes & Storage:** Block headers carry `stateRoot` that indexes the storage trie. Every storage slot you learned about in Solidity is committed to this root!
  - **03 Events & Logging:** Headers include `logsBloom` (bloom filter) and `receiptsRoot` used for efficient event queries

## Real-World Analogies

### The City Records Office Analogy
Calling the city records office: you ask "What's the latest ledger page number?" (block number) and "Which city am I talking to?" (chain ID). The clerk hands you the stamped page header (block hash/parent hash). The header is like a checksum—if someone tampered with the page, the hash would change.

### The CPU Register Snapshot Analogy
Think of a block header as a CPU register snapshot after executing a batch of instructions. The `stateRoot` is like the memory state, `transactionsRoot` is the instruction log, and `receiptsRoot` is the execution trace. The `parentHash` links to the previous snapshot, creating an immutable chain.

### The Git Commit Analogy
A block is like a Git commit:
- **Block hash** = commit SHA
- **Parent hash** = parent commit SHA
- **State root** = tree hash of the entire repository state
- **Transactions** = the diff/changes in that commit

## Fun Facts & Nerdy Details

### Chain ID History
- **EIP-155** (2016) introduced `chainId` to prevent replay attacks. Before this, a transaction signed on mainnet could be replayed on Ethereum Classic (ETC) or testnets!
- **Replay attack scenario:** You sign a transaction to send 1 ETH to Alice on mainnet. An attacker copies your signature and broadcasts it on ETC. Without chain ID, ETC would accept it, and you'd lose 1 ETC too!
- **Current chain IDs:** Mainnet = 1, Sepolia = 11155111, Holesky = 17000, Base = 8453, Arbitrum = 42161

### Network ID vs Chain ID
- **Network ID** (`net_version`) predates chain ID and was used for P2P networking (identifying which network peers belong to)
- **Chain ID** is used for transaction signing and replay protection
- On mainnet, they're both 1, but on some networks they differ (historical reasons)

### Performance Considerations
- **`eth_blockNumber`** is extremely cheap—just returns a number
- **`eth_getBlockByNumber`** with `fullTransactions=true` can return megabytes of data (each transaction includes calldata, which can be large)
- **Headers vs Full Blocks:** Headers are ~500 bytes. Full blocks can be 100KB-2MB depending on transaction count and calldata size
- **Pro tip:** If you only need the block number and hash, use `HeaderByNumber` instead of `BlockByNumber`

### Public RPC Limitations
- **Rate limits:** Free tiers often limit to 100k requests/day
- **Missing endpoints:** `debug_*`, `admin_*`, `trace_*` are usually disabled
- **Caching:** Responses may be cached, so you might not see the absolute latest state
- **Solution:** Run your own node for production applications (Geth, Erigon, or Nethermind)

## Comparisons

### Go `ethclient` vs JavaScript `ethers.js`
- **Same protocol:** Both use JSON-RPC under the hood
- **Ergonomics:** `ethers.js` has more helper methods (e.g., `provider.getNetwork()` returns chain ID + name), while `ethclient` is more low-level
- **Type safety:** Go's static typing catches errors at compile time
- **Performance:** Go is faster for heavy workloads, but JS is fine for most use cases

### Geth vs Other Execution Clients
- **Geth:** Most popular, battle-tested, written in Go
- **Erigon:** More efficient storage (stores state history), faster sync, also Go
- **Nethermind:** C#, good performance, active development
- **Besu:** Java, enterprise-friendly, Hyperledger project
- **API compatibility:** All implement the same JSON-RPC spec, so your code works with any of them!

### Mainnet vs L2 RPCs
- **L2s (Layer 2s)** like Arbitrum, Optimism, Base run their own execution clients
- **Different semantics:** Some expose L2-specific fields (e.g., `l1BlockNumber` on Optimism)
- **Gas fields:** L2s may have different gas pricing (e.g., Arbitrum uses L1 gas price + L2 fee)
- **Same JSON-RPC:** The core methods (`eth_blockNumber`, `eth_getBalance`) work the same way

## Building on Previous Concepts

This is your **first module**, so there are no previous geth modules to reference yet! But we're building on concepts from Solidity-edu:

- **From Solidity 01 (Datatypes & Storage):** You learned about storage slots. The `stateRoot` in block headers is a Merkle root committing to ALL storage slots across ALL contracts. It's like a cryptographic checksum of the entire Ethereum state!

- **From Solidity 03 (Events & Logging):** You learned about events and logs. Block headers include `logsBloom` (a bloom filter) that allows fast "does this block contain Transfer events?" queries without downloading all logs. The `receiptsRoot` commits to all transaction receipts (which contain logs).

## What You'll Build

In this module, you'll create a simple CLI that:
1. Connects to an Ethereum RPC endpoint (Infura, Alchemy, or your own node)
2. Queries the chain ID (proves you're connected to the right network)
3. Queries the network ID (legacy identifier)
4. Fetches the latest block header (proves connectivity and shows current state)

This is your "hello world" for Ethereum Go development. Every subsequent module builds on these fundamentals!

## Files

- **Starter:** `cmd/01-stack/main.go` - Your starting point with TODO comments
- **Solution:** `cmd/01-stack_solution/main.go` - Complete implementation with detailed comments

## Next Steps

After completing this module, you'll move to **02-rpc-basics** where you'll:
- Fetch full blocks (not just headers)
- Understand transaction structures
- Add retry logic for resilience
- Learn about JSON-RPC method names and parameters
