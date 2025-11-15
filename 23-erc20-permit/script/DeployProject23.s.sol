// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/solution/Project23Solution.sol";

/**
 * @title DeployProject23
 * @notice Deployment script for ERC-20 Permit token
 * @dev Deploys PermitToken with full EIP-2612 functionality
 */
contract DeployProject23 is Script {
    function run() external {
        // Get deployer private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        console.log("Deploying Project23 - ERC-20 Permit Token...");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("Chain ID:", block.chainid);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy main token with OpenZeppelin's ERC20Permit
        Project23Solution token = new Project23Solution();

        console.log("\nDeployment successful!");
        console.log("PermitToken address:", address(token));
        console.log("Token name:", token.name());
        console.log("Token symbol:", token.symbol());
        console.log("Initial supply:", token.totalSupply());
        console.log("Domain separator:", vm.toString(token.DOMAIN_SEPARATOR()));

        // Deploy custom implementation for comparison
        Project23CustomImplementation customToken = new Project23CustomImplementation();

        console.log("\nCustom implementation address:", address(customToken));
        console.log("Custom domain separator:", vm.toString(customToken.DOMAIN_SEPARATOR()));

        // Deploy helper contract
        PermitHelper helper = new PermitHelper();

        console.log("\nPermitHelper address:", address(helper));

        vm.stopBroadcast();

        // Log permit functionality details
        console.log("\n=== PERMIT FUNCTIONALITY ===");
        console.log("EIP-2612 compliant: YES");
        console.log("Nonce-based replay protection: YES");
        console.log("Deadline enforcement: YES");
        console.log("EIP-712 domain separation: YES");

        // Example permit signature creation (for documentation)
        console.log("\n=== HOW TO USE PERMIT ===");
        console.log("1. Off-chain: User signs permit using EIP-712");
        console.log("   Domain: { name, version, chainId, verifyingContract }");
        console.log("   Types: { owner, spender, value, nonce, deadline }");
        console.log("2. On-chain: Call token.permit(owner, spender, value, deadline, v, r, s)");
        console.log("3. Approval is set without user paying gas!");

        // Save deployment info
        _saveDeployment(address(token), address(customToken), address(helper));
    }

    function _saveDeployment(address token, address customToken, address helper) internal {
        string memory deploymentInfo = string(
            abi.encodePacked(
                "{\n",
                '  "token": "',
                vm.toString(token),
                '",\n',
                '  "customToken": "',
                vm.toString(customToken),
                '",\n',
                '  "helper": "',
                vm.toString(helper),
                '",\n',
                '  "chainId": ',
                vm.toString(block.chainid),
                ",\n",
                '  "timestamp": ',
                vm.toString(block.timestamp),
                "\n}"
            )
        );

        vm.writeFile("deployment-info.json", deploymentInfo);
        console.log("\nDeployment info saved to deployment-info.json");
    }
}

/**
 * @title DeployAndTest
 * @notice Deploy and run basic tests
 */
contract DeployAndTest is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy token
        Project23Solution token = new Project23Solution();

        console.log("Token deployed at:", address(token));
        console.log("Deployer balance:", token.balanceOf(deployer));

        // Create test account
        uint256 userPrivateKey = 0xA11CE;
        address user = vm.addr(userPrivateKey);

        // Transfer some tokens to user
        token.transfer(user, 1000e18);
        console.log("User balance:", token.balanceOf(user));

        vm.stopBroadcast();

        // Create permit signature (off-chain simulation)
        console.log("\n=== CREATING PERMIT SIGNATURE ===");

        address spender = makeAddr("spender");
        uint256 value = 100e18;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(user);

        console.log("Owner:", user);
        console.log("Spender:", spender);
        console.log("Value:", value);
        console.log("Nonce:", nonce);
        console.log("Deadline:", deadline);

        // Create struct hash
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                user,
                spender,
                value,
                nonce,
                deadline
            )
        );

        // Create digest
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash));

        console.log("Struct hash:", vm.toString(structHash));
        console.log("Digest:", vm.toString(digest));

        // Sign
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);

        console.log("Signature v:", v);
        console.log("Signature r:", vm.toString(r));
        console.log("Signature s:", vm.toString(s));

        // Execute permit
        vm.startBroadcast(deployerPrivateKey);

        console.log("\n=== EXECUTING PERMIT ===");
        token.permit(user, spender, value, deadline, v, r, s);

        console.log("Permit executed successfully!");
        console.log("Allowance:", token.allowance(user, spender));
        console.log("New nonce:", token.nonces(user));

        vm.stopBroadcast();

        console.log("\n=== SUCCESS ===");
        console.log("Gasless approval completed!");
    }
}

/**
 * @title InteractWithPermit
 * @notice Script to interact with deployed permit token
 */
contract InteractWithPermit is Script {
    function run() external {
        // Load deployed token address
        address tokenAddress = vm.envAddress("TOKEN_ADDRESS");
        Project23Solution token = Project23Solution(tokenAddress);

        uint256 userPrivateKey = vm.envUint("PRIVATE_KEY");
        address user = vm.addr(userPrivateKey);

        console.log("Interacting with token at:", tokenAddress);
        console.log("User:", user);
        console.log("User balance:", token.balanceOf(user));
        console.log("User nonce:", token.nonces(user));

        // Example: Create permit for a DEX
        address dexRouter = vm.envAddress("DEX_ROUTER");
        uint256 amount = 1000e18;
        uint256 deadline = block.timestamp + 1 hours;

        console.log("\n=== CREATING PERMIT FOR DEX ===");
        console.log("DEX Router:", dexRouter);
        console.log("Amount:", amount);
        console.log("Deadline:", deadline);

        // Get current nonce
        uint256 nonce = token.nonces(user);

        // Create permit signature
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                user,
                dexRouter,
                amount,
                nonce,
                deadline
            )
        );

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);

        console.log("\nSignature created!");
        console.log("v:", v);
        console.log("r:", vm.toString(r));
        console.log("s:", vm.toString(s));
        console.log("\nNow the DEX can call permit and swap in a single transaction!");
    }
}
