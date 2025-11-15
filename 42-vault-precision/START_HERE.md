# 🏦 Project 42: ERC-4626 Precision & Rounding

## 🎯 Welcome!

This is a comprehensive educational project about **vault mathematics** and **precision security** in DeFi.

You'll learn why a single wrong rounding decision can lead to **vault insolvency** or **user fund loss**.

## 🚀 Quick Start (Choose Your Path)

### Path A: I want to code immediately (3 hours)
```bash
1. Read README.md sections 1-3
2. Read TUTORIAL.md
3. Open src/Project42.sol
4. Implement the TODOs
5. Run: make test
```

### Path B: I want deep understanding (6 hours)
```bash
1. Read README.md (all)
2. Read TUTORIAL.md
3. Read MATH.md
4. Read ATTACKS.md
5. Implement src/Project42.sol
6. Run: make test-v
```

### Path C: I'm here for security (4 hours)
```bash
1. Read README.md (security sections)
2. Read ATTACKS.md
3. Study src/solution/Project42Solution.sol
4. Implement with security mindset
5. Run: make test-attacks
```

## 📚 Documentation Map

| File | Purpose | Read Time |
|------|---------|-----------|
| **README.md** | Concepts, theory, why it matters | 30 min |
| **TUTORIAL.md** | Step-by-step implementation guide | 45 min |
| **QUICKREF.md** | Quick lookup while coding | 5 min |
| **MATH.md** | Proofs and theory | 60 min |
| **ATTACKS.md** | Security deep dive | 45 min |
| **SETUP.md** | Installation guide | 10 min |
| **PROJECT_INDEX.md** | Complete navigation | 10 min |

## 🎓 What You'll Learn

### Core Concept
**Rounding direction determines vault security**

One wrong rounding = potential exploit

### Skills Gained
- ✅ Implement mathematically sound vault operations
- ✅ Understand ERC-4626 standard deeply
- ✅ Prevent precision-based attacks
- ✅ Write proofs for contract invariants
- ✅ Test DeFi protocols comprehensively

### Security Knowledge
- ✅ Share inflation attacks
- ✅ Precision drain vulnerabilities  
- ✅ Reentrancy in vaults
- ✅ Flash loan manipulation
- ✅ Mitigation strategies

## 🔑 The Golden Rule

**ALWAYS ROUND IN VAULT'S FAVOR**

| Operation | User Gives | User Gets | Round |
|-----------|-----------|-----------|-------|
| Deposit   | Assets    | Shares    | DOWN ⬇️ |
| Mint      | Assets    | Shares    | UP ⬆️   |
| Withdraw  | Shares    | Assets    | UP ⬆️   |
| Redeem    | Shares    | Assets    | DOWN ⬇️ |

## 📁 Project Structure

```
42-vault-precision/
│
├── 📖 Documentation (8 files, ~3200 lines)
│   ├── START_HERE.md        ← You are here
│   ├── README.md             ← Start learning here
│   ├── TUTORIAL.md           ← Implementation guide
│   ├── QUICKREF.md           ← Quick reference
│   ├── MATH.md               ← Mathematical proofs
│   ├── ATTACKS.md            ← Security analysis
│   ├── SETUP.md              ← Installation
│   └── PROJECT_INDEX.md      ← Complete index
│
├── 💻 Code (3 files, ~1600 lines)
│   ├── src/Project42.sol              ← Your implementation (TODOs)
│   ├── src/solution/Project42Solution.sol  ← Reference solution
│   └── test/Project42.t.sol           ← Comprehensive tests
│
├── 🚀 Infrastructure
│   ├── script/DeployProject42.s.sol   ← Deployment
│   ├── Makefile                       ← Commands
│   └── foundry.toml                   ← Config
│
└── 📊 Stats: 4900+ lines, 30+ tests, 6 attack scenarios
```

## 🧪 Testing Commands

```bash
make test              # Run all tests
make test-rounding     # Test rounding direction
make test-preview      # Test preview functions
make test-edge         # Test edge cases
make test-attacks      # Test attack prevention
make test-invariants   # Test mathematical invariants
make test-v            # Verbose output
make test-vv           # Very verbose output
make coverage          # Coverage report
```

## 🎯 Success Criteria

You've mastered this project when you can:

1. ✅ Explain why deposit rounds DOWN but mint rounds UP
2. ✅ Implement all preview functions with correct rounding
3. ✅ Describe the share inflation attack
4. ✅ Prove vault value never decreases
5. ✅ Pass all 30+ tests

## ⚡ Key Insights You'll Discover

1. **Precision Loss is Intentional**
   - Each operation "loses" up to 1 wei
   - This loss protects the vault
   - Accumulates in vault's favor

2. **Preview Must Match Action**
   - Users rely on previews for slippage
   - Mismatch breaks composability
   - Same rounding direction required

3. **First Deposit is Critical**
   - Can set arbitrary exchange rate
   - Opens inflation attack vector
   - Needs special protection

4. **Vault Invariants**
   - Value never decreases from user ops
   - User can't profit from round-trips
   - Total value is conserved

## 🚨 Common Pitfalls (Avoid These!)

```solidity
// ❌ WRONG: Deposit rounds UP
shares = mulDivUp(assets, totalSupply(), totalAssets());

// ✅ RIGHT: Deposit rounds DOWN
shares = mulDiv(assets, totalSupply(), totalAssets());

// ❌ WRONG: Preview doesn't match withdraw
function previewWithdraw(uint256 assets) returns (uint256) {
    return convertToShares(assets);  // Rounds DOWN
}

// ✅ RIGHT: Preview matches withdraw
function previewWithdraw(uint256 assets) returns (uint256) {
    return mulDivUp(assets, totalSupply(), totalAssets());  // Rounds UP
}
```

## 📖 Recommended Reading Order

### Beginner Path
1. START_HERE.md (this file)
2. README.md (sections 1-4)
3. TUTORIAL.md
4. Start coding!

### Intermediate Path
1. All beginner materials
2. MATH.md (proofs)
3. ATTACKS.md (security)
4. Implement with understanding

### Advanced Path
1. All materials
2. Study solution code
3. Implement from scratch
4. Write additional tests
5. Try to break it!

## 🔗 External Resources

- [EIP-4626 Standard](https://eips.ethereum.org/EIPS/eip-4626)
- [OpenZeppelin Implementation](https://docs.openzeppelin.com/contracts/4.x/erc4626)
- [Trail of Bits Security Analysis](https://blog.trailofbits.com/2022/04/18/erc-4626-security-considerations/)
- [Foundry Book](https://book.getfoundry.sh/)

## ⏱️ Time Investment

| Activity | Time | Value |
|----------|------|-------|
| Quick implementation | 2-3h | ⭐⭐⭐ |
| Deep understanding | 4-6h | ⭐⭐⭐⭐⭐ |
| Security mastery | 6-8h | ⭐⭐⭐⭐⭐ |
| Complete expertise | 8-10h | ⭐⭐⭐⭐⭐ |

## 🎬 Next Steps

Choose your starting point:

**I want to code RIGHT NOW:**
→ Open `TUTORIAL.md` and `src/Project42.sol`

**I want to understand the WHY:**
→ Open `README.md`

**I need quick reference:**
→ Open `QUICKREF.md`

**I want the full picture:**
→ Open `PROJECT_INDEX.md`

**I'm focused on security:**
→ Open `ATTACKS.md`

---

## 💬 Final Words

DeFi security often comes down to **getting the math right**.

A single incorrect rounding can cost millions of dollars in exploits.

This project teaches you to think like both:
- **A developer** (implement correctly)
- **An attacker** (find vulnerabilities)
- **An auditor** (prove security properties)

**Master this, and you'll understand DeFi vaults better than 95% of developers.**

---

**Ready to begin?** Choose your path above and start learning! 🚀

**Questions?** Check PROJECT_INDEX.md for complete navigation.

**Stuck?** Read SETUP.md for installation help.

---

**Build secure vaults. Master DeFi mathematics. 🏦📐🔒**
