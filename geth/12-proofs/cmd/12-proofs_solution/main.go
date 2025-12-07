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
	// ============================================================
	// CONFIGURATION: Reading RPC URL and Parameters
	// ============================================================
	// Building on modules 01-11: We use the same pattern for reading
	// RPC URL from environment variables with flag overrides.
	//
	// New in this module: We add flags for account address, storage slot,
	// and block number. This allows flexible proof queries.
	//
	// IMPORTANT: Not all RPC endpoints support eth_getProof!
	// - Public RPCs (Infura, Alchemy) often disable it
	// - Your own node (Geth, Erigon) supports it
	// - This is a security/performance consideration
	defaultRPC := os.Getenv("INFURA_RPC_URL")
	if defaultRPC == "" {
		defaultRPC = "https://mainnet.infura.io/v3/YOUR_KEY"
	}
	rpc := flag.String("rpc", defaultRPC, "RPC endpoint (needs eth_getProof support - may require own node)")
	accountHex := flag.String("account", "", "account address to prove (required)")
	slot := flag.Uint64("slot", 0, "optional storage slot to prove (0 = account only)")
	block := flag.Int64("block", -1, "block number (-1=latest, or specific block)")
	timeout := flag.Duration("timeout", 8*time.Second, "RPC call timeout")
	flag.Parse()

	// ============================================================
	// VALIDATION: Ensure Required Parameters
	// ============================================================
	// Account address is required. Without it, we can't generate proofs.
	if *accountHex == "" {
		log.Fatal("usage: -account <addr> [-slot N] [-block num]")
	}

	// ============================================================
	// CONCEPTUAL OVERVIEW: Merkle-Patricia Trie Proofs
	// ============================================================
	// MERKLE-PATRICIA TRIE PROOFS = TAMPER-EVIDENT RECEIPTS
	// ═══════════════════════════════════════════════════════════
	//
	// What are proofs?
	//   - Cryptographic receipts proving account/storage state
	//   - Enable verification without downloading full blockchain
	//   - Used by light clients, bridges, and indexers
	//
	// How do they work?
	//   1. State is organized as a Merkle-Patricia trie
	//   2. Each account/storage slot is a leaf in the trie
	//   3. Proof = path from root to leaf (sibling hashes)
	//   4. Verify by computing hashes up the tree
	//   5. If final hash matches stateRoot, proof is valid!
	//
	// Account Proof:
	//   - Proves: balance, nonce, codeHash, storageHash
	//   - Path: stateRoot → account node
	//   - Size: ~1-5 KB (depends on trie depth)
	//
	// Storage Proof:
	//   - Proves: storage slot value
	//   - Path: storageHash → storage slot node
	//   - Size: ~1-5 KB per slot
	//
	// Connection to module 11:
	//   - Storage proofs use same slot calculations you learned
	//   - Proof paths navigate the storage trie using slot hashes
	//
	// Real-world analogy:
	//   - Proof = notarized receipt stapled to ledger page
	//   - Proof nodes = notary signatures along the path
	//   - State root = official ledger seal
	//   - Verification = checking signatures match official seal
	//
	// Computer Science principle:
	//   - Merkle trees provide logarithmic proof size
	//   - For 2^256 accounts, you only need ~256 proof nodes
	//   - This enables light clients (verify without full sync)

	ctx, cancel := context.WithTimeout(context.Background(), *timeout)
	defer cancel()

	// ============================================================
	// DIALING THE RPC ENDPOINT: Establishing Connection
	// ============================================================
	// Same as modules 01-11: Dial JSON-RPC endpoint.
	//
	// IMPORTANT: Not all RPC endpoints support eth_getProof!
	// - Public RPCs often disable it (security/performance)
	// - Your own node (Geth, Erigon) supports it
	// - If you get "method not found", use your own node
	client, err := ethclient.DialContext(ctx, *rpc)
	if err != nil {
		log.Fatalf("dial: %v", err)
	}
	defer client.Close()

	// ============================================================
	// PREPARING PROOF REQUEST: Account and Storage Slots
	// ============================================================
	// GetProof signature:
	//   GetProof(ctx, address, storageSlots, blockNumber)
	//   - address: Account to prove
	//   - storageSlots: Optional list of storage slots to prove
	//   - blockNumber: nil = latest, or specific block number
	//
	// Returns: AccountResult containing:
	//   - Account state (balance, nonce, codeHash, storageHash)
	//   - Account proof nodes (Merkle path)
	//   - Storage proofs (if slots requested)
	//
	// JSON-RPC call: {"method": "eth_getProof", "params": [address, [slots], block]}
	//
	// Computer Science principle: This is a cryptographic query.
	// Instead of trusting the RPC endpoint, you get cryptographic proof
	// that you can verify independently.
	addr := common.HexToAddress(*accountHex)

	// Prepare storage slots (if provided)
	// Empty slice = account proof only
	// Non-empty = account proof + storage proofs for specified slots
	slots := []string{}
	if *slot != 0 {
		// Convert slot number to hex-encoded string (as expected by JSON-RPC)
		// Format: "0x0000...0000" (32-byte hex string)
		slots = []string{fmt.Sprintf("0x%064x", *slot)}
	}

	// Prepare block number
	// nil = latest block
	// Specific number = prove state at that block
	var blockNum *big.Int
	if *block >= 0 {
		blockNum = big.NewInt(*block)
	}

	// ============================================================
	// FETCHING PROOF: Account and Storage
	// ============================================================
	// This is the core operation: fetching Merkle-Patricia trie proofs.
	//
	// What you get back:
	//   1. Account state (balance, nonce, codeHash, storageHash)
	//   2. Account proof nodes (path from stateRoot to account)
	//   3. Storage proofs (if slots requested)
	//
	// Proof structure:
	//   - AccountProof: []string (hex-encoded proof nodes)
	//   - StorageProof: []StorageResult (one per requested slot)
	//   - Each proof node is a hash in the Merkle tree
	//
	// Verification process (not shown here, but important to understand):
	//   1. Start with account data (balance, nonce, etc.)
	//   2. Use proof nodes to compute hashes up the tree
	//   3. Final hash should match stateRoot in block header
	//   4. If it matches, proof is valid!
	//
	// Computer Science principle: This is zero-knowledge in the sense
	// that you can verify state without seeing the entire state trie.
	// You only need the proof nodes (logarithmic in size).
	proof, err := client.GetProof(ctx, addr, slots, blockNum)
	if err != nil {
		log.Fatalf("getProof: %v", err)
	}

	// ============================================================
	// DISPLAYING RESULTS: Account and Storage Proofs
	// ============================================================
	// Display account proof information:
	//   - Balance: Account's ETH balance (in wei)
	//   - Nonce: Transaction count (for EOA) or contract creation nonce
	//   - CodeHash: Hash of contract code (0x0 for EOA, non-zero for contracts)
	//   - StorageHash: Root of storage trie (0x0 for EOA, non-zero for contracts)
	//   - AccountProof: Number of proof nodes (trie depth)
	//
	// Account proof interpretation:
	//   - Balance: How much ETH the account holds
	//   - Nonce: Next transaction nonce (prevents replay attacks)
	//   - CodeHash: If non-zero, this is a contract account
	//   - StorageHash: Root of contract's storage trie (if contract)
	//   - AccountProof: Merkle path proving this account exists in stateRoot
	//
	// Proof node count:
	//   - Typically 7-9 nodes for account trie (mainnet)
	//   - More nodes = deeper trie = more accounts
	fmt.Printf("Account proof for %s at block %v\n", addr.Hex(), blockNum)
	fmt.Printf("  balance=%s nonce=%d codeHash=%s storageHash=%s\n",
		proof.Balance.String(),
		proof.Nonce,
		proof.CodeHash.Hex(),
		proof.StorageHash.Hex())
	fmt.Printf("  accountProof (nodes): %d\n", len(proof.AccountProof))

	// Display storage proof (if slot was requested)
	// Storage proof shows:
	//   - Key: Storage slot (hex-encoded)
	//   - Value: Value stored at that slot (raw 32 bytes as big.Int)
	//   - Proof: Merkle path proving this slot exists in storage trie
	//
	// Connection to module 11:
	//   - This is proving the storage slot you learned to read
	//   - Proof path uses same slot calculation (keccak256)
	//   - You can verify the proof against storageHash from account proof
	if len(proof.StorageProof) > 0 {
		sp := proof.StorageProof[0]
		fmt.Printf("  storage slot %s value=%s proofs=%d\n",
			sp.Key,
			sp.Value.String(),
			len(sp.Proof))
	}

	// ============================================================
	// EDUCATIONAL NOTES & KEY TAKEAWAYS
	// ============================================================
	//
	// PROOF TYPES:
	// ═══════════
	//
	// 1. ACCOUNT PROOFS:
	//    - Prove account state (balance, nonce, codeHash, storageHash)
	//    - Path: stateRoot → account node
	//    - Size: ~1-5 KB (7-9 proof nodes typically)
	//    - Use case: Light clients, balance verification
	//
	// 2. STORAGE PROOFS:
	//    - Prove storage slot value
	//    - Path: storageHash → storage slot node
	//    - Size: ~1-5 KB per slot (5-7 proof nodes typically)
	//    - Use case: Cross-chain bridges, storage verification
	//
	// VERIFICATION PROCESS:
	// ═════════════════════
	//
	// To verify a proof:
	//   1. Get stateRoot from block header (module 01)
	//   2. Start with account/storage data
	//   3. Use proof nodes to compute hashes up the tree
	//   4. Final hash should match stateRoot/storageHash
	//   5. If it matches, proof is valid!
	//
	// This enables trust-minimized verification:
	//   - You don't need to trust the RPC endpoint
	//   - You can verify proofs cryptographically
	//   - Light clients use this to verify without full sync
	//
	// CONNECTION TO PREVIOUS MODULES:
	// ════════════════════════════════
	//
	// Module 01 (Stack):
	//   - Block headers contain stateRoot (Merkle root)
	//   - Proofs prove membership in that trie
	//   - You can verify proofs against stateRoot
	//
	// Module 11 (Storage):
	//   - Storage slots you learned to read are what proofs prove
	//   - Proof paths use same slot calculations (keccak256)
	//   - Storage proofs prove specific slot values
	//
	// REAL-WORLD ANALOGIES:
	// ═════════════════════
	//
	// Notarized Receipt:
	//   - Proof = notarized receipt stapled to ledger page
	//   - Proof nodes = notary signatures along the path
	//   - State root = official ledger seal
	//   - Verification = checking signatures match seal
	//
	// Library Card Catalog:
	//   - State trie = library card catalog (index)
	//   - Account = specific book
	//   - Proof = path through catalog to find book
	//   - Verification = following path confirms book exists
	//
	// COMPARISONS:
	// ════════════
	//
	// Proofs vs Direct Queries:
	//   - Direct query (eth_getBalance): Trust RPC endpoint
	//   - Proof (eth_getProof): Cryptographic verification
	//   - Use proofs when you need trust-minimized verification
	//
	// Account Proofs vs Storage Proofs:
	//   - Account: Proves account state (balance, nonce)
	//   - Storage: Proves storage slot value
	//   - Storage proofs nested inside account proofs
	//
	// RPC ENDPOINT SUPPORT:
	// ════════════════════
	//
	// ⚠️  IMPORTANT: Not all RPC endpoints support eth_getProof!
	//   - Public RPCs (Infura, Alchemy) often disable it
	//   - Your own node (Geth, Erigon) supports it
	//   - If you get "method not found", use your own node
	//
	// NEXT STEPS (module 13):
	// ══════════════════════
	//
	// You'll learn about transaction tracing:
	//   - Opcode-by-opcode execution traces
	//   - Gas usage analysis
	//   - Debug contract behavior
	//   - Understand EVM internals
}
