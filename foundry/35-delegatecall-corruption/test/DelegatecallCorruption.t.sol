// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/DelegatecallCorruptionSolution.sol";

/**
 * @title Project 35 Tests: Delegatecall Storage Corruption
 * @notice Comprehensive tests demonstrating vulnerabilities and safe patterns
 */
contract DelegatecallCorruptionTest is Test {
    VulnerableProxy public vulnerableProxy;
    LegitimateImplementation public legitImpl;
    MaliciousImplementation public maliciousImpl;
    SafeImplementation public maliciousSafeImpl;

    SafeProxy public safeProxy;
    SafeImplementation public safeImpl;

    StorageInspector public inspector;

    address public owner = address(1);
    address public attacker = address(2);
    address public user = address(3);

    // Events to test
    event Pwned(address indexed attacker);
    event Upgraded(address indexed implementation);
    event ValueSet(uint256 value);

    function setUp() public {
        vm.deal(owner, 100 ether);
        vm.deal(attacker, 10 ether);

        // Deploy legitimate implementation
        legitImpl = new LegitimateImplementation();

        // Deploy vulnerable proxy with legitimate implementation
        vm.prank(owner);
        vulnerableProxy = new VulnerableProxy(address(legitImpl));

        // Deploy malicious implementation
        maliciousImpl = new MaliciousImplementation();

        // Deploy safe proxy and implementation
        safeImpl = new SafeImplementation();
        vm.prank(owner);
        safeProxy = new SafeProxy(address(safeImpl), owner);

        // Deploy storage inspector
        inspector = new StorageInspector();
    }

    /**
     * TEST SUITE 1: VULNERABLE PROXY - STORAGE CORRUPTION
     */

    function testVulnerableProxyInitialState() public view {
        assertEq(vulnerableProxy.implementation(), address(legitImpl));
        assertEq(vulnerableProxy.owner(), owner);
    }

    function testLegitimateImplementationWorks() public {
        // Call setValue through proxy
        LegitimateImplementation(address(vulnerableProxy)).setValue(42);

        // Check value was set
        (uint256 value, ) = LegitimateImplementation(address(vulnerableProxy)).getValues();
        assertEq(value, 42);
    }

    function testStorageCorruptionWithLegitImplementation() public {
        // When we call setValue, it writes to slot 0
        // slot 0 in proxy is the implementation address!

        address originalImpl = vulnerableProxy.implementation();

        // Set value to a number that looks like an address
        uint256 fakeAddress = uint256(uint160(address(0x1234)));
        LegitimateImplementation(address(vulnerableProxy)).setValue(fakeAddress);

        // Check if implementation was corrupted
        address newImpl = vulnerableProxy.implementation();

        // The implementation address should have changed (corrupted)
        assertTrue(newImpl != originalImpl, "Implementation should be corrupted");
        assertEq(uint160(newImpl), uint160(fakeAddress), "Implementation corrupted to our value");
    }

    function testMaliciousTakeOwnership() public {
        // First, owner upgrades to malicious implementation (unknowingly)
        vm.prank(owner);
        vulnerableProxy.upgrade(address(maliciousImpl));

        // Verify upgrade
        assertEq(vulnerableProxy.implementation(), address(maliciousImpl));

        // Attacker calls takeOwnership through proxy
        vm.prank(attacker);
        vm.expectEmit(true, false, false, false);
        emit Pwned(attacker);
        MaliciousImplementation(address(vulnerableProxy)).takeOwnership();

        // Attacker is now the owner!
        assertEq(vulnerableProxy.owner(), attacker, "Attacker should be owner");
        assertTrue(vulnerableProxy.owner() != owner, "Original owner should be replaced");
    }

    function testMaliciousChangeImplementation() public {
        // Setup: upgrade to malicious impl and take ownership
        vm.prank(owner);
        vulnerableProxy.upgrade(address(maliciousImpl));

        vm.prank(attacker);
        MaliciousImplementation(address(vulnerableProxy)).takeOwnership();

        // Now attacker can change implementation to anything
        address evilImpl = address(0xDEAD);

        vm.prank(attacker);
        MaliciousImplementation(address(vulnerableProxy)).changeImplementation(evilImpl);

        assertEq(vulnerableProxy.implementation(), evilImpl, "Implementation should be changed");
    }

    function testCompletePwnAttack() public {
        // Deploy a completely attacker-controlled implementation
        MaliciousImplementation attackerImpl = new MaliciousImplementation();

        // Owner upgrades to malicious implementation
        vm.prank(owner);
        vulnerableProxy.upgrade(address(maliciousImpl));

        // Attacker performs complete takeover in one call
        vm.prank(attacker);
        MaliciousImplementation(address(vulnerableProxy)).pwn(attacker, address(attackerImpl));

        // Verify complete control
        assertEq(vulnerableProxy.owner(), attacker, "Attacker is owner");
        assertEq(vulnerableProxy.implementation(), address(attackerImpl), "Attacker controls implementation");
    }

    function testDrainFundsAfterTakeover() public {
        // Send ETH to proxy
        vm.deal(address(vulnerableProxy), 50 ether);

        // Upgrade to malicious implementation
        vm.prank(owner);
        vulnerableProxy.upgrade(address(maliciousImpl));

        // Take ownership
        vm.prank(attacker);
        MaliciousImplementation(address(vulnerableProxy)).takeOwnership();

        // Record attacker balance before
        uint256 attackerBalanceBefore = attacker.balance;

        // Drain funds
        vm.prank(attacker);
        MaliciousImplementation(address(vulnerableProxy)).drain();

        // Verify funds drained
        assertEq(address(vulnerableProxy).balance, 0, "Proxy should be drained");
        assertEq(attacker.balance, attackerBalanceBefore + 50 ether, "Attacker should receive funds");
    }

    function testCannotUpgradeAfterOwnershipTakeover() public {
        // Upgrade to malicious implementation
        vm.prank(owner);
        vulnerableProxy.upgrade(address(maliciousImpl));

        // Attacker takes ownership
        vm.prank(attacker);
        MaliciousImplementation(address(vulnerableProxy)).takeOwnership();

        // Original owner can no longer upgrade
        vm.prank(owner);
        vm.expectRevert("Not owner");
        vulnerableProxy.upgrade(address(legitImpl));

        // But attacker can
        vm.prank(attacker);
        vulnerableProxy.upgrade(address(0x1234));
        assertEq(vulnerableProxy.implementation(), address(0x1234));
    }

    /**
     * TEST SUITE 2: SAFE PROXY - EIP-1967
     */

    function testSafeProxyInitialState() public view {
        assertEq(safeProxy.implementation(), address(safeImpl));
        assertEq(safeProxy.admin(), owner);
    }

    function testEIP1967SlotCalculation() public view {
        (bytes32 implSlot, bytes32 adminSlot) = inspector.verifyEIP1967Slots();

        // Verify against known EIP-1967 values
        assertEq(
            implSlot,
            0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc,
            "Implementation slot mismatch"
        );
        assertEq(
            adminSlot,
            0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103,
            "Admin slot mismatch"
        );
    }

    function testSafeProxyStorageSlots() public {
        // Load storage at EIP-1967 slots
        bytes32 implSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        bytes32 adminSlot = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

        address storedImpl = address(uint160(uint256(vm.load(address(safeProxy), implSlot))));
        address storedAdmin = address(uint160(uint256(vm.load(address(safeProxy), adminSlot))));

        assertEq(storedImpl, address(safeImpl), "Implementation should be in EIP-1967 slot");
        assertEq(storedAdmin, owner, "Admin should be in EIP-1967 slot");
    }

    function testSafeProxyNoStorageCollision() public {
        // Initialize implementation through proxy
        SafeImplementation(address(safeProxy)).initialize(owner);

        // Set value through proxy
        vm.prank(owner);
        SafeImplementation(address(safeProxy)).setValue(12345);

        // Verify value was set in implementation storage (slot 0)
        uint256 value = SafeImplementation(address(safeProxy)).value();
        assertEq(value, 12345, "Value should be set");

        // Verify proxy's implementation is unchanged (stored in EIP-1967 slot, not slot 0)
        assertEq(safeProxy.implementation(), address(safeImpl), "Implementation should be unchanged");
        assertEq(safeProxy.admin(), owner, "Admin should be unchanged");
    }

    function testSafeProxyUpgrade() public {
        // Deploy new implementation
        SafeImplementation newImpl = new SafeImplementation();

        // Only admin can upgrade
        vm.prank(attacker);
        vm.expectRevert("Not admin");
        safeProxy.upgradeTo(address(newImpl));

        // Admin can upgrade
        vm.prank(owner);
        vm.expectEmit(true, false, false, false);
        emit Upgraded(address(newImpl));
        safeProxy.upgradeTo(address(newImpl));

        assertEq(safeProxy.implementation(), address(newImpl), "Should upgrade");
    }

    function testSafeProxyChangeAdmin() public {
        address newAdmin = address(0x999);

        // Only admin can change admin
        vm.prank(attacker);
        vm.expectRevert("Not admin");
        safeProxy.changeAdmin(newAdmin);

        // Admin can change admin
        vm.prank(owner);
        safeProxy.changeAdmin(newAdmin);

        assertEq(safeProxy.admin(), newAdmin, "Admin should be changed");

        // Old admin can no longer upgrade
        vm.prank(owner);
        vm.expectRevert("Not admin");
        safeProxy.upgradeTo(address(0x123));
    }

    function testSafeImplementationCannotCorruptProxy() public {
        // Initialize
        SafeImplementation(address(safeProxy)).initialize(owner);

        // Deploy malicious safe implementation that tries to corrupt
        maliciousSafeImpl = new SafeImplementation();

        // Upgrade to "malicious" implementation
        vm.prank(owner);
        safeProxy.upgradeTo(address(maliciousSafeImpl));

        // Try to set values that would corrupt if storage collided
        SafeImplementation(address(safeProxy)).initialize(attacker);

        // Verify proxy state is unchanged
        assertEq(safeProxy.admin(), owner, "Admin should be unchanged");
        assertEq(safeProxy.implementation(), address(maliciousSafeImpl), "Implementation should be new");

        // The "corruption" only affects implementation storage, not proxy
        assertEq(SafeImplementation(address(safeProxy)).owner(), attacker, "Owner set in implementation");
    }

    /**
     * TEST SUITE 3: STORAGE SLOT CALCULATIONS
     */

    function testMappingSlotCalculation() public view {
        address testKey = address(0x123);
        uint256 position = 1; // mapping is at slot 1

        bytes32 slot = inspector.getMappingSlot(testKey, position);
        bytes32 expected = keccak256(abi.encode(testKey, position));

        assertEq(slot, expected, "Mapping slot calculation should match");
    }

    function testArraySlotCalculation() public view {
        uint256 position = 2; // array is at slot 2
        uint256 index = 5;

        bytes32 slot = inspector.getArraySlot(position, index);
        bytes32 baseSlot = keccak256(abi.encode(position));
        bytes32 expected = bytes32(uint256(baseSlot) + index);

        assertEq(slot, expected, "Array slot calculation should match");
    }

    function testStorageSlotVerification() public {
        // Initialize safe implementation
        SafeImplementation(address(safeProxy)).initialize(owner);

        // Set a balance
        vm.prank(owner);
        SafeImplementation(address(safeProxy)).setBalance(user, 1000);

        // Calculate expected storage slot for balance
        bytes32 balanceSlot = SafeImplementation(address(safeProxy)).getBalanceSlot(user);

        // Load from storage
        uint256 storedBalance = uint256(vm.load(address(safeProxy), balanceSlot));

        assertEq(storedBalance, 1000, "Balance should be at calculated slot");
    }

    function testSequentialStorageLayout() public {
        // Deploy a fresh implementation through proxy
        SafeImplementation(address(safeProxy)).initialize(owner);

        // Set value (slot 0)
        vm.prank(owner);
        SafeImplementation(address(safeProxy)).setValue(42);

        // Load slot 0 from proxy's storage
        uint256 slot0 = uint256(vm.load(address(safeProxy), bytes32(uint256(0))));
        assertEq(slot0, 42, "Value should be at slot 0");

        // Slot 1 is the mapping position marker
        uint256 slot1 = uint256(vm.load(address(safeProxy), bytes32(uint256(1))));
        assertEq(slot1, 0, "Slot 1 should be empty (mapping position)");

        // Slot 2 has initialized (bool) and owner (address) packed
        bytes32 slot2 = vm.load(address(safeProxy), bytes32(uint256(2)));

        // Extract initialized (first byte)
        uint8 initialized = uint8(uint256(slot2) & 0xFF);
        assertEq(initialized, 1, "Initialized should be true");
    }

    /**
     * TEST SUITE 4: PARITY WALLET SIMULATION
     */

    function testParityWalletVulnerability() public {
        // Deploy library and wallet
        ParityWalletLibrary library = new ParityWalletLibrary();
        ParityWallet wallet = new ParityWallet(address(library));

        // Fund the wallet
        vm.deal(address(wallet), 100 ether);

        // Attacker calls initWallet through wallet's fallback
        vm.prank(attacker);
        (bool success, ) = address(wallet).call(
            abi.encodeWithSignature("initWallet(address)", attacker)
        );
        assertTrue(success, "Init should succeed");

        // Check if attacker became owner in wallet's storage
        // The owner is at slot 0 in library, maps to wallet's slot 0
        address walletOwner = address(uint160(uint256(vm.load(address(wallet), bytes32(uint256(0))))));

        // Due to delegatecall, attacker is now owner in wallet's context
        assertEq(walletOwner, attacker, "Attacker should be owner of wallet");
    }

    /**
     * TEST SUITE 5: EDGE CASES AND SECURITY
     */

    function testCannotUpgradeToZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert("Invalid implementation");
        vulnerableProxy.upgrade(address(0));

        vm.prank(owner);
        vm.expectRevert("Invalid implementation");
        safeProxy.upgradeTo(address(0));
    }

    function testCannotInitializeSafeProxyWithZeroAddresses() public {
        vm.expectRevert("Invalid implementation");
        new SafeProxy(address(0), owner);

        vm.expectRevert("Invalid admin");
        new SafeProxy(address(safeImpl), address(0));
    }

    function testSafeProxyReceivesEther() public {
        vm.deal(user, 10 ether);

        vm.prank(user);
        (bool success, ) = address(safeProxy).call{value: 5 ether}("");
        assertTrue(success, "Should receive ether");
        assertEq(address(safeProxy).balance, 5 ether);
    }

    function testVulnerableProxyReceivesEther() public {
        vm.deal(user, 10 ether);

        vm.prank(user);
        (bool success, ) = address(vulnerableProxy).call{value: 5 ether}("");
        assertTrue(success, "Should receive ether");
        assertEq(address(vulnerableProxy).balance, 5 ether);
    }

    function testDelegatecallPreservesMessageSender() public {
        // Initialize safe implementation
        SafeImplementation(address(safeProxy)).initialize(owner);

        // When we call through proxy, msg.sender should be preserved
        vm.prank(attacker);
        vm.expectRevert("Not owner"); // Because msg.sender is attacker, not owner
        SafeImplementation(address(safeProxy)).setValue(100);

        // Owner can call
        vm.prank(owner);
        SafeImplementation(address(safeProxy)).setValue(100);
        assertEq(SafeImplementation(address(safeProxy)).value(), 100);
    }

    /**
     * TEST SUITE 6: GAS OPTIMIZATION AND EFFICIENCY
     */

    function testEIP1967SlotAccessGas() public {
        // Test gas cost of accessing EIP-1967 slots
        uint256 gasBefore = gasleft();
        safeProxy.implementation();
        uint256 gasAfter = gasleft();
        uint256 gasUsed = gasBefore - gasAfter;

        // Should be relatively cheap (one SLOAD)
        assertTrue(gasUsed < 5000, "Slot access should be cheap");
    }

    /**
     * HELPER FUNCTIONS
     */

    function testStorageInspectorHelpers() public view {
        // Test all helper functions work
        inspector.getMappingSlot(address(1), 0);
        inspector.getArraySlot(0, 0);
        inspector.verifyEIP1967Slots();
        inspector.getBeaconSlot();
        inspector.demonstrateStoragePacking();
    }
}
