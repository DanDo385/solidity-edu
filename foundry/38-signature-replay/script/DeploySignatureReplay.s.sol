// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/solution/SignatureReplaySolution.sol";

/**
 * @title Deploy Project 38: Signature Replay Attack
 * @notice Deployment script for signature replay vulnerability contracts
 */
contract DeploySignatureReplay is Script {
    // Deployed contracts
    VulnerableBankSolution public vulnerableBank;
    ReplayAttackerSolution public replayAttacker;
    SecureBankSolution public secureBank;
    CrossChainVulnerableSolution public crossChainVuln;
    CrossChainSecureSolution public crossChainSecure;
    EIP712SecureBankSolution public eip712Bank;
    AdvancedSecureBankSolution public advancedBank;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy vulnerable implementations
        console.log("Deploying vulnerable implementations...");
        vulnerableBank = new VulnerableBankSolution();
        console.log("VulnerableBank deployed at:", address(vulnerableBank));

        replayAttacker = new ReplayAttackerSolution(address(vulnerableBank));
        console.log("ReplayAttacker deployed at:", address(replayAttacker));

        crossChainVuln = new CrossChainVulnerableSolution();
        console.log("CrossChainVulnerable deployed at:", address(crossChainVuln));

        // Deploy secure implementations
        console.log("\nDeploying secure implementations...");
        secureBank = new SecureBankSolution();
        console.log("SecureBank deployed at:", address(secureBank));

        crossChainSecure = new CrossChainSecureSolution();
        console.log("CrossChainSecure deployed at:", address(crossChainSecure));

        eip712Bank = new EIP712SecureBankSolution();
        console.log("EIP712SecureBank deployed at:", address(eip712Bank));
        console.log("  Domain Separator:", vm.toString(eip712Bank.DOMAIN_SEPARATOR()));

        advancedBank = new AdvancedSecureBankSolution();
        console.log("AdvancedSecureBank deployed at:", address(advancedBank));
        console.log("  Domain Separator:", vm.toString(advancedBank.DOMAIN_SEPARATOR()));

        vm.stopBroadcast();

        // Log deployment summary
        console.log("\n=== Deployment Summary ===");
        console.log("Chain ID:", block.chainid);
        console.log("Deployer:", vm.addr(deployerPrivateKey));

        console.log("\nVulnerable Contracts (for educational purposes):");
        console.log("  VulnerableBank:", address(vulnerableBank));
        console.log("  ReplayAttacker:", address(replayAttacker));
        console.log("  CrossChainVulnerable:", address(crossChainVuln));

        console.log("\nSecure Contracts (best practices):");
        console.log("  SecureBank (nonce):", address(secureBank));
        console.log("  CrossChainSecure (chainID):", address(crossChainSecure));
        console.log("  EIP712SecureBank:", address(eip712Bank));
        console.log("  AdvancedSecureBank:", address(advancedBank));

        // Save deployment addresses
        saveDeployment();
    }

    function saveDeployment() internal {
        string memory json = "deployment";

        vm.serializeAddress(json, "vulnerableBank", address(vulnerableBank));
        vm.serializeAddress(json, "replayAttacker", address(replayAttacker));
        vm.serializeAddress(json, "crossChainVuln", address(crossChainVuln));
        vm.serializeAddress(json, "secureBank", address(secureBank));
        vm.serializeAddress(json, "crossChainSecure", address(crossChainSecure));
        vm.serializeAddress(json, "eip712Bank", address(eip712Bank));
        string memory finalJson = vm.serializeAddress(json, "advancedBank", address(advancedBank));

        string memory chainIdStr = vm.toString(block.chainid);
        string memory filename = string.concat(
            "./deployments/deployment-",
            chainIdStr,
            ".json"
        );

        vm.writeJson(finalJson, filename);
        console.log("\nDeployment addresses saved to:", filename);
    }

    /**
     * @notice Deploy only vulnerable contracts for testing
     */
    function deployVulnerableOnly() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        vulnerableBank = new VulnerableBankSolution();
        replayAttacker = new ReplayAttackerSolution(address(vulnerableBank));

        console.log("VulnerableBank:", address(vulnerableBank));
        console.log("ReplayAttacker:", address(replayAttacker));

        vm.stopBroadcast();
    }

    /**
     * @notice Deploy only secure contracts for production
     */
    function deploySecureOnly() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        secureBank = new SecureBankSolution();
        eip712Bank = new EIP712SecureBankSolution();
        advancedBank = new AdvancedSecureBankSolution();

        console.log("SecureBank:", address(secureBank));
        console.log("EIP712Bank:", address(eip712Bank));
        console.log("AdvancedBank:", address(advancedBank));

        vm.stopBroadcast();
    }
}

/**
 * @title Demonstration Script
 * @notice Script to demonstrate replay attack and protections
 */
contract DemonstrateReplayAttack is Script {
    VulnerableBankSolution public vulnerableBank;
    ReplayAttackerSolution public replayAttacker;

    function run() external {
        // Load deployed contracts
        vulnerableBank = VulnerableBankSolution(payable(vm.envAddress("VULNERABLE_BANK")));
        replayAttacker = ReplayAttackerSolution(payable(vm.envAddress("REPLAY_ATTACKER")));

        uint256 victimKey = vm.envUint("VICTIM_PRIVATE_KEY");
        address victim = vm.addr(victimKey);

        console.log("\n=== Demonstrating Replay Attack ===");
        console.log("Victim:", victim);
        console.log("VulnerableBank:", address(vulnerableBank));

        // Victim deposits
        vm.startBroadcast(victimKey);
        vulnerableBank.deposit{value: 5 ether}();
        console.log("Victim deposited: 5 ETH");
        console.log("Victim balance:", vulnerableBank.balances(victim));

        // Victim creates signature for 1 ETH withdrawal
        uint256 amount = 1 ether;
        bytes32 messageHash = keccak256(abi.encodePacked(amount));
        bytes32 ethSignedMessageHash = vulnerableBank.getEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(victimKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        console.log("\nVictim created signature for 1 ETH withdrawal");
        vm.stopBroadcast();

        // Attacker executes replay attack
        uint256 attackerKey = vm.envUint("ATTACKER_PRIVATE_KEY");
        vm.startBroadcast(attackerKey);

        console.log("\nAttacker replaying signature 3 times...");
        replayAttacker.attack(amount, signature, 3);

        console.log("Attack complete!");
        console.log("Victim balance after attack:", vulnerableBank.balances(victim));
        console.log("Attacker stole:", replayAttacker.stolenAmount());

        vm.stopBroadcast();
    }
}

/**
 * @title EIP-712 Signing Helper
 * @notice Helper script for creating EIP-712 signatures
 */
contract EIP712SigningHelper is Script {
    EIP712SecureBankSolution public bank;

    function run() external view {
        bank = EIP712SecureBankSolution(payable(vm.envAddress("EIP712_BANK")));

        address from = vm.envAddress("FROM_ADDRESS");
        address to = vm.envAddress("TO_ADDRESS");
        uint256 amount = vm.envUint("AMOUNT");
        uint256 nonce = bank.nonces(from);

        console.log("\n=== EIP-712 Signature Helper ===");
        console.log("Bank:", address(bank));
        console.log("From:", from);
        console.log("To:", to);
        console.log("Amount:", amount);
        console.log("Nonce:", nonce);

        // Get digest
        bytes32 digest = bank.getTransferDigest(from, to, amount, nonce);
        console.log("\nDigest to sign:");
        console.log(vm.toString(digest));

        console.log("\nDomain Separator:");
        console.log(vm.toString(bank.DOMAIN_SEPARATOR()));

        console.log("\nTransfer TypeHash:");
        console.log(vm.toString(bank.TRANSFER_TYPEHASH()));

        console.log("\nUse this digest to create signature off-chain");
        console.log("Chain ID:", block.chainid);
    }
}
