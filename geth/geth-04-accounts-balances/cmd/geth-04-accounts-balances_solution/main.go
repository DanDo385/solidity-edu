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

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
)

// EDUCATIONAL NOTES:
// - EOAs have no code; contracts do. Detect via CodeAt length (precompiles also have code).
// - BalanceAt reads wei at a specific block (nil = latest). Big ints avoid overflow.
// - Builds on modules 01–02: now you know who is talking (addresses) and can classify them.
// - Analogy: empty plot (EOA) vs building with machinery (contract) on the same street (address).

func main() {
	defaultRPC := os.Getenv("INFURA_RPC_URL")
	if defaultRPC == "" {
		defaultRPC = "https://mainnet.infura.io/v3/INFURA_RPC_URLPC_URL"
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

		// BalanceAt returns wei at latest block (nil). big.Int keeps precision.
		bal, err := client.BalanceAt(ctx, addr, nil)
		if err != nil {
			log.Fatalf("balance %s: %v", addr.Hex(), err)
		}

		// CodeAt returns contract bytecode; length > 0 => contract account.
		code, err := client.CodeAt(ctx, addr, nil)
		if err != nil {
			log.Fatalf("code %s: %v", addr.Hex(), err)
		}

		kind := "EOA"
		if len(code) > 0 {
			kind = "Contract"
		}

		fmt.Printf("%s | type=%s | balance=%s wei\n", addr.Hex(), kind, bal.String())
	}

	// Comparisons:
	// - ethers.js: provider.getBalance(addr), provider.getCode(addr)
	// - code size 0 => likely EOA; >0 => contract (note: precompiles have code!)
	// Analogy:
	// - Empty plot (EOA, no code) vs building with machinery inside (contract code).
}
