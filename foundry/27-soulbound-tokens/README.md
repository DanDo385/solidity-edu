# Project 27: Soulbound Tokens (SBTs)

Learn how to implement non-transferable NFTs for identity, credentials, and achievements.

## Table of Contents
- [Overview](#overview)
- [What are Soulbound Tokens?](#what-are-soulbound-tokens)
- [Use Cases](#use-cases)
- [EIP-5192: Minimal Soulbound NFTs](#eip-5192-minimal-soulbound-nfts)
- [Implementation Patterns](#implementation-patterns)
- [Security Considerations](#security-considerations)
- [Privacy Considerations](#privacy-considerations)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Testing](#testing)

## Overview

Soulbound Tokens (SBTs) are non-transferable NFTs that are permanently bound to a specific address. They represent achievements, credentials, reputation, or identity that shouldn't be sold or transferred.

**What You'll Learn:**
- How to prevent token transfers while maintaining ERC721 compatibility
- Different SBT patterns (permanent, revocable, recoverable)
- EIP-5192 standard implementation
- Revocation and recovery mechanisms
- Privacy-preserving techniques for SBTs

**Difficulty:** Advanced

## What are Soulbound Tokens? Non-Transferable Identity

**FIRST PRINCIPLES: Identity vs Property**

Soulbound Tokens are inspired by "soulbound items" in video games - items that become permanently bound to a player and cannot be traded or sold. In Web3, SBTs represent identity and credentials, not transferable property.

**CONNECTION TO PROJECT 09**:
- **Project 09**: ERC721 - transferable NFTs (property)
- **Project 27**: Soulbound Tokens - non-transferable NFTs (identity)
- Same standard (ERC721), different transfer behavior!

Soulbound Tokens serve as:

- **Non-transferable credentials**: Educational degrees, certifications
  - Example: University degree NFT (can't sell your degree!)
  
- **Reputation systems**: On-chain reputation that follows your identity
  - Example: DeFi credit score (personal, not transferable)
  
- **Achievement badges**: Proof of participation or accomplishment
  - Example: POAPs (Proof of Attendance Protocol)
  
- **Identity attestations**: KYC/AML compliance, proof of humanity
  - Example: Verified identity badge
  
- **Membership proofs**: DAO membership, community participation
  - Example: DAO member NFT (proves membership, can't transfer)

### Key Characteristics

**UNDERSTANDING THE RESTRICTIONS**:

1. **Non-transferable**: Cannot be sent to another address
   ```solidity
   // Override transfer functions to revert
   function transferFrom(...) public override {
       revert("Soulbound: non-transferable");
   }
   ```

2. **Revocable (optional)**: Issuer may revoke under certain conditions
   - Example: Degree revoked due to fraud
   - Example: Certification expired

3. **Recoverable (optional)**: Can be recovered if wallet is compromised
   - Example: Lost private key recovery mechanism
   - Trade-off: Security vs permanence

4. **Publicly verifiable**: Anyone can verify credentials on-chain
   - Example: Employer can verify degree on-chain
   - Transparency benefit

5. **Privacy-aware**: May use techniques to protect holder privacy
   - Example: Zero-knowledge proofs for private credentials
   - Balance: Verifiability vs privacy

**COMPARISON TO STANDARD ERC721** (from Project 09):

**Standard ERC721**:
```solidity
function transferFrom(address from, address to, uint256 tokenId) public {
    // Transfers token ✅
    // Can be sold, traded, gifted
}
```

**Soulbound Token**:
```solidity
function transferFrom(address from, address to, uint256 tokenId) public override {
    revert("Soulbound: non-transferable");  // ❌ Always reverts
    // Cannot be sold, traded, or gifted
    // Permanently bound to original owner
}
```

**REAL-WORLD ANALOGY**: 
Like a driver's license:
- **Standard NFT**: Can be transferred (like cash - can give it away)
- **Soulbound Token**: Cannot be transferred (like your license - tied to you)

## Use Cases

### 1. Educational Credentials
```solidity
// University issues degree SBTs
// - Non-transferable (you can't sell your degree)
// - Revocable (if fraud is discovered)
// - Non-recoverable (tied to your identity)
```

### 2. Professional Certifications
```solidity
// Professional bodies issue certification SBTs
// - Non-transferable
// - Revocable (if certification expires or is revoked)
// - May have expiration dates
```

### 3. Event Attendance (POAPs)
```solidity
// Proof of Attendance Protocols
// - Non-transferable
// - Non-revocable (you attended, period)
// - Collectible achievements
```

### 4. Reputation Systems
```solidity
// DeFi protocol credit scores
// - Non-transferable (reputation is personal)
// - Dynamic (updates based on behavior)
// - May be recoverable (if wallet compromised)
```

### 5. Identity & KYC
```solidity
// Know Your Customer compliance
// - Non-transferable
// - Revocable (if verification status changes)
// - Recoverable (allow wallet migration)
// - Privacy-preserving (zero-knowledge proofs)
```

### 6. DAO Membership
```solidity
// Membership tokens for DAOs
// - Non-transferable
// - Revocable (if member is removed)
// - May grant voting rights
```

## EIP-5192: Minimal Soulbound NFTs

[EIP-5192](https://eips.ethereum.org/EIPS/eip-5192) proposes a minimal standard for soulbound tokens:

### Interface

```solidity
interface IERC5192 {
    /// @notice Emitted when the locking status is changed to locked.
    /// @dev If a token is minted and the status is locked, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event Locked(uint256 tokenId);

    /// @notice Emitted when the locking status is changed to unlocked.
    /// @dev If a token is minted and the status is unlocked, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event Unlocked(uint256 tokenId);

    /// @notice Returns the locking status of an Soulbound Token
    /// @dev SBTs assigned to zero address are considered invalid, and queries
    /// about them do throw.
    /// @param tokenId The identifier for an SBT.
    function locked(uint256 tokenId) external view returns (bool);
}
```

### Key Points

- **`locked(uint256 tokenId)`**: Returns whether a token is locked (soulbound)
- **Events**: `Locked` and `Unlocked` events for status changes
- **Flexibility**: Tokens can be permanently or conditionally locked
- **Compatibility**: Works alongside ERC721

## Implementation Patterns

### Pattern 1: Permanently Soulbound

Tokens are **never** transferable after minting.

```solidity
contract PermanentSoulbound is ERC721 {
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal virtual override returns (address) {
        address from = _ownerOf(tokenId);

        // Allow minting (from == address(0))
        // Allow burning (to == address(0))
        // Reject all transfers
        if (from != address(0) && to != address(0)) {
            revert("Soulbound: Transfer not allowed");
        }

        return super._update(to, tokenId, auth);
    }
}
```

**Use Cases:**
- Educational degrees
- Attendance proofs
- Historical achievements

### Pattern 2: Revocable Soulbound

Issuer can revoke (burn) tokens under certain conditions.

```solidity
contract RevocableSoulbound is PermanentSoulbound {
    mapping(uint256 => address) public issuer;

    function revoke(uint256 tokenId) external {
        require(msg.sender == issuer[tokenId], "Not issuer");
        _burn(tokenId);
    }
}
```

**Use Cases:**
- Certifications with expiration
- Conditional credentials
- Reputation systems

### Pattern 3: Recoverable Soulbound

Allows recovery to a new address (e.g., if wallet is compromised).

```solidity
contract RecoverableSoulbound is RevocableSoulbound {
    function recover(uint256 tokenId, address newOwner) external {
        require(msg.sender == ownerOf(tokenId), "Not owner");
        require(newOwner != address(0), "Invalid address");

        // Special transfer allowed for recovery
        _transfer(msg.sender, newOwner, tokenId);
    }
}
```

**Use Cases:**
- Identity tokens
- High-value credentials
- Long-term reputation

### Pattern 4: Time-Locked Soulbound

Tokens become soulbound after a certain period.

```solidity
contract TimeLockedSoulbound is ERC721 {
    mapping(uint256 => uint256) public lockTime;
    uint256 public constant LOCK_DURATION = 30 days;

    function locked(uint256 tokenId) public view returns (bool) {
        return block.timestamp >= lockTime[tokenId];
    }

    function _update(...) internal virtual override returns (address) {
        if (locked(tokenId) && from != address(0) && to != address(0)) {
            revert("Soulbound: Token is locked");
        }
        return super._update(to, tokenId, auth);
    }
}
```

**Use Cases:**
- Vesting credentials
- Gradual commitment proofs
- Probationary memberships

### Pattern 5: Conditionally Soulbound

Tokens are soulbound based on certain conditions.

```solidity
contract ConditionalSoulbound is ERC721 {
    mapping(uint256 => bool) public isSoulbound;

    function makeNonTransferable(uint256 tokenId) external {
        require(msg.sender == ownerOf(tokenId), "Not owner");
        isSoulbound[tokenId] = true;
        emit Locked(tokenId);
    }
}
```

**Use Cases:**
- Optional permanence
- User choice in credential binding
- Hybrid systems

## Security Considerations

### 1. Transfer Prevention

**Challenge**: Must block all transfer methods while allowing mint/burn.

```solidity
// Override all transfer functions
function _update(address to, uint256 tokenId, address auth)
    internal virtual override returns (address)
{
    // Check transfer conditions
}

// Also consider: safeTransferFrom, transferFrom, approve, setApprovalForAll
```

### 2. Revocation Authority

**Challenge**: Who can revoke and under what conditions?

```solidity
// Options:
// 1. Only issuer
// 2. Multi-sig governance
// 3. Holder + issuer (mutual consent)
// 4. On-chain conditions (e.g., expiration)

// Best Practice: Emit events for transparency
event Revoked(uint256 indexed tokenId, address indexed holder, string reason);
```

### 3. Recovery Mechanism

**Challenge**: Prevent abuse while allowing legitimate recovery.

```solidity
// Security measures:
// 1. Time delays
// 2. Multi-signature approval
// 3. Social recovery (guardians)
// 4. On-chain proof requirements

// Example: Time-delayed recovery
mapping(uint256 => RecoveryRequest) public recoveryRequests;

struct RecoveryRequest {
    address newOwner;
    uint256 requestTime;
}

function initiateRecovery(uint256 tokenId, address newOwner) external {
    require(msg.sender == ownerOf(tokenId), "Not owner");
    recoveryRequests[tokenId] = RecoveryRequest(newOwner, block.timestamp);
}

function completeRecovery(uint256 tokenId) external {
    RecoveryRequest memory req = recoveryRequests[tokenId];
    require(block.timestamp >= req.requestTime + DELAY, "Too early");
    _transfer(ownerOf(tokenId), req.newOwner, tokenId);
}
```

### 4. Issuer Centralization

**Risk**: Single issuer has too much power.

**Mitigations:**
- Multi-sig issuers
- DAO governance for revocations
- Immutable credentials (no revocation)
- On-chain evidence requirements

### 5. Front-Running

**Risk**: MEV bots could front-run revocations or recoveries.

**Mitigations:**
- Time locks
- Commit-reveal schemes
- Private mempools (Flashbots)

## Privacy Considerations

### 1. Public Visibility

**Issue**: SBTs are publicly visible on-chain.

**Implications:**
- Anyone can see your credentials
- Can build profiles of individuals
- May reveal sensitive information

### 2. Selective Disclosure

**Solution**: Use zero-knowledge proofs.

```solidity
// Instead of storing credential on-chain:
// Store commitment: hash(credential + salt)

// Prove you have credential without revealing it:
function verifyCredential(
    bytes32 commitment,
    bytes calldata zkProof
) external view returns (bool);
```

### 3. Privacy-Preserving Patterns

**Pattern A: Merkle Tree Storage**
```solidity
// Store only merkle root of all credentials
// Prove membership without revealing which credential
bytes32 public credentialRoot;

function verify(
    bytes32 leaf,
    bytes32[] calldata proof
) external view returns (bool);
```

**Pattern B: Encrypted Metadata**
```solidity
// Store encrypted credential data
// Only holder can decrypt
mapping(uint256 => bytes) public encryptedMetadata;
```

**Pattern C: Separate Verification Contract**
```solidity
// SBT contract: Private, minimal info
// Verification contract: Public interface
// Verifiers query without seeing full credentials
```

### 4. Correlation Resistance

**Issue**: Multiple SBTs can be correlated to deanonymize users.

**Mitigations:**
- Use different addresses for different contexts
- Stealth addresses
- Zero-knowledge set membership proofs

## Project Structure

```
27-soulbound-tokens/
├── README.md
├── src/
│   ├── Project27.sol                 # Skeleton contract with TODOs
│   └── solution/
│       └── Project27Solution.sol     # Complete implementation
├── test/
│   └── Project27.t.sol              # Comprehensive test suite
└── script/
    └── DeployProject27.s.sol        # Deployment script
```

## Getting Started

### Step 1: Study the Skeleton

Open `src/Project27.sol` and read through the TODO comments.

### Step 2: Implement Core Features

1. **Permanent Soulbound**: Prevent all transfers
2. **Revocable Pattern**: Add issuer revocation
3. **Recoverable Pattern**: Implement recovery mechanism
4. **EIP-5192**: Add `locked()` function and events

### Step 3: Run Tests

```bash
forge test --match-path test/Project27.t.sol -vvv
```

### Step 4: Compare with Solution

Study `src/solution/Project27Solution.sol` to see best practices.

## Testing

The test suite covers:

### Transfer Prevention
- Cannot transfer after minting
- Cannot use safeTransferFrom
- Cannot approve others
- Can still mint and burn

### Revocation
- Only issuer can revoke
- Revocation burns token
- Events emitted correctly
- Non-issuer cannot revoke

### Recovery
- Owner can initiate recovery
- Time delay enforced
- Recovery completes successfully
- Non-owner cannot initiate

### EIP-5192 Compliance
- `locked()` returns correct status
- Events emitted on mint
- Interface support detected

### Edge Cases
- Recovery to zero address blocked
- Recovery cancellation
- Multiple simultaneous recoveries
- Revocation during recovery period

## Key Takeaways

1. **SBTs are not just "locked" NFTs** - they represent a new primitive for identity and reputation
2. **Transfer prevention requires careful implementation** - must override all transfer paths
3. **Revocation and recovery are trade-offs** - more flexibility means more attack surface
4. **Privacy is critical** - consider what information you're revealing on-chain
5. **Standards matter** - EIP-5192 provides interoperability
6. **Use cases drive design** - permanent degree ≠ revocable certification ≠ recoverable identity

## Advanced Topics

### Multi-Token Soulbound (ERC1155)

```solidity
// Multiple non-transferable token types
contract SoulboundBadges is ERC1155 {
    // Achievement system with multiple badge types
}
```

### Composable SBTs

```solidity
// SBTs that grant access to other SBTs
// E.g., Bachelor's degree → Master's degree → PhD
```

### Reputation Scoring

```solidity
// Dynamic SBTs that update based on behavior
contract ReputationSBT {
    mapping(uint256 => uint256) public reputationScore;
}
```

### Cross-Chain SBTs

```solidity
// SBTs that exist on multiple chains
// Using LayerZero, Axelar, or other bridges
```

## Resources

- [EIP-5192: Minimal Soulbound NFTs](https://eips.ethereum.org/EIPS/eip-5192)
- [Vitalik's SBT Paper: "Decentralized Society"](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4105763)
- [OpenZeppelin ERC721 Documentation](https://docs.openzeppelin.com/contracts/4.x/erc721)
- [Privacy-Preserving Credentials](https://zkp.science/)

## License

MIT
