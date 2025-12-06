# Project 19: Signed Messages & EIP-712

Learn about cryptographic signatures, EIP-712 typed structured data, and how to build secure off-chain authorization systems in Solidity.

## Table of Contents
- [Overview](#overview)
- [Cryptographic Signatures Primer](#cryptographic-signatures-primer)
- [EIP-191: Signed Data Standard](#eip-191-signed-data-standard)
- [EIP-712: Typed Structured Data](#eip-712-typed-structured-data)
- [Domain Separators](#domain-separators)
- [Signature Verification](#signature-verification)
- [Replay Protection](#replay-protection)
- [Implementation Guide](#implementation-guide)
- [Security Considerations](#security-considerations)
- [Real-World Applications](#real-world-applications)

## Overview

This project teaches you how to implement **EIP-712** (Typed Structured Data Hashing and Signing), a standard for creating human-readable, type-safe signatures that can be verified on-chain.

### What You'll Learn
- How ECDSA signatures work in Ethereum
- Difference between EIP-191 and EIP-712
- How to construct domain separators
- Typed structured data hashing
- On-chain signature verification
- Replay attack prevention with nonces
- Cross-chain replay protection with chainId
- Permit-style meta-transactions

### Use Cases
- **Gasless transactions** (meta-transactions)
- **ERC20 Permit** (approve via signature)
- **NFT lazy minting** (claim with signature)
- **DAO voting** (off-chain signatures)
- **Vouchers and coupons** (one-time use signatures)

## Cryptographic Signatures Primer: ECDSA in Ethereum

**FIRST PRINCIPLES: Asymmetric Cryptography**

Ethereum uses ECDSA (Elliptic Curve Digital Signature Algorithm) over the secp256k1 curve for signatures. Understanding how signatures work is essential for meta-transactions and permit patterns!

**CONNECTION TO PROJECT 08**:
ERC20 Permit (EIP-2612) uses signatures to approve tokens without a transaction! This project teaches the fundamentals behind permit.

### ECDSA (Elliptic Curve Digital Signature Algorithm)

Ethereum uses ECDSA over the secp256k1 curve. Here's how it works:

```
ECDSA Signature Flow:
┌─────────────────────────────────────────┐
│ Private Key (secret, 256 bits)          │ ← Only signer knows
│   ↓                                      │
│ Public Key (derived, 512 bits)          │ ← Can be shared
│   ↓                                      │
│ Ethereum Address (keccak256(public)[12:])│ ← 20 bytes
│   ↓                                      │
│ Sign Message                            │ ← Off-chain operation
│   ↓                                      │
│ Signature (v, r, s) - 65 bytes         │ ← Can be verified
│   ↓                                      │
│ Verify: Message + Signature → Address   │ ← On-chain verification
└─────────────────────────────────────────┘
```

**UNDERSTANDING THE MATHEMATICS** (DSA Concept):

ECDSA uses elliptic curve cryptography:
- **Private Key**: Random 256-bit number (secret)
- **Public Key**: Point on elliptic curve (derived from private key)
- **Signature**: Mathematical proof that private key holder signed message
- **Verification**: Mathematical operation that recovers public key from signature

**COMPARISON TO RUST** (DSA Concept):

**Rust** (using secp256k1 crate):
```rust
use secp256k1::{SecretKey, PublicKey, Message, Signature};

let secret = SecretKey::from_slice(&private_key_bytes)?;
let public = PublicKey::from_secret_key(&secret);
let message = Message::from_slice(&message_hash)?;
let signature = secret.sign_ecdsa(&message);
// Same ECDSA algorithm, different language
```

**Solidity** (using ecrecover):
```solidity
address signer = ecrecover(messageHash, v, r, s);
// Built-in EVM function for signature recovery
```

Both use the same ECDSA algorithm - Solidity just provides built-in recovery!

### Signature Components

An Ethereum signature consists of three parts:
- **v** (1 byte): Recovery identifier (27 or 28, sometimes 0 or 1)
  - Indicates which of two possible public keys to use
  - 27 = uncompressed, 28 = compressed (legacy)
  - 0/1 = EIP-155 compatible (chainId encoded)
  
- **r** (32 bytes): First part of the signature
  - X coordinate on elliptic curve (mod n)
  
- **s** (32 bytes): Second part of the signature
  - Signature proof value

**Total: 65 bytes** (1 + 32 + 32)

**UNDERSTANDING RECOVERY**:

```
Signature Recovery:
┌─────────────────────────────────────────┐
│ Input: messageHash, v, r, s            │
│   ↓                                      │
│ ecrecover(messageHash, v, r, s)        │ ← EVM opcode
│   ↓                                      │
│ Mathematical operation                  │ ← Elliptic curve math
│   ↓                                      │
│ Output: address (public key)           │ ← Signer's address
└─────────────────────────────────────────┘
```

**GAS COST**:
- `ecrecover()`: ~3,000 gas (expensive cryptographic operation!)
- Signature verification is one of the most expensive operations in Solidity

### Signing Process

```solidity
// Off-chain (TypeScript):
const messageHash = ethers.utils.keccak256(message);
const signature = await signer.signMessage(messageHash);
// signature = 0x... (130 hex chars = 65 bytes)

// Split signature:
const { v, r, s } = ethers.utils.splitSignature(signature);
```

### Verification Process

```solidity
// On-chain (Solidity):
address signer = ecrecover(messageHash, v, r, s);
require(signer == expectedSigner, "Invalid signature");
```

## EIP-191: Signed Data Standard

**EIP-191** defines a standard for signed data to prevent confusion between different types of data:

```
0x19 <1 byte version> <version specific data> <data to sign>
```

### Version 0x00: Data with intended validator
```
0x19 0x00 <20 bytes validator address> <data>
```

### Version 0x01: Structured data (EIP-712)
```
0x19 0x01 <32 bytes domainSeparator> <32 bytes structHash>
```

### Version 0x45: Personal message
```
0x19 "Ethereum Signed Message:\n" <length> <message>
```

This is what `eth_sign` and `personal_sign` use automatically.

## EIP-712: Typed Structured Data

**EIP-712** provides a standard for hashing and signing typed structured data, making signatures:
- **Human-readable**: Users can see what they're signing
- **Type-safe**: Structured data with types
- **Domain-specific**: Bound to specific contracts/chains
- **Replay-protected**: Nonces and deadlines

### EIP-712 Structure

```
Final Hash = keccak256(0x19 0x01 <domainSeparator> <structHash>)
```

Where:
- `domainSeparator`: Uniquely identifies the signing domain
- `structHash`: Hash of the typed structured data

### Type Hash

Each struct type has a type hash:

```solidity
// For a struct like:
struct Permit {
    address owner;
    address spender;
    uint256 value;
    uint256 nonce;
    uint256 deadline;
}

// The type hash is:
bytes32 constant PERMIT_TYPEHASH = keccak256(
    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
);
```

### Struct Hash

The struct hash combines the type hash with the data:

```solidity
bytes32 structHash = keccak256(
    abi.encode(
        PERMIT_TYPEHASH,
        owner,
        spender,
        value,
        nonce,
        deadline
    )
);
```

## Domain Separators

The **domain separator** ensures signatures are only valid for:
- A specific contract
- A specific blockchain (chainId)
- A specific version

### Domain Type

```solidity
bytes32 constant TYPE_HASH = keccak256(
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
);
```

### Computing Domain Separator

```solidity
bytes32 domainSeparator = keccak256(
    abi.encode(
        TYPE_HASH,
        keccak256(bytes(name)),        // Contract name
        keccak256(bytes(version)),     // Version (e.g., "1")
        block.chainid,                 // Chain ID (1 for mainnet)
        address(this)                  // This contract's address
    )
);
```

### Why Domain Separators Matter

Without domain separators:
- ✗ Signature from Contract A could work on Contract B
- ✗ Signature from Ethereum could work on Polygon
- ✗ No version control for upgrades

With domain separators:
- ✓ Signatures are contract-specific
- ✓ Signatures are chain-specific
- ✓ Signatures are version-specific

## Signature Verification

### Step 1: Recreate the Hash

```solidity
bytes32 structHash = keccak256(abi.encode(
    PERMIT_TYPEHASH,
    owner,
    spender,
    value,
    nonce,
    deadline
));

bytes32 digest = keccak256(abi.encodePacked(
    "\x19\x01",
    domainSeparator,
    structHash
));
```

### Step 2: Recover Signer

```solidity
address signer = ecrecover(digest, v, r, s);
```

### Step 3: Verify Signer

```solidity
require(signer != address(0), "Invalid signature");
require(signer == expectedSigner, "Unauthorized");
```

### ECDSA Library (OpenZeppelin)

For production, use OpenZeppelin's ECDSA library:

```solidity
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

address signer = ECDSA.recover(digest, signature);
```

This handles:
- Malleability protection
- Invalid signature checks
- Cleaner API

## Replay Protection

Signatures can be **replayed** (reused) unless you implement protections.

### Attack Scenario

```solidity
// Alice signs: "Transfer 100 tokens to Bob"
// ✓ Transaction 1: Bob submits signature -> Works
// ✗ Transaction 2: Bob submits SAME signature -> Works again!
```

### Solution 1: Nonces

Track a counter for each user:

```solidity
mapping(address => uint256) public nonces;

function verify(..., uint256 nonce, ...) {
    require(nonce == nonces[signer], "Invalid nonce");
    nonces[signer]++; // Increment after use
}
```

Now each signature can only be used once, in order.

### Solution 2: Deadlines

Add expiration time:

```solidity
function verify(..., uint256 deadline, ...) {
    require(block.timestamp <= deadline, "Signature expired");
}
```

### Solution 3: Used Signature Tracking

For one-time vouchers:

```solidity
mapping(bytes32 => bool) public usedSignatures;

function verify(bytes32 digest, ...) {
    require(!usedSignatures[digest], "Signature already used");
    usedSignatures[digest] = true;
}
```

### Chain ID Protection

Prevent cross-chain replays:

```solidity
// Domain separator includes block.chainid
// Signature valid on mainnet won't work on testnet
```

## Implementation Guide

### 1. Define Your Struct

```solidity
struct MetaTx {
    address from;
    address to;
    uint256 value;
    uint256 nonce;
    uint256 deadline;
}
```

### 2. Create Type Hash

```solidity
bytes32 public constant METATX_TYPEHASH = keccak256(
    "MetaTx(address from,address to,uint256 value,uint256 nonce,uint256 deadline)"
);
```

### 3. Implement Domain Separator

```solidity
bytes32 public immutable DOMAIN_SEPARATOR;

constructor() {
    DOMAIN_SEPARATOR = keccak256(
        abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes("MyContract")),
            keccak256(bytes("1")),
            block.chainid,
            address(this)
        )
    );
}
```

### 4. Create Verification Function

```solidity
function verify(
    MetaTx calldata metaTx,
    uint8 v,
    bytes32 r,
    bytes32 s
) public view returns (bool) {
    // 1. Check deadline
    require(block.timestamp <= metaTx.deadline, "Expired");

    // 2. Check nonce
    require(metaTx.nonce == nonces[metaTx.from], "Invalid nonce");

    // 3. Create struct hash
    bytes32 structHash = keccak256(
        abi.encode(
            METATX_TYPEHASH,
            metaTx.from,
            metaTx.to,
            metaTx.value,
            metaTx.nonce,
            metaTx.deadline
        )
    );

    // 4. Create digest
    bytes32 digest = keccak256(
        abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
    );

    // 5. Recover signer
    address signer = ecrecover(digest, v, r, s);

    // 6. Verify
    return signer == metaTx.from;
}
```

### 5. Execute Function

```solidity
function executeMetaTx(
    MetaTx calldata metaTx,
    uint8 v,
    bytes32 r,
    bytes32 s
) external {
    require(verify(metaTx, v, r, s), "Invalid signature");

    // Increment nonce BEFORE execution (reentrancy protection)
    nonces[metaTx.from]++;

    // Execute the transaction
    // ... your logic here ...
}
```

## Security Considerations

### 1. Signature Malleability

ECDSA signatures are malleable. For a valid signature `(v, r, s)`, there exists another valid signature `(v', r, s')` for the same message.

**Solution**: Use OpenZeppelin's ECDSA library or check:
```solidity
require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "Invalid s");
```

### 2. ecrecover Returns Zero Address

If signature is invalid, `ecrecover` returns `address(0)`.

**Solution**: Always check:
```solidity
require(signer != address(0), "Invalid signature");
```

### 3. Nonce Management

Wrong nonce handling can brick accounts or allow replays.

**Solution**:
- Increment nonce BEFORE external calls
- Allow nonce queries
- Consider partial ordering (DAI-style)

### 4. Deadline Validation

Missing deadline checks allow signatures to live forever.

**Solution**: Always check:
```solidity
require(block.timestamp <= deadline, "Expired");
```

### 5. Domain Separator Caching

If your contract can be deployed on multiple chains, don't cache the domain separator if using `CREATE2` deterministic deployment.

**Solution**: Compute domain separator dynamically or validate chainId.

### 6. Front-Running

Meta-transactions can be front-run.

**Solution**:
- Use nonces (ensures ordering)
- Add relayer-specific data
- Use flashbots or private mempools

### 7. Phishing

Users might sign malicious data.

**Solution**:
- Use EIP-712 (human-readable)
- Clear UI warnings
- Wallet integration

## Real-World Applications

### ERC20 Permit (EIP-2612)

Allow approvals via signature instead of transaction:

```solidity
function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
) external {
    // Verify signature
    // ...

    // Set allowance
    _approve(owner, spender, value);
}
```

Benefits:
- ✓ No approval transaction needed
- ✓ Save gas for users
- ✓ Better UX

### Meta-Transactions

Execute transactions on behalf of users:

```solidity
function executeMetaTx(
    address from,
    bytes calldata data,
    uint256 nonce,
    bytes calldata signature
) external {
    // Verify signature
    // Execute call from user's context
    // Relayer pays gas
}
```

### NFT Lazy Minting

Mint NFTs only when claimed:

```solidity
function claim(
    uint256 tokenId,
    address to,
    bytes calldata signature
) external {
    // Verify admin signature
    // Mint NFT to claimer
}
```

### DAO Voting

Vote off-chain, execute on-chain:

```solidity
function castVoteBySig(
    uint256 proposalId,
    uint8 support,
    uint8 v,
    bytes32 r,
    bytes32 s
) external {
    // Verify signature
    // Record vote
}
```

## Testing Your Implementation

```bash
# Run tests
forge test --match-path test/Project19.t.sol -vvv

# Run specific test
forge test --match-test testPermitSignature -vvv

# Check gas costs
forge test --match-path test/Project19.t.sol --gas-report
```

## Tasks

### Part 1: Understanding (src/Project19.sol)
1. Implement `DOMAIN_SEPARATOR` computation
2. Create `_hashPermit()` function for struct hashing
3. Implement `_verify()` for signature verification
4. Add nonce tracking
5. Implement deadline checks

### Part 2: Advanced Features
1. Add support for EIP-2612 permit
2. Implement meta-transaction execution
3. Create voucher system with one-time signatures
4. Add batch signature verification

### Part 3: Security
1. Prevent signature malleability
2. Handle nonce edge cases
3. Protect against replay attacks
4. Test cross-chain scenarios

## Additional Resources

### EIPs
- [EIP-191: Signed Data Standard](https://eips.ethereum.org/EIPS/eip-191)
- [EIP-712: Typed Structured Data](https://eips.ethereum.org/EIPS/eip-712)
- [EIP-2612: Permit Extension for ERC-20](https://eips.ethereum.org/EIPS/eip-2612)

### Libraries
- [OpenZeppelin ECDSA](https://docs.openzeppelin.com/contracts/4.x/api/utils#ECDSA)
- [OpenZeppelin EIP712](https://docs.openzeppelin.com/contracts/4.x/api/utils#EIP712)

### Tools
- [eth-sig-util](https://github.com/MetaMask/eth-sig-util) - Sign and verify
- [eip712-codegen](https://github.com/danfinlay/eip-712-codegen) - Generate TypeScript types

## License

MIT
