// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Project 26: ERC-1155 Multi-Token Standard
 * @notice Learn to implement the ERC-1155 standard for managing multiple token types
 * @dev This skeleton implements a gaming item system with fungible and non-fungible tokens
 *
 * Learning objectives:
 * - Implement ERC-1155 standard
 * - Handle both fungible and non-fungible tokens
 * - Implement batch operations
 * - Manage operator approvals
 * - Handle safe transfer callbacks
 * - Protect against reentrancy
 */

// TODO: Import IERC1155 and IERC1155MetadataURI interfaces
// TODO: Import IERC1155Receiver for callback handling
// TODO: Import ReentrancyGuard for reentrancy protection
// TODO: Import Ownable for access control

/**
 * @dev Implementation of the ERC-1155 Multi Token Standard
 *
 * Token ID Organization:
 * - 0-999: Currencies (fungible)
 * - 1000-9999: Consumables (fungible)
 * - 10000-99999: Equipment (non-fungible)
 */
contract GameItems {
    // TODO: State variables

    // Base URI for token metadata
    // TODO: Add string variable for _uri

    // Balances: tokenId => owner => amount
    // TODO: Add nested mapping for balances

    // Operator approvals: owner => operator => approved
    // TODO: Add nested mapping for operator approvals

    // Owner of the contract
    // TODO: Add owner variable

    // Reentrancy guard
    // TODO: Add reentrancy lock variable

    // Token supply tracking
    // TODO: Add mapping for total supply per token ID

    // Token ID constants (Gaming Example)
    uint256 public constant GOLD = 0;
    uint256 public constant SILVER = 1;
    uint256 public constant HEALTH_POTION = 1000;
    uint256 public constant MANA_POTION = 1001;
    // Equipment starts at 10000 (each is unique NFT)

    // TODO: Events
    // TODO: Implement TransferSingle event
    // TODO: Implement TransferBatch event
    // TODO: Implement ApprovalForAll event
    // TODO: Implement URI event

    // TODO: Errors
    // TODO: Add custom errors for better gas efficiency

    // TODO: Modifiers
    // TODO: Implement onlyOwner modifier
    // TODO: Implement nonReentrant modifier

    /**
     * @dev Constructor sets the URI template for all tokens
     * @param uri_ Base URI for token metadata (use {id} placeholder)
     */
    constructor(string memory uri_) {
        // TODO: Set the URI
        // TODO: Set the contract owner
    }

    /**
     * @dev Returns the URI for a given token ID
     * @param id Token ID to query
     * @return Token URI
     */
    function uri(uint256 id) public view returns (string memory) {
        // TODO: Return the URI for the token
        // For advanced implementation, replace {id} placeholder with actual ID
    }

    /**
     * @dev Returns the balance of an account for a token ID
     * @param account Address to query
     * @param id Token ID to query
     * @return Balance of the account
     */
    function balanceOf(address account, uint256 id) public view returns (uint256) {
        // TODO: Validate account is not zero address
        // TODO: Return balance from _balances mapping
    }

    /**
     * @dev Batch balance query
     * @param accounts Array of addresses to query
     * @param ids Array of token IDs to query
     * @return batchBalances Array of balances
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view returns (uint256[] memory) {
        // TODO: Validate arrays have same length
        // TODO: Create result array
        // TODO: Loop through and get each balance
        // TODO: Return result array
    }

    /**
     * @dev Grants or revokes permission to operator to transfer caller's tokens
     * @param operator Address to grant/revoke approval
     * @param approved True to grant, false to revoke
     */
    function setApprovalForAll(address operator, bool approved) public {
        // TODO: Validate operator is not caller
        // TODO: Set approval in _operatorApprovals mapping
        // TODO: Emit ApprovalForAll event
    }

    /**
     * @dev Returns true if operator is approved to transfer account's tokens
     * @param account Token owner
     * @param operator Address to check
     * @return True if approved
     */
    function isApprovedForAll(address account, address operator) public view returns (bool) {
        // TODO: Return approval status from _operatorApprovals mapping
    }

    /**
     * @dev Transfers tokens from one address to another
     * @param from Source address
     * @param to Destination address
     * @param id Token ID to transfer
     * @param amount Amount to transfer
     * @param data Additional data for receiver callback
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
        // TODO: Validate 'to' is not zero address
        // TODO: Check caller is 'from' or approved operator
        // TODO: Check 'from' has sufficient balance
        // TODO: Update balances (subtract from 'from', add to 'to')
        // TODO: Emit TransferSingle event
        // TODO: Call _doSafeTransferAcceptanceCheck
    }

    /**
     * @dev Batch transfer of multiple token types
     * @param from Source address
     * @param to Destination address
     * @param ids Array of token IDs
     * @param amounts Array of amounts
     * @param data Additional data for receiver callback
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public {
        // TODO: Validate 'to' is not zero address
        // TODO: Validate arrays have same length
        // TODO: Check caller is 'from' or approved operator
        // TODO: Loop through arrays:
        //       - Validate balance
        //       - Update balances
        // TODO: Emit TransferBatch event
        // TODO: Call _doSafeBatchTransferAcceptanceCheck
    }

    /**
     * @dev Mints tokens to an address (owner only)
     * @param to Recipient address
     * @param id Token ID to mint
     * @param amount Amount to mint
     * @param data Additional data for receiver callback
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
        // TODO: Add onlyOwner check
        // TODO: Validate 'to' is not zero address
        // TODO: Update balance
        // TODO: Update total supply
        // TODO: Emit TransferSingle event
        // TODO: Call _doSafeTransferAcceptanceCheck
    }

    /**
     * @dev Mints batch of tokens to an address (owner only)
     * @param to Recipient address
     * @param ids Array of token IDs
     * @param amounts Array of amounts
     * @param data Additional data for receiver callback
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public {
        // TODO: Add onlyOwner check
        // TODO: Validate 'to' is not zero address
        // TODO: Validate arrays have same length
        // TODO: Loop through arrays and update balances and supply
        // TODO: Emit TransferBatch event
        // TODO: Call _doSafeBatchTransferAcceptanceCheck
    }

    /**
     * @dev Burns tokens from an address
     * @param from Address to burn from
     * @param id Token ID to burn
     * @param amount Amount to burn
     */
    function burn(address from, uint256 id, uint256 amount) public {
        // TODO: Check caller is 'from' or approved operator
        // TODO: Validate balance is sufficient
        // TODO: Update balance
        // TODO: Update total supply
        // TODO: Emit TransferSingle event
    }

    /**
     * @dev Returns total supply of a token ID
     * @param id Token ID to query
     * @return Total supply
     */
    function totalSupply(uint256 id) public view returns (uint256) {
        // TODO: Return total supply from mapping
    }

    /**
     * @dev Checks if token ID is fungible (currency or consumable)
     * @param id Token ID to check
     * @return True if fungible
     */
    function isFungible(uint256 id) public pure returns (bool) {
        // TODO: Return true if id < 10000
    }

    /**
     * @dev Checks if token ID is non-fungible (equipment)
     * @param id Token ID to check
     * @return True if non-fungible
     */
    function isNonFungible(uint256 id) public pure returns (bool) {
        // TODO: Return true if id >= 10000
    }

    /**
     * @dev Mints a unique equipment NFT (helper function)
     * @param to Recipient address
     * @param equipmentId Unique equipment ID (must be >= 10000)
     */
    function mintEquipment(address to, uint256 equipmentId) public {
        // TODO: Add onlyOwner check
        // TODO: Validate equipmentId >= 10000
        // TODO: Validate total supply is 0 (must be unique)
        // TODO: Call mint with amount = 1
    }

    // Internal helper functions

    /**
     * @dev Checks if transfer to address is safe (implements ERC1155 receiver check)
     * @param operator Address performing the transfer
     * @param from Source address
     * @param to Destination address
     * @param id Token ID
     * @param amount Amount transferred
     * @param data Additional data
     */
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        // TODO: Check if 'to' is a contract (code size > 0)
        // TODO: If contract, call onERC1155Received and validate return value
        // TODO: Return value must be IERC1155Receiver.onERC1155Received.selector
    }

    /**
     * @dev Checks if batch transfer to address is safe
     * @param operator Address performing the transfer
     * @param from Source address
     * @param to Destination address
     * @param ids Array of token IDs
     * @param amounts Array of amounts
     * @param data Additional data
     */
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        // TODO: Check if 'to' is a contract (code size > 0)
        // TODO: If contract, call onERC1155BatchReceived and validate return value
        // TODO: Return value must be IERC1155Receiver.onERC1155BatchReceived.selector
    }

    /**
     * @dev Checks if address is a contract
     * @param account Address to check
     * @return True if contract
     */
    function _isContract(address account) private view returns (bool) {
        // TODO: Return true if code size > 0
    }

    /**
     * @dev Supports interface detection (ERC-165)
     * @param interfaceId Interface identifier
     * @return True if interface is supported
     */
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        // TODO: Return true for:
        //       - IERC165 (0x01ffc9a7)
        //       - IERC1155 (0xd9b67a26)
        //       - IERC1155MetadataURI (0x0e89341c)
    }
}

/**
 * @dev Interface for contracts that can receive ERC-1155 tokens
 */
interface IERC1155Receiver {
    /**
     * @dev Handles single token transfer
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles batch token transfer
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}
