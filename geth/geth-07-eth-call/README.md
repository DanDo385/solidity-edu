# geth-07-eth-call

**Goal:** perform read-only contract calls with manual ABI encoding/decoding.

## Big Picture

`eth_call` simulates a transaction without persisting state. You encode function selectors and args per ABI, send to the node, and decode the return data. No gas is spent on-chain, but the node executes the EVM locally.

## Learning Objectives
- Pack ABI for simple view functions (ERC20 name/symbol/decimals/totalSupply).
- Call contracts with `CallContract` and decode results.
- Handle reverts and raw return data.

## Prerequisites
- Modules 01–06 (RPC, keys/tx basics).
- Basic ABI understanding.

## Real-World Analogy
- Asking a clerk to read a value from the ledger without recording anything. CPU analogy: read-only syscall inspecting memory.

## Steps
1. Parse contract address and function name.
2. Build ABI-encoded call data.
3. Execute `CallContract` at latest block.
4. Decode and print result.

## Fun Facts & Comparisons
- Reverts surface as errors; revert strings live in return data when available.
- ethers.js: `contract.name()` etc. wraps the same ABI encode/decode.
- `eth_call` can target past blocks by specifying a block number.

## Related Solidity-edu Modules
- Functions & Payable — read/write distinction mirrors view/pure vs state-changing.
- Events & Logging — pair calls with log decoding for richer off-chain views.

## Files
- Starter: `cmd/geth-07-eth-call/main.go`
- Solution: `cmd/geth-07-eth-call_solution/main.go`
