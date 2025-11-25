// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/solution/OracleManipulationSolution.sol";

/**
 * @title DeployOracleManipulation
 * @notice Deployment script for Project 34: Oracle Manipulation Attack
 *
 * USAGE:
 * forge script script/DeployOracleManipulation.s.sol --rpc-url <RPC_URL> --broadcast --verify
 *
 * For local testing:
 * forge script script/DeployOracleManipulation.s.sol --fork-url http://localhost:8545 --broadcast
 */
contract DeployOracleManipulation is Script {
    // Deployment addresses
    Token public token0;
    Token public token1;
    SimpleAMM public amm;
    VulnerableLending public vulnerableLending;
    FlashloanProvider public flashloanProvider;
    AttackerSolution public attacker;

    // Secure implementations
    TWAPOracle public twapOracle;
    SecureLending public secureLending;
    MultiOracleProtection public multiOracle;

    // Configuration
    uint256 constant INITIAL_SUPPLY = 1_000_000 * 1e18;
    uint256 constant AMM_LIQUIDITY_0 = 100 * 1e18;
    uint256 constant AMM_LIQUIDITY_1 = 200_000 * 1e18;
    uint256 constant FLASHLOAN_POOL_AMOUNT = 500_000 * 1e18;
    uint256 constant LENDING_POOL_AMOUNT = 100_000 * 1e18;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying Project 34 with deployer:", deployer);
        console.log("Deployer balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        // ============================================
        // STEP 1: Deploy Tokens
        // ============================================
        console.log("\n1. Deploying tokens...");

        token0 = new Token("Wrapped BTC", "WBTC", INITIAL_SUPPLY);
        console.log("Token0 (WBTC) deployed at:", address(token0));

        token1 = new Token("USD Coin", "USDC", INITIAL_SUPPLY);
        console.log("Token1 (USDC) deployed at:", address(token1));

        // ============================================
        // STEP 2: Deploy AMM
        // ============================================
        console.log("\n2. Deploying AMM...");

        amm = new SimpleAMM(address(token0), address(token1));
        console.log("SimpleAMM deployed at:", address(amm));

        // Add initial liquidity
        token0.approve(address(amm), AMM_LIQUIDITY_0);
        token1.approve(address(amm), AMM_LIQUIDITY_1);
        amm.addLiquidity(AMM_LIQUIDITY_0, AMM_LIQUIDITY_1);

        uint256 initialPrice = amm.getPrice();
        console.log("Initial AMM price:", initialPrice / 1e18, "USDC per WBTC");

        // ============================================
        // STEP 3: Deploy Vulnerable Lending Protocol
        // ============================================
        console.log("\n3. Deploying vulnerable lending protocol...");

        vulnerableLending = new VulnerableLending(
            address(amm),
            address(token0),
            address(token1)
        );
        console.log("VulnerableLending deployed at:", address(vulnerableLending));

        // Fund lending protocol
        token1.transfer(address(vulnerableLending), LENDING_POOL_AMOUNT);
        console.log("Lending pool funded with:", LENDING_POOL_AMOUNT / 1e18, "USDC");

        // ============================================
        // STEP 4: Deploy Flashloan Provider
        // ============================================
        console.log("\n4. Deploying flashloan provider...");

        flashloanProvider = new FlashloanProvider(address(token1));
        console.log("FlashloanProvider deployed at:", address(flashloanProvider));

        // Fund flashloan pool
        token1.approve(address(flashloanProvider), FLASHLOAN_POOL_AMOUNT);
        flashloanProvider.deposit(FLASHLOAN_POOL_AMOUNT);
        console.log("Flashloan pool funded with:", FLASHLOAN_POOL_AMOUNT / 1e18, "USDC");

        // ============================================
        // STEP 5: Deploy Attacker Contract
        // ============================================
        console.log("\n5. Deploying attacker contract...");

        attacker = new AttackerSolution(
            address(amm),
            address(vulnerableLending),
            address(token0),
            address(token1),
            address(flashloanProvider)
        );
        console.log("AttackerSolution deployed at:", address(attacker));

        // ============================================
        // STEP 6: Deploy Secure Implementations
        // ============================================
        console.log("\n6. Deploying secure implementations...");

        // Deploy TWAP Oracle
        twapOracle = new TWAPOracle(address(amm));
        console.log("TWAPOracle deployed at:", address(twapOracle));

        // Deploy Secure Lending
        secureLending = new SecureLending(
            address(twapOracle),
            address(token0),
            address(token1)
        );
        console.log("SecureLending deployed at:", address(secureLending));

        // Fund secure lending
        token1.transfer(address(secureLending), LENDING_POOL_AMOUNT);
        console.log("Secure lending pool funded with:", LENDING_POOL_AMOUNT / 1e18, "USDC");

        // Deploy Multi-Oracle Protection
        multiOracle = new MultiOracleProtection(
            address(twapOracle),
            address(amm)
        );
        console.log("MultiOracleProtection deployed at:", address(multiOracle));

        vm.stopBroadcast();

        // ============================================
        // STEP 7: Print Summary
        // ============================================
        console.log("\n" "============================================");
        console.log("DEPLOYMENT SUMMARY");
        console.log("============================================");
        console.log("\nVulnerable System:");
        console.log("  Token0 (WBTC):", address(token0));
        console.log("  Token1 (USDC):", address(token1));
        console.log("  SimpleAMM:", address(amm));
        console.log("  VulnerableLending:", address(vulnerableLending));
        console.log("  FlashloanProvider:", address(flashloanProvider));
        console.log("  AttackerSolution:", address(attacker));
        console.log("\nSecure System:");
        console.log("  TWAPOracle:", address(twapOracle));
        console.log("  SecureLending:", address(secureLending));
        console.log("  MultiOracleProtection:", address(multiOracle));
        console.log("\nInitial State:");
        console.log("  AMM Price:", initialPrice / 1e18, "USDC per WBTC");
        console.log("  AMM Liquidity: ", AMM_LIQUIDITY_0 / 1e18, "WBTC,", AMM_LIQUIDITY_1 / 1e18, "USDC");
        console.log("  Lending Pool:", LENDING_POOL_AMOUNT / 1e18, "USDC");
        console.log("  Flashloan Pool:", FLASHLOAN_POOL_AMOUNT / 1e18, "USDC");
        console.log("============================================\n");

        // Save deployment info to file
        _saveDeployment();
    }

    /**
     * @notice Run a demonstration of the attack (local only)
     */
    function runDemo() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        console.log("\n" "============================================");
        console.log("RUNNING ATTACK DEMONSTRATION");
        console.log("============================================\n");

        // Record initial state
        uint256 priceBefore = amm.getPrice();
        uint256 lendingBalanceBefore = token1.balanceOf(address(vulnerableLending));

        console.log("Initial price:", priceBefore / 1e18, "USDC per WBTC");
        console.log("Lending pool balance:", lendingBalanceBefore / 1e18, "USDC");

        // Give attacker some collateral
        uint256 collateralAmount = 0.5 * 1e18;
        token0.transfer(address(attacker), collateralAmount);
        console.log("\nAttacker received:", collateralAmount / 1e18, "WBTC as collateral");

        // Execute attack
        uint256 flashloanAmount = 100_000 * 1e18;
        console.log("Executing attack with flashloan of:", flashloanAmount / 1e18, "USDC");

        attacker.attack(flashloanAmount, collateralAmount);

        // Check results
        uint256 priceAfter = amm.getPrice();
        uint256 lendingBalanceAfter = token1.balanceOf(address(vulnerableLending));
        uint256 profit = attacker.getProfit();

        console.log("\n--- ATTACK RESULTS ---");
        console.log("Final price:", priceAfter / 1e18, "USDC per WBTC");
        console.log("Lending pool balance:", lendingBalanceAfter / 1e18, "USDC");
        console.log("Protocol loss:", (lendingBalanceBefore - lendingBalanceAfter) / 1e18, "USDC");
        console.log("Attacker profit:", profit / 1e18, "USDC");

        // Withdraw profit
        attacker.withdrawProfit();
        console.log("\nProfit withdrawn to deployer");

        console.log("\n============================================");
        console.log("DEMONSTRATION COMPLETE");
        console.log("============================================\n");

        vm.stopBroadcast();
    }

    /**
     * @notice Save deployment addresses to a file
     */
    function _saveDeployment() internal {
        string memory json = "deployment";

        // Vulnerable system
        vm.serializeAddress(json, "token0", address(token0));
        vm.serializeAddress(json, "token1", address(token1));
        vm.serializeAddress(json, "amm", address(amm));
        vm.serializeAddress(json, "vulnerableLending", address(vulnerableLending));
        vm.serializeAddress(json, "flashloanProvider", address(flashloanProvider));
        vm.serializeAddress(json, "attacker", address(attacker));

        // Secure system
        vm.serializeAddress(json, "twapOracle", address(twapOracle));
        vm.serializeAddress(json, "secureLending", address(secureLending));
        string memory finalJson = vm.serializeAddress(json, "multiOracle", address(multiOracle));

        // Write to file
        string memory path = string.concat(vm.projectRoot(), "/deployment-addresses.json");
        vm.writeJson(finalJson, path);

        console.log("\nDeployment addresses saved to:", path);
    }
}

/**
 * @title DeployMinimal
 * @notice Minimal deployment for quick testing
 */
contract DeployMinimal is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying minimal setup...");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy tokens
        Token token0 = new Token("WBTC", "WBTC", 1_000_000 * 1e18);
        Token token1 = new Token("USDC", "USDC", 1_000_000 * 1e18);

        // Deploy AMM
        SimpleAMM amm = new SimpleAMM(address(token0), address(token1));

        // Add liquidity
        token0.approve(address(amm), 100 * 1e18);
        token1.approve(address(amm), 200_000 * 1e18);
        amm.addLiquidity(100 * 1e18, 200_000 * 1e18);

        // Deploy lending
        VulnerableLending lending = new VulnerableLending(
            address(amm),
            address(token0),
            address(token1)
        );
        token1.transfer(address(lending), 100_000 * 1e18);

        // Deploy flashloan provider
        FlashloanProvider flashloan = new FlashloanProvider(address(token1));
        token1.approve(address(flashloan), 500_000 * 1e18);
        flashloan.deposit(500_000 * 1e18);

        console.log("\nDeployment complete!");
        console.log("AMM:", address(amm));
        console.log("Lending:", address(lending));
        console.log("Flashloan:", address(flashloan));

        vm.stopBroadcast();
    }
}
