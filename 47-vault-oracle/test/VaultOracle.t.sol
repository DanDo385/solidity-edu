// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/VaultOracleSolution.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title VaultOracleTest - Comprehensive Oracle Integration Tests
 * @notice Tests for vault oracle integration, TWAP, and safety mechanisms
 */

// Mock ERC20 token for testing
contract MockToken is ERC20 {
    constructor() ERC20("Mock Token", "MOCK") {
        _mint(msg.sender, 1000000 * 10 ** 18);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

// Mock Chainlink price feed
contract MockChainlinkFeed {
    int256 public price;
    uint256 public updatedAt;
    uint80 public roundId;
    uint80 public answeredInRound;
    uint8 public decimals;

    bool public shouldRevert;

    constructor(int256 _initialPrice, uint8 _decimals) {
        price = _initialPrice;
        decimals = _decimals;
        updatedAt = block.timestamp;
        roundId = 1;
        answeredInRound = 1;
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 _roundId,
            int256 _price,
            uint256 startedAt,
            uint256 _updatedAt,
            uint80 _answeredInRound
        )
    {
        require(!shouldRevert, "Feed reverted");
        return (roundId, price, block.timestamp, updatedAt, answeredInRound);
    }

    function updatePrice(int256 newPrice) external {
        price = newPrice;
        updatedAt = block.timestamp;
        roundId++;
        answeredInRound = roundId;
    }

    function setStale(uint256 age) external {
        updatedAt = block.timestamp - age;
    }

    function setIncompleteRound() external {
        answeredInRound = roundId - 1;
    }

    function setShouldRevert(bool _shouldRevert) external {
        shouldRevert = _shouldRevert;
    }
}

// Mock fallback oracle
contract MockFallbackOracle {
    uint256 public price;
    bool public shouldRevert;

    constructor(uint256 _initialPrice) {
        price = _initialPrice;
    }

    function getPrice() external view returns (uint256) {
        require(!shouldRevert, "Fallback oracle failed");
        return price;
    }

    function updatePrice(uint256 newPrice) external {
        price = newPrice;
    }

    function setShouldRevert(bool _shouldRevert) external {
        shouldRevert = _shouldRevert;
    }
}

contract VaultOracleTest is Test {
    VaultOracleSolution public vault;
    MockToken public token;
    MockChainlinkFeed public chainlinkFeed;
    MockFallbackOracle public fallbackOracle;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public owner;

    uint256 constant INITIAL_PRICE = 2000 * 1e8; // $2000 with 8 decimals (Chainlink format)
    uint256 constant INITIAL_BALANCE = 10000 * 1e18;

    event PriceUpdated(uint256 newPrice, uint256 timestamp, uint256 cumulativePrice);
    event Deposit(address indexed user, uint256 assets, uint256 shares, uint256 price);
    event Withdraw(address indexed user, uint256 assets, uint256 shares, uint256 price);
    event OracleFailed(string reason, uint256 timestamp);
    event EmergencyShutdown(bool status);

    function setUp() public {
        owner = address(this);

        // Deploy mock token
        token = new MockToken();

        // Deploy mock Chainlink feed (8 decimals like real ETH/USD feed)
        chainlinkFeed = new MockChainlinkFeed(int256(INITIAL_PRICE), 8);

        // Deploy mock fallback oracle
        fallbackOracle = new MockFallbackOracle(2000 * 1e18); // 18 decimals

        // Deploy vault
        vault = new VaultOracleSolution(
            address(token),
            address(chainlinkFeed),
            "Vault Shares",
            "vSHARES"
        );

        // Set fallback oracle
        vault.updateFallbackOracle(address(fallbackOracle));

        // Fund test accounts
        token.transfer(alice, INITIAL_BALANCE);
        token.transfer(bob, INITIAL_BALANCE);

        // Approve vault
        vm.prank(alice);
        token.approve(address(vault), type(uint256).max);

        vm.prank(bob);
        token.approve(address(vault), type(uint256).max);
    }

    // ============================================
    // ORACLE PRICE TESTS
    // ============================================

    function testGetChainlinkPrice() public {
        (uint256 price, bool isValid) = vault.getChainlinkPrice();

        assertTrue(isValid, "Price should be valid");
        // $2000 with 8 decimals -> normalized to 18 decimals
        assertEq(price, 2000 * 1e18, "Price should be normalized to 18 decimals");
    }

    function testChainlinkPriceNormalization() public {
        // Test with different decimal values
        MockChainlinkFeed feed6Dec = new MockChainlinkFeed(2000 * 1e6, 6);
        vault.updatePriceFeed(address(feed6Dec));

        (uint256 price, bool isValid) = vault.getChainlinkPrice();
        assertTrue(isValid);
        assertEq(price, 2000 * 1e18, "6 decimals should normalize to 18");

        // Test 18 decimals (no conversion needed)
        MockChainlinkFeed feed18Dec = new MockChainlinkFeed(int256(2000 * 1e18), 18);
        vault.updatePriceFeed(address(feed18Dec));

        (price, isValid) = vault.getChainlinkPrice();
        assertTrue(isValid);
        assertEq(price, 2000 * 1e18, "18 decimals should stay at 18");
    }

    function testStaleDataRejection() public {
        // Make data stale (older than 1 hour)
        chainlinkFeed.setStale(2 hours);

        (uint256 price, bool isValid) = vault.getChainlinkPrice();

        assertFalse(isValid, "Stale data should be rejected");
        assertEq(price, 0, "Price should be 0 for invalid data");
    }

    function testInvalidPriceRejection() public {
        // Set negative/zero price
        chainlinkFeed.updatePrice(0);

        (uint256 price, bool isValid) = vault.getChainlinkPrice();

        assertFalse(isValid, "Zero price should be rejected");
        assertEq(price, 0);

        // Test negative price
        chainlinkFeed.updatePrice(-100);

        (price, isValid) = vault.getChainlinkPrice();
        assertFalse(isValid, "Negative price should be rejected");
    }

    function testIncompleteRoundRejection() public {
        chainlinkFeed.setIncompleteRound();

        (uint256 price, bool isValid) = vault.getChainlinkPrice();

        assertFalse(isValid, "Incomplete round should be rejected");
    }

    function testPriceBounds() public {
        // Set price above max bound
        vault.updatePriceBounds(1e6, 1000 * 1e18); // Max $1000

        chainlinkFeed.updatePrice(5000 * 1e8); // $5000

        (uint256 price, bool isValid) = vault.getChainlinkPrice();
        assertFalse(isValid, "Price above max should be rejected");

        // Set price below min bound
        chainlinkFeed.updatePrice(1); // Very low price

        (price, isValid) = vault.getChainlinkPrice();
        assertFalse(isValid, "Price below min should be rejected");
    }

    // ============================================
    // VALIDATED PRICE TESTS
    // ============================================

    function testGetValidatedPrice() public {
        uint256 price = vault.getValidatedPrice();
        assertEq(price, 2000 * 1e18, "Should return normalized Chainlink price");
    }

    function testValidatedPriceFallbackOnStale() public {
        // Record some observations first
        vault.updateObservation(2000 * 1e18);

        // Make Chainlink stale
        chainlinkFeed.setStale(2 hours);

        // Update fallback oracle
        fallbackOracle.updatePrice(2100 * 1e18);

        uint256 price = vault.getValidatedPrice();

        // Should fall back to fallback oracle
        assertEq(price, 2100 * 1e18, "Should use fallback oracle");
    }

    function testValidatedPriceUsesLastValidOnAllFailures() public {
        // Record initial price
        uint256 initialPrice = vault.lastValidPrice();

        // Make both oracles fail
        chainlinkFeed.setShouldRevert(true);
        fallbackOracle.setShouldRevert(true);

        uint256 price = vault.getValidatedPrice();

        // Should use last valid price
        assertEq(price, initialPrice, "Should use last valid price");
    }

    function testPriceDeviationLimit() public {
        // Set a known valid price
        vault.updateObservation(2000 * 1e18);
        vm.warp(block.timestamp + 1 hours);

        // Try to update with 20% deviation (should fail with 10% limit)
        chainlinkFeed.updatePrice(2400 * 1e8); // +20%

        // Should fall back due to deviation
        uint256 price = vault.getValidatedPrice();

        // Should use fallback or last valid price
        assertTrue(
            price == fallbackOracle.price() || price == vault.lastValidPrice(),
            "Should not use price with high deviation"
        );
    }

    // ============================================
    // TWAP TESTS
    // ============================================

    function testRecordObservation() public {
        uint256 price1 = 2000 * 1e18;

        vm.expectEmit(true, true, true, false);
        emit PriceUpdated(price1, block.timestamp, 0);

        vault.updateObservation(price1);

        (uint256 timestamp, uint256 price, uint256 cumulative) = vault.observations(0);

        assertEq(price, price1, "Price should be recorded");
        assertEq(timestamp, block.timestamp, "Timestamp should be current");
    }

    function testTWAPCalculation() public {
        // Record first observation
        vault.updateObservation(2000 * 1e18);

        // Advance time and record second observation
        vm.warp(block.timestamp + 1 hours);
        vault.updateObservation(2200 * 1e18);

        // Advance time and record third observation
        vm.warp(block.timestamp + 1 hours);
        vault.updateObservation(2400 * 1e18);

        // Calculate TWAP over 2 hours
        uint256 twap = vault.getTWAP(2 hours);

        // TWAP should be weighted average
        // Hour 1: 2000, Hour 2: 2200, Current: 2400
        // TWAP ≈ (2000 + 2200) / 2 = 2100 (simplified)
        assertTrue(twap > 2000 * 1e18 && twap < 2400 * 1e18, "TWAP should be between prices");
    }

    function testTWAPWithMultipleObservations() public {
        uint256[] memory prices = new uint256[](5);
        prices[0] = 2000 * 1e18;
        prices[1] = 2100 * 1e18;
        prices[2] = 2050 * 1e18;
        prices[3] = 2150 * 1e18;
        prices[4] = 2200 * 1e18;

        // Record observations over time
        for (uint256 i = 0; i < prices.length; i++) {
            vault.updateObservation(prices[i]);
            vm.warp(block.timestamp + 1 hours);
        }

        // Get TWAP over 4 hours
        uint256 twap = vault.getTWAP(4 hours);

        // TWAP should smooth out the prices
        assertTrue(twap > 2000 * 1e18 && twap < 2200 * 1e18, "TWAP should be averaged");
    }

    function testTWAPRingBuffer() public {
        // Fill buffer beyond MAX_OBSERVATIONS (24)
        for (uint256 i = 0; i < 30; i++) {
            vault.updateObservation(2000 * 1e18 + i * 1e18);
            vm.warp(block.timestamp + 1 hours);
        }

        // Should only have MAX_OBSERVATIONS
        (, , , , uint256 count) = vault.getOracleStatus();
        assertEq(count, vault.MAX_OBSERVATIONS(), "Should cap at MAX_OBSERVATIONS");
    }

    function testTWAPInsufficientData() public {
        // Only one observation
        vault.updateObservation(2000 * 1e18);

        // Try to get TWAP for period longer than available
        vm.expectRevert();
        vault.getTWAP(2 hours);
    }

    // ============================================
    // VAULT DEPOSIT TESTS
    // ============================================

    function testDeposit() public {
        uint256 depositAmount = 1000 * 1e18;

        vm.prank(alice);
        uint256 shares = vault.deposit(depositAmount);

        assertEq(vault.balanceOf(alice), shares, "Alice should receive shares");
        assertEq(token.balanceOf(address(vault)), depositAmount, "Vault should hold tokens");
        assertTrue(shares > 0, "Should mint shares");
    }

    function testFirstDepositOneToOne() public {
        uint256 depositAmount = 1000 * 1e18;

        vm.prank(alice);
        uint256 shares = vault.deposit(depositAmount);

        // First deposit should be 1:1
        assertEq(shares, depositAmount, "First deposit should be 1:1");
    }

    function testSubsequentDepositsMaintainRatio() public {
        // First deposit
        vm.prank(alice);
        uint256 shares1 = vault.deposit(1000 * 1e18);

        // Second deposit (same amount)
        vm.prank(bob);
        uint256 shares2 = vault.deposit(1000 * 1e18);

        // Should receive same shares
        assertEq(shares1, shares2, "Same deposit should yield same shares");
    }

    function testDepositDuringEmergencyShutdown() public {
        vault.setEmergencyShutdown(true);

        vm.prank(alice);
        vm.expectRevert(VaultOracleSolution.EmergencyShutdownActive.selector);
        vault.deposit(1000 * 1e18);
    }

    function testDepositZeroAmount() public {
        vm.prank(alice);
        vm.expectRevert(VaultOracleSolution.ZeroAmount.selector);
        vault.deposit(0);
    }

    // ============================================
    // VAULT WITHDRAWAL TESTS
    // ============================================

    function testWithdraw() public {
        // Deposit first
        vm.prank(alice);
        uint256 shares = vault.deposit(1000 * 1e18);

        // Record TWAP observation
        vault.updateObservation(2000 * 1e18);
        vm.warp(block.timestamp + 1 hours);

        uint256 balanceBefore = token.balanceOf(alice);

        // Withdraw
        vm.prank(alice);
        uint256 assets = vault.withdraw(shares);

        assertEq(vault.balanceOf(alice), 0, "Shares should be burned");
        assertEq(token.balanceOf(alice), balanceBefore + assets, "Should receive assets");
        assertTrue(assets > 0, "Should receive assets");
    }

    function testWithdrawUsesTWAP() public {
        // Deposit
        vm.prank(alice);
        uint256 shares = vault.deposit(1000 * 1e18);

        // Build TWAP history
        vault.updateObservation(2000 * 1e18);
        vm.warp(block.timestamp + 30 minutes);
        vault.updateObservation(2100 * 1e18);
        vm.warp(block.timestamp + 30 minutes);

        // Withdraw should use TWAP
        vm.prank(alice);
        uint256 assets = vault.withdraw(shares);

        assertTrue(assets > 0, "Should withdraw with TWAP pricing");
    }

    function testWithdrawInsufficientShares() public {
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                VaultOracleSolution.InsufficientShares.selector,
                1000 * 1e18,
                0
            )
        );
        vault.withdraw(1000 * 1e18);
    }

    function testWithdrawZeroAmount() public {
        vm.prank(alice);
        vm.expectRevert(VaultOracleSolution.ZeroAmount.selector);
        vault.withdraw(0);
    }

    // ============================================
    // EMERGENCY TESTS
    // ============================================

    function testEmergencyShutdown() public {
        vm.expectEmit(true, true, true, true);
        emit EmergencyShutdown(true);

        vault.setEmergencyShutdown(true);

        assertTrue(vault.emergencyShutdown(), "Should be in emergency mode");
    }

    function testEmergencyWithdraw() public {
        // Deposit first
        vm.prank(alice);
        uint256 shares = vault.deposit(1000 * 1e18);

        // Activate emergency shutdown
        vault.setEmergencyShutdown(true);

        uint256 balanceBefore = token.balanceOf(alice);

        // Emergency withdraw
        vm.prank(alice);
        uint256 assets = vault.emergencyWithdraw(shares);

        assertEq(vault.balanceOf(alice), 0, "Shares should be burned");
        assertTrue(assets > 0, "Should receive assets");
        assertEq(token.balanceOf(alice), balanceBefore + assets, "Should receive tokens");
    }

    function testEmergencyWithdrawOnlyInEmergency() public {
        vm.prank(alice);
        vault.deposit(1000 * 1e18);

        vm.prank(alice);
        vm.expectRevert("Not in emergency mode");
        vault.emergencyWithdraw(100 * 1e18);
    }

    // ============================================
    // PREVIEW TESTS
    // ============================================

    function testPreviewDeposit() public {
        uint256 depositAmount = 1000 * 1e18;

        uint256 expectedShares = vault.previewDeposit(depositAmount);

        vm.prank(alice);
        uint256 actualShares = vault.deposit(depositAmount);

        assertEq(expectedShares, actualShares, "Preview should match actual");
    }

    function testPreviewWithdraw() public {
        vm.prank(alice);
        uint256 shares = vault.deposit(1000 * 1e18);

        // Build TWAP
        vault.updateObservation(2000 * 1e18);
        vm.warp(block.timestamp + 1 hours);

        uint256 expectedAssets = vault.previewWithdraw(shares);

        assertTrue(expectedAssets > 0, "Should preview assets");
    }

    // ============================================
    // ADMIN TESTS
    // ============================================

    function testUpdatePriceFeed() public {
        MockChainlinkFeed newFeed = new MockChainlinkFeed(3000 * 1e8, 8);

        vault.updatePriceFeed(address(newFeed));

        (uint256 price, bool isValid) = vault.getChainlinkPrice();

        assertTrue(isValid);
        assertEq(price, 3000 * 1e18, "Should use new feed");
    }

    function testUpdateMaxStaleness() public {
        vault.updateMaxStaleness(2 hours);

        assertEq(vault.maxStaleness(), 2 hours, "Should update staleness");
    }

    function testUpdateMaxDeviation() public {
        vault.updateMaxDeviation(2000); // 20%

        assertEq(vault.maxPriceDeviation(), 2000, "Should update deviation");
    }

    function testUpdatePriceBounds() public {
        vault.updatePriceBounds(100 * 1e18, 10000 * 1e18);

        assertEq(vault.minPrice(), 100 * 1e18, "Should update min price");
        assertEq(vault.maxPrice(), 10000 * 1e18, "Should update max price");
    }

    function testOnlyOwnerCanUpdateParams() public {
        vm.prank(alice);
        vm.expectRevert();
        vault.updateMaxStaleness(2 hours);

        vm.prank(alice);
        vm.expectRevert();
        vault.setEmergencyShutdown(true);
    }

    // ============================================
    // INTEGRATION TESTS
    // ============================================

    function testMultipleDepositsAndWithdrawals() public {
        // Alice deposits
        vm.prank(alice);
        uint256 aliceShares = vault.deposit(1000 * 1e18);

        // Bob deposits
        vm.prank(bob);
        uint256 bobShares = vault.deposit(2000 * 1e18);

        // Build TWAP
        vault.updateObservation(2000 * 1e18);
        vm.warp(block.timestamp + 1 hours);

        // Alice withdraws half
        vm.prank(alice);
        vault.withdraw(aliceShares / 2);

        // Bob withdraws all
        vm.prank(bob);
        vault.withdraw(bobShares);

        // Vault should still have Alice's remaining deposit
        assertTrue(vault.totalValue() > 0, "Vault should have remaining deposits");
    }

    function testOraclePriceChangesAffectShares() public {
        // Deposit at $2000
        vm.prank(alice);
        uint256 shares1 = vault.deposit(1000 * 1e18);

        // Price increases to $2500
        chainlinkFeed.updatePrice(2500 * 1e8);

        // Same deposit should get fewer shares (vault value increased)
        vm.prank(bob);
        uint256 shares2 = vault.deposit(1000 * 1e18);

        assertTrue(shares2 < shares1, "Higher price should yield fewer shares");
    }

    function testGetOracleStatus() public {
        vault.updateObservation(2000 * 1e18);

        (
            uint256 chainlinkPrice,
            bool chainlinkValid,
            uint256 twapPrice,
            uint256 lastPrice,
            uint256 observationCount
        ) = vault.getOracleStatus();

        assertTrue(chainlinkValid, "Chainlink should be valid");
        assertEq(chainlinkPrice, 2000 * 1e18, "Chainlink price should match");
        assertTrue(observationCount > 0, "Should have observations");
        assertEq(lastPrice, vault.lastValidPrice(), "Last price should match");
    }

    // ============================================
    // EDGE CASE TESTS
    // ============================================

    function testTotalValueAndPricePerShare() public {
        uint256 totalValue1 = vault.totalValue();
        assertEq(totalValue1, 0, "Initial total value should be 0");

        vm.prank(alice);
        vault.deposit(1000 * 1e18);

        uint256 totalValue2 = vault.totalValue();
        assertEq(totalValue2, 1000 * 1e18, "Total value should equal deposit");

        uint256 pricePerShare = vault.pricePerShare();
        assertTrue(pricePerShare > 0, "Price per share should be positive");
    }

    function testMultipleOracleUpdates() public {
        // Update price multiple times
        for (uint256 i = 0; i < 10; i++) {
            vault.updateObservation(2000 * 1e18 + i * 10 * 1e18);
            vm.warp(block.timestamp + 30 minutes);
        }

        // TWAP should be available
        uint256 twap = vault.getTWAP(2 hours);
        assertTrue(twap > 0, "TWAP should be calculated");
    }

    function testFuzzDeposit(uint256 amount) public {
        amount = bound(amount, 1e18, 1000000 * 1e18);

        vm.prank(alice);
        uint256 shares = vault.deposit(amount);

        assertEq(vault.balanceOf(alice), shares, "Should receive shares");
        assertTrue(shares > 0, "Should mint shares");
    }

    function testFuzzWithdraw(uint256 depositAmount, uint256 withdrawRatio) public {
        depositAmount = bound(depositAmount, 1e18, 1000000 * 1e18);
        withdrawRatio = bound(withdrawRatio, 1, 100);

        // Deposit
        vm.prank(alice);
        uint256 shares = vault.deposit(depositAmount);

        // Build TWAP
        vault.updateObservation(2000 * 1e18);
        vm.warp(block.timestamp + 1 hours);

        // Withdraw portion
        uint256 withdrawShares = (shares * withdrawRatio) / 100;

        vm.prank(alice);
        uint256 assets = vault.withdraw(withdrawShares);

        assertTrue(assets > 0, "Should receive assets");
    }
}
