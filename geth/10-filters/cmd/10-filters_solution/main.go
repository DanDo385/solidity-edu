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
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/ethclient"
)

func main() {
	// ============================================================
	// CONFIGURATION: Flags for Subscription/Polling Mode
	// ============================================================
	// Building on previous modules: Same pattern for reading RPC URL.
	//
	// New in this module:
	// - WebSocket mode flag (-ws): Use WebSocket subscriptions
	// - Blocks flag (-blocks): Number of blocks to poll (HTTP fallback)
	defaultRPC := os.Getenv("INFURA_RPC_URL")
	if defaultRPC == "" {
		defaultRPC = "https://mainnet.infura.io/v3/YOUR_KEY"
	}
	rpc := flag.String("rpc", defaultRPC, "RPC endpoint")
	ws := flag.Bool("ws", false, "treat RPC as websocket for subscriptions")
	blocks := flag.Int("blocks", 3, "how many latest blocks to poll (fallback)")
	flag.Parse()

	// ============================================================
	// DIALING THE RPC ENDPOINT: WebSocket or HTTP
	// ============================================================
	// Use Dial() (not DialContext) for WebSocket support.
	// Dial() can handle both HTTP and WebSocket URLs.
	//
	// URL formats:
	// - HTTP: "https://mainnet.infura.io/v3/YOUR_KEY"
	// - WebSocket: "wss://mainnet.infura.io/v3/YOUR_KEY"
	//
	// Computer Science principle: WebSocket provides persistent
	// connection for push-based updates, HTTP provides request-response.
	client, err := ethclient.Dial(*rpc)
	if err != nil {
		log.Fatalf("dial: %v", err)
	}
	defer client.Close()

	// ============================================================
	// WEBSOCKET MODE: Real-Time Subscriptions
	// ============================================================
	// If WebSocket mode, subscribe to new block headers.
	// This provides real-time updates as new blocks are mined.
	if *ws {
		// Create channel for receiving headers
		// Channels are Go's way of communicating between goroutines
		heads := make(chan *types.Header)

		// Subscribe to new heads (WebSocket only)
		// SubscribeNewHead returns a Subscription that sends headers
		// to the channel as they arrive
		//
		// Computer Science principle: This is the observer pattern -
		// subscribing to events and receiving notifications.
		//
		// JSON-RPC: {"method": "eth_subscribe", "params": ["newHeads"], "id": 1}
		// Response: {"result": "0x1234...", "id": 1} (subscription ID)
		sub, err := client.SubscribeNewHead(context.Background(), heads)
		if err != nil {
			log.Fatalf("subscribe: %v", err)
		}
		defer sub.Unsubscribe()

		fmt.Println("listening for new heads (ctrl+c to exit)...")

		// Loop forever, receiving headers as they arrive
		// This is a blocking operation - it runs until interrupted
		for {
			select {
			case err := <-sub.Err():
				// Subscription error (connection lost, etc.)
				log.Fatalf("sub err: %v", err)
			case h := <-heads:
				// New header received - print it
				fmt.Printf("new head #%d hash=%s parent=%s\n",
					h.Number.Uint64(), h.Hash(), h.ParentHash)

				// Reorg detection hint:
				// If stored parentHash doesn't match previously seen hash,
				// a reorg happened. You'd need to:
				// 1. Store block hash by block number
				// 2. Compare parent hash with stored hash
				// 3. If mismatch, rewind and rescan (module 18)
			}
		}
	}

	// ============================================================
	// HTTP FALLBACK: Polling Latest Blocks
	// ============================================================
	// If not WebSocket mode, poll latest N blocks.
	// This is the fallback when WebSocket isn't available.
	//
	// Computer Science principle: Polling is less efficient than
	// subscriptions (repeated requests), but works everywhere.
	head, err := client.HeaderByNumber(context.Background(), nil)
	if err != nil {
		log.Fatalf("head: %v", err)
	}
	latest := head.Number.Uint64()
	start := latest - uint64(*blocks) + 1

	// Loop through latest N blocks and print headers
	for n := start; n <= latest; n++ {
		h, err := client.HeaderByNumber(context.Background(), big.NewInt(int64(n)))
		if err != nil {
			log.Fatalf("header %d: %v", n, err)
		}
		fmt.Printf("head #%d hash=%s parent=%s\n",
			n, h.Hash(), h.ParentHash)
	}

	// ============================================================
	// EDUCATIONAL NOTES & COMPARISONS
	// ============================================================
	//
	// Building on previous modules:
	// - Module 09: You learned to filter logs (historical queries)
	// - This module: You learned to subscribe to new blocks (real-time)
	// - Same filtering concepts, different protocol (WebSocket vs HTTP)
	//
	// Key concepts:
	// - WebSocket provides push-based updates (real-time)
	// - HTTP polling provides pull-based updates (periodic checks)
	// - Reorgs can be detected by comparing parent hashes
	// - Subscriptions are more efficient but require WebSocket
	//
	// Comparisons:
	// - WebSocket vs HTTP Polling: WebSocket is real-time, HTTP is fallback
	// - newHeads vs FilterLogs: newHeads is push, FilterLogs is pull
	//
	// Real-world analogies:
	// - WebSocket = live news ticker (updates pushed immediately)
	// - HTTP Polling = refreshing news website (checking periodically)
	// - Reorgs = breaking news corrections (story changed)
	//
	// Fun facts:
	// - WebSocket URLs use wss:// (WebSocket Secure, like https://)
	// - Public RPC providers may limit WebSocket connections
	// - Run your own node for unlimited subscriptions
	//
	// Production tips:
	// - Use WebSocket for real-time monitoring
	// - Use HTTP polling as fallback
	// - Handle subscription errors gracefully
	// - Detect reorgs by comparing parent hashes
	//
	// Next steps (module 11):
	// - You'll learn to query contract storage slots directly
	// - Understand storage layout (mappings, arrays)
	// - Learn about storage proofs
	// - Connect to Solidity storage concepts from module 01
}
