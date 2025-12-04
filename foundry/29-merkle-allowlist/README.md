# Project 29: Merkle Proof Allowlists

Learn how to use Merkle trees for efficient allowlist verification in smart contracts.

## Overview

This project teaches you how to implement gas-efficient allowlists using Merkle trees and Merkle proofs. Instead of storing thousands of allowlisted addresses on-chain, you store a single 32-byte Merkle root and verify proofs off-chain.

## What are Merkle Trees?

A Merkle tree (also called a hash tree) is a data structure where:
- Each leaf node is a hash of some data
- Each non-leaf node is a hash of its children
- The root node represents the entire dataset

```
         Root Hash (Merkle Root)
              /        \
           H(AB)      H(CD)
           /  \        /  \
         H(A) H(B)  H(C) H(D)
          |    |     |    |
          A    B     C    D
```

### Properties

1. **Compact**: Only need to store the root hash (32 bytes)
2. **Verifiable**: Can prove a leaf is in the tree without revealing all leaves
3. **Immutable**: Changing any leaf changes the root hash
4. **Efficient**: Proof size is O(log n) where n is the number of leaves

## How Merkle Proofs Work

To prove that leaf `A` is in the tree, you need:
1. The leaf data (`A`)
2. The sibling hashes along the path to the root (`H(B)`, `H(CD)`)

Verification:
```
1. Compute H(A)
2. Compute H(AB) = hash(H(A) + H(B))
3. Compute Root = hash(H(AB) + H(CD))
4. Compare computed Root with stored Root
```

If they match, the proof is valid!

## Why Use Merkle Trees vs Mappings?

### Traditional Allowlist (Mapping)

```solidity
mapping(address => bool) public allowlist;

// Setting up 1000 addresses
function setAllowlist(address[] calldata addresses) external {
    for (uint i = 0; i < addresses.length; i++) {
        allowlist[addresses[i]] = true; // ~20,000 gas per address
    }
}
// Total: ~20,000,000 gas for 1000 addresses!
```

### Merkle Allowlist

```solidity
bytes32 public merkleRoot;

// Setting up ANY number of addresses
function setMerkleRoot(bytes32 _root) external {
    merkleRoot = _root; // ~20,000 gas total
}
// Total: ~20,000 gas for ANY number of addresses!
```

### Gas Comparison

| Operation | Mapping | Merkle Tree |
|-----------|---------|-------------|
| Setup 100 addresses | ~2,000,000 gas | ~20,000 gas |
| Setup 1,000 addresses | ~20,000,000 gas | ~20,000 gas |
| Setup 10,000 addresses | ~200,000,000 gas | ~20,000 gas |
| Verify 1 address | ~2,100 gas | ~3,500 gas |

**Winner**: Merkle trees for large allowlists!

## Creating Merkle Trees Off-Chain

### Using TypeScript (ethers.js + merkletreejs)

```typescript
import { MerkleTree } from 'merkletreejs';
import keccak256 from 'keccak256';
import { ethers } from 'ethers';

// 1. Define your allowlist
const allowlist: string[] = [
    "0x1111111111111111111111111111111111111111",
    "0x2222222222222222222222222222222222222222",
    "0x3333333333333333333333333333333333333333"
];

// 2. Create leaf nodes (hash each address)
const leafNodes: Buffer[] = allowlist.map(addr =>
    keccak256(ethers.solidityPacked(['address'], [addr]))
);

// 3. Create Merkle tree
const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true });

// 4. Get root hash
const rootHash: Buffer = merkleTree.getRoot();
console.log("Merkle Root:", "0x" + rootHash.toString('hex'));

// 5. Generate proof for an address
const address: string = "0x1111111111111111111111111111111111111111";
const leaf: Buffer = keccak256(ethers.solidityPacked(['address'], [address]));
const proof: string[] = merkleTree.getHexProof(leaf);
console.log("Proof:", proof);
```

### Using Foundry (Solidity)

```solidity
// In your test file
import "forge-std/Test.sol";
import "murky/Merkle.sol";

contract MerkleTest is Test {
    Merkle merkle = new Merkle();

    function testGenerateMerkleTree() public {
        bytes32[] memory leaves = new bytes32[](3);
        leaves[0] = keccak256(abi.encodePacked(address(0x1111)));
        leaves[1] = keccak256(abi.encodePacked(address(0x2222)));
        leaves[2] = keccak256(abi.encodePacked(address(0x3333)));

        bytes32 root = merkle.getRoot(leaves);
        bytes32[] memory proof = merkle.getProof(leaves, 0);

        bool verified = merkle.verifyProof(root, proof, leaves[0]);
        assertTrue(verified);
    }
}
```

## Proof Verification On-Chain

### Using OpenZeppelin's MerkleProof

```solidity
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MyContract {
    bytes32 public merkleRoot;

    function verify(
        bytes32[] calldata proof,
        address account
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(account));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }
}
```

### Manual Implementation

```solidity
function verifyProof(
    bytes32[] memory proof,
    bytes32 root,
    bytes32 leaf
) internal pure returns (bool) {
    bytes32 computedHash = leaf;

    for (uint256 i = 0; i < proof.length; i++) {
        bytes32 proofElement = proof[i];

        if (computedHash <= proofElement) {
            computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
        } else {
            computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
        }
    }

    return computedHash == root;
}
```

## Security Considerations

### 1. Double Claiming

**Problem**: Users might try to claim multiple times

**Solution**: Track claimed addresses

```solidity
mapping(address => bool) public hasClaimed;

function claim(bytes32[] calldata proof) external {
    require(!hasClaimed[msg.sender], "Already claimed");
    require(verify(proof, msg.sender), "Invalid proof");

    hasClaimed[msg.sender] = true;
    // Transfer tokens/NFT
}
```

### 2. Leaf Node Hashing

**Problem**: If you hash just the address, someone could use a proof for one tree in another tree

**Solution**: Include additional context in the leaf

```solidity
// Better: Include contract-specific data
bytes32 leaf = keccak256(abi.encodePacked(account, amount, contractAddress));

// Or use OpenZeppelin's MessageHashUtils
bytes32 leaf = MessageHashUtils.toEthSignedMessageHash(
    keccak256(abi.encodePacked(account))
);
```

### 3. Proof Forgery

**Problem**: Attacker might try to forge proofs

**Defense**: OpenZeppelin's MerkleProof library handles this correctly by:
- Sorting pairs during hashing
- Preventing second pre-image attacks
- Validating proof length

### 4. Front-Running

**Problem**: Attacker sees your valid claim transaction and front-runs it

**Mitigation**:
```solidity
// Option 1: Signature-based claiming
function claim(bytes32[] calldata proof, bytes calldata signature) external {
    require(verify(proof, msg.sender), "Invalid proof");
    require(verifySignature(signature), "Invalid signature");
    // ...
}

// Option 2: Commit-reveal pattern
// Option 3: Accept front-running (if minting is cheap)
```

### 5. Root Update

**Problem**: Owner updates root maliciously

**Solution**:
```solidity
// Make root immutable
bytes32 public immutable merkleRoot;

constructor(bytes32 _root) {
    merkleRoot = _root;
}

// Or use a timelock
uint256 public constant ROOT_UPDATE_DELAY = 7 days;
```

## Common Use Cases

### 1. Allowlist Minting (NFTs)

```solidity
contract AllowlistNFT is ERC721 {
    bytes32 public merkleRoot;
    mapping(address => bool) public hasMinted;

    function allowlistMint(bytes32[] calldata proof) external {
        require(!hasMinted[msg.sender], "Already minted");
        require(verify(proof, msg.sender), "Not on allowlist");

        hasMinted[msg.sender] = true;
        _mint(msg.sender, totalSupply());
    }
}
```

### 2. Airdrops with Amounts

```solidity
contract Airdrop {
    bytes32 public merkleRoot;
    mapping(address => bool) public hasClaimed;

    function claim(
        uint256 amount,
        bytes32[] calldata proof
    ) external {
        require(!hasClaimed[msg.sender], "Already claimed");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");

        hasClaimed[msg.sender] = true;
        token.transfer(msg.sender, amount);
    }
}
```

### 3. Tiered Access

```solidity
contract TieredNFT {
    bytes32 public goldRoot;
    bytes32 public silverRoot;

    function mintGold(bytes32[] calldata proof) external {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, goldRoot, leaf), "Not gold tier");
        _mint(msg.sender, GOLD_TIER);
    }

    function mintSilver(bytes32[] calldata proof) external {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, silverRoot, leaf), "Not silver tier");
        _mint(msg.sender, SILVER_TIER);
    }
}
```

### 4. Vesting Schedule

```solidity
contract VestingAirdrop {
    struct VestingInfo {
        uint256 totalAmount;
        uint256 startTime;
        uint256 duration;
    }

    bytes32 public merkleRoot;
    mapping(address => uint256) public claimed;

    function claim(
        VestingInfo calldata vesting,
        bytes32[] calldata proof
    ) external {
        bytes32 leaf = keccak256(abi.encode(msg.sender, vesting));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");

        uint256 vested = calculateVested(vesting);
        uint256 claimable = vested - claimed[msg.sender];

        claimed[msg.sender] = vested;
        token.transfer(msg.sender, claimable);
    }
}
```

## Best Practices

1. **Always Use OpenZeppelin's MerkleProof**: Don't implement your own unless you have a specific reason
2. **Sort Pairs**: Ensure consistent tree construction with `{ sortPairs: true }`
3. **Track Claims**: Use mapping to prevent double claiming
4. **Test Edge Cases**: Empty proofs, invalid proofs, forged proofs
5. **Document Your Tree Structure**: Make it clear how leaves are hashed
6. **Consider Leaf Uniqueness**: Hash with additional data if needed
7. **Gas Optimize**: Larger trees = more proof elements = more gas
8. **Store Proofs Off-Chain**: Don't put proofs in the contract
9. **Provide Proof Generation Tools**: Make it easy for users to get their proofs
10. **Consider Multi-Proof**: For claiming multiple items, use MultiProof

## Advanced: Multi Proof

For claiming multiple items efficiently:

```solidity
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

function claimMultiple(
    uint256[] calldata amounts,
    bytes32[] calldata proof,
    bool[] calldata proofFlags
) external {
    bytes32[] memory leaves = new bytes32[](amounts.length);
    for (uint i = 0; i < amounts.length; i++) {
        leaves[i] = keccak256(abi.encodePacked(msg.sender, amounts[i]));
    }

    require(
        MerkleProof.multiProofVerify(proof, proofFlags, merkleRoot, leaves),
        "Invalid multi-proof"
    );

    // Process all claims
}
```

## Learning Objectives

By completing this project, you will learn:
- How Merkle trees work and why they're useful
- How to create Merkle trees off-chain
- How to verify Merkle proofs on-chain
- Gas efficiency comparison between methods
- Common security pitfalls and how to avoid them
- Real-world use cases for Merkle trees

## Project Structure

```
29-merkle-allowlist/
├── src/
│   ├── Project29.sol              # Skeleton with TODOs
│   └── solution/
│       └── Project29Solution.sol  # Complete solution
├── test/
│   └── Project29.t.sol            # Comprehensive tests
├── script/
│   └── DeployProject29.s.sol      # Deployment script
└── README.md                      # This file
```

## Tasks

1. Implement Merkle proof verification
2. Add allowlist minting functionality
3. Prevent double claiming
4. Write tests for valid and invalid proofs
5. Compare gas costs with mapping approach
6. Generate Merkle trees off-chain

## Testing

```bash
# Run tests
forge test --match-path test/Project29.t.sol -vv

# Run with gas reporting
forge test --match-path test/Project29.t.sol --gas-report

# Test specific function
forge test --match-test testValidProof -vvv
```

## Deployment

```bash
# Deploy to local network
forge script script/DeployProject29.s.sol --rpc-url http://localhost:8545 --broadcast

# Deploy to testnet
forge script script/DeployProject29.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
```

## Resources

- [OpenZeppelin MerkleProof](https://docs.openzeppelin.com/contracts/5.x/api/utils#MerkleProof)
- [Merkle Tree JS Library](https://github.com/merkletreejs/merkletreejs)
- [Murky (Foundry Merkle)](https://github.com/dmfxyz/murky)
- [Uniswap Merkle Distributor](https://github.com/Uniswap/merkle-distributor)
- [How Merkle Trees Work](https://en.wikipedia.org/wiki/Merkle_tree)

## Further Exploration

- Implement a multi-tier allowlist
- Add dynamic Merkle root updates with governance
- Create an airdrop with different amounts per address
- Implement batch claiming with MultiProof
- Build a frontend for proof generation and claiming
- Optimize for extremely large allowlists (1M+ addresses)

## Common Pitfalls

1. **Not sorting pairs**: Trees must be consistent
2. **Forgetting to track claims**: Users can claim multiple times
3. **Incorrect leaf hashing**: Must match off-chain construction
4. **Not validating proof length**: Could lead to unexpected behavior
5. **Storing proofs on-chain**: Defeats the purpose of Merkle trees
6. **Updating root without consideration**: Could invalidate existing proofs

Good luck! Merkle trees are a powerful tool for building gas-efficient smart contracts.
