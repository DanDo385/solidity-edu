// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DatatypesStorageSolution
 * @notice Complete reference implementation demonstrating Solidity datatypes and storage
 * @dev Reference implementation showing value types, reference types, data locations,
 *      struct packing, and common patterns. See README.md for detailed explanations.
 */
contract DatatypesStorageSolution {
    // ════════════════════════════════════════════════════════════════════════
    // TYPE DECLARATIONS
    // ════════════════════════════════════════════════════════════════════════
    //
    // Struct declarations are TYPE DEFINITIONS, not state variables.
    // They don't consume storage slots until used as state variables or in mappings/arrays.

    /**
     * @notice User struct demonstrating reference types
     * @dev Not packed - each field uses full slot (3 slots total).
     *      Used to track user information in mappings.
     *      Real-world: Similar to user profiles in DeFi protocols or NFT collections.
     */
    struct User {
        address wallet;
        uint256 balance;
        bool isRegistered;
    }

    /**
     * @notice Gas-optimized struct demonstrating packing
     * @dev Packed into 2 slots (saves 50% gas vs unpacked version).
     *      Small types pack together when total ≤ 32 bytes.
     *      Real-world: Used in production contracts to reduce gas costs (NFT metadata, DeFi positions).
     */
    struct PackedData {
        uint128 smallNumber1;
        uint128 smallNumber2;
        address user;
        uint64 timestamp;
        bool flag;
    }

    // ════════════════════════════════════════════════════════════════════════
    // STATE VARIABLES (Storage)
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Simple unsigned integer (256 bits)
     * @dev Stored in slot 0. uint256 is EVM-optimized - smaller types cost MORE gas for arithmetic.
     *      Real-world: Used for counters, amounts, timestamps throughout all smart contracts.
     */
    uint256 public number;

    /**
     * @notice Contract owner address
     * @dev Stored in slot 1. Address type has built-in methods (.transfer(), .call()).
     *      Real-world: Ownership pattern used in all access-controlled contracts (see Project 04).
     */
    address public owner;

    /**
     * @notice Active status flag
     * @dev Stored in slot 2. Uses full 32-byte slot despite being 1 bit.
     *      Real-world: Pause/unpause patterns in production contracts for emergency stops.
     */
    bool public isActive;

    /**
     * @notice Fixed-size 32-byte data
     * @dev Stored in slot 3. Gas-efficient for hashes (keccak256 outputs).
     *      Real-world: Merkle roots, hash commitments, fixed identifiers (see Project 29: Merkle).
     */
    bytes32 public data;

    /**
     * @notice Dynamic string message
     * @dev Stored starting at slot 4. More expensive than bytes32 due to dynamic length.
     *      Real-world: User-facing text (names, descriptions), but prefer bytes32 when possible.
     */
    string public message;

    /**
     * @notice Mapping from address to balance
     * @dev O(1) lookup. Storage slot = keccak256(abi.encodePacked(key, slot_5)).
     *      Real-world: ERC20 token balances (see Project 08), access control, voting weights.
     */
    mapping(address => uint256) public balances;

    /**
     * @notice Dynamic array of numbers
     * @dev Length in slot 6, elements at keccak256(6) + index. Iterable but can be DoS risk.
     *      Real-world: Lists when order matters, but prefer mappings + events for scalability.
     */
    uint256[] public numbers;

    /**
     * @notice Mapping from address to User struct
     * @dev Demonstrates nested reference types. Struct fields stored sequentially at calculated base slot.
     *      Real-world: User profiles, NFT metadata, DeFi positions (see Project 11: ERC4626).
     */
    mapping(address => User) public users;

    // ════════════════════════════════════════════════════════════════════════
    // EVENTS
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Emitted when number is updated
     * @dev Indexed params enable efficient filtering. Events are cheaper than storage (~2k vs ~20k gas).
     *      Real-world: Frontends and indexers rely on events for real-time UI updates (see Project 03).
     */
    event NumberUpdated(uint256 indexed oldValue, uint256 indexed newValue);

    /**
     * @notice Emitted when a user registers
     * @dev Wallet indexed for efficient filtering. Events complement storage for off-chain systems.
     *      Real-world: User registration tracking in DeFi protocols and NFT collections.
     */
    event UserRegistered(address indexed wallet, uint256 balance);

    /**
     * @notice Emitted when ETH is deposited
     * @dev Depositor indexed for filtering all deposits from a specific address.
     *      Real-world: Transaction history tracking in wallets and DeFi frontends.
     */
    event FundsDeposited(address indexed depositor, uint256 amount);

    /**
     * @notice Emitted when message is updated
     * @dev Strings can't be indexed. Events stored in logs, not contract storage.
     *      Real-world: Change logs and audit trails for contract state changes.
     */
    event MessageUpdated(string oldMessage, string newMessage);

    /**
     * @notice Emitted when balance is updated
     * @dev Non-indexed for simple logging. Use indexed params when filtering needed.
     *      Real-world: Balance change notifications in token contracts (see Project 08: ERC20).
     */
    event BalanceUpdated(address addr, uint256 balance);

    // ════════════════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Initializes the contract
     * @dev Constructor runs ONCE on deployment. Constructor code is not stored on-chain.
     *      Real-world: Critical security pattern - sets owner atomically during deployment (see Project 04: Modifiers).
     */
    constructor() {
        // Set owner to deployer - security pattern used in all access-controlled contracts
        owner = msg.sender;
        
        // Initialize contract as active - ready to use immediately
        isActive = true;
    }

    // ════════════════════════════════════════════════════════════════════════
    // ETHER HANDLING
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Deposit ETH into the contract
     * @dev Payable function receives ETH automatically. Uses += to accumulate deposits (read-modify-write pattern).
     *      Real-world: Deposit pattern in vaults, staking contracts, and payment systems (see Project 02: Functions & Payable).
     */
    function deposit() public payable {
        // Validate non-zero deposit. Uses += to accumulate multiple deposits (not = which would overwrite).
        require(msg.value > 0, "Deposit amount must be greater than 0");
        balances[msg.sender] += msg.value; // Read-modify-write: accumulates deposits over time
        emit FundsDeposited(msg.sender, msg.value);
    }

    // ════════════════════════════════════════════════════════════════════════
    // VALUE & REFERENCE TYPE FUNCTIONS
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Set the number value
     * @param _number The new number value
     * @dev Caches old value before update to avoid reading storage twice (gas optimization).
     *      Real-world: Pattern used throughout Solidity for state changes with event logging.
     */
    function setNumber(uint256 _number) public {
        // Cache old value - avoids second SLOAD when emitting event
        uint256 oldValue = number;
        number = _number;
        emit NumberUpdated(oldValue, _number);
    }

    /**
     * @notice Get the number value
     * @return The current number value
     * @dev View functions are free when called off-chain (frontends). On-chain calls cost gas.
     *      Real-world: Frontends constantly call view functions for real-time UI updates (all projects).
     */
    function getNumber() public view returns (uint256) {
        return number; // Note: public state variables auto-generate getters, but this demonstrates the pattern
    }

    /**
     * @notice Increment the number by 1
     * @dev Solidity 0.8.0+ automatically checks overflow (reverts on max value). += is read-modify-write in one op.
     *      Real-world: Counter patterns in NFT minting, voting systems, and iterators (see Project 09: ERC721).
     */
    function incrementNumber() public {
        number += 1; // Auto-overflow check in Solidity 0.8.0+
    }

    /**
     * @notice Set the message string
     * @param _message The new message
     * @dev Strings are dynamic and expensive (~2x cost vs bytes32). Cache old value for event emission.
     *      Real-world: Use for user-facing text, but prefer bytes32 for hashes and fixed identifiers.
     */
    function setMessage(string memory _message) public {
        // Cache old value - same pattern as setNumber()
        string memory oldMessage = message;
        message = _message; // Dynamic types are more expensive than fixed-size
        emit MessageUpdated(oldMessage, _message);
    }

    // ════════════════════════════════════════════════════════════════════════
    // MAPPING FUNCTIONS
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Set balance for an address
     * @param _address The address to set balance for
     * @param _balance The balance amount
     * @dev Direct assignment (no read needed when overwriting). Storage slot = keccak256(abi.encodePacked(key, slot_5)).
     *      Real-world: Balance setters in admin functions, token airdrops, and balance resets (see Project 08: ERC20).
     */
    function setBalance(address _address, uint256 _balance) public {
        balances[_address] = _balance; // Direct assignment - cheaper than read-modify-write when overwriting
        emit BalanceUpdated(_address, _balance);
    }

    /**
     * @notice Get balance for an address
     * @param _address The address to query
     * @return The balance amount
     * @dev Mappings always return a value (0 if key never set). Cannot distinguish "never set" from "set to 0".
     *      Real-world: Token balance queries. Use separate existence mapping if you need to distinguish states (see README).
     */
    function getBalance(address _address) public view returns (uint256) {
        return balances[_address]; // Returns 0 for unset keys - fundamental mapping behavior
    }

    // ════════════════════════════════════════════════════════════════════════
    // ARRAY FUNCTIONS
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Add a number to the numbers array
     * @param _number The number to add
     * @dev Push() does two storage writes (length + element). Watch for unbounded growth (DoS risk).
     *      Real-world: Use with size limits or prefer mappings for scalability (see Project 06: Mappings, Arrays & Gas).
     */
    function addNumber(uint256 _number) public {
        numbers.push(_number); // Two storage writes: length increment + element write
    }

    /**
     * @notice Get the length of the numbers array
     * @return The array length
     * @dev O(1) access - length stored explicitly in slot 6. Faster than counting elements.
     *      Real-world: Array length checks for bounds validation and iteration control throughout contracts.
     */
    function getNumbersLength() public view returns (uint256) {
        return numbers.length; // O(1) read from storage
    }

    /**
     * @notice Get a number at a specific index
     * @param _index The index to query
     * @return The number at that index
     * @dev Explicit bounds check saves gas vs automatic revert. Storage slot = keccak256(6) + index.
     *      Real-world: Array element access patterns in all contracts - bounds checking prevents errors.
     */
    function getNumberAt(uint256 _index) public view returns (uint256) {
        require(_index < numbers.length, "Index out of bounds");
        return numbers[_index];
    }

    /**
     * @notice Remove a number at a specific index from the array
     * @param _index The index of the element to remove
     * @dev Swap-and-pop pattern: O(1) instead of O(n) shifting. Order not preserved but 90% gas savings.
     *      Real-world: Used in production contracts for gas-efficient array management (see Project 06: Mappings, Arrays & Gas).
     */
    function removeNumber(uint256 _index) public {
        require(_index < numbers.length, "Index out of bounds");
        uint256 lastIndex = numbers.length - 1;
        numbers[_index] = numbers[lastIndex]; // Swap with last element
        numbers.pop(); // Remove last element (O(1) operation)
    }

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // STRUCT FUNCTIONS
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    /**
     * @notice Register a user
     * @param _wallet The user's wallet address
     * @param _balance The initial balance
     * @dev Direct struct assignment to storage (gas-efficient). Struct fields stored sequentially at calculated base slot.
     *      Real-world: User registration in DeFi protocols, NFT collections, and membership systems (see Project 09: ERC721).
     */
    function registerUser(address _wallet, uint256 _balance) public {
        // Direct assignment - more efficient than memory copy then storage write
        users[_wallet] = User({
            wallet: _wallet,
            balance: _balance,
            isRegistered: true
        });
        emit UserRegistered(_wallet, _balance);
    }

    /**
     * @notice Get user information
     * @param _wallet The user's wallet address
     * @return wallet address
     * @return balance amount
     * @return isRegistered status
     * @dev Copies struct to memory for return (required by Solidity). Returns multiple values as tuple.
     *      Real-world: User data retrieval in all contract types - enables clean frontend integration.
     */
    function getUser(address _wallet)
        public
        view
        returns (address wallet, uint256 balance, bool isRegistered)
    {
        // Memory copy required for returning struct values
        User memory user = users[_wallet];
        return (user.wallet, user.balance, user.isRegistered);
    }

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // DATA LOCATION DEMONSTRATION
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    /**
     * @notice Demonstrates memory usage - processes array without persisting
     * @param _arr Array to process (in memory)
     * @return The sum of array elements
     * @dev Pure function using memory for temporary calculations (~3 gas/word vs ~20k gas/write for storage).
     *      Real-world: Use memory for computations, storage only for persistent state (see README for details).
     */
    function sumMemoryArray(uint256[] memory _arr) public pure returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < _arr.length; i++) {
            sum += _arr[i]; // Memory reads are cheap compared to storage
        }
        return sum;
    }

    /**
     * @notice Demonstrates calldata usage - most gas-efficient for read-only
     * @param _arr Array to process (in calldata)
     * @return The first element
     * @dev Calldata is zero-copy (read from transaction directly). Only available in external functions.
     *      Real-world: Always use calldata for arrays/strings in external functions for gas savings (see Project 15: Low-Level Calls).
     */
    function getFirstElement(uint256[] calldata _arr) public pure returns (uint256) {
        require(_arr.length > 0, "Array is empty");
        return _arr[0]; // Zero-copy read from transaction calldata
    }

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // HELPER FUNCTIONS
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    /**
     * @notice Check if an address has a non-zero balance
     * @param _address The address to check
     * @return true if balance > 0
     * @dev Helper function for readability. Cannot distinguish "never set" from "set to 0" (see README for solutions).
     *      Real-world: Balance checks in access control, eligibility checks, and conditional logic throughout contracts.
     */
    function hasBalance(address _address) public view returns (bool) {
        return balances[_address] > 0; // Uses mapping zero-default behavior
    }

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // ADVANCED: Demonstrate storage slot packing
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    /**
     * @notice Gets packed data to demonstrate struct packing
     * @dev Demonstrates PackedData struct. In production, store in mapping/array for 50% gas savings vs unpacked.
     *      Real-world: NFT metadata optimization, DeFi position tracking (see Project 09: ERC721, Project 50: DeFi Capstone).
     */
    function getPackedDataExample()
        public
        view
        returns (uint128, uint128, uint64, address, bool)
    {
        PackedData memory example = PackedData({
            smallNumber1: 100,
            smallNumber2: 200,
            timestamp: uint64(block.timestamp),
            user: address(0x1234567890123456789012345678901234567890),
            flag: true
        });

        return (
            example.smallNumber1,
            example.smallNumber2,
            example.timestamp,
            example.user,
            example.flag
        );
    }
}
