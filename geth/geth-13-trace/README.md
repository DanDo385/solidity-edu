# geth-13-trace

**Goal:** trace a transaction with `debug_traceTransaction` to see call tree and gas usage.

## Big Picture

Tracing replays a transaction and emits detailed execution logs (opcodes, gas, calls). It’s essential for debugging, tooling, and understanding on-chain behavior. Not part of standard `eth_*`; often disabled on hosted RPC—use your own node or anvil.

## Learning Objectives
- Call `debug_traceTransaction` and pretty-print results.
- Understand trace limitations on public RPCs.
- Connect traces to gas costs and call depth.

## Prerequisites
- Modules 05–09 (tx basics, calls, events).
- Access to a node with debug API (local geth/anvil).

## Real-World Analogy
- Flight recorder/black box of a transaction’s execution.

## Steps
1. Parse tx hash and RPC.
2. Call `debug_traceTransaction` with default tracer.
3. Pretty-print JSON result (or further process).

## Fun Facts & Comparisons
- Foundry/Hardhat traces are similar, but formatting differs.
- Traces show internal calls and gas refunds—useful for optimization and audits.
- Some providers expose restricted tracing; your node gives full control.

## Related Solidity-edu Modules
- Gas/Optimization — traces reveal expensive code paths.
- Errors & Reverts — see exactly where/why a revert happened.

## Files
- Starter: `cmd/geth-13-trace/main.go`
- Solution: `cmd/geth-13-trace_solution/main.go`
