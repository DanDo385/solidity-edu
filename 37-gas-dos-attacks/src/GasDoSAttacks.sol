// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Project 37: Gas DoS Attacks
 * @notice Educational contracts demonstrating gas-based denial of service attacks
 * @dev These contracts are intentionally vulnerable - DO NOT use in production
 */

/**
 * @title VulnerableAirdrop
 * @notice Demonstrates DoS via unbounded loop iteration
 */
contract VulnerableAirdrop {
    address[] public recipients;
    mapping(address => bool) public hasReceived;

    event AirdropDistributed(address indexed recipient, uint256 amount);

    // TODO: Implement a vulnerable airdrop function that:
    // 1. Iterates through all recipients
    // 2. Sends 1 ether to each recipient
    // 3. Marks them as having received the airdrop
    // VULNERABILITY: Unbounded loop will fail when recipients array grows too large
    function distributeAirdrop() public {
        // TODO: Your code here
        // Hint: Use a for loop over recipients array
    }

    // TODO: Implement function to add recipients
    // VULNERABILITY: No bounds checking allows unlimited growth
    function addRecipient(address _recipient) public {
        // TODO: Your code here
        // Requirements:
        // - Prevent duplicate recipients
        // - Add to recipients array
    }

    // Helper function to fund the contract
    receive() external payable {}

    function getRecipientCount() public view returns (uint256) {
        return recipients.length;
    }
}

/**
 * @title VulnerableAuction
 * @notice Demonstrates DoS via malicious bidder blocking refunds
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

    // TODO: Implement vulnerable bid function that:
    // 1. Requires bid higher than current highest
    // 2. Refunds the previous highest bidder using transfer()
    // 3. Updates highest bid and bidder
    // VULNERABILITY: Malicious bidder can block refunds with reverting fallback
    function bid() public payable {
        // TODO: Your code here
        // Requirements:
        // - Check auction hasn't ended
        // - Require msg.value > highestBid
        // - Refund previous bidder (this is the vulnerable part!)
        // - Update state
    }

    function endAuction() public {
        require(block.timestamp >= auctionEndTime, "Auction not ended");
        emit AuctionEnded(highestBidder, highestBid);
    }
}

/**
 * @title MaliciousBidder
 * @notice Attacker contract that blocks refunds
 */
contract MaliciousBidder {
    VulnerableAuction public auction;

    constructor(address _auction) {
        auction = VulnerableAuction(_auction);
    }

    // TODO: Implement attack function that:
    // 1. Places a bid on the auction
    function attack() public payable {
        // TODO: Your code here
        // Hint: Call auction.bid() with msg.value
    }

    // TODO: Implement malicious receive function that:
    // 1. Reverts to block refunds
    // ATTACK: This prevents new bidders from placing bids
    receive() external payable {
        // TODO: Your code here
        // Hint: Simply revert to block the auction
    }
}

/**
 * @title VulnerableMassPayment
 * @notice Demonstrates DoS via block gas limit
 */
contract VulnerableMassPayment {
    address[] public payees;
    mapping(address => uint256) public payments;

    event PaymentAdded(address indexed payee, uint256 amount);
    event PaymentSent(address indexed payee, uint256 amount);

    // TODO: Implement function to add payment
    function addPayment(address _payee) public payable {
        // TODO: Your code here
        // Requirements:
        // - Add payee to array if not already present
        // - Accumulate payment amount
    }

    // TODO: Implement vulnerable mass payment function that:
    // 1. Iterates through all payees
    // 2. Sends their accumulated payment
    // 3. Resets their balance
    // VULNERABILITY: Will exceed block gas limit with too many payees
    function executePayments() public {
        // TODO: Your code here
        // Hint: Loop through payees array and transfer payments
    }

    function getPayeeCount() public view returns (uint256) {
        return payees.length;
    }
}

/**
 * @title ExpensiveFallbackRecipient
 * @notice Contract with expensive fallback that causes DoS
 */
contract ExpensiveFallbackRecipient {
    uint256[] public data;

    event ReceivedPayment(address sender, uint256 amount);

    // TODO: Implement expensive receive function that:
    // 1. Performs expensive operations (array pushes, storage writes)
    // 2. Consumes more than the default gas stipend (2300 gas)
    // ATTACK: When used as recipient in transfers, causes DoS
    receive() external payable {
        // TODO: Your code here
        // Hint: Push data to storage array in a loop
        // This will consume way more than 2300 gas
    }

    function getDataLength() public view returns (uint256) {
        return data.length;
    }
}

/**
 * @title VulnerableDistributor
 * @notice Vulnerable reward distributor with push payments
 */
contract VulnerableDistributor {
    address[] public stakeholders;
    mapping(address => uint256) public shares;
    uint256 public totalShares;

    event StakeholderAdded(address indexed stakeholder, uint256 shares);
    event RewardsDistributed(uint256 totalAmount);
    event RewardSent(address indexed recipient, uint256 amount);

    // TODO: Implement function to add stakeholder
    function addStakeholder(address _stakeholder, uint256 _shares) public {
        // TODO: Your code here
        // Requirements:
        // - Prevent duplicate stakeholders
        // - Add to stakeholders array
        // - Track shares
    }

    // TODO: Implement vulnerable distribution function that:
    // 1. Calculates reward per share
    // 2. Iterates through all stakeholders
    // 3. Sends proportional rewards using transfer()
    // VULNERABILITIES:
    // - Unbounded loop
    // - Push payments can be blocked
    // - Single failure blocks entire distribution
    function distributeRewards() public payable {
        // TODO: Your code here
        // Hint: Loop through stakeholders and send (msg.value * shares / totalShares)
    }

    function getStakeholderCount() public view returns (uint256) {
        return stakeholders.length;
    }
}

/**
 * @title GriefingAttacker
 * @notice Demonstrates griefing attack patterns
 */
contract GriefingAttacker {
    // TODO: Implement various griefing attack methods
    // Examples:
    // 1. Placing minimal bids repeatedly to waste gas
    // 2. Adding numerous small stakes to bloat arrays
    // 3. Reverting in fallback to block operations

    // TODO: Implement attack on VulnerableDistributor
    function attackDistributor(address _distributor) public {
        // TODO: Your code here
        // Strategy: Add this contract as stakeholder with small share
        // Then revert in receive() to block entire distribution
    }

    // TODO: Implement malicious receive
    receive() external payable {
        // TODO: Your code here
        // Revert to cause griefing
    }
}

/**
 * @title SafeAirdropWithPagination
 * @notice Safe implementation using pagination
 */
contract SafeAirdropWithPagination {
    address[] public recipients;
    mapping(address => bool) public hasReceived;
    uint256 public constant MAX_BATCH_SIZE = 50;

    event AirdropDistributed(address indexed recipient, uint256 amount);

    // TODO: Implement safe batched distribution that:
    // 1. Takes start and end indices as parameters
    // 2. Validates batch size doesn't exceed MAX_BATCH_SIZE
    // 3. Distributes only to the specified range
    // MITIGATION: Bounded loop prevents gas limit DoS
    function distributeBatch(uint256 _start, uint256 _end) public {
        // TODO: Your code here
        // Requirements:
        // - Validate _end <= recipients.length
        // - Validate _end > _start
        // - Validate batch size <= MAX_BATCH_SIZE
        // - Loop from _start to _end
    }

    function addRecipient(address _recipient) public {
        require(!hasReceived[_recipient], "Already added");
        recipients.push(_recipient);
    }

    receive() external payable {}

    function getRecipientCount() public view returns (uint256) {
        return recipients.length;
    }
}

/**
 * @title SafeAuctionWithPullPayments
 * @notice Safe auction using pull payment pattern
 */
contract SafeAuctionWithPullPayments {
    address public highestBidder;
    uint256 public highestBid;
    uint256 public auctionEndTime;

    // Pull payment pattern - users withdraw their own refunds
    mapping(address => uint256) public pendingReturns;

    event NewHighestBid(address indexed bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);
    event RefundAvailable(address indexed bidder, uint256 amount);

    constructor(uint256 _duration) {
        auctionEndTime = block.timestamp + _duration;
    }

    // TODO: Implement safe bid function that:
    // 1. Requires bid higher than current highest
    // 2. Records pending refund instead of sending it
    // 3. Updates highest bid and bidder
    // MITIGATION: Pull pattern prevents blocking attacks
    function bid() public payable {
        // TODO: Your code here
        // Requirements:
        // - Check auction hasn't ended
        // - Require msg.value > highestBid
        // - Add current highest bid to pendingReturns[highestBidder]
        // - Update highestBid and highestBidder
    }

    // TODO: Implement withdrawal function that:
    // 1. Checks pending returns for msg.sender
    // 2. Resets pending returns
    // 3. Sends the funds
    // MITIGATION: Each user controls their own withdrawal
    function withdraw() public {
        // TODO: Your code here
        // Requirements:
        // - Get amount from pendingReturns[msg.sender]
        // - Require amount > 0
        // - Reset pendingReturns[msg.sender] before transfer (CEI pattern)
        // - Transfer the amount
    }

    function endAuction() public {
        require(block.timestamp >= auctionEndTime, "Auction not ended");
        emit AuctionEnded(highestBidder, highestBid);
    }
}

/**
 * @title SafeMassPaymentWithPull
 * @notice Safe mass payment using pull pattern
 */
contract SafeMassPaymentWithPull {
    mapping(address => uint256) public pendingWithdrawals;

    event PaymentAdded(address indexed payee, uint256 amount);
    event PaymentWithdrawn(address indexed payee, uint256 amount);

    // TODO: Implement function to add payment
    function addPayment(address _payee) public payable {
        // TODO: Your code here
        // Simply accumulate payment in mapping
    }

    // TODO: Implement withdrawal function
    // MITIGATION: Pull pattern - each user withdraws independently
    function withdraw() public {
        // TODO: Your code here
        // Requirements:
        // - Get amount from pendingWithdrawals[msg.sender]
        // - Require amount > 0
        // - Reset before transfer (CEI pattern)
        // - Transfer amount
    }

    function getPendingAmount(address _payee) public view returns (uint256) {
        return pendingWithdrawals[_payee];
    }
}
