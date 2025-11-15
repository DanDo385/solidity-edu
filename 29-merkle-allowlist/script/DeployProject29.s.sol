// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/solution/Project29Solution.sol";

/**
 * @title DeployProject29
 * @notice Deployment script for Merkle Proof Allowlist NFT
 * @dev This script demonstrates:
 * 1. How to generate a Merkle root on-chain (for testing)
 * 2. How to deploy the NFT contract with the root
 * 3. Best practices for production deployment
 *
 * IMPORTANT FOR PRODUCTION:
 * ========================
 * In production, you should generate the Merkle tree OFF-CHAIN using:
 * - JavaScript (merkletreejs library)
 * - Python (merkly library)
 * - Or any other tool that can compute keccak256 hashes
 *
 * Why off-chain?
 * - Building a tree on-chain is extremely gas-intensive
 * - Off-chain generation is free
 * - You need to distribute proofs to users anyway
 *
 * This script uses on-chain generation ONLY for demonstration!
 */
contract DeployProject29 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Option 1: Use pre-computed Merkle root (RECOMMENDED for production)
        bytes32 preComputedRoot = vm.envOr(
            "MERKLE_ROOT",
            bytes32(0x0)
        );

        bytes32 merkleRoot;

        if (preComputedRoot != bytes32(0)) {
            console.log("Using pre-computed Merkle root from environment");
            merkleRoot = preComputedRoot;
        } else {
            console.log("WARNING: No MERKLE_ROOT env var found");
            console.log("Generating sample Merkle root for testing...");
            merkleRoot = generateSampleMerkleRoot();
        }

        // Deploy the NFT contract
        Project29Solution nft = new Project29Solution(merkleRoot);

        console.log("Deployed Project29Solution at:", address(nft));
        console.log("Merkle Root:", vm.toString(merkleRoot));
        console.log("Owner:", nft.owner());
        console.log("Max Supply:", nft.MAX_SUPPLY());
        console.log("Public Mint Price:", nft.PUBLIC_MINT_PRICE());

        vm.stopBroadcast();

        // Log deployment info to file
        string memory deploymentInfo = string.concat(
            "Contract Address: ", vm.toString(address(nft)), "\n",
            "Merkle Root: ", vm.toString(merkleRoot), "\n",
            "Owner: ", vm.toString(nft.owner()), "\n",
            "Network: ", block.chainid == 1 ? "Mainnet" :
                        block.chainid == 11155111 ? "Sepolia" :
                        vm.toString(block.chainid), "\n",
            "Block Number: ", vm.toString(block.number), "\n"
        );

        vm.writeFile("./deployment-info.txt", deploymentInfo);
        console.log("\nDeployment info written to deployment-info.txt");
    }

    /**
     * @notice Generate a sample Merkle root for testing
     * @dev This builds a simple tree with 4 addresses
     * DO NOT use this for production! Generate off-chain instead.
     */
    function generateSampleMerkleRoot() internal view returns (bytes32) {
        // Sample allowlist addresses
        address[4] memory allowlist = [
            address(0x1111111111111111111111111111111111111111),
            address(0x2222222222222222222222222222222222222222),
            address(0x3333333333333333333333333333333333333333),
            address(0x4444444444444444444444444444444444444444)
        ];

        console.log("\nSample Allowlist:");
        for (uint i = 0; i < allowlist.length; i++) {
            console.log("  Address", i, ":", allowlist[i]);
        }

        // Generate leaf nodes
        bytes32[4] memory leaves;
        for (uint i = 0; i < allowlist.length; i++) {
            leaves[i] = keccak256(abi.encodePacked(allowlist[i]));
        }

        // Build tree layer 1 (combine pairs)
        bytes32 hash01 = hashPair(leaves[0], leaves[1]);
        bytes32 hash23 = hashPair(leaves[2], leaves[3]);

        // Build root (layer 2)
        bytes32 root = hashPair(hash01, hash23);

        console.log("\nMerkle Tree Structure:");
        console.log("  Root:", vm.toString(root));
        console.log("  Hash(0,1):", vm.toString(hash01));
        console.log("  Hash(2,3):", vm.toString(hash23));

        return root;
    }

    /**
     * @notice Hash a pair of nodes in sorted order
     * @dev Sorting ensures deterministic tree construction
     */
    function hashPair(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        return a < b ? keccak256(abi.encodePacked(a, b)) : keccak256(abi.encodePacked(b, a));
    }
}

/**
 * ============================================================================
 * OFF-CHAIN MERKLE TREE GENERATION GUIDE
 * ============================================================================
 *
 * For production deployments, generate your Merkle tree OFF-CHAIN.
 * Here are complete examples in different languages:
 *
 * ----------------------------------------------------------------------------
 * JAVASCRIPT (Node.js with ethers v6 and merkletreejs)
 * ----------------------------------------------------------------------------
 *
 * ```javascript
 * // npm install ethers merkletreejs
 *
 * const { ethers } = require('ethers');
 * const { MerkleTree } = require('merkletreejs');
 * const keccak256 = require('keccak256');
 * const fs = require('fs');
 *
 * // 1. Load your allowlist (from CSV, database, etc.)
 * const allowlist = [
 *   "0x1111111111111111111111111111111111111111",
 *   "0x2222222222222222222222222222222222222222",
 *   "0x3333333333333333333333333333333333333333",
 *   // ... add all your addresses
 * ];
 *
 * // 2. Create leaf nodes
 * const leaves = allowlist.map(address =>
 *   keccak256(ethers.solidityPacked(['address'], [address]))
 * );
 *
 * // 3. Build Merkle tree
 * const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });
 * const root = tree.getHexRoot();
 *
 * console.log('Merkle Root:', root);
 *
 * // 4. Generate proofs for each address
 * const proofs = {};
 * allowlist.forEach((address, index) => {
 *   const leaf = keccak256(ethers.solidityPacked(['address'], [address]));
 *   const proof = tree.getHexProof(leaf);
 *   proofs[address] = proof;
 * });
 *
 * // 5. Save to file
 * fs.writeFileSync('merkle-data.json', JSON.stringify({
 *   root: root,
 *   proofs: proofs,
 *   total: allowlist.length
 * }, null, 2));
 *
 * console.log('Saved merkle data to merkle-data.json');
 * ```
 *
 * ----------------------------------------------------------------------------
 * PYTHON (with web3.py and merkly)
 * ----------------------------------------------------------------------------
 *
 * ```python
 * # pip install web3 merkly
 *
 * from web3 import Web3
 * from merkly.mtree import MerkleTree
 * import json
 *
 * # 1. Load allowlist
 * allowlist = [
 *     "0x1111111111111111111111111111111111111111",
 *     "0x2222222222222222222222222222222222222222",
 *     "0x3333333333333333333333333333333333333333",
 * ]
 *
 * # 2. Create leaf nodes
 * leaves = [
 *     Web3.solidity_keccak(['address'], [Web3.to_checksum_address(addr)])
 *     for addr in allowlist
 * ]
 *
 * # 3. Build tree
 * tree = MerkleTree(leaves)
 * root = tree.root.hex()
 *
 * print(f'Merkle Root: {root}')
 *
 * # 4. Generate proofs
 * proofs = {}
 * for i, addr in enumerate(allowlist):
 *     proof = [p.hex() for p in tree.get_proof(leaves[i])]
 *     proofs[addr] = proof
 *
 * # 5. Save to file
 * with open('merkle-data.json', 'w') as f:
 *     json.dump({
 *         'root': root,
 *         'proofs': proofs,
 *         'total': len(allowlist)
 *     }, f, indent=2)
 * ```
 *
 * ----------------------------------------------------------------------------
 * FOUNDRY (Using Murky Library)
 * ----------------------------------------------------------------------------
 *
 * ```solidity
 * // Install: forge install dmfxyz/murky
 *
 * import "murky/Merkle.sol";
 * import "forge-std/Script.sol";
 *
 * contract GenerateMerkleTree is Script {
 *     Merkle merkle = new Merkle();
 *
 *     function run() external {
 *         // Define allowlist
 *         address[] memory allowlist = new address[](3);
 *         allowlist[0] = 0x1111111111111111111111111111111111111111;
 *         allowlist[1] = 0x2222222222222222222222222222222222222222;
 *         allowlist[2] = 0x3333333333333333333333333333333333333333;
 *
 *         // Create leaves
 *         bytes32[] memory leaves = new bytes32[](allowlist.length);
 *         for (uint i = 0; i < allowlist.length; i++) {
 *             leaves[i] = keccak256(abi.encodePacked(allowlist[i]));
 *         }
 *
 *         // Get root
 *         bytes32 root = merkle.getRoot(leaves);
 *         console.log("Root:", vm.toString(root));
 *
 *         // Generate proofs
 *         for (uint i = 0; i < allowlist.length; i++) {
 *             bytes32[] memory proof = merkle.getProof(leaves, i);
 *             console.log("Proof for", allowlist[i]);
 *             for (uint j = 0; j < proof.length; j++) {
 *                 console.log("  ", vm.toString(proof[j]));
 *             }
 *         }
 *     }
 * }
 * ```
 *
 * ----------------------------------------------------------------------------
 * DEPLOYMENT STEPS
 * ----------------------------------------------------------------------------
 *
 * 1. Generate Merkle Tree Off-Chain:
 *    $ node generate-merkle.js
 *    # Outputs: merkle-data.json
 *
 * 2. Set Environment Variables:
 *    $ export MERKLE_ROOT=0x1234...
 *    $ export PRIVATE_KEY=0xabcd...
 *    $ export RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY
 *
 * 3. Deploy Contract:
 *    $ forge script script/DeployProject29.s.sol \
 *      --rpc-url $RPC_URL \
 *      --broadcast \
 *      --verify
 *
 * 4. Distribute Proofs:
 *    - Upload merkle-data.json to IPFS/Arweave
 *    - Create API endpoint for users to fetch their proofs
 *    - Or include in your frontend
 *
 * 5. Verify on Etherscan (optional):
 *    $ forge verify-contract \
 *      --chain-id 11155111 \
 *      --constructor-args $(cast abi-encode "constructor(bytes32)" $MERKLE_ROOT) \
 *      --compiler-version v0.8.20 \
 *      CONTRACT_ADDRESS \
 *      src/solution/Project29Solution.sol:Project29Solution
 *
 * ----------------------------------------------------------------------------
 * PROOF DISTRIBUTION STRATEGIES
 * ----------------------------------------------------------------------------
 *
 * Option 1: IPFS/Arweave
 * - Upload merkle-data.json to IPFS
 * - Users fetch their proof from IPFS
 * - Decentralized and censorship-resistant
 * - Example: ipfs://Qm.../merkle-data.json
 *
 * Option 2: Backend API
 * - Create endpoint: GET /api/proof/:address
 * - Returns proof for given address
 * - Can rate limit and add analytics
 * - Easier for users
 *
 * Option 3: Frontend Bundle
 * - Include proofs in your web app
 * - Users look up their own proof
 * - No backend needed
 * - Works offline
 *
 * Option 4: Hybrid
 * - Small lists: Bundle with frontend
 * - Large lists: Backend API + IPFS backup
 *
 * ----------------------------------------------------------------------------
 * SECURITY CHECKLIST
 * ----------------------------------------------------------------------------
 *
 * Before deploying to mainnet:
 *
 * ✅ Merkle root generated correctly off-chain
 * ✅ All allowlisted addresses verified
 * ✅ Proofs tested for sample addresses
 * ✅ Contract audited (for production)
 * ✅ Ownership transferred to multisig (if needed)
 * ✅ Emergency pause mechanism considered
 * ✅ Max supply set correctly
 * ✅ Public mint price set correctly
 * ✅ Merkle root made immutable (or secured)
 * ✅ Proof distribution method tested
 * ✅ Gas costs analyzed
 * ✅ Edge cases tested
 *
 * ----------------------------------------------------------------------------
 * COST ANALYSIS
 * ----------------------------------------------------------------------------
 *
 * Deployment costs (approximate):
 * - Contract deployment: ~2,000,000 gas
 * - At 30 gwei: ~0.06 ETH (~$120 at $2000/ETH)
 *
 * Per-user costs:
 * - Allowlist mint: ~80,000 gas (~$4.80)
 * - Public mint: ~70,000 gas (~$4.20)
 *
 * Comparison with mapping approach (1000 addresses):
 * - Mapping setup: ~20,000,000 gas (~$1,200)
 * - Merkle setup: ~20,000 gas (~$1.20)
 * - Savings: ~$1,199 🎉
 *
 * ============================================================================
 */
