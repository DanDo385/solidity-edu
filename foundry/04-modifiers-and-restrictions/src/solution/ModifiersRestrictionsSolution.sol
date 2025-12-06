// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ModifiersRestrictionsSolution
 * @notice Complete reference implementation of modifiers and access control
 * @dev Demonstrates gas-efficient access control patterns
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        CONCEPTUAL OVERVIEW
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * MODIFIERS: The Security Checkpoints
 * ═══════════════════════════════════════
 *
 * REAL-WORLD ANALOGY: Modifiers are like security checkpoints. Before you
 * can enter a restricted area (function), you must pass through the checkpoint
 * (modifier) that verifies your credentials (role, ownership, etc.).
 *
 * HOW MODIFIERS WORK:
 * ┌─────────────────────────────────────────┐
 * │ Function called                         │
 * │   ↓                                      │
 * │ Modifier checks execute                 │ ← Security checkpoint
 * │   ↓                                      │
 * │ If check passes: Continue               │
 * │ If check fails: Revert                  │ ← Access denied!
 * │   ↓                                      │
 * │ Function body executes                  │ ← Only if checks pass
 * └─────────────────────────────────────────┘
 *
 * FUN FACT: Modifiers are compiled into internal functions. Solc can inline
 * simple modifiers, so a clean `onlyOwner` often costs only a couple of
 * `JUMPI` opcodes in bytecode.
 *
 * KEY CONCEPTS:
 * - Modifiers: Code reuse, cleaner syntax, ~5 gas overhead per modifier
 * - Inline checks: More verbose, but same gas cost
 * - Trade-off: Modifiers are cleaner but add slight overhead
 *
 * LANGUAGE COMPARISON:
 *   TypeScript: Decorators (@decorator) - similar concept
 *   Go: No direct equivalent, use helper functions
 *   Rust: Attribute macros (#[attribute]) - similar concept
 *   Solidity: Modifiers are built-in language feature
 *
 * CONNECTION TO EARLIER CONCEPTS:
 * - Project 01: Mappings for role storage
 * - Project 02: require() statements for validation
 * - Project 03: Events for role change tracking
 * - Project 04: Modifiers combine all of these!
 */
contract ModifiersRestrictionsSolution {
    // ════════════════════════════════════════════════════════════════════════
    // STATE VARIABLES
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Role constant for admin operations
     * @dev Using keccak256 for deterministic role IDs
     *      Fun fact: keccak256 role IDs are deterministic, which keeps role
     *      management cheap on L2s and easy to replay on forks like Ethereum
     *      Classic if governance ever needs to migrate.
     *
     * WHY bytes32?
     * - Gas-efficient: Single storage slot lookup
     * - Deterministic: Same string always produces same hash
     * - Flexible: Can add new roles without changing contract structure
     */
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /**
     * @notice Role constant for minting operations
     * @dev Separate role for minting (principle of least privilege)
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @notice Contract owner address
     * @dev Set in constructor, used by onlyOwner modifier
     *      CONNECTION TO PROJECT 01: Simple address storage
     */
    address public owner;

    /**
     * @notice Pause flag for emergency stops
     * @dev When true, most operations are blocked
     *      CONNECTION TO PROJECT 01: Boolean storage
     */
    bool public paused;

    /**
     * @notice Simple counter for testing pause mechanism
     * @dev Incremented by incrementCounter() function
     */
    uint256 public counter;

   114

    // ════════════════════════════════════════════════════════════════════════
    // EVENTS
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Emitted when ownership is transferred
     * @dev CONNECTION TO PROJECT 03: Events for off-chain tracking!
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @notice Emitted when a role is granted
     * @dev Indexed parameters enable efficient filtering
     */
    event RoleGranted(bytes32 indexed role, address indexed account);

    /**
     * @notice Emitted when a role is revoked
     * @dev Indexed parameters enable efficient filtering
     */
    event RoleRevoked(bytes32 indexed role, address indexed account);

    /**
     * @notice Emitted when contract is paused
     * @dev Important for off-chain monitoring
     */
    event Paused(address account);

    /**
     * @notice Emitted when contract is unpaused
     * @dev Important for off-chain monitoring
     */
    event Unpaused(address account);

    // ════════════════════════════════════════════════════════════════════════
    // MODIFIERS
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Modifier to restrict function to owner only
     * @dev GAS COST: ~100 gas (1 SLOAD for owner) + ~5 gas modifier overhead
     *
     * GAS OPTIMIZATION: Why cache owner in modifier?
     * - Reading owner: 1 SLOAD = ~100 gas (warm)
     * - Caching saves: 0 gas (only used once)
     * - Current approach is optimal for single use
     *
     * REAL-WORLD ANALOGY: Like a bouncer at a club checking IDs.
     * Only the owner (VIP) can enter the function.
     *
     * CONNECTION TO PROJECT 02: Uses require() for validation!
     */
    modifier onlyOwner() {
        // GAS: 1 SLOAD = ~100 gas (warm)
        require(msg.sender == owner, "Not owner");
        _; // Function body executes here if check passes
    }

    /**
     * @notice Modifier to check role-based access
     * @param role The role to check
     * @dev GAS COST: ~100 gas (1 SLOAD for roles mapping) + ~5 gas modifier overhead
     *
     * GAS OPTIMIZATION: Why use nested mapping for roles?
     * - roles[account][role]: 1 SLOAD = ~100 gas (warm)
     * - Alternative: Separate mapping per role
     *   mapping(address => bool) public admins;
     *   Costs: Same gas, but requires separate mapping per role
     * - Trade-off: Nested mapping is more flexible, same gas cost
     *
     * REAL-WORLD ANALOGY: Like checking if someone has a specific badge.
     * Each role is a different badge, and you need the right badge to enter.
     *
     * CONNECTION TO PROJECT 01: Nested mappings!
     */
    modifier onlyRole(bytes32 role) {
        // GAS: 1 SLOAD = ~100 gas (warm)
        require(roles[msg.sender][role], "Missing role");
        _; // Function body executes here if check passes
    }

    /**
     * @notice Modifier to ensure contract is not paused
     * @dev GAS COST: ~100 gas (1 SLOAD for paused) + ~5 gas modifier overhead
     *
     * REAL-WORLD ANALOGY: Like checking if a store is open before entering.
     * The pause mechanism is an emergency stop - if paused, no operations allowed.
     *
     * CONNECTION TO PROJECT 02: Checks-Effects-Interactions pattern!
     */
    modifier whenNotPaused() {
        // GAS: 1 SLOAD = ~100 gas (warm)
        require(!paused, "Contract paused");
        _; // Function body executes here if check passes
    }

    /**
     * @notice Modifier to ensure contract is paused
     * @dev Used for functions that should only work when paused (like unpause)
     *      GAS COST: ~100 gas (1 SLOAD for paused) + ~5 gas modifier overhead
     */
    modifier whenPaused() {
        // GAS: 1 SLOAD = ~100 gas (warm)
        require(paused, "Contract not paused");
        _; // Function body executes here if check passes
    }

    // ════════════════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Initializes the contract
     * @dev Sets owner and grants initial roles
     *      CONNECTION TO PROJECT 01: Constructor pattern!
     */
    constructor() {
        owner = msg.sender;
        // Grant deployer both ADMIN_ROLE and MINTER_ROLE
        roles[msg.sender][ADMIN_ROLE] = true;
        roles[msg.sender][MINTER_ROLE] = true;
    }

    // ════════════════════════════════════════════════════════════════════════
    // OWNER FUNCTIONS
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Transfer ownership to a new address
     * @param newOwner The new owner address
     *
     * @dev OWNERSHIP TRANSFER: Critical Security Operation
     * ════════════════════════════════════════════════════
     *
     *      Transferring ownership is a CRITICAL operation that permanently
     *      changes who controls the contract. This must be done carefully!
     *
     *      EXECUTION FLOW:
     *      ┌─────────────────────────────────────────┐
     *      │ 1. MODIFIER CHECK: onlyOwner              │
     *      │    - Verifies msg.sender == owner         │
     *      │    - Reverts if not owner                 │
     *      │    ↓                                      │
     *      │ 2. VALIDATION: Check new owner            │
     *      │    - Must not be zero address            │
     *      │    ↓                                      │
     *      │ 3. CACHE OLD OWNER: Store current owner  │
     *      │    - Needed for event                    │
     *      │    ↓                                      │
     *      │ 4. UPDATE STATE: Set new owner           │
     *      │    - owner = newOwner                    │
     *      │    ↓                                      │
     *      │ 5. EMIT EVENT: Log the transfer          │
     *      │    - OwnershipTransferred(old, new)       │
     *      └─────────────────────────────────────────┘
     *
     *      CONNECTION TO PROJECT 04: Modifier Usage!
     *      ═══════════════════════════════════════════
     *
     *      This function uses the `onlyOwner` modifier we defined earlier.
     *      The modifier executes FIRST, before the function body!
     *
     *      MODIFIER EXECUTION:
     *      ┌─────────────────────────────────────────┐
     *      │ Function called                         │
     *      │   ↓                                      │
     *      │ onlyOwner modifier executes              │
     *      │   - Checks: msg.sender == owner?         │
     *      │   - If NO: Revert with "Not owner"     │
     *      │   - If YES: Continue                    │
     *      │   ↓                                      │
     *      │ Function body executes                  │
     *      └─────────────────────────────────────────┘
     *
     *      CONNECTION TO PROJECT 01: Storage Updates!
     *      ══════════════════════════════════════════
     *
     *      We're updating the owner state variable:
     *      - Stored in slot 0 (first state variable)
     *      - Cost: ~5,000 gas (warm) or ~20,000 gas (cold)
     *
     *      STORAGE UPDATE:
     *      ┌─────────────────────────────────────────────┐
     *      │ Slot 0: owner (address)                     │
     *      │ Old value: 0x1234... (current owner)      │
     *      │ New value: 0x5678... (new owner)          │
     *      │ Operation: SSTORE                           │
     *      │ Cost: ~5,000 gas (warm)                    │
     *      └─────────────────────────────────────────────┘
     *
     *      GAS OPTIMIZATION: Why Cache oldOwner?
     *      ═══════════════════════════════════════
     *
     *      APPROACH 1: Read Twice (INEFFICIENT!)
     *      ```solidity
     *      emit OwnershipTransferred(owner, newOwner);
     *      owner = newOwner;
     *      ```
     *      - Cost: 2 SLOADs = ~200 gas (warm)
     *      - Problem: Reads from storage twice!
     *
     *      APPROACH 2: Cache First (OPTIMAL!)
     *      ```solidity
     *      address oldOwner = owner;
     *      owner = newOwner;
     *      emit OwnershipTransferred(oldOwner, newOwner);
     *      ```
     *      - Cost: 1 SLOAD + 1 MLOAD = ~103 gas (warm)
     *      - Savings: ~97 gas per transfer
     *
     *      GAS COST BREAKDOWN:
     *      ┌─────────────────────┬──────────────┬─────────────────┐
     *      │ Operation           │ Gas (warm)   │ Gas (cold)      │
     *      ├─────────────────────┼──────────────┼─────────────────┤
     *      │ Modifier check      │ ~100 gas     │ ~2,100 gas      │
     *      │ require() check     │ ~3 gas       │ ~3 gas          │
     *      │ SLOAD owner         │ ~100 gas     │ ~2,100 gas      │
     *      │ SSTORE owner        │ ~5,000 gas   │ ~20,000 gas     │
     *      │ Event emission      │ ~1,500 gas   │ ~1,500 gas      │
     *      ├─────────────────────┼──────────────┼─────────────────┤
     *      │ TOTAL (warm)        │ ~6,703 gas   │                 │
     *      │ TOTAL (cold)        │              │ ~25,703 gas     │
     *      └─────────────────────┴──────────────┴─────────────────┘
     *
     *      SECURITY CONSIDERATIONS:
     *      ═════════════════════════
     *
     *      ⚠️  Always validate new owner is not zero address:
     *      - Prevents losing ownership permanently
     *      - Zero address can't call owner functions
     *      - Prevents accidental transfers
     *
     *      ⚠️  Ownership transfer is IRREVERSIBLE:
     *      - Once transferred, old owner loses all privileges
     *      - New owner gains all privileges immediately
     *      - No way to undo without new owner's cooperation
     *
     *      ⚠️  Production Best Practices:
     *      - Use multi-sig wallets for ownership
     *      - Add timelock for ownership transfers
     *      - Consider two-step ownership transfer (propose → accept)
     *      - OpenZeppelin's Ownable2Step implements this pattern
     *
     *      CONNECTION TO PROJECT 02: Input Validation!
     *      ═══════════════════════════════════════════
     *
     *      We validate the new owner address before transferring.
     *      This follows the input validation pattern we learned!
     *
     *      CONNECTION TO PROJECT 03: Event Emission!
     *      ══════════════════════════════════════════
     *
     *      We emit an event to log the ownership transfer.
     *      This is essential for off-chain tracking and transparency!
     *
     *      REAL-WORLD ANALOGY:
     *      ═══════════════════
     *
     *      Like transferring a company's CEO position:
     *      - **Old owner** = Current CEO
     *      - **New owner** = New CEO
     *      - **Transfer** = Handing over control
     *      - **Event** = Public announcement (permanent record)
     *
     *      Once transferred, the old CEO loses all privileges,
     *      and the new CEO gains them immediately!
     *
     *      🎓 LEARNING MOMENT:
     *      Ownership transfer is one of the most critical operations!
     *      Always validate inputs, emit events, and consider using
     *      two-step transfers for production contracts!
     */
    function transferOwnership(address newOwner) public onlyOwner {
        // 🛡️  VALIDATION: Check new owner is not zero address
        // CONNECTION TO PROJECT 02: Input validation!
        // Prevents losing ownership permanently (zero address can't call functions)
        require(newOwner != address(0), "Invalid address");

        // 💾 CACHE OLD OWNER: Read from storage once
        // CONNECTION TO PROJECT 01: Storage read pattern!
        // We'll use this in the event below - caching saves gas!
        // Cost: ~100 gas (warm) or ~2,100 gas (cold)
        address oldOwner = owner; // SLOAD: ~100 gas (warm)

        // 💾 UPDATE STATE: Transfer ownership
        // CONNECTION TO PROJECT 01: Storage write!
        // This permanently changes who controls the contract
        // Cost: ~5,000 gas (warm) or ~20,000 gas (cold)
        owner = newOwner; // SSTORE: ~5,000 gas (warm)

        // 📢 EVENT EMISSION: Log the ownership transfer
        // CONNECTION TO PROJECT 03: Event emission!
        // This is critical for transparency and off-chain tracking
        // Frontends and indexers listen to this event
        // Cost: ~1,500 gas
        emit OwnershipTransferred(oldOwner, newOwner); // ~1,500 gas
    }

    // ════════════════════════════════════════════════════════════════════════
    // ROLE MANAGEMENT FUNCTIONS
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Grant a role to an account
     * @param role The role to grant
     * @param account The account to grant the role to
     * @dev Uses onlyOwner modifier
     *      CONNECTION TO PROJECT 02: Input validation!
     *      CONNECTION TO PROJECT 03: Event emission!
     *
     * GAS OPTIMIZATION: Check before granting
     * - Prevents unnecessary storage writes
     * - Saves gas if role already granted
     */
    function grantRole(bytes32 role, address account) public onlyOwner {
        require(!roles[account][role], "Role already granted");
        roles[account][role] = true;
        emit RoleGranted(role, account);
    }

    /**
     * @notice Revoke a role from an account
     * @param role The role to revoke
     * @param account The account to revoke the role from
     * @dev Uses onlyOwner modifier
     *      CONNECTION TO PROJECT 02: Input validation!
     *      CONNECTION TO PROJECT 03: Event emission!
     *
     * GAS OPTIMIZATION: Check before revoking
     * - Prevents unnecessary storage writes
     * - Saves gas if role not granted
     */
    function revokeRole(bytes32 role, address account) public onlyOwner {
        require(roles[account][role], "Role not granted");
        roles[account][role] = false;
        emit RoleRevoked(role, account);
    }

    // ════════════════════════════════════════════════════════════════════════
    // PAUSE FUNCTIONS
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Pause the contract (emergency stop)
     *
     * @dev PAUSE MECHANISM: Emergency Stop Pattern
     * ═════════════════════════════════════════════
     *
     *      The pause mechanism is a critical security feature that allows
     *      administrators to stop all operations in case of an emergency.
     *
     *      HOW PAUSING WORKS:
     *      ┌─────────────────────────────────────────┐
     *      │ 1. MODIFIER CHECK: onlyRole(ADMIN_ROLE) │
     *      │    - Verifies caller has ADMIN_ROLE     │
     *      │    - Reverts if missing role             │
     *      │    ↓                                      │
     *      │ 2. VALIDATION: Check not already paused │
     *      │    - Prevents redundant pauses          │
     *      │    ↓                                      │
     *      │ 3. UPDATE STATE: Set paused = true      │
     *      │    - Blocks all operations              │
     *      │    ↓                                      │
     *      │ 4. EMIT EVENT: Log the pause            │
     *      │    - Off-chain systems can react        │
     *      └─────────────────────────────────────────┘
     *
     *      CONNECTION TO PROJECT 04: Modifier Usage!
     *      ═══════════════════════════════════════════
     *
     *      This function uses `onlyRole(ADMIN_ROLE)` modifier.
     *      Only addresses with ADMIN_ROLE can pause the contract!
     *
     *      MODIFIER EXECUTION:
     *      ┌─────────────────────────────────────────┐
     *      │ Function called                         │
     *      │   ↓                                      │
     *      │ onlyRole(ADMIN_ROLE) modifier executes  │
     *      │   - Checks: roles[msg.sender][ADMIN_ROLE]?│
     *      │   - If NO: Revert with "Missing role"  │
     *      │   - If YES: Continue                    │
     *      │   ↓                                      │
     *      │ Function body executes                  │
     *      └─────────────────────────────────────────┘
     *
     *      CONNECTION TO PROJECT 01: Boolean Storage!
     *      ══════════════════════════════════════════
     *
     *      We're updating the paused boolean:
     *      - Stored in slot 1 (second state variable)
     *      - Cost: ~5,000 gas (warm) or ~20,000 gas (cold)
     *
     *      STORAGE UPDATE:
     *      ┌─────────────────────────────────────────────┐
     *      │ Slot 1: paused (bool)                       │
     *      │ Old value: false                            │
     *      │ New value: true                             │
     *      │ Operation: SSTORE                           │
     *      │ Cost: ~5,000 gas (warm)                     │
     *      └─────────────────────────────────────────────┘
     *
     *      WHAT HAPPENS WHEN PAUSED:
     *      ═════════════════════════
     *
     *      Functions with `whenNotPaused` modifier will revert:
     *      ```solidity
     *      function mint() public whenNotPaused {
     *          // This will revert if paused = true
     *      }
     *      ```
     *
     *      This provides an emergency stop mechanism!
     *
     *      GAS COST BREAKDOWN:
     *      ┌─────────────────────┬──────────────┬─────────────────┐
     *      │ Operation           │ Gas (warm)   │ Gas (cold)      │
     *      ├─────────────────────┼──────────────┼─────────────────┤
     *      │ Modifier check      │ ~100 gas     │ ~2,100 gas      │
     *      │ require() check     │ ~3 gas       │ ~3 gas          │
     *      │ SSTORE paused      │ ~5,000 gas   │ ~20,000 gas     │
     *      │ Event emission      │ ~1,500 gas   │ ~1,500 gas      │
     *      ├─────────────────────┼──────────────┼─────────────────┤
     *      │ TOTAL (warm)        │ ~6,603 gas   │                 │
     *      │ TOTAL (cold)        │              │ ~23,603 gas     │
     *      └─────────────────────┴──────────────┴─────────────────┘
     *
     *      REAL-WORLD ANALOGY:
     *      ═══════════════════
     *
     *      Like a fire alarm in a building:
     *      - **Pause** = Pulling the fire alarm
     *      - **paused = true** = Alarm activated
     *      - **whenNotPaused modifier** = Doors locked, operations stopped
     *      - **Unpause** = Resetting the alarm
     *
     *      When the alarm is activated, all operations stop immediately
     *      for safety. The pause mechanism works the same way!
     *
     *      SECURITY CONSIDERATIONS:
     *      ═════════════════════════
     *
     *      ⚠️  Only admins can pause:
     *      - Prevents unauthorized pauses
     *      - Allows emergency response
     *      - Consider multi-sig for production
     *
     *      ⚠️  Pause is IRREVERSIBLE without unpause():
     *      - Once paused, contract stays paused
     *      - Must call unpause() to resume operations
     *      - This prevents accidental permanent pauses
     *
     *      ⚠️  Production Best Practices:
     *      - Use timelock for pause/unpause (prevents immediate pauses)
     *      - Consider partial pauses (pause specific functions)
     *      - Monitor pause events off-chain for alerts
     *
     *      CONNECTION TO PROJECT 02: Input Validation!
     *      ═══════════════════════════════════════════
     *
     *      We check if already paused before pausing.
     *      This prevents redundant operations and saves gas!
     *
     *      CONNECTION TO PROJECT 03: Event Emission!
     *      ══════════════════════════════════════════
     *
     *      We emit an event when the contract is paused.
     *      This is critical for off-chain monitoring and alerts!
     *
     *      🎓 LEARNING MOMENT:
     *      Pause mechanisms are essential for incident response!
     *      If a bug is discovered, admins can pause the contract
     *      immediately to prevent further damage while fixing the issue.
     */
    function pause() public onlyRole(ADMIN_ROLE) {
        // 🛡️  VALIDATION: Check not already paused
        // CONNECTION TO PROJECT 02: Input validation!
        // Prevents redundant pauses (saves gas)
        // If already paused, this will revert
        require(!paused, "Already paused");

        // 💾 UPDATE STATE: Set paused flag to true
        // CONNECTION TO PROJECT 01: Boolean storage write!
        // This permanently blocks all operations until unpaused
        // Cost: ~5,000 gas (warm) or ~20,000 gas (cold)
        paused = true; // SSTORE: ~5,000 gas (warm)

        // 📢 EVENT EMISSION: Log the pause
        // CONNECTION TO PROJECT 03: Event emission!
        // Critical for off-chain monitoring and alerts
        // Frontends and monitoring systems listen to this event
        // Cost: ~1,500 gas
        emit Paused(msg.sender); // ~1,500 gas
    }

    /**
     * @notice Unpause the contract
     * @dev Uses onlyRole(ADMIN_ROLE) and whenPaused modifiers
     *      CONNECTION TO PROJECT 03: Event emission!
     *
     * MODIFIER COMPOSITION: Two modifiers!
     * - onlyRole(ADMIN_ROLE): Must have admin role
     * - whenPaused: Contract must be paused
     * - Execution: Check role → Check paused → Execute function
     */
    function unpause() public onlyRole(ADMIN_ROLE) whenPaused {
        require(paused, "Not paused");
        paused = false;
        emit Unpaused(msg.sender);
    }

    // ════════════════════════════════════════════════════════════════════════
    // EXAMPLE FUNCTIONS USING MODIFIERS
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Increment counter (example function)
     * @dev Uses whenNotPaused modifier
     *      Demonstrates pause mechanism in action
     *
     * CONNECTION TO PROJECT 01: Simple state update!
     */
    function incrementCounter() public whenNotPaused {
        counter++;
    }

    /**
     * @notice Mint function (example)
     * @param to Address to mint to
     * @dev Uses onlyRole(MINTER_ROLE) and whenNotPaused modifiers
     *      MODIFIER COMPOSITION: Two modifiers!
     *      - onlyRole(MINTER_ROLE): Must have minter role
     *      - whenNotPaused: Contract must not be paused
     *      - Execution: Check role → Check paused → Execute function
     *
     * REAL-WORLD ANALOGY: Like needing both a key card AND the building to be open.
     * You need the minter role (key card) AND the contract must not be paused (building open).
     *
     * CONNECTION TO PROJECT 02: Checks-Effects-Interactions pattern!
     */
    function mint(address to) public onlyRole(MINTER_ROLE) whenNotPaused {
        // Minting logic would go here
        // This is just an example to show modifier composition
    }

    // ════════════════════════════════════════════════════════════════════════
    // VIEW FUNCTIONS
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Check if an account has a role
     * @param role The role to check
     * @param account The account to check
     * @return True if account has role, false otherwise
     *
     * @dev ROLE CHECK: Querying Access Control
     * ═════════════════════════════════════════
     *
     *      This function reads from nested mappings to check role membership.
     *      It's a view function, so it's FREE when called off-chain!
     *
     *      CONNECTION TO PROJECT 01: View Functions!
     *      ═════════════════════════════════════════
     *
     *      View functions are free when called off-chain.
     *      This is perfect for frontends to check permissions!
     *
     *      CONNECTION TO PROJECT 01: Nested Mapping Reads!
     *      ═══════════════════════════════════════════════
     *
     *      This reads from nested mappings: mapping(address => mapping(bytes32 => bool))
     *      - First level: Account address
     *      - Second level: Role identifier (bytes32)
     *      - Value: Boolean (true if has role)
     *
     *      STORAGE CALCULATION:
     *      For account 0x1234... and role ADMIN_ROLE:
     *      ┌─────────────────────────────────────────────┐
     *      │ Step 1: Calculate first mapping slot        │
     *      │ keccak256(abi.encodePacked(                 │
     *      │   0x1234...,                                │
     *      │   slot_number_of_roles_mapping              │
     *      │ ))                                          │
     *      │ Result: intermediate_slot = 0xABCD...      │
     *      │ ↓                                            │
     *      │ Step 2: Calculate nested mapping slot      │
     *      │ keccak256(abi.encodePacked(                 │
     *      │   ADMIN_ROLE (bytes32),                      │
     *      │   intermediate_slot                         │
     *      │ ))                                          │
     *      │ Result: final_slot = 0xEF01...              │
     *      │ ↓                                            │
     *      │ Read boolean value from final_slot          │
     *      └─────────────────────────────────────────────┘
     *
     *      FUN FACT: Role constants (like ADMIN_ROLE) are computed at compile time!
     *      keccak256("ADMIN_ROLE") produces the same hash every time.
     *      This makes role checks deterministic and gas-efficient.
     *
     *      REAL-WORLD ANALOGY:
     *      ═══════════════════
     *
     *      Like checking if someone has a badge:
     *      - **Account** = Person
     *      - **Role** = Badge type (Admin, Minter, etc.)
     *      - **hasRole()** = Checking if person has badge
     *      - **Result** = True/False (has badge or not)
     *
     *      GAS COST:
     *      - Off-chain call: FREE! (no transaction)
     *      - On-chain call: ~200 gas (2 SLOADs for nested mapping)
     *
     *      🎓 LEARNING MOMENT:
     *      This function is called constantly by frontends!
     *      Before showing admin buttons, frontends check if user has admin role.
     *      This prevents UI confusion and improves UX!
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        // 📖 READ FROM NESTED MAPPING: Two-level lookup
        // CONNECTION TO PROJECT 01: Nested mapping storage read!
        // This requires TWO keccak256 operations:
        // 1. Calculate account's slot
        // 2. Calculate role's slot within account's mapping
        // Cost: ~200 gas (if on-chain), FREE (if off-chain)
        return roles[account][role]; // 2 SLOADs: ~200 gas (if on-chain), FREE (if off-chain)
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. MODIFIERS ARE REUSABLE SECURITY CHECKS
 *    ✅ Reduce code duplication
 *    ✅ Enforce preconditions consistently
 *    ✅ Can take parameters (like onlyRole(bytes32))
 *    ✅ Chain multiple modifiers together
 *    ✅ Real-world: Like security checkpoints - must pass all to enter
 *
 * 2. MODIFIER EXECUTION ORDER MATTERS
 *    ✅ Modifiers execute left-to-right, then function body
 *    ✅ function example() modifierA modifierB { }
 *       Execution: modifierA → modifierB → function body
 *    ✅ Put cheaper checks first (like whenNotPaused)
 *    ✅ Put expensive checks last (like role lookups)
 *
 * 3. ROLE-BASED ACCESS CONTROL (RBAC)
 *    ✅ Uses nested mappings: mapping(address => mapping(bytes32 => bool))
 *    ✅ Roles are bytes32 constants (keccak256("ROLE_NAME"))
 *    ✅ Deterministic: Same string always produces same hash
 *    ✅ Flexible: Can add new roles without changing contract structure
 *    ✅ Real-world: Like employee badges - different roles, different access
 *
 * 4. PAUSE MECHANISM FOR EMERGENCY STOPS
 *    ✅ Emergency stop pattern for contracts
 *    ✅ whenNotPaused: Blocks operations when paused
 *    ✅ whenPaused: Allows unpause when paused
 *    ✅ Critical for incident response
 *    ✅ Real-world: Like a fire alarm - stops everything immediately
 *
 * 5. MODIFIER COMPOSITION IS POWERFUL
 *    ✅ Can chain multiple modifiers: onlyRole(MINTER_ROLE) whenNotPaused
 *    ✅ Each modifier adds ~5 gas overhead
 *    ✅ Keep modifiers simple for gas efficiency
 *    ✅ Real-world: Like needing both ID and boarding pass to board plane
 *
 * 6. OWNER PATTERN IS COMMON BUT HAS LIMITATIONS
 *    ✅ Simple: Single owner address
 *    ✅ Flexible: Owner can transfer ownership
 *    ✅ Limitation: Single point of failure
 *    ✅ Production: Use multi-sig or timelock
 *    ✅ Real-world: Like a single key holder vs multiple key holders
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMMON MISTAKES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ❌ Forgetting to validate inputs in modifiers (zero address, etc.)
 * ❌ Complex logic in modifiers (harder to audit, more gas)
 * ❌ Not emitting events when roles change (breaks off-chain tracking)
 * ❌ Using separate mappings per role instead of nested mapping
 * ❌ Not checking if role already granted/revoked (wastes gas)
 * ❌ Modifier order causing unnecessary gas costs
 * ❌ Single owner without backup (single point of failure)
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          NEXT STEPS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * • Study OpenZeppelin's Ownable and AccessControl contracts
 * • Implement time-locked operations (add delays to critical functions)
 * • Learn about multi-sig wallets and their access control patterns
 * • Explore upgradeable proxy patterns and their access control implications
 * • Move to Project 05 to learn about errors and reverts
 */
