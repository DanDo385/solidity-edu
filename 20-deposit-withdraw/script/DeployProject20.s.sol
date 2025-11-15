// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/solution/Project20Solution.sol";

/**
 * @title DeployProject20
 * @notice Deployment script for Project20 Deposit/Withdraw Vault
 *
 * USAGE:
 * ======
 *
 * Local deployment (Anvil):
 *   1. Start local node: anvil
 *   2. Deploy: forge script script/DeployProject20.s.sol --broadcast --rpc-url http://localhost:8545
 *
 * Testnet deployment:
 *   forge script script/DeployProject20.s.sol --broadcast --rpc-url $RPC_URL --verify
 *
 * ENVIRONMENT VARIABLES:
 * ======================
 *   PRIVATE_KEY - Deployer private key (defaults to Anvil account #0)
 *   TOKEN_ADDRESS - Address of ERC20 token to use (required for testnet)
 *
 * EXAMPLES:
 * =========
 *
 * Deploy with specific token:
 *   TOKEN_ADDRESS=0x... forge script script/DeployProject20.s.sol --broadcast
 *
 * Deploy and verify:
 *   forge script script/DeployProject20.s.sol --broadcast --verify --etherscan-api-key $API_KEY
 */
contract DeployProject20 is Script {
    function run() external {
        // Get deployer private key (defaults to Anvil account #0)
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );

        // Get token address from environment or use placeholder
        address tokenAddress = vm.envOr("TOKEN_ADDRESS", address(0));

        vm.startBroadcast(deployerPrivateKey);

        if (tokenAddress != address(0)) {
            // Deploy vault with specified token
            Project20Solution vault = new Project20Solution(tokenAddress);

            console.log("===============================================");
            console.log("Project20 Vault Deployed Successfully!");
            console.log("===============================================");
            console.log("Vault Address:", address(vault));
            console.log("Token Address:", tokenAddress);
            console.log("Total Assets:", vault.totalAssets());
            console.log("Total Shares:", vault.totalShares());
            console.log("===============================================");
        } else {
            // For demo/testing: Deploy a mock token first, then vault
            console.log("===============================================");
            console.log("No TOKEN_ADDRESS provided.");
            console.log("Deploying Mock Token for demonstration...");
            console.log("===============================================");

            MockERC20 mockToken = new MockERC20();
            console.log("Mock Token deployed at:", address(mockToken));

            Project20Solution vault = new Project20Solution(address(mockToken));
            console.log("Vault deployed at:", address(vault));

            // Mint some tokens to deployer for testing
            address deployer = vm.addr(deployerPrivateKey);
            mockToken.mint(deployer, 10000e18);
            console.log("Minted 10,000 tokens to deployer:", deployer);

            console.log("===============================================");
            console.log("Deployment Summary:");
            console.log("===============================================");
            console.log("Mock Token:", address(mockToken));
            console.log("Vault:", address(vault));
            console.log("Deployer:", deployer);
            console.log("Deployer Token Balance:", mockToken.balanceOf(deployer));
            console.log("===============================================");
            console.log("");
            console.log("Next Steps:");
            console.log("1. Approve vault to spend tokens:");
            console.log("   cast send", address(mockToken), '"approve(address,uint256)"', address(vault), "1000000000000000000000");
            console.log("");
            console.log("2. Deposit tokens:");
            console.log("   cast send", address(vault), '"deposit(uint256)"', "1000000000000000000000");
            console.log("");
            console.log("3. Check your shares:");
            console.log("   cast call", address(vault), '"shares(address)(uint256)"', deployer);
            console.log("===============================================");
        }

        vm.stopBroadcast();
    }
}

/**
 * @notice Mock ERC20 token for testing/demonstration
 * @dev Only deployed if no TOKEN_ADDRESS is provided
 */
contract MockERC20 {
    string public name = "Mock Token";
    string public symbol = "MOCK";
    uint8 public decimals = 18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");

        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        emit Transfer(from, to, amount);
        return true;
    }
}
