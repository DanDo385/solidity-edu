// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title MetaVault
 * @notice An ERC-4626 vault that wraps other ERC-4626 vaults
 * @dev Enables yield aggregation and auto-rebalancing across multiple underlying vaults
 *
 * KEY CONCEPTS:
 * 1. Recursive Calculations: totalAssets() must recursively call underlying vaults
 * 2. Multi-Vault Support: Can hold positions in multiple underlying vaults
 * 3. Rebalancing: Can shift capital between vaults to optimize yield
 * 4. Yield Aggregation: Combines yields from all underlying vaults
 *
 * ARCHITECTURE:
 *   User → MetaVault (this contract)
 *            → Underlying Vault A
 *            → Underlying Vault B
 *            → Underlying Vault C
 *
 * MATH EXAMPLE:
 *   User deposits 1000 DAI
 *   → MetaVault deposits to UnderlyingVault
 *   → UnderlyingVault mints X shares to MetaVault
 *   → MetaVault mints Y shares to User
 *
 *   When User redeems Y shares:
 *   → MetaVault calculates underlying shares: X
 *   → MetaVault redeems X from UnderlyingVault → gets Z DAI
 *   → MetaVault transfers Z DAI to User
 */
contract MetaVault is ERC4626, Ownable, ReentrancyGuard {
    // Constants
    uint256 public constant TOTAL_BPS = 10000; // 100%
    uint256 public constant MIN_REBALANCE_INTERVAL = 1 hours;

    // State variables
    IERC4626[] public underlyingVaults; // Array of underlying vaults
    mapping(address => bool) public isVault; // Quick lookup for valid vaults
    mapping(uint256 => uint256) public targetAllocations; // Target allocation per vault (in basis points)

    bool public autoRebalance; // Whether to auto-rebalance on deposits
    uint256 public lastRebalance; // Timestamp of last rebalance

    // Events
    event VaultAdded(address indexed vault, uint256 targetAllocation);
    event VaultRemoved(address indexed vault);
    event Rebalanced(uint256 timestamp);
    event AllocationUpdated(uint256 indexed vaultIndex, uint256 newAllocation);

    /**
     * @param _asset The underlying asset (e.g., DAI, USDC)
     * @param _name Name of the meta-vault token
     * @param _symbol Symbol of the meta-vault token
     */
    constructor(
        IERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC4626(_asset) ERC20(_name, _symbol) Ownable(msg.sender) {}

    /*//////////////////////////////////////////////////////////////
                        VAULT MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Add a new underlying vault to invest in
     * @param vault The ERC-4626 vault to add
     * @param allocation Target allocation in basis points (0-10000)
     *
     * TODO: Implement this function
     * Requirements:
     * - Vault must use the same underlying asset
     * - Vault must not already be added
     * - Total allocations after adding must not exceed TOTAL_BPS
     * - Only owner can call
     */
    function addVault(IERC4626 vault, uint256 allocation) external onlyOwner {
        // TODO: Verify vault uses same asset as this meta-vault
        // Hint: vault.asset() == asset()

        // TODO: Verify vault not already added
        // Hint: use isVault mapping

        // TODO: Verify total allocations don't exceed 100%
        // Hint: loop through all vaults and sum allocations

        // TODO: Add vault to array and mappings

        // TODO: Emit VaultAdded event
    }

    /**
     * @notice Remove an underlying vault
     * @param vaultIndex Index of vault to remove
     *
     * TODO: Implement this function
     * Requirements:
     * - Withdraw all assets from the vault first
     * - Remove from array and mappings
     * - Redistribute allocation among remaining vaults
     */
    function removeVault(uint256 vaultIndex) external onlyOwner {
        // TODO: Withdraw all shares from the vault

        // TODO: Remove from array (shift elements or use swap-and-pop)

        // TODO: Update mappings

        // TODO: Emit VaultRemoved event
    }

    /**
     * @notice Update target allocation for a vault
     * @param vaultIndex Index of vault to update
     * @param newAllocation New allocation in basis points
     */
    function updateAllocation(uint256 vaultIndex, uint256 newAllocation) external onlyOwner {
        // TODO: Verify total allocations don't exceed 100%

        // TODO: Update allocation

        // TODO: Emit AllocationUpdated event
    }

    /*//////////////////////////////////////////////////////////////
                    RECURSIVE ASSET CALCULATIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Calculate total assets held by this meta-vault
     * @dev MUST recursively call convertToAssets on all underlying vaults
     * @return Total assets in underlying asset terms
     *
     * TODO: Implement this function
     *
     * EXPLANATION:
     * This is the core of the meta-vault. We hold shares in underlying vaults,
     * not the actual assets. So we must:
     * 1. For each underlying vault, get our share balance
     * 2. Convert those shares to assets using the vault's convertToAssets
     * 3. Sum all the assets from all vaults
     *
     * EXAMPLE:
     * MetaVault holds:
     * - 100 shares in VaultA → VaultA.convertToAssets(100) = 110 DAI
     * - 200 shares in VaultB → VaultB.convertToAssets(200) = 250 DAI
     * Total assets = 110 + 250 = 360 DAI
     */
    function totalAssets() public view virtual override returns (uint256) {
        // TODO: Loop through all underlying vaults
        // For each vault:
        //   - Get our share balance: vault.balanceOf(address(this))
        //   - Convert to assets: vault.convertToAssets(shares)
        //   - Add to total

        return 0; // TODO: Replace with actual calculation
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposit assets into the meta-vault
     * @dev Override to handle depositing into underlying vaults
     */
    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal virtual override nonReentrant {
        // First, execute the standard ERC4626 deposit (transfer assets in, mint shares)
        super._deposit(caller, receiver, assets, shares);

        // Then, deposit the assets into underlying vault(s)
        // TODO: Implement _depositToUnderlying(assets)
    }

    /**
     * @notice Deposit assets to underlying vault(s)
     * @param assets Amount of assets to deposit
     *
     * TODO: Implement this function
     *
     * STRATEGY OPTIONS:
     * 1. Auto-rebalance mode: Deposit all to vault with highest yield
     * 2. Proportional mode: Deposit according to target allocations
     * 3. Single vault mode: Deposit to specific vault
     *
     * For skeleton, implement proportional distribution
     */
    function _depositToUnderlying(uint256 assets) internal {
        // TODO: If no underlying vaults, just hold assets (rare case)

        // TODO: For each vault, calculate proportional amount based on allocation
        //       amount = assets * targetAllocations[i] / TOTAL_BPS

        // TODO: Approve vault to spend assets

        // TODO: Deposit to vault: vault.deposit(amount, address(this))
    }

    /*//////////////////////////////////////////////////////////////
                        WITHDRAW LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Withdraw assets from the meta-vault
     * @dev Override to handle withdrawing from underlying vaults
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual override nonReentrant {
        // First, withdraw from underlying vaults to get assets
        // TODO: Implement _withdrawFromUnderlying(assets)

        // Then, execute the standard ERC4626 withdraw (burn shares, transfer assets out)
        super._withdraw(caller, receiver, owner, assets, shares);
    }

    /**
     * @notice Withdraw assets from underlying vault(s)
     * @param assets Amount of assets to withdraw
     *
     * TODO: Implement this function
     *
     * STRATEGY:
     * 1. Try to withdraw from vault with most liquidity first
     * 2. If one vault doesn't have enough, withdraw from multiple
     * 3. Handle case where total liquidity is insufficient
     */
    function _withdrawFromUnderlying(uint256 assets) internal {
        // TODO: Track remaining assets to withdraw
        // uint256 remaining = assets;

        // TODO: Loop through vaults until we have enough assets
        // For each vault:
        //   - Check available: vault.maxWithdraw(address(this))
        //   - Withdraw min(remaining, available)
        //   - Decrease remaining

        // TODO: Revert if we couldn't withdraw enough
    }

    /*//////////////////////////////////////////////////////////////
                        REBALANCING
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Rebalance assets between underlying vaults
     * @dev Moves funds to match target allocations
     *
     * TODO: Implement this function
     *
     * PROCESS:
     * 1. Calculate current allocation for each vault
     * 2. Compare to target allocation
     * 3. Withdraw from over-allocated vaults
     * 4. Deposit to under-allocated vaults
     *
     * EXAMPLE:
     * Total assets: 1000 DAI
     * Target: VaultA 60%, VaultB 40%
     * Current: VaultA 500 DAI (50%), VaultB 500 DAI (50%)
     *
     * Action:
     * - Withdraw 100 DAI from VaultB (500 → 400)
     * - Deposit 100 DAI to VaultA (500 → 600)
     * Result: VaultA 600 (60%), VaultB 400 (40%)
     */
    function rebalance() external {
        // TODO: Check minimum time between rebalances has passed

        // TODO: Calculate total assets

        // TODO: For each vault, calculate target amount and current amount

        // TODO: Withdraw from over-allocated vaults

        // TODO: Deposit to under-allocated vaults

        // TODO: Update lastRebalance timestamp

        // TODO: Emit Rebalanced event
    }

    /**
     * @notice Find the vault with the highest current yield
     * @return Index of the best vault
     *
     * TODO: Implement this function (optional, for auto-rebalance mode)
     *
     * HINT: This is tricky! You need to estimate APY or use recent performance.
     * For simplicity, could use a simple heuristic like:
     * - Vault with highest share price growth
     * - External oracle for APY data
     * - Manual configuration by owner
     */
    function _findBestVault() internal view returns (uint256) {
        // TODO: Implement yield comparison logic
        return 0;
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get the number of underlying vaults
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
     * @notice Get current allocation for each vault
     * @return allocations Array of current allocations in basis points
     *
     * TODO: Implement this function
     * Calculate actual current allocation based on assets held in each vault
     */
    function getCurrentAllocations() external view returns (uint256[] memory) {
        // TODO: Calculate current allocations based on actual assets in each vault
        uint256[] memory allocations = new uint256[](underlyingVaults.length);
        return allocations;
    }

    /**
     * @notice Get total assets in a specific vault
     * @param vaultIndex Index of the vault
     */
    function getVaultAssets(uint256 vaultIndex) external view returns (uint256) {
        // TODO: Get shares held in vault
        // TODO: Convert to assets
        return 0;
    }

    /*//////////////////////////////////////////////////////////////
                        ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Enable or disable auto-rebalancing on deposits
     */
    function setAutoRebalance(bool _autoRebalance) external onlyOwner {
        autoRebalance = _autoRebalance;
    }

    /**
     * @notice Emergency withdraw all funds from underlying vaults
     * @dev Only for emergencies, bypasses normal allocation logic
     */
    function emergencyWithdrawAll() external onlyOwner {
        // TODO: Withdraw all shares from all vaults
    }
}
