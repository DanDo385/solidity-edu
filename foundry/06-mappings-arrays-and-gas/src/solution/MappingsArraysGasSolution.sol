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
     * @dev USER ADDITION: Adding to Both Mapping and Array
     * ═══════════════════════════════════════════════════
     *
     *      This function demonstrates adding a user to both a mapping (for O(1) lookup)
     *      and an array (for iteration). This is a common pattern in Solidity!
     *
     *      EXECUTION FLOW:
     *      ┌─────────────────────────────────────────┐
     *      │ 1. VALIDATION: Check user doesn't exist │
     *      │    - Read isUser[user] mapping          │
     *      │    - Revert if already exists           │
     *      │    ↓                                      │
     *      │ 2. ARRAY OPERATION: Push to users[]     │
     *      │    - Add user to end of array           │
     *      │    - Updates array length               │
     *      │    ↓                                      │
     *      │ 3. MAPPING OPERATION: Set isUser flag   │
     *      │    - Set isUser[user] = true           │
     *      │    ↓                                      │
     *      │ 4. EVENT EMISSION: Log the addition     │
     *      │    - Emit UserAdded event               │
     *      └─────────────────────────────────────────┘
     *
     *      CONNECTION TO PROJECT 01: Mapping Storage!
     *      ════════════════════════════════════════════
     *
     *      We're using the mapping storage pattern we learned:
     *      - Storage slot: keccak256(abi.encodePacked(user, slot_number))
     *      - Writing to mapping: ~20,000 gas (zero to non-zero)
     *
     *      CONNECTION TO PROJECT 01: Array Storage!
     *      ══════════════════════════════════════════
     *
     *      Arrays store elements sequentially:
     *      - Length stored at slot N
     *      - Elements at keccak256(N), keccak256(N)+1, ...
     *      - Push operation: ~20,000 gas (new slot write)
     *
     *      STORAGE LAYOUT:
     *      ═══════════════
     *
     *      For user 0x1234...:
     *      ┌─────────────────────────────────────────────┐
     *      │ Mapping Storage (isUser):                    │
     *      │ keccak256(abi.encodePacked(                 │
     *      │   0x1234...,                                │
     *      │   slot_number_of_isUser_mapping             │
     *      │ ))                                          │
     *      │ ↓                                            │
     *      │ Storage slot: 0xABCD...                      │
     *      │ Old value: false (0)                         │
     *      │ New value: true (1)                           │
     *      │ Cost: ~20,000 gas (zero to non-zero)        │
     *      ├─────────────────────────────────────────────┤
     *      │ Array Storage (users):                       │
     *      │ Slot N: length (incremented)                 │
     *      │ Slot keccak256(N) + (length-1): 0x1234...   │
     *      │ Cost: ~20,000 gas (new slot write)          │
     *      └─────────────────────────────────────────────┘
     *
     *      GAS COST BREAKDOWN:
     *      ┌─────────────────────┬──────────────┬─────────────────┐
     *      │ Operation           │ Gas (warm)   │ Gas (cold)      │
     *      ├─────────────────────┼──────────────┼─────────────────┤
     *      │ SLOAD isUser[user]  │ ~100 gas     │ ~2,100 gas      │
     *      │ require() check     │ ~3 gas       │ ~3 gas          │
     *      │ Array push           │ ~20,000 gas  │ ~20,000 gas     │
     *      │ SSTORE isUser[user] │ ~5,000 gas   │ ~20,000 gas     │
     *      │ Event emission      │ ~1,500 gas   │ ~1,500 gas      │
     *      ├─────────────────────┼──────────────┼─────────────────┤
     *      │ TOTAL (warm)        │ ~26,603 gas  │                 │
     *      │ TOTAL (cold)        │              │ ~43,603 gas     │
     *      └─────────────────────┴──────────────┴─────────────────┘
     *
     *      GAS OPTIMIZATION: Order of Operations
     *      ═════════════════════════════════════
     *
     *      We push to array BEFORE setting mapping. Why?
     *      - If push fails (out of gas), mapping isn't set
     *      - Keeps state consistent (both or neither)
     *      - Array push is more likely to fail (unbounded growth)
     *
     *      REAL-WORLD ANALOGY:
     *      ═══════════════════
     *
     *      Like adding someone to both a phone book (mapping) and guest list (array):
     *      - **Phone book** = Instant lookup (mapping)
     *      - **Guest list** = Ordered list for iteration (array)
     *      - Both need to be updated together!
     *
     *      CONNECTION TO PROJECT 05: Error Handling!
     *      ══════════════════════════════════════════
     *
     *      Using require() with string is fine here, but custom error would save gas:
     *      - Current: require(!isUser[user], "User exists") = ~50 + string length
     *      - Better: if (isUser[user]) revert UserAlreadyExists();
     *      - Savings: ~26 gas + string length
     *
     *      🎓 LEARNING MOMENT:
     *      Maintaining both mapping and array is a common pattern!
     *      Mapping for fast lookups, array for iteration. The trade-off is
     *      extra storage cost, but it's worth it for the flexibility!
     */
    function addUser(address user) public {
        // 🛡️  VALIDATION: Check user doesn't already exist
        // CONNECTION TO PROJECT 01: Mapping storage read!
        // Reading from isUser mapping: ~100 gas (warm) or ~2,100 gas (cold)
        // CONNECTION TO PROJECT 05: Error handling!
        // Using require() - could use custom error for gas savings
        require(!isUser[user], "User exists"); // SLOAD: ~100 gas (warm)

        // 📝 ARRAY OPERATION: Add user to array
        // CONNECTION TO PROJECT 01: Array storage write!
        // Push operation: ~20,000 gas (new slot write)
        // This updates the array length and adds element at new position
        users.push(user); // SSTORE: ~20,000 gas (new slot)

        // 💾 MAPPING OPERATION: Set user flag
        // CONNECTION TO PROJECT 01: Mapping storage write!
        // Writing to isUser mapping: ~5,000 gas (warm) or ~20,000 gas (cold)
        // This enables O(1) lookup to check if address is a user
        isUser[user] = true; // SSTORE: ~5,000 gas (warm)

        // 📢 EVENT EMISSION: Log the addition
        // CONNECTION TO PROJECT 03: Event emission!
        // Frontends can listen to this event for real-time updates
        emit UserAdded(user); // ~1,500 gas
    }
    
    /**
     * @notice Set balance for a user (adds user if doesn't exist)
     * @param user Address to set balance for
     * @param amount New balance amount
     *
     * @dev BALANCE UPDATE: The Gas-Optimized Pattern
     * ═══════════════════════════════════════════════
     *
     *      This function demonstrates the critical pattern of tracking totals
     *      separately to avoid expensive iteration. This is THE key optimization!
     *
     *      EXECUTION FLOW:
     *      ┌─────────────────────────────────────────┐
     *      │ 1. CHECK: Is user already added?         │
     *      │    - If NO: Call addUser()              │
     *      │    - If YES: Continue                    │
     *      │    ↓                                      │
     *      │ 2. CACHE: Read old balance               │
     *      │    - Store in memory for reuse           │
     *      │    ↓                                      │
     *      │ 3. UPDATE: Set new balance              │
     *      │    - balances[user] = amount            │
     *      │    ↓                                      │
     *      │ 4. UPDATE TOTAL: Adjust running total   │
     *      │    - totalBalance -= oldBalance + amount │
     *      │    ↓                                      │
     *      │ 5. EVENT: Emit balance update            │
     *      └─────────────────────────────────────────┘
     *
     *      CONNECTION TO PROJECT 01: Mapping Storage!
     *      ════════════════════════════════════════════
     *
     *      We're updating the balances mapping:
     *      - Storage slot: keccak256(abi.encodePacked(user, slot_number))
     *      - Cost: ~5,000 gas (warm) or ~20,000 gas (cold)
     *
     *      GAS OPTIMIZATION: Why Cache oldBalance?
     *      ═══════════════════════════════════════════
     *
     *      APPROACH 1: Read Twice (INEFFICIENT!)
     *      ```solidity
     *      totalBalance = totalBalance - balances[user] + amount;
     *      balances[user] = amount;
     *      ```
     *      - Cost: 2 SLOADs for balances[user] = ~200 gas (warm)
     *      - Problem: Reads from storage twice!
     *
     *      APPROACH 2: Cache First (OPTIMAL!)
     *      ```solidity
     *      uint256 oldBalance = balances[user];
     *      balances[user] = amount;
     *      totalBalance = totalBalance - oldBalance + amount;
     *      ```
     *      - Cost: 1 SLOAD + 1 MLOAD = ~103 gas (warm)
     *      - Savings: ~97 gas per update
     *
     *      GAS OPTIMIZATION: Running Total Pattern
     *      ═════════════════════════════════════════
     *
     *      APPROACH 1: Recalculate Every Time (EXPENSIVE!)
     *      ```solidity
     *      totalBalance = sumAllBalances();  // Iterate through all users!
     *      ```
     *      - Cost: n × ~103 gas (for n users)
     *      - For 100 users: ~10,300 gas per update!
     *
     *      APPROACH 2: Incremental Update (CHEAP!)
     *      ```solidity
     *      totalBalance = totalBalance - oldBalance + amount;
     *      ```
     *      - Cost: 2 SLOADs + 1 SSTORE = ~5,200 gas
     *      - Savings: ~5,100 gas per update (for 100 users)
     *
     *      GAS COST BREAKDOWN:
     *      ┌─────────────────────┬──────────────┬─────────────────┐
     *      │ Operation           │ Gas (warm)   │ Gas (cold)      │
     *      ├─────────────────────┼──────────────┼─────────────────┤
     *      │ SLOAD isUser[user] │ ~100 gas     │ ~2,100 gas      │
     *      │ SLOAD oldBalance    │ ~100 gas     │ ~2,100 gas      │
     *      │ SSTORE balance      │ ~5,000 gas   │ ~20,000 gas     │
     *      │ SLOAD totalBalance │ ~100 gas     │ ~2,100 gas      │
     *      │ SSTORE totalBalance│ ~5,000 gas   │ ~20,000 gas     │
     *      │ Event emission     │ ~1,500 gas   │ ~1,500 gas      │
     *      ├─────────────────────┼──────────────┼─────────────────┤
     *      │ TOTAL (warm)        │ ~11,800 gas  │                 │
     *      │ TOTAL (cold)        │              │ ~47,800 gas     │
     *      └─────────────────────┴──────────────┴─────────────────┘
     *
     *      REAL-WORLD ANALOGY:
     *      ═══════════════════
     *
     *      Like updating a cash register:
     *      - **Old approach**: Count all items every time (expensive!)
     *      - **New approach**: Subtract old value, add new value (cheap!)
     *      - **Running total**: Display shows current total instantly
     *
     *      CONNECTION TO PROJECT 01: Storage Caching Pattern!
     *      ═══════════════════════════════════════════════════
     *
     *      We cache oldBalance in memory to avoid re-reading storage.
     *      This is the same pattern we learned: storage → memory → use!
     *
     *      🎓 LEARNING MOMENT:
     *      Tracking totals separately is THE most important gas optimization
     *      for balance tracking systems! It saves 99%+ gas compared to iteration.
     */
    function setBalance(address user, uint256 amount) public {
        // 🛡️  CHECK: Ensure user exists (add if needed)
        // CONNECTION TO PROJECT 01: Mapping storage read!
        // Reading from isUser mapping: ~100 gas (warm)
        // If user doesn't exist, add them (handles array push)
        if (!isUser[user]) {
            addUser(user);  // Handles array push and mapping update
        }

        // 💾 CACHE OLD BALANCE: Read once, use multiple times
        // CONNECTION TO PROJECT 01: Storage → Memory pattern!
        // Reading from balances mapping: ~100 gas (warm) or ~2,100 gas (cold)
        // We'll use this value twice: once for totalBalance calculation
        uint256 oldBalance = balances[user]; // SLOAD: ~100 gas (warm)

        // 💾 UPDATE USER BALANCE: Write new balance
        // CONNECTION TO PROJECT 01: Mapping storage write!
        // Writing to balances mapping: ~5,000 gas (warm) or ~20,000 gas (cold)
        balances[user] = amount; // SSTORE: ~5,000 gas (warm)

        // 💾 UPDATE RUNNING TOTAL: Incremental update (gas-efficient!)
        // CONNECTION TO PROJECT 01: Storage read-modify-write!
        // This is THE key optimization: update incrementally, don't recalculate!
        // Cost: 2 SLOADs (totalBalance, oldBalance) + 1 SSTORE = ~5,200 gas
        // Alternative (recalculate): n × ~103 gas = ~10,300 gas for 100 users!
        totalBalance = totalBalance - oldBalance + amount; // 2 SLOADs + 1 SSTORE: ~5,200 gas

        // 📢 EVENT EMISSION: Log the balance update
        // CONNECTION TO PROJECT 03: Event emission!
        // Frontends listen to this event for real-time balance updates
        emit BalanceUpdated(user, amount); // ~1,500 gas
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
     * @dev USER COUNT: Reading Array Length
     * ══════════════════════════════════════
     *
     *      Simple view function to get the number of users.
     *      Uses array length, which is stored in storage.
     *
     *      CONNECTION TO PROJECT 01: Array Storage!
     *      ══════════════════════════════════════════
     *
     *      Array length is stored at the array's base slot.
     *      Reading it: ~100 gas (warm) or ~2,100 gas (cold)
     *
     *      GAS OPTIMIZATION: Tracking Separately?
     *      ═════════════════════════════════════════
     *
     *      APPROACH 1: Read Array Length (Current)
     *      ```solidity
     *      return users.length;  // 1 SLOAD = ~100 gas
     *      ```
     *      - Cost: ~100 gas per read
     *      - Pros: No extra storage needed
     *      - Cons: SLOAD cost every time
     *
     *      APPROACH 2: Track Separately
     *      ```solidity
     *      uint256 public userCount;
     *      // Update in addUser(): userCount++;
     *      return userCount;  // 1 SLOAD = ~100 gas
     *      ```
     *      - Cost: ~100 gas per read (same!)
     *      - Extra cost: ~5,000 gas per user added (SSTORE)
     *      - Trade-off: Only worth it if read VERY frequently
     *
     *      REAL-WORLD ANALOGY:
     *      ═══════════════════
     *
     *      Like checking how many people are on a guest list:
     *      - **Array length** = Count stored automatically
     *      - **Separate counter** = Manual count (extra work to maintain)
     *
     *      For most cases, array length is fine!
     */
    function getUserCount() public view returns (uint256) {
        // 📖 READ ARRAY LENGTH: Simple storage read
        // CONNECTION TO PROJECT 01: Array storage read!
        // Reading array length: ~100 gas (warm) or ~2,100 gas (cold)
        // CONNECTION TO PROJECT 02: View functions are free off-chain!
        return users.length; // SLOAD: ~100 gas (if on-chain), FREE (if off-chain)
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
