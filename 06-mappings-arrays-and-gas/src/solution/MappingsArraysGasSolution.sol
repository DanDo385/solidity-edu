// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MappingsArraysGasSolution {
    mapping(address => uint256) public balances;
    mapping(address => bool) public isUser;
    address[] public users;
    uint256 public totalBalance;
    
    event UserAdded(address indexed user);
    event BalanceUpdated(address indexed user, uint256 newBalance);
    
    function addUser(address user) public {
        require(!isUser[user], "User exists");
        users.push(user);
        isUser[user] = true;
        emit UserAdded(user);
    }
    
    function setBalance(address user, uint256 amount) public {
        if (!isUser[user]) {
            addUser(user);
        }
        
        uint256 oldBalance = balances[user];
        balances[user] = amount;
        totalBalance = totalBalance - oldBalance + amount;
        
        emit BalanceUpdated(user, amount);
    }
    
    function sumAllBalances() public view returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < users.length; i++) {
            sum += balances[users[i]];
        }
        return sum;
    }
    
    function getTotalBalance() public view returns (uint256) {
        return totalBalance;
    }
    
    function getUserCount() public view returns (uint256) {
        return users.length;
    }
}
