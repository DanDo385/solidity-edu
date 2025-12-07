package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/ethereum/go-ethereum/ethclient"
)

func main() {
	// ============================================================
	// CONFIGURATION: Reading RPC URL from Environment or Flags
	// ============================================================
	// Flags keep this CLI flexible: swap endpoints without recompiling.
	// This is a common pattern in production Go applications.
	//
	// Environment variables are checked first (useful for CI/CD, Docker, etc.)
	// Then we fall back to a placeholder URL if nothing is set.
	//
	// Computer Science principle: Separation of configuration from code.
	// This makes your application portable across environments.
	defaultRPC := os.Getenv("INFURA_RPC_URL")
	if defaultRPC == "" {
		defaultRPC = "https://mainnet.infura.io/v3/YOUR_KEY" // fallback if env not set
	}
	rpcURL := flag.String("rpc", defaultRPC, "RPC endpoint (HTTP/WS). Uses INFURA_RPC_URL if set.")
	timeout := flag.Duration("timeout", 5*time.Second, "RPC call timeout")
	flag.Parse()

	// ============================================================
	// CONTEXT WITH TIMEOUT: Preventing Hanging Forever
	// ============================================================
	// Context with timeout = circuit breaker; avoids hangs on slow/broken RPCs.
	// This is CRITICAL for production code. Without timeouts, a broken RPC
	// could hang your application indefinitely.
	//
	// Computer Science principle: Timeouts are a form of fault tolerance.
	// They prevent cascading failures and resource exhaustion.
	//
	// The context pattern in Go allows cancellation propagation through
	// call chains. When the timeout expires, all operations using this
	// context will be cancelled.
	//
	// Fun fact: The `defer cancel()` is important even if you don't use
	// the cancel function directly. It releases resources associated with
	// the context and prevents memory leaks.
	ctx, cancel := context.WithTimeout(context.Background(), *timeout)
	defer cancel()

	// ============================================================
	// DIALING THE RPC ENDPOINT: Establishing the Connection
	// ============================================================
	// ethclient.DialContext opens a JSON-RPC connection (HTTP/WS depending on URL).
	// This is your "phone line" to the Ethereum node.
	//
	// Under the hood:
	// - HTTP URLs: Uses standard HTTP POST requests (JSON-RPC over HTTP)
	// - WS URLs (ws:// or wss://): Opens a WebSocket connection (better for subscriptions)
	//
	// The ethclient package handles:
	// - JSON-RPC request/response serialization
	// - Error handling
	// - Connection pooling (for HTTP)
	//
	// Comparison: This is similar to opening a database connection.
	// You dial once, then reuse the client for multiple queries.
	client, err := ethclient.DialContext(ctx, *rpcURL)
	if err != nil {
		log.Fatalf("dial failed: %v", err)
	}
	defer client.Close() // Always close connections to free resources

	// ============================================================
	// QUERYING CHAIN ID: Network Identification
	// ============================================================
	// ChainID is from EIP-155; used for replay protection in tx signing.
	// This tells you which network you're connected to.
	//
	// Common chain IDs:
	// - Mainnet: 1
	// - Sepolia testnet: 11155111
	// - Holesky testnet: 17000
	// - Base L2: 8453
	// - Arbitrum L2: 42161
	//
	// Why it matters: If you sign a transaction with chain ID 1, it can
	// only be valid on mainnet. If someone tries to replay it on Sepolia
	// (chain ID 11155111), the signature verification will fail.
	//
	// Nerdy detail: Chain ID is encoded in the transaction signature using
	// ECDSA with secp256k1. The signature includes (r, s, v) where v encodes
	// the chain ID for replay protection.
	chainID, err := client.ChainID(ctx)
	if err != nil {
		log.Fatalf("chainId failed: %v", err)
	}

	// ============================================================
	// QUERYING NETWORK ID: Legacy Network Identifier
	// ============================================================
	// NetworkID maps to net_version (legacy). Often same as chainID, but not guaranteed.
	// This was used before EIP-155 for P2P networking (identifying which network
	// peers belong to).
	//
	// Historical context: Network ID was introduced early in Ethereum's history
	// for peer discovery. Chain ID came later (EIP-155) specifically for transaction
	// replay protection. On mainnet, they're both 1, but on some networks they differ.
	//
	// Modern usage: Most applications use chain ID instead of network ID.
	// Network ID is kept for backward compatibility.
	netID, err := client.NetworkID(ctx)
	if err != nil {
		log.Fatalf("net_version failed: %v", err)
	}

	// ============================================================
	// FETCHING LATEST BLOCK HEADER: Lightweight Block Info
	// ============================================================
	// Latest header: nil means "tip" (the most recent block).
	// Header is cheaper than full block (no tx bodies).
	//
	// Block structure:
	// - Header: ~500 bytes (hash, parentHash, number, timestamp, stateRoot, etc.)
	// - Full block: Can be 100KB-2MB (includes all transaction data)
	//
	// When to use headers vs full blocks:
	// - Headers: When you only need metadata (number, hash, timestamp)
	// - Full blocks: When you need transaction data
	//
	// Computer Science principle: This is an example of data structure
	// optimization. Headers are like database indexes—they give you
	// metadata without loading the full data.
	//
	// The header contains:
	// - Number: Block height (increments by 1 each block)
	// - Hash: Cryptographic hash of the header (SHA3-256)
	// - ParentHash: Hash of the previous block (creates the chain)
	// - StateRoot: Merkle root of the entire state trie
	// - TransactionsRoot: Merkle root of all transactions
	// - ReceiptsRoot: Merkle root of all transaction receipts
	// - LogsBloom: Bloom filter for efficient event queries
	// - Timestamp: Unix timestamp when block was mined
	// - GasUsed: Total gas consumed by transactions
	// - GasLimit: Maximum gas allowed in the block
	head, err := client.HeaderByNumber(ctx, nil)
	if err != nil {
		log.Fatalf("header fetch failed: %v", err)
	}

	// ============================================================
	// OUTPUT: Displaying the Results
	// ============================================================
	fmt.Printf("✅ RPC ok\n  chainId:   %s\n  net_version: %s\n  head:      #%d hash=%s parent=%s\n",
		chainID.String(), netID.String(), head.Number.Uint64(), head.Hash(), head.ParentHash)

	// ============================================================
	// EDUCATIONAL NOTES & COMPARISONS
	// ============================================================
	//
	// Comparisons:
	// - JS ethers.js: provider.getNetwork() -> chainId, provider.getBlockNumber(),
	//   provider.getBlock("latest"). Same JSON-RPC under the hood, different ergonomics.
	// - Geth vs hosted RPC: hosted endpoints may rate-limit or omit debug/admin;
	//   run your own for full power (debug_traceTransaction, admin_peers, etc.)
	//
	// Analogy:
	// - chainId is the "city ID" stamped on every official ledger page to stop
	//   cross-city replay attacks.
	// - The header is the page header with seals (hash) and link to previous
	//   page (parentHash). It's like a Git commit—immutable and linked.
	//
	// Building on Solidity concepts:
	// - The stateRoot in the header commits to ALL storage slots you learned
	//   about in Solidity module 01. Every contract's storage is part of this root!
	// - The logsBloom allows fast event queries (from Solidity module 03) without
	//   downloading all logs. It's a probabilistic data structure (bloom filter).
	//
	// Next steps (module 02):
	// - You'll fetch full blocks (not just headers) to see transaction data
	// - Learn about transaction structures and gas usage
	// - Add retry logic for production resilience
}
