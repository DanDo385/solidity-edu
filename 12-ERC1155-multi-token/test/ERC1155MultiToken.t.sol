// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/ERC1155MultiTokenSolution.sol";

contract ERC1155MultiTokenTest is Test {
    ERC1155MultiTokenSolution public token;
    address public alice;
    address public bob;
    
    function setUp() public {
        token = new ERC1155MultiTokenSolution("GameAssets", "GAME", "https://api.game.com/");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
    }
    
    function test_Mint_IncreasesBalance() public {
        token.mint(alice, 1, 100, "");
        assertEq(token.balanceOf(alice, 1), 100);
    }
    
    function test_MintBatch_IncreasesBalances() public {
        uint256[] memory ids = new uint256[](3);
        ids[0] = 1;
        ids[1] = 2;
        ids[2] = 3;
        
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 100;
        amounts[1] = 50;
        amounts[2] = 1;
        
        token.mintBatch(alice, ids, amounts, "");
        
        assertEq(token.balanceOf(alice, 1), 100);
        assertEq(token.balanceOf(alice, 2), 50);
        assertEq(token.balanceOf(alice, 3), 1);
    }
    
    function test_SafeTransferFrom_Works() public {
        token.mint(alice, 1, 100, "");
        
        vm.prank(alice);
        token.safeTransferFrom(alice, bob, 1, 50, "");
        
        assertEq(token.balanceOf(alice, 1), 50);
        assertEq(token.balanceOf(bob, 1), 50);
    }
    
    function test_SafeBatchTransferFrom_Works() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 50;
        
        token.mintBatch(alice, ids, amounts, "");
        
        uint256[] memory transferAmounts = new uint256[](2);
        transferAmounts[0] = 50;
        transferAmounts[1] = 25;
        
        vm.prank(alice);
        token.safeBatchTransferFrom(alice, bob, ids, transferAmounts, "");
        
        assertEq(token.balanceOf(alice, 1), 50);
        assertEq(token.balanceOf(bob, 1), 50);
        assertEq(token.balanceOf(alice, 2), 25);
        assertEq(token.balanceOf(bob, 2), 25);
    }
    
    function test_SetApprovalForAll_Works() public {
        vm.prank(alice);
        token.setApprovalForAll(bob, true);
        
        assertTrue(token.isApprovedForAll(alice, bob));
    }
    
    function test_BalanceOfBatch_Works() public {
        token.mint(alice, 1, 100, "");
        token.mint(bob, 1, 50, "");
        
        address[] memory accounts = new address[](2);
        accounts[0] = alice;
        accounts[1] = bob;
        
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 1;
        
        uint256[] memory balances = token.balanceOfBatch(accounts, ids);
        
        assertEq(balances[0], 100);
        assertEq(balances[1], 50);
    }
}
