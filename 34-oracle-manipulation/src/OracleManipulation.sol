// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Project 34: Oracle Manipulation Attack
 * @notice Educational project demonstrating oracle manipulation vulnerabilities
 *
 * LEARNING OBJECTIVES:
 * 1. Understand how oracle manipulation works
 * 2. Implement flashloan-based price manipulation
 * 3. Recognize vulnerable oracle patterns
 * 4. Build secure oracle implementations
 *
 * SCENARIO:
 * - A simple lending protocol uses an AMM for price oracles
 * - The AMM uses spot price (vulnerable to manipulation)
 * - Attacker can use flashloans to manipulate the price
 * - By manipulating collateral value, attacker can over-borrow
 *
 * YOUR TASK:
 * Complete the Attacker contract to exploit the oracle vulnerability
 */

// Simple ERC20 token for testing
contract Token {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol, uint256 _initialSupply) {
        name = _name;
        symbol = _symbol;
        totalSupply = _initialSupply;
        balanceOf[msg.sender] = _initialSupply;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function mint(address to, uint256 amount) external {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }
}

/**
 * @title SimpleAMM
 * @notice A basic AMM (like Uniswap V2) for token swaps
 * @dev Uses constant product formula: x * y = k
 */
contract SimpleAMM {
    Token public token0;
    Token public token1;

    uint256 public reserve0;
    uint256 public reserve1;

    event Swap(
        address indexed user,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out
    );

    event LiquidityAdded(address indexed provider, uint256 amount0, uint256 amount1);

    constructor(address _token0, address _token1) {
        token0 = Token(_token0);
        token1 = Token(_token1);
    }

    /**
     * @notice Add liquidity to the pool
     */
    function addLiquidity(uint256 amount0, uint256 amount1) external {
        token0.transferFrom(msg.sender, address(this), amount0);
        token1.transferFrom(msg.sender, address(this), amount1);

        reserve0 += amount0;
        reserve1 += amount1;

        emit LiquidityAdded(msg.sender, amount0, amount1);
    }

    /**
     * @notice Swap token0 for token1
     * @dev Uses constant product formula
     */
    function swap(address tokenIn, uint256 amountIn) external returns (uint256 amountOut) {
        require(
            tokenIn == address(token0) || tokenIn == address(token1),
            "Invalid token"
        );

        bool isToken0 = tokenIn == address(token0);

        (Token tokenInContract, Token tokenOutContract, uint256 reserveIn, uint256 reserveOut) =
        isToken0
            ? (token0, token1, reserve0, reserve1)
            : (token1, token0, reserve1, reserve0);

        // Transfer tokens in
        tokenInContract.transferFrom(msg.sender, address(this), amountIn);

        // Calculate amount out using constant product formula
        // amountOut = (reserveOut * amountIn) / (reserveIn + amountIn)
        uint256 amountInWithFee = amountIn * 997; // 0.3% fee
        amountOut = (reserveOut * amountInWithFee) / (reserveIn * 1000 + amountInWithFee);

        // Transfer tokens out
        tokenOutContract.transfer(msg.sender, amountOut);

        // Update reserves
        if (isToken0) {
            reserve0 += amountIn;
            reserve1 -= amountOut;
            emit Swap(msg.sender, amountIn, 0, 0, amountOut);
        } else {
            reserve1 += amountIn;
            reserve0 -= amountOut;
            emit Swap(msg.sender, 0, amountIn, amountOut, 0);
        }
    }

    /**
     * @notice Get the current spot price of token0 in terms of token1
     * @dev ⚠️ VULNERABLE: This is a spot price oracle that can be manipulated!
     * @return price The amount of token1 per 1e18 token0
     */
    function getPrice() external view returns (uint256 price) {
        require(reserve0 > 0 && reserve1 > 0, "No liquidity");
        // TODO: Why is this vulnerable?
        // HINT: This price can change within a single transaction
        price = (reserve1 * 1e18) / reserve0;
    }
}

/**
 * @title VulnerableLending
 * @notice A lending protocol that uses AMM spot price as oracle
 * @dev ⚠️ VULNERABLE: Uses manipulable spot price for collateral valuation
 */
contract VulnerableLending {
    SimpleAMM public oracle;
    Token public collateralToken; // token0 from AMM
    Token public borrowToken;     // token1 from AMM

    uint256 public constant COLLATERAL_RATIO = 150; // 150% collateralization required

    mapping(address => uint256) public deposits;
    mapping(address => uint256) public borrowed;

    event Deposit(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor(address _oracle, address _collateralToken, address _borrowToken) {
        oracle = SimpleAMM(_oracle);
        collateralToken = Token(_collateralToken);
        borrowToken = Token(_borrowToken);
    }

    /**
     * @notice Deposit collateral
     */
    function deposit(uint256 amount) external {
        collateralToken.transferFrom(msg.sender, address(this), amount);
        deposits[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }

    /**
     * @notice Borrow tokens using deposited collateral
     * @dev ⚠️ VULNERABLE: Uses spot price from AMM oracle
     */
    function borrow(uint256 amount) external {
        // TODO: Identify the vulnerability in this function
        // HINT: Where does the price come from?

        uint256 collateralAmount = deposits[msg.sender];
        require(collateralAmount > 0, "No collateral");

        // Get price from AMM oracle (VULNERABLE!)
        uint256 price = oracle.getPrice(); // token1 per token0

        // Calculate collateral value in terms of borrow token
        uint256 collateralValue = (collateralAmount * price) / 1e18;

        // Calculate maximum borrow (considering collateral ratio)
        uint256 maxBorrow = (collateralValue * 100) / COLLATERAL_RATIO;

        // Check if borrow is allowed
        uint256 totalBorrowed = borrowed[msg.sender] + amount;
        require(totalBorrowed <= maxBorrow, "Insufficient collateral");

        // Update state
        borrowed[msg.sender] += amount;

        // Transfer tokens
        borrowToken.transfer(msg.sender, amount);

        emit Borrow(msg.sender, amount);
    }

    /**
     * @notice Repay borrowed tokens
     */
    function repay(uint256 amount) external {
        borrowed[msg.sender] -= amount;
        borrowToken.transferFrom(msg.sender, address(this), amount);
        emit Repay(msg.sender, amount);
    }

    /**
     * @notice Withdraw collateral
     */
    function withdraw(uint256 amount) external {
        require(borrowed[msg.sender] == 0, "Outstanding debt");
        deposits[msg.sender] -= amount;
        collateralToken.transfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    /**
     * @notice Get user's health factor
     * @return health The health factor (100 = healthy, < 100 = liquidatable)
     */
    function getHealthFactor(address user) external view returns (uint256 health) {
        uint256 collateralAmount = deposits[user];
        uint256 borrowedAmount = borrowed[user];

        if (borrowedAmount == 0) return type(uint256).max;

        uint256 price = oracle.getPrice();
        uint256 collateralValue = (collateralAmount * price) / 1e18;

        health = (collateralValue * 100) / borrowedAmount;
    }
}

/**
 * @title FlashloanProvider
 * @notice Provides flashloans for attacking
 * @dev Simplified flashloan implementation
 */
interface IFlashloanReceiver {
    function onFlashloan(address token, uint256 amount, bytes calldata data) external;
}

contract FlashloanProvider {
    Token public token;

    event Flashloan(address indexed receiver, uint256 amount);

    constructor(address _token) {
        token = Token(_token);
    }

    /**
     * @notice Execute a flashloan
     * @param amount Amount to borrow
     * @param data Arbitrary data to pass to receiver
     */
    function flashloan(uint256 amount, bytes calldata data) external {
        uint256 balanceBefore = token.balanceOf(address(this));

        // Transfer tokens to caller
        token.transfer(msg.sender, amount);

        // Call receiver
        IFlashloanReceiver(msg.sender).onFlashloan(address(token), amount, data);

        // Verify repayment
        uint256 balanceAfter = token.balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "Flashloan not repaid");

        emit Flashloan(msg.sender, amount);
    }

    // Allow deposits to the pool
    function deposit(uint256 amount) external {
        token.transferFrom(msg.sender, address(this), amount);
    }
}

/**
 * @title Attacker
 * @notice Contract to exploit the oracle manipulation vulnerability
 *
 * ATTACK FLOW:
 * 1. Take flashloan of token1 (borrow token)
 * 2. Swap large amount of token1 for token0 in AMM
 *    → This increases reserve1 and decreases reserve0
 *    → Price of token0 (collateral) increases
 * 3. Deposit small amount of token0 as collateral
 * 4. Borrow maximum token1 using inflated collateral value
 * 5. Swap token0 back to token1 to restore price
 * 6. Repay flashloan
 * 7. Profit = borrowed amount - flashloan
 */
contract Attacker is IFlashloanReceiver {
    SimpleAMM public amm;
    VulnerableLending public lending;
    Token public token0; // collateral token
    Token public token1; // borrow token
    FlashloanProvider public flashloanProvider;

    constructor(
        address _amm,
        address _lending,
        address _token0,
        address _token1,
        address _flashloanProvider
    ) {
        amm = SimpleAMM(_amm);
        lending = VulnerableLending(_lending);
        token0 = Token(_token0);
        token1 = Token(_token1);
        flashloanProvider = FlashloanProvider(_flashloanProvider);
    }

    /**
     * @notice Start the attack
     * @param flashloanAmount Amount of token1 to flashloan
     * @param collateralAmount Amount of token0 to use as collateral
     */
    function attack(uint256 flashloanAmount, uint256 collateralAmount) external {
        // TODO: Implement the attack
        // STEP 1: Initiate flashloan
        // HINT: Call flashloanProvider.flashloan() with appropriate parameters

        // The attack logic continues in onFlashloan callback
    }

    /**
     * @notice Flashloan callback - this is where the attack happens
     * @param token The token borrowed
     * @param amount The amount borrowed
     * @param data Custom data (we'll encode collateralAmount here)
     */
    function onFlashloan(address token, uint256 amount, bytes calldata data) external {
        require(msg.sender == address(flashloanProvider), "Only flashloan provider");

        // TODO: Decode collateralAmount from data
        uint256 collateralAmount = abi.decode(data, (uint256));

        // TODO: STEP 2 - Manipulate the price upward
        // HINT: Swap token1 → token0 in the AMM
        // This will make token0 appear more valuable
        // You need to:
        // 1. Approve AMM to spend token1
        // 2. Execute swap

        // TODO: Check the price after manipulation
        // uint256 manipulatedPrice = amm.getPrice();

        // TODO: STEP 3 - Deposit collateral to lending protocol
        // HINT: Approve lending protocol to spend token0
        // Then deposit collateralAmount

        // TODO: STEP 4 - Borrow maximum amount using inflated collateral
        // HINT: Calculate how much you can borrow based on manipulated price
        // Call lending.borrow()

        // TODO: STEP 5 - Restore the price by swapping back
        // HINT: Swap token0 → token1 to restore reserves
        // This allows us to repay the flashloan

        // TODO: STEP 6 - Repay flashloan
        // HINT: Approve flashloan provider to take back the borrowed amount

        // Profit remains in this contract!
    }

    /**
     * @notice Calculate profit from attack
     */
    function getProfit() external view returns (uint256) {
        // TODO: Return the token1 balance (profit after attack)
        return token1.balanceOf(address(this));
    }

    // Allow receiving tokens
    receive() external payable {}
}

/**
 * QUESTIONS TO CONSIDER:
 *
 * 1. Why can the AMM spot price be manipulated within a single transaction?
 *
 * 2. How does the flashloan enable this attack without requiring capital?
 *
 * 3. What is the maximum profit the attacker can extract?
 *
 * 4. How would a TWAP oracle prevent this attack?
 *
 * 5. What other defenses could the lending protocol implement?
 *
 * 6. Could this attack work across multiple transactions? Why or why not?
 *
 * 7. How does liquidity depth affect the cost/feasibility of this attack?
 */
