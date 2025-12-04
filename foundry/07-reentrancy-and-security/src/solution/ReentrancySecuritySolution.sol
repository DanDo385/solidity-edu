// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title VulnerableBank
 * @notice INTENTIONALLY VULNERABLE contract for educational purposes
 * DO NOT USE IN PRODUCTION
 */
contract VulnerableBank {
    mapping(address => uint256) public balances;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    
    function deposit() public payable {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    // ❌ VULNERABLE: External call before state update
    function withdrawVulnerable(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        // DANGER: External call before updating state
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        // TOO LATE: Attacker already re-entered
        balances[msg.sender] -= amount;
        emit Withdrawal(msg.sender, amount);
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. CHECKS-EFFECTS-INTERACTIONS PATTERN IS CRITICAL
 *    ✅ Step 1: CHECKS - Validate conditions first
 *    ✅ Step 2: EFFECTS - Update state second
 *    ✅ Step 3: INTERACTIONS - External calls last
 *    ✅ Prevents reentrancy attacks
 *    ✅ Used by ALL secure contracts (Uniswap, Aave, Compound)
 *
 * 2. REENTRANCY ATTACKS ARE STILL COMMON
 *    ✅ $60M The DAO hack (2016)
 *    ✅ Still happening in DeFi today
 *    ✅ Can drain entire contracts
 *    ✅ Always follow CEI pattern!
 *
 * 3. UPDATE STATE BEFORE EXTERNAL CALLS
 *    ✅ If state updated first, re-entered calls fail
 *    ✅ If external call first, attacker can drain contract
 *    ✅ Order matters! Effects before Interactions!
 *
 * 4. USE REENTRANCYGUARD FOR COMPLEX CONTRACTS
 *    ✅ OpenZeppelin ReentrancyGuard modifier
 *    ✅ Adds ~2,300 gas overhead
 *    ✅ Protects against cross-function reentrancy
 *    ✅ Use when multiple functions modify same state
 *
 * 5. TEST ATTACKS TO VERIFY SECURITY
 *    ✅ Write attack contracts to test vulnerabilities
 *    ✅ Verify attacks fail on secure implementations
 *    ✅ Understand how attacks work to prevent them
 *
 * 6. EVERY EXTERNAL CALL IS A RISK
 *    ✅ ETH transfers (.call{value:})
 *    ✅ Contract calls (other contracts)
 *    ✅ Delegate calls (proxy patterns)
 *    ✅ Always follow CEI pattern!
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMMON MISTAKES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ❌ External calls before state updates (reentrancy vulnerability)
 * ❌ Not using CEI pattern for state-changing functions
 * ❌ Forgetting ReentrancyGuard on complex contracts
 * ❌ Not testing reentrancy attacks
 * ❌ Cross-function reentrancy (harder to detect)
 * ❌ Assuming internal functions are safe (they're not!)
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          NEXT STEPS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * • Study real-world reentrancy attacks (The DAO, Lendf.me)
 * • Explore cross-function reentrancy patterns
 * • Learn about flash loan attacks
 * • Move to Project 08 to learn about ERC20 tokens
 */

/**
 * @title SecureBank
 * @notice SECURE implementation using Checks-Effects-Interactions pattern
 * 
 * REAL-WORLD ANALOGY: CEI pattern is like a bank teller - they check your ID
 * (checks), update your account balance (effects), THEN give you cash
 * (interactions). This prevents someone from withdrawing more than they have.
 * 
 * GAS OPTIMIZATION: Why CEI pattern saves gas?
 * - Vulnerable version: Attacker can drain contract, wasting gas on failed transactions
 * - Secure version: State updated first, preventing reentrancy loops
 * - Gas saved: Prevents infinite loops that could drain gas limit
 * 
 * SECURITY: CEI pattern prevents reentrancy attacks
 * - Update state BEFORE external calls
 * - Prevents attacker from re-entering with old state
 * - Critical for functions that send ETH or call external contracts
 */
contract SecureBank {
    mapping(address => uint256) public balances;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    
    /**
     * @notice Deposit ETH into the bank
     * 
     * GAS COST:
     * - SLOAD balance: ~100 gas (warm)
     * - SSTORE balance: ~5,000 gas (warm, non-zero to non-zero)
     * - Event: ~1,500 gas
     * - Total: ~6,600 gas
     */
    function deposit() public payable {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    /**
     * @notice Withdraw ETH from the bank (SECURE)
     * @param amount Amount to withdraw in wei
     *
     * @dev ⚠️  CRITICAL SECURITY FUNCTION: Checks-Effects-Interactions Pattern
     * ═══════════════════════════════════════════════════════════════════════════
     *
     *      This function demonstrates THE most important security pattern in Solidity:
     *      Checks-Effects-Interactions (CEI). This pattern prevents reentrancy attacks!
     *
     *      EXECUTION FLOW:
     *      ┌─────────────────────────────────────────┐
     *      │ 1. CHECKS: Validate all conditions       │
     *      │    - Check balance >= amount              │
     *      │    - Fail early if invalid                │
     *      │    ↓                                      │
     *      │ 2. EFFECTS: Update state                  │
     *      │    - Decrease balance in storage          │
     *      │    - State updated BEFORE external call   │
     *      │    ↓                                      │
     *      │ 3. INTERACTIONS: External calls           │
     *      │    - Send ETH to recipient                │
     *      │    - Emit event                           │
     *      └─────────────────────────────────────────┘
     *
     *      CONNECTION TO PROJECT 02: CEI Pattern!
     *      ═══════════════════════════════════════════
     *
     *      We learned this pattern in Project 02. This is the same pattern,
     *      but now we understand WHY it's critical for security!
     *
     *      WHY THIS ORDER MATTERS:
     *      ┌─────────────────────────────────────────────────────────┐
     *      │ If we call external function FIRST:                    │
     *      │   1. External call executes                            │
     *      │   2. Malicious contract re-enters withdraw()           │
     *      │   3. Balance still has old value!                      │
     *      │   4. Attacker drains contract! 💥                       │
     *      │                                                         │
     *      │ If we update state FIRST:                              │
     *      │   1. Balance updated immediately                       │
     *      │   2. External call executes                            │
     *      │   3. If re-entered, balance already updated            │
     *      │   4. Second call fails (insufficient balance) ✅       │
     *      └─────────────────────────────────────────────────────────┘
     *
     *      GAS COST BREAKDOWN:
     *      ┌─────────────────────┬──────────────┬─────────────────┐
     *      │ Operation           │ Gas (warm)   │ Gas (cold)      │
     *      ├─────────────────────┼──────────────┼─────────────────┤
     *      │ require() check     │ ~3 gas       │ ~3 gas          │
     *      │ SLOAD balance        │ ~100 gas     │ ~2,100 gas      │
     *      │ SSTORE balance       │ ~5,000 gas   │ ~20,000 gas     │
     *      │ .call{value:}()     │ ~2,100 gas   │ ~2,100 gas      │
     *      │ Event emission      │ ~1,500 gas   │ ~1,500 gas      │
     *      ├─────────────────────┼──────────────┼─────────────────┤
     *      │ TOTAL (warm)        │ ~8,703 gas   │                 │
     *      │ TOTAL (cold)        │              │ ~25,703 gas     │
     *      └─────────────────────┴──────────────┴─────────────────┘
     *
     *      REAL-WORLD ANALOGY:
     *      ═══════════════════
     *
     *      Like a bank teller:
     *      - **Checks** = Verify you have enough money
     *      - **Effects** = Update your account balance FIRST
     *      - **Interactions** = Give you cash LAST
     *
     *      If the teller gave you cash first, you could run to another teller
     *      and withdraw again before your balance was updated!
     *
     *      🎓 LEARNING MOMENT:
     *      This pattern is used in EVERY secure contract that handles ETH!
     *      Uniswap, Aave, Compound - they all use Checks-Effects-Interactions.
     *      Understanding this pattern is CRITICAL for secure Solidity development!
     */
    function withdraw(uint256 amount) public {
        // ════════════════════════════════════════════════════════════════════
        // STEP 1: CHECKS - Validate all conditions FIRST
        // ════════════════════════════════════════════════════════════════════
        // CONNECTION TO PROJECT 01: Mapping storage read!
        // Reading from balances mapping: ~100 gas (warm) or ~2,100 gas (cold)
        require(balances[msg.sender] >= amount, "Insufficient balance"); // SLOAD: ~100 gas

        // ════════════════════════════════════════════════════════════════════
        // STEP 2: EFFECTS - Update state BEFORE external interactions
        // ════════════════════════════════════════════════════════════════════
        // CONNECTION TO PROJECT 01: Mapping storage write!
        // CRITICAL: Update balance FIRST to prevent reentrancy attacks
        // If external call re-enters, balance is already updated!
        balances[msg.sender] -= amount; // SSTORE: ~5,000 gas (warm)

        // ════════════════════════════════════════════════════════════════════
        // STEP 3: INTERACTIONS - External calls LAST
        // ════════════════════════════════════════════════════════════════════
        // CONNECTION TO PROJECT 02: Safe ETH transfer!
        // Use .call{value:}() NOT .transfer() or .send()
        // Returns (bool success, bytes data) - we ignore bytes
        (bool success,) = msg.sender.call{value: amount}(""); // ~2,100 gas

        // ⚠️  CRITICAL: Always check return value!
        require(success, "Transfer failed");

        // 📢 EVENT EMISSION: Log the withdrawal
        // CONNECTION TO PROJECT 03: Event emission!
        emit Withdrawal(msg.sender, amount); // ~1,500 gas
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. CHECKS-EFFECTS-INTERACTIONS PATTERN IS CRITICAL
 *    ✅ Step 1: CHECKS - Validate conditions first
 *    ✅ Step 2: EFFECTS - Update state second
 *    ✅ Step 3: INTERACTIONS - External calls last
 *    ✅ Prevents reentrancy attacks
 *    ✅ Used by ALL secure contracts (Uniswap, Aave, Compound)
 *
 * 2. REENTRANCY ATTACKS ARE STILL COMMON
 *    ✅ $60M The DAO hack (2016)
 *    ✅ Still happening in DeFi today
 *    ✅ Can drain entire contracts
 *    ✅ Always follow CEI pattern!
 *
 * 3. UPDATE STATE BEFORE EXTERNAL CALLS
 *    ✅ If state updated first, re-entered calls fail
 *    ✅ If external call first, attacker can drain contract
 *    ✅ Order matters! Effects before Interactions!
 *
 * 4. USE REENTRANCYGUARD FOR COMPLEX CONTRACTS
 *    ✅ OpenZeppelin ReentrancyGuard modifier
 *    ✅ Adds ~2,300 gas overhead
 *    ✅ Protects against cross-function reentrancy
 *    ✅ Use when multiple functions modify same state
 *
 * 5. TEST ATTACKS TO VERIFY SECURITY
 *    ✅ Write attack contracts to test vulnerabilities
 *    ✅ Verify attacks fail on secure implementations
 *    ✅ Understand how attacks work to prevent them
 *
 * 6. EVERY EXTERNAL CALL IS A RISK
 *    ✅ ETH transfers (.call{value:})
 *    ✅ Contract calls (other contracts)
 *    ✅ Delegate calls (proxy patterns)
 *    ✅ Always follow CEI pattern!
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMMON MISTAKES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ❌ External calls before state updates (reentrancy vulnerability)
 * ❌ Not using CEI pattern for state-changing functions
 * ❌ Forgetting ReentrancyGuard on complex contracts
 * ❌ Not testing reentrancy attacks
 * ❌ Cross-function reentrancy (harder to detect)
 * ❌ Assuming internal functions are safe (they're not!)
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          NEXT STEPS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * • Study real-world reentrancy attacks (The DAO, Lendf.me)
 * • Explore cross-function reentrancy patterns
 * • Learn about flash loan attacks
 * • Move to Project 08 to learn about ERC20 tokens
 */

/**
 * @title Attacker
 * @notice Malicious contract that exploits reentrancy
 * FOR EDUCATIONAL PURPOSES ONLY
 */
contract Attacker {
    VulnerableBank public bank;
    uint256 public attackAmount;
    
    constructor(address _bankAddress) {
        bank = VulnerableBank(_bankAddress);
    }
    
    function attack() public payable {
        require(msg.value > 0, "Need ETH to attack");
        attackAmount = msg.value;
        
        bank.deposit{value: msg.value}();
        bank.withdrawVulnerable(msg.value);
    }
    
    // Fallback function - this is where reentrancy happens
    receive() external payable {
        if (address(bank).balance >= attackAmount) {
            bank.withdrawVulnerable(attackAmount);
        }
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. CHECKS-EFFECTS-INTERACTIONS PATTERN IS CRITICAL
 *    ✅ Step 1: CHECKS - Validate conditions first
 *    ✅ Step 2: EFFECTS - Update state second
 *    ✅ Step 3: INTERACTIONS - External calls last
 *    ✅ Prevents reentrancy attacks
 *    ✅ Used by ALL secure contracts (Uniswap, Aave, Compound)
 *
 * 2. REENTRANCY ATTACKS ARE STILL COMMON
 *    ✅ $60M The DAO hack (2016)
 *    ✅ Still happening in DeFi today
 *    ✅ Can drain entire contracts
 *    ✅ Always follow CEI pattern!
 *
 * 3. UPDATE STATE BEFORE EXTERNAL CALLS
 *    ✅ If state updated first, re-entered calls fail
 *    ✅ If external call first, attacker can drain contract
 *    ✅ Order matters! Effects before Interactions!
 *
 * 4. USE REENTRANCYGUARD FOR COMPLEX CONTRACTS
 *    ✅ OpenZeppelin ReentrancyGuard modifier
 *    ✅ Adds ~2,300 gas overhead
 *    ✅ Protects against cross-function reentrancy
 *    ✅ Use when multiple functions modify same state
 *
 * 5. TEST ATTACKS TO VERIFY SECURITY
 *    ✅ Write attack contracts to test vulnerabilities
 *    ✅ Verify attacks fail on secure implementations
 *    ✅ Understand how attacks work to prevent them
 *
 * 6. EVERY EXTERNAL CALL IS A RISK
 *    ✅ ETH transfers (.call{value:})
 *    ✅ Contract calls (other contracts)
 *    ✅ Delegate calls (proxy patterns)
 *    ✅ Always follow CEI pattern!
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMMON MISTAKES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ❌ External calls before state updates (reentrancy vulnerability)
 * ❌ Not using CEI pattern for state-changing functions
 * ❌ Forgetting ReentrancyGuard on complex contracts
 * ❌ Not testing reentrancy attacks
 * ❌ Cross-function reentrancy (harder to detect)
 * ❌ Assuming internal functions are safe (they're not!)
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          NEXT STEPS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * • Study real-world reentrancy attacks (The DAO, Lendf.me)
 * • Explore cross-function reentrancy patterns
 * • Learn about flash loan attacks
 * • Move to Project 08 to learn about ERC20 tokens
 */
