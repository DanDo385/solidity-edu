# geth-17-indexer

**Goal:** build a basic ERC20 Transfer indexer into sqlite with a simple query surface.

## Big Picture

Indexers watch events/logs and persist them into databases for fast queries. This module scans a block range for Transfer logs, decodes them, and stores into sqlite. Production indexers add pagination, reorg handling, and richer schemas.

## Learning Objectives
- Construct a filter for Transfer logs.
- Decode indexed/non-indexed params and persist to sqlite.
- Consider reorg handling (hash/number pairs) and pagination.

## Prerequisites
- Modules 09 (events), 15 (receipts), 16 (concurrency) helpful.
- Basic SQL familiarity.

## Real-World Analogy
- Clipping Transfer notices from the newspaper into your filing cabinet for fast lookup.

## Steps
1. Parse token, block range, sqlite path.
2. Create table if needed.
3. Filter logs, decode Transfer, insert rows.
4. (Optional) add pagination and block-hash tracking for reorg safety.

## Fun Facts & Comparisons
- The Graph/Indexers do similar, with PoI/merkle roots for correctness.
- Reorg-safe indexers store block hash and rewind on mismatch (module 18).
- ethers.js: queryFilter + insert into DB follows same pattern.

## Related Solidity-edu Modules
- Events & Logging — schema design and gas trade-offs.
- Reentrancy/DoS — large unbounded loops in contracts differ from off-chain indexing.

## Files
- Starter: `cmd/geth-17-indexer/main.go`
- Solution: `cmd/geth-17-indexer_solution/main.go`
