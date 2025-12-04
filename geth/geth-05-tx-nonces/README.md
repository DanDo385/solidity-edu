# geth-05-tx-nonces

**Goal:** build/send a legacy transaction, manage nonces, and understand replay protection.

## Big Picture

Transactions from an address are ordered by a monotonically increasing nonce. Legacy txs use `gasPrice`; post-London dynamic-fee txs are in module 06. ChainID (EIP-155) prevents cross-chain replay.

## Learning Objectives
- Fetch pending nonce for an address.
- Build/sign/send a legacy transaction with gasPrice.
- Understand nonce ordering and why gaps stall subsequent txs.

## Prerequisites
- Modules 01–04 (RPC, keys, balances).
- Basic familiarity with ETH units (wei vs ETH).

## Real-World Analogy
- Post-office queue: you take a ticket (nonce); counters process tickets in order. Skipping numbers leaves others stuck.

## Steps
1. Parse recipient, amount, private key.
2. Fetch pending nonce and suggested gasPrice.
3. Build a legacy transaction (21000 gas transfer).
4. Sign with EIP-155 signer (chainID) and send.

## Fun Facts & Comparisons
- Nonce gaps leave later txs pending until the missing nonce is filled or replaced.
- EIP-155 adds chainID into the signature to stop cross-chain replay (e.g., ETH vs fork).
- Production flows prefer EIP-1559 (module 06); legacy still works for compatibility.

## Related Solidity-edu Modules
- Functions & Payable — sending ETH and tracking balances.
- Errors & Reverts — tx status and failure modes connect to receipts (module 15).

## Files
- Starter: `cmd/geth-05-tx-nonces/main.go`
- Solution: `cmd/geth-05-tx-nonces_solution/main.go`
