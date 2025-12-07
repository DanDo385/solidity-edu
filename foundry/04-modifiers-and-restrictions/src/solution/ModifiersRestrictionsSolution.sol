// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ModifiersRestrictionsSolution
 * @notice Reference implementation for Project 04 that focuses on custom modifiers, role gating, and pause logic.
 * @dev Syntax-oriented: read this contract to see the minimal patterns, then jump to the README for deeper theory.
 */
contract ModifiersRestrictionsSolution {
    // Role identifiers are deterministic keccak256 hashes so callers can copy/paste them across chains.
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address public owner;
    bool public paused;
    uint256 public counter;

    // roles[account][role] => true when the account holds that badge.
    mapping(address => mapping(bytes32 => bool)) private roles;

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
        require(!paused, "Paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Not paused");
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
        require(account != address(0), "Invalid account");
        require(!roles[account][role], "Role already granted");
        roles[account][role] = true;
        emit RoleGranted(role, account);
    }

    function revokeRole(bytes32 role, address account) public onlyOwner {
        require(roles[account][role], "Role missing");
        roles[account][role] = false;
        emit RoleRevoked(role, account);
    }

    function pause() public onlyRole(ADMIN_ROLE) {
        require(!paused, "Already paused");
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public onlyRole(ADMIN_ROLE) whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    function incrementCounter() public whenNotPaused {
        counter += 1;
    }

    function mint(address to) public onlyRole(MINTER_ROLE) whenNotPaused {
        require(to != address(0), "Invalid address");
        // Business logic placeholder – in a token contract this would mint to `to`.
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return roles[account][role];
    }
}
