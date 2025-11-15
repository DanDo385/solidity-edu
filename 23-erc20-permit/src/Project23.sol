// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title Project23 - ERC-20 Permit (EIP-2612)
 * @notice Learn how to implement gasless token approvals using permit functionality
 * @dev Implement EIP-2612 compliant permit function for ERC-20 tokens
 *
 * CONCEPTS:
 * - EIP-2612 permit standard for gasless approvals
 * - EIP-712 typed structured data hashing
 * - ECDSA signature verification
 * - Nonce-based replay protection
 * - Deadline-based signature expiration
 * - Domain separators for contract/chain isolation
 * - Gas optimization through signature-based approvals
 *
 * KEY LEARNING POINTS:
 * - Why permit is better than approve (UX + gas)
 * - How to verify signatures on-chain
 * - Importance of nonces and deadlines
 * - EIP-712 domain separation
 */
contract Project23 is ERC20 {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice EIP-712 domain separator - uniquely identifies this token
    /// @dev Prevents signature replay across different tokens/chains
    bytes32 private immutable _DOMAIN_SEPARATOR;

    /// @notice EIP-712 domain typehash
    bytes32 private constant _DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /// @notice Permit function typehash as defined in EIP-2612
    /// @dev This is the keccak256 hash of the permit function signature
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @notice Nonce for each address to prevent permit replay attacks
    /// @dev Increments after each permit use
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
    error ERC20Permit__InvalidSigner();

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initialize the token with permit functionality
     * @dev Mints initial supply and computes domain separator
     */
    constructor() ERC20(_NAME, "PMT") {
        // TODO: Implement domain separator computation
        // HINT: Use keccak256(abi.encode(...)) with:
        //       - _DOMAIN_TYPEHASH
        //       - keccak256(bytes(_NAME))
        //       - keccak256(bytes(_VERSION))
        //       - block.chainid (for chain-specific signatures)
        //       - address(this) (for contract-specific signatures)
        //
        // WHY: This creates a unique identifier for this token on this chain,
        //      preventing signatures from being replayed on other tokens or chains

        _DOMAIN_SEPARATOR = bytes32(0); // Replace this

        // Mint initial supply for testing
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }

    /*//////////////////////////////////////////////////////////////
                          PERMIT FUNCTIONALITY
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Approve tokens via signature (EIP-2612)
     * @dev Implements gasless approval using off-chain signatures
     *
     * HOW IT WORKS:
     * 1. User signs approval off-chain (no gas, no transaction)
     * 2. Anyone can submit the signature on-chain
     * 3. Contract verifies signature and sets approval
     * 4. Nonce is incremented to prevent replay
     *
     * SECURITY:
     * - Deadline prevents stale signatures
     * - Nonce prevents replay attacks
     * - Domain separator prevents cross-contract/chain replays
     * - ECDSA.recover handles signature malleability
     *
     * @param owner Address of token owner (signer)
     * @param spender Address being approved
     * @param value Amount to approve
     * @param deadline Signature expiration timestamp
     * @param v ECDSA signature parameter (recovery id)
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
    ) public virtual {
        // TODO: Implement permit function
        //
        // STEPS:
        // 1. Check that deadline hasn't passed
        //    HINT: block.timestamp <= deadline
        //
        // 2. Get current nonce and increment it
        //    HINT: Use _useNonce(owner) which returns current and increments
        //
        // 3. Create the struct hash using EIP-712 format
        //    HINT: keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonce, deadline))
        //
        // 4. Create the digest (final hash to sign)
        //    HINT: Use _hashTypedDataV4(structHash) helper
        //
        // 5. Recover the signer from the signature
        //    HINT: Use ECDSA.recover(digest, v, r, s)
        //    NOTE: This automatically handles signature malleability
        //
        // 6. Verify the signer is the owner
        //    HINT: require(signer == owner, "Invalid signature")
        //
        // 7. Set the approval
        //    HINT: Use _approve(owner, spender, value)
        //
        // IMPORTANT: Why increment nonce BEFORE approval?
        // - Prevents reentrancy attacks
        // - Ensures signature can't be replayed even in complex scenarios

        revert("TODO: Implement permit");
    }

    /*//////////////////////////////////////////////////////////////
                          EIP-712 HELPERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get the domain separator
     * @dev Required by EIP-2612 for off-chain signature creation
     * @return The EIP-712 domain separator
     */
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        // TODO: Return the domain separator
        // HINT: Just return _DOMAIN_SEPARATOR
        //
        // WHY PUBLIC: Off-chain tools need this to create valid signatures

        return bytes32(0); // Replace this
    }

    /**
     * @notice Hash typed data according to EIP-712
     * @dev Combines domain separator with struct hash
     * @param structHash Hash of the typed structured data
     * @return digest Final hash ready for signing/verification
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32 digest) {
        // TODO: Implement EIP-712 digest creation
        // HINT: keccak256(abi.encodePacked("\x19\x01", _DOMAIN_SEPARATOR, structHash))
        //
        // EXPLANATION:
        // - "\x19\x01" is the EIP-191 version byte for structured data
        // - _DOMAIN_SEPARATOR provides domain isolation
        // - structHash contains the actual data being signed
        //
        // WHY THIS FORMAT:
        // - Prevents signature from being used as raw transaction
        // - Prevents confusion with eth_sign personal messages
        // - Standards-compliant across all EIP-712 implementations

        return bytes32(0); // Replace this
    }

    /*//////////////////////////////////////////////////////////////
                          NONCE MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get current nonce for an address
     * @dev Required by EIP-2612 for off-chain signature creation
     * @param owner Address to query
     * @return Current nonce value
     */
    function nonces(address owner) public view virtual returns (uint256) {
        // TODO: Return the current nonce
        // HINT: return _nonces[owner]
        //
        // WHY PUBLIC: Users need to know their nonce to create valid signatures

        return 0; // Replace this
    }

    /**
     * @notice Use (consume) a nonce
     * @dev Increments nonce and returns the old value
     * @param owner Address whose nonce to use
     * @return current The nonce before incrementing
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        // TODO: Implement nonce consumption
        // HINT: Get current value, increment in storage, return old value
        //
        // EXAMPLE:
        // current = _nonces[owner];
        // _nonces[owner] = current + 1;
        //
        // WHY INCREMENT: Prevents signature replay - each signature uses a different nonce

        return 0; // Replace this
    }

    /*//////////////////////////////////////////////////////////////
                          UTILITY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Mint tokens (for testing purposes)
     * @param to Address to mint to
     * @param amount Amount to mint
     */
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    /**
     * @notice Get token name (for EIP-712)
     * @return Token name
     */
    function name() public pure override returns (string memory) {
        return _NAME;
    }
}
