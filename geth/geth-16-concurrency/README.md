# geth-16-concurrency

**Goal:** fetch multiple resources concurrently with a worker pool while respecting RPC limits.

## Big Picture

RPCs can be slow; fan-out speeds things up, but you need to avoid rate limits and handle cancellation. Worker pools with contexts let you balance throughput and safety.

## Learning Objectives
- Build a simple worker pool to fetch block headers concurrently.
- Use contexts to cancel/timeout concurrent work.
- Understand rate limiting/backoff considerations.

## Prerequisites
- Modules 01–10; Go concurrency basics.

## Real-World Analogy
- Multiple clerks fetching ledger pages in parallel; close the office when time is up (context cancel).

## Steps
1. Parse start/count/workers.
2. Spin up worker goroutines that fetch headers.
3. Feed jobs, close channel, wait for completion.
4. Add logging for errors.

## Fun Facts & Comparisons
- Too much fan-out can trigger provider rate limits; add backoff/token bucket in production.
- ethers.js/JS often uses Promise.all; Go idiom is worker pools with channels.

## Related Solidity-edu Modules
- None directly; this is Go ergonomics that helps for indexing and monitoring.

## Files
- Starter: `cmd/geth-16-concurrency/main.go`
- Solution: `cmd/geth-16-concurrency_solution/main.go`
