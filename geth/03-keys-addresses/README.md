# 03-keys-addresses: Cryptographic Identity on Ethereum

**Goal:** Generate Ethereum keys in Go, derive addresses, and understand keystore JSON vs raw private keys.

## Big Picture: From "What" to "Who"

In **modules 01-02**, you learned to query Ethereum nodes—you were asking "what is the latest block?" or "what transactions are in this block?". Now we're moving to **"who is talking?"**—understanding cryptographic identity on Ethereum.

**EOA (Externally Owned Account) identity** = (private key, public key, address). This is the foundation of all Ethereum interactions:
- **Private key:** Your secret (never share this!)
- **Public key:** Derived from private key (can be shared)
- **Address:** Derived from public key (this is what you share publicly)

**Computer Science principle:** This is **public-key cryptography**. The private key can sign messages, and anyone with the public key can verify signatures. But you can't derive the private key from the public key—that's the mathematical foundation (discrete logarithm problem on elliptic curves).

### The Connection to Solidity

When you write Solidity code, `msg.sender` is the address derived from the signer's private key. This is how access control works:
```solidity
mapping(address => uint256) balances;

function transfer(address to, uint256 amount) external {
    require(balances[msg.sender] >= amount, "Insufficient balance");
    balances[msg.sender] -= amount;
    balances[to] += amount;
}
```

The `msg.sender` is the address of whoever signed the transaction. This module shows you how that address is derived!

## Learning Objectives

By the end of this module, you should be able to:

1. **Generate a secp256k1 private key** and understand the cryptographic primitives
2. **Derive the public key** from the private key (deterministic process)
3. **Derive the Ethereum address** from the public key (keccak256 hash)
4. **Save/load a key in Geth keystore JSON format** with passphrase encryption
5. **Compare raw hex vs keystore** security trade-offs
6. **Connect addresses to Solidity's `msg.sender`** and access control patterns

## Prerequisites

- **Module 02 (02-rpc-basics):** You should understand how to connect to Ethereum nodes
- **Go basics:** File I/O, error handling, flags
- **Conceptual understanding:** Public-key cryptography basics (helpful but not required)

## Building on Previous Modules

### From Module 01 (01-stack)
- You learned to connect to Ethereum nodes via JSON-RPC
- Now you're learning **who** is making those connections

### From Module 02 (02-rpc-basics)
- You learned about blocks and transactions
- Transactions are **signed** with private keys—this module shows you how those keys work

### Connection to Solidity-edu
- **Functions & Payable:** `msg.sender` comes from the signer's address (derived from private key)
- **Modifiers & Access Control:** Ownership checks use `msg.sender == owner`, where `owner` is an address
- **Events & Logging:** Events often include `indexed address` parameters—these are addresses derived from keys

## Understanding secp256k1: The Mathematical Foundation

**secp256k1** is an elliptic curve used by both Bitcoin and Ethereum. Here's the nerdy math:

### Elliptic Curve Cryptography (ECC)
- **Private key:** A random 256-bit number (32 bytes)
- **Public key:** A point on the elliptic curve, computed as `public_key = private_key * G`, where `G` is the generator point
- **Key insight:** Computing `public_key` from `private_key` is easy (multiplication). Computing `private_key` from `public_key` is computationally infeasible (discrete logarithm problem)

**Fun fact:** The same curve is used by Bitcoin! This means you can use the same private key for both Bitcoin and Ethereum (though addresses differ because Ethereum uses keccak256 while Bitcoin uses different hashing).

### Address Derivation: The Ethereum Way

Ethereum addresses are **NOT** the public key directly. Instead:

1. **Public key:** 64 bytes (uncompressed) or 33 bytes (compressed)
2. **Hash the public key:** `keccak256(public_key)` → 32 bytes
3. **Take last 20 bytes:** `keccak256(public_key)[12:]` → 20 bytes = address

**Why keccak256?** Ethereum uses Keccak-256 (SHA-3 variant) instead of SHA-256. This was chosen before SHA-3 was standardized, so Ethereum uses the original Keccak specification.

**Nerdy detail:** The address is 20 bytes (160 bits), which gives 2^160 possible addresses. That's more than the number of atoms on Earth! Collisions are astronomically unlikely.

## Keystore Files: Encrypted Key Storage

### The Problem with Raw Private Keys

Storing private keys as raw hex strings is **dangerous**:
- If someone gains access to your disk, they have your key
- No protection against accidental exposure
- Hard to manage multiple keys

### The Solution: Keystore JSON

**Keystore files** encrypt private keys with a passphrase:

```json
{
  "address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
  "crypto": {
    "cipher": "aes-128-ctr",
    "cipherparams": { "iv": "..." },
    "ciphertext": "...",
    "kdf": "scrypt",
    "kdfparams": { "n": 262144, "r": 8, "p": 1, "dklen": 32, "salt": "..." },
    "mac": "..."
  },
  "id": "...",
  "version": 3
}
```

**How it works:**
1. **KDF (Key Derivation Function):** Uses scrypt or PBKDF2 to derive an encryption key from your passphrase
2. **Encryption:** Uses AES-128-CTR to encrypt the private key
3. **MAC (Message Authentication Code):** Verifies the passphrase is correct (prevents tampering)

**Computer Science principle:** This is **key stretching**. Instead of using your passphrase directly as the encryption key, we derive a stronger key using a slow function (scrypt). This makes brute-force attacks much harder.

**Security trade-offs:**
- ✅ Safer than raw hex (encrypted at rest)
- ✅ Can use strong passphrases
- ❌ Still vulnerable if passphrase is weak
- ❌ Requires passphrase every time you unlock

### Hardware Wallets: The Ultimate Security

**Hardware wallets** (Ledger, Trezor) keep private keys **off your computer entirely**:
- Keys never leave the hardware device
- Signing happens on-device
- Even if your computer is compromised, keys are safe

**Comparison:**
- **Software keystore:** Encrypted file on disk (this module)
- **Hardware wallet:** Key never touches disk (most secure)

## Real-World Analogies

### The Master Key Analogy
- **Private key** = Master key to a building
- **Public key** = The lock mechanism (anyone can see it, but only the master key opens it)
- **Address** = The building's street address (how people find you)
- **Keystore file** = A locked safe containing the master key
- **Passphrase** = The combination to the safe

### The SSH Key Analogy
- **Private key** = Your SSH private key (`~/.ssh/id_rsa`)
- **Public key** = Your SSH public key (`~/.ssh/id_rsa.pub`)
- **Keystore file** = Encrypted SSH key file (with passphrase)
- **Address** = Your username/hostname (how others identify you)

### The Email Analogy
- **Private key** = Your email password
- **Public key** = Your email address's public key (for PGP encryption)
- **Address** = Your email address (what you share publicly)
- **Keystore** = Password manager entry (encrypted storage)

## Fun Facts & Nerdy Details

### secp256k1 Curve Parameters
- **Curve name:** secp256k1 = "Standards for Efficient Cryptography, Prime field, 256-bit, Koblitz curve"
- **Generator point G:** A specific point on the curve (hardcoded constant)
- **Order:** The number of points on the curve (very large prime number)
- **Used by:** Bitcoin, Ethereum, and many other cryptocurrencies

### Address Checksums (EIP-55)
Ethereum addresses can be **checksummed** (mixed case):
- `0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb` (checksummed)
- `0x742d35cc6634c0532925a3b844bc9e7595f0beb` (lowercase)

The checksum helps detect typos. Wallets typically display checksummed addresses.

**Fun fact:** The checksum algorithm uses keccak256! It capitalizes letters based on the hash of the lowercase address.

### Key Generation: True Randomness
- **Source:** Cryptographically secure random number generator (CSPRNG)
- **Go's `crypto/rand`:** Uses OS-provided randomness (e.g., `/dev/urandom` on Linux)
- **Critical:** Weak randomness = weak keys = compromised accounts

**Nerdy detail:** If you generate a key using a predictable source (like `time.Now().Unix()`), attackers can guess your key. Always use cryptographically secure randomness!

### Keystore Encryption Details
- **Scrypt parameters:** `N=262144, r=8, p=1` (StandardScryptN/P)
- **Why scrypt?** It's memory-hard, making GPU/ASIC attacks harder
- **AES-128-CTR:** Counter mode encryption (allows parallel encryption/decryption)
- **MAC:** Uses keccak256 to verify passphrase correctness

## Comparisons

### Raw Hex vs Keystore
| Aspect | Raw Hex | Keystore |
|--------|---------|----------|
| Security | ❌ No encryption | ✅ Encrypted |
| Convenience | ✅ Simple | ❌ Requires passphrase |
| Multi-key | ❌ Hard to manage | ✅ Easy (one file per key) |
| Recovery | ❌ Lost if file deleted | ✅ Can backup encrypted file |

### Software Keystore vs Hardware Wallet
| Aspect | Software Keystore | Hardware Wallet |
|--------|-------------------|-----------------|
| Security | Medium | High |
| Convenience | High | Medium |
| Cost | Free | $50-200 |
| Use case | Development, small amounts | Large amounts, production |

### Go `crypto` vs JavaScript `ethers.js`
- **Go:** `crypto.GenerateKey()` → Returns `*ecdsa.PrivateKey`
- **JavaScript:** `Wallet.createRandom()` → Returns `Wallet` object
- **Same primitives:** Both use secp256k1 under the hood

## Related Solidity-edu Modules

- **02 Functions & Payable:** `msg.sender` is the address derived from the transaction signer's private key. This module shows you how that address is computed!
- **04 Modifiers & Access Control:** Ownership checks use `msg.sender == owner`. The `owner` variable is an address (like the ones you'll generate in this module).
- **19 Signed Messages:** You'll sign messages with private keys. This module teaches you how to generate and manage those keys.

## What You'll Build

In this module, you'll create a CLI that:
1. Generates a new secp256k1 private key (cryptographically secure)
2. Derives the public key from the private key
3. Derives the Ethereum address from the public key (keccak256 hash)
4. Encrypts the private key into a keystore JSON file (with passphrase)
5. Unlocks the keystore to verify you can recover the same address

**Key learning:** You'll understand the complete flow from private key → public key → address. This is fundamental to all Ethereum interactions!

## Files

- **Starter:** `cmd/03-keys-addresses/main.go` - Your starting point with TODO comments
- **Solution:** `cmd/03-keys-addresses_solution/main.go` - Complete implementation with detailed comments

## Next Steps

After completing this module, you'll move to **04-accounts-balances** where you'll:
- Query account balances using addresses (the ones you just generated!)
- Distinguish between EOA (Externally Owned Accounts) and contract accounts
- Understand the difference between `eth_getBalance` and `eth_getCode`
- Connect addresses to account state on the blockchain
