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

    "github.com/ethereum/go-ethereum"
    "github.com/ethereum/go-ethereum/accounts/abi"
    "github.com/ethereum/go-ethereum/common"
    "github.com/ethereum/go-ethereum/ethclient"
)

func main() {
    defaultRPC := os.Getenv("INFURA_RPC_URL")
    if defaultRPC == "" {
        defaultRPC = "https://mainnet.infura.io/v3/YOUR_KEY"
    }
    rpc := flag.String("rpc", defaultRPC, "RPC endpoint")
    contractHex := flag.String("contract", "", "contract address")
    fn := flag.String("fn", "name", "view function: name|symbol|decimals|totalSupply")
    timeout := flag.Duration("timeout", 8*time.Second, "timeout")
    flag.Parse()

    if *contractHex == "" { log.Fatal("usage: -contract <addr> [-fn ...]") }

    ctx, cancel := context.WithTimeout(context.Background(), *timeout)
    defer cancel()

    client, err := ethclient.DialContext(ctx, *rpc)
    if err != nil { log.Fatalf("dial: %v", err) }
    defer client.Close()

    const erc20ABI = `[{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"type":"function"}]`
    parsed, err := abi.JSON(strings.NewReader(erc20ABI))
    if err != nil { log.Fatalf("abi parse: %v", err) }

    data, err := parsed.Pack(*fn)
    if err != nil { log.Fatalf("pack: %v", err) }

    to := common.HexToAddress(*contractHex)
    callMsg := ethereum.CallMsg{To: &to, Data: data}
    raw, err := client.CallContract(ctx, callMsg, nil)
    if err != nil { log.Fatalf("eth_call: %v", err) }

    switch *fn {
    case "name", "symbol":
        var out string
        if err := parsed.UnpackIntoInterface(&out, *fn, raw); err != nil { log.Fatalf("unpack: %v", err) }
        fmt.Printf("%s(): %s\n", *fn, out)
    case "decimals":
        var out uint8
        if err := parsed.UnpackIntoInterface(&out, *fn, raw); err != nil { log.Fatalf("unpack: %v", err) }
        fmt.Printf("decimals(): %d\n", out)
    case "totalSupply":
        var out *big.Int
        if err := parsed.UnpackIntoInterface(&out, *fn, raw); err != nil { log.Fatalf("unpack: %v", err) }
        fmt.Printf("totalSupply(): %s\n", out.String())
    default:
        fmt.Printf("raw hex: %x\n", raw)
    }
}
