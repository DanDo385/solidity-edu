# geth-22-peers

**Goal:** query peer count and understand p2p gossip health.

## Big Picture

Peers gossip txs/blocks across the network. Peer count is a coarse signal of connectivity; richer info lives in admin APIs. Public RPCs often hide peer details.

## Learning Objectives
- Call `net_peerCount` (hex) and parse it.
- Recognize limitations of public RPC vs your own node (admin_peers).
- Relate peer health to data freshness.

## Prerequisites
- Module 20 (node basics).

## Real-World Analogy
- Number of radio stations your node can hear; more stations = better news propagation.

## Steps
1. Parse RPC and timeout.
2. Call `net_peerCount`.
3. Print peer count.

## Fun Facts & Comparisons
- Peer count alone is not quality; some peers may be slow or malicious.
- admin_peers shows client versions/latency but usually requires IPC or admin API enabled.

## Related Solidity-edu Modules
- None directly; supports all chain interactions by ensuring healthy connectivity.

## Files
- Starter: `cmd/geth-22-peers/main.go`
- Solution: `cmd/geth-22-peers_solution/main.go`
