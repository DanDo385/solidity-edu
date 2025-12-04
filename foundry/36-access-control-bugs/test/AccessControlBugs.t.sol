// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/AccessControlBugsSolution.sol";

/**
 * @title Project 36: Access Control Bugs - Tests
 * @notice Comprehensive tests for access control vulnerabilities and fixes
 */
contract AccessControlBugsTest is Test {
    // Actors
    address owner;
    address attacker;
    address user1;
    address user2;

    // Setup common test accounts
    function setUp() public {
        owner = makeAddr("owner");
        attacker = makeAddr("attacker");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        vm.deal(owner, 100 ether);
        vm.deal(attacker, 100 ether);
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
    }

    // ============================================================================
    // Test 1: Uninitialized Owner Vulnerability
    // ============================================================================

    function testUninitializedOwner_Exploit() public {
        vm.startPrank(owner);
        UninitializedWallet wallet = new UninitializedWallet();
        vm.deal(address(wallet), 10 ether);
        vm.stopPrank();

        // Verify owner is not initialized
        assertEq(wallet.owner(), address(0));

        // Attacker takes ownership
        vm.startPrank(attacker);
        wallet.setOwner(attacker);
        assertEq(wallet.owner(), attacker);

        // Attacker withdraws funds
        uint256 balanceBefore = attacker.balance;
        wallet.withdraw();
        assertEq(attacker.balance, balanceBefore + 10 ether);
        assertEq(address(wallet).balance, 0);
        vm.stopPrank();
    }

    function testUninitializedOwner_CompleteExploit() public {
        vm.startPrank(owner);
        UninitializedWallet wallet = new UninitializedWallet();
        vm.deal(address(wallet), 10 ether);
        vm.stopPrank();

        // Use exploit contract
        vm.startPrank(attacker);
        UninitializedWalletExploit exploit = new UninitializedWalletExploit();
        uint256 balanceBefore = attacker.balance;

        exploit.exploit(wallet);

        assertEq(wallet.owner(), attacker);
        assertEq(attacker.balance, balanceBefore + 10 ether);
        vm.stopPrank();
    }

    function testSecureWallet_OwnerInitialized() public {
        vm.startPrank(owner);
        SecureWallet wallet = new SecureWallet();

        // Owner is initialized
        assertEq(wallet.owner(), owner);

        // Only owner can change owner
        wallet.setOwner(user1);
        assertEq(wallet.owner(), user1);
        vm.stopPrank();

        // Attacker cannot take ownership
        vm.startPrank(attacker);
        vm.expectRevert("Not owner");
        wallet.setOwner(attacker);
        vm.stopPrank();
    }

    function testSecureWallet_OnlyOwnerCanWithdraw() public {
        vm.startPrank(owner);
        SecureWallet wallet = new SecureWallet();
        vm.deal(address(wallet), 10 ether);
        vm.stopPrank();

        // Attacker cannot withdraw
        vm.startPrank(attacker);
        vm.expectRevert("Not owner");
        wallet.withdraw();
        vm.stopPrank();

        // Owner can withdraw
        vm.startPrank(owner);
        uint256 balanceBefore = owner.balance;
        wallet.withdraw();
        assertEq(owner.balance, balanceBefore + 10 ether);
        vm.stopPrank();
    }

    // ============================================================================
    // Test 2: Missing Modifier Vulnerability
    // ============================================================================

    function testMissingModifier_Exploit() public {
        vm.startPrank(owner);
        MissingModifier target = new MissingModifier();
        vm.stopPrank();

        // Users deposit funds
        vm.prank(user1);
        target.deposit{value: 5 ether}();

        vm.prank(user2);
        target.deposit{value: 5 ether}();

        assertEq(address(target).balance, 10 ether);

        // Attacker exploits missing modifier
        vm.startPrank(attacker);
        uint256 ownerBalanceBefore = owner.balance;

        // Anyone can call emergencyWithdraw!
        target.emergencyWithdraw();

        // Funds sent to owner (but attacker triggered it)
        assertEq(owner.balance, ownerBalanceBefore + 10 ether);
        assertEq(address(target).balance, 0);
        vm.stopPrank();
    }

    function testMissingModifier_CompleteExploit() public {
        vm.startPrank(owner);
        MissingModifier target = new MissingModifier();
        vm.deal(address(target), 10 ether);
        vm.stopPrank();

        vm.startPrank(attacker);
        MissingModifierExploit exploit = new MissingModifierExploit();

        uint256 ownerBalanceBefore = owner.balance;
        exploit.exploit(target);

        assertEq(owner.balance, ownerBalanceBefore + 10 ether);
        vm.stopPrank();
    }

    function testSecureModifiers_OnlyOwnerCanWithdraw() public {
        vm.startPrank(owner);
        SecureModifiers target = new SecureModifiers();
        vm.stopPrank();

        vm.prank(user1);
        target.deposit{value: 10 ether}();

        // Attacker cannot withdraw
        vm.startPrank(attacker);
        vm.expectRevert("Not owner");
        target.emergencyWithdraw();
        vm.stopPrank();

        // Owner can withdraw
        vm.startPrank(owner);
        uint256 balanceBefore = owner.balance;
        target.emergencyWithdraw();
        assertEq(owner.balance, balanceBefore + 10 ether);
        vm.stopPrank();
    }

    // ============================================================================
    // Test 3: tx.origin vs msg.sender Vulnerability
    // ============================================================================

    function testTxOrigin_PhishingExploit() public {
        vm.startPrank(owner);
        TxOriginWallet wallet = new TxOriginWallet();
        vm.deal(address(wallet), 10 ether);
        vm.stopPrank();

        // Attacker deploys phishing contract
        vm.prank(attacker);
        TxOriginExploit phishing = new TxOriginExploit(wallet);

        // Owner innocently calls phishing contract
        // (thinking it's a legitimate contract)
        vm.startPrank(owner);
        uint256 attackerBalanceBefore = attacker.balance;

        // This call drains owner's wallet!
        phishing.claimReward();

        // Attacker received the funds
        assertEq(attacker.balance, attackerBalanceBefore + 10 ether);
        assertEq(address(wallet).balance, 0);
        vm.stopPrank();
    }

    function testSecureMsgSender_PhishingPrevented() public {
        vm.startPrank(owner);
        SecureMsgSenderWallet wallet = new SecureMsgSenderWallet();
        vm.deal(address(wallet), 10 ether);
        vm.stopPrank();

        // Even if owner calls another contract that tries to withdraw,
        // it will fail because msg.sender is not owner

        vm.startPrank(owner);
        // Create a contract that tries to withdraw
        MaliciousContract malicious = new MaliciousContract();

        // Owner calls malicious contract
        // This should fail to drain the wallet
        vm.expectRevert("Not owner");
        malicious.tryToWithdraw(wallet);

        // Wallet still has funds
        assertEq(address(wallet).balance, 10 ether);
        vm.stopPrank();
    }

    // ============================================================================
    // Test 4: Role Escalation Vulnerability
    // ============================================================================

    function testRoleEscalation_Exploit() public {
        vm.startPrank(owner);
        VulnerableRoles target = new VulnerableRoles();
        vm.stopPrank();

        // Verify attacker is not admin
        assertFalse(target.admins(attacker));
        assertFalse(target.moderators(attacker));

        // Attacker escalates to admin
        vm.startPrank(attacker);

        // Step 1: Add self as moderator (no access control!)
        target.addModerator(attacker);
        assertTrue(target.moderators(attacker));

        // Step 2: Promote self to admin
        target.promoteToAdmin(attacker);
        assertTrue(target.admins(attacker));

        // Step 3: Can now call admin functions
        target.criticalOperation();
        vm.stopPrank();
    }

    function testRoleEscalation_CompleteExploit() public {
        vm.startPrank(owner);
        VulnerableRoles target = new VulnerableRoles();
        vm.stopPrank();

        vm.startPrank(attacker);
        RoleEscalationExploit exploit = new RoleEscalationExploit();

        // Exploit escalates to admin and calls critical function
        exploit.exploit(target);

        // Verify exploit is now admin
        assertTrue(target.admins(address(exploit)));
        vm.stopPrank();
    }

    function testSecureRoles_NoEscalation() public {
        vm.startPrank(owner);
        SecureRoles target = new SecureRoles();
        vm.stopPrank();

        // Attacker cannot add themselves as moderator
        vm.startPrank(attacker);
        vm.expectRevert("Not admin");
        target.addModerator(attacker);
        vm.stopPrank();

        // Owner adds attacker as moderator
        vm.prank(owner);
        target.addModerator(attacker);

        // Moderator cannot promote to admin
        vm.startPrank(attacker);
        vm.expectRevert("Not owner");
        target.addAdmin(attacker);
        vm.stopPrank();
    }

    function testSecureRoles_ProperHierarchy() public {
        vm.startPrank(owner);
        SecureRoles target = new SecureRoles();

        // Owner can add admin
        target.addAdmin(user1);
        assertTrue(target.admins(user1));

        // Admin can add moderator
        vm.startPrank(user1);
        target.addModerator(user2);
        assertTrue(target.moderators(user2));
        vm.stopPrank();

        // Only owner can remove admin
        vm.prank(attacker);
        vm.expectRevert("Not owner");
        target.removeAdmin(user1);

        vm.prank(owner);
        target.removeAdmin(user1);
        assertFalse(target.admins(user1));
        vm.stopPrank();
    }

    // ============================================================================
    // Test 5: Public Initializer Vulnerability
    // ============================================================================

    function testPublicInitializer_Exploit() public {
        vm.startPrank(owner);
        PublicInitializer target = new PublicInitializer();
        vm.stopPrank();

        // Attacker initializes before owner
        vm.startPrank(attacker);
        target.initialize(attacker);

        // Attacker is now owner with all tokens
        assertEq(target.owner(), attacker);
        assertEq(target.balances(attacker), 1000000);
        vm.stopPrank();

        // Owner cannot initialize anymore
        vm.startPrank(owner);
        vm.expectRevert("Already initialized");
        target.initialize(owner);
        vm.stopPrank();
    }

    function testPublicInitializer_CompleteExploit() public {
        vm.startPrank(owner);
        PublicInitializer target = new PublicInitializer();
        vm.stopPrank();

        vm.startPrank(attacker);
        PublicInitializerExploit exploit = new PublicInitializerExploit();
        exploit.exploit(target, attacker);

        assertEq(target.owner(), attacker);
        assertEq(target.balances(attacker), 1000000);
        vm.stopPrank();
    }

    function testSecureInitializer_ConstructorInitialization() public {
        vm.startPrank(owner);
        SecureInitializer target = new SecureInitializer();

        // Owner initialized in constructor
        assertEq(target.owner(), owner);
        assertEq(target.balances(owner), 1000000);
        vm.stopPrank();
    }

    function testSecureUpgradeableInitializer_OnlyDeployer() public {
        vm.startPrank(owner);
        SecureUpgradeableInitializer target = new SecureUpgradeableInitializer();

        // Owner can initialize
        target.initialize(user1);
        assertEq(target.owner(), user1);
        vm.stopPrank();

        // Cannot initialize again
        vm.startPrank(attacker);
        vm.expectRevert("Already initialized");
        target.initialize(attacker);
        vm.stopPrank();
    }

    function testSecureUpgradeableInitializer_OnlyDeployerCanInit() public {
        vm.startPrank(owner);
        SecureUpgradeableInitializer target = new SecureUpgradeableInitializer();
        vm.stopPrank();

        // Non-deployer cannot initialize
        vm.startPrank(attacker);
        vm.expectRevert("Not deployer");
        target.initialize(attacker);
        vm.stopPrank();
    }

    // ============================================================================
    // Test 6: Unprotected Delegatecall Vulnerability
    // ============================================================================

    function testDelegatecall_Exploit() public {
        vm.startPrank(owner);
        UnprotectedDelegatecall target = new UnprotectedDelegatecall();
        vm.deal(address(target), 10 ether);
        vm.stopPrank();

        // Attacker deploys malicious library
        vm.startPrank(attacker);
        MaliciousLibrary malicious = new MaliciousLibrary();

        // Attacker calls executeLibrary with malicious.pwn()
        bytes memory data = abi.encodeWithSignature("pwn()");
        target.executeLibrary(address(malicious), data);

        // Attacker is now owner!
        assertEq(target.owner(), attacker);
        vm.stopPrank();
    }

    function testDelegatecall_CompleteExploit() public {
        vm.startPrank(owner);
        UnprotectedDelegatecall target = new UnprotectedDelegatecall();
        vm.stopPrank();

        vm.startPrank(attacker);
        DelegatecallExploit exploit = new DelegatecallExploit();
        exploit.exploit(target);

        assertEq(target.owner(), attacker);
        vm.stopPrank();
    }

    function testSecureDelegatecall_OnlyTrusted() public {
        vm.startPrank(owner);
        SecureDelegatecall target = new SecureDelegatecall();
        MaliciousLibrary malicious = new MaliciousLibrary();
        vm.stopPrank();

        // Attacker cannot call untrusted library
        vm.startPrank(attacker);
        bytes memory data = abi.encodeWithSignature("pwn()");

        vm.expectRevert("Not owner");
        target.executeLibrary(address(malicious), data);
        vm.stopPrank();

        // Owner cannot call untrusted library either
        vm.startPrank(owner);
        vm.expectRevert("Library not trusted");
        target.executeLibrary(address(malicious), data);
        vm.stopPrank();
    }

    function testSecureDelegatecall_TrustedLibraryWorks() public {
        vm.startPrank(owner);
        SecureDelegatecall target = new SecureDelegatecall();
        GoodLibrary goodLib = new GoodLibrary();

        // Add trusted library
        target.addTrustedLibrary(address(goodLib));

        // Can execute trusted library
        bytes memory data = abi.encodeWithSignature("doSomething()");
        target.executeLibrary(address(goodLib), data);
        vm.stopPrank();
    }

    // ============================================================================
    // Test 7: Unprotected Mint Vulnerability
    // ============================================================================

    function testVulnerableToken_MintExploit() public {
        vm.startPrank(owner);
        VulnerableToken token = new VulnerableToken(1000000);
        vm.stopPrank();

        // Attacker mints unlimited tokens
        vm.startPrank(attacker);
        uint256 attackerBalanceBefore = token.balanceOf(attacker);

        token.mint(attacker, 1000000 * 10**18);

        assertEq(token.balanceOf(attacker), attackerBalanceBefore + 1000000 * 10**18);
        vm.stopPrank();
    }

    function testVulnerableToken_CompleteExploit() public {
        vm.startPrank(owner);
        VulnerableToken token = new VulnerableToken(1000000);
        vm.stopPrank();

        vm.startPrank(attacker);
        VulnerableTokenExploit exploit = new VulnerableTokenExploit();
        exploit.exploit(token, attacker);

        assertTrue(token.balanceOf(attacker) > 0);
        vm.stopPrank();
    }

    function testSecureToken_OnlyOwnerCanMint() public {
        vm.startPrank(owner);
        SecureToken token = new SecureToken(1000000);
        vm.stopPrank();

        // Attacker cannot mint
        vm.startPrank(attacker);
        vm.expectRevert("Not owner");
        token.mint(attacker, 1000000);
        vm.stopPrank();

        // Owner can mint
        vm.startPrank(owner);
        uint256 balanceBefore = token.balanceOf(user1);
        token.mint(user1, 1000);
        assertEq(token.balanceOf(user1), balanceBefore + 1000);
        vm.stopPrank();
    }

    function testSecureToken_AnyoneCanBurn() public {
        vm.startPrank(owner);
        SecureToken token = new SecureToken(1000000);
        token.transfer(user1, 1000);
        vm.stopPrank();

        // User can burn their own tokens
        vm.startPrank(user1);
        uint256 balanceBefore = token.balanceOf(user1);
        token.burn(500);
        assertEq(token.balanceOf(user1), balanceBefore - 500);
        vm.stopPrank();
    }

    // ============================================================================
    // Test 8: OpenZeppelin AccessControl Pattern
    // ============================================================================

    function testAccessControl_RoleBasedPermissions() public {
        vm.startPrank(owner);
        SecureAccessControl target = new SecureAccessControl();

        // Owner has all roles
        assertTrue(target.hasRole(target.DEFAULT_ADMIN_ROLE(), owner));
        assertTrue(target.hasRole(target.ADMIN_ROLE(), owner));
        assertTrue(target.hasRole(target.MINTER_ROLE(), owner));

        // Grant user1 MINTER_ROLE
        target.grantRole(target.MINTER_ROLE(), user1);
        vm.stopPrank();

        // User1 can call minter function
        vm.prank(user1);
        target.minterFunction();

        // User1 cannot call admin function
        vm.startPrank(user1);
        vm.expectRevert();
        target.adminFunction();
        vm.stopPrank();

        // Attacker has no roles
        vm.startPrank(attacker);
        vm.expectRevert();
        target.adminFunction();

        vm.expectRevert();
        target.minterFunction();
        vm.stopPrank();
    }

    function testAccessControl_RoleManagement() public {
        vm.startPrank(owner);
        SecureAccessControl target = new SecureAccessControl();

        // Grant and revoke roles
        target.grantRole(target.ADMIN_ROLE(), user1);
        assertTrue(target.hasRole(target.ADMIN_ROLE(), user1));

        target.revokeRole(target.ADMIN_ROLE(), user1);
        assertFalse(target.hasRole(target.ADMIN_ROLE(), user1));
        vm.stopPrank();
    }

    function testOwnable_OnlyOwnerCanSetValue() public {
        vm.startPrank(owner);
        SecureOwnable target = new SecureOwnable();

        target.setValue(42);
        assertEq(target.getValue(), 42);
        vm.stopPrank();

        // Attacker cannot set value
        vm.startPrank(attacker);
        vm.expectRevert();
        target.setValue(99);
        vm.stopPrank();
    }

    function testOwnable_OwnershipTransfer() public {
        vm.startPrank(owner);
        SecureOwnable target = new SecureOwnable();

        // Transfer ownership
        target.transferOwnership(user1);
        assertEq(target.owner(), user1);
        vm.stopPrank();

        // New owner can set value
        vm.prank(user1);
        target.setValue(100);
        assertEq(target.getValue(), 100);

        // Old owner cannot set value
        vm.startPrank(owner);
        vm.expectRevert();
        target.setValue(200);
        vm.stopPrank();
    }

    // ============================================================================
    // Edge Cases and Additional Tests
    // ============================================================================

    function testSecureWallet_CannotSetZeroAddress() public {
        vm.startPrank(owner);
        SecureWallet wallet = new SecureWallet();

        vm.expectRevert("Invalid owner");
        wallet.setOwner(address(0));
        vm.stopPrank();
    }

    function testSecureRoles_CannotRemoveOwner() public {
        vm.startPrank(owner);
        SecureRoles target = new SecureRoles();

        vm.expectRevert("Cannot remove owner");
        target.removeAdmin(owner);
        vm.stopPrank();
    }

    function testSecureToken_CannotTransferToZeroAddress() public {
        vm.startPrank(owner);
        SecureToken token = new SecureToken(1000000);

        vm.expectRevert("Invalid address");
        token.transfer(address(0), 100);
        vm.stopPrank();
    }

    function testSecureToken_CannotMintToZeroAddress() public {
        vm.startPrank(owner);
        SecureToken token = new SecureToken(1000000);

        vm.expectRevert("Invalid address");
        token.mint(address(0), 100);
        vm.stopPrank();
    }

    function testSecureToken_Events() public {
        vm.startPrank(owner);
        SecureToken token = new SecureToken(1000000);

        // Test Mint event
        vm.expectEmit(true, true, false, true);
        emit SecureToken.Mint(user1, 1000);
        token.mint(user1, 1000);

        // Test Transfer event
        vm.stopPrank();
        vm.startPrank(user1);
        vm.expectEmit(true, true, false, true);
        emit SecureToken.Transfer(user1, user2, 500);
        token.transfer(user2, 500);
        vm.stopPrank();
    }

    function testSecureRoles_Events() public {
        vm.startPrank(owner);
        SecureRoles target = new SecureRoles();

        vm.expectEmit(true, false, false, false);
        emit SecureRoles.AdminAdded(user1);
        target.addAdmin(user1);

        vm.expectEmit(true, false, false, false);
        emit SecureRoles.ModeratorAdded(user2);
        target.addModerator(user2);
        vm.stopPrank();
    }
}

// ============================================================================
// Helper Contracts for Testing
// ============================================================================

/**
 * @notice Helper contract to test msg.sender protection
 */
contract MaliciousContract {
    function tryToWithdraw(SecureMsgSenderWallet wallet) public {
        wallet.withdraw(payable(address(this)), 1 ether);
    }

    receive() external payable {}
}

/**
 * @notice Good library for testing trusted delegatecall
 */
contract GoodLibrary {
    uint256 public value;

    function doSomething() public {
        value += 1;
    }
}
