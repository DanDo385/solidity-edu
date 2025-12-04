// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title ExampleMarketplace
 * @notice Example marketplace demonstrating ERC-2981 integration
 * @dev This is a simplified example showing how marketplaces integrate with ERC-2981
 *
 * IMPORTANT: This is for educational purposes only!
 * Production marketplaces have additional features:
 * - Listings management
 * - Offer systems
 * - Auction mechanisms
 * - Fee structures
 * - Security features
 * - Gas optimizations
 *
 * How This Marketplace Uses ERC-2981:
 * 1. Seller lists NFT for sale
 * 2. Buyer purchases NFT
 * 3. Marketplace checks if NFT supports ERC-2981
 * 4. If yes, calculates royalty and pays creator
 * 5. Pays seller the remainder
 * 6. Transfers NFT to buyer
 */
contract ExampleMarketplace {
    // Listing structure
    struct Listing {
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 price;
        bool active;
    }

    // Listings by ID
    mapping(uint256 => Listing) public listings;
    uint256 public nextListingId;

    // Events
    event Listed(
        uint256 indexed listingId,
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        uint256 price
    );
    event Purchased(
        uint256 indexed listingId,
        address indexed buyer,
        uint256 price,
        uint256 royaltyPaid
    );
    event Delisted(uint256 indexed listingId);

    /**
     * @notice List an NFT for sale
     * @param nftContract Address of the NFT contract
     * @param tokenId Token ID to list
     * @param price Sale price in wei
     */
    function list(address nftContract, uint256 tokenId, uint256 price) external returns (uint256) {
        require(price > 0, "Price must be > 0");

        // Verify seller owns the NFT
        require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "Not token owner");

        // Verify marketplace is approved
        require(
            IERC721(nftContract).isApprovedForAll(msg.sender, address(this)) ||
            IERC721(nftContract).getApproved(tokenId) == address(this),
            "Marketplace not approved"
        );

        uint256 listingId = nextListingId++;

        listings[listingId] = Listing({
            seller: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            price: price,
            active: true
        });

        emit Listed(listingId, msg.sender, nftContract, tokenId, price);

        return listingId;
    }

    /**
     * @notice Purchase a listed NFT
     * @param listingId ID of the listing to purchase
     *
     * @dev This is where ERC-2981 integration happens!
     *
     * Steps:
     * 1. Validate listing is active and payment is correct
     * 2. Check if NFT supports ERC-2981 via ERC165
     * 3. If yes, call royaltyInfo() to get royalty details
     * 4. Pay royalty to creator
     * 5. Pay remainder to seller
     * 6. Transfer NFT to buyer
     */
    function purchase(uint256 listingId) external payable {
        Listing storage listing = listings[listingId];

        require(listing.active, "Listing not active");
        require(msg.value == listing.price, "Incorrect payment");

        // Mark as inactive before transfers (reentrancy protection)
        listing.active = false;

        uint256 royaltyAmount = 0;
        address royaltyReceiver = address(0);

        // CHECK FOR ERC-2981 SUPPORT
        // This is the key integration point!
        bool supportsRoyalties = IERC165(listing.nftContract).supportsInterface(0x2a55205a);

        if (supportsRoyalties) {
            // GET ROYALTY INFORMATION
            // Call the royaltyInfo function with tokenId and sale price
            (royaltyReceiver, royaltyAmount) =
                IERC2981(listing.nftContract).royaltyInfo(listing.tokenId, listing.price);

            // PAY ROYALTY
            // Send royalty to creator if amount > 0
            if (royaltyAmount > 0 && royaltyReceiver != address(0)) {
                (bool royaltySuccess,) = payable(royaltyReceiver).call{value: royaltyAmount}("");
                require(royaltySuccess, "Royalty payment failed");
            }
        }

        // PAY SELLER
        // Seller receives sale price minus royalty
        uint256 sellerProceeds = listing.price - royaltyAmount;
        (bool sellerSuccess,) = payable(listing.seller).call{value: sellerProceeds}("");
        require(sellerSuccess, "Seller payment failed");

        // TRANSFER NFT
        // Transfer NFT from seller to buyer
        IERC721(listing.nftContract).safeTransferFrom(
            listing.seller,
            msg.sender,
            listing.tokenId
        );

        emit Purchased(listingId, msg.sender, listing.price, royaltyAmount);
    }

    /**
     * @notice Delist an NFT
     * @param listingId ID of the listing to cancel
     */
    function delist(uint256 listingId) external {
        Listing storage listing = listings[listingId];

        require(listing.seller == msg.sender, "Not seller");
        require(listing.active, "Listing not active");

        listing.active = false;

        emit Delisted(listingId);
    }

    /**
     * @notice Preview royalty for a listing
     * @param listingId ID of the listing
     * @return receiver Address that will receive royalty
     * @return royaltyAmount Amount of royalty in wei
     * @return sellerProceeds Amount seller will receive in wei
     */
    function previewRoyalty(uint256 listingId)
        external
        view
        returns (address receiver, uint256 royaltyAmount, uint256 sellerProceeds)
    {
        Listing memory listing = listings[listingId];
        require(listing.active, "Listing not active");

        // Check royalty support
        bool supportsRoyalties = IERC165(listing.nftContract).supportsInterface(0x2a55205a);

        if (supportsRoyalties) {
            (receiver, royaltyAmount) =
                IERC2981(listing.nftContract).royaltyInfo(listing.tokenId, listing.price);
        }

        sellerProceeds = listing.price - royaltyAmount;
    }

    /**
     * @notice Check if an NFT contract supports ERC-2981
     * @param nftContract Address of NFT contract to check
     * @return bool True if contract supports ERC-2981
     */
    function supportsRoyalties(address nftContract) external view returns (bool) {
        return IERC165(nftContract).supportsInterface(0x2a55205a);
    }
}

/*
EXAMPLE USAGE FLOW:
===================

1. SELLER LISTS NFT:
   ```
   // Approve marketplace
   nft.setApprovalForAll(marketplace, true);

   // List NFT for 10 ETH
   uint256 listingId = marketplace.list(nftAddress, tokenId, 10 ether);
   ```

2. BUYER PREVIEWS ROYALTY:
   ```
   (address receiver, uint256 royalty, uint256 sellerAmount) =
       marketplace.previewRoyalty(listingId);

   // Output:
   // receiver: 0x123... (creator)
   // royalty: 0.5 ether (5%)
   // sellerAmount: 9.5 ether
   ```

3. BUYER PURCHASES:
   ```
   // Send 10 ETH to purchase
   marketplace.purchase{value: 10 ether}(listingId);

   // Payments:
   // - Creator receives: 0.5 ETH (royalty)
   // - Seller receives: 9.5 ETH
   // - Buyer receives: NFT
   ```

PAYMENT BREAKDOWN EXAMPLES:
============================

Example 1: NFT with 5% royalty sold for 10 ETH
- Sale price: 10 ETH
- Royalty (5%): 0.5 ETH → Creator
- Seller proceeds: 9.5 ETH → Seller
- NFT → Buyer

Example 2: NFT with 10% royalty sold for 2 ETH
- Sale price: 2 ETH
- Royalty (10%): 0.2 ETH → Creator
- Seller proceeds: 1.8 ETH → Seller
- NFT → Buyer

Example 3: NFT without royalty sold for 5 ETH
- Sale price: 5 ETH
- Royalty: 0 ETH (no ERC-2981 support)
- Seller proceeds: 5 ETH → Seller
- NFT → Buyer

INTEGRATION CHECKLIST FOR MARKETPLACES:
========================================

✓ Check ERC-2981 support via ERC165 (interface ID: 0x2a55205a)
✓ Call royaltyInfo(tokenId, salePrice) before executing sale
✓ Validate royalty amount doesn't exceed sale price
✓ Pay royalty to receiver before or during sale
✓ Calculate and pay seller proceeds (price - royalty)
✓ Handle NFTs without royalty support gracefully
✓ Emit events showing royalty payments
✓ Display royalty info to buyers before purchase
✓ Support both ETH and ERC20 payment tokens
✓ Handle edge cases (zero royalty, zero receiver, etc.)

SECURITY CONSIDERATIONS:
=========================

1. REENTRANCY:
   - Mark listing inactive before external calls
   - Use checks-effects-interactions pattern
   - Consider ReentrancyGuard

2. PAYMENT VALIDATION:
   - Ensure royalty doesn't exceed sale price
   - Check receiver address is not zero
   - Handle failed transfers gracefully

3. NFT VALIDATION:
   - Verify seller still owns NFT
   - Confirm marketplace approval
   - Check token exists

4. ROYALTY LIMITS:
   - Many marketplaces cap royalties (e.g., 10%)
   - Reject excessive royalty amounts
   - Document maximum royalty policy

ADVANCED FEATURES:
==================

Real marketplaces often add:

1. MARKETPLACE FEES:
   - Take 2-3% fee in addition to royalties
   - Reduce from seller proceeds

2. OFFERS AND BIDDING:
   - Support offers below listing price
   - Calculate royalty on accepted offer price

3. MULTIPLE PAYMENT TOKENS:
   - Support WETH, USDC, etc.
   - Calculate royalty in token amounts

4. BATCH OPERATIONS:
   - Buy multiple NFTs in one transaction
   - Aggregate royalty payments

5. LAZY ROYALTY CLAIMS:
   - Accumulate royalties
   - Allow creators to claim in batch

TESTING THE MARKETPLACE:
=========================

See test/Project28.t.sol for examples of testing
marketplace integration with ERC-2981 NFTs.

Key test scenarios:
- Purchase with royalty
- Purchase without royalty
- Royalty calculation accuracy
- Payment distribution
- Edge cases
*/
