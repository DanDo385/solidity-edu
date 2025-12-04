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
     * WHY OWNER PATTERN?
     *   - Common access control mechanism
     *   - Allows privileged operations
     *   - Should be transferred to multi-sig in production
     *
     * SECURITY: Single owner = single point of failure
     *           Consider OpenZeppelin Ownable or AccessControl
     */
    address public owner;

    /**
     * @notice Tracks deposited ETH for each address
     * @dev Maps address ’ balance in wei
     *
     * WHY TRACK BALANCES?
     *   - Allows users to deposit and withdraw individually
     *   - Provides accountability
     *   - Enables pull-over-push withdrawal pattern
     *
     * NOTE: address(this).balance is contract's TOTAL ETH
     *       balances[addr] is just the tracked portion
     *       Contract can have ETH not tracked in balances (via receive/fallback)
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
     * WHY PAYABLE CONSTRUCTOR?
     *   - Contract can receive initial funding
     *   - Common for DeFi protocols (liquidity, rewards pool)
     *   - Without payable, deployment with ETH reverts
     *
     * GAS: Constructor code is NOT stored on-chain
     *      Only runtime bytecode is stored
     *
     * DEPLOYMENT:
     *   With ETH: new FunctionsPayableSolution{value: 1 ether}()
     *   Without: new FunctionsPayableSolution()
     */
    constructor() payable {
        owner = msg.sender;

        // If ETH sent during deployment, emit event
        if (msg.value > 0) {
            emit Deposited(msg.sender, msg.value);
        }
    }

    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    // SPECIAL FUNCTIONS: receive() and fallback()
    // PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    /**
     * @notice Receives ETH sent with empty calldata
     * @dev Called when:
     *      - ETH sent to contract with empty msg.data
     *      - address(contract).transfer(amount)
     *      - address(contract).send(amount)
     *      - address(contract).call{value: amount}("")
     *
     * REQUIREMENTS:
     *   - Must be external
     *   - Must be payable
     *   - Cannot have arguments
     *   - Cannot return anything
     *
     * GAS: Only 2,300 gas when called via transfer/send
     *      All remaining gas when called via .call
     *
     * BEST PRACTICE: Keep logic minimal (gas limit concerns)
     *
     * PYTHON EQUIVALENT: __call__ magic method (but for ETH)
     * RUST EQUIVALENT: No direct equivalent (blockchain-specific)
     */
    receive() external payable {
        emit Received(msg.sender, msg.value);

        // NOTE: We don't update balances here
        //       This ETH goes to contract but isn't tracked per-user
        //       Could be used for contract funding, donations, etc.
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
     * HOW IT WORKS:
     *   1. User calls: contract.deposit{value: 1 ether}()
     *   2. msg.value contains ETH amount in wei
     *   3. ETH transferred to address(this)
     *   4. We track it in balances mapping
     *
     * WHY REQUIRE msg.value > 0?
     *   - Prevents useless transactions
     *   - Saves gas for users
     *   - Cleaner event logs
     *
     * GAS COST BREAKDOWN:
     *   - Transaction base: ~21,000 gas
     *   - SLOAD balance: ~100 gas (warm)
     *   - SSTORE balance: ~5,000 gas (warm, non-zero to non-zero)
     *   - Event: ~1,500 gas
     *   - Total: ~27,600 gas
     *
     * GAS OPTIMIZATION: Why use += instead of separate read/write?
     *   - balances[msg.sender] += msg.value: 1 SLOAD + 1 SSTORE = ~5,100 gas
     *   - Alternative: uint256 bal = balances[msg.sender]; bal += msg.value; balances[msg.sender] = bal;
     *     Costs: 1 SLOAD + 1 MLOAD + 1 SSTORE = ~5,103 gas
     *   - Savings: ~3 gas (minimal, but += is cleaner)
     *
     * REAL-WORLD ANALOGY: Like depositing cash at a bank - the money goes
     * into the bank's vault (contract balance), and your account balance
     * (mapping) is updated to reflect the deposit.
     *
     * COMPARISON:
     *   TypeScript: No built-in money, would be just numbers
     *   Go: No built-in money, would be just numbers
     *   Rust: No built-in money, would be just numbers
     *   Solidity: Real ETH, permanent blockchain state
     */
    function deposit() public payable {
        require(msg.value > 0, "Must send ETH");

        // SECURITY: No reentrancy risk here (no external calls)
        // GAS: 1 SLOAD + 1 SSTORE = ~5,100 gas (warm)
        balances[msg.sender] += msg.value;

        // GAS: Event emission = ~1,500 gas
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
