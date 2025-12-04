# geth-14-explorer

**Goal:** build a tiny block/tx explorer CLI.

## Big Picture

Block explorers read headers, transactions, and sometimes receipts/logs to present chain activity. Here we fetch a block (latest or numbered) and summarize txs. Extend with receipts/logs/traces for deeper insight.

## Learning Objectives
- Fetch a block by number (or latest) with txs.
- Print header fields and tx summaries (to/value/gasPrice).
- Understand how explorers stitch together headers, txs, receipts.

## Prerequisites
- Modules 01–10, plus tx basics.

## Real-World Analogy
- Flipping to a specific ledger page and reading every line item.

## Steps
1. Parse block number (or use latest).
2. Fetch block with tx objects.
3. Print header summary + tx list.
4. (Optional) enrich with receipts/logs (module 15) or traces (module 13).

## Fun Facts & Comparisons
- Full tx objects are heavier than hashes—use selectively for performance.
- explorers like Etherscan index receipts/logs in databases for fast queries.
- ethers.js: `getBlockWithTransactions` mirrors this flow.

## Related Solidity-edu Modules
- Events & Logging (module 09) — logs enrich tx views.
- Receipts (module 15) — success/fail and gas usage.

## Files
- Starter: `cmd/geth-14-explorer/main.go`
- Solution: `cmd/geth-14-explorer_solution/main.go`
