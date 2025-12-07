# 05-tx-nonces: Building and Sending Legacy Transactions

**Goal:** Build/send a legacy transaction, manage nonces, and understand replay protection.

## Big Picture: Transaction Lifecycle

Transactions are the fundamental unit of state change on Ethereum. Understanding how to build, sign, and send transactions is essential for any Ethereum developer.

**Computer Science principle:** Transactions are **immutable, ordered messages** that change blockchain state. They're like database transactions, but cryptographically signed and globally ordered.

### Transaction Components

A legacy transaction (pre-EIP-1559) contains:
- **Nonce:** Sequence number (prevents replay and ensures ordering)
- **Gas Price:** Price per unit of gas (in wei)
- **Gas Limit:** Maximum gas to consume
- **To:** Recipient address (nil for contract creation)
- **Value:** Amount of ETH to send (in wei)
- **Data:** Calldata (function calls, contract bytecode, etc.)
- **v, r, s:** Signature components (from ECDSA signing)

**Key insight:** Transactions are **signed messages**. The signature proves you own the private key, and the nonce ensures ordering.

## Learning Objectives

By the end of this module, you should be able to:

1. **Fetch pending nonce** for an address (includes pending transactions)
2. **Build a legacy transaction** with gasPrice
3. **Sign a transaction** with EIP-155 replay protection (chainID)
4. **Send a transaction** to the network
5. **Understand nonce ordering** and why gaps stall subsequent transactions

## Prerequisites

- **Modules 01-04:** RPC basics, keys/addresses, account balances
- **Basic familiarity:** ETH units (wei vs ETH), transaction concepts
- **Go basics:** Error handling, big integers, crypto operations

## Building on Previous Modules

### From Module 03 (03-keys-addresses)
- You learned to generate private keys and derive addresses
- Now you're using those keys to **sign transactions**
- The address you derive is the `from` address in transactions

### From Module 04 (04-accounts-balances)
- You learned to query account balances
- Now you're **changing** those balances by sending transactions
- The nonce you fetch is stored in the account state

### From Module 01 (01-stack)
- You learned about chainID (EIP-155 replay protection)
- Now you're using chainID in transaction signatures
- This prevents transactions from being replayed on other chains

### Connection to Solidity-edu
- **Functions & Payable:** Sending ETH and tracking balances
- **Errors & Reverts:** Transaction status and failure modes connect to receipts (module 15)
- **Gas & Storage:** Understanding gas limits and pricing

## Understanding Nonces: The Ordering Mechanism

### What is a Nonce?

**Nonce** = "number used once" - a sequence number for each address.

**Computer Science principle:** Nonces ensure **ordering** and **uniqueness**. They prevent:
1. **Replay attacks:** Can't reuse the same transaction
2. **Out-of-order execution:** Transactions must be processed sequentially
3. **Double-spending:** Can't send the same transaction twice

### Nonce Rules

- **Start at 0:** First transaction from an address uses nonce 0
- **Increment by 1:** Each subsequent transaction increments the nonce
- **No gaps:** If nonce 5 is missing, nonce 6+ will be stuck pending
- **No duplicates:** Can't reuse a nonce (transaction will fail)

**Fun fact:** Nonces are per-address, not global. Address A can use nonce 0 at the same time address B uses nonce 0.

### Pending vs Confirmed Nonces

- **PendingNonceAt():** Returns the next nonce including pending transactions
- **NonceAt(blockNumber):** Returns nonce at a specific block (confirmed only)

**Production tip:** Use `PendingNonceAt()` when sending transactions to avoid nonce conflicts with pending transactions.

## Real-World Analogies

### The Post Office Queue Analogy
- **Nonce:** Your ticket number
- **Queue:** Transactions waiting to be processed
- **Counter:** Block proposer/miner
- **Problem:** If ticket 5 is missing, tickets 6+ wait forever

### The Database Transaction Analogy
- **Nonce:** Transaction sequence number
- **Ordering:** Transactions must execute in order
- **Atomicity:** Each transaction is all-or-nothing

### The Checkbook Analogy
- **Nonce:** Check number
- **Ordering:** Checks must be cashed in order
- **Gaps:** Missing check numbers cause problems

## Fun Facts & Nerdy Details

### EIP-155: Replay Protection

**Before EIP-155:** Transactions could be replayed across chains (e.g., mainnet → testnet)

**After EIP-155:** ChainID is included in the signature:
- Signature includes `(r, s, v)` where `v` encodes chainID
- Transaction signed for chainID 1 (mainnet) can't be replayed on chainID 11155111 (Sepolia)

**Nerdy detail:** The `v` value is `recoveryID + chainID * 2 + 35`. This encodes both the recovery ID (for ECDSA) and the chain ID.

### Gas Price Mechanics

- **Gas Price:** Price per unit of gas (in wei)
- **Gas Limit:** Maximum gas to consume
- **Total Cost:** `gasPrice * gasUsed` (you pay for gas used, not limit)

**Fun fact:** Legacy transactions use a fixed gas price. EIP-1559 (module 06) introduces dynamic fees with base fee + tip.

### Transaction Signing Process

1. **Serialize transaction:** RLP-encode all fields except signature
2. **Hash:** Keccak256 hash of serialized data
3. **Sign:** ECDSA sign the hash with private key
4. **Encode:** Add signature to transaction (v, r, s)

**Computer Science principle:** Signing the hash (not the raw data) is more efficient and secure. The hash is fixed-size (32 bytes) regardless of transaction size.

## Comparisons

### Legacy vs EIP-1559 Transactions
| Aspect | Legacy (this module) | EIP-1559 (module 06) |
|--------|---------------------|---------------------|
| Gas pricing | Fixed `gasPrice` | Dynamic `baseFee + tip` |
| Fee structure | Single price | Max fee cap + priority tip |
| Efficiency | Less efficient | More efficient |
| Status | Still works | Recommended for production |

### PendingNonceAt vs NonceAt
| Method | Includes Pending | Use Case |
|--------|------------------|----------|
| `PendingNonceAt()` | ✅ Yes | Sending new transactions |
| `NonceAt(block)` | ❌ No | Historical queries |

### Go `ethclient` vs JavaScript `ethers.js`
- **Go:** `client.PendingNonceAt(ctx, addr)` → Returns `uint64`
- **JavaScript:** `provider.getTransactionCount(addr, "pending")` → Returns `BigNumber`
- **Same JSON-RPC:** Both call `eth_getTransactionCount` with `"pending"` block

## Related Solidity-edu Modules

- **02 Functions & Payable:** Sending ETH and tracking balances
- **05 Errors & Reverts:** Transaction status and failure modes connect to receipts (module 15)
- **06 Mappings, Arrays & Gas:** Understanding gas limits and pricing

## What You'll Build

In this module, you'll create a CLI that:
1. Takes recipient address, ETH amount, and private key as input
2. Fetches the pending nonce for the sender
3. Fetches the suggested gas price
4. Builds a legacy transaction
5. Signs the transaction with EIP-155 (chainID) protection
6. Sends the transaction to the network
7. Displays transaction hash and details

**Key learning:** You'll understand the complete transaction lifecycle from building to broadcasting!

## Files

- **Starter:** `cmd/05-tx-nonces/main.go` - Your starting point with TODO comments
- **Solution:** `cmd/05-tx-nonces_solution/main.go` - Complete implementation with detailed comments

## Next Steps

After completing this module, you'll move to **06-eip1559** where you'll:
- Build EIP-1559 dynamic fee transactions
- Understand base fee + priority tip mechanics
- Learn about max fee caps and refunds
- Use the modern transaction format (recommended for production)
