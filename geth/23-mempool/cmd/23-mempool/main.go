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

func main() {
    rpc := flag.String("rpc", "http://localhost:8545", "RPC (needs pending tx support)")
    limit := flag.Int("n", 5, "max pending to show")
    timeout := flag.Duration("timeout", 5*time.Second, "timeout")
    flag.Parse()

    ctx, cancel := context.WithTimeout(context.Background(), *timeout)
    defer cancel()

    client, err := ethclient.DialContext(ctx, *rpc)
    if err != nil { log.Fatalf("dial: %v", err) }
    defer client.Close()

    var pend []map[string]interface{}
    if err := client.Client().CallContext(ctx, &pend, "eth_pendingTransactions"); err != nil {
        log.Fatalf("pendingTransactions failed: %v", err)
    }

    fmt.Printf("Pending txs (up to %d):\n", *limit)
    for i, item := range pend {
        if i >= *limit { break }
        hashHex, _ := item["hash"].(string)
        toHex, _ := item["to"].(string)
        fmt.Printf("  %d) %s -> %s\n", i, hashHex, toHex)
    }
    _ = common.Hash{}
}
