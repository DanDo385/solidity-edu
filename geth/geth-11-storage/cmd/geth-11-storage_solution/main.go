package main

import (
	"context"
	"crypto/sha3"
	"encoding/hex"
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
		defaultRPC = "https://mainnet.infura.io/v3/INFURA_RPC_URL"
	}
	rpc := flag.String("rpc", defaultRPC, "RPC endpoint")
	contractHex := flag.String("contract", "", "contract address")
	slot := flag.Uint64("slot", 0, "storage slot index")
	mapKey := flag.String("mapkey", "", "optional mapping key (address)")
	timeout := flag.Duration("timeout", 8*time.Second, "timeout")
	flag.Parse()

	if *contractHex == "" {
		log.Fatal("usage: -contract <addr> -slot <n> [-mapkey addr]")
	}

	ctx, cancel := context.WithTimeout(context.Background(), *timeout)
	defer cancel()

	client, err := ethclient.DialContext(ctx, *rpc)
	if err != nil {
		log.Fatalf("dial: %v", err)
	}
	defer client.Close()

	addr := common.HexToAddress(*contractHex)
	slotHash := common.BigToHash(new(big.Int).SetUint64(*slot))

	raw, err := client.StorageAt(ctx, addr, slotHash.Bytes(), nil)
	if err != nil {
		log.Fatalf("storage: %v", err)
	}
	fmt.Printf("slot %d raw: 0x%s\n", *slot, hex.EncodeToString(raw))

	if *mapKey != "" {
		key := common.HexToAddress(*mapKey)
		h := sha3.NewLegacyKeccak256()
		h.Write(common.LeftPadBytes(key.Bytes(), 32))
		h.Write(common.LeftPadBytes(slotHash.Bytes(), 32))
		mapSlot := h.Sum(nil)

		mapVal, err := client.StorageAt(ctx, addr, mapSlot, nil)
		if err != nil {
			log.Fatalf("map storage: %v", err)
		}
		fmt.Printf("mapping[%s] slot=0x%s raw=0x%s\n", key.Hex(), hex.EncodeToString(mapSlot), hex.EncodeToString(mapVal))
	}

	// Commentary:
	// - Simple variables sit at declared slot numbers.
	// - mappings use keccak(key, slot) for storage location.
	// - dynamic arrays use keccak(slot) as base, then index offset.
	// Analogy: slots are numbered lockers; mappings compute locker number from key + aisle.
}
