# Solidity Educational Repository 📚

> **Master Solidity from first principles through hands-on projects**

## Overview

This repository is a comprehensive Solidity education platform designed to take you from complete beginner to production-ready smart contract developer through **47 progressively complex mini-projects**.

## What's Inside

This repository contains a complete Solidity learning curriculum built with **Foundry**, covering everything from basic datatypes to building full DeFi protocols.

### 📁 Repository Structure

```
solidity-edu/
├── README.md                # This file - high-level overview
├── foundry/                 # Main learning directory (47 mini-projects)
│   ├── README.md           # Complete curriculum guide & navigation
│   ├── 01-datatypes-and-storage/
│   ├── 02-functions-and-payable/
│   ├── ... (47 projects total)
│   └── 50-defi-capstone/
├── edu.md                   # Combined educational content from all projects
├── .env.example            # Environment variable template
└── LICENSE                 # MIT License

```

## 🚀 Quick Start

### Prerequisites

1. **Install Foundry**:
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Clone the repository**:
   ```bash
   git clone <repo-url>
   cd solidity-edu
   ```

3. **Set up environment**:
   ```bash
   cp .env.example .env
   # Uses default Anvil accounts for local development
   ```

4. **Install dependencies**:
   ```bash
   cd foundry
   forge install
   ```

### First Steps

1. **Start here**: Read `foundry/README.md` for the complete curriculum guide
2. **Begin learning**: Navigate to `foundry/01-datatypes-and-storage/`
3. **Follow along**: Each project has its own README with learning objectives
4. **Track progress**: Use the progress tracker in `foundry/README.md`

## 📚 Learning Path

### The 47-Project Curriculum

The curriculum is organized into 5 tracks:

1. **Beginner Foundations** (Projects 1-10)
   - Datatypes, storage, functions, events, modifiers
   - Learn Solidity basics and EVM fundamentals

2. **Intermediate Concepts** (Projects 11-20)
   - Reentrancy, ETH transfers, oracles, encoding
   - Master security patterns and advanced features

3. **Token Standards** (Projects 22-30)
   - ERC-20, ERC-721, ERC-1155, soulbound tokens
   - Implement all major token standards from scratch

4. **Security & Attacks** (Projects 31-40)
   - Reentrancy, overflow, MEV, oracle manipulation
   - Learn attack vectors and defense strategies

5. **DeFi Engineering** (Projects 11, 42-50)
   - ERC-4626 vaults, yield strategies, flash loans
   - Build production-grade DeFi protocols

**Total**: 47 projects, ~140-190 hours of learning

**Note**: Projects 21, 24, and 41 are not included in the sequence.

## 🎯 What Makes This Different

- **First Principles**: Understand *why* Solidity works the way it does
- **Security First**: Learn vulnerabilities and attack vectors from day 1
- **Production Ready**: Use industry-standard tools (Foundry, OpenZeppelin)
- **Comprehensive**: Every project includes skeleton code, tests, solutions, and deployment scripts
- **Deep Documentation**: Extensive inline comments explaining computer science concepts
- **Comparative Learning**: Compare Solidity with TypeScript, Go, Rust, and Python
- **Gas Awareness**: Every lesson discusses computational costs and optimizations

## 📖 Documentation

### Main Guides

- **[foundry/README.md](./foundry/README.md)** - Complete curriculum guide
  - 47-project breakdown
  - Learning tracks and paths
  - Quick reference for Foundry commands
  - Navigation and progress tracking

- **[edu.md](./edu.md)** - Combined educational content
  - All 47 project READMEs in one file
  - Searchable reference for concepts
  - Great for offline reading or printing

### Additional Resources

Each project directory contains:
- `README.md` - Project-specific learning objectives and tasks
- `src/` - Skeleton contracts and solution implementations
- `test/` - Test suites and solution tests
- `script/` - Deployment scripts and examples

## 🛠️ Technology Stack

- **Solidity** ^0.8.20 - Smart contract programming language
- **Foundry** - Development framework
  - **Forge** - Testing and building
  - **Cast** - Interacting with contracts
  - **Anvil** - Local Ethereum node
- **OpenZeppelin** - Audited contract libraries
- **Solmate** - Gas-optimized primitives

## 🎓 Learning Approach

### For Complete Beginners

1. Start with Project 01 (Datatypes & Storage)
2. Follow the curriculum sequentially through Project 10
3. Use the "Complete Beginner" track in `foundry/README.md`
4. Estimated time: 3-6 months (part-time)

### For Experienced Developers

1. Review Projects 01-05 quickly for Solidity-specific concepts
2. Jump to areas of interest (tokens, NFTs, vaults, security)
3. Use the "Experienced Developer" track in `foundry/README.md`
4. Estimated time: 2-4 months (part-time)

### For Specific Goals

- **Want to build a token?** → Projects 01-05, 08, 22-23
- **Want to build an NFT?** → Projects 01-05, 09, 25-30
- **Want to build a vault?** → Projects 01-05, 11, 20, 42-50
- **Want to learn security?** → Projects 01-10, 11, 31-40

See `foundry/README.md` for detailed learning paths.

## 🧪 Running Tests

```bash
# Test everything
cd foundry
forge test

# Test specific project
cd foundry/01-datatypes-and-storage
forge test

# Test with verbose output
forge test -vvv

# Test with gas reporting
forge test --gas-report
```

## 🏗️ Building Contracts

```bash
# Build all contracts
cd foundry
forge build

# Build with sizes (check 24KB limit)
forge build --sizes

# Force rebuild
forge build --force
```

## 🎯 Learning Outcomes

After completing this curriculum, you will:

✅ Understand EVM internals and gas mechanics
✅ Write production-grade Solidity with security best practices
✅ Implement all major ERC standards (20, 721, 1155, 4626)
✅ Master Foundry for testing, fuzzing, and deployment
✅ Recognize and prevent common attack vectors
✅ Optimize contracts for gas efficiency
✅ Design upgradeable systems with proxy patterns
✅ Build complex DeFi protocols
✅ Conduct security audits and code reviews
✅ Understand MEV, front-running, and economic exploits

## 🤝 Contributing

Found a bug or have a suggestion? Please open an issue or pull request!

**Guidelines:**
- Add tests for any new features
- Follow existing code style (`forge fmt`)
- Update documentation
- Ensure all tests pass: `forge test`

## 📄 License

MIT License - Learn freely, build responsibly.

See [LICENSE](./LICENSE) for details.

## 🔗 Resources

- **Foundry Book**: https://book.getfoundry.sh/
- **Solidity Docs**: https://docs.soliditylang.org/
- **OpenZeppelin**: https://docs.openzeppelin.com/
- **Ethereum.org**: https://ethereum.org/en/developers/docs/
- **Smart Contract Security**: https://consensys.github.io/smart-contract-best-practices/

## 🎯 Next Steps

1. Read `foundry/README.md` for the complete curriculum guide
2. Start with Project 01: `cd foundry/01-datatypes-and-storage`
3. Join the community and share your progress!

---

**Remember**: Smart contracts control real value. Test extensively, audit professionally, and never deploy experimental code to mainnet with funds at risk.

**Security is not optional. Gas optimization comes after correctness.**

*Happy learning! 🚀*
