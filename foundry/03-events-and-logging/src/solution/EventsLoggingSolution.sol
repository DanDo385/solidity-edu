// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EventsLoggingSolution
 * @notice Complete reference implementation demonstrating Solidity events and logging
 * @dev This solution shows why events are crucial and how to use them efficiently
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        CONCEPTUAL OVERVIEW
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * EVENTS: The Bridge Between On-Chain and Off-Chain
 * ═══════════════════════════════════════════════════
 *
 * REAL-WORLD ANALOGY: Events are like receipts or audit logs. You can't read them
 * from the contract (like you can't read receipts from a cash register), but they're
 * permanently recorded and can be read by anyone off-chain. They're cheaper than
 * storage (like printing a receipt vs storing data in a database).
 *
 * HOW EVENTS WORK:
 * ┌─────────────────────────────────────────┐
 * │ Contract emits event                    │
 * │   ↓                                      │
 * │ Event data stored in transaction log    │ ← Cheaper than storage!
 * │   ↓                                      │
 * │ Off-chain systems listen to events       │ ← Indexers, frontends
 * │   ↓                                      │
 * │ UI updates in real-time                 │ ← Magic! ✨
 * └─────────────────────────────────────────┘
 *
 * FUN FACT: Events are stored in transaction logs, not contract storage!
 * This makes them:
 * - Cheaper (~2,000 gas vs ~20,000 gas for storage)
 * - Searchable (can filter by indexed parameters)
 * - Perfect for off-chain systems
 *
 * KEY CONCEPTS:
 * - Events are cheaper than storage (~2k gas vs ~20k gas)
 * - Up to 3 indexed parameters for filtering
 * - Events cannot be read by contracts (write-only logs)
 * - Essential for off-chain indexing and frontend updates
 *
 * LANGUAGE COMPARISON:
 *   TypeScript: console.log() - similar concept, but not persistent
 *   Go: log.Printf() - similar concept, but not on-chain
 *   Rust: println!() - similar concept, but not persistent
 *   Solidity: Events are persistent, on-chain, and searchable!
 *
 * CONNECTION TO EARLIER CONCEPTS:
 * - Storage (Project 01): Expensive, persistent, queryable on-chain
 * - Events (Project 03): Cheap, persistent, queryable off-chain
 * - Best practice: Use storage for state, events for history!
 */
contract EventsLoggingSolution {
    // ════════════════════════════════════════════════════════════════════════
    // STATE VARIABLES (Storage)
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Contract owner address
     * @dev Set in constructor, can be used for access control
     */
    address public owner;

    /**
     * @notice Mapping from address to balance
     * @dev Tracks token balances for each user
     *      CONNECTION TO PROJECT 01: This is the same mapping pattern we learned!
     */
    mapping(address => uint256) public balances;

    /**
     * @notice Mapping from owner to spender to allowance amount
     * @dev Nested mapping for ERC20-style approvals
     *      CONNECTION TO PROJECT 01: Nested mappings work just like we learned!
     */
    mapping(address => mapping(address => uint256)) public allowances;

    /**
     * @notice Mapping from address to status string
     * @dev GAS WARNING: String storage is expensive!
     *      - Storing string: ~20,000 gas (cold) + ~5 gas per byte
     *      - Reading string: ~2,100 gas (cold) + ~3 gas per byte
     *      - For 100-byte string: ~20,500 gas to store, ~2,400 gas to read
     *
     * ALTERNATIVE: Use bytes32 instead of string for fixed-size statuses
     *   mapping(address => bytes32) public userStatus;
     *   Costs: ~5,000 gas (warm) vs ~20,500 gas for string
     *   Savings: ~15,500 gas per update!
     *   But: Limited to 32 bytes, less flexible
     */
    mapping(address => string) public userStatus;

    // ════════════════════════════════════════════════════════════════════════
    // EVENTS
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @dev Events with indexed parameters for filtering
     *
     * INDEXED PARAMETERS: The Search Feature
     * ════════════════════════════════════════
     *
     * Indexed parameters are like searchable tags:
     * - Can filter events by indexed values
     * - Up to 3 indexed parameters per event
     * - Each indexed param costs ~375 gas extra
     *
     * Example: Filter all Transfer events where from = 0x1234...
     * ```javascript
     * contract.on("Transfer", { from: "0x1234..." }, (event) => {
     *     console.log("Transfer from 0x1234...!");
     * });
     * ```
     *
     * GAS OPTIMIZATION: Why use indexed parameters?
     * - Indexed params: ~375 gas per indexed param (up to 3)
     * - Non-indexed params: ~8 gas per byte
     * - Indexed params enable filtering: can search by address
     * - Trade-off: More expensive, but enables efficient off-chain queries
     *
     * GAS COST BREAKDOWN:
     * - LOG1 (no indexed): ~375 gas base + 8 gas/byte
     * - LOG2 (1 indexed): ~750 gas base + 8 gas/byte
     * - LOG3 (2 indexed): ~1,125 gas base + 8 gas/byte
     * - LOG4 (3 indexed): ~1,500 gas base + 8 gas/byte
     *
     * ALTERNATIVE: Store data in mapping instead of events
     *   mapping(address => uint256) public transferHistory;
     *   Costs: ~20,000 gas per write (cold) vs ~1,500 gas for event
     *   Savings: ~18,500 gas per event!
     *   But: Can't filter efficiently, takes storage slots
     *
     * REAL-WORLD ANALOGY: Like choosing between a receipt (event) and a database
     * entry (storage). Receipts are cheaper and permanent, but you can't query
     * them from the contract. Database entries are expensive but queryable.
     *
     * CONNECTION TO STORAGE:
     * Events complement storage:
     * - Storage: For on-chain state (expensive, persistent)
     * - Events: For off-chain indexing (cheap, searchable)
     * - Best practice: Use both! Store state, emit events for tracking.
     */
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Deposit(address indexed user, uint256 amount, uint256 timestamp);
    event StatusChanged(address indexed user, string oldStatus, string newStatus);

    // ════════════════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Initializes the contract
     * @dev Constructor runs ONCE on deployment
     *
     * 🏗️  CONSTRUCTORS: The One-Time Setup
     * ═══════════════════════════════════════
     *
     * CONNECTION TO PROJECT 01: Same constructor pattern we learned!
     * Setting owner = msg.sender establishes who controls the contract.
     *
     * GAS OPTIMIZATION: Using multiplication instead of repeated addition
     * - 1000000 * 10**18: 1 multiplication operation
     * - Alternative: Loop with += would cost n * SSTORE operations
     * - Savings: Massive! One operation vs many storage writes
     *
     * REAL-WORLD ANALOGY: Like setting up a new bank account:
     * - Constructor = Opening the account (one-time setup)
     * - Owner = Account holder (who controls it)
     * - Initial balance = Starting funds
     */
    constructor() {
        owner = msg.sender;
        // GAS OPTIMIZATION: Using multiplication instead of repeated addition
        // 1000000 * 10**18: 1 multiplication operation
        // Alternative: Loop with += would cost n * SSTORE operations
        balances[msg.sender] = 1000000 * 10**18; // Initial supply
    }

    // ════════════════════════════════════════════════════════════════════════
    // FUNCTIONS THAT EMIT EVENTS
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Transfer tokens between addresses
     * @param _to Recipient address
     * @param _amount Amount to transfer
     *
     * @dev TRANSFER OPERATION: The Complete Flow
     * ════════════════════════════════════════════
     *
     *      This function demonstrates a complete token transfer operation,
     *      combining storage updates with event emission. It's a perfect
     *      example of how events complement storage!
     *
     *      EXECUTION FLOW:
     *      ┌─────────────────────────────────────────┐
     *      │ 1. VALIDATION (Checks)                  │
     *      │    - Check recipient is not zero        │
     *      │    - Check sender has sufficient balance│
     *      │    ↓                                      │
     *      │ 2. STATE UPDATE (Effects)                │
     *      │    - Decrease sender's balance          │
     *      │    - Increase recipient's balance        │
     *      │    ↓                                      │
     *      │ 3. EVENT EMISSION (Interactions)         │
     *      │    - Emit Transfer event                 │
     *      │    - Off-chain systems can listen        │
     *      └─────────────────────────────────────────┘
     *
     *      CONNECTION TO PROJECT 02: Checks-Effects-Interactions Pattern!
     *      ═══════════════════════════════════════════════════════════════
     *
     *      This follows the critical security pattern we learned:
     *      1. **Checks**: Validate all inputs and conditions FIRST
     *         - Prevents invalid operations
     *         - Saves gas by failing early
     *      2. **Effects**: Update state variables SECOND
     *         - Changes contract state
     *         - Makes state consistent before external calls
     *      3. **Interactions**: External calls/events LAST
     *         - Events are "off-chain interactions"
     *         - Safe because state is already updated
     *
     *      WHY THIS ORDER MATTERS:
     *      If we emitted the event BEFORE updating state, and then the
     *      transaction reverted, we'd still pay gas for the event emission!
     *      By emitting AFTER state updates, we ensure the event only fires
     *      when the transfer actually succeeds.
     *
     *      GAS OPTIMIZATION: Why emit event after state changes?
     *      ═══════════════════════════════════════════════════════
     *
     *      Events are emitted even if transaction reverts (in the same transaction),
     *      but if we emit before state changes and revert, event still costs gas.
     *      Emitting after ensures state is valid before logging.
     *
     *      GAS COST BREAKDOWN:
     *      ┌─────────────────────┬──────────────┬─────────────────┐
     *      │ Operation           │ Gas (warm)   │ Gas (cold)      │
     *      ├─────────────────────┼──────────────┼─────────────────┤
     *      │ require() checks    │ ~6 gas       │ ~6 gas          │
     *      │ SLOAD sender balance│ ~100 gas     │ ~2,100 gas      │
     *      │ SLOAD recipient bal │ ~100 gas     │ ~2,100 gas      │
     *      │ SSTORE sender       │ ~5,000 gas   │ ~20,000 gas     │
     *      │ SSTORE recipient    │ ~5,000 gas   │ ~20,000 gas     │
     *      │ Event emission      │ ~1,500 gas   │ ~1,500 gas      │
     *      ├─────────────────────┼──────────────┼─────────────────┤
     *      │ TOTAL (warm)        │ ~11,706 gas  │                 │
     *      │ TOTAL (cold)        │              │ ~45,706 gas     │
     *      └─────────────────────┴──────────────┴─────────────────┘
     *
     *      FUN FACT: The event costs ~1,500 gas regardless of whether
     *      storage is warm or cold! This is because events are stored
     *      in transaction logs, not contract storage.
     *
     *      STORAGE LAYOUT FOR THIS OPERATION:
     *      ═══════════════════════════════════
     *
     *      Remember from Project 01: Mappings use keccak256 for storage slots!
     *
     *      For sender address 0x1234...:
     *      ┌─────────────────────────────────────────────┐
     *      │ Slot calculation:                           │
     *      │ keccak256(abi.encodePacked(                 │
     *      │   0x1234...,                                │
     *      │   slot_number_of_balances_mapping          │
     *      │ ))                                          │
     *      │ ↓                                            │
     *      │ Storage slot: 0xABCD...                      │
     *      │ Value: balance (uint256)                    │
     *      │ Operation: Decrease by _amount              │
     *      └─────────────────────────────────────────────┘
     *
     *      For recipient address 0x5678...:
     *      ┌─────────────────────────────────────────────┐
     *      │ Slot calculation:                           │
     *      │ keccak256(abi.encodePacked(                 │
     *      │   0x5678...,                                │
     *      │   slot_number_of_balances_mapping          │
     *      │ ))                                          │
     *      │ ↓                                            │
     *      │ Storage slot: 0xEF01...                      │
     *      │ Value: balance (uint256)                    │
     *      │ Operation: Increase by _amount              │
     *      └─────────────────────────────────────────────┘
     *
     *      CONNECTION TO PROJECT 01: Storage Slot Calculation!
     *      This uses the exact same mapping storage pattern we learned!
     *      Each address maps to a unique storage slot via keccak256.
     *
     *      EVENT EMISSION DETAILS:
     *      ════════════════════════
     *
     *      When we emit Transfer(msg.sender, _to, _amount):
     *      ┌─────────────────────────────────────────┐
     *      │ Event signature hash:                   │
     *      │ keccak256("Transfer(address,address,uint256)")│
     *      │ ↓                                        │
     *      │ Topics (indexed parameters):            │
     *      │ [0] Event signature                     │
     *      │ [1] msg.sender (indexed)               │
     *      │ [2] _to (indexed)                       │
     *      │ ↓                                        │
     *      │ Data (non-indexed parameters):         │
     *      │ _amount (uint256)                      │
     *      │ ↓                                        │
     *      │ Stored in transaction log               │
     *      │ ↓                                        │
     *      │ Off-chain systems can filter/search     │
     *      └─────────────────────────────────────────┘
     *
     *      REAL-WORLD ANALOGY: Like updating a ledger entry and then printing a receipt.
     *      ════════════════════════════════════════════════════════════════════════════
     *
     *      Think of a bank transfer:
     *      - **Storage update** = Updating the bank ledger (permanent record)
     *      - **Event emission** = Printing a receipt (proof of transaction)
     *      - **Off-chain listeners** = Bank statements, mobile apps (read receipts)
     *
     *      The ledger (storage) is the source of truth, but the receipt (event)
     *      is what customers see and what external systems use for updates!
     *
     *      SECURITY CONSIDERATIONS:
     *      ═════════════════════════
     *
     *      ⚠️  Always validate addresses aren't zero:
     *      - address(0) is the zero address (invalid)
     *      - Sending to address(0) would burn tokens (lose them forever!)
     *      - This is a common mistake that can lead to permanent loss of funds
     *
     *      ⚠️  Always check balance before transfer:
     *      - Prevents underflow errors (Solidity 0.8.0+ reverts automatically)
     *      - Provides clear error message ("Insufficient balance")
     *      - Better UX than silent revert
     *
     *      LANGUAGE COMPARISON:
     *      ════════════════════
     *
     *      TypeScript/JavaScript:
     *      ```typescript
     *      function transfer(to: string, amount: number) {
     *          balances[msg.sender] -= amount;
     *          balances[to] += amount;
     *          // No events - just state change!
     *      }
     *      ```
     *
     *      Solidity:
     *      ```solidity
     *      function transfer(address to, uint256 amount) public {
     *          balances[msg.sender] -= amount;
     *          balances[to] += amount;
     *          emit Transfer(msg.sender, to, amount); // Event for off-chain!
     *      }
     *      ```
     *
     *      The key difference: Solidity needs events because contracts can't
     *      query storage efficiently from off-chain. Events bridge that gap!
     *
     *      🎓 LEARNING MOMENT:
     *      Events are your contract's "API" for off-chain systems!
     *      Without events, frontends would have to constantly poll storage
     *      (expensive and inefficient). Events make blockchain data accessible!
     *
     *      CONNECTION TO ERC20 STANDARD:
     *      This matches the ERC20 Transfer event signature exactly!
     *      Frontends, wallets, and indexers all expect this exact format.
     *      Changing it would break compatibility with existing tools.
     */
    function transfer(address _to, uint256 _amount) public {
        // 🛡️  STEP 1: CHECKS - Validate inputs FIRST
        // This prevents invalid operations and saves gas by failing early
        // CONNECTION TO PROJECT 02: Input validation pattern!
        require(_to != address(0), "Invalid recipient");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        // 💾 STEP 2: EFFECTS - Update state SECOND
        // CONNECTION TO PROJECT 01: Mapping storage updates!
        // We're modifying two different storage slots (one for sender, one for recipient)
        // Each update costs ~5,000 gas (warm) or ~20,000 gas (cold)
        balances[msg.sender] -= _amount; // SSTORE: Decrease sender balance
        balances[_to] += _amount;         // SSTORE: Increase recipient balance

        // 📢 STEP 3: INTERACTIONS - Emit event LAST
        // CONNECTION TO PROJECT 03: Event emission!
        // This event is stored in transaction logs, not contract storage
        // Off-chain systems (frontends, indexers) listen to this event
        // The indexed parameters (from, to) enable efficient filtering
        emit Transfer(msg.sender, _to, _amount); // ~1,500 gas (event emission)
    }

    /**
     * @notice Approve spender to transfer tokens
     * @param _spender Address to approve
     * @param _amount Amount to approve
     *
     * @dev APPROVAL MECHANISM: Delegating Spending Power
     * ═══════════════════════════════════════════════════
     *
     *      Approvals are a powerful pattern that allows one address to
     *      authorize another address to spend tokens on their behalf.
     *      This is essential for DeFi protocols, DEXs, and automated systems!
     *
     *      HOW APPROVALS WORK:
     *      ┌─────────────────────────────────────────┐
     *      │ 1. Alice approves Bob for 100 tokens     │
     *      │    allowances[alice][bob] = 100          │
     *      │    ↓                                      │
     *      │ 2. Bob can now call transferFrom()       │
     *      │    to transfer up to 100 tokens          │
     *      │    from Alice's balance                  │
     *      │    ↓                                      │
     *      │ 3. Each transferFrom() decreases         │
     *      │    the allowance until it reaches 0       │
     *      └─────────────────────────────────────────┘
     *
     *      CONNECTION TO PROJECT 01: Nested Mappings!
     *      ═══════════════════════════════════════════
     *
     *      This uses nested mappings: mapping(address => mapping(address => uint256))
     *      - First level: Owner address (who owns the tokens)
     *      - Second level: Spender address (who can spend)
     *      - Value: Allowance amount (how much can be spent)
     *
     *      STORAGE CALCULATION:
     *      For owner 0x1234... and spender 0x5678...:
     *      ┌─────────────────────────────────────────────┐
     *      │ Step 1: Calculate first mapping slot        │
     *      │ keccak256(abi.encodePacked(                 │
     *      │   0x1234...,                                │
     *      │   slot_number_of_allowances_mapping         │
     *      │ ))                                          │
     *      │ Result: intermediate_slot = 0xABCD...      │
     *      │ ↓                                            │
     *      │ Step 2: Calculate nested mapping slot      │
     *      │ keccak256(abi.encodePacked(                 │
     *      │   0x5678...,                                │
     *      │   intermediate_slot                         │
     *      │ ))                                          │
     *      │ Result: final_slot = 0xEF01...              │
     *      │ ↓                                            │
     *      │ Store allowance value at final_slot         │
     *      └─────────────────────────────────────────────┘
     *
     *      FUN FACT: Nested mappings require TWO keccak256 operations!
     *      This is why nested mapping reads cost slightly more gas than
     *      single-level mappings. But it's still O(1) - constant time!
     *
     *      GAS OPTIMIZATION: Direct Assignment vs Read-Modify-Write
     *      ═════════════════════════════════════════════════════════
     *
     *      APPROACH 1: Direct Assignment (What we use - OPTIMAL!)
     *      ```solidity
     *      allowances[msg.sender][_spender] = _amount;
     *      ```
     *      - Cost: 1 SSTORE = ~5,000 gas (warm) or ~20,000 gas (cold)
     *      - Pros: Fastest, simplest
     *      - Cons: Overwrites previous approval (by design!)
     *
     *      APPROACH 2: Read-Modify-Write (INEFFICIENT!)
     *      ```solidity
     *      uint256 oldAllowance = allowances[msg.sender][_spender];
     *      allowances[msg.sender][_spender] = oldAllowance + _amount;
     *      ```
     *      - Cost: 1 SLOAD + 1 SSTORE = ~7,100 gas (warm)
     *      - Pros: Incremental approvals
     *      - Cons: More expensive, requires reading first
     *
     *      GAS SAVINGS: ~2,100 gas per approval by using direct assignment!
     *
     *      GAS COST BREAKDOWN:
     *      ┌─────────────────────┬──────────────┬─────────────────┐
     *      │ Operation           │ Gas (warm)   │ Gas (cold)      │
     *      ├─────────────────────┼──────────────┼─────────────────┤
     *      │ require() check     │ ~3 gas       │ ~3 gas          │
     *      │ SSTORE allowance    │ ~5,000 gas   │ ~20,000 gas     │
     *      │ Event emission      │ ~1,500 gas   │ ~1,500 gas      │
     *      ├─────────────────────┼──────────────┼─────────────────┤
     *      │ TOTAL (warm)        │ ~6,503 gas   │                 │
     *      │ TOTAL (cold)        │              │ ~21,503 gas     │
     *      └─────────────────────┴──────────────┴─────────────────┘
     *
     *      IMPORTANT DESIGN DECISION:
     *      ═══════════════════════════
     *
     *      This function OVERWRITES previous approvals!
     *      - If Alice approved Bob for 100 tokens
     *      - Then Alice approves Bob for 50 tokens
     *      - Bob's allowance is now 50 (not 150!)
     *
     *      WHY THIS DESIGN?
     *      - Prevents accidental double-spending
     *      - Clearer semantics (approval = exact amount)
     *      - Matches ERC20 standard behavior
     *
     *      FOR INCREMENTAL APPROVALS:
     *      If you need to add to existing allowance:
     *      ```solidity
     *      allowances[msg.sender][_spender] += _amount;
     *      ```
     *      But be careful! This requires reading first (more gas).
     *
     *      CONNECTION TO ERC20 STANDARD:
     *      ═════════════════════════════
     *
     *      This matches the ERC20 standard approval pattern exactly!
     *      - Event signature: `Approval(address indexed owner, address indexed spender, uint256 value)`
     *      - Function signature: `approve(address spender, uint256 amount)`
     *      - Behavior: Overwrites previous approval
     *
     *      Frontends, wallets, and DEXs all expect this exact format.
     *      Changing it would break compatibility with existing infrastructure!
     *
     *      REAL-WORLD ANALOGY:
     *      ═══════════════════
     *
     *      Like giving someone a credit card with a spending limit:
     *      - **Approval** = Setting the credit limit
     *      - **Allowance** = How much they can spend
     *      - **transferFrom()** = Making a purchase (decreases allowance)
     *      - **Event** = Credit card statement (permanent record)
     *
     *      Just like credit cards, approvals can be:
     *      - Updated (change the limit)
     *      - Revoked (set to 0)
     *      - Used incrementally (multiple purchases)
     *
     *      SECURITY CONSIDERATIONS:
     *      ═════════════════════════
     *
     *      ⚠️  Always validate spender is not zero:
     *      - Prevents accidental approvals to invalid address
     *      - Zero address can't spend tokens anyway
     *      - Clear error message helps debugging
     *
     *      ⚠️  Frontend Warning Pattern:
     *      Many frontends warn users about large approvals:
     *      ```javascript
     *      if (amount > MAX_SAFE_APPROVAL) {
     *          showWarning("Large approval detected!");
     *      }
     *      ```
     *      This helps prevent accidental unlimited approvals!
     *
     *      🎓 LEARNING MOMENT:
     *      Approvals are a powerful but dangerous feature!
     *      Always be careful when approving tokens - you're giving
     *      someone else permission to spend YOUR tokens!
     *
     *      CONNECTION TO DEFI:
     *      Approvals are essential for DeFi protocols:
     *      - DEXs: Approve DEX to swap your tokens
     *      - Lending: Approve protocol to use tokens as collateral
     *      - Yield farming: Approve farm to stake your tokens
     *      Without approvals, DeFi wouldn't work!
     */
    function approve(address _spender, uint256 _amount) public {
        // 🛡️  VALIDATION: Check spender is not zero address
        // CONNECTION TO PROJECT 02: Input validation!
        // Prevents accidental approvals to invalid address
        require(_spender != address(0), "Invalid spender");

        // 💾 DIRECT ASSIGNMENT: Overwrite previous approval
        // CONNECTION TO PROJECT 01: Nested mapping storage!
        // This is the most gas-efficient approach - no need to read old value
        // Cost: ~5,000 gas (warm) or ~20,000 gas (cold)
        // 
        // NOTE: This OVERWRITES any previous approval!
        // If you need incremental approvals, use += instead
        allowances[msg.sender][_spender] = _amount; // SSTORE: ~5,000 gas (warm)

        // 📢 EVENT EMISSION: Log the approval
        // CONNECTION TO PROJECT 03: Event emission!
        // Frontends listen to this event to update UI in real-time
        // The indexed parameters (owner, spender) enable efficient filtering
        emit Approval(msg.sender, _spender, _amount); // ~1,500 gas
    }

    /**
     * @notice Deposit ETH and credit balance
     *
     * @dev PAYABLE FUNCTIONS: Receiving ETH
     * ═══════════════════════════════════════
     *
     *      This function demonstrates how contracts receive ETH using the
     *      `payable` keyword. Without `payable`, sending ETH would revert!
     *
     *      HOW PAYABLE WORKS:
     *      ┌─────────────────────────────────────────┐
     *      │ User sends transaction with ETH          │
     *      │   ↓                                      │
     *      │ Contract receives ETH automatically     │ ← Magic happens here!
     *      │   ↓                                      │
     *      │ msg.value contains the ETH amount       │ ← Accessible in function
     *      │   ↓                                      │
     *      │ Contract balance increases              │ ← No explicit transfer needed!
     *      └─────────────────────────────────────────┘
     *
     *      CONNECTION TO PROJECT 02: Payable Functions!
     *      ════════════════════════════════════════════
     *
     *      We learned in Project 02 that `payable` is required to receive ETH.
     *      Without it, transactions sending ETH would revert with an error.
     *
     *      FUN FACT: Before Solidity 0.6.0, you had to use `address(this).balance`
     *      to check received ETH. Now `msg.value` makes it explicit and safer!
     *
     *      GAS OPTIMIZATION: Event vs Storage for Timestamps
     *      ═════════════════════════════════════════════════
     *
     *      APPROACH 1: Store Timestamp in Mapping (EXPENSIVE!)
     *      ```solidity
     *      mapping(address => uint256) public depositTimestamps;
     *      depositTimestamps[msg.sender] = block.timestamp; // ~20,000 gas!
     *      ```
     *      - Cost: ~20,000 gas (cold SSTORE)
     *      - Pros: Queryable on-chain
     *      - Cons: Very expensive, takes storage slot
     *
     *      APPROACH 2: Include Timestamp in Event (CHEAP!)
     *      ```solidity
     *      emit Deposit(msg.sender, msg.value, block.timestamp); // ~32 gas!
     *      ```
     *      - Cost: ~32 gas (just data in event)
     *      - Pros: Cheap, permanent record
     *      - Cons: Not queryable on-chain (but off-chain systems can read it!)
     *
     *      GAS SAVINGS: ~19,968 gas per deposit by using event!
     *      That's a 99.8% reduction! 🎉
     *
     *      GAS COST BREAKDOWN:
     *      ┌─────────────────────┬──────────────┬─────────────────┐
     *      │ Operation           │ Gas (warm)   │ Gas (cold)      │
     *      ├─────────────────────┼──────────────┼─────────────────┤
     *      │ require() check     │ ~3 gas       │ ~3 gas          │
     *      │ SLOAD balance       │ ~100 gas     │ ~2,100 gas      │
     *      │ SSTORE balance      │ ~5,000 gas   │ ~20,000 gas     │
     *      │ Read block.timestamp│ ~2 gas       │ ~2 gas          │
     *      │ Event emission      │ ~1,500 gas   │ ~1,500 gas      │
     *      ├─────────────────────┼──────────────┼─────────────────┤
     *      │ TOTAL (warm)        │ ~6,605 gas   │                 │
     *      │ TOTAL (cold)        │              │ ~23,605 gas     │
     *      └─────────────────────┴──────────────┴─────────────────┘
     *
     *      STORAGE UPDATE PATTERN:
     *      ═══════════════════════
     *
     *      CONNECTION TO PROJECT 01: Read-Modify-Write Pattern!
     *      We're using `+=` which does:
     *      1. Read: Load current balance from storage (SLOAD)
     *      2. Modify: Add msg.value to the balance
     *      3. Write: Store new balance back to storage (SSTORE)
     *
     *      This is different from `=` which would overwrite the balance!
     *      Using `+=` allows multiple deposits to accumulate correctly.
     *
     *      REAL-WORLD ANALOGY:
     *      ═══════════════════
     *
     *      Like depositing money into a bank account:
     *      - **ETH sent** = Cash deposited
     *      - **balances mapping** = Bank ledger (tracks your balance)
     *      - **Event** = Deposit receipt (shows amount and timestamp)
     *      - **block.timestamp** = Date/time on receipt
     *
     *      The receipt (event) already has the date, so you don't need
     *      to store it separately in a database (storage mapping)!
     *
     *      SECURITY CONSIDERATIONS:
     *      ═════════════════════════
     *
     *      ⚠️  Always validate msg.value > 0:
     *      - Prevents accidental zero deposits (wasting gas)
     *      - Ensures meaningful transactions
     *      - Clear error message helps debugging
     *
     *      ⚠️  Reentrancy Protection:
     *      For production contracts, consider reentrancy guards:
     *      ```solidity
     *      modifier nonReentrant() {
     *          require(!locked, "Reentrant call");
     *          locked = true;
     *          _;
     *          locked = false;
     *      }
     *      ```
     *      This prevents malicious contracts from calling back during execution.
     *
     *      CONNECTION TO PROJECT 02: Checks-Effects-Interactions!
     *      This function follows the pattern:
     *      1. **Checks**: Validate msg.value > 0
     *      2. **Effects**: Update balances mapping
     *      3. **Interactions**: Emit event
     *
     *      🎓 LEARNING MOMENT:
     *      Events are perfect for storing historical data that doesn't need
     *      to be queried on-chain! Timestamps, transaction history, and
     *      audit logs are all great candidates for events instead of storage.
     *
     *      CONNECTION TO DEFI:
     *      Deposit functions are essential for:
     *      - Vaults: Users deposit assets to earn yield
     *      - Lending: Users deposit collateral
     *      - Staking: Users stake tokens to earn rewards
     *      All of these use events to track deposits efficiently!
     */
    function deposit() public payable {
        // 🛡️  VALIDATION: Check that ETH was actually sent
        // CONNECTION TO PROJECT 02: Input validation!
        // Prevents accidental zero deposits (wasting gas)
        // msg.value is automatically set by the EVM when ETH is sent
        require(msg.value > 0, "Must send ETH");

        // 💾 READ-MODIFY-WRITE: Update balance
        // CONNECTION TO PROJECT 01: Mapping storage updates!
        // Using += allows multiple deposits to accumulate correctly
        // This does: read balance → add msg.value → write balance
        // Cost: ~5,100 gas (warm) or ~22,100 gas (cold)
        balances[msg.sender] += msg.value; // SLOAD + ADD + SSTORE

        // 📢 EVENT EMISSION: Include timestamp in event
        // CONNECTION TO PROJECT 03: Event emission!
        // Instead of storing timestamp in mapping (~20k gas), we include it
        // in the event (~32 gas) - massive savings!
        // Off-chain systems can read the timestamp from the event
        // block.timestamp is a global variable (~2 gas to read)
        emit Deposit(msg.sender, msg.value, block.timestamp); // ~1,500 gas
    }

    /**
     * @notice Update user status string
     * @param _newStatus New status string
     *
     * @dev STRING STORAGE: The Expensive Choice
     * ═══════════════════════════════════════
     *
     *      This function demonstrates why string storage is expensive and
     *      how events can help track changes without storing full history.
     *
     *      HOW STRINGS ARE STORED:
     *      ┌─────────────────────────────────────┐
     *      │ Slot N: Length (uint256)              │ ← How many bytes?
     *      ├─────────────────────────────────────┤
     *      │ Slot N+1: First 32 bytes of data    │ ← UTF-8 encoded characters
     *      │ Slot N+2: Next 32 bytes of data     │ ← Continues if > 32 chars
     *      │ ...                                  │
     *      └─────────────────────────────────────┘
     *
     *      FUN FACT: "Hello World" (11 chars) uses 2 slots:
     *      - Slot 1: length = 11
     *      - Slot 2: "Hello World" + padding
     *      Total: ~40,000 gas (cold) vs bytes32's ~20,000 gas
     *
     *      WHY SO EXPENSIVE?
     *      1. Length encoding overhead (extra storage slot)
     *      2. UTF-8 encoding complexity (multi-byte characters)
     *      3. Dynamic size means more complex storage layout
     *
     *      CONNECTION TO PROJECT 01: String Storage Costs!
     *      ═══════════════════════════════════════════════
     *
     *      We learned in Project 01 that strings are dynamic and expensive.
     *      This function demonstrates that in practice!
     *
     *      GAS WARNING: String storage is expensive!
     *      ════════════════════════════════════════
     *
     *      ┌─────────────────────┬──────────────┬─────────────────┐
     *      │ Operation            │ Gas (warm)   │ Gas (cold)      │
     *      ├─────────────────────┼──────────────┼─────────────────┤
     *      │ Store 100-byte string│ ~20,500 gas  │ ~20,500 gas     │
     *      │ Read 100-byte string │ ~2,400 gas   │ ~2,400 gas      │
     *      │ bytes32 (32 bytes)   │ ~5,000 gas   │ ~20,000 gas     │
     *      └─────────────────────┴──────────────┴─────────────────┘
     *
     *      ALTERNATIVE: Use bytes32 instead of string for fixed-size statuses
     *      ```solidity
     *      mapping(address => bytes32) public userStatus;
     *      ```
     *      Costs: ~5,000 gas (warm) vs ~20,500 gas for string
     *      Savings: ~15,500 gas per update!
     *      But: Limited to 32 bytes, less flexible
     *
     *      GAS OPTIMIZATION: Why Cache oldStatus?
     *      ═══════════════════════════════════════
     *
     *      APPROACH 1: Read Twice (INEFFICIENT!)
     *      ```solidity
     *      emit StatusChanged(msg.sender, userStatus[msg.sender], _newStatus);
     *      userStatus[msg.sender] = _newStatus;
     *      ```
     *      - Cost: 2 SLOADs = ~4,200 gas (cold) or ~200 gas (warm)
     *      - Problem: Reads from storage twice!
     *
     *      APPROACH 2: Cache First (OPTIMAL!)
     *      ```solidity
     *      string memory oldStatus = userStatus[msg.sender];
     *      userStatus[msg.sender] = _newStatus;
     *      emit StatusChanged(msg.sender, oldStatus, _newStatus);
     *      ```
     *      - Cost: 1 SLOAD + 1 MLOAD = ~2,103 gas (cold) or ~103 gas (warm)
     *      - Savings: ~2,097 gas (cold) or ~97 gas (warm)
     *
     *      STORAGE LAYOUT FOR STRINGS:
     *      ═══════════════════════════
     *
     *      For address 0x1234... and status "Active":
     *      ┌─────────────────────────────────────────────┐
     *      │ Step 1: Calculate mapping slot              │
     *      │ keccak256(abi.encodePacked(                 │
     *      │   0x1234...,                                │
     *      │   slot_number_of_userStatus_mapping         │
     *      │ ))                                          │
     *      │ Result: base_slot = 0xABCD...              │
     *      │ ↓                                            │
     *      │ Step 2: Store length                       │
     *      │ base_slot: length = 6 (bytes)              │
     *      │ ↓                                            │
     *      │ Step 3: Store data                         │
     *      │ keccak256(base_slot): "Active" + padding   │
     *      └─────────────────────────────────────────────┘
     *
     *      REAL-WORLD ANALOGY:
     *      ═══════════════════
     *
     *      Like updating a user profile status:
     *      - **Storing string** = Writing a long bio in a database (expensive!)
     *      - **Events** = Change log entries (cheap, tracks history)
     *      - **Caching oldStatus** = Writing it on a sticky note first
     *        (so you don't have to look it up again)
     *
     *      The full string is expensive to store (like storing a long bio),
     *      but events let you track changes without storing the full history!
     *
     *      CONNECTION TO PROJECT 01: Data Location!
     *      ═══════════════════════════════════════════════════
     *
     *      Notice we use `string memory` for oldStatus?
     *      - We read from storage (expensive)
     *      - Copy to memory (cheap, temporary)
     *      - Use in event (memory is perfect for this!)
     *
     *      This is the same pattern we learned: storage → memory → use
     *
     *      🎓 LEARNING MOMENT:
     *      Always cache values you'll use multiple times!
     *      Reading from storage twice costs more than reading once and
     *      storing in memory. This is a common Solidity optimization pattern!
     */
    function updateStatus(string memory _newStatus) public {
        // 💾 CACHE OLD VALUE: Read from storage once, store in memory
        // CONNECTION TO PROJECT 01: Storage → Memory pattern!
        // Reading from storage: ~2,100 gas (cold) or ~100 gas (warm)
        // Copying to memory: ~3 gas per word (cheap!)
        // We'll use this cached value in the event below
        string memory oldStatus = userStatus[msg.sender]; // SLOAD: ~100 gas (warm)

        // 💾 UPDATE STORAGE: Write new status string
        // CONNECTION TO PROJECT 01: String storage is expensive!
        // For a 100-byte string: ~20,500 gas (cold) or ~20,500 gas (warm)
        // This is why we cache oldStatus - we don't want to read it again!
        userStatus[msg.sender] = _newStatus; // SSTORE: ~20,500 gas (string write)

        // 📢 EVENT EMISSION: Include both old and new status
        // CONNECTION TO PROJECT 03: Events for history tracking!
        // Events are perfect for tracking changes without storing full history
        // The oldStatus comes from memory (cached above) - much cheaper than
        // reading from storage again!
        emit StatusChanged(msg.sender, oldStatus, _newStatus); // ~1,500 gas
    }

    // ════════════════════════════════════════════════════════════════════════
    // VIEW FUNCTIONS
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Get balance of an account
     * @param _account Address to query
     * @return Balance amount
     *
     * @dev VIEW FUNCTIONS: Reading State Without Cost
     * ════════════════════════════════════════════════
     *
     *      View functions are special - they can read state but not modify it.
     *      When called off-chain, they're FREE! No gas cost at all!
     *
     *      HOW VIEW FUNCTIONS WORK:
     *      ┌─────────────────────────────────────────┐
     *      │ Off-chain call (e.g., from frontend)     │
     *      │   ↓                                      │
     *      │ Function executes locally                │ ← No transaction!
     *      │   ↓                                      │
     *      │ Reads state (simulated)                  │ ← Free!
     *      │   ↓                                      │
     *      │ Returns value                            │
     *      └─────────────────────────────────────────┘
     *
     *      FUN FACT: View functions don't create transactions!
     *      They're executed locally by your node, then the result is returned.
     *      This is why they're free - nothing is written to the blockchain!
     *
     *      WHEN DO VIEW FUNCTIONS COST GAS?
     *      Only when called by another contract (on-chain call):
     *      - Contract A calls Contract B's view function
     *      - This happens in a transaction
     *      - Gas is charged (~100 gas for SLOAD)
     *
     *      CONNECTION TO PROJECT 01: View Functions!
     *      ═════════════════════════════════════════
     *
     *      We learned in Project 01 that view functions are free off-chain.
     *      This is perfect for frontends to display balances!
     *
     *      CONNECTION TO PROJECT 01: Mapping Storage Reads!
     *      ═════════════════════════════════════════════════
     *
     *      This reads from the balances mapping we learned about:
     *      - Storage slot: keccak256(abi.encodePacked(_account, mapping_slot))
     *      - Cost: ~100 gas (warm) or ~2,100 gas (cold) if on-chain
     *      - Cost: FREE if called off-chain!
     *
     *      REAL-WORLD ANALOGY:
     *      ═══════════════════
     *
     *      Like checking your bank balance:
     *      - Off-chain: Look at your phone app (free, instant)
     *      - On-chain: Bank teller checks computer (costs time/money)
     *
     *      GAS COST:
     *      - Off-chain call: FREE! (no transaction)
     *      - On-chain call: ~100 gas (SLOAD from storage)
     *
     *      🎓 LEARNING MOMENT:
     *      View functions are perfect for frontends!
     *      You can call them as many times as you want without paying gas.
     *      This is why DApps can show real-time data - they're constantly
     *      calling view functions to update the UI!
     */
    function balanceOf(address _account) public view returns (uint256) {
        // 📖 READ FROM STORAGE: Simple and straightforward
        // CONNECTION TO PROJECT 01: Mapping storage read!
        // This reads from slot: keccak256(abi.encodePacked(_account, slot_number))
        // If called off-chain: FREE (no gas cost!)
        // If called on-chain: ~100 gas (SLOAD operation)
        return balances[_account]; // SLOAD: ~100 gas (if on-chain), FREE (if off-chain)
    }

    /**
     * @notice Get allowance amount
     * @param _owner Owner address
     * @param _spender Spender address
     * @return Allowance amount
     *
     * @dev ALLOWANCE QUERY: Checking Delegated Spending Power
     * ═══════════════════════════════════════════════════════
     *
     *      This function reads from nested mappings to check how much
     *      spending power has been delegated from owner to spender.
     *
     *      CONNECTION TO PROJECT 01: Nested Mapping Reads!
     *      ═══════════════════════════════════════════════
     *
     *      This uses nested mappings: mapping(address => mapping(address => uint256))
     *      - First level: Owner address
     *      - Second level: Spender address
     *      - Value: Allowance amount
     *
     *      STORAGE CALCULATION:
     *      For owner 0x1234... and spender 0x5678...:
     *      ┌─────────────────────────────────────────────┐
     *      │ Step 1: Calculate first mapping slot        │
     *      │ keccak256(abi.encodePacked(                 │
     *      │   0x1234...,                                │
     *      │   slot_number_of_allowances_mapping         │
     *      │ ))                                          │
     *      │ Result: intermediate_slot = 0xABCD...      │
     *      │ ↓                                            │
     *      │ Step 2: Calculate nested mapping slot      │
     *      │ keccak256(abi.encodePacked(                 │
     *      │   0x5678...,                                │
     *      │   intermediate_slot                         │
     *      │ ))                                          │
     *      │ Result: final_slot = 0xEF01...              │
     *      │ ↓                                            │
     *      │ Read allowance value from final_slot        │
     *      └─────────────────────────────────────────────┘
     *
     *      FUN FACT: Nested mappings require TWO keccak256 operations!
     *      This is why nested mapping reads cost slightly more gas than
     *      single-level mappings. But it's still O(1) - constant time!
     *
     *      CONNECTION TO ERC20 STANDARD:
     *      ═════════════════════════════
     *
     *      This matches the ERC20 standard allowance() function exactly!
     *      - Function signature: `allowance(address owner, address spender)`
     *      - Return type: `uint256`
     *      - Purpose: Check delegated spending power
     *
     *      Frontends use this to:
     *      - Display current approval amounts
     *      - Check if approval is needed before transfers
     *      - Show approval history
     *
     *      REAL-WORLD ANALOGY:
     *      ═══════════════════
     *
     *      Like checking a credit card limit:
     *      - **Owner** = Credit card holder
     *      - **Spender** = Authorized user
     *      - **Allowance** = Spending limit
     *      - **allowance()** = Checking the limit
     *
     *      GAS COST:
     *      - Off-chain call: FREE! (no transaction)
     *      - On-chain call: ~200 gas (2 SLOADs for nested mapping)
     *
     *      🎓 LEARNING MOMENT:
     *      This function is called constantly by frontends!
     *      Before showing "Approve" buttons, frontends check if approval
     *      is already granted. This saves users gas by avoiding unnecessary approvals!
     */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        // 📖 READ FROM NESTED MAPPING: Two-level lookup
        // CONNECTION TO PROJECT 01: Nested mapping storage read!
        // This requires TWO keccak256 operations:
        // 1. Calculate owner's slot
        // 2. Calculate spender's slot within owner's mapping
        // Cost: ~200 gas (if on-chain), FREE (if off-chain)
        return allowances[_owner][_spender]; // 2 SLOADs: ~200 gas (if on-chain), FREE (if off-chain)
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. EVENTS ARE CHEAPER THAN STORAGE
 *    ✅ Events: ~2,000 gas (permanent, searchable off-chain)
 *    ✅ Storage: ~20,000 gas (queryable on-chain)
 *    ✅ Best practice: Use storage for state, events for history!
 *
 * 2. INDEXED PARAMETERS ENABLE FILTERING
 *    ✅ Up to 3 indexed parameters per event
 *    ✅ Each indexed param costs ~375 gas extra
 *    ✅ Indexed params enable efficient off-chain queries
 *    ✅ Use indexed for addresses, IDs, and frequently filtered values
 *
 * 3. EVENTS CANNOT BE READ BY CONTRACTS
 *    ✅ Events are write-only logs
 *    ✅ Contracts can emit events but not read them
 *    ✅ Off-chain systems (indexers, frontends) read events
 *    ✅ This is by design - events are for off-chain consumption!
 *
 * 4. EVENTS ARE ESSENTIAL FOR OFF-CHAIN INDEXING
 *    ✅ Frontends rely on events for real-time updates
 *    ✅ Indexers (The Graph, Etherscan) parse events
 *    ✅ Without events, off-chain systems would need to constantly poll storage
 *    ✅ Events make blockchain data accessible and efficient!
 *
 * 5. CACHE VALUES YOU USE MULTIPLE TIMES
 *    ✅ Reading from storage twice costs more than reading once
 *    ✅ Cache storage values in memory if you'll use them multiple times
 *    ✅ This is a common Solidity optimization pattern!
 *
 * 6. STRING STORAGE IS EXPENSIVE
 *    ✅ Strings cost ~20,000+ gas to store
 *    ✅ Consider bytes32 for fixed-size data
 *    ✅ Use events to track string changes without storing full history
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMMON MISTAKES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ❌ Forgetting to emit events for state changes (breaks off-chain indexing)
 * ❌ Using more than 3 indexed parameters (compiler error!)
 * ❌ Reading from storage multiple times instead of caching
 * ❌ Storing data in events that needs to be queried on-chain
 * ❌ Using strings when bytes32 would work (gas waste)
 * ❌ Emitting events before state updates (wastes gas if transaction reverts)
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          NEXT STEPS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * • Experiment with event filtering using cast logs
 * • Study how The Graph indexes events
 * • Learn about event topics and bloom filters
 * • Move to Project 04 to learn about modifiers and access control
 * • Explore how frontends use events for real-time updates
 */
