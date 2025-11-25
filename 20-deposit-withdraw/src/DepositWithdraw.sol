// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Project20 - Deposit/Withdraw Accounting
 * @notice Skeleton implementation of share-based deposit/withdraw accounting
 * @dev Complete the TODOs to implement a simplified vault with slippage protection
 *
 * KEY CONCEPTS:
 * =============
 * - Share-based accounting: Users get shares representing proportional ownership
 * - Preview functions: Simulate transactions before executing
 * - Slippage protection: Prevent front-running losses
 * - Rounding: Always favor the vault (protocol) over users
 *
 * MATH FORMULAS:
 * ==============
 * shares = (assets * totalShares) / totalAssets
 * assets = (shares * totalAssets) / totalShares
 *
 * ROUNDING RULES:
 * ===============
 * - Deposit: Round DOWN shares given to user
 * - Withdraw: Round UP shares taken from user
 */

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Project20 {
    // ═══════════════════════════════════════════════════════════════
    // STATE VARIABLES
    // ═══════════════════════════════════════════════════════════════

    IERC20 public immutable token;

    // Share tracking
    mapping(address => uint256) public shares;
    uint256 public totalShares;

    // Asset tracking (internal accounting to prevent donation attacks)
    uint256 private _totalAssets;

    // TODO: Add reentrancy guard variable

    // ═══════════════════════════════════════════════════════════════
    // EVENTS
    // ═══════════════════════════════════════════════════════════════

    // TODO: Add Deposit event (sender, assets, shares)
    // TODO: Add Withdraw event (sender, assets, shares)

    // ═══════════════════════════════════════════════════════════════
    // ERRORS
    // ═══════════════════════════════════════════════════════════════

    // TODO: Add custom errors for better gas efficiency
    // Examples: ZeroAmount, ZeroShares, InsufficientShares, SlippageTooHigh

    // ═══════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════

    constructor(address _token) {
        token = IERC20(_token);
    }

    // ═══════════════════════════════════════════════════════════════
    // CORE FUNCTIONS
    // ═══════════════════════════════════════════════════════════════

    /**
     * @notice Deposit assets and receive shares
     * @param assets Amount of tokens to deposit
     * @return sharesOut Amount of shares minted
     *
     * TODO: Implement deposit logic
     * Steps:
     * 1. Validate assets > 0
     * 2. Convert assets to shares using convertToShares()
     * 3. Validate shares > 0 (prevent zero-share deposits)
     * 4. Transfer tokens from user to contract
     * 5. Update _totalAssets
     * 6. Update user's shares
     * 7. Update totalShares
     * 8. Emit Deposit event
     */
    function deposit(uint256 assets) external returns (uint256 sharesOut) {
        // TODO: Implement
    }

    /**
     * @notice Deposit assets with minimum share protection (slippage)
     * @param assets Amount of tokens to deposit
     * @param minShares Minimum shares to receive (reverts if less)
     * @return sharesOut Amount of shares minted
     *
     * TODO: Implement deposit with slippage protection
     * Steps:
     * 1. Call internal deposit logic (or deposit function)
     * 2. Require sharesOut >= minShares
     */
    function depositWithSlippage(uint256 assets, uint256 minShares)
        external
        returns (uint256 sharesOut)
    {
        // TODO: Implement
    }

    /**
     * @notice Withdraw assets by burning shares
     * @param assets Amount of tokens to withdraw
     * @return sharesIn Amount of shares burned
     *
     * TODO: Implement withdraw logic
     * Steps:
     * 1. Validate assets > 0
     * 2. Convert assets to shares using convertToSharesRoundUp()
     * 3. Validate user has enough shares
     * 4. Update user's shares
     * 5. Update totalShares
     * 6. Update _totalAssets
     * 7. Transfer tokens from contract to user
     * 8. Emit Withdraw event
     *
     * IMPORTANT: Use convertToSharesRoundUp to round AGAINST the user
     */
    function withdraw(uint256 assets) external returns (uint256 sharesIn) {
        // TODO: Implement
    }

    /**
     * @notice Withdraw assets with maximum share protection (slippage)
     * @param assets Amount of tokens to withdraw
     * @param maxShares Maximum shares to burn (reverts if more)
     * @return sharesIn Amount of shares burned
     *
     * TODO: Implement withdraw with slippage protection
     * Steps:
     * 1. Call internal withdraw logic (or withdraw function)
     * 2. Require sharesIn <= maxShares
     */
    function withdrawWithSlippage(uint256 assets, uint256 maxShares)
        external
        returns (uint256 sharesIn)
    {
        // TODO: Implement
    }

    // ═══════════════════════════════════════════════════════════════
    // VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════

    /**
     * @notice Get total assets held by the vault
     * @return Total assets (uses internal accounting, not balanceOf)
     */
    function totalAssets() public view returns (uint256) {
        return _totalAssets;
    }

    /**
     * @notice Convert assets to shares (rounds DOWN)
     * @param assets Amount of assets
     * @return Amount of shares
     *
     * TODO: Implement conversion
     * Formula: shares = (assets * totalShares) / totalAssets
     * Special case: If totalShares == 0, return assets (1:1 ratio for first deposit)
     *
     * IMPORTANT: This uses integer division which rounds DOWN
     * This favors the vault on deposits (user gets slightly fewer shares)
     */
    function convertToShares(uint256 assets) public view returns (uint256) {
        // TODO: Implement
    }

    /**
     * @notice Convert assets to shares (rounds UP)
     * @param assets Amount of assets
     * @return Amount of shares (rounded up)
     *
     * TODO: Implement conversion with rounding up
     * Formula: shares = (assets * totalShares + totalAssets - 1) / totalAssets
     * This is used for withdrawals to favor the vault
     *
     * IMPORTANT: This rounds UP, taking more shares from user on withdraw
     */
    function convertToSharesRoundUp(uint256 assets) public view returns (uint256) {
        // TODO: Implement
    }

    /**
     * @notice Convert shares to assets (rounds DOWN)
     * @param sharesAmount Amount of shares
     * @return Amount of assets
     *
     * TODO: Implement conversion
     * Formula: assets = (shares * totalAssets) / totalShares
     * Special case: If totalShares == 0, return shares
     *
     * IMPORTANT: This uses integer division which rounds DOWN
     * This favors the vault on redemptions (user gets slightly fewer assets)
     */
    function convertToAssets(uint256 sharesAmount) public view returns (uint256) {
        // TODO: Implement
    }

    // ═══════════════════════════════════════════════════════════════
    // PREVIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════

    /**
     * @notice Preview how many shares you'd get for depositing assets
     * @param assets Amount of assets to deposit
     * @return shares Amount of shares that would be minted
     *
     * TODO: Implement preview
     * Hint: Should match what deposit() returns
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares) {
        // TODO: Implement
    }

    /**
     * @notice Preview how many shares you'd burn for withdrawing assets
     * @param assets Amount of assets to withdraw
     * @return shares Amount of shares that would be burned
     *
     * TODO: Implement preview
     * Hint: Should match what withdraw() returns
     * Use convertToSharesRoundUp since withdraw rounds against user
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares) {
        // TODO: Implement
    }

    // ═══════════════════════════════════════════════════════════════
    // HELPER FUNCTIONS (OPTIONAL)
    // ═══════════════════════════════════════════════════════════════

    /**
     * @notice Calculate division rounding up
     * @param x Numerator
     * @param y Denominator
     * @return Result rounded up
     *
     * HINT: (x + y - 1) / y is a common pattern for rounding up
     */
    function _divUp(uint256 x, uint256 y) internal pure returns (uint256) {
        // TODO: Implement (optional helper)
        // return (x + y - 1) / y;
    }
}
