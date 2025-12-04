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

// EDUCATIONAL NOTES:
// - Private key = master key; public key = blueprint; address = mailbox number (keccak(pubkey)[12:]).
// - Keystore JSON uses scrypt/PBKDF2 to slow down brute-force attacks—safer than raw hex on disk.
// - Hardware wallets keep the key off disk entirely; keystores are software safes.
// - Compare to CPU/OS: private key is like a root SSH key; keystore file is an encrypted SSH key file.
// - We build on module 02 (RPC): this module explains *who* is talking on that RPC line.
func main() {
	// Flags control output location and passphrase. In production, DO NOT hardcode; use env/secret mgr.
	outDir := flag.String("out", "./keystore-demo", "directory to store keystore file")
	pass := flag.String("pass", "changeit", "keystore passphrase (demo only)")
	flag.Parse()

	// 1) Generate a new secp256k1 private key. This is the raw EOA secret.
	priv, err := crypto.GenerateKey()
	if err != nil {
		log.Fatalf("generate key: %v", err)
	}

	// 2) Derive public key and Ethereum address (keccak256(pubkey)[12:]).
	pub := priv.Public().(*ecdsa.PublicKey)
	addr := crypto.PubkeyToAddress(*pub)
	fmt.Printf("Generated key:\n  address:   %s\n  priv(hex): 0x%x\n", addr.Hex(), crypto.FromECDSA(priv))

	// 3) Write a keystore JSON (encrypted with passphrase). Safer than raw hex on disk.
	if err := os.MkdirAll(*outDir, 0o700); err != nil {
		log.Fatalf("mkdir keystore dir: %v", err)
	}
	ks := keystore.NewKeyStore(*outDir, keystore.StandardScryptN, keystore.StandardScryptP)
	account, err := ks.ImportECDSA(priv, *pass)
	if err != nil {
		log.Fatalf("keystore import: %v", err)
	}
	fmt.Printf("Keystore written for %s at %s\n", account.Address.Hex(), filepath.Join(*outDir, filepath.Base(account.URL.Path)))

	// 4) Unlock keystore to prove we can recover the same address.
	if err := ks.Unlock(account, *pass); err != nil {
		log.Fatalf("unlock failed: %v", err)
	}
	fmt.Printf("Unlocked keystore; recovered address: %s\n", account.Address.Hex())

	// Fun facts / comparisons:
	// - Keystore JSON uses scrypt/PBKDF2 to stretch passphrases; raw hex is risky at rest.
	// - ethers.js equivalent: Wallet.createRandom(), wallet.encrypt(password).
	// - Hardware wallets keep the private key off your disk entirely.
	// Analogy:
	// - Private key = master key; keystore = locked safe; passphrase = safe combo; address = mailbox number.
}
