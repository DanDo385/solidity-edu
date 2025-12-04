// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Project 38 Solution: Signature Replay Attack
 * @notice Complete implementations demonstrating vulnerabilities and protections
 */

// ============================================================================
// VULNERABLE IMPLEMENTATIONS
// ============================================================================

/**
 * @notice VULNERABLE: Bank without replay protection
 * @dev Missing nonce allows infinite signature reuse
 */
contract VulnerableBankSolution {
    mapping(address => uint256) public balances;

    event Withdrawal(address indexed user, uint256 amount);

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    /**
     * @notice VULNERABILITY: Signature can be replayed indefinitely
     * @dev The message only contains amount - no nonce, no chainID, no contract address
     *
     * Attack Vector:
     * 1. User signs withdrawal of 1 ETH
     * 2. Attacker calls withdrawWithSignature with same signature
     * 3. Attacker repeats until balance drained
     *
     * Why it works:
     * - No nonce tracking means signature never expires
     * - No used signature registry
     * - Same signature always produces same signer
     */
    function withdrawWithSignature(
        uint256 amount,
        bytes memory signature
    ) external {
        // Create message hash - VULNERABLE: only includes amount!
        bytes32 messageHash = keccak256(abi.encodePacked(amount));
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        address signer = recoverSigner(ethSignedMessageHash, signature);

        require(balances[signer] >= amount, "Insufficient balance");

        // No nonce increment - signature can be reused!
        balances[signer] -= amount;
        payable(msg.sender).transfer(amount);

        emit Withdrawal(signer, amount);
    }

    function getEthSignedMessageHash(bytes32 messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    }

    function recoverSigner(bytes32 ethSignedMessageHash, bytes memory signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "Invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. SIGNATURES CAN BE REPLAYED WITHOUT PROTECTION
 *    ✅ Same signature can be used multiple times
 *    ✅ Attacker can drain funds by replaying signature
 *    ✅ Real-world: Many exploits due to missing nonces
 *    ✅ CONNECTION TO PROJECT 19: EIP-712 signed messages!
 *
 * 2. NONCES PREVENT REPLAY ATTACKS
 *    ✅ Each address has incrementing nonce
 *    ✅ Signatures must include current nonce
 *    ✅ Nonce increments after use
 *    ✅ Ensures signatures used once, in order
 *
 * 3. CHAINID PREVENTS CROSS-CHAIN REPLAY
 *    ✅ Signatures valid on one chain invalid on others
 *    ✅ Prevents replay after hard forks
 *    ✅ Essential for multi-chain protocols
 *    ✅ Include in EIP-712 domain separator
 *
 * 4. DOMAIN SEPARATOR PREVENTS CROSS-CONTRACT REPLAY
 *    ✅ Includes contract address in signature
 *    ✅ Signature valid for one contract only
 *    ✅ Prevents replay on different contracts
 *    ✅ EIP-712 standard pattern
 *
 * 5. DEADLINE PREVENTS STALE SIGNATURES
 *    ✅ Signatures expire after deadline
 *    ✅ Prevents using old signatures
 *    ✅ Check block.timestamp <= deadline
 *    ✅ Common pattern for permits
 *
 * 6. EIP-712 PROVIDES COMPREHENSIVE PROTECTION
 *    ✅ Typed structured data
 *    ✅ Domain separator (chainId, contract address)
 *    ✅ Nonce tracking
 *    ✅ Deadline support
 *    ✅ Production-ready standard
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMMON MISTAKES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ❌ Not tracking nonces (infinite replay!)
 * ❌ Missing chainId in signatures (cross-chain replay!)
 * ❌ Missing contract address (cross-contract replay!)
 * ❌ Not checking deadlines (stale signatures!)
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          NEXT STEPS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * • Study EIP-712 in detail (Project 19)
 * • Learn about signature invalidation patterns
 * • Review real-world replay attack exploits
 * • Move to Project 39 to learn about governance attacks
 */

/**
 * @notice Attacker contract demonstrating replay attack
 * @dev Shows how to exploit missing nonce protection
 */
contract ReplayAttackerSolution {
    VulnerableBankSolution public targetBank;
    uint256 public stolenAmount;

    event AttackExecuted(uint256 times, uint256 totalStolen);

    constructor(address _targetBank) {
        targetBank = VulnerableBankSolution(_targetBank);
    }

    /**
     * @notice Execute replay attack by reusing the same signature
     * @dev Demonstrates the core vulnerability
     *
     * Attack Steps:
     * 1. Obtain a valid signature (could be from legitimate transaction)
     * 2. Call withdrawWithSignature repeatedly with same signature
     * 3. Each call succeeds because signature is never invalidated
     * 4. Drain victim's balance
     *
     * @param amount Amount specified in the signature
     * @param signature Valid signature to replay
     * @param times Number of times to replay (limited by victim's balance)
     */
    function attack(
        uint256 amount,
        bytes memory signature,
        uint256 times
    ) external {
        for (uint256 i = 0; i < times; i++) {
            // Replay the same signature multiple times!
            targetBank.withdrawWithSignature(amount, signature);
            stolenAmount += amount;
        }

        emit AttackExecuted(times, stolenAmount);
    }

    /**
     * @notice Withdraw stolen funds
     */
    function withdrawStolen() external {
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {}
}

// ============================================================================
// SECURE IMPLEMENTATION: NONCE PROTECTION
// ============================================================================

/**
 * @notice SECURE: Bank with proper nonce-based replay protection
 * @dev Each signature can only be used once per user
 */
contract SecureBankSolution {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public nonces;

    event Withdrawal(address indexed user, uint256 amount, uint256 nonce);

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    /**
     * @notice Secure withdrawal with nonce protection
     * @dev Prevents replay by tracking nonces per user
     *
     * Security Features:
     * 1. Nonce included in signature prevents reuse
     * 2. Nonce must match current value for user
     * 3. Nonce incremented after use (CEI pattern)
     * 4. Each user has independent nonce counter
     *
     * Why this works:
     * - After first use, nonce increments
     * - Replayed signature has old nonce
     * - Old nonce != current nonce → transaction reverts
     *
     * @param amount Amount to withdraw
     * @param nonce Must match user's current nonce
     * @param signature Signature over (amount, nonce)
     */
    function withdrawWithSignature(
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    ) external {
        // Create message hash including nonce
        bytes32 messageHash = keccak256(abi.encodePacked(amount, nonce));
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        address signer = recoverSigner(ethSignedMessageHash, signature);

        // Verify nonce matches (prevents replay)
        require(nonces[signer] == nonce, "Invalid nonce");
        require(balances[signer] >= amount, "Insufficient balance");

        // CEI Pattern: Update state before external call
        nonces[signer]++; // Increment BEFORE transfer
        balances[signer] -= amount;

        payable(msg.sender).transfer(amount);

        emit Withdrawal(signer, amount, nonce);
    }

    /**
     * @notice Get current nonce for user (useful for creating signatures)
     */
    function getNonce(address user) external view returns (uint256) {
        return nonces[user];
    }

    function getEthSignedMessageHash(bytes32 messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    }

    function recoverSigner(bytes32 ethSignedMessageHash, bytes memory signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "Invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. SIGNATURES CAN BE REPLAYED WITHOUT PROTECTION
 *    ✅ Same signature can be used multiple times
 *    ✅ Attacker can drain funds by replaying signature
 *    ✅ Real-world: Many exploits due to missing nonces
 *    ✅ CONNECTION TO PROJECT 19: EIP-712 signed messages!
 *
 * 2. NONCES PREVENT REPLAY ATTACKS
 *    ✅ Each address has incrementing nonce
 *    ✅ Signatures must include current nonce
 *    ✅ Nonce increments after use
 *    ✅ Ensures signatures used once, in order
 *
 * 3. CHAINID PREVENTS CROSS-CHAIN REPLAY
 *    ✅ Signatures valid on one chain invalid on others
 *    ✅ Prevents replay after hard forks
 *    ✅ Essential for multi-chain protocols
 *    ✅ Include in EIP-712 domain separator
 *
 * 4. DOMAIN SEPARATOR PREVENTS CROSS-CONTRACT REPLAY
 *    ✅ Includes contract address in signature
 *    ✅ Signature valid for one contract only
 *    ✅ Prevents replay on different contracts
 *    ✅ EIP-712 standard pattern
 *
 * 5. DEADLINE PREVENTS STALE SIGNATURES
 *    ✅ Signatures expire after deadline
 *    ✅ Prevents using old signatures
 *    ✅ Check block.timestamp <= deadline
 *    ✅ Common pattern for permits
 *
 * 6. EIP-712 PROVIDES COMPREHENSIVE PROTECTION
 *    ✅ Typed structured data
 *    ✅ Domain separator (chainId, contract address)
 *    ✅ Nonce tracking
 *    ✅ Deadline support
 *    ✅ Production-ready standard
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMMON MISTAKES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ❌ Not tracking nonces (infinite replay!)
 * ❌ Missing chainId in signatures (cross-chain replay!)
 * ❌ Missing contract address (cross-contract replay!)
 * ❌ Not checking deadlines (stale signatures!)
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          NEXT STEPS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * • Study EIP-712 in detail (Project 19)
 * • Learn about signature invalidation patterns
 * • Review real-world replay attack exploits
 * • Move to Project 39 to learn about governance attacks
 */

// ============================================================================
// VULNERABLE: CROSS-CHAIN REPLAY
// ============================================================================

/**
 * @notice VULNERABLE: Missing chainID allows cross-chain replay
 * @dev Signature valid on one chain can be replayed on another
 */
contract CrossChainVulnerableSolution {
    mapping(address => uint256) public claimed;
    address public immutable OWNER;

    event Claimed(address indexed user, uint256 amount);

    constructor() {
        OWNER = msg.sender;
    }

    /**
     * @notice VULNERABILITY: No chainID in signature
     * @dev Allows cross-chain replay attacks
     *
     * Attack Scenario:
     * 1. Owner signs airdrop on Goerli testnet
     * 2. User claims on Goerli (legitimate)
     * 3. Attacker takes same signature to Mainnet
     * 4. Signature is still valid on Mainnet!
     * 5. Attacker claims on Mainnet with testnet signature
     *
     * Why it works:
     * - Signature doesn't include block.chainid
     * - Message is identical across all chains
     * - ecrecover produces same signer on all chains
     *
     * Real-world impact:
     * - After Ethereum/ETC split, transactions replayed
     * - Modern bridges must include chainID
     */
    function claimAirdrop(
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    ) external {
        // VULNERABLE: Missing block.chainid!
        bytes32 messageHash = keccak256(abi.encodePacked(
            msg.sender,
            amount,
            nonce
            // Should include: block.chainid
        ));

        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        address signer = recoverSigner(ethSignedMessageHash, signature);

        require(signer == OWNER, "Invalid signature");
        require(claimed[msg.sender] == 0, "Already claimed");

        claimed[msg.sender] = amount;
        payable(msg.sender).transfer(amount);

        emit Claimed(msg.sender, amount);
    }

    function getEthSignedMessageHash(bytes32 messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    }

    function recoverSigner(bytes32 ethSignedMessageHash, bytes memory signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "Invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    receive() external payable {}
}

/**
 * @notice SECURE: Includes chainID to prevent cross-chain replay
 */
contract CrossChainSecureSolution {
    mapping(address => uint256) public claimed;
    address public immutable OWNER;

    event Claimed(address indexed user, uint256 amount, uint256 chainId);

    constructor() {
        OWNER = msg.sender;
    }

    /**
     * @notice Secure airdrop claim with chainID protection
     * @dev Signature includes chainID, preventing cross-chain replay
     *
     * Security improvement:
     * - block.chainid included in message
     * - Different chains = different chainid = different message
     * - Same signature produces different hash on different chains
     * - Signature from chain A won't verify on chain B
     */
    function claimAirdrop(
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    ) external {
        // SECURE: Includes block.chainid
        bytes32 messageHash = keccak256(abi.encodePacked(
            msg.sender,
            amount,
            nonce,
            block.chainid  // Prevents cross-chain replay!
        ));

        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        address signer = recoverSigner(ethSignedMessageHash, signature);

        require(signer == OWNER, "Invalid signature");
        require(claimed[msg.sender] == 0, "Already claimed");

        claimed[msg.sender] = amount;
        payable(msg.sender).transfer(amount);

        emit Claimed(msg.sender, amount, block.chainid);
    }

    function getEthSignedMessageHash(bytes32 messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    }

    function recoverSigner(bytes32 ethSignedMessageHash, bytes memory signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "Invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    receive() external payable {}
}

// ============================================================================
// SECURE IMPLEMENTATION: EIP-712
// ============================================================================

/**
 * @notice SECURE: Full EIP-712 implementation
 * @dev Gold standard for signature security with domain separation
 *
 * EIP-712 Benefits:
 * 1. Structured, human-readable signatures
 * 2. Domain separation (contract + chain specific)
 * 3. Prevents cross-contract replay
 * 4. Prevents cross-chain replay
 * 5. Standard format for wallets to display
 * 6. Type-safe signature verification
 */
contract EIP712SecureBankSolution {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public nonces;

    // EIP-712 Domain Separator
    // Uniquely identifies this contract on this chain
    bytes32 public immutable DOMAIN_SEPARATOR;

    // TypeHash for Transfer struct
    // Defines the structure of signed data
    bytes32 public constant TRANSFER_TYPEHASH = keccak256(
        "Transfer(address from,address to,uint256 amount,uint256 nonce)"
    );

    event Withdrawal(address indexed from, address indexed to, uint256 amount);

    constructor() {
        // Build domain separator
        // This makes signatures specific to THIS contract on THIS chain
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes("SecureBank")),        // Contract name
            keccak256(bytes("1")),                 // Version
            block.chainid,                         // Chain ID (prevents cross-chain)
            address(this)                          // Contract address (prevents cross-contract)
        ));
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    /**
     * @notice Transfer with EIP-712 signature
     * @dev Maximum security signature verification
     *
     * EIP-712 Process:
     * 1. Create struct hash from typed data
     * 2. Combine with domain separator
     * 3. Add EIP-712 prefix "\x19\x01"
     * 4. Hash to create final digest
     * 5. Recover signer from digest
     *
     * Security guarantees:
     * - Domain separator ensures contract + chain specificity
     * - Nonce prevents replay
     * - Type hash ensures data structure integrity
     * - Wallets can display human-readable data
     *
     * @param from Address sending tokens (must match signer)
     * @param to Address receiving tokens
     * @param amount Amount to transfer
     * @param nonce Must match from's current nonce
     * @param signature EIP-712 signature
     */
    function transferWithSignature(
        address from,
        address to,
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    ) external {
        require(to != address(0), "Invalid recipient");

        // Step 1: Create struct hash
        // Hash the actual data according to the type definition
        bytes32 structHash = keccak256(abi.encode(
            TRANSFER_TYPEHASH,
            from,
            to,
            amount,
            nonce
        ));

        // Step 2: Create EIP-712 digest
        // Combine domain separator with struct hash
        // "\x19\x01" is the EIP-712 prefix
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",           // EIP-712 prefix
            DOMAIN_SEPARATOR,     // Contract + chain specific
            structHash            // Data hash
        ));

        // Step 3: Recover signer
        address signer = recoverSigner(digest, signature);

        // Step 4: Verify authorization
        require(signer == from, "Invalid signature");
        require(nonces[from] == nonce, "Invalid nonce");
        require(balances[from] >= amount, "Insufficient balance");

        // Step 5: Execute transfer (CEI pattern)
        nonces[from]++;
        balances[from] -= amount;
        balances[to] += amount;

        emit Withdrawal(from, to, amount);
    }

    /**
     * @notice Helper to get domain separator (useful for off-chain signing)
     */
    function getDomainSeparator() external view returns (bytes32) {
        return DOMAIN_SEPARATOR;
    }

    /**
     * @notice Get current nonce for an address
     */
    function getNonce(address user) external view returns (uint256) {
        return nonces[user];
    }

    /**
     * @notice Get the digest for a transfer (useful for off-chain signing)
     */
    function getTransferDigest(
        address from,
        address to,
        uint256 amount,
        uint256 nonce
    ) external view returns (bytes32) {
        bytes32 structHash = keccak256(abi.encode(
            TRANSFER_TYPEHASH,
            from,
            to,
            amount,
            nonce
        ));

        return keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            structHash
        ));
    }

    function recoverSigner(bytes32 digest, bytes memory signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        return ecrecover(digest, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "Invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. SIGNATURES CAN BE REPLAYED WITHOUT PROTECTION
 *    ✅ Same signature can be used multiple times
 *    ✅ Attacker can drain funds by replaying signature
 *    ✅ Real-world: Many exploits due to missing nonces
 *    ✅ CONNECTION TO PROJECT 19: EIP-712 signed messages!
 *
 * 2. NONCES PREVENT REPLAY ATTACKS
 *    ✅ Each address has incrementing nonce
 *    ✅ Signatures must include current nonce
 *    ✅ Nonce increments after use
 *    ✅ Ensures signatures used once, in order
 *
 * 3. CHAINID PREVENTS CROSS-CHAIN REPLAY
 *    ✅ Signatures valid on one chain invalid on others
 *    ✅ Prevents replay after hard forks
 *    ✅ Essential for multi-chain protocols
 *    ✅ Include in EIP-712 domain separator
 *
 * 4. DOMAIN SEPARATOR PREVENTS CROSS-CONTRACT REPLAY
 *    ✅ Includes contract address in signature
 *    ✅ Signature valid for one contract only
 *    ✅ Prevents replay on different contracts
 *    ✅ EIP-712 standard pattern
 *
 * 5. DEADLINE PREVENTS STALE SIGNATURES
 *    ✅ Signatures expire after deadline
 *    ✅ Prevents using old signatures
 *    ✅ Check block.timestamp <= deadline
 *    ✅ Common pattern for permits
 *
 * 6. EIP-712 PROVIDES COMPREHENSIVE PROTECTION
 *    ✅ Typed structured data
 *    ✅ Domain separator (chainId, contract address)
 *    ✅ Nonce tracking
 *    ✅ Deadline support
 *    ✅ Production-ready standard
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMMON MISTAKES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ❌ Not tracking nonces (infinite replay!)
 * ❌ Missing chainId in signatures (cross-chain replay!)
 * ❌ Missing contract address (cross-contract replay!)
 * ❌ Not checking deadlines (stale signatures!)
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          NEXT STEPS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * • Study EIP-712 in detail (Project 19)
 * • Learn about signature invalidation patterns
 * • Review real-world replay attack exploits
 * • Move to Project 39 to learn about governance attacks
 */

// ============================================================================
// ADVANCED: SIGNATURE INVALIDATION
// ============================================================================

/**
 * @notice Advanced bank with signature invalidation capability
 * @dev Allows users to cancel signatures before they're used
 */
contract AdvancedSecureBankSolution {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public nonces;
    mapping(bytes32 => bool) public invalidatedSignatures;

    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public constant TRANSFER_TYPEHASH = keccak256(
        "Transfer(address from,address to,uint256 amount,uint256 nonce,uint256 deadline)"
    );

    event Withdrawal(address indexed from, address indexed to, uint256 amount);
    event SignatureInvalidated(bytes32 indexed signatureHash);

    constructor() {
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes("AdvancedSecureBank")),
            keccak256(bytes("1")),
            block.chainid,
            address(this)
        ));
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    /**
     * @notice Transfer with signature including deadline
     * @dev Adds time-based expiration to signatures
     */
    function transferWithSignature(
        address from,
        address to,
        uint256 amount,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) external {
        require(block.timestamp <= deadline, "Signature expired");
        require(to != address(0), "Invalid recipient");

        bytes32 structHash = keccak256(abi.encode(
            TRANSFER_TYPEHASH,
            from,
            to,
            amount,
            nonce,
            deadline
        ));

        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            structHash
        ));

        // Check if signature was manually invalidated
        require(!invalidatedSignatures[digest], "Signature invalidated");

        address signer = recoverSigner(digest, signature);

        require(signer == from, "Invalid signature");
        require(nonces[from] == nonce, "Invalid nonce");
        require(balances[from] >= amount, "Insufficient balance");

        nonces[from]++;
        balances[from] -= amount;
        balances[to] += amount;

        emit Withdrawal(from, to, amount);
    }

    /**
     * @notice Invalidate a signature before it's used
     * @dev Useful if signature is compromised or no longer desired
     */
    function invalidateSignature(
        address to,
        uint256 amount,
        uint256 nonce,
        uint256 deadline
    ) external {
        bytes32 structHash = keccak256(abi.encode(
            TRANSFER_TYPEHASH,
            msg.sender,
            to,
            amount,
            nonce,
            deadline
        ));

        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            structHash
        ));

        invalidatedSignatures[digest] = true;
        emit SignatureInvalidated(digest);
    }

    function recoverSigner(bytes32 digest, bytes memory signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        return ecrecover(digest, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "Invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. SIGNATURES CAN BE REPLAYED WITHOUT PROTECTION
 *    ✅ Same signature can be used multiple times
 *    ✅ Attacker can drain funds by replaying signature
 *    ✅ Real-world: Many exploits due to missing nonces
 *    ✅ CONNECTION TO PROJECT 19: EIP-712 signed messages!
 *
 * 2. NONCES PREVENT REPLAY ATTACKS
 *    ✅ Each address has incrementing nonce
 *    ✅ Signatures must include current nonce
 *    ✅ Nonce increments after use
 *    ✅ Ensures signatures used once, in order
 *
 * 3. CHAINID PREVENTS CROSS-CHAIN REPLAY
 *    ✅ Signatures valid on one chain invalid on others
 *    ✅ Prevents replay after hard forks
 *    ✅ Essential for multi-chain protocols
 *    ✅ Include in EIP-712 domain separator
 *
 * 4. DOMAIN SEPARATOR PREVENTS CROSS-CONTRACT REPLAY
 *    ✅ Includes contract address in signature
 *    ✅ Signature valid for one contract only
 *    ✅ Prevents replay on different contracts
 *    ✅ EIP-712 standard pattern
 *
 * 5. DEADLINE PREVENTS STALE SIGNATURES
 *    ✅ Signatures expire after deadline
 *    ✅ Prevents using old signatures
 *    ✅ Check block.timestamp <= deadline
 *    ✅ Common pattern for permits
 *
 * 6. EIP-712 PROVIDES COMPREHENSIVE PROTECTION
 *    ✅ Typed structured data
 *    ✅ Domain separator (chainId, contract address)
 *    ✅ Nonce tracking
 *    ✅ Deadline support
 *    ✅ Production-ready standard
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMMON MISTAKES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ❌ Not tracking nonces (infinite replay!)
 * ❌ Missing chainId in signatures (cross-chain replay!)
 * ❌ Missing contract address (cross-contract replay!)
 * ❌ Not checking deadlines (stale signatures!)
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          NEXT STEPS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * • Study EIP-712 in detail (Project 19)
 * • Learn about signature invalidation patterns
 * • Review real-world replay attack exploits
 * • Move to Project 39 to learn about governance attacks
 */
