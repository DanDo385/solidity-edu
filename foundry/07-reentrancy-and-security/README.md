# Project 07: Reentrancy & Security 🛡️

> **Master the most critical security pattern in Solidity**

## 🎯 Learning Objectives

By completing this project, you will:

1. **Understand reentrancy attacks** and how they work
2. **Reproduce the classic attack** ($60M The DAO hack)
3. **Apply Checks-Effects-Interactions pattern** correctly
4. **Use OpenZeppelin ReentrancyGuard** modifier
5. **Recognize cross-function reentrancy** vulnerabilities
6. **Understand gas limits** and DoS vectors
7. **Master secure ETH transfer** patterns
8. **Create Foundry deployment scripts** from scratch
9. **Write comprehensive test suites** demonstrating attacks and fixes

## 📁 Project Directory Structure

```
07-reentrancy-and-security/
├── README.md                          # This file
├── foundry.toml                       # Foundry configuration
├── src/
│   ├── ReentrancySecurity.sol        # Skeleton contract (TODO: implement)
│   └── solution/
│       └── ReentrancySecuritySolution.sol  # Complete reference implementation
├── script/
│   ├── DeployReentrancySecurity.s.sol # Deployment script (TODO: implement)
│   └── solution/
│       └── DeployReentrancySecuritySolution.s.sol  # Reference deployment
└── test/
    ├── ReentrancySecurity.t.sol        # Test suite (TODO: implement)
    └── solution/
        └── ReentrancySecuritySolution.t.sol  # Reference tests
```

## 🔑 Key Concepts

### The Reentrancy Attack

A reentrancy attack occurs when a malicious contract calls back into the original contract before the first call completes, exploiting state that hasn't been updated yet.

**The Vulnerability:**
```solidity
// ❌ VULNERABLE
function withdraw(uint256 amount) public {
    require(balances[msg.sender] >= amount);  // Check
    msg.sender.call{value: amount}("");       // Interaction FIRST!
    balances[msg.sender] -= amount;           // Effect TOO LATE!
}
```

**Attack Flow:**
1. Attacker calls `withdraw(100)`
2. Contract sends 100 ETH to attacker
3. Attacker's `receive()` function calls `withdraw(100)` again
4. Balance still shows 100 (not updated yet!)
5. Contract sends another 100 ETH
6. Attacker drains contract! 💥

### Checks-Effects-Interactions Pattern

The CEI pattern is THE fundamental security pattern for Solidity:

```solidity
// ✅ SECURE: Checks-Effects-Interactions
function withdraw(uint256 amount) public {
    require(balances[msg.sender] >= amount);  // 1. CHECKS
    balances[msg.sender] -= amount;           // 2. EFFECTS (first!)
    msg.sender.call{value: amount}("");       // 3. INTERACTIONS (last)
}
```

**Why This Order Matters:**
- **Checks**: Validate conditions first (fail early, save gas)
- **Effects**: Update state second (prevents reentrancy)
- **Interactions**: External calls last (safe because state already updated)

**Real-world analogy**: Like a bank teller - they check your ID (checks), update your account balance (effects), THEN give you cash (interactions).

### OpenZeppelin ReentrancyGuard

For complex contracts, use OpenZeppelin's ReentrancyGuard:

```solidity
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SecureContract is ReentrancyGuard {
    function withdraw() public nonReentrant {
        // Protected by ReentrancyGuard
    }
}
```

**How it works:**
- Uses aReentrancyGuard` modifier
- Sets a flag before function execution
- Clears flag after function completes
- Reverts if re-entered while flag is set

### Cross-Function Reentrancy

Reentrancy can occur across different functions:

```solidity
// ❌ VULNERABLE: Cross-function reentrancy
function withdraw() public {
    balances[msg.sender] -= amount;
    msg.sender.call{value: amount}("");
}

function transfer(address to, uint256 amount) public {
    balances[msg.sender] -= amount;
    balances[to] += amount;  // Attacker can call this from receive()!
}
```

**Mitigation:**
- Use ReentrancyGuard on all state-changing functions
- Or ensure all functions follow CEI pattern

## 🏗️ What You'll Build

A secure banking contract that demonstrates:

1. **Vulnerable implementation** (for learning)
2. **Secure implementation** using CEI pattern
3. **ReentrancyGuard** usage
4. **Attack demonstration** in tests

## 📋 Tasks

### 1. Implement Vulnerable Contract
- Create `withdrawVulnerable()` function
- Make external call BEFORE state update
- Demonstrate the vulnerability

### 2. Implement Secure Contract
- Create `withdrawSecure()` function
- Apply Checks-Effects-Interactions pattern
- Update state BEFORE external call

### 3. Implement ReentrancyGuard Version
- Use OpenZeppelin ReentrancyGuard
- Apply `nonReentrant` modifier
- Compare with CEI pattern

### 4. Write Attack Contract
- Create malicious contract with `receive()` function
- Attempt reentrancy attack on vulnerable contract
- Verify attack succeeds on vulnerable, fails on secure

### 5. Write Deployment Script
- Deploy all three contracts
- Log deployment addresses
- Verify deployments

### 6. Write Comprehensive Tests
- Test vulnerable contract (attack succeeds)
- Test secure contract (attack fails)
- Test ReentrancyGuard version
- Compare gas costs

## 🧪 Test Coverage

Your tests should verify:

- ✅ Vulnerable contract can be drained
- ✅ Secure contract prevents reentrancy
- ✅ ReentrancyGuard prevents reentrancy
- ✅ CEI pattern works correctly
- ✅ Attack fails on secure implementations
- ✅ Gas costs are reasonable

## 🎓 Real-World Analogies & Fun Facts

### Bank Teller Analogy
- **Vulnerable**: Give cash first, update account later (can withdraw multiple times!)
- **Secure**: Update account first, give cash later (can't withdraw twice)

### The DAO Hack ($60M)
- One of the largest hacks in crypto history
- Caused Ethereum hard fork (ETH vs ETC split)
- Led to creation of ReentrancyGuard pattern

### Fun Facts
- Reentrancy attacks are still common in DeFi
- CEI pattern is used in ALL secure contracts
- OpenZeppelin ReentrancyGuard adds ~2,300 gas overhead
- Cross-function reentrancy is harder to detect

## ✅ Completion Checklist

- [ ] Implement vulnerable withdraw function
- [ ] Implement secure withdraw function (CEI pattern)
- [ ] Implement ReentrancyGuard version
- [ ] Write attack contract
- [ ] Write deployment script
- [ ] Write comprehensive test suite
- [ ] Verify attack succeeds on vulnerable contract
- [ ] Verify attack fails on secure contracts
- [ ] Review solution implementation
- [ ] Understand CEI pattern deeply

## 💡 Pro Tips

1. **Always use CEI pattern**: For any function that modifies state and makes external calls
2. **Use ReentrancyGuard**: For complex contracts with multiple state-changing functions
3. **Test attacks**: Always test that attacks fail on secure implementations
4. **Understand gas limits**: Reentrancy can cause DoS if gas limit exceeded
5. **Review external calls**: Every external call is a potential reentrancy vector
6. **Use .call{value:}()**: Not .transfer() or .send() (Project 02!)

## 🚀 Next Steps

After completing this project:

- Move to [Project 08: ERC20 from Scratch](../08-ERC20-from-scratch/)
- Study real-world reentrancy attacks
- Explore cross-function reentrancy patterns
- Learn about flash loan attacks
