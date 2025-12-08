// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title VaultPrecisionSolution
 * @notice ERC-4626 vault with correct rounding to prevent precision loss attacks
 * 
 * PURPOSE: Demonstrates critical rounding rules that prevent vault insolvency
 * CS CONCEPTS: Integer division rounding, precision attacks, invariant maintenance
 * 
 * CONNECTIONS:
 * - Project 11: ERC-4626 standard (this shows correct rounding)
 * - Project 20: Share-based accounting (precision critical here)
 * - Project 44: Inflation attacks (rounding prevents these)
 * 
 * KEY: Deposit/mint round opposite directions - prevents precision loss exploitation
 */
contract VaultPrecisionSolution is ERC20, IERC4626 {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    IERC20 private immutable _asset;

    /*//////////////////////////////////////////////////////////////
                               EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);
    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        IERC20 asset_,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {
        _asset = asset_;
    }

    /*//////////////////////////////////////////////////////////////
                        ERC4626 METADATA
    //////////////////////////////////////////////////////////////*/

    function asset() public view virtual override returns (address) {
        return address(_asset);
    }

    /*//////////////////////////////////////////////////////////////
                        ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Total assets under management
     * @dev In production, this might include:
     *      - Idle balance
     *      - Deployed assets in strategies
     *      - Accrued but not yet claimed rewards
     *      Here we simply check the vault's balance
     */
    function totalAssets() public view virtual override returns (uint256) {
        return _asset.balanceOf(address(this));
    }

    /*//////////////////////////////////////////////////////////////
                        MATH HELPERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Multiply and divide, rounding DOWN
     * @dev Standard division in Solidity truncates (rounds down for positive numbers)
     * @param x First multiplicand
     * @param y Second multiplicand
     * @param denominator Divisor
     * @return result (x * y) / denominator, rounded DOWN
     *
     * IMPLEMENTATION NOTES:
     * - Solidity 0.8+ has built-in overflow protection
     * - Division by zero will revert automatically
     * - No remainder handling needed for round-down
     *
     * EXAMPLE:
     * mulDiv(5, 3, 2) = 15 / 2 = 7 (not 7.5)
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // Solidity's division operator automatically:
        // 1. Checks for division by zero (reverts if denominator == 0)
        // 2. Rounds down (truncates decimal part)
        // 3. Checks for overflow in multiplication (Solidity 0.8+)
        result = (x * y) / denominator;
    }

    /**
     * @notice Multiply and divide, rounding UP
     * @dev Critical for vault security - ensures vault never loses value
     * @param x First multiplicand
     * @param y Second multiplicand
     * @param denominator Divisor
     * @return result (x * y) / denominator, rounded UP
     *
     * MATHEMATICAL FORMULA:
     * result = (x * y + denominator - 1) / denominator
     *
     * WHY IT WORKS:
     * Let product = x * y
     * Let quotient = product / denominator (rounded down)
     * Let remainder = product % denominator
     *
     * Case 1: remainder == 0 (exact division)
     *   (product + denominator - 1) / denominator
     *   = (quotient * denominator + denominator - 1) / denominator
     *   = quotient + (denominator - 1) / denominator
     *   = quotient + 0  (since denominator - 1 < denominator)
     *   = quotient ✓ (no rounding needed)
     *
     * Case 2: remainder > 0 (needs rounding up)
     *   (product + denominator - 1) / denominator
     *   = ((quotient * denominator + remainder) + denominator - 1) / denominator
     *   = (quotient * denominator + (remainder + denominator - 1)) / denominator
     *   = quotient + (remainder + denominator - 1) / denominator
     *
     *   Since 0 < remainder < denominator:
     *   denominator <= remainder + denominator - 1 < 2 * denominator
     *   Therefore: (remainder + denominator - 1) / denominator = 1
     *   = quotient + 1 ✓ (rounded up by 1)
     *
     * EXAMPLES:
     * mulDivUp(5, 3, 2):
     *   product = 15, remainder = 1
     *   (15 + 2 - 1) / 2 = 16 / 2 = 8 ✓ (7.5 → 8)
     *
     * mulDivUp(6, 3, 2):
     *   product = 18, remainder = 0
     *   (18 + 2 - 1) / 2 = 19 / 2 = 9 ✓ (9.0 → 9)
     *
     * SECURITY NOTE:
     * This function is used when the vault needs to round in its favor:
     * - Taking assets from user (mint)
     * - Burning shares from user (withdraw)
     */
    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // Calculate product
        uint256 product = x * y;

        // Get the result rounded down
        result = product / denominator;

        // Check if there's a remainder
        // If remainder exists, we need to round up
        if (product % denominator > 0) {
            result += 1;
        }

        // Alternative one-liner (more gas efficient):
        // result = (x * y + denominator - 1) / denominator;
        // But the above is clearer for educational purposes
    }

    /*//////////////////////////////////////////////////////////////
                        CONVERSION FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Convert assets to shares, rounding DOWN
     * @dev Used by deposit and previewDeposit
     * @param assets Amount of underlying assets
     * @return shares Amount of vault shares (rounded down)
     *
     * FORMULA: shares = assets * totalSupply / totalAssets
     *
     * ROUNDING: DOWN
     * WHY: Gives user fewer shares, vault keeps difference
     *
     * EDGE CASE HANDLING:
     * 1. Empty vault (totalSupply == 0):
     *    Return 1:1 ratio (shares = assets)
     *    First depositor establishes the initial exchange rate
     *
     * 2. Zero assets in vault but shares exist (totalAssets == 0, totalSupply > 0):
     *    This indicates vault has been drained or suffered a loss
     *    Should generally not happen, but handled conservatively
     *
     * ATTACK PREVENTION:
     * First depositor could deposit 1 wei, then donate large amount to inflate share price
     * This would cause rounding issues for subsequent depositors
     * Mitigation: Require minimum deposit or use virtual shares (not shown here)
     */
    function convertToShares(uint256 assets) public view virtual override returns (uint256) {
        uint256 supply = totalSupply();

        // EDGE CASE: Empty vault (first deposit)
        // Return 1:1 ratio - first depositor sets initial exchange rate
        // Example: Deposit 1000 assets → receive 1000 shares
        if (supply == 0) {
            return assets;
        }

        // NORMAL CASE: Calculate proportional shares
        // shares = (assets * totalSupply) / totalAssets
        // Uses mulDiv which rounds DOWN
        // Example: 100 assets, 1000 supply, 500 total assets
        //   shares = (100 * 1000) / 500 = 200 shares
        return mulDiv(assets, supply, totalAssets());
    }

    /**
     * @notice Convert shares to assets, rounding DOWN
     * @dev Used by redeem and previewRedeem
     * @param shares Amount of vault shares
     * @return assets Amount of underlying assets (rounded down)
     *
     * FORMULA: assets = shares * totalAssets / totalSupply
     *
     * ROUNDING: DOWN
     * WHY: Gives user fewer assets, vault keeps difference
     *
     * EDGE CASE HANDLING:
     * 1. No shares exist (totalSupply == 0):
     *    Return 0 (shares have no value if none exist)
     *
     * 2. Zero shares input:
     *    Return 0 (no shares = no assets)
     */
    function convertToAssets(uint256 shares) public view virtual override returns (uint256) {
        uint256 supply = totalSupply();

        // EDGE CASE: No shares exist
        // If no shares exist, they have no value
        if (supply == 0) {
            return 0;
        }

        // NORMAL CASE: Calculate proportional assets
        // assets = (shares * totalAssets) / totalSupply
        // Uses mulDiv which rounds DOWN
        // Example: 200 shares, 500 total assets, 1000 supply
        //   assets = (200 * 500) / 1000 = 100 assets
        return mulDiv(shares, totalAssets(), supply);
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LIMITS
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual override returns (uint256) {
        return convertToAssets(balanceOf(owner));
    }

    function maxRedeem(address owner) public view virtual override returns (uint256) {
        return balanceOf(owner);
    }

    /*//////////////////////////////////////////////////////////////
                        PREVIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Preview deposit: how many shares for given assets
     * @dev MUST round DOWN to match deposit()
     * @param assets Amount to deposit
     * @return shares Shares that would be received
     *
     * EIP-4626 REQUIREMENT:
     * "MUST return as close to and no fewer than the exact amount of shares
     * that would be minted in a deposit call in the same transaction."
     *
     * IMPLEMENTATION: Reuses convertToShares (already rounds down)
     */
    function previewDeposit(uint256 assets) public view virtual override returns (uint256) {
        return convertToShares(assets);
    }

    /**
     * @notice Preview mint: how many assets needed for given shares
     * @dev MUST round UP to match mint()
     * @param shares Amount to mint
     * @return assets Assets that would be required
     *
     * EIP-4626 REQUIREMENT:
     * "MUST return as close to and no more than the exact amount of assets
     * that would be deposited in a mint call in the same transaction."
     *
     * ROUNDING UP ENSURES:
     * - User pays enough to cover the exact shares requested
     * - Vault doesn't lose value
     * - Preview matches actual mint() behavior
     */
    function previewMint(uint256 shares) public view virtual override returns (uint256) {
        uint256 supply = totalSupply();

        // EDGE CASE: Empty vault, 1:1 ratio
        if (supply == 0) {
            return shares;
        }

        // NORMAL CASE: Round UP assets required
        // assets = roundUp((shares * totalAssets) / totalSupply)
        // User must pay this much to get exact shares
        return mulDivUp(shares, totalAssets(), supply);
    }

    /**
     * @notice Preview withdraw: how many shares needed for given assets
     * @dev MUST round UP to match withdraw()
     * @param assets Amount to withdraw
     * @return shares Shares that would be burned
     *
     * EIP-4626 REQUIREMENT:
     * "MUST return as close to and no fewer than the exact amount of shares
     * that would be burned in a withdraw call in the same transaction."
     *
     * ROUNDING UP ENSURES:
     * - User burns enough shares to cover the exact assets requested
     * - Vault doesn't lose value
     * - Preview matches actual withdraw() behavior
     */
    function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
        uint256 supply = totalSupply();

        // EDGE CASE: No shares exist, return 0
        if (supply == 0) {
            return 0;
        }

        // NORMAL CASE: Round UP shares required
        // shares = roundUp((assets * totalSupply) / totalAssets)
        // User must burn this many to get exact assets
        return mulDivUp(assets, supply, totalAssets());
    }

    /**
     * @notice Preview redeem: how many assets for given shares
     * @dev MUST round DOWN to match redeem()
     * @param shares Amount to redeem
     * @return assets Assets that would be received
     *
     * EIP-4626 REQUIREMENT:
     * "MUST return as close to and no more than the exact amount of assets
     * that would be withdrawn in a redeem call in the same transaction."
     *
     * IMPLEMENTATION: Reuses convertToAssets (already rounds down)
     */
    function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposit assets, receive shares
     * @param assets Amount of assets to deposit
     * @param receiver Who receives the shares
     * @return shares Amount of shares minted (rounded down)
     *
     * FLOW:
     * 1. Calculate shares (round DOWN) - convertToShares handles this
     * 2. Transfer assets from caller to vault
     * 3. Mint shares to receiver
     * 4. Emit event
     *
     * ROUNDING: DOWN (fewer shares to user)
     * SECURITY: User can't gain value through rounding
     *
     * EXAMPLE:
     * User deposits 100 assets
     * Exchange rate is 3:2 (1.5 assets per share)
     * shares = (100 * totalSupply) / totalAssets
     * If this equals 66.666..., rounds down to 66 shares
     * User "loses" 0.666... shares worth ~1 asset
     * This accumulates in vault's favor
     */
    function deposit(uint256 assets, address receiver) public virtual override returns (uint256 shares) {
        // STEP 1: Calculate shares (rounds down)
        shares = convertToShares(assets);

        // Ensure we're actually minting something
        require(shares > 0, "ERC4626: cannot mint 0 shares");

        // STEP 2: Transfer assets from caller to vault
        // SafeERC20 handles return value checks
        _asset.safeTransferFrom(msg.sender, address(this), assets);

        // STEP 3: Mint shares to receiver
        _mint(receiver, shares);

        // STEP 4: Emit event
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /**
     * @notice Mint exact shares, pay assets
     * @param shares Exact amount of shares to mint
     * @param receiver Who receives the shares
     * @return assets Amount of assets required (rounded up)
     *
     * FLOW:
     * 1. Calculate assets needed (round UP) - previewMint handles this
     * 2. Transfer assets from caller to vault
     * 3. Mint exact shares to receiver
     * 4. Emit event
     *
     * ROUNDING: UP (more assets from user)
     * SECURITY: Vault receives enough value for shares minted
     *
     * EXAMPLE:
     * User wants exactly 66 shares
     * Exchange rate is 3:2 (1.5 assets per share)
     * assets = roundUp((66 * totalAssets) / totalSupply)
     * If this equals 99.000..., rounds to 99 (no change)
     * If this equals 99.001..., rounds up to 100
     * User "pays" 0.999... extra assets
     * This accumulates in vault's favor
     */
    function mint(uint256 shares, address receiver) public virtual override returns (uint256 assets) {
        // STEP 1: Calculate assets needed (rounds up)
        assets = previewMint(shares);

        // STEP 2: Transfer assets from caller to vault
        _asset.safeTransferFrom(msg.sender, address(this), assets);

        // STEP 3: Mint exact shares to receiver
        _mint(receiver, shares);

        // STEP 4: Emit event
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /*//////////////////////////////////////////////////////////////
                        WITHDRAW/REDEEM LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Withdraw exact assets, burn shares
     * @param assets Exact amount of assets to withdraw
     * @param receiver Who receives the assets
     * @param owner Who owns the shares (must approve if not caller)
     * @return shares Amount of shares burned (rounded up)
     *
     * FLOW:
     * 1. Calculate shares to burn (round UP) - previewWithdraw handles this
     * 2. Handle allowance if caller != owner
     * 3. Burn shares from owner
     * 4. Transfer exact assets to receiver
     * 5. Emit event
     *
     * ROUNDING: UP (more shares burned)
     * SECURITY: Vault doesn't give out more value than shares burned
     *
     * EXAMPLE:
     * User wants exactly 100 assets
     * Exchange rate is 3:2 (1.5 assets per share)
     * shares = roundUp((100 * totalSupply) / totalAssets)
     * If this equals 66.666..., rounds up to 67 shares
     * User "loses" 0.333... shares worth ~0.5 assets
     * This accumulates in vault's favor
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override returns (uint256 shares) {
        // STEP 1: Calculate shares to burn (rounds up)
        shares = previewWithdraw(assets);

        // STEP 2: Handle allowance if needed
        _spendAllowance(owner, shares);

        // STEP 3: Burn shares from owner
        _burn(owner, shares);

        // STEP 4: Transfer exact assets to receiver
        _asset.safeTransfer(receiver, assets);

        // STEP 5: Emit event
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /**
     * @notice Redeem shares for assets
     * @param shares Amount of shares to burn
     * @param receiver Who receives the assets
     * @param owner Who owns the shares (must approve if not caller)
     * @return assets Amount of assets received (rounded down)
     *
     * FLOW:
     * 1. Calculate assets to give (round DOWN) - convertToAssets handles this
     * 2. Handle allowance if caller != owner
     * 3. Burn shares from owner
     * 4. Transfer assets to receiver
     * 5. Emit event
     *
     * ROUNDING: DOWN (fewer assets given)
     * SECURITY: Vault keeps difference between theoretical and actual
     *
     * EXAMPLE:
     * User redeems 67 shares
     * Exchange rate is 3:2 (1.5 assets per share)
     * assets = (67 * totalAssets) / totalSupply
     * If this equals 100.5, rounds down to 100 assets
     * User "loses" 0.5 assets
     * This accumulates in vault's favor
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override returns (uint256 assets) {
        // STEP 1: Calculate assets to give (rounds down)
        assets = convertToAssets(shares);

        // STEP 2: Handle allowance if needed
        _spendAllowance(owner, shares);

        // STEP 3: Burn shares from owner
        _burn(owner, shares);

        // STEP 4: Transfer assets to receiver
        _asset.safeTransfer(receiver, assets);

        // STEP 5: Emit event
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL HELPERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Spend allowance for withdraw/redeem operations
     * @param owner The owner of the shares
     * @param shares The amount of shares being spent
     *
     * SPECIAL CASE: If allowance is max uint256, don't decrease it
     * This allows for "infinite" approvals (common pattern)
     */
    function _spendAllowance(address owner, uint256 shares) internal {
        if (msg.sender != owner) {
            uint256 currentAllowance = allowance(owner, msg.sender);
            if (currentAllowance != type(uint256).max) {
                require(currentAllowance >= shares, "ERC4626: insufficient allowance");
                _approve(owner, msg.sender, currentAllowance - shares);
            }
        }
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. ROUNDING DIRECTION IS CRITICAL FOR SECURITY
 *    ✅ Deposit: Round DOWN shares (vault keeps extra)
 *    ✅ Mint: Round UP assets (user pays more)
 *    ✅ Withdraw: Round UP shares (user burns more)
 *    ✅ Redeem: Round DOWN assets (user receives less)
 *    ✅ Always favor vault to prevent exploitation
 *
 * 2. PREVIEW FUNCTIONS MUST MATCH ACTUAL BEHAVIOR
 *    ✅ previewDeposit() must equal actual deposit shares
 *    ✅ previewWithdraw() must equal actual withdraw shares
 *    ✅ Frontends rely on preview functions
 *    ✅ Must account for rounding correctly
 *    ✅ CONNECTION TO PROJECT 11: ERC-4626 standard!
 *
 * 3. EDGE CASES REQUIRE SPECIAL HANDLING
 *    ✅ First deposit: 1:1 ratio (no rounding)
 *    ✅ Zero supply: Handle division by zero
 *    ✅ Zero assets: Handle gracefully
 *    ✅ Very small amounts: May round to zero
 *
 * 4. PRECISION LOSS IS UNAVOIDABLE
 *    ✅ Integer division truncates
 *    ✅ Small amounts may round to zero
 *    ✅ Vault accumulates rounding "fees"
 *    ✅ Document expected behavior
 *
 * 5. MATHEMATICAL INVARIANTS MUST BE MAINTAINED
 *    ✅ totalAssets >= sum(user shares * price per share)
 *    ✅ Shares can't exceed assets value
 *    ✅ Rounding ensures vault always solvent
 *    ✅ Test invariants in all scenarios
 *
 * 6. PRODUCTION VAULTS USE OPENZEPPELIN
 *    ✅ Battle-tested rounding logic
 *    ✅ Handles all edge cases
 *    ✅ Gas optimized
 *    ✅ Use instead of custom implementation
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMMON MISTAKES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ❌ Rounding in favor of users (allows exploitation!)
 * ❌ Preview functions don't match actual behavior (breaks frontends!)
 * ❌ Not handling first deposit edge case
 * ❌ Division by zero in edge cases
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          NEXT STEPS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * • Study OpenZeppelin ERC4626 implementation
 * • Learn about fixed-point arithmetic
 * • Explore precision optimization techniques
 * • Move to Project 43 to learn about yield vaults
 */
