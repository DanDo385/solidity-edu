# Project Navigation Guide

> **Learning paths and project dependencies for the Solidity Education curriculum**

This guide helps you navigate the 50 projects and choose the best learning path for your experience level.

## Table of Contents

1. [Learning Tracks](#learning-tracks)
2. [Project Dependencies](#project-dependencies)
3. [Quick Start Paths](#quick-start-paths)
4. [Project Categories](#project-categories)
5. [Prerequisites Matrix](#prerequisites-matrix)

---

## Learning Tracks

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

## Project Dependencies

### Foundation Projects (Must Complete First)

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

### Intermediate Projects

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

### Token Standard Projects

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

### Advanced Vault Projects

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

---

## Quick Start Paths

### Path A: "I Want to Build a Token"

1. **Week 1:** Projects 01-05 (Foundations)
2. **Week 2:** Projects 21-22 (ERC-20)
3. **Week 3:** Project 23 (ERC-20 Permit)
4. **Week 4:** Deploy and test your token!

### Path B: "I Want to Build an NFT"

1. **Week 1:** Projects 01-05 (Foundations)
2. **Week 2:** Projects 24-25 (ERC-721)
3. **Week 3:** Projects 27-28 (Soulbound, Royalties)
4. **Week 4:** Projects 29-30 (Allowlists, SVG)

### Path C: "I Want to Build a Vault"

1. **Week 1:** Projects 01-05 (Foundations)
2. **Week 2:** Projects 11-12 (Security basics)
3. **Week 3:** Project 20 (Deposit/Withdraw)
4. **Week 4:** Project 41 (ERC-4626)
5. **Week 5:** Projects 42-43 (Precision, Yield)

### Path D: "I Want to Learn Security"

1. **Week 1:** Projects 01-10 (Foundations)
2. **Week 2:** Projects 11, 31-32 (Reentrancy, Overflow)
3. **Week 3:** Projects 33-35 (MEV, Oracle, Delegatecall)
4. **Week 4:** Projects 36-38 (Access Control, Gas DoS, Signature Replay)
5. **Week 5:** Projects 39-40 (Governance, Multisig)

---

## Project Categories

### Foundations (Projects 1-10)
**Focus:** Core Solidity concepts
- Datatypes, functions, events, modifiers, errors
- Mappings, arrays, gas optimization
- Reentrancy, safe transfers

**Best for:** Complete beginners

### Intermediate (Projects 11-20)
**Focus:** Security patterns and advanced concepts
- Reentrancy protection
- Safe ETH transfers
- Block time logic
- ABI encoding
- Low-level calls
- Contract factories
- Oracles
- Signed messages
- Deposit/withdraw patterns

**Best for:** Developers ready for production patterns

### Token Standards (Projects 21-30)
**Focus:** ERC standards implementation
- ERC-20 (basic and OpenZeppelin)
- ERC-20 Permit
- ERC-721 (basic and optimized)
- ERC-1155
- Soulbound tokens
- Royalties
- Merkle allowlists
- On-chain SVG

**Best for:** NFT/token developers

### Security Labs (Projects 31-40)
**Focus:** Attack vectors and defenses
- Reentrancy attacks
- Integer overflow
- MEV and front-running
- Oracle manipulation
- Delegatecall corruption
- Access control bugs
- Gas DoS attacks
- Signature replay
- Governance attacks
- Multisig wallets

**Best for:** Security auditors and developers

### Advanced DeFi (Projects 41-50)
**Focus:** Complex DeFi protocols
- ERC-4626 vaults
- Precision and rounding
- Yield generation
- Inflation attacks
- Multi-asset vaults
- Insolvency scenarios
- Oracle integration
- Meta-vaults
- Leverage vaults
- Full DeFi capstone

**Best for:** DeFi protocol developers

---

## Prerequisites Matrix

| Project | Requires Projects | Difficulty | Time Estimate |
|--------|------------------|------------|---------------|
| 01 | None | Beginner | 2-3 hours |
| 02 | 01 | Beginner | 2-3 hours |
| 03 | 01 | Beginner | 2-3 hours |
| 04 | 02 | Beginner | 2-3 hours |
| 05 | 01 | Beginner | 2-3 hours |
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

---

## Recommended Learning Order

### For Complete Beginners

```
Week 1: Projects 01-05 (Foundations)
Week 2: Projects 06-10 (Advanced foundations)
Week 3: Projects 11-15 (Security and patterns)
Week 4: Projects 16-20 (Advanced concepts)
Week 5-6: Choose a track (Tokens, NFTs, Vaults, Security)
```

### For Experienced Developers

```
Week 1: Projects 01-05 (Quick review)
Week 2: Projects 11-15 (Core patterns)
Week 3: Projects 21-25 (Token standards)
Week 4: Projects 31-35 (Security)
Week 5: Projects 41-45 (Vaults)
Week 6: Projects 46-50 (Advanced DeFi)
```

### For Security Focus

```
Week 1: Projects 01-10 (Foundations)
Week 2: Projects 11, 31-32 (Reentrancy, Overflow)
Week 3: Projects 33-35 (MEV, Oracle, Delegatecall)
Week 4: Projects 36-38 (Access Control, DoS, Replay)
Week 5: Projects 39-40, 42, 44 (Governance, Multisig, Attacks)
```

---

## Tips for Navigation

1. **Don't skip foundations** - Projects 01-10 are essential
2. **Follow dependencies** - Check prerequisites before starting
3. **Take your time** - Understanding is more important than speed
4. **Experiment** - Modify code, break things, learn from mistakes
5. **Read solutions** - Even if you solve it yourself, read the solution
6. **Run tests** - Always run tests to verify understanding
7. **Deploy locally** - Use Anvil to see contracts in action

---

## Getting Help

- **Stuck on a concept?** Re-read the project README
- **Tests failing?** Check the solution file for hints
- **Confused about dependencies?** Refer to this guide
- **Want to skip ahead?** Make sure you understand prerequisites

---

**Happy learning!** 🚀
