# Security Guide - DeFi Protocol Capstone

## Overview

This document outlines security considerations, common vulnerabilities, and best practices for the DeFi Protocol. Security is paramount in DeFi - a single vulnerability can lead to loss of user funds.

---

## Security Architecture

### Defense in Depth

Our protocol uses multiple layers of security:

```
Layer 1: Smart Contract Security
├── Reentrancy guards
├── Access control
├── Input validation
└── Safe math operations

Layer 2: Economic Security
├── Fee limits
├── Rate limiting
├── Oracle manipulation resistance
└── Flash loan protections

Layer 3: Governance Security
├── Timelock delays
├── Multi-sig controls
├── Proposal thresholds
└── Emergency pause

Layer 4: Operational Security
├── Monitoring & alerts
├── Incident response
├── Upgrade procedures
└── Bug bounty program
```

---

## Common Vulnerabilities & Mitigations

### 1. Reentrancy Attacks

**What it is:**
When an external contract calls back into your contract before the first invocation completes, potentially allowing repeated withdrawals or state manipulation.

**Example Vulnerable Code:**
```solidity
// ❌ VULNERABLE
function withdraw(uint256 amount) external {
    require(balances[msg.sender] >= amount);

    // External call before state update
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success);

    balances[msg.sender] -= amount; // Too late!
}
```

**Fixed Code:**
```solidity
// ✅ SECURE
function withdraw(uint256 amount) external nonReentrant {
    require(balances[msg.sender] >= amount);

    // State update BEFORE external call
    balances[msg.sender] -= amount;

    (bool success, ) = msg.sender.call{value: amount}("");
    require(success);
}
```

**Our Implementation:**
- ✅ All state-changing functions use `nonReentrant` modifier
- ✅ Checks-Effects-Interactions pattern followed
- ✅ OpenZeppelin ReentrancyGuard used

### 2. Flash Loan Attacks

**What it is:**
Attackers borrow large amounts without collateral to manipulate markets, oracles, or protocol state within a single transaction.

**Attack Vectors:**
- Oracle price manipulation
- Vault share inflation
- Governance vote manipulation
- Liquidity pool imbalance

**Mitigations:**
```solidity
// ✅ Use TWAP (Time-Weighted Average Price)
function getPrice() external view returns (uint256) {
    // Multiple block average, not single block
    return oracle.getTWAP(token, 1800); // 30 min average
}

// ✅ Limit flash loan amounts
function maxFlashLoan(address token) external view returns (uint256) {
    uint256 available = IERC20(token).balanceOf(address(this));
    return (available * FLASH_LOAN_LIMIT_PERCENTAGE) / BASIS_POINTS;
}

// ✅ Add deposit/withdrawal delays
mapping(address => uint256) public lastDepositBlock;

function deposit(uint256 amount) external {
    lastDepositBlock[msg.sender] = block.number;
    // ... deposit logic
}

function withdraw(uint256 amount) external {
    require(
        block.number > lastDepositBlock[msg.sender] + MIN_DELAY,
        "Too soon after deposit"
    );
    // ... withdraw logic
}
```

**Our Implementation:**
- ✅ Flash loan amount limited to 80% of vault
- ✅ Multi-block oracle averaging
- ✅ Proper fee collection
- ✅ Balance verification after loan

### 3. First Depositor Attack (Vault Inflation)

**What it is:**
First depositor deposits 1 wei, then donates large amount to inflate share price, causing rounding issues for subsequent depositors.

**Attack Flow:**
```
1. Attacker deposits 1 wei → Gets 1 share
2. Attacker donates 1000 ETH to vault
3. Share price = 1000 ETH per share
4. Victim deposits 1999 ETH
5. Victim gets 1 share (rounds down from 1.999)
6. Attacker withdraws: gets ~999.5 ETH
7. Attacker profit: 999.5 ETH from victim
```

**Mitigation:**
```solidity
// ✅ Option 1: Minimum shares on first deposit
function _deposit(uint256 assets, address receiver) internal {
    uint256 shares = previewDeposit(assets);

    if (totalSupply() == 0) {
        require(shares >= MIN_SHARES, "First deposit too small");
    }

    _mint(receiver, shares);
}

// ✅ Option 2: Virtual shares/assets
uint256 constant VIRTUAL_SHARES = 1e3;
uint256 constant VIRTUAL_ASSETS = 1e3;

function convertToShares(uint256 assets) public view returns (uint256) {
    uint256 supply = totalSupply() + VIRTUAL_SHARES;
    uint256 totalAssets = totalAssets() + VIRTUAL_ASSETS;
    return (assets * supply) / totalAssets;
}
```

**Our Implementation:**
- ✅ Uses ERC4626 standard with proper rounding
- ✅ Add virtual shares on first deposit (if needed)
- ✅ Monitor for suspicious donation patterns

### 4. Oracle Manipulation

**What it is:**
Attackers manipulate price feeds to exploit protocol mechanics, often via flash loans.

**Vulnerable Oracle:**
```solidity
// ❌ VULNERABLE - Uses spot price
function getPrice() external view returns (uint256) {
    (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
    return (reserve1 * 1e18) / reserve0;
}
```

**Secure Oracle:**
```solidity
// ✅ SECURE - Multiple sources with staleness check
function getPrice(address asset) external view returns (uint256) {
    PriceFeed memory feed = priceFeeds[asset];
    require(feed.isActive, "Inactive feed");

    (, int256 price, , uint256 updatedAt, ) =
        IPriceFeed(feed.source).latestRoundData();

    require(price > 0, "Invalid price");
    require(block.timestamp - updatedAt <= feed.heartbeat, "Stale price");

    // Validate against backup oracle
    if (hasBackup(asset)) {
        uint256 backupPrice = getBackupPrice(asset);
        uint256 deviation = calculateDeviation(uint256(price), backupPrice);
        require(deviation <= MAX_DEVIATION, "Price deviation too high");
    }

    return uint256(price);
}
```

**Our Implementation:**
- ✅ Chainlink price feeds (primary)
- ✅ TWAP fallback mechanism
- ✅ Staleness checks (max 1 hour)
- ✅ Price deviation limits (±10%)
- ✅ Circuit breaker on anomalies

### 5. Integer Overflow/Underflow

**What it is:**
Arithmetic operations that exceed type boundaries, wrapping around to unexpected values.

**Note:** Solidity 0.8.0+ has built-in overflow/underflow checks, but `unchecked` blocks bypass this.

**Vulnerable Code:**
```solidity
// ❌ VULNERABLE in Solidity < 0.8.0
function badMath(uint256 a, uint256 b) public pure returns (uint256) {
    return a + b; // Could overflow
}

// ❌ VULNERABLE even in 0.8.0+
function stillVulnerable(uint256 a, uint256 b) public pure returns (uint256) {
    unchecked {
        return a + b; // Could overflow
    }
}
```

**Safe Code:**
```solidity
// ✅ SECURE - Compiler checks in 0.8.0+
function safeMath(uint256 a, uint256 b) public pure returns (uint256) {
    return a + b; // Reverts on overflow
}

// ✅ SECURE - Only use unchecked when provably safe
function safeUnchecked(uint256 i) public pure returns (uint256) {
    unchecked {
        return i + 1; // Safe if i < type(uint256).max
    }
}
```

**Our Implementation:**
- ✅ Solidity 0.8.20 (built-in checks)
- ✅ `unchecked` only where provably safe
- ✅ SafeMath patterns for complex math

### 6. Access Control Issues

**What it is:**
Functions that should be restricted are accessible to anyone, or roles are improperly configured.

**Vulnerable Code:**
```solidity
// ❌ VULNERABLE - No access control
function withdraw() external {
    payable(msg.sender).transfer(address(this).balance);
}

// ❌ VULNERABLE - Improper modifier
modifier onlyAdmin() {
    require(msg.sender == admin);
    _; // Missing return/revert on failure
}
```

**Secure Code:**
```solidity
// ✅ SECURE - Proper access control
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SecureContract is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    function sensitiveFunction() external onlyRole(ADMIN_ROLE) {
        // Only admins can call
    }
}
```

**Our Implementation:**
- ✅ OpenZeppelin AccessControl for all contracts
- ✅ Role-based permissions (ADMIN, PAUSER, MINTER, etc.)
- ✅ Multi-sig for critical operations
- ✅ Timelock for governance changes

### 7. Frontrunning / MEV

**What it is:**
Miners or bots see pending transactions and place their own transactions with higher gas to execute first.

**Attack Scenarios:**
- Frontrun large trades
- Sandwich attacks (frontrun + backrun)
- Oracle update frontrunning
- Governance vote frontrunning

**Mitigations:**
```solidity
// ✅ Use commit-reveal for sensitive operations
mapping(address => bytes32) public commits;

function commit(bytes32 hash) external {
    commits[msg.sender] = hash;
}

function reveal(uint256 amount, bytes32 salt) external {
    require(
        commits[msg.sender] == keccak256(abi.encode(amount, salt)),
        "Invalid reveal"
    );
    // Execute with revealed amount
}

// ✅ Add minimum/maximum slippage protection
function swap(
    uint256 amountIn,
    uint256 minAmountOut
) external {
    uint256 amountOut = calculateSwap(amountIn);
    require(amountOut >= minAmountOut, "Slippage too high");
    // ... execute swap
}
```

**Our Implementation:**
- ✅ Timelock delays for governance
- ✅ TWAP oracles resist manipulation
- ✅ Slippage protection on swaps
- ✅ MEV-resistant design patterns

### 8. Denial of Service (DoS)

**What it is:**
Attackers make the contract unusable, either by consuming all gas or blocking critical operations.

**Vulnerable Patterns:**
```solidity
// ❌ VULNERABLE - Unbounded loop
function distributeRewards(address[] memory users) external {
    for (uint256 i = 0; i < users.length; i++) {
        // Could run out of gas
        payable(users[i]).transfer(rewards[users[i]]);
    }
}

// ❌ VULNERABLE - External call in loop
function processAll(address[] memory contracts) external {
    for (uint256 i = 0; i < contracts.length; i++) {
        // One failure blocks all
        IContract(contracts[i]).process();
    }
}
```

**Secure Patterns:**
```solidity
// ✅ SECURE - Pull over push
mapping(address => uint256) public claimableRewards;

function claim() external {
    uint256 amount = claimableRewards[msg.sender];
    claimableRewards[msg.sender] = 0;
    payable(msg.sender).transfer(amount);
}

// ✅ SECURE - Batch with limits
function processBatch(
    address[] memory contracts,
    uint256 startIndex,
    uint256 count
) external {
    require(count <= MAX_BATCH_SIZE, "Batch too large");
    for (uint256 i = 0; i < count; i++) {
        // Process with bounds
    }
}
```

**Our Implementation:**
- ✅ Pull payment pattern
- ✅ Batch operations with limits
- ✅ Gas limits on external calls
- ✅ Emergency pause functionality

### 9. Timestamp Manipulation

**What it is:**
Miners have some control over `block.timestamp` (±15 seconds), which can be exploited in time-sensitive operations.

**Vulnerable Code:**
```solidity
// ❌ VULNERABLE to 15-second manipulation
function claimReward() external {
    require(block.timestamp >= nextClaimTime[msg.sender], "Too early");
    // Miner could manipulate timestamp
}

// ❌ VULNERABLE - Using timestamp as randomness
function random() external view returns (uint256) {
    return uint256(keccak256(abi.encode(block.timestamp)));
}
```

**Secure Code:**
```solidity
// ✅ SECURE - Use block.number for precision
function claimReward() external {
    require(block.number >= nextClaimBlock[msg.sender], "Too early");
    // Block manipulation much harder
}

// ✅ SECURE - Use VRF for randomness
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

function requestRandomness() external {
    requestId = requestRandomness(keyHash, fee);
}
```

**Our Implementation:**
- ✅ `block.number` for short delays
- ✅ `block.timestamp` only for long periods (>15 min)
- ✅ Never use timestamp as randomness
- ✅ Chainlink VRF for random numbers (if needed)

### 10. Unchecked External Calls

**What it is:**
External calls can fail silently if return values aren't checked.

**Vulnerable Code:**
```solidity
// ❌ VULNERABLE - Ignores return value
function withdraw() external {
    token.transfer(msg.sender, amount);
    // If transfer fails, state still updated!
}

// ❌ VULNERABLE - Low-level call not checked
function execute(address target, bytes memory data) external {
    target.call(data); // Ignores success
}
```

**Secure Code:**
```solidity
// ✅ SECURE - Check return value
function withdraw() external {
    bool success = token.transfer(msg.sender, amount);
    require(success, "Transfer failed");
}

// ✅ SECURE - Use SafeERC20
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

using SafeERC20 for IERC20;

function withdraw() external {
    token.safeTransfer(msg.sender, amount);
}

// ✅ SECURE - Check low-level call
function execute(address target, bytes memory data) external {
    (bool success, ) = target.call(data);
    require(success, "Call failed");
}
```

**Our Implementation:**
- ✅ SafeERC20 for all token operations
- ✅ All external calls checked
- ✅ Proper error handling

---

## Audit Checklist

### Pre-Audit Preparation

- [ ] Complete test coverage (>95%)
- [ ] All tests passing
- [ ] Documentation complete
- [ ] Code comments clear
- [ ] NatSpec on all public functions
- [ ] Remove all TODOs
- [ ] Remove debug code
- [ ] Gas optimizations complete
- [ ] Slither analysis clean
- [ ] Mythril scan clean

### External Audit Questions

**Provide to auditors:**

1. **Architecture Documentation**
   - System design diagrams
   - Contract interaction flows
   - State transition diagrams
   - Economic model documentation

2. **Known Issues**
   - Any acknowledged risks
   - Trade-offs made
   - Areas of concern
   - Assumptions made

3. **Test Results**
   - Coverage report
   - Gas benchmarks
   - Fuzzing results
   - Invariant test results

4. **Dependencies**
   - All external contracts
   - Oracle dependencies
   - Library versions
   - Upgrade mechanisms

### Post-Audit Actions

- [ ] Review all findings
- [ ] Categorize by severity
- [ ] Fix critical/high issues
- [ ] Document medium/low issues
- [ ] Re-test after fixes
- [ ] Get auditor sign-off
- [ ] Publish audit report
- [ ] Implement monitoring

---

## Incident Response Plan

### Detection

**Monitoring Setup:**
```
- 24/7 contract monitoring
- Alert on unusual transactions
- Oracle deviation alerts
- TVL change alerts
- Governance activity alerts
```

### Response Levels

#### Level 1: Minor Issue
- Response time: 24 hours
- Example: UI bug, minor inefficiency
- Action: Schedule fix in next update

#### Level 2: Medium Issue
- Response time: 4 hours
- Example: Unexpected behavior, potential exploit
- Action: Investigate, prepare fix, monitor closely

#### Level 3: Critical Issue
- Response time: Immediate
- Example: Active exploit, funds at risk
- Action: **Execute emergency response**

### Emergency Response Procedure

```
1. PAUSE ⏸️
   - Immediately pause affected contracts
   - Multi-sig executes pause

2. ASSESS 🔍
   - Identify root cause
   - Determine scope of impact
   - Estimate funds at risk

3. COMMUNICATE 📢
   - Alert users via Twitter/Discord
   - Update status page
   - Contact affected users

4. MITIGATE 🛠️
   - Deploy fix (if simple)
   - Upgrade contracts (if needed)
   - Reimburse affected users

5. RESUME ▶️
   - Verify fix works
   - Re-enable contracts
   - Monitor closely

6. POST-MORTEM 📝
   - Write incident report
   - Update security measures
   - Implement preventions
```

### Communication Template

```
🚨 SECURITY ALERT 🚨

Status: [INVESTIGATING | MITIGATED | RESOLVED]

Issue: [Brief description]

Impact: [Affected components, user funds status]

Actions Taken:
- [Timestamp] Contracts paused
- [Timestamp] Issue identified
- [Timestamp] Fix deployed

User Action Required: [None | Withdraw | Wait]

Updates: [Link to status page]

Contact: security@protocol.xyz
```

---

## Security Tools & Resources

### Static Analysis

**Slither:**
```bash
slither . --exclude-optimization --exclude-informational
```

**Mythril:**
```bash
myth analyze src/Project50.sol
```

**Aderyn:**
```bash
aderyn .
```

### Testing Tools

**Foundry:**
```bash
forge test
forge coverage
forge snapshot
```

**Echidna (Fuzzing):**
```bash
echidna-test . --contract Project50 --config echidna.yaml
```

### Monitoring

- **Tenderly**: Transaction monitoring & alerts
- **OpenZeppelin Defender**: Automated security operations
- **Forta**: Real-time threat detection

### Audit Firms

- Trail of Bits
- OpenZeppelin
- ConsenSys Diligence
- Certora
- Quantstamp

---

## Best Practices Summary

### Development

✅ **DO:**
- Use latest stable Solidity version
- Follow checks-effects-interactions
- Use OpenZeppelin libraries
- Document all functions
- Write comprehensive tests
- Run static analysis tools
- Get external audits

❌ **DON'T:**
- Use `tx.origin` for authentication
- Use `block.timestamp` as randomness
- Ignore return values
- Use `delegatecall` carelessly
- Deploy without testing
- Skip access controls

### Testing

✅ **DO:**
- Test edge cases
- Test attack scenarios
- Use fuzzing
- Test invariants
- Test with mainnet forks
- Gas benchmark

❌ **DON'T:**
- Only test happy paths
- Ignore coverage gaps
- Skip integration tests
- Trust without verification

### Deployment

✅ **DO:**
- Deploy to testnet first
- Use multi-sig for admin
- Implement timelock
- Set up monitoring
- Have pause mechanism
- Prepare incident response

❌ **DON'T:**
- Deploy to mainnet first
- Use EOA for admin
- Skip gradual rollout
- Deploy and forget

---

## Additional Resources

- [Smart Contract Security Best Practices](https://consensys.github.io/smart-contract-best-practices/)
- [SWC Registry](https://swcregistry.io/) - Smart Contract Weakness Classification
- [Rekt News](https://rekt.news/) - Learn from past exploits
- [Secureum](https://secureum.substack.com/) - Security newsletter
- [OpenZeppelin Security](https://blog.openzeppelin.com/security-audits/)

---

**Remember: Security is not a checkbox—it's an ongoing process. Stay vigilant! 🛡️**
