// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title ERC4626VaultSolution
 * @notice Complete implementation of ERC-4626 Tokenized Vault Standard
 * @dev This contract implements the ERC-4626 standard for tokenized vaults.
 *      It wraps an ERC-20 asset and issues share tokens representing ownership.
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        CONCEPTUAL OVERVIEW
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ERC-4626 TOKENIZED VAULT: DeFi Yield Standard
 * ═════════════════════════════════════════════
 *
 * An ERC-4626 vault is a wrapper around an ERC-20 asset that:
 * 1. Accepts deposits of underlying asset (USDC, DAI, WETH, etc.)
 * 2. Mints share tokens representing proportional ownership
 * 3. Can deploy assets to yield strategies (Aave, Compound, Curve)
 * 4. Allows withdrawals by burning shares
 *
 * REAL-WORLD ANALOGY:
 * Like a mutual fund:
 * - **Assets** = Underlying investments (USDC, DAI)
 * - **Shares** = Fund shares (yUSDC, vDAI)
 * - **Deposit** = Buying fund shares
 * - **Withdraw** = Selling fund shares
 * - **Yield** = Returns from investments
 *
 * CONNECTION TO PROJECT 08: ERC20 Tokens!
 * ═════════════════════════════════════════
 *
 * Vault shares are ERC20 tokens! Users can transfer, approve, and trade them.
 * This makes vaults composable with other DeFi protocols.
 *
 * SHARE MATH: The Core Formula
 * ═════════════════════════════
 *
 * shares = (assets * totalSupply) / totalAssets
 * assets = (shares * totalAssets) / totalSupply
 *
 * Example:
 * - Vault has 1000 USDC (totalAssets)
 * - Vault has 1000 shares (totalSupply)
 * - User deposits 100 USDC
 * - Shares minted = (100 * 1000) / 1000 = 100 shares
 * - Later: Vault earns yield, now has 1100 USDC
 * - User's 100 shares now worth = (100 * 1100) / 1000 = 110 USDC!
 *
 * ROUNDING: Always Favor the Vault!
 * ══════════════════════════════════
 *
 * ⚠️  CRITICAL: Always round in favor of the vault (never favor users):
 * - deposit/mint: Round DOWN shares given to user
 * - withdraw/redeem: Round UP shares taken from user
 *
 * Why? Prevents attackers from exploiting rounding to drain vault!
 *
 * SECURITY CONSIDERATIONS:
 * ═══════════════════════
 *
 * 1. **Inflation Attack**: First depositor can manipulate share price
 * 2. **Donation Attack**: Direct transfers can break accounting
 * 3. **Reentrancy**: Use nonReentrant on all state-changing functions
 * 4. **Rounding**: Always favor vault to prevent exploitation
 */
contract ERC4626VaultSolution {
    // ════════════════════════════════════════════════════════════════
    // STATE VARIABLES
    // ════════════════════════════════════════════════════════════════

    // Constants
    uint8 public constant decimals = 18;
    
    // Immutables
    IERC20 public immutable asset;
    
    // ERC-20 share token metadata
    string public name;
    string public symbol;
    
    // ERC-20 share token state
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    // Track actual deposited assets (prevent donation attack)
    uint256 private _totalAssets;
    
    // Simple reentrancy guard
    uint256 private _locked = 1;
    
    // ════════════════════════════════════════════════════════════════
    // EVENTS
    // ════════════════════════════════════════════════════════════════
    
    // ERC-20 events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    // ERC-4626 events
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);
    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );
    
    // ════════════════════════════════════════════════════════════════
    // MODIFIERS
    // ════════════════════════════════════════════════════════════════
    
    modifier nonReentrant() {
        require(_locked == 1, "Reentrant call");
        _locked = 2;
        _;
        _locked = 1;
    }
    
    // ════════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ════════════════════════════════════════════════════════════════
    
    constructor(
        address _asset,
        string memory _name,
        string memory _symbol
    ) {
        asset = IERC20(_asset);
        name = _name;
        symbol = _symbol;
    }
    
    // ════════════════════════════════════════════════════════════════
    // ERC-20 SHARE TOKEN FUNCTIONS
    // ════════════════════════════════════════════════════════════════
    
    function transfer(address to, uint256 amount) public returns (bool) {
        require(to != address(0), "Invalid recipient");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) public returns (bool) {
        require(spender != address(0), "Invalid spender");
        
        allowance[msg.sender][spender] = amount;
        
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(from != address(0), "Invalid sender");
        require(to != address(0), "Invalid recipient");
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
        
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        
        emit Transfer(from, to, amount);
        return true;
    }
    
    // ════════════════════════════════════════════════════════════════
    // ERC-4626 CORE FUNCTIONS
    // ════════════════════════════════════════════════════════════════
    
    /**
     * @notice Deposit assets and receive shares
     * @param assets Amount of underlying asset to deposit
     * @param receiver Address to receive shares
     * @return shares Amount of shares minted
     *
     * @dev DEPOSIT OPERATION: Converting Assets to Shares
     * ═══════════════════════════════════════════════════
     *
     *      This function deposits underlying assets and mints share tokens.
     *      Shares represent proportional ownership of vault assets.
     *
     *      EXECUTION FLOW:
     *      ┌─────────────────────────────────────────┐
     *      │ 1. VALIDATION: Check inputs               │
     *      │    - Receiver not zero                   │
     *      │    - Assets > 0                          │
     *      │    ↓                                      │
     *      │ 2. CALCULATE SHARES: Round DOWN           │
     *      │    - shares = (assets * totalSupply) / totalAssets│
     *      │    - Round DOWN to favor vault           │
     *      │    ↓                                      │
     *      │ 3. TRANSFER ASSETS: From sender          │
     *      │    - asset.transferFrom()                │
     *      │    ↓                                      │
     *      │ 4. UPDATE ACCOUNTING: Track assets       │
     *      │    - _totalAssets += assets              │
     *      │    ↓                                      │
     *      │ 5. MINT SHARES: To receiver              │
     *      │    - _mint(receiver, shares)             │
     *      │    ↓                                      │
     *      │ 6. EMIT EVENT: Deposit event             │
     *      └─────────────────────────────────────────┘
     *
     *      CONNECTION TO PROJECT 08: ERC20 Transfer!
     *      ══════════════════════════════════════════
     *
     *      We use asset.transferFrom() to get assets from user.
     *      User must approve vault first (ERC20 approval pattern)!
     *
     *      CONNECTION TO PROJECT 07: Reentrancy Protection!
     *      ════════════════════════════════════════════════
     *
     *      Uses nonReentrant modifier to prevent reentrancy attacks.
     *      Critical for vault security!
     *
     *      SHARE CALCULATION:
     *      ══════════════════
     *
     *      Formula: shares = (assets * totalSupply) / totalAssets
     *
     *      Example:
     *      - Vault has 1000 USDC (totalAssets)
     *      - Vault has 1000 shares (totalSupply)
     *      - User deposits 100 USDC
     *      - Shares = (100 * 1000) / 1000 = 100 shares
     *
     *      Edge case (first deposit):
     *      - totalSupply == 0
     *      - Shares = assets (1:1 ratio)
     *
     *      ROUNDING DIRECTION: Round DOWN
     *      ═══════════════════════════════
     *
     *      We round DOWN shares to favor the vault:
     *      - If calculation gives 99.9 shares, user gets 99 shares
     *      - Vault keeps the 0.9 share value
     *      - Prevents attackers from exploiting rounding
     *
     *      GAS COST BREAKDOWN:
     *      ┌─────────────────────┬──────────────┬─────────────────┐
     *      │ Operation           │ Gas (warm)   │ Gas (cold)      │
     *      ├─────────────────────┼──────────────┼─────────────────┤
     *      │ require() checks    │ ~6 gas       │ ~6 gas          │
     *      │ convertToShares()   │ ~200 gas     │ ~200 gas        │
     *      │ transferFrom()      │ ~11,700 gas  │ ~45,700 gas     │
     *      │ SSTORE _totalAssets │ ~5,000 gas   │ ~20,000 gas     │
     *      │ _mint() shares      │ ~5,000 gas   │ ~20,000 gas     │
     *      │ Event emission      │ ~1,500 gas   │ ~1,500 gas      │
     *      ├─────────────────────┼──────────────┼─────────────────┤
     *      │ TOTAL (warm)        │ ~23,406 gas  │                 │
     *      │ TOTAL (cold)        │              │ ~87,406 gas      │
     *      └─────────────────────┴──────────────┴─────────────────┘
     *
     *      REAL-WORLD ANALOGY:
     *      ═══════════════════
     *
     *      Like buying mutual fund shares:
     *      - **Assets** = Money you invest (USDC)
     *      - **Shares** = Fund shares you receive
     *      - **Exchange rate** = Current NAV (Net Asset Value)
     *      - **Rounding** = Bank rounds in their favor (standard practice)
     *
     *      SECURITY: Donation Attack Prevention
     *      ════════════════════════════════════
     *
     *      We track _totalAssets internally instead of using asset.balanceOf().
     *      This prevents donation attacks where someone sends assets directly!
     */
    function deposit(uint256 assets, address receiver) public nonReentrant returns (uint256 shares) {
        require(receiver != address(0), "Invalid receiver");
        require(assets > 0, "Zero assets");
        
        // 💰 CALCULATE SHARES: Round DOWN to favor vault
        // CONNECTION TO PROJECT 01: Division and rounding!
        // Formula: shares = (assets * totalSupply) / totalAssets
        // Rounding DOWN ensures vault benefits from any rounding remainder
        shares = convertToShares(assets); // ~200 gas
        require(shares > 0, "Zero shares");
        
        // 💾 TRANSFER ASSETS: From sender to vault
        // CONNECTION TO PROJECT 08: ERC20 transferFrom!
        // User must approve vault first (ERC20 approval pattern)
        require(asset.transferFrom(msg.sender, address(this), assets), "Transfer failed"); // ~11,700 gas
        
        // 💾 UPDATE ACCOUNTING: Track deposited assets
        // CONNECTION TO PROJECT 01: Storage write!
        // We track internally to prevent donation attacks
        _totalAssets += assets; // SSTORE: ~5,000 gas
        
        // 💾 MINT SHARES: To receiver
        // CONNECTION TO PROJECT 08: ERC20 minting!
        // Shares are ERC20 tokens representing vault ownership
        _mint(receiver, shares); // SSTORE: ~5,000 gas
        
        // 📢 EVENT EMISSION: Log the deposit
        // CONNECTION TO PROJECT 03: Event emission!
        emit Deposit(msg.sender, receiver, assets, shares); // ~1,500 gas
    }
    
    /**
     * @notice Mint exact amount of shares
     * @param shares Amount of shares to mint
     * @param receiver Address to receive shares
     * @return assets Amount of assets deposited
     */
    function mint(uint256 shares, address receiver) public nonReentrant returns (uint256 assets) {
        require(receiver != address(0), "Invalid receiver");
        require(shares > 0, "Zero shares");
        
        // Calculate assets needed (round up to favor vault)
        assets = previewMint(shares);
        
        // Transfer assets from sender
        require(asset.transferFrom(msg.sender, address(this), assets), "Transfer failed");
        
        // Update accounting
        _totalAssets += assets;
        
        // Mint shares to receiver
        _mint(receiver, shares);
        
        emit Deposit(msg.sender, receiver, assets, shares);
    }
    
    /**
     * @notice Withdraw exact assets by burning shares
     * @param assets Amount of assets to withdraw
     * @param receiver Address to receive assets
     * @param owner Address whose shares to burn
     * @return shares Amount of shares burned
     */
    function withdraw(uint256 assets, address receiver, address owner) 
        public 
        nonReentrant 
        returns (uint256 shares) 
    {
        require(receiver != address(0), "Invalid receiver");
        require(assets > 0, "Zero assets");
        
        // Calculate shares to burn (round up to favor vault)
        shares = previewWithdraw(assets);
        
        // Handle allowance if not owner
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender];
            require(allowed >= shares, "Insufficient allowance");
            if (allowed != type(uint256).max) {
                allowance[owner][msg.sender] = allowed - shares;
            }
        }
        
        // Burn shares from owner
        _burn(owner, shares);
        
        // Update accounting
        _totalAssets -= assets;
        
        // Transfer assets to receiver
        require(asset.transfer(receiver, assets), "Transfer failed");
        
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }
    
    /**
     * @notice Redeem exact shares for assets
     * @param shares Amount of shares to burn
     * @param receiver Address to receive assets
     * @param owner Address whose shares to burn
     * @return assets Amount of assets withdrawn
     */
    function redeem(uint256 shares, address receiver, address owner) 
        public 
        nonReentrant 
        returns (uint256 assets) 
    {
        require(receiver != address(0), "Invalid receiver");
        require(shares > 0, "Zero shares");
        
        // Calculate assets to withdraw (round down to favor vault)
        assets = convertToAssets(shares);
        
        // Handle allowance if not owner
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender];
            require(allowed >= shares, "Insufficient allowance");
            if (allowed != type(uint256).max) {
                allowance[owner][msg.sender] = allowed - shares;
            }
        }
        
        // Burn shares from owner
        _burn(owner, shares);
        
        // Update accounting
        _totalAssets -= assets;
        
        // Transfer assets to receiver
        require(asset.transfer(receiver, assets), "Transfer failed");
        
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }
    
    // ════════════════════════════════════════════════════════════════
    // ERC-4626 VIEW FUNCTIONS
    // ════════════════════════════════════════════════════════════════
    
    function totalAssets() public view returns (uint256) {
        return _totalAssets;
    }
    
    function convertToShares(uint256 assets) public view returns (uint256) {
        uint256 supply = totalSupply;
        return supply == 0 ? assets : (assets * supply) / totalAssets();
    }
    
    function convertToAssets(uint256 shares) public view returns (uint256) {
        uint256 supply = totalSupply;
        return supply == 0 ? shares : (shares * totalAssets()) / supply;
    }
    
    function previewDeposit(uint256 assets) public view returns (uint256) {
        return convertToShares(assets);
    }
    
    function previewMint(uint256 shares) public view returns (uint256) {
        uint256 supply = totalSupply;
        return supply == 0 ? shares : _divUp(shares * totalAssets(), supply);
    }
    
    function previewWithdraw(uint256 assets) public view returns (uint256) {
        uint256 supply = totalSupply;
        return supply == 0 ? assets : _divUp(assets * supply, totalAssets());
    }
    
    function previewRedeem(uint256 shares) public view returns (uint256) {
        return convertToAssets(shares);
    }
    
    function maxDeposit(address) public pure returns (uint256) {
        return type(uint256).max;
    }
    
    function maxMint(address) public pure returns (uint256) {
        return type(uint256).max;
    }
    
    function maxWithdraw(address owner) public view returns (uint256) {
        return convertToAssets(balanceOf[owner]);
    }
    
    function maxRedeem(address owner) public view returns (uint256) {
        return balanceOf[owner];
    }
    
    // ════════════════════════════════════════════════════════════════
    // INTERNAL HELPERS
    // ════════════════════════════════════════════════════════════════
    
    function _mint(address to, uint256 amount) internal {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }
    
    function _burn(address from, uint256 amount) internal {
        balanceOf[from] -= amount;
        totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }
    
    /**
     * @notice Round up division
     * @dev Helper for rounding UP (used in withdraw/redeem)
     *      Formula: (x + y - 1) / y
     *      Example: _divUp(10, 3) = (10 + 3 - 1) / 3 = 12 / 3 = 4
     *      Standard: 10 / 3 = 3 (rounds down)
     *      This rounds UP to favor vault
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
 * 1. ERC-4626 IS THE VAULT STANDARD
 *    ✅ Standardized interface for tokenized vaults
 *    ✅ Powers Yearn, Beefy, Rari, and other DeFi protocols
 *    ✅ Shares are ERC20 tokens (composable!)
 *    ✅ Enables yield-generating strategies
 *
 * 2. ASSET VS SHARES CONVERSION
 *    ✅ shares = (assets * totalSupply) / totalAssets
 *    ✅ assets = (shares * totalAssets) / totalSupply
 *    ✅ Exchange rate changes as vault earns yield
 *    ✅ Shares become more valuable over time!
 *
 * 3. ROUNDING ALWAYS FAVORS VAULT
 *    ✅ Deposit/mint: Round DOWN shares given to user
 *    ✅ Withdraw/redeem: Round UP shares taken from user
 *    ✅ Prevents attackers from exploiting rounding
 *    ✅ Standard practice in DeFi vaults
 *
 * 4. SECURITY PATTERNS ARE CRITICAL
 *    ✅ Reentrancy protection (nonReentrant modifier)
 *    ✅ Track assets internally (prevent donation attack)
 *    ✅ Handle first depositor (inflation attack risk)
 *    ✅ Validate all inputs (zero addresses, zero amounts)
 *
 * 5. PREVIEW FUNCTIONS MUST MATCH ACTUAL BEHAVIOR
 *    ✅ previewDeposit() must equal actual deposit shares
 *    ✅ previewWithdraw() must equal actual withdraw shares
 *    ✅ Frontends rely on preview functions
 *    ✅ Must account for rounding correctly
 *
 * 6. VAULTS ENABLE YIELD STRATEGIES
 *    ✅ Accept deposits of underlying asset
 *    ✅ Deploy to yield strategies (Aave, Compound, Curve)
 *    ✅ Auto-compound rewards
 *    ✅ Users earn yield automatically
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMMON MISTAKES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ❌ Rounding in favor of users (allows exploitation!)
 * ❌ Using asset.balanceOf() instead of tracking internally (donation attack)
 * ❌ Not protecting against reentrancy (critical vulnerability)
 * ❌ Preview functions don't match actual behavior (breaks frontends)
 * ❌ Not handling first depositor edge case (inflation attack)
 * ❌ Forgetting to check zero addresses and amounts
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          NEXT STEPS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * • Study OpenZeppelin ERC4626 implementation
 * • Implement actual yield strategies (Aave deposits, Curve LPs)
 * • Add fee mechanisms (performance fees, management fees)
 * • Explore multi-asset vaults
 * • Move to Project 12 to learn about safe ETH transfers
 */
