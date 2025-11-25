// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MappingsArraysGasSolution
 * @notice Demonstrates gas-efficient patterns for mappings, arrays, and balance tracking
 * @dev This solution shows why certain patterns are chosen and how gas is saved
 *
 * REAL-WORLD ANALOGY: Think of mappings like a phone book (fast lookup) and arrays
 * like a guest list (ordered but slower to search). We use both strategically:
 * - Mapping for O(1) lookups (phone book)
 * - Array for iteration when needed (guest list)
 * - Track totals separately to avoid expensive loops
 */

contract MappingsArraysGasSolution {
    /**
     * @dev Mapping for O(1) balance lookups
     * 
     * GAS OPTIMIZATION: Why mapping instead of array search?
     * - Mapping lookup: O(1) = ~2,100 gas (cold) or 100 gas (warm)
     * - Array search: O(n) = ~2,100 gas per element checked
     * - For 100 users: mapping = 100 gas, array search = 210,000 gas worst case!
     * 
     * REAL-WORLD ANALOGY: Like using a phone book (mapping) vs reading through
     * a guest list (array) to find someone's number. Phone book is instant!
     */
    mapping(address => uint256) public balances;

    /**
     * @dev Mapping to track if address is a user (O(1) check)
     * 
     * GAS OPTIMIZATION: Why separate mapping instead of checking balance > 0?
     * - Checking isUser[addr]: 1 SLOAD = 100 gas (warm)
     * - Checking balances[addr] > 0: 1 SLOAD = 100 gas (same cost!)
     * - BUT: We can distinguish between "not a user" and "user with 0 balance"
     * - Trade-off: Extra storage slot, but better semantics
     * 
     * ALTERNATIVE: Could use balances[addr] > 0, but then can't distinguish
     * between "never added" and "added but has 0 balance"
     */
    mapping(address => bool) public isUser;

    /**
     * @dev Array to track all users for iteration
     * 
     * GAS WARNING: Arrays in storage are expensive!
     * - push(): ~20,000 gas (cold write to new slot)
     * - Access: ~100 gas per read (warm)
     * - Length: ~100 gas per read
     * 
     * WHY KEEP ARRAY?
     * - Need to iterate for sumAllBalances()
     * - Need to get user count
     * - Trade-off: Extra storage cost for iteration capability
     * 
     * ALTERNATIVE: Could remove array and only use mapping, but then:
     * - Can't iterate over all users
     * - Can't get total user count
     * - Would need to track separately (which we do with totalBalance!)
     */
    address[] public users;

    /**
     * @dev Track total balance separately to avoid expensive loops
     * 
     * GAS OPTIMIZATION: Why track totalBalance separately?
     * - Reading totalBalance: 1 SLOAD = 100 gas (warm)
     * - Calculating sumAllBalances(): n * (SLOAD + MLOAD) = n * ~103 gas
     * - For 100 users: totalBalance = 100 gas, sumAllBalances() = 10,300 gas!
     * - Savings: ~10,200 gas per read
     * 
     * TRADE-OFF:
     * - Extra storage slot (costs ~20k gas to initialize)
     * - Must maintain consistency (update on every balance change)
     * - But saves massive gas on reads
     * 
     * REAL-WORLD ANALOGY: Like keeping a running total at a cash register
     * instead of counting all items every time someone asks for the total.
     * You update it as you go, then read it instantly.
     */
    uint256 public totalBalance;
    
    event UserAdded(address indexed user);
    event BalanceUpdated(address indexed user, uint256 newBalance);
    
    /**
     * @notice Add a new user to the system
     * @param user Address to add as a user
     * 
     * GAS COST BREAKDOWN:
     * - SLOAD isUser[user]: 2,100 gas (cold) or 100 gas (warm)
     * - SSTORE isUser[user]: 20,000 gas (zero to non-zero)
     * - Array push: ~20,000 gas (new slot)
     * - Event: ~1,500 gas
     * - Total: ~44,600 gas (first time)
     * 
     * GAS OPTIMIZATION: Using require with custom error would save ~50 gas
     * - Current: require(!isUser[user], "User exists") = ~50 + string length
     * - Better: if (isUser[user]) revert UserAlreadyExists();
     * - Savings: ~26 gas + string length
     */
    function addUser(address user) public {
        require(!isUser[user], "User exists");
        
        // GAS OPTIMIZATION: Push before setting mapping
        // Why? If push fails (out of gas), we haven't wasted gas on mapping write
        // Actually, push is more likely to fail (unbounded), so this order is fine
        users.push(user);
        isUser[user] = true;
        emit UserAdded(user);
    }
    
    /**
     * @notice Set balance for a user (adds user if doesn't exist)
     * @param user Address to set balance for
     * @param amount New balance amount
     * 
     * GAS OPTIMIZATION: Why cache oldBalance?
     * - Reading balances[user]: 1 SLOAD = 100 gas (warm)
     * - We use it twice: once for check, once for totalBalance update
     * - Caching saves: 1 SLOAD = 100 gas
     * 
     * GAS OPTIMIZATION: Why update totalBalance this way?
     * - totalBalance = totalBalance - oldBalance + amount
     *   Costs: 2 SLOADs (totalBalance, oldBalance) + 1 SSTORE = ~5,200 gas
     * - Alternative: totalBalance = sumAllBalances()
     *   Costs: n * (SLOAD + MLOAD) = 100 users * 103 = 10,300 gas!
     * - Savings: ~5,100 gas per update
     * 
     * REAL-WORLD ANALOGY: Like updating a running total - subtract the old
     * value and add the new value, rather than recalculating everything.
     */
    function setBalance(address user, uint256 amount) public {
        // GAS OPTIMIZATION: Check mapping first (cheap) before array operations
        if (!isUser[user]) {
            addUser(user);  // This handles the array push
        }
        
        // Cache old balance to avoid re-reading storage
        uint256 oldBalance = balances[user];
        
        // Update user balance
        balances[user] = amount;
        
        // Update total balance efficiently
        // GAS: 2 SLOADs + 1 SSTORE = ~5,200 gas
        totalBalance = totalBalance - oldBalance + amount;
        
        emit BalanceUpdated(user, amount);
    }
    
    /**
     * @notice Sum all balances by iterating (expensive!)
     * @return Sum of all user balances
     * 
     * GAS WARNING: This function is expensive!
     * - For n users: n * (SLOAD + MLOAD) = n * ~103 gas
     * - 10 users: ~1,030 gas
     * - 100 users: ~10,300 gas
     * - 1000 users: ~103,000 gas (could exceed gas limit!)
     * 
     * WHY KEEP THIS FUNCTION?
     * - Useful for verification (compare with totalBalance)
     * - Demonstrates why tracking totals separately is important
     * - Can be used for one-time calculations
     * 
     * GAS OPTIMIZATION: Cache array length
     * - Reading users.length: 1 SLOAD = 100 gas
     * - If we read it in loop condition: n * 100 gas
     * - Caching: 1 SLOAD + n * 3 gas (MLOAD) = 100 + 3n gas
     * - For 100 users: saves ~9,700 gas!
     * 
     * ALTERNATIVE (current implementation):
     * - Reading length in condition: n * 100 gas
     * - Could cache: saves ~97 gas per iteration
     */
    function sumAllBalances() public view returns (uint256) {
        uint256 sum = 0;
        
        // GAS OPTIMIZATION: Cache length to avoid repeated SLOADs
        uint256 userCount = users.length;
        
        // GAS OPTIMIZATION: Use unchecked increment (safe, saves ~100 gas per iteration)
        // We know i < userCount, so i++ can't overflow
        for (uint256 i = 0; i < userCount; ) {
            // GAS: 1 SLOAD (balances) + 1 MLOAD (users[i]) = ~103 gas per iteration
            sum += balances[users[i]];
            
            unchecked {
                i++;
            }
        }
        return sum;
    }
    
    /**
     * @notice Get total balance (gas-efficient!)
     * @return Total balance across all users
     * 
     * GAS OPTIMIZATION: Why this is better than sumAllBalances()
     * - This function: 1 SLOAD = 100 gas (warm)
     * - sumAllBalances(): n * ~103 gas
     * - For 100 users: 100 gas vs 10,300 gas
     * - Savings: ~10,200 gas (99% reduction!)
     * 
     * REAL-WORLD ANALOGY: Like reading a pre-calculated total from a display
     * instead of manually adding up all items in a shopping cart.
     */
    function getTotalBalance() public view returns (uint256) {
        return totalBalance;
    }
    
    /**
     * @notice Get total number of users
     * @return Number of users in the system
     * 
     * GAS OPTIMIZATION: Reading array length
     * - users.length: 1 SLOAD = 100 gas (warm)
     * - This is the only way to get user count (unless we track separately)
     * 
     * ALTERNATIVE: Could track userCount separately
     * - Would save: 1 SLOAD = 100 gas per read
     * - But costs: 1 SSTORE = 5,000 gas per user added
     * - Trade-off: Only worth it if read frequently
     */
    function getUserCount() public view returns (uint256) {
        return users.length;
    }
}
