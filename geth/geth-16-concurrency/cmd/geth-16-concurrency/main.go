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
    if defaultRPC == "" { defaultRPC = "https://mainnet.infura.io/v3/YOUR_KEY" }
    rpc := flag.String("rpc", defaultRPC, "RPC endpoint")
    start := flag.Int64("start", 0, "start block")
    count := flag.Int64("count", 5, "number of blocks")
    workers := flag.Int("workers", 3, "workers")
    flag.Parse()

    ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
    defer cancel()

    client, err := ethclient.DialContext(ctx, *rpc)
    if err != nil { log.Fatalf("dial: %v", err) }
    defer client.Close()

    jobs := make(chan uint64)
    wg := sync.WaitGroup{}

    for i := 0; i < *workers; i++ {
        wg.Add(1)
        go func(id int) {
            defer wg.Done()
            for n := range jobs {
                h, err := client.HeaderByNumber(ctx, new(big.Int).SetUint64(n))
                if err != nil {
                    log.Printf("worker %d block %d err: %v", id, n, err)
                    continue
                }
                fmt.Printf("worker %d got block %d hash=%s\n", id, n, h.Hash())
            }
        }(i)
    }

    for n := uint64(*start); n < uint64(*start+*count); n++ {
        jobs <- n
    }
    close(jobs)
    wg.Wait()
}
