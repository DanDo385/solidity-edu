// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title MetaVaultSolution
 * @notice A complete ERC-4626 meta-vault that wraps other ERC-4626 vaults
 * @dev Demonstrates yield aggregation, multi-vault management, and auto-rebalancing
 *
 * ARCHITECTURE:
 * This meta-vault is itself an ERC-4626 vault, but instead of directly managing
 * assets, it deposits them into other ERC-4626 vaults. This creates a recursive
 * structure where:
 * 1. Users deposit assets → receive meta-vault shares
 * 2. Meta-vault deposits assets → receives underlying vault shares
 * 3. Yields from underlying vaults accrue to meta-vault
 * 4. Meta-vault share value increases proportionally
 *
 * RECURSIVE MATH:
 * totalAssets() = sum(underlyingVault.convertToAssets(shares held))
 *
 * This recursive calculation means:
 * - User shares → Meta-vault assets calculation
 * - Meta-vault assets → Underlying vault shares → Actual assets
 *
 * YIELD COMPOUNDING:
 * If Vault A earns 10% and Meta-Vault adds 5% strategy alpha:
 * - Year 1: 100 → 110 (Vault A) → 115.5 (Meta-Vault)
 * - Effective APY: 15.5% (compound, not simple addition)
 */
contract MetaVaultSolution is ERC4626, Ownable, ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 public constant TOTAL_BPS = 10000; // 100% in basis points
    uint256 public constant MIN_REBALANCE_INTERVAL = 1 hours;
    uint256 public constant MAX_VAULTS = 10; // Reasonable limit

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    // Array of underlying ERC-4626 vaults
    IERC4626[] public underlyingVaults;

    // Quick lookup to check if address is a valid vault
    mapping(address => bool) public isVault;

    // Target allocation for each vault (in basis points, sum should = TOTAL_BPS)
    mapping(uint256 => uint256) public targetAllocations;

    // Configuration
    bool public autoRebalance; // Auto-rebalance on deposits to highest yield vault
    uint256 public lastRebalance; // Timestamp of last rebalance
    uint256 public rebalanceThreshold; // Minimum drift to trigger rebalance (in BPS)

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event VaultAdded(address indexed vault, uint256 targetAllocation);
    event VaultRemoved(address indexed vault);
    event Rebalanced(uint256 timestamp, uint256 totalAssets);
    event AllocationUpdated(uint256 indexed vaultIndex, uint256 newAllocation);
    event AutoRebalanceToggled(bool enabled);

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidAsset();
    error VaultAlreadyAdded();
    error VaultNotFound();
    error InvalidAllocation();
    error TooManyVaults();
    error RebalanceTooSoon();
    error InsufficientLiquidity();

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        IERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC4626(_asset) ERC20(_name, _symbol) Ownable(msg.sender) {
        rebalanceThreshold = 500; // 5% default threshold
    }

    /*//////////////////////////////////////////////////////////////
                        VAULT MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Add a new underlying vault to the meta-vault
     * @param vault The ERC-4626 vault to add
     * @param allocation Target allocation in basis points (0-10000)
     *
     * EXPLANATION:
     * When adding a vault, we need to ensure:
     * 1. It uses the same underlying asset (can't mix DAI and USDC vaults)
     * 2. It's not already added (prevent duplicates)
     * 3. Total allocations remain valid (sum ≤ 100%)
     * 4. We don't exceed maximum vault count (gas optimization)
     */
    function addVault(IERC4626 vault, uint256 allocation) external onlyOwner {
        // Verify the vault uses the same underlying asset as this meta-vault
        if (vault.asset() != asset()) revert InvalidAsset();

        // Prevent duplicate vaults
        if (isVault[address(vault)]) revert VaultAlreadyAdded();

        // Check max vaults limit (prevents excessive gas costs)
        if (underlyingVaults.length >= MAX_VAULTS) revert TooManyVaults();

        // Verify total allocations don't exceed 100%
        uint256 totalAllocation = allocation;
        for (uint256 i = 0; i < underlyingVaults.length; i++) {
            totalAllocation += targetAllocations[i];
        }
        if (totalAllocation > TOTAL_BPS) revert InvalidAllocation();

        // Add the vault
        uint256 vaultIndex = underlyingVaults.length;
        underlyingVaults.push(vault);
        isVault[address(vault)] = true;
        targetAllocations[vaultIndex] = allocation;

        emit VaultAdded(address(vault), allocation);
    }

    /**
     * @notice Remove a vault from the meta-vault
     * @param vaultIndex Index of the vault to remove
     *
     * EXPLANATION:
     * Removing a vault requires:
     * 1. Withdraw all our shares from that vault
     * 2. Remove it from our tracking arrays
     * 3. Keep withdrawn assets as idle (owner can rebalance later)
     *
     * NOTE: We use swap-and-pop for gas-efficient array removal
     */
    function removeVault(uint256 vaultIndex) external onlyOwner {
        if (vaultIndex >= underlyingVaults.length) revert VaultNotFound();

        IERC4626 vault = underlyingVaults[vaultIndex];

        // Withdraw all shares from this vault
        uint256 shares = vault.balanceOf(address(this));
        if (shares > 0) {
            vault.redeem(shares, address(this), address(this));
        }

        // Remove from mapping
        isVault[address(vault)] = false;

        // Swap with last element and pop (gas efficient removal)
        uint256 lastIndex = underlyingVaults.length - 1;
        if (vaultIndex != lastIndex) {
            underlyingVaults[vaultIndex] = underlyingVaults[lastIndex];
            targetAllocations[vaultIndex] = targetAllocations[lastIndex];
        }

        underlyingVaults.pop();
        delete targetAllocations[lastIndex];

        emit VaultRemoved(address(vault));
    }

    /**
     * @notice Update target allocation for a vault
     * @param vaultIndex Index of the vault
     * @param newAllocation New target allocation in basis points
     */
    function updateAllocation(uint256 vaultIndex, uint256 newAllocation) external onlyOwner {
        if (vaultIndex >= underlyingVaults.length) revert VaultNotFound();

        // Calculate total with new allocation
        uint256 totalAllocation = newAllocation;
        for (uint256 i = 0; i < underlyingVaults.length; i++) {
            if (i != vaultIndex) {
                totalAllocation += targetAllocations[i];
            }
        }

        if (totalAllocation > TOTAL_BPS) revert InvalidAllocation();

        targetAllocations[vaultIndex] = newAllocation;
        emit AllocationUpdated(vaultIndex, newAllocation);
    }

    /*//////////////////////////////////////////////////////////////
                    RECURSIVE ASSET CALCULATIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Calculate total assets held by this meta-vault
     * @return Total assets across all underlying vaults
     *
     * CRITICAL RECURSIVE LOGIC:
     * This is the heart of the meta-vault. We don't hold assets directly,
     * we hold shares in other vaults. So we must:
     *
     * 1. For each underlying vault, get our share balance
     * 2. Convert those shares to assets using vault.convertToAssets()
     * 3. Sum all the assets
     *
     * EXAMPLE:
     * MetaVault holds:
     * - 100 shares in VaultA (1 share = 1.1 assets) → 110 assets
     * - 200 shares in VaultB (1 share = 1.25 assets) → 250 assets
     * Total assets = 360
     *
     * When user has 50 meta-vault shares out of 100 total:
     * User's assets = 50 * 360 / 100 = 180 assets
     *
     * YIELD ACCUMULATION:
     * As underlying vaults earn yield, their share-to-asset ratio increases.
     * This automatically increases our totalAssets(), which increases our
     * share-to-asset ratio, benefiting our users!
     */
    function totalAssets() public view virtual override returns (uint256) {
        uint256 total = 0;

        // Add assets from all underlying vaults
        for (uint256 i = 0; i < underlyingVaults.length; i++) {
            IERC4626 vault = underlyingVaults[i];

            // Get our share balance in this vault
            uint256 shares = vault.balanceOf(address(this));

            // Convert shares to assets (recursive call to underlying vault)
            // This is where the recursion happens!
            uint256 assets = vault.convertToAssets(shares);

            total += assets;
        }

        // Add any idle assets not yet deposited
        total += IERC20(asset()).balanceOf(address(this));

        return total;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Override deposit to handle depositing into underlying vaults
     *
     * FLOW:
     * 1. User calls deposit(1000 assets)
     * 2. super._deposit() handles:
     *    - Transfer 1000 assets from user to meta-vault
     *    - Mint shares to user based on current share price
     * 3. _depositToUnderlying() handles:
     *    - Deposit 1000 assets into underlying vault(s)
     *    - Receive underlying vault shares
     */
    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal virtual override nonReentrant {
        // First, execute standard ERC4626 deposit
        // This transfers assets in and mints shares to receiver
        super._deposit(caller, receiver, assets, shares);

        // Then, deposit the assets into underlying vault(s)
        _depositToUnderlying(assets);
    }

    /**
     * @notice Deposit assets to underlying vault(s)
     * @param assets Amount of assets to deposit
     *
     * STRATEGY:
     * - If autoRebalance is enabled: deposit all to highest-yield vault
     * - Otherwise: deposit proportionally according to target allocations
     *
     * PROPORTIONAL DISTRIBUTION EXAMPLE:
     * Assets to deposit: 1000
     * VaultA target: 60% (6000 BPS)
     * VaultB target: 40% (4000 BPS)
     *
     * Distribution:
     * - VaultA: 1000 * 6000 / 10000 = 600
     * - VaultB: 1000 * 4000 / 10000 = 400
     */
    function _depositToUnderlying(uint256 assets) internal {
        if (underlyingVaults.length == 0) {
            // No underlying vaults yet, just hold assets
            return;
        }

        if (autoRebalance) {
            // Deposit all to the best vault
            uint256 bestVault = _findBestVault();
            _depositToVault(bestVault, assets);
        } else {
            // Deposit proportionally to target allocations
            uint256 remaining = assets;

            for (uint256 i = 0; i < underlyingVaults.length; i++) {
                // Calculate proportional amount for this vault
                uint256 amount;

                if (i == underlyingVaults.length - 1) {
                    // Last vault gets remaining (handles rounding)
                    amount = remaining;
                } else {
                    amount = (assets * targetAllocations[i]) / TOTAL_BPS;
                    remaining -= amount;
                }

                if (amount > 0) {
                    _depositToVault(i, amount);
                }
            }
        }
    }

    /**
     * @notice Helper to deposit to a specific vault
     */
    function _depositToVault(uint256 vaultIndex, uint256 assets) internal {
        if (assets == 0) return;

        IERC4626 vault = underlyingVaults[vaultIndex];

        // Approve the vault to spend our assets
        IERC20(asset()).approve(address(vault), assets);

        // Deposit and receive shares
        vault.deposit(assets, address(this));
    }

    /*//////////////////////////////////////////////////////////////
                        WITHDRAW LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Override withdraw to handle withdrawing from underlying vaults
     *
     * FLOW:
     * 1. User calls withdraw(500 assets)
     * 2. _withdrawFromUnderlying() handles:
     *    - Redeem shares from underlying vault(s)
     *    - Receive 500 assets
     * 3. super._withdraw() handles:
     *    - Burn user's shares
     *    - Transfer 500 assets to user
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual override nonReentrant {
        // First, withdraw from underlying vaults to get assets
        _withdrawFromUnderlying(assets);

        // Then, execute standard ERC4626 withdraw
        // This burns shares and transfers assets out
        super._withdraw(caller, receiver, owner, assets, shares);
    }

    /**
     * @notice Withdraw assets from underlying vault(s)
     * @param assets Amount of assets to withdraw
     *
     * STRATEGY:
     * 1. Try to withdraw from idle assets first (if any)
     * 2. Withdraw from vaults starting with most liquid
     * 3. If one vault doesn't have enough, withdraw from multiple
     *
     * EXAMPLE:
     * Need to withdraw: 500 assets
     * VaultA has: 600 assets worth of shares
     * VaultB has: 400 assets worth of shares
     *
     * Strategy: Withdraw 500 from VaultA (most liquid, has enough)
     * Result: VaultA left with 100, VaultB unchanged
     */
    function _withdrawFromUnderlying(uint256 assets) internal {
        // First, use any idle assets
        uint256 idle = IERC20(asset()).balanceOf(address(this));
        if (idle >= assets) {
            // We have enough idle assets, no need to withdraw from vaults
            return;
        }

        // Need to withdraw from vaults
        uint256 remaining = assets - idle;

        // Try to withdraw from vaults in order
        for (uint256 i = 0; i < underlyingVaults.length && remaining > 0; i++) {
            IERC4626 vault = underlyingVaults[i];

            // Check how much we can withdraw from this vault
            uint256 available = vault.maxWithdraw(address(this));

            if (available == 0) continue;

            // Withdraw min(remaining, available)
            uint256 toWithdraw = remaining > available ? available : remaining;

            vault.withdraw(toWithdraw, address(this), address(this));
            remaining -= toWithdraw;
        }

        // Ensure we withdrew enough
        if (remaining > 0) revert InsufficientLiquidity();
    }

    /*//////////////////////////////////////////////////////////////
                        REBALANCING
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Rebalance assets between vaults to match target allocations
     *
     * PROCESS:
     * 1. Calculate total assets
     * 2. For each vault, calculate target amount vs current amount
     * 3. Withdraw from over-allocated vaults
     * 4. Deposit to under-allocated vaults
     *
     * EXAMPLE:
     * Total assets: 1000
     * Target: VaultA 70%, VaultB 30%
     * Current: VaultA 500 (50%), VaultB 500 (50%)
     *
     * Target amounts:
     * - VaultA: 1000 * 70% = 700
     * - VaultB: 1000 * 30% = 300
     *
     * Actions:
     * 1. Withdraw 200 from VaultB (500 → 300)
     * 2. Deposit 200 to VaultA (500 → 700)
     *
     * WHEN TO REBALANCE:
     * - After major deposits/withdrawals
     * - When allocation drifts beyond threshold (e.g., >5%)
     * - When vault yields change significantly
     * - Periodically (e.g., daily/weekly)
     *
     * GAS CONSIDERATIONS:
     * Rebalancing is expensive! It involves:
     * - Multiple vault.withdraw() calls
     * - Multiple vault.deposit() calls
     * - Share price calculations
     *
     * Only rebalance when the yield benefit exceeds gas costs!
     */
    function rebalance() external {
        // Prevent too frequent rebalancing (gas optimization)
        if (block.timestamp < lastRebalance + MIN_REBALANCE_INTERVAL) {
            revert RebalanceTooSoon();
        }

        uint256 total = totalAssets();
        if (total == 0) return; // Nothing to rebalance

        // First, calculate current assets in each vault
        uint256[] memory currentAssets = new uint256[](underlyingVaults.length);
        for (uint256 i = 0; i < underlyingVaults.length; i++) {
            uint256 shares = underlyingVaults[i].balanceOf(address(this));
            currentAssets[i] = underlyingVaults[i].convertToAssets(shares);
        }

        // Withdraw from over-allocated vaults
        uint256 idle = IERC20(asset()).balanceOf(address(this));
        for (uint256 i = 0; i < underlyingVaults.length; i++) {
            uint256 target = (total * targetAllocations[i]) / TOTAL_BPS;

            if (currentAssets[i] > target) {
                // Over-allocated, withdraw excess
                uint256 excess = currentAssets[i] - target;
                underlyingVaults[i].withdraw(excess, address(this), address(this));
                idle += excess;
            }
        }

        // Deposit to under-allocated vaults
        for (uint256 i = 0; i < underlyingVaults.length; i++) {
            uint256 target = (total * targetAllocations[i]) / TOTAL_BPS;

            if (currentAssets[i] < target) {
                // Under-allocated, deposit needed amount
                uint256 needed = target - currentAssets[i];
                uint256 toDeposit = needed > idle ? idle : needed;

                if (toDeposit > 0) {
                    _depositToVault(i, toDeposit);
                    idle -= toDeposit;
                }
            }
        }

        lastRebalance = block.timestamp;
        emit Rebalanced(block.timestamp, total);
    }

    /**
     * @notice Find vault with highest expected yield
     * @return Index of the best vault
     *
     * SIMPLIFIED HEURISTIC:
     * We use recent share price growth as a proxy for yield.
     * Better implementations could:
     * - Use off-chain APY oracles
     * - Track historical performance
     * - Consider risk-adjusted returns
     * - Factor in liquidity constraints
     *
     * CALCULATION:
     * For each vault, check how much 1e18 shares is worth in assets.
     * The vault with highest asset value per share is earning best yield.
     *
     * NOTE: This is a simplified approach. In production, you'd want
     * more sophisticated yield tracking and prediction.
     */
    function _findBestVault() internal view returns (uint256) {
        if (underlyingVaults.length == 0) return 0;
        if (underlyingVaults.length == 1) return 0;

        uint256 bestVault = 0;
        uint256 bestRatio = 0;

        for (uint256 i = 0; i < underlyingVaults.length; i++) {
            // Convert a standard amount to see share price
            uint256 ratio = underlyingVaults[i].convertToAssets(1e18);

            if (ratio > bestRatio) {
                bestRatio = ratio;
                bestVault = i;
            }
        }

        return bestVault;
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get number of underlying vaults
     */
    function getVaultCount() external view returns (uint256) {
        return underlyingVaults.length;
    }

    /**
     * @notice Get all underlying vaults
     */
    function getVaults() external view returns (IERC4626[] memory) {
        return underlyingVaults;
    }

    /**
     * @notice Get current allocation for each vault (in BPS)
     * @return allocations Array of current allocations based on actual assets
     *
     * EXAMPLE:
     * Total assets: 1000
     * VaultA has: 700 assets → 7000 BPS (70%)
     * VaultB has: 300 assets → 3000 BPS (30%)
     */
    function getCurrentAllocations() external view returns (uint256[] memory) {
        uint256[] memory allocations = new uint256[](underlyingVaults.length);
        uint256 total = totalAssets();

        if (total == 0) return allocations;

        for (uint256 i = 0; i < underlyingVaults.length; i++) {
            uint256 shares = underlyingVaults[i].balanceOf(address(this));
            uint256 assets = underlyingVaults[i].convertToAssets(shares);
            allocations[i] = (assets * TOTAL_BPS) / total;
        }

        return allocations;
    }

    /**
     * @notice Get target allocations for all vaults
     */
    function getTargetAllocations() external view returns (uint256[] memory) {
        uint256[] memory allocations = new uint256[](underlyingVaults.length);
        for (uint256 i = 0; i < underlyingVaults.length; i++) {
            allocations[i] = targetAllocations[i];
        }
        return allocations;
    }

    /**
     * @notice Get total assets in a specific vault
     * @param vaultIndex Index of the vault
     */
    function getVaultAssets(uint256 vaultIndex) external view returns (uint256) {
        if (vaultIndex >= underlyingVaults.length) return 0;

        uint256 shares = underlyingVaults[vaultIndex].balanceOf(address(this));
        return underlyingVaults[vaultIndex].convertToAssets(shares);
    }

    /**
     * @notice Get shares held in a specific vault
     */
    function getVaultShares(uint256 vaultIndex) external view returns (uint256) {
        if (vaultIndex >= underlyingVaults.length) return 0;
        return underlyingVaults[vaultIndex].balanceOf(address(this));
    }

    /**
     * @notice Check if rebalancing is needed
     * @return Whether current allocations drift beyond threshold from target
     */
    function needsRebalancing() external view returns (bool) {
        if (underlyingVaults.length == 0) return false;

        uint256 total = totalAssets();
        if (total == 0) return false;

        for (uint256 i = 0; i < underlyingVaults.length; i++) {
            uint256 shares = underlyingVaults[i].balanceOf(address(this));
            uint256 assets = underlyingVaults[i].convertToAssets(shares);
            uint256 currentAllocation = (assets * TOTAL_BPS) / total;
            uint256 targetAllocation = targetAllocations[i];

            // Check if drift exceeds threshold
            uint256 drift = currentAllocation > targetAllocation
                ? currentAllocation - targetAllocation
                : targetAllocation - currentAllocation;

            if (drift > rebalanceThreshold) {
                return true;
            }
        }

        return false;
    }

    /*//////////////////////////////////////////////////////////////
                        ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Toggle auto-rebalancing mode
     * @param _autoRebalance Whether to enable auto-rebalancing
     *
     * When enabled: All deposits go to highest-yield vault
     * When disabled: Deposits are distributed proportionally
     */
    function setAutoRebalance(bool _autoRebalance) external onlyOwner {
        autoRebalance = _autoRebalance;
        emit AutoRebalanceToggled(_autoRebalance);
    }

    /**
     * @notice Set rebalance drift threshold
     * @param _threshold Threshold in basis points (e.g., 500 = 5%)
     */
    function setRebalanceThreshold(uint256 _threshold) external onlyOwner {
        rebalanceThreshold = _threshold;
    }

    /**
     * @notice Emergency withdraw all funds from underlying vaults
     * @dev Only for emergencies, bypasses normal allocation logic
     *
     * USE CASE:
     * If an underlying vault is compromised, quickly exit all positions
     */
    function emergencyWithdrawAll() external onlyOwner {
        for (uint256 i = 0; i < underlyingVaults.length; i++) {
            uint256 shares = underlyingVaults[i].balanceOf(address(this));
            if (shares > 0) {
                underlyingVaults[i].redeem(shares, address(this), address(this));
            }
        }
    }
}
