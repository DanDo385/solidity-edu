# 👋 Welcome to Project 44: Inflation Attack Demo

## 🚀 Quick Start in 3 Steps

### 1. Read the Guide
```bash
cat README.md
```
This explains what inflation attacks are and how they work.

### 2. Install & Build
```bash
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge install foundry-rs/forge-std --no-commit
forge build
```

### 3. Run Tests
```bash
forge test --match-test test_InflationAttack_Success -vvv
```
Watch the attack happen in real-time!

---

## 📚 What to Read First

**Complete Beginner?**
1. README.md - Understand the concepts
2. Run the tests to see it in action
3. Study QUICK_REFERENCE.md for summary

**Want to Code?**
1. Open src/Project44.sol
2. Try filling in the TODOs
3. Compare with src/solution/Project44Solution.sol

**Just Need Reference?**
- QUICK_REFERENCE.md - Fast lookup
- INDEX.md - Navigate all files

---

## 🎯 What You'll Learn

- ✅ How ERC-4626 inflation attacks work
- ✅ Why share price manipulation is dangerous
- ✅ Three different mitigation strategies
- ✅ How to implement secure vaults
- ✅ Economic analysis of attacks

---

## 📁 Key Files

| File | Purpose |
|------|---------|
| **README.md** | Complete guide (start here!) |
| **src/Project44.sol** | Skeleton with TODOs |
| **src/solution/Project44Solution.sol** | Complete solution |
| **test/Project44.t.sol** | 14 comprehensive tests |
| **QUICK_REFERENCE.md** | Quick lookup guide |

---

## ⚡ Quick Commands

```bash
# See attack succeed
forge test --match-test test_InflationAttack_Success -vvv

# See mitigations work
forge test --match-test test_VirtualShares_PreventsAttack -vv
forge test --match-test test_MinDeposit_PreventsAttack -vv
forge test --match-test test_DeadShares_PreventsAttack -vv

# Compare all mitigations
forge test --match-test test_CompareMitigations -vv

# Run everything
forge test -vv
```

---

## 🎓 Learning Path

**Hour 1**: Read README.md, understand the attack
**Hour 2**: Run tests, see attack in action  
**Hour 3**: Study vulnerable vault code
**Hour 4**: Study mitigation strategies
**Hour 5**: Implement TODOs yourself
**Hour 6**: Compare with solution

---

## ⚠️ Important

This project contains **intentionally vulnerable code** for educational purposes.

**NEVER** use `VulnerableVault` in production!

**ALWAYS** use one of the protected implementations or OpenZeppelin's ERC4626.

---

## 🎉 Ready?

Start with:
```bash
cat README.md | less
```

Then:
```bash
forge test --match-test test_InflationAttack_Success -vvv
```

Happy learning! 🔒
