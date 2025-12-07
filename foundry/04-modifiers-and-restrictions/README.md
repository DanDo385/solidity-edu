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

### Function Modifiers: Reusable Access Control Patterns

**FIRST PRINCIPLES: The Decorator Pattern**

Modifiers are reusable checks that run before/after function execution. They implement the decorator pattern - wrapping functions with additional behavior without modifying the function itself.

**UNDERSTANDING THE SYNTAX**:

```solidity
modifier onlyOwner() {
    require(msg.sender == owner, "Not owner");
    _;  // This is where the function body executes
}

function transferOwnership(address newOwner) public onlyOwner {
    owner = newOwner;
}
```

**HOW MODIFIERS WORK**:

```
Function Call Flow:
┌─────────────────────────────────────────┐
│ transferOwnership(newOwner) called     │
│   ↓                                      │
│ onlyOwner modifier executes             │ ← Check: msg.sender == owner?
│   ↓                                      │
│ If check passes: Continue               │
│ If check fails: REVERT                  │ ← Access denied!
│   ↓                                      │
│ Function body executes at _             │ ← Only if check passed
│   ↓                                      │
│ owner = newOwner;                       │ ← Function logic
└─────────────────────────────────────────┘
```

**CONNECTION TO PROJECT 01 & 02**:
- **Project 01**: We learned about storage and mappings
- **Project 02**: We learned about `require()` statements for validation
- **Project 04**: Modifiers combine these concepts - they use `require()` to check conditions before allowing function execution

**WHY USE MODIFIERS?**:

1. **Code Reuse (DRY Principle)**:
   ```solidity
   // ❌ WITHOUT modifiers: Repetitive code
   function transferOwnership(address newOwner) public {
       require(msg.sender == owner, "Not owner");
       owner = newOwner;
   }
   
   function pause() public {
       require(msg.sender == owner, "Not owner");
       paused = true;
   }
   
   // ✅ WITH modifiers: Write once, use everywhere
   modifier onlyOwner() {
       require(msg.sender == owner, "Not owner");
       _;
   }
   
   function transferOwnership(address newOwner) public onlyOwner {
       owner = newOwner;
   }
   
   function pause() public onlyOwner {
       paused = true;
   }
   ```

2. **Cleaner Syntax**: `onlyOwner` is more readable than inline `require()`
3. **Consistency**: Same check logic across all functions (prevents bugs)
4. **Gas Efficiency**: Modifiers compile to internal functions, optimizer can inline them

**GAS COST BREAKDOWN**:

**Modifier Overhead**:
- Base modifier call: ~5 gas (JUMP operation)
- `require()` check: ~3 gas (if passes)
- Total: ~8 gas per modifier (negligible compared to storage operations)

**Comparison**:
- **Inline require**: ~3 gas
- **Modifier**: ~8 gas
- **Difference**: ~5 gas (negligible, but modifiers are cleaner)

**COMPARISON TO RUST**:

**Rust** (similar concept with attribute macros):
```rust
#[only_owner]
fn transfer_ownership(new_owner: Address) {
    // Function body
}
```

**Solidity** (built-in language feature):
```solidity
function transferOwnership(address newOwner) public onlyOwner {
    // Function body
}
```

Both implement the decorator pattern, but Solidity's modifiers are built into the language, while Rust uses macros.

**REAL-WORLD ANALOGY**: 
Modifiers are like security checkpoints. Before you can enter a restricted area (function), you must pass through the checkpoint (modifier) that verifies your credentials (role, ownership, etc.). If you don't have the right credentials, you're denied access (revert).

**COMPILER OPTIMIZATION**:

Modifiers are compiled into internal functions. The Solidity optimizer can inline simple modifiers, so a clean `onlyOwner` often costs only a couple of `JUMPI` opcodes in bytecode. This means modifiers are both clean AND efficient!

### Modifier Execution Order

Modifiers execute in the order they're declared:

```solidity
function example() public modifierA modifierB {
    // Execution: modifierA → modifierB → function body
}
```

**Fun fact**: Modifiers are compiled into internal functions. Solc can inline simple modifiers, so a clean `onlyOwner` often costs only a couple of `JUMPI` opcodes in bytecode.

**Real-world analogy**: Like needing both a boarding pass AND an ID to board a plane - you must pass both checks in order.

### Role-Based Access Control (RBAC): Flexible Permission Systems

**FIRST PRINCIPLES: Beyond Simple Ownership**

RBAC uses roles instead of simple ownership, allowing fine-grained access control. This is a fundamental design pattern in access control systems.

**UNDERSTANDING THE STRUCTURE**:

```solidity
mapping(address => mapping(bytes32 => bool)) public roles;

bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

modifier onlyRole(bytes32 role) {
    require(roles[msg.sender][role], "Missing role");
    _;
}
```

**HOW RBAC WORKS**:

```
Role Assignment:
┌─────────────────────────────────────────┐
│ grantRole(ADMIN_ROLE, alice)            │
│   ↓                                      │
│ roles[alice][ADMIN_ROLE] = true         │ ← Storage write
│   ↓                                      │
│ Alice can now call admin functions      │
└─────────────────────────────────────────┘

Role Check:
┌─────────────────────────────────────────┐
│ pause() called by alice                 │
│   ↓                                      │
│ onlyRole(ADMIN_ROLE) modifier executes  │
│   ↓                                      │
│ Check: roles[alice][ADMIN_ROLE] == true?│ ← Storage read
│   ↓                                      │
│ If true: Continue                       │
│ If false: REVERT                        │
└─────────────────────────────────────────┘
```

**CONNECTION TO PROJECT 01**: 
This uses **nested mappings**! `mapping(address => mapping(bytes32 => bool))` is a mapping of mappings:
- Outer mapping: address → (inner mapping)
- Inner mapping: bytes32 role → bool (has role?)

**Storage Layout** (from Project 01 knowledge):
For account `0x1234...` and role `ADMIN_ROLE`:
```
Storage slot = keccak256(abi.encodePacked(
    keccak256(abi.encodePacked(0x1234..., slot_number)),
    ADMIN_ROLE
))
```

**GAS COST BREAKDOWN**:

**Role Check**:
- SLOAD from nested mapping: ~100 gas (warm) or ~2,100 gas (cold)
- require() check: ~3 gas (if passes)
- Total: ~103 gas (warm) or ~2,103 gas (cold)

**Role Grant**:
- SSTORE to nested mapping: ~5,000 gas (warm) or ~20,000 gas (cold)
- Event emission: ~2,000 gas
- Total: ~7,000 gas (warm) or ~22,000 gas (cold)

**WHY `bytes32` FOR ROLES?**:

1. **Gas-Efficient**: Single storage slot lookup (32 bytes fits in one slot)
2. **Deterministic**: `keccak256("ADMIN_ROLE")` always produces same hash
3. **Flexible**: Can add new roles without changing contract structure
4. **Collision-Resistant**: keccak256 prevents role name collisions

**Alternative Approaches**:

**Option 1: Enum** (Less Flexible):
```solidity
enum Role { NONE, ADMIN, MINTER }
mapping(address => Role) public roles;
// ❌ Problem: Can't add new roles without redeploying
```

**Option 2: String** (Expensive):
```solidity
mapping(address => mapping(string => bool)) public roles;
// ❌ Problem: String storage is expensive (~20k gas)
```

**Option 3: bytes32** (Best):
```solidity
mapping(address => mapping(bytes32 => bool)) public roles;
// ✅ Problem: Gas-efficient, flexible, deterministic
```

**COMPARISON TO RUST** (DSA Concept):

**Rust** (similar pattern with HashMap):
```rust
use std::collections::HashMap;

struct AccessControl {
    roles: HashMap<Address, HashSet<Role>>,
}

impl AccessControl {
    fn has_role(&self, account: Address, role: Role) -> bool {
        self.roles.get(&account)
            .map(|roles| roles.contains(&role))
            .unwrap_or(false)
    }
}
```

**Solidity** (nested mapping):
```solidity
mapping(address => mapping(bytes32 => bool)) public roles;

function hasRole(address account, bytes32 role) public view returns (bool) {
    return roles[account][role];
}
```

Both use hash-based data structures (HashMap in Rust, mapping in Solidity) for O(1) lookup, but Solidity's nested mapping is more gas-efficient for this use case.

**REAL-WORLD ANALOGY**: 
Like a company with different departments - employees have different roles (admin, manager, employee), and each role has different permissions. The roles mapping is like an employee directory that tracks who has which permissions.

**PRINCIPLE OF LEAST PRIVILEGE**:

RBAC enables the principle of least privilege - users only get the minimum permissions they need:
- **Admin**: Can pause/unpause (emergency control)
- **Minter**: Can mint tokens (limited operation)
- **User**: Can only interact with public functions

This reduces attack surface - if a minter's key is compromised, they can't pause the contract!

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

## 🔍 Contract Walkthrough (Solution Highlights)

- **State + role scaffolding**: `owner`, `paused`, and `counter` sit beside the nested `roles[address][role]` mapping so you can trace every storage write from Projects 01–03. The constructor seeds both `ADMIN_ROLE` and `MINTER_ROLE` for the deployer, so your tests start with one known admin/minter without extra setup.
- **Modifier library**: `onlyOwner`, `onlyRole`, `whenNotPaused`, and `whenPaused` are intentionally tiny—just a `require` each—so you can compose them freely. `transferOwnership` highlights the pattern of caching `owner` once before writing/ emitting, which saves a second SLOAD.
- **Role lifecycle**: `grantRole` / `revokeRole` guard against redundant writes, flip the nested mapping flag, and emit `RoleGranted`/`RoleRevoked` so explorers, bots, and dashboards stay in sync with on-chain authority changes.
- **Circuit breaker**: `pause` (only ADMIN) and `unpause` (ADMIN + `whenPaused`) let you exercise modifier order: role check → pause flag check → function body. Both fire events that double as incident-response alerts for monitoring systems.
- **Usage sites**: `incrementCounter` is the simple “business logic” hook you can call through different modifiers, `mint` demonstrates stacking role + pause guards before any external side effect, and `hasRole` rounds out the API so frontends can query permissions off-chain.

## ✅ Key Takeaways & Common Pitfalls

- Keep modifiers short and reusable; complex logic belongs inside functions where the compiler can better optimize ordering.
- Emit events for every ownership or role change—state alone cannot tell off-chain systems who is in control or when it changed.
- Cache storage reads you plan to reuse in the same function (e.g., old owner for an event) to avoid double `SLOAD`s when modifiers already do heavy lifting.
- Validate inputs inside gated functions (`newOwner != address(0)`, prevent duplicate role grants) to avoid soft-locking the contract or wasting gas on no-ops.
- Order modifiers by cost: cheap checks like `whenNotPaused` should run before nested mapping lookups performed in `onlyRole`.

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
