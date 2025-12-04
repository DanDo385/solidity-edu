package main

import (
    "context"
    "flag"
    "fmt"
    "log"
    "os"
    "time"

    "github.com/ethereum/go-ethereum/ethclient"
)

func main() {
    defaultRPC := os.Getenv("INFURA_RPC_URL")
    if defaultRPC == "" {
        defaultRPC = "https://mainnet.infura.io/v3/YOUR_KEY"
    }
    rpcURL := flag.String("rpc", defaultRPC, "RPC endpoint (HTTP/WS). Uses INFURA_RPC_URL if set.")
    timeout := flag.Duration("timeout", 5*time.Second, "RPC call timeout")
    flag.Parse()

    ctx, cancel := context.WithTimeout(context.Background(), *timeout)
    defer cancel()

    client, err := ethclient.DialContext(ctx, *rpcURL)
    if err != nil {
        log.Fatalf("dial failed: %v", err)
    }
    defer client.Close()

    chainID, err := client.ChainID(ctx)
    if err != nil {
        log.Fatalf("chainId failed: %v", err)
    }
    netID, err := client.NetworkID(ctx)
    if err != nil {
        log.Fatalf("net_version failed: %v", err)
    }
    head, err := client.HeaderByNumber(ctx, nil)
    if err != nil {
        log.Fatalf("header fetch failed: %v", err)
    }

    fmt.Printf("RPC ok\n chainId=%s net=%s head=%d hash=%s parent=%s\n",
        chainID.String(), netID.String(), head.Number.Uint64(), head.Hash(), head.ParentHash)
}
