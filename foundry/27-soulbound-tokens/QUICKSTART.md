# Project 27: Soulbound Tokens - Quick Start Guide

## Overview
This project teaches you how to implement non-transferable NFTs (Soulbound Tokens) with various patterns including revocation and recovery mechanisms.

## Project Structure
```
27-soulbound-tokens/
├── README.md                           # Comprehensive educational guide (521 lines)
├── QUICKSTART.md                       # This file
├── src/
│   ├── Project27.sol                   # Skeleton with TODOs (344 lines)
│   └── solution/
│       └── Project27Solution.sol       # Complete solution (669 lines)
├── test/
│   └── Project27.t.sol                 # 52 test functions (740 lines)
└── script/
    └── DeployProject27.s.sol          # Deployment scripts (296 lines)
```

## Key Concepts Covered

### 1. EIP-5192 Compliance
- `locked(uint256)` view function
- `Locked` and `Unlocked` events
- Interface support detection

### 2. Transfer Prevention
- Override `_update()` to block transfers
- Allow minting and burning
- Special handling for recovery

### 3. Revocation Mechanism
- Issuer-based revocation rights
- Token burning on revocation
- Transparent event emission

### 4. Recovery Mechanism
- Two-step recovery process (initiate → complete)
- 7-day time delay for security
- Cancellable during delay period
- Helps with lost/compromised wallets

## Implementation Patterns in Solution

1. **SoulboundTokenSolution** - Main implementation with all features
2. **PermanentSoulboundToken** - Simplest: permanently non-transferable
3. **TimeLockedSoulboundToken** - Becomes soulbound after time period
4. **DynamicSoulboundToken** - Updatable reputation scores

## Learning Path

### Step 1: Read the README (30-45 minutes)
- Understand what soulbound tokens are
- Learn different use cases
- Study implementation patterns
- Review security considerations

### Step 2: Study the Skeleton (15 minutes)
- Read through `src/Project27.sol`
- Understand the contract structure
- Review the TODO comments

### Step 3: Implement Core Features (2-3 hours)
Start with these TODOs in order:
1. `mint()` - Basic token issuance
2. `locked()` - EIP-5192 compliance
3. `_update()` - Transfer prevention
4. `revoke()` - Token revocation
5. `initiateRecovery()` - Start recovery
6. `completeRecovery()` - Finish recovery
7. `cancelRecovery()` - Cancel recovery

### Step 4: Run Tests
```bash
forge test --match-path test/Project27.t.sol -vv
```

### Step 5: Study the Solution
Compare your implementation with `src/solution/Project27Solution.sol`

## Test Coverage

The test suite includes:
- ✅ Minting (4 tests)
- ✅ EIP-5192 Compliance (4 tests)
- ✅ Transfer Prevention (6 tests)
- ✅ Revocation (6 tests)
- ✅ Recovery Initiation (6 tests)
- ✅ Recovery Completion (6 tests)
- ✅ Recovery Cancellation (5 tests)
- ✅ Complex Scenarios (4 tests)
- ✅ View Functions (3 tests)
- ✅ Fuzz Tests (3 tests)
- ✅ Alternative Patterns (5 tests)

**Total: 52 comprehensive tests**

## Key Implementation Details

### Transfer Matrix
| From       | To         | Operation | Allowed? |
|------------|------------|-----------|----------|
| address(0) | any        | Mint      | ✅       |
| any        | address(0) | Burn      | ✅       |
| any        | any        | Transfer  | ❌       |
| any        | any        | Recovery  | ✅ (flag)|

### Security Features
1. **Time Delay**: 7-day recovery period
2. **Access Control**: Only issuer can revoke
3. **Cancellation**: Owner can cancel recovery
4. **Validation**: Comprehensive input validation
5. **Events**: Transparent event emission

### Gas Optimizations
- Custom errors (saves ~50 gas per revert)
- State cleanup on revocation
- Packed structs where possible
- Minimal storage slots

## Common Pitfalls to Avoid

1. ❌ **Not overriding ALL transfer paths**
   - Must override `_update()`, not individual transfer functions

2. ❌ **Forgetting to allow minting and burning**
   - Check `from` and `to` addresses carefully

3. ❌ **Not handling recovery in _update()**
   - Need special flag to allow recovery transfers

4. ❌ **Missing validation in recovery**
   - Always check for zero address, same address, etc.

5. ❌ **Not cleaning up state**
   - Delete recovery requests when done

## Deployment

### Local Testing
```bash
# Deploy skeleton
forge script script/DeployProject27.s.sol:DeployProject27 --fork-url <RPC_URL>

# Deploy solution
forge script script/DeployProject27.s.sol:DeployProject27Solution --fork-url <RPC_URL>

# Deploy all patterns
forge script script/DeployProject27.s.sol:DeployAllPatterns --fork-url <RPC_URL>
```

### Testnet Deployment
```bash
forge script script/DeployProject27.s.sol:DeployProject27Solution \
  --rpc-url $RPC_URL \
  --broadcast \
  --verify
```

## Real-World Use Cases

1. **Educational Credentials**: Universities issuing degrees
2. **Professional Certifications**: Medical licenses, bar admissions
3. **Event Attendance**: POAPs for conferences/events
4. **Reputation Systems**: DeFi credit scores
5. **Identity**: KYC/AML attestations
6. **Membership**: DAO participation tokens

## Advanced Challenges

Once you complete the basic implementation, try:

1. **Privacy Enhancement**: Add zero-knowledge proofs
2. **Batch Operations**: Mint multiple tokens efficiently
3. **Metadata**: Add ERC721Metadata with IPFS
4. **Expiration**: Add time-based expiration
5. **Delegation**: Allow credential delegation (view-only)
6. **Composability**: Create dependent credentials

## Resources

- [EIP-5192 Specification](https://eips.ethereum.org/EIPS/eip-5192)
- [Vitalik's SBT Paper](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4105763)
- [OpenZeppelin Docs](https://docs.openzeppelin.com/contracts/4.x/)

## Need Help?

If you get stuck:
1. Read the detailed comments in the solution
2. Review the test cases to understand expected behavior
3. Check the README for implementation patterns
4. Study alternative implementations for different approaches

## Success Criteria

You've successfully completed this project when:
- ✅ All tests pass
- ✅ Tokens cannot be transferred after minting
- ✅ Issuers can revoke their tokens
- ✅ Owners can recover tokens with time delay
- ✅ EIP-5192 interface is supported
- ✅ All edge cases are handled

Good luck! 🚀
