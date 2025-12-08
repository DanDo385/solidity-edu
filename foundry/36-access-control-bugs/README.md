# Project 36: Access Control Bugs

Learn about common access control vulnerabilities in Solidity and how to prevent them.

## Overview

Access control is one of the most critical aspects of smart contract security. Improper access control can lead to unauthorized users performing privileged operations, potentially draining funds or corrupting contract state. This project explores common access control bugs and their exploits.

## Learning Objectives

By completing this project, you will:
- Understand common access control anti-patterns
- Learn the difference between `tx.origin` and `msg.sender`
- Identify uninitialized owner vulnerabilities
- Recognize missing modifier bugs
- Understand role escalation attacks
- Learn proper initialization patterns
- Master OpenZeppelin's AccessControl library

## Common Access Control Vulnerabilities: The Gatekeepers' Mistakes

**FIRST PRINCIPLES: Access Control is Critical**

Access control bugs are among the most common and dangerous vulnerabilities. Understanding these patterns is essential for secure contract development!

**CONNECTION TO PROJECT 04 & 10**:
- **Project 04**: We learned about modifiers and access control patterns
- **Project 10**: We learned about proxy patterns and initialization
- **Project 36**: We learn about common access control bugs and exploits!

### 1. Uninitialized Proxy Owner: The Race Condition

**PROBLEM**: In upgradeable proxy patterns, if the owner is not initialized in the constructor or initializer, anyone can claim ownership.

**CONNECTION TO PROJECT 10**:
Proxy contracts don't use constructors (they delegate to implementation). If initialization isn't protected, first caller wins!

```solidity
contract VulnerableProxy {
    address public owner;  // Slot 0: address(0) initially

    // ❌ Owner never initialized!
    // First caller of setOwner becomes owner
    function setOwner(address newOwner) public {
        require(owner == address(0), "Owner already set");
        owner = newOwner;  // Anyone can call this first!
    }
}
```

**ATTACK SCENARIO**:

```
Race Condition Attack:
┌─────────────────────────────────────────┐
│ Proxy deployed                          │
│   owner = address(0)                     │ ← Uninitialized!
│   ↓                                      │
│ Attacker sees deployment                │ ← Mempool observation
│   ↓                                      │
│ Attacker calls setOwner(attacker)       │ ← Front-run!
│   ↓                                      │
│ Check: owner == address(0)? ✅          │ ← Passes!
│   ↓                                      │
│ owner = attacker                        │ ← Attacker becomes owner!
│   ↓                                      │
│ Legitimate owner tries to initialize    │ ← Too late!
│   ↓                                      │
│ Check: owner == address(0)? ❌          │ ← Fails!
│   ↓                                      │
│ Attacker has full control! 💥           │
└─────────────────────────────────────────┘
```

**THE FIX**: Initialize owner in constructor or use proper initializer pattern:

```solidity
contract SecureProxy {
    address public owner;

    constructor() {
        owner = msg.sender;  // ✅ Initialized immediately!
    }

    function setOwner(address newOwner) public {
        require(msg.sender == owner, "Not owner");  // ✅ Protected!
        owner = newOwner;
    }
}
```

**OR** (for upgradeable proxies):

```solidity
bool private initialized;

function initialize(address _owner) public {
    require(!initialized, "Already initialized");  // ✅ One-time only!
    owner = _owner;
    initialized = true;
}
```

**GAS COST** (from Project 01 & 04 knowledge):
- Setting owner: ~20,000 gas (cold SSTORE)
- Initialization check: ~100 gas (SLOAD)
- Total: ~20,100 gas (one-time cost)

**REAL-WORLD ANALOGY**: 
Like a bank vault with no lock - first person to arrive can set the combination! Always initialize access control immediately!

### 2. Missing Access Control Modifiers

**Problem**: Forgetting to add access control modifiers to privileged functions.

```solidity
contract MissingModifier {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // Missing onlyOwner modifier!
    function withdraw() public {
        payable(owner).transfer(address(this).balance);
    }
}
```

**Fix**: Always add appropriate modifiers:

```solidity
contract SecureContract {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
```

### 3. tx.origin vs msg.sender

**Problem**: Using `tx.origin` for authentication can be exploited through phishing attacks.

```solidity
contract VulnerableTxOrigin {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function withdraw() public {
        require(tx.origin == owner, "Not owner");  // VULNERABLE!
        payable(owner).transfer(address(this).balance);
    }
}
```

**Attack Scenario**:
1. Attacker deploys malicious contract
2. Owner calls malicious contract
3. Malicious contract calls `withdraw()` on vulnerable contract
4. Since `tx.origin` is still the owner, the check passes
5. Funds are drained

**Fix**: Always use `msg.sender`:

```solidity
contract SecureContract {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function withdraw() public {
        require(msg.sender == owner, "Not owner");  // CORRECT
        payable(owner).transfer(address(this).balance);
    }
}
```

### 4. Role Escalation

**Problem**: Users can escalate their privileges through improper role management.

```solidity
contract VulnerableRoles {
    mapping(address => bool) public admins;

    constructor() {
        admins[msg.sender] = true;
    }

    // Anyone can become admin!
    function addAdmin(address newAdmin) public {
        admins[newAdmin] = true;
    }
}
```

**Fix**: Restrict role management to existing privileged users:

```solidity
contract SecureRoles {
    mapping(address => bool) public admins;

    constructor() {
        admins[msg.sender] = true;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Not admin");
        _;
    }

    function addAdmin(address newAdmin) public onlyAdmin {
        admins[newAdmin] = true;
    }
}
```

### 5. Public Functions That Should Be Private/Internal

**Problem**: Making initialization or privileged functions public when they should be restricted.

```solidity
contract VulnerableInitialization {
    address public owner;
    bool private initialized;

    // Should be external or have access control!
    function initialize(address _owner) public {
        require(!initialized, "Already initialized");
        owner = _owner;
        initialized = true;
    }
}
```

**Fix**: Use proper visibility and access control:

```solidity
contract SecureInitialization {
    address public owner;
    bool private initialized;

    constructor(address _owner) {
        owner = _owner;
        initialized = true;
    }

    // Or use initializer pattern with Ownable
    function initialize(address _owner) external {
        require(!initialized, "Already initialized");
        require(msg.sender == deployer, "Not deployer");
        owner = _owner;
        initialized = true;
    }
}
```

### 6. Constructor vs Initializer Issues

**Problem**: In upgradeable contracts, constructors don't work as expected. Initializers must be protected.

```solidity
// WRONG for upgradeable contracts
contract VulnerableUpgradeable {
    address public owner;

    constructor() {
        owner = msg.sender;  // Won't work with proxies!
    }
}

// WRONG - unprotected initializer
contract VulnerableInitializer {
    address public owner;

    function initialize() public {
        owner = msg.sender;  // Can be called multiple times!
    }
}
```

**Fix**: Use proper initializer pattern:

```solidity
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract SecureUpgradeable is Initializable, OwnableUpgradeable {
    function initialize() public initializer {
        __Ownable_init(msg.sender);
    }
}
```

### 7. Delegatecall Preservation

**Problem**: When using `delegatecall`, the caller's context is preserved, which can bypass access controls.

```solidity
contract VulnerableDelegatecall {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function delegateCallToLibrary(address library, bytes memory data) public {
        // No access control!
        library.delegatecall(data);
    }
}
```

**Fix**: Restrict delegatecall to trusted addresses:

```solidity
contract SecureDelegatecall {
    address public owner;
    mapping(address => bool) public trustedLibraries;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function delegateCallToLibrary(address library, bytes memory data) public onlyOwner {
        require(trustedLibraries[library], "Untrusted library");
        library.delegatecall(data);
    }
}
```

## Real-World Access Control Bugs

### Parity Wallet Hack (2017)

The Parity multi-sig wallet had an uninitialized owner vulnerability. The library contract's `initWallet` function was public and unprotected:

```solidity
function initWallet(address[] _owners, uint _required, uint _daylimit) {
    // No check if already initialized!
    initMultiowned(_owners, _required);
    initDaylimit(_daylimit);
}
```

An attacker called `initWallet`, became the owner, and then called `kill`, destroying the library contract and freezing ~$300M in ETH.

### Rubixi (2016)

The contract was originally named "DynamicPyramid" but was renamed to "Rubixi". However, the constructor name wasn't updated:

```solidity
contract Rubixi {
    address private creator;

    // Old constructor name - now just a public function!
    function DynamicPyramid() public {
        creator = msg.sender;
    }
}
```

Anyone could call `DynamicPyramid()` and become the creator.

### OpenZeppelin AccessControl Best Practices

OpenZeppelin provides robust role-based access control:

```solidity
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SecureContract is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function adminFunction() public onlyRole(ADMIN_ROLE) {
        // Admin-only logic
    }

    function operatorFunction() public onlyRole(OPERATOR_ROLE) {
        // Operator-only logic
    }
}
```

## Project Tasks

### Part 1: Identify Vulnerabilities

Examine the vulnerable contracts in `src/Project36.sol` and identify:
1. Which contracts have access control bugs
2. What type of vulnerability each has
3. How an attacker could exploit each bug

### Part 2: Write Exploits

Create exploit contracts that:
1. Take ownership of uninitialized contracts
2. Call functions missing modifiers
3. Exploit tx.origin authentication
4. Escalate roles
5. Call unprotected initializers

### Part 3: Fix Vulnerabilities

Implement secure versions:
1. Add proper initialization
2. Add missing modifiers
3. Replace tx.origin with msg.sender
4. Add role-based access control
5. Protect all privileged functions

### Part 4: Write Tests

Create comprehensive tests:
1. Verify exploits work on vulnerable contracts
2. Verify fixes prevent exploits
3. Test edge cases
4. Test role-based access control

## Testing

Run the test suite:

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vvv

# Run specific test
forge test --match-test testUninitializedOwner -vvv

# Check gas usage
forge test --gas-report
```

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/AccessControlBugsSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployAccessControlBugsSolution.s.sol` - Deployment script patterns
- `test/solution/AccessControlBugsSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains access control vulnerabilities, tx.origin vs msg.sender, initialization patterns
- **Connections to Project 04**: Modifiers and access control (this shows common bugs)
- **Connections to Project 10**: Proxy initialization (uninitialized owner is a common bug)
- **Real-World Context**: Access control bugs are among the most common vulnerabilities

## Key Takeaways

1. **Always initialize ownership**: Never leave owner uninitialized
2. **Use modifiers consistently**: Don't forget access control modifiers
3. **Never use tx.origin**: Always use msg.sender for authentication
4. **Protect role management**: Only privileged users should manage roles
5. **Follow initialization patterns**: Use OpenZeppelin's Initializable for upgradeable contracts
6. **Use established libraries**: OpenZeppelin AccessControl is battle-tested
7. **Test access control**: Always test both positive and negative cases
8. **Principle of least privilege**: Give minimum necessary permissions
9. **Audit carefully**: Access control bugs are subtle and critical
10. **Document permissions**: Clearly document who should have what access

## Additional Resources

- [OpenZeppelin Access Control](https://docs.openzeppelin.com/contracts/4.x/access-control)
- [SWC-105: Unprotected Ether Withdrawal](https://swcregistry.io/docs/SWC-105)
- [SWC-115: Authorization through tx.origin](https://swcregistry.io/docs/SWC-115)
- [Consensys Best Practices: Access Control](https://consensys.github.io/smart-contract-best-practices/development-recommendations/solidity-specific/access-control/)
- [Parity Wallet Hack Explained](https://blog.openzeppelin.com/on-the-parity-wallet-multisig-hack-405a8c12e8f7)

## Security Tips

- Use OpenZeppelin's `Ownable` and `AccessControl` contracts
- Initialize all state variables
- Use modifiers for repeated access checks
- Never trust `tx.origin`
- Test access control thoroughly
- Consider multi-sig for critical operations
- Implement timelock for sensitive changes
- Emit events for all permission changes
- Use role-based access control for complex permissions
- Review access control in every function

Remember: Access control is the first line of defense in smart contract security!
