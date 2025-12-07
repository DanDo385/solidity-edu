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
	// ============================================================
	// CONFIGURATION: Reading RPC URL and Parameters
	// ============================================================
	// Building on modules 01-10: We use the same pattern for reading
	// RPC URL from environment variables with flag overrides.
	//
	// New in this module: We add flags for contract address, storage slot,
	// and optional mapping key. This allows flexible storage queries.
	//
	// Computer Science principle: Command-line flags provide a clean interface
	// for CLI tools. Environment variables are better for CI/CD, flags for
	// interactive use.
	defaultRPC := os.Getenv("INFURA_RPC_URL")
	if defaultRPC == "" {
		defaultRPC = "https://mainnet.infura.io/v3/YOUR_KEY"
	}
	rpc := flag.String("rpc", defaultRPC, "RPC endpoint (HTTP/WS)")
	contractHex := flag.String("contract", "", "contract address (required)")
	slot := flag.Uint64("slot", 0, "storage slot index (for simple variables)")
	mapKey := flag.String("mapkey", "", "optional mapping key (address) - computes mapping slot")
	timeout := flag.Duration("timeout", 8*time.Second, "RPC call timeout")
	flag.Parse()

	// ============================================================
	// VALIDATION: Ensure Required Parameters
	// ============================================================
	// Contract address is required. Without it, we can't query storage.
	// This is a simple input validation pattern.
	if *contractHex == "" {
		log.Fatal("usage: -contract <addr> -slot <n> [-mapkey addr]")
	}

	// ============================================================
	// CONCEPTUAL OVERVIEW: Storage Slot Model
	// ============================================================
	// STORAGE SLOTS = NUMBERED LOCKERS (32 bytes each)
	// ═══════════════════════════════════════════════════════════
	//
	// Ethereum storage is organized as 2^256 possible 32-byte slots.
	// Think of it like a massive array where each index is a storage slot.
	//
	// SIMPLE VARIABLES:
	//   - Live at declared slot numbers (slot 0, 1, 2, ...)
	//   - Example: uint256 value → slot 0
	//   - Example: address owner → slot 1
	//
	// MAPPINGS:
	//   - Base slot is declared (e.g., mapping at slot 5)
	//   - Actual storage: slot = keccak256(key, baseSlot)
	//   - Example: mapping(address => uint256) balances at slot 0
	//     → balances[0xABC...] stored at keccak256(0xABC..., 0)
	//
	// DYNAMIC ARRAYS:
	//   - Length stored in declared slot
	//   - Data starts at: base = keccak256(slot)
	//   - Item at index i: base + i
	//   - Example: uint256[] items at slot 2
	//     → items.length in slot 2
	//     → items[0] at keccak256(2)
	//     → items[1] at keccak256(2) + 1
	//
	// CONNECTION TO SOLIDITY:
	//   - From Solidity-edu 01: Storage layout rules
	//   - From Solidity-edu 06: Mapping slot calculation
	//   - This module: How to read those slots from Go
	//
	// CONNECTION TO PROOFS (module 12):
	//   - Storage proofs use the same slot calculations
	//   - Proofs prove "contract X has value Y in slot Z"
	//
	// REAL-WORLD ANALOGY:
	//   - Storage slots = numbered lockers in a gym
	//   - Simple variables = your assigned locker (always same number)
	//   - Mappings = compute locker number from key + aisle
	//   - Arrays = consecutive lockers starting at computed base
	//
	// CPU ANALOGY:
	//   - Like fixed memory addresses in assembly
	//   - Mapping hash = computing memory offset via hash function

	ctx, cancel := context.WithTimeout(context.Background(), *timeout)
	defer cancel()

	// ============================================================
	// DIALING THE RPC ENDPOINT: Establishing Connection
	// ============================================================
	// Same as modules 01-10: Dial JSON-RPC endpoint.
	// This is your connection to the Ethereum node.
	//
	// Building on previous modules: We reuse the same connection pattern.
	// In production, you'd often reuse a single client across multiple
	// requests (connection pooling).
	client, err := ethclient.DialContext(ctx, *rpc)
	if err != nil {
		log.Fatalf("dial: %v", err)
	}
	defer client.Close()

	// ============================================================
	// STEP 1: Read Simple Storage Slot
	// ============================================================
	// For simple variables, the slot number is declared directly.
	// Example: uint256 public value; → stored at slot 0
	//
	// StorageAt signature:
	//   StorageAt(ctx, address, slot, blockNumber)
	//   - address: Contract address
	//   - slot: 32-byte slot number (as []byte)
	//   - blockNumber: nil = latest, or specific block number
	//
	// Returns: 32-byte raw value (you must decode based on type)
	//
	// JSON-RPC call: {"method": "eth_getStorageAt", "params": [address, slot, "latest"]}
	//
	// Computer Science principle: This is direct memory access, similar to
	// reading from a specific memory address. The slot number is like a
	// memory address.
	addr := common.HexToAddress(*contractHex)
	slotHash := common.BigToHash(new(big.Int).SetUint64(*slot))

	raw, err := client.StorageAt(ctx, addr, slotHash.Bytes(), nil)
	if err != nil {
		log.Fatalf("storage: %v", err)
	}
	fmt.Printf("slot %d raw: 0x%s\n", *slot, hex.EncodeToString(raw))

	// ============================================================
	// STEP 2: Compute and Read Mapping Slot (if key provided)
	// ============================================================
	// MAPPING SLOT CALCULATION:
	// ═══════════════════════════════════════════════════════════
	//
	// Formula: slot = keccak256(abi.encode(key, baseSlot))
	//
	// In Solidity:
	//   mapping(address => uint256) balances;  // baseSlot = 0
	//   balances[0xABC...] → stored at keccak256(0xABC..., 0)
	//
	// In Go:
	//   1. Pad key to 32 bytes (left-pad with zeros)
	//   2. Pad baseSlot to 32 bytes (left-pad with zeros)
	//   3. Concatenate: key || baseSlot
	//   4. Hash: keccak256(concatenated bytes)
	//
	// Why padding?
	//   - keccak256 operates on bytes, not types
	//   - We need exactly 32 bytes for each component
	//   - Left-padding ensures consistent encoding
	//
	// Example:
	//   - Key: 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb (20 bytes)
	//   - Base slot: 0 (uint64, but needs 32 bytes)
	//   - Padded key: 0x0000...00742d35Cc6634C0532925a3b844Bc9e7595f0bEb
	//   - Padded slot: 0x0000...0000000000000000000000000000000000000000000000000000000000000000
	//   - Concatenated: 64 bytes total
	//   - Hash: keccak256(64 bytes) → 32-byte slot number
	//
	// Computer Science principle: This is a hash table with perfect
	// collision resistance (keccak256 is cryptographically secure).
	// The hash function distributes keys uniformly across 2^256 slots.
	//
	// Security note: The same key + baseSlot always produces the same
	// slot number (deterministic). This is by design—it allows anyone
	// to compute where a mapping value is stored.
	if *mapKey != "" {
		// Parse the mapping key (address in this example)
		key := common.HexToAddress(*mapKey)

		// Create keccak256 hasher
		// Note: Ethereum uses Keccak-256 (SHA-3 variant), not standard SHA-3
		// This is why we use sha3.NewLegacyKeccak256() instead of sha3.New256()
		h := sha3.NewLegacyKeccak256()

		// Hash the key (padded to 32 bytes) and base slot (padded to 32 bytes)
		// LeftPadBytes ensures each component is exactly 32 bytes
		// This matches Solidity's abi.encode() behavior
		h.Write(common.LeftPadBytes(key.Bytes(), 32))  // Pad address to 32 bytes
		h.Write(common.LeftPadBytes(slotHash.Bytes(), 32)) // Pad slot to 32 bytes

		// Compute the final slot number (32 bytes)
		mapSlot := h.Sum(nil)

		// Read the mapping value from the computed slot
		mapVal, err := client.StorageAt(ctx, addr, mapSlot, nil)
		if err != nil {
			log.Fatalf("map storage: %v", err)
		}

		// Display results
		// - mapKey: The key we used (address)
		// - mapSlot: The computed slot number (hex-encoded)
		// - mapVal: The raw 32-byte value stored at that slot
		fmt.Printf("mapping[%s] slot=0x%s raw=0x%s\n",
			key.Hex(),
			hex.EncodeToString(mapSlot),
			hex.EncodeToString(mapVal))
	}

	// ============================================================
	// EDUCATIONAL NOTES & KEY TAKEAWAYS
	// ============================================================
	//
	// STORAGE SLOT TYPES:
	// ═══════════════════
	//
	// 1. SIMPLE VARIABLES:
	//    - Stored at declared slot numbers
	//    - Example: uint256 value → slot 0
	//    - Direct access: StorageAt(ctx, addr, slot0, nil)
	//
	// 2. MAPPINGS:
	//    - Base slot declared, actual slot computed
	//    - Formula: keccak256(key, baseSlot)
	//    - Example: mapping(address => uint256) → keccak256(addr, 0)
	//    - Deterministic: same key + baseSlot = same slot
	//
	// 3. DYNAMIC ARRAYS:
	//    - Length in declared slot
	//    - Data at: keccak256(slot) + index
	//    - Example: uint256[] items → items[0] at keccak256(slot), items[1] at keccak256(slot) + 1
	//
	// 4. PACKED VARIABLES:
	//    - Multiple small types in one slot
	//    - Example: uint128 + uint128 in slot 0
	//    - Requires bit manipulation to decode
	//
	// CONNECTION TO SOLIDITY:
	// ═══════════════════════
	//
	// From Solidity-edu 01 (Datatypes & Storage):
	//   - Storage slots are 32 bytes each
	//   - Variables packed when possible (gas optimization)
	//   - Mappings use hash-based slot calculation
	//
	// From Solidity-edu 06 (Mappings, Arrays & Gas):
	//   - Mapping slot: keccak256(key, baseSlot)
	//   - Array slot: keccak256(slot) + index
	//   - Understanding slot calculation helps optimize gas
	//
	// REAL-WORLD ANALOGIES:
	// ═════════════════════
	//
	// Gym Locker Analogy:
	//   - Storage slots = numbered lockers (32 bytes each)
	//   - Simple variables = your assigned locker (always same number)
	//   - Mappings = compute locker number from key + aisle
	//   - Arrays = consecutive lockers starting at computed base
	//
	// Database Analogy:
	//   - Storage slots = database rows (32 bytes each)
	//   - Simple variables = direct row access (row 0, 1, 2, ...)
	//   - Mappings = indexed lookup (hash(key) = row number)
	//
	// COMPARISONS:
	// ════════════
	//
	// Go vs JavaScript:
	//   - Go: client.StorageAt() → []byte (raw 32 bytes)
	//   - JS: provider.getStorageAt() → string (hex-encoded)
	//   - Both call eth_getStorageAt JSON-RPC method
	//   - Both require manual decoding
	//
	// Storage vs Memory vs Calldata:
	//   - Storage: Persistent, on-chain, expensive (20k gas per write)
	//   - Memory: Temporary, function-scoped, cheap (~3 gas per word)
	//   - Calldata: Read-only, transaction data, cheapest
	//
	// NEXT STEPS (module 12):
	// ══════════════════════
	//
	// You'll learn about storage proofs:
	//   - Merkle-Patricia trie proofs for storage slots
	//   - How to prove "contract X has value Y in slot Z"
	//   - Light client verification without full state
	//   - Same slot calculations, but with cryptographic proofs
}
