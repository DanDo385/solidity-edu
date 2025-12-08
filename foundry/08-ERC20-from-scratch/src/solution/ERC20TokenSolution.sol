// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ERC20TokenSolution
 * @notice Complete ERC20 token implementation combining all previous concepts
 * 
 * PURPOSE: The foundation of DeFi - fungible token standard enabling interoperability
 * CS CONCEPTS: Hash tables (balances), nested mappings (allowances), delegation pattern
 * 
 * CONNECTIONS:
 * - Project 01: Mapping storage for balances, nested mappings for allowances
 * - Project 02: Public functions, CEI pattern for transfers
 * - Project 03: Transfer/Approval events (required by standard)
 * - Project 04: Access control patterns (for minting/burning extensions)
 * - Project 05: Error handling for validation
 * 
 * REAL-WORLD: Used by 500,000+ tokens, foundation for all DeFi protocols
 */
contract ERC20TokenSolution {
    // ════════════════════════════════════════════════════════════════════════
    // STATE VARIABLES
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Token name (e.g., "MyToken")
     * @dev Stored as string in storage (expensive!)
     *      CONNECTION TO PROJECT 01: String storage costs ~20k+ gas
     */
    string public name;

    /**
     * @notice Token symbol (e.g., "MTK")
     * @dev Short identifier for the token
     *      CONNECTION TO PROJECT 01: String storage costs ~20k+ gas
     */
    string public symbol;

    /**
     * @notice Number of decimals for token
     * @dev Most tokens use 18 decimals (like ETH)
     *      This determines the smallest unit: 1 token = 10^decimals smallest units
     */
    uint8 public decimals;

    /**
     * @notice Total token supply
     * @dev Tracks total number of tokens in existence
     *      CONNECTION TO PROJECT 01: uint256 storage slot
     */
    uint256 public totalSupply;

    /**
     * @notice Mapping of addresses to token balances
     * @dev CONNECTION TO PROJECT 01: Mapping storage pattern!
     *      Storage slot: keccak256(abi.encodePacked(address, slot_number))
     *      O(1) lookup: ~100 gas (warm) or ~2,100 gas (cold)
     */
    mapping(address => uint256) public balanceOf;

    /**
     * @notice Mapping of owner => spender => allowance amount
     * @dev CONNECTION TO PROJECT 01: Nested mapping storage pattern!
     *      Enables delegated spending - allows spender to transfer owner's tokens
     *      Storage: Two-level keccak256 calculation
     */
    mapping(address => mapping(address => uint256)) public allowance;

    // ════════════════════════════════════════════════════════════════════════
    // EVENTS
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Emitted when tokens are transferred
     * @param from Address tokens are transferred from (address(0) for minting)
     * @param to Address tokens are transferred to (address(0) for burning)
     * @param value Amount of tokens transferred
     * @dev CONNECTION TO PROJECT 03: Event emission!
     *      Required by ERC20 standard. Indexed parameters enable filtering.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @notice Emitted when approval is set
     * @param owner Address that owns the tokens
     * @param spender Address approved to spend tokens
     * @param value Amount of tokens approved
     * @dev CONNECTION TO PROJECT 03: Event emission!
     *      Required by ERC20 standard. Indexed parameters enable filtering.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // ════════════════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Deploys ERC20 token with initial supply
     * @param _name Token name
     * @param _symbol Token symbol
     * @param _initialSupply Initial token supply (will be multiplied by 10^decimals)
     *
     * @dev TOKEN INITIALIZATION: Setting Up the Token
     * ═════════════════════════════════════════════════
     *
     *      This constructor initializes the token with metadata and mints
     *      the initial supply to the deployer.
     *
     *      EXECUTION FLOW:
     *      ┌─────────────────────────────────────────┐
     *      │ 1. SET METADATA: Name, symbol, decimals │
     *      │    - Stored in contract storage         │
     *      │    ↓                                      │
     *      │ 2. CALCULATE SUPPLY: Multiply by decimals│
     *      │    - _initialSupply * 10^18             │
     *      │    ↓                                      │
     *      │ 3. MINT TO DEPLOYER: Set balance        │
     *      │    - balanceOf[msg.sender] = totalSupply │
     *      │    ↓                                      │
     *      │ 4. EMIT EVENT: Transfer from address(0) │
     *      │    - Indicates minting                  │
     *      └─────────────────────────────────────────┘
     *
     *      CONNECTION TO PROJECT 01: Storage Writes!
     *      ══════════════════════════════════════════
     *
     *      We're writing multiple storage slots:
     *      - name: String storage (~20k+ gas)
     *      - symbol: String storage (~20k+ gas)
     *      - decimals: uint8 storage (~20k gas, zero to non-zero)
     *      - totalSupply: uint256 storage (~20k gas, zero to non-zero)
     *      - balanceOf[deployer]: Mapping storage (~20k gas, zero to non-zero)
     *
     *      GAS COST BREAKDOWN:
     *      ┌─────────────────────┬──────────────┬─────────────────┐
     *      │ Operation           │ Gas (cold)   │ Notes           │
     *      ├─────────────────────┼──────────────┼─────────────────┤
     *      │ String storage (name)│ ~20,000 gas │ Depends on length│
     *      │ String storage (symbol)│ ~20,000 gas │ Depends on length│
     *      │ SSTORE decimals     │ ~20,000 gas  │ Zero to non-zero│
     *      │ SSTORE totalSupply  │ ~20,000 gas  │ Zero to non-zero│
     *      │ SSTORE balanceOf    │ ~20,000 gas  │ Zero to non-zero│
     *      │ Event emission      │ ~1,500 gas   │                 │
     *      ├─────────────────────┼──────────────┼─────────────────┤
     *      │ TOTAL               │ ~101,500 gas │ Approximate     │
     *      └─────────────────────┴──────────────┴─────────────────┘
     *
     *      REAL-WORLD ANALOGY:
     *      ═══════════════════
     *
     *      Like printing money at a mint:
     *      - **Name/Symbol** = Currency name (USD, EUR, etc.)
     *      - **Decimals** = Smallest unit (cents, pence, etc.)
     *      - **Initial Supply** = Amount printed
     *      - **Deployer balance** = Who gets the printed money
     *
     *      🎓 LEARNING MOMENT:
     *      The Transfer event from address(0) indicates minting!
     *      address(0) represents "no address" - perfect for representing
     *      tokens coming into existence.
     */
    constructor(string memory _name, string memory _symbol, uint256 _initialSupply) {
        // 💾 SET METADATA: Token name, symbol, decimals
        // CONNECTION TO PROJECT 01: String storage writes!
        // These are expensive but necessary for token identification
        name = _name;        // SSTORE: ~20,000 gas (string write)
        symbol = _symbol;    // SSTORE: ~20,000 gas (string write)
        decimals = 18;       // SSTORE: ~20,000 gas (zero to non-zero)

        // 💾 CALCULATE TOTAL SUPPLY: Multiply by decimals
        // Most tokens use 18 decimals (like ETH)
        // Example: _initialSupply = 1000 → totalSupply = 1000 * 10^18
        totalSupply = _initialSupply * 10**decimals; // SSTORE: ~20,000 gas

        // 💾 MINT TO DEPLOYER: Set initial balance
        // CONNECTION TO PROJECT 01: Mapping storage write!
        // All tokens go to the deployer initially
        balanceOf[msg.sender] = totalSupply; // SSTORE: ~20,000 gas (zero to non-zero)

        // 📢 EVENT EMISSION: Log the minting
        // CONNECTION TO PROJECT 03: Event emission!
        // Transfer from address(0) indicates minting (tokens created from nothing)
        emit Transfer(address(0), msg.sender, totalSupply); // ~1,500 gas
    }

    // ════════════════════════════════════════════════════════════════════════
    // TRANSFER FUNCTION
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Transfer tokens (core ERC20 function)
     * @dev CS: State transition with validation - CEI pattern
     * CONNECTION: Project 01 (mapping storage), Project 02 (CEI), Project 03 (events)
     * 
     * EXECUTION: Validate → Update balances → Emit event
     * Required by ERC20 standard - enables token transfers
     */
    function transfer(address to, uint256 amount) public returns (bool) {
        require(to != address(0), "Invalid recipient"); // CONNECTION: Project 05 error handling
        require(balanceOf[msg.sender] >= amount, "Insufficient balance"); // CONNECTION: Project 01 mapping read
        
        balanceOf[msg.sender] -= amount; // CONNECTION: Project 01 mapping write
        balanceOf[to] += amount; // CONNECTION: Project 01 mapping write
        
        emit Transfer(msg.sender, to, amount); // CONNECTION: Project 03 event (required by ERC20)
        return true;
    }

    // ════════════════════════════════════════════════════════════════════════
    // APPROVAL FUNCTION
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Approve spender to transfer tokens on your behalf
     * @param spender Address approved to spend tokens
     * @param amount Amount of tokens approved
     * @return success True if approval succeeded
     *
     * @dev APPROVAL OPERATION: Delegated Spending Permission
     * ═══════════════════════════════════════════════════════
     *
     *      This function enables delegated spending - allowing another address
     *      to transfer tokens on your behalf up to the approved amount.
     *
     *      EXECUTION FLOW:
     *      ┌─────────────────────────────────────────┐
     *      │ 1. VALIDATION: Check spender             │
     *      │    - Must not be zero address           │
     *      │    ↓                                      │
     *      │ 2. SET ALLOWANCE: Update nested mapping │
     *      │    - allowance[owner][spender] = amount │
     *      │    ↓                                      │
     *      │ 3. EMIT EVENT: Approval event            │
     *      │    - Log the approval                    │
     *      │    ↓                                      │
     *      │ 4. RETURN: Return true                   │
     *      └─────────────────────────────────────────┘
     *
     *      CONNECTION TO PROJECT 01: Nested Mapping Storage!
     *      ════════════════════════════════════════════════
     *
     *      We're writing to nested mappings:
     *      - Storage slot: keccak256(keccak256(owner, slot), spender)
     *      - Two-level keccak256 calculation
     *
     *      CONNECTION TO PROJECT 03: Event Emission!
     *      ══════════════════════════════════════════
     *
     *      Approval event is required by ERC20 standard.
     *      Frontends use this to show approval status!
     *
     *      ⚠️  APPROVAL RACE CONDITION WARNING:
     *      ═════════════════════════════════════════
     *
     *      There's a known race condition in ERC20 approvals!
     *
     *      VULNERABLE SCENARIO:
     *      1. Alice approves Bob for 100 tokens
     *      2. Alice wants to change to 50 tokens
     *      3. Alice calls approve(bob, 50)
     *      4. Bob sees transaction in mempool
     *      5. Bob front-runs with transferFrom(alice, bob, 100) (uses old approval)
     *      6. Then Alice's approval goes through (sets to 50)
     *      7. Bob got 100 tokens, not 50!
     *
     *      MITIGATION:
     *      - Use increaseAllowance() / decreaseAllowance() (OpenZeppelin)
     *      - Or approve to 0 first, then approve new amount
     *      - Or use safeIncreaseAllowance() pattern
     *
     *      GAS COST BREAKDOWN:
     *      ┌─────────────────────┬──────────────┬─────────────────┐
     *      │ Operation           │ Gas (warm)   │ Gas (cold)      │
     *      ├─────────────────────┼──────────────┼─────────────────┤
     *      │ require() check     │ ~3 gas       │ ~3 gas          │
     *      │ SSTORE allowance    │ ~5,000 gas   │ ~20,000 gas     │
     *      │ Event emission      │ ~1,500 gas   │ ~1,500 gas      │
     *      ├─────────────────────┼──────────────┼─────────────────┤
     *      │ TOTAL (warm)        │ ~6,503 gas   │                 │
     *      │ TOTAL (cold)        │              │ ~21,503 gas     │
     *      └─────────────────────┴──────────────┴─────────────────┘
     *
     *      REAL-WORLD ANALOGY:
     *      ═══════════════════
     *
     *      Like giving someone a credit card with a spending limit:
     *      - **approve()** = Setting the credit limit
     *      - **allowance** = How much they can spend
     *      - **transferFrom()** = Making a purchase (decreases allowance)
     *      - **Event** = Credit card statement (permanent record)
     *
     *      🎓 LEARNING MOMENT:
     *      Approvals are essential for DeFi protocols:
     *      - DEXs: Approve DEX to swap your tokens
     *      - Lending: Approve protocol to use tokens as collateral
     *      - Yield farming: Approve farm to stake your tokens
     *      Without approvals, DeFi wouldn't work!
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        require(spender != address(0), "Invalid spender"); // CONNECTION: Project 05 validation
        
        allowance[msg.sender][spender] = amount; // CONNECTION: Project 01 nested mapping write
        emit Approval(msg.sender, spender, amount); // CONNECTION: Project 03 event (required by ERC20)
        
        return true;
    }

    // ════════════════════════════════════════════════════════════════════════
    // TRANSFERFROM FUNCTION
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Transfer tokens from one address to another (delegated transfer)
     * @param from Address to transfer from (must have approved msg.sender)
     * @param to Address to transfer to
     * @param amount Amount of tokens to transfer
     * @return success True if transfer succeeded
     *
     * @dev TRANSFERFROM OPERATION: Delegated Token Transfer
     * ═══════════════════════════════════════════════════
     *
     *      This function enables delegated transfers - allowing an approved
     *      address to transfer tokens on behalf of another address.
     *
     *      EXECUTION FLOW:
     *      ┌─────────────────────────────────────────┐
     *      │ 1. VALIDATION: Check addresses           │
     *      │    - From and to must not be zero       │
     *      │    ↓                                      │
     *      │ 2. VALIDATION: Check balance             │
     *      │    - From must have sufficient tokens   │
     *      │    ↓                                      │
     *      │ 3. VALIDATION: Check allowance          │
     *      │    - Spender must have sufficient allowance│
     *      │    ↓                                      │
     *      │ 4. UPDATE BALANCES: Decrease from       │
     *      │    - balanceOf[from] -= amount           │
     *      │    ↓                                      │
     *      │ 5. UPDATE BALANCES: Increase to         │
     *      │    - balanceOf[to] += amount              │
     *      │    ↓                                      │
     *      │ 6. DECREASE ALLOWANCE: Update approval   │
     *      │    - allowance[from][spender] -= amount │
     *      │    ↓                                      │
     *      │ 7. EMIT EVENT: Transfer event             │
     *      │    - Log the transfer                    │
     *      │    ↓                                      │
     *      │ 8. RETURN: Return true                   │
     *      └─────────────────────────────────────────┘
     *
     *      CONNECTION TO PROJECT 01: Multiple Storage Updates!
     *      ═══════════════════════════════════════════════════
     *
     *      We're updating three storage locations:
     *      - From balance: Mapping storage
     *      - To balance: Mapping storage
     *      - Allowance: Nested mapping storage
     *
     *      CONNECTION TO PROJECT 02: Checks-Effects-Interactions!
     *      ════════════════════════════════════════════════════
     *
     *      This follows the CEI pattern:
     *      - Checks: Validate inputs, balance, allowance
     *      - Effects: Update balances and allowance
     *      - Interactions: Emit event
     *
     *      GAS COST BREAKDOWN:
     *      ┌─────────────────────┬──────────────┬─────────────────┐
     *      │ Operation           │ Gas (warm)   │ Gas (cold)      │
     *      ├─────────────────────┼──────────────┼─────────────────┤
     *      │ require() checks    │ ~12 gas      │ ~12 gas         │
     *      │ SLOAD from balance  │ ~100 gas     │ ~2,100 gas      │
     *      │ SLOAD allowance     │ ~200 gas     │ ~4,200 gas      │
     *      │ SSTORE from balance │ ~5,000 gas   │ ~20,000 gas     │
     *      │ SSTORE to balance   │ ~5,000 gas   │ ~20,000 gas     │
     *      │ SSTORE allowance    │ ~5,000 gas   │ ~20,000 gas     │
     *      │ Event emission      │ ~1,500 gas   │ ~1,500 gas      │
     *      ├─────────────────────┼──────────────┼─────────────────┤
     *      │ TOTAL (warm)        │ ~16,812 gas  │                 │
     *      │ TOTAL (cold)        │              │ ~67,812 gas     │
     *      └─────────────────────┴──────────────┴─────────────────┘
     *
     *      REAL-WORLD ANALOGY:
     *      ═══════════════════
     *
     *      Like using a credit card:
     *      - **From** = Credit card owner
     *      - **To** = Merchant receiving payment
     *      - **Spender (msg.sender)** = Credit card user
     *      - **Allowance** = Credit limit
     *      - **Decrease allowance** = Charge reduces available credit
     *
     *      USE CASES:
     *      ══════════
     *
     *      - DEXs: Swap tokens (approve DEX, DEX calls transferFrom)
     *      - Lending: Use tokens as collateral (approve protocol, protocol calls transferFrom)
     *      - Yield farming: Stake tokens (approve farm, farm calls transferFrom)
     *
     *      🎓 LEARNING MOMENT:
     *      transferFrom is THE function that makes DeFi composable!
     *      Without it, every protocol would need direct access to your tokens.
     *      With approvals, you maintain control while enabling delegation.
     */
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        // 🛡️  VALIDATION: Check addresses are not zero
        // CONNECTION TO PROJECT 02: Input validation!
        require(from != address(0), "Invalid sender");
        require(to != address(0), "Invalid recipient");

        // 🛡️  VALIDATION: Check from has sufficient balance
        // CONNECTION TO PROJECT 01: Mapping storage read!
        require(balanceOf[from] >= amount, "Insufficient balance"); // SLOAD: ~100 gas

        // 🛡️  VALIDATION: Check spender has sufficient allowance
        // CONNECTION TO PROJECT 01: Nested mapping storage read!
        // Reading from allowance mapping: ~200 gas (warm) or ~4,200 gas (cold)
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance"); // 2 SLOADs: ~200 gas

        // 💾 UPDATE FROM BALANCE: Decrease balance
        // CONNECTION TO PROJECT 01: Mapping storage write!
        balanceOf[from] -= amount; // SSTORE: ~5,000 gas (warm)

        // 💾 UPDATE TO BALANCE: Increase balance
        // CONNECTION TO PROJECT 01: Mapping storage write!
        balanceOf[to] += amount; // SSTORE: ~5,000 gas (warm)

        // 💾 DECREASE ALLOWANCE: Update approval
        // CONNECTION TO PROJECT 01: Nested mapping storage write!
        // CRITICAL: Always decrease allowance after transferFrom!
        // This prevents double-spending of approvals
        allowance[from][msg.sender] -= amount; // SSTORE: ~5,000 gas (warm)

        // 📢 EVENT EMISSION: Log the transfer
        // CONNECTION TO PROJECT 03: Event emission!
        // Required by ERC20 standard. Note: from is the owner, not msg.sender!
        emit Transfer(from, to, amount); // ~1,500 gas

        // ✅ RETURN: ERC20 standard requires bool return
        return true;
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. ERC20 IS THE FOUNDATION OF DEFI
 *    ✅ Most widely used token standard on Ethereum
 *    ✅ Over 500,000 ERC20 tokens exist
 *    ✅ Enables interoperability between protocols
 *    ✅ Required functions: transfer, approve, transferFrom
 *
 * 2. TRANSFER FUNCTION MOVES TOKENS DIRECTLY
 *    ✅ Moves tokens from caller to recipient
 *    ✅ Updates two balances (sender -, recipient +)
 *    ✅ Emits Transfer event (required by standard)
 *    ✅ Gas cost: ~11,700 gas (warm) for simple transfer
 *
 * 3. APPROVAL ENABLES DELEGATED SPENDING
 *    ✅ Owner approves spender for specific amount
 *    ✅ Spender can then call transferFrom
 *    ✅ Essential for DEXs, lending, yield farming
 *    ✅ ⚠️  Has race condition vulnerability!
 *
 * 4. TRANSFERFROM ENABLES DELEGATED TRANSFERS
 *    ✅ Approved spender transfers on owner's behalf
 *    ✅ Automatically decreases allowance
 *    ✅ Gas cost: ~16,800 gas (warm)
 *    ✅ Makes DeFi composable!
 *
 * 5. EVENTS ARE REQUIRED BY STANDARD
 *    ✅ Transfer event: Logs all token movements
 *    ✅ Approval event: Logs all approvals
 *    ✅ Indexed parameters enable efficient filtering
 *    ✅ Frontends and indexers rely on events
 *
 * 6. APPROVAL RACE CONDITION EXISTS
 *    ✅ Changing approval can be front-run
 *    ✅ Mitigation: Use increaseAllowance/decreaseAllowance
 *    ✅ Or approve to 0 first, then new amount
 *    ✅ Still widely used despite vulnerability
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMMON MISTAKES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ❌ Forgetting to validate zero addresses (burns tokens!)
 * ❌ Not checking balance before transfer (underflow errors)
 * ❌ Not decreasing allowance in transferFrom (double-spending!)
 * ❌ Not emitting events (breaks off-chain indexing)
 * ❌ Not returning bool (ERC20 standard requirement)
 * ❌ Not handling approval race condition
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          NEXT STEPS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * • Study OpenZeppelin ERC20 implementation
 * • Add extensions (burnable, mintable, pausable)
 * • Learn about ERC20 extensions (ERC20Votes, ERC20Permit)
 * • Move to Project 09 to learn about ERC721 NFTs
 */
