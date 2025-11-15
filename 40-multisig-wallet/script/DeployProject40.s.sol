// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/solution/Project40Solution.sol";

/**
 * @title Deploy Multi-Sig Wallet Script
 * @notice Deployment script for the Multi-Signature Wallet
 * @dev Supports multiple deployment configurations
 *
 * Usage:
 * forge script script/DeployProject40.s.sol:DeployProject40 --rpc-url <RPC_URL> --broadcast
 *
 * Environment Variables:
 * - OWNER_1: First owner address (required)
 * - OWNER_2: Second owner address (required)
 * - OWNER_3: Third owner address (optional)
 * - OWNER_4: Fourth owner address (optional)
 * - OWNER_5: Fifth owner address (optional)
 * - THRESHOLD: Minimum confirmations required (required)
 * - INITIAL_DEPOSIT: Initial ETH to deposit (optional, default: 0)
 *
 * Example .env file:
 * OWNER_1=0x1234...
 * OWNER_2=0x5678...
 * OWNER_3=0x9abc...
 * THRESHOLD=2
 * INITIAL_DEPOSIT=1000000000000000000  # 1 ETH in wei
 */
contract DeployProject40 is Script {
    // Default configuration for testing
    address[] public defaultOwners;
    uint256 public constant DEFAULT_THRESHOLD = 2;
    uint256 public constant DEFAULT_INITIAL_DEPOSIT = 0;

    function setUp() public {
        // Set up default owners for testing (addresses with known private keys on testnet)
        defaultOwners.push(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266); // Anvil default account 0
        defaultOwners.push(0x70997970C51812dc3A010C7d01b50e0d17dc79C8); // Anvil default account 1
        defaultOwners.push(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC); // Anvil default account 2
    }

    /**
     * @notice Main deployment function
     * @dev Deploys MultiSigWallet with owners from environment or defaults
     */
    function run() external {
        // Load configuration
        (address[] memory owners, uint256 threshold, uint256 initialDeposit) = loadConfiguration();

        // Validate configuration
        validateConfiguration(owners, threshold);

        // Log deployment parameters
        console.log("=== Multi-Sig Wallet Deployment ===");
        console.log("Number of Owners:", owners.length);
        console.log("Threshold:", threshold);
        console.log("Initial Deposit:", initialDeposit, "wei");
        console.log("\nOwners:");
        for (uint256 i = 0; i < owners.length; i++) {
            console.log("  Owner", i + 1, ":", owners[i]);
        }
        console.log("");

        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy the wallet
        MultiSigWalletSolution wallet = new MultiSigWalletSolution(owners, threshold);

        console.log("MultiSigWallet deployed at:", address(wallet));

        // Send initial deposit if specified
        if (initialDeposit > 0) {
            (bool success,) = address(wallet).call{value: initialDeposit}("");
            require(success, "Initial deposit failed");
            console.log("Initial deposit sent:", initialDeposit, "wei");
            console.log("Wallet balance:", address(wallet).balance, "wei");
        }

        vm.stopBroadcast();

        // Post-deployment verification
        console.log("\n=== Deployment Verification ===");
        verifyDeployment(wallet, owners, threshold);

        // Print usage instructions
        printUsageInstructions(address(wallet));
    }

    /**
     * @notice Load configuration from environment variables or use defaults
     * @return owners Array of owner addresses
     * @return threshold Minimum confirmations required
     * @return initialDeposit Initial ETH to deposit in wei
     */
    function loadConfiguration()
        internal
        view
        returns (address[] memory owners, uint256 threshold, uint256 initialDeposit)
    {
        // Try to load from environment
        try vm.envAddress("OWNER_1") returns (address owner1) {
            // Environment variables are available, use them
            owners = loadOwnersFromEnv();
            threshold = vm.envUint("THRESHOLD");

            // Optional initial deposit
            try vm.envUint("INITIAL_DEPOSIT") returns (uint256 deposit) {
                initialDeposit = deposit;
            } catch {
                initialDeposit = DEFAULT_INITIAL_DEPOSIT;
            }
        } catch {
            // No environment variables, use defaults
            console.log("No environment variables found, using default configuration");
            owners = defaultOwners;
            threshold = DEFAULT_THRESHOLD;
            initialDeposit = DEFAULT_INITIAL_DEPOSIT;
        }
    }

    /**
     * @notice Load owner addresses from environment variables
     * @return owners Array of owner addresses
     * @dev Supports up to 5 owners (OWNER_1 to OWNER_5)
     */
    function loadOwnersFromEnv() internal view returns (address[] memory owners) {
        address[] memory tempOwners = new address[](5);
        uint256 count = 0;

        // Try to load each owner
        try vm.envAddress("OWNER_1") returns (address owner) {
            tempOwners[count++] = owner;
        } catch {}

        try vm.envAddress("OWNER_2") returns (address owner) {
            tempOwners[count++] = owner;
        } catch {}

        try vm.envAddress("OWNER_3") returns (address owner) {
            tempOwners[count++] = owner;
        } catch {}

        try vm.envAddress("OWNER_4") returns (address owner) {
            tempOwners[count++] = owner;
        } catch {}

        try vm.envAddress("OWNER_5") returns (address owner) {
            tempOwners[count++] = owner;
        } catch {}

        // Create array with actual count
        owners = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            owners[i] = tempOwners[i];
        }

        require(count >= 1, "At least one owner required");
    }

    /**
     * @notice Validate deployment configuration
     * @param owners Array of owner addresses
     * @param threshold Minimum confirmations required
     */
    function validateConfiguration(address[] memory owners, uint256 threshold) internal pure {
        require(owners.length > 0, "No owners provided");
        require(threshold > 0, "Threshold must be greater than 0");
        require(threshold <= owners.length, "Threshold cannot exceed number of owners");

        // Check for duplicate owners
        for (uint256 i = 0; i < owners.length; i++) {
            require(owners[i] != address(0), "Owner cannot be zero address");
            for (uint256 j = i + 1; j < owners.length; j++) {
                require(owners[i] != owners[j], "Duplicate owner detected");
            }
        }

        console.log("Configuration validation passed");
    }

    /**
     * @notice Verify deployment was successful
     * @param wallet Deployed wallet instance
     * @param expectedOwners Expected owner addresses
     * @param expectedThreshold Expected threshold
     */
    function verifyDeployment(
        MultiSigWalletSolution wallet,
        address[] memory expectedOwners,
        uint256 expectedThreshold
    ) internal view {
        // Verify threshold
        require(wallet.threshold() == expectedThreshold, "Threshold mismatch");
        console.log("✓ Threshold verified:", wallet.threshold());

        // Verify owners
        address[] memory actualOwners = wallet.getOwners();
        require(actualOwners.length == expectedOwners.length, "Owner count mismatch");
        console.log("✓ Owner count verified:", actualOwners.length);

        // Verify each owner
        for (uint256 i = 0; i < expectedOwners.length; i++) {
            require(wallet.isOwner(expectedOwners[i]), "Owner not registered");
        }
        console.log("✓ All owners verified");

        // Verify initial nonce
        require(wallet.nonce() == 0, "Initial nonce should be 0");
        console.log("✓ Initial nonce verified: 0");

        console.log("\nDeployment verification complete!");
    }

    /**
     * @notice Print usage instructions for the deployed wallet
     * @param walletAddress Address of the deployed wallet
     */
    function printUsageInstructions(address walletAddress) internal pure {
        console.log("\n=== Usage Instructions ===");
        console.log("\n1. Submit a transaction:");
        console.log("   wallet.submitTransaction(destination, value, data)");
        console.log("\n2. Confirm a transaction (as an owner):");
        console.log("   wallet.confirmTransaction(txId)");
        console.log("\n3. Execute a transaction (once threshold is met):");
        console.log("   wallet.executeTransaction(txId)");
        console.log("\n4. View pending transactions:");
        console.log("   wallet.getTransaction(txId)");
        console.log("\n5. Check confirmation status:");
        console.log("   wallet.getConfirmationCount(txId)");
        console.log("   wallet.isThresholdMet(txId)");
        console.log("\nWallet Address:", walletAddress);
        console.log("\nIMPORTANT: Keep owner private keys secure!");
        console.log("Loss of threshold number of keys will lock the wallet permanently.");
    }
}

/**
 * @title Deploy Multi-Sig Wallet with Custom Configuration
 * @notice Alternative deployment script with inline configuration
 * @dev Use this for quick deployments with hardcoded parameters
 */
contract DeployProject40Custom is Script {
    function run() external {
        // CONFIGURE YOUR DEPLOYMENT HERE
        address[] memory owners = new address[](3);
        owners[0] = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // Replace with your owner 1
        owners[1] = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8; // Replace with your owner 2
        owners[2] = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC; // Replace with your owner 3

        uint256 threshold = 2; // Require 2 confirmations
        uint256 initialDeposit = 0 ether; // Initial ETH deposit

        // Deploy
        vm.startBroadcast();

        MultiSigWalletSolution wallet = new MultiSigWalletSolution(owners, threshold);
        console.log("MultiSigWallet deployed at:", address(wallet));

        if (initialDeposit > 0) {
            (bool success,) = address(wallet).call{value: initialDeposit}("");
            require(success, "Initial deposit failed");
            console.log("Deposited:", initialDeposit);
        }

        vm.stopBroadcast();

        // Verify
        console.log("\nOwners:", wallet.getOwners().length);
        console.log("Threshold:", wallet.threshold());
        console.log("Balance:", address(wallet).balance);
    }
}

/**
 * @title Deploy Multi-Sig Wallet for Production
 * @notice Production deployment script with additional safety checks
 * @dev Use this for mainnet deployments
 */
contract DeployProject40Production is Script {
    function run() external {
        // Load configuration
        address[] memory owners = loadOwnersFromEnv();
        uint256 threshold = vm.envUint("THRESHOLD");

        // PRODUCTION SAFETY CHECKS
        console.log("\n=== PRODUCTION DEPLOYMENT ===");
        console.log("WARNING: This is a production deployment!");
        console.log("Please verify all parameters carefully.\n");

        // Verify we're not on a testnet
        require(block.chainid != 1337, "Cannot deploy to Anvil in production mode");
        require(block.chainid != 31337, "Cannot deploy to local network in production mode");

        // Display configuration
        console.log("Chain ID:", block.chainid);
        console.log("Number of Owners:", owners.length);
        console.log("Threshold:", threshold);
        console.log("\nOwners:");
        for (uint256 i = 0; i < owners.length; i++) {
            console.log("  ", i + 1, ":", owners[i]);
        }

        // Validate configuration
        require(owners.length >= 2, "Production wallet should have at least 2 owners");
        require(threshold >= 2, "Production wallet should require at least 2 confirmations");
        require(threshold * 100 / owners.length >= 50, "Threshold should be at least 50% of owners");

        // Check for duplicate owners
        for (uint256 i = 0; i < owners.length; i++) {
            require(owners[i] != address(0), "Invalid owner address");
            for (uint256 j = i + 1; j < owners.length; j++) {
                require(owners[i] != owners[j], "Duplicate owner");
            }
        }

        console.log("\n✓ All safety checks passed");
        console.log("\nDeploying...\n");

        // Deploy
        vm.startBroadcast();
        MultiSigWalletSolution wallet = new MultiSigWalletSolution(owners, threshold);
        vm.stopBroadcast();

        console.log("=== DEPLOYMENT SUCCESSFUL ===");
        console.log("MultiSigWallet:", address(wallet));
        console.log("\nIMPORTANT:");
        console.log("1. Verify the contract on the block explorer");
        console.log("2. Test with small amounts first");
        console.log("3. Store owner private keys securely");
        console.log("4. Document recovery procedures");
        console.log("5. Consider setting up monitoring");
    }

    function loadOwnersFromEnv() internal view returns (address[] memory) {
        address[] memory tempOwners = new address[](10);
        uint256 count = 0;

        for (uint256 i = 1; i <= 10; i++) {
            try vm.envAddress(string(abi.encodePacked("OWNER_", vm.toString(i)))) returns (address owner) {
                tempOwners[count++] = owner;
            } catch {
                break;
            }
        }

        require(count >= 1, "At least one owner required");

        address[] memory owners = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            owners[i] = tempOwners[i];
        }

        return owners;
    }
}
