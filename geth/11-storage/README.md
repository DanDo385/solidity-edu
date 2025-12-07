# 11-storage: Reading Raw Storage Slots

**Goal:** Read raw storage slots directly from contracts, including mapping slots, and connect to Solidity storage layout.

## Big Picture: Storage as a Cryptographic Database

Ethereum's storage is like a **cryptographic hash table** where every contract has 2^256 possible 32-byte slots. Unlike traditional databases, storage slots are:
- **Immutable** (once written, can't be changed without a transaction)
- **Cryptographically verifiable** (committed to the state root in block headers)
- **Deterministic** (same contract code + same inputs = same storage layout)

**Computer Science principle:** Storage is organized as a **Merkle-Patricia trie**. The `stateRoot` in block headers is the root hash of this trie. Every storage slot is part of this tree, making it possible to prove "contract X has value Y in slot Z" without downloading the entire state.

### The Storage Model

```
┌─────────────────────────────────────────────────────────┐
│              Contract Storage (2^256 slots)             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐             │
│  │  Slot 0  │  │  Slot 1  │  │  Slot 2  │  ...        │
│  │ 32 bytes │  │ 32 bytes │  │ 32 bytes │             │
│  └──────────┘  └──────────┘  └──────────┘             │
│                                                          │
│  Simple variables: Direct slot access                   │
│  Mappings: slot = keccak256(key, baseSlot)             │
│  Arrays: base = keccak256(slot), then base + index      │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │   State Root (Merkle)  │
              │   (in block header)    │
              └───────────────────────┘
```

**Real-world analogy:** Think of storage slots as **numbered lockers in a gym**:
- **Simple variables:** Locker #5 always contains your jacket
- **Mappings:** To find locker for "Alice", compute: locker_number = hash("Alice" + aisle_number)
- **Arrays:** All items stored in lockers starting at a computed base number

## Learning Objectives

By the end of this module, you should be able to:

1. **Understand storage slot layout:**
   - Simple variables: Direct slot access (slot 0, 1, 2, ...)
   - Mappings: `slot = keccak256(abi.encode(key, baseSlot))`
   - Dynamic arrays: `base = keccak256(slot)`, then `base + index`
   - Packed variables: Multiple small types in one slot

2. **Call `eth_getStorageAt` via Go's `StorageAt` method:**
   - Read raw 32-byte values from any slot
   - Understand that values are returned as raw bytes (you must decode)

3. **Compute mapping slot hashes:**
   - Hash the key and base slot together
   - Use proper padding (32 bytes for each component)

4. **Connect to Solidity storage layout:**
   - Relate Go storage reads to Solidity variable declarations
   - Understand packed vs unpacked storage
   - Decode common types (uint256, address, bool)

## Prerequisites

- **Modules 01-10:** You should understand RPC basics, blocks, transactions, and ABI encoding
- **Solidity-edu 01 (Datatypes & Storage):** Foundational storage layout rules
- **Solidity-edu 06 (Mappings, Arrays & Gas):** Mapping slot calculation
- **Go basics:** Hashing, hex encoding, big integers

## Building on Previous Modules

### From Module 01-02 (RPC Basics)
- You learned to query blocks and transactions
- Now you're querying **state** (storage slots)
- Storage is part of the state trie committed to `stateRoot` in block headers

### From Module 11 (Storage) - This Module
- This is the foundation for understanding how contracts store data
- Storage proofs (module 12) use the same slot calculations

### Connection to Solidity-edu

**From Solidity 01 (Datatypes & Storage):**
- Storage slots are 32 bytes each
- Variables are packed when possible (uint128 + uint128 in one slot)
- Mappings use `keccak256(key, slot)` for storage location
- Arrays store length in the slot, data at `keccak256(slot)`

**From Solidity 06 (Mappings, Arrays & Gas):**
- Mapping slot calculation: `keccak256(abi.encode(key, baseSlot))`
- Dynamic array slot calculation: `keccak256(slot)` for base, then `base + index`
- Understanding these calculations helps optimize gas costs

## Understanding Storage Slot Calculation

### Simple Variables

```solidity
contract Simple {
    uint256 public value;      // Slot 0
    address public owner;      // Slot 1
    bool public initialized;   // Slot 2
}
```

**Storage layout:**
- `value` → Slot 0 (32 bytes)
- `owner` → Slot 1 (32 bytes, but only 20 bytes used)
- `initialized` → Slot 2 (32 bytes, but only 1 bit used)

**Go code to read:**
```go
slot0 := common.BigToHash(big.NewInt(0))
value, _ := client.StorageAt(ctx, contractAddr, slot0.Bytes(), nil)
```

### Mappings

```solidity
contract Mapping {
    mapping(address => uint256) public balances;  // Slot 0 (base slot)
}
```

**Storage calculation:**
- Base slot: 0
- Key: `0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb`
- Storage slot: `keccak256(abi.encode(key, baseSlot))`
  - = `keccak256(0x0000...742d35Cc6634C0532925a3b844Bc9e7595f0bEb, 0x0000...0000)`

**Go code:**
```go
h := sha3.NewLegacyKeccak256()
h.Write(common.LeftPadBytes(key.Bytes(), 32))  // Pad key to 32 bytes
h.Write(common.LeftPadBytes(slot.Bytes(), 32)) // Pad slot to 32 bytes
mapSlot := h.Sum(nil)
```

### Dynamic Arrays

```solidity
contract Array {
    uint256[] public items;  // Slot 0
}
```

**Storage calculation:**
- Length stored in slot 0
- Data starts at `keccak256(slot 0)`
- Item at index `i`: `keccak256(slot 0) + i`

**Computer Science principle:** This is similar to how hash tables work. The hash function distributes array elements across storage slots to avoid collisions.

## Real-World Analogies

### The Gym Locker Analogy
- **Storage slots** = Numbered lockers (each holds 32 bytes)
- **Simple variables** = Your assigned locker number (always the same)
- **Mappings** = "Find locker for Alice" → Compute: `hash("Alice" + aisle_number)`
- **Arrays** = All items stored in consecutive lockers starting at a computed base

### The Database Table Analogy
- **Storage slots** = Database rows (each row is 32 bytes)
- **Simple variables** = Direct row access (row 0, row 1, row 2)
- **Mappings** = Indexed lookup: `SELECT * FROM table WHERE key = 'Alice'` → hash(key) = row number
- **Arrays** = Sequential rows starting at a computed offset

### The Memory Address Analogy
- **Storage slots** = Memory addresses (each address holds 32 bytes)
- **Simple variables** = Fixed memory addresses (like global variables in C)
- **Mappings** = Hash table lookup (compute address from key)
- **Arrays** = Contiguous memory allocation (base address + index offset)

## Fun Facts & Nerdy Details

### Storage Slot Limits
- **Total slots:** 2^256 (astronomically large, effectively unlimited)
- **Slot size:** 32 bytes (256 bits)
- **Gas cost:** 
  - First write (SSTORE cold): ~20,000 gas
  - Update (SSTORE warm): ~5,000 gas
  - Read (SLOAD cold): ~2,100 gas
  - Read (SLOAD warm): ~100 gas

### Packing Optimization
Solidity automatically packs variables when possible:
```solidity
struct Packed {
    uint128 a;  // Slot 0, bytes 0-15
    uint128 b;  // Slot 0, bytes 16-31
    uint256 c;  // Slot 1 (doesn't fit in slot 0)
}
```

**Gas savings:** Packing saves storage slots, which saves gas on writes!

### Mapping Collision Resistance
- **Key space:** 2^256 possible keys
- **Slot space:** 2^256 possible slots
- **Collision probability:** Negligible (keccak256 is cryptographically secure)
- **Real-world:** No known collisions in production

### Storage vs Memory vs Calldata
- **Storage:** Persistent, on-chain, expensive (20k gas per write)
- **Memory:** Temporary, function-scoped, cheap (~3 gas per 32-byte word)
- **Calldata:** Read-only, transaction data, cheapest (no storage cost)

## Comparisons

### Go `ethclient.StorageAt` vs JavaScript `ethers.js`

| Aspect | Go `ethclient` | JavaScript `ethers.js` |
|--------|----------------|------------------------|
| Method | `client.StorageAt(ctx, addr, slot, block)` | `provider.getStorageAt(addr, slot, block)` |
| Returns | `[]byte` (raw 32 bytes) | `string` (hex-encoded) |
| Decoding | Manual (you decode) | Manual (you decode) |
| Type safety | Compile-time (Go types) | Runtime (JavaScript) |

**Same JSON-RPC:** Both call `eth_getProof` under the hood. The difference is in ergonomics and type safety.

### Storage vs State vs Code

| Concept | What It Is | How to Query |
|---------|------------|--------------|
| **Storage** | Contract's persistent data | `eth_getStorageAt` |
| **State** | All accounts + storage | `stateRoot` in block header |
| **Code** | Contract bytecode | `eth_getCode` |

**Computer Science principle:** Storage is part of state. State includes:
- Account balances (EOA)
- Account nonces (EOA)
- Contract code (contract accounts)
- Contract storage (contract accounts)

## Related Solidity-edu Modules

- **01 Datatypes & Storage:** Foundational storage layout rules, packing, slot allocation
- **06 Mappings, Arrays & Gas:** Mapping slot calculation, array storage, gas optimization
- **12 Proofs (geth module 12):** Storage proofs use the same slot calculations you learn here

## What You'll Build

In this module, you'll create a CLI that:
1. Takes a contract address and storage slot number
2. Optionally takes a mapping key
3. Computes the correct storage slot (with mapping hash if needed)
4. Reads raw 32-byte values via `eth_getStorageAt`
5. Displays the raw hex-encoded value

**Key learning:** You'll understand how Solidity's storage layout translates to actual on-chain storage slots. This is essential for:
- Debugging contract state
- Building indexers
- Verifying storage proofs
- Understanding gas costs

## Files

- **Starter:** `cmd/11-storage/main.go` - Your starting point with TODO comments
- **Solution:** `cmd/11-storage_solution/main.go` - Complete implementation with detailed comments

## Next Steps

After completing this module, you'll move to **12-proofs** where you'll:
- Fetch Merkle-Patricia trie proofs for accounts and storage slots
- Understand how proofs enable trust-minimized verification
- Connect storage slot calculations to proof paths
- Learn how light clients verify state without full sync
