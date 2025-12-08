// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DepositWithdrawSolution
 * @notice Share-based deposit/withdraw accounting for yield-bearing vaults
 * 
 * PURPOSE: Proportional ownership accounting that handles yield automatically
 * CS CONCEPTS: Proportional math, share-based accounting, precision handling
 * 
 * CONNECTIONS:
 * - Project 11: ERC-4626 uses this exact pattern
 * - Project 06: Running totals for totalAssets/totalShares
 * - Project 02: CEI pattern for deposits/withdrawals
 * 
 * KEY MATH: shares = (assets * totalShares) / totalAssets (proportional minting)
 * Enables yield distribution without tracking individual user balances
 *
 * WITHDRAW (shares → assets):
 *   assets = (shares * totalAssets) / totalShares
 *
 *   Example: Vault has 1000 assets, 900 shares
 *   User redeems 90 shares
 *   assets = (90 * 1000) / 900 = 100 assets
 *   (User gets proportional value)
 *
 * ROUNDING STRATEGY:
 * ==================
 * Always round AGAINST the user, in FAVOR of the vault:
 *
 * - Deposit: Round DOWN shares (user gets fewer shares)
 *   shares = (assets * totalShares) / totalAssets  // Integer division truncates
 *
 * - Withdraw: Round UP shares burned (user burns more shares)
 *   shares = (assets * totalShares + totalAssets - 1) / totalAssets
 *
 * Why? Attackers could exploit favorable rounding to drain the vault.
 * Small rounding "fees" accumulate in vault as protection.
 *
 * SLIPPAGE PROTECTION:
 * ====================
 * Exchange rate can change between preview and execution (front-running).
 *
 * Example attack:
 *   1. Alice previews: deposit 1000 → expect 100 shares
 *   2. MEV bot front-runs with large deposit, changing rate
 *   3. Alice gets only 90 shares (lost value!)
 *
 * Solution: Let users specify min/max acceptable amounts:
 *   depositWithSlippage(1000 assets, 95 minShares)
 *   If < 95 shares, transaction reverts
 *
 * ATTACK MITIGATIONS:
 * ===================
 *
 * 1. Inflation Attack:
 *    - First depositor gets 1 share for 1 wei
 *    - Attacker donates 1000 ETH to vault
 *    - Now 1 share = 1000 ETH
 *    - Victim deposits 999 ETH, gets 0 shares (rounds down)
 *
 *    Mitigation: Require shares > 0, or mint dead shares on first deposit
 *
 * 2. Donation Attack:
 *    - Attacker sends tokens directly to vault
 *    - If using balanceOf for accounting, this breaks share math
 *
 *    Mitigation: Use internal _totalAssets counter, not balanceOf
 *
 * 3. Front-running:
 *    - Attacker sees deposit in mempool, front-runs to change rate
 *
 *    Mitigation: Slippage protection (minShares, maxShares parameters)
 *
 * ════════════════════════════════════════════════════════════════════════════
 */

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Project20Solution {
    // ═══════════════════════════════════════════════════════════════
    // STATE VARIABLES
    // ═══════════════════════════════════════════════════════════════

    /// @notice The underlying ERC20 token
    IERC20 public immutable token;

    /// @notice User share balances
    mapping(address => uint256) public shares;

    /// @notice Total shares minted across all users
    uint256 public totalShares;

    /// @notice Total assets in vault (internal accounting)
    /// @dev Uses internal counter instead of balanceOf to prevent donation attack
    uint256 private _totalAssets;

    /// @notice Simple reentrancy guard
    uint256 private _locked = 1;

    // ═══════════════════════════════════════════════════════════════
    // EVENTS
    // ═══════════════════════════════════════════════════════════════

    /// @notice Emitted when user deposits assets
    event Deposit(address indexed sender, uint256 assets, uint256 shares);

    /// @notice Emitted when user withdraws assets
    event Withdraw(address indexed sender, uint256 assets, uint256 shares);

    // ═══════════════════════════════════════════════════════════════
    // ERRORS
    // ═══════════════════════════════════════════════════════════════

    error ZeroAmount();
    error ZeroShares();
    error InsufficientShares();
    error SlippageTooHigh();
    error ReentrantCall();
    error TransferFailed();

    // ═══════════════════════════════════════════════════════════════
    // MODIFIERS
    // ═══════════════════════════════════════════════════════════════

    modifier nonReentrant() {
        if (_locked != 1) revert ReentrantCall();
        _locked = 2;
        _;
        _locked = 1;
    }

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
     * FLOW:
     *   1. Validate assets > 0
     *   2. Calculate shares = (assets * totalShares) / totalAssets
     *   3. Handle first deposit (totalShares == 0) → 1:1 ratio
     *   4. Validate shares > 0 (prevent zero-share attack)
     *   5. Transfer tokens from user to vault
     *   6. Update internal accounting
     *   7. Mint shares to user
     *   8. Emit event
     *
     * SECURITY:
     *   - Reentrancy guard
     *   - Rounds DOWN shares (favors vault)
     *   - Requires shares > 0 (prevents inflation attack)
     *   - Updates state BEFORE external call (CEI pattern)
     */
    function deposit(uint256 assets) public nonReentrant returns (uint256 sharesOut) {
        // Validate input
        if (assets == 0) revert ZeroAmount();

        // Calculate shares to mint (rounds DOWN to favor vault)
        sharesOut = convertToShares(assets);

        // Prevent zero-share deposits (inflation attack mitigation)
        if (sharesOut == 0) revert ZeroShares();

        // Update accounting BEFORE external call (Checks-Effects-Interactions)
        _totalAssets += assets;
        shares[msg.sender] += sharesOut;
        totalShares += sharesOut;

        // Transfer tokens from user to vault
        bool success = token.transferFrom(msg.sender, address(this), assets);
        if (!success) revert TransferFailed();

        emit Deposit(msg.sender, assets, sharesOut);
    }

    /**
     * @notice Deposit assets with minimum share protection (slippage)
     * @param assets Amount of tokens to deposit
     * @param minShares Minimum shares to receive (reverts if less)
     * @return sharesOut Amount of shares minted
     *
     * USE CASE:
     *   User previews deposit: 1000 assets → 100 shares
     *   User sets minShares = 95 (5% slippage tolerance)
     *   If front-runner changes rate and user would get < 95 shares, reverts
     *
     * CALCULATION:
     *   expectedShares = previewDeposit(1000)  // Returns 100
     *   slippageTolerance = 5%
     *   minShares = expectedShares * 95 / 100 = 95
     *   depositWithSlippage(1000, 95)
     */
    function depositWithSlippage(uint256 assets, uint256 minShares)
        external
        returns (uint256 sharesOut)
    {
        sharesOut = deposit(assets);

        // Revert if slippage exceeded
        if (sharesOut < minShares) revert SlippageTooHigh();
    }

    /**
     * @notice Withdraw assets by burning shares
     * @param assets Amount of tokens to withdraw
     * @return sharesIn Amount of shares burned
     *
     * FLOW:
     *   1. Validate assets > 0
     *   2. Calculate shares = (assets * totalShares) / totalAssets (ROUND UP!)
     *   3. Validate user has enough shares
     *   4. Burn shares from user
     *   5. Update internal accounting
     *   6. Transfer tokens from vault to user
     *   7. Emit event
     *
     * SECURITY:
     *   - Reentrancy guard
     *   - Rounds UP shares burned (favors vault)
     *   - Updates state BEFORE external call
     *
     * ROUNDING:
     *   Uses convertToSharesRoundUp to take MORE shares from user.
     *   This prevents users from withdrawing more assets than their fair share.
     *
     *   Example: User wants 100 assets, calculation gives 99.9 shares
     *   - Round down: burn 99 shares (user could slowly drain vault)
     *   - Round up: burn 100 shares (vault is protected) ✓
     */
    function withdraw(uint256 assets) public nonReentrant returns (uint256 sharesIn) {
        // Validate input
        if (assets == 0) revert ZeroAmount();

        // Calculate shares to burn (rounds UP to favor vault)
        sharesIn = convertToSharesRoundUp(assets);

        // Validate user has enough shares
        if (shares[msg.sender] < sharesIn) revert InsufficientShares();

        // Update accounting BEFORE external call
        shares[msg.sender] -= sharesIn;
        totalShares -= sharesIn;
        _totalAssets -= assets;

        // Transfer tokens from vault to user
        bool success = token.transfer(msg.sender, assets);
        if (!success) revert TransferFailed();

        emit Withdraw(msg.sender, assets, sharesIn);
    }

    /**
     * @notice Withdraw assets with maximum share protection (slippage)
     * @param assets Amount of tokens to withdraw
     * @param maxShares Maximum shares to burn (reverts if more)
     * @return sharesIn Amount of shares burned
     *
     * USE CASE:
     *   User previews withdraw: 1000 assets → 100 shares burned
     *   User sets maxShares = 105 (5% slippage tolerance)
     *   If front-runner changes rate and user must burn > 105 shares, reverts
     *
     * CALCULATION:
     *   expectedShares = previewWithdraw(1000)  // Returns 100
     *   slippageTolerance = 5%
     *   maxShares = expectedShares * 105 / 100 = 105
     *   withdrawWithSlippage(1000, 105)
     */
    function withdrawWithSlippage(uint256 assets, uint256 maxShares)
        external
        returns (uint256 sharesIn)
    {
        sharesIn = withdraw(assets);

        // Revert if slippage exceeded
        if (sharesIn > maxShares) revert SlippageTooHigh();
    }

    // ═══════════════════════════════════════════════════════════════
    // VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════

    /**
     * @notice Get total assets held by the vault
     * @return Total assets (uses internal accounting, not balanceOf)
     *
     * SECURITY NOTE:
     *   We use _totalAssets instead of token.balanceOf(address(this))
     *   to prevent donation attacks.
     *
     *   If we used balanceOf:
     *     1. Vault has 1000 assets, 1000 shares (1:1 ratio)
     *     2. Attacker sends 1000 tokens directly to vault
     *     3. balanceOf returns 2000, but totalShares still 1000
     *     4. Each share now "worth" 2 tokens, but who gets the profit?
     *     5. Share math breaks, users can steal tokens
     *
     *   With internal accounting:
     *     1. Vault has 1000 _totalAssets, 1000 shares
     *     2. Attacker sends 1000 tokens directly
     *     3. _totalAssets still 1000 (ignores the donation)
     *     4. Share math remains correct
     *     5. Donated tokens are stuck in contract (attacker loses money)
     */
    function totalAssets() public view returns (uint256) {
        return _totalAssets;
    }

    /**
     * @notice Convert assets to shares (rounds DOWN)
     * @param assets Amount of assets
     * @return Amount of shares
     *
     * FORMULA: shares = (assets * totalShares) / totalAssets
     *
     * SPECIAL CASE: First deposit (totalShares == 0)
     *   Return assets directly for 1:1 ratio
     *   This bootstraps the vault
     *
     * ROUNDING:
     *   Integer division rounds DOWN
     *   Example: (100 * 999) / 1000 = 99.9 → 99 shares
     *   User deposits 100, gets 99 shares
     *   Vault keeps the 0.9 share worth as "fee"
     *
     * WHY ROUND DOWN?
     *   If we rounded UP, user could get MORE than their fair share
     *   Over many deposits, attackers could drain the vault
     *   Rounding down means vault slowly accumulates value = protection
     */
    function convertToShares(uint256 assets) public view returns (uint256) {
        uint256 supply = totalShares;

        // First deposit: 1:1 ratio
        if (supply == 0) {
            return assets;
        }

        // Subsequent deposits: proportional to existing shares
        // Integer division rounds DOWN (favors vault)
        return (assets * supply) / totalAssets();
    }

    /**
     * @notice Convert assets to shares (rounds UP)
     * @param assets Amount of assets
     * @return Amount of shares (rounded up)
     *
     * FORMULA: shares = (assets * totalShares + totalAssets - 1) / totalAssets
     *
     * MATH EXPLANATION:
     *   To round up: (x + y - 1) / y
     *
     *   Example: (100 * 999 + 1000 - 1) / 1000
     *          = (99900 + 999) / 1000
     *          = 100899 / 1000
     *          = 100.899 → 100 shares (rounds up)
     *
     *   Compare to round down: (100 * 999) / 1000 = 99 shares
     *
     * WHY ROUND UP?
     *   Used for withdrawals
     *   User wants 100 assets, calculation gives 99.9 shares
     *   If we rounded down (99 shares), user gets 100 assets for 99 shares
     *   Over many withdrawals, attackers could drain vault
     *   Rounding up (100 shares) means user pays fair price
     *
     * USAGE:
     *   - withdraw() uses this
     *   - previewWithdraw() uses this
     */
    function convertToSharesRoundUp(uint256 assets) public view returns (uint256) {
        uint256 supply = totalShares;

        // First withdrawal: 1:1 ratio
        if (supply == 0) {
            return assets;
        }

        // Round up using: (x + y - 1) / y formula
        uint256 numerator = assets * supply;
        uint256 denominator = totalAssets();

        // Add (denominator - 1) before dividing to round up
        return (numerator + denominator - 1) / denominator;
    }

    /**
     * @notice Convert shares to assets (rounds DOWN)
     * @param sharesAmount Amount of shares
     * @return Amount of assets
     *
     * FORMULA: assets = (shares * totalAssets) / totalShares
     *
     * SPECIAL CASE: No shares exist (totalShares == 0)
     *   Return shares directly (shouldn't happen in practice)
     *
     * ROUNDING:
     *   Integer division rounds DOWN
     *   Example: (100 * 1000) / 999 = 100.1 → 100 assets
     *   User redeems 100 shares, gets 100 assets
     *   Vault keeps the 0.1 asset as "fee"
     *
     * WHY ROUND DOWN?
     *   If we rounded UP, user gets MORE assets than fair share
     *   Rounding down protects vault from being drained
     *
     * USAGE:
     *   - Could be used for a redeem() function (not implemented here)
     *   - Useful for displaying user's asset balance
     */
    function convertToAssets(uint256 sharesAmount) public view returns (uint256) {
        uint256 supply = totalShares;

        // Edge case: no shares exist
        if (supply == 0) {
            return sharesAmount;
        }

        // Integer division rounds DOWN (favors vault)
        return (sharesAmount * totalAssets()) / supply;
    }

    // ═══════════════════════════════════════════════════════════════
    // PREVIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════

    /**
     * @notice Preview how many shares you'd get for depositing assets
     * @param assets Amount of assets to deposit
     * @return shares Amount of shares that would be minted
     *
     * PURPOSE:
     *   - Let users see outcome before transaction
     *   - Calculate slippage tolerance
     *   - Display in UI
     *
     * MUST MATCH:
     *   previewDeposit(x) must return same value as deposit(x)
     *   Otherwise users can't trust the preview
     *
     * EXAMPLE USAGE:
     *   uint256 expectedShares = vault.previewDeposit(1000);
     *   // expectedShares = 100
     *
     *   // Set 2% slippage tolerance
     *   uint256 minShares = expectedShares * 98 / 100;  // 98
     *
     *   // Execute with protection
     *   vault.depositWithSlippage(1000, minShares);
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares) {
        return convertToShares(assets);
    }

    /**
     * @notice Preview how many shares you'd burn for withdrawing assets
     * @param assets Amount of assets to withdraw
     * @return shares Amount of shares that would be burned
     *
     * PURPOSE:
     *   - Let users see cost before transaction
     *   - Calculate slippage tolerance
     *   - Display in UI
     *
     * MUST MATCH:
     *   previewWithdraw(x) must return same value as withdraw(x)
     *
     * IMPORTANT:
     *   Uses convertToSharesRoundUp (not convertToShares)
     *   Must match withdraw() logic
     *
     * EXAMPLE USAGE:
     *   uint256 expectedShares = vault.previewWithdraw(1000);
     *   // expectedShares = 100
     *
     *   // Set 2% slippage tolerance
     *   uint256 maxShares = expectedShares * 102 / 100;  // 102
     *
     *   // Execute with protection
     *   vault.withdrawWithSlippage(1000, maxShares);
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares) {
        return convertToSharesRoundUp(assets);
    }

    // ═══════════════════════════════════════════════════════════════
    // HELPER FUNCTIONS
    // ═══════════════════════════════════════════════════════════════

    /**
     * @notice Calculate division rounding up
     * @param x Numerator
     * @param y Denominator
     * @return Result rounded up
     *
     * FORMULA: (x + y - 1) / y
     *
     * MATH:
     *   Normal division: x / y (rounds down)
     *   Round up: (x + y - 1) / y
     *
     *   Example: x = 10, y = 3
     *   Round down: 10 / 3 = 3.33 → 3
     *   Round up: (10 + 3 - 1) / 3 = 12 / 3 = 4
     *
     * WHY IT WORKS:
     *   Adding (y-1) before dividing ensures any remainder causes round up
     *
     *   x = 9, y = 3:  (9 + 2) / 3 = 11/3 = 3.67 → 3 (no change, evenly divisible)
     *   x = 10, y = 3: (10 + 2) / 3 = 12/3 = 4 (rounded up from 3.33)
     *   x = 11, y = 3: (11 + 2) / 3 = 13/3 = 4.33 → 4 (rounded up from 3.67)
     *
     * NOTE: Not used in this implementation, but useful to understand
     */
    function _divUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x + y - 1) / y;
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. SHARE-BASED ACCOUNTING HANDLES YIELD AUTOMATICALLY
 *    ✅ Shares represent proportional ownership
 *    ✅ Exchange rate changes as vault earns yield
 *    ✅ Users' shares become more valuable over time
 *    ✅ Real-world: Like mutual fund shares
 *
 * 2. SHARE CALCULATION FORMULAS
 *    ✅ Deposit: shares = (assets * totalShares) / totalAssets
 *    ✅ Withdraw: assets = (shares * totalAssets) / totalShares
 *    ✅ Exchange rate = totalAssets / totalShares
 *    ✅ First deposit: shares = assets (1:1 ratio)
 *
 * 3. ROUNDING ALWAYS FAVORS VAULT
 *    ✅ Deposit: Round DOWN shares (user gets fewer)
 *    ✅ Withdraw: Round UP shares burned (user burns more)
 *    ✅ Prevents attackers from exploiting rounding
 *    ✅ Small "fees" accumulate in vault
 *
 * 4. SLIPPAGE PROTECTION PREVENTS FRONT-RUNNING
 *    ✅ Users specify minShares or maxShares
 *    ✅ Transaction reverts if slippage too high
 *    ✅ Protects against MEV bots
 *    ✅ Essential for production vaults
 *
 * 5. PREVIEW FUNCTIONS MUST MATCH ACTUAL BEHAVIOR
 *    ✅ previewDeposit() must equal actual deposit shares
 *    ✅ previewWithdraw() must equal actual withdraw shares
 *    ✅ Frontends rely on preview functions
 *    ✅ Must account for rounding correctly
 *
 * 6. ATTACK MITIGATIONS ARE CRITICAL
 *    ✅ Inflation attack: Require shares > 0, or mint dead shares
 *    ✅ Donation attack: Track assets internally, not balanceOf()
 *    ✅ Front-running: Slippage protection
 *    ✅ All mitigations implemented in this contract
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMMON MISTAKES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ❌ Rounding in favor of users (allows exploitation!)
 * ❌ Using balanceOf() instead of tracking internally (donation attack!)
 * ❌ Not handling first depositor edge case (inflation attack!)
 * ❌ Preview functions don't match actual behavior
 * ❌ Not implementing slippage protection
 * ❌ Not checking zero addresses and amounts
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          NEXT STEPS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * • Study ERC-4626 Tokenized Vault Standard (Project 11)
 * • Implement actual yield strategies
 * • Explore multi-asset vaults
 * • Continue to next projects for advanced patterns
 */
