// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Multi-Asset Vault - Complete Solution
 * @notice A sophisticated vault holding multiple ERC20 tokens with weighted allocations
 * @dev Implements index fund patterns with dynamic rebalancing and oracle pricing
 */

interface IPriceOracle {
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function decimals() external view returns (uint8);
}

interface IDEXRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
}

contract MultiAssetVaultSolution is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ========== STRUCTS ==========

    struct Asset {
        address token;
        uint256 targetWeight; // Basis points (10000 = 100%)
        address priceOracle;
        bool active;
    }

    // ========== STATE VARIABLES ==========

    Asset[] public assets;
    mapping(address => uint256) public assetIndex;
    mapping(address => bool) public isAsset;

    uint256 public rebalanceThreshold; // Max deviation (basis points)
    uint256 public lastRebalanceTime;
    uint256 public minRebalanceInterval;
    address public dexRouter;

    address public baseAsset;
    uint256 public depositFee;
    uint256 public withdrawFee;

    uint256 public totalDeposited;
    uint256 public totalWithdrawn;
    uint256 public cumulativeSlippage;
    uint256 public rebalanceCount;

    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant MAX_ASSETS = 20;
    uint256 public constant PRICE_PRECISION = 1e18;
    uint256 public constant MAX_PRICE_AGE = 1 hours;

    // ========== EVENTS ==========

    event AssetAdded(address indexed token, uint256 targetWeight, address oracle);
    event AssetRemoved(address indexed token);
    event WeightUpdated(address indexed token, uint256 oldWeight, uint256 newWeight);
    event Deposited(address indexed user, uint256 assetAmount, uint256 shares, uint256 nav);
    event Withdrawn(address indexed user, uint256 shares, uint256 assetAmount, uint256 nav);
    event Rebalanced(
        address indexed fromAsset, address indexed toAsset, uint256 amountIn, uint256 amountOut, uint256 slippage
    );
    event ConfigUpdated(string param, uint256 value);

    // ========== ERRORS ==========

    error InvalidAddress();
    error InvalidWeight();
    error TooManyAssets();
    error WeightsMustEqual100();
    error AssetNotFound();
    error AssetAlreadyExists();
    error InsufficientShares();
    error InvalidAmount();
    error RebalanceNotNeeded();
    error RebalanceTooSoon();
    error StalePrice();
    error InvalidPrice();
    error ExcessiveSlippage();

    // ========== CONSTRUCTOR ==========

    constructor(
        string memory name,
        string memory symbol,
        address _baseAsset,
        address _dexRouter,
        uint256 _rebalanceThreshold
    ) ERC20(name, symbol) Ownable(msg.sender) {
        if (_baseAsset == address(0) || _dexRouter == address(0)) revert InvalidAddress();

        baseAsset = _baseAsset;
        dexRouter = _dexRouter;
        rebalanceThreshold = _rebalanceThreshold;
        minRebalanceInterval = 1 hours;
        depositFee = 10; // 0.1%
        withdrawFee = 10; // 0.1%
    }

    // ========== ASSET MANAGEMENT ==========

    function addAsset(address token, uint256 targetWeight, address oracle) external onlyOwner {
        if (token == address(0) || oracle == address(0)) revert InvalidAddress();
        if (targetWeight == 0) revert InvalidWeight();
        if (assets.length >= MAX_ASSETS) revert TooManyAssets();
        if (isAsset[token]) revert AssetAlreadyExists();

        // Verify total weights don't exceed 100%
        uint256 totalWeight = getTotalWeight() + targetWeight;
        if (totalWeight > BASIS_POINTS) revert WeightsMustEqual100();

        // Add asset
        assetIndex[token] = assets.length;
        isAsset[token] = true;

        assets.push(Asset({token: token, targetWeight: targetWeight, priceOracle: oracle, active: true}));

        emit AssetAdded(token, targetWeight, oracle);
    }

    function removeAsset(address token) external onlyOwner {
        if (!isAsset[token]) revert AssetNotFound();

        uint256 idx = assetIndex[token];

        // Ensure no balance remains
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance == 0, "Asset has balance, sell first");

        // Mark as inactive (don't remove to preserve indices)
        assets[idx].active = false;
        isAsset[token] = false;

        emit AssetRemoved(token);
    }

    function setTargetWeight(address token, uint256 newWeight) external onlyOwner {
        if (!isAsset[token]) revert AssetNotFound();
        if (newWeight == 0) revert InvalidWeight();

        uint256 idx = assetIndex[token];
        uint256 oldWeight = assets[idx].targetWeight;

        assets[idx].targetWeight = newWeight;

        // Verify total weights equal 100%
        if (getTotalWeight() != BASIS_POINTS) revert WeightsMustEqual100();

        emit WeightUpdated(token, oldWeight, newWeight);
    }

    // ========== NAV CALCULATION ==========

    function calculateNAV() public view returns (uint256) {
        uint256 totalValue = 0;

        for (uint256 i = 0; i < assets.length; i++) {
            if (!assets[i].active) continue;

            uint256 value = getAssetValue(assets[i].token);
            totalValue += value;
        }

        return totalValue;
    }

    function getPricePerShare() public view returns (uint256) {
        uint256 supply = totalSupply();
        if (supply == 0) return PRICE_PRECISION;

        uint256 nav = calculateNAV();
        return (nav * PRICE_PRECISION) / supply;
    }

    function getAssetValue(address token) public view returns (uint256) {
        if (!isAsset[token]) return 0;

        uint256 idx = assetIndex[token];
        if (!assets[idx].active) return 0;

        // Get balance
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance == 0) return 0;

        // Get price
        uint256 price = getOraclePrice(assets[idx].priceOracle);

        // Get token decimals
        uint8 tokenDecimals = ERC20(token).decimals();

        // Calculate value: balance * price, normalized to 18 decimals
        // balance is in token decimals, price is in 18 decimals
        // result should be in 18 decimals (base asset terms)
        uint256 value = (balance * price) / (10 ** tokenDecimals);

        return value;
    }

    function getOraclePrice(address oracle) public view returns (uint256) {
        IPriceOracle priceFeed = IPriceOracle(oracle);

        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            priceFeed.latestRoundData();

        // Validate price data
        if (answer <= 0) revert InvalidPrice();
        if (updatedAt == 0) revert StalePrice();
        if (block.timestamp - updatedAt > MAX_PRICE_AGE) revert StalePrice();
        if (answeredInRound < roundId) revert StalePrice();

        // Get oracle decimals and normalize to 18 decimals
        uint8 oracleDecimals = priceFeed.decimals();
        uint256 price = uint256(answer);

        if (oracleDecimals < 18) {
            price = price * (10 ** (18 - oracleDecimals));
        } else if (oracleDecimals > 18) {
            price = price / (10 ** (oracleDecimals - 18));
        }

        return price;
    }

    // ========== CURRENT ALLOCATION ==========

    function getCurrentWeights() public view returns (uint256[] memory weights) {
        weights = new uint256[](assets.length);
        uint256 totalNAV = calculateNAV();

        if (totalNAV == 0) return weights;

        for (uint256 i = 0; i < assets.length; i++) {
            if (!assets[i].active) continue;

            uint256 value = getAssetValue(assets[i].token);
            weights[i] = (value * BASIS_POINTS) / totalNAV;
        }

        return weights;
    }

    function needsRebalancing() public view returns (bool) {
        // Check minimum interval
        if (block.timestamp < lastRebalanceTime + minRebalanceInterval) {
            return false;
        }

        uint256[] memory currentWeights = getCurrentWeights();

        for (uint256 i = 0; i < assets.length; i++) {
            if (!assets[i].active) continue;

            uint256 targetWeight = assets[i].targetWeight;
            uint256 currentWeight = currentWeights[i];

            // Calculate absolute deviation
            uint256 deviation = currentWeight > targetWeight
                ? currentWeight - targetWeight
                : targetWeight - currentWeight;

            if (deviation > rebalanceThreshold) {
                return true;
            }
        }

        return false;
    }

    // ========== DEPOSIT / WITHDRAW ==========

    function deposit(uint256 amount) external nonReentrant returns (uint256 shares) {
        if (amount == 0) revert InvalidAmount();

        // Transfer base asset from user
        IERC20(baseAsset).safeTransferFrom(msg.sender, address(this), amount);

        // Calculate shares to mint
        uint256 supply = totalSupply();
        if (supply == 0) {
            // First deposit: 1:1 ratio
            shares = amount;
        } else {
            // shares = (amount * totalSupply) / NAV
            uint256 nav = calculateNAV();
            shares = (amount * supply) / nav;
        }

        // Apply deposit fee
        uint256 fee = (shares * depositFee) / BASIS_POINTS;
        shares -= fee;

        if (shares == 0) revert InvalidAmount();

        // Mint shares
        _mint(msg.sender, shares);

        // Update tracking
        totalDeposited += amount;

        // Optionally allocate to basket immediately
        // (For simplicity, we'll wait for rebalancing)

        emit Deposited(msg.sender, amount, shares, calculateNAV());

        return shares;
    }

    function withdraw(uint256 shares) external nonReentrant returns (uint256 baseAmount) {
        if (shares == 0) revert InvalidAmount();
        if (balanceOf(msg.sender) < shares) revert InsufficientShares();

        // Calculate proportion of vault
        uint256 supply = totalSupply();
        uint256 proportion = (shares * PRICE_PRECISION) / supply;

        // Burn shares first
        _burn(msg.sender, shares);

        // Strategy: Convert all assets to base and return base asset
        // Alternative: Return proportional basket (more complex)

        baseAmount = 0;

        for (uint256 i = 0; i < assets.length; i++) {
            if (!assets[i].active) continue;

            address token = assets[i].token;
            uint256 balance = IERC20(token).balanceOf(address(this));

            if (balance == 0) continue;

            uint256 withdrawAmount = (balance * proportion) / PRICE_PRECISION;

            if (token == baseAsset) {
                baseAmount += withdrawAmount;
            } else if (withdrawAmount > 0) {
                // Swap to base asset
                uint256 received = _swapToBase(token, withdrawAmount);
                baseAmount += received;
            }
        }

        // Apply withdrawal fee
        uint256 fee = (baseAmount * withdrawFee) / BASIS_POINTS;
        baseAmount -= fee;

        if (baseAmount == 0) revert InvalidAmount();

        // Transfer base asset to user
        IERC20(baseAsset).safeTransfer(msg.sender, baseAmount);

        // Update tracking
        totalWithdrawn += baseAmount;

        emit Withdrawn(msg.sender, shares, baseAmount, calculateNAV());

        return baseAmount;
    }

    function previewDeposit(uint256 amount) external view returns (uint256 shares) {
        if (amount == 0) return 0;

        uint256 supply = totalSupply();
        if (supply == 0) {
            shares = amount;
        } else {
            uint256 nav = calculateNAV();
            shares = (amount * supply) / nav;
        }

        // Apply fee
        uint256 fee = (shares * depositFee) / BASIS_POINTS;
        shares -= fee;

        return shares;
    }

    function previewWithdraw(uint256 shares) external view returns (uint256 amount) {
        if (shares == 0) return 0;

        uint256 supply = totalSupply();
        if (supply == 0) return 0;

        uint256 nav = calculateNAV();
        amount = (shares * nav) / supply;

        // Apply fee
        uint256 fee = (amount * withdrawFee) / BASIS_POINTS;
        amount -= fee;

        return amount;
    }

    // ========== REBALANCING ==========

    function rebalance() external nonReentrant {
        if (!needsRebalancing()) revert RebalanceNotNeeded();

        uint256 totalNAV = calculateNAV();
        uint256[] memory currentWeights = getCurrentWeights();

        // Execute rebalancing swaps
        for (uint256 i = 0; i < assets.length; i++) {
            if (!assets[i].active) continue;

            uint256 targetWeight = assets[i].targetWeight;
            uint256 currentWeight = currentWeights[i];

            // Skip if already at target
            if (currentWeight == targetWeight) continue;

            uint256 targetValue = (totalNAV * targetWeight) / BASIS_POINTS;
            uint256 currentValue = getAssetValue(assets[i].token);

            if (currentValue > targetValue) {
                // Sell excess (swap to base asset)
                uint256 excessValue = currentValue - targetValue;
                _sellAsset(assets[i].token, excessValue);
            }
        }

        // Buy underweight assets with accumulated base asset
        for (uint256 i = 0; i < assets.length; i++) {
            if (!assets[i].active) continue;

            uint256 targetWeight = assets[i].targetWeight;
            uint256 currentWeight = currentWeights[i];

            uint256 targetValue = (totalNAV * targetWeight) / BASIS_POINTS;
            uint256 currentValue = getAssetValue(assets[i].token);

            if (currentValue < targetValue) {
                // Buy deficit
                uint256 deficitValue = targetValue - currentValue;
                _buyAsset(assets[i].token, deficitValue);
            }
        }

        lastRebalanceTime = block.timestamp;
        rebalanceCount++;
    }

    function _sellAsset(address token, uint256 targetValue) internal {
        if (token == baseAsset) return; // Already in base asset

        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance == 0) return;

        // Calculate amount to sell based on value
        uint256 price = getOraclePrice(assets[assetIndex[token]].priceOracle);
        uint8 decimals = ERC20(token).decimals();
        uint256 amountToSell = (targetValue * (10 ** decimals)) / price;

        // Don't sell more than we have
        if (amountToSell > balance) {
            amountToSell = balance;
        }

        if (amountToSell > 0) {
            _swapToBase(token, amountToSell);
        }
    }

    function _buyAsset(address token, uint256 targetValue) internal {
        if (token == baseAsset) return; // Already in base asset

        uint256 baseBalance = IERC20(baseAsset).balanceOf(address(this));
        if (baseBalance == 0) return;

        // Use available base asset (capped at target value)
        uint256 amountToSpend = targetValue < baseBalance ? targetValue : baseBalance;

        if (amountToSpend > 0) {
            _swapFromBase(token, amountToSpend);
        }
    }

    function _swapToBase(address fromToken, uint256 amountIn) internal returns (uint256 amountOut) {
        if (amountIn == 0) return 0;

        // Get expected output
        address[] memory path = new address[](2);
        path[0] = fromToken;
        path[1] = baseAsset;

        uint256[] memory expectedAmounts = IDEXRouter(dexRouter).getAmountsOut(amountIn, path);
        uint256 expectedOut = expectedAmounts[1];

        // Apply slippage tolerance (1%)
        uint256 minOut = (expectedOut * 9900) / BASIS_POINTS;

        // Approve and swap
        IERC20(fromToken).safeIncreaseAllowance(dexRouter, amountIn);

        uint256[] memory amounts =
            IDEXRouter(dexRouter).swapExactTokensForTokens(amountIn, minOut, path, address(this), block.timestamp);

        amountOut = amounts[1];

        // Track slippage
        if (expectedOut > amountOut) {
            uint256 slippage = ((expectedOut - amountOut) * BASIS_POINTS) / expectedOut;
            cumulativeSlippage += slippage;
        }

        emit Rebalanced(fromToken, baseAsset, amountIn, amountOut, cumulativeSlippage);

        return amountOut;
    }

    function _swapFromBase(address toToken, uint256 amountIn) internal returns (uint256 amountOut) {
        if (amountIn == 0) return 0;

        // Get expected output
        address[] memory path = new address[](2);
        path[0] = baseAsset;
        path[1] = toToken;

        uint256[] memory expectedAmounts = IDEXRouter(dexRouter).getAmountsOut(amountIn, path);
        uint256 expectedOut = expectedAmounts[1];

        // Apply slippage tolerance (1%)
        uint256 minOut = (expectedOut * 9900) / BASIS_POINTS;

        // Approve and swap
        IERC20(baseAsset).safeIncreaseAllowance(dexRouter, amountIn);

        uint256[] memory amounts =
            IDEXRouter(dexRouter).swapExactTokensForTokens(amountIn, minOut, path, address(this), block.timestamp);

        amountOut = amounts[1];

        // Track slippage
        if (expectedOut > amountOut) {
            uint256 slippage = ((expectedOut - amountOut) * BASIS_POINTS) / expectedOut;
            cumulativeSlippage += slippage;
        }

        emit Rebalanced(baseAsset, toToken, amountIn, amountOut, cumulativeSlippage);

        return amountOut;
    }

    function calculateRebalanceAmounts()
        public
        view
        returns (uint256[] memory sells, uint256[] memory buys)
    {
        sells = new uint256[](assets.length);
        buys = new uint256[](assets.length);

        uint256 totalNAV = calculateNAV();
        if (totalNAV == 0) return (sells, buys);

        for (uint256 i = 0; i < assets.length; i++) {
            if (!assets[i].active) continue;

            uint256 targetValue = (totalNAV * assets[i].targetWeight) / BASIS_POINTS;
            uint256 currentValue = getAssetValue(assets[i].token);

            if (currentValue > targetValue) {
                sells[i] = currentValue - targetValue;
            } else if (currentValue < targetValue) {
                buys[i] = targetValue - currentValue;
            }
        }

        return (sells, buys);
    }

    // ========== ADMIN FUNCTIONS ==========

    function setRebalanceThreshold(uint256 _threshold) external onlyOwner {
        require(_threshold <= 1000, "Threshold too high");
        rebalanceThreshold = _threshold;
        emit ConfigUpdated("rebalanceThreshold", _threshold);
    }

    function setMinRebalanceInterval(uint256 _interval) external onlyOwner {
        minRebalanceInterval = _interval;
        emit ConfigUpdated("minRebalanceInterval", _interval);
    }

    function setDepositFee(uint256 _fee) external onlyOwner {
        require(_fee <= 100, "Fee too high");
        depositFee = _fee;
        emit ConfigUpdated("depositFee", _fee);
    }

    function setWithdrawFee(uint256 _fee) external onlyOwner {
        require(_fee <= 100, "Fee too high");
        withdrawFee = _fee;
        emit ConfigUpdated("withdrawFee", _fee);
    }

    function setDEXRouter(address _router) external onlyOwner {
        if (_router == address(0)) revert InvalidAddress();
        dexRouter = _router;
    }

    // Emergency function to recover stuck tokens
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
    }

    // ========== VIEW FUNCTIONS ==========

    function getAssetCount() external view returns (uint256) {
        return assets.length;
    }

    function getAsset(uint256 index) external view returns (Asset memory) {
        return assets[index];
    }

    function getTotalWeight() public view returns (uint256 total) {
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i].active) {
                total += assets[i].targetWeight;
            }
        }
    }

    function getPerformanceMetrics()
        external
        view
        returns (uint256 avgSlippage, uint256 deposited, uint256 withdrawn, uint256 rebalances)
    {
        avgSlippage = rebalanceCount > 0 ? cumulativeSlippage / rebalanceCount : 0;
        deposited = totalDeposited;
        withdrawn = totalWithdrawn;
        rebalances = rebalanceCount;
    }

    function getAllAssets() external view returns (Asset[] memory) {
        return assets;
    }

    function getActiveAssets() external view returns (address[] memory activeTokens) {
        uint256 count = 0;
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i].active) count++;
        }

        activeTokens = new address[](count);
        uint256 j = 0;
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i].active) {
                activeTokens[j] = assets[i].token;
                j++;
            }
        }

        return activeTokens;
    }
}
