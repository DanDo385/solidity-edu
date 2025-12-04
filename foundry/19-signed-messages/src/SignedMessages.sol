// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Project19 - Signed Messages & EIP-712
 * @notice Learn about cryptographic signatures and EIP-712 typed structured data
 * @dev Implement EIP-712 compliant signature verification with replay protection
 *
 * CONCEPTS:
 * - EIP-191 vs EIP-712 signed data standards
 * - Domain separators for contract/chain-specific signatures
 * - Typed structured data hashing
 * - ECDSA signature verification with ecrecover
 * - Replay protection using nonces
 * - Deadline-based signature expiration
 * - Signature malleability prevention
 */
contract Project19 {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice EIP-712 domain separator - uniquely identifies this contract
    /// @dev Includes name, version, chainId, and contract address
    bytes32 public immutable DOMAIN_SEPARATOR;

    /// @notice Type hash for the EIP-712 domain
    bytes32 public constant EIP712_DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /// @notice Type hash for the Permit struct
    /// @dev Used for EIP-2612 style permit functionality
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @notice Type hash for MetaTransaction struct
    /// @dev Used for gasless transactions
    bytes32 public constant METATX_TYPEHASH =
        keccak256("MetaTx(address from,address to,uint256 amount,uint256 nonce,uint256 deadline)");

    /// @notice Nonce for each address to prevent replay attacks
    /// @dev Incremented after each signature use
    mapping(address => uint256) public nonces;

    /// @notice Track used voucher signatures to prevent reuse
    mapping(bytes32 => bool) public usedVouchers;

    /// @notice Balance tracking for demonstration
    mapping(address => uint256) public balances;

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

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        // TODO: Implement domain separator computation
        // HINT: Use keccak256(abi.encode(...)) with:
        //       - EIP712_DOMAIN_TYPEHASH
        //       - keccak256(bytes("Project19"))  // name
        //       - keccak256(bytes("1"))          // version
        //       - block.chainid
        //       - address(this)

        DOMAIN_SEPARATOR = bytes32(0); // Replace this
    }

    /*//////////////////////////////////////////////////////////////
                            CORE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Approve spender via signature (EIP-2612 style permit)
     * @dev Allows gasless approvals using off-chain signatures
     * @param owner Address of token owner
     * @param spender Address of approved spender
     * @param value Amount to approve
     * @param deadline Signature expiration timestamp
     * @param v ECDSA signature parameter
     * @param r ECDSA signature parameter
     * @param s ECDSA signature parameter
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
        // TODO: Implement permit function
        // Steps:
        // 1. Check deadline hasn't passed
        // 2. Get and increment nonce
        // 3. Create struct hash using PERMIT_TYPEHASH
        // 4. Create digest using domain separator
        // 5. Recover signer using ecrecover
        // 6. Verify signer is the owner
        // 7. Set approval (emit Approval event)

        revert("TODO: Implement permit");
    }

    /**
     * @notice Execute a meta-transaction on behalf of a user
     * @dev Allows gasless transactions - relayer pays gas
     * @param from Address initiating the transaction
     * @param to Recipient address
     * @param amount Amount to transfer
     * @param deadline Signature expiration timestamp
     * @param v ECDSA signature parameter
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
        // TODO: Implement meta-transaction execution
        // Steps:
        // 1. Check deadline
        // 2. Get current nonce
        // 3. Create struct hash using METATX_TYPEHASH
        // 4. Create digest
        // 5. Recover and verify signer
        // 6. Increment nonce (BEFORE transfer for reentrancy protection)
        // 7. Execute transfer
        // 8. Emit MetaTxExecuted event

        revert("TODO: Implement executeMetaTx");
    }

    /**
     * @notice Claim a voucher using an admin signature
     * @dev One-time use vouchers signed by authorized issuer
     * @param claimer Address claiming the voucher
     * @param amount Amount to credit
     * @param deadline Signature expiration timestamp
     * @param v ECDSA signature parameter
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
        // TODO: Implement voucher claiming
        // Steps:
        // 1. Check deadline
        // 2. Create struct hash (use METATX_TYPEHASH as a placeholder, or define VOUCHER_TYPEHASH)
        // 3. Create digest
        // 4. Check voucher hasn't been used (usedVouchers mapping)
        // 5. Recover signer
        // 6. Verify signer is authorized (could be owner or specific admin)
        // 7. Mark voucher as used
        // 8. Credit amount to claimer
        // 9. Emit VoucherClaimed event

        revert("TODO: Implement claimVoucher");
    }

    /*//////////////////////////////////////////////////////////////
                          HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Create the struct hash for a permit
     * @param owner Token owner
     * @param spender Approved spender
     * @param value Amount to approve
     * @param nonce Current nonce
     * @param deadline Expiration timestamp
     * @return Hash of the permit struct
     */
    function _hashPermit(
        address owner,
        address spender,
        uint256 value,
        uint256 nonce,
        uint256 deadline
    ) internal pure returns (bytes32) {
        // TODO: Implement struct hash creation
        // HINT: Use keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonce, deadline))

        return bytes32(0); // Replace this
    }

    /**
     * @notice Create the struct hash for a meta-transaction
     * @param from Sender address
     * @param to Recipient address
     * @param amount Transfer amount
     * @param nonce Current nonce
     * @param deadline Expiration timestamp
     * @return Hash of the meta-transaction struct
     */
    function _hashMetaTx(
        address from,
        address to,
        uint256 amount,
        uint256 nonce,
        uint256 deadline
    ) internal pure returns (bytes32) {
        // TODO: Implement struct hash for meta-transaction
        // HINT: Similar to _hashPermit but with METATX_TYPEHASH

        return bytes32(0); // Replace this
    }

    /**
     * @notice Create the final EIP-712 digest
     * @param structHash Hash of the typed struct data
     * @return EIP-712 compliant digest ready for signature verification
     */
    function _toTypedDataHash(bytes32 structHash) internal view returns (bytes32) {
        // TODO: Implement EIP-712 digest creation
        // HINT: keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash))
        // The "\x19\x01" prefix is defined by EIP-191 for structured data

        return bytes32(0); // Replace this
    }

    /**
     * @notice Verify a signature and return the signer
     * @param digest Message hash that was signed
     * @param v ECDSA recovery id
     * @param r ECDSA signature r parameter
     * @param s ECDSA signature s parameter
     * @return signer Address that created the signature
     */
    function _recoverSigner(
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address signer) {
        // TODO: Implement signature recovery
        // HINT: Use ecrecover(digest, v, r, s)
        // SECURITY: Check that recovered address is not zero!

        return address(0); // Replace this
    }

    /**
     * @notice Check if signature is valid and not malleable
     * @param s The s parameter of the signature
     * @return True if s is in the valid range
     */
    function _isValidSignatureS(bytes32 s) internal pure returns (bool) {
        // TODO: Implement signature malleability check
        // HINT: s must be in the lower half of the curve order
        // The maximum valid s value is:
        // 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0

        return true; // Replace this
    }

    /*//////////////////////////////////////////////////////////////
                          UTILITY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposit funds for testing
     */
    function deposit() external payable {
        balances[msg.sender] += msg.value;
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
}
