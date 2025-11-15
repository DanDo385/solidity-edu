// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/solution/ABIEncodingSolution.sol";

/**
 * @title DeployABIEncoding
 * @notice Deployment script for ABI Encoding educational contract
 * @dev Run with: forge script script/Deploy.s.sol:DeployABIEncoding --rpc-url <RPC> --broadcast
 */
contract DeployABIEncoding is Script {
    function run() external {
        // Use private key from env or default to Anvil's first account
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the contract
        ABIEncodingSolution encoder = new ABIEncodingSolution();

        console.log("========================================");
        console.log("ABI Encoding Contract Deployed!");
        console.log("========================================");
        console.log("Address:", address(encoder));
        console.log("");
        console.log("Try these functions to learn:");
        console.log("- demonstrateEncode() vs demonstrateEncodePacked()");
        console.log("- demonstrateHashCollision() (DANGEROUS!)");
        console.log("- getTransferSelector() (0xa9059cbb)");
        console.log("- calculateSelector(string)");
        console.log("========================================");

        // Demonstrate some functionality
        console.log("");
        console.log("Quick demonstrations:");
        console.log("");

        // Show selector calculation
        bytes4 transferSelector = encoder.getTransferSelector();
        console.log("ERC20 transfer selector:");
        console.logBytes4(transferSelector);

        // Show encoding difference
        bytes memory encoded = encoder.demonstrateEncode("AA", "BB");
        bytes memory packed = encoder.demonstrateEncodePacked("AA", "BB");

        console.log("");
        console.log("Encoding size comparison for ('AA', 'BB'):");
        console.log("abi.encode length:", encoded.length);
        console.log("abi.encodePacked length:", packed.length);

        // Demonstrate collision
        bool hasCollision = encoder.demonstrateHashCollision();
        console.log("");
        console.log("Hash collision demo:");
        console.log("encodePacked('A', 'BC') == encodePacked('AB', 'C'):", hasCollision);
        console.log("^ This is why encodePacked is dangerous!");

        // Show safe hashing
        bool safeCollision = encoder.demonstrateSafeHashing();
        console.log("");
        console.log("Safe hashing demo:");
        console.log("encode('A', 'BC') == encode('AB', 'C'):", safeCollision);
        console.log("^ abi.encode prevents collisions!");

        console.log("");
        console.log("========================================");

        vm.stopBroadcast();
    }
}
