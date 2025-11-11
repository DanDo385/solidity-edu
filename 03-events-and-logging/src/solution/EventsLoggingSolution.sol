// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EventsLoggingSolution  
 * @notice Complete implementation demonstrating Solidity events and logging
 * 
 * KEY CONCEPTS:
 * - Events are cheaper than storage (~2k gas vs ~20k gas)
 * - Up to 3 indexed parameters for filtering  
 * - Events cannot be read by contracts (write-only logs)
 * - Essential for off-chain indexing and frontend updates
 */
contract EventsLoggingSolution {
    address public owner;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;
    mapping(address => string) public userStatus;

    // Events with indexed parameters for filtering
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Deposit(address indexed user, uint256 amount, uint256 timestamp);
    event StatusChanged(address indexed user, string oldStatus, string newStatus);

    constructor() {
        owner = msg.sender;
        balances[msg.sender] = 1000000 * 10**18; // Initial supply
    }

    function transfer(address _to, uint256 _amount) public {
        require(_to != address(0), "Invalid recipient");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        
        emit Transfer(msg.sender, _to, _amount);
    }

    function approve(address _spender, uint256 _amount) public {
        require(_spender != address(0), "Invalid spender");
        
        allowances[msg.sender][_spender] = _amount;
        
        emit Approval(msg.sender, _spender, _amount);
    }

    function deposit() public payable {
        require(msg.value > 0, "Must send ETH");
        
        balances[msg.sender] += msg.value;
        
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }

    function updateStatus(string memory _newStatus) public {
        string memory oldStatus = userStatus[msg.sender];
        userStatus[msg.sender] = _newStatus;
        
        emit StatusChanged(msg.sender, oldStatus, _newStatus);
    }

    function balanceOf(address _account) public view returns (uint256) {
        return balances[_account];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }
}
