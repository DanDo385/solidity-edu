// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/solution/Project44Solution.sol";

/**
 * @title Deploy Project 44
 * @notice Deployment script for inflation attack demonstration
 */
contract DeployProject44 is Script {
    // Deployment addresses will be logged
    VulnerableVault public vulnerableVault;
    VaultWithVirtualShares public virtualSharesVault;
    VaultWithMinDeposit public minDepositVault;
    VaultWithDeadShares public deadSharesVault;
    InflationAttacker public attackerContract;
    MockERC20 public mockToken;

    function run() external {
        // Get deployer private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== Project 44: Inflation Attack Demo Deployment ===");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy mock token for testing
        console.log("Deploying Mock ERC20 token...");
        mockToken = new MockERC20();
        console.log("Mock Token deployed at:", address(mockToken));
        console.log("");

        // Deploy vulnerable vault
        console.log("Deploying Vulnerable Vault...");
        vulnerableVault = new VulnerableVault(mockToken);
        console.log("Vulnerable Vault deployed at:", address(vulnerableVault));
        console.log("  WARNING: This vault is INTENTIONALLY vulnerable!");
        console.log("  DO NOT use in production!");
        console.log("");

        // Deploy vault with virtual shares (offset = 3)
        console.log("Deploying Vault with Virtual Shares (offset=3)...");
        virtualSharesVault = new VaultWithVirtualShares(mockToken, 3);
        console.log("Virtual Shares Vault deployed at:", address(virtualSharesVault));
        console.log("  Protection: 1000 virtual shares");
        console.log("");

        // Deploy vault with minimum deposit (1000 tokens)
        console.log("Deploying Vault with Minimum Deposit...");
        uint256 minDeposit = 1000 ether; // Adjust based on token decimals
        minDepositVault = new VaultWithMinDeposit(mockToken, minDeposit);
        console.log("Min Deposit Vault deployed at:", address(minDepositVault));
        console.log("  Minimum first deposit:", minDeposit / 1 ether, "tokens");
        console.log("");

        // Deploy vault with dead shares
        console.log("Deploying Vault with Dead Shares...");
        deadSharesVault = new VaultWithDeadShares(mockToken);
        console.log("Dead Shares Vault deployed at:", address(deadSharesVault));
        console.log("  Dead shares amount:", deadSharesVault.DEAD_SHARES());
        console.log("  Dead address:", deadSharesVault.DEAD_ADDRESS());
        console.log("");

        // Deploy attacker contract
        console.log("Deploying Inflation Attacker contract...");
        attackerContract = new InflationAttacker(address(vulnerableVault));
        console.log("Inflation Attacker deployed at:", address(attackerContract));
        console.log("  Target vault:", address(vulnerableVault));
        console.log("");

        vm.stopBroadcast();

        // Log deployment summary
        console.log("=== Deployment Summary ===");
        console.log("");
        console.log("Mock Token:              ", address(mockToken));
        console.log("Vulnerable Vault:        ", address(vulnerableVault));
        console.log("Virtual Shares Vault:    ", address(virtualSharesVault));
        console.log("Min Deposit Vault:       ", address(minDepositVault));
        console.log("Dead Shares Vault:       ", address(deadSharesVault));
        console.log("Inflation Attacker:      ", address(attackerContract));
        console.log("");

        // Save deployment info
        _saveDeployment();
    }

    /**
     * @notice Save deployment addresses to file
     */
    function _saveDeployment() internal {
        string memory json = "deployment";

        vm.serializeAddress(json, "mockToken", address(mockToken));
        vm.serializeAddress(json, "vulnerableVault", address(vulnerableVault));
        vm.serializeAddress(json, "virtualSharesVault", address(virtualSharesVault));
        vm.serializeAddress(json, "minDepositVault", address(minDepositVault));
        vm.serializeAddress(json, "deadSharesVault", address(deadSharesVault));
        string memory finalJson = vm.serializeAddress(
            json,
            "attackerContract",
            address(attackerContract)
        );

        string memory filename = string.concat(
            "deployments/project44-",
            vm.toString(block.chainid),
            ".json"
        );

        vm.writeJson(finalJson, filename);
        console.log("Deployment info saved to:", filename);
    }

    /**
     * @notice Deploy and setup for testing
     * @dev This includes minting tokens and setting up scenarios
     */
    function runWithSetup() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== Project 44: Full Setup Deployment ===");
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy all contracts
        mockToken = new MockERC20();
        vulnerableVault = new VulnerableVault(mockToken);
        virtualSharesVault = new VaultWithVirtualShares(mockToken, 3);
        minDepositVault = new VaultWithMinDeposit(mockToken, 1000 ether);
        deadSharesVault = new VaultWithDeadShares(mockToken);
        attackerContract = new InflationAttacker(address(vulnerableVault));

        // Mint tokens for testing
        console.log("Minting test tokens...");
        mockToken.mint(deployer, 10000 ether);
        mockToken.mint(address(attackerContract), 2000 ether);

        console.log("  Deployer balance:", mockToken.balanceOf(deployer) / 1 ether, "tokens");
        console.log("  Attacker contract balance:", mockToken.balanceOf(address(attackerContract)) / 1 ether, "tokens");
        console.log("");

        vm.stopBroadcast();

        console.log("Setup complete! Ready for testing.");
        console.log("");

        _saveDeployment();
    }
}

/**
 * @title MockERC20
 * @notice Simple ERC20 token for testing
 */
contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Token", "MOCK") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }
}

/**
 * @dev Deployment Instructions:
 *
 * LOCAL TESTING (Anvil):
 * 1. Start local node:
 *    anvil
 *
 * 2. Deploy:
 *    forge script script/DeployProject44.s.sol:DeployProject44 \
 *      --rpc-url http://localhost:8545 \
 *      --private-key <anvil-private-key> \
 *      --broadcast
 *
 * 3. Deploy with setup:
 *    forge script script/DeployProject44.s.sol:DeployProject44 \
 *      --sig "runWithSetup()" \
 *      --rpc-url http://localhost:8545 \
 *      --private-key <anvil-private-key> \
 *      --broadcast
 *
 * TESTNET DEPLOYMENT:
 * 1. Set environment variables:
 *    export PRIVATE_KEY=your_private_key
 *    export RPC_URL=your_rpc_url
 *
 * 2. Deploy:
 *    forge script script/DeployProject44.s.sol:DeployProject44 \
 *      --rpc-url $RPC_URL \
 *      --private-key $PRIVATE_KEY \
 *      --broadcast \
 *      --verify
 *
 * VERIFICATION:
 * After deployment, verify contracts on block explorer:
 *    forge verify-contract <address> <contract> \
 *      --chain-id <chain-id> \
 *      --etherscan-api-key <api-key>
 *
 * TESTING ATTACK:
 * After deployment, you can test the attack:
 *
 * 1. Get mock tokens:
 *    cast send <mockToken> "mint(address,uint256)" <your-address> 10000000000000000000000
 *
 * 2. Approve vulnerable vault:
 *    cast send <mockToken> "approve(address,uint256)" <vulnerableVault> 115792089237316195423570985008687907853269984665640564039457584007913129639935
 *
 * 3. Execute attack via attacker contract:
 *    cast send <attackerContract> "executeAttack(uint256)" 1000000000000000000000 --value 0
 *
 * 4. Check balances and shares:
 *    cast call <vulnerableVault> "balanceOf(address)" <attackerContract>
 *    cast call <vulnerableVault> "totalSupply()"
 *    cast call <vulnerableVault> "totalAssets()"
 */
