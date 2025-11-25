// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Project 35: Delegatecall Storage Corruption
 * @notice Learn about delegatecall vulnerabilities and storage collisions
 *
 * LEARNING OBJECTIVES:
 * 1. Understand how delegatecall affects storage
 * 2. Identify storage collision vulnerabilities
 * 3. Exploit storage corruption
 * 4. Implement safe proxy patterns
 *
 * TASKS:
 * 1. Complete the VulnerableProxy contract
 * 2. Create MaliciousImplementation to exploit storage
 * 3. Implement SafeProxy using EIP-1967
 * 4. Add proper access control
 */

/**
 * @notice VULNERABLE PROXY - Has storage collision vulnerability
 *
 * Storage Layout:
 * slot 0: implementation (address)
 * slot 1: owner (address)
 *
 * VULNERABILITY: Implementation contracts can overwrite these slots!
 */
contract VulnerableProxy {
    // TODO: Add state variables
    // HINT: You need implementation and owner addresses
    // WARNING: This storage layout is vulnerable!

    // Storage slot 0
    address public implementation;

    // Storage slot 1
    address public owner;

    constructor(address _implementation) {
        // TODO: Initialize implementation and owner
        // HINT: Owner should be msg.sender

    }

    /**
     * @notice Upgrade to a new implementation
     * @dev TODO: Add access control
     */
    function upgrade(address _newImplementation) external {
        // TODO: Implement upgrade logic
        // HINT: Only owner should be able to upgrade
        // QUESTION: What happens if implementation is malicious?

    }

    /**
     * @notice Fallback function that delegates all calls
     * @dev This is where the delegatecall happens
     */
    fallback() external payable {
        // TODO: Implement delegatecall logic
        // HINT: Use assembly to preserve return data
        // STEPS:
        // 1. Load implementation address
        // 2. Copy calldata to memory
        // 3. Perform delegatecall
        // 4. Copy return data
        // 5. Return or revert based on result

    }

    receive() external payable {}
}

/**
 * @notice LEGITIMATE IMPLEMENTATION - Works as expected
 *
 * Storage Layout:
 * slot 0: value (uint256)
 * slot 1: data (address)
 *
 * SAFE: This implementation doesn't try to modify proxy's state
 */
contract LegitimateImplementation {
    // TODO: Add state variables
    // HINT: These should be at slots 0 and 1

    uint256 public value;
    address public data;

    /**
     * @notice Set a value
     * @dev This is safe - only modifies implementation-specific storage
     */
    function setValue(uint256 _value) external {
        // TODO: Implement setValue
        // HINT: Simple storage write

    }

    /**
     * @notice Set data address
     */
    function setData(address _data) external {
        // TODO: Implement setData

    }

    /**
     * @notice Get current values
     */
    function getValues() external view returns (uint256, address) {
        // TODO: Return value and data

    }
}

/**
 * @notice MALICIOUS IMPLEMENTATION - Exploits storage collision
 *
 * Storage Layout (DESIGNED TO MATCH PROXY):
 * slot 0: implementation (address) - OVERWRITES PROXY'S IMPLEMENTATION!
 * slot 1: owner (address) - OVERWRITES PROXY'S OWNER!
 *
 * ATTACK VECTOR: By matching proxy's storage layout, we can overwrite critical variables
 */
contract MaliciousImplementation {
    // TODO: Add state variables that match the proxy's layout
    // HINT: These should map to proxy's implementation and owner slots
    // CRITICAL: Variable names don't matter, only positions!

    address public implementation;  // slot 0 - maps to proxy's implementation
    address public owner;          // slot 1 - maps to proxy's owner

    /**
     * @notice Takes ownership of the proxy
     * @dev This writes to slot 1, which is the proxy's owner slot!
     */
    function takeOwnership() external {
        // TODO: Implement ownership takeover
        // HINT: Setting owner here sets it in the PROXY's storage
        // QUESTION: Why does this work?

    }

    /**
     * @notice Changes the implementation address
     * @dev This writes to slot 0, which is the proxy's implementation slot!
     */
    function changeImplementation(address _newImplementation) external {
        // TODO: Implement implementation change
        // HINT: This lets you upgrade to any contract!
        // CRITICAL: This is a complete takeover

    }

    /**
     * @notice Complete takeover in one call
     * @dev Sets both implementation and owner
     */
    function pwn(address _attacker, address _newImplementation) external {
        // TODO: Implement complete takeover
        // HINT: Set both owner and implementation
        // RESULT: Attacker controls the proxy completely

    }
}

/**
 * @notice SAFE PROXY - Uses EIP-1967 storage slots
 *
 * Storage Layout:
 * Uses pseudo-random slots to avoid collision:
 * - Implementation: keccak256("eip1967.proxy.implementation") - 1
 * - Admin: keccak256("eip1967.proxy.admin") - 1
 *
 * SAFE: Implementation contracts can't accidentally overwrite these slots
 */
contract SafeProxy {
    // EIP-1967 Storage Slots
    // TODO: Define storage slot constants
    // HINT: These are computed using keccak256

    /**
     * @dev Storage slot: keccak256("eip1967.proxy.implementation") - 1
     * = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
     */
    bytes32 private constant IMPLEMENTATION_SLOT =
        bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);

    /**
     * @dev Storage slot: keccak256("eip1967.proxy.admin") - 1
     * = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
     */
    bytes32 private constant ADMIN_SLOT =
        bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);

    event Upgraded(address indexed implementation);
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);

    constructor(address _implementation, address _admin) {
        // TODO: Initialize implementation and admin
        // HINT: Use assembly to write to specific slots

    }

    /**
     * @notice Get current implementation address
     */
    function _getImplementation() private view returns (address impl) {
        // TODO: Load implementation from storage slot
        // HINT: Use assembly sload

    }

    /**
     * @notice Get current admin address
     */
    function _getAdmin() private view returns (address admin) {
        // TODO: Load admin from storage slot

    }

    /**
     * @notice Set implementation address
     */
    function _setImplementation(address _implementation) private {
        // TODO: Store implementation at specific slot
        // HINT: Use assembly sstore

    }

    /**
     * @notice Set admin address
     */
    function _setAdmin(address _admin) private {
        // TODO: Store admin at specific slot

    }

    /**
     * @notice Upgrade to new implementation
     * @dev Only admin can upgrade
     */
    function upgradeTo(address _newImplementation) external {
        // TODO: Implement upgrade with access control
        // HINT: Check admin, set implementation, emit event

    }

    /**
     * @notice Change admin
     * @dev Only current admin can change admin
     */
    function changeAdmin(address _newAdmin) external {
        // TODO: Implement admin change
        // HINT: Check current admin, set new admin, emit event

    }

    /**
     * @notice Fallback function for delegatecall
     */
    fallback() external payable {
        // TODO: Implement delegatecall
        // HINT: Similar to VulnerableProxy but load from EIP-1967 slot

    }

    receive() external payable {}
}

/**
 * @notice Safe implementation for use with SafeProxy
 */
contract SafeImplementation {
    // TODO: Add implementation storage
    // HINT: These won't collide with proxy's EIP-1967 slots

    uint256 public value;
    mapping(address => uint256) public balances;

    event ValueSet(uint256 value);
    event BalanceUpdated(address indexed user, uint256 balance);

    function setValue(uint256 _value) external {
        // TODO: Implement setValue

    }

    function setBalance(address _user, uint256 _balance) external {
        // TODO: Implement setBalance

    }

    function getStorageSlot() external pure returns (uint256) {
        // TODO: Return the storage slot for 'value'
        // HINT: It's slot 0 in normal sequential storage

    }
}

/**
 * @title Storage Inspector
 * @notice Helper contract to inspect storage slots
 */
contract StorageInspector {
    /**
     * @notice Calculate storage slot for a mapping
     * @dev slot = keccak256(abi.encode(key, position))
     */
    function getMappingSlot(address key, uint256 position) external pure returns (bytes32) {
        // TODO: Calculate mapping storage slot
        // HINT: Use keccak256(abi.encode(key, position))

    }

    /**
     * @notice Calculate storage slot for dynamic array element
     * @dev slot = keccak256(abi.encode(position)) + index
     */
    function getArraySlot(uint256 position, uint256 index) external pure returns (bytes32) {
        // TODO: Calculate array element slot
        // HINT: Base = keccak256(position), then add index

    }

    /**
     * @notice Verify EIP-1967 slots
     */
    function verifyEIP1967Slots() external pure returns (bytes32 implSlot, bytes32 adminSlot) {
        // TODO: Calculate and return EIP-1967 slots
        // HINT: keccak256("eip1967.proxy.implementation") - 1

    }
}

/**
 * KEY CONCEPTS TO UNDERSTAND:
 *
 * 1. STORAGE CONTEXT:
 *    - delegatecall executes code in caller's storage context
 *    - Storage slots are accessed by position, not variable name
 *    - slot 0 in implementation = slot 0 in proxy (dangerous!)
 *
 * 2. STORAGE COLLISION:
 *    - Occurs when proxy and implementation have different layouts
 *    - Implementation can accidentally overwrite proxy's critical variables
 *    - Can lead to ownership takeover or contract corruption
 *
 * 3. EIP-1967 SOLUTION:
 *    - Uses pseudo-random storage slots
 *    - keccak256 hash ensures no collision with sequential slots
 *    - Standard adopted by OpenZeppelin and others
 *
 * 4. ATTACK SCENARIO:
 *    - Deploy VulnerableProxy with LegitimateImplementation
 *    - Upgrade to MaliciousImplementation
 *    - Call takeOwnership() to become owner
 *    - Now attacker controls the proxy!
 *
 * 5. SAFE PATTERNS:
 *    - Use EIP-1967 slots for proxy state
 *    - Implementation storage won't collide
 *    - Proper access control on upgrade functions
 */
