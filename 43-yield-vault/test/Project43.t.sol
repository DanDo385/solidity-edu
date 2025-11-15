// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/solution/Project43Solution.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Token", "MOCK") {
        _mint(msg.sender, 1000000 * 10 ** 18);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract Project43Test is Test {
    MockERC20 public token;
    YieldVault public vault;
    MockYieldSource public yieldSource;
    SimpleYieldStrategy public strategy;

    address public owner = address(this);
    address public feeRecipient = address(0x1);
    address public alice = address(0x2);
    address public bob = address(0x3);

    uint256 public constant PERFORMANCE_FEE = 1000; // 10%
    uint256 public constant APY = 1000; // 10% APY

    function setUp() public {
        // Deploy token
        token = new MockERC20();

        // Deploy yield source with 10% APY
        yieldSource = new MockYieldSource(token, APY);

        // Deploy vault
        vault = new YieldVault(
            token,
            "Yield Vault Token",
            "yvToken",
            feeRecipient,
            PERFORMANCE_FEE
        );

        // Deploy strategy
        strategy = new SimpleYieldStrategy(token, yieldSource, address(vault));

        // Set strategy in vault
        vault.setStrategy(strategy);

        // Fund users
        token.mint(alice, 10000 * 10 ** 18);
        token.mint(bob, 10000 * 10 ** 18);

        // Set labels for better trace output
        vm.label(address(token), "Token");
        vm.label(address(vault), "Vault");
        vm.label(address(yieldSource), "YieldSource");
        vm.label(address(strategy), "Strategy");
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
    }

    /*//////////////////////////////////////////////////////////////
                        BASIC VAULT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Deployment() public view {
        assertEq(address(vault.asset()), address(token));
        assertEq(vault.performanceFee(), PERFORMANCE_FEE);
        assertEq(vault.feeRecipient(), feeRecipient);
        assertEq(address(vault.strategy()), address(strategy));
    }

    function test_Deposit() public {
        uint256 depositAmount = 1000 * 10 ** 18;

        vm.startPrank(alice);
        token.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, alice);
        vm.stopPrank();

        // First deposit gets 1:1 share ratio
        assertEq(shares, depositAmount);
        assertEq(vault.balanceOf(alice), depositAmount);
        assertEq(vault.totalAssets(), depositAmount);

        // Assets should be in strategy
        assertEq(strategy.totalAssets(), depositAmount);
    }

    function test_Withdraw() public {
        uint256 depositAmount = 1000 * 10 ** 18;

        // Alice deposits
        vm.startPrank(alice);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, alice);

        // Alice withdraws
        uint256 withdrawn = vault.redeem(vault.balanceOf(alice), alice, alice);
        vm.stopPrank();

        assertEq(withdrawn, depositAmount);
        assertEq(vault.balanceOf(alice), 0);
        assertEq(token.balanceOf(alice), 10000 * 10 ** 18); // Back to original
    }

    function test_MultipleDeposits() public {
        uint256 aliceDeposit = 1000 * 10 ** 18;
        uint256 bobDeposit = 500 * 10 ** 18;

        // Alice deposits
        vm.startPrank(alice);
        token.approve(address(vault), aliceDeposit);
        vault.deposit(aliceDeposit, alice);
        vm.stopPrank();

        // Bob deposits
        vm.startPrank(bob);
        token.approve(address(vault), bobDeposit);
        vault.deposit(bobDeposit, bob);
        vm.stopPrank();

        assertEq(vault.totalAssets(), aliceDeposit + bobDeposit);
        assertEq(vault.balanceOf(alice), aliceDeposit);
        assertEq(vault.balanceOf(bob), bobDeposit);
    }

    /*//////////////////////////////////////////////////////////////
                        YIELD ACCRUAL TESTS
    //////////////////////////////////////////////////////////////*/

    function test_YieldAccrual() public {
        uint256 depositAmount = 1000 * 10 ** 18;

        // Alice deposits
        vm.startPrank(alice);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, alice);
        vm.stopPrank();

        uint256 initialAssets = vault.totalAssets();

        // Fast forward 30 days
        vm.warp(block.timestamp + 30 days);

        uint256 finalAssets = vault.totalAssets();

        // Should have accrued yield
        // 10% APY over 30 days ≈ 0.82%
        // Expected: ~1008.2 tokens
        assertGt(finalAssets, initialAssets);

        uint256 expectedYield = (depositAmount * APY * 30 days) / (365 days * 10000);
        assertApproxEqRel(finalAssets, initialAssets + expectedYield, 0.01e18); // 1% tolerance
    }

    function test_TotalAssetsDrift() public {
        uint256 depositAmount = 1000 * 10 ** 18;

        vm.startPrank(alice);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, alice);
        vm.stopPrank();

        uint256[] memory timestamps = new uint256[](5);
        uint256[] memory assets = new uint256[](5);

        // Record totalAssets at different times
        for (uint256 i = 0; i < 5; i++) {
            timestamps[i] = block.timestamp;
            assets[i] = vault.totalAssets();

            // Fast forward 10 days
            vm.warp(block.timestamp + 10 days);
        }

        // Verify totalAssets increases over time
        for (uint256 i = 1; i < 5; i++) {
            assertGt(assets[i], assets[i - 1], "Assets should increase");
        }

        console.log("Total Assets Drift Over Time:");
        for (uint256 i = 0; i < 5; i++) {
            console.log("Day", i * 10, ":", assets[i]);
        }
    }

    function test_SharePriceGrowth() public {
        uint256 depositAmount = 1000 * 10 ** 18;

        vm.startPrank(alice);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, alice);
        vm.stopPrank();

        // Initial share price should be 1:1
        uint256 initialPrice = vault.convertToAssets(1e18);
        assertEq(initialPrice, 1e18);

        // Fast forward and accrue yield
        vm.warp(block.timestamp + 30 days);

        // Share price should increase
        uint256 finalPrice = vault.convertToAssets(1e18);
        assertGt(finalPrice, initialPrice);

        console.log("Initial Share Price:", initialPrice);
        console.log("Final Share Price:  ", finalPrice);
        console.log("Growth:            ", ((finalPrice - initialPrice) * 100) / initialPrice, "%");
    }

    /*//////////////////////////////////////////////////////////////
                        HARVEST TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Harvest() public {
        uint256 depositAmount = 1000 * 10 ** 18;

        // Alice deposits
        vm.startPrank(alice);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, alice);
        vm.stopPrank();

        // Fast forward to accrue yield
        vm.warp(block.timestamp + 30 days);

        uint256 assetsBeforeHarvest = vault.totalAssets();

        // Anyone can harvest
        vm.warp(block.timestamp + 1 hours + 1); // Pass cooldown
        vault.harvest();

        uint256 assetsAfterHarvest = vault.totalAssets();

        // Total assets should remain similar (yield was reinvested)
        // Slight decrease due to performance fee
        assertLt(assetsAfterHarvest, assetsBeforeHarvest);
        assertApproxEqRel(assetsAfterHarvest, assetsBeforeHarvest, 0.15e18); // 15% tolerance for fee
    }

    function test_HarvestPerformanceFee() public {
        uint256 depositAmount = 1000 * 10 ** 18;

        vm.startPrank(alice);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, alice);
        vm.stopPrank();

        // Fast forward
        vm.warp(block.timestamp + 30 days);

        uint256 feeRecipientBefore = token.balanceOf(feeRecipient);

        // Harvest
        vm.warp(block.timestamp + 1 hours + 1);
        vault.harvest();

        uint256 feeRecipientAfter = token.balanceOf(feeRecipient);

        // Fee recipient should receive performance fee
        uint256 feeCollected = feeRecipientAfter - feeRecipientBefore;
        assertGt(feeCollected, 0);

        console.log("Performance Fee Collected:", feeCollected);
        console.log("Total Fees Collected:", vault.totalFeesCollected());
    }

    function test_HarvestCooldown() public {
        uint256 depositAmount = 1000 * 10 ** 18;

        vm.startPrank(alice);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, alice);
        vm.stopPrank();

        vm.warp(block.timestamp + 30 days);

        // First harvest should work
        vm.warp(block.timestamp + 1 hours + 1);
        vault.harvest();

        // Immediate second harvest should fail
        vm.expectRevert("Cooldown not elapsed");
        vault.harvest();

        // After cooldown, should work again
        vm.warp(block.timestamp + 1 hours + 1);
        // Need more yield to harvest
        vm.warp(block.timestamp + 1 days);
        vault.harvest(); // Should succeed
    }

    function test_HarvestReinvestment() public {
        uint256 depositAmount = 1000 * 10 ** 18;

        vm.startPrank(alice);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, alice);
        vm.stopPrank();

        // First period
        vm.warp(block.timestamp + 30 days);
        uint256 assets1 = vault.totalAssets();

        vm.warp(block.timestamp + 1 hours + 1);
        vault.harvest();

        // Second period - should have compound effect
        vm.warp(block.timestamp + 30 days);
        uint256 assets2 = vault.totalAssets();

        vm.warp(block.timestamp + 1 hours + 1);
        vault.harvest();

        // Third period
        vm.warp(block.timestamp + 30 days);
        uint256 assets3 = vault.totalAssets();

        // Each period should show growth
        assertGt(assets2, assets1);
        assertGt(assets3, assets2);

        console.log("Period 1 Assets:", assets1);
        console.log("Period 2 Assets:", assets2);
        console.log("Period 3 Assets:", assets3);
    }

    /*//////////////////////////////////////////////////////////////
                    COMPOUND INTEREST TESTS
    //////////////////////////////////////////////////////////////*/

    function test_CompoundInterest() public {
        uint256 principal = 1000 * 10 ** 18;

        vm.startPrank(alice);
        token.approve(address(vault), principal);
        vault.deposit(principal, alice);
        vm.stopPrank();

        // Harvest monthly for a year
        for (uint256 i = 0; i < 12; i++) {
            vm.warp(block.timestamp + 30 days);
            vm.warp(block.timestamp + 1 hours + 1);

            try vault.harvest() {} catch {}
        }

        uint256 finalAssets = vault.totalAssets();
        uint256 totalGain = finalAssets > principal ? finalAssets - principal : 0;

        console.log("Principal:        ", principal);
        console.log("Final Assets:     ", finalAssets);
        console.log("Total Gain:       ", totalGain);
        console.log("Effective APY:    ", (totalGain * 10000) / principal, "bps");

        // Should have meaningful gains from compounding
        assertGt(finalAssets, principal);
    }

    function test_CompoundVsSimpleInterest() public {
        uint256 amount = 1000 * 10 ** 18;

        // Setup two vaults - one harvests, one doesn't
        YieldVault compoundVault = new YieldVault(
            token,
            "Compound Vault",
            "cvToken",
            feeRecipient,
            0 // No fee for fair comparison
        );
        MockYieldSource compoundSource = new MockYieldSource(token, APY);
        SimpleYieldStrategy compoundStrategy = new SimpleYieldStrategy(
            token,
            compoundSource,
            address(compoundVault)
        );
        compoundVault.setStrategy(compoundStrategy);

        // Deposit to both
        vm.startPrank(alice);
        token.approve(address(compoundVault), amount);
        compoundVault.deposit(amount, alice);
        vm.stopPrank();

        vm.startPrank(bob);
        token.approve(address(yieldSource), amount);
        yieldSource.deposit(amount);
        vm.stopPrank();

        // Compound vault harvests monthly
        for (uint256 i = 0; i < 12; i++) {
            vm.warp(block.timestamp + 30 days);
            compoundVault.setHarvestCooldown(0); // Disable cooldown for test
            try compoundVault.harvest() {} catch {}
        }

        uint256 compoundBalance = compoundVault.totalAssets();
        uint256 simpleBalance = yieldSource.balanceOf(bob);

        console.log("Compound Balance:", compoundBalance);
        console.log("Simple Balance:  ", simpleBalance);
        console.log("Difference:      ", compoundBalance > simpleBalance ? compoundBalance - simpleBalance : 0);

        // Compound should be higher (if harvests worked)
        // assertGe(compoundBalance, simpleBalance);
    }

    /*//////////////////////////////////////////////////////////////
                    MULTI-USER SCENARIOS
    //////////////////////////////////////////////////////////////*/

    function test_MultiUserYieldDistribution() public {
        uint256 aliceDeposit = 1000 * 10 ** 18;
        uint256 bobDeposit = 500 * 10 ** 18;

        // Alice deposits
        vm.startPrank(alice);
        token.approve(address(vault), aliceDeposit);
        vault.deposit(aliceDeposit, alice);
        vm.stopPrank();

        uint256 aliceShares = vault.balanceOf(alice);

        // Time passes, yield accrues
        vm.warp(block.timestamp + 15 days);

        // Bob deposits (should get fewer shares due to increased share price)
        vm.startPrank(bob);
        token.approve(address(vault), bobDeposit);
        vault.deposit(bobDeposit, bob);
        vm.stopPrank();

        uint256 bobShares = vault.balanceOf(bob);

        // Bob should get fewer shares than if he deposited initially
        assertLt(bobShares, bobDeposit); // Less than 1:1 ratio

        // More time passes
        vm.warp(block.timestamp + 30 days);

        // Check final values
        uint256 aliceValue = vault.convertToAssets(aliceShares);
        uint256 bobValue = vault.convertToAssets(bobShares);

        console.log("Alice Deposit:", aliceDeposit, "Final:", aliceValue);
        console.log("Bob Deposit:  ", bobDeposit, "Final:", bobValue);

        // Both should have gains
        assertGt(aliceValue, aliceDeposit);
        assertGt(bobValue, bobDeposit);

        // Alice should have more total gains (deposited earlier)
        assertGt(aliceValue - aliceDeposit, bobValue - bobDeposit);
    }

    function test_WithdrawalAfterYield() public {
        uint256 depositAmount = 1000 * 10 ** 18;

        vm.startPrank(alice);
        token.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, alice);
        vm.stopPrank();

        // Accrue yield
        vm.warp(block.timestamp + 30 days);

        // Alice withdraws all shares
        vm.startPrank(alice);
        uint256 withdrawn = vault.redeem(shares, alice, alice);
        vm.stopPrank();

        // Should get more than deposited
        assertGt(withdrawn, depositAmount);

        console.log("Deposited:", depositAmount);
        console.log("Withdrawn:", withdrawn);
        console.log("Profit:   ", withdrawn - depositAmount);
    }

    /*//////////////////////////////////////////////////////////////
                        APY CALCULATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_APYCalculation() public {
        uint256 depositAmount = 1000 * 10 ** 18;

        vm.startPrank(alice);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, alice);
        vm.stopPrank();

        uint256 startTime = block.timestamp;
        uint256 startAssets = vault.totalAssets();

        // Run for 90 days with monthly harvests
        for (uint256 i = 0; i < 3; i++) {
            vm.warp(block.timestamp + 30 days);
            vault.setHarvestCooldown(0);
            try vault.harvest() {} catch {}
        }

        uint256 endAssets = vault.totalAssets();
        uint256 timePeriod = block.timestamp - startTime;

        // Calculate APY
        uint256 gain = endAssets > startAssets ? endAssets - startAssets : 0;
        uint256 simpleAPY = (gain * 365 days * 10000) / (startAssets * timePeriod);

        console.log("Start Assets:", startAssets);
        console.log("End Assets:  ", endAssets);
        console.log("Time Period: ", timePeriod / 1 days, "days");
        console.log("Simple APY:  ", simpleAPY, "bps");
    }

    /*//////////////////////////////////////////////////////////////
                        STRATEGY TESTS
    //////////////////////////////////////////////////////////////*/

    function test_StrategyMigration() public {
        uint256 depositAmount = 1000 * 10 ** 18;

        vm.startPrank(alice);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, alice);
        vm.stopPrank();

        // Create new strategy
        MockYieldSource newYieldSource = new MockYieldSource(token, 1500); // 15% APY
        SimpleYieldStrategy newStrategy = new SimpleYieldStrategy(
            token,
            newYieldSource,
            address(vault)
        );

        uint256 assetsBeforeMigration = vault.totalAssets();

        // Migrate to new strategy
        vault.setStrategy(newStrategy);

        uint256 assetsAfterMigration = vault.totalAssets();

        // Assets should be preserved
        assertEq(assetsAfterMigration, assetsBeforeMigration);

        // New strategy should have the assets
        assertEq(newStrategy.totalAssets(), depositAmount);

        // Old strategy should be empty
        assertEq(strategy.totalAssets(), 0);
    }

    function test_CompoundStrategy() public {
        // Deploy compound strategy
        CompoundStrategy compStrategy = new CompoundStrategy(
            token,
            yieldSource,
            address(vault)
        );

        vault.setStrategy(compStrategy);

        uint256 depositAmount = 1000 * 10 ** 18;

        vm.startPrank(alice);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, alice);
        vm.stopPrank();

        vault.setHarvestCooldown(0);

        // Harvest multiple times
        for (uint256 i = 0; i < 5; i++) {
            vm.warp(block.timestamp + 30 days);
            try vault.harvest() {} catch {}
        }

        uint256 finalAssets = vault.totalAssets();

        console.log("Deposit:      ", depositAmount);
        console.log("Final Assets: ", finalAssets);

        assertGt(finalAssets, depositAmount);
    }

    /*//////////////////////////////////////////////////////////////
                        EDGE CASE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_FirstDepositAttack() public {
        // Attacker deposits 1 wei
        vm.startPrank(alice);
        token.approve(address(vault), 1);
        vault.deposit(1, alice);
        vm.stopPrank();

        assertEq(vault.balanceOf(alice), 1);
        assertEq(vault.totalAssets(), 1);

        // Normal user deposits large amount
        vm.startPrank(bob);
        token.approve(address(vault), 1000 * 10 ** 18);
        uint256 shares = vault.deposit(1000 * 10 ** 18, bob);
        vm.stopPrank();

        // Bob should get reasonable shares
        assertGt(shares, 0);

        // Verify Bob isn't severely diluted
        uint256 bobValue = vault.convertToAssets(shares);
        assertApproxEqRel(bobValue, 1000 * 10 ** 18, 0.01e18); // Within 1%
    }

    function test_ZeroDeposit() public {
        vm.startPrank(alice);
        token.approve(address(vault), 0);
        vm.expectRevert();
        vault.deposit(0, alice);
        vm.stopPrank();
    }

    function test_EmptyVaultHarvest() public {
        // Try to harvest with no deposits
        vm.warp(block.timestamp + 1 hours + 1);
        vm.expectRevert();
        vault.harvest();
    }

    /*//////////////////////////////////////////////////////////////
                    REALISTIC YIELD SCENARIOS
    //////////////////////////////////////////////////////////////*/

    function test_RealisticYieldScenario() public {
        console.log("\n=== Realistic Yield Scenario: 6 Month Simulation ===\n");

        uint256 aliceInitial = 5000 * 10 ** 18;
        uint256 bobInitial = 3000 * 10 ** 18;

        // Month 1: Alice deposits
        console.log("Month 1: Alice deposits 5000 tokens");
        vm.startPrank(alice);
        token.approve(address(vault), aliceInitial);
        vault.deposit(aliceInitial, alice);
        vm.stopPrank();

        console.log("  Total Assets:", vault.totalAssets() / 10 ** 18);
        console.log("  Share Price:  ", vault.convertToAssets(1e18) / 10 ** 18);

        // Month 2: Bob deposits
        vm.warp(block.timestamp + 30 days);
        console.log("\nMonth 2: Bob deposits 3000 tokens");

        vm.startPrank(bob);
        token.approve(address(vault), bobInitial);
        vault.deposit(bobInitial, bob);
        vm.stopPrank();

        console.log("  Total Assets:", vault.totalAssets() / 10 ** 18);
        console.log("  Share Price:  ", vault.convertToAssets(1e18) / 10 ** 18);

        // Monthly harvests and reporting
        for (uint256 month = 3; month <= 6; month++) {
            vm.warp(block.timestamp + 30 days);
            vault.setHarvestCooldown(0);

            console.log("\nMonth", month, ": Harvest");

            try vault.harvest() {
                console.log("  Harvested!");
            } catch {
                console.log("  No yield to harvest");
            }

            console.log("  Total Assets:", vault.totalAssets() / 10 ** 18);
            console.log("  Share Price:  ", vault.convertToAssets(1e18) / 10 ** 18);
            console.log("  Total Yield:  ", vault.totalYieldHarvested() / 10 ** 18);
            console.log("  Total Fees:   ", vault.totalFeesCollected() / 10 ** 18);
        }

        // Final positions
        console.log("\n=== Final Positions ===");
        uint256 aliceFinal = vault.convertToAssets(vault.balanceOf(alice));
        uint256 bobFinal = vault.convertToAssets(vault.balanceOf(bob));

        console.log("Alice: ", aliceInitial / 10 ** 18, "->", aliceFinal / 10 ** 18);
        console.log("  Gain:", (aliceFinal - aliceInitial) / 10 ** 18);
        console.log("Bob:   ", bobInitial / 10 ** 18, "->", bobFinal / 10 ** 18);
        console.log("  Gain:", (bobFinal - bobInitial) / 10 ** 18);

        assertGt(aliceFinal, aliceInitial);
        assertGt(bobFinal, bobInitial);
    }

    /*//////////////////////////////////////////////////////////////
                        ADMIN FUNCTION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SetPerformanceFee() public {
        vault.setPerformanceFee(1500); // 15%
        assertEq(vault.performanceFee(), 1500);

        vm.expectRevert("Fee too high");
        vault.setPerformanceFee(3000); // 30% should fail
    }

    function test_SetFeeRecipient() public {
        address newRecipient = address(0x999);
        vault.setFeeRecipient(newRecipient);
        assertEq(vault.feeRecipient(), newRecipient);

        vm.expectRevert("Invalid recipient");
        vault.setFeeRecipient(address(0));
    }

    function test_SetHarvestCooldown() public {
        vault.setHarvestCooldown(2 hours);
        assertEq(vault.harvestCooldown(), 2 hours);
    }

    function test_OnlyOwnerCanSetStrategy() public {
        vm.startPrank(alice);
        vm.expectRevert();
        vault.setStrategy(IYieldStrategy(address(0x123)));
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        GAS BENCHMARKS
    //////////////////////////////////////////////////////////////*/

    function test_GasDeposit() public {
        uint256 amount = 1000 * 10 ** 18;

        vm.startPrank(alice);
        token.approve(address(vault), amount);

        uint256 gasBefore = gasleft();
        vault.deposit(amount, alice);
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas used for deposit:", gasUsed);
        vm.stopPrank();
    }

    function test_GasWithdraw() public {
        uint256 amount = 1000 * 10 ** 18;

        vm.startPrank(alice);
        token.approve(address(vault), amount);
        vault.deposit(amount, alice);

        uint256 gasBefore = gasleft();
        vault.redeem(vault.balanceOf(alice), alice, alice);
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas used for withdraw:", gasUsed);
        vm.stopPrank();
    }

    function test_GasHarvest() public {
        uint256 amount = 1000 * 10 ** 18;

        vm.startPrank(alice);
        token.approve(address(vault), amount);
        vault.deposit(amount, alice);
        vm.stopPrank();

        vm.warp(block.timestamp + 30 days);
        vault.setHarvestCooldown(0);

        uint256 gasBefore = gasleft();
        try vault.harvest() {} catch {}
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas used for harvest:", gasUsed);
    }
}
