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
     * @notice Dynamic string message
     * @dev Stored starting at slot 4
     *      Strings are dynamic and expensive - each character costs gas
     *      Prefer bytes32 for fixed-size data when possible
     *
     * GAS: More expensive than bytes32 due to dynamic length encoding
     */
    string public message;

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
     * @dev EVENTS: The Bridge Between On-Chain and Off-Chain
     * ═══════════════════════════════════════════════════════════
     *
     *      Events are like receipts - they prove something happened on-chain!
     *      But unlike storage, they're optimized for off-chain consumption.
     *
     *      HOW EVENTS WORK:
     *      ┌─────────────────────────────────────────┐
     *      │ Contract emits event                    │
     *      │   ↓                                      │
     *      │ Event data stored in transaction log    │ ← Cheaper than storage!
     *      │   ↓                                      │
     *      │ Off-chain systems listen to events       │ ← Indexers, frontends
     *      │   ↓                                      │
     *      │ UI updates in real-time                 │ ← Magic! ✨
     *      └─────────────────────────────────────────┘
     *
     *      FUN FACT: Events are stored in transaction logs, not contract storage!
     *      This makes them:
     *      - Cheaper (~2,000 gas vs ~20,000 gas for storage)
     *      - Searchable (can filter by indexed parameters)
     *      - Perfect for off-chain systems
     *
     *      INDEXED PARAMETERS: The Search Feature
     *      ════════════════════════════════════════
     *
     *      Indexed parameters are like searchable tags:
     *      - Can filter events by indexed values
     *      - Up to 3 indexed parameters per event
     *      - Each indexed param costs ~375 gas extra
     *
     *      Example: Filter all NumberUpdated events where oldValue = 100
     *      ```javascript
     *      contract.on("NumberUpdated", { oldValue: 100 }, (event) => {
     *          console.log("Number was updated from 100!");
     *      });
     *      ```
     *
     *      CONNECTION TO STORAGE:
     *      Events complement storage:
     *      - Storage: For on-chain state (expensive, persistent)
     *      - Events: For off-chain indexing (cheap, searchable)
     *      - Best practice: Use both! Store state, emit events for tracking.
     *
     *      REAL-WORLD ANALOGY:
     *      Like a receipt system:
     *      - Storage = The actual inventory (what's in stock)
     *      - Events = Receipts (proof of transactions)
     *      - Frontend = Cash register display (shows events in real-time)
     *
     *      GAS COST:
     *      - Base event: ~375 gas
     *      - Each indexed param: +375 gas
     *      - Each non-indexed param: +375 gas (for data)
     *      TOTAL: ~2,000-3,000 gas (much cheaper than storage!)
     *
     *      🎓 LEARNING MOMENT:
     *      Events are your contract's "API" for off-chain systems!
     *      Frontends, indexers, and analytics tools all rely on events.
     *      Without events, off-chain systems would have to constantly poll storage
     *      (expensive and inefficient!). Events make blockchain data accessible!
     */
    event NumberUpdated(uint256 indexed oldValue, uint256 indexed newValue);

    /**
     * @notice Emitted when a user registers
     * @dev Notice: wallet is indexed (searchable), balance is not
     *      This allows filtering by wallet address efficiently
     */
    event UserRegistered(address indexed wallet, uint256 balance);

    /**
     * @notice Emitted when ETH is deposited
     * @dev depositor is indexed for efficient filtering
     *      Frontends can listen to all deposits from a specific address
     */
    event FundsDeposited(address indexed depositor, uint256 amount);

    /**
     * @notice Emitted when message is updated
     * @dev Strings can't be indexed (too large)
     *      Both parameters are non-indexed (stored as data)
     */
    event MessageUpdated(string oldMessage, string newMessage);

    /**
     * @notice Emitted when balance is updated
     * @dev Both parameters are non-indexed
     */
    event BalanceUpdated(address addr, uint256 balance);

    // ════════════════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Initializes the contract
     * @dev Constructor runs ONCE on deployment
     *
     * 🏗️  CONSTRUCTORS: The One-Time Setup
     * ═══════════════════════════════════════
     *
     *      Constructors are special functions that run EXACTLY ONCE - when the contract is deployed.
     *      Think of them as the "birth" of your contract - they set up the initial state.
     *
     *      HOW CONSTRUCTORS WORK:
     *      ┌─────────────────────────────────────────┐
     *      │ Developer deploys contract             │
     *      │   ↓                                      │
     *      │ Constructor executes                   │ ← Runs ONCE, never again!
     *      │   ↓                                      │
     *      │ Initial state is set                    │
     *      │   ↓                                      │
     *      │ Contract is live on blockchain          │
     *      │   ↓                                      │
     *      │ Constructor code is DISCARDED           │ ← Not stored!
     *      └─────────────────────────────────────────┘
     *
     *      FUN FACT: Constructor code is NOT stored on-chain!
     *      Only the runtime code (your functions) is stored.
     *      The constructor runs during deployment, then disappears!
     *      This saves gas - you don't pay to store initialization code forever.
     *
     *      WHY SET OWNER IN CONSTRUCTOR?
     *      This is a CRITICAL security pattern:
     *      1. Establishes who controls the contract
     *      2. msg.sender during deployment = the deployer
     *      3. Prevents anyone else from claiming ownership
     *      4. Common pattern in "Ownable" contracts (like OpenZeppelin)
     *
     *      CONNECTION TO SECURITY:
     *      Setting owner in constructor ensures:
     *      - Only deployer can be owner (can't be changed later)
     *      - No race conditions (set atomically during deployment)
     *      - Clear ownership from the start
     *
     *      REAL-WORLD ANALOGY:
     *      Like setting up a new bank account:
     *      - Constructor = Opening the account (one-time setup)
     *      - Owner = Account holder (who controls it)
     *      - isActive = Account status (active/inactive)
     *
     *      GAS COST:
     *      - Constructor execution: Included in deployment cost
     *      - Setting owner: ~20,000 gas (cold write)
     *      - Setting isActive: ~20,000 gas (cold write)
     *      - Total deployment: ~200,000+ gas (includes bytecode storage)
     *
     *      ⚠️  IMPORTANT: Constructor can't be called again!
     *      Once deployed, there's NO WAY to re-run the constructor.
     *      This is why initialization must be complete and correct!
     *
     *      🎓 LEARNING MOMENT:
     *      Constructors are your only chance to set initial state!
     *      Make sure everything is initialized correctly here.
     *      If you forget something, you'll need a separate initialization function
     *      (but that's less secure - anyone could call it!).
     */
    constructor() {
        // 👤 SET OWNER: Critical security step!
        // msg.sender during deployment = the address deploying the contract
        // This establishes who "owns" the contract
        // Common pattern: owner can call admin functions later
        owner = msg.sender; // SSTORE: ~20,000 gas (cold write to slot 1)
        
        // ✅ ACTIVATE CONTRACT: Set initial state
        // Starting with isActive = true means contract is ready to use immediately
        // Alternative: Start false, require activation function (more secure)
        isActive = true; // SSTORE: ~20,000 gas (cold write to slot 2)

        // 💡 ALTERNATIVE PATTERN:
        // You could accept owner as parameter:
        //   constructor(address _owner) { owner = _owner; }
        // This allows deploying with a different owner (useful for proxies)
        // But simpler contracts usually use msg.sender (like we do here)
    }

    // ════════════════════════════════════════════════════════════════════════
    // ETHER HANDLING
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Deposit ETH into the contract
     * @dev Payable function - receives ETH and updates balance
     *
     * 💰 RECEIVING ETH: The Magic of Payable Functions
     * ════════════════════════════════════════════════
     *
     *      This function is SPECIAL - it can receive Ether! Notice the `payable` keyword?
     *      Without `payable`, sending ETH to this function would REVERT.
     *
     *      HOW IT WORKS:
     *      ┌─────────────────────────────────────────┐
     *      │ User sends transaction with ETH         │
     *      │   ↓                                      │
     *      │ Contract receives ETH automatically     │ ← Magic happens here!
     *      │   ↓                                      │
     *      │ msg.value contains the ETH amount       │ ← Accessible in function
     *      │   ↓                                      │
     *      │ Contract balance increases              │ ← No explicit transfer needed!
     *      └─────────────────────────────────────────┘
     *
     *      FUN FACT: Before Solidity 0.6.0, you had to use `address(this).balance`
     *      to check received ETH. Now `msg.value` makes it explicit and safer!
     *
     *      CONNECTION TO MAPPINGS:
     *      We're using the `balances` mapping we learned about earlier!
     *      This is a real-world use case: tracking user deposits.
     *
     *      REAL-WORLD ANALOGY:
     *      Think of this like a vending machine:
     *      - You insert coins (send ETH)
     *      - Machine records your credit (updates balances mapping)
     *      - You can check your balance anytime (getBalance())
     *      - Machine logs the transaction (emits event)
     *
     *      SECURITY CONSIDERATIONS:
     *      ⚠️  Always validate msg.value > 0 (prevents accidental zero deposits)
     *      ⚠️  Use += instead of = to handle multiple deposits correctly
     *      ⚠️  Consider reentrancy protection for production contracts
     *
     *      GAS BREAKDOWN:
     *      - require() check: ~3 gas (if passes)
     *      - Mapping read + write: ~20,000 gas (cold) or ~5,000 gas (warm)
     *      - Event emission: ~2,000 gas
     *      TOTAL: ~22,000 gas (first deposit) or ~7,000 gas (subsequent)
     *
     *      PATTERN RECOGNITION:
     *      Notice we use `+=` here? This is read-modify-write pattern.
     *      We MUST read first (to get existing balance), then add, then write.
     *      This is different from setBalance() where we just overwrite!
     *
     *      🎓 LEARNING MOMENT:
     *      Why `+=` instead of `=`? Because users might deposit multiple times!
     *      If Alice deposits 1 ETH, then 2 ETH, her balance should be 3 ETH total.
     *      Using `=` would overwrite and lose the first deposit! 😱
     */
    function deposit() public payable {
        // 🛡️  VALIDATION: Always check inputs!
        // This prevents users from accidentally sending 0 ETH (wasting gas)
        // It's also a security best practice - validate everything!
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        // 💵 READ-MODIFY-WRITE PATTERN:
        // 1. Read: balances[msg.sender] (SLOAD: ~100 gas warm)
        // 2. Modify: Add msg.value to existing balance
        // 3. Write: Store back to mapping (SSTORE: ~5,000 gas warm)
        // 
        // Why += instead of =? Because users can deposit multiple times!
        // Example: Deposit 1 ETH, then 2 ETH → balance should be 3 ETH total
        balances[msg.sender] += msg.value; // Magic: ETH automatically added to contract!
        
        // 📢 EVENT: Log the deposit for transparency
        // Off-chain systems (like frontends) can listen to this event
        // to show users their deposit history in real-time!
        emit FundsDeposited(msg.sender, msg.value);
    }

    // ════════════════════════════════════════════════════════════════════════
    // VALUE & REFERENCE TYPE FUNCTIONS
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
     * GAS OPTIMIZATION: Why cache oldValue?
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
        // 🎯 PATTERN: Cache-Before-Update
        // This is a common Solidity pattern! We read the old value first,
        // then update, then use the cached value for the event.
        // Why? Because reading from storage twice costs more gas!
        //
        // Gas comparison:
        //   Bad: emit NumberUpdated(number, _number); number = _number;
        //        → Reads number twice = 2 × SLOAD = 200 gas
        //   Good: Cache first, then update = 1 × SLOAD = 100 gas
        //        Savings: 100 gas per call!
        uint256 oldValue = number; // SLOAD: ~100 gas (warm read from slot 0)
        
        // 💾 WRITE OPERATION: Update the state variable
        // This is where the real cost happens - storage writes are expensive!
        // Cold write: ~20,000 gas (first time)
        // Warm write: ~5,000 gas (subsequent writes)
        number = _number; // SSTORE: ~5,000 gas (warm write to slot 0)
        
        // 📢 EVENT EMISSION: Log the change
        // Events are like receipts - they prove something happened!
        // Off-chain systems (like frontends) listen to these events
        // to update UIs in real-time. Much cheaper than storage!
        emit NumberUpdated(oldValue, _number); // ~2,000 gas (event emission)
    }

    /**
     * @notice Get the number value
     * @return The current number value
     *
     * @dev VIEW FUNCTIONS: Reading State Without Cost
     * ════════════════════════════════════════════════
     *
     *      View functions are special - they can read state but not modify it.
     *      When called off-chain, they're FREE! No gas cost at all!
     *
     *      HOW VIEW FUNCTIONS WORK:
     *      ┌─────────────────────────────────────────┐
     *      │ Off-chain call (e.g., from frontend)     │
     *      │   ↓                                      │
     *      │ Function executes locally                │ ← No transaction!
     *      │   ↓                                      │
     *      │ Reads state (simulated)                  │ ← Free!
     *      │   ↓                                      │
     *      │ Returns value                            │
     *      └─────────────────────────────────────────┘
     *
     *      FUN FACT: View functions don't create transactions!
     *      They're executed locally by your node, then the result is returned.
     *      This is why they're free - nothing is written to the blockchain!
     *
     *      WHEN DO VIEW FUNCTIONS COST GAS?
     *      Only when called by another contract (on-chain call):
     *      - Contract A calls Contract B's view function
     *      - This happens in a transaction
     *      - Gas is charged (~100 gas for SLOAD)
     *
     *      CONNECTION TO AUTOMATIC GETTERS:
     *      Remember: `public uint256 number;` automatically creates a getter!
     *      Solidity generates `function number() public view returns (uint256)`
     *      So why write this explicit function?
     *      - Demonstrates the concept
     *      - Can add custom logic later
     *      - Shows how view functions work
     *
     *      REAL-WORLD ANALOGY:
     *      Like checking your bank balance:
     *      - Off-chain: Look at your phone app (free, instant)
     *      - On-chain: Bank teller checks computer (costs time/money)
     *
     *      GAS COST:
     *      - Off-chain call: FREE! (no transaction)
     *      - On-chain call: ~100 gas (SLOAD from storage)
     *
     *      🎓 LEARNING MOMENT:
     *      View functions are perfect for frontends!
     *      You can call them as many times as you want without paying gas.
     *      This is why DApps can show real-time data - they're constantly
     *      calling view functions to update the UI!
     */
    function getNumber() public view returns (uint256) {
        // 📖 READ FROM STORAGE: Simple and straightforward
        // This reads from slot 0 (where 'number' is stored)
        // If called off-chain: FREE (no gas cost!)
        // If called on-chain: ~100 gas (SLOAD operation)
        return number; // SLOAD from slot 0: ~100 gas (if on-chain), FREE (if off-chain)
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
        // 🔢 INCREMENT OPERATION: The += Pattern
        // This single line does THREE things:
        //   1. Read: Load number from storage (SLOAD: ~100 gas)
        //   2. Compute: Add 1 to the value (ADD: ~3 gas)
        //   3. Write: Store result back (SSTORE: ~5,000 gas)
        // Total: ~5,103 gas (warm)
        //
        // FUN FACT: Solidity 0.8.0+ automatically checks for overflow!
        // If number == type(uint256).max (2^256 - 1), this will REVERT.
        // Pre-0.8.0: Would silently wrap to 0 (dangerous!)
        //
        // CONNECTION TO SAFETY:
        // This is checked arithmetic - Solidity ensures we can't overflow.
        // The overflow check costs ~100 gas, but it prevents bugs!
        number += 1; // Read-modify-write in one operation: ~5,103 gas (warm)
        
        // 💡 OPTIMIZATION TIP:
        // If you're CERTAIN overflow can't happen, you can use:
        //   unchecked { number += 1; }  // Saves ~100 gas
        // But be careful! Only use unchecked when you're 100% sure!
    }

    /**
     * @notice Set the message string
     * @param _message The new message
     *
     * @dev STRING STORAGE: The Expensive Choice
     *      ═══════════════════════════════════════
     *      
     *      Strings in Solidity are like luxury items - they work great, but they cost!
     *      Unlike bytes32 (fixed 32 bytes), strings are dynamic and variable-length.
     *
     *      HOW STRINGS ARE STORED:
     *      ┌─────────────────────────────────────┐
     *      │ Slot N: Length (uint256)           │ ← How many bytes?
     *      ├─────────────────────────────────────┤
     *      │ Slot N+1: First 32 bytes of data   │ ← UTF-8 encoded characters
     *      │ Slot N+2: Next 32 bytes of data    │ ← Continues if > 32 chars
     *      │ ...                                 │
     *      └─────────────────────────────────────┘
     *
     *      FUN FACT: "Hello World" (11 chars) uses 2 slots:
     *      - Slot 1: length = 11
     *      - Slot 2: "Hello World" + padding
     *      Total: ~40,000 gas (cold) vs bytes32's ~20,000 gas
     *
     *      WHY SO EXPENSIVE?
     *      1. Length encoding overhead (extra storage slot)
     *      2. UTF-8 encoding complexity (multi-byte characters)
     *      3. Dynamic size means more complex storage layout
     *
     *      CONNECTION TO EARLIER CONCEPTS:
     *      Remember bytes32? It's like a fixed-size box - predictable and cheap.
     *      Strings are like expandable luggage - flexible but heavier!
     *
     *      REAL-WORLD ANALOGY:
     *      bytes32 = Fixed-size shipping box (always same cost)
     *      string = Variable-size package (costs more, scales with size)
     *
     *      WHEN TO USE STRINGS:
     *      ✅ User-facing text (names, descriptions)
     *      ✅ Dynamic content that changes length
     *      ❌ Don't use for: hashes, fixed identifiers, gas-critical operations
     *
     *      GAS BREAKDOWN:
     *      - Reading old message: ~2,100 gas (cold) or ~100 gas (warm)
     *      - Writing new message: ~20,000+ gas (depends on length)
     *      - Event emission: ~2,000 gas
     *      TOTAL: ~24,000+ gas (first call)
     *
     *      OPTIMIZATION TIP:
     *      If you know max length ≤ 32 bytes, use bytes32 instead!
     *      Example: bytes32 public shortMessage; // Much cheaper!
     */
    function setMessage(string memory _message) public {
        // 🎯 PATTERN: Cache old value before updating
        // Why? We need it for the event, and reading twice costs more gas
        // This is the same pattern we used in setNumber() - see the connection?
        string memory oldMessage = message; // SLOAD: ~100 gas (warm)
        
        // 💾 WRITE OPERATION: This is where the cost happens!
        // For "Hello World" (11 bytes): ~20,000 gas (cold storage write)
        // The EVM must:
        //   1. Calculate storage slots needed
        //   2. Encode the string as UTF-8
        //   3. Write length + data to storage
        message = _message; // SSTORE: expensive for dynamic types!
        
        // 📢 EVENT: Log the change for off-chain systems
        // Events are cheaper than storage (~2k vs ~20k gas)
        // Frontends can listen to these events to update UIs in real-time!
        emit MessageUpdated(oldMessage, _message);
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
        emit BalanceUpdated(_address, _balance);
    }

    /**
     * @notice Get balance for an address
     * @param _address The address to query
     * @return The balance amount
     *
     * @dev MAPPING DEFAULT VALUES: The Zero Mystery
     * ═══════════════════════════════════════════════
     *
     *      Here's something fascinating about Solidity mappings:
     *      They ALWAYS return a value, even for keys that were never set!
     *
     *      THE ZERO DEFAULT:
     *      ┌─────────────────────────────────────┐
     *      │ Key never set? → Returns 0         │ ← Not an error!
     *      │ Key set to 0?   → Returns 0         │ ← Same result!
     *      └─────────────────────────────────────┘
     *
     *      FUN FACT: This is different from most languages!
     *      - Python: Raises KeyError if key doesn't exist
     *      - JavaScript: Returns undefined
     *      - Solidity: Returns the type's default value (0 for uint256)
     *
     *      WHY THIS DESIGN?
     *      Solidity prioritizes gas efficiency and safety:
     *      1. No need to check "does key exist?" (saves gas)
     *      2. No risk of undefined/null errors (safer)
     *      3. Predictable behavior (easier to reason about)
     *
     *      THE PROBLEM: Can't Distinguish States
     *      ════════════════════════════════════════
     *      
     *      How do you know if someone has zero balance because:
     *      A) They never deposited (key doesn't exist)
     *      B) They deposited and withdrew everything (key exists, value is 0)
     *
     *      SOLUTION PATTERNS:
     *      
     *      Pattern 1: Separate existence mapping
     *      ```solidity
     *      mapping(address => bool) public hasDeposited;
     *      mapping(address => uint256) public balances;
     *      
     *      function deposit() public payable {
     *          hasDeposited[msg.sender] = true;  // Mark as existing
     *          balances[msg.sender] += msg.value;
     *      }
     *      ```
     *
     *      Pattern 2: Use non-zero sentinel value
     *      ```solidity
     *      // Reserve 0 for "never set", use 1 wei minimum for "exists"
     *      ```
     *
     *      CONNECTION TO STORAGE:
     *      Remember how mappings calculate storage slots?
     *      slot = keccak256(key, mapping_slot)
     *      If that slot was never written to, it contains all zeros!
     *      That's why we get 0 back - it's literally reading empty storage!
     *
     *      REAL-WORLD ANALOGY:
     *      Like checking a mailbox:
     *      - Empty mailbox (never used) = 0 letters
     *      - Mailbox with 0 letters (all removed) = 0 letters
     *      You can't tell which is which just by looking!
     *
     *      GAS COST:
     *      - Cold read: ~2,100 gas (first time accessing this address)
     *      - Warm read: ~100 gas (subsequent reads)
     *      - No gas if called off-chain (view functions are free when called externally)
     *
     *      🎓 LEARNING MOMENT:
     *      This is why `hasBalance()` exists! It's a helper that checks if balance > 0.
     *      But remember: balance = 0 doesn't mean "never set" - it could mean "withdrawn everything"!
     */
    function getBalance(address _address) public view returns (uint256) {
        // 🔍 MAPPING LOOKUP: Always succeeds, never throws!
        // Even if _address was never used before, this returns 0
        // This is the "zero default" behavior we discussed above
        return balances[_address]; // SLOAD from calculated slot: keccak256(_address, slot_4)
    }

    // ════════════════════════════════════════════════════════════════════════
    // ARRAY FUNCTIONS
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Add a number to the numbers array
     * @param _number The number to add
     *
     * @dev ARRAYS: Ordered Collections with Hidden Complexity
     * ════════════════════════════════════════════════════════
     *
     *      Arrays in Solidity are like numbered shelves in a warehouse.
     *      Each item has a position (index), and you can add items to the end.
     *
     *      HOW ARRAYS ARE STORED:
     *      ┌─────────────────────────────────────────────┐
     *      │ Slot 5: Length (how many items)            │ ← Stored separately!
     *      ├─────────────────────────────────────────────┤
     *      │ Slot keccak256(5) + 0: numbers[0]          │ ← First element
     *      │ Slot keccak256(5) + 1: numbers[1]          │ ← Second element
     *      │ Slot keccak256(5) + 2: numbers[2]          │ ← Third element
     *      │ ...                                         │
     *      └─────────────────────────────────────────────┘
     *
     *      FUN FACT: The length and elements are stored SEPARATELY!
     *      This is different from languages like Python where length is calculated.
     *      In Solidity, length is a state variable that must be updated manually.
     *
     *      WHAT HAPPENS WHEN YOU PUSH:
     *      Step 1: Read current length (SLOAD: ~100 gas warm)
     *      Step 2: Write new length = old_length + 1 (SSTORE: ~5,000 gas warm)
     *      Step 3: Calculate new element slot = keccak256(5) + new_length
     *      Step 4: Write element to that slot (SSTORE: ~5,000 gas warm)
     *      
     *      TOTAL: ~10,000+ gas (warm) or ~40,000+ gas (cold)
     *
     *      CONNECTION TO MAPPINGS:
     *      Notice the storage calculation? It's similar to mappings!
     *      - Mapping: slot = keccak256(key, mapping_slot)
     *      - Array: slot = keccak256(array_slot) + index
     *      Both use keccak256, but arrays use sequential indices!
     *
     *      REAL-WORLD ANALOGY:
     *      Think of a library:
     *      - Length = catalog showing how many books
     *      - Elements = actual books on numbered shelves
     *      - push() = add a new book and update the catalog
     *
     *      ⚠️  THE DANGER: Unbounded Growth!
     *      ════════════════════════════════════
     *      
     *      Arrays can grow FOREVER (up to 2^256 elements theoretically).
     *      This creates a Denial of Service (DoS) vulnerability:
     *
     *      Example Attack:
     *      ```solidity
     *      // Attacker calls this repeatedly
     *      function attack() public {
     *          for(uint i = 0; i < 1000; i++) {
     *              addNumber(i); // Makes array huge!
     *          }
     *      }
     *      
     *      // Later, this becomes impossible (exceeds gas limit)
     *      function processAll() public {
     *          for(uint i = 0; i < numbers.length; i++) {
     *              // Process numbers[i]...
     *              // ❌ FAILS if array too large!
     *          }
     *      }
     *      ```
     *
     *      DEFENSE PATTERNS:
     *      1. Limit array size: require(numbers.length < MAX_SIZE)
     *      2. Use mappings instead (O(1) access, no iteration needed)
     *      3. Emit events, process off-chain (indexers handle the heavy lifting)
     *
     *      GAS OPTIMIZATION TIP:
     *      If you know the max size upfront, use fixed-size arrays!
     *      ```solidity
     *      uint256[10] public fixedNumbers; // Max 10 elements, cheaper!
     *      ```
     *
     *      🎓 LEARNING MOMENT:
     *      Why is push() expensive? Because it does TWO storage writes:
     *      1. Update the length counter
     *      2. Write the new element
     *      Each storage write costs ~5,000 gas (warm) or ~20,000 gas (cold)!
     */
    function addNumber(uint256 _number) public {
        // 📦 ARRAY.PUSH(): The Two-Step Dance
        // Behind the scenes, Solidity does:
        //   1. numbers.length++ (increment length counter)
        //   2. numbers[numbers.length - 1] = _number (write element)
        // 
        // This is why push() costs ~10,000 gas (warm) - two storage operations!
        // Compare to mapping assignment: only one storage write (~5,000 gas)
        numbers.push(_number); // Append to end of array
        
        // 💡 THOUGHT: Why "push" and not "append"?
        // It comes from stack data structures (push/pop operations)
        // Arrays in Solidity behave like stacks: you push to the end, pop from the end
    }

    /**
     * @notice Get the length of the numbers array
     * @return The array length
     *
     * @dev ARRAY LENGTH: A Stored Counter
     * ═══════════════════════════════════════
     *
     *      Unlike many languages, Solidity arrays store their length explicitly!
     *      This is a design choice that prioritizes gas efficiency.
     *
     *      HOW IT WORKS:
     *      ┌─────────────────────────────────┐
     *      │ Slot 5: numbers.length = 3       │ ← Stored as uint256
     *      └─────────────────────────────────┘
     *
     *      FUN FACT: In Python, len(array) calculates length by counting elements.
     *      In Solidity, .length just reads a stored value - much faster!
     *
     *      WHY STORE IT?
     *      1. O(1) access time (constant, not linear)
     *      2. No need to iterate to count elements
     *      3. Prevents out-of-bounds errors (can check before access)
     *
     *      CONNECTION TO STORAGE MODEL:
     *      Remember: length is stored in slot 5 (the array's base slot)
     *      Elements are stored starting at keccak256(5) + index
     *      This separation allows O(1) length access!
     *
     *      REAL-WORLD ANALOGY:
     *      Like a library catalog:
     *      - Python: Count books by walking through shelves (O(n))
     *      - Solidity: Check the catalog card (O(1))
     *
     *      GAS COST:
     *      - Cold read: ~2,100 gas (first access)
     *      - Warm read: ~100 gas (subsequent reads)
     *      - Free if called off-chain (view functions)
     *
     *      🎓 LEARNING MOMENT:
     *      This is why checking `if (index < numbers.length)` is safe!
     *      The length is always up-to-date because push() and pop() update it automatically.
     */
    function getNumbersLength() public view returns (uint256) {
        // 📏 LENGTH READ: Just a simple storage read!
        // This is stored in slot 5 (the array's base slot)
        // Much faster than counting elements like Python's len()
        return numbers.length; // SLOAD from slot 5: O(1) operation!
    }

    /**
     * @notice Get a number at a specific index
     * @param _index The index to query
     * @return The number at that index
     *
     * @dev ARRAY ACCESS: Bounds Checking is Your Friend
     * ═══════════════════════════════════════════════════
     *
     *      Accessing array elements requires bounds checking.
     *      Solidity does this automatically, but explicit checks are clearer!
     *
     *      HOW IT WORKS:
     *      ┌─────────────────────────────────────────┐
     *      │ 1. Check: Is _index < numbers.length?   │ ← Our explicit check
     *      │    ❌ No → REVERT with error message      │
     *      │    ✅ Yes → Continue                      │
     *      ├─────────────────────────────────────────┤
     *      │ 2. Calculate slot:                       │
     *      │    slot = keccak256(5) + _index          │
     *      ├─────────────────────────────────────────┤
     *      │ 3. Read from storage (SLOAD)             │
     *      │    Return the value                       │
     *      └─────────────────────────────────────────┘
     *
     *      FUN FACT: Solidity 0.8.0+ has automatic bounds checking!
     *      Even without our require(), accessing numbers[_index] where _index >= length
     *      would revert automatically. But explicit checks are better because:
     *      1. Clearer error messages ("Index out of bounds" vs generic panic)
     *      2. More gas-efficient (our check happens before slot calculation)
     *      3. Better developer experience
     *
     *      THE STORAGE CALCULATION:
     *      Remember: array elements are stored at keccak256(base_slot) + index
     *      For our numbers array (slot 5):
     *      - numbers[0] → slot = keccak256(5) + 0
     *      - numbers[1] → slot = keccak256(5) + 1
     *      - numbers[2] → slot = keccak256(5) + 2
     *
     *      CONNECTION TO MAPPINGS:
     *      Arrays and mappings both use keccak256 for storage calculation!
     *      - Mapping: keccak256(key, mapping_slot)
     *      - Array: keccak256(array_slot) + index
     *      The difference: arrays use sequential indices, mappings use arbitrary keys
     *
     *      LANGUAGE COMPARISON:
     *      ┌─────────────┬──────────────────────────────┐
     *      │ Language    │ Behavior on out-of-bounds    │
     *      ├─────────────┼──────────────────────────────┤
     *      │ C           │ Undefined behavior (danger!) │
     *      │ Python      │ Raises IndexError             │
     *      │ JavaScript  │ Returns undefined            │
     *      │ Solidity    │ Reverts transaction (safe!)  │
     *      └─────────────┴──────────────────────────────┘
     *
     *      REAL-WORLD ANALOGY:
     *      Like asking for book #1000 in a library with only 100 books:
     *      - C: Gives you garbage data (undefined behavior)
     *      - Python: Throws an error (IndexError)
     *      - Solidity: Stops everything, refunds gas (revert)
     *
     *      GAS COST:
     *      - require() check: ~3 gas (if passes)
     *      - Storage read: ~2,100 gas (cold) or ~100 gas (warm)
     *      TOTAL: ~2,103 gas (cold) or ~103 gas (warm)
     *
     *      🎓 LEARNING MOMENT:
     *      Why check bounds explicitly? Because it's cheaper!
     *      If we don't check and Solidity's automatic check triggers,
     *      we've already wasted gas calculating the storage slot.
     *      Our explicit check prevents that waste!
     */
    function getNumberAt(uint256 _index) public view returns (uint256) {
        // 🛡️  BOUNDS CHECK: Always validate before access!
        // This prevents reading from invalid slots (saves gas)
        // Also provides a clear error message if something goes wrong
        require(_index < numbers.length, "Index out of bounds"); // Explicit check
        
        // 📖 ARRAY ACCESS: Calculate slot and read
        // Slot calculation: keccak256(5) + _index
        // This is similar to mapping access, but with sequential indices!
        return numbers[_index]; // SLOAD from calculated slot: keccak256(5) + _index
    }

    /**
     * @notice Remove a number at a specific index from the array
     * @param _index The index of the element to remove
     *
     * @dev ARRAY REMOVAL: The Clever Swap Trick
     * ════════════════════════════════════════════
     *
     *      Removing from arrays is tricky! You have two approaches:
     *
     *      APPROACH 1: Shift Everything (Naive, Expensive)
     *      ┌─────────────────────────────────────────┐
     *      │ [10, 20, 30, 40]                       │
     *      │ Remove index 1 (value 20)              │
     *      │ ↓                                       │
     *      │ [10, 30, 40, 0]  ← Shift left         │
     *      │ Cost: O(n) - must move all elements!   │
     *      │ Gas: ~20,000+ for large arrays         │
     *      └─────────────────────────────────────────┘
     *
     *      APPROACH 2: Swap with Last (Clever, Efficient)
     *      ┌─────────────────────────────────────────┐
     *      │ [10, 20, 30, 40]                       │
     *      │ Remove index 1 (value 20)              │
     *      │ ↓                                       │
     *      │ Step 1: Swap [1] with [3]              │
     *      │ [10, 40, 30, 20]                       │
     *      │ ↓                                       │
     *      │ Step 2: Pop last element               │
     *      │ [10, 40, 30]                           │
     *      │ Cost: O(1) - constant time!           │
     *      │ Gas: ~5,000 (just swap + pop)          │
     *      └─────────────────────────────────────────┘
     *
     *      FUN FACT: This is called the "swap-and-pop" pattern!
     *      It's used in many Solidity contracts because it's gas-efficient.
     *      The trade-off: order is not preserved, but that's often fine!
     *
     *      WHY IT WORKS:
     *      Arrays don't care about order for many use cases.
     *      If you need order, you'd use a different data structure anyway.
     *
     *      CONNECTION TO STORAGE:
     *      Remember: array elements are stored at keccak256(5) + index
     *      - Swapping: Just two storage writes (cheap!)
     *      - Shifting: N storage writes (expensive!)
     *
     *      REAL-WORLD ANALOGY:
     *      Like removing a book from a library shelf:
     *      - Naive: Shift all books left (lots of work!)
     *      - Clever: Swap with last book, remove last (minimal work!)
     *
     *      GAS COMPARISON:
     *      ┌─────────────────┬──────────────┬──────────────┐
     *      │ Method          │ Time         │ Gas (10 el)  │
     *      ├─────────────────┼──────────────┼──────────────┤
     *      │ Shift all       │ O(n)         │ ~50,000      │
     *      │ Swap + pop      │ O(1)         │ ~5,000       │
     *      └─────────────────┴──────────────┴──────────────┘
     *      Savings: 90% gas reduction! 🎉
     *
     *      ⚠️  IMPORTANT CAVEAT:
     *      This changes the order! If order matters, use a different approach:
     *      - Use a mapping instead of an array
     *      - Accept the gas cost of shifting
     *      - Use a linked list (more complex but preserves order)
     *
     *      🎓 LEARNING MOMENT:
     *      This pattern shows why understanding data structures matters!
     *      Choosing the right approach can save massive amounts of gas.
     *      In blockchain development, gas = money, so efficiency is critical!
     */
    function removeNumber(uint256 _index) public {
        // 🛡️  VALIDATION: Always check bounds first!
        // This prevents accessing invalid indices
        require(_index < numbers.length, "Index out of bounds");
        
        // 📍 CALCULATE LAST INDEX:
        // If array has length 4, last index is 3 (0-indexed!)
        // This is the element we'll swap with
        uint256 lastIndex = numbers.length - 1;
        
        // 🔄 SWAP OPERATION: The Magic Trick!
        // Instead of shifting everything, we swap the element to remove
        // with the last element. This is O(1) instead of O(n)!
        //
        // Example: Remove index 1 from [10, 20, 30, 40]
        // Step 1: numbers[1] = numbers[3] → [10, 40, 30, 40]
        // Step 2: numbers.pop() → [10, 40, 30]
        // Result: Removed 20, but order changed (30 moved to index 1)
        numbers[_index] = numbers[lastIndex]; // SSTORE: ~5,000 gas (warm)
        
        // 🗑️  POP OPERATION: Remove the last element
        // This does two things:
        //   1. Decrements numbers.length (SSTORE)
        //   2. Sets last element to 0 (SSTORE, but may refund gas!)
        // Total: ~5,000 gas, but may get refund for clearing storage
        numbers.pop(); // Removes last element, updates length
    }

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // STRUCT FUNCTIONS
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    /**
     * @notice Register a user
     * @param _wallet The user's wallet address
     * @param _balance The initial balance
     *
     * @dev STRUCTS: Custom Types That Group Related Data
     * ════════════════════════════════════════════════════
     *
     *      Structs are like custom containers that group related data together.
     *      Think of them as "mini-objects" or "records" in other languages.
     *
     *      HOW STRUCTS ARE STORED IN MAPPINGS:
     *      ┌─────────────────────────────────────────────┐
     *      │ Mapping slot calculation:                   │
     *      │ base_slot = keccak256(_wallet, mapping_slot)│
     *      ├─────────────────────────────────────────────┤
     *      │ base_slot + 0: wallet (address)            │ ← 20 bytes, uses full slot
     *      │ base_slot + 1: balance (uint256)           │ ← 32 bytes
     *      │ base_slot + 2: isRegistered (bool)         │ ← 1 byte, uses full slot
     *      └─────────────────────────────────────────────┘
     *      Total: 3 storage slots per User struct
     *
     *      FUN FACT: Structs in mappings are stored sequentially!
     *      Unlike arrays where elements are at keccak256(slot) + index,
     *      struct fields are at base_slot + field_offset.
     *      This makes struct access predictable and efficient!
     *
     *      THREE WAYS TO CREATE STRUCTS:
     *      
     *      Method 1: Named Fields (Most Readable) ✅
     *      ```solidity
     *      User({wallet: _wallet, balance: _balance, isRegistered: true})
     *      ```
     *      Pros: Self-documenting, order doesn't matter
     *      Cons: More verbose
     *
     *      Method 2: Positional (Concise)
     *      ```solidity
     *      User(_wallet, _balance, true)
     *      ```
     *      Pros: Shorter
     *      Cons: Must remember field order, less readable
     *
     *      Method 3: Direct Storage Assignment (What we use!)
     *      ```solidity
     *      users[_wallet] = User({wallet: _wallet, balance: _balance, isRegistered: true});
     *      ```
     *      Pros: Direct write, no intermediate copy, gas-efficient
     *      Cons: None! This is the best approach for storage mappings
     *
     *      CONNECTION TO STORAGE MODEL:
     *      Remember how mappings calculate slots? Same here!
     *      The struct is stored starting at keccak256(_wallet, slot_6)
     *      Each field occupies sequential slots after that.
     *
     *      REAL-WORLD ANALOGY:
     *      Like a filing cabinet:
     *      - Mapping = Drawer (organized by wallet address)
     *      - Struct = Folder (contains related documents)
     *      - Fields = Documents (wallet, balance, isRegistered)
     *
     *      GAS BREAKDOWN:
     *      - Calculate mapping slot: ~100 gas (keccak256 computation)
     *      - Write wallet field: ~20,000 gas (cold) or ~5,000 gas (warm)
     *      - Write balance field: ~20,000 gas (cold) or ~5,000 gas (warm)
     *      - Write isRegistered field: ~20,000 gas (cold) or ~5,000 gas (warm)
     *      - Event emission: ~2,000 gas
     *      TOTAL: ~62,000 gas (cold) or ~17,000 gas (warm)
     *
     *      🎓 LEARNING MOMENT:
     *      Why not use memory first? Because copying to memory then to storage
     *      costs MORE gas! Direct assignment is always more efficient.
     *      Memory is for temporary data, storage is for persistent data!
     */
    function registerUser(address _wallet, uint256 _balance) public {
        // 📝 STRUCT INITIALIZATION: Named fields for clarity!
        // This creates a User struct with all fields set
        // The struct is written directly to storage - no memory copy needed!
        users[_wallet] = User({
            wallet: _wallet,           // Field 1: address (20 bytes)
            balance: _balance,         // Field 2: uint256 (32 bytes)
            isRegistered: true         // Field 3: bool (1 byte, but uses full slot)
        });
        // Behind the scenes, Solidity writes to 3 sequential storage slots:
        // slot_0 = keccak256(_wallet, 6) + 0 → wallet
        // slot_1 = keccak256(_wallet, 6) + 1 → balance
        // slot_2 = keccak256(_wallet, 6) + 2 → isRegistered

        // 📢 EVENT: Log the registration
        // Events are perfect for off-chain indexing and frontend updates
        // Notice we only emit wallet and balance - isRegistered is always true here!
        emit UserRegistered(_wallet, _balance);
    }

    /**
     * @notice Get user information
     * @param _wallet The user's wallet address
     * @return wallet address
     * @return balance amount
     * @return isRegistered status
     *
     * @dev MULTIPLE RETURN VALUES: Solidity's Superpower!
     * ════════════════════════════════════════════════════
     *
     *      Solidity functions can return MULTIPLE values - like Python tuples!
     *      This is incredibly useful and makes code cleaner.
     *
     *      HOW IT WORKS:
     *      ┌─────────────────────────────────────────┐
     *      │ Function returns 3 values:              │
     *      │   (address, uint256, bool)              │
     *      │ ↓                                        │
     *      │ Caller receives all 3 values            │
     *      │   (wallet, balance, status) = getUser()│
     *      └─────────────────────────────────────────┘
     *
     *      FUN FACT: Named returns are a Solidity feature!
     *      You can name the return values in the function signature,
     *      and then just assign to them instead of using return!
     *
     *      EXAMPLE WITH NAMED RETURNS:
     *      ```solidity
     *      function getUser(address _wallet)
     *          public view
     *          returns (address wallet, uint256 balance, bool isRegistered)
     *      {
     *          wallet = users[_wallet].wallet;  // Just assign!
     *          balance = users[_wallet].balance;
     *          isRegistered = users[_wallet].isRegistered;
     *          // No return statement needed!
     *      }
     *      ```
     *
     *      DATA LOCATION: Storage vs Memory
     *      ═══════════════════════════════════
     *
     *      When reading structs from mappings, you have two choices:
     *
     *      Option 1: Storage Reference (Cheaper, but Read-Only)
     *      ```solidity
     *      User storage user = users[_wallet];
     *      // user is a REFERENCE to storage
     *      // Can't modify (would need special syntax)
     *      ```
     *
     *      Option 2: Memory Copy (What we use!)
     *      ```solidity
     *      User memory user = users[_wallet];
     *      // user is a COPY in memory
     *      // Safe to read, can modify copy (doesn't affect storage)
     *      ```
     *
     *      WHY MEMORY HERE?
     *      1. We're returning values - memory is perfect for this
     *      2. Clear intent: we're reading, not modifying
     *      3. Slightly more gas (copying), but safer and clearer
     *
     *      CONNECTION TO EARLIER CONCEPTS:
     *      Remember storage vs memory vs calldata?
     *      - Storage: Persistent, expensive (~20k gas/write)
     *      - Memory: Temporary, cheap (~3 gas/word)
     *      - Calldata: Read-only, cheapest (no copy)
     *
     *      REAL-WORLD ANALOGY:
     *      Like photocopying a document:
     *      - Storage reference = Pointing to original (cheap, but can't modify)
     *      - Memory copy = Photocopy (costs a bit, but safe to modify)
     *
     *      GAS COST:
     *      - Read wallet: ~2,100 gas (cold) or ~100 gas (warm)
     *      - Read balance: ~2,100 gas (cold) or ~100 gas (warm)
     *      - Read isRegistered: ~2,100 gas (cold) or ~100 gas (warm)
     *      - Copy to memory: ~9 gas (3 words × 3 gas)
     *      TOTAL: ~6,309 gas (cold) or ~309 gas (warm)
     *
     *      🎓 LEARNING MOMENT:
     *      Why copy to memory? Because we're returning the values!
     *      Return values must be in memory (or calldata for external functions).
     *      This is a Solidity requirement - you can't return storage references!
     */
    function getUser(address _wallet)
        public
        view
        returns (address wallet, uint256 balance, bool isRegistered)
    {
        // 📖 READ FROM STORAGE: Copy struct to memory
        // This reads all 3 fields from storage and copies them to memory
        // Memory is needed because we're returning the values
        User memory user = users[_wallet]; // 3 SLOADs: ~300 gas (warm)
        
        // 📤 RETURN MULTIPLE VALUES: Solidity's tuple feature!
        // We can return multiple values at once - super convenient!
        // The caller can destructure: (wallet, balance, status) = getUser(addr)
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
     * @dev DATA LOCATIONS: The Three Realms of Solidity
     * ════════════════════════════════════════════════════
     *
     *      Solidity has THREE data locations, each with different properties:
     *
     *      ┌─────────────┬──────────────┬──────────────┬──────────────┐
     *      │ Location    │ Persistence  │ Cost         │ Mutability   │
     *      ├─────────────┼──────────────┼──────────────┼──────────────┤
     *      │ storage     │ Permanent    │ ~20k/write   │ Mutable      │
     *      │ memory      │ Temporary    │ ~3/word      │ Mutable      │
     *      │ calldata    │ Read-only    │ Free         │ Immutable    │
     *      └─────────────┴──────────────┴──────────────┴──────────────┘
     *
     *      MEMORY: The Temporary Workspace
     *      ═══════════════════════════════════
     *
     *      Memory is like a scratchpad - temporary and cheap!
     *      - Allocated when function is called
     *      - Erased when function exits
     *      - Perfect for calculations and return values
     *
     *      HOW MEMORY WORKS:
     *      ┌─────────────────────────────────────────┐
     *      │ Function called                          │
     *      │   ↓                                      │
     *      │ Memory allocated (grows as needed)      │
     *      │   ↓                                      │
     *      │ Function executes (uses memory)         │
     *      │   ↓                                      │
     *      │ Function returns                         │
     *      │   ↓                                      │
     *      │ Memory cleared (freed automatically)     │
     *      └─────────────────────────────────────────┘
     *
     *      FUN FACT: Memory grows linearly!
     *      Each 32-byte word costs ~3 gas to allocate.
     *      An array of 10 uint256s costs ~30 gas for memory allocation.
     *      Compare that to storage: ~200,000 gas for 10 writes!
     *
     *      CONNECTION TO STORAGE:
     *      Remember: storage is expensive (~20k gas/write)
     *      Memory is cheap (~3 gas/word)
     *      That's why we use memory for temporary calculations!
     *
     *      REAL-WORLD ANALOGY:
     *      - Storage = Filing cabinet (permanent, expensive to access)
     *      - Memory = Desk workspace (temporary, cheap, easy to use)
     *      - Calldata = Reading a letter (read-only, free)
     *
     *      WHY PURE?
     *      This function is `pure` because it:
     *      1. Doesn't read state (no SLOAD operations)
     *      2. Doesn't write state (no SSTORE operations)
     *      3. Only uses function parameters and local variables
     *
     *      PURE vs VIEW vs PAYABLE:
     *      - pure: No state access, no ETH (most restrictive)
     *      - view: Can read state, no ETH
     *      - payable: Can read/write state, can receive ETH
     *
     *      GAS BREAKDOWN:
     *      - Function call overhead: ~21,000 gas (if on-chain)
     *      - Memory allocation: ~3 gas × array length
     *      - Loop operations: ~3 gas × array length (additions)
     *      - Return: ~3 gas × return size
     *      TOTAL: ~21,000 + (6 gas × length) if on-chain
     *             FREE if called off-chain (pure functions!)
     *
     *      🎓 LEARNING MOMENT:
     *      Why use memory here? Because we're not storing anything!
     *      We're just calculating a sum and returning it.
     *      Using storage would be wasteful - we'd pay ~20k gas per write
     *      just to read it back immediately!
     */
    function sumMemoryArray(uint256[] memory _arr) public pure returns (uint256) {
        // 🧮 ACCUMULATOR PATTERN: Classic programming technique!
        // Start with 0, add each element to the running total
        uint256 sum = 0;
        
        // 🔄 LOOP THROUGH ARRAY: Process each element
        // This is a standard for-loop pattern you'll see everywhere
        // i starts at 0, increments by 1, stops when i >= length
        for (uint256 i = 0; i < _arr.length; i++) {
            // 💰 READ FROM MEMORY: Super cheap!
            // Reading from memory costs ~3 gas per 32-byte word
            // Compare to storage: ~100 gas (warm) or ~2,100 gas (cold)
            sum += _arr[i]; // Read from memory, add to accumulator
        }
        
        // 📤 RETURN RESULT: The sum of all elements
        // This returns the value to the caller
        // If called off-chain, this is FREE (no gas cost!)
        return sum;
    }

    /**
     * @notice Demonstrates calldata usage - most gas-efficient for read-only
     * @param _arr Array to process (in calldata)
     * @return The first element
     *
     * @dev CALLDATA: The Zero-Copy Champion!
     * ════════════════════════════════════════════
     *
     *      Calldata is the MOST gas-efficient data location!
     *      It's read-only data that comes directly from the transaction.
     *
     *      HOW CALLDATA WORKS:
     *      ┌─────────────────────────────────────────┐
     *      │ User sends transaction with data        │
     *      │   ↓                                      │
     *      │ Data stored in transaction calldata    │ ← Already on-chain!
     *      │   ↓                                      │
     *      │ Function reads directly from calldata   │ ← No copy needed!
     *      │   ↓                                      │
     *      │ Function returns                         │
     *      └─────────────────────────────────────────┘
     *
     *      FUN FACT: Calldata is part of the transaction itself!
     *      When you call a function, the parameters are encoded in the transaction.
     *      Calldata lets you read directly from that transaction data - zero copy!
     *
     *      THE THREE DATA LOCATIONS COMPARED:
     *      
     *      Storage (Most Expensive):
     *      - Cost: ~20,000 gas/write, ~100 gas/read (warm)
     *      - Use: Persistent state
     *      - Example: State variables
     *
     *      Memory (Medium Cost):
     *      - Cost: ~3 gas/word allocation
     *      - Use: Temporary calculations
     *      - Example: Local variables, return values
     *
     *      Calldata (Cheapest!):
     *      - Cost: ~100 gas (just reading, no allocation)
     *      - Use: Function parameters (external functions)
     *      - Example: Arrays/strings passed to external functions
     *
     *      CONNECTION TO GAS OPTIMIZATION:
     *      Remember: gas = money on Ethereum!
     *      Using calldata instead of memory can save thousands of gas.
     *      For a 100-element array:
     *      - Memory: ~300 gas (copy 100 words × 3 gas)
     *      - Calldata: ~100 gas (just read, no copy)
     *      Savings: 200 gas per call!
     *
     *      REAL-WORLD ANALOGY:
     *      - Storage = Filing cabinet (expensive to access)
     *      - Memory = Photocopying a document (costs money)
     *      - Calldata = Reading the original document (free!)
     *
     *      ⚠️  RESTRICTIONS:
     *      - Only available in EXTERNAL functions
     *      - Cannot be modified (read-only)
     *      - Cannot be used in internal/public functions
     *
     *      WHY EXTERNAL?
     *      External functions are more gas-efficient than public:
     *      - Public: Can be called internally (requires memory copy)
     *      - External: Only callable externally (can use calldata)
     *      - Trade-off: Can't call from within contract (use this.functionName())
     *
     *      GAS COMPARISON (100-element array):
     *      ┌─────────────┬──────────────┬─────────────────┐
     *      │ Location    │ Allocation  │ Read First El   │
     *      ├─────────────┼──────────────┼─────────────────┤
     *      │ calldata    │ 0 gas       │ ~100 gas        │ ← Winner!
     *      │ memory      │ ~300 gas    │ ~103 gas        │
     *      │ storage     │ N/A         │ ~100 gas        │
     *      └─────────────┴──────────────┴─────────────────┘
     *
     *      🎓 LEARNING MOMENT:
     *      Always use calldata for arrays/strings in external functions!
     *      It's the most gas-efficient option and makes your intent clear.
     *      Only use memory if you need to modify the data.
     */
    function getFirstElement(uint256[] calldata _arr) public pure returns (uint256) {
        // 🛡️  VALIDATION: Check array is not empty
        // This prevents reading from an empty array (would revert anyway, but clearer error)
        require(_arr.length > 0, "Array is empty");
        
        // 📖 READ FROM CALLDATA: Zero-copy access!
        // This reads directly from the transaction data - no memory allocation needed!
        // For a 100-element array, this saves ~300 gas compared to memory!
        return _arr[0]; // Read directly from calldata (cheapest option!)
    }

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // HELPER FUNCTIONS
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    /**
     * @notice Check if an address has a non-zero balance
     * @param _address The address to check
     * @return true if balance > 0
     *
     * @dev HELPER FUNCTIONS: Making Code More Readable
     * ════════════════════════════════════════════════════
     *
     *      Helper functions are like shortcuts - they make code cleaner and easier to understand.
     *      Instead of writing `balances[_address] > 0` everywhere, we create a helper!
     *
     *      THE MAPPING ZERO PROBLEM:
     *      ═══════════════════════════
     *
     *      Remember the "zero default" behavior we learned about?
     *      Mappings always return 0 for non-existent keys.
     *      This creates an ambiguity:
     *
     *      ┌─────────────────────────────────────────────┐
     *      │ balances[alice] = 0                        │
     *      │                                             │
     *      │ Does this mean:                            │
     *      │   A) Alice never deposited?                 │
     *      │   B) Alice deposited and withdrew all?      │
     *      │                                             │
     *      │ We can't tell! Both return 0!              │
     *      └─────────────────────────────────────────────┘
     *
     *      WHAT THIS FUNCTION DOES:
     *      This function checks if balance > 0.
     *      It's a simple check, but it's useful because:
     *      1. More readable than `balances[_address] > 0`
     *      2. Can be extended later (add more checks)
     *      3. Documents intent clearly
     *
     *      CONNECTION TO EARLIER CONCEPTS:
     *      This uses the mapping we learned about earlier!
     *      We're reading from `balances` mapping and checking the value.
     *      Simple, but demonstrates how concepts connect!
     *
     *      REAL-WORLD ANALOGY:
     *      Like checking if a bank account has money:
     *      - Balance = 0 → No money (but was it ever used?)
     *      - Balance > 0 → Definitely has money!
     *
     *      BETTER PATTERN FOR EXISTENCE:
     *      If you need to distinguish "never set" from "set to 0":
     *      ```solidity
     *      mapping(address => bool) public hasDeposited;
     *      mapping(address => uint256) public balances;
     *      
     *      function deposit() public payable {
     *          hasDeposited[msg.sender] = true;  // Mark as existing
     *          balances[msg.sender] += msg.value;
     *      }
     *      
     *      function hasBalance(address addr) public view returns (bool) {
     *          return hasDeposited[addr] && balances[addr] > 0;
     *      }
     *      ```
     *
     *      GAS COST:
     *      - Mapping read: ~2,100 gas (cold) or ~100 gas (warm)
     *      - Comparison (> 0): ~3 gas
     *      TOTAL: ~2,103 gas (cold) or ~103 gas (warm)
     *
     *      🎓 LEARNING MOMENT:
     *      Helper functions make code more maintainable!
     *      If you need to change the logic later (e.g., add minimum balance check),
     *      you only change it in one place. This is the DRY principle:
     *      Don't Repeat Yourself!
     */
    function hasBalance(address _address) public view returns (bool) {
        // 🔍 SIMPLE CHECK: Is balance greater than zero?
        // This uses the mapping we learned about earlier
        // Returns true if balance > 0, false otherwise
        // 
        // Note: This can't distinguish "never set" from "set to 0"
        // Both return false! See the comment above for better patterns.
        return balances[_address] > 0; // SLOAD + comparison: ~103 gas (warm)
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
