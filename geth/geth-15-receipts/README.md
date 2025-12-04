# geth-15-receipts

**Goal:** fetch transaction receipts and classify success/failure, logs, and gas usage.

## Big Picture

Receipts record the outcome of a transaction: status, cumulative gas, and emitted logs. They live alongside blocks but outside the state trie. Decoding receipts is key for dApps, indexers, and monitoring.

## Learning Objectives
- Fetch receipts for tx hashes.
- Interpret `status`, `gasUsed`, `logs`, `blockNumber`.
- Tie receipts to log decoding (module 09) and traces (module 13).

## Prerequisites
- Modules 05–09.

## Real-World Analogy
- Delivery receipt with a success stamp and a list of items delivered (logs).
- CPU analogy: syscall return struct with status + emitted events.

## Steps
1. Parse tx hashes.
2. Call `TransactionReceipt` for each.
3. Print status, gasUsed, log count, block number.

## Fun Facts & Comparisons
- Status 1 = success, 0 = revert (post-Byzantium). Pre-Byzantium had no status.
- CumulativeGasUsed is per-block order; useful for gas accounting.
- ethers.js: `provider.getTransactionReceipt` same RPC.

## Related Solidity-edu Modules
- Events & Logging — decode logs from receipts.
- Errors & Reverts — status and revert reasons.

## Files
- Starter: `cmd/geth-15-receipts/main.go`
- Solution: `cmd/geth-15-receipts_solution/main.go`
