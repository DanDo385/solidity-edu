# geth-02-rpc-basics

**Goal:** build a tiny JSON-RPC client, call common endpoints, and practice timeouts/retries.

## Big Picture

JSON-RPC is your “librarian desk” to Ethereum: you ask for data (`eth_blockNumber`, `eth_getBlockByNumber`) or submit work (transactions). Geth exposes this API; hosted RPCs proxy it with rate limits.

## Learning Objectives

- Initialize `ethclient` with context timeouts.
- Call `eth_blockNumber`, `eth_getBlockByNumber`, `net_version`.
- Inspect block fields (hash, parentHash, gasUsed, tx count).
- Understand JSON-RPC vs running a node (limitations, debug/admin access).

## Prerequisites

- Module 01 (chain/head ping).
- Go basics; comfort with flags and contexts.

## Real-World Analogy

- Calling the city clerk for the latest ledger page and a photocopy of that page (full block) to see every entry (transactions).

## Steps

1. Parse `-rpc` (defaults to `INFURA_RPC_URL` env if set) and `-timeout`.
2. Dial with `ethclient.DialContext`.
3. Call `BlockNumber`, `NetworkID`, and `BlockByNumber(nil)`.
4. Print summary: block number, hash, parent hash, tx count, gasUsed.
5. Add minimal retry loop for block fetch to show resiliency.

## Fun Facts & Comparisons

- `eth_getBlockByNumber` can return tx hashes or full tx objects; full objects are heavier.
- Hosted RPCs may cache responses; your own node gives freshest view and debug endpoints.
- JS ethers.js: `provider.getBlockNumber()`, `getBlockWithTransactions()`.

## Related Solidity-edu Modules

- Events & Logging — blocks contain log roots/bloom filters.
- Datatypes & Storage — block header includes stateRoot (where storage hangs).

## Files

- Starter: `cmd/geth-02-rpc-basics/main.go`
- Solution: `cmd/geth-02-rpc-basics_solution/main.go`
