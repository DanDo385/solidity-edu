# geth-23-mempool

**Goal:** inspect pending transactions (where supported) and understand mempool visibility limits.

## Big Picture

Pending txs live in the txpool before inclusion. Many public RPCs do not expose full mempool; Geth’s `eth_pendingTransactions` or `txpool_*` may be restricted. Visibility varies by provider and node config.

## Learning Objectives
- Attempt `eth_pendingTransactions` and handle lack of support.
- Understand mempool privacy/visibility trade-offs.
- Recognize that pending txs can be evicted/replaced (nonce rules, gas price/fee bumping).

## Prerequisites
- Modules 05–06 (tx basics/fees).

## Real-World Analogy
- Waiting room with frosted glass: some venues let you peek, others hide it.

## Steps
1. Parse RPC, limit.
2. Call `eth_pendingTransactions`.
3. Print a few pending tx summaries if available; note errors otherwise.

## Fun Facts & Comparisons
- Geth’s `txpool_content` offers richer view but needs txpool API enabled.
- Mempool contents are not part of consensus; they can differ per node and change rapidly.
- MEV and privacy concerns affect what is exposed.

## Related Solidity-edu Modules
- Tx construction (modules 05–06) and replacement rules.
- Security/MEV awareness (conceptual link).

## Files
- Starter: `cmd/geth-23-mempool/main.go`
- Solution: `cmd/geth-23-mempool_solution/main.go`
