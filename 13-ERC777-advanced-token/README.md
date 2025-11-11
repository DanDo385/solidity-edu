# Project 13: ERC-777 Advanced Token with Hooks 🔄

> **Implement advanced fungible tokens with operators and hooks for automated DeFi workflows**

## 🎯 Learning Objectives

- Understand ERC-777's improvements over ERC-20
- Implement hooks (tokensToSend, tokensReceived callbacks)
- Learn operator pattern for authorized third parties
- Handle backwards compatibility with ERC-20
- Study DeFi automation use cases

## 📚 Background: Why ERC-777?

ERC-777 improves upon ERC-20 by adding:

### Key Innovations

**1. Hooks (Callbacks)**
```solidity
// Contract can react when receiving tokens
function tokensReceived(...) external {
    // Auto-compound rewards
    // Auto-stake tokens  
    // Trigger smart contract logic
}
```

**2. Operators**
```solidity
// Authorized operators can send on your behalf
// Like ERC-20 approve, but more flexible
authorizeOperator(subscriptionContract);
```

**3. No More approve() + transferFrom() Dance**
```solidity
// ERC-20 requires two transactions:
approve(spender, amount);      // Transaction 1
transferFrom(from, to, amount); // Transaction 2

// ERC-777 uses operators - one transaction:
send(to, amount, data);        // Just send!
```

**4. Backwards Compatible with ERC-20**
- Implements ERC-20 interface
- Can be used with existing DeFi

## 🔧 Core Concepts

### Operators

```solidity
// Default operators (set at deployment)
constructor(address[] memory defaultOperators)

// User authorizes operator
authorizeOperator(operator);

// User revokes operator
revokeOperator(operator);

// Check if operator
isOperatorFor(operator, tokenHolder);
```

### Hooks (ERC1820 Registry)

```solidity
// Sender hook - called before tokens leave
function tokensToSend(
    address operator,
    address from,
    address to,
    uint256 amount,
    bytes calldata userData,
    bytes calldata operatorData
) external;

// Receiver hook - called when tokens arrive
function tokensReceived(
    address operator,
    address from,
    address to,
    uint256 amount,
    bytes calldata userData,
    bytes calldata operatorData
) external;
```

## 📝 Tasks

### Task 1: Implement the Contract

Open `src/ERC777AdvancedToken.sol` and implement:
1. **Operator management** - Authorize, revoke, check operators
2. **Send function** - Token transfers with hooks
3. **Hook interfaces** - ERC777Sender and ERC777Recipient
4. **ERC-20 compatibility** - transfer(), approve(), transferFrom()
5. **Burn and mint** - With proper hook calls

### Task 2: Run Tests

```bash
cd 13-ERC777-advanced-token
forge test -vvv
forge test --match-test test_Hooks
forge test --match-test test_Operators
```

## ⚠️ Security Considerations

### 1. Reentrancy via Hooks

```solidity
// Hooks can call back into contract!
// MUST use checks-effects-interactions
balances[from] -= amount;  // Update BEFORE hook
_callTokensToSend(...);    // Hook AFTER state change
```

### 2. ERC-20 Compatibility Issues

```solidity
// Some DeFi protocols expect pure ERC-20
// ERC-777 hooks can break assumptions
// Test thoroughly with target protocols
```

### 3. Gas Costs

```solidity
// Hooks add significant gas overhead
// ERC-20 transfer: ~50k gas
// ERC-777 send: ~80k gas (with hooks)
```

## 🌍 Real-World Examples

### Use Cases

**Subscription Payments:**
```solidity
// Operator automatically deducts monthly fee
subscriptionContract.operatorSend(user, company, monthlyFee, "");
```

**Auto-Compounding:**
```solidity
// tokensReceived hook auto-stakes rewards
function tokensReceived(...) {
    stakingPool.stake(amount);
}
```

**Atomic Swaps:**
```solidity
// Receive tokens and instantly swap
function tokensReceived(...) {
    dex.swap(tokenA, tokenB, amount);
}
```

## ✅ Completion Checklist

- [ ] Implemented operator system
- [ ] Implemented hooks (send/receive)
- [ ] ERC-20 backwards compatibility
- [ ] All tests pass
- [ ] Understand reentrancy risks
- [ ] Can explain vs ERC-20 trade-offs

## 🚀 Next Steps

- Move to [Project 14: ERC-1400 Security Tokens](../14-ERC1400-security-token/)
- Study real ERC-777 implementations
- Test with DeFi protocols

## 📖 Further Reading

- [EIP-777 Specification](https://eips.ethereum.org/EIPS/eip-777)
- [EIP-1820 Registry](https://eips.ethereum.org/EIPS/eip-1820)
