// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/ERC721NFTSolution.sol";

contract ERC721NFTTest is Test {
    ERC721NFTSolution public nft;
    address public user1;
    address public user2;
    
    function setUp() public {
        nft = new ERC721NFTSolution("Test NFT", "TNFT");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
    }
    
    function test_Mint_CreatesToken() public {
        uint256 tokenId = nft.mint(user1, "ipfs://test");
        
        assertEq(nft.ownerOf(tokenId), user1);
        assertEq(nft.balanceOf(user1), 1);
        assertEq(nft.tokenURI(tokenId), "ipfs://test");
    }
    
    function test_Transfer_ChangesOwnership() public {
        uint256 tokenId = nft.mint(user1, "ipfs://test");
        
        vm.prank(user1);
        nft.transferFrom(user1, user2, tokenId);
        
        assertEq(nft.ownerOf(tokenId), user2);
        assertEq(nft.balanceOf(user1), 0);
        assertEq(nft.balanceOf(user2), 1);
    }
    
    function test_Approve_GrantsPermission() public {
        uint256 tokenId = nft.mint(user1, "ipfs://test");
        
        vm.prank(user1);
        nft.approve(user2, tokenId);
        
        assertEq(nft.getApproved(tokenId), user2);
    }
    
    function test_TransferFrom_WorksWithApproval() public {
        uint256 tokenId = nft.mint(user1, "ipfs://test");
        
        vm.prank(user1);
        nft.approve(user2, tokenId);
        
        vm.prank(user2);
        nft.transferFrom(user1, address(this), tokenId);
        
        assertEq(nft.ownerOf(tokenId), address(this));
    }
}
