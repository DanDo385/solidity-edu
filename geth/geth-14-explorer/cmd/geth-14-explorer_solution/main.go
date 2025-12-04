package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"math/big"
	"os"
	"time"

	"github.com/ethereum/go-ethereum/ethclient"
)

func main() {
	defaultRPC := os.Getenv("INFURA_RPC_URL")
	if defaultRPC == "" {
		defaultRPC = "https://mainnet.infura.io/v3/YOUR_KEY"
	}
	rpc := flag.String("rpc", defaultRPC, "RPC endpoint")
	blockNum := flag.Int64("block", -1, "block number (-1 = latest)")
	flag.Parse()

	// EDUCATIONAL NOTES:
	// - Mini explorer: prints header + tx summaries (to/value/gasPrice).
	// - Extend with receipts/logs (module 15) or traces (module 13) for deeper inspection.
	// - Analogy: flipping to a specific ledger page and reading every line item.

	ctx, cancel := context.WithTimeout(context.Background(), 12*time.Second)
	defer cancel()

	client, err := ethclient.DialContext(ctx, *rpc)
	if err != nil {
		log.Fatalf("dial: %v", err)
	}
	defer client.Close()

	var num *big.Int
	if *blockNum >= 0 {
		num = big.NewInt(*blockNum)
	}
	block, err := client.BlockByNumber(ctx, num)
	if err != nil {
		log.Fatalf("block: %v", err)
	}

	fmt.Printf("Block #%d hash=%s parent=%s txs=%d gasUsed=%d\n", block.NumberU64(), block.Hash(), block.ParentHash(), len(block.Transactions()), block.GasUsed())
	for i, tx := range block.Transactions() {
		fmt.Printf("  [%d] %s to=%v value=%s wei gasPrice=%s\n", i, tx.Hash(), tx.To(), tx.Value().String(), tx.GasPrice().String())
	}

	// Commentary:
	// - This is a mini block explorer: shows block header and each tx summary.
	// - You can extend to fetch receipts/logs (module 15) or traces (module 13).
	// Analogy: flipping to a specific ledger page and reading every entry.
}
