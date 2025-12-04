// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/MetaVaultSolution.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

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
 * @notice Simple ERC4626 vault for testing meta-vault
 * @dev Simulates a real vault with configurable yield
 */
contract MockVault is ERC4626 {
    uint256 public yieldRate; // Yield rate in basis points per call to accrueYield()
    uint256 public totalYield; // Total yield accumulated

    constructor(
        IERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC4626(_asset) ERC20(_name, _symbol) {
        yieldRate = 100; // 1% default
    }

    /**
     * @notice Simulate yield accumulation
     * @dev Increases totalAssets by minting new tokens to the vault
     */
    function accrueYield() external {
        uint256 currentAssets = IERC20(asset()).balanceOf(address(this));
        uint256 yield = (currentAssets * yieldRate) / 10000;

        if (yield > 0) {
            MockERC20(asset()).mint(address(this), yield);
            totalYield += yield;
        }
    }

    /**
     * @notice Set the yield rate
     * @param _yieldRate Yield rate in basis points
     */
    function setYieldRate(uint256 _yieldRate) external {
        yieldRate = _yieldRate;
    }

    /**
     * @notice Override totalAssets to include vault balance
     */
    function totalAssets() public view override returns (uint256) {
        return IERC20(asset()).balanceOf(address(this));
    }
}

/**
 * @title MetaVaultTest
 * @notice Comprehensive tests for MetaVault
 */
contract MetaVaultTest is Test {
    MockERC20 public asset;
    MockVault public vaultA;
    MockVault public vaultB;
    MockVault public vaultC;
    MetaVaultSolution public metaVault;

    address public alice = address(0x1);
    address public bob = address(0x2);
    address public owner = address(this);

    uint256 constant INITIAL_BALANCE = 100000e18;

    function setUp() public {
        // Deploy asset
        asset = new MockERC20("Test Token", "TEST");

        // Deploy underlying vaults
        vaultA = new MockVault(asset, "Vault A", "vA");
        vaultB = new MockVault(asset, "Vault B", "vB");
        vaultC = new MockVault(asset, "Vault C", "vC");

        // Set different yield rates
        vaultA.setYieldRate(100); // 1%
        vaultB.setYieldRate(200); // 2%
        vaultC.setYieldRate(150); // 1.5%

        // Deploy meta-vault
        metaVault = new MetaVaultSolution(asset, "Meta Vault", "META");

        // Setup users
        asset.transfer(alice, INITIAL_BALANCE);
        asset.transfer(bob, INITIAL_BALANCE);

        vm.prank(alice);
        asset.approve(address(metaVault), type(uint256).max);

        vm.prank(bob);
        asset.approve(address(metaVault), type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////
                        VAULT MANAGEMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function testAddVault() public {
        // Add vault A with 50% allocation
        metaVault.addVault(vaultA, 5000);

        assertEq(metaVault.getVaultCount(), 1);
        assertEq(address(metaVault.underlyingVaults(0)), address(vaultA));
        assertEq(metaVault.targetAllocations(0), 5000);
        assertTrue(metaVault.isVault(address(vaultA)));
    }

    function testAddMultipleVaults() public {
        metaVault.addVault(vaultA, 5000); // 50%
        metaVault.addVault(vaultB, 3000); // 30%
        metaVault.addVault(vaultC, 2000); // 20%

        assertEq(metaVault.getVaultCount(), 3);
        assertEq(metaVault.targetAllocations(0), 5000);
        assertEq(metaVault.targetAllocations(1), 3000);
        assertEq(metaVault.targetAllocations(2), 2000);
    }

    function testCannotAddVaultWithWrongAsset() public {
        MockERC20 differentAsset = new MockERC20("Different", "DIFF");
        MockVault wrongVault = new MockVault(differentAsset, "Wrong Vault", "WRONG");

        vm.expectRevert(MetaVaultSolution.InvalidAsset.selector);
        metaVault.addVault(wrongVault, 5000);
    }

    function testCannotAddDuplicateVault() public {
        metaVault.addVault(vaultA, 5000);

        vm.expectRevert(MetaVaultSolution.VaultAlreadyAdded.selector);
        metaVault.addVault(vaultA, 3000);
    }

    function testCannotExceedTotalAllocation() public {
        metaVault.addVault(vaultA, 6000);
        metaVault.addVault(vaultB, 3000);

        // Total would be 6000 + 3000 + 2000 = 11000 > 10000
        vm.expectRevert(MetaVaultSolution.InvalidAllocation.selector);
        metaVault.addVault(vaultC, 2000);
    }

    function testRemoveVault() public {
        // Add vaults
        metaVault.addVault(vaultA, 5000);
        metaVault.addVault(vaultB, 3000);

        // Deposit some assets to create positions
        vm.prank(alice);
        metaVault.deposit(10000e18, alice);

        // Remove vault A
        metaVault.removeVault(0);

        assertEq(metaVault.getVaultCount(), 1);
        assertFalse(metaVault.isVault(address(vaultA)));

        // Vault B should now be at index 0 (swap-and-pop)
        assertEq(address(metaVault.underlyingVaults(0)), address(vaultB));
    }

    function testUpdateAllocation() public {
        metaVault.addVault(vaultA, 5000);
        metaVault.addVault(vaultB, 3000);

        // Update vault A to 6000
        metaVault.updateAllocation(0, 6000);

        assertEq(metaVault.targetAllocations(0), 6000);
    }

    function testCannotUpdateAllocationBeyondMax() public {
        metaVault.addVault(vaultA, 5000);
        metaVault.addVault(vaultB, 3000);

        // Trying to set vault A to 8000 would exceed total (8000 + 3000 > 10000)
        vm.expectRevert(MetaVaultSolution.InvalidAllocation.selector);
        metaVault.updateAllocation(0, 8000);
    }

    /*//////////////////////////////////////////////////////////////
                    RECURSIVE CALCULATION TESTS
    //////////////////////////////////////////////////////////////*/

    function testTotalAssetsWithSingleVault() public {
        metaVault.addVault(vaultA, 10000);

        // Deposit 1000 tokens
        vm.prank(alice);
        metaVault.deposit(1000e18, alice);

        // Should have 1000 assets in vault A
        assertEq(metaVault.totalAssets(), 1000e18);
        assertEq(metaVault.getVaultAssets(0), 1000e18);
    }

    function testTotalAssetsWithMultipleVaults() public {
        metaVault.addVault(vaultA, 6000); // 60%
        metaVault.addVault(vaultB, 4000); // 40%

        vm.prank(alice);
        metaVault.deposit(1000e18, alice);

        // Should be distributed proportionally
        uint256 totalAssets = metaVault.totalAssets();
        assertApproxEqAbs(totalAssets, 1000e18, 1e18); // Allow 1 token rounding

        uint256 vaultAAssets = metaVault.getVaultAssets(0);
        uint256 vaultBAssets = metaVault.getVaultAssets(1);

        assertApproxEqAbs(vaultAAssets, 600e18, 1e18); // ~60%
        assertApproxEqAbs(vaultBAssets, 400e18, 1e18); // ~40%
    }

    function testRecursiveYieldAccumulation() public {
        metaVault.addVault(vaultA, 10000);

        // Alice deposits 1000 tokens
        vm.prank(alice);
        metaVault.deposit(1000e18, alice);

        uint256 sharesBefore = metaVault.balanceOf(alice);
        uint256 assetsBefore = metaVault.convertToAssets(sharesBefore);

        // Accrue yield in vault A (1% = 10 tokens)
        vaultA.accrueYield();

        // Meta-vault's totalAssets should increase due to recursive calculation
        uint256 assetsAfter = metaVault.totalAssets();
        assertGt(assetsAfter, assetsBefore);

        // Alice's shares should now be worth more
        uint256 aliceAssetsAfter = metaVault.convertToAssets(sharesBefore);
        assertGt(aliceAssetsAfter, assetsBefore);
    }

    function testCompoundingYield() public {
        metaVault.addVault(vaultA, 10000);

        vm.prank(alice);
        metaVault.deposit(1000e18, alice);

        uint256 initialAssets = metaVault.totalAssets();

        // Accrue yield multiple times to test compounding
        vaultA.accrueYield(); // +1%
        uint256 afterFirst = metaVault.totalAssets();

        vaultA.accrueYield(); // +1% on increased amount
        uint256 afterSecond = metaVault.totalAssets();

        // Second yield should be larger due to compounding
        uint256 firstYield = afterFirst - initialAssets;
        uint256 secondYield = afterSecond - afterFirst;

        assertGt(secondYield, firstYield);
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAW TESTS
    //////////////////////////////////////////////////////////////*/

    function testDepositToSingleVault() public {
        metaVault.addVault(vaultA, 10000);

        uint256 depositAmount = 1000e18;

        vm.prank(alice);
        uint256 shares = metaVault.deposit(depositAmount, alice);

        assertGt(shares, 0);
        assertEq(metaVault.balanceOf(alice), shares);
        assertEq(metaVault.totalAssets(), depositAmount);
    }

    function testDepositProportionalDistribution() public {
        metaVault.addVault(vaultA, 7000); // 70%
        metaVault.addVault(vaultB, 3000); // 30%

        vm.prank(alice);
        metaVault.deposit(1000e18, alice);

        uint256 vaultAAssets = metaVault.getVaultAssets(0);
        uint256 vaultBAssets = metaVault.getVaultAssets(1);

        // Check proportional distribution (allow small rounding errors)
        assertApproxEqAbs(vaultAAssets, 700e18, 1e18);
        assertApproxEqAbs(vaultBAssets, 300e18, 1e18);
    }

    function testWithdrawFromSingleVault() public {
        metaVault.addVault(vaultA, 10000);

        // Deposit
        vm.prank(alice);
        metaVault.deposit(1000e18, alice);

        uint256 balanceBefore = asset.balanceOf(alice);

        // Withdraw half
        vm.prank(alice);
        metaVault.withdraw(500e18, alice, alice);

        uint256 balanceAfter = asset.balanceOf(alice);

        assertEq(balanceAfter - balanceBefore, 500e18);
        assertApproxEqAbs(metaVault.totalAssets(), 500e18, 1e18);
    }

    function testWithdrawFromMultipleVaults() public {
        metaVault.addVault(vaultA, 5000);
        metaVault.addVault(vaultB, 5000);

        vm.prank(alice);
        metaVault.deposit(1000e18, alice);

        uint256 balanceBefore = asset.balanceOf(alice);

        // Withdraw most of it
        vm.prank(alice);
        metaVault.withdraw(900e18, alice, alice);

        uint256 balanceAfter = asset.balanceOf(alice);

        assertApproxEqAbs(balanceAfter - balanceBefore, 900e18, 1e18);
    }

    function testRedeemShares() public {
        metaVault.addVault(vaultA, 10000);

        vm.prank(alice);
        uint256 shares = metaVault.deposit(1000e18, alice);

        uint256 balanceBefore = asset.balanceOf(alice);

        // Redeem all shares
        vm.prank(alice);
        metaVault.redeem(shares, alice, alice);

        uint256 balanceAfter = asset.balanceOf(alice);

        assertApproxEqAbs(balanceAfter - balanceBefore, 1000e18, 1e18);
        assertEq(metaVault.balanceOf(alice), 0);
    }

    function testMultipleUsersDepositWithdraw() public {
        metaVault.addVault(vaultA, 10000);

        // Alice deposits
        vm.prank(alice);
        metaVault.deposit(1000e18, alice);

        // Bob deposits
        vm.prank(bob);
        metaVault.deposit(500e18, bob);

        assertApproxEqAbs(metaVault.totalAssets(), 1500e18, 1e18);

        // Accrue some yield
        vaultA.accrueYield();

        // Alice withdraws
        vm.prank(alice);
        uint256 aliceAssets = metaVault.redeem(metaVault.balanceOf(alice), alice, alice);

        // Bob should still have his share (proportional to deposit ratio)
        uint256 bobAssets = metaVault.convertToAssets(metaVault.balanceOf(bob));

        // Alice deposited 2x Bob's amount, should receive ~2x after yield
        assertApproxEqRel(aliceAssets, bobAssets * 2, 0.01e18); // 1% tolerance
    }

    /*//////////////////////////////////////////////////////////////
                        REBALANCING TESTS
    //////////////////////////////////////////////////////////////*/

    function testRebalanceToTargetAllocation() public {
        metaVault.addVault(vaultA, 6000); // 60%
        metaVault.addVault(vaultB, 4000); // 40%

        // Initial deposit
        vm.prank(alice);
        metaVault.deposit(1000e18, alice);

        // Manually shift allocation by depositing more to vault B
        uint256 vaultAShares = metaVault.getVaultShares(0);
        vm.prank(address(metaVault));
        vaultA.redeem(vaultAShares / 2, address(metaVault), address(metaVault));

        uint256 idle = asset.balanceOf(address(metaVault));
        vm.prank(address(metaVault));
        asset.approve(address(vaultB), idle);
        vm.prank(address(metaVault));
        vaultB.deposit(idle, address(metaVault));

        // Now allocation is skewed
        uint256[] memory currentBefore = metaVault.getCurrentAllocations();

        // Fast forward time to allow rebalance
        vm.warp(block.timestamp + 2 hours);

        // Rebalance
        metaVault.rebalance();

        // Check allocation is now close to target
        uint256[] memory currentAfter = metaVault.getCurrentAllocations();

        assertApproxEqAbs(currentAfter[0], 6000, 100); // ~60%
        assertApproxEqAbs(currentAfter[1], 4000, 100); // ~40%
    }

    function testCannotRebalanceTooSoon() public {
        metaVault.addVault(vaultA, 5000);
        metaVault.addVault(vaultB, 5000);

        vm.prank(alice);
        metaVault.deposit(1000e18, alice);

        // First rebalance
        vm.warp(block.timestamp + 2 hours);
        metaVault.rebalance();

        // Try to rebalance immediately
        vm.expectRevert(MetaVaultSolution.RebalanceTooSoon.selector);
        metaVault.rebalance();
    }

    function testAutoRebalanceToHighestYield() public {
        metaVault.addVault(vaultA, 5000); // 1% yield
        metaVault.addVault(vaultB, 5000); // 2% yield (highest)

        // Enable auto-rebalance
        metaVault.setAutoRebalance(true);

        // Deposit should go to vault B (highest yield)
        vm.prank(alice);
        metaVault.deposit(1000e18, alice);

        uint256 vaultAAssets = metaVault.getVaultAssets(0);
        uint256 vaultBAssets = metaVault.getVaultAssets(1);

        // Most/all should be in vault B
        assertEq(vaultAAssets, 0);
        assertApproxEqAbs(vaultBAssets, 1000e18, 1e18);
    }

    function testRebalancingShiftsToHigherYield() public {
        metaVault.addVault(vaultA, 5000);
        metaVault.addVault(vaultB, 5000);

        vm.prank(alice);
        metaVault.deposit(1000e18, alice);

        // Initially equal distribution
        assertApproxEqAbs(metaVault.getVaultAssets(0), 500e18, 1e18);
        assertApproxEqAbs(metaVault.getVaultAssets(1), 500e18, 1e18);

        // Change target allocation to favor vault B
        metaVault.updateAllocation(0, 3000); // 30%
        metaVault.updateAllocation(1, 7000); // 70%

        vm.warp(block.timestamp + 2 hours);
        metaVault.rebalance();

        // Should now be 30/70 split
        uint256 vaultAAssets = metaVault.getVaultAssets(0);
        uint256 vaultBAssets = metaVault.getVaultAssets(1);

        assertApproxEqAbs(vaultAAssets, 300e18, 10e18);
        assertApproxEqAbs(vaultBAssets, 700e18, 10e18);
    }

    function testNeedsRebalancing() public {
        metaVault.addVault(vaultA, 5000);
        metaVault.addVault(vaultB, 5000);

        vm.prank(alice);
        metaVault.deposit(1000e18, alice);

        // Should not need rebalancing initially
        assertFalse(metaVault.needsRebalancing());

        // Change target allocation significantly
        metaVault.updateAllocation(0, 8000);
        metaVault.updateAllocation(1, 2000);

        // Should now need rebalancing (current 50/50 vs target 80/20)
        assertTrue(metaVault.needsRebalancing());
    }

    /*//////////////////////////////////////////////////////////////
                        YIELD COMPARISON TESTS
    //////////////////////////////////////////////////////////////*/

    function testYieldFromSingleVault() public {
        metaVault.addVault(vaultA, 10000);

        vm.prank(alice);
        uint256 shares = metaVault.deposit(1000e18, alice);

        uint256 assetsBefore = metaVault.convertToAssets(shares);

        // Accrue yield 5 times (simulating 5 periods)
        for (uint256 i = 0; i < 5; i++) {
            vaultA.accrueYield();
        }

        uint256 assetsAfter = metaVault.convertToAssets(shares);

        // Should have gained yield
        assertGt(assetsAfter, assetsBefore);

        uint256 yield = assetsAfter - assetsBefore;
        console.log("Yield earned:", yield);
    }

    function testYieldFromMultipleVaults() public {
        metaVault.addVault(vaultA, 5000); // 1% yield
        metaVault.addVault(vaultB, 5000); // 2% yield

        vm.prank(alice);
        uint256 shares = metaVault.deposit(1000e18, alice);

        uint256 assetsBefore = metaVault.convertToAssets(shares);

        // Accrue yield in both vaults
        vaultA.accrueYield();
        vaultB.accrueYield();

        uint256 assetsAfter = metaVault.convertToAssets(shares);

        // Combined yield should be average of both vaults (1.5%)
        uint256 yield = assetsAfter - assetsBefore;

        // Expected: 500 * 1% + 500 * 2% = 5 + 10 = 15
        assertApproxEqAbs(yield, 15e18, 1e18);
    }

    function testHigherYieldVaultBenefitsUsers() public {
        // Setup: Two vaults with different yields
        metaVault.addVault(vaultA, 5000); // 1% yield
        metaVault.addVault(vaultB, 5000); // 2% yield

        vm.prank(alice);
        metaVault.deposit(1000e18, alice);

        // Change to favor higher-yield vault
        metaVault.updateAllocation(0, 2000); // 20% to low-yield
        metaVault.updateAllocation(1, 8000); // 80% to high-yield

        vm.warp(block.timestamp + 2 hours);
        metaVault.rebalance();

        uint256 sharesBefore = metaVault.balanceOf(alice);
        uint256 assetsBefore = metaVault.convertToAssets(sharesBefore);

        // Accrue yield
        vaultA.accrueYield();
        vaultB.accrueYield();

        uint256 assetsAfter = metaVault.convertToAssets(sharesBefore);
        uint256 yield = assetsAfter - assetsBefore;

        // Yield should be closer to 2% (vault B) than 1% (vault A)
        // Expected: 200 * 1% + 800 * 2% = 2 + 16 = 18
        assertApproxEqAbs(yield, 18e18, 2e18);
    }

    /*//////////////////////////////////////////////////////////////
                        EDGE CASE TESTS
    //////////////////////////////////////////////////////////////*/

    function testDepositWithNoVaults() public {
        // Meta-vault with no underlying vaults should still accept deposits
        vm.prank(alice);
        metaVault.deposit(1000e18, alice);

        // Assets should be held idle
        assertEq(asset.balanceOf(address(metaVault)), 1000e18);
        assertEq(metaVault.totalAssets(), 1000e18);
    }

    function testWithdrawWithIdleAssets() public {
        metaVault.addVault(vaultA, 10000);

        vm.prank(alice);
        metaVault.deposit(1000e18, alice);

        // Withdraw some assets from vault A to create idle balance
        metaVault.emergencyWithdrawAll();

        // Alice should still be able to withdraw
        vm.prank(alice);
        metaVault.withdraw(500e18, alice, alice);

        assertApproxEqAbs(asset.balanceOf(alice), INITIAL_BALANCE - 500e18, 1e18);
    }

    function testEmergencyWithdrawAll() public {
        metaVault.addVault(vaultA, 5000);
        metaVault.addVault(vaultB, 5000);

        vm.prank(alice);
        metaVault.deposit(1000e18, alice);

        // Emergency withdraw
        metaVault.emergencyWithdrawAll();

        // All assets should now be idle
        uint256 idle = asset.balanceOf(address(metaVault));
        assertApproxEqAbs(idle, 1000e18, 1e18);

        // Vaults should have no shares from meta-vault
        assertEq(metaVault.getVaultShares(0), 0);
        assertEq(metaVault.getVaultShares(1), 0);
    }

    function testZeroDeposit() public {
        metaVault.addVault(vaultA, 10000);

        vm.prank(alice);
        vm.expectRevert();
        metaVault.deposit(0, alice);
    }

    function testMaxWithdraw() public {
        metaVault.addVault(vaultA, 10000);

        vm.prank(alice);
        metaVault.deposit(1000e18, alice);

        uint256 maxWithdraw = metaVault.maxWithdraw(alice);

        assertApproxEqAbs(maxWithdraw, 1000e18, 1e18);
    }

    function testMaxRedeem() public {
        metaVault.addVault(vaultA, 10000);

        vm.prank(alice);
        uint256 shares = metaVault.deposit(1000e18, alice);

        uint256 maxRedeem = metaVault.maxRedeem(alice);

        assertEq(maxRedeem, shares);
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTION TESTS
    //////////////////////////////////////////////////////////////*/

    function testGetCurrentAllocations() public {
        metaVault.addVault(vaultA, 6000);
        metaVault.addVault(vaultB, 4000);

        vm.prank(alice);
        metaVault.deposit(1000e18, alice);

        uint256[] memory allocations = metaVault.getCurrentAllocations();

        assertEq(allocations.length, 2);
        assertApproxEqAbs(allocations[0], 6000, 100);
        assertApproxEqAbs(allocations[1], 4000, 100);
    }

    function testGetTargetAllocations() public {
        metaVault.addVault(vaultA, 7000);
        metaVault.addVault(vaultB, 3000);

        uint256[] memory allocations = metaVault.getTargetAllocations();

        assertEq(allocations.length, 2);
        assertEq(allocations[0], 7000);
        assertEq(allocations[1], 3000);
    }

    function testGetVaults() public {
        metaVault.addVault(vaultA, 5000);
        metaVault.addVault(vaultB, 5000);

        IERC4626[] memory vaults = metaVault.getVaults();

        assertEq(vaults.length, 2);
        assertEq(address(vaults[0]), address(vaultA));
        assertEq(address(vaults[1]), address(vaultB));
    }

    /*//////////////////////////////////////////////////////////////
                        ADMIN FUNCTION TESTS
    //////////////////////////////////////////////////////////////*/

    function testSetAutoRebalance() public {
        assertFalse(metaVault.autoRebalance());

        metaVault.setAutoRebalance(true);
        assertTrue(metaVault.autoRebalance());

        metaVault.setAutoRebalance(false);
        assertFalse(metaVault.autoRebalance());
    }

    function testSetRebalanceThreshold() public {
        metaVault.setRebalanceThreshold(1000); // 10%
        assertEq(metaVault.rebalanceThreshold(), 1000);
    }

    function testOnlyOwnerCanAddVault() public {
        vm.prank(alice);
        vm.expectRevert();
        metaVault.addVault(vaultA, 5000);
    }

    function testOnlyOwnerCanRemoveVault() public {
        metaVault.addVault(vaultA, 5000);

        vm.prank(alice);
        vm.expectRevert();
        metaVault.removeVault(0);
    }

    function testOnlyOwnerCanUpdateAllocation() public {
        metaVault.addVault(vaultA, 5000);

        vm.prank(alice);
        vm.expectRevert();
        metaVault.updateAllocation(0, 6000);
    }

    /*//////////////////////////////////////////////////////////////
                    COMPLEX SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function testComplexMultiVaultScenario() public {
        // Setup: 3 vaults with different yields and allocations
        metaVault.addVault(vaultA, 5000); // 50%, 1% yield
        metaVault.addVault(vaultB, 3000); // 30%, 2% yield
        metaVault.addVault(vaultC, 2000); // 20%, 1.5% yield

        // Alice and Bob deposit
        vm.prank(alice);
        metaVault.deposit(10000e18, alice);

        vm.prank(bob);
        metaVault.deposit(5000e18, bob);

        // Check initial allocations
        assertApproxEqAbs(metaVault.getVaultAssets(0), 7500e18, 10e18); // 50% of 15000
        assertApproxEqAbs(metaVault.getVaultAssets(1), 4500e18, 10e18); // 30% of 15000
        assertApproxEqAbs(metaVault.getVaultAssets(2), 3000e18, 10e18); // 20% of 15000

        // Accrue yield in all vaults
        vaultA.accrueYield();
        vaultB.accrueYield();
        vaultC.accrueYield();

        uint256 totalAfterYield = metaVault.totalAssets();
        assertGt(totalAfterYield, 15000e18);

        // Alice withdraws half
        uint256 aliceShares = metaVault.balanceOf(alice);
        vm.prank(alice);
        metaVault.redeem(aliceShares / 2, alice, alice);

        // Bob should still have his proportional share
        uint256 bobAssets = metaVault.convertToAssets(metaVault.balanceOf(bob));
        assertGt(bobAssets, 5000e18); // Should have gained yield
    }

    function testYieldComparisonAcrossVaults() public {
        // Compare yield from meta-vault vs direct vault investment
        metaVault.addVault(vaultA, 5000);
        metaVault.addVault(vaultB, 5000);

        // Alice invests in meta-vault
        vm.prank(alice);
        uint256 aliceShares = metaVault.deposit(1000e18, alice);

        // Bob invests directly in vault B (higher yield)
        vm.prank(bob);
        asset.approve(address(vaultB), type(uint256).max);
        vm.prank(bob);
        uint256 bobShares = vaultB.deposit(1000e18, bob);

        // Accrue yield
        vaultA.accrueYield();
        vaultB.accrueYield();

        uint256 aliceAssets = metaVault.convertToAssets(aliceShares);
        uint256 bobAssets = vaultB.convertToAssets(bobShares);

        // Bob should have slightly more (invested 100% in higher-yield vault)
        // Alice has 50% in lower-yield vault A
        assertGt(bobAssets, aliceAssets);

        console.log("Alice (meta-vault):", aliceAssets);
        console.log("Bob (direct vault B):", bobAssets);
    }
}
