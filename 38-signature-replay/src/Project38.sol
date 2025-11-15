// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Project 38: Signature Replay Attack
 * @notice Learn about signature replay vulnerabilities and protections
 *
 * This project demonstrates:
 * 1. Vulnerable signature verification (no nonce)
 * 2. Replay attack exploitation
 * 3. Proper nonce-based protection
 * 4. ChainID and domain separator usage
 * 5. EIP-712 implementation
 *
 * Related to Project 19: Basic Signature Verification
 */

/**
 * @notice VULNERABLE: Contract without nonce protection
 * @dev This contract is intentionally vulnerable to replay attacks
 *
 * TODO: Identify the replay vulnerability in this contract
 */
contract VulnerableBank {
    mapping(address => uint256) public balances;

    event Withdrawal(address indexed user, uint256 amount);

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    /**
     * @notice Withdraw using a signature (VULNERABLE!)
     * @dev TODO: Explain why this is vulnerable to replay attacks
     *
     * Hint: What prevents the same signature from being used twice?
     */
    function withdrawWithSignature(
        uint256 amount,
        bytes memory signature
    ) external {
        // TODO: Identify the vulnerability here
        bytes32 messageHash = keccak256(abi.encodePacked(amount));
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        address signer = recoverSigner(ethSignedMessageHash, signature);

        require(balances[signer] >= amount, "Insufficient balance");

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
 * @notice Attacker contract to exploit replay vulnerability
 * @dev TODO: Complete the attack implementation
 */
contract ReplayAttacker {
    VulnerableBank public targetBank;

    constructor(address _targetBank) {
        targetBank = VulnerableBank(_targetBank);
    }

    /**
     * @notice Execute replay attack
     * @dev TODO: Implement the replay attack
     *
     * Steps:
     * 1. Call withdrawWithSignature multiple times
     * 2. Use the same signature each time
     * 3. Drain the victim's balance
     *
     * @param amount Amount from the signature
     * @param signature Valid signature to replay
     * @param times Number of times to replay
     */
    function attack(
        uint256 amount,
        bytes memory signature,
        uint256 times
    ) external {
        // TODO: Implement replay attack
        // Hint: Loop and call targetBank.withdrawWithSignature
    }

    receive() external payable {}
}

/**
 * @notice SECURE: Bank with nonce protection
 * @dev TODO: Complete the implementation with proper nonce tracking
 */
contract SecureBank {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public nonces; // TODO: Use this to prevent replay

    event Withdrawal(address indexed user, uint256 amount, uint256 nonce);

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    /**
     * @notice Withdraw using a signature with nonce protection
     * @dev TODO: Implement proper nonce-based replay protection
     *
     * Requirements:
     * 1. Include nonce in the message hash
     * 2. Verify the nonce matches the user's current nonce
     * 3. Increment the nonce after successful withdrawal
     *
     * @param amount Amount to withdraw
     * @param nonce Current nonce (must match stored nonce)
     * @param signature Signature over (amount, nonce)
     */
    function withdrawWithSignature(
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    ) external {
        // TODO: Implement nonce verification
        // Step 1: Check nonce matches

        // TODO: Create message hash with nonce
        bytes32 messageHash = bytes32(0); // REPLACE THIS

        // TODO: Recover signer and verify

        // TODO: Check balance

        // TODO: Increment nonce BEFORE transfer (CEI pattern)

        // TODO: Perform transfer

        emit Withdrawal(address(0), amount, nonce); // Fix parameters
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
 * @notice VULNERABLE: Missing chainID in signature
 * @dev TODO: Identify the cross-chain replay vulnerability
 */
contract CrossChainVulnerable {
    mapping(address => uint256) public claimed;

    event Claimed(address indexed user, uint256 amount);

    /**
     * @notice Claim airdrop with signature (VULNERABLE to cross-chain replay!)
     * @dev TODO: Explain how this can be exploited across different chains
     */
    function claimAirdrop(
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    ) external {
        // TODO: Identify missing chainID protection
        bytes32 messageHash = keccak256(abi.encodePacked(
            msg.sender,
            amount,
            nonce
            // Missing: block.chainid
        ));

        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        address signer = recoverSigner(ethSignedMessageHash, signature);

        require(signer == owner(), "Invalid signature");
        require(claimed[msg.sender] == 0, "Already claimed");

        claimed[msg.sender] = amount;
        payable(msg.sender).transfer(amount);

        emit Claimed(msg.sender, amount);
    }

    function owner() public pure returns (address) {
        return address(0x1234); // Placeholder
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
 * @notice SECURE: EIP-712 implementation
 * @dev TODO: Complete the EIP-712 signature verification
 */
contract EIP712SecureBank {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public nonces;

    // TODO: Define the domain separator
    bytes32 public DOMAIN_SEPARATOR;

    // TODO: Define the Transfer typehash
    bytes32 public constant TRANSFER_TYPEHASH = keccak256(
        "Transfer(address from,address to,uint256 amount,uint256 nonce)"
    );

    event Withdrawal(address indexed from, address indexed to, uint256 amount);

    constructor() {
        // TODO: Initialize DOMAIN_SEPARATOR
        // Include: contract name, version, chainID, and contract address
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes("SecureBank")),
            keccak256(bytes("1")),
            block.chainid,
            address(this)
        ));
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    /**
     * @notice Transfer with EIP-712 signature
     * @dev TODO: Implement EIP-712 signature verification
     *
     * Steps:
     * 1. Create struct hash using TRANSFER_TYPEHASH
     * 2. Create digest using DOMAIN_SEPARATOR
     * 3. Recover signer using ECDSA
     * 4. Verify nonce and execute transfer
     */
    function transferWithSignature(
        address from,
        address to,
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    ) external {
        // TODO: Verify nonce

        // TODO: Create struct hash
        bytes32 structHash = bytes32(0); // REPLACE THIS

        // TODO: Create EIP-712 digest
        bytes32 digest = bytes32(0); // REPLACE THIS

        // TODO: Recover signer

        // TODO: Verify signer matches 'from'

        // TODO: Check balance

        // TODO: Update state and transfer

        emit Withdrawal(from, to, amount);
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
 * @notice Learning Exercises
 *
 * 1. EXPLOIT: Complete ReplayAttacker to drain VulnerableBank
 *    - Use the same signature multiple times
 *    - Observe how funds are drained
 *
 * 2. FIX: Complete SecureBank with nonce protection
 *    - Add nonce to message hash
 *    - Verify and increment nonce
 *    - Test that replay fails
 *
 * 3. ANALYZE: Explain CrossChainVulnerable's weakness
 *    - Why can signatures be replayed across chains?
 *    - What should be added to prevent this?
 *
 * 4. IMPLEMENT: Complete EIP712SecureBank
 *    - Calculate struct hash correctly
 *    - Use domain separator properly
 *    - Verify signature recovery
 *
 * 5. COMPARE: Test all implementations
 *    - Demonstrate vulnerabilities
 *    - Verify protections work
 *    - Understand trade-offs
 */
