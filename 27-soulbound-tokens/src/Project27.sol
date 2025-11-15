// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SoulboundToken
 * @notice Implementation of a non-transferable NFT (Soulbound Token)
 * @dev This contract demonstrates the core concepts of SBTs:
 *      1. Non-transferability (except minting and burning)
 *      2. EIP-5192 compliance
 *      3. Revocation mechanism
 *      4. Recovery mechanism for lost wallets
 */
contract SoulboundToken is ERC721, Ownable {
    // ============================================
    // STATE VARIABLES
    // ============================================

    uint256 private _nextTokenId;

    // Track the issuer of each token for revocation rights
    mapping(uint256 => address) public issuer;

    // Recovery mechanism: tokenId => RecoveryRequest
    struct RecoveryRequest {
        address newOwner;
        uint256 requestTime;
    }
    mapping(uint256 => RecoveryRequest) public recoveryRequests;

    // Time delay for recovery to prevent abuse
    uint256 public constant RECOVERY_DELAY = 7 days;

    // ============================================
    // EVENTS
    // ============================================

    /// @notice Emitted when a token is locked (becomes soulbound)
    /// @dev Part of EIP-5192
    event Locked(uint256 tokenId);

    /// @notice Emitted when a token is unlocked
    /// @dev Part of EIP-5192 (though our tokens never unlock)
    event Unlocked(uint256 tokenId);

    /// @notice Emitted when a token is revoked by its issuer
    event Revoked(uint256 indexed tokenId, address indexed holder, address indexed issuer);

    /// @notice Emitted when recovery is initiated
    event RecoveryInitiated(
        uint256 indexed tokenId,
        address indexed currentOwner,
        address indexed newOwner,
        uint256 readyTime
    );

    /// @notice Emitted when recovery is completed
    event RecoveryCompleted(uint256 indexed tokenId, address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when recovery is cancelled
    event RecoveryCancelled(uint256 indexed tokenId);

    // ============================================
    // ERRORS
    // ============================================

    error TransferNotAllowed();
    error NotTokenOwner();
    error NotIssuer();
    error InvalidRecoveryAddress();
    error RecoveryNotReady();
    error NoRecoveryInProgress();

    // ============================================
    // CONSTRUCTOR
    // ============================================

    constructor() ERC721("Soulbound Token", "SBT") Ownable(msg.sender) {}

    // ============================================
    // MINTING FUNCTION
    // ============================================

    /**
     * @notice Mint a new soulbound token to a recipient
     * @param to The address to receive the token
     * @return tokenId The ID of the newly minted token
     *
     * TODO: Implement the minting logic
     * HINTS:
     * 1. Use _nextTokenId for the token ID and increment it
     * 2. Store the issuer (msg.sender) for this token
     * 3. Mint the token using _safeMint
     * 4. Emit the Locked event (EIP-5192)
     * 5. Return the token ID
     */
    function mint(address to) external returns (uint256) {
        // TODO: Implement minting
        // Your code here
        revert("Not implemented");
    }

    // ============================================
    // SOULBOUND FUNCTIONALITY (EIP-5192)
    // ============================================

    /**
     * @notice Check if a token is locked (soulbound)
     * @dev Part of EIP-5192 interface
     * @param tokenId The token to check
     * @return bool Always returns true for this implementation
     *
     * TODO: Implement the locked function
     * HINTS:
     * 1. All tokens in this contract are permanently locked
     * 2. First verify the token exists (use _ownerOf)
     * 3. Return true if the token exists
     */
    function locked(uint256 tokenId) external view returns (bool) {
        // TODO: Implement locked check
        // Your code here
        revert("Not implemented");
    }

    // ============================================
    // TRANSFER PREVENTION
    // ============================================

    /**
     * @notice Override _update to prevent transfers
     * @dev This is the core of soulbound functionality
     *      The _update function is called by all transfer methods in ERC721
     *
     * TODO: Implement transfer prevention
     * HINTS:
     * 1. Get the current owner using _ownerOf(tokenId)
     * 2. Allow minting (from == address(0))
     * 3. Allow burning (to == address(0))
     * 4. Block all other transfers (from != 0 && to != 0)
     * 5. For recovery, check if caller is allowed to bypass the restriction
     * 6. Call super._update() if the operation is allowed
     *
     * IMPORTANT: Think about how recovery should work with this function
     */
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal virtual override returns (address) {
        // TODO: Implement transfer prevention with recovery support
        // Your code here
        revert("Not implemented");
    }

    // ============================================
    // REVOCATION MECHANISM
    // ============================================

    /**
     * @notice Revoke (burn) a token - only callable by the original issuer
     * @param tokenId The token to revoke
     *
     * TODO: Implement revocation
     * HINTS:
     * 1. Check that msg.sender is the issuer of this token
     * 2. Store the current owner for the event
     * 3. Burn the token using _burn
     * 4. Emit the Revoked event
     * 5. Consider: Should we clean up the issuer mapping?
     */
    function revoke(uint256 tokenId) external {
        // TODO: Implement revocation
        // Your code here
        revert("Not implemented");
    }

    // ============================================
    // RECOVERY MECHANISM
    // ============================================

    /**
     * @notice Initiate recovery process to move token to a new address
     * @param tokenId The token to recover
     * @param newOwner The new address to receive the token
     *
     * TODO: Implement recovery initiation
     * HINTS:
     * 1. Verify msg.sender owns the token
     * 2. Verify newOwner is not the zero address
     * 3. Verify newOwner is different from current owner
     * 4. Create a RecoveryRequest with newOwner and current timestamp
     * 5. Store it in recoveryRequests mapping
     * 6. Emit RecoveryInitiated event with readyTime (now + RECOVERY_DELAY)
     */
    function initiateRecovery(uint256 tokenId, address newOwner) external {
        // TODO: Implement recovery initiation
        // Your code here
        revert("Not implemented");
    }

    /**
     * @notice Complete the recovery process after the delay period
     * @param tokenId The token to complete recovery for
     *
     * TODO: Implement recovery completion
     * HINTS:
     * 1. Get the recovery request from the mapping
     * 2. Verify a recovery is in progress (newOwner != address(0))
     * 3. Verify the delay period has passed
     * 4. Store the old owner and new owner for the event
     * 5. Delete the recovery request
     * 6. Transfer the token to the new owner
     *    (Note: You'll need to handle this specially in _update)
     * 7. Emit RecoveryCompleted event
     */
    function completeRecovery(uint256 tokenId) external {
        // TODO: Implement recovery completion
        // Your code here
        revert("Not implemented");
    }

    /**
     * @notice Cancel an ongoing recovery process
     * @param tokenId The token to cancel recovery for
     *
     * TODO: Implement recovery cancellation
     * HINTS:
     * 1. Verify msg.sender owns the token
     * 2. Verify a recovery is in progress
     * 3. Delete the recovery request
     * 4. Emit RecoveryCancelled event
     */
    function cancelRecovery(uint256 tokenId) external {
        // TODO: Implement recovery cancellation
        // Your code here
        revert("Not implemented");
    }

    // ============================================
    // VIEW FUNCTIONS
    // ============================================

    /**
     * @notice Get the current token ID counter
     * @return The next token ID that will be minted
     */
    function getCurrentTokenId() external view returns (uint256) {
        return _nextTokenId;
    }

    /**
     * @notice Check if a recovery is in progress for a token
     * @param tokenId The token to check
     * @return bool True if recovery is in progress
     */
    function hasRecoveryInProgress(uint256 tokenId) external view returns (bool) {
        return recoveryRequests[tokenId].newOwner != address(0);
    }

    /**
     * @notice Get recovery request details
     * @param tokenId The token to check
     * @return newOwner The address that will receive the token
     * @return requestTime When the recovery was initiated
     * @return readyTime When the recovery can be completed
     */
    function getRecoveryRequest(uint256 tokenId)
        external
        view
        returns (
            address newOwner,
            uint256 requestTime,
            uint256 readyTime
        )
    {
        RecoveryRequest memory req = recoveryRequests[tokenId];
        return (req.newOwner, req.requestTime, req.requestTime + RECOVERY_DELAY);
    }

    // ============================================
    // INTERFACE SUPPORT
    // ============================================

    /**
     * @notice Check if contract supports an interface
     * @dev Override to include EIP-5192 interface
     *
     * TODO: Add EIP-5192 support
     * HINTS:
     * 1. EIP-5192 interface ID is: 0xb45a3c0e
     * 2. Also call super.supportsInterface for ERC721 interfaces
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        // TODO: Add EIP-5192 interface support
        // interfaceId == 0xb45a3c0e for EIP-5192
        return super.supportsInterface(interfaceId);
    }
}

/**
 * LEARNING CHALLENGES:
 *
 * 1. BASIC: Implement the core soulbound functionality
 *    - Prevent transfers in _update
 *    - Implement mint function
 *    - Implement locked function
 *
 * 2. INTERMEDIATE: Add revocation
 *    - Only issuer can revoke
 *    - Proper event emission
 *    - Clean state management
 *
 * 3. ADVANCED: Implement recovery mechanism
 *    - Time-delayed recovery
 *    - Recovery cancellation
 *    - Integration with _update function
 *
 * 4. EXPERT: Consider edge cases
 *    - What if someone tries to recover to current owner?
 *    - What if token is revoked during recovery?
 *    - What if multiple recoveries are attempted?
 *    - How to make recovery tamper-proof?
 *
 * SECURITY CONSIDERATIONS:
 * - Ensure _update correctly identifies minting, burning, and recovery
 * - Verify all access controls (owner, issuer)
 * - Check for reentrancy in recovery functions
 * - Validate all address parameters
 * - Consider front-running attacks on recovery
 *
 * GAS OPTIMIZATION IDEAS:
 * - Pack RecoveryRequest struct
 * - Use custom errors (already done)
 * - Consider removing issuer mapping after revocation
 * - Batch operations for multiple tokens
 */
