// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ModifiersRestrictions {
    // ============================================================
    // STATE VARIABLES
    // ============================================================

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    address public owner;
    bool public paused;
    
    mapping(address => mapping(bytes32 => bool)) public roles;

    // ============================================================
    // MODIFIERS
    // ============================================================

    // Modifiers here are the contract's front door policies. The Solidity
    // optimizer often inlines simple modifiers, so a tight require is cheaper
    // than duplicating the same check everywhere.
    // TODO: Implement modifier 'onlyOwner' that checks msg.sender == owner
    
    // TODO: Implement modifier 'onlyRole(bytes32 role)' that checks roles[msg.sender][role]
    
    // TODO: Implement modifier 'whenNotPaused' that checks !paused

    // ============================================================
    // CONSTRUCTOR
    // ============================================================

    constructor() {
        owner = msg.sender;
        roles[msg.sender][ADMIN_ROLE] = true;
        // Fun fact: keccak256 role IDs are deterministic, which keeps role
        // management cheap on L2s and easy to replay on forks like Ethereum
        // Classic if governance ever needs to migrate.
    }
    
    // TODO: Implement function to transfer ownership (onlyOwner)
    
    // TODO: Implement function to grant role (onlyOwner)
    
    // TODO: Implement function to pause (onlyRole(ADMIN_ROLE))
    
    // TODO: Implement function that uses multiple modifiers
    // Chaining modifiers is like requiring both a boarding pass and ID; order
    // matters for gas and safety. Keep checks first, effects later, and avoid
    // external calls inside modifiers unless absolutely necessary.
}
