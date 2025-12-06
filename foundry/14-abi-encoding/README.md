# Project 14: ABI Encoding & Function Selectors

> **Master low-level encoding, function selectors, and security pitfalls**

## Learning Objectives

- Understand `abi.encode` vs `abi.encodePacked` vs `abi.encodeWithSignature`
- Calculate and use function selectors
- Recognize selector collision risks
- Identify hash collision vulnerabilities with `encodePacked`
- Implement manual function routing with fallback
- Choose the right encoding method for each use case

## Key Concepts

### ABI Encoding Methods

Solidity provides several encoding functions, each with different use cases and security implications:

#### 1. `abi.encode` - Standard ABI Encoding

```solidity
// Adds padding, unambiguous
abi.encode("AA", "BB")
// → 0x0000...0020 (offset for "AA")
//    0000...0060 (offset for "BB")
//    0000...0002 (length of "AA")
//    4141000000... (padded "AA")
//    0000...0002 (length of "BB")
//    4242000000... (padded "BB")
```

**Use when:**
- Encoding function call data
- Need unambiguous encoding
- Working with contracts that expect standard ABI

#### 2. `abi.encodePacked` - Tight Packing (Dangerous!)

**FIRST PRINCIPLES: Hash Collision Vulnerability**

`abi.encodePacked` concatenates values without padding, making it compact but **dangerous** due to collision risks!

**CONNECTION TO PROJECT 01**:
We learned about `keccak256` hashing in Project 01 for storage calculations. `abi.encodePacked` is often used with `keccak256`, but must be used carefully!

```solidity
// No padding, compact but dangerous
abi.encodePacked("AA", "BB")
// → 0x41414242 (just the bytes)

// ⚠️ COLLISION RISK!
abi.encodePacked("A", "ABB") == abi.encodePacked("AA", "BB") // true!
// Both produce: 0x41414242
```

**UNDERSTANDING THE COLLISION**:

```
Why Collisions Happen:
┌─────────────────────────────────────────┐
│ encodePacked("A", "ABB"):               │
│   "A" = 0x41                            │
│   "ABB" = 0x414242                      │
│   Result: 0x41414242                     │
│                                          │
│ encodePacked("AA", "BB"):               │
│   "AA" = 0x4141                         │
│   "BB" = 0x4242                         │
│   Result: 0x41414242                     │ ← SAME!
└─────────────────────────────────────────┘

No delimiter = Ambiguity!
```

**SECURITY IMPLICATIONS**:

**Vulnerable Example**:
```solidity
// ❌ DANGEROUS: Collision possible!
bytes32 hash = keccak256(abi.encodePacked(user, amount));
// Attacker can manipulate: ("Alice", 100) vs ("Ali", "ce100")
```

**Safe Example**:
```solidity
// ✅ SAFE: Unambiguous encoding
bytes32 hash = keccak256(abi.encode(user, amount));
// Each value padded, no collision possible
```

**Use when:**
- Computing hashes (with caution!)
- Gas optimization for storage
- Working with `keccak256` for signatures
- **BUT**: Only with fixed-size types or single dynamic type!

**DANGER:** Never use with multiple variable-length types in critical contexts!

**COMPARISON TO RUST** (DSA Concept):

**Rust** (similar concatenation risk):
```rust
// Similar risk with string concatenation
let hash1 = sha256(format!("{}{}", "A", "ABB"));
let hash2 = sha256(format!("{}{}", "AA", "BB"));
// Could collide if not careful with delimiters
```

**Solidity** (encodePacked):
```solidity
bytes32 hash1 = keccak256(abi.encodePacked("A", "ABB"));
bytes32 hash2 = keccak256(abi.encodePacked("AA", "BB"));
// Collision risk - use abi.encode instead!
```

Both have similar risks - always use delimiters or unambiguous encoding!

#### 3. `abi.encodeWithSignature` - Function Calls

```solidity
// Includes 4-byte function selector
abi.encodeWithSignature("transfer(address,uint256)", to, amount)
// → 0xa9059cbb (selector) + encoded parameters
```

**Use when:**
- Making dynamic contract calls
- Implementing proxy patterns
- Building meta-transaction systems

### Function Selectors

Function selectors are the first 4 bytes of the keccak256 hash of the function signature:

```solidity
bytes4 selector = bytes4(keccak256("transfer(address,uint256)"));
// → 0xa9059cbb
```

**Key points:**
- Only 4 bytes (32 bits) → ~4.3 billion possibilities
- Birthday paradox: ~77k functions have 50% collision chance
- Malicious contracts can create intentional collisions
- Used for function dispatching in the EVM

### Hash Collision with encodePacked

When using `abi.encodePacked` with multiple dynamic-length arguments:

```solidity
// VULNERABLE: These produce the same hash!
keccak256(abi.encodePacked("A", "BC"))
keccak256(abi.encodePacked("AB", "C"))

// SAFE: Use abi.encode instead
keccak256(abi.encode("A", "BC")) != keccak256(abi.encode("AB", "C"))
```

**Real-world impact:**
- Signature replay attacks
- Authorization bypasses
- Merkle tree manipulation

### When to Use Each Method

| Method | Padding | Gas | Collision Risk | Use Case |
|--------|---------|-----|----------------|----------|
| `abi.encode` | Yes | Higher | None | Function calls, standard ABI |
| `abi.encodePacked` | No | Lower | HIGH | Hashing (carefully), gas optimization |
| `abi.encodeWithSignature` | Yes | Higher | None | Dynamic calls, proxies |
| `abi.encodeWithSelector` | Yes | Lower | None | Known selectors, gas saving |

## Security Checklist

- [ ] Never use `encodePacked` with multiple variable-length types for signatures
- [ ] Always validate function selectors in fallback functions
- [ ] Be aware of potential selector collisions in untrusted contracts
- [ ] Use `abi.encode` for hashing when collision resistance is critical
- [ ] Test for collision scenarios in security-critical code

## Common Vulnerabilities

### 1. Hash Collision in Signatures

```solidity
// VULNERABLE
function verify(string memory a, string memory b) public view returns (bool) {
    bytes32 hash = keccak256(abi.encodePacked(a, b));
    return hash == storedHash;
}

// Attacker: verify("A", "BC") == verify("AB", "C")
```

### 2. Selector Collision Attack

```solidity
// Attacker creates collisionFunc() with same selector as adminFunc()
// If contract only checks selector, both functions execute same code
```

### 3. Unchecked Fallback Routing

```solidity
fallback() external payable {
    // VULNERABLE: No selector validation
    address(implementation).delegatecall(msg.data);
}
```

## Tasks

```bash
cd 14-abi-encoding

# Run tests to see encoding differences
forge test -vvv

# See gas comparison
forge test --gas-report

# Run specific collision tests
forge test --match-test testHashCollision -vvv
```

### Implementation Checklist

Skeleton contract (`src/ABIEncoding.sol`):
- [ ] Implement encoding demonstration functions
- [ ] Calculate function selectors
- [ ] Create collision examples
- [ ] Build manual function router
- [ ] Add security comments

## Expected Output

```
Running tests...

[PASS] testEncodeVsEncodePacked() (gas: 15234)
Logs:
  abi.encode length: 192
  abi.encodePacked length: 4

[PASS] testHashCollision() (gas: 12456)
Logs:
  Hash 1: 0x1234...
  Hash 2: 0x1234... (COLLISION!)

[PASS] testFunctionSelector() (gas: 8901)
Logs:
  Selector: 0xa9059cbb
```

## Advanced Topics

### Function Selector Optimization

```solidity
// Gas efficient: pre-computed selector
bytes4 constant TRANSFER_SELECTOR = 0xa9059cbb;

// vs computing each time
bytes4 selector = bytes4(keccak256("transfer(address,uint256)"));
```

### Safe Multi-Argument Hashing

```solidity
// UNSAFE
keccak256(abi.encodePacked(a, b, c))

// SAFE - Add separators
keccak256(abi.encodePacked(a, ":", b, ":", c))

// SAFEST - Use abi.encode
keccak256(abi.encode(a, b, c))
```

## Real-World Examples

1. **OpenZeppelin's EIP-712** - Uses `abi.encode` for typed data hashing
2. **Uniswap V2** - Uses `encodePacked` carefully in pair creation
3. **ECDSA Signatures** - Always use `abi.encode` for message hashing
4. **Proxy Patterns** - Use `encodeWithSelector` for delegatecalls

## Common Mistakes

1. Using `encodePacked` for signature verification
2. Not validating selectors in fallback functions
3. Assuming 4-byte selectors are collision-resistant
4. Mixing encoding methods in security-critical code
5. Not testing for collision scenarios

## Resources

- [Solidity Docs: ABI Encoding](https://docs.soliditylang.org/en/latest/abi-spec.html)
- [SWC-133: Hash Collisions](https://swcregistry.io/docs/SWC-133)
- [EIP-712: Typed Data Signing](https://eips.ethereum.org/EIPS/eip-712)
- [Function Selector Database](https://www.4byte.directory/)

## Status

 **Ready to Learn** - Critical encoding concepts

## Next Steps

After completing this project, you'll understand:
- How the EVM dispatches function calls
- Why encoding method choice matters for security
- How to prevent hash collision attacks
- When to use each encoding variant

**Challenge**: Try finding two different function signatures with the same selector!
