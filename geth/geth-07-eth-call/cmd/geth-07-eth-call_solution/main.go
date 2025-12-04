package main

import (
    "context"
    "encoding/hex"
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
    contractHex := flag.String("contract", "", "contract address (e.g., ERC20)")
    fn := flag.String("fn", "name", "view function to call (e.g., name, symbol, decimals)")
    timeout := flag.Duration("timeout", 8*time.Second, "timeout")
    flag.Parse()

    if *contractHex == "" {
        log.Fatal("usage: -contract <addr> [-fn name|symbol|decimals]")
    }

    ctx, cancel := context.WithTimeout(context.Background(), *timeout)
    defer cancel()

    client, err := ethclient.DialContext(ctx, *rpc)
    if err != nil {
        log.Fatalf("dial: %v", err)
    }
    defer client.Close()

    // Minimal ERC20 ABI for common view functions.
    const erc20ABI = `[
        {"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"type":"function"},
        {"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"type":"function"},
        {"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"type":"function"},
        {"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"type":"function"}
    ]`

    parsed, err := abi.JSON(strings.NewReader(erc20ABI))
    if err != nil {
        log.Fatalf("abi parse: %v", err)
    }

    // Encode the function selector + args (no args for these view functions).
    data, err := parsed.Pack(*fn)
    if err != nil {
        log.Fatalf("abi pack: %v", err)
    }

    to := common.HexToAddress(*contractHex)
    callMsg := ethereum.CallMsg{To: &to, Data: data}

    // Perform eth_call at latest block (nil).
    raw, err := client.CallContract(ctx, callMsg, nil)
    if err != nil {
        log.Fatalf("eth_call: %v", err)
    }

    // Decode based on selected function.
    switch *fn {
    case "name", "symbol":
        var out string
        if err := parsed.UnpackIntoInterface(&out, *fn, raw); err != nil {
            log.Fatalf("unpack: %v", err)
        }
        fmt.Printf("%s(): %s\n", *fn, out)
    case "decimals":
        var out uint8
        if err := parsed.UnpackIntoInterface(&out, *fn, raw); err != nil {
            log.Fatalf("unpack: %v", err)
        }
        fmt.Printf("decimals(): %d\n", out)
    case "totalSupply":
        var out *big.Int
        if err := parsed.UnpackIntoInterface(&out, *fn, raw); err != nil {
            log.Fatalf("unpack: %v", err)
        }
        fmt.Printf("totalSupply(): %s\n", out.String())
    default:
        fmt.Printf("raw hex: %s\n", hex.EncodeToString(raw))
    }

    // Commentary / nerdy bits:
    // - eth_call is read-only; no gas spent on-chain, but the node simulates the EVM.
    // - Manual ABI packing mirrors ethers.js contract.populateTransaction().
    // - Reverts surface as errors; revert data may contain an error string—inspect raw bytes when needed.
    // - CPU analogy: read-only syscall that inspects memory/state without committing writes.
    // - Analogy: asking the contract clerk to read a value without recording anything in the ledger.
}
