package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
)

func main() {
	// ============================================================
	// CONFIGURATION: RPC URL and Timeout
	// ============================================================
	// Building on modules 01-02: Same pattern for reading RPC URL
	// from environment variables with flag overrides.
	//
	// New in this module: We accept addresses as command-line arguments
	// instead of hardcoding them. This makes the tool flexible.
	defaultRPC := os.Getenv("INFURA_RPC_URL")
	if defaultRPC == "" {
		defaultRPC = "https://mainnet.infura.io/v3/YOUR_KEY"
	}
	rpc := flag.String("rpc", defaultRPC, "RPC endpoint")
	timeout := flag.Duration("timeout", 8*time.Second, "timeout")
	flag.Parse()

	// ============================================================
	// INPUT VALIDATION: Address Arguments
	// ============================================================
	// Get addresses from command-line arguments (everything after flags).
	// This allows users to query multiple addresses in one run.
	//
	// Example usage: ./04-accounts-balances 0x742d35Cc... 0x1234...
	addrs := flag.Args()
	if len(addrs) == 0 {
		log.Fatal("usage: <addr1> <addr2> ...")
	}

	// ============================================================
	// CONTEXT WITH TIMEOUT: Preventing Hanging Forever
	// ============================================================
	// Same as modules 01-02: Context with timeout prevents hanging.
	// We use a slightly longer timeout (8 seconds) since we're making
	// multiple RPC calls (one per address).
	ctx, cancel := context.WithTimeout(context.Background(), *timeout)
	defer cancel()

	// ============================================================
	// DIALING THE RPC ENDPOINT: Establishing Connection
	// ============================================================
	// Same as modules 01-02: Dial JSON-RPC endpoint.
	// We'll reuse this client for all address queries.
	client, err := ethclient.DialContext(ctx, *rpc)
	if err != nil {
		log.Fatalf("dial: %v", err)
	}
	defer client.Close()

	// ============================================================
	// QUERYING ACCOUNT STATE: Balance and Code
	// ============================================================
	// Loop through each address and query its state.
	// For each address, we need to determine:
	// 1. Balance (in wei)
	// 2. Code (bytecode, if any)
	// 3. Account type (EOA vs Contract)
	for _, raw := range addrs {
		// Convert hex string to common.Address
		// common.HexToAddress handles validation and normalization
		addr := common.HexToAddress(raw)

		// ============================================================
		// QUERYING BALANCE: eth_getBalance
		// ============================================================
		// BalanceAt returns balance in wei at a specific block.
		// nil = latest block (tip of chain).
		//
		// Computer Science principle: Balances are stored as big.Int
		// to avoid overflow. ETH has 18 decimal places, so we need
		// arbitrary precision integers.
		//
		// JSON-RPC call: {"method": "eth_getBalance", "params": [address, "latest"], "id": 1}
		// Response: {"result": "0x1234...", "id": 1} (hex-encoded wei)
		//
		// Fun fact: Wei is named after Wei Dai, creator of b-money
		// (an early cryptocurrency proposal). Ethereum uses wei to
		// honor this contribution to the field.
		bal, err := client.BalanceAt(ctx, addr, nil)
		if err != nil {
			log.Fatalf("balance %s: %v", addr.Hex(), err)
		}

		// ============================================================
		// QUERYING CODE: eth_getCode
		// ============================================================
		// CodeAt returns contract bytecode at a specific block.
		// nil = latest block.
		//
		// Account type detection:
		// - EOA: code length == 0 (no bytecode)
		// - Contract: code length > 0 (has bytecode)
		//
		// Computer Science principle: Code is stored separately from
		// the account trie. The account stores codeHash (hash of bytecode),
		// and the actual bytecode is stored in a separate database.
		// This keeps the account trie small while allowing large contracts.
		//
		// JSON-RPC call: {"method": "eth_getCode", "params": [address, "latest"], "id": 1}
		// Response: {"result": "0x6080604052...", "id": 1} (hex-encoded bytecode)
		//
		// Special cases:
		// - Precompiles (0x01-0x09): Have code but are native implementations
		// - Selfdestructed contracts: Have nonce > 0 but code length == 0
		code, err := client.CodeAt(ctx, addr, nil)
		if err != nil {
			log.Fatalf("code %s: %v", addr.Hex(), err)
		}

		// ============================================================
		// ACCOUNT TYPE CLASSIFICATION
		// ============================================================
		// Determine account type based on code presence.
		//
		// EOA (Externally Owned Account):
		// - Has private key (from module 03)
		// - No code (code length == 0)
		// - Can initiate transactions
		// - Analogy: Empty plot of land with a mailbox
		//
		// Contract Account:
		// - No private key (cannot initiate transactions directly)
		// - Has code (code length > 0)
		// - Can be called by EOAs or other contracts
		// - Analogy: Building with machinery (code) on the same street
		//
		// Note: This is a heuristic. Selfdestructed contracts have
		// code length == 0 but nonce > 0. For production code, you'd
		// check nonce too to distinguish them from EOAs.
		kind := "EOA"
		if len(code) > 0 {
			kind = "Contract"
		}

		// Display results
		fmt.Printf("%s | type=%s | balance=%s wei\n", addr.Hex(), kind, bal.String())
	}

	// ============================================================
	// EDUCATIONAL NOTES & COMPARISONS
	// ============================================================
	//
	// Building on previous modules:
	// - Module 03: You generated addresses from private keys (EOAs)
	// - This module: You query those addresses on-chain to see their state
	// - Module 01-02: You learned about blocks and stateRoot (account trie root)
	//
	// Connection to Solidity:
	// - msg.sender can be either EOA or contract (contracts can call contracts)
	// - Access control uses addresses (from module 03) and account types (this module)
	// - Balances change when contracts receive ETH via payable functions
	//
	// Comparisons:
	// - ethers.js: provider.getBalance(addr), provider.getCode(addr)
	// - Code size 0 => likely EOA; >0 => contract (note: precompiles have code!)
	//
	// Real-world analogies:
	// - Empty plot (EOA, no code) vs building with machinery inside (contract code)
	// - Personal bank account (EOA) vs trust account/automated system (contract)
	//
	// Fun facts:
	// - Precompiles (0x01-0x09) have code but are native implementations
	// - Selfdestructed contracts have nonce > 0 but code length == 0
	// - Account creation: EOAs appear when they receive first tx, contracts appear on deployment
	//
	// Next steps (module 05):
	// - You'll build transactions from scratch
	// - Understand transaction nonces (sequence numbers)
	// - Sign transactions with private keys (from module 03)
	// - Broadcast transactions to the network
}
