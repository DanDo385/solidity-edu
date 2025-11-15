# Learning Guide: Advanced Reentrancy Lab

Welcome to Project 31! This guide will help you navigate the advanced reentrancy lab effectively.

## Prerequisites

Before starting this lab, you should:

1. Complete Project 07 (Basic Reentrancy and Security)
2. Understand the Checks-Effects-Interactions (CEI) pattern
3. Be familiar with Ethereum's call stack and execution model
4. Know how to use Foundry for testing

## Lab Structure

```
31-reentrancy-lab/
├── README.md                       # Comprehensive theory and case studies
├── LEARNING_GUIDE.md              # This file - practical walkthrough
├── src/
│   ├── Project31.sol              # Vulnerable contracts with TODOs
│   └── solution/
│       └── Project31Solution.sol  # Complete solutions
├── test/
│   └── Project31.t.sol            # Comprehensive test suite
└── script/
    └── DeployProject31.s.sol      # Deployment scripts
```

## Learning Path

### Phase 1: Theory (1-2 hours)

1. **Read README.md thoroughly**
   - Focus on understanding each attack type
   - Study the real-world case studies
   - Note the differences from basic reentrancy

2. **Key Concepts to Master:**
   - Multi-function reentrancy vs single-function
   - Cross-contract reentrancy attack paths
   - Read-only reentrancy and oracle manipulation
   - Multi-hop attack chains

### Phase 2: Exploration (2-3 hours)

1. **Study Vulnerable Contracts**

   Start with `src/Project31.sol`:

   ```bash
   # Open the file and read each vulnerable contract
   # Pay attention to:
   # - Where external calls happen
   # - What state is shared between functions
   # - What view functions expose
   ```

2. **Identify Vulnerabilities**

   For each contract, answer:
   - What is the attack vector?
   - What state is exposed during reentrancy?
   - How can an attacker profit?
   - What makes this different from basic reentrancy?

3. **Exercise Workflow:**

   ```
   VulnerableBank (Multi-Function):
   ├─ Read withdraw() function
   ├─ Read transfer() function
   ├─ Identify shared state (balances mapping)
   ├─ Map the attack flow
   └─ Complete MultiFunctionAttacker template
   ```

### Phase 3: Hands-On Exploitation (3-4 hours)

#### Exercise 1: Multi-Function Reentrancy

**Goal:** Complete `MultiFunctionAttacker` in `src/Project31.sol`

1. **Study the vulnerability:**
   ```solidity
   // In withdraw(): external call before state update
   // In transfer(): uses same balances mapping
   // Attack: Call transfer() during withdraw() callback
   ```

2. **Implement the attacker:**
   - Complete `attack()` function
   - Complete `receive()` function
   - Think about: When to call transfer()?

3. **Test your attack:**
   ```bash
   forge test --match-test testMultiFunctionReentrancy -vvvv
   ```

4. **Questions to answer:**
   - How much can you extract?
   - Why doesn't Solidity 0.8+ underflow protection stop this?
   - What if there were more functions sharing the balance?

#### Exercise 2: Cross-Contract Reentrancy

**Goal:** Complete `CrossContractAttacker`

1. **Map the call path:**
   ```
   Your Attack → Vault.deposit()
              → Router.notifyDeposit()
              → Your receive()
              → Vault.withdraw() [REENTRY]
   ```

2. **Implement the attacker:**
   - Deposit to trigger the chain
   - Withdraw during the callback
   - Timing is everything!

3. **Test:**
   ```bash
   forge test --match-test testCrossContractReentrancy -vvvv
   ```

4. **Advanced challenge:**
   - Can you drain more than you deposited?
   - What if multiple users have deposited?

#### Exercise 3: Read-Only Reentrancy

**Goal:** Complete `ReadOnlyAttacker` to manipulate oracle price

1. **Understand the vulnerability:**
   ```solidity
   // During withdraw:
   // 1. User balance -= amount (updated)
   // 2. ETH transferred (callback happens)
   // 3. totalSupply -= amount (NOT YET UPDATED)

   // During callback:
   // getPrice() = balance / totalSupply
   // Balance is low, totalSupply is high
   // Price appears artificially low!
   ```

2. **Implement the attack:**
   - Setup: Deposit to oracle and lender
   - Attack: Trigger withdraw to manipulate price
   - Exploit: Use manipulated price somehow

3. **Test:**
   ```bash
   forge test --match-test testReadOnlyReentrancy -vvvv
   ```

4. **Real-world connection:**
   - This is how Cream Finance was exploited!
   - Read the case study in README.md
   - Think about how lending protocols use oracles

#### Exercise 4: Multi-Hop Reentrancy

**Goal:** Complete `MultiHopAttacker` for 3-hop chain

1. **Visualize the chain:**
   ```
   A.processAction()
   → B.processB()
   → C.processC()
   → Attacker.receive()
   → A.withdraw() [REENTRY]
   ```

2. **Implement:**
   - Trigger the chain
   - Reenter at the right moment
   - Exploit the timing window

3. **Test:**
   ```bash
   forge test --match-test testMultiHopReentrancy -vvvv
   ```

### Phase 4: Defense Analysis (2-3 hours)

1. **Study Secure Implementations**

   Compare `VulnerableBankSolution` vs `SecureBankSolution`:

   ```solidity
   // Vulnerable:
   function withdraw(uint amount) external {
       require(balances[msg.sender] >= amount);
       msg.sender.call{value: amount}("");  // External call
       balances[msg.sender] -= amount;      // State update AFTER
   }

   // Secure:
   function withdraw(uint amount) external nonReentrant {
       require(_balances[msg.sender] >= amount);
       _balances[msg.sender] -= amount;     // State update FIRST
       msg.sender.call{value: amount}("");  // External call AFTER
   }
   ```

2. **Test Defense Effectiveness:**
   ```bash
   forge test --match-test Blocked -vvv
   ```

3. **Understand Each Defense:**
   - **CEI Pattern:** Prevents basic reentrancy
   - **Reentrancy Guard:** Prevents cross-function reentrancy
   - **View Guard:** Prevents read-only reentrancy
   - **Global Guard:** Prevents cross-contract reentrancy

4. **Gas Analysis:**
   ```bash
   forge test --gas-report
   ```
   - How much does security cost?
   - Is it worth it?

### Phase 5: Testing & Validation (1-2 hours)

1. **Run all tests:**
   ```bash
   # Basic run
   forge test

   # Verbose output
   forge test -vvv

   # Very verbose with trace
   forge test -vvvv

   # Specific test
   forge test --match-test testMultiFunctionReentrancy -vvvv
   ```

2. **Understand test output:**
   - Green = Test passed
   - Red = Test failed
   - Look for event emissions
   - Check balance changes
   - Analyze gas costs

3. **Write your own tests:**
   - Can you exploit the vulnerabilities differently?
   - What edge cases exist?
   - Add tests to `test/Project31.t.sol`

### Phase 6: Real-World Application (Ongoing)

1. **Case Study Deep Dives:**
   - The DAO (2016) - READ: Original analysis
   - Cream Finance (2021) - WATCH: Post-mortem videos
   - Curve/Vyper (2023) - READ: Technical reports

2. **Practice Security Reviews:**
   - Review DeFi protocols on GitHub
   - Look for reentrancy vulnerabilities
   - Check if guards are properly applied

3. **Build Secure Contracts:**
   - Apply learned patterns to your own projects
   - Use OpenZeppelin's ReentrancyGuard
   - Always follow CEI pattern

## Common Mistakes & Pitfalls

### Mistake 1: Thinking CEI is Enough

```solidity
// This looks safe (CEI pattern):
function withdraw(uint amount) external {
    balances[msg.sender] -= amount;  // Effect first
    msg.sender.call{value: amount}("");  // Interaction last
}

function transfer(address to, uint amount) external {
    balances[msg.sender] -= amount;  // Effect first
    balances[to] += amount;
}

// But still vulnerable to cross-function reentrancy!
// withdraw() → receive() → transfer() still works
```

**Lesson:** CEI protects individual functions, not the whole contract.

### Mistake 2: Forgetting View Functions

```solidity
// Secure state-changing function:
function withdraw(uint amount) external nonReentrant {
    balances[msg.sender] -= amount;
    totalSupply -= amount;
    msg.sender.call{value: amount}("");
}

// But unprotected view function:
function getPrice() external view returns (uint) {
    return balance / totalSupply;  // Inconsistent during withdraw!
}
```

**Lesson:** Protect view functions too!

### Mistake 3: Trusting External Contracts

```solidity
// Looks safe:
function deposit() external payable nonReentrant {
    balances[msg.sender] += msg.value;
    rewardContract.notify(msg.sender);  // External call
}

// But if rewardContract is malicious or calls back:
// You have cross-contract reentrancy!
```

**Lesson:** External calls create reentrancy vectors, even with guards.

## Quick Reference

### Attack Checklist

When analyzing a contract, check for:

- [ ] External calls (`.call`, `.transfer`, `.send`)
- [ ] State updates after external calls
- [ ] Multiple functions sharing state
- [ ] External contract interactions
- [ ] View functions reading mutable state
- [ ] Callbacks and hooks

### Defense Checklist

When securing a contract, ensure:

- [ ] All state updates before external calls (CEI)
- [ ] `nonReentrant` modifier on vulnerable functions
- [ ] View functions protected or state consistent
- [ ] External contracts trusted or calls isolated
- [ ] Comprehensive test coverage
- [ ] Professional security audit

## Testing Tips

### Debugging Failed Tests

```bash
# See detailed logs
forge test -vvvv

# See specific test
forge test --match-test testName -vvvv

# See gas usage
forge test --gas-report

# Check coverage
forge coverage
```

### Reading Traces

```
[PASS] testMultiFunctionReentrancy() (gas: 123456)
Traces:
  [123456] Project31Test::testMultiFunctionReentrancy()
    ├─ [45678] MultiFunctionAttacker::attack{value: 5000000000000000000}()
    │   ├─ [12345] VulnerableBank::deposit{value: 5000000000000000000}()
    │   │   └─ ← ()
    │   ├─ [98765] VulnerableBank::withdraw(5000000000000000000)
    │   │   ├─ [0] MultiFunctionAttacker::receive{value: 5000000000000000000}()
    │   │   │   ├─ [5000] VulnerableBank::transfer(accomplice, 5000000000000000000)
    │   │   │   │   └─ ← ()
    │   │   │   └─ ← ()
    │   │   └─ ← ()
    │   └─ ← ()
    └─ ← ()
```

This shows the entire call stack!

## Next Steps

After completing this lab:

1. **Build Your Own Vulnerable Contract**
   - Create a new vulnerability pattern
   - Test it thoroughly
   - Then secure it

2. **Audit a Real Project**
   - Find an open-source DeFi project
   - Analyze for reentrancy vulnerabilities
   - Submit findings responsibly

3. **Advanced Topics**
   - Cross-chain reentrancy
   - ERC-777 and ERC-1155 hooks
   - Account abstraction reentrancy
   - MEV + reentrancy combinations

4. **Stay Updated**
   - Follow security researchers on Twitter
   - Read post-mortems of new exploits
   - Join security Discord communities
   - Participate in audit contests (Code4rena, Sherlock)

## Resources

### Must-Read

- [Consensys Smart Contract Best Practices](https://consensys.github.io/smart-contract-best-practices/)
- [SWC Registry: Reentrancy](https://swcregistry.io/docs/SWC-107)
- [OpenZeppelin Security Documentation](https://docs.openzeppelin.com/contracts/4.x/api/security)

### Tools

- [Slither](https://github.com/crytic/slither) - Static analysis
- [Mythril](https://github.com/ConsenSys/mythril) - Security analysis
- [Echidna](https://github.com/crytic/echidna) - Fuzzing

### Communities

- [Ethereum Security Discord](https://discord.gg/ethereum-security)
- [OpenZeppelin Forum](https://forum.openzeppelin.com/)
- [r/ethdev](https://reddit.com/r/ethdev)

## Questions & Challenges

### Quiz Yourself

1. What's the difference between single-function and multi-function reentrancy?
2. Why doesn't a reentrancy guard on one contract prevent cross-contract reentrancy?
3. How can a view function be exploited if it doesn't modify state?
4. What makes multi-hop reentrancy harder to detect than simple reentrancy?
5. When is CEI pattern alone insufficient?

### Advanced Challenges

1. **Create a 4-hop reentrancy chain** (A → B → C → D → A)
2. **Exploit read-only reentrancy for profit** in a complex DeFi scenario
3. **Bypass a reentrancy guard** (hint: think about delegatecall)
4. **Combine reentrancy with integer overflow** (in older Solidity)
5. **Design a global reentrancy protection system** for multiple contracts

## Getting Help

Stuck? Here's how to get help:

1. **Re-read the theory** in README.md
2. **Study the solution** in `src/solution/Project31Solution.sol`
3. **Run tests with -vvvv** to see detailed execution
4. **Check the case studies** for real-world examples
5. **Ask in the community** (provide details about what you've tried)

## Conclusion

Mastering advanced reentrancy is crucial for:
- Building secure smart contracts
- Auditing DeFi protocols
- Understanding complex exploits
- Protecting user funds

Take your time, experiment, and most importantly: **think like an attacker** to defend like a pro!

Happy hacking! 🔒
