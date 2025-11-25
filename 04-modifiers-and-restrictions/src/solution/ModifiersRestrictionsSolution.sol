// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ModifiersRestrictionsSolution
 * @notice Complete implementation of modifiers and access control
 * @dev Demonstrates gas-efficient access control patterns
 * 
 * REAL-WORLD ANALOGY: Modifiers are like security checkpoints. Before you
 * can enter a restricted area (function), you must pass through the checkpoint
 * (modifier) that verifies your credentials (role, ownership, etc.).
 * 
 * GAS OPTIMIZATION: Why use modifiers instead of inline checks?
 * - Modifiers: Code reuse, cleaner syntax, ~5 gas overhead per modifier
 * - Inline checks: More verbose, but same gas cost
 * - Trade-off: Modifiers are cleaner but add slight overhead
 * 
 * LANGUAGE COMPARISON:
 *   TypeScript: Decorators (@decorator) - similar concept
 *   Go: No direct equivalent, use helper functions
 *   Rust: Attribute macros (#[attribute]) - similar concept
 *   Solidity: Modifiers are built-in language feature
 */
contract ModifiersRestrictionsSolution {
    address public owner;
    bool public paused;
    uint256 public counter;
    
    mapping(address => mapping(bytes32 => bool)) public roles;
    
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event RoleGranted(bytes32 indexed role, address indexed account);
    event RoleRevoked(bytes32 indexed role, address indexed account);
    event Paused(address account);
    event Unpaused(address account);
    
    /**
     * @notice Modifier to restrict function to owner only
     * 
     * GAS COST: ~100 gas (1 SLOAD for owner) + ~5 gas modifier overhead
     * 
     * GAS OPTIMIZATION: Why cache owner in modifier?
     * - Reading owner: 1 SLOAD = ~100 gas (warm)
     * - Caching saves: 0 gas (only used once)
     * - Current approach is optimal for single use
     */
    modifier onlyOwner() {
        // GAS: 1 SLOAD = ~100 gas (warm)
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    /**
     * @notice Modifier to check role-based access
     * @param role The role to check
     * 
     * GAS COST: ~100 gas (1 SLOAD for roles mapping) + ~5 gas modifier overhead
     * 
     * GAS OPTIMIZATION: Why use nested mapping for roles?
     * - roles[account][role]: 1 SLOAD = ~100 gas (warm)
     * - Alternative: Separate mapping per role
     *   mapping(address => bool) public admins;
     *   Costs: Same gas, but requires separate mapping per role
     * - Trade-off: Nested mapping is more flexible, same gas cost
     */
    modifier onlyRole(bytes32 role) {
        // GAS: 1 SLOAD = ~100 gas (warm)
        require(roles[msg.sender][role], "Missing role");
        _;
    }
    
    /**
     * @notice Modifier to ensure contract is not paused
     * 
     * GAS COST: ~100 gas (1 SLOAD for paused) + ~5 gas modifier overhead
     * 
     * REAL-WORLD ANALOGY: Like checking if a store is open before entering.
     * The pause mechanism is an emergency stop - if paused, no operations allowed.
     */
    modifier whenNotPaused() {
        // GAS: 1 SLOAD = ~100 gas (warm)
        require(!paused, "Contract paused");
        _;
    }
    
    /**
     * @notice Modifier to ensure contract is paused
     * 
     * GAS COST: ~100 gas (1 SLOAD for paused) + ~5 gas modifier overhead
     */
    modifier whenPaused() {
        // GAS: 1 SLOAD = ~100 gas (warm)
        require(paused, "Contract not paused");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        roles[msg.sender][ADMIN_ROLE] = true;
        roles[msg.sender][MINTER_ROLE] = true;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    
    function grantRole(bytes32 role, address account) public onlyOwner {
        require(!roles[account][role], "Role already granted");
        roles[account][role] = true;
        emit RoleGranted(role, account);
    }
    
    function revokeRole(bytes32 role, address account) public onlyOwner {
        require(roles[account][role], "Role not granted");
        roles[account][role] = false;
        emit RoleRevoked(role, account);
    }
    
    function pause() public onlyRole(ADMIN_ROLE) {
        require(!paused, "Already paused");
        paused = true;
        emit Paused(msg.sender);
    }
    
    function unpause() public onlyRole(ADMIN_ROLE) {
        require(paused, "Not paused");
        paused = false;
        emit Unpaused(msg.sender);
    }
    
    function incrementCounter() public whenNotPaused {
        counter++;
    }
    
    function mint(address to) public onlyRole(MINTER_ROLE) whenNotPaused {
        // Minting logic
    }
    
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return roles[account][role];
    }
}
