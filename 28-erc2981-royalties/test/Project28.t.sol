// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Project28.sol";
import "../src/solution/Project28Solution.sol";

/**
 * @title Project28Test
 * @notice Comprehensive tests for ERC-2981 royalty implementation
 */
contract Project28Test is Test {
    Project28Solution public nft;

    address public owner = address(this);
    address public royaltyReceiver = makeAddr("royaltyReceiver");
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");

    uint96 public constant DEFAULT_ROYALTY_FEE = 500; // 5%
    uint96 public constant MAX_ROYALTY_FEE = 1000; // 10%

    // ERC2981 interface ID
    bytes4 public constant INTERFACE_ID_ERC2981 = 0x2a55205a;

    // Events to test
    event DefaultRoyaltySet(address indexed receiver, uint96 feeNumerator);
    event TokenRoyaltySet(uint256 indexed tokenId, address indexed receiver, uint96 feeNumerator);
    event TokenRoyaltyReset(uint256 indexed tokenId);

    function setUp() public {
        nft = new Project28Solution("RoyaltyNFT", "RNFT", royaltyReceiver, DEFAULT_ROYALTY_FEE);
    }

    /*//////////////////////////////////////////////////////////////
                          CONSTRUCTOR TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Constructor() public {
        // Verify NFT metadata
        assertEq(nft.name(), "RoyaltyNFT");
        assertEq(nft.symbol(), "RNFT");
        assertEq(nft.owner(), owner);

        // Verify default royalty is set
        (address receiver, uint256 amount) = nft.royaltyInfo(0, 10 ether);
        assertEq(receiver, royaltyReceiver);
        assertEq(amount, 0.5 ether); // 5% of 10 ETH
    }

    function test_Constructor_InvalidRoyaltyFee() public {
        vm.expectRevert("Royalty fee too high");
        new Project28Solution("Test", "TEST", royaltyReceiver, MAX_ROYALTY_FEE + 1);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERFACE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SupportsInterface_ERC2981() public {
        assertTrue(nft.supportsInterface(INTERFACE_ID_ERC2981));
    }

    function test_SupportsInterface_ERC721() public {
        // ERC721 interface ID
        assertTrue(nft.supportsInterface(0x80ac58cd));
    }

    function test_SupportsInterface_ERC165() public {
        // ERC165 interface ID
        assertTrue(nft.supportsInterface(0x01ffc9a7));
    }

    function test_SupportsInterface_Invalid() public {
        assertFalse(nft.supportsInterface(0xffffffff));
    }

    /*//////////////////////////////////////////////////////////////
                          MINTING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Mint() public {
        uint256 tokenId = nft.mint(user1);

        assertEq(tokenId, 0);
        assertEq(nft.ownerOf(tokenId), user1);
        assertEq(nft.totalSupply(), 1);
    }

    function test_Mint_Multiple() public {
        uint256 tokenId1 = nft.mint(user1);
        uint256 tokenId2 = nft.mint(user2);
        uint256 tokenId3 = nft.mint(user1);

        assertEq(tokenId1, 0);
        assertEq(tokenId2, 1);
        assertEq(tokenId3, 2);
        assertEq(nft.totalSupply(), 3);
    }

    function test_Mint_InheritsDefaultRoyalty() public {
        uint256 tokenId = nft.mint(user1);

        (address receiver, uint256 amount) = nft.royaltyInfo(tokenId, 10 ether);
        assertEq(receiver, royaltyReceiver);
        assertEq(amount, 0.5 ether); // 5% of 10 ETH
    }

    /*//////////////////////////////////////////////////////////////
                      GLOBAL ROYALTY TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RoyaltyInfo_DefaultRoyalty() public {
        uint256 tokenId = nft.mint(user1);

        // Test various sale prices
        (address receiver, uint256 amount) = nft.royaltyInfo(tokenId, 1 ether);
        assertEq(receiver, royaltyReceiver);
        assertEq(amount, 0.05 ether); // 5% of 1 ETH

        (receiver, amount) = nft.royaltyInfo(tokenId, 100 ether);
        assertEq(receiver, royaltyReceiver);
        assertEq(amount, 5 ether); // 5% of 100 ETH
    }

    function test_RoyaltyInfo_ZeroSalePrice() public {
        uint256 tokenId = nft.mint(user1);

        (address receiver, uint256 amount) = nft.royaltyInfo(tokenId, 0);
        assertEq(receiver, royaltyReceiver);
        assertEq(amount, 0);
    }

    function test_SetDefaultRoyalty() public {
        address newReceiver = makeAddr("newReceiver");
        uint96 newFee = 750; // 7.5%

        vm.expectEmit(true, false, false, true);
        emit DefaultRoyaltySet(newReceiver, newFee);

        nft.setDefaultRoyalty(newReceiver, newFee);

        // Verify new default applies to new tokens
        uint256 tokenId = nft.mint(user1);
        (address receiver, uint256 amount) = nft.royaltyInfo(tokenId, 10 ether);
        assertEq(receiver, newReceiver);
        assertEq(amount, 0.75 ether); // 7.5% of 10 ETH
    }

    function test_SetDefaultRoyalty_OnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        nft.setDefaultRoyalty(user1, 500);
    }

    function test_SetDefaultRoyalty_InvalidReceiver() public {
        vm.expectRevert("Invalid receiver");
        nft.setDefaultRoyalty(address(0), 500);
    }

    function test_SetDefaultRoyalty_FeeTooHigh() public {
        vm.expectRevert("Royalty fee too high");
        nft.setDefaultRoyalty(royaltyReceiver, MAX_ROYALTY_FEE + 1);
    }

    function test_DeleteDefaultRoyalty() public {
        nft.deleteDefaultRoyalty();

        uint256 tokenId = nft.mint(user1);
        (address receiver, uint256 amount) = nft.royaltyInfo(tokenId, 10 ether);

        // Should return zero address and zero amount
        assertEq(receiver, address(0));
        assertEq(amount, 0);
    }

    /*//////////////////////////////////////////////////////////////
                      PER-TOKEN ROYALTY TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SetTokenRoyalty() public {
        uint256 tokenId = nft.mint(user1);

        address tokenReceiver = makeAddr("tokenReceiver");
        uint96 tokenFee = 1000; // 10%

        vm.expectEmit(true, true, false, true);
        emit TokenRoyaltySet(tokenId, tokenReceiver, tokenFee);

        nft.setTokenRoyalty(tokenId, tokenReceiver, tokenFee);

        (address receiver, uint256 amount) = nft.royaltyInfo(tokenId, 10 ether);
        assertEq(receiver, tokenReceiver);
        assertEq(amount, 1 ether); // 10% of 10 ETH
    }

    function test_SetTokenRoyalty_OverridesDefault() public {
        // Mint two tokens
        uint256 tokenId1 = nft.mint(user1);
        uint256 tokenId2 = nft.mint(user2);

        // Set custom royalty for token 1
        address customReceiver = makeAddr("customReceiver");
        nft.setTokenRoyalty(tokenId1, customReceiver, 250); // 2.5%

        // Token 1 should use custom royalty
        (address receiver1, uint256 amount1) = nft.royaltyInfo(tokenId1, 10 ether);
        assertEq(receiver1, customReceiver);
        assertEq(amount1, 0.25 ether); // 2.5% of 10 ETH

        // Token 2 should use default royalty
        (address receiver2, uint256 amount2) = nft.royaltyInfo(tokenId2, 10 ether);
        assertEq(receiver2, royaltyReceiver);
        assertEq(amount2, 0.5 ether); // 5% of 10 ETH
    }

    function test_SetTokenRoyalty_OnlyOwner() public {
        uint256 tokenId = nft.mint(user1);

        vm.prank(user1);
        vm.expectRevert();
        nft.setTokenRoyalty(tokenId, user1, 500);
    }

    function test_SetTokenRoyalty_InvalidReceiver() public {
        uint256 tokenId = nft.mint(user1);

        vm.expectRevert("Invalid receiver");
        nft.setTokenRoyalty(tokenId, address(0), 500);
    }

    function test_SetTokenRoyalty_FeeTooHigh() public {
        uint256 tokenId = nft.mint(user1);

        vm.expectRevert("Royalty fee too high");
        nft.setTokenRoyalty(tokenId, royaltyReceiver, MAX_ROYALTY_FEE + 1);
    }

    function test_ResetTokenRoyalty() public {
        uint256 tokenId = nft.mint(user1);

        // Set custom royalty
        address customReceiver = makeAddr("customReceiver");
        nft.setTokenRoyalty(tokenId, customReceiver, 1000);

        // Verify custom royalty is set
        (address receiver, uint256 amount) = nft.royaltyInfo(tokenId, 10 ether);
        assertEq(receiver, customReceiver);
        assertEq(amount, 1 ether);

        // Reset to default
        vm.expectEmit(true, false, false, false);
        emit TokenRoyaltyReset(tokenId);

        nft.resetTokenRoyalty(tokenId);

        // Should use default royalty again
        (receiver, amount) = nft.royaltyInfo(tokenId, 10 ether);
        assertEq(receiver, royaltyReceiver);
        assertEq(amount, 0.5 ether); // Back to 5%
    }

    function test_ResetTokenRoyalty_OnlyOwner() public {
        uint256 tokenId = nft.mint(user1);

        vm.prank(user1);
        vm.expectRevert();
        nft.resetTokenRoyalty(tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                      ROYALTY CALCULATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RoyaltyCalculation_1Percent() public {
        nft.setDefaultRoyalty(royaltyReceiver, 100); // 1%
        uint256 tokenId = nft.mint(user1);

        (,uint256 amount) = nft.royaltyInfo(tokenId, 10 ether);
        assertEq(amount, 0.1 ether);
    }

    function test_RoyaltyCalculation_2Point5Percent() public {
        nft.setDefaultRoyalty(royaltyReceiver, 250); // 2.5%
        uint256 tokenId = nft.mint(user1);

        (,uint256 amount) = nft.royaltyInfo(tokenId, 10 ether);
        assertEq(amount, 0.25 ether);
    }

    function test_RoyaltyCalculation_5Percent() public {
        nft.setDefaultRoyalty(royaltyReceiver, 500); // 5%
        uint256 tokenId = nft.mint(user1);

        (,uint256 amount) = nft.royaltyInfo(tokenId, 10 ether);
        assertEq(amount, 0.5 ether);
    }

    function test_RoyaltyCalculation_10Percent() public {
        nft.setDefaultRoyalty(royaltyReceiver, 1000); // 10%
        uint256 tokenId = nft.mint(user1);

        (,uint256 amount) = nft.royaltyInfo(tokenId, 10 ether);
        assertEq(amount, 1 ether);
    }

    function test_RoyaltyCalculation_LargeSalePrice() public {
        uint256 tokenId = nft.mint(user1);

        (,uint256 amount) = nft.royaltyInfo(tokenId, 1000 ether);
        assertEq(amount, 50 ether); // 5% of 1000 ETH
    }

    function test_RoyaltyCalculation_SmallSalePrice() public {
        uint256 tokenId = nft.mint(user1);

        (,uint256 amount) = nft.royaltyInfo(tokenId, 0.001 ether);
        assertEq(amount, 0.00005 ether); // 5% of 0.001 ETH
    }

    function test_RoyaltyCalculation_Rounding() public {
        uint256 tokenId = nft.mint(user1);

        // Test rounding down (Solidity default)
        (,uint256 amount) = nft.royaltyInfo(tokenId, 1.999 ether);
        // Expected: (1.999 * 500) / 10000 = 0.09995 ETH
        assertEq(amount, 99950000000000000); // 0.09995 ETH
    }

    /*//////////////////////////////////////////////////////////////
                      MARKETPLACE INTEGRATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_MarketplaceIntegration_BasicSale() public {
        // Setup: Mint NFT and set up sale
        uint256 tokenId = nft.mint(user1);
        uint256 salePrice = 10 ether;

        // Marketplace checks royalty support
        bool supportsRoyalties = nft.supportsInterface(INTERFACE_ID_ERC2981);
        assertTrue(supportsRoyalties);

        // Marketplace gets royalty info
        (address receiver, uint256 royaltyAmount) = nft.royaltyInfo(tokenId, salePrice);

        // Verify correct royalty calculation
        assertEq(receiver, royaltyReceiver);
        assertEq(royaltyAmount, 0.5 ether); // 5% of 10 ETH

        // Calculate seller proceeds
        uint256 sellerProceeds = salePrice - royaltyAmount;
        assertEq(sellerProceeds, 9.5 ether);
    }

    function test_MarketplaceIntegration_MultipleTokens() public {
        // Mint tokens with different royalty settings
        uint256 tokenId1 = nft.mint(user1);
        uint256 tokenId2 = nft.mint(user2);

        address specialReceiver = makeAddr("specialReceiver");
        nft.setTokenRoyalty(tokenId2, specialReceiver, 1000); // 10%

        uint256 salePrice = 5 ether;

        // Token 1 uses default royalty
        (address receiver1, uint256 amount1) = nft.royaltyInfo(tokenId1, salePrice);
        assertEq(receiver1, royaltyReceiver);
        assertEq(amount1, 0.25 ether); // 5%

        // Token 2 uses custom royalty
        (address receiver2, uint256 amount2) = nft.royaltyInfo(tokenId2, salePrice);
        assertEq(receiver2, specialReceiver);
        assertEq(amount2, 0.5 ether); // 10%
    }

    function test_MarketplaceIntegration_NoRoyalty() public {
        // Delete default royalty
        nft.deleteDefaultRoyalty();

        uint256 tokenId = nft.mint(user1);
        uint256 salePrice = 10 ether;

        (address receiver, uint256 royaltyAmount) = nft.royaltyInfo(tokenId, salePrice);

        // No royalty should be returned
        assertEq(receiver, address(0));
        assertEq(royaltyAmount, 0);

        // Seller gets full amount
        assertEq(salePrice - royaltyAmount, 10 ether);
    }

    /*//////////////////////////////////////////////////////////////
                          FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzz_RoyaltyCalculation(uint256 salePrice, uint96 feeNumerator) public {
        // Bound fee to valid range
        feeNumerator = uint96(bound(feeNumerator, 0, MAX_ROYALTY_FEE));

        // Bound sale price to reasonable range (avoid overflow)
        salePrice = bound(salePrice, 0, type(uint128).max);

        nft.setDefaultRoyalty(royaltyReceiver, feeNumerator);
        uint256 tokenId = nft.mint(user1);

        (address receiver, uint256 royaltyAmount) = nft.royaltyInfo(tokenId, salePrice);

        // Verify receiver is correct
        assertEq(receiver, royaltyReceiver);

        // Verify calculation is correct
        uint256 expectedAmount = (salePrice * feeNumerator) / 10000;
        assertEq(royaltyAmount, expectedAmount);

        // Verify royalty doesn't exceed sale price
        assertLe(royaltyAmount, salePrice);
    }

    function testFuzz_SetTokenRoyalty(address receiver, uint96 feeNumerator) public {
        // Skip zero address
        vm.assume(receiver != address(0));

        // Bound fee to valid range
        feeNumerator = uint96(bound(feeNumerator, 0, MAX_ROYALTY_FEE));

        uint256 tokenId = nft.mint(user1);

        nft.setTokenRoyalty(tokenId, receiver, feeNumerator);

        (address returnedReceiver, uint256 amount) = nft.royaltyInfo(tokenId, 10 ether);

        assertEq(returnedReceiver, receiver);
        assertEq(amount, (10 ether * feeNumerator) / 10000);
    }

    /*//////////////////////////////////////////////////////////////
                          EDGE CASE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_EdgeCase_MaxUint256SalePrice() public {
        // Set low royalty to avoid overflow
        nft.setDefaultRoyalty(royaltyReceiver, 1); // 0.01%
        uint256 tokenId = nft.mint(user1);

        // Should not revert with max sale price
        (address receiver, uint256 amount) = nft.royaltyInfo(tokenId, type(uint256).max);

        assertEq(receiver, royaltyReceiver);
        // Calculation should work without overflow
        assertGt(amount, 0);
    }

    function test_EdgeCase_ZeroRoyaltyFee() public {
        nft.setDefaultRoyalty(royaltyReceiver, 0);
        uint256 tokenId = nft.mint(user1);

        (address receiver, uint256 amount) = nft.royaltyInfo(tokenId, 10 ether);

        assertEq(receiver, royaltyReceiver);
        assertEq(amount, 0);
    }

    function test_EdgeCase_MaxRoyaltyFee() public {
        nft.setDefaultRoyalty(royaltyReceiver, MAX_ROYALTY_FEE);
        uint256 tokenId = nft.mint(user1);

        (address receiver, uint256 amount) = nft.royaltyInfo(tokenId, 10 ether);

        assertEq(receiver, royaltyReceiver);
        assertEq(amount, 1 ether); // 10% of 10 ETH
    }

    function test_EdgeCase_UpdateRoyaltyMultipleTimes() public {
        uint256 tokenId = nft.mint(user1);

        // Update royalty multiple times
        address receiver1 = makeAddr("receiver1");
        address receiver2 = makeAddr("receiver2");
        address receiver3 = makeAddr("receiver3");

        nft.setTokenRoyalty(tokenId, receiver1, 100);
        nft.setTokenRoyalty(tokenId, receiver2, 500);
        nft.setTokenRoyalty(tokenId, receiver3, 1000);

        // Should use the last set royalty
        (address receiver, uint256 amount) = nft.royaltyInfo(tokenId, 10 ether);
        assertEq(receiver, receiver3);
        assertEq(amount, 1 ether);
    }

    function test_EdgeCase_ResetNonExistentTokenRoyalty() public {
        uint256 tokenId = nft.mint(user1);

        // Reset without setting custom royalty first
        nft.resetTokenRoyalty(tokenId);

        // Should still use default royalty
        (address receiver, uint256 amount) = nft.royaltyInfo(tokenId, 10 ether);
        assertEq(receiver, royaltyReceiver);
        assertEq(amount, 0.5 ether);
    }

    /*//////////////////////////////////////////////////////////////
                      INTEGRATION SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Scenario_CollaborativeCollection() public {
        // Scenario: NFT collection with multiple artists
        // Each artist gets royalties for their tokens

        address artist1 = makeAddr("artist1");
        address artist2 = makeAddr("artist2");
        address artist3 = makeAddr("artist3");

        // Mint tokens for different artists
        uint256 token1 = nft.mint(user1); // Artist 1's work
        uint256 token2 = nft.mint(user1); // Artist 2's work
        uint256 token3 = nft.mint(user2); // Artist 3's work

        // Set per-token royalties for each artist
        nft.setTokenRoyalty(token1, artist1, 500); // 5%
        nft.setTokenRoyalty(token2, artist2, 750); // 7.5%
        nft.setTokenRoyalty(token3, artist3, 1000); // 10%

        // Verify each token has correct royalty
        uint256 salePrice = 10 ether;

        (address receiver1, uint256 amount1) = nft.royaltyInfo(token1, salePrice);
        assertEq(receiver1, artist1);
        assertEq(amount1, 0.5 ether);

        (address receiver2, uint256 amount2) = nft.royaltyInfo(token2, salePrice);
        assertEq(receiver2, artist2);
        assertEq(amount2, 0.75 ether);

        (address receiver3, uint256 amount3) = nft.royaltyInfo(token3, salePrice);
        assertEq(receiver3, artist3);
        assertEq(amount3, 1 ether);
    }

    function test_Scenario_RoyaltyRateChange() public {
        // Scenario: Project starts with 5% royalty, later increases to 7.5%

        uint256 token1 = nft.mint(user1);
        uint256 token2 = nft.mint(user2);

        // Initial royalty: 5%
        (,uint256 amount1) = nft.royaltyInfo(token1, 10 ether);
        assertEq(amount1, 0.5 ether);

        // Change default royalty
        address newReceiver = makeAddr("newReceiver");
        nft.setDefaultRoyalty(newReceiver, 750); // 7.5%

        // Old tokens still use old royalty (unless reset)
        (,uint256 amount2) = nft.royaltyInfo(token1, 10 ether);
        assertEq(amount2, 0.5 ether); // Still 5%

        // New tokens use new royalty
        uint256 token3 = nft.mint(user1);
        (address receiver3, uint256 amount3) = nft.royaltyInfo(token3, 10 ether);
        assertEq(receiver3, newReceiver);
        assertEq(amount3, 0.75 ether); // 7.5%
    }
}
