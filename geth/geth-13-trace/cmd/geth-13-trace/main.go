package main

import (
    "context"
    "encoding/json"
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
    if defaultRPC == "" { defaultRPC = "http://localhost:8545" }
    rpc := flag.String("rpc", defaultRPC, "RPC endpoint (needs debug_traceTransaction)")
    txHex := flag.String("tx", "", "tx hash")
    timeout := flag.Duration("timeout", 15*time.Second, "timeout")
    flag.Parse()

    if *txHex == "" { log.Fatal("usage: -tx <hash>") }

    ctx, cancel := context.WithTimeout(context.Background(), *timeout)
    defer cancel()

    client, err := ethclient.DialContext(ctx, *rpc)
    if err != nil { log.Fatalf("dial: %v", err) }
    defer client.Close()

    var result map[string]interface{}
    if err := client.Client().CallContext(ctx, &result, "debug_traceTransaction", common.HexToHash(*txHex), map[string]interface{}{}); err != nil {
        log.Fatalf("trace: %v", err)
    }
    pretty, _ := json.MarshalIndent(result, "", "  ")
    fmt.Printf("Trace for %s:\n%s\n", *txHex, pretty)
}
