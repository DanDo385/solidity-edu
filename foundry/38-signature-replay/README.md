# Project 38: Signature Replay Attack

Learn about signature replay vulnerabilities and how to protect against them in Solidity smart contracts.

## Overview

Signature replay attacks occur when a valid signature can be reused maliciously in ways not intended by the signer. This project explores various replay attack vectors and demonstrates proper defenses using nonces, chainID, domain separators, and EIP-712.

## Vulnerability Categories

### 1. Missing Nonce Vulnerability: Infinite Replay

**FIRST PRINCIPLES: Signature Uniqueness**

The most common replay attack occurs when contracts don't track which signatures have been used. Signatures must be unique per transaction!

**CONNECTION TO PROJECT 19 & 23**:
- **Project 19**: We learned about EIP-712 signatures
- **Project 23**: ERC20 Permit uses signatures with nonces
- **Project 38**: Missing nonces allow signature replay attacks!

**THE VULNERABILITY**:

```solidity
// ❌ VULNERABLE: Signature can be replayed infinitely
function transfer(address to, uint256 amount, bytes memory signature) external {
    bytes32 message = keccak256(abi.encodePacked(to, amount));
    address signer = recover(message, signature);  // From Project 19!
    // ❌ No nonce tracking - signature can be reused!
    _transfer(signer, to, amount);
}
```

**ATTACK SCENARIO**:

```
Signature Replay Attack:
┌─────────────────────────────────────────┐
│ User signs: transfer(alice, 100)        │
│   Signature: 0xABCD...                 │ ← Valid signature
│   ↓                                      │
│ Legitimate use:                         │
│   Contract verifies signature ✅         │
│   Transfers 100 tokens                  │
│   ↓                                      │
│ Attacker observes transaction           │ ← Mempool observation
│   ↓                                      │
│ Attacker replays same signature         │ ← Reuse signature!
│   Contract verifies signature ✅         │ ← Still valid!
│   Transfers 100 tokens again            │ ← Funds drained!
│   ↓                                      │
│ Attacker repeats infinitely             │ ← Can replay forever!
└─────────────────────────────────────────┘
```

**WHY IT WORKS**:
- Signature is valid for the message (to, amount)
- No tracking of used signatures
- Same signature can be submitted multiple times
- Each submission transfers funds!

**THE FIX** (Nonce Tracking):

```solidity
// ✅ SAFE: Nonce tracking prevents replay
mapping(address => uint256) public nonces;  // From Project 01!

function transfer(
    address to, 
    uint256 amount, 
    uint256 nonce,  // ✅ Include nonce!
    bytes memory signature
) external {
    require(nonce == nonces[msg.sender], "Invalid nonce");  // ✅ Check nonce
    nonces[msg.sender]++;  // ✅ Increment nonce (prevents replay!)
    
    bytes32 message = keccak256(abi.encodePacked(to, amount, nonce));  // ✅ Include nonce in message
    address signer = recover(message, signature);
    require(signer == msg.sender, "Invalid signature");
    
    _transfer(signer, to, amount);
}
```

**HOW NONCES PREVENT REPLAY**:

```
Nonce Protection Flow:
┌─────────────────────────────────────────┐
│ User signs: transfer(alice, 100, nonce=5)│
│   Signature: 0xABCD...                  │ ← Includes nonce
│   ↓                                      │
│ First use:                              │
│   Check: nonce == 5? ✅                 │ ← Matches!
│   nonces[user] = 6                      │ ← Incremented
│   Transfer succeeds                     │
│   ↓                                      │
│ Attacker replays signature:             │
│   Check: nonce == 5? ❌                 │ ← Nonce is now 6!
│   Transaction REVERTS                   │ ← Replay prevented!
└─────────────────────────────────────────┘
```

**GAS COST** (from Project 01 & 19 knowledge):
- Nonce check: ~100 gas (SLOAD)
- Nonce increment: ~5,000 gas (SSTORE)
- Signature verification: ~3,000 gas (ecrecover)
- Total: ~8,100 gas (small cost for security!)

**REAL-WORLD ANALOGY**: 
Like a checkbook - each check has a unique number. If you reuse a check number, the bank rejects it. Nonces are like check numbers - each signature must have a unique nonce!

### 2. ChainID Replay Attack
Without chainID in signatures, they can be replayed across different blockchain networks:
```solidity
// VULNERABLE: Works on mainnet, can replay on testnets or forks
bytes32 message = keccak256(abi.encodePacked(to, amount, nonce));
```

**Attack**: Use a signature from mainnet on a testnet, or replay after a hard fork.

### 3. Cross-Contract Replay
Signatures valid for one contract can be replayed on another contract:
```solidity
// VULNERABLE: Missing contract address in message
bytes32 message = keccak256(abi.encodePacked(to, amount, nonce));
```

**Attack**: Use a signature intended for ContractA on ContractB.

### 4. Timestamp-Only Protection (Weak)
Using only timestamps for replay protection is insufficient:
```solidity
// WEAK: Attacker can replay within the time window
function transfer(uint256 deadline, ...) external {
    require(block.timestamp <= deadline, "Expired");
    // No nonce - can replay until deadline!
}
```

## Proper Defenses

### Defense 1: Nonce Tracking
Track used nonces per user:
```solidity
mapping(address => uint256) public nonces;

function transfer(address to, uint256 amount, uint256 nonce, bytes memory sig) external {
    require(nonce == nonces[msg.sender], "Invalid nonce");
    nonces[msg.sender]++;

    bytes32 message = keccak256(abi.encodePacked(to, amount, nonce));
    address signer = recover(message, sig);
    require(signer == msg.sender, "Invalid signature");

    _transfer(signer, to, amount);
}
```

### Defense 2: ChainID Protection
Include chainID in the message:
```solidity
bytes32 message = keccak256(abi.encodePacked(
    to,
    amount,
    nonce,
    block.chainid  // Prevents cross-chain replay
));
```

### Defense 3: Domain Separator (EIP-712)
Use EIP-712 structured data hashing:
```solidity
bytes32 public DOMAIN_SEPARATOR;

constructor() {
    DOMAIN_SEPARATOR = keccak256(abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes("MyContract")),
        keccak256(bytes("1")),
        block.chainid,
        address(this)
    ));
}

function hashTypedData(bytes32 structHash) internal view returns (bytes32) {
    return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
}
```

### Defense 4: Signature Invalidation
Allow users to invalidate signatures:
```solidity
mapping(bytes32 => bool) public invalidatedSignatures;

function invalidateSignature(bytes32 sigHash) external {
    invalidatedSignatures[sigHash] = true;
}
```

## EIP-712 Standard

EIP-712 provides structured, human-readable signatures with built-in replay protection:

```solidity
// Define typed data structure
bytes32 public constant TRANSFER_TYPEHASH = keccak256(
    "Transfer(address from,address to,uint256 amount,uint256 nonce)"
);

function verifyTransferSignature(
    address from,
    address to,
    uint256 amount,
    uint256 nonce,
    bytes memory signature
) internal view returns (bool) {
    bytes32 structHash = keccak256(abi.encode(
        TRANSFER_TYPEHASH,
        from,
        to,
        amount,
        nonce
    ));

    bytes32 digest = keccak256(abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        structHash
    ));

    address signer = ECDSA.recover(digest, signature);
    return signer == from && nonces[from] == nonce;
}
```

## Real-World Replay Exploits

### 1. Classic Ethereum (ETC) Replay (2016)
After the DAO hard fork, transactions on Ethereum mainnet could be replayed on Ethereum Classic because chainID wasn't universally implemented.

**Impact**: Millions of dollars in unintended transfers.

### 2. Wintermute Hack (2022)
While not purely a replay attack, missing signature validation allowed unauthorized transfers.

**Impact**: $160 million loss.

### 3. Multiple DEX Permit Exploits (2020-2023)
DEXs using EIP-2612 permits without proper nonce/deadline checks suffered replay attacks.

**Impact**: Various losses from repeated permit executions.

### 4. Cross-Chain Bridge Replays
Several bridges lacked proper chainID validation, allowing signatures to be replayed on different chains.

**Impact**: Double-spending across chains.

## Attack Scenarios

### Scenario 1: Token Transfer Replay
```solidity
// User signs: "Transfer 100 tokens to Alice"
// Attacker: Replays signature 10 times
// Result: 1000 tokens transferred instead of 100
```

### Scenario 2: Voting Replay
```solidity
// User signs: "Vote Yes on Proposal #5"
// Attacker: Replays signature multiple times
// Result: Vote count manipulated
```

### Scenario 3: Cross-Chain Airdrop Abuse
```solidity
// User signs airdrop claim on testnet
// Attacker: Replays on mainnet
// Result: Unauthorized mainnet claim
```

### Scenario 4: Meta-Transaction Replay
```solidity
// User signs gasless transaction
// Relayer: Submits transaction
// Attacker: Front-runs and replays
// Result: Double execution, user pays twice
```

## Best Practices

1. **Always Use Nonces**: Track per-user nonces for sequential ordering
2. **Include ChainID**: Prevent cross-chain replay attacks
3. **Use EIP-712**: Standard format for structured, safe signatures
4. **Add Contract Address**: Prevent cross-contract replay
5. **Implement Deadlines**: Add expiration for time-sensitive operations
6. **Signature Invalidation**: Allow users to revoke signatures
7. **Audit Carefully**: Signature logic is complex and error-prone

## Common Pitfalls

- Forgetting to increment nonces after use
- Using `block.timestamp` alone without nonces
- Not including chainID in signature messages
- Reusing signatures across different functions
- Allowing zero address as signer
- Not validating signature length
- Missing domain separator updates on upgrades

## Connection to Project 19

Project 19 covers basic signature verification and ECDSA. This project extends those concepts to:
- Advanced signature security
- Replay attack prevention
- Production-ready signature schemes
- EIP-712 implementation

## Learning Objectives

After completing this project, you will understand:
1. How signature replay attacks work
2. Why nonces are critical for signature security
3. The importance of chainID and domain separators
4. How to implement EIP-712 properly
5. Real-world replay attack vectors
6. Best practices for signature verification

## Testing Guide

The test suite demonstrates:
- Basic replay attacks on vulnerable contracts
- Nonce protection effectiveness
- ChainID validation
- Cross-contract replay prevention
- EIP-712 signature verification
- Proper signature invalidation

## Project Structure

```
38-signature-replay/
├── README.md                          # This file
├── src/
│   ├── Project38.sol                  # Skeleton with TODOs
│   └── solution/
│       └── Project38Solution.sol      # Complete implementation
├── test/
│   └── Project38.t.sol                # Comprehensive tests
└── script/
    └── DeployProject38.s.sol          # Deployment script
```

## Resources

- [EIP-712: Typed Structured Data Hashing](https://eips.ethereum.org/EIPS/eip-712)
- [EIP-2612: Permit Extension for ERC-20](https://eips.ethereum.org/EIPS/eip-2612)
- [OpenZeppelin ECDSA Library](https://docs.openzeppelin.com/contracts/4.x/api/utils#ECDSA)
- [Consensys: Signature Replay Attacks](https://consensys.github.io/smart-contract-best-practices/attacks/replay-attacks/)

## Setup

```bash
# Install dependencies
forge install

# Run tests
forge test --match-path test/Project38.t.sol -vvv

# Run specific test
forge test --match-test testReplayAttack -vvv

# Deploy
forge script script/DeployProject38.s.sol --rpc-url $RPC_URL --broadcast
```

## Exercises

1. **Basic Replay**: Exploit the vulnerable contract by replaying a signature
2. **Add Nonce Protection**: Fix the vulnerable contract with nonce tracking
3. **ChainID Attack**: Demonstrate cross-chain replay vulnerability
4. **Implement EIP-712**: Create a secure signature scheme using EIP-712
5. **Cross-Contract Replay**: Show how signatures can be replayed across contracts
6. **Advanced Defense**: Combine multiple protections for maximum security

## Security Checklist

- [ ] Nonces implemented and incremented
- [ ] ChainID included in signature
- [ ] Contract address in domain separator
- [ ] EIP-712 standard followed
- [ ] Signature length validated
- [ ] Zero address checks present
- [ ] Deadline/expiration implemented
- [ ] Tests cover replay scenarios
- [ ] Signature invalidation available
- [ ] No signature reuse across functions

---

**Remember**: Signature security is critical. A single mistake can lead to catastrophic fund loss. Always use established standards like EIP-712 and thoroughly test signature handling logic.
