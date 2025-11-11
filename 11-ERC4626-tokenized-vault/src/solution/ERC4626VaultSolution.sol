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
 * 
 * CONCEPTUAL OVERVIEW:
 * ====================
 * An ERC-4626 vault is a wrapper around an ERC-20 asset that:
 * 1. Accepts deposits of the underlying asset (e.g., USDC, DAI, WETH)
 * 2. Mints share tokens representing proportional ownership
 * 3. Can deploy assets to yield strategies
 * 4. Allows withdrawals by burning shares
 * 
 * SHARE MATH:
 * ===========
 * shares = (assets * totalSupply) / totalAssets
 * assets = (shares * totalAssets) / totalSupply
 * 
 * ROUNDING:
 * =========
 * Always favor the vault (never favor the user):
 * - deposit/mint: round DOWN shares given to user
 * - withdraw/redeem: round UP shares taken from user
 * 
 * SECURITY:
 * =========
 * - Inflation attack: First depositor can manipulate share price
 * - Donation attack: Direct transfers can break accounting
 * - Reentrancy: Use nonReentrant on all state-changing functions
 */
contract ERC4626VaultSolution {
    // ════════════════════════════════════════════════════════════════
    // STATE VARIABLES
    // ════════════════════════════════════════════════════════════════
    
    IERC20 public immutable asset;
    
    // ERC-20 share token metadata
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    
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
     */
    function deposit(uint256 assets, address receiver) public nonReentrant returns (uint256 shares) {
        require(receiver != address(0), "Invalid receiver");
        require(assets > 0, "Zero assets");
        
        // Calculate shares to mint (round down to favor vault)
        shares = convertToShares(assets);
        require(shares > 0, "Zero shares");
        
        // Transfer assets from sender
        require(asset.transferFrom(msg.sender, address(this), assets), "Transfer failed");
        
        // Update accounting
        _totalAssets += assets;
        
        // Mint shares to receiver
        _mint(receiver, shares);
        
        emit Deposit(msg.sender, receiver, assets, shares);
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
    
    function _divUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x + y - 1) / y;
    }
}
