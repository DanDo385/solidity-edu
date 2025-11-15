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
 * @title DeFi Protocol Capstone - Complete Solution
 * @notice Production-ready DeFi protocol with full integration
 * @dev Combines: ERC20, ERC721, ERC4626, Governance, Oracles, Flash Loans
 */

// ============================================================================
// PROTOCOL TOKEN (ERC20)
// ============================================================================

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

    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 1e18;

    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);

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

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply");
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

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

contract NFTMembership is
    Initializable,
    ERC721Upgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;

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

    mapping(Tier => uint256) public tierPrices;
    mapping(Tier => uint256) public tierMaxSupply;
    mapping(Tier => uint256) public tierMinted;
    mapping(uint256 => Membership) public memberships;
    mapping(address => uint256) public userNFT;

    event MembershipMinted(address indexed user, uint256 indexed tokenId, Tier tier, uint256 price);
    event MembershipUpgraded(uint256 indexed tokenId, Tier oldTier, Tier newTier, uint256 cost);

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
        _nextTokenId = 1;

        // Set tier prices
        tierPrices[Tier.BRONZE] = 100 * 1e18;
        tierPrices[Tier.SILVER] = 1_000 * 1e18;
        tierPrices[Tier.GOLD] = 10_000 * 1e18;
        tierPrices[Tier.PLATINUM] = 100_000 * 1e18;

        // Set max supplies
        tierMaxSupply[Tier.BRONZE] = type(uint256).max;
        tierMaxSupply[Tier.SILVER] = type(uint256).max;
        tierMaxSupply[Tier.GOLD] = type(uint256).max;
        tierMaxSupply[Tier.PLATINUM] = 100;
    }

    function mintMembership(Tier tier) external returns (uint256) {
        require(userNFT[msg.sender] == 0, "Already has membership");
        require(tierMinted[tier] < tierMaxSupply[tier], "Tier sold out");

        uint256 price = tierPrices[tier];
        require(protocolToken.balanceOf(msg.sender) >= price, "Insufficient PROTO");

        // Burn tokens to mint NFT
        protocolToken.transferFrom(msg.sender, address(this), price);
        ProtocolToken(address(protocolToken)).burn(price);

        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);

        memberships[tokenId] = Membership({
            tier: tier,
            mintedAt: block.timestamp,
            stakingBoost: 0
        });

        userNFT[msg.sender] = tokenId;
        tierMinted[tier]++;

        emit MembershipMinted(msg.sender, tokenId, tier, price);
        return tokenId;
    }

    function upgradeMembership(uint256 tokenId, Tier newTier) external {
        require(ownerOf(tokenId) == msg.sender, "Not owner");

        Tier currentTier = memberships[tokenId].tier;
        require(newTier > currentTier, "Must upgrade to higher tier");
        require(tierMinted[newTier] < tierMaxSupply[newTier], "Tier sold out");

        uint256 upgradeCost = tierPrices[newTier] - tierPrices[currentTier];
        require(protocolToken.balanceOf(msg.sender) >= upgradeCost, "Insufficient PROTO");

        protocolToken.transferFrom(msg.sender, address(this), upgradeCost);
        ProtocolToken(address(protocolToken)).burn(upgradeCost);

        // Update tier counts
        tierMinted[currentTier]--;
        tierMinted[newTier]++;

        memberships[tokenId].tier = newTier;

        emit MembershipUpgraded(tokenId, currentTier, newTier, upgradeCost);
    }

    function getTier(uint256 tokenId) public view returns (Tier) {
        require(_exists(tokenId), "Token doesn't exist");
        return memberships[tokenId].tier;
    }

    function getVotingMultiplier(address user) public view returns (uint256) {
        uint256 tokenId = userNFT[user];
        if (tokenId == 0 || !_exists(tokenId)) return 1;

        Tier tier = memberships[tokenId].tier;
        if (tier == Tier.BRONZE) return 1;
        if (tier == Tier.SILVER) return 2;
        if (tier == Tier.GOLD) return 5;
        if (tier == Tier.PLATINUM) return 10;
        return 1;
    }

    function getFeeDiscount(address user) public view returns (uint256) {
        uint256 tokenId = userNFT[user];
        if (tokenId == 0 || !_exists(tokenId)) return 0;

        Tier tier = memberships[tokenId].tier;
        if (tier == Tier.BRONZE) return 500;      // 5%
        if (tier == Tier.SILVER) return 1000;     // 10%
        if (tier == Tier.GOLD) return 2500;       // 25%
        if (tier == Tier.PLATINUM) return 5000;   // 50%
        return 0;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
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

interface IPriceFeed {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract PriceOracle is Initializable, AccessControlUpgradeable {
    bytes32 public constant ORACLE_ADMIN_ROLE = keccak256("ORACLE_ADMIN_ROLE");

    struct PriceFeed {
        address source;
        uint256 heartbeat;
        bool isActive;
    }

    mapping(address => PriceFeed) public priceFeeds;
    uint256 public constant MAX_DEVIATION = 1000; // 10%
    uint256 public constant BASIS_POINTS = 10000;

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

    function setPriceFeed(
        address asset,
        address source,
        uint256 heartbeat
    ) external onlyRole(ORACLE_ADMIN_ROLE) {
        require(asset != address(0), "Invalid asset");
        require(source != address(0), "Invalid source");
        require(heartbeat > 0, "Invalid heartbeat");

        priceFeeds[asset] = PriceFeed({
            source: source,
            heartbeat: heartbeat,
            isActive: true
        });

        emit PriceFeedUpdated(asset, source, heartbeat);
    }

    function getPrice(address asset) external view returns (uint256) {
        PriceFeed memory feed = priceFeeds[asset];
        require(feed.isActive, "Price feed not active");

        (
            ,
            int256 price,
            ,
            uint256 updatedAt,

        ) = IPriceFeed(feed.source).latestRoundData();

        require(price > 0, "Invalid price");
        require(block.timestamp - updatedAt <= feed.heartbeat, "Stale price");

        emit PriceReported(asset, uint256(price), updatedAt);
        return uint256(price);
    }

    function validatePrice(address asset, uint256 proposedPrice) external view returns (bool) {
        PriceFeed memory feed = priceFeeds[asset];
        if (!feed.isActive) return false;

        (
            ,
            int256 currentPrice,
            ,
            uint256 updatedAt,

        ) = IPriceFeed(feed.source).latestRoundData();

        if (currentPrice <= 0) return false;
        if (block.timestamp - updatedAt > feed.heartbeat) return false;

        uint256 deviation;
        if (proposedPrice > uint256(currentPrice)) {
            deviation = ((proposedPrice - uint256(currentPrice)) * BASIS_POINTS) / uint256(currentPrice);
        } else {
            deviation = ((uint256(currentPrice) - proposedPrice) * BASIS_POINTS) / uint256(currentPrice);
        }

        return deviation <= MAX_DEVIATION;
    }

    function deactivateFeed(address asset) external onlyRole(ORACLE_ADMIN_ROLE) {
        priceFeeds[asset].isActive = false;
    }
}

// ============================================================================
// GOVERNANCE SYSTEM
// ============================================================================

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

    struct ProposalCore {
        uint256 id;
        address proposer;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        bool executed;
        bool canceled;
    }

    struct ProposalData {
        address[] targets;
        uint256[] values;
        bytes[] calldatas;
        string description;
        mapping(address => bool) hasVoted;
    }

    IERC20 public protocolToken;
    NFTMembership public nftMembership;

    uint256 public proposalCount;
    mapping(uint256 => ProposalCore) public proposalCores;
    mapping(uint256 => ProposalData) private proposalData;
    mapping(uint256 => uint256) public proposalEta;

    uint256 public proposalThreshold;
    uint256 public quorumPercentage;
    uint256 public votingDelay;
    uint256 public votingPeriod;
    uint256 public timelockDelay;

    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        address[] targets,
        string description
    );
    event VoteCast(address indexed voter, uint256 indexed proposalId, uint8 support, uint256 weight);
    event ProposalQueued(uint256 indexed proposalId, uint256 eta);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);

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

        proposalThreshold = 100_000 * 1e18;
        quorumPercentage = 4;
        votingDelay = 1;
        votingPeriod = 50400; // ~7 days
        timelockDelay = 2 days;
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256) {
        uint256 tokenBalance = protocolToken.balanceOf(msg.sender);
        uint256 nftTokenId = nftMembership.userNFT(msg.sender);

        bool hasGoldNFT = false;
        if (nftTokenId > 0) {
            NFTMembership.Tier tier = nftMembership.getTier(nftTokenId);
            hasGoldNFT = tier >= NFTMembership.Tier.GOLD;
        }

        require(
            tokenBalance >= proposalThreshold || hasGoldNFT,
            "Insufficient tokens or NFT tier"
        );

        require(targets.length > 0, "No targets");
        require(
            targets.length == values.length &&
            targets.length == calldatas.length,
            "Length mismatch"
        );

        uint256 proposalId = ++proposalCount;

        proposalCores[proposalId] = ProposalCore({
            id: proposalId,
            proposer: msg.sender,
            startBlock: block.number + votingDelay,
            endBlock: block.number + votingDelay + votingPeriod,
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0,
            executed: false,
            canceled: false
        });

        ProposalData storage data = proposalData[proposalId];
        data.targets = targets;
        data.values = values;
        data.calldatas = calldatas;
        data.description = description;

        emit ProposalCreated(proposalId, msg.sender, targets, description);
        return proposalId;
    }

    function castVote(uint256 proposalId, uint8 support) external {
        require(state(proposalId) == ProposalState.Active, "Not active");
        require(support <= 2, "Invalid support value");

        ProposalData storage data = proposalData[proposalId];
        require(!data.hasVoted[msg.sender], "Already voted");

        uint256 weight = getVotes(msg.sender);
        require(weight > 0, "No voting power");

        data.hasVoted[msg.sender] = true;

        ProposalCore storage core = proposalCores[proposalId];
        if (support == 0) {
            core.againstVotes += weight;
        } else if (support == 1) {
            core.forVotes += weight;
        } else {
            core.abstainVotes += weight;
        }

        emit VoteCast(msg.sender, proposalId, support, weight);
    }

    function queue(uint256 proposalId) external {
        require(state(proposalId) == ProposalState.Succeeded, "Not succeeded");

        uint256 eta = block.timestamp + timelockDelay;
        proposalEta[proposalId] = eta;

        emit ProposalQueued(proposalId, eta);
    }

    function execute(uint256 proposalId) external nonReentrant onlyRole(EXECUTOR_ROLE) {
        require(state(proposalId) == ProposalState.Queued, "Not queued");
        require(block.timestamp >= proposalEta[proposalId], "Timelock not passed");

        ProposalCore storage core = proposalCores[proposalId];
        core.executed = true;

        ProposalData storage data = proposalData[proposalId];
        for (uint256 i = 0; i < data.targets.length; i++) {
            (bool success, ) = data.targets[i].call{value: data.values[i]}(data.calldatas[i]);
            require(success, "Execution failed");
        }

        emit ProposalExecuted(proposalId);
    }

    function cancel(uint256 proposalId) external {
        ProposalCore storage core = proposalCores[proposalId];
        require(msg.sender == core.proposer || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not authorized");
        require(!core.executed, "Already executed");

        core.canceled = true;
        emit ProposalCanceled(proposalId);
    }

    function state(uint256 proposalId) public view returns (ProposalState) {
        ProposalCore storage core = proposalCores[proposalId];

        if (core.canceled) return ProposalState.Canceled;
        if (core.executed) return ProposalState.Executed;
        if (block.number < core.startBlock) return ProposalState.Pending;
        if (block.number <= core.endBlock) return ProposalState.Active;

        if (proposalEta[proposalId] > 0) {
            if (block.timestamp > proposalEta[proposalId] + 14 days) {
                return ProposalState.Expired;
            }
            return ProposalState.Queued;
        }

        uint256 totalVotes = core.forVotes + core.againstVotes + core.abstainVotes;
        if (totalVotes < quorum() || core.forVotes <= core.againstVotes) {
            return ProposalState.Defeated;
        }

        return ProposalState.Succeeded;
    }

    function getVotes(address account) public view returns (uint256) {
        uint256 tokenBalance = protocolToken.balanceOf(account);
        uint256 multiplier = nftMembership.getVotingMultiplier(account);
        return tokenBalance * multiplier;
    }

    function quorum() public view returns (uint256) {
        return (protocolToken.totalSupply() * quorumPercentage) / 100;
    }

    function getProposalData(uint256 proposalId)
        external
        view
        returns (
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            string memory description
        )
    {
        ProposalData storage data = proposalData[proposalId];
        return (data.targets, data.values, data.calldatas, data.description);
    }
}

// ============================================================================
// VAULT (ERC4626) WITH FLASH LOANS
// ============================================================================

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

    uint256 public performanceFee;
    uint256 public managementFee;
    uint256 public flashLoanFee;

    uint256 public constant MAX_PERFORMANCE_FEE = 2000;
    uint256 public constant MAX_MANAGEMENT_FEE = 500;
    uint256 public constant MAX_FLASH_LOAN_FEE = 100;
    uint256 public constant FLASH_LOAN_LIMIT_PERCENTAGE = 8000;
    uint256 public constant BASIS_POINTS = 10000;

    uint256 public lastHarvestTimestamp;
    uint256 public totalFeesCollected;
    uint256 public totalProfitGenerated;

    event FeesUpdated(uint256 performanceFee, uint256 managementFee, uint256 flashLoanFee);
    event Harvest(uint256 profit, uint256 performanceFees, uint256 managementFees);
    event FlashLoan(address indexed borrower, uint256 amount, uint256 fee);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);

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

        performanceFee = 1000;
        managementFee = 200;
        flashLoanFee = 9;

        lastHarvestTimestamp = block.timestamp;
    }

    function deposit(uint256 assets, address receiver)
        public
        override
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        uint256 discount = nftMembership.getFeeDiscount(msg.sender);

        // Apply discount to any deposit fees if implemented
        // Currently no deposit fee, but structure allows for it

        return super.deposit(assets, receiver);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override whenNotPaused nonReentrant returns (uint256) {
        uint256 discount = nftMembership.getFeeDiscount(owner);

        // Apply discount to withdrawal fees if implemented
        // Currently minimal, but structure allows for it

        return super.withdraw(assets, receiver, owner);
    }

    function harvest() external onlyRole(STRATEGIST_ROLE) {
        uint256 currentAssets = totalAssets();
        uint256 totalShares = totalSupply();

        if (totalShares == 0) {
            lastHarvestTimestamp = block.timestamp;
            return;
        }

        // Calculate expected assets based on shares (without new profit)
        uint256 expectedAssets = (totalShares * 1e18) / 1e18;

        // Profit is any assets above expected
        uint256 profit = currentAssets > expectedAssets ? currentAssets - expectedAssets : 0;

        // Calculate time-based management fee
        uint256 timeElapsed = block.timestamp - lastHarvestTimestamp;
        uint256 annualFee = (currentAssets * managementFee) / BASIS_POINTS;
        uint256 managementFees = (annualFee * timeElapsed) / 365 days;

        // Calculate performance fee on profit
        uint256 performanceFees = (profit * performanceFee) / BASIS_POINTS;

        uint256 totalFees = performanceFees + managementFees;

        if (totalFees > 0) {
            IERC20(asset()).safeTransfer(treasury, totalFees);
            totalFeesCollected += totalFees;
        }

        if (profit > 0) {
            totalProfitGenerated += profit;
        }

        lastHarvestTimestamp = block.timestamp;

        emit Harvest(profit, performanceFees, managementFees);
    }

    // ========== FLASH LOAN FUNCTIONALITY ==========

    function maxFlashLoan(address token) external view override returns (uint256) {
        if (token != asset()) return 0;

        uint256 available = IERC20(asset()).balanceOf(address(this));
        uint256 maxLoan = (available * FLASH_LOAN_LIMIT_PERCENTAGE) / BASIS_POINTS;

        return maxLoan;
    }

    function flashFee(address token, uint256 amount) public view override returns (uint256) {
        require(token == asset(), "Unsupported token");
        return (amount * flashLoanFee) / BASIS_POINTS;
    }

    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external override nonReentrant returns (bool) {
        require(token == asset(), "Unsupported token");
        require(amount <= this.maxFlashLoan(token), "Amount exceeds max");

        uint256 fee = flashFee(token, amount);
        uint256 balanceBefore = IERC20(asset()).balanceOf(address(this));

        // Transfer loan to borrower
        IERC20(asset()).safeTransfer(address(receiver), amount);

        // Execute borrower's callback
        require(
            receiver.onFlashLoan(msg.sender, token, amount, fee, data) == CALLBACK_SUCCESS,
            "Callback failed"
        );

        // Collect repayment
        IERC20(asset()).safeTransferFrom(address(receiver), address(this), amount + fee);

        uint256 balanceAfter = IERC20(asset()).balanceOf(address(this));
        require(balanceAfter >= balanceBefore + fee, "Insufficient repayment");

        // Distribute fee (50% to treasury, 50% to vault)
        if (fee > 0) {
            uint256 treasuryFee = fee / 2;
            IERC20(asset()).safeTransfer(treasury, treasuryFee);
            totalFeesCollected += treasuryFee;
        }

        emit FlashLoan(address(receiver), amount, fee);
        return true;
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

    function setTreasury(address _treasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_treasury != address(0), "Invalid treasury");
        address oldTreasury = treasury;
        treasury = _treasury;
        emit TreasuryUpdated(oldTreasury, _treasury);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function emergencyWithdraw(address token, uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(paused(), "Not paused");
        IERC20(token).safeTransfer(treasury, amount);
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

contract MultiSigTreasury is Initializable, ReentrancyGuardUpgradeable {
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
    }

    address[] public signers;
    mapping(address => bool) public isSigner;
    uint256 public requiredConfirmations;

    uint256 public transactionCount;
    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    event SignerAdded(address indexed signer);
    event SignerRemoved(address indexed signer);
    event RequirementChanged(uint256 required);
    event TransactionSubmitted(uint256 indexed txId, address indexed to, uint256 value, bytes data);
    event TransactionConfirmed(uint256 indexed txId, address indexed signer);
    event ConfirmationRevoked(uint256 indexed txId, address indexed signer);
    event TransactionExecuted(uint256 indexed txId);
    event TransactionFailed(uint256 indexed txId);

    modifier onlySigner() {
        require(isSigner[msg.sender], "Not a signer");
        _;
    }

    modifier txExists(uint256 txId) {
        require(txId < transactionCount, "Transaction doesn't exist");
        _;
    }

    modifier notExecuted(uint256 txId) {
        require(!transactions[txId].executed, "Already executed");
        _;
    }

    modifier notConfirmed(uint256 txId) {
        require(!isConfirmed[txId][msg.sender], "Already confirmed");
        _;
    }

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

        for (uint256 i = 0; i < _signers.length; i++) {
            address signer = _signers[i];
            require(signer != address(0), "Invalid signer");
            require(!isSigner[signer], "Duplicate signer");

            isSigner[signer] = true;
            signers.push(signer);
            emit SignerAdded(signer);
        }

        requiredConfirmations = _requiredConfirmations;
    }

    function submitTransaction(
        address to,
        uint256 value,
        bytes memory data
    ) public onlySigner returns (uint256) {
        uint256 txId = transactionCount++;

        transactions[txId] = Transaction({
            to: to,
            value: value,
            data: data,
            executed: false,
            confirmations: 0
        });

        emit TransactionSubmitted(txId, to, value, data);

        // Auto-confirm from submitter
        confirmTransaction(txId);

        return txId;
    }

    function confirmTransaction(uint256 txId)
        public
        onlySigner
        txExists(txId)
        notExecuted(txId)
        notConfirmed(txId)
    {
        isConfirmed[txId][msg.sender] = true;
        transactions[txId].confirmations++;

        emit TransactionConfirmed(txId, msg.sender);

        // Auto-execute if threshold reached
        if (transactions[txId].confirmations >= requiredConfirmations) {
            executeTransaction(txId);
        }
    }

    function revokeConfirmation(uint256 txId)
        public
        onlySigner
        txExists(txId)
        notExecuted(txId)
    {
        require(isConfirmed[txId][msg.sender], "Not confirmed");

        isConfirmed[txId][msg.sender] = false;
        transactions[txId].confirmations--;

        emit ConfirmationRevoked(txId, msg.sender);
    }

    function executeTransaction(uint256 txId)
        public
        nonReentrant
        txExists(txId)
        notExecuted(txId)
    {
        Transaction storage txn = transactions[txId];
        require(txn.confirmations >= requiredConfirmations, "Not enough confirmations");

        txn.executed = true;

        (bool success, ) = txn.to.call{value: txn.value}(txn.data);

        if (success) {
            emit TransactionExecuted(txId);
        } else {
            emit TransactionFailed(txId);
            txn.executed = false;
        }
    }

    function getSigners() public view returns (address[] memory) {
        return signers;
    }

    function getTransactionCount(bool pending, bool executed)
        public
        view
        returns (uint256 count)
    {
        for (uint256 i = 0; i < transactionCount; i++) {
            if (
                (pending && !transactions[i].executed) ||
                (executed && transactions[i].executed)
            ) {
                count++;
            }
        }
    }

    function getConfirmationCount(uint256 txId) public view returns (uint256) {
        return transactions[txId].confirmations;
    }

    receive() external payable {}
}
