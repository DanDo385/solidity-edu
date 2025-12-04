// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MappingsArraysGas {
    mapping(address => uint256) public balances;
    address[] public users;
    
    // TODO: Implement addUser (check for duplicates)
    // TODO: Implement sumAllBalances (demonstrate DoS risk)
    // TODO: Implement gas-efficient alternative
}
