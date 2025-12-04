# geth-12-proofs

**Goal:** fetch and interpret account/storage proofs via `eth_getProof`.

## Big Picture

`eth_getProof` returns Merkle-Patricia trie proofs for accounts and storage slots. Proofs are tamper-evident receipts light clients and bridges can verify without full state. Pairs with storage layout (module 11).

## Learning Objectives
- Call `GetProof` for an account and optional storage slot at a block.
- Inspect returned balance/nonce/codeHash/storageHash and proof nodes.
- Understand how proofs enable trust-minimized verification.

## Prerequisites
- Module 11 (storage slots) and basic trie awareness.

## Real-World Analogy
- Notarized receipt stapled to a ledger page showing your entry existed at that block.

## Steps
1. Parse account, slot, optional block.
2. Call `GetProof` and print account/storage proofs.
3. Note proof lengths and values.

## Fun Facts & Comparisons
- Proof paths follow the same hashing scheme as storage slot calculation.
- Hosted RPCs may disable `eth_getProof`; own node recommended.
- Light clients rely on proofs to check state without full sync.

## Related Solidity-edu Modules
- Storage & Mappings — slot math that proofs cover.
- Events & Logging — proofs differ from logs (logs are in receipts, not storage trie).

## Files
- Starter: `cmd/geth-12-proofs/main.go`
- Solution: `cmd/geth-12-proofs_solution/main.go`
