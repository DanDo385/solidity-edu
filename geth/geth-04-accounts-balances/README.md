# geth-04-accounts-balances

**Goal:** classify EOAs vs contracts and query balances.

## Big Picture

Ethereum accounts come in two flavors: EOAs (no code) and contracts (code at the address). Balances live in the account trie; detecting code helps you understand who you’re talking to. Builds on keys (module 03) and RPC basics (01–02).

## Learning Objectives
- Fetch balances at latest block in wei.
- Detect whether an address has code (contract) or not (EOA).
- Note special cases (precompiles have code; selfdestructed contracts have nonce > 0 but code size 0).

## Prerequisites
- Module 03 (keys/addresses).
- Basic RPC familiarity.

## Real-World Analogy
- Empty plot of land (EOA) vs a building with machinery (contract code) on the same street (address).

## Steps
1. Parse a list of addresses.
2. Call `BalanceAt` for each (wei).
3. Call `CodeAt` to check for bytecode length > 0.
4. Print type + balance.

## Fun Facts & Comparisons
- Precompiles (e.g., 0x01–0x09) have code; they’re special-purpose contracts.
- ethers.js equivalent: `getBalance(addr)`, `getCode(addr)`.
- Code size 0 is a common heuristic for EOAs, but beware selfdestructed contracts (nonce set, code gone).

## Related Solidity-edu Modules
- Access Control / Ownable — ownership checks assume EOAs or smart wallets.
- Functions & Payable — balances change on deposits/withdrawals.

## Files
- Starter: `cmd/geth-04-accounts-balances/main.go`
- Solution: `cmd/geth-04-accounts-balances_solution/main.go`
