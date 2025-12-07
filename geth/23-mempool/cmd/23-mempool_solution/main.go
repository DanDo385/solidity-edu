package main

import (
    "context"
    "flag"
    "fmt"
    "log"
    "time"

    "github.com/ethereum/go-ethereum/common"
    "github.com/ethereum/go-ethereum/ethclient"
)

// Note: pending tx visibility depends on node settings. Many public RPCs do not expose full mempool.
// Analogy: waiting room behind frosted glass—some venues let you peek, others don't.
// Nerdy: pending txs live in the txpool; nodes gossip them over p2p before inclusion.

func main() {
    rpc := flag.String("rpc", "http://localhost:8545", "RPC (needs txpool/pending support)")
    limit := flag.Int("n", 5, "max pending txs to show")
    timeout := flag.Duration("timeout", 5*time.Second, "timeout")
    flag.Parse()

    ctx, cancel := context.WithTimeout(context.Background(), *timeout)
    defer cancel()

    client, err := ethclient.DialContext(ctx, *rpc)
    if err != nil {
        log.Fatalf("dial: %v", err)
    }
    defer client.Close()

    // Try eth_pendingTransactions (not standard on all nodes).
    var pend []map[string]interface{}
    err = client.Client().CallContext(ctx, &pend, "eth_pendingTransactions")
    if err != nil {
        log.Fatalf("pendingTransactions call failed (node may not support): %v", err)
    }

    fmt.Printf("Pending txs (showing up to %d):\n", *limit)
    for i, item := range pend {
        if i >= *limit {
            break
        }
        hashHex, _ := item["hash"].(string)
        toHex, _ := item["to"].(string)
        fmt.Printf("  %d) %s -> %s\n", i, hashHex, toHex)
    }

    // Alternative: txpool_content (Geth) provides richer mempool view but requires enabling txpool API.
    // Analogy: peeking into the waiting room before transactions are written into a block.
    _ = common.Hash{}
}
