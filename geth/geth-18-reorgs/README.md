# geth-18-reorgs

**Goal:** detect reorgs by comparing stored block hashes to parent hashes; learn how to rewind/rescan.

## Big Picture

Reorgs happen when a different chain of blocks becomes canonical. Shallow reorgs are normal; indexers and monitors must detect them and replay affected ranges. Comparing parentHash to previously stored hash reveals mismatches.

## Learning Objectives
- Fetch sequential blocks and track hash/parentHash.
- Detect parent mismatches (reorg hint).
- Understand how to rollback and rescan safely.

## Prerequisites
- Modules 09–17 (events, indexing).

## Real-World Analogy
- Ledger page revised: if a page points to a different previous page, redo that section of the archive.

## Steps
1. Parse start/count.
2. Iterate blocks, storing hash and checking parent matches prior hash.
3. Print warnings on mismatch.
4. (Optional) implement rewind depth and rescan.

## Fun Facts & Comparisons
- Mainnet reorgs are usually shallow (1–2 blocks), but deeper ones can happen on unstable networks.
- Store (number, hash) in DB; on mismatch, rollback a few blocks and rescan.

## Related Solidity-edu Modules
- Events/Indexing — reorg handling protects your off-chain state.
- Consensus overview — ties back to fork choice in execution/consensus split.

## Files
- Starter: `cmd/geth-18-reorgs/main.go`
- Solution: `cmd/geth-18-reorgs_solution/main.go`
