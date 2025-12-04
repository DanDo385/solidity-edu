# geth-01-stack

**Goal:** understand what Geth is, how it fits with consensus clients, and prove connectivity by reading chain ID + latest block.

## Big Picture

Geth is an **execution client**: it executes transactions, maintains the state trie, and exposes JSON-RPC. It pairs with a **consensus client** (Prysm, Lighthouse, Nimbus, etc.) that runs the Beacon Chain and drives fork choice. Think of:

- **Execution client (Geth)** = the city’s accounting department: processes transactions, updates balances (state).
- **Consensus client** = the city council: decides which ledger page is the official one (fork choice via PoS).
- **JSON-RPC** = the customer service desk: you ask for data (blocks, txs) or submit work (transactions).

## Learning Objectives

- Draw the high-level Ethereum stack: execution vs consensus vs networking vs JSON-RPC.
- Use Go + `ethclient` to dial an RPC endpoint with timeouts.
- Query `chainId`, `net_version`, and the latest block header.
- Interpret the difference between **chain ID** (EIP-155 replay protection) and **network ID**.
- Understand why “public RPC” != “running a node” (rate limits, missing debug APIs).

## Prerequisites

- Go basics (modules, `go run`).
- Conceptual Ethereum familiarity (blocks, txs, state).
- From Solidity-edu: “Datatypes & Storage” (slots) and “Events & Logging” (blocks/logs context).

## Real-World Analogy

Calling the city records office: you ask “What’s the latest ledger page number?” (block number) and “Which city am I talking to?” (chain ID). The clerk hands you the stamped page header (block hash/parent hash).

## Fun Facts

- `chainId` was added by EIP-155 to stop replay attacks across chains (e.g., ETH vs ETC).
- `net_version` (network ID) predates `chainId`; some RPCs report both.
- `eth_blockNumber` is cheap; `eth_getBlockByNumber` can be heavy if you request full tx objects.
- Many hosted RPCs disable admin/debug endpoints—run your own node for full power.

## Comparisons

- Go `ethclient` vs JS `ethers.js` provider: same JSON-RPC under the hood; ergonomics differ.
- Geth vs Erigon/Nethermind/Besu: all are execution clients; APIs mostly compatible but debug features differ.
- Mainnet vs L2 RPCs: L2s may expose different endpoints or semantics (e.g., L2-specific gas fields).

## Related Solidity-edu Modules

- 01 Datatypes & Storage — block headers carry state roots that index storage tries.
- 03 Events & Logging — headers include bloom filters and log roots used for event queries.

## Files

- Starter: `cmd/geth-01-stack/main.go` (defaults to `INFURA_RPC_URL` if set)
- Solution: `cmd/geth-01-stack_solution/main.go` (reads `INFURA_RPC_URL` if set)
