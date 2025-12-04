# Project 04: Modifiers & Access Control 🔐

> **Implement custom modifiers and access control patterns**

## 🎯 Learning Objectives

By completing this project, you will:

1. **Create custom function modifiers** from scratch
2. **Implement `onlyOwner` pattern** for access control
3. **Understand role-based access control (RBAC)** with nested mappings
4. **Compare DIY vs OpenZeppelin AccessControl** patterns
5. **Learn modifier execution order** and composition
6. **See how access control choices affect** upgradeability, L2 fee profiles, and incident response
7. **Create Foundry deployment scripts** with access control setup
8. **Write comprehensive test suites** for access control scenarios

## 📁 Project Directory Structure

### Understanding Foundry Project Structure

This project follows the same structure as Project 01:

```
04-modifiers-and-restrictions/
├── src/
│   ├── ModifiersRestrictions.sol          # Skeleton contract (your implementation)
│   └── solution/
│       └── ModifiersRestrictionsSolution.sol  # Reference solution
├── script/
│   ├── DeployModifiersRestrictions.s.sol  # Skeleton deployment script (your implementation)
│   └── solution/
│       └── DeployModifiersRestrictionsSolution.s.sol  # Reference solution
├── test/
│   ├── ModifiersRestrictions.t.sol        # Skeleton test suite (your implementation)
│   └── solution/
│       └── ModifiersRestrictionsSolution.t.sol  # Reference solution
├── foundry.toml                           # Foundry configuration
└── README.md                              # This file
```

**Key directories**:
- `src/`: Your contract implementations
- `script/`: Deployment scripts
- `test/`: Test suites
- `solution/`: Reference implementations (study these after completing your own!)

## 📚 Key Concepts

### Function Modifiers

Modifiers are reusable checks that run before/after function execution:

```solidity
modifier onlyOwner() {
    require(msg.sender == owner, "Not owner");
    _;  // This is where the function body executes
}

function transferOwnership(address newOwner) public onlyOwner {
    owner = newOwner;
}
```

**Real-world analogy**: Modifiers are like security checkpoints. Before you can enter a restricted area (function), you must pass through the checkpoint (modifier) that verifies your credentials (role, ownership, etc.).

**Why use modifiers?**:
- **Code reuse**: Write the check once, use it everywhere
- **Cleaner syntax**: `onlyOwner` is more readable than inline `require()`
- **Consistency**: Same check logic across all functions
- **Gas efficiency**: Modifiers compile to internal functions, optimizer can inline them

**Gas cost**: ~5 gas overhead per modifier (negligible compared to storage operations)

### Modifier Execution Order

Modifiers execute in the order they're declared:

```solidity
function example() public modifierA modifierB {
    // Execution: modifierA → modifierB → function body
}
```

**Fun fact**: Modifiers are compiled into internal functions. Solc can inline simple modifiers, so a clean `onlyOwner` often costs only a couple of `JUMPI` opcodes in bytecode.

**Real-world analogy**: Like needing both a boarding pass AND an ID to board a plane - you must pass both checks in order.

### Role-Based Access Control (RBAC)

RBAC uses roles instead of simple ownership:

```solidity
mapping(address => mapping(bytes32 => bool)) public roles;

bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

modifier onlyRole(bytes32 role) {
    require(roles[msg.sender][role], "Missing role");
    _;
}
```

**Why `bytes32` for roles?**:
- Gas-efficient: Single storage slot lookup
- Deterministic: `keccak256("ADMIN_ROLE")` always produces same hash
- Flexible: Can add new roles without changing contract structure

**Real-world analogy**: Like a company with different departments - employees have different roles (admin, manager, employee), and each role has different permissions.

**Connection to Project 01**: This uses nested mappings! `mapping(address => mapping(bytes32 => bool))` is a mapping of mappings.

### Pause Mechanism

Emergency stop pattern for contracts:

```solidity
bool public paused;

modifier whenNotPaused() {
    require(!paused, "Contract paused");
    _;
}

function pause() public onlyOwner {
    paused = true;
}
```

**Why pause?**:
- Emergency response: Stop operations if bug is discovered
- Security: Prevent further damage while fixing issues
- Governance: Allows controlled shutdown

**Real-world analogy**: Like a fire alarm - when activated, all operations stop immediately for safety.

**Connection to Project 02**: Pause checks follow the Checks-Effects-Interactions pattern!

### Modifier Composition

You can chain multiple modifiers:

```solidity
function mint(address to) public onlyRole(MINTER_ROLE) whenNotPaused {
    // Must have MINTER_ROLE AND contract must not be paused
}
```

**Execution order**: Modifiers execute left-to-right, then function body executes.

**Gas consideration**: Each modifier adds ~5 gas overhead. Keep modifiers simple!

**Best practice**: Put cheaper checks first (like `whenNotPaused`) before expensive checks (like role lookups).

## 🔧 What You'll Build

A contract demonstrating:
- Custom modifiers with parameters (`onlyRole(bytes32)`)
- Owner-based access control (`onlyOwner`)
- Role management system (grant/revoke roles)
- Modifier composition and chaining
- Pause mechanism for emergency stops
- Checks-effects-interactions ordering inside modifiers

Plus:
- **Deployment script** that sets up initial roles
- **Comprehensive test suite** covering all access control scenarios

## 📝 Tasks

### Task 1: Implement Custom Modifiers

Open `src/ModifiersRestrictions.sol` and implement:

1. **`onlyOwner` modifier**: Checks `msg.sender == owner`
2. **`onlyRole(bytes32 role)` modifier**: Checks `roles[msg.sender][role]`
3. **`whenNotPaused` modifier**: Checks `!paused`
4. **`whenPaused` modifier**: Checks `paused` (for unpause function)

**Hints**:
- Use `require()` statements for checks
- Use `_;` to indicate where function body executes
- Remember: modifiers execute BEFORE the function body

### Task 2: Implement Access Control Functions

Implement functions that use your modifiers:

1. **`transferOwnership(address newOwner)`**: Uses `onlyOwner`
2. **`grantRole(bytes32 role, address account)`**: Uses `onlyOwner`
3. **`revokeRole(bytes32 role, address account)`**: Uses `onlyOwner`
4. **`pause()`**: Uses `onlyRole(ADMIN_ROLE)`
5. **`unpause()`**: Uses `onlyRole(ADMIN_ROLE)` and `whenPaused`
6. **`incrementCounter()`**: Uses `whenNotPaused`
7. **`mint(address to)`**: Uses `onlyRole(MINTER_ROLE)` and `whenNotPaused`

### Task 3: Create Your Deployment Script

Open `script/DeployModifiersRestrictions.s.sol` and implement:

1. Read deployer's private key from environment using `vm.envOr()`
2. Start broadcasting transactions with `vm.startBroadcast()`
3. Deploy the contract
4. Log deployment information (address, owner, initial roles)
5. (Optional) Grant roles to test addresses
6. Stop broadcasting with `vm.stopBroadcast()`

**Why deployment scripts?** Access control contracts need proper setup - deployment scripts ensure roles are configured correctly.

### Task 4: Write Your Test Suite

Open `test/ModifiersRestrictions.t.sol` and write comprehensive tests:

1. **Constructor tests**: Verify owner and initial roles are set correctly
2. **`onlyOwner` tests**: Verify only owner can call owner-only functions
3. **`onlyRole` tests**: Verify only users with role can call role-gated functions
4. **Role management tests**: Grant/revoke roles, verify changes
5. **Pause tests**: Pause/unpause, verify operations are blocked/allowed
6. **Modifier composition tests**: Verify functions with multiple modifiers work correctly
7. **Edge cases**: Zero address, invalid roles, already granted/revoked roles
8. **Event tests**: Verify events are emitted correctly

**Testing Best Practices**:
- Use `vm.prank()` to simulate different callers
- Use `vm.expectRevert()` for access control failures
- Use descriptive test names: `test_OnlyOwner_RevertsForNonOwner`
- Follow Arrange-Act-Assert pattern

### Task 5: Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/ModifiersRestrictionsSolution.sol` - Reference contract implementation
- `script/solution/DeployModifiersRestrictionsSolution.s.sol` - Deployment script patterns
- `test/solution/ModifiersRestrictionsSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

### Task 6: Compile and Test

```bash
cd 04-modifiers-and-restrictions

# Compile contracts
forge build

# Run all tests
forge test

# Run with verbose output
forge test -vvv

# Run with gas reporting
forge test --gas-report

# Run specific test
forge test --match-test test_OnlyOwner
```

### Task 7: Deploy Locally

**⚠️ IMPORTANT: This project runs on LOCAL ANVIL ONLY**

```bash
# Terminal 1: Start Anvil (keep this running)
anvil

# Terminal 2: Deploy
cd 04-modifiers-and-restrictions

# Dry run (simulation only)
forge script script/DeployModifiersRestrictions.s.sol

# Deploy to local Anvil (with transactions)
forge script script/DeployModifiersRestrictions.s.sol \
  --broadcast \
  --rpc-url http://localhost:8545
```

### Task 8: Experiment

Try these experiments:
1. Change modifier order - does it affect gas costs?
2. Add a modifier that checks multiple conditions - how does gas change?
3. Compare gas costs: inline `require()` vs modifier
4. Test with multiple roles - verify role combinations work correctly
5. Test pause/unpause flow - verify state transitions

## 🧪 Test Coverage

The test suite covers:

- ✅ Constructor behavior and initial state
- ✅ Owner-only functions (transferOwnership)
- ✅ Role-based functions (grantRole, revokeRole, pause, unpause)
- ✅ Modifier composition (multiple modifiers on one function)
- ✅ Pause mechanism (pause/unpause, operations blocked/allowed)
- ✅ Edge cases (zero address, invalid roles, already granted/revoked)
- ✅ Event emissions verification
- ✅ Access control failures (wrong caller, missing role, paused contract)
- ✅ Gas benchmarking

## 🛰️ Real-World Analogies & Fun Facts

- **Bouncer at a club**: `onlyOwner` is the bouncer checking IDs before anyone enters the function. Stacking modifiers is like needing both a ticket and a VIP wristband.

- **Compiler trivia**: Modifiers are syntactic sugar. Solc desugars them into internal calls, which the optimizer can inline, so keeping modifiers short often reduces gas.

- **Layer 2 tie-in**: Pausing contracts on L2 during incidents prevents costly dispute windows on L1. Cheap role checks (packed `bytes32` roles) make multi-sig admin actions more affordable across chains.

- **ETH inflation risk**: Overly permissive write functions can bloat state. Tight modifiers help limit who can create new storage, indirectly reducing long-term state growth pressure on validator hardware (and issuance).

- **Design history**: Access control libraries evolved after early hacks (e.g., Parity multisig). Clear modifiers make audits and incident response faster.

- **OpenZeppelin patterns**: OpenZeppelin's `Ownable` and `AccessControl` contracts use similar patterns. Learning these fundamentals helps you understand production-grade code.

- **Security importance**: Most hacks involve access control failures. Understanding modifiers deeply is critical for secure smart contract development.

- **DAO fork lesson**: The DAO fork highlighted the need for clear access control. Proper modifiers make it clear who can do what, preventing confusion during incidents.

## ✅ Completion Checklist

- [ ] Implemented custom modifiers (`onlyOwner`, `onlyRole`, `whenNotPaused`, `whenPaused`)
- [ ] Implemented access control functions (transferOwnership, grantRole, revokeRole, pause, unpause)
- [ ] Created deployment script (`script/DeployModifiersRestrictions.s.sol`)
- [ ] Wrote comprehensive test suite (`test/ModifiersRestrictions.t.sol`)
- [ ] All tests pass (`forge test`)
- [ ] Deployment script works locally (`forge script --broadcast`)
- [ ] Read and understood solution contract (`src/solution/`)
- [ ] Read and understood solution script (`script/solution/`)
- [ ] Read and understood solution tests (`test/solution/`)
- [ ] Compared gas costs (`forge test --gas-report`)
- [ ] Experimented with modifier composition
- [ ] Can explain modifier execution order
- [ ] Understands role-based access control patterns
- [ ] Understands pause mechanism and emergency stops

## 🚀 Next Steps

Once comfortable with modifiers and access control:

- Move to [Project 05: Errors & Reverts](../05-errors-and-reverts/)
- Study OpenZeppelin access control contracts (`Ownable.sol`, `AccessControl.sol`)
- Implement time-locked operations (add delays to critical functions)
- Consider how ownership transfers behaved during the Ethereum Classic split
- Learn about multi-sig wallets and their access control patterns
- Explore upgradeable proxy patterns and their access control implications

## 💡 Pro Tips

1. **Always validate inputs in modifiers**: Check for zero address, invalid roles, etc.
2. **Keep modifiers simple**: Complex logic in modifiers is harder to audit
3. **Use events**: Emit events when roles change (helps with off-chain tracking)
4. **Test access control thoroughly**: Most bugs are access control related
5. **Document modifier behavior**: Comments help auditors understand intent
6. **Consider gas costs**: Each modifier adds overhead - don't overuse
7. **Use constants for roles**: `keccak256("ADMIN_ROLE")` is deterministic
8. **Follow Checks-Effects-Interactions**: Even in modifiers!
9. **Test edge cases**: Zero address, already granted roles, etc.
10. **Study OpenZeppelin**: Their patterns are battle-tested

---

**Ready to code?** Start with `src/ModifiersRestrictions.sol`, then create your deployment script and test suite! Remember: access control is critical for security - take your time and test thoroughly! 🔐
