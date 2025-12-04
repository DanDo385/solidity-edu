# geth-03-keys-addresses

**Goal:** generate Ethereum keys in Go, derive addresses, and understand keystore JSON vs raw private keys.

## Big Picture

EOA identity = (private key, public key, address). Geth can load keys from JSON keystores or raw hex; wallets like MetaMask do the same under the hood. Solidity’s `msg.sender` is the address derived from the signer’s key. We’re moving from “talking to a node” (modules 01–02) to “who is talking.”

## Learning Objectives

- Generate a secp256k1 private key and derive the public key + address.
- Save/load a key in Geth keystore JSON format (with a passphrase).
- Compare raw hex vs keystore UX and security trade-offs.
- Connect the derived address to Solidity’s `msg.sender` and access control patterns.

## Prerequisites

- Module 02 (RPC basics).
- Go basics; comfort with files/env vars.

## Real-World Analogy

- Private key = master key; public key = the key’s blueprint; address = the mailbox number printed on envelopes.
- CPU analogy: private key = root SSH key; keystore file = encrypted SSH key on disk; passphrase = unlock phrase.

## Steps

1. Generate a new keypair.
2. Derive the address and print it.
3. Encrypt key to keystore JSON (temporary file) using a passphrase.
4. Decrypt the keystore and confirm the same address.

## Fun Facts & Comparisons

- Keystore JSON uses PBKDF2/scrypt for key stretching—safer than storing raw hex.
- JS ethers.js: `Wallet.createRandom()`, `wallet.encrypt()` mirror this flow.
- Hardware wallets keep keys off-disk; keystores are a software fallback.
- secp256k1 curve is also used by Bitcoin; Ethereum addresses are keccak(pubkey)[12:].

## Related Solidity-edu Modules

- Functions & Payable — `msg.sender` comes from the signer’s address.
- Modifiers & Access Control — ownership checks hinge on derived addresses.

## Files

- Starter: `cmd/geth-03-keys-addresses/main.go`
- Solution: `cmd/geth-03-keys-addresses_solution/main.go`
