// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/solution/Project37Solution.sol";

/**
 * @title DeployProject37
 * @notice Deployment script for Gas DoS Attacks project
 * @dev Deploys both vulnerable and safe contract examples
 */
contract DeployProject37 is Script {
    // Vulnerable contracts
    VulnerableAirdrop public vulnerableAirdrop;
    VulnerableAuction public vulnerableAuction;
    VulnerableMassPayment public vulnerableMassPayment;
    ExpensiveFallbackRecipient public expensiveFallback;
    VulnerableDistributor public vulnerableDistributor;

    // Safe contracts
    SafeAirdropWithPagination public safeAirdrop;
    SafeAuctionWithPullPayments public safeAuction;
    SafeMassPaymentWithPull public safeMassPayment;
    SafeDistributorHybrid public safeDistributor;

    // Attack contracts
    MaliciousBidder public maliciousBidder;
    GriefingAttacker public griefingAttacker;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying from:", deployer);
        console.log("Deployer balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy vulnerable contracts
        console.log("\n=== Deploying Vulnerable Contracts ===");

        vulnerableAirdrop = new VulnerableAirdrop();
        console.log("VulnerableAirdrop deployed at:", address(vulnerableAirdrop));

        vulnerableAuction = new VulnerableAuction(7 days);
        console.log("VulnerableAuction deployed at:", address(vulnerableAuction));

        vulnerableMassPayment = new VulnerableMassPayment();
        console.log("VulnerableMassPayment deployed at:", address(vulnerableMassPayment));

        expensiveFallback = new ExpensiveFallbackRecipient();
        console.log("ExpensiveFallbackRecipient deployed at:", address(expensiveFallback));

        vulnerableDistributor = new VulnerableDistributor();
        console.log("VulnerableDistributor deployed at:", address(vulnerableDistributor));

        // Deploy attack contracts
        console.log("\n=== Deploying Attack Contracts ===");

        maliciousBidder = new MaliciousBidder(address(vulnerableAuction));
        console.log("MaliciousBidder deployed at:", address(maliciousBidder));

        griefingAttacker = new GriefingAttacker();
        console.log("GriefingAttacker deployed at:", address(griefingAttacker));

        // Deploy safe contracts
        console.log("\n=== Deploying Safe Contracts ===");

        safeAirdrop = new SafeAirdropWithPagination();
        console.log("SafeAirdropWithPagination deployed at:", address(safeAirdrop));

        safeAuction = new SafeAuctionWithPullPayments(7 days);
        console.log("SafeAuctionWithPullPayments deployed at:", address(safeAuction));

        safeMassPayment = new SafeMassPaymentWithPull();
        console.log("SafeMassPaymentWithPull deployed at:", address(safeMassPayment));

        safeDistributor = new SafeDistributorHybrid();
        console.log("SafeDistributorHybrid deployed at:", address(safeDistributor));

        vm.stopBroadcast();

        // Log summary
        console.log("\n=== Deployment Summary ===");
        console.log("Total contracts deployed: 11");
        console.log("Vulnerable contracts: 5");
        console.log("Attack contracts: 2");
        console.log("Safe contracts: 4");

        // Save deployment addresses to file
        saveDeploymentInfo();
    }

    /**
     * @notice Deploy with some initial setup for demonstration
     */
    function runWithSetup() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy contracts
        vulnerableAirdrop = new VulnerableAirdrop();
        vulnerableAuction = new VulnerableAuction(7 days);
        safeAirdrop = new SafeAirdropWithPagination();
        safeAuction = new SafeAuctionWithPullPayments(7 days);

        console.log("\n=== Setting Up Demonstration Scenarios ===");

        // Fund airdrop contracts
        payable(address(vulnerableAirdrop)).transfer(10 ether);
        payable(address(safeAirdrop)).transfer(10 ether);
        console.log("Funded airdrop contracts with 10 ETH each");

        // Add some initial recipients
        address[] memory initialRecipients = new address[](5);
        initialRecipients[0] = 0x1111111111111111111111111111111111111111;
        initialRecipients[1] = 0x2222222222222222222222222222222222222222;
        initialRecipients[2] = 0x3333333333333333333333333333333333333333;
        initialRecipients[3] = 0x4444444444444444444444444444444444444444;
        initialRecipients[4] = 0x5555555555555555555555555555555555555555;

        for (uint256 i = 0; i < initialRecipients.length; i++) {
            vulnerableAirdrop.addRecipient(initialRecipients[i]);
            safeAirdrop.addRecipient(initialRecipients[i]);
        }
        console.log("Added 5 initial recipients to airdrop contracts");

        vm.stopBroadcast();

        console.log("\n=== Setup Complete ===");
        console.log("Ready for demonstration");
    }

    /**
     * @notice Demonstrate the unbounded loop DoS attack
     */
    function demonstrateUnboundedLoopDoS() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        vulnerableAirdrop = new VulnerableAirdrop();
        payable(address(vulnerableAirdrop)).transfer(100 ether);

        console.log("\n=== Demonstrating Unbounded Loop DoS ===");

        // Add many recipients to demonstrate gas growth
        uint256[] memory counts = new uint256[](4);
        counts[0] = 10;
        counts[1] = 50;
        counts[2] = 100;
        counts[3] = 200;

        for (uint256 j = 0; j < counts.length; j++) {
            VulnerableAirdrop testAirdrop = new VulnerableAirdrop();
            payable(address(testAirdrop)).transfer(100 ether);

            uint256 count = counts[j];

            for (uint256 i = 0; i < count; i++) {
                testAirdrop.addRecipient(address(uint160(i + 1)));
            }

            uint256 gasBefore = gasleft();
            testAirdrop.distributeAirdrop();
            uint256 gasUsed = gasBefore - gasleft();

            console.log("Recipients:", count, "| Gas used:", gasUsed);
        }

        vm.stopBroadcast();
    }

    /**
     * @notice Demonstrate auction DoS attack
     */
    function demonstrateAuctionDoS() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        vulnerableAuction = new VulnerableAuction(7 days);
        maliciousBidder = new MaliciousBidder(address(vulnerableAuction));

        console.log("\n=== Demonstrating Auction DoS ===");

        // Normal bid
        vulnerableAuction.bid{value: 1 ether}();
        console.log("Normal bid placed: 1 ETH");

        // Malicious bid
        payable(address(maliciousBidder)).transfer(2 ether);
        maliciousBidder.attack{value: 2 ether}();
        console.log("Malicious bid placed: 2 ETH");
        console.log("Highest bidder is now:", vulnerableAuction.highestBidder());

        // Try to outbid - will fail
        console.log("\nAttempting to place higher bid...");
        console.log("This will fail due to malicious receive() function");

        vm.stopBroadcast();
    }

    /**
     * @notice Demonstrate safe implementations
     */
    function demonstrateSafeImplementations() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        safeAirdrop = new SafeAirdropWithPagination();
        safeAuction = new SafeAuctionWithPullPayments(7 days);
        safeMassPayment = new SafeMassPaymentWithPull();

        console.log("\n=== Demonstrating Safe Implementations ===");

        // Fund contracts
        payable(address(safeAirdrop)).transfer(50 ether);

        // Add recipients
        for (uint256 i = 0; i < 100; i++) {
            safeAirdrop.addRecipient(address(uint160(i + 1)));
        }
        console.log("Added 100 recipients to safe airdrop");

        // Process in batches
        console.log("\nProcessing in batches of 50:");

        uint256 gas1 = gasleft();
        safeAirdrop.distributeBatch(0, 50);
        console.log("Batch 1 gas used:", gas1 - gasleft());

        uint256 gas2 = gasleft();
        safeAirdrop.distributeBatch(50, 100);
        console.log("Batch 2 gas used:", gas2 - gasleft());

        console.log("\nSafe auction with pull payments:");
        safeAuction.bid{value: 1 ether}();
        console.log("Bid placed successfully");
        console.log("Pending returns can be withdrawn anytime");

        vm.stopBroadcast();
    }

    /**
     * @notice Save deployment information to a file
     */
    function saveDeploymentInfo() internal {
        string memory deploymentInfo = string.concat(
            "# Project 37: Gas DoS Attacks - Deployment Addresses\n\n",
            "## Vulnerable Contracts\n",
            "- VulnerableAirdrop: ",
            vm.toString(address(vulnerableAirdrop)),
            "\n",
            "- VulnerableAuction: ",
            vm.toString(address(vulnerableAuction)),
            "\n",
            "- VulnerableMassPayment: ",
            vm.toString(address(vulnerableMassPayment)),
            "\n",
            "- ExpensiveFallbackRecipient: ",
            vm.toString(address(expensiveFallback)),
            "\n",
            "- VulnerableDistributor: ",
            vm.toString(address(vulnerableDistributor)),
            "\n\n",
            "## Attack Contracts\n",
            "- MaliciousBidder: ",
            vm.toString(address(maliciousBidder)),
            "\n",
            "- GriefingAttacker: ",
            vm.toString(address(griefingAttacker)),
            "\n\n",
            "## Safe Contracts\n",
            "- SafeAirdropWithPagination: ",
            vm.toString(address(safeAirdrop)),
            "\n",
            "- SafeAuctionWithPullPayments: ",
            vm.toString(address(safeAuction)),
            "\n",
            "- SafeMassPaymentWithPull: ",
            vm.toString(address(safeMassPayment)),
            "\n",
            "- SafeDistributorHybrid: ",
            vm.toString(address(safeDistributor)),
            "\n"
        );

        vm.writeFile("deployment-addresses.txt", deploymentInfo);
        console.log("\nDeployment addresses saved to deployment-addresses.txt");
    }
}
