# geth-09-events

**Goal:** decode ERC20 Transfer logs and understand topics vs data.

## Big Picture

Events/logs are append-only “newspaper clippings” emitted during tx execution. Indexed params go into topics (bloom-filtered for search); non-indexed go into data. This is the off-chain friendly history of state changes.

## Learning Objectives
- Build a filter query for a token’s Transfer events over a block range.
- Decode indexed vs non-indexed params with ABI.
- Understand log roots/bloom filters in block headers.

## Prerequisites
- Modules 01–08 (RPC, ABI basics).

## Real-World Analogy
- Headlines vs article body: topics are bold headlines; data is the article content.

## Steps
1. Parse token address and block range.
2. Build `FilterQuery` with Transfer topic.
3. Fetch logs, decode `from/to/value`, print summaries.
4. (Optional) paginate for large ranges.

## Fun Facts & Comparisons
- Topics[0] = keccak(event signature). Bloom filters in headers speed up topic searches.
- Logs live in receipts; reorgs can drop/replay logs—handle accordingly.
- ethers.js: `contract.queryFilter(contract.filters.Transfer(), from, to)`.

## Related Solidity-edu Modules
- Events & Logging — schema design and gas trade-offs.
- Datatypes & Storage — logs sit outside storage; cheaper than writing state history.

## Files
- Starter: `cmd/geth-09-events/main.go`
- Solution: `cmd/geth-09-events_solution/main.go`
