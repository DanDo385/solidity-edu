// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Project 32 Solution: Integer Overflow Labs
 * @notice Complete solution demonstrating overflow/underflow vulnerabilities and protections
 * @dev This solution uses Solidity 0.8.20 but simulates pre-0.8 behavior with unchecked blocks
 *
 * This file contains:
 * 1. Vulnerable contracts simulating pre-0.8.0 behavior
 * 2. Complete SafeMath library implementation
 * 3. Safe contracts using SafeMath
 * 4. Modern contracts using 0.8+ automatic checks
 * 5. Examples of safe and unsafe unchecked usage
 */

// ============================================================================
// PART 1: VULNERABLE TOKEN (PRE-0.8 SIMULATION)
// ============================================================================

/**
 * @notice Vulnerable token contract simulating pre-0.8.0 behavior
 * @dev Uses unchecked blocks to demonstrate overflow/underflow vulnerabilities
 *
 * VULNERABILITIES:
 * 1. transfer() - Underflow on sender balance, overflow on recipient balance
 * 2. batchTransfer() - Overflow in total amount calculation (BeautyChain exploit)
 * 3. transferProxy() - Overflow in fee calculation (SMT token exploit)
 */
contract VulnerableToken {
    mapping(address => uint256) public balances;
    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(uint256 initialSupply) {
        balances[msg.sender] = initialSupply;
        totalSupply = initialSupply;
    }

    /**
     * @notice Vulnerable transfer function with unchecked arithmetic
     * @dev VULNERABILITY: No checks for underflow/overflow
     *
     * EXPLOIT SCENARIO:
     * 1. Attacker has 0 tokens
     * 2. Calls transfer(victim, 1)
     * 3. balances[attacker] = 0 - 1 = 2^256 - 1 (underflow!)
     * 4. Attacker now has max uint256 tokens
     */
    function transfer(address to, uint256 amount) public returns (bool) {
        unchecked {
            // No check: allows sender balance to underflow
            balances[msg.sender] -= amount;

            // No check: allows recipient balance to overflow
            balances[to] += amount;
        }
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @notice Vulnerable batch transfer (BeautyChain BEC Token Exploit)
     * @dev VULNERABILITY: Overflow in totalAmount calculation
     *
     * REAL EXPLOIT (April 2018):
     * - BEC token had this exact vulnerability
     * - Attacker passed: recipients=[addr1, addr2], value=2^255
     * - totalAmount = 2 * 2^255 = 2^256 = 0 (overflow!)
     * - Balance check: require(balance >= 0) ✓ passes
     * - Transferred 2^255 tokens to each address from nothing!
     * - Created ~10^77 tokens, crashed token price to $0
     * - All exchanges halted trading
     *
     * LESSON: Even one overflow can destroy a token economy
     */
    function batchTransfer(address[] calldata recipients, uint256 value) public returns (bool) {
        unchecked {
            // VULNERABILITY: This multiplication can overflow!
            uint256 totalAmount = recipients.length * value;

            // If overflow occurred, totalAmount is wrong but we don't know
            require(balances[msg.sender] >= totalAmount, "Insufficient balance");

            balances[msg.sender] -= totalAmount;

            for (uint256 i = 0; i < recipients.length; i++) {
                balances[recipients[i]] += value;
                emit Transfer(msg.sender, recipients[i], value);
            }
        }

        return true;
    }

    /**
     * @notice Vulnerable transferProxy (SMT Token Exploit)
     * @dev VULNERABILITY: Overflow in total calculation
     *
     * REAL EXPLOIT (April 2018):
     * - SMT token had this vulnerability
     * - Attacker passed: value=2^256-1, fee=1
     * - total = (2^256-1) + 1 = 2^256 = 0 (overflow!)
     * - Balance check: require(balance >= 0) ✓ passes
     * - Transferred max value with 0 balance requirement!
     *
     * LESSON: Addition can overflow too, not just multiplication
     */
    function transferProxy(
        address from,
        address to,
        uint256 value,
        uint256 fee
    ) public returns (bool) {
        unchecked {
            // VULNERABILITY: This addition can overflow!
            uint256 total = value + fee;

            require(balances[from] >= total, "Insufficient balance");

            balances[from] -= total;
            balances[to] += value;
            balances[msg.sender] += fee;

            emit Transfer(from, to, value);
            emit Transfer(from, msg.sender, fee);
        }

        return true;
    }

    /**
     * @notice Vulnerable mint function (overflow in totalSupply)
     * @dev VULNERABILITY: totalSupply can overflow
     *
     * EXPLOIT:
     * - Mint max uint256 tokens
     * - Mint 1 more token
     * - totalSupply wraps to 0
     * - Supply tracking is broken
     */
    function mint(address to, uint256 amount) public returns (bool) {
        unchecked {
            balances[to] += amount;
            totalSupply += amount;  // Can overflow!
        }
        return true;
    }
}

// ============================================================================
// PART 2: SAFEMATH LIBRARY (PRE-0.8 PROTECTION)
// ============================================================================

/**
 * @notice SafeMath library for safe arithmetic operations
 * @dev This was the standard protection before Solidity 0.8.0
 *
 * HOW IT WORKS:
 * - Each operation checks for overflow/underflow
 * - Uses require() to revert if overflow detected
 * - More gas expensive than 0.8+ built-in checks
 *
 * HISTORICAL CONTEXT:
 * - Used in millions of contracts pre-0.8
 * - OpenZeppelin's SafeMath was the industry standard
 * - No longer needed in 0.8+, but important to understand
 */
library SafeMath {
    /**
     * @notice Adds two numbers with overflow check
     * @dev Returns a + b, reverts on overflow
     *
     * OVERFLOW DETECTION:
     * - If a + b overflows, result < a
     * - Example: 2^256-1 + 2 = 1, and 1 < 2^256-1
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @notice Subtracts two numbers with underflow check
     * @dev Returns a - b, reverts on underflow (b > a)
     *
     * UNDERFLOW DETECTION:
     * - Check b <= a before subtraction
     * - If b > a, subtraction would underflow
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction underflow");
        return a - b;
    }

    /**
     * @notice Subtracts with custom error message
     * @dev Useful for domain-specific error messages
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @notice Multiplies two numbers with overflow check
     * @dev Returns a * b, reverts on overflow
     *
     * OVERFLOW DETECTION:
     * - Special case: if a is 0, return 0 (no overflow possible)
     * - Calculate c = a * b
     * - Check: c / a should equal b (if no overflow)
     * - If overflow occurred, c / a ≠ b
     *
     * Example: 2^128 * 2^128 = 2^256 = 0 (overflow)
     * - Check: 0 / 2^128 = 0 ≠ 2^128, overflow detected!
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: 0 * anything = 0, no overflow possible
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @notice Divides two numbers
     * @dev Returns a / b, reverts on division by zero
     *
     * NOTE: Division cannot overflow in Solidity
     * Only need to check for division by zero
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @notice Division with custom error message
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @notice Returns the remainder of dividing two numbers
     * @dev Returns a % b, reverts if b is zero
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @notice Modulo with custom error message
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// ============================================================================
// PART 3: SAFE TOKEN (USING SAFEMATH)
// ============================================================================

/**
 * @notice Safe token contract using SafeMath library
 * @dev Demonstrates how contracts protected themselves pre-0.8.0
 *
 * KEY POINTS:
 * - Uses SafeMath for all arithmetic
 * - Prevents overflow/underflow attacks
 * - More verbose than 0.8+ code
 * - Slightly higher gas cost than 0.8+ built-in checks
 */
contract SafeToken {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;
    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(uint256 initialSupply) {
        balances[msg.sender] = initialSupply;
        totalSupply = initialSupply;
    }

    /**
     * @notice Safe transfer using SafeMath
     * @dev Uses .sub() and .add() to prevent underflow/overflow
     *
     * PROTECTION:
     * - sub() reverts if amount > balance (underflow prevention)
     * - add() reverts if balance + amount overflows (overflow prevention)
     */
    function transfer(address to, uint256 amount) public returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(amount, "Insufficient balance");
        balances[to] = balances[to].add(amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @notice Safe batch transfer using SafeMath
     * @dev Prevents BeautyChain-style exploit
     *
     * PROTECTION:
     * - mul() checks for overflow in total calculation
     * - Prevents creating tokens from nothing
     */
    function batchTransfer(address[] calldata recipients, uint256 value) public returns (bool) {
        // Safe multiplication - reverts on overflow
        uint256 totalAmount = uint256(recipients.length).mul(value);

        // Safe subtraction - reverts on underflow
        balances[msg.sender] = balances[msg.sender].sub(totalAmount, "Insufficient balance");

        for (uint256 i = 0; i < recipients.length; i++) {
            // Safe addition - reverts on overflow
            balances[recipients[i]] = balances[recipients[i]].add(value);
            emit Transfer(msg.sender, recipients[i], value);
        }

        return true;
    }

    /**
     * @notice Safe transferProxy using SafeMath
     * @dev Prevents SMT-style exploit
     *
     * PROTECTION:
     * - add() checks for overflow when calculating total
     * - Prevents bypassing balance check
     */
    function transferProxy(
        address from,
        address to,
        uint256 value,
        uint256 fee
    ) public returns (bool) {
        // Safe addition - reverts on overflow
        uint256 total = value.add(fee);

        // Safe subtraction - reverts on underflow
        balances[from] = balances[from].sub(total, "Insufficient balance");

        balances[to] = balances[to].add(value);
        balances[msg.sender] = balances[msg.sender].add(fee);

        emit Transfer(from, to, value);
        emit Transfer(from, msg.sender, fee);

        return true;
    }

    /**
     * @notice Safe mint using SafeMath
     * @dev Prevents totalSupply overflow
     */
    function mint(address to, uint256 amount) public returns (bool) {
        balances[to] = balances[to].add(amount);
        totalSupply = totalSupply.add(amount);  // Reverts on overflow
        return true;
    }
}

// ============================================================================
// PART 4: MODERN TOKEN (0.8+ AUTOMATIC CHECKS)
// ============================================================================

/**
 * @notice Modern token using Solidity 0.8+ automatic overflow checks
 * @dev Demonstrates that SafeMath is no longer needed in 0.8+
 *
 * SOLIDITY 0.8.0+ IMPROVEMENTS:
 * - Automatic overflow/underflow checks on all arithmetic
 * - Reverts instead of wrapping
 * - No library needed
 * - Cleaner, more readable code
 * - More gas efficient than SafeMath
 *
 * WHEN TO USE:
 * - All new contracts should use 0.8.0+
 * - Only use unchecked when you have a good reason
 * - Document any unchecked usage
 */
contract ModernToken {
    mapping(address => uint256) public balances;
    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(uint256 initialSupply) {
        balances[msg.sender] = initialSupply;
        totalSupply = initialSupply;
    }

    /**
     * @notice Transfer with automatic overflow checks
     * @dev No SafeMath needed - arithmetic is automatically checked!
     *
     * AUTOMATIC PROTECTION:
     * - balances[msg.sender] -= amount reverts if amount > balance
     * - balances[to] += amount reverts if result overflows
     */
    function transfer(address to, uint256 amount) public returns (bool) {
        balances[msg.sender] -= amount;  // Auto-checked for underflow
        balances[to] += amount;           // Auto-checked for overflow
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @notice Batch transfer with automatic checks
     * @dev Prevents BeautyChain exploit automatically
     *
     * AUTOMATIC PROTECTION:
     * - recipients.length * value reverts on overflow
     * - No way to bypass balance check
     */
    function batchTransfer(address[] calldata recipients, uint256 value) public returns (bool) {
        uint256 totalAmount = recipients.length * value;  // Auto-checked!
        require(balances[msg.sender] >= totalAmount, "Insufficient balance");

        balances[msg.sender] -= totalAmount;

        for (uint256 i = 0; i < recipients.length; i++) {
            balances[recipients[i]] += value;
            emit Transfer(msg.sender, recipients[i], value);
        }

        return true;
    }

    /**
     * @notice TransferProxy with automatic checks
     * @dev Prevents SMT exploit automatically
     *
     * AUTOMATIC PROTECTION:
     * - value + fee reverts on overflow
     * - Cannot bypass balance check
     */
    function transferProxy(
        address from,
        address to,
        uint256 value,
        uint256 fee
    ) public returns (bool) {
        uint256 total = value + fee;  // Auto-checked for overflow!

        require(balances[from] >= total, "Insufficient balance");

        balances[from] -= total;
        balances[to] += value;
        balances[msg.sender] += fee;

        emit Transfer(from, to, value);
        emit Transfer(from, msg.sender, fee);

        return true;
    }

    /**
     * @notice Mint with automatic checks
     * @dev totalSupply cannot overflow
     */
    function mint(address to, uint256 amount) public returns (bool) {
        balances[to] += amount;
        totalSupply += amount;  // Auto-checked for overflow
        return true;
    }
}

// ============================================================================
// PART 5: UNCHECKED USAGE EXAMPLES
// ============================================================================

/**
 * @notice Examples of safe and unsafe unchecked usage
 * @dev Critical knowledge for gas optimization and security
 *
 * RULES FOR UNCHECKED:
 * 1. ✅ Use for loop counters with proven bounds
 * 2. ✅ Use after explicit overflow checks
 * 3. ✅ Use for intentional wrapping (rare, document heavily)
 * 4. ❌ Never use with user-controlled values
 * 5. ❌ Never use for financial calculations
 * 6. ❌ Never use without mathematical proof of safety
 */
contract UncheckedExamples {
    /**
     * @notice ✅ SAFE: Loop counter with unchecked increment
     * @dev Counter is bounded by array length, cannot overflow
     *
     * GAS SAVINGS: ~30 gas per iteration
     *
     * WHY SAFE:
     * - i < data.length in every iteration
     * - data.length is max 2^256-1
     * - Even if data.length = 2^256-1, loop would run out of gas before overflow
     * - Therefore i++ can never overflow in practice
     */
    function safeLoopCounter(uint256[] calldata data) public pure returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < data.length;) {
            sum += data[i];  // Keep sum checked - user data could overflow
            unchecked {
                i++;  // Safe to uncheck - bounded by array length
            }
        }
        return sum;
    }

    /**
     * @notice ✅ SAFE: Unchecked after explicit bounds check
     * @dev We verify a >= b before subtraction
     *
     * WHY SAFE:
     * - require(a >= b) ensures subtraction won't underflow
     * - Unchecked saves gas on operation we know is safe
     * - Common pattern in optimized contracts
     */
    function safeSubtractWithCheck(uint256 a, uint256 b) public pure returns (uint256) {
        require(a >= b, "Underflow");
        unchecked {
            return a - b;  // Safe: we just proved a >= b
        }
    }

    /**
     * @notice ✅ SAFE: Decrement in loop with lower bound
     * @dev Countdown loop with explicit stop condition
     *
     * WHY SAFE:
     * - Loop condition i > 0 prevents underflow
     * - i-- only executes when i >= 1
     * - Cannot underflow
     */
    function safeCountdown(uint256 start) public pure returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = start; i > 0;) {
            sum += i;
            unchecked {
                i--;  // Safe: loop condition ensures i > 0
            }
        }
        return sum;
    }

    /**
     * @notice ✅ SAFE: Intentional wrapping for hash calculation
     * @dev Wrapping is desired behavior for mixing function
     *
     * WHY SAFE:
     * - Algorithm requires wrapping behavior
     * - Not used for financial calculations
     * - Heavily documented
     * - Common in cryptographic functions
     */
    function hashMix(uint256 a, uint256 b) public pure returns (uint256) {
        unchecked {
            // Intentional wrapping for hash mixing
            // This is similar to Java's hashCode() which allows overflow
            return (a * 31) + b;
        }
    }

    /**
     * @notice ❌ UNSAFE: Unchecked with user input
     * @dev User controls value, can cause overflow
     *
     * WHY UNSAFE:
     * - userValue is attacker-controlled
     * - userValue could be 2^255 + 1
     * - userValue * 2 would overflow
     * - Result would be small number instead of expected large number
     * - Could break business logic that relies on this calculation
     */
    function unsafeUserInput(uint256 userValue) public pure returns (uint256) {
        unchecked {
            return userValue * 2;  // DANGEROUS!
        }
    }

    /**
     * @notice ❌ UNSAFE: Unchecked financial calculation
     * @dev Reward calculation must never overflow
     *
     * WHY UNSAFE:
     * - Financial calculations must be exact
     * - Overflow could give user less reward than deserved (loss of funds)
     * - Or more reward than deserved (minting from nothing)
     * - Never worth the gas savings
     */
    function unsafeRewardCalculation(uint256 stake, uint256 multiplier) public pure returns (uint256) {
        unchecked {
            return stake * multiplier;  // DANGEROUS!
        }
    }

    /**
     * @notice ❌ UNSAFE: Unchecked balance update
     * @dev Balance arithmetic must always be checked
     *
     * WHY UNSAFE:
     * - Balance could underflow (create tokens from nothing)
     * - Balance could overflow (lose user funds)
     * - These are the exact vulnerabilities we're trying to prevent!
     */
    mapping(address => uint256) public balances;

    function unsafeTransfer(address to, uint256 amount) public {
        unchecked {
            balances[msg.sender] -= amount;  // DANGEROUS!
            balances[to] += amount;           // DANGEROUS!
        }
    }

    /**
     * @notice ❌ UNSAFE: Unchecked timestamp arithmetic
     * @dev Time calculations can have security implications
     *
     * WHY UNSAFE:
     * - If delay is large, block.timestamp + delay could overflow
     * - Overflowed timestamp would be in the past
     * - Time lock would be immediately unlockable
     * - Real vulnerability in some contracts
     */
    function unsafeTimeLock(uint256 delay) public view returns (uint256) {
        unchecked {
            return block.timestamp + delay;  // DANGEROUS!
        }
    }

    /**
     * @notice Gas comparison: Checked vs Unchecked
     * @dev Run tests to see actual gas difference
     */
    function expensiveLoop(uint256[] calldata data) public pure returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < data.length; i++) {  // Checked increment
            sum += data[i];
        }
        return sum;
    }

    function cheaperLoop(uint256[] calldata data) public pure returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < data.length;) {
            sum += data[i];
            unchecked { i++; }  // Unchecked increment - saves ~30 gas/iteration
        }
        return sum;
    }
}

// ============================================================================
// BONUS: ADVANCED OVERFLOW SCENARIOS
// ============================================================================

/**
 * @notice Advanced overflow scenarios and edge cases
 */
contract AdvancedOverflowScenarios {
    /**
     * @notice Time lock with overflow vulnerability (pre-0.8 simulation)
     * @dev Shows how overflow can bypass time locks
     */
    mapping(address => uint256) public unlockTime;

    function vulnerableSetUnlockTime(uint256 delay) public {
        unchecked {
            // If delay is large enough, this overflows to past timestamp
            unlockTime[msg.sender] = block.timestamp + delay;
        }
    }

    function safeSetUnlockTime(uint256 delay) public {
        // Automatic overflow check prevents bypass
        unlockTime[msg.sender] = block.timestamp + delay;
    }

    function withdraw() public {
        require(block.timestamp >= unlockTime[msg.sender], "Still locked");
        // ... withdrawal logic
    }

    /**
     * @notice Voting with overflow vulnerability
     * @dev Vote count could overflow, breaking governance
     */
    mapping(uint256 => uint256) public proposalVotes;

    function vulnerableVote(uint256 proposalId, uint256 votes) public {
        unchecked {
            // Vote count could overflow, resetting to low number
            proposalVotes[proposalId] += votes;
        }
    }

    function safeVote(uint256 proposalId, uint256 votes) public {
        // Automatic check prevents vote count overflow
        proposalVotes[proposalId] += votes;
    }

    /**
     * @notice Interest calculation with careful bounds
     * @dev Shows safe way to calculate interest on large principals
     */
    function calculateInterest(
        uint256 principal,
        uint256 ratePercent,
        uint256 periods
    ) public pure returns (uint256) {
        // Safe approach: check intermediate results
        uint256 ratePerPeriod = ratePercent;  // e.g., 5 for 5%

        // Calculate interest per period
        // interest = principal * rate / 100
        // This could overflow if principal is very large

        // Safe calculation: do division first if possible
        uint256 interestPerPeriod = (principal / 100) * ratePerPeriod;

        // Then multiply by periods (still checked)
        uint256 totalInterest = interestPerPeriod * periods;

        return principal + totalInterest;
    }

    /**
     * @notice Demonstrates downcasting overflow
     * @dev Downcasting can also overflow (uint256 -> uint8)
     */
    function downcastingOverflow(uint256 value) public pure returns (uint8) {
        // In 0.8+, this reverts if value > 255
        return uint8(value);
    }

    function unsafeDowncasting(uint256 value) public pure returns (uint8) {
        unchecked {
            // This truncates: 256 becomes 0, 257 becomes 1, etc.
            return uint8(value);
        }
    }
}
