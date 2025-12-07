package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/ethclient"
)

func main() {
	// ============================================================
	// CONFIGURATION: Environment Variables and Flags
	// ============================================================
	// Building on module 01: We use the same pattern for reading RPC URL
	// from environment variables with flag overrides.
	//
	// New in this module: We add a retry count flag. This allows users
	// to configure how many retries to attempt for block fetching.
	defaultRPC := os.Getenv("INFURA_RPC_URL")
	if defaultRPC == "" {
		defaultRPC = "https://mainnet.infura.io/v3/YOUR_KEY" // fallback for demos
	}
	rpcURL := flag.String("rpc", defaultRPC, "RPC endpoint (uses INFURA_RPC_URL if set)")
	timeout := flag.Duration("timeout", 5*time.Second, "RPC timeout")
	retries := flag.Int("retries", 1, "block fetch retries")
	flag.Parse()

	// ============================================================
	// CONTEXT WITH TIMEOUT: Preventing Hanging Forever
	// ============================================================
	// Same as module 01: Context with timeout = circuit breaker.
	// This prevents hanging forever on slow/broken RPCs.
	//
	// Computer Science principle: Timeouts are essential for production
	// systems. Without them, a single slow RPC could hang your entire
	// application.
	ctx, cancel := context.WithTimeout(context.Background(), *timeout)
	defer cancel()

	// ============================================================
	// DIALING THE RPC ENDPOINT: Establishing Connection
	// ============================================================
	// Same as module 01: Dial JSON-RPC (HTTP/WS depending on URL).
	// This is your "phone line" to the node.
	//
	// Building on module 01: We're reusing the same connection pattern.
	// In production, you'd often reuse a single client across multiple
	// requests (connection pooling).
	client, err := ethclient.DialContext(ctx, *rpcURL)
	if err != nil {
		log.Fatalf("dial failed: %v", err)
	}
	defer client.Close()

	// ============================================================
	// QUERYING BLOCK NUMBER: The Cheapest Operation
	// ============================================================
	// blockNumber maps to eth_blockNumber (cheap: just the latest height).
	// This is the lightest-weight operation you can perform.
	//
	// JSON-RPC call: {"method": "eth_blockNumber", "params": [], "id": 1}
	// Response: {"result": "0x1234", "id": 1} (hex-encoded block number)
	//
	// Why hex? Ethereum uses hex encoding for numbers in JSON-RPC because
	// JavaScript's Number type can't safely represent large integers (like
	// block numbers). Hex strings are safe across all languages.
	//
	// Fun fact: Block numbers are uint64, so max block number is
	// 18,446,744,073,709,551,615. At 12 seconds per block, that's enough
	// for ~7 billion years!
	height, err := client.BlockNumber(ctx)
	if err != nil {
		log.Fatalf("blockNumber failed: %v", err)
	}

	// ============================================================
	// QUERYING NETWORK ID: Legacy Identifier
	// ============================================================
	// net_version = legacy network id (not chainId, but often matches on mainnet).
	// This is from module 01 - we're including it for completeness.
	//
	// Historical context: Network ID was used for P2P peer discovery.
	// Chain ID (from module 01) is used for transaction replay protection.
	netID, err := client.NetworkID(ctx)
	if err != nil {
		log.Fatalf("net_version failed: %v", err)
	}

	// ============================================================
	// FETCHING FULL BLOCK: The Heavy Operation
	// ============================================================
	// Fetch full latest block (tx objects). Heavier than hash-only;
	// good for explorers/analytics.
	//
	// Key difference from module 01:
	// - Module 01: HeaderByNumber() → Returns just header (~500 bytes)
	// - This module: BlockByNumber() → Returns full block (100KB-2MB)
	//
	// The full block includes:
	// - Header (same as HeaderByNumber)
	// - All transactions (with full calldata)
	// - Uncle blocks (stale blocks)
	//
	// Computer Science principle: This is a trade-off between bandwidth
	// and functionality. Headers are fast but limited. Full blocks are
	// slow but complete.
	//
	// JSON-RPC call: {"method": "eth_getBlockByNumber", "params": ["latest", true], "id": 1}
	// - "latest" = nil in Go (means tip of chain)
	// - true = include full transaction objects (not just hashes)
	var block *types.Block
	var lastErr error
	
	// ============================================================
	// RETRY LOGIC: Building Resilience
	// ============================================================
	// Retry loop: try up to (retries + 1) times.
	// This handles transient failures like:
	// - Network hiccups
	// - Rate limiting (429 errors)
	// - Server overload (503 errors)
	//
	// Computer Science principle: Retries are a form of fault tolerance.
	// They allow transient failures to be automatically recovered.
	//
	// Production tip: In production, use exponential backoff:
	// - Wait 100ms, then 200ms, then 400ms, etc.
	// - This prevents "thundering herd" problems
	//
	// For this module, we use a simple fixed delay (100ms).
	for i := 0; i <= *retries; i++ {
		block, lastErr = client.BlockByNumber(ctx, nil) // nil => latest
		if lastErr == nil {
			break // Success! Exit the retry loop
		}
		// Small delay before retry (prevents hammering the server)
		time.Sleep(100 * time.Millisecond)
	}
	
	// Check if all retries failed
	if lastErr != nil {
		log.Fatalf("get block failed after retries: %v", lastErr)
	}

	// ============================================================
	// BLOCK ANALYSIS: Understanding Block Structure
	// ============================================================
	// Now we have a full block! Let's examine what we can learn from it:
	//
	// - block.NumberU64(): Block height (should match height from BlockNumber())
	// - block.Hash(): Cryptographic hash of the block header
	// - block.ParentHash(): Hash of the previous block (creates the chain)
	// - len(block.Transactions()): Number of transactions in this block
	// - block.GasUsed(): Total gas consumed by all transactions
	//
	// Fun fact: The block hash is computed from the header. If ANY field
	// in the header changes, the hash changes. This is how blockchain
	// immutability works—you can't change a block without changing its hash,
	// which would break the chain (parentHash of next block wouldn't match).
	//
	// Computer Science principle: Cryptographic hashes are one-way functions.
	// You can compute hash(data), but you can't compute data from hash.
	// This makes blocks tamper-evident.

	fmt.Printf("✅ RPC basics\n  net_version: %s\n  latest: #%d hash=%s parent=%s txs=%d gasUsed=%d\n",
		netID.String(), block.NumberU64(), block.Hash(), block.ParentHash(), len(block.Transactions()), block.GasUsed())

	// ============================================================
	// EDUCATIONAL NOTES & COMPARISONS
	// ============================================================
	//
	// Building on module 01:
	// - Module 01: Headers only (~500 bytes, fast)
	// - This module: Full blocks (100KB-2MB, slower but complete)
	//
	// When to use what:
	// - Headers: Block explorers showing block list, monitoring block height
	// - Full blocks: Transaction analysis, indexing, event queries
	//
	// Comparisons:
	// - JS ethers: provider.getBlockNumber(), provider.getBlockWithTransactions("latest")
	// - CPU analogy: Block header ≈ CPU register dump; full block ≈ instruction log + memory writes
	//
	// Real-world analogy:
	// - Calling the city clerk for the latest ledger page and getting both
	//   the stamped header (hashes) and every line item (transactions)
	//
	// Related Solidity concepts:
	// - Transactions in blocks are what execute your Solidity contracts
	// - Gas used tells you how expensive operations were (from Solidity module 06)
	// - Transaction receipts (module 15) contain logs (events from Solidity module 03)
	//
	// Next steps (module 03):
	// - You'll learn how to generate keys and addresses
	// - Understand the connection between addresses and msg.sender in Solidity
	// - Work with keystore files (encrypted key storage)
}
