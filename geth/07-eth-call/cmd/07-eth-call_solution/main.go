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
	// ============================================================
	// CONFIGURATION: Flags for Contract Call Parameters
	// ============================================================
	// Building on modules 01-06: Same pattern for reading RPC URL
	// from environment variables with flag overrides.
	//
	// New in this module: We accept contract address and function name.
	// This allows querying any ERC20 contract's view functions.
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

	// ============================================================
	// CONTEXT WITH TIMEOUT: Preventing Hanging Forever
	// ============================================================
	// Same as previous modules: Context with timeout prevents hanging.
	ctx, cancel := context.WithTimeout(context.Background(), *timeout)
	defer cancel()

	// ============================================================
	// DIALING THE RPC ENDPOINT: Establishing Connection
	// ============================================================
	// Same as previous modules: Dial JSON-RPC endpoint.
	client, err := ethclient.DialContext(ctx, *rpc)
	if err != nil {
		log.Fatalf("dial: %v", err)
	}
	defer client.Close()

	// ============================================================
	// DEFINING ERC20 ABI: Contract Interface Definition
	// ============================================================
	// Minimal ERC20 ABI for common view functions.
	// ABI (Application Binary Interface) defines how to encode/decode
	// function calls and return values.
	//
	// Computer Science principle: ABIs are like API contracts.
	// They define the interface between caller and contract, ensuring
	// data is encoded/decoded correctly.
	//
	// This ABI includes:
	// - name(): Returns token name (string)
	// - symbol(): Returns token symbol (string)
	// - decimals(): Returns decimal places (uint8)
	// - totalSupply(): Returns total supply (uint256)
	const erc20ABI = `[
		{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"type":"function"},
		{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"type":"function"},
		{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"type":"function"},
		{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"type":"function"}
	]`

	// ============================================================
	// PARSING ABI: Creating ABI Object for Encoding/Decoding
	// ============================================================
	// Parse the ABI JSON string into an ABI object.
	// This object provides methods for encoding function calls
	// and decoding return values.
	//
	// Computer Science principle: Parsing converts human-readable
	// JSON into a structured format that can be used for encoding/decoding.
	parsed, err := abi.JSON(strings.NewReader(erc20ABI))
	if err != nil {
		log.Fatalf("abi parse: %v", err)
	}

	// ============================================================
	// ABI PACKING: Encoding Function Call
	// ============================================================
	// Pack encodes the function selector + arguments.
	//
	// Function selector calculation:
	// 1. Function signature: "name()"
	// 2. Hash: keccak256("name()") = 0x06fdde03...
	// 3. Selector: First 4 bytes = 0x06fdde03
	//
	// Computer Science principle: Function selectors are like hash
	// table keys. They allow the EVM to quickly identify which
	// function to call without parsing the entire function name.
	//
	// For functions with no arguments (like name(), symbol(), etc.):
	// - Data = function selector only (4 bytes)
	// - Example: name() → 0x06fdde03
	//
	// For functions with arguments:
	// - Data = function selector + ABI-encoded arguments
	// - Example: balanceOf(address) → selector + encoded address
	data, err := parsed.Pack(*fn)
	if err != nil {
		log.Fatalf("abi pack: %v", err)
	}

	// ============================================================
	// BUILDING CALL MESSAGE: Contract Call Parameters
	// ============================================================
	// Convert contract address and create CallMsg.
	// CallMsg specifies what to call and with what data.
	//
	// ethereum.CallMsg fields:
	// - To: Contract address (pointer, nil for contract creation)
	// - Data: Encoded function call (selector + arguments)
	// - Value: ETH to send (nil for view functions)
	// - Gas: Gas limit (nil for automatic estimation)
	to := common.HexToAddress(*contractHex)
	callMsg := ethereum.CallMsg{To: &to, Data: data}

	// ============================================================
	// EXECUTING ETH_CALL: Read-Only Contract Execution
	// ============================================================
	// CallContract executes eth_call - simulates transaction without
	// persisting state changes.
	//
	// Key differences from eth_sendTransaction:
	// - No state changes are persisted
	// - No gas is spent (free to call)
	// - No transaction hash (not broadcast to network)
	// - Executes locally on the node
	//
	// Computer Science principle: This is like a "dry run" or
	// "read-only query". The EVM executes the code, but no state
	// changes are committed.
	//
	// nil = latest block (tip of chain)
	// You can also specify a block number for historical queries.
	//
	// JSON-RPC call: {"method": "eth_call", "params": [callMsg, "latest"], "id": 1}
	// Response: {"result": "0x...", "id": 1} (hex-encoded return data)
	raw, err := client.CallContract(ctx, callMsg, nil)
	if err != nil {
		log.Fatalf("eth_call: %v", err)
	}

	// ============================================================
	// DECODING RETURN VALUES: ABI Unpacking
	// ============================================================
	// Decode the return value based on function return type.
	// Different functions return different types, so we use a switch
	// statement to handle each case.
	//
	// ABI unpacking process:
	// 1. Take raw bytes from eth_call response
	// 2. Decode according to function's return type
	// 3. Convert to Go type (string, uint8, *big.Int, etc.)
	//
	// Computer Science principle: Decoding is the inverse of encoding.
	// We encoded the function call, now we decode the response.
	switch *fn {
	case "name", "symbol":
		// String return type
		var out string
		if err := parsed.UnpackIntoInterface(&out, *fn, raw); err != nil {
			log.Fatalf("unpack: %v", err)
		}
		fmt.Printf("%s(): %s\n", *fn, out)
	case "decimals":
		// uint8 return type
		var out uint8
		if err := parsed.UnpackIntoInterface(&out, *fn, raw); err != nil {
			log.Fatalf("unpack: %v", err)
		}
		fmt.Printf("decimals(): %d\n", out)
	case "totalSupply":
		// uint256 return type (big.Int in Go)
		var out *big.Int
		if err := parsed.UnpackIntoInterface(&out, *fn, raw); err != nil {
			log.Fatalf("unpack: %v", err)
		}
		fmt.Printf("totalSupply(): %s\n", out.String())
	default:
		// Unknown function - print raw hex
		fmt.Printf("raw hex: %s\n", hex.EncodeToString(raw))
	}

	// ============================================================
	// EDUCATIONAL NOTES & COMPARISONS
	// ============================================================
	//
	// Building on previous modules:
	// - Module 05-06: You learned to build and send transactions (state-changing)
	// - This module: You learned to query contracts without sending transactions
	// - Module 08: You'll learn typed bindings that simplify this process
	//
	// Key concepts:
	// - eth_call is read-only (no state changes, no gas cost)
	// - ABI encoding converts function calls to bytes
	// - Function selectors identify which function to call
	// - Decoding converts return bytes back to Go types
	//
	// Comparisons:
	// - Manual ABI (this module) vs Typed Bindings (module 08): Manual gives control, bindings give safety
	// - eth_call vs eth_sendTransaction: Call is read-only, sendTransaction changes state
	//
	// Real-world analogies:
	// - eth_call = database SELECT query (read-only)
	// - eth_sendTransaction = database INSERT/UPDATE (changes data)
	// - Function selector = hash table key (quick lookup)
	//
	// Fun facts:
	// - Function selectors are first 4 bytes of keccak256(signature)
	// - Selector collisions are extremely rare (1 in 4 billion)
	// - Reverts return error data that can be decoded
	//
	// Production tips:
	// - Always handle errors (contracts can revert)
	// - Use typed bindings (module 08) for production code
	// - Estimate gas before sending transactions
	//
	// Next steps (module 08):
	// - You'll learn typed contract bindings
	// - Reduce boilerplate with compile-time type safety
	// - See how abigen generates Go code from ABIs
}
