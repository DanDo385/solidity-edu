# geth-25-toolbox

**Goal:** build a Swiss Army CLI that combines status, block/tx lookup, and event decoding.

## Big Picture

Capstone module that stitches together previous lessons into one tool with subcommands. Reuses RPC basics, block/tx retrieval, receipts/logs decoding, and event filtering.

## Learning Objectives
- Parse subcommands and route to shared helpers.
- Implement status, block, tx, and events commands.
- Reuse ABI decoding for events.

## Prerequisites
- Modules 01–24.

## Real-World Analogy
- Swiss Army knife: one handle, many blades for everyday node ops.
- CPU analogy: reading registers (status), instruction log (block/tx), syscall log (events).

## Steps
1. Parse `status|block|tx|events` subcommands and args.
2. Dial RPC with timeout.
3. Implement handlers: status (head/network), block (header + txs), tx (pending/receipt), events (ERC20 Transfer filter).

## Fun Facts & Comparisons
- Mirrors functionality of tools like `cast`/`etherscan-cli`, but in Go.
- Easy to extend with mempool peek, health checks, or index summaries.

## Related Solidity-edu Modules
- Events & Logging (09, 15), storage/gas lessons (05–06), and indexing (17–18).

## Files
- Starter: `cmd/geth-25-toolbox/main.go`
- Solution: `cmd/geth-25-toolbox_solution/main.go`
