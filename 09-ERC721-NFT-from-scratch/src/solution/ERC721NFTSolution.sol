// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC721NFTSolution {
    string public name;
    string public symbol;
    uint256 private _tokenIdCounter;
    
    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    mapping(uint256 => string) public tokenURI;
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }
    
    function mint(address to, string memory uri) public returns (uint256) {
        require(to != address(0), "Invalid recipient");
        
        uint256 tokenId = _tokenIdCounter++;
        
        balanceOf[to]++;
        ownerOf[tokenId] = to;
        tokenURI[tokenId] = uri;
        
        emit Transfer(address(0), to, tokenId);
        return tokenId;
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(from == ownerOf[tokenId], "Not owner");
        require(to != address(0), "Invalid recipient");
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized");
        
        balanceOf[from]--;
        balanceOf[to]++;
        ownerOf[tokenId] = to;
        delete getApproved[tokenId];
        
        emit Transfer(from, to, tokenId);
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        transferFrom(from, to, tokenId);
        
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                require(retval == IERC721Receiver.onERC721Received.selector, "Invalid receiver");
            } catch {
                revert("Transfer to non-receiver");
            }
        }
    }
    
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf[tokenId];
        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "Not authorized");
        
        getApproved[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }
    
    function setApprovalForAll(address operator, bool approved) public {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf[tokenId];
        return (spender == owner || getApproved[tokenId] == spender || isApprovedForAll[owner][spender]);
    }
    
    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter;
    }
}
