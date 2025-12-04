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

// Minimal ERC20 ABI used to build a bound contract at runtime (abigen would normally generate code).
const erc20ABI = `[
    {"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"type":"function"},
    {"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"type":"function"},
    {"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"type":"function"},
    {"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"type":"function"},
    {"constant":true,"inputs":[{"name":"owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"","type":"uint256"}],"type":"function"}
]`

// ERC20Binding simulates what abigen would generate: typed methods wrapping BoundContract.
type ERC20Binding struct {
    contract *bind.BoundContract
}

func newERC20(addr common.Address, backend bind.ContractBackend) (*ERC20Binding, error) {
    parsed, err := abi.JSON(strings.NewReader(erc20ABI))
    if err != nil {
        return nil, err
    }
    return &ERC20Binding{contract: bind.NewBoundContract(addr, parsed, backend, backend, backend)}, nil
}

func (e *ERC20Binding) Name(ctx context.Context) (string, error) {
    var out []interface{}
    err := e.contract.Call(&bind.CallOpts{Context: ctx}, &out, "name")
    if err != nil {
        return "", err
    }
    if len(out) == 1 {
        if s, ok := out[0].(string); ok {
            return s, nil
        }
    }
    return "", fmt.Errorf("unexpected type for name")
}

func (e *ERC20Binding) Symbol(ctx context.Context) (string, error) {
    var out []interface{}
    err := e.contract.Call(&bind.CallOpts{Context: ctx}, &out, "symbol")
    if err != nil {
        return "", err
    }
    if len(out) == 1 {
        if s, ok := out[0].(string); ok {
            return s, nil
        }
    }
    return "", fmt.Errorf("unexpected type for symbol")
}

func (e *ERC20Binding) Decimals(ctx context.Context) (uint8, error) {
    var out []interface{}
    err := e.contract.Call(&bind.CallOpts{Context: ctx}, &out, "decimals")
    if err != nil {
        return 0, err
    }
    if len(out) == 1 {
        switch v := out[0].(type) {
        case uint8:
            return v, nil
        case uint64:
            return uint8(v), nil
        case *big.Int:
            return uint8(v.Uint64()), nil
        }
    }
    return 0, fmt.Errorf("unexpected type for decimals")
}

func (e *ERC20Binding) BalanceOf(ctx context.Context, owner common.Address) (*big.Int, error) {
    var out []interface{}
    err := e.contract.Call(&bind.CallOpts{Context: ctx}, &out, "balanceOf", owner)
    if err != nil {
        return nil, err
    }
    if len(out) == 1 {
        if b, ok := out[0].(*big.Int); ok {
            return b, nil
        }
    }
    return nil, fmt.Errorf("unexpected type for balance")
}

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
    if err != nil {
        log.Fatalf("dial: %v", err)
    }
    defer client.Close()

    tokenAddr := common.HexToAddress(*tokenHex)
    binding, err := newERC20(tokenAddr, client)
    if err != nil {
        log.Fatalf("binding: %v", err)
    }

    name, _ := binding.Name(ctx)
    symbol, _ := binding.Symbol(ctx)
    decimals, _ := binding.Decimals(ctx)
    fmt.Printf("Token %s (%s) decimals=%d\n", name, symbol, decimals)

    if *holderHex != "" {
        holder := common.HexToAddress(*holderHex)
        bal, err := binding.BalanceOf(ctx, holder)
        if err != nil {
            log.Fatalf("balanceOf: %v", err)
        }
        fmt.Printf("balanceOf(%s) = %s\n", holder.Hex(), bal.String())
    }

    // Commentary:
    // - In real workflows, abigen generates these bindings automatically from ABI, giving compile-time safety.
    // - bind.CallOpts carries context and block number; bind.TransactOpts would include signer for txs.
    // - Compared to manual ABI packing, bindings reduce boilerplate and type errors.
    // - CPU analogy: typed bindings are like syscall stubs instead of writing raw opcodes.
    // - Analogy: a typed remote control with labeled buttons instead of raw hex payloads.
}
