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
    rpc := flag.String("rpc", "http://localhost:8545", "RPC endpoint")
    maxLag := flag.Uint64("maxlag", 3, "max acceptable block lag")
    timeout := flag.Duration("timeout", 5*time.Second, "timeout")
    flag.Parse()

    ctx, cancel := context.WithTimeout(context.Background(), *timeout)
    defer cancel()

    client, err := ethclient.DialContext(ctx, *rpc)
    if err != nil { log.Fatalf("dial: %v", err) }
    defer client.Close()

    head, err := client.HeaderByNumber(ctx, nil)
    if err != nil { log.Fatalf("head: %v", err) }

    now := time.Now().Unix()
    lagBlocks := uint64(0)
    if now > int64(head.Time) {
        lagBlocks = uint64((now - int64(head.Time)) / 12)
    }
    status := "OK"
    if lagBlocks > *maxLag { status = "STALE" }
    fmt.Printf("status=%s block=%d ts=%d lagBlocks~%d\n", status, head.Number.Uint64(), head.Time, lagBlocks)
}
