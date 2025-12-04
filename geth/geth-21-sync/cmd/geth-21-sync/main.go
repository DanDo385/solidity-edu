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
    rpc := flag.String("rpc", "http://localhost:8545", "RPC (node)")
    timeout := flag.Duration("timeout", 5*time.Second, "timeout")
    flag.Parse()

    ctx, cancel := context.WithTimeout(context.Background(), *timeout)
    defer cancel()

    client, err := ethclient.DialContext(ctx, *rpc)
    if err != nil { log.Fatalf("dial: %v", err) }
    defer client.Close()

    progress, err := client.SyncProgress(ctx)
    if err != nil { log.Fatalf("syncProgress: %v", err) }
    if progress == nil {
        fmt.Println("synced")
        return
    }
    fmt.Printf("syncing current=%d highest=%d pulledStates=%d knownStates=%d\n", progress.CurrentBlock, progress.HighestBlock, progress.PulledStates, progress.KnownStates)
}
