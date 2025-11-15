// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Project 33: MEV & Front-Running Simulation
 * @notice Educational contracts demonstrating MEV vulnerabilities and attacks
 * @dev Complete the TODOs to understand MEV extraction techniques
 */

/**
 * @title VulnerableAuction
 * @notice Simple auction contract vulnerable to front-running
 * @dev Anyone can see pending bids and front-run with a higher bid
 */
contract VulnerableAuction {
    address public highestBidder;
    uint256 public highestBid;
    uint256 public auctionEndTime;
    bool public ended;

    mapping(address => uint256) public pendingReturns;

    event BidPlaced(address indexed bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);

    constructor(uint256 _duration) {
        auctionEndTime = block.timestamp + _duration;
    }

    /**
     * @notice Place a bid in the auction
     * @dev TODO: Identify the front-running vulnerability
     *      What information is visible in the mempool?
     *      How can an attacker use this information?
     */
    function placeBid() external payable {
        require(block.timestamp < auctionEndTime, "Auction ended");
        require(msg.value > highestBid, "Bid too low");

        // TODO: Complete the bidding logic
        // 1. Store the previous highest bid for refund
        // 2. Update highest bidder and bid
        // 3. Emit event

        emit BidPlaced(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw a bid that was outbid
     */
    function withdraw() external {
        uint256 amount = pendingReturns[msg.sender];
        require(amount > 0, "No funds to withdraw");

        pendingReturns[msg.sender] = 0;
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    /**
     * @notice End the auction
     */
    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "Auction not ended");
        require(!ended, "Already ended");

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
    }
}

/**
 * @title SimpleAMM
 * @notice Simplified constant product AMM (like Uniswap V2)
 * @dev Vulnerable to sandwich attacks due to price impact
 */
contract SimpleAMM {
    uint256 public reserveA;
    uint256 public reserveB;
    uint256 public constant MINIMUM_LIQUIDITY = 1000;

    mapping(address => uint256) public liquidity;
    uint256 public totalLiquidity;

    event Swap(address indexed user, uint256 amountIn, uint256 amountOut, bool aToB);
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB);

    /**
     * @notice Add liquidity to the pool
     * @dev First liquidity provider sets the initial price
     */
    function addLiquidity(uint256 amountA, uint256 amountB) external payable returns (uint256 liquidityMinted) {
        require(amountA > 0 && amountB > 0, "Invalid amounts");

        if (totalLiquidity == 0) {
            // Initial liquidity
            liquidityMinted = sqrt(amountA * amountB) - MINIMUM_LIQUIDITY;
            totalLiquidity = liquidityMinted + MINIMUM_LIQUIDITY;
        } else {
            // TODO: Calculate liquidity tokens to mint based on existing reserves
            // Hint: liquidityMinted should be proportional to the deposit
            // liquidityMinted = min(amountA * totalLiquidity / reserveA, amountB * totalLiquidity / reserveB)
        }

        liquidity[msg.sender] += liquidityMinted;
        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(msg.sender, amountA, amountB);
    }

    /**
     * @notice Swap token A for token B
     * @dev TODO: Identify the sandwich attack vulnerability
     *      - How does a large swap affect the price?
     *      - What if someone trades before and after this swap?
     */
    function swapAForB(uint256 amountAIn, uint256 minAmountBOut) external returns (uint256 amountBOut) {
        require(amountAIn > 0, "Invalid input");
        require(reserveA > 0 && reserveB > 0, "No liquidity");

        // TODO: Implement constant product formula (x * y = k)
        // 1. Calculate amountBOut using the formula
        // 2. Apply fee (0.3%)
        // 3. Check slippage protection (minAmountBOut)
        // 4. Update reserves
        //
        // Formula: amountBOut = (amountAIn * reserveB) / (reserveA + amountAIn)
        // With fee: amountAIn_withFee = amountAIn * 997 / 1000

        emit Swap(msg.sender, amountAIn, amountBOut, true);
    }

    /**
     * @notice Swap token B for token A
     */
    function swapBForA(uint256 amountBIn, uint256 minAmountAOut) external returns (uint256 amountAOut) {
        require(amountBIn > 0, "Invalid input");
        require(reserveA > 0 && reserveB > 0, "No liquidity");

        // TODO: Implement swap logic (similar to swapAForB)

        emit Swap(msg.sender, amountBIn, amountAOut, false);
    }

    /**
     * @notice Calculate output amount for a given input
     * @dev Uses constant product formula: x * y = k
     */
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        public
        pure
        returns (uint256 amountOut)
    {
        require(amountIn > 0, "Invalid input");
        require(reserveIn > 0 && reserveOut > 0, "Invalid reserves");

        // TODO: Implement the calculation
        // amountIn_withFee = amountIn * 997
        // amountOut = (amountIn_withFee * reserveOut) / (reserveIn * 1000 + amountIn_withFee)
    }

    /**
     * @notice Get current price (how much B for 1 A)
     */
    function getPrice() external view returns (uint256) {
        require(reserveA > 0, "No liquidity");
        return (reserveB * 1e18) / reserveA;
    }

    /**
     * @notice Square root function (Babylonian method)
     */
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
}

/**
 * @title FrontRunner
 * @notice Template for a front-running bot
 * @dev Observes pending transactions and submits higher gas price TXs
 */
contract FrontRunner {
    address public owner;
    address public targetAuction;

    event FrontRunAttempt(address indexed target, uint256 bidAmount, uint256 gasPrice);

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Front-run a bid in an auction
     * @param auction The auction contract to target
     * @param targetBid The bid amount we observed in the mempool
     * @dev TODO: Implement front-running logic
     *      1. Calculate a slightly higher bid
     *      2. Submit with higher gas price
     *      3. Ensure profitability (bid increase < expected profit)
     */
    function frontRunBid(address auction, uint256 targetBid) external payable {
        require(msg.sender == owner, "Not owner");

        // TODO: Implement front-running logic
        // 1. Calculate outbid amount (targetBid + small increase)
        // 2. Call auction.placeBid() with higher amount
        // 3. Ensure this TX has higher gas price than target

        emit FrontRunAttempt(auction, targetBid, tx.gasprice);
    }

    /**
     * @notice Withdraw profits
     */
    function withdraw() external {
        require(msg.sender == owner, "Not owner");
        (bool success,) = owner.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    receive() external payable {}
}

/**
 * @title SandwichAttacker
 * @notice Template for sandwich attack bot
 * @dev Frontruns and backruns victim's DEX swap to extract profit
 */
contract SandwichAttacker {
    address public owner;
    SimpleAMM public targetDEX;

    event SandwichAttempt(uint256 frontRunAmount, uint256 backRunAmount, uint256 profit);

    constructor(address _dex) {
        owner = msg.sender;
        targetDEX = SimpleAMM(_dex);
    }

    /**
     * @notice Execute sandwich attack
     * @param victimAmountIn Amount victim is swapping
     * @param frontRunAmount How much to swap in front-run
     * @dev TODO: Implement sandwich attack logic
     *
     * Attack structure:
     * 1. Front-run: Buy token B (pushes price up)
     * 2. Victim's swap executes (pays inflated price)
     * 3. Back-run: Sell token B (profit from price increase)
     */
    function executeSandwich(uint256 victimAmountIn, uint256 frontRunAmount) external payable {
        require(msg.sender == owner, "Not owner");

        // TODO: Implement sandwich attack
        // Step 1: Front-run - swap A for B
        //   - This increases the price of B
        //   - Store the amount of B received

        // Step 2: (Victim's transaction executes here)
        //   - Victim swaps at inflated price
        //   - Price of B increases further

        // Step 3: Back-run - swap B back to A
        //   - Sell the B we bought in step 1
        //   - Should receive more A than we spent
        //   - Calculate profit

        // Step 4: Verify profitability
        //   - profit = final balance - initial balance - gas costs
    }

    /**
     * @notice Calculate potential profit from sandwich attack
     * @param victimAmountIn Victim's swap amount
     * @param frontRunAmount Our front-run amount
     * @return estimatedProfit Estimated profit in token A
     */
    function calculateProfit(uint256 victimAmountIn, uint256 frontRunAmount)
        external
        view
        returns (uint256 estimatedProfit)
    {
        // TODO: Simulate the sandwich attack and calculate profit
        // 1. Calculate reserves after front-run
        // 2. Calculate reserves after victim's swap
        // 3. Calculate back-run output
        // 4. Calculate profit (back-run output - front-run input)
    }

    /**
     * @notice Withdraw profits
     */
    function withdraw() external {
        require(msg.sender == owner, "Not owner");
        (bool success,) = owner.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    receive() external payable {}
}

/**
 * @title CommitRevealAuction
 * @notice Auction with commit-reveal scheme to prevent front-running
 * @dev TODO: Implement commit-reveal pattern
 *
 * How it works:
 * 1. Commit phase: Users submit hash of (bid + salt)
 * 2. Reveal phase: Users reveal actual bid and salt
 * 3. Contract verifies hash matches and processes bid
 */
contract CommitRevealAuction {
    struct Commitment {
        bytes32 commitHash;
        uint256 commitTime;
        bool revealed;
    }

    mapping(address => Commitment) public commitments;
    mapping(address => uint256) public bids;
    mapping(address => uint256) public deposits;

    address public highestBidder;
    uint256 public highestBid;

    uint256 public commitEndTime;
    uint256 public revealEndTime;
    uint256 public constant MIN_COMMIT_DURATION = 1 hours;

    bool public ended;

    event CommitPlaced(address indexed bidder, bytes32 commitHash);
    event BidRevealed(address indexed bidder, uint256 bid);
    event AuctionEnded(address winner, uint256 amount);

    constructor(uint256 _commitDuration, uint256 _revealDuration) {
        require(_commitDuration >= MIN_COMMIT_DURATION, "Commit too short");
        commitEndTime = block.timestamp + _commitDuration;
        revealEndTime = commitEndTime + _revealDuration;
    }

    /**
     * @notice Commit to a bid without revealing the amount
     * @param commitHash Hash of (bidAmount, salt, sender)
     * @dev TODO: Implement commit logic
     *      - Store the commit hash
     *      - Record commit time
     *      - Accept deposit (must be >= actual bid)
     */
    function commit(bytes32 commitHash) external payable {
        require(block.timestamp < commitEndTime, "Commit phase ended");
        require(commitments[msg.sender].commitHash == bytes32(0), "Already committed");

        // TODO: Store commitment
    }

    /**
     * @notice Reveal your bid
     * @param bidAmount The actual bid amount
     * @param salt Random salt used in commit
     * @dev TODO: Implement reveal logic
     *      - Verify hash matches commitment
     *      - Check deposit >= bidAmount
     *      - Update highest bid if necessary
     */
    function reveal(uint256 bidAmount, bytes32 salt) external {
        require(block.timestamp >= commitEndTime, "Commit phase not ended");
        require(block.timestamp < revealEndTime, "Reveal phase ended");
        require(!commitments[msg.sender].revealed, "Already revealed");

        // TODO: Verify and process reveal
        // 1. Calculate expected hash: keccak256(abi.encode(bidAmount, salt, msg.sender))
        // 2. Verify it matches stored commitment
        // 3. Check deposit >= bidAmount
        // 4. Update highest bid if this is higher
        // 5. Mark as revealed
    }

    /**
     * @notice Generate commit hash (helper for users)
     */
    function generateCommitHash(uint256 bidAmount, bytes32 salt, address bidder)
        external
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(bidAmount, salt, bidder));
    }

    /**
     * @notice End auction and determine winner
     */
    function endAuction() external {
        require(block.timestamp >= revealEndTime, "Reveal not ended");
        require(!ended, "Already ended");

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
    }

    /**
     * @notice Withdraw losing bids or excess deposit
     */
    function withdraw() external {
        require(ended, "Auction not ended");
        require(msg.sender != highestBidder, "Winner cannot withdraw");

        uint256 amount = deposits[msg.sender];
        require(amount > 0, "No deposit");

        deposits[msg.sender] = 0;
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
}

/**
 * @title ProtectedDEX
 * @notice AMM with slippage protection and other MEV mitigations
 * @dev TODO: Implement protections against sandwich attacks
 */
contract ProtectedDEX {
    uint256 public reserveA;
    uint256 public reserveB;

    uint256 public constant MAX_PRICE_IMPACT = 100; // 1% max price impact
    uint256 public constant PRICE_IMPACT_DENOMINATOR = 10000;

    event Swap(address indexed user, uint256 amountIn, uint256 amountOut, bool aToB);

    /**
     * @notice Swap with strict slippage protection
     * @param amountAIn Input amount
     * @param minAmountBOut Minimum acceptable output
     * @param maxPriceImpact Maximum acceptable price impact (in basis points)
     * @dev TODO: Implement enhanced slippage protection
     */
    function swapAForB(uint256 amountAIn, uint256 minAmountBOut, uint256 maxPriceImpact)
        external
        returns (uint256 amountBOut)
    {
        // TODO: Implement swap with protections
        // 1. Calculate output amount
        // 2. Check minAmountBOut requirement
        // 3. Calculate price impact
        // 4. Ensure price impact <= maxPriceImpact
        // 5. Execute swap
    }

    /**
     * @notice Calculate price impact of a trade
     * @param amountIn Input amount
     * @param reserveIn Input reserve
     * @param reserveOut Output reserve
     * @return priceImpact Price impact in basis points
     */
    function calculatePriceImpact(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        public
        pure
        returns (uint256 priceImpact)
    {
        // TODO: Calculate price impact
        // priceImpact = (amountIn / (reserveIn + amountIn)) * PRICE_IMPACT_DENOMINATOR
    }

    /**
     * @notice Add liquidity
     */
    function addLiquidity(uint256 amountA, uint256 amountB) external payable {
        require(amountA > 0 && amountB > 0, "Invalid amounts");
        reserveA += amountA;
        reserveB += amountB;
    }
}

/**
 * @title BatchAuction
 * @notice Batch auction system for fair price discovery
 * @dev All orders in a batch execute at the same clearing price
 * TODO: Implement batch auction mechanism
 */
contract BatchAuction {
    struct Order {
        address user;
        uint256 amount;
        uint256 price; // Maximum price willing to pay
        bool filled;
    }

    Order[] public orders;
    uint256 public batchEndTime;
    uint256 public constant BATCH_DURATION = 5 minutes;

    bool public batchExecuted;
    uint256 public clearingPrice;

    event OrderSubmitted(address indexed user, uint256 amount, uint256 maxPrice);
    event BatchExecuted(uint256 clearingPrice, uint256 totalVolume);

    constructor() {
        batchEndTime = block.timestamp + BATCH_DURATION;
    }

    /**
     * @notice Submit an order for the current batch
     * @param amount Amount to buy
     * @param maxPrice Maximum price willing to pay per unit
     * @dev TODO: Implement order submission
     */
    function submitOrder(uint256 amount, uint256 maxPrice) external payable {
        require(block.timestamp < batchEndTime, "Batch ended");
        require(amount > 0 && maxPrice > 0, "Invalid order");

        // TODO: Store order
    }

    /**
     * @notice Execute the batch at clearing price
     * @dev TODO: Implement batch execution
     *      1. Calculate clearing price
     *      2. Fill all orders at clearing price
     *      3. Refund excess payments
     */
    function executeBatch() external {
        require(block.timestamp >= batchEndTime, "Batch not ended");
        require(!batchExecuted, "Already executed");

        // TODO: Execute batch
        // 1. Sort orders by price (descending)
        // 2. Calculate clearing price where supply meets demand
        // 3. Fill orders at clearing price
        // 4. Emit event

        batchExecuted = true;
    }

    /**
     * @notice Calculate clearing price for current orders
     * @dev TODO: Implement clearing price calculation
     */
    function calculateClearingPrice() public view returns (uint256) {
        // TODO: Calculate the price where total buy amount equals total sell amount
        // For simplicity, can use median price or volume-weighted average
    }
}

/**
 * @dev Additional TODOs and learning objectives:
 *
 * 1. VULNERABILITY ANALYSIS
 *    - Identify which contracts are vulnerable to front-running
 *    - Explain why commit-reveal prevents front-running
 *    - Compare gas costs of vulnerable vs protected contracts
 *
 * 2. ATTACK SIMULATIONS
 *    - Implement a profitable sandwich attack
 *    - Calculate minimum victim trade size for profitability
 *    - Account for gas costs in profit calculations
 *
 * 3. DEFENSE MECHANISMS
 *    - Implement full commit-reveal auction
 *    - Add deadline checks to prevent staleness
 *    - Create batch auction with fair clearing price
 *
 * 4. ECONOMIC ANALYSIS
 *    - Calculate MEV extracted in each attack
 *    - Determine break-even points for attackers
 *    - Analyze victim losses vs attacker profits
 *
 * 5. ADVANCED TOPICS (Optional)
 *    - Implement Flashbots bundle simulation
 *    - Create decoy transaction system
 *    - Design submarine send mechanism
 *    - Build fair ordering protocol
 */
