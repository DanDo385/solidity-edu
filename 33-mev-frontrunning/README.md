# Project 33: MEV & Front-Running Simulation

## Overview

This project provides an in-depth exploration of **MEV (Maximal Extractable Value)**, front-running, and sandwich attacks in Ethereum and EVM-compatible blockchains. You'll learn how these attacks work, how to simulate them, and most importantly, how to protect against them.

## Table of Contents

1. [What is MEV?](#what-is-mev)
2. [Front-Running Mechanics](#front-running-mechanics)
3. [Sandwich Attack Anatomy](#sandwich-attack-anatomy)
4. [Mempool Observation](#mempool-observation)
5. [Attack Simulations](#attack-simulations)
6. [Protection Mechanisms](#protection-mechanisms)
7. [Real-World MEV Examples](#real-world-mev-examples)
8. [Learning Objectives](#learning-objectives)
9. [Project Structure](#project-structure)
10. [Getting Started](#getting-started)

---

## What is MEV?

**MEV (Maximal Extractable Value)**, formerly known as "Miner Extractable Value," is the maximum value that can be extracted from block production beyond the standard block reward and gas fees.

### Why MEV Exists

MEV exists due to the following characteristics of blockchain systems:

1. **Public Mempool**: Transactions are publicly visible before inclusion in a block
2. **Transaction Ordering**: Block producers (miners/validators) can order transactions arbitrarily
3. **Deterministic Execution**: Smart contract behavior is predictable
4. **Latency**: Network propagation creates timing opportunities

### Types of MEV

1. **Front-Running**: Placing a transaction before a target transaction
2. **Back-Running**: Placing a transaction immediately after a target transaction
3. **Sandwich Attacks**: Front-running + back-running a target transaction
4. **Liquidations**: Racing to liquidate under-collateralized positions
5. **Arbitrage**: Exploiting price differences across DEXs
6. **Time-Bandit Attacks**: Reordering historical blocks (theoretical)

### MEV Value Chain

```
┌─────────────────┐
│   Searcher      │  Identifies MEV opportunities
└────────┬────────┘
         │
┌────────▼────────┐
│   Builder       │  Constructs optimized blocks
└────────┬────────┘
         │
┌────────▼────────┐
│   Proposer      │  Proposes blocks to network
└─────────────────┘
```

---

## Front-Running Mechanics

Front-running occurs when an attacker observes a pending transaction and submits their own transaction with a higher gas price to be executed first.

### How Front-Running Works

```
Timeline:
1. User submits TX1 (gas price: 50 gwei)
2. Attacker sees TX1 in mempool
3. Attacker submits TX2 (gas price: 100 gwei)
4. Block is mined: [TX2, TX1]  ← Attacker's transaction executed first
5. Attacker profits from executing before user
```

### Front-Running Attack Scenarios

#### 1. Auction Sniping
```solidity
// User places bid
auction.bid{value: 100 ether}();

// Attacker front-runs with slightly higher bid
auction.bid{value: 100.1 ether}();  // Executed first
```

#### 2. Price Oracle Manipulation
```solidity
// User initiates oracle update
oracle.updatePrice(newPrice);

// Attacker trades before price update
dex.swap(tokenA, tokenB);  // Profits from old price
```

#### 3. Token Purchase Front-Running
```solidity
// User tries to buy token at current price
dex.buyToken(amount);

// Attacker front-runs, driving up price
dex.buyToken(largeAmount);  // User pays more
```

### Gas Price Wars

Front-running often leads to gas price auctions:

```
Original TX:   50 gwei
Front-runner:  60 gwei
Counter:       70 gwei
Counter:       80 gwei
...
Result: Massive gas costs, failed transactions
```

---

## Sandwich Attack Anatomy

A sandwich attack combines front-running and back-running to profit from a victim's transaction.

### Attack Structure

```
Block Structure:
┌──────────────────────────────┐
│  TX1: Attacker Buy (Front)   │  ← Push price up
├──────────────────────────────┤
│  TX2: Victim Buy             │  ← Victim pays inflated price
├──────────────────────────────┤
│  TX3: Attacker Sell (Back)   │  ← Profit from price increase
└──────────────────────────────┘
```

### Step-by-Step Sandwich Attack

**Setup**: DEX with AMM (Automated Market Maker)

```
Initial State:
- Pool: 100 ETH / 10,000 USDC
- Price: 1 ETH = 100 USDC

Step 1: Victim submits buy order (10 ETH for USDC)
- Visible in mempool
- Slippage tolerance: 5%

Step 2: Attacker Front-Runs
- Buys 5 ETH for ~476 USDC
- New pool: 105 ETH / 9,524 USDC
- New price: 1 ETH ≈ 90.7 USDC

Step 3: Victim's Transaction Executes
- Buys 10 ETH for ~1,111 USDC (inflated price)
- New pool: 115 ETH / 8,413 USDC
- New price: 1 ETH ≈ 73.2 USDC

Step 4: Attacker Back-Runs
- Sells 5 ETH for ~405 USDC
- Profit: 405 - 476 = -71 USDC

Wait, let me recalculate...
Actually the attacker profits when the victim BUYS tokens:

Correct Example:
Initial: 10,000 USDC / 100 ETH (1 ETH = 100 USDC)

Victim wants to BUY 100 USDC worth of ETH

Step 1: Attacker Front-Run (Buy ETH)
- Buy 0.5 ETH for ~50 USDC
- New: 9,950 USDC / 99.5 ETH

Step 2: Victim Executes (Buy ETH)
- Buys at inflated price
- Gets less ETH than expected

Step 3: Attacker Back-Run (Sell ETH)
- Sells 0.5 ETH back
- Gets more USDC than spent
- Profit extracted
```

### Sandwich Attack Requirements

1. **Sufficient Liquidity**: Attacker needs capital
2. **Price Impact**: Victim's trade must move the price
3. **Slippage Tolerance**: Victim's slippage allows the attack
4. **Gas Control**: Attacker can control transaction ordering

### Mathematical Model

For constant product AMM (x * y = k):

```
Profit = BackRunRevenue - FrontRunCost - GasCosts

Where:
- FrontRunCost = Amount paid to push price up
- BackRunRevenue = Amount received selling at inflated price
- GasCosts = Gas for both transactions
```

---

## Mempool Observation

The mempool is where pending transactions wait for inclusion in blocks.

### Mempool Characteristics

```
┌─────────────────────────────────────┐
│           Public Mempool            │
│                                     │
│  ┌─────┐  ┌─────┐  ┌─────┐        │
│  │ TX1 │  │ TX2 │  │ TX3 │  ...   │
│  └─────┘  └─────┘  └─────┘        │
│                                     │
│  All transactions visible           │
│  to all nodes                       │
└─────────────────────────────────────┘
```

### Information Leaked in Mempool

1. **Transaction Data**: Complete transaction payload
2. **Target Contract**: Which contract will be called
3. **Function**: Which function will be executed
4. **Parameters**: All input parameters
5. **Value**: ETH amount being sent
6. **Gas Price**: How much user is willing to pay

### Mempool Monitoring Tools

```javascript
// Using ethers.js to monitor mempool
provider.on("pending", (txHash) => {
  provider.getTransaction(txHash).then((tx) => {
    // Analyze transaction
    if (isProfitableToFrontRun(tx)) {
      submitFrontRunningTx(tx);
    }
  });
});
```

### Dark Pools / Private Mempools

To combat MEV, private transaction pools have emerged:

1. **Flashbots Protect**: Private transaction relay
2. **Eden Network**: Priority ordering for members
3. **KeeperDAO**: MEV redistribution
4. **Manifold Finance**: Private RPC endpoints

---

## Attack Simulations

This project includes several MEV attack simulations:

### 1. Simple Front-Running

**Scenario**: Auction bidding

```solidity
// Victim bids 10 ETH
function placeBid() external payable {
    require(msg.value > highestBid, "Bid too low");
    highestBid = msg.value;
    highestBidder = msg.sender;
}

// Attacker observes and front-runs with 10.1 ETH
```

### 2. DEX Sandwich Attack

**Scenario**: Token swap on AMM

```solidity
// Victim swaps 100 ETH for USDC
dex.swap(100 ether, tokenIn, tokenOut, minOut);

// Attacker:
// 1. Front-run: Buy USDC (price ↑)
// 2. Victim executes (pays inflated price)
// 3. Back-run: Sell USDC (profit)
```

### 3. Oracle Manipulation

**Scenario**: Price oracle update

```solidity
// Victim updates oracle price
oracle.updatePrice(newPrice);

// Attacker front-runs with trade at old price
lending.borrow(amount);  // Uses old oracle price
```

### 4. NFT Minting Front-Running

**Scenario**: Rare NFT mint

```solidity
// Victim mints NFT #100 (rare)
nft.mint(100);

// Attacker sees transaction and front-runs
nft.mint(100);  // Executes first, gets rare NFT
```

---

## Protection Mechanisms

### 1. Commit-Reveal Schemes

Hide transaction intent until execution is guaranteed.

```solidity
// Phase 1: Commit
function commit(bytes32 hash) external {
    commitments[msg.sender] = hash;
    commitTime[msg.sender] = block.timestamp;
}

// Phase 2: Reveal (after time delay)
function reveal(uint256 bid, bytes32 salt) external {
    require(block.timestamp >= commitTime[msg.sender] + DELAY);
    require(keccak256(abi.encode(bid, salt)) == commitments[msg.sender]);

    // Execute bid
    executeBid(bid);
}
```

**Pros**: Completely hides intent
**Cons**: Requires two transactions, time delay

### 2. Slippage Protection

Limit acceptable price movement.

```solidity
function swap(
    uint256 amountIn,
    uint256 minAmountOut  // Minimum acceptable output
) external {
    uint256 amountOut = calculateSwap(amountIn);
    require(amountOut >= minAmountOut, "Slippage too high");

    // Execute swap
}
```

**Pros**: Simple, built into most DEXs
**Cons**: Can still be sandwiched within slippage tolerance

### 3. Batch Auctions

Execute multiple orders at the same price.

```solidity
// Collect orders during batch period
function submitOrder(uint256 amount, uint256 price) external {
    orders.push(Order(msg.sender, amount, price));
}

// Execute all orders at clearing price
function executeBatch() external {
    uint256 clearingPrice = calculateClearingPrice(orders);
    for (uint i = 0; i < orders.length; i++) {
        executeOrder(orders[i], clearingPrice);
    }
}
```

**Pros**: Eliminates intra-batch front-running
**Cons**: Requires coordination, delayed execution

### 4. Time Locks

Enforce minimum delay between submission and execution.

```solidity
function submitAction(bytes calldata data) external {
    bytes32 id = keccak256(data);
    pendingActions[id] = block.timestamp + TIME_LOCK;
}

function executeAction(bytes calldata data) external {
    bytes32 id = keccak256(data);
    require(block.timestamp >= pendingActions[id], "Time lock active");

    // Execute action
}
```

**Pros**: Gives time for review/cancellation
**Cons**: Poor UX, delayed execution

### 5. Submarine Sends

Hide transaction until commitment is mined.

```solidity
// Off-chain: Generate commit hash
// On-chain: Submit commit
function commit(bytes32 commitHash) external payable {
    commits[commitHash] = msg.value;
}

// Later: Reveal transaction
function reveal(bytes memory data, bytes32 salt) external {
    bytes32 commitHash = keccak256(abi.encode(data, salt));
    require(commits[commitHash] > 0, "No commit");

    // Execute hidden transaction
}
```

**Pros**: Strong protection
**Cons**: Complex, capital lockup

### 6. Private Transactions (Flashbots)

Submit transactions privately to block builders.

```javascript
// Send transaction via Flashbots RPC
const flashbotsProvider = await FlashbotsBundleProvider.create(
  provider,
  authSigner
);

const bundle = [{
  transaction: signedTransaction
}];

await flashbotsProvider.sendBundle(bundle, targetBlock);
```

**Pros**: No public mempool exposure
**Cons**: Requires Flashbots integration, validator support

### 7. Fair Ordering Protocols

Use protocols designed for fair ordering.

Examples:
- **Chainlink FSS (Fair Sequencing Services)**
- **Arbitrum's Fair Ordering**
- **Optimism's Sequencer**

### 8. Decoy Transactions

Submit multiple conflicting transactions.

```solidity
// Submit multiple bids with different nonces
submitBid(10 ETH, nonce: 1);
submitBid(11 ETH, nonce: 1);  // Conflicts
submitBid(12 ETH, nonce: 1);  // Conflicts

// Only one will be included
```

**Pros**: Confuses attackers
**Cons**: Wastes gas, unreliable

---

## Real-World MEV Examples

### 1. The $1.4M Arbitrage (April 2023)

**Incident**: MEV bot extracted $1.4M from single Curve pool arbitrage

**Details**:
- Exploited price difference between Curve and Uniswap
- Single atomic transaction
- Required flash loan of $200M+
- Gas cost: $30,000+
- Net profit: $1.4M

**Transaction Flow**:
```
1. Flash loan 200M USDC
2. Swap on Curve (low price)
3. Swap on Uniswap (high price)
4. Repay flash loan
5. Keep profit
```

### 2. Salmonella Token Attack

**Incident**: Honeypot tokens that only allow deployer to sell

**Mechanism**:
```solidity
function transfer(address to, uint256 amount) public returns (bool) {
    if (msg.sender != owner) {
        revert("Only owner can transfer");
    }
    // transfer logic
}
```

**Result**: MEV bots lost millions trying to sandwich these tokens

### 3. Ethereum's First Block MEV

**Date**: September 15, 2022 (The Merge)

**Details**:
- First PoS block on Ethereum
- Builder: 0x690...
- MEV extracted: 0.548 ETH
- Historic significance: First post-merge MEV

### 4. NFT Minting Front-Running

**Incident**: Bored Ape Yacht Club minting chaos

**Details**:
- Gas wars during mint
- Front-runners paid 2-5 ETH in gas
- Some paid more in gas than NFT cost
- Congested network for hours

### 5. DeFi Protocol Liquidations

**Example**: Compound Finance liquidation bot wars

**Details**:
- Under-collateralized positions trigger liquidation
- Bots compete to liquidate first
- Priority gas auctions (PGAs)
- Gas prices spike 1000x+

### 6. Sandwich Attack Statistics

**Research Findings** (2023):
- ~5% of all Uniswap trades sandwiched
- Average victim loss: $50-100
- Daily MEV from sandwiching: $500K+
- Largest single sandwich: $300K profit

---

## Learning Objectives

After completing this project, you will understand:

1. **MEV Fundamentals**
   - What MEV is and why it exists
   - Different types of MEV extraction
   - Economic incentives for searchers

2. **Attack Mechanisms**
   - How front-running works
   - Sandwich attack construction
   - Gas price manipulation
   - Mempool monitoring techniques

3. **Vulnerability Patterns**
   - Contracts susceptible to MEV
   - Information leakage in transactions
   - Price impact vulnerabilities

4. **Defense Strategies**
   - Commit-reveal patterns
   - Slippage protection
   - Batch processing
   - Private transaction submission
   - Fair ordering mechanisms

5. **Real-World Impact**
   - MEV's effect on users
   - Network congestion from gas wars
   - Protocol security considerations

---

## Project Structure

```
33-mev-frontrunning/
├── README.md                          (This file)
├── src/
│   ├── Project33.sol                 (Skeleton with TODOs)
│   └── solution/
│       └── Project33Solution.sol     (Complete implementation)
├── test/
│   └── Project33.t.sol               (Attack simulations & tests)
└── script/
    └── DeployProject33.s.sol         (Deployment script)
```

### Contract Components

#### Vulnerable Contracts
1. **VulnerableAuction**: Simple auction susceptible to front-running
2. **VulnerableDEX**: AMM DEX vulnerable to sandwich attacks
3. **VulnerableOracle**: Price oracle with update delays

#### Attack Contracts
1. **FrontRunner**: Generic front-running bot
2. **SandwichAttacker**: DEX sandwich attack implementation
3. **MEVSearcher**: Multi-strategy MEV searcher

#### Protected Contracts
1. **CommitRevealAuction**: Auction with commit-reveal
2. **ProtectedDEX**: DEX with slippage limits
3. **BatchAuction**: Fair batch auction system

---

## Getting Started

### Prerequisites

- Foundry installed
- Basic understanding of Solidity
- Familiarity with DeFi concepts (AMMs, DEXs)

### Installation

```bash
# Navigate to project directory
cd 33-mev-frontrunning

# Install dependencies (if any)
forge install

# Run tests
forge test -vvv
```

### Running Attack Simulations

```bash
# Run all tests
forge test

# Run specific attack simulation
forge test --match-test testFrontRunning -vvv
forge test --match-test testSandwichAttack -vvv

# Run with gas reporting
forge test --gas-report
```

### Deployment

```bash
# Deploy to local testnet
anvil  # In separate terminal

# Deploy contracts
forge script script/DeployProject33.s.sol --rpc-url http://localhost:8545 --broadcast

# Deploy to testnet
forge script script/DeployProject33.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
```

---

## Learning Path

### Stage 1: Understanding (src/Project33.sol)

1. Read through the skeleton contracts
2. Understand the vulnerability patterns
3. Complete the TODOs for basic implementations

### Stage 2: Attacking

1. Study the attack contracts
2. Simulate front-running attacks
3. Execute sandwich attacks
4. Analyze profit extraction

### Stage 3: Defending (solution contracts)

1. Implement commit-reveal scheme
2. Add slippage protection
3. Create batch auction system
4. Test mitigation effectiveness

### Stage 4: Advanced Topics

1. Study Flashbots integration
2. Explore MEV-Boost architecture
3. Analyze real-world MEV transactions
4. Consider L2 MEV implications

---

## Additional Resources

### Documentation
- [Flashbots Documentation](https://docs.flashbots.net/)
- [Ethereum MEV Research](https://ethereum.org/en/developers/docs/mev/)
- [MEV-Boost](https://boost.flashbots.net/)

### Research Papers
- "Flash Boys 2.0" by Daian et al.
- "Quantifying MEV" by Flashbots Research
- "SoK: Transparent Dishonesty" by Eskandari et al.

### Tools
- [Flashbots Explorer](https://transparency.flashbots.net/)
- [MEV-Inspect](https://github.com/flashbots/mev-inspect-py)
- [EigenPhi](https://eigenphi.io/)
- [Zeromev](https://www.zeromev.org/)

### Community
- [Flashbots Discord](https://discord.gg/flashbots)
- [MEV Research Forum](https://collective.flashbots.net/)
- [EthResearch MEV Category](https://ethresear.ch/c/mev/)

---

## Security Warnings

**EDUCATIONAL PURPOSE ONLY**

This project is for educational purposes. MEV extraction and front-running can:

1. **Harm Users**: Cause financial losses to transaction submitters
2. **Congest Networks**: Drive up gas prices for everyone
3. **Violate ToS**: May violate exchange terms of service
4. **Legal Issues**: May have legal implications in some jurisdictions

**DO NOT** use these techniques on mainnet to harm others.

**DO** use this knowledge to:
- Protect your own contracts
- Understand the MEV landscape
- Design MEV-resistant protocols
- Contribute to fair ordering research

---

## Challenges

1. **Implement a profitable sandwich attack** that extracts value from a DEX trade
2. **Create a commit-reveal auction** that prevents front-running
3. **Build slippage protection** that minimizes sandwich attack profitability
4. **Design a batch auction system** with fair price discovery
5. **Analyze gas costs** and determine MEV profitability thresholds

---

## Contributing

Found a vulnerability pattern we missed? Have ideas for better mitigations? Contributions welcome!

---

## License

MIT License - Educational use only

---

## Acknowledgments

- Flashbots team for MEV research and tooling
- Ethereum Foundation for MEV documentation
- DeFi protocols for open-source implementations
- Security researchers for vulnerability disclosures

---

**Remember**: The goal is to understand MEV to build better, more secure protocols. Use this knowledge responsibly.

Happy learning!
