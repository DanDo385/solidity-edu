// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MappingsArraysGasSolution
 * @notice Gas-optimized balance tracking using mappings + arrays + running totals
 * 
 * PURPOSE: Demonstrates the critical pattern of tracking totals separately to avoid
 * expensive O(n) iteration. This is THE most important gas optimization for balance systems.
 * 
 * CS CONCEPTS:
 * - Hash Tables (mappings): O(1) lookups vs O(n) array search
 * - Running Totals: Incremental updates vs recalculation
 * - Data Structure Trade-offs: Mappings for lookups, arrays for iteration
 * 
 * CONNECTIONS:
 * - Project 01: Mapping/array storage patterns
 * - Project 02: Function visibility and state updates
 * - Project 03: Event emission for tracking
 * 
 * REAL-WORLD: Used in all DeFi protocols (Uniswap, Aave) for efficient balance tracking
 */

contract MappingsArraysGasSolution {
    /**
     * @dev Hash table for O(1) balance lookups
     * CS: Hash table property - constant-time access via keccak256(key, slot)
     * CONNECTION: Project 01 mapping storage pattern
     */
    mapping(address => uint256) public balances;

    /**
     * @dev Separate mapping to distinguish "not a user" from "user with 0 balance"
     * CS: Semantics vs efficiency trade-off - extra storage for clearer meaning
     */
    mapping(address => bool) public isUser;

    /**
     * @dev Array for iteration capability (ordered list)
     * CS: Dynamic array - O(1) indexed access, O(n) iteration
     * TRADE-OFF: Expensive storage (~20k gas per push) but enables iteration
     */
    address[] public users;

    /**
     * @dev Running total - THE critical gas optimization!
     * CS: Incremental updates (O(1)) vs recalculation (O(n))
     * For 100 users: 100 gas vs 10,300 gas - 99% savings!
     * CONNECTION: Project 01 storage caching pattern applied to totals
     */
    uint256 public totalBalance;
    
    event UserAdded(address indexed user);
    event BalanceUpdated(address indexed user, uint256 newBalance);
    
    /**
     * @notice Add user to both mapping (O(1) lookup) and array (iteration)
     * @dev CS: Dual data structure pattern - hash table + dynamic array
     * CONNECTION: Project 01 (mapping/array storage), Project 03 (events)
     * 
     * EXECUTION: Validate → Array push → Mapping set → Event
     * Why array first? If push fails, mapping isn't set (consistency)
     */
    function addUser(address user) public {
        require(!isUser[user], "User exists"); // CONNECTION: Project 01 mapping read
        
        users.push(user); // CONNECTION: Project 01 array storage write
        isUser[user] = true; // CONNECTION: Project 01 mapping storage write
        
        emit UserAdded(user); // CONNECTION: Project 03 event emission
    }
    
    /**
     * @notice Set balance with incremental total update (THE key optimization!)
     * @dev CS: Running total pattern - O(1) incremental update vs O(n) recalculation
     * CONNECTION: Project 01 (storage caching), Project 03 (events)
     * 
     * PATTERN: Cache oldBalance → Update balance → Adjust total incrementally
     * For 100 users: 5,200 gas vs 10,300 gas (99% savings!)
     */
    function setBalance(address user, uint256 amount) public {
        if (!isUser[user]) {
            addUser(user); // CONNECTION: Ensures user exists in both structures
        }

        uint256 oldBalance = balances[user]; // CONNECTION: Project 01 storage caching
        balances[user] = amount; // CONNECTION: Project 01 mapping write
        
        // THE KEY OPTIMIZATION: Incremental update instead of recalculation
        totalBalance = totalBalance - oldBalance + amount; // O(1) vs O(n)!
        
        emit BalanceUpdated(user, amount); // CONNECTION: Project 03 event
    }
    
    /**
     * @notice Sum balances by iteration (O(n) - expensive!)
     * @dev CS: Demonstrates why running totals are critical
     * For 100 users: ~10,300 gas vs 100 gas for getTotalBalance()
     * CONNECTION: Project 01 array iteration, Project 02 view functions
     */
    function sumAllBalances() public view returns (uint256) {
        uint256 sum = 0;
        uint256 userCount = users.length; // Cache length (gas optimization)
        
        for (uint256 i = 0; i < userCount; ) {
            sum += balances[users[i]]; // O(n) iteration
            unchecked { i++; } // Safe increment (gas optimization)
        }
        return sum;
    }
    
    /**
     * @notice Get total balance (O(1) - gas-efficient!)
     * @dev CS: Running total pattern - 99% gas savings vs iteration
     * CONNECTION: Project 01 storage read, Project 02 view functions
     */
    function getTotalBalance() public view returns (uint256) {
        return totalBalance; // O(1) vs O(n) for sumAllBalances()
    }
    
    /**
     * @notice Get user count
     * @dev CONNECTION: Project 01 array length storage read
     */
    function getUserCount() public view returns (uint256) {
        return users.length; // CONNECTION: Project 01 array storage
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. MAPPINGS PROVIDE O(1) LOOKUPS
 *    ✅ Constant-time access: ~100 gas (warm) or ~2,100 gas (cold)
 *    ✅ Perfect for lookups by key
 *    ✅ Storage slot: keccak256(abi.encodePacked(key, slot_number))
 *    ✅ Real-world: Like a phone book - instant lookup!
 *
 * 2. ARRAYS ARE EXPENSIVE FOR ITERATION
 *    ✅ Iteration costs: n × ~103 gas (SLOAD + MLOAD per element)
 *    ✅ Push operation: ~20,000 gas (new slot write)
 *    ✅ Perfect for ordered data and iteration
 *    ✅ Real-world: Like a guest list - ordered but must scan
 *
 * 3. TRACK TOTALS SEPARATELY (CRITICAL OPTIMIZATION!)
 *    ✅ Reading totalBalance: ~100 gas (warm)
 *    ✅ Calculating sumAllBalances(): n × ~103 gas
 *    ✅ For 100 users: 100 gas vs 10,300 gas (99% reduction!)
 *    ✅ Always update incrementally: totalBalance -= old + new
 *
 * 4. CACHE VALUES YOU USE MULTIPLE TIMES
 *    ✅ Reading from storage twice: 2 × ~100 gas = ~200 gas
 *    ✅ Caching: 1 SLOAD + 1 MLOAD = ~103 gas
 *    ✅ Savings: ~97 gas per cached value
 *    ✅ Common pattern: storage → memory → use
 *
 * 5. UNBOUNDED LOOPS ARE DANGEROUS
 *    ✅ Can cause DoS attacks (exceed gas limit)
 *    ✅ Mitigation: Track totals separately, limit array size
 *    ✅ Consider pagination for large datasets
 *    ✅ Use mappings + events instead of arrays when possible
 *
 * 6. USE UNCHECKED ARITHMETIC IN LOOPS
 *    ✅ Safe when you know bounds (i < length)
 *    ✅ Saves ~100 gas per iteration
 *    ✅ Example: unchecked { i++; }
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMMON MISTAKES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ❌ Recalculating totals instead of tracking separately (wastes gas!)
 * ❌ Reading from storage multiple times instead of caching
 * ❌ Using arrays for lookups instead of mappings (O(n) vs O(1))
 * ❌ Unbounded loops without limits (DoS risk)
 * ❌ Not caching array length in loops (repeated SLOADs)
 * ❌ Forgetting to update running totals when balances change
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          NEXT STEPS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * • Run `forge test --gas-report` to see actual gas costs
 * • Experiment with different numbers of users
 * • Compare iteration vs tracking gas costs
 * • Study how DeFi protocols handle large user bases
 * • Move to Project 07 to learn about reentrancy and security
 */
