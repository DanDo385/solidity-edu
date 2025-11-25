// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/solution/VaultInsolvencySolution.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Deploy Project 46 - Vault Insolvency Scenarios
 * @notice Deployment script for vault insolvency demonstration
 */

// Mock token for testing
contract DeployToken is ERC20 {
    constructor() ERC20("Vault Asset Token", "VAT") {
        _mint(msg.sender, 1_000_000 * 10 ** 18);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract DeployVaultInsolvency is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying Project 46: Vault Insolvency Scenarios");
        console.log("Deployer:", deployer);
        console.log("----------------------------------------");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy mock token
        console.log("1. Deploying mock token...");
        DeployToken token = new DeployToken();
        console.log("   Token deployed at:", address(token));
        console.log("   Token name:", token.name());
        console.log("   Token symbol:", token.symbol());

        // 2. Deploy strategy
        console.log("\n2. Deploying risky strategy...");
        RiskyStrategySolution strategy = new RiskyStrategySolution(address(token));
        console.log("   Strategy deployed at:", address(strategy));

        // 3. Deploy vault
        console.log("\n3. Deploying insolvency vault...");
        VaultInsolvencySolution vault = new VaultInsolvencySolution(address(token), address(strategy));
        console.log("   Vault deployed at:", address(vault));

        // 4. Display initial status
        console.log("\n4. Initial Vault Status:");
        console.log("   Asset:", address(vault.asset()));
        console.log("   Strategy:", address(vault.strategy()));
        console.log("   Owner:", vault.owner());
        console.log("   Mode:", vault.getCurrentModeString());

        (
            VaultInsolvencySolution.Mode mode,
            uint256 totalAssets,
            uint256 totalShares,
            uint256 lossPercentage,
            bool isSolvent
        ) = vault.getVaultStatus();

        console.log("   Total Assets:", totalAssets);
        console.log("   Total Shares:", totalShares);
        console.log("   Loss Percentage:", lossPercentage);
        console.log("   Is Solvent:", isSolvent);

        // 5. Mint some tokens to deployer for testing
        console.log("\n5. Minting test tokens...");
        uint256 testAmount = 10_000 * 10 ** 18;
        token.mint(deployer, testAmount);
        console.log("   Minted", testAmount / 10 ** 18, "tokens to deployer");

        vm.stopBroadcast();

        // 6. Display summary
        console.log("\n========================================");
        console.log("DEPLOYMENT SUMMARY");
        console.log("========================================");
        console.log("Token Address:    ", address(token));
        console.log("Strategy Address: ", address(strategy));
        console.log("Vault Address:    ", address(vault));
        console.log("Owner Address:    ", deployer);
        console.log("========================================");

        // 7. Next steps
        console.log("\nNEXT STEPS:");
        console.log("1. Approve vault to spend tokens:");
        console.log("   token.approve(vaultAddress, amount)");
        console.log("\n2. Deposit tokens:");
        console.log("   vault.deposit(amount)");
        console.log("\n3. Simulate loss (for testing):");
        console.log("   strategy.simulateLoss(lossAmount)");
        console.log("\n4. Trigger emergency:");
        console.log("   vault.triggerEmergency()");
        console.log("\n5. Check vault status:");
        console.log("   vault.getVaultStatus()");
        console.log("\n6. Withdraw (mode-dependent):");
        console.log("   vault.withdraw(shares)");
        console.log("========================================");
    }
}

/**
 * @title Deploy with Scenario Testing
 * @notice Extended deployment with scenario simulation
 */
contract DeployWithScenario is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying and Testing Insolvency Scenarios");
        console.log("Deployer:", deployer);
        console.log("========================================");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy contracts
        DeployToken token = new DeployToken();
        RiskyStrategySolution strategy = new RiskyStrategySolution(address(token));
        VaultInsolvencySolution vault = new VaultInsolvencySolution(address(token), address(strategy));

        console.log("Contracts deployed:");
        console.log("  Token:    ", address(token));
        console.log("  Strategy: ", address(strategy));
        console.log("  Vault:    ", address(vault));

        // Scenario 1: Normal Operations
        console.log("\n=== SCENARIO 1: Normal Operations ===");

        uint256 depositAmount = 1000 * 10 ** 18;
        token.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount);

        console.log("Deposited:", depositAmount / 10 ** 18, "tokens");
        console.log("Received:", shares / 10 ** 18, "shares");
        console.log("Total Assets:", vault.totalAssets() / 10 ** 18);

        // Scenario 2: Small Loss
        console.log("\n=== SCENARIO 2: Small Loss (10%) ===");

        uint256 smallLoss = 100 * 10 ** 18; // 10%
        strategy.simulateLoss(smallLoss);

        console.log("Loss Amount:", smallLoss / 10 ** 18, "tokens");
        console.log("Total Assets After Loss:", vault.totalAssets() / 10 ** 18);
        console.log("Loss Percentage:", vault.calculateLoss(), "basis points");

        uint256 pricePerShare = vault.getPricePerShare();
        console.log("Price Per Share:", pricePerShare);
        console.log("Share Value Decrease:", (1e18 - pricePerShare) * 100 / 1e18, "%");

        // Scenario 3: Emergency Mode
        console.log("\n=== SCENARIO 3: Trigger Emergency ===");

        vault.triggerEmergency();

        (
            VaultInsolvencySolution.Mode mode,
            uint256 totalAssets,
            uint256 totalShares,
            uint256 lossPercentage,
            bool isSolvent
        ) = vault.getVaultStatus();

        console.log("Current Mode:", vault.getCurrentModeString());
        console.log("Total Assets:", totalAssets / 10 ** 18);
        console.log("Total Shares:", totalShares / 10 ** 18);
        console.log("Is Solvent:", isSolvent);

        // Scenario 4: Emergency Withdrawal
        console.log("\n=== SCENARIO 4: Emergency Withdrawal ===");

        uint256 balanceBefore = token.balanceOf(deployer);
        uint256 userShares = vault.shares(deployer);

        uint256 assetsReceived = vault.withdraw(userShares);

        uint256 balanceAfter = token.balanceOf(deployer);

        console.log("Shares Burned:", userShares / 10 ** 18);
        console.log("Assets Received:", assetsReceived / 10 ** 18);
        console.log("Token Balance Increase:", (balanceAfter - balanceBefore) / 10 ** 18);

        // Calculate loss
        uint256 originalDeposit = depositAmount;
        uint256 actualReceived = assetsReceived;
        uint256 userLoss = originalDeposit - actualReceived;

        console.log("\nUser Loss Summary:");
        console.log("  Original Deposit:", originalDeposit / 10 ** 18, "tokens");
        console.log("  Amount Received:", actualReceived / 10 ** 18, "tokens");
        console.log("  Total Loss:", userLoss / 10 ** 18, "tokens");
        console.log("  Loss Percentage:", (userLoss * 100) / originalDeposit, "%");

        vm.stopBroadcast();

        console.log("\n========================================");
        console.log("SCENARIO TESTING COMPLETE");
        console.log("========================================");
    }
}

/**
 * @title Deploy Multi-User Scenario
 * @notice Demonstrates loss socialization among multiple users
 */
contract DeployMultiUserScenario is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        console.log("Multi-User Loss Socialization Scenario");
        console.log("========================================");

        // Deploy
        DeployToken token = new DeployToken();
        RiskyStrategySolution strategy = new RiskyStrategySolution(address(token));
        VaultInsolvencySolution vault = new VaultInsolvencySolution(address(token), address(strategy));

        // Create test users
        address alice = address(0x1);
        address bob = address(0x2);
        address carol = address(0x3);

        console.log("Test Users:");
        console.log("  Alice:", alice);
        console.log("  Bob:  ", bob);
        console.log("  Carol:", carol);

        // Fund users
        token.mint(alice, 2000 * 10 ** 18);
        token.mint(bob, 1000 * 10 ** 18);
        token.mint(carol, 1000 * 10 ** 18);

        vm.stopBroadcast();

        // Simulate as Alice (deposits 2000)
        vm.startBroadcast(deployerPrivateKey);
        vm.prank(alice);
        token.approve(address(vault), 2000 * 10 ** 18);
        vm.stopBroadcast();

        // Continue simulation...
        console.log("\nDeployment complete. Use separate transactions to simulate multi-user scenario.");
        console.log("Contracts:");
        console.log("  Token:", address(token));
        console.log("  Vault:", address(vault));

        vm.startBroadcast(deployerPrivateKey);
        vm.stopBroadcast();
    }
}

/*
DEPLOYMENT INSTRUCTIONS:

1. Set up environment:
   export PRIVATE_KEY=your_private_key
   export RPC_URL=your_rpc_url

2. Deploy basic contracts:
   forge script script/DeployVaultInsolvency.s.sol:DeployVaultInsolvency --rpc-url $RPC_URL --broadcast

3. Deploy with scenario:
   forge script script/DeployVaultInsolvency.s.sol:DeployWithScenario --rpc-url $RPC_URL --broadcast

4. Local testing:
   forge script script/DeployVaultInsolvency.s.sol:DeployVaultInsolvency --fork-url $RPC_URL

5. Verify contracts:
   forge verify-contract <address> VaultInsolvencySolution --chain-id <id>

TESTING LOCALLY:

1. Start local node:
   anvil

2. Deploy to local node:
   forge script script/DeployVaultInsolvency.s.sol:DeployWithScenario --rpc-url http://localhost:8545 --broadcast

3. Interact with contracts using cast:

   # Check vault status
   cast call <vault> "getVaultStatus()"

   # Deposit
   cast send <vault> "deposit(uint256)" 1000000000000000000000 --private-key <key>

   # Simulate loss
   cast send <strategy> "simulateLoss(uint256)" 100000000000000000000 --private-key <key>

   # Trigger emergency
   cast send <vault> "triggerEmergency()" --private-key <key>

   # Withdraw
   cast send <vault> "withdraw(uint256)" <shares> --private-key <key>

PRODUCTION DEPLOYMENT:

1. Audit all contracts thoroughly
2. Use multi-sig for owner role
3. Set appropriate thresholds for circuit breakers
4. Test on testnet extensively
5. Have emergency response plan
6. Monitor vault health continuously
7. Implement timelocks for critical operations

SECURITY CHECKLIST:

✓ ReentrancyGuard on all state-changing functions
✓ Access control for emergency functions
✓ Circuit breakers for automatic protection
✓ Fair loss distribution (pro-rata)
✓ Proper rounding (favor vault)
✓ Event emissions for transparency
✓ Mode-based operation restrictions
✓ Comprehensive testing of edge cases

Remember: This is educational code. Real production vaults need:
- Multi-sig governance
- Timelocks on critical functions
- Oracle integration
- Strategy whitelisting
- Yield optimization
- Gas optimization
- Professional audits
*/
