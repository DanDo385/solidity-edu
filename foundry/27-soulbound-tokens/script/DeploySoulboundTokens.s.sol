// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SoulboundTokens.sol";
import "../src/solution/SoulboundTokensSolution.sol";

/**
 * @title DeploySoulboundTokens
 * @notice Deployment script for Soulbound Token contracts
 * @dev Demonstrates deployment of different SBT patterns
 *
 * Usage:
 *   Deploy skeleton:
 *     forge script script/DeploySoulboundTokens.s.sol:DeploySoulboundTokens --rpc-url <RPC_URL> --broadcast
 *
 *   Deploy solution:
 *     forge script script/DeploySoulboundTokens.s.sol:DeploySoulboundTokensSolution --rpc-url <RPC_URL> --broadcast
 *
 *   Deploy all patterns:
 *     forge script script/DeploySoulboundTokens.s.sol:DeployAllPatterns --rpc-url <RPC_URL> --broadcast
 */
contract DeploySoulboundTokens is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        SoulboundToken sbt = new SoulboundToken();

        console.log("SoulboundToken deployed at:", address(sbt));
        console.log("Deployer:", msg.sender);

        vm.stopBroadcast();
    }
}

/**
 * @title DeploySoulboundTokensSolution
 * @notice Deploy the complete solution
 */
contract DeploySoulboundTokensSolution is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        SoulboundTokenSolution sbt = new SoulboundTokenSolution();

        console.log("SoulboundTokenSolution deployed at:", address(sbt));
        console.log("Deployer:", msg.sender);
        console.log("Recovery Delay:", sbt.RECOVERY_DELAY());

        // Verify EIP-5192 interface support
        bool supportsEIP5192 = sbt.supportsInterface(0xb45a3c0e);
        console.log("Supports EIP-5192:", supportsEIP5192);

        vm.stopBroadcast();
    }
}

/**
 * @title DeployAllPatterns
 * @notice Deploy all SBT pattern implementations
 */
contract DeployAllPatterns is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy main solution
        SoulboundTokenSolution mainSBT = new SoulboundTokenSolution();
        console.log("\n=== Main Soulbound Token ===");
        console.log("Address:", address(mainSBT));
        console.log("Name:", mainSBT.name());
        console.log("Symbol:", mainSBT.symbol());

        // Deploy permanent pattern
        PermanentSoulboundToken permanentSBT = new PermanentSoulboundToken();
        console.log("\n=== Permanent Soulbound Token ===");
        console.log("Address:", address(permanentSBT));
        console.log("Name:", permanentSBT.name());
        console.log("Symbol:", permanentSBT.symbol());

        // Deploy time-locked pattern
        TimeLockedSoulboundToken timeLockedSBT = new TimeLockedSoulboundToken();
        console.log("\n=== Time-Locked Soulbound Token ===");
        console.log("Address:", address(timeLockedSBT));
        console.log("Name:", timeLockedSBT.name());
        console.log("Symbol:", timeLockedSBT.symbol());
        console.log("Lock Duration:", timeLockedSBT.LOCK_DURATION());

        // Deploy dynamic pattern
        DynamicSoulboundToken dynamicSBT = new DynamicSoulboundToken();
        console.log("\n=== Dynamic Soulbound Token ===");
        console.log("Address:", address(dynamicSBT));
        console.log("Name:", dynamicSBT.name());
        console.log("Symbol:", dynamicSBT.symbol());

        console.log("\n=== Deployment Summary ===");
        console.log("Deployer:", msg.sender);
        console.log("Total Contracts Deployed: 4");

        vm.stopBroadcast();
    }
}

/**
 * @title InteractWithSBT
 * @notice Example interaction script for testing SBT functionality
 */
contract InteractWithSBT is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address sbtAddress = vm.envAddress("SBT_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        SoulboundTokenSolution sbt = SoulboundTokenSolution(sbtAddress);

        console.log("\n=== Interacting with SBT at:", sbtAddress);

        // Mint a token
        address recipient = msg.sender;
        uint256 tokenId = sbt.mint(recipient);
        console.log("\nMinted token:", tokenId);
        console.log("Owner:", sbt.ownerOf(tokenId));
        console.log("Issuer:", sbt.issuer(tokenId));
        console.log("Locked:", sbt.locked(tokenId));

        // Check current token ID
        console.log("\nNext token ID:", sbt.getCurrentTokenId());

        // Initiate recovery (example - would need different address in production)
        // address newOwner = vm.envAddress("NEW_OWNER");
        // sbt.initiateRecovery(tokenId, newOwner);
        // console.log("\nRecovery initiated to:", newOwner);

        vm.stopBroadcast();
    }
}

/**
 * @title DemoSBTUseCases
 * @notice Demonstrate different SBT use cases
 */
contract DemoSBTUseCases is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        console.log("\n=== SBT Use Case Demonstrations ===\n");

        // Use Case 1: Educational Credentials
        console.log("1. EDUCATIONAL CREDENTIALS");
        PermanentSoulboundToken universitySBT = new PermanentSoulboundToken();
        console.log("   University Degree Token:", address(universitySBT));
        console.log("   Pattern: Permanent (non-revocable)");

        // Use Case 2: Professional Certifications
        console.log("\n2. PROFESSIONAL CERTIFICATIONS");
        SoulboundTokenSolution certificationSBT = new SoulboundTokenSolution();
        console.log("   Certification Token:", address(certificationSBT));
        console.log("   Pattern: Revocable (issuer can revoke)");

        // Use Case 3: Event Attendance (POAPs)
        console.log("\n3. EVENT ATTENDANCE (POAPs)");
        PermanentSoulboundToken poapSBT = new PermanentSoulboundToken();
        console.log("   POAP Token:", address(poapSBT));
        console.log("   Pattern: Permanent (immutable proof)");

        // Use Case 4: Identity & Recovery
        console.log("\n4. IDENTITY WITH RECOVERY");
        SoulboundTokenSolution identitySBT = new SoulboundTokenSolution();
        console.log("   Identity Token:", address(identitySBT));
        console.log("   Pattern: Recoverable (wallet migration)");
        console.log("   Recovery Delay:", identitySBT.RECOVERY_DELAY(), "seconds");

        // Use Case 5: Time-Locked Membership
        console.log("\n5. TIME-LOCKED MEMBERSHIP");
        TimeLockedSoulboundToken membershipSBT = new TimeLockedSoulboundToken();
        console.log("   Membership Token:", address(membershipSBT));
        console.log("   Pattern: Time-Locked (becomes soulbound)");
        console.log("   Lock Duration:", membershipSBT.LOCK_DURATION(), "seconds");

        // Use Case 6: Dynamic Reputation
        console.log("\n6. DYNAMIC REPUTATION");
        DynamicSoulboundToken reputationSBT = new DynamicSoulboundToken();
        console.log("   Reputation Token:", address(reputationSBT));
        console.log("   Pattern: Dynamic (updatable scores)");

        console.log("\n=== Demo Complete ===");
        console.log("Total Use Cases Demonstrated: 6");

        vm.stopBroadcast();
    }
}

/**
 * @title MintBatchSBTs
 * @notice Mint multiple SBTs to different recipients
 */
contract MintBatchSBTs is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address sbtAddress = vm.envAddress("SBT_ADDRESS");

        // Recipients can be provided via env or hardcoded for testing
        address[] memory recipients = new address[](3);
        recipients[0] = 0x1234567890123456789012345678901234567890;
        recipients[1] = 0x2345678901234567890123456789012345678901;
        recipients[2] = 0x3456789012345678901234567890123456789012;

        vm.startBroadcast(deployerPrivateKey);

        SoulboundTokenSolution sbt = SoulboundTokenSolution(sbtAddress);

        console.log("\n=== Batch Minting SBTs ===");
        console.log("SBT Contract:", sbtAddress);
        console.log("Issuer:", msg.sender);
        console.log("Recipients:", recipients.length);

        for (uint256 i = 0; i < recipients.length; i++) {
            uint256 tokenId = sbt.mint(recipients[i]);
            console.log("\nToken", i + 1);
            console.log("  Token ID:", tokenId);
            console.log("  Recipient:", recipients[i]);
            console.log("  Locked:", sbt.locked(tokenId));
        }

        console.log("\n=== Batch Minting Complete ===");
        console.log("Total Minted:", recipients.length);
        console.log("Next Token ID:", sbt.getCurrentTokenId());

        vm.stopBroadcast();
    }
}

/**
 * DEPLOYMENT GUIDE:
 *
 * 1. SETUP ENVIRONMENT:
 *    Create a .env file with:
 *    PRIVATE_KEY=your_private_key
 *    RPC_URL=your_rpc_url
 *    SBT_ADDRESS=deployed_sbt_address (for interaction scripts)
 *    NEW_OWNER=address_for_recovery (optional)
 *
 * 2. DEPLOY SKELETON (for students):
 *    forge script script/DeploySoulboundTokens.s.sol:DeploySoulboundTokens \
 *      --rpc-url $RPC_URL \
 *      --broadcast \
 *      --verify
 *
 * 3. DEPLOY SOLUTION:
 *    forge script script/DeploySoulboundTokens.s.sol:DeploySoulboundTokensSolution \
 *      --rpc-url $RPC_URL \
 *      --broadcast \
 *      --verify
 *
 * 4. DEPLOY ALL PATTERNS:
 *    forge script script/DeploySoulboundTokens.s.sol:DeployAllPatterns \
 *      --rpc-url $RPC_URL \
 *      --broadcast
 *
 * 5. INTERACT WITH DEPLOYED SBT:
 *    forge script script/DeploySoulboundTokens.s.sol:InteractWithSBT \
 *      --rpc-url $RPC_URL \
 *      --broadcast
 *
 * 6. DEMO USE CASES:
 *    forge script script/DeploySoulboundTokens.s.sol:DemoSBTUseCases \
 *      --rpc-url $RPC_URL \
 *      --broadcast
 *
 * 7. BATCH MINT:
 *    forge script script/DeploySoulboundTokens.s.sol:MintBatchSBTs \
 *      --rpc-url $RPC_URL \
 *      --broadcast
 *
 * TESTNET RECOMMENDATIONS:
 * - Ethereum Sepolia
 * - Polygon Mumbai
 * - Optimism Goerli
 * - Arbitrum Goerli
 *
 * MAINNET CONSIDERATIONS:
 * - Carefully review recovery delay (7 days may be too long/short)
 * - Consider multi-sig for issuer role
 * - Implement pausability for emergencies
 * - Add comprehensive events for off-chain indexing
 * - Consider gas optimizations for batch operations
 * - Implement metadata standards (ERC721Metadata)
 */
