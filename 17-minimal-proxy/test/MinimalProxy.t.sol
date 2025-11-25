// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/MinimalProxySolution.sol";

/**
 * @title MinimalProxyTest
 * @notice Comprehensive tests for Minimal Proxy (EIP-1167) pattern
 * @dev Tests both functionality and gas comparison
 */
contract MinimalProxyTest is Test {
    SimpleWallet public implementation;
    WalletFactory public factory;
    DirectWallet public directWallet;

    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);

    event WalletCreated(address indexed wallet, address indexed owner, bool deterministic);
    event Initialized(address indexed owner);
    event Deposited(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);

    function setUp() public {
        // Deploy implementation contract
        implementation = new SimpleWallet();

        // Deploy factory with implementation
        factory = new WalletFactory(address(implementation));

        // Deploy a direct wallet for comparison
        directWallet = new DirectWallet(owner);

        // Give users some ETH
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(owner, 100 ether);
    }

    /*//////////////////////////////////////////////////////////////
                        IMPLEMENTATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ImplementationDeployment() public view {
        // Implementation should exist
        assertTrue(address(implementation) != address(0));
        assertTrue(address(implementation).code.length > 0);

        // Should not be initialized (it's just the implementation)
        assertFalse(implementation.isInitialized());
        assertEq(implementation.owner(), address(0));
    }

    function test_ImplementationCannotBeUsedDirectly() public {
        // Trying to use implementation directly should work but is not recommended
        implementation.initialize(owner);
        assertTrue(implementation.isInitialized());

        // But now it can't be initialized again
        vm.expectRevert("Already initialized");
        implementation.initialize(user1);
    }

    /*//////////////////////////////////////////////////////////////
                        FACTORY TESTS
    //////////////////////////////////////////////////////////////*/

    function test_FactoryDeployment() public view {
        // Factory should be deployed with correct implementation
        assertEq(factory.implementation(), address(implementation));
        assertEq(factory.getWalletCount(), 0);
    }

    function test_FactoryRevertsWithInvalidImplementation() public {
        // Should revert with zero address
        vm.expectRevert("Invalid implementation");
        new WalletFactory(address(0));

        // Should revert with EOA (no code)
        vm.expectRevert("Implementation must be contract");
        new WalletFactory(address(0x123));
    }

    /*//////////////////////////////////////////////////////////////
                        CLONE CREATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_CreateWallet() public {
        vm.startPrank(user1);

        // Expect WalletCreated event
        vm.expectEmit(false, true, false, true);
        emit WalletCreated(address(0), user1, false); // address will be different

        // Create wallet
        address wallet = factory.createWallet();

        // Verify wallet was created
        assertTrue(wallet != address(0));
        assertTrue(wallet != address(implementation));

        // Verify wallet is initialized
        SimpleWallet clone = SimpleWallet(payable(wallet));
        assertTrue(clone.isInitialized());
        assertEq(clone.owner(), user1);

        // Verify tracking
        assertEq(factory.userWallets(user1), wallet);
        assertEq(factory.getWalletCount(), 1);
        assertEq(factory.getWalletAt(0), wallet);

        vm.stopPrank();
    }

    function test_CreateWalletRevertsIfAlreadyExists() public {
        vm.startPrank(user1);

        // Create first wallet
        factory.createWallet();

        // Try to create second wallet - should revert
        vm.expectRevert("Wallet already exists");
        factory.createWallet();

        vm.stopPrank();
    }

    function test_MultipleUsersCanCreateWallets() public {
        // User1 creates wallet
        vm.prank(user1);
        address wallet1 = factory.createWallet();

        // User2 creates wallet
        vm.prank(user2);
        address wallet2 = factory.createWallet();

        // Wallets should be different
        assertTrue(wallet1 != wallet2);

        // Each user should have their own wallet
        assertEq(factory.userWallets(user1), wallet1);
        assertEq(factory.userWallets(user2), wallet2);

        // Factory should track both
        assertEq(factory.getWalletCount(), 2);

        // Each wallet should have correct owner
        assertEq(SimpleWallet(payable(wallet1)).owner(), user1);
        assertEq(SimpleWallet(payable(wallet2)).owner(), user2);
    }

    function test_CreateDeterministicWallet() public {
        bytes32 salt = keccak256("user1-wallet");

        vm.startPrank(user1);

        // Predict address
        address predicted = factory.predictWalletAddress(salt);

        // Create deterministic wallet
        vm.expectEmit(true, true, false, true);
        emit WalletCreated(predicted, user1, true);

        address wallet = factory.createDeterministicWallet(salt);

        // Address should match prediction
        assertEq(wallet, predicted);

        // Wallet should be initialized
        SimpleWallet clone = SimpleWallet(payable(wallet));
        assertTrue(clone.isInitialized());
        assertEq(clone.owner(), user1);

        vm.stopPrank();
    }

    function test_DeterministicAddressPrediction() public view {
        bytes32 salt = keccak256("test-salt");

        // Predict address before deployment
        address predicted = factory.predictWalletAddress(salt);

        // Prediction should be deterministic
        address predicted2 = factory.predictWalletAddress(salt);
        assertEq(predicted, predicted2);

        // Different salt should give different prediction
        bytes32 salt2 = keccak256("different-salt");
        address predicted3 = factory.predictWalletAddress(salt2);
        assertTrue(predicted != predicted3);
    }

    function test_CreateDeterministicWalletRevertsIfSaltReused() public {
        bytes32 salt = keccak256("same-salt");

        vm.startPrank(user1);

        // Create first wallet
        factory.createDeterministicWallet(salt);

        // Try to create with same salt - should revert (address collision)
        vm.expectRevert();
        factory.createDeterministicWallet(salt);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                    WALLET FUNCTIONALITY TESTS
    //////////////////////////////////////////////////////////////*/

    function test_WalletDeposit() public {
        vm.prank(user1);
        address wallet = factory.createWallet();

        SimpleWallet clone = SimpleWallet(payable(wallet));

        // Deposit via deposit function
        vm.prank(user2);
        vm.expectEmit(true, false, false, true);
        emit Deposited(user2, 1 ether);
        clone.deposit{value: 1 ether}();

        assertEq(clone.balance(), 1 ether);
        assertEq(clone.getBalance(), 1 ether);
    }

    function test_WalletReceive() public {
        vm.prank(user1);
        address wallet = factory.createWallet();

        SimpleWallet clone = SimpleWallet(payable(wallet));

        // Send ETH directly to wallet
        vm.prank(user2);
        vm.expectEmit(true, false, false, true);
        emit Deposited(user2, 2 ether);
        (bool success,) = wallet.call{value: 2 ether}("");
        assertTrue(success);

        assertEq(clone.balance(), 2 ether);
        assertEq(clone.getBalance(), 2 ether);
    }

    function test_WalletWithdraw() public {
        vm.prank(user1);
        address wallet = factory.createWallet();

        SimpleWallet clone = SimpleWallet(payable(wallet));

        // Deposit first
        vm.prank(user2);
        clone.deposit{value: 5 ether}();

        // Withdraw as owner
        uint256 balanceBefore = user1.balance;
        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit Withdrawn(user1, 3 ether);
        clone.withdraw(3 ether);

        assertEq(clone.balance(), 2 ether);
        assertEq(user1.balance, balanceBefore + 3 ether);
    }

    function test_WalletWithdrawRevertsIfNotOwner() public {
        vm.prank(user1);
        address wallet = factory.createWallet();

        SimpleWallet clone = SimpleWallet(payable(wallet));

        // Deposit
        vm.prank(user1);
        clone.deposit{value: 1 ether}();

        // Try to withdraw as non-owner
        vm.prank(user2);
        vm.expectRevert("Not owner");
        clone.withdraw(1 ether);
    }

    function test_WalletWithdrawRevertsIfInsufficientBalance() public {
        vm.prank(user1);
        address wallet = factory.createWallet();

        SimpleWallet clone = SimpleWallet(payable(wallet));

        // Try to withdraw without balance
        vm.prank(user1);
        vm.expectRevert("Insufficient balance");
        clone.withdraw(1 ether);
    }

    function test_WalletInitializeRevertsIfAlreadyInitialized() public {
        vm.prank(user1);
        address wallet = factory.createWallet();

        SimpleWallet clone = SimpleWallet(payable(wallet));

        // Try to initialize again
        vm.expectRevert("Already initialized");
        clone.initialize(user2);

        // Owner should still be user1
        assertEq(clone.owner(), user1);
    }

    /*//////////////////////////////////////////////////////////////
                    CLONE INDEPENDENCE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ClonesHaveIndependentStorage() public {
        // Create two wallets
        vm.prank(user1);
        address wallet1 = factory.createWallet();

        vm.prank(user2);
        address wallet2 = factory.createWallet();

        SimpleWallet clone1 = SimpleWallet(payable(wallet1));
        SimpleWallet clone2 = SimpleWallet(payable(wallet2));

        // Each should have different owner
        assertEq(clone1.owner(), user1);
        assertEq(clone2.owner(), user2);

        // Deposit to wallet1
        vm.prank(user1);
        clone1.deposit{value: 5 ether}();

        // Deposit to wallet2
        vm.prank(user2);
        clone2.deposit{value: 3 ether}();

        // Each should have independent balance
        assertEq(clone1.balance(), 5 ether);
        assertEq(clone2.balance(), 3 ether);

        // Withdraw from wallet1
        vm.prank(user1);
        clone1.withdraw(2 ether);

        // Should not affect wallet2
        assertEq(clone1.balance(), 3 ether);
        assertEq(clone2.balance(), 3 ether);
    }

    function test_ImplementationStorageNotAffected() public {
        // Create clone
        vm.prank(user1);
        address wallet = factory.createWallet();

        SimpleWallet clone = SimpleWallet(payable(wallet));

        // Deposit to clone
        vm.prank(user1);
        clone.deposit{value: 10 ether}();

        // Implementation should not have any balance or owner
        assertEq(implementation.balance(), 0);
        assertEq(implementation.owner(), address(0));
        assertEq(address(implementation).balance, 0);
    }

    /*//////////////////////////////////////////////////////////////
                        GAS COMPARISON TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GasComparison_CloneVsDirect() public {
        // Deploy direct wallet
        uint256 gasBefore = gasleft();
        DirectWallet direct = new DirectWallet(user1);
        uint256 directGas = gasBefore - gasleft();

        // Deploy clone wallet
        vm.prank(user1);
        gasBefore = gasleft();
        address clone = factory.createWallet();
        uint256 cloneGas = gasBefore - gasleft();

        // Clone should use significantly less gas
        console.log("Direct deployment gas:", directGas);
        console.log("Clone deployment gas:", cloneGas);
        console.log("Gas saved:", directGas - cloneGas);
        console.log("Savings percentage:", ((directGas - cloneGas) * 100) / directGas);

        // Clone should save at least 50% gas
        assertTrue(cloneGas < directGas / 2, "Clone should save at least 50% gas");

        // Both should work the same
        assertTrue(address(direct) != address(0));
        assertTrue(clone != address(0));
    }

    function test_GasComparison_MultipleClones() public {
        // Deploy implementation once
        uint256 implGas;
        {
            uint256 gasBefore = gasleft();
            SimpleWallet impl = new SimpleWallet();
            implGas = gasBefore - gasleft();
            console.log("Implementation deployment gas:", implGas);
        }

        // Deploy 10 direct wallets
        uint256 totalDirectGas = 0;
        for (uint256 i = 0; i < 10; i++) {
            uint256 gasBefore = gasleft();
            new DirectWallet(address(uint160(i + 1)));
            totalDirectGas += gasBefore - gasleft();
        }
        console.log("10 direct deployments total gas:", totalDirectGas);
        console.log("Average per direct deployment:", totalDirectGas / 10);

        // Deploy 10 clones
        uint256 totalCloneGas = 0;
        for (uint256 i = 0; i < 10; i++) {
            vm.prank(address(uint160(100 + i)));
            uint256 gasBefore = gasleft();
            factory.createWallet();
            totalCloneGas += gasBefore - gasleft();
        }
        console.log("10 clone deployments total gas:", totalCloneGas);
        console.log("Average per clone deployment:", totalCloneGas / 10);

        // Total with implementation
        uint256 totalWithImpl = implGas + totalCloneGas;
        console.log("Total with implementation:", totalWithImpl);

        // Savings
        console.log("Gas saved:", totalDirectGas - totalWithImpl);
        console.log("Savings percentage:", ((totalDirectGas - totalWithImpl) * 100) / totalDirectGas);

        // Even with implementation cost, clones should save gas
        assertTrue(totalWithImpl < totalDirectGas, "Clones should save gas even with impl cost");
    }

    function test_GasComparison_DeterministicVsRegular() public {
        bytes32 salt = keccak256("test");

        // Regular clone
        vm.prank(user1);
        uint256 gasBefore = gasleft();
        factory.createWallet();
        uint256 regularGas = gasBefore - gasleft();

        // Deterministic clone
        vm.prank(user2);
        gasBefore = gasleft();
        factory.createDeterministicWallet(salt);
        uint256 deterministicGas = gasBefore - gasleft();

        console.log("Regular clone gas:", regularGas);
        console.log("Deterministic clone gas:", deterministicGas);
        console.log("Difference:", deterministicGas > regularGas ? deterministicGas - regularGas : regularGas - deterministicGas);

        // Deterministic should be slightly more expensive (CREATE2 vs CREATE)
        // But difference should be small (< 10%)
        assertTrue(
            deterministicGas < regularGas * 110 / 100,
            "Deterministic should be within 10% of regular"
        );
    }

    /*//////////////////////////////////////////////////////////////
                        HELPER FUNCTION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GetAllWallets() public {
        // Create 3 wallets
        vm.prank(user1);
        address wallet1 = factory.createWallet();

        vm.prank(user2);
        address wallet2 = factory.createWallet();

        bytes32 salt = keccak256("user3");
        vm.prank(address(0x4));
        address wallet3 = factory.createDeterministicWallet(salt);

        // Get all wallets
        address[] memory wallets = factory.getAllWallets();

        assertEq(wallets.length, 3);
        assertEq(wallets[0], wallet1);
        assertEq(wallets[1], wallet2);
        assertEq(wallets[2], wallet3);
    }

    function test_GetWalletAt() public {
        // Create wallets
        vm.prank(user1);
        address wallet1 = factory.createWallet();

        vm.prank(user2);
        address wallet2 = factory.createWallet();

        // Get by index
        assertEq(factory.getWalletAt(0), wallet1);
        assertEq(factory.getWalletAt(1), wallet2);

        // Out of bounds should revert
        vm.expectRevert("Index out of bounds");
        factory.getWalletAt(2);
    }

    function test_GetWalletCount() public {
        assertEq(factory.getWalletCount(), 0);

        vm.prank(user1);
        factory.createWallet();
        assertEq(factory.getWalletCount(), 1);

        vm.prank(user2);
        factory.createWallet();
        assertEq(factory.getWalletCount(), 2);

        bytes32 salt = keccak256("test");
        vm.prank(address(0x4));
        factory.createDeterministicWallet(salt);
        assertEq(factory.getWalletCount(), 3);
    }

    /*//////////////////////////////////////////////////////////////
                        FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzz_CreateWalletForAnyUser(address user) public {
        vm.assume(user != address(0));
        vm.assume(user.code.length == 0); // Not a contract

        vm.prank(user);
        address wallet = factory.createWallet();

        SimpleWallet clone = SimpleWallet(payable(wallet));
        assertEq(clone.owner(), user);
        assertTrue(clone.isInitialized());
    }

    function testFuzz_DepositAndWithdraw(uint96 depositAmount) public {
        vm.assume(depositAmount > 0);

        vm.prank(user1);
        address wallet = factory.createWallet();

        SimpleWallet clone = SimpleWallet(payable(wallet));

        // Deposit
        vm.deal(user2, depositAmount);
        vm.prank(user2);
        clone.deposit{value: depositAmount}();

        assertEq(clone.balance(), depositAmount);

        // Withdraw
        vm.prank(user1);
        clone.withdraw(depositAmount);

        assertEq(clone.balance(), 0);
        assertEq(user1.balance, depositAmount);
    }

    function testFuzz_DeterministicAddress(bytes32 salt) public {
        // Predict address
        address predicted = factory.predictWalletAddress(salt);

        // Create wallet
        vm.prank(user1);
        address wallet = factory.createDeterministicWallet(salt);

        // Should match
        assertEq(wallet, predicted);
    }

    /*//////////////////////////////////////////////////////////////
                        EDGE CASE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_CloneWithZeroEthBalance() public {
        vm.prank(user1);
        address wallet = factory.createWallet();

        SimpleWallet clone = SimpleWallet(payable(wallet));

        // Should have zero balance
        assertEq(clone.balance(), 0);
        assertEq(clone.getBalance(), 0);

        // Should still be able to receive ETH
        vm.prank(user2);
        clone.deposit{value: 1 ether}();
        assertEq(clone.balance(), 1 ether);
    }

    function test_MultipleDepositsAndWithdrawals() public {
        vm.prank(user1);
        address wallet = factory.createWallet();

        SimpleWallet clone = SimpleWallet(payable(wallet));

        // Multiple deposits
        vm.prank(user2);
        clone.deposit{value: 1 ether}();

        vm.prank(user2);
        clone.deposit{value: 2 ether}();

        vm.prank(user2);
        clone.deposit{value: 3 ether}();

        assertEq(clone.balance(), 6 ether);

        // Partial withdrawals
        vm.prank(user1);
        clone.withdraw(1 ether);
        assertEq(clone.balance(), 5 ether);

        vm.prank(user1);
        clone.withdraw(2 ether);
        assertEq(clone.balance(), 3 ether);

        vm.prank(user1);
        clone.withdraw(3 ether);
        assertEq(clone.balance(), 0);
    }

    function test_CloneCodeSize() public {
        vm.prank(user1);
        address wallet = factory.createWallet();

        // Clone should have minimal bytecode
        uint256 codeSize = wallet.code.length;
        console.log("Clone code size:", codeSize);

        // Should be exactly 45 bytes (EIP-1167 minimal proxy)
        assertEq(codeSize, 45, "Clone should be exactly 45 bytes");

        // Compare to implementation
        uint256 implCodeSize = address(implementation).code.length;
        console.log("Implementation code size:", implCodeSize);

        // Implementation should be much larger
        assertTrue(implCodeSize > codeSize * 10, "Implementation should be much larger");
    }
}
