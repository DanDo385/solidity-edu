# Project 04: Modifiers & Access Control 🔐

> **Implement custom modifiers and access control patterns**

## 🎯 Learning Objectives

- Create custom function modifiers
- Implement `onlyOwner` pattern from scratch
- Understand role-based access control (RBAC)
- Compare DIY vs OpenZeppelin AccessControl
- Learn modifier execution order and composition
- See how access control choices affect upgradeability, L2 fee profiles, and incident response

## 📚 Key Concepts

### Function Modifiers

Modifiers are reusable checks that run before/after function execution:
- Reduce code duplication
- Enforce preconditions  
- Can take parameters
- Chain multiple modifiers
- Act like airport security lanes that must be cleared before boarding the function body

### Modifier Execution Order

```solidity
function example() public modifierA modifierB {
    // Execution: modifierA → modifierB → function body
}
```

**Fun fact**: Modifiers are compiled into internal functions. Solc can inline simple modifiers, so a clean `onlyOwner` often costs only a couple of `JUMPI` opcodes in bytecode.

## 🔧 What You'll Build

A contract demonstrating:
- Custom modifiers with parameters
- Owner-based access control
- Role management system
- Modifier composition and chaining
- Checks-effects-interactions ordering inside modifiers to prevent footguns

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

Also notice how role hashes are just `bytes32` values; on L2s these small constants avoid extra storage hits during role checks.

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
- Consider how ownership transfers behaved during the Ethereum Classic split—clear admin paths help avoid governance chaos during forks

## 🛰️ Real-World Analogies & Fun Facts

- **Bouncer at a club**: `onlyOwner` is the bouncer checking IDs before anyone enters the function. Stacking modifiers is like needing both a ticket and a VIP wristband.
- **Compiler trivia**: Modifiers are syntactic sugar. Solc desugars them into internal calls, which the optimizer can inline, so keeping modifiers short often reduces gas.
- **Layer 2 tie-in**: Pausing contracts on L2 during incidents prevents costly dispute windows on L1. Cheap role checks (packed `bytes32` roles) make multi-sig admin actions more affordable across chains.
- **ETH inflation risk**: Overly permissive write functions can bloat state. Tight modifiers help limit who can create new storage, indirectly reducing long-term state growth pressure on validator hardware (and issuance).
- **Design history**: Access control libraries evolved after early hacks (e.g., Parity multisig). Clear modifiers make audits and incident response faster.
