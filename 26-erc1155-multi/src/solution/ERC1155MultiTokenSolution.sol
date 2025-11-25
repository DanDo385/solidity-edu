// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Project 26 Solution: ERC-1155 Multi-Token Standard
 * @notice Complete implementation of ERC-1155 for a gaming item system
 * @dev Demonstrates both fungible and non-fungible tokens in a single contract
 *
 * Key Features:
 * - Fungible tokens (currencies, consumables)
 * - Non-fungible tokens (unique equipment)
 * - Batch operations for gas efficiency
 * - Operator approvals
 * - Safe transfer callbacks with reentrancy protection
 * - Supply tracking
 */

/**
 * @dev Interface for contracts that can receive ERC-1155 tokens
 */
interface IERC1155Receiver {
    /**
     * @notice Handle the receipt of a single ERC1155 token type
     * @dev Must return its Solidity selector to confirm acceptance
     * @param operator The address which initiated the transfer
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if accepted
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @notice Handle the receipt of multiple ERC1155 token types
     * @dev Must return its Solidity selector to confirm acceptance
     * @param operator The address which initiated the batch transfer
     * @param from The address which previously owned the tokens
     * @param ids An array containing ids of each token being transferred
     * @param values An array containing amounts of each token being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if accepted
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Complete implementation of ERC-1155 Multi Token Standard
 *
 * Token ID Organization (Gaming Example):
 * - 0-999: Currencies (fungible) - GOLD, SILVER, etc.
 * - 1000-9999: Consumables (fungible) - HEALTH_POTION, MANA_POTION, etc.
 * - 10000-99999: Equipment (non-fungible) - Unique swords, armor, etc.
 */
contract GameItems {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev Base URI for computing token URIs
    string private _uri;

    /// @dev Mapping from token ID to account balances
    /// tokenId => owner => balance
    mapping(uint256 => mapping(address => uint256)) private _balances;

    /// @dev Mapping from account to operator approvals
    /// owner => operator => approved
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /// @dev Owner of the contract (for minting permissions)
    address public owner;

    /// @dev Reentrancy lock
    uint256 private _locked = 1;

    /// @dev Total supply per token ID
    mapping(uint256 => uint256) private _totalSupply;

    /*//////////////////////////////////////////////////////////////
                            TOKEN CONSTANTS
    //////////////////////////////////////////////////////////////*/

    // Fungible tokens (currencies)
    uint256 public constant GOLD = 0;
    uint256 public constant SILVER = 1;

    // Fungible tokens (consumables)
    uint256 public constant HEALTH_POTION = 1000;
    uint256 public constant MANA_POTION = 1001;

    // Non-fungible tokens start at 10000
    // Each equipment piece is unique

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Emitted when tokens are transferred
     * @param operator Address performing the transfer
     * @param from Source address
     * @param to Destination address
     * @param id Token ID
     * @param value Amount transferred
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /**
     * @dev Emitted when batch transfer occurs
     * @param operator Address performing the transfer
     * @param from Source address
     * @param to Destination address
     * @param ids Array of token IDs
     * @param values Array of amounts
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when approval is granted or revoked
     * @param account Token owner
     * @param operator Address being approved/revoked
     * @param approved True if approved, false if revoked
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when URI is updated
     * @param value New URI
     * @param id Token ID (or 0 for all)
     */
    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidAddress();
    error NotAuthorized();
    error InsufficientBalance();
    error ArrayLengthMismatch();
    error UnsafeRecipient();
    error AlreadyExists();
    error InvalidTokenId();
    error Reentrancy();

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotAuthorized();
        _;
    }

    modifier nonReentrant() {
        if (_locked != 1) revert Reentrancy();
        _locked = 2;
        _;
        _locked = 1;
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Initializes the contract with a URI template
     * @param uri_ Base URI for all tokens (use {id} as placeholder)
     *
     * Example: "https://game.com/api/item/{id}.json"
     * Token 42 would resolve to: "https://game.com/api/item/42.json"
     */
    constructor(string memory uri_) {
        _uri = uri_;
        owner = msg.sender;
        emit URI(uri_, 0); // 0 indicates URI applies to all tokens
    }

    /*//////////////////////////////////////////////////////////////
                            ERC1155 VIEWS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns the URI for token type `id`
     * @param id Token ID to query
     * @return Token URI
     *
     * Note: In production, you might replace {id} placeholder with actual ID
     * For simplicity, we return the template directly
     */
    function uri(uint256 id) public view returns (string memory) {
        // In a complete implementation, you would replace {id} with actual token ID
        // For example: return string(abi.encodePacked(_baseURI, Strings.toString(id), ".json"));
        return _uri;
    }

    /**
     * @dev Returns the amount of tokens of type `id` owned by `account`
     * @param account Address to query
     * @param id Token ID to query
     * @return Balance of the account for the token ID
     */
    function balanceOf(address account, uint256 id) public view returns (uint256) {
        if (account == address(0)) revert InvalidAddress();
        return _balances[id][account];
    }

    /**
     * @dev Batch balance query - more efficient than multiple balanceOf calls
     * @param accounts Array of addresses to query
     * @param ids Array of token IDs to query
     * @return batchBalances Array of balances corresponding to accounts and IDs
     *
     * Requirements:
     * - `accounts` and `ids` must have the same length
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view returns (uint256[] memory) {
        if (accounts.length != ids.length) revert ArrayLengthMismatch();

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; i++) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev Returns true if `operator` is approved to transfer `account`'s tokens
     * @param account Token owner
     * @param operator Address to check approval for
     * @return True if operator is approved
     */
    function isApprovedForAll(address account, address operator) public view returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /*//////////////////////////////////////////////////////////////
                            ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Grants or revokes permission to `operator` to transfer caller's tokens
     * @param operator Address to grant/revoke permission
     * @param approved True to approve, false to revoke
     *
     * Important: This approves the operator for ALL token types!
     * Unlike ERC-721, there is no per-token approval
     *
     * Emits an {ApprovalForAll} event
     */
    function setApprovalForAll(address operator, bool approved) public {
        if (operator == msg.sender) revert InvalidAddress();

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev Transfers `amount` tokens of type `id` from `from` to `to`
     * @param from Source address
     * @param to Destination address
     * @param id Token ID to transfer
     * @param amount Amount to transfer
     * @param data Additional data passed to receiver callback
     *
     * Requirements:
     * - `to` cannot be zero address
     * - Caller must be `from` or approved operator
     * - `from` must have sufficient balance
     * - If `to` is a contract, it must implement {IERC1155Receiver}
     *
     * Emits a {TransferSingle} event
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public nonReentrant {
        if (to == address(0)) revert InvalidAddress();
        if (from != msg.sender && !isApprovedForAll(from, msg.sender)) {
            revert NotAuthorized();
        }

        uint256 fromBalance = _balances[id][from];
        if (fromBalance < amount) revert InsufficientBalance();

        // Update balances - checks-effects-interactions pattern
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        // Call receiver hook if `to` is a contract
        _doSafeTransferAcceptanceCheck(msg.sender, from, to, id, amount, data);
    }

    /**
     * @dev Batch version of {safeTransferFrom}
     * @param from Source address
     * @param to Destination address
     * @param ids Array of token IDs
     * @param amounts Array of amounts (must match ids length)
     * @param data Additional data passed to receiver callback
     *
     * Requirements:
     * - `ids` and `amounts` must have the same length
     * - All other requirements from {safeTransferFrom} apply
     *
     * Emits a {TransferBatch} event
     *
     * Gas Optimization: Transfers multiple token types in one transaction
     * This is significantly more efficient than multiple safeTransferFrom calls
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public nonReentrant {
        if (to == address(0)) revert InvalidAddress();
        if (ids.length != amounts.length) revert ArrayLengthMismatch();
        if (from != msg.sender && !isApprovedForAll(from, msg.sender)) {
            revert NotAuthorized();
        }

        // Process all transfers
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            if (fromBalance < amount) revert InsufficientBalance();

            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        // Call receiver hook if `to` is a contract
        _doSafeBatchTransferAcceptanceCheck(msg.sender, from, to, ids, amounts, data);
    }

    /*//////////////////////////////////////////////////////////////
                            MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Creates `amount` tokens of type `id` and assigns them to `to`
     * @param to Recipient address
     * @param id Token ID to mint
     * @param amount Amount to mint
     * @param data Additional data for receiver callback
     *
     * Requirements:
     * - Caller must be contract owner
     * - `to` cannot be zero address
     * - If `to` is a contract, it must implement {IERC1155Receiver}
     *
     * Emits a {TransferSingle} event
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwner nonReentrant {
        if (to == address(0)) revert InvalidAddress();

        _balances[id][to] += amount;
        _totalSupply[id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(msg.sender, address(0), to, id, amount, data);
    }

    /**
     * @dev Batch minting function
     * @param to Recipient address
     * @param ids Array of token IDs
     * @param amounts Array of amounts
     * @param data Additional data for receiver callback
     *
     * Requirements:
     * - Caller must be contract owner
     * - Arrays must have the same length
     *
     * Emits a {TransferBatch} event
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner nonReentrant {
        if (to == address(0)) revert InvalidAddress();
        if (ids.length != amounts.length) revert ArrayLengthMismatch();

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
            _totalSupply[ids[i]] += amounts[i];
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(msg.sender, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of type `id` from `from`
     * @param from Address to burn from
     * @param id Token ID to burn
     * @param amount Amount to burn
     *
     * Requirements:
     * - Caller must be `from` or approved operator
     * - `from` must have sufficient balance
     *
     * Emits a {TransferSingle} event with `to` set to zero address
     */
    function burn(address from, uint256 id, uint256 amount) public nonReentrant {
        if (from != msg.sender && !isApprovedForAll(from, msg.sender)) {
            revert NotAuthorized();
        }

        uint256 fromBalance = _balances[id][from];
        if (fromBalance < amount) revert InsufficientBalance();

        unchecked {
            _balances[id][from] = fromBalance - amount;
            _totalSupply[id] -= amount;
        }

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }

    /*//////////////////////////////////////////////////////////////
                        SUPPLY TRACKING
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns the total amount of tokens of type `id` that exist
     * @param id Token ID to query
     * @return Total supply of the token
     */
    function totalSupply(uint256 id) public view returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Checks if a token ID represents a fungible token
     * @param id Token ID to check
     * @return True if token is fungible (currency or consumable)
     */
    function isFungible(uint256 id) public pure returns (bool) {
        return id < 10000;
    }

    /**
     * @dev Checks if a token ID represents a non-fungible token
     * @param id Token ID to check
     * @return True if token is non-fungible (equipment)
     */
    function isNonFungible(uint256 id) public pure returns (bool) {
        return id >= 10000;
    }

    /*//////////////////////////////////////////////////////////////
                        HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Mints a unique equipment NFT
     * @param to Recipient address
     * @param equipmentId Unique equipment ID (must be >= 10000)
     *
     * Requirements:
     * - Equipment ID must be >= 10000
     * - Equipment must not already exist (supply must be 0)
     *
     * This helper ensures NFTs are truly unique
     */
    function mintEquipment(address to, uint256 equipmentId) public onlyOwner {
        if (equipmentId < 10000) revert InvalidTokenId();
        if (_totalSupply[equipmentId] != 0) revert AlreadyExists();

        mint(to, equipmentId, 1, "");
    }

    /*//////////////////////////////////////////////////////////////
                    SAFE TRANSFER CHECKS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Performs acceptance check for single transfer
     * @param operator Address performing the transfer
     * @param from Source address
     * @param to Destination address
     * @param id Token ID
     * @param amount Amount transferred
     * @param data Additional data
     *
     * If `to` is a contract, calls onERC1155Received and validates the response
     * This prevents tokens from being locked in contracts that can't handle them
     *
     * Reentrancy Protection:
     * - This function is called AFTER state updates (checks-effects-interactions)
     * - The outer function uses nonReentrant modifier
     * - Even if receiver reenters, balances are already updated
     */
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (_isContract(to)) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert UnsafeRecipient();
                }
            } catch {
                revert UnsafeRecipient();
            }
        }
    }

    /**
     * @dev Performs acceptance check for batch transfer
     * @param operator Address performing the transfer
     * @param from Source address
     * @param to Destination address
     * @param ids Array of token IDs
     * @param amounts Array of amounts
     * @param data Additional data
     *
     * Similar to _doSafeTransferAcceptanceCheck but for batch operations
     */
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (_isContract(to)) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert UnsafeRecipient();
                }
            } catch {
                revert UnsafeRecipient();
            }
        }
    }

    /**
     * @dev Checks if an address is a contract
     * @param account Address to check
     * @return True if the address has code
     *
     * Note: This check is not foolproof:
     * - Returns false for contracts in construction
     * - Returns false for addresses where a contract will be created
     * - Returns false for addresses where a contract was destroyed
     */
    function _isContract(address account) private view returns (bool) {
        return account.code.length > 0;
    }

    /*//////////////////////////////////////////////////////////////
                        ERC165 SUPPORT
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns true if this contract implements the interface
     * @param interfaceId Interface identifier (4 bytes)
     * @return True if interface is supported
     *
     * Supported interfaces:
     * - IERC165: 0x01ffc9a7
     * - IERC1155: 0xd9b67a26
     * - IERC1155MetadataURI: 0x0e89341c
     */
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }
}
