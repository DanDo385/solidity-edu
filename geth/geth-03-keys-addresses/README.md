# geth-03-keys-addresses

**Goal:** generate Ethereum keys in Go, derive addresses, and understand keystore JSON vs raw private keys.

## Big Picture

EOA identity = (private key, public key, address). Geth can load keys from JSON keystores or raw hex; wallets like MetaMask do the same under the hood. Solidity’s `msg.sender` is the address derived from the signer’s key.

## Learning Objectives

- Generate a secp256k1 private key and derive the public key + address.
- Save/load a key in Geth keystore JSON format (with a passphrase).
- Compare raw hex vs keystore UX and security trade-offs.

## Prerequisites

- Module 02 (basic RPC familiarity).
- Go basics; comfort with files/env vars.

## Real-World Analogy

- Private key = master key; public key = the key’s blueprint; address = the mailbox number printed on envelopes.

## Steps

1. Generate a new keypair.
2. Derive the address and print it.
3. Encrypt key to keystore JSON (temporary file) using a passphrase.
4. Decrypt keystore back and confirm the same address.

## Fun Facts & Comparisons

- Keystore JSON uses PBKDF2/scrypt for key stretching—safer than storing raw hex.
- JS ethers.js: `Wallet.createRandom()`, `wallet.encrypt()` mirror this flow.
- Hardware wallets keep keys off-disk; keystores are a software fallback.

## Related Solidity-edu Modules

- Functions & Payable — `msg.sender` comes from the signer’s address.
- Modifiers & Access Control — ownership checks hinge on derived addresses.

## Files

- Starter: `cmd/geth-03-keys-addresses/main.go`
- Solution: `cmd/geth-03-keys-addresses_solution/main.go`
