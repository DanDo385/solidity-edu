# Project 17: Minimal Proxy (EIP-1167)

Learn how to use the minimal proxy pattern to deploy multiple contract instances at a fraction of the normal deployment cost.

## Learning Objectives

- Understand EIP-1167 minimal proxy standard
- Master the clone factory pattern
- Learn initialization patterns for proxies
- Compare gas costs: clone vs new deployment
- Understand when to use clones vs regular deployments
- Work with OpenZeppelin's Clones library

## What is EIP-1167?

EIP-1167 defines a minimal bytecode implementation that delegates all calls to a known, fixed address. This standard allows for the creation of extremely cheap proxy contracts (clones) that forward all calls to an implementation contract.

### Key Concepts

#### 1. Minimal Proxy Bytecode

The minimal proxy is only **45 bytes** of bytecode that:
- Delegates all calls to an implementation address
- Forwards all `msg.data` to the implementation
- Returns the result back to the caller
- Preserves `msg.sender` and `msg.value`

```
363d3d373d3d3d363d73bebebebebebebebebebebebebebebebebebebebe5af43d82803e903d91602b57fd5bf3
```

Where `bebebebe...` is the implementation address.

#### 2. How It Works

```
┌─────────────┐         ┌──────────────┐         ┌────────────────┐
│   Caller    │────────>│  Clone Proxy │────────>│ Implementation │
└─────────────┘         └──────────────┘         └────────────────┘
                              (45 bytes)             (Full Contract)
```

**Call Flow:**
1. User calls clone at address A
2. Clone's minimal bytecode delegates to implementation at address B
3. Implementation executes in the context of clone (using clone's storage)
4. Result is returned to user

#### 3. Important Properties

- **Storage**: Each clone has its own storage (isolated from implementation and other clones)
- **Address**: Each clone has a unique address
- **Bytecode**: All clones share the same minimal bytecode (only implementation address differs)
- **Execution Context**: Functions execute with the clone's `address(this)` and storage

## Clone vs New Deployment

### Gas Cost Comparison

| Operation | New Deployment | Clone | Savings |
|-----------|---------------|-------|---------|
| Simple Contract | ~200,000 gas | ~40,000 gas | **80%** |
| Medium Contract | ~500,000 gas | ~40,000 gas | **92%** |
| Complex Contract | ~2,000,000 gas | ~40,000 gas | **98%** |

**Why such savings?**
- New deployment: Must deploy full bytecode (runtime + constructor)
- Clone: Only deploys 45 bytes + minimal creation code

### When to Use Clones

**Good Use Cases:**
- NFT collections (each token as a separate contract)
- User wallets (one per user)
- Escrow contracts (one per transaction)
- Prediction markets (one per market)
- Any pattern requiring many identical contract instances

**Not Recommended:**
- Upgradeable proxies (use UUPS or Transparent instead)
- Single instance contracts
- When initialization is complex and gas is not critical

## Runtime vs Initcode

### Understanding the Separation

**Initcode (Constructor Code):**
- Runs only once during deployment
- Returns the runtime bytecode
- Can accept constructor arguments
- Not stored on-chain

**Runtime Bytecode:**
- Stored on-chain permanently
- Executed on every call
- Contains all contract functions
- Must be as small as possible

### Clone Pattern Impact

```solidity
// Traditional deployment
contract MyContract {
    address public owner;
    uint256 public value;

    // Constructor runs during deployment (initcode)
    constructor(address _owner, uint256 _value) {
        owner = _owner;
        value = _value;
    }
}

// Clone pattern - no constructor!
contract MyContractCloneable {
    address public owner;
    uint256 public value;
    bool private initialized;

    // Initialize function runs AFTER deployment
    function initialize(address _owner, uint256 _value) external {
        require(!initialized, "Already initialized");
        initialized = true;
        owner = _owner;
        value = _value;
    }
}
```

**Why no constructor for clones?**
- Clones copy runtime bytecode only
- Constructor is part of initcode (not copied)
- Must use initialization function instead

## Clone Factory Patterns

### Pattern 1: Basic Clone Factory

```solidity
import "@openzeppelin/contracts/proxy/Clones.sol";

contract BasicFactory {
    address public implementation;

    constructor(address _implementation) {
        implementation = _implementation;
    }

    function createClone() external returns (address) {
        return Clones.clone(implementation);
    }
}
```

### Pattern 2: Clone and Initialize

```solidity
contract CloneAndInitFactory {
    address public implementation;

    function createClone(bytes memory initData) external returns (address) {
        address clone = Clones.clone(implementation);
        (bool success,) = clone.call(initData);
        require(success, "Initialization failed");
        return clone;
    }
}
```

### Pattern 3: Deterministic Clones

```solidity
contract DeterministicFactory {
    address public implementation;

    function createClone(bytes32 salt) external returns (address) {
        return Clones.cloneDeterministic(implementation, salt);
    }

    function predictAddress(bytes32 salt) external view returns (address) {
        return Clones.predictDeterministicAddress(implementation, salt);
    }
}
```

## Initialization Patterns

### Anti-Pattern: Unprotected Initialize

```solidity
// DON'T DO THIS - Anyone can initialize!
contract Bad {
    address public owner;

    function initialize(address _owner) external {
        owner = _owner; // No protection!
    }
}
```

### Pattern 1: Single Initialize

```solidity
contract SingleInit {
    address public owner;
    bool private initialized;

    function initialize(address _owner) external {
        require(!initialized, "Already initialized");
        initialized = true;
        owner = _owner;
    }
}
```

### Pattern 2: OpenZeppelin Initializable

```solidity
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract OZInit is Initializable {
    address public owner;

    function initialize(address _owner) external initializer {
        owner = _owner;
    }
}
```

### Pattern 3: Factory-Only Initialize

```solidity
contract FactoryInit {
    address public immutable factory;
    address public owner;
    bool private initialized;

    constructor() {
        factory = msg.sender; // Set in implementation deployment
    }

    function initialize(address _owner) external {
        require(msg.sender == factory, "Only factory");
        require(!initialized, "Already initialized");
        initialized = true;
        owner = _owner;
    }
}
```

## OpenZeppelin Clones Library

### Available Functions

```solidity
library Clones {
    // Creates a non-deterministic clone
    function clone(address implementation) internal returns (address);

    // Creates a deterministic clone using CREATE2
    function cloneDeterministic(address implementation, bytes32 salt)
        internal returns (address);

    // Predicts the address of a deterministic clone
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address);

    // Predicts using msg.sender as deployer
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal view returns (address);
}
```

### Usage Example

```solidity
import "@openzeppelin/contracts/proxy/Clones.sol";

contract MyFactory {
    using Clones for address;

    address public implementation;
    address[] public allClones;

    function createClone() external returns (address) {
        // Simple clone
        address clone = implementation.clone();
        allClones.push(clone);
        return clone;
    }

    function createDeterministicClone(bytes32 salt) external returns (address) {
        // Deterministic clone (can predict address)
        address clone = implementation.cloneDeterministic(salt);
        allClones.push(clone);
        return clone;
    }

    function predictCloneAddress(bytes32 salt) external view returns (address) {
        return implementation.predictDeterministicAddress(salt);
    }
}
```

## Security Considerations

### 1. Initialize Protection

```solidity
// CRITICAL: Prevent re-initialization
bool private initialized;

function initialize(address _owner) external {
    require(!initialized, "Already initialized");
    initialized = true;
    owner = _owner;
}
```

### 2. Selfdestruct Warning

```solidity
// DANGER: If implementation selfdestructs, ALL clones break!
contract Implementation {
    function destroy() external {
        selfdestruct(payable(msg.sender)); // DON'T DO THIS!
    }
}
```

### 3. Delegatecall Awareness

Remember: Clones use `delegatecall`, so:
- `msg.sender` is preserved (the original caller)
- `address(this)` is the clone's address
- Storage is the clone's storage
- Implementation cannot have constructor state

## Gas Optimization Tips

### 1. Batch Clone Creation

```solidity
function createMultipleClones(uint256 count) external returns (address[] memory) {
    address[] memory newClones = new address[](count);
    for (uint256 i = 0; i < count; i++) {
        newClones[i] = Clones.clone(implementation);
    }
    return newClones;
}
```

### 2. Deterministic vs Regular Clones

- **Regular clone** (`clone`): Cheaper (~41,000 gas)
- **Deterministic clone** (`cloneDeterministic`): Slightly more expensive (~43,000 gas)
- Use deterministic only when you need predictable addresses

### 3. Initialize in Same Transaction

```solidity
function createAndInitialize(address owner) external returns (address) {
    address clone = Clones.clone(implementation);
    IMyContract(clone).initialize(owner);
    return clone;
}
```

## Common Patterns

### Pattern 1: NFT Collection Factory

```solidity
contract NFTCollectionFactory {
    address public nftImplementation;
    mapping(address => address[]) public creatorCollections;

    function createCollection(string memory name, string memory symbol)
        external returns (address) {
        address collection = Clones.clone(nftImplementation);
        INFTCollection(collection).initialize(msg.sender, name, symbol);
        creatorCollections[msg.sender].push(collection);
        return collection;
    }
}
```

### Pattern 2: Wallet Factory

```solidity
contract WalletFactory {
    address public walletImplementation;
    mapping(address => address) public userWallets;

    function createWallet() external returns (address) {
        require(userWallets[msg.sender] == address(0), "Wallet exists");

        bytes32 salt = bytes32(uint256(uint160(msg.sender)));
        address wallet = Clones.cloneDeterministic(walletImplementation, salt);

        IWallet(wallet).initialize(msg.sender);
        userWallets[msg.sender] = wallet;
        return wallet;
    }

    function predictWalletAddress(address user) external view returns (address) {
        bytes32 salt = bytes32(uint256(uint160(user)));
        return Clones.predictDeterministicAddress(walletImplementation, salt);
    }
}
```

### Pattern 3: Escrow Factory

```solidity
contract EscrowFactory {
    address public escrowImplementation;

    event EscrowCreated(address indexed escrow, address indexed buyer, address indexed seller);

    function createEscrow(address seller, address token, uint256 amount)
        external returns (address) {
        address escrow = Clones.clone(escrowImplementation);
        IEscrow(escrow).initialize(msg.sender, seller, token, amount);
        emit EscrowCreated(escrow, msg.sender, seller);
        return escrow;
    }
}
```

## Your Task

Implement a complete clone factory system:

1. **Implementation Contract**: Create a simple contract that can be cloned
2. **Factory Contract**: Create a factory that clones the implementation
3. **Initialization**: Implement safe initialization pattern
4. **Gas Comparison**: Compare gas costs between clone and new deployment
5. **Multiple Clones**: Deploy and test multiple independent clones

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/MinimalProxySolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployMinimalProxySolution.s.sol` - Deployment script patterns
- `test/solution/MinimalProxySolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains code reuse via delegatecall, template pattern, gas optimization
- **Connections to Project 10**: Uses delegatecall (like upgradeable proxies)
- **Connections to Project 15**: Low-level calls for cloning mechanism
- **Connections to Project 16**: CREATE2 for deterministic clone addresses
- **Real-World Context**: 88% gas savings vs full deployment - used in production for multi-instance contracts

## Testing Checklist

- [ ] Deploy implementation contract
- [ ] Create clone factory
- [ ] Deploy clone using factory
- [ ] Initialize clone successfully
- [ ] Verify clone independence (separate storage)
- [ ] Compare gas costs (clone vs new)
- [ ] Test multiple clones
- [ ] Verify initialization protection (prevent re-init)
- [ ] Test deterministic clones (optional)
- [ ] Verify address prediction (optional)

## Expected Gas Savings

For the implementation in this project:
- **New deployment**: ~350,000 - 400,000 gas
- **Clone deployment**: ~41,000 - 45,000 gas
- **Savings**: ~90% reduction!

## Resources

- [EIP-1167 Specification](https://eips.ethereum.org/EIPS/eip-1167)
- [OpenZeppelin Clones Library](https://docs.openzeppelin.com/contracts/4.x/api/proxy#Clones)
- [Minimal Proxy Deep Dive](https://blog.openzeppelin.com/deep-dive-into-the-minimal-proxy-contract/)

## Running the Project

```bash
# Install dependencies
forge install

# Run tests
forge test --match-path test/Project17.t.sol -vv

# See gas comparison
forge test --match-path test/Project17.t.sol --gas-report

# Deploy
forge script script/DeployProject17.s.sol:DeployProject17 --rpc-url <your_rpc_url> --broadcast
```

## Next Steps

After completing this project, explore:
- **UUPS Proxies** (upgradeable proxies)
- **Transparent Proxies** (admin-based upgrades)
- **Beacon Proxies** (multiple proxies, single upgradeable implementation)
- **Diamond Pattern** (multi-facet proxies)
