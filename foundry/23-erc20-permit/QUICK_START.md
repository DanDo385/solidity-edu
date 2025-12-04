# Quick Start Guide - Project 23: ERC-20 Permit

Get started with ERC-20 Permit (EIP-2612) in 5 minutes!

## Prerequisites

```bash
# Ensure Foundry is installed
forge --version

# If not installed, run:
# curl -L https://foundry.paradigm.xyz | bash
# foundryup
```

## 1. Install Dependencies

From the main repository directory:

```bash
cd /home/user/solidity-edu

# Install OpenZeppelin contracts
forge install OpenZeppelin/openzeppelin-contracts --no-commit
```

## 2. Build the Project

```bash
# Build all contracts
forge build

# Build only Project 23
forge build --contracts 23-erc20-permit
```

## 3. Run Tests

```bash
# Run all Project 23 tests
forge test --match-path 23-erc20-permit/test/Project23.t.sol -vv

# Run with gas reporting
forge test --match-path 23-erc20-permit/test/Project23.t.sol --gas-report

# Run specific test
forge test --match-test testPermitSetsApproval -vvv

# Run with detailed gas comparison
forge test --match-test testGasComparison -vvv
```

## 4. Understanding the Code

### Start with the Skeleton (`src/Project23.sol`)

This file has TODOs for you to implement:
- Domain separator computation
- Permit signature verification
- Nonce management
- EIP-712 hashing

### Review the Solution (`src/solution/Project23Solution.sol`)

Two implementations provided:
1. **Project23Solution**: Uses OpenZeppelin's ERC20Permit (recommended)
2. **Project23CustomImplementation**: Manual implementation for learning

### Study the Tests (`test/Project23.t.sol`)

Comprehensive test coverage:
- Basic permit functionality
- Signature verification
- Replay protection
- Gas comparisons (approve vs permit)
- Edge cases

## 5. Key Concepts to Understand

### EIP-2612 Permit Function

```solidity
function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
) external;
```

### Creating a Permit Signature (Off-Chain)

```typescript
// In your frontend/tests
const domain = {
    name: 'PermitToken',
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
    deadline: Math.floor(Date.now() / 1000) + 3600
};

const signature: string = await signer.signTypedData(domain, types, value);
```

## 6. Deploy Locally

```bash
# Start local Anvil node
anvil

# In another terminal, deploy
forge script 23-erc20-permit/script/DeployProject23.s.sol:DeployProject23 \
    --rpc-url http://localhost:8545 \
    --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
    --broadcast
```

## 7. Interactive Testing

```bash
# Start Forge console
forge console

# Inside console:
> Project23Solution token = new Project23Solution()
> token.name()
> token.DOMAIN_SEPARATOR()
> token.balanceOf(address(this))
```

## 8. Common Tasks

### Task 1: Implement the Skeleton

1. Open `src/Project23.sol`
2. Fill in the TODOs:
   - `constructor()` - Compute domain separator
   - `permit()` - Implement signature verification
   - `DOMAIN_SEPARATOR()` - Return cached separator
   - `_hashTypedDataV4()` - Create EIP-712 digest
   - `nonces()` - Return current nonce
   - `_useNonce()` - Increment and return nonce

### Task 2: Test Your Implementation

```bash
# Test your implementation
forge test --match-path 23-erc20-permit/test/Project23.t.sol -vv
```

### Task 3: Compare Gas Usage

```bash
# Run gas comparison tests
forge test --match-test testGasComparison -vvv

# Expected output:
# Approve gas: ~46,000
# Permit gas: ~40,000
# Traditional (2 tx): ~111,000
# With Permit (1 tx): ~85,000
# Savings: ~26,000 gas (23%)
```

## 9. Learning Path

1. **Read the README.md** - Understand EIP-2612 and why it matters
2. **Study Project19** - Learn about EIP-712 signatures (prerequisite)
3. **Review the Solution** - See how permit is implemented
4. **Run the Tests** - See permit in action
5. **Implement the Skeleton** - Practice implementing permit
6. **Compare Gas** - Understand the savings
7. **Integrate in Your Project** - Use ERC20Permit in your tokens

## 10. Common Issues

### Issue: "Invalid signature" error

**Solution**: Make sure you're using the correct:
- Nonce (call `token.nonces(owner)`)
- Deadline (future timestamp)
- Domain separator (from the correct token)
- Signature (v, r, s components)

### Issue: "Expired deadline" error

**Solution**: Set deadline in the future:
```solidity
uint256 deadline = block.timestamp + 1 hours;
```

### Issue: Signature works in tests but not in production

**Solution**: Check chain ID - domain separator includes `block.chainid`:
```solidity
// Make sure you're on the right network
require(block.chainid == expectedChainId);
```

## 11. Next Steps

- **Integrate with DeFi protocols**: Use permit in Uniswap-style routers
- **Build meta-transaction relayers**: Enable gasless transactions
- **Study Permit2**: Learn about Uniswap's universal permit
- **Implement EIP-4494**: NFT permit extension

## 12. Resources

- [EIP-2612 Specification](https://eips.ethereum.org/EIPS/eip-2612)
- [EIP-712 Specification](https://eips.ethereum.org/EIPS/eip-712)
- [OpenZeppelin ERC20Permit](https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#ERC20Permit)
- [Uniswap Permit2](https://github.com/Uniswap/permit2)

## Questions?

Review:
- `README.md` - Comprehensive guide
- `src/solution/Project23Solution.sol` - Detailed comments
- `test/Project23.t.sol` - Example usage
- `script/DeployProject23.s.sol` - Deployment examples

Happy coding! 🚀
