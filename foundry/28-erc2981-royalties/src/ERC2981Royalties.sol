// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Project28 - ERC-2981 Royalties
 * @notice NFT contract with on-chain royalty standard
 * @dev Implement ERC-2981 for marketplace royalty integration
 *
 * Learning Objectives:
 * 1. Understand EIP-2981 royalty standard
 * 2. Implement on-chain royalty information
 * 3. Calculate royalty fees correctly
 * 4. Manage global and per-token royalties
 * 5. Integrate with NFT marketplaces
 *
 * Key Concepts:
 * - ERC2981 interface and royaltyInfo function
 * - Basis points for percentage calculation
 * - Global vs per-token royalty settings
 * - Interface detection via ERC165
 * - Marketplace integration patterns
 */
contract Project28 is ERC721, ERC2981, Ownable {
    // ============================================================
    // STATE VARIABLES
    // ============================================================

    // Constants
    uint96 public constant MAX_ROYALTY_FEE = 1000;

    // Counter for token IDs
    uint256 private _nextTokenId;

    // ============================================================
    // EVENTS
    // ============================================================

    event DefaultRoyaltySet(address indexed receiver, uint96 feeNumerator);
    event TokenRoyaltySet(uint256 indexed tokenId, address indexed receiver, uint96 feeNumerator);
    event TokenRoyaltyReset(uint256 indexed tokenId);

    constructor(
        string memory name,
        string memory symbol,
        address defaultRoyaltyReceiver,
        uint96 defaultRoyaltyFee
    ) ERC721(name, symbol) Ownable(msg.sender) {
        // TODO: Validate royalty fee doesn't exceed maximum
        // TODO: Set default royalty for all tokens
        // Hint: Use _setDefaultRoyalty from ERC2981
    }

    /**
     * @notice Mint a new NFT
     * @param to Address to mint to
     * @return tokenId The ID of the minted token
     */
    function mint(address to) external returns (uint256) {
        // TODO: Implement minting logic
        // TODO: Increment token counter
        // TODO: Mint token using _safeMint
        // TODO: Return the minted token ID
    }

    /**
     * @notice Set default royalty for all tokens
     * @param receiver Address to receive royalties
     * @param feeNumerator Royalty fee in basis points (e.g., 500 = 5%)
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        // TODO: Validate receiver is not zero address
        // TODO: Validate fee doesn't exceed maximum
        // TODO: Set default royalty using _setDefaultRoyalty
        // TODO: Emit DefaultRoyaltySet event
    }

    /**
     * @notice Set royalty for a specific token
     * @param tokenId Token to set royalty for
     * @param receiver Address to receive royalties
     * @param feeNumerator Royalty fee in basis points
     */
    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external onlyOwner {
        // TODO: Validate receiver is not zero address
        // TODO: Validate fee doesn't exceed maximum
        // TODO: Set token-specific royalty using _setTokenRoyalty
        // TODO: Emit TokenRoyaltySet event
    }

    /**
     * @notice Reset royalty for a specific token to default
     * @param tokenId Token to reset royalty for
     */
    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        // TODO: Reset token royalty using _resetTokenRoyalty
        // TODO: Emit TokenRoyaltyReset event
    }

    /**
     * @notice Delete default royalty
     */
    function deleteDefaultRoyalty() external onlyOwner {
        // TODO: Delete default royalty using _deleteDefaultRoyalty
    }

    /**
     * @notice Check interface support
     * @dev Must override to support both ERC721 and ERC2981
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        // TODO: Return combined interface support from both parent contracts
        // Hint: Use super.supportsInterface(interfaceId)
    }

    /**
     * @notice Get total supply
     */
    function totalSupply() external view returns (uint256) {
        return _nextTokenId;
    }
}

/*
TASKS:
1. Complete the constructor to set default royalty
2. Implement the mint function
3. Implement setDefaultRoyalty with validation
4. Implement setTokenRoyalty with validation
5. Implement resetTokenRoyalty
6. Implement deleteDefaultRoyalty
7. Override supportsInterface correctly
8. Run tests to verify your implementation

TESTING:
- forge test --match-path test/Project28.t.sol -vv

HINTS:
- Basis points: 100 = 1%, 500 = 5%, 1000 = 10%
- Denominator is always 10000 for basis points
- ERC2981 uses _setDefaultRoyalty(receiver, feeNumerator)
- Per-token royalties override global royalties
- Must override supportsInterface for multiple inheritance
- ERC2981 interface ID is 0x2a55205a

MARKETPLACE INTEGRATION NOTES:
1. Marketplaces check: supportsInterface(0x2a55205a)
2. Marketplaces call: royaltyInfo(tokenId, salePrice)
3. Returns: (receiver address, royalty amount)
4. Marketplace pays: royalty to receiver, rest to seller
*/
