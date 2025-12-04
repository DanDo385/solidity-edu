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
    if defaultRPC == "" {
        defaultRPC = "https://mainnet.infura.io/v3/YOUR_KEY"
    }
    rpc := flag.String("rpc", defaultRPC, "RPC endpoint")
    timeout := flag.Duration("timeout", 8*time.Second, "timeout")
    flag.Parse()

    addrs := flag.Args()
    if len(addrs) == 0 {
        log.Fatal("usage: <addr1> <addr2> ...")
    }

    ctx, cancel := context.WithTimeout(context.Background(), *timeout)
    defer cancel()

    client, err := ethclient.DialContext(ctx, *rpc)
    if err != nil {
        log.Fatalf("dial: %v", err)
    }
    defer client.Close()

    for _, raw := range addrs {
        addr := common.HexToAddress(raw)
        bal, err := client.BalanceAt(ctx, addr, nil)
        if err != nil {
            log.Fatalf("balance %s: %v", addr.Hex(), err)
        }
        code, err := client.CodeAt(ctx, addr, nil)
        if err != nil {
            log.Fatalf("code %s: %v", addr.Hex(), err)
        }
        kind := "EOA"
        if len(code) > 0 {
            kind = "Contract"
        }
        fmt.Printf("%s type=%s balance=%s wei\n", addr.Hex(), kind, bal.String())
    }
}
