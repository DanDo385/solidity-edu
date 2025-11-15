// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Multi-Signature Wallet
 * @notice A secure wallet requiring multiple approvals for transactions
 * @dev Implement a multi-sig wallet with threshold signatures
 *
 * Requirements:
 * 1. Support multiple owners with M-of-N threshold
 * 2. Allow transaction submission, confirmation, and execution
 * 3. Implement replay protection using nonces
 * 4. Support owner management (add/remove owners, change threshold)
 * 5. Emit events for all critical operations
 * 6. Follow checks-effects-interactions pattern
 *
 * Learning Objectives:
 * - Understand multi-signature security patterns
 * - Implement threshold cryptography concepts
 * - Handle complex access control
 * - Protect against replay attacks
 * - Manage transaction lifecycle
 */
contract MultiSigWallet {
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    // TODO: Add event for transaction submission
    // Should include: txId, submitter, destination, value, data

    // TODO: Add event for transaction confirmation
    // Should include: txId, owner

    // TODO: Add event for confirmation revocation
    // Should include: txId, owner

    // TODO: Add event for transaction execution
    // Should include: txId

    // TODO: Add event for owner addition
    // Should include: owner

    // TODO: Add event for owner removal
    // Should include: owner

    // TODO: Add event for threshold change
    // Should include: newThreshold

    // TODO: Add event for ETH deposit
    // Should include: sender, amount, balance

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    // TODO: Define Transaction struct
    // Should include: to, value, data, executed
    // Hint: Use bytes for data to support any function call

    // TODO: Add array of owner addresses
    // Hint: Use dynamic array to support variable owner count

    // TODO: Add mapping to check if address is owner
    // Hint: Use mapping(address => bool) for O(1) lookups

    // TODO: Add threshold (minimum confirmations required)
    // Hint: Use uint256

    // TODO: Add nonce for replay protection
    // Hint: Increments with each new transaction

    // TODO: Add mapping to store transactions
    // Hint: mapping(uint256 => Transaction)

    // TODO: Add mapping to track confirmations
    // Hint: mapping(txId => mapping(owner => bool))

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    // TODO: Implement onlyOwner modifier
    // Should revert if msg.sender is not an owner

    // TODO: Implement txExists modifier
    // Should revert if transaction doesn't exist

    // TODO: Implement notExecuted modifier
    // Should revert if transaction already executed

    // TODO: Implement notConfirmed modifier
    // Should revert if owner already confirmed this transaction

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    // TODO: Implement constructor
    // Parameters: address[] memory _owners, uint256 _threshold
    // Should:
    // 1. Validate _owners array is not empty
    // 2. Validate _threshold is valid (> 0 and <= owners.length)
    // 3. Validate no duplicate owners
    // 4. Validate no zero address owners
    // 5. Store owners in both array and mapping
    // 6. Set threshold

    /*//////////////////////////////////////////////////////////////
                        TRANSACTION FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Submit a new transaction proposal
     * @param to Destination address
     * @param value ETH value to send
     * @param data Call data
     * @return txId The ID of the created transaction
     */
    function submitTransaction(address to, uint256 value, bytes calldata data)
        external
        returns (uint256 txId)
    {
        // TODO: Implement transaction submission
        // Should:
        // 1. Check caller is owner (use modifier)
        // 2. Validate destination address (not zero address)
        // 3. Create new transaction with current nonce
        // 4. Store transaction in mapping
        // 5. Increment nonce
        // 6. Emit TransactionSubmitted event
        // 7. Return transaction ID
    }

    /**
     * @notice Confirm a pending transaction
     * @param txId Transaction ID to confirm
     */
    function confirmTransaction(uint256 txId) external {
        // TODO: Implement transaction confirmation
        // Should:
        // 1. Validate using modifiers (onlyOwner, txExists, notExecuted, notConfirmed)
        // 2. Mark transaction as confirmed by msg.sender
        // 3. Emit Confirmation event
        // Hint: Store confirmation in mapping
    }

    /**
     * @notice Revoke a previous confirmation
     * @param txId Transaction ID to revoke confirmation for
     */
    function revokeConfirmation(uint256 txId) external {
        // TODO: Implement confirmation revocation
        // Should:
        // 1. Validate using modifiers (onlyOwner, txExists, notExecuted)
        // 2. Check that msg.sender previously confirmed
        // 3. Remove confirmation
        // 4. Emit Revocation event
    }

    /**
     * @notice Execute a confirmed transaction
     * @param txId Transaction ID to execute
     */
    function executeTransaction(uint256 txId) external {
        // TODO: Implement transaction execution
        // Should:
        // 1. Validate using modifiers (txExists, notExecuted)
        // 2. Check that threshold is met (use helper function)
        // 3. Mark transaction as executed (CEI pattern!)
        // 4. Execute the transaction (call with value and data)
        // 5. Require execution success
        // 6. Emit Execution event
        // IMPORTANT: Follow Checks-Effects-Interactions pattern
    }

    /*//////////////////////////////////////////////////////////////
                        OWNER MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Add a new owner (only callable via multi-sig)
     * @param owner Address of new owner
     */
    function addOwner(address owner) external {
        // TODO: Implement owner addition
        // Should:
        // 1. Require msg.sender == address(this) (only via multi-sig)
        // 2. Validate owner address (not zero, not already owner)
        // 3. Add to owners array
        // 4. Mark as owner in mapping
        // 5. Emit OwnerAdded event
    }

    /**
     * @notice Remove an owner (only callable via multi-sig)
     * @param owner Address of owner to remove
     */
    function removeOwner(address owner) external {
        // TODO: Implement owner removal
        // Should:
        // 1. Require msg.sender == address(this) (only via multi-sig)
        // 2. Validate owner exists
        // 3. Validate removal won't break threshold
        // 4. Remove from isOwner mapping
        // 5. Remove from owners array (swap with last, then pop)
        // 6. Emit OwnerRemoved event
        // Hint: Iterate to find owner index, swap with last element, pop
    }

    /**
     * @notice Change the confirmation threshold (only callable via multi-sig)
     * @param _threshold New threshold value
     */
    function changeThreshold(uint256 _threshold) external {
        // TODO: Implement threshold change
        // Should:
        // 1. Require msg.sender == address(this) (only via multi-sig)
        // 2. Validate new threshold (> 0 and <= owners.length)
        // 3. Update threshold
        // 4. Emit ThresholdChanged event
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get confirmation count for a transaction
     * @param txId Transaction ID
     * @return count Number of confirmations
     */
    function getConfirmationCount(uint256 txId) public view returns (uint256 count) {
        // TODO: Implement confirmation counting
        // Should:
        // 1. Iterate through all owners
        // 2. Count how many have confirmed this transaction
        // 3. Return count
    }

    /**
     * @notice Check if threshold is met for a transaction
     * @param txId Transaction ID
     * @return True if threshold is met
     */
    function isThresholdMet(uint256 txId) public view returns (bool) {
        // TODO: Implement threshold check
        // Should:
        // 1. Get confirmation count
        // 2. Return true if count >= threshold
    }

    /**
     * @notice Get all owner addresses
     * @return Array of owner addresses
     */
    function getOwners() external view returns (address[] memory) {
        // TODO: Return owners array
    }

    /**
     * @notice Get transaction details
     * @param txId Transaction ID
     * @return to Destination address
     * @return value ETH value
     * @return data Call data
     * @return executed Execution status
     */
    function getTransaction(uint256 txId)
        external
        view
        returns (address to, uint256 value, bytes memory data, bool executed)
    {
        // TODO: Return transaction details
        // Hint: Access from transactions mapping
    }

    /**
     * @notice Check if an owner has confirmed a transaction
     * @param txId Transaction ID
     * @param owner Owner address
     * @return True if owner has confirmed
     */
    function isConfirmedBy(uint256 txId, address owner) external view returns (bool) {
        // TODO: Return confirmation status
        // Hint: Access from confirmations mapping
    }

    /*//////////////////////////////////////////////////////////////
                        RECEIVE ETH
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Receive ETH
     */
    receive() external payable {
        // TODO: Emit deposit event with sender, amount, and new balance
    }

    /**
     * @notice Fallback function
     */
    fallback() external payable {
        // TODO: Emit deposit event with sender, amount, and new balance
    }
}
