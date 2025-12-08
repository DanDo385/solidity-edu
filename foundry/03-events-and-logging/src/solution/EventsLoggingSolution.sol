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
     * @notice Transfer tokens to another address
     * @dev TRANSFER FUNCTION (Computer Science: State Transition with Logging)
     * 
     * This function demonstrates the ERC20 transfer pattern:
     * 1. Validate inputs (checks)
     * 2. Update balances (effects)
     * 3. Emit event (interactions - off-chain)
     * 
     * CONNECTION TO PROJECT 02: CEI Pattern!
     * - Checks: Validate recipient and balance
     * - Effects: Update balances in storage
     * - Interactions: Emit event (off-chain interaction)
     * 
     * CONNECTION TO PROJECT 01: Mapping Storage!
     * - Updates two mapping storage slots
     * - O(1) lookup and update operations
     * 
     * CONNECTION TO PROJECT 08: ERC20 Standard!
     * - This is the core ERC20 transfer function
     * - Required by ERC20 standard
     * - Must emit Transfer event
     * 
     * GAS COST: ~11,700 gas (warm) + event emission
     * 
     * SYNTAX: emit Transfer(from, to, amount);
     * - emit: Keyword for emitting events
     * - Event name must match declaration
     * - Parameters passed to event
     */
    function transfer(address _to, uint256 _amount) public {
        // ════════════════════════════════════════════════════════════════════
        // CHECKS: Validate inputs
        // ════════════════════════════════════════════════════════════════════
        require(_to != address(0), "Invalid recipient");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        // ════════════════════════════════════════════════════════════════════
        // EFFECTS: Update state
        // ════════════════════════════════════════════════════════════════════
        // CONNECTION TO PROJECT 01: Mapping storage updates!
        balances[msg.sender] -= _amount; // SSTORE: ~5,000 gas (warm)
        balances[_to] += _amount; // SSTORE: ~5,000 gas (warm)

        // ════════════════════════════════════════════════════════════════════
        // INTERACTIONS: Emit event (off-chain)
        // ════════════════════════════════════════════════════════════════════
        // Events are permanent, searchable, and cheap!
        emit Transfer(msg.sender, _to, _amount); // ~1,500 gas
    }

    /**
     * @notice Approve spender to transfer tokens on your behalf
     * @dev APPROVAL FUNCTION (Computer Science: Delegation Pattern)
     * 
     * This function enables delegated spending - allowing another address
     * to transfer tokens on your behalf up to the approved amount.
     * 
     * CONNECTION TO PROJECT 01: Nested Mapping Storage!
     * - Storage: keccak256(keccak256(owner, slot), spender)
     * - Two-level hash table lookup
     * 
     * CONNECTION TO PROJECT 08: ERC20 Standard!
     * - Required by ERC20 standard
     * - Must emit Approval event
     * - Used by transferFrom() function
     * 
     * DELEGATION PATTERN:
     * - Owner grants permission to spender
     * - Spender can transfer up to approved amount
     * - Common in DeFi (DEXs, lending, yield farming)
     * 
     * GAS COST: ~6,500 gas (warm) + event emission
     * 
     * SYNTAX: allowances[owner][spender] = amount;
     * - Nested mapping access
     * - Direct assignment (overwrites previous approval)
     */
    function approve(address _spender, uint256 _amount) public {
        require(_spender != address(0), "Invalid spender");

        // CONNECTION TO PROJECT 01: Nested mapping storage write!
        allowances[msg.sender][_spender] = _amount; // SSTORE: ~5,000 gas (warm)

        // Emit event: Required by ERC20 standard
        emit Approval(msg.sender, _spender, _amount); // ~1,500 gas
    }

    /**
     * @notice Deposit ETH and credit balance
     * @dev PAYABLE FUNCTION (Computer Science: Message Passing with Value)
     * 
     * CONNECTION TO PROJECT 02: Payable functions!
     * - Can receive ETH with function call
     * - msg.value contains amount sent
     * 
     * EVENT LOGGING PATTERN:
     * - Includes timestamp in event (not storage!)
     * - Much cheaper than storing timestamp in storage
     * - Events are perfect for historical data
     * 
     * block.timestamp:
     * - Current block timestamp (Unix epoch)
     * - Set by miner/validator
     * - Available in all functions
     * 
     * SYNTAX: emit Deposit(user, amount, block.timestamp);
     * - Can include block properties in events
     * - Timestamp stored in event log (not storage)
     */
    function deposit() public payable {
        require(msg.value > 0, "Must send ETH");

        // CONNECTION TO PROJECT 01: Mapping storage update!
        balances[msg.sender] += msg.value; // SSTORE: ~5,000 gas (warm)

        // Emit event with timestamp - cheaper than storing in storage!
        emit Deposit(msg.sender, msg.value, block.timestamp); // ~1,500 gas
    }

    /**
     * @notice Update user status and log the change
     * @dev STORAGE CACHING PATTERN (Computer Science: Memory Optimization)
     * 
     * This function demonstrates:
     * 1. Storage caching to avoid double reads
     * 2. Event logging for historical data
     * 
     * CONNECTION TO PROJECT 01: Storage Caching!
     * - Read from storage once, cache in memory
     * - Use cached value multiple times
     * - Saves gas on expensive string reads
     * 
     * EVENT VS STORAGE:
     * - Storage: Current state only (expensive)
     * - Events: Historical changes (cheap)
     * - Use events to track history, storage for current state
     * 
     * STRING STORAGE COST:
     * - Very expensive (~20,000+ gas per write)
     * - Consider bytes32 for fixed-size statuses
     * - Events are perfect for logging changes
     * 
     * SYNTAX: string memory oldStatus = userStatus[msg.sender];
     * - Copy from storage to memory
     * - Avoids reading from storage twice
     */
    function updateStatus(string memory _newStatus) public {
        // CACHE: Read from storage once (expensive for strings!)
        string memory oldStatus = userStatus[msg.sender]; // Expensive: copies string

        // UPDATE: Write new status to storage
        userStatus[msg.sender] = _newStatus; // SSTORE: ~20,000+ gas (depends on length)

        // EMIT: Log the change (cheap historical record)
        emit StatusChanged(msg.sender, oldStatus, _newStatus); // ~1,500 gas
    }

    // ════════════════════════════════════════════════════════════════════════
    // VIEW FUNCTIONS - Query Operations
    // ════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Get balance for an address
     * @dev CONNECTION TO PROJECT 01: Mapping storage read!
     * View functions are free when called off-chain
     */
    function balanceOf(address _account) public view returns (uint256) {
        return balances[_account]; // SLOAD: ~100 gas (on-chain), FREE (off-chain)
    }

    /**
     * @notice Get allowance for owner-spender pair
     * @dev CONNECTION TO PROJECT 01: Nested mapping storage read!
     * Returns approved amount for delegated spending
     */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender]; // 2 SLOADs: ~200 gas (on-chain), FREE (off-chain)
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS - PROJECT 03
 * ═══════════════════════════════════════════════════════════════════════════
 * 
 * 1. EVENTS ARE CHEAPER THAN STORAGE FOR HISTORY
 *    ✅ Events: ~1,500 gas (permanent, searchable)
 *    ✅ Storage: ~20,000+ gas (persistent, queryable)
 *    ✅ Use events for historical data, storage for current state
 * 
 * 2. INDEXED PARAMETERS ENABLE EFFICIENT FILTERING
 *    ✅ Up to 3 indexed parameters per event
 *    ✅ Stored in transaction receipt's logsBloom
 *    ✅ Enable efficient filtering via RPC (eth_getLogs)
 * 
 * 3. EVENTS ARE PERMANENT AND SEARCHABLE
 *    ✅ Stored in transaction receipts (separate from state)
 *    ✅ Can be queried via RPC (eth_getLogs)
 *    ✅ Essential for off-chain indexing and frontends
 * 
 * 4. ERC20 PATTERNS USE EVENTS
 *    ✅ Transfer event: Required for all token movements
 *    ✅ Approval event: Required for all approvals
 *    ✅ Events enable off-chain tracking of token state
 * 
 * 5. BLOCK PROPERTIES IN EVENTS
 *    ✅ block.timestamp: Current block timestamp
 *    ✅ Can include in events (cheaper than storage)
 *    ✅ Perfect for logging when events occurred
 * 
 * 6. STORAGE CACHING SAVES GAS
 *    ✅ Read from storage once, cache in memory
 *    ✅ Use cached value multiple times
 *    ✅ Especially important for expensive types (strings)
 * 
 * ═══════════════════════════════════════════════════════════════════════════
 *                    CONNECTIONS TO FUTURE PROJECTS
 * ═══════════════════════════════════════════════════════════════════════════
 * 
 * • Project 08: ERC20 Token
 *   - Uses Transfer and Approval events (required by standard)
 *   - Events enable off-chain tracking of token state
 *   - Foundation for DeFi protocols
 * 
 * • Project 09: ERC721 NFT
 *   - Uses Transfer event for NFT movements
 *   - Events track NFT ownership history
 *   - Essential for NFT marketplaces
 * 
 * • All DeFi Projects
 *   - Events are used throughout for logging
 *   - Off-chain systems rely on events
 *   - Critical for composability
 * 
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMPUTER SCIENCE CONCEPTS
 * ═══════════════════════════════════════════════════════════════════════════
 * 
 * • Event-Driven Architecture: Events decouple on-chain logic from off-chain
 * • Logging vs Storage: Trade-offs between cost and queryability
 * • Bloom Filters: Indexed parameters use bloom filters for efficient filtering
 * • Transaction Receipts: Events stored separately from state
 * • Delegation Pattern: Approvals enable delegated spending
 * 
 * Events are the bridge between on-chain and off-chain systems!
 */
