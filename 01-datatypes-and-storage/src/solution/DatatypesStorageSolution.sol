// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DatatypesStorageSolution
 * @notice Complete reference implementation demonstrating Solidity datatypes and storage
 * @dev This contract showcases:
 *      - Value types (uint, address, bool, bytes32)
 *      - Reference types (arrays, structs, mappings)
 *      - Data locations (storage, memory, calldata)
 *      - Gas-efficient struct packing
 *      - Common patterns and best practices
 *
 * ????????????????????????????????????????????????????????????????????????????
 *                        CONCEPTUAL OVERVIEW
 * ????????????????????????????????????????????????????????????????????????????
 *
 * SOLIDITY TYPE SYSTEM: Why so strict?
 * ????????????????????????????????????
 * 
 * REAL-WORLD ANALOGY: Solidity types are like numbered lockers in a gym.
 * Each locker (variable) has a fixed size (type) and can only hold items that
 * fit exactly. Unlike TypeScript/Go/Rust where storage is flexible, Solidity
 * requires exact sizes because every node on the blockchain must compute the
 * same storage layout.
 *
 * Unlike TypeScript/Go/Rust (static typing with inference), Solidity requires
 * explicit types and sizes because the EVM (Ethereum Virtual Machine) needs to:
 *   1. Calculate exact gas costs at compile time
 *   2. Determine storage layout deterministically
 *   3. Prevent type confusion attacks
 *   4. Enable all nodes to compute identical state
 *
 * COMPARISON TO OTHER LANGUAGES:
 * ????????????????????????????????
 * 
 * TypeScript:
 *   let x: number = 42;  // Static typing with inference
 *   x = "hello";  // Compile error ?
 *
 * Go:
 *   var x uint256 = 42  // Static, explicit types
 *   x = "hello"  // Compile error ?
 *
 * Rust:
 *   let x: u256 = 42;  // Static, strong inference
 *   x = "hello";  // Compile error ?
 *
 * Solidity:
 *   uint256 x = 42;  // Static, explicit, NO inference, fixed size
 *   x = "hello";  // Compile error ?
 *   // Must always specify type AND size
 *
 * STORAGE MODEL:
 * ??????????????
 * 
 * REAL-WORLD ANALOGY: Storage slots are like numbered lockers in a gym.
 * Each locker (slot) can hold exactly 32 bytes (256 bits). You can pack
 * multiple small items (variables) into one locker if they fit, saving money
 * (gas). Reading/writing to lockers costs money - first access is expensive
 * (cold), subsequent accesses are cheaper (warm).
 *
 * Every contract has 2^256 storage slots (each 32 bytes / 256 bits)
 * State variables are packed into slots sequentially
 * Variables < 32 bytes can share slots if declared consecutively
 *
 * COSTS (as of 2024):
 * ????????????????????
 * - SSTORE (cold): ~20,000 gas (first write to slot) - like renting a new locker
 * - SSTORE (warm): ~5,000 gas (update existing slot) - like accessing your locker
 * - SLOAD (cold): ~2,100 gas (first read from slot) - like opening a locker for first time
 * - SLOAD (warm): ~100 gas (subsequent reads) - like quickly checking your locker
 * - Memory: ~3 gas per 32-byte word - like using a temporary desk
 * - Calldata: cheapest, read-only from transaction data - like reading a letter
 */
contract DatatypesStorageSolution {
    // ????????????????????????????????????????????????????????????????????????
    // STATE VARIABLES (Storage)
    // ????????????????????????????????????????????????????????????????????????

    /**
     * @notice A simple unsigned integer (256 bits / 32 bytes)
     * @dev Stored in slot 0
     *      WHY uint256? EVM is optimized for 256-bit words
     *      Smaller types (uint8, uint128) cost MORE gas for arithmetic
     *      unless used in structs for packing
     *
     * GAS COST: Writing this costs ~20,000 gas (first write)
     * 
     * REAL-WORLD ANALOGY: Like renting a storage unit - first time costs more
     * (cold write), but accessing it later is cheaper (warm write).
     *
     * LANGUAGE COMPARISON:
     *   TypeScript: let x: number = 42;  (static typing, no size concern)
     *   Go: var x uint256 = 42  (static, explicit, size varies by platform)
     *   Rust: let x: u256 = 42;  (static, explicit, size depends on target)
     *   Solidity: uint256 x = 42;  (static, explicit, FIXED 256-bit size)
     */
    uint256 public number;

    /**
     * @notice Ethereum address (20 bytes)
     * @dev Stored in slot 1
     *      WHY address type? Represents Ethereum accounts (EOAs) or contracts
     *      Special type with built-in methods: .transfer(), .send(), .call()
     *
     * SECURITY: Always validate addresses aren't zero: address(0)
     *
     * NOTE: Only 20 bytes, but occupies full 32-byte slot (12 bytes wasted)
     *       Could be packed with other variables if declared together
     */
    address public owner;

    /**
     * @notice Boolean flag (1 bit, but uses 1 byte in storage)
     * @dev Stored in slot 2
     *      WHY whole slot? EVM works with 32-byte words, can't address bits
     *
     * GAS OPTIMIZATION: If you had multiple bools, declare them consecutively:
     *   bool flag1; bool flag2; bool flag3;  // Still uses 32 bytes total
     *   Better: Pack in a struct with other small types
     */
    bool public isActive;

    /**
     * @notice Fixed-size byte array (32 bytes)
     * @dev Stored in slot 3
     *      WHY bytes32? Gas-efficient for hashes (keccak256 output)
     *      Fixed size = predictable gas costs
     *
     * COMPARISON:
     *   bytes32: Fixed, efficient, 32-byte hash/data
     *   bytes: Dynamic, expensive, arbitrary length
     *   string: Dynamic, UTF-8 encoded, avoid for gas efficiency
     */
    bytes32 public data;

    /**
     * @notice Mapping from address to balance
     * @dev Stored starting at slot 4 (conceptually)
     *      Actual storage: keccak256(abi.encodePacked(key, slot))
     *
     * WHY MAPPINGS?
     *   - O(1) lookup/insert (constant gas)
     *   - No iteration (can't loop over keys)
     *   - Infinite conceptual size (2^256 possible keys)
     *   - Default value is 0 for uint, false for bool, etc.
     *
     * STORAGE CALCULATION:
     *   For key 0x1234... the storage slot is:
     *   keccak256(abi.encodePacked(0x1234..., 4))
     *
     * GAS: First access (cold): ~2,100 gas
     *      Subsequent (warm): ~100 gas
     *
     * PYTHON EQUIVALENT: balances = {}  (dictionary)
     * RUST EQUIVALENT: HashMap<Address, u256>
     */
    mapping(address => uint256) public balances;

    /**
     * @notice Dynamic array of unsigned integers
     * @dev Stored starting at slot 5
     *      Length is stored in slot 5
     *      Elements stored at: keccak256(5) + index
     *
     * WHY ARRAYS?
     *   - Ordered collection
     *   - Iterable (unlike mappings)
     *   - Can be in storage, memory, or calldata
     *
     * GAS WARNING:
     *   - push(): ~20,000+ gas (cold storage write)
     *   - pop(): ~5,000 gas (sets last element to 0, refunds gas)
     *   - Iterating large arrays can exceed block gas limit ï¿½ DoS
     *
     * BEST PRACTICE: Limit array sizes or use off-chain indexing
     *
     * STORAGE LAYOUT:
     *   Slot 5: array length
     *   Slot keccak256(5) + 0: numbers[0]
     *   Slot keccak256(5) + 1: numbers[1]
     *   ...
     */
    uint256[] public numbers;

    /**
     * @notice User struct demonstrating reference types
     * @dev This struct is NOT packed (each field uses full slot)
     *
     * STORAGE LAYOUT (in mapping):
     *   address: 20 bytes ï¿½ occupies 32 bytes (slot 0 of struct)
     *   uint256: 32 bytes ï¿½ occupies 32 bytes (slot 1 of struct)
     *   bool: 1 byte ï¿½ occupies 32 bytes (slot 2 of struct)
     *
     * TOTAL: 96 bytes (3 slots) per User
     *
     * GAS INEFFICIENCY: bool wastes 31 bytes
     * See PackedData below for optimized version
     */
    struct User {
        address wallet;
        uint256 balance;
        bool isRegistered;
    }

    /**
     * @notice Mapping from address to User struct
     * @dev Demonstrates nested reference types
     *
     * STORAGE CALCULATION (for address 0xABCD...):
     *   Base slot: keccak256(abi.encodePacked(0xABCD..., 6))
     *   wallet: base_slot + 0
     *   balance: base_slot + 1
     *   isRegistered: base_slot + 2
     */
    mapping(address => User) public users;

    /**
     * @notice Gas-optimized struct with tight packing
     * @dev TOTAL: 64 bytes (2 slots) instead of 128 bytes (4 slots)
     *
     * PACKING RULES:
     *   1. Variables pack if total size <= 32 bytes
     *   2. Packing ONLY works in structs, not global state variables
     *   3. Order matters! Solidity doesn't reorder
     *
     * STORAGE LAYOUT:
     *   Slot 0: [uint128 smallNumber1][uint128 smallNumber2]  (16+16=32 bytes)
     *   Slot 1: [uint64 timestamp][address user][bool flag]    (8+20+1=29 bytes)
     *
     * GAS OPTIMIZATION: Why pack structs?
     * - Unpacked version: 4 slots = 4 * 20,000 gas (cold) = 80,000 gas
     * - Packed version: 2 slots = 2 * 20,000 gas (cold) = 40,000 gas
     * - Savings: ~40,000 gas per struct write!
     *
     * GAS SAVINGS: 2 slots vs 4 slots = ~10,000 gas saved per write!
     *
     * TRADE-OFF:
     *   ✅ Saves storage gas
     *   ❌ Slightly more complex read/write operations
     *   ❌ Must access both values in slot to modify one (in some cases)
     *
     * ALTERNATIVE (unpacked):
     *   struct UnpackedData {
     *       uint128 smallNumber1;  // Slot 0 (wastes 16 bytes)
     *       uint128 smallNumber2;  // Slot 1 (wastes 16 bytes)
     *       uint64 timestamp;      // Slot 2 (wastes 24 bytes)
     *       address user;          // Slot 3 (wastes 12 bytes)
     *       bool flag;             // Slot 4 (wastes 31 bytes)
     *   }
     *   Total: 5 slots = 100,000 gas (cold) vs 2 slots = 40,000 gas
     *   Savings: 60,000 gas (60% reduction!)
     *
     * REAL-WORLD ANALOGY: Like packing a suitcase efficiently - you can fit
     * more items (data) in fewer suitcases (storage slots), saving space
     * (gas) and money (transaction costs).
     *
     * LANGUAGE COMPARISON:
     *   TypeScript: No packing - memory layout managed by JavaScript engine
     *   Go: Struct fields aligned, but no explicit packing control
     *   Rust: #[repr(packed)] does similar optimization
     *   Solidity: Packing is automatic within structs, but order matters!
     */
    struct PackedData {
        uint128 smallNumber1; // 16 bytes
        uint128 smallNumber2; // 16 bytes
        // ^^ These two pack into one 32-byte slot
        uint64 timestamp; // 8 bytes
        address user; // 20 bytes (address is 20 bytes, not 32!)
        bool flag; // 1 byte
        // ^^ These three pack into one 32-byte slot (8+20+1=29, <32)
    }

    // ════════════════════════════════════════════════════════════════════════
    // EVENTS
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Emitted when number is updated
     * @dev Events are cheaper than storage (~2k vs ~20k gas)
     *      Used for off-chain indexing and frontend updates
     *
     * INDEXED: Allows filtering events by this parameter
     *          Can have up to 3 indexed parameters
     *          Each indexed param adds ~375 gas
     */
    event NumberUpdated(uint256 indexed oldValue, uint256 indexed newValue);

    event UserRegistered(address indexed wallet, uint256 balance);

    // ════════════════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Initializes the contract
     * @dev Constructor runs ONCE on deployment
     *      Cannot be called again (no way to re-run)
     *
     * WHY SET OWNER IN CONSTRUCTOR?
     *   - Establishes initial access control
     *   - msg.sender during deployment = deployer address
     *   - Common pattern for Ownable contracts
     *
     * GAS: Constructor code is NOT stored on-chain
     *      Only the runtime code is stored
     */
    constructor() {
        owner = msg.sender;
        isActive = true; // Initialize to active state

        // ALTERNATIVE: Could accept owner as parameter:
        // constructor(address _owner) { owner = _owner; }
    }

    // ════════════════════════════════════════════════════════════════════════
    // VALUE TYPE FUNCTIONS
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Set the number value
     * @param _number The new number value
     *
     * @dev GAS COST BREAKDOWN:
     *      - Function call overhead: ~21,000 gas (transaction base cost)
     *      - SLOAD (read old value for event): ~2,100 gas (cold) or ~100 (warm)
     *      - SSTORE (write new value): ~20,000 gas (cold) or ~5,000 (warm)
     *      - Event emission: ~2,000 gas
     *      TOTAL: ~45,000 gas (first call), ~28,000 gas (subsequent)
     *
     * GAS OPTIMIZATION: Why cache oldNumber?
     * - Reading number: 1 SLOAD = 100 gas (warm)
     * - We use it for the event
     * - If we read it twice: 2 SLOADs = 200 gas
     * - Caching: 1 SLOAD + 1 MLOAD = 103 gas
     * - Savings: ~97 gas
     *
     * ALTERNATIVE (less efficient):
     *   emit NumberUpdated(number, _number);  // Reads number twice
     *   number = _number;
     *   This would cost more gas due to multiple storage reads
     *
     * WHY PUBLIC?
     *   - Callable externally and internally
     *   - Generates automatic getter
     *   - Costs ~200 gas more than 'external' due to memory copying
     *
     * ALTERNATIVE: Could use 'external' if never called internally
     *   - Saves ~200 gas per call
     *   - But can't call from within contract
     *
     * VISIBILITY OPTIONS:
     *   public: callable anywhere (costs ~200 gas more for arrays)
     *   external: callable only from outside (cheaper for arrays)
     *   internal: callable only by this contract or derived contracts
     *   private: callable only by this contract
     *
     * REAL-WORLD ANALOGY: Like updating a value in a spreadsheet - you read
     * the old value first (to log it), then write the new value. Caching the
     * old value is like writing it on a sticky note so you don't have to
     * look it up again.
     */
    function setNumber(uint256 _number) public {
        // GAS OPTIMIZATION: Cache storage read to avoid re-reading
        uint256 oldNumber = number; // Read from storage (SLOAD: 100 gas warm)
        number = _number; // Write to storage (SSTORE: 5,000 gas warm)
        emit NumberUpdated(oldNumber, _number); // Emit event for off-chain tracking
    }

    /**
     * @notice Get the number value
     * @return The current number value
     *
     * @dev VIEW function: reads state but doesn't modify
     *      - No gas cost when called externally (off-chain call)
     *      - Costs gas when called by another contract (on-chain)
     *
     * WHY NOT JUST USE PUBLIC VARIABLE?
     *   public uint256 number; already creates a getter
     *   This explicit getter demonstrates the concept
     *   In production, rely on automatic getters for simple variables
     *
     * NOTE: Solidity ^0.8.0 has automatic overflow checks
     *       Unlike C/Python, uint256 + 1 at max value will REVERT
     */
    function getNumber() public view returns (uint256) {
        return number; // SLOAD (but no gas cost if called off-chain)
    }

    /**
     * @notice Increment the number by 1
     *
     * @dev SOLIDITY 0.8.0+ SAFETY:
     *      If number == type(uint256).max, this reverts automatically
     *      Pre-0.8.0: Would silently wrap to 0 (overflow)
     *
     * GAS OPTIMIZATION: Why use += instead of separate operations?
     * - number += 1: 1 SLOAD + 1 SSTORE = ~5,100 gas (warm)
     * - Alternative: uint256 temp = number; temp += 1; number = temp;
     *   Costs: 1 SLOAD + 1 MLOAD + 1 ADD + 1 SSTORE = ~5,103 gas
     * - Savings: Minimal (~3 gas), but += is cleaner
     *
     * GAS: ~5,000 gas if slot is warm (already accessed)
     *
     * ALTERNATIVE PATTERNS:
     *   unchecked { number += 1; }  // Disable overflow check, save ~100 gas
     *   But DANGEROUS if overflow is possible!
     *   Only use unchecked when you're CERTAIN overflow can't happen
     *
     * REAL-WORLD ANALOGY: Like incrementing a counter - you read the current
     * value, add 1, and write it back. Using += does this in one operation.
     */
    function incrementNumber() public {
        // Checked arithmetic (safe, but costs ~100 gas for overflow check)
        number += 1; // SLOAD (100) + ADD (3) + SSTORE (5,000) = ~5,103 gas (warm)
    }

    // ════════════════════════════════════════════════════════════════════════
    // MAPPING FUNCTIONS
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Set balance for an address
     * @param _address The address to set balance for
     * @param _balance The balance amount
     *
     * @dev MAPPING BEHAVIOR:
     *      - If key doesn't exist, creates new entry
     *      - No "key exists" check needed
     *      - Can't iterate over keys (no .keys() like Python)
     *      - Can't get length/size
     *
     * STORAGE SLOT CALCULATION:
     *   Slot = keccak256(abi.encodePacked(_address, 4))
     *   where 4 is the slot of the 'balances' mapping
     *
     * GAS OPTIMIZATION: Direct assignment vs read-modify-write
     * - balances[_address] = _balance: 1 SSTORE = ~20,000 gas (cold) or ~5,000 (warm)
     * - Alternative: uint256 old = balances[_address]; balances[_address] = _balance;
     *   Costs: 1 SLOAD + 1 SSTORE = ~7,100 gas (warm)
     * - Direct assignment saves: ~2,100 gas (no need to read if we're overwriting)
     *
     * GAS: ~20,000 gas (first write to this address - cold)
     *      ~5,000 gas (update existing balance - warm)
     *
     * REAL-WORLD ANALOGY: Like writing a new value in a phone book - if you're
     * replacing the entire entry, you don't need to read it first. Just write
     * the new value directly.
     *
     * LANGUAGE COMPARISON:
     *   TypeScript: balances.set(address, balance) - similar concept
     *   Go: balances[address] = balance - similar syntax
     *   Rust: balances.insert(address, balance) - similar concept
     *   Solidity: balances[address] = balance - direct assignment
     */
    function setBalance(address _address, uint256 _balance) public {
        // Direct assignment - no need to read first if we're overwriting
        balances[_address] = _balance; // SSTORE to calculated slot
    }

    /**
     * @notice Get balance for an address
     * @param _address The address to query
     * @return The balance amount
     *
     * @dev MAPPING DEFAULT VALUES:
     *      If key never set, returns default (0 for uint256)
     *      This is different from Python, which would raise KeyError
     *
     * To check if key exists explicitly:
     *   if (balances[_address] != 0) { ... }
     *   But careful: can't distinguish "never set" from "set to 0"
     *
     * Better pattern: Use a separate mapping for existence:
     *   mapping(address => bool) exists;
     */
    function getBalance(address _address) public view returns (uint256) {
        return balances[_address]; // SLOAD from calculated slot
    }

    // ════════════════════════════════════════════════════════════════════════
    // ARRAY FUNCTIONS
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Add a number to the numbers array
     * @param _number The number to add
     *
     * @dev ARRAY.PUSH():
     *      1. Increments array length (SSTORE)
     *      2. Writes new element (SSTORE)
     *
     * GAS: ~40,000+ gas (two cold storage writes)
     *
     * STORAGE SLOTS:
     *   Length: slot 5
     *   Element 0: keccak256(5) + 0
     *   Element 1: keccak256(5) + 1
     *   ...
     *
     * ï¿½ DANGER: Unbounded growth!
     *   If array grows too large, iterating over it can exceed block gas limit
     *   ï¿½ Contract becomes unusable (DoS)
     *
     * BEST PRACTICE:
     *   - Limit array sizes
     *   - Use mappings for large datasets
     *   - Emit events for off-chain indexing instead
     */
    function addNumber(uint256 _number) public {
        numbers.push(_number); // Append to array
    }

    /**
     * @notice Get the length of the numbers array
     * @return The array length
     *
     * @dev Array length is stored in the mapping's slot
     *      For dynamic arrays in storage, .length is a state variable
     *
     * GAS: ~2,100 gas (cold read) or ~100 gas (warm read)
     */
    function getNumbersLength() public view returns (uint256) {
        return numbers.length; // SLOAD from slot 5
    }

    /**
     * @notice Get a number at a specific index
     * @param _index The index to query
     * @return The number at that index
     *
     * @dev BOUNDS CHECKING:
     *      Solidity automatically checks if index < length
     *      If out of bounds, reverts with panic
     *
     * This is safer than C (undefined behavior) but costs gas
     *
     * GAS: ~2,100 gas (cold) or ~100 gas (warm)
     *
     * PYTHON COMPARISON:
     *   Python: numbers[_index]  # Raises IndexError if out of bounds
     *   Solidity: numbers[_index]  # Reverts if out of bounds
     */
    function getNumberAt(uint256 _index) public view returns (uint256) {
        require(_index < numbers.length, "Index out of bounds"); // Explicit check
        return numbers[_index]; // SLOAD from calculated slot
    }

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // STRUCT FUNCTIONS
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    /**
     * @notice Register a user
     * @param _wallet The user's wallet address
     * @param _balance The initial balance
     *
     * @dev STRUCT INITIALIZATION:
     *      Three ways to create a struct:
     *        1. Named fields: User({wallet: _wallet, balance: _balance, isRegistered: true})
     *        2. Positional: User(_wallet, _balance, true)
     *        3. Storage reference: users[_wallet].wallet = _wallet; (shown below)
     *
     * WHY METHOD 3?
     *   - Direct storage write, no intermediate copy
     *   - Gas-efficient for partial updates
     *   - Clear which fields are being set
     *
     * GAS: ~60,000 gas (3 storage slots: wallet, balance, isRegistered)
     *
     * ALTERNATIVE (memory then copy):
     *   User memory tempUser = User(_wallet, _balance, true);
     *   users[_wallet] = tempUser;
     *   Slightly less gas-efficient due to memory allocation
     */
    function registerUser(address _wallet, uint256 _balance) public {
        // Write directly to storage mapping
        users[_wallet] = User({wallet: _wallet, balance: _balance, isRegistered: true});

        emit UserRegistered(_wallet, _balance);
    }

    /**
     * @notice Get user information
     * @param _wallet The user's wallet address
     * @return wallet address
     * @return balance amount
     * @return isRegistered status
     *
     * @dev RETURN VALUES:
     *      Can return multiple values (like Python tuples)
     *      Can use named returns: returns (address wallet, ...)
     *      Then return statement optional (returns named vars automatically)
     *
     * STORAGE vs MEMORY:
     *   User storage user = users[_wallet];  // Reference to storage
     *   User memory user = users[_wallet];   // Copy to memory
     *
     * WHY MEMORY HERE?
     *   - We're only reading, not modifying
     *   - Memory copy is fine for return values
     *   - Slightly clearer intent
     *
     * GAS: ~6,300 gas (3 cold SLOADs) or ~300 gas (warm)
     */
    function getUser(address _wallet)
        public
        view
        returns (address wallet, uint256 balance, bool isRegistered)
    {
        User memory user = users[_wallet]; // Copy from storage to memory
        return (user.wallet, user.balance, user.isRegistered);
    }

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // DATA LOCATION DEMONSTRATION
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    /**
     * @notice Demonstrates memory usage - processes array without persisting
     * @param _arr Array to process (in memory)
     * @return The sum of array elements
     *
     * @dev DATA LOCATION: memory
     *      - Temporary allocation, erased after function exits
     *      - Mutable within function
     *      - Costs ~3 gas per 32-byte word
     *
     * WHEN TO USE MEMORY:
     *   - Temporary calculations
     *   - Function return values
     *   - When you need to modify a copy without affecting storage
     *
     * WHY PURE?
     *   - Doesn't read or write state
     *   - Can be executed off-chain (no gas)
     *   - Can be executed locally by contracts (costs gas)
     *
     * GAS: ~200 gas + (3 gas ï¿½ array length)
     *
     * PYTHON EQUIVALENT:
     *   def sum_array(arr):  # arr is passed by reference, but not stored
     *       return sum(arr)
     */
    function sumMemoryArray(uint256[] memory _arr) public pure returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < _arr.length; i++) {
            sum += _arr[i]; // Read from memory (cheap)
        }
        return sum;
    }

    /**
     * @notice Demonstrates calldata usage - most gas-efficient for read-only
     * @param _arr Array to process (in calldata)
     * @return The first element
     *
     * @dev DATA LOCATION: calldata
     *      - Read-only, cannot be modified
     *      - Comes directly from transaction data
     *      - No copying overhead
     *      - Cheapest option for external function parameters
     *
     * WHEN TO USE CALLDATA:
     *   - External function parameters that you won't modify
     *   - Arrays and strings in external functions
     *   - When gas optimization is critical
     *
     * RESTRICTION: Only available in external functions
     *   internal/private/public functions can't use calldata for arrays
     *
     * GAS: ~100 gas (no copying overhead)
     *
     * WHY EXTERNAL?
     *   - Required for calldata parameters
     *   - More gas-efficient than public (no memory copy)
     *   - Can't be called internally (use this.functionName())
     *
     * GAS COMPARISON:
     *   calldata: 100 gas (read-only, direct access)
     *   memory: 3 gas ï¿½ array length (copy entire array)
     *   storage: ~2,100 gas per element (if reading from state)
     */
    function getFirstElement(uint256[] calldata _arr) external pure returns (uint256) {
        require(_arr.length > 0, "Array is empty");
        return _arr[0]; // Read directly from calldata (no copy)
    }

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // HELPER FUNCTIONS
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    /**
     * @notice Check if an address has a non-zero balance
     * @param _address The address to check
     * @return true if balance > 0
     *
     * @dev MAPPING EXISTENCE CHECK:
     *      mappings always return default value (0) for non-existent keys
     *      Can't distinguish "never set" from "set to 0"
     *
     * Better pattern for existence tracking:
     *   mapping(address => bool) exists;
     *   mapping(address => uint256) balances;
     *   Then: if (exists[_address]) { ... }
     *
     * GAS: ~2,100 gas (cold) or ~100 gas (warm)
     */
    function hasBalance(address _address) public view returns (bool) {
        return balances[_address] > 0;
    }

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // ADVANCED: Demonstrate storage slot packing
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    /**
     * @notice Gets packed data to demonstrate struct packing
     * @dev This is just a view function to show that PackedData struct exists
     *      In real usage, you'd store PackedData in a mapping or array
     *
     * EXAMPLE USAGE:
     *   mapping(uint256 => PackedData) public packedDataStore;
     *
     *   function storePackedData(uint256 id) public {
     *       packedDataStore[id] = PackedData({
     *           smallNumber1: 100,
     *           smallNumber2: 200,
     *           timestamp: uint64(block.timestamp),
     *           user: msg.sender,
     *           flag: true
     *       });
     *   }
     *
     * GAS SAVINGS:
     *   Without packing: 4 slots ï¿½ 20,000 gas = 80,000 gas
     *   With packing: 2 slots ï¿½ 20,000 gas = 40,000 gas
     *   SAVINGS: 50% reduction!
     */
    function getPackedDataExample()
        public
        pure
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

/**
 * TPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPW
 * Q                          KEY TAKEAWAYS                                    Q
 * ZPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP]
 *
 * 1. TYPES ARE STRICT
 *      EVM requires deterministic, fixed-size layout
 *      No type inference, no dynamic typing
 *
 * 2. DATA LOCATIONS MATTER
 *      storage: Persistent, expensive (~20k gas/write)
 *      memory: Temporary, medium cost (~3 gas/word)
 *      calldata: Read-only, cheapest (no copy)
 *
 * 3. GAS IS KING
 *      Every operation costs gas
 *      Storage is 100x more expensive than memory
 *      Struct packing can save 50%+ gas
 *
 * 4. MAPPINGS ARE SPECIAL
 *      O(1) access, no iteration
 *      Infinite conceptual size
 *      Storage slot = keccak256(key, slot)
 *
 * 5. ARRAYS ARE DANGEROUS
 *      Unbounded growth ï¿½ DoS
 *      Iteration costs scale linearly
 *      Consider mappings + events instead
 *
 * 6. SOLIDITY != OTHER LANGUAGES
 *      Python: Dynamic, forgiving, high-level
 *      Rust: Static, safe, but has inference
 *      Solidity: Static, explicit, gas-aware, blockchain-specific
 *
 * TPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPW
 * Q                        COMMON MISTAKES                                    Q
 * ZPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP]
 *
 * L Forgetting data location: uint[] arr (missing memory/calldata)
 * L Modifying memory instead of storage: User memory u = users[addr]; u.x = 5;
 * L Inefficient packing: Declaring uint8 after uint256
 * L Unbounded loops: for(i = 0; i < array.length; i++) on large arrays
 * L Not checking array bounds explicitly when needed
 * L Using smaller uints for local variables (costs MORE gas)
 * L Not emitting events for state changes (off-chain indexing needs them)
 *
 * TPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPW
 * Q                          NEXT STEPS                                       Q
 * ZPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP]
 *
 * ï¿½ Experiment with different data types in Remix
 * ï¿½ Use `forge test --gas-report` to see actual gas costs
 * ï¿½ Try modifying struct packing and observe gas differences
 * ï¿½ Move to Project 02 to learn about functions and ETH handling
 */
