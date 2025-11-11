// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/ERC4626VaultSolution.sol";

// Mock ERC20 for testing
contract MockERC20 is IERC20 {
    string public name = "Mock Token";
    string public symbol = "MOCK";
    uint8 public decimals = 18;
    uint256 public override totalSupply;
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function mint(address to, uint256 amount) external {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }
    
    function transfer(address to, uint256 amount) external override returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
}

contract ERC4626VaultTest is Test {
    ERC4626VaultSolution public vault;
    MockERC20 public underlying;
    
    address public alice;
    address public bob;
    address public carol;
    
    function setUp() public {
        underlying = new MockERC20();
        vault = new ERC4626VaultSolution(
            address(underlying),
            "Vault Token",
            "vTKN"
        );
        
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        carol = makeAddr("carol");
        
        // Mint tokens to test users
        underlying.mint(alice, 10000e18);
        underlying.mint(bob, 10000e18);
        underlying.mint(carol, 10000e18);
    }
    
    // ═══════════════════════════════════════════════════════════
    // DEPOSIT TESTS
    // ═══════════════════════════════════════════════════════════
    
    function test_Deposit_MintsShares() public {
        uint256 depositAmount = 1000e18;
        
        vm.startPrank(alice);
        underlying.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, alice);
        vm.stopPrank();
        
        assertEq(vault.balanceOf(alice), shares);
        assertEq(vault.totalAssets(), depositAmount);
        assertEq(underlying.balanceOf(address(vault)), depositAmount);
    }
    
    function test_Deposit_FirstDepositor() public {
        vm.startPrank(alice);
        underlying.approve(address(vault), 1000e18);
        uint256 shares = vault.deposit(1000e18, alice);
        vm.stopPrank();
        
        // First depositor gets 1:1 ratio
        assertEq(shares, 1000e18);
    }
    
    function test_Deposit_SubsequentDepositors() public {
        // Alice deposits first
        vm.startPrank(alice);
        underlying.approve(address(vault), 1000e18);
        vault.deposit(1000e18, alice);
        vm.stopPrank();
        
        // Bob deposits same amount
        vm.startPrank(bob);
        underlying.approve(address(vault), 1000e18);
        uint256 shares = vault.deposit(1000e18, bob);
        vm.stopPrank();
        
        // Same ratio
        assertEq(shares, 1000e18);
    }
    
    function test_Deposit_EmitsEvent() public {
        vm.startPrank(alice);
        underlying.approve(address(vault), 100e18);
        
        vm.expectEmit(true, true, false, true);
        emit ERC4626VaultSolution.Deposit(alice, alice, 100e18, 100e18);
        
        vault.deposit(100e18, alice);
        vm.stopPrank();
    }
    
    // ═══════════════════════════════════════════════════════════
    // MINT TESTS
    // ═══════════════════════════════════════════════════════════
    
    function test_Mint_DepositsAssets() public {
        vm.startPrank(alice);
        underlying.approve(address(vault), type(uint256).max);
        uint256 assets = vault.mint(500e18, alice);
        vm.stopPrank();
        
        assertEq(vault.balanceOf(alice), 500e18);
        assertEq(assets, 500e18); // First mint is 1:1
    }
    
    // ═══════════════════════════════════════════════════════════
    // WITHDRAW TESTS
    // ═══════════════════════════════════════════════════════════
    
    function test_Withdraw_BurnsShares() public {
        // Setup: Alice deposits
        vm.startPrank(alice);
        underlying.approve(address(vault), 1000e18);
        vault.deposit(1000e18, alice);
        
        // Alice withdraws half
        uint256 sharesBurned = vault.withdraw(500e18, alice, alice);
        vm.stopPrank();
        
        assertEq(vault.balanceOf(alice), 1000e18 - sharesBurned);
        assertEq(underlying.balanceOf(alice), 9500e18); // Got back 500
    }
    
    function test_Withdraw_WithAllowance() public {
        // Alice deposits
        vm.startPrank(alice);
        underlying.approve(address(vault), 1000e18);
        vault.deposit(1000e18, alice);
        
        // Alice approves Bob
        vault.approve(bob, 500e18);
        vm.stopPrank();
        
        // Bob withdraws for Alice
        vm.prank(bob);
        vault.withdraw(400e18, bob, alice);
        
        assertTrue(vault.balanceOf(alice) < 1000e18);
        assertTrue(underlying.balanceOf(bob) > 0);
    }
    
    // ═══════════════════════════════════════════════════════════
    // REDEEM TESTS
    // ═══════════════════════════════════════════════════════════
    
    function test_Redeem_WithdrawsAssets() public {
        vm.startPrank(alice);
        underlying.approve(address(vault), 1000e18);
        vault.deposit(1000e18, alice);
        
        uint256 assets = vault.redeem(500e18, alice, alice);
        vm.stopPrank();
        
        assertEq(vault.balanceOf(alice), 500e18);
        assertEq(assets, 500e18); // 1:1 ratio maintained
    }
    
    // ═══════════════════════════════════════════════════════════
    // CONVERSION TESTS
    // ═══════════════════════════════════════════════════════════
    
    function test_ConvertToShares_FirstDeposit() public {
        uint256 shares = vault.convertToShares(1000e18);
        assertEq(shares, 1000e18);
    }
    
    function test_ConvertToAssets_FirstDeposit() public {
        vm.startPrank(alice);
        underlying.approve(address(vault), 1000e18);
        vault.deposit(1000e18, alice);
        vm.stopPrank();
        
        uint256 assets = vault.convertToAssets(1000e18);
        assertEq(assets, 1000e18);
    }
    
    // ═══════════════════════════════════════════════════════════
    // PREVIEW TESTS
    // ═══════════════════════════════════════════════════════════
    
    function test_PreviewDeposit_MatchesActual() public {
        uint256 previewShares = vault.previewDeposit(1000e18);
        
        vm.startPrank(alice);
        underlying.approve(address(vault), 1000e18);
        uint256 actualShares = vault.deposit(1000e18, alice);
        vm.stopPrank();
        
        assertEq(previewShares, actualShares);
    }
    
    function test_PreviewWithdraw_MatchesActual() public {
        vm.startPrank(alice);
        underlying.approve(address(vault), 1000e18);
        vault.deposit(1000e18, alice);
        
        uint256 previewShares = vault.previewWithdraw(500e18);
        uint256 actualShares = vault.withdraw(500e18, alice, alice);
        vm.stopPrank();
        
        assertEq(previewShares, actualShares);
    }
    
    // ═══════════════════════════════════════════════════════════
    // MAX FUNCTION TESTS
    // ═══════════════════════════════════════════════════════════
    
    function test_MaxWithdraw_ReturnsBalance() public {
        vm.startPrank(alice);
        underlying.approve(address(vault), 1000e18);
        vault.deposit(1000e18, alice);
        vm.stopPrank();
        
        uint256 maxWithdraw = vault.maxWithdraw(alice);
        assertEq(maxWithdraw, 1000e18);
    }
    
    function test_MaxRedeem_ReturnsShares() public {
        vm.startPrank(alice);
        underlying.approve(address(vault), 1000e18);
        vault.deposit(1000e18, alice);
        vm.stopPrank();
        
        uint256 maxRedeem = vault.maxRedeem(alice);
        assertEq(maxRedeem, vault.balanceOf(alice));
    }
    
    // ═══════════════════════════════════════════════════════════
    // EDGE CASE TESTS
    // ═══════════════════════════════════════════════════════════
    
    function test_MultipleUsersDepositAndWithdraw() public {
        // Alice deposits
        vm.startPrank(alice);
        underlying.approve(address(vault), 1000e18);
        vault.deposit(1000e18, alice);
        vm.stopPrank();
        
        // Bob deposits
        vm.startPrank(bob);
        underlying.approve(address(vault), 2000e18);
        vault.deposit(2000e18, bob);
        vm.stopPrank();
        
        // Carol deposits
        vm.startPrank(carol);
        underlying.approve(address(vault), 500e18);
        vault.deposit(500e18, carol);
        vm.stopPrank();
        
        // Total assets should match
        assertEq(vault.totalAssets(), 3500e18);
        
        // Each withdraws
        vm.prank(alice);
        vault.redeem(vault.balanceOf(alice), alice, alice);
        
        vm.prank(bob);
        vault.redeem(vault.balanceOf(bob), bob, bob);
        
        vm.prank(carol);
        vault.redeem(vault.balanceOf(carol), carol, carol);
        
        // Vault should be empty
        assertEq(vault.totalAssets(), 0);
        assertEq(vault.totalSupply(), 0);
    }
    
    // ═══════════════════════════════════════════════════════════
    // FUZZ TESTS
    // ═══════════════════════════════════════════════════════════
    
    function testFuzz_DepositWithdraw(uint96 amount) public {
        vm.assume(amount > 0 && amount <= 10000e18);
        
        vm.startPrank(alice);
        underlying.approve(address(vault), amount);
        uint256 shares = vault.deposit(amount, alice);
        
        uint256 assets = vault.redeem(shares, alice, alice);
        vm.stopPrank();
        
        assertEq(assets, amount);
    }
    
    function testFuzz_ConversionConsistency(uint96 assets) public {
        vm.assume(assets > 0 && assets <= 10000e18);
        
        vm.startPrank(alice);
        underlying.approve(address(vault), assets);
        vault.deposit(assets, alice);
        vm.stopPrank();
        
        uint256 shares = vault.convertToShares(assets);
        uint256 backToAssets = vault.convertToAssets(shares);
        
        assertApproxEqAbs(backToAssets, assets, 1);
    }
}
