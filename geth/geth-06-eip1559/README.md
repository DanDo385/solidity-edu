# geth-06-eip1559

**Goal:** build/send an EIP-1559 (dynamic fee) transaction and understand base fee + tip math.

## Big Picture

Post-London, Ethereum uses dynamic fees: baseFee (burned) + priority fee (tip). You cap spending with maxFeePerGas and maxPriorityFeePerGas. Effective gas price = min(maxFeeCap, baseFee + tip); excess refunded.

## Learning Objectives
- Construct a DynamicFeeTx with caps and tip.
- Convert user inputs (gwei) to wei safely.
- Sign with London signer (chainID-aware) and broadcast.

## Prerequisites
- Module 05 (nonces, legacy tx flow).
- Comfort with ETH units and RPC basics.

## Real-World Analogy
- Bus fare: base fare (baseFee) plus a tip for faster boarding; maxFee is your total budget cap.

## Steps
1. Parse recipient, amount, maxFee, maxPriority.
2. Fetch nonce and chainID.
3. Build DynamicFeeTx (set GasFeeCap, GasTipCap).
4. Sign and send.

## Fun Facts & Comparisons
- Base fee is algorithmic per EIP-1559; tips go to the block proposer.
- Legacy gasPrice still works but misses automatic baseFee handling.
- ethers.js: populateTransaction + signer.sendTransaction uses EIP-1559 by default on London chains.

## Related Solidity-edu Modules
- Functions & Payable — gas budgeting affects send/withdraw patterns.
- Gas & Storage lessons — understanding gas pricing is critical for optimizing costs.

## Files
- Starter: `cmd/geth-06-eip1559/main.go`
- Solution: `cmd/geth-06-eip1559_solution/main.go`
