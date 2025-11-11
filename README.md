# Solidity 10x Mini-Projects 🔥

> **Learn Solidity by building 10 progressively challenging mini-projects**
> Focus on *WHY* Solidity works the way it does, not just syntax.

## 🎯 What Makes This Different

This repository teaches Solidity through **first principles** and **comparative learning**:

- 🧠 **Conceptual depth**: Understand *why* Solidity has specific design constraints
- ⚖️ **Trade-offs analysis**: Compare patterns with Python, Rust, Go, and JavaScript
- 🔒 **Security-first**: Learn common vulnerabilities from Day 1
- ⛽ **Gas awareness**: Every lesson discusses computational cost implications
- 🛠️ **Production-ready**: Use industry-standard tools (Foundry, OpenZeppelin)

## 📚 Learning Philosophy

**Bad tutorial**: "Use `public` to make a function callable"
**This repo**: "Use `public` to expose a function externally. It costs ~200 gas more than `external` because it copies calldata to memory, enabling internal calls. Use `external` for public APIs you'll never call internally."

Every pattern includes:
- **What**: Syntax and mechanics
- **Why**: Design rationale and EVM constraints
- **When**: Use cases and anti-patterns
- **Pitfalls**: Common mistakes and exploits
- **Comparisons**: How other languages solve the same problem

## 🚀 Quick Start

### Prerequisites

1. **Install Foundry** (Forge, Cast, Anvil):
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Verify installation**:
   ```bash
   forge --version
   cast --version
   ```

### Setup

```bash
# Clone this repository
git clone <repo-url>
cd edu-solidity

# Install dependencies (OpenZeppelin contracts)
forge install openzeppelin/openzeppelin-contracts --no-commit

# Run all tests
forge test

# Run tests with verbose output
forge test -vvv

# Run tests for a specific project
forge test --match-path "01-datatypes-and-storage/test/*.t.sol"
```

## 📖 Project Roadmap

Each project is a standalone Foundry workspace with:
- Skeleton contracts to complete
- Full solution implementations with extreme documentation
- Comprehensive test suites
- README with learning objectives and challenges

### Beginner (Projects 1-3)

| # | Project | Concepts | Status |
|---|---------|----------|--------|
| 01 | [Datatypes & Storage](./01-datatypes-and-storage/) | `uint`, `mapping`, storage vs memory, gas costs | ✅ Complete |
| 02 | [Functions & Payable](./02-functions-and-payable/) | `payable`, `receive()`, `fallback()`, ETH transfers | ✅ Complete |
| 03 | [Events & Logging](./03-events-and-logging/) | `event`, `emit`, indexed parameters, off-chain indexing | ✅ Complete |

### Intermediate (Projects 4-6)

| # | Project | Concepts | Status |
|---|---------|----------|--------|
| 04 | [Modifiers & Access Control](./04-modifiers-and-restrictions/) | Custom modifiers, `onlyOwner`, role-based access | ✅ Complete |
| 05 | [Errors & Reverts](./05-errors-and-reverts/) | `require()`, `revert()`, custom errors, gas optimization | ✅ Complete |
| 06 | [Mappings, Arrays & Gas](./06-mappings-arrays-and-gas/) | Storage slot hashing, iteration costs, optimization | ✅ Complete |

### Advanced (Projects 7-10)

| # | Project | Concepts | Status |
|---|---------|----------|--------|
| 07 | [Reentrancy & Security](./07-reentrancy-and-security/) | Classic reentrancy attack, checks-effects-interactions | ✅ Complete |
| 08 | [ERC20 from Scratch](./08-ERC20-from-scratch/) | Token standard, manual implementation vs OpenZeppelin | ✅ Complete |
| 09 | [ERC721 NFT](./09-ERC721-NFT-from-scratch/) | NFT standard, metadata, approval model, mint races | ✅ Complete |
| 10 | [Upgradeability & Proxies](./10-upgradeability-and-proxies/) | UUPS proxy pattern, storage collisions, EIP-1967 | ✅ Complete |

### Expert (Project 11)

| # | Project | Concepts | Status |
|---|---------|----------|--------|
| 11 | [ERC-4626 Tokenized Vault](./11-ERC4626-tokenized-vault/) | Vault standard, share math, yield strategies, DeFi | ✅ Complete |

## 🎓 How to Use This Repository

### Path 1: Guided Learning (Recommended for beginners)

1. **Read** the project README to understand objectives
2. **Attempt** the skeleton contract yourself
3. **Run tests** to validate your implementation: `forge test`
4. **Compare** your solution with `src/solution/` files
5. **Study** the extensive inline comments explaining *why*

### Path 2: Challenge Mode (For experienced developers)

1. Read only the project README
2. Implement from scratch without looking at skeletons
3. Make all tests pass
4. Review solution for gas optimizations and security patterns

### Path 3: Reference Mode (Quick lookup)

- Jump to any project's `solution/` folder
- Read the comprehensive documentation
- Use as a pattern library for your own contracts

## 🔧 Development Workflow

### Running Tests

```bash
# All tests
forge test

# Specific project
forge test --match-path "01-datatypes-and-storage/**/*.t.sol"

# With gas reporting
forge test --gas-report

# With detailed traces
forge test -vvvv

# With gas snapshots
forge snapshot
```

### Local Deployment

```bash
# Start local Ethereum node
anvil

# Deploy contract (in another terminal)
forge script script/Deploy.s.sol --broadcast --rpc-url http://localhost:8545
```

### Interacting with Contracts

```bash
# Call a read function
cast call <CONTRACT_ADDRESS> "balanceOf(address)(uint256)" <USER_ADDRESS>

# Send a transaction
cast send <CONTRACT_ADDRESS> "transfer(address,uint256)" <TO_ADDRESS> 1000000 \
  --private-key <PRIVATE_KEY>
```

## 🔍 Key Learning Resources

Each project includes:

1. **README.md**: Learning objectives, prerequisites, challenges
2. **Skeleton contracts**: Fill-in-the-blank implementations
3. **Solution contracts**: Production-quality implementations with:
   - Line-by-line explanations
   - Gas cost analysis
   - Security considerations
   - Multi-language comparisons
4. **Test suites**: Positive, negative, and attack scenarios
5. **Deployment scripts**: Ready-to-use deployment examples

## 🌟 Best Practices Taught

- ✅ **Checks-Effects-Interactions** pattern for reentrancy protection
- ✅ **Custom errors** over `require` strings (saves gas)
- ✅ **Events** for all state changes (off-chain indexing)
- ✅ **Explicit visibility** specifiers (security)
- ✅ **Pull over Push** payments (avoid DoS)
- ✅ **Rate limiting** and access controls
- ✅ **Integer overflow** protection (built-in Solidity 0.8+)
- ✅ **Gas optimization** techniques
- ✅ **Storage layout** understanding
- ✅ **Proxy patterns** for upgradeability

## ⚠️ Common Pitfalls Covered

- ❌ Reentrancy vulnerabilities
- ❌ Integer overflow/underflow (pre-0.8.0)
- ❌ Unprotected `selfdestruct`
- ❌ Gas limit DoS via unbounded loops
- ❌ Front-running and MEV
- ❌ Storage collision in proxies
- ❌ Delegatecall to untrusted contracts
- ❌ Signature replay attacks
- ❌ Timestamp dependence
- ❌ tx.origin authentication

## 📊 Comparison: Solidity vs Other Languages

Throughout the projects, you'll see comparisons like:

| Concept | Python | Solidity | Why Different? |
|---------|--------|----------|----------------|
| Variables | Dynamic typing | Static typing | EVM requires compile-time memory layout |
| Errors | Exceptions | Reverts (rollback state) | Blockchain state must be atomic |
| Loops | Arbitrary length | Gas-bounded | Prevent infinite loops / DoS |
| Functions | Free to call | Costs gas | Decentralized computation has costs |
| Privacy | True private variables | All data public | Blockchain is transparent |

## 🛠️ Tech Stack

- **Solidity** ^0.8.20: Smart contract language
- **Foundry**: Development framework (Forge, Cast, Anvil)
- **OpenZeppelin**: Audited contract libraries
- **Foundry-rs**: Testing in Solidity (no JavaScript!)

## 🤝 Contributing

Found a bug or improvement? Please open an issue or PR!

## 📄 License

MIT License - Learn freely, build responsibly

## 🚦 Next Steps

1. Complete [SOLIDITY_BASICS.md](./SOLIDITY_BASICS.md) quick reference
2. Start with [Project 01: Datatypes & Storage](./01-datatypes-and-storage/)
3. Join the community discussions (Discord/Telegram links)
4. Build your own contracts using these patterns

---

**Remember**: Smart contracts control real value. Test extensively, audit professionally, and never deploy experimental code to mainnet with funds at risk.

*Happy building! 🚀*
