// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/solution/OverflowLabSolution.sol";

/**
 * @title Deploy Project 32: Integer Overflow Labs
 * @notice Deployment script for overflow/underflow demonstration contracts
 * @dev Deploys all contract variations for educational purposes
 *
 * Usage:
 *   forge script script/DeployOverflowLab.s.sol:DeployOverflowLab --rpc-url <RPC_URL> --broadcast
 *
 * Local deployment:
 *   forge script script/DeployOverflowLab.s.sol:DeployOverflowLab --rpc-url http://localhost:8545 --broadcast
 *
 * Dry run (simulation):
 *   forge script script/DeployOverflowLab.s.sol:DeployOverflowLab --rpc-url <RPC_URL>
 */
contract DeployOverflowLab is Script {
    // Deployment configuration
    uint256 constant INITIAL_SUPPLY = 1_000_000 ether;

    // Deployed contract addresses (saved for verification)
    VulnerableToken public vulnerableToken;
    SafeToken public safeToken;
    ModernToken public modernToken;
    UncheckedExamples public uncheckedExamples;
    AdvancedOverflowScenarios public advancedScenarios;

    function run() public {
        // Get deployer private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        console.log("========================================");
        console.log("Deploying Project 32: Integer Overflow Labs");
        console.log("========================================");
        console.log("Deployer address:", vm.addr(deployerPrivateKey));
        console.log("Chain ID:", block.chainid);
        console.log("Initial supply:", INITIAL_SUPPLY);
        console.log("");

        // Deploy VulnerableToken
        console.log("Deploying VulnerableToken...");
        vulnerableToken = new VulnerableToken(INITIAL_SUPPLY);
        console.log("VulnerableToken deployed at:", address(vulnerableToken));
        console.log("  - Simulates pre-0.8.0 behavior with unchecked");
        console.log("  - WARNING: Contains intentional vulnerabilities!");
        console.log("");

        // Deploy SafeToken
        console.log("Deploying SafeToken...");
        safeToken = new SafeToken(INITIAL_SUPPLY);
        console.log("SafeToken deployed at:", address(safeToken));
        console.log("  - Uses SafeMath library for protection");
        console.log("  - Demonstrates pre-0.8.0 best practices");
        console.log("");

        // Deploy ModernToken
        console.log("Deploying ModernToken...");
        modernToken = new ModernToken(INITIAL_SUPPLY);
        console.log("ModernToken deployed at:", address(modernToken));
        console.log("  - Uses Solidity 0.8+ automatic checks");
        console.log("  - Modern, safe by default");
        console.log("");

        // Deploy UncheckedExamples
        console.log("Deploying UncheckedExamples...");
        uncheckedExamples = new UncheckedExamples();
        console.log("UncheckedExamples deployed at:", address(uncheckedExamples));
        console.log("  - Demonstrates safe and unsafe unchecked usage");
        console.log("  - Educational examples for gas optimization");
        console.log("");

        // Deploy AdvancedOverflowScenarios
        console.log("Deploying AdvancedOverflowScenarios...");
        advancedScenarios = new AdvancedOverflowScenarios();
        console.log("AdvancedOverflowScenarios deployed at:", address(advancedScenarios));
        console.log("  - Time locks, voting, interest calculations");
        console.log("  - Advanced overflow patterns");
        console.log("");

        // Stop broadcasting
        vm.stopBroadcast();

        // Print summary
        console.log("========================================");
        console.log("Deployment Summary");
        console.log("========================================");
        console.log("All contracts deployed successfully!");
        console.log("");
        console.log("Contract Addresses:");
        console.log("  VulnerableToken:", address(vulnerableToken));
        console.log("  SafeToken:", address(safeToken));
        console.log("  ModernToken:", address(modernToken));
        console.log("  UncheckedExamples:", address(uncheckedExamples));
        console.log("  AdvancedOverflowScenarios:", address(advancedScenarios));
        console.log("");
        console.log("Next steps:");
        console.log("  1. Verify contracts on block explorer");
        console.log("  2. Test vulnerable contracts (DO NOT use in production!)");
        console.log("  3. Compare SafeMath vs Modern implementations");
        console.log("  4. Study unchecked usage patterns");
        console.log("");
        console.log("WARNING: VulnerableToken contains intentional bugs!");
        console.log("Only use for educational purposes.");
        console.log("========================================");

        // Save deployment addresses to file
        saveDeploymentInfo();
    }

    /**
     * @notice Save deployment information to a JSON file
     * @dev Useful for frontend integration and verification
     */
    function saveDeploymentInfo() internal {
        string memory json = "deployment";

        // Build JSON object
        vm.serializeAddress(json, "vulnerableToken", address(vulnerableToken));
        vm.serializeAddress(json, "safeToken", address(safeToken));
        vm.serializeAddress(json, "modernToken", address(modernToken));
        vm.serializeAddress(json, "uncheckedExamples", address(uncheckedExamples));
        vm.serializeAddress(json, "advancedScenarios", address(advancedScenarios));
        vm.serializeUint(json, "initialSupply", INITIAL_SUPPLY);
        vm.serializeUint(json, "chainId", block.chainid);
        vm.serializeUint(json, "deploymentBlock", block.number);
        string memory finalJson = vm.serializeUint(json, "timestamp", block.timestamp);

        // Write to file
        string memory fileName = string.concat(
            "deployments/project32-",
            vm.toString(block.chainid),
            ".json"
        );
        vm.writeJson(finalJson, fileName);

        console.log("Deployment info saved to:", fileName);
    }

    /**
     * @notice Demonstrate overflow exploits (for educational purposes)
     * @dev This function shows the vulnerabilities in action
     * WARNING: Do not call this in production!
     */
    function demonstrateExploits() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("========================================");
        console.log("DEMONSTRATION: Overflow Exploits");
        console.log("========================================");
        console.log("WARNING: This demonstrates VULNERABILITIES");
        console.log("DO NOT replicate in production code!");
        console.log("");

        // Exploit 1: Underflow attack
        console.log("Exploit 1: Underflow Attack");
        address attacker = vm.addr(deployerPrivateKey);
        uint256 balanceBefore = vulnerableToken.balances(attacker);
        console.log("  Balance before:", balanceBefore);

        // Create new address with 0 balance
        address victim = address(0x123);

        // Transfer from 0 balance (if we had 0)
        // This is just a demonstration - in real attack, attacker would have 0 balance
        console.log("  Attempting transfer with insufficient balance...");
        console.log("  (In real exploit, attacker has 0 balance)");
        console.log("");

        // Exploit 2: BeautyChain exploit
        console.log("Exploit 2: BeautyChain Batch Transfer");
        console.log("  Creating 2^255 tokens from nothing...");
        uint256 exploitValue = 2**255;
        address[] memory recipients = new address[](2);
        recipients[0] = address(0x456);
        recipients[1] = address(0x789);

        // This would exploit if we had vulnerable batchTransfer
        console.log("  Exploit value per recipient:", exploitValue);
        console.log("  Number of recipients:", recipients.length);
        console.log("  Total (with overflow): 0");
        console.log("");

        // Exploit 3: SMT exploit
        console.log("Exploit 3: SMT TransferProxy");
        console.log("  Bypassing balance check with overflow...");
        console.log("  Value: MAX_UINT256");
        console.log("  Fee: 1");
        console.log("  Total (with overflow): 0");
        console.log("");

        console.log("========================================");
        console.log("For full exploit demonstrations, run:");
        console.log("  forge test --match-test testBeautyChainExploit -vvv");
        console.log("  forge test --match-test testSMTExploit -vvv");
        console.log("  forge test --match-test testVulnerableTransferUnderflow -vvv");
        console.log("========================================");

        vm.stopBroadcast();
    }

    /**
     * @notice Compare gas costs between SafeMath and Modern (0.8+)
     * @dev Educational demonstration of gas efficiency improvements
     */
    function compareGasCosts() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("========================================");
        console.log("Gas Cost Comparison");
        console.log("========================================");

        address recipient = address(0x999);
        uint256 transferAmount = 100 ether;

        // SafeMath transfer
        console.log("SafeMath Transfer:");
        uint256 gasBefore1 = gasleft();
        safeToken.transfer(recipient, transferAmount);
        uint256 gasUsed1 = gasBefore1 - gasleft();
        console.log("  Gas used:", gasUsed1);

        // Modern transfer
        console.log("Modern (0.8+) Transfer:");
        uint256 gasBefore2 = gasleft();
        modernToken.transfer(recipient, transferAmount);
        uint256 gasUsed2 = gasBefore2 - gasleft();
        console.log("  Gas used:", gasUsed2);

        console.log("");
        if (gasUsed2 < gasUsed1) {
            console.log("Modern version saves:", gasUsed1 - gasUsed2, "gas");
            console.log("Improvement:", ((gasUsed1 - gasUsed2) * 100) / gasUsed1, "%");
        } else {
            console.log("Both versions have similar gas costs");
        }

        console.log("========================================");

        vm.stopBroadcast();
    }
}

/**
 * @title Deploy to Local Network
 * @notice Deployment script for local testing with Anvil
 */
contract DeployLocal is Script {
    function run() public {
        // For local deployment, use default Anvil account
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying to local network...");

        uint256 initialSupply = 1_000_000 ether;

        VulnerableToken vulnerableToken = new VulnerableToken(initialSupply);
        SafeToken safeToken = new SafeToken(initialSupply);
        ModernToken modernToken = new ModernToken(initialSupply);
        UncheckedExamples uncheckedExamples = new UncheckedExamples();
        AdvancedOverflowScenarios advancedScenarios = new AdvancedOverflowScenarios();

        console.log("Local deployment complete!");
        console.log("VulnerableToken:", address(vulnerableToken));
        console.log("SafeToken:", address(safeToken));
        console.log("ModernToken:", address(modernToken));
        console.log("UncheckedExamples:", address(uncheckedExamples));
        console.log("AdvancedOverflowScenarios:", address(advancedScenarios));

        vm.stopBroadcast();
    }
}
