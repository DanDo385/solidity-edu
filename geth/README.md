# Ethereum Go Development Track

25 progressive Ethereum/Go projects (01-stack through 25-toolbox) from beginner to "I can build production-grade Ethereum tooling". Each module builds on previous concepts, with detailed explanations from computer science first principles.

## Philosophy

This track teaches Ethereum development from the ground up, with a nerdy, educational tone that:
- Explains concepts from **computer science first principles**
- Uses **analogies** and **comparisons** to make concepts accessible
- Includes **fun facts** and **nerdy details** for deeper understanding
- **Cross-references** previous modules to show how concepts build on each other
- **Ties concepts together** as they repeat throughout the course

## Quick Start

### Prerequisites
- Go 1.22 or later
- An Ethereum RPC endpoint (Infura, Alchemy, or your own node)

### Setup

1. **Configure RPC endpoint** (choose one):
   ```bash
   # Option 1: Set environment variable
   export INFURA_RPC_URL=https://mainnet.infura.io/v3/YOUR_INFURA_PROJECT_ID
   
   # Option 2: Copy .env.example to .env and edit
   cp .env.example .env
   # Then edit .env with your RPC URL
   ```

2. **Install dependencies**:
   ```bash
   make tidy
   # or manually:
   go mod tidy
   ```

3. **Run a module**:
   ```bash
   # Using Makefile (recommended)
   make run-01  # Run 01-stack solution
   
   # Or manually
   go run 01-stack/cmd/01-stack_solution/main.go
   
   # Or work on the starter version
   go run 01-stack/cmd/01-stack/main.go
   ```

### Available Make Targets

- `make tidy` - Update Go dependencies
- `make build` - Build all module binaries
- `make clean` - Remove build artifacts and databases
- `make run-01` through `make run-25` - Run specific module solutions
- `make help` - Show all available targets

### Project Structure

Each module (`XX-name/`) contains:
- `README.md` - Learning objectives, CS-first-principles explanations, analogies, comparisons, fun facts, and cross-references
- `cmd/XX-name/main.go` - Starter code with TODO comments
- `cmd/XX-name_solution/main.go` - Complete solution with detailed educational commentary

## Module Map

### Foundation (Modules 01-04)
**Building blocks:** Understanding the Ethereum stack, RPC basics, cryptographic identity, and account types.

1. **01-stack:** Execution vs consensus clients, JSON-RPC basics, chain ID, block headers
2. **02-rpc-basics:** Full blocks, transaction structures, retry logic, JSON-RPC method details
3. **03-keys-addresses:** secp256k1 cryptography, key generation, address derivation, keystore files
4. **04-accounts-balances:** EOA vs contract accounts, balance queries, code storage

### Transactions (Modules 05-06)
**Building blocks:** Understanding how transactions work, from signing to execution.

5. **05-tx-nonces:** Transaction nonces, legacy transaction building, signing, broadcasting
6. **06-eip1559:** EIP-1559 dynamic fees, base fee, priority fee, gas price calculations

### Contract Interaction (Modules 07-08)
**Building blocks:** Calling contracts, encoding/decoding data, typed bindings.

7. **07-eth-call:** Manual ABI encoding/decoding, view calls, error handling
8. **08-abigen:** Typed contract bindings, code generation, type-safe contract calls

### Events & Logs (Modules 09-10)
**Building blocks:** Understanding events, logs, and real-time updates.

9. **09-events:** Event decoding, ERC20 Transfer logs, log parsing
10. **10-filters:** WebSocket subscriptions, newHeads filters, polling fallback

### Storage & Proofs (Modules 11-12)
**Building blocks:** Understanding storage layout, Merkle proofs, and cryptographic verification.

11. **11-storage:** Storage slots, mapping/array layouts, `eth_getStorageAt`
12. **12-proofs:** Merkle Patricia tries, `eth_getProof`, storage proofs, account proofs

### Advanced Debugging (Modules 13-15)
**Building blocks:** Deep transaction analysis, tracing, and receipt inspection.

13. **13-trace:** `debug_traceTransaction`, call trees, gas analysis, execution traces
14. **14-explorer:** Building a mini block/tx explorer CLI
15. **15-receipts:** Transaction receipts, status codes, logs, cumulative gas

### Production Patterns (Modules 16-18)
**Building blocks:** Concurrency, indexing, and handling chain reorganizations.

16. **16-concurrency:** Fan-out/fan-in patterns, worker pools, concurrent RPC calls
17. **17-indexer:** ERC20 transfer indexing, SQLite storage, efficient data structures
18. **18-reorgs:** Chain reorganizations, parent hash mismatches, rescanning logic

### Development & Testing (Module 19)
**Building blocks:** Local development networks and testing tools.

19. **19-devnets:** Anvil fork, account impersonation, funding accounts, local testing

### Node Operations (Modules 20-22)
**Building blocks:** Understanding node internals, sync status, and peer management.

20. **20-node:** Node information, client version, peer count, sync status
21. **21-sync:** Full/snap/light sync modes, sync progress, sync status
22. **22-peers:** Peer management, gossip health, peer information

### Monitoring & Operations (Modules 23-25)
**Building blocks:** Production monitoring, mempool visibility, and comprehensive tooling.

23. **23-mempool:** Pending transaction visibility, mempool caveats, transaction propagation
24. **24-monitor:** Head freshness, lag detection, health monitoring
25. **25-toolbox:** Swiss Army CLI combining status/block/tx/events queries

## Cross-Links to Solidity-edu

This track complements the Solidity-edu foundry track:

- **Storage/mappings/arrays** ↔ modules 01, 11, 12
  - Solidity storage slots → Ethereum storage trie → Merkle proofs
- **Events/logging** ↔ modules 09, 15
  - Solidity events → Ethereum logs → Bloom filters → Event queries
- **Gas/transactions** ↔ modules 05, 06, 13, 14
  - Solidity gas costs → Transaction gas → Gas analysis → Trace debugging
- **Access control/EOA vs contract** ↔ modules 03, 04
  - Solidity `msg.sender` → Address derivation → Account types → Access control

## Learning Path

### Beginner Path (Modules 01-10)
Start here if you're new to Ethereum Go development:
1. Understand the Ethereum stack (01)
2. Learn RPC basics (02)
3. Generate keys and addresses (03)
4. Query accounts and balances (04)
5. Build and send transactions (05-06)
6. Interact with contracts (07-08)
7. Work with events (09-10)

### Intermediate Path (Modules 11-18)
Deep dive into storage, proofs, and production patterns:
1. Understand storage layout (11)
2. Learn Merkle proofs (12)
3. Debug transactions (13-15)
4. Build concurrent applications (16)
5. Create indexers (17)
6. Handle reorgs (18)

### Advanced Path (Modules 19-25)
Production operations and monitoring:
1. Set up devnets (19)
2. Monitor nodes (20-22)
3. Track mempool (23)
4. Build monitoring tools (24)
5. Create comprehensive tooling (25)

## Contributing

Each module follows a consistent structure:
- **README.md:** Comprehensive explanations with CS-first-principles, analogies, comparisons, fun facts, and cross-references
- **Starter code:** TODO comments guiding implementation
- **Solution code:** Detailed educational commentary explaining every concept

When adding new modules:
1. Follow the naming convention: `XX-name/`
2. Include comprehensive README with educational content
3. Add TODO comments to starter code
4. Provide detailed solution commentary
5. Cross-reference related modules
6. Update this README's module map

## Resources

- [Go Ethereum Documentation](https://geth.ethereum.org/docs/)
- [Ethereum JSON-RPC Specification](https://ethereum.org/en/developers/docs/apis/json-rpc/)
- [Ethereum Yellow Paper](https://ethereum.github.io/yellowpaper/paper.pdf)
- [Solidity-edu Track](../foundry/README.md) - Complementary Solidity learning track
