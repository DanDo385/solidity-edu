// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Project 31: Advanced Reentrancy Lab
 * @notice Educational contracts demonstrating advanced reentrancy vulnerabilities
 * @dev These contracts are INTENTIONALLY VULNERABLE for learning purposes
 */

// =============================================================================
// VULNERABLE CONTRACT 1: Multi-Function Reentrancy
// =============================================================================

/**
 * @notice Bank with withdraw and transfer functions
 * @dev VULNERABLE: Shared state between functions enables cross-function reentrancy
 */
contract VulnerableBank {
    mapping(address => uint256) public balances;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw funds from the bank
     * @dev VULNERABLE: Updates state after external call
     * TODO: Identify the vulnerability
     */
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // External call before state update
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        balances[msg.sender] -= amount;
        emit Withdrawal(msg.sender, amount);
    }

    /**
     * @notice Transfer balance to another address
     * @dev VULNERABLE: Can be called during withdraw callback
     * TODO: How can this be exploited during withdraw()?
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

// =============================================================================
// ATTACKER TEMPLATE 1: Multi-Function Reentrancy
// =============================================================================

/**
 * @notice Template for attacking VulnerableBank
 * @dev TODO: Complete the attack logic
 */
contract MultiFunctionAttacker {
    VulnerableBank public bank;
    address public accomplice;
    uint256 public attackAmount;

    constructor(address _bank, address _accomplice) {
        bank = VulnerableBank(_bank);
        accomplice = _accomplice;
    }

    /**
     * @notice Start the attack
     * @dev TODO: Implement the attack sequence
     * HINT: 1. Deposit funds, 2. Call withdraw, 3. In receive(), call transfer
     */
    function attack() external payable {
        // TODO: Implement attack
        // Step 1: Deposit some ETH to the bank

        // Step 2: Store the attack amount

        // Step 3: Call withdraw to trigger the reentrancy
    }

    /**
     * @notice Receive function - called during withdraw
     * @dev TODO: Implement reentrancy logic
     * HINT: Call transfer() to move funds before withdraw completes
     */
    receive() external payable {
        // TODO: Implement reentrancy
        // During the withdraw callback, call transfer to move funds
    }

    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }
}

// =============================================================================
// VULNERABLE CONTRACT 2: Cross-Contract Reentrancy
// =============================================================================

/**
 * @notice Vault that notifies a rewards contract on deposits
 * @dev VULNERABLE: External call creates reentrancy opportunity
 */
contract VulnerableVault {
    mapping(address => uint256) public balances;
    RewardsRouter public rewardsRouter;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    constructor(address _rewardsRouter) {
        rewardsRouter = RewardsRouter(_rewardsRouter);
    }

    /**
     * @notice Deposit ETH into the vault
     * @dev VULNERABLE: Notifies external contract before deposit completes
     * TODO: Find the reentrancy vector
     */
    function deposit() external payable {
        balances[msg.sender] += msg.value;

        // VULNERABLE: External call during state transition
        // TODO: How can this be exploited?
        rewardsRouter.notifyDeposit(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw funds from the vault
     * @dev TODO: Is this function safe? Why or why not?
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
 * @notice Rewards router that notifies users
 * @dev Part of cross-contract reentrancy attack vector
 */
contract RewardsRouter {
    event RewardNotification(address indexed user, uint256 amount);

    /**
     * @notice Notify user of deposit
     * @dev VULNERABLE: Calls back to user during vault deposit
     * TODO: Understand how this enables reentrancy
     */
    function notifyDeposit(address user, uint256 amount) external {
        emit RewardNotification(user, amount);

        // Callback to user - this is the reentrancy vector!
        // TODO: How does this enable attacking the vault?
        (bool success,) = user.call("");
        require(success);
    }
}

// =============================================================================
// ATTACKER TEMPLATE 2: Cross-Contract Reentrancy
// =============================================================================

/**
 * @notice Template for cross-contract reentrancy attack
 * @dev TODO: Complete the attack logic
 */
contract CrossContractAttacker {
    VulnerableVault public vault;
    bool public attacking;

    constructor(address _vault) {
        vault = VulnerableVault(_vault);
    }

    /**
     * @notice Start the attack
     * @dev TODO: Implement the attack
     * HINT: deposit() -> notifyDeposit() -> receive() -> withdraw()
     */
    function attack() external payable {
        // TODO: Implement attack
        // Step 1: Set attacking flag

        // Step 2: Call vault.deposit() with the sent ETH
        // This will trigger: deposit -> notifyDeposit -> receive -> withdraw

        // Step 3: Clean up
    }

    /**
     * @notice Receive function - called by RewardsRouter
     * @dev TODO: Implement reentrancy logic
     * HINT: This is called during deposit(), so reenter via withdraw()
     */
    receive() external payable {
        // TODO: Implement reentrancy
        // Check if we're attacking

        // If so, call vault.withdraw() before deposit completes
    }

    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }
}

// =============================================================================
// VULNERABLE CONTRACT 3: Read-Only Reentrancy
// =============================================================================

/**
 * @notice Vault with price oracle functionality
 * @dev VULNERABLE: View functions expose inconsistent state during reentrancy
 */
contract VulnerableOracle {
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
     * @notice Withdraw funds
     * @dev VULNERABLE: totalSupply updated AFTER external call
     * TODO: What is the issue with the order of operations?
     */
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;

        // External call happens here
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        // VULNERABLE: totalSupply updated AFTER the call
        // TODO: What state is visible to view functions during the call?
        totalSupply -= amount;

        emit Withdrawal(msg.sender, amount);
    }

    /**
     * @notice Get the price per share
     * @dev VULNERABLE: Reads inconsistent state during reentrancy
     * TODO: How can this return incorrect values during withdraw?
     */
    function getPrice() external view returns (uint256) {
        if (totalSupply == 0) return 1e18;
        // Price = (total ETH * 1e18) / totalSupply
        // TODO: What happens if this is called during withdraw()?
        return (address(this).balance * 1e18) / totalSupply;
    }

    /**
     * @notice Get total value locked
     * @dev TODO: Is this function safe during reentrancy?
     */
    function getTVL() external view returns (uint256) {
        return address(this).balance;
    }
}

/**
 * @notice Lending protocol that uses the oracle
 * @dev Can be exploited via read-only reentrancy
 */
contract SimpleLender {
    VulnerableOracle public oracle;
    mapping(address => uint256) public collateral;
    mapping(address => uint256) public debt;

    constructor(address _oracle) {
        oracle = VulnerableOracle(_oracle);
    }

    /**
     * @notice Deposit collateral
     */
    function depositCollateral() external payable {
        collateral[msg.sender] += msg.value;
    }

    /**
     * @notice Borrow against collateral
     * @dev VULNERABLE: Uses oracle price which can be manipulated
     * TODO: How can read-only reentrancy exploit this?
     */
    function borrow(uint256 amount) external {
        uint256 price = oracle.getPrice();
        uint256 collateralValue = collateral[msg.sender] * price / 1e18;
        uint256 maxBorrow = (collateralValue * 80) / 100; // 80% LTV

        require(debt[msg.sender] + amount <= maxBorrow, "Insufficient collateral");

        debt[msg.sender] += amount;
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    receive() external payable {}
}

// =============================================================================
// ATTACKER TEMPLATE 3: Read-Only Reentrancy
// =============================================================================

/**
 * @notice Template for read-only reentrancy attack
 * @dev TODO: Complete the attack logic
 */
contract ReadOnlyAttacker {
    VulnerableOracle public oracle;
    SimpleLender public lender;
    bool public attacking;

    constructor(address _oracle, address _lender) {
        oracle = VulnerableOracle(_oracle);
        lender = SimpleLender(payable(_lender));
    }

    /**
     * @notice Setup attack
     * @dev TODO: Deposit to oracle and lender
     */
    function setup() external payable {
        // TODO: Deposit half to oracle

        // TODO: Deposit half to lender as collateral
    }

    /**
     * @notice Execute the attack
     * @dev TODO: Trigger read-only reentrancy
     * HINT: withdraw() -> receive() -> check price -> borrow
     */
    function attack() external {
        // TODO: Implement attack
        // Step 1: Set attacking flag

        // Step 2: Call oracle.withdraw() to trigger reentrancy

        // Step 3: Clean up
    }

    /**
     * @notice Receive function
     * @dev TODO: Exploit the manipulated oracle price
     * HINT: During callback, getPrice() returns inflated value
     */
    receive() external payable {
        // TODO: Implement reentrancy
        // During oracle.withdraw(), the price is inflated
        // Use this window to borrow more from the lender
    }

    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }
}

// =============================================================================
// VULNERABLE CONTRACT 4: Multi-Hop Reentrancy
// =============================================================================

/**
 * @notice Contract A in a multi-hop chain
 * @dev VULNERABLE: Can be reentered through complex call path
 */
contract ContractA {
    mapping(address => uint256) public balances;
    ContractB public contractB;

    constructor(address _contractB) {
        contractB = ContractB(_contractB);
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    /**
     * @notice Process action through ContractB
     * @dev VULNERABLE: Creates multi-hop reentrancy opportunity
     * TODO: Trace the full call path
     */
    function processAction() external {
        require(balances[msg.sender] > 0, "No balance");

        // Call ContractB - this starts the chain
        // TODO: Map out: A -> B -> C -> callback -> A
        contractB.processB(msg.sender);

        // State update happens here
        // TODO: Can this be exploited?
        balances[msg.sender] = 0;
    }

    /**
     * @notice Withdraw remaining balance
     * @dev TODO: Can this be called during processAction()?
     */
    function withdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance");

        balances[msg.sender] = 0;

        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    receive() external payable {}
}

/**
 * @notice Contract B in the multi-hop chain
 */
contract ContractB {
    ContractC public contractC;

    constructor(address _contractC) {
        contractC = ContractC(_contractC);
    }

    /**
     * @notice Process and forward to ContractC
     * @dev Part of multi-hop chain: A -> B -> C
     */
    function processB(address user) external {
        // Forward to ContractC
        contractC.processC(user);
    }
}

/**
 * @notice Contract C in the multi-hop chain
 */
contract ContractC {
    /**
     * @notice Process and callback to user
     * @dev Completes the chain: A -> B -> C -> user
     */
    function processC(address user) external {
        // Callback to user - reentrancy opportunity!
        // TODO: What can the user do in this callback?
        (bool success,) = user.call("");
        require(success);
    }
}

// =============================================================================
// ATTACKER TEMPLATE 4: Multi-Hop Reentrancy
// =============================================================================

/**
 * @notice Template for multi-hop reentrancy attack
 * @dev TODO: Complete the attack logic
 */
contract MultiHopAttacker {
    ContractA public contractA;
    uint256 public callCount;

    constructor(address _contractA) {
        contractA = ContractA(_contractA);
    }

    /**
     * @notice Execute the attack
     * @dev TODO: Trigger multi-hop reentrancy
     */
    function attack() external payable {
        // TODO: Implement attack
        // Step 1: Deposit to ContractA

        // Step 2: Call processAction()
        // This triggers: A -> B -> C -> receive() -> A.withdraw()
    }

    /**
     * @notice Receive function - called by ContractC
     * @dev TODO: Reenter ContractA
     * HINT: We're in the middle of processAction(), can call withdraw()
     */
    receive() external payable {
        // TODO: Implement reentrancy
        // We're being called from ContractC during processAction()
        // ContractA.balances[this] is still non-zero
        // Call withdraw() to extract funds before processAction() completes

        // Limit reentrancy depth
    }

    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }
}

// =============================================================================
// HELPER CONTRACTS
// =============================================================================

/**
 * @notice Simple counter to track call depth
 */
contract CallDepthTracker {
    uint256 public currentDepth;
    uint256 public maxDepth;

    function incrementDepth() external {
        currentDepth++;
        if (currentDepth > maxDepth) {
            maxDepth = currentDepth;
        }
    }

    function decrementDepth() external {
        if (currentDepth > 0) {
            currentDepth--;
        }
    }

    function reset() external {
        currentDepth = 0;
        maxDepth = 0;
    }
}
