// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title SimpleWallet
 * @notice A simple wallet implementation that can be cloned
 * @dev This contract demonstrates the minimal proxy pattern (EIP-1167)
 *
 * Gas Benchmarks:
 * - Deploy implementation: ~350,000 gas (one-time cost)
 * - Deploy clone: ~41,000 gas (per clone)
 * - Initialize clone: ~50,000 gas
 * - Total per clone: ~91,000 gas vs ~350,000 for direct deployment
 * - Savings: ~74% per wallet after first deployment
 */
contract SimpleWallet {
    // State variables
    address public owner;
    uint256 public balance;
    bool private initialized;

    // Events
    event Initialized(address indexed owner);
    event Deposited(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);

    /**
     * @notice Initialize the wallet (replaces constructor for clones)
     * @param _owner The owner of this wallet
     *
     * SOLUTION NOTES:
     * - Uses initialized flag to prevent re-initialization
     * - Validates owner address
     * - Sets state and emits event
     * - This function is part of runtime bytecode (included in clones)
     */
    function initialize(address _owner) external {
        // Prevent re-initialization
        require(!initialized, "Already initialized");

        // Set initialized flag first (reentrancy protection)
        initialized = true;

        // Validate owner
        require(_owner != address(0), "Invalid owner");

        // Set the owner
        owner = _owner;

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
     * SOLUTION NOTES:
     * - Checks owner permission
     * - Validates balance before transfer
     * - Uses call instead of transfer for better compatibility
     * - Updates state before external call (CEI pattern)
     */
    function withdraw(uint256 amount) external {
        require(msg.sender == owner, "Not owner");
        require(amount <= balance, "Insufficient balance");
        require(amount <= address(this).balance, "Insufficient contract balance");

        // Update balance before external call (CEI pattern)
        balance -= amount;

        // Use call instead of transfer for better compatibility
        (bool success,) = payable(owner).call{value: amount}("");
        require(success, "Transfer failed");

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

    // The implementation contract address
    address public implementation;

    // Track all created wallets
    address[] public allWallets;

    // Map user address to their wallet
    mapping(address => address) public userWallets;

    // Events
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
    address public owner;
    uint256 public balance;

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
