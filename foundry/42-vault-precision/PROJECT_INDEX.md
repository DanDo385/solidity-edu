# Project 42: ERC-4626 Precision & Rounding - Complete Index

## 📁 Project Structure

```
42-vault-precision/
├── README.md                           # Main project overview & concepts
├── TUTORIAL.md                         # Step-by-step implementation guide
├── QUICKREF.md                         # Quick reference for developers
├── MATH.md                             # Mathematical proofs & theory
├── ATTACKS.md                          # Security analysis & attack scenarios
├── SETUP.md                            # Installation & setup instructions
├── PROJECT_INDEX.md                    # This file - project navigation
├── Makefile                            # Build & test automation
├── foundry.toml                        # Foundry configuration
├── .gitignore                          # Git ignore rules
│
├── src/
│   ├── Project42.sol                   # 🎯 SKELETON - Your implementation
│   └── solution/
│       └── Project42Solution.sol       # ✅ SOLUTION - Reference implementation
│
├── test/
│   └── Project42.t.sol                 # 🧪 TESTS - Comprehensive test suite
│
└── script/
    └── DeployProject42.s.sol           # 🚀 DEPLOYMENT - Deploy scripts
```

## 📖 Documentation Guide

### For Learning (Read in Order)

1. **[README.md](./README.md)** - Start here!
   - Why rounding matters
   - ERC-4626 basics
   - Security implications
   - Attack scenarios overview
   - Testing strategy

2. **[TUTORIAL.md](./TUTORIAL.md)** - Step-by-step implementation
   - How to implement `mulDiv` functions
   - Conversion function walkthroughs
   - Preview function implementation
   - Deposit/mint/withdraw/redeem logic
   - Common mistakes to avoid

3. **[QUICKREF.md](./QUICKREF.md)** - While coding
   - Quick lookup table for rounding
   - Copy-paste code snippets
   - Testing checklist
   - Common mistake warnings

### For Deep Understanding

4. **[MATH.md](./MATH.md)** - Mathematical foundations
   - Rigorous proofs of rounding formulas
   - Invariant proofs
   - Precision loss analysis
   - Exchange rate dynamics

5. **[ATTACKS.md](./ATTACKS.md)** - Security deep dive
   - Share inflation attack (detailed)
   - Precision drain attack
   - Reentrancy scenarios
   - Flash loan manipulation
   - Withdrawal front-running
   - Mitigations for each attack

### For Setup & Usage

6. **[SETUP.md](./SETUP.md)** - Getting started
   - Install Foundry
   - Install dependencies
   - Build & test commands
   - Troubleshooting

7. **[Makefile](./Makefile)** - Command reference
   - `make test` - Run all tests
   - `make test-rounding` - Test rounding only
   - `make test-attacks` - Test attack prevention
   - See file for all commands

## 🎯 Learning Paths

### Path 1: Quick Implementation (2-3 hours)

1. Read README.md (concepts)
2. Read TUTORIAL.md (implementation)
3. Implement TODOs in `src/Project42.sol`
4. Run tests: `make test`
5. Compare with solution

### Path 2: Deep Understanding (4-6 hours)

1. Read README.md
2. Read TUTORIAL.md
3. Read MATH.md (proofs)
4. Implement Project42.sol
5. Read ATTACKS.md
6. Run all test categories
7. Try to break your implementation

### Path 3: Security Focus (3-4 hours)

1. Read README.md (security section)
2. Read ATTACKS.md (all scenarios)
3. Read solution code with security comments
4. Implement with security in mind
5. Run attack tests: `make test-attacks`
6. Add additional attack tests

## 📝 File Descriptions

### Source Files

**`src/Project42.sol`** (Skeleton)
- Contains TODOs for you to implement
- Extensive comments explaining each function
- Mathematical explanations inline
- Edge case handling notes
- Lines: ~500 (with comments)

**`src/solution/Project42Solution.sol`** (Complete)
- Full working implementation
- Detailed comments on every function
- Mathematical proofs inline
- Edge case handling
- Lines: ~700 (heavily commented)

### Test File

**`test/Project42.t.sol`**
- 30+ test functions
- Categories:
  - Basic functionality
  - Rounding direction
  - Preview function accuracy
  - Edge cases
  - Invariants
  - Precision loss
  - Attack prevention
  - Allowances
  - Fuzz tests
- Lines: ~600

### Deployment

**`script/DeployProject42.s.sol`**
- Deploy skeleton
- Deploy solution
- Deploy local test environment
- Includes mock ERC20 token
- Lines: ~200

## 🧪 Testing Strategy

### Test Categories

| Category | Command | Purpose |
|----------|---------|---------|
| All Tests | `make test` | Run everything |
| Rounding | `make test-rounding` | Verify rounding directions |
| Preview | `make test-preview` | Ensure previews match actions |
| Edge Cases | `make test-edge` | Zero values, empty vault |
| Attacks | `make test-attacks` | Security validations |
| Invariants | `make test-invariants` | Mathematical properties |
| Fuzz | `make test-fuzz` | Random input testing |

### Coverage Goals

- ✅ 100% function coverage
- ✅ All rounding scenarios
- ✅ All edge cases
- ✅ All attack vectors
- ✅ Both student skeleton and solution

## 🎓 Learning Objectives

After completing this project, you will understand:

### Technical Skills
- ✅ Implementing integer division with rounding control
- ✅ Building ERC-4626 compliant vaults
- ✅ Handling edge cases in financial contracts
- ✅ Writing comprehensive tests for DeFi protocols
- ✅ Using Foundry for Solidity development

### Mathematical Understanding
- ✅ Why rounding direction affects security
- ✅ How precision loss accumulates
- ✅ Proving contract invariants
- ✅ Analyzing exchange rate dynamics

### Security Knowledge
- ✅ Share inflation attacks
- ✅ Precision drain vulnerabilities
- ✅ Reentrancy in vault operations
- ✅ Flash loan attack vectors
- ✅ First depositor manipulation
- ✅ Mitigation strategies for each

### DeFi Concepts
- ✅ Tokenized vaults (ERC-4626)
- ✅ Share-based accounting
- ✅ Deposit/withdrawal mechanics
- ✅ Preview function requirements
- ✅ Allowance patterns

## 🚀 Quick Start

```bash
# 1. Install Foundry (if not installed)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# 2. Navigate to project
cd /home/user/solidity-edu/42-vault-precision

# 3. Install dependencies
make install

# 4. Build
make build

# 5. Run tests on solution (to see expected behavior)
forge test --match-contract Project42Test -vv

# 6. Implement your version in src/Project42.sol

# 7. Test your implementation
make test

# 8. Compare with solution
diff src/Project42.sol src/solution/Project42Solution.sol
```

## 📊 Difficulty Level

- **Difficulty**: ⭐⭐⭐⭐ (Advanced)
- **Prerequisites**:
  - Solidity basics
  - ERC-20 understanding
  - Integer arithmetic
  - Testing fundamentals
- **Time to Complete**: 3-6 hours
- **Concepts**: 8-10 hours to master fully

## 🔗 Related Topics

This project prepares you for:
- Building yield aggregators (Yearn-style)
- Implementing lending protocols
- Creating liquidity mining vaults
- Developing strategy vaults
- Auditing DeFi protocols

## 🎯 Success Criteria

You've successfully completed this project when:

1. ✅ All tests pass for your implementation
2. ✅ You can explain why each function rounds its direction
3. ✅ You understand the inflation attack and its mitigation
4. ✅ You can prove vault invariants hold
5. ✅ Your code matches security best practices

## 📚 Additional Resources

### Official Documentation
- [EIP-4626 Standard](https://eips.ethereum.org/EIPS/eip-4626)
- [OpenZeppelin ERC4626](https://docs.openzeppelin.com/contracts/4.x/erc4626)
- [Solidity Math Docs](https://docs.soliditylang.org/en/latest/types.html)

### Reference Implementations
- [OpenZeppelin ERC4626.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC4626.sol)
- [Solmate ERC4626.sol](https://github.com/transmissions11/solmate/blob/main/src/mixins/ERC4626.sol)

### Security Resources
- [Trail of Bits ERC4626 Security](https://blog.trailofbits.com/2022/04/18/erc-4626-security-considerations/)
- [Smart Contract Security Best Practices](https://consensys.github.io/smart-contract-best-practices/)

### Tools Used
- [Foundry](https://book.getfoundry.sh/)
- [Forge Testing](https://book.getfoundry.sh/forge/tests)
- [Solidity](https://docs.soliditylang.org/)

## 💡 Tips for Success

1. **Read before coding**: Understand the math before implementing
2. **Test frequently**: Run tests after each function
3. **Use QUICKREF**: Keep it open while coding
4. **Compare with solution**: When stuck, check the solution's approach
5. **Understand, don't copy**: Type out the solution to learn
6. **Ask "why"**: For each rounding, ask why that direction
7. **Break things**: Try to attack your own implementation

## 🤝 Contributing

Found an issue or have an improvement?
- Check all test cases pass
- Ensure code is well-commented
- Follow the project's style
- Add tests for new features

## 📄 License

MIT License - Educational purposes

## 🙏 Acknowledgments

This project is inspired by:
- EIP-4626 authors
- OpenZeppelin's implementation
- Solmate's gas-optimized version
- Real-world vault security issues

## 📞 Support

Stuck on something?
1. Re-read the relevant documentation section
2. Check the solution's comments
3. Run tests with `-vvvv` for full traces
4. Review TUTORIAL.md step-by-step guide
5. Study ATTACKS.md for security insights

---

**Happy learning! Build secure vaults and master DeFi mathematics! 🏦📐🔒**
