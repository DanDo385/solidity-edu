// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ReentrancySecurity {
    mapping(address => uint256) public balances;
    
    // TODO: Implement VULNERABLE withdraw function (for learning!)
    // TODO: Implement SAFE withdraw function using CEI pattern
    // TODO: Implement deposit function
}

contract AttackerContract {
    // TODO: Implement attack contract that exploits reentrancy
}
