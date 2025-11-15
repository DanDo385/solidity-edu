# Project 12: Safe ETH Transfer Library

## Overview

This project teaches you how to safely handle ETH transfers in smart contracts using **pull payment patterns** and **withdrawal queues**. You'll learn why "push payments" can be dangerous and how to implement secure alternatives.

## Learning Objectives

- Understand the difference between push and pull payment patterns
- Learn about DoS (Denial of Service) attack vectors in push payments
- Implement a secure withdrawal queue system
- Handle failed ETH transfers gracefully
- Understand EIP-1884 and gas stipend concerns
- Master safe ETH transfer mechanisms

---

## What Are Pull Payments?

### Push vs Pull Patterns

**Push Payment Pattern (Dangerous):**
```solidity
// BAD: Pushing payment to recipient
function distributeRewards(address[] memory recipients) public {
    for (uint i = 0; i < recipients.length; i++) {
        recipients[i].call{value: rewardAmount}("");
    }
}
```

**Pull Payment Pattern (Safe):**
```solidity
// GOOD: Let recipients withdraw their own funds
mapping(address => uint256) public pendingWithdrawals;

function withdraw() public {
    uint256 amount = pendingWithdrawals[msg.sender];
    pendingWithdrawals[msg.sender] = 0;
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed");
}
```

---

## Why Push Payments Are Dangerous

### 1. Denial of Service (DoS) Attack

An attacker can block the entire payment distribution by refusing to accept ETH:

```solidity
contract MaliciousRecipient {
    // This contract has no receive() or fallback()
    // Any ETH sent to it will fail
}

// If this recipient is in the list, the entire distributeRewards() fails
```

**Impact:**
- One malicious recipient can block payments to ALL users
- Contract functionality becomes frozen
- Gas is wasted on failed transactions

### 2. Unbounded Gas Consumption

```solidity
// What if recipients array has 1000 addresses?
function distributeRewards(address[] memory recipients) public {
    for (uint i = 0; i < recipients.length; i++) {
        // Each iteration costs gas
        // Total gas may exceed block gas limit!
        recipients[i].call{value: rewardAmount}("");
    }
}
```

**Problems:**
- Transaction may exceed block gas limit
- Unpredictable gas costs
- Can become impossible to execute as array grows

### 3. Reentrancy Vulnerabilities

```solidity
function distributeReward(address recipient) public {
    uint256 reward = calculateReward(recipient);
    // DANGER: External call before state update
    recipient.call{value: reward}("");
    // Attacker can re-enter here!
    hasReceivedReward[recipient] = true;
}
```

---

## EIP-1884 and Gas Stipends

### The 2300 Gas Stipend Problem

Prior to EIP-1884 (Istanbul hard fork), the common pattern was:

```solidity
recipient.transfer(amount);  // 2300 gas stipend
// or
recipient.send(amount);      // 2300 gas stipend
```

**EIP-1884 Changed Everything:**
- Increased gas cost of `SLOAD` from 200 to 800 gas
- The 2300 gas stipend is no longer sufficient for many operations
- Even a simple fallback function might fail

**Example of EIP-1884 Impact:**
```solidity
contract Recipient {
    uint256 private balance;

    receive() external payable {
        balance += msg.value;  // SLOAD (800) + SSTORE (20000)
        // This FAILS with 2300 gas stipend!
    }
}
```

### Modern Best Practice: Forward More Gas

```solidity
// BAD: Fixed 2300 gas
recipient.transfer(amount);

// GOOD: Forward sufficient gas (but not all gas)
(bool success, ) = recipient.call{value: amount}("");
require(success, "Transfer failed");
```

---

## Storage Diagrams for Withdrawal Queues

### Simple Withdrawal Mapping

```
┌─────────────────────────────────────────┐
│     Withdrawal Queue Storage            │
├─────────────────────────────────────────┤
│                                         │
│  mapping(address => uint256) balances   │
│                                         │
│  ┌──────────────┬──────────────┐       │
│  │   Address    │   Balance    │       │
│  ├──────────────┼──────────────┤       │
│  │  0x123...    │  1.5 ETH     │       │
│  │  0x456...    │  0.8 ETH     │       │
│  │  0x789...    │  2.0 ETH     │       │
│  └──────────────┴──────────────┘       │
│                                         │
│  Storage Slot: keccak256(address || slot) │
│  Gas Cost: 20,000 (cold SLOAD)         │
│            2,100 (warm SLOAD)           │
└─────────────────────────────────────────┘
```

### Advanced Queue with Metadata

```
┌─────────────────────────────────────────────────┐
│     Enhanced Withdrawal Queue                   │
├─────────────────────────────────────────────────┤
│                                                 │
│  struct Withdrawal {                            │
│      uint256 amount;                            │
│      uint256 timestamp;                         │
│      bool processed;                            │
│  }                                              │
│                                                 │
│  mapping(address => Withdrawal) withdrawals     │
│                                                 │
│  ┌─────────┬──────────┬─────────────┬──────┐  │
│  │ Address │  Amount  │  Timestamp  │ Done │  │
│  ├─────────┼──────────┼─────────────┼──────┤  │
│  │ 0x123   │ 1.5 ETH  │ 1699999999  │  ✓   │  │
│  │ 0x456   │ 0.8 ETH  │ 1700000123  │  ✗   │  │
│  │ 0x789   │ 2.0 ETH  │ 1700001000  │  ✗   │  │
│  └─────────┴──────────┴─────────────┴──────┘  │
│                                                 │
│  Storage: 3 slots per withdrawal                │
│  Gas: ~60,000 for first write (cold)           │
└─────────────────────────────────────────────────┘
```

---

## Security Pitfalls and Solutions

### Pitfall 1: Check-Effects-Interactions Violation

```solidity
// VULNERABLE
function withdraw() public {
    uint256 amount = balances[msg.sender];
    // DANGER: External call before state change
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success);
    balances[msg.sender] = 0;  // TOO LATE!
}

// SECURE
function withdraw() public {
    uint256 amount = balances[msg.sender];
    balances[msg.sender] = 0;  // Update state FIRST
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success);
}
```

### Pitfall 2: Not Handling Failed Transfers

```solidity
// BAD: Funds are lost if transfer fails
function withdraw() public {
    uint256 amount = balances[msg.sender];
    balances[msg.sender] = 0;
    msg.sender.call{value: amount}("");  // Ignores failure!
}

// GOOD: Revert on failure to preserve state
function withdraw() public {
    uint256 amount = balances[msg.sender];
    balances[msg.sender] = 0;
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed");  // State reverts
}
```

### Pitfall 3: Integer Overflow/Underflow

```solidity
// Pre-0.8.0: VULNERABLE
function deposit() public payable {
    balances[msg.sender] += msg.value;  // Can overflow!
}

// Post-0.8.0: SAFE (automatic checks)
// Or use SafeMath explicitly
```

### Pitfall 4: Unprotected Self-Destruct

```solidity
// VULNERABLE
function destroy() public {
    selfdestruct(payable(owner));  // Anyone can call!
}

// SECURE
function destroy() public {
    require(msg.sender == owner, "Not owner");
    selfdestruct(payable(owner));
}
```

---

## Gas Analysis

### Deposit Function

```solidity
function deposit() public payable {
    balances[msg.sender] += msg.value;
    emit Deposited(msg.sender, msg.value);
}
```

**Gas Breakdown:**
- `SLOAD` (cold): 2,100 gas (read balance)
- `SSTORE` (non-zero to non-zero): 5,000 gas
- `SSTORE` (zero to non-zero): 20,000 gas (first deposit)
- `LOG2` (event): ~1,500 gas
- Base transaction: 21,000 gas

**Total:**
- First deposit: ~44,600 gas
- Subsequent deposits: ~29,600 gas

### Withdraw Function

```solidity
function withdraw() public {
    uint256 amount = balances[msg.sender];
    require(amount > 0, "No balance");

    balances[msg.sender] = 0;

    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed");

    emit Withdrawn(msg.sender, amount);
}
```

**Gas Breakdown:**
- `SLOAD` (cold): 2,100 gas (read balance)
- `SSTORE` (non-zero to zero): -15,000 gas (gas refund)
- `CALL`: 9,000 base + 2,300 stipend + recipient code
- `LOG2` (event): ~1,500 gas
- Base transaction: 21,000 gas

**Total:**
- ~30,000-50,000 gas (depends on recipient)

### Gas Refunds

Since Solidity 0.8.0 and EIP-3529:
- Storage refunds are capped at 20% of gas used
- Setting storage to zero gives refund, but limited
- Old refund: 15,000 gas
- New refund: Capped by transaction gas

---

## Common Attack Vectors

### 1. Reentrancy Attack

```solidity
contract Attacker {
    VulnerableContract target;

    function attack() public payable {
        target.deposit{value: 1 ether}();
        target.withdraw();
    }

    receive() external payable {
        if (address(target).balance >= 1 ether) {
            target.withdraw();  // Re-enter!
        }
    }
}
```

**Defense:** Checks-Effects-Interactions pattern

### 2. DoS by Block Gas Limit

```solidity
// Attacker creates many small deposits
for (uint i = 0; i < 1000; i++) {
    target.deposit{value: 1 wei}();
}

// Now any function iterating over deposits fails
```

**Defense:** Use pull pattern, never iterate unbounded arrays

### 3. Force-Feeding ETH

```solidity
// Contract with strict balance check
require(address(this).balance == expectedBalance);

// Attacker can break this with selfdestruct
selfdestruct(payable(targetContract));
```

**Defense:** Never rely on exact balance checks

---

## Implementation Checklist

- [ ] Use pull payment pattern for all ETH transfers
- [ ] Follow Checks-Effects-Interactions pattern
- [ ] Handle failed transfers appropriately
- [ ] Emit events for all state changes
- [ ] Protect against reentrancy
- [ ] Avoid unbounded loops
- [ ] Use OpenZeppelin's ReentrancyGuard
- [ ] Test with malicious contracts
- [ ] Consider emergency withdrawal mechanisms
- [ ] Document all edge cases

---

## Testing Strategy

### Unit Tests
- Test successful deposits
- Test successful withdrawals
- Test zero balance withdrawals
- Test reentrancy protection
- Test event emissions

### Integration Tests
- Test with contracts that reject ETH
- Test with contracts that consume lots of gas
- Test gas limits
- Test multiple users

### Fuzzing Tests
- Random deposit amounts
- Random withdrawal patterns
- Edge case amounts (0, MAX_UINT256)

---

## Best Practices Summary

1. **Always use pull payments** for distributing funds to multiple recipients
2. **Follow CEI pattern**: Checks → Effects → Interactions
3. **Handle failures**: Never ignore return values from `.call()`
4. **Use ReentrancyGuard**: Defense in depth
5. **Emit events**: Make all state changes observable
6. **Test thoroughly**: Include malicious contract tests
7. **Document**: Explain security decisions in comments
8. **Gas considerations**: Forward appropriate gas, not all gas

---

## Additional Resources

- [ConsenSys Best Practices: Pull over Push](https://consensys.github.io/smart-contract-best-practices/attacks/denial-of-service/#favor-pull-over-push-for-external-calls)
- [OpenZeppelin Pull Payment](https://docs.openzeppelin.com/contracts/4.x/api/security#PullPayment)
- [EIP-1884: Repricing for trie-size-dependent opcodes](https://eips.ethereum.org/EIPS/eip-1884)
- [SWC-107: Reentrancy](https://swcregistry.io/docs/SWC-107)
- [SWC-113: DoS with Failed Call](https://swcregistry.io/docs/SWC-113)

---

## Project Structure

```
12-safe-eth-transfer/
├── README.md
├── src/
│   ├── Project12.sol           # Skeleton with TODOs
│   └── solution/
│       └── Project12Solution.sol # Complete implementation
├── test/
│   └── Project12.t.sol         # Comprehensive tests
└── script/
    └── DeployProject12.s.sol   # Deployment script
```

---

## Getting Started

1. Read this README thoroughly
2. Study the skeleton contract in `src/Project12.sol`
3. Try implementing the TODOs yourself
4. Run tests: `forge test`
5. Compare with solution in `src/solution/Project12Solution.sol`
6. Deploy: `forge script script/DeployProject12.s.sol`

Happy learning!
