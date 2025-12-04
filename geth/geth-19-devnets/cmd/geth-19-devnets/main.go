package main

import (
    "context"
    "flag"
    "fmt"
    "log"
    "math/big"
    "os"
    "time"

    "github.com/ethereum/go-ethereum/common"
    "github.com/ethereum/go-ethereum/ethclient"
)

func main() {
    rpc := flag.String("rpc", "http://127.0.0.1:8545", "devnet RPC (anvil)")
    who := flag.String("addr", "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266", "address to inspect")
    timeout := flag.Duration("timeout", 8*time.Second, "timeout")
    flag.Parse()

    ctx, cancel := context.WithTimeout(context.Background(), *timeout)
    defer cancel()

    client, err := ethclient.DialContext(ctx, *rpc)
    if err != nil { log.Fatalf("dial: %v", err) }
    defer client.Close()

    addr := common.HexToAddress(*who)
    bal, err := client.BalanceAt(ctx, addr, nil)
    if err != nil { log.Fatalf("balance: %v", err) }
    head, _ := client.BlockNumber(ctx)
    fmt.Printf("devnet %s balance=%s head=%d\n", addr.Hex(), bal.String(), head)
}
