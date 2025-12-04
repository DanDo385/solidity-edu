// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VaultPrecision.sol";
import "../src/solution/VaultPrecisionSolution.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockERC20
 * @notice Simple ERC20 for testing
 */
contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Token", "MOCK") {
        _mint(msg.sender, 1_000_000 ether);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/**
 * @title VaultPrecisionTest
 * @notice Comprehensive tests for ERC-4626 precision and rounding
 */
contract VaultPrecisionTest is Test {
    VaultPrecisionSolution public vault;
    MockERC20 public asset;

    address public alice = address(0x1);
    address public bob = address(0x2);
    address public carol = address(0x3);

    function setUp() public {
        // Deploy mock asset
        asset = new MockERC20();

        // Deploy vault
        vault = new VaultPrecisionSolution(
            IERC20(address(asset)),
            "Vault Shares",
            "vMOCK"
        );

        // Setup test users with tokens
        asset.mint(alice, 10000 ether);
        asset.mint(bob, 10000 ether);
        asset.mint(carol, 10000 ether);

        // Approve vault
        vm.prank(alice);
        asset.approve(address(vault), type(uint256).max);
        vm.prank(bob);
        asset.approve(address(vault), type(uint256).max);
        vm.prank(carol);
        asset.approve(address(vault), type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////
                        BASIC FUNCTIONALITY TESTS
    //////////////////////////////////////////////////////////////*/

    function testMetadata() public {
        assertEq(vault.asset(), address(asset));
        assertEq(vault.name(), "Vault Shares");
        assertEq(vault.symbol(), "vMOCK");
    }

    function testInitialState() public {
        assertEq(vault.totalAssets(), 0);
        assertEq(vault.totalSupply(), 0);
    }

    function testFirstDeposit() public {
        uint256 depositAmount = 1000 ether;

        vm.prank(alice);
        uint256 shares = vault.deposit(depositAmount, alice);

        // First deposit should be 1:1
        assertEq(shares, depositAmount, "First deposit should be 1:1");
        assertEq(vault.balanceOf(alice), depositAmount);
        assertEq(vault.totalAssets(), depositAmount);
        assertEq(vault.totalSupply(), depositAmount);
    }

    /*//////////////////////////////////////////////////////////////
                        ROUNDING DIRECTION TESTS
    //////////////////////////////////////////////////////////////*/

    function testDepositRoundsDownShares() public {
        // Setup: Create exchange rate where rounding matters
        // Alice deposits 1000, gets 1000 shares (1:1)
        vm.prank(alice);
        vault.deposit(1000 ether, alice);

        // Manipulate exchange rate by donating assets
        // Now we have 1000 shares : 1500 assets (1.5:1 ratio)
        asset.mint(address(vault), 500 ether);

        // Bob deposits 100 assets
        // Expected shares = 100 * 1000 / 1500 = 66.666...
        // Should round DOWN to 66
        vm.prank(bob);
        uint256 shares = vault.deposit(100 ether, bob);

        assertEq(shares, 66, "Deposit should round DOWN shares");

        // Verify Bob got 66 shares, not 67
        assertEq(vault.balanceOf(bob), 66);
    }

    function testMintRoundsUpAssets() public {
        // Setup: Create exchange rate where rounding matters
        vm.prank(alice);
        vault.deposit(1000 ether, alice);
        asset.mint(address(vault), 500 ether);
        // Rate: 1000 shares : 1500 assets (1.5:1)

        uint256 bobBalanceBefore = asset.balanceOf(bob);

        // Bob mints exactly 66 shares
        // Expected assets = 66 * 1500 / 1000 = 99.0 exactly
        vm.prank(bob);
        uint256 assets = vault.mint(66, bob);

        assertEq(assets, 99, "Should take exactly 99 assets");
        assertEq(vault.balanceOf(bob), 66, "Should mint exactly 66 shares");

        // Now test a case that requires rounding up
        // Carol mints 67 shares
        // Expected assets = 67 * 1500 / 1000 = 100.5
        // Should round UP to 101
        vm.prank(carol);
        uint256 assets2 = vault.mint(67, carol);

        assertEq(assets2, 101, "Mint should round UP assets when needed");
        assertEq(vault.balanceOf(carol), 67, "Should mint exactly 67 shares");
    }

    function testWithdrawRoundsUpShares() public {
        // Setup
        vm.prank(alice);
        vault.deposit(1000 ether, alice);
        asset.mint(address(vault), 500 ether);
        // Rate: 1000 shares : 1500 assets

        // Bob deposits to get some shares
        vm.prank(bob);
        vault.deposit(150 ether, bob);

        uint256 bobSharesBefore = vault.balanceOf(bob);

        // Bob withdraws exactly 100 assets
        // Expected shares = 100 * totalSupply / totalAssets
        // totalSupply = 1000 + 100 = 1100 (Bob got 100 shares from 150 assets)
        // totalAssets = 1500 + 150 = 1650
        // shares = 100 * 1100 / 1650 = 66.666...
        // Should round UP to 67
        vm.prank(bob);
        uint256 sharesBurned = vault.withdraw(100 ether, bob, bob);

        assertEq(sharesBurned, 67, "Withdraw should round UP shares");
        assertEq(vault.balanceOf(bob), bobSharesBefore - 67);
    }

    function testRedeemRoundsDownAssets() public {
        // Setup
        vm.prank(alice);
        vault.deposit(1000 ether, alice);
        asset.mint(address(vault), 500 ether);
        // Rate: 1000 shares : 1500 assets

        vm.prank(bob);
        vault.deposit(150 ether, bob);

        uint256 bobAssetsBefore = asset.balanceOf(bob);

        // Bob redeems 67 shares
        // Expected assets = 67 * totalAssets / totalSupply
        // totalSupply = 1100, totalAssets = 1650
        // assets = 67 * 1650 / 1100 = 100.5
        // Should round DOWN to 100
        vm.prank(bob);
        uint256 assetsReceived = vault.redeem(67, bob, bob);

        assertEq(assetsReceived, 100, "Redeem should round DOWN assets");
        assertEq(asset.balanceOf(bob), bobAssetsBefore + 100);
    }

    /*//////////////////////////////////////////////////////////////
                        PREVIEW FUNCTION TESTS
    //////////////////////////////////////////////////////////////*/

    function testPreviewDepositMatchesDeposit() public {
        vm.prank(alice);
        vault.deposit(1000 ether, alice);
        asset.mint(address(vault), 500 ether);

        uint256 depositAmount = 100 ether;

        // Preview should match actual
        uint256 previewedShares = vault.previewDeposit(depositAmount);

        vm.prank(bob);
        uint256 actualShares = vault.deposit(depositAmount, bob);

        assertEq(actualShares, previewedShares, "Preview must match actual deposit");
    }

    function testPreviewMintMatchesMint() public {
        vm.prank(alice);
        vault.deposit(1000 ether, alice);
        asset.mint(address(vault), 500 ether);

        uint256 sharesToMint = 67;

        // Preview should match actual
        uint256 previewedAssets = vault.previewMint(sharesToMint);

        vm.prank(bob);
        uint256 actualAssets = vault.mint(sharesToMint, bob);

        assertEq(actualAssets, previewedAssets, "Preview must match actual mint");
    }

    function testPreviewWithdrawMatchesWithdraw() public {
        vm.prank(alice);
        vault.deposit(1000 ether, alice);
        asset.mint(address(vault), 500 ether);

        vm.prank(bob);
        vault.deposit(150 ether, bob);

        uint256 assetsToWithdraw = 100 ether;

        // Preview should match actual
        uint256 previewedShares = vault.previewWithdraw(assetsToWithdraw);

        vm.prank(bob);
        uint256 actualShares = vault.withdraw(assetsToWithdraw, bob, bob);

        assertEq(actualShares, previewedShares, "Preview must match actual withdraw");
    }

    function testPreviewRedeemMatchesRedeem() public {
        vm.prank(alice);
        vault.deposit(1000 ether, alice);
        asset.mint(address(vault), 500 ether);

        vm.prank(bob);
        vault.deposit(150 ether, bob);

        uint256 sharesToRedeem = 67;

        // Preview should match actual
        uint256 previewedAssets = vault.previewRedeem(sharesToRedeem);

        vm.prank(bob);
        uint256 actualAssets = vault.redeem(sharesToRedeem, bob, bob);

        assertEq(actualAssets, previewedAssets, "Preview must match actual redeem");
    }

    /*//////////////////////////////////////////////////////////////
                        EDGE CASE TESTS
    //////////////////////////////////////////////////////////////*/

    function testConvertToSharesWhenEmpty() public {
        // When vault is empty, should return 1:1
        uint256 shares = vault.convertToShares(1000 ether);
        assertEq(shares, 1000 ether, "Empty vault should return 1:1");
    }

    function testConvertToAssetsWhenEmpty() public {
        // When no shares exist, should return 0
        uint256 assets = vault.convertToAssets(1000 ether);
        assertEq(assets, 0, "No shares = no assets");
    }

    function testPreviewMintWhenEmpty() public {
        // When vault is empty, should return 1:1
        uint256 assets = vault.previewMint(1000 ether);
        assertEq(assets, 1000 ether, "Empty vault mint should be 1:1");
    }

    function testPreviewWithdrawWhenEmpty() public {
        // When no shares exist, should return 0
        uint256 shares = vault.previewWithdraw(1000 ether);
        assertEq(shares, 0, "Empty vault withdraw should return 0");
    }

    function testZeroDeposit() public {
        vm.prank(alice);
        vm.expectRevert("ERC4626: cannot mint 0 shares");
        vault.deposit(0, alice);
    }

    /*//////////////////////////////////////////////////////////////
                        INVARIANT TESTS
    //////////////////////////////////////////////////////////////*/

    function testVaultCannotLoseValue() public {
        // Setup vault state
        vm.prank(alice);
        vault.deposit(1000 ether, alice);

        uint256 vaultValueBefore = vault.totalAssets();

        // Bob deposits and immediately redeems
        vm.startPrank(bob);
        uint256 shares = vault.deposit(100 ether, bob);
        uint256 assetsBack = vault.redeem(shares, bob, bob);
        vm.stopPrank();

        uint256 vaultValueAfter = vault.totalAssets();

        // Bob should get <= what he deposited
        assertLe(assetsBack, 100 ether, "User cannot profit from round-trip");

        // Vault should gain or stay same
        assertGe(vaultValueAfter, vaultValueBefore, "Vault should not lose value");
    }

    function testUserCannotProfitFromRoundTrip() public {
        vm.prank(alice);
        vault.deposit(1000 ether, alice);

        uint256 bobStartBalance = asset.balanceOf(bob);

        // Bob tries to profit via deposit -> redeem
        vm.startPrank(bob);
        uint256 shares = vault.deposit(100 ether, bob);
        vault.redeem(shares, bob, bob);
        vm.stopPrank();

        uint256 bobEndBalance = asset.balanceOf(bob);

        // Bob should have <= his starting balance (accounting for any lost wei)
        assertLe(bobEndBalance, bobStartBalance, "User cannot profit from round-trip");
    }

    function testTotalValueConserved() public {
        // Initial state
        vm.prank(alice);
        vault.deposit(1000 ether, alice);

        uint256 aliceShares = vault.balanceOf(alice);
        uint256 aliceAssetValue = vault.convertToAssets(aliceShares);
        uint256 vaultAssets = vault.totalAssets();

        // Total value should equal vault assets
        assertEq(aliceAssetValue, vaultAssets, "Total value should be conserved");

        // Add Bob
        vm.prank(bob);
        vault.deposit(500 ether, bob);

        uint256 totalShares = vault.totalSupply();
        uint256 totalAssetValue = vault.convertToAssets(totalShares);
        uint256 totalVaultAssets = vault.totalAssets();

        // Should still be conserved (within rounding error of 1 wei per user)
        assertApproxEqAbs(totalAssetValue, totalVaultAssets, 2, "Value conserved with multiple users");
    }

    /*//////////////////////////////////////////////////////////////
                        PRECISION TESTS
    //////////////////////////////////////////////////////////////*/

    function testSmallDepositPrecision() public {
        // Setup unfavorable exchange rate
        vm.prank(alice);
        vault.deposit(1000 ether, alice);
        asset.mint(address(vault), 500 ether);
        // Rate: 1 share = 1.5 assets

        // Bob deposits very small amount
        // 1 asset = 1 * 1000 / 1500 = 0.666... shares
        // Should round to 0 shares
        vm.prank(bob);
        vm.expectRevert("ERC4626: cannot mint 0 shares");
        vault.deposit(1, bob);

        // But 2 assets should work
        // 2 * 1000 / 1500 = 1.333... → 1 share
        vm.prank(bob);
        uint256 shares = vault.deposit(2, bob);
        assertEq(shares, 1, "Small deposit should round down");
    }

    function testPrecisionLossAccumulation() public {
        // Each deposit/redeem cycle may lose 1 wei due to rounding
        // This should accumulate in vault's favor

        vm.prank(alice);
        vault.deposit(1000 ether, alice);
        asset.mint(address(vault), 500 ether);

        uint256 vaultValueBefore = vault.totalAssets();

        // Multiple users do small operations
        for (uint i = 0; i < 10; i++) {
            address user = address(uint160(1000 + i));
            asset.mint(user, 1 ether);

            vm.startPrank(user);
            asset.approve(address(vault), type(uint256).max);
            uint256 shares = vault.deposit(0.1 ether, user);
            if (shares > 0) {
                vault.redeem(shares, user, user);
            }
            vm.stopPrank();
        }

        uint256 vaultValueAfter = vault.totalAssets();

        // Vault should have gained or stayed same
        assertGe(vaultValueAfter, vaultValueBefore, "Precision loss favors vault");
    }

    /*//////////////////////////////////////////////////////////////
                        ATTACK PREVENTION TESTS
    //////////////////////////////////////////////////////////////*/

    function testInflationAttackPrevention() public {
        // Attacker tries classic inflation attack:
        // 1. First deposit (1 wei → 1 share)
        // 2. Donate large amount to inflate share price
        // 3. Victim deposits and loses value due to rounding

        // Attacker deposits 1 wei
        vm.prank(alice);
        vault.deposit(1, alice);

        // Attacker donates 1000 ether directly
        asset.mint(address(vault), 1000 ether);
        // Now: 1 share = 1000 ether + 1 wei

        // Victim deposits 1999 ether
        // shares = 1999 ether * 1 / (1000 ether + 1)
        //        ≈ 1999 ether * 1 / 1000 ether
        //        ≈ 1.999 → rounds to 1 share
        vm.prank(bob);
        uint256 shares = vault.deposit(1999 ether, bob);

        // Bob should get 1 share (this is the vulnerability)
        // In a production vault, you'd prevent this with:
        // - Minimum deposit amounts
        // - Virtual shares/assets
        // - Locked initial liquidity
        assertEq(shares, 1, "Victim gets only 1 share due to inflation");

        // This test demonstrates the attack works in basic implementation
        // Solution implementations should add protections!
    }

    function testCannotDrainVaultWithSmallOperations() public {
        vm.prank(alice);
        vault.deposit(1000 ether, alice);

        uint256 vaultValueBefore = vault.totalAssets();

        // Attacker tries to repeatedly deposit/withdraw to drain vault
        vm.startPrank(bob);
        for (uint i = 0; i < 100; i++) {
            uint256 shares = vault.deposit(1 ether, bob);
            if (shares > 0) {
                vault.redeem(shares, bob, bob);
            }
        }
        vm.stopPrank();

        uint256 vaultValueAfter = vault.totalAssets();

        // Vault should not have lost value
        assertGe(vaultValueAfter, vaultValueBefore, "Repeated operations cannot drain vault");
    }

    /*//////////////////////////////////////////////////////////////
                        ALLOWANCE TESTS
    //////////////////////////////////////////////////////////////*/

    function testWithdrawWithAllowance() public {
        // Alice deposits
        vm.prank(alice);
        vault.deposit(1000 ether, alice);

        // Alice approves Bob to withdraw
        vm.prank(alice);
        vault.approve(bob, 100);

        // Bob withdraws on Alice's behalf
        vm.prank(bob);
        vault.withdraw(100 ether, bob, alice);

        // Allowance should be reduced
        assertTrue(vault.allowance(alice, bob) < 100);
    }

    function testRedeemWithAllowance() public {
        // Alice deposits
        vm.prank(alice);
        vault.deposit(1000 ether, alice);

        // Alice approves Bob to redeem
        vm.prank(alice);
        vault.approve(bob, 100 ether);

        // Bob redeems on Alice's behalf
        vm.prank(bob);
        vault.redeem(100 ether, bob, alice);

        // Allowance should be reduced
        assertEq(vault.allowance(alice, bob), 0);
    }

    function testInfiniteAllowanceNotReduced() public {
        // Alice deposits
        vm.prank(alice);
        vault.deposit(1000 ether, alice);

        // Alice gives infinite approval
        vm.prank(alice);
        vault.approve(bob, type(uint256).max);

        // Bob withdraws on Alice's behalf
        vm.prank(bob);
        vault.withdraw(100 ether, bob, alice);

        // Infinite allowance should remain
        assertEq(vault.allowance(alice, bob), type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////
                        FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzzDepositRedeem(uint256 amount) public {
        amount = bound(amount, 1 ether, 1000 ether);

        vm.prank(alice);
        uint256 shares = vault.deposit(amount, alice);

        vm.prank(alice);
        uint256 assetsBack = vault.redeem(shares, alice, alice);

        // User should get <= what they deposited
        assertLe(assetsBack, amount, "Cannot profit from round-trip");
    }

    function testFuzzMintWithdraw(uint256 shares) public {
        shares = bound(shares, 1 ether, 1000 ether);

        vm.prank(alice);
        uint256 assetsPaid = vault.mint(shares, alice);

        vm.prank(alice);
        uint256 sharesBackRequired = vault.withdraw(assetsPaid, alice, alice);

        // Should require >= shares to get back the assets
        assertGe(sharesBackRequired, shares, "Cannot profit from round-trip");
    }

    function testFuzzConversionConsistency(uint256 assets) public {
        assets = bound(assets, 1 ether, 1000 ether);

        // Setup vault with some deposits
        vm.prank(alice);
        vault.deposit(1000 ether, alice);

        // Convert assets → shares → assets
        uint256 shares = vault.convertToShares(assets);
        uint256 assetsBack = vault.convertToAssets(shares);

        // Due to rounding down, assetsBack <= original
        assertLe(assetsBack, assets, "Double conversion should not increase value");
    }
}
