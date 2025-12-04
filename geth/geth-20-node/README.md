# geth-20-node

**Goal:** query basic node info (client version, peer count, sync status) from your own Geth node.

## Big Picture

Running your own node grants full control and fresh data. Basic health signals: client version, peer count, and sync progress. Some APIs (admin_*, txpool_*) require enabling extra modules or IPC.

## Learning Objectives
- Call `web3_clientVersion` and `net_peerCount`.
- Check sync progress via `SyncProgress`.
- Understand limits of public RPC vs your own node.

## Prerequisites
- Modules 01–05.

## Real-World Analogy
- Checking the health board: software version, how many neighbors, and whether the node is caught up.

## Steps
1. Parse RPC.
2. Call `web3_clientVersion` and parse peer count (hex string).
3. Check `SyncProgress` (nil = synced).

## Fun Facts & Comparisons
- Peer count is a coarse metric; admin_peers gives richer info (often disabled on HTTP).
- Public RPCs typically hide admin/txpool APIs for safety; use IPC/local for full control.

## Related Solidity-edu Modules
- None directly; this is node ops hygiene that supports all contract work.

## Files
- Starter: `cmd/geth-20-node/main.go`
- Solution: `cmd/geth-20-node_solution/main.go`
