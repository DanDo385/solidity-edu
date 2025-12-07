// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EventsLoggingSolution
 * @notice Token-like reference contract that demonstrates how events connect on-chain state to off-chain listeners.
 * @dev Shows indexed topics, ERC20-style flows, and CEI ordering. See README.md for the deep dive.
 */
contract EventsLoggingSolution {
    // STATE
    address public owner;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;
    mapping(address => string) public userStatus; // Strings keep the demo about costly dynamic data; bytes32 is cheaper for fixed statuses.

    // EVENTS
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Deposit(address indexed user, uint256 amount, uint256 timestamp);
    event StatusChanged(address indexed user, string oldStatus, string newStatus);

    constructor() {
        // One-time setup: deployer owns an initial supply for demos/tests.
        owner = msg.sender;
        balances[msg.sender] = 1_000_000 * 10**18;
    }

    /**
     * @notice Move tokens and publish an ERC20-style receipt.
     * @dev Follows checks-effects-interactions; mapping writes reuse Project 01 storage layout and the event is indexed for filtering.
     */
    function transfer(address _to, uint256 _amount) public {
        require(_to != address(0), "Invalid recipient");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        balances[_to] += _amount;

        emit Transfer(msg.sender, _to, _amount);
    }

    /**
     * @notice Delegate spending power to `_spender`.
     * @dev Direct assignment is the ERC20 pattern and cheapest write; nested mapping mirrors the slot math from Project 01.
     */
    function approve(address _spender, uint256 _amount) public {
        require(_spender != address(0), "Invalid spender");

        allowances[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
    }

    /**
     * @notice Receive ETH and credit the sender.
     * @dev `payable` unlocks value transfer (Project 02); we log timestamps in the event instead of burning storage slots.
     */
    function deposit() public payable {
        require(msg.value > 0, "Must send ETH");

        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }

    /**
     * @notice Update your status string and log the change.
     * @dev Strings are pricey; cache the old value to avoid double SLOADs and emit history instead of storing every version.
     */
    function updateStatus(string memory _newStatus) public {
        string memory oldStatus = userStatus[msg.sender];
        userStatus[msg.sender] = _newStatus;
        emit StatusChanged(msg.sender, oldStatus, _newStatus);
    }

    // View helpers (free off-chain; cheap on-chain)
    function balanceOf(address _account) public view returns (uint256) {
        return balances[_account];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }
}
