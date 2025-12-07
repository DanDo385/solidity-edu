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

// ============================================================
// ERC20 ABI: Contract Interface Definition
// ============================================================
// Minimal ERC20 ABI used to build a bound contract at runtime.
// In production, abigen would generate typed bindings from this ABI.
//
// This ABI includes view functions:
// - name(): Returns token name
// - symbol(): Returns token symbol
// - decimals(): Returns decimal places
// - totalSupply(): Returns total supply
// - balanceOf(address): Returns balance for an address
const erc20ABI = `[
	{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"type":"function"},
	{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"type":"function"},
	{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"type":"function"},
	{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"type":"function"},
	{"constant":true,"inputs":[{"name":"owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"","type":"uint256"}],"type":"function"}
]`

// ============================================================
// ERC20Binding: Typed Contract Binding
// ============================================================
// ERC20Binding simulates what abigen would generate: typed methods
// wrapping BoundContract.
//
// Computer Science principle: This is the adapter pattern - wrapping
// low-level RPC calls with a high-level, type-safe interface.
//
// In production, abigen would generate this code automatically:
//   abigen --abi erc20.abi --pkg erc20 --out erc20.go
type ERC20Binding struct {
	contract *bind.BoundContract
}

// ============================================================
// newERC20: Creating Typed Binding from ABI
// ============================================================
// Creates a new ERC20Binding from address and backend.
//
// bind.NewBoundContract creates a BoundContract that provides:
// - Call(): For view functions (read-only)
// - Transact(): For state-changing functions (write)
// - FilterLogs(): For event queries
//
// Parameters:
// - addr: Contract address
// - backend: RPC client (implements bind.ContractBackend)
//
// Computer Science principle: BoundContract is like a database
// connection + schema. It knows the contract's interface (ABI)
// and can encode/decode calls automatically.
func newERC20(addr common.Address, backend bind.ContractBackend) (*ERC20Binding, error) {
	parsed, err := abi.JSON(strings.NewReader(erc20ABI))
	if err != nil {
		return nil, err
	}
	return &ERC20Binding{
		contract: bind.NewBoundContract(addr, parsed, backend, backend, backend),
	}, nil
}

// ============================================================
// Name: Typed Method for name() Function
// ============================================================
// Calls the name() view function and returns the token name.
//
// bind.CallOpts carries:
// - Context: For cancellation/timeouts
// - BlockNumber: Which block to query (nil = latest)
// - From: Optional sender address (for view functions that check msg.sender)
//
// Computer Science principle: Typed methods provide compile-time
// type safety. Wrong return type = compile error, not runtime error.
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

// Symbol: Typed method for symbol() function
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

// Decimals: Typed method for decimals() function
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

// BalanceOf: Typed method for balanceOf(address) function
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
	// ============================================================
	// CONFIGURATION: Flags for Token Query Parameters
	// ============================================================
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

	// ============================================================
	// CONTEXT WITH TIMEOUT: Preventing Hanging Forever
	// ============================================================
	ctx, cancel := context.WithTimeout(context.Background(), *timeout)
	defer cancel()

	// ============================================================
	// DIALING THE RPC ENDPOINT: Establishing Connection
	// ============================================================
	client, err := ethclient.DialContext(ctx, *rpc)
	if err != nil {
		log.Fatalf("dial: %v", err)
	}
	defer client.Close()

	// ============================================================
	// CREATING TYPED BINDING: From Address and Backend
	// ============================================================
	// Convert token address and create typed binding.
	// This binding provides type-safe methods for calling contract functions.
	tokenAddr := common.HexToAddress(*tokenHex)
	binding, err := newERC20(tokenAddr, client)
	if err != nil {
		log.Fatalf("binding: %v", err)
	}

	// ============================================================
	// CALLING TYPED METHODS: Type-Safe Contract Calls
	// ============================================================
	// Call typed methods - much simpler than manual ABI encoding!
	// Compare to module 07 where we had to manually pack/unpack.
	//
	// Benefits:
	// - Compile-time type safety
	// - Less boilerplate
	// - Better IDE autocomplete
	// - Easier to read and maintain
	name, _ := binding.Name(ctx)
	symbol, _ := binding.Symbol(ctx)
	decimals, _ := binding.Decimals(ctx)
	fmt.Printf("Token %s (%s) decimals=%d\n", name, symbol, decimals)

	// ============================================================
	// QUERYING BALANCE: Using Typed Method with Arguments
	// ============================================================
	// If holder address is provided, query balance using typed method.
	// Notice how clean this is compared to manual ABI encoding!
	if *holderHex != "" {
		holder := common.HexToAddress(*holderHex)
		bal, err := binding.BalanceOf(ctx, holder)
		if err != nil {
			log.Fatalf("balanceOf: %v", err)
		}
		fmt.Printf("balanceOf(%s) = %s\n", holder.Hex(), bal.String())
	}

	// ============================================================
	// EDUCATIONAL NOTES & COMPARISONS
	// ============================================================
	//
	// Building on module 07:
	// - Module 07: Manual ABI encoding/decoding (full control, more boilerplate)
	// - This module: Typed bindings (type-safe, less boilerplate)
	// - Same underlying JSON-RPC calls, better ergonomics
	//
	// Key concepts:
	// - BoundContract wraps ABI + address + backend
	// - CallOpts for read operations (lightweight)
	// - TransactOpts for write operations (includes signing)
	// - Typed methods provide compile-time type safety
	//
	// Comparisons:
	// - Manual ABI vs Typed Bindings: Manual gives control, bindings give safety
	// - CallOpts vs TransactOpts: CallOpts is lightweight, TransactOpts includes signing
	//
	// Real-world analogies:
	// - Typed bindings = labeled remote control buttons
	// - Manual ABI = raw hex payloads
	// - BoundContract = remote control itself
	//
	// Production tips:
	// - Use abigen to generate bindings from ABI files
	// - Typed bindings catch errors at compile time
	// - Less boilerplate = fewer bugs
	//
	// Next steps (module 09):
	// - You'll learn to decode ERC20 Transfer events
	// - Understand topics vs data in logs
	// - Filter events by block range
	// - See how events complement function calls
}
