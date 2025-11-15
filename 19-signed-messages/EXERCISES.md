# Project 19: Exercises and Challenges

Complete these exercises to master EIP-712 signatures and replay protection mechanisms.

## Exercise 1: Complete the Skeleton Contract

Your task is to complete `src/Project19.sol` by implementing all the TODOs.

### Checklist

- [ ] Implement `DOMAIN_SEPARATOR` computation in constructor
- [ ] Complete `_hashPermit()` function
- [ ] Complete `_hashMetaTx()` function
- [ ] Implement `_toTypedDataHash()` function
- [ ] Implement `_recoverSigner()` with malleability protection
- [ ] Complete `permit()` function with all security checks
- [ ] Complete `executeMetaTx()` function
- [ ] Complete `claimVoucher()` function
- [ ] Ensure all nonce increments happen BEFORE external calls

### Testing Your Implementation

```bash
# Run all tests
forge test --match-path test/Project19.t.sol -vv

# Run specific test
forge test --match-test testPermitSignature -vvv

# Check gas costs
forge test --match-path test/Project19.t.sol --gas-report
```

## Exercise 2: Batch Permit

Implement a function that allows approving multiple spenders in a single signature.

### Requirements

1. Create a new struct type:
```solidity
struct BatchPermit {
    address owner;
    address[] spenders;
    uint256[] values;
    uint256 nonce;
    uint256 deadline;
}
```

2. Create the type hash:
```solidity
bytes32 public constant BATCH_PERMIT_TYPEHASH = keccak256(
    "BatchPermit(address owner,address[] spenders,uint256[] values,uint256 nonce,uint256 deadline)"
);
```

3. Implement `batchPermit()` function:
```solidity
function batchPermit(
    address owner,
    address[] calldata spenders,
    uint256[] calldata values,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
) external {
    // Your implementation here
}
```

4. Handle array hashing correctly:
```solidity
// Arrays must be hashed with keccak256(abi.encodePacked(array))
bytes32 spendersHash = keccak256(abi.encodePacked(spenders));
bytes32 valuesHash = keccak256(abi.encodePacked(values));
```

### Tests to Write

```solidity
function testBatchPermit() public {
    address[] memory spenders = new address[](2);
    spenders[0] = address(0x1);
    spenders[1] = address(0x2);

    uint256[] memory values = new uint256[](2);
    values[0] = 100 ether;
    values[1] = 200 ether;

    // Create and verify signature
    // Execute batchPermit
    // Verify all allowances set correctly
}
```

## Exercise 3: Delegated Transfer

Implement a function where Alice can sign a permission for Bob to transfer tokens from Alice to Charlie.

### Requirements

1. Create struct:
```solidity
struct DelegatedTransfer {
    address from;      // Token owner
    address to;        // Recipient
    uint256 amount;
    address delegate;  // Who can execute this
    uint256 nonce;
    uint256 deadline;
}
```

2. Implement function:
```solidity
function delegatedTransfer(
    address from,
    address to,
    uint256 amount,
    address delegate,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
) external {
    // Must be called by delegate
    require(msg.sender == delegate, "Not authorized delegate");

    // Verify signature from 'from' address
    // Execute transfer
}
```

### Use Case
Alice signs: "Bob can transfer 100 tokens from me to Charlie"
Only Bob can execute this, and it transfers Alice's tokens to Charlie.

## Exercise 4: Time-Locked Signatures

Implement signatures that can only be used AFTER a certain time.

### Requirements

1. Add `validAfter` field:
```solidity
struct TimeLockedPermit {
    address owner;
    address spender;
    uint256 value;
    uint256 nonce;
    uint256 validAfter;  // Can't use before this time
    uint256 deadline;    // Can't use after this time
}
```

2. Implement validation:
```solidity
function timeLockedPermit(..., uint256 validAfter, ...) external {
    require(block.timestamp >= validAfter, "Too early");
    require(block.timestamp <= deadline, "Too late");
    // Rest of permit logic
}
```

### Use Case
Schedule approvals to activate in the future.

## Exercise 5: Conditional Vouchers

Create vouchers that can only be claimed if certain conditions are met.

### Requirements

1. Add merkle proof verification:
```solidity
struct ConditionalVoucher {
    address claimer;
    uint256 amount;
    bytes32 merkleRoot;  // Proof required
    uint256 deadline;
}

function claimConditionalVoucher(
    address claimer,
    uint256 amount,
    bytes32 merkleRoot,
    uint256 deadline,
    bytes32[] calldata merkleProof,
    uint8 v,
    bytes32 r,
    bytes32 s
) external {
    // Verify signature
    // Verify merkle proof
    // Credit amount
}
```

### Use Case
Distribute vouchers to whitelisted addresses only.

## Exercise 6: Gas Rebate System

Implement a system where users can submit transactions and get gas rebates via signature.

### Requirements

1. Track gas spent:
```solidity
mapping(address => uint256) public gasSpent;

function trackGasUsage() external {
    uint256 gasStart = gasleft();

    // Do some work...

    uint256 gasUsed = gasStart - gasleft();
    gasSpent[msg.sender] += gasUsed;
}
```

2. Allow admin to sign rebates:
```solidity
struct GasRebate {
    address user;
    uint256 amount;
    uint256 nonce;
    uint256 deadline;
}

function claimGasRebate(...) external {
    // Verify admin signature
    // Transfer rebate to user
}
```

## Exercise 7: Multi-Signature Permit

Implement a permit that requires multiple signatures.

### Requirements

1. Define multi-sig struct:
```solidity
struct MultiSigPermit {
    address owner;
    address spender;
    uint256 value;
    uint256 nonce;
    uint256 deadline;
    address[] signers;
    uint256 threshold;
}
```

2. Implement function that accepts multiple signatures:
```solidity
function multiSigPermit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    address[] calldata signers,
    uint256 threshold,
    bytes[] calldata signatures
) external {
    require(signatures.length >= threshold, "Not enough signatures");

    // Verify each signature
    // Check no duplicate signers
    // Execute permit
}
```

## Exercise 8: EIP-2612 Token

Create a full ERC20 token with EIP-2612 permit support.

### Requirements

```solidity
contract ERC20Permit {
    // ERC20 state
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // EIP-2612 state
    mapping(address => uint256) public nonces;
    bytes32 public immutable DOMAIN_SEPARATOR;

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // Implement full EIP-2612 permit
    }

    function transferWithPermit(
        address owner,
        address to,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // Permit + transfer in one call
        permit(owner, msg.sender, value, deadline, v, r, s);
        transferFrom(owner, to, value);
    }
}
```

## Exercise 9: NFT Lazy Minting

Implement lazy minting where NFTs are only minted when claimed with a signature.

### Requirements

```solidity
struct LazyMintVoucher {
    uint256 tokenId;
    address to;
    string uri;
    uint256 price;
    uint256 deadline;
}

function lazyMint(
    uint256 tokenId,
    string calldata uri,
    uint256 price,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
) external payable {
    require(msg.value >= price, "Insufficient payment");

    // Verify admin signature
    // Mint NFT
    // Set token URI
    // Forward payment to admin
}
```

### Use Case
NFT projects can sign thousands of mint vouchers without paying gas until users claim them.

## Exercise 10: DAO Voting with Signatures

Implement off-chain voting where votes are collected as signatures and executed on-chain.

### Requirements

```solidity
struct Vote {
    uint256 proposalId;
    bool support;
    address voter;
    uint256 weight;
    uint256 deadline;
}

mapping(uint256 => mapping(address => bool)) public hasVoted;
mapping(uint256 => uint256) public votesFor;
mapping(uint256 => uint256) public votesAgainst;

function castVoteBySig(
    uint256 proposalId,
    bool support,
    uint256 weight,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
) external {
    // Verify signature
    // Record vote
    // Update tallies
}

function batchCastVotes(
    uint256 proposalId,
    bool[] calldata supports,
    address[] calldata voters,
    uint256[] calldata weights,
    uint256 deadline,
    bytes[] calldata signatures
) external {
    // Process multiple votes at once
}
```

## Security Challenges

### Challenge 1: Find the Vulnerability

Identify the security issue in this code:

```solidity
function brokenPermit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    bytes calldata signature
) external {
    bytes32 structHash = keccak256(abi.encode(
        PERMIT_TYPEHASH,
        owner,
        spender,
        value,
        deadline  // Missing nonce!
    ));

    bytes32 digest = _toTypedDataHash(structHash);
    address signer = ECDSA.recover(digest, signature);

    require(signer == owner, "Invalid signature");

    allowances[owner][spender] = value;
}
```

**Question**: What attack is possible? How would you fix it?

### Challenge 2: Signature Replay

This contract has a cross-function replay vulnerability:

```solidity
function permit(address owner, address spender, uint256 value, ...) {
    nonces[owner]++;
    // ... rest of permit logic
}

function metaTx(address from, address to, uint256 amount, ...) {
    nonces[from]++;
    // ... rest of metaTx logic
}
```

**Question**: How can a signature intended for `permit()` be used in `metaTx()`? How do you prevent this?

### Challenge 3: Domain Separator Issue

```solidity
contract VulnerableContract {
    bytes32 public DOMAIN_SEPARATOR;

    constructor() {
        DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    function computeDomainSeparator() internal view returns (bytes32) {
        return keccak256(abi.encode(
            TYPE_HASH,
            keccak256(bytes("MyContract")),
            keccak256(bytes("1")),
            block.chainid,
            address(this)
        ));
    }
}
```

**Question**: What happens if this contract is deployed via CREATE2 on multiple chains with the same address? Is the cached DOMAIN_SEPARATOR still valid?

## Advanced Topics

### Topic 1: EIP-712 with Nested Structs

```solidity
struct Order {
    address maker;
    Asset[] assets;
    uint256 deadline;
}

struct Asset {
    address token;
    uint256 amount;
}

// How do you hash nested structs in EIP-712?
```

### Topic 2: Signature Aggregation

Research BLS signatures for aggregating multiple signatures into one.

### Topic 3: Account Abstraction

How do EIP-712 signatures relate to EIP-4337 account abstraction?

## Resources

- [EIP-712 Specification](https://eips.ethereum.org/EIPS/eip-712)
- [EIP-2612: Permit for ERC-20](https://eips.ethereum.org/EIPS/eip-2612)
- [OpenZeppelin EIP712 Implementation](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/EIP712.sol)
- [Uniswap Permit2](https://github.com/Uniswap/permit2)

## Submission

Create a pull request with:
1. Completed `src/Project19.sol`
2. At least 3 additional exercises implemented
3. Tests for all your implementations
4. Gas optimization report

Good luck!
