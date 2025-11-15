// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";

/**
 * @title DeFi Protocol Capstone - Skeleton
 * @notice Complete the TODOs to build a full-featured DeFi protocol
 * @dev This integrates: ERC20, ERC721, ERC4626, Governance, Oracles, Flash Loans
 */

// ============================================================================
// PROTOCOL TOKEN (ERC20)
// ============================================================================

/**
 * @title ProtocolToken
 * @notice The governance and utility token of the protocol
 */
contract ProtocolToken is
    Initializable,
    ERC20Upgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 1e18; // 1 billion tokens

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address admin) public initializer {
        __ERC20_init("Protocol Token", "PROTO");
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);
    }

    // TODO: Implement mint function with MAX_SUPPLY check
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        // TODO: Check that total supply + amount <= MAX_SUPPLY
        // TODO: Mint tokens to the address
    }

    // TODO: Implement burn function
    function burn(uint256 amount) public {
        // TODO: Burn tokens from msg.sender
    }

    // TODO: Implement pause/unpause functions
    function pause() public onlyRole(PAUSER_ROLE) {
        // TODO: Pause the contract
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        // TODO: Unpause the contract
    }

    // TODO: Override _beforeTokenTransfer to respect pause
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}
}

// ============================================================================
// NFT MEMBERSHIP SYSTEM (ERC721)
// ============================================================================

/**
 * @title NFTMembership
 * @notice Tiered NFT membership providing benefits and governance weight
 */
contract NFTMembership is
    Initializable,
    ERC721Upgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    enum Tier {
        BRONZE,   // 5% discount, 1x voting
        SILVER,   // 10% discount, 2x voting
        GOLD,     // 25% discount, 5x voting
        PLATINUM  // 50% discount, 10x voting
    }

    struct Membership {
        Tier tier;
        uint256 mintedAt;
        uint256 stakingBoost;
    }

    IERC20 public protocolToken;
    uint256 private _nextTokenId;

    // Tier pricing in PROTO tokens
    mapping(Tier => uint256) public tierPrices;

    // Tier supply limits
    mapping(Tier => uint256) public tierMaxSupply;
    mapping(Tier => uint256) public tierMinted;

    // Token ID to membership data
    mapping(uint256 => Membership) public memberships;

    // User to token ID (one NFT per user)
    mapping(address => uint256) public userNFT;

    event MembershipMinted(address indexed user, uint256 indexed tokenId, Tier tier);
    event MembershipUpgraded(uint256 indexed tokenId, Tier oldTier, Tier newTier);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address admin, address _protocolToken) public initializer {
        __ERC721_init("DeFi Protocol Membership", "DPM");
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);

        protocolToken = IERC20(_protocolToken);

        // TODO: Set tier prices
        // BRONZE: 100 PROTO, SILVER: 1000 PROTO, GOLD: 10000 PROTO, PLATINUM: 100000 PROTO

        // TODO: Set tier max supplies
        // PLATINUM limited to 100
    }

    // TODO: Implement mintMembership function
    function mintMembership(Tier tier) external returns (uint256) {
        // TODO: Check user doesn't already have an NFT
        // TODO: Check tier supply limits
        // TODO: Calculate price based on tier
        // TODO: Transfer PROTO tokens from user to contract (burn them)
        // TODO: Mint NFT to user
        // TODO: Record membership data
        // TODO: Emit event
        // TODO: Return token ID
    }

    // TODO: Implement upgradeMembership function
    function upgradeMembership(uint256 tokenId, Tier newTier) external {
        // TODO: Check msg.sender owns the NFT
        // TODO: Check newTier is higher than current tier
        // TODO: Calculate upgrade cost (difference in tier prices)
        // TODO: Transfer PROTO tokens
        // TODO: Update membership tier
        // TODO: Emit event
    }

    // TODO: Implement helper functions
    function getTier(uint256 tokenId) public view returns (Tier) {
        // TODO: Return the tier of a token ID
    }

    function getVotingMultiplier(address user) public view returns (uint256) {
        // TODO: Return voting multiplier based on NFT tier
        // No NFT: 1x, BRONZE: 1x, SILVER: 2x, GOLD: 5x, PLATINUM: 10x
    }

    function getFeeDiscount(address user) public view returns (uint256) {
        // TODO: Return fee discount percentage (in basis points)
        // No NFT: 0, BRONZE: 500 (5%), SILVER: 1000 (10%), GOLD: 2500 (25%), PLATINUM: 5000 (50%)
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}
}

// ============================================================================
// ORACLE SYSTEM
// ============================================================================

/**
 * @title PriceOracle
 * @notice Aggregates price feeds with fallback mechanisms
 */
contract PriceOracle is Initializable, AccessControlUpgradeable {
    bytes32 public constant ORACLE_ADMIN_ROLE = keccak256("ORACLE_ADMIN_ROLE");

    struct PriceFeed {
        address source;
        uint256 heartbeat; // Max staleness
        bool isActive;
    }

    // Asset => Price feed
    mapping(address => PriceFeed) public priceFeeds;

    // Price deviation threshold (10%)
    uint256 public constant MAX_DEVIATION = 1000; // 10% in basis points

    event PriceFeedUpdated(address indexed asset, address indexed source, uint256 heartbeat);
    event PriceReported(address indexed asset, uint256 price, uint256 timestamp);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address admin) public initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ORACLE_ADMIN_ROLE, admin);
    }

    // TODO: Implement price feed management
    function setPriceFeed(
        address asset,
        address source,
        uint256 heartbeat
    ) external onlyRole(ORACLE_ADMIN_ROLE) {
        // TODO: Set the price feed for an asset
    }

    // TODO: Implement getPrice with staleness check
    function getPrice(address asset) external view returns (uint256) {
        // TODO: Get price from the source
        // TODO: Check staleness (block.timestamp - lastUpdate <= heartbeat)
        // TODO: Return price
    }

    // TODO: Implement price validation
    function validatePrice(address asset, uint256 proposedPrice) external view returns (bool) {
        // TODO: Get current price
        // TODO: Check deviation is within MAX_DEVIATION
        // TODO: Return true if valid
    }
}

// ============================================================================
// GOVERNANCE SYSTEM
// ============================================================================

/**
 * @title Governance
 * @notice On-chain governance with NFT-weighted voting
 */
contract Governance is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    struct Proposal {
        uint256 id;
        address proposer;
        address[] targets;
        uint256[] values;
        bytes[] calldatas;
        string description;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        bool executed;
        bool canceled;
        mapping(address => bool) hasVoted;
    }

    IERC20 public protocolToken;
    NFTMembership public nftMembership;

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;

    // Governance parameters
    uint256 public proposalThreshold; // Tokens needed to propose
    uint256 public quorumPercentage; // % of supply needed
    uint256 public votingDelay; // Blocks before voting starts
    uint256 public votingPeriod; // Blocks voting is open
    uint256 public timelockDelay; // Seconds before execution

    // Proposal queue
    mapping(uint256 => uint256) public proposalEta; // Execution time

    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        address[] targets,
        string description
    );
    event VoteCast(address indexed voter, uint256 indexed proposalId, uint8 support, uint256 weight);
    event ProposalQueued(uint256 indexed proposalId, uint256 eta);
    event ProposalExecuted(uint256 indexed proposalId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address admin,
        address _protocolToken,
        address _nftMembership
    ) public initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(EXECUTOR_ROLE, admin);

        protocolToken = IERC20(_protocolToken);
        nftMembership = NFTMembership(_nftMembership);

        // TODO: Set initial governance parameters
        proposalThreshold = 100_000 * 1e18; // 100k tokens
        quorumPercentage = 4; // 4%
        votingDelay = 1; // ~1 block
        votingPeriod = 50400; // ~7 days
        timelockDelay = 2 days;
    }

    // TODO: Implement propose function
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256) {
        // TODO: Check proposer has enough tokens OR gold+ NFT
        // TODO: Validate inputs (same length arrays)
        // TODO: Create proposal
        // TODO: Set start and end blocks
        // TODO: Emit event
        // TODO: Return proposal ID
    }

    // TODO: Implement castVote function
    function castVote(uint256 proposalId, uint8 support) external {
        // TODO: Check proposal is active
        // TODO: Check user hasn't voted
        // TODO: Calculate voting weight (tokens * NFT multiplier)
        // TODO: Record vote
        // TODO: Update vote counts
        // TODO: Emit event
    }

    // TODO: Implement queue function
    function queue(uint256 proposalId) external {
        // TODO: Check proposal succeeded
        // TODO: Set ETA (now + timelock delay)
        // TODO: Update state
        // TODO: Emit event
    }

    // TODO: Implement execute function
    function execute(uint256 proposalId) external nonReentrant onlyRole(EXECUTOR_ROLE) {
        // TODO: Check proposal is queued and ready
        // TODO: Check ETA has passed
        // TODO: Execute all calls
        // TODO: Mark as executed
        // TODO: Emit event
    }

    // TODO: Implement helper functions
    function state(uint256 proposalId) public view returns (ProposalState) {
        // TODO: Return current state of proposal
    }

    function getVotes(address account) public view returns (uint256) {
        // TODO: Get token balance
        // TODO: Apply NFT multiplier
        // TODO: Return total voting power
    }

    function quorum() public view returns (uint256) {
        // TODO: Calculate quorum based on total supply
    }
}

// ============================================================================
// VAULT (ERC4626) WITH FLASH LOANS
// ============================================================================

/**
 * @title DeFiVault
 * @notice ERC4626 vault with yield strategies and flash loan capability
 */
contract DeFiVault is
    Initializable,
    ERC4626Upgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IERC3156FlashLender
{
    using SafeERC20 for IERC20;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant STRATEGIST_ROLE = keccak256("STRATEGIST_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    NFTMembership public nftMembership;
    address public treasury;

    // Fee structure (in basis points, 10000 = 100%)
    uint256 public performanceFee; // 1000 = 10%
    uint256 public managementFee;  // 200 = 2% annual
    uint256 public flashLoanFee;   // 9 = 0.09%

    uint256 public constant MAX_PERFORMANCE_FEE = 2000; // 20%
    uint256 public constant MAX_MANAGEMENT_FEE = 500;   // 5%
    uint256 public constant MAX_FLASH_LOAN_FEE = 100;   // 1%

    // Flash loan limits
    uint256 public maxFlashLoan;
    uint256 public constant FLASH_LOAN_LIMIT_PERCENTAGE = 8000; // 80%

    uint256 public lastHarvestTimestamp;
    uint256 public totalFeesCollected;

    event FeesUpdated(uint256 performanceFee, uint256 managementFee, uint256 flashLoanFee);
    event Harvest(uint256 profit, uint256 fees);
    event FlashLoan(address indexed borrower, uint256 amount, uint256 fee);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address admin,
        IERC20 _asset,
        address _nftMembership,
        address _treasury
    ) public initializer {
        __ERC4626_init(_asset);
        __ERC20_init("DeFi Vault Token", "dvToken");
        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(STRATEGIST_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);

        nftMembership = NFTMembership(_nftMembership);
        treasury = _treasury;

        performanceFee = 1000;  // 10%
        managementFee = 200;    // 2%
        flashLoanFee = 9;       // 0.09%

        lastHarvestTimestamp = block.timestamp;
    }

    // TODO: Override deposit to apply NFT fee discounts
    function deposit(uint256 assets, address receiver)
        public
        override
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        // TODO: Get user's fee discount from NFT
        // TODO: Calculate shares with discount applied
        // TODO: Call parent deposit
    }

    // TODO: Override withdraw to apply NFT fee discounts
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override whenNotPaused nonReentrant returns (uint256) {
        // TODO: Get user's fee discount from NFT
        // TODO: Calculate fees with discount
        // TODO: Call parent withdraw
    }

    // TODO: Implement harvest function (collect yield and distribute fees)
    function harvest() external onlyRole(STRATEGIST_ROLE) {
        // TODO: Calculate profit since last harvest
        // TODO: Calculate management fees (time-based)
        // TODO: Calculate performance fees (profit-based)
        // TODO: Distribute fees to treasury
        // TODO: Update last harvest timestamp
        // TODO: Emit event
    }

    // ========== FLASH LOAN FUNCTIONALITY ==========

    // TODO: Implement maxFlashLoan
    function maxFlashLoan(address token) external view override returns (uint256) {
        // TODO: Return 0 if token is not the vault asset
        // TODO: Return min(available balance, max flash loan limit)
    }

    // TODO: Implement flashFee
    function flashFee(address token, uint256 amount) external view override returns (uint256) {
        // TODO: Require token is vault asset
        // TODO: Calculate fee based on amount and flashLoanFee
    }

    // TODO: Implement flashLoan
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external override nonReentrant returns (bool) {
        // TODO: Validate token is vault asset
        // TODO: Validate amount <= maxFlashLoan
        // TODO: Calculate fee
        // TODO: Record balance before
        // TODO: Transfer tokens to receiver
        // TODO: Call receiver.onFlashLoan()
        // TODO: Check callback returns CALLBACK_SUCCESS
        // TODO: Transfer tokens + fee back from receiver
        // TODO: Verify balance >= balanceBefore + fee
        // TODO: Distribute fee
        // TODO: Emit event
        // TODO: Return true
    }

    // ========== ADMIN FUNCTIONS ==========

    function setFees(
        uint256 _performanceFee,
        uint256 _managementFee,
        uint256 _flashLoanFee
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_performanceFee <= MAX_PERFORMANCE_FEE, "Performance fee too high");
        require(_managementFee <= MAX_MANAGEMENT_FEE, "Management fee too high");
        require(_flashLoanFee <= MAX_FLASH_LOAN_FEE, "Flash loan fee too high");

        performanceFee = _performanceFee;
        managementFee = _managementFee;
        flashLoanFee = _flashLoanFee;

        emit FeesUpdated(_performanceFee, _managementFee, _flashLoanFee);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}
}

// ============================================================================
// MULTI-SIG TREASURY
// ============================================================================

/**
 * @title MultiSigTreasury
 * @notice Multi-signature treasury for protocol funds
 */
contract MultiSigTreasury is Initializable, ReentrancyGuardUpgradeable {
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
        mapping(address => bool) isConfirmed;
    }

    address[] public signers;
    mapping(address => bool) public isSigner;
    uint256 public requiredConfirmations;

    uint256 public transactionCount;
    mapping(uint256 => Transaction) public transactions;

    event SignerAdded(address indexed signer);
    event SignerRemoved(address indexed signer);
    event TransactionSubmitted(uint256 indexed txId, address indexed to, uint256 value);
    event TransactionConfirmed(uint256 indexed txId, address indexed signer);
    event TransactionExecuted(uint256 indexed txId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address[] memory _signers,
        uint256 _requiredConfirmations
    ) public initializer {
        __ReentrancyGuard_init();

        require(_signers.length >= 3, "Need at least 3 signers");
        require(_requiredConfirmations >= 2, "Need at least 2 confirmations");
        require(_requiredConfirmations <= _signers.length, "Invalid confirmation count");

        // TODO: Initialize signers
        // TODO: Set required confirmations
    }

    // TODO: Implement submitTransaction
    function submitTransaction(
        address to,
        uint256 value,
        bytes memory data
    ) public returns (uint256) {
        // TODO: Check msg.sender is signer
        // TODO: Create transaction
        // TODO: Auto-confirm from submitter
        // TODO: Emit events
        // TODO: Return transaction ID
    }

    // TODO: Implement confirmTransaction
    function confirmTransaction(uint256 txId) public {
        // TODO: Check msg.sender is signer
        // TODO: Check transaction exists and not executed
        // TODO: Check not already confirmed by this signer
        // TODO: Add confirmation
        // TODO: Emit event
    }

    // TODO: Implement executeTransaction
    function executeTransaction(uint256 txId) public nonReentrant {
        // TODO: Check transaction exists and not executed
        // TODO: Check enough confirmations
        // TODO: Mark as executed
        // TODO: Execute the transaction
        // TODO: Emit event
    }

    receive() external payable {}
}
