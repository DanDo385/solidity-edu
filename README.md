# Solidity 50-Project Mastery Curriculum 🔥

> **Master Solidity from First Principles through 50 Progressively Complex Mini-Projects**
> Learn *WHY* Solidity works the way it does, not just syntax.

## 🎯 What Makes This Different

This repository teaches Solidity through **first principles** and **deep comparative learning**:

- 🧠 **Conceptual depth**: Understand *why* Solidity has specific design constraints
- ⚖️ **Trade-offs analysis**: Compare patterns with Python, Rust, Go, and JavaScript
- 🔒 **Security-first**: Learn common vulnerabilities and attack vectors from Day 1
- ⛽ **Gas awareness**: Every lesson discusses computational cost implications
- 🛠️ **Production-ready**: Use industry-standard tools (Foundry, OpenZeppelin)
- 🏗️ **Full-stack DeFi**: From basics to complete protocol engineering

## 📚 Learning Philosophy

**Bad tutorial**: "Use `public` to make a function callable"

**This repo**: "Use `public` to expose a function externally. It costs ~200 gas more than `external` because it copies calldata to memory, enabling internal calls. Use `external` for public APIs you'll never call internally."

Every pattern includes:
- **What**: Syntax and mechanics
- **Why**: Design rationale and EVM constraints
- **When**: Use cases and anti-patterns
- **Pitfalls**: Common mistakes and exploits
- **Comparisons**: How other languages solve the same problem
- **Storage Diagrams**: Visual representation of memory layout
- **Gas Analysis**: Concrete cost measurements

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
cd solidity-edu

# Install dependencies (OpenZeppelin contracts)
forge install openzeppelin/openzeppelin-contracts --no-commit

# Run all tests
forge test

# Run tests with verbose output
forge test -vvv

# Run tests for a specific project
forge test --match-path "01-datatypes-and-storage/test/*.t.sol"

# Generate gas report
forge test --gas-report

# Generate gas snapshots
forge snapshot
```

## 📖 Complete 50-Project Curriculum

Each project is a standalone Foundry workspace with:
- Skeleton contracts to complete
- Full solution implementations with extreme documentation
- Comprehensive test suites (positive, negative, fuzz, invariant)
- Deployment scripts
- README with learning objectives and challenges

---

### 🌱 BEGINNER FOUNDATIONS (Projects 1-10)

| # | Project | Core Concepts | Status |
|---|---------|--------------|--------|
| 01 | [Datatypes & Storage](./01-datatypes-and-storage/) | `uint/int`, `address`, `mapping`, storage slots, packing | ✅ Complete |
| 02 | [Functions & Payable](./02-functions-and-payable/) | `payable`, `receive()`, `fallback()`, ETH transfers | ✅ Complete |
| 03 | [Events & Logging](./03-events-and-logging/) | `event`, `indexed`, bloom filters, off-chain indexing | ✅ Complete |
| 04 | [Modifiers & Access Control](./04-modifiers-and-restrictions/) | Custom modifiers, `onlyOwner`, RBAC patterns | ✅ Complete |
| 05 | [Errors & Reverts](./05-errors-and-reverts/) | `require/revert/assert`, custom errors, gas savings | ✅ Complete |
| 06 | [Mappings, Arrays & Gas](./06-mappings-arrays-and-gas/) | Storage hashing, iteration costs, DoS vectors | ✅ Complete |
| 07 | [Structs, Enums & Storage Packing](./07-structs-enums-packing/) | Struct packing, enum representation, optimization | 📝 Ready |
| 08 | [Constructors & Immutables](./08-constructors-immutables/) | Constructor flows, immutable vs constant | 📝 Ready |
| 09 | [Inheritance & Interfaces](./09-inheritance-interfaces/) | virtual/override, diamond inheritance | 📝 Ready |
| 10 | [Foundry Basics](./10-foundry-basics/) | Fuzzing, cheatcodes, invariant testing | 📝 Ready |

---

### 🎓 INTERMEDIATE LEVEL (Projects 11-20)

| # | Project | Core Concepts | Status |
|---|---------|--------------|--------|
| 11 | [Reentrancy & Security](./07-reentrancy-and-security/) | Classic reentrancy, CEI pattern, attacks | ✅ Complete |
| 12 | [Safe ETH Transfer Library](./12-safe-eth-transfer/) | Pull payments, withdrawal patterns, queues | 📝 Ready |
| 13 | [Block Properties & Time Logic](./13-block-time-logic/) | timestamp manipulation, rate limiting | 📝 Ready |
| 14 | [ABI Encoding & Selectors](./14-abi-encoding/) | abi.encode, encodePacked, selector collisions | 📝 Ready |
| 15 | [Low-Level Calls](./15-low-level-calls/) | call/delegatecall/staticcall, storage corruption | 📝 Ready |
| 16 | [Contract Factories (CREATE2)](./16-contract-factories/) | Deterministic deployment, initcode, salts | 📝 Ready |
| 17 | [Minimal Proxy (EIP-1167)](./17-minimal-proxy/) | Clone factory, minimal bytecode | 📝 Ready |
| 18 | [Oracles (Chainlink)](./18-oracles-chainlink/) | AggregatorV3, stale data, TWAP | 📝 Ready |
| 19 | [Signed Messages & EIP-712](./19-signed-messages/) | Typed structured data, domain separators | 📝 Ready |
| 20 | [Deposit/Withdraw Accounting](./20-deposit-withdraw/) | Share vs asset accounting, preview functions | 📝 Ready |

---

### 🎨 TOKEN STANDARDS & NFT TRACK (Projects 21-30)

| # | Project | Core Concepts | Status |
|---|---------|--------------|--------|
| 21 | [ERC-20 From Scratch](./08-ERC20-from-scratch/) | balanceOf, transfer, allowance, events | ✅ Complete |
| 22 | [ERC-20 (OpenZeppelin)](./22-erc20-openzeppelin/) | OZ implementation, hooks, extensions | 📝 Ready |
| 23 | [ERC-20 Permit (EIP-2612)](./23-erc20-permit/) | permit signatures, nonces, gas savings | 📝 Ready |
| 24 | [ERC-721 From Scratch](./09-ERC721-NFT-from-scratch/) | ownerOf, approve, safeTransferFrom | ✅ Complete |
| 25 | [ERC-721A Optimized](./25-erc721a-optimized/) | Azuki batch minting, storage packing | 📝 Ready |
| 26 | [ERC-1155 Multi-Token](./26-erc1155-multi/) | Fungible+NFT hybrid, batch transfers | 📝 Ready |
| 27 | [Soulbound Tokens](./27-soulbound-tokens/) | Non-transferable NFTs, revocation | 📝 Ready |
| 28 | [ERC-2981 Royalties](./28-erc2981-royalties/) | On-chain royalties, fee calculation | 📝 Ready |
| 29 | [Merkle Proof Allowlists](./29-merkle-allowlist/) | Merkle trees, proofs, allowlist minting | 📝 Ready |
| 30 | [On-Chain SVG Rendering](./30-onchain-svg/) | Base64 encoding, SVG assembly | 📝 Ready |

---

### 🔐 SECURITY & ATTACK LAB TRACK (Projects 31-40)

| # | Project | Core Concepts | Status |
|---|---------|--------------|--------|
| 31 | [Reentrancy Lab](./31-reentrancy-lab/) | Multi-hop attacks, attacker contracts | 📝 Ready |
| 32 | [Integer Overflow Labs](./32-overflow-lab/) | Pre-0.8 vulnerabilities, safe math | 📝 Ready |
| 33 | [MEV & Front-Running](./33-mev-frontrunning/) | Order injection, sandwich attacks | 📝 Ready |
| 34 | [Oracle Manipulation](./34-oracle-manipulation/) | Price manipulation, flashloan exploits | 📝 Ready |
| 35 | [Delegatecall Corruption](./35-delegatecall-corruption/) | Untrusted callee, proxy exploits | 📝 Ready |
| 36 | [Access Control Bugs](./36-access-control-bugs/) | Uninitialized ownership, role escalation | 📝 Ready |
| 37 | [Gas DoS Attacks](./37-gas-dos-attacks/) | Unbounded loops, griefing | 📝 Ready |
| 38 | [Signature Replay Attack](./38-signature-replay/) | Missing nonce, chainId issues | 📝 Ready |
| 39 | [Governance Attack Simulation](./39-governance-attack/) | Flashloan voting, quorum manipulation | 📝 Ready |
| 40 | [Multi-Sig Wallet](./40-multisig-wallet/) | Threshold approvals, queued txs | 📝 Ready |

---

### 🏦 4626 VAULT MASTERY & DEFI ENGINEERING (Projects 41-50)

| # | Project | Core Concepts | Status |
|---|---------|--------------|--------|
| 41 | [ERC-4626 Base Vault](./11-ERC4626-tokenized-vault/) | convertToShares, deposit/mint/withdraw/redeem | ✅ Complete |
| 42 | [ERC-4626 Precision & Rounding](./42-vault-precision/) | Rounding modes, denominator issues | 📝 Ready |
| 43 | [Yield-Bearing Vault](./43-yield-vault/) | Interest accrual, harvest, reinvest | 📝 Ready |
| 44 | [Inflation Attack Demo](./44-inflation-attack/) | Donation attack, mitigation patterns | 📝 Ready |
| 45 | [Multi-Asset Vault](./45-multi-asset-vault/) | Basket of tokens, weighted NAV | 📝 Ready |
| 46 | [Vault Insolvency Scenarios](./46-vault-insolvency/) | Bad debt, emergency withdrawals | 📝 Ready |
| 47 | [Vault Oracle Integration](./47-vault-oracle/) | TWAP, stale data handling | 📝 Ready |
| 48 | [Meta-Vault (4626→4626)](./48-meta-vault/) | Wrapping vaults, compounding | 📝 Ready |
| 49 | [Leverage Looping Vault](./49-leverage-vault/) | Borrow-deposit loop, liquidation bands | 📝 Ready |
| 50 | [Full DeFi Protocol Capstone](./50-defi-capstone/) | Token+NFT+Vault+Governance+Multisig | 📝 Ready |

---

## 🎓 How to Use This Repository

### Path 1: Guided Learning (Recommended for beginners)

1. **Read** the project README to understand objectives
2. **Read** [SOLIDITY_BASICS.md](./SOLIDITY_BASICS.md) for quick reference
3. **Attempt** the skeleton contract yourself
4. **Run tests** to validate your implementation: `forge test`
5. **Compare** your solution with `src/solution/` files
6. **Study** the extensive inline comments explaining *why*
7. **Complete** advanced challenges in README

### Path 2: Challenge Mode (For experienced developers)

1. Read only the project README
2. Implement from scratch without looking at skeletons
3. Make all tests pass (including fuzz and invariant tests)
4. Review solution for gas optimizations and security patterns
5. Compare gas reports with `forge snapshot`

### Path 3: Reference Mode (Quick lookup)

- Jump to any project's `solution/` folder
- Read the comprehensive documentation
- Use as a pattern library for your own contracts
- Refer to specialized guides (ERC4626_MATH_REFERENCE.md, etc.)

---

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

# Fuzz testing with custom runs
forge test --fuzz-runs 10000

# Invariant testing
forge test --match-test invariant
```

### Local Deployment

```bash
# Start local Ethereum node
anvil

# Deploy contract (in another terminal)
cd 01-datatypes-and-storage
forge script script/Deploy.s.sol --broadcast --rpc-url http://localhost:8545

# Deploy with verification
forge script script/Deploy.s.sol --broadcast --verify
```

### Interacting with Contracts

```bash
# Call a read function
cast call <CONTRACT_ADDRESS> "balanceOf(address)(uint256)" <USER_ADDRESS>

# Send a transaction
cast send <CONTRACT_ADDRESS> "transfer(address,uint256)" <TO_ADDRESS> 1000000 \
  --private-key <PRIVATE_KEY>

# Decode transaction data
cast 4byte-decode <CALLDATA>

# Get storage slot
cast storage <CONTRACT_ADDRESS> <SLOT>
```

---

## 📚 Comprehensive Documentation

This repository includes extensive reference materials:

- **[SOLIDITY_BASICS.md](./SOLIDITY_BASICS.md)** - Quick reference for Solidity syntax
- **[PROJECT_SUMMARY.md](./PROJECT_SUMMARY.md)** - Overview of all 50 projects
- **[SECURITY_CHECKLIST.md](./SECURITY_CHECKLIST.md)** - Pre-deployment security audit checklist
- **[GAS_OPTIMIZATION_GUIDE.md](./GAS_OPTIMIZATION_GUIDE.md)** - Comprehensive gas saving techniques
- **[FOUNDRY_GUIDE.md](./FOUNDRY_GUIDE.md)** - Deep dive into Foundry tooling
- **[ERC4626_MATH_REFERENCE.md](./ERC4626_MATH_REFERENCE.md)** - Vault mathematics explained
- **[DEFI_ATTACKS_REFERENCE.md](./DEFI_ATTACKS_REFERENCE.md)** - Common attack vectors
- **[COMPARATIVE_LANGUAGE_GUIDE.md](./COMPARATIVE_LANGUAGE_GUIDE.md)** - Solidity vs Python/Rust/Go/JS

---

## 🌟 Best Practices Taught

- ✅ **Checks-Effects-Interactions** pattern for reentrancy protection
- ✅ **Custom errors** over `require` strings (saves ~50 gas per revert)
- ✅ **Events** for all state changes (off-chain indexing, transparency)
- ✅ **Explicit visibility** specifiers (security, gas optimization)
- ✅ **Pull over Push** payments (avoid DoS vectors)
- ✅ **Rate limiting** and access controls
- ✅ **Integer overflow** protection (built-in Solidity 0.8+)
- ✅ **Storage packing** for gas savings
- ✅ **Immutable** and **constant** for deployment/runtime optimization
- ✅ **Proxy patterns** for upgradeability
- ✅ **Invariant testing** for protocol correctness
- ✅ **Fuzzing** for edge case discovery

---

## ⚠️ Common Pitfalls Covered

- ❌ Reentrancy vulnerabilities (cross-function, cross-contract)
- ❌ Integer overflow/underflow (pre-0.8.0)
- ❌ Unprotected `selfdestruct` and `delegatecall`
- ❌ Gas limit DoS via unbounded loops
- ❌ Front-running and MEV exploitation
- ❌ Storage collision in proxies
- ❌ Signature replay attacks (missing nonce/chainId)
- ❌ Timestamp dependence and miner manipulation
- ❌ `tx.origin` authentication (vs `msg.sender`)
- ❌ Floating pragma and outdated compiler versions
- ❌ Oracle manipulation and stale data
- ❌ Approval race conditions
- ❌ ERC-4626 inflation attacks
- ❌ Governance takeover via flashloans

---

## 📊 Comparison: Solidity vs Other Languages

Throughout the projects, you'll see comparisons like:

| Concept | Python | Rust | Solidity | Why Different? |
|---------|--------|------|----------|----------------|
| **Variables** | Dynamic typing | Static typing | Static typing | EVM requires compile-time memory layout |
| **Errors** | Exceptions | Result<T,E> | Reverts (rollback) | Blockchain state must be atomic |
| **Loops** | Arbitrary length | Arbitrary length | Gas-bounded | Prevent infinite loops / DoS |
| **Functions** | Free to call | Free to call | Costs gas | Decentralized computation has costs |
| **Privacy** | True private | Module privacy | All data public | Blockchain is transparent ledger |
| **Memory** | Garbage collected | Ownership/borrowing | Manual (storage/memory) | EVM requires explicit allocation |
| **Upgrades** | Deploy new version | Deploy new binary | Proxy patterns | Immutable bytecode on-chain |

---

## 🛠️ Tech Stack

- **Solidity** ^0.8.20: Smart contract language
- **Foundry**: Development framework (Forge, Cast, Anvil)
  - **Forge**: Testing, building, deployment
  - **Cast**: CLI for Ethereum RPC interactions
  - **Anvil**: Local Ethereum node
- **OpenZeppelin**: Audited contract libraries
- **Solmate**: Gas-optimized primitives

---

## 🎯 Learning Outcomes

After completing this curriculum, you will:

1. ✅ Understand EVM internals (storage layout, gas mechanics, bytecode)
2. ✅ Write production-grade Solidity with security best practices
3. ✅ Implement all major ERC standards (20, 721, 1155, 4626, 2612, 2981)
4. ✅ Master Foundry for testing, fuzzing, and invariant checking
5. ✅ Recognize and prevent common attack vectors
6. ✅ Optimize contracts for gas efficiency
7. ✅ Design upgradeable systems with proxy patterns
8. ✅ Build complex DeFi protocols (vaults, AMMs, lending)
9. ✅ Conduct security audits and code reviews
10. ✅ Understand MEV, front-running, and economic exploits

---

## 🤝 Contributing

Found a bug or improvement? Please open an issue or PR!

**Guidelines:**
- Add tests for any new features
- Follow existing code style (forge fmt)
- Update documentation
- Ensure all tests pass: `forge test`

---

## 📄 License

MIT License - Learn freely, build responsibly

---

## 🚦 Next Steps

1. Complete [SOLIDITY_BASICS.md](./SOLIDITY_BASICS.md) quick reference
2. Review [SECURITY_CHECKLIST.md](./SECURITY_CHECKLIST.md)
3. Start with [Project 01: Datatypes & Storage](./01-datatypes-and-storage/)
4. Progress through projects sequentially
5. Build your own contracts using these patterns
6. Complete the [Full DeFi Protocol Capstone](./50-defi-capstone/)

---

## 📞 Resources

- **Foundry Book**: https://book.getfoundry.sh/
- **Solidity Docs**: https://docs.soliditylang.org/
- **OpenZeppelin**: https://docs.openzeppelin.com/
- **EIPs**: https://eips.ethereum.org/
- **Etherscan**: https://etherscan.io/

---

**Remember**: Smart contracts control real value. Test extensively, audit professionally, and never deploy experimental code to mainnet with funds at risk.

**Security is not optional. Gas optimization comes after correctness.**

*Happy building! 🚀*
