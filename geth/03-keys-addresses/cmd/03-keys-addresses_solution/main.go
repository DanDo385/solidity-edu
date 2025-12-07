package main

import (
	"crypto/ecdsa"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"

	"github.com/ethereum/go-ethereum/accounts/keystore"
	"github.com/ethereum/go-ethereum/crypto"
)

func main() {
	// ============================================================
	// CONFIGURATION: Flags for Output Directory and Passphrase
	// ============================================================
	// Flags control output location and passphrase.
	// In production, DO NOT hardcode passphrases!
	// Use environment variables or secret management systems.
	//
	// Security note: The default passphrase "changeit" is for demo only.
	// In production, always use strong, randomly generated passphrases.
	outDir := flag.String("out", "./keystore-demo", "directory to store keystore file")
	pass := flag.String("pass", "changeit", "keystore passphrase (demo only)")
	flag.Parse()

	// ============================================================
	// STEP 1: Generate a New secp256k1 Private Key
	// ============================================================
	// Generate a new secp256k1 private key. This is the raw EOA secret.
	//
	// Computer Science principle: Cryptographically secure random number
	// generation is critical. Weak randomness = weak keys = compromised accounts.
	//
	// Under the hood:
	// - Uses Go's crypto/rand package
	// - On Linux: reads from /dev/urandom
	// - On Windows: uses CryptGenRandom API
	// - On macOS: uses SecRandomCopyBytes
	//
	// Fun fact: secp256k1 is the same curve used by Bitcoin! The private key
	// format is identical, but addresses differ (Bitcoin uses different hashing).
	//
	// Nerdy detail: The private key is a 256-bit number (32 bytes). It must be
	// in the range [1, secp256k1_order - 1]. crypto.GenerateKey() ensures this.
	priv, err := crypto.GenerateKey()
	if err != nil {
		log.Fatalf("generate key: %v", err)
	}

	// ============================================================
	// STEP 2: Derive Public Key from Private Key
	// ============================================================
	// Derive public key and Ethereum address (keccak256(pubkey)[12:]).
	//
	// Mathematical foundation:
	// - Public key = private_key * G (where G is the generator point)
	// - This is a point multiplication on the elliptic curve
	// - Computing public_key from private_key is easy (multiplication)
	// - Computing private_key from public_key is computationally infeasible
	//   (discrete logarithm problem)
	//
	// The public key is a point on the elliptic curve:
	// - Uncompressed: 64 bytes (x-coordinate + y-coordinate)
	// - Compressed: 33 bytes (x-coordinate + parity bit for y)
	//
	// Type assertion: priv.Public() returns crypto.PublicKey interface.
	// We assert it to *ecdsa.PublicKey (the concrete type for secp256k1).
	pub := priv.Public().(*ecdsa.PublicKey)

	// ============================================================
	// STEP 3: Derive Ethereum Address from Public Key
	// ============================================================
	// Ethereum addresses are NOT the public key directly!
	// Instead: address = keccak256(public_key)[12:] (last 20 bytes)
	//
	// Why keccak256?
	// - Ethereum uses Keccak-256 (SHA-3 variant) instead of SHA-256
	// - This was chosen before SHA-3 was standardized
	// - Ethereum uses the original Keccak specification
	//
	// Why 20 bytes?
	// - 20 bytes = 160 bits = 2^160 possible addresses
	// - That's more than the number of atoms on Earth!
	// - Collisions are astronomically unlikely
	//
	// Address format:
	// - Hex-encoded: "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb"
	// - Can be checksummed (EIP-55) for typo detection
	addr := crypto.PubkeyToAddress(*pub)
	
	// Display the generated key information
	// Note: In production, NEVER print private keys! This is for educational purposes only.
	fmt.Printf("Generated key:\n  address:   %s\n  priv(hex): 0x%x\n", addr.Hex(), crypto.FromECDSA(priv))

	// ============================================================
	// STEP 4: Create Keystore Directory
	// ============================================================
	// Create the output directory with proper permissions.
	// 0o700 = owner read/write/execute only (no group/other access)
	//
	// Security principle: Least privilege. Only the owner should be able
	// to access the keystore directory.
	//
	// os.MkdirAll creates parent directories if needed (like mkdir -p).
	if err := os.MkdirAll(*outDir, 0o700); err != nil {
		log.Fatalf("mkdir keystore dir: %v", err)
	}

	// ============================================================
	// STEP 5: Create Keystore and Encrypt Private Key
	// ============================================================
	// Create a new keystore with standard scrypt parameters.
	//
	// Keystore encryption process:
	// 1. Key Derivation Function (KDF): Uses scrypt to derive encryption key from passphrase
	//    - StandardScryptN = 262144 (CPU/memory cost parameter)
	//    - StandardScryptP = 1 (parallelization parameter)
	//    - This makes brute-force attacks much harder (key stretching)
	// 2. Encryption: Uses AES-128-CTR to encrypt the private key
	// 3. MAC: Uses keccak256 to create a message authentication code
	//    - Verifies passphrase correctness (prevents tampering)
	//
	// Computer Science principle: Key stretching makes brute-force attacks
	// computationally expensive. Instead of trying 1000 passphrases/second,
	// attackers might only try 1 passphrase/second (or slower).
	//
	// Security trade-offs:
	// - ✅ Safer than raw hex (encrypted at rest)
	// - ✅ Can use strong passphrases
	// - ❌ Still vulnerable if passphrase is weak
	// - ❌ Requires passphrase every time you unlock
	ks := keystore.NewKeyStore(*outDir, keystore.StandardScryptN, keystore.StandardScryptP)
	
	// Import the private key into the keystore (encrypts and saves to disk)
	account, err := ks.ImportECDSA(priv, *pass)
	if err != nil {
		log.Fatalf("keystore import: %v", err)
	}
	
	// Display keystore file location
	// The keystore file is named with the account address (for easy identification)
	fmt.Printf("Keystore written for %s at %s\n", account.Address.Hex(), filepath.Join(*outDir, filepath.Base(account.URL.Path)))

	// ============================================================
	// STEP 6: Unlock Keystore to Verify Recovery
	// ============================================================
	// Unlock keystore to prove we can recover the same address.
	// This verifies that encryption/decryption works correctly.
	//
	// Unlocking process:
	// 1. Derive encryption key from passphrase (using scrypt)
	// 2. Decrypt the private key (using AES-128-CTR)
	// 3. Verify MAC (ensures passphrase is correct)
	// 4. Derive address from decrypted private key
	//
	// If the passphrase is wrong, MAC verification fails and unlock fails.
	if err := ks.Unlock(account, *pass); err != nil {
		log.Fatalf("unlock failed: %v", err)
	}
	fmt.Printf("Unlocked keystore; recovered address: %s\n", account.Address.Hex())

	// ============================================================
	// EDUCATIONAL NOTES & COMPARISONS
	// ============================================================
	//
	// Building on previous modules:
	// - Module 01-02: You learned to query Ethereum nodes
	// - This module: You learned WHO is making those queries (addresses from keys)
	//
	// Connection to Solidity:
	// - msg.sender in Solidity is the address derived from the transaction signer's key
	// - Access control uses addresses: require(msg.sender == owner)
	// - Events often include indexed address parameters
	//
	// Comparisons:
	// - Keystore JSON uses scrypt/PBKDF2 to stretch passphrases; raw hex is risky at rest
	// - ethers.js equivalent: Wallet.createRandom(), wallet.encrypt(password)
	// - Hardware wallets keep the private key off your disk entirely (most secure)
	//
	// Real-world analogies:
	// - Private key = master key; keystore = locked safe; passphrase = safe combo
	// - Address = mailbox number (how people find you)
	// - Public key = lock mechanism (anyone can see it, but only master key opens it)
	//
	// Security best practices:
	// - Never share private keys
	// - Use strong, randomly generated passphrases
	// - Backup keystore files securely (encrypted backups)
	// - Consider hardware wallets for large amounts
	//
	// Next steps (module 04):
	// - You'll query account balances using addresses (the ones you just generated!)
	// - Distinguish between EOA and contract accounts
	// - Understand account state on the blockchain
}
