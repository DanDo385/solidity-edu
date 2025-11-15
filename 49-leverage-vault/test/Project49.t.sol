// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/Project49Solution.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Leverage Looping Vault Tests
 * @notice Comprehensive test suite for leverage vault functionality
 */

// Mock ERC20 token for testing
contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Token", "MOCK") {
        _mint(msg.sender, 1000000 ether);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

// Mock lending pool (simplified Aave)
contract MockLendingPool {
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public borrows;

    uint256 public liquidationThreshold = 8250; // 82.5%
    uint256 public ltv = 7500; // 75%
    uint256 public constant BASIS_POINTS = 10000;

    IERC20 public asset;

    // Interest rate parameters (simplified)
    uint256 public supplyRate = 300; // 3% APY
    uint256 public borrowRate = 200; // 2% APY
    uint256 public lastUpdateTimestamp;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 amount);

    constructor(address _asset) {
        asset = IERC20(_asset);
        lastUpdateTimestamp = block.timestamp;
    }

    function deposit(address, uint256 amount, address onBehalfOf, uint16) external {
        asset.transferFrom(msg.sender, address(this), amount);
        deposits[onBehalfOf] += amount;
        emit Deposited(onBehalfOf, amount);
    }

    function withdraw(address, uint256 amount, address to) external returns (uint256) {
        require(deposits[msg.sender] >= amount, "Insufficient deposit");

        // Check health factor after withdrawal
        uint256 newDeposit = deposits[msg.sender] - amount;
        uint256 currentBorrow = borrows[msg.sender];

        if (currentBorrow > 0) {
            uint256 hf = calculateHealthFactor(newDeposit, currentBorrow);
            require(hf >= 1e18, "Health factor too low");
        }

        deposits[msg.sender] -= amount;
        asset.transfer(to, amount);
        emit Withdrawn(msg.sender, amount);
        return amount;
    }

    function borrow(address, uint256 amount, uint256, uint16, address onBehalfOf) external {
        uint256 maxBorrow = (deposits[onBehalfOf] * ltv) / BASIS_POINTS;
        require(borrows[onBehalfOf] + amount <= maxBorrow, "Exceeds borrow capacity");

        borrows[onBehalfOf] += amount;
        asset.transfer(msg.sender, amount);
        emit Borrowed(onBehalfOf, amount);
    }

    function repay(address, uint256 amount, uint256, address onBehalfOf) external returns (uint256) {
        asset.transferFrom(msg.sender, address(this), amount);

        uint256 repayAmount = amount > borrows[onBehalfOf] ? borrows[onBehalfOf] : amount;
        borrows[onBehalfOf] -= repayAmount;

        emit Repaid(onBehalfOf, repayAmount);
        return repayAmount;
    }

    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 currentLtv,
            uint256 healthFactor
        )
    {
        totalCollateralETH = deposits[user];
        totalDebtETH = borrows[user];
        uint256 maxBorrow = (totalCollateralETH * ltv) / BASIS_POINTS;
        availableBorrowsETH = maxBorrow > totalDebtETH ? maxBorrow - totalDebtETH : 0;
        currentLiquidationThreshold = liquidationThreshold;
        currentLtv = ltv;
        healthFactor = calculateHealthFactor(totalCollateralETH, totalDebtETH);
    }

    function calculateHealthFactor(uint256 collateral, uint256 debt) public view returns (uint256) {
        if (debt == 0) return type(uint256).max;
        return (collateral * liquidationThreshold * 1e18) / (BASIS_POINTS * debt);
    }

    // Admin functions for testing
    function setLiquidationThreshold(uint256 _threshold) external {
        liquidationThreshold = _threshold;
    }

    function setLTV(uint256 _ltv) external {
        ltv = _ltv;
    }

    // Simulate interest accrual
    function accrueInterest(uint256 timeElapsed) external {
        for (uint256 i = 0; i < 10; i++) {
            if (borrows[address(uint160(i))] > 0) {
                // Simple interest for testing
                uint256 interest = (borrows[address(uint160(i))] * borrowRate * timeElapsed) / (365 days * BASIS_POINTS);
                borrows[address(uint160(i))] += interest;
            }
            if (deposits[address(uint160(i))] > 0) {
                uint256 interest =
                    (deposits[address(uint160(i))] * supplyRate * timeElapsed) / (365 days * BASIS_POINTS);
                deposits[address(uint160(i))] += interest;
            }
        }
        lastUpdateTimestamp = block.timestamp;
    }

    // Simulate price crash by reducing collateral value
    function simulatePriceCrash(address user, uint256 percentDrop) external {
        deposits[user] = (deposits[user] * (BASIS_POINTS - percentDrop)) / BASIS_POINTS;
    }
}

// Mock price oracle
contract MockPriceOracle {
    mapping(address => uint256) public prices;

    function setAssetPrice(address asset, uint256 price) external {
        prices[asset] = price;
    }

    function getAssetPrice(address asset) external view returns (uint256) {
        return prices[asset];
    }
}

contract Project49Test is Test {
    LeverageLoopingVaultSolution public vault;
    MockERC20 public token;
    MockLendingPool public lendingPool;
    MockPriceOracle public oracle;

    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);

    uint256 public constant INITIAL_BALANCE = 1000 ether;
    uint256 public constant TARGET_LEVERAGE = 40000; // 4x
    uint256 public constant TARGET_LTV = 7500; // 75%
    uint256 public constant MIN_HEALTH_FACTOR = 1.5e18; // 1.5

    event Deposited(address indexed user, uint256 amount, uint256 newBalance);
    event Withdrawn(address indexed user, uint256 amount, uint256 newBalance);
    event Leveraged(uint256 iterations, uint256 finalLeverage, uint256 healthFactor);
    event Deleveraged(uint256 iterations, uint256 finalLeverage, uint256 healthFactor);
    event Rebalanced(uint256 oldLTV, uint256 newLTV, uint256 healthFactor);
    event EmergencyDeleveraged(uint256 healthFactor, uint256 newLeverage);

    function setUp() public {
        // Deploy contracts
        vm.startPrank(owner);

        token = new MockERC20();
        lendingPool = new MockLendingPool(address(token));
        oracle = new MockPriceOracle();

        vault = new LeverageLoopingVaultSolution(
            address(token),
            address(lendingPool),
            address(oracle),
            TARGET_LEVERAGE,
            TARGET_LTV,
            MIN_HEALTH_FACTOR
        );

        // Setup oracle
        oracle.setAssetPrice(address(token), 2000e8); // $2000

        // Fund lending pool
        token.mint(address(lendingPool), 10000 ether);

        // Fund users
        token.mint(user1, INITIAL_BALANCE);
        token.mint(user2, INITIAL_BALANCE);

        vm.stopPrank();
    }

    // ============================================
    // Basic Functionality Tests
    // ============================================

    function test_Deployment() public view {
        assertEq(address(vault.asset()), address(token));
        assertEq(address(vault.lendingPool()), address(lendingPool));
        assertEq(vault.targetLeverage(), TARGET_LEVERAGE);
        assertEq(vault.targetLTV(), TARGET_LTV);
        assertEq(vault.minHealthFactor(), MIN_HEALTH_FACTOR);
    }

    function test_Deposit() public {
        uint256 depositAmount = 100 ether;

        vm.startPrank(user1);
        token.approve(address(vault), depositAmount);

        vm.expectEmit(true, true, true, true);
        emit Deposited(user1, depositAmount, depositAmount);

        vault.deposit(depositAmount);
        vm.stopPrank();

        assertEq(vault.userDeposits(user1), depositAmount);
        assertEq(vault.totalDeposits(), depositAmount);
    }

    function test_RevertDeposit_ZeroAmount() public {
        vm.prank(user1);
        vm.expectRevert(LeverageLoopingVaultSolution.ZeroAmount.selector);
        vault.deposit(0);
    }

    function test_RevertDeposit_WhenPaused() public {
        vm.prank(owner);
        vault.pause();

        vm.startPrank(user1);
        token.approve(address(vault), 100 ether);

        vm.expectRevert(LeverageLoopingVaultSolution.VaultPaused.selector);
        vault.deposit(100 ether);
        vm.stopPrank();
    }

    function test_Withdraw() public {
        uint256 depositAmount = 100 ether;

        // First deposit
        vm.startPrank(user1);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);

        // Then withdraw
        uint256 withdrawAmount = 50 ether;
        vault.withdraw(withdrawAmount);
        vm.stopPrank();

        assertEq(vault.userDeposits(user1), depositAmount - withdrawAmount);
    }

    function test_RevertWithdraw_InsufficientBalance() public {
        vm.prank(user1);
        vm.expectRevert(LeverageLoopingVaultSolution.InsufficientBalance.selector);
        vault.withdraw(100 ether);
    }

    // ============================================
    // Leverage Loop Tests
    // ============================================

    function test_LeverageLoop_ExecutesCorrectly() public {
        uint256 depositAmount = 100 ether;

        vm.startPrank(user1);
        token.approve(address(vault), depositAmount);

        vm.expectEmit(false, false, false, false);
        emit Leveraged(0, 0, 0); // Just check event is emitted

        vault.deposit(depositAmount);
        vm.stopPrank();

        // Check leverage is close to target (4x)
        uint256 currentLeverage = vault.getCurrentLeverage();
        assertGt(currentLeverage, 35000); // At least 3.5x
        assertLt(currentLeverage, 45000); // At most 4.5x

        // Check health factor is safe
        uint256 hf = vault.getHealthFactor();
        assertGt(hf, MIN_HEALTH_FACTOR);
    }

    function test_LeverageLoop_AchievesTargetLeverage() public {
        uint256 depositAmount = 100 ether;

        vm.startPrank(user1);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);
        vm.stopPrank();

        uint256 currentLeverage = vault.getCurrentLeverage();

        // Should be within 10% of target
        uint256 diff = currentLeverage > TARGET_LEVERAGE
            ? currentLeverage - TARGET_LEVERAGE
            : TARGET_LEVERAGE - currentLeverage;

        assertLt(diff, TARGET_LEVERAGE / 10);
    }

    function test_LeverageLoop_MaintainsSafeHealthFactor() public {
        uint256 depositAmount = 100 ether;

        vm.startPrank(user1);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);
        vm.stopPrank();

        uint256 hf = vault.getHealthFactor();
        assertGe(hf, MIN_HEALTH_FACTOR);
    }

    function test_LeverageLoop_CorrectLTV() public {
        uint256 depositAmount = 100 ether;

        vm.startPrank(user1);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);
        vm.stopPrank();

        uint256 currentLTV = vault.getCurrentLTV();

        // Should be close to target LTV (75%)
        assertGt(currentLTV, 7000); // At least 70%
        assertLt(currentLTV, 8000); // At most 80%
    }

    function test_LeverageLoop_MultipleIterations() public {
        // Test that multiple iterations execute
        uint256 depositAmount = 100 ether;

        vm.startPrank(user1);
        token.approve(address(vault), depositAmount);

        // Capture events to verify iterations
        vm.recordLogs();
        vault.deposit(depositAmount);
        vm.stopPrank();

        // Verify multiple deposit/borrow events occurred
        Vm.Log[] memory logs = vm.getRecordedLogs();
        uint256 borrowCount = 0;
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == keccak256("Borrowed(address,uint256)")) {
                borrowCount++;
            }
        }

        // Should have multiple borrow iterations
        assertGt(borrowCount, 2);
    }

    // ============================================
    // Deleverage Tests
    // ============================================

    function test_Deleverage_ReducesPosition() public {
        uint256 depositAmount = 100 ether;

        // First leverage
        vm.startPrank(user1);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);

        uint256 initialLeverage = vault.getCurrentLeverage();

        // Then withdraw (deleverage)
        vault.withdraw(50 ether);
        vm.stopPrank();

        uint256 finalLeverage = vault.getCurrentLeverage();

        // Leverage should decrease or stay similar (position reduced)
        assertLe(finalLeverage, initialLeverage + 1000); // Allow small increase due to rounding
    }

    function test_Deleverage_MaintainsHealthFactor() public {
        uint256 depositAmount = 100 ether;

        vm.startPrank(user1);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);

        vault.withdraw(30 ether);
        vm.stopPrank();

        uint256 hf = vault.getHealthFactor();
        assertGe(hf, MIN_HEALTH_FACTOR);
    }

    function test_Deleverage_ProportionalReduction() public {
        uint256 depositAmount = 100 ether;

        vm.startPrank(user1);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);

        (uint256 collateralBefore, uint256 debtBefore,,,,) = lendingPool.getUserAccountData(address(vault));

        // Withdraw 50% of position
        vault.withdraw(50 ether);
        vm.stopPrank();

        (uint256 collateralAfter, uint256 debtAfter,,,,) = lendingPool.getUserAccountData(address(vault));

        // Both collateral and debt should reduce proportionally
        // Allow 20% margin for rounding and iteration effects
        uint256 collateralRatio = (collateralAfter * 100) / collateralBefore;
        uint256 debtRatio = (debtAfter * 100) / debtBefore;

        assertGt(collateralRatio, 30); // At least 30% remaining
        assertLt(collateralRatio, 70); // At most 70% remaining
        assertGt(debtRatio, 30);
        assertLt(debtRatio, 70);
    }

    // ============================================
    // Rebalancing Tests
    // ============================================

    function test_Rebalance_WhenOverLeveraged() public {
        uint256 depositAmount = 100 ether;

        vm.startPrank(user1);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);
        vm.stopPrank();

        // Simulate market change that increases LTV (price drop)
        // Manually adjust lending pool state
        vm.prank(address(lendingPool));
        lendingPool.simulatePriceCrash(address(vault), 500); // 5% drop

        uint256 ltvBefore = vault.getCurrentLTV();

        // Rebalance should deleverage
        vault.rebalance();

        uint256 ltvAfter = vault.getCurrentLTV();

        // LTV should be closer to target
        assertLt(ltvAfter, ltvBefore);
    }

    function test_RevertRebalance_WhenNotNeeded() public {
        uint256 depositAmount = 100 ether;

        vm.startPrank(user1);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);
        vm.stopPrank();

        // Immediately rebalancing should fail (no drift)
        vm.expectRevert(LeverageLoopingVaultSolution.RebalanceNotNeeded.selector);
        vault.rebalance();
    }

    function test_Rebalance_EmitsEvent() public {
        uint256 depositAmount = 100 ether;

        vm.startPrank(user1);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);
        vm.stopPrank();

        // Create drift
        vm.prank(address(lendingPool));
        lendingPool.simulatePriceCrash(address(vault), 1000); // 10% drop

        vm.expectEmit(false, false, false, false);
        emit Rebalanced(0, 0, 0);

        vault.rebalance();
    }

    // ============================================
    // Emergency Deleverage Tests
    // ============================================

    function test_EmergencyDeleverage_WhenHealthFactorLow() public {
        uint256 depositAmount = 100 ether;

        vm.startPrank(user1);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);
        vm.stopPrank();

        // Simulate severe price crash to lower health factor
        vm.prank(address(lendingPool));
        lendingPool.simulatePriceCrash(address(vault), 2000); // 20% drop

        uint256 hfBefore = vault.getHealthFactor();
        assertLt(hfBefore, MIN_HEALTH_FACTOR);

        // Emergency deleverage
        vm.expectEmit(false, false, false, false);
        emit EmergencyDeleveraged(0, 0);

        vault.emergencyDeleverage();

        uint256 hfAfter = vault.getHealthFactor();

        // Health factor should improve
        assertGt(hfAfter, hfBefore);
    }

    function test_EmergencyDeleverage_ReducesLeverage() public {
        uint256 depositAmount = 100 ether;

        vm.startPrank(user1);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);
        vm.stopPrank();

        uint256 leverageBefore = vault.getCurrentLeverage();

        // Create dangerous situation
        vm.prank(address(lendingPool));
        lendingPool.simulatePriceCrash(address(vault), 1500); // 15% drop

        vault.emergencyDeleverage();

        uint256 leverageAfter = vault.getCurrentLeverage();

        // Leverage should decrease
        assertLt(leverageAfter, leverageBefore);
    }

    // ============================================
    // Interest Accrual Tests
    // ============================================

    function test_InterestAccrual_IncreasesDebt() public {
        uint256 depositAmount = 100 ether;

        vm.startPrank(user1);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);
        vm.stopPrank();

        (, uint256 debtBefore,,,,) = lendingPool.getUserAccountData(address(vault));

        // Simulate 1 year of interest
        vm.warp(block.timestamp + 365 days);
        lendingPool.accrueInterest(365 days);

        (, uint256 debtAfter,,,,) = lendingPool.getUserAccountData(address(vault));

        // Debt should increase due to interest
        assertGt(debtAfter, debtBefore);
    }

    function test_InterestAccrual_IncreasesCollateral() public {
        uint256 depositAmount = 100 ether;

        vm.startPrank(user1);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);
        vm.stopPrank();

        (uint256 collateralBefore,,,,,) = lendingPool.getUserAccountData(address(vault));

        // Simulate 1 year of interest
        vm.warp(block.timestamp + 365 days);
        lendingPool.accrueInterest(365 days);

        (uint256 collateralAfter,,,,,) = lendingPool.getUserAccountData(address(vault));

        // Collateral should increase due to supply interest
        assertGt(collateralAfter, collateralBefore);
    }

    function test_InterestAccrual_NetPositive() public {
        uint256 depositAmount = 100 ether;

        vm.startPrank(user1);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);
        vm.stopPrank();

        uint256 positionBefore = vault.getPositionValue();

        // Simulate 1 year (supply rate > borrow rate = profit)
        vm.warp(block.timestamp + 365 days);
        lendingPool.accrueInterest(365 days);

        uint256 positionAfter = vault.getPositionValue();

        // Position should grow (supply yield > borrow cost)
        assertGt(positionAfter, positionBefore);
    }

    // ============================================
    // Market Crash Simulation Tests
    // ============================================

    function test_MarketCrash_10Percent() public {
        uint256 depositAmount = 100 ether;

        vm.startPrank(user1);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);
        vm.stopPrank();

        uint256 hfBefore = vault.getHealthFactor();

        // 10% crash
        vm.prank(address(lendingPool));
        lendingPool.simulatePriceCrash(address(vault), 1000);

        uint256 hfAfter = vault.getHealthFactor();

        // Health factor should drop but still be > 1.0
        assertLt(hfAfter, hfBefore);
        assertGt(hfAfter, 1e18);
    }

    function test_MarketCrash_20Percent() public {
        uint256 depositAmount = 100 ether;

        vm.startPrank(user1);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);
        vm.stopPrank();

        // 20% crash
        vm.prank(address(lendingPool));
        lendingPool.simulatePriceCrash(address(vault), 2000);

        uint256 hf = vault.getHealthFactor();

        // Should trigger emergency deleverage
        if (hf < MIN_HEALTH_FACTOR) {
            vault.emergencyDeleverage();
            uint256 newHF = vault.getHealthFactor();
            assertGt(newHF, hf);
        }
    }

    function test_MarketCrash_30Percent_PreventLiquidation() public {
        uint256 depositAmount = 100 ether;

        vm.startPrank(user1);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);
        vm.stopPrank();

        // Severe 30% crash
        vm.prank(address(lendingPool));
        lendingPool.simulatePriceCrash(address(vault), 3000);

        uint256 hfBefore = vault.getHealthFactor();

        // Emergency deleverage to prevent liquidation
        if (hfBefore < MIN_HEALTH_FACTOR) {
            vault.emergencyDeleverage();
        }

        uint256 hfAfter = vault.getHealthFactor();

        // Should avoid liquidation (HF > 1.0)
        assertGt(hfAfter, 1e18);
    }

    // ============================================
    // View Function Tests
    // ============================================

    function test_GetCurrentLeverage() public {
        uint256 depositAmount = 100 ether;

        vm.startPrank(user1);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);
        vm.stopPrank();

        uint256 leverage = vault.getCurrentLeverage();

        assertGt(leverage, 10000); // > 1x
        assertLt(leverage, 50000); // < 5x
    }

    function test_GetCurrentLTV() public {
        uint256 depositAmount = 100 ether;

        vm.startPrank(user1);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);
        vm.stopPrank();

        uint256 ltv = vault.getCurrentLTV();

        assertGt(ltv, 0);
        assertLt(ltv, 10000); // < 100%
    }

    function test_GetHealthFactor() public {
        uint256 depositAmount = 100 ether;

        vm.startPrank(user1);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);
        vm.stopPrank();

        uint256 hf = vault.getHealthFactor();

        assertGe(hf, MIN_HEALTH_FACTOR);
    }

    function test_GetUserShare() public {
        vm.startPrank(user1);
        token.approve(address(vault), 100 ether);
        vault.deposit(100 ether);
        vm.stopPrank();

        vm.startPrank(user2);
        token.approve(address(vault), 100 ether);
        vault.deposit(100 ether);
        vm.stopPrank();

        uint256 user1Share = vault.getUserShare(user1);
        uint256 user2Share = vault.getUserShare(user2);

        assertEq(user1Share, 5000); // 50%
        assertEq(user2Share, 5000); // 50%
    }

    function test_GetPositionValue() public {
        uint256 depositAmount = 100 ether;

        vm.startPrank(user1);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);
        vm.stopPrank();

        uint256 positionValue = vault.getPositionValue();

        // Position value should be positive
        assertGt(positionValue, 0);
    }

    function test_GetPositionMetrics() public {
        uint256 depositAmount = 100 ether;

        vm.startPrank(user1);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);
        vm.stopPrank();

        (uint256 collateral, uint256 debt, uint256 leverage, uint256 ltv, uint256 healthFactor) =
            vault.getPositionMetrics();

        assertGt(collateral, depositAmount); // Should be leveraged
        assertGt(debt, 0);
        assertGt(leverage, 10000); // > 1x
        assertGt(ltv, 0);
        assertGe(healthFactor, MIN_HEALTH_FACTOR);
    }

    // ============================================
    // Admin Function Tests
    // ============================================

    function test_UpdateParameters() public {
        uint256 newLeverage = 30000; // 3x
        uint256 newLTV = 6500; // 65%
        uint256 newMinHF = 1.8e18;

        vm.prank(owner);
        vault.updateParameters(newLeverage, newLTV, newMinHF);

        assertEq(vault.targetLeverage(), newLeverage);
        assertEq(vault.targetLTV(), newLTV);
        assertEq(vault.minHealthFactor(), newMinHF);
    }

    function test_RevertUpdateParameters_OnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        vault.updateParameters(30000, 6500, 1.8e18);
    }

    function test_RevertUpdateParameters_UnsafeLeverage() public {
        vm.prank(owner);
        vm.expectRevert(LeverageLoopingVaultSolution.UnsafeParameters.selector);
        vault.updateParameters(5000, 7500, 1.5e18); // 0.5x leverage (< 1x)
    }

    function test_RevertUpdateParameters_UnsafeLTV() public {
        vm.prank(owner);
        vm.expectRevert(LeverageLoopingVaultSolution.UnsafeParameters.selector);
        vault.updateParameters(40000, 10000, 1.5e18); // 100% LTV
    }

    function test_Pause() public {
        vm.prank(owner);
        vault.pause();

        assertTrue(vault.paused());
    }

    function test_Unpause() public {
        vm.startPrank(owner);
        vault.pause();
        vault.unpause();
        vm.stopPrank();

        assertFalse(vault.paused());
    }

    function test_RevertPause_OnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        vault.pause();
    }

    // ============================================
    // Multi-User Tests
    // ============================================

    function test_MultiUser_IndependentDeposits() public {
        vm.startPrank(user1);
        token.approve(address(vault), 100 ether);
        vault.deposit(100 ether);
        vm.stopPrank();

        vm.startPrank(user2);
        token.approve(address(vault), 50 ether);
        vault.deposit(50 ether);
        vm.stopPrank();

        assertEq(vault.userDeposits(user1), 100 ether);
        assertEq(vault.userDeposits(user2), 50 ether);
        assertEq(vault.totalDeposits(), 150 ether);
    }

    function test_MultiUser_ProportionalShares() public {
        vm.startPrank(user1);
        token.approve(address(vault), 100 ether);
        vault.deposit(100 ether);
        vm.stopPrank();

        vm.startPrank(user2);
        token.approve(address(vault), 100 ether);
        vault.deposit(100 ether);
        vm.stopPrank();

        uint256 share1 = vault.getUserShare(user1);
        uint256 share2 = vault.getUserShare(user2);

        assertEq(share1, share2);
        assertEq(share1 + share2, 10000); // 100%
    }

    // ============================================
    // Edge Cases
    // ============================================

    function test_EdgeCase_VerySmallDeposit() public {
        uint256 depositAmount = 0.001 ether;

        vm.startPrank(user1);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);
        vm.stopPrank();

        assertEq(vault.userDeposits(user1), depositAmount);
    }

    function test_EdgeCase_FullWithdrawal() public {
        uint256 depositAmount = 100 ether;

        vm.startPrank(user1);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);

        vault.withdraw(depositAmount);
        vm.stopPrank();

        assertEq(vault.userDeposits(user1), 0);
        assertEq(vault.totalDeposits(), 0);
    }

    function test_EdgeCase_ZeroLeverageState() public view {
        // Fresh vault should have 1x leverage (no position)
        uint256 leverage = vault.getCurrentLeverage();
        assertEq(leverage, 10000); // 1x = 10000 basis points
    }
}
