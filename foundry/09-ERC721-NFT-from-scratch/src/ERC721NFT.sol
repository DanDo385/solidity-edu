// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ERC721NFT {
    // ============================================================
    // STATE VARIABLES
    // ============================================================

    string public name;
    string public symbol;
    
    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    // ============================================================
    // EVENTS
    // ============================================================

    // TODO: Implement ERC721 events

    // ============================================================
    // CONSTRUCTOR
    // ============================================================

    // TODO: Implement constructor

    // ============================================================
    // EXTERNAL FUNCTIONS
    // ============================================================

    // TODO: Implement mint
    // TODO: Implement transferFrom
    // TODO: Implement safeTransferFrom
    // TODO: Implement approve
    // TODO: Implement setApprovalForAll
}
