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

// Note: debug_traceTransaction is not part of the standard eth namespace and may be disabled on hosted RPCs.

func main() {
    defaultRPC := os.Getenv("INFURA_RPC_URL")
    if defaultRPC == "" {
        defaultRPC = "http://localhost:8545" // debug usually local
    }
    rpc := flag.String("rpc", defaultRPC, "RPC endpoint (must support debug_traceTransaction)")
    txHex := flag.String("tx", "", "tx hash to trace")
    timeout := flag.Duration("timeout", 15*time.Second, "timeout")
    flag.Parse()

    if *txHex == "" {
        log.Fatal("usage: -tx <hash>")
    }

    ctx, cancel := context.WithTimeout(context.Background(), *timeout)
    defer cancel()

    client, err := ethclient.DialContext(ctx, *rpc)
    if err != nil {
        log.Fatalf("dial: %v", err)
    }
    defer client.Close()

    // Build raw RPC call (go-ethereum client does not wrap debug namespace helpers by default).
    var result map[string]interface{}
    // Tracer defaults: structLogs etc. Minimal example.
    err = client.Client().CallContext(ctx, &result, "debug_traceTransaction", common.HexToHash(*txHex), map[string]interface{}{})
    if err != nil {
        log.Fatalf("trace: %v", err)
    }

    pretty, _ := json.MarshalIndent(result, "", "  ")
    fmt.Printf("Trace for %s:\n%s\n", *txHex, pretty)

    // Commentary:
    // - Traces show call tree, opcodes, gas usage; invaluable for debugging and tooling.
    // - Hosted RPCs often disable debug_*; run your own node or anvil for tracing.
    // - Compare to Foundry traces: both walk the EVM execution, but formatting differs.
    // Analogy: flight recorder/black box of a transaction’s execution.
}
