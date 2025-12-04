package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"math/big"
	"os"
	"sync"
	"time"

	"github.com/ethereum/go-ethereum/ethclient"
)

func main() {
	defaultRPC := os.Getenv("INFURA_RPC_URL")
	if defaultRPC == "" {
		defaultRPC = "https://mainnet.infura.io/v3/YOUR_KEY"
	}
	rpc := flag.String("rpc", defaultRPC, "RPC endpoint")
	start := flag.Int64("start", 0, "start block")
	count := flag.Int64("count", 5, "number of blocks to fetch concurrently")
	workers := flag.Int("workers", 3, "concurrent workers")
	flag.Parse()

	// EDUCATIONAL NOTES:
	// - Worker pools help fan-out requests; add rate limiting/backoff to respect provider limits.
	// - Context cancellation stops workers on timeout.
	// - Analogy: multiple clerks fetching ledger pages in parallel to speed up research.
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	client, err := ethclient.DialContext(ctx, *rpc)
	if err != nil {
		log.Fatalf("dial: %v", err)
	}
	defer client.Close()

	type job struct{ num uint64 }
	jobs := make(chan job)
	wg := sync.WaitGroup{}

	// Worker pool: fetch block headers concurrently.
	for i := 0; i < *workers; i++ {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()
			for j := range jobs {
				h, err := client.HeaderByNumber(ctx, new(big.Int).SetUint64(j.num))
				if err != nil {
					log.Printf("worker %d block %d err: %v", id, j.num, err)
					continue
				}
				fmt.Printf("worker %d got block %d hash=%s\n", id, j.num, h.Hash())
			}
		}(i)
	}

	for n := uint64(*start); n < uint64(*start+*count); n++ {
		jobs <- job{num: n}
	}
	close(jobs)
	wg.Wait()

	// Commentary:
	// - Context propagates cancellation; if timeout hits, calls abort.
	// - Add rate limiting/backoff for noisy RPCs in production.
	// Analogy: multiple clerks fetching ledger pages in parallel to speed up research.
}
