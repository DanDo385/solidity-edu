// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title MinimalProxySolution
 * @notice EIP-1167 minimal proxy pattern - gas-efficient contract cloning
 * 
 * PURPOSE: Deploy many contracts cheaply by cloning a single implementation
 * CS CONCEPTS: Code reuse via delegatecall, template pattern, gas optimization
 * 
 * CONNECTIONS:
 * - Project 10: Uses delegatecall (like upgradeable proxies)
 * - Project 15: Low-level calls for cloning mechanism
 * - Project 16: CREATE2 for deterministic clone addresses
 * 
 * KEY: ~41k gas per clone vs ~350k for full deployment (88% savings!)
 */
contract SimpleWallet {
    // ============================================================
    // STATE VARIABLES
    // ============================================================

    address public owner;
    uint256 public balance;
    bool private initialized;

    // ============================================================
    // EVENTS
    // ============================================================

    event Initialized(address indexed owner);
    event Deposited(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);

    /**
     * @notice Initialize the wallet (replaces constructor for clones)
     * @param _owner The owner of this wallet
     *
     * GAS OPTIMIZATION: Why initialize() instead of constructor?
     * - Constructors: Execute during deployment (not in runtime bytecode)
     * - initialize(): Part of runtime bytecode (included in clones)
     * - Clones can't execute constructors, so we use initialize()
     * - Gas: ~50,000 gas (storage writes + event)
     *
     * GAS OPTIMIZATION: Why check initialized flag first?
     * - Reading initialized: 1 SLOAD = ~100 gas (warm)
     * - Prevents re-initialization attacks
     * - Sets flag before other state changes (CEI pattern)
     * - Trade-off: Extra SLOAD, but critical security check
     *
     * REAL-WORLD ANALOGY: Like setting up a new bank account - you can only
     * do it once, and you need to verify the owner before proceeding.
     */
    function initialize(address _owner) external {
        // Prevent re-initialization
        // GAS: 1 SLOAD = ~100 gas (warm), prevents expensive re-init
        require(!initialized, "Already initialized");

        // Set initialized flag first (reentrancy protection)
        // GAS: 1 SSTORE = ~5,000 gas (zero to non-zero)
        initialized = true;

        // Validate owner
        require(_owner != address(0), "Invalid owner");

        // Set the owner
        // GAS: 1 SSTORE = ~5,000 gas (zero to non-zero)
        owner = _owner;

        // GAS: Event emission = ~1,500 gas
        emit Initialized(_owner);
    }

    /**
     * @notice Deposit ETH into the wallet
     *
     * SOLUTION NOTES:
     * - Updates internal balance tracker
     * - Emits event for tracking
     * - Also accepts ETH via receive()
     */
    function deposit() external payable {
        balance += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw ETH from the wallet
     * @param amount The amount to withdraw
     *
     * GAS OPTIMIZATION: Why update balance before external call?
     * - Following Checks-Effects-Interactions (CEI) pattern
     * - Prevents reentrancy attacks
     * - Balance update: 1 SSTORE = ~5,000 gas (warm)
     * - External call: ~2,100 gas base + gas for recipient
     *
     * GAS OPTIMIZATION: Why use .call() instead of .transfer()?
     * - .transfer(): Limited to 2,300 gas, can fail on gas-stingy contracts
     * - .call(): Forwards all available gas, more flexible
     * - .call() cost: ~2,100 gas base (same as .transfer())
     * - Trade-off: More gas forwarded, but better compatibility
     *
     * GAS COST BREAKDOWN:
     * - 2 SLOADs (owner, balance): ~200 gas (warm)
     * - 1 SSTORE (balance): ~5,000 gas (warm)
     * - External call: ~2,100 gas base
     * - Event: ~1,500 gas
     * - Total: ~8,800 gas (excluding recipient gas)
     *
     * REAL-WORLD ANALOGY: Like withdrawing from an ATM - you update your
     * account balance first (state), then dispense cash (external call).
     * This prevents someone from withdrawing more than they have.
     */
    function withdraw(uint256 amount) external {
        // GAS: 1 SLOAD = ~100 gas (warm)
        require(msg.sender == owner, "Not owner");
        // GAS: 1 SLOAD = ~100 gas (warm)
        require(amount <= balance, "Insufficient balance");
        require(amount <= address(this).balance, "Insufficient contract balance");

        // Update balance before external call (CEI pattern)
        // GAS: 1 SSTORE = ~5,000 gas (warm, non-zero to non-zero)
        balance -= amount;

        // Use call instead of transfer for better compatibility
        // GAS: ~2,100 gas base + gas forwarded to recipient
        (bool success,) = payable(owner).call{value: amount}("");
        require(success, "Transfer failed");

        // GAS: Event emission = ~1,500 gas
        emit Withdrawn(owner, amount);
    }

    /**
     * @notice Get the current ETH balance of the contract
     * @return The balance in wei
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Check if this wallet is initialized
     * @return True if initialized
     */
    function isInitialized() external view returns (bool) {
        return initialized;
    }

    // ============================================================
    // RECEIVE FUNCTION
    // ============================================================

    // Allow contract to receive ETH
    receive() external payable {
        balance += msg.value;
        emit Deposited(msg.sender, msg.value);
    }
}

/**
 * @title WalletFactory
 * @notice Factory contract for creating SimpleWallet clones
 * @dev Uses OpenZeppelin's Clones library to deploy minimal proxies
 *
 * IMPLEMENTATION NOTES:
 * - Uses OpenZeppelin's battle-tested Clones library
 * - Supports both regular and deterministic clones
 * - Tracks all created wallets
 * - Prevents multiple wallets per user (in createWallet)
 *
 * GAS COMPARISON:
 * Direct Deployment (DirectWallet):
 * - Constructor execution: ~50,000 gas
 * - Bytecode storage: ~300,000 gas
 * - Total: ~350,000 gas per wallet
 *
 * Clone Deployment (via this factory):
 * - Implementation deployment: ~350,000 gas (one-time)
 * - Clone deployment: ~41,000 gas (per clone)
 * - Initialize: ~50,000 gas (per clone)
 * - Total per clone: ~91,000 gas
 *
 * Savings after 1st clone: 74% per wallet
 * Savings after 10 clones: 88% average
 * Savings after 100 clones: 98% average
 */
contract WalletFactory {
    using Clones for address;

    // ============================================================
    // STATE VARIABLES
    // ============================================================

    // The implementation contract address
    address public implementation;

    // Track all created wallets
    address[] public allWallets;

    // Map user address to their wallet
    mapping(address => address) public userWallets;

    // ============================================================
    // EVENTS
    // ============================================================

    event WalletCreated(address indexed wallet, address indexed owner, bool deterministic);
    event ImplementationUpdated(address indexed oldImpl, address indexed newImpl);

    /**
     * @notice Deploy the factory with an implementation address
     * @param _implementation Address of the SimpleWallet implementation
     *
     * SOLUTION NOTES:
     * - Validates implementation address
     * - Stores implementation for cloning
     * - Implementation must be deployed before factory
     */
    constructor(address _implementation) {
        require(_implementation != address(0), "Invalid implementation");
        require(_implementation.code.length > 0, "Implementation must be contract");
        implementation = _implementation;
    }

    /**
     * @notice Create a new wallet clone for the caller
     * @return wallet The address of the newly created wallet
     *
     * SOLUTION NOTES:
     * - Uses Clones.clone() for non-deterministic deployment
     * - Initializes clone in same transaction
     * - Prevents multiple wallets per user
     * - Tracks all wallets for enumeration
     *
     * GAS BREAKDOWN:
     * - Clones.clone(): ~41,000 gas (minimal proxy deployment)
     * - initialize(): ~50,000 gas (set owner, mark initialized)
     * - Storage updates: ~45,000 gas (userWallets, allWallets)
     * - Total: ~136,000 gas
     *
     * Compare to DirectWallet deployment: ~350,000 gas
     * Savings: 61% even with tracking overhead!
     */
    function createWallet() external returns (address wallet) {
        require(userWallets[msg.sender] == address(0), "Wallet already exists");

        // Clone the implementation (uses CREATE opcode)
        // This deploys only 45 bytes of proxy bytecode
        wallet = implementation.clone();

        // Initialize the clone with msg.sender as owner
        // This must be done in a separate call (not in constructor)
        SimpleWallet(wallet).initialize(msg.sender);

        // Track the wallet
        allWallets.push(wallet);
        userWallets[msg.sender] = wallet;

        emit WalletCreated(wallet, msg.sender, false);
    }

    /**
     * @notice Create a deterministic wallet clone
     * @param salt The salt for deterministic deployment
     * @return wallet The address of the newly created wallet
     *
     * SOLUTION NOTES:
     * - Uses Clones.cloneDeterministic() (CREATE2)
     * - Address can be predicted before deployment
     * - Useful for counterfactual instantiation
     * - Slightly more gas than regular clone (~2k more)
     *
     * USE CASES:
     * - Wallet address needed before deployment
     * - Cross-chain address consistency
     * - Receiving funds before wallet exists
     *
     * GAS: ~43,000 for clone, ~138,000 total
     */
    function createDeterministicWallet(bytes32 salt) external returns (address wallet) {
        // Clone deterministically using CREATE2
        // Address = keccak256(0xff ++ factory ++ salt ++ keccak256(init_code))
        wallet = implementation.cloneDeterministic(salt);

        // Initialize the clone
        SimpleWallet(wallet).initialize(msg.sender);

        // Track the wallet
        allWallets.push(wallet);
        // Note: Not adding to userWallets since user might create multiple with different salts

        emit WalletCreated(wallet, msg.sender, true);
    }

    /**
     * @notice Predict the address of a deterministic wallet
     * @param salt The salt that would be used for deployment
     * @return predicted The predicted wallet address
     *
     * SOLUTION NOTES:
     * - Pure function, no gas cost (view call)
     * - Uses same formula as CREATE2
     * - Address is guaranteed if salt not used yet
     *
     * FORMULA:
     * address = keccak256(0xff ++ deployer ++ salt ++ keccak256(init_code))[12:]
     */
    function predictWalletAddress(bytes32 salt) external view returns (address predicted) {
        return implementation.predictDeterministicAddress(salt);
    }

    /**
     * @notice Get the total number of wallets created
     * @return The count of all wallets
     */
    function getWalletCount() external view returns (uint256) {
        return allWallets.length;
    }

    /**
     * @notice Get wallet at specific index
     * @param index The index in the allWallets array
     * @return The wallet address
     */
    function getWalletAt(uint256 index) external view returns (address) {
        require(index < allWallets.length, "Index out of bounds");
        return allWallets[index];
    }

    /**
     * @notice Get all wallets created by this factory
     * @return Array of all wallet addresses
     */
    function getAllWallets() external view returns (address[] memory) {
        return allWallets;
    }
}

/**
 * @title DirectWallet
 * @notice A traditionally deployed wallet for gas comparison
 * @dev This is deployed normally (not cloned) to compare gas costs
 *
 * GAS COMPARISON:
 * This contract shows why clones save gas:
 *
 * DirectWallet deployment:
 * - Creation code: ~50,000 gas
 * - Runtime code: ~300,000 gas
 * - Total: ~350,000 gas
 *
 * SimpleWallet clone (after impl deployed):
 * - Minimal proxy: ~41,000 gas
 * - Initialize: ~50,000 gas
 * - Total: ~91,000 gas
 *
 * Why such savings?
 * - DirectWallet: Full bytecode stored on-chain for EACH deployment
 * - SimpleWallet clone: Only 45 bytes stored, delegates to shared implementation
 *
 * The more wallets you deploy, the more you save:
 * - 1 wallet: Similar cost (need to deploy impl)
 * - 10 wallets: ~65% savings
 * - 100 wallets: ~97% savings
 * - 1000 wallets: ~99% savings
 */
contract DirectWallet {
    // ============================================================
    // STATE VARIABLES
    // ============================================================

    address public owner;
    uint256 public balance;

    // ============================================================
    // EVENTS
    // ============================================================

    event Deposited(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);

    /**
     * @notice Deploy a new wallet with a constructor
     * @param _owner The owner of this wallet
     *
     * NOTE: Constructor increases deployment cost
     * - Constructor code is in creation bytecode
     * - Creation bytecode is NOT stored on-chain
     * - But it still costs gas to execute
     * - Runtime bytecode IS stored (expensive!)
     */
    constructor(address _owner) {
        require(_owner != address(0), "Invalid owner");
        owner = _owner;
    }

    function deposit() external payable {
        balance += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        require(msg.sender == owner, "Not owner");
        require(amount <= balance, "Insufficient balance");
        require(amount <= address(this).balance, "Insufficient contract balance");

        balance -= amount;

        (bool success,) = payable(owner).call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawn(owner, amount);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {
        balance += msg.value;
        emit Deposited(msg.sender, msg.value);
    }
}

/*
 * ADVANCED NOTES: HOW EIP-1167 WORKS
 * ===================================
 *
 * The Minimal Proxy Bytecode (45 bytes):
 *
 * 363d3d373d3d3d363d73bebebebebebebebebebebebebebebebebebebebe5af43d82803e903d91602b57fd5bf3
 *
 * Breakdown:
 * 36       CALLDATASIZE    # Get size of calldata
 * 3d       RETURNDATASIZE  # Push 0 (before any calls, returndatasize is 0)
 * 3d       RETURNDATASIZE  # Push 0 again
 * 37       CALLDATACOPY    # Copy calldata to memory [0:calldatasize]
 * 3d       RETURNDATASIZE  # Push 0
 * 3d       RETURNDATASIZE  # Push 0
 * 3d       RETURNDATASIZE  # Push 0
 * 36       CALLDATASIZE    # Get calldata size
 * 3d       RETURNDATASIZE  # Push 0
 * 73bebe...be PUSH20      # Push implementation address (20 bytes)
 * 5a       GAS             # Get remaining gas
 * f4       DELEGATECALL    # Delegate to implementation
 * 3d       RETURNDATASIZE  # Get return data size
 * 82       DUP3            # Duplicate
 * 80       DUP1            # Duplicate
 * 3e       RETURNDATACOPY  # Copy return data
 * 90       SWAP1           # Swap
 * 3d       RETURNDATASIZE  # Get size
 * 91       SWAP2           # Swap
 * 602b     PUSH1 0x2b      # Push 43 (length to jump)
 * 57       JUMPI           # Jump if delegatecall succeeded
 * fd       REVERT          # Revert if failed
 * 5b       JUMPDEST        # Jump destination
 * f3       RETURN          # Return the data
 *
 * What happens on a call to the proxy:
 * 1. Copy calldata to memory
 * 2. DELEGATECALL to implementation with copied calldata
 * 3. Copy return data from implementation
 * 4. If delegatecall succeeded: RETURN the data
 * 5. If delegatecall failed: REVERT
 *
 * Key properties:
 * - Uses DELEGATECALL (code runs in proxy's context)
 * - msg.sender is preserved (original caller)
 * - address(this) is the proxy's address
 * - Storage is the proxy's storage
 * - ETH balance is the proxy's balance
 *
 * Why it saves gas:
 * - Only 45 bytes stored per proxy
 * - Implementation code stored once, shared by all proxies
 * - For 1000 proxies of 10KB contract:
 *   * Normal: 1000 * 10KB = 10MB on-chain
 *   * EIP-1167: 10KB + (1000 * 45 bytes) = 55KB on-chain
 *   * Savings: 99.45%!
 *
 * Security considerations:
 * - Implementation must not selfdestruct
 * - Implementation must not use constructor state
 * - Proxies must use initialize pattern
 * - Initialize must be protected against re-initialization
 */

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. MINIMAL PROXY PATTERN SAVES MASSIVE GAS
 *    ✅ Deploy implementation: ~350,000 gas (one-time)
 *    ✅ Deploy clone: ~41,000 gas (per clone)
 *    ✅ Savings: ~309,000 gas per clone (88% reduction!)
 *    ✅ Real-world: Like using templates instead of building from scratch
 *
 * 2. EIP-1167 IS ONLY 45 BYTES
 *    ✅ Minimal bytecode that delegates all calls
 *    ✅ Uses delegatecall to implementation
 *    ✅ Preserves msg.sender and msg.value
 *    ✅ All clones share same implementation code
 *
 * 3. INITIALIZATION PATTERN REPLACES CONSTRUCTOR
 *    ✅ Clones can't execute constructors
 *    ✅ Use initialize() function instead
 *    ✅ Protect against re-initialization
 *    ✅ Set initialized flag first (CEI pattern)
 *
 * 4. STORAGE LAYOUT MUST MATCH
 *    ✅ Implementation and clones share storage layout
 *    ✅ Changes to implementation affect all clones
 *    ✅ Must maintain backward compatibility
 *    ✅ Same risks as proxy patterns (Project 10)
 *
 * 5. USE CASES FOR CLONES
 *    ✅ Multiple instances of same contract (wallets, pools)
 *    ✅ Gas-efficient mass deployment
 *    ✅ Upgradeable pattern (change implementation)
 *    ✅ Counterfactual deployments (predict addresses)
 *
 * 6. OPENZEPPELIN CLONES LIBRARY
 *    ✅ Battle-tested implementation
 *    ✅ Handles edge cases
 *    ✅ Use in production instead of custom code
 *    ✅ Supports CREATE2 for deterministic addresses
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMMON MISTAKES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ❌ Using constructor in implementation (doesn't work with clones!)
 * ❌ Not protecting initialize() from re-initialization
 * ❌ Changing storage layout in implementation (breaks clones!)
 * ❌ Not checking if clone is initialized
 * ❌ Assuming clones are independent (they share implementation)
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          NEXT STEPS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * • Study OpenZeppelin Clones library
 * • Combine with CREATE2 for deterministic addresses
 * • Explore upgradeable clone patterns
 * • Move to Project 18 to learn about Chainlink oracles
 */
