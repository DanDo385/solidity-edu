# Project 39: Governance Attack Simulation

Learn about DAO governance vulnerabilities and how attackers exploit voting mechanisms through flashloans, vote buying, and other attack vectors.

## Overview

Decentralized Autonomous Organizations (DAOs) rely on token-based governance where token holders vote on proposals. However, this system is vulnerable to various attacks that can compromise the integrity of governance decisions. This project demonstrates real-world governance attack vectors and defensive patterns.

## Governance Attack Vectors

### 1. Flashloan Governance Attacks

**The Vulnerability:**
Many DAOs use token balance as voting power. Attackers can flashloan massive amounts of governance tokens, vote on proposals, and return the tokens in the same transaction.

**Attack Flow:**
```
1. Attacker creates malicious proposal
2. Attacker takes flashloan of governance tokens
3. Attacker votes with borrowed tokens
4. Proposal passes due to inflated voting power
5. Attacker returns flashloan
6. Malicious proposal executes later
```

**Real Example:**
- **Beanstalk DAO (April 2022)**: Attacker used flashloans to acquire 79% voting power, passed a malicious proposal that drained $182M
- The attacker borrowed over $1B in assets across multiple DeFi protocols to gain voting majority

**Prevention:**
- Snapshot voting power at proposal creation time
- Require minimum lock period before tokens can vote
- Implement delegation with time delays
- Use vote escrow mechanisms (lock tokens for extended periods)

### 2. Vote Buying and Delegation Exploits

**The Vulnerability:**
Token delegation allows users to delegate voting power to others. Attackers can accumulate delegated power to manipulate votes.

**Attack Vectors:**
- Bribing token holders to delegate voting power
- Offering financial incentives for votes on specific proposals
- Creating secondary markets for voting rights
- Temporary vote lending without token transfer

**Real Example:**
- **Curve Wars**: Protocols compete to accumulate veCRV voting power to direct emissions
- Billions of dollars locked to influence governance decisions
- Creation of "vote markets" like Votium and Hidden Hand

**Prevention:**
- Implement delegation cooldown periods
- Track and limit delegation chains
- Require skin-in-the-game for voters
- Use conviction voting (voting power increases with lock time)

### 3. Quorum Manipulation

**The Vulnerability:**
DAOs often require a minimum quorum (participation threshold) for proposals to pass. Attackers can manipulate this in multiple ways.

**Attack Types:**

**A. Quorum Denial:**
- Attackers acquire tokens and don't vote
- Prevents legitimate proposals from reaching quorum
- Gridlocks the DAO

**B. Dust Attack Quorum:**
- Set very low quorum requirements
- Attacker creates proposal when participation is low
- Small amount of tokens can pass malicious proposals

**C. Quorum Inflation:**
- Use flashloans or borrowed tokens to artificially inflate participation
- Makes future quorums harder to reach organically

**Prevention:**
- Adaptive quorum based on token supply participation
- Minimum absolute vote threshold (not just percentage)
- Require sustained participation over time
- Implement quadratic voting

### 4. Proposal Spam and Griefing

**The Vulnerability:**
If proposal creation is unrestricted or has low barriers, attackers can spam the system.

**Attack Impact:**
- Flooding with junk proposals
- Legitimate proposals get buried
- Community fatigue and disengagement
- Draining treasury through proposal deposits (if refundable)

**Real Example:**
- Multiple DAOs faced spam attacks where hundreds of worthless proposals were created
- Gitcoin and other platforms had to increase proposal thresholds

**Prevention:**
- Require significant token holdings to create proposals
- Non-refundable proposal deposits
- Rate limiting on proposal creation
- Community vetting period before voting starts

### 5. Timelock Bypasses

**The Vulnerability:**
Timelocks give the community time to react to malicious proposals. However, various bypasses exist.

**Attack Vectors:**

**A. Short Timelock:**
- DAO sets timelock too short (e.g., 1 hour)
- Not enough time for community to react and exit

**B. Timelock Reduction:**
- Attacker first passes proposal to reduce timelock
- Then passes malicious proposal with shorter delay

**C. Emergency Function Abuse:**
- Many DAOs have emergency functions that bypass timelock
- If governance controls emergency functions, attackers can abuse them

**Real Example:**
- **Indexed Finance (October 2021)**: Attacker attempted to pass proposal to reduce timelock and gain control

**Prevention:**
- Set minimum timelock periods (24-48 hours minimum)
- Separate timelock for different proposal types
- Emergency functions controlled by separate multisig, not governance
- Timelock parameters should themselves have long delays to change

### 6. Malicious Proposal Execution

**The Vulnerability:**
Proposals can execute arbitrary code, allowing complete control over DAO assets.

**Attack Examples:**

**A. Treasury Drain:**
```solidity
// Malicious proposal: Transfer all treasury funds to attacker
function execute() external {
    treasury.transfer(attacker, treasury.balance);
}
```

**B. Token Minting:**
```solidity
// Mint unlimited governance tokens to attacker
function execute() external {
    governanceToken.mint(attacker, 1000000000 * 1e18);
}
```

**C. Contract Upgrade:**
```solidity
// Replace DAO logic with malicious implementation
function execute() external {
    proxy.upgradeTo(maliciousImplementation);
}
```

**D. Parameter Manipulation:**
```solidity
// Change critical parameters to attacker's benefit
function execute() external {
    dao.setQuorum(1); // Allow any vote to pass
    dao.setTimelock(0); // Remove safety delay
    dao.setAdmin(attacker); // Give attacker control
}
```

**Prevention:**
- Use proposal templates with limited actions
- Implement proposal validation and whitelisting
- Require multiple separate proposals for critical changes
- Add proposal value limits (e.g., max 5% of treasury per proposal)
- Use multisig guardians with veto power

### 7. Vote Timing Attacks

**The Vulnerability:**
Attackers exploit the timing of snapshot blocks, voting periods, and execution.

**Attack Types:**

**A. Snapshot Front-Running:**
- Attacker monitors for upcoming proposals
- Buys tokens right before snapshot block
- Votes with new tokens
- Sells immediately after snapshot

**B. Last-Minute Voting:**
- Accumulate tokens during voting period
- Wait until last block to vote
- Community can't react or counter-vote

**C. Execution Timing:**
- Time malicious proposal execution for maximum damage
- Execute during holidays, weekends, or low activity periods

**Prevention:**
- Random or delayed snapshot blocks
- Minimum token holding period before voting
- Extended timelock after vote passes
- Active monitoring and alerting systems

## Real-World DAO Hacks

### 1. Beanstalk DAO - $182M (April 2022)
- **Attack**: Flashloan governance attack
- **Method**: Borrowed $1B in crypto via flashloans to gain 67% voting power
- **Outcome**: Passed malicious proposal that drained treasury
- **Key Lesson**: Never use current token balance for voting; use snapshots with time locks

### 2. Audius - $6M (July 2022)
- **Attack**: Malicious proposal execution
- **Method**: Exploited governance to make malicious proposal pass
- **Outcome**: Unauthorized token minting
- **Key Lesson**: Implement proper proposal validation and safeguards

### 3. Build Finance - $470K (February 2021)
- **Attack**: Governance takeover
- **Method**: Attacker accumulated 25% of tokens and passed malicious proposal
- **Outcome**: Treasury drained
- **Key Lesson**: Higher thresholds needed for critical operations

### 4. Indexed Finance - Attempted (October 2021)
- **Attack**: Attempted governance takeover
- **Method**: Tried to pass proposal to reduce timelock
- **Outcome**: Community detected and prevented
- **Key Lesson**: Long timelocks and active monitoring save DAOs

## Defensive Patterns

### 1. Snapshot Voting
```solidity
// Record voting power at proposal creation, not voting time
mapping(uint256 => mapping(address => uint256)) public votingPowerSnapshot;

function propose() external returns (uint256 proposalId) {
    uint256 currentBlock = block.number;
    // Take snapshot of all token balances
    votingPowerSnapshot[proposalId][msg.sender] = token.balanceOf(msg.sender);
}
```

### 2. Vote Escrow (ve-Tokenomics)
```solidity
// Users lock tokens for extended periods to gain voting power
// Longer lock = more voting power
// Prevents flashloan attacks and aligns long-term incentives
struct Lock {
    uint256 amount;
    uint256 unlockTime;
}

function votingPower(address user) public view returns (uint256) {
    Lock memory lock = locks[user];
    if (block.timestamp >= lock.unlockTime) return 0;

    uint256 timeLeft = lock.unlockTime - block.timestamp;
    // Max 4 year lock
    return lock.amount * timeLeft / 4 years;
}
```

### 3. Quadratic Voting
```solidity
// Cost to vote increases quadratically
// Prevents whales from dominating votes
function votingCost(uint256 votes) public pure returns (uint256) {
    return votes * votes;
}
```

### 4. Multi-Tier Governance
```solidity
// Different proposal types require different thresholds
enum ProposalType {
    Minor,      // 10% quorum, 51% approval
    Standard,   // 20% quorum, 66% approval
    Critical,   // 30% quorum, 75% approval
    Emergency   // Multisig only
}
```

### 5. Timelock with Guardians
```solidity
// Add guardian multisig that can veto malicious proposals
contract GovernorWithGuardian {
    address public guardian; // Multisig

    function veto(uint256 proposalId) external {
        require(msg.sender == guardian, "Only guardian");
        proposals[proposalId].vetoed = true;
    }
}
```

### 6. Rage Quit Mechanism
```solidity
// Allow token holders to exit with their share before malicious proposal executes
function rageQuit() external {
    uint256 share = (treasury.balance * token.balanceOf(msg.sender)) / token.totalSupply();
    token.burn(msg.sender, token.balanceOf(msg.sender));
    payable(msg.sender).transfer(share);
}
```

## Key Takeaways

1. **Never use current balances for voting** - Always use historical snapshots
2. **Implement meaningful timelocks** - Minimum 24-48 hours for community reaction
3. **Require skin in the game** - Lock tokens to vote, prevent flashloans
4. **Multi-tier governance** - Critical changes need higher thresholds
5. **Guardian multisigs** - Last line of defense against obvious attacks
6. **Proposal validation** - Limit what proposals can do
7. **Active monitoring** - Automated alerts for unusual proposals
8. **Emergency exits** - Allow users to leave before malicious execution

## Project Structure

```
39-governance-attack/
├── src/
│   ├── Project39.sol                 # Skeleton with TODOs
│   └── solution/
│       └── Project39Solution.sol     # Complete implementation
├── test/
│   └── Project39.t.sol              # Attack simulation tests
├── script/
│   └── DeployProject39.s.sol        # Deployment script
└── README.md
```

## Learning Objectives

After completing this project, you will understand:

1. How flashloan governance attacks work
2. Vote buying and delegation vulnerabilities
3. Quorum manipulation techniques
4. Proposal spam and griefing attacks
5. Timelock bypass methods
6. Malicious proposal execution patterns
7. Real-world DAO security incidents
8. Defensive governance patterns

## Setup

```bash
# Install dependencies
forge install

# Run tests
forge test --match-path test/Project39.t.sol -vvv

# Run specific test
forge test --match-test testFlashloanGovernanceAttack -vvvv
```

## Tasks

1. **Understand the Vulnerability**: Review the VulnerableDAO contract
2. **Implement Flashloan Attack**: Complete the FlashloanGovernanceAttacker
3. **Test Vote Buying**: Demonstrate delegation exploits
4. **Simulate Quorum Manipulation**: Show how to bypass quorum requirements
5. **Implement Defenses**: Complete the SafeDAO with protective measures
6. **Run Attack Simulations**: Execute all test cases

## Security Considerations

This project is for EDUCATIONAL PURPOSES ONLY:
- Never deploy vulnerable contracts to mainnet
- Understand attacks to build better defenses
- Real DAOs require comprehensive security audits
- Governance is a complex socio-technical problem
- No single solution prevents all attacks

## Going Further

1. Research Compound and Curve governance models
2. Study ve-tokenomics and vote escrow mechanisms
3. Explore optimistic governance (Optimism's model)
4. Implement conviction voting
5. Design hybrid on-chain/off-chain governance
6. Study snapshot.org for gas-efficient voting
7. Research quadratic funding and voting

## Additional Resources

- [Beanstalk Post-Mortem](https://bean.money/blog/beanstalk-governance-exploit)
- [Curve Wars Explained](https://every.to/almanack/curve-wars)
- [Vitalik on Governance](https://vitalik.ca/general/2021/08/16/voting3.html)
- [OpenZeppelin Governor](https://docs.openzeppelin.com/contracts/4.x/governance)
- [Compound Governance](https://compound.finance/docs/governance)
- [Trail of Bits: Governance Security](https://blog.trailofbits.com/2023/03/01/dao-governance-attacks/)

## Further Reading

- **Research Papers**: "SoK: Decentralized Finance (DeFi)" - arXiv:2101.08778
- **Security Guides**: "Not So Smart Contracts" - Trail of Bits
- **Best Practices**: "Smart Contract Security Verification Standard"

---

Remember: Good governance is not just about code - it's about incentive alignment, community engagement, and thoughtful system design. Defense in depth requires technical, economic, and social safeguards.
