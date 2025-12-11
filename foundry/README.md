# Solidity 47-Project Mastery Curriculum 🔥

> **Master Solidity from First Principles through 47 Progressively Complex Mini-Projects**
> Learn *WHY* Solidity works the way it does, not just syntax.

## Table of Contents

- [What Makes This Different](#-what-makes-this-different)
- [Learning Philosophy](#-learning-philosophy)
- [Where to Start?](#-where-to-start)
- [Quick Start](#-quick-start)
- [Complete Project Curriculum](#-complete-47-project-curriculum)
- [Learning Tracks & Paths](#-learning-tracks--paths)
- [Project Navigation Guide](#-project-navigation-guide)
- [Progress Tracker](#-progress-tracker)
- [How to Use This Repository](#-how-to-use-this-repository)
- [Development Workflow](#-development-workflow)
- [Documentation](#-comprehensive-documentation)
- [Common Questions](#-common-questions)
- [Learning Outcomes](#-learning-outcomes)

---

## 🎯 What Makes This Different

This repository teaches Solidity through **first principles** and **deep comparative learning**:

- 🧠 **Conceptual depth**: Understand *why* Solidity has specific design constraints
- ⚖️ **Trade-offs analysis**: Compare patterns with Python, Rust, Go, and TypeScript
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

### Enhanced Solution Files

All solution files (`src/solution/*.sol`) have been enhanced with:

- **Computer Science Concepts**: Explanations from first principles (hash tables, state machines, memory management, etc.)
- **Purpose Statements**: Clear descriptions of real-world use cases for each contract
- **Syntax Explanations**: Detailed comments explaining Solidity syntax and patterns
- **Cross-Project Connections**: References showing how concepts build on each other across projects
- **Progressive Learning**: Early projects (01-05) have comprehensive explanations; later projects (06-50) have streamlined comments that reinforce concepts

**Learning Approach**: The solution files are designed to reinforce learning by:
- Explaining CS concepts that apply across all programming languages
- Showing how Solidity patterns connect to fundamental computer science
- Building connections between projects to reinforce understanding
- Demonstrating how simple concepts combine into complex DeFi protocols

---

## 🎯 Where to Start?

**New to Solidity?**
1. Read [Quick Start](#-quick-start) below to set up Foundry
2. Start with [Project 01: Datatypes & Storage](./01-datatypes-and-storage/)
3. Follow [Track 1: Complete Beginner](#track-1-complete-beginner) path
4. Use [LEARNING_GUIDE.md](./LEARNING_GUIDE.md) as your reference companion

**Experienced Developer?**
1. Review [Projects 01-05](#-beginner-foundations-projects-1-10) quickly to understand Solidity-specific concepts
2. Jump to [Track 2: Experienced Developer](#track-2-experienced-developer) path
3. Use [LEARNING_GUIDE.md](./LEARNING_GUIDE.md) for quick syntax lookup
4. Reference [DEFI_REFERENCE.md](./DEFI_REFERENCE.md) when building DeFi protocols

**Want to Build Something Specific?**
- **Token?** → See [Path A: "I Want to Build a Token"](#path-a-i-want-to-build-a-token)
- **NFT?** → See [Path B: "I Want to Build an NFT"](#path-b-i-want-to-build-an-nft)
- **Vault?** → See [Path C: "I Want to Build a Vault"](#path-c-i-want-to-build-a-vault)
- **Security?** → See [Path D: "I Want to Learn Security"](#path-d-i-want-to-learn-security)

**Need Quick Reference?**
- **[LEARNING_GUIDE.md](./LEARNING_GUIDE.md)** - Solidity syntax, Foundry commands, gas optimization
- **[DEFI_REFERENCE.md](./DEFI_REFERENCE.md)** - DeFi attacks, ERC-4626 vault mathematics
- **[PROJECT_MANAGEMENT.md](./PROJECT_MANAGEMENT.md)** - Project navigation, dependencies, progress tracking

---

## 🚀 Quick Start

> **⚠️ IMPORTANT: This project is designed for LOCAL DEVELOPMENT ONLY using Anvil**
> 
> All projects run on a local Anvil blockchain. Do not deploy to testnets or mainnet.
> Use the default Anvil accounts provided below for all interactions.

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

# Set up environment variables (use default Anvil accounts)
cp .env.example .env  # Or create .env with the keys below

# Start Anvil in a separate terminal (keep it running)
anvil

# Compile all contracts (creates bytecode artifacts)
forge build

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

### Environment Variables (.env)

**This project uses the default Anvil accounts for local development:**

Create a `.env` file in the root directory with:

```bash
# Default Anvil Account #0 (Main deployer - 10,000 ETH)
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Additional Anvil Accounts (for multi-address interactions)
PRIVATE_KEY_1=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
PRIVATE_KEY_2=0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
PRIVATE_KEY_3=0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6
PRIVATE_KEY_4=0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a
PRIVATE_KEY_5=0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba
PRIVATE_KEY_6=0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e
PRIVATE_KEY_7=0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356
PRIVATE_KEY_8=0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97
PRIVATE_KEY_9=0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6
```

**Account Details:**
- **PRIVATE_KEY**: Account #0 - `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` (Main deployer)
- **PRIVATE_KEY_1**: Account #1 - `0x70997970C51812dc3A010C7d01b50e0d17dc79C8`
- **PRIVATE_KEY_2**: Account #2 - `0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC`
- **PRIVATE_KEY_3-9**: Accounts #3-9 (use for multi-address testing)

All accounts are pre-funded with 10,000 ETH when Anvil starts.

### Compiling Contracts

**Foundry automatically compiles contracts when you run `forge test` or `forge script`, but you can also compile explicitly:**

```bash
# Compile all contracts
forge build

# Force recompilation (ignore cache)
forge build --force

# Compile with verbose output (see compilation details)
forge build -vv

# Compile specific contract
forge build --contracts src/DatatypesStorage.sol

# Show contract sizes after compilation
forge build --sizes

# Compile with specific optimizer settings
forge build --optimizer-runs 200

# Compile with specific EVM version
forge build --evm-version paris
```

**Compiled artifacts are saved in `out/` directory:**
- `out/DatatypesStorage.sol/DatatypesStorage.json` - Contains bytecode, ABI, and metadata
- Bytecode is stored in the `bytecode` field (deployment bytecode)
- Runtime bytecode (what's stored on-chain) is in `deployedBytecode`
- ABI is in the `abi` field

### Analyzing Bytecode

**View compiled bytecode:**
```bash
# Extract bytecode from compiled artifact
cat out/DatatypesStorage.sol/DatatypesStorage.json | jq -r '.bytecode.object'

# Extract runtime bytecode
cat out/DatatypesStorage.sol/DatatypesStorage.json | jq -r '.deployedBytecode.object'

# Save bytecode to a file for analysis
cat out/DatatypesStorage.sol/DatatypesStorage.json | jq -r '.bytecode.object' > bytecode.txt

# View contract size (important for deployment limits)
forge build --sizes
```

**Bytecode Analysis Tools:**
- **Etherscan**: Verify and view bytecode on-chain
- **evm.codes**: Interactive EVM opcode reference
- **Mythril**: Security analysis of bytecode
- **Slither**: Static analysis (works on source, but can analyze bytecode patterns)

---

## 🧭 Navigating the Project

### Project Structure

Each mini-project follows a consistent structure:

```
foundry/
├── 01-datatypes-and-storage/
│   ├── README.md              # Project-specific learning guide
│   ├── foundry.toml           # Project configuration
│   ├── src/
│   │   ├── Contract.sol       # Skeleton contract (your work)
│   │   └── solution/
│   │       └── ContractSolution.sol  # Reference implementation
│   ├── test/
│   │   ├── Contract.t.sol     # Test suite (your tests)
│   │   └── solution/
│   │       └── ContractSolution.t.sol  # Reference tests
│   └── script/
│       ├── Deploy.s.sol       # Deployment script
│       └── solution/
│           └── DeploySolution.s.sol  # Reference deployment
├── 02-functions-and-payable/
│   └── ... (same structure)
└── ... (47 projects total)
```

### Running Tests

**Test All Projects**:
```bash
# From the foundry directory
forge test

# With verbose output
forge test -vvv

# With gas reporting
forge test --gas-report
```

**Test Specific Project**:
```bash
# Navigate to project directory
cd 01-datatypes-and-storage

# Run tests for this project only
forge test

# Run specific test function
forge test --match-test test_SetNumber

# Run tests matching a pattern
forge test --match-path "test/*.t.sol"
```

**Common Test Commands**:
```bash
# Run with detailed traces (helpful for debugging)
forge test -vvvv

# Run fuzz tests with custom runs
forge test --fuzz-runs 10000

# Create gas snapshots for optimization tracking
forge snapshot

# Compare gas usage with previous snapshot
forge snapshot --diff

# Get coverage report
forge coverage
```

### Building Contracts

```bash
# Build all contracts
forge build

# Build with verbose output
forge build -vv

# Force rebuild (ignore cache)
forge build --force

# View contract sizes (24KB limit)
forge build --sizes
```

### Common Workflows

**Starting a New Project**:
1. Read the project README thoroughly
2. Review the skeleton contract in `src/`
3. Implement the TODOs in the skeleton
4. Write tests in `test/`
5. Run `forge test` to verify
6. Compare with `src/solution/` and `test/solution/`
7. Deploy locally with `forge script`

**Debugging Failures**:
1. Run with `-vvvv` for full traces
2. Add `console.log()` statements (import from `forge-std/console.sol`)
3. Use `forge test --debug <test_name>` for interactive debugging
4. Check gas usage with `--gas-report`

**Gas Optimization**:
1. Create baseline: `forge snapshot`
2. Make optimizations
3. Compare: `forge snapshot --diff`
4. Review gas report: `forge test --gas-report`

---

## 📖 Complete 47-Project Curriculum

**Note**: The curriculum includes 47 projects total. Projects 21, 24, and 41 are not included in the sequence.

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

> Reference: Storage + data locations → [LEARNING_GUIDE.md](./LEARNING_GUIDE.md#data-locations); Function visibility/payable → [LEARNING_GUIDE.md](./LEARNING_GUIDE.md#functions); Event patterns → [LEARNING_GUIDE.md](./LEARNING_GUIDE.md#important-patterns).

---

### 🎓 INTERMEDIATE LEVEL (Projects 11-20)

| # | Project | Core Concepts | Status |
|---|---------|--------------|--------|
| 11 | [Reentrancy & Security](./07-reentrancy-and-security/) | Classic reentrancy, CEI pattern, attacks | ✅ Complete |
| 12 | [Safe ETH Transfer Library](./12-safe-eth-transfer/) | Pull payments, withdrawal patterns, queues | ✅ Complete |
| 13 | [Block Properties & Time Logic](./13-block-time-logic/) | timestamp manipulation, rate limiting | ✅ Complete |
| 14 | [ABI Encoding & Selectors](./14-abi-encoding/) | abi.encode, encodePacked, selector collisions | ✅ Complete |
| 15 | [Low-Level Calls](./15-low-level-calls/) | call/delegatecall/staticcall, storage corruption | ✅ Complete |
| 16 | [Contract Factories (CREATE2)](./16-contract-factories/) | Deterministic deployment, initcode, salts | ✅ Complete |
| 17 | [Minimal Proxy (EIP-1167)](./17-minimal-proxy/) | Clone factory, minimal bytecode | ✅ Complete |
| 18 | [Oracles (Chainlink)](./18-oracles-chainlink/) | AggregatorV3, stale data, TWAP | ✅ Complete |
| 19 | [Signed Messages & EIP-712](./19-signed-messages/) | Typed structured data, domain separators | ✅ Complete |
| 20 | [Deposit/Withdraw Accounting](./20-deposit-withdraw/) | Share vs asset accounting, preview functions | ✅ Complete |

---

### 🎨 TOKEN STANDARDS & NFT TRACK (Projects 21-30)

| # | Project | Core Concepts | Status |
|---|---------|--------------|--------|
| 21 | [ERC-20 From Scratch](./08-ERC20-from-scratch/) | balanceOf, transfer, allowance, events | ✅ Complete |
| 22 | [ERC-20 (OpenZeppelin)](./22-erc20-openzeppelin/) | OZ implementation, hooks, extensions | ✅ Complete |
| 23 | [ERC-20 Permit (EIP-2612)](./23-erc20-permit/) | permit signatures, nonces, gas savings | ✅ Complete |
| 24 | [ERC-721 From Scratch](./09-ERC721-NFT-from-scratch/) | ownerOf, approve, safeTransferFrom | ✅ Complete |
| 25 | [ERC-721A Optimized](./25-erc721a-optimized/) | Azuki batch minting, storage packing | ✅ Complete |
| 26 | [ERC-1155 Multi-Token](./26-erc1155-multi/) | Fungible+NFT hybrid, batch transfers | ✅ Complete |
| 27 | [Soulbound Tokens](./27-soulbound-tokens/) | Non-transferable NFTs, revocation | ✅ Complete |
| 28 | [ERC-2981 Royalties](./28-erc2981-royalties/) | On-chain royalties, fee calculation | ✅ Complete |
| 29 | [Merkle Proof Allowlists](./29-merkle-allowlist/) | Merkle trees, proofs, allowlist minting | ✅ Complete |
| 30 | [On-Chain SVG Rendering](./30-onchain-svg/) | Base64 encoding, SVG assembly | ✅ Complete |

---

### 🔐 SECURITY & ATTACK LAB TRACK (Projects 31-40)

| # | Project | Core Concepts | Status |
|---|---------|--------------|--------|
| 31 | [Reentrancy Lab](./31-reentrancy-lab/) | Multi-hop attacks, attacker contracts | ✅ Complete |
| 32 | [Integer Overflow Labs](./32-overflow-lab/) | Pre-0.8 vulnerabilities, safe math | ✅ Complete |
| 33 | [MEV & Front-Running](./33-mev-frontrunning/) | Order injection, sandwich attacks | ✅ Complete |
| 34 | [Oracle Manipulation](./34-oracle-manipulation/) | Price manipulation, flashloan exploits | ✅ Complete |
| 35 | [Delegatecall Corruption](./35-delegatecall-corruption/) | Untrusted callee, proxy exploits | ✅ Complete |
| 36 | [Access Control Bugs](./36-access-control-bugs/) | Uninitialized ownership, role escalation | ✅ Complete |
| 37 | [Gas DoS Attacks](./37-gas-dos-attacks/) | Unbounded loops, griefing | ✅ Complete |
| 38 | [Signature Replay Attack](./38-signature-replay/) | Missing nonce, chainId issues | ✅ Complete |
| 39 | [Governance Attack Simulation](./39-governance-attack/) | Flashloan voting, quorum manipulation | ✅ Complete |
| 40 | [Multi-Sig Wallet](./40-multisig-wallet/) | Threshold approvals, queued txs | ✅ Complete |

---

### 🏦 4626 VAULT MASTERY & DEFI ENGINEERING (Projects 11, 42-50)

**Note**: Project 41 is not included in this track. The ERC-4626 base vault is covered in Project 11, and advanced vault topics continue from Project 42 onwards.

| # | Project | Core Concepts | Status |
|---|---------|--------------|--------|
| 11 | [ERC-4626 Base Vault](./11-ERC4626-tokenized-vault/) | convertToShares, deposit/mint/withdraw/redeem | ✅ Complete |
| 42 | [ERC-4626 Precision & Rounding](./42-vault-precision/) | Rounding modes, denominator issues | ✅ Complete |
| 43 | [Yield-Bearing Vault](./43-yield-vault/) | Interest accrual, harvest, reinvest | ✅ Complete |
| 44 | [Inflation Attack Demo](./44-inflation-attack/) | Donation attack, mitigation patterns | ✅ Complete |
| 45 | [Multi-Asset Vault](./45-multi-asset-vault/) | Basket of tokens, weighted NAV | ✅ Complete |
| 46 | [Vault Insolvency Scenarios](./46-vault-insolvency/) | Bad debt, emergency withdrawals | ✅ Complete |
| 47 | [Vault Oracle Integration](./47-vault-oracle/) | TWAP, stale data handling | ✅ Complete |
| 48 | [Meta-Vault (4626→4626)](./48-meta-vault/) | Wrapping vaults, compounding | ✅ Complete |
| 49 | [Leverage Looping Vault](./49-leverage-vault/) | Borrow-deposit loop, liquidation bands | ✅ Complete |
| 50 | [Full DeFi Protocol Capstone](./50-defi-capstone/) | Token+NFT+Vault+Governance+Multisig | ✅ Complete |

---

## 🎓 Learning Tracks & Paths

### Track 1: Complete Beginner
**For:** Developers new to Solidity and blockchain

**Path:**
1. Projects 01-10 (Foundations)
2. Projects 11-20 (Intermediate)
3. Projects 21-30 (Token Standards)
4. Projects 31-40 (Security)
5. Projects 41-50 (Advanced DeFi)

**Time Estimate:** 3-6 months (part-time)

### Track 2: Experienced Developer
**For:** Developers with experience in TypeScript, Go, or Rust

**Path:**
1. Projects 01-05 (Quick review)
2. Projects 06-15 (Core concepts)
3. Projects 16-25 (Advanced patterns)
4. Projects 26-35 (Security focus)
5. Projects 36-50 (DeFi mastery)

**Time Estimate:** 2-4 months (part-time)

### Track 3: Security Focus
**For:** Developers wanting to specialize in security

**Path:**
1. Projects 01-10 (Foundations - required)
2. Projects 11, 31-40 (Security labs)
3. Projects 42, 44, 46 (Vault security)
4. Projects 33-34 (Attack vectors)

**Time Estimate:** 2-3 months (part-time)

### Track 4: DeFi Specialist
**For:** Developers building DeFi protocols

**Path:**
1. Projects 01-10 (Foundations)
2. Projects 11, 20 (Vault basics)
3. Projects 21-23 (Token standards)
4. Projects 41-50 (Advanced vaults)

**Time Estimate:** 3-5 months (part-time)

---

## 🗺️ Project Navigation Guide

### Quick Start Paths

#### Path A: "I Want to Build a Token"

1. **Week 1:** Projects 01-05 (Foundations)
2. **Week 2:** Projects 21-22 (ERC-20)
3. **Week 3:** Project 23 (ERC-20 Permit)
4. **Week 4:** Deploy and test your token!

#### Path B: "I Want to Build an NFT"

1. **Week 1:** Projects 01-05 (Foundations)
2. **Week 2:** Projects 24-25 (ERC-721)
3. **Week 3:** Projects 27-28 (Soulbound, Royalties)
4. **Week 4:** Projects 29-30 (Allowlists, SVG)

#### Path C: "I Want to Build a Vault"

1. **Week 1:** Projects 01-05 (Foundations)
2. **Week 2:** Projects 11-12 (Security basics)
3. **Week 3:** Project 20 (Deposit/Withdraw)
4. **Week 4:** Project 41 (ERC-4626)
5. **Week 5:** Projects 42-43 (Precision, Yield)

#### Path D: "I Want to Learn Security"

1. **Week 1:** Projects 01-10 (Foundations)
2. **Week 2:** Projects 11, 31-32 (Reentrancy, Overflow)
3. **Week 3:** Projects 33-35 (MEV, Oracle, Delegatecall)
4. **Week 4:** Projects 36-38 (Access Control, Gas DoS, Signature Replay)
5. **Week 5:** Projects 39-40 (Governance, Multisig)

### Project Dependencies

#### Foundation Projects (Must Complete First)

**Project 01: Datatypes & Storage**
- **Prerequisites:** None
- **Teaches:** Types, storage, memory, calldata
- **Required for:** All subsequent projects

**Project 02: Functions & Payable**
- **Prerequisites:** Project 01
- **Teaches:** Function visibility, payable, ETH transfers
- **Required for:** Projects 11, 20, 40+

**Project 03: Events & Logging**
- **Prerequisites:** Project 01
- **Teaches:** Events, indexing, off-chain data
- **Required for:** All token projects (21-30)

**Project 04: Modifiers & Access Control**
- **Prerequisites:** Project 02
- **Teaches:** Custom modifiers, access patterns
- **Required for:** Projects 11, 36, 40+

**Project 05: Errors & Reverts**
- **Prerequisites:** Project 01
- **Teaches:** Error handling, custom errors
- **Required for:** All projects

#### Intermediate Projects

**Project 11: Reentrancy & Security**
- **Prerequisites:** Projects 01-05
- **Teaches:** CEI pattern, reentrancy attacks
- **Required for:** Projects 31, 40, 42+

**Project 12: Safe ETH Transfer**
- **Prerequisites:** Projects 02, 11
- **Teaches:** Pull payments, withdrawal patterns
- **Required for:** Projects 20, 40, 42+

**Project 20: Deposit/Withdraw Accounting**
- **Prerequisites:** Projects 01-05, 11-12
- **Teaches:** Share accounting, vault basics
- **Required for:** Projects 41-50 (all vault projects)

#### Token Standard Projects

**Project 21: ERC-20 From Scratch**
- **Prerequisites:** Projects 01-05
- **Teaches:** Token basics, transfers, approvals
- **Required for:** Projects 22, 23, 41+

**Project 22: ERC-20 (OpenZeppelin)**
- **Prerequisites:** Project 21
- **Teaches:** Production patterns, hooks
- **Required for:** Projects 23, 41+

**Project 24: ERC-721 From Scratch**
- **Prerequisites:** Projects 01-05
- **Teaches:** NFT basics, ownership
- **Required for:** Projects 25, 27, 28

#### Advanced Vault Projects

**Project 41: ERC-4626 Base Vault**
- **Prerequisites:** Projects 11, 20, 21
- **Teaches:** ERC-4626 standard, share accounting
- **Required for:** Projects 42-50

**Project 42: Vault Precision**
- **Prerequisites:** Project 41
- **Teaches:** Rounding, precision issues
- **Required for:** Projects 43-50

**Project 43: Yield Vault**
- **Prerequisites:** Projects 41-42
- **Teaches:** Yield generation, strategies
- **Required for:** Projects 48-49

### Prerequisites Matrix

| Project | Requires Projects | Difficulty | Time Estimate |
|--------|------------------|------------|---------------|
| 01 | None | Beginner | 2-3 hours |
| 02 | 01 | Beginner | 2-3 hours |
| 03 | 01 | Beginner | 2-3 hours |
| 04 | 02 | Beginner | 2-3 hours |
| 05 | 01 | Beginner | 2-3 hours |
| 06 | 01-05 | Beginner | 3-4 hours |
| 11 | 01-05 | Intermediate | 4-6 hours |
| 12 | 02, 11 | Intermediate | 3-4 hours |
| 20 | 01-05, 11-12 | Intermediate | 4-6 hours |
| 21 | 01-05 | Intermediate | 4-6 hours |
| 22 | 21 | Intermediate | 3-4 hours |
| 24 | 01-05 | Intermediate | 4-6 hours |
| 31 | 11 | Advanced | 4-6 hours |
| 41 | 11, 20, 21 | Advanced | 6-8 hours |
| 42 | 41 | Advanced | 6-8 hours |
| 50 | 41-49 | Expert | 10-15 hours |

### Tips for Navigation

1. **Don't skip foundations** - Projects 01-10 are essential
2. **Follow dependencies** - Check prerequisites before starting
3. **Take your time** - Understanding is more important than speed
4. **Experiment** - Modify code, break things, learn from mistakes
5. **Read solutions** - Even if you solve it yourself, read the solution
6. **Run tests** - Always run tests to verify understanding
7. **Deploy locally** - Use Anvil to see contracts in action

---

## 📊 Progress Tracker

Use this section to track your progress through the 50 projects.

### Completion Status

| Project | Status | Concepts Mastered | Completed Date |
|---------|--------|-------------------|----------------|
| 01 - Datatypes & Storage | ⬜ | `uint`, `mapping`, storage vs memory, gas costs | - |
| 02 - Functions & Payable | ⬜ | `payable`, `receive()`, `fallback()`, ETH transfers | - |
| 03 - Events & Logging | ⬜ | `event`, `emit`, indexed parameters | - |
| 04 - Modifiers & Access Control | ⬜ | Custom modifiers, `onlyOwner`, RBAC | - |
| 05 - Errors & Reverts | ⬜ | `require()`, `revert()`, custom errors | - |
| 06 - Mappings, Arrays & Gas | ⬜ | Storage slot hashing, iteration costs | - |
| 07 - Reentrancy & Security | ⬜ | Reentrancy attack, CEI pattern | - |
| 08 - ERC20 from Scratch | ⬜ | Token standard, manual vs OpenZeppelin | - |
| 09 - ERC721 NFT | ⬜ | NFT standard, metadata, approvals | - |
| 10 - Upgradeability & Proxies | ⬜ | UUPS proxy, storage collisions | - |
| 11 - ERC-4626 Tokenized Vault | ⬜ | Vault standard, share math, DeFi yield | - |
| 12-50 - Continue tracking... | ⬜ | ... | - |

**Total Estimated Time**: 140-190 hours for complete mastery of all 47 projects

### Learning Objectives by Project Category

#### Beginner Track (Projects 1-10)

**Core Fundamentals**:
- Understand Solidity's static type system
- Distinguish between value types and reference types
- Master storage vs memory vs calldata location keywords
- Analyze gas costs of different data structures
- Master function visibility (public, external, internal, private)
- Understand `payable` functions and receiving ETH
- Emit events for state changes
- Use indexed parameters for filtering
- Create custom function modifiers
- Implement ownership patterns
- Use `require()`, `revert()`, and `assert()` appropriately
- Implement custom errors (Solidity 0.8.4+)

#### Intermediate Track (Projects 11-20)

**Security Patterns and Advanced Concepts**:
- Reproduce classic reentrancy attack
- Apply Checks-Effects-Interactions pattern
- Implement pull payment patterns
- Handle block timestamp and time-based logic
- Master ABI encoding and function selectors
- Use low-level calls safely
- Implement factory patterns with CREATE2
- Work with minimal proxy patterns (EIP-1167)
- Integrate Chainlink oracles
- Implement EIP-712 signed messages
- Master deposit/withdraw accounting

#### Token Standards Track (Projects 21-30)

**ERC Implementation Mastery**:
- Implement ERC-20 interface manually
- Compare to OpenZeppelin ERC-20
- Understand approval/allowance mechanics
- Implement ERC-20 Permit (EIP-2612)
- Implement ERC-721 interface manually
- Handle token metadata and URIs
- Implement safe transfer callbacks
- Optimize batch minting (ERC-721A)
- Master ERC-1155 multi-token standard
- Implement soulbound tokens
- Add royalty standards (ERC-2981)
- Use Merkle trees for allowlists
- Generate on-chain SVG

#### Security Labs Track (Projects 31-40)

**Attack Vectors and Defense**:
- Master reentrancy attacks and defenses
- Understand integer overflow/underflow
- Learn MEV and front-running prevention
- Prevent oracle manipulation
- Avoid delegatecall corruption
- Implement proper access control
- Prevent gas DoS attacks
- Protect against signature replay
- Secure governance mechanisms
- Build multi-sig wallets

#### Advanced DeFi Track (Projects 41-50)

**Protocol Engineering**:
- Implement ERC-4626 Tokenized Vault Standard
- Master share/asset conversion mathematics
- Handle deposit/withdraw mechanisms
- Learn vault security patterns (inflation attack, donation attack)
- Understand real-world DeFi yield strategies
- Handle rounding and precision issues
- Implement yield-bearing vaults
- Build multi-asset vaults
- Handle insolvency scenarios
- Integrate oracles with vaults
- Build meta-vaults and leverage vaults
- Complete full DeFi protocol capstone

### Completion Checklist

After completing all 47 projects, you should be able to:

- [ ] Read and understand production Solidity code
- [ ] Identify common security vulnerabilities
- [ ] Estimate gas costs for operations
- [ ] Make informed trade-offs in contract design
- [ ] Use Foundry for testing and deployment
- [ ] Integrate with OpenZeppelin libraries
- [ ] Deploy contracts to testnets and mainnet
- [ ] Verify contracts on Etherscan
- [ ] Build full-stack dApps with smart contract backends
- [ ] Implement all major token standards (ERC-20, ERC-721, ERC-1155, ERC-4626)
- [ ] Design and implement DeFi protocols
- [ ] Conduct security audits and code reviews
- [ ] Optimize contracts for gas efficiency
- [ ] Understand and prevent MEV exploitation

---

## 🎓 How to Use This Repository

### Path 1: Guided Learning (Recommended for beginners)

1. **Read** the project README to understand objectives
2. **Read** [LEARNING_GUIDE.md](./LEARNING_GUIDE.md) for quick reference
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
- Refer to specialized guides ([LEARNING_GUIDE.md](./LEARNING_GUIDE.md), [DEFI_REFERENCE.md](./DEFI_REFERENCE.md), [PROJECT_MANAGEMENT.md](./PROJECT_MANAGEMENT.md))

---

## 🔧 Development Workflow

### Compiling Contracts

**Explicit Compilation:**

While Foundry automatically compiles when running tests or scripts, you can compile explicitly:

```bash
# Compile all contracts
forge build

# Force recompilation (useful after dependency changes)
forge build --force

# Verbose compilation output
forge build -vv

# Show contract sizes (important for 24KB limit)
forge build --sizes

# Compile specific contract
forge build --contracts src/MyContract.sol
```

**Understanding Compiled Artifacts:**

After compilation, artifacts are saved in `out/` directory:
```
out/
├── DatatypesStorage.sol/
│   └── DatatypesStorage.json    # Contains bytecode, ABI, metadata
├── MyContract.sol/
│   └── MyContract.json
└── ...
```

**Each JSON file contains:**
- `bytecode.object`: Deployment bytecode (constructor + contract code)
- `deployedBytecode.object`: Runtime bytecode (what's stored on-chain)
- `abi`: Application Binary Interface (function signatures, events)
- `metadata`: Compiler version, settings, source mappings

**Extracting and Analyzing Bytecode:**

```bash
# Extract deployment bytecode
cat out/DatatypesStorage.sol/DatatypesStorage.json | jq -r '.bytecode.object' > deployment-bytecode.txt

# Extract runtime bytecode (what's actually deployed)
cat out/DatatypesStorage.sol/DatatypesStorage.json | jq -r '.deployedBytecode.object' > runtime-bytecode.txt

# Extract ABI
cat out/DatatypesStorage.sol/DatatypesStorage.json | jq '.abi' > abi.json

# View contract size (critical - contracts must be < 24KB)
forge build --sizes
```

**Why Bytecode Analysis Matters:**
- **Security**: Analyze deployed bytecode for vulnerabilities
- **Verification**: Compare on-chain bytecode with compiled bytecode
- **Optimization**: Understand gas costs at the opcode level
- **Size Limits**: Ensure contracts don't exceed 24KB deployment limit
- **Upgradeability**: Compare bytecode versions for proxy patterns

**Bytecode Analysis Tools:**
- **evm.codes**: Interactive EVM opcode reference and disassembler
- **Etherscan**: View verified bytecode on-chain
- **Mythril**: Security analysis of bytecode
- **Panoramix**: Decompiler for EVM bytecode
- **Cast**: Foundry's CLI tool for bytecode operations

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

### Local Deployment (Anvil Only)

**⚠️ This project is designed for LOCAL DEVELOPMENT ONLY on Anvil**

```bash
# Terminal 1: Start Anvil (keep running)
anvil

# Terminal 2: Deploy contract to local Anvil
cd 01-datatypes-and-storage

# Load environment variables
source ../.env  # Or export PRIVATE_KEY=0xac0974...

# Deploy to Anvil
forge script script/DeployDatatypesStorage.s.sol \
  --broadcast \
  --rpc-url http://localhost:8545

# The script will use PRIVATE_KEY from .env automatically
# All 10 Anvil accounts are available via PRIVATE_KEY, PRIVATE_KEY_1-9
```

**Important Notes:**
- **Never deploy to testnets or mainnet** - this is a learning project
- All deployments use the local Anvil chain (`http://localhost:8545`)
- Use `PRIVATE_KEY` for main deployer, `PRIVATE_KEY_1` through `PRIVATE_KEY_9` for multi-address interactions
- Anvil accounts are pre-funded with 10,000 ETH each

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

### Standardization & Tooling Roadmap

- **Scripts & Makefile**: Add `scripts/setup.sh`, `scripts/test-all.sh`, and a root `Makefile` so newcomers can run `make setup && make test`.
- **Templates**: Create `docs/TEMPLATE_README.md` plus a `PROJECT_TEMPLATE/` folder to keep structure consistent across all 50 projects.
- **Progress Tracking**: Ship a gitignored `PROGRESS.md` generator to log completions locally without polluting the repo.
- **Validation**: Add `scripts/validate-structure.sh` and naming checks to keep contracts/tests/scripts aligned (`PascalCase`, `DeployPascalCase.s.sol`, etc.).
- **Gas + Coverage**: Include `scripts/gas-benchmark.sh` and coverage targets in a future CI matrix.

---

## 📚 Comprehensive Documentation

This repository includes extensive reference materials organized by purpose:

### Learning Resources

- **[LEARNING_GUIDE.md](./LEARNING_GUIDE.md)** (8,000+ lines)
  - **Part 1**: Solidity basics (data types, functions, storage, patterns)
  - **Part 2**: Language comparisons (TypeScript/Go/Rust vs Solidity)
  - **Part 3**: Foundry development (testing, deployment, advanced patterns)
  - **Part 4**: Gas optimization (storage, functions, loops, advanced techniques)
  - **Part 5**: Security checklist (reentrancy, access control, testing, deployment)
  - **Use when**: Learning syntax, comparing concepts, optimizing gas, security review

### DeFi Reference

- **[DEFI_REFERENCE.md](./DEFI_REFERENCE.md)** (4,700+ lines)
  - **Part 1**: DeFi attack vectors (reentrancy, flashloans, oracle manipulation, MEV, etc.)
  - **Part 2**: ERC-4626 vault mathematics (share calculations, rounding, precision)
  - **Use when**: Building vaults, understanding attacks, implementing ERC-4626

### Project Management

- **[PROJECT_MANAGEMENT.md](./PROJECT_MANAGEMENT.md)**
  - Learning tracks and paths
  - Project dependencies and prerequisites
  - Naming standards and implementation status
  - **Use when**: Planning your learning path, tracking progress

### Quick Reference Guide

| Need Help With | Check This |
|---------------|------------|
| Solidity syntax | [LEARNING_GUIDE.md](./LEARNING_GUIDE.md) Part 1 |
| Foundry commands | [LEARNING_GUIDE.md](./LEARNING_GUIDE.md) Part 3 |
| Gas optimization | [LEARNING_GUIDE.md](./LEARNING_GUIDE.md) Part 4 |
| Security patterns | [LEARNING_GUIDE.md](./LEARNING_GUIDE.md) Part 5 |
| DeFi attacks | [DEFI_REFERENCE.md](./DEFI_REFERENCE.md) Part 1 |
| Vault math | [DEFI_REFERENCE.md](./DEFI_REFERENCE.md) Part 2 |
| Project navigation | [PROJECT_MANAGEMENT.md](./PROJECT_MANAGEMENT.md) |

---

## ❓ Common Questions

**Q: Do I need to complete all 50 projects?**  
A: No! Choose a learning track that matches your goals. See [Learning Tracks & Paths](#-learning-tracks--paths) above.

**Q: Can I skip foundation projects?**  
A: Not recommended. Projects 01-10 teach essential concepts used throughout all subsequent projects.

**Q: How long does each project take?**  
A: 2-15 hours depending on difficulty. See [Prerequisites Matrix](#prerequisites-matrix) in PROJECT_MANAGEMENT.md for detailed estimates.

**Q: Where do I find solutions?**  
A: Each project has a `solution/` folder with fully documented implementations. Study them even if you solve it yourself!

**Q: What if I'm stuck?**  
A: 1) Read the project README thoroughly, 2) Check the solution file for hints, 3) Review [LEARNING_GUIDE.md](./LEARNING_GUIDE.md) for concepts

**Q: Can I use this code in production?**  
A: These are educational projects. Always audit production code professionally and follow security best practices.

**Q: Which projects are most important?**  
A: Projects 01-10 (foundations) are essential. After that, choose based on your goals (tokens, NFTs, vaults, security).

**Q: Do I need prior blockchain knowledge?**  
A: No! Start with Project 01. Basic programming knowledge (any language) is helpful but not required.

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

## 🚀 Next Steps After Completion

1. **Build a portfolio project**: Combine concepts from multiple projects
2. **Audit open-source contracts**: Practice on Etherscan verified contracts
3. **Contribute to DeFi protocols**: Many have "good first issue" labels
4. **Participate in CTFs**: Ethernaut, Damn Vulnerable DeFi, Paradigm CTF
5. **Study production vaults**: Yearn, Beefy, Aave, Compound
6. **Build your own DeFi protocol**: Combine ERC-20, ERC-721, ERC-4626
7. **Stay updated**: Follow EIPs, security disclosures, and new patterns

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

## 📞 Resources

- **Foundry Book**: https://book.getfoundry.sh/
- **Solidity Docs**: https://docs.soliditylang.org/
- **OpenZeppelin**: https://docs.openzeppelin.com/
- **EIPs**: https://eips.ethereum.org/
- **Etherscan**: https://etherscan.io/
- **Smart Contract Security Best Practices**: https://consensys.github.io/smart-contract-best-practices/
- **EIP-4626 Specification**: https://eips.ethereum.org/EIPS/eip-4626
- **Ethereum.org Developer Docs**: https://ethereum.org/en/developers/docs/

---

**Remember**: Smart contracts control real value. Test extensively, audit professionally, and never deploy experimental code to mainnet with funds at risk.

**Security is not optional. Gas optimization comes after correctness.**

*Happy building! 🚀*
