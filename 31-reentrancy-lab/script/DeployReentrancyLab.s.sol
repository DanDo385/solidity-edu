// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/ReentrancyLab.sol";
import "../src/solution/ReentrancyLabSolution.sol";

/**
 * @title Deploy Project 31: Advanced Reentrancy Lab
 * @notice Deployment script for all contracts in the reentrancy lab
 */
contract DeployReentrancyLab is Script {
    // Vulnerable contracts
    VulnerableBankSolution vulnerableBank;
    VulnerableVaultSolution vulnerableVault;
    RewardsRouterSolution rewardsRouter;
    VulnerableOracleSolution vulnerableOracle;
    SimpleLenderSolution lender;
    ContractASolution contractA;
    ContractBSolution contractB;
    ContractCSolution contractC;

    // Secure contracts
    SecureBankSolution secureBank;
    SecureVaultSolution secureVault;
    SecureOracleSolution secureOracle;
    SecureContractASolution secureContractA;

    // Metrics
    AttackMetrics metrics;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== Deploying Advanced Reentrancy Lab ===");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy vulnerable contracts
        deployVulnerableContracts();

        // Deploy secure contracts
        deploySecureContracts();

        // Deploy metrics tracker
        metrics = new AttackMetrics();
        console.log("AttackMetrics deployed at:", address(metrics));

        vm.stopBroadcast();

        // Print deployment summary
        printDeploymentSummary();

        // Save deployment addresses
        saveDeploymentAddresses();
    }

    function deployVulnerableContracts() internal {
        console.log("--- Deploying Vulnerable Contracts ---");

        // 1. Multi-Function Reentrancy
        vulnerableBank = new VulnerableBankSolution();
        console.log("VulnerableBank deployed at:", address(vulnerableBank));

        // 2. Cross-Contract Reentrancy
        rewardsRouter = new RewardsRouterSolution();
        console.log("RewardsRouter deployed at:", address(rewardsRouter));

        vulnerableVault = new VulnerableVaultSolution(address(rewardsRouter));
        console.log("VulnerableVault deployed at:", address(vulnerableVault));

        // 3. Read-Only Reentrancy
        vulnerableOracle = new VulnerableOracleSolution();
        console.log("VulnerableOracle deployed at:", address(vulnerableOracle));

        lender = new SimpleLenderSolution(address(vulnerableOracle));
        console.log("SimpleLender deployed at:", address(lender));

        // 4. Multi-Hop Reentrancy
        contractC = new ContractCSolution();
        console.log("ContractC deployed at:", address(contractC));

        contractB = new ContractBSolution(address(contractC));
        console.log("ContractB deployed at:", address(contractB));

        contractA = new ContractASolution(address(contractB));
        console.log("ContractA deployed at:", address(contractA));

        console.log("");
    }

    function deploySecureContracts() internal {
        console.log("--- Deploying Secure Contracts ---");

        // 1. Secure Bank
        secureBank = new SecureBankSolution();
        console.log("SecureBank deployed at:", address(secureBank));

        // 2. Secure Vault
        secureVault = new SecureVaultSolution(address(rewardsRouter));
        console.log("SecureVault deployed at:", address(secureVault));

        // 3. Secure Oracle
        secureOracle = new SecureOracleSolution();
        console.log("SecureOracle deployed at:", address(secureOracle));

        // 4. Secure ContractA
        secureContractA = new SecureContractASolution(address(contractB));
        console.log("SecureContractA deployed at:", address(secureContractA));

        console.log("");
    }

    function printDeploymentSummary() internal view {
        console.log("=== Deployment Summary ===");
        console.log("");

        console.log("Vulnerable Contracts:");
        console.log("  1. Multi-Function Reentrancy:");
        console.log("     VulnerableBank:", address(vulnerableBank));
        console.log("");

        console.log("  2. Cross-Contract Reentrancy:");
        console.log("     VulnerableVault:", address(vulnerableVault));
        console.log("     RewardsRouter:", address(rewardsRouter));
        console.log("");

        console.log("  3. Read-Only Reentrancy:");
        console.log("     VulnerableOracle:", address(vulnerableOracle));
        console.log("     SimpleLender:", address(lender));
        console.log("");

        console.log("  4. Multi-Hop Reentrancy:");
        console.log("     ContractA:", address(contractA));
        console.log("     ContractB:", address(contractB));
        console.log("     ContractC:", address(contractC));
        console.log("");

        console.log("Secure Contracts:");
        console.log("  SecureBank:", address(secureBank));
        console.log("  SecureVault:", address(secureVault));
        console.log("  SecureOracle:", address(secureOracle));
        console.log("  SecureContractA:", address(secureContractA));
        console.log("");

        console.log("Utilities:");
        console.log("  AttackMetrics:", address(metrics));
        console.log("");

        console.log("=== Next Steps ===");
        console.log("1. Study vulnerable contracts to understand attack vectors");
        console.log("2. Deploy attacker contracts to exploit vulnerabilities");
        console.log("3. Compare with secure implementations");
        console.log("4. Run comprehensive tests: forge test -vvv");
        console.log("");
    }

    function saveDeploymentAddresses() internal {
        string memory deploymentJson = "deployments";

        // Vulnerable contracts
        vm.serializeAddress(deploymentJson, "vulnerableBank", address(vulnerableBank));
        vm.serializeAddress(deploymentJson, "vulnerableVault", address(vulnerableVault));
        vm.serializeAddress(deploymentJson, "rewardsRouter", address(rewardsRouter));
        vm.serializeAddress(deploymentJson, "vulnerableOracle", address(vulnerableOracle));
        vm.serializeAddress(deploymentJson, "lender", address(lender));
        vm.serializeAddress(deploymentJson, "contractA", address(contractA));
        vm.serializeAddress(deploymentJson, "contractB", address(contractB));
        vm.serializeAddress(deploymentJson, "contractC", address(contractC));

        // Secure contracts
        vm.serializeAddress(deploymentJson, "secureBank", address(secureBank));
        vm.serializeAddress(deploymentJson, "secureVault", address(secureVault));
        vm.serializeAddress(deploymentJson, "secureOracle", address(secureOracle));
        vm.serializeAddress(deploymentJson, "secureContractA", address(secureContractA));

        // Metrics
        string memory finalJson = vm.serializeAddress(deploymentJson, "metrics", address(metrics));

        // Write to file
        string memory filename = string.concat(
            "./deployments/project31-",
            vm.toString(block.chainid),
            ".json"
        );
        vm.writeJson(finalJson, filename);

        console.log("Deployment addresses saved to:", filename);
    }
}

/**
 * @title Deploy and Demo Script
 * @notice Deploys contracts and runs demo attacks
 */
contract DeployAndDemo is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        console.log("=== Deploying and Running Demos ===");
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy all contracts
        DeployReentrancyLab deployer = new DeployReentrancyLab();
        deployer.run();

        // Run demo attacks (if desired)
        // Note: This is just deployment, actual attacks are in tests

        vm.stopBroadcast();

        console.log("=== Deployment and Demo Complete ===");
        console.log("Run tests to see attacks in action: forge test -vvv");
    }
}

/**
 * @title Deploy Vulnerable Only
 * @notice Deploys only vulnerable contracts for security auditing practice
 */
contract DeployVulnerableOnly is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        console.log("=== Deploying Vulnerable Contracts Only ===");
        console.log("Use these for security auditing practice");
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // Multi-Function Reentrancy
        VulnerableBankSolution bank = new VulnerableBankSolution();
        console.log("VulnerableBank:", address(bank));

        // Cross-Contract Reentrancy
        RewardsRouterSolution router = new RewardsRouterSolution();
        VulnerableVaultSolution vault = new VulnerableVaultSolution(address(router));
        console.log("VulnerableVault:", address(vault));
        console.log("RewardsRouter:", address(router));

        // Read-Only Reentrancy
        VulnerableOracleSolution oracle = new VulnerableOracleSolution();
        SimpleLenderSolution lender = new SimpleLenderSolution(address(oracle));
        console.log("VulnerableOracle:", address(oracle));
        console.log("SimpleLender:", address(lender));

        // Multi-Hop
        ContractCSolution c = new ContractCSolution();
        ContractBSolution b = new ContractBSolution(address(c));
        ContractASolution a = new ContractASolution(address(b));
        console.log("ContractA:", address(a));
        console.log("ContractB:", address(b));
        console.log("ContractC:", address(c));

        vm.stopBroadcast();

        console.log("");
        console.log("=== Audit Challenge ===");
        console.log("Find and exploit all reentrancy vulnerabilities!");
    }
}

/**
 * @title Deploy Secure Only
 * @notice Deploys only secure contracts as reference implementations
 */
contract DeploySecureOnly is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        console.log("=== Deploying Secure Contracts Only ===");
        console.log("Production-ready implementations with reentrancy protection");
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy dummy router for vault
        RewardsRouterSolution router = new RewardsRouterSolution();

        // Deploy dummy contractB for contractA
        ContractCSolution c = new ContractCSolution();
        ContractBSolution b = new ContractBSolution(address(c));

        SecureBankSolution bank = new SecureBankSolution();
        console.log("SecureBank:", address(bank));

        SecureVaultSolution vault = new SecureVaultSolution(address(router));
        console.log("SecureVault:", address(vault));

        SecureOracleSolution oracle = new SecureOracleSolution();
        console.log("SecureOracle:", address(oracle));

        SecureContractASolution a = new SecureContractASolution(address(b));
        console.log("SecureContractA:", address(a));

        vm.stopBroadcast();

        console.log("");
        console.log("=== Secure Contracts Deployed ===");
        console.log("All contracts include reentrancy protection");
    }
}
