// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC1155Receiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);
    
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC1155MultiTokenSolution
 * @notice Complete ERC-1155 implementation supporting fungible + non-fungible tokens
 *
 * KEY INNOVATION:
 * - Single contract manages BOTH fungible and non-fungible tokens
 * - Batch operations for massive gas savings
 * - Simpler than managing multiple ERC-20/721 contracts
 *
 * USE CASES:
 * - Gaming: items, currency, collectibles in one contract
 * - Metaverse: land, wearables, currency
 * - DeFi: multiple tranches, batch portfolio management
 */
contract ERC1155MultiTokenSolution {
    // account => tokenId => balance
    mapping(address => mapping(uint256 => uint256)) public balanceOf;
    
    // account => operator => approved
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    
    // tokenId => URI
    mapping(uint256 => string) private _tokenURIs;
    
    string public name;
    string public symbol;
    string private _baseURI;
    
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
    event URI(string value, uint256 indexed id);
    
    constructor(string memory _name, string memory _symbol, string memory baseURI_) {
        name = _name;
        symbol = _symbol;
        _baseURI = baseURI_;
    }
    
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) public view returns (uint256[] memory) {
        require(accounts.length == ids.length, "Length mismatch");
        
        uint256[] memory batchBalances = new uint256[](accounts.length);
        
        for (uint256 i = 0; i < accounts.length; i++) {
            batchBalances[i] = balanceOf[accounts[i]][ids[i]];
        }
        
        return batchBalances;
    }
    
    function setApprovalForAll(address operator, bool approved) public {
        require(msg.sender != operator, "Cannot approve self");
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public {
        require(
            from == msg.sender || isApprovedForAll[from][msg.sender],
            "Not authorized"
        );
        require(to != address(0), "Invalid recipient");
        
        uint256 fromBalance = balanceOf[from][id];
        require(fromBalance >= amount, "Insufficient balance");
        
        balanceOf[from][id] = fromBalance - amount;
        balanceOf[to][id] += amount;
        
        emit TransferSingle(msg.sender, from, to, id, amount);
        
        _doSafeTransferAcceptanceCheck(msg.sender, from, to, id, amount, data);
    }
    
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public {
        require(
            from == msg.sender || isApprovedForAll[from][msg.sender],
            "Not authorized"
        );
        require(to != address(0), "Invalid recipient");
        require(ids.length == amounts.length, "Length mismatch");
        
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            
            uint256 fromBalance = balanceOf[from][id];
            require(fromBalance >= amount, "Insufficient balance");
            
            balanceOf[from][id] = fromBalance - amount;
            balanceOf[to][id] += amount;
        }
        
        emit TransferBatch(msg.sender, from, to, ids, amounts);
        
        _doSafeBatchTransferAcceptanceCheck(msg.sender, from, to, ids, amounts, data);
    }
    
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public {
        require(to != address(0), "Invalid recipient");
        
        balanceOf[to][id] += amount;
        
        emit TransferSingle(msg.sender, address(0), to, id, amount);
        
        _doSafeTransferAcceptanceCheck(msg.sender, address(0), to, id, amount, data);
    }
    
    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public {
        require(to != address(0), "Invalid recipient");
        require(ids.length == amounts.length, "Length mismatch");
        
        for (uint256 i = 0; i < ids.length; i++) {
            balanceOf[to][ids[i]] += amounts[i];
        }
        
        emit TransferBatch(msg.sender, address(0), to, ids, amounts);
        
        _doSafeBatchTransferAcceptanceCheck(msg.sender, address(0), to, ids, amounts, data);
    }
    
    function burn(address from, uint256 id, uint256 amount) public {
        require(
            from == msg.sender || isApprovedForAll[from][msg.sender],
            "Not authorized"
        );
        
        uint256 fromBalance = balanceOf[from][id];
        require(fromBalance >= amount, "Insufficient balance");
        
        balanceOf[from][id] = fromBalance - amount;
        
        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
    
    function uri(uint256 id) public view returns (string memory) {
        string memory tokenURI = _tokenURIs[id];
        
        if (bytes(tokenURI).length > 0) {
            return tokenURI;
        }
        
        return string(abi.encodePacked(_baseURI, _toString(id)));
    }
    
    function setURI(uint256 id, string memory newuri) public {
        _tokenURIs[id] = newuri;
        emit URI(newuri, id);
    }
    
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("Invalid receiver");
                }
            } catch {
                revert("Transfer to non-receiver");
            }
        }
    }
    
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("Invalid receiver");
                }
            } catch {
                revert("Batch transfer to non-receiver");
            }
        }
    }
    
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
