# geth-11-storage

**Goal:** read raw storage slots, including mapping slots, and connect to Solidity layout.

## Big Picture

Storage slots are 32-byte “lockers.” Simple variables live at declared slots; mappings/arrays compute slots via hashing. `eth_getStorageAt` lets you peek at raw slots; you must know layout to decode.

## Learning Objectives
- Compute slot hash for simple variables and mappings (keccak(key, slot)).
- Call `StorageAt` and print raw 32-byte values.
- Relate to Solidity storage layout (packed vs unpacked, dynamic types).

## Prerequisites
- Modules 01–10 (RPC, ABI/log basics).
- Solidity storage layout basics from Solidity-edu.

## Real-World Analogy
- Numbered lockers; mappings compute locker numbers from key + aisle (slot).

## Steps
1. Parse contract address, slot, optional mapping key.
2. Compute slot hash (and mapping slot if key provided).
3. Read raw bytes via `StorageAt`.
4. Print results (optionally decode manually).

## Fun Facts & Comparisons
- Dynamic arrays: base = keccak(slot), then base + index.
- Strings/bytes store length in slot; data at keccak(slot).
- ethers.js: `provider.getStorageAt(addr, slot)`—same RPC; decoding is manual.

## Related Solidity-edu Modules
- Datatypes & Storage — foundational layout rules.
- Mappings & Arrays — slot math connects directly.
- Proofs (module 12) — proofs cover the same trie paths.

## Files
- Starter: `cmd/geth-11-storage/main.go`
- Solution: `cmd/geth-11-storage_solution/main.go`
