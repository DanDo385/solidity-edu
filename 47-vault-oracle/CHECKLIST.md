# Project 47: Implementation Checklist

Use this checklist to track your progress through the project.

## Phase 1: Setup and Understanding

- [ ] Read README.md completely
- [ ] Understand oracle risks and vulnerabilities
- [ ] Study Chainlink integration patterns
- [ ] Learn TWAP concepts
- [ ] Review security best practices
- [ ] Install Foundry and dependencies
- [ ] Build the project successfully
- [ ] Run existing tests (they should fail on skeleton)

## Phase 2: Oracle Basic Functions

### Helper Functions
- [ ] Implement `_isStale(uint256 updatedAt)`
  - [ ] Compare timestamp correctly
  - [ ] Use maxStaleness threshold
  - [ ] Test with testStaleDataRejection

- [ ] Implement `_normalizeDecimals(int256 price)`
  - [ ] Get decimals from price feed
  - [ ] Convert to 18 decimals correctly
  - [ ] Handle different decimal values
  - [ ] Test with testChainlinkPriceNormalization

### Chainlink Integration
- [ ] Implement `getChainlinkPrice()`
  - [ ] Call latestRoundData()
  - [ ] Check staleness
  - [ ] Validate answer > 0
  - [ ] Verify round completion (answeredInRound >= roundId)
  - [ ] Normalize decimals
  - [ ] Check price bounds
  - [ ] Handle exceptions with try/catch
  - [ ] Test with testGetChainlinkPrice

### Price Validation
- [ ] Implement `_isDeviationAcceptable()`
  - [ ] Calculate absolute deviation
  - [ ] Use basis points (10000 = 100%)
  - [ ] Compare with maxPriceDeviation
  - [ ] Handle zero reference price
  - [ ] Test with testPriceDeviationLimit

- [ ] Implement `getValidatedPrice()`
  - [ ] Try Chainlink first
  - [ ] Check deviation from last price
  - [ ] Fall back to fallback oracle
  - [ ] Use last valid price as final fallback
  - [ ] Validate time limits
  - [ ] Test with testGetValidatedPrice

## Phase 3: TWAP Implementation

### Observation Recording
- [ ] Implement `_recordObservation(uint256 price)`
  - [ ] Get last observation
  - [ ] Calculate time delta
  - [ ] Update cumulative price
  - [ ] Create new observation
  - [ ] Handle ring buffer logic
  - [ ] Update index correctly
  - [ ] Emit PriceUpdated event
  - [ ] Test with testRecordObservation

- [ ] Implement `updateObservation(uint256 price)` (public)
  - [ ] Add access control (onlyOwner)
  - [ ] Validate price input
  - [ ] Call _recordObservation
  - [ ] Update lastValidPrice
  - [ ] Update lastPriceUpdate
  - [ ] Test observation updates

### TWAP Calculation
- [ ] Implement `_getObservationAt(uint256 targetTime)`
  - [ ] Search through observations
  - [ ] Find closest before target
  - [ ] Handle ring buffer wrapping
  - [ ] Return appropriate observation
  - [ ] Test edge cases

- [ ] Implement `getTWAP(uint256 period)`
  - [ ] Check observations exist
  - [ ] Handle zero/small period
  - [ ] Get current observation
  - [ ] Calculate target time
  - [ ] Get old observation
  - [ ] Calculate cumulative delta
  - [ ] Calculate time delta
  - [ ] Validate sufficient history
  - [ ] Return TWAP
  - [ ] Test with testTWAPCalculation

## Phase 4: Vault Functions

### Deposits
- [ ] Implement `deposit(uint256 assets)`
  - [ ] Check emergency shutdown
  - [ ] Validate amount > 0
  - [ ] Get validated price
  - [ ] Calculate shares (first deposit vs subsequent)
  - [ ] Transfer assets from user
  - [ ] Mint shares to user
  - [ ] Emit Deposit event
  - [ ] Test with testDeposit

- [ ] Implement `previewDeposit(uint256 assets)`
  - [ ] Handle zero supply case
  - [ ] Calculate expected shares
  - [ ] Test with testPreviewDeposit

### Withdrawals
- [ ] Implement `withdraw(uint256 shares)`
  - [ ] Validate amount > 0
  - [ ] Check user balance
  - [ ] Get TWAP price (safer)
  - [ ] Fall back to spot if TWAP fails
  - [ ] Calculate assets to return
  - [ ] Burn shares from user
  - [ ] Transfer assets to user
  - [ ] Emit Withdraw event
  - [ ] Test with testWithdraw

- [ ] Implement `previewWithdraw(uint256 shares)`
  - [ ] Handle zero supply
  - [ ] Calculate expected assets
  - [ ] Test with testPreviewWithdraw

### Utility Functions
- [ ] Implement `totalValue()`
  - [ ] Return vault balance
  - [ ] Test with testTotalValueAndPricePerShare

- [ ] Implement `pricePerShare()`
  - [ ] Handle zero supply
  - [ ] Calculate price ratio
  - [ ] Use correct precision
  - [ ] Test with testTotalValueAndPricePerShare

## Phase 5: Admin Functions

- [ ] Implement `updatePriceFeed(address newPriceFeed)`
  - [ ] Validate address
  - [ ] Update state variable
  - [ ] Emit event
  - [ ] Test with testUpdatePriceFeed

- [ ] Implement `updateFallbackOracle(address newFallbackOracle)`
  - [ ] Update state variable
  - [ ] Test functionality

- [ ] Implement `updateMaxStaleness(uint256 newMaxStaleness)`
  - [ ] Validate bounds
  - [ ] Update state variable
  - [ ] Test with testUpdateMaxStaleness

- [ ] Implement `updateMaxDeviation(uint256 newMaxDeviation)`
  - [ ] Validate bounds (max 50%)
  - [ ] Update state variable
  - [ ] Test with testUpdateMaxDeviation

- [ ] Implement `setEmergencyShutdown(bool status)`
  - [ ] Update state variable
  - [ ] Emit event
  - [ ] Test with testEmergencyShutdown

- [ ] Implement `emergencyWithdraw(uint256 shares)`
  - [ ] Verify emergency mode active
  - [ ] Validate amount and balance
  - [ ] Calculate assets with last price
  - [ ] Burn shares
  - [ ] Transfer assets
  - [ ] Emit event
  - [ ] Test with testEmergencyWithdraw

## Phase 6: Testing

### Run Individual Test Categories
- [ ] Oracle tests pass
  ```bash
  forge test --match-test testGetChainlinkPrice -vvv
  forge test --match-test testStale -vvv
  forge test --match-test testInvalid -vvv
  ```

- [ ] TWAP tests pass
  ```bash
  forge test --match-test testTWAP -vvv
  forge test --match-test testObservation -vvv
  ```

- [ ] Vault tests pass
  ```bash
  forge test --match-test testDeposit -vvv
  forge test --match-test testWithdraw -vvv
  ```

- [ ] Admin tests pass
  ```bash
  forge test --match-test testUpdate -vvv
  forge test --match-test testEmergency -vvv
  ```

### Run Full Test Suite
- [ ] All tests pass
  ```bash
  forge test
  ```

- [ ] Tests pass with high verbosity
  ```bash
  forge test -vvv
  ```

- [ ] Gas report looks reasonable
  ```bash
  forge test --gas-report
  ```

- [ ] Coverage is good
  ```bash
  forge coverage
  ```

## Phase 7: Code Review and Comparison

- [ ] Compare your implementation with solution
- [ ] Understand security checks in solution
- [ ] Review error handling approaches
- [ ] Study gas optimization techniques
- [ ] Read all security comments
- [ ] Identify improvements in your code

## Phase 8: Advanced Understanding

### Security Deep Dive
- [ ] Can explain why staleness checks matter
- [ ] Understand price manipulation attacks
- [ ] Know when to use TWAP vs spot price
- [ ] Explain circuit breaker necessity
- [ ] Understand decimal handling pitfalls
- [ ] Can identify oracle failure modes

### Design Decisions
- [ ] Why ring buffer for TWAP?
- [ ] Why basis points for deviation?
- [ ] Why 18 decimal normalization?
- [ ] Why TWAP for withdrawals?
- [ ] Why multiple validation layers?
- [ ] Why fallback oracle needed?

### Edge Cases
- [ ] What if oracle is stale?
- [ ] What if price deviates too much?
- [ ] What if both oracles fail?
- [ ] What if TWAP has insufficient data?
- [ ] What if first deposit is huge?
- [ ] What if vault has no balance?

## Phase 9: Extensions (Optional)

- [ ] Add L2 sequencer uptime check
- [ ] Implement multi-asset support
- [ ] Build oracle aggregator (median of 3+)
- [ ] Add governance for parameter updates
- [ ] Implement timelocks
- [ ] Add flash loan protection
- [ ] Create historical price query
- [ ] Build oracle monitoring dashboard

## Phase 10: Deployment

### Testnet Deployment
- [ ] Set up .env file
- [ ] Get testnet ETH
- [ ] Deploy to Sepolia
- [ ] Verify on Etherscan
- [ ] Test with real Chainlink feed
- [ ] Perform real deposits/withdrawals
- [ ] Test emergency scenarios

### Documentation
- [ ] Document deployment addresses
- [ ] Write usage guide
- [ ] Create parameter recommendations
- [ ] Document monitoring procedures
- [ ] Write incident response plan

## Completion Criteria

You've mastered this project when you can:

- [x] ✅ Implement all TODOs correctly
- [x] ✅ Pass all 40+ tests
- [x] ✅ Explain every security check
- [x] ✅ Calculate TWAP by hand
- [x] ✅ Handle all failure modes
- [x] ✅ Deploy to testnet
- [x] ✅ Debug oracle issues
- [x] ✅ Optimize gas usage
- [x] ✅ Review security thoroughly
- [x] ✅ Understand real-world applications

## Final Checklist

- [ ] All tests passing
- [ ] Code reviewed against solution
- [ ] Security understood deeply
- [ ] Gas optimizations considered
- [ ] Edge cases handled
- [ ] Documentation complete
- [ ] Deployed and tested
- [ ] Ready for real-world use

## Time Tracking

Estimated time per phase:
- Phase 1 (Setup): 1 hour
- Phase 2 (Oracle): 2-3 hours
- Phase 3 (TWAP): 2-3 hours
- Phase 4 (Vault): 2-3 hours
- Phase 5 (Admin): 1 hour
- Phase 6 (Testing): 1-2 hours
- Phase 7 (Review): 1-2 hours
- Phase 8 (Understanding): 1-2 hours
- Phase 9 (Extensions): 3-5 hours (optional)
- Phase 10 (Deployment): 1-2 hours

**Total: 12-22 hours** (depending on depth)

## Notes

Use this space to track insights, questions, or issues:

```
Date: _________

Current Phase: _________

Notes:
-
-
-

Questions:
-
-
-

Issues Encountered:
-
-
-

Solutions Found:
-
-
-
```

---

Good luck! Take your time and understand each concept deeply. 🚀
