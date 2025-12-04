// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * @title BasicTokenSolution
 * @dev A simple ERC20 token using OpenZeppelin's implementation
 *
 * This demonstrates the most basic usage of OpenZeppelin's ERC20:
 * - Inherits all standard ERC20 functionality
 * - Sets token name and symbol
 * - Mints initial supply to deployer
 *
 * Gas cost for deployment: ~750k gas
 * Gas cost for transfer: ~52k gas
 */
contract BasicTokenSolution is ERC20 {
    /**
     * @dev Constructor sets token metadata and mints initial supply
     * @notice The ERC20 constructor takes (name, symbol) parameters
     */
    constructor() ERC20("Basic Token", "BASIC") {
        // Mint 1,000,000 tokens to the deployer
        // Note: Using 18 decimals (standard), so multiply by 10^18
        _mint(msg.sender, 1_000_000 * 10**decimals());
    }
}

/**
 * @title BurnableTokenSolution
 * @dev A token that can be burned by holders
 *
 * ERC20Burnable adds two functions:
 * - burn(uint256 amount): Burn caller's tokens
 * - burnFrom(address account, uint256 amount): Burn tokens from account (requires allowance)
 *
 * Use cases:
 * - Deflationary tokenomics
 * - Burn-to-redeem mechanisms
 * - Supply reduction events
 *
 * Gas overhead: ~500 gas per burn operation
 */
contract BurnableTokenSolution is ERC20, ERC20Burnable {
    constructor() ERC20("Burnable Token", "BURN") {
        _mint(msg.sender, 1_000_000 * 10**decimals());
    }

    // No additional code needed!
    // ERC20Burnable provides burn() and burnFrom() automatically
}

/**
 * @title PausableTokenSolution
 * @dev A token that can be paused by the owner
 *
 * When paused, all transfers are blocked. Useful for:
 * - Emergency situations (detected exploit)
 * - Regulatory compliance
 * - Migration periods
 *
 * Important notes:
 * - Paused state persists until explicitly unpaused
 * - Minting and burning are also blocked when paused
 * - Only the owner can pause/unpause
 *
 * Gas overhead: ~2.5k gas per transfer (checks paused state)
 */
contract PausableTokenSolution is ERC20, ERC20Pausable, Ownable {
    constructor() ERC20("Pausable Token", "PAUSE") Ownable(msg.sender) {
        _mint(msg.sender, 1_000_000 * 10**decimals());
    }

    /**
     * @dev Pause all token transfers
     * @notice Only owner can pause
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause all token transfers
     * @notice Only owner can unpause
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Override required by Solidity for multiple inheritance
     * @notice ERC20Pausable's _update checks if paused before allowing transfers
     */
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Pausable) {
        super._update(from, to, value);
    }
}

/**
 * @title SnapshotTokenSolution
 * @dev A token that can take snapshots of balances
 *
 * Snapshots record the balance of all accounts at a specific point in time.
 * Perfect for:
 * - Dividend distributions
 * - Governance voting (based on historical holdings)
 * - Airdrop calculations
 *
 * How it works:
 * 1. Owner calls snapshot() to create a new snapshot
 * 2. Returns snapshot ID (sequential: 1, 2, 3...)
 * 3. Anyone can query balances at any snapshot using balanceOfAt()
 *
 * Gas overhead: ~10-15k gas per transfer (maintains historical records)
 */
contract SnapshotTokenSolution is ERC20, ERC20Snapshot, Ownable {
    constructor() ERC20("Snapshot Token", "SNAP") Ownable(msg.sender) {
        _mint(msg.sender, 1_000_000 * 10**decimals());
    }

    /**
     * @dev Creates a new snapshot of all balances
     * @return snapshotId The ID of the newly created snapshot
     */
    function snapshot() public onlyOwner returns (uint256) {
        return _snapshot();
    }

    /**
     * @dev Override required for ERC20Snapshot
     * @notice Snapshot's _update maintains historical balance records
     */
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Snapshot) {
        super._update(from, to, value);
    }
}

/**
 * @title GovernanceTokenSolution
 * @dev A governance token with voting capabilities
 *
 * This token enables on-chain governance with:
 * - ERC20Votes: Delegation and voting power tracking
 * - ERC20Permit: Gasless approvals via signatures
 *
 * Key concepts:
 * - Voting power must be delegated (even to yourself)
 * - Historical voting power is tracked via checkpoints
 * - Votes can be delegated to another address
 * - Past voting power can be queried for any block
 *
 * Usage pattern:
 * 1. User receives tokens
 * 2. User calls delegate(address) to activate voting power
 * 3. Governance contract queries getPastVotes() for proposal voting
 *
 * Gas overhead: ~20-30k gas per transfer (maintains voting checkpoints)
 */
contract GovernanceTokenSolution is ERC20, ERC20Permit, ERC20Votes {
    constructor()
        ERC20("Governance Token", "GOV")
        ERC20Permit("Governance Token")
    {
        _mint(msg.sender, 1_000_000 * 10**decimals());
    }

    /**
     * @dev Override required for ERC20Votes
     * @notice Updates voting power checkpoints on transfers
     */
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    /**
     * @dev Resolve nonces conflict between ERC20Permit and Nonces
     * @notice Required when using both ERC20Permit and ERC20Votes
     */
    function nonces(address owner)
        public
        view
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}

/**
 * @title CappedTokenSolution
 * @dev A token with a maximum supply cap
 *
 * The cap is set in the constructor and cannot be changed.
 * Any attempt to mint beyond the cap will revert.
 *
 * Use cases:
 * - Fixed supply tokens (Bitcoin-like)
 * - Tokenomics with guaranteed maximum supply
 * - Preventing infinite inflation
 *
 * Gas overhead: ~200 gas per mint operation (cap check)
 */
contract CappedTokenSolution is ERC20, ERC20Capped, Ownable {
    constructor()
        ERC20("Capped Token", "CAP")
        ERC20Capped(10_000_000 * 10**18) // 10 million cap
        Ownable(msg.sender)
    {
        // Mint 5 million initially (50% of cap)
        _mint(msg.sender, 5_000_000 * 10**decimals());
    }

    /**
     * @dev Mint new tokens (respecting the cap)
     * @param to Address to receive tokens
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
        // Will revert if total supply + amount > cap
    }

    /**
     * @dev Override required for ERC20Capped
     * @notice Capped's _update checks if minting would exceed cap
     */
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Capped) {
        super._update(from, to, value);
    }
}

/**
 * @title FullFeaturedTokenSolution
 * @dev A token combining multiple extensions
 *
 * This demonstrates combining multiple extensions:
 * - Burnable: Users can burn their tokens
 * - Pausable: Owner can pause all transfers
 * - Snapshot: Owner can create balance snapshots
 *
 * Important: When combining extensions, you must:
 * 1. List ALL parent contracts in the override clause
 * 2. Call super._update() to invoke all parent implementations
 * 3. Be aware of gas costs stacking
 *
 * Total gas overhead: ~15k per transfer (sum of all extensions)
 */
contract FullFeaturedTokenSolution is
    ERC20,
    ERC20Burnable,
    ERC20Pausable,
    ERC20Snapshot,
    Ownable
{
    constructor() ERC20("Full Featured Token", "FULL") Ownable(msg.sender) {
        _mint(msg.sender, 1_000_000 * 10**decimals());
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function snapshot() public onlyOwner returns (uint256) {
        return _snapshot();
    }

    /**
     * @dev Critical: Must override with ALL parent contracts that implement _update
     * @notice The order matters - super._update calls each parent in order
     */
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Pausable, ERC20Snapshot) {
        // This calls:
        // 1. ERC20Pausable._update (checks if paused)
        // 2. ERC20Snapshot._update (records historical balance)
        // 3. ERC20._update (performs the actual transfer)
        super._update(from, to, value);
    }
}

/**
 * @title CustomHookTokenSolution
 * @dev A token with custom hook logic implementing transfer fees
 *
 * This demonstrates advanced hook usage:
 * - 1% fee on all transfers (not mints/burns)
 * - Fees sent to treasury
 * - Owner can update treasury address
 *
 * Hook pattern:
 * - from == address(0): Minting (no fee)
 * - to == address(0): Burning (no fee)
 * - both != address(0): Transfer (charge fee)
 *
 * Important: The fee is deducted from the transferred amount,
 * so if you send 100 tokens, recipient gets 99 and treasury gets 1.
 */
contract CustomHookTokenSolution is ERC20, Ownable {
    address public treasury;
    uint256 public constant FEE_BASIS_POINTS = 100; // 1% (100/10000)
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event FeeCollected(address indexed from, address indexed to, uint256 fee);

    constructor(address _treasury) ERC20("Custom Hook Token", "HOOK") Ownable(msg.sender) {
        require(_treasury != address(0), "Treasury cannot be zero address");
        treasury = _treasury;
        _mint(msg.sender, 1_000_000 * 10**decimals());
    }

    /**
     * @dev Update the treasury address
     * @param _treasury New treasury address
     */
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Treasury cannot be zero address");
        address oldTreasury = treasury;
        treasury = _treasury;
        emit TreasuryUpdated(oldTreasury, _treasury);
    }

    /**
     * @dev Custom hook implementing transfer fees
     * @notice Fees only apply to transfers, not minting or burning
     */
    function _update(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        // Only charge fee on transfers (not mints or burns)
        if (from != address(0) && to != address(0)) {
            // Calculate 1% fee
            uint256 fee = (value * FEE_BASIS_POINTS) / BASIS_POINTS_DIVISOR;

            if (fee > 0) {
                // Transfer fee to treasury
                super._update(from, treasury, fee);
                emit FeeCollected(from, to, fee);

                // Reduce amount by fee
                value = value - fee;
            }
        }

        // Perform the actual transfer (or mint/burn)
        super._update(from, to, value);
    }
}

/**
 * @title VestingTokenSolution
 * @dev A token with vesting period using hooks
 *
 * Features:
 * - Tokens are locked for 30 days after being received
 * - Owner can bypass vesting (for initial distributions)
 * - Tracks when tokens were received per address
 *
 * Use cases:
 * - Team token vesting
 * - Investor lockup periods
 * - Staking rewards with unlock periods
 *
 * Note: This is a simplified vesting. Production systems typically use
 * separate vesting contracts for more complex schedules.
 */
contract VestingTokenSolution is ERC20, Ownable {
    // Track when tokens were last received
    mapping(address => uint256) public tokenReceivedAt;

    uint256 public constant VESTING_PERIOD = 30 days;

    event TokensVested(address indexed account, uint256 timestamp);

    constructor() ERC20("Vesting Token", "VEST") Ownable(msg.sender) {
        _mint(msg.sender, 1_000_000 * 10**decimals());
        // Owner tokens are immediately vested
        tokenReceivedAt[msg.sender] = block.timestamp;
    }

    /**
     * @dev Override _update to enforce vesting period
     */
    function _update(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        // Check vesting period for transfers (not mints/burns)
        if (from != address(0) && from != owner()) {
            require(
                block.timestamp >= tokenReceivedAt[from] + VESTING_PERIOD,
                "Tokens are still vesting"
            );
        }

        // Perform the transfer
        super._update(from, to, value);

        // Update received timestamp for recipient (not for burns)
        if (to != address(0)) {
            // If receiving for the first time, set timestamp
            if (tokenReceivedAt[to] == 0) {
                tokenReceivedAt[to] = block.timestamp;
                emit TokensVested(to, block.timestamp);
            }
        }
    }
}

/**
 * @title RewardTokenSolution
 * @dev A token that distributes ETH rewards based on snapshots
 *
 * This is a complete reward distribution system:
 * 1. Owner adds ETH to reward pool and creates snapshot
 * 2. Users claim their share based on token holdings at snapshot
 * 3. Prevents double-claiming per snapshot
 *
 * Reward calculation:
 * userReward = (userBalanceAtSnapshot / totalSupplyAtSnapshot) * totalRewards
 *
 * Use cases:
 * - Profit sharing with token holders
 * - Dividend distributions
 * - Staking rewards
 */
contract RewardTokenSolution is ERC20, ERC20Snapshot, Ownable {
    // Track claimed rewards per snapshot per user
    mapping(uint256 => mapping(address => bool)) public hasClaimed;

    // Track total rewards per snapshot
    mapping(uint256 => uint256) public snapshotRewards;

    event RewardsAdded(uint256 indexed snapshotId, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 indexed snapshotId, uint256 amount);

    constructor() ERC20("Reward Token", "REWARD") Ownable(msg.sender) {
        _mint(msg.sender, 1_000_000 * 10**decimals());
    }

    /**
     * @dev Create a snapshot of current balances
     * @return snapshotId The ID of the created snapshot
     */
    function snapshot() public onlyOwner returns (uint256) {
        return _snapshot();
    }

    /**
     * @dev Add ETH rewards for a specific snapshot
     * @param snapshotId The snapshot ID to add rewards for
     */
    function addRewards(uint256 snapshotId) external payable onlyOwner {
        require(msg.value > 0, "Must send ETH");
        require(snapshotId > 0 && snapshotId <= _getCurrentSnapshotId(), "Invalid snapshot");

        snapshotRewards[snapshotId] += msg.value;
        emit RewardsAdded(snapshotId, msg.value);
    }

    /**
     * @dev Claim rewards for a specific snapshot
     * @param snapshotId The snapshot ID to claim rewards from
     */
    function claimRewards(uint256 snapshotId) external {
        require(!hasClaimed[snapshotId][msg.sender], "Already claimed");
        require(snapshotRewards[snapshotId] > 0, "No rewards for this snapshot");

        // Get user's balance at the snapshot
        uint256 userBalance = balanceOfAt(msg.sender, snapshotId);
        require(userBalance > 0, "No balance at snapshot");

        // Get total supply at the snapshot
        uint256 totalSupplyAtSnapshot = totalSupplyAt(snapshotId);

        // Calculate user's share of rewards
        uint256 userReward = (snapshotRewards[snapshotId] * userBalance) / totalSupplyAtSnapshot;
        require(userReward > 0, "No rewards to claim");

        // Mark as claimed
        hasClaimed[snapshotId][msg.sender] = true;

        // Transfer rewards
        (bool success, ) = msg.sender.call{value: userReward}("");
        require(success, "Reward transfer failed");

        emit RewardsClaimed(msg.sender, snapshotId, userReward);
    }

    /**
     * @dev Calculate pending rewards for an address
     * @param account Address to check
     * @param snapshotId Snapshot ID to check
     * @return Amount of pending rewards
     */
    function pendingRewards(address account, uint256 snapshotId) external view returns (uint256) {
        if (hasClaimed[snapshotId][account] || snapshotRewards[snapshotId] == 0) {
            return 0;
        }

        uint256 userBalance = balanceOfAt(account, snapshotId);
        if (userBalance == 0) {
            return 0;
        }

        uint256 totalSupplyAtSnapshot = totalSupplyAt(snapshotId);
        return (snapshotRewards[snapshotId] * userBalance) / totalSupplyAtSnapshot;
    }

    /**
     * @dev Override required for ERC20Snapshot
     */
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Snapshot) {
        super._update(from, to, value);
    }

    /**
     * @dev Allow contract to receive ETH
     */
    receive() external payable {}
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. OPENZEPPELIN PROVIDES BATTLE-TESTED CONTRACTS
 *    ✅ Audited by multiple security firms
 *    ✅ Used by thousands of production projects
 *    ✅ Gas-optimized implementations
 *    ✅ Regular security updates
 *    ✅ Standardized patterns reduce audit time
 *
 * 2. MODULAR EXTENSION PATTERN IS POWERFUL
 *    ✅ Base ERC20 + extensions (Burnable, Pausable, etc.)
 *    ✅ Add functionality without bloating base contract
 *    ✅ Mix and match extensions as needed
 *    ✅ Each extension adds ~2% gas overhead
 *
 * 3. HOOK SYSTEM ENABLES CUSTOM LOGIC
 *    ✅ _update() hook called on all transfers/mints/burns
 *    ✅ Override to add custom behavior
 *    ✅ Use cases: Pausable, Snapshot, Vesting, Fees
 *    ✅ OpenZeppelin 5.x uses _update() instead of _beforeTokenTransfer
 *
 * 4. EXTENSIONS HAVE SPECIFIC USE CASES
 *    ✅ ERC20Burnable: Deflationary tokenomics
 *    ✅ ERC20Pausable: Emergency stops
 *    ✅ ERC20Snapshot: Historical balance queries
 *    ✅ ERC20Votes: Governance voting
 *    ✅ ERC20Capped: Maximum supply limits
 *
 * 5. GAS TRADE-OFFS ARE MINIMAL
 *    ✅ OpenZeppelin adds ~2% gas overhead per operation
 *    ✅ Deployment: ~750k vs ~650k gas (+15%)
 *    ✅ Transfer: ~52k vs ~51k gas (+2%)
 *    ✅ Security benefits far outweigh small gas cost
 *
 * 6. PRODUCTION BEST PRACTICES
 *    ✅ Use OpenZeppelin for production contracts
 *    ✅ Choose extensions carefully (each adds gas)
 *    ✅ Test thoroughly before deployment
 *    ✅ Document which extensions are used
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMMON MISTAKES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ❌ Not calling super._update() in overrides (breaks inheritance!)
 * ❌ Using too many extensions (gas bloat)
 * ❌ Not understanding hook execution order
 * ❌ Custom implementation instead of OpenZeppelin (security risk)
 * ❌ Not testing extension combinations
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          NEXT STEPS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * • Study ERC20 Permit extension (Project 23)
 * • Explore custom hook implementations
 * • Learn about upgradeable token patterns
 * • Move to Project 23 to learn about EIP-2612 permit
 */
