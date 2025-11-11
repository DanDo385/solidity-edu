# Project 04: Modifiers & Access Control 🔐

> **Implement custom modifiers and access control patterns**

## 🎯 Learning Objectives

- Create custom function modifiers
- Implement `onlyOwner` pattern
- Understand role-based access control (RBAC)
- Compare DIY vs OpenZeppelin AccessControl
- Learn modifier execution order and composition

## 📚 Key Concepts

### Function Modifiers

Modifiers are **reusable checks** that run before/after function execution:
- Reduce code duplication
- Enforce preconditions
- Can take parameters
- Chain multiple modifiers

### Common Patterns

- **Ownable**: Single owner with special privileges
- **RBAC**: Multiple roles with different permissions
- **Pausable**: Emergency stop mechanism
- **Reentrancy Guard**: Prevent reentrant calls

## 🔧 What You'll Build

A contract demonstrating:
- Custom modifiers with parameters
- Owner-based access control
- Role-based permissions
- Modifier composition

## ✅ Status

🚧 **Scaffold** - Complete Projects 01-03 first

## 🚀 Next Steps

After completing this project:
- Move to [Project 05: Errors & Reverts](../05-errors-and-reverts/)
