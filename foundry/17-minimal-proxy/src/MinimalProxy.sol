// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title SimpleWallet
 * @notice A simple wallet implementation that can be cloned
 * @dev This contract demonstrates the minimal proxy pattern (EIP-1167)
 *
 * Key Points:
 * - No constructor (clones don't execute constructors)
 * - Uses initialize() pattern instead
 * - Each clone has independent storage
 * - Implementation is immutable once deployed
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
     * TODO: Implement initialization logic
     * - Check if already initialized (prevent re-initialization)
     * - Set the owner
     * - Set initialized flag to true
     * - Emit Initialized event
     */
    function initialize(address _owner) external {
        // TODO: Add require statement to prevent re-initialization
        // HINT: require(!initialized, "Already initialized");

        // TODO: Set the initialized flag

        // TODO: Validate and set the owner
        // HINT: Check that _owner is not address(0)

        // TODO: Emit the Initialized event
    }

    /**
     * @notice Deposit ETH into the wallet
     *
     * TODO: Implement deposit logic
     * - Update the balance
     * - Emit Deposited event
     */
    function deposit() external payable {
        // TODO: Update balance (track deposits)

        // TODO: Emit Deposited event
    }

    /**
     * @notice Withdraw ETH from the wallet
     * @param amount The amount to withdraw
     *
     * TODO: Implement withdrawal logic
     * - Check that caller is owner
     * - Check sufficient balance
     * - Update balance
     * - Transfer ETH
     * - Emit Withdrawn event
     */
    function withdraw(uint256 amount) external {
        // TODO: Require that msg.sender is the owner

        // TODO: Require that balance is sufficient
        // HINT: Check both this.balance and contract balance

        // TODO: Update the balance

        // TODO: Transfer ETH to owner
        // HINT: Use call instead of transfer for better compatibility

        // TODO: Emit Withdrawn event
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
 * Gas Comparison:
 * - Deploying SimpleWallet directly: ~350,000 gas
 * - Cloning SimpleWallet: ~41,000 gas
 * - Savings: ~88% reduction!
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
     * TODO: Implement constructor
     * - Validate implementation address
     * - Set the implementation
     */
    constructor(address _implementation) {
        // TODO: Require valid implementation address
        // HINT: Check that it's not address(0)

        // TODO: Set the implementation address
    }

    /**
     * @notice Create a new wallet clone for the caller
     * @return wallet The address of the newly created wallet
     *
     * TODO: Implement wallet creation
     * - Check user doesn't already have a wallet
     * - Clone the implementation
     * - Initialize the clone
     * - Track the wallet
     * - Emit event
     */
    function createWallet() external returns (address wallet) {
        // TODO: Require that user doesn't already have a wallet
        // HINT: Check userWallets[msg.sender]

        // TODO: Clone the implementation contract
        // HINT: Use Clones.clone(implementation)

        // TODO: Initialize the clone with msg.sender as owner
        // HINT: Call initialize on the cloned contract

        // TODO: Store the wallet address
        // - Add to allWallets array
        // - Add to userWallets mapping

        // TODO: Emit WalletCreated event

        // TODO: Return the wallet address
    }

    /**
     * @notice Create a deterministic wallet clone
     * @param salt The salt for deterministic deployment
     * @return wallet The address of the newly created wallet
     *
     * TODO: Implement deterministic wallet creation
     * - Clone using CREATE2 (deterministic)
     * - Initialize the clone
     * - Track the wallet
     * - Emit event
     *
     * BONUS: This allows predicting the wallet address before deployment!
     */
    function createDeterministicWallet(bytes32 salt) external returns (address wallet) {
        // TODO: Clone the implementation deterministically
        // HINT: Use Clones.cloneDeterministic(implementation, salt)

        // TODO: Initialize the clone

        // TODO: Store the wallet address

        // TODO: Emit WalletCreated event with deterministic=true

        // TODO: Return the wallet address
    }

    /**
     * @notice Predict the address of a deterministic wallet
     * @param salt The salt that would be used for deployment
     * @return predicted The predicted wallet address
     *
     * TODO: Implement address prediction
     * - Use Clones.predictDeterministicAddress
     */
    function predictWalletAddress(bytes32 salt) external view returns (address predicted) {
        // TODO: Return the predicted address
        // HINT: Use Clones.predictDeterministicAddress(implementation, salt)
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
     * NOTE: This uses a constructor, which means:
     * - Higher deployment gas cost
     * - Owner set immediately on deployment
     * - Cannot be used with cloning
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
 * LEARNING NOTES
 * ==============
 *
 * 1. Why No Constructor in SimpleWallet?
 *    - Clones only copy runtime bytecode
 *    - Constructors are part of creation bytecode
 *    - Must use initialize() pattern instead
 *
 * 2. Initialize vs Constructor
 *    Constructor:
 *    - Runs once during deployment
 *    - Cannot be called again
 *    - Part of creation bytecode
 *
 *    Initialize:
 *    - Runs after deployment
 *    - Must be protected against re-initialization
 *    - Part of runtime bytecode (included in clones)
 *
 * 3. Gas Savings Breakdown
 *    New DirectWallet deployment:
 *    - Creation code: ~50,000 gas
 *    - Runtime code storage: ~300,000 gas
 *    - Total: ~350,000 gas
 *
 *    Clone SimpleWallet:
 *    - Minimal proxy creation: ~40,000 gas
 *    - No runtime code storage (uses implementation)
 *    - Total: ~41,000 gas
 *
 *    Savings: 88% reduction!
 *
 * 4. When to Use Clones
 *    Good for:
 *    - Multiple instances of same contract
 *    - User-specific contracts (wallets, vaults)
 *    - Per-transaction contracts (escrows)
 *
 *    Not good for:
 *    - Single instance contracts
 *    - Upgradeable proxies (use UUPS/Transparent)
 *    - Contracts with complex initialization
 *
 * 5. Storage Independence
 *    - Each clone has its own storage
 *    - Clones don't share state
 *    - Implementation contract's storage is never used
 *    - Each clone can have different owner, balance, etc.
 *
 * 6. Deterministic vs Regular Clones
 *    Regular (CREATE):
 *    - Address depends on factory address and nonce
 *    - Cannot predict address beforehand
 *    - Slightly cheaper (~41k gas)
 *
 *    Deterministic (CREATE2):
 *    - Address depends on factory, salt, and bytecode
 *    - Can predict address before deployment
 *    - Slightly more expensive (~43k gas)
 *    - Useful for counterfactual instantiation
 */
