// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/VaultPrecision.sol";
import "../src/solution/VaultPrecisionSolution.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title DeployVaultPrecision
 * @notice Deployment script for ERC-4626 Precision & Rounding Vault
 *
 * USAGE:
 * Deploy skeleton:
 *   forge script script/DeployVaultPrecision.s.sol:DeployVaultPrecision --rpc-url $RPC_URL --broadcast
 *
 * Deploy solution:
 *   forge script script/DeployVaultPrecision.s.sol:DeployVaultPrecisionSolution --rpc-url $RPC_URL --broadcast
 *
 * Deploy with verification:
 *   forge script script/DeployVaultPrecision.s.sol:DeployVaultPrecision --rpc-url $RPC_URL --broadcast --verify
 */
contract DeployVaultPrecision is Script {
    // Default asset address (USDC on mainnet)
    // Update this for your deployment network
    address public constant DEFAULT_ASSET = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    function run() external {
        // Get deployment parameters
        address assetAddress = vm.envOr("ASSET_ADDRESS", DEFAULT_ASSET);
        string memory vaultName = vm.envOr("VAULT_NAME", string("Precision Vault"));
        string memory vaultSymbol = vm.envOr("VAULT_SYMBOL", string("pVAULT"));

        console.log("=== Deploying VaultPrecision Vault ===");
        console.log("Asset:", assetAddress);
        console.log("Name:", vaultName);
        console.log("Symbol:", vaultSymbol);
        console.log("Deployer:", msg.sender);

        vm.startBroadcast();

        // Deploy the vault
        VaultPrecision vault = new VaultPrecision(
            IERC20(assetAddress),
            vaultName,
            vaultSymbol
        );

        vm.stopBroadcast();

        console.log("=== Deployment Successful ===");
        console.log("Vault deployed at:", address(vault));
        console.log("");
        console.log("Verify with:");
        console.log(
            "forge verify-contract",
            address(vault),
            "src/VaultPrecision.sol:VaultPrecision",
            "--constructor-args $(cast abi-encode 'constructor(address,string,string)'",
            assetAddress,
            vaultName,
            vaultSymbol,
            ")"
        );
    }
}

/**
 * @title DeployVaultPrecisionSolution
 * @notice Deployment script for the complete solution vault
 */
contract DeployVaultPrecisionSolution is Script {
    address public constant DEFAULT_ASSET = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    function run() external {
        address assetAddress = vm.envOr("ASSET_ADDRESS", DEFAULT_ASSET);
        string memory vaultName = vm.envOr("VAULT_NAME", string("Precision Vault Solution"));
        string memory vaultSymbol = vm.envOr("VAULT_SYMBOL", string("pVAULT-SOL"));

        console.log("=== Deploying VaultPrecisionSolution Vault ===");
        console.log("Asset:", assetAddress);
        console.log("Name:", vaultName);
        console.log("Symbol:", vaultSymbol);
        console.log("Deployer:", msg.sender);

        vm.startBroadcast();

        VaultPrecisionSolution vault = new VaultPrecisionSolution(
            IERC20(assetAddress),
            vaultName,
            vaultSymbol
        );

        vm.stopBroadcast();

        console.log("=== Deployment Successful ===");
        console.log("Vault deployed at:", address(vault));
        console.log("");
        console.log("Verify with:");
        console.log(
            "forge verify-contract",
            address(vault),
            "src/solution/VaultPrecisionSolution.sol:VaultPrecisionSolution",
            "--constructor-args $(cast abi-encode 'constructor(address,string,string)'",
            assetAddress,
            vaultName,
            vaultSymbol,
            ")"
        );
    }
}

/**
 * @title DeployLocalTestVault
 * @notice Deploys a vault with a mock token for local testing
 */
contract DeployLocalTestVault is Script {
    function run() external {
        console.log("=== Deploying Local Test Environment ===");

        vm.startBroadcast();

        // Deploy mock ERC20
        MockERC20 asset = new MockERC20();
        console.log("Mock asset deployed at:", address(asset));

        // Deploy vault
        VaultPrecisionSolution vault = new VaultPrecisionSolution(
            IERC20(address(asset)),
            "Test Precision Vault",
            "tPVAULT"
        );
        console.log("Vault deployed at:", address(vault));

        // Mint some tokens to deployer
        asset.mint(msg.sender, 1_000_000 ether);
        console.log("Minted 1,000,000 tokens to deployer");

        vm.stopBroadcast();

        console.log("=== Deployment Complete ===");
        console.log("");
        console.log("Next steps:");
        console.log("1. Approve vault: cast send", address(asset), "'approve(address,uint256)'", address(vault), "$(cast max-uint256)");
        console.log("2. Deposit: cast send", address(vault), "'deposit(uint256,address)' 1000000000000000000", msg.sender);
    }
}

/**
 * @title MockERC20
 * @notice Simple ERC20 for testing
 */
contract MockERC20 {
    string public name = "Mock Token";
    string public symbol = "MOCK";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function mint(address to, uint256 amount) external {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= amount;
        }
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
}
