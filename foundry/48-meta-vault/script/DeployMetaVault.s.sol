// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/solution/MetaVaultSolution.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC4626.sol";

/**
 * @title DeployMetaVault
 * @notice Deployment script for MetaVault
 *
 * USAGE:
 * forge script script/DeployMetaVault.s.sol:DeployMetaVault --rpc-url <RPC_URL> --broadcast
 *
 * CONFIGURATION:
 * Set environment variables:
 * - UNDERLYING_ASSET: Address of the asset (e.g., DAI, USDC)
 * - VAULT_A: Address of first underlying vault (optional)
 * - VAULT_B: Address of second underlying vault (optional)
 * - VAULT_C: Address of third underlying vault (optional)
 *
 * EXAMPLES:
 * 1. Deploy on mainnet with existing vaults:
 *    UNDERLYING_ASSET=0x6B175474E89094C44Da98b954EedeAC495271d0F \
 *    VAULT_A=0x... \
 *    forge script script/DeployMetaVault.s.sol --rpc-url mainnet --broadcast
 *
 * 2. Deploy on testnet with configuration:
 *    forge script script/DeployMetaVault.s.sol --rpc-url sepolia --broadcast
 */
contract DeployMetaVault is Script {
    // Configuration
    address public underlyingAsset;
    address public vaultA;
    address public vaultB;
    address public vaultC;

    // Deployed contracts
    MetaVaultSolution public metaVault;

    function run() external {
        // Load configuration from environment or use defaults
        loadConfiguration();

        // Get deployer private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy meta-vault
        deployMetaVault();

        // Configure meta-vault with underlying vaults (if provided)
        configureVaults();

        vm.stopBroadcast();

        // Print deployment information
        printDeploymentInfo();
    }

    /**
     * @notice Load configuration from environment variables
     */
    function loadConfiguration() internal {
        // Try to load underlying asset
        try vm.envAddress("UNDERLYING_ASSET") returns (address asset) {
            underlyingAsset = asset;
            console.log("Using configured asset:", asset);
        } catch {
            console.log("UNDERLYING_ASSET not set, will need manual configuration");
        }

        // Try to load vault addresses
        try vm.envAddress("VAULT_A") returns (address vault) {
            vaultA = vault;
            console.log("Vault A configured:", vault);
        } catch {
            console.log("VAULT_A not set");
        }

        try vm.envAddress("VAULT_B") returns (address vault) {
            vaultB = vault;
            console.log("Vault B configured:", vault);
        } catch {
            console.log("VAULT_B not set");
        }

        try vm.envAddress("VAULT_C") returns (address vault) {
            vaultC = vault;
            console.log("Vault C configured:", vault);
        } catch {
            console.log("VAULT_C not set");
        }
    }

    /**
     * @notice Deploy the meta-vault
     */
    function deployMetaVault() internal {
        require(underlyingAsset != address(0), "UNDERLYING_ASSET must be set");

        console.log("Deploying MetaVault...");
        console.log("Underlying asset:", underlyingAsset);

        metaVault = new MetaVaultSolution(
            IERC20(underlyingAsset),
            "Meta Yield Vault",
            "metaYLD"
        );

        console.log("MetaVault deployed at:", address(metaVault));
    }

    /**
     * @notice Configure the meta-vault with underlying vaults
     */
    function configureVaults() internal {
        if (vaultA != address(0)) {
            console.log("Adding Vault A:", vaultA);

            // Verify vault uses correct asset
            require(
                IERC4626(vaultA).asset() == underlyingAsset,
                "Vault A uses different asset"
            );

            // Add with 50% allocation if it's the only vault
            uint256 allocation = 5000; // 50%

            if (vaultB != address(0)) {
                // If vault B exists, give A 40%
                allocation = 4000;
            }

            metaVault.addVault(IERC4626(vaultA), allocation);
            console.log("Vault A added with allocation:", allocation);
        }

        if (vaultB != address(0)) {
            console.log("Adding Vault B:", vaultB);

            require(
                IERC4626(vaultB).asset() == underlyingAsset,
                "Vault B uses different asset"
            );

            // Add with 40% allocation if vault C doesn't exist, otherwise 30%
            uint256 allocation = vaultC != address(0) ? 3000 : 4000;

            metaVault.addVault(IERC4626(vaultB), allocation);
            console.log("Vault B added with allocation:", allocation);
        }

        if (vaultC != address(0)) {
            console.log("Adding Vault C:", vaultC);

            require(
                IERC4626(vaultC).asset() == underlyingAsset,
                "Vault C uses different asset"
            );

            // Add with remaining allocation (30%)
            metaVault.addVault(IERC4626(vaultC), 3000);
            console.log("Vault C added with allocation: 3000");
        }

        // Set reasonable rebalance threshold (5%)
        metaVault.setRebalanceThreshold(500);
        console.log("Rebalance threshold set to 5%");
    }

    /**
     * @notice Print deployment information
     */
    function printDeploymentInfo() internal view {
        console.log("\n=== DEPLOYMENT SUMMARY ===");
        console.log("MetaVault:", address(metaVault));
        console.log("Underlying Asset:", underlyingAsset);
        console.log("Vault Count:", metaVault.getVaultCount());

        if (metaVault.getVaultCount() > 0) {
            console.log("\nConfigured Vaults:");
            IERC4626[] memory vaults = metaVault.getVaults();
            uint256[] memory allocations = metaVault.getTargetAllocations();

            for (uint256 i = 0; i < vaults.length; i++) {
                console.log("  Vault", i, ":", address(vaults[i]));
                console.log("  Allocation:", allocations[i], "BPS");
            }
        }

        console.log("\n=== NEXT STEPS ===");
        console.log("1. Verify contracts on Etherscan:");
        console.log("   forge verify-contract", address(metaVault), "src/solution/MetaVaultSolution.sol:MetaVaultSolution");

        console.log("\n2. Add more vaults if needed:");
        console.log("   metaVault.addVault(vaultAddress, allocationBPS)");

        console.log("\n3. Enable auto-rebalancing (optional):");
        console.log("   metaVault.setAutoRebalance(true)");

        console.log("\n4. Test deposit:");
        console.log("   asset.approve(metaVault, amount)");
        console.log("   metaVault.deposit(amount, receiver)");
    }
}

/**
 * @title DeployWithMockVaults
 * @notice Deployment script that also deploys mock vaults for testing
 *
 * USAGE:
 * forge script script/DeployMetaVault.s.sol:DeployWithMockVaults --rpc-url <RPC_URL> --broadcast
 */
contract DeployWithMockVaults is Script {
    // Mock contracts for testing
    MockERC20 public asset;
    MockVault public vaultA;
    MockVault public vaultB;
    MockVault public vaultC;
    MetaVaultSolution public metaVault;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy mock asset
        console.log("Deploying mock asset...");
        asset = new MockERC20("Test USDC", "USDC");
        console.log("Mock asset deployed at:", address(asset));

        // Deploy mock vaults with different yield rates
        console.log("\nDeploying mock vaults...");

        vaultA = new MockVault(asset, "Conservative Vault", "cVault");
        vaultA.setYieldRate(100); // 1% per period
        console.log("Vault A (1% yield) deployed at:", address(vaultA));

        vaultB = new MockVault(asset, "Balanced Vault", "bVault");
        vaultB.setYieldRate(200); // 2% per period
        console.log("Vault B (2% yield) deployed at:", address(vaultB));

        vaultC = new MockVault(asset, "Aggressive Vault", "aVault");
        vaultC.setYieldRate(300); // 3% per period
        console.log("Vault C (3% yield) deployed at:", address(vaultC));

        // Deploy meta-vault
        console.log("\nDeploying meta-vault...");
        metaVault = new MetaVaultSolution(
            asset,
            "Meta Yield Aggregator",
            "metaYLD"
        );
        console.log("MetaVault deployed at:", address(metaVault));

        // Configure meta-vault
        console.log("\nConfiguring meta-vault...");
        metaVault.addVault(IERC4626(address(vaultA)), 3000); // 30%
        metaVault.addVault(IERC4626(address(vaultB)), 4000); // 40%
        metaVault.addVault(IERC4626(address(vaultC)), 3000); // 30%

        console.log("Vaults added with allocations: 30%, 40%, 30%");

        // Set rebalance threshold
        metaVault.setRebalanceThreshold(500); // 5%
        console.log("Rebalance threshold set to 5%");

        vm.stopBroadcast();

        // Print summary
        printTestDeploymentInfo();
    }

    function printTestDeploymentInfo() internal view {
        console.log("\n=== TEST DEPLOYMENT SUMMARY ===");
        console.log("Mock Asset:", address(asset));
        console.log("MetaVault:", address(metaVault));
        console.log("\nUnderlying Vaults:");
        console.log("  Vault A (1% yield):", address(vaultA));
        console.log("  Vault B (2% yield):", address(vaultB));
        console.log("  Vault C (3% yield):", address(vaultC));

        console.log("\n=== TESTING INSTRUCTIONS ===");
        console.log("1. Mint test tokens:");
        console.log("   asset.mint(yourAddress, amount)");

        console.log("\n2. Approve and deposit to meta-vault:");
        console.log("   asset.approve(metaVault, amount)");
        console.log("   metaVault.deposit(amount, yourAddress)");

        console.log("\n3. Simulate yield in underlying vaults:");
        console.log("   vaultA.accrueYield()");
        console.log("   vaultB.accrueYield()");
        console.log("   vaultC.accrueYield()");

        console.log("\n4. Check your balance increased:");
        console.log("   metaVault.maxWithdraw(yourAddress)");

        console.log("\n5. Rebalance to optimal allocation:");
        console.log("   metaVault.rebalance()");
    }
}

/**
 * @title MockERC20
 * @notice Simple ERC20 for testing
 */
contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000000e18);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/**
 * @title MockVault
 * @notice Simple ERC4626 vault for testing
 */
contract MockVault is ERC4626 {
    uint256 public yieldRate;

    constructor(
        IERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC4626(_asset) ERC20(_name, _symbol) {
        yieldRate = 100; // 1% default
    }

    function accrueYield() external {
        uint256 currentAssets = IERC20(asset()).balanceOf(address(this));
        uint256 yield = (currentAssets * yieldRate) / 10000;

        if (yield > 0) {
            MockERC20(asset()).mint(address(this), yield);
        }
    }

    function setYieldRate(uint256 _yieldRate) external {
        yieldRate = _yieldRate;
    }

    function totalAssets() public view override returns (uint256) {
        return IERC20(asset()).balanceOf(address(this));
    }
}
