// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title Project29Solution - Merkle Proof Allowlist NFT
 * @notice Complete implementation of an NFT with Merkle tree allowlist
 * @dev This is the solution contract demonstrating best practices
 *
 * MERKLE TREE CONSTRUCTION (Off-Chain):
 * =====================================
 * This contract expects a Merkle tree constructed as follows:
 *
 * 1. Create leaf nodes by hashing each allowlisted address:
 *    leaf = keccak256(abi.encodePacked(address))
 *
 * 2. Build the tree bottom-up:
 *    - Sort pairs to ensure deterministic tree construction
 *    - Hash pairs together: keccak256(abi.encodePacked(left, right))
 *    - Continue until you reach the root
 *
 * 3. Store only the root on-chain (this contract)
 *
 * 4. Generate proofs for each address off-chain
 *    - Proof = array of sibling hashes from leaf to root
 *
 * Example using merkletreejs (TypeScript):
 * ```typescript
 * import { MerkleTree } from 'merkletreejs';
 * import keccak256 from 'keccak256';
 * import { ethers } from 'ethers';
 *
 * const allowlist: string[] = ["0x123...", "0x456...", "0x789..."];
 * const leaves: Buffer[] = allowlist.map(addr =>
 *   keccak256(ethers.solidityPacked(['address'], [addr]))
 * );
 * const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });
 * const root = tree.getRoot();
 *
 * // Generate proof for specific address
 * const proof = tree.getHexProof(leaves[0]);
 * ```
 *
 * Example using Murky (Solidity/Foundry):
 * ```solidity
 * import "murky/Merkle.sol";
 *
 * Merkle merkle = new Merkle();
 * bytes32[] memory leaves = new bytes32[](3);
 * leaves[0] = keccak256(abi.encodePacked(address1));
 * leaves[1] = keccak256(abi.encodePacked(address2));
 * leaves[2] = keccak256(abi.encodePacked(address3));
 *
 * bytes32 root = merkle.getRoot(leaves);
 * bytes32[] memory proof = merkle.getProof(leaves, 0);
 * ```
 */
contract Project29Solution is ERC721, Ownable {
    // ============================================================
    // STATE VARIABLES
    // ============================================================

    // Constants
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant PUBLIC_MINT_PRICE = 0.01 ether;

    /// @notice The Merkle root representing the entire allowlist
    bytes32 public merkleRoot;

    /// @notice Tracks which addresses have already claimed their NFT
    mapping(address => bool) public hasClaimed;

    /// @notice Counter for token IDs
    uint256 private _nextTokenId;

    /// @notice Whether public minting is enabled
    bool public publicMintEnabled;

    // ============================================================
    // EVENTS
    // ============================================================

    event MerkleRootUpdated(bytes32 indexed oldRoot, bytes32 indexed newRoot);
    event AllowlistMinted(address indexed account, uint256 indexed tokenId);
    event PublicMinted(address indexed account, uint256 indexed tokenId);

    // ============================================================
    // ERRORS
    // ============================================================

    error AlreadyClaimed();
    error InvalidProof();
    error MaxSupplyReached();
    error PublicMintNotEnabled();
    error IncorrectPayment();
    error NoBalanceToWithdraw();

    // ============================================================
    // CONSTRUCTOR
    // ============================================================

    /**
     * @notice Initialize the NFT contract with a Merkle root
     * @param _merkleRoot The root hash of the Merkle tree containing allowlisted addresses
     */
    constructor(bytes32 _merkleRoot) ERC721("MerkleNFT", "MNFT") Ownable(msg.sender) {
        merkleRoot = _merkleRoot;
    }

    // ============================================================
    // MINTING FUNCTIONS
    // ============================================================

    /**
     * @notice Allows allowlisted addresses to mint for free
     * @param proof The Merkle proof proving the sender is on the allowlist
     *
     * @dev How this works:
     * 1. Create a leaf node from msg.sender's address
     * 2. Verify the proof against the stored Merkle root
     * 3. If valid, the sender is on the allowlist!
     *
     * Security considerations:
     * - Must check hasClaimed to prevent double claiming
     * - Proof verification is done by OpenZeppelin's battle-tested library
     * - No need to store the entire allowlist on-chain!
     */
    function allowlistMint(bytes32[] calldata proof) external {
        // Check if already claimed (prevent double claiming)
        if (hasClaimed[msg.sender]) revert AlreadyClaimed();

        // Check max supply
        if (_nextTokenId >= MAX_SUPPLY) revert MaxSupplyReached();

        // Verify the Merkle proof
        // 1. Create leaf from sender's address
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        // 2. Verify proof using OpenZeppelin's MerkleProof library
        // This reconstructs the path from leaf to root and compares with stored root
        if (!MerkleProof.verify(proof, merkleRoot, leaf)) {
            revert InvalidProof();
        }

        // Mark as claimed
        hasClaimed[msg.sender] = true;

        // Mint the NFT
        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);

        emit AllowlistMinted(msg.sender, tokenId);
    }

    /**
     * @notice Verify if an address is on the allowlist
     * @param account The address to check
     * @param proof The Merkle proof for this address
     * @return bool True if the proof is valid
     *
     * @dev This is a view function - it doesn't modify state
     * Useful for frontends to check eligibility before submitting transaction
     */
    function verifyAllowlist(address account, bytes32[] calldata proof) public view returns (bool) {
        // Create the leaf node for this address
        // IMPORTANT: This MUST match how you created the tree off-chain!
        bytes32 leaf = keccak256(abi.encodePacked(account));

        // Verify the proof
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    /**
     * @notice Public minting (enabled after allowlist phase)
     * @dev Anyone can mint by paying the public price
     */
    function publicMint() external payable {
        // Check if public minting is enabled
        if (!publicMintEnabled) revert PublicMintNotEnabled();

        // Check correct payment
        if (msg.value != PUBLIC_MINT_PRICE) revert IncorrectPayment();

        // Check max supply
        if (_nextTokenId >= MAX_SUPPLY) revert MaxSupplyReached();

        // Mint the NFT
        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);

        emit PublicMinted(msg.sender, tokenId);
    }

    // ============ Admin Functions ============

    /**
     * @notice Update the Merkle root (only owner)
     * @param _merkleRoot The new Merkle root
     *
     * @dev ⚠️ WARNING: Updating the root will invalidate ALL previous proofs!
     * Use cases:
     * - Fixing an error in the original allowlist
     * - Adding a new wave of allowlisted addresses
     *
     * Best practice:
     * - Consider making the root immutable for most use cases
     * - If updates are needed, use a timelock or governance
     * - Clear communication with users before updating
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        bytes32 oldRoot = merkleRoot;
        merkleRoot = _merkleRoot;
        emit MerkleRootUpdated(oldRoot, _merkleRoot);
    }

    /**
     * @notice Enable or disable public minting
     * @param enabled Whether public minting should be enabled
     */
    function setPublicMintEnabled(bool enabled) external onlyOwner {
        publicMintEnabled = enabled;
    }

    /**
     * @notice Withdraw contract balance (only owner)
     * @dev Transfers all ETH from public mints to the owner
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert NoBalanceToWithdraw();

        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Transfer failed");
    }

    // ============ View Functions ============

    /**
     * @notice Get the current token ID counter
     * @return uint256 The next token ID to be minted
     */
    function getCurrentTokenId() external view returns (uint256) {
        return _nextTokenId;
    }

    /**
     * @notice Check if an address has claimed their allowlist NFT
     * @param account The address to check
     * @return bool True if the address has claimed
     */
    function hasAddressClaimed(address account) external view returns (bool) {
        return hasClaimed[account];
    }

    /**
     * @notice Get the total number of NFTs minted
     * @return uint256 The total supply
     */
    function totalSupply() public view returns (uint256) {
        return _nextTokenId;
    }
}

/**
 * ============================================================================
 * IMPLEMENTATION NOTES
 * ============================================================================
 *
 * 1. WHY MERKLE TREES?
 * ---------------------
 * Traditional approach: Store mapping(address => bool) for allowlist
 * - Gas cost to store 1000 addresses: ~20,000,000 gas
 * - Gas cost per mint: ~2,100 gas (SLOAD)
 *
 * Merkle tree approach: Store single bytes32 root
 * - Gas cost to store root: ~20,000 gas
 * - Gas cost per mint: ~3,500 gas (proof verification)
 *
 * Winner: Merkle trees for large allowlists!
 * Break-even point: ~10-20 addresses
 *
 * 2. SECURITY CONSIDERATIONS
 * ---------------------------
 * a) Double Claiming:
 *    - MUST track hasClaimed mapping
 *    - Alternative: Burn a token on claim
 *
 * b) Proof Forgery:
 *    - OpenZeppelin's MerkleProof handles this correctly
 *    - Sorts pairs during verification
 *    - Prevents second pre-image attacks
 *
 * c) Leaf Construction:
 *    - Using just keccak256(abi.encodePacked(address)) is usually fine
 *    - For extra security, include contract address or chain ID:
 *      keccak256(abi.encodePacked(address, contractAddress, block.chainid))
 *
 * d) Root Updates:
 *    - Invalidates all previous proofs!
 *    - Consider making immutable for most use cases
 *    - Use events to track updates
 *
 * 3. GAS OPTIMIZATION TIPS
 * -------------------------
 * a) Proof Size:
 *    - Proof size = O(log₂ n) where n = number of leaves
 *    - 1,000 addresses → ~10 proof elements → ~3,500 gas
 *    - 1,000,000 addresses → ~20 proof elements → ~7,000 gas
 *
 * b) Tree Balance:
 *    - Keep tree balanced for optimal proof size
 *    - Use sortPairs: true when building tree
 *
 * c) Custom Errors:
 *    - Using custom errors instead of require strings
 *    - Saves gas on reverts
 *
 * 4. COMMON MISTAKES
 * ------------------
 * ❌ Not tracking hasClaimed → users claim multiple times
 * ❌ Different leaf hashing on/off chain → proofs don't verify
 * ❌ Not using sortPairs → inconsistent tree construction
 * ❌ Updating root without warning → invalidates all proofs
 * ❌ Storing proofs on-chain → defeats the purpose!
 *
 * 5. TESTING CHECKLIST
 * --------------------
 * ✅ Valid proof verifies correctly
 * ✅ Invalid proof is rejected
 * ✅ Forged proof is rejected
 * ✅ Empty proof is rejected
 * ✅ Double claiming is prevented
 * ✅ Correct token is minted
 * ✅ Events are emitted
 * ✅ Gas costs are reasonable
 * ✅ Root updates work correctly
 * ✅ Different addresses can claim
 *
 * 6. PRODUCTION CONSIDERATIONS
 * ----------------------------
 * - Store tree data off-chain (IPFS, Arweave, or your backend)
 * - Provide API for users to fetch their proofs
 * - Consider using multiProof for batch claims
 * - Document your leaf construction method clearly
 * - Test with realistic allowlist sizes
 * - Have a plan for root updates (if needed)
 * - Consider adding pause functionality
 * - Audit before mainnet deployment!
 *
 * 7. ALTERNATIVE APPROACHES
 * -------------------------
 * a) Signature-based allowlist:
 *    - Owner signs each allowed address
 *    - Users submit signature with mint
 *    - More flexible but requires online signer
 *
 * b) Token-gated:
 *    - Check if user holds specific token
 *    - No allowlist needed
 *    - Anyone can buy/sell access
 *
 * c) Commit-reveal:
 *    - Users commit to mint in advance
 *    - Reveal later to actually mint
 *    - Prevents some MEV attacks
 *
 * ============================================================================
 */

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. MERKLE TREES ENABLE GAS-EFFICIENT ALLOWLISTS
 *    ✅ Store only root hash (32 bytes) instead of all addresses
 *    ✅ Verify proofs off-chain
 *    ✅ O(log n) proof size vs O(n) storage
 *    ✅ Real-world: Used by major NFT projects
 *
 * 2. MERKLE PROOF VERIFICATION IS SIMPLE
 *    ✅ Reconstruct path from leaf to root
 *    ✅ Hash sibling nodes along the path
 *    ✅ Compare computed root with stored root
 *    ✅ If match, proof is valid
 *
 * 3. LEAF HASHING MUST BE CONSISTENT
 *    ✅ Use same hashing function for all leaves
 *    ✅ Common: keccak256(abi.encodePacked(address))
 *    ✅ Sort pairs for deterministic trees
 *    ✅ Must match between tree construction and verification
 *
 * 4. PROOF GENERATION IS OFF-CHAIN
 *    ✅ Build Merkle tree off-chain
 *    ✅ Generate proofs for each address
 *    ✅ Provide proofs to users
 *    ✅ Users submit proofs on-chain
 *
 * 5. GAS SAVINGS SCALE WITH LIST SIZE
 *    ✅ 100 addresses: ~5,000 gas vs ~200,000 gas (mapping)
 *    ✅ 1,000 addresses: ~5,000 gas vs ~2,000,000 gas
 *    ✅ 10,000 addresses: ~5,000 gas vs ~20,000,000 gas
 *    ✅ Larger lists = better savings
 *
 * 6. USE CASES FOR MERKLE ALLOWLISTS
 *    ✅ NFT allowlist mints
 *    ✅ Airdrop eligibility
 *    ✅ Whitelist verification
 *    ✅ Permission checks
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMMON MISTAKES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ❌ Inconsistent leaf hashing (proofs fail!)
 * ❌ Not sorting pairs in tree construction (different roots!)
 * ❌ Not preventing double-claiming (track claimed addresses!)
 * ❌ Wrong proof order (must match tree structure!)
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          NEXT STEPS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * • Study Merkle tree algorithms
 * • Explore batch proof verification
 * • Learn about sparse Merkle trees
 * • Move to Project 30 to learn about on-chain SVG rendering
 */
