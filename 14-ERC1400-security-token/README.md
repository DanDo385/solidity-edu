# Project 14: ERC-1400 Security Tokens for RWAs 🏛️

> **Implement compliant security tokens for tokenizing real-world assets with regulatory features**

## 🎯 Learning Objectives

- Understand security token standards for RWAs
- Implement transfer restrictions and compliance
- Learn partition-based token management
- Handle investor whitelisting and KYC
- Study regulatory requirements for tokenized securities

## 📚 Background: Why ERC-1400?

ERC-1400 enables **regulated securities** on blockchain:

### Real-World Assets (RWAs)

Traditional assets being tokenized:
- 🏢 **Real Estate** - Properties, REITs
- 📈 **Equities** - Company shares, stock
- 💰 **Bonds** - Corporate, government debt
- 🎨 **Art & Collectibles** - Fractional ownership
- 🏭 **Commodities** - Gold, oil, agricultural products

### Regulatory Requirements

Securities need compliance features:

```solidity
// KYC/AML Verification
require(isVerified[investor], "Not KYC'd");

// Accredited Investor Checks
require(isAccredited[investor], "Not accredited");

// Transfer Restrictions
require(canTransfer(from, to, amount), "Transfer restricted");

// Lock-up Periods
require(block.timestamp > lockupEnd, "Tokens locked");

// Geographic Restrictions
require(!isRestricted[country[investor]], "Jurisdiction restricted");
```

## 🔧 Core Concepts

### Partitions (Tranches)

```solidity
// Different classes of securities
bytes32 constant COMMON_STOCK = bytes32("CommonStock");
bytes32 constant PREFERRED_STOCK = bytes32("PreferredStock");
bytes32 constant SERIES_A = bytes32("SeriesA");

// Each partition has separate balance
balanceOfByPartition[investor][COMMON_STOCK] = 1000;
balanceOfByPartition[investor][PREFERRED_STOCK] = 500;
```

### Transfer Restrictions

```solidity
// Check if transfer is allowed
function canTransfer(
    address from,
    address to,
    uint256 amount,
    bytes calldata data
) public view returns (bool, bytes32 reason);

// Possible restriction reasons:
// - Not KYC'd
// - Tokens locked
// - Exceeds ownership limit
// - Blacklisted address
// - Regulatory restriction
```

### Document Management

```solidity
// Legal documents on-chain
setDocument("Prospectus", "ipfs://...", bytes32("hash"));
setDocument("TermSheet", "ipfs://...", bytes32("hash"));
```

## 📝 Tasks

### Task 1: Implement the Contract

Open `src/ERC1400SecurityToken.sol` and implement:
1. **Partition management** - Different token classes
2. **Transfer restrictions** - Compliance checks
3. **Whitelist/KYC system** - Investor verification
4. **Document management** - Legal docs on-chain
5. **Controller functions** - Forced transfers for compliance

### Task 2: Run Tests

```bash
cd 14-ERC1400-security-token
forge test -vvv
forge test --match-test test_Compliance
forge test --match-test test_Partitions
```

## ⚠️ Regulatory Considerations

### Compliance Features

**KYC/AML:**
```solidity
mapping(address => bool) public isKYCd;
mapping(address => uint256) public kycExpiry;
```

**Accredited Investors:**
```solidity
mapping(address => bool) public isAccredited;
mapping(address => string) public jurisdiction;
```

**Transfer Limits:**
```solidity
uint256 public maxHoldingAmount;
uint256 public minHoldingAmount;
mapping(address => uint256) public transferLockup;
```

## 🌍 Real-World Examples

### Tokenized Real Estate

```solidity
// Property worth $1M divided into 1000 tokens
ERC1400 propertyToken = new ERC1400("123 Main St", "PROP123");

// Investors buy fractional ownership
propertyToken.issueByPartition(OWNERSHIP, investor, 10); // 1% ownership

// Rental income distributed proportionally
propertyToken.distributeD dividends(rentalIncome);
```

### Corporate Shares

```solidity
// Company issues different stock classes
issueByPartition(COMMON_STOCK, investor1, 10000);
issueByPartition(PREFERRED_STOCK, investor2, 5000);

// Preferred stock has different rights (voting, dividends)
```

### Bonds

```solidity
// Corporate bond with maturity date
ERC1400 bond = new ERC1400("Corp Bond 2025", "BOND25");

// Interest payments
bond.issueByPartition(INTEREST, bondholders, amount);

// Maturity redemption
bond.redeemByPartition(PRINCIPAL, bondholder, faceValue);
```

## ✅ Completion Checklist

- [ ] Implemented partition system
- [ ] Implemented transfer restrictions
- [ ] Implemented KYC/whitelist
- [ ] Implemented document management
- [ ] All compliance tests pass
- [ ] Understand regulatory requirements
- [ ] Can explain vs regular ERC-20 tokens

## 💡 Use Cases

**Advantages of Tokenization:**
- ✅ **Fractional Ownership** - Buy $100 of real estate
- ✅ **24/7 Trading** - No market hours
- ✅ **Global Access** - Permissionless (with compliance)
- ✅ **Instant Settlement** - T+0 instead of T+2
- ✅ **Programmable Compliance** - Automated restrictions
- ✅ **Lower Costs** - No intermediaries
- ✅ **Transparency** - On-chain audit trail

## 🚀 Next Steps

After completing this project:

- **Study platforms**: Polymath, Securitize, Harbor
- **Understand regulations**: SEC (US), MiFID II (EU), etc.
- **Integration**: Connect to compliance providers
- **Build**: Tokenize a real asset (with proper legal)

## 📖 Further Reading

- [EIP-1400 Specification](https://github.com/ethereum/eips/issues/1400)
- [Security Token Standards](https://thesecuritytokenstandard.org/)
- [Polymath Documentation](https://docs.polymath.network/)
- [SEC Digital Asset Framework](https://www.sec.gov/corpfin/framework-investment-contract-analysis-digital-assets)

---

**Congratulations!** You've completed all 14 Solidity mini-projects, from basics to cutting-edge security tokens! 🎓🚀
