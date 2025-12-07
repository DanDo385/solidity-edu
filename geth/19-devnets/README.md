# geth-19-devnets

**Goal:** interact with a local devnet (e.g., anvil mainnet fork) and inspect balances/heads.

## Big Picture

Devnets let you fork mainnet state and safely test flows: impersonate accounts, fund addresses, and send txs without real risk. Anvil/Hardhat provide JSON-RPC compatible endpoints.

## Learning Objectives
- Dial a local devnet and query balances/head.
- Understand forked state vs live mainnet.
- Impersonation/funding basics (via anvil flags).

## Prerequisites
- Modules 01–05 (RPC, balances, tx basics).

## Real-World Analogy
- Movie set replica of the city ledger—rehearse actions without touching the real one.

## Steps
1. Start anvil fork (outside this script) with `--fork-url $INFURA_RPC_URL`.
2. Dial devnet RPC.
3. Query balance/head for a test address.

## Fun Facts & Comparisons
- Anvil supports `--impersonate` to send txs as any account in forked state.
- Hardhat/Foundry expose similar devnet features; all speak JSON-RPC.

## Related Solidity-edu Modules
- Functions & Payable — practice deposits/withdrawals safely.
- Access Control — test ownership flows without mainnet risk.

## Files
- Starter: `cmd/geth-19-devnets/main.go`
- Solution: `cmd/geth-19-devnets_solution/main.go`
