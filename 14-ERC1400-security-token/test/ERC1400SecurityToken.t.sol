// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/ERC1400SecurityTokenSolution.sol";

contract ERC1400SecurityTokenTest is Test {
    ERC1400SecurityTokenSolution public token;
    address public owner;
    address public investor1;
    address public investor2;
    
    bytes32 constant COMMON = bytes32("Common");
    bytes32 constant PREFERRED = bytes32("Preferred");
    
    function setUp() public {
        owner = address(this);
        investor1 = makeAddr("investor1");
        investor2 = makeAddr("investor2");
        
        token = new ERC1400SecurityTokenSolution("Security Token", "SEC");
        
        // Whitelist investors
        token.addToWhitelist(investor1, "US");
        token.addToWhitelist(investor2, "US");
    }
    
    function test_IssueByPartition_Works() public {
        token.issueByPartition(COMMON, investor1, 1000e18, "");
        assertEq(token.balanceOfByPartition(COMMON, investor1), 1000e18);
    }
    
    function test_TransferByPartition_Works() public {
        token.issueByPartition(COMMON, investor1, 1000e18, "");
        
        vm.prank(investor1);
        token.transferByPartition(COMMON, investor2, 500e18, "");
        
        assertEq(token.balanceOfByPartition(COMMON, investor1), 500e18);
        assertEq(token.balanceOfByPartition(COMMON, investor2), 500e18);
    }
    
    function test_TransferToNonWhitelisted_Reverts() public {
        address nonWhitelisted = makeAddr("nonWhitelisted");
        token.issueByPartition(COMMON, investor1, 1000e18, "");
        
        vm.prank(investor1);
        vm.expectRevert();
        token.transferByPartition(COMMON, nonWhitelisted, 500e18, "");
    }
    
    function test_SetDocument_Works() public {
        token.setDocument(
            bytes32("Prospectus"),
            "ipfs://QmProspectus...",
            keccak256("prospectus")
        );
        
        (string memory uri, bytes32 hash, uint256 timestamp) = token.getDocument(bytes32("Prospectus"));
        assertEq(uri, "ipfs://QmProspectus...");
        assertTrue(timestamp > 0);
    }
}
