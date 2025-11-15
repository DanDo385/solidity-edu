// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/Project29Solution.sol";

/**
 * @title Project29Test
 * @notice Comprehensive tests for Merkle proof allowlist functionality
 * @dev Tests cover:
 * - Valid proof verification
 * - Invalid proof rejection
 * - Forged proof attempts
 * - Double claiming prevention
 * - Gas comparisons
 * - Large allowlist scenarios
 */
contract Project29Test is Test {
    Project29Solution public nft;

    // Test addresses
    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    address public user3 = address(4);
    address public notAllowlisted = address(5);

    // Merkle tree data
    // Tree structure for 3 addresses:
    //           root
    //          /    \
    //       h12      h3
    //       / \       |
    //     h1   h2    h3
    //     |    |     |
    //   user1 user2 user3

    bytes32 public merkleRoot;
    mapping(address => bytes32[]) public proofs;

    function setUp() public {
        vm.startPrank(owner);

        // Build a simple Merkle tree manually for testing
        // In production, use a library like merkletreejs or murky
        bytes32 leaf1 = keccak256(abi.encodePacked(user1));
        bytes32 leaf2 = keccak256(abi.encodePacked(user2));
        bytes32 leaf3 = keccak256(abi.encodePacked(user3));

        // Build tree bottom-up
        bytes32 hash12;
        if (leaf1 < leaf2) {
            hash12 = keccak256(abi.encodePacked(leaf1, leaf2));
        } else {
            hash12 = keccak256(abi.encodePacked(leaf2, leaf1));
        }

        // Root is hash of hash12 and leaf3
        if (hash12 < leaf3) {
            merkleRoot = keccak256(abi.encodePacked(hash12, leaf3));
        } else {
            merkleRoot = keccak256(abi.encodePacked(leaf3, hash12));
        }

        // Generate proofs for each user
        // Proof for user1: [leaf2, leaf3]
        proofs[user1] = new bytes32[](2);
        proofs[user1][0] = leaf2;
        proofs[user1][1] = leaf3;

        // Proof for user2: [leaf1, leaf3]
        proofs[user2] = new bytes32[](2);
        proofs[user2][0] = leaf1;
        proofs[user2][1] = leaf3;

        // Proof for user3: [hash12]
        proofs[user3] = new bytes32[](1);
        proofs[user3][0] = hash12;

        // Deploy contract with Merkle root
        nft = new Project29Solution(merkleRoot);

        vm.stopPrank();
    }

    // ============ Basic Functionality Tests ============

    function test_Deployment() public view {
        assertEq(nft.merkleRoot(), merkleRoot);
        assertEq(nft.owner(), owner);
        assertEq(nft.name(), "MerkleNFT");
        assertEq(nft.symbol(), "MNFT");
        assertEq(nft.getCurrentTokenId(), 0);
        assertFalse(nft.publicMintEnabled());
    }

    function test_ValidProofVerification() public view {
        // All three users should verify successfully
        assertTrue(nft.verifyAllowlist(user1, proofs[user1]));
        assertTrue(nft.verifyAllowlist(user2, proofs[user2]));
        assertTrue(nft.verifyAllowlist(user3, proofs[user3]));
    }

    function test_InvalidProofRejection() public view {
        // User not on allowlist with empty proof
        bytes32[] memory emptyProof = new bytes32[](0);
        assertFalse(nft.verifyAllowlist(notAllowlisted, emptyProof));

        // User not on allowlist with wrong proof
        assertFalse(nft.verifyAllowlist(notAllowlisted, proofs[user1]));
    }

    function test_AllowlistMint() public {
        vm.startPrank(user1);

        // User1 should be able to mint
        nft.allowlistMint(proofs[user1]);

        // Check NFT was minted
        assertEq(nft.ownerOf(0), user1);
        assertEq(nft.totalSupply(), 1);
        assertTrue(nft.hasClaimed(user1));

        vm.stopPrank();
    }

    function test_AllowlistMintEmitsEvent() public {
        vm.startPrank(user1);

        // Expect event
        vm.expectEmit(true, true, false, true);
        emit Project29Solution.AllowlistMinted(user1, 0);

        nft.allowlistMint(proofs[user1]);

        vm.stopPrank();
    }

    function test_MultipleUsersMint() public {
        // User1 mints
        vm.prank(user1);
        nft.allowlistMint(proofs[user1]);
        assertEq(nft.ownerOf(0), user1);

        // User2 mints
        vm.prank(user2);
        nft.allowlistMint(proofs[user2]);
        assertEq(nft.ownerOf(1), user2);

        // User3 mints
        vm.prank(user3);
        nft.allowlistMint(proofs[user3]);
        assertEq(nft.ownerOf(2), user3);

        assertEq(nft.totalSupply(), 3);
    }

    function test_RevertDoubleClaim() public {
        vm.startPrank(user1);

        // First mint succeeds
        nft.allowlistMint(proofs[user1]);

        // Second mint should revert
        vm.expectRevert(Project29Solution.AlreadyClaimed.selector);
        nft.allowlistMint(proofs[user1]);

        vm.stopPrank();
    }

    function test_RevertInvalidProof() public {
        vm.startPrank(notAllowlisted);

        bytes32[] memory invalidProof = new bytes32[](1);
        invalidProof[0] = bytes32(uint256(123)); // Random invalid proof

        vm.expectRevert(Project29Solution.InvalidProof.selector);
        nft.allowlistMint(invalidProof);

        vm.stopPrank();
    }

    function test_RevertEmptyProof() public {
        vm.startPrank(user1);

        bytes32[] memory emptyProof = new bytes32[](0);

        vm.expectRevert(Project29Solution.InvalidProof.selector);
        nft.allowlistMint(emptyProof);

        vm.stopPrank();
    }

    function test_RevertWrongUserWithValidProof() public {
        vm.startPrank(notAllowlisted);

        // Using user1's proof but from different address
        vm.expectRevert(Project29Solution.InvalidProof.selector);
        nft.allowlistMint(proofs[user1]);

        vm.stopPrank();
    }

    // ============ Public Mint Tests ============

    function test_PublicMint() public {
        vm.prank(owner);
        nft.setPublicMintEnabled(true);

        vm.deal(notAllowlisted, 1 ether);
        vm.prank(notAllowlisted);
        nft.publicMint{value: 0.01 ether}();

        assertEq(nft.ownerOf(0), notAllowlisted);
        assertEq(nft.totalSupply(), 1);
    }

    function test_PublicMintEmitsEvent() public {
        vm.prank(owner);
        nft.setPublicMintEnabled(true);

        vm.deal(notAllowlisted, 1 ether);
        vm.prank(notAllowlisted);

        vm.expectEmit(true, true, false, true);
        emit Project29Solution.PublicMinted(notAllowlisted, 0);

        nft.publicMint{value: 0.01 ether}();
    }

    function test_RevertPublicMintNotEnabled() public {
        vm.deal(notAllowlisted, 1 ether);
        vm.prank(notAllowlisted);

        vm.expectRevert(Project29Solution.PublicMintNotEnabled.selector);
        nft.publicMint{value: 0.01 ether}();
    }

    function test_RevertPublicMintIncorrectPayment() public {
        vm.prank(owner);
        nft.setPublicMintEnabled(true);

        vm.deal(notAllowlisted, 1 ether);
        vm.prank(notAllowlisted);

        // Too little
        vm.expectRevert(Project29Solution.IncorrectPayment.selector);
        nft.publicMint{value: 0.001 ether}();

        // Too much
        vm.expectRevert(Project29Solution.IncorrectPayment.selector);
        nft.publicMint{value: 0.1 ether}();
    }

    function test_RevertMaxSupplyReached() public {
        vm.prank(owner);
        nft.setPublicMintEnabled(true);

        // Mint 1000 NFTs (max supply)
        for (uint256 i = 0; i < 1000; i++) {
            address minter = address(uint160(1000 + i));
            vm.deal(minter, 1 ether);
            vm.prank(minter);
            nft.publicMint{value: 0.01 ether}();
        }

        // 1001st mint should fail
        address extraMinter = address(9999);
        vm.deal(extraMinter, 1 ether);
        vm.prank(extraMinter);

        vm.expectRevert(Project29Solution.MaxSupplyReached.selector);
        nft.publicMint{value: 0.01 ether}();
    }

    // ============ Admin Function Tests ============

    function test_SetMerkleRoot() public {
        bytes32 newRoot = keccak256(abi.encodePacked("new root"));

        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit Project29Solution.MerkleRootUpdated(merkleRoot, newRoot);

        nft.setMerkleRoot(newRoot);

        assertEq(nft.merkleRoot(), newRoot);
    }

    function test_RevertSetMerkleRootNotOwner() public {
        bytes32 newRoot = keccak256(abi.encodePacked("new root"));

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        nft.setMerkleRoot(newRoot);
    }

    function test_SetPublicMintEnabled() public {
        vm.prank(owner);
        nft.setPublicMintEnabled(true);
        assertTrue(nft.publicMintEnabled());

        vm.prank(owner);
        nft.setPublicMintEnabled(false);
        assertFalse(nft.publicMintEnabled());
    }

    function test_Withdraw() public {
        // Enable public mint and have some users mint
        vm.prank(owner);
        nft.setPublicMintEnabled(true);

        vm.deal(user1, 1 ether);
        vm.prank(user1);
        nft.publicMint{value: 0.01 ether}();

        uint256 ownerBalanceBefore = owner.balance;
        uint256 contractBalance = address(nft).balance;

        vm.prank(owner);
        nft.withdraw();

        assertEq(owner.balance, ownerBalanceBefore + contractBalance);
        assertEq(address(nft).balance, 0);
    }

    function test_RevertWithdrawNoBalance() public {
        vm.prank(owner);
        vm.expectRevert(Project29Solution.NoBalanceToWithdraw.selector);
        nft.withdraw();
    }

    function test_RevertWithdrawNotOwner() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        nft.withdraw();
    }

    // ============ View Function Tests ============

    function test_HasAddressClaimed() public {
        assertFalse(nft.hasAddressClaimed(user1));

        vm.prank(user1);
        nft.allowlistMint(proofs[user1]);

        assertTrue(nft.hasAddressClaimed(user1));
    }

    function test_GetCurrentTokenId() public {
        assertEq(nft.getCurrentTokenId(), 0);

        vm.prank(user1);
        nft.allowlistMint(proofs[user1]);

        assertEq(nft.getCurrentTokenId(), 1);
    }

    function test_TotalSupply() public {
        assertEq(nft.totalSupply(), 0);

        vm.prank(user1);
        nft.allowlistMint(proofs[user1]);

        assertEq(nft.totalSupply(), 1);

        vm.prank(user2);
        nft.allowlistMint(proofs[user2]);

        assertEq(nft.totalSupply(), 2);
    }

    // ============ Gas Comparison Tests ============

    function test_GasComparison_AllowlistVsMapping() public {
        // This test demonstrates why Merkle trees are better for large allowlists

        // Scenario 1: Setting up allowlist with mapping (traditional approach)
        MappingAllowlist mappingNFT = new MappingAllowlist();

        address[] memory addresses = new address[](100);
        for (uint i = 0; i < 100; i++) {
            addresses[i] = address(uint160(1000 + i));
        }

        uint256 gasBefore = gasleft();
        mappingNFT.setAllowlist(addresses);
        uint256 gasUsedMapping = gasBefore - gasleft();

        console.log("Gas to set up 100 addresses with mapping:", gasUsedMapping);

        // Scenario 2: Setting up allowlist with Merkle root
        gasBefore = gasleft();
        new Project29Solution(merkleRoot);
        uint256 gasUsedMerkle = gasBefore - gasleft();

        console.log("Gas to set up with Merkle root:", gasUsedMerkle);
        console.log("Gas saved:", gasUsedMapping - gasUsedMerkle);

        // Merkle should be significantly more efficient
        assertLt(gasUsedMerkle, gasUsedMapping);
    }

    function test_GasCost_ValidProofVerification() public {
        vm.prank(user1);

        uint256 gasBefore = gasleft();
        nft.allowlistMint(proofs[user1]);
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas used for allowlist mint with 2 proof elements:", gasUsed);
    }

    function test_GasCost_PublicMint() public {
        vm.prank(owner);
        nft.setPublicMintEnabled(true);

        vm.deal(notAllowlisted, 1 ether);
        vm.prank(notAllowlisted);

        uint256 gasBefore = gasleft();
        nft.publicMint{value: 0.01 ether}();
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas used for public mint:", gasUsed);
    }

    // ============ Edge Case Tests ============

    function test_ProofOrderMatters() public view {
        // Proof elements must be in correct order
        bytes32[] memory wrongOrderProof = new bytes32[](2);
        wrongOrderProof[0] = proofs[user1][1]; // Swapped order
        wrongOrderProof[1] = proofs[user1][0];

        // This should fail
        assertFalse(nft.verifyAllowlist(user1, wrongOrderProof));
    }

    function test_ProofWithExtraElements() public view {
        // Proof with extra elements should fail
        bytes32[] memory extraProof = new bytes32[](3);
        extraProof[0] = proofs[user1][0];
        extraProof[1] = proofs[user1][1];
        extraProof[2] = bytes32(uint256(123)); // Extra element

        assertFalse(nft.verifyAllowlist(user1, extraProof));
    }

    function test_ProofWithMissingElements() public view {
        // Proof with missing elements should fail
        bytes32[] memory shortProof = new bytes32[](1);
        shortProof[0] = proofs[user1][0]; // Missing second element

        assertFalse(nft.verifyAllowlist(user1, shortProof));
    }

    function test_FuzzInvalidProofs(address attacker, bytes32[] calldata randomProof) public view {
        vm.assume(attacker != user1 && attacker != user2 && attacker != user3);

        // Random proofs should not verify for non-allowlisted addresses
        bool result = nft.verifyAllowlist(attacker, randomProof);
        assertFalse(result);
    }

    function test_FuzzValidUsersAlwaysVerify(address caller) public view {
        // Valid proofs should always work
        if (caller == user1) {
            assertTrue(nft.verifyAllowlist(caller, proofs[user1]));
        } else if (caller == user2) {
            assertTrue(nft.verifyAllowlist(caller, proofs[user2]));
        } else if (caller == user3) {
            assertTrue(nft.verifyAllowlist(caller, proofs[user3]));
        }
    }

    // ============ Integration Tests ============

    function test_FullMintingFlow() public {
        // Phase 1: Allowlist minting
        vm.prank(user1);
        nft.allowlistMint(proofs[user1]);

        vm.prank(user2);
        nft.allowlistMint(proofs[user2]);

        assertEq(nft.totalSupply(), 2);

        // Phase 2: Enable public minting
        vm.prank(owner);
        nft.setPublicMintEnabled(true);

        // Public user mints
        vm.deal(notAllowlisted, 1 ether);
        vm.prank(notAllowlisted);
        nft.publicMint{value: 0.01 ether}();

        assertEq(nft.totalSupply(), 3);

        // Phase 3: Allowlisted user can still mint if they haven't
        vm.prank(user3);
        nft.allowlistMint(proofs[user3]);

        assertEq(nft.totalSupply(), 4);

        // Phase 4: Withdraw funds
        uint256 expectedBalance = 0.01 ether; // One public mint
        assertEq(address(nft).balance, expectedBalance);

        vm.prank(owner);
        nft.withdraw();

        assertEq(address(nft).balance, 0);
        assertEq(owner.balance, expectedBalance);
    }
}

// ============ Helper Contracts ============

/**
 * @title MappingAllowlist
 * @notice Traditional allowlist using mapping for gas comparison
 */
contract MappingAllowlist is ERC721, Ownable {
    mapping(address => bool) public allowlist;
    uint256 private _nextTokenId;

    constructor() ERC721("MappingNFT", "MAP") Ownable(msg.sender) {}

    function setAllowlist(address[] calldata addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            allowlist[addresses[i]] = true;
        }
    }

    function mint() external {
        require(allowlist[msg.sender], "Not allowlisted");
        _safeMint(msg.sender, _nextTokenId++);
    }
}

/**
 * ============================================================================
 * TEST COVERAGE SUMMARY
 * ============================================================================
 *
 * ✅ Basic Functionality
 *    - Contract deployment
 *    - Valid proof verification
 *    - Invalid proof rejection
 *    - Allowlist minting
 *    - Multiple users minting
 *
 * ✅ Security Tests
 *    - Double claim prevention
 *    - Invalid proof rejection
 *    - Wrong user with valid proof
 *    - Forged proof attempts
 *    - Empty proof handling
 *
 * ✅ Public Minting
 *    - Successful public mint
 *    - Disabled public mint
 *    - Incorrect payment
 *    - Max supply enforcement
 *
 * ✅ Admin Functions
 *    - Merkle root updates
 *    - Public mint toggle
 *    - Fund withdrawal
 *    - Ownership checks
 *
 * ✅ Gas Analysis
 *    - Mapping vs Merkle comparison
 *    - Proof verification costs
 *    - Public mint costs
 *
 * ✅ Edge Cases
 *    - Proof order sensitivity
 *    - Extra proof elements
 *    - Missing proof elements
 *    - Fuzz testing
 *
 * ✅ Integration
 *    - Full minting flow
 *    - Multi-phase minting
 *    - Fund management
 *
 * ============================================================================
 */
