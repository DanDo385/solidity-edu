// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ERC20Token {
    // ============================================================
    // STATE VARIABLES
    // ============================================================

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // ============================================================
    // EVENTS
    // ============================================================

    // TODO: Implement ERC20 events

    // ============================================================
    // CONSTRUCTOR
    // ============================================================

    // TODO: Implement constructor

    // ============================================================
    // EXTERNAL FUNCTIONS
    // ============================================================

    // TODO: Implement transfer
    // TODO: Implement approve  
    // TODO: Implement transferFrom
}
