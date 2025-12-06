// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title SoulboundTokenSolution
 * @notice Complete implementation of a non-transferable NFT (Soulbound Token)
 * @dev This solution demonstrates:
 *      - EIP-5192 compliance
 *      - Transfer prevention with recovery support
 *      - Issuer-based revocation
 *      - Time-delayed recovery mechanism
 *      - Comprehensive security patterns
 *
 * @author Solidity Education - Project 27
 */
contract SoulboundTokenSolution is ERC721, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    // ============================================
    // TYPE DECLARATIONS
    // ============================================

    /// @notice Recovery requests for tokens
    struct RecoveryRequest {
        address newOwner;
        uint256 requestTime;
    }

    // ============================================
    // STATE VARIABLES
    // ============================================

    // Constants
    uint256 public constant RECOVERY_DELAY = 7 days;

    /// @notice Counter for token IDs
    uint256 private _nextTokenId;

    /// @notice Track the issuer of each token (for revocation rights)
    mapping(uint256 => address) public issuer;

    mapping(uint256 => RecoveryRequest) public recoveryRequests;

    /// @notice Track tokens being recovered (for _update function)
    mapping(uint256 => bool) private _recovering;

    // ============================================
    // EVENTS (EIP-5192 + Custom)
    // ============================================

    /// @notice Emitted when a token is locked (becomes soulbound)
    /// @dev Required by EIP-5192
    event Locked(uint256 indexed tokenId);

    /// @notice Emitted when a token is unlocked
    /// @dev Required by EIP-5192 (not used in this implementation)
    event Unlocked(uint256 indexed tokenId);

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
    error TokenDoesNotExist();

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
     * @dev Process:
     *      1. Generate new token ID
     *      2. Record the issuer (msg.sender)
     *      3. Mint the token
     *      4. Emit Locked event (EIP-5192)
     */
    function mint(address to) external returns (uint256) {
        uint256 tokenId = _nextTokenId++;

        // Record the issuer for revocation rights
        issuer[tokenId] = msg.sender;

        // Mint the token
        _safeMint(to, tokenId);

        // Emit Locked event (EIP-5192)
        // The token is permanently soulbound from creation
        emit Locked(tokenId);

        return tokenId;
    }

    // ============================================
    // SOULBOUND FUNCTIONALITY (EIP-5192)
    // ============================================

    /**
     * @notice Check if a token is locked (soulbound)
     * @dev Required by EIP-5192
     * @param tokenId The token to check
     * @return bool Always returns true (all tokens are permanently locked)
     *
     * NOTE: In more complex implementations, this could vary per token.
     * For example:
     * - Time-locked tokens (locked after certain time)
     * - Conditionally locked tokens
     * - Unlockable tokens (with special permissions)
     */
    function locked(uint256 tokenId) external view returns (bool) {
        // Verify token exists
        if (_ownerOf(tokenId) == address(0)) {
            revert TokenDoesNotExist();
        }

        // All tokens in this implementation are permanently locked
        return true;
    }

    // ============================================
    // TRANSFER PREVENTION
    // ============================================

    /**
     * @notice Override _update to prevent transfers (core soulbound mechanism)
     * @dev The _update function is called by ALL transfer methods in ERC721:
     *      - transferFrom
     *      - safeTransferFrom
     *      - approve + transferFrom
     *
     * Transfer Matrix:
     * | From      | To        | Operation | Allowed? |
     * |-----------|-----------|-----------|----------|
     * | address(0)| any       | Mint      | ✓        |
     * | any       | address(0)| Burn      | ✓        |
     * | any       | any       | Transfer  | ✗        |
     * | any       | any       | Recovery  | ✓ (flag) |
     *
     * @param to The address to transfer to
     * @param tokenId The token being transferred
     * @param auth The address authorized to perform the transfer
     * @return address The previous owner of the token
     */
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal virtual override returns (address) {
        address from = _ownerOf(tokenId);

        // Allow minting (from == address(0))
        // Allow burning (to == address(0))
        // Allow recovery (special flag set during completeRecovery)
        if (from != address(0) && to != address(0)) {
            // Check if this is a recovery transfer
            if (!_recovering[tokenId]) {
                revert TransferNotAllowed();
            }
        }

        // Proceed with the transfer
        return super._update(to, tokenId, auth);
    }

    // ============================================
    // REVOCATION MECHANISM
    // ============================================

    /**
     * @notice Revoke (burn) a token - only callable by the original issuer
     * @param tokenId The token to revoke
     *
     * @dev Use Cases:
     *      - Certification expires
     *      - Credential is invalidated
     *      - Fraudulent claim discovered
     *      - Membership terminated
     *
     * Security:
     *      - Only issuer can revoke (not contract owner)
     *      - Emits event for transparency
     *      - Cleans up state to save gas
     */
    function revoke(uint256 tokenId) external {
        // Verify caller is the issuer
        if (msg.sender != issuer[tokenId]) {
            revert NotIssuer();
        }

        // Get current owner for event
        address holder = ownerOf(tokenId);

        // Clean up any pending recovery
        if (recoveryRequests[tokenId].newOwner != address(0)) {
            delete recoveryRequests[tokenId];
        }

        // Burn the token
        _burn(tokenId);

        // Emit event for transparency
        emit Revoked(tokenId, holder, msg.sender);

        // Clean up issuer mapping to save gas on future operations
        delete issuer[tokenId];
    }

    // ============================================
    // RECOVERY MECHANISM
    // ============================================

    /**
     * @notice Initiate recovery process to move token to a new address
     * @param tokenId The token to recover
     * @param newOwner The new address to receive the token
     *
     * @dev Recovery is needed when:
     *      - Private key is lost
     *      - Wallet is compromised
     *      - Migrating to new wallet
     *
     * Security Measures:
     *      - Time delay (RECOVERY_DELAY = 7 days)
     *      - Only current owner can initiate
     *      - Transparent (emits event)
     *      - Cancellable during delay period
     *
     * Alternative Approaches:
     *      1. Social Recovery: Require approval from N guardians
     *      2. Multi-sig: Require multiple signatures
     *      3. Admin Recovery: Trusted admin can recover
     *      4. Proof-based: Require cryptographic proof of ownership
     */
    function initiateRecovery(uint256 tokenId, address newOwner) external {
        // Verify caller owns the token
        if (msg.sender != ownerOf(tokenId)) {
            revert NotTokenOwner();
        }

        // Validate new owner address
        if (newOwner == address(0)) {
            revert InvalidRecoveryAddress();
        }

        // Prevent recovery to same address (no-op)
        if (newOwner == msg.sender) {
            revert InvalidRecoveryAddress();
        }

        // Create recovery request
        recoveryRequests[tokenId] = RecoveryRequest({
            newOwner: newOwner,
            requestTime: block.timestamp
        });

        // Emit event with ready time
        emit RecoveryInitiated(
            tokenId,
            msg.sender,
            newOwner,
            block.timestamp + RECOVERY_DELAY
        );
    }

    /**
     * @notice Complete the recovery process after the delay period
     * @param tokenId The token to complete recovery for
     *
     * @dev Anyone can call this after the delay period.
     *      This is intentional - it allows the new owner to claim
     *      even if they don't have the old wallet.
     *
     * Security:
     *      - Requires delay period to pass
     *      - Verifies recovery was initiated
     *      - Uses special flag to bypass transfer restriction
     */
    function completeRecovery(uint256 tokenId) external {
        RecoveryRequest memory request = recoveryRequests[tokenId];

        // Verify recovery is in progress
        if (request.newOwner == address(0)) {
            revert NoRecoveryInProgress();
        }

        // Verify delay period has passed
        if (block.timestamp < request.requestTime + RECOVERY_DELAY) {
            revert RecoveryNotReady();
        }

        // Get current owner for event
        address oldOwner = ownerOf(tokenId);

        // Clear recovery request
        delete recoveryRequests[tokenId];

        // Set recovery flag to allow transfer in _update
        _recovering[tokenId] = true;

        // Transfer token to new owner
        _transfer(oldOwner, request.newOwner, tokenId);

        // Clear recovery flag
        _recovering[tokenId] = false;

        // Emit completion event
        emit RecoveryCompleted(tokenId, oldOwner, request.newOwner);
    }

    /**
     * @notice Cancel an ongoing recovery process
     * @param tokenId The token to cancel recovery for
     *
     * @dev Allows owner to cancel if:
     *      - Recovery was initiated by mistake
     *      - Security threat has passed
     *      - Owner regained access to wallet
     */
    function cancelRecovery(uint256 tokenId) external {
        // Verify caller owns the token
        if (msg.sender != ownerOf(tokenId)) {
            revert NotTokenOwner();
        }

        // Verify recovery is in progress
        if (recoveryRequests[tokenId].newOwner == address(0)) {
            revert NoRecoveryInProgress();
        }

        // Delete recovery request
        delete recoveryRequests[tokenId];

        // Emit cancellation event
        emit RecoveryCancelled(tokenId);
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
     * @dev Adds support for EIP-5192 (Minimal Soulbound NFTs)
     * @param interfaceId The interface identifier
     * @return bool True if interface is supported
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        // EIP-5192 interface: locked(uint256) returns (bool)
        // Interface ID: 0xb45a3c0e
        return interfaceId == 0xb45a3c0e || super.supportsInterface(interfaceId);
    }
}

// ============================================
// ALTERNATIVE IMPLEMENTATIONS
// ============================================

/**
 * @title PermanentSoulboundToken
 * @notice Simplest SBT - permanently non-transferable, no recovery
 * @dev Use for: Educational degrees, historical achievements, immutable credentials
 */
contract PermanentSoulboundToken is ERC721, Ownable {
    uint256 private _nextTokenId;

    event Locked(uint256 indexed tokenId);

    constructor() ERC721("Permanent SBT", "PSBT") Ownable(msg.sender) {}

    function mint(address to) external returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        emit Locked(tokenId);
        return tokenId;
    }

    function locked(uint256 tokenId) external view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal virtual override returns (address) {
        address from = _ownerOf(tokenId);

        // Only allow minting and burning
        if (from != address(0) && to != address(0)) {
            revert("Soulbound: Transfer not allowed");
        }

        return super._update(to, tokenId, auth);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == 0xb45a3c0e || super.supportsInterface(interfaceId);
    }
}

/**
 * @title TimeLockedSoulboundToken
 * @notice Tokens become soulbound after a lock period
 * @dev Use for: Vesting credentials, probationary memberships, commitment proofs
 */
contract TimeLockedSoulboundToken is ERC721, Ownable {
    uint256 private _nextTokenId;
    mapping(uint256 => uint256) public lockTime;
    uint256 public constant LOCK_DURATION = 30 days;

    event Locked(uint256 indexed tokenId);
    event Unlocked(uint256 indexed tokenId);

    constructor() ERC721("Time-Locked SBT", "TLSBT") Ownable(msg.sender) {}

    function mint(address to) external returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        lockTime[tokenId] = block.timestamp + LOCK_DURATION;
        _safeMint(to, tokenId);

        // Initially unlocked
        emit Unlocked(tokenId);

        return tokenId;
    }

    function locked(uint256 tokenId) public view returns (bool) {
        if (_ownerOf(tokenId) == address(0)) {
            revert("Token does not exist");
        }
        return block.timestamp >= lockTime[tokenId];
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal virtual override returns (address) {
        address from = _ownerOf(tokenId);

        // Check if token is locked
        if (from != address(0) && to != address(0) && locked(tokenId)) {
            revert("Soulbound: Token is locked");
        }

        address previousOwner = super._update(to, tokenId, auth);

        // Emit Locked event when lock time is reached
        if (to != address(0) && block.timestamp >= lockTime[tokenId]) {
            emit Locked(tokenId);
        }

        return previousOwner;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == 0xb45a3c0e || super.supportsInterface(interfaceId);
    }
}

/**
 * @title DynamicSoulboundToken
 * @notice Tokens with updatable metadata/reputation scores
 * @dev Use for: Reputation systems, evolving credentials, achievement tracking
 */
contract DynamicSoulboundToken is ERC721, Ownable {
    uint256 private _nextTokenId;

    struct TokenData {
        uint256 reputationScore;
        uint256 level;
        uint256 lastUpdate;
        bool active;
    }

    mapping(uint256 => TokenData) public tokenData;
    mapping(uint256 => address) public issuer;

    event Locked(uint256 indexed tokenId);
    event ReputationUpdated(uint256 indexed tokenId, uint256 oldScore, uint256 newScore);
    event LevelUp(uint256 indexed tokenId, uint256 newLevel);

    constructor() ERC721("Dynamic SBT", "DSBT") Ownable(msg.sender) {}

    function mint(address to) external returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        issuer[tokenId] = msg.sender;

        tokenData[tokenId] = TokenData({
            reputationScore: 0,
            level: 1,
            lastUpdate: block.timestamp,
            active: true
        });

        _safeMint(to, tokenId);
        emit Locked(tokenId);

        return tokenId;
    }

    function updateReputation(uint256 tokenId, uint256 newScore) external {
        require(msg.sender == issuer[tokenId], "Not issuer");

        uint256 oldScore = tokenData[tokenId].reputationScore;
        tokenData[tokenId].reputationScore = newScore;
        tokenData[tokenId].lastUpdate = block.timestamp;

        emit ReputationUpdated(tokenId, oldScore, newScore);

        // Auto level-up based on reputation
        uint256 newLevel = (newScore / 100) + 1;
        if (newLevel > tokenData[tokenId].level) {
            tokenData[tokenId].level = newLevel;
            emit LevelUp(tokenId, newLevel);
        }
    }

    function locked(uint256 tokenId) external view returns (bool) {
        return _ownerOf(tokenId) != address(0) && tokenData[tokenId].active;
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal virtual override returns (address) {
        address from = _ownerOf(tokenId);

        if (from != address(0) && to != address(0)) {
            revert("Soulbound: Transfer not allowed");
        }

        return super._update(to, tokenId, auth);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == 0xb45a3c0e || super.supportsInterface(interfaceId);
    }
}

/**
 * KEY IMPLEMENTATION PATTERNS:
 *
 * 1. TRANSFER PREVENTION:
 *    - Override _update (called by all transfer methods)
 *    - Check from/to addresses to identify operation type
 *    - Use flags for special cases (recovery)
 *
 * 2. REVOCATION:
 *    - Store issuer on mint
 *    - Allow issuer to burn token
 *    - Clean up state for gas savings
 *    - Emit transparent events
 *
 * 3. RECOVERY:
 *    - Two-step process (initiate + complete)
 *    - Time delay for security
 *    - Cancellable during delay
 *    - Anyone can complete (helps new wallet)
 *
 * 4. EIP-5192 COMPLIANCE:
 *    - Implement locked() view function
 *    - Emit Locked/Unlocked events
 *    - Declare interface support
 *
 * SECURITY BEST PRACTICES:
 * - Use custom errors for gas efficiency
 * - Validate all address inputs
 * - Use flags instead of try/catch for control flow
 * - Clean up state when possible
 * - Emit events for all state changes
 * - Consider reentrancy (not an issue here, but good practice)
 */

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. SOULBOUND TOKENS ARE NON-TRANSFERABLE NFTS
 *    ✅ Permanently bound to specific address
 *    ✅ Cannot be sold or transferred
 *    ✅ Represent credentials, achievements, identity
 *    ✅ Real-world: Like diplomas or certificates
 *
 * 2. EIP-5192 DEFINES THE STANDARD
 *    ✅ locked() function returns true for soulbound tokens
 *    ✅ Locked/Unlocked events
 *    ✅ Interface detection via ERC165
 *    ✅ Marketplaces can detect and prevent listing
 *
 * 3. TRANSFER PREVENTION IS CRITICAL
 *    ✅ Override transferFrom and safeTransferFrom
 *    ✅ Revert all transfer attempts
 *    ✅ Exception: Recovery mechanism (optional)
 *    ✅ Use custom errors for gas efficiency
 *
 * 4. REVOCATION ENABLES ISSUER CONTROL
 *    ✅ Issuer can revoke tokens
 *    ✅ Useful for invalidated credentials
 *    ✅ Track issuer per token
 *    ✅ Only issuer can revoke
 *
 * 5. RECOVERY PREVENTS PERMANENT LOSS
 *    ✅ Two-step process (initiate + complete)
 *    ✅ Time delay prevents abuse
 *    ✅ Cancellable during delay
 *    ✅ Helps if wallet is compromised
 *
 * 6. USE CASES FOR SOULBOUND TOKENS
 *    ✅ Educational credentials
 *    ✅ Reputation systems
 *    ✅ Achievement badges
 *    ✅ Identity attestations
 *    ✅ DAO membership proofs
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMMON MISTAKES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ❌ Not implementing EIP-5192 (marketplaces can't detect!)
 * ❌ Allowing transfers accidentally (breaks soulbound property!)
 * ❌ Not implementing recovery (permanent loss risk!)
 * ❌ Not tracking issuer (can't revoke!)
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          NEXT STEPS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * • Study EIP-5192 specification
 * • Explore credential systems
 * • Learn about privacy-preserving SBTs
 * • Move to Project 28 to learn about ERC-2981 royalties
 */
