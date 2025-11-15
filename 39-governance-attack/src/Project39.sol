// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Project 39: Governance Attack Simulation
 * @notice Educational project demonstrating DAO governance vulnerabilities
 * @dev THIS IS FOR LEARNING PURPOSES - Contains intentional vulnerabilities
 *
 * LEARNING OBJECTIVES:
 * 1. Understand flashloan governance attacks
 * 2. Explore vote buying and delegation exploits
 * 3. Learn quorum manipulation techniques
 * 4. Study defensive governance patterns
 */

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title GovernanceToken
 * @notice Simple ERC20 token with delegation capability
 */
contract GovernanceToken is ERC20 {
    mapping(address => address) public delegates;
    mapping(address => uint256) public numCheckpoints;
    mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;

    struct Checkpoint {
        uint256 fromBlock;
        uint256 votes;
    }

    constructor() ERC20("Governance Token", "GOV") {
        _mint(msg.sender, 1_000_000 * 1e18);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    /**
     * @notice Delegate votes to another address
     * TODO: Implement delegation
     * HINTS:
     * - Store the delegate address
     * - Update voting power checkpoints
     * - Consider delegation chains
     */
    function delegate(address delegatee) external {
        // TODO: Implement delegation logic
        // Consider:
        // - What happens if user already has a delegate?
        // - Should there be a cooldown period?
        // - How to prevent delegation loops?
    }

    /**
     * @notice Get current voting power of an address
     * TODO: Implement voting power calculation
     * HINTS:
     * - Include delegated votes
     * - Should this use current balance or snapshot?
     */
    function getVotes(address account) external view returns (uint256) {
        // TODO: Calculate total voting power
        // Include: own balance + delegated votes
        return 0;
    }

    /**
     * @notice Get voting power at a specific block
     * TODO: Implement historical voting power lookup
     * SECURITY: This prevents flashloan attacks!
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256) {
        // TODO: Implement checkpoint lookup
        // This is crucial for preventing flashloan attacks
        return 0;
    }
}

/**
 * @title VulnerableDAO
 * @notice DAO with multiple governance vulnerabilities
 * @dev INTENTIONALLY VULNERABLE - For educational purposes only
 */
contract VulnerableDAO {
    GovernanceToken public governanceToken;

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 startBlock;
        uint256 endBlock;
        bool executed;
        bool canceled;
        address target;
        bytes data;
        uint256 value;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    uint256 public proposalCount;

    // Governance parameters
    uint256 public votingPeriod = 100; // blocks
    uint256 public votingDelay = 10; // blocks
    uint256 public proposalThreshold = 1000 * 1e18; // tokens needed to propose
    uint256 public quorumVotes = 100_000 * 1e18; // votes needed for quorum

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(address indexed voter, uint256 indexed proposalId, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);

    constructor(address _governanceToken) {
        governanceToken = GovernanceToken(_governanceToken);
    }

    /**
     * @notice Create a new proposal
     * VULNERABILITY: Uses current balance, not historical snapshot!
     * TODO: Identify the vulnerability
     */
    function propose(
        address target,
        uint256 value,
        bytes memory data,
        string memory description
    ) external returns (uint256) {
        // VULNERABILITY: Uses current balance instead of snapshot
        // Attacker can flashloan tokens to meet threshold
        require(
            governanceToken.balanceOf(msg.sender) >= proposalThreshold,
            "Below proposal threshold"
        );

        uint256 proposalId = proposalCount++;

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: description,
            forVotes: 0,
            againstVotes: 0,
            startBlock: block.number + votingDelay,
            endBlock: block.number + votingDelay + votingPeriod,
            executed: false,
            canceled: false,
            target: target,
            data: data,
            value: value
        });

        emit ProposalCreated(proposalId, msg.sender, description);
        return proposalId;
    }

    /**
     * @notice Cast a vote on a proposal
     * VULNERABILITY: Uses current balance for voting power!
     * TODO: Implement voting with flashloan protection
     * HINTS:
     * - Currently uses balanceOf (flashloan vulnerable)
     * - Should use snapshot voting power
     * - Consider delegation
     */
    function castVote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        require(block.number >= proposal.startBlock, "Voting not started");
        require(block.number <= proposal.endBlock, "Voting ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted");

        // CRITICAL VULNERABILITY: Uses current balance!
        // Attacker can flashloan tokens, vote, and return them
        uint256 votes = governanceToken.balanceOf(msg.sender);

        // TODO: Fix this vulnerability
        // Should use: governanceToken.getPastVotes(msg.sender, proposal.startBlock)

        hasVoted[proposalId][msg.sender] = true;

        if (support) {
            proposal.forVotes += votes;
        } else {
            proposal.againstVotes += votes;
        }

        emit VoteCast(msg.sender, proposalId, support, votes);
    }

    /**
     * @notice Execute a passed proposal
     * VULNERABILITY: No timelock delay!
     * TODO: Add timelock protection
     */
    function execute(uint256 proposalId) external payable {
        Proposal storage proposal = proposals[proposalId];
        require(block.number > proposal.endBlock, "Voting not ended");
        require(!proposal.executed, "Already executed");
        require(!proposal.canceled, "Proposal canceled");

        // Check if proposal passed
        require(proposal.forVotes > proposal.againstVotes, "Proposal failed");
        require(proposal.forVotes >= quorumVotes, "Quorum not reached");

        // VULNERABILITY: No timelock! Executes immediately
        // Community has no time to react to malicious proposals
        proposal.executed = true;

        // TODO: Add timelock delay here
        // Should wait 24-48 hours before execution

        // Execute the proposal
        (bool success, ) = proposal.target.call{value: proposal.value}(proposal.data);
        require(success, "Execution failed");

        emit ProposalExecuted(proposalId);
    }

    /**
     * @notice Check if proposal has reached quorum
     */
    function hasReachedQuorum(uint256 proposalId) external view returns (bool) {
        Proposal storage proposal = proposals[proposalId];
        return (proposal.forVotes + proposal.againstVotes) >= quorumVotes;
    }

    /**
     * @notice Get proposal state
     */
    function state(uint256 proposalId) external view returns (string memory) {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.canceled) return "Canceled";
        if (proposal.executed) return "Executed";
        if (block.number <= proposal.startBlock) return "Pending";
        if (block.number <= proposal.endBlock) return "Active";
        if (proposal.forVotes <= proposal.againstVotes) return "Defeated";
        if (proposal.forVotes < quorumVotes) return "Quorum Not Reached";
        return "Succeeded";
    }

    receive() external payable {}
}

/**
 * @title SimpleFlashloanProvider
 * @notice Provides flashloans for testing governance attacks
 */
contract SimpleFlashloanProvider {
    GovernanceToken public token;

    event FlashloanExecuted(address indexed borrower, uint256 amount);

    constructor(address _token) {
        token = GovernanceToken(_token);
    }

    function depositTokens(uint256 amount) external {
        token.transferFrom(msg.sender, address(this), amount);
    }

    /**
     * @notice Execute a flashloan
     * @param amount Amount to borrow
     * @param target Contract to call with borrowed tokens
     * @param data Calldata for the target
     */
    function flashloan(uint256 amount, address target, bytes calldata data) external {
        uint256 balanceBefore = token.balanceOf(address(this));
        require(balanceBefore >= amount, "Insufficient liquidity");

        // Transfer tokens to borrower
        token.transfer(msg.sender, amount);

        // Execute borrower's code
        (bool success, ) = target.call(data);
        require(success, "Flashloan callback failed");

        // Verify tokens were returned
        uint256 balanceAfter = token.balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "Flashloan not repaid");

        emit FlashloanExecuted(msg.sender, amount);
    }
}

/**
 * @title FlashloanGovernanceAttacker
 * @notice Demonstrates flashloan governance attack
 * TODO: Complete the attack implementation
 *
 * ATTACK FLOW:
 * 1. Create malicious proposal (or wait for existing proposal)
 * 2. Take flashloan of governance tokens
 * 3. Use tokens to vote on proposal
 * 4. Return flashloan
 * 5. Wait for proposal to execute
 */
contract FlashloanGovernanceAttacker {
    VulnerableDAO public dao;
    SimpleFlashloanProvider public flashloanProvider;
    GovernanceToken public token;

    uint256 public targetProposalId;
    bool public supportProposal;

    constructor(address _dao, address _flashloanProvider, address _token) {
        dao = VulnerableDAO(_dao);
        flashloanProvider = SimpleFlashloanProvider(_flashloanProvider);
        token = GovernanceToken(_token);
    }

    /**
     * @notice Execute flashloan governance attack
     * TODO: Implement the attack
     * HINTS:
     * - Use flashloan to borrow massive amount of tokens
     * - Vote with borrowed tokens
     * - Return tokens in same transaction
     * - Proposal will execute later with your votes counted!
     */
    function attack(uint256 proposalId, bool support) external {
        targetProposalId = proposalId;
        supportProposal = support;

        // TODO: Implement attack
        // 1. Calculate how many tokens needed to pass proposal
        // 2. Request flashloan of that amount
        // 3. In callback, vote on proposal
        // 4. Return tokens
        //
        // The vote will be counted even though we don't own the tokens anymore!
    }

    /**
     * @notice Flashloan callback
     * TODO: Implement voting logic here
     */
    function onFlashloan(uint256 amount) external {
        // TODO: This is called by flashloan provider
        // 1. Verify we received the tokens
        // 2. Cast vote on proposal
        // 3. Approve tokens back to flashloan provider
        // 4. Return (flashloan provider will pull tokens back)
    }
}

/**
 * @title MaliciousTreasury
 * @notice Contract that can be targeted by malicious proposals
 */
contract MaliciousTreasury {
    event TreasuryDrained(address indexed attacker, uint256 amount);

    receive() external payable {}

    /**
     * @notice Function that could be called by malicious proposal
     */
    function drainFunds(address payable recipient) external {
        uint256 balance = address(this).balance;
        recipient.transfer(balance);
        emit TreasuryDrained(recipient, balance);
    }
}

/**
 * @title SafeDAO
 * @notice DAO with proper security measures
 * TODO: Implement defensive patterns
 *
 * SECURITY FEATURES TO IMPLEMENT:
 * 1. Snapshot voting (use getPastVotes)
 * 2. Timelock delay before execution
 * 3. Guardian/multisig veto power
 * 4. Higher quorum for critical proposals
 * 5. Proposal value limits
 */
contract SafeDAO {
    GovernanceToken public governanceToken;

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 snapshotBlock; // SECURITY: Snapshot for voting power
        uint256 startBlock;
        uint256 endBlock;
        uint256 eta; // SECURITY: Timelock execution time
        bool executed;
        bool canceled;
        bool vetoed; // SECURITY: Guardian can veto
        address target;
        bytes data;
        uint256 value;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    uint256 public proposalCount;

    // SECURITY: Governance parameters
    uint256 public votingPeriod = 100;
    uint256 public votingDelay = 10;
    uint256 public proposalThreshold = 10_000 * 1e18; // Higher threshold
    uint256 public quorumVotes = 200_000 * 1e18; // Higher quorum
    uint256 public timelockPeriod = 172800; // 2 days in seconds
    address public guardian; // Multisig that can veto

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer);
    event VoteCast(address indexed voter, uint256 indexed proposalId, bool support, uint256 votes);
    event ProposalQueued(uint256 indexed proposalId, uint256 eta);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalVetoed(uint256 indexed proposalId);

    constructor(address _governanceToken, address _guardian) {
        governanceToken = GovernanceToken(_governanceToken);
        guardian = _guardian;
    }

    /**
     * @notice Create a proposal with snapshot
     * TODO: Implement secure proposal creation
     */
    function propose(
        address target,
        uint256 value,
        bytes memory data,
        string memory description
    ) external returns (uint256) {
        // TODO: Implement with snapshot voting
        // Use getPastVotes instead of balanceOf
        return 0;
    }

    /**
     * @notice Cast vote using snapshot
     * TODO: Implement secure voting
     * SECURITY: Use snapshot voting power, not current balance
     */
    function castVote(uint256 proposalId, bool support) external {
        // TODO: Use getPastVotes(msg.sender, proposal.snapshotBlock)
        // This prevents flashloan attacks!
    }

    /**
     * @notice Queue proposal for execution after timelock
     * TODO: Implement timelock queue
     */
    function queue(uint256 proposalId) external {
        // TODO: Set execution time in future (eta)
        // This gives community time to react
    }

    /**
     * @notice Execute proposal after timelock
     * TODO: Implement timelock execution
     */
    function execute(uint256 proposalId) external payable {
        // TODO: Verify timelock period has passed
        // Check: block.timestamp >= proposal.eta
    }

    /**
     * @notice Guardian can veto malicious proposals
     * TODO: Implement veto mechanism
     */
    function veto(uint256 proposalId) external {
        // TODO: Only guardian can call
        // Mark proposal as vetoed
    }

    receive() external payable {}
}

/*
 * CHALLENGES:
 *
 * 1. FLASHLOAN ATTACK:
 *    - Complete FlashloanGovernanceAttacker
 *    - Borrow tokens, vote, return tokens
 *    - Verify vote is still counted
 *
 * 2. VOTE BUYING:
 *    - Implement delegation attack
 *    - Accumulate delegated votes
 *    - Pass proposal with delegated power
 *
 * 3. QUORUM MANIPULATION:
 *    - Create proposal when participation is low
 *    - Use minimal tokens to reach quorum
 *    - Demonstrate the vulnerability
 *
 * 4. IMPLEMENT SAFE DAO:
 *    - Complete SafeDAO contract
 *    - Use snapshot voting
 *    - Add timelock
 *    - Implement guardian veto
 *
 * 5. TEST DEFENSES:
 *    - Verify flashloan attack fails against SafeDAO
 *    - Test timelock delay
 *    - Verify guardian can veto
 *
 * SECURITY CONSIDERATIONS:
 * - This is educational code with intentional vulnerabilities
 * - Never deploy vulnerable contracts to mainnet
 * - Real governance requires comprehensive audits
 * - Consider economic and social attack vectors too
 */
