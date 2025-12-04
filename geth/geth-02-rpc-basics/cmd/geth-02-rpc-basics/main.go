package main

import (
    "context"
    "flag"
    "fmt"
    "log"
    "os"
    "time"

    "github.com/ethereum/go-ethereum/core/types"
    "github.com/ethereum/go-ethereum/ethclient"
)

func main() {
    defaultRPC := os.Getenv("INFURA_RPC_URL")
    if defaultRPC == "" {
        defaultRPC = "https://mainnet.infura.io/v3/YOUR_KEY"
    }
    rpcURL := flag.String("rpc", defaultRPC, "RPC endpoint (uses INFURA_RPC_URL if set)")
    timeout := flag.Duration("timeout", 5*time.Second, "RPC timeout")
    retries := flag.Int("retries", 1, "block fetch retries")
    flag.Parse()

    ctx, cancel := context.WithTimeout(context.Background(), *timeout)
    defer cancel()

    client, err := ethclient.DialContext(ctx, *rpcURL)
    if err != nil {
        log.Fatalf("dial failed: %v", err)
    }
    defer client.Close()

    height, err := client.BlockNumber(ctx)
    if err != nil {
        log.Fatalf("blockNumber failed: %v", err)
    }
    netID, err := client.NetworkID(ctx)
    if err != nil {
        log.Fatalf("net_version failed: %v", err)
    }

    var block *types.Block
    var lastErr error
    for i := 0; i <= *retries; i++ {
        block, lastErr = client.BlockByNumber(ctx, nil)
        if lastErr == nil {
            break
        }
        time.Sleep(100 * time.Millisecond)
    }
    if lastErr != nil {
        log.Fatalf("get block failed: %v", lastErr)
    }

    fmt.Printf("RPC basics\n net_version=%s height=%d latest=%d hash=%s parent=%s txs=%d gasUsed=%d\n",
        netID.String(), height, block.NumberU64(), block.Hash(), block.ParentHash(), len(block.Transactions()), block.GasUsed())
}
