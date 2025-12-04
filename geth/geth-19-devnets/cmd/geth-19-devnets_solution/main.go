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

// This module shows how to talk to a local devnet (e.g., anvil mainnet fork).
// We assume you started anvil: anvil --fork-url $INFURA_RPC_URL --fork-block-number N

// EDUCATIONAL NOTES:
// - Devnets let you fork state, impersonate accounts, and fund addresses freely.
// - Perfect for rehearsing transactions without risking mainnet value.
// - Analogy: movie set replica of the city ledger—practice safely.
func main() {
    rpc := flag.String("rpc", "http://127.0.0.1:8545", "devnet RPC (anvil)")
    who := flag.String("addr", "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266", "address to inspect (anvil default)")
    timeout := flag.Duration("timeout", 8*time.Second, "timeout")
    flag.Parse()

    ctx, cancel := context.WithTimeout(context.Background(), *timeout)
    defer cancel()

    client, err := ethclient.DialContext(ctx, *rpc)
    if err != nil {
        log.Fatalf("dial: %v", err)
    }
    defer client.Close()

    addr := common.HexToAddress(*who)
    bal, err := client.BalanceAt(ctx, addr, nil)
    if err != nil {
        log.Fatalf("balance: %v", err)
    }
    head, _ := client.BlockNumber(ctx)
    fmt.Printf("devnet %s: balance=%s wei head=%d\n", addr.Hex(), bal.String(), head)

    // Commentary:
    // - Anvil forks mainnet state; you can impersonate accounts with `anvil --impersonate <addr>`.
    // - Compare flows: Geth dev node vs Anvil vs Hardhat; all expose JSON-RPC but differ in extras.
    // - Use devnets to safely test tx flows without real funds.
    // Analogy: a movie set replica of the city ledger where you can rehearse actions.
}
