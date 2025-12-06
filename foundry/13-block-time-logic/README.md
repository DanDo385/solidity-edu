# Project 13: Block Properties & Time Logic ⏰

> **Master blockchain time and block properties safely**

## 🎯 Learning Objectives

By completing this project, you will:

1. **Understand `block.timestamp` vs `block.number`** and when to use each
2. **Learn about miner manipulation** possibilities and risks
3. **Implement rate limiting patterns** to prevent spam
4. **Create cooldown mechanisms** for two-step processes
5. **Recognize time-based exploits** and avoid them
6. **Use Foundry's time manipulation** (`vm.warp()`, `vm.roll()`, `skip()`)
7. **Implement vesting schedules** and time-locked vaults
8. **Create Foundry deployment scripts** for time-based contracts
9. **Write comprehensive test suites** with time manipulation

## Block Properties Deep Dive

### block.timestamp: Human-Readable Time

**FIRST PRINCIPLES: Miner-Controlled Time**

`block.timestamp` is the Unix timestamp (seconds since January 1, 1970) when the block was mined. Understanding its limitations is critical for secure time-based logic!

**CONNECTION TO PROJECT 11**:
ERC-4626 vaults use `block.timestamp` for yield calculations and vesting schedules. Understanding timestamp manipulation is essential!

**KEY CHARACTERISTICS**:
- Measured in seconds (Unix timestamp)
- Set by the block miner (not perfectly accurate!)
- Subject to ~15 second drift allowance (manipulation possible!)
- Can be manipulated within limits by miners
- More human-readable for time periods

**UNDERSTANDING MINER MANIPULATION**:

```
Timestamp Setting Process:
┌─────────────────────────────────────────┐
│ Miner creates block                    │
│   ↓                                      │
│ Miner sets block.timestamp              │ ← Miner chooses!
│   ↓                                      │
│ Constraints:                            │
│   - Must be > parent block timestamp    │ ← Can't go backwards
│   - Must be within ~15s of real time    │ ← Can manipulate ±15s
│   ↓                                      │
│ Other nodes validate                    │ ← Reject if invalid
│   ↓                                      │
│ Block accepted if valid                  │
└─────────────────────────────────────────┘
```

**EXAMPLE**:
```solidity
// Current timestamp
uint256 currentTime = block.timestamp;  // e.g., 1699876543

// Check if 1 day has passed
require(block.timestamp >= lastAction + 1 days, "Too soon");
// 1 days = 86400 seconds
// Safe for long periods (15s manipulation is negligible)
```

**GAS COST** (from Project 01 knowledge):
- Reading `block.timestamp`: ~2 gas (special opcode, very cheap!)
- Time comparisons: ~3 gas (arithmetic operations)

### block.number: Block-Based Time

**FIRST PRINCIPLES: Deterministic Block Counting**

`block.number` is the sequential number of the current block in the blockchain. It's more predictable than timestamp but less human-readable.

**KEY CHARACTERISTICS**:
- Increments by 1 for each block (deterministic!)
- Cannot be manipulated (other than by controlling block production)
- More predictable than timestamp
- Average block time: ~12 seconds on Ethereum mainnet
- Block time varies by network (e.g., 2s on Polygon, 1s on BSC)

**UNDERSTANDING BLOCK TIME VARIANCE**:

```
Block Production:
┌─────────────────────────────────────────┐
│ Ethereum Mainnet:                       │
│   Average: ~12 seconds per block         │
│   Range: 10-20 seconds (variable)        │
│                                          │
│ Polygon:                                 │
│   Average: ~2 seconds per block          │
│   Range: 1-3 seconds                     │
│                                          │
│ block.number increments deterministically│ ← Always +1
│   ↓                                      │
│ Cannot be manipulated by miners!        │ ← More secure
└─────────────────────────────────────────┘
```

**EXAMPLE**:
```solidity
// Current block number
uint256 currentBlock = block.number;  // e.g., 18500000

// Check if 100 blocks have passed (~20 minutes on Ethereum)
require(block.number >= lastBlock + 100, "Too soon");
// 100 blocks × 12 seconds = ~20 minutes
// More predictable than timestamp!
```

**GAS COST**:
- Reading `block.number`: ~2 gas (special opcode, very cheap!)
- Block comparisons: ~3 gas (arithmetic operations)

**COMPARISON TO RUST** (Conceptual):

**Rust** (can get real time):
```rust
use std::time::{SystemTime, UNIX_EPOCH};

let timestamp = SystemTime::now()
    .duration_since(UNIX_EPOCH)
    .unwrap()
    .as_secs();
// Real time, not manipulable
```

**Solidity** (blockchain time):
```solidity
uint256 timestamp = block.timestamp;  // Miner-controlled, ±15s variance
uint256 blockNum = block.number;      // Deterministic, but time varies
```

Blockchain time is fundamentally different - it's approximate and miner-controlled!

**Example:**
```solidity
// Current block number
uint256 currentBlock = block.number;

// Check if 100 blocks have passed (~20 minutes on Ethereum)
require(block.number >= lastBlock + 100, "Too soon");
```

## Miner Manipulation: Understanding the Risks

**FIRST PRINCIPLES: Trust in Decentralized Systems**

Ethereum protocol allows miners to set `block.timestamp` with constraints. Understanding these limits is critical for secure time-based logic!

**CONNECTION TO PROJECT 07**:
Time-based logic can be exploited if not designed carefully. Understanding manipulation limits helps prevent vulnerabilities!

### The 15-Second Drift Rule

Ethereum protocol allows miners to set `block.timestamp` with these constraints:
- Must be greater than the parent block's timestamp (monotonic)
- Must be within ~15 seconds of the actual time (drift limit)
- Other nodes will reject blocks that violate these rules (consensus enforcement)

**UNDERSTANDING THE CONSTRAINTS**:

```
Timestamp Validation:
┌─────────────────────────────────────────┐
│ Miner sets timestamp: T                 │
│   ↓                                      │
│ Check 1: T > parent.timestamp?          │ ← Must be increasing
│   ❌ No → Block rejected                 │
│   ✅ Yes → Continue                      │
│   ↓                                      │
│ Check 2: |T - real_time| < 15s?         │ ← Drift limit
│   ❌ No → Block rejected                 │
│   ✅ Yes → Block accepted                │
└─────────────────────────────────────────┘
```

**WHAT THIS MEANS**:
- Miners can manipulate timestamp by ±15 seconds (within limits)
- For short time periods (<15 seconds), timestamp is unreliable
- For longer periods (hours/days), manipulation is negligible

**SECURITY IMPLICATIONS**:

**Vulnerable Pattern**:
```solidity
// ❌ DANGEROUS: Short time window
function claimReward() external {
    require(block.timestamp % 10 == 0, "Only on even 10s");
    // Miner can manipulate ±15s to hit this condition!
    // Attack: Miner sets timestamp to even 10s, claims reward
}
```

**Safe Pattern**:
```solidity
// ✅ SAFE: Long time period
function claimReward() external {
    require(block.timestamp >= lastClaim + 1 days, "24h cooldown");
    // 15 second manipulation is negligible over 24 hours
    // Attack: Miner can only manipulate ±15s (0.017% of 24h)
}
```

**REAL-WORLD ANALOGY**: 
Like a clock that can be set ±15 seconds - fine for long periods (days), but unreliable for short periods (seconds). Always design for worst-case manipulation!

### Attack Scenarios

**Vulnerable code:**
```solidity
// DANGEROUS: Can be manipulated
function claimReward() external {
    require(block.timestamp % 10 == 0, "Only on even 10s");
    // Miner can manipulate to hit this condition
}
```

**Safer code:**
```solidity
// BETTER: Long time periods are safer
function claimReward() external {
    require(block.timestamp >= lastClaim + 1 days, "24h cooldown");
    // 15 second manipulation is negligible over 1 day
}
```

## When to Use Each Approach

### Use block.timestamp when:
- Time periods are measured in hours, days, weeks, or longer
- Human-readable time matters (e.g., "7 day voting period")
- Exact timing isn't critical for security
- You need to work with specific dates/times

**Good use cases:**
- Vesting schedules
- Lock-up periods
- Voting durations
- Auction end times
- Cooldown periods (>1 hour)

### Use block.number when:
- You need more predictable intervals
- Security depends on precise ordering
- Working with short time periods
- You want network-agnostic logic

**Good use cases:**
- Snapshot mechanisms
- Oracle price updates
- Rate limiting (very short periods)
- Governance checkpoints

### Avoid time-based logic when:
- Security depends on exact second precision
- Time periods are < 15 seconds
- Randomness is involved (never use block properties for randomness!)

## Common Patterns

### 1. Rate Limiting

Restrict how often an action can be performed.

```solidity
mapping(address => uint256) public lastActionTime;
uint256 public constant RATE_LIMIT = 1 hours;

function rateLimitedAction() external {
    require(
        block.timestamp >= lastActionTime[msg.sender] + RATE_LIMIT,
        "Rate limit active"
    );

    lastActionTime[msg.sender] = block.timestamp;
    // Perform action...
}
```

### 2. Cooldown Period

Enforce waiting time between state changes.

```solidity
mapping(address => uint256) public cooldownStart;
uint256 public constant COOLDOWN_PERIOD = 7 days;

function initiateCooldown() external {
    cooldownStart[msg.sender] = block.timestamp;
}

function executeAfterCooldown() external {
    require(
        cooldownStart[msg.sender] != 0,
        "Cooldown not initiated"
    );
    require(
        block.timestamp >= cooldownStart[msg.sender] + COOLDOWN_PERIOD,
        "Cooldown not finished"
    );

    cooldownStart[msg.sender] = 0;
    // Execute action...
}
```

### 3. Time-Locked Vault

Lock funds until a specific time.

```solidity
uint256 public unlockTime;

constructor(uint256 _lockDuration) {
    unlockTime = block.timestamp + _lockDuration;
}

function withdraw() external {
    require(block.timestamp >= unlockTime, "Still locked");
    // Withdraw logic...
}
```

### 4. Deadline Enforcement

Ensure actions happen before a deadline.

```solidity
uint256 public deadline;

function submitProposal() external {
    require(block.timestamp <= deadline, "Deadline passed");
    // Submit logic...
}
```

## Testing Time-Based Logic

Foundry provides powerful time manipulation tools:

### vm.warp(timestamp)

Sets `block.timestamp` to a specific value.

```solidity
function testCooldown() public {
    // Set to a known time
    vm.warp(1000);

    contract.initiateCooldown();

    // Fast forward 7 days
    vm.warp(1000 + 7 days);

    contract.executeAfterCooldown();
}
```

### vm.roll(blockNumber)

Sets `block.number` to a specific value.

```solidity
function testBlockBased() public {
    vm.roll(100);

    contract.doSomething();

    // Advance 100 blocks
    vm.roll(200);

    contract.doSomethingElse();
}
```

### skip(duration)

Advances `block.timestamp` by a duration.

```solidity
function testRateLimit() public {
    contract.action();

    // Try too soon
    vm.expectRevert("Rate limit active");
    contract.action();

    // Skip forward
    skip(1 hours);

    // Should work now
    contract.action();
}
```

## Common Pitfalls & Exploits

### 1. Short Time Windows

**Problem:**
```solidity
// VULNERABLE
require(block.timestamp % 60 < 10, "Only in first 10 seconds of each minute");
```

**Why:** Miner can manipulate within 15 seconds to hit this window.

### 2. Timestamp as Randomness

**Problem:**
```solidity
// NEVER DO THIS
uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp))) % 100;
```

**Why:** Miners can manipulate timestamp AND see the value before mining.

### 3. Comparison with block.timestamp Equality

**Problem:**
```solidity
// FRAGILE
require(block.timestamp == unlockTime, "Not exact time");
```

**Why:** Very unlikely to execute at exact second. Use `>=` instead.

**Fix:**
```solidity
// CORRECT
require(block.timestamp >= unlockTime, "Not yet unlocked");
```

### 4. Overflow with Arithmetic

**Problem (pre-0.8.0):**
```solidity
// Could overflow
uint256 deadline = block.timestamp + 100 days;
```

**Why:** In Solidity <0.8.0, this could overflow. Always use SafeMath or 0.8.0+.

### 5. Network-Specific Assumptions

**Problem:**
```solidity
// Assumes Ethereum block time
uint256 blocksPerDay = 7200; // 12 second blocks
```

**Why:** Different networks have different block times (Polygon ~2s, BSC ~3s).

## Real-World Examples

### DeFi Vesting
```solidity
// Vesting contract releases tokens over time
function calculateVested() public view returns (uint256) {
    if (block.timestamp < startTime) return 0;
    if (block.timestamp >= startTime + duration) return totalAmount;

    uint256 elapsed = block.timestamp - startTime;
    return (totalAmount * elapsed) / duration;
}
```

### Governance Voting
```solidity
// Voting period with clear start/end times
require(block.timestamp >= proposalStart, "Not started");
require(block.timestamp <= proposalEnd, "Voting ended");
```

### Flash Loan Protection
```solidity
// Prevent flash loan attacks with cooldown
require(
    lastDepositBlock[msg.sender] < block.number,
    "No same-block withdraw"
);
```

## Security Best Practices

1. **Use timestamp for long periods (>1 hour):** Manipulation is negligible.
2. **Use block.number for short periods:** More predictable.
3. **Never use for randomness:** Use Chainlink VRF or similar.
4. **Use >= not ==:** Time won't hit exact seconds.
5. **Document assumptions:** Note block time assumptions.
6. **Test edge cases:** Use vm.warp() and vm.roll() extensively.
7. **Consider MEV:** Miners/validators can see pending transactions.

## Project Tasks

In this project, you will implement:

1. **TimeLockedVault:** Lock ETH until a specific timestamp
2. **RateLimiter:** Allow actions only after a cooldown period
3. **BlockBasedLottery:** Use block numbers for fair lottery mechanics
4. **VestingWallet:** Release tokens linearly over time

Each implementation will include security considerations and proper testing.

## Resources

- [Solidity Documentation - Block and Transaction Properties](https://docs.soliditylang.org/en/latest/units-and-global-variables.html#block-and-transaction-properties)
- [Consensys Best Practices - Timestamp Dependence](https://consensys.github.io/smart-contract-best-practices/development-recommendations/solidity-specific/timestamp-dependence/)
- [SWC-116: Block values as a proxy for time](https://swcregistry.io/docs/SWC-116)
- [Foundry Cheatcodes - Time](https://book.getfoundry.sh/cheatcodes/warp)

## Running the Project

```bash
# Run tests
forge test --match-path test/BlockTimeLogic.t.sol -vvv

# Run specific test
forge test --match-test testRateLimit -vvv

# Deploy
forge script script/DeployBlockTimeLogic.s.sol --rpc-url <your-rpc> --broadcast

# Test with gas report
forge test --match-path test/BlockTimeLogic.t.sol --gas-report
```

## Success Criteria

- All tests pass
- Understand timestamp vs block number tradeoffs
- Can identify vulnerable time-based code
- Know when each approach is appropriate
- Can use vm.warp() and vm.roll() for testing
