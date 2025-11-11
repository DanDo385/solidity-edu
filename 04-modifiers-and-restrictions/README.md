# Project 04: Modifiers & Access Control 🔐

> **Implement custom modifiers and access control patterns**

## 🎯 Learning Objectives

- Create custom function modifiers
- Implement `onlyOwner` pattern from scratch
- Understand role-based access control (RBAC)
- Compare DIY vs OpenZeppelin AccessControl
- Learn modifier execution order and composition

## 📚 Key Concepts

### Function Modifiers

Modifiers are reusable checks that run before/after function execution:
- Reduce code duplication
- Enforce preconditions  
- Can take parameters
- Chain multiple modifiers

### Modifier Execution Order

```solidity
function example() public modifierA modifierB {
    // Execution: modifierA → modifierB → function body
}
```

## 🔧 What You'll Build

A contract demonstrating:
- Custom modifiers with parameters
- Owner-based access control
- Role management system
- Modifier composition and chaining

## 📝 Tasks

### Task 1: Implement Custom Modifiers

Open `src/ModifiersRestrictions.sol` and implement:
1. `onlyOwner` modifier
2. `onlyRole` modifier with parameter
3. `notPaused` modifier
4. Modifiers that can chain together

### Task 2: Run Tests

```bash
cd 04-modifiers-and-restrictions
forge test -vvv
forge test --gas-report
```

### Task 3: Study Patterns

Compare your implementation with OpenZeppelin:
- Ownable.sol
- AccessControl.sol
- Pausable.sol

## ✅ Completion Checklist

- [ ] Implemented custom modifiers
- [ ] All tests pass
- [ ] Understand modifier execution order
- [ ] Can create parameterized modifiers  
- [ ] Know when to use modifiers vs require()

## 🚀 Next Steps

- Move to [Project 05: Errors & Reverts](../05-errors-and-reverts/)
- Study OpenZeppelin access control contracts
- Implement time-locked operations
