// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Project13Solution - Block Properties & Time Logic (Complete Implementation)
 * @notice Complete solution demonstrating safe time-based logic patterns
 * @dev This contract shows best practices for working with block.timestamp and block.number
 *
 * KEY LEARNINGS IMPLEMENTED:
 * - block.timestamp for long-duration locks (hours/days)
 * - block.number for predictable event timing
 * - Rate limiting to prevent spam
 * - Cooldown periods for two-step processes
 * - Linear vesting calculations
 * - Proper time comparisons using >=
 *
 * SECURITY CONSIDERATIONS:
 * - All time comparisons use >= instead of ==
 * - Timestamp manipulation (±15 seconds) is negligible for our use cases
 * - Reentrancy protection via checks-effects-interactions pattern
 * - blockhash randomness is NOT secure (educational only)
 */
contract Project13Solution {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    // Owner address
    address public owner;

    // TimeLockedVault variables
    uint256 public vaultUnlockTime;
    uint256 public vaultBalance;

    // RateLimiter variables
    // Maps user address to timestamp of their last action
    mapping(address => uint256) public lastActionTime;
    uint256 public constant RATE_LIMIT_DURATION = 1 hours;

    // Cooldown variables
    // Maps user address to timestamp when cooldown started
    mapping(address => uint256) public cooldownStart;
    uint256 public constant COOLDOWN_DURATION = 7 days;
    mapping(address => bool) public cooldownActive;

    // VestingWallet variables
    uint256 public vestingStartTime;
    uint256 public vestingDuration;
    uint256 public vestingTotalAmount;
    uint256 public vestingReleased;
    address public vestingBeneficiary;

    // BlockBasedLottery variables
    uint256 public lotteryStartBlock;
    uint256 public lotteryEndBlock;
    mapping(address => bool) public hasEntered;
    address[] public participants;
    address public lotteryWinner;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event VaultLocked(uint256 unlockTime, uint256 amount);
    event VaultWithdrawn(address indexed to, uint256 amount);
    event ActionPerformed(address indexed user, uint256 timestamp);
    event CooldownInitiated(address indexed user, uint256 startTime);
    event CooldownCompleted(address indexed user);
    event VestingInitialized(address indexed beneficiary, uint256 amount, uint256 duration);
    event TokensReleased(address indexed beneficiary, uint256 amount);
    event LotteryEntered(address indexed participant, uint256 blockNumber);
    event LotteryWinnerSelected(address indexed winner, uint256 blockNumber);

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error Unauthorized();
    error VaultStillLocked();
    error InsufficientBalance();
    error RateLimitActive();
    error CooldownNotInitiated();
    error CooldownNotFinished();
    error CooldownAlreadyActive();
    error NoTokensToRelease();
    error LotteryNotActive();
    error AlreadyEntered();
    error LotteryNotEnded();
    error NoParticipants();

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        owner = msg.sender;
    }

    /*//////////////////////////////////////////////////////////////
                        TIME-LOCKED VAULT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Lock ETH in the vault until a specific timestamp
     * @param lockDuration How long to lock the funds (in seconds)
     * @dev Uses block.timestamp for human-readable lock periods
     *
     * SECURITY NOTE: block.timestamp can be manipulated by ±15 seconds
     * For a lock period of hours/days, this manipulation is negligible
     * Example: 15 seconds is only 0.017% of a 24-hour lock period
     *
     * PATTERN: This demonstrates using block.timestamp for long-duration locks
     * Perfect for time-locks, vesting, and other time-based restrictions
     */
    function lockInVault(uint256 lockDuration) external payable {
        // Calculate unlock time by adding duration to current timestamp
        vaultUnlockTime = block.timestamp + lockDuration;

        // Add deposited ETH to vault balance
        vaultBalance += msg.value;

        // Emit event for transparency
        emit VaultLocked(vaultUnlockTime, msg.value);
    }

    /**
     * @notice Withdraw ETH from the vault after unlock time
     * @dev Demonstrates safe time comparison and reentrancy protection
     *
     * SECURITY NOTES:
     * 1. Uses >= instead of == for time comparison
     *    - We'll never hit an exact timestamp to the second
     *    - >= ensures the function becomes callable once time passes
     * 2. Follows checks-effects-interactions pattern
     *    - Check: verify unlock time and balance
     *    - Effects: update state before external call
     *    - Interactions: transfer ETH last
     * 3. Zero out balance before transfer to prevent reentrancy
     */
    function withdrawFromVault() external {
        // CHECK: Verify unlock time has passed
        // Using >= not == because we need "at or after", not "exactly at"
        if (block.timestamp < vaultUnlockTime) {
            revert VaultStillLocked();
        }

        // CHECK: Verify there's a balance to withdraw
        if (vaultBalance == 0) {
            revert InsufficientBalance();
        }

        // EFFECTS: Update state before external call (reentrancy protection)
        uint256 amount = vaultBalance;
        vaultBalance = 0;

        // INTERACTIONS: External call happens last
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit VaultWithdrawn(msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////
                         RATE LIMITER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Perform an action that is rate-limited to once per hour
     * @dev Demonstrates rate limiting pattern to prevent spam/abuse
     *
     * PATTERN: Rate limiting is common in DeFi for:
     * - Claiming rewards (prevent gas griefing)
     * - Voting (prevent spam proposals)
     * - Withdrawals (circuit breaker mechanism)
     *
     * SECURITY: The first call by a user always succeeds because
     * lastActionTime[msg.sender] starts at 0, and 0 + RATE_LIMIT_DURATION < block.timestamp
     * This is intentional and expected behavior
     */
    function performRateLimitedAction() external {
        // Calculate when the next action is allowed
        uint256 nextAllowedTime = lastActionTime[msg.sender] + RATE_LIMIT_DURATION;

        // Revert if not enough time has passed
        // For first-time users, lastActionTime is 0, so this check passes
        if (block.timestamp < nextAllowedTime) {
            revert RateLimitActive();
        }

        // Update the timestamp for this user
        lastActionTime[msg.sender] = block.timestamp;

        // Emit event to track actions
        emit ActionPerformed(msg.sender, block.timestamp);

        // In a real implementation, perform the actual action here
        // Examples: claim rewards, submit proposal, withdraw funds, etc.
    }

    /**
     * @notice Get remaining time until action is available again
     * @param user Address to check
     * @return seconds until action is available (0 if available now)
     * @dev Useful for UI to show countdown timers
     *
     * LEARNING: View functions can perform calculations without gas cost
     * Perfect for providing user-friendly information to frontends
     */
    function getRemainingCooldown(address user) external view returns (uint256) {
        // Calculate when next action is allowed
        uint256 nextAllowedTime = lastActionTime[user] + RATE_LIMIT_DURATION;

        // If enough time has passed, return 0 (action is available)
        if (block.timestamp >= nextAllowedTime) {
            return 0;
        }

        // Otherwise, return remaining time
        return nextAllowedTime - block.timestamp;
    }

    /*//////////////////////////////////////////////////////////////
                         COOLDOWN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initiate a cooldown period (e.g., before unstaking)
     * @dev Two-step process provides safety and transparency
     *
     * PATTERN: Two-step cooldown is common in staking protocols:
     * 1. User initiates cooldown (this function)
     * 2. After waiting period, user executes action (executeAfterCooldown)
     *
     * WHY TWO STEPS?
     * - Prevents instant unstaking that could destabilize protocol
     * - Gives protocol time to adjust (e.g., rebalance liquidity)
     * - Makes user intention explicit (must actively confirm)
     * - Reduces risk of accidental actions
     *
     * EXAMPLES: Lido staking, Curve vote locking, many liquid staking protocols
     */
    function initiateCooldown() external {
        // Prevent starting new cooldown if one is already active
        if (cooldownActive[msg.sender]) {
            revert CooldownAlreadyActive();
        }

        // Record when cooldown started
        cooldownStart[msg.sender] = block.timestamp;

        // Mark cooldown as active
        cooldownActive[msg.sender] = true;

        emit CooldownInitiated(msg.sender, block.timestamp);
    }

    /**
     * @notice Execute action after cooldown period has finished
     * @dev Completes the two-step process
     *
     * SECURITY NOTES:
     * 1. Checks that cooldown was actually initiated (prevents bypass)
     * 2. Uses >= for time comparison (standard practice)
     * 3. Resets state after execution (prevents double execution)
     *
     * LEARNING: The full cooldown duration is COOLDOWN_DURATION
     * Example: If COOLDOWN_DURATION = 7 days, user must wait 7 days
     * between initiateCooldown() and executeAfterCooldown()
     */
    function executeAfterCooldown() external {
        // CHECK: Verify cooldown was initiated
        if (!cooldownActive[msg.sender]) {
            revert CooldownNotInitiated();
        }

        // CHECK: Verify enough time has passed
        // Using >= because we want "at or after", not "exactly at"
        if (block.timestamp < cooldownStart[msg.sender] + COOLDOWN_DURATION) {
            revert CooldownNotFinished();
        }

        // EFFECTS: Reset state (allows initiating new cooldown in future)
        cooldownActive[msg.sender] = false;
        cooldownStart[msg.sender] = 0;

        emit CooldownCompleted(msg.sender);

        // In a real implementation, execute the action here
        // Examples: unstake tokens, withdraw from vault, etc.
    }

    /*//////////////////////////////////////////////////////////////
                        VESTING WALLET FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initialize vesting schedule for beneficiary
     * @param beneficiary Address that will receive vested tokens
     * @param totalAmount Total amount to vest over time
     * @param duration Vesting duration in seconds
     * @dev Linear vesting: tokens release proportionally over time
     *
     * PATTERN: Linear vesting is the most common vesting schedule
     * - 0% vested at start
     * - Increases linearly over time
     * - 100% vested at end
     *
     * FORMULA: vestedAmount = (totalAmount * timeElapsed) / totalDuration
     *
     * EXAMPLES: Team token vesting, advisor vesting, investor vesting
     * Common durations: 1 year, 2 years, 4 years
     * Often includes a "cliff" (we'll implement simple linear here)
     */
    function initializeVesting(
        address beneficiary,
        uint256 totalAmount,
        uint256 duration
    ) external onlyOwner {
        // Set beneficiary who will receive vested tokens
        vestingBeneficiary = beneficiary;

        // Record when vesting starts (current time)
        vestingStartTime = block.timestamp;

        // Set vesting duration
        vestingDuration = duration;

        // Set total amount to vest
        vestingTotalAmount = totalAmount;

        // Reset released amount (in case re-initializing)
        vestingReleased = 0;

        emit VestingInitialized(beneficiary, totalAmount, duration);
    }

    /**
     * @notice Calculate how many tokens have vested so far
     * @return Amount of tokens vested (including already released)
     * @dev Linear vesting formula: (totalAmount * timeElapsed) / totalDuration
     *
     * LEARNING: This is a view function, so it can be called anytime
     * to check vesting progress without costing gas
     *
     * THREE SCENARIOS:
     * 1. Before vesting starts: return 0
     * 2. After vesting ends: return totalAmount (fully vested)
     * 3. During vesting: calculate proportionally
     *
     * SECURITY: Uses Solidity 0.8.0+ built-in overflow protection
     * In older versions, you'd need SafeMath for the multiplication
     */
    function calculateVestedAmount() public view returns (uint256) {
        // SCENARIO 1: Vesting hasn't started yet
        if (block.timestamp < vestingStartTime) {
            return 0;
        }

        // SCENARIO 2: Vesting period has ended, all tokens are vested
        if (block.timestamp >= vestingStartTime + vestingDuration) {
            return vestingTotalAmount;
        }

        // SCENARIO 3: During vesting period, calculate proportionally
        // timeElapsed = how many seconds have passed since vesting started
        uint256 timeElapsed = block.timestamp - vestingStartTime;

        // Linear vesting formula:
        // vestedAmount = (totalAmount * timeElapsed) / totalDuration
        //
        // Example: If 25% of time has passed, 25% of tokens are vested
        // - totalAmount = 1000 tokens
        // - duration = 100 days
        // - timeElapsed = 25 days
        // - vested = (1000 * 25) / 100 = 250 tokens
        return (vestingTotalAmount * timeElapsed) / vestingDuration;
    }

    /**
     * @notice Release vested tokens to beneficiary
     * @return amount Amount of tokens released
     * @dev Anyone can call this, but tokens always go to beneficiary
     *
     * PATTERN: "Push" model where tokens are actively claimed
     * Alternative: "Pull" model where beneficiary must claim
     *
     * SECURITY NOTES:
     * 1. Calculates vested amount at call time (dynamic)
     * 2. Tracks already-released amount to prevent double-release
     * 3. Only releases the difference (vested - released)
     * 4. Updates state before any token transfer (if implemented)
     */
    function releaseVestedTokens() external returns (uint256) {
        // Calculate total vested amount at this moment
        uint256 vestedAmount = calculateVestedAmount();

        // Calculate how much is newly vested (not yet released)
        // releasable = total vested - already released
        uint256 releasable = vestedAmount - vestingReleased;

        // Require that there's something to release
        if (releasable == 0) {
            revert NoTokensToRelease();
        }

        // EFFECTS: Update state before any external calls
        vestingReleased += releasable;

        emit TokensReleased(vestingBeneficiary, releasable);

        // INTERACTIONS: In a real implementation, transfer tokens here
        // Example with ERC20:
        // token.transfer(vestingBeneficiary, releasable);

        return releasable;
    }

    /*//////////////////////////////////////////////////////////////
                    BLOCK-BASED LOTTERY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Start a new lottery that runs for specified number of blocks
     * @param durationInBlocks How many blocks the lottery will run
     * @dev Uses block.number for more predictable timing
     *
     * WHY block.number INSTEAD OF block.timestamp?
     * - More predictable: blocks are sequential, time can vary
     * - Network-agnostic: works same on any EVM chain (with adjustments)
     * - Cannot be manipulated by miners (beyond censoring transactions)
     *
     * LEARNING: Average block time on Ethereum is ~12 seconds
     * - 300 blocks ≈ 1 hour
     * - 7200 blocks ≈ 1 day
     * BUT: Use actual network's block time for estimates!
     */
    function startLottery(uint256 durationInBlocks) external onlyOwner {
        // Record starting block
        lotteryStartBlock = block.number;

        // Calculate ending block
        lotteryEndBlock = block.number + durationInBlocks;

        // Reset participants from any previous lottery
        delete participants;

        // Reset winner
        lotteryWinner = address(0);

        // Note: We don't reset hasEntered mapping for gas efficiency
        // It will be overwritten as users enter new lottery
    }

    /**
     * @notice Enter the lottery
     * @dev Participants can enter during the lottery period
     *
     * CHECKS:
     * 1. Lottery is active (current block is within range)
     * 2. User hasn't already entered this lottery
     *
     * PATTERN: Entry tracking prevents duplicate entries
     * Uses both mapping (for O(1) lookup) and array (for iteration)
     */
    function enterLottery() external {
        // CHECK: Verify lottery is active
        // Must be >= startBlock AND < endBlock (not <=, end is exclusive)
        if (block.number < lotteryStartBlock || block.number >= lotteryEndBlock) {
            revert LotteryNotActive();
        }

        // CHECK: Verify user hasn't already entered
        if (hasEntered[msg.sender]) {
            revert AlreadyEntered();
        }

        // EFFECTS: Mark user as entered
        hasEntered[msg.sender] = true;

        // Add to participants array for winner selection
        participants.push(msg.sender);

        emit LotteryEntered(msg.sender, block.number);
    }

    /**
     * @notice Select lottery winner using block hash
     * @dev Uses blockhash for pseudo-randomness (NOT secure for high-value lotteries!)
     *
     * SECURITY WARNING: This is NOT production-ready randomness!
     *
     * VULNERABILITIES:
     * 1. Miners can manipulate blockhash by not publishing blocks
     * 2. Miners can see the hash before deciding to publish
     * 3. blockhash is only available for last 256 blocks
     *
     * FOR PRODUCTION: Use Chainlink VRF or similar oracle-based randomness
     *
     * THIS IS FOR EDUCATIONAL PURPOSES ONLY!
     * Perfect for learning, but DO NOT use for real money!
     */
    function selectWinner() external {
        // CHECK: Verify lottery has ended
        if (block.number < lotteryEndBlock) {
            revert LotteryNotEnded();
        }

        // CHECK: Verify there are participants
        if (participants.length == 0) {
            revert NoParticipants();
        }

        // PSEUDO-RANDOM winner selection (NOT SECURE!)
        // Get blockhash of the ending block
        bytes32 blockHash = blockhash(lotteryEndBlock);

        // Convert to uint and take modulo of participants count
        // This gives us a "random" index within the participants array
        uint256 randomIndex = uint256(blockHash) % participants.length;

        // Select winner
        lotteryWinner = participants[randomIndex];

        // Reset hasEntered for all participants (gas intensive, but clean)
        for (uint256 i = 0; i < participants.length; i++) {
            hasEntered[participants[i]] = false;
        }

        emit LotteryWinnerSelected(lotteryWinner, block.number);

        // In a real implementation, transfer prize to winner here
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get current block timestamp
     * @return Current block.timestamp value
     * @dev Useful for debugging and testing
     */
    function getCurrentTimestamp() external view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @notice Get current block number
     * @return Current block.number value
     * @dev Useful for debugging and testing
     */
    function getCurrentBlockNumber() external view returns (uint256) {
        return block.number;
    }

    /**
     * @notice Check if vault is currently locked
     * @return true if locked, false if unlocked
     * @dev Returns true if current time is before unlock time
     */
    function isVaultLocked() external view returns (bool) {
        return block.timestamp < vaultUnlockTime;
    }

    /**
     * @notice Get number of lottery participants
     * @return Number of participants
     */
    function getParticipantCount() external view returns (uint256) {
        return participants.length;
    }

    /**
     * @notice Get all lottery participants
     * @return Array of participant addresses
     * @dev Returns dynamic array, can be gas-intensive for many participants
     */
    function getParticipants() external view returns (address[] memory) {
        return participants;
    }

    /**
     * @notice Check if lottery is currently active
     * @return true if active, false otherwise
     * @dev Lottery is active if current block is in [start, end) range
     */
    function isLotteryActive() external view returns (bool) {
        return block.number >= lotteryStartBlock && block.number < lotteryEndBlock;
    }

    /*//////////////////////////////////////////////////////////////
                         UTILITY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Receive function to accept ETH
     * @dev Allows contract to receive ETH via send/transfer
     */
    receive() external payable {}
}
