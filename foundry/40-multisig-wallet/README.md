# Project 40: Multi-Sig Wallet

## Overview

A multi-signature (multi-sig) wallet is a smart contract that requires multiple parties to approve a transaction before it can be executed. This is one of the most critical security patterns in blockchain development, used to protect high-value assets and critical operations.

## Learning Objectives

- Understand multi-signature wallet architecture
- Implement threshold signature schemes (M-of-N)
- Build secure transaction proposal and approval systems
- Implement replay protection for multi-sig transactions
- Handle owner management safely
- Learn from production systems like Gnosis Safe
- Apply security best practices for asset custody

## Multi-Sig Wallet Design Patterns: Secure Asset Custody

**FIRST PRINCIPLES: Distributed Trust**

A multi-signature wallet requires multiple parties to approve transactions, eliminating single points of failure. This is critical for high-value asset custody!

**CONNECTION TO PROJECT 04 & 19**:
- **Project 04**: We learned about access control and roles
- **Project 19**: We learned about EIP-712 signatures
- **Project 40**: Multi-sig combines both - multiple owners with signature verification!

### Basic Architecture

**UNDERSTANDING THE COMPONENTS**:

A multi-sig wallet typically consists of:

1. **Owner Set**: A list of authorized signers
   - From Project 01: `address[] public owners;`
   - Multiple addresses with voting power
   - Can add/remove owners (with approval)

2. **Threshold**: The minimum number of signatures required (M-of-N)
   - Example: 3-of-5 (3 signatures needed from 5 owners)
   - Balances security vs convenience
   - From Project 04: Threshold-based access control!

3. **Transaction Proposal System**: Mechanism to propose transactions
   - Anyone (or owners) can propose transactions
   - Proposals stored until approved
   - From Project 01: Structs for transaction data!

4. **Approval/Signature Collection**: Tracking who has approved
   - From Project 01: `mapping(uint256 => mapping(address => bool)) public confirmations;`
   - Nested mapping tracks approvals per transaction
   - From Project 04: Similar to role-based access control!

5. **Execution Logic**: Execute when threshold is met
   - Check: `approvalCount >= threshold`
   - Execute transaction (send ETH, call contract, etc.)
   - From Project 02: ETH transfers and external calls!

6. **Nonce System**: Prevent replay attacks
   - From Project 38: Nonces prevent signature replay!
   - Each transaction has unique nonce
   - Prevents reusing signatures

**UNDERSTANDING M-OF-N** (from Project 04 knowledge):

```
M-of-N Multi-Sig Example (3-of-5):
┌─────────────────────────────────────────┐
│ Owners: [Alice, Bob, Carol, Dave, Eve]  │ ← 5 owners
│ Threshold: 3                             │ ← Need 3 approvals
│                                          │
│ Transaction Proposal:                   │
│   Send 10 ETH to recipient             │
│   ↓                                      │
│ Approvals Collected:                    │
│   ✅ Alice approves                     │ ← 1/3
│   ✅ Bob approves                       │ ← 2/3
│   ✅ Carol approves                     │ ← 3/3 ✅ Threshold met!
│   ↓                                      │
│ Transaction Executes                    │ ← 10 ETH sent
└─────────────────────────────────────────┘
```

**GAS COST BREAKDOWN** (from Project 01 & 19 knowledge):

**On-Chain Confirmation Pattern**:
- Each confirmation: ~20,000 gas (SSTORE)
- Execution: ~23,000 gas (ETH transfer)
- Total for 3-of-5: ~83,000 gas (3 confirmations + execution)

**Off-Chain Signature Pattern**:
- Signature verification: ~3,000 gas × 3 = ~9,000 gas
- Execution: ~23,000 gas
- Total: ~32,000 gas (much cheaper!)

**REAL-WORLD ANALOGY**: 
Like a bank vault requiring multiple keys:
- **Single owner**: One key opens vault (single point of failure)
- **Multi-sig**: Multiple keys required (distributed trust)
- **Threshold**: Need M keys out of N total keys

### Design Pattern 1: On-Chain Confirmation

```solidity
// Each owner confirms on-chain
mapping(uint256 => mapping(address => bool)) public confirmations;

function confirmTransaction(uint256 txId) external onlyOwner {
    confirmations[txId][msg.sender] = true;
    emit Confirmation(msg.sender, txId);
}
```

**Pros**:
- Simple to implement
- Transparent confirmation status
- No off-chain coordination needed

**Cons**:
- Higher gas costs (each confirmation is a transaction)
- Multiple transactions required

### Design Pattern 2: Off-Chain Signatures (EIP-712)

```solidity
// Collect signatures off-chain, submit all at once
function executeWithSignatures(
    Transaction memory tx,
    bytes[] memory signatures
) external {
    bytes32 txHash = hashTransaction(tx);
    require(verifySignatures(txHash, signatures), "Invalid signatures");
    executeTx(tx);
}
```

**Pros**:
- Lower gas costs
- Single transaction for execution
- Better UX for signers

**Cons**:
- Requires off-chain coordination
- More complex signature verification
- Need to handle signature malleability

## Threshold Signature Schemes (M-of-N)

### What is M-of-N?

In an M-of-N multi-sig:
- **N** = Total number of owners
- **M** = Minimum signatures required (threshold)
- Example: 2-of-3 means 2 out of 3 owners must approve

### Choosing the Right Threshold

```
1-of-N: Single point of failure (avoid for security)
2-of-3: Good for small teams (66% agreement)
3-of-5: Good for medium teams (60% agreement)
5-of-7: Good for larger teams (71% agreement)
N-of-N: All must agree (can cause gridlock)
```

### Threshold Validation

```solidity
function isThresholdMet(uint256 txId) public view returns (bool) {
    uint256 count = 0;
    for (uint256 i = 0; i < owners.length; i++) {
        if (confirmations[txId][owners[i]]) {
            count++;
            if (count >= threshold) {
                return true;
            }
        }
    }
    return false;
}
```

## Transaction Queuing and Execution

### Transaction Lifecycle

1. **Proposal**: Owner proposes a transaction
2. **Confirmation**: Owners confirm/approve
3. **Execution**: When threshold met, anyone can execute
4. **Completion**: Transaction marked as executed

### Transaction Structure

```solidity
struct Transaction {
    address to;           // Destination address
    uint256 value;        // ETH value to send
    bytes data;           // Function call data
    bool executed;        // Execution status
    uint256 nonce;        // Replay protection
    uint256 confirmations; // Confirmation count
}
```

### Execution Patterns

**Pattern 1: Execute Immediately When Threshold Met**
```solidity
function confirmTransaction(uint256 txId) external {
    // Confirm
    confirmations[txId][msg.sender] = true;

    // Auto-execute if threshold met
    if (isThresholdMet(txId) && !transactions[txId].executed) {
        executeTransaction(txId);
    }
}
```

**Pattern 2: Separate Confirmation and Execution**
```solidity
function confirmTransaction(uint256 txId) external {
    confirmations[txId][msg.sender] = true;
}

function executeTransaction(uint256 txId) external {
    require(isThresholdMet(txId), "Threshold not met");
    require(!transactions[txId].executed, "Already executed");
    // Execute...
}
```

## Replay Protection for Multi-Sig

### Why Replay Protection?

Without replay protection, a transaction could be:
- Executed multiple times
- Re-submitted after owner changes
- Replayed on different chains (post-fork)

### Nonce-Based Protection

```solidity
uint256 public nonce;

function submitTransaction(
    address to,
    uint256 value,
    bytes calldata data
) external returns (uint256 txId) {
    txId = nonce++;
    transactions[txId] = Transaction({
        to: to,
        value: value,
        data: data,
        executed: false,
        nonce: txId
    });
}
```

### EIP-712 Structured Data Hashing

```solidity
bytes32 public constant TRANSACTION_TYPEHASH = keccak256(
    "Transaction(address to,uint256 value,bytes data,uint256 nonce)"
);

function hashTransaction(Transaction memory tx) public view returns (bytes32) {
    return keccak256(abi.encode(
        TRANSACTION_TYPEHASH,
        tx.to,
        tx.value,
        keccak256(tx.data),
        tx.nonce
    ));
}
```

### Chain ID Protection

```solidity
// Include chain ID in signature to prevent cross-chain replay
bytes32 domainSeparator = keccak256(abi.encode(
    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
    keccak256(bytes("MultiSigWallet")),
    keccak256(bytes("1")),
    block.chainid,
    address(this)
));
```

## Owner Management

### Adding Owners

```solidity
function addOwner(address newOwner) external {
    require(msg.sender == address(this), "Only via multi-sig");
    require(newOwner != address(0), "Invalid owner");
    require(!isOwner[newOwner], "Already owner");

    owners.push(newOwner);
    isOwner[newOwner] = true;

    emit OwnerAdded(newOwner);
}
```

### Removing Owners

```solidity
function removeOwner(address owner) external {
    require(msg.sender == address(this), "Only via multi-sig");
    require(isOwner[owner], "Not an owner");
    require(owners.length - 1 >= threshold, "Would break threshold");

    isOwner[owner] = false;

    // Remove from array
    for (uint256 i = 0; i < owners.length; i++) {
        if (owners[i] == owner) {
            owners[i] = owners[owners.length - 1];
            owners.pop();
            break;
        }
    }

    emit OwnerRemoved(owner);
}
```

### Changing Threshold

```solidity
function changeThreshold(uint256 newThreshold) external {
    require(msg.sender == address(this), "Only via multi-sig");
    require(newThreshold > 0, "Threshold must be > 0");
    require(newThreshold <= owners.length, "Threshold too high");

    threshold = newThreshold;
    emit ThresholdChanged(newThreshold);
}
```

### Critical Invariants

Always maintain these invariants:
- `threshold > 0`
- `threshold <= owners.length`
- `owners.length > 0`
- No duplicate owners
- No zero address owners

## Gnosis Safe Comparison

### Gnosis Safe Architecture

Gnosis Safe is the industry-standard multi-sig wallet. Key features:

1. **Modular Design**: Extensible via modules
2. **Gas Optimization**: Efficient signature verification
3. **EIP-1271**: Contract signature validation
4. **Delegate Calls**: Execute complex operations
5. **Gas Refunds**: Relayer can be reimbursed
6. **Social Recovery**: Module for account recovery

### Our Implementation vs Gnosis Safe

| Feature | Our Implementation | Gnosis Safe |
|---------|-------------------|-------------|
| Basic Multi-Sig | ✓ | ✓ |
| On-Chain Confirmations | ✓ | ✓ |
| Off-Chain Signatures | Basic | Advanced (EIP-712) |
| Modules | ✗ | ✓ |
| Gas Refunds | ✗ | ✓ |
| EIP-1271 | ✗ | ✓ |
| Delegate Calls | ✓ | ✓ |
| Upgradability | ✗ | ✓ (Proxy) |

### Key Gnosis Safe Patterns

**Pattern 1: Signature Encoding**
```solidity
// Gnosis uses packed signatures for gas efficiency
// Each signature is 65 bytes (r, s, v)
function checkNSignatures(
    bytes32 dataHash,
    bytes memory data,
    bytes memory signatures,
    uint256 requiredSignatures
) public view
```

**Pattern 2: Module System**
```solidity
// Modules can execute transactions
mapping(address => bool) public modules;

function execTransactionFromModule(
    address to,
    uint256 value,
    bytes memory data,
    Operation operation
) public returns (bool success)
```

## Security Best Practices

### 1. Prevent Signature Malleability

```solidity
// ECDSA signatures can be malleable
// Always use the lower s value
function recoverSigner(
    bytes32 hash,
    bytes memory signature
) internal pure returns (address) {
    require(signature.length == 65, "Invalid signature length");

    bytes32 r;
    bytes32 s;
    uint8 v;

    assembly {
        r := mload(add(signature, 0x20))
        s := mload(add(signature, 0x40))
        v := byte(0, mload(add(signature, 0x60)))
    }

    // Prevent signature malleability
    require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
        "Invalid signature 's' value");

    return ecrecover(hash, v, r, s);
}
```

### 2. Protect Against Reentrancy

```solidity
// Mark as executed BEFORE external call
function executeTransaction(uint256 txId) external {
    Transaction storage txn = transactions[txId];
    require(!txn.executed, "Already executed");
    require(isThresholdMet(txId), "Threshold not met");

    // CEI pattern: Mark executed first
    txn.executed = true;

    // Then make external call
    (bool success,) = txn.to.call{value: txn.value}(txn.data);
    require(success, "Transaction failed");
}
```

### 3. Validate All Inputs

```solidity
function submitTransaction(
    address to,
    uint256 value,
    bytes calldata data
) external onlyOwner returns (uint256) {
    // Validate destination
    require(to != address(0), "Invalid destination");

    // Validate value
    require(value <= address(this).balance, "Insufficient balance");

    // Validate data (if necessary)
    // For example, prevent calling selfdestruct

    // Create transaction...
}
```

### 4. Owner Management Safety

```solidity
// Never allow the last owner to be removed
require(owners.length > 1, "Cannot remove last owner");

// Never allow threshold to exceed owners
require(threshold <= owners.length, "Invalid threshold");

// Never allow zero address as owner
require(owner != address(0), "Invalid owner");
```

### 5. Gas Limits for Execution

```solidity
// Don't forward all gas to prevent gas griefing
function executeTransaction(uint256 txId) external {
    // Reserve gas for cleanup
    uint256 gasToForward = gasleft() - 5000;

    (bool success,) = txn.to.call{
        value: txn.value,
        gas: gasToForward
    }(txn.data);

    // Handle success/failure
}
```

### 6. Event Emission for Transparency

```solidity
event TransactionSubmitted(uint256 indexed txId, address indexed submitter);
event TransactionConfirmed(uint256 indexed txId, address indexed owner);
event TransactionExecuted(uint256 indexed txId);
event OwnerAdded(address indexed owner);
event OwnerRemoved(address indexed owner);
event ThresholdChanged(uint256 threshold);
```

### 7. Access Control

```solidity
modifier onlyOwner() {
    require(isOwner[msg.sender], "Not an owner");
    _;
}

modifier onlyWallet() {
    require(msg.sender == address(this), "Only wallet can call");
    _;
}
```

## Common Vulnerabilities

### 1. Confirmation Replay

**Vulnerability**: Re-using confirmations for different transactions

**Fix**: Tie confirmations to specific transaction IDs
```solidity
mapping(uint256 => mapping(address => bool)) public confirmations;
```

### 2. Missing Execution Check

**Vulnerability**: Executing a transaction multiple times

**Fix**: Track execution status
```solidity
require(!transactions[txId].executed, "Already executed");
transactions[txId].executed = true;
```

### 3. Threshold Bypass

**Vulnerability**: Executing without meeting threshold

**Fix**: Always verify threshold before execution
```solidity
require(getConfirmationCount(txId) >= threshold, "Threshold not met");
```

### 4. Owner Manipulation

**Vulnerability**: Malicious owner changes during pending transactions

**Fix**: Option 1 - Invalidate pending transactions
```solidity
function removeOwner(address owner) external {
    // Clear their confirmations
    for (uint256 i = 0; i < transactionCount; i++) {
        if (confirmations[i][owner]) {
            confirmations[i][owner] = false;
        }
    }
}
```

**Fix**: Option 2 - Require higher threshold for owner changes
```solidity
// Use separate, higher threshold for governance
uint256 public governanceThreshold;
```

### 5. Front-Running

**Vulnerability**: Attacker sees pending confirmation and front-runs

**Fix**: Implement commit-reveal or use off-chain signatures

## Testing Strategy

### Unit Tests

1. **Owner Management**
   - Add owner
   - Remove owner
   - Change threshold
   - Validate invariants

2. **Transaction Submission**
   - Submit transaction
   - Validate storage
   - Event emission

3. **Confirmation**
   - Confirm transaction
   - Prevent double confirmation
   - Count confirmations correctly

4. **Execution**
   - Execute when threshold met
   - Fail when threshold not met
   - Prevent double execution

### Integration Tests

1. **Complete Flows**
   - Submit → Confirm → Execute
   - Multiple confirmations
   - Revocation flows

2. **Edge Cases**
   - Exactly threshold confirmations
   - More than threshold
   - Threshold changes mid-flight

### Security Tests

1. **Access Control**
   - Non-owner cannot submit
   - Non-owner cannot confirm
   - Only wallet can change owners

2. **Reentrancy**
   - Test with malicious recipient
   - Verify CEI pattern

3. **Replay Protection**
   - Cannot execute twice
   - Nonce increments correctly

## Implementation Guide

### Step 1: Define State Variables

```solidity
address[] public owners;
mapping(address => bool) public isOwner;
uint256 public threshold;
uint256 public nonce;
```

### Step 2: Define Transaction Structure

```solidity
struct Transaction {
    address to;
    uint256 value;
    bytes data;
    bool executed;
}

mapping(uint256 => Transaction) public transactions;
mapping(uint256 => mapping(address => bool)) public confirmations;
```

### Step 3: Implement Constructor

```solidity
constructor(address[] memory _owners, uint256 _threshold) {
    require(_owners.length > 0, "Owners required");
    require(_threshold > 0 && _threshold <= _owners.length, "Invalid threshold");

    for (uint256 i = 0; i < _owners.length; i++) {
        require(_owners[i] != address(0), "Invalid owner");
        require(!isOwner[_owners[i]], "Duplicate owner");

        owners.push(_owners[i]);
        isOwner[_owners[i]] = true;
    }

    threshold = _threshold;
}
```

### Step 4: Implement Core Functions

1. `submitTransaction()`
2. `confirmTransaction()`
3. `revokeConfirmation()`
4. `executeTransaction()`
5. `getConfirmationCount()`

### Step 5: Implement Owner Management

1. `addOwner()`
2. `removeOwner()`
3. `changeThreshold()`

### Step 6: Add Helper Functions

1. `getOwners()`
2. `getTransactionCount()`
3. `isConfirmedBy()`

## Gas Optimization Tips

1. **Use `uint256` for loop counters** (cheaper than smaller types)
2. **Cache array length** in loops
3. **Pack struct variables** efficiently
4. **Use events instead of storage** for historical data
5. **Avoid unnecessary SLOADs** (storage reads)
6. **Use `calldata` for read-only parameters**

## Deployment Checklist

- [ ] Validate initial owners (no duplicates, no zero addresses)
- [ ] Validate threshold (> 0, <= owner count)
- [ ] Test all functions on testnet
- [ ] Verify contracts on block explorer
- [ ] Test with small amounts first
- [ ] Document all owner addresses
- [ ] Set up monitoring for events
- [ ] Plan for owner key management

## Conclusion

Multi-sig wallets are essential for:
- Protecting high-value assets
- Decentralizing control
- Preventing single points of failure
- Adding accountability and transparency

This implementation provides a solid foundation, but for production use, consider:
- Using battle-tested contracts like Gnosis Safe
- Professional security audits
- Comprehensive testing
- Proper key management procedures
- Emergency procedures

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/MultiSigWalletSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployMultiSigWalletSolution.s.sol` - Deployment script patterns
- `test/solution/MultiSigWalletSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains threshold cryptography, consensus mechanisms, state machines
- **Connections to Project 04**: Access control patterns (extended to multi-party)
- **Connections to Project 07**: CEI pattern for secure execution
- **Connections to Project 05**: Error handling for invalid transactions
- **Real-World Context**: Transaction lifecycle - Submit → Confirm (M times) → Execute

## Additional Resources

- [Gnosis Safe Contracts](https://github.com/safe-global/safe-contracts)
- [EIP-712: Typed structured data hashing](https://eips.ethereum.org/EIPS/eip-712)
- [EIP-1271: Standard Signature Validation](https://eips.ethereum.org/EIPS/eip-1271)
- [OpenZeppelin Multi-Sig](https://docs.openzeppelin.com/contracts/4.x/)
- [ConsenSys Best Practices](https://consensys.github.io/smart-contract-best-practices/)
