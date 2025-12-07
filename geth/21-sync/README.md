# geth-21-sync

**Goal:** inspect sync progress and understand full/snap/light modes.

## Big Picture

Sync modes: full replays all blocks, snap downloads snapshots then heals, light fetches proofs on demand. `SyncProgress` reports current vs highest block and state sync counters. Nil means the node believes it is synced.

## Learning Objectives
- Call `SyncProgress` and interpret fields.
- Differentiate sync modes conceptually.
- Spot stale nodes (progress non-nil or head lagging).

## Prerequisites
- Module 20 (node info helpful).

## Real-World Analogy
- Downloading a city archive (snapshot) then filling missing pages (healing); or reading every page from genesis (full).

## Steps
1. Parse RPC and timeout.
2. Call `SyncProgress`.
3. Print status (synced vs in-progress).

## Fun Facts & Comparisons
- Snap sync introduced in Geth v1.10; faster initial sync than full.
- Light client support is sparse; many nodes don’t serve light peers.

## Related Solidity-edu Modules
- Storage/gas lessons: state size affects sync times.

## Files
- Starter: `cmd/geth-21-sync/main.go`
- Solution: `cmd/geth-21-sync_solution/main.go`
