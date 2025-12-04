package main

import (
    "context"
    "flag"
    "fmt"
    "log"
    "os"
    "time"

    "github.com/ethereum/go-ethereum/common"
    "github.com/ethereum/go-ethereum/ethclient"
)

func main() {
    defaultRPC := os.Getenv("INFURA_RPC_URL")
    if defaultRPC == "" { defaultRPC = "https://mainnet.infura.io/v3/YOUR_KEY" }
    rpc := flag.String("rpc", defaultRPC, "RPC endpoint")
    flag.Parse()

    hashes := flag.Args()
    if len(hashes) == 0 { log.Fatal("usage: <txHash> [txHash...]") }

    ctx, cancel := context.WithTimeout(context.Background(), 12*time.Second)
    defer cancel()

    client, err := ethclient.DialContext(ctx, *rpc)
    if err != nil { log.Fatalf("dial: %v", err) }
    defer client.Close()

    for _, h := range hashes {
        r, err := client.TransactionReceipt(ctx, common.HexToHash(h))
        if err != nil { log.Fatalf("receipt %s: %v", h, err) }
        status := "FAIL"
        if r.Status == 1 { status = "OK" }
        fmt.Printf("tx=%s status=%s gasUsed=%d logs=%d block=%d\n", h, status, r.GasUsed, len(r.Logs), r.BlockNumber.Uint64())
    }
}
