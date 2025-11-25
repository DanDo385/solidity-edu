// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/MultiAssetVaultSolution.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Mock ERC20 token
contract MockERC20 is ERC20 {
    uint8 private _decimals;

    constructor(string memory name, string memory symbol, uint8 decimals_) ERC20(name, symbol) {
        _decimals = decimals_;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}

// Mock Price Oracle (Chainlink-style)
contract MockPriceOracle {
    int256 private _price;
    uint8 private _decimals;
    uint256 private _updatedAt;

    constructor(int256 initialPrice, uint8 decimals_) {
        _price = initialPrice;
        _decimals = decimals_;
        _updatedAt = block.timestamp;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (1, _price, block.timestamp, _updatedAt, 1);
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function setPrice(int256 newPrice) external {
        _price = newPrice;
        _updatedAt = block.timestamp;
    }

    function setUpdatedAt(uint256 timestamp) external {
        _updatedAt = timestamp;
    }
}

// Mock DEX Router
contract MockDEXRouter {
    uint256 public slippagePercent = 100; // 1% slippage

    function setSlippage(uint256 _slippage) external {
        slippagePercent = _slippage;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        require(deadline >= block.timestamp, "Expired");
        require(path.length == 2, "Invalid path");

        IERC20 tokenIn = IERC20(path[0]);
        IERC20 tokenOut = IERC20(path[1]);

        // Transfer input token from sender
        tokenIn.transferFrom(msg.sender, address(this), amountIn);

        // Calculate output with slippage (simplified 1:1 - slippage)
        uint256 amountOut = (amountIn * (10000 - slippagePercent)) / 10000;
        require(amountOut >= amountOutMin, "Insufficient output");

        // Mint output tokens to recipient (in real DEX, would come from liquidity pool)
        MockERC20(address(tokenOut)).mint(to, amountOut);

        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;

        return amounts;
    }

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts) {
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;

        // Simplified: assume 1:1 exchange rate minus slippage
        amounts[1] = (amountIn * (10000 - slippagePercent)) / 10000;

        return amounts;
    }
}

contract MultiAssetVaultTest is Test {
    MultiAssetVaultSolution public vault;

    MockERC20 public usdc; // Base asset
    MockERC20 public tokenA;
    MockERC20 public tokenB;
    MockERC20 public tokenC;

    MockPriceOracle public usdcOracle;
    MockPriceOracle public oracleA;
    MockPriceOracle public oracleB;
    MockPriceOracle public oracleC;

    MockDEXRouter public dex;

    address public alice = address(0x1);
    address public bob = address(0x2);

    function setUp() public {
        // Deploy mock tokens
        usdc = new MockERC20("USD Coin", "USDC", 6); // 6 decimals like real USDC
        tokenA = new MockERC20("Token A", "TKNA", 18);
        tokenB = new MockERC20("Token B", "TKNB", 18);
        tokenC = new MockERC20("Token C", "TKNC", 8);

        // Deploy mock oracles (prices in USD with 8 decimals like Chainlink)
        usdcOracle = new MockPriceOracle(1e8, 8); // $1.00
        oracleA = new MockPriceOracle(10e8, 8); // $10.00
        oracleB = new MockPriceOracle(5e8, 8); // $5.00
        oracleC = new MockPriceOracle(20e8, 8); // $20.00

        // Deploy mock DEX
        dex = new MockDEXRouter();

        // Deploy vault
        vault = new MultiAssetVaultSolution("Multi-Asset Vault", "MAV", address(usdc), address(dex), 500); // 5% threshold

        // Mint tokens to users
        usdc.mint(alice, 100000e6); // 100k USDC
        usdc.mint(bob, 50000e6); // 50k USDC

        // Approve vault
        vm.prank(alice);
        usdc.approve(address(vault), type(uint256).max);

        vm.prank(bob);
        usdc.approve(address(vault), type(uint256).max);

        // Approve DEX for vault
        vm.startPrank(address(vault));
        usdc.approve(address(dex), type(uint256).max);
        tokenA.approve(address(dex), type(uint256).max);
        tokenB.approve(address(dex), type(uint256).max);
        tokenC.approve(address(dex), type(uint256).max);
        vm.stopPrank();
    }

    // ========== ASSET MANAGEMENT TESTS ==========

    function testAddAsset() public {
        vault.addAsset(address(tokenA), 2500, address(oracleA)); // 25%

        MultiAssetVaultSolution.Asset memory asset = vault.getAsset(0);
        assertEq(asset.token, address(tokenA));
        assertEq(asset.targetWeight, 2500);
        assertEq(asset.priceOracle, address(oracleA));
        assertTrue(asset.active);
    }

    function testAddMultipleAssets() public {
        vault.addAsset(address(tokenA), 4000, address(oracleA)); // 40%
        vault.addAsset(address(tokenB), 3000, address(oracleB)); // 30%
        vault.addAsset(address(tokenC), 3000, address(oracleC)); // 30%

        assertEq(vault.getAssetCount(), 3);
        assertEq(vault.getTotalWeight(), 10000); // 100%
    }

    function testCannotExceed100Percent() public {
        vault.addAsset(address(tokenA), 6000, address(oracleA)); // 60%

        vm.expectRevert(MultiAssetVaultSolution.WeightsMustEqual100.selector);
        vault.addAsset(address(tokenB), 5000, address(oracleB)); // Would be 110%
    }

    function testCannotAddDuplicateAsset() public {
        vault.addAsset(address(tokenA), 5000, address(oracleA));

        vm.expectRevert(MultiAssetVaultSolution.AssetAlreadyExists.selector);
        vault.addAsset(address(tokenA), 3000, address(oracleA));
    }

    function testSetTargetWeight() public {
        vault.addAsset(address(tokenA), 5000, address(oracleA));
        vault.addAsset(address(tokenB), 5000, address(oracleB));

        vault.setTargetWeight(address(tokenA), 6000);
        vault.setTargetWeight(address(tokenB), 4000);

        assertEq(vault.getAsset(0).targetWeight, 6000);
        assertEq(vault.getAsset(1).targetWeight, 4000);
    }

    function testSetWeightMustEqual100() public {
        vault.addAsset(address(tokenA), 5000, address(oracleA));
        vault.addAsset(address(tokenB), 5000, address(oracleB));

        vm.expectRevert(MultiAssetVaultSolution.WeightsMustEqual100.selector);
        vault.setTargetWeight(address(tokenA), 7000); // Total would be 120%
    }

    // ========== NAV CALCULATION TESTS ==========

    function testCalculateNAVWithNoAssets() public {
        uint256 nav = vault.calculateNAV();
        assertEq(nav, 0);
    }

    function testCalculateNAVWithOneAsset() public {
        vault.addAsset(address(tokenA), 10000, address(oracleA)); // 100%, $10 each

        // Give vault 100 tokens worth $10 each = $1000
        tokenA.mint(address(vault), 100e18);

        uint256 nav = vault.calculateNAV();
        assertEq(nav, 1000e18); // $1000 in 18 decimals
    }

    function testCalculateNAVWithMultipleAssets() public {
        vault.addAsset(address(tokenA), 3333, address(oracleA)); // 33.33%, $10 each
        vault.addAsset(address(tokenB), 3333, address(oracleB)); // 33.33%, $5 each
        vault.addAsset(address(tokenC), 3334, address(oracleC)); // 33.34%, $20 each

        // Give vault assets
        tokenA.mint(address(vault), 50e18); // 50 * $10 = $500
        tokenB.mint(address(vault), 100e18); // 100 * $5 = $500
        tokenC.mint(address(vault), 25e8); // 25 * $20 = $500

        uint256 nav = vault.calculateNAV();
        assertEq(nav, 1500e18); // Total $1500
    }

    function testGetAssetValue() public {
        vault.addAsset(address(tokenA), 10000, address(oracleA));
        tokenA.mint(address(vault), 100e18);

        uint256 value = vault.getAssetValue(address(tokenA));
        assertEq(value, 1000e18); // 100 tokens * $10
    }

    function testGetAssetValueDifferentDecimals() public {
        // USDC has 6 decimals, oracle reports $1.00
        vault.addAsset(address(usdc), 10000, address(usdcOracle));
        usdc.mint(address(vault), 1000e6); // 1000 USDC

        uint256 value = vault.getAssetValue(address(usdc));
        assertEq(value, 1000e18); // Should be $1000 in 18 decimals
    }

    function testGetPricePerShare() public {
        vault.addAsset(address(tokenA), 10000, address(oracleA));
        tokenA.mint(address(vault), 100e18); // NAV = $1000

        // Mint 500 shares
        vm.prank(address(this));
        vault.mint(address(alice), 500e18);

        uint256 pricePerShare = vault.getPricePerShare();
        assertEq(pricePerShare, 2e18); // $1000 / 500 shares = $2 per share
    }

    function testGetPricePerShareNoShares() public {
        uint256 pricePerShare = vault.getPricePerShare();
        assertEq(pricePerShare, 1e18); // Default to 1:1 when no shares
    }

    // ========== ORACLE TESTS ==========

    function testOraclePriceNormalization() public {
        vault.addAsset(address(tokenA), 10000, address(oracleA));

        uint256 price = vault.getOraclePrice(address(oracleA));
        assertEq(price, 10e18); // $10 normalized to 18 decimals
    }

    function testStaleOraclePrice() public {
        vault.addAsset(address(tokenA), 10000, address(oracleA));

        // Make price stale
        oracleA.setUpdatedAt(block.timestamp - 2 hours);

        vm.expectRevert(MultiAssetVaultSolution.StalePrice.selector);
        vault.getOraclePrice(address(oracleA));
    }

    function testInvalidOraclePrice() public {
        MockPriceOracle badOracle = new MockPriceOracle(-100, 8); // Negative price
        vault.addAsset(address(tokenA), 10000, address(badOracle));

        vm.expectRevert(MultiAssetVaultSolution.InvalidPrice.selector);
        vault.getOraclePrice(address(badOracle));
    }

    // ========== DEPOSIT TESTS ==========

    function testFirstDeposit() public {
        vault.addAsset(address(usdc), 10000, address(usdcOracle)); // 100% USDC

        vm.prank(alice);
        uint256 shares = vault.deposit(10000e6); // Deposit 10k USDC

        // First deposit: 1:1 ratio minus fee (0.1%)
        uint256 expectedShares = 10000e6 - (10000e6 * 10) / 10000;
        assertEq(shares, expectedShares);
        assertEq(vault.balanceOf(alice), expectedShares);
    }

    function testSubsequentDeposit() public {
        vault.addAsset(address(tokenA), 10000, address(oracleA));
        tokenA.mint(address(vault), 100e18); // NAV = $1000

        // First deposit
        vm.prank(address(this));
        vault.mint(address(alice), 500e18); // 500 shares

        // Alice deposits $1000 when NAV is $1000 and supply is 500
        // shares = (1000 * 500) / 1000 = 500 shares (minus fee)
        vm.prank(alice);
        uint256 shares = vault.deposit(1000e6);

        uint256 expectedShares = 500e6 - (500e6 * 10) / 10000;
        assertApproxEqRel(shares, expectedShares, 0.01e18); // 1% tolerance
    }

    function testDepositWithMultipleAssets() public {
        vault.addAsset(address(tokenA), 5000, address(oracleA)); // 50%
        vault.addAsset(address(tokenB), 5000, address(oracleB)); // 50%

        tokenA.mint(address(vault), 50e18); // $500
        tokenB.mint(address(vault), 100e18); // $500
        // Total NAV = $1000

        vm.prank(address(this));
        vault.mint(address(bob), 1000e18); // 1000 shares

        vm.prank(alice);
        uint256 shares = vault.deposit(1000e6); // Deposit $1000

        // shares = (1000 * 1000) / 1000 = 1000 (minus 0.1% fee)
        uint256 expectedShares = 1000e6 - (1000e6 * 10) / 10000;
        assertApproxEqRel(shares, expectedShares, 0.01e18);
    }

    function testPreviewDeposit() public {
        vault.addAsset(address(tokenA), 10000, address(oracleA));
        tokenA.mint(address(vault), 100e18); // NAV = $1000

        vm.prank(address(this));
        vault.mint(address(alice), 500e18); // 500 shares

        uint256 previewShares = vault.previewDeposit(1000e6);

        vm.prank(alice);
        uint256 actualShares = vault.deposit(1000e6);

        assertEq(previewShares, actualShares);
    }

    function testCannotDepositZero() public {
        vault.addAsset(address(usdc), 10000, address(usdcOracle));

        vm.prank(alice);
        vm.expectRevert(MultiAssetVaultSolution.InvalidAmount.selector);
        vault.deposit(0);
    }

    // ========== WITHDRAW TESTS ==========

    function testWithdraw() public {
        vault.addAsset(address(usdc), 10000, address(usdcOracle));

        // Alice deposits
        vm.prank(alice);
        uint256 shares = vault.deposit(10000e6);

        uint256 balanceBefore = usdc.balanceOf(alice);

        // Alice withdraws all shares
        vm.prank(alice);
        uint256 received = vault.withdraw(shares);

        assertGt(received, 0);
        assertEq(vault.balanceOf(alice), 0);

        // Should receive approximately original amount minus fees
        uint256 balanceAfter = usdc.balanceOf(alice);
        assertGt(balanceAfter, balanceBefore);
    }

    function testWithdrawMultipleAssets() public {
        vault.addAsset(address(usdc), 5000, address(usdcOracle));
        vault.addAsset(address(tokenA), 5000, address(oracleA));

        // Setup vault with assets
        usdc.mint(address(vault), 5000e6);
        tokenA.mint(address(vault), 50e18); // Worth $500

        vm.prank(address(this));
        vault.mint(address(alice), 1000e18); // Alice has 100% of shares

        vm.prank(alice);
        uint256 received = vault.withdraw(500e18); // Withdraw 50%

        assertGt(received, 0);
        assertEq(vault.balanceOf(alice), 500e18); // 50% remains
    }

    function testPreviewWithdraw() public {
        vault.addAsset(address(usdc), 10000, address(usdcOracle));

        vm.prank(alice);
        uint256 shares = vault.deposit(10000e6);

        uint256 previewAmount = vault.previewWithdraw(shares / 2);

        vm.prank(alice);
        uint256 actualAmount = vault.withdraw(shares / 2);

        assertApproxEqRel(previewAmount, actualAmount, 0.05e18); // 5% tolerance (due to swaps)
    }

    function testCannotWithdrawMoreThanBalance() public {
        vault.addAsset(address(usdc), 10000, address(usdcOracle));

        vm.prank(alice);
        uint256 shares = vault.deposit(1000e6);

        vm.prank(alice);
        vm.expectRevert(MultiAssetVaultSolution.InsufficientShares.selector);
        vault.withdraw(shares + 1);
    }

    // ========== CURRENT WEIGHTS TESTS ==========

    function testGetCurrentWeights() public {
        vault.addAsset(address(tokenA), 5000, address(oracleA)); // Target 50%
        vault.addAsset(address(tokenB), 5000, address(oracleB)); // Target 50%

        // Give vault assets at target weights
        tokenA.mint(address(vault), 50e18); // 50 * $10 = $500
        tokenB.mint(address(vault), 100e18); // 100 * $5 = $500

        uint256[] memory weights = vault.getCurrentWeights();

        assertEq(weights[0], 5000); // 50%
        assertEq(weights[1], 5000); // 50%
    }

    function testGetCurrentWeightsUnbalanced() public {
        vault.addAsset(address(tokenA), 5000, address(oracleA)); // Target 50%
        vault.addAsset(address(tokenB), 5000, address(oracleB)); // Target 50%

        // Give vault unbalanced assets
        tokenA.mint(address(vault), 75e18); // 75 * $10 = $750 (75%)
        tokenB.mint(address(vault), 50e18); // 50 * $5 = $250 (25%)

        uint256[] memory weights = vault.getCurrentWeights();

        assertEq(weights[0], 7500); // 75%
        assertEq(weights[1], 2500); // 25%
    }

    // ========== REBALANCING TESTS ==========

    function testNeedsRebalancing() public {
        vault.addAsset(address(tokenA), 5000, address(oracleA)); // Target 50%
        vault.addAsset(address(tokenB), 5000, address(oracleB)); // Target 50%

        // Balanced - should not need rebalancing
        tokenA.mint(address(vault), 50e18); // $500
        tokenB.mint(address(vault), 100e18); // $500

        assertFalse(vault.needsRebalancing());

        // Make unbalanced beyond threshold (5%)
        tokenA.mint(address(vault), 10e18); // Now 60 * $10 = $600 (60%)

        // Advance time to pass minimum interval
        vm.warp(block.timestamp + 2 hours);

        assertTrue(vault.needsRebalancing());
    }

    function testCalculateRebalanceAmounts() public {
        vault.addAsset(address(tokenA), 5000, address(oracleA)); // Target 50%
        vault.addAsset(address(tokenB), 5000, address(oracleB)); // Target 50%

        // Unbalanced: 75% A, 25% B
        tokenA.mint(address(vault), 75e18); // $750
        tokenB.mint(address(vault), 50e18); // $250

        (uint256[] memory sells, uint256[] memory buys) = vault.calculateRebalanceAmounts();

        // Should sell $250 of A and buy $250 of B
        assertEq(sells[0], 250e18);
        assertEq(buys[1], 250e18);
    }

    function testRebalance() public {
        vault.addAsset(address(usdc), 5000, address(usdcOracle)); // Target 50%
        vault.addAsset(address(tokenA), 5000, address(oracleA)); // Target 50%

        // Start unbalanced
        usdc.mint(address(vault), 7500e6); // $7500 (75%)
        tokenA.mint(address(vault), 250e18); // $2500 (25%)

        // Advance time
        vm.warp(block.timestamp + 2 hours);

        assertTrue(vault.needsRebalancing());

        // Perform rebalance
        vault.rebalance();

        // Check weights are closer to target
        uint256[] memory weights = vault.getCurrentWeights();

        // Should be approximately 50/50 (within some tolerance due to slippage)
        assertApproxEqAbs(weights[0], 5000, 200); // Within 2%
        assertApproxEqAbs(weights[1], 5000, 200);
    }

    function testRebalanceEmitsEvents() public {
        vault.addAsset(address(usdc), 5000, address(usdcOracle));
        vault.addAsset(address(tokenA), 5000, address(oracleA));

        usdc.mint(address(vault), 7500e6);
        tokenA.mint(address(vault), 250e18);

        vm.warp(block.timestamp + 2 hours);

        vm.expectEmit(true, true, false, false);
        emit MultiAssetVaultSolution.Rebalanced(address(usdc), address(tokenA), 0, 0, 0);

        vault.rebalance();
    }

    function testCannotRebalanceTooSoon() public {
        vault.addAsset(address(tokenA), 5000, address(oracleA));
        vault.addAsset(address(tokenB), 5000, address(oracleB));

        tokenA.mint(address(vault), 75e18);
        tokenB.mint(address(vault), 50e18);

        // Try to rebalance immediately
        vm.expectRevert(MultiAssetVaultSolution.RebalanceNotNeeded.selector);
        vault.rebalance();
    }

    // ========== ORACLE PRICE CHANGE TESTS ==========

    function testNAVChangesWithOraclePrice() public {
        vault.addAsset(address(tokenA), 10000, address(oracleA));
        tokenA.mint(address(vault), 100e18);

        uint256 navBefore = vault.calculateNAV();
        assertEq(navBefore, 1000e18); // 100 * $10

        // Price doubles
        oracleA.setPrice(20e8); // $20

        uint256 navAfter = vault.calculateNAV();
        assertEq(navAfter, 2000e18); // 100 * $20
    }

    function testPricePerShareChangesWithOraclePrice() public {
        vault.addAsset(address(tokenA), 10000, address(oracleA));
        tokenA.mint(address(vault), 100e18);

        vm.prank(address(this));
        vault.mint(address(alice), 500e18); // 500 shares

        uint256 ppsBefore = vault.getPricePerShare();
        assertEq(ppsBefore, 2e18); // $1000 / 500 = $2

        // Price increases 50%
        oracleA.setPrice(15e8); // $15

        uint256 ppsAfter = vault.getPricePerShare();
        assertEq(ppsAfter, 3e18); // $1500 / 500 = $3
    }

    // ========== BASKET COMPOSITION TESTS ==========

    function testGetAllAssets() public {
        vault.addAsset(address(tokenA), 3333, address(oracleA));
        vault.addAsset(address(tokenB), 3333, address(oracleB));
        vault.addAsset(address(tokenC), 3334, address(oracleC));

        MultiAssetVaultSolution.Asset[] memory allAssets = vault.getAllAssets();

        assertEq(allAssets.length, 3);
        assertEq(allAssets[0].token, address(tokenA));
        assertEq(allAssets[1].token, address(tokenB));
        assertEq(allAssets[2].token, address(tokenC));
    }

    function testGetActiveAssets() public {
        vault.addAsset(address(tokenA), 5000, address(oracleA));
        vault.addAsset(address(tokenB), 5000, address(oracleB));

        address[] memory active = vault.getActiveAssets();

        assertEq(active.length, 2);
        assertEq(active[0], address(tokenA));
        assertEq(active[1], address(tokenB));
    }

    function testRemoveAsset() public {
        vault.addAsset(address(tokenA), 5000, address(oracleA));
        vault.addAsset(address(tokenB), 5000, address(oracleB));

        // Cannot remove with balance
        tokenA.mint(address(vault), 10e18);

        vm.expectRevert("Asset has balance, sell first");
        vault.removeAsset(address(tokenA));

        // Burn balance
        vm.prank(address(vault));
        tokenA.transfer(address(0xdead), 10e18);

        // Now can remove
        vault.removeAsset(address(tokenA));

        address[] memory active = vault.getActiveAssets();
        assertEq(active.length, 1);
        assertEq(active[0], address(tokenB));
    }

    // ========== PERFORMANCE TRACKING TESTS ==========

    function testPerformanceMetrics() public {
        (uint256 avgSlippage, uint256 deposited, uint256 withdrawn, uint256 rebalances) =
            vault.getPerformanceMetrics();

        assertEq(avgSlippage, 0);
        assertEq(deposited, 0);
        assertEq(withdrawn, 0);
        assertEq(rebalances, 0);

        // Make a deposit
        vault.addAsset(address(usdc), 10000, address(usdcOracle));

        vm.prank(alice);
        vault.deposit(1000e6);

        (, deposited,,) = vault.getPerformanceMetrics();
        assertEq(deposited, 1000e6);
    }

    function testSlippageTracking() public {
        vault.addAsset(address(usdc), 5000, address(usdcOracle));
        vault.addAsset(address(tokenA), 5000, address(oracleA));

        // Set DEX slippage
        dex.setSlippage(200); // 2% slippage

        usdc.mint(address(vault), 7500e6);
        tokenA.mint(address(vault), 250e18);

        vm.warp(block.timestamp + 2 hours);

        vault.rebalance();

        (uint256 avgSlippage,,,) = vault.getPerformanceMetrics();
        assertGt(avgSlippage, 0); // Should have recorded some slippage
    }

    // ========== ADMIN FUNCTION TESTS ==========

    function testSetRebalanceThreshold() public {
        vault.setRebalanceThreshold(300); // 3%
        assertEq(vault.rebalanceThreshold(), 300);
    }

    function testSetRebalanceThresholdTooHigh() public {
        vm.expectRevert("Threshold too high");
        vault.setRebalanceThreshold(1001); // >10%
    }

    function testSetDepositFee() public {
        vault.setDepositFee(50); // 0.5%
        assertEq(vault.depositFee(), 50);
    }

    function testSetDepositFeeTooHigh() public {
        vm.expectRevert("Fee too high");
        vault.setDepositFee(101); // >1%
    }

    function testOnlyOwnerCanAddAsset() public {
        vm.prank(alice);
        vm.expectRevert();
        vault.addAsset(address(tokenA), 5000, address(oracleA));
    }

    function testOnlyOwnerCanSetWeight() public {
        vault.addAsset(address(tokenA), 5000, address(oracleA));
        vault.addAsset(address(tokenB), 5000, address(oracleB));

        vm.prank(alice);
        vm.expectRevert();
        vault.setTargetWeight(address(tokenA), 6000);
    }

    // ========== EDGE CASE TESTS ==========

    function testDepositWithNAVZero() public {
        vault.addAsset(address(usdc), 10000, address(usdcOracle));

        // First deposit when NAV is 0
        vm.prank(alice);
        uint256 shares = vault.deposit(1000e6);

        assertGt(shares, 0);
    }

    function testMultipleUsersSharesAccounting() public {
        vault.addAsset(address(usdc), 10000, address(usdcOracle));

        // Alice deposits first
        vm.prank(alice);
        uint256 aliceShares = vault.deposit(10000e6);

        // Bob deposits same amount
        vm.prank(bob);
        uint256 bobShares = vault.deposit(10000e6);

        // Should get approximately same shares
        assertApproxEqRel(aliceShares, bobShares, 0.01e18);

        // Total shares should equal sum
        assertEq(vault.totalSupply(), aliceShares + bobShares);
    }

    function testComplexRebalancingScenario() public {
        // Create a 3-asset portfolio
        vault.addAsset(address(tokenA), 4000, address(oracleA)); // 40%
        vault.addAsset(address(tokenB), 3000, address(oracleB)); // 30%
        vault.addAsset(address(tokenC), 3000, address(oracleC)); // 30%

        // Start with balanced portfolio
        tokenA.mint(address(vault), 40e18); // $400
        tokenB.mint(address(vault), 60e18); // $300
        tokenC.mint(address(vault), 15e8); // $300
        // Total: $1000

        // Simulate price changes
        oracleA.setPrice(15e8); // A: $10 -> $15 (+50%)
        // Now A is worth $600 (60% of $1000)

        vm.warp(block.timestamp + 2 hours);

        assertTrue(vault.needsRebalancing());

        vault.rebalance();

        // Should be closer to target weights
        uint256[] memory weights = vault.getCurrentWeights();
        assertApproxEqAbs(weights[0], 4000, 300); // ~40%
        assertApproxEqAbs(weights[1], 3000, 300); // ~30%
        assertApproxEqAbs(weights[2], 3000, 300); // ~30%
    }
}
