package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"time"

	"github.com/ethereum/go-ethereum/ethclient"
)

// EDUCATIONAL NOTES:
// - Head freshness is a key SLO: stale head => node is unhealthy or disconnected.
// - Simplistic lag estimate: timestamp vs wall clock; refine with known block times per network.
// - Analogy: vital signs monitor (heart rate = block cadence; temperature = latency).
func main() {
	rpc := flag.String("rpc", "http://localhost:8545", "RPC endpoint")
	maxLag := flag.Uint64("maxlag", 3, "max acceptable block lag")
	timeout := flag.Duration("timeout", 5*time.Second, "timeout")
	flag.Parse()

    ctx, cancel := context.WithTimeout(context.Background(), *timeout)
    defer cancel()

    client, err := ethclient.DialContext(ctx, *rpc)
    if err != nil {
        log.Fatalf("dial: %v", err)
    }
    defer client.Close()

    // Health check: fetch latest block number and timestamp.
    head, err := client.HeaderByNumber(ctx, nil)
    if err != nil {
        log.Fatalf("head: %v", err)
    }

    now := time.Now().Unix()
    lagBlocks := uint64(0)
    latestTs := head.Time
    // Rough check: if latest block timestamp is older than ~maxLag * 12s, flag.
    if now > int64(latestTs) {
        age := now - int64(latestTs)
        lagBlocks = uint64(age / 12)
    }

    status := "OK"
    if lagBlocks > *maxLag {
        status = "STALE"
    }

    fmt.Printf("status=%s block=%d ts=%d lagBlocks~%d\n", status, head.Number.Uint64(), head.Time, lagBlocks)

    // Commentary:
    // - Production: expose Prometheus metrics (head age, RPC latency, error counts).
    // - Alert when head age exceeds threshold or when error rate spikes.
    // Analogy: node vital signs dashboard (heart rate = block cadence; temperature = latency).
}
