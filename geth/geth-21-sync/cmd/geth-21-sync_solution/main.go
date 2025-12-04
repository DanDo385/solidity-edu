package main

import (
    "context"
    "flag"
    "fmt"
    "log"
    "time"

    "github.com/ethereum/go-ethereum/ethclient"
)

func main() {
    rpc := flag.String("rpc", "http://localhost:8545", "RPC (ideally your own node)")
    timeout := flag.Duration("timeout", 5*time.Second, "timeout")
    flag.Parse()

    // EDUCATIONAL NOTES:
    // - SyncProgress nil => node thinks it's caught up. Otherwise, watch Current vs Highest and state heal counters.
    // - Sync modes: snap grabs snapshot + heals; full replays everything; light fetches proofs on demand.
    // - Analogy: downloading a city archive (snapshot) then filling missing pages (healing).
    ctx, cancel := context.WithTimeout(context.Background(), *timeout)
    defer cancel()

    client, err := ethclient.DialContext(ctx, *rpc)
    if err != nil {
        log.Fatalf("dial: %v", err)
    }
    defer client.Close()

    progress, err := client.SyncProgress(ctx)
    if err != nil {
        log.Fatalf("syncProgress: %v", err)
    }

    if progress == nil {
        fmt.Println("✅ synced (no active sync)")
        return
    }

    fmt.Printf("⏳ syncing: currentBlock=%d highestBlock=%d pulledStates=%d knownStates=%d\n",
        progress.CurrentBlock, progress.HighestBlock, progress.PulledStates, progress.KnownStates)

    // Commentary:
    // - Full vs snap vs light: snap grabs snapshots then heals; full replays everything; light fetches proofs on demand.
    // - SyncProgress nil means fully synced.
    // Analogy: downloading a city archive (snap) then filling missing pages (healing).
}
