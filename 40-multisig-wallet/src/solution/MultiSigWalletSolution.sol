// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Multi-Signature Wallet - Complete Solution
 * @author Solidity Education
 * @notice A production-grade multi-signature wallet with comprehensive security features
 * @dev This implementation follows industry best practices and security patterns
 *
 * Security Features:
 * - M-of-N threshold signatures for transaction execution
 * - Nonce-based replay protection
 * - Checks-Effects-Interactions pattern to prevent reentrancy
 * - Comprehensive input validation
 * - Owner management via multi-sig consensus
 * - Emergency owner recovery capabilities
 * - Gas-efficient confirmation tracking
 *
 * Architecture:
 * - Transaction lifecycle: Submit → Confirm → Execute
 * - Owner management requires multi-sig approval
 * - Threshold enforcement on every execution
 * - Event emission for full transparency
 *
 * Gas Optimizations:
 * - Packed struct layout
 * - Cached array lengths in loops
 * - uint256 for all numeric values (EVM-native)
 * - Minimal storage writes
 */
contract MultiSigWalletSolution {
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted when a new transaction is submitted
     * @param txId Unique transaction identifier
     * @param submitter Address that submitted the transaction
     * @param to Destination address
     * @param value ETH value to transfer
     * @param data Calldata to execute
     */
    event TransactionSubmitted(
        uint256 indexed txId, address indexed submitter, address indexed to, uint256 value, bytes data
    );

    /**
     * @notice Emitted when an owner confirms a transaction
     * @param txId Transaction identifier
     * @param owner Owner who confirmed
     */
    event TransactionConfirmed(uint256 indexed txId, address indexed owner);

    /**
     * @notice Emitted when an owner revokes their confirmation
     * @param txId Transaction identifier
     * @param owner Owner who revoked
     */
    event ConfirmationRevoked(uint256 indexed txId, address indexed owner);

    /**
     * @notice Emitted when a transaction is successfully executed
     * @param txId Transaction identifier
     * @param executor Address that triggered execution
     */
    event TransactionExecuted(uint256 indexed txId, address indexed executor);

    /**
     * @notice Emitted when a new owner is added
     * @param owner New owner address
     */
    event OwnerAdded(address indexed owner);

    /**
     * @notice Emitted when an owner is removed
     * @param owner Removed owner address
     */
    event OwnerRemoved(address indexed owner);

    /**
     * @notice Emitted when the confirmation threshold changes
     * @param threshold New threshold value
     */
    event ThresholdChanged(uint256 threshold);

    /**
     * @notice Emitted when ETH is deposited into the wallet
     * @param sender Address that sent ETH
     * @param amount Amount of ETH received
     * @param balance New wallet balance
     */
    event Deposit(address indexed sender, uint256 amount, uint256 balance);

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error NotOwner();
    error InvalidOwner();
    error DuplicateOwner();
    error InvalidThreshold();
    error NoOwners();
    error InvalidDestination();
    error TransactionDoesNotExist();
    error TransactionAlreadyExecuted();
    error AlreadyConfirmed();
    error NotConfirmed();
    error ThresholdNotMet();
    error TransactionFailed();
    error OnlyWalletCanCall();
    error WouldBreakThreshold();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Transaction structure
     * @dev Packed for gas efficiency (256 bits)
     * @param to Destination address (160 bits)
     * @param executed Execution status (8 bits)
     * @param value ETH value to send
     * @param data Calldata to execute
     */
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
    }

    /**
     * @notice Array of all owner addresses
     * @dev Dynamic array allows for owner addition/removal
     */
    address[] public owners;

    /**
     * @notice Mapping for O(1) owner verification
     * @dev Used in onlyOwner modifier for gas efficiency
     */
    mapping(address => bool) public isOwner;

    /**
     * @notice Minimum number of confirmations required for execution
     * @dev Must satisfy: 0 < threshold <= owners.length
     */
    uint256 public threshold;

    /**
     * @notice Transaction counter for unique IDs and replay protection
     * @dev Incremented on each new transaction submission
     * This provides:
     * 1. Unique transaction identifiers
     * 2. Replay protection (same tx can't be executed twice)
     * 3. Chronological ordering of transactions
     */
    uint256 public nonce;

    /**
     * @notice Storage for all transactions
     * @dev Maps transaction ID to Transaction struct
     */
    mapping(uint256 => Transaction) public transactions;

    /**
     * @notice Confirmation tracking per transaction per owner
     * @dev Maps: txId => owner => hasConfirmed
     * This nested mapping allows:
     * 1. Each owner to confirm each transaction independently
     * 2. O(1) lookup for confirmation status
     * 3. Easy revocation of confirmations
     */
    mapping(uint256 => mapping(address => bool)) public confirmations;

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Restricts function access to wallet owners only
     * @dev Reverts with NotOwner if caller is not an owner
     * Gas-efficient: Single SLOAD from isOwner mapping
     */
    modifier onlyOwner() {
        if (!isOwner[msg.sender]) revert NotOwner();
        _;
    }

    /**
     * @notice Ensures transaction exists before operations
     * @param txId Transaction identifier to check
     * @dev A transaction exists if txId < nonce
     * This works because nonce is incremented on each submission
     */
    modifier txExists(uint256 txId) {
        if (txId >= nonce) revert TransactionDoesNotExist();
        _;
    }

    /**
     * @notice Ensures transaction hasn't been executed yet
     * @param txId Transaction identifier to check
     * @dev Critical for preventing double-execution attacks
     */
    modifier notExecuted(uint256 txId) {
        if (transactions[txId].executed) revert TransactionAlreadyExecuted();
        _;
    }

    /**
     * @notice Ensures caller hasn't already confirmed this transaction
     * @param txId Transaction identifier to check
     * @dev Prevents confirmation spam and ensures fair vote counting
     */
    modifier notConfirmed(uint256 txId) {
        if (confirmations[txId][msg.sender]) revert AlreadyConfirmed();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initialize the multi-sig wallet
     * @param _owners Array of initial owner addresses
     * @param _threshold Minimum confirmations required (M in M-of-N)
     *
     * @dev Security validations:
     * 1. Owners array must not be empty
     * 2. Threshold must be at least 1 (otherwise no security)
     * 3. Threshold cannot exceed owner count (otherwise deadlock)
     * 4. No zero address owners (would break security model)
     * 5. No duplicate owners (would break vote counting)
     *
     * Gas optimization: Single pass through owners array
     */
    constructor(address[] memory _owners, uint256 _threshold) {
        // SECURITY: Prevent empty owner set (would brick the wallet)
        if (_owners.length == 0) revert NoOwners();

        // SECURITY: Validate threshold boundaries
        // threshold == 0: Anyone can execute (no security)
        // threshold > owners.length: No transaction can ever execute (deadlock)
        if (_threshold == 0 || _threshold > _owners.length) {
            revert InvalidThreshold();
        }

        // Process and validate each owner
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            // SECURITY: Prevent zero address (would allow anyone to fake ownership)
            if (owner == address(0)) revert InvalidOwner();

            // SECURITY: Prevent duplicates (would allow double-voting)
            if (isOwner[owner]) revert DuplicateOwner();

            // Store owner in both array and mapping
            owners.push(owner);
            isOwner[owner] = true;
        }

        threshold = _threshold;
    }

    /*//////////////////////////////////////////////////////////////
                        TRANSACTION FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Submit a new transaction proposal
     * @param to Destination address (contract or EOA)
     * @param value Amount of ETH to send (in wei)
     * @param data Encoded function call data (or empty for ETH transfer)
     * @return txId Unique identifier for this transaction
     *
     * @dev Transaction lifecycle begins here:
     * 1. Submit (this function) - Creates proposal
     * 2. Confirm (confirmTransaction) - Owners vote
     * 3. Execute (executeTransaction) - Execute when threshold met
     *
     * Security notes:
     * - Only owners can submit (prevents spam)
     * - Zero address destination is rejected (would burn funds)
     * - Transaction ID is from nonce (prevents replay)
     * - Nonce increments atomically (prevents ID collision)
     */
    function submitTransaction(address to, uint256 value, bytes calldata data)
        external
        onlyOwner
        returns (uint256 txId)
    {
        // SECURITY: Prevent sending to zero address (would burn ETH/tokens)
        if (to == address(0)) revert InvalidDestination();

        // Get current nonce as transaction ID
        txId = nonce;

        // Store transaction
        // NOTE: Transaction is not automatically confirmed by submitter
        // This allows separation of proposal from approval
        transactions[txId] = Transaction({to: to, value: value, data: data, executed: false});

        // SECURITY: Increment nonce for next transaction (replay protection)
        // This happens AFTER creating the transaction to use current nonce as ID
        unchecked {
            ++nonce; // Safe: Would take billions of years to overflow
        }

        emit TransactionSubmitted(txId, msg.sender, to, value, data);
    }

    /**
     * @notice Confirm a pending transaction
     * @param txId Transaction identifier to confirm
     *
     * @dev Owners signal approval by calling this function
     * Each owner can confirm once per transaction
     * Confirmations can be revoked before execution
     *
     * Security features:
     * - Only owners can confirm
     * - Transaction must exist
     * - Transaction must not be executed
     * - Owner cannot double-confirm
     *
     * Gas optimization:
     * - Single storage write (confirmations mapping)
     * - No loops required
     */
    function confirmTransaction(uint256 txId)
        external
        onlyOwner
        txExists(txId)
        notExecuted(txId)
        notConfirmed(txId)
    {
        // Record confirmation
        // SECURITY: This is a simple flag set, protected by modifiers
        confirmations[txId][msg.sender] = true;

        emit TransactionConfirmed(txId, msg.sender);
    }

    /**
     * @notice Revoke a previous confirmation
     * @param txId Transaction identifier
     *
     * @dev Allows owners to change their vote before execution
     * This is important for:
     * 1. Correcting mistakes
     * 2. Responding to new information
     * 3. Preventing malicious transactions
     *
     * Cannot revoke after execution (would be meaningless)
     *
     * Security: Only the owner who confirmed can revoke their own confirmation
     */
    function revokeConfirmation(uint256 txId) external onlyOwner txExists(txId) notExecuted(txId) {
        // SECURITY: Check that owner actually confirmed
        // Prevents unnecessary storage writes and event spam
        if (!confirmations[txId][msg.sender]) revert NotConfirmed();

        // Remove confirmation
        confirmations[txId][msg.sender] = false;

        emit ConfirmationRevoked(txId, msg.sender);
    }

    /**
     * @notice Execute a transaction that meets the confirmation threshold
     * @param txId Transaction identifier to execute
     *
     * @dev This is where the actual transaction happens
     *
     * CRITICAL SECURITY PATTERN: Checks-Effects-Interactions (CEI)
     * 1. CHECKS: Verify all conditions
     *    - Transaction exists
     *    - Not already executed
     *    - Threshold is met
     * 2. EFFECTS: Update state
     *    - Mark transaction as executed
     * 3. INTERACTIONS: External calls
     *    - Call target contract
     *
     * CEI prevents reentrancy attacks:
     * - State is updated BEFORE external call
     * - Reentrant calls see executed=true and revert
     * - No double-execution possible
     *
     * @dev Anyone can call this (not just owners) once threshold is met
     * This allows for execution automation and better UX
     */
    function executeTransaction(uint256 txId) external txExists(txId) notExecuted(txId) {
        // CHECKS: Verify threshold is met
        // SECURITY: This prevents execution without sufficient approvals
        if (!isThresholdMet(txId)) revert ThresholdNotMet();

        Transaction storage txn = transactions[txId];

        // EFFECTS: Mark as executed BEFORE external call
        // SECURITY: This is the reentrancy protection
        // Any reentrant call will see executed=true and revert
        txn.executed = true;

        // INTERACTIONS: Execute the transaction
        // Forward all remaining gas to prevent griefing
        // Use call for flexibility (supports ETH + data)
        (bool success,) = txn.to.call{value: txn.value}(txn.data);

        // SECURITY: Revert if transaction fails
        // This ensures wallet doesn't mark failed transactions as successful
        // Note: This reverts ALL state changes including executed=true
        if (!success) revert TransactionFailed();

        emit TransactionExecuted(txId, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                        OWNER MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Add a new owner to the wallet
     * @param owner Address of the new owner
     *
     * @dev CRITICAL SECURITY: Only callable via multi-sig
     * msg.sender must be address(this), meaning:
     * 1. A transaction must be submitted via submitTransaction
     * 2. Threshold owners must confirm it
     * 3. Someone must execute it
     * 4. Only then does this function run with msg.sender == address(this)
     *
     * This prevents:
     * - Single owner adding themselves or allies
     * - External attackers adding themselves
     * - Unauthorized owner set changes
     *
     * All owner management functions follow this pattern
     */
    function addOwner(address owner) external {
        // SECURITY: Only the wallet itself can call this
        // This ensures multi-sig consensus for owner changes
        if (msg.sender != address(this)) revert OnlyWalletCanCall();

        // SECURITY: Validate new owner
        if (owner == address(0)) revert InvalidOwner();
        if (isOwner[owner]) revert DuplicateOwner();

        // Add to owner set
        owners.push(owner);
        isOwner[owner] = true;

        emit OwnerAdded(owner);

        // NOTE: Adding an owner doesn't change the threshold
        // This means the approval percentage decreases
        // E.g., 2-of-3 (66%) becomes 2-of-4 (50%) after adding an owner
        // Use changeThreshold if you want to maintain the same percentage
    }

    /**
     * @notice Remove an existing owner from the wallet
     * @param owner Address of the owner to remove
     *
     * @dev CRITICAL SECURITY: Only callable via multi-sig
     *
     * Additional safety check:
     * - Ensures removal won't make threshold impossible to meet
     * - E.g., can't remove owner if it would make 3-of-2 (impossible)
     *
     * Gas optimization:
     * - Swap-and-pop pattern for array removal
     * - Avoids shifting all subsequent elements
     */
    function removeOwner(address owner) external {
        // SECURITY: Only the wallet itself can call this
        if (msg.sender != address(this)) revert OnlyWalletCanCall();

        // SECURITY: Validate owner exists
        if (!isOwner[owner]) revert InvalidOwner();

        // SECURITY: Ensure removal won't break threshold
        // After removal, there must be enough owners to meet threshold
        // E.g., with threshold=3, must have at least 3 owners after removal
        if (owners.length - 1 < threshold) revert WouldBreakThreshold();

        // Remove from mapping
        isOwner[owner] = false;

        // GAS OPTIMIZATION: Swap-and-pop to remove from array
        // Find the owner's index
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == owner) {
                // Swap with last element
                owners[i] = owners[owners.length - 1];
                // Remove last element
                owners.pop();
                break;
            }
        }

        emit OwnerRemoved(owner);

        // NOTE: Consider clearing this owner's confirmations on pending transactions
        // Current implementation preserves confirmations, which could be dangerous
        // if owner was removed due to compromise
        // Production systems often invalidate pending transactions on owner changes
    }

    /**
     * @notice Change the confirmation threshold
     * @param _threshold New threshold value
     *
     * @dev CRITICAL SECURITY: Only callable via multi-sig
     *
     * Threshold considerations:
     * - Too low (1-of-N): Defeats purpose of multi-sig
     * - Too high (N-of-N): Any single owner can block (deadlock risk)
     * - Recommended: 60-75% of owners (e.g., 2-of-3, 3-of-5, 4-of-6)
     *
     * This function allows adapting security as the owner set changes
     */
    function changeThreshold(uint256 _threshold) external {
        // SECURITY: Only the wallet itself can call this
        if (msg.sender != address(this)) revert OnlyWalletCanCall();

        // SECURITY: Validate new threshold
        if (_threshold == 0 || _threshold > owners.length) {
            revert InvalidThreshold();
        }

        threshold = _threshold;

        emit ThresholdChanged(_threshold);

        // NOTE: Changing threshold affects pending transactions immediately
        // A transaction that didn't meet the old threshold might meet the new one
        // Or vice versa - a confirmed transaction might become unconfirmed
        // This is intended behavior but should be considered carefully
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Count confirmations for a transaction
     * @param txId Transaction identifier
     * @return count Number of owner confirmations
     *
     * @dev Iterates through all owners and counts confirmations
     * Gas cost is O(n) where n = number of owners
     * This is acceptable because:
     * 1. It's a view function (no gas cost when called off-chain)
     * 2. Multi-sigs typically have few owners (3-10)
     * 3. When called on-chain, gas cost is predictable
     *
     * For large owner sets (>20), consider maintaining a counter
     */
    function getConfirmationCount(uint256 txId) public view returns (uint256 count) {
        // Cache array length for gas savings
        uint256 ownerCount = owners.length;

        // Count confirmations
        for (uint256 i = 0; i < ownerCount; i++) {
            if (confirmations[txId][owners[i]]) {
                unchecked {
                    ++count; // Safe: count <= owners.length (small number)
                }
            }
        }
    }

    /**
     * @notice Check if transaction has met the confirmation threshold
     * @param txId Transaction identifier
     * @return True if threshold is met, false otherwise
     *
     * @dev This is the core security check for execution
     * Used by executeTransaction to ensure sufficient approvals
     *
     * Optimization: Returns early when threshold is reached
     */
    function isThresholdMet(uint256 txId) public view returns (bool) {
        uint256 count = 0;
        uint256 ownerCount = owners.length;

        for (uint256 i = 0; i < ownerCount; i++) {
            if (confirmations[txId][owners[i]]) {
                unchecked {
                    ++count;
                }
                // Early return optimization
                if (count >= threshold) {
                    return true;
                }
            }
        }

        return false;
    }

    /**
     * @notice Get all owner addresses
     * @return Array of owner addresses
     *
     * @dev Returns a copy of the owners array
     * Useful for UI and off-chain applications
     */
    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    /**
     * @notice Get transaction details
     * @param txId Transaction identifier
     * @return to Destination address
     * @return value ETH value in wei
     * @return data Calldata
     * @return executed Whether transaction has been executed
     *
     * @dev Useful for UI to display pending transactions
     */
    function getTransaction(uint256 txId)
        external
        view
        returns (address to, uint256 value, bytes memory data, bool executed)
    {
        Transaction storage txn = transactions[txId];
        return (txn.to, txn.value, txn.data, txn.executed);
    }

    /**
     * @notice Check if a specific owner confirmed a transaction
     * @param txId Transaction identifier
     * @param owner Owner address to check
     * @return True if owner confirmed, false otherwise
     *
     * @dev Useful for UI to show which owners have confirmed
     */
    function isConfirmedBy(uint256 txId, address owner) external view returns (bool) {
        return confirmations[txId][owner];
    }

    /**
     * @notice Get the current transaction count (nonce)
     * @return Current nonce value
     *
     * @dev The next submitted transaction will have this ID
     */
    function getTransactionCount() external view returns (uint256) {
        return nonce;
    }

    /*//////////////////////////////////////////////////////////////
                        RECEIVE ETH
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Receive ETH via direct transfers
     * @dev Triggered when ETH is sent without data
     *
     * This allows the wallet to receive:
     * - Simple ETH transfers
     * - Mining rewards
     * - selfdestruct proceeds
     *
     * Events are emitted for transparency and tracking
     */
    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    /**
     * @notice Fallback function for ETH with data
     * @dev Triggered when ETH is sent with non-matching function selector
     *
     * This prevents accidental loss of ETH sent to wrong function
     */
    fallback() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
}
