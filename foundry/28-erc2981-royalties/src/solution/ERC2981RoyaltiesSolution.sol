// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Project28Solution - ERC-2981 Royalties
 * @notice Complete implementation of NFT with on-chain royalty standard
 * @dev Demonstrates ERC-2981 implementation with OpenZeppelin
 *
 * Key Features:
 * - ERC-2981 compliant royalty information
 * - Global default royalties for all tokens
 * - Per-token royalty customization
 * - Royalty fee validation and caps
 * - Proper interface detection
 * - Marketplace integration ready
 *
 * How ERC-2981 Works:
 * 1. Contract stores royalty information on-chain
 * 2. Marketplaces query royaltyInfo(tokenId, salePrice)
 * 3. Function returns (receiver, royaltyAmount)
 * 4. Marketplace pays royalty to receiver
 * 5. Marketplace pays remainder to seller
 *
 * Important Notes:
 * - Royalties are NOT enforced, only informational
 * - Marketplaces must voluntarily honor them
 * - Direct transfers bypass royalty mechanisms
 * - Royalty amounts calculated as percentage of sale price
 */
contract Project28Solution is ERC721, ERC2981, Ownable {
    // ============================================================
    // STATE VARIABLES
    // ============================================================

    // Constants
    // Maximum royalty fee (10% = 1000 basis points)
    // Prevents excessive royalties that marketplaces may reject
    uint96 public constant MAX_ROYALTY_FEE = 1000;

    // Counter for token IDs
    uint256 private _nextTokenId;

    // ============================================================
    // EVENTS
    // ============================================================

    // Events for tracking royalty changes
    event DefaultRoyaltySet(address indexed receiver, uint96 feeNumerator);
    event TokenRoyaltySet(uint256 indexed tokenId, address indexed receiver, uint96 feeNumerator);
    event TokenRoyaltyReset(uint256 indexed tokenId);

    /**
     * @notice Initialize NFT with default royalty settings
     * @param name NFT collection name
     * @param symbol NFT collection symbol
     * @param defaultRoyaltyReceiver Address to receive royalties
     * @param defaultRoyaltyFee Royalty percentage in basis points (e.g., 500 = 5%)
     *
     * @dev Basis points explained:
     * - 100 basis points = 1%
     * - 500 basis points = 5%
     * - 1000 basis points = 10%
     * - Denominator is always 10000
     */
    constructor(
        string memory name,
        string memory symbol,
        address defaultRoyaltyReceiver,
        uint96 defaultRoyaltyFee
    ) ERC721(name, symbol) Ownable(msg.sender) {
        // Validate royalty fee doesn't exceed maximum
        require(defaultRoyaltyFee <= MAX_ROYALTY_FEE, "Royalty fee too high");

        // Set default royalty for all tokens
        // This applies to all tokens unless overridden by setTokenRoyalty
        _setDefaultRoyalty(defaultRoyaltyReceiver, defaultRoyaltyFee);

        emit DefaultRoyaltySet(defaultRoyaltyReceiver, defaultRoyaltyFee);
    }

    /**
     * @notice Mint a new NFT
     * @param to Address to mint to
     * @return tokenId The ID of the minted token
     *
     * @dev Minted tokens automatically inherit default royalty settings
     * Can be overridden later with setTokenRoyalty
     */
    function mint(address to) external returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        return tokenId;
    }

    /**
     * @notice Set default royalty for all tokens
     * @param receiver Address to receive royalties
     * @param feeNumerator Royalty fee in basis points (e.g., 500 = 5%)
     *
     * @dev This sets the global royalty that applies to all tokens
     * unless a token has a specific royalty set via setTokenRoyalty
     *
     * Example calculation:
     * - Sale price: 10 ETH
     * - Fee numerator: 500 (5%)
     * - Royalty amount: (10 ETH * 500) / 10000 = 0.5 ETH
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        require(receiver != address(0), "Invalid receiver");
        require(feeNumerator <= MAX_ROYALTY_FEE, "Royalty fee too high");

        _setDefaultRoyalty(receiver, feeNumerator);

        emit DefaultRoyaltySet(receiver, feeNumerator);
    }

    /**
     * @notice Set royalty for a specific token
     * @param tokenId Token to set royalty for
     * @param receiver Address to receive royalties for this token
     * @param feeNumerator Royalty fee in basis points
     *
     * @dev Per-token royalties override the default royalty
     * Useful for:
     * - Special edition tokens with higher royalties
     * - Collaborative works with different creators
     * - Transferring royalty rights to new addresses
     *
     * Example use case:
     * - Default royalty: 5% to main artist
     * - Special token #42: 10% to featured collaborator
     */
    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external onlyOwner {
        require(receiver != address(0), "Invalid receiver");
        require(feeNumerator <= MAX_ROYALTY_FEE, "Royalty fee too high");

        _setTokenRoyalty(tokenId, receiver, feeNumerator);

        emit TokenRoyaltySet(tokenId, receiver, feeNumerator);
    }

    /**
     * @notice Reset royalty for a specific token to default
     * @param tokenId Token to reset royalty for
     *
     * @dev Removes per-token royalty override
     * Token will use default royalty after reset
     */
    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);

        emit TokenRoyaltyReset(tokenId);
    }

    /**
     * @notice Delete default royalty
     *
     * @dev Removes global royalty setting
     * Tokens with specific royalties keep them
     * Other tokens will have no royalty
     */
    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    /**
     * @notice Check interface support
     * @param interfaceId Interface to check
     * @return bool True if interface is supported
     *
     * @dev Must override to support both ERC721 and ERC2981
     *
     * Supported interfaces:
     * - 0x80ac58cd: ERC721
     * - 0x5b5e139f: ERC721Metadata
     * - 0x2a55205a: ERC2981 (Royalty Standard)
     * - 0x01ffc9a7: ERC165 (Interface Detection)
     *
     * Marketplaces use this to detect royalty support:
     * if (nft.supportsInterface(0x2a55205a)) {
     *     // NFT supports royalties
     *     (address receiver, uint256 amount) = nft.royaltyInfo(tokenId, salePrice);
     * }
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        // Check both parent contracts for interface support
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Get total supply
     * @return Total number of tokens minted
     */
    function totalSupply() external view returns (uint256) {
        return _nextTokenId;
    }
}

/*
MARKETPLACE INTEGRATION GUIDE:
================================

How a marketplace would integrate with this contract:

1. DETECTION:
   Check if NFT contract supports ERC-2981:
   ```
   bool supportsRoyalties = IERC165(nftContract).supportsInterface(0x2a55205a);
   ```

2. QUERY ROYALTY INFO:
   Get royalty details for a sale:
   ```
   (address receiver, uint256 royaltyAmount) =
       IERC2981(nftContract).royaltyInfo(tokenId, salePrice);
   ```

3. PROCESS PAYMENT:
   Example marketplace sale function:
   ```
   function executeSale(address nftContract, uint256 tokenId, uint256 price) external {
       address seller = IERC721(nftContract).ownerOf(tokenId);

       // Check royalty support
       if (IERC165(nftContract).supportsInterface(0x2a55205a)) {
           (address royaltyReceiver, uint256 royaltyAmount) =
               IERC2981(nftContract).royaltyInfo(tokenId, price);

           // Pay royalty
           payable(royaltyReceiver).transfer(royaltyAmount);

           // Pay seller (price minus royalty)
           payable(seller).transfer(price - royaltyAmount);
       } else {
           // No royalties, pay full amount to seller
           payable(seller).transfer(price);
       }

       // Transfer NFT
       IERC721(nftContract).transferFrom(seller, msg.sender, tokenId);
   }
   ```

CALCULATION EXAMPLES:
=====================

Example 1: Global Royalty
- Default royalty: 5% (500 basis points) to 0xABC...
- Token #1 sold for 10 ETH
- royaltyInfo(1, 10 ether) returns:
  * receiver: 0xABC...
  * amount: 0.5 ether (10 * 500 / 10000)

Example 2: Per-Token Royalty
- Token #42 has specific royalty: 10% (1000 basis points) to 0xDEF...
- Token #42 sold for 5 ETH
- royaltyInfo(42, 5 ether) returns:
  * receiver: 0xDEF...
  * amount: 0.5 ether (5 * 1000 / 10000)

Example 3: Multiple Currency Support
- Royalty: 5% (500 basis points)
- Sale in USDC: 1000 USDC (1000 * 10^6)
- royaltyInfo(1, 1000000000) returns:
  * receiver: 0xABC...
  * amount: 50000000 (50 USDC)

IMPORTANT LIMITATIONS:
======================

1. NOT ENFORCEABLE:
   - ERC-2981 only provides information
   - Marketplaces must voluntarily honor royalties
   - Direct transfers bypass royalties completely
   - No on-chain enforcement mechanism

2. MARKETPLACE DEPENDENT:
   - Only works if marketplace checks ERC-2981
   - Some marketplaces may ignore or cap royalties
   - Different marketplaces may implement differently

3. TRANSFER RESTRICTIONS:
   - Cannot prevent direct wallet-to-wallet transfers
   - Cannot force royalty payment on all sales
   - Consider Operator Filter Registry for enforcement

4. GAS COSTS:
   - Per-token royalties increase gas costs
   - Reading royalty info is cheap (view function)
   - Setting royalties costs gas

5. PRIVACY:
   - All royalty information is public
   - Receiver addresses visible on-chain
   - Percentages are transparent

BEST PRACTICES:
===============

1. Set reasonable royalty percentages (typically 2.5% - 10%)
2. Validate all inputs (max fees, non-zero addresses)
3. Emit events for all royalty changes
4. Document royalty structure clearly
5. Consider marketplace compatibility
6. Use global royalties for simplicity
7. Use per-token royalties for flexibility
8. Cap maximum royalties to ensure marketplace acceptance
9. Implement access controls for royalty updates
10. Test with actual marketplace integrations

ADVANCED PATTERNS:
==================

1. SPLIT ROYALTIES:
   Use PaymentSplitter as royalty receiver:
   ```
   PaymentSplitter splitter = new PaymentSplitter([artist, dev], [70, 30]);
   _setDefaultRoyalty(address(splitter), 500);
   ```

2. DYNAMIC ROYALTIES:
   Override royaltyInfo for custom logic:
   ```
   function royaltyInfo(uint256 tokenId, uint256 salePrice)
       public view override returns (address, uint256)
   {
       uint256 fee = isRare(tokenId) ? 1000 : 500; // Higher for rare
       return (receiver, (salePrice * fee) / 10000);
   }
   ```

3. TIME-BASED ROYALTIES:
   Decrease royalties over time:
   ```
   uint256 age = block.timestamp - mintTime[tokenId];
   uint256 fee = age > 365 days ? 250 : 500;
   ```

4. MULTI-TIER ROYALTIES:
   Different rates for price ranges:
   ```
   if (salePrice > 100 ether) fee = 1000; // 10% for high sales
   else if (salePrice > 10 ether) fee = 500; // 5% for medium
   else fee = 250; // 2.5% for low
   ```
*/

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. ERC-2981 STANDARDIZES NFT ROYALTIES
 *    ✅ Standardized interface for royalty information
 *    ✅ Works with any marketplace that supports it
 *    ✅ On-chain royalty data
 *    ✅ Real-world: Used by major NFT marketplaces
 *
 * 2. ROYALTIES ARE INFORMATIONAL, NOT ENFORCED
 *    ✅ Marketplaces voluntarily honor royalties
 *    ✅ Direct transfers bypass royalty mechanisms
 *    ✅ Cannot force payment on-chain
 *    ✅ Trust marketplace to pay correctly
 *
 * 3. BASIS POINTS ARE USED FOR PERCENTAGES
 *    ✅ 100 basis points = 1%
 *    ✅ 500 basis points = 5%
 *    ✅ 1000 basis points = 10%
 *    ✅ Denominator is always 10,000
 *
 * 4. GLOBAL VS PER-TOKEN ROYALTIES
 *    ✅ Global: Default for all tokens
 *    ✅ Per-token: Override for specific tokens
 *    ✅ Use global for simplicity
 *    ✅ Use per-token for flexibility
 *
 * 5. ROYALTY CALCULATION IS SIMPLE
 *    ✅ royaltyAmount = (salePrice * feeNumerator) / 10000
 *    ✅ Example: 10 ETH sale, 500 basis points = 0.5 ETH royalty
 *    ✅ Return (receiver, royaltyAmount)
 *    ✅ Marketplace pays royalty to receiver
 *
 * 6. MAXIMUM ROYALTY CAPS ARE IMPORTANT
 *    ✅ Some marketplaces reject high royalties
 *    ✅ Typical max: 10% (1000 basis points)
 *    ✅ Validate royalty fees don't exceed cap
 *    ✅ Ensures marketplace compatibility
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMMON MISTAKES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ❌ Setting royalties too high (marketplaces reject!)
 * ❌ Not validating fee numerator (can exceed 100%!)
 * ❌ Not implementing ERC165 interface detection
 * ❌ Assuming royalties are enforced (they're not!)
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          NEXT STEPS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * • Study marketplace royalty implementations
 * • Explore split royalty patterns
 * • Learn about dynamic royalty systems
 * • Move to Project 29 to learn about Merkle allowlists
 */
