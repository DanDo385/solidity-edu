// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/solution/YieldVaultSolution.sol";

/**
 * @title Deploy Project 43: Yield-Bearing Vault
 * @notice Deployment script for yield vault with strategies
 */
contract DeployYieldVault is Script {
    // Configuration
    uint256 public constant PERFORMANCE_FEE = 1000; // 10%
    uint256 public constant MOCK_APY = 1000; // 10% for testing

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying Project 43: Yield-Bearing Vault");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy or use existing ERC20 token
        IERC20 asset = deployToken();
        console.log("Asset Token:", address(asset));

        // 2. Deploy mock yield source (for testing)
        MockYieldSource yieldSource = new MockYieldSource(asset, MOCK_APY);
        console.log("Mock Yield Source:", address(yieldSource));

        // 3. Deploy vault
        address feeRecipient = deployer; // In production, use treasury
        YieldVault vault = new YieldVault(
            asset,
            "Yield Vault Token",
            "yvToken",
            feeRecipient,
            PERFORMANCE_FEE
        );
        console.log("Yield Vault:", address(vault));

        // 4. Deploy simple strategy
        SimpleYieldStrategy simpleStrategy = new SimpleYieldStrategy(
            asset,
            yieldSource,
            address(vault)
        );
        console.log("Simple Strategy:", address(simpleStrategy));

        // 5. Deploy compound strategy
        CompoundStrategy compoundStrategy = new CompoundStrategy(
            asset,
            yieldSource,
            address(vault)
        );
        console.log("Compound Strategy:", address(compoundStrategy));

        // 6. Set initial strategy
        vault.setStrategy(simpleStrategy);
        console.log("Strategy set to Simple Strategy");

        // 7. Configure harvest cooldown
        vault.setHarvestCooldown(1 hours);
        console.log("Harvest cooldown set to 1 hour");

        vm.stopBroadcast();

        // Log deployment summary
        console.log("\n=== Deployment Summary ===");
        console.log("Asset:            ", address(asset));
        console.log("Yield Source:     ", address(yieldSource));
        console.log("Vault:            ", address(vault));
        console.log("Simple Strategy:  ", address(simpleStrategy));
        console.log("Compound Strategy:", address(compoundStrategy));
        console.log("Fee Recipient:    ", feeRecipient);
        console.log("Performance Fee:  ", PERFORMANCE_FEE, "bps");
        console.log("Mock APY:         ", MOCK_APY, "bps");

        console.log("\n=== Next Steps ===");
        console.log("1. Approve vault to spend your tokens");
        console.log("2. Deposit tokens: vault.deposit(amount, receiver)");
        console.log("3. Wait for yield to accrue");
        console.log("4. Call harvest(): vault.harvest()");
        console.log("5. Withdraw: vault.redeem(shares, receiver, owner)");

        // Verify vault configuration
        verifyDeployment(vault, asset, feeRecipient);
    }

    /**
     * @notice Deploys a mock ERC20 token for testing
     * @dev In production, this would use an existing token address
     */
    function deployToken() internal returns (IERC20) {
        // Check if we should use an existing token
        try vm.envAddress("ASSET_TOKEN") returns (address existingToken) {
            console.log("Using existing token:", existingToken);
            return IERC20(existingToken);
        } catch {
            // Deploy new mock token
            MockToken token = new MockToken();
            console.log("Deployed new mock token");
            return IERC20(address(token));
        }
    }

    /**
     * @notice Verifies the deployment was successful
     */
    function verifyDeployment(
        YieldVault vault,
        IERC20 asset,
        address feeRecipient
    ) internal view {
        console.log("\n=== Verification ===");

        require(address(vault.asset()) == address(asset), "Asset mismatch");
        console.log("✓ Asset configured correctly");

        require(vault.feeRecipient() == feeRecipient, "Fee recipient mismatch");
        console.log("✓ Fee recipient configured correctly");

        require(vault.performanceFee() == PERFORMANCE_FEE, "Fee mismatch");
        console.log("✓ Performance fee configured correctly");

        require(address(vault.strategy()) != address(0), "Strategy not set");
        console.log("✓ Strategy configured correctly");

        require(vault.owner() == msg.sender, "Owner mismatch");
        console.log("✓ Owner configured correctly");

        console.log("\nDeployment verified successfully!");
    }
}

/**
 * @title MockToken
 * @notice Simple ERC20 for testing
 */
contract MockToken is ERC20 {
    constructor() ERC20("Mock USDC", "USDC") {
        _mint(msg.sender, 1000000 * 10 ** 18);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }
}

/**
 * @title DeployProduction
 * @notice Production deployment script with real yield sources
 */
contract DeployProduction is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Production configuration
        address assetToken = vm.envAddress("ASSET_TOKEN"); // e.g., USDC
        address feeRecipient = vm.envAddress("FEE_RECIPIENT"); // Treasury
        uint256 performanceFee = vm.envUint("PERFORMANCE_FEE"); // e.g., 1000 = 10%

        console.log("=== Production Deployment ===");
        console.log("Deployer:", deployer);
        console.log("Asset:", assetToken);
        console.log("Fee Recipient:", feeRecipient);
        console.log("Performance Fee:", performanceFee, "bps");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy vault
        YieldVault vault = new YieldVault(
            IERC20(assetToken),
            vm.envString("VAULT_NAME"),
            vm.envString("VAULT_SYMBOL"),
            feeRecipient,
            performanceFee
        );

        console.log("Vault deployed:", address(vault));

        // Note: Strategy deployment depends on the actual yield source
        // For Aave: deploy AaveStrategy
        // For Compound: deploy CompoundStrategy
        // For Staking: deploy StakingStrategy

        vm.stopBroadcast();

        console.log("\n=== Production Deployment Complete ===");
        console.log("Vault:", address(vault));
        console.log("\nREMEMBER:");
        console.log("1. Deploy appropriate strategy for your yield source");
        console.log("2. Set strategy: vault.setStrategy(strategyAddress)");
        console.log("3. Test deposits/withdrawals on testnet first");
        console.log("4. Consider timelock for admin functions");
        console.log("5. Get contract audited before mainnet deployment");
    }
}

/**
 * @title QuickTest
 * @notice Quick local test of the vault
 */
contract QuickTest is Script {
    function run() external {
        console.log("=== Quick Test ===");

        // Deploy everything
        MockToken token = new MockToken();
        MockYieldSource yieldSource = new MockYieldSource(token, 1000); // 10% APY

        YieldVault vault = new YieldVault(
            token,
            "Test Vault",
            "tvToken",
            address(this),
            1000 // 10% fee
        );

        SimpleYieldStrategy strategy = new SimpleYieldStrategy(
            token,
            yieldSource,
            address(vault)
        );

        vault.setStrategy(strategy);

        // Test deposit
        uint256 depositAmount = 1000 * 10 ** 18;
        token.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, address(this));

        console.log("Deposited:", depositAmount);
        console.log("Shares received:", shares);
        console.log("Share price:", vault.convertToAssets(1e18));

        // Fast forward time
        vm.warp(block.timestamp + 30 days);

        console.log("\nAfter 30 days:");
        console.log("Total assets:", vault.totalAssets());
        console.log("Share price:", vault.convertToAssets(1e18));

        // Harvest
        vault.setHarvestCooldown(0);
        try vault.harvest() {
            console.log("Harvested successfully!");
            console.log("Total yield:", vault.totalYieldHarvested());
            console.log("Total fees:", vault.totalFeesCollected());
        } catch {
            console.log("Harvest failed");
        }

        // Withdraw
        uint256 withdrawn = vault.redeem(shares, address(this), address(this));
        console.log("\nWithdrew:", withdrawn);
        console.log("Profit:", withdrawn > depositAmount ? withdrawn - depositAmount : 0);

        console.log("\n=== Test Complete ===");
    }
}
