# Project 23: ERC-20 Permit (EIP-2612)

Learn how to implement gasless token approvals using EIP-2612 permit functionality, enabling better UX and significant gas savings for users.

## Table of Contents
- [Overview](#overview)
- [The Approval Problem](#the-approval-problem)
- [EIP-2612 Solution](#eip-2612-solution)
- [How Permit Works](#how-permit-works)
- [EIP-712 Integration](#eip-712-integration)
- [Gas Comparison](#gas-comparison)
- [Nonces and Deadlines](#nonces-and-deadlines)
- [Implementation Guide](#implementation-guide)
- [Security Considerations](#security-considerations)
- [Real-World Usage](#real-world-usage)

## Overview

**EIP-2612** introduces the `permit` function to ERC-20 tokens, allowing users to approve token spending via off-chain signatures instead of on-chain transactions.

### What You'll Learn
- EIP-2612 permit standard specification
- Signature-based approvals using EIP-712
- Domain separators and replay protection
- Nonce management for permits
- Deadline enforcement for signature expiration
- Gas optimization through signature-based approvals
- OpenZeppelin ERC20Permit extension usage

### Why This Matters
- **Better UX**: One transaction instead of two (approve + transfer)
- **Gas Savings**: No approval transaction needed
- **Gasless Approvals**: Users can sign without paying gas
- **Meta-Transactions**: Enable relayer-based transactions
- **Standard Compliance**: Used by major DeFi protocols

## The Approval Problem

### Traditional ERC-20 Workflow

When a user wants to interact with a DeFi protocol (like Uniswap), they need TWO transactions:

```solidity
// Transaction 1: Approve
token.approve(uniswapRouter, 1000e18);  // Costs gas, requires ETH

// Transaction 2: Execute
uniswapRouter.swapExactTokensForETH(...);  // Costs gas again
```

### Problems
1. **Two Transactions Required**: User must wait for approval to confirm
2. **Poor UX**: Confusing for new users ("Why do I need to approve?")
3. **Gas Costs**: Both transactions cost gas
4. **ETH Requirement**: User needs ETH for gas even if they only have tokens
5. **Front-Running Risk**: Approval can be front-run

## EIP-2612 Solution

### Permit Workflow

With EIP-2612, users can approve via signature:

```solidity
// Off-chain: User signs permit (NO GAS, NO TRANSACTION)
const signature = await signPermit(owner, spender, amount, deadline);

// On-chain: Single transaction does everything
token.permit(owner, spender, amount, deadline, v, r, s);  // Sets approval
uniswapRouter.swapExactTokensForETH(...);  // Uses approval
```

### Benefits
- **One Transaction**: Approve and execute in single transaction
- **No Gas for Approval**: Signature is free
- **Better UX**: Simpler flow for users
- **Gasless Transactions**: Relayers can submit on behalf of users
- **Meta-Transactions**: Enable advanced patterns

## How Permit Works

### The Permit Function

```solidity
function permit(
    address owner,        // Token owner granting approval
    address spender,      // Address being approved
    uint256 value,        // Amount to approve
    uint256 deadline,     // Signature expiration timestamp
    uint8 v,             // ECDSA signature component
    bytes32 r,           // ECDSA signature component
    bytes32 s            // ECDSA signature component
) external;
```

### Step-by-Step Process

#### 1. Off-Chain: User Signs Permit

```javascript
// User's wallet (MetaMask, etc.)
const domain = {
    name: 'MyToken',
    version: '1',
    chainId: 1,
    verifyingContract: tokenAddress
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
    owner: userAddress,
    spender: spenderAddress,
    value: amount,
    nonce: await token.nonces(userAddress),
    deadline: Math.floor(Date.now() / 1000) + 3600  // 1 hour
};

// User signs (no transaction, no gas)
const signature = await signer._signTypedData(domain, types, value);
const { v, r, s } = ethers.utils.splitSignature(signature);
```

#### 2. On-Chain: Contract Verifies and Approves

```solidity
function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
) public virtual {
    // 1. Check deadline
    require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

    // 2. Get current nonce
    uint256 nonce = _useNonce(owner);

    // 3. Create EIP-712 struct hash
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

    // 4. Create digest with domain separator
    bytes32 digest = _hashTypedDataV4(structHash);

    // 5. Recover signer from signature
    address signer = ECDSA.recover(digest, v, r, s);

    // 6. Verify signer is owner
    require(signer == owner, "ERC20Permit: invalid signature");

    // 7. Set approval
    _approve(owner, spender, value);
}
```

## EIP-712 Integration

### Why EIP-712?

EIP-712 provides:
- **Structured Data**: Type-safe signing
- **Human-Readable**: Users see what they're signing
- **Domain Separation**: Prevents cross-contract/chain replays

### Domain Separator

The domain separator uniquely identifies the token:

```solidity
// Computed once at deployment
bytes32 private immutable _DOMAIN_SEPARATOR;

constructor() {
    _DOMAIN_SEPARATOR = keccak256(
        abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes("MyToken")),      // Token name
            keccak256(bytes("1")),            // Version
            block.chainid,                    // Chain ID (1 = mainnet)
            address(this)                     // Token contract address
        )
    );
}
```

### Permit Typehash

```solidity
bytes32 public constant PERMIT_TYPEHASH = keccak256(
    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
);
```

### Creating the Digest

```solidity
// 1. Hash the struct data
bytes32 structHash = keccak256(
    abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonce, deadline)
);

// 2. Combine with domain separator (EIP-712 format)
bytes32 digest = keccak256(
    abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
);

// 3. Recover signer
address signer = ecrecover(digest, v, r, s);
```

## Gas Comparison

### Traditional Approve + TransferFrom

```solidity
// Transaction 1: approve() - ~46,000 gas
token.approve(spender, amount);

// Transaction 2: transferFrom() - ~65,000 gas
spender.transferFrom(owner, recipient, amount);

// TOTAL: ~111,000 gas + 2 transactions
```

### With Permit

```solidity
// Off-chain: User signs permit - 0 gas, no transaction

// On-chain: permit() + transferFrom() in one tx - ~85,000 gas
token.permit(owner, spender, amount, deadline, v, r, s);  // ~40,000 gas
spender.transferFrom(owner, recipient, amount);           // ~45,000 gas

// TOTAL: ~85,000 gas + 1 transaction
```

### Savings
- **Gas**: ~26,000 gas saved (~23% reduction)
- **Transactions**: 1 instead of 2 (50% reduction)
- **User Experience**: Dramatically improved
- **Cost at 50 gwei**: Saves ~$0.13 per approval (at $2000 ETH)

### Even Better: Integrated Permit

Many protocols integrate permit into their functions:

```solidity
// Single transaction does everything!
function swapWithPermit(
    address owner,
    uint256 amount,
    uint256 deadline,
    uint8 v, bytes32 r, bytes32 s
) external {
    // Apply permit
    token.permit(owner, address(this), amount, deadline, v, r, s);

    // Execute swap
    _swap(owner, amount);

    // No separate transferFrom needed - we're already approved!
}

// TOTAL: ~70,000 gas + 1 transaction
// SAVINGS: ~41,000 gas (37% reduction)
```

## Nonces and Deadlines

### Nonces

Nonces prevent replay attacks:

```solidity
// Each owner has an incrementing nonce
mapping(address => uint256) private _nonces;

function nonces(address owner) public view returns (uint256) {
    return _nonces[owner];
}

function _useNonce(address owner) internal returns (uint256 current) {
    current = _nonces[owner];
    _nonces[owner] = current + 1;
}
```

**Why Nonces Matter:**
- Each signature can only be used once
- Signatures must be used in order
- Prevents signature replay attacks
- Protects against front-running

### Deadlines

Deadlines limit signature validity:

```solidity
require(block.timestamp <= deadline, "ERC20Permit: expired deadline");
```

**Benefits:**
- Limits time window for signature use
- Prevents stale signatures
- User control over expiration
- Common practice: `deadline = block.timestamp + 1 hour`

### Nonce vs Deadline

| Feature | Nonce | Deadline |
|---------|-------|----------|
| Purpose | Prevent replay | Limit validity window |
| Type | Counter | Timestamp |
| Scope | Per user | Per signature |
| Required | Yes | Yes |
| User Control | No (automatic) | Yes (sets expiration) |

## Implementation Guide

### Option 1: OpenZeppelin (Recommended)

Use OpenZeppelin's battle-tested implementation:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract MyToken is ERC20, ERC20Permit {
    constructor() ERC20("MyToken", "MTK") ERC20Permit("MyToken") {
        _mint(msg.sender, 1000000 * 10**18);
    }
}

// That's it! You now have full permit functionality.
```

### Option 2: Manual Implementation

Implement yourself for learning:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract MyTokenWithPermit is ERC20, EIP712 {
    bytes32 private constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    mapping(address => uint256) private _nonces;

    constructor() ERC20("MyToken", "MTK") EIP712("MyToken", "1") {
        _mint(msg.sender, 1000000 * 10**18);
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(
            abi.encode(PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline)
        );

        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    function nonces(address owner) public view virtual returns (uint256) {
        return _nonces[owner];
    }

    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function _useNonce(address owner) internal virtual returns (uint256 current) {
        current = _nonces[owner];
        _nonces[owner] = current + 1;
    }
}
```

## Security Considerations

### 1. Signature Malleability

**Problem**: ECDSA signatures are malleable - multiple valid signatures exist for same message.

**Solution**: OpenZeppelin's ECDSA library handles this automatically:
```solidity
// Checks that s is in lower half of curve order
address signer = ECDSA.recover(hash, v, r, s);
```

### 2. Front-Running

**Problem**: Relayer could front-run permit transactions.

**Mitigation**:
- Nonces prevent replay
- Deadlines limit time window
- Use flashbots for MEV protection
- Integrate permit into main function

### 3. Deadline Validation

**Always check deadlines:**
```solidity
require(block.timestamp <= deadline, "Expired");
```

**Never use:**
```solidity
// BAD - deadline could be in the past!
deadline = block.timestamp - 1 days;

// GOOD - reasonable future deadline
deadline = block.timestamp + 1 hours;
```

### 4. Nonce Management

**Critical rules:**
- Increment nonce BEFORE external calls (reentrancy protection)
- Never reuse nonces
- Make nonces publicly queryable
- Consider ordered vs unordered nonces

### 5. Domain Separator

**Important for cross-chain:**
```solidity
// BAD - cached domain separator breaks on chain forks
bytes32 public constant DOMAIN_SEPARATOR = 0x123...;

// GOOD - computed dynamically or with fork detection
function _domainSeparatorV4() internal view returns (bytes32) {
    if (block.chainid == _CACHED_CHAIN_ID) {
        return _CACHED_DOMAIN_SEPARATOR;
    } else {
        return _buildDomainSeparator();
    }
}
```

### 6. Griefing Attacks

**Problem**: Attacker could front-run permit to grief user.

**Not a real issue because:**
- Only sets approval (desired outcome)
- Nonce prevents actual replay
- User's intended action still works

### 7. Infinite Approvals

**Consider the implications:**
```solidity
// Common pattern but has risks
token.permit(owner, spender, type(uint256).max, deadline, v, r, s);
```

**Better approach:**
```solidity
// Approve exact amount needed
token.permit(owner, spender, exactAmount, deadline, v, r, s);
```

## Real-World Usage

### Uniswap V2

```solidity
// UniswapV2Router02.sol
function swapExactTokensForETHWithPermit(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline,
    bool approveMax,
    uint8 v, bytes32 r, bytes32 s
) external {
    uint value = approveMax ? type(uint256).max : amountIn;
    IERC20Permit(path[0]).permit(msg.sender, address(this), value, deadline, v, r, s);
    swapExactTokensForETH(amountIn, amountOutMin, path, to, deadline);
}
```

### DAI

DAI was one of the first to implement permit (pre-EIP-2612):

```solidity
// Maker's DAI uses slightly different parameter order
function permit(
    address holder,
    address spender,
    uint256 nonce,  // Different position!
    uint256 expiry,
    bool allowed,   // Boolean instead of amount
    uint8 v, bytes32 r, bytes32 s
) external;
```

### USDC

USDC implements standard EIP-2612:

```solidity
// Can approve USDC via permit
usdc.permit(owner, spender, amount, deadline, v, r, s);
```

### Common DeFi Integrations

```solidity
// Aave
pool.supplyWithPermit(asset, amount, onBehalfOf, referralCode, deadline, v, r, s);

// 1inch
aggregator.swapWithPermit(...);

// SushiSwap
router.swapWithPermit(...);
```

## Testing Your Implementation

```bash
# Run all tests
forge test --match-path test/Project23.t.sol -vvv

# Test specific function
forge test --match-test testPermitSetsApproval -vvv

# Check gas usage
forge test --match-path test/Project23.t.sol --gas-report

# Test with gas comparison
forge test --match-test testGasComparison -vvv
```

## Tasks

### Part 1: Understanding (src/Project23.sol)
1. Implement `permit()` function with signature verification
2. Add nonce tracking and management
3. Implement deadline validation
4. Create EIP-712 domain separator
5. Implement struct hashing

### Part 2: Gas Optimization
1. Compare gas costs: approve vs permit
2. Implement integrated permit functions
3. Optimize signature verification
4. Test with various amounts

### Part 3: Security
1. Prevent signature malleability
2. Handle nonce edge cases
3. Validate deadline properly
4. Test replay protection
5. Check domain separator uniqueness

### Part 4: Integration
1. Use OpenZeppelin's ERC20Permit
2. Create wrapper functions with permit
3. Test with relayer pattern
4. Implement batch permits

## Additional Resources

### Standards
- [EIP-2612: Permit Extension for ERC-20](https://eips.ethereum.org/EIPS/eip-2612)
- [EIP-712: Typed Structured Data](https://eips.ethereum.org/EIPS/eip-712)
- [EIP-191: Signed Data Standard](https://eips.ethereum.org/EIPS/eip-191)

### Implementations
- [OpenZeppelin ERC20Permit](https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#ERC20Permit)
- [Uniswap Permit2](https://github.com/Uniswap/permit2)
- [DAI Permit](https://github.com/makerdao/dss/blob/master/src/dai.sol)

### Tools
- [eth-permit](https://github.com/dmihal/eth-permit) - Easy permit signing
- [permit-helper](https://github.com/Uniswap/permit2-sdk) - Uniswap SDK
- [EIP-712 Signing](https://docs.metamask.io/guide/signing-data.html) - MetaMask docs

### Articles
- [Understanding EIP-2612](https://soliditydeveloper.com/eip-2612)
- [Gasless Approvals Deep Dive](https://blog.openzeppelin.com/workshop-recap-secure-development-workshop-2/)

## License

MIT
