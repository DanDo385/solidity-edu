// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Project13 - Block Properties & Time Logic
 * @notice Learn to work with block.timestamp, block.number, and time-based logic
 * @dev This contract teaches safe time manipulation patterns in Solidity
 *
 * KEY CONCEPTS:
 * - block.timestamp: Unix timestamp in seconds, can be manipulated ~15 seconds by miners
 * - block.number: Current block number, more predictable than timestamp
 * - Rate limiting: Restrict action frequency
 * - Cooldown periods: Enforce waiting times
 * - Time-locked actions: Prevent execution until specific time
 *
 * SECURITY NOTES:
 * - Never use block.timestamp for randomness (miners can manipulate)
 * - Use >= instead of == for time comparisons
 * - For periods >1 hour, timestamp manipulation is negligible
 * - For short periods, consider using block.number instead
 */
contract Project13 {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    // Owner address
    address public owner;

    // TimeLockedVault variables
    uint256 public vaultUnlockTime;
    uint256 public vaultBalance;

    // RateLimiter variables
    mapping(address => uint256) public lastActionTime;
    uint256 public constant RATE_LIMIT_DURATION = 1 hours;

    // Cooldown variables
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
     * TODO: Implement this function
     * Requirements:
     * 1. Must receive ETH (payable)
     * 2. Calculate unlockTime = block.timestamp + lockDuration
     * 3. Update vaultUnlockTime and vaultBalance
     * 4. Emit VaultLocked event
     *
     * LEARNING: block.timestamp is perfect for lock periods measured in hours/days
     * A 15-second manipulation is negligible for a 7-day lock period
     */
    function lockInVault(uint256 lockDuration) external payable {
        // TODO: Implement vault locking logic
    }

    /**
     * @notice Withdraw ETH from the vault after unlock time
     * @dev Demonstrates safe time comparison with >=
     *
     * TODO: Implement this function
     * Requirements:
     * 1. Check that block.timestamp >= vaultUnlockTime (use >= not ==!)
     * 2. Check that vaultBalance > 0
     * 3. Store vaultBalance in local variable
     * 4. Reset vaultBalance to 0 (prevent reentrancy)
     * 5. Transfer ETH to msg.sender
     * 6. Emit VaultWithdrawn event
     *
     * SECURITY: Always use >= for time comparisons, never ==
     * The exact second may never occur!
     */
    function withdrawFromVault() external {
        // TODO: Implement withdrawal logic with time check
    }

    /*//////////////////////////////////////////////////////////////
                         RATE LIMITER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Perform an action that is rate-limited to once per hour
     * @dev Demonstrates rate limiting pattern to prevent spam
     *
     * TODO: Implement this function
     * Requirements:
     * 1. Check if block.timestamp >= lastActionTime[msg.sender] + RATE_LIMIT_DURATION
     * 2. If not enough time has passed, revert with RateLimitActive()
     * 3. Update lastActionTime[msg.sender] = block.timestamp
     * 4. Emit ActionPerformed event
     *
     * LEARNING: Rate limiting prevents users from performing actions too frequently
     * Common in DeFi for claiming rewards, voting, etc.
     */
    function performRateLimitedAction() external {
        // TODO: Implement rate limiting logic
    }

    /**
     * @notice Get remaining time until action is available again
     * @return seconds until action is available (0 if available now)
     *
     * TODO: Implement this function
     * Requirements:
     * 1. Calculate when next action is allowed: lastActionTime[user] + RATE_LIMIT_DURATION
     * 2. If block.timestamp >= next allowed time, return 0
     * 3. Otherwise, return (next allowed time - block.timestamp)
     */
    function getRemainingCooldown(address user) external view returns (uint256) {
        // TODO: Implement cooldown calculation
        return 0; // Placeholder
    }

    /*//////////////////////////////////////////////////////////////
                         COOLDOWN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initiate a cooldown period (e.g., before unstaking)
     * @dev Two-step process: initiate cooldown, then execute after period
     *
     * TODO: Implement this function
     * Requirements:
     * 1. Check that user doesn't already have active cooldown
     * 2. Set cooldownStart[msg.sender] = block.timestamp
     * 3. Set cooldownActive[msg.sender] = true
     * 4. Emit CooldownInitiated event
     *
     * LEARNING: Cooldowns are common in staking protocols
     * They prevent instant unstaking and protect protocol liquidity
     */
    function initiateCooldown() external {
        // TODO: Implement cooldown initiation
    }

    /**
     * @notice Execute action after cooldown period has finished
     * @dev Completes the two-step process
     *
     * TODO: Implement this function
     * Requirements:
     * 1. Check that cooldown was initiated (cooldownActive[msg.sender] == true)
     * 2. Check that block.timestamp >= cooldownStart[msg.sender] + COOLDOWN_DURATION
     * 3. Reset cooldownActive[msg.sender] = false
     * 4. Reset cooldownStart[msg.sender] = 0
     * 5. Emit CooldownCompleted event
     *
     * SECURITY: Two-step process prevents accidental instant execution
     */
    function executeAfterCooldown() external {
        // TODO: Implement cooldown completion logic
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
     * TODO: Implement this function
     * Requirements:
     * 1. Only owner can call this
     * 2. Set vestingBeneficiary = beneficiary
     * 3. Set vestingStartTime = block.timestamp
     * 4. Set vestingDuration = duration
     * 5. Set vestingTotalAmount = totalAmount
     * 6. Set vestingReleased = 0
     * 7. Emit VestingInitialized event
     *
     * LEARNING: Vesting is crucial for token distribution
     * Prevents dumps by releasing tokens gradually
     */
    function initializeVesting(
        address beneficiary,
        uint256 totalAmount,
        uint256 duration
    ) external onlyOwner {
        // TODO: Implement vesting initialization
    }

    /**
     * @notice Calculate how many tokens have vested so far
     * @return Amount of tokens vested (including already released)
     * @dev Linear vesting formula: (totalAmount * timeElapsed) / totalDuration
     *
     * TODO: Implement this function
     * Requirements:
     * 1. If block.timestamp < vestingStartTime, return 0 (not started)
     * 2. If block.timestamp >= vestingStartTime + vestingDuration, return vestingTotalAmount (fully vested)
     * 3. Otherwise, calculate: (vestingTotalAmount * elapsed) / vestingDuration
     *    where elapsed = block.timestamp - vestingStartTime
     *
     * LEARNING: Linear vesting is most common, but cliff vesting also exists
     */
    function calculateVestedAmount() public view returns (uint256) {
        // TODO: Implement vesting calculation
        return 0; // Placeholder
    }

    /**
     * @notice Release vested tokens to beneficiary
     * @return amount Amount of tokens released
     *
     * TODO: Implement this function
     * Requirements:
     * 1. Calculate vested amount using calculateVestedAmount()
     * 2. Calculate releasable = vestedAmount - vestingReleased
     * 3. Require releasable > 0
     * 4. Update vestingReleased += releasable
     * 5. Emit TokensReleased event
     * 6. Return releasable amount
     *
     * NOTE: In a real implementation, this would transfer tokens
     * For this exercise, we just track the amounts
     */
    function releaseVestedTokens() external returns (uint256) {
        // TODO: Implement token release logic
        return 0; // Placeholder
    }

    /*//////////////////////////////////////////////////////////////
                    BLOCK-BASED LOTTERY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Start a new lottery that runs for specified number of blocks
     * @param durationInBlocks How many blocks the lottery will run
     * @dev Uses block.number for more predictable timing
     *
     * TODO: Implement this function
     * Requirements:
     * 1. Only owner can call
     * 2. Set lotteryStartBlock = block.number
     * 3. Set lotteryEndBlock = block.number + durationInBlocks
     * 4. Reset participants array (delete participants)
     * 5. Reset lotteryWinner = address(0)
     *
     * LEARNING: block.number is more predictable than timestamp
     * Good for lottery mechanics where predictability matters
     */
    function startLottery(uint256 durationInBlocks) external onlyOwner {
        // TODO: Implement lottery start logic
    }

    /**
     * @notice Enter the lottery
     * @dev Participants can enter during the lottery period
     *
     * TODO: Implement this function
     * Requirements:
     * 1. Check block.number >= lotteryStartBlock and block.number < lotteryEndBlock
     * 2. Check that msg.sender hasn't already entered (hasEntered[msg.sender] == false)
     * 3. Mark hasEntered[msg.sender] = true
     * 4. Add msg.sender to participants array
     * 5. Emit LotteryEntered event
     */
    function enterLottery() external {
        // TODO: Implement lottery entry logic
    }

    /**
     * @notice Select lottery winner using block hash
     * @dev Uses blockhash for pseudo-randomness (NOT secure for high-value lotteries!)
     *
     * TODO: Implement this function
     * Requirements:
     * 1. Check that block.number >= lotteryEndBlock (lottery has ended)
     * 2. Check that participants.length > 0
     * 3. Generate random index: uint256(blockhash(lotteryEndBlock)) % participants.length
     * 4. Set lotteryWinner = participants[randomIndex]
     * 5. Emit LotteryWinnerSelected event
     *
     * SECURITY WARNING: This is NOT secure for real lotteries!
     * Miners can manipulate blockhash. Use Chainlink VRF for production.
     * This is for educational purposes only!
     */
    function selectWinner() external {
        // TODO: Implement winner selection logic
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get current block timestamp
     * @return Current block.timestamp value
     */
    function getCurrentTimestamp() external view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @notice Get current block number
     * @return Current block.number value
     */
    function getCurrentBlockNumber() external view returns (uint256) {
        return block.number;
    }

    /**
     * @notice Check if vault is currently locked
     * @return true if locked, false if unlocked
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
     */
    function getParticipants() external view returns (address[] memory) {
        return participants;
    }

    /**
     * @notice Check if lottery is currently active
     * @return true if active, false otherwise
     */
    function isLotteryActive() external view returns (bool) {
        return block.number >= lotteryStartBlock && block.number < lotteryEndBlock;
    }

    /*//////////////////////////////////////////////////////////////
                         UTILITY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Receive function to accept ETH
     */
    receive() external payable {}
}
