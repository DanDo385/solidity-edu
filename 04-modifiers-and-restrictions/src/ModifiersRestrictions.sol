// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ModifiersRestrictions {
    address public owner;
    bool public paused;
    
    mapping(address => mapping(bytes32 => bool)) public roles;
    
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    // TODO: Implement modifier 'onlyOwner' that checks msg.sender == owner
    
    // TODO: Implement modifier 'onlyRole(bytes32 role)' that checks roles[msg.sender][role]
    
    // TODO: Implement modifier 'whenNotPaused' that checks !paused
    
    constructor() {
        owner = msg.sender;
        roles[msg.sender][ADMIN_ROLE] = true;
    }
    
    // TODO: Implement function to transfer ownership (onlyOwner)
    
    // TODO: Implement function to grant role (onlyOwner)
    
    // TODO: Implement function to pause (onlyRole(ADMIN_ROLE))
    
    // TODO: Implement function that uses multiple modifiers
}
