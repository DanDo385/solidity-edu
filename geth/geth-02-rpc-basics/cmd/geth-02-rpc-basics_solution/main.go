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
	defaultRPC := os.Getenv("INFURA_RPC_URL")
	if defaultRPC == "" {
		defaultRPC = "https://mainnet.infura.io/v3/YOUR_KEY" // fallback for demos
	}
	rpcURL := flag.String("rpc", defaultRPC, "RPC endpoint (uses INFURA_RPC_URL if set)")
	timeout := flag.Duration("timeout", 5*time.Second, "RPC timeout")
	retries := flag.Int("retries", 1, "block fetch retries")
	flag.Parse()

	// 🛡️ Context with timeout = circuit breaker; avoids hangs on slow/broken RPCs.
	ctx, cancel := context.WithTimeout(context.Background(), *timeout)
	defer cancel()

	// 🔌 Dial JSON-RPC (HTTP/WS depending on URL). This is your “phone line” to the node.
	client, err := ethclient.DialContext(ctx, *rpcURL)
	if err != nil {
		log.Fatalf("dial failed: %v", err)
	}
	defer client.Close()

	// 📄 blockNumber maps to eth_blockNumber (cheap: just the latest height).
	height, err := client.BlockNumber(ctx)
	if err != nil {
		log.Fatalf("blockNumber failed: %v", err)
	}

	// 🌐 net_version = legacy network id (not chainId, but often matches on mainnet).
	netID, err := client.NetworkID(ctx)
	if err != nil {
		log.Fatalf("net_version failed: %v", err)
	}

	// 📦 Fetch full latest block (tx objects). Heavier than hash-only; good for explorers/analytics.
	var block *types.Block
	var lastErr error
	for i := 0; i <= *retries; i++ {
		block, lastErr = client.BlockByNumber(ctx, nil) // nil => latest
		if lastErr == nil {
			break
		}
		time.Sleep(100 * time.Millisecond)
	}
	if lastErr != nil {
		log.Fatalf("get block failed after retries: %v", lastErr)
	}

	fmt.Printf("✅ RPC basics\n  net_version: %s\n  latest: #%d hash=%s parent=%s txs=%d gasUsed=%d\n",
		netID.String(), block.NumberU64(), block.Hash(), block.ParentHash(), len(block.Transactions()), block.GasUsed())

	// ============================================================
	// FUN / NERDY FACTS & ANALOGIES
	// ============================================================
	// - EVM is a stack machine (like early CPUs); the block header is its “register snapshot” for that tick.
	// - Header roots (stateRoot/txRoot/receiptsRoot) commit to Merkle-Patricia tries = tamper-evident ledgers.
	// - Headers are ~500 bytes; full blocks can be megabytes. Avoid full tx bodies if you only need hashes.
	// - Public RPCs may cache block responses; your own node = freshest data + debug/admin namespaces.
	//
	// ASCII mental model:
	//   [ you ] --JSON-RPC--> [ Geth ] --p2p gossip--> [ peers ]
	//      |                     |
	//      |                state trie / headers
	//      v
	//   blockNumber, block, net_version
	//
	// Comparisons:
	// - JS ethers: provider.getBlockNumber(), provider.getBlockWithTransactions("latest")
	// - CPU analogy: block header ≈ CPU register dump; full block ≈ instruction log + memory writes for that tick.
	//
	// Real-world analogy:
	// - Calling the city clerk for the latest ledger page and getting both the stamped header (hashes) and every line item (txs).
}
