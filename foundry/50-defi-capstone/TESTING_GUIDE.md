# Testing & Security Guide - Project 50

## Test Coverage Matrix

### Protocol Token (ProtocolToken.sol)

#### Unit Tests
- [x] `test_ProtocolToken_Initialization` - Verify name, symbol, supply
- [x] `test_ProtocolToken_Mint` - Mint tokens successfully
- [x] `test_ProtocolToken_MintRevertsMaxSupply` - Reject minting beyond max
- [x] `test_ProtocolToken_Burn` - Burn tokens successfully
- [x] `test_ProtocolToken_PauseTransfers` - Pause blocks transfers
- [ ] `test_ProtocolToken_UnpauseTransfers` - Unpause allows transfers
- [ ] `test_ProtocolToken_OnlyMinterCanMint` - Access control
- [ ] `test_ProtocolToken_OnlyPauserCanPause` - Access control

#### Edge Cases
- [ ] Mint exactly to max supply
- [ ] Burn entire balance
- [ ] Transfer while paused (should revert)
- [ ] Multiple minters scenario

### NFT Membership (NFTMembership.sol)

#### Unit Tests
- [x] `test_NFTMembership_MintBronze` - Mint bronze tier
- [x] `test_NFTMembership_GetVotingMultiplier` - Correct multipliers
- [x] `test_NFTMembership_GetFeeDiscount` - Correct discounts
- [x] `test_NFTMembership_UpgradeTier` - Upgrade tier successfully
- [x] `test_NFTMembership_RevertsDoubleNFT` - One NFT per user
- [ ] `test_NFTMembership_MintAllTiers` - All tiers work
- [ ] `test_NFTMembership_PlatinumSupplyLimit` - Respect 100 limit
- [ ] `test_NFTMembership_UpgradeMultipleTiers` - Bronze → Platinum

#### Edge Cases
- [ ] Mint 100th Platinum NFT
- [ ] Attempt 101st Platinum (should fail)
- [ ] Upgrade cost calculation
- [ ] NFT with zero PROTO balance

### Price Oracle (PriceOracle.sol)

#### Unit Tests
- [x] `test_Oracle_GetPrice` - Fetch current price
- [x] `test_Oracle_RevertsStalePrice` - Reject old data
- [x] `test_Oracle_ValidatePrice` - Validate deviation
- [ ] `test_Oracle_SetPriceFeed` - Configure feed
- [ ] `test_Oracle_DeactivateFeed` - Deactivate feed
- [ ] `test_Oracle_MultipleFeedSources` - Fallback logic

#### Edge Cases
- [ ] Price exactly at heartbeat
- [ ] Price at max deviation (10%)
- [ ] Price beyond max deviation
- [ ] Negative price (invalid)
- [ ] Zero price (invalid)

### Governance (Governance.sol)

#### Unit Tests
- [x] `test_Governance_Propose` - Create proposal
- [x] `test_Governance_ProposeWithGoldNFT` - NFT threshold bypass
- [x] `test_Governance_CastVote` - Vote on proposal
- [x] `test_Governance_NFTVotingWeight` - NFT multiplier effect
- [x] `test_Governance_FullProposalLifecycle` - Complete flow
- [ ] `test_Governance_QuorumNotMet` - Fail without quorum
- [ ] `test_Governance_VotingPeriodExpired` - Can't vote after period
- [ ] `test_Governance_ExecuteBeforeTimelock` - Fail early execution
- [ ] `test_Governance_CancelProposal` - Cancel by proposer
- [ ] `test_Governance_DelegateVotes` - Delegation (if implemented)

#### Edge Cases
- [ ] Proposal with multiple actions
- [ ] Exactly at quorum threshold
- [ ] Exactly 51% for/against
- [ ] Vote during pending state
- [ ] Execute expired proposal

### Vault (DeFiVault.sol)

#### Unit Tests
- [x] `test_Vault_Deposit` - Basic deposit
- [x] `test_Vault_DepositWithNFTBonus` - NFT discount
- [x] `test_Vault_Withdraw` - Basic withdrawal
- [x] `test_Vault_Harvest` - Fee collection
- [ ] `test_Vault_PreviewDeposit` - Preview shares
- [ ] `test_Vault_PreviewWithdraw` - Preview assets
- [ ] `test_Vault_FirstDepositorAttack` - Inflation protection
- [ ] `test_Vault_EmergencyWithdraw` - Admin emergency function
- [ ] `test_Vault_SetFees` - Update fee parameters

#### Flash Loan Tests
- [x] `test_FlashLoan_Success` - Successful loan
- [x] `test_FlashLoan_MaxAmount` - Respect limits
- [x] `test_FlashLoan_RevertsOnFailedCallback` - Bad callback
- [x] `test_FlashLoan_RevertsOnInsufficientRepayment` - Steal attempt
- [ ] `test_FlashLoan_FeeDistribution` - Correct fee split
- [ ] `test_FlashLoan_MultipleLoans` - Sequential loans
- [ ] `test_FlashLoan_DuringPause` - Should revert when paused

#### Edge Cases
- [ ] First depositor with 1 wei
- [ ] Last withdrawer
- [ ] Deposit max uint256 (should handle)
- [ ] Flash loan entire vault balance
- [ ] Harvest with zero profit
- [ ] Harvest with loss

### Multi-sig Treasury (MultiSigTreasury.sol)

#### Unit Tests
- [x] `test_Treasury_SubmitTransaction` - Submit tx
- [x] `test_Treasury_ConfirmTransaction` - Confirm tx
- [x] `test_Treasury_ExecuteTransaction` - Execute tx
- [x] `test_Treasury_RevokeConfirmation` - Revoke confirmation
- [ ] `test_Treasury_RequireMinSigners` - Need 3+ signers
- [ ] `test_Treasury_RequireMinConfirmations` - Need 2+ confirmations
- [ ] `test_Treasury_NonSignerCannotSubmit` - Access control
- [ ] `test_Treasury_CannotExecuteTwice` - Double execution protection

#### Edge Cases
- [ ] Transaction with exact threshold (3/5)
- [ ] Revoke then re-confirm
- [ ] Multiple pending transactions
- [ ] Transaction fails on execution
- [ ] Large payload transaction

## Integration Test Scenarios

### End-to-End User Journeys

#### Journey 1: New User Onboarding
```
1. User receives PROTO tokens
2. User mints Bronze NFT
3. User deposits into vault
4. Vault generates yield
5. User upgrades to Silver NFT
6. User withdraws with reduced fees
7. User participates in governance
```

#### Journey 2: Flash Loan Arbitrage
```
1. User identifies arbitrage opportunity
2. User takes flash loan from vault
3. User executes arbitrage strategy
4. User repays loan + fee
5. Protocol collects flash loan fee
6. Fee distributed to treasury and stakers
```

#### Journey 3: Governance Proposal
```
1. Gold NFT holder creates proposal
2. Community discusses (3 days)
3. Voting period begins
4. Users cast weighted votes
5. Proposal passes quorum
6. Proposal queued in timelock
7. After delay, proposal executed
8. Protocol parameters updated
```

#### Journey 4: Emergency Response
```
1. Security issue detected
2. Pauser pauses affected contracts
3. Multi-sig investigates
4. Governance proposal for fix
5. Community votes
6. Fix deployed via upgrade
7. System unpaused
```

## Attack Scenario Tests

### 1. Reentrancy Attacks

**Test:** `test_Attack_ReentrancyProtection`
```solidity
// Attempt to re-enter vault during withdrawal
// Expected: Transaction reverts with "ReentrancyGuard: reentrant call"
```

**Vectors to Test:**
- Deposit reentrancy
- Withdraw reentrancy
- Flash loan callback reentrancy
- Harvest reentrancy

### 2. Flash Loan Attacks

**Test:** `test_Attack_FlashLoanInflationAttack`
```solidity
// Attempt to manipulate share price via flash loan
// Expected: Share price remains stable
```

**Vectors to Test:**
- Share price manipulation
- Oracle price manipulation
- Sandwich attack on deposits
- MEV extraction

### 3. Governance Attacks

**Test:** `test_Attack_GovernanceTakeover`
```solidity
// Attempt to gain control via malicious proposal
// Expected: Insufficient voting power or timelock protection
```

**Vectors to Test:**
- Proposal spam
- Vote buying
- Last-minute vote swing
- Timelock bypass attempt
- Emergency veto abuse

### 4. Oracle Manipulation

**Test:** `test_Attack_OracleManipulation`
```solidity
// Attempt to exploit stale or manipulated prices
// Expected: Stale price rejected, deviation detected
```

**Vectors to Test:**
- Stale price exploitation
- Flash loan price manipulation
- Multiple oracle source manipulation
- Heartbeat boundary conditions

### 5. Economic Exploits

**Test:** `test_Attack_FirstDepositorInflation`
```solidity
// Inflate share price to steal from future depositors
// Expected: Protected by minimum shares or donation protection
```

**Vectors to Test:**
- First depositor attack
- Donation attack
- Rounding error exploitation
- Fee manipulation

## Invariant Testing

### Vault Invariants

```solidity
// Total shares should represent total assets (within fee margin)
function invariant_VaultSharesMatchAssets() public {
    assertApproxEqRel(vault.totalAssets(), vault.totalSupply(), 0.1e18);
}

// User shares should never exceed total shares
function invariant_UserSharesLessThanTotal(address user) public {
    assertLe(vault.balanceOf(user), vault.totalSupply());
}

// Total assets should never decrease except for withdrawals
function invariant_TotalAssetsNonDecreasing() public {
    // Track previous total assets
    // Ensure current >= previous (excluding withdrawals)
}
```

### Token Invariants

```solidity
// Total supply never exceeds max supply
function invariant_TokenSupplyNeverExceedsMax() public {
    assertLe(protoToken.totalSupply(), protoToken.MAX_SUPPLY());
}

// Sum of all balances equals total supply
function invariant_BalancesSumToTotalSupply() public {
    // Iterate all known addresses
    // Sum should equal totalSupply()
}
```

### Governance Invariants

```solidity
// Quorum should always be percentage of total supply
function invariant_QuorumConsistent() public {
    uint256 expected = (protoToken.totalSupply() * governance.quorumPercentage()) / 100;
    assertEq(governance.quorum(), expected);
}

// Executed proposals should have sufficient votes
function invariant_ExecutedProposalsHadQuorum(uint256 proposalId) public {
    if (governance.state(proposalId) == Executed) {
        // Check it had quorum when executed
    }
}
```

## Fuzzing Tests

### Deposit/Withdraw Fuzzing

```solidity
function testFuzz_Vault_DepositWithdraw(uint256 amount) public {
    amount = bound(amount, 1e18, USER_INITIAL_BALANCE);

    // Deposit
    uint256 shares = vault.deposit(amount, user);

    // Withdraw
    uint256 assets = vault.withdraw(amount, user, user);

    // User should get approximately same amount back
    assertApproxEqRel(assets, amount, 0.01e18); // 1% tolerance
}
```

### Flash Loan Fuzzing

```solidity
function testFuzz_FlashLoan_Amount(uint256 amount) public {
    uint256 maxLoan = vault.maxFlashLoan(asset);
    amount = bound(amount, 1e18, maxLoan);

    // Execute flash loan
    // Should succeed for any amount <= maxLoan
}
```

### Voting Weight Fuzzing

```solidity
function testFuzz_Governance_VotingWeight(
    uint256 tokenBalance,
    uint8 nftTier
) public {
    tokenBalance = bound(tokenBalance, 1e18, 1_000_000e18);
    nftTier = uint8(bound(nftTier, 0, 3));

    // Setup user with tokens and NFT
    // Calculate expected voting weight
    // Verify getVotes() returns correct weight
}
```

## Gas Optimization Tests

### Gas Benchmarks

```solidity
function test_Gas_Deposit() public {
    uint256 gasBefore = gasleft();
    vault.deposit(1000e18, user);
    uint256 gasUsed = gasBefore - gasleft();

    // Log and compare against baseline
    console.log("Deposit gas:", gasUsed);
}
```

**Target Gas Costs:**
- Token transfer: < 50,000 gas
- Vault deposit: < 100,000 gas
- Vault withdraw: < 100,000 gas
- NFT mint: < 150,000 gas
- Flash loan: < 200,000 gas
- Governance vote: < 80,000 gas

## Security Checklist

### Pre-Deployment

- [ ] All tests passing (100% pass rate)
- [ ] Test coverage > 95%
- [ ] All invariants holding
- [ ] No critical or high severity issues
- [ ] Gas costs optimized
- [ ] Code reviewed by multiple developers
- [ ] External security audit completed
- [ ] Audit findings addressed
- [ ] Testnet deployment successful
- [ ] Stress testing completed

### Access Control

- [ ] Admin roles properly configured
- [ ] Multi-sig setup verified
- [ ] Timelock delays appropriate
- [ ] Emergency pause tested
- [ ] Role transfer procedures documented
- [ ] No single points of failure

### Economic Security

- [ ] Fee parameters validated
- [ ] Token economics sound
- [ ] Flash loan limits appropriate
- [ ] Oracle manipulation resistant
- [ ] MEV extraction minimized
- [ ] First depositor attack prevented

### Upgrade Safety

- [ ] Storage layout preserved
- [ ] Initialize functions protected
- [ ] Upgrade path tested
- [ ] Rollback plan prepared
- [ ] Multi-sig controls upgrade
- [ ] Governance approves upgrades

### Operational Security

- [ ] Monitoring systems in place
- [ ] Alert thresholds configured
- [ ] Incident response plan documented
- [ ] Emergency contacts established
- [ ] Communication channels ready
- [ ] Bug bounty program active

## Post-Deployment Monitoring

### On-chain Metrics

Monitor these continuously:

1. **Total Value Locked (TVL)**
   - Vault total assets
   - Treasury balance
   - Protocol token market cap

2. **Protocol Activity**
   - Daily deposits/withdrawals
   - Flash loan volume
   - Governance participation
   - NFT minting rate

3. **Security Indicators**
   - Large deposits/withdrawals
   - Price deviation events
   - Failed transactions
   - Unusual voting patterns

4. **Economic Health**
   - Vault performance vs benchmarks
   - Fee collection rates
   - Token distribution
   - Liquidity depth

### Alert Thresholds

Set up alerts for:

- [ ] Single deposit > 5% of TVL
- [ ] TVL drop > 10% in 1 hour
- [ ] Price deviation > 5%
- [ ] Failed flash loan
- [ ] Governance proposal created
- [ ] Emergency pause triggered
- [ ] Oracle update failed

## Testing Best Practices

### 1. Test Organization

```
test/
├── unit/
│   ├── ProtocolToken.t.sol
│   ├── NFTMembership.t.sol
│   ├── Oracle.t.sol
│   └── ...
├── integration/
│   ├── UserJourneys.t.sol
│   └── CrossContract.t.sol
├── attack/
│   ├── Reentrancy.t.sol
│   ├── FlashLoan.t.sol
│   └── Governance.t.sol
└── fuzz/
    └── PropertyTests.t.sol
```

### 2. Setup Helpers

```solidity
contract TestHelpers is Test {
    function setupUser(address user, uint256 balance) internal {
        deal(address(protoToken), user, balance);
    }

    function setupNFT(address user, Tier tier) internal {
        // Mint NFT for user
    }

    function createProposal() internal returns (uint256) {
        // Create test proposal
    }
}
```

### 3. Use Descriptive Names

```solidity
✅ function test_Vault_DepositRevertsWhenPaused()
✅ function test_Governance_ProposalFailsWithoutQuorum()
❌ function test1()
❌ function testStuff()
```

### 4. Test One Thing

```solidity
✅ function test_Mint_Success()
✅ function test_Mint_RevertsMaxSupply()

❌ function test_MintAndBurn() // Tests two things
```

### 5. Use Expectations

```solidity
// Expect specific revert
vm.expectRevert("Insufficient balance");
token.transfer(user, amount);

// Expect event
vm.expectEmit(true, true, false, true);
emit Transfer(from, to, amount);
vault.deposit(amount, user);
```

## Continuous Testing

### GitHub Actions Workflow

```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Foundry
        uses: foundry-rs/foundry-toolchain@v1
      - name: Run tests
        run: forge test
      - name: Gas report
        run: forge test --gas-report
      - name: Coverage
        run: forge coverage
```

---

**Remember:** Testing is not just about coverage percentage—it's about covering the right scenarios, especially edge cases and attack vectors. A well-tested protocol builds user confidence and prevents exploits.

**Good luck securing your protocol! 🛡️**
