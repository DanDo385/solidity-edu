# Project 31: Reentrancy Lab (Advanced) 🔄

> **Master advanced reentrancy attack patterns and defenses**

## 🎯 Learning Objectives

By completing this project, you will:

1. **Understand multi-function reentrancy attacks** and cross-function exploitation
2. **Exploit cross-contract reentrancy vulnerabilities** through multiple contracts
3. **Master read-only reentrancy** (view function exploits)
4. **Build multi-hop reentrancy chains** for complex attacks
5. **Analyze real-world case studies** (DAO hack, Lendf.me)
6. **Implement advanced defense strategies** beyond basic ReentrancyGuard
7. **Create Foundry attack simulations** for testing
8. **Write comprehensive test suites** covering all attack vectors
9. **Understand defense-in-depth** approaches

## Reentrancy Attack Types

### 1. Single-Function Reentrancy (Basic)

**CONNECTION TO PROJECT 07**:
We learned about basic reentrancy in Project 07. Here we dive deeper into advanced patterns!

The classic DAO attack pattern where a function is reentered before state updates:

```solidity
function withdraw(uint amount) external {
    require(balances[msg.sender] >= amount);  // CHECK ✅
    // ❌ VULNERABLE: External call before state update
    (bool success,) = msg.sender.call{value: amount}("");  // INTERACTION FIRST!
    require(success);
    balances[msg.sender] -= amount; // ❌ EFFECT TOO LATE!
}
```

**DETAILED ATTACK FLOW** (from Project 07 knowledge):

```
Call Stack Visualization:
┌─────────────────────────────────────────┐
│ withdraw(100) - First Call              │
│   ↓                                      │
│ Check: balance >= 100 ✅                 │ ← Passes
│   ↓                                      │
│ External call: send 100 ETH             │ ← Attacker receives ETH
│   ↓                                      │
│ [ATTACKER'S RECEIVE() EXECUTES]         │ ← Re-enters contract!
│   ↓                                      │
│ withdraw(100) - Second Call             │ ← Reentrant call!
│   ↓                                      │
│ Check: balance >= 100 ✅                 │ ← STILL PASSES! (not updated!)
│   ↓                                      │
│ External call: send 100 ETH             │ ← More ETH sent!
│   ↓                                      │
│ [ATTACKER'S RECEIVE() EXECUTES AGAIN]   │ ← Can repeat!
│   ↓                                      │
│ ... (continues until contract drained)  │
│   ↓                                      │
│ Finally: balance -= 100                 │ ← Too late! Already drained
└─────────────────────────────────────────┘
```

**WHY IT WORKS**:
- State updated AFTER external call
- Reentrant call sees old state
- Can drain contract before state updates

**THE FIX** (Checks-Effects-Interactions from Project 07):
```solidity
function withdraw(uint amount) external {
    require(balances[msg.sender] >= amount);  // CHECK ✅
    balances[msg.sender] -= amount;           // EFFECT FIRST! ✅
    (bool success,) = msg.sender.call{value: amount}("");  // INTERACTION LAST ✅
    require(success);
}
```

### 2. Multi-Function Reentrancy (Cross-Function)

Reentering through a DIFFERENT function than the one being exploited:

```solidity
function withdraw(uint amount) external {
    require(balances[msg.sender] >= amount);
    (bool success,) = msg.sender.call{value: amount}("");
    require(success);
    balances[msg.sender] -= amount;
}

function transfer(address to, uint amount) external {
    require(balances[msg.sender] >= amount);
    balances[msg.sender] -= amount;
    balances[to] += amount;
}
```

**Attack Flow:**
1. Call withdraw(100)
2. During ETH transfer callback, call transfer(attacker2, 100)
3. Balance is still 100, so transfer succeeds
4. Then withdraw completes, subtracting balance
5. Result: Withdrew 100 + transferred 100 with only 100 balance

**Why It's Dangerous:**
- Each function individually looks safe (updates state)
- The vulnerability emerges from SHARED state
- Harder to detect with basic pattern matching

### 3. Cross-Contract Reentrancy

Reentering Contract A through Contract B:

```
User → ContractA.deposit()
  → ContractB.callback()
    → ContractA.withdraw()  // Reentrancy!
```

**Example Scenario:**
```solidity
// Vault contract
function deposit() external payable {
    balances[msg.sender] += msg.value;
    // Notify rewards contract
    rewardsContract.notifyDeposit(msg.sender, msg.value);
}

// Rewards contract
function notifyDeposit(address user, uint amount) external {
    // Attacker's receive() function can now call Vault.withdraw()
    (bool success,) = user.call("");
}
```

**Attack Flow:**
1. Attacker calls Vault.deposit()
2. Vault updates balance, then calls Rewards.notifyDeposit()
3. Rewards calls attacker's contract
4. Attacker's receive() calls Vault.withdraw()
5. Vault balance hasn't been "locked" yet
6. Withdraw succeeds, then deposit completes

**Why It's Dangerous:**
- State updates happen in correct order WITHIN each contract
- The reentrancy path goes through an external contract
- Traditional mutex guards might not catch it
- Requires analyzing entire call graph

### 4. Read-Only Reentrancy

Exploiting inconsistent state visible through VIEW functions:

```solidity
contract Vault {
    uint public totalSupply;
    mapping(address => uint) public balances;

    function withdraw(uint amount) external {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount; // Updated
        (bool success,) = msg.sender.call{value: amount}("");
        require(success);
        totalSupply -= amount; // NOT YET UPDATED during callback
    }

    function getPrice() public view returns (uint) {
        return (address(this).balance * 1e18) / totalSupply;
    }
}

contract Oracle {
    function getVaultPrice() external view returns (uint) {
        return vault.getPrice(); // Uses inconsistent state!
    }
}
```

**Attack Flow:**
1. Vault has 100 ETH, 100 totalSupply (price = 1 ETH)
2. Attacker calls withdraw(50)
3. Vault updates balances[attacker] (50 → 0)
4. Vault sends 50 ETH to attacker
5. During callback, attacker calls Oracle.getVaultPrice()
6. Vault balance = 50 ETH, but totalSupply still = 100
7. Oracle returns price = 0.5 ETH (WRONG!)
8. Attacker uses this to exploit lending protocol, etc.

**Why It's Dangerous:**
- No state is being WRITTEN during reentrancy
- View functions seem "safe"
- Leads to oracle manipulation attacks
- Cream Finance lost $130M to this in 2021

### 5. Multi-Hop Reentrancy Chains

Creating complex call chains: A → B → C → A

```
1. User calls ContractA.action()
2. ContractA calls ContractB.process()
3. ContractB calls ContractC.verify()
4. ContractC triggers callback to User
5. User reenters ContractA.action() again
```

**Why It's Dangerous:**
- Each individual hop might be "safe"
- The vulnerability emerges from the CHAIN
- Extremely difficult to audit
- Can bypass per-contract reentrancy guards

## Real-World Case Studies

### Case Study 1: The DAO (2016)

**Amount Lost:** $60 million (3.6M ETH)

**Vulnerability:** Basic single-function reentrancy

**Code:**
```solidity
function withdraw(uint _amount) {
    if (balances[msg.sender] >= _amount) {
        if (msg.sender.call.value(_amount)()) {
            balances[msg.sender] -= _amount;
        }
    }
}
```

**Impact:**
- Led to Ethereum hard fork (ETH/ETC split)
- Changed smart contract security forever
- Introduced Checks-Effects-Interactions pattern

### Case Study 2: Cream Finance (2021)

**Amount Lost:** $130 million

**Vulnerability:** Read-only reentrancy via ERC777 tokens

**Attack Flow:**
1. Cream used Curve LP tokens as collateral
2. Curve's `balanceOf()` could be reentered via ERC777 hooks
3. During withdrawal, balances were inconsistent
4. Attacker borrowed against inflated collateral value
5. Drained multiple pools

**Key Insight:** View functions can be exploited if they read inconsistent state!

### Case Study 3: Curve/Vyper Reentrancy (2023)

**Amount Lost:** $52 million

**Vulnerability:** Vyper compiler bug - reentrancy guards ineffective

**Details:**
- Vyper 0.2.15-0.3.0 had broken reentrancy guards
- Multiple Curve pools affected
- Even "protected" functions were vulnerable
- Never trust compiler features blindly

### Case Study 4: Lendf.Me (2020)

**Amount Lost:** $25 million

**Vulnerability:** ERC777 reentrancy during supply/borrow

**Attack Pattern:**
```
1. Supply ERC777 tokens as collateral
2. During supply callback, borrow against the collateral
3. Collateral not yet fully recorded
4. Over-borrow beyond collateral value
```

**Lesson:** Be extremely careful with tokens that have hooks (ERC777, ERC1155)

## Defense Strategies

### Level 1: Checks-Effects-Interactions (CEI)

The foundational pattern:

```solidity
function withdraw(uint amount) external {
    // CHECKS
    require(balances[msg.sender] >= amount);

    // EFFECTS
    balances[msg.sender] -= amount;
    totalSupply -= amount; // Update ALL state!

    // INTERACTIONS
    (bool success,) = msg.sender.call{value: amount}("");
    require(success);
}
```

**Limitations:**
- Only protects single function
- Doesn't prevent cross-function reentrancy
- Doesn't prevent read-only reentrancy

### Level 2: Reentrancy Guards (Mutex)

```solidity
uint private _status = 1; // 1 = NOT_ENTERED, 2 = ENTERED

modifier nonReentrant() {
    require(_status != 2, "ReentrancyGuard: reentrant call");
    _status = 2;
    _;
    _status = 1;
}

function withdraw(uint amount) external nonReentrant {
    // Function body
}
```

**Advantages:**
- Protects against cross-function reentrancy
- Simple to implement
- Gas efficient

**Limitations:**
- Must be applied to ALL vulnerable functions
- Doesn't prevent cross-contract reentrancy
- Doesn't prevent read-only reentrancy

### Level 3: Pull Payment Pattern

```solidity
mapping(address => uint) public pendingWithdrawals;

function withdraw(uint amount) external {
    require(balances[msg.sender] >= amount);
    balances[msg.sender] -= amount;
    pendingWithdrawals[msg.sender] += amount;
}

function claimWithdrawal() external {
    uint amount = pendingWithdrawals[msg.sender];
    pendingWithdrawals[msg.sender] = 0;
    (bool success,) = msg.sender.call{value: amount}("");
    require(success);
}
```

**Advantages:**
- Completely isolates state changes from external calls
- Users pull funds rather than contract pushing

**Limitations:**
- Requires two transactions
- More gas for users
- Doesn't prevent read-only reentrancy

### Level 4: Global Reentrancy Guard

For cross-contract reentrancy:

```solidity
contract ReentrancyGuardRegistry {
    mapping(address => bool) public locked;

    modifier globalGuard() {
        require(!locked[tx.origin], "Global reentrancy");
        locked[tx.origin] = true;
        _;
        locked[tx.origin] = false;
    }
}

// Both contracts use the same registry
contract VaultA {
    function action() external globalGuard {
        // Safe from cross-contract reentrancy
    }
}

contract VaultB {
    function action() external globalGuard {
        // Safe from cross-contract reentrancy
    }
}
```

**Advantages:**
- Protects entire ecosystem
- Catches cross-contract attacks

**Limitations:**
- Complex to implement
- Still doesn't prevent read-only reentrancy
- Can block legitimate multi-contract interactions

### Level 5: Read-Only Reentrancy Protection

```solidity
uint private _status = 1;

modifier nonReentrant() {
    require(_status != 2);
    _status = 2;
    _;
    _status = 1;
}

modifier nonReentrantView() {
    require(_status != 2, "Cannot read during reentrancy");
    _;
}

function withdraw(uint amount) external nonReentrant {
    balances[msg.sender] -= amount;
    totalSupply -= amount; // CRITICAL: Update before external call
    (bool success,) = msg.sender.call{value: amount}("");
    require(success);
}

function getPrice() public view nonReentrantView returns (uint) {
    return (address(this).balance * 1e18) / totalSupply;
}
```

**Key Points:**
- View functions check the guard too
- All state must be consistent before external calls
- Prevents oracle manipulation

### Level 6: The Ultimate Pattern

Combining all strategies:

```solidity
contract SecureVault is ReentrancyGuard {
    using SafeERC20 for IERC20;

    mapping(address => uint) private _balances; // Private to enforce getter
    uint private _totalSupply;

    // WRITE operations
    function withdraw(uint amount) external nonReentrant {
        // CHECKS
        require(_balances[msg.sender] >= amount, "Insufficient balance");

        // EFFECTS - Update ALL state first
        _balances[msg.sender] -= amount;
        _totalSupply -= amount;

        // INTERACTIONS - External calls last
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    // READ operations - protected view
    function balanceOf(address account) external view nonReentrantView returns (uint) {
        return _balances[account];
    }

    function totalSupply() external view nonReentrantView returns (uint) {
        return _totalSupply;
    }

    function getPrice() external view nonReentrantView returns (uint) {
        if (_totalSupply == 0) return 0;
        return (address(this).balance * 1e18) / _totalSupply;
    }
}
```

## Lab Exercises

### Exercise 1: Multi-Function Reentrancy

**Goal:** Exploit the Bank contract by reentering through transfer() during withdraw()

**Vulnerable Contract:** `VulnerableBank` in Project31.sol

**Task:**
1. Study how withdraw() and transfer() share the `balances` mapping
2. Create an attacker contract that:
   - Calls withdraw()
   - During the callback, calls transfer() to move funds
   - Extracts more value than deposited
3. Write a test demonstrating the exploit

### Exercise 2: Cross-Contract Reentrancy

**Goal:** Exploit the Vault through the Router contract

**Vulnerable Contracts:** `VulnerableVault` and `RewardsRouter`

**Task:**
1. Understand the deposit → notifyRewards → callback chain
2. Create an attacker that reenters vault during rewards notification
3. Drain funds using cross-contract reentrancy

### Exercise 3: Read-Only Reentrancy

**Goal:** Manipulate the Oracle by exploiting view functions during reentrancy

**Vulnerable Contract:** `VulnerableOracle`

**Task:**
1. Identify inconsistent state windows
2. Create an attack that exploits getPrice() during withdrawal
3. Use the manipulated price to profit in a lending scenario

### Exercise 4: Multi-Hop Chain

**Goal:** Build a complex A → B → C → A attack chain

**Task:**
1. Create a 3-hop reentrancy path
2. Demonstrate how single-contract guards fail
3. Show the entire call stack

### Exercise 5: Fix Everything

**Goal:** Secure all contracts against advanced reentrancy

**Task:**
1. Apply appropriate guards
2. Implement CEI pattern correctly
3. Protect view functions
4. Write tests proving security

## Running the Lab

```bash
# Install dependencies
forge install

# Run all tests
forge test -vvv

# Run specific test
forge test --match-test testMultiFunctionReentrancy -vvvv

# See gas costs
forge test --gas-report

# Deploy locally
forge script script/DeployProject31.s.sol --fork-url http://localhost:8545 --broadcast
```

## Key Takeaways

1. **Reentrancy is not just about one function** - Consider the entire contract state
2. **View functions can be exploited** - Read-only reentrancy is real
3. **Cross-contract interactions are dangerous** - Think about the entire call graph
4. **Defense in depth** - Use multiple protection layers
5. **Test everything** - Write comprehensive attack simulations
6. **Real audits matter** - These vulnerabilities are subtle

## Advanced Topics

### Gas Optimization vs Security

Reentrancy guards cost gas. When is the tradeoff worth it?

```solidity
// More gas, more secure
function withdraw(uint amount) external nonReentrant {
    // ...
}

// Less gas, requires perfect CEI
function withdraw(uint amount) external {
    // Must be perfect...
}
```

### Reentrancy in DeFi Protocols

- **AMMs:** Price manipulation via read-only reentrancy
- **Lending:** Collateral valuation attacks
- **Yield Farms:** Reward calculation exploits
- **Bridges:** Cross-chain reentrancy (even more complex!)

### Future Threats

- **Account Abstraction:** New reentrancy vectors via ERC-4337
- **Cross-chain:** Reentrancy across different chains
- **MEV:** Reentrancy combined with sandwich attacks
- **AI-discovered exploits:** Automated vulnerability finding

## Resources

- [Consensys Smart Contract Best Practices](https://consensys.github.io/smart-contract-best-practices/)
- [SWC-107: Reentrancy](https://swcregistry.io/docs/SWC-107)
- [Curve Read-Only Reentrancy Analysis](https://chainsecurity.com/curve-lp-oracle-manipulation-post-mortem/)
- [OpenZeppelin ReentrancyGuard](https://docs.openzeppelin.com/contracts/4.x/api/security#ReentrancyGuard)

## Conclusion

Advanced reentrancy attacks are among the most dangerous vulnerabilities in smart contracts. Understanding these patterns is essential for:

- Writing secure contracts
- Auditing DeFi protocols
- Designing safe cross-contract interactions
- Building robust oracle systems

Master these concepts, and you'll be well-equipped to handle real-world smart contract security.
