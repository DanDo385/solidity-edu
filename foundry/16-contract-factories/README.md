# Project 16: Contract Factories (CREATE2)

Learn how to deploy contracts with deterministic addresses using CREATE2 opcode, enabling address prediction before deployment.

## Overview

This project explores CREATE2, an opcode introduced in EIP-1014 that allows deploying contracts to deterministic addresses. Unlike CREATE, CREATE2 makes the deployment address predictable and independent of the deployer's nonce.

## Learning Objectives

- Understand CREATE vs CREATE2
- Calculate deterministic addresses
- Use salts for unique deployments
- Distinguish initcode from runtime code
- Predict addresses off-chain
- Implement counterfactual contracts

## CREATE vs CREATE2

### CREATE (Traditional Deployment)

When you deploy a contract normally, the address is calculated as:

```
address = keccak256(rlp([sender_address, sender_nonce]))[12:]
```

**Characteristics:**
- Address depends on deployer's nonce
- Non-deterministic (nonce changes with each transaction)
- Cannot predict address before deployment
- Standard `new Contract()` syntax uses CREATE

**Example:**
```solidity
// Uses CREATE
MyContract instance = new MyContract();
// Address depends on factory's nonce at deployment time
```

### CREATE2 (Deterministic Deployment): Predictable Addresses

**FIRST PRINCIPLES: Deterministic Address Calculation**

CREATE2 calculates the address deterministically, enabling address prediction before deployment. This is powerful for counterfactual contracts and address-based logic!

**CONNECTION TO PROJECT 01**:
We learned about `keccak256` hashing in Project 01. CREATE2 uses keccak256 to calculate deterministic addresses!

CREATE2 calculates the address as:

```
address = keccak256(0xff ++ sender_address ++ salt ++ keccak256(initCode))[12:]
```

**UNDERSTANDING THE FORMULA**:

```
CREATE2 Address Calculation:
┌─────────────────────────────────────────┐
│ Input Components:                       │
│   1. 0xff (1 byte)                     │ ← Prefix to distinguish from CREATE
│   2. sender_address (20 bytes)         │ ← Factory contract address
│   3. salt (32 bytes)                    │ ← Chosen by deployer
│   4. keccak256(initCode) (32 bytes)    │ ← Hash of creation bytecode
│   ↓                                      │
│ Concatenate: 0xff || sender || salt || hash │
│   ↓                                      │
│ Hash: keccak256(concatenated)           │ ← Single hash operation
│   ↓                                      │
│ Extract: last 20 bytes                  │ ← Address format
│   ↓                                      │
│ Result: Deterministic address!          │ ← Always the same!
└─────────────────────────────────────────┘
```

**CHARACTERISTICS:**
- Address is deterministic and predictable ✅
- Independent of nonce ✅ (unlike CREATE)
- Depends on: deployer address, salt, and contract bytecode
- Enables address prediction before deployment
- Requires assembly or specific syntax

**COMPONENTS BREAKDOWN**:

1. **`0xff`** - Constant prefix to distinguish from CREATE
   - Prevents collision with CREATE addresses
   - Single byte: `0xff`

2. **`sender_address`** - Factory contract address (20 bytes)
   - The contract deploying (factory)
   - From Project 01: address type is 20 bytes

3. **`salt`** - 32-byte value chosen by deployer
   - Allows multiple deployments with same bytecode
   - Different salt = different address
   - From Project 01: bytes32 type

4. **`initCode`** - Contract creation bytecode (constructor + runtime code)
   - Includes constructor parameters
   - Hash ensures bytecode changes = address changes

**USE CASES**:

1. **Counterfactual Contracts**: Deploy only when needed
2. **Address-Based Logic**: Know address before deployment
3. **Minimal Proxies**: Deploy many instances efficiently
4. **State Channels**: Predictable addresses for channels

**GAS COST** (from Project 01 knowledge):
- CREATE2 deployment: ~32,000 gas (base) + contract size
- Address calculation: ~100 gas (keccak256 computation)
- Prediction: FREE (off-chain calculation)

**COMPARISON TO RUST** (Conceptual):

**Rust** (no direct equivalent):
```rust
// Rust doesn't have deterministic deployment
// But similar concept: deterministic IDs based on content
let id = sha256(format!("{}{}{}", prefix, salt, content));
```

**Solidity** (CREATE2):
```solidity
address predicted = address(uint160(uint256(keccak256(abi.encodePacked(
    bytes1(0xff),
    factory,
    salt,
    keccak256(initCode)
)))));
```

CREATE2 is unique to EVM - enables powerful deployment patterns!

## How CREATE2 Works

### Address Calculation Formula

```solidity
address predictedAddress = address(uint160(uint256(keccak256(abi.encodePacked(
    bytes1(0xff),
    address(this),      // Factory address
    salt,               // 32-byte salt
    keccak256(initCode) // Hash of creation bytecode
)))));
```

### Initcode vs Runtime Code

**Initcode (Creation Bytecode):**
- Code that runs during contract deployment
- Includes constructor logic and parameters
- Returns the runtime bytecode
- Never stored on-chain
- Used for address calculation in CREATE2

**Runtime Code:**
- The actual contract code stored on-chain
- What you write in your contract
- Executes when contract is called
- Result of initcode execution

**Getting Initcode:**
```solidity
// Without constructor arguments
bytes memory initCode = type(MyContract).creationCode;

// With constructor arguments
bytes memory initCode = abi.encodePacked(
    type(MyContract).creationCode,
    abi.encode(arg1, arg2, arg3)
);
```

### Salt Usage

The salt is a 32-byte value that allows deploying the same contract to different addresses:

```solidity
bytes32 salt1 = keccak256("version1");
bytes32 salt2 = keccak256("version2");

// Same contract, different salts = different addresses
address addr1 = deploy(salt1);
address addr2 = deploy(salt2);
```

**Salt Strategies:**
- User-specific: `keccak256(abi.encodePacked(userAddress))`
- Version-based: `keccak256("v1.0.0")`
- Sequential: `bytes32(uint256(counter++))`
- Random: `keccak256(abi.encodePacked(block.timestamp, msg.sender))`

## Deploying with CREATE2

### Basic Syntax

```solidity
contract Factory {
    function deploy(bytes32 salt) public returns (address) {
        MyContract instance = new MyContract{salt: salt}();
        return address(instance);
    }
}
```

### With Assembly

```solidity
function deploy(bytes32 salt, bytes memory bytecode) public returns (address addr) {
    assembly {
        addr := create2(
            0,                              // value (ETH to send)
            add(bytecode, 0x20),           // bytecode start
            mload(bytecode),               // bytecode length
            salt                            // salt
        )

        if iszero(extcodesize(addr)) {
            revert(0, 0)
        }
    }
}
```

### Assembly Breakdown

- `create2(value, offset, size, salt)` - CREATE2 opcode
- `add(bytecode, 0x20)` - Skip first 32 bytes (length prefix)
- `mload(bytecode)` - Read length from first 32 bytes
- `extcodesize(addr)` - Check deployment succeeded (size > 0)

## Address Prediction Off-Chain

You can predict addresses before deployment using the same formula:

### TypeScript Example

```typescript
import { ethers } from 'ethers';

function predictAddress(factoryAddress: string, salt: string, initCodeHash: string): string {
    return ethers.getCreate2Address(
        factoryAddress,
        salt,
        initCodeHash
    );
}

// Usage
const factory: string = "0x1234...";
const salt: string = ethers.id("my-salt");
const initCode: string = MyContract.bytecode;
const initCodeHash: string = ethers.keccak256(initCode);

const predicted: string = predictAddress(factory, salt, initCodeHash);
```

### Solidity Example

```solidity
function predictAddress(bytes32 salt, bytes memory bytecode)
    public
    view
    returns (address)
{
    bytes32 hash = keccak256(
        abi.encodePacked(
            bytes1(0xff),
            address(this),
            salt,
            keccak256(bytecode)
        )
    );
    return address(uint160(uint256(hash)));
}
```

## Use Cases

### 1. Counterfactual Contracts

Deploy contracts only when needed, but use the address beforehand:

```solidity
// Predict address
address wallet = predictWalletAddress(owner);

// Send funds to predicted address
(bool sent, ) = wallet.call{value: 1 ether}("");

// Deploy later when needed
if (address(wallet).code.length == 0) {
    deployWallet(owner);
}
```

### 2. State Channels

- Predict contract addresses for state channel disputes
- Deploy only if dispute occurs
- Saves gas in optimistic case

### 3. Minimal Proxies

- Deploy minimal proxy clones to deterministic addresses
- EIP-1167 compatible
- Gas-efficient contract replication

### 4. Account Abstraction

- Smart contract wallets (EIP-4337)
- Predict wallet address before deployment
- Users can receive funds before wallet creation

### 5. Cross-Chain Deployment

- Deploy same contract to same address on different chains
- Requires same deployer address and salt
- Useful for multi-chain protocols

### 6. Upgradeable Patterns

- Deploy new implementations to predictable addresses
- Coordinate upgrades across multiple proxies
- Version management

## Important Considerations

### 1. Deployment Fails if Address Occupied

```solidity
// Will revert if already deployed
new MyContract{salt: salt}();

// Check before deploying
if (predictedAddress.code.length == 0) {
    new MyContract{salt: salt}();
}
```

### 2. Constructor Arguments Affect Address

```solidity
// Different initcode = different address
bytes memory initCode1 = abi.encodePacked(
    type(MyContract).creationCode,
    abi.encode(arg1)
);

bytes memory initCode2 = abi.encodePacked(
    type(MyContract).creationCode,
    abi.encode(arg2)
);

// initCode1 != initCode2, so addresses will differ
```

### 3. Self-Destruct and Redeployment

Before Cancun upgrade:
- Could `selfdestruct` and redeploy to same address
- Enabled malicious patterns

After Cancun (EIP-6780):
- `selfdestruct` only works in same transaction as creation
- Cannot redeploy to same address after deployment
- More secure

### 4. Factory Address Matters

```solidity
// Different factory = different address (same salt, same bytecode)
Factory1.deploy(salt) != Factory2.deploy(salt)
```

## Security Considerations

### 1. Salt Manipulation

```solidity
// Bad: Predictable salt
bytes32 salt = keccak256(abi.encodePacked(block.timestamp));

// Better: Include sender
bytes32 salt = keccak256(abi.encodePacked(msg.sender, userNonce));
```

### 2. Frontrunning

Attackers can frontrun deployment with same salt:
- Monitor mempool for CREATE2 deployments
- Deploy with higher gas price
- Original transaction reverts

**Mitigation:**
```solidity
mapping(address => bool) public canDeploy;

function deploy(bytes32 salt) public {
    require(canDeploy[msg.sender], "Not authorized");
    // Deploy...
}
```

### 3. Initcode Verification

Always verify the bytecode matches expectations:
```solidity
function deploy(bytes32 salt, bytes memory bytecode) public {
    bytes32 expectedHash = keccak256(type(MyContract).creationCode);
    bytes32 actualHash = keccak256(bytecode);
    require(expectedHash == actualHash, "Invalid bytecode");

    // Deploy...
}
```

## Testing Strategies

1. **Address Prediction:**
   - Predict address off-chain
   - Deploy contract
   - Verify addresses match

2. **Salt Uniqueness:**
   - Deploy with salt A
   - Attempt redeploy with same salt (should revert)
   - Deploy with salt B (should succeed)

3. **Constructor Arguments:**
   - Test with different constructor args
   - Verify addresses differ
   - Ensure proper initialization

4. **Cross-Factory:**
   - Deploy from different factories
   - Verify addresses differ
   - Test isolation

## Project Structure

```
16-contract-factories/
├── src/
│   ├── Project16.sol              # Skeleton implementation
│   └── solution/
│       └── Project16Solution.sol  # Complete solution
├── test/
│   └── Project16.t.sol            # Comprehensive tests
├── script/
│   └── DeployProject16.s.sol      # Deployment script
└── README.md                       # This file
```

## Tasks

### Part 1: Basic Factory

1. Implement `ContractFactory` with CREATE2
2. Add address prediction function
3. Track deployed contracts
4. Prevent duplicate deployments

### Part 2: Advanced Features

5. Deploy with constructor arguments
6. Implement salt generation strategies
7. Add deployment events
8. Create helper functions

### Part 3: Testing

9. Write prediction tests
10. Test duplicate prevention
11. Verify address calculation
12. Test edge cases

## Getting Started

```bash
# Run tests
forge test --match-path test/ContractFactory.t.sol -vvv

# Check skeleton
forge build

# See solution
cat src/solution/ContractFactorySolution.sol

# Deploy
forge script script/DeployContractFactory.s.sol --rpc-url $RPC_URL --broadcast
```

## Additional Resources

- [EIP-1014: CREATE2](https://eips.ethereum.org/EIPS/eip-1014)
- [EIP-6780: SELFDESTRUCT Changes](https://eips.ethereum.org/EIPS/eip-6780)
- [OpenZeppelin CREATE2](https://docs.openzeppelin.com/cli/2.8/deploying-with-create2)
- [Solidity Documentation: CREATE2](https://docs.soliditylang.org/en/latest/control-structures.html#salted-contract-creations-create2)

## Common Pitfalls

1. Forgetting to include constructor args in initcode
2. Using wrong factory address in prediction
3. Not checking if address already deployed
4. Assuming bytecode is constant across Solidity versions
5. Not accounting for compiler settings affecting bytecode

## Advanced Topics

- Minimal proxy factories with CREATE2
- Diamond pattern deployment
- CREATE3 (CREATE2 + proxy wrapper)
- Deterministic cross-chain deployments
- Metamorphic contracts (pre-Cancun)

## Conclusion

CREATE2 is a powerful tool for deterministic deployments. Understanding address calculation, initcode, and salt usage unlocks advanced patterns like counterfactual contracts and state channels.

Master these concepts to build more sophisticated smart contract systems!
