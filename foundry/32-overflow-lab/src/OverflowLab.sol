// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Project 32: Integer Overflow Labs (Pre-0.8)
 * @notice Educational project demonstrating integer overflow/underflow vulnerabilities
 * @dev This uses Solidity 0.8.20 but simulates pre-0.8 behavior with unchecked blocks
 *
 * LEARNING OBJECTIVES:
 * 1. Understand how overflow/underflow worked in pre-0.8.0 Solidity
 * 2. Implement SafeMath library for protection
 * 3. Recognize vulnerable patterns in legacy contracts
 * 4. Learn when unchecked blocks are safe vs dangerous
 */

// ============================================================================
// PART 1: VULNERABLE TOKEN (PRE-0.8 SIMULATION)
// ============================================================================

/**
 * @notice Vulnerable token contract simulating pre-0.8.0 behavior
 * @dev Uses unchecked blocks to demonstrate overflow/underflow vulnerabilities
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
     * @dev TODO: Identify the vulnerability in this function
     *
     * QUESTIONS:
     * 1. What happens if amount > balances[msg.sender]?
     * 2. What happens if balances[to] + amount > type(uint256).max?
     * 3. How would you exploit this?
     */
    function transfer(address to, uint256 amount) public returns (bool) {
        // TODO: Uncomment and analyze this vulnerable code
        // unchecked {
        //     balances[msg.sender] -= amount;
        //     balances[to] += amount;
        // }
        // emit Transfer(msg.sender, to, amount);
        // return true;

        // For now, use safe version (remove this when implementing vulnerable version)
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @notice Vulnerable batch transfer (similar to BeautyChain exploit)
     * @dev TODO: Identify and fix the overflow vulnerability
     *
     * HINT: The vulnerability is in the calculation of total amount
     */
    function batchTransfer(address[] calldata recipients, uint256 value) public returns (bool) {
        // TODO: Implement vulnerable version that calculates:
        // uint256 totalAmount = recipients.length * value;
        // Then transfers value to each recipient
        //
        // VULNERABILITY: recipients.length * value can overflow!
        //
        // Example exploit:
        // - recipients.length = 2
        // - value = 2^255 + 1
        // - totalAmount = 2 * (2^255 + 1) = overflow to small number
        // - Passes balance check but creates tokens from nothing!

        revert("TODO: Implement batchTransfer");
    }

    /**
     * @notice Vulnerable transferProxy (similar to SMT token exploit)
     * @dev TODO: Identify the overflow vulnerability
     */
    function transferProxy(
        address from,
        address to,
        uint256 value,
        uint256 fee
    ) public returns (bool) {
        // TODO: Implement vulnerable version that calculates:
        // uint256 total = value + fee;
        // require(balances[from] >= total);
        //
        // VULNERABILITY: value + fee can overflow!
        //
        // Example exploit:
        // - value = 2^256 - 1 (max uint256)
        // - fee = 1
        // - total = overflow to 0
        // - Passes balance check but transfers max value!

        revert("TODO: Implement transferProxy");
    }
}

// ============================================================================
// PART 2: SAFEMATH LIBRARY
// ============================================================================

/**
 * @notice SafeMath library for safe arithmetic operations (pre-0.8.0 pattern)
 * @dev TODO: Implement all SafeMath functions with overflow protection
 *
 * This library was the standard way to prevent overflows before Solidity 0.8.0
 * Your task: Implement each function with proper overflow/underflow checks
 */
library SafeMath {
    /**
     * @notice Adds two numbers with overflow check
     * @dev TODO: Implement safe addition
     *
     * HINT: After a + b, check that result >= a
     * If result < a, then overflow occurred
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        // TODO: Implement
        // uint256 c = a + b;
        // require(c >= a, "SafeMath: addition overflow");
        // return c;

        revert("TODO: Implement SafeMath.add");
    }

    /**
     * @notice Subtracts two numbers with underflow check
     * @dev TODO: Implement safe subtraction
     *
     * HINT: Check that b <= a before subtracting
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        // TODO: Implement
        // require(b <= a, "SafeMath: subtraction underflow");
        // return a - b;

        revert("TODO: Implement SafeMath.sub");
    }

    /**
     * @notice Multiplies two numbers with overflow check
     * @dev TODO: Implement safe multiplication
     *
     * HINT: If a is 0, return 0. Otherwise, check that (a * b) / a == b
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // TODO: Implement
        // if (a == 0) return 0;
        // uint256 c = a * b;
        // require(c / a == b, "SafeMath: multiplication overflow");
        // return c;

        revert("TODO: Implement SafeMath.mul");
    }

    /**
     * @notice Divides two numbers with zero check
     * @dev TODO: Implement safe division
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // TODO: Implement
        // require(b > 0, "SafeMath: division by zero");
        // return a / b;

        revert("TODO: Implement SafeMath.div");
    }

    /**
     * @notice Returns the remainder of dividing two numbers
     * @dev TODO: Implement safe modulo
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        // TODO: Implement
        // require(b > 0, "SafeMath: modulo by zero");
        // return a % b;

        revert("TODO: Implement SafeMath.mod");
    }
}

// ============================================================================
// PART 3: SAFE TOKEN (USING SAFEMATH)
// ============================================================================

/**
 * @notice Safe token contract using SafeMath library
 * @dev TODO: Implement transfer functions using SafeMath
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
     * @dev TODO: Implement using SafeMath.sub and SafeMath.add
     */
    function transfer(address to, uint256 amount) public returns (bool) {
        // TODO: Implement using SafeMath
        // balances[msg.sender] = balances[msg.sender].sub(amount);
        // balances[to] = balances[to].add(amount);
        // emit Transfer(msg.sender, to, amount);
        // return true;

        revert("TODO: Implement safe transfer");
    }

    /**
     * @notice Safe batch transfer using SafeMath
     * @dev TODO: Implement using SafeMath to prevent overflow
     */
    function batchTransfer(address[] calldata recipients, uint256 value) public returns (bool) {
        // TODO: Implement using SafeMath
        // Calculate total using SafeMath.mul
        // Check balance using SafeMath
        // Transfer to each recipient

        revert("TODO: Implement safe batchTransfer");
    }
}

// ============================================================================
// PART 4: MODERN TOKEN (0.8+ AUTOMATIC CHECKS)
// ============================================================================

/**
 * @notice Modern token using Solidity 0.8+ automatic overflow checks
 * @dev This demonstrates that SafeMath is no longer needed in 0.8+
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
     * @notice Transfer with automatic overflow checks (0.8+)
     * @dev No SafeMath needed - arithmetic is automatically checked!
     */
    function transfer(address to, uint256 amount) public returns (bool) {
        balances[msg.sender] -= amount;  // Automatically reverts on underflow
        balances[to] += amount;           // Automatically reverts on overflow
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @notice Batch transfer with automatic overflow checks
     * @dev Overflow protection is automatic in 0.8+
     */
    function batchTransfer(address[] calldata recipients, uint256 value) public returns (bool) {
        uint256 totalAmount = recipients.length * value;  // Automatically checked!
        require(balances[msg.sender] >= totalAmount, "Insufficient balance");

        balances[msg.sender] -= totalAmount;

        for (uint256 i = 0; i < recipients.length; i++) {
            balances[recipients[i]] += value;
            emit Transfer(msg.sender, recipients[i], value);
        }

        return true;
    }
}

// ============================================================================
// PART 5: UNCHECKED USAGE EXAMPLES
// ============================================================================

/**
 * @notice Examples of safe and unsafe unchecked usage
 * @dev TODO: Study these patterns to understand when unchecked is appropriate
 */
contract UncheckedExamples {
    /**
     * @notice SAFE: Loop counter with unchecked increment
     * @dev Counter is bounded by array length, cannot overflow
     */
    function safeLoopCounter(uint256[] calldata data) public pure returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < data.length;) {
            sum += data[i];
            unchecked {
                i++;  // Safe: i < data.length, cannot overflow
            }
        }
        return sum;
    }

    /**
     * @notice SAFE: Unchecked after explicit bounds check
     * @dev TODO: Complete this function
     */
    function safeSubtractWithCheck(uint256 a, uint256 b) public pure returns (uint256) {
        // TODO: Add require check, then use unchecked
        // require(a >= b, "Underflow");
        // unchecked {
        //     return a - b;  // Safe: we checked a >= b
        // }

        revert("TODO: Implement");
    }

    /**
     * @notice UNSAFE: Unchecked with user input
     * @dev TODO: Identify why this is dangerous
     */
    function unsafeUnchecked(uint256 userValue) public pure returns (uint256) {
        // TODO: Why is this unsafe?
        // unchecked {
        //     return userValue * 2;  // DANGEROUS: Can overflow!
        // }

        revert("TODO: Analyze this");
    }

    /**
     * @notice BENCHMARK: Compare gas costs
     * @dev TODO: Run tests to compare gas usage
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
            unchecked { i++; }  // Unchecked increment - saves gas
        }
        return sum;
    }
}

// ============================================================================
// BONUS CHALLENGES
// ============================================================================

/**
 * @notice Bonus challenges for advanced students
 */
contract BonusChallenges {
    /**
     * CHALLENGE 1: Time Lock Bypass
     * TODO: Create a function that sets unlock time with delay
     * Show how overflow could bypass the time lock in pre-0.8
     */

    /**
     * CHALLENGE 2: Voting Overflow
     * TODO: Create a voting contract where vote count could overflow
     * Show the exploit and fix
     */

    /**
     * CHALLENGE 3: Interest Calculation
     * TODO: Create an interest calculation that could overflow
     * Show how to safely calculate interest on large principals
     */
}
