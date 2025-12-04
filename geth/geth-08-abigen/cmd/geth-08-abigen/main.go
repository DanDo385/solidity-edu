package main

import (
    "context"
    "flag"
    "fmt"
    "log"
    "math/big"
    "os"
    "strings"
    "time"

    "github.com/ethereum/go-ethereum/accounts/abi"
    "github.com/ethereum/go-ethereum/accounts/abi/bind"
    "github.com/ethereum/go-ethereum/common"
    "github.com/ethereum/go-ethereum/ethclient"
)

const erc20ABI = `[{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"type":"function"},{"constant":true,"inputs":[{"name":"owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"","type":"uint256"}],"type":"function"}]`

func main() {
    defaultRPC := os.Getenv("INFURA_RPC_URL")
    if defaultRPC == "" {
        defaultRPC = "https://mainnet.infura.io/v3/YOUR_KEY"
    }
    rpc := flag.String("rpc", defaultRPC, "RPC endpoint")
    tokenHex := flag.String("token", "", "ERC20 address")
    holderHex := flag.String("holder", "", "address to query balance for")
    timeout := flag.Duration("timeout", 8*time.Second, "timeout")
    flag.Parse()

    if *tokenHex == "" {
        log.Fatal("usage: -token <erc20 address> [-holder addr]")
    }

    ctx, cancel := context.WithTimeout(context.Background(), *timeout)
    defer cancel()

    client, err := ethclient.DialContext(ctx, *rpc)
    if err != nil { log.Fatalf("dial: %v", err) }
    defer client.Close()

    parsed, err := abi.JSON(strings.NewReader(erc20ABI))
    if err != nil { log.Fatalf("abi parse: %v", err) }
    token := common.HexToAddress(*tokenHex)
    bound := bind.NewBoundContract(token, parsed, client, client, client)

    // Call name/symbol/decimals using typed output containers.
    var name, symbol string
    var decimals uint8
    if err := bound.Call(&bind.CallOpts{Context: ctx}, &name, "name"); err != nil { log.Fatalf("name: %v", err) }
    if err := bound.Call(&bind.CallOpts{Context: ctx}, &symbol, "symbol"); err != nil { log.Fatalf("symbol: %v", err) }
    if err := bound.Call(&bind.CallOpts{Context: ctx}, &decimals, "decimals"); err != nil { log.Fatalf("decimals: %v", err) }
    fmt.Printf("Token %s (%s) decimals=%d\n", name, symbol, decimals)

    if *holderHex != "" {
        holder := common.HexToAddress(*holderHex)
        var bal *big.Int
        if err := bound.Call(&bind.CallOpts{Context: ctx}, &bal, "balanceOf", holder); err != nil { log.Fatalf("balanceOf: %v", err) }
        fmt.Printf("balanceOf(%s) = %s\n", holder.Hex(), bal.String())
    }
}
