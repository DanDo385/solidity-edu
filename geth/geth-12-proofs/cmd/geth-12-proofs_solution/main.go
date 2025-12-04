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
	defaultRPC := os.Getenv("INFURA_RPC_URL")
	if defaultRPC == "" {
		defaultRPC = "https://mainnet.infura.io/v3/YOUR_KEY"
	}
	rpc := flag.String("rpc", defaultRPC, "RPC endpoint (needs eth_getProof support)")
	accountHex := flag.String("account", "", "account to prove")
	slot := flag.Uint64("slot", 0, "storage slot to prove")
	block := flag.Int64("block", -1, "block number (-1=latest)")
	timeout := flag.Duration("timeout", 8*time.Second, "timeout")
	flag.Parse()

	if *accountHex == "" {
		log.Fatal("usage: -account <addr> [-slot N] [-block num]")
	}

	// EDUCATIONAL NOTES:
	// - eth_getProof returns Merkle Patricia trie proofs (account + storage). Think tamper-evident receipts.
	// - Light clients/bridges verify these without full state; ties to storage layout (module 11).
	// - Analogy: notarized receipt stapled to the ledger page proving your entry existed at that block.

	ctx, cancel := context.WithTimeout(context.Background(), *timeout)
	defer cancel()

	client, err := ethclient.DialContext(ctx, *rpc)
	if err != nil {
		log.Fatalf("dial: %v", err)
	}
	defer client.Close()

	addr := common.HexToAddress(*accountHex)
	slots := []string{}
	if flag.Lookup("slot") != nil {
		slots = []string{fmt.Sprintf("0x%x", *slot)}
	}

	var blockNum *big.Int
	if *block >= 0 {
		blockNum = big.NewInt(*block)
	}

	proof, err := client.GetProof(ctx, addr, slots, blockNum)
	if err != nil {
		log.Fatalf("getProof: %v", err)
	}

	fmt.Printf("Account proof for %s at block %v\n", addr.Hex(), blockNum)
	fmt.Printf("  balance=%s nonce=%d codeHash=%s storageHash=%s\n", proof.Balance.String(), proof.Nonce, proof.CodeHash.Hex(), proof.StorageHash.Hex())
	fmt.Printf("  accountProof (nodes): %d\n", len(proof.AccountProof))
	if len(proof.StorageProof) > 0 {
		sp := proof.StorageProof[0]
		fmt.Printf("  storage slot %s value=%s proofs=%d\n", sp.Key, sp.Value.String(), len(sp.Proof))
	}

	// Commentary:
	// - eth_getProof returns Merkle Patricia trie proofs; think of them as tamper-evident receipts.
	// - Light clients or bridges verify these proofs without full state.
	// - Hosted RPCs may not expose eth_getProof; use your own node when possible.
	// Analogy: a notarized receipt stapled to the ledger page showing your entry existed at that block.
}
