// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/**
 * @title Project23Solution - ERC-20 Permit (EIP-2612)
 * @notice Complete implementation of gasless token approvals using OpenZeppelin's ERC20Permit
 * @dev Production-ready permit functionality with comprehensive security measures
 *
 * IMPLEMENTATION APPROACH:
 * This solution uses OpenZeppelin's battle-tested ERC20Permit extension.
 * We also provide a custom implementation for educational purposes.
 *
 * WHY USE OPENZEPPELIN:
 * - Battle-tested and audited
 * - Handles edge cases (signature malleability, etc.)
 * - Gas optimized
 * - Standards compliant
 * - Includes EIP-5267 (EIP-712 domain)
 */
contract Project23Solution is ERC20, ERC20Permit {
    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initialize token with permit functionality
     * @dev ERC20Permit requires the token name for EIP-712 domain
     *
     * INHERITANCE CHAIN:
     * Project23Solution
     *   ├─ ERC20 (basic token functionality)
     *   └─ ERC20Permit (permit functionality)
     *        ├─ IERC20Permit (interface)
     *        ├─ EIP712 (domain separator)
     *        └─ Nonces (nonce management)
     */
    constructor() ERC20("PermitToken", "PMT") ERC20Permit("PermitToken") {
        // Mint initial supply
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }

    /*//////////////////////////////////////////////////////////////
                          UTILITY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Mint tokens (for testing)
     * @param to Recipient address
     * @param amount Amount to mint
     */
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    /**
     * @notice Burn tokens (for testing)
     * @param from Address to burn from
     * @param amount Amount to burn
     */
    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
}

/**
 * @title Project23CustomImplementation
 * @notice Custom implementation of EIP-2612 permit for educational purposes
 * @dev This shows how permit works under the hood without using OpenZeppelin's extension
 *
 * USE THIS TO LEARN:
 * - How EIP-712 domain separator is constructed
 * - How struct hashing works
 * - How signature verification works
 * - How nonces prevent replay attacks
 * - How deadlines limit signature validity
 *
 * IN PRODUCTION, USE:
 * - OpenZeppelin's ERC20Permit (shown above)
 * - It handles more edge cases and is gas optimized
 */
contract Project23CustomImplementation is ERC20 {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice EIP-712 domain separator
    /// @dev Computed once at deployment and cached
    ///      Includes: contract name, version, chainId, and address
    ///      This ensures signatures are only valid for THIS token on THIS chain
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;

    /// @notice Chain ID at deployment
    /// @dev Used to detect chain forks and recompute domain separator
    uint256 private immutable _CACHED_CHAIN_ID;

    /// @notice Contract address at deployment
    /// @dev Used for domain separator computation
    address private immutable _CACHED_THIS;

    /// @notice EIP-712 domain typehash
    /// @dev Defines the structure of the domain separator
    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /// @notice Permit typehash as defined in EIP-2612
    /// @dev Defines the structure of the permit function
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @notice Nonces for replay protection
    /// @dev Each address has an incrementing nonce
    mapping(address => uint256) private _nonces;

    /// @notice Token name for EIP-712
    string private constant _NAME = "PermitToken";

    /// @notice Token version for EIP-712
    string private constant _VERSION = "1";

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error ERC20Permit__ExpiredDeadline();
    error ERC20Permit__InvalidSignature();

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() ERC20(_NAME, "PMT") {
        // DOMAIN SEPARATOR COMPUTATION
        // ============================
        // The domain separator is a hash that uniquely identifies:
        // 1. This specific token (by name and address)
        // 2. The version of the permit implementation
        // 3. The blockchain network (by chainId)
        //
        // This prevents:
        // - Signatures from Token A working on Token B
        // - Signatures from Ethereum working on Polygon
        // - Old signatures working after upgrades

        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_THIS = address(this);
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator();

        // Mint initial supply
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }

    /*//////////////////////////////////////////////////////////////
                          PERMIT FUNCTIONALITY
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Approve tokens via signature (EIP-2612)
     * @dev Implements gasless approval using off-chain signatures
     *
     * PERMIT VS APPROVE:
     * Traditional:
     *   1. User calls approve() - costs gas
     *   2. User calls action() - costs gas
     *   Total: 2 transactions, ~111k gas
     *
     * With Permit:
     *   1. User signs permit off-chain - FREE
     *   2. Anyone calls permitAndAction() - costs gas
     *   Total: 1 transaction, ~85k gas
     *
     * GAS SAVINGS: ~26k gas (23%) + better UX
     *
     * @param owner Token owner (must sign the permit)
     * @param spender Address being approved
     * @param value Amount to approve
     * @param deadline Signature expiration timestamp
     * @param v ECDSA recovery id (27 or 28)
     * @param r First 32 bytes of signature
     * @param s Last 32 bytes of signature
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        // STEP 1: CHECK DEADLINE
        // ======================
        // Signatures should have an expiration time to:
        // - Limit the window for potential attacks
        // - Allow users to "cancel" signatures by waiting
        // - Prevent very old signatures from being used
        if (block.timestamp > deadline) {
            revert ERC20Permit__ExpiredDeadline();
        }

        // STEP 2: GET AND INCREMENT NONCE
        // ================================
        // Nonces prevent replay attacks:
        // - Each signature can only be used once
        // - Signatures must be used in order (nonce 0, then 1, then 2, etc.)
        // - Prevents: Alice signs once, Bob submits signature multiple times
        uint256 nonce = _useNonce(owner);

        // STEP 3: CREATE STRUCT HASH
        // ==========================
        // Hash the typed structured data according to EIP-712
        // Format: keccak256(abi.encode(typeHash, ...values))
        //
        // This creates a unique hash representing:
        // - The permit operation (PERMIT_TYPEHASH)
        // - The specific parameters (owner, spender, value, nonce, deadline)
        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH, // What kind of operation
                owner, // Who is approving
                spender, // Who is being approved
                value, // How much
                nonce, // Which nonce (for replay protection)
                deadline // When it expires
            )
        );

        // STEP 4: CREATE FINAL DIGEST
        // ===========================
        // Combine the struct hash with the domain separator
        // Format: keccak256("\x19\x01" ++ domainSeparator ++ structHash)
        //
        // The "\x19\x01" prefix is from EIP-191 and means:
        // "This is EIP-712 structured data, not a raw transaction"
        //
        // This final hash is what the user actually signed
        bytes32 digest = _hashTypedDataV4(structHash);

        // STEP 5: RECOVER SIGNER
        // ======================
        // Use ECDSA to recover the address that created the signature
        //
        // ecrecover works like this:
        // - Input: message hash + signature (v, r, s)
        // - Output: public key (Ethereum address)
        //
        // If the signature is valid, the recovered address will match the owner
        address signer = ecrecover(digest, v, r, s);

        // STEP 6: VALIDATE SIGNATURE
        // ==========================
        // Check that:
        // 1. ecrecover didn't fail (returns address(0) on failure)
        // 2. The recovered signer matches the claimed owner
        //
        // This proves:
        // - The owner signed this exact permit
        // - The signature is cryptographically valid
        // - The parameters haven't been tampered with
        if (signer == address(0) || signer != owner) {
            revert ERC20Permit__InvalidSignature();
        }

        // STEP 7: APPROVE
        // ===============
        // Everything checks out! Set the approval.
        // This is the same as calling approve() directly,
        // but triggered by a signature instead of a transaction.
        _approve(owner, spender, value);
    }

    /*//////////////////////////////////////////////////////////////
                          EIP-712 HELPERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get the domain separator
     * @dev Returns cached value or recomputes on chain fork
     * @return The current domain separator
     */
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        // Check if we're still on the same chain
        // If the chain forked (e.g., Ethereum Classic fork), we need a new separator
        if (block.chainid == _CACHED_CHAIN_ID && address(this) == _CACHED_THIS) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator();
        }
    }

    /**
     * @notice Build the domain separator
     * @dev Constructs EIP-712 domain separator from current state
     * @return Domain separator hash
     */
    function _buildDomainSeparator() private view returns (bytes32) {
        return keccak256(
            abi.encode(
                _TYPE_HASH,
                keccak256(bytes(_NAME)), // Token name
                keccak256(bytes(_VERSION)), // Version "1"
                block.chainid, // Current chain ID
                address(this) // This contract's address
            )
        );
    }

    /**
     * @notice Hash typed data according to EIP-712
     * @dev Combines domain separator with struct hash
     *
     * EIP-712 SIGNING FORMAT:
     * =======================
     * The final hash has this format:
     * "\x19\x01" ++ domainSeparator ++ structHash
     *
     * Where:
     * - "\x19\x01" = EIP-191 version byte for structured data
     * - domainSeparator = Unique identifier for this contract/chain
     * - structHash = Hash of the specific data being signed
     *
     * WHY THIS FORMAT:
     * - "\x19" prevents confusion with valid transactions
     * - "\x01" indicates EIP-712 structured data
     * - domainSeparator prevents cross-contract/chain replays
     * - structHash contains the actual signed data
     *
     * @param structHash Hash of the typed structured data
     * @return Final hash for signing/verification
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), structHash));
    }

    /*//////////////////////////////////////////////////////////////
                          NONCE MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get current nonce for an address
     * @dev Required by EIP-2612 - users need this to create signatures
     * @param owner Address to query
     * @return Current nonce value
     */
    function nonces(address owner) public view virtual returns (uint256) {
        return _nonces[owner];
    }

    /**
     * @notice Consume a nonce
     * @dev Increments the nonce and returns the previous value
     *
     * NONCE PATTERN:
     * ==============
     * This function:
     * 1. Reads the current nonce
     * 2. Increments it in storage
     * 3. Returns the OLD value
     *
     * Why this pattern?
     * - The returned value is used in the permit signature
     * - The incremented value prevents replay
     * - It's atomic - no race conditions
     *
     * Example:
     * - User's nonce is 5
     * - User signs permit with nonce 5
     * - permit() calls _useNonce() which returns 5 and sets nonce to 6
     * - Signature with nonce 5 is validated
     * - Next signature must use nonce 6
     *
     * @param owner Address whose nonce to use
     * @return current The nonce value before incrementing
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        // Get current value
        current = _nonces[owner];

        // Increment for next use
        // This prevents the same signature from being used twice
        _nonces[owner] = current + 1;

        // Return the old value (which was used in the signature)
    }

    /*//////////////////////////////////////////////////////////////
                          UTILITY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Mint tokens (for testing)
     */
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    /**
     * @notice Get token name (for EIP-712)
     */
    function name() public pure override returns (string memory) {
        return _NAME;
    }
}

/**
 * @title PermitHelper
 * @notice Helper contract demonstrating integrated permit usage
 * @dev Shows how protocols can integrate permit into their functions
 */
contract PermitHelper {
    /**
     * @notice Transfer tokens using permit in a single transaction
     * @dev Combines permit and transferFrom into one transaction
     *
     * TRADITIONAL FLOW:
     * 1. User calls token.approve(helper, amount)
     * 2. User calls helper.transfer(...)
     * Total: 2 transactions
     *
     * WITH PERMIT:
     * 1. User signs permit off-chain (FREE)
     * 2. Anyone calls transferWithPermit(..., signature)
     * Total: 1 transaction
     *
     * @param token ERC20 token with permit
     * @param from Token owner
     * @param to Recipient
     * @param amount Amount to transfer
     * @param deadline Permit deadline
     * @param v Signature v
     * @param r Signature r
     * @param s Signature s
     */
    function transferWithPermit(
        Project23Solution token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // Apply permit (sets approval)
        token.permit(from, address(this), amount, deadline, v, r, s);

        // Use the approval immediately
        token.transferFrom(from, to, amount);

        // Single transaction, seamless UX!
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. EIP-2612 PERMIT ENABLES GASLESS APPROVALS
 *    ✅ Users sign off-chain (no gas cost)
 *    ✅ Relayer submits permit transaction
 *    ✅ One transaction instead of two (approve + transfer)
 *    ✅ Better UX for DeFi interactions
 *
 * 2. EIP-712 PROVIDES TYPE-SAFE SIGNATURES
 *    ✅ Typed structured data (not raw bytes)
 *    ✅ Domain separator prevents cross-chain replay
 *    ✅ Human-readable in wallet UIs
 *    ✅ Standardized format
 *
 * 3. NONCES PREVENT REPLAY ATTACKS
 *    ✅ Each address has incrementing nonce
 *    ✅ Signatures must use current nonce
 *    ✅ Nonce increments after permit
 *    ✅ Ensures signatures used once, in order
 *
 * 4. DEADLINES LIMIT SIGNATURE VALIDITY
 *    ✅ Signatures expire after deadline
 *    ✅ Prevents using stale signatures
 *    ✅ Check block.timestamp <= deadline
 *    ✅ Common pattern for permits
 *
 * 5. OPENZEPPELIN ERC20PERMIT IS PRODUCTION-READY
 *    ✅ Battle-tested implementation
 *    ✅ Handles edge cases (malleability, etc.)
 *    ✅ Gas optimized
 *    ✅ Use in production instead of custom code
 *
 * 6. PERMIT ENABLES META-TRANSACTIONS
 *    ✅ Users sign permits off-chain
 *    ✅ Relayers pay gas for transactions
 *    ✅ Enables gasless token approvals
 *    ✅ Better UX for mobile wallets
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMMON MISTAKES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ❌ Not checking deadline (stale signatures!)
 * ❌ Not checking nonce (replay attacks!)
 * ❌ Wrong domain separator (cross-chain replay!)
 * ❌ Not preventing signature malleability
 * ❌ Custom implementation instead of OpenZeppelin
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          NEXT STEPS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * • Study EIP-712 in detail (Project 19)
 * • Explore meta-transaction patterns
 * • Learn about signature-based access control
 * • Move to Project 25 to learn about ERC-721A optimization
 */
