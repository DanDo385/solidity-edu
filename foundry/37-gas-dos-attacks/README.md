# Project 37: Gas DoS Attacks

A comprehensive educational project demonstrating gas-based denial of service (DoS) attacks in Solidity and their mitigations.

## Overview

Gas DoS attacks exploit the gas mechanics of the Ethereum Virtual Machine to make contracts unusable or significantly degrade their performance. This project explores various DoS attack vectors and teaches secure coding patterns to prevent them.

## Learning Objectives

- Understand unbounded loops and their dangers
- Learn about block gas limit constraints
- Recognize expensive fallback function vulnerabilities
- Understand griefing attacks and economic DoS
- Master push vs pull payment patterns
- Identify msg.sender blocking attacks
- Implement effective mitigation strategies

## DoS Attack Vectors

### 1. Unbounded Loops and Iteration: The Gas Limit Trap

**FIRST PRINCIPLES: Block Gas Limits**

Loops that iterate over dynamically-sized arrays can grow beyond the block gas limit, making functions permanently unusable. This is a fundamental DoS vector!

**CONNECTION TO PROJECT 06 & 12**:
- **Project 06**: We learned about array iteration costs (O(n) gas)
- **Project 12**: We learned about push vs pull patterns
- **Project 37**: Unbounded loops can exceed block gas limit (DoS)!

**UNDERSTANDING THE VULNERABILITY**:

**VULNERABLE PATTERN**:
```solidity
address[] public participants;  // From Project 01: Dynamic array

function distributeRewards() public {
    for (uint i = 0; i < participants.length; i++) {
        // Gas cost grows with array size
        payable(participants[i]).transfer(1 ether);  // ~23,000 gas per transfer
    }
}
```

**GAS COST ANALYSIS** (from Project 01, 02, & 06 knowledge):

```
Gas Cost Per Iteration:
┌─────────────────────────────────────────┐
│ Loop overhead: ~10 gas                 │
│ Array access: ~100 gas (SLOAD)         │
│ Transfer: ~23,000 gas                  │
│ Total per iteration: ~23,110 gas        │
│                                          │
│ Block gas limit: ~30,000,000 gas        │
│ Max iterations: ~1,300 iterations       │ ← Can exceed this!
└─────────────────────────────────────────┘
```

**IMPACT**:
- Function becomes uncallable when array grows too large
- Permanent DoS if no alternative access pattern exists
- Attackers can deliberately add entries to bloat arrays

**ATTACK SCENARIO**:

```
DoS Attack Flow:
┌─────────────────────────────────────────┐
│ Attacker calls addParticipant()        │
│   (if public or accessible)            │
│   ↓                                      │
│ Attacker adds 2,000 addresses          │ ← Bloat array
│   ↓                                      │
│ Legitimate user calls distributeRewards()│
│   ↓                                      │
│ Loop tries to process 2,000 addresses   │
│   ↓                                      │
│ Gas required: 2,000 × 23,110 = 46M gas  │ ← Exceeds limit!
│   ↓                                      │
│ Transaction REVERTS                      │ ← DoS achieved!
│   ↓                                      │
│ Function permanently unusable! 💥       │
└─────────────────────────────────────────┘
```

**THE FIX** (Pull Pattern from Project 12):

```solidity
// ✅ SAFE: Pull pattern (from Project 12)
mapping(address => uint256) public pendingRewards;  // From Project 01!

function distributeRewards(address[] calldata recipients, uint256[] calldata amounts) public {
    // Update mappings only (cheap!)
    for (uint i = 0; i < recipients.length; i++) {
        pendingRewards[recipients[i]] += amounts[i];  // ~5,000 gas per update
    }
}

function withdrawReward() public {
    // Users withdraw individually (no DoS!)
    uint256 amount = pendingRewards[msg.sender];
    pendingRewards[msg.sender] = 0;
    payable(msg.sender).transfer(amount);
}
```

**GAS COMPARISON**:

**Push Pattern** (Vulnerable):
- 1,000 recipients: ~23,110,000 gas (exceeds limit!)
- DoS risk: HIGH

**Pull Pattern** (Safe):
- Distributor: ~5,000,000 gas (updates only)
- Users: ~23,000 gas each (withdraw individually)
- DoS risk: NONE

**REAL-WORLD ANALOGY**: 
Like trying to deliver mail to everyone in a city at once (push) vs having people pick up their mail (pull). Push can fail if there's too much mail, pull scales infinitely!

**Mitigation:**
- Use pull payment patterns instead of push
- Implement pagination for large datasets
- Set maximum bounds on loops
- Use mappings with external indexing when appropriate

### 2. Block Gas Limit DoS

**Vulnerability:**
Operations that consume gas proportional to user-controlled data can be forced to exceed the block gas limit.

**Example:**
```solidity
mapping(address => uint) public balances;
address[] public users;

function withdrawAll() public {
    for (uint i = 0; i < users.length; i++) {
        if (balances[users[i]] > 0) {
            payable(users[i]).transfer(balances[users[i]]);
        }
    }
}
```

**Impact:**
- Critical functions become permanently disabled
- Funds can be locked in the contract
- Service degradation as operations become expensive

**Mitigation:**
- Batch processing with user-specified limits
- Pull over push patterns
- Separate state modification from external calls

### 3. Expensive Fallback Functions

**Vulnerability:**
Contracts with expensive fallback/receive functions can cause DoS when they are recipients of transfers.

**Example:**
```solidity
contract ExpensiveFallback {
    uint[] public data;

    receive() external payable {
        // Expensive operation in fallback
        for (uint i = 0; i < 1000; i++) {
            data.push(i);
        }
    }
}
```

**Impact:**
- Auctions can't send refunds to previous highest bidder
- Payment distributions fail
- Legitimate transfers revert

**Mitigation:**
- Use pull payment patterns
- Limit gas for external calls with `.call{gas: X}`
- Handle failed transfers gracefully
- Emit events and allow manual withdrawal

### 4. Griefing Attacks

**Vulnerability:**
Attackers can waste gas or cause financial harm without direct benefit, just to disrupt the protocol.

**Example:**
```solidity
function bid() public payable {
    require(msg.value > highestBid);
    // Refund previous bidder - can be griefed
    payable(previousBidder).transfer(previousBid);
    highestBid = msg.value;
}
```

**Impact:**
- Economic damage to protocol users
- Service disruption
- Wasted gas fees
- User frustration leading to protocol abandonment

**Mitigation:**
- Pull payment patterns
- Gas limits on external calls
- Economic incentives against griefing
- Whitelisting or reputation systems

### 5. Push vs Pull Payment Patterns

**Push Pattern (Vulnerable):**
```solidity
function distribute() public {
    for (uint i = 0; i < recipients.length; i++) {
        recipients[i].transfer(amounts[i]); // Can fail
    }
}
```

**Pull Pattern (Safe):**
```solidity
mapping(address => uint) public pendingWithdrawals;

function withdraw() public {
    uint amount = pendingWithdrawals[msg.sender];
    pendingWithdrawals[msg.sender] = 0;
    payable(msg.sender).transfer(amount);
}
```

**Benefits of Pull Pattern:**
- Each user controls their own withdrawal
- One failing transfer doesn't affect others
- Predictable gas costs
- No array iteration needed

### 6. msg.sender Blocking

**Vulnerability:**
Malicious contracts can revert in their fallback function to block operations that depend on sending them funds.

**Example:**
```solidity
contract Auction {
    function bid() public payable {
        require(msg.value > highestBid);
        // This can be blocked by current leader
        payable(currentLeader).transfer(previousBid);
        currentLeader = msg.sender;
    }
}

contract MaliciousBlocker {
    receive() external payable {
        revert("I block refunds!");
    }
}
```

**Impact:**
- Auctions become stuck
- Legitimate users can't participate
- Contract functionality breaks down

**Mitigation:**
- Pull payment patterns
- Graceful handling of failed transfers
- Allow admin override in extreme cases
- Blacklist mechanisms (use carefully)

## Gas Optimization Techniques

### 1. Pagination

```solidity
function processInBatches(uint start, uint end) public {
    require(end <= users.length);
    require(end > start);
    require(end - start <= MAX_BATCH_SIZE);

    for (uint i = start; i < end; i++) {
        // Process users[i]
    }
}
```

### 2. Pull Payments

```solidity
mapping(address => uint) public pendingPayments;

function claim() public {
    uint amount = pendingPayments[msg.sender];
    require(amount > 0);
    pendingPaydrawals[msg.sender] = 0;
    payable(msg.sender).transfer(amount);
}
```

### 3. Gas-Limited External Calls

```solidity
(bool success, ) = recipient.call{value: amount, gas: 2300}("");
if (!success) {
    // Handle failure gracefully
    pendingWithdrawals[recipient] += amount;
    emit WithdrawalFailed(recipient, amount);
}
```

### 4. Bounded Loops

```solidity
uint constant MAX_PARTICIPANTS = 100;

function addParticipant(address user) public {
    require(participants.length < MAX_PARTICIPANTS);
    participants.push(user);
}
```

## Project Structure

```
37-gas-dos-attacks/
├── README.md
├── src/
│   ├── Project37.sol                      # Skeleton with TODOs
│   └── solution/
│       └── Project37Solution.sol          # Complete implementation
├── test/
│   └── Project37.t.sol                    # Comprehensive tests
└── script/
    └── DeployProject37.s.sol              # Deployment script
```

## Getting Started

### Prerequisites

- Foundry installed
- Basic understanding of Solidity
- Knowledge of gas mechanics

### Installation

```bash
# Navigate to project directory
cd 37-gas-dos-attacks

# Install dependencies
forge install

# Build the project
forge build
```

### Running Tests

```bash
# Run all tests
forge test

# Run with gas reporting
forge test --gas-report

# Run with verbosity to see gas details
forge test -vvv

# Run specific test
forge test --match-test testUnboundedLoopDoS
```

## Exercises

### Exercise 1: Unbounded Loop Attack
1. Review the `VulnerableAirdrop` contract
2. Add participants until the `distribute()` function fails
3. Calculate the gas cost growth rate
4. Implement the pull payment solution

### Exercise 2: Auction Griefing
1. Study the `VulnerableAuction` contract
2. Create a malicious bidder that blocks refunds
3. Demonstrate the DoS attack
4. Implement the pull pattern fix

### Exercise 3: Block Gas Limit
1. Analyze the `MassPayment` contract
2. Calculate maximum recipients before hitting gas limit
3. Test the pagination solution
4. Compare gas costs between push and pull patterns

### Exercise 4: Expensive Fallback
1. Create a contract with an expensive receive function
2. Make it a recipient in the auction
3. Show how it DoSes the auction
4. Implement graceful failure handling

## Key Takeaways

1. **Never use unbounded loops** over dynamic arrays in critical functions
2. **Always prefer pull over push** for payments and distributions
3. **Limit gas for external calls** to prevent griefing
4. **Implement pagination** for operations over large datasets
5. **Handle external call failures gracefully** - never assume they succeed
6. **Consider economic incentives** that might motivate DoS attacks
7. **Test gas costs** at scale before deployment
8. **Monitor contract state growth** in production

## Common Patterns to Avoid

❌ **Never do this:**
```solidity
// Unbounded loop with external calls
for (uint i = 0; i < users.length; i++) {
    users[i].transfer(amounts[i]);
}

// Assuming external calls succeed
payable(user).transfer(amount);
nextOperation(); // This won't run if transfer fails

// No bounds checking
function addUser(address user) public {
    users.push(user); // Can grow infinitely
}
```

✅ **Do this instead:**
```solidity
// Pull payment pattern
mapping(address => uint) public withdrawals;
function withdraw() public {
    uint amount = withdrawals[msg.sender];
    withdrawals[msg.sender] = 0;
    payable(msg.sender).transfer(amount);
}

// Graceful failure handling
(bool success, ) = user.call{value: amount}("");
if (!success) {
    withdrawals[user] += amount;
}

// Bounded growth
require(users.length < MAX_USERS);
users.push(user);
```

## Real-World Examples

### GovernMental (2016)
- Ponzi scheme contract with unbounded loop
- Became unusable when participant array grew too large
- ~1100 ETH locked forever
- Classic example of DoS by block gas limit

### King of the Ether (2016)
- Auction contract using push payments
- Malicious contract could become "king" and refuse payments
- Prevented anyone else from claiming the throne
- Fixed by implementing pull payments

## Gas Analysis

### Unbounded Loop Growth
```
10 participants:   ~50,000 gas
100 participants:  ~500,000 gas
1000 participants: ~5,000,000 gas
2000 participants: Exceeds block limit (30M gas)
```

### Pull vs Push Comparison
```
Push to 100 users:  ~5,000,000 gas (single transaction)
Pull (per user):    ~50,000 gas (100 transactions)
                    Total: ~5,000,000 gas
```

**Key Difference:** Pull pattern distributes gas cost across users and prevents DoS.

## Additional Resources

- [Consensys Smart Contract Best Practices - DoS](https://consensys.github.io/smart-contract-best-practices/attacks/denial-of-service/)
- [SWC-128: DoS with Block Gas Limit](https://swcregistry.io/docs/SWC-128)
- [SWC-113: DoS with Failed Call](https://swcregistry.io/docs/SWC-113)
- [Ethereum Block Gas Limit](https://ethereum.org/en/developers/docs/gas/)

## Security Checklist

- [ ] No unbounded loops in critical functions
- [ ] All payment distributions use pull pattern
- [ ] External calls have gas limits or failure handling
- [ ] Array growth is bounded or paginated
- [ ] Gas costs tested at realistic scale
- [ ] No assumptions about external call success
- [ ] Fallback functions are minimal
- [ ] Economic incentives considered for griefing

## License

MIT License - Educational purposes only

## Disclaimer

This project contains intentionally vulnerable contracts for educational purposes. Never deploy these contracts to mainnet with real funds. Always conduct thorough security audits before deploying smart contracts.
