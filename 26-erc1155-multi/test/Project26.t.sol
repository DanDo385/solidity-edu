// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/Project26Solution.sol";

/**
 * @title Project 26 Tests: ERC-1155 Multi-Token Standard
 * @notice Comprehensive test suite for ERC-1155 implementation
 */
contract Project26Test is Test {
    GameItems public gameItems;

    address public owner;
    address public alice;
    address public bob;
    address public carol;

    // Events to test
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    function setUp() public {
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        carol = makeAddr("carol");

        gameItems = new GameItems("https://game.com/api/item/{id}.json");
    }

    /*//////////////////////////////////////////////////////////////
                        BASIC FUNCTIONALITY TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Constructor() public {
        assertEq(gameItems.owner(), owner);
        assertEq(gameItems.uri(0), "https://game.com/api/item/{id}.json");
    }

    function test_MintFungibleToken() public {
        uint256 amount = 1000;

        vm.expectEmit(true, true, true, true);
        emit TransferSingle(owner, address(0), alice, gameItems.GOLD(), amount);

        gameItems.mint(alice, gameItems.GOLD(), amount, "");

        assertEq(gameItems.balanceOf(alice, gameItems.GOLD()), amount);
        assertEq(gameItems.totalSupply(gameItems.GOLD()), amount);
    }

    function test_MintNonFungibleToken() public {
        uint256 swordId = 10000;

        gameItems.mintEquipment(alice, swordId);

        assertEq(gameItems.balanceOf(alice, swordId), 1);
        assertEq(gameItems.totalSupply(swordId), 1);
        assertTrue(gameItems.isNonFungible(swordId));
    }

    function test_RevertMintEquipmentTwice() public {
        uint256 swordId = 10000;

        gameItems.mintEquipment(alice, swordId);

        vm.expectRevert(GameItems.AlreadyExists.selector);
        gameItems.mintEquipment(bob, swordId);
    }

    function test_RevertMintEquipmentInvalidId() public {
        vm.expectRevert(GameItems.InvalidTokenId.selector);
        gameItems.mintEquipment(alice, 999); // Must be >= 10000
    }

    function test_BalanceOf() public {
        gameItems.mint(alice, gameItems.GOLD(), 1000, "");
        gameItems.mint(alice, gameItems.SILVER(), 500, "");

        assertEq(gameItems.balanceOf(alice, gameItems.GOLD()), 1000);
        assertEq(gameItems.balanceOf(alice, gameItems.SILVER()), 500);
        assertEq(gameItems.balanceOf(bob, gameItems.GOLD()), 0);
    }

    function test_BalanceOfBatch() public {
        gameItems.mint(alice, gameItems.GOLD(), 1000, "");
        gameItems.mint(alice, gameItems.SILVER(), 500, "");
        gameItems.mint(bob, gameItems.GOLD(), 2000, "");

        address[] memory accounts = new address[](3);
        accounts[0] = alice;
        accounts[1] = alice;
        accounts[2] = bob;

        uint256[] memory ids = new uint256[](3);
        ids[0] = gameItems.GOLD();
        ids[1] = gameItems.SILVER();
        ids[2] = gameItems.GOLD();

        uint256[] memory balances = gameItems.balanceOfBatch(accounts, ids);

        assertEq(balances[0], 1000);
        assertEq(balances[1], 500);
        assertEq(balances[2], 2000);
    }

    function test_RevertBalanceOfBatchLengthMismatch() public {
        address[] memory accounts = new address[](2);
        uint256[] memory ids = new uint256[](3);

        vm.expectRevert(GameItems.ArrayLengthMismatch.selector);
        gameItems.balanceOfBatch(accounts, ids);
    }

    /*//////////////////////////////////////////////////////////////
                        TRANSFER TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SafeTransferFrom() public {
        gameItems.mint(alice, gameItems.GOLD(), 1000, "");

        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(alice, alice, bob, gameItems.GOLD(), 500);

        vm.prank(alice);
        gameItems.safeTransferFrom(alice, bob, gameItems.GOLD(), 500, "");

        assertEq(gameItems.balanceOf(alice, gameItems.GOLD()), 500);
        assertEq(gameItems.balanceOf(bob, gameItems.GOLD()), 500);
    }

    function test_RevertTransferInsufficientBalance() public {
        gameItems.mint(alice, gameItems.GOLD(), 100, "");

        vm.prank(alice);
        vm.expectRevert(GameItems.InsufficientBalance.selector);
        gameItems.safeTransferFrom(alice, bob, gameItems.GOLD(), 500, "");
    }

    function test_RevertTransferNotAuthorized() public {
        gameItems.mint(alice, gameItems.GOLD(), 1000, "");

        vm.prank(bob);
        vm.expectRevert(GameItems.NotAuthorized.selector);
        gameItems.safeTransferFrom(alice, bob, gameItems.GOLD(), 500, "");
    }

    function test_RevertTransferToZeroAddress() public {
        gameItems.mint(alice, gameItems.GOLD(), 1000, "");

        vm.prank(alice);
        vm.expectRevert(GameItems.InvalidAddress.selector);
        gameItems.safeTransferFrom(alice, address(0), gameItems.GOLD(), 500, "");
    }

    function test_SafeBatchTransferFrom() public {
        // Mint multiple token types to alice
        gameItems.mint(alice, gameItems.GOLD(), 1000, "");
        gameItems.mint(alice, gameItems.SILVER(), 500, "");
        gameItems.mint(alice, gameItems.HEALTH_POTION(), 10, "");

        uint256[] memory ids = new uint256[](3);
        ids[0] = gameItems.GOLD();
        ids[1] = gameItems.SILVER();
        ids[2] = gameItems.HEALTH_POTION();

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 300;
        amounts[1] = 200;
        amounts[2] = 5;

        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit TransferBatch(alice, alice, bob, ids, amounts);

        vm.prank(alice);
        gameItems.safeBatchTransferFrom(alice, bob, ids, amounts, "");

        // Verify alice's balances
        assertEq(gameItems.balanceOf(alice, gameItems.GOLD()), 700);
        assertEq(gameItems.balanceOf(alice, gameItems.SILVER()), 300);
        assertEq(gameItems.balanceOf(alice, gameItems.HEALTH_POTION()), 5);

        // Verify bob's balances
        assertEq(gameItems.balanceOf(bob, gameItems.GOLD()), 300);
        assertEq(gameItems.balanceOf(bob, gameItems.SILVER()), 200);
        assertEq(gameItems.balanceOf(bob, gameItems.HEALTH_POTION()), 5);
    }

    function test_MintBatch() public {
        uint256[] memory ids = new uint256[](3);
        ids[0] = gameItems.GOLD();
        ids[1] = gameItems.SILVER();
        ids[2] = gameItems.HEALTH_POTION();

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 1000;
        amounts[1] = 500;
        amounts[2] = 10;

        vm.expectEmit(true, true, true, true);
        emit TransferBatch(owner, address(0), alice, ids, amounts);

        gameItems.mintBatch(alice, ids, amounts, "");

        assertEq(gameItems.balanceOf(alice, gameItems.GOLD()), 1000);
        assertEq(gameItems.balanceOf(alice, gameItems.SILVER()), 500);
        assertEq(gameItems.balanceOf(alice, gameItems.HEALTH_POTION()), 10);
    }

    /*//////////////////////////////////////////////////////////////
                        APPROVAL TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SetApprovalForAll() public {
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit ApprovalForAll(alice, bob, true);

        vm.prank(alice);
        gameItems.setApprovalForAll(bob, true);

        assertTrue(gameItems.isApprovedForAll(alice, bob));
    }

    function test_RevokeApprovalForAll() public {
        vm.prank(alice);
        gameItems.setApprovalForAll(bob, true);

        vm.prank(alice);
        gameItems.setApprovalForAll(bob, false);

        assertFalse(gameItems.isApprovedForAll(alice, bob));
    }

    function test_OperatorTransfer() public {
        gameItems.mint(alice, gameItems.GOLD(), 1000, "");

        // Alice approves bob as operator
        vm.prank(alice);
        gameItems.setApprovalForAll(bob, true);

        // Bob transfers on behalf of alice
        vm.prank(bob);
        gameItems.safeTransferFrom(alice, carol, gameItems.GOLD(), 500, "");

        assertEq(gameItems.balanceOf(alice, gameItems.GOLD()), 500);
        assertEq(gameItems.balanceOf(carol, gameItems.GOLD()), 500);
    }

    function test_RevertOperatorTransferAfterRevoke() public {
        gameItems.mint(alice, gameItems.GOLD(), 1000, "");

        vm.prank(alice);
        gameItems.setApprovalForAll(bob, true);

        vm.prank(alice);
        gameItems.setApprovalForAll(bob, false);

        vm.prank(bob);
        vm.expectRevert(GameItems.NotAuthorized.selector);
        gameItems.safeTransferFrom(alice, carol, gameItems.GOLD(), 500, "");
    }

    /*//////////////////////////////////////////////////////////////
                        BURN TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Burn() public {
        gameItems.mint(alice, gameItems.GOLD(), 1000, "");

        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(alice, alice, address(0), gameItems.GOLD(), 300);

        vm.prank(alice);
        gameItems.burn(alice, gameItems.GOLD(), 300);

        assertEq(gameItems.balanceOf(alice, gameItems.GOLD()), 700);
        assertEq(gameItems.totalSupply(gameItems.GOLD()), 700);
    }

    function test_BurnByOperator() public {
        gameItems.mint(alice, gameItems.GOLD(), 1000, "");

        vm.prank(alice);
        gameItems.setApprovalForAll(bob, true);

        vm.prank(bob);
        gameItems.burn(alice, gameItems.GOLD(), 300);

        assertEq(gameItems.balanceOf(alice, gameItems.GOLD()), 700);
    }

    function test_RevertBurnInsufficientBalance() public {
        gameItems.mint(alice, gameItems.GOLD(), 100, "");

        vm.prank(alice);
        vm.expectRevert(GameItems.InsufficientBalance.selector);
        gameItems.burn(alice, gameItems.GOLD(), 500);
    }

    /*//////////////////////////////////////////////////////////////
                    SAFE TRANSFER CALLBACK TESTS
    //////////////////////////////////////////////////////////////*/

    function test_TransferToEOA() public {
        // EOAs (externally owned accounts) don't need to implement receiver
        gameItems.mint(alice, gameItems.GOLD(), 1000, "");

        vm.prank(alice);
        gameItems.safeTransferFrom(alice, bob, gameItems.GOLD(), 500, "");

        assertEq(gameItems.balanceOf(bob, gameItems.GOLD()), 500);
    }

    function test_TransferToValidReceiver() public {
        ValidReceiver receiver = new ValidReceiver();
        gameItems.mint(alice, gameItems.GOLD(), 1000, "");

        vm.prank(alice);
        gameItems.safeTransferFrom(alice, address(receiver), gameItems.GOLD(), 500, "");

        assertEq(gameItems.balanceOf(address(receiver), gameItems.GOLD()), 500);
        assertEq(receiver.lastOperator(), alice);
        assertEq(receiver.lastFrom(), alice);
        assertEq(receiver.lastId(), gameItems.GOLD());
        assertEq(receiver.lastValue(), 500);
    }

    function test_RevertTransferToInvalidReceiver() public {
        InvalidReceiver receiver = new InvalidReceiver();
        gameItems.mint(alice, gameItems.GOLD(), 1000, "");

        vm.prank(alice);
        vm.expectRevert(GameItems.UnsafeRecipient.selector);
        gameItems.safeTransferFrom(alice, address(receiver), gameItems.GOLD(), 500, "");
    }

    function test_RevertTransferToNonReceiver() public {
        NonReceiver receiver = new NonReceiver();
        gameItems.mint(alice, gameItems.GOLD(), 1000, "");

        vm.prank(alice);
        vm.expectRevert(GameItems.UnsafeRecipient.selector);
        gameItems.safeTransferFrom(alice, address(receiver), gameItems.GOLD(), 500, "");
    }

    function test_BatchTransferToValidReceiver() public {
        ValidReceiver receiver = new ValidReceiver();
        gameItems.mint(alice, gameItems.GOLD(), 1000, "");
        gameItems.mint(alice, gameItems.SILVER(), 500, "");

        uint256[] memory ids = new uint256[](2);
        ids[0] = gameItems.GOLD();
        ids[1] = gameItems.SILVER();

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 300;
        amounts[1] = 200;

        vm.prank(alice);
        gameItems.safeBatchTransferFrom(alice, address(receiver), ids, amounts, "");

        assertEq(gameItems.balanceOf(address(receiver), gameItems.GOLD()), 300);
        assertEq(gameItems.balanceOf(address(receiver), gameItems.SILVER()), 200);
    }

    /*//////////////////////////////////////////////////////////////
                        REENTRANCY TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RevertReentrancyOnTransfer() public {
        ReentrantAttacker attacker = new ReentrantAttacker(address(gameItems));
        gameItems.mint(address(attacker), gameItems.GOLD(), 1000, "");

        vm.expectRevert(GameItems.Reentrancy.selector);
        attacker.attack(alice, gameItems.GOLD(), 500);
    }

    function test_RevertReentrancyOnBatchTransfer() public {
        ReentrantBatchAttacker attacker = new ReentrantBatchAttacker(address(gameItems));
        gameItems.mint(address(attacker), gameItems.GOLD(), 1000, "");
        gameItems.mint(address(attacker), gameItems.SILVER(), 500, "");

        uint256[] memory ids = new uint256[](2);
        ids[0] = gameItems.GOLD();
        ids[1] = gameItems.SILVER();

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 300;
        amounts[1] = 200;

        vm.expectRevert(GameItems.Reentrancy.selector);
        attacker.attack(alice, ids, amounts);
    }

    /*//////////////////////////////////////////////////////////////
                        MIXED TOKEN TYPE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_MixedFungibleAndNFT() public {
        // Mint fungible tokens
        gameItems.mint(alice, gameItems.GOLD(), 1000, "");
        gameItems.mint(alice, gameItems.HEALTH_POTION(), 10, "");

        // Mint NFT
        uint256 swordId = 10000;
        gameItems.mintEquipment(alice, swordId);

        // Verify fungible
        assertTrue(gameItems.isFungible(gameItems.GOLD()));
        assertTrue(gameItems.isFungible(gameItems.HEALTH_POTION()));

        // Verify NFT
        assertTrue(gameItems.isNonFungible(swordId));

        // Transfer mix in batch
        uint256[] memory ids = new uint256[](3);
        ids[0] = gameItems.GOLD();
        ids[1] = gameItems.HEALTH_POTION();
        ids[2] = swordId;

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 500;
        amounts[1] = 5;
        amounts[2] = 1;

        vm.prank(alice);
        gameItems.safeBatchTransferFrom(alice, bob, ids, amounts, "");

        // Verify balances
        assertEq(gameItems.balanceOf(bob, gameItems.GOLD()), 500);
        assertEq(gameItems.balanceOf(bob, gameItems.HEALTH_POTION()), 5);
        assertEq(gameItems.balanceOf(bob, swordId), 1);
        assertEq(gameItems.balanceOf(alice, swordId), 0); // NFT fully transferred
    }

    /*//////////////////////////////////////////////////////////////
                        ERC165 TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SupportsInterface() public {
        // ERC165
        assertTrue(gameItems.supportsInterface(0x01ffc9a7));
        // ERC1155
        assertTrue(gameItems.supportsInterface(0xd9b67a26));
        // ERC1155MetadataURI
        assertTrue(gameItems.supportsInterface(0x0e89341c));
        // Random interface
        assertFalse(gameItems.supportsInterface(0x12345678));
    }

    /*//////////////////////////////////////////////////////////////
                        GAS COMPARISON TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GasComparisonSingleVsBatch() public {
        gameItems.mint(alice, gameItems.GOLD(), 1000, "");
        gameItems.mint(alice, gameItems.SILVER(), 1000, "");
        gameItems.mint(alice, gameItems.HEALTH_POTION(), 1000, "");

        // Measure individual transfers
        uint256 gasBefore = gasleft();
        vm.prank(alice);
        gameItems.safeTransferFrom(alice, bob, gameItems.GOLD(), 100, "");
        vm.prank(alice);
        gameItems.safeTransferFrom(alice, bob, gameItems.SILVER(), 100, "");
        vm.prank(alice);
        gameItems.safeTransferFrom(alice, bob, gameItems.HEALTH_POTION(), 100, "");
        uint256 gasIndividual = gasBefore - gasleft();

        // Mint fresh tokens for batch test
        gameItems.mint(alice, gameItems.GOLD(), 1000, "");
        gameItems.mint(alice, gameItems.SILVER(), 1000, "");
        gameItems.mint(alice, gameItems.HEALTH_POTION(), 1000, "");

        // Measure batch transfer
        uint256[] memory ids = new uint256[](3);
        ids[0] = gameItems.GOLD();
        ids[1] = gameItems.SILVER();
        ids[2] = gameItems.HEALTH_POTION();

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 100;
        amounts[1] = 100;
        amounts[2] = 100;

        gasBefore = gasleft();
        vm.prank(alice);
        gameItems.safeBatchTransferFrom(alice, carol, ids, amounts, "");
        uint256 gasBatch = gasBefore - gasleft();

        // Batch should be significantly cheaper (at least 30% savings)
        assertLt(gasBatch, (gasIndividual * 70) / 100);

        emit log_named_uint("Gas for 3 individual transfers", gasIndividual);
        emit log_named_uint("Gas for 1 batch transfer", gasBatch);
        emit log_named_uint("Gas savings", gasIndividual - gasBatch);
        emit log_named_uint("Savings percentage", ((gasIndividual - gasBatch) * 100) / gasIndividual);
    }

    /*//////////////////////////////////////////////////////////////
                        FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzz_MintAndTransfer(address to, uint256 amount) public {
        vm.assume(to != address(0));
        vm.assume(amount > 0 && amount < type(uint128).max); // Prevent overflow

        gameItems.mint(alice, gameItems.GOLD(), amount, "");

        vm.prank(alice);
        gameItems.safeTransferFrom(alice, to, gameItems.GOLD(), amount, "");

        assertEq(gameItems.balanceOf(to, gameItems.GOLD()), amount);
        assertEq(gameItems.balanceOf(alice, gameItems.GOLD()), 0);
    }

    function testFuzz_BalanceOfBatch(uint8 count) public {
        vm.assume(count > 0 && count <= 50); // Reasonable array size

        address[] memory accounts = new address[](count);
        uint256[] memory ids = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            accounts[i] = address(uint160(i + 1));
            ids[i] = i;
            gameItems.mint(accounts[i], ids[i], 100, "");
        }

        uint256[] memory balances = gameItems.balanceOfBatch(accounts, ids);

        for (uint256 i = 0; i < count; i++) {
            assertEq(balances[i], 100);
        }
    }
}

/*//////////////////////////////////////////////////////////////
                    HELPER CONTRACTS
//////////////////////////////////////////////////////////////*/

contract ValidReceiver is IERC1155Receiver {
    address public lastOperator;
    address public lastFrom;
    uint256 public lastId;
    uint256 public lastValue;

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata
    ) external returns (bytes4) {
        lastOperator = operator;
        lastFrom = from;
        lastId = id;
        lastValue = value;
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

contract InvalidReceiver is IERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        return 0x12345678; // Wrong selector
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return 0x12345678; // Wrong selector
    }
}

contract NonReceiver {
    // Does not implement IERC1155Receiver
}

contract ReentrantAttacker is IERC1155Receiver {
    GameItems public gameItems;
    address public target;

    constructor(address _gameItems) {
        gameItems = GameItems(_gameItems);
    }

    function attack(address _target, uint256 id, uint256 amount) external {
        target = _target;
        gameItems.safeTransferFrom(address(this), target, id, amount, "");
    }

    function onERC1155Received(
        address,
        address,
        uint256 id,
        uint256 value,
        bytes calldata
    ) external returns (bytes4) {
        // Attempt reentrancy
        if (gameItems.balanceOf(address(this), id) > 0) {
            gameItems.safeTransferFrom(address(this), target, id, value, "");
        }
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

contract ReentrantBatchAttacker is IERC1155Receiver {
    GameItems public gameItems;
    address public target;

    constructor(address _gameItems) {
        gameItems = GameItems(_gameItems);
    }

    function attack(address _target, uint256[] memory ids, uint256[] memory amounts) external {
        target = _target;
        gameItems.safeBatchTransferFrom(address(this), target, ids, amounts, "");
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata
    ) external returns (bytes4) {
        // Attempt reentrancy
        if (gameItems.balanceOf(address(this), ids[0]) > 0) {
            gameItems.safeBatchTransferFrom(address(this), target, ids, amounts, "");
        }
        return this.onERC1155BatchReceived.selector;
    }
}
