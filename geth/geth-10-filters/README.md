# geth-10-filters

**Goal:** practice filters and subscriptions (newHeads), and understand polling vs websockets.

## Big Picture

Filters let you query past logs; subscriptions push new data (heads/logs) over websockets. When WS isn’t available, you poll. Detecting reorgs means comparing parent hashes to what you stored.

## Learning Objectives
- Subscribe to `newHeads` over WS.
- Poll latest headers over HTTP fallback.
- Understand reorg detection via parent hash mismatch.

## Prerequisites
- Modules 01–09 (RPC, logs).

## Real-World Analogy
- Live news ticker (WS) vs refreshing the newspaper site periodically (polling).

## Steps
1. Parse RPC, choose WS vs HTTP.
2. If WS: subscribe to heads, print number/hash/parent.
3. If HTTP: poll latest N headers and print summary.
4. Note reorg hint: parent hash mismatch => rewind.

## Fun Facts & Comparisons
- WS endpoints may differ from HTTP (e.g., wss://). Hosted providers may limit WS.
- Log filters can also be streamed via WS (topics + addresses).
- ethers.js: `provider.on('block', ...)` for heads; `provider.getLogs` for polling.

## Related Solidity-edu Modules
- Events & Logging — same filtering applies to logs.
- Reorg handling — pairs with module 18 (rescan on mismatch).

## Files
- Starter: `cmd/geth-10-filters/main.go`
- Solution: `cmd/geth-10-filters_solution/main.go`
