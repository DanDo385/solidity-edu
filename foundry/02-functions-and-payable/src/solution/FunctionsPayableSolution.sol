// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title FunctionsPayableSolution
 * @notice Complete reference implementation for functions, payable, and ETH handling
 * @dev This contract demonstrates:
 *      - Function visibility (public, external, internal, private)
 *      - The payable modifier
 *      - receive() and fallback() special functions
 *      - Safe ETH transfer patterns
 *      - Checks-Effects-Interactions pattern
 *
 * TPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPW
 * Q                        CONCEPTUAL OVERVIEW                                Q
 * ZPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP]
 *
 * SOLIDITY FUNCTIONS: More than just code blocks
 * PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
 * Unlike Python/JavaScript, Solidity functions can:
 *   1. Receive real monetary value (ETH)
 *   2. Cost gas to execute (computational cost)
 *   3. Permanently modify blockchain state
 *   4. Call other contracts (composability)
 *
 * COMPARISON TO OTHER LANGUAGES:
 * PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
 * Python:   def func(): pass  # Free to call, no money involved
 * Go:       func F() {}  # Also free, no built-in money
 * Rust:     fn func() {}  # No native money handling
 * Solidity: function func() public payable {}  # Costs gas, can receive ETH
 *
 * ETH HANDLING:
 * PPPPPPPPPPPP
 * ETH is the NATIVE currency (not a token contract)
 * - Tracked by EVM itself, not a contract
 * - Measured in wei (1 ETH = 10^18 wei)
 * - Can be sent to EOAs (Externally Owned Accounts) or contracts
 * - Contracts must explicitly accept ETH (via payable)
 *
 * SECURITY CRITICAL:
 * PPPPPPPPPPPPPPPPP
 * - Wrong ETH handling = permanent loss
 * - Reentrancy attacks via ETH sends
 * - Gas limits affect transfer success
 * - Smart contract wallets need sufficient gas
 */
contract FunctionsPayableSolution {
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // STATE VARIABLES
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    /**
     * @notice Contract owner (deployer)
     * @dev Used for access control in ownerWithdraw()
     *
     * 🏗️  OWNER PATTERN: The Foundation of Access Control
     * ════════════════════════════════════════════════════
     *
     *      The owner pattern is one of the most fundamental access control mechanisms
     *      in Solidity. It establishes who has privileged access to certain functions.
     *
     *      HOW IT WORKS:
     *      ┌─────────────────────────────────────────┐
     *      │ Constructor sets owner = msg.sender     │ ← Deployer becomes owner
     *      │   ↓                                      │
     *      │ Owner can call privileged functions      │ ← Access control check
     *      │   ↓                                      │
     *      │ Non-owners are rejected                  │ ← require(msg.sender == owner)
     *      └─────────────────────────────────────────┘
     *
     *      CONNECTION TO PROJECT 01:
     *      Remember how we learned about address types? The owner is stored as an
     *      address type (20 bytes) in slot 0. This is the same storage model we
     *      learned about - just storing an address value!
     *
     *      WHY OWNER PATTERN?
     *      - Common access control mechanism (used everywhere)
     *      - Allows privileged operations (withdrawals, upgrades, etc.)
     *      - Simple to understand and implement
     *      - Should be transferred to multi-sig in production (security best practice)
     *
     *      STORAGE LAYOUT:
     *      - Slot 0: owner (address, 20 bytes, uses full 32-byte slot)
     *      - Gas cost: ~20,000 gas (cold write) or ~5,000 gas (warm write)
     *
     *      SECURITY CONSIDERATIONS:
     *      ⚠️  Single owner = single point of failure
     *      ⚠️  If owner's private key is compromised, attacker has full control
     *      ⚠️  Consider OpenZeppelin Ownable or AccessControl for production
     *      ⚠️  Use multi-sig wallets for owner in production (Gnosis Safe, etc.)
     *
     *      REAL-WORLD ANALOGY:
     *      Like a bank vault - only the owner (bank manager) has the key.
     *      Everyone else is locked out. But if the key is stolen, the vault
     *      is compromised!
     *
     *      GAS COST:
     *      - Reading owner: ~100 gas (warm SLOAD)
     *      - Setting owner: ~20,000 gas (cold SSTORE) or ~5,000 gas (warm SSTORE)
     *
     *      🎓 LEARNING MOMENT:
     *      This is the same address type we learned about in Project 01!
     *      The owner is just an address stored in storage slot 0.
     *      Access control is just checking if msg.sender matches the stored address.
     */
    address public owner;

    /**
     * @notice Tracks deposited ETH for each address
     * @dev Maps address to balance in wei
     *
     * 💰 BALANCE TRACKING: The Core of Deposit/Withdraw Systems
     * ═══════════════════════════════════════════════════════════
     *
     *      This mapping is the heart of our deposit/withdraw system. It tracks
     *      how much ETH each user has deposited and can withdraw.
     *
     *      CONNECTION TO PROJECT 01:
     *      This is the EXACT same mapping type we learned about in Project 01!
     *      Remember: mappings use keccak256(key, slot) to calculate storage locations.
     *      For this mapping (slot 1), the storage slot for address 0x1234... is:
     *      keccak256(abi.encodePacked(0x1234..., 1))
     *
     *      HOW IT WORKS:
     *      ┌─────────────────────────────────────────┐
     *      │ User deposits 1 ETH                     │
     *      │   ↓                                      │
     *      │ balances[user] += 1 ether               │ ← Storage write
     *      │   ↓                                      │
     *      │ User withdraws 0.5 ETH                 │
     *      │   ↓                                      │
     *      │ balances[user] -= 0.5 ether            │ ← Storage write
     *      │   ↓                                      │
     *      │ User checks balance                     │
     *      │   ↓                                      │
     *      │ balances[user] returns 0.5 ether        │ ← Storage read
     *      └─────────────────────────────────────────┘
     *
     *      STORAGE CALCULATION:
     *      For address 0xABCD...:
     *      - Storage slot = keccak256(abi.encodePacked(0xABCD..., 1))
     *      - This is the same calculation we learned in Project 01!
     *
     *      WHY TRACK BALANCES?
     *      - Allows users to deposit and withdraw individually
     *      - Provides accountability (who deposited what)
     *      - Enables pull-over-push withdrawal pattern
     *      - Separates user funds from contract funds
     *
     *      IMPORTANT DISTINCTION:
     *      - address(this).balance = contract's TOTAL ETH (all sources)
     *      - balances[addr] = tracked portion (only deposits via deposit())
     *      - Contract can have ETH not tracked in balances (via receive/fallback)
     *
     *      EXAMPLE:
     *      ```
     *      Contract receives:
     *      - 1 ETH via deposit() → balances[alice] = 1 ether
     *      - 0.5 ETH via receive() → balances[alice] = 1 ether (unchanged!)
     *      - address(this).balance = 1.5 ether (total)
     *      ```
     *
     *      GAS COSTS (from Project 01):
     *      - Cold read: ~2,100 gas (first access)
     *      - Warm read: ~100 gas (subsequent reads)
     *      - Cold write: ~20,000 gas (first write)
     *      - Warm write: ~5,000 gas (subsequent writes)
     *
     *      REAL-WORLD ANALOGY:
     *      Like a bank account ledger - it tracks how much each customer
     *      has deposited. The bank's total cash (address(this).balance) might
     *      be more than the sum of all customer balances (donations, fees, etc.).
     *
     *      🎓 LEARNING MOMENT:
     *      This mapping uses the EXACT same storage model we learned in Project 01!
     *      The storage slot calculation, gas costs, and behavior are identical.
     *      The only difference is we're tracking ETH balances instead of arbitrary data.
     */
    mapping(address => uint256) public balances;

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // EVENTS
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    /**
     * @notice Emitted when ETH is deposited
     * @param sender Address that deposited
     * @param amount Amount deposited in wei
     *
     * WHY EVENTS?
     *   - Off-chain indexing (The Graph, Etherscan)
     *   - Frontend can listen for updates
     *   - Cheaper than storage (~2k gas vs ~20k)
     *   - Permanent log (cannot be modified)
     *
     * INDEXED: Up to 3 parameters can be indexed
     *          Indexed params are filterable but cost ~375 gas extra
     */
    event Deposited(address indexed sender, uint256 amount);

    /**
     * @notice Emitted when ETH is withdrawn
     * @param recipient Address that withdrew
     * @param amount Amount withdrawn in wei
     */
    event Withdrawn(address indexed recipient, uint256 amount);

    /**
     * @notice Emitted when ETH received via receive()
     * @param sender Address that sent ETH
     * @param amount Amount received in wei
     *
     * NOTE: receive() is called for plain ETH transfers (empty msg.data)
     */
    event Received(address indexed sender, uint256 amount);

    /**
     * @notice Emitted when fallback() is triggered
     * @param sender Address that called
     * @param amount ETH sent (if any)
     * @param data Calldata sent
     *
     * NOTE: fallback() catches:
     *       1. Function signature mismatches
     *       2. ETH sent when no receive() (and msg.data is empty)
     */
    event FallbackCalled(address indexed sender, uint256 amount, bytes data);

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // CONSTRUCTOR
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    /**
     * @notice Deploys the contract and sets owner
     * @dev PAYABLE constructor allows ETH to be sent during deployment
     *
     * 🏗️  CONSTRUCTORS: The One-Time Setup (Revisited from Project 01)
     * ═══════════════════════════════════════════════════════════════════
     *
     *      CONNECTION TO PROJECT 01:
     *      Remember constructors from Project 01? They run EXACTLY ONCE during
     *      deployment. Here we're adding the `payable` keyword, which allows
     *      the constructor to receive ETH during deployment!
     *
     *      HOW IT WORKS:
     *      ┌─────────────────────────────────────────┐
     *      │ Developer deploys contract              │
     *      │   ↓                                      │
     *      │ Constructor executes                    │ ← Runs ONCE, never again!
     *      │   ↓                                      │
     *      │ Sets owner = msg.sender                 │ ← Deployer becomes owner
     *      │   ↓                                      │
     *      │ If ETH sent, emits Deposited event      │ ← Optional initial funding
     *      │   ↓                                      │
     *      │ Contract is live on blockchain          │
     *      │   ↓                                      │
     *      │ Constructor code is DISCARDED           │ ← Not stored!
     *      └─────────────────────────────────────────┘
     *
     *      WHY PAYABLE CONSTRUCTOR?
     *      - Contract can receive initial funding (common in DeFi)
     *      - Useful for liquidity pools, reward pools, etc.
     *      - Without payable, deployment with ETH reverts
     *      - Makes intent explicit (contract accepts ETH from the start)
     *
     *      DEPLOYMENT EXAMPLES:
     *      ```solidity
     *      // Without ETH:
     *      new FunctionsPayableSolution()
     *
     *      // With ETH (requires payable constructor):
     *      new FunctionsPayableSolution{value: 1 ether}()
     *      ```
     *
     *      GAS COST BREAKDOWN:
     *      - Constructor execution: Included in deployment cost
     *      - Setting owner: ~20,000 gas (cold SSTORE to slot 0)
     *      - Event emission (if ETH sent): ~2,000 gas
     *      - Total deployment: ~200,000+ gas (includes bytecode storage)
     *
     *      FUN FACT: Constructor code is NOT stored on-chain!
     *      Only the runtime bytecode (your functions) is stored.
     *      The constructor runs during deployment, then disappears!
     *      This saves gas - you don't pay to store initialization code forever.
     *
     *      REAL-WORLD ANALOGY:
     *      Like opening a bank account with an initial deposit:
     *      - Constructor = Opening the account (one-time setup)
     *      - Owner = Account holder (who controls it)
     *      - ETH sent = Initial deposit (optional funding)
     *
     *      SECURITY CONSIDERATION:
     *      The owner is set to msg.sender during deployment. This means the
     *      deployer becomes the owner. In production, consider:
     *      - Using a multi-sig wallet as deployer
     *      - Transferring ownership to a governance contract
     *      - Using OpenZeppelin Ownable for better security
     *
     *      🎓 LEARNING MOMENT:
     *      This constructor is almost identical to Project 01's constructor!
     *      The only difference is the `payable` keyword, which allows ETH
     *      to be sent during deployment. This is a common pattern in DeFi
     *      protocols that need initial funding.
     */
    constructor() payable {
        // 👤 SET OWNER: Critical security step!
        // msg.sender during deployment = the address deploying the contract
        // This establishes who "owns" the contract
        // Common pattern: owner can call admin functions later
        // GAS: ~20,000 gas (cold SSTORE to slot 0)
        owner = msg.sender;

        // 💰 OPTIONAL INITIAL FUNDING:
        // If ETH is sent during deployment, emit an event to track it
        // This is useful for DeFi protocols that need initial liquidity
        // GAS: ~2,000 gas (event emission)
        if (msg.value > 0) {
            emit Deposited(msg.sender, msg.value);
        }
    }

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // SPECIAL FUNCTIONS: receive() and fallback()
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    /**
     * @notice Receives ETH sent with empty calldata
     * @dev Called when ETH is sent to contract with empty msg.data
     *
     * 📬 RECEIVE(): The Plain ETH Handler
     * ═══════════════════════════════════════
     *
     *      This is a SPECIAL function that handles plain ETH transfers.
     *      It's called automatically when ETH is sent without calling a specific function.
     *
     *      HOW IT WORKS:
     *      ┌─────────────────────────────────────────┐
     *      │ User sends ETH with empty calldata        │
     *      │   ↓                                        │
     *      │ EVM checks: Is msg.data empty?            │ ← Yes!
     *      │   ↓                                        │
     *      │ EVM checks: Does receive() exist?        │ ← Yes!
     *      │   ↓                                        │
     *      │ EVM calls receive() automatically        │ ← Magic!
     *      │   ↓                                        │
     *      │ Contract receives ETH                      │
     *      │   ↓                                        │
     *      │ Event emitted for tracking                │
     *      └─────────────────────────────────────────┘
     *
     *      WHEN IS IT CALLED?
     *      These all trigger receive():
     *      - address(contract).transfer(amount)
     *      - address(contract).send(amount)
     *      - address(contract).call{value: amount}("")
     *      - contract.receive{value: amount}()  // If receive() exists
     *
     *      REQUIREMENTS (COMPILER ENFORCED):
     *      ✅ Must be `external` (cannot be public/internal/private)
     *      ✅ Must be `payable` (required keyword)
     *      ✅ Cannot have arguments (no parameters allowed)
     *      ✅ Cannot return anything (no return value)
     *
     *      GAS CONSIDERATIONS:
     *      ⚠️  When called via .transfer() or .send(): Only 2,300 gas available!
     *      ✅ When called via .call{value:}(): All remaining gas available
     *      💡 BEST PRACTICE: Keep logic minimal (gas limit concerns)
     *
     *      GAS COST BREAKDOWN:
     *      - Function execution: ~2,100 gas (base call)
     *      - Event emission: ~2,000 gas
     *      - Total: ~4,100 gas (if called via .call)
     *      - Total: ~2,300 gas (if called via .transfer - may fail!)
     *
     *      WHY WE DON'T UPDATE BALANCES HERE:
     *      This ETH goes to the contract but isn't tracked per-user.
     *      This is intentional! It allows:
     *      - Contract funding (donations, fees)
     *      - Untracked ETH (not part of user deposits)
     *      - Flexibility (contract can have ETH beyond user balances)
     *
     *      CONNECTION TO PROJECT 01:
     *      Remember events from Project 01? We're using the same event system!
     *      Events are cheaper than storage (~2k gas vs ~20k gas) and perfect
     *      for off-chain indexing. This is why we emit an event here instead
     *      of storing the data.
     *
     *      REAL-WORLD ANALOGY:
     *      Like an ATM slot - it only accepts cash (ETH) with no instructions.
     *      Just drop money in, and it's accepted. No need to specify what to do
     *      with it - the contract handles it automatically.
     *
     *      COMPARISON TO OTHER LANGUAGES:
     *      - Python: `__call__` magic method (similar concept, but for function calls)
     *      - Go/Rust: No direct equivalent (blockchain-specific feature)
     *      - Solidity: Special function for ETH handling (unique to blockchain)
     *
     *      SECURITY CONSIDERATION:
     *      If you want to track this ETH in user balances, you'd need to call
     *      deposit() instead. receive() is for untracked ETH (donations, fees, etc.).
     *
     *      🎓 LEARNING MOMENT:
     *      This function demonstrates the power of Solidity's special functions.
     *      Unlike regular functions, receive() is called automatically by the EVM
     *      when certain conditions are met. This is blockchain-specific behavior
     *      that doesn't exist in traditional programming languages!
     */
    receive() external payable {
        // 📢 EVENT EMISSION: Log the plain ETH transfer
        // Events are cheaper than storage (~2k gas vs ~20k gas)
        // Perfect for off-chain indexing and frontend updates
        // GAS: ~2,000 gas (event emission)
        emit Received(msg.sender, msg.value);

        // 💡 DESIGN DECISION: We don't update balances here
        // This ETH goes to contract but isn't tracked per-user
        // Could be used for:
        //   - Contract funding (donations, fees)
        //   - Untracked ETH (not part of user deposits)
        //   - Flexibility (contract can have ETH beyond user balances)
        //
        // If you want to track this ETH, users should call deposit() instead!
    }

    /**
     * @notice Catches calls to non-existent functions or ETH with data
     * @dev Called when:
     *      1. Function signature doesn't match any function
     *      2. ETH sent with data but no receive() function
     *      3. ETH sent with empty data but no receive() function
     *
     * REQUIREMENTS:
     *   - Must be external
     *   - Can be payable (to accept ETH) or not
     *   - Can access msg.data
     *
     * USE CASES:
     *   - Proxy pattern (delegate all calls)
     *   - Catch-all for logging
     *   - Accept ETH when receive() not defined
     *
     * SECURITY WARNING:
     *   - Don't blindly trust msg.data
     *   - Attacker can send malicious calldata
     *   - In proxy patterns, use proper checks
     *
     * GAS: Similar to receive() gas constraints
     */
    fallback() external payable {
        emit FallbackCalled(msg.sender, msg.value, msg.data);

        // NOTE: msg.data contains the full calldata
        //       First 4 bytes = function selector
        //       Remaining = encoded arguments
    }

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // DEPOSIT FUNCTIONS (PAYABLE)
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    /**
     * @notice Deposit ETH into your balance
     * @dev Must be payable to accept ETH
     *
     * 💰 DEPOSIT(): The Foundation of ETH Handling
     * ════════════════════════════════════════════
     *
     *      This function is the core of our deposit system. It accepts ETH and
     *      tracks it in the balances mapping.
     *
     *      CONNECTION TO PROJECT 01:
     *      This function uses the EXACT same mapping operations we learned in
     *      Project 01! The `balances[msg.sender] += msg.value` operation is:
     *      1. Read from mapping (SLOAD: ~100 gas warm)
     *      2. Add msg.value (ADD: ~3 gas)
     *      3. Write back to mapping (SSTORE: ~5,000 gas warm)
     *      This is the same read-modify-write pattern from Project 01!
     *
     *      HOW IT WORKS:
     *      ┌─────────────────────────────────────────┐
     *      │ User calls: deposit{value: 1 ether}()   │
     *      │   ↓                                      │
     *      │ msg.value = 1 ether (in wei)            │ ← ETH amount sent
     *      │   ↓                                      │
     *      │ Check: msg.value > 0?                    │ ← Validation
     *      │   ↓                                      │
     *      │ ETH automatically transferred to contract │ ← Magic!
     *      │   ↓                                      │
     *      │ balances[msg.sender] += msg.value        │ ← Track deposit
     *      │   ↓                                      │
     *      │ Event emitted for off-chain tracking     │ ← Log the deposit
     *      └─────────────────────────────────────────┘
     *
     *      UNDERSTANDING msg.value:
     *      - Type: uint256
     *      - Unit: Always in wei (smallest unit)
     *      - Scope: Available in payable functions
     *      - Value: Amount of ETH sent with the call
     *
     *      EXAMPLE:
     *      ```solidity
     *      // User sends 1 ETH:
     *      contract.deposit{value: 1 ether}();
     *      // msg.value = 1000000000000000000 wei
     *      // balances[msg.sender] += 1000000000000000000
     *      ```
     *
     *      WHY REQUIRE msg.value > 0?
     *      - Prevents useless transactions (wasting gas)
     *      - Saves gas for users (fail fast)
     *      - Cleaner event logs (no zero deposits)
     *      - Security best practice (validate inputs)
     *
     *      GAS COST BREAKDOWN (from Project 01 knowledge):
     *      - Transaction base: ~21,000 gas (base transaction cost)
     *      - require() check: ~3 gas (if passes)
     *      - SLOAD balance: ~100 gas (warm read from mapping)
     *      - ADD operation: ~3 gas (addition)
     *      - SSTORE balance: ~5,000 gas (warm write to mapping)
     *      - Event emission: ~2,000 gas
     *      - Total: ~28,106 gas (first deposit)
     *      - Total: ~28,106 gas (subsequent deposits, warm)
     *
     *      GAS OPTIMIZATION: Why use += instead of separate operations?
     *      ```solidity
     *      // ✅ GOOD: Single operation
     *      balances[msg.sender] += msg.value;
     *      // Costs: 1 SLOAD + 1 ADD + 1 SSTORE = ~5,103 gas
     *
     *      // ❌ LESS EFFICIENT: Separate operations
     *      uint256 bal = balances[msg.sender];
     *      bal += msg.value;
     *      balances[msg.sender] = bal;
     *      // Costs: 1 SLOAD + 1 MLOAD + 1 ADD + 1 SSTORE = ~5,106 gas
     *      ```
     *      Savings: ~3 gas (minimal, but += is cleaner and more readable)
     *
     *      SECURITY CONSIDERATIONS:
     *      ✅ No reentrancy risk here (no external calls)
     *      ✅ State updated before any external interactions
     *      ✅ Input validation (msg.value > 0)
     *      ✅ Event emitted for transparency
     *
     *      REAL-WORLD ANALOGY:
     *      Like depositing cash at a bank:
     *      - You hand over cash (send ETH)
     *      - Bank puts it in vault (contract balance increases)
     *      - Bank updates your account (balances mapping updated)
     *      - Bank gives you receipt (event emitted)
     *
     *      COMPARISON TO OTHER LANGUAGES:
     *      - TypeScript: No built-in money, would be just numbers in memory
     *      - Go: No built-in money, would be just numbers
     *      - Rust: No built-in money, would be just numbers
     *      - Solidity: Real ETH, permanent blockchain state, costs gas
     *
     *      🎓 LEARNING MOMENT:
     *      This function demonstrates the power of Solidity's `payable` keyword.
     *      Without it, sending ETH would revert. With it, ETH is automatically
     *      transferred to the contract. The `msg.value` variable gives us access
     *      to the amount sent, which we use to update the balances mapping.
     *      This is the same mapping pattern from Project 01, but now we're
     *      handling real money!
     */
    function deposit() public payable {
        // 🛡️  VALIDATION: Always check inputs!
        // This prevents users from accidentally sending 0 ETH (wasting gas)
        // It's also a security best practice - validate everything!
        // GAS: ~3 gas (if check passes)
        require(msg.value > 0, "Must send ETH");

        // 💵 READ-MODIFY-WRITE PATTERN (from Project 01):
        // 1. Read: balances[msg.sender] (SLOAD: ~100 gas warm)
        // 2. Modify: Add msg.value to existing balance (ADD: ~3 gas)
        // 3. Write: Store back to mapping (SSTORE: ~5,000 gas warm)
        //
        // This is the EXACT same pattern we learned in Project 01!
        // The only difference is we're handling real ETH instead of arbitrary data.
        //
        // SECURITY: No reentrancy risk here (no external calls)
        // GAS: 1 SLOAD + 1 ADD + 1 SSTORE = ~5,103 gas (warm)
        balances[msg.sender] += msg.value;

        // 📢 EVENT EMISSION: Log the deposit for transparency
        // Events are cheaper than storage (~2k gas vs ~20k gas)
        // Off-chain systems (like frontends) can listen to this event
        // to show users their deposit history in real-time!
        // GAS: ~2,000 gas (event emission)
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @notice Deposit ETH for a specific recipient
     * @param _recipient Address to credit the deposit
     *
     * @dev USE CASE: Gifting, paying on behalf of someone
     *
     * WHY CHECK _recipient != address(0)?
     *   - Prevents accidental ETH burning
     *   - Zero address can't withdraw (no private key)
     *   - Good UX / safety measure
     *
     * SECURITY: Sender pays, recipient gets credit
     *           No approval needed (gift/payment model)
     */
    function depositFor(address _recipient) public payable {
        require(msg.value > 0, "Must send ETH");
        require(_recipient != address(0), "Invalid recipient");

        balances[_recipient] += msg.value;

        emit Deposited(_recipient, msg.value);
    }

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // WITHDRAWAL FUNCTIONS (CRITICAL SECURITY)
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    /**
     * @notice Withdraw ETH from your balance
     * @param _amount Amount to withdraw in wei
     *
     * @dev   CRITICAL: Uses Checks-Effects-Interactions pattern
     *
     * CHECKS-EFFECTS-INTERACTIONS PATTERN:
     * PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
     * 1. CHECKS: Validate conditions (require statements)
     * 2. EFFECTS: Update state (modify storage)
     * 3. INTERACTIONS: External calls (send ETH, call contracts)
     *
     * WHY THIS ORDER?
     *   - Prevents reentrancy attacks
     *   - State updated BEFORE external call
     *   - If external call re-enters, state already changed
     *
     * REENTRANCY EXAMPLE (VULNERABLE):
     * PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
     * L BAD:
     *   require(balances[msg.sender] >= _amount);
     *   msg.sender.call{value: _amount}("");  // External call first!
     *   balances[msg.sender] -= _amount;  // Too late, attacker re-entered
     *
     *  GOOD (this implementation):
     *   require(balances[msg.sender] >= _amount);  // CHECK
     *   balances[msg.sender] -= _amount;  // EFFECT (update first!)
     *   msg.sender.call{value: _amount}("");  // INTERACTION (call last)
     *
     * WHY .call{value:} INSTEAD OF .transfer()?
     * PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
     *   .transfer() problems:
     *     - Only forwards 2,300 gas
     *     - Breaks with smart contract wallets (Gnosis Safe, Argent, etc.)
     *     - EVM repricing can break it (Istanbul fork example)
     *
     *   .call{value:} benefits:
     *     - Forwards all remaining gas
     *     - Works with smart contract wallets
     *     - Future-proof
     *     - Returns (bool success, bytes data)
     *
     * GAS COST BREAKDOWN:
     *   - CHECKS: 1 SLOAD = ~100 gas (warm)
     *   - EFFECTS: 1 SSTORE = ~5,000 gas (warm, non-zero to non-zero)
     *   - INTERACTIONS: External call = ~2,100 gas base
     *   - Event: ~1,500 gas
     *   - Total: ~8,700 gas (excluding recipient gas)
     *
     * GAS OPTIMIZATION: Why update balance before external call?
     *   - Prevents reentrancy attacks
     *   - If external call re-enters, balance already updated
     *   - Saves gas by preventing failed attack transactions
     */
    function withdraw(uint256 _amount) public {
        // ================================================================
        // 1. CHECKS: Validate all conditions
        // ================================================================
        require(_amount > 0, "Amount must be greater than 0");
        // GAS: 1 SLOAD = ~100 gas (warm)
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        // ================================================================
        // 2. EFFECTS: Update state BEFORE external interactions
        // ================================================================
        // GAS: 1 SSTORE = ~5,000 gas (warm, non-zero to non-zero)
        balances[msg.sender] -= _amount;

        // ================================================================
        // 3. INTERACTIONS: External calls LAST
        // ================================================================

        // Use .call{value:} for ETH transfer (NOT .transfer or .send)
        // GAS: ~2,100 gas base + gas forwarded to recipient
        (bool success,) = payable(msg.sender).call{value: _amount}("");

        // Always check return value
        require(success, "Transfer failed");

        // Emit event for off-chain tracking
        // GAS: Event emission = ~1,500 gas
        emit Withdrawn(msg.sender, _amount);
    }

    /**
     * @notice Withdraw your entire balance
     *
     * @dev Convenience function, uses same security pattern
     *
     * WHY SEPARATE FUNCTION?
     *   - Common use case (withdraw all)
     *   - Saves gas (one less parameter encoding)
     *   - Better UX
     *
     * ALTERNATIVE: Just call withdraw(balances[msg.sender])
     *              But that costs extra gas reading storage twice
     */
    function withdrawAll() public {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance to withdraw");

        // CHECKS-EFFECTS-INTERACTIONS
        balances[msg.sender] = 0; // Set to 0 (cheaper than -= amount)

        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @notice Owner withdraws unreserved contract funds
     * @param _amount Amount to withdraw
     *
     * @dev OWNER-ONLY: Only contract owner can call
     *
     * SECURITY CONSIDERATIONS:
     *   - Only owner can withdraw
     *   - Could track "reserved" (sum of balances) separately
     *   - Here we just check total balance
     *
     * PRODUCTION IMPROVEMENT:
     *   - Use OpenZeppelin Ownable
     *   - Track reserved vs unreserved funds explicitly
     *   - Add timelock for owner operations
     *   - Use multi-sig for owner
     *
     * WHY ALLOW OWNER WITHDRAWAL?
     *   - Contract can receive ETH via receive()/fallback()
     *   - That ETH isn't tracked in user balances
     *   - Owner can collect fees, donations, etc.
     */
    function ownerWithdraw(uint256 _amount) public {
        require(msg.sender == owner, "Only owner");
        require(_amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= _amount, "Insufficient contract balance");

        // No balance tracking update needed (owner's personal withdrawal)

        (bool success,) = payable(owner).call{value: _amount}("");
        require(success, "Transfer failed");

        emit Withdrawn(owner, _amount);
    }

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // VIEW FUNCTIONS (READ-ONLY, NO GAS WHEN CALLED EXTERNALLY)
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    /**
     * @notice Get balance for an address
     * @param _address Address to query
     * @return Balance in wei
     *
     * @dev VIEW: Reads state but doesn't modify
     *      No gas cost when called externally (off-chain)
     *      Costs gas when called by another contract (on-chain)
     *
     * WHY VIEW?
     *   - Explicitly marks as read-only
     *   - Compiler enforces no state changes
     *   - Wallets know not to send transactions
     *
     * NOTE: Public state variable 'balances' has auto-generated getter
     *       This explicit function is for demonstration
     */
    function getBalance(address _address) public view returns (uint256) {
        return balances[_address];
    }

    /**
     * @notice Get contract's total ETH balance
     * @return Total ETH held by contract in wei
     *
     * @dev address(this).balance is TOTAL ETH in contract
     *      Includes:
     *        - All deposited ETH (tracked in balances)
     *        - ETH from receive()/fallback() (not tracked)
     *        - ETH sent during deployment
     *
     * IMPORTANT:
     *   address(this).balance >= sum(balances[all users])
     *   Difference = unreserved funds (owner can withdraw)
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // FUNCTION VISIBILITY DEMONSTRATIONS
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    /**
     * @notice PUBLIC: Callable from anywhere
     * @return A string message
     *
     * @dev PUBLIC visibility:
     *      - Callable externally (from EOAs, other contracts)
     *      - Callable internally (from this contract)
     *      - Auto-generates getter for state variables
     *
     * GAS COST:
     *   - Slightly more expensive than external (copies calldata to memory)
     *   - ~200 gas overhead vs external for complex params
     *
     * WHEN TO USE:
     *   - Need to call function internally AND externally
     *   - Simple functions where gas difference negligible
     *
     * COMPARISON:
     *   Python: No visibility keywords, use _ prefix convention
     *   Go: Capitalized = public, lowercase = package-private
     *   Rust: pub keyword
     */
    function publicFunction() public pure returns (string memory) {
        return "This is public";
    }

    /**
     * @notice EXTERNAL: Only callable from outside
     * @return A string message
     *
     * @dev EXTERNAL visibility:
     *      - Only callable externally (from EOAs, other contracts)
     *      - NOT callable internally (must use this.externalFunction())
     *      - More gas-efficient for complex parameters (uses calldata)
     *
     * GAS SAVINGS:
     *   - For arrays/strings: ~200+ gas saved vs public
     *   - Reads directly from calldata (no memory copy)
     *
     * WHEN TO USE:
     *   - Public API functions never called internally
     *   - Functions with array/struct/string parameters
     *   - Gas optimization priority
     *
     * LIMITATION: Can't call internally without this.func() (external call)
     */
    function externalFunction() external pure returns (string memory) {
        return "This is external";
    }

    /**
     * @notice INTERNAL: Callable from this contract and derived contracts
     * @return A string message
     *
     * @dev INTERNAL visibility:
     *      - Callable from this contract
     *      - Callable from contracts that inherit this
     *      - NOT callable externally
     *
     * WHEN TO USE:
     *   - Helper functions
     *   - Shared logic in inheritance hierarchy
     *   - Internal building blocks
     *
     * COMPARISON:
     *   Python: Single underscore prefix _internal_func()
     *   Go: lowercase (package-private, similar concept)
     *   Rust: pub(crate) or no pub
     *
     * INHERITANCE:
     *   contract Child is FunctionsPayable {
     *     function callInternal() public pure returns (string memory) {
     *       return internalFunction();  // OK, inherits access
     *     }
     *   }
     */
    function internalFunction() internal pure returns (string memory) {
        return "This is internal";
    }

    /**
     * @notice PRIVATE: Only callable from this exact contract
     * @return A string message
     *
     * @dev PRIVATE visibility:
     *      - Only callable from this contract
     *      - NOT callable from derived contracts (unlike internal)
     *      - Most restricted visibility
     *
     * WHEN TO USE:
     *   - Implementation details
     *   - Functions that should never be overridden
     *   - Sensitive logic encapsulation
     *
     * SECURITY NOTE:
     *   - "Private" != encrypted
     *   - All blockchain data is public
     *   - Just controls function callable, not data visibility
     *
     * COMPARISON:
     *   Python: Double underscore __private_func()
     *   Go: lowercase (similar)
     *   Rust: No pub keyword
     *
     * INHERITANCE:
     *   contract Child is FunctionsPayable {
     *     function callPrivate() public pure returns (string memory) {
     *       return privateFunction();  // ERROR: not accessible
     *     }
     *   }
     */
    function privateFunction() private pure returns (string memory) {
        return "This is private";
    }

    /**
     * @notice Wrapper to demonstrate calling internal function
     * @return Result from internal function
     *
     * @dev Shows that internal functions can be called from within contract
     */
    function callInternalFunction() public pure returns (string memory) {
        return internalFunction(); // OK: internal is accessible here
    }

    /**
     * @notice Wrapper to demonstrate calling private function
     * @return Result from private function
     *
     * @dev Shows that private functions can be called from within contract
     */
    function callPrivateFunction() public pure returns (string memory) {
        return privateFunction(); // OK: private is accessible here
    }
}

/**
 * TPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPW
 * Q                          KEY TAKEAWAYS                                    Q
 * ZPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP]
 *
 * 1. PAYABLE MODIFIER IS REQUIRED TO ACCEPT ETH
 *      Without it, transactions with ETH revert
 *      Makes intent explicit and prevents accidents
 *
 * 2. SPECIAL FUNCTIONS
 *      receive(): Plain ETH transfers (empty calldata)
 *      fallback(): Unknown function calls or ETH with data
 *
 * 3. ETH TRANSFER SAFETY
 *      Use .call{value:}() NOT .transfer() or .send()
 *      Always check return value
 *      Forward sufficient gas for smart contract wallets
 *
 * 4. CHECKS-EFFECTS-INTERACTIONS PATTERN
 *      Validate first (require)
 *      Update state second (modify storage)
 *      External calls last (send ETH, call contracts)
 *      Prevents reentrancy attacks
 *
 * 5. FUNCTION VISIBILITY
 *      public: Anywhere, auto-getter for variables
 *      external: Outside only, gas-efficient for arrays
 *      internal: This contract + derived contracts
 *      private: This contract only
 *
 * 6. VIEW/PURE FUNCTIONS
 *      view: Reads state, no modifications, free off-chain
 *      pure: No state access, deterministic, free off-chain
 *
 * TPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPW
 * Q                        COMMON MISTAKES                                    Q
 * ZPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP]
 *
 * ❌ Using .transfer() or .send() (breaks with smart contract wallets)
 * ❌ Not checking .call() return value (silent failures)
 * ❌ External calls before state updates (reentrancy vulnerability)
 * ❌ Forgetting payable on constructor (can't fund during deployment)
 * ❌ Using public when external would save gas (arrays/strings)
 * ❌ Not emitting events for ETH transfers (breaks indexing)
 * ❌ Assuming "private" means encrypted (all data is public!)
 * ❌ Not validating msg.value > 0 (wastes gas on zero deposits)
 * ❌ Calling external functions internally without this.func()
 *
 * TPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPW
 * Q                          NEXT STEPS                                       Q
 * ZPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP]
 *
 * • Deploy to testnet and send real ETH
 * • Experiment with receive() vs fallback() by sending different calldata
 * • Study reentrancy attacks in Project 07
 * • Learn about events and logging in Project 03
 * • Practice with different function visibility modifiers
 * • Compare gas costs: public vs external for arrays
 */
