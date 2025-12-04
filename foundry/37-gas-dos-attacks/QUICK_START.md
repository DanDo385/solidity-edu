# Project 37: Gas DoS Attacks - Quick Start Guide

## Project Overview

This educational project demonstrates various gas-based denial of service (DoS) attacks in Solidity and their mitigations. It contains 5 vulnerable contracts, 2 attack contracts, and 4 safe implementations showing best practices.

## Files Created

### 1. README.md (434 lines)
Comprehensive guide covering:
- Unbounded loops and iteration attacks
- Block gas limit DoS
- Expensive fallback functions
- Griefing attacks
- Push vs pull payment patterns
- msg.sender blocking attacks
- Detailed mitigation strategies
- Real-world examples (GovernMental, King of the Ether)
- Gas analysis and comparisons

### 2. src/Project37.sol (354 lines)
Skeleton contracts with TODOs for learning:
- `VulnerableAirdrop` - Unbounded loop vulnerability
- `VulnerableAuction` - Push payment pattern DoS
- `MaliciousBidder` - Attacker that blocks refunds
- `VulnerableMassPayment` - Block gas limit DoS
- `ExpensiveFallbackRecipient` - Expensive fallback attack
- `VulnerableDistributor` - Multiple DoS vectors
- `GriefingAttacker` - Griefing attack patterns
- `SafeAirdropWithPagination` - Bounded loop mitigation
- `SafeAuctionWithPullPayments` - Pull payment pattern
- `SafeMassPaymentWithPull` - Pull payment for mass payments

### 3. src/solution/Project37Solution.sol (734 lines)
Complete implementations with detailed comments:
- All vulnerable contracts fully implemented
- Attack contracts with DoS strategies
- Safe implementations with multiple mitigation techniques
- Extensive gas analysis comments
- Real gas consumption calculations
- Hybrid safe distributor with batch processing + pull fallback

Key features:
- Line-by-line vulnerability explanations
- Gas cost analysis for each attack
- Attack scenarios documented
- Mitigation strategies with explanations

### 4. test/Project37.t.sol (692 lines)
Comprehensive test suite with 25+ tests:

**DoS Attack Tests:**
- `test_UnboundedLoop_GasGrowth` - Measures gas growth with recipient count
- `test_UnboundedLoop_DoS` - Demonstrates DoS with large arrays
- `test_UnboundedLoop_AttackerBloatsArray` - Attack demonstration
- `test_VulnerableAuction_DoSAttack` - Malicious bidder blocks auction
- `test_MassPayment_GasGrowth` - Gas consumption growth analysis
- `test_ExpensiveFallback_BlocksTransfer` - transfer() fails with expensive fallback
- `test_Griefing_BlockDistributor` - Griefing attack demonstration

**Mitigation Tests:**
- `test_SafePagination_BoundedGas` - Pagination ensures bounded gas
- `test_SafeAuction_PullPayments` - Pull pattern prevents blocking
- `test_SafeAuction_CannotBeDoSed` - Attack resistance verification
- `test_SafeMassPayment_PullPattern` - Independent withdrawals
- `test_SafeDistributor_GracefulFailure` - Graceful failure handling

**Comparison Tests:**
- `test_Comparison_PushVsPull` - Gas comparison analysis
- `test_ComprehensiveDoSScenario` - All attack vectors in one test

### 5. script/DeployProject37.s.sol (297 lines)
Deployment scripts with multiple scenarios:
- `run()` - Deploy all contracts
- `runWithSetup()` - Deploy with initial setup for demos
- `demonstrateUnboundedLoopDoS()` - Show unbounded loop gas growth
- `demonstrateAuctionDoS()` - Show auction blocking attack
- `demonstrateSafeImplementations()` - Show safe patterns
- Automatic deployment address logging

## Attack Vectors Covered

### 1. Unbounded Loop DoS
**Vulnerability:** Dynamic arrays without bounds
```solidity
for (uint i = 0; i < recipients.length; i++) {
    payable(recipients[i]).transfer(1 ether);
}
```
**Gas Impact:**
- 100 recipients: ~3M gas
- 1000 recipients: ~30M gas (near block limit)

### 2. Auction Blocking
**Vulnerability:** Push payments with transfer()
```solidity
payable(highestBidder).transfer(highestBid); // Can be blocked
```
**Attack:** Malicious contract reverts in receive()

### 3. Block Gas Limit
**Vulnerability:** Operations grow with user-controlled data
**Attack:** Add many entries to force function over gas limit

### 4. Expensive Fallback
**Vulnerability:** Recipient with expensive receive()
**Impact:** transfer() only provides 2300 gas, fails with expensive operations

### 5. Griefing Attacks
**Vulnerability:** Economic attacks without direct benefit
**Impact:** Waste gas, block functionality, degrade UX

## Mitigation Strategies Implemented

### 1. Pagination (Bounded Loops)
```solidity
function distributeBatch(uint start, uint end) public {
    require(end - start <= MAX_BATCH_SIZE);
    for (uint i = start; i < end; i++) {
        // Process
    }
}
```

### 2. Pull Payment Pattern
```solidity
mapping(address => uint) public pendingReturns;

function withdraw() public {
    uint amount = pendingReturns[msg.sender];
    pendingReturns[msg.sender] = 0;
    payable(msg.sender).transfer(amount);
}
```

### 3. Graceful Failure Handling
```solidity
(bool success, ) = payable(recipient).call{value: amount}("");
if (!success) {
    pendingWithdrawals[recipient] += amount;
}
```

### 4. Hybrid Approach
- Batch processing for efficiency
- Pull pattern fallback for failed transfers
- Best of both worlds

## How to Use This Project

### For Learning (Start with Skeleton)

1. **Read the README.md** to understand attack vectors
2. **Open src/Project37.sol** and read the TODOs
3. **Implement the vulnerable contracts** following the hints
4. **Try the attacks** by completing attacker contracts
5. **Implement safe versions** using mitigation patterns
6. **Compare with solution** in src/solution/Project37Solution.sol

### For Reference (Use Solution)

1. **Study src/solution/Project37Solution.sol** for complete implementations
2. **Read the detailed comments** explaining each vulnerability
3. **Check gas analysis** in comments for real consumption data
4. **Run tests** to see attacks in action
5. **Use as templates** for your own secure contracts

### Running Tests

```bash
# Navigate to project root
cd /home/user/solidity-edu

# Run all tests for this project
forge test --match-path "37-gas-dos-attacks/test/Project37.t.sol"

# Run with gas reporting
forge test --match-path "37-gas-dos-attacks/test/Project37.t.sol" --gas-report

# Run with detailed output
forge test --match-path "37-gas-dos-attacks/test/Project37.t.sol" -vvv

# Run specific test
forge test --match-test test_UnboundedLoop_GasGrowth -vvv
```

### Deployment

```bash
# Set your private key
export PRIVATE_KEY=your_private_key_here

# Deploy all contracts
forge script script/DeployProject37.s.sol:DeployProject37 --rpc-url $RPC_URL --broadcast

# Deploy with demo setup
forge script script/DeployProject37.s.sol:DeployProject37 --sig "runWithSetup()" --rpc-url $RPC_URL --broadcast

# Demonstrate unbounded loop DoS
forge script script/DeployProject37.s.sol:DeployProject37 --sig "demonstrateUnboundedLoopDoS()" --rpc-url $RPC_URL --broadcast
```

## Key Learning Outcomes

After completing this project, you will understand:

1. ✅ How unbounded loops can DoS contracts
2. ✅ Why push payments are dangerous
3. ✅ How to implement pull payment patterns
4. ✅ The importance of bounded operations
5. ✅ Gas limit implications for contract design
6. ✅ Griefing attacks and economic incentives
7. ✅ How to handle external call failures gracefully
8. ✅ Pagination strategies for large datasets
9. ✅ Real gas costs of different patterns
10. ✅ Defense-in-depth security approaches

## Real-World Impact

**Historic Attacks:**
- **GovernMental (2016):** ~1100 ETH locked due to unbounded loop DoS
- **King of the Ether (2016):** Auction stuck due to push payment vulnerability

**Modern Implications:**
- Airdrops must use pull patterns or pagination
- Auctions require pull payments
- Reward distributions need batching
- Mass payments should be pull-based

## Testing Checklist

When building contracts, verify:
- [ ] No unbounded loops in critical functions
- [ ] Payment distributions use pull pattern
- [ ] External calls have failure handling
- [ ] Array growth is bounded
- [ ] Gas costs tested at scale
- [ ] No assumption of call success
- [ ] Fallback functions are minimal
- [ ] Economic incentives considered

## Best Practices Summary

**Never:**
- ❌ Loop over unbounded arrays
- ❌ Use push payments for distributions
- ❌ Assume external calls succeed
- ❌ Allow unlimited array growth

**Always:**
- ✅ Use pull payments for refunds/distributions
- ✅ Implement pagination for loops
- ✅ Handle external call failures
- ✅ Bound array sizes
- ✅ Test gas costs at scale
- ✅ Use CEI pattern (Checks-Effects-Interactions)

## Project Statistics

- **Total Lines of Code:** 2,511
- **Contracts:** 15 (5 vulnerable, 4 safe, 2 attacker, 4 examples)
- **Tests:** 25+ comprehensive test cases
- **Documentation:** 434 lines of educational content
- **Attack Vectors:** 6 distinct DoS scenarios
- **Mitigation Patterns:** 4 different strategies

## Additional Resources

- [Consensys Best Practices](https://consensys.github.io/smart-contract-best-practices/)
- [SWC Registry - DoS](https://swcregistry.io/)
- [Ethereum Gas Documentation](https://ethereum.org/en/developers/docs/gas/)

## Support and Questions

If you have questions or find issues:
1. Review the comprehensive comments in solution contracts
2. Check test cases for usage examples
3. Refer to README.md for theoretical background
4. Study real-world examples mentioned in documentation

---

**Remember:** These are intentionally vulnerable contracts for educational purposes. Never deploy vulnerable versions to mainnet!
