// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ERC1155MultiToken
 * @notice Skeleton implementation of ERC-1155 Multi-Token Standard
 * @dev Complete the TODOs to implement the full standard
 */
contract ERC1155MultiToken {
    // Nested mapping: account => tokenId => balance
    mapping(address => mapping(uint256 => uint256)) public balanceOf;
    
    // Operator approvals: account => operator => approved
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    
    string public name;
    string public symbol;
    
    // TODO: Define ERC-1155 events
    // event TransferSingle(...)
    // event TransferBatch(...)
    // event ApprovalForAll(...)
    // event URI(...)
    
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }
    
    // TODO: Implement balanceOfBatch
    
    // TODO: Implement setApprovalForAll
    
    // TODO: Implement safeTransferFrom
    
    // TODO: Implement safeBatchTransferFrom
    
    // TODO: Implement mint
    
    // TODO: Implement mintBatch
    
    // TODO: Implement uri(uint256 id)
}
