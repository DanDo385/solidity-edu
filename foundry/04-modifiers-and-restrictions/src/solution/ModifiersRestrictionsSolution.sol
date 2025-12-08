// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ModifiersRestrictionsSolution
 * @notice Educational contract demonstrating modifiers, access control, and pause functionality
 * 
 * ═══════════════════════════════════════════════════════════════════════════
 *                        CONTRACT PURPOSE
 * ═══════════════════════════════════════════════════════════════════════════
 * 
 * This contract builds on Projects 01-03 and introduces:
 * 
 * 1. **Modifiers**: Code reuse and access control
 *    - Reusable code that wraps functions
 *    - Similar to decorators in Python or annotations in Java
 *    - Essential for DRY (Don't Repeat Yourself) principle
 * 
 * 2. **Access Control Patterns**: Owner and role-based access
 *    - Owner pattern (from Projects 01-02, now with modifiers)
 *    - Role-based access control (RBAC)
 *    - Multi-level permission system
 * 
 * 3. **Pause Functionality**: Emergency stop mechanism
 *    - Allows pausing contract operations
 *    - Critical for security and upgrades
 *    - Common in production contracts
 * 
 * REAL-WORLD USE CASES:
 * - Token contracts (minting, pausing)
 * - DeFi protocols (admin functions, emergency stops)
 * - Governance systems (role-based voting)
 * - Any contract needing access control
 * 
 * ═══════════════════════════════════════════════════════════════════════════
 *                    COMPUTER SCIENCE CONCEPTS
 * ═══════════════════════════════════════════════════════════════════════════
 * 
 * 1. **Modifiers (Aspect-Oriented Programming)**
 *    - Similar to decorators, annotations, or middleware
 *    - Wrap functions with reusable logic
 *    - Execute before (and optionally after) function body
 * 
 * 2. **Access Control (Authorization)**
 *    - Owner pattern: Single admin
 *    - RBAC: Multiple roles with different permissions
 *    - Essential for secure smart contracts
 * 
 * 3. **State Machine (Pause Pattern)**
 *    - Contract can be in paused or unpaused state
 *    - Prevents operations when paused
 *    - Emergency stop mechanism
 * 
 * 4. **Constants and Deterministic Hashes**
 *    - Constants save gas (no storage slot)
 *    - keccak256 creates deterministic hashes
 *    - Same input = same output (cross-chain compatible)
 * 
 * CONNECTION TO PROJECT 01:
 * - Uses mapping storage for roles
 * - Uses owner pattern (from Project 01)
 * - Builds on storage layout concepts
 * 
 * CONNECTION TO PROJECT 02:
 * - Generalizes owner checks with modifiers
 * - Replaces manual require() checks
 * - Cleaner, more maintainable code
 * 
 * CONNECTION TO PROJECT 03:
 * - Uses events for role changes
 * - Logs ownership transfers
 * - Event-driven architecture
 * 
 * @dev This is the FOURTH project - generalizes access control patterns
 */
contract ModifiersRestrictionsSolution {
    // ════════════════════════════════════════════════════════════════════════
    // CONSTANTS - Deterministic Role Identifiers
    // ════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Admin role identifier
     * @dev CONSTANT DECLARATION (Computer Science: Immutable Values)
     * 
     * Constants are compile-time values stored in bytecode, not storage.
     * They don't consume storage slots (save gas!).
     * 
     * DETERMINISTIC HASHES:
     * - keccak256("ADMIN_ROLE") always produces same hash
     * - Same across all chains and deployments
     * - Enables cross-chain compatibility
     * 
     * COMPUTER SCIENCE: Hash Functions
     * - keccak256: Cryptographic hash function
     * - Deterministic: Same input = same output
     * - One-way: Can't reverse hash to get input
     * 
     * GAS SAVINGS:
     * - Constant: No storage slot (free!)
     * - Variable: ~20,000 gas to initialize
     * 
     * SYNTAX: bytes32 public constant ROLE = keccak256("ROLE");
     * - constant: Value set at compile time
     * - public: Generates getter function
     * - bytes32: 32-byte hash value
     */
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // ════════════════════════════════════════════════════════════════════════
    // STATE VARIABLES
    // ════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Contract owner
     * @dev CONNECTION TO PROJECT 01: Address storage pattern
     * Used for owner-only functions (generalized with modifiers)
     */
    address public owner;

    /**
     * @notice Pause state flag
     * @dev CONNECTION TO PROJECT 01: Boolean storage
     * When true, most functions are disabled (emergency stop)
     */
    bool public paused;

    /**
     * @notice Example counter for demonstration
     * @dev Simple state variable for testing pause functionality
     */
    uint256 public counter;

    /**
     * @notice Role mapping (account => role => hasRole)
     * @dev CONNECTION TO PROJECT 01: Nested mapping storage pattern!
     * Storage: keccak256(keccak256(account, slot), role)
     * Enables role-based access control (RBAC)
     */
    mapping(address => mapping(bytes32 => bool)) private roles;

    // ════════════════════════════════════════════════════════════════════════
    // EVENTS - Access Control and State Changes
    // ════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Events for tracking access control changes
     * @dev CONNECTION TO PROJECT 03: Event emission pattern
     * Events log all important state changes for off-chain tracking
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event RoleGranted(bytes32 indexed role, address indexed account);
    event RoleRevoked(bytes32 indexed role, address indexed account);
    event Paused(address account);
    event Unpaused(address account);

    // ════════════════════════════════════════════════════════════════════════
    // MODIFIERS - Code Reuse and Access Control
    // ════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Modifier: Only owner can call
     * @dev MODIFIER DECLARATION (Computer Science: Aspect-Oriented Programming)
     * 
     * Modifiers wrap functions with reusable logic.
     * They execute before the function body (and optionally after).
     * 
     * COMPUTER SCIENCE: Aspect-Oriented Programming
     * - Similar to decorators in Python (@decorator)
     * - Similar to annotations in Java (@Annotation)
     * - Similar to middleware in web frameworks
     * 
     * EXECUTION FLOW:
     * 1. Modifier code executes (before function)
     * 2. _; (placeholder for function body)
     * 3. Optional: More modifier code (after function)
     * 
     * CONNECTION TO PROJECT 02: Generalizes owner checks!
     * - Instead of: require(msg.sender == owner, "Not owner");
     * - Use: modifier onlyOwner() { ... }
     * - Cleaner, more maintainable code
     * 
     * SYNTAX: modifier name() { require(...); _; }
     * - modifier: Keyword for modifier declaration
     * - _; : Placeholder for function body
     * - Can have parameters: modifier onlyRole(bytes32 role)
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _; // Function body executes here
    }

    /**
     * @notice Modifier: Only accounts with specific role can call
     * @dev ROLE-BASED ACCESS CONTROL (Computer Science: RBAC)
     * 
     * Demonstrates parameterized modifiers.
     * Enables flexible, reusable access control.
     * 
     * CONNECTION TO PROJECT 01: Nested mapping storage read!
     * - roles[msg.sender][role]: Check if account has role
     * - O(1) lookup time (hash table property)
     * 
     * RBAC PATTERN:
     * - Multiple roles (ADMIN, MINTER, etc.)
     * - Each role has different permissions
     * - More flexible than owner-only pattern
     * 
     * SYNTAX: modifier onlyRole(bytes32 role) { ... }
     * - Parameters: Modifiers can take parameters
     * - Flexible: Same modifier for different roles
     */
    modifier onlyRole(bytes32 role) {
        // CONNECTION TO PROJECT 01: Nested mapping storage read!
        require(roles[msg.sender][role], "Missing role"); // 2 SLOADs: ~200 gas
        _; // Function body executes here
    }

    /**
     * @notice Modifier: Function can only be called when not paused
     * @dev PAUSE PATTERN (Computer Science: State Machine)
     * 
     * Prevents function execution when contract is paused.
     * Critical for emergency stops and upgrades.
     * 
     * STATE MACHINE:
     * - Contract has two states: paused or unpaused
     * - Most functions require unpaused state
     * - Admin can pause/unpause
     * 
     * USE CASES:
     * - Emergency stops (security issues)
     * - Upgrades (pause, upgrade, unpause)
     * - Maintenance windows
     * 
     * SYNTAX: modifier whenNotPaused() { require(!paused, "Paused"); _; }
     * - !paused: Negation operator (not paused)
     * - Reverts if paused is true
     */
    modifier whenNotPaused() {
        require(!paused, "Paused");
        _; // Function body executes here
    }

    /**
     * @notice Modifier: Function can only be called when paused
     * @dev INVERSE PAUSE PATTERN
     * 
     * Some functions (like unpause) can only be called when paused.
     * Demonstrates inverse state checks.
     * 
     * SYNTAX: modifier whenPaused() { require(paused, "Not paused"); _; }
     * - Only allows execution when paused is true
     * - Used for functions that should only run when paused
     */
    modifier whenPaused() {
        require(paused, "Not paused");
        _; // Function body executes here
    }

    /**
     * @notice Constructor - initializes owner and roles
     * @dev CONNECTION TO PROJECT 01: Constructor pattern
     * Sets deployer as owner and grants initial roles
     */
    constructor() {
        owner = msg.sender;
        // Grant deployer admin and minter roles
        roles[msg.sender][ADMIN_ROLE] = true; // CONNECTION TO PROJECT 01: Nested mapping write!
        roles[msg.sender][MINTER_ROLE] = true;
    }

    /**
     * @notice Transfer ownership to new address
     * @dev OWNERSHIP TRANSFER (Computer Science: State Transition)
     * 
     * MODIFIER USAGE: onlyOwner
     * - Wraps function with owner check
     * - Cleaner than manual require() check
     * 
     * CONNECTION TO PROJECT 02: Owner pattern generalized!
     * - Project 02: Manual require(msg.sender == owner)
     * - Project 04: Modifier onlyOwner (cleaner!)
     * 
     * SYNTAX: function name() public onlyOwner { ... }
     * - Modifier applied after function declaration
     * - Executes before function body
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner); // CONNECTION TO PROJECT 03: Event emission!
    }

    /**
     * @notice Grant role to account
     * @dev ROLE MANAGEMENT (Computer Science: Permission System)
     * 
     * MODIFIER USAGE: onlyOwner
     * - Only owner can grant roles
     * - Demonstrates modifier chaining
     * 
     * CONNECTION TO PROJECT 01: Nested mapping storage write!
     * - roles[account][role] = true
     * - Enables account to use functions with onlyRole(role)
     */
    function grantRole(bytes32 role, address account) public onlyOwner {
        require(account != address(0), "Invalid account");
        require(!roles[account][role], "Role already granted");
        roles[account][role] = true; // CONNECTION TO PROJECT 01: Nested mapping write!
        emit RoleGranted(role, account); // CONNECTION TO PROJECT 03: Event emission!
    }

    /**
     * @notice Revoke role from account
     * @dev ROLE REVOCATION
     * 
     * Removes permission from account.
     * Sets role to false (removes from mapping).
     */
    function revokeRole(bytes32 role, address account) public onlyOwner {
        require(roles[account][role], "Role missing");
        roles[account][role] = false; // CONNECTION TO PROJECT 01: Nested mapping write!
        emit RoleRevoked(role, account); // CONNECTION TO PROJECT 03: Event emission!
    }

    /**
     * @notice Pause contract operations
     * @dev PAUSE FUNCTION (Computer Science: Emergency Stop)
     * 
     * MODIFIER USAGE: onlyRole(ADMIN_ROLE)
     * - Only admin can pause
     * - Demonstrates parameterized modifier
     * 
     * STATE TRANSITION:
     * - paused: false → true
     * - Disables functions with whenNotPaused modifier
     */
    function pause() public onlyRole(ADMIN_ROLE) {
        require(!paused, "Already paused");
        paused = true; // CONNECTION TO PROJECT 01: Boolean storage write!
        emit Paused(msg.sender); // CONNECTION TO PROJECT 03: Event emission!
    }

    /**
     * @notice Unpause contract operations
     * @dev UNPAUSE FUNCTION
     * 
     * MODIFIER CHAINING: onlyRole(ADMIN_ROLE) whenPaused
     * - Multiple modifiers can be applied
     * - Execute in order (left to right)
     * - All must pass for function to execute
     * 
     * STATE TRANSITION:
     * - paused: true → false
     * - Re-enables functions with whenNotPaused modifier
     */
    function unpause() public onlyRole(ADMIN_ROLE) whenPaused {
        paused = false; // CONNECTION TO PROJECT 01: Boolean storage write!
        emit Unpaused(msg.sender); // CONNECTION TO PROJECT 03: Event emission!
    }

    /**
     * @notice Increment counter (example function)
     * @dev DEMONSTRATES PAUSE PATTERN
     * 
     * MODIFIER USAGE: whenNotPaused
     * - Function disabled when paused
     * - Demonstrates pause functionality
     * 
     * This function would fail if contract is paused.
     */
    function incrementCounter() public whenNotPaused {
        counter += 1; // CONNECTION TO PROJECT 01: Storage update!
    }

    /**
     * @notice Mint function (example with role and pause)
     * @dev MULTIPLE MODIFIERS (Computer Science: Modifier Chaining)
     * 
     * MODIFIER CHAINING: onlyRole(MINTER_ROLE) whenNotPaused
     * - Both modifiers must pass
     * - Executes in order: onlyRole → whenNotPaused → function body
     * 
     * ACCESS CONTROL:
     * - Requires MINTER_ROLE
     * - Requires contract not paused
     * - Demonstrates multi-level access control
     */
    function mint(address to) public onlyRole(MINTER_ROLE) whenNotPaused {
        require(to != address(0), "Invalid address");
        // Business logic placeholder – in a token contract this would mint to `to`.
    }

    /**
     * @notice Check if account has role
     * @dev VIEW FUNCTION (Computer Science: Query Function)
     * 
     * CONNECTION TO PROJECT 01: Nested mapping storage read!
     * Returns true if account has the specified role
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return roles[account][role]; // CONNECTION TO PROJECT 01: Nested mapping read!
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS - PROJECT 04
 * ═══════════════════════════════════════════════════════════════════════════
 * 
 * 1. MODIFIERS ENABLE CODE REUSE
 *    ✅ Wrap functions with reusable logic
 *    ✅ Execute before (and optionally after) function body
 *    ✅ Similar to decorators, annotations, middleware
 * 
 * 2. ACCESS CONTROL PATTERNS
 *    ✅ Owner pattern: Single admin (from Projects 01-02)
 *    ✅ RBAC: Multiple roles with different permissions
 *    ✅ Modifiers make access control cleaner
 * 
 * 3. PAUSE FUNCTIONALITY
 *    ✅ Emergency stop mechanism
 *    ✅ Critical for security and upgrades
 *    ✅ State machine pattern (paused/unpaused)
 * 
 * 4. MODIFIER CHAINING
 *    ✅ Multiple modifiers can be applied
 *    ✅ Execute in order (left to right)
 *    ✅ All must pass for function to execute
 * 
 * 5. CONSTANTS SAVE GAS
 *    ✅ Stored in bytecode, not storage
 *    ✅ No storage slot consumption
 *    ✅ Deterministic hashes enable cross-chain compatibility
 * 
 * 6. PARAMETERIZED MODIFIERS
 *    ✅ Modifiers can take parameters
 *    ✅ Enables flexible, reusable logic
 *    ✅ Example: onlyRole(bytes32 role)
 * 
 * ═══════════════════════════════════════════════════════════════════════════
 *                    CONNECTIONS TO FUTURE PROJECTS
 * ═══════════════════════════════════════════════════════════════════════════
 * 
 * • All Future Projects
 *   - Modifiers used throughout for access control
 *   - Pause pattern used in production contracts
 *   - RBAC used in governance and DeFi
 * 
 * • Project 08: ERC20 Token
 *   - Uses modifiers for minting/burning
 *   - Uses pause for emergency stops
 *   - Access control for admin functions
 * 
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMPUTER SCIENCE CONCEPTS
 * ═══════════════════════════════════════════════════════════════════════════
 * 
 * • Aspect-Oriented Programming: Modifiers wrap functions with cross-cutting concerns
 * • Access Control: Authorization patterns (owner, RBAC)
 * • State Machines: Pause pattern (paused/unpaused states)
 * • Code Reuse: DRY principle with modifiers
 * • Deterministic Hashes: keccak256 for cross-chain compatibility
 * 
 * Modifiers are essential for clean, maintainable smart contracts!
 */
