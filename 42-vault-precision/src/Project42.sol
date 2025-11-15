// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Project42 - ERC-4626 Precision & Rounding Vault
 * @notice Educational implementation focusing on correct rounding mathematics
 * @dev Students implement proper rounding for vault security
 *
 * LEARNING OBJECTIVES:
 * 1. Understand WHY rounding direction matters for vault security
 * 2. Implement mulDiv with round-up capability
 * 3. Handle edge cases (zero denominators, first deposit)
 * 4. Ensure preview functions match action rounding
 * 5. Prevent precision-based attacks
 *
 * CRITICAL RULE: ALWAYS ROUND IN VAULT'S FAVOR
 * - Deposit: Round DOWN shares given to user
 * - Mint: Round UP assets taken from user
 * - Withdraw: Round UP shares taken from user
 * - Redeem: Round DOWN assets given to user
 */
contract Project42 is ERC20, IERC4626 {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    IERC20 private immutable _asset;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the vault
     * @param asset_ The underlying ERC20 token
     * @param name_ The vault share token name
     * @param symbol_ The vault share token symbol
     */
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

    /**
     * @notice Returns the address of the underlying token
     * @return The underlying asset address
     */
    function asset() public view virtual override returns (address) {
        return address(_asset);
    }

    /*//////////////////////////////////////////////////////////////
                        ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns total assets held by vault
     * @dev This is the sum of all underlying tokens the vault controls
     * @return Total assets in vault
     *
     * NOTE: In a real vault, this might include:
     * - Idle balance in vault
     * - Assets deployed to strategies
     * - Pending rewards
     * For simplicity, we just check our balance
     */
    function totalAssets() public view virtual override returns (uint256) {
        return _asset.balanceOf(address(this));
    }

    /*//////////////////////////////////////////////////////////////
                        MATH HELPERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Multiply two numbers and divide by a third, rounding DOWN
     * @dev Standard Solidity division rounds down by default
     * @param x First multiplicand
     * @param y Second multiplicand
     * @param denominator The divisor
     * @return result The result of (x * y) / denominator, rounded DOWN
     *
     * MATH EXPLANATION:
     * - Solidity's division operator / always truncates (rounds toward zero)
     * - For positive numbers, this means rounding DOWN
     * - Example: 5 / 2 = 2 (not 2.5)
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // TODO: Implement multiplication with division, rounding DOWN
        // HINT: Solidity's default division already rounds down
        // HINT: Be careful of overflow in multiplication!

        // Your code here
    }

    /**
     * @notice Multiply two numbers and divide by a third, rounding UP
     * @dev This is CRITICAL for vault security - used when we need to favor vault
     * @param x First multiplicand
     * @param y Second multiplicand
     * @param denominator The divisor
     * @return result The result of (x * y) / denominator, rounded UP
     *
     * MATH EXPLANATION:
     * To round up, we use: (x * y + denominator - 1) / denominator
     *
     * WHY THIS WORKS:
     * Let q = (x * y) / denominator (quotient, rounded down)
     * Let r = (x * y) % denominator (remainder)
     *
     * If r > 0 (there's a remainder):
     *   (x * y + denominator - 1) / denominator
     *   = ((q * denominator + r) + denominator - 1) / denominator
     *   = (q * denominator + (r + denominator - 1)) / denominator
     *   = q + (r + denominator - 1) / denominator
     *
     *   Since 0 < r < denominator:
     *   denominator <= (r + denominator - 1) < 2 * denominator
     *   So (r + denominator - 1) / denominator = 1
     *   Result = q + 1 ✓ (rounded up)
     *
     * If r = 0 (no remainder):
     *   (x * y + denominator - 1) / denominator
     *   = (q * denominator + denominator - 1) / denominator
     *   = q + (denominator - 1) / denominator
     *   = q + 0  (since denominator - 1 < denominator)
     *   Result = q ✓ (no change needed)
     *
     * EXAMPLE:
     * 5 * 3 / 2 = 15 / 2
     * Round down: 15 / 2 = 7
     * Round up: (15 + 2 - 1) / 2 = 16 / 2 = 8 ✓
     */
    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // TODO: Implement rounding UP
        // HINT: Use formula (x * y + denominator - 1) / denominator
        // HINT: But only if (x * y) % denominator > 0!
        // HINT: Be careful of overflow!

        // Your code here
    }

    /*//////////////////////////////////////////////////////////////
                        CONVERSION FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Convert assets to shares
     * @dev Used by deposit - rounds DOWN to give user fewer shares (vault favorable)
     * @param assets Amount of underlying assets
     * @return shares Amount of vault shares
     *
     * FORMULA: shares = assets * totalSupply / totalAssets
     *
     * ROUNDING: DOWN (gives user minimum shares)
     * WHY: If we rounded up, user gets MORE shares for same assets = bad for vault
     *
     * EDGE CASES:
     * 1. totalSupply == 0 (empty vault): Return 1:1 (shares = assets)
     * 2. totalAssets == 0: Should not happen if supply > 0, but handle safely
     */
    function convertToShares(uint256 assets) public view virtual override returns (uint256) {
        // TODO: Implement asset to share conversion
        // HINT: Check if totalSupply is 0 first (empty vault case)
        // HINT: Use mulDiv (rounds down) for normal case
        // HINT: Formula: (assets * totalSupply) / totalAssets

        // Your code here
    }

    /**
     * @notice Convert shares to assets
     * @dev Used by redeem - rounds DOWN to give user fewer assets (vault favorable)
     * @param shares Amount of vault shares
     * @return assets Amount of underlying assets
     *
     * FORMULA: assets = shares * totalAssets / totalSupply
     *
     * ROUNDING: DOWN (gives user minimum assets)
     * WHY: If we rounded up, user gets MORE assets for same shares = bad for vault
     *
     * EDGE CASES:
     * 1. totalSupply == 0: Return 0 (no shares exist, no value)
     * 2. shares == 0: Return 0
     */
    function convertToAssets(uint256 shares) public view virtual override returns (uint256) {
        // TODO: Implement share to asset conversion
        // HINT: Check if totalSupply is 0 (should return 0)
        // HINT: Use mulDiv (rounds down) for normal case
        // HINT: Formula: (shares * totalAssets) / totalSupply

        // Your code here
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LIMITS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Maximum assets that can be deposited
     * @dev For this simple vault, no limit
     */
    function maxDeposit(address) public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    /**
     * @notice Maximum shares that can be minted
     * @dev For this simple vault, no limit
     */
    function maxMint(address) public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    /**
     * @notice Maximum assets that can be withdrawn by owner
     * @dev Limited by owner's share balance converted to assets
     */
    function maxWithdraw(address owner) public view virtual override returns (uint256) {
        return convertToAssets(balanceOf(owner));
    }

    /**
     * @notice Maximum shares that can be redeemed by owner
     * @dev Limited by owner's share balance
     */
    function maxRedeem(address owner) public view virtual override returns (uint256) {
        return balanceOf(owner);
    }

    /*//////////////////////////////////////////////////////////////
                        PREVIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Preview how many shares would be minted for an asset deposit
     * @dev MUST round DOWN (same as deposit)
     * @param assets Amount of assets to deposit
     * @return shares Amount of shares that would be minted
     *
     * PER EIP-4626:
     * "MUST return as close to and no fewer than the exact amount of shares
     * that would be minted in a deposit call in the same transaction."
     *
     * Translation: Must round DOWN (same direction as deposit)
     */
    function previewDeposit(uint256 assets) public view virtual override returns (uint256) {
        // TODO: Implement preview for deposit
        // HINT: This should match the rounding of deposit()
        // HINT: Can you reuse convertToShares()?

        // Your code here
    }

    /**
     * @notice Preview how many assets are needed to mint exact shares
     * @dev MUST round UP (vault favorable)
     * @param shares Amount of shares to mint
     * @return assets Amount of assets that would be required
     *
     * PER EIP-4626:
     * "MUST return as close to and no more than the exact amount of assets
     * that would be deposited in a mint call in the same transaction."
     *
     * Translation: Must round UP (more assets required = vault favorable)
     *
     * ROUNDING EXPLANATION:
     * - User wants exact X shares
     * - We calculate: assets = shares * totalAssets / totalSupply
     * - If we round DOWN: User pays LESS, gets EXACT shares = bad for vault
     * - If we round UP: User pays MORE, gets EXACT shares = good for vault ✓
     */
    function previewMint(uint256 shares) public view virtual override returns (uint256) {
        // TODO: Implement preview for mint
        // HINT: Check if totalSupply is 0 (empty vault)
        // HINT: Use mulDivUp to round UP
        // HINT: Formula: roundUp((shares * totalAssets) / totalSupply)

        // Your code here
    }

    /**
     * @notice Preview how many shares needed to withdraw exact assets
     * @dev MUST round UP (vault favorable)
     * @param assets Amount of assets to withdraw
     * @return shares Amount of shares that would be burned
     *
     * PER EIP-4626:
     * "MUST return as close to and no fewer than the exact amount of shares
     * that would be burned in a withdraw call in the same transaction."
     *
     * Translation: Must round UP (more shares burned = vault favorable)
     *
     * ROUNDING EXPLANATION:
     * - User wants exact X assets out
     * - We calculate: shares = assets * totalSupply / totalAssets
     * - If we round DOWN: Burn LESS shares, give EXACT assets = bad for vault
     * - If we round UP: Burn MORE shares, give EXACT assets = good for vault ✓
     */
    function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
        // TODO: Implement preview for withdraw
        // HINT: Check if totalSupply is 0
        // HINT: Use mulDivUp to round UP
        // HINT: Formula: roundUp((assets * totalSupply) / totalAssets)

        // Your code here
    }

    /**
     * @notice Preview how many assets received for redeeming shares
     * @dev MUST round DOWN (vault favorable)
     * @param shares Amount of shares to redeem
     * @return assets Amount of assets that would be received
     *
     * PER EIP-4626:
     * "MUST return as close to and no more than the exact amount of assets
     * that would be withdrawn in a redeem call in the same transaction."
     *
     * Translation: Must round DOWN (fewer assets given = vault favorable)
     */
    function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
        // TODO: Implement preview for redeem
        // HINT: This should match the rounding of redeem()
        // HINT: Can you reuse convertToAssets()?

        // Your code here
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposit assets and receive shares
     * @param assets Amount of underlying assets to deposit
     * @param receiver Address that will receive the shares
     * @return shares Amount of shares minted
     *
     * ROUNDING: DOWN (give user fewer shares)
     * INVARIANT: User must receive at least previewDeposit(assets) shares
     *
     * FLOW:
     * 1. Calculate shares (round DOWN)
     * 2. Transfer assets from caller to vault
     * 3. Mint shares to receiver
     */
    function deposit(uint256 assets, address receiver) public virtual override returns (uint256 shares) {
        // TODO: Implement deposit
        // STEP 1: Calculate shares using convertToShares (rounds down)
        // STEP 2: Transfer assets from msg.sender to this contract
        // STEP 3: Mint shares to receiver
        // STEP 4: Emit Deposit event
        // STEP 5: Return shares

        // Your code here
    }

    /**
     * @notice Mint exact shares by depositing assets
     * @param shares Exact amount of shares to mint
     * @param receiver Address that will receive the shares
     * @return assets Amount of assets deposited
     *
     * ROUNDING: UP (take more assets from user)
     * INVARIANT: Must take at most previewMint(shares) assets
     *
     * FLOW:
     * 1. Calculate assets needed (round UP)
     * 2. Transfer assets from caller to vault
     * 3. Mint exact shares to receiver
     */
    function mint(uint256 shares, address receiver) public virtual override returns (uint256 assets) {
        // TODO: Implement mint
        // STEP 1: Calculate assets using previewMint (rounds up)
        // STEP 2: Transfer assets from msg.sender to this contract
        // STEP 3: Mint exact shares to receiver
        // STEP 4: Emit Deposit event
        // STEP 5: Return assets

        // Your code here
    }

    /*//////////////////////////////////////////////////////////////
                        WITHDRAW/REDEEM LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Withdraw exact assets by burning shares
     * @param assets Exact amount of assets to withdraw
     * @param receiver Address that will receive the assets
     * @param owner Address that owns the shares (must approve if not caller)
     * @return shares Amount of shares burned
     *
     * ROUNDING: UP (burn more shares from user)
     * INVARIANT: Must burn at most previewWithdraw(assets) shares
     *
     * FLOW:
     * 1. Calculate shares to burn (round UP)
     * 2. If caller is not owner, check and update allowance
     * 3. Burn shares from owner
     * 4. Transfer exact assets to receiver
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override returns (uint256 shares) {
        // TODO: Implement withdraw
        // STEP 1: Calculate shares using previewWithdraw (rounds up)
        // STEP 2: If msg.sender != owner, check allowance and update
        // STEP 3: Burn shares from owner
        // STEP 4: Transfer assets to receiver
        // STEP 5: Emit Withdraw event
        // STEP 6: Return shares

        // Your code here
    }

    /**
     * @notice Redeem shares for assets
     * @param shares Amount of shares to burn
     * @param receiver Address that will receive the assets
     * @param owner Address that owns the shares (must approve if not caller)
     * @return assets Amount of assets withdrawn
     *
     * ROUNDING: DOWN (give user fewer assets)
     * INVARIANT: User must receive at least previewRedeem(shares) assets
     *
     * FLOW:
     * 1. Calculate assets to give (round DOWN)
     * 2. If caller is not owner, check and update allowance
     * 3. Burn shares from owner
     * 4. Transfer assets to receiver
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override returns (uint256 assets) {
        // TODO: Implement redeem
        // STEP 1: Calculate assets using convertToAssets (rounds down)
        // STEP 2: If msg.sender != owner, check allowance and update
        // STEP 3: Burn shares from owner
        // STEP 4: Transfer assets to receiver
        // STEP 5: Emit Withdraw event
        // STEP 6: Return assets

        // Your code here
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL HELPERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Internal helper to handle allowance for withdraw/redeem
     * @param owner The owner of the shares
     * @param shares The amount of shares being spent
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
