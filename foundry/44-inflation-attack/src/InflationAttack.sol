// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title Project 44: ERC-4626 Inflation Attack Demo
 * @notice Educational project demonstrating inflation attacks on vaults and mitigations
 *
 * LEARNING OBJECTIVES:
 * 1. Understand how share-based vaults calculate deposits
 * 2. Learn the inflation attack mechanism
 * 3. Explore why direct donations can manipulate share price
 * 4. Implement multiple mitigation strategies
 * 5. Analyze economic viability of attacks
 *
 * CONCEPTS COVERED:
 * - ERC-4626 vault standard
 * - Share price manipulation
 * - Integer division rounding
 * - Virtual shares/assets
 * - Dead shares pattern
 * - Minimum deposit requirements
 *
 * ATTACK FLOW:
 * 1. Attacker deposits 1 wei → receives 1 share
 * 2. Attacker donates 1000 ether directly to vault
 * 3. Share price is now 1000 ether per share
 * 4. Victim deposits 999 ether
 * 5. Victim receives: (999 * 1) / 1000 = 0 shares (rounds down!)
 * 6. Attacker withdraws, taking victim's funds
 */

// ======================
// VULNERABLE VAULT
// ======================

/**
 * @title VulnerableVault
 * @notice A basic ERC-4626 implementation WITHOUT inflation attack protection
 * @dev This vault is intentionally vulnerable for educational purposes
 *
 * VULNERABILITY:
 * - No minimum deposit requirement
 * - No virtual shares/assets
 * - Allows share price manipulation via donations
 *
 * TODO: Implement the basic ERC-4626 functions
 */
contract VulnerableVault is ERC4626 {
    using Math for uint256;

    constructor(IERC20 asset)
        ERC4626(asset)
        ERC20("Vulnerable Vault", "vVAULT")
    {}

    /**
     * @notice Returns total assets held by the vault
     * @dev This includes any tokens sent directly (donations)
     *
     * TODO: Implement this function
     * HINT: Check the vault's balance of the underlying asset
     */
    function totalAssets() public view override returns (uint256) {
        // TODO: Return the total balance of the underlying asset
        // This should include both deposited assets and any direct transfers (donations)
    }

    /**
     * @notice Convert assets to shares
     * @dev Uses standard formula: shares = assets * totalSupply / totalAssets
     *
     * VULNERABILITY EXPLANATION:
     * When totalAssets >> totalSupply (due to donation), this can round to zero
     * Example: 1000 * 1 / 1000000 = 0 (integer division)
     *
     * TODO: Implement the conversion logic
     */
    function _convertToShares(uint256 assets, Math.Rounding rounding)
        internal
        view
        override
        returns (uint256)
    {
        // TODO: Implement share calculation
        // HINT: Use totalSupply() and totalAssets()
        // HINT: Handle the case when totalSupply is 0 (first deposit)
        // HINT: Use Math.mulDiv for safe multiplication and division
    }

    /**
     * @notice Convert shares to assets
     * @dev Uses standard formula: assets = shares * totalAssets / totalSupply
     */
    function _convertToAssets(uint256 shares, Math.Rounding rounding)
        internal
        view
        override
        returns (uint256)
    {
        // TODO: Implement asset calculation (inverse of _convertToShares)
    }

    /**
     * @notice Deposit assets and mint shares
     * @dev Basic implementation without protection
     */
    function deposit(uint256 assets, address receiver)
        public
        override
        returns (uint256)
    {
        // TODO: Implement deposit logic
        // 1. Calculate shares to mint
        // 2. Transfer assets from sender
        // 3. Mint shares to receiver
        // 4. Emit Deposit event
        // HINT: Use SafeERC20.safeTransferFrom for the transfer
    }

    /**
     * @notice Redeem shares for assets
     * @dev Basic implementation
     */
    function redeem(uint256 shares, address receiver, address owner)
        public
        override
        returns (uint256)
    {
        // TODO: Implement redeem logic
        // 1. Check allowance if owner != msg.sender
        // 2. Calculate assets to return
        // 3. Burn shares
        // 4. Transfer assets to receiver
        // 5. Emit Withdraw event
    }
}

// ======================
// ATTACKER CONTRACT
// ======================

/**
 * @title InflationAttacker
 * @notice Contract that executes the inflation attack
 *
 * ATTACK STEPS:
 * 1. Deposit minimal amount (1 wei) to get 1 share
 * 2. Donate large amount directly to vault (not via deposit)
 * 3. Wait for victim to deposit
 * 4. Victim gets 0 shares due to rounding
 * 5. Withdraw all assets, profiting from victim's deposit
 *
 * TODO: Implement the attack execution
 */
contract InflationAttacker {
    using SafeERC20 for IERC20;

    VulnerableVault public immutable vault;
    IERC20 public immutable asset;

    // Track attacker's investment and profit
    uint256 public initialDeposit;
    uint256 public donationAmount;
    uint256 public finalWithdrawal;

    constructor(address _vault) {
        vault = VulnerableVault(_vault);
        asset = IERC20(vault.asset());
    }

    /**
     * @notice Execute the inflation attack
     * @param _donationAmount Amount to donate after initial deposit
     *
     * ATTACK FLOW:
     * 1. Deposit 1 wei to get 1 share
     * 2. Transfer _donationAmount directly to vault
     * 3. Now totalAssets = 1 + _donationAmount but totalSupply = 1
     * 4. Any victim deposit < _donationAmount will round to 0 shares
     *
     * TODO: Implement the attack
     */
    function executeAttack(uint256 _donationAmount) external {
        // TODO: Implement attack steps
        // 1. Approve vault to spend tokens
        // 2. Deposit 1 wei to get 1 share (store as initialDeposit)
        // 3. Transfer _donationAmount directly to vault address (store as donationAmount)
        // 4. At this point, share price is massively inflated
        //
        // HINT: Direct transfer bypasses the deposit function
        // HINT: asset.transfer(address(vault), _donationAmount)
    }

    /**
     * @notice Withdraw all funds after victims have deposited
     * @dev Redeems all shares to capture victim's funds
     */
    function collectProfit() external returns (uint256 profit) {
        // TODO: Implement profit collection
        // 1. Get attacker's share balance
        // 2. Redeem all shares
        // 3. Calculate and return profit
        // HINT: profit = finalWithdrawal - (initialDeposit + donationAmount)
    }

    /**
     * @notice Calculate expected profit from an attack
     * @param victimDeposit Expected victim deposit amount
     * @return profit Expected profit (may be negative if attack fails)
     */
    function calculateExpectedProfit(uint256 victimDeposit)
        external
        view
        returns (int256 profit)
    {
        // TODO: Calculate if attack would be profitable
        // If victim gets 0 shares, attacker gets their full deposit
        // profit = victimDeposit - (initialDeposit + donationAmount)
        //
        // HINT: Cast to int256 for negative values
    }
}

// ======================
// MITIGATION 1: Virtual Shares
// ======================

/**
 * @title VaultWithVirtualShares
 * @notice Vault protected using virtual shares/assets (OpenZeppelin approach)
 *
 * MITIGATION EXPLANATION:
 * Adding virtual offset makes inflation attack exponentially more expensive.
 * Formula becomes: shares = assets * (totalSupply + OFFSET) / (totalAssets + 1)
 *
 * With offset = 1000:
 * - Normal deposit: 1000 assets → ~1000 shares ✓
 * - Attack attempt: 1 asset, 1M donation
 *   - Without offset: victim gets (1000 * 1) / 1000001 = 0 shares ✗
 *   - With offset: victim gets (1000 * 1001) / 1000001 = 1 share ✓
 *
 * To make victim get 0 shares with offset, attacker needs ~1000x more capital!
 *
 * TODO: Implement virtual offset protection
 */
contract VaultWithVirtualShares is ERC4626 {
    using Math for uint256;

    // Decimals offset for virtual shares
    uint8 private immutable _offset;

    constructor(IERC20 asset, uint8 offset_)
        ERC4626(asset)
        ERC20("Virtual Shares Vault", "vsVAULT")
    {
        _offset = offset_;
    }

    function totalAssets() public view override returns (uint256) {
        return IERC20(asset()).balanceOf(address(this));
    }

    /**
     * @notice Returns the decimals offset for virtual shares
     * @dev This creates an offset of 10^_offset virtual shares
     */
    function _decimalsOffset() internal view virtual returns (uint8) {
        return _offset;
    }

    /**
     * @notice Convert assets to shares with virtual offset
     * @dev Adds 10^offset virtual shares and 1 virtual asset
     *
     * TODO: Implement with virtual shares
     * Formula: shares = assets * (totalSupply + 10^offset) / (totalAssets + 1)
     */
    function _convertToShares(uint256 assets, Math.Rounding rounding)
        internal
        view
        override
        returns (uint256)
    {
        // TODO: Implement with virtual offset
        // HINT: Use 10 ** _decimalsOffset() for virtual shares
        // HINT: Add 1 to totalAssets() for virtual asset
    }

    /**
     * @notice Convert shares to assets with virtual offset
     */
    function _convertToAssets(uint256 shares, Math.Rounding rounding)
        internal
        view
        override
        returns (uint256)
    {
        // TODO: Implement (inverse of _convertToShares with same offset)
    }
}

// ======================
// MITIGATION 2: Minimum Deposit
// ======================

/**
 * @title VaultWithMinDeposit
 * @notice Vault protected with minimum first deposit requirement
 *
 * MITIGATION EXPLANATION:
 * Requires first depositor to commit substantial capital.
 * This makes the attack economically unfeasible.
 *
 * Example with MIN_FIRST_DEPOSIT = 1000 ether:
 * - Attacker must deposit 1000 ether initially
 * - To profit, must donate > victim's expected deposit
 * - If victim deposits 100 ether, attacker loses money
 *
 * TODO: Implement minimum deposit check
 */
contract VaultWithMinDeposit is ERC4626 {
    using Math for uint256;
    using SafeERC20 for IERC20;

    uint256 public immutable MIN_FIRST_DEPOSIT;

    constructor(IERC20 asset, uint256 minFirstDeposit)
        ERC4626(asset)
        ERC20("Min Deposit Vault", "mdVAULT")
    {
        MIN_FIRST_DEPOSIT = minFirstDeposit;
    }

    function totalAssets() public view override returns (uint256) {
        return IERC20(asset()).balanceOf(address(this));
    }

    function _convertToShares(uint256 assets, Math.Rounding rounding)
        internal
        view
        override
        returns (uint256)
    {
        uint256 supply = totalSupply();
        return (supply == 0)
            ? assets
            : assets.mulDiv(supply, totalAssets(), rounding);
    }

    function _convertToAssets(uint256 shares, Math.Rounding rounding)
        internal
        view
        override
        returns (uint256)
    {
        uint256 supply = totalSupply();
        return (supply == 0)
            ? shares
            : shares.mulDiv(totalAssets(), supply, rounding);
    }

    /**
     * @notice Deposit with minimum first deposit check
     * @dev First deposit must meet minimum requirement
     *
     * TODO: Add minimum deposit validation
     */
    function deposit(uint256 assets, address receiver)
        public
        override
        returns (uint256)
    {
        // TODO: Add check for first deposit
        // HINT: if (totalSupply() == 0) require(assets >= MIN_FIRST_DEPOSIT)
        // Then proceed with normal deposit logic
    }
}

// ======================
// MITIGATION 3: Dead Shares
// ======================

/**
 * @title VaultWithDeadShares
 * @notice Vault protected by burning initial shares
 *
 * MITIGATION EXPLANATION:
 * First deposit mints some shares to a dead address.
 * These shares inflate totalSupply but can't be controlled by attacker.
 *
 * Example with DEAD_SHARES = 1000:
 * - First deposit of 2000: mints 1000 to dead address, 1000 to depositor
 * - totalSupply = 2000, totalAssets = 2000
 * - Attacker can't get totalSupply = 1 for manipulation
 *
 * TODO: Implement dead shares pattern
 */
contract VaultWithDeadShares is ERC4626 {
    using Math for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant DEAD_SHARES = 1000;
    address public constant DEAD_ADDRESS = address(0xdead);

    bool private _initialized;

    constructor(IERC20 asset)
        ERC4626(asset)
        ERC20("Dead Shares Vault", "dsVAULT")
    {}

    function totalAssets() public view override returns (uint256) {
        return IERC20(asset()).balanceOf(address(this));
    }

    function _convertToShares(uint256 assets, Math.Rounding rounding)
        internal
        view
        override
        returns (uint256)
    {
        uint256 supply = totalSupply();
        return (supply == 0)
            ? assets
            : assets.mulDiv(supply, totalAssets(), rounding);
    }

    function _convertToAssets(uint256 shares, Math.Rounding rounding)
        internal
        view
        override
        returns (uint256)
    {
        uint256 supply = totalSupply();
        return (supply == 0)
            ? shares
            : shares.mulDiv(totalAssets(), supply, rounding);
    }

    /**
     * @notice Deposit with dead shares initialization
     * @dev First deposit burns DEAD_SHARES to dead address
     *
     * TODO: Implement dead shares minting on first deposit
     */
    function deposit(uint256 assets, address receiver)
        public
        override
        returns (uint256 shares)
    {
        // TODO: Implement dead shares pattern
        // 1. Check if this is the first deposit (!_initialized)
        // 2. If first:
        //    a. Require assets > DEAD_SHARES
        //    b. Mint DEAD_SHARES to DEAD_ADDRESS
        //    c. Mint (assets - DEAD_SHARES) to receiver
        //    d. Set _initialized = true
        // 3. If not first, use normal share calculation
        // 4. Transfer assets from sender
        // 5. Emit Deposit event
    }
}

/**
 * @dev Key Takeaways:
 *
 * 1. VULNERABILITY:
 *    - Integer division + external donations = share price manipulation
 *    - Attacker inflates price to make victim deposits round to 0 shares
 *
 * 2. ECONOMICS:
 *    - Attack requires capital: initial deposit + donation
 *    - Only profitable if victim deposits > attacker's costs
 *    - Mitigations make attack exponentially more expensive
 *
 * 3. MITIGATIONS:
 *    - Virtual shares: Mathematical elegance, adds virtual offset
 *    - Minimum deposit: Simple, forces attacker capital commitment
 *    - Dead shares: Permanent protection via burned shares
 *
 * 4. BEST PRACTICE:
 *    - Use OpenZeppelin ERC4626 (includes virtual shares)
 *    - Consider combining mitigations for high-value vaults
 *    - Always test with inflation attack scenarios
 *    - Audit vault implementations thoroughly
 *
 * 5. TESTING:
 *    - Verify attack succeeds on vulnerable vault
 *    - Verify attack fails on protected vaults
 *    - Test economic boundaries (when attack becomes unprofitable)
 *    - Check edge cases (dust deposits, maximum values, etc.)
 */
