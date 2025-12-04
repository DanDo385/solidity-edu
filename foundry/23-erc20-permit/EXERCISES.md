# Project 23 Exercises: ERC-20 Permit (EIP-2612)

Complete these exercises to master gasless token approvals and EIP-712 signatures.

## Setup

```bash
cd /home/user/solidity-edu
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge build
```

## Part 1: Understanding Permit (30 minutes)

### Exercise 1.1: Read and Analyze

1. Read the full README.md
2. Answer these questions in your own words:
   - What problem does EIP-2612 solve?
   - How does permit save gas?
   - What is a domain separator and why is it needed?
   - What prevents permit signatures from being replayed?

### Exercise 1.2: Explore the Solution

1. Open `src/solution/Project23Solution.sol`
2. Find and understand:
   - Where the domain separator is computed
   - How the permit function verifies signatures
   - Why nonces are incremented BEFORE approval
   - The difference between Project23Solution and Project23CustomImplementation

### Exercise 1.3: Run the Tests

```bash
# Run all tests
forge test --match-path 23-erc20-permit/test/Project23.t.sol -vv

# Run with gas reporting
forge test --match-path 23-erc20-permit/test/Project23.t.sol --gas-report

# Study the output and note:
# - Which tests pass/fail
# - Gas costs for approve vs permit
# - How signatures are created in tests
```

## Part 2: Implement the Skeleton (1 hour)

### Exercise 2.1: Domain Separator

Open `src/Project23.sol` and implement the constructor:

```solidity
constructor() ERC20(_NAME, "PMT") {
    // TODO: Compute the domain separator
    // Hint: keccak256(abi.encode(...))
    _DOMAIN_SEPARATOR = ???;

    _mint(msg.sender, 1_000_000 * 10 ** decimals());
}
```

**Requirements:**
- Use `_DOMAIN_TYPEHASH`, `_NAME`, `_VERSION`, `block.chainid`, and `address(this)`
- Hash all string values before encoding
- Store result in `_DOMAIN_SEPARATOR`

**Test:**
```bash
forge test --match-test testDomainSeparator -vv
```

### Exercise 2.2: Nonce Management

Implement the nonce functions:

```solidity
function nonces(address owner) public view virtual returns (uint256) {
    // TODO: Return the nonce for owner
    return ???;
}

function _useNonce(address owner) internal virtual returns (uint256 current) {
    // TODO: Get current nonce, increment it, return old value
    current = ???;
    ??? = current + 1;
}
```

**Test:**
```bash
forge test --match-test testPermitNonceIncrement -vv
```

### Exercise 2.3: EIP-712 Hashing

Implement the typed data hash function:

```solidity
function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32 digest) {
    // TODO: Create EIP-712 compliant digest
    // Format: keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash))
    return ???;
}
```

**Test:**
```bash
forge test --match-test testPermitSignature -vv
```

### Exercise 2.4: Permit Function

Implement the complete permit function:

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
    // TODO: Step 1 - Check deadline
    require(???, "Expired");

    // TODO: Step 2 - Get and increment nonce
    uint256 nonce = ???;

    // TODO: Step 3 - Create struct hash
    bytes32 structHash = keccak256(abi.encode(
        PERMIT_TYPEHASH,
        ???
    ));

    // TODO: Step 4 - Create digest
    bytes32 digest = ???;

    // TODO: Step 5 - Recover signer
    address signer = ECDSA.recover(???, ???, ???, ???);

    // TODO: Step 6 - Verify signer
    require(???, "Invalid signature");

    // TODO: Step 7 - Set approval
    ???;
}
```

**Test:**
```bash
forge test --match-path 23-erc20-permit/test/Project23.t.sol -vv
```

### Exercise 2.5: DOMAIN_SEPARATOR Function

Implement the public getter:

```solidity
function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
    // TODO: Return the cached domain separator
    return ???;
}
```

**Verification:**
All tests should now pass!

```bash
forge test --match-path 23-erc20-permit/test/Project23.t.sol -vv
```

## Part 3: Gas Analysis (30 minutes)

### Exercise 3.1: Measure Gas Costs

Run the gas comparison tests:

```bash
forge test --match-test testGasComparison -vvv
```

Record the results:
- `approve()` gas cost: _______
- `permit()` gas cost: _______
- Traditional flow (approve + transferFrom): _______
- Permit flow (permit + transferFrom): _______
- Gas savings: _______
- Percentage saved: _______%

### Exercise 3.2: Understand the Savings

Answer:
1. Why does permit cost similar gas to approve?
2. Where do the gas savings come from?
3. In what scenarios would permit save the MOST gas?
4. Are there scenarios where permit might cost MORE?

### Exercise 3.3: Integrated Permit

Study `PermitHelper.transferWithPermit()` in the solution.

Create your own integrated function:

```solidity
contract MyDEX {
    function swapWithPermit(
        IERC20Permit token,
        address owner,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline,
        uint8 v, bytes32 r, bytes32 s
    ) external {
        // TODO: Apply permit
        ???

        // TODO: Execute swap
        ???
    }
}
```

## Part 4: Security Testing (45 minutes)

### Exercise 4.1: Replay Attack

Try to replay a permit signature:

```solidity
function testReplayAttack() public {
    // Create permit
    (uint8 v, bytes32 r, bytes32 s) = createPermitSignature(...);

    // Use once - should work
    token.permit(...);

    // Try to use again - should fail
    vm.expectRevert("???");
    token.permit(...);
}
```

**Question:** What prevents the replay?

### Exercise 4.2: Expired Deadline

Test deadline enforcement:

```solidity
function testExpiredDeadline() public {
    uint256 deadline = block.timestamp + 1 hours;
    (uint8 v, bytes32 r, bytes32 s) = createPermitSignature(..., deadline);

    // TODO: Fast forward past deadline
    vm.warp(???);

    // TODO: Try to use permit - should fail
    ???
}
```

### Exercise 4.3: Wrong Signer

Test signature verification:

```solidity
function testWrongSigner() public {
    // Bob signs a permit claiming to be Alice
    (uint8 v, bytes32 r, bytes32 s) = signPermitAs(bob, bobKey, ...);

    // TODO: Try to use as Alice - should fail
    vm.expectRevert("???");
    token.permit(alice, ...);
}
```

### Exercise 4.4: Cross-Token Attack

Test domain separation:

```solidity
function testCrossTokenAttack() public {
    // Deploy two tokens
    Project23Solution token1 = new Project23Solution();
    Project23Solution token2 = new Project23Solution();

    // Create permit for token1
    (uint8 v, bytes32 r, bytes32 s) = signPermitFor(token1, ...);

    // TODO: Try to use on token2 - should fail
    ???
}
```

**Question:** What prevents cross-token attacks?

## Part 5: Real-World Integration (1 hour)

### Exercise 5.1: Build a DEX Router

Create a simple DEX that uses permit:

```solidity
contract SimpleDEX {
    struct Pool {
        uint256 tokenA;
        uint256 tokenB;
    }

    Pool public pool;

    function swapAforBWithPermit(
        IERC20Permit tokenA,
        uint256 amountIn,
        uint256 deadline,
        uint8 v, bytes32 r, bytes32 s
    ) external returns (uint256 amountOut) {
        // TODO: 1. Apply permit
        // TODO: 2. Transfer tokens in
        // TODO: 3. Calculate amountOut
        // TODO: 4. Transfer tokens out
    }
}
```

### Exercise 5.2: Build a Staking Contract

Create a staking contract that accepts permits:

```solidity
contract Staking {
    mapping(address => uint256) public stakedBalance;

    function stakeWithPermit(
        IERC20Permit token,
        uint256 amount,
        uint256 deadline,
        uint8 v, bytes32 r, bytes32 s
    ) external {
        // TODO: Implement permit-based staking
    }
}
```

### Exercise 5.3: Build an Airdrop Contract

Create an airdrop that uses permits from recipients:

```solidity
contract Airdrop {
    IERC20Permit public token;

    function claimWithPermit(
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint256 deadline,
        uint8 v, bytes32 r, bytes32 s
    ) external {
        // TODO: Verify merkle proof
        // TODO: Use permit to allow contract to transfer
        // TODO: Transfer tokens to claimer
    }
}
```

## Part 6: Advanced Topics (1 hour)

### Exercise 6.1: Implement DAI-Style Permit

DAI uses a different permit interface. Implement it:

```solidity
function permit(
    address holder,
    address spender,
    uint256 nonce,      // Different position!
    uint256 expiry,
    bool allowed,       // Boolean instead of amount!
    uint8 v, bytes32 r, bytes32 s
) external {
    // TODO: Implement DAI-style permit
}
```

### Exercise 6.2: Add Permit with Signature Helper

Create a helper function that accepts signature as bytes:

```solidity
function permitWithSignature(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    bytes calldata signature
) external {
    // TODO: Split signature into v, r, s
    // TODO: Call permit
}
```

### Exercise 6.3: Implement Batch Permits

Allow multiple permits in one transaction:

```solidity
struct PermitData {
    address owner;
    address spender;
    uint256 value;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
}

function batchPermit(PermitData[] calldata permits) external {
    // TODO: Execute multiple permits
}
```

### Exercise 6.4: Off-Chain Signature Creation

Write a script to create permit signatures off-chain:

```typescript
// In TypeScript
async function createPermitSignature(
    token: any,
    owner: string,
    spender: string,
    value: bigint,
    deadline: number
): Promise<{ v: number; r: string; s: string }> {
    // TODO: Get domain separator
    // TODO: Get nonce
    // TODO: Create EIP-712 signature
    // TODO: Return v, r, s
}
```

## Part 7: Testing & Optimization (30 minutes)

### Exercise 7.1: Fuzz Testing

Add fuzz tests for permit:

```solidity
function testFuzzPermitAmount(uint256 amount) public {
    // TODO: Bound amount to reasonable range
    // TODO: Create and execute permit
    // TODO: Verify approval
}

function testFuzzPermitDeadline(uint256 deadline) public {
    // TODO: Bound deadline to future values
    // TODO: Create and execute permit
    // TODO: Verify it works
}
```

### Exercise 7.2: Gas Optimization

Optimize the custom implementation:

1. Can you reduce gas in `_useNonce()`?
2. Should domain separator be cached or computed?
3. When should you use `immutable` vs `constant`?

### Exercise 7.3: Invariant Testing

Write invariant tests:

```solidity
function invariant_nonceAlwaysIncreases() public {
    // TODO: Nonces should only increase
}

function invariant_validPermitAlwaysWorks() public {
    // TODO: Valid signatures should always work before deadline
}
```

## Bonus Challenges

### Challenge 1: Implement EIP-4494

Implement permit for ERC-721 NFTs.

### Challenge 2: Build Permit2 Clone

Study and implement a simplified version of Uniswap's Permit2.

### Challenge 3: Meta-Transaction Relayer

Build a relayer that executes permits on behalf of users.

### Challenge 4: Permit Analytics Dashboard

Create a tool to analyze permit usage across tokens.

## Solutions

Solutions are provided in:
- `src/solution/Project23Solution.sol` - Complete implementations
- `test/Project23.t.sol` - Comprehensive tests
- `script/DeployProject23.s.sol` - Deployment examples

## Verification Checklist

- [ ] All tests pass
- [ ] Gas costs are reasonable
- [ ] Security tests prevent attacks
- [ ] Domain separator is unique
- [ ] Nonces prevent replay
- [ ] Deadlines are enforced
- [ ] Signatures verify correctly
- [ ] Integration works with helpers

## Next Steps

After completing these exercises:

1. Review [EIP-2612 specification](https://eips.ethereum.org/EIPS/eip-2612)
2. Study [OpenZeppelin's implementation](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC20Permit.sol)
3. Explore [Uniswap's Permit2](https://github.com/Uniswap/permit2)
4. Integrate permit into your own tokens
5. Build protocols that leverage permit for better UX

Good luck! 🚀
