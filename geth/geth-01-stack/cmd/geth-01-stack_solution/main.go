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
	// Flags keep this CLI flexible: swap endpoints without recompiling.
	defaultRPC := os.Getenv("INFURA_RPC_URL")
	if defaultRPC == "" {
		defaultRPC = "https://mainnet.infura.io/v3/INFURA_RPC_URL" // fallback if env not set
	}
	rpcURL := flag.String("rpc", defaultRPC, "RPC endpoint (HTTP/WS). Uses INFURA_RPC_URL if set.")
	timeout := flag.Duration("timeout", 5*time.Second, "RPC call timeout")
	flag.Parse()

	// Context with timeout: prevents hanging forever on slow/broken RPCs.
	ctx, cancel := context.WithTimeout(context.Background(), *timeout)
	defer cancel()

	// ethclient.DialContext opens a JSON-RPC connection (HTTP/WS depending on URL).
	client, err := ethclient.DialContext(ctx, *rpcURL)
	if err != nil {
		log.Fatalf("dial failed: %v", err)
	}
	defer client.Close()

	// ChainID is from EIP-155; used for replay protection in tx signing.
	chainID, err := client.ChainID(ctx)
	if err != nil {
		log.Fatalf("chainId failed: %v", err)
	}

	// NetworkID maps to net_version (legacy). Often same as chainID, but not guaranteed.
	netID, err := client.NetworkID(ctx)
	if err != nil {
		log.Fatalf("net_version failed: %v", err)
	}

	// Latest header: nil means "tip". Header is cheaper than full block (no tx bodies).
	head, err := client.HeaderByNumber(ctx, nil)
	if err != nil {
		log.Fatalf("header fetch failed: %v", err)
	}

	fmt.Printf("✅ RPC ok\n  chainId:   %s\n  net_version: %s\n  head:      #%d hash=%s parent=%s\n",
		chainID.String(), netID.String(), head.Number.Uint64(), head.Hash(), head.ParentHash)

	// Comparisons:
	// - JS ethers.js: provider.getNetwork() -> chainId, provider.getBlockNumber(), provider.getBlock("latest")
	// - Geth vs hosted RPC: hosted endpoints may rate-limit or omit debug/admin; run your own for full power.
	//
	// Analogy:
	// - chainId is the "city ID" stamped on every official ledger page to stop cross-city replay.
	// - The header is the page header with seals (hash) and link to previous page (parentHash).
}
