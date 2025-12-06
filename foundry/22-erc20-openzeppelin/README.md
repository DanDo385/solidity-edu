# Project 22: ERC-20 (OpenZeppelin)

This project explores OpenZeppelin's ERC-20 implementation, teaching you how to leverage battle-tested contract patterns, hooks, and extensions to build production-ready tokens.

## Learning Objectives

- Understand OpenZeppelin vs manual ERC-20 implementation
- Master the ERC20 base contract and its features
- Learn the hook system (_beforeTokenTransfer, _afterTokenTransfer)
- Implement various extension patterns (Burnable, Pausable, Snapshot, Votes)
- Make informed decisions about when to use each extension
- Compare gas costs between manual and OpenZeppelin implementations
- Apply best practices for production token contracts

## OpenZeppelin vs Manual Implementation: Production-Ready Patterns

**FIRST PRINCIPLES: Battle-Tested vs Custom Code**

OpenZeppelin provides production-ready implementations of common standards. Understanding when to use libraries vs custom code is crucial!

**CONNECTION TO PROJECT 08**:
- **Project 08**: We implemented ERC20 from scratch (learning the fundamentals)
- **Project 22**: We use OpenZeppelin's ERC20 (production-ready implementation)
- Both approaches have their place - understand fundamentals, use libraries in production!

### Why Use OpenZeppelin?

**Advantages:**
1. **Battle-tested**: Audited by multiple security firms and used by thousands of projects
2. **Gas-optimized**: Carefully optimized for gas efficiency (though slightly more than custom)
3. **Modular**: Extension pattern allows adding functionality without bloating base contract
4. **Maintained**: Regular updates for security patches and new standards
5. **Standardized**: Widely recognized code patterns reduce audit time

**Disadvantages:**
1. **Slightly higher gas costs**: Generic implementation trades some gas for flexibility (~2% overhead)
2. **Learning curve**: Need to understand the extension patterns
3. **Dependency**: External dependency in your project
4. **Less control**: Can't customize low-level behavior without forking

**WHEN TO USE OPENZEPPELIN**:
- ✅ Production contracts (security > gas savings)
- ✅ Standard functionality (ERC20, ERC721, etc.)
- ✅ When you need extensions (Pausable, Burnable, etc.)
- ✅ When audit time is limited (battle-tested code)

**WHEN TO USE CUSTOM**:
- ✅ Learning/education (understand fundamentals)
- ✅ Gas-critical applications (need every optimization)
- ✅ Non-standard requirements (custom logic needed)
- ✅ When you need full control (no dependencies)

**COMPARISON TO RUST** (DSA/Library Pattern):

**Rust** (using crates):
```rust
// Using standard library or crates
use std::collections::HashMap;
use serde::{Serialize, Deserialize};

// Benefits: Battle-tested, maintained, standardized
// Trade-off: Less control, dependency management
```

**Solidity** (using OpenZeppelin):
```solidity
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    // Benefits: Battle-tested, maintained, standardized
    // Trade-off: Slightly more gas, dependency
}
```

Both use library patterns - leverage existing code for production, write custom for learning!

### Gas Comparison

| Operation | Manual ERC20 | OpenZeppelin ERC20 | Difference |
|-----------|-------------|-------------------|------------|
| Deployment | ~650k gas | ~750k gas | +15% |
| Transfer | ~51k gas | ~52k gas | +2% |
| Approve | ~44k gas | ~45k gas | +2% |
| TransferFrom | ~55k gas | ~56k gas | +2% |

**Verdict**: OpenZeppelin adds ~2% gas overhead per operation but provides significantly better security guarantees. The trade-off is almost always worth it for production contracts.

## ERC20 Base Contract Features

OpenZeppelin's ERC20 provides:

```solidity
// Core ERC20 functionality
function totalSupply() public view returns (uint256)
function balanceOf(address account) public view returns (uint256)
function transfer(address to, uint256 amount) public returns (bool)
function allowance(address owner, address spender) public view returns (uint256)
function approve(address spender, uint256 amount) public returns (bool)
function transferFrom(address from, address to, uint256 amount) public returns (bool)

// Extended functionality
function name() public view returns (string memory)
function symbol() public view returns (string memory)
function decimals() public view returns (uint8)

// Internal functions for extensions
function _mint(address account, uint256 amount) internal
function _burn(address account, uint256 amount) internal
function _transfer(address from, address to, uint256 amount) internal
function _approve(address owner, address spender, uint256 amount) internal
```

## Hook System

OpenZeppelin's hook system allows you to inject custom logic before and after token transfers.

### Available Hooks

```solidity
function _update(address from, address to, uint256 value) internal virtual
```

**Note**: In OpenZeppelin 5.x, `_beforeTokenTransfer` and `_afterTokenTransfer` were replaced with a single `_update` hook that's called during transfers, mints, and burns.

### Hook Use Cases

1. **Pausable Tokens**: Prevent transfers when contract is paused
2. **Snapshot Tokens**: Record balances at specific blocks
3. **Vesting**: Enforce token lock-up periods
4. **Fees**: Deduct fees on every transfer
5. **Whitelisting**: Restrict transfers to approved addresses
6. **Supply Caps**: Enforce maximum supply limits

### Hook Example

```solidity
function _update(address from, address to, uint256 value) internal virtual override {
    // from == address(0) means minting
    // to == address(0) means burning
    // both non-zero means transfer

    if (from != address(0) && to != address(0)) {
        // Custom transfer logic
        require(!paused, "Transfers are paused");
    }

    super._update(from, to, value);
}
```

## Extension Patterns

OpenZeppelin provides several pre-built extensions. Here's when to use each:

### 1. ERC20Burnable

**What it does**: Allows token holders to burn (destroy) their tokens.

**Use when**:
- You want deflationary tokenomics
- Users need to permanently remove tokens from circulation
- Implementing burn-to-redeem mechanisms

**Gas cost**: Adds ~500 gas per burn operation

```solidity
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract MyToken is ERC20, ERC20Burnable {
    // burn() and burnFrom() are now available
}
```

### 2. ERC20Pausable

**What it does**: Allows owner to pause all token transfers.

**Use when**:
- You need emergency stop functionality
- Regulatory compliance requires transfer halting
- During security incident response

**Gas cost**: Adds ~2.5k gas per transfer (checks paused state)

```solidity
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";

contract MyToken is ERC20, ERC20Pausable, Ownable {
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
```

### 3. ERC20Snapshot

**What it does**: Records token balances at specific points in time.

**Use when**:
- Implementing dividend distributions based on historical holdings
- Governance voting based on past balances
- Airdrop calculations

**Gas cost**: Adds ~10-15k gas per transfer (maintains historical records)

```solidity
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";

contract MyToken is ERC20, ERC20Snapshot, Ownable {
    function snapshot() public onlyOwner returns (uint256) {
        return _snapshot();
    }

    function balanceOfAt(address account, uint256 snapshotId) public view returns (uint256) {
        return super.balanceOfAt(account, snapshotId);
    }
}
```

### 4. ERC20Votes

**What it does**: Enables on-chain governance with delegation and voting power.

**Use when**:
- Building a DAO governance token
- Need delegated voting mechanisms
- Implementing on-chain governance proposals

**Gas cost**: Adds ~20-30k gas per transfer (maintains voting checkpoints)

```solidity
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract GovernanceToken is ERC20, ERC20Votes {
    constructor() ERC20("Governance", "GOV") ERC20Permit("Governance") {
        _mint(msg.sender, 1_000_000e18);
    }

    // Required overrides
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    function nonces(address owner) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
```

### 5. ERC20Permit (EIP-2612)

**What it does**: Allows approvals via signatures instead of transactions.

**Use when**:
- Improving UX by removing approval transactions
- Building gasless transaction systems
- Integrating with meta-transaction protocols

**Gas cost**: ~0 gas (uses off-chain signatures)

```solidity
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract MyToken is ERC20, ERC20Permit {
    constructor() ERC20("MyToken", "MTK") ERC20Permit("MyToken") {
        _mint(msg.sender, 1_000_000e18);
    }
}
```

### 6. ERC20Capped

**What it does**: Enforces a maximum token supply cap.

**Use when**:
- You want to guarantee maximum supply
- Implementing fixed-supply tokenomics
- Building deflationary with supply cap

**Gas cost**: Adds ~200 gas per mint operation

```solidity
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

contract MyToken is ERC20, ERC20Capped {
    constructor() ERC20("MyToken", "MTK") ERC20Capped(1_000_000e18) {
        _mint(msg.sender, 500_000e18); // Can't exceed cap
    }
}
```

## Combining Multiple Extensions

You can combine multiple extensions, but be aware of:

1. **Override conflicts**: Multiple extensions may override the same function
2. **Gas costs**: Each extension adds overhead
3. **Complexity**: More extensions = more complex interactions

### Example: Full-Featured Token

```solidity
contract FullToken is ERC20, ERC20Burnable, ERC20Pausable, ERC20Snapshot, Ownable {
    constructor() ERC20("Full", "FULL") Ownable(msg.sender) {
        _mint(msg.sender, 1_000_000e18);
    }

    // Must override _update to resolve conflicts
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Pausable, ERC20Snapshot) {
        super._update(from, to, value);
    }
}
```

## Extension Selection Guide

| Feature Needed | Extension | Gas Impact | Complexity |
|----------------|-----------|------------|------------|
| Token burning | ERC20Burnable | Low | Low |
| Emergency pause | ERC20Pausable | Low | Low |
| Historical balances | ERC20Snapshot | Medium | Medium |
| Governance/voting | ERC20Votes | High | High |
| Gasless approvals | ERC20Permit | None | Low |
| Supply cap | ERC20Capped | Low | Low |
| Flash minting | ERC20FlashMint | Medium | Medium |

## Best Practices

### 1. Initialization

```solidity
// Good: Set metadata in constructor
constructor() ERC20("MyToken", "MTK") {
    _mint(msg.sender, INITIAL_SUPPLY);
}

// Bad: Forgetting to set supply
constructor() ERC20("MyToken", "MTK") {
    // No tokens minted - useless token!
}
```

### 2. Access Control

```solidity
// Good: Use OpenZeppelin's AccessControl or Ownable
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, Ownable {
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

// Bad: Manual access control (bug-prone)
address public owner;
modifier onlyOwner() {
    require(msg.sender == owner); // Missing error message
    _;
}
```

### 3. Safe Minting

```solidity
// Good: Check for address(0) and overflow
function mint(address to, uint256 amount) public onlyOwner {
    require(to != address(0), "Cannot mint to zero address");
    _mint(to, amount); // OpenZeppelin checks for overflow
}

// Bad: No validation
function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount); // Could mint to address(0)
}
```

### 4. Event Emissions

```solidity
// Good: OpenZeppelin automatically emits Transfer events
// You just need to emit custom events

event TokensMinted(address indexed to, uint256 amount);

function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount); // Emits Transfer(address(0), to, amount)
    emit TokensMinted(to, amount); // Your custom event
}
```

### 5. Override Conflicts

```solidity
// Good: Properly resolve multiple inheritance
function _update(
    address from,
    address to,
    uint256 value
) internal override(ERC20, ERC20Pausable, ERC20Snapshot) {
    super._update(from, to, value); // Calls all parent implementations
}

// Bad: Missing override specifiers
function _update(address from, address to, uint256 value) internal override(ERC20) {
    super._update(from, to, value); // Doesn't call all parents!
}
```

### 6. Decimal Precision

```solidity
// Good: Document your decimal choice
/**
 * @dev Uses 18 decimals (standard for most ERC20 tokens)
 * 1 token = 1e18 units
 */
constructor() ERC20("MyToken", "MTK") {
    _mint(msg.sender, 1_000_000 * 10**18);
}

// Also good: Custom decimals with clear documentation
function decimals() public pure override returns (uint8) {
    return 6; // USDC-style 6 decimals
}
```

### 7. Testing

```solidity
// Always test:
// 1. Basic transfers
// 2. Approval mechanisms
// 3. Edge cases (zero address, zero amount)
// 4. Access control
// 5. Extension-specific functionality
// 6. Integration with other contracts
```

## Common Pitfalls

### 1. Forgetting Override Specifiers

```solidity
// Wrong: Will fail to compile
contract MyToken is ERC20, ERC20Pausable {
    function _update(address from, address to, uint256 value) internal {
        // Missing: override(ERC20, ERC20Pausable)
        super._update(from, to, value);
    }
}
```

### 2. Incorrect Super Calls

```solidity
// Wrong: Not calling super._update
function _update(address from, address to, uint256 value)
    internal override(ERC20, ERC20Pausable)
{
    // Custom logic but forgot super call!
    // This breaks the token!
}

// Correct:
function _update(address from, address to, uint256 value)
    internal override(ERC20, ERC20Pausable)
{
    // Custom logic first
    super._update(from, to, value); // Then call parent
}
```

### 3. Snapshot Before Distribution

```solidity
// Wrong: Snapshot after distribution
function distributeRewards() public {
    uint256 currentSnapshot = _snapshot(); // Too late!
    // Users could have transferred tokens already
}

// Correct: Snapshot before announcement
function announceDistribution() public {
    uint256 snapshot = _snapshot(); // Lock balances first
    // Then announce distribution
}
```

### 4. Not Handling Delegation for Votes

```solidity
// Wrong: Assuming votes are automatic
function getVotingPower(address account) public view returns (uint256) {
    return balanceOf(account); // Wrong! Need to delegate first
}

// Correct: Use getVotes
function getVotingPower(address account) public view returns (uint256) {
    return getVotes(account); // Returns delegated voting power
}
```

## Project Structure

```
22-erc20-openzeppelin/
├── README.md
├── src/
│   ├── Project22.sol              # Skeleton for students
│   └── solution/
│       └── Project22Solution.sol  # Complete solution
├── test/
│   └── Project22.t.sol           # Comprehensive tests
└── script/
    └── DeployProject22.s.sol     # Deployment script
```

## Getting Started

1. Install dependencies:
```bash
forge install OpenZeppelin/openzeppelin-contracts
```

2. Implement the TODOs in `src/Project22.sol`

3. Run tests:
```bash
forge test --match-path test/Project22.t.sol -vv
```

4. Compare with solution:
```bash
forge test --match-path test/Project22.t.sol --match-contract Project22SolutionTest -vvv
```

## Tasks

### Basic Tasks

1. Create a simple ERC20 token using OpenZeppelin
2. Add burnable functionality
3. Add pausable functionality
4. Combine multiple extensions

### Advanced Tasks

5. Implement a snapshot token for dividend distribution
6. Create a governance token with voting capabilities
7. Build a token with custom hook logic
8. Implement a capped token with vesting

### Expert Tasks

9. Create a full-featured token combining 4+ extensions
10. Build a token with custom fee mechanism using hooks
11. Implement a governance token with delegation strategies
12. Compare gas costs between manual and OZ implementation

## Additional Resources

- [OpenZeppelin ERC20 Documentation](https://docs.openzeppelin.com/contracts/5.x/erc20)
- [OpenZeppelin Contracts GitHub](https://github.com/OpenZeppelin/openzeppelin-contracts)
- [EIP-20: Token Standard](https://eips.ethereum.org/EIPS/eip-20)
- [EIP-2612: Permit Extension](https://eips.ethereum.org/EIPS/eip-2612)
- [OpenZeppelin Wizard](https://wizard.openzeppelin.com/)

## Security Considerations

1. **Always use latest OpenZeppelin version**: Security patches are critical
2. **Audit custom hooks**: Any custom logic in hooks should be thoroughly audited
3. **Test extension interactions**: Multiple extensions can have unexpected interactions
4. **Be cautious with pausability**: Paused tokens can be permanently locked
5. **Understand delegation**: ERC20Votes delegation can have complex edge cases
6. **Reentrancy**: While ERC20 is generally safe, custom hooks may introduce risks

## Summary

OpenZeppelin's ERC20 implementation provides:
- Battle-tested, secure token functionality
- Modular extension system for common patterns
- Small gas overhead (~2%) for significant security gains
- Comprehensive hooks for custom logic
- Production-ready code used by thousands of projects

For production tokens, OpenZeppelin is almost always the right choice. The minor gas costs are far outweighed by the security, maintainability, and community trust it provides.
