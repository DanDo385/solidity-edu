// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EventsLoggingSolution  
 * @notice Complete implementation demonstrating Solidity events and logging
 * @dev This solution shows why events are crucial and how to use them efficiently
 * 
 * REAL-WORLD ANALOGY: Events are like receipts or audit logs. You can't read them
 * from the contract (like you can't read receipts from a cash register), but they're
 * permanently recorded and can be read by anyone off-chain. They're cheaper than
 * storage (like printing a receipt vs storing data in a database).
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

    /**
     * @dev Events with indexed parameters for filtering
     * 
     * GAS OPTIMIZATION: Why use indexed parameters?
     * - Indexed params: ~375 gas per indexed param (up to 3)
     * - Non-indexed params: ~8 gas per byte
     * - Indexed params enable filtering: can search by address
     * - Trade-off: More expensive, but enables efficient off-chain queries
     * 
     * GAS COST BREAKDOWN:
     * - LOG1 (no indexed): ~375 gas base + 8 gas/byte
     * - LOG2 (1 indexed): ~750 gas base + 8 gas/byte
     * - LOG3 (2 indexed): ~1,125 gas base + 8 gas/byte
     * - LOG4 (3 indexed): ~1,500 gas base + 8 gas/byte
     * 
     * ALTERNATIVE: Store data in mapping instead of events
     *   mapping(address => uint256) public transferHistory;
     *   Costs: ~20,000 gas per write (cold) vs ~1,500 gas for event
     *   Savings: ~18,500 gas per event!
     *   But: Can't filter efficiently, takes storage slots
     * 
     * REAL-WORLD ANALOGY: Like choosing between a receipt (event) and a database
     * entry (storage). Receipts are cheaper and permanent, but you can't query
     * them from the contract. Database entries are expensive but queryable.
     */
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Deposit(address indexed user, uint256 amount, uint256 timestamp);
    event StatusChanged(address indexed user, string oldStatus, string newStatus);

    constructor() {
        owner = msg.sender;
        // GAS OPTIMIZATION: Using multiplication instead of repeated addition
        // 1000000 * 10**18: 1 multiplication operation
        // Alternative: Loop with += would cost n * SSTORE operations
        balances[msg.sender] = 1000000 * 10**18; // Initial supply
    }

    /**
     * @notice Transfer tokens between addresses
     * @param _to Recipient address
     * @param _amount Amount to transfer
     * 
     * GAS OPTIMIZATION: Why emit event after state changes?
     * - Events are emitted even if transaction reverts (in the same transaction)
     * - But if we emit before state changes and revert, event still costs gas
     * - Emitting after ensures state is valid before logging
     * 
     * GAS COST:
     * - 2 SLOADs (balances): ~200 gas (warm)
     * - 2 SSTOREs (balances): ~10,000 gas (warm)
     * - Event: ~1,500 gas
     * - Total: ~11,700 gas
     * 
     * REAL-WORLD ANALOGY: Like updating a ledger entry and then printing a receipt.
     * You update the balances first (state), then print the receipt (event) to
     * prove the transaction happened.
     */
    function transfer(address _to, uint256 _amount) public {
        require(_to != address(0), "Invalid recipient");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        // Update state first (Checks-Effects-Interactions pattern)
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        
        // Emit event after state changes
        emit Transfer(msg.sender, _to, _amount);
    }

    /**
     * @notice Approve spender to transfer tokens
     * @param _spender Address to approve
     * @param _amount Amount to approve
     * 
     * GAS OPTIMIZATION: Direct assignment vs read-modify-write
     * - allowances[msg.sender][_spender] = _amount: 1 SSTORE = ~5,000 gas (warm)
     * - Alternative: Read old value first, then write
     *   Costs: 1 SLOAD + 1 SSTORE = ~7,100 gas
     * - Direct assignment saves: ~2,100 gas
     * 
     * NOTE: This overwrites previous approval. For incremental approvals,
     * you'd need: allowances[msg.sender][_spender] += _amount;
     */
    function approve(address _spender, uint256 _amount) public {
        require(_spender != address(0), "Invalid spender");
        
        // Direct assignment - no need to read old value if overwriting
        allowances[msg.sender][_spender] = _amount;
        
        emit Approval(msg.sender, _spender, _amount);
    }

    /**
     * @notice Deposit ETH and credit balance
     * 
     * GAS OPTIMIZATION: Why include block.timestamp in event?
     * - block.timestamp: ~2 gas (read from global variable)
     * - Storing timestamp in mapping: ~20,000 gas (cold SSTORE)
     * - Event with timestamp: ~8 gas per byte = ~32 gas for uint256
     * - Savings: ~19,968 gas by using event instead of storage!
     * 
     * REAL-WORLD ANALOGY: Like including the date on a receipt instead of
     * storing it in a separate database. The receipt (event) already has the
     * timestamp, so you don't need to store it separately.
     */
    function deposit() public payable {
        require(msg.value > 0, "Must send ETH");
        
        balances[msg.sender] += msg.value;
        
        // Include timestamp in event instead of storing separately
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }

    /**
     * @notice Update user status string
     * @param _newStatus New status string
     * 
     * GAS WARNING: String storage is expensive!
     * - Storing string: ~20,000 gas (cold) + ~5 gas per byte
     * - Reading string: ~2,100 gas (cold) + ~3 gas per byte
     * - For 100-byte string: ~20,500 gas to store, ~2,400 gas to read
     * 
     * GAS OPTIMIZATION: Why cache oldStatus?
     * - Reading userStatus[msg.sender]: 1 SLOAD = ~2,100 gas (cold)
     * - We use it in event, so cache to avoid re-reading
     * - Savings: ~2,100 gas if we were to read twice
     * 
     * ALTERNATIVE: Use bytes32 instead of string for fixed-size statuses
     *   mapping(address => bytes32) public userStatus;
     *   Costs: ~5,000 gas (warm) vs ~20,500 gas for string
     *   Savings: ~15,500 gas per update!
     *   But: Limited to 32 bytes, less flexible
     * 
     * REAL-WORLD ANALOGY: Like updating a user profile status. Storing the
     * full string is expensive (like storing a long bio), but events let you
     * track changes without storing the full history.
     */
    function updateStatus(string memory _newStatus) public {
        // Cache old status to avoid re-reading storage
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
