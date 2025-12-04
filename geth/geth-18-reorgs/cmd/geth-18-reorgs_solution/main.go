package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"math/big"
	"os"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
)

func main() {
	defaultRPC := os.Getenv("INFURA_RPC_URL")
	if defaultRPC == "" {
		defaultRPC = "https://mainnet.infura.io/v3/YOUR_KEY"
	}
	rpc := flag.String("rpc", defaultRPC, "RPC endpoint")
	start := flag.Int64("start", 0, "start block")
	count := flag.Int64("count", 20, "number of blocks to scan")
	flag.Parse()

	// EDUCATIONAL NOTES:
	// - Reorgs: when a different fork becomes canonical; shallow ones are expected occasionally.
	// - Store (number, hash); if parent hash mismatches, rollback a few blocks and rescan.
	// - Analogy: ledger page revised—if a page points to a different previous page, redo the archive.

	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	client, err := ethclient.DialContext(ctx, *rpc)
	if err != nil {
		log.Fatalf("dial: %v", err)
	}
	defer client.Close()

	var prevHash common.Hash
	for n := *start; n < *start+*count; n++ {
		blk, err := client.BlockByNumber(ctx, big.NewInt(n))
		if err != nil {
			log.Fatalf("block %d: %v", n, err)
		}
		if n > *start && blk.ParentHash() != prevHash {
			fmt.Printf("⚠️  reorg detected at block %d: expected parent %s got %s\n", n, prevHash, blk.ParentHash())
		}
		fmt.Printf("block %d hash=%s parent=%s txs=%d\n", n, blk.Hash(), blk.ParentHash(), len(blk.Transactions()))
		prevHash = blk.Hash()
	}

	// Commentary:
	// - Store (number, hash) in your DB; on mismatch, rollback to safe depth and rescan.
	// - Deep reorgs are rare on mainnet; shallow (1-2 blocks) can happen.
	// Analogy: ledger page revised; if the page points to a different previous page, redo the archive.
}
