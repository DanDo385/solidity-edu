# geth-edu Track

25 progressive Geth/Go projects (geth-01 ... geth-25) from beginner to “I can build production-ish tooling”. Each module has:
- README with objectives, analogies, comparisons, fun facts, and Solidity-edu links.
- Starter CLI (TODOs).
- Commented solution with rich explanations, tips, and gotchas.

## Module Map

1) Stack basics: execution vs consensus, ping chain/head.  
2) RPC basics: blockNumber/getBlock/net_version, timeouts.  
3) Keys/addresses: secp256k1, keystore JSON.  
4) Accounts/balances: EOA vs contract, balance/code.  
5) Tx nonces: legacy tx build/sign/send.  
6) EIP-1559: dynamic fees, tip/base fee math.  
7) eth_call: manual ABI encode/decode for view calls.  
8) abigen: typed bindings for contracts.  
9) Events: decode ERC20 Transfer logs.  
10) Filters/subs: newHeads via WS, polling fallback.  
11) Storage: eth_getStorageAt, mapping/array slots.  
12) Proofs: eth_getProof, Merkle Patricia tries.  
13) Trace: debug_traceTransaction (call tree/gas).  
14) Explorer: mini block/tx explorer CLI.  
15) Receipts: status/logs/cumulative gas.  
16) Concurrency: fan-out/fan-in, worker pool.  
17) Indexer: ERC20 transfers into sqlite.  
18) Reorgs: detect parent mismatch, rescan.  
19) Devnets: anvil fork, impersonation/funding.  
20) Node info: client version, peers, sync.  
21) Sync: full/snap/light progress.  
22) Peers: peer count, gossip health.  
23) Mempool: pending tx visibility caveats.  
24) Monitor: head freshness/lag check.  
25) Toolbox: Swiss Army CLI combining status/block/tx/events.

### Cross-links to Solidity-edu
- Storage/mappings/arrays ↔ modules 01, 11, 12.  
- Events/logging ↔ modules 09, 15.  
- Gas/txs ↔ modules 05, 06, 13, 14.  
- Access control/EOA vs contract ↔ modules 03, 04.
