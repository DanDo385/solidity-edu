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

// ============================================================
// ERC20 Transfer Event ABI
// ============================================================
// ERC20 Transfer event definition:
// - from: indexed address (goes into Topics[1])
// - to: indexed address (goes into Topics[2])
// - value: non-indexed uint256 (goes into Data)
//
// Computer Science principle: Indexed parameters are searchable
// via bloom filters, non-indexed are cheaper to store.
const erc20ABI = `[{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Transfer","type":"event"}]`

func main() {
	// ============================================================
	// CONFIGURATION: Flags for Event Filtering Parameters
	// ============================================================
	defaultRPC := os.Getenv("INFURA_RPC_URL")
	if defaultRPC == "" {
		defaultRPC = "https://mainnet.infura.io/v3/YOUR_KEY"
	}
	rpc := flag.String("rpc", defaultRPC, "RPC endpoint")
	tokenHex := flag.String("token", "", "ERC20 token address")
	fromBlock := flag.Int64("from", 0, "start block")
	toBlock := flag.Int64("to", 0, "end block (0=latest)")
	flag.Parse()

	if *tokenHex == "" {
		log.Fatal("usage: -token <addr> [-from N] [-to M]")
	}

	// ============================================================
	// CONTEXT WITH TIMEOUT: Preventing Hanging Forever
	// ============================================================
	// Use longer timeout (15 seconds) since filtering can take time
	// for large block ranges.
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
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
	// PARSING EVENT ABI: Creating ABI Object for Event Decoding
	// ============================================================
	// Parse the Transfer event ABI to get event signature and structure.
	token := common.HexToAddress(*tokenHex)
	parsed, err := abi.JSON(strings.NewReader(erc20ABI))
	if err != nil {
		log.Fatalf("abi: %v", err)
	}

	// ============================================================
	// GETTING EVENT TOPIC: Event Signature Hash
	// ============================================================
	// Get the Transfer event topic (event signature hash).
	// This is Topics[0] - the event signature hash that identifies
	// the event type.
	//
	// Calculation:
	// 1. Event signature: "Transfer(address,address,uint256)"
	// 2. Hash: keccak256(signature) = 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
	// 3. This is Topics[0] for all Transfer events
	//
	// Computer Science principle: Event signatures are like hash
	// table keys. They allow fast filtering by event type.
	transferID := parsed.Events["Transfer"].ID

	// ============================================================
	// BUILDING FILTER QUERY: Event Filter Parameters
	// ============================================================
	// Build FilterQuery to filter Transfer events:
	// - FromBlock: Start block (0 = from genesis)
	// - ToBlock: End block (nil = latest)
	// - Addresses: Token contract address (filter by contract)
	// - Topics: Event signature hash (filter by event type)
	//
	// Computer Science principle: FilterQuery is like a SQL WHERE
	// clause. It specifies which events to retrieve based on criteria.
	//
	// Topics structure:
	// - Topics[0]: Event signature (required)
	// - Topics[1]: First indexed parameter (optional, nil = match any)
	// - Topics[2]: Second indexed parameter (optional, nil = match any)
	// - Topics[3]: Third indexed parameter (optional, nil = match any)
	q := ethereum.FilterQuery{
		FromBlock: big.NewInt(*fromBlock),
		ToBlock:   nil, // nil = latest block
		Addresses: []common.Address{token},
		Topics:    [][]common.Hash{{transferID}}, // Filter by Transfer event
	}
	if *toBlock > 0 {
		q.ToBlock = big.NewInt(*toBlock)
	}

	// ============================================================
	// FETCHING LOGS: Executing Filter Query
	// ============================================================
	// FilterLogs executes the filter query and returns matching logs.
	//
	// What happens:
	// 1. Node checks bloom filters in block headers (fast filtering)
	// 2. For blocks with matching bloom, fetches full logs
	// 3. Filters logs by address and topics
	// 4. Returns matching logs
	//
	// Computer Science principle: Bloom filters allow fast "does this
	// block contain Transfer events?" queries without downloading
	// all logs. This is a probabilistic data structure (may have
	// false positives, never false negatives).
	//
	// JSON-RPC call: {"method": "eth_getLogs", "params": [filterQuery], "id": 1}
	// Response: {"result": [log1, log2, ...], "id": 1}
	logs, err := client.FilterLogs(ctx, q)
	if err != nil {
		log.Fatalf("filter: %v", err)
	}

	// ============================================================
	// DECODING LOGS: Extracting Event Data
	// ============================================================
	// Loop through each log and decode it:
	// - Extract indexed parameters from Topics
	// - Decode non-indexed parameters from Data
	//
	// Log structure:
	// - Topics[0]: Event signature (already filtered)
	// - Topics[1]: from address (indexed)
	// - Topics[2]: to address (indexed)
	// - Data: value (non-indexed, ABI-encoded)
	for _, lg := range logs {
		// Extract indexed parameters from topics
		// Topics are 32-byte hashes, addresses are 20 bytes
		// Addresses are padded to 32 bytes in topics
		from := common.BytesToAddress(lg.Topics[1].Bytes())
		to := common.BytesToAddress(lg.Topics[2].Bytes())

		// Decode non-indexed parameters from data
		// Data contains ABI-encoded non-indexed parameters
		var data struct {
			Value *big.Int
		}
		if err := parsed.UnpackIntoInterface(&data, "Transfer", lg.Data); err != nil {
			log.Fatalf("unpack: %v", err)
		}

		// Display decoded event
		fmt.Printf("block=%d tx=%s from=%s to=%s value=%s\n",
			lg.BlockNumber, lg.TxHash, from.Hex(), to.Hex(), data.Value.String())
	}

	// ============================================================
	// EDUCATIONAL NOTES & COMPARISONS
	// ============================================================
	//
	// Building on previous modules:
	// - Module 08: You learned to call contract functions
	// - This module: You learned to listen to events emitted by functions
	// - Events complement function calls - they show what happened
	//
	// Key concepts:
	// - Events are append-only history (like audit logs)
	// - Indexed parameters are searchable (via bloom filters)
	// - Non-indexed parameters are cheaper to store
	// - Topics[0] is event signature hash
	// - Topics[1..] are indexed parameters
	// - Data contains non-indexed parameters
	//
	// Comparisons:
	// - Topics vs Data: Topics are searchable, Data is cheaper
	// - FilterLogs vs SubscribeLogs: FilterLogs is HTTP polling, SubscribeLogs is WS push
	//
	// Real-world analogies:
	// - Events = newspaper clippings (append-only history)
	// - Topics = bold headlines (indexed, searchable)
	// - Data = article body (non-indexed, cheaper)
	// - Bloom filters = index of headlines (fast search)
	//
	// Fun facts:
	// - Event signature hash is keccak256(event signature)
	// - Bloom filters allow fast event queries without downloading all logs
	// - Maximum 4 topics per event (including signature)
	// - Maximum ~24KB data per log
	//
	// Production tips:
	// - Index only what you need to search by (indexed params cost more gas)
	// - Use WebSocket subscriptions (module 10) for real-time monitoring
	// - Paginate large block ranges to avoid provider limits
	// - Handle reorgs gracefully (logs can be dropped/replayed)
	//
	// Next steps (module 10):
	// - You'll learn to subscribe to new block headers via WebSocket
	// - Poll headers as a fallback (HTTP)
	// - Understand real-time vs polling approaches
	// - Detect chain reorganizations
}
