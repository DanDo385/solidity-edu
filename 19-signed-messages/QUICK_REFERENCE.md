# EIP-712 Quick Reference

Quick reference guide for EIP-712 implementation patterns.

## Type Hash Formulas

### Standard Types

```solidity
// Permit (EIP-2612)
bytes32 constant PERMIT_TYPEHASH = keccak256(
    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
);

// Transfer
bytes32 constant TRANSFER_TYPEHASH = keccak256(
    "Transfer(address from,address to,uint256 amount,uint256 nonce,uint256 deadline)"
);

// Vote
bytes32 constant VOTE_TYPEHASH = keccak256(
    "Vote(uint256 proposalId,bool support,address voter,uint256 nonce,uint256 deadline)"
);

// Domain
bytes32 constant TYPE_HASH = keccak256(
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
);
```

## Domain Separator

```solidity
// Compute once in constructor
bytes32 public immutable DOMAIN_SEPARATOR;

constructor() {
    DOMAIN_SEPARATOR = keccak256(
        abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes("YourContractName")),
            keccak256(bytes("1")),
            block.chainid,
            address(this)
        )
    );
}
```

## Struct Hash Computation

```solidity
// For simple types
bytes32 structHash = keccak256(
    abi.encode(
        TYPEHASH,
        field1,
        field2,
        field3
    )
);

// For strings and bytes
bytes32 structHash = keccak256(
    abi.encode(
        TYPEHASH,
        keccak256(bytes(stringField)),
        keccak256(bytesField)
    )
);

// For arrays
bytes32 structHash = keccak256(
    abi.encode(
        TYPEHASH,
        keccak256(abi.encodePacked(arrayField))
    )
);
```

## Digest Creation

```solidity
bytes32 digest = keccak256(
    abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        structHash
    )
);
```

## Signature Recovery

```solidity
// Basic ecrecover
address signer = ecrecover(digest, v, r, s);

// With OpenZeppelin ECDSA
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

address signer = ECDSA.recover(digest, signature);
// or
address signer = ECDSA.recover(digest, v, r, s);
```

## Malleability Protection

```solidity
// Check s value is in lower half of curve
require(
    uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
    "Invalid s value"
);

// Or use OpenZeppelin's ECDSA.recover (includes this check)
```

## Common Patterns

### Pattern 1: Nonce-Based Replay Protection

```solidity
mapping(address => uint256) public nonces;

function verify(..., uint256 nonce, ...) {
    require(nonce == nonces[signer], "Invalid nonce");
    nonces[signer]++;
    // ... rest of logic
}
```

### Pattern 2: Signature Hash Tracking

```solidity
mapping(bytes32 => bool) public used;

function verify(...) {
    bytes32 digest = _createDigest(...);
    require(!used[digest], "Already used");
    used[digest] = true;
    // ... rest of logic
}
```

### Pattern 3: Deadline Validation

```solidity
function verify(..., uint256 deadline, ...) {
    require(block.timestamp <= deadline, "Expired");
    // ... rest of logic
}
```

### Pattern 4: Combined Protection

```solidity
function verify(
    address signer,
    uint256 nonce,
    uint256 deadline,
    bytes memory signature
) internal {
    // Check deadline
    require(block.timestamp <= deadline, "Expired");

    // Check nonce
    require(nonce == nonces[signer], "Invalid nonce");

    // Verify signature
    bytes32 digest = _createDigest(signer, nonce, deadline);
    address recovered = ECDSA.recover(digest, signature);
    require(recovered == signer, "Invalid signature");

    // Increment nonce AFTER all checks, BEFORE external calls
    nonces[signer]++;
}
```

## JavaScript Signing (ethers.js v6)

```javascript
const domain = {
    name: 'ContractName',
    version: '1',
    chainId: 1,
    verifyingContract: '0x...'
};

const types = {
    Permit: [
        { name: 'owner', type: 'address' },
        { name: 'spender', type: 'address' },
        { name: 'value', type: 'uint256' },
        { name: 'nonce', type: 'uint256' },
        { name: 'deadline', type: 'uint256' }
    ]
};

const value = {
    owner: '0x...',
    spender: '0x...',
    value: ethers.parseEther('100'),
    nonce: 0,
    deadline: Math.floor(Date.now() / 1000) + 3600
};

const signature = await wallet.signTypedData(domain, types, value);
const sig = ethers.Signature.from(signature);
// sig.v, sig.r, sig.s
```

## Security Checklist

- [ ] Domain separator includes name, version, chainId, and address
- [ ] All signatures have expiration (deadline)
- [ ] Nonces prevent replay attacks
- [ ] s value is validated (malleability protection)
- [ ] ecrecover result checked for zero address
- [ ] Nonces incremented BEFORE external calls
- [ ] Type hash matches struct field order exactly
- [ ] String/bytes fields are hashed in struct hash
- [ ] Array fields are encoded properly
- [ ] Cross-chain replay prevented (chainId in domain)

## Gas Optimization Tips

1. Use `immutable` for domain separator
2. Cache type hashes as constants
3. Use `calldata` for signature parameters
4. Batch signature verifications when possible
5. Consider OpenZeppelin's ECDSA library (gas efficient + secure)

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| Invalid signature | Wrong signer or tampered data | Verify domain, types, and values match |
| Expired | Deadline passed | Use future timestamp |
| Invalid nonce | Wrong nonce or already used | Query current nonce from contract |
| Zero address recovered | Invalid signature format | Check v, r, s values |
| Signature replay | No nonce/tracking | Implement nonce or used mapping |

## Testing Tips

```solidity
// Create test signature
(uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

// Test expiration
vm.warp(deadline + 1);
vm.expectRevert("Expired");

// Test wrong signer
(uint8 v, bytes32 r, bytes32 s) = vm.sign(wrongPrivateKey, digest);
vm.expectRevert("Invalid signature");

// Test replay
contract.execute(...); // First call succeeds
vm.expectRevert("Invalid nonce");
contract.execute(...); // Same signature fails
```

## Standards Reference

- **EIP-191**: Signed Data Standard (prefix format)
- **EIP-712**: Typed Structured Data Hashing and Signing
- **EIP-2612**: Permit Extension for ERC-20
- **EIP-4494**: Permit for ERC-721 NFTs

## Useful Libraries

```solidity
// OpenZeppelin
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

// Usage
contract MyContract is EIP712 {
    constructor() EIP712("MyContract", "1") {}

    function verify(...) public {
        bytes32 digest = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(digest, signature);
        // ...
    }
}
```
