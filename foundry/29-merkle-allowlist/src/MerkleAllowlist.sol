// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title Project29 - Merkle Proof Allowlist NFT
 * @notice An NFT contract that uses Merkle trees for gas-efficient allowlist verification
 * @dev This contract demonstrates how to use Merkle proofs for allowlist minting
 *
 * Key Concepts:
 * - Merkle trees store thousands of addresses as a single 32-byte root
 * - Users provide proofs to verify they're on the allowlist
 * - Much more gas efficient than storing mapping of all addresses
 * - Prevents double claiming with a claimed tracking mechanism
 *
 * Learning Objectives:
 * 1. Understand how Merkle trees work
 * 2. Implement Merkle proof verification
 * 3. Compare gas costs with traditional mapping approach
 * 4. Prevent double claiming attacks
 * 5. Create Merkle trees off-chain
 */
contract Project29 is ERC721, Ownable {
    // ============================================================
    // STATE VARIABLES
    // ============================================================

    // Constants
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant PUBLIC_MINT_PRICE = 0.01 ether;

    /// @notice The Merkle root representing the entire allowlist
    /// @dev This single 32-byte value represents potentially thousands of addresses
    bytes32 public merkleRoot;

    /// @notice Tracks which addresses have already claimed their NFT
    /// @dev Prevents double claiming - this is critical for security!
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
    // CONSTRUCTOR
    // ============================================================

    /**
     * @notice Initialize the NFT contract with a Merkle root
     * @param _merkleRoot The root hash of the Merkle tree containing allowlisted addresses
     */
    constructor(bytes32 _merkleRoot) ERC721("MerkleNFT", "MNFT") Ownable(msg.sender) {
        merkleRoot = _merkleRoot;
    }

    // ============ TODO: Implement These Functions ============

    /**
     * @notice Allows allowlisted addresses to mint for free
     * @param proof The Merkle proof proving the sender is on the allowlist
     *
     * Requirements:
     * - Sender must not have already claimed
     * - Proof must be valid
     * - Must not exceed max supply
     *
     * TODO: Implement this function
     * Steps:
     * 1. Check that msg.sender hasn't already claimed
     * 2. Verify the Merkle proof
     * 3. Mark msg.sender as having claimed
     * 4. Mint the NFT
     * 5. Emit an event
     *
     * Hints:
     * - Use MerkleProof.verify() from OpenZeppelin
     * - Create the leaf by hashing the address: keccak256(abi.encodePacked(msg.sender))
     * - Don't forget to increment _nextTokenId
     */
    function allowlistMint(bytes32[] calldata proof) external {
        // TODO: Implement allowlist minting
        revert("Not implemented");
    }

    /**
     * @notice Verify if an address is on the allowlist
     * @param account The address to check
     * @param proof The Merkle proof for this address
     * @return bool True if the proof is valid
     *
     * TODO: Implement this function
     * Steps:
     * 1. Create a leaf node by hashing the account address
     * 2. Use MerkleProof.verify() to check if the proof is valid
     *
     * Hints:
     * - Leaf must be: keccak256(abi.encodePacked(account))
     * - This must match how you created the tree off-chain!
     */
    function verifyAllowlist(address account, bytes32[] calldata proof) public view returns (bool) {
        // TODO: Implement proof verification
        revert("Not implemented");
    }

    /**
     * @notice Public minting (enabled after allowlist phase)
     * @dev Anyone can mint by paying the public price
     *
     * TODO: Implement this function
     * Steps:
     * 1. Check that public minting is enabled
     * 2. Check that correct payment was sent
     * 3. Check that max supply isn't exceeded
     * 4. Mint the NFT
     * 5. Emit an event
     */
    function publicMint() external payable {
        // TODO: Implement public minting
        revert("Not implemented");
    }

    // ============ Admin Functions ============

    /**
     * @notice Update the Merkle root (only owner)
     * @param _merkleRoot The new Merkle root
     * @dev Be careful! This will invalidate all previous proofs
     *
     * TODO: Implement this function
     * Steps:
     * 1. Store the old root for the event
     * 2. Update merkleRoot
     * 3. Emit an event
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        // TODO: Implement Merkle root update
        revert("Not implemented");
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
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        payable(owner()).transfer(balance);
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

// ============ BONUS CHALLENGES ============
//
// 1. Gas Comparison:
//    - Create a version using mapping(address => bool) instead of Merkle tree
//    - Compare gas costs for setting up 100, 1000, 10000 addresses
//    - Compare gas costs for minting with each approach
//
// 2. Multi-Tier Allowlist:
//    - Add different Merkle roots for different tiers (Gold, Silver, Bronze)
//    - Each tier gets different mint limits or prices
//
// 3. Allowlist with Amounts:
//    - Allow different addresses to mint different amounts
//    - Include the amount in the Merkle leaf: keccak256(abi.encodePacked(address, amount))
//    - Users provide both address and amount in their proof
//
// 4. Time-Based Allowlist:
//    - Add start and end times for allowlist minting
//    - Automatically enable public minting after allowlist ends
//
// 5. Batch Minting:
//    - Allow users to mint multiple NFTs at once if allowed
//    - Implement using OpenZeppelin's multiProofVerify
//
// 6. Off-Chain Tree Generation:
//    - Write a script to generate Merkle trees from a CSV file
//    - Export proofs for each address to JSON
//    - Create a simple web interface to look up proofs
//
// 7. Emergency Stop:
//    - Add a pause mechanism using OpenZeppelin's Pausable
//    - Pause all minting in case of issues
//
// 8. Refund Mechanism:
//    - If public mint is overpaid, refund the excess
//    - Handle edge cases carefully
