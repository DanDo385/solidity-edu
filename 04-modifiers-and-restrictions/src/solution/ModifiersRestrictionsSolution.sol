// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ModifiersRestrictionsSolution
 * @notice Complete implementation of modifiers and access control
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
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    modifier onlyRole(bytes32 role) {
        require(roles[msg.sender][role], "Missing role");
        _;
    }
    
    modifier whenNotPaused() {
        require(!paused, "Contract paused");
        _;
    }
    
    modifier whenPaused() {
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
