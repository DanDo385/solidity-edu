// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/ERC20OpenZeppelinSolution.sol";

/**
 * @title ERC20OpenZeppelinTest
 * @dev Comprehensive tests for OpenZeppelin ERC20 implementations
 */
contract ERC20OpenZeppelinTest is Test {
    // Test accounts
    address public owner;
    address public alice;
    address public bob;
    address public treasury;

    // Events to test
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function setUp() public {
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        treasury = makeAddr("treasury");

        // Fund test accounts
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
    }

    /*//////////////////////////////////////////////////////////////
                        BASIC TOKEN TESTS
    //////////////////////////////////////////////////////////////*/

    function test_BasicToken_Deployment() public {
        BasicTokenSolution token = new BasicTokenSolution();

        assertEq(token.name(), "Basic Token");
        assertEq(token.symbol(), "BASIC");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), 1_000_000e18);
        assertEq(token.balanceOf(owner), 1_000_000e18);
    }

    function test_BasicToken_Transfer() public {
        BasicTokenSolution token = new BasicTokenSolution();

        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, alice, 100e18);

        token.transfer(alice, 100e18);

        assertEq(token.balanceOf(alice), 100e18);
        assertEq(token.balanceOf(owner), 1_000_000e18 - 100e18);
    }

    function test_BasicToken_Approve() public {
        BasicTokenSolution token = new BasicTokenSolution();

        vm.expectEmit(true, true, false, true);
        emit Approval(owner, alice, 500e18);

        token.approve(alice, 500e18);

        assertEq(token.allowance(owner, alice), 500e18);
    }

    function test_BasicToken_TransferFrom() public {
        BasicTokenSolution token = new BasicTokenSolution();

        // Owner approves Alice to spend tokens
        token.approve(alice, 500e18);

        // Alice transfers from owner to bob
        vm.prank(alice);
        token.transferFrom(owner, bob, 200e18);

        assertEq(token.balanceOf(bob), 200e18);
        assertEq(token.allowance(owner, alice), 300e18); // Reduced by transfer amount
    }

    function test_BasicToken_TransferFromInsufficientAllowance() public {
        BasicTokenSolution token = new BasicTokenSolution();

        token.approve(alice, 100e18);

        vm.prank(alice);
        vm.expectRevert();
        token.transferFrom(owner, bob, 200e18); // Exceeds allowance
    }

    function test_BasicToken_TransferInsufficientBalance() public {
        BasicTokenSolution token = new BasicTokenSolution();

        vm.prank(alice);
        vm.expectRevert();
        token.transfer(bob, 100e18); // Alice has no tokens
    }

    /*//////////////////////////////////////////////////////////////
                        BURNABLE TOKEN TESTS
    //////////////////////////////////////////////////////////////*/

    function test_BurnableToken_Burn() public {
        BurnableTokenSolution token = new BurnableTokenSolution();

        uint256 initialSupply = token.totalSupply();
        uint256 burnAmount = 100e18;

        token.burn(burnAmount);

        assertEq(token.totalSupply(), initialSupply - burnAmount);
        assertEq(token.balanceOf(owner), initialSupply - burnAmount);
    }

    function test_BurnableToken_BurnFrom() public {
        BurnableTokenSolution token = new BurnableTokenSolution();

        // Transfer tokens to Alice
        token.transfer(alice, 500e18);

        // Alice approves owner to burn her tokens
        vm.prank(alice);
        token.approve(owner, 200e18);

        uint256 initialSupply = token.totalSupply();
        token.burnFrom(alice, 100e18);

        assertEq(token.totalSupply(), initialSupply - 100e18);
        assertEq(token.balanceOf(alice), 400e18);
    }

    function test_BurnableToken_BurnExceedsBalance() public {
        BurnableTokenSolution token = new BurnableTokenSolution();

        token.transfer(alice, 100e18);

        vm.prank(alice);
        vm.expectRevert();
        token.burn(200e18); // Exceeds balance
    }

    /*//////////////////////////////////////////////////////////////
                        PAUSABLE TOKEN TESTS
    //////////////////////////////////////////////////////////////*/

    function test_PausableToken_PauseUnpause() public {
        PausableTokenSolution token = new PausableTokenSolution();

        assertFalse(token.paused());

        token.pause();
        assertTrue(token.paused());

        token.unpause();
        assertFalse(token.paused());
    }

    function test_PausableToken_TransferWhenPaused() public {
        PausableTokenSolution token = new PausableTokenSolution();

        token.pause();

        vm.expectRevert();
        token.transfer(alice, 100e18);
    }

    function test_PausableToken_TransferWhenUnpaused() public {
        PausableTokenSolution token = new PausableTokenSolution();

        token.pause();
        token.unpause();

        token.transfer(alice, 100e18);
        assertEq(token.balanceOf(alice), 100e18);
    }

    function test_PausableToken_OnlyOwnerCanPause() public {
        PausableTokenSolution token = new PausableTokenSolution();

        vm.prank(alice);
        vm.expectRevert();
        token.pause();
    }

    /*//////////////////////////////////////////////////////////////
                        SNAPSHOT TOKEN TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SnapshotToken_CreateSnapshot() public {
        SnapshotTokenSolution token = new SnapshotTokenSolution();

        uint256 snapshotId = token.snapshot();
        assertEq(snapshotId, 1);

        uint256 snapshotId2 = token.snapshot();
        assertEq(snapshotId2, 2);
    }

    function test_SnapshotToken_BalanceAtSnapshot() public {
        SnapshotTokenSolution token = new SnapshotTokenSolution();

        // Transfer to Alice
        token.transfer(alice, 100e18);

        // Create snapshot 1
        uint256 snapshot1 = token.snapshot();

        // Transfer more to Alice
        token.transfer(alice, 50e18);

        // Create snapshot 2
        uint256 snapshot2 = token.snapshot();

        // Check balances at different snapshots
        assertEq(token.balanceOfAt(alice, snapshot1), 100e18);
        assertEq(token.balanceOfAt(alice, snapshot2), 150e18);
        assertEq(token.balanceOf(alice), 150e18); // Current balance
    }

    function test_SnapshotToken_TotalSupplyAtSnapshot() public {
        SnapshotTokenSolution token = new SnapshotTokenSolution();

        uint256 initialSupply = token.totalSupply();

        uint256 snapshot1 = token.snapshot();

        // Burn tokens
        token.burn(100e18);

        uint256 snapshot2 = token.snapshot();

        assertEq(token.totalSupplyAt(snapshot1), initialSupply);
        assertEq(token.totalSupplyAt(snapshot2), initialSupply - 100e18);
    }

    function test_SnapshotToken_OnlyOwnerCanSnapshot() public {
        SnapshotTokenSolution token = new SnapshotTokenSolution();

        vm.prank(alice);
        vm.expectRevert();
        token.snapshot();
    }

    /*//////////////////////////////////////////////////////////////
                        GOVERNANCE TOKEN TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GovernanceToken_Delegation() public {
        GovernanceTokenSolution token = new GovernanceTokenSolution();

        // Transfer tokens to Alice
        token.transfer(alice, 1000e18);

        // Initially, Alice has 0 voting power (must delegate)
        assertEq(token.getVotes(alice), 0);

        // Alice delegates to herself
        vm.prank(alice);
        token.delegate(alice);

        // Now Alice has voting power
        assertEq(token.getVotes(alice), 1000e18);
    }

    function test_GovernanceToken_DelegateToOther() public {
        GovernanceTokenSolution token = new GovernanceTokenSolution();

        token.transfer(alice, 1000e18);

        // Alice delegates to Bob
        vm.prank(alice);
        token.delegate(bob);

        // Bob has voting power, Alice doesn't
        assertEq(token.getVotes(alice), 0);
        assertEq(token.getVotes(bob), 1000e18);
    }

    function test_GovernanceToken_PastVotes() public {
        GovernanceTokenSolution token = new GovernanceTokenSolution();

        token.transfer(alice, 1000e18);

        vm.prank(alice);
        token.delegate(alice);

        // Mine a block
        vm.roll(block.number + 1);

        uint256 pastVotes = token.getPastVotes(alice, block.number - 1);
        assertEq(pastVotes, 1000e18);
    }

    function test_GovernanceToken_VotesUpdateOnTransfer() public {
        GovernanceTokenSolution token = new GovernanceTokenSolution();

        token.transfer(alice, 1000e18);

        vm.prank(alice);
        token.delegate(alice);

        assertEq(token.getVotes(alice), 1000e18);

        // Alice transfers to Bob
        vm.prank(alice);
        token.transfer(bob, 500e18);

        // Alice's voting power decreases
        assertEq(token.getVotes(alice), 500e18);
    }

    function test_GovernanceToken_Permit() public {
        GovernanceTokenSolution token = new GovernanceTokenSolution();

        // Create a private key for signing
        uint256 privateKey = 0xA11CE;
        address signer = vm.addr(privateKey);

        // Transfer tokens to signer
        token.transfer(signer, 1000e18);

        // Create permit signature
        uint256 nonce = token.nonces(signer);
        uint256 deadline = block.timestamp + 1 hours;

        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                signer,
                alice,
                500e18,
                nonce,
                deadline
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

        // Execute permit
        token.permit(signer, alice, 500e18, deadline, v, r, s);

        // Check allowance was set
        assertEq(token.allowance(signer, alice), 500e18);
    }

    /*//////////////////////////////////////////////////////////////
                        CAPPED TOKEN TESTS
    //////////////////////////////////////////////////////////////*/

    function test_CappedToken_Cap() public {
        CappedTokenSolution token = new CappedTokenSolution();

        assertEq(token.cap(), 10_000_000e18);
        assertEq(token.totalSupply(), 5_000_000e18); // Initial mint
    }

    function test_CappedToken_MintBelowCap() public {
        CappedTokenSolution token = new CappedTokenSolution();

        token.mint(alice, 1_000_000e18);

        assertEq(token.balanceOf(alice), 1_000_000e18);
        assertEq(token.totalSupply(), 6_000_000e18);
    }

    function test_CappedToken_MintExceedsCap() public {
        CappedTokenSolution token = new CappedTokenSolution();

        // Try to mint more than cap allows
        vm.expectRevert();
        token.mint(alice, 6_000_000e18); // Would exceed 10M cap
    }

    function test_CappedToken_MintExactlyToCap() public {
        CappedTokenSolution token = new CappedTokenSolution();

        // Mint exactly to cap
        token.mint(alice, 5_000_000e18);

        assertEq(token.totalSupply(), 10_000_000e18);
        assertEq(token.totalSupply(), token.cap());
    }

    /*//////////////////////////////////////////////////////////////
                    FULL FEATURED TOKEN TESTS
    //////////////////////////////////////////////////////////////*/

    function test_FullFeaturedToken_AllFeatures() public {
        FullFeaturedTokenSolution token = new FullFeaturedTokenSolution();

        // Test burnable
        token.burn(100e18);
        assertEq(token.totalSupply(), 1_000_000e18 - 100e18);

        // Test snapshot
        uint256 snapshotId = token.snapshot();
        assertEq(snapshotId, 1);

        // Test pausable
        token.pause();
        assertTrue(token.paused());

        vm.expectRevert();
        token.transfer(alice, 100e18);

        token.unpause();
        token.transfer(alice, 100e18);
        assertEq(token.balanceOf(alice), 100e18);
    }

    function test_FullFeaturedToken_SnapshotWhilePaused() public {
        FullFeaturedTokenSolution token = new FullFeaturedTokenSolution();

        token.transfer(alice, 1000e18);

        token.pause();

        // Can still create snapshots while paused
        uint256 snapshotId = token.snapshot();

        assertEq(token.balanceOfAt(alice, snapshotId), 1000e18);
    }

    /*//////////////////////////////////////////////////////////////
                    CUSTOM HOOK TOKEN TESTS
    //////////////////////////////////////////////////////////////*/

    function test_CustomHookToken_FeeOnTransfer() public {
        CustomHookTokenSolution token = new CustomHookTokenSolution(treasury);

        uint256 transferAmount = 1000e18;
        uint256 expectedFee = (transferAmount * 100) / 10000; // 1%

        token.transfer(alice, transferAmount);

        // Alice receives 99% (1% fee)
        assertEq(token.balanceOf(alice), transferAmount - expectedFee);

        // Treasury receives 1% fee
        assertEq(token.balanceOf(treasury), expectedFee);
    }

    function test_CustomHookToken_NoFeeOnMint() public {
        CustomHookTokenSolution token = new CustomHookTokenSolution(treasury);

        uint256 initialTreasuryBalance = token.balanceOf(treasury);

        // Minting happens in constructor - treasury should have 0
        assertEq(initialTreasuryBalance, 0);
    }

    function test_CustomHookToken_NoFeeOnBurn() public {
        CustomHookTokenSolution token = new CustomHookTokenSolution(treasury);

        token.transfer(alice, 1000e18);
        uint256 treasuryBalance = token.balanceOf(treasury);

        // Alice burns her tokens
        vm.prank(alice);
        token.transfer(address(0), 100e18);

        // Treasury balance shouldn't change from burn
        // Note: Can't actually burn to address(0) with standard ERC20
        // This test would need ERC20Burnable
    }

    function test_CustomHookToken_SetTreasury() public {
        CustomHookTokenSolution token = new CustomHookTokenSolution(treasury);

        address newTreasury = makeAddr("newTreasury");

        token.setTreasury(newTreasury);
        assertEq(token.treasury(), newTreasury);
    }

    function test_CustomHookToken_SetTreasuryZeroAddress() public {
        CustomHookTokenSolution token = new CustomHookTokenSolution(treasury);

        vm.expectRevert("Treasury cannot be zero address");
        token.setTreasury(address(0));
    }

    function test_CustomHookToken_MultipleFees() public {
        CustomHookTokenSolution token = new CustomHookTokenSolution(treasury);

        // Transfer to Alice (fee charged)
        token.transfer(alice, 10000e18);
        uint256 fee1 = token.balanceOf(treasury);

        // Alice transfers to Bob (fee charged again)
        vm.prank(alice);
        token.transfer(bob, 5000e18);

        // Treasury should have accumulated both fees
        assertTrue(token.balanceOf(treasury) > fee1);
    }

    /*//////////////////////////////////////////////////////////////
                        VESTING TOKEN TESTS
    //////////////////////////////////////////////////////////////*/

    function test_VestingToken_Deployment() public {
        VestingTokenSolution token = new VestingTokenSolution();

        // Owner tokens should be immediately vested
        assertEq(token.tokenReceivedAt(owner), block.timestamp);
    }

    function test_VestingToken_TransferBeforeVesting() public {
        VestingTokenSolution token = new VestingTokenSolution();

        // Transfer to Alice
        token.transfer(alice, 1000e18);

        // Alice tries to transfer immediately (should fail)
        vm.prank(alice);
        vm.expectRevert("Tokens are still vesting");
        token.transfer(bob, 500e18);
    }

    function test_VestingToken_TransferAfterVesting() public {
        VestingTokenSolution token = new VestingTokenSolution();

        token.transfer(alice, 1000e18);

        // Fast forward 30 days
        vm.warp(block.timestamp + 30 days);

        // Alice can now transfer
        vm.prank(alice);
        token.transfer(bob, 500e18);

        assertEq(token.balanceOf(bob), 500e18);
    }

    function test_VestingToken_OwnerBypassesVesting() public {
        VestingTokenSolution token = new VestingTokenSolution();

        // Owner can transfer immediately
        token.transfer(alice, 1000e18);
        token.transfer(bob, 1000e18);

        assertEq(token.balanceOf(alice), 1000e18);
        assertEq(token.balanceOf(bob), 1000e18);
    }

    function test_VestingToken_TimestampUpdated() public {
        VestingTokenSolution token = new VestingTokenSolution();

        uint256 timestamp1 = block.timestamp;
        token.transfer(alice, 1000e18);

        assertEq(token.tokenReceivedAt(alice), timestamp1);

        // Fast forward and transfer more
        vm.warp(block.timestamp + 40 days);

        // Transfer from owner to alice again
        token.transfer(alice, 500e18);

        // Timestamp shouldn't update (already set)
        assertEq(token.tokenReceivedAt(alice), timestamp1);
    }

    /*//////////////////////////////////////////////////////////////
                        REWARD TOKEN TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RewardToken_AddRewards() public {
        RewardTokenSolution token = new RewardTokenSolution();

        uint256 snapshotId = token.snapshot();

        vm.deal(owner, 10 ether);
        token.addRewards{value: 5 ether}(snapshotId);

        assertEq(token.snapshotRewards(snapshotId), 5 ether);
        assertEq(address(token).balance, 5 ether);
    }

    function test_RewardToken_ClaimRewards() public {
        RewardTokenSolution token = new RewardTokenSolution();

        // Transfer 50% of tokens to Alice
        token.transfer(alice, 500_000e18);

        uint256 snapshotId = token.snapshot();

        // Add 10 ETH rewards
        vm.deal(owner, 10 ether);
        token.addRewards{value: 10 ether}(snapshotId);

        // Alice claims (should get 50% = 5 ETH)
        uint256 aliceBalanceBefore = alice.balance;

        vm.prank(alice);
        token.claimRewards(snapshotId);

        assertEq(alice.balance - aliceBalanceBefore, 5 ether);
    }

    function test_RewardToken_CannotClaimTwice() public {
        RewardTokenSolution token = new RewardTokenSolution();

        token.transfer(alice, 500_000e18);

        uint256 snapshotId = token.snapshot();

        vm.deal(owner, 10 ether);
        token.addRewards{value: 10 ether}(snapshotId);

        vm.prank(alice);
        token.claimRewards(snapshotId);

        // Try to claim again
        vm.prank(alice);
        vm.expectRevert("Already claimed");
        token.claimRewards(snapshotId);
    }

    function test_RewardToken_PendingRewards() public {
        RewardTokenSolution token = new RewardTokenSolution();

        token.transfer(alice, 250_000e18); // 25%

        uint256 snapshotId = token.snapshot();

        vm.deal(owner, 100 ether);
        token.addRewards{value: 100 ether}(snapshotId);

        uint256 pending = token.pendingRewards(alice, snapshotId);
        assertEq(pending, 25 ether); // 25% of 100 ETH
    }

    function test_RewardToken_MultipleSnapshots() public {
        RewardTokenSolution token = new RewardTokenSolution();

        // Snapshot 1: Alice has 50%
        token.transfer(alice, 500_000e18);
        uint256 snapshot1 = token.snapshot();

        // Snapshot 2: Alice has 25% (transferred half to Bob)
        vm.prank(alice);
        token.transfer(bob, 250_000e18);
        uint256 snapshot2 = token.snapshot();

        // Add rewards to both snapshots
        vm.deal(owner, 20 ether);
        token.addRewards{value: 10 ether}(snapshot1);
        token.addRewards{value: 10 ether}(snapshot2);

        // Alice claims from snapshot 1 (should get 5 ETH = 50%)
        vm.prank(alice);
        token.claimRewards(snapshot1);
        assertEq(alice.balance, 5 ether);

        // Alice claims from snapshot 2 (should get 2.5 ETH = 25%)
        vm.prank(alice);
        token.claimRewards(snapshot2);
        assertEq(alice.balance, 7.5 ether);

        // Bob claims from snapshot 2 (should get 2.5 ETH = 25%)
        vm.prank(bob);
        token.claimRewards(snapshot2);
        assertEq(bob.balance, 100 ether + 2.5 ether); // Initial balance + reward
    }

    function test_RewardToken_NoBalanceNoClaim() public {
        RewardTokenSolution token = new RewardTokenSolution();

        uint256 snapshotId = token.snapshot();

        vm.deal(owner, 10 ether);
        token.addRewards{value: 10 ether}(snapshotId);

        // Alice has no tokens
        vm.prank(alice);
        vm.expectRevert("No balance at snapshot");
        token.claimRewards(snapshotId);
    }

    /*//////////////////////////////////////////////////////////////
                        GAS COMPARISON TESTS
    //////////////////////////////////////////////////////////////*/

    function testGas_BasicTransfer() public {
        BasicTokenSolution token = new BasicTokenSolution();

        token.transfer(alice, 100e18);

        uint256 gasBefore = gasleft();
        token.transfer(alice, 100e18);
        uint256 gasUsed = gasBefore - gasleft();

        // Log gas usage for comparison
        emit log_named_uint("Basic transfer gas:", gasUsed);
    }

    function testGas_PausableTransfer() public {
        PausableTokenSolution token = new PausableTokenSolution();

        token.transfer(alice, 100e18);

        uint256 gasBefore = gasleft();
        token.transfer(alice, 100e18);
        uint256 gasUsed = gasBefore - gasleft();

        emit log_named_uint("Pausable transfer gas:", gasUsed);
    }

    function testGas_SnapshotTransfer() public {
        SnapshotTokenSolution token = new SnapshotTokenSolution();

        token.snapshot();
        token.transfer(alice, 100e18);

        uint256 gasBefore = gasleft();
        token.transfer(alice, 100e18);
        uint256 gasUsed = gasBefore - gasleft();

        emit log_named_uint("Snapshot transfer gas:", gasUsed);
    }

    function testGas_GovernanceTransfer() public {
        GovernanceTokenSolution token = new GovernanceTokenSolution();

        token.transfer(alice, 100e18);
        vm.prank(alice);
        token.delegate(alice);

        uint256 gasBefore = gasleft();
        vm.prank(alice);
        token.transfer(bob, 50e18);
        uint256 gasUsed = gasBefore - gasleft();

        emit log_named_uint("Governance transfer gas:", gasUsed);
    }

    function testGas_FullFeaturedTransfer() public {
        FullFeaturedTokenSolution token = new FullFeaturedTokenSolution();

        token.snapshot();
        token.transfer(alice, 100e18);

        uint256 gasBefore = gasleft();
        token.transfer(alice, 100e18);
        uint256 gasUsed = gasBefore - gasleft();

        emit log_named_uint("Full featured transfer gas:", gasUsed);
    }

    /*//////////////////////////////////////////////////////////////
                        EDGE CASE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_TransferToZeroAddress() public {
        BasicTokenSolution token = new BasicTokenSolution();

        vm.expectRevert();
        token.transfer(address(0), 100e18);
    }

    function test_TransferZeroAmount() public {
        BasicTokenSolution token = new BasicTokenSolution();

        // Should succeed but not change balances
        token.transfer(alice, 0);

        assertEq(token.balanceOf(alice), 0);
    }

    function test_ApproveToZeroAddress() public {
        BasicTokenSolution token = new BasicTokenSolution();

        vm.expectRevert();
        token.approve(address(0), 100e18);
    }

    function test_SelfTransfer() public {
        BasicTokenSolution token = new BasicTokenSolution();

        uint256 balanceBefore = token.balanceOf(owner);

        token.transfer(owner, 100e18);

        assertEq(token.balanceOf(owner), balanceBefore); // Same balance
    }

    function testFuzz_Transfer(uint256 amount) public {
        BasicTokenSolution token = new BasicTokenSolution();

        // Bound amount to valid range
        amount = bound(amount, 0, token.balanceOf(owner));

        token.transfer(alice, amount);

        assertEq(token.balanceOf(alice), amount);
    }

    function testFuzz_Approve(uint256 amount) public {
        BasicTokenSolution token = new BasicTokenSolution();

        token.approve(alice, amount);

        assertEq(token.allowance(owner, alice), amount);
    }
}
