// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Project19Solution - Signed Messages & EIP-712
 * @notice Complete implementation of EIP-712 typed structured data signing
 * @dev Production-ready signature verification with comprehensive security measures
 *
 * IMPLEMENTATION DETAILS:
 * - Full EIP-712 compliance with domain separation
 * - ECDSA signature verification using ecrecover
 * - Nonce-based replay protection
 * - Deadline-based signature expiration
 * - Signature malleability prevention
 * - Support for permits, meta-transactions, and vouchers
 */
contract Project19Solution {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice EIP-712 domain separator - uniquely identifies this contract
    /// @dev Computed once in constructor and stored as immutable
    ///      Includes: contract name, version, chainId, and address
    ///      This ensures signatures are only valid for THIS contract on THIS chain
    bytes32 public immutable DOMAIN_SEPARATOR;

    /// @notice Type hash for the EIP-712 domain structure
    /// @dev This is the keccak256 hash of the domain type string
    ///      Format: "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    bytes32 public constant EIP712_DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /// @notice Type hash for permit operations (EIP-2612 style)
    /// @dev Defines the structure for gasless approvals
    ///      Fields: owner, spender, value, nonce, deadline
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @notice Type hash for meta-transactions
    /// @dev Defines the structure for gasless transfers
    ///      Fields: from, to, amount, nonce, deadline
    bytes32 public constant METATX_TYPEHASH =
        keccak256("MetaTx(address from,address to,uint256 amount,uint256 nonce,uint256 deadline)");

    /// @notice Nonce tracking for replay protection
    /// @dev Each address has an incrementing nonce
    ///      Signatures must use the current nonce and increment it
    ///      This ensures each signature can only be used once, in order
    mapping(address => uint256) public nonces;

    /// @notice Track used voucher signatures
    /// @dev Maps voucher hash to used status
    ///      Prevents vouchers from being claimed multiple times
    mapping(bytes32 => bool) public usedVouchers;

    /// @notice Simple balance tracking for demonstration
    /// @dev In production, this might be ERC20 balances
    mapping(address => uint256) public balances;

    /// @notice Allowances for permit functionality
    /// @dev owner => spender => amount
    mapping(address => mapping(address => uint256)) public allowances;

    /// @notice Authorized voucher issuer
    /// @dev Only this address can sign valid vouchers
    address public immutable voucherIssuer;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event MetaTxExecuted(address indexed from, address indexed to, uint256 amount);
    event VoucherClaimed(address indexed claimer, uint256 amount, bytes32 voucherHash);

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidSignature();
    error SignatureExpired();
    error InvalidNonce();
    error VoucherAlreadyUsed();
    error InsufficientBalance();
    error ZeroAddress();
    error InvalidSParameter();

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initialize the contract with EIP-712 domain separator
     * @dev Computes and stores the domain separator as immutable
     */
    constructor() {
        // DOMAIN SEPARATOR COMPUTATION
        // ============================
        // The domain separator uniquely identifies:
        // 1. This specific contract (by name and address)
        // 2. The version of the signing schema
        // 3. The blockchain (by chainId)
        //
        // This prevents:
        // - Signatures from being used on different contracts
        // - Signatures from being replayed on different chains (e.g., mainnet vs testnet)
        // - Version conflicts if the signing schema changes

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes("Project19")), // Contract name
                keccak256(bytes("1")),          // Version
                block.chainid,                  // Chain ID (prevents cross-chain replay)
                address(this)                   // Contract address (prevents cross-contract replay)
            )
        );

        // Set deployer as voucher issuer for demonstration
        voucherIssuer = msg.sender;
    }

    /*//////////////////////////////////////////////////////////////
                            CORE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Approve spender via signature (EIP-2612 style permit)
     * @dev Implements gasless approvals using off-chain signatures
     *
     * HOW IT WORKS:
     * 1. User signs permit off-chain (no gas cost)
     * 2. Anyone can submit the signature on-chain
     * 3. Contract verifies signature and sets approval
     * 4. User's nonce is incremented to prevent replay
     *
     * BENEFITS:
     * - No approval transaction needed from user
     * - Saves gas for users
     * - Enables one-transaction flows (approve + action)
     *
     * @param owner Address of token owner
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
    ) external {
        // STEP 1: Check deadline
        // Signatures can have expiration times to limit their validity window
        if (block.timestamp > deadline) revert SignatureExpired();

        // STEP 2: Get current nonce
        // Each user has an incrementing nonce to prevent replay attacks
        uint256 nonce = nonces[owner];

        // STEP 3: Create struct hash
        // This hashes the typed structured data according to EIP-712
        bytes32 structHash = _hashPermit(owner, spender, value, nonce, deadline);

        // STEP 4: Create final digest
        // Combines domain separator with struct hash using EIP-712 format
        bytes32 digest = _toTypedDataHash(structHash);

        // STEP 5: Recover signer from signature
        // Uses ECDSA to recover the address that signed the digest
        address signer = _recoverSigner(digest, v, r, s);

        // STEP 6: Verify signer is the owner
        // The signature must come from the token owner
        if (signer != owner) revert InvalidSignature();

        // STEP 7: Increment nonce
        // IMPORTANT: Increment BEFORE any external calls (reentrancy protection)
        // This ensures the signature can never be replayed
        nonces[owner] = nonce + 1;

        // STEP 8: Set approval
        allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @notice Execute a meta-transaction on behalf of a user
     * @dev Enables gasless transactions where relayer pays gas
     *
     * META-TRANSACTION FLOW:
     * 1. User signs transaction data off-chain
     * 2. Relayer submits signature + data on-chain (pays gas)
     * 3. Contract verifies signature
     * 4. Contract executes transaction on behalf of user
     * 5. Relayer can charge user in tokens or get compensated separately
     *
     * USE CASES:
     * - Onboarding users without ETH for gas
     * - Paying gas in stablecoins instead of ETH
     * - Batch transactions from multiple users
     *
     * @param from Address initiating the transaction
     * @param to Recipient address
     * @param amount Amount to transfer
     * @param deadline Signature expiration timestamp
     * @param v ECDSA recovery id
     * @param r ECDSA signature parameter
     * @param s ECDSA signature parameter
     */
    function executeMetaTx(
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // Validate inputs
        if (to == address(0)) revert ZeroAddress();
        if (block.timestamp > deadline) revert SignatureExpired();

        // Get current nonce for replay protection
        uint256 nonce = nonces[from];

        // Create typed structured data hash
        bytes32 structHash = _hashMetaTx(from, to, amount, nonce, deadline);

        // Create EIP-712 compliant digest
        bytes32 digest = _toTypedDataHash(structHash);

        // Recover and verify signer
        address signer = _recoverSigner(digest, v, r, s);
        if (signer != from) revert InvalidSignature();

        // CRITICAL: Increment nonce BEFORE executing transfer
        // This prevents reentrancy attacks where the transfer could
        // call back into this function with the same signature
        nonces[from] = nonce + 1;

        // Execute the transfer
        if (balances[from] < amount) revert InsufficientBalance();
        balances[from] -= amount;
        balances[to] += amount;

        emit MetaTxExecuted(from, to, amount);
        emit Transfer(from, to, amount);
    }

    /**
     * @notice Claim a voucher using an admin signature
     * @dev One-time use vouchers for airdrops, promotions, etc.
     *
     * VOUCHER SYSTEM:
     * - Admin signs vouchers off-chain
     * - Users claim on-chain with signature
     * - Each voucher can only be used once
     * - No nonce required (uses signature hash tracking)
     *
     * DIFFERENCES FROM META-TX:
     * - Uses signature hash instead of nonce (unordered)
     * - Signer is admin, not claimer
     * - One-time use, not sequential
     *
     * @param claimer Address claiming the voucher
     * @param amount Amount to credit
     * @param deadline Signature expiration timestamp
     * @param v ECDSA recovery id
     * @param r ECDSA signature parameter
     * @param s ECDSA signature parameter
     */
    function claimVoucher(
        address claimer,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (claimer == address(0)) revert ZeroAddress();
        if (block.timestamp > deadline) revert SignatureExpired();

        // Create struct hash (reuse MetaTx type for simplicity)
        // In production, you might define a specific VOUCHER_TYPEHASH
        bytes32 structHash = keccak256(
            abi.encode(
                METATX_TYPEHASH,
                voucherIssuer, // from = issuer
                claimer,       // to = claimer
                amount,
                uint256(0),    // nonce not used for vouchers
                deadline
            )
        );

        // Create digest
        bytes32 digest = _toTypedDataHash(structHash);

        // Check if voucher already used
        // Use digest as unique identifier for this voucher
        if (usedVouchers[digest]) revert VoucherAlreadyUsed();

        // Recover and verify signer
        address signer = _recoverSigner(digest, v, r, s);

        // Signer must be authorized voucher issuer
        if (signer != voucherIssuer) revert InvalidSignature();

        // Mark voucher as used
        usedVouchers[digest] = true;

        // Credit amount to claimer
        balances[claimer] += amount;

        emit VoucherClaimed(claimer, amount, digest);
    }

    /*//////////////////////////////////////////////////////////////
                          HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Create the struct hash for a permit
     * @dev Implements EIP-712 typed struct hashing
     *
     * STRUCT HASHING:
     * The struct hash is computed as:
     * keccak256(abi.encode(typeHash, value1, value2, ...))
     *
     * For Permit:
     * keccak256(abi.encode(
     *     PERMIT_TYPEHASH,
     *     owner,
     *     spender,
     *     value,
     *     nonce,
     *     deadline
     * ))
     *
     * @param owner Token owner
     * @param spender Approved spender
     * @param value Amount to approve
     * @param nonce Current nonce
     * @param deadline Expiration timestamp
     * @return Struct hash for the permit
     */
    function _hashPermit(
        address owner,
        address spender,
        uint256 value,
        uint256 nonce,
        uint256 deadline
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonce, deadline));
    }

    /**
     * @notice Create the struct hash for a meta-transaction
     * @param from Sender address
     * @param to Recipient address
     * @param amount Transfer amount
     * @param nonce Current nonce
     * @param deadline Expiration timestamp
     * @return Struct hash for the meta-transaction
     */
    function _hashMetaTx(
        address from,
        address to,
        uint256 amount,
        uint256 nonce,
        uint256 deadline
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(METATX_TYPEHASH, from, to, amount, nonce, deadline));
    }

    /**
     * @notice Create the final EIP-712 digest
     * @dev Combines domain separator with struct hash
     *
     * EIP-712 DIGEST FORMAT:
     * "\x19\x01" ++ domainSeparator ++ structHash
     *
     * The "\x19\x01" prefix is defined by EIP-191 for structured data.
     * This ensures the data being signed can't be confused with:
     * - Raw transactions (\x19\x00)
     * - Personal messages (\x19"Ethereum Signed Message:\n")
     *
     * @param structHash Hash of the typed struct data
     * @return EIP-712 compliant digest
     */
    function _toTypedDataHash(bytes32 structHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
    }

    /**
     * @notice Recover signer address from signature
     * @dev Uses ECDSA ecrecover with malleability protection
     *
     * ECDSA SIGNATURE VERIFICATION:
     * Given a message hash (digest) and signature (v, r, s),
     * ecrecover returns the public key (address) that signed it.
     *
     * SECURITY CONSIDERATIONS:
     * 1. ecrecover returns address(0) for invalid signatures
     * 2. ECDSA signatures are malleable (can create valid s' from s)
     * 3. Must validate s is in lower half of curve order
     *
     * @param digest Message hash that was signed
     * @param v Recovery id (27 or 28, sometimes 0 or 1)
     * @param r First 32 bytes of signature
     * @param s Last 32 bytes of signature
     * @return signer Address that created the signature
     */
    function _recoverSigner(
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address signer) {
        // SIGNATURE MALLEABILITY CHECK
        // ============================
        // For any valid signature (v, r, s), there exists another valid signature (v', r, s')
        // where s' = N - s (N is the curve order).
        // We prevent this by requiring s to be in the lower half of the curve.
        //
        // Maximum valid s value (secp256k1 curve order / 2):
        // 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert InvalidSParameter();
        }

        // ECRECOVER
        // =========
        // Recovers the public key (address) from the signature
        // Returns address(0) if signature is invalid
        signer = ecrecover(digest, v, r, s);

        // Must check for zero address (invalid signature)
        if (signer == address(0)) revert InvalidSignature();
    }

    /*//////////////////////////////////////////////////////////////
                          UTILITY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposit ETH to balance for testing
     */
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    /**
     * @notice Withdraw balance
     */
    function withdraw(uint256 amount) external {
        if (balances[msg.sender] < amount) revert InsufficientBalance();
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    /**
     * @notice Get current nonce for an address
     * @param account Address to query
     * @return Current nonce value
     */
    function getNonce(address account) external view returns (uint256) {
        return nonces[account];
    }

    /**
     * @notice Check if a voucher has been used
     * @param voucherHash Hash of the voucher
     * @return True if voucher has been claimed
     */
    function isVoucherUsed(bytes32 voucherHash) external view returns (bool) {
        return usedVouchers[voucherHash];
    }

    /**
     * @notice Get the domain separator
     * @return The EIP-712 domain separator
     */
    function getDomainSeparator() external view returns (bytes32) {
        return DOMAIN_SEPARATOR;
    }

    /**
     * @notice Get allowance amount
     * @param owner Token owner
     * @param spender Approved spender
     * @return Approved amount
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return allowances[owner][spender];
    }
}
