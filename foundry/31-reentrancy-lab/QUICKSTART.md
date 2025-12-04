# Quick Start Guide

Get up and running with the Advanced Reentrancy Lab in 5 minutes!

## Prerequisites

```bash
# Install Foundry (if not already installed)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Verify installation
forge --version
```

## Installation

```bash
# Navigate to the project
cd 31-reentrancy-lab

# Install dependencies
forge install foundry-rs/forge-std --no-commit

# Build the project
forge build
```

## Run Tests

```bash
# Run all tests
forge test

# Run with verbose output
forge test -vvv

# Run specific test
forge test --match-test testMultiFunctionReentrancy -vvvv

# Run with gas report
forge test --gas-report
```

## Project Structure

```
31-reentrancy-lab/
├── README.md                    # Comprehensive theory & case studies
├── LEARNING_GUIDE.md           # Step-by-step learning path
├── QUICKSTART.md               # This file
├── foundry.toml                # Foundry configuration
├── src/
│   ├── Project31.sol           # Vulnerable contracts (student version)
│   └── solution/
│       └── Project31Solution.sol   # Complete solutions
├── test/
│   └── Project31.t.sol         # Comprehensive tests
└── script/
    └── DeployProject31.s.sol   # Deployment scripts
```

## What to Study

### 1. Theory First (1-2 hours)
- Read **README.md** for comprehensive coverage
- Understand the 4 attack types:
  - Multi-function reentrancy
  - Cross-contract reentrancy
  - Read-only reentrancy
  - Multi-hop chains

### 2. Hands-On (3-4 hours)
- Study vulnerable contracts in `src/Project31.sol`
- Complete the attacker templates (look for TODOs)
- Run tests to verify your attacks work

### 3. Defense (2-3 hours)
- Compare vulnerable vs secure implementations
- Understand defense mechanisms
- Study the test suite in `test/Project31.t.sol`

## Quick Commands

```bash
# Build everything
forge build

# Test everything
forge test -vvv

# Test specific attack type
forge test --match-test "MultiFunction" -vvvv
forge test --match-test "CrossContract" -vvvv
forge test --match-test "ReadOnly" -vvvv
forge test --match-test "MultiHop" -vvvv

# Test defenses
forge test --match-test "Blocked" -vvv

# Gas analysis
forge test --gas-report

# Coverage
forge coverage

# Format code
forge fmt
```

## Attack Demonstrations

### Multi-Function Reentrancy
```bash
forge test --match-test testMultiFunctionReentrancy -vvvv
```
Exploits shared state between `withdraw()` and `transfer()`

### Cross-Contract Reentrancy
```bash
forge test --match-test testCrossContractReentrancy -vvvv
```
Reenters Vault through RewardsRouter callback

### Read-Only Reentrancy
```bash
forge test --match-test testReadOnlyReentrancy -vvvv
```
Manipulates oracle price via view functions

### Multi-Hop Chain
```bash
forge test --match-test testMultiHopReentrancy -vvvv
```
Exploits A → B → C → A call chain

## Learning Path

**Beginner** (just completed Project 07):
1. Start with README.md theory
2. Study Multi-Function Reentrancy first (easiest)
3. Work through LEARNING_GUIDE.md step-by-step

**Intermediate** (familiar with reentrancy):
1. Jump to Cross-Contract Reentrancy
2. Study Read-Only Reentrancy case studies
3. Complete all attacker templates

**Advanced** (want to master reentrancy):
1. Study all attack patterns
2. Analyze real-world exploits
3. Write your own tests
4. Try to break the secure implementations

## Key Files

| File | Purpose | Lines |
|------|---------|-------|
| `README.md` | Theory, case studies, defenses | 565 |
| `LEARNING_GUIDE.md` | Step-by-step walkthrough | 475 |
| `src/Project31.sol` | Vulnerable contracts + TODOs | 562 |
| `src/solution/Project31Solution.sol` | Complete solutions | 1035 |
| `test/Project31.t.sol` | Comprehensive test suite | 704 |
| `script/DeployProject31.s.sol` | Deployment scripts | 308 |

**Total: 3,649 lines of educational content!**

## Common Issues

### Issue: "forge: command not found"
**Solution:** Install Foundry
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Issue: "forge-std not found"
**Solution:** Install dependencies
```bash
forge install foundry-rs/forge-std --no-commit
```

### Issue: Tests fail
**Solution:** Build first
```bash
forge build
forge test
```

### Issue: Need more detail
**Solution:** Use verbose flags
```bash
forge test -vvvv  # Very verbose with traces
```

## Next Steps

1. **Complete the exercises** in LEARNING_GUIDE.md
2. **Study the solutions** in `src/solution/`
3. **Read case studies** in README.md
4. **Run all tests** to see attacks in action
5. **Deploy locally** using the deployment scripts

## Get Help

- **Re-read theory:** README.md has extensive explanations
- **Check solutions:** All attacks are fully implemented
- **Run with trace:** Use `-vvvv` to see execution flow
- **Study tests:** `test/Project31.t.sol` shows all patterns

## Pro Tips

1. **Use traces:** `-vvvv` shows the entire call stack
2. **Check events:** Look for event emissions in tests
3. **Compare implementations:** Vulnerable vs Secure side-by-side
4. **Gas costs:** Run `--gas-report` to see security overhead
5. **Real exploits:** Read the case studies for context

## Resources

- [Foundry Book](https://book.getfoundry.sh/)
- [Smart Contract Security](https://consensys.github.io/smart-contract-best-practices/)
- [OpenZeppelin Security](https://docs.openzeppelin.com/contracts/4.x/api/security)

---

Ready to become a reentrancy expert? Start with:

```bash
forge test --match-test testMultiFunctionReentrancy -vvvv
```

Good luck! 🚀
