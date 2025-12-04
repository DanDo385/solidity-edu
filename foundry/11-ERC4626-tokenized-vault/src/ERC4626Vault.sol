// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
}

/**
 * @title ERC4626Vault
 * @notice Skeleton implementation of ERC-4626 Tokenized Vault Standard
 * @dev Complete the TODOs to implement a fully functional vault
 */
contract ERC4626Vault {
    IERC20 public asset;
    
    string public name;
    string public symbol;
    uint8 public decimals;
    
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    // TODO: Implement ERC-20 events for share token
    // TODO: Implement ERC-4626 events (Deposit, Withdraw)
    
    constructor(address _asset, string memory _name, string memory _symbol) {
        asset = IERC20(_asset);
        name = _name;
        symbol = _symbol;
        decimals = 18;
    }
    
    // ============ ERC-20 Share Token Functions ============
    
    // TODO: Implement transfer
    // TODO: Implement approve
    // TODO: Implement transferFrom
    
    // ============ ERC-4626 Core Functions ============
    
    // TODO: Implement deposit(uint256 assets, address receiver) returns (uint256 shares)
    
    // TODO: Implement mint(uint256 shares, address receiver) returns (uint256 assets)
    
    // TODO: Implement withdraw(uint256 assets, address receiver, address owner) returns (uint256 shares)
    
    // TODO: Implement redeem(uint256 shares, address receiver, address owner) returns (uint256 assets)
    
    // ============ ERC-4626 View Functions ============
    
    // TODO: Implement totalAssets() returns (uint256)
    
    // TODO: Implement convertToShares(uint256 assets) returns (uint256)
    
    // TODO: Implement convertToAssets(uint256 shares) returns (uint256)
    
    // TODO: Implement previewDeposit(uint256 assets) returns (uint256)
    
    // TODO: Implement previewMint(uint256 shares) returns (uint256)
    
    // TODO: Implement previewWithdraw(uint256 assets) returns (uint256)
    
    // TODO: Implement previewRedeem(uint256 shares) returns (uint256)
    
    // TODO: Implement maxDeposit(address) returns (uint256)
    
    // TODO: Implement maxMint(address) returns (uint256)
    
    // TODO: Implement maxWithdraw(address owner) returns (uint256)
    
    // TODO: Implement maxRedeem(address owner) returns (uint256)
}
