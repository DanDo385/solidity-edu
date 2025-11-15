# Project 31: Advanced Reentrancy Lab - Complete Index

## Quick Navigation

### For Quick Start
→ **[QUICKSTART.md](QUICKSTART.md)** - Get running in 5 minutes

### For Learning
→ **[LEARNING_GUIDE.md](LEARNING_GUIDE.md)** - Step-by-step curriculum

### For Theory
→ **[README.md](README.md)** - Comprehensive theory & case studies

### For Overview
→ **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** - Complete project details

---

## What's Inside

### 📚 Documentation (4 files, 1,600+ lines)

| File | Lines | Purpose |
|------|-------|---------|
| README.md | 565 | Theory, attack types, case studies, defenses |
| LEARNING_GUIDE.md | 475 | Step-by-step learning path, exercises, tips |
| QUICKSTART.md | 310 | 5-minute setup, quick commands |
| PROJECT_SUMMARY.md | 233 | Complete project overview, statistics |

### 💻 Smart Contracts (4 files, 2,300+ lines)

| File | Lines | Purpose |
|------|-------|---------|
| src/Project31.sol | 562 | Vulnerable contracts + attacker templates |
| src/solution/Project31Solution.sol | 1,035 | Complete solutions with detailed comments |
| test/Project31.t.sol | 704 | Comprehensive test suite (20+ tests) |
| script/DeployProject31.s.sol | 308 | Deployment scripts (4 variants) |

---

## Attack Types Covered

### 1️⃣ Multi-Function Reentrancy
**Files:** VulnerableBank, MultiFunctionAttacker  
**Test:** `testMultiFunctionReentrancy`  
**Exploit:** Reenter through transfer() during withdraw()

### 2️⃣ Cross-Contract Reentrancy
**Files:** VulnerableVault, RewardsRouter, CrossContractAttacker  
**Test:** `testCrossContractReentrancy`  
**Exploit:** Reenter Vault through Router callback

### 3️⃣ Read-Only Reentrancy
**Files:** VulnerableOracle, SimpleLender, ReadOnlyAttacker  
**Test:** `testReadOnlyReentrancy`  
**Exploit:** Manipulate oracle price via view functions

### 4️⃣ Multi-Hop Reentrancy
**Files:** ContractA/B/C, MultiHopAttacker  
**Test:** `testMultiHopReentrancy`  
**Exploit:** A → B → C → receive() → A.withdraw()

---

## Key Contracts

### Vulnerable Implementations
- **VulnerableBank** - Multi-function reentrancy
- **VulnerableVault** - Cross-contract reentrancy
- **VulnerableOracle** - Read-only reentrancy
- **ContractA** - Multi-hop reentrancy

### Secure Implementations
- **SecureBank** - Protected with guards + CEI
- **SecureVault** - Protected cross-contract
- **SecureOracle** - Protected view functions
- **SecureContractA** - Protected multi-hop

### Attacker Contracts
- **MultiFunctionAttacker** - Exploits shared state
- **CrossContractAttacker** - Exploits callback chain
- **ReadOnlyAttacker** - Exploits oracle manipulation
- **MultiHopAttacker** - Exploits complex call path

---

## Real-World Case Studies

1. **The DAO (2016)** - $60M - Single-function reentrancy
2. **Cream Finance (2021)** - $130M - Read-only reentrancy
3. **Curve/Vyper (2023)** - $52M - Compiler bug
4. **Lendf.Me (2020)** - $25M - ERC777 reentrancy

---

## Defense Mechanisms

### ✅ Level 1: CEI Pattern
Update state before external calls

### ✅ Level 2: Reentrancy Guards
`nonReentrant` modifier on functions

### ✅ Level 3: Pull Payments
Separate withdrawal from state changes

### ✅ Level 4: Global Guards
Shared protection across contracts

### ✅ Level 5: View Protection
Guards on read-only functions

### ✅ Level 6: Ultimate Pattern
Combines all strategies

---

## Test Suite (20+ Tests)

### Attack Demonstrations
- `testMultiFunctionReentrancy` - Proves exploit works
- `testCrossContractReentrancy` - Shows cross-contract attack
- `testReadOnlyReentrancy` - Demonstrates oracle manipulation
- `testMultiHopReentrancy` - Proves multi-hop vulnerability

### Defense Verification
- `testMultiFunctionReentrancyBlocked` - Secure version works
- `testCrossContractReentrancyBlocked` - Protection effective
- `testReadOnlyReentrancyBlocked` - View guards work
- `testMultiHopReentrancyBlocked` - Guards prevent attack

### Analysis
- `testGasComparison` - Security overhead measurement
- `testDefenseLayersAll` - All mechanisms tested
- `testRealWorldScenario_DAOAttack` - DAO simulation

---

## Quick Commands

```bash
# Setup
forge install foundry-rs/forge-std --no-commit
forge build

# Run all tests
forge test -vvv

# Test specific attack
forge test --match-test testMultiFunctionReentrancy -vvvv

# Gas analysis
forge test --gas-report

# Deploy
forge script script/DeployProject31.s.sol --broadcast
```

---

## Learning Paths

### 🟢 Beginner Path (6-8 hours)
1. Read README.md theory section
2. Study Multi-Function Reentrancy
3. Complete MultiFunctionAttacker template
4. Run tests to verify
5. Compare with secure implementation

### 🟡 Intermediate Path (4-6 hours)
1. Quick review of README.md
2. Complete all 4 attacker templates
3. Run all tests
4. Study defense mechanisms
5. Write your own tests

### 🔴 Advanced Path (3-4 hours)
1. Study all attack patterns
2. Analyze real-world case studies
3. Break secure implementations (if you can!)
4. Write additional attack vectors
5. Audit a real DeFi project

---

## File Structure

```
31-reentrancy-lab/
├── INDEX.md                        # This file
├── README.md                       # Theory & case studies
├── LEARNING_GUIDE.md              # Learning curriculum
├── QUICKSTART.md                  # Quick setup
├── PROJECT_SUMMARY.md             # Project overview
├── foundry.toml                   # Foundry config
├── .gitignore                     # Git ignores
│
├── src/
│   ├── Project31.sol              # Vulnerable contracts (student version)
│   └── solution/
│       └── Project31Solution.sol  # Complete solutions
│
├── test/
│   └── Project31.t.sol            # Comprehensive tests
│
└── script/
    └── DeployProject31.s.sol      # Deployment scripts
```

---

## Statistics

- **Total Lines:** 3,882
- **Solidity Contracts:** 18
- **Test Functions:** 20+
- **Attack Types:** 4
- **Case Studies:** 4
- **Defense Levels:** 6
- **Documentation Files:** 4

---

## Learning Outcomes

After completing this project, you will:

✅ Understand all major reentrancy attack types  
✅ Identify vulnerabilities in smart contracts  
✅ Exploit reentrancy in multiple scenarios  
✅ Implement appropriate defenses  
✅ Analyze real-world exploits  
✅ Secure DeFi protocols  
✅ Audit contracts professionally  

---

## Next Steps

1. **Start Here:**
   - New to the project? → [QUICKSTART.md](QUICKSTART.md)
   - Want structured learning? → [LEARNING_GUIDE.md](LEARNING_GUIDE.md)
   - Need theory? → [README.md](README.md)

2. **Practice:**
   - Complete attacker templates in `src/Project31.sol`
   - Run tests: `forge test -vvv`
   - Study solutions in `src/solution/`

3. **Master:**
   - Read all case studies
   - Understand all defense mechanisms
   - Audit a real project
   - Build your own secure contracts

---

## Resources

- **Foundry:** https://book.getfoundry.sh/
- **Security Best Practices:** https://consensys.github.io/smart-contract-best-practices/
- **OpenZeppelin:** https://docs.openzeppelin.com/contracts/4.x/api/security
- **SWC Registry:** https://swcregistry.io/docs/SWC-107

---

## License

MIT License - Free for educational use

---

**Ready to become a reentrancy expert?**

```bash
cd 31-reentrancy-lab
forge test --match-test testMultiFunctionReentrancy -vvvv
```

**Happy learning! 🔒🚀**
